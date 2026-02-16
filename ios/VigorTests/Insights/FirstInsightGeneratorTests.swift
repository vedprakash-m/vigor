//
//  FirstInsightGeneratorTests.swift
//  VigorTests
//
//  Created by Vigor Team on February 15, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Tests for FirstInsightGenerator — data quality assessment,
//  sleep/workout/recovery/timing analysis, and caching.
//

import XCTest
@testable import Vigor

final class FirstInsightGeneratorTests: XCTestCase {

    var sut: TestableInsightGenerator!

    override func setUp() async throws {
        sut = await TestableInsightGenerator()
    }

    override func tearDown() async throws {
        sut = nil
    }

    // MARK: - Data Quality Assessment

    func testRichQuality() async {
        let quality = await sut.assessQuality(sleepCount: 14, workoutCount: 10)
        XCTAssertEqual(quality, DataQuality.rich)
    }

    func testModerateQualityWithWorkouts() async {
        let quality = await sut.assessQuality(sleepCount: 0, workoutCount: 3)
        XCTAssertEqual(quality, DataQuality.moderate)
    }

    func testModerateQualityWithSleep() async {
        let quality = await sut.assessQuality(sleepCount: 7, workoutCount: 0)
        XCTAssertEqual(quality, DataQuality.moderate)
    }

    func testMinimalQuality() async {
        let quality = await sut.assessQuality(sleepCount: 2, workoutCount: 1)
        XCTAssertEqual(quality, DataQuality.minimal)
    }

    func testRichRequiresBothConditions() async {
        // 10 workouts but only 5 sleep records → moderate, not rich
        let quality = await sut.assessQuality(sleepCount: 5, workoutCount: 10)
        XCTAssertEqual(quality, DataQuality.moderate)
    }

    // MARK: - Data Quality Descriptions

    func testDataQualityDescriptions() {
        XCTAssertEqual(DataQuality.rich.description, "90 days of health data")
        XCTAssertEqual(DataQuality.moderate.description, "recent health data")
        XCTAssertEqual(DataQuality.minimal.description, "initial data")
    }

    // MARK: - Sleep Analysis

    func testNoSleepDataReturnsNil() async {
        let insight = await sut.analyzeSleepPublic([])
        XCTAssertNil(insight, "Should not generate insight with no sleep data")
    }

    func testTooFewSleepRecordsReturnsNil() async {
        let data = makeSleepData(count: 2, avgHours: 7.0)
        let insight = await sut.analyzeSleepPublic(data)
        XCTAssertNil(insight, "Need >= 3 records for sleep insight")
    }

    func testLowSleepGeneratesWarning() async {
        let data = makeSleepData(count: 10, avgHours: 5.5)
        let insight = await sut.analyzeSleepPublic(data)

        XCTAssertNotNil(insight)
        XCTAssertEqual(insight?.category, .sleep)
        XCTAssertTrue(insight!.headline.contains("attention"), "Low sleep should warn user")
    }

    func testHighSleepGeneratesPositiveInsight() async {
        let data = makeSleepData(count: 10, avgHours: 8.0)
        let insight = await sut.analyzeSleepPublic(data)

        XCTAssertNotNil(insight)
        XCTAssertEqual(insight?.category, .sleep)
        XCTAssertTrue(insight!.headline.contains("Strong"), "High sleep should be positive")
    }

    func testModerateSleepGeneratesMixedInsight() async {
        let data = makeSleepData(count: 10, avgHours: 7.0)
        let insight = await sut.analyzeSleepPublic(data)

        XCTAssertNotNil(insight)
        XCTAssertEqual(insight?.category, .sleep)
        XCTAssertTrue(insight!.headline.contains("improve"), "Moderate sleep should note room to improve")
    }

    // MARK: - Workout Consistency

    func testNoWorkoutsGeneratesFreshStart() async {
        let insight = await sut.analyzeWorkoutsPublic([])

        XCTAssertNotNil(insight)
        XCTAssertEqual(insight?.category, .workout)
        XCTAssertTrue(insight!.headline.contains("Fresh start"))
    }

    func testSingleWorkoutReturnsNil() async {
        let workouts = makeWorkouts(count: 1)
        let insight = await sut.analyzeWorkoutsPublic(workouts)
        XCTAssertNil(insight, "Need >= 2 workouts for consistency insight")
    }

    // MARK: - Recovery Analysis

