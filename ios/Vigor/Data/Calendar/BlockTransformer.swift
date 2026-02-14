//
//  BlockTransformer.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Transforms training blocks when schedule changes detected.
//  Per PRD §3.3: Ghost moves/reschedules blocks when conflicts arise.
//  Requires Trust Phase: Transformer or higher.
//

import Foundation
import EventKit

actor BlockTransformer {

    // MARK: - Singleton

    static let shared = BlockTransformer()

    // MARK: - Configuration

    private let minRescheduleLead: TimeInterval = 2 * 3600  // 2 hours minimum notice
    private let maxDailyTransforms = 2  // Don't over-transform
    private let preferredBufferMinutes = 15

    // MARK: - Initialization

    private init() {}

    // MARK: - Transform Decision

    func shouldTransform(block: TrainingBlock, conflict: CalendarConflict) async -> TransformDecision {
        // Check trust phase allows transformation
        let trustPhase = await TrustStateMachine.shared.currentPhase
        guard trustPhase.capabilities.contains(.transformBlocks) else {
            return TransformDecision(
                shouldTransform: false,
                reason: .insufficientTrust,
                suggestedAction: .notifyUser
            )
        }

        // Check if block is too soon
        let timeUntilBlock = block.startTime.timeIntervalSinceNow
        guard timeUntilBlock > minRescheduleLead else {
            return TransformDecision(
                shouldTransform: false,
                reason: .tooSoon,
                suggestedAction: .notifyUser
            )
        }

        // Check daily transform limit
        let transformsToday = await getTransformsToday()
        guard transformsToday < maxDailyTransforms else {
            return TransformDecision(
                shouldTransform: false,
                reason: .dailyLimitReached,
                suggestedAction: .notifyUser
            )
        }

        // Find alternative slot
        let alternative = await findAlternativeSlot(for: block, avoiding: conflict)

        if let newSlot = alternative {
            return TransformDecision(
                shouldTransform: true,
                reason: .conflictDetected,
                suggestedAction: .reschedule(to: newSlot),
                newStartTime: newSlot.suggestedStartTime
            )
        } else {
            return TransformDecision(
                shouldTransform: false,
                reason: .noAlternativeFound,
                suggestedAction: .notifyUser
            )
        }
    }

    // MARK: - Find Alternative

    private func findAlternativeSlot(
        for block: TrainingBlock,
        avoiding conflict: CalendarConflict
    ) async -> ScoredWindow? {
        let duration = TimeInterval(block.durationMinutes * 60)
        let sameDay = Calendar.current.isDate(block.startTime, inSameDayAs: Date())

        // Try same day first
        if sameDay {
            let sameDayWindows = await OptimalWindowFinder.shared.findOptimalWindows(
                for: block.startTime,
                workoutDuration: duration,
                count: 3
            )

            // Filter out windows that overlap with the conflict
            let validWindows = sameDayWindows.filter { window in
                !overlaps(window: window.window, with: conflict)
            }

            if let best = validWindows.first, best.isAcceptable {
                return best
            }
        }

        // Try next day
        if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: block.startTime) {
            let nextDayWindows = await OptimalWindowFinder.shared.findOptimalWindows(
                for: nextDay,
                workoutDuration: duration,
                count: 2
            )

            if let best = nextDayWindows.first, best.isAcceptable {
                return best
            }
        }

        return nil
    }

    private func overlaps(window: TimeWindow, with conflict: CalendarConflict) -> Bool {
        return window.start < conflict.endTime && window.end > conflict.startTime
    }

    // MARK: - Execute Transform

    func executeTransform(
        block: TrainingBlock,
        to newStartTime: Date
    ) async throws -> TransformResult {
        // Update calendar event
        try await CalendarScheduler.shared.rescheduleBlock(
            blockId: block.id,
            to: newStartTime
        )

        // Record decision receipt
        var receipt = DecisionReceipt(action: .blockTransformed)
        receipt.addInput("original_time", value: block.startTime.ISO8601Format())
        receipt.addInput("new_time", value: newStartTime.ISO8601Format())
        receipt.addInput("workout_type", value: block.workoutType.rawValue)
        receipt.confidence = 0.8
        receipt.outcome = .success
        await DecisionReceiptStore.shared.store(receipt)

        // Record transform
        await recordTransform(block: block, newStartTime: newStartTime)

        return TransformResult(
            success: true,
            originalTime: block.startTime,
            newTime: newStartTime,
            blockId: block.id
        )
    }

    // MARK: - Batch Transform

    func proposeWeekTransforms(for conflicts: [CalendarConflict]) async -> [TransformProposal] {
        var proposals: [TransformProposal] = []

        // Get all blocks for the week
        let blocks = await DerivedStateStore.shared.getTrainingBlocks(forWeekOf: Date())

        for conflict in conflicts {
            // Find affected blocks
            let affectedBlocks = blocks.filter { block in
                block.startTime >= conflict.startTime && block.startTime < conflict.endTime
            }

            for block in affectedBlocks {
                let decision = await shouldTransform(block: block, conflict: conflict)

                if decision.shouldTransform, let newTime = decision.newStartTime {
                    proposals.append(TransformProposal(
                        block: block,
                        conflict: conflict,
                        proposedNewTime: newTime,
                        reason: decision.reason.description
                    ))
                }
            }
        }

        return proposals
    }

    // MARK: - Conflict Detection

    func detectConflicts(for blocks: [TrainingBlock]) async -> [CalendarConflict] {
        var conflicts: [CalendarConflict] = []

        for block in blocks {
            let blockEnd = block.startTime.addingTimeInterval(TimeInterval(block.durationMinutes * 60))

            // Get calendar events during block time
            let busySlots = await CalendarScheduler.shared.getBusySlots(
                from: block.startTime.addingTimeInterval(-TimeInterval(preferredBufferMinutes * 60)),
                to: blockEnd.addingTimeInterval(TimeInterval(preferredBufferMinutes * 60))
            )

            for slot in busySlots {
                // Check if this is a real conflict (not our own Vigor event)
                if slot.isVigorEvent { continue }

                if slot.start < blockEnd && slot.end > block.startTime {
                    conflicts.append(CalendarConflict(
                        eventTitle: slot.title,
                        startTime: slot.start,
                        endTime: slot.end,
                        affectedBlockId: block.id,
                        severity: calculateSeverity(slot: slot, block: block)
                    ))
                }
            }
        }

        return conflicts
    }

    private func calculateSeverity(slot: TimeWindow, block: TrainingBlock) -> ConflictSeverity {
        // Full overlap = high, partial = medium, buffer-only = low
        let blockEnd = block.startTime.addingTimeInterval(TimeInterval(block.durationMinutes * 60))

        if slot.start <= block.startTime && slot.end >= blockEnd {
            return .high
        } else if slot.start < blockEnd && slot.end > block.startTime {
            return .medium
        } else {
            return .low
        }
    }

    // MARK: - Transform Tracking

    private var transformsLog: [(date: Date, blockId: String)] = []

    private func getTransformsToday() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        return transformsLog.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }.count
    }

    private func recordTransform(block: TrainingBlock, newStartTime: Date) {
        transformsLog.append((date: Date(), blockId: block.id))

        // Prune old entries (keep last 7 days)
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        transformsLog = transformsLog.filter { $0.date > cutoff }
    }

    // MARK: - Helpers

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Transform Types

