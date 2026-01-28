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
    case watchPairing
    case healthPermissions
    case calendarPermissions
    case workoutPreferences
    case confirmation

    var title: String {
        switch self {
        case .welcome: return "Welcome to Vigor"
        case .watchPairing: return "Connect Your Watch"
        case .healthPermissions: return "Health Access"
        case .calendarPermissions: return "Calendar Access"
        case .workoutPreferences: return "Your Preferences"
        case .confirmation: return "Ready to Go"
        }
    }

    var subtitle: String {
        switch self {
        case .welcome:
            return "Your invisible fitness coach"
        case .watchPairing:
            return "Apple Watch is required for Vigor"
        case .healthPermissions:
            return "We'll learn your patterns to optimize your schedule"
        case .calendarPermissions:
            return "We'll find the perfect workout windows"
        case .workoutPreferences:
            return "Just a few quick questions"
        case .confirmation:
            return "The Ghost will start learning"
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

        let session = WCSession.default
        #if os(iOS)
        watchPaired = session.isPaired
        watchAppInstalled = session.isWatchAppInstalled
        #endif
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
        defer { isProcessing = false }

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
            healthAuthorized = true
        } catch {
            self.error = .healthAuthorizationFailed
        }
    }

    // MARK: - Calendar Permissions

    func requestCalendarPermissions() async {
        isProcessing = true
        defer { isProcessing = false }

        if #available(iOS 17.0, *) {
            let granted = try? await eventStore.requestFullAccessToEvents()
            calendarAuthorized = granted ?? false
        } else {
            let granted = try? await eventStore.requestAccess(to: .event)
            calendarAuthorized = granted ?? false
        }

        if !calendarAuthorized {
            error = .calendarAuthorizationFailed
        }
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
                try? await HealthKitObserver.shared.startQuickImport()
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
        case .watchPairing:
            WatchPairingStepView(viewModel: viewModel)
        case .healthPermissions:
            HealthPermissionsStepView(viewModel: viewModel)
        case .calendarPermissions:
            CalendarPermissionsStepView(viewModel: viewModel)
        case .workoutPreferences:
            PreferencesStepView(viewModel: viewModel)
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
        case .healthPermissions:
            return viewModel.healthAuthorized ? "Continue" : "Grant Access"
        case .calendarPermissions:
            return viewModel.calendarAuthorized ? "Continue" : "Grant Access"
        default:
            return "Continue"
        }
    }

    private var canProceed: Bool {
        switch viewModel.currentStep {
        case .welcome:
            return true
        case .watchPairing:
            return viewModel.watchPaired && viewModel.watchAppInstalled
        case .healthPermissions:
            return true // Can proceed after attempting
        case .calendarPermissions:
            return true // Can proceed after attempting
        case .workoutPreferences:
            return true
        case .confirmation:
            return false
        }
    }

    private func handleNextButton() {
        switch viewModel.currentStep {
        case .healthPermissions where !viewModel.healthAuthorized:
            Task { await viewModel.requestHealthPermissions() }
        case .calendarPermissions where !viewModel.calendarAuthorized:
            Task { await viewModel.requestCalendarPermissions() }
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

struct WatchPairingStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "applewatch")
                .font(.system(size: 80))
                .foregroundColor(viewModel.watchPaired ? .green : .orange)

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

struct HealthPermissionsStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 80))
                .foregroundColor(viewModel.healthAuthorized ? .green : .red)

            Text("Health Access")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("We'll read your sleep, heart rate variability, and workout data to understand your recovery and optimize scheduling.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 12) {
                DataAccessRow(icon: "bed.double.fill", title: "Sleep Analysis")
                DataAccessRow(icon: "heart.fill", title: "Heart Rate & HRV")
                DataAccessRow(icon: "figure.walk", title: "Workouts & Activity")
            }
            .padding(.top, 16)

            if viewModel.healthAuthorized {
                Label("Access Granted", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 24)
    }
}

struct DataAccessRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            Text(title)
                .foregroundColor(.white)
        }
    }
}

struct CalendarPermissionsStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 80))
                .foregroundColor(viewModel.calendarAuthorized ? .green : .blue)

            Text("Calendar Access")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("We'll read your calendars to find available time slots and write workout blocks to a dedicated 'Vigor Training' calendar.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "eye")
                        .foregroundColor(.blue)
                    Text("Read ALL your calendars")
                        .foregroundColor(.white)
                }

                HStack {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                    Text("Write ONLY to Vigor calendar")
                        .foregroundColor(.white)
                }
            }
            .padding(.top, 16)

            if viewModel.calendarAuthorized {
                Label("Access Granted", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 24)
    }
}

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

            Text("The Ghost is now in Observer mode. Over the next week, it will learn your patterns without making any changes to your calendar.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 8) {
                InfoRow(icon: "eye", text: "Week 1-2: Observing your patterns")
                InfoRow(icon: "lightbulb", text: "Week 3+: Suggesting workout times")
                InfoRow(icon: "calendar", text: "Later: Automatic scheduling (with permission)")
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
