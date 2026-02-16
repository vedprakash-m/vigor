//
//  SilentPushReceiver.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Silent Push Infrastructure - P0 Critical for Ghost Survival.
//  Per PRD §5.1: If not implemented as P0, Ghost dies after 3 days of non-use.
//  Silent push wakes Ghost even when app is not running.
//

import Foundation
import UIKit
import BackgroundTasks

actor SilentPushReceiver {

    // MARK: - Singleton

    static let shared = SilentPushReceiver()

    // MARK: - Background Task Identifiers

    static let ghostRefreshTaskId = "com.vigor.ghost.refresh"
    static let ghostProcessingTaskId = "com.vigor.ghost.processing"

    // MARK: - State

    private var lastWakeTime: Date?
    private var consecutiveFailures: Int = 0
    private let maxConsecutiveFailures = 5

    // MARK: - Initialization

    private init() {}

    // MARK: - Background Task Registration

    func registerBackgroundTasks() {
        // Register refresh task - runs every ~15 minutes when possible
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.ghostRefreshTaskId,
            using: nil
        ) { task in
            Task {
                await self.handleGhostRefresh(task: task as! BGAppRefreshTask)
            }
        }

        // Register processing task - for longer operations (up to several minutes)
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.ghostProcessingTaskId,
            using: nil
        ) { task in
            Task {
                await self.handleGhostProcessing(task: task as! BGProcessingTask)
            }
        }
    }

    // MARK: - Schedule Background Tasks

    func scheduleGhostRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.ghostRefreshTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Failed to schedule - Ghost will rely on silent push
        }
    }

    func scheduleGhostProcessing() {
        let request = BGProcessingTaskRequest(identifier: Self.ghostProcessingTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60) // 1 hour
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Failed to schedule
        }
    }

    // MARK: - Background Task Handlers

    private func handleGhostRefresh(task: BGAppRefreshTask) async {
        // Schedule next refresh immediately
        scheduleGhostRefresh()

        // Set expiration handler
        task.expirationHandler = {
            // Cleanup if needed
        }

        do {
            // Quick Ghost cycle
            await GhostEngine.shared.performQuickCycle()
            task.setTaskCompleted(success: true)
            consecutiveFailures = 0
        } catch {
            task.setTaskCompleted(success: false)
            consecutiveFailures += 1
        }
    }

    private func handleGhostProcessing(task: BGProcessingTask) async {
        // Schedule next processing
        scheduleGhostProcessing()

        task.expirationHandler = {
            // Cleanup
        }

        do {
            // Full Ghost processing
            let ghostEngine = GhostEngine.shared

            // Sync with backend
            try await VigorAPIClient.shared.syncGhostState()

            // Process pending transformations
            await ghostEngine.processPendingTransformations()

            // Update behavioral memory
            await BehavioralMemoryStore.shared.consolidatePatterns()

            task.setTaskCompleted(success: true)
            consecutiveFailures = 0
        } catch {
            task.setTaskCompleted(success: false)
            consecutiveFailures += 1
        }
    }

    // MARK: - Silent Push Handler

    func handleSilentPush(
        userInfo: [AnyHashable: Any],
        completion: @escaping (UIBackgroundFetchResult) -> Void
    ) async {
        lastWakeTime = Date()

        guard let pushType = userInfo["ghost_action"] as? String else {
            completion(.noData)
            return
        }

        do {
            let result = try await processPushAction(pushType, userInfo: userInfo)
            completion(result)
            consecutiveFailures = 0
        } catch {
            consecutiveFailures += 1
            completion(.failed)

            // If too many failures, notify Ghost health monitor
            if consecutiveFailures >= maxConsecutiveFailures {
                await GhostHealthMonitor.shared.recordSystemFailure(
                    "Silent push processing failed \(consecutiveFailures) times"
                )
            }
        }
    }

    private func processPushAction(
        _ action: String,
        userInfo: [AnyHashable: Any]
    ) async throws -> UIBackgroundFetchResult {

        switch action {
        case "morning_cycle":
            await GhostEngine.shared.executeMorningCycle()
            return .newData

        case "evening_cycle":
            await GhostEngine.shared.executeEveningCycle()
            return .newData

        case "sunday_cycle":
            await GhostEngine.shared.executeSundayEveningCycle()
            return .newData

        case "sync":
            try await VigorAPIClient.shared.syncGhostState()
            return .newData

        case "health_check":
            let health = await GhostHealthMonitor.shared.getHealth()
            try await VigorAPIClient.shared.reportHealthStatus(health)
            return .newData

        case "workout_detected":
            if let workoutData = userInfo["workout"] as? [String: Any] {
                // Backend detected a workout via watch data
                try await processRemoteWorkoutDetection(workoutData)
                return .newData
            }
            return .noData

        case "block_transformation":
            if let blockId = userInfo["block_id"] as? String,
               let newType = userInfo["new_type"] as? String {
                try await processRemoteBlockTransformation(blockId, newType: newType)
                return .newData
            }
            return .noData

        case "trust_update":
            if let trustData = userInfo["trust"] as? [String: Any] {
                try await processRemoteTrustUpdate(trustData)
                return .newData
            }
            return .noData

        case "emergency_protocol":
            if let protocolData = userInfo["protocol"] as? [String: Any] {
                try await processEmergencyProtocol(protocolData)
                return .newData
            }
            return .noData

        case "keep_alive":
            // Simple wake to maintain background execution budget
            await GhostEngine.shared.recordWake(source: .silentPush)
            return .newData

        default:
            return .noData
        }
    }

    // MARK: - Remote Action Processors

    private func processRemoteWorkoutDetection(_ data: [String: Any]) async throws {
        guard let typeStr = data["type"] as? String,
              let type = WorkoutType(rawValue: typeStr),
              let duration = data["duration_minutes"] as? Int,
              let timestamp = data["timestamp"] as? TimeInterval else {
            return
        }

        let startDate = Date(timeIntervalSince1970: timestamp)
        let workout = DetectedWorkout(
            id: data["id"] as? String ?? UUID().uuidString,
            type: type,
            startDate: startDate,
            endDate: startDate.addingTimeInterval(TimeInterval(duration * 60)),
            duration: TimeInterval(duration * 60),
            activeCalories: Double(data["calories"] as? Int ?? 0),
            averageHeartRate: (data["hr_avg"] as? Int).map { Double($0) },
            source: "watch"
        )

        await GhostEngine.shared.handleWorkoutCompletion(workout)
    }

    private func processRemoteBlockTransformation(
        _ blockId: String,
        newType: String
    ) async throws {
        guard let workoutType = WorkoutType(rawValue: newType),
              let block = await CalendarScheduler.shared.getBlock(by: blockId) else {
            return
        }

        try await CalendarScheduler.shared.transformBlock(block, to: workoutType)
    }

    private func processRemoteTrustUpdate(_ data: [String: Any]) async throws {
        guard let score = data["score"] as? Double,
              let phaseRaw = data["phase"] as? Int,
              let phase = TrustPhase(rawValue: phaseRaw) else {
            return
        }

        await TrustStateMachine.shared.applyRemoteState(score: score, phase: phase)
    }

    private func processEmergencyProtocol(_ data: [String: Any]) async throws {
        guard let typeStr = data["type"] as? String else { return }

        switch typeStr {
        case "illness":
            // Clear all upcoming workouts — safe mode
            await GhostEngine.shared.enterSafeMode(reason: "Illness detected")

        case "injury":
            // Pause Ghost
            await GhostEngine.shared.enterSafeMode(reason: "Injury detected")

        case "vacation":
            let days = data["days"] as? Int ?? 7
            await GhostEngine.shared.enterVacationMode(days: days)

        default:
            break
        }
    }

    // MARK: - Wake Statistics

    func getWakeStatistics() async -> WakeStatistics {
        WakeStatistics(
            lastWakeTime: lastWakeTime,
            consecutiveFailures: consecutiveFailures,
            backgroundRefreshEnabled: await checkBackgroundRefreshStatus()
        )
    }

    private func checkBackgroundRefreshStatus() async -> Bool {
        await MainActor.run {
            UIApplication.shared.backgroundRefreshStatus == .available
        }
    }
}

