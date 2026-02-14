//
//  PhenomeEntities.swift
//  Vigor
//
//  NSManagedObject subclasses for the Phenome Core Data model.
//  Each entity provides toDomain() and from(_:context:) for converting
//  between Core Data objects and Swift domain types.
//

import Foundation
import CoreData

// MARK: - SleepDataEntity

@objc(SleepDataEntity)
final class SleepDataEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var totalHours: Double
    @NSManaged var qualityScore: Double
    @NSManaged var date: Date
    @NSManaged var stagesJSON: String?

    func toDomain() -> SleepData {
        let stages: [SleepStage] = {
            guard let json = stagesJSON, let data = json.data(using: .utf8) else { return [] }
            return (try? JSONDecoder().decode([SleepStage].self, from: data)) ?? []
        }()
        return SleepData(totalHours: totalHours, qualityScore: qualityScore, stages: stages)
    }

    static func from(_ domain: SleepData, date: Date = Date(), context: NSManagedObjectContext) -> SleepDataEntity {
        let entity = SleepDataEntity(context: context)
        entity.id = UUID()
        entity.totalHours = domain.totalHours
        entity.qualityScore = domain.qualityScore
        entity.date = domain.stages.first?.startDate ?? date
        entity.stagesJSON = {
            guard let data = try? JSONEncoder().encode(domain.stages) else { return "[]" }
            return String(data: data, encoding: .utf8) ?? "[]"
        }()
        return entity
    }

    static func fetchRequest() -> NSFetchRequest<SleepDataEntity> {
        NSFetchRequest<SleepDataEntity>(entityName: "SleepDataEntity")
    }

    static func recentRequest(days: Int) -> NSFetchRequest<SleepDataEntity> {
        let req = fetchRequest()
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        req.predicate = NSPredicate(format: "date >= %@", cutoff as NSDate)
        req.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return req
    }
}

// MARK: - HRVDataEntity

@objc(HRVDataEntity)
final class HRVDataEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var averageHRV: Double
    @NSManaged var trend: String?
    @NSManaged var date: Date
    @NSManaged var readingsJSON: String?

    func toDomain() -> HRVData {
        let readings: [HRVReading] = {
            guard let json = readingsJSON, let data = json.data(using: .utf8) else { return [] }
            return (try? JSONDecoder().decode([HRVReading].self, from: data)) ?? []
        }()
        return HRVData(
            averageHRV: averageHRV,
            trend: HRVTrend(rawValue: trend ?? "stable") ?? .stable,
            readings: readings
        )
    }

    static func from(_ domain: HRVData, date: Date = Date(), context: NSManagedObjectContext) -> HRVDataEntity {
        let entity = HRVDataEntity(context: context)
        entity.id = UUID()
        entity.averageHRV = domain.averageHRV
        entity.trend = domain.trend.rawValue
        entity.date = domain.readings.first?.date ?? date
        entity.readingsJSON = {
            guard let data = try? JSONEncoder().encode(domain.readings) else { return "[]" }
            return String(data: data, encoding: .utf8) ?? "[]"
        }()
        return entity
    }

    static func fetchRequest() -> NSFetchRequest<HRVDataEntity> {
        NSFetchRequest<HRVDataEntity>(entityName: "HRVDataEntity")
    }

    static func recentRequest(days: Int) -> NSFetchRequest<HRVDataEntity> {
        let req = fetchRequest()
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        req.predicate = NSPredicate(format: "date >= %@", cutoff as NSDate)
        req.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return req
    }
}

// MARK: - WorkoutEntity

@objc(WorkoutEntity)
final class WorkoutEntity: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var startDate: Date
    @NSManaged var endDate: Date
    @NSManaged var duration: Double
    @NSManaged var activeCalories: Double
    @NSManaged var averageHeartRate: Double
    @NSManaged var workoutType: String?
    @NSManaged var source: String?
    @NSManaged var wasConfirmed: Bool

    func toDomain() -> DetectedWorkout {
        DetectedWorkout(
            id: id,
            type: WorkoutType(rawValue: workoutType ?? "other") ?? .other,
            startDate: startDate,
            endDate: endDate,
            duration: duration,
            activeCalories: activeCalories,
            averageHeartRate: averageHeartRate > 0 ? averageHeartRate : nil,
            source: source ?? ""
        )
    }

    static func from(_ domain: DetectedWorkout, context: NSManagedObjectContext) -> WorkoutEntity {
        let entity = WorkoutEntity(context: context)
        entity.id = domain.id
        entity.startDate = domain.startDate
        entity.endDate = domain.endDate
        entity.duration = domain.duration
        entity.activeCalories = domain.activeCalories
        entity.averageHeartRate = domain.averageHeartRate ?? 0
        entity.workoutType = domain.type.rawValue
        entity.source = domain.source
        entity.wasConfirmed = false
        return entity
    }

    static func fetchRequest() -> NSFetchRequest<WorkoutEntity> {
        NSFetchRequest<WorkoutEntity>(entityName: "WorkoutEntity")
    }

    static func recentRequest(days: Int) -> NSFetchRequest<WorkoutEntity> {
        let req = fetchRequest()
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        req.predicate = NSPredicate(format: "startDate >= %@", cutoff as NSDate)
        req.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        return req
    }
}

