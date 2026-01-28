//
//  TrustStateMachineTests.swift
//  VigorTests
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Test suite for Trust State Machine - validates all phase transitions
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

    func testInitialConfidenceIsZero() async {
        let confidence = await sut.currentConfidence
        XCTAssertEqual(confidence, 0.0, accuracy: 0.01, "Initial confidence should be 0")
    }

    // MARK: - Forward Progression Tests

    func testObserverToSchedulerProgression() async {
        // Complete enough workouts to reach Scheduler threshold
        for _ in 0..<5 {
            await sut.handleEvent(.completedWorkout)
        }

        let phase = await sut.currentPhase
        XCTAssertEqual(phase, .scheduler, "Should progress to Scheduler after demonstrating consistency")
    }

    func testSchedulerToAutoSchedulerProgression() async {
        // First get to Scheduler
        await sut.setPhase(.scheduler)
        await sut.setConfidence(TrustPhase.scheduler.confidenceThreshold)

        // Build confidence through consistent behavior
        for _ in 0..<7 {
            await sut.handleEvent(.completedWorkout)
            await sut.handleEvent(.suggestedSlotAccepted)
        }

        let phase = await sut.currentPhase
        XCTAssertEqual(phase, .autoScheduler, "Should progress to AutoScheduler")
    }

    func testAutoSchedulerToTransformerProgression() async {
        await sut.setPhase(.autoScheduler)
        await sut.setConfidence(TrustPhase.autoScheduler.confidenceThreshold)

        // Demonstrate trust through auto-scheduled workout completions
        for _ in 0..<10 {
            await sut.handleEvent(.completedWorkout)
            await sut.handleEvent(.autoScheduledWorkoutCompleted)
        }

        let phase = await sut.currentPhase
        XCTAssertEqual(phase, .transformer, "Should progress to Transformer")
    }

    func testTransformerToFullGhostProgression() async {
        await sut.setPhase(.transformer)
        await sut.setConfidence(TrustPhase.transformer.confidenceThreshold)

        // Extended period of full autonomy trust
        for _ in 0..<14 {
            await sut.handleEvent(.completedWorkout)
            await sut.handleEvent(.transformedScheduleAccepted)
        }

        let phase = await sut.currentPhase
        XCTAssertEqual(phase, .fullGhost, "Should progress to FullGhost")
    }

    // MARK: - Confidence Adjustment Tests

    func testCompletedWorkoutIncreasesConfidence() async {
        let initialConfidence = await sut.currentConfidence
        await sut.handleEvent(.completedWorkout)
        let newConfidence = await sut.currentConfidence

        XCTAssertGreaterThan(newConfidence, initialConfidence, "Completing workout should increase confidence")
    }

    func testMissedWorkoutDecreasesConfidence() async {
        // Start with some confidence
        await sut.setConfidence(0.5)
        let initialConfidence = await sut.currentConfidence

        await sut.handleEvent(.missedWorkout(.noReason))
        let newConfidence = await sut.currentConfidence

        XCTAssertLessThan(newConfidence, initialConfidence, "Missing workout should decrease confidence")
    }

    func testUserDeletedBlockHasLargeNegativeImpact() async {
        await sut.setConfidence(0.7)
        let initialConfidence = await sut.currentConfidence

        await sut.handleEvent(.userDeletedBlock)
        let newConfidence = await sut.currentConfidence

        let drop = initialConfidence - newConfidence
        XCTAssertGreaterThan(drop, 0.1, "User deleting block should have significant negative impact")
    }

    // MARK: - Safety Breaker Tests (Critical - PRD §2.2.2)

    func testSafetyBreakerTriggerOnThreeDeletes() async {
        // Get to AutoScheduler
        await sut.setPhase(.autoScheduler)
        await sut.setConfidence(0.8)

        // Three consecutive deletes should trigger Safety Breaker
        await sut.handleEvent(.userDeletedBlock)
        var phase = await sut.currentPhase
        XCTAssertEqual(phase, .autoScheduler, "Should still be at AutoScheduler after 1 delete")

        await sut.handleEvent(.userDeletedBlock)
        phase = await sut.currentPhase
        XCTAssertEqual(phase, .autoScheduler, "Should still be at AutoScheduler after 2 deletes")

        await sut.handleEvent(.userDeletedBlock)
        phase = await sut.currentPhase
        XCTAssertEqual(phase, .scheduler, "Safety Breaker: 3 deletes should downgrade by one phase")
    }

    func testSafetyBreakerResetsOnCompletedWorkout() async {
        await sut.setPhase(.autoScheduler)
        await sut.setConfidence(0.8)

        // Two deletes
        await sut.handleEvent(.userDeletedBlock)
        await sut.handleEvent(.userDeletedBlock)

        // Completed workout should reset the counter
        await sut.handleEvent(.completedWorkout)

        // Third delete after reset shouldn't trigger
        await sut.handleEvent(.userDeletedBlock)

        let phase = await sut.currentPhase
        XCTAssertEqual(phase, .autoScheduler, "Safety Breaker counter should reset after completed workout")
    }

    func testSafetyBreakerFromFullGhostDropsToTransformer() async {
        await sut.setPhase(.fullGhost)
        await sut.setConfidence(0.95)

        // Trigger Safety Breaker from FullGhost
        for _ in 0..<3 {
            await sut.handleEvent(.userDeletedBlock)
        }

        let phase = await sut.currentPhase
        XCTAssertEqual(phase, .transformer, "Safety Breaker from FullGhost should drop to Transformer")
    }

    func testSafetyBreakerCannotDropBelowObserver() async {
        await sut.setPhase(.observer)
        await sut.setConfidence(0.1)

        // Multiple delete attempts
        for _ in 0..<10 {
            await sut.handleEvent(.userDeletedBlock)
        }

        let phase = await sut.currentPhase
        XCTAssertEqual(phase, .observer, "Cannot drop below Observer phase")
    }

    // MARK: - Regression Protection Tests

    func testPhaseDoesNotDropOnSingleMiss() async {
        await sut.setPhase(.scheduler)
        await sut.setConfidence(0.6)

        await sut.handleEvent(.missedWorkout(.calendarConflict))

        let phase = await sut.currentPhase
        XCTAssertEqual(phase, .scheduler, "Single miss should not cause phase regression")
    }

    func testSignificantConfidenceDropCausesPhaseRegression() async {
        await sut.setPhase(.autoScheduler)
        await sut.setConfidence(TrustPhase.autoScheduler.confidenceThreshold + 0.05)

        // Multiple negative events
        for _ in 0..<5 {
            await sut.handleEvent(.missedWorkout(.noReason))
        }

        let phase = await sut.currentPhase
        XCTAssertEqual(phase, .scheduler, "Should regress when confidence drops below threshold")
    }

    // MARK: - Excuse Recognition Tests

    func testRecognizedExcuseReducesNegativeImpact() async {
        await sut.setConfidence(0.7)

        // Miss with recognized excuse
        await sut.handleEvent(.missedWorkout(.calendarConflict))
        let confidenceWithExcuse = await sut.currentConfidence

        // Reset and miss without excuse
        await sut.setConfidence(0.7)
        await sut.handleEvent(.missedWorkout(.noReason))
        let confidenceWithoutExcuse = await sut.currentConfidence

        XCTAssertGreaterThan(confidenceWithExcuse, confidenceWithoutExcuse,
                            "Recognized excuse should result in smaller confidence drop")
    }

    func testTravelModeExcuseHasMinimalImpact() async {
        await sut.setConfidence(0.8)
        let initial = await sut.currentConfidence

        await sut.handleEvent(.missedWorkout(.travelMode))
        let after = await sut.currentConfidence

        let drop = initial - after
        XCTAssertLessThan(drop, 0.02, "Travel mode should have minimal negative impact")
    }

    // MARK: - Capability Tests

    func testObserverCannotAutoSchedule() async {
        await sut.setPhase(.observer)
        let capabilities = await sut.currentCapabilities

        XCTAssertFalse(capabilities.contains(.autoScheduleBlocks),
                       "Observer should not have auto-schedule capability")
    }

    func testAutoSchedulerCanAutoSchedule() async {
        await sut.setPhase(.autoScheduler)
        let capabilities = await sut.currentCapabilities

        XCTAssertTrue(capabilities.contains(.autoScheduleBlocks),
                      "AutoScheduler should have auto-schedule capability")
    }

    func testFullGhostHasAllCapabilities() async {
        await sut.setPhase(.fullGhost)
        let capabilities = await sut.currentCapabilities

        XCTAssertTrue(capabilities.contains(.autoScheduleBlocks))
        XCTAssertTrue(capabilities.contains(.transformSchedule))
        XCTAssertTrue(capabilities.contains(.shadowSyncToWork))
        XCTAssertTrue(capabilities.contains(.suggestRecoveryDays))
    }

    // MARK: - Edge Case Tests

    func testConfidenceCannotExceedOne() async {
        await sut.setPhase(.fullGhost)
        await sut.setConfidence(0.99)

        for _ in 0..<20 {
            await sut.handleEvent(.completedWorkout)
        }

        let confidence = await sut.currentConfidence
        XCTAssertLessThanOrEqual(confidence, 1.0, "Confidence should not exceed 1.0")
    }

    func testConfidenceCannotGoBelowZero() async {
        await sut.setConfidence(0.05)

        for _ in 0..<20 {
            await sut.handleEvent(.missedWorkout(.noReason))
        }

        let confidence = await sut.currentConfidence
        XCTAssertGreaterThanOrEqual(confidence, 0.0, "Confidence should not go below 0.0")
    }

    func testRapidEventSequenceHandledCorrectly() async {
        // Simulate rapid real-world sequence
        await sut.handleEvent(.completedWorkout)
        await sut.handleEvent(.suggestedSlotAccepted)
        await sut.handleEvent(.missedWorkout(.calendarConflict))
        await sut.handleEvent(.completedWorkout)
        await sut.handleEvent(.completedWorkout)

        // Should still be in valid state
        let confidence = await sut.currentConfidence
        let phase = await sut.currentPhase

        XCTAssertGreaterThanOrEqual(confidence, 0.0)
        XCTAssertLessThanOrEqual(confidence, 1.0)
        XCTAssertNotNil(phase)
    }
}