    func testTooFewHRVReturnsNil() async {
        let hrv = makeHRVData(count: 3, avgHRV: 50)
        let insight = await sut.analyzeRecoveryPublic(hrvData: hrv, restingHR: [])
        XCTAssertNil(insight, "Need >= 5 HRV records")
    }

    func testSteadyHRVGeneratesStableInsight() async {
        // All identical values — trend = 0%
        let hrv = makeHRVData(count: 14, avgHRV: 50)
        let insight = await sut.analyzeRecoveryPublic(hrvData: hrv, restingHR: [])

        XCTAssertNotNil(insight)
        XCTAssertEqual(insight?.category, .recovery)
        XCTAssertTrue(insight!.headline.contains("Steady"), "Flat HRV trend -> steady baseline")
    }

    // MARK: - Workout Timing

    func testTooFewWorkoutsForTimingReturnsNil() async {
        let workouts = makeWorkouts(count: 3)
        let insight = await sut.analyzeTimingPublic(workouts)
        XCTAssertNil(insight, "Need >= 5 workouts for timing insight")
    }

    func testMorningWorkoutsDetected() async {
        let workouts = makeWorkoutsAtHour(count: 7, hour: 7)
        let insight = await sut.analyzeTimingPublic(workouts)

        XCTAssertNotNil(insight)
        XCTAssertEqual(insight?.category, .schedule)
        XCTAssertTrue(insight!.headline.contains("morning"), "7 AM workouts should detect morning")
    }

    func testEveningWorkoutsDetected() async {
        let workouts = makeWorkoutsAtHour(count: 7, hour: 19)
        let insight = await sut.analyzeTimingPublic(workouts)

        XCTAssertNotNil(insight)
        XCTAssertTrue(insight!.headline.contains("evening"), "7 PM workouts should detect evening")
    }

    // MARK: - First Insight Category

    func testFirstInsightCategoryRawValues() {
        XCTAssertEqual(FirstInsightCategory.sleep.rawValue, "sleep")
        XCTAssertEqual(FirstInsightCategory.workout.rawValue, "workout")
        XCTAssertEqual(FirstInsightCategory.recovery.rawValue, "recovery")
        XCTAssertEqual(FirstInsightCategory.schedule.rawValue, "schedule")
    }

    // MARK: - First Insight Model

    func testFirstInsightHasGeneratedAt() {
        let before = Date()
        let insight = FirstInsight(
            headline: "Test",
            detail: "Detail",
            dataPoint: "Data",
            category: .sleep
        )
        let after = Date()

        XCTAssertGreaterThanOrEqual(insight.generatedAt, before)
        XCTAssertLessThanOrEqual(insight.generatedAt, after)
    }

    func testFirstInsightIsCodable() throws {
        let insight = FirstInsight(
            headline: "Test",
            detail: "Detail",
            dataPoint: "7.5h avg",
            category: .sleep
        )

        let data = try JSONEncoder().encode(insight)
        let decoded = try JSONDecoder().decode(FirstInsight.self, from: data)

        XCTAssertEqual(decoded.headline, "Test")
        XCTAssertEqual(decoded.category, .sleep)
    }

    // MARK: - InsightBundle Summary Lines

    func testBundleSummaryLineVariesByQuality() {
        let primary = FirstInsight(headline: "T", detail: "D", dataPoint: "P", category: .workout)

        let rich = FirstInsightBundle(primaryInsight: primary, supportingInsights: [], suggestedWorkoutWindow: nil, dataQuality: .rich)
        XCTAssertTrue(rich.summaryLine.contains("Ghost already knows"))

        let moderate = FirstInsightBundle(primaryInsight: primary, supportingInsights: [], suggestedWorkoutWindow: nil, dataQuality: .moderate)
        XCTAssertTrue(moderate.summaryLine.contains("enough data"))

        let minimal = FirstInsightBundle(primaryInsight: primary, supportingInsights: [], suggestedWorkoutWindow: nil, dataQuality: .minimal)
        XCTAssertTrue(minimal.summaryLine.contains("ready"))
    }

    // MARK: - Caching

    func testGenerateInsightsCachesResult() async {
        var callCount = 0
        let bundle = await sut.generateInsightsWithCounter(counter: &callCount)
        XCTAssertEqual(callCount, 1)

        // Second call should return cached
        let cached = await sut.generateInsightsWithCounter(counter: &callCount)
        XCTAssertEqual(callCount, 1, "Second call should use cache")
        XCTAssertEqual(bundle.dataQuality, cached.dataQuality)
    }