// MARK: - TrainingBlockEntity

@objc(TrainingBlockEntity)
final class TrainingBlockEntity: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var calendarEventId: String?
    @NSManaged var workoutType: String?
    @NSManaged var startTime: Date
    @NSManaged var endTime: Date
    @NSManaged var wasAutoScheduled: Bool
    @NSManaged var status: String?
    @NSManaged var generatedWorkoutJSON: String?

    func toDomain() -> TrainingBlock {
        let workout: GeneratedWorkout? = {
            guard let json = generatedWorkoutJSON, let data = json.data(using: .utf8) else { return nil }
            return try? JSONDecoder().decode(GeneratedWorkout.self, from: data)
        }()
        return TrainingBlock(
            id: id,
            calendarEventId: calendarEventId ?? "",
            workoutType: WorkoutType(rawValue: workoutType ?? "other") ?? .other,
            startTime: startTime,
            endTime: endTime,
            wasAutoScheduled: wasAutoScheduled,
            status: BlockStatus(rawValue: status ?? "scheduled") ?? .scheduled,
            generatedWorkout: workout
        )
    }

    static func from(_ domain: TrainingBlock, context: NSManagedObjectContext) -> TrainingBlockEntity {
        let entity = TrainingBlockEntity(context: context)
        entity.id = domain.id
        entity.calendarEventId = domain.calendarEventId
        entity.workoutType = domain.workoutType.rawValue
        entity.startTime = domain.startTime
        entity.endTime = domain.endTime
        entity.wasAutoScheduled = domain.wasAutoScheduled
        entity.status = domain.status.rawValue
        entity.generatedWorkoutJSON = {
            guard let wk = domain.generatedWorkout,
                  let data = try? JSONEncoder().encode(wk) else { return nil }
            return String(data: data, encoding: .utf8)
        }()
        return entity
    }

    static func fetchRequest() -> NSFetchRequest<TrainingBlockEntity> {
        NSFetchRequest<TrainingBlockEntity>(entityName: "TrainingBlockEntity")
    }
}

// MARK: - MorningStateEntity

@objc(MorningStateEntity)
final class MorningStateEntity: NSManagedObject {
    @NSManaged var date: Date
    @NSManaged var recoveryScore: Double
    @NSManaged var sleepHours: Double
    @NSManaged var sleepQuality: Double
    @NSManaged var hrvAverage: Double
    @NSManaged var hrvTrend: String?

    func toDomain() -> MorningState {
        MorningState(
            date: date,
            recoveryScore: recoveryScore,
            sleepHours: sleepHours,
            sleepQuality: sleepQuality,
            hrvAverage: hrvAverage,
            hrvTrend: HRVTrend(rawValue: hrvTrend ?? "stable") ?? .stable
        )
    }

    static func from(_ domain: MorningState, context: NSManagedObjectContext) -> MorningStateEntity {
        let entity = MorningStateEntity(context: context)
        entity.date = domain.date
        entity.recoveryScore = domain.recoveryScore
        entity.sleepHours = domain.sleepHours
        entity.sleepQuality = domain.sleepQuality
        entity.hrvAverage = domain.hrvAverage
        entity.hrvTrend = domain.hrvTrend.rawValue
        return entity
    }

    static func fetchRequest() -> NSFetchRequest<MorningStateEntity> {
        NSFetchRequest<MorningStateEntity>(entityName: "MorningStateEntity")
    }
}

// MARK: - DecisionReceiptEntity

