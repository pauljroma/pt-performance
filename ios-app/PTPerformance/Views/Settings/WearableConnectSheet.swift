// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  WearableConnectSheet.swift
//  PTPerformance
//
//  ACP-472: Wearable Settings UI
//  Bottom sheet for connecting a new wearable device
//

import SwiftUI

/// Bottom sheet presented when a user taps "Connect" on an available wearable.
///
/// Displays the device icon (large), name, description of what data it provides,
/// and a connect button. Handles OAuth devices (WHOOP, Oura) and HealthKit
/// (Apple Watch) differently. Shows loading, success, and error states.
struct WearableConnectSheet: View {

    // MARK: - Properties

    let wearableType: WearableType
    let onConnect: () async throws -> Void

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var connectionState: ConnectionState = .idle
    @State private var errorMessage: String?

    // MARK: - Connection State

    private enum ConnectionState: Equatable {
        case idle
        case connecting
        case success
        case error
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Device icon (large)
                    deviceIconView

                    // Device name and description
                    deviceInfoView

                    // Data capabilities
                    dataCapabilitiesView

                    Spacer(minLength: Spacing.lg)

                    // Connect button or status
                    connectionActionView

                    // Cancel button (when not connecting)
                    if connectionState == .idle {
                        Button("Cancel") {
                            HapticFeedback.light()
                            dismiss()
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, Spacing.md)
                        .accessibilityLabel("Cancel")
                        .accessibilityHint("Dismisses the connection sheet")
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)
            }
            .navigationTitle("Connect \(wearableType.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if connectionState != .connecting {
                        Button("Close") {
                            dismiss()
                        }
                        .accessibilityLabel("Close")
                    }
                }
            }
            .interactiveDismissDisabled(connectionState == .connecting)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Device Icon

    private var deviceIconView: some View {
        ZStack {
            Circle()
                .fill(wearableType.brandColor.opacity(0.12))
                .frame(width: 96, height: 96)

            Image(systemName: wearableType.iconName)
                .font(.system(size: 40))
                .foregroundColor(wearableType.brandColor)
        }
        .accessibilityHidden(true)
        .overlay(alignment: .bottomTrailing) {
            if connectionState == .success {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(DesignTokens.statusSuccess)
                    .background(Circle().fill(Color(.systemBackground)).padding(-2))
            }
        }
    }

    // MARK: - Device Info

    private var deviceInfoView: some View {
        VStack(spacing: Spacing.xs) {
            Text(wearableType.displayName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(connectionDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)
        }
    }

    // MARK: - Data Capabilities

    private var dataCapabilitiesView: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Data we'll sync")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: Spacing.xs)], spacing: Spacing.xs) {
                ForEach(dataCapabilities, id: \.self) { capability in
                    HStack(spacing: 4) {
                        Image(systemName: capability.icon)
                            .font(.caption2)
                            .accessibilityHidden(true)
                        Text(capability.label)
                            .font(.caption)
                    }
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, Spacing.xxs)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.xs)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Data synced: \(dataCapabilities.map(\.label).joined(separator: ", "))")
    }

    // MARK: - Connection Action

    @ViewBuilder
    private var connectionActionView: some View {
        switch connectionState {
        case .idle:
            Button {
                Task {
                    await performConnection()
                }
            } label: {
                HStack {
                    Image(systemName: connectButtonIcon)
                    Text(connectButtonTitle)
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(wearableType.brandColor)
                .foregroundColor(.white)
                .cornerRadius(CornerRadius.md)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(connectButtonTitle)
            .accessibilityHint(connectButtonHint)

        case .connecting:
            VStack(spacing: Spacing.sm) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.2)

                Text(connectingMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .accessibilityLabel(connectingMessage)

        case .success:
            VStack(spacing: Spacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(DesignTokens.statusSuccess)

                Text("Connected!")
                    .font(.headline)
                    .foregroundColor(DesignTokens.statusSuccess)

                Text("Your \(wearableType.displayName) data will sync automatically.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Button("Done") {
                    HapticFeedback.light()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .padding(.top, Spacing.xs)
                .accessibilityLabel("Done")
                .accessibilityHint("Closes the connection sheet")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)

        case .error:
            VStack(spacing: Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(DesignTokens.statusError)

                Text("Connection Failed")
                    .font(.headline)
                    .foregroundColor(DesignTokens.statusError)

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: Spacing.md) {
                    Button("Try Again") {
                        HapticFeedback.light()
                        Task {
                            await performConnection()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .accessibilityLabel("Try Again")

                    Button("Cancel") {
                        HapticFeedback.light()
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .accessibilityLabel("Cancel")
                }
                .padding(.top, Spacing.xs)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
        }
    }

    // MARK: - Actions

    private func performConnection() async {
        connectionState = .connecting
        errorMessage = nil

        do {
            try await onConnect()
            connectionState = .success
            HapticFeedback.success()
        } catch is CancellationError {
            // User cancelled (e.g. dismissed OAuth flow), just reset
            connectionState = .idle
        } catch {
            connectionState = .error
            errorMessage = error.localizedDescription
            HapticFeedback.error()
        }
    }

    // MARK: - Computed Properties

    private var connectionDescription: String {
        if wearableType.requiresOAuth {
            return "Sign in with your \(wearableType.displayName) account to sync your recovery and readiness data."
        } else {
            return "Allow access to Apple Health to sync your recovery and readiness data."
        }
    }

    private var connectButtonTitle: String {
        if wearableType.requiresOAuth {
            return "Connect \(wearableType.displayName)"
        } else {
            return "Allow Access"
        }
    }

    private var connectButtonIcon: String {
        if wearableType.requiresOAuth {
            return "link"
        } else {
            return "heart.circle"
        }
    }

    private var connectButtonHint: String {
        if wearableType.requiresOAuth {
            return "Opens \(wearableType.displayName) sign-in to authorize data access"
        } else {
            return "Requests permission to read health data from Apple Health"
        }
    }

    private var connectingMessage: String {
        if wearableType.requiresOAuth {
            return "Connecting to \(wearableType.displayName)..."
        } else {
            return "Requesting Apple Health access..."
        }
    }

    private var dataCapabilities: [DataCapability] {
        switch wearableType {
        case .whoop:
            return [
                DataCapability(icon: "waveform.path.ecg", label: "HRV"),
                DataCapability(icon: "flame.fill", label: "Strain"),
                DataCapability(icon: "battery.100", label: "Recovery"),
                DataCapability(icon: "bed.double.fill", label: "Sleep")
            ]
        case .appleWatch:
            return [
                DataCapability(icon: "waveform.path.ecg", label: "HRV"),
                DataCapability(icon: "heart.fill", label: "Heart Rate"),
                DataCapability(icon: "bed.double.fill", label: "Sleep"),
                DataCapability(icon: "figure.run", label: "Workouts")
            ]
        case .oura:
            return [
                DataCapability(icon: "waveform.path.ecg", label: "HRV"),
                DataCapability(icon: "battery.100", label: "Readiness"),
                DataCapability(icon: "bed.double.fill", label: "Sleep"),
                DataCapability(icon: "figure.walk", label: "Activity")
            ]
        case .garmin:
            return [
                DataCapability(icon: "waveform.path.ecg", label: "HRV"),
                DataCapability(icon: "bolt.fill", label: "Body Battery"),
                DataCapability(icon: "bed.double.fill", label: "Sleep"),
                DataCapability(icon: "brain.head.profile", label: "Stress")
            ]
        }
    }
}

// MARK: - Data Capability Model

private struct DataCapability: Hashable {
    let icon: String
    let label: String
}

// MARK: - Flow Layout
// Uses FlowLayout defined in ExerciseDetailSheet.swift (project-wide)

// MARK: - Preview

#Preview("OAuth Device (WHOOP)") {
    Text("Background")
        .sheet(isPresented: .constant(true)) {
            WearableConnectSheet(
                wearableType: .whoop,
                onConnect: {
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                }
            )
        }
}

#Preview("HealthKit Device (Apple Watch)") {
    Text("Background")
        .sheet(isPresented: .constant(true)) {
            WearableConnectSheet(
                wearableType: .appleWatch,
                onConnect: {
                    try await Task.sleep(nanoseconds: 1_500_000_000)
                }
            )
        }
}

#Preview("Oura Ring") {
    Text("Background")
        .sheet(isPresented: .constant(true)) {
            WearableConnectSheet(
                wearableType: .oura,
                onConnect: {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    throw WearableError.authorizationFailed("Oura authorization failed")
                }
            )
        }
}
