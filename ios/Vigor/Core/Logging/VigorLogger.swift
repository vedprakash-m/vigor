//
//  VigorLogger.swift
//  Vigor
//
//  Created by Vigor Team on February 15, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Structured logging for Ghost Engine, Notifications, and HealthKit.
//  Uses os.Logger (Apple Unified Logging) for production and #if DEBUG print.
//

import Foundation
import os

/// Structured logger using Apple's unified logging system.
/// Each subsystem gets its own category for filtering in Console.app.
enum VigorLogger {

    // MARK: - Categories

    static let ghost = Logger(subsystem: "com.vigor.app", category: "GhostEngine")
    static let notifications = Logger(subsystem: "com.vigor.app", category: "Notifications")
    static let healthKit = Logger(subsystem: "com.vigor.app", category: "HealthKit")
    static let trust = Logger(subsystem: "com.vigor.app", category: "Trust")
    static let api = Logger(subsystem: "com.vigor.app", category: "API")
    static let general = Logger(subsystem: "com.vigor.app", category: "General")

    // MARK: - Convenience: Timed Operation

    /// Measure and log the duration of an async operation.
    static func timed<T>(
        _ logger: Logger,
        _ message: String,
        operation: () async throws -> T
    ) async rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let duration = CFAbsoluteTimeGetCurrent() - start
        logger.info("\(message) completed in \(String(format: "%.2f", duration))s")
        return result
    }
}
