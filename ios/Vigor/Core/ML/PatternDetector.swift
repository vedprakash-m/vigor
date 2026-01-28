//
//  PatternDetector.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Detect behavioral patterns for scheduling optimization.
//  Per PRD §4.2: Pattern detection enables predictive scheduling.
//

import Foundation

actor PatternDetector {

    // MARK: - Singleton

    static let shared = PatternDetector()

    // MARK: - Configuration

    private let minDataPointsForPattern = 4
    private let significantPatternThreshold = 0.7
    private let analysisWindowDays = 30

    // MARK: - Detected Patterns

    private var cachedPatterns: UserBehaviorPatterns?
    private var lastAnalysis: Date?
    private let cacheValidityDuration: TimeInterval = 6 * 3600  // 6 hours

    // MARK: - Initialization

    private init() {}

    // MARK: - Analyze Patterns

    func analyzePatterns() async -> UserBehaviorPatterns {
        // Check cache
        if let cached = cachedPatterns,
           let lastCheck = lastAnalysis,
           Date().timeIntervalSince(lastCheck) < cacheValidityDuration {
            return cached
        }

        // Gather data
        let workoutHistory = await BehavioralMemoryStore.shared.getRecentWorkouts(days: analysisWindowDays)
        let timeSlotHistory = await BehavioralMemoryStore.shared.getAllTimeSlotStats()

        // Analyze each pattern type
        let weekdayPatterns = analyzeWeekdayPatterns(from: workoutHistory)
        let timeOfDayPatterns = analyzeTimeOfDayPatterns(from: workoutHistory, slots: timeSlotHistory)
        let workoutTypePatterns = analyzeWorkoutTypePatterns(from: workoutHistory)
        let skipPatterns = analyzeSkipPatterns(from: workoutHistory)
        let streakPatterns = analyzeStreakPatterns(from: workoutHistory)
        let recoveryPatterns = await analyzeRecoveryPatterns()

        let patterns = UserBehaviorPatterns(
            weekdayPatterns: weekdayPatterns,
            timeOfDayPatterns: timeOfDayPatterns,
            workoutTypePatterns: workoutTypePatterns,
            skipPatterns: skipPatterns,
            streakPatterns: streakPatterns,
            recoveryPatterns: recoveryPatterns,
            analysisDate: Date(),
            dataPointCount: workoutHistory.count
        )

        // Cache results
        cachedPatterns = patterns
        lastAnalysis = Date()

        return patterns
    }

    // MARK: - Weekday Patterns

    private func analyzeWeekdayPatterns(from workouts: [WorkoutRecord]) -> WeekdayPatterns {
        var dayStats: [Int: DayStats] = [:]

        for day in 1...7 {
            dayStats[day] = DayStats()
        }

        for workout in workouts {
            let day = Calendar.current.component(.weekday, from: workout.date)
            dayStats[day]?.totalScheduled += 1
            if workout.completed {
                dayStats[day]?.completed += 1
            }
        }

        // Find best and worst days
        var bestDays: [Int] = []
        var worstDays: [Int] = []

        for (day, stats) in dayStats where stats.totalScheduled >= minDataPointsForPattern {
            let rate = Double(stats.completed) / Double(stats.totalScheduled)
            if rate >= significantPatternThreshold {
                bestDays.append(day)
            } else if rate < 0.4 {
                worstDays.append(day)
            }
        }

        return WeekdayPatterns(
            bestDays: bestDays.sorted(),
            worstDays: worstDays.sorted(),
            completionByDay: dayStats.mapValues { stats in
                stats.totalScheduled > 0 ? Double(stats.completed) / Double(stats.totalScheduled) : nil
            }
        )
    }

    // MARK: - Time of Day Patterns

    private func analyzeTimeOfDayPatterns(
        from workouts: [WorkoutRecord],
        slots: [TimeSlotKey: TimeSlotStats]
    ) -> TimeOfDayPatterns {
        // Categorize hours into periods
        let morningHours = 5...9
        let middayHours = 10...14
        let eveningHours = 15...21

        var morningSuccess = 0
        var morningTotal = 0
        var middaySuccess = 0
        var middayTotal = 0
        var eveningSuccess = 0
        var eveningTotal = 0

        for workout in workouts {
            let hour = Calendar.current.component(.hour, from: workout.date)

            if morningHours.contains(hour) {
                morningTotal += 1
                if workout.completed { morningSuccess += 1 }
            } else if middayHours.contains(hour) {
                middayTotal += 1
                if workout.completed { middaySuccess += 1 }
            } else if eveningHours.contains(hour) {
                eveningTotal += 1
                if workout.completed { eveningSuccess += 1 }
            }
        }

        // Determine preferred period
        let rates: [(TimeOfDayPeriod, Double, Int)] = [
            (.morning, morningTotal > 0 ? Double(morningSuccess) / Double(morningTotal) : 0, morningTotal),
            (.midday, middayTotal > 0 ? Double(middaySuccess) / Double(middayTotal) : 0, middayTotal),
            (.evening, eveningTotal > 0 ? Double(eveningSuccess) / Double(eveningTotal) : 0, eveningTotal)
        ]

        let significantRates = rates.filter { $0.2 >= minDataPointsForPattern }
        let preferredPeriod = significantRates.max { $0.1 < $1.1 }?.0

        // Find peak hours from slot data
        let peakHours = slots
            .filter { $0.value.totalAttempts >= minDataPointsForPattern }
            .sorted { ($0.value.completedCount / max(1, $0.value.totalAttempts)) > ($1.value.completedCount / max(1, $1.value.totalAttempts)) }
            .prefix(3)
            .map { $0.key.hourOfDay }

        return TimeOfDayPatterns(
            preferredPeriod: preferredPeriod,
            morningCompletionRate: morningTotal > 0 ? Double(morningSuccess) / Double(morningTotal) : nil,
            middayCompletionRate: middayTotal > 0 ? Double(middaySuccess) / Double(middayTotal) : nil,
            eveningCompletionRate: eveningTotal > 0 ? Double(eveningSuccess) / Double(eveningTotal) : nil,
            peakPerformanceHours: Array(peakHours)
        )
    }

    // MARK: - Workout Type Patterns

    private func analyzeWorkoutTypePatterns(from workouts: [WorkoutRecord]) -> WorkoutTypePatterns {
        var typeStats: [String: (completed: Int, total: Int)] = [:]

        for workout in workouts {
            let type = workout.workoutType
            var stats = typeStats[type] ?? (0, 0)
            stats.total += 1
            if workout.completed {
                stats.completed += 1
            }
            typeStats[type] = stats
        }

        // Find most completed and most skipped types
        var completionRates: [(String, Double)] = []

        for (type, stats) in typeStats where stats.total >= minDataPointsForPattern {
            let rate = Double(stats.completed) / Double(stats.total)
            completionRates.append((type, rate))
        }

        completionRates.sort { $0.1 > $1.1 }

        return WorkoutTypePatterns(
            preferredTypes: completionRates.filter { $0.1 >= 0.7 }.map { $0.0 },
            avoidedTypes: completionRates.filter { $0.1 < 0.4 }.map { $0.0 },
            completionByType: typeStats.mapValues { stats in
                stats.total > 0 ? Double(stats.completed) / Double(stats.total) : nil
            }
        )
    }

    // MARK: - Skip Patterns

    private func analyzeSkipPatterns(from workouts: [WorkoutRecord]) -> SkipPatterns {
        let skippedWorkouts = workouts.filter { !$0.completed }

        guard skippedWorkouts.count >= minDataPointsForPattern else {
            return SkipPatterns(
                commonSkipDays: [],
                commonSkipHours: [],
                skipAfterHardWorkout: false,
                skipOnBusyDays: false,
                averageSkipStreak: 0
            )
        }

        // Analyze skip days
        var skipDayCount: [Int: Int] = [:]
        var skipHourCount: [Int: Int] = [:]

        for workout in skippedWorkouts {
            let day = Calendar.current.component(.weekday, from: workout.date)
            let hour = Calendar.current.component(.hour, from: workout.date)
            skipDayCount[day, default: 0] += 1
            skipHourCount[hour, default: 0] += 1
        }

        let totalSkips = skippedWorkouts.count
        let commonSkipDays = skipDayCount
            .filter { Double($0.value) / Double(totalSkips) > 0.3 }
            .map { $0.key }

        let commonSkipHours = skipHourCount
            .filter { Double($0.value) / Double(totalSkips) > 0.3 }
            .map { $0.key }

        // Analyze skip streaks
        var currentStreak = 0
        var totalStreaks = 0
        var streakCount = 0

        for workout in workouts.sorted(by: { $0.date < $1.date }) {
            if workout.completed {
                if currentStreak > 0 {
                    totalStreaks += currentStreak
                    streakCount += 1
                }
                currentStreak = 0
            } else {
                currentStreak += 1
            }
        }

        let averageSkipStreak = streakCount > 0 ? Double(totalStreaks) / Double(streakCount) : 0

        return SkipPatterns(
            commonSkipDays: commonSkipDays.sorted(),
            commonSkipHours: commonSkipHours.sorted(),
            skipAfterHardWorkout: false,  // Would need intensity data
            skipOnBusyDays: false,  // Would need calendar correlation
            averageSkipStreak: averageSkipStreak
        )
    }

    // MARK: - Streak Patterns

    private func analyzeStreakPatterns(from workouts: [WorkoutRecord]) -> StreakPatterns {
        let sortedWorkouts = workouts.sorted { $0.date < $1.date }

        var currentStreak = 0
        var longestStreak = 0
        var streakLengths: [Int] = []

        for workout in sortedWorkouts {
            if workout.completed {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                if currentStreak > 0 {
                    streakLengths.append(currentStreak)
                }
                currentStreak = 0
            }
        }

        // Add final streak if exists
        if currentStreak > 0 {
            streakLengths.append(currentStreak)
        }

        let averageStreak = streakLengths.isEmpty ? 0 : Double(streakLengths.reduce(0, +)) / Double(streakLengths.count)

        // Calculate current streak
        var activeStreak = 0
        for workout in sortedWorkouts.reversed() {
            if workout.completed {
                activeStreak += 1
            } else {
                break
            }
        }

        return StreakPatterns(
            currentStreak: activeStreak,
            longestStreak: longestStreak,
            averageStreakLength: averageStreak,
            streaksAboveFive: streakLengths.filter { $0 >= 5 }.count
        )
    }

    // MARK: - Recovery Patterns

    private func analyzeRecoveryPatterns() async -> RecoveryPatterns {
        // Get recovery history
        let recoveryHistory = await DerivedStateStore.shared.getRecoveryHistory(days: analysisWindowDays)

        guard !recoveryHistory.isEmpty else {
            return RecoveryPatterns(
                averageRecoveryScore: 0.7,
                recoveryVariability: .low,
                typicalRecoveryDays: 1,
                sensitiveToSleep: false,
                sensitiveToStrain: false
            )
        }

        // Calculate average and variability
        let scores = recoveryHistory.map { $0.score }
        let average = scores.reduce(0.0, +) / Double(scores.count)
        let variance = scores.map { pow($0 - average, 2) }.reduce(0.0, +) / Double(scores.count)
        let standardDeviation = sqrt(variance)

        let variability: RecoveryVariability
        switch standardDeviation {
        case 0..<0.1: variability = .low
        case 0.1..<0.2: variability = .moderate
        default: variability = .high
        }

        return RecoveryPatterns(
            averageRecoveryScore: average,
            recoveryVariability: variability,
            typicalRecoveryDays: 1,  // Would need more analysis
            sensitiveToSleep: false,  // Would need correlation analysis
            sensitiveToStrain: false
        )
    }

    // MARK: - Pattern Insights

    func getSchedulingInsights() async -> [PatternInsight] {
        let patterns = await analyzePatterns()
        var insights: [PatternInsight] = []

        // Best days insight
        if !patterns.weekdayPatterns.bestDays.isEmpty {
            let dayNames = patterns.weekdayPatterns.bestDays.compactMap { dayName(for: $0) }
            insights.append(PatternInsight(
                type: .positive,
                category: .scheduling,
                title: "Best Workout Days",
                description: "You're most consistent on \(dayNames.joined(separator: ", "))",
                actionable: "Consider prioritizing workouts on these days"
            ))
        }

        // Preferred time insight
        if let preferred = patterns.timeOfDayPatterns.preferredPeriod {
            insights.append(PatternInsight(
                type: .positive,
                category: .timing,
                title: "\(preferred.rawValue.capitalized) Person",
                description: "You complete more workouts in the \(preferred.rawValue)",
                actionable: "Ghost will prioritize \(preferred.rawValue) slots for you"
            ))
        }

        // Skip patterns insight
        if !patterns.skipPatterns.commonSkipDays.isEmpty {
            let dayNames = patterns.skipPatterns.commonSkipDays.compactMap { dayName(for: $0) }
            insights.append(PatternInsight(
                type: .warning,
                category: .scheduling,
                title: "Common Skip Days",
                description: "You tend to skip on \(dayNames.joined(separator: ", "))",
                actionable: "Consider lighter workouts or rest days"
            ))
        }

        // Streak insight
        if patterns.streakPatterns.longestStreak >= 7 {
            insights.append(PatternInsight(
                type: .positive,
                category: .motivation,
                title: "Strong Consistency",
                description: "Your longest streak is \(patterns.streakPatterns.longestStreak) workouts!",
                actionable: "Keep building on this momentum"
            ))
        }

        return insights
    }

    private func dayName(for weekday: Int) -> String? {
        let formatter = DateFormatter()
        guard weekday >= 1 && weekday <= 7 else { return nil }
        return formatter.weekdaySymbols[weekday - 1]
    }
}

