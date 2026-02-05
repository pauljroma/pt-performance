//
//  PasswordResetView.swift
//  PTPerformance
//
//  Auth redesign: Magic link login form (simpler than password reset)
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
                Text("Enter your email address and we'll send you a magic link to sign back in. No password needed!")
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

            // MARK: - Send Magic Link Button
            Section {
                Button(action: {
                    Task {
                        await sendMagicLink()
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
                        Text("Send Magic Link")
                            .font(.body.weight(.semibold))
                        Spacer()
                    }
                }
                .disabled(!isEmailValid || isLoading || showConfirmation)
                .accessibilityLabel(isLoading ? "Sending magic link" : "Send Magic Link")
                .accessibilityHint(isEmailValid ? "Send a sign-in link to your email" : "Enter a valid email address first")
            }

            // MARK: - Confirmation
            if showConfirmation {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "paperplane.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                            .accessibilityHidden(true)

                        Text("Magic link sent!")
                            .font(.headline)

                        Text("Check your email at \(email) for a link to sign in. Just tap the link and you'll be logged in automatically.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Magic link sent. Check your email at \(email) for a link to sign in.")
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
        .navigationTitle("Sign In with Email")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Validation

    private var isEmailValid: Bool {
        guard !email.isEmpty else { return false }
        return emailValidation?.isValid ?? false
    }

    // MARK: - Send Magic Link

    private func sendMagicLink() async {
        isLoading = true
        errorMessage = nil

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
                errorMessage = "Failed to send magic link: \(error.localizedDescription)"
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
