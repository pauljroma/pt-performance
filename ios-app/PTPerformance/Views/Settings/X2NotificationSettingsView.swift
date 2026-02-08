//
//  X2NotificationSettingsView.swift
//  PTPerformance
//
//  X2Index Phase 2: Push Notification Settings View
//  Settings UI for managing athlete reminders and PT alerts
//

import SwiftUI
import UserNotifications

/// Settings view for managing X2Index push notifications
///
/// Allows users to:
/// - Enable/disable master notification toggle
/// - Set check-in reminder time
/// - Configure task reminders
/// - Toggle PT alerts (for therapists)
/// - Send test notification
struct X2NotificationSettingsView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @StateObject private var viewModel = NotificationSettingsViewModel()

    // MARK: - Body

    var body: some View {
        List {
            // Permission Section
            permissionSection

            if viewModel.isEnabled {
                // Check-In Reminders Section
                checkInSection

                // Task Reminders Section
                taskRemindersSection

                // Notification Types Section
                notificationTypesSection

                // PT Alerts Section (Therapists Only)
                if viewModel.showPTAlertToggle {
                    ptAlertsSection
                }

                // Test Section
                testSection
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadSettings()
        }
        .onChange(of: viewModel.checkInReminderTime) { _, _ in
            Task { await viewModel.saveSettings() }
        }
        .onChange(of: viewModel.taskRemindersEnabled) { _, _ in
            Task { await viewModel.saveSettings() }
        }
        .onChange(of: viewModel.ptAlertsEnabled) { _, _ in
            Task { await viewModel.saveSettings() }
        }
        .onChange(of: viewModel.streakMilestonesEnabled) { _, _ in
            Task { await viewModel.saveSettings() }
        }
        .onChange(of: viewModel.briefNotificationsEnabled) { _, _ in
            Task { await viewModel.saveSettings() }
        }
        .alert(
            viewModel.error?.errorDescription ?? "Error",
            isPresented: $viewModel.showError,
            presenting: viewModel.error
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { error in
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
            }
        }
        .overlay {
            if viewModel.isLoading {
                loadingOverlay
            }
        }
    }

    // MARK: - Permission Section

    private var permissionSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: permissionIcon)
                    .font(.title2)
                    .foregroundColor(permissionColor)
                    .frame(width: 32)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(permissionTitle)
                        .font(.headline)
                    Text(permissionSubtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if viewModel.authorizationStatus == .denied {
                    Button("Settings") {
                        viewModel.openSystemSettings()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                } else if viewModel.authorizationStatus == .notDetermined {
                    Button("Enable") {
                        Task {
                            await viewModel.requestPermissionIfNeeded()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Permission")
        } footer: {
            if viewModel.authorizationStatus == .denied {
                Text("Notifications are disabled in system settings. Tap Settings to enable them.")
            }
        }
    }

    private var permissionIcon: String {
        switch viewModel.authorizationStatus {
        case .authorized, .provisional:
            return "bell.badge.fill"
        case .denied:
            return "bell.slash.fill"
        case .notDetermined, .ephemeral:
            return "bell.fill"
        @unknown default:
            return "bell.fill"
        }
    }

    private var permissionColor: Color {
        switch viewModel.authorizationStatus {
        case .authorized, .provisional:
            return .green
        case .denied:
            return .red
        case .notDetermined, .ephemeral:
            return .orange
        @unknown default:
            return .gray
        }
    }

    private var permissionTitle: String {
        switch viewModel.authorizationStatus {
        case .authorized, .provisional:
            return "Notifications Enabled"
        case .denied:
            return "Notifications Disabled"
        case .notDetermined:
            return "Enable Notifications"
        case .ephemeral:
            return "Temporary Access"
        @unknown default:
            return "Unknown Status"
        }
    }

    private var permissionSubtitle: String {
        switch viewModel.authorizationStatus {
        case .authorized, .provisional:
            return "You'll receive reminders and alerts"
        case .denied:
            return "Open Settings to enable notifications"
        case .notDetermined:
            return "Get reminders for check-ins and tasks"
        case .ephemeral:
            return "Limited notification access"
        @unknown default:
            return "Please enable notifications"
        }
    }

    // MARK: - Check-In Section

    private var checkInSection: some View {
        Section {
            DatePicker(
                "Daily Check-In Time",
                selection: $viewModel.checkInReminderTime,
                displayedComponents: .hourAndMinute
            )
            .accessibilityLabel("Daily check-in reminder time")

            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
                    .font(.caption)
                Text("We'll remind you to complete your daily check-in at this time.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 2)
        } header: {
            HStack {
                Image(systemName: "checkmark.message.fill")
                    .foregroundColor(.blue)
                Text("Daily Check-In")
            }
        }
    }

    // MARK: - Task Reminders Section

    private var taskRemindersSection: some View {
        Section {
            Toggle(isOn: $viewModel.taskRemindersEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Task Reminders")
                        .font(.body)
                    Text("Get notified before tasks are due")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .blue))
        } header: {
            HStack {
                Image(systemName: "checklist")
                    .foregroundColor(.orange)
                Text("Task Notifications")
            }
        } footer: {
            Text("Reminders are sent based on task schedule and your preferred timing.")
        }
    }

    // MARK: - Notification Types Section

    private var notificationTypesSection: some View {
        Section {
            Toggle(isOn: $viewModel.streakMilestonesEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .frame(width: 20)
                        Text("Streak Milestones")
                    }
                    Text("Celebrate consistency achievements")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 28)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .blue))

            Toggle(isOn: $viewModel.briefNotificationsEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.purple)
                            .frame(width: 20)
                        Text("PT Briefs")
                    }
                    Text("New briefs from your physical therapist")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 28)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .blue))
        } header: {
            Text("Notification Types")
        }
    }

    // MARK: - PT Alerts Section

    private var ptAlertsSection: some View {
        Section {
            Toggle(isOn: $viewModel.ptAlertsEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Safety Alerts")
                        .font(.body)
                    Text("Urgent notifications about patient safety incidents")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .red))
        } header: {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Therapist Alerts")
            }
        } footer: {
            Text("Critical alerts for patient safety incidents require immediate attention.")
        }
    }

    // MARK: - Test Section

    private var testSection: some View {
        Section {
            Button {
                Task {
                    await viewModel.sendTestNotification()
                }
            } label: {
                HStack {
                    Image(systemName: "bell.and.waveform")
                        .foregroundColor(.blue)
                    Text("Send Test Notification")
                    Spacer()
                    if viewModel.testNotificationSent {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            .disabled(viewModel.isSaving)
        } header: {
            Text("Test")
        } footer: {
            Text("Send a test notification to verify everything is working correctly.")
        }
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ProgressView()
            .scaleEffect(1.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground).opacity(0.8))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        X2NotificationSettingsView()
    }
}
