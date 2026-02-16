//
//  OnboardingFlow.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Progressive onboarding flow - Apple Watch required, minimal input.
//  Per PRD §4.1: Onboarding should be fast and not ask redundant questions.
//

import SwiftUI
import HealthKit
import EventKit
import WatchConnectivity

// MARK: - Onboarding State

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case meetTheGhost        // Merged: philosophy + trust explanation
    case watchPairing
    case permissions         // Merged: health + calendar on one screen
    case workoutPreferences
    case absolution
    case confirmation

    var title: String {
        switch self {
        case .welcome: return "Welcome to Vigor"
        case .meetTheGhost: return "Meet The Ghost"
        case .watchPairing: return "Connect Your Watch"
        case .permissions: return "Connect Your Data"
        case .workoutPreferences: return "Your Preferences"
        case .absolution: return "Your First Insight"
        case .confirmation: return "Ready to Go"
        }
    }

    var subtitle: String {
        switch self {
        case .welcome:
            return "Your invisible fitness coach"
        case .meetTheGhost:
            return "An AI that earns your trust through results"
        case .watchPairing:
            return "Apple Watch is required for Vigor"
        case .permissions:
            return "Health data and calendar access in one step"
        case .workoutPreferences:
            return "Just a few quick questions"
        case .absolution:
            return "The Ghost already knows you"
        case .confirmation:
            return "The Ghost is ready to help"
        }
    }
}

// MARK: - Onboarding View Model

@MainActor
class OnboardingViewModel: ObservableObject {

    @Published var currentStep: OnboardingStep = .welcome
    @Published var isProcessing = false
    @Published var error: OnboardingError?

    // Permissions state
    @Published var watchPaired = false
    @Published var watchAppInstalled = false
    @Published var healthAuthorized = false
    @Published var calendarAuthorized = false
    @Published var healthPermissionAttempted = false
    @Published var calendarPermissionAttempted = false

    // User preferences
    @Published var workoutDaysPerWeek = 3
    @Published var preferredDuration = 45 // minutes
    @Published var primaryGoal: FitnessGoal = .generalFitness

    private let healthStore = HKHealthStore()
    private let eventStore = EKEventStore()

    init() {
        checkWatchStatus()
    }

    // MARK: - Navigation

    func nextStep() {
        guard let nextIndex = OnboardingStep.allCases.firstIndex(where: { $0.rawValue == currentStep.rawValue + 1 }) else {
            completeOnboarding()
            return
        }

        withAnimation(.easeInOut) {
            currentStep = OnboardingStep.allCases[nextIndex]
        }
    }

    func previousStep() {
        guard currentStep.rawValue > 0 else { return }

        withAnimation(.easeInOut) {
            currentStep = OnboardingStep(rawValue: currentStep.rawValue - 1) ?? .welcome
        }
    }

    // MARK: - Watch Pairing

    func checkWatchStatus() {
        guard WCSession.isSupported() else {
            watchPaired = false
            return
        }

        // Use WatchConnectivityManager which properly activates the session
        // and updates its published properties via the WCSessionDelegate.
        // Reading WCSession.default directly without activation returns false.
        let manager = WatchConnectivityManager.shared
        watchPaired = manager.isPaired
        watchAppInstalled = manager.isWatchAppInstalled
    }

    func openWatchApp() {
        // Deep link to Watch app on iPhone
        if let url = URL(string: "itms-watchs://") {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Health Permissions

    func requestHealthPermissions() async {
        isProcessing = true
        defer {
            isProcessing = false
            healthPermissionAttempted = true
        }

        guard HKHealthStore.isHealthDataAvailable() else {
            // HealthKit not available (e.g., iPad) — allow proceeding
            healthAuthorized = false
            return
        }

        let readTypes: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.workoutType()
        ]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            // Note: requestAuthorization succeeds even if user denies —
            // it only throws on system-level failures
            healthAuthorized = true
        } catch {
            // Don't block onboarding — user can grant access later in Settings
            print("HealthKit authorization error: \(error.localizedDescription)")
            healthAuthorized = false
        }
    }

