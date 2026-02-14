// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  EmailSignInView.swift
//  PTPerformance
//
//  Auth redesign: Email sign-in form with validation and security monitoring
//

import SwiftUI

struct EmailSignInView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    // Validation states
    @State private var emailValidation: ValidationResult?
    @State private var passwordValidation: ValidationResult?

    // Navigation
    @State private var showPasswordReset = false

    var body: some View {
        Form {
            // MARK: - Credentials
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("emailTextField")
                        .accessibilityLabel("Email")
                        .accessibilityHint("Enter your email address")
                        .onChange(of: email) { _, newValue in
                            if !newValue.isEmpty {
                                emailValidation = ValidationHelpers.validateEmail(newValue)
                            } else {
                                emailValidation = nil
                            }
                        }

                    if let error = emailValidation?.errorMessage, !email.isEmpty {
                        validationErrorLabel(error)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .accessibilityIdentifier("passwordSecureField")
                        .accessibilityLabel("Password")
                        .accessibilityHint("Enter your password")
                        .onChange(of: password) { _, newValue in
                            if !newValue.isEmpty {
                                passwordValidation = ValidationHelpers.validatePassword(newValue)
                            } else {
                                passwordValidation = nil
                            }
                        }

                    if let error = passwordValidation?.errorMessage, !password.isEmpty {
                        validationErrorLabel(error)
                    }
                }
            }

            // MARK: - Sign In Button
            Section {
                Button(action: {
                    HapticFeedback.medium()
                    Task {
                        await signIn()
                    }
                }) {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding(.trailing, Spacing.xs)
                                .accessibilityHidden(true)
                        }
                        Text("Sign In")
                            .font(.body.weight(.semibold))
                        Spacer()
                    }
                }
                .disabled(!isFormValid || isLoading)
                .accessibilityIdentifier("signInButton")
                .accessibilityLabel(isLoading ? "Signing in" : "Sign In")
                .accessibilityHint(isFormValid ? "Sign in with your credentials" : "Complete all fields correctly to sign in")
            }

            // MARK: - Forgot Password
            Section {
                Button(action: {
                    HapticFeedback.light()
                    showPasswordReset = true
                }) {
                    Text("Forgot Password?")
                        .font(.subheadline)
                        .foregroundColor(.modusCyan)
                }
                .accessibilityLabel("Forgot Password")
                .accessibilityHint("Navigate to password reset")
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
        .navigationTitle("Sign In")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(isPresented: $showPasswordReset) {
            PasswordResetView()
        }
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        guard !email.isEmpty && !password.isEmpty else {
            return false
        }
        let emailValid = emailValidation?.isValid ?? false
        let passwordValid = passwordValidation?.isValid ?? false
        return emailValid && passwordValid
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

    // MARK: - Sign In

    private func signIn() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if account is locked before attempting
        if SecurityMonitor.shared.isAccountLocked(email: trimmedEmail) {
            let remainingTime = SecurityMonitor.shared.getRemainingLockoutTime(email: trimmedEmail)
            let remainingMinutes = Int(remainingTime / 60) + 1
            await MainActor.run {
                errorMessage = "Account locked due to too many failed login attempts. Please try again in \(remainingMinutes) minutes."
            }
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await PTSupabaseClient.shared.signIn(email: trimmedEmail, password: password)

            // Record successful login (clear failed attempts)
            SecurityMonitor.shared.recordSuccessfulLogin(email: trimmedEmail)

            // Start session monitoring (HIPAA automatic logoff requirement)
            SessionManager.shared.startMonitoring()

            // Update app state after successful login
            let supabase = PTSupabaseClient.shared
            await MainActor.run {
                HapticFeedback.formSubmission(success: true)
                if let userRole = supabase.userRole {
                    appState.userRole = userRole
                }
                appState.userId = supabase.userId
                appState.isAuthenticated = true
                isLoading = false
            }
        } catch {
            // Record failed login attempt
            await SecurityMonitor.shared.recordFailedLogin(email: trimmedEmail)

            // Check if account is now locked after this failed attempt
            if SecurityMonitor.shared.isAccountLocked(email: trimmedEmail) {
                let remainingTime = SecurityMonitor.shared.getRemainingLockoutTime(email: trimmedEmail)
                let remainingMinutes = Int(remainingTime / 60) + 1
                await MainActor.run {
                    HapticFeedback.formSubmission(success: false)
                    errorMessage = "Account locked due to too many failed login attempts. Please try again in \(remainingMinutes) minutes."
                    isLoading = false
                }
            } else {
                let remaining = SecurityMonitor.shared.getRemainingAttempts(email: trimmedEmail)
                await MainActor.run {
                    HapticFeedback.formSubmission(success: false)
                    errorMessage = "Sign in failed: \(error.localizedDescription)\n\(remaining) attempts remaining."
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        EmailSignInView()
            .environmentObject(AppState())
    }
}
