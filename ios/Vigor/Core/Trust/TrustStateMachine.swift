//
//  TrustStateMachine.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  5-phase trust progression with safety breakers.
//  Observer → Scheduler → Auto-Scheduler → Transformer → Full Ghost
//
//  Per Tech Spec §2.3
//

import Foundation
import Combine

@MainActor
final class TrustStateMachine: ObservableObject {

    // MARK: - Singleton

    static let shared = TrustStateMachine()

    // MARK: - Published State

    @Published private(set) var currentPhase: TrustPhase = .observer
    @Published private(set) var trustScore: Double = 0.0
    @Published private(set) var phaseStartDate: Date = Date()
    @Published private(set) var lastTrustEvent: TrustEvent?

    // MARK: - Components

    let safetyBreaker = SafetyBreaker()
    private let attributionEngine = TrustAttributionEngine()

    // MARK: - Phase Thresholds

    private let phaseThresholds: [TrustPhase: (min: Double, days: Int)] = [
        .observer: (min: 0, days: 7),          // 7 days minimum in Observer
        .scheduler: (min: 30, days: 14),       // 14 days minimum in Scheduler
        .autoScheduler: (min: 60, days: 21),   // 21 days minimum in Auto-Scheduler
        .transformer: (min: 80, days: 14),     // 14 days minimum in Transformer
        .fullGhost: (min: 90, days: 0)         // No minimum in Full Ghost
    ]

    // MARK: - Initialization

    private init() {
        Task {
            await loadPersistedState()
        }

        // Setup safety breaker callback
        safetyBreaker.onTrigger = { [weak self] in
            Task { @MainActor in
                await self?.handleSafetyBreakerTrigger()
            }
        }
    }

    // MARK: - Event Recording

    func recordEvent(_ event: TrustEvent) async {
        lastTrustEvent = event

        // Calculate trust delta using Attribution Engine
        let delta = await attributionEngine.calculateTrustDelta(
            event: event,
            currentPhase: currentPhase,
            trustScore: trustScore
        )

        // Apply delta with bounds
        trustScore = max(0, min(100, trustScore + delta))

        // Check for phase transitions
        await evaluatePhaseTransition()

        // Handle safety breaker for delete events
        if case .blockDeleted(let block) = event {
            if block.wasAutoScheduled {
                await safetyBreaker.recordAutoScheduledDelete()
            }
        }

        // Persist state
        await persistState()

        // Store decision receipt
        await storeEventReceipt(event: event, delta: delta)
    }

    // MARK: - Phase Transitions

    private func evaluatePhaseTransition() async {
        // Check for advancement
        if canAdvancePhase() {
            await advancePhase()
        }

        // Check for retreat (handled by safety breaker)
    }

    private func canAdvancePhase() -> Bool {
        guard let nextPhase = currentPhase.next else { return false }
        guard let threshold = phaseThresholds[nextPhase] else { return false }

        // Check trust score threshold
        guard trustScore >= threshold.min else { return false }

        // Check minimum time in current phase
        let daysInPhase = Calendar.current.dateComponents(
            [.day],
            from: phaseStartDate,
            to: Date()
        ).day ?? 0

        guard let currentThreshold = phaseThresholds[currentPhase],
              daysInPhase >= currentThreshold.days else { return false }

        return true
    }

    private func advancePhase() async {
        guard let nextPhase = currentPhase.next else { return }

        let previousPhase = currentPhase
        currentPhase = nextPhase
        phaseStartDate = Date()

        // Record advancement
        await DecisionReceiptStore.shared.store(
            DecisionReceipt(action: .trustAdvanced)
        )

        // Notify user
        await NotificationOrchestrator.shared.sendTrustAdvancement(
            from: previousPhase,
            to: nextPhase
        )

        // Haptic feedback
        await VigorHaptics.trustAdvancement()
    }

    private func retreatToPhase(_ phase: TrustPhase) async {
        guard phase.rawValue < currentPhase.rawValue else { return }

        let previousPhase = currentPhase
        currentPhase = phase
        phaseStartDate = Date()

        // Reduce trust score to phase minimum
        if let threshold = phaseThresholds[phase] {
            trustScore = min(trustScore, threshold.min + 10)
        }

        // Record retreat
        await DecisionReceiptStore.shared.store(
            DecisionReceipt(action: .trustRetreated)
        )

        // Notify user (apologetic)
        await NotificationOrchestrator.shared.sendTrustRetreat(
            from: previousPhase,
            to: phase
        )
    }

    // MARK: - Safety Breaker

    private func handleSafetyBreakerTrigger() async {
        // CRITICAL: Immediate downgrade from Auto-Scheduler to Scheduler
        if currentPhase == .autoScheduler || currentPhase == .transformer || currentPhase == .fullGhost {
            await retreatToPhase(.scheduler)

            // Record decision
            var receipt = DecisionReceipt(action: .safetyBreakerTriggered)
            receipt.addInput("previous_phase", value: currentPhase.rawValue)
            receipt.addInput("consecutive_deletes", value: 3)
            receipt.confidence = 1.0
            receipt.outcome = .success
            await DecisionReceiptStore.shared.store(receipt)
        }
    }

    // MARK: - Manual Controls

    func manualAdvance() async {
        guard currentPhase != .fullGhost else { return }
        await advancePhase()
    }

    func manualRetreat() async {
        guard currentPhase != .observer else { return }
        if let previousPhase = currentPhase.previous {
            await retreatToPhase(previousPhase)
        }
    }

    // MARK: - Persistence

    private func loadPersistedState() async {
        if let data = UserDefaults.standard.data(forKey: "trustState"),
           let state = try? JSONDecoder().decode(PersistedTrustState.self, from: data) {
            currentPhase = state.phase
            trustScore = state.score
            phaseStartDate = state.phaseStartDate
        }
    }

    private func persistState() async {
        let state = PersistedTrustState(
            phase: currentPhase,
            score: trustScore,
            phaseStartDate: phaseStartDate
        )

        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: "trustState")
        }
    }

    private func storeEventReceipt(event: TrustEvent, delta: Double) async {
        var receipt = DecisionReceipt(action: delta > 0 ? .trustAdvanced : .trustRetreated)
        receipt.addInput("event_type", value: event.description)
        receipt.addInput("trust_delta", value: delta)
        receipt.addInput("new_trust_score", value: trustScore)
        receipt.trustImpact = delta
        receipt.outcome = .success
        await DecisionReceiptStore.shared.store(receipt)
    }
}

// MARK: - Safety Breaker

@MainActor
final class SafetyBreaker: ObservableObject {

    @Published private(set) var consecutiveAutoDeleteCount: Int = 0

    var onTrigger: (() -> Void)?

    private let triggerThreshold = 3

    func recordAutoScheduledDelete() async {
        consecutiveAutoDeleteCount += 1

        if consecutiveAutoDeleteCount >= triggerThreshold {
            // TRIGGER SAFETY BREAKER
            onTrigger?()

            // Reset counter after trigger
            consecutiveAutoDeleteCount = 0
        }
    }

    func resetConsecutiveDeletes() async {
        consecutiveAutoDeleteCount = 0
    }

    func recordManualAction() async {
        // Any positive action resets the counter
        consecutiveAutoDeleteCount = 0
    }
}

// MARK: - Persisted State

private struct PersistedTrustState: Codable {
    let phase: TrustPhase
    let score: Double
    let phaseStartDate: Date
}
