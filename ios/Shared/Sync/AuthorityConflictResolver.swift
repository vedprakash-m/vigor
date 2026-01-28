//
//  AuthorityConflictResolver.swift
//  Shared
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Device authority resolution - Watch owns workouts, Phone owns planning.
//  Per PRD §3.3: Watch is authoritative for workout execution,
//  Phone is authoritative for schedule planning.
//

import Foundation

// MARK: - Authority Domain

enum AuthorityDomain: String, Codable {
    case workoutExecution       // Watch authority
    case workoutDetection       // Watch authority
    case heartRateData          // Watch authority
    case scheduleManagement     // Phone authority
    case calendarIntegration    // Phone authority
    case trustCalculation       // Phone authority (with watch input)
    case notificationDelivery   // Phone authority
    case userPreferences        // Phone authority
    case behavioralMemory       // Phone authority (sync from watch)
}

extension AuthorityDomain {
    var authoritativeDevice: AuthorityDevice {
        switch self {
        case .workoutExecution, .workoutDetection, .heartRateData:
            return .watch
        case .scheduleManagement, .calendarIntegration, .trustCalculation,
             .notificationDelivery, .userPreferences, .behavioralMemory:
            return .phone
        }
    }
}

// MARK: - Authority Device

enum AuthorityDevice: String, Codable {
    case watch
    case phone

    var displayName: String {
        switch self {
        case .watch: return "Apple Watch"
        case .phone: return "iPhone"
        }
    }
}

// MARK: - Conflict

struct AuthorityConflict: Identifiable {
    let id = UUID()
    let domain: AuthorityDomain
    let localValue: Any
    let remoteValue: Any
    let localTimestamp: Date
    let remoteTimestamp: Date
    let localDevice: AuthorityDevice
    let remoteDevice: AuthorityDevice
}

// MARK: - Resolution Strategy

enum ConflictResolutionStrategy {
    case authorityWins          // Device with domain authority wins
    case latestWins             // Most recent timestamp wins
    case merge                  // Merge values if possible
    case askUser                // Conflict requires user input
}

// MARK: - Resolution Result

struct ResolutionResult {
    let conflict: AuthorityConflict
    let strategy: ConflictResolutionStrategy
    let resolvedValue: Any
    let resolvedDevice: AuthorityDevice
    let requiresSync: Bool
}

// MARK: - Authority Conflict Resolver

