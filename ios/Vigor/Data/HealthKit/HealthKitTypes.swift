//
//  HealthKitTypes.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Data types for HealthKit integration.
//

import Foundation

// MARK: - Sleep Data

struct SleepData: Codable {
    let totalHours: Double
    let qualityScore: Double
    let stages: [SleepStage]

    var isAdequate: Bool {
        totalHours >= 6.0
    }

    var isOptimal: Bool {
        totalHours >= 7.0 && totalHours <= 9.0 && qualityScore >= 80
    }
}

struct SleepStage: Codable {
    let type: SleepStageType
    let startDate: Date
    let endDate: Date

    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
}

enum SleepStageType: String, Codable {
    case inBed = "inBed"
    case awake = "awake"
    case asleep = "asleep"
    case core = "core"
    case deep = "deep"
    case rem = "rem"
}

// MARK: - HRV Data

struct HRVData: Codable {
    let averageHRV: Double
    let trend: HRVTrend
    let readings: [HRVReading]

    var isLow: Bool {
        averageHRV < 30
    }

    var isNormal: Bool {
        averageHRV >= 30 && averageHRV <= 100
    }

    var isHigh: Bool {
        averageHRV > 100
    }
}

struct HRVReading: Codable {
    let value: Double
    let date: Date
}

enum HRVTrend: String, Codable {
    case improving = "improving"
    case stable = "stable"
    case declining = "declining"
}

// MARK: - Detected Workout

struct DetectedWorkout: Codable, Identifiable {
    let id: String
    let type: WorkoutType
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let activeCalories: Double
    let averageHeartRate: Double?
    let source: String

    var durationMinutes: Int {
        Int(duration / 60)
    }
}

// MARK: - Workout Type

enum WorkoutType: String, Codable, CaseIterable {
    case strength = "strength"
    case cardio = "cardio"
    case hiit = "hiit"
    case flexibility = "flexibility"
    case recoveryWalk = "recovery_walk"
    case lightCardio = "light_cardio"
    case other = "other"

    var displayName: String {
        switch self {
        case .strength: return "Strength"
        case .cardio: return "Cardio"
        case .hiit: return "HIIT"
        case .flexibility: return "Flexibility"
        case .recoveryWalk: return "Recovery Walk"
        case .lightCardio: return "Light Cardio"
        case .other: return "Workout"
        }
    }

    var iconName: String {
        switch self {
        case .strength: return "dumbbell"
        case .cardio: return "figure.run"
        case .hiit: return "bolt.heart"
        case .flexibility: return "figure.yoga"
        case .recoveryWalk: return "figure.walk"
        case .lightCardio: return "figure.walk.motion"
        case .other: return "figure.mixed.cardio"
        }
    }

    var intensity: WorkoutIntensity {
        switch self {
        case .strength, .cardio, .hiit:
            return .high
        case .flexibility, .lightCardio:
            return .low
        case .recoveryWalk:
            return .recovery
        case .other:
            return .medium
        }
    }

    /// Can this workout type be transformed to another when recovery is low?
    var canBeDowngraded: Bool {
        switch self {
        case .strength, .cardio, .hiit:
            return true
        case .flexibility, .lightCardio, .recoveryWalk, .other:
            return false
        }
    }

    /// What workout type should this become when recovery is low?
    var downgradedType: WorkoutType {
        switch self {
        case .strength, .hiit:
            return .recoveryWalk
        case .cardio:
            return .lightCardio
        default:
            return self
        }
    }
}

enum WorkoutIntensity: String, Codable {
    case recovery = "recovery"
    case low = "low"
    case medium = "medium"
    case high = "high"
}

// MARK: - Training Block

struct TrainingBlock: Codable, Identifiable {
    let id: String
    let calendarEventId: String
    let workoutType: WorkoutType
    let startTime: Date
    let endTime: Date
    let wasAutoScheduled: Bool
    var status: BlockStatus
    var generatedWorkout: GeneratedWorkout?

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    var durationMinutes: Int {
        Int(duration / 60)
    }
}

enum BlockStatus: String, Codable {
    case scheduled = "scheduled"
    case completed = "completed"
    case missed = "missed"
    case cancelled = "cancelled"
    case transformed = "transformed"
}

// MARK: - Generated Workout

struct GeneratedWorkout: Codable, Identifiable {
    let id: String
    let type: WorkoutType
    let name: String
    let description: String
    let durationMinutes: Int
    let exercises: [Exercise]
    let warmup: [Exercise]?
    let cooldown: [Exercise]?
    let generatedAt: Date
    let confidence: Double
}

struct Exercise: Codable, Identifiable {
    let id: String
    let name: String
    let sets: Int?
    let reps: String?
    let duration: Int?
    let restSeconds: Int?
    let notes: String?
}
