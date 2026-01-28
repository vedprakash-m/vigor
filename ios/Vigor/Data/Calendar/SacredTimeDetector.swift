//
//  SacredTimeDetector.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Detects and protects user's sacred times from workout scheduling.
//  Per PRD §3.2: "Never schedule workouts during sacred times"
//
//  Sacred times are recurring blocks the user never wants interrupted:
//  - Morning routine (6-8 AM)
//  - Family dinner (6-7 PM)
//  - Kids' bedtime (7:30-9 PM)
//  - Religious observances
//  - Regular meetings/commitments
//

import Foundation
import EventKit

actor SacredTimeDetector {

    // MARK: - Singleton

    static let shared = SacredTimeDetector()

    // MARK: - Configuration

    private let minOccurrencesForPattern = 3
    private let patternWindowWeeks = 8
    private let confidenceThreshold = 0.75

    // MARK: - State

    private var detectedPatterns: [SacredTimePattern] = []
    private var userDeclaredTimes: [DeclaredSacredTime] = []
    private var lastAnalysis: Date?

    // MARK: - Initialization

    private init() {}

    // MARK: - Detection

    func analyzeCalendarForSacredTimes() async {
        // Get calendar events from past N weeks
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .weekOfYear, value: -patternWindowWeeks, to: endDate) else { return }

        let events = await CalendarScheduler.shared.getAllEvents(from: startDate, to: endDate)

        // Group events by day of week and hour
        var eventsByTimeSlot: [TimeSlotKey: [RecurringEventInfo]] = [:]

        for event in events {
            let dayOfWeek = calendar.component(.weekday, from: event.startDate)
            let hour = calendar.component(.hour, from: event.startDate)
            let key = TimeSlotKey(dayOfWeek: dayOfWeek, hourOfDay: hour)

            let info = RecurringEventInfo(
                title: event.title ?? "",
                date: event.startDate,
                duration: event.endDate.timeIntervalSince(event.startDate)
            )

            eventsByTimeSlot[key, default: []].append(info)
        }

        // Identify patterns
        var patterns: [SacredTimePattern] = []

        for (slot, events) in eventsByTimeSlot {
            // Check for recurring events (same title)
            let titleGroups = Dictionary(grouping: events, by: { normalizeTitle($0.title) })

            for (title, occurrences) in titleGroups where occurrences.count >= minOccurrencesForPattern {
                let confidence = Double(occurrences.count) / Double(patternWindowWeeks)

                if confidence >= confidenceThreshold {
                    let avgDuration = occurrences.map(\.duration).reduce(0, +) / Double(occurrences.count)

                    patterns.append(SacredTimePattern(
                        id: UUID(),
                        name: title.isEmpty ? "Recurring Block" : title,
                        dayOfWeek: slot.dayOfWeek,
                        startHour: slot.hourOfDay,
                        durationMinutes: Int(avgDuration / 60),
                        confidence: confidence,
                        detectedFrom: .calendarPattern,
                        occurrenceCount: occurrences.count
                    ))
                }
            }
        }

        detectedPatterns = patterns
        lastAnalysis = Date()
    }

    private func normalizeTitle(_ title: String) -> String {
        // Normalize for comparison
        return title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - User Declaration

    func declareSacredTime(_ time: DeclaredSacredTime) {
        userDeclaredTimes.append(time)
    }

    func removeSacredTime(id: UUID) {
        userDeclaredTimes.removeAll { $0.id == id }
    }

    func getAllSacredTimes() -> [SacredTime] {
        var allTimes: [SacredTime] = []

        // Add detected patterns
        for pattern in detectedPatterns {
            allTimes.append(SacredTime(
                id: pattern.id,
                name: pattern.name,
                dayOfWeek: pattern.dayOfWeek,
                startHour: pattern.startHour,
                startMinute: 0,
                durationMinutes: pattern.durationMinutes,
                source: .detected,
                confidence: pattern.confidence
            ))
        }

        // Add user-declared times (higher priority)
        for declared in userDeclaredTimes {
            allTimes.append(SacredTime(
                id: declared.id,
                name: declared.name,
                dayOfWeek: declared.dayOfWeek,
                startHour: declared.startHour,
                startMinute: declared.startMinute,
                durationMinutes: declared.durationMinutes,
                source: .userDeclared,
                confidence: 1.0
            ))
        }

        return allTimes
    }

    // MARK: - Conflict Checking

    func isSacredTime(_ date: Date, duration: TimeInterval) -> Bool {
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: date)
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)

        let endDate = date.addingTimeInterval(duration)
        let endHour = calendar.component(.hour, from: endDate)
        let endMinute = calendar.component(.minute, from: endDate)

        for sacred in getAllSacredTimes() where sacred.dayOfWeek == dayOfWeek {
            let sacredStart = sacred.startHour * 60 + sacred.startMinute
            let sacredEnd = sacredStart + sacred.durationMinutes

            let proposedStart = hour * 60 + minute
            let proposedEnd = endHour * 60 + endMinute

            // Check overlap
            if proposedStart < sacredEnd && proposedEnd > sacredStart {
                return true
            }
        }

        return false
    }

    func getSacredTimesFor(date: Date) -> [SacredTime] {
        let dayOfWeek = Calendar.current.component(.weekday, from: date)
        return getAllSacredTimes().filter { $0.dayOfWeek == dayOfWeek }
    }

    // MARK: - Suggestions

    func suggestSacredTimes() async -> [SacredTimeSuggestion] {
        // Re-analyze if stale
        if lastAnalysis == nil || Date().timeIntervalSince(lastAnalysis!) > 7 * 24 * 3600 {
            await analyzeCalendarForSacredTimes()
        }

        var suggestions: [SacredTimeSuggestion] = []

        // Find high-confidence patterns not yet declared
        let declaredSlots = Set(userDeclaredTimes.map { TimeSlotKey(dayOfWeek: $0.dayOfWeek, hourOfDay: $0.startHour) })

        for pattern in detectedPatterns where pattern.confidence >= 0.8 {
            let slot = TimeSlotKey(dayOfWeek: pattern.dayOfWeek, hourOfDay: pattern.startHour)

            if !declaredSlots.contains(slot) {
                suggestions.append(SacredTimeSuggestion(
                    pattern: pattern,
                    reason: "This time slot has \(pattern.name) \(pattern.occurrenceCount) times in the past \(patternWindowWeeks) weeks"
                ))
            }
        }

        return suggestions.sorted { $0.pattern.confidence > $1.pattern.confidence }
    }
}

