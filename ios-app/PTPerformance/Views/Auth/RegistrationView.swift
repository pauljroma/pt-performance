// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  RegistrationView.swift
//  PTPerformance
//
//  Auth redesign: Email registration form with validation
//

import SwiftUI

struct RegistrationView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    // Validation states
    @State private var emailValidation: ValidationResult?
    @State private var passwordValidation: ValidationResult?
    @State private var confirmPasswordValidation: ValidationResult?
    @State private var fullNameValidation: ValidationResult?

    var body: some View {
        Form {
            // MARK: - Your Information
            Section("Your Information") {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Full Name", text: $fullName)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("fullNameTextField")
                        .accessibilityLabel("Full Name")
                        .onChange(of: fullName) { _, newValue in
                            if !newValue.isEmpty {
                                fullNameValidation = ValidationHelpers.validateNotEmpty(newValue, fieldName: "Full name")
                            } else {
                                fullNameValidation = nil
                            }
                        }

                    if let error = fullNameValidation?.errorMessage, !fullName.isEmpty {
                        validationErrorLabel(error)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("registrationEmailTextField")
                        .accessibilityLabel("Email")
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
            }

            // MARK: - Security
            Section("Security") {
                VStack(alignment: .leading, spacing: 4) {
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                        .accessibilityIdentifier("registrationPasswordSecureField")
                        .accessibilityLabel("Password")
                        .accessibilityHint("At least 8 characters with 1 uppercase letter and 1 number")
                        .onChange(of: password) { _, newValue in
                            if !newValue.isEmpty {
                                passwordValidation = ValidationHelpers.validatePassword(newValue)
                            } else {
                                passwordValidation = nil
                            }
                            // Re-validate confirm password when password changes
                            if !confirmPassword.isEmpty {
                                confirmPasswordValidation = validateConfirmPassword()
                            }
                        }

                    if let error = passwordValidation?.errorMessage, !password.isEmpty {
                        validationErrorLabel(error)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                        .accessibilityIdentifier("confirmPasswordSecureField")
                        .accessibilityLabel("Confirm Password")
                        .accessibilityHint("Re-enter your password to confirm")
                        .onChange(of: confirmPassword) { _, newValue in
                            if !newValue.isEmpty {
                                confirmPasswordValidation = validateConfirmPassword()
                            } else {
                                confirmPasswordValidation = nil
                            }
                        }

                    if let error = confirmPasswordValidation?.errorMessage, !confirmPassword.isEmpty {
                        validationErrorLabel(error)
                    }
                }
            }

            // MARK: - Create Account Button
            Section {
                Button(action: {
                    Task {
                        await createAccount()
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
                        Text("Create Account")
                            .font(.body.weight(.semibold))
                        Spacer()
                    }
                }
                .disabled(!isFormValid || isLoading)
                .accessibilityIdentifier("createAccountButton")
                .accessibilityLabel(isLoading ? "Creating account" : "Create Account")
                .accessibilityHint(isFormValid ? "Create your new account" : "Complete all fields correctly to create account")
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
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        let nameValid = !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let emailValid = emailValidation?.isValid ?? false
        let passwordValid = passwordValidation?.isValid ?? false
        let confirmValid = confirmPasswordValidation?.isValid ?? false
        return nameValid && emailValid && passwordValid && confirmValid
    }

    private func validateConfirmPassword() -> ValidationResult {
        if confirmPassword != password {
            return .invalid("Passwords do not match")
        }
        return .valid
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

    // MARK: - Account Creation

    private func createAccount() async {
        isLoading = true
        errorMessage = nil

        do {
            try await PTSupabaseClient.shared.signUp(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password,
                fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines)
            )

            let supabase = PTSupabaseClient.shared

            // BUILD 317: Check if we have a valid session (no email confirmation required)
            // or if email confirmation is needed
            if supabase.currentSession != nil {
                // Start session monitoring (HIPAA automatic logoff requirement)
                SessionManager.shared.startMonitoring()

                // Update app state after successful registration
                await MainActor.run {
                    appState.userRole = supabase.userRole ?? .patient
                    appState.userId = supabase.userId
                    appState.isAuthenticated = true
                    isLoading = false
                }
            } else {
                // Email confirmation required - show message and return to login
                await MainActor.run {
                    errorMessage = "Account created! Please check your email to verify your account, then sign in."
                    isLoading = false
                    // Clear form
                    fullName = ""
                    email = ""
                    password = ""
                    confirmPassword = ""
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Registration failed: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        RegistrationView()
            .environmentObject(AppState())
    }
}
