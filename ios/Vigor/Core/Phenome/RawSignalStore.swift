//
//  RawSignalStore.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Raw signal storage for HealthKit data and calendar events.
//  First tier of the Phenome storage system.
//

import Foundation

actor RawSignalStore {

    // MARK: - Storage

    private var sleepData: [SleepData] = []
    private var hrvData: [HRVData] = []
    private var workouts: [DetectedWorkout] = []

    // MARK: - Aggregates

    var averageSleepHours: Double {
        guard !sleepData.isEmpty else { return 0 }
        return sleepData.reduce(0) { $0 + $1.totalHours } / Double(sleepData.count)
    }

    var averageHRV: Double {
        guard !hrvData.isEmpty else { return 0 }
        return hrvData.reduce(0) { $0 + $1.averageHRV } / Double(hrvData.count)
    }

    // MARK: - Sleep Data

    func storeSleepData(_ data: [SleepData]) {
        sleepData.append(contentsOf: data)
        pruneOldData()
    }

    func getRecentSleep(days: Int) -> [SleepData] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return sleepData.filter { sleep in
            guard let firstStage = sleep.stages.first else { return false }
            return firstStage.startDate >= cutoff
        }
    }

    // MARK: - HRV Data

    func storeHRVData(_ data: [HRVData]) {
        hrvData.append(contentsOf: data)
        pruneOldData()
    }

    func getRecentHRV(days: Int) -> [HRVData] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return hrvData.filter { hrv in
            guard let firstReading = hrv.readings.first else { return false }
            return firstReading.date >= cutoff
        }
    }

    // MARK: - Workouts

    func storeWorkouts(_ data: [DetectedWorkout]) {
        workouts.append(contentsOf: data)
        pruneOldData()
    }

    func storeWorkout(_ workout: DetectedWorkout) {
        workouts.append(workout)
    }

    func getRecentWorkouts(days: Int) -> [DetectedWorkout] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return workouts.filter { $0.startDate >= cutoff }
    }

    // MARK: - Cleanup

    private func pruneOldData() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date())!

        sleepData.removeAll { sleep in
            guard let firstStage = sleep.stages.first else { return true }
            return firstStage.startDate < cutoff
        }

        hrvData.removeAll { hrv in
            guard let firstReading = hrv.readings.first else { return true }
            return firstReading.date < cutoff
        }

        workouts.removeAll { $0.startDate < cutoff }
    }
}
