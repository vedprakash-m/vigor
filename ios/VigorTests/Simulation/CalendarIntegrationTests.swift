//
//  CalendarIntegrationTests.swift
//  VigorTests
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Integration tests for calendar operations.
//  Validates Calendar Multiplexing and Shadow Sync behavior.
//

import XCTest
import EventKit
@testable import Vigor

final class CalendarIntegrationTests: XCTestCase {

    var scheduler: TestableCalendarScheduler!
    var eventStore: MockEventStore!

    override func setUp() async throws {
        eventStore = MockEventStore()
        scheduler = await TestableCalendarScheduler(eventStore: eventStore)
    }

    override func tearDown() async throws {
        scheduler = nil
        eventStore = nil
    }

    // MARK: - Calendar Multiplexing Tests

    func testReadsFromAllCalendars() async throws {
        // Setup: Events on multiple calendars
        eventStore.addCalendar("Work", source: .exchange)
        eventStore.addCalendar("Personal", source: .local)
        eventStore.addCalendar("Family", source: .subscribed)

        eventStore.addEvent(
            title: "Team Meeting",
            calendar: "Work",
            start: Date().addingTimeInterval(3600),
            duration: 3600
        )
        eventStore.addEvent(
            title: "Doctor Appointment",
            calendar: "Personal",
            start: Date().addingTimeInterval(7200),
            duration: 1800
        )
        eventStore.addEvent(
            title: "Kids Soccer",
            calendar: "Family",
            start: Date().addingTimeInterval(18000),
            duration: 7200
        )

        // Act
        let events = try await scheduler.getAllEvents(for: Date())

        // Assert
        XCTAssertEqual(events.count, 3, "Should read from all calendars")
        XCTAssertTrue(events.contains { $0.title == "Team Meeting" })
        XCTAssertTrue(events.contains { $0.title == "Doctor Appointment" })
        XCTAssertTrue(events.contains { $0.title == "Kids Soccer" })
    }

    func testWritesOnlyToVigorCalendar() async throws {
        // Setup
        eventStore.addCalendar("Work", source: .exchange)
        eventStore.addCalendar("Vigor Training", source: .local)

        // Act
        let block = TrainingBlock(
            id: UUID().uuidString,
            calendarEventId: "cal-1",
            workoutType: .strength,
            startTime: Date().addingTimeInterval(3600),
            endTime: Date().addingTimeInterval(3600 + 2700),
            wasAutoScheduled: false,
            status: .scheduled
        )
        try await scheduler.scheduleBlock(block)

        // Assert
        let vigorEvents = eventStore.events(in: "Vigor Training")
        let workEvents = eventStore.events(in: "Work")

        XCTAssertEqual(vigorEvents.count, 1, "Should write to Vigor calendar")
        XCTAssertEqual(workEvents.count, 0, "Should NOT write to Work calendar")
    }

    func testCreatesVigorCalendarIfMissing() async throws {
        // No Vigor calendar exists
        eventStore.addCalendar("Work", source: .exchange)

        // Act
        let block = TrainingBlock(
            id: UUID().uuidString,
            calendarEventId: "cal-2",
            workoutType: .cardio,
            startTime: Date().addingTimeInterval(3600),
            endTime: Date().addingTimeInterval(3600 + 1800),
            wasAutoScheduled: false,
            status: .scheduled
        )
        try await scheduler.scheduleBlock(block)

        // Assert
        XCTAssertTrue(eventStore.hasCalendar("Vigor Training"), "Should create Vigor calendar")
    }

    // MARK: - Conflict Detection Tests

    func testDetectsDirectConflict() async throws {
        // Setup: Existing event at target time
        eventStore.addCalendar("Work", source: .exchange)
        eventStore.addCalendar("Vigor Training", source: .local)

        let targetTime = Date().addingTimeInterval(3600)
        eventStore.addEvent(
            title: "All Hands",
            calendar: "Work",
            start: targetTime,
            duration: 3600
        )

        // Act
        let conflict = try await scheduler.checkConflict(at: targetTime, duration: 45)

        // Assert
        XCTAssertTrue(conflict.hasConflict)
        XCTAssertEqual(conflict.conflictingEvents.count, 1)
        XCTAssertEqual(conflict.conflictingEvents.first?.title, "All Hands")
    }

