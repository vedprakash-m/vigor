//
//  VigorWatchApp.swift
//  VigorWatch
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  watchOS app entry point - complication-driven design.
//  Apple Watch is mandatory for Vigor - it's the primary workout sensor.
//

import SwiftUI
import HealthKit
import WatchKit

@main
struct VigorWatchApp: App {
    @StateObject private var workoutManager = WatchWorkoutManager.shared
    @StateObject private var syncManager = WatchSyncManager.shared

    @WKApplicationDelegateAdaptor(ExtensionDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(workoutManager)
                .environmentObject(syncManager)
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @EnvironmentObject private var workoutManager: WatchWorkoutManager
    @EnvironmentObject private var syncManager: WatchSyncManager

    var body: some View {
        NavigationStack {
            if workoutManager.isWorkoutActive {
                ActiveWorkoutView()
            } else {
                TodayView()
            }
        }
    }
}

// MARK: - Extension Delegate

class ExtensionDelegate: NSObject, WKApplicationDelegate {

    func applicationDidFinishLaunching() {
        // Request HealthKit authorization
        Task {
            await requestHealthKitAuthorization()
        }

        // Set up background refresh
        scheduleBackgroundRefresh()
    }

    func applicationDidBecomeActive() {
        // Sync with iPhone
        Task {
            await WatchSyncManager.shared.syncWithPhone()
        }
    }

    func applicationWillResignActive() {
        // Save state
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let refreshTask as WKApplicationRefreshBackgroundTask:
                handleRefreshTask(refreshTask)

            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                handleSnapshotTask(snapshotTask)

            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                handleConnectivityTask(connectivityTask)

            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

    private func handleRefreshTask(_ task: WKApplicationRefreshBackgroundTask) {
        Task {
            // Refresh complication data
            await ComplicationController.shared.refreshData()

            // Sync with iPhone (wakes iPhone via WCSession)
            await WatchSyncManager.shared.syncWithPhone()

            // Schedule next refresh
            scheduleBackgroundRefresh()

            task.setTaskCompletedWithSnapshot(true)
        }
    }

    private func handleSnapshotTask(_ task: WKSnapshotRefreshBackgroundTask) {
        task.setTaskCompletedWithSnapshot(true)
    }

    private func handleConnectivityTask(_ task: WKWatchConnectivityRefreshBackgroundTask) {
        Task {
            // Process pending data from iPhone
            await WatchSyncManager.shared.processPendingData()
            task.setTaskCompletedWithSnapshot(false)
        }
    }

    private func scheduleBackgroundRefresh() {
        // Schedule refresh for 15 minutes from now
        let fireDate = Date().addingTimeInterval(15 * 60)
        WKApplication.shared().scheduleBackgroundRefresh(
            withPreferredDate: fireDate,
            userInfo: nil
        ) { error in
            if let error = error {
                print("Failed to schedule background refresh: \(error)")
            }
        }
    }

    private func requestHealthKitAuthorization() async {
        let healthStore = HKHealthStore()

        let readTypes: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .stepCount)!
        ]

        do {
            try await healthStore.requestAuthorization(toShare: [HKObjectType.workoutType()], read: readTypes)
        } catch {
            print("HealthKit authorization failed: \(error)")
        }
    }
}
