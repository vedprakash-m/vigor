//
//  FirstInsightGenerator.swift
//  Vigor
//
//  Created by Vigor Team on February 15, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Generates the "Absolution Moment" — a personalized first insight from
//  imported HealthKit data, delivered within 5 minutes of install.
//  Per PRD §5.1, UX Spec §5.2.
//
//  Analyzes 90 days of imported data to surface:
//  - Sleep pattern insights
//  - Workout consistency & gaps
//  - Recovery trends
//  - Optimal workout window for tomorrow
//

import Foundation
import SwiftUI

// MARK: - First Insight Model

struct FirstInsight: Identifiable, Codable {
    let id: UUID
    let headline: String
    let detail: String
    let dataPoint: String
    let category: FirstInsightCategory
    let generatedAt: Date

    init(headline: String, detail: String, dataPoint: String, category: FirstInsightCategory) {
        self.id = UUID()
        self.headline = headline
        self.detail = detail
        self.dataPoint = dataPoint
        self.category = category
        self.generatedAt = Date()
    }
}

enum FirstInsightCategory: String, Codable {
    case sleep
    case workout
    case recovery
    case schedule
}

struct FirstInsightBundle: Codable {
    let primaryInsight: FirstInsight
    let supportingInsights: [FirstInsight]
    let suggestedWorkoutWindow: SuggestedWindow?
    let dataQuality: DataQuality

    /// A summary sentence for the onboarding screen
    var summaryLine: String {
        switch dataQuality {
        case .rich:
            return "Based on \(dataQuality.description), here's what the Ghost already knows."
        case .moderate:
            return "The Ghost found enough data to start helping you today."
        case .minimal:
            return "The Ghost is ready. Your first suggestion is below."
        }
    }
}

struct SuggestedWindow: Codable {
    let date: Date
    let startTime: Date
    let durationMinutes: Int
    let workoutType: String
    let confidence: Double

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: startTime)
    }

    var formattedDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        }
        return formatter.string(from: date)
    }
}

enum DataQuality: String, Codable {
    case rich       // ≥10 workouts AND ≥14 sleep records
    case moderate   // ≥3 workouts OR ≥7 sleep records
    case minimal    // Less than moderate

    var description: String {
        switch self {
        case .rich: return "90 days of health data"
        case .moderate: return "recent health data"
        case .minimal: return "initial data"
        }
    }
}

// MARK: - Generator

@MainActor
final class FirstInsightGenerator {

    static let shared = FirstInsightGenerator()

    private var cachedBundle: FirstInsightBundle?

    // MARK: - Public API

    /// Generate the first insight bundle from imported data.
    /// Returns cached result if already generated for this session.
    func generateInsights() async -> FirstInsightBundle {
        if let cached = cachedBundle { return cached }

        let sleepData = await RawSignalStore.shared.getRecentSleep(days: 90)
        let hrvData = await RawSignalStore.shared.getRecentHRV(days: 90)
        let workouts = await RawSignalStore.shared.getRecentWorkouts(days: 90)
        let restingHR = await RawSignalStore.shared.getRecentRestingHR(days: 90)

        let quality = assessDataQuality(
            sleepCount: sleepData.count,
            workoutCount: workouts.count
        )

        var insights: [FirstInsight] = []

        // Sleep insight
        if let sleepInsight = analyzeSleep(sleepData) {
            insights.append(sleepInsight)
        }

        // Workout consistency insight
        if let workoutInsight = analyzeWorkoutConsistency(workouts) {
            insights.append(workoutInsight)
        }

        // Recovery trend insight
        if let recoveryInsight = analyzeRecovery(hrvData: hrvData, restingHR: restingHR) {
            insights.append(recoveryInsight)
        }

        // Schedule gap insight
        if let scheduleInsight = analyzeWorkoutTiming(workouts) {
            insights.append(scheduleInsight)
        }

        // Find tomorrow's optimal window
        let suggestedWindow = await findFirstWorkoutWindow()

        // Pick primary and supporting
        let primary = insights.first ?? defaultInsight()
        let supporting = Array(insights.dropFirst().prefix(2))

        let bundle = FirstInsightBundle(
            primaryInsight: primary,
            supportingInsights: supporting,
            suggestedWorkoutWindow: suggestedWindow,
            dataQuality: quality
        )

        cachedBundle = bundle
        return bundle
    }