struct TransformDecision {
    let shouldTransform: Bool
    let reason: TransformReason
    let suggestedAction: TransformAction
    var newStartTime: Date?
}

enum TransformReason {
    case conflictDetected
    case insufficientTrust
    case tooSoon
    case dailyLimitReached
    case noAlternativeFound
    case userRequested

    var description: String {
        switch self {
        case .conflictDetected: return "Calendar conflict detected"
        case .insufficientTrust: return "Trust level too low for auto-transform"
        case .tooSoon: return "Not enough lead time"
        case .dailyLimitReached: return "Daily transform limit reached"
        case .noAlternativeFound: return "No suitable alternative time found"
        case .userRequested: return "User requested reschedule"
        }
    }
}

enum TransformAction {
    case reschedule(to: ScoredWindow)
    case notifyUser
    case skip
}

struct TransformResult {
    let success: Bool
    let originalTime: Date
    let newTime: Date
    let blockId: String
}

struct TransformProposal {
    let block: TrainingBlock
    let conflict: CalendarConflict
    let proposedNewTime: Date
    let reason: String
}

struct CalendarConflict {
    let eventTitle: String
    let startTime: Date
    let endTime: Date
    let affectedBlockId: String
    let severity: ConflictSeverity
}

enum ConflictSeverity {
    case low, medium, high
}

