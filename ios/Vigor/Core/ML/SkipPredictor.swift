//
//  SkipPredictor.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Core ML model for predicting workout skip probability.
//  Per PRD §3.1: Ghost proactively reschedules when skip probability > threshold.
//

import Foundation
import CoreML

actor SkipPredictor {

    // MARK: - Singleton

    static let shared = SkipPredictor()

    // MARK: - Model

    private var model: SkipPredictionModel?
    private let modelVersion = "1.0.0"

    // MARK: - Feature Weights (Rule-based fallback)

    private let featureWeights: [String: Double] = [
        "time_slot_miss_rate": 0.30,
        "workout_type_adherence": 0.15,
        "recovery_score": 0.20,
        "calendar_density": 0.15,
        "day_of_week_pattern": 0.10,
        "streak_length": 0.10
    ]

    // MARK: - Initialization

    private init() {
        loadModel()
    }

    private func loadModel() {
        // Try to load Core ML model
        // In production, this would be a trained .mlmodel
        // For now, we use rule-based prediction
    }

    // MARK: - Prediction

    func predictSkipProbability(for context: SkipPredictionContext) async -> SkipPrediction {
        // If Core ML model is available, use it
        if let model = model {
            return await predictWithModel(model, context: context)
        }

        // Fall back to rule-based prediction
        return predictWithRules(context: context)
    }

    private func predictWithModel(
        _ model: SkipPredictionModel,
        context: SkipPredictionContext
    ) async -> SkipPrediction {
        // Core ML inference would go here
        // Placeholder for now
        return predictWithRules(context: context)
    }

    private func predictWithRules(context: SkipPredictionContext) -> SkipPrediction {
        var probability: Double = 0
        var factors: [SkipFactor] = []

        // Factor 1: Time slot historical miss rate
        if context.timeSlotMissRate > 0.5 {
            let contribution = context.timeSlotMissRate * featureWeights["time_slot_miss_rate"]!
            probability += contribution
            factors.append(SkipFactor(
                name: "Time Slot History",
                impact: contribution,
                description: "You often skip workouts at this time"
            ))
        }

        // Factor 2: Workout type adherence
        let typeAdherence = 1.0 - context.workoutTypeCompletionRate
        if typeAdherence > 0.3 {
            let contribution = typeAdherence * featureWeights["workout_type_adherence"]!
            probability += contribution
            factors.append(SkipFactor(
                name: "Workout Type",
                impact: contribution,
                description: "This workout type has lower completion"
            ))
        }

        // Factor 3: Recovery score
        if context.recoveryScore < 50 {
            let contribution = (1.0 - context.recoveryScore / 100) * featureWeights["recovery_score"]!
            probability += contribution
            factors.append(SkipFactor(
                name: "Recovery Status",
                impact: contribution,
                description: "Low recovery may affect motivation"
            ))
        }

        // Factor 4: Calendar density
        if context.calendarDensity > 0.7 {
            let contribution = context.calendarDensity * featureWeights["calendar_density"]!
            probability += contribution
            factors.append(SkipFactor(
                name: "Busy Day",
                impact: contribution,
                description: "Dense calendar increases skip likelihood"
            ))
        }

        // Factor 5: Day of week pattern
        if context.dayOfWeekMissRate > 0.4 {
            let contribution = context.dayOfWeekMissRate * featureWeights["day_of_week_pattern"]!
            probability += contribution
            factors.append(SkipFactor(
                name: "Day Pattern",
                impact: contribution,
                description: "This day of week has lower completion"
            ))
        }

        // Factor 6: Streak bonus (negative - reduces skip probability)
        if context.currentStreak > 3 {
            let streakBonus = min(0.15, Double(context.currentStreak) * 0.03)
            probability -= streakBonus
            factors.append(SkipFactor(
                name: "Streak Momentum",
                impact: -streakBonus,
                description: "\(context.currentStreak)-day streak builds momentum"
            ))
        }

        // Clamp probability
        probability = max(0, min(1, probability))

        return SkipPrediction(
            probability: probability,
            confidence: calculateConfidence(context),
            factors: factors,
            recommendation: getRecommendation(probability),
            modelVersion: modelVersion
        )
    }

    private func calculateConfidence(_ context: SkipPredictionContext) -> Double {
        // Confidence based on data availability
        var confidence = 0.5 // Base confidence

        if context.historicalDataPoints >= 10 { confidence += 0.1 }
        if context.historicalDataPoints >= 30 { confidence += 0.1 }
        if context.historicalDataPoints >= 90 { confidence += 0.1 }
        if context.recoveryScore > 0 { confidence += 0.1 }
        if context.calendarDensity >= 0 { confidence += 0.1 }

        return min(1.0, confidence)
    }

    private func getRecommendation(_ probability: Double) -> SkipRecommendation {
        switch probability {
        case 0..<0.2:
            return .proceed
        case 0.2..<0.4:
            return .monitorClosely
        case 0.4..<0.6:
            return .considerRescheduling
        case 0.6..<0.8:
            return .suggestAlternative
        default:
            return .proactiveReschedule
        }
    }

    // MARK: - Batch Prediction

    func predictForWeek(
        blocks: [TrainingBlock],
        context: WeekContext
    ) async -> [String: SkipPrediction] {
        var predictions: [String: SkipPrediction] = [:]

        for block in blocks {
            let blockContext = await buildContext(for: block, weekContext: context)
            let prediction = await predictSkipProbability(for: blockContext)
            predictions[block.id] = prediction
        }

        return predictions
    }

    private func buildContext(
        for block: TrainingBlock,
        weekContext: WeekContext
    ) async -> SkipPredictionContext {
        let timeSlotKey = SkipTimeSlotKey(
            dayOfWeek: Calendar.current.component(.weekday, from: block.startTime),
            hourOfDay: Calendar.current.component(.hour, from: block.startTime)
        )

        let timeSlotStats = await BehavioralMemoryStore.shared.getTimeSlotStats(for: timeSlotKey)
        let workoutPattern = await BehavioralMemoryStore.shared.getWorkoutPattern(for: block.workoutType)

        return SkipPredictionContext(
            timeSlotMissRate: timeSlotStats?.missRate ?? 0.3,
            workoutTypeCompletionRate: workoutPattern?.completionRate ?? 0.7,
            recoveryScore: weekContext.currentRecoveryScore,
            calendarDensity: weekContext.dayDensities[block.startTime] ?? 0.5,
            dayOfWeekMissRate: weekContext.dayOfWeekMissRates[timeSlotKey.dayOfWeek] ?? 0.3,
            currentStreak: weekContext.currentStreak,
            historicalDataPoints: timeSlotStats?.totalAttempts ?? 0
        )
    }
}

