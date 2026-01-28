//
//  PasswordResetView.swift
//  PTPerformance
//
//  Auth redesign: Simple password reset request form
//

import SwiftUI

struct PasswordResetView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var isLoading = false
    @State private var showConfirmation = false
    @State private var errorMessage: String?

    // Validation
    @State private var emailValidation: ValidationResult?

    var body: some View {
        Form {
            // MARK: - Instructions
            Section {
                Text("Enter the email address associated with your account and we'll send you a link to reset your password.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // MARK: - Email Input
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .accessibilityLabel("Email")
                        .accessibilityHint("Enter the email address for your account")
                        .onChange(of: email) { _, newValue in
                            if !newValue.isEmpty {
                                emailValidation = ValidationHelpers.validateEmail(newValue)
                            } else {
                                emailValidation = nil
                            }
                        }

                    if let error = emailValidation?.errorMessage, !email.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption)
                            Text(error)
                                .font(.caption)
                        }
                        .foregroundColor(.red)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Error: \(error)")
                    }
                }
            }

            // MARK: - Send Reset Link Button
            Section {
                Button(action: {
                    Task {
                        await sendResetLink()
                    }
                }) {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding(.trailing, 8)
                        }
                        Text("Send Reset Link")
                            .font(.body.weight(.semibold))
                        Spacer()
                    }
                }
                .disabled(!isEmailValid || isLoading || showConfirmation)
                .accessibilityLabel("Send Reset Link")
                .accessibilityHint(isEmailValid ? "Send a password reset link to your email" : "Enter a valid email address first")
            }

            // MARK: - Confirmation
            if showConfirmation {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)

                        Text("Reset link sent!")
                            .font(.headline)

                        Text("Check your email at \(email) for a link to reset your password. It may take a few minutes to arrive.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Reset link sent. Check your email at \(email) for a link to reset your password.")
                }
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
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Error: \(errorMessage)")
                }
            }
        }
        .navigationTitle("Reset Password")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Validation

    private var isEmailValid: Bool {
        guard !email.isEmpty else { return false }
        return emailValidation?.isValid ?? false
    }

    // MARK: - Send Reset Link

    private func sendResetLink() async {
        isLoading = true
        errorMessage = nil

        do {
            try await PTSupabaseClient.shared.resetPassword(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines)
            )

            await MainActor.run {
                showConfirmation = true
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to send reset link: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        PasswordResetView()
    }
}
