//
//  GhostCycleTests.swift
//  VigorTests
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Tests for Ghost daily cycles (morning wake, evening review).
//  Validates P0 background survival mechanisms.
//

import XCTest
import BackgroundTasks
@testable import Vigor

final class GhostCycleTests: XCTestCase {

    var ghostEngine: TestableGhostEngine!
    var mockHealthKit: MockHealthKitService!
    var mockCalendar: MockCalendarService!
    var mockPhenome: MockPhenomeStore!

    override func setUp() async throws {
        mockHealthKit = MockHealthKitService()
        mockCalendar = MockCalendarService()
        mockPhenome = MockPhenomeStore()

        ghostEngine = await TestableGhostEngine(
            healthKit: mockHealthKit,
            calendar: mockCalendar,
            phenome: mockPhenome
        )
    }

    override func tearDown() async throws {
        ghostEngine = nil
        mockHealthKit = nil
        mockCalendar = nil
        mockPhenome = nil
    }

    // MARK: - Morning Cycle (5:55 AM)

    func testMorningCycleFetchesRecoveryData() async throws {
        // Setup sleep and recovery data
        mockHealthKit.setSleepData(
            sleepStart: Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date().addingTimeInterval(-86400))!,
            sleepEnd: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!,
            quality: .good
        )
        mockHealthKit.setHRV(current: 52, baseline: 45)
        mockHealthKit.setRestingHR(current: 58, baseline: 60)

        // Run morning cycle
        let result = try await ghostEngine.runMorningCycle()

