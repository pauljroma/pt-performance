//
//  CoachingPreferencesView.swift
//  PTPerformance
//
//  Settings for coaching dashboard thresholds and notification preferences.
//  Allows therapists to customize when they receive alerts.
//

import SwiftUI

// MARK: - CoachingPreferencesView

struct CoachingPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CoachingPreferencesViewModel()

    var body: some View {
        NavigationStack {
            Form {
                // Alert Thresholds Section
                alertThresholdsSection

                // Notification Preferences Section
                notificationPreferencesSection

                // Alert Priority Section
                alertPrioritySection

                // Quiet Hours Section
                quietHoursSection

                // Reset Section
                resetSection
            }
            .navigationTitle("Coaching Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.savePreferences()
                        HapticFeedback.success()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Alert Thresholds Section

    private var alertThresholdsSection: some View {
        Section {
            // Pain threshold
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Label("Pain Alert Threshold", systemImage: "waveform.path.ecg")
                        .font(.subheadline)

                    Spacer()

                    Text("\(Int(viewModel.painThreshold))/10")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }

                Slider(
                    value: $viewModel.painThreshold,
                    in: 1...10,
                    step: 1
                )
                .tint(.red)

                Text("Alert when patient reports pain at or above this level")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, Spacing.xs)

            // Adherence threshold
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Label("Adherence Alert Threshold", systemImage: "chart.line.downtrend.xyaxis")
                        .font(.subheadline)

                    Spacer()

                    Text("\(Int(viewModel.adherenceThreshold))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }

                Slider(
                    value: $viewModel.adherenceThreshold,
                    in: 20...80,
                    step: 5
                )
                .tint(.orange)

                Text("Alert when adherence drops below this percentage")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, Spacing.xs)

            // Inactivity threshold
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Label("Inactivity Alert", systemImage: "calendar.badge.exclamationmark")
                        .font(.subheadline)

                    Spacer()

                    Text("\(viewModel.inactivityDays) days")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                }

                Stepper(
                    "",
                    value: $viewModel.inactivityDays,
                    in: 3...30
                )
                .labelsHidden()

                Text("Alert when patient has no activity for this many days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, Spacing.xs)
        } header: {
            Text("Alert Thresholds")
        } footer: {
            Text("Configure when exceptions should be generated for your patients.")
        }
    }

    // MARK: - Notification Preferences Section

    private var notificationPreferencesSection: some View {
        Section {
            Toggle(isOn: $viewModel.pushNotificationsEnabled) {
                Label("Push Notifications", systemImage: "bell.badge.fill")
            }

            Toggle(isOn: $viewModel.emailNotificationsEnabled) {
                Label("Email Notifications", systemImage: "envelope.fill")
            }

            Toggle(isOn: $viewModel.inAppBadgesEnabled) {
                Label("In-App Badges", systemImage: "app.badge.fill")
            }

            if viewModel.pushNotificationsEnabled {
                Picker(selection: $viewModel.notificationFrequency) {
                    ForEach(NotificationFrequency.allCases, id: \.self) { frequency in
                        Text(frequency.rawValue).tag(frequency)
                    }
                } label: {
                    Label("Notification Frequency", systemImage: "clock")
                }
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text("Choose how you want to be notified about patient exceptions.")
        }
    }

    // MARK: - Alert Priority Section

    private var alertPrioritySection: some View {
        Section {
            Toggle(isOn: $viewModel.criticalAlertsEnabled) {
                HStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                    Text("Critical Alerts")
                }
            }

            Toggle(isOn: $viewModel.highAlertsEnabled) {
                HStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 12, height: 12)
                    Text("High Priority Alerts")
                }
            }

            Toggle(isOn: $viewModel.mediumAlertsEnabled) {
                HStack {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 12, height: 12)
                    Text("Medium Priority Alerts")
                }
            }

            Toggle(isOn: $viewModel.lowAlertsEnabled) {
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                    Text("Low Priority Alerts")
                }
            }
        } header: {
            Text("Alert Priorities")
        } footer: {
            Text("Select which priority levels should generate notifications.")
        }
    }

    // MARK: - Quiet Hours Section

    private var quietHoursSection: some View {
        Section {
            Toggle(isOn: $viewModel.quietHoursEnabled) {
                Label("Enable Quiet Hours", systemImage: "moon.fill")
            }

            if viewModel.quietHoursEnabled {
                DatePicker(
                    "Start Time",
                    selection: $viewModel.quietHoursStart,
                    displayedComponents: .hourAndMinute
                )

                DatePicker(
                    "End Time",
                    selection: $viewModel.quietHoursEnd,
                    displayedComponents: .hourAndMinute
                )

                Toggle(isOn: $viewModel.allowCriticalDuringQuiet) {
                    Text("Allow Critical Alerts")
                }
            }
        } header: {
            Text("Quiet Hours")
        } footer: {
            Text("Suppress non-critical notifications during specified hours.")
        }
    }

    // MARK: - Reset Section

    private var resetSection: some View {
        Section {
            Button(action: {
                HapticFeedback.warning()
                viewModel.resetToDefaults()
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset to Defaults")
                }
                .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Notification Frequency

enum NotificationFrequency: String, CaseIterable {
    case immediate = "Immediate"
    case hourly = "Hourly Digest"
    case daily = "Daily Digest"
    case weekly = "Weekly Summary"
}

// MARK: - ViewModel

@MainActor
final class CoachingPreferencesViewModel: ObservableObject {
    // Alert Thresholds
    @Published var painThreshold: Double = 7.0
    @Published var adherenceThreshold: Double = 50.0
    @Published var inactivityDays: Int = 7

    // Notification Preferences
    @Published var pushNotificationsEnabled = true
    @Published var emailNotificationsEnabled = true
    @Published var inAppBadgesEnabled = true
    @Published var notificationFrequency: NotificationFrequency = .immediate

    // Alert Priorities
    @Published var criticalAlertsEnabled = true
    @Published var highAlertsEnabled = true
    @Published var mediumAlertsEnabled = true
    @Published var lowAlertsEnabled = false

    // Quiet Hours
    @Published var quietHoursEnabled = false
    @Published var quietHoursStart = Calendar.current.date(from: DateComponents(hour: 22)) ?? Date()
    @Published var quietHoursEnd = Calendar.current.date(from: DateComponents(hour: 7)) ?? Date()
    @Published var allowCriticalDuringQuiet = true

    private let userDefaults = UserDefaults.standard
    private let preferencesKey = "coaching_preferences"

    init() {
        loadPreferences()
    }

    func loadPreferences() {
        // In production, load from UserDefaults or remote storage
        if let data = userDefaults.data(forKey: preferencesKey),
           let preferences = try? JSONDecoder().decode(ViewCoachingPreferences.self, from: data) {
            applyPreferences(preferences)
        }
    }

    func savePreferences() {
        let preferences = ViewCoachingPreferences(
            painThreshold: painThreshold,
            adherenceThreshold: adherenceThreshold,
            inactivityDays: inactivityDays,
            pushNotificationsEnabled: pushNotificationsEnabled,
            emailNotificationsEnabled: emailNotificationsEnabled,
            inAppBadgesEnabled: inAppBadgesEnabled,
            notificationFrequency: notificationFrequency.rawValue,
            criticalAlertsEnabled: criticalAlertsEnabled,
            highAlertsEnabled: highAlertsEnabled,
            mediumAlertsEnabled: mediumAlertsEnabled,
            lowAlertsEnabled: lowAlertsEnabled,
            quietHoursEnabled: quietHoursEnabled,
            quietHoursStart: quietHoursStart,
            quietHoursEnd: quietHoursEnd,
            allowCriticalDuringQuiet: allowCriticalDuringQuiet
        )

        if let data = try? JSONEncoder().encode(preferences) {
            userDefaults.set(data, forKey: preferencesKey)
        }

        // Post notification for other parts of app to react
        NotificationCenter.default.post(name: .coachingPreferencesUpdated, object: nil)
    }

    func resetToDefaults() {
        painThreshold = 7.0
        adherenceThreshold = 50.0
        inactivityDays = 7
        pushNotificationsEnabled = true
        emailNotificationsEnabled = true
        inAppBadgesEnabled = true
        notificationFrequency = .immediate
        criticalAlertsEnabled = true
        highAlertsEnabled = true
        mediumAlertsEnabled = true
        lowAlertsEnabled = false
        quietHoursEnabled = false
        quietHoursStart = Calendar.current.date(from: DateComponents(hour: 22)) ?? Date()
        quietHoursEnd = Calendar.current.date(from: DateComponents(hour: 7)) ?? Date()
        allowCriticalDuringQuiet = true
    }

    private func applyPreferences(_ preferences: ViewCoachingPreferences) {
        painThreshold = preferences.painThreshold
        adherenceThreshold = preferences.adherenceThreshold
        inactivityDays = preferences.inactivityDays
        pushNotificationsEnabled = preferences.pushNotificationsEnabled
        emailNotificationsEnabled = preferences.emailNotificationsEnabled
        inAppBadgesEnabled = preferences.inAppBadgesEnabled
        notificationFrequency = NotificationFrequency(rawValue: preferences.notificationFrequency) ?? .immediate
        criticalAlertsEnabled = preferences.criticalAlertsEnabled
        highAlertsEnabled = preferences.highAlertsEnabled
        mediumAlertsEnabled = preferences.mediumAlertsEnabled
        lowAlertsEnabled = preferences.lowAlertsEnabled
        quietHoursEnabled = preferences.quietHoursEnabled
        quietHoursStart = preferences.quietHoursStart
        quietHoursEnd = preferences.quietHoursEnd
        allowCriticalDuringQuiet = preferences.allowCriticalDuringQuiet
    }
}

// MARK: - Preferences Model (View-specific)

struct ViewCoachingPreferences: Codable {
    var painThreshold: Double
    var adherenceThreshold: Double
    var inactivityDays: Int
    var pushNotificationsEnabled: Bool
    var emailNotificationsEnabled: Bool
    var inAppBadgesEnabled: Bool
    var notificationFrequency: String
    var criticalAlertsEnabled: Bool
    var highAlertsEnabled: Bool
    var mediumAlertsEnabled: Bool
    var lowAlertsEnabled: Bool
    var quietHoursEnabled: Bool
    var quietHoursStart: Date
    var quietHoursEnd: Date
    var allowCriticalDuringQuiet: Bool
}

// MARK: - Notification Name

extension Notification.Name {
    static let coachingPreferencesUpdated = Notification.Name("coachingPreferencesUpdated")
}

// MARK: - Preview

#if DEBUG
struct CoachingPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        CoachingPreferencesView()
    }
}
#endif