// MARK: - Wake Statistics

struct WakeStatistics {
    let lastWakeTime: Date?
    let consecutiveFailures: Int
    let backgroundRefreshEnabled: Bool

    var timeSinceLastWake: TimeInterval? {
        lastWakeTime.map { Date().timeIntervalSince($0) }
    }

    var isHealthy: Bool {
        guard let elapsed = timeSinceLastWake else { return false }
        // Healthy if woken within last 4 hours and fewer than 3 failures
        return elapsed < 4 * 60 * 60 && consecutiveFailures < 3
    }
}

// MARK: - GhostEngine Extension for Silent Push

extension GhostEngine {

    enum WakeSource: String {
        case silentPush
        case backgroundRefresh
        case complication
        case userLaunch
        case watchSync
    }

    func recordWake(source: WakeSource) async {
        // Track wake sources for survival analytics
        var receipt = DecisionReceipt(action: .workoutDetected)
        receipt.addInput("wake_source", value: source.rawValue)
        receipt.outcome = .success
        await DecisionReceiptStore.shared.store(receipt)
    }

    func performQuickCycle() async {
        // Fast cycle for background refresh (30 second budget)
        let health = await GhostHealthMonitor.shared.getHealth()

        // Only do essential work
        if health.mode == .healthy {
            // Check for workout completions
            if let workout = await HealthKitObserver.shared.checkRecentWorkout() {
                await handleWorkoutCompletion(workout)
            }
        }
    }

