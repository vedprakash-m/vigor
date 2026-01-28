//
//  HealthKitObserver.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  HealthKit integration for reading sleep, HRV, workouts, and other health data.
//  Implements progressive 7-day + 90-day import with savepoints.
//
//  Per Task 1.3
//

import Foundation
import HealthKit
import Combine

@MainActor
final class HealthKitObserver: ObservableObject {

    // MARK: - Singleton

    static let shared = HealthKitObserver()

    // MARK: - Published State

    @Published private(set) var isAuthorized = false
    @Published private(set) var importProgress: Double = 0.0
    @Published private(set) var lastDetectedWorkout: DetectedWorkout?
    @Published private(set) var lastSyncDate: Date?

    // MARK: - HealthKit Store

    private let healthStore = HKHealthStore()

    // MARK: - Import State

    private var importState: HealthKitImportState?

    // MARK: - Data Types

    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()

        // Sleep
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepType)
        }

        // HRV
        if let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            types.insert(hrvType)
        }

        // Resting Heart Rate
        if let restingHRType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) {
            types.insert(restingHRType)
        }

        // Steps
        if let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount) {
            types.insert(stepsType)
        }

        // Active Energy
        if let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeEnergyType)
        }

        // Workouts
        types.insert(HKObjectType.workoutType())

        return types
    }

    // MARK: - Initialization

    private init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        try await healthStore.requestAuthorization(toShare: [], read: readTypes)

        isAuthorized = true

        // Setup background delivery
        await setupBackgroundDelivery()
    }

    private func checkAuthorizationStatus() {
        // Check if we have authorization for key types
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            isAuthorized = false
            return
        }

        let status = healthStore.authorizationStatus(for: sleepType)
        isAuthorized = status == .sharingAuthorized
    }

    // MARK: - Background Delivery

    private func setupBackgroundDelivery() async {
        // Workouts - immediate delivery
        if let workoutType = HKObjectType.workoutType() as? HKSampleType {
            do {
                try await healthStore.enableBackgroundDelivery(
                    for: workoutType,
                    frequency: .immediate
                )
            } catch {
                // Log but don't fail - this is an optimization
            }
        }

        // Sleep - hourly delivery
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            do {
                try await healthStore.enableBackgroundDelivery(
                    for: sleepType,
                    frequency: .hourly
                )
            } catch {
                // Log but don't fail
            }
        }
    }

    // MARK: - Initial Import

    func performInitialImport() async throws {
        importProgress = 0.0

        // Phase 1: Import last 7 days (quick start)
        try await importData(daysBack: 7)
        importProgress = 0.3

        // Phase 2: Import remaining 83 days (background)
        try await importData(from: 7, to: 90)
        importProgress = 1.0

        // Save import completion
        importState = HealthKitImportState(
            lastFullImport: Date(),
            daysImported: 90
        )
    }

    private func importData(daysBack: Int) async throws {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -daysBack, to: endDate)!

        try await importData(startDate: startDate, endDate: endDate)
    }

    private func importData(from startDaysBack: Int, to endDaysBack: Int) async throws {
        let endDate = Calendar.current.date(byAdding: .day, value: -startDaysBack, to: Date())!
        let startDate = Calendar.current.date(byAdding: .day, value: -endDaysBack, to: Date())!

        try await importData(startDate: startDate, endDate: endDate)
    }

    private func importData(startDate: Date, endDate: Date) async throws {
        // Import sleep data
        let sleepData = try await fetchSleepData(from: startDate, to: endDate)
        await PhenomeCoordinator.shared.importSleepData(sleepData)

        // Import HRV data
        let hrvData = try await fetchHRVData(from: startDate, to: endDate)
        await PhenomeCoordinator.shared.importHRVData(hrvData)

        // Import workouts
        let workouts = try await fetchWorkouts(from: startDate, to: endDate)
        await PhenomeCoordinator.shared.importWorkouts(workouts)

        lastSyncDate = Date()
    }

    // MARK: - Sleep Data

    func fetchLastNightSleep() async throws -> SleepData {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -1, to: endDate)!

        let sleepRecords = try await fetchSleepData(from: startDate, to: Date())

        guard !sleepRecords.isEmpty else {
            return SleepData(totalHours: 0, qualityScore: 0, stages: [])
        }

        return sleepRecords.last!
    }

    private func fetchSleepData(from startDate: Date, to endDate: Date) async throws -> [SleepData] {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.typeNotAvailable
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKCategorySample], Error>) in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples as? [HKCategorySample] ?? [])
                }
            }
            healthStore.execute(query)
        }

        return aggregateSleepSamples(samples)
    }

    private func aggregateSleepSamples(_ samples: [HKCategorySample]) -> [SleepData] {
        // Group samples by night
        let calendar = Calendar.current
        var nightlyData: [Date: [HKCategorySample]] = [:]

        for sample in samples {
            let nightDate = calendar.startOfDay(for: sample.startDate)
            nightlyData[nightDate, default: []].append(sample)
        }

        return nightlyData.map { (date, samples) in
            let totalSeconds = samples.reduce(0.0) { total, sample in
                total + sample.endDate.timeIntervalSince(sample.startDate)
            }
            let totalHours = totalSeconds / 3600

            // Calculate quality score based on sleep stages
            let qualityScore = calculateSleepQuality(samples: samples)

            let stages = samples.compactMap { sample -> SleepStage? in
                guard let value = HKCategoryValueSleepAnalysis(rawValue: sample.value) else {
                    return nil
                }
                return SleepStage(
                    type: mapSleepValue(value),
                    startDate: sample.startDate,
                    endDate: sample.endDate
                )
            }

            return SleepData(
                totalHours: totalHours,
                qualityScore: qualityScore,
                stages: stages
            )
        }.sorted { $0.stages.first?.startDate ?? Date.distantPast < $1.stages.first?.startDate ?? Date.distantPast }
    }

    private func calculateSleepQuality(samples: [HKCategorySample]) -> Double {
        // Basic quality calculation based on total time and continuity
        let totalSeconds = samples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
        let hours = totalSeconds / 3600

        // Score based on hours (optimal 7-9 hours)
        var score: Double = 0
        if hours >= 7 && hours <= 9 {
            score = 100
        } else if hours >= 6 || hours <= 10 {
            score = 80
        } else if hours >= 5 || hours <= 11 {
            score = 60
        } else {
            score = 40
        }

        return score
    }

    private func mapSleepValue(_ value: HKCategoryValueSleepAnalysis) -> SleepStageType {
        switch value {
        case .inBed: return .inBed
        case .asleepUnspecified: return .asleep
        case .awake: return .awake
        case .asleepCore: return .core
        case .asleepDeep: return .deep
        case .asleepREM: return .rem
        @unknown default: return .asleep
        }
    }

    // MARK: - HRV Data

    func fetchMorningHRV() async throws -> HRVData {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let hrvRecords = try await fetchHRVData(from: startOfToday, to: Date())

        guard !hrvRecords.isEmpty else {
            // Try yesterday's data
            let yesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday)!
            let yesterdayRecords = try await fetchHRVData(from: yesterday, to: startOfToday)
            return yesterdayRecords.last ?? HRVData(averageHRV: 0, trend: .stable, readings: [])
        }

        return hrvRecords.last!
    }

    private func fetchHRVData(from startDate: Date, to endDate: Date) async throws -> [HRVData] {
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            throw HealthKitError.typeNotAvailable
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
                }
            }
            healthStore.execute(query)
        }

        return aggregateHRVSamples(samples)
    }

    private func aggregateHRVSamples(_ samples: [HKQuantitySample]) -> [HRVData] {
        guard !samples.isEmpty else { return [] }

        let readings = samples.map { sample in
            HRVReading(
                value: sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)),
                date: sample.startDate
            )
        }

        let average = readings.reduce(0.0) { $0 + $1.value } / Double(readings.count)

        // Calculate trend
        let trend = calculateHRVTrend(readings: readings)

        return [HRVData(averageHRV: average, trend: trend, readings: readings)]
    }

    private func calculateHRVTrend(readings: [HRVReading]) -> HRVTrend {
        guard readings.count >= 2 else { return .stable }

        let recentAvg = readings.suffix(3).reduce(0.0) { $0 + $1.value } / Double(min(3, readings.count))
        let olderAvg = readings.prefix(3).reduce(0.0) { $0 + $1.value } / Double(min(3, readings.count))

        let change = (recentAvg - olderAvg) / olderAvg

        if change > 0.1 {
            return .improving
        } else if change < -0.1 {
            return .declining
        } else {
            return .stable
        }
    }

    // MARK: - Workouts

    private func fetchWorkouts(from startDate: Date, to endDate: Date) async throws -> [DetectedWorkout] {
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKWorkout], Error>) in
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples as? [HKWorkout] ?? [])
                }
            }
            healthStore.execute(query)
        }

        return samples.map { workout in
            DetectedWorkout(
                id: workout.uuid.uuidString,
                type: mapWorkoutType(workout.workoutActivityType),
                startDate: workout.startDate,
                endDate: workout.endDate,
                duration: workout.duration,
                activeCalories: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
                averageHeartRate: nil,  // Would need to query separately
                source: workout.sourceRevision.source.name
            )
        }
    }

    private func mapWorkoutType(_ hkType: HKWorkoutActivityType) -> WorkoutType {
        switch hkType {
        case .traditionalStrengthTraining, .functionalStrengthTraining:
            return .strength
        case .running, .cycling, .swimming, .elliptical:
            return .cardio
        case .highIntensityIntervalTraining:
            return .hiit
        case .yoga, .pilates:
            return .flexibility
        case .walking:
            return .recoveryWalk
        default:
            return .other
        }
    }

    // MARK: - Background Delivery Handler

    func processBackgroundDelivery() async {
        // Process any new data since last sync
        guard let lastSync = lastSyncDate else {
            // First time - do initial import
            try? await performInitialImport()
            return
        }

        do {
            try await importData(startDate: lastSync, endDate: Date())
        } catch {
            // Log error but don't throw - background delivery should be resilient
        }
    }

    // MARK: - Query Helpers

    func getSleepHours(for date: Date) async -> Double? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        do {
            let sleepData = try await fetchSleepData(from: startOfDay, to: endOfDay)
            return sleepData.first?.totalHours
        } catch {
            return nil
        }
    }
}

// MARK: - HealthKit Error

enum HealthKitError: LocalizedError {
    case notAvailable
    case typeNotAvailable
    case queryFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .typeNotAvailable:
            return "Required health data type is not available"
        case .queryFailed(let message):
            return "Health data query failed: \(message)"
        }
    }
}

// MARK: - Import State

struct HealthKitImportState: Codable {
    var lastFullImport: Date
    var daysImported: Int
}
