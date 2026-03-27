//
//  HealthSyncStatusView.swift
//  PTPerformance
//
//  ACP-827: Apple Health Sync Status Display
//  Shows last sync time, data synced, and sync controls
//

import SwiftUI
import HealthKit

/// Compact status view for health sync state with enhanced reliability indicators
struct HealthSyncStatusView: View {
    @EnvironmentObject var healthKitService: HealthKitService
    @StateObject private var syncManager = HealthSyncManager.shared
    @StateObject private var healthKitSyncService = HealthKitSyncService.shared
    @State private var showDetailedStatus = false
    @State private var isRefreshing = false

    var body: some View {
        VStack(spacing: 0) {
            // Main status row
            Button {
                HapticFeedback.light()
                showDetailedStatus.toggle()
            } label: {
                HStack(spacing: 12) {
                    // Status icon with enhanced states
                    statusIcon

                    // Status text with sync quality indicator
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(statusTitle)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)

                            // Sync quality indicator
                            if healthKitService.isAuthorized {
                                syncQualityBadge
                            }
                        }
                        Text(statusSubtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Error indicator
                    if syncManager.syncError != nil || healthKitSyncService.error != nil {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(DesignTokens.statusWarning)
                            .accessibilityLabel("Sync error")
                    }

                    // Chevron
                    Image(systemName: showDetailedStatus ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Health sync status")
            .accessibilityHint("Tap to view details")

            // Expanded details
            if showDetailedStatus {
                Divider()
                detailedStatusView
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .shadow(color: Shadow.subtle.color(for: .light), radius: Shadow.subtle.radius, x: Shadow.subtle.x, y: Shadow.subtle.y)
    }

    // MARK: - Status Components

    private var statusIcon: some View {
        Group {
            if healthKitService.isLoading || isRefreshing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .modusCyan))
                    .accessibilityLabel("Syncing")
            } else if syncManager.syncError != nil || healthKitSyncService.error != nil {
                Image(systemName: "heart.circle.badge.exclamationmark")
                    .font(.title2)
                    .foregroundColor(DesignTokens.statusError)
                    .accessibilityLabel("Sync error")
            } else if healthKitService.isAuthorized {
                Image(systemName: "heart.circle.fill")
                    .font(.title2)
                    .foregroundColor(.modusTealAccent)
                    .accessibilityLabel("Connected to Apple Health")
            } else {
                Image(systemName: "heart.slash.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .accessibilityLabel("Not connected")
            }
        }
        .frame(width: 32, height: 32)
    }

    private var statusTitle: String {
        if healthKitService.isLoading || isRefreshing {
            return "Syncing..."
        } else if syncManager.syncError != nil || healthKitSyncService.error != nil {
            return "Sync Error"
        } else if !healthKitService.isAuthorized {
            return "Not Connected"
        } else if healthKitService.hasHealthData {
            return "Synced"
        } else {
            return "No Data Yet"
        }
    }

    private var statusSubtitle: String {
        if healthKitService.isLoading || isRefreshing {
            return "Updating health data"
        } else if let error = syncManager.syncError ?? healthKitSyncService.error {
            return error
        } else if !healthKitService.isAuthorized {
            return "Tap to connect Apple Health"
        } else if let lastSync = healthKitService.lastSyncDate {
            return "Last synced \(RelativeDateTimeFormatter().localizedString(for: lastSync, relativeTo: Date()))"
        } else {
            return "Tap to sync now"
        }
    }

    /// Sync quality badge showing data completeness
    private var syncQualityBadge: some View {
        Group {
            if let quality = syncDataQuality {
                HStack(spacing: 2) {
                    Image(systemName: quality.icon)
                        .font(.system(size: 8))
                    Text(quality.label)
                        .font(.system(size: 9, weight: .medium))
                }
                .foregroundColor(quality.color)
                .padding(.horizontal, Spacing.xxs)
                .padding(.vertical, 2)
                .background(quality.color.opacity(0.15))
                .cornerRadius(CornerRadius.xs)
                .accessibilityLabel("Data quality: \(quality.label)")
            }
        }
    }

    private var syncDataQuality: (icon: String, label: String, color: Color)? {
        guard healthKitService.isAuthorized else { return nil }

        let dataPoints = [
            healthKitService.todayHRV != nil,
            healthKitService.todaySleep != nil,
            healthKitService.todayRestingHR != nil
        ].filter { $0 }.count

        switch dataPoints {
        case 3:
            return ("checkmark.circle.fill", "Complete", DesignTokens.statusSuccess)
        case 2:
            return ("checkmark.circle", "Partial", DesignTokens.statusWarning)
        case 1:
            return ("exclamationmark.circle", "Limited", DesignTokens.statusWarning)
        default:
            return ("xmark.circle", "No Data", DesignTokens.statusError)
        }
    }

    // MARK: - Detailed Status View

    private var detailedStatusView: some View {
        VStack(spacing: Spacing.md) {
            // Authorization revocation alert
            if healthKitService.authorizationWasRevoked {
                authorizationRevokedBanner
            }

            // Error message banner
            if let error = syncManager.syncError ?? healthKitSyncService.error {
                errorBanner(error)
            }

            // Data summary
            if healthKitService.isAuthorized {
                dataSummaryGrid
            }

            // Sync status details
            if healthKitService.isAuthorized {
                syncStatusDetails
            }

            // Action buttons
            actionButtons
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }

    private var authorizationRevokedBanner: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.shield.fill")
                .foregroundColor(DesignTokens.statusError)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Authorization Revoked")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("Apple Health access was removed. Re-enable in Settings > Privacy > Health.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            Spacer()
        }
        .padding(Spacing.sm)
        .background(DesignTokens.statusError.opacity(0.15))
        .cornerRadius(CornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .stroke(DesignTokens.statusError.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Warning: Authorization revoked")
    }

    private func errorBanner(_ error: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(DesignTokens.statusError)
                .accessibilityHidden(true)

            Text(error)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(2)

            Spacer()
        }
        .padding(Spacing.sm)
        .background(DesignTokens.statusError.opacity(0.1))
        .cornerRadius(CornerRadius.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(error)")
    }

    private var syncStatusDetails: some View {
        VStack(spacing: Spacing.xs) {
            syncDetailRow(
                icon: "arrow.triangle.2.circlepath",
                label: "Last Import",
                value: healthKitService.lastSyncDate.map { formatRelativeDate($0) } ?? "Never",
                color: .modusCyan
            )

            if let lastBackgroundSync = syncManager.lastBackgroundSync {
                syncDetailRow(
                    icon: "clock.arrow.circlepath",
                    label: "Background Sync",
                    value: formatRelativeDate(lastBackgroundSync),
                    color: .modusDeepTeal
                )
            }

            if !syncManager.pendingExports.isEmpty {
                syncDetailRow(
                    icon: "arrow.up.circle",
                    label: "Pending Exports",
                    value: "\(syncManager.pendingExports.count)",
                    color: DesignTokens.statusWarning
                )
            }
        }
        .padding(Spacing.sm)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.sm)
    }

    private func syncDetailRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 20)
                .accessibilityHidden(true)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private var dataSummaryGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            // HRV
            DataTile(
                icon: "waveform.path.ecg",
                iconColor: .purple,
                title: "HRV",
                value: healthKitService.todayHRV.map { "\(Int($0)) ms" } ?? "--"
            )

            // Sleep
            DataTile(
                icon: "bed.double.fill",
                iconColor: .indigo,
                title: "Sleep",
                value: healthKitService.todaySleep.map { String(format: "%.1f hrs", $0.totalHours) } ?? "--"
            )

            // Resting HR
            DataTile(
                icon: "heart.fill",
                iconColor: .red,
                title: "RHR",
                value: healthKitService.todayRestingHR.map { "\(Int($0)) bpm" } ?? "--"
            )

            // Exported Workouts
            DataTile(
                icon: "arrow.up.circle.fill",
                iconColor: .green,
                title: "Exported",
                value: "\(healthKitService.exportedWorkoutsCount)"
            )

            // Last Import
            DataTile(
                icon: "arrow.down.circle.fill",
                iconColor: .modusCyan,
                title: "Import",
                value: healthKitService.lastSyncDate.map { shortTimeAgo($0) } ?? "Never"
            )

            // Last Export
            DataTile(
                icon: "square.and.arrow.up.fill",
                iconColor: .orange,
                title: "Export",
                value: healthKitService.lastExportDate.map { shortTimeAgo($0) } ?? "Never"
            )
        }
    }

    private var actionButtons: some View {
        HStack(spacing: Spacing.sm) {
            if healthKitService.isAuthorized {
                // Manual sync button with pull-to-refresh style
                Button {
                    HapticFeedback.medium()
                    Task {
                        isRefreshing = true
                        defer { isRefreshing = false }
                        await syncManager.performSync()
                        HapticFeedback.success()
                    }
                } label: {
                    HStack(spacing: 6) {
                        if isRefreshing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        Text(isRefreshing ? "Syncing..." : "Sync Now")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.modusCyan)
                    .foregroundColor(.white)
                    .cornerRadius(CornerRadius.sm)
                }
                .disabled(healthKitService.isLoading || isRefreshing)
                .opacity((healthKitService.isLoading || isRefreshing) ? 0.6 : 1.0)
                .accessibilityLabel(isRefreshing ? "Syncing health data" : "Sync health data now")
            } else {
                // v1.0: Connect button removed — requestAuthorization not showing
                // dialog on iOS 26.4. Direct user to Settings instead.
                Text("Enable Apple Health access in Settings > Health > Korza Training")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Helpers

    private func shortTimeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "Now"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h"
        } else {
            return "\(Int(interval / 86400))d"
        }
    }
}

