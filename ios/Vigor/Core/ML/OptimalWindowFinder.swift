//
//  OptimalWindowFinder.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Find optimal workout windows based on calendar, patterns, and preferences.
//  Per PRD §3.1: Ghost identifies windows that maximize completion probability.
//

import Foundation
import EventKit

actor OptimalWindowFinder {

    // MARK: - Singleton

    static let shared = OptimalWindowFinder()

    // MARK: - Configuration

    private let minWindowDuration: TimeInterval = 30 * 60  // 30 minutes
    private let maxWindowsPerDay = 5
    private let bufferBeforeEvent: TimeInterval = 15 * 60  // 15 min buffer
    private let bufferAfterEvent: TimeInterval = 15 * 60

    // MARK: - Initialization

    private init() {}

    // MARK: - Find Windows

    func findOptimalWindows(
        for date: Date,
        workoutDuration: TimeInterval,
        count: Int = 3
    ) async -> [ScoredWindow] {
        // Get all available windows for the day
        let availableWindows = await getAvailableWindows(for: date)

        // Filter windows that can fit the workout
        let fittingWindows = availableWindows.filter { window in
            window.duration >= workoutDuration + bufferBeforeEvent + bufferAfterEvent
        }

        // Score each window
        var scoredWindows: [ScoredWindow] = []
        for window in fittingWindows {
            let score = await scoreWindow(window, workoutDuration: workoutDuration)
            scoredWindows.append(score)
        }

        // Sort by score and return top N
        return scoredWindows
            .sorted { $0.totalScore > $1.totalScore }
            .prefix(count)
            .map { $0 }
    }

    func findOptimalWindowsForWeek(
        workoutsPerWeek: Int,
        preferredDuration: TimeInterval
    ) async -> [Date: [ScoredWindow]] {
        let calendar = Calendar.current
        let startOfWeek = calendar.startOfWeek(for: Date())

        var weekWindows: [Date: [ScoredWindow]] = [:]

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) else { continue }
            let windows = await findOptimalWindows(
                for: date,
                workoutDuration: preferredDuration,
                count: 3
            )
            weekWindows[date] = windows
        }

        return weekWindows
    }

    // MARK: - Get Available Windows

    private func getAvailableWindows(for date: Date) async -> [TimeWindow] {
        let calendar = Calendar.current

        // Define day boundaries (e.g., 6 AM to 10 PM)
        var dayStart = calendar.startOfDay(for: date)
        dayStart = calendar.date(byAdding: .hour, value: 6, to: dayStart) ?? dayStart

        var dayEnd = calendar.startOfDay(for: date)
        dayEnd = calendar.date(byAdding: .hour, value: 22, to: dayEnd) ?? dayEnd

        // Get all calendar events
        let busySlots = await CalendarScheduler.shared.getBusySlots(for: date)

        // Get sacred times
        let sacredTimes = await BehavioralMemoryStore.shared.getSacredTimes(for: date)

        // Combine and sort all blocked times
        var blockedSlots: [TimeWindow] = busySlots
        blockedSlots.append(contentsOf: sacredTimes.map { TimeWindow(start: $0.startTime, end: $0.endTime) })
        blockedSlots.sort { $0.start < $1.start }

        // Find gaps between blocked slots
        var availableWindows: [TimeWindow] = []
        var currentStart = dayStart

        for slot in blockedSlots {
            // Add buffer before the event
            let bufferedStart = slot.start.addingTimeInterval(-bufferBeforeEvent)

            if bufferedStart > currentStart {
                let window = TimeWindow(start: currentStart, end: bufferedStart)
                if window.duration >= minWindowDuration {
                    availableWindows.append(window)
                }
            }

            // Move current start to after this event (with buffer)
            let bufferedEnd = slot.end.addingTimeInterval(bufferAfterEvent)
            if bufferedEnd > currentStart {
                currentStart = bufferedEnd
            }
        }

        // Add final window to end of day
        if dayEnd > currentStart {
            let window = TimeWindow(start: currentStart, end: dayEnd)
            if window.duration >= minWindowDuration {
                availableWindows.append(window)
            }
        }

        return availableWindows
    }

    // MARK: - Score Window

    private func scoreWindow(
        _ window: TimeWindow,
        workoutDuration: TimeInterval
    ) async -> ScoredWindow {
        var scores: [WindowScoreFactor] = []

        // Factor 1: Historical completion rate for this time slot
        let historicalScore = await scoreHistoricalSuccess(for: window)
        scores.append(historicalScore)

        // Factor 2: User preference alignment
        let preferenceScore = await scorePreferenceAlignment(for: window)
        scores.append(preferenceScore)

        // Factor 3: Buffer quality (time before/after commitments)
        let bufferScore = scoreBufferQuality(window: window, workoutDuration: workoutDuration)
        scores.append(bufferScore)

        // Factor 4: Time of day energy levels
        let energyScore = scoreTimeOfDayEnergy(for: window)
        scores.append(energyScore)

        // Factor 5: Flexibility (larger windows score higher)
        let flexibilityScore = scoreFlexibility(window: window, workoutDuration: workoutDuration)
        scores.append(flexibilityScore)

        // Calculate weighted total
        let totalScore = scores.reduce(0.0) { $0 + ($1.score * $1.weight) }

        return ScoredWindow(
            window: window,
            totalScore: totalScore,
            factors: scores,
            suggestedStartTime: calculateOptimalStartTime(in: window, duration: workoutDuration)
        )
    }

    private func scoreHistoricalSuccess(for window: TimeWindow) async -> WindowScoreFactor {
        let hour = Calendar.current.component(.hour, from: window.start)
        let dayOfWeek = Calendar.current.component(.weekday, from: window.start)

        let timeSlotKey = TimeSlotKey(dayOfWeek: dayOfWeek, hourOfDay: hour)
        let stats = await BehavioralMemoryStore.shared.getTimeSlotStats(for: timeSlotKey)

        let completionRate = stats?.completionRate ?? 0.5

        return WindowScoreFactor(
            name: "Historical Success",
            score: completionRate,
            weight: 0.30,
            description: completionRate > 0.7 ? "You often succeed at this time" :
                        completionRate < 0.3 ? "Lower historical completion" : "Mixed results"
        )
    }

    private func scorePreferenceAlignment(for window: TimeWindow) async -> WindowScoreFactor {
        let preferences = await BehavioralMemoryStore.shared.getWorkoutTimePreferences()
        let hour = Calendar.current.component(.hour, from: window.start)

        var score = 0.5
        var description = "Neutral time preference"

        if let prefs = preferences {
            if prefs.preferredMorning && hour >= 5 && hour <= 9 {
                score = 0.9
                description = "Matches your morning preference"
            } else if prefs.preferredEvening && hour >= 17 && hour <= 21 {
                score = 0.9
                description = "Matches your evening preference"
            } else if prefs.preferredLunch && hour >= 11 && hour <= 14 {
                score = 0.9
                description = "Matches your midday preference"
            }
        }

        return WindowScoreFactor(
            name: "Preference Match",
            score: score,
            weight: 0.25,
            description: description
        )
    }

    private func scoreBufferQuality(
        window: TimeWindow,
        workoutDuration: TimeInterval
    ) -> WindowScoreFactor {
        let availableBuffer = window.duration - workoutDuration
        let idealBuffer: TimeInterval = 30 * 60 // 30 minutes of buffer

        let bufferRatio = min(1.0, availableBuffer / idealBuffer)

        return WindowScoreFactor(
            name: "Buffer Quality",
            score: bufferRatio,
            weight: 0.20,
            description: bufferRatio > 0.8 ? "Plenty of buffer time" :
                        bufferRatio < 0.4 ? "Tight schedule" : "Adequate buffer"
        )
    }

    private func scoreTimeOfDayEnergy(for window: TimeWindow) -> WindowScoreFactor {
        let hour = Calendar.current.component(.hour, from: window.start)

        // General energy curve (can be personalized later)
        let energyScores: [Int: Double] = [
            5: 0.5, 6: 0.6, 7: 0.8, 8: 0.9, 9: 0.95,
            10: 0.9, 11: 0.85, 12: 0.7, 13: 0.6, 14: 0.5,
            15: 0.55, 16: 0.7, 17: 0.85, 18: 0.9, 19: 0.85,
            20: 0.7, 21: 0.5, 22: 0.3
        ]

        let score = energyScores[hour] ?? 0.5

        return WindowScoreFactor(
            name: "Energy Level",
            score: score,
            weight: 0.15,
            description: score > 0.8 ? "Peak energy time" :
                        score < 0.5 ? "Lower energy expected" : "Moderate energy"
        )
    }

    private func scoreFlexibility(
        window: TimeWindow,
        workoutDuration: TimeInterval
    ) -> WindowScoreFactor {
        let excessTime = window.duration - workoutDuration
        let flexibilityMinutes = excessTime / 60

        // More excess time = more flexibility = higher score
        let score: Double
        switch flexibilityMinutes {
        case 60...: score = 1.0
        case 45..<60: score = 0.9
        case 30..<45: score = 0.7
        case 15..<30: score = 0.5
        default: score = 0.3
        }

        return WindowScoreFactor(
            name: "Flexibility",
            score: score,
            weight: 0.10,
            description: flexibilityMinutes > 30 ? "Flexible timing" : "Fixed timing needed"
        )
    }

    private func calculateOptimalStartTime(
        in window: TimeWindow,
        duration: TimeInterval
    ) -> Date {
        // Start with some buffer from the window start
        let bufferFromStart = min(15 * 60, (window.duration - duration) / 2)
        return window.start.addingTimeInterval(bufferFromStart)
    }
}

