//
//  ActiveWorkoutView.swift
//  VigorWatch
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Active workout view with real-time metrics.
//

import SwiftUI
import HealthKit

struct ActiveWorkoutView: View {
    @EnvironmentObject private var workoutManager: WatchWorkoutManager
    @State private var showEndConfirmation = false

    var body: some View {
        TabView {
            // Main metrics view
            MetricsView()

            // Controls view
            ControlsView(showEndConfirmation: $showEndConfirmation)
        }
        .tabViewStyle(.page)
        .navigationBarBackButtonHidden(true)
        .confirmationDialog("End Workout?", isPresented: $showEndConfirmation) {
            Button("End", role: .destructive) {
                workoutManager.endWorkout()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Metrics View

struct MetricsView: View {
    @EnvironmentObject private var workoutManager: WatchWorkoutManager

    var body: some View {
        VStack(spacing: 8) {
            // Workout type and duration
            HStack {
                Image(systemName: workoutManager.currentWorkoutType?.watchIcon ?? "figure.run")
                    .foregroundColor(.green)
                Text(workoutManager.formattedDuration)
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.bold)
            }

            // Heart Rate (large)
            VStack(spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(workoutManager.currentHeartRate)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.red)
                    Text("BPM")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }

            // Secondary metrics
            HStack(spacing: 16) {
                MetricBadge(
                    value: "\(workoutManager.activeCalories)",
                    label: "CAL",
                    color: .orange
                )

                MetricBadge(
                    value: workoutManager.formattedAvgHeartRate,
                    label: "AVG",
                    color: .pink
                )
            }
        }
        .padding()
    }
}

// MARK: - Metric Badge

struct MetricBadge: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.2))
        .cornerRadius(8)
    }
}

// MARK: - Controls View

struct ControlsView: View {
    @EnvironmentObject private var workoutManager: WatchWorkoutManager
    @Binding var showEndConfirmation: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Pause/Resume button
            Button {
                if workoutManager.isPaused {
                    workoutManager.resumeWorkout()
                } else {
                    workoutManager.pauseWorkout()
                }
            } label: {
                HStack {
                    Image(systemName: workoutManager.isPaused ? "play.fill" : "pause.fill")
                    Text(workoutManager.isPaused ? "Resume" : "Pause")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.yellow)
                .foregroundColor(.black)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)

            // End button
            Button {
                showEndConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "stop.fill")
                    Text("End")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)

            // Water Lock
            Button {
                WKInterfaceDevice.current().enableWaterLock()
            } label: {
                HStack {
                    Image(systemName: "drop.fill")
                    Text("Water Lock")
                }
                .font(.caption)
                .foregroundColor(.cyan)
            }
        }
        .padding()
    }
}

// MARK: - Workout Summary View

struct WorkoutSummaryView: View {
    let summary: WorkoutSummaryData
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)

                    Text("Great Work!")
                        .font(.headline)
                }

                // Summary stats
                VStack(spacing: 12) {
                    SummaryRow(label: "Duration", value: summary.formattedDuration)
                    SummaryRow(label: "Calories", value: "\(summary.activeCalories)")
                    SummaryRow(label: "Avg HR", value: "\(summary.avgHeartRate) BPM")
                    SummaryRow(label: "Max HR", value: "\(summary.maxHeartRate) BPM")
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)

                // Done button
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Workout Summary Data

struct WorkoutSummaryData {
    let workoutType: WatchWorkoutType
    let startTime: Date
    let endTime: Date
    let activeCalories: Int
    let avgHeartRate: Int
    let maxHeartRate: Int

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    var formattedDuration: String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
}
