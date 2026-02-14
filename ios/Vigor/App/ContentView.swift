//
//  ContentView.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Root content view that handles authentication state and navigation.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var ghostEngine: GhostEngine
    @EnvironmentObject var phenomeCoordinator: PhenomeCoordinator

    @State private var showOnboarding = false
    @State private var triageRequest: MissedBlockTriageRequest?

    var body: some View {
        ZStack {
            #if ENABLE_MSAL
            if !authManager.isAuthenticated {
                SignInView()
            } else if showOnboarding {
                OnboardingFlowView(isComplete: $showOnboarding)
            } else if let triage = triageRequest {
                TriageCardView(card: triage.toCardData()) { action in
                    Task {
                        await handleTriageAction(action)
                    }
                }
            } else {
                MainTabView()
            }
            #else
            if showOnboarding {
                OnboardingFlowView(isComplete: $showOnboarding)
            } else if let triage = triageRequest {
                TriageCardView(card: triage.toCardData()) { action in
                    Task {
                        await handleTriageAction(action)
                    }
                }
            } else {
                MainTabView()
            }
            #endif
        }
        .onAppear {
            checkOnboardingStatus()
        }
        .onReceive(ghostEngine.$pendingTriageRequest) { request in
            // Show triage card on app open after missed workout
            if request != nil {
                triageRequest = request
            }
        }
    }

    private func checkOnboardingStatus() {
        // Check if user has completed onboarding (OnboardingFlow writes "onboarding_completed")
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "onboarding_completed")
        showOnboarding = !hasCompletedOnboarding
    }

    private func handleTriageAction(_ action: TriageAction) async {
        guard let request = triageRequest else { return }

        // Map TriageAction to MissedWorkoutReason
        let reason: MissedWorkoutReason
        switch action {
        case .reject, .dismiss, .skip:
            reason = .tooTired
        case .accept, .startWorkout, .markComplete, .confirm:
            reason = .unknown
        case .correct:
            reason = .wrongWorkout
        case .viewDetails, .reschedule:
            reason = .badTimeSlot
        }

        await FailureDisambiguator.shared.recordTriageResponse(
            blockId: request.blockId,
            reason: reason
        )

        triageRequest = nil
        ghostEngine.clearPendingTriageRequest()
    }
}

// MARK: - MissedBlockTriageRequest Extension

extension MissedBlockTriageRequest {
    func toCardData() -> TriageCardData {
        TriageCardData(
            id: id,
            workoutType: workoutType,
            scheduledTime: blockTime,
            duration: 45,
            recoveryScore: 75,
            recoveryReason: nil,
            ghostInsight: nil,
            alternativeSlots: []
        )
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "calendar")
                }
                .tag(0)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(1)
        }
    }
}

// MARK: - Sign In View

#if ENABLE_MSAL
struct SignInView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var isSigningIn = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Logo and tagline
            VStack(spacing: 16) {
                Image(systemName: "figure.run")
                    .font(.system(size: 80))
                    .foregroundStyle(.tint)

                Text("Vigor")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("The Ghost that handles your fitness")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Sign in button
            VStack(spacing: 16) {
                Button {
                    signIn()
                } label: {
                    HStack {
                        if isSigningIn {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "person.badge.key")
                        }
                        Text("Sign in with Microsoft")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isSigningIn)

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    private func signIn() {
        isSigningIn = true
        errorMessage = nil

        Task {
            do {
                try await authManager.signIn()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSigningIn = false
        }
    }
}
#endif // ENABLE_MSAL

#Preview {
    ContentView()
        .environmentObject(AuthManager.shared)
        .environmentObject(GhostEngine.shared)
        .environmentObject(PhenomeCoordinator.shared)
        .environmentObject(TrustStateMachine.shared)
}