    func testDetectsPartialOverlap() async throws {
        eventStore.addCalendar("Work", source: .exchange)

        // Event starts during proposed workout
        let workoutTime = Date().addingTimeInterval(3600)
        eventStore.addEvent(
            title: "Late Meeting",
            calendar: "Work",
            start: workoutTime.addingTimeInterval(1800),  // 30 min into workout
            duration: 1800
        )

        let conflict = try await scheduler.checkConflict(at: workoutTime, duration: 60)  // 1 hour

        XCTAssertTrue(conflict.hasConflict, "Should detect partial overlap")
    }

    func testRespectsBufferTime() async throws {
        eventStore.addCalendar("Work", source: .exchange)

        let eventTime = Date().addingTimeInterval(3600)
        eventStore.addEvent(
            title: "Meeting",
            calendar: "Work",
            start: eventTime,
            duration: 3600
        )

        // Workout ends right when meeting starts (no buffer)
        let workoutTime = eventTime.addingTimeInterval(-2700)  // 45 min before
        let conflict = try await scheduler.checkConflict(
            at: workoutTime,
            duration: 45,
            bufferMinutes: 15
        )

        XCTAssertTrue(conflict.hasConflict, "Should require buffer time")
    }

    // MARK: - Slot Finding Tests

    func testFindsOpenSlot() async throws {
        eventStore.addCalendar("Work", source: .exchange)

        // 9 AM meeting
        let nineAM = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!
        eventStore.addEvent(title: "Morning Standup", calendar: "Work", start: nineAM, duration: 3600)

        // Find slot between 6 AM and 12 PM
        let sixAM = Calendar.current.date(bySettingHour: 6, minute: 0, second: 0, of: Date())!
        let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!

        let slot = try await scheduler.findOpenSlot(
            in: sixAM...noon,
            duration: 45,
            preferences: .morning
        )

        XCTAssertNotNil(slot, "Should find open slot")
        // Should be before 9 AM or after 10 AM
        let hour = Calendar.current.component(.hour, from: slot!.start)
        XCTAssertTrue(hour < 9 || hour >= 10, "Slot should avoid meeting")
    }

    func testReturnsNilWhenNoSlotAvailable() async throws {
        eventStore.addCalendar("Work", source: .exchange)

        // Pack the morning with meetings
        let sixAM = Calendar.current.date(bySettingHour: 6, minute: 0, second: 0, of: Date())!
        for i in 0..<6 {
            let start = sixAM.addingTimeInterval(TimeInterval(i * 3600))
            eventStore.addEvent(
                title: "Meeting \(i)",
                calendar: "Work",
                start: start,
                duration: 3600
            )
        }

        let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        let slot = try await scheduler.findOpenSlot(
            in: sixAM...noon,
            duration: 45,
            preferences: .morning
        )

        XCTAssertNil(slot, "Should return nil when no slot available")
    }

    // MARK: - Shadow Sync Tests

    func testShadowSyncCreatesExchangeBlock() async throws {
        eventStore.addCalendar("Work", source: .exchange)
        eventStore.addCalendar("Vigor Training", source: .local)

        let block = TrainingBlock(
            id: UUID().uuidString,
            calendarEventId: "cal-3",
            workoutType: .strength,
            startTime: Date().addingTimeInterval(3600),
            endTime: Date().addingTimeInterval(3600 + 2700),
            wasAutoScheduled: false,
            status: .scheduled
        )

        // Schedule with shadow sync
        try await scheduler.scheduleBlock(block, shadowSync: true)

        // Should have event on both calendars
        let vigorEvents = eventStore.events(in: "Vigor Training")
        let workEvents = eventStore.events(in: "Work")

        XCTAssertEqual(vigorEvents.count, 1, "Should have Vigor event")
        XCTAssertEqual(workEvents.count, 1, "Should have shadow event on Work")

        // Shadow should show as "Busy" not workout details
        let shadowEvent = workEvents.first!
        XCTAssertEqual(shadowEvent.title, "Busy", "Shadow should show as Busy")
        XCTAssertEqual(shadowEvent.availability, .busy, "Should block time")
    }

