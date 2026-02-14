//
//  BehavioralMemoryStore.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Long-term behavioral memory storage.
//  Tracks preferences, sacred times, patterns, and learned behaviors.
//  Third tier of the Phenome storage system.
//

import Foundation
import CoreData

actor BehavioralMemoryStore {

    // MARK: - Singleton
    static let shared = BehavioralMemoryStore()

    // MARK: - Storage

    private var _workoutPreferences: WorkoutPreferences = .default
    private var sacredTimes: [SacredTime] = []
    private var timeSlotHistory: [TimeSlotKey: TimeSlotStats] = [:]
    private var workoutPatterns: [WorkoutPattern] = []

    // MARK: - Public Properties

    var workoutPreferences: WorkoutPreferences {
        _workoutPreferences
    }

    var preferredWorkoutTime: String {
        _workoutPreferences.preferredTimeOfDay
    }

    var availableEquipment: [String] {
        _workoutPreferences.equipment
    }

    // MARK: - Preference Updates

    func updatePreferences(_ preferences: WorkoutPreferences) {
        _workoutPreferences = preferences
        persistPreferences()
    }

    /// Convenience overload for updating from raw dictionary (e.g. onboarding)
    func updatePreferences(_ dict: [String: Any]) {
        // Apply known keys to the current preferences
        if let days = dict["workout_days_per_week"] as? Int {
            _workoutPreferences.preferredDays = Array(2...(min(days + 1, 7)))
        }
        if let duration = dict["preferred_duration"] as? Int {
            _workoutPreferences.sessionDurationMinutes = duration
        }
        persistPreferences()
    }

    // MARK: - Workout Tracking

    func recordWorkoutCompletion(type: WorkoutType, time: Date) {
        let key = TimeSlotKey(from: time)

        var stats = timeSlotHistory[key] ?? TimeSlotStats()
        stats.completedCount += 1
        stats.lastCompleted = time
        timeSlotHistory[key] = stats

        // Update patterns
        updatePatterns(type: type, time: time, completed: true)
    }

    func recordMissedWorkout(time: Date, type: WorkoutType) {
        let key = TimeSlotKey(from: time)

        var stats = timeSlotHistory[key] ?? TimeSlotStats()
        stats.missedCount += 1
        stats.lastMissed = time
        timeSlotHistory[key] = stats

        // Update patterns
        updatePatterns(type: type, time: time, completed: false)
    }

    // MARK: - Time Slot Analysis

    func penalizeTimeSlot(_ time: Date) {
        let key = TimeSlotKey(from: time)

        var stats = timeSlotHistory[key] ?? TimeSlotStats()
        stats.penaltyCount += 1
        timeSlotHistory[key] = stats

        // Check if this should become sacred time
        if stats.penaltyCount >= 3 {
            addSacredTime(for: key)
        }
    }

    func getTimeSlotScore(_ key: TimeSlotKey) -> Double {
        guard let stats = timeSlotHistory[key] else { return 50.0 }
        return stats.successRate * 100
    }

    func isTimeSlotViable(_ key: TimeSlotKey) -> Bool {
        // Check if time slot is not sacred and has acceptable success rate
        let isSacred = sacredTimes.contains { $0.matches(key) }
        if isSacred { return false }

        guard let stats = timeSlotHistory[key] else { return true }
        return stats.successRate >= 0.3 // At least 30% success rate
    }

    // MARK: - Sacred Times

    private func addSacredTime(for key: TimeSlotKey) {
        let sacred = SacredTime(
            dayOfWeek: key.dayOfWeek,
            hourOfDay: key.hourOfDay,
            reason: .repeatedDeletions,
            createdAt: Date()
        )

        if !sacredTimes.contains(where: { $0.matches(key) }) {
            sacredTimes.append(sacred)
        }
    }

    func addSacredTime(_ sacred: SacredTime) {
        if !sacredTimes.contains(where: { $0.dayOfWeek == sacred.dayOfWeek && $0.hourOfDay == sacred.hourOfDay }) {
            sacredTimes.append(sacred)
        }
    }

    func removeSacredTime(dayOfWeek: Int, hourOfDay: Int) {
        sacredTimes.removeAll { $0.dayOfWeek == dayOfWeek && $0.hourOfDay == hourOfDay }
    }

    func getSacredTimes() -> [SacredTime] {
        sacredTimes
    }

    func isSacredTime(_ date: Date) -> Bool {
        let key = TimeSlotKey(from: date)
        return sacredTimes.contains { $0.matches(key) }
    }

    // MARK: - Pattern Analysis

    private func updatePatterns(type: WorkoutType, time: Date, completed: Bool) {
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: time)
        let hour = calendar.component(.hour, from: time)

        // Find or create pattern
        if let index = workoutPatterns.firstIndex(where: { $0.workoutType == type && $0.dayOfWeek == dayOfWeek }) {
            var pattern = workoutPatterns[index]
            if completed {
                pattern.successCount += 1
            } else {
                pattern.failureCount += 1
            }
            pattern.preferredHour = hour
            workoutPatterns[index] = pattern
        } else {
            let pattern = WorkoutPattern(
                workoutType: type,
                dayOfWeek: dayOfWeek,
                preferredHour: hour,
                successCount: completed ? 1 : 0,
                failureCount: completed ? 0 : 1
            )
            workoutPatterns.append(pattern)
        }
    }

    func getBestTimeFor(workoutType: WorkoutType, dayOfWeek: Int) -> Int? {
        let matchingPatterns = workoutPatterns.filter {
            $0.workoutType == workoutType && $0.dayOfWeek == dayOfWeek && $0.successRate >= 0.5
        }

        return matchingPatterns.max(by: { $0.successRate < $1.successRate })?.preferredHour
    }

    // MARK: - Persistence

    private var stack: CoreDataStack { CoreDataStack.shared }

    private func persistPreferences() {
        if let data = try? JSONEncoder().encode(_workoutPreferences) {
            UserDefaults.standard.set(data, forKey: "workoutPreferences")
        }
    }

    /// Save all behavioral data to Core Data (sacred times, time slots, patterns).
    func saveAll() {
        let ctx = stack.newBackgroundContext()
        ctx.performAndWait {
            // --- Sacred Times: delete all, re-insert ---
            let deleteSacred = NSFetchRequest<NSFetchRequestResult>(entityName: "SacredTimeEntity")
            if let deleteReq = try? NSBatchDeleteRequest(fetchRequest: deleteSacred) as NSPersistentStoreRequest {
                _ = try? ctx.execute(deleteReq as! NSPersistentStoreRequest)
            }
            for sacred in sacredTimes {
                _ = SacredTimeEntity.from(sacred, context: ctx)
            }

            // --- Time Slot Stats: delete all, re-insert ---
            let deleteSlots = NSFetchRequest<NSFetchRequestResult>(entityName: "TimeSlotStatsEntity")
            if let deleteReq = try? NSBatchDeleteRequest(fetchRequest: deleteSlots) as NSPersistentStoreRequest {
                _ = try? ctx.execute(deleteReq as! NSPersistentStoreRequest)
            }
            for (key, stats) in timeSlotHistory {
                _ = TimeSlotStatsEntity.from(key: key, stats: stats, context: ctx)
            }

            // --- Workout Patterns: delete all, re-insert ---
            let deletePatterns = NSFetchRequest<NSFetchRequestResult>(entityName: "WorkoutPatternEntity")
            if let deleteReq = try? NSBatchDeleteRequest(fetchRequest: deletePatterns) as NSPersistentStoreRequest {
                _ = try? ctx.execute(deleteReq as! NSPersistentStoreRequest)
            }
            for pattern in workoutPatterns {
                _ = WorkoutPatternEntity.from(pattern, context: ctx)
            }

            CoreDataStack.save(ctx)
        }
    }

    /// Load all behavioral data from Core Data + UserDefaults.
    func loadPersistedData() {
        // Load preferences from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "workoutPreferences"),
           let preferences = try? JSONDecoder().decode(WorkoutPreferences.self, from: data) {
            _workoutPreferences = preferences
        }

        // Load sacred times from Core Data
        let ctx = stack.viewContext
        ctx.performAndWait {
            let sacredReq = SacredTimeEntity.fetchRequest()
            sacredTimes = ((try? ctx.fetch(sacredReq)) ?? []).map { $0.toDomain() }

            // Load time slot history
            let slotReq = TimeSlotStatsEntity.fetchRequest()
            let slotEntities = (try? ctx.fetch(slotReq)) ?? []
            timeSlotHistory = [:]
            for entity in slotEntities {
                let (key, stats) = entity.toDomain()
                timeSlotHistory[key] = stats
            }

            // Load workout patterns
            let patternReq = WorkoutPatternEntity.fetchRequest()
            workoutPatterns = ((try? ctx.fetch(patternReq)) ?? []).map { $0.toDomain() }
        }
    }
}

