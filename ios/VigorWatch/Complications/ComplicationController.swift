//
//  ComplicationController.swift
//  VigorWatch
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Watch complications - critical for Ghost survival.
//  Per PRD §5.1: Complication refresh wakes iPhone via WCSession,
//  ensuring Ghost stays alive even when app is not used.
//

import ClockKit
import SwiftUI

@MainActor
class ComplicationController: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = ComplicationController()

    // MARK: - State

    @Published var nextWorkout: NextWorkoutInfo?
    @Published var weekProgress: WeekProgressInfo?
    @Published var recoveryScore: Int?

    // MARK: - Initialization

    override private init() {
        super.init()
    }

    // MARK: - Refresh Data

    func refreshData() async {
        // Sync with phone to get latest data
        await WatchSyncManager.shared.syncWithPhone()

        // Reload complications
        reloadComplications()
    }

    func updateFromPhone(_ data: [String: Any]) async {
        if let nextData = data["next_workout"] as? [String: Any] {
            nextWorkout = parseNextWorkout(nextData)
        }

        if let progressData = data["week_progress"] as? [String: Any] {
            weekProgress = parseWeekProgress(progressData)
        }

        if let recovery = data["recovery_score"] as? Int {
            recoveryScore = recovery
        }

        reloadComplications()
    }

    // MARK: - Parsing

    private func parseNextWorkout(_ data: [String: Any]) -> NextWorkoutInfo? {
        guard let type = data["type"] as? String,
              let time = data["time"] as? TimeInterval,
              let duration = data["duration"] as? Int else {
            return nil
        }

        return NextWorkoutInfo(
            type: type,
            scheduledTime: Date(timeIntervalSince1970: time),
            durationMinutes: duration
        )
    }

    private func parseWeekProgress(_ data: [String: Any]) -> WeekProgressInfo? {
        guard let completed = data["completed"] as? Int,
              let scheduled = data["scheduled"] as? Int else {
            return nil
        }

        let progress = scheduled > 0 ? Double(completed) / Double(scheduled) : 0

        return WeekProgressInfo(
            completed: completed,
            scheduled: scheduled,
            progressPercentage: progress
        )
    }

    // MARK: - Reload Complications

    private func reloadComplications() {
        let server = CLKComplicationServer.sharedInstance()
        for complication in server.activeComplications ?? [] {
            server.reloadTimeline(for: complication)
        }
    }
}

// MARK: - Complication Data Source

class ComplicationDataSource: NSObject, CLKComplicationDataSource {