// MARK: - Pattern Data Structures

struct UserBehaviorPatterns {
    let weekdayPatterns: WeekdayPatterns
    let timeOfDayPatterns: TimeOfDayPatterns
    let workoutTypePatterns: WorkoutTypePatterns
    let skipPatterns: SkipPatterns
    let streakPatterns: StreakPatterns
    let recoveryPatterns: RecoveryPatterns
    let analysisDate: Date
    let dataPointCount: Int

    var hasEnoughData: Bool { dataPointCount >= 10 }
}

struct WeekdayPatterns {
    let bestDays: [Int]  // 1-7 (Sunday-Saturday)
    let worstDays: [Int]
    let completionByDay: [Int: Double?]
}

struct TimeOfDayPatterns {
    let preferredPeriod: TimeOfDayPeriod?
    let morningCompletionRate: Double?
    let middayCompletionRate: Double?
    let eveningCompletionRate: Double?
    let peakPerformanceHours: [Int]
}

enum TimeOfDayPeriod: String {
    case morning, midday, evening
}

struct WorkoutTypePatterns {
    let preferredTypes: [String]
    let avoidedTypes: [String]
    let completionByType: [String: Double?]
}

struct SkipPatterns {
    let commonSkipDays: [Int]
    let commonSkipHours: [Int]
    let skipAfterHardWorkout: Bool
    let skipOnBusyDays: Bool
    let averageSkipStreak: Double
}

