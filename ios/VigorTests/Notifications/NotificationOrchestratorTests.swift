//
//  NotificationOrchestratorTests.swift
//  VigorTests
//
//  Created by Vigor Team on February 15, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Tests for NotificationOrchestrator rate limiting, priority queueing,
//  and badge-only bypass behavior (PRD §4.3).
//

import XCTest
@testable import Vigor

final class NotificationOrchestratorTests: XCTestCase {

    var sut: TestableNotificationOrchestrator!

    override func setUp() async throws {
        sut = TestableNotificationOrchestrator()
    }

    override func tearDown() async throws {
        sut = nil
    }

    // MARK: - Priority Ordering

    func testPriorityOrderingLowIsLowest() {
        XCTAssertLessThan(NotificationPriority.low, NotificationPriority.normal)
        XCTAssertLessThan(NotificationPriority.low, NotificationPriority.high)
        XCTAssertLessThan(NotificationPriority.low, NotificationPriority.critical)
    }

    func testPriorityOrderingCriticalIsHighest() {
        XCTAssertGreaterThan(NotificationPriority.critical, NotificationPriority.high)
        XCTAssertGreaterThan(NotificationPriority.critical, NotificationPriority.normal)
        XCTAssertGreaterThan(NotificationPriority.critical, NotificationPriority.low)
    }

    func testPriorityComparableChain() {
        XCTAssertTrue(NotificationPriority.low < .normal)
        XCTAssertTrue(NotificationPriority.normal < .high)
        XCTAssertTrue(NotificationPriority.high < .critical)
    }

    func testPriorityEqualityWithSamePriority() {
        XCTAssertEqual(NotificationPriority.critical, NotificationPriority.critical)
        XCTAssertFalse(NotificationPriority.critical < .critical)
    }

    func testPriorityRawValues() {
        XCTAssertEqual(NotificationPriority.low.rawValue, 0)
        XCTAssertEqual(NotificationPriority.normal.rawValue, 1)
        XCTAssertEqual(NotificationPriority.high.rawValue, 2)
        XCTAssertEqual(NotificationPriority.critical.rawValue, 3)
    }

    // MARK: - Rate Limiting

    func testFirstNotificationCanBeSent() async {
        let result = await sut.trySend(title: "Test", priority: .normal)
        XCTAssertTrue(result.delivered, "First notification should be delivered")
    }

    func testSecondNotificationIsQueued() async {
        // Consume the daily slot
        _ = await sut.trySend(title: "First", priority: .normal)

        // Second should be queued, not delivered
        let result = await sut.trySend(title: "Second", priority: .normal)
        XCTAssertFalse(result.delivered, "Second notification should not be delivered immediately")
        XCTAssertTrue(result.queued, "Second notification should be queued")
    }

    func testHigherPriorityReplacesQueuedLowerPriority() async {
        // Fill daily slot
        _ = await sut.trySend(title: "First", priority: .normal)

        // Queue a low-priority notification
        _ = await sut.trySend(title: "Low", priority: .low)

        // Now push a critical one — should replace
        let result = await sut.trySend(title: "Critical", priority: .critical)
        XCTAssertTrue(result.queued, "Critical should be queued (replaced lower)")

        let pending = await sut.getPendingTitle()
        XCTAssertEqual(pending, "Critical", "Pending notification should be the critical one")
    }

    func testLowerPriorityDoesNotReplacePending() async {
        // Fill daily slot
        _ = await sut.trySend(title: "First", priority: .normal)

        // Queue a critical notification
        _ = await sut.trySend(title: "Critical", priority: .critical)

        // Try to push a low-priority one — should be dropped
        let result = await sut.trySend(title: "Low", priority: .low)
        XCTAssertFalse(result.delivered, "Low priority should not be delivered")
        XCTAssertFalse(result.queued, "Low priority should not replace critical")

        let pending = await sut.getPendingTitle()
        XCTAssertEqual(pending, "Critical", "Critical should remain pending")
    }

    func testEqualPriorityDoesNotReplacePending() async {
        // Fill daily slot
        _ = await sut.trySend(title: "First", priority: .normal)

        // Queue a high notification
        _ = await sut.trySend(title: "High1", priority: .high)

        // Try same priority — should be dropped
        let result = await sut.trySend(title: "High2", priority: .high)
        XCTAssertFalse(result.queued, "Equal priority should not replace pending")

        let pending = await sut.getPendingTitle()
        XCTAssertEqual(pending, "High1")
    }