actor AuthorityConflictResolver {

    // MARK: - Singleton

    static let shared = AuthorityConflictResolver()

    // MARK: - State

    private var pendingConflicts: [AuthorityConflict] = []
    private var resolutionLog: [ResolutionResult] = []

    // MARK: - Current Device

    #if os(watchOS)
    private let currentDevice: AuthorityDevice = .watch
    #else
    private let currentDevice: AuthorityDevice = .phone
    #endif

    // MARK: - Initialization

    private init() {}

    // MARK: - Conflict Resolution

    func resolveConflict(_ conflict: AuthorityConflict) -> ResolutionResult {
        let strategy = determineStrategy(for: conflict)
        let result = applyStrategy(strategy, to: conflict)

        resolutionLog.append(result)

        // Trim log to last 100 entries
        if resolutionLog.count > 100 {
            resolutionLog.removeFirst(resolutionLog.count - 100)
        }

        return result
    }

    private func determineStrategy(for conflict: AuthorityConflict) -> ConflictResolutionStrategy {
        let authorityDevice = conflict.domain.authoritativeDevice

        // Special cases where we might override authority
        switch conflict.domain {
        case .workoutExecution:
            // Watch always wins for workout execution
            return .authorityWins

        case .workoutDetection:
            // Watch wins, but if phone has more complete data, merge
            if hasMoreCompleteData(conflict.localValue, than: conflict.remoteValue) {
                return .merge
            }
            return .authorityWins

        case .trustCalculation:
            // Phone is authority, but must incorporate watch data
            return .merge

        case .behavioralMemory:
            // Phone authority, merge watch observations
            return .merge

        default:
            // Standard authority-based resolution
            return .authorityWins
        }
    }

    private func applyStrategy(
        _ strategy: ConflictResolutionStrategy,
        to conflict: AuthorityConflict
    ) -> ResolutionResult {

        switch strategy {
        case .authorityWins:
            let authorityDevice = conflict.domain.authoritativeDevice
            let value = authorityDevice == conflict.localDevice
                ? conflict.localValue
                : conflict.remoteValue

            return ResolutionResult(
                conflict: conflict,
                strategy: strategy,
                resolvedValue: value,
                resolvedDevice: authorityDevice,
                requiresSync: authorityDevice != currentDevice
            )

        case .latestWins:
            let localIsNewer = conflict.localTimestamp > conflict.remoteTimestamp

            return ResolutionResult(
                conflict: conflict,
                strategy: strategy,
                resolvedValue: localIsNewer ? conflict.localValue : conflict.remoteValue,
                resolvedDevice: localIsNewer ? conflict.localDevice : conflict.remoteDevice,
                requiresSync: !localIsNewer
            )

        case .merge:
            let merged = mergeValues(
                local: conflict.localValue,
                remote: conflict.remoteValue,
                domain: conflict.domain
            )

            return ResolutionResult(
                conflict: conflict,
                strategy: strategy,
                resolvedValue: merged,
                resolvedDevice: currentDevice,
                requiresSync: true
            )

        case .askUser:
            // Queue for user resolution - use local as temporary
            pendingConflicts.append(conflict)

            return ResolutionResult(
                conflict: conflict,
                strategy: strategy,
                resolvedValue: conflict.localValue,
                resolvedDevice: conflict.localDevice,
                requiresSync: false
            )
        }
    }

    // MARK: - Merge Logic

    private func mergeValues(local: Any, remote: Any, domain: AuthorityDomain) -> Any {
        switch domain {
        case .trustCalculation:
            return mergeTrustData(local: local, remote: remote)

        case .behavioralMemory:
            return mergeBehavioralData(local: local, remote: remote)

        case .workoutDetection:
            return mergeWorkoutData(local: local, remote: remote)

        default:
            // Default to authority device value
            return domain.authoritativeDevice == currentDevice ? local : remote
        }
    }

    private func mergeTrustData(local: Any, remote: Any) -> Any {
        // Merge trust events from both devices
        guard let localTrust = local as? TrustMergeData,
              let remoteTrust = remote as? TrustMergeData else {
            return local
        }

        // Combine events, deduplicate by timestamp
        var allEvents = localTrust.events + remoteTrust.events
        allEvents = Array(Set(allEvents)).sorted { $0.timestamp < $1.timestamp }

        return TrustMergeData(
            score: localTrust.score, // Phone calculates final score
            events: allEvents
        )
    }

    private func mergeBehavioralData(local: Any, remote: Any) -> Any {
        // Watch provides workout observations, phone maintains patterns
        guard let localBehavior = local as? BehavioralMergeData,
              let remoteBehavior = remote as? BehavioralMergeData else {
            return local
        }

        return BehavioralMergeData(
            preferences: localBehavior.preferences,
            workoutObservations: remoteBehavior.workoutObservations,
            timeSlotStats: mergeTimeSlotStats(
                local: localBehavior.timeSlotStats,
                remote: remoteBehavior.timeSlotStats
            )
        )
    }

    private func mergeTimeSlotStats(
        local: [String: TimeSlotMergeStats],
        remote: [String: TimeSlotMergeStats]
    ) -> [String: TimeSlotMergeStats] {
        var merged = local

        for (key, remoteStats) in remote {
            if let localStats = merged[key] {
                // Combine stats
                merged[key] = TimeSlotMergeStats(
                    completedCount: localStats.completedCount + remoteStats.completedCount,
                    missedCount: localStats.missedCount + remoteStats.missedCount,
                    avgDuration: (localStats.avgDuration + remoteStats.avgDuration) / 2
                )
            } else {
                merged[key] = remoteStats
            }
        }

        return merged
    }

    private func mergeWorkoutData(local: Any, remote: Any) -> Any {
        // Prefer watch data but fill gaps with phone observations
        guard let localWorkout = local as? WorkoutMergeData,
              let remoteWorkout = remote as? WorkoutMergeData else {
            return remote // Watch authority
        }

        return WorkoutMergeData(
            type: remoteWorkout.type,
            duration: remoteWorkout.duration,
            calories: remoteWorkout.calories ?? localWorkout.calories,
            heartRate: remoteWorkout.heartRate ?? localWorkout.heartRate,
            source: remoteWorkout.source
        )
    }

    // MARK: - Helper Methods

    private func hasMoreCompleteData(_ value1: Any, than value2: Any) -> Bool {
        // Compare completeness of data structures
        guard let workout1 = value1 as? WorkoutMergeData,
              let workout2 = value2 as? WorkoutMergeData else {
            return false
        }

        let score1 = (workout1.calories != nil ? 1 : 0) + (workout1.heartRate != nil ? 1 : 0)
        let score2 = (workout2.calories != nil ? 1 : 0) + (workout2.heartRate != nil ? 1 : 0)

        return score1 > score2
    }

    // MARK: - Pending Conflicts

    func getPendingConflicts() -> [AuthorityConflict] {
        return pendingConflicts
    }

    func resolveUserConflict(
        _ conflictId: UUID,
        chosenDevice: AuthorityDevice
    ) async {
        guard let index = pendingConflicts.firstIndex(where: { $0.id == conflictId }) else {
            return
        }

        let conflict = pendingConflicts.remove(at: index)
        let value = chosenDevice == conflict.localDevice
            ? conflict.localValue
            : conflict.remoteValue

        let result = ResolutionResult(
            conflict: conflict,
            strategy: .askUser,
            resolvedValue: value,
            resolvedDevice: chosenDevice,
            requiresSync: chosenDevice != currentDevice
        )

        resolutionLog.append(result)
    }

    // MARK: - Resolution Log

    func getRecentResolutions(limit: Int = 20) -> [ResolutionResult] {
        Array(resolutionLog.suffix(limit))
    }
}