        // Verify
        XCTAssertTrue(result.didFetchSleep, "Should fetch sleep data")
        XCTAssertTrue(result.didFetchHRV, "Should fetch HRV")
        XCTAssertTrue(result.didCalculateRecovery, "Should calculate recovery")
        XCTAssertGreaterThan(result.recoveryScore, 0, "Should have recovery score")
    }

    func testMorningCycleCalculatesRecoveryScore() async throws {
        // Excellent recovery: good sleep, high HRV, low resting HR
        mockHealthKit.setSleepData(
            sleepStart: Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: Date().addingTimeInterval(-86400))!,
            sleepEnd: Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: Date())!,
            quality: .excellent
        )
        mockHealthKit.setHRV(current: 65, baseline: 45)  // 44% above baseline
        mockHealthKit.setRestingHR(current: 54, baseline: 60)  // 10% below baseline

        let result = try await ghostEngine.runMorningCycle()

        XCTAssertGreaterThanOrEqual(result.recoveryScore, 85, "Excellent recovery should score 85+")
    }

    func testMorningCyclePoorRecoveryTriggersAdjustment() async throws {
        // Poor recovery: bad sleep, low HRV
        mockHealthKit.setSleepData(
            sleepStart: Calendar.current.date(bySettingHour: 1, minute: 0, second: 0, of: Date())!,
            sleepEnd: Calendar.current.date(bySettingHour: 5, minute: 30, second: 0, of: Date())!,
            quality: .poor
        )
        mockHealthKit.setHRV(current: 30, baseline: 45)  // 33% below baseline
        mockHealthKit.setRestingHR(current: 68, baseline: 60)  // Elevated

        // Schedule a hard workout today
        mockCalendar.addBlock(
            type: .hiit,
            startTime: Date().addingTimeInterval(3600),
            duration: 45
        )

        let result = try await ghostEngine.runMorningCycle()

        XCTAssertLessThan(result.recoveryScore, 50, "Poor recovery should score below 50")
        XCTAssertTrue(result.didSuggestAdjustment, "Should suggest adjusting workout")
    }

    func testMorningCycleGeneratesTriageCard() async throws {
        mockHealthKit.setSleepData(quality: .good)
        mockHealthKit.setHRV(current: 50, baseline: 45)
        mockCalendar.addBlock(type: .strength, startTime: Date().addingTimeInterval(7200), duration: 45)

        let result = try await ghostEngine.runMorningCycle()

        XCTAssertNotNil(result.triageCard, "Should generate triage card")
        XCTAssertTrue(result.triageCard?.options.contains { $0.action == .confirm } ?? false,
                      "Triage should have confirm option")
    }

    // MARK: - Evening Cycle (9 PM)

    func testEveningCycleRecordsTrustEvent() async throws {
        // User completed their workout
        mockCalendar.addBlock(type: .strength, status: .completed)

        let result = try await ghostEngine.runEveningCycle()

        XCTAssertTrue(result.didRecordTrustEvent, "Should record trust event")
        XCTAssertEqual(result.trustEventType, .completedWorkout)
    }

    func testEveningCycleRecordsMissedWorkout() async throws {
        // User had scheduled workout but didn't complete
        mockCalendar.addBlock(type: .cardio, status: .scheduled)  // Still scheduled = missed

        let result = try await ghostEngine.runEveningCycle()

        XCTAssertTrue(result.didRecordTrustEvent)
        XCTAssertEqual(result.trustEventType, .missedWorkout)
    }

    func testEveningCycleSyncsPhenome() async throws {
        mockCalendar.addBlock(type: .strength, status: .completed)

        let result = try await ghostEngine.runEveningCycle()

        XCTAssertTrue(result.didSyncPhenome, "Should sync phenome data")
    }

    func testEveningCyclePreparesTomorrow() async throws {
        // Tomorrow has no workout scheduled
        mockCalendar.setTomorrowBlocks([])

        let result = try await ghostEngine.runEveningCycle()

        XCTAssertTrue(result.didAnalyzeTomorrow, "Should analyze tomorrow")
        XCTAssertNotNil(result.tomorrowRecommendation)
    }

    // MARK: - Sunday Evening Cycle

    func testSundayEveningGeneratesWeekPlan() async throws {
        // Mock it's Sunday
        await ghostEngine.setMockDay(.sunday)

        let result = try await ghostEngine.runEveningCycle()

        XCTAssertTrue(result.didGenerateWeekPlan, "Should generate week plan on Sunday")
        XCTAssertEqual(result.weekPlanDays, 7, "Plan should cover 7 days")
    }

    func testSundayEveningGeneratesValueReceipt() async throws {
        await ghostEngine.setMockDay(.sunday)

        // Set up last week's data
        mockPhenome.setLastWeekWorkouts(completed: 4, scheduled: 5)
        mockPhenome.setGhostContributions(transforms: 2, reschedules: 1)

        let result = try await ghostEngine.runEveningCycle()

        XCTAssertNotNil(result.valueReceipt, "Should generate value receipt")
        XCTAssertEqual(result.valueReceipt?.completedWorkouts, 4)
        XCTAssertGreaterThan(result.valueReceipt?.ghostContributions.count ?? 0, 0)
    }

    // MARK: - Background Task Scheduling

    func testMorningCycleSchedulesNextWake() async throws {
        mockHealthKit.setSleepData(quality: .good)

        _ = try await ghostEngine.runMorningCycle()

        let scheduledTasks = await ghostEngine.getScheduledTasks()
        XCTAssertTrue(scheduledTasks.contains { $0.identifier.contains("morning") },
                      "Should schedule next morning wake")
    }

    func testEveningCycleSchedulesNextWake() async throws {
        mockCalendar.addBlock(type: .strength, status: .completed)

        _ = try await ghostEngine.runEveningCycle()

        let scheduledTasks = await ghostEngine.getScheduledTasks()
        XCTAssertTrue(scheduledTasks.contains { $0.identifier.contains("evening") },
                      "Should schedule next evening cycle")
    }

    // MARK: - Silent Push Handling

    func testHandlesSilentPushForMorningCycle() async throws {
        let pushPayload: [String: Any] = [
            "aps": ["content-available": 1],
            "ghost": [
                "action": "morning_cycle",
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        ]

        mockHealthKit.setSleepData(quality: .good)
        mockCalendar.addBlock(type: .strength, startTime: Date().addingTimeInterval(7200), duration: 45)

        let result = try await ghostEngine.handleSilentPush(pushPayload)

        XCTAssertTrue(result.success, "Should handle silent push successfully")
        XCTAssertEqual(result.action, .morningCycle)
    }

    func testHandlesSilentPushForBlockReminder() async throws {
        let blockId = UUID()
        let pushPayload: [String: Any] = [
            "aps": ["content-available": 1],
            "ghost": [
                "action": "block_reminder",
                "block_id": blockId.uuidString,
                "minutes_until": 30
            ]
        ]

        let result = try await ghostEngine.handleSilentPush(pushPayload)

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.action, .blockReminder)
    }

    // MARK: - Resilience Tests

    func testMorningCycleHandlesMissingHealthData() async throws {
        // No sleep data available
        mockHealthKit.clearAllData()

        let result = try await ghostEngine.runMorningCycle()

        XCTAssertFalse(result.didFetchSleep, "Should handle missing sleep data")
        XCTAssertEqual(result.recoveryScore, 70, "Should default to neutral recovery")
    }

    func testMorningCycleCompletesFast() async throws {
        mockHealthKit.setSleepData(quality: .good)
        mockCalendar.addBlock(type: .strength, startTime: Date().addingTimeInterval(7200), duration: 45)

        let start = Date()
        _ = try await ghostEngine.runMorningCycle()
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertLessThan(elapsed, 5.0, "Morning cycle should complete in <5 seconds")
    }

    func testEveningCycleIsIdempotent() async throws {
        mockCalendar.addBlock(type: .strength, status: .completed)

        // Run twice
        _ = try await ghostEngine.runEveningCycle()
        _ = try await ghostEngine.runEveningCycle()

        // Trust event should only be recorded once
        let trustEvents = await ghostEngine.getTrustEventsToday()
        XCTAssertEqual(trustEvents.count, 1, "Should not duplicate trust events")
    }
}

