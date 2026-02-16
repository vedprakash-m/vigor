//
//  TrustStateMachineTests.swift
//  VigorTests
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Test suite for Trust State Machine — validates all phase transitions
//  and Safety Breaker behavior per PRD §2.2.2.
//

import XCTest
@testable import Vigor

final class TrustStateMachineTests: XCTestCase {

    var sut: TestableTrustStateMachine!

    override func setUp() async throws {
        sut = await TestableTrustStateMachine()
    }

    override func tearDown() async throws {
        sut = nil
    }

    // MARK: - Initial State Tests

    func testInitialStateIsObserver() async {
        let phase = await sut.currentPhase
        XCTAssertEqual(phase, .observer, "Trust should start at Observer phase")
    }

    func testInitialTrustScoreIsZero() async {
        let score = await sut.trustScore
        XCTAssertEqual(score, 0.0, accuracy: 0.01, "Initial trust score should be 0")
    }

    // MARK: - Forward Progression Tests

    func testObserverToSchedulerProgression() async {
        // Complete enough workouts to reach Scheduler threshold (30)
        for _ in 0..<8 {
            await sut.handleEvent(.workoutCompleted(makeWorkout()))
        }

        let phase = await sut.currentPhase
        XCTAssertEqual(phase, .scheduler, "Should progress to Scheduler after demonstrating consistency")
    }

    func testSchedulerToAutoSchedulerProgression() async {
        await sut.setPhase(.scheduler)
        await sut.setTrustScore(35)

        // Build trust through consistent behavior
        for _ in 0..<7 {
            await sut.handleEvent(.workoutCompleted(makeWorkout()))
            await sut.handleEvent(.proposalAccepted)
        }

        let phase = await sut.currentPhase
        XCTAssertEqual(phase, .autoScheduler, "Should progress to AutoScheduler")
    }

    func testAutoSchedulerToTransformerProgression() async {
        await sut.setPhase(.autoScheduler)
        await sut.setTrustScore(65)

        // Demonstrate trust through completed workouts and accepted blocks
        for _ in 0..<5 {
            await sut.handleEvent(.workoutCompleted(makeWorkout()))
            await sut.handleEvent(.blockAccepted(makeBlock(autoScheduled: true)))
        }

        let phase = await sut.currentPhase
        XCTAssertEqual(phase, .transformer, "Should progress to Transformer")
    }

    func testTransformerToFullGhostProgression() async {
        await sut.setPhase(.transformer)
        await sut.setTrustScore(85)

        // Extended period of full autonomy trust
        for _ in 0..<5 {
            await sut.handleEvent(.workoutCompleted(makeWorkout()))
            await sut.handleEvent(.blockAccepted(makeBlock(autoScheduled: true)))
        }

        let phase = await sut.currentPhase
        XCTAssertEqual(phase, .fullGhost, "Should progress to FullGhost")
    }

    // MARK: - Trust Score Adjustment Tests

    func testWorkoutCompletedIncreasesTrustScore() async {
        let initial = await sut.trustScore
        await sut.handleEvent(.workoutCompleted(makeWorkout()))
        let updated = await sut.trustScore

        XCTAssertGreaterThan(updated, initial, "Completing workout should increase trust score")
    }

    func testBlockMissedDecreasesTrustScore() async {
        await sut.setTrustScore(50)
        let initial = await sut.trustScore

        await sut.handleEvent(.blockMissed(makeBlock(autoScheduled: true)))
        let updated = await sut.trustScore

        XCTAssertLessThan(updated, initial, "Missing block should decrease trust score")
    }

    func testBlockDeletedHasLargeNegativeImpact() async {
        await sut.setTrustScore(70)
        let initial = await sut.trustScore

        await sut.handleEvent(.blockDeleted(makeBlock(autoScheduled: true)))
        let updated = await sut.trustScore

        let drop = initial - updated
        XCTAssertGreaterThan(drop, 2, "Block deletion should have significant negative impact")
    }

    // MARK: - Safety Breaker Tests (Critical — PRD §2.2.2)

    func testSafetyBreakerTriggerOnThreeAutoDeletes() async {
        await sut.setPhase(.autoScheduler)
        await sut.setTrustScore(70)

        // Three consecutive auto-scheduled deletes should trigger Safety Breaker
        let autoBlock = makeBlock(autoScheduled: true)

        await sut.handleEvent(.blockDeleted(autoBlock))
        var phase = await sut.currentPhase
        XCTAssertEqual(phase, .autoScheduler, "Should still be at AutoScheduler after 1 delete")

        await sut.handleEvent(.blockDeleted(autoBlock))
        phase = await sut.currentPhase
        XCTAssertEqual(phase, .autoScheduler, "Should still be at AutoScheduler after 2 deletes")

        await sut.handleEvent(.blockDeleted(autoBlock))
        phase = await sut.currentPhase
        XCTAssertEqual(phase, .scheduler, "Safety Breaker: 3 auto-deletes should downgrade by one phase")
    }

