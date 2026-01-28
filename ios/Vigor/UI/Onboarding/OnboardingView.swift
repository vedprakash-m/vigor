//
//  OnboardingView.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Polished onboarding flow for The Ghost.
//  Explains the invisible philosophy and requests permissions.
//

import SwiftUI
import HealthKit
import EventKit

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.black, Color(white: 0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            TabView(selection: $viewModel.currentPage) {
                // Page 1: Welcome
                WelcomePage()
                    .tag(OnboardingPage.welcome)

                // Page 2: The Ghost Philosophy
                PhilosophyPage()
                    .tag(OnboardingPage.philosophy)

                // Page 3: Trust System
                TrustExplanationPage()
                    .tag(OnboardingPage.trust)

                // Page 4: Health Permissions
                HealthPermissionsPage(viewModel: viewModel)
                    .tag(OnboardingPage.healthPermissions)

                // Page 5: Calendar Permissions
                CalendarPermissionsPage(viewModel: viewModel)
                    .tag(OnboardingPage.calendarPermissions)

                // Page 6: Ready
                ReadyPage(viewModel: viewModel)
                    .tag(OnboardingPage.ready)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Welcome Page

struct WelcomePage: View {
    @State private var showGhost = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Ghost icon with fade-in
            Image(systemName: "eye.slash.fill")
                .font(.system(size: 80))
                .foregroundStyle(.linearGradient(
                    colors: [.white, .gray],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .opacity(showGhost ? 1 : 0)
                .scaleEffect(showGhost ? 1 : 0.8)
                .accessibilityLabel("Ghost icon")

            VStack(spacing: 16) {
                Text("The Ghost")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Invisible Fitness Intelligence")
                    .font(.title3)
                    .foregroundColor(.gray)
            }

            Spacer()

            // Swipe hint
            VStack(spacing: 8) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.gray.opacity(0.6))

                Text("Swipe to learn more")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 60)
        }
        .onAppear {
            withAnimation(reduceMotion ? .none : .easeOut(duration: 0.8)) {
                showGhost = true
            }
        }
    }
}

// MARK: - Philosophy Page

struct PhilosophyPage: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "bell.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(.white)

            VStack(spacing: 24) {
                Text("Different by Design")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(
                        icon: "xmark.circle.fill",
                        iconColor: .red.opacity(0.8),
                        text: "No motivational notifications"
                    )

                    FeatureRow(
                        icon: "xmark.circle.fill",
                        iconColor: .red.opacity(0.8),
                        text: "No streak pressure"
                    )

                    FeatureRow(
                        icon: "xmark.circle.fill",
                        iconColor: .red.opacity(0.8),
                        text: "No guilt trips"
                    )

                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.vertical, 8)

                    FeatureRow(
                        icon: "checkmark.circle.fill",
                        iconColor: .green.opacity(0.8),
                        text: "Invisible scheduling"
                    )

                    FeatureRow(
                        icon: "checkmark.circle.fill",
                        iconColor: .green.opacity(0.8),
                        text: "Works around your life"
                    )

                    FeatureRow(
                        icon: "checkmark.circle.fill",
                        iconColor: .green.opacity(0.8),
                        text: "Earns trust over time"
                    )
                }
                .padding(.horizontal)
            }

            Spacer()
            Spacer()
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let iconColor: Color
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 24)

            Text(text)
                .font(.body)
                .foregroundColor(.white)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Trust Explanation Page

