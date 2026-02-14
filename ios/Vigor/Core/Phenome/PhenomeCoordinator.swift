//
//  PhenomeCoordinator.swift
//  Vigor
//
//  Phenome storage coordinator managing three physical stores:
//  - RawSignalStore: HealthKit data, calendar events
//  - DerivedStateStore: Recovery scores, patterns, predictions
//  - BehavioralMemoryStore: Long-term preferences, sacred times
//
//  Per Tech Spec §2.4, §2.10, §2.11
//

import Foundation
import CoreData
import Combine

@MainActor
final class PhenomeCoordinator: ObservableObject {

    // MARK: - Singleton

    static let shared = PhenomeCoordinator()

    // MARK: - Published State

    @Published private(set) var isInitialized = false
    @Published private(set) var lastSyncTimestamp: Date?
    @Published private(set) var currentRecoveryScore: Double = 0.0

    // MARK: - Stores (shared singletons backed by Core Data)

    private let rawSignalStore = RawSignalStore.shared
    private let derivedStateStore = DerivedStateStore.shared
    private let behavioralMemoryStore = BehavioralMemoryStore.shared

    // MARK: - Metric Registry

    private let metricRegistry = MetricRegistry()

    // MARK: - Core Data (delegated to CoreDataStack)

    var viewContext: NSManagedObjectContext {
        CoreDataStack.shared.viewContext
    }

    // MARK: - Initialization

    private init() {}

    func initialize() async {
        // Load persisted state
        await loadPersistedState()

        // Initialize metric registry with versioned formulas
        await metricRegistry.registerMetrics()

        isInitialized = true
    }

    private func loadPersistedState() async {
        // Load last sync timestamp
        if let timestamp = UserDefaults.standard.object(forKey: "phenomeLastSync") as? Date {
            lastSyncTimestamp = timestamp
        }

        // Load current recovery score
        if let score = UserDefaults.standard.object(forKey: "currentRecoveryScore") as? Double {
            currentRecoveryScore = score
        }
    }

    // MARK: - Workout Preferences

    var workoutPreferences: WorkoutPreferences {
        get async {
            await behavioralMemoryStore.workoutPreferences
        }
    }

    // MARK: - Recovery Score Calculation

    func calculateRecoveryScore(sleep: SleepData, hrv: HRVData) async -> Double {
        let score = await metricRegistry.calculate(
            metric: "recovery_score",
            inputs: [
                "sleep_hours": sleep.totalHours,
                "sleep_quality": sleep.qualityScore,
                "hrv_value": hrv.averageHRV,
                "hrv_trend": hrv.trend.rawValue
            ]
        )

        currentRecoveryScore = score
        UserDefaults.standard.set(score, forKey: "currentRecoveryScore")

        return score
    }

    // MARK: - Data Import

    func importSleepData(_ sleepData: [SleepData]) async {
        await rawSignalStore.storeSleepData(sleepData)
        lastSyncTimestamp = Date()
    }

    func importHRVData(_ hrvData: [HRVData]) async {
        await rawSignalStore.storeHRVData(hrvData)
        lastSyncTimestamp = Date()
    }

    func importWorkouts(_ workouts: [DetectedWorkout]) async {
        await rawSignalStore.storeWorkouts(workouts)
        lastSyncTimestamp = Date()
    }

    // MARK: - Workout Logging

    func logWorkout(_ workout: DetectedWorkout) async {
        await rawSignalStore.storeWorkout(workout)

        // Update derived state
        await derivedStateStore.updateAfterWorkout(workout)

        // Update behavioral memory
        await behavioralMemoryStore.recordWorkoutCompletion(
            type: workout.type,
            time: workout.startDate
        )

        lastSyncTimestamp = Date()
    }

    // MARK: - Block Management

    func storeBlock(_ block: TrainingBlock) async {
        await derivedStateStore.storeBlock(block)
    }

