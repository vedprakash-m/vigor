//
//  VigorAPIClient.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  API client for Azure Functions backend communication.
//  Handles authentication, retry logic, and offline resilience.
//

import Foundation
import UIKit

actor VigorAPIClient {

    // MARK: - Singleton

    static let shared = VigorAPIClient()

    // MARK: - Configuration

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // MARK: - State

    private var authToken: String?
    private var pendingOperations: [PendingOperation] = []
    private var isOnline: Bool = true

    // MARK: - Initialization

    private init() {
        #if DEBUG
        self.baseURL = URL(string: "http://localhost:7071/api")!
        #else
        self.baseURL = URL(string: "https://vigor-functions.azurewebsites.net/api")!
        #endif

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    // MARK: - Authentication

    func setAuthToken(_ token: String) {
        self.authToken = token
    }

    func clearAuthToken() {
        self.authToken = nil
    }

    // MARK: - User Profile

    func fetchUserProfile() async throws -> UserProfile {
        let response: UserProfile = try await request(
            endpoint: "user/profile",
            method: .get
        )
        return response
    }

    #if ENABLE_MSAL
    func getUserProfile(token: String) async throws -> VigorUser {
        setAuthToken(token)
        let profile = try await fetchUserProfile()
        return VigorUser(
            id: profile.id,
            email: profile.email,
            displayName: profile.displayName,
            tier: .free,
            createdAt: profile.createdAt,
            lastActiveAt: profile.updatedAt,
            preferences: nil
        )
    }

    func createUser(token: String) async throws -> VigorUser {
        setAuthToken(token)
        let profile: UserProfile = try await request(
            endpoint: "user/profile",
            method: .post,
            body: UserProfileUpdate(displayName: nil, preferences: nil)
        )
        return VigorUser(
            id: profile.id,
            email: profile.email,
            displayName: profile.displayName,
            tier: .free,
            createdAt: profile.createdAt,
            lastActiveAt: profile.updatedAt,
            preferences: nil
        )
    }
    #endif

    func updateUserProfile(_ profile: UserProfileUpdate) async throws {
        let _: EmptyResponse = try await request(
            endpoint: "user/profile",
            method: .put,
            body: profile
        )
    }

    // MARK: - Ghost State

    func syncGhostState() async throws {
        let localState = await collectLocalGhostState()

        let response: GhostSyncResponse = try await request(
            endpoint: "ghost/sync",
            method: .post,
            body: localState
        )

        // Apply any updates from server
        if let trustScore = response.trustScore {
            await TrustStateMachine.shared.applyRemoteState(
                score: trustScore,
                phase: response.trustPhase ?? .observer
            )
        }
    }

    func reportHealthStatus(_ health: GhostHealthSnapshot) async throws {
        let _: EmptyResponse = try await request(
            endpoint: "ghost/health",
            method: .post,
            body: health
        )
    }

    // MARK: - Workouts

    func recordWorkout(_ workout: WorkoutRecord) async throws {
        let operation = PendingOperation(
            type: .recordWorkout,
            payload: try encoder.encode(workout),
            timestamp: Date()
        )

        do {
            let _: EmptyResponse = try await request(
                endpoint: "workouts",
                method: .post,
                body: workout
            )
        } catch {
            // Queue for later sync
            pendingOperations.append(operation)
            throw error
        }
    }

    func getWorkoutHistory(days: Int = 30) async throws -> [WorkoutRecord] {
        let response: [WorkoutRecord] = try await request(
            endpoint: "workouts?days=\(days)",
            method: .get
        )
        return response
    }

    // MARK: - Training Blocks

    func syncTrainingBlocks(_ blocks: [TrainingBlockDTO]) async throws -> [TrainingBlockDTO] {
        let response: TrainingBlockSyncResponse = try await request(
            endpoint: "blocks/sync",
            method: .post,
            body: TrainingBlockSyncRequest(blocks: blocks)
        )
        return response.blocks
    }

    func reportBlockOutcome(_ outcome: BlockOutcome) async throws {
        let _: EmptyResponse = try await request(
            endpoint: "blocks/outcome",
            method: .post,
            body: outcome
        )
    }

    // MARK: - Trust Events

    func recordTrustEvent(_ event: TrustEventDTO) async throws {
        let _: EmptyResponse = try await request(
            endpoint: "trust/event",
            method: .post,
            body: event
        )
    }

    func getTrustHistory() async throws -> TrustHistoryResponse {
        let response: TrustHistoryResponse = try await request(
            endpoint: "trust/history",
            method: .get
        )
        return response
    }

    // MARK: - AI Coaching

    func getWorkoutRecommendation(context: WorkoutContext) async throws -> WorkoutRecommendation {
        let response: WorkoutRecommendation = try await request(
            endpoint: "coach/recommend",
            method: .post,
            body: context
        )
        return response
    }

    func getRecoveryAssessment() async throws -> RecoveryAssessment {
        let response: RecoveryAssessment = try await request(
            endpoint: "coach/recovery",
            method: .get
        )
        return response
    }

    func generateWorkout(
        window: TimeWindow,
        preferences: WorkoutPreferences,
        phenomeSnapshot: PhenomeSnapshot
    ) async throws -> GeneratedWorkout {
        struct GenerateWorkoutRequest: Codable {
            let startTime: Date
            let endTime: Date
            let durationMinutes: Int
        }
        let req = GenerateWorkoutRequest(
            startTime: window.start,
            endTime: window.end,
            durationMinutes: Int(window.duration / 60)
        )
        let response: GeneratedWorkout = try await request(
            endpoint: "coach/generate-workout",
            method: .post,
            body: req
        )
        return response
    }

    // MARK: - Device Registration

    func registerDevice(_ device: DeviceRegistration) async throws {
        let _: EmptyResponse = try await request(
            endpoint: "devices/register",
            method: .post,
            body: device
        )
    }

    func registerPushToken(_ token: String) async throws {
        let _: EmptyResponse = try await request(
            endpoint: "devices/push-token",
            method: .post,
            body: PushTokenRequest(token: token)
        )
    }

    // MARK: - Pending Operations

    func processPendingOperations() async throws {
        let operations = pendingOperations
        pendingOperations.removeAll()

        for operation in operations {
            do {
                try await processOperation(operation)
            } catch {
                // Re-queue if still failing
                pendingOperations.append(operation)
            }
        }
    }

    private func processOperation(_ operation: PendingOperation) async throws {
        switch operation.type {
        case .recordWorkout:
            let workout = try decoder.decode(WorkoutRecord.self, from: operation.payload)
            let _: EmptyResponse = try await request(
                endpoint: "workouts",
                method: .post,
                body: workout
            )

        case .recordTrustEvent:
            let event = try decoder.decode(TrustEventDTO.self, from: operation.payload)
            let _: EmptyResponse = try await request(
                endpoint: "trust/event",
                method: .post,
                body: event
            )

        case .syncBlocks:
            let blocks = try decoder.decode([TrainingBlockDTO].self, from: operation.payload)
            let _ = try await syncTrainingBlocks(blocks)
        }
    }

    // MARK: - Network Request

    private func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        body: Encodable? = nil
    ) async throws -> T {
        var url = baseURL.appendingPathComponent(endpoint)

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200..<300:
            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }
            return try decoder.decode(T.self, from: data)

        case 401:
            throw NetworkError.unauthorized

        case 403:
            throw NetworkError.forbidden

        case 404:
            throw NetworkError.notFound

        case 429:
            throw NetworkError.rateLimited

        case 500..<600:
            throw NetworkError.serverError(httpResponse.statusCode)

        default:
            throw NetworkError.httpError(httpResponse.statusCode)
        }
    }

    // MARK: - Helper Methods

    private func collectLocalGhostState() async -> GhostStateDTO {
        let trustMachine = await TrustStateMachine.shared
        let trustScore = await trustMachine.trustScore
        let trustPhase = await trustMachine.currentPhase
        let wakeStats = await SilentPushReceiver.shared.getWakeStatistics()
        let deviceId = await UIDevice.current.identifierForVendor?.uuidString ?? "unknown"

        return GhostStateDTO(
            trustScore: trustScore,
            trustPhase: String(trustPhase.rawValue),
            healthMode: "healthy",
            lastWakeTime: wakeStats.lastWakeTime,
            deviceId: deviceId
        )
    }
}

// MARK: - HTTP Method

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - Network Error

enum NetworkError: LocalizedError {
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case rateLimited
    case serverError(Int)
    case httpError(Int)
    case noConnection
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Authentication required"
        case .forbidden:
            return "Access denied"
        case .notFound:
            return "Resource not found"
        case .rateLimited:
            return "Too many requests"
        case .serverError(let code):
            return "Server error (\(code))"
        case .httpError(let code):
            return "HTTP error (\(code))"
        case .noConnection:
            return "No internet connection"
        case .timeout:
            return "Request timed out"
        }
    }
}

// MARK: - Empty Response

struct EmptyResponse: Decodable {}

// MARK: - Pending Operation

struct PendingOperation {
    enum OperationType: String {
        case recordWorkout
        case recordTrustEvent
        case syncBlocks
    }

    let type: OperationType
    let payload: Data
    let timestamp: Date
}
