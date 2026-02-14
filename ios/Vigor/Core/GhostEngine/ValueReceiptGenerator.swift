//
//  ValueReceiptGenerator.swift
//  Vigor
//
//  Generates weekly Value Receipts summarizing Ghost activity.
//  Per PRD §3.3: Shows "what Ghost did this week" with tangible proof of value.
//

import Foundation

@MainActor
final class ValueReceiptGenerator {
    static let shared = ValueReceiptGenerator()
    private init() {}

    func generate(
        phenome: PhenomeCoordinator,
        trustState: TrustStateMachine,
        receipts: DecisionReceiptStore
    ) async -> ValueReceipt {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? now

        // Gather workout data for the week
        let weekWorkouts = await phenome.getRecentWorkoutHistory(days: 7)
        let completed = weekWorkouts.count

        // Get decision receipts for the week to count scheduled & missed
        let weekReceipts = await receipts.getRecentReceipts(days: 7)
        let scheduled = weekReceipts.filter { $0.action == .blockCreated }.count
        let missed = weekReceipts.filter { $0.action == .triageRecorded || $0.action == .blockRemoved }.count

        // Total workout minutes
        let totalMinutes = Int(weekWorkouts.reduce(0.0) { $0 + $1.duration } / 60)

        // Estimate time saved: scheduling + rescheduling decisions
        let decisions = weekReceipts.count
        let timeSavedMinutes = decisions * 3 // ~3 min saved per autonomous decision

        // Patterns discovered
        let patterns = discoverPatterns(from: weekReceipts)

        // Trust progress
        let trustProgress = trustState.currentPhase != .observer
            ? "Progressed to \(trustState.currentPhase.displayName) level"
            : nil

        // Current streak
        let streak = calculateStreak(workouts: weekWorkouts)

        return ValueReceipt(
            weekStartDate: weekStart,
            weekEndDate: min(weekEnd, now),
            completedWorkouts: completed,
            scheduledWorkouts: max(scheduled, completed),
            missedWorkouts: missed,
            totalMinutes: totalMinutes,
            timeSavedMinutes: timeSavedMinutes,
            patternsDiscovered: patterns,
            trustProgress: trustProgress,
            streak: streak
        )
    }

    // MARK: - Pattern Discovery

    private func discoverPatterns(from receipts: [DecisionReceipt]) -> [String] {
        var patterns: [String] = []

        // Check for morning cycle adjustments
        let morningCycles = receipts.filter { $0.action == .morningCycle }
        if morningCycles.count >= 3 {
            patterns.append("Established consistent morning check-in routine")
        }

        // Check for rescheduling success
        let transforms = receipts.filter { $0.action == .blockTransformed }
        if !transforms.isEmpty {
            patterns.append("Adapted \(transforms.count) workout(s) based on your recovery")
        }

        // Check for trust advancement
        let trustAdvances = receipts.filter { $0.action == .trustAdvanced }
        if !trustAdvances.isEmpty {
            patterns.append("Earned more autonomy through consistent engagement")
        }

        if patterns.isEmpty {
            patterns.append("Building your baseline patterns — more insights coming soon")
        }

        return patterns
    }

    // MARK: - Streak Calculation

    private func calculateStreak(workouts: [DetectedWorkout]) -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        for _ in 0..<30 {
            let dayWorkouts = workouts.filter { calendar.isDate($0.startDate, inSameDayAs: checkDate) }
            if dayWorkouts.isEmpty { break }
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }

        return streak
    }
}