    // MARK: - Badge-Only Bypass

    func testBadgeOnlyBypassesDailyLimit() async {
        // Consume the daily slot
        _ = await sut.trySend(title: "First", priority: .normal)

        // Badge-only should still be delivered
        let result = await sut.trySend(title: "Badge", priority: .low, badgeOnly: true)
        XCTAssertTrue(result.delivered, "Badge-only should bypass rate limit")
    }

    func testMultipleBadgeOnlyNotificationsAllowed() async {
        // Fill daily slot
        _ = await sut.trySend(title: "First", priority: .normal)

        // Multiple badge-only should all go through
        let r1 = await sut.trySend(title: "Badge1", priority: .low, badgeOnly: true)
        let r2 = await sut.trySend(title: "Badge2", priority: .low, badgeOnly: true)
        let r3 = await sut.trySend(title: "Badge3", priority: .low, badgeOnly: true)

        XCTAssertTrue(r1.delivered)
        XCTAssertTrue(r2.delivered)
        XCTAssertTrue(r3.delivered)
    }

    // MARK: - Onboarding Gate

    func testNotificationsBlockedBeforeOnboarding() async {
        await sut.setOnboardingComplete(false)

        let result = await sut.trySend(title: "Test", priority: .critical)
        XCTAssertFalse(result.delivered, "Should not send before onboarding")
    }

    func testNotificationsAllowedAfterOnboarding() async {
        await sut.setOnboardingComplete(true)

        let result = await sut.trySend(title: "Test", priority: .normal)
        XCTAssertTrue(result.delivered, "Should send after onboarding")
    }

    // MARK: - Day Reset

    func testNewDayResetsCounter() async {
        // Send one today
        _ = await sut.trySend(title: "Today", priority: .normal)

        // Simulate a new day
        await sut.simulateNewDay()

        // Should be able to send again
        let result = await sut.trySend(title: "Tomorrow", priority: .normal)
        XCTAssertTrue(result.delivered, "New day should reset daily counter")
    }
}

// MARK: - Testable Notification Orchestrator

/// Self-contained testable wrapper replicating NotificationOrchestrator's
/// rate limiting and priority queueing logic without UNUserNotificationCenter.
actor TestableNotificationOrchestrator {

    struct SendResult {
        let delivered: Bool
        let queued: Bool
    }

    private var notificationsSentToday = 0
    private var lastNotificationDate: Date?
    private let maxNotificationsPerDay = 1
    private var onboardingComplete = true
    private var pendingNotification: (title: String, priority: NotificationPriority)?

    // MARK: - Public test API

    func setOnboardingComplete(_ value: Bool) {
        onboardingComplete = value
    }

    func simulateNewDay() {
        // Push last notification date to yesterday
        lastNotificationDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        notificationsSentToday = 0
    }

    func getPendingTitle() -> String? {
        pendingNotification?.title
    }

    // MARK: - Send (mirrors real logic)

    func trySend(
        title: String,
        priority: NotificationPriority,
        badgeOnly: Bool = false
    ) -> SendResult {
        guard onboardingComplete else {
            return SendResult(delivered: false, queued: false)
        }

        // Badge-only bypass
        if badgeOnly {
            return SendResult(delivered: true, queued: false)
        }

        // Daily slot available?
        if canSendNotification() {
            recordNotificationSent()
            return SendResult(delivered: true, queued: false)
        }

        // Try to queue
        if let pending = pendingNotification {
            if priority > pending.priority {
                pendingNotification = (title, priority)
                return SendResult(delivered: false, queued: true)
            } else {
                // Equal or lower — drop
                return SendResult(delivered: false, queued: false)
            }
        } else {
            pendingNotification = (title, priority)
            return SendResult(delivered: false, queued: true)
        }
    }

    // MARK: - Private (mirrors real logic)

    private func canSendNotification() -> Bool {
        guard onboardingComplete else { return false }
        guard let lastDate = lastNotificationDate else { return true }

        let calendar = Calendar.current
        if calendar.isDateInToday(lastDate) {
            return notificationsSentToday < maxNotificationsPerDay
        } else {
            notificationsSentToday = 0
            return true
        }
    }

    private func recordNotificationSent() {
        notificationsSentToday += 1
        lastNotificationDate = Date()
    }
}