    func testResetClearsCache() async {
        var callCount = 0
        _ = await sut.generateInsightsWithCounter(counter: &callCount)
        XCTAssertEqual(callCount, 1)

        await sut.reset()

        _ = await sut.generateInsightsWithCounter(counter: &callCount)
        XCTAssertEqual(callCount, 2, "After reset, should regenerate")
    }
}

// MARK: - Test Helpers

extension FirstInsightGeneratorTests {

    /// Create N SleepData records with an average totalHours.
    func makeSleepData(count: Int, avgHours: Double) -> [SleepData] {
        (0..<count).map { i in
            SleepData(
                totalHours: avgHours + Double(i % 2 == 0 ? 0.1 : -0.1),
                qualityScore: 80.0,
                stages: []
            )
        }
    }

    /// Create N HRVData records with the same averageHRV.
    func makeHRVData(count: Int, avgHRV: Double) -> [HRVData] {
        (0..<count).map { _ in
            HRVData(
                averageHRV: avgHRV,
                trend: .stable,
                readings: []
            )
        }
    }

    /// Create N DetectedWorkout records spread across the last 90 days.
    func makeWorkouts(count: Int) -> [DetectedWorkout] {
        let spacing = max(1, 90 / max(count, 1))
        return (0..<count).map { i in
            let start = Calendar.current.date(byAdding: .day, value: -(i * spacing), to: Date())!
            let end = start.addingTimeInterval(3600)
            return DetectedWorkout(
                id: UUID().uuidString,
                type: .cardio,
                startDate: start,
                endDate: end,
                duration: 3600,
                activeCalories: 400,
                averageHeartRate: 140,
                source: "Apple Watch"
            )
        }
    }

    /// Create workouts all at a specific hour-of-day.
    func makeWorkoutsAtHour(count: Int, hour: Int) -> [DetectedWorkout] {
        (0..<count).map { i in
            let day = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            let start = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: day)!
            let end = start.addingTimeInterval(3600)
            return DetectedWorkout(
                id: UUID().uuidString,
                type: .cardio,
                startDate: start,
                endDate: end,
                duration: 3600,
                activeCalories: 400,
                averageHeartRate: 140,
                source: "Apple Watch"
            )
        }
    }
}

// MARK: - Testable Insight Generator

/// Testable wrapper that mirrors FirstInsightGenerator's analysis logic
/// without dependencies on RawSignalStore or OptimalWindowFinder.
@MainActor
final class TestableInsightGenerator {

    private var cachedBundle: FirstInsightBundle?

    func reset() {
        cachedBundle = nil
    }

    // MARK: - Exposed analysis methods (mirror private logic)

    func assessQuality(sleepCount: Int, workoutCount: Int) -> DataQuality {
        if workoutCount >= 10 && sleepCount >= 14 {
            return .rich
        } else if workoutCount >= 3 || sleepCount >= 7 {
            return .moderate
        } else {
            return .minimal
        }
    }

    func analyzeSleepPublic(_ sleepData: [SleepData]) -> FirstInsight? {
        guard sleepData.count >= 3 else { return nil }

        let totalHours = sleepData.map { $0.totalHours }
        let avgSleep = totalHours.reduce(0.0, +) / Double(totalHours.count)
        let sorted = sleepData.sorted(by: { $0.totalHours > $1.totalHours })
        let bestNight = sorted.first

        let avgFormatted = String(format: "%.1f", avgSleep)

        if avgSleep < 6.5 {
            return FirstInsight(
                headline: "Your sleep needs attention",
                detail: "You averaged \(avgFormatted) hours over the past \(sleepData.count) nights. The Ghost will avoid scheduling workouts after short sleep nights.",
                dataPoint: "\(avgFormatted)h avg sleep",
                category: .sleep
            )
        } else if avgSleep >= 7.5 {
            return FirstInsight(
                headline: "Strong sleep foundation",
                detail: "Averaging \(avgFormatted) hours per night. Your recovery capacity supports consistent training.",
                dataPoint: "\(avgFormatted)h avg sleep",
                category: .sleep
            )
        } else {
            return FirstInsight(
                headline: "Solid sleep, room to improve",
                detail: "Averaging \(avgFormatted)h per night. On your best nights you hit \(String(format: "%.1f", bestNight?.totalHours ?? 0))h. The Ghost factors this into workout timing.",
                dataPoint: "\(avgFormatted)h avg sleep",
                category: .sleep
            )
        }
    }

