//
//  DecisionReceiptStore.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Forensic logging for Ghost decisions.
//  Records: action, inputs (hashed), alternatives, confidence, trust impact
//  90-day TTL with rolling window.
//
//  Per Tech Spec §2.4
//

import Foundation
import CoreData

actor DecisionReceiptStore {

    // MARK: - Singleton

    static let shared = DecisionReceiptStore()

    // MARK: - Storage

    private var receipts: [DecisionReceipt] = []
    private let maxReceiptAge: TimeInterval = 90 * 24 * 60 * 60 // 90 days
    private var pendingReceipts: [DecisionReceipt] = []

    // MARK: - Initialization

    private init() {
        Task {
            await loadFromDisk()
        }
    }

    // MARK: - Storage Operations

    func store(_ receipt: DecisionReceipt) async {
        var mutableReceipt = receipt
        mutableReceipt.timestamp = Date()

        receipts.append(mutableReceipt)
        pendingReceipts.append(mutableReceipt)

        // Cleanup old receipts
        await pruneOldReceipts()

        // Persist if we have enough pending
        if pendingReceipts.count >= 10 {
            await flush()
        }
    }

    func flush() async {
        guard !pendingReceipts.isEmpty else { return }

        // Persist to Core Data
        await persistToCoreData(pendingReceipts)
        pendingReceipts.removeAll()
    }

    // MARK: - Query Operations

    func getReceipts(
        for action: DecisionAction? = nil,
        from startDate: Date? = nil,
        to endDate: Date? = nil,
        limit: Int = 100
    ) async -> [DecisionReceipt] {
        var filtered = receipts

        if let action = action {
            filtered = filtered.filter { $0.action == action }
        }

        if let start = startDate {
            filtered = filtered.filter { $0.timestamp >= start }
        }

        if let end = endDate {
            filtered = filtered.filter { $0.timestamp <= end }
        }

        return Array(filtered.suffix(limit))
    }

    func getRecentReceipts(days: Int) async -> [DecisionReceipt] {
        let cutoff = Date().addingTimeInterval(-Double(days) * 24 * 60 * 60)
        return receipts.filter { $0.timestamp >= cutoff }
    }

    func getReceiptsForExplainability(blockId: String) async -> [DecisionReceipt] {
        return receipts.filter { receipt in
            receipt.inputs.contains { $0.key == "block_id" && $0.value == blockId }
        }
    }

    // MARK: - Analytics

    func getSuccessRate(for action: DecisionAction, days: Int) async -> Double {
        let cutoff = Date().addingTimeInterval(-Double(days) * 24 * 60 * 60)
        let actionReceipts = receipts.filter {
            $0.action == action && $0.timestamp >= cutoff
        }

        guard !actionReceipts.isEmpty else { return 0 }

        let successCount = actionReceipts.filter {
            if case .success = $0.outcome { return true }
            return false
        }.count

        return Double(successCount) / Double(actionReceipts.count)
    }

    func getAverageConfidence(for action: DecisionAction, days: Int) async -> Double {
        let cutoff = Date().addingTimeInterval(-Double(days) * 24 * 60 * 60)
        let actionReceipts = receipts.filter {
            $0.action == action && $0.timestamp >= cutoff
        }

        guard !actionReceipts.isEmpty else { return 0 }

        let totalConfidence = actionReceipts.reduce(0.0) { $0 + $1.confidence }
        return totalConfidence / Double(actionReceipts.count)
    }

    // MARK: - Cleanup

    private func pruneOldReceipts() async {
        let cutoff = Date().addingTimeInterval(-maxReceiptAge)
        receipts.removeAll { $0.timestamp < cutoff }
    }

    // MARK: - Persistence

    private func loadFromDisk() async {
        // Load from Core Data
        // Implementation depends on Core Data model setup
    }

    private func persistToCoreData(_ receipts: [DecisionReceipt]) async {
        // Persist to Core Data
        // Implementation depends on Core Data model setup
    }
}

