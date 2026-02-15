//
//  BiometricLockScreen.swift
//  PTPerformance
//
//  ACP-1039: Biometric Lock Screen Overlay
//  Full-screen lock overlay requiring Face ID / Touch ID to unlock
//

import SwiftUI

// MARK: - Biometric Lock Screen

/// Full-screen lock overlay shown when the app requires biometric authentication
///
/// Displays the app branding, biometric icon, and unlock buttons.
/// Supports Face ID, Touch ID, and device passcode fallback.
struct BiometricLockScreen: View {

    // MARK: - State

    @StateObject private var biometricService = BiometricAuthService.shared
    @State private var isAuthenticating = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var iconScale: CGFloat = 0.8
    @State private var iconOpacity: Double = 0.0

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer()

                // App Branding
                brandingSection

                Spacer()

                // Biometric Icon
                biometricIcon

                // Status Text
                statusText

                Spacer()

                // Unlock Buttons
                unlockButtons

                Spacer()
                    .frame(height: Spacing.xxl)
            }
            .padding(.horizontal, Spacing.lg)
        }
        .onAppear {
            withAnimation(.easeOut(duration: AnimationDuration.slow)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }
            // Auto-trigger authentication on appear
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay for smooth transition
                await attemptUnlock()
            }
        }
        .alert("Authentication Failed", isPresented: $showError) {
            Button("Try Again") {
                Task {
                    await attemptUnlock()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("App locked. \(biometricService.biometricType.rawValue) required to unlock.")
    }

    // MARK: - Branding Section

    private var brandingSection: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 48))
                .foregroundColor(.modusCyan)
                .accessibilityHidden(true)

            Text("PT Performance")
                .font(.title2)
                .fontWeight(.bold)

            Text("Modus")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("PT Performance by Modus")
    }

    // MARK: - Biometric Icon

    private var biometricIcon: some View {
        Image(systemName: biometricService.biometricType.iconName)
            .font(.system(size: 64))
            .foregroundColor(.modusCyan)
            .scaleEffect(iconScale)
            .opacity(iconOpacity)
            .accessibilityHidden(true)
    }

    // MARK: - Status Text

    private var statusText: some View {
        VStack(spacing: Spacing.xs) {
            Text("App Locked")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Use \(biometricService.biometricType.rawValue) or your passcode to unlock")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Unlock Buttons

    private var unlockButtons: some View {
        VStack(spacing: Spacing.md) {
            // Primary unlock button (biometric)
            Button {
                HapticFeedback.medium()
                Task {
                    await attemptUnlock()
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    if isAuthenticating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: biometricService.biometricType.iconName)
                    }
                    Text(isAuthenticating ? "Authenticating..." : "Unlock with \(biometricService.biometricType.rawValue)")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(Color.modusCyan)
                .cornerRadius(CornerRadius.md)
            }
            .disabled(isAuthenticating)
            .accessibilityLabel("Unlock with \(biometricService.biometricType.rawValue)")
            .accessibilityHint("Double tap to authenticate with \(biometricService.biometricType.rawValue)")

            // Passcode fallback button
            Button {
                HapticFeedback.light()
                Task {
                    await attemptPasscodeUnlock()
                }
            } label: {
                Text("Use Passcode")
                    .font(.subheadline)
                    .foregroundColor(.modusCyan)
            }
            .disabled(isAuthenticating)
            .accessibilityLabel("Use device passcode")
            .accessibilityHint("Double tap to unlock using your device passcode instead")
        }
    }

    // MARK: - Actions

    private func attemptUnlock() async {
        guard !isAuthenticating else { return }

        isAuthenticating = true
        defer { isAuthenticating = false }

        let success = await biometricService.unlock()
        if !success {
            errorMessage = "Could not verify your identity. Please try again."
            // Don't show alert on first auto-attempt to avoid jarring UX
        }
    }

    private func attemptPasscodeUnlock() async {
        guard !isAuthenticating else { return }

        isAuthenticating = true
        defer { isAuthenticating = false }

        let success = await biometricService.authenticateWithPasscodeFallback(
            reason: "Unlock PT Performance"
        )
        if success {
            biometricService.isLocked = false
            HapticFeedback.success()
        } else {
            errorMessage = "Passcode verification failed. Please try again."
            showError = true
        }
    }
}

// MARK: - Preview

#Preview {
    BiometricLockScreen()
}
