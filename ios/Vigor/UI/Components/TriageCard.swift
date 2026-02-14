//
//  TriageCard.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Triage cards - single actionable item on home screen.
//  Per PRD §4.2: Ghost should never show more than one triageable item.
//

import SwiftUI

// MARK: - Triage Item Type

enum TriageItemType {
    case blockProposal(GeneratedWorkout, TimeWindow)
    case blockConfirmation(TrainingBlock)
    case workoutFeedback(DetectedWorkout)
    case trustProgress(TrustPhase, Double)
    case weeklyReceipt(ValueReceipt)
    case recoveryAlert(TriageRecoveryStatus)
    case healthCheck
    case empty
}

// MARK: - Recovery Status

enum TriageRecoveryStatus {
    case fullyRecovered
    case partiallyRecovered
    case fatigued
    case overtrained

    var message: String {
        switch self {
        case .fullyRecovered: return "Ready for intense training"
        case .partiallyRecovered: return "Light activity recommended"
        case .fatigued: return "Consider a rest day"
        case .overtrained: return "Rest strongly recommended"
        }
    }

    var color: Color {
        switch self {
        case .fullyRecovered: return .green
        case .partiallyRecovered: return .yellow
        case .fatigued: return .orange
        case .overtrained: return .red
        }
    }
}

// MARK: - Triage Card View

struct TriageCard: View {
    let item: TriageItemType
    let onAction: (TriageAction) -> Void

    var body: some View {
        switch item {
        case .blockProposal(let workout, let window):
            BlockProposalCard(workout: workout, window: window, onAction: onAction)

        case .blockConfirmation(let block):
            BlockConfirmationCard(block: block, onAction: onAction)

        case .workoutFeedback(let workout):
            WorkoutFeedbackCard(workout: workout, onAction: onAction)

        case .trustProgress(let phase, let score):
            TrustProgressCard(phase: phase, score: score)

        case .weeklyReceipt(let receipt):
            WeeklyReceiptCard(receipt: receipt)

        case .recoveryAlert(let status):
            RecoveryAlertCard(status: status)

        case .healthCheck:
            HealthCheckCard(onAction: onAction)

        case .empty:
            EmptyTriageCard()
        }
    }
}

// MARK: - Triage Action

enum TriageAction {
    case accept
    case reject
    case correct
    case dismiss
    case viewDetails
    case startWorkout
    case markComplete
    case skip
    case reschedule
    case confirm
}

// MARK: - Block Proposal Card

struct BlockProposalCard: View {
    let workout: GeneratedWorkout
    let window: TimeWindow
    let onAction: (TriageAction) -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .font(.title2)
                    .foregroundColor(.blue)