struct StreakPatterns {
    let currentStreak: Int
    let longestStreak: Int
    let averageStreakLength: Double
    let streaksAboveFive: Int
}

struct RecoveryPatterns {
    let averageRecoveryScore: Double
    let recoveryVariability: RecoveryVariability
    let typicalRecoveryDays: Int
    let sensitiveToSleep: Bool
    let sensitiveToStrain: Bool
}

enum RecoveryVariability: String {
    case low, moderate, high
}

struct PatternInsight {
    let type: InsightType
    let category: InsightCategory
    let title: String
    let description: String
    let actionable: String
}

enum InsightType {
    case positive, warning, info
}

enum InsightCategory {
    case scheduling, timing, motivation, recovery
}

// MARK: - Helper Types

private struct DayStats {
    var completed: Int = 0
    var totalScheduled: Int = 0
}

struct RecoveryRecord {
    let date: Date
    let score: Double
}

// MARK: - Store Extensions

extension BehavioralMemoryStore {
    func getRecentWorkouts(days: Int) async -> [WorkoutRecord] {
        []
    }

    func getAllTimeSlotStats() async -> [TimeSlotKey: TimeSlotStats] {
        [:]
    }
}

extension DerivedStateStore {
    func getRecoveryHistory(days: Int) async -> [RecoveryRecord] {
        []
    }
}
