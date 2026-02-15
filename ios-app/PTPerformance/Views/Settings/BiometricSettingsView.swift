//
//  BiometricSettingsView.swift
//  PTPerformance
//
//  ACP-1039: Biometric Authentication Settings
//  Allows users to enable/disable Face ID / Touch ID lock
//

import SwiftUI

// MARK: - Biometric Settings View

/// Settings view for configuring biometric authentication (Face ID / Touch ID)
struct BiometricSettingsView: View {

    // MARK: - State

    @StateObject private var biometricService = BiometricAuthService.shared
    @State private var showEnableError = false
    @State private var showDisableConfirmation = false
    @State private var isAuthenticating = false

    // MARK: - Body

    var body: some View {
        List {
            // Status Section
            statusSection

            // Main Toggle Section
            if biometricService.isBiometryAvailable {
                mainToggleSection
            }

            // Lock Timing Section
            if biometricService.isBiometricLockEnabled {
                lockTimingSection
                sensitiveScreensSection
            }

            // Info Section
            infoSection
        }
        .navigationTitle("Biometric Lock")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Could Not Enable", isPresented: $showEnableError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(biometricService.biometricType.rawValue) authentication failed. Please try again or check your device settings.")
        }
        .alert("Disable \(biometricService.biometricType.rawValue) Lock?", isPresented: $showDisableConfirmation) {
            Button("Disable", role: .destructive) {
                biometricService.disableBiometricLock()
                HapticFeedback.toggle()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your app will no longer require \(biometricService.biometricType.rawValue) to unlock.")
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        Section {
            HStack(spacing: Spacing.md) {
                Image(systemName: biometricService.biometricType.iconName)
                    .font(.system(size: 40))
                    .foregroundColor(biometricService.isBiometryAvailable ? .modusCyan : .secondary)
                    .frame(width: 50)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(biometricService.biometricType.rawValue)
                        .font(.headline)

                    Text(statusDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, Spacing.xs)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(biometricService.biometricType.rawValue): \(statusDescription)")
        }
    }

    // MARK: - Main Toggle Section

    private var mainToggleSection: some View {
        Section {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "lock.fill")
                    .foregroundColor(.modusCyan)
                    .frame(width: 28)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Require \(biometricService.biometricType.rawValue)")

                    Text("Lock app with \(biometricService.biometricType.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isAuthenticating {
                    ProgressView()
                } else {
                    Toggle("", isOn: Binding(
                        get: { biometricService.isBiometricLockEnabled },
                        set: { newValue in
                            handleToggle(newValue)
                        }
                    ))
                    .labelsHidden()
                    .tint(.modusCyan)
                }
            }
            .accessibilityLabel("Require \(biometricService.biometricType.rawValue)")
            .accessibilityValue(biometricService.isBiometricLockEnabled ? "On" : "Off")
            .accessibilityHint("Toggle to require \(biometricService.biometricType.rawValue) when opening the app")
        } header: {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.modusCyan)
                Text("App Lock")
            }
            .accessibilityAddTraits(.isHeader)
        } footer: {
            Text("When enabled, \(biometricService.biometricType.rawValue) or your device passcode will be required to access the app.")
        }
    }

    // MARK: - Lock Timing Section

    private var lockTimingSection: some View {
        Section {
            Picker("Lock after", selection: Binding(
                get: { biometricService.lockTiming },
                set: { newValue in
                    biometricService.lockTiming = newValue
                    HapticFeedback.selectionChanged()
                }
            )) {
                ForEach(BiometricLockTiming.allCases) { timing in
                    Text(timing.rawValue).tag(timing)
                }
            }
            .accessibilityLabel("Lock timing")
            .accessibilityHint("Choose how long after backgrounding the app before the lock engages")
        } header: {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.modusCyan)
                Text("Lock Timing")
            }
            .accessibilityAddTraits(.isHeader)
        } footer: {
            Text("Choose how long after leaving the app before the lock screen appears.")
        }
    }

    // MARK: - Sensitive Screens Section

    private var sensitiveScreensSection: some View {
        Section {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "heart.text.square.fill")
                    .foregroundColor(.red)
                    .frame(width: 28)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Protect Sensitive Data")

                    Text("Require authentication for labs and health data")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Toggle("", isOn: $biometricService.isSensitiveScreenLockEnabled)
                    .labelsHidden()
                    .tint(.modusCyan)
                    .onChange(of: biometricService.isSensitiveScreenLockEnabled) { _, _ in
                        HapticFeedback.toggle()
                    }
            }
            .accessibilityLabel("Protect sensitive data")
            .accessibilityValue(biometricService.isSensitiveScreenLockEnabled ? "On" : "Off")
            .accessibilityHint("Toggle to require authentication when viewing labs and health data")
        } header: {
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundColor(.modusCyan)
                Text("Sensitive Data")
            }
            .accessibilityAddTraits(.isHeader)
        } footer: {
            Text("When enabled, viewing lab results and health data will require additional \(biometricService.biometricType.rawValue) verification.")
        }
    }

    // MARK: - Info Section

    private var infoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                infoRow(icon: "checkmark.shield.fill", text: "Biometric data never leaves your device")
                infoRow(icon: "cpu", text: "Secured by the Secure Enclave processor")
                infoRow(icon: "key.fill", text: "Device passcode available as fallback")
            }
            .padding(.vertical, Spacing.xs)
        } header: {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.modusCyan)
                Text("Privacy & Security")
            }
            .accessibilityAddTraits(.isHeader)
        }
    }

    // MARK: - Helpers

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(.modusCyan)
                .frame(width: 20)
                .accessibilityHidden(true)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var statusDescription: String {
        if !biometricService.isBiometryAvailable {
            return "Not available on this device"
        } else if biometricService.isBiometricLockEnabled {
            return "Enabled - App is protected"
        } else {
            return "Available - Not enabled"
        }
    }

    private func handleToggle(_ newValue: Bool) {
        if newValue {
            // Enabling — require biometric auth first
            isAuthenticating = true
            Task {
                let success = await biometricService.enableBiometricLock()
                isAuthenticating = false
                if success {
                    HapticFeedback.success()
                } else {
                    showEnableError = true
                    HapticFeedback.error()
                }
            }
        } else {
            // Disabling — show confirmation
            showDisableConfirmation = true
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BiometricSettingsView()
    }
}
