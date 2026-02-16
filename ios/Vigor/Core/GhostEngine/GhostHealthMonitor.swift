//
//  GhostHealthMonitor.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Systemic self-degradation for silent failures.
//  Tracks background failures, missed windows, calendar failures.
//  Modes: healthy → degraded → safeMode → suspended
//
//  Per Tech Spec §2.4
//

import Foundation
import Combine

@MainActor
final class GhostHealthMonitor: ObservableObject {

    // MARK: - Singleton
    static let shared = GhostHealthMonitor()

    // MARK: - Published State

    @Published private(set) var currentMode: GhostHealthMode = .healthy
    @Published private(set) var healthScore: Double = 100.0
    @Published private(set) var lastHealthCheck: Date?
    @Published private(set) var issues: [GhostHealthIssue] = []

    // MARK: - Thresholds

    private let degradedThreshold: Double = 70.0
    private let safeModeThreshold: Double = 40.0
    private let suspendedThreshold: Double = 20.0

    // MARK: - Onboarding Awareness

    /// During onboarding, permission states are expected to be unavailable.
    /// We must not penalize health score or send notifications before onboarding completes.
    private var isOnboardingComplete: Bool {
        UserDefaults.standard.bool(forKey: "onboarding_completed")
    }

    // MARK: - Failure Tracking

    private var backgroundFailures: [Date] = []
    private var cycleFailures: [Date] = []
    private var calendarFailures: [Date] = []
    private var pushUnavailable = false
    private var healthKitUnavailable = false
    private var calendarUnavailable = false

    // MARK: - Auto-Recovery

    private var recoveryAttempts = 0
    private let maxRecoveryAttempts = 3

    // MARK: - Failure Reporting

    func reportCycleFailure(_ cycle: GhostCycle, error: Error) async {
        cycleFailures.append(Date())
        cleanupOldFailures()

        issues.append(GhostHealthIssue(
            type: .cycleFailure,
            description: "\(cycle.rawValue) cycle failed: \(error.localizedDescription)",
            timestamp: Date(),
            severity: .warning
        ))

        await recalculateHealth()
    }

    func reportBackgroundTaskSchedulingFailure(error: Error) async {
        backgroundFailures.append(Date())
        cleanupOldFailures()

        issues.append(GhostHealthIssue(
            type: .backgroundTaskFailure,
            description: "Background task scheduling failed: \(error.localizedDescription)",
            timestamp: Date(),
            severity: .warning
        ))

        await recalculateHealth()
    }

    func reportCalendarWriteFailure(error: Error) async {
        calendarFailures.append(Date())
        cleanupOldFailures()

        issues.append(GhostHealthIssue(
            type: .calendarFailure,
            description: "Calendar write failed: \(error.localizedDescription)",
            timestamp: Date(),
            severity: .warning
        ))

        await recalculateHealth()
    }

    func reportPushUnavailable(error: Error) async {
        pushUnavailable = true

        issues.append(GhostHealthIssue(
            type: .pushUnavailable,
            description: "Push notifications unavailable: \(error.localizedDescription)",
            timestamp: Date(),
            severity: .info
        ))

        await recalculateHealth()
    }

    func reportHealthKitUnavailable() async {
        healthKitUnavailable = true

        issues.append(GhostHealthIssue(
            type: .healthKitUnavailable,
            description: "HealthKit permissions not granted",
            timestamp: Date(),
            severity: .critical
        ))

        await recalculateHealth()
    }

    func reportCalendarUnavailable() async {
        calendarUnavailable = true

        issues.append(GhostHealthIssue(
            type: .calendarUnavailable,
            description: "Calendar permissions not granted",
            timestamp: Date(),
            severity: .critical
        ))

        await recalculateHealth()
    }

    // MARK: - Health Calculation

    private func recalculateHealth() async {
        var score: Double = 100.0

        // Deduct for recent failures (last 24 hours)
        let recentBackgroundFailures = backgroundFailures.filter {
            Date().timeIntervalSince($0) < 86400
        }.count
        score -= Double(recentBackgroundFailures) * 10.0

        let recentCycleFailures = cycleFailures.filter {
            Date().timeIntervalSince($0) < 86400
        }.count
        score -= Double(recentCycleFailures) * 15.0

        let recentCalendarFailures = calendarFailures.filter {
            Date().timeIntervalSince($0) < 86400
        }.count
        score -= Double(recentCalendarFailures) * 10.0

        // Deduct for missing capabilities — but ONLY after onboarding is complete.
        // Before onboarding, permissions haven't been requested yet, so
        // penalizing their absence would immediately drop score to safeMode
        // and trigger useless "Minimal operations only" notifications.
        if isOnboardingComplete {
            if pushUnavailable {
                score -= 10.0 // Push is nice-to-have, not critical
            }

            if healthKitUnavailable {
                score -= 40.0 // HealthKit is critical
            }

            if calendarUnavailable {
                score -= 30.0 // Calendar is important
            }
        }

        // Clamp to 0-100
        healthScore = max(0, min(100, score))
        lastHealthCheck = Date()

        // Update mode based on score
        updateMode()

        // Attempt auto-recovery if degraded
        if currentMode != .healthy && recoveryAttempts < maxRecoveryAttempts {
            await attemptRecovery()
        }
    }

