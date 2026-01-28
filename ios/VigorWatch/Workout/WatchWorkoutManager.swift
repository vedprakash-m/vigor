//
//  WatchWorkoutManager.swift
//  VigorWatch
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Workout session management with HealthKit integration.
//  Watch is authoritative for workout data per PRD §3.3.
//

import Foundation
import HealthKit
import WatchKit
import Combine

@MainActor
class WatchWorkoutManager: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = WatchWorkoutManager()

    // MARK: - Published State

    @Published var isWorkoutActive = false
    @Published var isPaused = false
    @Published var currentWorkoutType: WatchWorkoutType?
    @Published var currentHeartRate: Int = 0
    @Published var activeCalories: Int = 0
    @Published var elapsedSeconds: TimeInterval = 0
    @Published var workoutSummary: WorkoutSummaryData?

    // MARK: - Private State

    private var healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var startTime: Date?
    private var heartRateSamples: [Int] = []
    private var timer: Timer?

    // Current block being tracked (if scheduled workout)
    private var currentBlockId: String?

    // MARK: - Computed Properties

    var formattedDuration: String {
        let minutes = Int(elapsedSeconds / 60)
        let seconds = Int(elapsedSeconds.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedAvgHeartRate: String {
        guard !heartRateSamples.isEmpty else { return "--" }
        let avg = heartRateSamples.reduce(0, +) / heartRateSamples.count
        return "\(avg)"
    }

    // MARK: - Initialization

    override private init() {
        super.init()
    }

    // MARK: - Start Workout

    func startWorkout(_ block: WatchTrainingBlock) {
        currentBlockId = block.id
        startWorkout(type: block.workoutType)
    }

    func startFreeWorkout(_ type: WatchWorkoutType) {
        currentBlockId = nil
        startWorkout(type: type)
    }

    private func startWorkout(type: WatchWorkoutType) {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = type.healthKitType
        configuration.locationType = type.locationType

        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()

            session?.delegate = self
            builder?.delegate = self

            builder?.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )

            let startDate = Date()
            session?.startActivity(with: startDate)
            builder?.beginCollection(withStart: startDate) { success, error in
                if success {
                    DispatchQueue.main.async {
                        self.isWorkoutActive = true
                        self.isPaused = false
                        self.currentWorkoutType = type
                        self.startTime = startDate
                        self.elapsedSeconds = 0
                        self.heartRateSamples = []
                        self.activeCalories = 0
                        self.currentHeartRate = 0
                        self.startTimer()
                    }
                }
            }
        } catch {
            print("Failed to start workout: \(error)")
        }
    }

    // MARK: - Pause/Resume

    func pauseWorkout() {
        session?.pause()
        isPaused = true
        timer?.invalidate()
    }

    func resumeWorkout() {
        session?.resume()
        isPaused = false
        startTimer()
    }

    // MARK: - End Workout

    func endWorkout() {
        timer?.invalidate()
        session?.end()

        let endDate = Date()
        builder?.endCollection(withEnd: endDate) { [weak self] success, error in
            guard let self = self, success else { return }

            self.builder?.finishWorkout { workout, error in
                DispatchQueue.main.async {
                    self.processWorkoutCompletion(workout: workout, endDate: endDate)
                }
            }
        }
    }

    private func processWorkoutCompletion(workout: HKWorkout?, endDate: Date) {
        guard let startTime = startTime,
              let workoutType = currentWorkoutType else {
            resetState()
            return
        }

        let avgHR = heartRateSamples.isEmpty ? 0 : heartRateSamples.reduce(0, +) / heartRateSamples.count
        let maxHR = heartRateSamples.max() ?? 0

        let summary = WorkoutSummaryData(
            workoutType: workoutType,
            startTime: startTime,
            endTime: endDate,
            activeCalories: activeCalories,
            avgHeartRate: avgHR,
            maxHeartRate: maxHR
        )

        workoutSummary = summary

        // Send to iPhone
        Task {
            await sendWorkoutToPhone(summary)
        }

        resetState()
    }

    private func sendWorkoutToPhone(_ summary: WorkoutSummaryData) async {
        let workoutData: [String: Any] = [
            "type": summary.workoutType.rawValue,
            "start_time": summary.startTime.timeIntervalSince1970,
            "end_time": summary.endTime.timeIntervalSince1970,
            "duration": Int(summary.duration / 60),
            "calories": summary.activeCalories,
            "hr_avg": summary.avgHeartRate,
            "hr_max": summary.maxHeartRate,
            "block_id": currentBlockId ?? ""
        ]

        await WatchSyncManager.shared.sendWorkoutCompletion(workoutData)
    }

    private func resetState() {
        isWorkoutActive = false
        isPaused = false
        currentWorkoutType = nil
        currentBlockId = nil
        startTime = nil
        session = nil
        builder = nil
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime, !self.isPaused else { return }
            DispatchQueue.main.async {
                self.elapsedSeconds = Date().timeIntervalSince(startTime)
            }
        }
    }
}

