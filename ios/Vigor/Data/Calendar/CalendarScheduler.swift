//
//  CalendarScheduler.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  EventKit integration for calendar scheduling.
//  Creates and manages workout blocks in the user's calendar.
//
//  Per Task 1.4 - Calendar Multiplexing:
//  - Read from ALL calendars (Exchange, Outlook, iCloud, Google)
//  - Write ONLY to local Vigor calendar
//

import Foundation
import EventKit
import Combine

@MainActor
final class CalendarScheduler: ObservableObject {

    // MARK: - Singleton

    static let shared = CalendarScheduler()

    // MARK: - Published State

    @Published private(set) var isAuthorized = false
    @Published private(set) var vigorCalendar: EKCalendar?
    @Published private(set) var blockerCalendars: [EKCalendar] = []

    // MARK: - EventKit Store

    let eventStore = EKEventStore()

    // MARK: - Constants

    private let vigorCalendarTitle = "Vigor Training"

    // MARK: - Initialization

    private init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func requestAuthorization() async throws {
        let status = try await eventStore.requestFullAccessToEvents()

        guard status else {
            throw CalendarError.authorizationDenied
        }

        isAuthorized = true

        // Setup or find Vigor calendar
        try await setupVigorCalendar()

        // Load all calendars for reading
        await loadBlockerCalendars()
    }

