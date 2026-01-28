//
//  VigorApp.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Main entry point for the Vigor iOS app.
//  The Ghost - An invisible fitness system that schedules, adapts, and learns.
//

import SwiftUI
import HealthKit

@main
struct VigorApp: App {
    @StateObject private var ghostEngine = GhostEngine.shared
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var phenomeCoordinator = PhenomeCoordinator.shared
    @StateObject private var trustStateMachine = TrustStateMachine.shared

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ghostEngine)
                .environmentObject(authManager)
                .environmentObject(phenomeCoordinator)
                .environmentObject(trustStateMachine)
                .onAppear {
                    Task {
                        await initializeGhost()
                    }
                }
        }
    }

    /// Initialize Ghost Engine and related systems
    private func initializeGhost() async {
        // Check authentication state
        guard authManager.isAuthenticated else {
            return
        }

        // Initialize Phenome storage
        await phenomeCoordinator.initialize()

        // Start Ghost Engine background cycles
        await ghostEngine.start()

        // Request necessary permissions
        await requestPermissions()
    }

    /// Request HealthKit and Calendar permissions
    private func requestPermissions() async {
        // HealthKit permissions are requested during onboarding
        // Calendar permissions are requested during onboarding
        // This is called for returning users to verify permissions still granted

        let healthObserver = HealthKitObserver.shared
        if !healthObserver.isAuthorized {
            // Permissions may have been revoked - Ghost enters degraded mode
            await ghostEngine.healthMonitor.reportHealthKitUnavailable()
        }

        let calendarScheduler = CalendarScheduler.shared
        if !calendarScheduler.isAuthorized {
            await ghostEngine.healthMonitor.reportCalendarUnavailable()
        }
    }
}