    /// Clear cached insights (e.g., on re-onboarding)
    func reset() {
        cachedBundle = nil
    }

    // MARK: - Data Quality

    private func assessDataQuality(sleepCount: Int, workoutCount: Int) -> DataQuality {
        if workoutCount >= 10 && sleepCount >= 14 {
            return .rich
        } else if workoutCount >= 3 || sleepCount >= 7 {
            return .moderate
        } else {
            return .minimal
        }
    }

    // MARK: - Sleep Analysis

    private func analyzeSleep(_ sleepData: [SleepData]) -> FirstInsight? {
        guard sleepData.count >= 3 else { return nil }

        let totalHours = sleepData.map { $0.totalHours }
        let avgSleep = totalHours.reduce(0.0, +) / Double(totalHours.count)

        // Find best/worst nights
        let sorted = sleepData.sorted(by: { $0.totalHours > $1.totalHours })
        let bestNight = sorted.first

        let avgFormatted = String(format: "%.1f", avgSleep)

        if avgSleep < 6.5 {
            return FirstInsight(
                headline: "Your sleep needs attention",
                detail: "You averaged \(avgFormatted) hours over the past \(sleepData.count) nights. The Ghost will avoid scheduling workouts after short sleep nights.",
                dataPoint: "\(avgFormatted)h avg sleep",
                category: .sleep
            )
        } else if avgSleep >= 7.5 {
            return FirstInsight(
                headline: "Strong sleep foundation",
                detail: "Averaging \(avgFormatted) hours per night. Your recovery capacity supports consistent training.",
                dataPoint: "\(avgFormatted)h avg sleep",
                category: .sleep
            )
        } else {
            return FirstInsight(
                headline: "Solid sleep, room to improve",
                detail: "Averaging \(avgFormatted)h per night. On your best nights you hit \(String(format: "%.1f", bestNight?.totalHours ?? 0))h. The Ghost factors this into workout timing.",
                dataPoint: "\(avgFormatted)h avg sleep",
                category: .sleep
            )
        }
    }

    // MARK: - Workout Consistency

    private func analyzeWorkoutConsistency(_ workouts: [DetectedWorkout]) -> FirstInsight? {
        guard workouts.count >= 2 else {
            if workouts.isEmpty {
                return FirstInsight(
                    headline: "Fresh start",
                    detail: "No recent workout history found. The Ghost will start with gentle suggestions and build from there.",
                    dataPoint: "0 workouts / 90 days",
                    category: .workout
                )
            }
            return nil
        }

        let weeksOfData = max(1, Calendar.current.dateComponents([.weekOfYear], from: workouts.last!.startDate, to: Date()).weekOfYear ?? 1)
        let workoutsPerWeek = Double(workouts.count) / Double(weeksOfData)

        // Find gaps > 7 days
        let sortedByDate = workouts.sorted(by: { $0.startDate < $1.startDate })
        var maxGapDays = 0
        for i in 1..<sortedByDate.count {
            let gap = Calendar.current.dateComponents([.day], from: sortedByDate[i-1].startDate, to: sortedByDate[i].startDate).day ?? 0
            maxGapDays = max(maxGapDays, gap)
        }

        let wpwFormatted = String(format: "%.1f", workoutsPerWeek)

        if workoutsPerWeek >= 4.0 {
            return FirstInsight(
                headline: "You're consistently active",
                detail: "\(wpwFormatted) workouts per week over \(weeksOfData) weeks. The Ghost will optimize when you train, not how often.",
                dataPoint: "\(wpwFormatted)/week",
                category: .workout
            )
        } else if workoutsPerWeek >= 2.0 {
            if maxGapDays > 10 {
                return FirstInsight(
                    headline: "Good base, some gaps",
                    detail: "\(wpwFormatted) workouts per week, but your longest gap was \(maxGapDays) days. The Ghost will help maintain consistency.",
                    dataPoint: "\(wpwFormatted)/week • \(maxGapDays)d max gap",
                    category: .workout
                )
            }
            return FirstInsight(
                headline: "Solid workout habit",
                detail: "\(wpwFormatted) workouts per week over \(weeksOfData) weeks. The Ghost will protect this momentum.",
                dataPoint: "\(wpwFormatted)/week",
                category: .workout
            )
        } else {
            return FirstInsight(
                headline: "Building a habit",
                detail: "\(wpwFormatted) workouts per week. The Ghost will place small, achievable blocks to build consistency.",
                dataPoint: "\(wpwFormatted)/week",
                category: .workout
            )
        }
    }

