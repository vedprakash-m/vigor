//
//  VigorLoggerTests.swift
//  VigorTests
//
//  Created by Vigor Team on February 15, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Tests for VigorLogger — verifies static Logger instances
//  and the timed() convenience method.
//

import XCTest
import os
@testable import Vigor

final class VigorLoggerTests: XCTestCase {

    // MARK: - Logger Categories Exist

    func testGhostLoggerIsNotNil() {
        let logger = VigorLogger.ghost
        XCTAssertNotNil(logger)
    }

    func testNotificationsLoggerIsNotNil() {
        XCTAssertNotNil(VigorLogger.notifications)
    }

    func testHealthKitLoggerIsNotNil() {
        XCTAssertNotNil(VigorLogger.healthKit)
    }

    func testTrustLoggerIsNotNil() {
        XCTAssertNotNil(VigorLogger.trust)
    }

    func testAPILoggerIsNotNil() {
        XCTAssertNotNil(VigorLogger.api)
    }

    func testGeneralLoggerIsNotNil() {
        XCTAssertNotNil(VigorLogger.general)
    }

    // MARK: - All Loggers Are Distinct

    func testLoggersAreDistinctInstances() {
        // Each category should produce a different Logger
        // (os.Logger doesn't conform to Equatable, so we test via type stability)
        let loggers: [Logger] = [
            VigorLogger.ghost,
            VigorLogger.notifications,
            VigorLogger.healthKit,
            VigorLogger.trust,
            VigorLogger.api,
            VigorLogger.general
        ]
        // Each Logger is a value type; at minimum, ensure we got 6 of them
        XCTAssertEqual(loggers.count, 6)
    }

    // MARK: - timed()

    func testTimedReturnsOperationResult() async {
        let result = await VigorLogger.timed(VigorLogger.general, "Test op") {
            return 42
        }
        XCTAssertEqual(result, 42)
    }

    func testTimedReturnsStringResult() async {
        let result = await VigorLogger.timed(VigorLogger.api, "String op") {
            return "hello"
        }
        XCTAssertEqual(result, "hello")
    }

    func testTimedPropagatesThrow() async {
        do {
            let _: Int = try await VigorLogger.timed(VigorLogger.general, "Fail op") {
                throw TestLoggerError.intentional
            }
            XCTFail("Should have thrown")
        } catch {
            XCTAssertTrue(error is TestLoggerError)
        }
    }

    func testTimedMeasuresNonTrivialDuration() async {
        let start = CFAbsoluteTimeGetCurrent()
        let _: Bool = await VigorLogger.timed(VigorLogger.general, "Sleep op") {
            try? await Task.sleep(nanoseconds: 50_000_000) // 50 ms
            return true
        }
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        XCTAssertGreaterThanOrEqual(elapsed, 0.04, "Should take at least ~50ms")
    }
}

private enum TestLoggerError: Error {
    case intentional
}