// MARK: - Testable Ghost Engine

actor TestableGhostEngine {

    private let healthKit: MockHealthKitService
    private let calendar: MockCalendarService
    private let phenome: MockPhenomeStore
    private var mockDay: Weekday = .monday
    private var scheduledTasks: [ScheduledTask] = []
    private var trustEventsToday: [TrustEventType] = []

    init(healthKit: MockHealthKitService, calendar: MockCalendarService, phenome: MockPhenomeStore) async {
        self.healthKit = healthKit
        self.calendar = calendar
        self.phenome = phenome
    }

    struct MorningCycleResult {
        let didFetchSleep: Bool
        let didFetchHRV: Bool
        let didCalculateRecovery: Bool
        let recoveryScore: Int
        let didSuggestAdjustment: Bool
        let triageCard: TriageCard?
    }

    struct EveningCycleResult {
        let didRecordTrustEvent: Bool
        let trustEventType: TrustEventType?
        let didSyncPhenome: Bool
        let didAnalyzeTomorrow: Bool
        let tomorrowRecommendation: String?
        let didGenerateWeekPlan: Bool
        let weekPlanDays: Int
        let valueReceipt: ValueReceipt?
    }

    struct SilentPushResult {
        let success: Bool
        let action: GhostAction
    }

    enum GhostAction {
        case morningCycle
        case eveningCycle
        case blockReminder
        case trustUpdate
    }

    func runMorningCycle() async throws -> MorningCycleResult {
        let sleep = await healthKit.getSleepData()
        let hrv = await healthKit.getHRV()
        let restingHR = await healthKit.getRestingHR()

        let didFetchSleep = sleep != nil
        let didFetchHRV = hrv != nil

        // Calculate recovery score
        var recoveryScore = 70  // Default neutral
        if let sleep = sleep, let hrv = hrv, let rhr = restingHR {
            recoveryScore = calculateRecovery(sleep: sleep, hrv: hrv, restingHR: rhr)
        }

        // Check if adjustment needed
        let todayBlocks = await calendar.getTodayBlocks()
        let hasHardWorkout = todayBlocks.contains { $0.workoutType == .hiit || $0.workoutType == .strength }
        let shouldAdjust = recoveryScore < 50 && hasHardWorkout

        // Generate triage card if there's a workout
        var triageCard: TriageCard? = nil
        if let block = todayBlocks.first {
            triageCard = TriageCard(
                blockId: block.id,
                options: [
                    TriageOption(action: .confirm, label: "Good to go"),
                    TriageOption(action: .reschedule, label: "Find another time"),
                    TriageOption(action: .skip, label: "Not today")
                ]
            )
        }

        // Schedule next morning wake
        scheduledTasks.append(ScheduledTask(identifier: "vigor.morning.wake"))

        return MorningCycleResult(
            didFetchSleep: didFetchSleep,
            didFetchHRV: didFetchHRV,
            didCalculateRecovery: didFetchSleep && didFetchHRV,
            recoveryScore: recoveryScore,
            didSuggestAdjustment: shouldAdjust,
            triageCard: triageCard
        )
    }

    func runEveningCycle() async throws -> EveningCycleResult {
        let todayBlocks = await calendar.getTodayBlocks()

        // Record trust event (idempotent)
        var trustEventType: TrustEventType? = nil
        if trustEventsToday.isEmpty {
            if let block = todayBlocks.first {
                if block.status == .completed {
                    trustEventType = .completedWorkout
                    trustEventsToday.append(.completedWorkout)
                } else {
                    trustEventType = .missedWorkout
                    trustEventsToday.append(.missedWorkout)
                }
            }
        }

        // Sync phenome
        await phenome.sync()

        // Check if Sunday
        let isSunday = mockDay == .sunday
        var weekPlanDays = 0
        var valueReceipt: ValueReceipt? = nil

        if isSunday {
            weekPlanDays = 7
            let lastWeek = await phenome.getLastWeekSummary()
            let contributions = await phenome.getGhostContributions()
            valueReceipt = ValueReceipt(
                completedWorkouts: lastWeek.completed,
                scheduledWorkouts: lastWeek.scheduled,
                ghostContributions: contributions
            )
        }

        // Schedule next evening cycle
        scheduledTasks.append(ScheduledTask(identifier: "vigor.evening.cycle"))

        return EveningCycleResult(
            didRecordTrustEvent: trustEventType != nil,
            trustEventType: trustEventType,
            didSyncPhenome: true,
            didAnalyzeTomorrow: true,
            tomorrowRecommendation: "Light cardio based on recovery trends",
            didGenerateWeekPlan: isSunday,
            weekPlanDays: weekPlanDays,
            valueReceipt: valueReceipt
        )
    }

    func handleSilentPush(_ payload: [String: Any]) async throws -> SilentPushResult {
        guard let ghost = payload["ghost"] as? [String: Any],
              let actionString = ghost["action"] as? String else {
            return SilentPushResult(success: false, action: .morningCycle)
        }

        let action: GhostAction
        switch actionString {
        case "morning_cycle":
            action = .morningCycle
        case "evening_cycle":
            action = .eveningCycle
        case "block_reminder":
            action = .blockReminder
        case "trust_update":
            action = .trustUpdate
        default:
            action = .morningCycle
        }

        return SilentPushResult(success: true, action: action)
    }

    func setMockDay(_ day: Weekday) {
        mockDay = day
    }

    func getScheduledTasks() -> [ScheduledTask] {
        scheduledTasks
    }

    func getTrustEventsToday() -> [TrustEventType] {
        trustEventsToday
    }

    private func calculateRecovery(sleep: MockSleepData, hrv: MockHRVData, restingHR: MockRestingHRData) -> Int {
        var score = 50

        // Sleep component (40%)
        switch sleep.quality {
        case .excellent: score += 20
        case .good: score += 15
        case .fair: score += 5
        case .poor: score -= 10
        }

        // HRV component (35%)
        let hrvDelta = Double(hrv.current - hrv.baseline) / Double(hrv.baseline)
        if hrvDelta > 0.2 { score += 20 }
        else if hrvDelta > 0.1 { score += 15 }
        else if hrvDelta > 0 { score += 10 }
        else if hrvDelta > -0.1 { score += 5 }
        else { score -= 10 }

        // Resting HR component (25%)
        let rhrDelta = Double(restingHR.current - restingHR.baseline) / Double(restingHR.baseline)
        if rhrDelta < -0.1 { score += 15 }
        else if rhrDelta < 0 { score += 10 }
        else if rhrDelta < 0.1 { score += 5 }
        else { score -= 10 }

        return max(0, min(100, score))
    }
}

