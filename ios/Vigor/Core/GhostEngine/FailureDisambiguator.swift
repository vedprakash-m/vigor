//
//  FailureDisambiguator.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Distinguishes "bad schedule" from "life happened" when workouts are missed.
//  Without disambiguation, Ghost learns wrong patterns.
//
//  Per Tech Spec §2.13
//

import Foundation

actor FailureDisambiguator {

    // MARK: - Singleton

    static let shared = FailureDisambiguator()

    // MARK: - Storage

    private var pendingTriages: [String: PendingTriage] = [:]
    private var timeSlotPenalties: [TimeSlotKey: Int] = [:]

    // MARK: - Constants

    private let triageExpirationHours: Double = 24
    private let maxTriagesPerDay: Int = 1
    private var triagesTodayCount: Int = 0
    private var lastTriageDate: Date?

    // MARK: - Initialization

    private init() {}

    // MARK: - Missed Block Processing

    /// Called when a scheduled block passes without workout detection
    func processMissedBlock(_ block: TrainingBlock) async -> TriageResult {
        // Check if we already have a pending triage
        if pendingTriages[block.id] != nil {
            return .alreadyPending
        }

        // Check daily triage limit
        if isAtDailyTriageLimit() {
            // Silently record as unknown
            await recordReason(for: block.id, reason: .unknown)
            return .skippedDueToLimit
        }

        // Attempt automatic disambiguation
        if let autoReason = await attemptAutomaticDisambiguation(block) {
            await recordReason(for: block.id, reason: autoReason)
            return .automaticallyResolved(autoReason)
        }

        // Queue for manual triage
        let triage = PendingTriage(
            blockId: block.id,
            blockTime: block.startTime,
            workoutType: block.workoutType,
            createdAt: Date()
        )
        pendingTriages[block.id] = triage

        return .requiresManualTriage
    }

    // MARK: - Automatic Disambiguation

    private func attemptAutomaticDisambiguation(_ block: TrainingBlock) async -> MissedWorkoutReason? {
        // Check 1: Time slot has been deleted multiple times
        let timeSlotKey = TimeSlotKey(from: block.startTime)
        if let penalties = timeSlotPenalties[timeSlotKey], penalties >= 2 {
            // This time slot has been problematic before
            return .badTimeSlot
        }

        // Check 2: Sleep data suggests exhaustion
        if let sleepHours = await getSleepHoursForDay(block.startTime) {
            if sleepHours < 5 {
                return .tooTired
            }
        }

        // Check 3: Calendar had unusual activity (many meetings)
        if await wasUnusuallyBusyDay(block.startTime) {
            return .lifeHappened
        }

        // Can't determine automatically
        return nil
    }

    // MARK: - Manual Triage

    func recordTriageResponse(blockId: String, reason: MissedWorkoutReason) async {
        guard let triage = pendingTriages[blockId] else { return }

        await recordReason(for: blockId, reason: reason)

        pendingTriages.removeValue(forKey: blockId)
        triagesTodayCount += 1
        lastTriageDate = Date()
    }

    private func recordReason(for blockId: String, reason: MissedWorkoutReason) async {
        // Get the block details
        guard let block = await CalendarScheduler.shared.getBlock(by: blockId) else { return }

        // Update time slot penalties if applicable
        if reason.shouldPenalizeTimeSlot {
            let key = TimeSlotKey(from: block.startTime)
            timeSlotPenalties[key, default: 0] += 1
        }

        // Record in Phenome for pattern learning
        await PhenomeCoordinator.shared.recordMissedWorkoutReason(
            blockId: blockId,
            reason: reason
        )

        // Update trust with disambiguation context
        await TrustStateMachine.shared.recordEvent(.triageResponded(reason))

        // Store decision receipt
        var receipt = DecisionReceipt(action: .triageRecorded)
        receipt.addInput("block_id", value: blockId)
        receipt.addInput("reason", value: reason.rawValue)
        receipt.addInput("was_automatic", value: false)
        receipt.confidence = 1.0
        receipt.outcome = .success
        await DecisionReceiptStore.shared.store(receipt)
    }

    // MARK: - Helpers

    private func isAtDailyTriageLimit() -> Bool {
        guard let lastDate = lastTriageDate else { return false }

        let calendar = Calendar.current
        if calendar.isDateInToday(lastDate) {
            return triagesTodayCount >= maxTriagesPerDay
        } else {
            // Reset daily counter
            triagesTodayCount = 0
            return false
        }
    }

    private func getSleepHoursForDay(_ date: Date) async -> Double? {
        // Query HealthKit for sleep data
        return await HealthKitObserver.shared.getSleepHours(for: date)
    }

    private func wasUnusuallyBusyDay(_ date: Date) async -> Bool {
        // Query calendar for meeting density
        let meetings = await CalendarScheduler.shared.getMeetingCount(for: date)
        let averageMeetings = await CalendarScheduler.shared.getAverageDailyMeetings()

        return Double(meetings) > averageMeetings * 1.5
    }

    // MARK: - Cleanup

    func cleanupExpiredTriages() async {
        let cutoff = Date().addingTimeInterval(-triageExpirationHours * 3600)

        for (id, triage) in pendingTriages {
            if triage.createdAt < cutoff {
                // Expired - record as unknown
                await recordReason(for: id, reason: .unknown)
                pendingTriages.removeValue(forKey: id)
            }
        }
    }

    // MARK: - Time Slot Analysis

    func getProblematicTimeSlots() async -> [TimeSlotKey] {
        return timeSlotPenalties
            .filter { $0.value >= 3 }
            .map { $0.key }
    }

    func isTimeSlotProblematic(_ date: Date) async -> Bool {
        let key = TimeSlotKey(from: date)
        return (timeSlotPenalties[key] ?? 0) >= 3
    }
}

// MARK: - Supporting Types

struct PendingTriage {
    let blockId: String
    let blockTime: Date
    let workoutType: WorkoutType
    let createdAt: Date
}

enum TriageResult {
    case alreadyPending
    case skippedDueToLimit
    case automaticallyResolved(MissedWorkoutReason)
    case requiresManualTriage
}

struct TimeSlotKey: Hashable, Codable {
    let dayOfWeek: Int      // 1-7 (Sunday-Saturday)
    let hourOfDay: Int      // 0-23

    init(from date: Date) {
        let calendar = Calendar.current
        self.dayOfWeek = calendar.component(.weekday, from: date)
        self.hourOfDay = calendar.component(.hour, from: date)
    }

    var displayString: String {
        let days = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let dayName = days[dayOfWeek]
        let hourString = hourOfDay < 12 ? "\(hourOfDay)AM" : "\(hourOfDay - 12)PM"
        return "\(dayName) \(hourString)"
    }
}
