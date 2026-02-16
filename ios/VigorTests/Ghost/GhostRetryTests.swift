//
//  GhostRetryTests.swift
//  VigorTests
//
//  Created by Vigor Team on February 15, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Tests for GhostEngine's executeWithRetry behavior, validating
//  retry counts, success-exit, and max-retry exhaustion.
//

import XCTest
@testable import Vigor

final class GhostRetryTests: XCTestCase {

    var sut: TestableRetryEngine!

    override func setUp() async throws {
        sut = TestableRetryEngine()
    }

    override func tearDown() async throws {
        sut = nil
    }

    // MARK: - Immediate Success

    func testSuccessOnFirstAttemptDoesNotRetry() async {
        await sut.executeWithRetry(cycleName: "morning", maxRetries: 2) {
            self.sut.recordAttempt()
            self.sut.markMorningSuccess()
        }

        XCTAssertEqual(sut.attemptCount, 1, "Should succeed on first try")
    }

    // MARK: - Retry on Failure

    func testRetriesOnFirstFailure() async {
        var callCount = 0
        await sut.executeWithRetry(cycleName: "morning", maxRetries: 2) {
            callCount += 1
            self.sut.recordAttempt()
            if callCount >= 2 {
                self.sut.markMorningSuccess()
            }
            // First attempt doesn't mark success → triggers retry
        }

        XCTAssertEqual(sut.attemptCount, 2, "Should retry once and succeed on second attempt")
    }

    // MARK: - Max Retries Exhausted

    func testStopsAfterMaxRetries() async {
        await sut.executeWithRetry(cycleName: "morning", maxRetries: 2) {
            self.sut.recordAttempt()
            // Never mark success
        }

        // 1 initial + 2 retries = 3 total attempts
        XCTAssertEqual(sut.attemptCount, 3, "Should attempt 1 + maxRetries times")
    }

    // MARK: - Evening Cycle

    func testEveningCycleRetryWorks() async {
        var callCount = 0
        await sut.executeWithRetry(cycleName: "evening", maxRetries: 2) {
            callCount += 1
            self.sut.recordAttempt()
            if callCount >= 3 {
                self.sut.markEveningSuccess()
            }
        }

        // Should exhaust all retries if needed
        XCTAssertEqual(sut.attemptCount, 3)
        XCTAssertTrue(sut.eveningCycleSucceeded)
    }

    // MARK: - Zero Max Retries

    func testZeroMaxRetriesNoRetry() async {
        await sut.executeWithRetry(cycleName: "morning", maxRetries: 0) {
            self.sut.recordAttempt()
            // No success mark
        }

        XCTAssertEqual(sut.attemptCount, 1, "Zero retries means only initial attempt")
    }

    // MARK: - Success Stops Retrying

    func testSuccessStopsRetrying() async {
        var callCount = 0
        await sut.executeWithRetry(cycleName: "morning", maxRetries: 5) {
            callCount += 1
            self.sut.recordAttempt()
            if callCount == 1 {
                self.sut.markMorningSuccess()
            }
        }

        XCTAssertEqual(sut.attemptCount, 1, "Should stop after success even with retries remaining")
    }
}

// MARK: - Testable Retry Engine

/// Mirrors GhostEngine's executeWithRetry logic without real cycle
/// bodies, sleep delays, or singleton dependencies.
final class TestableRetryEngine {

    private(set) var attemptCount = 0
    private(set) var morningCycleSucceeded = false
    private(set) var eveningCycleSucceeded = false

    func recordAttempt() {
        attemptCount += 1
    }

    func markMorningSuccess() {
        morningCycleSucceeded = true
    }

    func markEveningSuccess() {
        eveningCycleSucceeded = true
    }

    /// Mirrors GhostEngine.executeWithRetry but without Task.sleep delays
    /// and uses local success flags instead of checking date timestamps.
    func executeWithRetry(
        cycleName: String,
        maxRetries: Int = 2,
        body: @escaping () async -> Void
    ) async {
        var attempt = 0

        while attempt <= maxRetries {
            await body()

            // Check success
            let succeeded: Bool
            if cycleName == "morning" {
                succeeded = morningCycleSucceeded
            } else {
                succeeded = eveningCycleSucceeded
            }

            if succeeded {
                return
            }

            attempt += 1
        }
    }
}
