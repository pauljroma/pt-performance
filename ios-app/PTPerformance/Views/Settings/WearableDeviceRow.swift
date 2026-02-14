// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  WearableDeviceRow.swift
//  PTPerformance
//
//  ACP-472: Wearable Settings UI
//  Reusable row component for displaying a wearable device connection
//

import SwiftUI

/// Reusable row for displaying a connected wearable device with context menu actions.
///
/// Shows the device icon, name, primary badge, relative last sync time,
/// and provides a context menu with Set as Primary, Sync Now, and Disconnect actions.
/// Supports swipe-to-disconnect for quick removal.
struct WearableDeviceRow: View {

    // MARK: - Properties

    let connection: WearableConnection
    let onSetPrimary: () -> Void
    let onSyncNow: () async -> Void
    let onDisconnect: () -> Void

    // MARK: - Private State

    @State private var isSyncing = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Device icon
            deviceIcon

            // Device info
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack(spacing: Spacing.xs) {
                    Text(connection.wearableType.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if connection.isPrimary {
                        primaryBadge
                    }
                }

                // Last sync time
                lastSyncLabel
            }

            Spacer()

            // Sync indicator or menu button
            if isSyncing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.8)
                    .accessibilityLabel("Syncing")
            }
        }
        .padding(.vertical, Spacing.xxs)
        .contentShape(Rectangle())
        .contextMenu {
            contextMenuItems
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                HapticFeedback.medium()
                onDisconnect()
            } label: {
                Label("Disconnect", systemImage: "xmark.circle")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap for options. Swipe left to disconnect.")
    }

    // MARK: - Subviews

    private var deviceIcon: some View {
        Image(systemName: connection.wearableType.iconName)
            .font(.title2)
            .foregroundColor(connection.wearableType.brandColor)
            .frame(width: 36, height: 36)
            .background(connection.wearableType.brandColor.opacity(0.12))
            .cornerRadius(CornerRadius.sm)
            .accessibilityHidden(true)
    }

    private var primaryBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .font(.caption2)
            Text("Primary")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.yellow.opacity(0.15))
        .foregroundColor(.orange)
        .cornerRadius(CornerRadius.xs)
        .accessibilityLabel("Primary device")
    }

    private var lastSyncLabel: some View {
        Group {
            if let lastSync = connection.lastSyncAt {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption2)
                        .accessibilityHidden(true)
                    Text("Last sync: ")
                        .font(.caption)
                    + Text(lastSync, style: .relative)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            } else {
                Text("Not yet synced")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private var contextMenuItems: some View {
        if !connection.isPrimary {
            Button {
                HapticFeedback.light()
                onSetPrimary()
            } label: {
                Label("Set as Primary", systemImage: "star")
            }
        }

        Button {
            HapticFeedback.light()
            Task {
                isSyncing = true
                await onSyncNow()
                isSyncing = false
            }
        } label: {
            Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
        }

        Divider()

        Button(role: .destructive) {
            HapticFeedback.medium()
            onDisconnect()
        } label: {
            Label("Disconnect", systemImage: "xmark.circle")
        }
    }

    // MARK: - Computed Properties

    /// Cached formatter for relative date descriptions in accessibility labels.
    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    private var accessibilityDescription: String {
        var description = connection.wearableType.displayName
        if connection.isPrimary {
            description += ", Primary device"
        }
        if connection.isActive {
            description += ", Connected"
        }
        if let lastSync = connection.lastSyncAt {
            let relativeTime = Self.relativeDateFormatter.localizedString(for: lastSync, relativeTo: Date())
            description += ", Last synced \(relativeTime)"
        } else {
            description += ", Not yet synced"
        }
        return description
    }
}

// MARK: - Available Device Row

/// Row for a wearable device that is not yet connected.
/// Shows the device icon, name, and either a Connect button or a "Coming Soon" badge.
struct AvailableWearableRow: View {

    let wearableType: WearableType
    let isComingSoon: Bool
    let onConnect: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Device icon
            Image(systemName: wearableType.iconName)
                .font(.title2)
                .foregroundColor(wearableType.brandColor)
                .frame(width: 36, height: 36)
                .background(wearableType.brandColor.opacity(0.12))
                .cornerRadius(CornerRadius.sm)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(wearableType.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(wearableType.dataDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isComingSoon {
                Text("Coming Soon")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, Spacing.xxs)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .foregroundColor(.secondary)
                    .cornerRadius(CornerRadius.xs)
            } else {
                Button {
                    HapticFeedback.light()
                    onConnect()
                } label: {
                    Text("Connect")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .accessibilityLabel("Connect \(wearableType.displayName)")
                .accessibilityHint("Opens the connection flow for \(wearableType.displayName)")
            }
        }
        .padding(.vertical, Spacing.xxs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Computed Properties

    private var accessibilityDescription: String {
        if isComingSoon {
            return "\(wearableType.displayName), Coming soon"
        }
        return "\(wearableType.displayName), Available to connect"
    }
}

// MARK: - Preview

#Preview("Connected Device") {
    List {
        WearableDeviceRow(
            connection: WearableConnection(
                id: UUID(),
                patientId: UUID(),
                wearableType: .whoop,
                isPrimary: true,
                isActive: true,
                connectedAt: Date().addingTimeInterval(-86400 * 7),
                lastSyncAt: Date().addingTimeInterval(-120),
                deviceMetadata: nil
            ),
            onSetPrimary: {},
            onSyncNow: {},
            onDisconnect: {}
        )

        WearableDeviceRow(
            connection: WearableConnection(
                id: UUID(),
                patientId: UUID(),
                wearableType: .appleWatch,
                isPrimary: false,
                isActive: true,
                connectedAt: Date().addingTimeInterval(-86400 * 30),
                lastSyncAt: Date().addingTimeInterval(-3600),
                deviceMetadata: nil
            ),
            onSetPrimary: {},
            onSyncNow: {},
            onDisconnect: {}
        )
    }
}

#Preview("Available Device") {
    List {
        AvailableWearableRow(
            wearableType: .oura,
            isComingSoon: false,
            onConnect: {}
        )

        AvailableWearableRow(
            wearableType: .garmin,
            isComingSoon: true,
            onConnect: {}
        )
    }
}
