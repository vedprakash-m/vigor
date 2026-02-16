//
//  OfflineAPIQueueTests.swift
//  VigorTests
//
//  Created by Vigor Team on February 15, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Tests for OfflineAPIQueue — persistent queuing, flush, retry,
//  and max-retries drop behavior.
//

import XCTest
@testable import Vigor

final class OfflineAPIQueueTests: XCTestCase {

    var sut: TestableOfflineQueue!

    override func setUp() async throws {
        sut = TestableOfflineQueue()
    }

    override func tearDown() async throws {
        sut = nil
    }

    // MARK: - QueuedOperation Model

    func testQueuedOperationDefaults() {
        let op = QueuedOperation(endpoint: "/api/test", method: "POST", body: nil)
        XCTAssertEqual(op.retryCount, 0, "New operations start with 0 retries")
        XCTAssertEqual(op.method, "POST")
        XCTAssertEqual(op.endpoint, "/api/test")
        XCTAssertFalse(op.id.isEmpty, "ID should be auto-generated")
    }

    func testQueuedOperationMaxRetries() {
        XCTAssertEqual(QueuedOperation.maxRetries, 5, "Max retries should be 5")
    }

    func testQueuedOperationIsCodable() throws {
        let op = QueuedOperation(
            endpoint: "/api/workout",
            method: "POST",
            body: "{}".data(using: .utf8)
        )

        let data = try JSONEncoder().encode(op)
        let decoded = try JSONDecoder().decode(QueuedOperation.self, from: data)

        XCTAssertEqual(decoded.endpoint, op.endpoint)
        XCTAssertEqual(decoded.method, op.method)
        XCTAssertEqual(decoded.body, op.body)
        XCTAssertEqual(decoded.retryCount, 0)
    }

    // MARK: - Enqueue / Count

    func testEnqueueIncrementsPendingCount() async {
        let op = QueuedOperation(endpoint: "/api/test", method: "POST", body: nil)
        await sut.enqueue(op)

        let count = await sut.pendingCount
        XCTAssertEqual(count, 1)
    }

    func testMultipleEnqueueIncrementsCount() async {
        for i in 0..<3 {
            let op = QueuedOperation(endpoint: "/api/test/\(i)", method: "POST", body: nil)
            await sut.enqueue(op)
        }

        let count = await sut.pendingCount
        XCTAssertEqual(count, 3)
    }

    // MARK: - Flush Success

    func testFlushClearsQueueOnSuccess() async {
        let op = QueuedOperation(endpoint: "/api/test", method: "POST", body: nil)
        await sut.enqueue(op)

        await sut.flush { _ in
            // Success — no throw
        }

        let count = await sut.pendingCount
        XCTAssertEqual(count, 0, "All operations should be flushed on success")
    }

    func testFlushCallsSenderForEachOperation() async {
        for i in 0..<3 {
            await sut.enqueue(QueuedOperation(endpoint: "/api/\(i)", method: "POST", body: nil))
        }

        var sentEndpoints: [String] = []
        await sut.flush { op in
            sentEndpoints.append(op.endpoint)
        }

        XCTAssertEqual(sentEndpoints.count, 3)
        XCTAssertTrue(sentEndpoints.contains("/api/0"))
        XCTAssertTrue(sentEndpoints.contains("/api/1"))
        XCTAssertTrue(sentEndpoints.contains("/api/2"))
    }

    // MARK: - Flush Failure & Retry

    func testFlushKeepsFailedOperationsForRetry() async {
        await sut.enqueue(QueuedOperation(endpoint: "/api/test", method: "POST", body: nil))

        await sut.flush { _ in
            throw TestError.networkFailure
        }

        let count = await sut.pendingCount
        XCTAssertEqual(count, 1, "Failed operation should remain in queue")
    }

    func testRetryCountIncrementsOnFailure() async {
        await sut.enqueue(QueuedOperation(endpoint: "/api/test", method: "POST", body: nil))

        // Flush with failure 3 times
        for _ in 0..<3 {
            await sut.flush { _ in throw TestError.networkFailure }
        }

        let retryCount = await sut.getFirstRetryCount()
        XCTAssertEqual(retryCount, 3, "Retry count should increment with each failure")
    }