// MARK: - Merge Data Types

struct TrustMergeData: Equatable {
    let score: Double
    let events: [TrustMergeEvent]
}

struct TrustMergeEvent: Hashable {
    let type: String
    let timestamp: Date
}

struct BehavioralMergeData {
    let preferences: [String: Any]
    let workoutObservations: [WorkoutObservation]
    let timeSlotStats: [String: TimeSlotMergeStats]
}

struct WorkoutObservation {
    let type: String
    let timestamp: Date
    let duration: Int
    let source: AuthorityDevice
}

struct TimeSlotMergeStats {
    let completedCount: Int
    let missedCount: Int
    let avgDuration: Double
}

struct WorkoutMergeData {
    let type: String
    let duration: Int
    let calories: Int?
    let heartRate: Int?
    let source: AuthorityDevice
}

// MARK: - Workout Authority Protocol

protocol WorkoutAuthoritySource {
    var isAuthoritative: Bool { get }
    func reportWorkout(_ workout: DetectedWorkout) async
}

// MARK: - Watch Authority Handler

#if os(watchOS)
class WatchAuthorityHandler: WorkoutAuthoritySource {
    var isAuthoritative: Bool { true }

    func reportWorkout(_ workout: DetectedWorkout) async {
        // Watch is authoritative - record locally and sync to phone
        await WatchConnectivityManager.shared.sendWorkout(workout)
    }
}
#endif

// MARK: - Phone Authority Handler

#if os(iOS)
class PhoneAuthorityHandler: WorkoutAuthoritySource {
    var isAuthoritative: Bool { false }

    func reportWorkout(_ workout: DetectedWorkout) async {
        // Phone is not authoritative for workouts
        // Only record if watch data is unavailable
        let hasWatchData = await checkForWatchData(workout)
        if !hasWatchData {
            // Record with lower confidence
            await recordFallbackWorkout(workout)
        }
    }

    private func checkForWatchData(_ workout: DetectedWorkout) async -> Bool {
        // Check if we received this workout from watch already
        false // Placeholder
    }

    private func recordFallbackWorkout(_ workout: DetectedWorkout) async {
        // Record with note that this is phone-observed
    }
}
#endif
