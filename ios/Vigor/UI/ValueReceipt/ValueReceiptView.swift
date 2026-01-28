//
//  ValueReceiptView.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Weekly value receipt showing Ghost's contributions.
//  Per PRD §4.2: "Why did my score change?" explainability
//

import SwiftUI

struct ValueReceiptView: View {
    let receipt: WeeklyReceipt
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    receiptHeader

                    // Summary stats
                    summarySection

                    // Week dots
                    weekDotsSection

                    // Ghost contributions
                    ghostContributionsSection

                    // Trust progress
                    trustProgressSection

                    // Time saved
                    timeSavedSection

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Weekly Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Receipt Header

    private var receiptHeader: some View {
        VStack(spacing: 8) {
            Text("Week of \(receipt.weekStartDate, style: .date)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(receiptGrade)
                .font(.system(size: 64, weight: .bold))
                .foregroundColor(gradeColor)

            Text(receiptSummary)
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    private var receiptGrade: String {
        switch receipt.completionRate {
        case 0.9...1.0: return "A+"
        case 0.8..<0.9: return "A"
        case 0.7..<0.8: return "B"
        case 0.6..<0.7: return "C"
        default: return "D"
        }
    }

    private var gradeColor: Color {
        switch receipt.completionRate {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .yellow
        default: return .orange
        }
    }

    private var receiptSummary: String {
        if receipt.completionRate >= 0.9 {
            return "Perfect week! Ghost kept you on track."
        } else if receipt.completionRate >= 0.7 {
            return "Solid week. Trust is building."
        } else if receipt.completionRate >= 0.5 {
            return "Room for improvement. Let's adjust."
        } else {
            return "Challenging week. Ghost is learning."
        }
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        HStack(spacing: 16) {
            SummaryCard(
                title: "Completed",
                value: "\(receipt.completedWorkouts)",
                subtitle: "of \(receipt.scheduledWorkouts)",
                icon: "checkmark.circle.fill",
                color: .green
            )

            SummaryCard(
                title: "Streak",
                value: "\(receipt.currentStreak)",
                subtitle: "days",
                icon: "flame.fill",
                color: .orange
            )

            SummaryCard(
                title: "Trust",
                value: "\(Int(receipt.trustDelta * 100))%",
                subtitle: receipt.trustDelta >= 0 ? "gained" : "lost",
                icon: receipt.trustDelta >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
                color: receipt.trustDelta >= 0 ? .green : .red
            )
        }
    }

    // MARK: - Week Dots

    private var weekDotsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Week")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(0..<7, id: \.self) { dayIndex in
                    VStack(spacing: 4) {
                        dayDot(for: dayIndex)
                        Text(dayLabel(for: dayIndex))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private func dayDot(for index: Int) -> some View {
        let status = receipt.dailyStatus[index]
        return Circle()
            .fill(dotColor(for: status))
            .frame(width: 32, height: 32)
            .overlay {
                Image(systemName: dotIcon(for: status))
                    .foregroundColor(.white)
                    .font(.caption)
            }
    }

    private func dotColor(for status: DayStatus) -> Color {
        switch status {
        case .completed: return .green
        case .missed: return .red
        case .excused: return .yellow
        case .rest: return .gray.opacity(0.3)
        case .scheduled: return .blue.opacity(0.3)
        }
    }

    private func dotIcon(for status: DayStatus) -> String {
        switch status {
        case .completed: return "checkmark"
        case .missed: return "xmark"
        case .excused: return "pause"
        case .rest: return "moon.zzz"
        case .scheduled: return "calendar"
        }
    }

    private func dayLabel(for index: Int) -> String {
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        return days[index]
    }

    // MARK: - Ghost Contributions

    private var ghostContributionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ghost Contributions")
                .font(.headline)

            ForEach(receipt.ghostContributions, id: \.description) { contribution in
                HStack(spacing: 12) {
                    Image(systemName: contribution.icon)
                        .foregroundColor(.blue)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(contribution.description)
                            .font(.subheadline)
                        Text(contribution.impact)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Trust Progress

    private var trustProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trust Progress")
                .font(.headline)

            VStack(spacing: 8) {
                ProgressView(value: receipt.currentTrustLevel)
                    .tint(trustColor)

                HStack {
                    Text(receipt.currentPhase.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    if let nextPhase = receipt.currentPhase.nextPhase {
                        Text("\(Int((receipt.nextPhaseThreshold - receipt.currentTrustLevel) * 100))% to \(nextPhase.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var trustColor: Color {
        switch receipt.currentPhase {
        case .observer: return .gray
        case .scheduler: return .blue
        case .autoScheduler: return .purple
        case .transformer: return .orange
        case .fullGhost: return .green
        }
    }

    // MARK: - Time Saved

    private var timeSavedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Saved by Ghost")
                .font(.headline)

            HStack {
                VStack(alignment: .leading) {
                    Text("\(receipt.minutesSaved)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.blue)
                    Text("minutes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("This includes:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(receipt.schedulingDecisions) scheduling decisions")
                        .font(.caption)
                    Text("\(receipt.conflictResolutions) conflict resolutions")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Types

struct WeeklyReceipt {
    let weekStartDate: Date
    let completedWorkouts: Int
    let scheduledWorkouts: Int
    let currentStreak: Int
    let trustDelta: Double
    let dailyStatus: [DayStatus]
    let ghostContributions: [GhostContribution]
    let currentPhase: TrustPhase
    let currentTrustLevel: Double
    let nextPhaseThreshold: Double
    let minutesSaved: Int
    let schedulingDecisions: Int
    let conflictResolutions: Int

    var completionRate: Double {
        guard scheduledWorkouts > 0 else { return 0 }
        return Double(completedWorkouts) / Double(scheduledWorkouts)
    }
}

enum DayStatus {
    case completed
    case missed
    case excused
    case rest
    case scheduled
}

struct GhostContribution {
    let description: String
    let impact: String
    let icon: String
}

// MARK: - TrustPhase Extension

extension TrustPhase {
    var displayName: String {
        switch self {
        case .observer: return "Observer"
        case .scheduler: return "Scheduler"
        case .autoScheduler: return "Auto-Scheduler"
        case .transformer: return "Transformer"
        case .fullGhost: return "Full Ghost"
        }
    }

    var nextPhase: TrustPhase? {
        switch self {
        case .observer: return .scheduler
        case .scheduler: return .autoScheduler
        case .autoScheduler: return .transformer
        case .transformer: return .fullGhost
        case .fullGhost: return nil
        }
    }
}

// MARK: - Preview

#Preview {
    ValueReceiptView(
        receipt: WeeklyReceipt(
            weekStartDate: Date(),
            completedWorkouts: 4,
            scheduledWorkouts: 5,
            currentStreak: 12,
            trustDelta: 0.08,
            dailyStatus: [.completed, .completed, .rest, .completed, .missed, .completed, .rest],
            ghostContributions: [
                GhostContribution(
                    description: "Rescheduled Thursday workout",
                    impact: "Avoided conflict with team meeting",
                    icon: "arrow.triangle.swap"
                ),
                GhostContribution(
                    description: "Detected recovery need",
                    impact: "Added rest day on Wednesday",
                    icon: "heart.fill"
                ),
                GhostContribution(
                    description: "Optimized Friday timing",
                    impact: "Used your peak energy window",
                    icon: "bolt.fill"
                )
            ],
            currentPhase: .autoScheduler,
            currentTrustLevel: 0.62,
            nextPhaseThreshold: 0.70,
            minutesSaved: 45,
            schedulingDecisions: 8,
            conflictResolutions: 2
        )
    )
}
