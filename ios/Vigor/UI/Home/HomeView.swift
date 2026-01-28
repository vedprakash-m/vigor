//
//  HomeView.swift
//  Vigor
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Main home view - minimalist Ghost-centric interface.
//  Per PRD §4.2: One triage card at a time, Ghost status always visible.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var ghostEngine: GhostEngine
    @EnvironmentObject private var trustMachine: TrustStateMachine
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Ghost Status Header
                        GhostStatusHeader(
                            phase: viewModel.trustPhase,
                            healthMode: viewModel.healthMode,
                            score: viewModel.trustScore
                        )
                        .padding(.horizontal)

                        // Single Triage Card
                        if let triageItem = viewModel.currentTriageItem {
                            TriageCard(item: triageItem) { action in
                                Task {
                                    await viewModel.handleTriageAction(action)
                                }
                            }
                            .padding(.horizontal)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        } else {
                            TriageCard(item: .empty) { _ in }
                                .padding(.horizontal)
                        }

                        // Week Overview
                        WeekOverviewView(
                            blocks: viewModel.weekBlocks,
                            completedCount: viewModel.completedThisWeek
                        )
                        .padding(.horizontal)

                        // Quick Actions (minimal)
                        QuickActionsView(
                            onStartWorkout: { viewModel.showWorkoutPicker = true },
                            onViewCalendar: { viewModel.showCalendarView = true }
                        )
                        .padding(.horizontal)

                        Spacer(minLength: 100)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Vigor")
                        .font(.headline)
                        .foregroundColor(.white)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.gray)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showWorkoutPicker) {
                WorkoutPickerSheet(
                    onSelect: { workout in
                        Task {
                            await viewModel.startManualWorkout(workout)
                        }
                    }
                )
            }
            .sheet(isPresented: $viewModel.showCalendarView) {
                CalendarDetailView(blocks: viewModel.allBlocks)
            }
        }
        .onAppear {
            Task {
                await viewModel.refresh()
            }
        }
    }
}

// MARK: - Home View Model

@MainActor
class HomeViewModel: ObservableObject {
    @Published var currentTriageItem: TriageItemType?
    @Published var weekBlocks: [TrainingBlock] = []
    @Published var allBlocks: [TrainingBlock] = []
    @Published var completedThisWeek: Int = 0
    @Published var trustPhase: TrustPhase = .observer
    @Published var trustScore: Double = 0
    @Published var healthMode: GhostHealthMode = .healthy
    @Published var showWorkoutPicker = false
    @Published var showCalendarView = false

    func refresh() async {
        // Get current trust state
        let trustState = await TrustStateMachine.shared.getState()
        trustPhase = trustState.phase
        trustScore = trustState.score

        // Get health mode
        let health = await GhostHealthMonitor.shared.getHealth()
        healthMode = health.mode

        // Get week blocks
        let startOfWeek = Calendar.current.startOfWeek(for: Date())
        let endOfWeek = Calendar.current.date(byAdding: .day, value: 7, to: startOfWeek)!
        weekBlocks = await CalendarScheduler.shared.getBlocks(from: startOfWeek, to: endOfWeek)
        allBlocks = await CalendarScheduler.shared.getBlocks(
            from: Date(),
            to: Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        )

        // Count completed
        completedThisWeek = weekBlocks.filter { $0.status == .completed }.count

        // Determine current triage item
        currentTriageItem = await determineTriageItem()
    }

