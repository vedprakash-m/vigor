//
//  SettingsView.swift
//  Vigor
//
//  Full settings interface per PRD §4.8 and UX Spec.
//  Sections: Trust Phase, Workout Preferences, Sacred Times,
//  Ghost Status, Data & Privacy, About.
//

import SwiftUI
import EventKit
import HealthKit

// MARK: - Main Settings View

struct SettingsView: View {
    @EnvironmentObject private var trustState: TrustStateMachine
    @StateObject private var healthKit = HealthKitObserver.shared
    @StateObject private var healthMonitor = GhostHealthMonitor.shared
    @StateObject private var viewModel = SettingsViewModel()

    @AppStorage("notifications_enabled") private var notificationsEnabled = true
    @AppStorage("haptics_enabled") private var hapticsEnabled = true

    var body: some View {
        List {
            trustPhaseSection
            workoutPreferencesSection
            sacredTimesSection
            ghostStatusSection
            notificationsSection
            dataPrivacySection
            aboutSection
            dangerZoneSection
        }
        .navigationTitle("Settings")
        .task {
            await viewModel.load()
        }
        .sheet(isPresented: $viewModel.showAddSacredTime) {
            AddSacredTimeSheet { sacred in
                Task { await viewModel.addSacredTime(sacred) }
            }
        }
        .sheet(isPresented: $viewModel.showEditPreferences) {
            EditPreferencesSheet(
                preferences: viewModel.preferences
            ) { updated in
                Task { await viewModel.updatePreferences(updated) }
            }
        }
    }

    // MARK: - Trust Phase