    // MARK: - Calendar Permissions

    func requestCalendarPermissions() async {
        isProcessing = true
        defer {
            isProcessing = false
            calendarPermissionAttempted = true
        }

        if #available(iOS 17.0, *) {
            let granted = try? await eventStore.requestFullAccessToEvents()
            calendarAuthorized = granted ?? false
        } else {
            let granted = try? await eventStore.requestAccess(to: .event)
            calendarAuthorized = granted ?? false
        }
        // Don't set error — user can grant calendar access later in Settings
    }

    // MARK: - Complete Onboarding

    func completeOnboarding() {
        Task {
            isProcessing = true
            defer { isProcessing = false }

            // Save preferences
            await savePreferences()

            // Start Ghost learning phase
            await GhostEngine.shared.startLearningPhase()

            // Mark onboarding complete
            UserDefaults.standard.set(true, forKey: "onboarding_completed")

            // Trigger initial HealthKit import
            Task {
                try? await HealthKitObserver.shared.performInitialImport()
            }
        }
    }

    private func savePreferences() async {
        let preferences = UserPreferences(
            workoutDaysPerWeek: workoutDaysPerWeek,
            preferredWorkoutDuration: preferredDuration,
            preferredWorkoutTimes: [],
            sacredTimes: [],
            notificationsEnabled: true,
            calendarSyncEnabled: true,
            watchSyncEnabled: true
        )

        await BehavioralMemoryStore.shared.updatePreferences([
            "workout_days_per_week": workoutDaysPerWeek,
            "preferred_duration": preferredDuration,
            "primary_goal": primaryGoal.rawValue
        ])
    }
}

// MARK: - Fitness Goal

enum FitnessGoal: String, CaseIterable {
    case generalFitness = "general"
    case buildStrength = "strength"
    case improveEndurance = "endurance"
    case loseWeight = "weight_loss"
    case stayActive = "active"

    var displayName: String {
        switch self {
        case .generalFitness: return "General Fitness"
        case .buildStrength: return "Build Strength"
        case .improveEndurance: return "Improve Endurance"
        case .loseWeight: return "Lose Weight"
        case .stayActive: return "Stay Active"
        }
    }

    var icon: String {
        switch self {
        case .generalFitness: return "figure.mixed.cardio"
        case .buildStrength: return "dumbbell.fill"
        case .improveEndurance: return "figure.run"
        case .loseWeight: return "scalemass.fill"
        case .stayActive: return "heart.fill"
        }
    }
}

// MARK: - Onboarding Error

enum OnboardingError: LocalizedError {
    case watchNotPaired
    case watchAppNotInstalled
    case healthAuthorizationFailed
    case calendarAuthorizationFailed
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .watchNotPaired:
            return "Please pair an Apple Watch to continue"
        case .watchAppNotInstalled:
            return "Please install the Vigor watch app"
        case .healthAuthorizationFailed:
            return "Health access is required for Vigor to work"
        case .calendarAuthorizationFailed:
            return "Calendar access is required for scheduling"
        case .saveFailed:
            return "Failed to save preferences"
        }
    }
}

// MARK: - Onboarding Flow View

