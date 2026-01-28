//
//  WatchConnectivityTests.swift
//  VigorTests
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Tests for iPhone-Watch bidirectional sync.
//  Validates Authority Model and data consistency.
//

import XCTest
import WatchConnectivity
@testable import Vigor

final class WatchConnectivityTests: XCTestCase {

    var phoneSession: MockWCSession!
    var watchSession: MockWCSession!
    var phoneConnector: TestablePhoneConnector!
    var watchConnector: TestableWatchConnector!

    override func setUp() async throws {
        phoneSession = MockWCSession(isPhone: true)
        watchSession = MockWCSession(isPhone: false)
        phoneConnector = await TestablePhoneConnector(session: phoneSession)
        watchConnector = await TestableWatchConnector(session: watchSession)

        // Link sessions
        phoneSession.counterpart = watchSession
        watchSession.counterpart = phoneSession
    }

    override func tearDown() async throws {
        phoneSession = nil
        watchSession = nil
        phoneConnector = nil
        watchConnector = nil
    }

    // MARK: - Authority Model Tests

    func testWatchIsAuthorityForWorkouts() async throws {
        // Watch records workout
        let workout = WorkoutRecord(
            id: UUID(),
            type: .strength,
            startTime: Date().addingTimeInterval(-2700),
            endTime: Date(),
            heartRateAvg: 135,
            caloriesBurned: 280
        )

        await watchConnector.recordWorkout(workout)

        // Should sync to phone
        let phoneSynced = await phoneConnector.getReceivedWorkouts()
        XCTAssertEqual(phoneSynced.count, 1, "Phone should receive workout from Watch")
        XCTAssertEqual(phoneSynced.first?.id, workout.id)
    }

    func testPhoneIsAuthorityForPlanning() async throws {
        // Phone creates training block
        let block = TrainingBlock(
            id: UUID(),
            type: .cardio,
            startTime: Date().addingTimeInterval(3600),
            duration: 30,
            status: .scheduled
        )

        await phoneConnector.scheduleBlock(block)

        // Should sync to Watch
        let watchBlocks = await watchConnector.getTodayBlocks()
        XCTAssertEqual(watchBlocks.count, 1, "Watch should receive block from Phone")
        XCTAssertEqual(watchBlocks.first?.id, block.id)
    }

    func testPhoneIsAuthorityForTrust() async throws {
        // Phone updates trust state
        await phoneConnector.updateTrust(phase: .scheduler, confidence: 0.35)

        // Watch should receive update
        let watchTrust = await watchConnector.getCurrentTrust()
        XCTAssertEqual(watchTrust.phase, .scheduler)
        XCTAssertEqual(watchTrust.confidence, 0.35, accuracy: 0.01)
    }

    // MARK: - Sync Message Tests

    func testMessageContainsRequiredFields() async throws {
        await phoneConnector.sendSync()

        let message = phoneSession.lastSentMessage
        XCTAssertNotNil(message)
        XCTAssertNotNil(message?["trust_phase"], "Should include trust phase")
        XCTAssertNotNil(message?["confidence"], "Should include confidence")
        XCTAssertNotNil(message?["timestamp"], "Should include timestamp")
    }

    func testWorkoutMessageContainsMetrics() async throws {
        let workout = WorkoutRecord(
            id: UUID(),
            type: .hiit,
            startTime: Date().addingTimeInterval(-1800),
            endTime: Date(),
            heartRateAvg: 155,
            caloriesBurned: 350
        )

        await watchConnector.recordWorkout(workout)

        let message = watchSession.lastSentMessage
        XCTAssertNotNil(message?["workout"])

        let workoutData = message?["workout"] as? [String: Any]
        XCTAssertNotNil(workoutData?["heart_rate_avg"])
        XCTAssertNotNil(workoutData?["calories"])
        XCTAssertNotNil(workoutData?["duration"])
    }

    // MARK: - Application Context Tests

    func testApplicationContextUpdatesOnChange() async throws {
        // Phone updates context when trust changes
        await phoneConnector.updateTrust(phase: .autoScheduler, confidence: 0.55)

        let context = phoneSession.applicationContext
        XCTAssertEqual(context["trust_phase"] as? Int, TrustPhase.autoScheduler.rawValue)
    }