    private var trustPhaseSection: some View {
        Section {
            // Current phase display
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(trustPhaseColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: trustState.currentPhase.iconName)
                        .font(.title3)
                        .foregroundColor(trustPhaseColor)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(trustState.currentPhase.displayName)
                        .font(.headline)
                    Text(trustState.currentPhase.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            // Trust score progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Trust Score")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(trustState.trustScore))")
                        .font(.subheadline.monospacedDigit().bold())
                }
                ProgressView(value: trustState.trustScore, total: 100)
                    .tint(trustPhaseColor)

                if let nextPhase = trustState.currentPhase.next {
                    Text("Next: \(nextPhase.displayName)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // Phase capabilities
            DisclosureGroup("Capabilities") {
                ForEach(trustState.currentPhase.capabilities, id: \.self) { cap in
                    Label(cap.displayName, systemImage: capabilityIcon(cap))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Manual retreat
            if trustState.currentPhase != .observer {
                Button(role: .destructive) {
                    viewModel.showRetreatConfirm = true
                } label: {
                    Label("Reduce Ghost Autonomy", systemImage: "arrow.uturn.backward")
                }
                .alert("Reduce Trust Phase?", isPresented: $viewModel.showRetreatConfirm) {
                    Button("Reduce", role: .destructive) {
                        Task { await viewModel.retreatPhase() }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    if let prev = trustState.currentPhase.previous {
                        Text("This will move the Ghost back to \(prev.displayName) phase. The Ghost will lose some autonomy.")
                    }
                }
            }
        } header: {
            Text("Ghost Trust Level")
        }
    }

    // MARK: - Workout Preferences

    private var workoutPreferencesSection: some View {
        Section {
            LabeledContent("Preferred Time") {
                Text(viewModel.preferences.preferredTimeOfDay.capitalized)
            }
            LabeledContent("Session Duration") {
                Text("\(viewModel.preferences.sessionDurationMinutes) min")
            }
            LabeledContent("Days / Week") {
                Text("\(viewModel.preferences.preferredDays.count)")
            }
            if !viewModel.preferences.equipment.isEmpty {
                LabeledContent("Equipment") {
                    Text(viewModel.preferences.equipment.joined(separator: ", "))
                        .lineLimit(1)
                }
            }
            if !viewModel.preferences.injuries.isEmpty {
                LabeledContent("Injury Notes") {
                    Text(viewModel.preferences.injuries.joined(separator: ", "))
                        .foregroundStyle(.orange)
                        .lineLimit(1)
                }
            }
            Button {
                viewModel.showEditPreferences = true
            } label: {
                Label("Edit Preferences", systemImage: "pencil")
            }
        } header: {
            Text("Workout Preferences")
        }
    }

    // MARK: - Sacred Times

    private var sacredTimesSection: some View {
        Section {
            if viewModel.sacredTimes.isEmpty {
                Text("No sacred times declared yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Sacred times are slots the Ghost will never schedule over. They can be auto-detected from repeated block deletions.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(viewModel.sacredTimes) { sacred in
                    HStack {
                        Image(systemName: "clock.badge.xmark")
                            .foregroundColor(.red)
                        VStack(alignment: .leading) {
                            Text(dayName(sacred.dayOfWeek) + " at " + hourLabel(sacred.hourOfDay))
                                .font(.subheadline)
                            Text(sacred.reason.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    Task { await viewModel.removeSacredTimes(at: offsets) }
                }
            }
            Button {
                viewModel.showAddSacredTime = true
            } label: {
                Label("Add Sacred Time", systemImage: "plus")
            }
        } header: {
            Text("Sacred Times")
        }
    }

    // MARK: - Ghost Status

    private var ghostStatusSection: some View {
        Section {
            LabeledContent("Health Mode") {
                HStack(spacing: 4) {
                    Circle()
                        .fill(healthModeColor)
                        .frame(width: 8, height: 8)
                    Text(healthMonitor.currentMode.displayName)
                }
            }
            LabeledContent("Health Score") {
                Text("\(Int(healthMonitor.healthScore))%")
                    .foregroundStyle(healthMonitor.healthScore >= 70 ? .green : healthMonitor.healthScore >= 40 ? .yellow : .red)
            }
            if let lastCheck = healthMonitor.lastHealthCheck {
                LabeledContent("Last Check") {
                    Text(lastCheck, style: .relative)
                }
            }
            if !healthMonitor.issues.isEmpty {
                DisclosureGroup("Active Issues (\(healthMonitor.issues.count))") {
                    ForEach(healthMonitor.issues.prefix(5), id: \.timestamp) { issue in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(issue.description)
                                .font(.caption)
                            Text(issue.timestamp, style: .relative)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        } header: {
            Text("Ghost Status")
        }
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        Section {
            Toggle("Ghost Notifications", isOn: $notificationsEnabled)
            Toggle("Haptic Feedback", isOn: $hapticsEnabled)
        } header: {
            Text("Notifications & Feedback")
        } footer: {
            Text("The Ghost sends at most 1 notification per day.")
        }
    }

    // MARK: - Data & Privacy

    private var dataPrivacySection: some View {
        Section {
            LabeledContent("HealthKit") {
                HStack(spacing: 4) {
                    Circle()
                        .fill(healthKit.isAuthorized ? .green : .red)
                        .frame(width: 8, height: 8)
                    Text(healthKit.isAuthorized ? "Connected" : "Not Connected")
                }
            }
            if let lastSync = healthKit.lastSyncDate {
                LabeledContent("Last HealthKit Sync") {
                    Text(lastSync, style: .relative)
                }
            }

            LabeledContent("Calendar") {
                let status = EKEventStore.authorizationStatus(for: .event)
                HStack(spacing: 4) {
                    Circle()
                        .fill(status == .fullAccess || status == .authorized ? .green : .red)
                        .frame(width: 8, height: 8)
                    Text(calendarStatusText(status))
                }
            }

            LabeledContent("Data Retention") {
                Text("90 days")
            }

            NavigationLink {
                DataManagementView()
            } label: {
                Label("Manage Data", systemImage: "externaldrive")
            }
        } header: {
            Text("Data & Privacy")
        } footer: {
            Text("Vigor processes all health data on-device. Only anonymized analytics are sent to the server.")
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            LabeledContent("Version") {
                Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
            }
            LabeledContent("Build") {
                Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1")
            }
            NavigationLink {
                TrustPhaseExplainerView()
            } label: {
                Label("How Trust Works", systemImage: "info.circle")
            }
        } header: {
            Text("About Vigor")
        }
    }

    // MARK: - Danger Zone

    private var dangerZoneSection: some View {
        Section {
            Button("Reset Onboarding", role: .destructive) {
                viewModel.showResetConfirm = true
            }
            .alert("Reset Onboarding?", isPresented: $viewModel.showResetConfirm) {
                Button("Reset", role: .destructive) {
                    UserDefaults.standard.removeObject(forKey: "onboarding_completed")
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will restart the initial setup flow. Your data will not be deleted.")
            }
        }
    }

    // MARK: - Helpers

    private var trustPhaseColor: Color {
        switch trustState.currentPhase {
        case .observer:       return .gray
        case .scheduler:      return .blue
        case .autoScheduler:  return .green
        case .transformer:    return .purple
        case .fullGhost:      return .orange
        }
    }

    private var healthModeColor: Color {
        switch healthMonitor.currentMode {
        case .healthy:   return .green
        case .degraded:  return .yellow
        case .safeMode:  return .orange
        case .suspended: return .red
        }
    }

    private func capabilityIcon(_ cap: TrustCapability) -> String {
        switch cap {
        case .readHealthKit:    return "heart.text.square"
        case .readCalendar:     return "calendar"
        case .learnPatterns:    return "brain"
        case .proposeBlocks:    return "lightbulb"
        case .createBlocks:     return "calendar.badge.plus"
        case .transformBlocks:  return "arrow.triangle.2.circlepath"
        case .removeBlocks:     return "trash"
        }
    }

    private func dayName(_ day: Int) -> String {
        let names = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return day >= 1 && day <= 7 ? names[day] : "Unknown"
    }

    private func hourLabel(_ hour: Int) -> String {
        if hour == 0 { return "12 AM" }
        if hour < 12 { return "\(hour) AM" }
        if hour == 12 { return "12 PM" }
        return "\(hour - 12) PM"
    }

    private func calendarStatusText(_ status: EKAuthorizationStatus) -> String {
        switch status {
        case .authorized, .fullAccess: return "Connected"
        case .denied, .restricted:     return "Denied"
        case .notDetermined:           return "Not Set"
        case .writeOnly:               return "Write Only"
        @unknown default:              return "Unknown"
        }
    }
}

// MARK: - Settings View Model

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var preferences: WorkoutPreferences = .default
    @Published var sacredTimes: [SacredTime] = []
    @Published var showAddSacredTime = false
    @Published var showEditPreferences = false
    @Published var showRetreatConfirm = false
    @Published var showResetConfirm = false

    func load() async {
        let store = BehavioralMemoryStore.shared
        preferences = await store.workoutPreferences
        sacredTimes = await store.getSacredTimes()
    }

    func updatePreferences(_ updated: WorkoutPreferences) async {
        await BehavioralMemoryStore.shared.updatePreferences(updated)
        preferences = updated
    }

    func addSacredTime(_ sacred: SacredTime) async {
        await BehavioralMemoryStore.shared.addSacredTime(sacred)
        sacredTimes = await BehavioralMemoryStore.shared.getSacredTimes()
    }

    func removeSacredTimes(at offsets: IndexSet) async {
        for index in offsets {
            let sacred = sacredTimes[index]
            await BehavioralMemoryStore.shared.removeSacredTime(
                dayOfWeek: sacred.dayOfWeek,
                hourOfDay: sacred.hourOfDay
            )
        }
        sacredTimes = await BehavioralMemoryStore.shared.getSacredTimes()
    }

    func retreatPhase() async {
        await TrustStateMachine.shared.manualRetreat()
    }
}

// MARK: - Add Sacred Time Sheet

struct AddSacredTimeSheet: View {
    let onSave: (SacredTime) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDay = 1
    @State private var selectedHour = 9

    private let days = [
        (1, "Sunday"), (2, "Monday"), (3, "Tuesday"), (4, "Wednesday"),
        (5, "Thursday"), (6, "Friday"), (7, "Saturday")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Picker("Day", selection: $selectedDay) {
                    ForEach(days, id: \.0) { day in
                        Text(day.1).tag(day.0)
                    }
                }
                Picker("Hour", selection: $selectedHour) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(hourLabel(hour)).tag(hour)
                    }
                }
                Section {
                    Text("The Ghost will never schedule workouts during this time slot.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Sacred Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let sacred = SacredTime(
                            dayOfWeek: selectedDay,
                            hourOfDay: selectedHour,
                            reason: .userSpecified
                        )
                        onSave(sacred)
                        dismiss()
                    }
                }
            }
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        if hour == 0 { return "12 AM" }
        if hour < 12 { return "\(hour) AM" }
        if hour == 12 { return "12 PM" }
        return "\(hour - 12) PM"
    }
}

// MARK: - Edit Preferences Sheet

struct EditPreferencesSheet: View {
    let preferences: WorkoutPreferences
    let onSave: (WorkoutPreferences) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var days: Set<Int> = []
    @State private var timeOfDay = "morning"
    @State private var duration = 45
    @State private var equipmentText = ""
    @State private var injuryText = ""

    private let timeOptions = ["morning", "afternoon", "evening"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Preferred Days") {
                    ForEach(daysList, id: \.0) { day in
                        Toggle(day.1, isOn: Binding(
                            get: { days.contains(day.0) },
                            set: { on in
                                if on { days.insert(day.0) } else { days.remove(day.0) }
                            }
                        ))
                    }
                }

                Section("Time of Day") {
                    Picker("Preferred Time", selection: $timeOfDay) {
                        ForEach(timeOptions, id: \.self) { t in
                            Text(t.capitalized).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Session Duration") {
                    Stepper("\(duration) minutes", value: $duration, in: 15...120, step: 5)
                }

                Section {
                    TextField("e.g. dumbbells, barbell, pull-up bar", text: $equipmentText)
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Equipment")
                } footer: {
                    Text("Comma-separated. Leave empty for bodyweight only.")
                }

                Section {
                    TextField("e.g. shoulder, lower back", text: $injuryText)
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Injury Notes")
                } footer: {
                    Text("The Ghost will avoid exercises that stress these areas.")
                }
            }
            .navigationTitle("Workout Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let equipment = equipmentText
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                            .filter { !$0.isEmpty }
                        let injuries = injuryText
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                            .filter { !$0.isEmpty }

                        let updated = WorkoutPreferences(
                            preferredDays: Array(days).sorted(),
                            preferredTimeOfDay: timeOfDay,
                            sessionDurationMinutes: duration,
                            equipment: equipment,
                            goals: preferences.goals,
                            injuries: injuries
                        )
                        onSave(updated)
                        dismiss()
                    }
                }
            }
            .onAppear {
                days = Set(preferences.preferredDays)
                timeOfDay = preferences.preferredTimeOfDay
                duration = preferences.sessionDurationMinutes
                equipmentText = preferences.equipment.joined(separator: ", ")
                injuryText = preferences.injuries.joined(separator: ", ")
            }
        }
    }

    private var daysList: [(Int, String)] {
        [(2, "Monday"), (3, "Tuesday"), (4, "Wednesday"), (5, "Thursday"),
         (6, "Friday"), (7, "Saturday"), (1, "Sunday")]
    }
}

// MARK: - Data Management View

struct DataManagementView: View {
    @State private var showDeleteConfirm = false
    @State private var isExporting = false

    var body: some View {
        List {
            Section {
                LabeledContent("Health Data") {
                    Text("On-device only")
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Decision Receipts") {
                    Text("90-day retention")
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Behavioral Patterns") {
                    Text("On-device only")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Data Storage")
            } footer: {
                Text("All health and behavioral data is processed and stored exclusively on your device. The server stores only your account profile and trust state for cross-device sync.")
            }

            Section {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete All Local Data", systemImage: "trash")
                }
            } footer: {
                Text("This will remove all locally stored health data, patterns, and decision receipts. Your account and trust state will be preserved on the server.")
            }
        }
        .navigationTitle("Manage Data")
        .alert("Delete All Local Data?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task { await deleteLocalData() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone. All health metrics, behavioral patterns, and decision receipts stored on this device will be permanently deleted.")
        }
    }

    private func deleteLocalData() async {
        await CoreDataStack.shared.deleteAllData()
    }
}

// MARK: - Trust Phase Explainer

struct TrustPhaseExplainerView: View {
    var body: some View {
        List {
            ForEach(TrustPhase.allCases, id: \.self) { phase in
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: phase.iconName)
                                .foregroundColor(phaseColor(phase))
                            Text(phase.displayName)
                                .font(.headline)
                        }
                        Text(phase.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Divider()

                        Text("Capabilities:")
                            .font(.caption.bold())
                        ForEach(phase.capabilities, id: \.self) { cap in
                            Label(cap.displayName, systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("How Trust Works")
    }

    private func phaseColor(_ phase: TrustPhase) -> Color {
        switch phase {
        case .observer:       return .gray
        case .scheduler:      return .blue
        case .autoScheduler:  return .green
        case .transformer:    return .purple
        case .fullGhost:      return .orange
        }
    }
}

// MARK: - Sacred Time Reason Display

extension SacredTimeReason {
    var displayName: String {
        switch self {
        case .repeatedDeletions: return "Auto-detected"
        case .userSpecified:     return "Manually added"
        case .weekendMorning:    return "Weekend morning"
        case .lunchHour:         return "Lunch hour"
        case .personalEvent:     return "Personal event"
        }
    }
}
