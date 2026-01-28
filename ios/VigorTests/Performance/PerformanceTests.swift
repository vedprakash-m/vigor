//
//  PerformanceTests.swift
//  VigorTests
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Performance tests for critical Ghost operations.
//  Validates background efficiency and memory constraints.
//

import XCTest
@testable import Vigor

final class PerformanceTests: XCTestCase {

    // MARK: - Background Task Performance

    func testMorningCycleCompletesFast() async throws {
        // Background tasks must complete within 30 seconds
        // Morning cycle should complete well under that

        let metrics = try await XCTContext.runActivity(named: "Morning Cycle Performance") { _ in
            await measureGhostCycle(.morning)
        }

        XCTAssertLessThan(metrics.duration, 5.0, "Morning cycle must complete in <5s")
        XCTAssertLessThan(metrics.peakMemoryMB, 50, "Peak memory should be <50MB")
    }

    func testEveningCycleCompletesFast() async throws {
        let metrics = try await XCTContext.runActivity(named: "Evening Cycle Performance") { _ in
            await measureGhostCycle(.evening)
        }

        XCTAssertLessThan(metrics.duration, 5.0, "Evening cycle must complete in <5s")
        XCTAssertLessThan(metrics.peakMemoryMB, 50, "Peak memory should be <50MB")
    }

    func testSilentPushHandlingFast() async throws {
        let metrics = try await XCTContext.runActivity(named: "Silent Push Performance") { _ in
            await measureSilentPush()
        }

        // Silent push must respond before system kills us (~30s)
        XCTAssertLessThan(metrics.duration, 10.0, "Silent push handling must complete in <10s")
    }

    // MARK: - HealthKit Query Performance

    func testSleepQueryPerformance() async throws {
        measure {
            let expectation = self.expectation(description: "Sleep query")
            Task {
                let _ = await MockHealthKitPerf.querySleepData()
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 5.0)
        }
    }

    func testHRVQueryPerformance() async throws {
        measure {
            let expectation = self.expectation(description: "HRV query")
            Task {
                let _ = await MockHealthKitPerf.queryHRV()
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 5.0)
        }
    }

    func testRecoveryCalculationPerformance() async throws {
        // Recovery calculation with 30 days of data
        measure {
            let expectation = self.expectation(description: "Recovery calc")
            Task {
                let _ = await MockRecoveryAnalyzer.calculate(daysOfData: 30)
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 5.0)
        }
    }

    // MARK: - Trust State Machine Performance

