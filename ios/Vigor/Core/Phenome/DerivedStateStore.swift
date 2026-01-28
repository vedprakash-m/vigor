//
//  DerivedStateStore.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Derived state storage for computed metrics and predictions.
//  Second tier of the Phenome storage system.
//

import Foundation

actor DerivedStateStore {

    // MARK: - Storage

    private var blocks: [String: TrainingBlock] = [:]
    private var morningStates: [Date: MorningState] = [:]
    private var workoutStats: WorkoutStats = WorkoutStats()

    // MARK: - Aggregates

    var averageWorkoutsPerWeek: Double {
        workoutStats.averagePerWeek
    }

    // MARK: - Blocks

    func storeBlock(_ block: TrainingBlock) {
        blocks[block.id] = block
    }

    func getBlock(by id: String) -> TrainingBlock? {
        blocks[id]
    }

    func updateBlockStatus(_ blockId: String, status: BlockStatus) {
        if var block = blocks[blockId] {
            block.status = status
            blocks[blockId] = block
        }
    }

    func updateBlockType(_ blockId: String, newType: WorkoutType) {
        if var block = blocks[blockId] {
            blocks[blockId] = TrainingBlock(
                id: block.id,
                calendarEventId: block.calendarEventId,
                workoutType: newType,
                startTime: block.startTime,
                endTime: block.endTime,
                wasAutoScheduled: block.wasAutoScheduled,
                status: .transformed,
                generatedWorkout: block.generatedWorkout
            )
        }
    }

    func recordMissedBlock(_ block: TrainingBlock) {
        if var storedBlock = blocks[block.id] {
            storedBlock.status = .missed
            blocks[block.id] = storedBlock
        }

        workoutStats.recordMiss()
    }

    func recordMissedReason(blockId: String, reason: MissedWorkoutReason) {
        // Store reason for pattern analysis
        // This would typically go to Core Data
    }

    // MARK: - Morning State

    func updateMorningState(
        recoveryScore: Double,
        sleepData: SleepData,
        hrvData: HRVData
    ) {
        let today = Calendar.current.startOfDay(for: Date())

        morningStates[today] = MorningState(
            date: today,
            recoveryScore: recoveryScore,
            sleepHours: sleepData.totalHours,
            sleepQuality: sleepData.qualityScore,
            hrvAverage: hrvData.averageHRV,
            hrvTrend: hrvData.trend
        )
    }

    // MARK: - Workout Updates

    func updateAfterWorkout(_ workout: DetectedWorkout) {
        workoutStats.recordWorkout(workout)
    }

    // MARK: - Cleanup

    func pruneOldData() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())!

        // Remove old blocks
        blocks = blocks.filter { $0.value.startTime >= cutoff }

        // Remove old morning states
        morningStates = morningStates.filter { $0.key >= cutoff }
    }
}

// MARK: - Morning State

struct MorningState: Codable {
    let date: Date
    let recoveryScore: Double
    let sleepHours: Double
    let sleepQuality: Double
    let hrvAverage: Double
    let hrvTrend: HRVTrend
}

// MARK: - Workout Stats

struct WorkoutStats: Codable {
    var totalWorkouts: Int = 0
    var workoutsThisWeek: Int = 0
    var weekStartDate: Date = Calendar.current.startOfDay(for: Date())
    var missedThisWeek: Int = 0

    var averagePerWeek: Double {
        guard totalWorkouts > 0 else { return 0 }
        // Simplified calculation
        return Double(workoutsThisWeek)
    }

    var completionRate: Double {
        let total = workoutsThisWeek + missedThisWeek
        guard total > 0 else { return 1.0 }
        return Double(workoutsThisWeek) / Double(total)
    }

    mutating func recordWorkout(_ workout: DetectedWorkout) {
        totalWorkouts += 1

        let calendar = Calendar.current
        let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!

        if weekStartDate != currentWeekStart {
            // New week - reset weekly counters
            weekStartDate = currentWeekStart
            workoutsThisWeek = 0
            missedThisWeek = 0
        }

        workoutsThisWeek += 1
    }

    mutating func recordMiss() {
        let calendar = Calendar.current
        let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!

        if weekStartDate != currentWeekStart {
            weekStartDate = currentWeekStart
            workoutsThisWeek = 0
            missedThisWeek = 0
        }

        missedThisWeek += 1
    }
}