// MARK: - Decision Receipt

struct DecisionReceipt: Identifiable, Codable {
    let id: UUID
    var timestamp: Date
    let action: DecisionAction
    var inputs: [DecisionInput]
    var alternatives: [String]
    var confidence: Double
    var outcome: DecisionOutcome
    var trustImpact: Double?

    init(action: DecisionAction) {
        self.id = UUID()
        self.timestamp = Date()
        self.action = action
        self.inputs = []
        self.alternatives = []
        self.confidence = 0.0
        self.outcome = .pending
        self.trustImpact = nil
    }

    mutating func addInput(_ key: String, value: Any) {
        // Hash sensitive values
        let hashedValue = hashIfSensitive(key: key, value: value)
        inputs.append(DecisionInput(key: key, value: hashedValue))
    }

    private func hashIfSensitive(key: String, value: Any) -> String {
        let sensitiveKeys = ["user_id", "device_token", "calendar_id"]

        if sensitiveKeys.contains(key) {
            // Return hashed value for privacy
            return String(describing: value).hashValue.description
        }

        return String(describing: value)
    }
}

struct DecisionInput: Codable, Equatable {
    let key: String
    let value: String
}

enum DecisionAction: String, Codable {
    case morningCycle = "morning_cycle"
    case eveningCycle = "evening_cycle"
    case workoutDetected = "workout_detected"
    case blockCreated = "block_created"
    case blockTransformed = "block_transformed"
    case blockRemoved = "block_removed"
    case trustAdvanced = "trust_advanced"
    case trustRetreated = "trust_retreated"
    case safetyBreakerTriggered = "safety_breaker_triggered"
    case triageRecorded = "triage_recorded"
}

enum DecisionOutcome: Codable, Equatable {
    case pending
    case success
    case failure(String)
    case skipped(String)

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}

// MARK: - Human Readable Extension

extension DecisionReceipt {
    var humanReadableReason: String {
        switch action {
        case .morningCycle:
            return formatMorningCycleReason()
        case .eveningCycle:
            return formatEveningCycleReason()
        case .blockTransformed:
            return formatBlockTransformationReason()
        case .blockRemoved:
            return formatBlockRemovalReason()
        default:
            return "Decision made based on your patterns and preferences."
        }
    }

    private func formatMorningCycleReason() -> String {
        var reasons: [String] = []

        if let sleepHours = inputs.first(where: { $0.key == "sleep_hours" })?.value,
           let hours = Double(sleepHours), hours < 6 {
            reasons.append("You got \(String(format: "%.1f", hours)) hours of sleep")
        }

        if let recoveryScore = inputs.first(where: { $0.key == "recovery_score" })?.value,
           let score = Double(recoveryScore), score < 50 {
            reasons.append("Your recovery score is \(Int(score))%")
        }

        if reasons.isEmpty {
            return "Your morning metrics look good!"
        }

        return reasons.joined(separator: ". ") + "."
    }

    private func formatEveningCycleReason() -> String {
        if let window = inputs.first(where: { $0.key == "optimal_window_start" })?.value {
            return "Found an optimal workout window at \(window) based on your calendar."
        }
        return "Analyzed tomorrow's schedule to find the best time for your workout."
    }

    private func formatBlockTransformationReason() -> String {
        if let originalType = inputs.first(where: { $0.key == "original_block_type" })?.value,
           let transformation = inputs.first(where: { $0.key == "transformation" })?.value {
            return "Changed from \(originalType) to \(transformation) to match your recovery level."
        }
        return "Adjusted your workout based on how you're feeling."
    }

    private func formatBlockRemovalReason() -> String {
        if let recoveryScore = inputs.first(where: { $0.key == "recovery_score" })?.value,
           let score = Double(recoveryScore) {
            return "Removed today's workout because your recovery score (\(Int(score))%) suggests you need rest."
        }
        return "Removed workout to prioritize your recovery."
    }
}
