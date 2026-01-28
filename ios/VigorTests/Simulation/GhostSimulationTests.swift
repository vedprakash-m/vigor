//
//  GhostSimulationTests.swift
//  VigorTests
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Simulates 60-day user journey to validate Ghost behavior.
//  Per Tasks.md Phase 2.6: Simulation covering edge cases.
//

import XCTest
@testable import Vigor

final class GhostSimulationTests: XCTestCase {

    var simulator: GhostSimulator!

    override func setUp() async throws {
        simulator = await GhostSimulator()
    }

    override func tearDown() async throws {
        simulator = nil
    }

    // MARK: - 60-Day Journey Tests

    func testPerfectUserJourney() async {
        // User who completes every workout
        let journey = await simulator.simulate(
            days: 60,
            completionRate: 1.0,
            excuseRate: 0.0,
            deleteRate: 0.0
        )

        XCTAssertEqual(journey.finalPhase, .fullGhost, "Perfect user should reach FullGhost")
        XCTAssertGreaterThanOrEqual(journey.finalConfidence, 0.90, "Should have very high confidence")
        XCTAssertEqual(journey.safetyBreakerTriggers, 0, "No safety breaker triggers")
    }

    func testConsistentUserJourney() async {
        // User who completes 80% of workouts
        let journey = await simulator.simulate(
            days: 60,
            completionRate: 0.80,
            excuseRate: 0.3,  // 30% of misses have excuses
            deleteRate: 0.0
        )

        XCTAssertTrue([.transformer, .fullGhost].contains(journey.finalPhase),
                      "Consistent user should reach Transformer or FullGhost")
        XCTAssertGreaterThanOrEqual(journey.finalConfidence, 0.65, "Should have good confidence")
    }

    func testInconsistentUserJourney() async {
        // User who completes 50% of workouts
        let journey = await simulator.simulate(
            days: 60,
            completionRate: 0.50,
            excuseRate: 0.2,
            deleteRate: 0.0
        )

        XCTAssertTrue([.scheduler, .autoScheduler].contains(journey.finalPhase),
                      "Inconsistent user should stay at Scheduler or AutoScheduler")
    }

    func testHostileUserJourney() async {
        // User who frequently deletes blocks
        let journey = await simulator.simulate(
            days: 60,
            completionRate: 0.30,
            excuseRate: 0.1,
            deleteRate: 0.4  // 40% of scheduled blocks deleted
        )

        XCTAssertEqual(journey.finalPhase, .observer, "Hostile user should regress to Observer")
        XCTAssertGreaterThan(journey.safetyBreakerTriggers, 0, "Safety breaker should trigger")
    }

    // MARK: - Edge Case Tests

    func testVacationMode() async {
        // User goes on 2-week vacation
        let journey = await simulator.simulate(
            days: 60,
            completionRate: 0.75,
            excuseRate: 0.5,
            deleteRate: 0.0,
            vacationPeriods: [(start: 20, end: 34)]  // Days 20-34 vacation
        )

        // Should not lose too much trust during vacation
        XCTAssertGreaterThanOrEqual(journey.trustBeforeVacation - journey.trustAfterVacation, -0.1,
                                    "Vacation should not cause major trust loss")
    }

    func testIllnessRecovery() async {
        // User gets sick for a week
        let journey = await simulator.simulate(
            days: 60,
            completionRate: 0.70,
            excuseRate: 0.9,  // Most misses during illness are excused
            deleteRate: 0.0,
            illnessPeriods: [(start: 25, end: 32)]
        )

        // Trust should recover after illness
        XCTAssertGreaterThanOrEqual(journey.finalConfidence, journey.confidenceAtDay30 - 0.15,
                                    "Trust should recover after illness")
    }

    func testBurstySafetyBreaker() async {
        // User deletes 3 blocks in a row, then becomes consistent
        let journey = await simulator.simulate(
            days: 60,
            completionRate: 0.85,
            excuseRate: 0.0,
            deleteRate: 0.0,
            burstDeletes: [(day: 15, count: 3), (day: 45, count: 3)]
        )

        // Should recover after each burst
        XCTAssertEqual(journey.safetyBreakerTriggers, 2, "Should trigger twice")
        XCTAssertGreaterThanOrEqual(journey.finalConfidence, 0.5, "Should recover to reasonable level")
    }

    // MARK: - Calendar Conflict Tests

    func testCalendarConflictHandling() async {
        // Simulate calendar conflicts requiring transforms
        let journey = await simulator.simulate(
            days: 60,
            completionRate: 0.80,
            excuseRate: 0.5,
            deleteRate: 0.0,
            conflictsPerWeek: 2
        )

        XCTAssertGreaterThan(journey.transformsExecuted, 0, "Should execute some transforms")
        XCTAssertGreaterThanOrEqual(journey.transformAcceptanceRate, 0.7, "Most transforms should be accepted")
    }

    func testWeekendOnlyUser() async {
        // User only works out on weekends
        let journey = await simulator.simulate(
            days: 60,
            completionRate: 0.90,
            excuseRate: 0.0,
            deleteRate: 0.0,
            weekendOnly: true
        )

        // Should still progress (Ghost adapts to pattern)
        XCTAssertTrue([.autoScheduler, .transformer, .fullGhost].contains(journey.finalPhase),
                      "Weekend-only user with high completion should progress")
    }

    // MARK: - Recovery Pattern Tests

