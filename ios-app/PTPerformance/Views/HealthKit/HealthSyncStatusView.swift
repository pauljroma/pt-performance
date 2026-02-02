//
//  HealthSyncStatusView.swift
//  PTPerformance
//
//  ACP-827: Apple Health Sync Status Display
//  Shows last sync time, data synced, and sync controls
//

import SwiftUI
import HealthKit

/// Compact status view for health sync state
struct HealthSyncStatusView: View {
    @EnvironmentObject var healthKitService: HealthKitService
    @State private var showDetailedStatus = false

    var body: some View {
        VStack(spacing: 0) {
            // Main status row
            Button {
                showDetailedStatus.toggle()
            } label: {
                HStack(spacing: 12) {
                    // Status icon
                    statusIcon

                    // Status text
                    VStack(alignment: .leading, spacing: 2) {
                        Text(statusTitle)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        Text(statusSubtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Chevron
                    Image(systemName: showDetailedStatus ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .buttonStyle(.plain)

            // Expanded details
            if showDetailedStatus {
                Divider()
                detailedStatusView
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }

    // MARK: - Status Components

    private var statusIcon: some View {
        Group {
            if healthKitService.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else if healthKitService.isAuthorized {
                Image(systemName: "heart.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
            } else {
                Image(systemName: "heart.slash.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 32, height: 32)
    }

    private var statusTitle: String {
        if healthKitService.isLoading {
            return "Syncing..."
        } else if !healthKitService.isAuthorized {
            return "Not Connected"
        } else if healthKitService.hasHealthData {
            return "Synced"
        } else {
            return "No Data Yet"
        }
    }

    private var statusSubtitle: String {
        if healthKitService.isLoading {
            return "Updating health data"
        } else if !healthKitService.isAuthorized {
            return "Tap to connect Apple Health"
        } else if let lastSync = healthKitService.lastSyncDate {
            return "Last synced \(RelativeDateTimeFormatter().localizedString(for: lastSync, relativeTo: Date()))"
        } else {
            return "Tap to sync now"
        }
    }

    // MARK: - Detailed Status View

    private var detailedStatusView: some View {
        VStack(spacing: 12) {
            // Data summary
            if healthKitService.isAuthorized {
                dataSummaryGrid
            }

            // Action buttons
            actionButtons
        }
        .padding()
        .background(Color(.secondarySystemBackground))
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
                iconColor: .blue,
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
        HStack(spacing: 12) {
            if healthKitService.isAuthorized {
                Button {
                    Task {
                        _ = try? await healthKitService.syncTodayData()
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Sync Now")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(healthKitService.isLoading)
            } else {
                Button {
                    Task {
                        _ = try? await healthKitService.requestAuthorization()
                    }
                } label: {
                    HStack {
                        Image(systemName: "heart.circle")
                        Text("Connect")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
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
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
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
                        .foregroundColor(.blue)
                }
            }

            if healthKitService.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.7)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
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