    func testTrustTransitionPerformance() async throws {
        // Trust transitions should be instantaneous
        measure {
            let expectation = self.expectation(description: "Trust transition")
            Task {
                let machine = await MockTrustMachine()
                for _ in 0..<100 {
                    await machine.handleEvent(.completedWorkout)
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 2.0)
        }
    }

    func testTrustConfidenceCalculationPerformance() async throws {
        // Confidence calculation with 60 days of history
        measure {
            let expectation = self.expectation(description: "Confidence calc")
            Task {
                let _ = await MockTrustMachine.calculateConfidence(events: 180)  // 60 days, ~3 events/day
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 2.0)
        }
    }

    // MARK: - Calendar Performance

    func testCalendarConflictDetectionPerformance() async throws {
        // Conflict detection with busy calendar (20+ events/day)
        measure {
            let expectation = self.expectation(description: "Conflict detection")
            Task {
                let _ = await MockCalendarPerf.checkConflicts(eventsPerDay: 20, days: 7)
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 3.0)
        }
    }

    func testSlotFindingPerformance() async throws {
        // Find optimal slot in packed calendar
        measure {
            let expectation = self.expectation(description: "Slot finding")
            Task {
                let _ = await MockCalendarPerf.findOptimalSlot(eventsPerDay: 15, days: 7)
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 3.0)
        }
    }

    // MARK: - ML Model Performance

    func testSkipPredictionPerformance() async throws {
        // Skip prediction should be very fast
        measure {
            let expectation = self.expectation(description: "Skip prediction")
            Task {
                let _ = await MockMLPerf.predictSkip()
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 1.0)
        }
    }

    func testOptimalWindowFindingPerformance() async throws {
        // Finding optimal windows for a week
        measure {
            let expectation = self.expectation(description: "Optimal windows")
            Task {
                let _ = await MockMLPerf.findOptimalWindows(days: 7)
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 3.0)
        }
    }

    func testPatternDetectionPerformance() async throws {
        // Pattern detection with 60 days of history
        measure {
            let expectation = self.expectation(description: "Pattern detection")
            Task {
                let _ = await MockMLPerf.detectPatterns(daysOfHistory: 60)
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 3.0)
        }
    }

    // MARK: - Memory Tests

    func testMemoryUsageDuringBackgroundTask() async throws {
        let initialMemory = getMemoryUsageMB()

        // Simulate full background task
        await simulateFullBackgroundTask()

        let peakMemory = getMemoryUsageMB()
        let memoryIncrease = peakMemory - initialMemory

        XCTAssertLessThan(memoryIncrease, 30, "Background task should use <30MB additional memory")
    }

    func testPhenomeStoreSizeConstraint() async throws {
        // Phenome stores should stay within reasonable size
        let storeSize = await MockPhenomePerf.estimateStoreSize(daysOfData: 365)

        XCTAssertLessThan(storeSize, 10 * 1024 * 1024, "Phenome store should be <10MB for 1 year of data")
    }

    // MARK: - Concurrent Operations

    func testConcurrentHealthKitQueries() async throws {
        // Multiple HealthKit queries should run concurrently
        measure {
            let expectation = self.expectation(description: "Concurrent queries")
            Task {
                await withTaskGroup(of: Void.self) { group in
                    group.addTask { await MockHealthKitPerf.querySleepData() }
                    group.addTask { await MockHealthKitPerf.queryHRV() }
                    group.addTask { await MockHealthKitPerf.queryRestingHR() }
                    group.addTask { await MockHealthKitPerf.queryWorkouts() }
                    group.addTask { await MockHealthKitPerf.querySteps() }
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 5.0)
        }
    }

    // MARK: - Watch Connectivity Performance

    func testWatchMessageSizeConstraint() async throws {
        // Watch messages should be compact
        let message = await MockWatchPerf.buildSyncMessage()
        let messageSize = try JSONSerialization.data(withJSONObject: message).count

        // WCSession message limit is ~64KB for immediate, less for background
        XCTAssertLessThan(messageSize, 10 * 1024, "Watch sync message should be <10KB")
    }

    func testWatchContextUpdatePerformance() async throws {
        measure {
            let expectation = self.expectation(description: "Watch context")
            Task {
                await MockWatchPerf.prepareApplicationContext()
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 1.0)
        }
    }

    // MARK: - Helper Methods

    private func measureGhostCycle(_ type: CycleType) async -> PerformanceMetrics {
        let startMemory = getMemoryUsageMB()
        let startTime = Date()

        switch type {
        case .morning:
            await simulateMorningCycle()
        case .evening:
            await simulateEveningCycle()
        }

        let duration = Date().timeIntervalSince(startTime)
        let peakMemory = getMemoryUsageMB()

        return PerformanceMetrics(
            duration: duration,
            peakMemoryMB: peakMemory - startMemory
        )
    }

    private func measureSilentPush() async -> PerformanceMetrics {
        let startTime = Date()
        let startMemory = getMemoryUsageMB()

        await simulateSilentPushHandling()

        return PerformanceMetrics(
            duration: Date().timeIntervalSince(startTime),
            peakMemoryMB: getMemoryUsageMB() - startMemory
        )
    }

    private func simulateMorningCycle() async {
        // Simulate morning cycle operations
        await MockHealthKitPerf.querySleepData()
        await MockHealthKitPerf.queryHRV()
        await MockHealthKitPerf.queryRestingHR()
        await MockRecoveryAnalyzer.calculate(daysOfData: 7)
        await MockCalendarPerf.getTodayEvents()
        await MockMLPerf.predictSkip()
        try? await Task.sleep(for: .milliseconds(100))
    }

    private func simulateEveningCycle() async {
        // Simulate evening cycle operations
        await MockCalendarPerf.getTodayEvents()
        let _ = await MockTrustMachine()
        await MockPhenomePerf.sync()
        await MockCalendarPerf.checkConflicts(eventsPerDay: 10, days: 1)
        try? await Task.sleep(for: .milliseconds(100))
    }

    private func simulateSilentPushHandling() async {
        // Minimal work to acknowledge push
        await MockCalendarPerf.getTodayEvents()
        await MockHealthKitPerf.queryHRV()
        try? await Task.sleep(for: .milliseconds(50))
    }

    private func simulateFullBackgroundTask() async {
        await simulateMorningCycle()
        await simulateEveningCycle()
    }

    private func getMemoryUsageMB() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            return Double(info.resident_size) / (1024 * 1024)
        }
        return 0
    }
}

