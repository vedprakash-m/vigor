//
//  DerivedStateStore.swift
//  Vigor
//
//  Derived state storage for computed metrics and predictions.
//  Second tier of the Phenome storage system.
//
//  Backed by Core Data for persistence across app launches.
//

import Foundation
import CoreData

actor DerivedStateStore {

    // MARK: - Singleton

    static let shared = DerivedStateStore()

    // MARK: - Core Data

    private var stack: CoreDataStack { CoreDataStack.shared }

    // MARK: - Aggregates

    var averageWorkoutsPerWeek: Double {
        get async {
            await loadWorkoutStats().averagePerWeek
        }
    }

    // MARK: - Blocks

    func storeBlock(_ block: TrainingBlock) {
        let ctx = stack.newBackgroundContext()
        ctx.performAndWait {
            // Upsert – delete existing block with same id
            let delReq = NSFetchRequest<TrainingBlockEntity>(entityName: "TrainingBlockEntity")
            delReq.predicate = NSPredicate(format: "id == %@", block.id)
            if let existing = try? ctx.fetch(delReq).first { ctx.delete(existing) }
            _ = TrainingBlockEntity.from(block, context: ctx)
            CoreDataStack.save(ctx)
        }
    }

    func getBlock(by id: String) -> TrainingBlock? {
        let ctx = stack.viewContext
        var result: TrainingBlock?
        ctx.performAndWait {
            let req = NSFetchRequest<TrainingBlockEntity>(entityName: "TrainingBlockEntity")
            req.predicate = NSPredicate(format: "id == %@", id)
            req.fetchLimit = 1
            result = (try? ctx.fetch(req))?.first?.toDomain()
        }
        return result
    }

    func getTrainingBlocks(forWeekOf date: Date) -> [TrainingBlock] {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)),
              let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return []
        }
        let ctx = stack.viewContext
        var result: [TrainingBlock] = []
        ctx.performAndWait {
            let req = NSFetchRequest<TrainingBlockEntity>(entityName: "TrainingBlockEntity")
            req.predicate = NSPredicate(format: "startTime >= %@ AND startTime < %@", weekStart as NSDate, weekEnd as NSDate)
            result = ((try? ctx.fetch(req)) ?? []).map { $0.toDomain() }
        }
        return result
    }

    func updateBlockStatus(_ blockId: String, status: BlockStatus) {
        let ctx = stack.newBackgroundContext()
        ctx.performAndWait {
            let req = NSFetchRequest<TrainingBlockEntity>(entityName: "TrainingBlockEntity")
            req.predicate = NSPredicate(format: "id == %@", blockId)
            req.fetchLimit = 1
            if let entity = (try? ctx.fetch(req))?.first {
                entity.status = status.rawValue
                CoreDataStack.save(ctx)
            }
        }
    }

    func updateBlockType(_ blockId: String, newType: WorkoutType) {
        let ctx = stack.newBackgroundContext()
        ctx.performAndWait {
            let req = NSFetchRequest<TrainingBlockEntity>(entityName: "TrainingBlockEntity")
            req.predicate = NSPredicate(format: "id == %@", blockId)
            req.fetchLimit = 1
            if let entity = (try? ctx.fetch(req))?.first {
                entity.workoutType = newType.rawValue
                entity.status = BlockStatus.transformed.rawValue
                CoreDataStack.save(ctx)
            }
        }
    }

    func updateBlockTime(_ blockId: String, newStart: Date, newEnd: Date) {
        let ctx = stack.newBackgroundContext()
        ctx.performAndWait {
            let req = NSFetchRequest<TrainingBlockEntity>(entityName: "TrainingBlockEntity")
            req.predicate = NSPredicate(format: "id == %@", blockId)
            req.fetchLimit = 1
            if let entity = (try? ctx.fetch(req))?.first {
                entity.startTime = newStart
                entity.endTime = newEnd
                CoreDataStack.save(ctx)
            }
        }
    }

    func recordMissedBlock(_ block: TrainingBlock) {
        updateBlockStatus(block.id, status: .missed)

        // Update workout stats
        let ctx = stack.newBackgroundContext()
        ctx.performAndWait {
            let stats = fetchOrCreateWorkoutStats(in: ctx)
            stats.rollWeekIfNeeded()
            stats.missedThisWeek += 1
            CoreDataStack.save(ctx)
        }
    }

    func recordMissedReason(blockId: String, reason: MissedWorkoutReason) {
        // Could extend TrainingBlockEntity with a missedReason field in future
    }

    // MARK: - Morning State

    func updateMorningState(
        recoveryScore: Double,
        sleepData: SleepData,
        hrvData: HRVData
    ) {
        let today = Calendar.current.startOfDay(for: Date())
        let ctx = stack.newBackgroundContext()
        ctx.performAndWait {
            // Upsert today's morning state
            let req = NSFetchRequest<MorningStateEntity>(entityName: "MorningStateEntity")
            req.predicate = NSPredicate(format: "date == %@", today as NSDate)
            if let existing = (try? ctx.fetch(req))?.first { ctx.delete(existing) }

            let state = MorningState(
                date: today,
                recoveryScore: recoveryScore,
                sleepHours: sleepData.totalHours,
                sleepQuality: sleepData.qualityScore,
                hrvAverage: hrvData.averageHRV,
                hrvTrend: hrvData.trend
            )
            _ = MorningStateEntity.from(state, context: ctx)
            CoreDataStack.save(ctx)
        }
    }

    // MARK: - Workout Updates

    func updateAfterWorkout(_ workout: DetectedWorkout) {
        let ctx = stack.newBackgroundContext()
        ctx.performAndWait {
            let stats = fetchOrCreateWorkoutStats(in: ctx)
            stats.rollWeekIfNeeded()
            stats.totalWorkouts += 1
            stats.workoutsThisWeek += 1
            CoreDataStack.save(ctx)
        }
    }

    // MARK: - Workout Stats Helpers

    private func loadWorkoutStats() async -> WorkoutStats {
        let ctx = stack.viewContext
        return await ctx.perform {
            let req = WorkoutStatsEntity.fetchRequest()
            req.fetchLimit = 1
            if let entity = (try? ctx.fetch(req))?.first {
                return entity.toDomain()
            }
            return WorkoutStats()
        }
    }

    private func fetchOrCreateWorkoutStats(in ctx: NSManagedObjectContext) -> WorkoutStatsEntity {
        let req = WorkoutStatsEntity.fetchRequest()
        req.fetchLimit = 1
        if let existing = (try? ctx.fetch(req))?.first {
            return existing
        }
        let entity = WorkoutStatsEntity(context: ctx)
        entity.totalWorkouts = 0
        entity.workoutsThisWeek = 0
        entity.weekStartDate = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))
        entity.missedThisWeek = 0
        return entity
    }

    // MARK: - Cleanup (30-day retention for derived data)

    func pruneOldData() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())! as NSDate
        let ctx = stack.newBackgroundContext()
        ctx.performAndWait {
            CoreDataStack.batchDelete(entityName: "TrainingBlockEntity",
                                      predicate: NSPredicate(format: "startTime < %@", cutoff),
                                      in: ctx)
            CoreDataStack.batchDelete(entityName: "MorningStateEntity",
                                      predicate: NSPredicate(format: "date < %@", cutoff),
                                      in: ctx)
        }
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
