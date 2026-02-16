//
//  TrustAttributionTests.swift
//  VigorTests
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Test suite for Trust Attribution Engine — validates weighted deltas
//  and modifier calculations per Tech Spec §2.3.
//

import XCTest
@testable import Vigor

final class TrustAttributionTests: XCTestCase {

    var sut: TestableTrustAttribution!

    override func setUp() async throws {
        sut = TestableTrustAttribution()
    }

    override func tearDown() async throws {
        sut = nil
    }

    // MARK: - Event Weight Lookup

    func testWorkoutCompletedHasPositiveWeight() async {
        let workout = makeWorkout(duration: 3600)
        let delta = await sut.calculateTrustDelta(
            event: .workoutCompleted(workout),
            currentPhase: .observer,
            trustScore: 20
        )
        XCTAssertGreaterThan(delta, 0, "Completed workout should have positive delta")
    }

    func testBlockDeletedHasNegativeWeight() async {
        let block = makeBlock(autoScheduled: false)
        let delta = await sut.calculateTrustDelta(
            event: .blockDeleted(block),
            currentPhase: .scheduler,
            trustScore: 40
        )
        XCTAssertLessThan(delta, 0, "Deleting a block should have negative delta")
    }

    func testBlockMissedHasNegativeWeight() async {
        let block = makeBlock(autoScheduled: true)
        let delta = await sut.calculateTrustDelta(
            event: .blockMissed(block),
            currentPhase: .autoScheduler,
            trustScore: 60
        )
        XCTAssertLessThan(delta, 0, "Missed block should have negative delta")
    }

    func testProposalAcceptedHasPositiveWeight() async {
        let delta = await sut.calculateTrustDelta(
            event: .proposalAccepted,
            currentPhase: .scheduler,
            trustScore: 30
        )
        XCTAssertGreaterThan(delta, 0)
    }

    func testProposalRejectedHasNegativeWeight() async {
        let delta = await sut.calculateTrustDelta(
            event: .proposalRejected,
            currentPhase: .scheduler,
            trustScore: 30
        )
        XCTAssertLessThan(delta, 0)
    }

    func testPermissionRevokedHasLargeNegativeWeight() async {
        let delta = await sut.calculateTrustDelta(
            event: .permissionRevoked("HealthKit"),
            currentPhase: .autoScheduler,
            trustScore: 50
        )
        XCTAssertLessThan(delta, -5, "Permission revocation should have large negative impact")
    }

    // MARK: - Phase Modifier Tests

    func testObserverPhaseHasHigherMultiplier() async {
        let workout = makeWorkout(duration: 3600)
        let observerDelta = await sut.calculateTrustDelta(
            event: .workoutCompleted(workout),
            currentPhase: .observer,
            trustScore: 10
        )
        let fullGhostDelta = await sut.calculateTrustDelta(
            event: .workoutCompleted(workout),
            currentPhase: .fullGhost,
            trustScore: 10
        )
        XCTAssertGreaterThan(observerDelta, fullGhostDelta,
                            "Observer phase should amplify positive events more than Full Ghost")
    }

    // MARK: - Confidence Modifier Tests

    func testLongWorkoutHasHigherConfidenceModifier() async {
        let longWorkout = makeWorkout(duration: 60 * 60)   // 60 min
        let shortWorkout = makeWorkout(duration: 10 * 60)  // 10 min

        let longDelta = await sut.calculateTrustDelta(
            event: .workoutCompleted(longWorkout),
            currentPhase: .scheduler,
            trustScore: 30
        )
        let shortDelta = await sut.calculateTrustDelta(
            event: .workoutCompleted(shortWorkout),
            currentPhase: .scheduler,
            trustScore: 30
        )
        XCTAssertGreaterThan(longDelta, shortDelta,
                            "Longer workout should earn more trust")
    }

    func testAutoScheduledBlockDeleteHasHigherImpact() async {
        let autoBlock = makeBlock(autoScheduled: true)
        let manualBlock = makeBlock(autoScheduled: false)

        let autoDelta = await sut.calculateTrustDelta(
            event: .blockDeleted(autoBlock),
            currentPhase: .autoScheduler,
            trustScore: 50
        )
        let manualDelta = await sut.calculateTrustDelta(
            event: .blockDeleted(manualBlock),
            currentPhase: .autoScheduler,
            trustScore: 50
        )
        XCTAssertLessThan(autoDelta, manualDelta,
                         "Deleting auto-scheduled block should hurt more")
    }

    // MARK: - Diminishing Returns at High Trust

