//
//  AppDelegate.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  App Delegate for handling push notifications, background tasks,
//  and other UIKit lifecycle events.
//

import UIKit
import UserNotifications
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {

    // MARK: - Application Lifecycle

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        #if ENABLE_PUSH_NOTIFICATIONS
        // Register for remote notifications (silent push for Ghost wake)
        registerForRemoteNotifications(application)
        #endif

        // Register background tasks
        registerBackgroundTasks()

        // Configure notification delegate (local notifications — works with free provisioning)
        UNUserNotificationCenter.current().delegate = self

        return true
    }

    // MARK: - Remote Notifications (Silent Push)

    #if ENABLE_PUSH_NOTIFICATIONS
    private func registerForRemoteNotifications(_ application: UIApplication) {
        application.registerForRemoteNotifications()
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()

        Task {
            // Register token with backend for silent push wakes
            await SilentPushReceiver.shared.registerDeviceToken(tokenString)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // Silent push unavailable - Ghost must rely on BGTaskScheduler only
        // This is a degraded state but not fatal
        Task {
            await GhostEngine.shared.healthMonitor.reportPushUnavailable(error: error)
        }
    }

    /// Handle silent push notification (content-available: 1)
    /// This is the PRIMARY mechanism for waking the Ghost when iOS throttles BGTaskScheduler
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Task {
            let result = await SilentPushReceiver.shared.handleSilentPush(userInfo: userInfo)
            completionHandler(result)
        }
    }
    #endif

    // MARK: - Background Tasks

    private func registerBackgroundTasks() {
        // Morning cycle background task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: BackgroundTaskIdentifiers.morningCycle,
            using: nil
        ) { task in
            guard let processingTask = task as? BGProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self.handleMorningCycleTask(processingTask)
        }

        // Evening cycle background task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: BackgroundTaskIdentifiers.eveningCycle,
            using: nil
        ) { task in
            guard let processingTask = task as? BGProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self.handleEveningCycleTask(processingTask)
        }

        // HealthKit background delivery
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: BackgroundTaskIdentifiers.healthKitDelivery,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self.handleHealthKitDeliveryTask(refreshTask)
        }
    }

    private func handleMorningCycleTask(_ task: BGProcessingTask) {
        task.expirationHandler = {
            // Task about to be terminated - save state
            Task {
                await GhostEngine.shared.saveStateForTermination()
            }
        }

        Task {
            await GhostEngine.shared.executeMorningCycle()
            task.setTaskCompleted(success: true)
        }
    }

    private func handleEveningCycleTask(_ task: BGProcessingTask) {
        task.expirationHandler = {
            Task {
                await GhostEngine.shared.saveStateForTermination()
            }
        }

        Task {
            await GhostEngine.shared.executeEveningCycle()
            task.setTaskCompleted(success: true)
        }
    }

    private func handleHealthKitDeliveryTask(_ task: BGAppRefreshTask) {
        Task {
            await HealthKitObserver.shared.processBackgroundDelivery()
            task.setTaskCompleted(success: true)
        }
    }

    // MARK: - URL Handling (MSAL Auth)

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        #if ENABLE_MSAL
        // Handle MSAL authentication callback
        return AuthManager.shared.handleAuthCallback(url: url)
        #else
        return false
        #endif
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {

    /// Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification banner even when app is in foreground
        completionHandler([.banner, .sound])
    }

    /// Handle notification interaction
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier

        Task {
            await NotificationOrchestrator.shared.handleNotificationResponse(
                actionIdentifier: actionIdentifier,
                userInfo: userInfo
            )
            completionHandler()
        }
    }
}