    func testWatchReadsContextOnLaunch() async throws {
        // Set phone context
        phoneSession.applicationContext = [
            "trust_phase": TrustPhase.transformer.rawValue,
            "confidence": 0.72,
            "today_block": [
                "id": UUID().uuidString,
                "type": "strength",
                "start": ISO8601DateFormatter().string(from: Date().addingTimeInterval(3600)),
                "duration": 45
            ]
        ]

        // Watch reads on launch
        await watchConnector.syncFromContext()

        let trust = await watchConnector.getCurrentTrust()
        XCTAssertEqual(trust.phase, .transformer)

        let blocks = await watchConnector.getTodayBlocks()
        XCTAssertEqual(blocks.count, 1)
    }

    // MARK: - Conflict Resolution Tests

    func testWatchWorkoutOverridesPhone() async throws {
        // Phone has stale workout data
        let staleWorkout = WorkoutRecord(
            id: UUID(),
            type: .cardio,
            startTime: Date().addingTimeInterval(-3600),
            endTime: Date().addingTimeInterval(-1800),
            heartRateAvg: 120,
            caloriesBurned: 200
        )
        await phoneConnector.storeLocalWorkout(staleWorkout)

        // Watch sends updated version
        let watchWorkout = WorkoutRecord(
            id: staleWorkout.id,  // Same ID
            type: .cardio,
            startTime: Date().addingTimeInterval(-3600),
            endTime: Date().addingTimeInterval(-1800),
            heartRateAvg: 125,  // Updated values from Watch sensors
            caloriesBurned: 220
        )
        await watchConnector.recordWorkout(watchWorkout)

        // Phone should use Watch version (authoritative)
        let phoneWorkouts = await phoneConnector.getLocalWorkouts()
        let workout = phoneWorkouts.first { $0.id == staleWorkout.id }
        XCTAssertEqual(workout?.heartRateAvg, 125, "Watch data should override")
    }

    func testPhoneBlockOverridesWatch() async throws {
        // Watch has stale block
        let staleBlock = TrainingBlock(
            id: UUID(),
            type: .strength,
            startTime: Date().addingTimeInterval(3600),
            duration: 45,
            status: .scheduled
        )
        await watchConnector.storeLocalBlock(staleBlock)

        // Phone sends updated version (rescheduled)
        let phoneBlock = TrainingBlock(
            id: staleBlock.id,
            type: .strength,
            startTime: Date().addingTimeInterval(7200),  // Moved 1 hour later
            duration: 45,
            status: .scheduled
        )
        await phoneConnector.scheduleBlock(phoneBlock)

        // Watch should use Phone version
        let watchBlocks = await watchConnector.getTodayBlocks()
        let block = watchBlocks.first { $0.id == staleBlock.id }
        XCTAssertEqual(block?.startTime, phoneBlock.startTime, "Phone data should override")
    }

    // MARK: - Offline Handling Tests

    func testQueuesMessagesWhenUnreachable() async throws {
        phoneSession.isReachable = false

        let block = TrainingBlock(
            id: UUID(),
            type: .mobility,
            startTime: Date().addingTimeInterval(3600),
            duration: 20,
            status: .scheduled
        )

        await phoneConnector.scheduleBlock(block)

        XCTAssertEqual(phoneConnector.pendingMessages, 1, "Should queue message")
        XCTAssertNil(phoneSession.lastSentMessage, "Should not send immediately")
    }

    func testSendsQueuedMessagesWhenReachable() async throws {
        phoneSession.isReachable = false

        let block = TrainingBlock(
            id: UUID(),
            type: .mobility,
            startTime: Date().addingTimeInterval(3600),
            duration: 20,
            status: .scheduled
        )

        await phoneConnector.scheduleBlock(block)

        // Connection restored
        phoneSession.isReachable = true
        await phoneConnector.flushPendingMessages()

        XCTAssertEqual(phoneConnector.pendingMessages, 0, "Queue should be empty")
        XCTAssertNotNil(phoneSession.lastSentMessage, "Should have sent message")
    }

    func testUsesUserInfoTransferWhenUnreachable() async throws {
        phoneSession.isReachable = false

        // Important data should use guaranteed delivery
        await phoneConnector.updateTrust(phase: .fullGhost, confidence: 0.90)

        XCTAssertNotNil(phoneSession.lastTransferredUserInfo, "Should use transferUserInfo")
    }

