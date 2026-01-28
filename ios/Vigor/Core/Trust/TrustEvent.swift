//
//  TrustEvent.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Events that affect trust score calculation.
//

import Foundation

enum TrustEvent: CustomStringConvertible {
    // Positive events
    case workoutCompleted(DetectedWorkout)
    case blockAccepted(TrainingBlock)
    case proposalAccepted
    case appOpened
    case settingsConfigured

    // Negative events
    case blockDeleted(TrainingBlock)
    case blockMissed(TrainingBlock)
    case proposalRejected
    case permissionRevoked(String)

    // Neutral events
    case blockModified(TrainingBlock)
    case triageResponded(MissedWorkoutReason)

    var description: String {
        switch self {
        case .workoutCompleted: return "workout_completed"
        case .blockAccepted: return "block_accepted"
        case .proposalAccepted: return "proposal_accepted"
        case .appOpened: return "app_opened"
        case .settingsConfigured: return "settings_configured"
        case .blockDeleted: return "block_deleted"
        case .blockMissed: return "block_missed"
        case .proposalRejected: return "proposal_rejected"
        case .permissionRevoked: return "permission_revoked"
        case .blockModified: return "block_modified"
        case .triageResponded: return "triage_responded"
        }
    }

    var isPositive: Bool {
        switch self {
        case .workoutCompleted, .blockAccepted, .proposalAccepted, .appOpened, .settingsConfigured:
            return true
        default:
            return false
        }
    }

    var isNegative: Bool {
        switch self {
        case .blockDeleted, .blockMissed, .proposalRejected, .permissionRevoked:
            return true
        default:
            return false
        }
    }
}

// MARK: - Missed Workout Reason

enum MissedWorkoutReason: String, Codable, CaseIterable {
    case badTimeSlot = "bad_time_slot"       // The scheduled time doesn't work
    case tooTired = "too_tired"              // User was too tired/low energy
    case lifeHappened = "life_happened"      // External circumstances
    case wrongWorkout = "wrong_workout"      // Didn't want that workout type
    case unknown = "unknown"                 // No response (ambiguous)

    var displayText: String {
        switch self {
        case .badTimeSlot: return "Bad time"
        case .tooTired: return "Too tired"
        case .lifeHappened: return "Life happened"
        case .wrongWorkout: return "Wrong workout"
        case .unknown: return "Unknown"
        }
    }

    var iconName: String {
        switch self {
        case .badTimeSlot: return "clock.badge.xmark"
        case .tooTired: return "battery.25percent"
        case .lifeHappened: return "exclamationmark.triangle"
        case .wrongWorkout: return "arrow.triangle.2.circlepath"
        case .unknown: return "questionmark.circle"
        }
    }

    /// Whether this reason should penalize the time slot
    var shouldPenalizeTimeSlot: Bool {
        switch self {
        case .badTimeSlot: return true
        case .tooTired, .lifeHappened, .wrongWorkout, .unknown: return false
        }
    }

    /// Whether this reason affects Ghost's scheduling algorithm
    var affectsSchedulingAlgorithm: Bool {
        switch self {
        case .badTimeSlot, .wrongWorkout: return true
        case .tooTired, .lifeHappened, .unknown: return false
        }
    }
}
