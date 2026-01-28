//
//  TrustPhase.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Trust phases representing progressive autonomy levels.
//  Per Tech Spec §2.3
//

import Foundation

enum TrustPhase: Int, Codable, CaseIterable {
    case observer = 1        // Phase 1: Just watches, learns patterns
    case scheduler = 2       // Phase 2: Suggests blocks, needs confirmation
    case autoScheduler = 3   // Phase 3: Auto-creates blocks, can be deleted
    case transformer = 4     // Phase 4: Transforms blocks based on biometrics
    case fullGhost = 5       // Phase 5: Full autonomy, minimal intervention needed

    // MARK: - Display Properties

    var displayName: String {
        switch self {
        case .observer: return "Observer"
        case .scheduler: return "Scheduler"
        case .autoScheduler: return "Auto-Scheduler"
        case .transformer: return "Transformer"
        case .fullGhost: return "Full Ghost"
        }
    }

    var description: String {
        switch self {
        case .observer:
            return "Learning your patterns and preferences"
        case .scheduler:
            return "Suggesting workout times for your approval"
        case .autoScheduler:
            return "Automatically scheduling your workouts"
        case .transformer:
            return "Adapting workouts based on your recovery"
        case .fullGhost:
            return "Handling everything seamlessly"
        }
    }

    var shortDescription: String {
        switch self {
        case .observer: return "Learning"
        case .scheduler: return "Suggesting"
        case .autoScheduler: return "Scheduling"
        case .transformer: return "Adapting"
        case .fullGhost: return "Autonomous"
        }
    }

    // MARK: - Capabilities

    var capabilities: [TrustCapability] {
        switch self {
        case .observer:
            return [.readHealthKit, .readCalendar, .learnPatterns]
        case .scheduler:
            return [.readHealthKit, .readCalendar, .learnPatterns, .proposeBlocks]
        case .autoScheduler:
            return [.readHealthKit, .readCalendar, .learnPatterns, .proposeBlocks, .createBlocks]
        case .transformer:
            return [.readHealthKit, .readCalendar, .learnPatterns, .proposeBlocks, .createBlocks, .transformBlocks]
        case .fullGhost:
            return [.readHealthKit, .readCalendar, .learnPatterns, .proposeBlocks, .createBlocks, .transformBlocks, .removeBlocks]
        }
    }

    var canAutoSchedule: Bool {
        rawValue >= TrustPhase.autoScheduler.rawValue
    }

    var canTransformBlocks: Bool {
        rawValue >= TrustPhase.transformer.rawValue
    }

    var canRemoveBlocks: Bool {
        rawValue >= TrustPhase.fullGhost.rawValue
    }

    // MARK: - Action Confidence Thresholds

    /// Minimum confidence required to take an action at this phase
    var actionConfidenceThreshold: Double {
        switch self {
        case .observer: return 0.95      // Very high bar - mostly observing
        case .scheduler: return 0.80     // High bar - user confirms
        case .autoScheduler: return 0.70 // Moderate bar
        case .transformer: return 0.60   // Lower bar - established trust
        case .fullGhost: return 0.50     // Lowest bar - full trust
        }
    }

    // MARK: - Navigation

    var next: TrustPhase? {
        TrustPhase(rawValue: rawValue + 1)
    }

    var previous: TrustPhase? {
        TrustPhase(rawValue: rawValue - 1)
    }

    // MARK: - Visual

    var iconName: String {
        switch self {
        case .observer: return "eye"
        case .scheduler: return "calendar.badge.plus"
        case .autoScheduler: return "calendar.badge.checkmark"
        case .transformer: return "arrow.triangle.2.circlepath"
        case .fullGhost: return "sparkles"
        }
    }

    var color: String {
        switch self {
        case .observer: return "gray"
        case .scheduler: return "blue"
        case .autoScheduler: return "green"
        case .transformer: return "purple"
        case .fullGhost: return "orange"
        }
    }
}

// MARK: - Trust Capability

enum TrustCapability: String, Codable {
    case readHealthKit = "read_healthkit"
    case readCalendar = "read_calendar"
    case learnPatterns = "learn_patterns"
    case proposeBlocks = "propose_blocks"
    case createBlocks = "create_blocks"
    case transformBlocks = "transform_blocks"
    case removeBlocks = "remove_blocks"

    var displayName: String {
        switch self {
        case .readHealthKit: return "Read Health Data"
        case .readCalendar: return "Read Calendar"
        case .learnPatterns: return "Learn Patterns"
        case .proposeBlocks: return "Suggest Workouts"
        case .createBlocks: return "Schedule Workouts"
        case .transformBlocks: return "Adapt Workouts"
        case .removeBlocks: return "Remove Workouts"
        }
    }
}