struct OnboardingFlowView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Binding var isComplete: Bool

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: Double(viewModel.currentStep.rawValue + 1),
                           total: Double(OnboardingStep.allCases.count))
                    .tint(.blue)
                    .padding(.horizontal, 40)
                    .padding(.top, 20)

                Spacer()

                // Step content
                stepContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                Spacer()

                // Navigation buttons
                navigationButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
        .onChange(of: viewModel.currentStep) { _, newStep in
            if newStep == .confirmation {
                viewModel.completeOnboarding()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isComplete = true
                }
            }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .welcome:
            WelcomeStepView()
        case .meetTheGhost:
            MeetTheGhostStepView()
        case .watchPairing:
            WatchPairingStepView(viewModel: viewModel)
        case .permissions:
            PermissionsStepView(viewModel: viewModel)
        case .workoutPreferences:
            PreferencesStepView(viewModel: viewModel)
        case .absolution:
            AbsolutionStepView()
        case .confirmation:
            ConfirmationStepView()
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if viewModel.currentStep.rawValue > 0 && viewModel.currentStep != .confirmation {
                Button("Back") {
                    viewModel.previousStep()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            if viewModel.currentStep != .confirmation {
                Button(action: handleNextButton) {
                    if viewModel.isProcessing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(nextButtonTitle)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canProceed ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(!canProceed || viewModel.isProcessing)
            }
        }
    }

    private var nextButtonTitle: String {
        switch viewModel.currentStep {
        case .permissions:
            let bothGranted = viewModel.healthAuthorized && viewModel.calendarAuthorized
            let anyAttempted = viewModel.healthPermissionAttempted || viewModel.calendarPermissionAttempted
            if bothGranted {
                return "Continue"
            } else if anyAttempted {
                return "Continue Anyway"
            } else {
                return "Grant Access"
            }
        default:
            return "Continue"
        }
    }

    private var canProceed: Bool {
        switch viewModel.currentStep {
        case .welcome, .meetTheGhost:
            return true
        case .watchPairing:
            #if FREE_PROVISIONING
            return true
            #else
            return viewModel.watchPaired && viewModel.watchAppInstalled
            #endif
        case .permissions:
            return true // Can proceed after attempting
        case .workoutPreferences:
            return true
        case .absolution:
            return true
        case .confirmation:
            return false
        }
    }

    private func handleNextButton() {
        switch viewModel.currentStep {
        case .permissions where !viewModel.healthAuthorized && !viewModel.healthPermissionAttempted:
            Task {
                await viewModel.requestHealthPermissions()
                if viewModel.healthAuthorized {
                    // Also request calendar in same flow
                    await viewModel.requestCalendarPermissions()
                    if viewModel.calendarAuthorized {
                        viewModel.nextStep()
                    }
                }
            }
        case .permissions where viewModel.healthAuthorized && !viewModel.calendarAuthorized && !viewModel.calendarPermissionAttempted:
            Task {
                await viewModel.requestCalendarPermissions()
                if viewModel.calendarAuthorized {
                    viewModel.nextStep()
                }
            }
        default:
            viewModel.nextStep()
        }
    }
}

// MARK: - Step Views

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.run")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("The Ghost")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("An invisible fitness coach that learns your patterns and schedules workouts that actually happen.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "calendar", title: "Smart Scheduling", subtitle: "Works around your life")
                FeatureRow(icon: "brain.head.profile", title: "Learns You", subtitle: "Gets better over time")
                FeatureRow(icon: "bell.slash", title: "Minimal Interruptions", subtitle: "Max 1 notification per day")
            }
            .padding(.top, 20)
        }
        .padding(.horizontal, 24)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Philosophy & Trust Steps

struct MeetTheGhostStepView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "eye.slash")
                .font(.system(size: 60))
                .foregroundColor(.purple)

            Text("How The Ghost Works")
                .font(.title2).fontWeight(.bold)
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 12) {
                PhilosophyRow(icon: "moon.stars", text: "Runs silently — no constant nagging")
                PhilosophyRow(icon: "waveform.path.ecg", text: "Reads biometrics to understand readiness")
                PhilosophyRow(icon: "calendar.badge.clock", text: "Finds windows that fit your real schedule")
                PhilosophyRow(icon: "brain", text: "Gets smarter the more you use it")
            }
            .padding(.horizontal, 8)

            Divider().background(Color.gray.opacity(0.3))

            Text("Five Levels of Trust")
                .font(.subheadline).fontWeight(.semibold)
                .foregroundColor(.white)

            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { level in
                    VStack(spacing: 4) {
                        Text("\(level)")
                            .font(.caption2).fontWeight(.bold)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Color.green.opacity(0.3)))
                            .foregroundColor(.green)
                        Text(trustLevelName(level))
                            .font(.system(size: 9))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Text("Ghost starts at Level 1 and earns its way up.")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }

    private func trustLevelName(_ level: Int) -> String {
        switch level {
        case 1: return "Observer"
        case 2: return "Scheduler"
        case 3: return "Auto"
        case 4: return "Transform"
        case 5: return "Full Ghost"
        default: return ""
        }
    }
}

