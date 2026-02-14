// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  HealthSyncSettingsView.swift
//  PTPerformance
//
//  ACP-827: Apple Health Deep Sync Settings
//  Allows users to toggle individual sync options
//

import SwiftUI

/// Settings view for configuring Apple Health sync options
struct HealthSyncSettingsView: View {
    @EnvironmentObject var healthKitService: HealthKitService
    @State private var config: HealthSyncConfig
    @State private var showResetConfirmation = false

    init() {
        _config = State(initialValue: HealthSyncConfig.load())
    }

    var body: some View {
        List {
            // Connection Status
            connectionStatusSection

            // Export Settings
            if healthKitService.isAuthorized {
                exportSettingsSection
                importSettingsSection
                syncScheduleSection
                syncStatusSection
            }

            // Reset Section
            if healthKitService.isAuthorized {
                resetSection
            }
        }
        .navigationTitle("Health Sync")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: config) { _, newValue in
            newValue.save()
            healthKitService.syncConfig = newValue
        }
        .alert("Reset Sync Settings", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                config.reset()
            }
        } message: {
            Text("This will restore all sync settings to their defaults.")
        }
    }

    // MARK: - Connection Status Section

    private var connectionStatusSection: some View {
        Section {
            HStack {
                Image(systemName: healthKitService.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(healthKitService.isAuthorized ? DesignTokens.statusSuccess : DesignTokens.statusError)
                    .font(.title2)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(healthKitService.isAuthorized ? "Connected" : "Not Connected")
                        .font(.headline)
                    Text(healthKitService.isAuthorized
                         ? "Bidirectional sync enabled"
                         : "Connect to sync with Apple Health")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, Spacing.xxs)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(healthKitService.isAuthorized ? "Connected. Bidirectional sync enabled" : "Not connected. Connect to sync with Apple Health")

            if !healthKitService.isAuthorized {
                Button {
                    Task {
                        _ = try? await healthKitService.requestAuthorization()
                        // Verify connection by actually querying data
                        _ = await healthKitService.verifyConnection()
                        // Try to sync data immediately
                        _ = try? await healthKitService.syncTodayData()
                    }
                } label: {
                    HStack {
                        Image(systemName: "heart.circle")
                        Text("Connect Apple Health")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignTokens.statusError)
                    .foregroundColor(DesignTokens.buttonTextOnAccent)
                    .cornerRadius(CornerRadius.sm)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Connect Apple Health")
                .accessibilityHint("Requests access to sync data with Apple Health")
            }
        } header: {
            Text("Connection")
        }
    }

    // MARK: - Export Settings Section

    private var exportSettingsSection: some View {
        Section {
            Toggle(isOn: $config.exportWorkouts) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Export Workouts")
                        Text("Send completed workouts to Apple Health")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } icon: {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(DesignTokens.statusSuccess)
                }
            }
            .accessibilityLabel("Export Workouts")
            .accessibilityValue(config.exportWorkouts ? "On" : "Off")
            .accessibilityHint("Toggle to send completed workouts to Apple Health")

            if config.exportWorkouts {
                Toggle(isOn: $config.exportOnCompletion) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto-Export")
                            Text("Export immediately after workout")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "bolt.circle.fill")
                            .foregroundColor(DesignTokens.statusWarning)
                    }
                }
                .accessibilityLabel("Auto-Export")
                .accessibilityValue(config.exportOnCompletion ? "On" : "Off")
                .accessibilityHint("Toggle to export immediately after completing a workout")
            }
        } header: {
            Text("Export to Apple Health")
        } footer: {
            Text("Workouts will appear in the Health app's Activity section.")
        }
    }

    // MARK: - Import Settings Section

    private var importSettingsSection: some View {
        Section {
            Toggle(isOn: $config.importSleep) {
                Label {
                    Text("Sleep Data")
                } icon: {
                    Image(systemName: "bed.double.fill")
                        .foregroundColor(.indigo)
                }
            }
            .accessibilityLabel("Sleep Data")
            .accessibilityValue(config.importSleep ? "On" : "Off")

            Toggle(isOn: $config.importHRV) {
                Label {
                    Text("Heart Rate Variability")
                } icon: {
                    Image(systemName: "waveform.path.ecg")
                        .foregroundColor(.purple)
                }
            }
            .accessibilityLabel("Heart Rate Variability")
            .accessibilityValue(config.importHRV ? "On" : "Off")

            Toggle(isOn: $config.importRestingHR) {
                Label {
                    Text("Resting Heart Rate")
                } icon: {
                    Image(systemName: "heart.fill")
                        .foregroundColor(DesignTokens.statusError)
                }
            }
            .accessibilityLabel("Resting Heart Rate")
            .accessibilityValue(config.importRestingHR ? "On" : "Off")

            Toggle(isOn: $config.importActiveEnergy) {
                Label {
                    Text("Active Energy")
                } icon: {
                    Image(systemName: "flame.fill")
                        .foregroundColor(DesignTokens.statusWarning)
                }
            }
            .accessibilityLabel("Active Energy")
            .accessibilityValue(config.importActiveEnergy ? "On" : "Off")

            Toggle(isOn: $config.importExerciseMinutes) {
                Label {
                    Text("Exercise Minutes")
                } icon: {
                    Image(systemName: "figure.run")
                        .foregroundColor(DesignTokens.statusSuccess)
                }
            }
            .accessibilityLabel("Exercise Minutes")
            .accessibilityValue(config.importExerciseMinutes ? "On" : "Off")

            Toggle(isOn: $config.importStepCount) {
                Label {
                    Text("Step Count")
                } icon: {
                    Image(systemName: "figure.walk")
                        .foregroundColor(DesignTokens.statusInfo)
                }
            }
            .accessibilityLabel("Step Count")
            .accessibilityValue(config.importStepCount ? "On" : "Off")
        } header: {
            Text("Import from Apple Health")
        } footer: {
            Text("This data is used for readiness check-ins and recovery recommendations.")
        }
    }

    // MARK: - Sync Schedule Section

    private var syncScheduleSection: some View {
        Section {
            Picker("Sync Frequency", selection: $config.syncFrequency) {
                ForEach(SyncFrequency.allCases, id: \.self) { frequency in
                    Text(frequency.displayName).tag(frequency)
                }
            }

            Toggle(isOn: $config.backgroundSyncEnabled) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Background Sync")
                        Text("Sync while app is closed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } icon: {
                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                        .foregroundColor(DesignTokens.statusInfo)
                }
            }
            .accessibilityLabel("Background Sync")
            .accessibilityValue(config.backgroundSyncEnabled ? "On" : "Off")
            .accessibilityHint("Toggle to sync health data while the app is closed")

            Toggle(isOn: $config.syncOnLaunch) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sync on Launch")
                        Text("Refresh data when opening app")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } icon: {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .foregroundColor(.teal)
                }
            }
            .accessibilityLabel("Sync on Launch")
            .accessibilityValue(config.syncOnLaunch ? "On" : "Off")
            .accessibilityHint("Toggle to refresh health data when opening the app")
        } header: {
            Text("Sync Schedule")
        } footer: {
            Text(config.syncFrequency.description)
        }
    }

    // MARK: - Sync Status Section

    private var syncStatusSection: some View {
        Section {
            // Last Import
            HStack {
                Image(systemName: "arrow.down.circle")
                    .foregroundColor(DesignTokens.statusInfo)
                    .frame(width: 28)
                Text("Last Import")
                Spacer()
                if let lastSync = healthKitService.lastSyncDate {
                    Text(lastSync, style: .relative)
                        .foregroundColor(.secondary)
                } else {
                    Text("Never")
                        .foregroundColor(.secondary)
                }
            }

            // Last Export
            HStack {
                Image(systemName: "arrow.up.circle")
                    .foregroundColor(DesignTokens.statusSuccess)
                    .frame(width: 28)
                Text("Last Export")
                Spacer()
                if let lastExport = healthKitService.lastExportDate {
                    Text(lastExport, style: .relative)
                        .foregroundColor(.secondary)
                } else {
                    Text("Never")
                        .foregroundColor(.secondary)
                }
            }

            // Exported Workouts Count
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(DesignTokens.statusWarning)
                    .frame(width: 28)
                Text("Workouts Exported")
                Spacer()
                Text("\(healthKitService.exportedWorkoutsCount)")
                    .foregroundColor(.secondary)
            }

            // Sync Now Button
            Button {
                Task {
                    _ = try? await healthKitService.syncTodayData()
                }
            } label: {
                HStack {
                    if healthKitService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .accessibilityHidden(true)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    Text("Sync Now")
                }
            }
            .disabled(healthKitService.isLoading)
            .accessibilityLabel(healthKitService.isLoading ? "Syncing health data" : "Sync Now")
            .accessibilityHint("Synchronizes health data with Apple Health")
        } header: {
            Text("Sync Status")
        }
    }

    // MARK: - Reset Section

    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    Text("Reset to Defaults")
                    Spacer()
                }
            }
            .accessibilityLabel("Reset to Defaults")
            .accessibilityHint("Restores all sync settings to their default values")
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HealthSyncSettingsView()
            .environmentObject(HealthKitService.shared)
    }
}
