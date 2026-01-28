//
//  RecoveryAnalyzer.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Recovery analysis using HRV, sleep, and activity data.
//  Per PRD §2.2: Ghost transforms based on recovery status.
//

import Foundation
import HealthKit

actor RecoveryAnalyzer {

    // MARK: - Singleton

    static let shared = RecoveryAnalyzer()

    // MARK: - Weights

    private let weights: [String: Double] = [
        "hrv_trend": 0.30,
        "sleep_quality": 0.30,
        "recent_strain": 0.25,
        "resting_hr_trend": 0.15
    ]

    // MARK: - Initialization

    private init() {}

    // MARK: - Recovery Analysis

    func analyzeRecovery() async -> RecoveryAnalysis {
        async let hrvAnalysis = analyzeHRV()
        async let sleepAnalysis = analyzeSleep()
        async let strainAnalysis = analyzeStrain()
        async let restingHRAnalysis = analyzeRestingHR()

        let hrv = await hrvAnalysis
        let sleep = await sleepAnalysis
        let strain = await strainAnalysis
        let restingHR = await restingHRAnalysis

        // Calculate composite score
        let score = calculateCompositeScore(
            hrv: hrv,
            sleep: sleep,
            strain: strain,
            restingHR: restingHR
        )

        let status = determineStatus(score: score)
        let recommendation = generateRecommendation(
            status: status,
            factors: [hrv, sleep, strain, restingHR]
        )

        return RecoveryAnalysis(
            score: score,
            status: status,
            factors: [
                RecoveryFactor(
                    name: "HRV",
                    value: hrv.normalizedValue,
                    impact: hrv.impact,
                    trend: hrv.trend,
                    description: hrv.description
                ),
                RecoveryFactor(
                    name: "Sleep",
                    value: sleep.normalizedValue,
                    impact: sleep.impact,
                    trend: sleep.trend,
                    description: sleep.description
                ),
                RecoveryFactor(
                    name: "Training Load",
                    value: strain.normalizedValue,
                    impact: strain.impact,
                    trend: strain.trend,
                    description: strain.description
                ),
                RecoveryFactor(
                    name: "Resting HR",
                    value: restingHR.normalizedValue,
                    impact: restingHR.impact,
                    trend: restingHR.trend,
                    description: restingHR.description
                )
            ],
            recommendation: recommendation,
            suggestedWorkoutIntensity: suggestIntensity(score: score),
            timestamp: Date()
        )
    }

    // MARK: - HRV Analysis

    private func analyzeHRV() async -> FactorAnalysis {
        let recentHRV = await RawSignalStore.shared.getRecentHRV(days: 7)
        let baselineHRV = await RawSignalStore.shared.getBaselineHRV(days: 30)

        guard !recentHRV.isEmpty, !baselineHRV.isEmpty else {
            return FactorAnalysis(
                normalizedValue: 0.5,
                impact: .neutral,
                trend: .stable,
                description: "Insufficient HRV data"
            )
        }

        let recentAvg = recentHRV.map(\.averageMs).reduce(0, +) / Double(recentHRV.count)
        let baselineAvg = baselineHRV.map(\.averageMs).reduce(0, +) / Double(baselineHRV.count)

        let ratio = recentAvg / baselineAvg

        let normalizedValue: Double
        let impact: RecoveryImpact
        let trend: RecoveryTrend
        let description: String

        if ratio >= 1.1 {
            normalizedValue = min(1.0, 0.7 + (ratio - 1.1) * 0.5)
            impact = .positive
            trend = .improving
            description = "HRV above baseline - excellent recovery"
        } else if ratio >= 0.9 {
            normalizedValue = 0.5 + (ratio - 0.9) * 1.0
            impact = .neutral
            trend = .stable
            description = "HRV near baseline - normal recovery"
        } else {
            normalizedValue = max(0, 0.5 - (0.9 - ratio) * 1.5)
            impact = .negative
            trend = .declining
            description = "HRV below baseline - may need extra rest"
        }

        return FactorAnalysis(
            normalizedValue: normalizedValue,
            impact: impact,
            trend: trend,
            description: description
        )
    }

    // MARK: - Sleep Analysis

    private func analyzeSleep() async -> FactorAnalysis {
        let recentSleep = await RawSignalStore.shared.getRecentSleep(days: 3)

        guard !recentSleep.isEmpty else {
            return FactorAnalysis(
                normalizedValue: 0.5,
                impact: .neutral,
                trend: .stable,
                description: "Insufficient sleep data"
            )
        }

        let avgDuration = recentSleep.map(\.totalMinutes).reduce(0, +) / recentSleep.count
        let avgQuality = recentSleep.map(\.quality).reduce(0, +) / Double(recentSleep.count)

        // Target: 7-9 hours of sleep
        let durationScore: Double
        switch avgDuration {
        case 420...540: durationScore = 1.0  // 7-9 hours
        case 360..<420: durationScore = 0.7  // 6-7 hours
        case 300..<360: durationScore = 0.4  // 5-6 hours
        default: durationScore = 0.2
        }

        let normalizedValue = (durationScore * 0.6) + (avgQuality * 0.4)

        let impact: RecoveryImpact
        let trend: RecoveryTrend
        let description: String

        if normalizedValue >= 0.7 {
            impact = .positive
            trend = .improving
            description = "Good sleep quality and duration"
        } else if normalizedValue >= 0.4 {
            impact = .neutral
            trend = .stable
            description = "Adequate sleep - room for improvement"
        } else {
            impact = .negative
            trend = .declining
            description = "Sleep deficit detected"
        }

        return FactorAnalysis(
            normalizedValue: normalizedValue,
            impact: impact,
            trend: trend,
            description: description
        )
    }

    // MARK: - Strain Analysis

    private func analyzeStrain() async -> FactorAnalysis {
        let recentWorkouts = await DerivedStateStore.shared.getRecentWorkouts(days: 7)
        let weeklyTargetMinutes = 150 // WHO recommendation

        let totalMinutes = recentWorkouts.reduce(0) { $0 + $1.durationMinutes }
        let avgIntensity = recentWorkouts.isEmpty ? 0.5 :
            recentWorkouts.map(\.intensity).reduce(0, +) / Double(recentWorkouts.count)

        // Calculate strain score (higher = more fatigued)
        let volumeRatio = Double(totalMinutes) / Double(weeklyTargetMinutes)
        let intensityFactor = avgIntensity
        let strainLevel = volumeRatio * intensityFactor

        // Invert for recovery score (lower strain = better recovery)
        let normalizedValue: Double
        let impact: RecoveryImpact
        let trend: RecoveryTrend
        let description: String

        if strainLevel < 0.5 {
            normalizedValue = 0.8
            impact = .positive
            trend = .stable
            description = "Light training load - well recovered"
        } else if strainLevel < 1.0 {
            normalizedValue = 0.6
            impact = .neutral
            trend = .stable
            description = "Moderate training load"
        } else if strainLevel < 1.5 {
            normalizedValue = 0.4
            impact = .neutral
            trend = .declining
            description = "Elevated training load - monitor recovery"
        } else {
            normalizedValue = 0.2
            impact = .negative
            trend = .declining
            description = "High training load - rest recommended"
        }

        return FactorAnalysis(
            normalizedValue: normalizedValue,
            impact: impact,
            trend: trend,
            description: description
        )
    }

    // MARK: - Resting HR Analysis

    private func analyzeRestingHR() async -> FactorAnalysis {
        let recentRHR = await RawSignalStore.shared.getRecentRestingHR(days: 7)
        let baselineRHR = await RawSignalStore.shared.getBaselineRestingHR(days: 30)

        guard !recentRHR.isEmpty, !baselineRHR.isEmpty else {
            return FactorAnalysis(
                normalizedValue: 0.5,
                impact: .neutral,
                trend: .stable,
                description: "Insufficient resting HR data"
            )
        }

        let recentAvg = Double(recentRHR.reduce(0, +)) / Double(recentRHR.count)
        let baselineAvg = Double(baselineRHR.reduce(0, +)) / Double(baselineRHR.count)

        let difference = recentAvg - baselineAvg

        let normalizedValue: Double
        let impact: RecoveryImpact
        let trend: RecoveryTrend
        let description: String

        if difference <= -3 {
            normalizedValue = 0.9
            impact = .positive
            trend = .improving
            description = "Resting HR below baseline - excellent fitness"
        } else if difference < 3 {
            normalizedValue = 0.6
            impact = .neutral
            trend = .stable
            description = "Resting HR at baseline"
        } else if difference < 7 {
            normalizedValue = 0.4
            impact = .neutral
            trend = .declining
            description = "Resting HR slightly elevated"
        } else {
            normalizedValue = 0.2
            impact = .negative
            trend = .declining
            description = "Resting HR elevated - may indicate fatigue or illness"
        }

        return FactorAnalysis(
            normalizedValue: normalizedValue,
            impact: impact,
            trend: trend,
            description: description
        )
    }

    // MARK: - Composite Calculation

    private func calculateCompositeScore(
        hrv: FactorAnalysis,
        sleep: FactorAnalysis,
        strain: FactorAnalysis,
        restingHR: FactorAnalysis
    ) -> Double {
        let score = (hrv.normalizedValue * weights["hrv_trend"]!) +
                   (sleep.normalizedValue * weights["sleep_quality"]!) +
                   (strain.normalizedValue * weights["recent_strain"]!) +
                   (restingHR.normalizedValue * weights["resting_hr_trend"]!)

        return score * 100 // Convert to 0-100 scale
    }

    private func determineStatus(score: Double) -> RecoveryStatus {
        switch score {
        case 75...100: return .fullyRecovered
        case 50..<75: return .partiallyRecovered
        case 25..<50: return .fatigued
        default: return .needsRest
        }
    }

    private func generateRecommendation(
        status: RecoveryStatus,
        factors: [FactorAnalysis]
    ) -> RecoveryRecommendation {
        let negativeFactors = factors.filter { $0.impact == .negative }

        switch status {
        case .fullyRecovered:
            return RecoveryRecommendation(
                action: .proceedAsPlanned,
                message: "Ready for any workout intensity",
                adjustments: []
            )

        case .partiallyRecovered:
            return RecoveryRecommendation(
                action: .reduceIntensity,
                message: "Consider moderate intensity today",
                adjustments: negativeFactors.map { "Address \($0.description)" }
            )

        case .fatigued:
            return RecoveryRecommendation(
                action: .suggestRecovery,
                message: "Light activity or active recovery recommended",
                adjustments: negativeFactors.map { "Focus on: \($0.description)" }
            )

        case .needsRest:
            return RecoveryRecommendation(
                action: .restDay,
                message: "Rest day recommended for optimal recovery",
                adjustments: ["Prioritize sleep", "Reduce stress", "Stay hydrated"]
            )
        }
    }

    private func suggestIntensity(score: Double) -> WorkoutIntensity {
        switch score {
        case 80...100: return .high
        case 60..<80: return .moderate
        case 40..<60: return .low
        default: return .recovery
        }
    }
}

