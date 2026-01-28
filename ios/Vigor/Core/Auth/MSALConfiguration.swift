//
//  MSALConfiguration.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  MSAL configuration for Microsoft Entra ID authentication.
//

import Foundation

struct MSALConfiguration {

    // MARK: - Singleton

    static let shared = MSALConfiguration()

    // MARK: - Configuration Values

    /// Azure AD Client ID (Application ID)
    let clientId: String

    /// Redirect URI for iOS app
    let redirectUri: String

    /// Azure AD Authority URL
    let authorityURL: URL

    /// API Scopes to request
    let scopes: [String]

    /// Backend API Base URL
    let apiBaseURL: URL

    // MARK: - Initialization

    private init() {
        // Load from Info.plist or environment
        guard let clientId = Bundle.main.object(forInfoDictionaryKey: "AZURE_AD_CLIENT_ID") as? String,
              !clientId.isEmpty else {
            fatalError("AZURE_AD_CLIENT_ID not configured in Info.plist")
        }

        guard let tenantId = Bundle.main.object(forInfoDictionaryKey: "AZURE_AD_TENANT_ID") as? String,
              !tenantId.isEmpty else {
            fatalError("AZURE_AD_TENANT_ID not configured in Info.plist")
        }

        guard let apiBaseURLString = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
              let apiURL = URL(string: apiBaseURLString) else {
            fatalError("API_BASE_URL not configured in Info.plist")
        }

        self.clientId = clientId
        self.apiBaseURL = apiURL

        // Construct redirect URI using bundle identifier
        let bundleId = Bundle.main.bundleIdentifier ?? "com.vigor.app"
        self.redirectUri = "msauth.\(bundleId)://auth"

        // Construct authority URL
        self.authorityURL = URL(string: "https://login.microsoftonline.com/\(tenantId)")!

        // Define scopes
        self.scopes = [
            "openid",
            "profile",
            "email",
            "offline_access",
            "User.Read",
            "Calendars.ReadWrite",  // For Shadow Sync
            "\(apiBaseURLString)/.default"
        ]
    }
}

// MARK: - Debug Configuration

#if DEBUG
extension MSALConfiguration {
    /// Override for testing with development credentials
    static func testConfiguration() -> MSALConfiguration {
        // Use test configuration
        return .shared
    }
}
#endif