                VStack(alignment: .leading) {
                    Text("Workout Proposal")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(window.start.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()
            }

            // Workout details
            HStack {
                WorkoutTypeIcon(type: workout.type)
                    .frame(width: 50, height: 50)

                VStack(alignment: .leading) {
                    Text(workout.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Text("\(workout.durationMinutes) minutes")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()
            }

            // Binary actions
            HStack(spacing: 16) {
                Button {
                    onAction(.reject)
                } label: {
                    Text("No")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button {
                    onAction(.accept)
                } label: {
                    Text("Yes")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(16)
    }
}

// MARK: - Block Confirmation Card

struct BlockConfirmationCard: View {
    let block: TrainingBlock
    let onAction: (TriageAction) -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.title2)
                    .foregroundColor(.orange)

                VStack(alignment: .leading) {
                    Text("Upcoming Workout")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(timeUntilBlock)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()
            }

            HStack {
                WorkoutTypeIcon(type: block.workoutType)
                    .frame(width: 50, height: 50)

                VStack(alignment: .leading) {
                    Text(block.workoutType.displayName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Text(block.startTime.formatted(date: .omitted, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()

                Button {
                    onAction(.startWorkout)
                } label: {
                    Image(systemName: "play.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.green)
                        .clipShape(Circle())
                }
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(16)
    }

    private var timeUntilBlock: String {
        let interval = block.startTime.timeIntervalSinceNow
        if interval < 0 { return "Starting now" }
        if interval < 60 { return "In less than a minute" }
        if interval < 3600 { return "In \(Int(interval / 60)) minutes" }
        return "In \(Int(interval / 3600)) hours"
    }
}

// MARK: - Workout Feedback Card

struct WorkoutFeedbackCard: View {
    let workout: DetectedWorkout
    let onAction: (TriageAction) -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)

                VStack(alignment: .leading) {
                    Text("Workout Logged")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(workout.startDate.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()
            }

            HStack {
                WorkoutTypeIcon(type: workout.type)
                    .frame(width: 50, height: 50)

                VStack(alignment: .leading) {
                    Text(workout.type.displayName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Text("\(workout.durationMinutes) min · \(Int(workout.activeCalories)) cal")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()
            }

            HStack(spacing: 16) {
                Button {
                    onAction(.correct)
                } label: {
                    Text("Wrong")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button {
                    onAction(.dismiss)
                } label: {
                    Text("Correct")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(16)
    }
}

// MARK: - Trust Progress Card

struct TrustProgressCard: View {
    let phase: TrustPhase
    let score: Double

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: phase.iconName)
                    .font(.title2)
                    .foregroundColor(.purple)

                VStack(alignment: .leading) {
                    Text("Trust Level")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(phase.displayName)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(phase.swiftUIColor)
                            .frame(width: geometry.size.width * CGFloat(score / 100), height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text(phase.capabilitySummary)
                        .font(.caption)
                        .foregroundColor(.gray)

                    Spacer()

                    Text("\(Int(score))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(16)
    }
}

extension TrustPhase {
    var swiftUIColor: Color {
        switch self {
        case .observer: return .gray
        case .scheduler: return .blue
        case .autoScheduler: return .green
        case .transformer: return .orange
        case .fullGhost: return .purple
        }
    }

    var capabilitySummary: String {
        switch self {
        case .observer: return "Learning your patterns"
        case .scheduler: return "Suggesting workouts"
        case .autoScheduler: return "Auto-scheduling"
        case .transformer: return "Adapting workouts"
        case .fullGhost: return "Full automation"
        }
    }
}

// MARK: - Weekly Receipt Card

struct WeeklyReceiptCard: View {
    let receipt: ValueReceipt

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(.blue)

                Text("Your Week")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()
            }

            HStack(spacing: 24) {
                StatView(value: "\(receipt.completedWorkouts)", label: "Workouts")
                StatView(value: "\(receipt.totalMinutes)", label: "Minutes")
                StatView(value: "\(receipt.streak)", label: "Day Streak")
            }

            if receipt.timeSavedMinutes > 0 {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.green)
                    Text("Ghost saved you \(receipt.timeSavedMinutes) minutes of planning")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(16)
    }
}

struct StatView: View {
    let value: String
    let label: String

    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Recovery Alert Card

struct RecoveryAlertCard: View {
    let status: TriageRecoveryStatus

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundColor(status.color)

                VStack(alignment: .leading) {
                    Text("Recovery Status")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(status.message)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(16)
    }
}

// MARK: - Health Check Card

struct HealthCheckCard: View {
    let onAction: (TriageAction) -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)

                VStack(alignment: .leading) {
                    Text("Ghost Needs Attention")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Some features may be limited")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()
            }

            Button {
                onAction(.viewDetails)
            } label: {
                Text("View Details")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .cornerRadius(8)
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(16)
    }
}

// MARK: - Empty Triage Card

struct EmptyTriageCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 40))
                .foregroundColor(.green)

            Text("All Clear")
                .font(.headline)
                .foregroundColor(.white)

            Text("The Ghost is working. Nothing needs your attention.")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(16)
    }
}

// MARK: - Workout Type Icon

struct WorkoutTypeIcon: View {
    let type: WorkoutType

    var body: some View {
        ZStack {
            Circle()
                .fill(type.swiftUIColor.opacity(0.2))

            Image(systemName: type.icon)
                .font(.title3)
                .foregroundColor(type.swiftUIColor)
        }
    }
}

extension WorkoutType {
    var icon: String {
        switch self {
        case .strength: return "dumbbell.fill"
        case .cardio: return "figure.run"
        case .hiit: return "bolt.fill"
        case .flexibility: return "figure.flexibility"
        case .recoveryWalk: return "figure.walk"
        case .lightCardio: return "figure.walk.motion"
        case .other: return "star.fill"
        }
    }

    var swiftUIColor: Color {
        switch self {
        case .strength: return .orange
        case .cardio: return .red
        case .hiit: return .yellow
        case .flexibility: return .mint
        case .recoveryWalk: return .teal
        case .lightCardio: return .green
        case .other: return .pink
        }
    }
}