@objc(DecisionReceiptEntity)
final class DecisionReceiptEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var action: String
    @NSManaged var timestamp: Date
    @NSManaged var confidence: Double
    @NSManaged var outcomeJSON: String?
    @NSManaged var inputsJSON: String?
    @NSManaged var ttlDate: Date?

    func toDomain() -> DecisionReceipt {
        let inputs: [DecisionInput] = {
            guard let json = inputsJSON, let data = json.data(using: .utf8) else { return [] }
            return (try? JSONDecoder().decode([DecisionInput].self, from: data)) ?? []
        }()
        let outcome: DecisionOutcome = {
            guard let json = outcomeJSON, let data = json.data(using: .utf8) else { return .pending }
            return (try? JSONDecoder().decode(DecisionOutcome.self, from: data)) ?? .pending
        }()
        var receipt = DecisionReceipt(action: DecisionAction(rawValue: action) ?? .morningCycle)
        receipt.timestamp = timestamp
        receipt.inputs = inputs
        receipt.confidence = confidence
        receipt.outcome = outcome
        return receipt
    }

    static func from(_ domain: DecisionReceipt, context: NSManagedObjectContext) -> DecisionReceiptEntity {
        let entity = DecisionReceiptEntity(context: context)
        entity.id = domain.id
        entity.action = domain.action.rawValue
        entity.timestamp = domain.timestamp
        entity.confidence = domain.confidence
        entity.outcomeJSON = {
            guard let data = try? JSONEncoder().encode(domain.outcome) else { return "\"pending\"" }
            return String(data: data, encoding: .utf8) ?? "\"pending\""
        }()
        entity.inputsJSON = {
            guard let data = try? JSONEncoder().encode(domain.inputs) else { return "[]" }
            return String(data: data, encoding: .utf8) ?? "[]"
        }()
        entity.ttlDate = Calendar.current.date(byAdding: .day, value: 90, to: domain.timestamp)
        return entity
    }

    static func fetchRequest() -> NSFetchRequest<DecisionReceiptEntity> {
        NSFetchRequest<DecisionReceiptEntity>(entityName: "DecisionReceiptEntity")
    }
}

// MARK: - WorkoutStatsEntity

@objc(WorkoutStatsEntity)
final class WorkoutStatsEntity: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var totalWorkouts: Int32
    @NSManaged var workoutsThisWeek: Int16
    @NSManaged var missedThisWeek: Int16
    @NSManaged var weekStartDate: Date?

    func toDomain() -> WorkoutStats {
        WorkoutStats(
            totalWorkouts: Int(totalWorkouts),
            workoutsThisWeek: Int(workoutsThisWeek),
            weekStartDate: weekStartDate ?? Calendar.current.startOfDay(for: Date()),
            missedThisWeek: Int(missedThisWeek)
        )
    }

    /// Rolls weekly counters if the calendar week has changed.
    func rollWeekIfNeeded() {
        let calendar = Calendar.current
        let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let stored = weekStartDate ?? .distantPast
        if stored != currentWeekStart {
            weekStartDate = currentWeekStart
            workoutsThisWeek = 0
            missedThisWeek = 0
        }
    }

    static func fetchRequest() -> NSFetchRequest<WorkoutStatsEntity> {
        NSFetchRequest<WorkoutStatsEntity>(entityName: "WorkoutStatsEntity")
    }
}

// MARK: - RestingHREntity (Phase 11)

@objc(RestingHREntity)
final class RestingHREntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var bpm: Int16
    @NSManaged var date: Date

    static func from(bpm: Int, date: Date, context: NSManagedObjectContext) -> RestingHREntity {
        let entity = RestingHREntity(context: context)
        entity.id = UUID()
        entity.bpm = Int16(bpm)
        entity.date = date
        return entity
    }

    static func fetchRequest() -> NSFetchRequest<RestingHREntity> {
        NSFetchRequest<RestingHREntity>(entityName: "RestingHREntity")
    }

    static func recentRequest(days: Int) -> NSFetchRequest<RestingHREntity> {
        let req = fetchRequest()
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        req.predicate = NSPredicate(format: "date >= %@", cutoff as NSDate)
        req.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return req
    }
}

// MARK: - SacredTimeEntity (Phase 11)

@objc(SacredTimeEntity)
final class SacredTimeEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var dayOfWeek: Int16
    @NSManaged var hourOfDay: Int16
    @NSManaged var reason: String?
    @NSManaged var createdAt: Date

    func toDomain() -> SacredTime {
        SacredTime(
            dayOfWeek: Int(dayOfWeek),
            hourOfDay: Int(hourOfDay),
            reason: SacredTimeReason(rawValue: reason ?? "repeated_deletions") ?? .repeatedDeletions,
            createdAt: createdAt
        )
    }

    static func from(_ domain: SacredTime, context: NSManagedObjectContext) -> SacredTimeEntity {
        let entity = SacredTimeEntity(context: context)
        entity.id = domain.id
        entity.dayOfWeek = Int16(domain.dayOfWeek)
        entity.hourOfDay = Int16(domain.hourOfDay)
        entity.reason = domain.reason.rawValue
        entity.createdAt = domain.createdAt
        return entity
    }

    static func fetchRequest() -> NSFetchRequest<SacredTimeEntity> {
        NSFetchRequest<SacredTimeEntity>(entityName: "SacredTimeEntity")
    }
}

