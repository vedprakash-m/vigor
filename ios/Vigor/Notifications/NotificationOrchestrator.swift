//
//  NotificationOrchestrator.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Notification orchestration - max 1 notification per day, binary actions only.
//  Per PRD §4.3: Never ask questions, binary response only, contextual silence.
//

import Foundation
import UserNotifications

// MARK: - Notification Priority

/// Priority levels for notification queueing.
/// When the daily limit is reached, a higher-priority notification can
/// replace a queued lower-priority one.
enum NotificationPriority: Int, Comparable {
    case low = 0       // badge-only updates (workout confirmations)
    case normal = 1    // informational (value receipts, MDM fallback)
    case high = 2      // trust changes, health mode
    case critical = 3  // actionable (block proposals, transformations, removals)

    static func < (lhs: NotificationPriority, rhs: NotificationPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

actor NotificationOrchestrator {

    // MARK: - Singleton

    static let shared = NotificationOrchestrator()

    // MARK: - State

    private var notificationsSentToday: Int = 0
    private var lastNotificationDate: Date?
    private let maxNotificationsPerDay = 1

    /// Pending notification waiting for the daily slot (replaced if a higher-priority one arrives).
    private var pendingNotification: (content: UNMutableNotificationContent, priority: NotificationPriority)?

    // MARK: - Initialization

    private init() {
        Task {
            await requestAuthorization()
        }
    }

    // MARK: - Authorization

    private func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            if !granted {
                // User declined - Ghost operates in silent mode
            }
        } catch {
            // Authorization failed
        }

        // Register notification categories with actions
        await registerNotificationCategories()
    }