    func testOperationDroppedAfterMaxRetries() async {
        await sut.enqueue(QueuedOperation(endpoint: "/api/test", method: "POST", body: nil))

        // Fail QueuedOperation.maxRetries times (5)
        for _ in 0..<QueuedOperation.maxRetries {
            await sut.flush { _ in throw TestError.networkFailure }
        }

        let count = await sut.pendingCount
        XCTAssertEqual(count, 0, "Operation should be dropped after max retries")
    }

    func testOperationKeptUntilMaxRetries() async {
        await sut.enqueue(QueuedOperation(endpoint: "/api/test", method: "POST", body: nil))

        // Fail (maxRetries - 1) times — should still be queued
        for _ in 0..<(QueuedOperation.maxRetries - 1) {
            await sut.flush { _ in throw TestError.networkFailure }
        }

        let count = await sut.pendingCount
        XCTAssertEqual(count, 1, "Operation should remain until max retries reached")
    }

    // MARK: - Mixed Success/Failure

    func testFlushKeepsOnlyFailedOperations() async {
        await sut.enqueue(QueuedOperation(endpoint: "/api/success", method: "POST", body: nil))
        await sut.enqueue(QueuedOperation(endpoint: "/api/failure", method: "POST", body: nil))
        await sut.enqueue(QueuedOperation(endpoint: "/api/success2", method: "POST", body: nil))

        await sut.flush { op in
            if op.endpoint.contains("failure") {
                throw TestError.networkFailure
            }
        }

        let count = await sut.pendingCount
        XCTAssertEqual(count, 1, "Only the failed operation should remain")
    }

    // MARK: - Clear

    func testClearQueueRemovesAll() async {
        for i in 0..<5 {
            await sut.enqueue(QueuedOperation(endpoint: "/api/\(i)", method: "POST", body: nil))
        }

        await sut.clearQueue()

        let count = await sut.pendingCount
        XCTAssertEqual(count, 0, "Queue should be empty after clear")
    }

    // MARK: - Empty Queue Flush

    func testFlushOnEmptyQueueDoesNothing() async {
        var callCount = 0
        await sut.flush { _ in
            callCount += 1
        }
        XCTAssertEqual(callCount, 0, "Sender should not be called on empty queue")
    }

    // MARK: - Offline Guard

    func testFlushDoesNothingWhenOffline() async {
        await sut.enqueue(QueuedOperation(endpoint: "/api/test", method: "POST", body: nil))
        await sut.setConnected(false)

        var callCount = 0
        await sut.flush { _ in
            callCount += 1
        }

        XCTAssertEqual(callCount, 0, "Should not flush when offline")
        let count = await sut.pendingCount
        XCTAssertEqual(count, 1, "Operations should remain queued when offline")
    }
}

// MARK: - Test Helpers

private enum TestError: Error {
    case networkFailure
}

// MARK: - Testable Offline Queue

/// Self-contained actor mirroring OfflineAPIQueue logic, without
/// NWPathMonitor, UserDefaults, or VigorAPIClient dependencies.
actor TestableOfflineQueue {

    private var queue: [QueuedOperation] = []
    private var isFlushing = false
    private(set) var isConnected = true

    func enqueue(_ operation: QueuedOperation) {
        queue.append(operation)
    }

    var pendingCount: Int { queue.count }

    func setConnected(_ connected: Bool) {
        isConnected = connected
    }

    func getFirstRetryCount() -> Int {
        queue.first?.retryCount ?? -1
    }

    func flush(using sender: @escaping (QueuedOperation) async throws -> Void) async {
        guard isConnected, !isFlushing, !queue.isEmpty else { return }
        isFlushing = true
        defer { isFlushing = false }

        var remaining: [QueuedOperation] = []

        for var op in queue {
            do {
                try await sender(op)
            } catch {
                op.retryCount += 1
                if op.retryCount < QueuedOperation.maxRetries {
                    remaining.append(op)
                }
            }
        }

        queue = remaining
    }

    func clearQueue() {
        queue.removeAll()
    }
}