// MARK: - HKWorkoutSessionDelegate

extension WatchWorkoutManager: HKWorkoutSessionDelegate {

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        // Handle state changes
    }

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        print("Workout session failed: \(error)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension WatchWorkoutManager: HKLiveWorkoutBuilderDelegate {

    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }

            let statistics = workoutBuilder.statistics(for: quantityType)

            Task { @MainActor in
                updateMetrics(statistics, for: quantityType)
            }
        }
    }

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Handle workout events
    }

    @MainActor
    private func updateMetrics(_ statistics: HKStatistics?, for type: HKQuantityType) {
        guard let statistics = statistics else { return }

        switch type {
        case HKQuantityType.quantityType(forIdentifier: .heartRate):
            let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
            if let value = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) {
                currentHeartRate = Int(value)
                heartRateSamples.append(Int(value))
            }

        case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
            let calorieUnit = HKUnit.kilocalorie()
            if let value = statistics.sumQuantity()?.doubleValue(for: calorieUnit) {
                activeCalories = Int(value)
            }

        default:
            break
        }
    }
}

// MARK: - Watch Workout Type

enum WatchWorkoutType: String, CaseIterable {
    case strength
    case cardio
    case hiit
    case yoga
    case flexibility
    case recovery
    case swimming
    case cycling
    case walking
    case custom

    var displayName: String {
        switch self {
        case .strength: return "Strength"
        case .cardio: return "Cardio"
        case .hiit: return "HIIT"
        case .yoga: return "Yoga"
        case .flexibility: return "Stretch"
        case .recovery: return "Recovery"
        case .swimming: return "Swim"
        case .cycling: return "Cycle"
        case .walking: return "Walk"
        case .custom: return "Other"
        }
    }

    var watchIcon: String {
        switch self {
        case .strength: return "dumbbell.fill"
        case .cardio: return "figure.run"
        case .hiit: return "bolt.fill"
        case .yoga: return "figure.mind.and.body"
        case .flexibility: return "figure.flexibility"
        case .recovery: return "bed.double.fill"
        case .swimming: return "figure.pool.swim"
        case .cycling: return "bicycle"
        case .walking: return "figure.walk"
        case .custom: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .strength: return .orange
        case .cardio: return .red
        case .hiit: return .yellow
        case .yoga: return .purple
        case .flexibility: return .mint
        case .recovery: return .blue
        case .swimming: return .cyan
        case .cycling: return .green
        case .walking: return .teal
        case .custom: return .pink
        }
    }

    var healthKitType: HKWorkoutActivityType {
        switch self {
        case .strength: return .traditionalStrengthTraining
        case .cardio: return .running
        case .hiit: return .highIntensityIntervalTraining
        case .yoga: return .yoga
        case .flexibility: return .flexibility
        case .recovery: return .mindAndBody
        case .swimming: return .swimming
        case .cycling: return .cycling
        case .walking: return .walking
        case .custom: return .other
        }
    }

    var locationType: HKWorkoutSessionLocationType {
        switch self {
        case .swimming: return .unknown
        case .cycling, .walking, .cardio: return .outdoor
        default: return .indoor
        }
    }
}

// MARK: - Watch Training Block

struct WatchTrainingBlock: Identifiable, Codable {
    let id: String
    let workoutType: WatchWorkoutType
    let scheduledStart: Date
    let scheduledEnd: Date
    let status: String
}

import SwiftUI

extension WatchWorkoutType: Codable {}