// MARK: - Time Slot Stats

struct TimeSlotStats: Codable {
    var completedCount: Int = 0
    var missedCount: Int = 0
    var penaltyCount: Int = 0
    var lastCompleted: Date?
    var lastMissed: Date?

    var successRate: Double {
        let total = completedCount + missedCount
        guard total > 0 else { return 0.5 }
        return Double(completedCount) / Double(total)
    }
}

// MARK: - Sacred Time

struct SacredTime: Codable, Identifiable {
    let id: UUID
    let dayOfWeek: Int     // 1-7 (Sunday-Saturday)
    let hourOfDay: Int     // 0-23
    let reason: SacredTimeReason
    let createdAt: Date

    init(dayOfWeek: Int, hourOfDay: Int, reason: SacredTimeReason, createdAt: Date = Date()) {
        self.id = UUID()
        self.dayOfWeek = dayOfWeek
        self.hourOfDay = hourOfDay
        self.reason = reason
        self.createdAt = createdAt
    }

    func matches(_ key: TimeSlotKey) -> Bool {
        dayOfWeek == key.dayOfWeek && hourOfDay == key.hourOfDay
    }
}

enum SacredTimeReason: String, Codable {
    case repeatedDeletions = "repeated_deletions"
    case userSpecified = "user_specified"
    case weekendMorning = "weekend_morning"
    case lunchHour = "lunch_hour"
    case personalEvent = "personal_event"
}

// MARK: - Workout Pattern

struct WorkoutPattern: Codable {
    let workoutType: WorkoutType
    let dayOfWeek: Int
    var preferredHour: Int
    var successCount: Int
    var failureCount: Int

    var successRate: Double {
        let total = successCount + failureCount
        guard total > 0 else { return 0 }
        return Double(successCount) / Double(total)
    }
}