    func testRecoveryBasedScheduling() async {
        // Simulate low recovery days
        let journey = await simulator.simulate(
            days: 60,
            completionRate: 0.75,
            excuseRate: 0.8,  // Low recovery = excused
            deleteRate: 0.0,
            lowRecoveryDays: [5, 12, 19, 26, 33, 40, 47, 54]  // Periodic low recovery
        )

        XCTAssertGreaterThan(journey.recoveryBasedSkips, 0, "Should have recovery-based skips")
        XCTAssertGreaterThanOrEqual(journey.finalConfidence, 0.5, "Recovery skips shouldn't tank trust")
    }
}

// MARK: - Ghost Simulator

actor GhostSimulator {

    private var trustMachine: TestableTrustStateMachine
    private var dayLog: [DaySimulation] = []

    init() async {
        trustMachine = await TestableTrustStateMachine()
    }

    struct SimulationResult {
        let finalPhase: TrustPhase
        let finalConfidence: Double
        let safetyBreakerTriggers: Int
        let trustBeforeVacation: Double
        let trustAfterVacation: Double
        let confidenceAtDay30: Double
        let transformsExecuted: Int
        let transformAcceptanceRate: Double
        let recoveryBasedSkips: Int
        let phaseHistory: [(day: Int, phase: TrustPhase)]
    }

    func simulate(
        days: Int,
        completionRate: Double,
        excuseRate: Double,
        deleteRate: Double,
        vacationPeriods: [(start: Int, end: Int)] = [],
        illnessPeriods: [(start: Int, end: Int)] = [],
        burstDeletes: [(day: Int, count: Int)] = [],
        conflictsPerWeek: Int = 0,
        weekendOnly: Bool = false,
        lowRecoveryDays: [Int] = []
    ) async -> SimulationResult {

        var safetyBreakerTriggers = 0
        var trustBeforeVacation = 0.0
        var trustAfterVacation = 0.0
        var confidenceAtDay30 = 0.0
        var transformsExecuted = 0
        var transformsAccepted = 0
        var recoveryBasedSkips = 0
        var phaseHistory: [(Int, TrustPhase)] = []

        for day in 1...days {
            // Record phase
            let phase = await trustMachine.currentPhase
            phaseHistory.append((day, phase))

            // Check special periods
            let isVacation = vacationPeriods.contains { $0.start <= day && day <= $0.end }
            let isIllness = illnessPeriods.contains { $0.start <= day && day <= $0.end }
            let isLowRecovery = lowRecoveryDays.contains(day)
            let isWeekend = (day % 7 == 6) || (day % 7 == 0)

            // Check burst deletes
            if let burst = burstDeletes.first(where: { $0.day == day }) {
                for _ in 0..<burst.count {
                    await trustMachine.handleEvent(.userDeletedBlock)
                    let newPhase = await trustMachine.currentPhase
                    if newPhase != phase {
                        safetyBreakerTriggers += 1
                    }
                }
                continue
            }

            // Track vacation
            if day == vacationPeriods.first?.start ?? -1 {
                trustBeforeVacation = await trustMachine.currentConfidence
            }
            if day == (vacationPeriods.first?.end ?? -1) + 1 {
                trustAfterVacation = await trustMachine.currentConfidence
            }

            // Skip workouts on vacation/illness/weekend-only
            if isVacation {
                await trustMachine.handleEvent(.missedWorkout(.travelMode))
                continue
            }

            if isIllness {
                await trustMachine.handleEvent(.missedWorkout(.illness))
                continue
            }

            if weekendOnly && !isWeekend {
                continue  // No workout scheduled
            }

            if isLowRecovery {
                await trustMachine.handleEvent(.missedWorkout(.poorRecovery))
                recoveryBasedSkips += 1
                continue
            }

            // Simulate transforms
            if conflictsPerWeek > 0 && day % (7 / conflictsPerWeek) == 0 {
                transformsExecuted += 1
                if Double.random(in: 0...1) < 0.8 {
                    transformsAccepted += 1
                    await trustMachine.handleEvent(.transformedScheduleAccepted)
                }
            }

            // Simulate delete
            if Double.random(in: 0...1) < deleteRate {
                await trustMachine.handleEvent(.userDeletedBlock)
                continue
            }

            // Simulate completion
            if Double.random(in: 0...1) < completionRate {
                await trustMachine.handleEvent(.completedWorkout)
            } else {
                // Missed - with or without excuse
                if Double.random(in: 0...1) < excuseRate {
                    await trustMachine.handleEvent(.missedWorkout(.calendarConflict))
                } else {
                    await trustMachine.handleEvent(.missedWorkout(.noReason))
                }
            }

            // Capture day 30 confidence
            if day == 30 {
                confidenceAtDay30 = await trustMachine.currentConfidence
            }
        }

        return SimulationResult(
            finalPhase: await trustMachine.currentPhase,
            finalConfidence: await trustMachine.currentConfidence,
            safetyBreakerTriggers: safetyBreakerTriggers,
            trustBeforeVacation: trustBeforeVacation,
            trustAfterVacation: trustAfterVacation,
            confidenceAtDay30: confidenceAtDay30,
            transformsExecuted: transformsExecuted,
            transformAcceptanceRate: transformsExecuted > 0 ? Double(transformsAccepted) / Double(transformsExecuted) : 1.0,
            recoveryBasedSkips: recoveryBasedSkips,
            phaseHistory: phaseHistory
        )
    }
}

struct DaySimulation {
    let day: Int
    let phase: TrustPhase
    let confidence: Double
    let events: [TrustEvent]
}