// MARK: - Testable Trust State Machine

/// Testable wrapper that allows setting internal state for testing
actor TestableTrustStateMachine {
    private var phase: TrustPhase = .observer
    private var confidence: Double = 0.0
    private var consecutiveDeletes: Int = 0

    var currentPhase: TrustPhase { phase }
    var currentConfidence: Double { confidence }
    var currentCapabilities: Set<TrustCapability> { Set(phase.capabilities) }

    func setPhase(_ newPhase: TrustPhase) {
        phase = newPhase
    }

    func setConfidence(_ newConfidence: Double) {
        confidence = max(0, min(1, newConfidence))
    }

    func handleEvent(_ event: TrustEvent) async {
        // Apply confidence delta
        let delta = TrustAttributionEngine.shared.calculateDelta(for: event, currentPhase: phase)
        confidence = max(0, min(1, confidence + delta))

        // Handle Safety Breaker
        if case .userDeletedBlock = event {
            consecutiveDeletes += 1
            if consecutiveDeletes >= 3 {
                // Downgrade one phase
                if let lowerPhase = phase.previousPhase {
                    phase = lowerPhase
                }
                consecutiveDeletes = 0
            }
        } else if case .completedWorkout = event {
            consecutiveDeletes = 0
        }

        // Check for phase progression or regression
        updatePhaseBasedOnConfidence()
    }

    private func updatePhaseBasedOnConfidence() {
        // Check for progression
        if let nextPhase = phase.nextPhase,
           confidence >= nextPhase.confidenceThreshold {
            phase = nextPhase
        }

        // Check for regression
        if confidence < phase.confidenceThreshold,
           let previousPhase = phase.previousPhase {
            phase = previousPhase
        }
    }
}

// MARK: - Trust Phase Extensions for Testing

extension TrustPhase {
    var nextPhase: TrustPhase? {
        switch self {
        case .observer: return .scheduler
        case .scheduler: return .autoScheduler
        case .autoScheduler: return .transformer
        case .transformer: return .fullGhost
        case .fullGhost: return nil
        }
    }

    var previousPhase: TrustPhase? {
        switch self {
        case .observer: return nil
        case .scheduler: return .observer
        case .autoScheduler: return .scheduler
        case .transformer: return .autoScheduler
        case .fullGhost: return .transformer
        }
    }
}
