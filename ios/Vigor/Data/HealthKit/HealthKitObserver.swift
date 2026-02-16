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

    /// Debounce timer for background delivery (Tech Spec §2.5: 60s)
    private var backgroundDeliveryDebounceTask: Task<Void, Never>?
    private let debounceInterval: TimeInterval = 60

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
        UserDefaults.standard.set(true, forKey: "healthKitAuthorized")
        KeychainHelper.save(key: "healthKitAuthorized", data: Data("true".utf8))

        // Setup background delivery
        await setupBackgroundDelivery()
    }

    private func checkAuthorizationStatus() {
        // Probe-based detection: attempt a lightweight HealthKit query.
        // If data returns (even empty), authorization was previously granted.
        // This survives re-installs and free provisioning re-signing, unlike UserDefaults.
        // Also check Keychain as a fast cache.
        if let keychainData = KeychainHelper.read(key: "healthKitAuthorized"),
           String(data: keychainData, encoding: .utf8) == "true" {
            isAuthorized = true
            return
        }

        // Probe: query last 1 day of step count — fast and always available
        guard HKHealthStore.isHealthDataAvailable(),
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            isAuthorized = false
            return
        }

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: Date())
        let query = HKSampleQuery(
            sampleType: stepType,
            predicate: predicate,
            limit: 1,
            sortDescriptors: nil
        ) { [weak self] _, results, error in
            DispatchQueue.main.async {
                // If we get results array (even empty but no auth error), auth was granted
                if error == nil {
                    self?.isAuthorized = true
                    KeychainHelper.save(key: "healthKitAuthorized", data: Data("true".utf8))
                } else {
                    // Check UserDefaults as legacy fallback
                    self?.isAuthorized = UserDefaults.standard.bool(forKey: "healthKitAuthorized")
                }
            }
        }
        healthStore.execute(query)
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
        // Resume from last savepoint if available
        let savedState = loadImportState()
        let startDaysBack = savedState?.daysImported ?? 0

        if startDaysBack == 0 {
            // Phase 1: Import last 7 days (quick start)
            importProgress = 0.0
            try await importDataChunked(fromDaysBack: 0, toDaysBack: 7)
            saveImportState(daysImported: 7)
            importProgress = 0.3
        }

        if startDaysBack < 90 {
            // Phase 2: Import remaining days up to 90 in 7-day chunks
            let resumeFrom = max(startDaysBack, 7)
            let totalRemaining = 90 - resumeFrom
            var imported = 0

            var chunkStart = resumeFrom
            while chunkStart < 90 {
                let chunkEnd = min(chunkStart + 7, 90)
                try await importDataChunked(fromDaysBack: chunkStart, toDaysBack: chunkEnd)

                // Savepoint after each chunk
                saveImportState(daysImported: chunkEnd)
                imported += (chunkEnd - chunkStart)
                importProgress = 0.3 + 0.7 * (Double(imported) / Double(max(totalRemaining, 1)))
                chunkStart = chunkEnd
            }
        }

        importProgress = 1.0
        importState = HealthKitImportState(lastFullImport: Date(), daysImported: 90)
        saveImportState(daysImported: 90)
    }

    /// Import a single chunk defined by days-back range.
    private func importDataChunked(fromDaysBack: Int, toDaysBack: Int) async throws {
        let endDate = Calendar.current.date(byAdding: .day, value: -fromDaysBack, to: Date())!
        let startDate = Calendar.current.date(byAdding: .day, value: -toDaysBack, to: Date())!
        try await importData(startDate: startDate, endDate: endDate)
    }

    // MARK: - Import State Persistence

    private static let importStateKey = "healthKitImportState"

    private func saveImportState(daysImported: Int) {
        let state = HealthKitImportState(lastFullImport: Date(), daysImported: daysImported)
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: Self.importStateKey)
        }
    }

    private func loadImportState() -> HealthKitImportState? {
        guard let data = UserDefaults.standard.data(forKey: Self.importStateKey) else { return nil }
        return try? JSONDecoder().decode(HealthKitImportState.self, from: data)
    }

    private func importData(startDate: Date, endDate: Date) async throws {
        VigorLogger.healthKit.info("Import chunk: \(startDate.formatted(.dateTime.month().day())) → \(endDate.formatted(.dateTime.month().day()))")

        // Offload heavy HealthKit queries to background to avoid blocking MainActor
        let healthStore = self.healthStore
        let (sleepData, hrvData, workouts, restingHR) = try await Task.detached(priority: .utility) {
            async let sleep = self.fetchSleepData(from: startDate, to: endDate)
            async let hrv = self.fetchHRVData(from: startDate, to: endDate)
            async let wk = self.fetchWorkouts(from: startDate, to: endDate)
            async let hr = self.fetchRestingHR(from: startDate, to: endDate)
            return try await (sleep, hrv, wk, hr)
        }.value

        VigorLogger.healthKit.info("Fetched \(sleepData.count) sleep, \(hrvData.count) HRV, \(workouts.count) workouts, \(restingHR.count) resting HR")

        // Import into Phenome (back on MainActor)
        await PhenomeCoordinator.shared.importSleepData(sleepData)
        await PhenomeCoordinator.shared.importHRVData(hrvData)
        await PhenomeCoordinator.shared.importWorkouts(workouts)
        await RawSignalStore.shared.storeRestingHR(restingHR)

        // Track imported data counts for trust acceleration
        // (TrustStateMachine uses these to allow faster phase advancement)
        let currentWorkoutCount = UserDefaults.standard.integer(forKey: "importedWorkoutCount")
        UserDefaults.standard.set(currentWorkoutCount + workouts.count, forKey: "importedWorkoutCount")
        let currentSleepCount = UserDefaults.standard.integer(forKey: "importedSleepRecordCount")
        UserDefaults.standard.set(currentSleepCount + sleepData.count, forKey: "importedSleepRecordCount")

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

    // MARK: - Resting Heart Rate

    private func fetchRestingHR(from startDate: Date, to endDate: Date) async throws -> [(bpm: Int, date: Date)] {
        guard let restingHRType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else {
            throw HealthKitError.typeNotAvailable
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
            let query = HKSampleQuery(
                sampleType: restingHRType,
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

        return samples.map { sample in
            let bpm = Int(sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
            return (bpm: bpm, date: sample.startDate)
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

    /// Called by HKObserverQuery callbacks. Debounces at 60s to avoid
    /// redundant imports when HealthKit fires multiple deliveries in quick
    /// succession (e.g. watch syncs several sample types at once).
    func processBackgroundDelivery() async {
        // Cancel any previously scheduled debounce
        backgroundDeliveryDebounceTask?.cancel()

        backgroundDeliveryDebounceTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: UInt64(60 * 1_000_000_000)) // 60s
            } catch {
                return // Cancelled
            }
            await self?.executeBackgroundSync()
        }
    }

    /// Actual sync logic — only runs after the debounce window elapses.
    private func executeBackgroundSync() async {
        guard let lastSync = lastSyncDate else {
            try? await performInitialImport()
            return
        }

        do {
            try await importData(startDate: lastSync, endDate: Date())
        } catch {
            // Background delivery should be resilient — log but don't throw
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