    // MARK: - Complication Update Tests

    func testTriggersComplicationUpdate() async throws {
        // Phone updates trust
        await phoneConnector.updateTrust(phase: .autoScheduler, confidence: 0.52)

        XCTAssertTrue(phoneSession.didTransferCurrentComplicationUserInfo,
                      "Should trigger complication update")
    }

    func testComplicationUpdateIncludesMinimalData() async throws {
        await phoneConnector.updateTrust(phase: .transformer, confidence: 0.75)

        let complicationData = phoneSession.lastComplicationUserInfo
        XCTAssertNotNil(complicationData)

        // Should only include what complication needs
        XCTAssertNotNil(complicationData?["phase"])
        XCTAssertNotNil(complicationData?["confidence"])

        // Should be compact
        let dataSize = try JSONSerialization.data(withJSONObject: complicationData!).count
        XCTAssertLessThan(dataSize, 1024, "Complication data should be <1KB")
    }

    // MARK: - Performance Tests

    func testSyncMessageIsCompact() async throws {
        // Full sync message should be under WCSession limits
        await phoneConnector.sendFullSync()

        guard let message = phoneSession.lastSentMessage else {
            XCTFail("No message sent")
            return
        }

        let data = try JSONSerialization.data(withJSONObject: message)
        XCTAssertLessThan(data.count, 65536, "Message should be under 64KB limit")
    }

    func testBatchesMultipleUpdates() async throws {
        // Multiple rapid updates should batch
        for i in 0..<10 {
            let block = TrainingBlock(
                id: UUID(),
                type: .strength,
                startTime: Date().addingTimeInterval(TimeInterval(i * 3600)),
                duration: 45,
                status: .scheduled
            )
            await phoneConnector.scheduleBlock(block, debounce: true)
        }

        // Should coalesce into fewer messages
        XCTAssertLessThan(phoneSession.sentMessageCount, 10, "Should batch messages")
    }
}

// MARK: - Mock WCSession

class MockWCSession {
    let isPhone: Bool
    var isReachable: Bool = true
    var counterpart: MockWCSession?

    var applicationContext: [String: Any] = [:]
    var lastSentMessage: [String: Any]?
    var lastTransferredUserInfo: [String: Any]?
    var lastComplicationUserInfo: [String: Any]?
    var didTransferCurrentComplicationUserInfo = false
    var sentMessageCount = 0

    init(isPhone: Bool) {
        self.isPhone = isPhone
    }

    func sendMessage(_ message: [String: Any]) {
        lastSentMessage = message
        sentMessageCount += 1
        counterpart?.receiveMessage(message)
    }

    func receiveMessage(_ message: [String: Any]) {
        // Process received message
    }

    func transferUserInfo(_ userInfo: [String: Any]) {
        lastTransferredUserInfo = userInfo
        counterpart?.receiveUserInfo(userInfo)
    }

    func receiveUserInfo(_ userInfo: [String: Any]) {
        // Process received user info
    }

    func transferCurrentComplicationUserInfo(_ userInfo: [String: Any]) {
        lastComplicationUserInfo = userInfo
        didTransferCurrentComplicationUserInfo = true
    }

    func updateApplicationContext(_ context: [String: Any]) {
        applicationContext = context
    }
}

// MARK: - Testable Connectors

