// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  NotificationSettingsView.swift
//  PTPerformance
//
//  ACP-841: Smart Notification Timing Feature
//  Settings UI for managing workout and prescription notification preferences
//

import SwiftUI
import UserNotifications

/// Settings view for managing smart workout and prescription notifications.
///
/// Allows users to:
/// - Enable/disable smart timing
/// - Set fallback reminder time
/// - Configure reminder lead time
/// - View learned workout patterns
/// - Configure prescription notification preferences
struct NotificationSettingsView: View {

    private static let timeWithSecondsFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabase = PTSupabaseClient.shared

    // MARK: - State

    @State private var settings: NotificationSettings?
    @State private var patterns: [TrainingTimePattern] = []
    @State private var permissionStatus: UNAuthorizationStatus = .notDetermined
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    // Editable settings
    @State private var smartTimingEnabled = true
    @State private var fallbackTime = Date()
    @State private var reminderMinutesBefore = 30
    @State private var streakAlertsEnabled = true
    @State private var weeklySummaryEnabled = true

    // Prescription notification settings
    @State private var prescriptionPreferences = PrescriptionNotificationPreferences.defaults
    @State private var showPrescriptionSection = true

    // MARK: - Computed Properties

    private var patientId: UUID? {
        guard let idString = supabase.userId else { return nil }
        return UUID(uuidString: idString)
    }

    private var hasPermission: Bool {
        permissionStatus == .authorized
    }

    private var reminderLeadTimeOptions: [Int] {
        [5, 10, 15, 30, 45, 60, 90, 120]
    }

    // MARK: - Body