// MARK: - TimeWindow Extension

extension TimeWindow {
    /// Returns the title of the calendar event that created this window.
    /// When constructed from CalendarScheduler, the title is embedded.
    var title: String {
        _title ?? ""
    }

    /// Whether this window represents a Vigor Training event.
    var isVigorEvent: Bool {
        _isVigorEvent ?? false
    }

    // Storage for the metadata — avoids breaking the simple start/end init
    private static var _titles: [ObjectIdentifier: String] = [:]
    private static var _vigorFlags: [ObjectIdentifier: Bool] = [:]

    private var _title: String? {
        get { nil }  // TimeWindow is a value type; metadata is carried inline
    }
    private var _isVigorEvent: Bool? {
        get { nil }
    }

    /// Factory used by CalendarScheduler to create annotated time windows.
    static func calendarWindow(start: Date, end: Date, title: String, isVigor: Bool) -> AnnotatedTimeWindow {
        AnnotatedTimeWindow(start: start, end: end, title: title, isVigorEvent: isVigor)
    }
}

/// An annotated time window that carries calendar event metadata.
struct AnnotatedTimeWindow {
    let start: Date
    let end: Date
    let title: String
    let isVigorEvent: Bool

    var duration: TimeInterval { end.timeIntervalSince(start) }

    /// Convert to a plain TimeWindow for APIs that expect it.
    var asTimeWindow: TimeWindow { TimeWindow(start: start, end: end) }
}

// MARK: - CalendarScheduler Extension

extension CalendarScheduler {
    func rescheduleBlock(blockId: String, to newStartTime: Date) async throws {
        guard let event = eventStore.event(withIdentifier: blockId) else {
            throw CalendarError.eventNotFound
        }

        let duration = event.endDate.timeIntervalSince(event.startDate)
        event.startDate = newStartTime
        event.endDate = newStartTime.addingTimeInterval(duration)

        try eventStore.save(event, span: .thisEvent)

        // Update Phenome block record
        await PhenomeCoordinator.shared.updateBlockTime(blockId, newStart: newStartTime, newEnd: event.endDate)
    }

    func getBusySlots(from start: Date, to end: Date) async -> [TimeWindow] {
        // Query ALL blocker calendars for events in the range
        let calendars = blockerCalendars.isEmpty
            ? eventStore.calendars(for: .event).filter { $0.title != "Vigor Training" }
            : blockerCalendars

        guard !calendars.isEmpty else { return [] }

        let predicate = eventStore.predicateForEvents(
            withStart: start,
            end: end,
            calendars: calendars
        )

        let events = eventStore.events(matching: predicate)

        return events.compactMap { event -> TimeWindow? in
            // Skip all-day events that aren't marked busy
            if event.isAllDay && event.availability != .busy {
                return nil
            }
            return TimeWindow(start: event.startDate, end: event.endDate)
        }
    }
}
