//
//  AuthManager.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Microsoft Entra ID (MSAL) authentication for iOS.
//  Per Task 1.2
//

import Foundation
import MSAL
import Combine

@MainActor
final class AuthManager: ObservableObject {

    // MARK: - Singleton

    static let shared = AuthManager()

    // MARK: - Published State

    @Published private(set) var isAuthenticated = false
    @Published private(set) var currentUser: VigorUser?
    @Published private(set) var isLoading = false
    @Published var error: AuthError?

    // MARK: - MSAL Client

    private var msalClient: MSALPublicClientApplication?
    private var currentAccount: MSALAccount?

    // MARK: - Configuration

    private let config = MSALConfiguration.shared

    // MARK: - Initialization

    private init() {
        setupMSALClient()
        checkExistingSession()
    }

    private func setupMSALClient() {
        do {
            let authority = try MSALAADAuthority(url: config.authorityURL)

            let msalConfig = MSALPublicClientApplicationConfig(
                clientId: config.clientId,
                redirectUri: config.redirectUri,
                authority: authority
            )

            msalClient = try MSALPublicClientApplication(configuration: msalConfig)
        } catch {
            self.error = .configurationError(error.localizedDescription)
        }
    }

    // MARK: - Authentication

    func signIn() async throws {
        guard let client = msalClient else {
            throw AuthError.notConfigured
        }

        isLoading = true
        defer { isLoading = false }

        // Get the current window scene for presenting the auth flow
        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = await windowScene.windows.first?.rootViewController else {
            throw AuthError.noViewController
        }

        let webviewParameters = MSALWebviewParameters(authPresentationViewController: rootViewController)
        let interactiveParameters = MSALInteractiveTokenParameters(
            scopes: config.scopes,
            webviewParameters: webviewParameters
        )

        do {
            let result = try await client.acquireToken(with: interactiveParameters)
            await handleAuthResult(result)
        } catch let msalError as NSError {
            if msalError.domain == MSALErrorDomain {
                switch msalError.code {
                case MSALError.userCanceled.rawValue:
                    throw AuthError.userCancelled
                case MSALError.interactionRequired.rawValue:
                    throw AuthError.interactionRequired
                default:
                    throw AuthError.msalError(msalError.localizedDescription)
                }
            }
            throw AuthError.unknown(msalError.localizedDescription)
        }
    }

    func signOut() async {
        guard let client = msalClient, let account = currentAccount else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            // Remove account from MSAL cache
            try client.remove(account)

            // Clear local state
            currentAccount = nil
            currentUser = nil
            isAuthenticated = false

            // Clear stored tokens
            UserDefaults.standard.removeObject(forKey: "cachedAccessToken")

        } catch {
            self.error = .signOutError(error.localizedDescription)
        }
    }

    // MARK: - Token Management

    func getAccessToken() async throws -> String {
        guard let client = msalClient else {
            throw AuthError.notConfigured
        }

        // Try to get token silently first
        if let account = currentAccount {
            let silentParameters = MSALSilentTokenParameters(
                scopes: config.scopes,
                account: account
            )

            do {
                let result = try await client.acquireTokenSilent(with: silentParameters)
                return result.accessToken
            } catch let error as NSError {
                if error.code == MSALError.interactionRequired.rawValue {
                    // Token expired, need interactive refresh
                    try await signIn()
                    return try await getAccessToken()
                }
                throw AuthError.tokenError(error.localizedDescription)
            }
        }

        throw AuthError.notAuthenticated
    }

    // MARK: - Session Management

    private func checkExistingSession() {
        guard let client = msalClient else { return }

        do {
            let accounts = try client.allAccounts()
            if let account = accounts.first {
                currentAccount = account

                // Try to get token silently to verify session
                Task {
                    do {
                        let token = try await getAccessToken()
                        await loadUserProfile(token: token)
                        isAuthenticated = true
                    } catch {
                        // Session expired, user needs to sign in again
                        currentAccount = nil
                        isAuthenticated = false
                    }
                }
            }
        } catch {
            // No cached accounts
            isAuthenticated = false
        }
    }

    private func handleAuthResult(_ result: MSALResult) async {
        currentAccount = result.account
        isAuthenticated = true

        // Store token for API calls
        UserDefaults.standard.set(result.accessToken, forKey: "cachedAccessToken")

        // Load user profile
        await loadUserProfile(token: result.accessToken)

        // Register device token with backend
        await registerDevice()
    }

    private func loadUserProfile(token: String) async {
        do {
            let user = try await VigorAPIClient.shared.getUserProfile(token: token)
            currentUser = user
        } catch {
            // Create user if doesn't exist
            do {
                let newUser = try await VigorAPIClient.shared.createUser(token: token)
                currentUser = newUser
            } catch {
                self.error = .profileError(error.localizedDescription)
            }
        }
    }

    private func registerDevice() async {
        // Register APNs token with backend for silent push
        // Token is registered in AppDelegate when received from APNs
    }

    // MARK: - URL Handling

    func handleAuthCallback(url: URL) -> Bool {
        guard let client = msalClient else { return false }
        return MSALPublicClientApplication.handleMSALResponse(
            url,
            sourceApplication: nil
        )
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case notConfigured
    case noViewController
    case userCancelled
    case interactionRequired
    case notAuthenticated
    case tokenError(String)
    case msalError(String)
    case signOutError(String)
    case profileError(String)
    case configurationError(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Authentication not configured"
        case .noViewController:
            return "Cannot present authentication"
        case .userCancelled:
            return "Sign in was cancelled"
        case .interactionRequired:
            return "Please sign in again"
        case .notAuthenticated:
            return "Not authenticated"
        case .tokenError(let message):
            return "Token error: \(message)"
        case .msalError(let message):
            return "Authentication error: \(message)"
        case .signOutError(let message):
            return "Sign out error: \(message)"
        case .profileError(let message):
            return "Profile error: \(message)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - Vigor User

struct VigorUser: Codable, Identifiable {
    let id: String
    let email: String
    let displayName: String
    let tier: UserTier
    let createdAt: Date
    var lastActiveAt: Date
    var preferences: UserPreferences?

    enum UserTier: String, Codable {
        case free = "free"
        case premium = "premium"
        case enterprise = "enterprise"
    }
}

struct UserPreferences: Codable {
    var preferredWorkoutDays: [Int]       // 1-7 (Sun-Sat)
    var preferredWorkoutTime: String      // "morning", "afternoon", "evening"
    var availableEquipment: [String]
    var fitnessGoals: [String]
    var injuriesOrLimitations: [String]
}