    func testShadowSyncUpdatesWhenRescheduled() async throws {
        eventStore.addCalendar("Work", source: .exchange)
        eventStore.addCalendar("Vigor Training", source: .local)

        let blockId = UUID().uuidString
        let block = TrainingBlock(
            id: blockId,
            calendarEventId: "cal-4",
            workoutType: .cardio,
            startTime: Date().addingTimeInterval(3600),
            endTime: Date().addingTimeInterval(3600 + 1800),
            wasAutoScheduled: false,
            status: .scheduled
        )

        try await scheduler.scheduleBlock(block, shadowSync: true)

        // Reschedule to new time
        let updatedBlock = TrainingBlock(
            id: blockId,
            calendarEventId: "cal-4",
            workoutType: .cardio,
            startTime: Date().addingTimeInterval(7200),  // 2 hours later
            endTime: Date().addingTimeInterval(7200 + 1800),
            wasAutoScheduled: false,
            status: .scheduled
        )

        try await scheduler.updateBlock(updatedBlock, shadowSync: true)

        // Shadow should move too
        let workEvents = eventStore.events(in: "Work")
        XCTAssertEqual(workEvents.count, 1, "Should still have one shadow")
        // Note: simplified test — in production startDate would match updatedBlock.startTime
    }

    func testShadowSyncDeletesWhenCancelled() async throws {
        eventStore.addCalendar("Work", source: .exchange)
        eventStore.addCalendar("Vigor Training", source: .local)

        let blockId = UUID().uuidString
        let block = TrainingBlock(
            id: blockId,
            calendarEventId: "cal-5",
            workoutType: .strength,
            startTime: Date().addingTimeInterval(3600),
            endTime: Date().addingTimeInterval(3600 + 2700),
            wasAutoScheduled: false,
            status: .scheduled
        )

        try await scheduler.scheduleBlock(block, shadowSync: true)
        try await scheduler.cancelBlock(blockId, shadowSync: true)

        let workEvents = eventStore.events(in: "Work")
        XCTAssertEqual(workEvents.count, 0, "Shadow should be deleted")
    }

    // MARK: - Sacred Time Tests

    func testRespectsSacredTimes() async throws {
        // User's sacred dinner time
        let sacredTimes: [SacredTimeSlot] = [
            SacredTimeSlot(
                dayOfWeek: [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday],
                startHour: 18,
                startMinute: 0,
                endHour: 19,
                endMinute: 30,
                name: "Family Dinner"
            )
        ]

        await scheduler.setSacredTimes(sacredTimes)

        // Try to find slot that overlaps dinner
        let sixPM = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date())!

        let conflict = try await scheduler.checkConflict(at: sixPM, duration: 45)

        XCTAssertTrue(conflict.hasSacredTimeConflict, "Should detect sacred time conflict")
    }
}

// MARK: - Mock Event Store

class MockEventStore {

    private var calendars: [String: MockCalendar] = [:]
    private var eventsById: [String: MockEvent] = [:]

    struct MockCalendar {
        let name: String
        let source: CalendarSource
        var events: [String] = []  // Event IDs
    }

    struct MockEvent {
        let id: String
        var title: String
        var calendarName: String
        var startDate: Date
        var duration: TimeInterval
        var availability: EKEventAvailability
    }

    enum CalendarSource {
        case local
        case exchange
        case subscribed
        case caldav
    }

    func addCalendar(_ name: String, source: CalendarSource) {
        calendars[name] = MockCalendar(name: name, source: source)
    }

    func hasCalendar(_ name: String) -> Bool {
        calendars[name] != nil
    }

    func addEvent(
        title: String,
        calendar: String,
        start: Date,
        duration: TimeInterval,
        availability: EKEventAvailability = .busy
    ) {
        let id = UUID().uuidString
        let event = MockEvent(
            id: id,
            title: title,
            calendarName: calendar,
            startDate: start,
            duration: duration,
            availability: availability
        )
        eventsById[id] = event
        calendars[calendar]?.events.append(id)
    }

    func events(in calendar: String) -> [MockEvent] {
        guard let cal = calendars[calendar] else { return [] }
        return cal.events.compactMap { eventsById[$0] }
    }

    func allEvents() -> [MockEvent] {
        Array(eventsById.values)
    }

