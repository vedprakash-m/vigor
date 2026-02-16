//
//  GhostEngine.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  The Ghost Engine - Central orchestration layer coordinating all Ghost components.
//  Manages morning/evening cycles, workout detection, and system health.
//
//  Per Tech Spec §2.2:
//  - Morning cycle (6 AM): Pull sleep, calculate recovery, transform blocks
//  - Evening cycle (9 PM): Evaluate tomorrow, find optimal window, schedule/propose
//  - Workout detection response: Auto-log, update Phenome, plan next session
//

import Foundation
import Combine
import BackgroundTasks

@MainActor
final class GhostEngine: ObservableObject {

    // MARK: - Singleton

    static let shared = GhostEngine()

    // MARK: - Published State

    @Published private(set) var isRunning = false
    @Published private(set) var lastMorningCycle: Date?
    @Published private(set) var lastEveningCycle: Date?
    @Published var pendingTriageRequest: MissedBlockTriageRequest?
    @Published private(set) var pendingProposal: (workout: GeneratedWorkout, window: TimeWindow)?
    @Published private(set) var unconfirmedWorkout: DetectedWorkout?

    // MARK: - Components

    let healthMonitor = GhostHealthMonitor.shared
    private let decisionReceiptStore = DecisionReceiptStore.shared
    private let failureDisambiguator = FailureDisambiguator.shared

    // MARK: - Dependencies

    private var healthKitObserver: HealthKitObserver { HealthKitObserver.shared }
    private var calendarScheduler: CalendarScheduler { CalendarScheduler.shared }
    private var trustStateMachine: TrustStateMachine { TrustStateMachine.shared }
    private var phenomeCoordinator: PhenomeCoordinator { PhenomeCoordinator.shared }
    private var notificationOrchestrator: NotificationOrchestrator { NotificationOrchestrator.shared }

    // MARK: - Private

    private var cancellables = Set<AnyCancellable>()
    private let calendar = Calendar.current

    // MARK: - Initialization

    private init() {
        setupObservers()
    }

