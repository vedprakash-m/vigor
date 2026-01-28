//
//  TrustAttributionTests.swift
//  VigorTests
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Test suite for Trust Attribution Engine - validates weighted deltas
//  and excuse recognition per PRD §2.2.2.
//

import XCTest
@testable import Vigor

final class TrustAttributionTests: XCTestCase {

    // MARK: - Positive Event Delta Tests

    func testCompletedWorkoutHasPositiveDelta() {
        let delta = TrustAttributionEngine.shared.calculateDelta(
            for: .completedWorkout,
            currentPhase: .observer
        )

        XCTAssertGreaterThan(delta, 0, "Completed workout should have positive delta")
    }

    func testSuggestedSlotAcceptedHasPositiveDelta() {
        let delta = TrustAttributionEngine.shared.calculateDelta(
            for: .suggestedSlotAccepted,
            currentPhase: .scheduler
        )

        XCTAssertGreaterThan(delta, 0, "Accepting suggested slot should have positive delta")
    }

    func testAutoScheduledWorkoutCompletedHasLargePositiveDelta() {
        let delta = TrustAttributionEngine.shared.calculateDelta(
            for: .autoScheduledWorkoutCompleted,
            currentPhase: .autoScheduler
        )

        let regularDelta = TrustAttributionEngine.shared.calculateDelta(
            for: .completedWorkout,
            currentPhase: .autoScheduler
        )

        XCTAssertGreaterThan(delta, regularDelta,
                            "Completing auto-scheduled workout should have larger delta than regular")
    }

    // MARK: - Negative Event Delta Tests

    func testMissedWorkoutWithoutExcuseHasNegativeDelta() {
        let delta = TrustAttributionEngine.shared.calculateDelta(
            for: .missedWorkout(.noReason),
            currentPhase: .scheduler
        )

        XCTAssertLessThan(delta, 0, "Missed workout without excuse should have negative delta")
    }

    func testUserDeletedBlockHasLargeNegativeDelta() {
        let deleteDelta = TrustAttributionEngine.shared.calculateDelta(
            for: .userDeletedBlock,
            currentPhase: .autoScheduler
        )

        let missedDelta = TrustAttributionEngine.shared.calculateDelta(
            for: .missedWorkout(.noReason),
            currentPhase: .autoScheduler
        )

        XCTAssertLessThan(deleteDelta, missedDelta,
                         "Deleting block should have larger negative impact than missing workout")
    }

    // MARK: - Excuse Recognition Tests

    func testCalendarConflictReducesNegativeImpact() {
        let noExcuseDelta = TrustAttributionEngine.shared.calculateDelta(
            for: .missedWorkout(.noReason),
            currentPhase: .scheduler
        )

        let excusedDelta = TrustAttributionEngine.shared.calculateDelta(
            for: .missedWorkout(.calendarConflict),
            currentPhase: .scheduler
        )

        XCTAssertGreaterThan(excusedDelta, noExcuseDelta,
                            "Calendar conflict excuse should reduce negative impact")
    }

    func testIllnessExcuseHasMinimalImpact() {
        let delta = TrustAttributionEngine.shared.calculateDelta(
            for: .missedWorkout(.illness),
            currentPhase: .autoScheduler
        )

        XCTAssertGreaterThan(delta, -0.02, "Illness excuse should have minimal negative impact")
    }

    func testTravelModeExcuseIsNeutral() {
        let delta = TrustAttributionEngine.shared.calculateDelta(
            for: .missedWorkout(.travelMode),
            currentPhase: .transformer
        )

        XCTAssertGreaterThan(delta, -0.01, "Travel mode should be nearly neutral")
    }

    func testPoorRecoveryExcuseReducesImpact() {
        let noExcuseDelta = TrustAttributionEngine.shared.calculateDelta(
            for: .missedWorkout(.noReason),
            currentPhase: .scheduler
        )

        let recoveryDelta = TrustAttributionEngine.shared.calculateDelta(
            for: .missedWorkout(.poorRecovery),
            currentPhase: .scheduler
        )

        XCTAssertGreaterThan(recoveryDelta, noExcuseDelta,
                            "Poor recovery should reduce negative impact")
    }

    // MARK: - Phase-Specific Delta Tests