    private func determineTriageItem() async -> TriageItemType? {
        // Priority order for triage items:

        // 1. Health check if Ghost is in degraded mode
        if healthMode != .healthy {
            return .healthCheck
        }

        // 2. Upcoming workout in next 30 minutes
        if let upcomingBlock = weekBlocks.first(where: { block in
            block.status == .scheduled &&
            block.scheduledStart > Date() &&
            block.scheduledStart < Date().addingTimeInterval(30 * 60)
        }) {
            return .blockConfirmation(upcomingBlock)
        }

        // 3. Pending proposal
        if let proposal = await GhostEngine.shared.getPendingProposal() {
            return .blockProposal(proposal.workout, proposal.window)
        }

        // 4. Recent workout needing confirmation
        if let recentWorkout = await GhostEngine.shared.getUnconfirmedWorkout() {
            return .workoutFeedback(recentWorkout)
        }

        // 5. Weekly receipt on Sundays
        let calendar = Calendar.current
        if calendar.component(.weekday, from: Date()) == 1 { // Sunday
            if let receipt = await generateWeeklyReceipt() {
                return .weeklyReceipt(receipt)
            }
        }

        // 6. Trust progress (show occasionally)
        if shouldShowTrustProgress() {
            return .trustProgress(trustPhase, trustScore)
        }

        return nil
    }

    private func shouldShowTrustProgress() -> Bool {
        // Show trust progress if close to phase transition
        let state = trustScore
        let thresholds = [20.0, 40.0, 60.0, 80.0]

        for threshold in thresholds {
            if abs(state - threshold) < 5 {
                return true
            }
        }
        return false
    }

    private func generateWeeklyReceipt() async -> ValueReceipt? {
        let calendar = Calendar.current
        let startOfWeek = calendar.startOfWeek(for: Date())
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!

        let scheduled = weekBlocks.count
        let completed = weekBlocks.filter { $0.status == .completed }.count
        let missed = weekBlocks.filter { $0.status == .missed }.count

        let totalMinutes = weekBlocks
            .filter { $0.status == .completed }
            .reduce(0) { $0 + Int($1.scheduledEnd.timeIntervalSince($1.scheduledStart) / 60) }

        return ValueReceipt(
            weekStartDate: startOfWeek,
            weekEndDate: endOfWeek,
            completedWorkouts: completed,
            scheduledWorkouts: scheduled,
            missedWorkouts: missed,
            totalMinutes: totalMinutes,
            timeSavedMinutes: completed * 5, // Estimated planning time saved
            patternsDiscovered: [],
            trustProgress: nil,
            streak: await calculateStreak()
        )
    }

    private func calculateStreak() async -> Int {
        // Calculate consecutive days with completed workouts
        return 0 // Placeholder
    }

    func handleTriageAction(_ action: TriageAction) async {
        switch action {
        case .accept:
            if case .blockProposal(let workout, let window) = currentTriageItem {
                try? await CalendarScheduler.shared.createBlock(workout, in: window)
                await TrustStateMachine.shared.recordEvent(.proposalAccepted)
            }

        case .reject:
            if case .blockProposal = currentTriageItem {
                await TrustStateMachine.shared.recordEvent(.proposalRejected)
            }

        case .correct:
            // Open workout correction UI
            break

        case .dismiss:
            break

        case .viewDetails:
            // Open Ghost health details
            break

        case .startWorkout:
            if case .blockConfirmation(let block) = currentTriageItem {
                await startBlockWorkout(block)
            }

        case .markComplete:
            break
        }

        // Refresh to get next triage item
        withAnimation {
            currentTriageItem = nil
        }

        await refresh()
    }

    func startManualWorkout(_ type: WorkoutType) async {
        // Create and start a manual workout
    }

    private func startBlockWorkout(_ block: TrainingBlock) async {
        // Transition to workout tracking
    }
}

// MARK: - Ghost Status Header

struct GhostStatusHeader: View {
    let phase: TrustPhase
    let healthMode: GhostHealthMode
    let score: Double

