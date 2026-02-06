//
//  PasswordResetView.swift
//  PTPerformance
//
//  Auth redesign: Password recovery options - Magic link OR password reset
//

import SwiftUI

struct PasswordResetView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var isLoading = false
    @State private var showConfirmation = false
    @State private var confirmationType: ConfirmationType = .magicLink
    @State private var errorMessage: String?

    // Validation
    @State private var emailValidation: ValidationResult?

    enum ConfirmationType {
        case magicLink
        case passwordReset
    }

    var body: some View {
        Form {
            // MARK: - Instructions
            Section {
                Text("Enter your email address to sign back into your account.")
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

            // MARK: - Action Buttons
            if !showConfirmation {
                // MARK: - Send Magic Link Button (Primary)
                Section {
                    Button(action: {
                        Task {
                            await sendMagicLink()
                        }
                    }) {
                        HStack {
                            Spacer()
                            if isLoading && confirmationType == .magicLink {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .padding(.trailing, 8)
                                    .accessibilityHidden(true)
                            }
                            VStack(spacing: 2) {
                                Text("Send Sign-In Link")
                                    .font(.body.weight(.semibold))
                                Text("(Recommended)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!isEmailValid || isLoading)
                    .accessibilityLabel(isLoading ? "Sending sign-in link" : "Send Sign-In Link")
                    .accessibilityHint(isEmailValid ? "Send a link to sign in without a password" : "Enter a valid email address first")
                } footer: {
                    Text("We'll email you a link that signs you in instantly - no password needed.")
                }

                // MARK: - Reset Password Button (Secondary)
                Section {
                    Button(action: {
                        Task {
                            await sendPasswordReset()
                        }
                    }) {
                        HStack {
                            Spacer()
                            if isLoading && confirmationType == .passwordReset {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .padding(.trailing, 8)
                                    .accessibilityHidden(true)
                            }
                            Text("Reset My Password")
                                .font(.body)
                                .foregroundColor(.blue)
                            Spacer()
                        }
                    }
                    .disabled(!isEmailValid || isLoading)
                    .accessibilityLabel(isLoading ? "Sending password reset" : "Reset My Password")
                    .accessibilityHint(isEmailValid ? "Send a link to set a new password" : "Enter a valid email address first")
                } footer: {
                    Text("Forgot your password? We'll send a link to create a new one.")
                }
            }

            // MARK: - Confirmation
            if showConfirmation {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "paperplane.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                            .accessibilityHidden(true)

                        Text(confirmationType == .magicLink ? "Sign-in link sent!" : "Password reset link sent!")
                            .font(.headline)

                        Text(confirmationMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(confirmationMessage)
                }

                Section {
                    Button("Send Another Link") {
                        showConfirmation = false
                    }
                    .foregroundColor(.blue)
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
        .navigationTitle("Account Recovery")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Computed Properties

    private var isEmailValid: Bool {
        guard !email.isEmpty else { return false }
        return emailValidation?.isValid ?? false
    }

    private var confirmationMessage: String {
        switch confirmationType {
        case .magicLink:
            return "Check your email at \(email) for a link to sign in. Just tap the link and you'll be logged in automatically."
        case .passwordReset:
            return "Check your email at \(email) for a link to reset your password. The link will open the app where you can set a new password."
        }
    }

    // MARK: - Actions

    private func sendMagicLink() async {
        isLoading = true
        errorMessage = nil
        confirmationType = .magicLink

        do {
            try await PTSupabaseClient.shared.sendMagicLink(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines)
            )

            await MainActor.run {
                showConfirmation = true
                isLoading = false
            }
        } catch {
            await MainActor.run {
                // Provide user-friendly error message
                let errorString = String(describing: error)
                if errorString.contains("rate") || errorString.contains("limit") {
                    errorMessage = "Too many requests. Please wait a few minutes and try again."
                } else if errorString.contains("invalid") || errorString.contains("not found") {
                    errorMessage = "We couldn't find an account with that email. Please check and try again."
                } else {
                    errorMessage = "Unable to send sign-in link. Please check your internet connection and try again."
                }
                isLoading = false

                #if DEBUG
                print("❌ Magic link error: \(error)")
                #endif
            }
        }
    }

    private func sendPasswordReset() async {
        isLoading = true
        errorMessage = nil
        confirmationType = .passwordReset

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
                // Provide user-friendly error message
                let errorString = String(describing: error)
                if errorString.contains("rate") || errorString.contains("limit") {
                    errorMessage = "Too many requests. Please wait a few minutes and try again."
                } else if errorString.contains("invalid") || errorString.contains("not found") {
                    errorMessage = "We couldn't find an account with that email. Please check and try again."
                } else {
                    errorMessage = "Unable to send password reset email. Please check your internet connection and try again."
                }
                isLoading = false

                #if DEBUG
                print("❌ Password reset error: \(error)")
                #endif
            }
        }
    }
}

#Preview {
    NavigationStack {
        PasswordResetView()
    }
}
