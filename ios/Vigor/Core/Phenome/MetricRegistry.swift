//
//  MetricRegistry.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Versioned metric recomputation engine.
//  Handles formula changes without breaking user trust.
//
//  Per Tech Spec §2.10, §2.11
//

import Foundation

// MARK: - Metric Version

struct MetricVersion: Codable, Hashable {
    let metricName: String
    let version: String
    let formula: String
    let inputSnapshot: InputSnapshot

    struct InputSnapshot: Codable, Hashable {
        let inputNames: [String]
        let inputHash: String
    }
}

// MARK: - Derived Metric Protocol

protocol DerivedMetric {
    static var name: String { get }
    static var version: String { get }
    static var inputs: [String] { get }

    func calculate(inputs: [String: Any]) -> Double
}

// MARK: - Metric Registry

actor MetricRegistry {

    // MARK: - Registered Metrics

    private var metrics: [String: any DerivedMetric] = [:]
    private var metricVersions: [String: MetricVersion] = [:]

    // MARK: - Registration

    func registerMetrics() async {
        // Register all derived metrics
        register(RecoveryScoreMetric())
        register(SkipProbabilityMetric())
        register(OptimalWindowMetric())
        register(StrainAccumulationMetric())
    }

    private func register(_ metric: any DerivedMetric) {
        let name = type(of: metric).name
        metrics[name] = metric

        // Create version record
        let version = MetricVersion(
            metricName: name,
            version: type(of: metric).version,
            formula: String(describing: type(of: metric)),
            inputSnapshot: MetricVersion.InputSnapshot(
                inputNames: type(of: metric).inputs,
                inputHash: type(of: metric).inputs.joined(separator: ",").hashValue.description
            )
        )
        metricVersions[name] = version
    }

    // MARK: - Calculation

    func calculate(metric name: String, inputs: [String: Any]) async -> Double {
        guard let metric = metrics[name] else {
            return 0.0
        }

        let result = metric.calculate(inputs: inputs)

        // Store provenance
        await storeProvenance(
            metric: name,
            inputs: inputs,
            result: result
        )

        return result
    }

    private func storeProvenance(
        metric: String,
        inputs: [String: Any],
        result: Double
    ) async {
        // Store calculation provenance for audit trail
        // This allows "Why did my score change?" queries
        let provenance = MetricProvenance(
            metricName: metric,
            version: metricVersions[metric]?.version ?? "unknown",
            timestamp: Date(),
            inputHash: inputs.description.hashValue.description,
            result: result
        )

        await MetricProvenanceStore.shared.store(provenance)
    }

    // MARK: - Version Management

    func getVersion(for metric: String) -> String? {
        metricVersions[metric]?.version
    }

    func getAllVersions() -> [MetricVersion] {
        Array(metricVersions.values)
    }
}

// MARK: - Recovery Score Metric

struct RecoveryScoreMetric: DerivedMetric {
    static let name = "recovery_score"
    static let version = "1.0.0"
    static let inputs = ["sleep_hours", "sleep_quality", "hrv_value", "hrv_trend"]

    func calculate(inputs: [String: Any]) -> Double {
        let sleepHours = inputs["sleep_hours"] as? Double ?? 0
        let sleepQuality = inputs["sleep_quality"] as? Double ?? 0
        let hrvValue = inputs["hrv_value"] as? Double ?? 0
        let hrvTrend = inputs["hrv_trend"] as? String ?? "stable"

        // Calculate base score
        var score: Double = 0

        // Sleep component (40% weight)
        let sleepScore: Double
        if sleepHours >= 7 && sleepHours <= 9 {
            sleepScore = 100
        } else if sleepHours >= 6 {
            sleepScore = 70 + (sleepHours - 6) * 30
        } else if sleepHours >= 5 {
            sleepScore = 40 + (sleepHours - 5) * 30
        } else {
            sleepScore = max(0, sleepHours * 8)
        }
        score += sleepScore * 0.25
        score += sleepQuality * 0.15

        // HRV component (40% weight)
        // Normalize HRV (assuming typical range 20-100ms)
        let normalizedHRV = min(100, max(0, (hrvValue - 20) / 80 * 100))
        score += normalizedHRV * 0.30

        // Trend modifier
        switch hrvTrend {
        case "improving":
            score += 10
        case "declining":
            score -= 10
        default:
            break
        }

        // Remaining 20% for other factors (future expansion)
        score += 10 // Base points

        return min(100, max(0, score))
    }
}