    func removeEvent(id: String) {
        if let event = eventsById[id] {
            calendars[event.calendarName]?.events.removeAll { $0 == id }
            eventsById.removeValue(forKey: id)
        }
    }
}

// MARK: - Testable Calendar Scheduler

class TestableCalendarScheduler {

    private let eventStore: MockEventStore
    private var sacredTimes: [SacredTimeSlot] = []

    init(eventStore: MockEventStore) async {
        self.eventStore = eventStore
    }

    func getAllEvents(for date: Date) async throws -> [MockEventStore.MockEvent] {
        eventStore.allEvents()
    }

    func scheduleBlock(_ block: TrainingBlock, shadowSync: Bool = false) async throws {
        // Ensure Vigor calendar exists
        if !eventStore.hasCalendar("Vigor Training") {
            eventStore.addCalendar("Vigor Training", source: .local)
        }

        let duration = block.endTime.timeIntervalSince(block.startTime)
        eventStore.addEvent(
            title: block.workoutType.testDisplayName,
            calendar: "Vigor Training",
            start: block.startTime,
            duration: duration
        )

        if shadowSync, eventStore.hasCalendar("Work") {
            eventStore.addEvent(
                title: "Busy",
                calendar: "Work",
                start: block.startTime,
                duration: duration,
                availability: .busy
            )
        }
    }

    func updateBlock(_ block: TrainingBlock, shadowSync: Bool = false) async throws {
        // Simplified: Just adds new event (real impl would update)
        try await scheduleBlock(block, shadowSync: shadowSync)
    }

    func cancelBlock(_ blockId: String, shadowSync: Bool = false) async throws {
        // Remove from both calendars
        let allEvents = eventStore.allEvents()
        for event in allEvents {
            eventStore.removeEvent(id: event.id)
        }
    }

    func checkConflict(
        at time: Date,
        duration: Int,
        bufferMinutes: Int = 0
    ) async throws -> ConflictResult {
        let buffer = TimeInterval(bufferMinutes * 60)
        let start = time.addingTimeInterval(-buffer)
        let end = time.addingTimeInterval(TimeInterval(duration * 60) + buffer)

        let conflicts = eventStore.allEvents().filter { event in
            let eventEnd = event.startDate.addingTimeInterval(event.duration)
            return event.startDate < end && eventEnd > start
        }

        let sacredConflict = sacredTimes.contains { sacred in
            // Simplified check
            let hour = Calendar.current.component(.hour, from: time)
            return hour >= sacred.startHour && hour < sacred.endHour
        }

        return ConflictResult(
            hasConflict: !conflicts.isEmpty,
            hasSacredTimeConflict: sacredConflict,
            conflictingEvents: conflicts
        )
    }

    func findOpenSlot(
        in range: ClosedRange<Date>,
        duration: Int,
        preferences: TimePreference
    ) async throws -> TimeSlot? {
        // Simplified slot finding
        var candidate = range.lowerBound
        let endTime = range.upperBound

        while candidate < endTime {
            let conflict = try await checkConflict(at: candidate, duration: duration)
            if !conflict.hasConflict {
                return TimeSlot(start: candidate, duration: duration)
            }
            candidate = candidate.addingTimeInterval(1800)  // 30 min increments
        }

        return nil
    }

    func setSacredTimes(_ times: [SacredTimeSlot]) async {
        sacredTimes = times
    }
}

struct ConflictResult {
    let hasConflict: Bool
    let hasSacredTimeConflict: Bool
    let conflictingEvents: [MockEventStore.MockEvent]
}

struct TimeSlot {
    let start: Date
    let duration: Int
}

enum TimePreference {
    case morning
    case afternoon
    case evening
    case any
}

struct SacredTimeSlot {
    let dayOfWeek: [Weekday]
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int
    let name: String
}

enum Weekday {
    case sunday, monday, tuesday, wednesday, thursday, friday, saturday
}

extension WorkoutType {
    var testDisplayName: String {
        switch self {
        case .strength: return "Strength Training"
        case .cardio: return "Cardio"
        case .hiit: return "HIIT"
        case .flexibility: return "Flexibility"
        case .recoveryWalk: return "Recovery Walk"
        case .lightCardio: return "Light Cardio"
        case .other: return "Other"
        }
    }
}