// MARK: - Skip Prediction Context

struct SkipPredictionContext {
    let timeSlotMissRate: Double
    let workoutTypeCompletionRate: Double
    let recoveryScore: Double
    let calendarDensity: Double
    let dayOfWeekMissRate: Double
    let currentStreak: Int
    let historicalDataPoints: Int
}

// MARK: - Skip Prediction Result

struct SkipPrediction {
    let probability: Double
    let confidence: Double
    let factors: [SkipFactor]
    let recommendation: SkipRecommendation
    let modelVersion: String

    var isHighRisk: Bool { probability >= 0.6 }
    var shouldReschedule: Bool { recommendation == .proactiveReschedule }
}

struct SkipFactor {
    let name: String
    let impact: Double
    let description: String
}

enum SkipRecommendation: String {
    case proceed = "proceed"
    case monitorClosely = "monitor"
    case considerRescheduling = "consider_reschedule"
    case suggestAlternative = "suggest_alternative"
    case proactiveReschedule = "reschedule"
}

// MARK: - Week Context

struct WeekContext {
    let currentRecoveryScore: Double
    let dayDensities: [Date: Double]
    let dayOfWeekMissRates: [Int: Double]
    let currentStreak: Int
}

// MARK: - Core ML Model Protocol

protocol SkipPredictionModel {
    func predict(features: [String: Double]) -> Double
}

// MARK: - TimeSlotKey

struct SkipTimeSlotKey: Hashable, Codable {
    let dayOfWeek: Int // 1-7
    let hourOfDay: Int // 0-23

    var description: String {
        let days = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let period = hourOfDay < 12 ? "AM" : "PM"
        let hour = hourOfDay == 0 ? 12 : (hourOfDay > 12 ? hourOfDay - 12 : hourOfDay)
        return "\(days[dayOfWeek]) \(hour)\(period)"
    }
}

// MARK: - Extensions for Integration

extension BehavioralMemoryStore {
    func getTimeSlotStats(for key: SkipTimeSlotKey) async -> SkipTimeSlotStats? {
        // Return stats for the time slot
        nil // Placeholder
    }

    func getWorkoutPattern(for type: WorkoutType) async -> SkipWorkoutPattern? {
        // Return pattern for workout type
        nil // Placeholder
    }
}

struct SkipTimeSlotStats {
    let completedCount: Int
    let missedCount: Int
    let totalAttempts: Int

    var missRate: Double {
        guard totalAttempts > 0 else { return 0.3 }
        return Double(missedCount) / Double(totalAttempts)
    }
}

struct SkipWorkoutPattern {
    let workoutType: WorkoutType
    let completedCount: Int
    let scheduledCount: Int

    var completionRate: Double {
        guard scheduledCount > 0 else { return 0.7 }
        return Double(completedCount) / Double(scheduledCount)
    }
}
