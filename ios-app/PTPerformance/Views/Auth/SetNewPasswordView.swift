//
//  SetNewPasswordView.swift
//  PTPerformance
//
//  View for setting a new password after clicking the password reset link
//

import SwiftUI

struct SetNewPasswordView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var isEstablishingSession = true
    @State private var showSuccess = false
    @State private var errorMessage: String?

    // Validation states
    @State private var passwordValidation: ValidationResult?
    @State private var confirmValidation: ValidationResult?

    var body: some View {
        NavigationStack {
            Group {
                if isEstablishingSession {
                    // Show loading while extracting session from URL
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Verifying reset link...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                } else {
                    passwordForm
                }
            }
            .navigationTitle("Set New Password")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        cancelAndSignOut()
                    }
                }
            }
            .alert("Password Updated", isPresented: $showSuccess) {
                Button("Sign In") {
                    completePasswordReset()
                }
            } message: {
                Text("Your password has been updated successfully. Please sign in with your new password.")
            }
        }
        .task {
            await establishSession()
        }
    }

    // MARK: - Password Form

    private var passwordForm: some View {
        Form {
            // MARK: - Instructions
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "lock.rotation")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 8)

                    Text("Create a new password for your account. Make sure it's at least 8 characters and includes an uppercase letter and a number.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 8)
            }

            // MARK: - Password Fields
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    SecureField("New Password", text: $newPassword)
                        .textContentType(.newPassword)
                        .accessibilityLabel("New Password")
                        .accessibilityHint("Enter your new password")
                        .onChange(of: newPassword) { _, newValue in
                            if !newValue.isEmpty {
                                passwordValidation = ValidationHelpers.validatePassword(newValue)
                            } else {
                                passwordValidation = nil
                            }
                            // Re-validate confirm field if it has content
                            if !confirmPassword.isEmpty {
                                validateConfirmPassword()
                            }
                        }

                    if let error = passwordValidation?.errorMessage, !newPassword.isEmpty {
                        validationErrorLabel(error)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                        .accessibilityLabel("Confirm Password")
                        .accessibilityHint("Re-enter your new password to confirm")
                        .onChange(of: confirmPassword) { _, _ in
                            validateConfirmPassword()
                        }

                    if let error = confirmValidation?.errorMessage, !confirmPassword.isEmpty {
                        validationErrorLabel(error)
                    }
                }
            } header: {
                Text("New Password")
            } footer: {
                Text("Password must be at least 8 characters with 1 uppercase letter and 1 number")
            }

            // MARK: - Update Password Button
            Section {
                Button(action: {
                    Task {
                        await updatePassword()
                    }
                }) {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding(.trailing, 8)
                                .accessibilityHidden(true)
                        }
                        Text("Update Password")
                            .font(.body.weight(.semibold))
                        Spacer()
                    }
                }
                .disabled(!isFormValid || isLoading)
                .accessibilityLabel(isLoading ? "Updating password" : "Update Password")
                .accessibilityHint(isFormValid ? "Save your new password" : "Complete all fields correctly first")
            }

            // MARK: - Error Display
            if let errorMessage = errorMessage {
                Section {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.leading)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Error: \(errorMessage)")
                }
            }
        }
    }

    // MARK: - Session Establishment

    private func establishSession() async {
        guard let url = appState.pendingPasswordResetURL else {
            await MainActor.run {
                errorMessage = "No password reset link found. Please request a new reset email."
                isEstablishingSession = false
            }
            return
        }

        do {
            let session = try await PTSupabaseClient.shared.client.auth.session(from: url)

            await MainActor.run {
                appState.userId = session.user.id.uuidString
                appState.pendingPasswordResetURL = nil // Clear the URL after use
                isEstablishingSession = false
            }

            DebugLogger.shared.success("SetNewPasswordView", "Password reset session established for user: \(session.user.id)")
        } catch {
            await MainActor.run {
                errorMessage = "Reset link is invalid or has expired. Please request a new password reset email."
                isEstablishingSession = false
            }

            DebugLogger.shared.error("SetNewPasswordView", "Failed to establish session: \(error.localizedDescription)")
        }
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        guard !newPassword.isEmpty && !confirmPassword.isEmpty else {
            return false
        }
        let passwordValid = passwordValidation?.isValid ?? false
        let confirmValid = confirmValidation?.isValid ?? false
        return passwordValid && confirmValid
    }

    private func validateConfirmPassword() {
        if confirmPassword.isEmpty {
            confirmValidation = nil
        } else if confirmPassword != newPassword {
            confirmValidation = .invalid("Passwords do not match")
        } else {
            confirmValidation = .valid
        }
    }

    private func validationErrorLabel(_ message: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption)
            Text(message)
                .font(.caption)
        }
        .foregroundColor(.red)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
    }

    // MARK: - Actions

    private func updatePassword() async {
        isLoading = true
        errorMessage = nil

        do {
            try await PTSupabaseClient.shared.updatePassword(newPassword: newPassword)

            await MainActor.run {
                isLoading = false
                showSuccess = true
            }

            DebugLogger.shared.success("SetNewPasswordView", "Password updated successfully")
        } catch {
            await MainActor.run {
                errorMessage = "Failed to update password: \(error.localizedDescription)"
                isLoading = false
            }

            DebugLogger.shared.error("SetNewPasswordView", "Password update failed: \(error.localizedDescription)")
        }
    }

    private func completePasswordReset() {
        Task {
            // Sign out to clear the reset session
            try? await PTSupabaseClient.shared.signOut()

            await MainActor.run {
                appState.showSetNewPassword = false
                appState.pendingPasswordResetURL = nil
                appState.isAuthenticated = false
                appState.userId = nil
                appState.userRole = nil
            }
        }
    }

    private func cancelAndSignOut() {
        Task {
            // Sign out to clear the reset session
            try? await PTSupabaseClient.shared.signOut()

            await MainActor.run {
                appState.showSetNewPassword = false
                appState.pendingPasswordResetURL = nil
                appState.isAuthenticated = false
                appState.userId = nil
                appState.userRole = nil
            }
        }
    }
}

#Preview {
    SetNewPasswordView()
        .environmentObject(AppState())
}