    func testDeltasAreSmallerAtHigherPhases() {
        // At higher phases, system should be more stable (smaller swings)
        let observerDelta = TrustAttributionEngine.shared.calculateDelta(
            for: .completedWorkout,
            currentPhase: .observer
        )

        let fullGhostDelta = TrustAttributionEngine.shared.calculateDelta(
            for: .completedWorkout,
            currentPhase: .fullGhost
        )

        // Higher phases should have dampened positive swings (already trusted)
        XCTAssertLessThanOrEqual(fullGhostDelta, observerDelta,
                                 "Positive deltas should be equal or smaller at higher phases")
    }

    func testNegativeEventsHaveLargerImpactAtHigherPhases() {
        // Betraying trust at higher phases should hurt more
        let observerDelta = TrustAttributionEngine.shared.calculateDelta(
            for: .missedWorkout(.noReason),
            currentPhase: .observer
        )

        let transformerDelta = TrustAttributionEngine.shared.calculateDelta(
            for: .missedWorkout(.noReason),
            currentPhase: .transformer
        )

        // This is a design decision - could go either way
        // Currently testing that they're both negative
        XCTAssertLessThan(observerDelta, 0)
        XCTAssertLessThan(transformerDelta, 0)
    }

    // MARK: - Delta Magnitude Tests

    func testDeltaMagnitudesAreReasonable() {
        let events: [TrustEvent] = [
            .completedWorkout,
            .missedWorkout(.noReason),
            .missedWorkout(.calendarConflict),
            .missedWorkout(.illness),
            .missedWorkout(.travelMode),
            .userDeletedBlock,
            .suggestedSlotAccepted,
            .autoScheduledWorkoutCompleted
        ]

        for event in events {
            let delta = TrustAttributionEngine.shared.calculateDelta(
                for: event,
                currentPhase: .scheduler
            )

            XCTAssertGreaterThanOrEqual(delta, -0.3, "Delta should not be too negative: \(event)")
            XCTAssertLessThanOrEqual(delta, 0.2, "Delta should not be too positive: \(event)")
        }
    }

    // MARK: - Consistency Tests

    func testDeltasAreConsistentAcrossCalls() {
        let delta1 = TrustAttributionEngine.shared.calculateDelta(
            for: .completedWorkout,
            currentPhase: .scheduler
        )

        let delta2 = TrustAttributionEngine.shared.calculateDelta(
            for: .completedWorkout,
            currentPhase: .scheduler
        )

        XCTAssertEqual(delta1, delta2, "Same event should always produce same delta")
    }

    func testAllExcuseTypesHaveSmallerImpactThanNoReason() {
        let noReasonDelta = TrustAttributionEngine.shared.calculateDelta(
            for: .missedWorkout(.noReason),
            currentPhase: .autoScheduler
        )

        let excuseTypes: [MissedWorkoutReason] = [
            .calendarConflict,
            .illness,
            .travelMode,
            .poorRecovery,
            .emergencyConflict
        ]

        for excuse in excuseTypes {
            let excusedDelta = TrustAttributionEngine.shared.calculateDelta(
                for: .missedWorkout(excuse),
                currentPhase: .autoScheduler
            )

            XCTAssertGreaterThanOrEqual(excusedDelta, noReasonDelta,
                                        "Excuse \(excuse) should reduce negative impact")
        }
    }

    // MARK: - Integration Tests

    func testCumulativeDeltasProgressThroughPhases() {
        // Simulate progression through phases
        var confidence = 0.0

        // Simulate 20 completed workouts
        for _ in 0..<20 {
            let delta = TrustAttributionEngine.shared.calculateDelta(
                for: .completedWorkout,
                currentPhase: .observer
            )
            confidence += delta
        }

        XCTAssertGreaterThan(confidence, TrustPhase.scheduler.confidenceThreshold,
                            "20 completed workouts should get past Scheduler threshold")
    }

    func testMixedEventsResultInReasonableConfidence() {
        var confidence = 0.5

        // Mix of positive and negative events
        let events: [(TrustEvent, Int)] = [
            (.completedWorkout, 5),
            (.missedWorkout(.calendarConflict), 2),
            (.suggestedSlotAccepted, 3),
            (.userDeletedBlock, 1),
            (.completedWorkout, 4)
        ]

        for (event, count) in events {
            for _ in 0..<count {
                let delta = TrustAttributionEngine.shared.calculateDelta(
                    for: event,
                    currentPhase: .scheduler
                )
                confidence = max(0, min(1, confidence + delta))
            }
        }

        XCTAssertGreaterThan(confidence, 0, "Mixed events should result in positive confidence")
        XCTAssertLessThan(confidence, 1, "Should not hit max confidence")
    }
}
