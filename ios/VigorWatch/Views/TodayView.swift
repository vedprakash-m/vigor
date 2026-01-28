//
//  TodayView.swift
//  VigorWatch
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Watch Today view - shows next workout, quick start, weekly progress.
//

import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var workoutManager: WatchWorkoutManager
    @EnvironmentObject private var syncManager: WatchSyncManager

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Next Workout Card
                if let nextBlock = syncManager.nextBlock {
                    NextWorkoutCard(block: nextBlock)
                } else {
                    NoWorkoutCard()
                }

                // Quick Start Button
                NavigationLink(destination: WorkoutTypePickerView()) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Quick Start")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)

                // Week Progress
                WeekProgressRing(
                    completed: syncManager.completedThisWeek,
                    total: syncManager.scheduledThisWeek
                )

                // Recovery Status (if available)
                if let recoveryScore = syncManager.recoveryScore {
                    RecoveryIndicator(score: recoveryScore)
                }
            }
            .padding(.horizontal, 8)
        }
        .navigationTitle("Vigor")
        .onAppear {
            Task {
                await syncManager.syncWithPhone()
            }
        }
    }
}

// MARK: - Next Workout Card

struct NextWorkoutCard: View {
    let block: WatchTrainingBlock
    @EnvironmentObject private var workoutManager: WatchWorkoutManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: block.workoutType.watchIcon)
                    .foregroundColor(block.workoutType.color)

                VStack(alignment: .leading) {
                    Text(block.workoutType.displayName)
                        .font(.headline)
                    Text(timeUntilBlock)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                Spacer()
            }

            // Start button
            Button {
                workoutManager.startWorkout(block)
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color.green)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }

    private var timeUntilBlock: String {
        let interval = block.scheduledStart.timeIntervalSinceNow
        if interval < 0 { return "Now" }
        if interval < 60 { return "In 1 min" }
        if interval < 3600 { return "In \(Int(interval / 60)) min" }
        if interval < 86400 { return "In \(Int(interval / 3600)) hr" }
        return block.scheduledStart.formatted(date: .abbreviated, time: .shortened)
    }
}

// MARK: - No Workout Card

struct NoWorkoutCard: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title)
                .foregroundColor(.green)

            Text("No workout scheduled")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
}

// MARK: - Week Progress Ring

struct WeekProgressRing: View {
    let completed: Int
    let total: Int

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: 44, height: 44)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))

                Text("\(completed)")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.bold)
            }

            VStack(alignment: .leading) {
                Text("This Week")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("\(completed)/\(total) workouts")
                    .font(.caption2)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
}

// MARK: - Recovery Indicator

struct RecoveryIndicator: View {
    let score: Int

    private var status: RecoveryStatus {
        switch score {
        case 80...100: return .fullyRecovered
        case 60..<80: return .partiallyRecovered
        case 40..<60: return .fatigued
        default: return .overtrained
        }
    }

    var body: some View {
        HStack {
            Image(systemName: "heart.fill")
                .foregroundColor(status.color)

            VStack(alignment: .leading) {
                Text("Recovery")
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text("\(score)%")
                    .font(.caption)
                    .fontWeight(.semibold)
            }

            Spacer()

            Text(status.label)
                .font(.caption2)
                .foregroundColor(status.color)
        }
        .padding(12)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }

    enum RecoveryStatus {
        case fullyRecovered
        case partiallyRecovered
        case fatigued
        case overtrained

        var color: Color {
            switch self {
            case .fullyRecovered: return .green
            case .partiallyRecovered: return .yellow
            case .fatigued: return .orange
            case .overtrained: return .red
            }
        }

        var label: String {
            switch self {
            case .fullyRecovered: return "Ready"
            case .partiallyRecovered: return "Moderate"
            case .fatigued: return "Rest"
            case .overtrained: return "Rest"
            }
        }
    }
}

// MARK: - Workout Type Picker

struct WorkoutTypePickerView: View {
    @EnvironmentObject private var workoutManager: WatchWorkoutManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List(WatchWorkoutType.allCases, id: \.self) { type in
            Button {
                workoutManager.startFreeWorkout(type)
                dismiss()
            } label: {
                HStack {
                    Image(systemName: type.watchIcon)
                        .foregroundColor(type.color)
                    Text(type.displayName)
                }
            }
        }
        .navigationTitle("Start Workout")
    }
}