    func handleWorkoutCompletion(_ workout: DetectedWorkout) async {
        // Log the workout
        await PhenomeCoordinator.shared.logWorkout(workout)

        // Update trust (positive signal)
        await TrustStateMachine.shared.recordEvent(.workoutCompleted(workout))

        // Send passive confirmation
        await NotificationOrchestrator.shared.sendWorkoutConfirmation(workout)
    }

    func processPendingTransformations() async {
        // Process any queued block transformations
        // This runs during BGProcessingTask with more time budget
        guard TrustStateMachine.shared.currentPhase.canTransformBlocks else { return }

        let calendar = Calendar.current
        let startOfWeek = calendar.startOfWeek(for: Date())
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!

        guard let blocks = try? await CalendarScheduler.shared.fetchBlocks(from: startOfWeek, to: endOfWeek) else { return }

        for block in blocks where block.status == .scheduled && block.startTime > Date() {
            // Check if recovery data suggests modification
            let recovery = await PhenomeCoordinator.shared.currentRecoveryScore
            if recovery < 40 {
                // Low recovery — transform to a lighter workout type
                let lighterType = block.workoutType.downgradedType
                if lighterType != block.workoutType {
                    try? await CalendarScheduler.shared.transformBlock(block, to: lighterType)
                }

                var receipt = DecisionReceipt(action: .blockTransformed)
                receipt.addInput("reason", value: "low_recovery")
                receipt.addInput("recovery_score", value: recovery)
                receipt.outcome = .success
                await DecisionReceiptStore.shared.store(receipt)
            }
        }
    }

    func enterSafeMode(reason: String) async {
        // Clear upcoming auto-scheduled blocks and pause Ghost scheduling
        await GhostHealthMonitor.shared.recordSystemFailure(reason)

        // Cancel upcoming auto-scheduled blocks
        let calendar = Calendar.current
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: Date())!
        if let blocks = try? await CalendarScheduler.shared.fetchBlocks(from: Date(), to: endOfWeek) {
            for block in blocks where block.wasAutoScheduled && block.status == .scheduled {
                try? await CalendarScheduler.shared.removeBlock(block)
            }
        }

        var receipt = DecisionReceipt(action: .trustRetreated)
        receipt.addInput("reason", value: reason)
        receipt.addInput("action", value: "safe_mode")
        receipt.outcome = .success
        await DecisionReceiptStore.shared.store(receipt)
    }

    func enterVacationMode(days: Int) async {
        // Pause all scheduling for specified days
        let vacationEnd = Calendar.current.date(byAdding: .day, value: days, to: Date())!

        // Cancel upcoming auto-scheduled blocks within vacation period
        if let blocks = try? await CalendarScheduler.shared.fetchBlocks(from: Date(), to: vacationEnd) {
            for block in blocks where block.wasAutoScheduled && block.status == .scheduled {
                try? await CalendarScheduler.shared.removeBlock(block)
            }
        }

        // Mark as vacation in behavioral memory
        await BehavioralMemoryStore.shared.recordVacation(days: days)

        var receipt = DecisionReceipt(action: .trustRetreated)
        receipt.addInput("action", value: "vacation_mode")
        receipt.addInput("days", value: days)
        receipt.outcome = .success
        await DecisionReceiptStore.shared.store(receipt)
    }
}

// MARK: - HealthKitObserver Extension

extension HealthKitObserver {

    func checkRecentWorkout() async -> DetectedWorkout? {
        // Quick check for workouts completed in the last hour
        // Used during background refresh with 30-second budget
        let recentWorkouts = await PhenomeCoordinator.shared.getRecentWorkoutHistory(days: 1)
        let oneHourAgo = Date().addingTimeInterval(-60 * 60)

        // Return the most recent workout from the last hour
        return recentWorkouts.first { workout in
            workout.startDate >= oneHourAgo
        }
    }
}

// MARK: - BehavioralMemoryStore Extension

extension BehavioralMemoryStore {

    func recordVacation(days: Int) {
        // Mark vacation period in behavioral memory via UserDefaults
        let vacationEnd = Calendar.current.date(byAdding: .day, value: days, to: Date())!
        UserDefaults.standard.set(Date(), forKey: "vacationStart")
        UserDefaults.standard.set(vacationEnd, forKey: "vacationEnd")
    }

    func consolidatePatterns() {
        // Long-running pattern consolidation for BGProcessingTask
        // Persist current in-memory behavioral data to Core Data
        saveAll()
    }
}

// Note: TrustStateMachine.applyRemoteState is defined in TrustStateMachine.swift