    private func updateMode() {
        let previousMode = currentMode

        if healthScore >= degradedThreshold {
            currentMode = .healthy
        } else if healthScore >= safeModeThreshold {
            currentMode = .degraded
        } else if healthScore >= suspendedThreshold {
            currentMode = .safeMode
        } else {
            currentMode = .suspended
        }

        // Health mode changes are internal system state — only log, don't notify user.
        // Per PRD §4.3: notifications are for actionable workout decisions, not system diagnostics.
        // Previously this sent "Minimal operations only" notifications which confused users.
        if previousMode != currentMode {
            // Log for Decision Receipt / debugging only
            Task {
                await DecisionReceiptStore.shared.store(
                    DecisionReceipt(action: .healthModeChanged)
                )
            }
        }
    }

    // MARK: - Recovery

    private func attemptRecovery() async {
        recoveryAttempts += 1

        // Clear old failures (older than 24 hours)
        cleanupOldFailures()

        // Remove resolved issues
        issues.removeAll { issue in
            switch issue.type {
            case .pushUnavailable:
                return !pushUnavailable
            case .healthKitUnavailable:
                return !healthKitUnavailable
            case .calendarUnavailable:
                return !calendarUnavailable
            default:
                return false
            }
        }

        // Recalculate after cleanup
        await recalculateHealth()

        if currentMode == .healthy {
            recoveryAttempts = 0
        }
    }

    private func cleanupOldFailures() {
        let cutoff = Date().addingTimeInterval(-86400) // 24 hours ago

        backgroundFailures.removeAll { $0 < cutoff }
        cycleFailures.removeAll { $0 < cutoff }
        calendarFailures.removeAll { $0 < cutoff }
    }

    // MARK: - Manual Recovery Trigger

    func manualRecoveryAttempt() async {
        recoveryAttempts = 0

        // Re-check capabilities
        if healthKitUnavailable {
            healthKitUnavailable = !HealthKitObserver.shared.isAuthorized
        }

        if calendarUnavailable {
            calendarUnavailable = !CalendarScheduler.shared.isAuthorized
        }

        await recalculateHealth()
    }

    /// Called when a permission is detected as re-granted (e.g., HealthKit approved in Settings).
    /// Automatically clears the corresponding issue and recalculates health.
    func onPermissionGranted(_ permissionType: GhostHealthIssue.IssueType) async {
        switch permissionType {
        case .healthKitUnavailable:
            healthKitUnavailable = false
        case .calendarUnavailable:
            calendarUnavailable = false
        case .pushUnavailable:
            pushUnavailable = false
        default:
            break
        }
        issues.removeAll { $0.type == permissionType }
        recoveryAttempts = 0
        await recalculateHealth()
    }

    // MARK: - System Failure Recording

    func recordSystemFailure(_ message: String) async {
        issues.append(GhostHealthIssue(
            type: .cycleFailure,
            description: message,
            timestamp: Date(),
            severity: .critical
        ))
        await recalculateHealth()
    }

    // MARK: - Health Snapshot

    func getHealth() -> GhostHealthSnapshot {
        GhostHealthSnapshot(
            mode: currentMode,
            score: healthScore,
            issueCount: issues.count,
            lastCheck: lastHealthCheck
        )
    }
}

// MARK: - Supporting Types

enum GhostHealthMode: String, Codable {
    case healthy = "healthy"
    case degraded = "degraded"
    case safeMode = "safeMode"
    case suspended = "suspended"

    var displayName: String {
        switch self {
        case .healthy: return "Healthy"
        case .degraded: return "Degraded"
        case .safeMode: return "Safe Mode"
        case .suspended: return "Suspended"
        }
    }

    var description: String {
        switch self {
        case .healthy:
            return "All systems operational"
        case .degraded:
            return "Some features may be delayed"
        case .safeMode:
            return "Minimal operations only"
        case .suspended:
            return "Ghost is paused"
        }
    }
}

enum GhostCycle: String {
    case morning = "Morning"
    case evening = "Evening"
    case sunday = "Sunday"
}

struct GhostHealthIssue: Identifiable {
    let id = UUID()
    let type: IssueType
    let description: String
    let timestamp: Date
    let severity: Severity

    enum IssueType {
        case cycleFailure
        case backgroundTaskFailure
        case calendarFailure
        case pushUnavailable
        case healthKitUnavailable
        case calendarUnavailable
    }

    enum Severity {
        case info
        case warning
        case critical
    }
}

// MARK: - Ghost Health Snapshot

struct GhostHealthSnapshot: Codable {
    let mode: GhostHealthMode
    let score: Double
    let issueCount: Int
    let lastCheck: Date?
}