struct TrustExplanationPage: View {
    @State private var animatedPhase = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let phases = [
        ("Observer", "👁️", "Watching & learning"),
        ("Scheduler", "📅", "Suggesting times"),
        ("Auto-Scheduler", "⚡", "Placing workouts"),
        ("Transformer", "🔄", "Moving when needed"),
        ("Full Ghost", "👻", "Complete autonomy")
    ]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("The Trust System")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)

            Text("The Ghost earns autonomy through demonstrated competence")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(Array(phases.enumerated()), id: \.offset) { index, phase in
                    TrustPhaseRow(
                        emoji: phase.1,
                        name: phase.0,
                        description: phase.2,
                        isHighlighted: index <= animatedPhase
                    )
                }
            }
            .padding(.horizontal)

            // Safety breaker note
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundColor(.orange)

                Text("Delete 3 workouts in a row? Ghost immediately backs off.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .padding(.horizontal)

            Spacer()
            Spacer()
        }
        .onAppear {
            if !reduceMotion {
                animateTrust()
            } else {
                animatedPhase = phases.count - 1
            }
        }
    }

    private func animateTrust() {
        for i in 0..<phases.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    animatedPhase = i
                }
            }
        }
    }
}

struct TrustPhaseRow: View {
    let emoji: String
    let name: String
    let description: String
    let isHighlighted: Bool

    var body: some View {
        HStack(spacing: 16) {
            Text(emoji)
                .font(.title2)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.headline)
                    .foregroundColor(isHighlighted ? .white : .gray)

                Text(description)
                    .font(.caption)
                    .foregroundColor(isHighlighted ? .gray : .gray.opacity(0.5))
            }

            Spacer()

            if isHighlighted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green.opacity(0.8))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(isHighlighted ? Color.white.opacity(0.05) : Color.clear)
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name): \(description)")
    }
}

// MARK: - Health Permissions Page

struct HealthPermissionsPage: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 60))
                .foregroundStyle(.linearGradient(
                    colors: [.red, .pink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            VStack(spacing: 16) {
                Text("Recovery-Aware Scheduling")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("The Ghost uses your health data to schedule workouts when you're actually ready for them.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(alignment: .leading, spacing: 12) {
                HealthDataRow(icon: "bed.double.fill", text: "Sleep quality & duration")
                HealthDataRow(icon: "waveform.path.ecg", text: "Heart rate variability (HRV)")
                HealthDataRow(icon: "heart.fill", text: "Resting heart rate")
                HealthDataRow(icon: "figure.run", text: "Workout history")
            }
            .padding(.horizontal, 32)

            Spacer()

            Button(action: {
                viewModel.requestHealthKitAccess()
            }) {
                HStack {
                    if viewModel.isRequestingHealth {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else if viewModel.healthKitGranted {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Access Granted")
                    } else {
                        Image(systemName: "heart.fill")
                        Text("Enable Health Access")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.healthKitGranted ? Color.green : Color.red.opacity(0.8))
                .cornerRadius(16)
            }
            .disabled(viewModel.isRequestingHealth || viewModel.healthKitGranted)
            .padding(.horizontal)
            .padding(.bottom, 60)
        }
    }
}

struct HealthDataRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.red.opacity(0.8))
                .frame(width: 30)

            Text(text)
                .font(.body)
                .foregroundColor(.white)

            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Calendar Permissions Page

struct CalendarPermissionsPage: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundStyle(.linearGradient(
                    colors: [.blue, .cyan],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            VStack(spacing: 16) {
                Text("Calendar Intelligence")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("The Ghost reads ALL your calendars to find real availability, but only writes to its own calendar.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(alignment: .leading, spacing: 16) {
                CalendarFeatureRow(
                    icon: "eye.fill",
                    text: "Reads work, personal, family calendars"
                )
                CalendarFeatureRow(
                    icon: "pencil.circle.fill",
                    text: "Writes only to \"Vigor Training\""
                )
                CalendarFeatureRow(
                    icon: "shield.fill",
                    text: "Respects your sacred times"
                )
            }
            .padding(.horizontal, 32)

            Spacer()

            Button(action: {
                viewModel.requestCalendarAccess()
            }) {
                HStack {
                    if viewModel.isRequestingCalendar {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else if viewModel.calendarGranted {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Access Granted")
                    } else {
                        Image(systemName: "calendar")
                        Text("Enable Calendar Access")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.calendarGranted ? Color.green : Color.blue.opacity(0.8))
                .cornerRadius(16)
            }
            .disabled(viewModel.isRequestingCalendar || viewModel.calendarGranted)
            .padding(.horizontal)
            .padding(.bottom, 60)
        }
    }
}

struct CalendarFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue.opacity(0.8))
                .frame(width: 30)

            Text(text)
                .font(.body)
                .foregroundColor(.white)

            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Ready Page

struct ReadyPage: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showPulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            ZStack {
                // Pulse effect
                if !reduceMotion {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 200, height: 200)
                        .scaleEffect(showPulse ? 1.5 : 1)
                        .opacity(showPulse ? 0 : 0.5)
                }

                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
            }
            .onAppear {
                if !reduceMotion {
                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: false)) {
                        showPulse = true
                    }
                }
            }

            VStack(spacing: 16) {
                Text("The Ghost is Ready")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)

                Text("Starting in Observer mode. It will watch, learn, and earn your trust over time.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Permission summary
            VStack(spacing: 12) {
                PermissionStatusRow(
                    name: "Health",
                    granted: viewModel.healthKitGranted
                )
                PermissionStatusRow(
                    name: "Calendar",
                    granted: viewModel.calendarGranted
                )
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .padding(.horizontal)

            Spacer()

            Button(action: {
                viewModel.completeOnboarding()
            }) {
                Text("Begin")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
            }
            .padding(.horizontal)
            .padding(.bottom, 60)
        }
    }
}