// MARK: - Scored Window

struct ScoredWindow {
    let window: TimeWindow
    let totalScore: Double
    let factors: [WindowScoreFactor]
    let suggestedStartTime: Date

    var isHighQuality: Bool { totalScore >= 0.7 }
    var isAcceptable: Bool { totalScore >= 0.4 }
}

struct WindowScoreFactor {
    let name: String
    let score: Double
    let weight: Double
    let description: String
}

// MARK: - Time Window Extension

extension TimeWindow {
    var duration: TimeInterval {
        end.timeIntervalSince(start)
    }
}

// MARK: - Time Slot Stats Extension

extension TimeSlotStats {
    var completionRate: Double {
        guard totalAttempts > 0 else { return 0.5 }
        return Double(completedCount) / Double(totalAttempts)
    }
}

// MARK: - Behavioral Memory Extension

struct WorkoutTimePreferences {
    let preferredMorning: Bool
    let preferredLunch: Bool
    let preferredEvening: Bool
}

extension BehavioralMemoryStore {
    func getSacredTimes(for date: Date) async -> [SacredTimeEntry] {
        []
    }

    func getWorkoutTimePreferences() async -> WorkoutTimePreferences? {
        nil
    }
}

struct SacredTimeEntry {
    let name: String
    let startTime: Date
    let endTime: Date
}