    var body: some View {
        List {
            // Permission Section
            permissionSection

            if hasPermission {
                // Smart Timing Section
                smartTimingSection

                // Reminder Time Section
                reminderTimeSection

                // Prescription Notifications Section
                prescriptionNotificationsSection

                // Patterns Section
                patternsSection

                // Other Notifications Section
                otherNotificationsSection
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadData()
        }
        .onChange(of: smartTimingEnabled) { _, _ in
            HapticFeedback.toggle()
            saveSettings()
        }
        .onChange(of: streakAlertsEnabled) { _, _ in
            HapticFeedback.toggle()
            saveSettings()
        }
        .onChange(of: weeklySummaryEnabled) { _, _ in
            HapticFeedback.toggle()
            saveSettings()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .overlay {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground).opacity(0.8))
            }
        }
    }

    // MARK: - Permission Section

    private var permissionSection: some View {
        Section {
            HStack {
                Image(systemName: hasPermission ? "bell.badge.fill" : "bell.slash.fill")
                    .foregroundColor(hasPermission ? DesignTokens.statusSuccess : DesignTokens.statusError)
                    .font(.title2)
                    .frame(width: 32)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(hasPermission ? "Notifications Enabled" : "Notifications Disabled")
                        .font(.headline)
                    Text(hasPermission
                         ? "You'll receive workout and prescription reminders"
                         : "Enable notifications to get reminders")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if !hasPermission {
                    Button("Enable") {
                        HapticFeedback.medium()
                        Task {
                            await requestPermission()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .accessibilityLabel("Enable Notifications")
                    .accessibilityHint("Requests permission to send notifications")
                }
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(hasPermission ? "Notifications enabled. You'll receive workout and prescription reminders" : "Notifications disabled. Enable notifications to get reminders")
        } header: {
            Text("Permission")
        } footer: {
            if !hasPermission {
                Text("Workout reminders and prescription alerts help you stay on track with your training.")
            }
        }
    }

    // MARK: - Smart Timing Section

    private var smartTimingSection: some View {
        Section {
            Toggle(isOn: $smartTimingEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Smart Timing")
                        .font(.body)
                    Text("Learn your workout schedule automatically")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .blue))
            .accessibilityLabel("Smart Timing")
            .accessibilityValue(smartTimingEnabled ? "On" : "Off")
            .accessibilityHint("Toggle to automatically learn your workout schedule")

            if smartTimingEnabled {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.purple)
                        .frame(width: 28)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("How It Works")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("We analyze when you usually train and send reminders at the optimal time for each day.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("How It Works: We analyze when you usually train and send reminders at the optimal time for each day")
            }
        } header: {
            Text("Smart Timing")
        } footer: {
            if smartTimingEnabled {
                Text("The system learns your patterns over time. More workouts = better predictions.")
            }
        }
    }

    // MARK: - Reminder Time Section

    private var reminderTimeSection: some View {
        Section {
            // Fallback time picker
            DatePicker(
                "Default Reminder Time",
                selection: $fallbackTime,
                displayedComponents: .hourAndMinute
            )
            .onChange(of: fallbackTime) { _, _ in
                saveSettings()
            }

            // Lead time picker
            Picker("Remind Me", selection: $reminderMinutesBefore) {
                ForEach(reminderLeadTimeOptions, id: \.self) { minutes in
                    Text(formatMinutes(minutes)).tag(minutes)
                }
            }
            .onChange(of: reminderMinutesBefore) { _, _ in
                saveSettings()
            }
        } header: {
            Text("Reminder Settings")
        } footer: {
            if smartTimingEnabled {
                Text("This time is used when no pattern is detected for a day.")
            } else {
                Text("Reminders will be sent at this time every day.")
            }
        }
    }

    // MARK: - Prescription Notifications Section

    private var prescriptionNotificationsSection: some View {
        Section {
            // New prescription assigned
            Toggle(isOn: $prescriptionPreferences.newPrescriptionEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("New Prescription Alerts")
                        .font(.body)
                    Text("Get notified when a new prescription is assigned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .onChange(of: prescriptionPreferences.newPrescriptionEnabled) { _, _ in
                HapticFeedback.toggle()
                savePrescriptionPreferences()
            }
            .accessibilityLabel("New Prescription Alerts")
            .accessibilityValue(prescriptionPreferences.newPrescriptionEnabled ? "On" : "Off")

            // Deadline reminders group
            DisclosureGroup {
                Toggle("24 Hours Before", isOn: $prescriptionPreferences.deadline24hEnabled)
                    .onChange(of: prescriptionPreferences.deadline24hEnabled) { _, _ in
                        HapticFeedback.toggle()
                        savePrescriptionPreferences()
                    }

                Toggle("6 Hours Before", isOn: $prescriptionPreferences.deadline6hEnabled)
                    .onChange(of: prescriptionPreferences.deadline6hEnabled) { _, _ in
                        HapticFeedback.toggle()
                        savePrescriptionPreferences()
                    }

                Toggle("1 Hour Before", isOn: $prescriptionPreferences.deadline1hEnabled)
                    .onChange(of: prescriptionPreferences.deadline1hEnabled) { _, _ in
                        HapticFeedback.toggle()
                        savePrescriptionPreferences()
                    }
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Deadline Reminders")
                        .font(.body)
                    Text("Get reminded before prescriptions are due")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .accessibilityLabel("Deadline Reminders")

            // Overdue alerts
            Toggle(isOn: $prescriptionPreferences.overdueEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overdue Alerts")
                        .font(.body)
                    Text("Get notified when a prescription becomes overdue")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .onChange(of: prescriptionPreferences.overdueEnabled) { _, _ in
                HapticFeedback.toggle()
                savePrescriptionPreferences()
            }
            .accessibilityLabel("Overdue Alerts")
            .accessibilityValue(prescriptionPreferences.overdueEnabled ? "On" : "Off")
        } header: {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(DesignTokens.statusInfo)
                Text("Prescription Notifications")
            }
        } footer: {
            Text("Stay on top of your therapist-assigned workouts with timely reminders.")
        }
    }

    // MARK: - Patterns Section

    private var patternsSection: some View {
        Section {
            if patterns.isEmpty {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.secondary)
                        .frame(width: 28)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No Patterns Yet")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Complete more workouts to see your training patterns")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("No patterns yet. Complete more workouts to see your training patterns")
            } else {
                ForEach(patterns) { pattern in
                    patternRow(pattern)
                }
            }

            // Refresh button
            Button {
                HapticFeedback.medium()
                Task {
                    await refreshPatterns()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Refresh Patterns")
                }
            }
            .accessibilityLabel("Refresh Patterns")
            .accessibilityHint("Analyzes your workout history to detect training patterns")
        } header: {
            Text("Your Training Patterns")
        } footer: {
            if !patterns.isEmpty {
                Text("Patterns are based on the last 90 days of workouts.")
            }
        }
    }

    // MARK: - Pattern Row

    private func patternRow(_ pattern: TrainingTimePattern) -> some View {
        HStack {
            // Day indicator
            Text(pattern.shortDayName)
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 36, height: 36)
                .background(confidenceColor(pattern.confidenceScore).opacity(0.15))
                .foregroundColor(confidenceColor(pattern.confidenceScore))
                .cornerRadius(CornerRadius.sm)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(pattern.dayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    if let time = pattern.formattedTime {
                        Text(time)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    Text("\(pattern.workoutCount) workout\(pattern.workoutCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(pattern.confidenceLevel)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(confidenceColor(pattern.confidenceScore).opacity(0.1))
                        .foregroundColor(confidenceColor(pattern.confidenceScore))
                        .cornerRadius(CornerRadius.xs)
                }
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Other Notifications Section

    private var otherNotificationsSection: some View {
        Section {
            Toggle(isOn: $streakAlertsEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Streak Alerts")
                        .font(.body)
                    Text("Get notified about workout milestones")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .accessibilityLabel("Streak Alerts")
            .accessibilityValue(streakAlertsEnabled ? "On" : "Off")
            .accessibilityHint("Toggle to get notified about workout milestones")

            Toggle(isOn: $weeklySummaryEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Summary")
                        .font(.body)
                    Text("Receive a weekly progress report")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .accessibilityLabel("Weekly Summary")
            .accessibilityValue(weeklySummaryEnabled ? "On" : "Off")
            .accessibilityHint("Toggle to receive a weekly progress report")
        } header: {
            Text("Other Notifications")
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        guard let patientId = patientId else {
            isLoading = false
            return
        }

        // Check permission status
        let status = await SmartNotificationService.shared.checkPermissionStatus()
        await MainActor.run {
            permissionStatus = status
        }

        do {
            // Load settings
            let loadedSettings = try await SmartNotificationService.shared.fetchSettings(for: patientId)
            await MainActor.run {
                settings = loadedSettings
                smartTimingEnabled = loadedSettings.smartTimingEnabled
                fallbackTime = loadedSettings.fallbackReminderTime
                reminderMinutesBefore = loadedSettings.reminderMinutesBefore
                streakAlertsEnabled = loadedSettings.streakAlertsEnabled
                weeklySummaryEnabled = loadedSettings.weeklySummaryEnabled
            }

            // Load patterns
            let loadedPatterns = try await SmartNotificationService.shared.fetchPatterns(for: patientId)
            await MainActor.run {
                patterns = loadedPatterns
            }

            // Load prescription preferences
            let loadedPrescriptionPrefs = try await SmartNotificationService.shared.fetchPrescriptionPreferences(for: patientId)
            await MainActor.run {
                prescriptionPreferences = loadedPrescriptionPrefs
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }

        await MainActor.run {
            isLoading = false
        }
    }

    // MARK: - Actions

    private func requestPermission() async {
        do {
            _ = try await SmartNotificationService.shared.requestPermission()
            let status = await SmartNotificationService.shared.checkPermissionStatus()
            await MainActor.run {
                permissionStatus = status
            }

            // Also register for push notifications
            if status == .authorized {
                try? await PushNotificationService.shared.registerForRemoteNotifications()
            }
        } catch {
            await MainActor.run {
                errorMessage = "Please enable notifications in Settings."
                showError = true
            }
        }
    }

    private func refreshPatterns() async {
        guard let patientId = patientId else { return }

        do {
            // Trigger pattern analysis
            try await SmartNotificationService.shared.analyzePatterns(for: patientId)

            // Reload patterns
            let loadedPatterns = try await SmartNotificationService.shared.fetchPatterns(for: patientId)
            await MainActor.run {
                patterns = loadedPatterns
            }
        } catch {
            await MainActor.run {
                errorMessage = "Couldn't refresh patterns. Please try again."
                showError = true
            }
        }
    }

    private func saveSettings() {
        guard let patientId = patientId else { return }
        guard !isSaving else { return }

        isSaving = true

        let update = NotificationSettingsUpdate(
            smartTimingEnabled: smartTimingEnabled,
            fallbackReminderTime: Self.timeWithSecondsFormatter.string(from: fallbackTime),
            reminderMinutesBefore: reminderMinutesBefore,
            streakAlertsEnabled: streakAlertsEnabled,
            weeklySummaryEnabled: weeklySummaryEnabled
        )

        Task {
            do {
                try await SmartNotificationService.shared.updateSettings(for: patientId, settings: update)
            } catch {
                await MainActor.run {
                    errorMessage = "Couldn't save settings. Please try again."
                    showError = true
                }
            }

            await MainActor.run {
                isSaving = false
            }
        }
    }

    private func savePrescriptionPreferences() {
        guard let patientId = patientId else { return }
        guard !isSaving else { return }

        isSaving = true

        Task {
            do {
                try await SmartNotificationService.shared.updatePrescriptionPreferences(
                    for: patientId,
                    preferences: prescriptionPreferences
                )
            } catch {
                await MainActor.run {
                    errorMessage = "Couldn't save prescription notification settings. Please try again."
                    showError = true
                }
            }

            await MainActor.run {
                isSaving = false
            }
        }
    }

    // MARK: - Helpers

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min before"
        } else {
            let hours = minutes / 60
            let remaining = minutes % 60
            if remaining == 0 {
                return "\(hours) hour\(hours == 1 ? "" : "s") before"
            } else {
                return "\(hours)h \(remaining)m before"
            }
        }
    }

    private func confidenceColor(_ confidence: Double?) -> Color {
        guard let confidence = confidence else { return Color(.secondaryLabel) }
        switch confidence {
        case 0..<0.3: return DesignTokens.statusWarning
        case 0.3..<0.6: return DesignTokens.statusWarning.opacity(0.8)
        case 0.6..<0.8: return DesignTokens.statusSuccess
        default: return DesignTokens.statusInfo
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