struct PermissionStatusRow: View {
    let name: String
    let granted: Bool

    var body: some View {
        HStack {
            Text(name)
                .foregroundColor(.white)

            Spacer()

            if granted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.orange)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name): \(granted ? "Granted" : "Not granted")")
    }
}

// MARK: - View Model

enum OnboardingPage: Int, CaseIterable {
    case welcome
    case philosophy
    case trust
    case healthPermissions
    case calendarPermissions
    case ready
}

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentPage: OnboardingPage = .welcome
    @Published var healthKitGranted = false
    @Published var calendarGranted = false
    @Published var isRequestingHealth = false
    @Published var isRequestingCalendar = false

    private let healthStore = HKHealthStore()
    private let eventStore = EKEventStore()

    func requestHealthKitAccess() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        isRequestingHealth = true

        let readTypes: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .stepCount)!
        ]

        let writeTypes: Set<HKSampleType> = [
            HKObjectType.workoutType()
        ]

        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isRequestingHealth = false
                self?.healthKitGranted = success && error == nil

                if success {
                    // Auto-advance to next page
                    withAnimation {
                        self?.currentPage = .calendarPermissions
                    }
                }
            }
        }
    }

    func requestCalendarAccess() {
        isRequestingCalendar = true

        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, error in
                DispatchQueue.main.async {
                    self?.isRequestingCalendar = false
                    self?.calendarGranted = granted && error == nil

                    if granted {
                        withAnimation {
                            self?.currentPage = .ready
                        }
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                DispatchQueue.main.async {
                    self?.isRequestingCalendar = false
                    self?.calendarGranted = granted && error == nil

                    if granted {
                        withAnimation {
                            self?.currentPage = .ready
                        }
                    }
                }
            }
        }
    }

    func completeOnboarding() {
        // Mark onboarding complete
        UserDefaults.standard.set(true, forKey: "onboarding_completed")
        UserDefaults.standard.set(Date(), forKey: "onboarding_date")

        // Initialize in Observer phase
        UserDefaults.standard.set(TrustPhase.observer.rawValue, forKey: "trust_phase")
        UserDefaults.standard.set(0.0, forKey: "trust_confidence")

        // Post notification for app to show main view
        NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
    }
}

extension Notification.Name {
    static let onboardingCompleted = Notification.Name("onboardingCompleted")
}

// MARK: - Preview

#Preview {
    OnboardingView()
}
