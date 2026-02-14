//
//  RawSignalStore.swift
//  Vigor
//
//  Raw signal storage for HealthKit data and calendar events.
//  First tier of the Phenome storage system.
//
//  Backed by Core Data for persistence across app launches.
//

import Foundation
import CoreData

actor RawSignalStore {

    // MARK: - Singleton
    static let shared = RawSignalStore()

    // MARK: - Core Data

    private var stack: CoreDataStack { CoreDataStack.shared }

    // MARK: - Aggregates (computed from Core Data)

    var averageSleepHours: Double {
        get async {
            let ctx = stack.viewContext
            return await ctx.perform {
                let req = SleepDataEntity.recentRequest(days: 30)
                let results = (try? ctx.fetch(req)) ?? []
                guard !results.isEmpty else { return 0.0 }
                return results.reduce(0.0) { $0 + $1.totalHours } / Double(results.count)
            }
        }
    }

    var averageHRV: Double {
        get async {
            let ctx = stack.viewContext
            return await ctx.perform {
                let req = HRVDataEntity.recentRequest(days: 30)
                let results = (try? ctx.fetch(req)) ?? []
                guard !results.isEmpty else { return 0.0 }
                return results.reduce(0.0) { $0 + $1.averageHRV } / Double(results.count)
            }
        }
    }

    // MARK: - Sleep Data

    func storeSleepData(_ data: [SleepData]) {
        let ctx = stack.newBackgroundContext()
        ctx.performAndWait {
            for item in data {
                _ = SleepDataEntity.from(item, context: ctx)
            }
            CoreDataStack.save(ctx)
        }
    }

    func storeSleepData(_ data: SleepData) {
        let ctx = stack.newBackgroundContext()
        ctx.performAndWait {
            _ = SleepDataEntity.from(data, context: ctx)
            CoreDataStack.save(ctx)
        }
    }

    func getRecentSleep(days: Int) -> [SleepData] {
        let ctx = stack.viewContext
        var result: [SleepData] = []
        ctx.performAndWait {
            let req = SleepDataEntity.recentRequest(days: days)
            result = ((try? ctx.fetch(req)) ?? []).map { $0.toDomain() }
        }
        return result
    }

    // MARK: - HRV Data

    func storeHRVData(_ data: [HRVData]) {
        let ctx = stack.newBackgroundContext()
        ctx.performAndWait {
            for item in data {
                _ = HRVDataEntity.from(item, context: ctx)
            }
            CoreDataStack.save(ctx)
        }
    }

    func storeHRVData(_ data: HRVData) {
        let ctx = stack.newBackgroundContext()
        ctx.performAndWait {
            _ = HRVDataEntity.from(data, context: ctx)
            CoreDataStack.save(ctx)
        }
    }

    func getRecentHRV(days: Int) -> [HRVData] {
        let ctx = stack.viewContext
        var result: [HRVData] = []
        ctx.performAndWait {
            let req = HRVDataEntity.recentRequest(days: days)
            result = ((try? ctx.fetch(req)) ?? []).map { $0.toDomain() }
        }
        return result
    }

    func getBaselineHRV(days: Int) -> [HRVData] {
        getRecentHRV(days: days)
    }

    func getRecentRestingHR(days: Int) -> [Int] {
        let ctx = stack.viewContext
        var result: [Int] = []
        ctx.performAndWait {
            let req = RestingHREntity.recentRequest(days: days)
            let entities = (try? ctx.fetch(req)) ?? []
            result = entities.map { Int($0.bpm) }
        }
        return result
    }

    func getBaselineRestingHR(days: Int) -> [Int] {
        getRecentRestingHR(days: days)
    }

    // MARK: - Resting HR Storage

    func storeRestingHR(_ samples: [(bpm: Int, date: Date)]) {
        guard !samples.isEmpty else { return }
        let ctx = stack.newBackgroundContext()
        ctx.performAndWait {
            for sample in samples {
                _ = RestingHREntity.from(bpm: sample.bpm, date: sample.date, context: ctx)
            }
            CoreDataStack.save(ctx)
        }
    }

    // MARK: - Workouts

    func storeWorkouts(_ data: [DetectedWorkout]) {
        let ctx = stack.newBackgroundContext()
        ctx.performAndWait {
            for item in data {
                _ = WorkoutEntity.from(item, context: ctx)
            }
            CoreDataStack.save(ctx)
        }
    }

    func storeWorkout(_ workout: DetectedWorkout) {
        let ctx = stack.newBackgroundContext()
        ctx.performAndWait {
            _ = WorkoutEntity.from(workout, context: ctx)
            CoreDataStack.save(ctx)
        }
    }

    func getRecentWorkouts(days: Int) -> [DetectedWorkout] {
        let ctx = stack.viewContext
        var result: [DetectedWorkout] = []
        ctx.performAndWait {
            let req = WorkoutEntity.recentRequest(days: days)
            result = ((try? ctx.fetch(req)) ?? []).map { $0.toDomain() }
        }
        return result
    }

    // MARK: - Cleanup (90-day retention)

    func pruneOldData() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date())! as NSDate
        let pred = NSPredicate(format: "date < %@", cutoff)
        let pred2 = NSPredicate(format: "startDate < %@", cutoff)

        let ctx = stack.newBackgroundContext()
        ctx.performAndWait {
            CoreDataStack.batchDelete(entityName: "SleepDataEntity", predicate: pred, in: ctx)
            CoreDataStack.batchDelete(entityName: "HRVDataEntity", predicate: pred, in: ctx)
            CoreDataStack.batchDelete(entityName: "WorkoutEntity", predicate: pred2, in: ctx)
            CoreDataStack.batchDelete(entityName: "RestingHREntity", predicate: pred, in: ctx)
        }
    }
}
