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
        Group {
            if !authManager.isAuthenticated {
                // Not authenticated - show sign in
                SignInView()
            } else if showOnboarding {
                // First time user - show onboarding flow
                OnboardingView(isComplete: $showOnboarding)
            } else if let triage = triageRequest {
                // Missed workout needs disambiguation
                TriageCardView(request: triage) { reason in
                    Task {
                        await handleTriageResponse(reason: reason)
                    }
                }
            } else {
                // Main app experience - Today View
                MainTabView()
            }
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
        // Check if user has completed onboarding
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        showOnboarding = !hasCompletedOnboarding
    }

    private func handleTriageResponse(reason: MissedWorkoutReason) async {
        guard let request = triageRequest else { return }

        await FailureDisambiguator.shared.recordTriageResponse(
            blockId: request.blockId,
            reason: reason
        )

        triageRequest = nil
        ghostEngine.clearPendingTriageRequest()
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

#Preview {
    ContentView()
        .environmentObject(AuthManager.shared)
        .environmentObject(GhostEngine.shared)
        .environmentObject(PhenomeCoordinator.shared)
        .environmentObject(TrustStateMachine.shared)
}