    // MARK: - Recovery Analysis

    private func analyzeRecovery(hrvData: [HRVData], restingHR: [Int]) -> FirstInsight? {
        guard hrvData.count >= 5 else { return nil }

        let avgHRV = hrvData.map { $0.averageHRV }.reduce(0.0, +) / Double(hrvData.count)
        let avgHRVFormatted = String(format: "%.0f", avgHRV)

        // HRV trend (recent 7 days vs. overall)
        let recentHRV = hrvData.prefix(7).map { $0.averageHRV }
        let recentAvg = recentHRV.isEmpty ? avgHRV : recentHRV.reduce(0.0, +) / Double(recentHRV.count)

        let trendPct = ((recentAvg - avgHRV) / avgHRV) * 100

        if trendPct > 10 {
            return FirstInsight(
                headline: "Recovery trending up",
                detail: "Your HRV is \(String(format: "%.0f", trendPct))% above your baseline of \(avgHRVFormatted)ms. Good time to push intensity.",
                dataPoint: "\(avgHRVFormatted)ms avg HRV ↑",
                category: .recovery
            )
        } else if trendPct < -10 {
            return FirstInsight(
                headline: "Recovery needs monitoring",
                detail: "Your recent HRV is \(String(format: "%.0f", abs(trendPct)))% below your baseline of \(avgHRVFormatted)ms. The Ghost will adapt workout intensity.",
                dataPoint: "\(avgHRVFormatted)ms avg HRV ↓",
                category: .recovery
            )
        } else {
            return FirstInsight(
                headline: "Steady recovery baseline",
                detail: "Your HRV averages \(avgHRVFormatted)ms — stable and consistent. A foundation the Ghost can build on.",
                dataPoint: "\(avgHRVFormatted)ms avg HRV",
                category: .recovery
            )
        }
    }

    // MARK: - Workout Timing

    private func analyzeWorkoutTiming(_ workouts: [DetectedWorkout]) -> FirstInsight? {
        guard workouts.count >= 5 else { return nil }

        let calendar = Calendar.current
        var hourCounts: [Int: Int] = [:]
        for workout in workouts {
            let hour = calendar.component(.hour, from: workout.startDate)
            hourCounts[hour, default: 0] += 1
        }

        guard let peakHour = hourCounts.max(by: { $0.value < $1.value }) else { return nil }

        let timeLabel: String
        switch peakHour.key {
        case 5...8: timeLabel = "early morning"
        case 9...11: timeLabel = "morning"
        case 12...14: timeLabel = "midday"
        case 15...17: timeLabel = "afternoon"
        case 18...20: timeLabel = "evening"
        default: timeLabel = "night"
        }

        let pctAtPeak = Double(peakHour.value) / Double(workouts.count) * 100

        return FirstInsight(
            headline: "You're a \(timeLabel) mover",
            detail: "\(String(format: "%.0f", pctAtPeak))% of your workouts happen in the \(timeLabel). The Ghost will prioritize this window.",
            dataPoint: "\(timeLabel) peak",
            category: .schedule
        )
    }

    // MARK: - First Workout Window

    private func findFirstWorkoutWindow() async -> SuggestedWindow? {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

        let windows = await OptimalWindowFinder.shared.findOptimalWindows(
            for: tomorrow,
            workoutDuration: 45,
            count: 1
        )

        guard let best = windows.first else { return nil }

        return SuggestedWindow(
            date: tomorrow,
            startTime: best.suggestedStartTime,
            durationMinutes: 45,
            workoutType: "Workout",
            confidence: best.totalScore
        )
    }

    // MARK: - Fallback

    private func defaultInsight() -> FirstInsight {
        FirstInsight(
            headline: "The Ghost is ready",
            detail: "Your invisible fitness coach is set up and learning. Your first workout suggestion will arrive soon.",
            dataPoint: "Day 1",
            category: .workout
        )
    }
}