    // MARK: - Timeline Configuration

    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(
                identifier: "VigorNextWorkout",
                displayName: "Next Workout",
                supportedFamilies: [
                    .circularSmall,
                    .modularSmall,
                    .modularLarge,
                    .utilitarianSmall,
                    .utilitarianSmallFlat,
                    .utilitarianLarge,
                    .graphicCorner,
                    .graphicCircular,
                    .graphicRectangular,
                    .graphicExtraLarge
                ]
            ),
            CLKComplicationDescriptor(
                identifier: "VigorWeekProgress",
                displayName: "Week Progress",
                supportedFamilies: [
                    .circularSmall,
                    .modularSmall,
                    .graphicCorner,
                    .graphicCircular
                ]
            ),
            CLKComplicationDescriptor(
                identifier: "VigorRecovery",
                displayName: "Recovery",
                supportedFamilies: [
                    .circularSmall,
                    .modularSmall,
                    .graphicCorner,
                    .graphicCircular
                ]
            )
        ]

        handler(descriptors)
    }

    // MARK: - Timeline Entry Provider

    func getCurrentTimelineEntry(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void
    ) {
        Task { @MainActor in
            let template = createTemplate(for: complication)
            if let template = template {
                let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
                handler(entry)
            } else {
                handler(nil)
            }
        }
    }

    func getTimelineEntries(
        for complication: CLKComplication,
        after date: Date,
        limit: Int,
        withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void
    ) {
        // Provide future entries based on scheduled workouts
        Task { @MainActor in
            var entries: [CLKComplicationTimelineEntry] = []

            if complication.identifier == "VigorNextWorkout",
               let next = ComplicationController.shared.nextWorkout {
                let template = createNextWorkoutTemplate(
                    for: complication.family,
                    workout: next
                )
                if let template = template {
                    let entry = CLKComplicationTimelineEntry(
                        date: next.scheduledTime.addingTimeInterval(-3600),
                        complicationTemplate: template
                    )
                    entries.append(entry)
                }
            }

            handler(entries.isEmpty ? nil : entries)
        }
    }

    // MARK: - Template Creation

    @MainActor
    private func createTemplate(for complication: CLKComplication) -> CLKComplicationTemplate? {
        switch complication.identifier {
        case "VigorNextWorkout":
            return createNextWorkoutTemplate(
                for: complication.family,
                workout: ComplicationController.shared.nextWorkout
            )

        case "VigorWeekProgress":
            return createWeekProgressTemplate(
                for: complication.family,
                progress: ComplicationController.shared.weekProgress
            )

        case "VigorRecovery":
            return createRecoveryTemplate(
                for: complication.family,
                score: ComplicationController.shared.recoveryScore
            )

        default:
            return nil
        }
    }

    private func createNextWorkoutTemplate(
        for family: CLKComplicationFamily,
        workout: NextWorkoutInfo?
    ) -> CLKComplicationTemplate? {

        let workoutText: String
        let timeText: String

        if let workout = workout {
            workoutText = workout.type

            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm"
            timeText = formatter.string(from: workout.scheduledTime)
        } else {
            workoutText = "None"
            timeText = "--:--"
        }

        switch family {
        case .graphicCircular:
            return CLKComplicationTemplateGraphicCircularStackText(
                line1TextProvider: CLKSimpleTextProvider(text: workoutText),
                line2TextProvider: CLKSimpleTextProvider(text: timeText)
            )

        case .graphicCorner:
            return CLKComplicationTemplateGraphicCornerStackText(
                innerTextProvider: CLKSimpleTextProvider(text: workoutText),
                outerTextProvider: CLKSimpleTextProvider(text: timeText)
            )

        case .graphicRectangular:
            return CLKComplicationTemplateGraphicRectangularStandardBody(
                headerTextProvider: CLKSimpleTextProvider(text: "Next Workout"),
                body1TextProvider: CLKSimpleTextProvider(text: workoutText),
                body2TextProvider: CLKSimpleTextProvider(text: timeText)
            )

        case .modularSmall:
            return CLKComplicationTemplateModularSmallStackText(
                line1TextProvider: CLKSimpleTextProvider(text: workoutText),
                line2TextProvider: CLKSimpleTextProvider(text: timeText)
            )

        case .modularLarge:
            return CLKComplicationTemplateModularLargeStandardBody(
                headerTextProvider: CLKSimpleTextProvider(text: "Next Workout"),
                body1TextProvider: CLKSimpleTextProvider(text: workoutText),
                body2TextProvider: CLKSimpleTextProvider(text: timeText)
            )

        case .utilitarianSmallFlat, .utilitarianSmall:
            return CLKComplicationTemplateUtilitarianSmallFlat(
                textProvider: CLKSimpleTextProvider(text: "\(workoutText) \(timeText)")
            )

        case .utilitarianLarge:
            return CLKComplicationTemplateUtilitarianLargeFlat(
                textProvider: CLKSimpleTextProvider(text: "\(workoutText) at \(timeText)")
            )

        case .circularSmall:
            return CLKComplicationTemplateCircularSmallStackText(
                line1TextProvider: CLKSimpleTextProvider(text: workoutText),
                line2TextProvider: CLKSimpleTextProvider(text: timeText)
            )

        default:
            return nil
        }
    }

    private func createWeekProgressTemplate(
        for family: CLKComplicationFamily,
        progress: WeekProgressInfo?
    ) -> CLKComplicationTemplate? {

        let progressText: String
        let percentValue: Float

        if let progress = progress {
            progressText = "\(progress.completed)/\(progress.scheduled)"
            percentValue = Float(progress.progressPercentage)
        } else {
            progressText = "0/0"
            percentValue = 0
        }

        switch family {
        case .graphicCircular:
            return CLKComplicationTemplateGraphicCircularClosedGaugeText(
                gaugeProvider: CLKSimpleGaugeProvider(
                    style: .fill,
                    gaugeColor: .green,
                    fillFraction: percentValue
                ),
                centerTextProvider: CLKSimpleTextProvider(text: progressText)
            )

        case .graphicCorner:
            return CLKComplicationTemplateGraphicCornerGaugeText(
                gaugeProvider: CLKSimpleGaugeProvider(
                    style: .fill,
                    gaugeColor: .green,
                    fillFraction: percentValue
                ),
                outerTextProvider: CLKSimpleTextProvider(text: progressText)
            )

        case .circularSmall:
            return CLKComplicationTemplateCircularSmallRingText(
                textProvider: CLKSimpleTextProvider(text: progressText),
                fillFraction: percentValue,
                ringStyle: .closed
            )

        case .modularSmall:
            return CLKComplicationTemplateModularSmallRingText(
                textProvider: CLKSimpleTextProvider(text: progressText),
                fillFraction: percentValue,
                ringStyle: .closed
            )

        default:
            return nil
        }
    }

    private func createRecoveryTemplate(
        for family: CLKComplicationFamily,
        score: Int?
    ) -> CLKComplicationTemplate? {

        let scoreText = score.map { "\($0)%" } ?? "--%"
        let fillFraction = Float(score ?? 0) / 100.0
        let gaugeColor: UIColor = (score ?? 0) >= 70 ? .green : (score ?? 0) >= 40 ? .yellow : .red

        switch family {
        case .graphicCircular:
            return CLKComplicationTemplateGraphicCircularClosedGaugeText(
                gaugeProvider: CLKSimpleGaugeProvider(
                    style: .fill,
                    gaugeColor: gaugeColor,
                    fillFraction: fillFraction
                ),
                centerTextProvider: CLKSimpleTextProvider(text: scoreText)
            )

        case .graphicCorner:
            return CLKComplicationTemplateGraphicCornerGaugeText(
                gaugeProvider: CLKSimpleGaugeProvider(
                    style: .fill,
                    gaugeColor: gaugeColor,
                    fillFraction: fillFraction
                ),
                outerTextProvider: CLKSimpleTextProvider(text: scoreText)
            )

        case .circularSmall:
            return CLKComplicationTemplateCircularSmallRingText(
                textProvider: CLKSimpleTextProvider(text: scoreText),
                fillFraction: fillFraction,
                ringStyle: .closed
            )

        case .modularSmall:
            return CLKComplicationTemplateModularSmallRingText(
                textProvider: CLKSimpleTextProvider(text: scoreText),
                fillFraction: fillFraction,
                ringStyle: .closed
            )

        default:
            return nil
        }
    }

    // MARK: - Placeholder

    func getLocalizableSampleTemplate(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTemplate?) -> Void
    ) {
        let template = createNextWorkoutTemplate(
            for: complication.family,
            workout: NextWorkoutInfo(
                type: "Strength",
                scheduledTime: Date().addingTimeInterval(3600),
                durationMinutes: 45
            )
        )
        handler(template)
    }
}

// MARK: - Next Workout Info

struct NextWorkoutInfo: Codable {
    let type: String
    let scheduledTime: Date
    let durationMinutes: Int
}

// MARK: - Week Progress Info

struct WeekProgressInfo: Codable {
    let completed: Int
    let scheduled: Int
    let progressPercentage: Double
}