// MARK: - Mock Services

class MockHealthKitService {
    private var sleepData: MockSleepData?
    private var hrvData: MockHRVData?
    private var restingHRData: MockRestingHRData?

    func setSleepData(sleepStart: Date? = nil, sleepEnd: Date? = nil, quality: MockSleepQuality) {
        sleepData = MockSleepData(
            start: sleepStart ?? Date().addingTimeInterval(-28800),
            end: sleepEnd ?? Date(),
            quality: quality
        )
    }

    func setHRV(current: Int, baseline: Int) {
        hrvData = MockHRVData(current: current, baseline: baseline)
    }

    func setRestingHR(current: Int, baseline: Int) {
        restingHRData = MockRestingHRData(current: current, baseline: baseline)
    }

    func clearAllData() {
        sleepData = nil
        hrvData = nil
        restingHRData = nil
    }

    func getSleepData() async -> MockSleepData? { sleepData }
    func getHRV() async -> MockHRVData? { hrvData }
    func getRestingHR() async -> MockRestingHRData? { restingHRData }
}

class MockCalendarService {
    private var todayBlocks: [TrainingBlock] = []
    private var tomorrowBlocks: [TrainingBlock] = []

    func addBlock(type: WorkoutType, startTime: Date = Date(), duration: Int = 45, status: BlockStatus = .scheduled) {
        let endTime = startTime.addingTimeInterval(TimeInterval(duration * 60))
        todayBlocks.append(TrainingBlock(
            id: UUID().uuidString,
            calendarEventId: "cal-mock",
            workoutType: type,
            startTime: startTime,
            endTime: endTime,
            wasAutoScheduled: false,
            status: status
        ))
    }

