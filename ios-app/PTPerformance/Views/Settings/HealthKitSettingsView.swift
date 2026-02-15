// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  HealthKitSettingsView.swift
//  PTPerformance
//
//  Build 362: Apple Health Integration Settings
//  ACP-827: Updated for bidirectional sync
//

import SwiftUI

/// Settings view for managing Apple Health integration
struct HealthKitSettingsView: View {
    @EnvironmentObject var healthKitService: HealthKitService

    var body: some View {
        List {
            // Connection Status Section
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
                             : "Connect to sync HRV, sleep, and heart rate")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, Spacing.xxs)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(healthKitService.isAuthorized ? "Connected. Bidirectional sync enabled" : "Not connected. Connect to sync HRV, sleep, and heart rate")

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
                Text("Connection Status")
            }

            // Today's Data Section
            if healthKitService.isAuthorized {
                Section {
                    // HRV
                    HStack {
                        Image(systemName: "waveform.path.ecg")
                            .foregroundColor(.purple)
                            .frame(width: 28)
                            .accessibilityHidden(true)
                        Text("HRV (SDNN)")
                        Spacer()
                        if let hrv = healthKitService.todayHRV {
                            Text("\(Int(hrv)) ms")
                                .foregroundColor(.secondary)
                        } else {
                            Text("No data")
                                .foregroundColor(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Heart Rate Variability: \(healthKitService.todayHRV.map { "\(Int($0)) milliseconds" } ?? "No data")")

                    // Resting Heart Rate
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(DesignTokens.statusError)
                            .frame(width: 28)
                            .accessibilityHidden(true)
                        Text("Resting HR")
                        Spacer()
                        if let hr = healthKitService.todayRestingHR {
                            Text("\(Int(hr)) bpm")
                                .foregroundColor(.secondary)
                        } else {
                            Text("No data")
                                .foregroundColor(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Resting Heart Rate: \(healthKitService.todayRestingHR.map { "\(Int($0)) beats per minute" } ?? "No data")")

                    // Sleep
                    HStack {
                        Image(systemName: "bed.double.fill")
                            .foregroundColor(.indigo)
                            .frame(width: 28)
                            .accessibilityHidden(true)
                        Text("Sleep")
                        Spacer()
                        if let sleep = healthKitService.todaySleep {
                            Text(String(format: "%.1f hrs", sleep.totalHours))
                                .foregroundColor(.secondary)
                        } else {
                            Text("No data")
                                .foregroundColor(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Sleep: \(healthKitService.todaySleep.map { String(format: "%.1f hours", $0.totalHours) } ?? "No data")")

                    // ACP-827: Exported Workouts
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(DesignTokens.statusSuccess)
                            .frame(width: 28)
                            .accessibilityHidden(true)
                        Text("Workouts Exported")
                        Spacer()
                        Text("\(healthKitService.exportedWorkoutsCount)")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Workouts Exported: \(healthKitService.exportedWorkoutsCount)")

                    // Last Sync
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(DesignTokens.statusInfo)
                            .frame(width: 28)
                            .accessibilityHidden(true)
                        Text("Last Synced")
                        Spacer()
                        if let lastSync = healthKitService.lastSyncDate {
                            Text(lastSync, style: .relative)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Never")
                                .foregroundColor(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Last Synced: \(healthKitService.lastSyncDate != nil ? "recently" : "Never")")

                    // Sync Button
                    Button {
                        Task {
                            _ = try? await healthKitService.syncTodayData()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Sync Now")
                        }
                    }
                    .accessibilityLabel("Sync Now")
                    .accessibilityHint("Synchronizes health data with Apple Health")
                } header: {
                    Text("Today's Health Data")
                }

                // ACP-827: Advanced Sync Settings
                Section {
                    NavigationLink {
                        HealthSyncSettingsView()
                            .environmentObject(healthKitService)
                    } label: {
                        HStack {
                            Image(systemName: "gearshape.2")
                                .foregroundColor(Color(.secondaryLabel))
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sync Settings")
                                Text("Configure what data syncs and when")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Advanced")
                }
            }

            // ACP-1052: Currently Shared Data summary
            if healthKitService.isAuthorized {
                Section {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.green)
                                .accessibilityHidden(true)
                            Text("Your data stays on-device unless you choose to sync.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        SharedDataRow(
                            icon: "waveform.path.ecg",
                            iconColor: .purple,
                            title: "Heart Rate Variability (HRV)",
                            purpose: "Recovery & readiness assessment",
                            isSharing: true
                        )

                        SharedDataRow(
                            icon: "bed.double.fill",
                            iconColor: .indigo,
                            title: "Sleep Analysis",
                            purpose: "Sleep quality for readiness check-in",
                            isSharing: true
                        )

                        SharedDataRow(
                            icon: "heart.fill",
                            iconColor: .red,
                            title: "Resting Heart Rate",
                            purpose: "Cardiovascular health tracking",
                            isSharing: true
                        )

                        SharedDataRow(
                            icon: "flame.fill",
                            iconColor: .orange,
                            title: "Active Energy Burned",
                            purpose: "Activity level monitoring",
                            isSharing: true
                        )

                        SharedDataRow(
                            icon: "figure.walk",
                            iconColor: .green,
                            title: "Steps & Exercise Time",
                            purpose: "Daily activity tracking",
                            isSharing: true
                        )

                        SharedDataRow(
                            icon: "lungs.fill",
                            iconColor: .cyan,
                            title: "Oxygen Saturation",
                            purpose: "Recovery monitoring",
                            isSharing: true
                        )

                        SharedDataRow(
                            icon: "figure.strengthtraining.traditional",
                            iconColor: .modusCyan,
                            title: "Workout Export (Write)",
                            purpose: "Completed sessions sent to Apple Health",
                            isSharing: true
                        )
                    }
                    .padding(.vertical, Spacing.xs)
                } header: {
                    Text("Currently Shared Data")
                } footer: {
                    Text("To change what Modus can access, go to Settings > Privacy & Security > Health > Modus on your device.")
                }
            }

            // ACP-827: Updated data sync section for bidirectional
            Section {
                // Import
                VStack(alignment: .leading, spacing: 8) {
                    Label("Import from Apple Health", systemImage: "arrow.down.circle")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    HStack(spacing: 8) {
                        DataTypeChip(icon: "waveform.path.ecg", text: "HRV")
                        DataTypeChip(icon: "heart.fill", text: "HR")
                        DataTypeChip(icon: "bed.double.fill", text: "Sleep")
                        DataTypeChip(icon: "flame.fill", text: "Energy")
                    }
                }
                .padding(.vertical, Spacing.xxs)

                // Export
                VStack(alignment: .leading, spacing: 8) {
                    Label("Export to Apple Health", systemImage: "arrow.up.circle")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    HStack(spacing: 8) {
                        DataTypeChip(icon: "figure.strengthtraining.traditional", text: "Workouts")
                    }
                }
                .padding(.vertical, Spacing.xxs)
            } header: {
                Text("Bidirectional Sync")
            } footer: {
                Text("Modus imports your health data to personalize recovery, and exports completed workouts to Apple Health.")
            }

            // How It's Used Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(
                        icon: "battery.100",
                        title: "Readiness Check-In",
                        description: "Auto-fill sleep and energy from Apple Watch"
                    )
                    FeatureRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Recovery Tracking",
                        description: "HRV trends help detect fatigue"
                    )
                    FeatureRow(
                        icon: "bed.double",
                        title: "Deload Recommendations",
                        description: "Smart rest suggestions based on your data"
                    )
                    // ACP-827: New workout export feature
                    FeatureRow(
                        icon: "heart.text.square",
                        title: "Workout Export",
                        description: "See your training in Apple Health Activity"
                    )
                }
                .padding(.vertical, Spacing.xxs)
            } header: {
                Text("How We Use Your Data")
            }
        }
        .navigationTitle("Apple Health")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if healthKitService.isAuthorized {
                _ = try? await healthKitService.syncTodayData()
            }
        }
    }
}

// MARK: - Data Type Chip

private struct DataTypeChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .accessibilityHidden(true)
            Text(text)
                .font(.caption)
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
        .accessibilityLabel(text)
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(DesignTokens.statusInfo)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(description)")
    }
}

// MARK: - Shared Data Row

private struct SharedDataRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let purpose: String
    let isSharing: Bool

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(purpose)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: isSharing ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundColor(isSharing ? DesignTokens.statusSuccess : DesignTokens.statusError)
                .font(.body)
                .accessibilityHidden(true)
        }
        .padding(.vertical, Spacing.xxs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(isSharing ? "Shared" : "Not shared"). \(purpose)")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HealthKitSettingsView()
            .environmentObject(HealthKitService.shared)
    }
}