    private func setupObservers() {
        // Observe workout completions from HealthKit
        healthKitObserver.$lastDetectedWorkout
            .compactMap { $0 }
            .sink { [weak self] workout in
                Task {
                    await self?.handleWorkoutDetected(workout)
                }
            }
            .store(in: &cancellables)

        // Observe health monitor mode changes
        healthMonitor.$currentMode
            .sink { [weak self] mode in
                Task {
                    await self?.handleHealthModeChange(mode)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Lifecycle

    func start() async {
        guard !isRunning else { return }

        isRunning = true

        // Schedule background tasks
        scheduleBackgroundTasks()

        // Check for missed blocks that need triage
        await checkForMissedBlocks()

        // Determine if we need to run a cycle now
        await runImmediateCycleIfNeeded()
    }

    func stop() async {
        isRunning = false
    }

    /// Called after onboarding to start the initial observer/learning phase
    func startLearningPhase() async {
        await start()
    }

    // MARK: - Retry Logic

    /// Execute a cycle with retry — up to 2 retries with exponential backoff (30s, 60s).
    /// Records failure to health monitor only after all retries are exhausted.
    private func executeWithRetry(
        cycleName: String,
        maxRetries: Int = 2,
        body: @escaping () async -> Void
    ) async {
        var attempt = 0
        let delays: [UInt64] = [30_000_000_000, 60_000_000_000] // 30s, 60s in nanoseconds

        while attempt <= maxRetries {
            // If not first attempt, wait before retrying
            if attempt > 0 && attempt - 1 < delays.count {
                VigorLogger.ghost.warning("\(cycleName) cycle retry \(attempt)/\(maxRetries)")
                try? await Task.sleep(nanoseconds: delays[attempt - 1])
            }

            // Try executing the cycle body
            await body()

            // If cycle succeeded (health monitor didn't record failure), we're done
            // We check this by seeing if the last cycle timestamp was updated
            let succeeded: Bool
            if cycleName == "morning" {
                succeeded = lastMorningCycle != nil &&
                    Calendar.current.isDateInToday(lastMorningCycle ?? .distantPast)
            } else {
                succeeded = lastEveningCycle != nil &&
                    Calendar.current.isDateInToday(lastEveningCycle ?? .distantPast)
            }

            if succeeded {
                return // Success — no retry needed
            }

            attempt += 1
        }
    }

    // MARK: - Morning Cycle

    /// Morning cycle - runs around 6 AM
    /// Pulls sleep data, calculates recovery score, transforms blocks if needed
    func executeMorningCycle() async {
        await executeWithRetry(cycleName: "morning") {
            await self._executeMorningCycleBody()
        }
    }

    private func _executeMorningCycleBody() async {
        guard healthMonitor.currentMode != .suspended else {
            VigorLogger.ghost.info("Morning cycle skipped — health mode suspended")
            return
        }

        let cycleStart = Date()
        VigorLogger.ghost.info("Morning cycle started")
        var receipt = DecisionReceipt(action: .morningCycle)

        do {
            // 1. Pull sleep data from last night
            let sleepData = try await healthKitObserver.fetchLastNightSleep()
            receipt.addInput("sleep_hours", value: sleepData.totalHours)
            receipt.addInput("sleep_quality", value: sleepData.qualityScore)

            // 2. Pull HRV data
            let hrvData = try await healthKitObserver.fetchMorningHRV()
            receipt.addInput("hrv_ms", value: hrvData.averageHRV)
            receipt.addInput("hrv_trend", value: hrvData.trend.rawValue)

            // 3. Calculate recovery score
            let recoveryScore = await phenomeCoordinator.calculateRecoveryScore(
                sleep: sleepData,
                hrv: hrvData
            )
            receipt.addInput("recovery_score", value: recoveryScore)

            // 4. Check today's scheduled blocks
            let todayBlocks = try await calendarScheduler.fetchTodayBlocks()

            // 5. Transform blocks if needed based on recovery
            if recoveryScore < 40 {
                // Poor recovery - transform to lighter workout or remove
                for block in todayBlocks {
                    let transformation = await determineBlockTransformation(
                        block: block,
                        recoveryScore: recoveryScore
                    )

                    if case .none = transformation {} else {
                        try await applyBlockTransformation(
                            block: block,
                            transformation: transformation,
                            receipt: &receipt
                        )
                    }
                }
            }

            // 6. Update Phenome with morning state
            await phenomeCoordinator.updateDerivedState(
                recoveryScore: recoveryScore,
                sleepData: sleepData,
                hrvData: hrvData
            )

            receipt.confidence = 0.9
            receipt.outcome = .success
            lastMorningCycle = cycleStart
            let duration = Date().timeIntervalSince(cycleStart)
            VigorLogger.ghost.info("Morning cycle completed in \(String(format: "%.1f", duration))s — recovery=\(String(format: "%.0f", recoveryScore))")

        } catch {
            receipt.outcome = .failure(error.localizedDescription)
            VigorLogger.ghost.error("Morning cycle failed: \(error.localizedDescription)")
            await healthMonitor.reportCycleFailure(.morning, error: error)
        }

        await decisionReceiptStore.store(receipt)
    }

    // MARK: - Evening Cycle

    /// Evening cycle - runs around 9 PM
    /// Evaluates tomorrow's calendar, finds optimal workout window, schedules or proposes
    func executeEveningCycle() async {
        await executeWithRetry(cycleName: "evening") {
            await self._executeEveningCycleBody()
        }
    }

    private func _executeEveningCycleBody() async {
        guard healthMonitor.currentMode != .suspended else {
            VigorLogger.ghost.info("Evening cycle skipped — health mode suspended")
            return
        }

        let cycleStart = Date()
        VigorLogger.ghost.info("Evening cycle started")
        var receipt = DecisionReceipt(action: .eveningCycle)

        do {
            // 1. Get tomorrow's calendar
            let tomorrowBusySlots = try await calendarScheduler.fetchTomorrowBusySlots()
            receipt.addInput("busy_slots_count", value: tomorrowBusySlots.count)

            // 2. Check current trust phase
            let trustPhase = trustStateMachine.currentPhase
            receipt.addInput("trust_phase", value: trustPhase.rawValue)

            // 3. Find optimal workout window
            let preferredDuration = TimeInterval(await phenomeCoordinator.workoutPreferences.sessionDurationMinutes * 60)
            let windows = await OptimalWindowFinder.shared.findOptimalWindows(
                for: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
                workoutDuration: preferredDuration,
                count: 1
            )
            let optimalWindow = windows.first.map { TimeWindow(start: $0.window.start, end: $0.window.end) }

            guard let window = optimalWindow else {
                // No available window tomorrow
                receipt.outcome = .skipped("No available workout window")
                await decisionReceiptStore.store(receipt)
                return
            }

            receipt.addInput("optimal_window_start", value: window.start.ISO8601Format())

            // 4. Generate workout based on Phenome state
            let workout = try await generateWorkout(for: window)

            // 5. Schedule or propose based on trust phase
            switch trustPhase {
            case .observer:
                // Phase 1: Observer actively suggests — per PRD §1.2 Law II ("Magic in five minutes")
                // and §1.3 ("Ghost watches and suggests. All actions require explicit approval.")
                // Observer is NOT silent — it proposes workouts via notification, requiring user approval.
                pendingProposal = (workout: workout, window: window)
                try await notificationOrchestrator.sendBlockProposal(
                    workout: workout,
                    window: window
                )
                receipt.outcome = .success

            case .scheduler:
                // Phase 2: Same as Observer but with higher trust context
                pendingProposal = (workout: workout, window: window)
                try await notificationOrchestrator.sendBlockProposal(
                    workout: workout,
                    window: window
                )
                receipt.outcome = .success

            case .autoScheduler, .transformer, .fullGhost:
                // Phase 3+: Auto-schedule
                try await calendarScheduler.createBlock(
                    workout: workout,
                    window: window
                )
                receipt.outcome = .success
            }

            receipt.confidence = 0.85
            lastEveningCycle = cycleStart
            let duration = Date().timeIntervalSince(cycleStart)
            VigorLogger.ghost.info("Evening cycle completed in \(String(format: "%.1f", duration))s — phase=\(trustPhase.rawValue)")

        } catch {
            receipt.outcome = .failure(error.localizedDescription)
            VigorLogger.ghost.error("Evening cycle failed: \(error.localizedDescription)")
            await healthMonitor.reportCycleFailure(.evening, error: error)
        }

        await decisionReceiptStore.store(receipt)
    }

    // MARK: - Sunday Evening Cycle

    /// Sunday evening cycle - generates weekly Value Receipt
    func executeSundayEveningCycle() async {
        guard calendar.component(.weekday, from: Date()) == 1 else { return } // Sunday

        let receipt = await ValueReceiptGenerator.shared.generate(
            phenome: phenomeCoordinator,
            trustState: trustStateMachine,
            receipts: decisionReceiptStore
        )

        // Show Value Receipt notification
        await notificationOrchestrator.sendValueReceipt(receipt)
    }

    // MARK: - Workout Detection

    private func handleWorkoutDetected(_ workout: DetectedWorkout) async {
        var receipt = DecisionReceipt(action: .workoutDetected)
        receipt.addInput("workout_type", value: workout.type.rawValue)
        receipt.addInput("duration_minutes", value: workout.duration / 60)

        // 1. Auto-log the workout
        await phenomeCoordinator.logWorkout(workout)

        // 2. Track as unconfirmed until user acknowledges
        unconfirmedWorkout = workout

        // 2. Update trust (positive signal)
        await trustStateMachine.recordEvent(.workoutCompleted(workout))

        // 3. Check if this was a scheduled block
        if let matchedBlock = await calendarScheduler.findMatchingBlock(for: workout) {
            // Mark block as completed
            await calendarScheduler.markBlockCompleted(matchedBlock)
            receipt.addInput("matched_block", value: matchedBlock.id)
        }

        // 4. Reset safety breaker counter
        await trustStateMachine.safetyBreaker.resetConsecutiveDeletes()

        // 5. Send passive confirmation
        await notificationOrchestrator.sendWorkoutConfirmation(workout)

        receipt.outcome = .success
        await decisionReceiptStore.store(receipt)
    }

    // MARK: - Block Transformation

    private func determineBlockTransformation(
        block: TrainingBlock,
        recoveryScore: Double
    ) async -> BlockTransformation {
        if recoveryScore < 20 {
            // Very poor recovery - remove the block
            return .remove
        } else if recoveryScore < 40 {
            // Poor recovery - downgrade intensity
            switch block.workoutType {
            case .strength, .hiit:
                return .transformTo(.recoveryWalk)
            case .cardio:
                return .transformTo(.lightCardio)
            default:
                return .none
            }
        }
        return .none
    }

    private func applyBlockTransformation(
        block: TrainingBlock,
        transformation: BlockTransformation,
        receipt: inout DecisionReceipt
    ) async throws {
        receipt.addInput("original_block_type", value: block.workoutType.rawValue)
        receipt.addInput("transformation", value: transformation.description)

        switch transformation {
        case .remove:
            try await calendarScheduler.removeBlock(block)
            await notificationOrchestrator.sendBlockRemovalNotice(block, reason: "Low recovery")

        case .transformTo(let newType):
            try await calendarScheduler.transformBlock(block, to: newType)
            await notificationOrchestrator.sendBlockTransformationNotice(
                original: block,
                newType: newType,
                reason: "Adjusting for recovery"
            )

        case .none:
            break
        }
    }

    // MARK: - Missed Block Handling

    private func checkForMissedBlocks() async {
        let missedBlocks = await calendarScheduler.findMissedBlocks()

        for block in missedBlocks {
            // Record miss in Phenome
            await phenomeCoordinator.recordMissedBlock(block)

            // Queue for triage (max 1 per day)
            if pendingTriageRequest == nil {
                pendingTriageRequest = MissedBlockTriageRequest(
                    blockId: block.id,
                    blockTime: block.startTime,
                    workoutType: block.workoutType
                )
            }

            // Update trust (negative signal, but handled by triage)
            await trustStateMachine.recordEvent(.blockMissed(block))
        }
    }

    func clearPendingTriageRequest() {
        pendingTriageRequest = nil
    }

    // MARK: - Pending Proposals & Unconfirmed Workouts

    /// Returns a pending block proposal (workout + window) if one exists
    func getPendingBlockProposal() async -> (workout: GeneratedWorkout, window: TimeWindow)? {
        return pendingProposal
    }

    /// Clears the pending proposal after user acts on it.
    func clearPendingProposal() {
        pendingProposal = nil
    }

    /// Returns a recently detected workout that hasn't been confirmed by the user
    func getUnconfirmedDetectedWorkout() async -> DetectedWorkout? {
        return unconfirmedWorkout
    }

    /// Clears the unconfirmed workout after user confirms or dismisses.
    func clearUnconfirmedWorkout() {
        unconfirmedWorkout = nil
    }

    // MARK: - Workout Generation

    private func generateWorkout(for window: TimeWindow) async throws -> GeneratedWorkout {
        // Use local template engine for most cases
        // Fall back to API for complex/edge cases

        let preferences = await phenomeCoordinator.workoutPreferences
        let recentHistory = await phenomeCoordinator.getRecentWorkoutHistory(days: 7)

        // Try local generation first
        if let localWorkout = await LocalWorkoutGenerator.shared.generate(
            window: window,
            preferences: preferences,
            recentHistory: recentHistory
        ) {
            return localWorkout
        }

        // Fall back to API
        return try await VigorAPIClient.shared.generateWorkout(
            window: window,
            preferences: preferences,
            phenomeSnapshot: await phenomeCoordinator.anonymizedSnapshot()
        )
    }

    // MARK: - Health Mode Handling

    private func handleHealthModeChange(_ mode: GhostHealthMode) async {
        switch mode {
        case .healthy:
            // Resume normal operations
            break

        case .degraded:
            // Reduce cycle frequency, increase error tolerance
            break

        case .safeMode:
            // Minimal operations only
            break

        case .suspended:
            // Stop all operations
            await stop()
        }
    }

    // MARK: - Background Tasks

    private func scheduleBackgroundTasks() {
        // Schedule morning cycle for 6 AM
        scheduleMorningCycleTask()

        // Schedule evening cycle for 9 PM
        scheduleEveningCycleTask()
    }

    private func scheduleMorningCycleTask() {
        let request = BGProcessingTaskRequest(identifier: BackgroundTaskIdentifiers.morningCycle)

        // Schedule for 6 AM tomorrow
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 6
        components.minute = 0

        if let scheduledDate = calendar.date(from: components) {
            let targetDate = scheduledDate < Date()
                ? calendar.date(byAdding: .day, value: 1, to: scheduledDate)!
                : scheduledDate
            request.earliestBeginDate = targetDate
        }

        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // BGTaskScheduler may fail - Ghost degrades gracefully
            Task {
                await healthMonitor.reportBackgroundTaskSchedulingFailure(error: error)
            }
        }
    }

    private func scheduleEveningCycleTask() {
        let request = BGProcessingTaskRequest(identifier: BackgroundTaskIdentifiers.eveningCycle)

        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 21
        components.minute = 0

        if let scheduledDate = calendar.date(from: components) {
            let targetDate = scheduledDate < Date()
                ? calendar.date(byAdding: .day, value: 1, to: scheduledDate)!
                : scheduledDate
            request.earliestBeginDate = targetDate
        }

        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            Task {
                await healthMonitor.reportBackgroundTaskSchedulingFailure(error: error)
            }
        }
    }

    private func runImmediateCycleIfNeeded() async {
        let now = Date()
        let hour = calendar.component(.hour, from: now)

        // If it's morning (6-10 AM) and we haven't run morning cycle today
        if hour >= 6 && hour < 10 {
            if !isSameDay(lastMorningCycle, now) {
                await executeMorningCycle()
            }
        }

        // If it's Sunday evening, run Sunday cycle
        if calendar.component(.weekday, from: now) == 1 && hour >= 18 {
            await executeSundayEveningCycle()
        }
    }

    private func isSameDay(_ date1: Date?, _ date2: Date) -> Bool {
        guard let date1 = date1 else { return false }
        return calendar.isDate(date1, inSameDayAs: date2)
    }

    // MARK: - State Persistence

    func saveStateForTermination() async {
        // Save any pending state before iOS terminates the background task
        await phenomeCoordinator.savePendingChanges()
        await decisionReceiptStore.flush()
    }
}

// MARK: - Supporting Types

enum BlockTransformation: CustomStringConvertible {
    case none
    case remove
    case transformTo(WorkoutType)

    var description: String {
        switch self {
        case .none: return "none"
        case .remove: return "remove"
        case .transformTo(let type): return "transformTo(\(type.rawValue))"
        }
    }
}

struct MissedBlockTriageRequest: Identifiable {
    let id = UUID()
    let blockId: String
    let blockTime: Date
    let workoutType: WorkoutType
}

struct TimeWindow {
    let start: Date
    let end: Date

    var duration: TimeInterval {
        end.timeIntervalSince(start)
    }
}
