//
//  OfflineAPIQueue.swift
//  Vigor
//
//  Created by Vigor Team on February 15, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Persistent offline queue for API operations that fail due to connectivity.
//  Uses UserDefaults for lightweight persistence; NWPathMonitor for
//  connectivity awareness. Automatically flushes when connectivity returns.
//

import Foundation
import Network

// MARK: - Queued Operation

struct QueuedOperation: Codable, Identifiable {
    let id: String
    let endpoint: String
    let method: String // HTTPMethod raw value
    let body: Data?
    let timestamp: Date
    var retryCount: Int

    static let maxRetries = 5

    init(endpoint: String, method: String, body: Data?, timestamp: Date = Date()) {
        self.id = UUID().uuidString
        self.endpoint = endpoint
        self.method = method
        self.body = body
        self.timestamp = timestamp
        self.retryCount = 0
    }
}

// MARK: - Offline API Queue

actor OfflineAPIQueue {

    static let shared = OfflineAPIQueue()

    // MARK: - Properties

    private let storageKey = "vigor_offline_api_queue"
    private var queue: [QueuedOperation] = []
    private var isFlushing = false
    private let monitor: NWPathMonitor
    private let monitorQueue: DispatchQueue
    private(set) var isConnected: Bool = true

    // MARK: - Initialization

    private init() {
        self.monitor = NWPathMonitor()
        self.monitorQueue = DispatchQueue(label: "com.vigor.connectivity", qos: .utility)

        // Load persisted queue
        queue = Self.loadQueue()

        // Start connectivity monitoring
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            Task {
                await self.handleConnectivityChange(path.status == .satisfied)
            }
        }
        monitor.start(queue: monitorQueue)
    }

    // MARK: - Queue Management

    /// Enqueue a failed operation for later retry.
    func enqueue(_ operation: QueuedOperation) {
        queue.append(operation)
        persistQueue()
    }

    /// Number of pending operations.
    var pendingCount: Int { queue.count }

    /// Try to flush all queued operations when online.
    /// Called automatically on connectivity change, or can be called manually.
    func flush(using sender: @escaping (QueuedOperation) async throws -> Void) async {
        guard isConnected, !isFlushing, !queue.isEmpty else { return }
        isFlushing = true
        defer { isFlushing = false }

        var remaining: [QueuedOperation] = []

        for var op in queue {
            do {
                try await sender(op)
                // Success — don't re-queue
            } catch {
                op.retryCount += 1
                if op.retryCount < QueuedOperation.maxRetries {
                    remaining.append(op)
                }
                // else: exceeded max retries — drop
            }
        }

        queue = remaining
        persistQueue()
    }

    // MARK: - Connectivity

    private func handleConnectivityChange(_ connected: Bool) {
        let wasDisconnected = !isConnected
        isConnected = connected

        if connected && wasDisconnected && !queue.isEmpty {
            // Connectivity restored — trigger flush from VigorAPIClient
            Task {
                try? await VigorAPIClient.shared.processPendingOperations()
            }
        }
    }

    // MARK: - Persistence

    private func persistQueue() {
        guard let data = try? JSONEncoder().encode(queue) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private static func loadQueue() -> [QueuedOperation] {
        guard let data = UserDefaults.standard.data(forKey: "vigor_offline_api_queue"),
              let ops = try? JSONDecoder().decode([QueuedOperation].self, from: data) else {
            return []
        }
        return ops
    }

    /// Remove all queued operations (e.g. on logout).
    func clearQueue() {
        queue.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