// MARK: - Supporting Types

struct FactorAnalysis {
    let normalizedValue: Double
    let impact: RecoveryImpact
    let trend: RecoveryTrend
    let description: String
}

enum RecoveryImpact: String {
    case positive
    case neutral
    case negative
}

enum RecoveryTrend: String {
    case improving
    case stable
    case declining
}

enum RecoveryStatus: String {
    case fullyRecovered
    case partiallyRecovered
    case fatigued
    case needsRest
}

struct RecoveryAnalysis {
    let score: Double
    let status: RecoveryStatus
    let factors: [RecoveryFactor]
    let recommendation: RecoveryRecommendation
    let suggestedWorkoutIntensity: WorkoutIntensity
    let timestamp: Date
}

struct RecoveryFactor {
    let name: String
    let value: Double
    let impact: RecoveryImpact
    let trend: RecoveryTrend
    let description: String
}

struct RecoveryRecommendation {
    let action: RecoveryAction
    let message: String
    let adjustments: [String]
}

enum RecoveryAction: String {
    case proceedAsPlanned
    case reduceIntensity
    case suggestRecovery
    case restDay
}

enum WorkoutIntensity: String {
    case high
    case moderate
    case low
    case recovery
}

// MARK: - Store Extensions

extension RawSignalStore {
    func getRecentHRV(days: Int) async -> [HRVData] { [] }
    func getBaselineHRV(days: Int) async -> [HRVData] { [] }
    func getRecentSleep(days: Int) async -> [SleepData] { [] }
    func getRecentRestingHR(days: Int) async -> [Int] { [] }
    func getBaselineRestingHR(days: Int) async -> [Int] { [] }
}

extension DerivedStateStore {
    func getRecentWorkouts(days: Int) async -> [WorkoutStats] { [] }
}

struct WorkoutStats {
    let durationMinutes: Int
    let intensity: Double
}