    func testPositiveDeltaDiminishesAtHighTrust() async {
        let workout = makeWorkout(duration: 3600)
        let lowTrustDelta = await sut.calculateTrustDelta(
            event: .workoutCompleted(workout),
            currentPhase: .fullGhost,
            trustScore: 50
        )
        let highTrustDelta = await sut.calculateTrustDelta(
            event: .workoutCompleted(workout),
            currentPhase: .fullGhost,
            trustScore: 95
        )
        XCTAssertGreaterThan(lowTrustDelta, highTrustDelta,
                            "Positive delta should diminish at high trust scores")
    }

    func testNegativeDeltaAmplifiedAtHighTrust() async {
        let block = makeBlock(autoScheduled: true)
        let lowTrustDelta = await sut.calculateTrustDelta(
            event: .blockMissed(block),
            currentPhase: .fullGhost,
            trustScore: 50
        )
        let highTrustDelta = await sut.calculateTrustDelta(
            event: .blockMissed(block),
            currentPhase: .fullGhost,
            trustScore: 90
        )
        XCTAssertLessThan(highTrustDelta, lowTrustDelta,
                         "Negative delta should be amplified at high trust")
    }

    // MARK: - Triage Modifier Tests

    func testTriageResponseIsPositive() async {
        let delta = await sut.calculateTrustDelta(
            event: .triageResponded(.lifeHappened),
            currentPhase: .scheduler,
            trustScore: 30
        )
        XCTAssertGreaterThan(delta, 0, "Responding to triage should be positive")
    }

    // MARK: - Streak Bonus

    func testStreakBonusZeroForShortStreaks() async {
        let bonus = await sut.calculateStreakBonus(consecutiveWorkouts: 1)
        XCTAssertEqual(bonus, 0)
    }

    func testStreakBonusIncreasesWithStreak() async {
        let bonus3 = await sut.calculateStreakBonus(consecutiveWorkouts: 3)
        let bonus7 = await sut.calculateStreakBonus(consecutiveWorkouts: 7)
        let bonus14 = await sut.calculateStreakBonus(consecutiveWorkouts: 14)

        XCTAssertGreaterThan(bonus3, 0)
        XCTAssertGreaterThan(bonus7, bonus3)
        XCTAssertGreaterThan(bonus14, bonus7)
    }

    // MARK: - Consistency

    func testSameEventProducesSameDelta() async {
        let workout = makeWorkout(duration: 3600)
        let delta1 = await sut.calculateTrustDelta(
            event: .workoutCompleted(workout),
            currentPhase: .scheduler,
            trustScore: 40
        )
        let delta2 = await sut.calculateTrustDelta(
            event: .workoutCompleted(workout),
            currentPhase: .scheduler,
            trustScore: 40
        )
        XCTAssertEqual(delta1, delta2, accuracy: 0.0001)
    }

    // MARK: - Delta Magnitude Bounds

    func testDeltaMagnitudesAreReasonable() async {
        let events: [TrustEvent] = [
            .workoutCompleted(makeWorkout(duration: 3600)),
            .blockDeleted(makeBlock(autoScheduled: false)),
            .blockMissed(makeBlock(autoScheduled: true)),
            .proposalAccepted,
            .proposalRejected,
            .appOpened,
            .triageResponded(.lifeHappened)
        ]

        for event in events {
            let delta = await sut.calculateTrustDelta(
                event: event,
                currentPhase: .scheduler,
                trustScore: 40
            )
            XCTAssertGreaterThanOrEqual(delta, -30, "Delta should not be unreasonably negative: \(event)")
            XCTAssertLessThanOrEqual(delta, 20, "Delta should not be unreasonably positive: \(event)")
        }
    }
}

// MARK: - Testable Wrapper

/// Thin wrapper to instantiate TrustAttributionEngine (actor) for testing.
actor TestableTrustAttribution {
    private let engine = TrustAttributionEngine()

    func calculateTrustDelta(event: TrustEvent, currentPhase: TrustPhase, trustScore: Double) async -> Double {
        await engine.calculateTrustDelta(event: event, currentPhase: currentPhase, trustScore: trustScore)
    }

    func calculateStreakBonus(consecutiveWorkouts: Int) async -> Double {
        await engine.calculateStreakBonus(consecutiveWorkouts: consecutiveWorkouts)
    }
}

// MARK: - Test Helpers

extension TrustAttributionTests {
    func makeWorkout(duration: TimeInterval) -> DetectedWorkout {
        DetectedWorkout(
            id: UUID().uuidString,
            type: .cardio,
            startDate: Date(),
            endDate: Date().addingTimeInterval(duration),
            duration: duration,
            activeCalories: 300,
            averageHeartRate: 140,
            source: "Apple Watch"
        )
    }

    func makeBlock(autoScheduled: Bool) -> TrainingBlock {
        TrainingBlock(
            id: UUID().uuidString,
            calendarEventId: "cal-1",
            workoutType: .strength,
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600),
            wasAutoScheduled: autoScheduled,
            status: .scheduled,
            generatedWorkout: nil
        )
    }
}