// MARK: - Data Tile Component

private struct DataTile: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xs)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.sm)
    }
}

// MARK: - Inline Sync Status Banner

/// Smaller inline banner for showing sync status in other views
struct HealthSyncBanner: View {
    @EnvironmentObject var healthKitService: HealthKitService
    let showAction: Bool

    init(showAction: Bool = true) {
        self.showAction = showAction
    }

    var body: some View {
        HStack(spacing: 8) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            if showAction && healthKitService.isAuthorized && !healthKitService.isLoading {
                Button {
                    Task {
                        _ = try? await healthKitService.syncTodayData()
                    }
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption)
                        .foregroundColor(.modusCyan)
                }
            }

            if healthKitService.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.7)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.sm)
    }

    private var statusColor: Color {
        if healthKitService.isLoading {
            return .orange
        } else if !healthKitService.isAuthorized {
            return .gray
        } else if healthKitService.hasHealthData {
            return .green
        } else {
            return .yellow
        }
    }

    private var statusText: String {
        if healthKitService.isLoading {
            return "Syncing health data..."
        } else if !healthKitService.isAuthorized {
            return "Apple Health not connected"
        } else if let lastSync = healthKitService.lastSyncDate {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return "Synced \(formatter.localizedString(for: lastSync, relativeTo: Date()))"
        } else {
            return "No health data synced"
        }
    }
}

// MARK: - Preview

#Preview("Full Status View") {
    VStack {
        HealthSyncStatusView()
            .padding()
        Spacer()
    }
    .background(Color(.secondarySystemBackground))
    .environmentObject(HealthKitService.shared)
}

#Preview("Banner") {
    VStack {
        HealthSyncBanner()
            .padding()
        Spacer()
    }
    .environmentObject(HealthKitService.shared)
}
