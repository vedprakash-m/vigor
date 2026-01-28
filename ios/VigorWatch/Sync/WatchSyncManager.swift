//
//  WatchSyncManager.swift
//  VigorWatch
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Watch-iPhone sync manager via WatchConnectivity.
//  Watch is authoritative for workout data, phone is authoritative for scheduling.
//

import Foundation
import WatchConnectivity

@MainActor
class WatchSyncManager: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = WatchSyncManager()

    // MARK: - Published State

    @Published var nextBlock: WatchTrainingBlock?
    @Published var todayBlocks: [WatchTrainingBlock] = []
    @Published var completedThisWeek: Int = 0
    @Published var scheduledThisWeek: Int = 0
    @Published var recoveryScore: Int?
    @Published var trustPhase: String = "observer"
    @Published var isPhoneReachable: Bool = false
    @Published var lastSyncTime: Date?

    // MARK: - Private State

    private var session: WCSession?
    private var pendingWorkouts: [[String: Any]] = []

    // MARK: - Initialization

    override private init() {
        super.init()
        setupSession()
    }

    private func setupSession() {
        guard WCSession.isSupported() else { return }

        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    // MARK: - Sync Methods

    func syncWithPhone() async {
        guard let session = session, session.isReachable else {
            isPhoneReachable = false
            return
        }

        isPhoneReachable = true

        // Request current schedule from phone
        let message: [String: Any] = [
            "type": "sync_request",
            "timestamp": Date().timeIntervalSince1970
        ]

        do {
            let reply = try await sendMessageAsync(message)
            await processPhoneReply(reply)
            lastSyncTime = Date()
        } catch {
            print("Sync failed: \(error)")
        }
    }

    func sendWorkoutCompletion(_ workoutData: [String: Any]) async {
        var data = workoutData
        data["type"] = "workout_completed"
        data["timestamp"] = Date().timeIntervalSince1970

        guard let session = session, session.isReachable else {
            // Queue for later
            pendingWorkouts.append(data)
            return
        }

        do {
            _ = try await sendMessageAsync(data)
        } catch {
            // Queue for later
            pendingWorkouts.append(data)
        }
    }

    func processPendingData() async {
        // Process any pending workouts
        guard let session = session, session.isReachable else { return }

        let pending = pendingWorkouts
        pendingWorkouts.removeAll()

        for workout in pending {
            do {
                _ = try await sendMessageAsync(workout)
            } catch {
                pendingWorkouts.append(workout)
            }
        }
    }

    // MARK: - Message Sending

    private func sendMessageAsync(_ message: [String: Any]) async throws -> [String: Any] {
        try await withCheckedThrowingContinuation { continuation in
            session?.sendMessage(message, replyHandler: { reply in
                continuation.resume(returning: reply)
            }, errorHandler: { error in
                continuation.resume(throwing: error)
            })
        }
    }

    // MARK: - Process Phone Data

    private func processPhoneReply(_ reply: [String: Any]) async {
        // Process schedule data
        if let blocksData = reply["blocks"] as? [[String: Any]] {
            let blocks = blocksData.compactMap { parseBlock($0) }
            todayBlocks = blocks.filter { Calendar.current.isDateInToday($0.scheduledStart) }
            nextBlock = todayBlocks.first { $0.scheduledStart > Date() }
        }

        // Process week stats
        if let completed = reply["completed_this_week"] as? Int {
            completedThisWeek = completed
        }
        if let scheduled = reply["scheduled_this_week"] as? Int {
            scheduledThisWeek = scheduled
        }

        // Process recovery
        if let recovery = reply["recovery_score"] as? Int {
            recoveryScore = recovery
        }

        // Process trust phase
        if let phase = reply["trust_phase"] as? String {
            trustPhase = phase
        }
    }

    private func parseBlock(_ data: [String: Any]) -> WatchTrainingBlock? {
        guard let id = data["id"] as? String,
              let typeStr = data["type"] as? String,
              let type = WatchWorkoutType(rawValue: typeStr),
              let start = data["start"] as? TimeInterval,
              let end = data["end"] as? TimeInterval,
              let status = data["status"] as? String else {
            return nil
        }

        return WatchTrainingBlock(
            id: id,
            workoutType: type,
            scheduledStart: Date(timeIntervalSince1970: start),
            scheduledEnd: Date(timeIntervalSince1970: end),
            status: status
        )
    }
}

// MARK: - WCSessionDelegate

extension WatchSyncManager: WCSessionDelegate {

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            isPhoneReachable = session.isReachable
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isPhoneReachable = session.isReachable

            if session.isReachable {
                await syncWithPhone()
                await processPendingData()
            }
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        Task { @MainActor in
            let response = await handlePhoneMessage(message)
            replyHandler(response)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            _ = await handlePhoneMessage(message)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        Task { @MainActor in
            await processPhoneReply(applicationContext)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String: Any]
    ) {
        Task { @MainActor in
            await handleUserInfo(userInfo)
        }
    }

    // MARK: - Message Handling

    @MainActor
    private func handlePhoneMessage(_ message: [String: Any]) async -> [String: Any] {
        guard let type = message["type"] as? String else {
            return ["error": "Unknown message type"]
        }

        switch type {
        case "schedule_update":
            await processPhoneReply(message)
            return ["status": "received"]

        case "complication_update":
            // Update complication data
            await ComplicationController.shared.updateFromPhone(message)
            return ["status": "received"]

        case "start_workout":
            if let typeStr = message["workout_type"] as? String,
               let workoutType = WatchWorkoutType(rawValue: typeStr) {
                WatchWorkoutManager.shared.startFreeWorkout(workoutType)
                return ["status": "started"]
            }
            return ["error": "Invalid workout type"]

        case "health_check":
            return [
                "status": "healthy",
                "workout_active": WatchWorkoutManager.shared.isWorkoutActive,
                "last_sync": lastSyncTime?.timeIntervalSince1970 ?? 0
            ]

        default:
            return ["error": "Unknown type: \(type)"]
        }
    }

    @MainActor
    private func handleUserInfo(_ userInfo: [String: Any]) async {
        // Handle background user info transfers
        if let type = userInfo["type"] as? String {
            switch type {
            case "complication_data":
                await ComplicationController.shared.updateFromPhone(userInfo)
            default:
                break
            }
        }
    }
}