    private func checkAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        isAuthorized = status == .fullAccess
    }

    // MARK: - Calendar Setup

    private func setupVigorCalendar() async throws {
        // Find existing Vigor calendar
        let calendars = eventStore.calendars(for: .event)

        if let existing = calendars.first(where: { $0.title == vigorCalendarTitle }) {
            vigorCalendar = existing
            return
        }

        // Create new local calendar for Vigor
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        newCalendar.title = vigorCalendarTitle

        // Use local source only (prevents corporate sync pollution)
        if let localSource = eventStore.sources.first(where: { $0.sourceType == .local }) {
            newCalendar.source = localSource
        } else if let defaultSource = eventStore.defaultCalendarForNewEvents?.source {
            newCalendar.source = defaultSource
        }

        // Set calendar color
        newCalendar.cgColor = CGColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0)

        try eventStore.saveCalendar(newCalendar, commit: true)
        vigorCalendar = newCalendar
    }

    private func loadBlockerCalendars() async {
        // Load all calendars for conflict detection
        blockerCalendars = eventStore.calendars(for: .event)
            .filter { $0.title != vigorCalendarTitle }
    }

    // MARK: - Block Creation

    func createBlock(
        workout: GeneratedWorkout,
        window: TimeWindow
    ) async throws {
        guard let calendar = vigorCalendar else {
            throw CalendarError.noVigorCalendar
        }

        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        event.title = "💪 \(workout.name)"
        event.startDate = window.start
        event.endDate = window.end
        event.notes = formatWorkoutNotes(workout)

        // Add structured data
        event.url = URL(string: "vigor://block/\(workout.id)")

        // Set alarm 15 minutes before
        let alarm = EKAlarm(relativeOffset: -15 * 60)
        event.alarms = [alarm]

        try eventStore.save(event, span: .thisEvent)

        // Store block reference
        let block = TrainingBlock(
            id: UUID().uuidString,
            calendarEventId: event.eventIdentifier,
            workoutType: workout.type,
            startTime: window.start,
            endTime: window.end,
            wasAutoScheduled: true,
            status: .scheduled,
            generatedWorkout: workout
        )

        await PhenomeCoordinator.shared.storeBlock(block)

        // Trigger Shadow Sync to corporate calendars
        await CalendarShadowSync.shared.syncToExchange(block: block)
    }

    private func formatWorkoutNotes(_ workout: GeneratedWorkout) -> String {
        var notes = "🏋️ Vigor Workout\n\n"
        notes += "\(workout.description)\n\n"
        notes += "Duration: \(workout.durationMinutes) minutes\n\n"

        if let warmup = workout.warmup {
            notes += "Warmup:\n"
            for exercise in warmup {
                notes += "• \(exercise.name)\n"
            }
            notes += "\n"
        }

        notes += "Exercises:\n"
        for exercise in workout.exercises {
            var line = "• \(exercise.name)"
            if let sets = exercise.sets, let reps = exercise.reps {
                line += " - \(sets)x\(reps)"
            } else if let duration = exercise.duration {
                line += " - \(duration)s"
            }
            notes += line + "\n"
        }

        return notes
    }

    // MARK: - Block Queries

    func fetchTodayBlocks() async throws -> [TrainingBlock] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return try await fetchBlocks(from: startOfDay, to: endOfDay)
    }

    func fetchBlocks(from startDate: Date, to endDate: Date) async throws -> [TrainingBlock] {
        guard let vigorCal = vigorCalendar else {
            return []
        }

        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: [vigorCal]
        )

        let events = eventStore.events(matching: predicate)

        return events.compactMap { event -> TrainingBlock? in
            // Parse workout type from event
            let workoutType = parseWorkoutType(from: event.title)

            return TrainingBlock(
                id: event.eventIdentifier,
                calendarEventId: event.eventIdentifier,
                workoutType: workoutType,
                startTime: event.startDate,
                endTime: event.endDate,
                wasAutoScheduled: true,  // Assume auto-scheduled if in Vigor calendar
                status: .scheduled,
                generatedWorkout: nil
            )
        }
    }

    func fetchTomorrowBusySlots() async throws -> [BusySlot] {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let startOfTomorrow = calendar.startOfDay(for: tomorrow)
        let endOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfTomorrow)!

        return try await fetchBusySlots(from: startOfTomorrow, to: endOfTomorrow)
    }

    func fetchBusySlots(from startDate: Date, to endDate: Date) async throws -> [BusySlot] {
        // Read from ALL calendars for conflict detection
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: blockerCalendars
        )

        let events = eventStore.events(matching: predicate)

        return events.compactMap { event -> BusySlot? in
            // Skip all-day events unless marked as Busy
            if event.isAllDay && event.availability != .busy {
                return nil
            }

            return BusySlot(
                startDate: event.startDate,
                endDate: event.endDate,
                title: event.title,
                calendarId: event.calendar.calendarIdentifier,
                isAllDay: event.isAllDay
            )
        }
    }

    private func parseWorkoutType(from title: String?) -> WorkoutType {
        guard let title = title?.lowercased() else { return .other }

        if title.contains("strength") || title.contains("lift") {
            return .strength
        } else if title.contains("cardio") || title.contains("run") {
            return .cardio
        } else if title.contains("hiit") {
            return .hiit
        } else if title.contains("yoga") || title.contains("stretch") {
            return .flexibility
        } else if title.contains("walk") || title.contains("recovery") {
            return .recoveryWalk
        }

        return .other
    }

    // MARK: - Block Modifications

    func removeBlock(_ block: TrainingBlock) async throws {
        guard let event = eventStore.event(withIdentifier: block.calendarEventId) else {
            throw CalendarError.eventNotFound
        }

        try eventStore.remove(event, span: .thisEvent)

        // Update block status
        await PhenomeCoordinator.shared.updateBlockStatus(block.id, status: .cancelled)

        // Remove from Shadow Sync
        await CalendarShadowSync.shared.removeFromExchange(blockId: block.id)
    }

    func transformBlock(_ block: TrainingBlock, to newType: WorkoutType) async throws {
        guard let event = eventStore.event(withIdentifier: block.calendarEventId) else {
            throw CalendarError.eventNotFound
        }

        // Update event title
        event.title = "💪 \(newType.displayName)"

        try eventStore.save(event, span: .thisEvent)

        // Update block in Phenome
        await PhenomeCoordinator.shared.updateBlockType(block.id, newType: newType)
    }

    func markBlockCompleted(_ block: TrainingBlock) async {
        await PhenomeCoordinator.shared.updateBlockStatus(block.id, status: .completed)
    }

    // MARK: - Block Matching

    func findMatchingBlock(for workout: DetectedWorkout) async -> TrainingBlock? {
        // Find a scheduled block that matches the workout time
        let calendar = Calendar.current
        let windowStart = calendar.date(byAdding: .hour, value: -1, to: workout.startDate)!
        let windowEnd = calendar.date(byAdding: .hour, value: 1, to: workout.endDate)!

        do {
            let blocks = try await fetchBlocks(from: windowStart, to: windowEnd)
            return blocks.first { block in
                block.status == .scheduled &&
                abs(block.startTime.timeIntervalSince(workout.startDate)) < 3600
            }
        } catch {
            return nil
        }
    }

    func findMissedBlocks() async -> [TrainingBlock] {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        let now = Date()

        do {
            let blocks = try await fetchBlocks(from: yesterday, to: now)
            return blocks.filter { block in
                block.status == .scheduled && block.endTime < now
            }
        } catch {
            return []
        }
    }

    func getBlock(by id: String) async -> TrainingBlock? {
        // Query Phenome for stored block
        return await PhenomeCoordinator.shared.getBlock(by: id)
    }

    // MARK: - Meeting Analytics

    func getMeetingCount(for date: Date) async -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        do {
            let busySlots = try await fetchBusySlots(from: startOfDay, to: endOfDay)
            return busySlots.filter { !$0.isAllDay }.count
        } catch {
            return 0
        }
    }

    func getAverageDailyMeetings() async -> Double {
        // Get average meetings over last 30 days
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: endDate)!

        var totalMeetings = 0
        var daysWithData = 0

        for dayOffset in 0..<30 {
            let day = calendar.date(byAdding: .day, value: -dayOffset, to: endDate)!
            let count = await getMeetingCount(for: day)
            if count > 0 {
                totalMeetings += count
                daysWithData += 1
            }
        }

        guard daysWithData > 0 else { return 5.0 } // Default
        return Double(totalMeetings) / Double(daysWithData)
    }
}

// MARK: - Calendar Error

enum CalendarError: LocalizedError {
    case authorizationDenied
    case noVigorCalendar
    case eventNotFound
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Calendar access was denied"
        case .noVigorCalendar:
            return "Vigor calendar not found"
        case .eventNotFound:
            return "Calendar event not found"
        case .saveFailed(let message):
            return "Failed to save calendar event: \(message)"
        }
    }
}

// MARK: - Busy Slot

struct BusySlot {
    let startDate: Date
    let endDate: Date
    let title: String
    let calendarId: String
    let isAllDay: Bool

    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
}