    var body: some View {
        HStack(spacing: 16) {
            // Ghost icon with status indicator
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: "sparkles")
                    .font(.title)
                    .foregroundColor(statusColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(phase.displayName)
                        .font(.headline)
                        .foregroundColor(.white)

                    if healthMode != .healthy {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }

                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            // Mini progress ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: 44, height: 44)

                Circle()
                    .trim(from: 0, to: score / 100)
                    .stroke(phase.color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(score))")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }

    private var statusColor: Color {
        switch healthMode {
        case .healthy: return .green
        case .degraded: return .yellow
        case .safeMode: return .orange
        case .suspended: return .red
        }
    }

    private var statusMessage: String {
        switch healthMode {
        case .healthy:
            return "Ghost is active and learning"
        case .degraded:
            return "Running with limited features"
        case .safeMode:
            return "Safe mode - minimal actions"
        case .suspended:
            return "Ghost is paused"
        }
    }
}

// MARK: - Week Overview

struct WeekOverviewView: View {
    let blocks: [TrainingBlock]
    let completedCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("This Week")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Text("\(completedCount)/\(blocks.count)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            // Day indicators
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { dayOffset in
                    DayIndicator(
                        dayOffset: dayOffset,
                        blocks: blocksForDay(dayOffset)
                    )
                }
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }

    private func blocksForDay(_ offset: Int) -> [TrainingBlock] {
        let calendar = Calendar.current
        let startOfWeek = calendar.startOfWeek(for: Date())
        let targetDate = calendar.date(byAdding: .day, value: offset, to: startOfWeek)!

        return blocks.filter { block in
            calendar.isDate(block.scheduledStart, inSameDayAs: targetDate)
        }
    }
}

struct DayIndicator: View {
    let dayOffset: Int
    let blocks: [TrainingBlock]

    private let dayLetters = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(spacing: 4) {
            Text(dayLetters[dayOffset])
                .font(.caption2)
                .foregroundColor(.gray)

            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 32, height: 32)

                if !blocks.isEmpty {
                    Image(systemName: iconName)
                        .font(.caption)
                        .foregroundColor(iconColor)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var backgroundColor: Color {
        if blocks.isEmpty { return Color.gray.opacity(0.2) }

        let hasCompleted = blocks.contains { $0.status == .completed }
        let hasMissed = blocks.contains { $0.status == .missed }
        let hasScheduled = blocks.contains { $0.status == .scheduled }

        if hasCompleted { return Color.green.opacity(0.3) }
        if hasMissed { return Color.red.opacity(0.3) }
        if hasScheduled { return Color.blue.opacity(0.3) }

        return Color.gray.opacity(0.2)
    }

    private var iconName: String {
        if blocks.contains(where: { $0.status == .completed }) {
            return "checkmark"
        }
        if blocks.contains(where: { $0.status == .missed }) {
            return "xmark"
        }
        if blocks.contains(where: { $0.status == .scheduled }) {
            return "clock"
        }
        return ""
    }

    private var iconColor: Color {
        if blocks.contains(where: { $0.status == .completed }) {
            return .green
        }
        if blocks.contains(where: { $0.status == .missed }) {
            return .red
        }
        return .blue
    }
}

// MARK: - Quick Actions

struct QuickActionsView: View {
    let onStartWorkout: () -> Void
    let onViewCalendar: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onStartWorkout) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Quick Workout")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.2))
                .foregroundColor(.blue)
                .cornerRadius(8)
            }

            Button(action: onViewCalendar) {
                HStack {
                    Image(systemName: "calendar")
                    Text("View Schedule")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Helper Extensions

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }
}

// MARK: - Placeholder Views

struct SettingsView: View {
    var body: some View {
        Text("Settings")
            .foregroundColor(.white)
    }
}

struct WorkoutPickerSheet: View {
    let onSelect: (WorkoutType) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(WorkoutType.allCases, id: \.self) { type in
                Button {
                    onSelect(type)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: type.icon)
                            .foregroundColor(type.color)
                        Text(type.displayName)
                    }
                }
            }
            .navigationTitle("Start Workout")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct CalendarDetailView: View {
    let blocks: [TrainingBlock]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(blocks, id: \.id) { block in
                HStack {
                    Image(systemName: block.workoutType.icon)
                        .foregroundColor(block.workoutType.color)

                    VStack(alignment: .leading) {
                        Text(block.workoutType.displayName)
                        Text(block.scheduledStart.formatted())
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Text(block.status.rawValue)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Schedule")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