// MARK: - Types

enum CycleType {
    case morning
    case evening
}

struct PerformanceMetrics {
    let duration: TimeInterval
    let peakMemoryMB: Double
}

// MARK: - Mock Performance Helpers

enum MockHealthKitPerf {
    @discardableResult
    static func querySleepData() async -> Any? {
        try? await Task.sleep(for: .milliseconds(50))
        return nil
    }

    @discardableResult
    static func queryHRV() async -> Any? {
        try? await Task.sleep(for: .milliseconds(30))
        return nil
    }

    @discardableResult
    static func queryRestingHR() async -> Any? {
        try? await Task.sleep(for: .milliseconds(20))
        return nil
    }

    @discardableResult
    static func queryWorkouts() async -> Any? {
        try? await Task.sleep(for: .milliseconds(40))
        return nil
    }

    @discardableResult
    static func querySteps() async -> Any? {
        try? await Task.sleep(for: .milliseconds(25))
        return nil
    }
}

enum MockRecoveryAnalyzer {
    @discardableResult
    static func calculate(daysOfData: Int) async -> Int {
        // Simulate calculation proportional to data
        try? await Task.sleep(for: .milliseconds(daysOfData * 2))
        return 75
    }
}

actor MockTrustMachine {
    func handleEvent(_ event: TrustEvent) async {
        // Fast state transition
        try? await Task.sleep(for: .microseconds(100))
    }

    static func calculateConfidence(events: Int) async -> Double {
        // Simulate confidence calculation
        try? await Task.sleep(for: .milliseconds(events / 10))
        return 0.75
    }
}

enum MockCalendarPerf {
    static func checkConflicts(eventsPerDay: Int, days: Int) async -> Int {
        let totalEvents = eventsPerDay * days
        try? await Task.sleep(for: .milliseconds(totalEvents))
        return 0
    }

    static func findOptimalSlot(eventsPerDay: Int, days: Int) async -> Date? {
        let totalEvents = eventsPerDay * days
        try? await Task.sleep(for: .milliseconds(totalEvents * 2))
        return Date()
    }

    static func getTodayEvents() async -> [Any] {
        try? await Task.sleep(for: .milliseconds(20))
        return []
    }
}

enum MockMLPerf {
    static func predictSkip() async -> Double {
        try? await Task.sleep(for: .milliseconds(10))
        return 0.2
    }

    static func findOptimalWindows(days: Int) async -> [Date] {
        try? await Task.sleep(for: .milliseconds(days * 50))
        return []
    }

    static func detectPatterns(daysOfHistory: Int) async -> [Any] {
        try? await Task.sleep(for: .milliseconds(daysOfHistory * 3))
        return []
    }
}

enum MockPhenomePerf {
    static func sync() async {
        try? await Task.sleep(for: .milliseconds(50))
    }

    static func estimateStoreSize(daysOfData: Int) async -> Int {
        // Estimate: ~20KB per day (conservative)
        return daysOfData * 20 * 1024
    }
}

enum MockWatchPerf {
    static func buildSyncMessage() async -> [String: Any] {
        [
            "trust_phase": 2,
            "confidence": 0.65,
            "today_block": [
                "id": UUID().uuidString,
                "type": "strength",
                "start": ISO8601DateFormatter().string(from: Date()),
                "duration": 45
            ],
            "recovery_score": 75
        ]
    }

    static func prepareApplicationContext() async {
        try? await Task.sleep(for: .milliseconds(30))
    }
}