// MARK: - Types

struct SacredTimePattern {
    let id: UUID
    let name: String
    let dayOfWeek: Int  // 1-7 (Sunday-Saturday)
    let startHour: Int
    let durationMinutes: Int
    let confidence: Double
    let detectedFrom: PatternSource
    let occurrenceCount: Int
}

enum PatternSource {
    case calendarPattern
    case healthKitPattern
    case behavioralPattern
}

struct DeclaredSacredTime: Codable, Identifiable {
    let id: UUID
    let name: String
    let dayOfWeek: Int
    let startHour: Int
    let startMinute: Int
    let durationMinutes: Int
    let reason: String?

    init(
        id: UUID = UUID(),
        name: String,
        dayOfWeek: Int,
        startHour: Int,
        startMinute: Int = 0,
        durationMinutes: Int,
        reason: String? = nil
    ) {
        self.id = id
        self.name = name
        self.dayOfWeek = dayOfWeek
        self.startHour = startHour
        self.startMinute = startMinute
        self.durationMinutes = durationMinutes
        self.reason = reason
    }
}

struct SacredTime: Identifiable {
    let id: UUID
    let name: String
    let dayOfWeek: Int
    let startHour: Int
    let startMinute: Int
    let durationMinutes: Int
    let source: SacredTimeSource
    let confidence: Double

    var displayTime: String {
        let startFormatted = String(format: "%d:%02d", startHour, startMinute)
        let endHour = startHour + durationMinutes / 60
        let endMinute = startMinute + durationMinutes % 60
        let endFormatted = String(format: "%d:%02d", endHour, endMinute)
        return "\(startFormatted) - \(endFormatted)"
    }

    var dayName: String {
        let formatter = DateFormatter()
        guard dayOfWeek >= 1 && dayOfWeek <= 7 else { return "" }
        return formatter.weekdaySymbols[dayOfWeek - 1]
    }
}

enum SacredTimeSource {
    case detected
    case userDeclared
}

struct SacredTimeSuggestion {
    let pattern: SacredTimePattern
    let reason: String
}

struct RecurringEventInfo {
    let title: String
    let date: Date
    let duration: TimeInterval
}

// MARK: - CalendarScheduler Extension

extension CalendarScheduler {
    func getAllEvents(from start: Date, to end: Date) async -> [EKEvent] {
        guard isAuthorized else { return [] }

        let predicate = eventStore.predicateForEvents(
            withStart: start,
            end: end,
            calendars: nil
        )

        return eventStore.events(matching: predicate)
    }
}