// MARK: - TimeSlotStatsEntity (Phase 11)

@objc(TimeSlotStatsEntity)
final class TimeSlotStatsEntity: NSManagedObject {
    @NSManaged var dayOfWeek: Int16
    @NSManaged var hourOfDay: Int16
    @NSManaged var completedCount: Int32
    @NSManaged var missedCount: Int32
    @NSManaged var penaltyCount: Int32
    @NSManaged var lastCompleted: Date?
    @NSManaged var lastMissed: Date?

    func toDomain() -> (key: TimeSlotKey, stats: TimeSlotStats) {
        let key = TimeSlotKey(dayOfWeek: Int(dayOfWeek), hourOfDay: Int(hourOfDay))
        let stats = TimeSlotStats(
            completedCount: Int(completedCount),
            missedCount: Int(missedCount),
            penaltyCount: Int(penaltyCount),
            lastCompleted: lastCompleted,
            lastMissed: lastMissed
        )
        return (key, stats)
    }

    static func from(key: TimeSlotKey, stats: TimeSlotStats, context: NSManagedObjectContext) -> TimeSlotStatsEntity {
        let entity = TimeSlotStatsEntity(context: context)
        entity.dayOfWeek = Int16(key.dayOfWeek)
        entity.hourOfDay = Int16(key.hourOfDay)
        entity.completedCount = Int32(stats.completedCount)
        entity.missedCount = Int32(stats.missedCount)
        entity.penaltyCount = Int32(stats.penaltyCount)
        entity.lastCompleted = stats.lastCompleted
        entity.lastMissed = stats.lastMissed
        return entity
    }

    static func fetchRequest() -> NSFetchRequest<TimeSlotStatsEntity> {
        NSFetchRequest<TimeSlotStatsEntity>(entityName: "TimeSlotStatsEntity")
    }

    /// Fetch the entity for a specific time slot, or nil if not found.
    static func request(for key: TimeSlotKey) -> NSFetchRequest<TimeSlotStatsEntity> {
        let req = fetchRequest()
        req.predicate = NSPredicate(format: "dayOfWeek == %d AND hourOfDay == %d", key.dayOfWeek, key.hourOfDay)
        req.fetchLimit = 1
        return req
    }
}

// MARK: - WorkoutPatternEntity (Phase 11)

@objc(WorkoutPatternEntity)
final class WorkoutPatternEntity: NSManagedObject {
    @NSManaged var workoutType: String
    @NSManaged var dayOfWeek: Int16
    @NSManaged var preferredHour: Int16
    @NSManaged var successCount: Int32
    @NSManaged var failureCount: Int32

    func toDomain() -> WorkoutPattern {
        WorkoutPattern(
            workoutType: WorkoutType(rawValue: workoutType) ?? .other,
            dayOfWeek: Int(dayOfWeek),
            preferredHour: Int(preferredHour),
            successCount: Int(successCount),
            failureCount: Int(failureCount)
        )
    }

    static func from(_ domain: WorkoutPattern, context: NSManagedObjectContext) -> WorkoutPatternEntity {
        let entity = WorkoutPatternEntity(context: context)
        entity.workoutType = domain.workoutType.rawValue
        entity.dayOfWeek = Int16(domain.dayOfWeek)
        entity.preferredHour = Int16(domain.preferredHour)
        entity.successCount = Int32(domain.successCount)
        entity.failureCount = Int32(domain.failureCount)
        return entity
    }

    static func fetchRequest() -> NSFetchRequest<WorkoutPatternEntity> {
        NSFetchRequest<WorkoutPatternEntity>(entityName: "WorkoutPatternEntity")
    }

    /// Fetch by workout type and day of week.
    static func request(type: WorkoutType, dayOfWeek: Int) -> NSFetchRequest<WorkoutPatternEntity> {
        let req = fetchRequest()
        req.predicate = NSPredicate(format: "workoutType == %@ AND dayOfWeek == %d", type.rawValue, dayOfWeek)
        req.fetchLimit = 1
        return req
    }
}
