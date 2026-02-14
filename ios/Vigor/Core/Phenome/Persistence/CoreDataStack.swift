//
//  CoreDataStack.swift
//  Vigor
//
//  Core Data persistence stack for the Phenome storage system.
//  Uses a programmatic model (no .xcdatamodeld file) for portability with xcodegen.
//
//  Entities:
//    SleepDataEntity, HRVDataEntity, WorkoutEntity, TrainingBlockEntity,
//    MorningStateEntity, DecisionReceiptEntity, WorkoutStatsEntity
//

import Foundation
import CoreData

final class CoreDataStack: @unchecked Sendable {

    // MARK: - Singleton

    static let shared = CoreDataStack()

    // MARK: - Container

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    // MARK: - Initialization

    private init() {
        let model = CoreDataStack.buildModel()

        #if ENABLE_CLOUDKIT
        container = NSPersistentCloudKitContainer(name: "Vigor", managedObjectModel: model)
        if let desc = container.persistentStoreDescriptions.first {
            desc.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.vigor.phenome"
            )
            desc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            desc.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }
        #else
        container = NSPersistentContainer(name: "Vigor", managedObjectModel: model)
        #endif

        container.loadPersistentStores { _, error in
            if let error {
                // Non-fatal in debug: log and continue with in-memory fallback
                #if DEBUG
                print("⚠️ CoreDataStack: Failed to load store — \(error.localizedDescription)")
                #endif
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Background Context

    func newBackgroundContext() -> NSManagedObjectContext {
        let ctx = container.newBackgroundContext()
        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return ctx
    }

    func performBackground(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }

    // MARK: - Save Helpers

    func saveViewContext() {
        let ctx = viewContext
        guard ctx.hasChanges else { return }
        do {
            try ctx.save()
        } catch {
            #if DEBUG
            print("⚠️ CoreDataStack: viewContext save failed — \(error.localizedDescription)")
            #endif
        }
    }

    static func save(_ context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            #if DEBUG
            print("⚠️ CoreDataStack: context save failed — \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Batch Delete

    static func batchDelete(
        entityName: String,
        predicate: NSPredicate,
        in context: NSManagedObjectContext
    ) {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetch.predicate = predicate
        let deleteReq = NSBatchDeleteRequest(fetchRequest: fetch)
        deleteReq.resultType = .resultTypeObjectIDs

        do {
            if let result = try context.execute(deleteReq) as? NSBatchDeleteResult,
               let ids = result.result as? [NSManagedObjectID] {
                let changes = [NSDeletedObjectsKey: ids]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
            }
        } catch {
            #if DEBUG
            print("⚠️ CoreDataStack: batch delete failed — \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Programmatic Model Builder

    private static func buildModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // ── SleepDataEntity ──────────────────────────────────
        let sleep = NSEntityDescription()
        sleep.name = "SleepDataEntity"
        sleep.managedObjectClassName = "SleepDataEntity"
        sleep.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("totalHours", .doubleAttributeType),
            attribute("qualityScore", .doubleAttributeType),
            attribute("date", .dateAttributeType, optional: false),
            attribute("stagesJSON", .stringAttributeType, defaultValue: "[]"),
        ]

        // ── HRVDataEntity ────────────────────────────────────
        let hrv = NSEntityDescription()
        hrv.name = "HRVDataEntity"
        hrv.managedObjectClassName = "HRVDataEntity"
        hrv.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("averageHRV", .doubleAttributeType),
            attribute("trend", .stringAttributeType, defaultValue: "stable"),
            attribute("date", .dateAttributeType, optional: false),
            attribute("readingsJSON", .stringAttributeType, defaultValue: "[]"),
        ]

        // ── WorkoutEntity ────────────────────────────────────
        let workout = NSEntityDescription()
        workout.name = "WorkoutEntity"
        workout.managedObjectClassName = "WorkoutEntity"
        workout.properties = [
            attribute("id", .stringAttributeType, optional: false),
            attribute("startDate", .dateAttributeType, optional: false),
            attribute("endDate", .dateAttributeType, optional: false),
            attribute("duration", .doubleAttributeType),
            attribute("activeCalories", .doubleAttributeType),
            attribute("averageHeartRate", .doubleAttributeType),
            attribute("workoutType", .stringAttributeType, defaultValue: "other"),
            attribute("source", .stringAttributeType, defaultValue: ""),
            attribute("wasConfirmed", .booleanAttributeType, defaultValue: false),
        ]

        // ── TrainingBlockEntity ──────────────────────────────
        let block = NSEntityDescription()
        block.name = "TrainingBlockEntity"
        block.managedObjectClassName = "TrainingBlockEntity"
        block.properties = [
            attribute("id", .stringAttributeType, optional: false),
            attribute("calendarEventId", .stringAttributeType, defaultValue: ""),
            attribute("workoutType", .stringAttributeType, defaultValue: "other"),
            attribute("startTime", .dateAttributeType, optional: false),
            attribute("endTime", .dateAttributeType, optional: false),
            attribute("wasAutoScheduled", .booleanAttributeType, defaultValue: false),
            attribute("status", .stringAttributeType, defaultValue: "scheduled"),
            attribute("generatedWorkoutJSON", .stringAttributeType),
        ]

        // ── MorningStateEntity ───────────────────────────────
        let morning = NSEntityDescription()
        morning.name = "MorningStateEntity"
        morning.managedObjectClassName = "MorningStateEntity"
        morning.properties = [
            attribute("date", .dateAttributeType, optional: false),
            attribute("recoveryScore", .doubleAttributeType),
            attribute("sleepHours", .doubleAttributeType),
            attribute("sleepQuality", .doubleAttributeType),
            attribute("hrvAverage", .doubleAttributeType),
            attribute("hrvTrend", .stringAttributeType, defaultValue: "stable"),
        ]

        // ── DecisionReceiptEntity ────────────────────────────
        let receipt = NSEntityDescription()
        receipt.name = "DecisionReceiptEntity"
        receipt.managedObjectClassName = "DecisionReceiptEntity"
        receipt.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("action", .stringAttributeType, optional: false),
            attribute("timestamp", .dateAttributeType, optional: false),
            attribute("confidence", .doubleAttributeType),
            attribute("outcomeJSON", .stringAttributeType, defaultValue: "\"pending\""),
            attribute("inputsJSON", .stringAttributeType, defaultValue: "[]"),
            attribute("ttlDate", .dateAttributeType),
        ]

        // ── WorkoutStatsEntity ───────────────────────────────
        let stats = NSEntityDescription()
        stats.name = "WorkoutStatsEntity"
        stats.managedObjectClassName = "WorkoutStatsEntity"
        stats.properties = [
            attribute("id", .stringAttributeType, optional: false),
            attribute("totalWorkouts", .integer32AttributeType),
            attribute("workoutsThisWeek", .integer16AttributeType),
            attribute("missedThisWeek", .integer16AttributeType),
            attribute("weekStartDate", .dateAttributeType, optional: false),
        ]

        model.entities = [sleep, hrv, workout, block, morning, receipt, stats,
                          buildRestingHREntity(), buildSacredTimeEntity(),
                          buildTimeSlotStatsEntity(), buildWorkoutPatternEntity()]
        return model
    }

    // MARK: - Phase 11 Entities

    /// Resting heart rate samples from HealthKit
    private static func buildRestingHREntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "RestingHREntity"
        entity.managedObjectClassName = "RestingHREntity"
        entity.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("bpm", .integer16AttributeType),
            attribute("date", .dateAttributeType, optional: false),
        ]
        return entity
    }

    /// Sacred times learned by BehavioralMemoryStore
    private static func buildSacredTimeEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "SacredTimeEntity"
        entity.managedObjectClassName = "SacredTimeEntity"
        entity.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("dayOfWeek", .integer16AttributeType),
            attribute("hourOfDay", .integer16AttributeType),
            attribute("reason", .stringAttributeType, defaultValue: "repeated_deletions"),
            attribute("createdAt", .dateAttributeType, optional: false),
        ]
        return entity
    }

    /// Time slot statistics tracked by BehavioralMemoryStore
    private static func buildTimeSlotStatsEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "TimeSlotStatsEntity"
        entity.managedObjectClassName = "TimeSlotStatsEntity"
        entity.properties = [
            attribute("dayOfWeek", .integer16AttributeType),
            attribute("hourOfDay", .integer16AttributeType),
            attribute("completedCount", .integer32AttributeType, defaultValue: 0),
            attribute("missedCount", .integer32AttributeType, defaultValue: 0),
            attribute("penaltyCount", .integer32AttributeType, defaultValue: 0),
            attribute("lastCompleted", .dateAttributeType),
            attribute("lastMissed", .dateAttributeType),
        ]
        return entity
    }

    /// Workout patterns tracked by BehavioralMemoryStore
    private static func buildWorkoutPatternEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "WorkoutPatternEntity"
        entity.managedObjectClassName = "WorkoutPatternEntity"
        entity.properties = [
            attribute("workoutType", .stringAttributeType, optional: false),
            attribute("dayOfWeek", .integer16AttributeType),
            attribute("preferredHour", .integer16AttributeType),
            attribute("successCount", .integer32AttributeType, defaultValue: 0),
            attribute("failureCount", .integer32AttributeType, defaultValue: 0),
        ]
        return entity
    }

    // MARK: - Attribute Factory

    private static func attribute(
        _ name: String,
        _ type: NSAttributeType,
        optional: Bool = true,
        defaultValue: Any? = nil
    ) -> NSAttributeDescription {
        let attr = NSAttributeDescription()
        attr.name = name
        attr.attributeType = type
        attr.isOptional = optional
        if let val = defaultValue {
            attr.defaultValue = val
        }
        return attr
    }
}