// MARK: - Skip Probability Metric

struct SkipProbabilityMetric: DerivedMetric {
    static let name = "skip_probability"
    static let version = "1.0.0"
    static let inputs = ["meeting_density", "sleep_hours", "recovery_score", "time_slot_penalty"]

    func calculate(inputs: [String: Any]) -> Double {
        let meetingDensity = inputs["meeting_density"] as? Double ?? 0
        let sleepHours = inputs["sleep_hours"] as? Double ?? 7
        let recoveryScore = inputs["recovery_score"] as? Double ?? 50
        let timeSlotPenalty = inputs["time_slot_penalty"] as? Int ?? 0

        var skipProbability: Double = 0

        // Meeting density increases skip probability
        skipProbability += meetingDensity * 0.1

        // Poor sleep increases skip probability
        if sleepHours < 6 {
            skipProbability += (6 - sleepHours) * 0.15
        }

        // Low recovery increases skip probability
        if recoveryScore < 50 {
            skipProbability += (50 - recoveryScore) / 100 * 0.3
        }

        // Time slot penalties
        skipProbability += Double(timeSlotPenalty) * 0.1

        return min(1.0, max(0, skipProbability))
    }
}

// MARK: - Optimal Window Metric

struct OptimalWindowMetric: DerivedMetric {
    static let name = "optimal_window_score"
    static let version = "1.0.0"
    static let inputs = ["time_of_day", "energy_level", "meetings_before", "meetings_after"]

    func calculate(inputs: [String: Any]) -> Double {
        let timeOfDay = inputs["time_of_day"] as? Int ?? 12 // Hour of day
        let energyLevel = inputs["energy_level"] as? Double ?? 50
        let meetingsBefore = inputs["meetings_before"] as? Int ?? 0
        let meetingsAfter = inputs["meetings_after"] as? Int ?? 0

        var score: Double = 50

        // Morning preference
        if timeOfDay >= 6 && timeOfDay <= 9 {
            score += 20
        } else if timeOfDay >= 17 && timeOfDay <= 19 {
            score += 15
        } else if timeOfDay >= 12 && timeOfDay <= 14 {
            score += 10
        }

        // Energy level
        score += energyLevel * 0.2

        // Meeting buffer
        if meetingsBefore == 0 {
            score += 10
        }
        if meetingsAfter == 0 {
            score += 5
        }

        return min(100, max(0, score))
    }
}

// MARK: - Strain Accumulation Metric

struct StrainAccumulationMetric: DerivedMetric {
    static let name = "strain_accumulation"
    static let version = "1.0.0"
    static let inputs = ["workouts_last_7_days", "total_duration_minutes", "intensity_scores"]

    func calculate(inputs: [String: Any]) -> Double {
        let workoutCount = inputs["workouts_last_7_days"] as? Int ?? 0
        let totalDuration = inputs["total_duration_minutes"] as? Int ?? 0
        let intensityScores = inputs["intensity_scores"] as? [Double] ?? []

        // Calculate accumulated strain
        var strain: Double = 0

        // Volume strain
        strain += Double(workoutCount) * 5
        strain += Double(totalDuration) * 0.1

        // Intensity strain
        if !intensityScores.isEmpty {
            let avgIntensity = intensityScores.reduce(0, +) / Double(intensityScores.count)
            strain += avgIntensity * 0.5
        }

        return min(100, strain)
    }
}

// MARK: - Metric Provenance

struct MetricProvenance: Codable {
    let metricName: String
    let version: String
    let timestamp: Date
    let inputHash: String
    let result: Double
}

actor MetricProvenanceStore {
    static let shared = MetricProvenanceStore()

    private var provenances: [MetricProvenance] = []
    private let maxEntries = 1000

    func store(_ provenance: MetricProvenance) {
        provenances.append(provenance)

        // Keep only recent entries
        if provenances.count > maxEntries {
            provenances.removeFirst(provenances.count - maxEntries)
        }
    }

    func getHistory(for metric: String, limit: Int = 100) -> [MetricProvenance] {
        provenances
            .filter { $0.metricName == metric }
            .suffix(limit)
            .reversed()
            .map { $0 }
    }
}