    func testSafetyBreakerResetsOnWorkoutCompleted() async {
        await sut.setPhase(.autoScheduler)
        await sut.setTrustScore(70)

        let autoBlock = makeBlock(autoScheduled: true)

        // Two auto-deletes
        await sut.handleEvent(.blockDeleted(autoBlock))
        await sut.handleEvent(.blockDeleted(autoBlock))

        // Completed workout should reset the counter
        await sut.handleEvent(.workoutCompleted(makeWorkout()))

        // Third delete after reset shouldn't trigger breaker
        await sut.handleEvent(.blockDeleted(autoBlock))

        let phase = await sut.currentPhase
        XCTAssertEqual(phase, .autoScheduler, "Safety Breaker counter should reset after completed workout")
    }

    func testSafetyBreakerFromFullGhostDropsToTransformer() async {
        await sut.setPhase(.fullGhost)
        await sut.setTrustScore(95)

        let autoBlock = makeBlock(autoScheduled: true)

        // Trigger Safety Breaker from FullGhost
        for _ in 0..<3 {
            await sut.handleEvent(.blockDeleted(autoBlock))
        }

        let phase = await sut.currentPhase
        XCTAssertEqual(phase, .transformer, "Safety Breaker from FullGhost should drop to Transformer")
    }

    func testSafetyBreakerCannotDropBelowObserver() async {
        await sut.setPhase(.observer)
        await sut.setTrustScore(5)

        let autoBlock = makeBlock(autoScheduled: true)

        for _ in 0..<10 {
            await sut.handleEvent(.blockDeleted(autoBlock))
        }

        let phase = await sut.currentPhase
        XCTAssertEqual(phase, .observer, "Cannot drop below Observer phase")
    }

    func testManualBlockDeleteDoesNotTriggerSafetyBreaker() async {
        await sut.setPhase(.autoScheduler)
        await sut.setTrustScore(70)

        let manualBlock = makeBlock(autoScheduled: false)

        // Three manual deletes should NOT trigger safety breaker
        for _ in 0..<3 {
            await sut.handleEvent(.blockDeleted(manualBlock))
        }

        let phase = await sut.currentPhase
        XCTAssertEqual(phase, .autoScheduler,
                       "Manual block deletes should not trigger Safety Breaker")
    }

    // MARK: - Regression Protection Tests

    func testPhaseDoesNotDropOnSingleMiss() async {
        await sut.setPhase(.scheduler)
        await sut.setTrustScore(40)

        await sut.handleEvent(.blockMissed(makeBlock(autoScheduled: false)))

        let phase = await sut.currentPhase
        XCTAssertEqual(phase, .scheduler, "Single miss should not cause phase regression")
    }

    func testSignificantScoreDropCausesPhaseRegression() async {
        await sut.setPhase(.autoScheduler)
        await sut.setTrustScore(62) // Just above threshold of 60

        // Multiple negative events
        for _ in 0..<5 {
            await sut.handleEvent(.blockMissed(makeBlock(autoScheduled: true)))
        }

        let phase = await sut.currentPhase
        XCTAssertEqual(phase, .scheduler, "Should regress when trust score drops below threshold")
    }

    // MARK: - Triage Response Tests

    func testTriageResponseIsPositive() async {
        await sut.setTrustScore(40)
        let initial = await sut.trustScore

        await sut.handleEvent(.triageResponded(.lifeHappened))
        let updated = await sut.trustScore

        XCTAssertGreaterThan(updated, initial, "Triage response should increase trust")
    }

    // MARK: - Capability Tests

    func testObserverCannotCreateBlocks() async {
        await sut.setPhase(.observer)
        let capabilities = await sut.currentCapabilities

        XCTAssertFalse(capabilities.contains(.createBlocks),
                       "Observer should not have createBlocks capability")
    }

    func testAutoSchedulerCanCreateBlocks() async {
        await sut.setPhase(.autoScheduler)
        let capabilities = await sut.currentCapabilities

        XCTAssertTrue(capabilities.contains(.createBlocks),
                      "AutoScheduler should have createBlocks capability")
    }

    func testFullGhostHasAllCapabilities() async {
        await sut.setPhase(.fullGhost)
        let capabilities = await sut.currentCapabilities

        XCTAssertTrue(capabilities.contains(.createBlocks))
        XCTAssertTrue(capabilities.contains(.transformBlocks))
        XCTAssertTrue(capabilities.contains(.removeBlocks))
    }

