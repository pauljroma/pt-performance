// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  WearableSettingsView.swift
//  PTPerformance
//
//  ACP-472: Wearable Settings UI
//  Main settings screen for managing wearable device connections
//

import SwiftUI

/// Main settings view for managing wearable device connections.
///
/// Displays two sections:
/// - **Connected**: Active wearable connections with sync status, primary badge,
///   and context menus for Set as Primary, Sync Now, and Disconnect.
/// - **Available**: Devices that can be connected, with Connect buttons or
///   "Coming Soon" badges for unsupported devices.
///
/// Supports pull-to-refresh, haptic feedback, and a connect sheet using
/// `.sheet(item:)` to avoid race conditions.
struct WearableSettingsView: View {

    // MARK: - Environment

    @EnvironmentObject var connectionManager: WearableConnectionManager

    // MARK: - State

    @State private var connectingDevice: WearableType?
    @State private var showDisconnectConfirmation = false
    @State private var deviceToDisconnect: WearableConnection?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isRefreshing = false

    // MARK: - Computed Properties

    /// Connected (active) wearable devices, sorted with primary first
    private var connectedDevices: [WearableConnection] {
        connectionManager.connections
            .filter { $0.isActive }
            .sorted { lhs, rhs in
                if lhs.isPrimary != rhs.isPrimary {
                    return lhs.isPrimary
                }
                return lhs.connectedAt < rhs.connectedAt
            }
    }

    /// Wearable types that are not currently connected
    private var availableDevices: [WearableType] {
        let connectedTypes = Set(connectedDevices.map(\.wearableType))
        return WearableType.allCases.filter { !connectedTypes.contains($0) }
    }

    /// Whether Garmin is coming soon (not yet implemented)
    private func isComingSoon(_ type: WearableType) -> Bool {
        type == .garmin
    }

    // MARK: - Body

    var body: some View {
        List {
            // Connected Devices Section
            if !connectedDevices.isEmpty {
                connectedSection
            }

            // Available Devices Section
            if !availableDevices.isEmpty {
                availableSection
            }

            // Info Footer Section
            infoSection
        }
        .navigationTitle("Wearable Devices")
        .navigationBarTitleDisplayMode(.inline)
        .refreshableWithHaptic {
            await refreshConnections()
        }
        .task {
            await loadConnections()
        }
        .sheet(item: connectingDeviceBinding) { type in
            WearableConnectSheet(
                wearableType: type,
                onConnect: {
                    try await connectionManager.connect(type: type)
                }
            )
        }
        .alert("Disconnect Device", isPresented: $showDisconnectConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Disconnect", role: .destructive) {
                if let device = deviceToDisconnect {
                    Task {
                        await performDisconnect(device)
                    }
                }
            }
        } message: {
            if let device = deviceToDisconnect {
                Text("Are you sure you want to disconnect \(device.wearableType.displayName)? Your data will be preserved but syncing will stop.")
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .overlay {
            if connectedDevices.isEmpty && !isRefreshing {
                emptyStateView
            }
        }
    }

    // MARK: - Connected Section

    private var connectedSection: some View {
        Section {
            ForEach(connectedDevices) { connection in
                WearableDeviceRow(
                    connection: connection,
                    onSetPrimary: {
                        Task {
                            await setPrimary(connection)
                        }
                    },
                    onSyncNow: {
                        await syncDevice(connection)
                    },
                    onDisconnect: {
                        deviceToDisconnect = connection
                        showDisconnectConfirmation = true
                    }
                )
            }
        } header: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(DesignTokens.statusSuccess)
                Text("Connected")
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Connected devices")
            .accessibilityAddTraits(.isHeader)
        }
    }

    // MARK: - Available Section

    private var availableSection: some View {
        Section {
            ForEach(availableDevices, id: \.self) { type in
                AvailableWearableRow(
                    wearableType: type,
                    isComingSoon: isComingSoon(type),
                    onConnect: {
                        connectingDevice = type
                    }
                )
            }
        } header: {
            HStack {
                Image(systemName: "plus.circle")
                    .foregroundColor(DesignTokens.statusInfo)
                Text("Available")
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Available devices")
            .accessibilityAddTraits(.isHeader)
        }
    }

    // MARK: - Info Section

    private var infoSection: some View {
        Section {
            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: "info.circle")
                    .foregroundColor(DesignTokens.statusInfo)
                    .font(.body)
                    .accessibilityHidden(true)

                Text("Your primary device is used for readiness scoring. Tap and hold a connected device to change or disconnect.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, Spacing.xxs)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Your primary device is used for readiness scoring. Tap and hold a connected device to change or disconnect.")
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        EmptyStateView(
            title: "No Wearables Connected",
            message: "Connect a wearable device to sync your recovery data and improve readiness scoring.",
            icon: "applewatch.and.arrow.forward",
            iconColor: DesignTokens.statusInfo
        )
    }

    // MARK: - Sheet Binding

    /// Uses `.sheet(item:)` pattern with a custom Binding to avoid race conditions.
    /// WearableType conforms to Identifiable in WearableProvider.swift to support this pattern.
    private var connectingDeviceBinding: Binding<WearableType?> {
        Binding(
            get: { connectingDevice },
            set: { newValue in
                if newValue != nil {
                    HapticFeedback.sheetPresented()
                }
                connectingDevice = newValue
            }
        )
    }

    // MARK: - Actions

    private func loadConnections() async {
        // Connections are loaded by the manager during sign-in via loadConnections(patientId:).
        // On initial appearance, trigger a sync to refresh data from all connected wearables.
        await connectionManager.syncAll()
    }

    private func refreshConnections() async {
        isRefreshing = true
        defer { isRefreshing = false }
        await connectionManager.syncAll()
    }

    private func setPrimary(_ connection: WearableConnection) async {
        HapticFeedback.selectionChanged()
        do {
            try await connectionManager.setPrimary(type: connection.wearableType)
        } catch {
            errorMessage = "Could not set \(connection.wearableType.displayName) as primary."
            showError = true
            HapticFeedback.error()
        }
    }

    private func syncDevice(_ connection: WearableConnection) async {
        HapticFeedback.light()
        do {
            let _ = try await connectionManager.fetchRecoveryData(from: connection.wearableType)
            HapticFeedback.success()
        } catch {
            errorMessage = "Sync failed for \(connection.wearableType.displayName). Please try again."
            showError = true
            HapticFeedback.error()
        }
    }

    private func performDisconnect(_ connection: WearableConnection) async {
        HapticFeedback.medium()
        do {
            try await connectionManager.disconnect(type: connection.wearableType)
            deviceToDisconnect = nil
            HapticFeedback.success()
        } catch {
            errorMessage = "Could not disconnect \(connection.wearableType.displayName)."
            showError = true
            HapticFeedback.error()
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    NavigationStack {
        WearableSettingsView()
            .environmentObject(WearableConnectionManager.preview)
    }
}
#endif
