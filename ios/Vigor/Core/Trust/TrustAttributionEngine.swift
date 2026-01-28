//
//  TrustAttributionEngine.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Calculates trust score changes based on events.
//  Uses weighted trust updates (confidence × ambiguity).
//
//  Per Tech Spec §2.3
//

import Foundation

actor TrustAttributionEngine {

    // MARK: - Base Weights

    private let eventWeights: [String: Double] = [
        // Positive events
        "workout_completed": 5.0,
        "block_accepted": 3.0,
        "proposal_accepted": 2.0,
        "app_opened": 0.5,
        "settings_configured": 1.0,

        // Negative events
        "block_deleted": -4.0,
        "block_missed": -2.0,
        "proposal_rejected": -1.5,
        "permission_revoked": -10.0,

        // Neutral events
        "block_modified": 0.5,
        "triage_responded": 1.0
    ]

    // MARK: - Trust Delta Calculation

    func calculateTrustDelta(
        event: TrustEvent,
        currentPhase: TrustPhase,
        trustScore: Double
    ) -> Double {
        let baseWeight = eventWeights[event.description] ?? 0.0

        // Apply modifiers
        var delta = baseWeight

        // Phase modifier - early phases have higher impact
        let phaseModifier = calculatePhaseModifier(currentPhase)
        delta *= phaseModifier

        // Confidence modifier based on event details
        let confidenceModifier = calculateConfidenceModifier(event)
        delta *= confidenceModifier

        // Ambiguity modifier
        let ambiguityModifier = calculateAmbiguityModifier(event)
        delta *= ambiguityModifier

        // Diminishing returns for high trust scores
        if trustScore > 80 && delta > 0 {
            delta *= (100 - trustScore) / 20 // Reduces positive gains at high trust
        }

        // Amplify negative events for high trust scores
        if trustScore > 80 && delta < 0 {
            delta *= 1.5 // Trust is hard to build, easy to lose
        }

        return delta
    }

    // MARK: - Modifiers

    private func calculatePhaseModifier(_ phase: TrustPhase) -> Double {
        switch phase {
        case .observer: return 1.5      // High impact during learning
        case .scheduler: return 1.2     // Still building trust
        case .autoScheduler: return 1.0 // Standard
        case .transformer: return 0.9   // Established trust
        case .fullGhost: return 0.8     // Small adjustments
        }
    }

    private func calculateConfidenceModifier(_ event: TrustEvent) -> Double {
        switch event {
        case .workoutCompleted(let workout):
            // Longer workouts = higher confidence in completion
            if workout.duration > 45 * 60 {
                return 1.2
            } else if workout.duration < 15 * 60 {
                return 0.8
            }
            return 1.0

        case .blockDeleted(let block):
            // Auto-scheduled deletes are more significant
            return block.wasAutoScheduled ? 1.5 : 1.0

        case .triageResponded(let reason):
            // Responding to triage (even negatively) is positive
            return reason == .unknown ? 0.5 : 1.0

        default:
            return 1.0
        }
    }

    private func calculateAmbiguityModifier(_ event: TrustEvent) -> Double {
        switch event {
        case .blockMissed:
            // Missed blocks are ambiguous - could be Ghost's fault or life
            return 0.7

        case .triageResponded(let reason):
            // Triage removes ambiguity
            switch reason {
            case .badTimeSlot:
                return 0.5 // Ghost's fault - reduced negative impact on user trust
            case .lifeHappened:
                return 0.3 // Not Ghost's fault - minimal impact
            case .tooTired:
                return 0.6 // Mixed - Ghost could have predicted
            case .wrongWorkout:
                return 0.7 // Ghost's fault - workout selection
            case .unknown:
                return 1.0 // No info - full weight
            }

        default:
            return 1.0
        }
    }

    // MARK: - Streak Bonuses

    func calculateStreakBonus(consecutiveWorkouts: Int) -> Double {
        // Bonus for workout streaks
        switch consecutiveWorkouts {
        case 0..<3: return 0
        case 3..<7: return 2.0
        case 7..<14: return 5.0
        case 14..<30: return 10.0
        default: return 15.0
        }
    }
}