    // MARK: - Edge Case Tests

    func testTrustScoreCannotExceed100() async {
        await sut.setPhase(.fullGhost)
        await sut.setTrustScore(98)

        for _ in 0..<20 {
            await sut.handleEvent(.workoutCompleted(makeWorkout()))
        }

        let score = await sut.trustScore
        XCTAssertLessThanOrEqual(score, 100.0, "Trust score should not exceed 100")
    }

    func testTrustScoreCannotGoBelowZero() async {
        await sut.setTrustScore(3)

        for _ in 0..<20 {
            await sut.handleEvent(.blockMissed(makeBlock(autoScheduled: true)))
        }

        let score = await sut.trustScore
        XCTAssertGreaterThanOrEqual(score, 0.0, "Trust score should not go below 0")
    }

    func testRapidEventSequenceHandledCorrectly() async {
        await sut.handleEvent(.workoutCompleted(makeWorkout()))
        await sut.handleEvent(.proposalAccepted)
        await sut.handleEvent(.blockMissed(makeBlock(autoScheduled: false)))
        await sut.handleEvent(.workoutCompleted(makeWorkout()))
        await sut.handleEvent(.workoutCompleted(makeWorkout()))

        let score = await sut.trustScore
        let phase = await sut.currentPhase

        XCTAssertGreaterThanOrEqual(score, 0.0)
        XCTAssertLessThanOrEqual(score, 100.0)
        XCTAssertNotNil(phase)
    }
}

// MARK: - Testable Trust State Machine

/// Testable wrapper that allows setting internal state for testing.
/// Mirrors TrustStateMachine logic without persistence, notifications, or time gates.
actor TestableTrustStateMachine {
    private var phase: TrustPhase = .observer
    private var score: Double = 0.0
    private var consecutiveAutoDeletes: Int = 0
    private let engine = TrustAttributionEngine()

    /// Phase thresholds (score-based, ignoring time gates for testing).
    private let thresholds: [TrustPhase: Double] = [
        .observer: 0,
        .scheduler: 30,
        .autoScheduler: 60,
        .transformer: 80,
        .fullGhost: 90
    ]

    var currentPhase: TrustPhase { phase }
    var trustScore: Double { score }
    var currentCapabilities: Set<TrustCapability> { Set(phase.capabilities) }

    func setPhase(_ newPhase: TrustPhase) {
        phase = newPhase
    }

    func setTrustScore(_ newScore: Double) {
        score = max(0, min(100, newScore))
    }

    func handleEvent(_ event: TrustEvent) async {
        // Calculate delta via Attribution Engine
        let delta = await engine.calculateTrustDelta(
            event: event,
            currentPhase: phase,
            trustScore: score
        )
        score = max(0, min(100, score + delta))

        // Safety Breaker — only auto-scheduled deletes count
        if case .blockDeleted(let block) = event, block.wasAutoScheduled {
            consecutiveAutoDeletes += 1
            if consecutiveAutoDeletes >= 3 {
                if let lower = phase.previous {
                    phase = lower
                    // Reduce score to just above the destination threshold
                    if let t = thresholds[phase] {
                        score = min(score, t + 10)
                    }
                }
                consecutiveAutoDeletes = 0
            }
        } else if case .workoutCompleted = event {
            consecutiveAutoDeletes = 0
        }

        // Phase progression / regression (no time gate in tests)
        updatePhaseBasedOnScore()
    }

    private func updatePhaseBasedOnScore() {
        // Progression
        if let nextPhase = phase.next,
           let threshold = thresholds[nextPhase],
           score >= threshold {
            phase = nextPhase
        }

        // Regression
        if let threshold = thresholds[phase],
           score < threshold,
           let prev = phase.previous {
            phase = prev
        }
    }
}

// MARK: - Test Helpers

extension TrustStateMachineTests {
    func makeWorkout(duration: TimeInterval = 3600) -> DetectedWorkout {
        DetectedWorkout(
            id: UUID().uuidString,
            type: .cardio,
            startDate: Date(),
            endDate: Date().addingTimeInterval(duration),
            duration: duration,
            activeCalories: 300,
            averageHeartRate: 145,
            source: "Apple Watch"
        )
    }

    func makeBlock(autoScheduled: Bool) -> TrainingBlock {
        TrainingBlock(
            id: UUID().uuidString,
            calendarEventId: "cal-\(UUID().uuidString.prefix(4))",
            workoutType: .strength,
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600),
            wasAutoScheduled: autoScheduled,
            status: .scheduled,
            generatedWorkout: nil
        )
    }
}