// MARK: - Legacy views removed: PhilosophyStepView, TrustExplanationStepView
// Merged into MeetTheGhostStepView above

private struct PhilosophyRow: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(.purple).frame(width: 28)
            Text(text).font(.subheadline).foregroundColor(.white)
        }
    }
}

// TrustLevelRow removed — trust levels now shown inline in MeetTheGhostStepView

struct WatchPairingStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "applewatch")
                .font(.system(size: 80))
                .foregroundColor(viewModel.watchPaired ? .green : .orange)

            #if FREE_PROVISIONING
            Text("Apple Watch")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("Vigor works best with an Apple Watch to track workouts and recovery. The Watch companion app will be available in a future release.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 16) {
                StatusRow(
                    title: "Watch Paired",
                    isComplete: viewModel.watchPaired,
                    action: nil
                )

                if !viewModel.watchPaired {
                    Text("No Apple Watch detected — you can still continue. Workout tracking will use iPhone sensors.")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, 20)

            Button("Refresh Status") {
                viewModel.checkWatchStatus()
            }
            .foregroundColor(.blue)

            #else
            Text("Apple Watch Required")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("Vigor uses your Apple Watch to track workouts and detect your fitness patterns. This is required for the Ghost to work effectively.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 16) {
                StatusRow(
                    title: "Watch Paired",
                    isComplete: viewModel.watchPaired,
                    action: nil
                )

                StatusRow(
                    title: "Vigor Watch App Installed",
                    isComplete: viewModel.watchAppInstalled,
                    action: viewModel.watchAppInstalled ? nil : {
                        viewModel.openWatchApp()
                    }
                )
            }
            .padding(.top, 20)

            Button("Refresh Status") {
                viewModel.checkWatchStatus()
            }
            .foregroundColor(.blue)
            #endif
        }
        .padding(.horizontal, 24)
        .onAppear {
            viewModel.checkWatchStatus()
        }
    }
}

struct StatusRow: View {
    let title: String
    let isComplete: Bool
    let action: (() -> Void)?

    var body: some View {
        HStack {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isComplete ? .green : .gray)

            Text(title)
                .foregroundColor(.white)

            Spacer()

            if let action = action, !isComplete {
                Button("Fix") {
                    action()
                }
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
    }
}

struct PermissionsStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: viewModel.healthAuthorized && viewModel.calendarAuthorized ? "checkmark.shield.fill" : "link.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(viewModel.healthAuthorized && viewModel.calendarAuthorized ? .green : .blue)