    func getBlock(by id: String) async -> TrainingBlock? {
        await derivedStateStore.getBlock(by: id)
    }

    func updateBlockStatus(_ blockId: String, status: BlockStatus) async {
        await derivedStateStore.updateBlockStatus(blockId, status: status)
    }

    func updateBlockType(_ blockId: String, newType: WorkoutType) async {
        await derivedStateStore.updateBlockType(blockId, newType: newType)
    }

    func updateBlockTime(_ blockId: String, newStart: Date, newEnd: Date) async {
        await derivedStateStore.updateBlockTime(blockId, newStart: newStart, newEnd: newEnd)
    }

    func recordMissedBlock(_ block: TrainingBlock) async {
        await derivedStateStore.recordMissedBlock(block)
        await behavioralMemoryStore.recordMissedWorkout(
            time: block.startTime,
            type: block.workoutType
        )
    }

    func recordMissedWorkoutReason(blockId: String, reason: MissedWorkoutReason) async {
        await derivedStateStore.recordMissedReason(blockId: blockId, reason: reason)

        if reason.shouldPenalizeTimeSlot {
            let block = await getBlock(by: blockId)
            if let time = block?.startTime {
                await behavioralMemoryStore.penalizeTimeSlot(time)
            }
        }
    }

    // MARK: - Derived State

    func updateDerivedState(
        recoveryScore: Double,
        sleepData: SleepData,
        hrvData: HRVData
    ) async {
        await derivedStateStore.updateMorningState(
            recoveryScore: recoveryScore,
            sleepData: sleepData,
            hrvData: hrvData
        )
    }

    // MARK: - Workout History

    func getRecentWorkoutHistory(days: Int) async -> [DetectedWorkout] {
        await rawSignalStore.getRecentWorkouts(days: days)
    }

    // MARK: - Anonymized Snapshot

    func anonymizedSnapshot() async -> PhenomeSnapshot {
        let avgSleep = await rawSignalStore.averageSleepHours
        let avgHRV = await rawSignalStore.averageHRV
        let workoutsPerWeek = await derivedStateStore.averageWorkoutsPerWeek
        let preferredTime = await behavioralMemoryStore.preferredWorkoutTime
        let equipment = await behavioralMemoryStore.availableEquipment

        return PhenomeSnapshot(
            recoveryScore: currentRecoveryScore,
            averageSleepHours: avgSleep,
            averageHRV: avgHRV,
            workoutsPerWeek: workoutsPerWeek,
            preferredWorkoutTime: preferredTime,
            equipmentAvailable: equipment
        )
    }

    // MARK: - Persistence

    func savePendingChanges() async {
        // Flush any buffered decision receipts
        await DecisionReceiptStore.shared.flush()

        // Save Core Data view context
        CoreDataStack.shared.saveViewContext()

        UserDefaults.standard.set(lastSyncTimestamp, forKey: "phenomeLastSync")
    }
}

// MARK: - Phenome Snapshot

struct PhenomeSnapshot: Codable {
    let recoveryScore: Double
    let averageSleepHours: Double
    let averageHRV: Double
    let workoutsPerWeek: Double
    let preferredWorkoutTime: String
    let equipmentAvailable: [String]
}

// MARK: - Workout Preferences

struct WorkoutPreferences: Codable {
    var preferredDays: [Int]          // 1-7 (Sun-Sat)
    var preferredTimeOfDay: String    // "morning", "afternoon", "evening"
    var sessionDurationMinutes: Int
    var equipment: [String]
    var goals: [String]
    var injuries: [String]

    static var `default`: WorkoutPreferences {
        WorkoutPreferences(
            preferredDays: [2, 3, 4, 5, 6], // Mon-Fri
            preferredTimeOfDay: "morning",
            sessionDurationMinutes: 45,
            equipment: [],
            goals: ["general_fitness"],
            injuries: []
        )
    }
}
