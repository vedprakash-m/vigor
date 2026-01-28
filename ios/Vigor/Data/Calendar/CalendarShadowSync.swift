//
//  CalendarShadowSync.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Shadow Sync: Write "Busy" blocks back to corporate Exchange/Outlook calendars
//  to prevent colleagues from double-booking workout times.
//
//  Per Task 1.4b - Corporate Resilience
//

import Foundation
import MSAL

actor CalendarShadowSync {

    // MARK: - Singleton

    static let shared = CalendarShadowSync()

    // MARK: - State

    private var isEnabled = true
    private var lastSyncError: Error?
    private var mdmFallbackActive = false

    // MARK: - MS Graph Client

    private var accessToken: String?

    // MARK: - Initialization

    private init() {
        Task {
            await checkMDMStatus()
        }
    }

    // MARK: - Sync Operations

    func syncToExchange(block: TrainingBlock) async {
        guard isEnabled && !mdmFallbackActive else { return }

        do {
            let token = try await getGraphToken()

            // Create "Busy" event in primary Exchange calendar
            let event = MSGraphEvent(
                subject: "Busy",
                start: block.startTime,
                end: block.endTime,
                showAs: .busy,
                isPrivate: true,
                vigorBlockId: block.id
            )

            try await createEvent(event, token: token)

        } catch {
            lastSyncError = error
            await handleSyncError(error)
        }
    }

    func removeFromExchange(blockId: String) async {
        guard isEnabled && !mdmFallbackActive else { return }

        do {
            let token = try await getGraphToken()

            // Find and delete the corresponding event
            if let eventId = await findEventId(for: blockId, token: token) {
                try await deleteEvent(eventId, token: token)
            }

        } catch {
            lastSyncError = error
            // Silent failure for delete - not critical
        }
    }

    // MARK: - MS Graph API Calls

    private func createEvent(_ event: MSGraphEvent, token: String) async throws {
        let url = URL(string: "https://graph.microsoft.com/v1.0/me/events")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "subject": event.subject,
            "start": [
                "dateTime": ISO8601DateFormatter().string(from: event.start),
                "timeZone": TimeZone.current.identifier
            ],
            "end": [
                "dateTime": ISO8601DateFormatter().string(from: event.end),
                "timeZone": TimeZone.current.identifier
            ],
            "showAs": event.showAs.graphValue,
            "sensitivity": event.isPrivate ? "private" : "normal",
            "categories": ["Vigor"],
            "body": [
                "contentType": "text",
                "content": "Vigor Training Block - ID: \(event.vigorBlockId)"
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw ShadowSyncError.createFailed
        }
    }

    private func deleteEvent(_ eventId: String, token: String) async throws {
        let url = URL(string: "https://graph.microsoft.com/v1.0/me/events/\(eventId)")!

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 204 else {
            throw ShadowSyncError.deleteFailed
        }
    }

    private func findEventId(for blockId: String, token: String) async -> String? {
        let url = URL(string: "https://graph.microsoft.com/v1.0/me/events?\$filter=categories/any(c:c eq 'Vigor')&\$select=id,body")!

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let value = json["value"] as? [[String: Any]] {
                for event in value {
                    if let body = event["body"] as? [String: Any],
                       let content = body["content"] as? String,
                       content.contains(blockId) {
                        return event["id"] as? String
                    }
                }
            }
        } catch {
            // Silent failure
        }

        return nil
    }

    // MARK: - Token Management

    private func getGraphToken() async throws -> String {
        if let token = accessToken {
            return token
        }

        // Get token from AuthManager
        let token = try await AuthManager.shared.getAccessToken()
        accessToken = token
        return token
    }

    // MARK: - MDM Handling

    private func checkMDMStatus() async {
        // Check if MDM blocks Graph API access
        do {
            let token = try await getGraphToken()

            // Test API access
            let url = URL(string: "https://graph.microsoft.com/v1.0/me")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 403 {
                    // MDM is blocking - activate fallback
                    await activateMDMFallback()
                }
            }
        } catch {
            // Can't determine MDM status - assume not blocked
        }
    }

    private func activateMDMFallback() async {
        mdmFallbackActive = true

        // Notify user that shadow sync is unavailable
        await NotificationOrchestrator.shared.sendMDMFallbackNotice()
    }

    // MARK: - Error Handling

    private func handleSyncError(_ error: Error) async {
        if let syncError = error as? ShadowSyncError {
            switch syncError {
            case .mdmBlocked:
                await activateMDMFallback()
            case .tokenExpired:
                accessToken = nil
            default:
                break
            }
        }
    }

    // MARK: - Configuration

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }

    var isMDMFallbackActive: Bool {
        mdmFallbackActive
    }
}

// MARK: - MS Graph Event

struct MSGraphEvent {
    let subject: String
    let start: Date
    let end: Date
    let showAs: ShowAs
    let isPrivate: Bool
    let vigorBlockId: String

    enum ShowAs {
        case free
        case tentative
        case busy
        case outOfOffice

        var graphValue: String {
            switch self {
            case .free: return "free"
            case .tentative: return "tentative"
            case .busy: return "busy"
            case .outOfOffice: return "oof"
            }
        }
    }
}

// MARK: - Shadow Sync Error

enum ShadowSyncError: LocalizedError {
    case createFailed
    case deleteFailed
    case tokenExpired
    case mdmBlocked
    case networkError

    var errorDescription: String? {
        switch self {
        case .createFailed:
            return "Failed to create calendar event"
        case .deleteFailed:
            return "Failed to delete calendar event"
        case .tokenExpired:
            return "Authentication token expired"
        case .mdmBlocked:
            return "Calendar access blocked by corporate policy"
        case .networkError:
            return "Network error during sync"
        }
    }
}