            Text("Connect Your Data")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("The Ghost needs health data and calendar access to find optimal workout windows and track your recovery.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // Health section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "heart.text.square.fill")
                        .foregroundColor(.red)
                    Text("Health & Fitness")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(.white)
                    Spacer()
                    if viewModel.healthAuthorized {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                Text("Sleep, HRV, workouts, activity")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)

            // Calendar section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.blue)
                    Text("Calendar")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(.white)
                    Spacer()
                    if viewModel.calendarAuthorized {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                Text("Read all • Write only to Vigor calendar")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)

            if viewModel.healthAuthorized && viewModel.calendarAuthorized {
                Label("All permissions granted", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.subheadline)
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Legacy views removed: HealthPermissionsStepView, CalendarPermissionsStepView
// Merged into PermissionsStepView above

struct PreferencesStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 32) {
            Text("Quick Preferences")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 8) {
                Text("Workouts per week")
                    .foregroundColor(.gray)

                Picker("Days", selection: $viewModel.workoutDaysPerWeek) {
                    ForEach(1...7, id: \.self) { days in
                        Text("\(days)").tag(days)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Preferred workout length")
                    .foregroundColor(.gray)

                Picker("Duration", selection: $viewModel.preferredDuration) {
                    Text("30 min").tag(30)
                    Text("45 min").tag(45)
                    Text("60 min").tag(60)
                    Text("90 min").tag(90)
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Primary goal")
                    .foregroundColor(.gray)

                ForEach(FitnessGoal.allCases, id: \.self) { goal in
                    Button {
                        viewModel.primaryGoal = goal
                    } label: {
                        HStack {
                            Image(systemName: goal.icon)
                                .foregroundColor(.blue)
                            Text(goal.displayName)
                                .foregroundColor(.white)
                            Spacer()
                            if viewModel.primaryGoal == goal {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(viewModel.primaryGoal == goal ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Absolution Moment Step (PRD §5.1)

struct AbsolutionStepView: View {
    @State private var insightBundle: FirstInsightBundle?
    @State private var isLoading = true
    @State private var animationProgress: CGFloat = 0

    var body: some View {
        VStack(spacing: 24) {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Analyzing your data...")
                        .font(.body)
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
            } else if let bundle = insightBundle {
                // Primary insight card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: iconFor(bundle.primaryInsight.category))
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text(bundle.primaryInsight.headline)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }

                    Text(bundle.primaryInsight.detail)
                        .font(.body)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(bundle.primaryInsight.dataPoint)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(8)
                }
                .padding(20)
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .opacity(Double(animationProgress))

                // Supporting insights
                ForEach(bundle.supportingInsights) { insight in
                    HStack(spacing: 12) {
                        Image(systemName: iconFor(insight.category))
                            .font(.body)
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(insight.headline)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            Text(insight.dataPoint)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(12)
                    .opacity(Double(animationProgress))
                }

                // First workout suggestion
                if let window = bundle.suggestedWorkoutWindow {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("YOUR FIRST BLOCK")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                            .tracking(1.2)

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(window.formattedDay) at \(window.formattedTime)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("\(window.durationMinutes) min \(window.workoutType)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "calendar.badge.plus")
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                    .opacity(Double(animationProgress))
                }

                Text(bundle.summaryLine)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .opacity(Double(animationProgress))
            }
        }
        .padding(.horizontal, 24)
        .task {
            let bundle = await FirstInsightGenerator.shared.generateInsights()
            withAnimation(.easeInOut(duration: 0.3)) {
                insightBundle = bundle
                isLoading = false
            }
            withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
                animationProgress = 1.0
            }
        }
    }

    private func iconFor(_ category: FirstInsightCategory) -> String {
        switch category {
        case .sleep: return "moon.zzz.fill"
        case .workout: return "figure.run"
        case .recovery: return "heart.fill"
        case .schedule: return "clock.fill"
        }
    }
}

struct ConfirmationStepView: View {
    @State private var animationProgress: CGFloat = 0

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: animationProgress)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.green)
                    .opacity(animationProgress >= 1 ? 1 : 0)
            }

            Text("You're All Set!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("The Ghost is already analyzing your data. Your first workout suggestion can arrive as early as today.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 8) {
                InfoRow(icon: "sparkles", text: "Today: Your first smart suggestion")
                InfoRow(icon: "hand.thumbsup", text: "You approve every workout — always in control")
                InfoRow(icon: "calendar", text: "Over time: Ghost earns more autonomy")
            }
            .padding(.top, 16)
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                animationProgress = 1.0
            }
        }
    }
}

struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            Text(text)
                .font(.callout)
                .foregroundColor(.white)
        }
    }
}