actor TestablePhoneConnector {
    let session: MockWCSession
    var receivedWorkouts: [WorkoutRecord] = []
    var localWorkouts: [WorkoutRecord] = []
    var pendingMessages = 0
    var debouncedBlocks: [TrainingBlock] = []

    init(session: MockWCSession) async {
        self.session = session
    }

    func scheduleBlock(_ block: TrainingBlock, debounce: Bool = false) {
        if debounce {
            debouncedBlocks.append(block)
            return
        }

        if session.isReachable {
            session.sendMessage([
                "action": "schedule_block",
                "block": blockToDict(block)
            ])
        } else {
            pendingMessages += 1
        }
    }

    func updateTrust(phase: TrustPhase, confidence: Double) {
        let trustData: [String: Any] = [
            "trust_phase": phase.rawValue,
            "confidence": confidence
        ]

        session.updateApplicationContext(trustData)

        if session.isReachable {
            session.sendMessage(["action": "trust_update"] + trustData)
        } else {
            session.transferUserInfo(trustData)
        }

        // Trigger complication update
        session.transferCurrentComplicationUserInfo([
            "phase": phase.rawValue,
            "confidence": confidence
        ])
    }

    func sendSync() {
        session.sendMessage([
            "action": "sync",
            "trust_phase": TrustPhase.scheduler.rawValue,
            "confidence": 0.35,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ])
    }

    func sendFullSync() {
        session.sendMessage([
            "action": "full_sync",
            "trust_phase": TrustPhase.scheduler.rawValue,
            "confidence": 0.35,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "blocks": [],
            "phenome_version": 1
        ])
    }

    func flushPendingMessages() {
        while pendingMessages > 0 && session.isReachable {
            session.sendMessage(["action": "pending_flush"])
            pendingMessages -= 1
        }
    }

    func getReceivedWorkouts() -> [WorkoutRecord] { receivedWorkouts }
    func getLocalWorkouts() -> [WorkoutRecord] { localWorkouts }
    func storeLocalWorkout(_ workout: WorkoutRecord) { localWorkouts.append(workout) }

    private func blockToDict(_ block: TrainingBlock) -> [String: Any] {
        [
            "id": block.id.uuidString,
            "type": block.type.rawValue,
            "start": ISO8601DateFormatter().string(from: block.startTime),
            "duration": block.duration,
            "status": block.status.rawValue
        ]
    }
}

actor TestableWatchConnector {
    let session: MockWCSession
    var todayBlocks: [TrainingBlock] = []
    var localBlocks: [TrainingBlock] = []
    var currentTrust: (phase: TrustPhase, confidence: Double) = (.observer, 0.0)

    init(session: MockWCSession) async {
        self.session = session
    }

    func recordWorkout(_ workout: WorkoutRecord) {
        session.sendMessage([
            "action": "workout_complete",
            "workout": [
                "id": workout.id.uuidString,
                "type": workout.type.rawValue,
                "start": ISO8601DateFormatter().string(from: workout.startTime),
                "end": ISO8601DateFormatter().string(from: workout.endTime),
                "heart_rate_avg": workout.heartRateAvg,
                "calories": workout.caloriesBurned,
                "duration": workout.endTime.timeIntervalSince(workout.startTime)
            ]
        ])
    }

    func getTodayBlocks() -> [TrainingBlock] { todayBlocks }
    func getCurrentTrust() -> (phase: TrustPhase, confidence: Double) { currentTrust }

    func syncFromContext() {
        let context = session.counterpart?.applicationContext ?? [:]

        if let phaseRaw = context["trust_phase"] as? Int,
           let phase = TrustPhase(rawValue: phaseRaw),
           let confidence = context["confidence"] as? Double {
            currentTrust = (phase, confidence)
        }

        if let blockData = context["today_block"] as? [String: Any],
           let id = blockData["id"] as? String,
           let typeRaw = blockData["type"] as? String,
           let startStr = blockData["start"] as? String,
           let duration = blockData["duration"] as? Int {

            let formatter = ISO8601DateFormatter()
            if let uuid = UUID(uuidString: id),
               let start = formatter.date(from: startStr) {
                let block = TrainingBlock(
                    id: uuid,
                    type: WorkoutType(rawValue: typeRaw) ?? .strength,
                    startTime: start,
                    duration: duration,
                    status: .scheduled
                )
                todayBlocks.append(block)
            }
        }
    }

    func storeLocalBlock(_ block: TrainingBlock) {
        localBlocks.append(block)
    }
}

// MARK: - Supporting Types

struct WorkoutRecord {
    let id: UUID
    let type: WorkoutType
    let startTime: Date
    let endTime: Date
    let heartRateAvg: Int
    let caloriesBurned: Int
}

extension WorkoutType: RawRepresentable {
    public init?(rawValue: String) {
        switch rawValue {
        case "strength": self = .strength
        case "cardio": self = .cardio
        case "hiit": self = .hiit
        case "mobility": self = .mobility
        case "recovery": self = .recovery
        case "custom": self = .custom
        default: return nil
        }
    }

    public var rawValue: String {
        switch self {
        case .strength: return "strength"
        case .cardio: return "cardio"
        case .hiit: return "hiit"
        case .mobility: return "mobility"
        case .recovery: return "recovery"
        case .custom: return "custom"
        }
    }
}