    private func registerNotificationCategories() async {
        let center = UNUserNotificationCenter.current()

        // Block proposal category
        let acceptAction = UNNotificationAction(
            identifier: "ACCEPT",
            title: "Yes",
            options: [.foreground]
        )
        let rejectAction = UNNotificationAction(
            identifier: "REJECT",
            title: "No",
            options: []
        )
        let proposalCategory = UNNotificationCategory(
            identifier: "BLOCK_PROPOSAL",
            actions: [acceptAction, rejectAction],
            intentIdentifiers: [],
            options: []
        )

        // Workout confirmation category
        let correctAction = UNNotificationAction(
            identifier: "CORRECT",
            title: "Correct",
            options: []
        )
        let wrongAction = UNNotificationAction(
            identifier: "WRONG",
            title: "Wrong",
            options: [.foreground]
        )
        let confirmationCategory = UNNotificationCategory(
            identifier: "WORKOUT_CONFIRMATION",
            actions: [correctAction, wrongAction],
            intentIdentifiers: [],
            options: []
        )

        // Transformation notice category
        let okAction = UNNotificationAction(
            identifier: "OK",
            title: "OK",
            options: []
        )
        let revertAction = UNNotificationAction(
            identifier: "REVERT",
            title: "Revert",
            options: [.foreground]
        )
        let transformationCategory = UNNotificationCategory(
            identifier: "BLOCK_TRANSFORMATION",
            actions: [okAction, revertAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([
            proposalCategory,
            confirmationCategory,
            transformationCategory
        ])
    }

    // MARK: - Rate Limiting

    /// Gate: No notifications before onboarding completes.
    /// Per PRD §4.3 — notifications are for actionable Ghost decisions,
    /// not system setup status.
    private var isOnboardingComplete: Bool {
        UserDefaults.standard.bool(forKey: "onboarding_completed")
    }

    private func canSendNotification() -> Bool {
        // Never send notifications before onboarding completes
        guard isOnboardingComplete else { return false }

        guard let lastDate = lastNotificationDate else { return true }

        let calendar = Calendar.current
        if calendar.isDateInToday(lastDate) {
            return notificationsSentToday < maxNotificationsPerDay
        } else {
            // New day - reset counter
            notificationsSentToday = 0
            return true
        }
    }

    private func recordNotificationSent() {
        notificationsSentToday += 1
        lastNotificationDate = Date()
    }

    // MARK: - Universal Send

    /// Universal notification delivery — ALL notification types go through here.
    /// Enforces the 1/day rate limit (PRD §4.3).
    /// If the daily slot is taken, queues the notification; a higher-priority
    /// notification will replace a queued lower-priority one.
    ///
    /// - Parameters:
    ///   - content: The notification content.
    ///   - priority: Determines whether this can bump a pending notification.
    ///   - badgeOnly: If true, only updates badge count (no alert/sound); these
    ///     always go through without consuming the daily slot.
    private func send(
        _ content: UNMutableNotificationContent,
        priority: NotificationPriority,
        badgeOnly: Bool = false
    ) async {
        guard isOnboardingComplete else { return }

        // Badge-only notifications bypass the daily limit entirely
        if badgeOnly {
            content.sound = nil
            // Deliver silently — appears only in Notification Center
            content.interruptionLevel = .passive
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
            try? await UNUserNotificationCenter.current().add(request)
            VigorLogger.notifications.debug("Badge-only notification sent: \(content.title)")
            return
        }

        // Check daily slot
        if canSendNotification() {
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
            do {
                try await UNUserNotificationCenter.current().add(request)
                recordNotificationSent()
                VigorLogger.notifications.info("Notification sent [p\(priority.rawValue)]: \(content.title)")
            } catch {
                VigorLogger.notifications.error("Notification delivery failed: \(error.localizedDescription)")
            }
        } else {
            // Daily limit reached — queue if higher priority than pending
            if let pending = pendingNotification {
                if priority > pending.priority {
                    pendingNotification = (content, priority)
                    VigorLogger.notifications.info("Notification queued (replaced lower priority): \(content.title)")
                } else {
                    VigorLogger.notifications.info("Notification dropped (rate limited): \(content.title)")
                }
                // else: lower or equal priority — drop it
            } else {
                pendingNotification = (content, priority)
                VigorLogger.notifications.info("Notification queued (daily limit reached): \(content.title)")
            }
        }
    }

    // MARK: - Block Proposal

    func sendBlockProposal(workout: GeneratedWorkout, window: TimeWindow) async {
        let content = UNMutableNotificationContent()
        content.title = "Workout Tomorrow"
        content.body = "\(window.start.formatted(date: .omitted, time: .shortened)) \(workout.name)?"
        content.categoryIdentifier = "BLOCK_PROPOSAL"
        content.userInfo = [
            "type": "block_proposal",
            "workout_id": workout.id,
            "window_start": window.start.timeIntervalSince1970,
            "window_end": window.end.timeIntervalSince1970
        ]
        content.sound = .default

        await send(content, priority: .critical)
    }

    // MARK: - Workout Confirmation

    func sendWorkoutConfirmation(_ workout: DetectedWorkout) async {
        // Badge-only — no alert, no sound, doesn't consume daily slot
        let content = UNMutableNotificationContent()
        content.title = "Logged"
        content.body = "\(workout.durationMinutes) min \(workout.type.displayName)"
        content.categoryIdentifier = "WORKOUT_CONFIRMATION"
        content.userInfo = [
            "type": "workout_confirmation",
            "workout_id": workout.id
        ]

        await send(content, priority: .low, badgeOnly: true)
    }

    // MARK: - Block Transformation

    func sendBlockTransformationNotice(
        original: TrainingBlock,
        newType: WorkoutType,
        reason: String
    ) async {
        let content = UNMutableNotificationContent()
        content.title = "Adjusted"
        content.body = "\(original.workoutType.displayName) → \(newType.displayName)"
        content.categoryIdentifier = "BLOCK_TRANSFORMATION"
        content.userInfo = [
            "type": "block_transformation",
            "block_id": original.id,
            "original_type": original.workoutType.rawValue,
            "new_type": newType.rawValue
        ]
        content.sound = .default

        await send(content, priority: .critical)
    }

    // MARK: - Block Removal

    func sendBlockRemovalNotice(_ block: TrainingBlock, reason: String) async {
        let content = UNMutableNotificationContent()
        content.title = "Rest Day"
        content.body = "Today's workout removed for recovery"
        content.sound = nil // Gentle - no sound

        await send(content, priority: .critical)
    }

    // MARK: - Value Receipt

    func sendValueReceipt(_ receipt: ValueReceipt) async {
        let content = UNMutableNotificationContent()
        content.title = "Your Week"
        content.body = "\(receipt.completedWorkouts) workouts, \(receipt.totalMinutes) minutes"
        content.sound = .default
        content.userInfo = [
            "type": "value_receipt",
            "receipt_id": receipt.id.uuidString
        ]

        await send(content, priority: .normal)
    }

    // MARK: - Trust Changes

    func sendTrustAdvancement(from: TrustPhase, to: TrustPhase) async {
        let content = UNMutableNotificationContent()
        content.title = "Trust Level Up"
        content.body = "Now: \(to.displayName)"
        content.sound = .default

        await send(content, priority: .high)
    }

    func sendTrustRetreat(from: TrustPhase, to: TrustPhase) async {
        let content = UNMutableNotificationContent()
        content.title = "Stepping Back"
        content.body = "I'll suggest instead of schedule for now"
        content.sound = nil // Silent - apologetic

        await send(content, priority: .high)
    }

    // MARK: - Health Mode Changes

    func sendHealthModeChange(from: GhostHealthMode, to: GhostHealthMode) async {
        guard to != .healthy else { return } // Only notify about problems

        let content = UNMutableNotificationContent()
        content.title = "Ghost Status"
        content.body = to.description
        content.sound = nil

        await send(content, priority: .high)
    }

    // MARK: - MDM Fallback

    func sendMDMFallbackNotice() async {
        let content = UNMutableNotificationContent()
        content.title = "Calendar Sync"
        content.body = "Corporate calendar sync unavailable. Workouts will only appear in Vigor calendar."
        content.sound = nil

        await send(content, priority: .normal)
    }

    // MARK: - Response Handling

    func handleNotificationResponse(actionIdentifier: String, userInfo: [AnyHashable: Any]) async {
        guard let type = userInfo["type"] as? String else { return }

        switch type {
        case "block_proposal":
            await handleProposalResponse(action: actionIdentifier, userInfo: userInfo)
        case "workout_confirmation":
            await handleConfirmationResponse(action: actionIdentifier, userInfo: userInfo)
        case "block_transformation":
            await handleTransformationResponse(action: actionIdentifier, userInfo: userInfo)
        default:
            break
        }
    }

    private func handleProposalResponse(action: String, userInfo: [AnyHashable: Any]) async {
        guard let workoutId = userInfo["workout_id"] as? String,
              let windowStart = userInfo["window_start"] as? TimeInterval,
              let windowEnd = userInfo["window_end"] as? TimeInterval else { return }

        let window = TimeWindow(
            start: Date(timeIntervalSince1970: windowStart),
            end: Date(timeIntervalSince1970: windowEnd)
        )

        switch action {
        case "ACCEPT":
            // Create the block
            await TrustStateMachine.shared.recordEvent(.proposalAccepted)
            // Block creation would happen here
        case "REJECT":
            await TrustStateMachine.shared.recordEvent(.proposalRejected)
        default:
            break
        }
    }

    private func handleConfirmationResponse(action: String, userInfo: [AnyHashable: Any]) async {
        guard let workoutId = userInfo["workout_id"] as? String else { return }

        switch action {
        case "WRONG":
            // User says workout was logged incorrectly - open app for correction
            break
        default:
            break
        }
    }

    private func handleTransformationResponse(action: String, userInfo: [AnyHashable: Any]) async {
        guard let blockId = userInfo["block_id"] as? String,
              let originalType = userInfo["original_type"] as? String else { return }

        switch action {
        case "REVERT":
            // Revert to original workout type
            if let type = WorkoutType(rawValue: originalType) {
                try? await CalendarScheduler.shared.transformBlock(
                    await CalendarScheduler.shared.getBlock(by: blockId)!,
                    to: type
                )
            }
        default:
            break
        }
    }
}

// MARK: - Value Receipt

struct ValueReceipt: Identifiable {
    let id = UUID()
    let weekStartDate: Date
    let weekEndDate: Date
    let completedWorkouts: Int
    let scheduledWorkouts: Int
    let missedWorkouts: Int
    let totalMinutes: Int
    let timeSavedMinutes: Int
    let patternsDiscovered: [String]
    let trustProgress: String?
    let streak: Int
}