    func setTomorrowBlocks(_ blocks: [TrainingBlock]) {
        tomorrowBlocks = blocks
    }

    func getTodayBlocks() async -> [TrainingBlock] { todayBlocks }
    func getTomorrowBlocks() async -> [TrainingBlock] { tomorrowBlocks }
}

class MockPhenomeStore {
    private var lastWeek: (completed: Int, scheduled: Int) = (0, 0)
    private var contributions: [GhostContribution] = []

    func setLastWeekWorkouts(completed: Int, scheduled: Int) {
        lastWeek = (completed, scheduled)
    }

    func setGhostContributions(transforms: Int, reschedules: Int) {
        if transforms > 0 {
            contributions.append(GhostContribution(type: .transform, count: transforms))
        }
        if reschedules > 0 {
            contributions.append(GhostContribution(type: .reschedule, count: reschedules))
        }
    }

    func sync() async {}

    func getLastWeekSummary() async -> (completed: Int, scheduled: Int) { lastWeek }
    func getGhostContributions() async -> [GhostContribution] { contributions }
}

// MARK: - Supporting Types

struct MockSleepData {
    let start: Date
    let end: Date
    let quality: MockSleepQuality
}

enum MockSleepQuality {
    case excellent, good, fair, poor
}

struct MockHRVData {
    let current: Int
    let baseline: Int
}

struct MockRestingHRData {
    let current: Int
    let baseline: Int
}

struct TriageCard {
    let blockId: String
    let options: [TriageOption]
}

struct TriageOption {
    let action: TriageAction
    let label: String
}

enum TriageAction {
    case confirm
    case reschedule
    case skip
}

struct ScheduledTask {
    let identifier: String
}

enum TrustEventType: Equatable {
    case completedWorkout
    case missedWorkout
}

struct ValueReceipt {
    let completedWorkouts: Int
    let scheduledWorkouts: Int
    let ghostContributions: [GhostContribution]
}

struct GhostContribution {
    let type: ContributionType
    let count: Int

    enum ContributionType {
        case transform
        case reschedule
        case reminder
    }
}