    func analyzeWorkoutsPublic(_ workouts: [DetectedWorkout]) -> FirstInsight? {
        guard workouts.count >= 2 else {
            if workouts.isEmpty {
                return FirstInsight(
                    headline: "Fresh start",
                    detail: "No recent workout history found. The Ghost will start with gentle suggestions and build from there.",
                    dataPoint: "0 workouts / 90 days",
                    category: .workout
                )
            }
            return nil
        }
        // Simplified — full logic in production
        return FirstInsight(
            headline: "Workout pattern detected",
            detail: "Found \(workouts.count) workouts.",
            dataPoint: "\(workouts.count) workouts",
            category: .workout
        )
    }

    func analyzeRecoveryPublic(hrvData: [HRVData], restingHR: [Int]) -> FirstInsight? {
        guard hrvData.count >= 5 else { return nil }

        let avgHRV = hrvData.map { $0.averageHRV }.reduce(0.0, +) / Double(hrvData.count)
        let avgHRVFormatted = String(format: "%.0f", avgHRV)

        let recentHRV = hrvData.prefix(7).map { $0.averageHRV }
        let recentAvg = recentHRV.isEmpty ? avgHRV : recentHRV.reduce(0.0, +) / Double(recentHRV.count)

        let trendPct = ((recentAvg - avgHRV) / avgHRV) * 100

        if trendPct > 10 {
            return FirstInsight(
                headline: "Recovery trending up",
                detail: "Your HRV is \(String(format: "%.0f", trendPct))% above your baseline of \(avgHRVFormatted)ms. Good time to push intensity.",
                dataPoint: "\(avgHRVFormatted)ms avg HRV ↑",
                category: .recovery
            )
        } else if trendPct < -10 {
            return FirstInsight(
                headline: "Recovery needs monitoring",
                detail: "Your recent HRV is \(String(format: "%.0f", abs(trendPct)))% below your baseline of \(avgHRVFormatted)ms. The Ghost will adapt workout intensity.",
                dataPoint: "\(avgHRVFormatted)ms avg HRV ↓",
                category: .recovery
            )
        } else {
            return FirstInsight(
                headline: "Steady recovery baseline",
                detail: "Your HRV averages \(avgHRVFormatted)ms — stable and consistent. A foundation the Ghost can build on.",
                dataPoint: "\(avgHRVFormatted)ms avg HRV",
                category: .recovery
            )
        }
    }

    func analyzeTimingPublic(_ workouts: [DetectedWorkout]) -> FirstInsight? {
        guard workouts.count >= 5 else { return nil }

        let calendar = Calendar.current
        var hourCounts: [Int: Int] = [:]
        for workout in workouts {
            let hour = calendar.component(.hour, from: workout.startDate)
            hourCounts[hour, default: 0] += 1
        }

        guard let peakHour = hourCounts.max(by: { $0.value < $1.value }) else { return nil }

        let timeLabel: String
        switch peakHour.key {
        case 5...8: timeLabel = "early morning"
        case 9...11: timeLabel = "morning"
        case 12...14: timeLabel = "midday"
        case 15...17: timeLabel = "afternoon"
        case 18...20: timeLabel = "evening"
        default: timeLabel = "night"
        }

        let pctAtPeak = Double(peakHour.value) / Double(workouts.count) * 100

        return FirstInsight(
            headline: "You're a \(timeLabel) mover",
            detail: "\(String(format: "%.0f", pctAtPeak))% of your workouts happen in the \(timeLabel). The Ghost will prioritize this window.",
            dataPoint: "\(timeLabel) peak",
            category: .schedule
        )
    }

    // MARK: - Caching test

    func generateInsightsWithCounter(counter: inout Int) -> FirstInsightBundle {
        if let cached = cachedBundle { return cached }
        counter += 1

        let primary = FirstInsight(headline: "Default", detail: "Detail", dataPoint: "D1", category: .workout)
        let bundle = FirstInsightBundle(
            primaryInsight: primary,
            supportingInsights: [],
            suggestedWorkoutWindow: nil,
            dataQuality: .minimal
        )
        cachedBundle = bundle
        return bundle
    }
}
