//
//  APIModels.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  API request and response models for Azure Functions backend.
//

import Foundation

// MARK: - User Profile

struct UserProfile: Codable, Identifiable {
    let id: String
    let email: String
    let displayName: String
    let createdAt: Date
    let updatedAt: Date
    let preferences: UserPreferences
    let trustPhase: String
    let trustScore: Double
    let onboardingCompleted: Bool
    let watchPaired: Bool
}

struct UserProfileUpdate: Codable {
    var displayName: String?
    var preferences: UserPreferences?
}

struct UserPreferences: Codable {
    var workoutDaysPerWeek: Int
    var preferredWorkoutDuration: Int // minutes
    var preferredWorkoutTimes: [PreferredTimeSlot]
    var sacredTimes: [SacredTimeDTO]
    var notificationsEnabled: Bool
    var calendarSyncEnabled: Bool
    var watchSyncEnabled: Bool
}

struct PreferredTimeSlot: Codable {
    let dayOfWeek: Int // 1-7
    let startHour: Int // 0-23
    let endHour: Int // 0-23
}

struct SacredTimeDTO: Codable {
    let name: String
    let dayOfWeek: Int
    let startHour: Int
    let endHour: Int
    let neverSchedule: Bool
}

// MARK: - Ghost State

struct GhostStateDTO: Codable {
    let trustScore: Double
    let trustPhase: String
    let healthMode: String
    let lastWakeTime: Date?
    let deviceId: String
}

struct GhostSyncResponse: Codable {
    let trustScore: Double?
    let trustPhase: TrustPhase?
    let pendingActions: [PendingActionDTO]?
    let serverTime: Date
}

struct PendingActionDTO: Codable {
    let id: String
    let type: String
    let payload: [String: AnyCodable]
    let expiresAt: Date
}

// MARK: - Workouts

struct WorkoutRecord: Codable, Identifiable {
    let id: String
    let userId: String
    let type: String
    let startTime: Date
    let endTime: Date
    let durationMinutes: Int
    let calories: Int?
    let averageHeartRate: Int?
    let maxHeartRate: Int?
    let source: String // "watch", "phone", "manual"
    let wasScheduled: Bool
    let blockId: String?
    let createdAt: Date
}

struct WorkoutContext: Codable {
    let currentDate: Date
    let recentWorkouts: [WorkoutSummary]
    let sleepData: SleepSummary?
    let hrvData: HRVSummary?
    let trustPhase: String
    let availableWindows: [TimeWindowDTO]
}

struct WorkoutSummary: Codable {
    let type: String
    let date: Date
    let durationMinutes: Int
    let intensity: String // "low", "medium", "high"
}

struct SleepSummary: Codable {
    let totalMinutes: Int
    let deepSleepMinutes: Int
    let remMinutes: Int
    let quality: Double // 0-1
    let date: Date
}

struct HRVSummary: Codable {
    let averageMs: Double
    let trend: String // "improving", "stable", "declining"
    let date: Date
}

struct TimeWindowDTO: Codable {
    let start: Date
    let end: Date
    let durationMinutes: Int
    let conflictLevel: String // "none", "soft", "hard"
}

struct WorkoutRecommendation: Codable {
    let workoutType: String
    let suggestedWindow: TimeWindowDTO
    let reasoning: String
    let confidence: Double
    let alternatives: [AlternativeWorkout]
}

struct AlternativeWorkout: Codable {
    let workoutType: String
    let suggestedWindow: TimeWindowDTO
    let reasoning: String
}

// MARK: - Training Blocks

struct TrainingBlockDTO: Codable, Identifiable {
    let id: String
    let userId: String
    let calendarEventId: String?
    let workoutType: String
    let scheduledStart: Date
    let scheduledEnd: Date
    let status: String // "scheduled", "completed", "missed", "cancelled", "transformed"
    let outcomeType: String?
    let createdAt: Date
    let updatedAt: Date
    let transformedFromType: String?
    let transformationReason: String?
}

struct TrainingBlockSyncRequest: Codable {
    let blocks: [TrainingBlockDTO]
}

struct TrainingBlockSyncResponse: Codable {
    let blocks: [TrainingBlockDTO]
    let conflictResolutions: [ConflictResolution]?
}

struct ConflictResolution: Codable {
    let blockId: String
    let resolution: String
    let reason: String
}

struct BlockOutcome: Codable {
    let blockId: String
    let outcome: String // "completed", "missed", "cancelled"
    let completedWorkoutId: String?
    let missedReason: String?
}

// MARK: - Trust

struct TrustEventDTO: Codable {
    let event: String
    let timestamp: Date
    let context: [String: AnyCodable]?
}

struct TrustHistoryResponse: Codable {
    let currentScore: Double
    let currentPhase: String
    let history: [TrustHistoryEntry]
    let phaseTransitions: [PhaseTransition]
}

struct TrustHistoryEntry: Codable {
    let date: Date
    let score: Double
    let delta: Double
    let event: String
}

struct PhaseTransition: Codable {
    let from: String
    let to: String
    let date: Date
    let reason: String
}

// MARK: - Recovery

struct RecoveryAssessment: Codable {
    let score: Double // 0-100
    let status: String // "recovered", "recovering", "fatigued", "overtrained"
    let factors: [RecoveryFactorDTO]
    let recommendation: String
    let suggestedRestDays: Int
}

struct RecoveryFactorDTO: Codable {
    let name: String
    let value: Double
    let impact: String // "positive", "neutral", "negative"
    let description: String
}

// MARK: - Device Registration

struct DeviceRegistration: Codable {
    let deviceId: String
    let deviceType: String // "iphone", "apple_watch"
    let osVersion: String
    let appVersion: String
    let pushToken: String?
    let capabilities: [String]
    let isPrimary: Bool
}

struct PushTokenRequest: Codable {
    let token: String
}

// MARK: - Ghost Health

struct GhostHealthDTO: Codable {
    let mode: String
    let successRate: Double
    let lastCycleTime: Date?
    let pendingActions: Int
    let backgroundRefreshEnabled: Bool
}

// MARK: - AnyCodable Helper

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            self.value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode AnyCodable"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Cannot encode \(type(of: value))"
                )
            )
        }
    }
}
