//
//  TriageCardView.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  The morning triage card - the primary Ghost interaction point.
//  Designed for quick, one-tap responses.
//

import SwiftUI

struct TriageCardView: View {
    let card: TriageCardData
    let onAction: (TriageAction) -> Void

    @State private var selectedAction: TriageAction?
    @State private var isExpanded = false
    @State private var showRescheduleOptions = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            // Header
            cardHeader

            Divider()
                .background(Color.gray.opacity(0.2))

            // Main content
            if showRescheduleOptions {
                rescheduleView
            } else {
                mainContent
            }

            Divider()
                .background(Color.gray.opacity(0.2))

            // Action buttons
            actionButtons
        }
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
        .padding(.horizontal)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Training card for \(card.workoutType.displayName) at \(card.formattedTime)")
    }

    // MARK: - Header

    private var cardHeader: some View {
        HStack {
            // Workout type icon
            ZStack {
                Circle()
                    .fill(card.workoutType.swiftUIColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: card.workoutType.iconName)
                    .font(.title3)
                    .foregroundColor(card.workoutType.swiftUIColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(card.workoutType.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(card.formattedTime)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text("\(card.duration) min")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Recovery indicator
            recoveryBadge
        }
        .padding()
    }

    private var recoveryBadge: some View {
        VStack(spacing: 2) {
            Text("\(card.recoveryScore)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(recoveryColor)

            Text("Recovery")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 60)
        .accessibilityLabel("Recovery score: \(card.recoveryScore) percent")
    }

    private var recoveryColor: Color {
        switch card.recoveryScore {
        case 80...: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 16) {
            // Ghost insight
            if let insight = card.ghostInsight {
                HStack(spacing: 12) {
                    Image(systemName: "eye.slash.fill")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text(insight)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 16)
            }

            // Recovery warning if low
            if card.recoveryScore < 60 {
                lowRecoveryWarning
            }

            Spacer().frame(height: 8)
        }
    }

    private var lowRecoveryWarning: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Low Recovery Detected")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(card.recoveryReason ?? "Consider a lighter session")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Reschedule View

    private var rescheduleView: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: {
                    withAnimation(reduceMotion ? .none : .spring()) {
                        showRescheduleOptions = false
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("Choose a new time")
                    .font(.headline)

                Spacer()

                // Spacer for symmetry
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.clear)
            }
            .padding(.horizontal)
            .padding(.top, 16)

            // Alternative slots
            ForEach(card.alternativeSlots, id: \.time) { slot in
                Button(action: {
                    selectedAction = .reschedule
                    onAction(.reschedule)
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(slot.formattedTime)
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text(slot.reason)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)

            Spacer().frame(height: 8)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Skip button
            ActionButton(
                title: "Not Today",
                icon: "xmark",
                style: .secondary,
                isSelected: selectedAction == .skip
            ) {
                withAnimation(reduceMotion ? .none : .spring()) {
                    selectedAction = .skip
                }
                onAction(.skip)
            }

            // Reschedule button
            ActionButton(
                title: "Later",
                icon: "clock.arrow.circlepath",
                style: .secondary,
                isSelected: selectedAction == .reschedule
            ) {
                withAnimation(reduceMotion ? .none : .spring()) {
                    showRescheduleOptions = true
                }
            }

            // Confirm button
            ActionButton(
                title: "Ready",
                icon: "checkmark",
                style: .primary,
                isSelected: selectedAction == .confirm
            ) {
                withAnimation(reduceMotion ? .none : .spring()) {
                    selectedAction = .confirm
                }
                onAction(.confirm)
            }
        }
        .padding()
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let title: String
    let icon: String
    let style: ActionButtonStyle
    let isSelected: Bool
    let action: () -> Void

    enum ActionButtonStyle {
        case primary
        case secondary
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(borderColor, lineWidth: style == .secondary ? 1 : 0)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to \(title.lowercased())")
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return isSelected ? .green : .blue
        case .secondary:
            return isSelected ? Color(.secondarySystemBackground) : Color(.systemBackground)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return isSelected ? .primary : .secondary
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary:
            return .clear
        case .secondary:
            return Color.gray.opacity(0.3)
        }
    }
}

// MARK: - Data Models

struct TriageCardData {
    let id: UUID
    let workoutType: WorkoutType
    let scheduledTime: Date
    let duration: Int
    let recoveryScore: Int
    let recoveryReason: String?
    let ghostInsight: String?
    let alternativeSlots: [AlternativeSlot]

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: scheduledTime)
    }
}

struct AlternativeSlot {
    let time: Date
    let reason: String

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: time)
    }
}

// WorkoutType.iconName defined in HealthKitTypes.swift
// WorkoutType.swiftUIColor defined in TriageCard.swift

// MARK: - Preview

#Preview {
    VStack {
        Spacer()

        TriageCardView(
            card: TriageCardData(
                id: UUID(),
                workoutType: .strength,
                scheduledTime: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!,
                duration: 45,
                recoveryScore: 78,
                recoveryReason: nil,
                ghostInsight: "Tuesdays at 7 AM have 85% completion rate",
                alternativeSlots: [
                    AlternativeSlot(
                        time: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!,
                        reason: "Lunch break - clear calendar"
                    ),
                    AlternativeSlot(
                        time: Calendar.current.date(bySettingHour: 18, minute: 30, second: 0, of: Date())!,
                        reason: "After work"
                    )
                ]
            )
        ) { action in
            print("Selected: \(action)")
        }

        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Low Recovery") {
    VStack {
        Spacer()

        TriageCardView(
            card: TriageCardData(
                id: UUID(),
                workoutType: .hiit,
                scheduledTime: Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: Date())!,
                duration: 30,
                recoveryScore: 45,
                recoveryReason: "Poor sleep detected (5h 12m). Consider mobility instead.",
                ghostInsight: "HRV 22% below your baseline",
                alternativeSlots: []
            )
        ) { action in
            print("Selected: \(action)")
        }

        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}
