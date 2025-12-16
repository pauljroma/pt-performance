import SwiftUI

struct AuthView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var supabase = PTSupabaseClient.shared

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    // Validation state
    @State private var emailValidation: ValidationResult?
    @State private var passwordValidation: ValidationResult?

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("PT Performance")
                    .font(.largeTitle)
                    .bold()

                Text("Physical Therapy Progress Tracking")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 32)

            // Email & Password Login (Hidden for demo)
            if false {  // Set to true to enable manual login
                VStack(spacing: 12) {
                    // Email field with validation
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .accessibilityLabel("Email")
                            .accessibilityHint("Enter your email address")
                            .onChange(of: email) { newValue in
                                if !newValue.isEmpty {
                                    emailValidation = ValidationHelpers.validateEmail(newValue)
                                } else {
                                    emailValidation = nil
                                }
                            }

                        if let errorMessage = emailValidation?.errorMessage, !email.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.caption)
                                Text(errorMessage)
                                    .font(.caption)
                            }
                            .foregroundColor(.red)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Error: \(errorMessage)")
                        }
                    }

                    // Password field with validation
                    VStack(alignment: .leading, spacing: 4) {
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .accessibilityLabel("Password")
                            .accessibilityHint("Enter your password, at least 8 characters with 1 uppercase letter and 1 number")
                            .onChange(of: password) { newValue in
                                if !newValue.isEmpty {
                                    passwordValidation = ValidationHelpers.validatePassword(newValue)
                                } else {
                                    passwordValidation = nil
                                }
                            }

                        if let errorMessage = passwordValidation?.errorMessage, !password.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.caption)
                                Text(errorMessage)
                                    .font(.caption)
                            }
                            .foregroundColor(.red)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Error: \(errorMessage)")
                        }
                    }

                    Button("Sign In") {
                        Task {
                            await signIn()
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                    .accessibilityLabel("Sign In")
                    .accessibilityHint(isFormValid ? "Sign in with your credentials" : "Complete all fields correctly to sign in")
                }
            }

            // Demo User Buttons
            VStack(spacing: 16) {
                Button(action: {
                    Task {
                        await signInAsDemoPatient()
                    }
                }) {
                    HStack {
                        Image(systemName: "person.fill")
                        Text("Sign in as Demo Patient")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isLoading)
                .accessibilityLabel("Sign in as Demo Patient")
                .accessibilityHint("Quick sign in to view patient features")

                Button(action: {
                    Task {
                        await signInAsNicRoma()
                    }
                }) {
                    HStack {
                        Image(systemName: "dumbbell.fill")
                        Text("Sign in as Nic Roma")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isLoading)
                .accessibilityLabel("Sign in as Nic Roma")
                .accessibilityHint("Quick sign in to view Nic Roma's training program")

                Button(action: {
                    Task {
                        await signInAsDemoTherapist()
                    }
                }) {
                    HStack {
                        Image(systemName: "stethoscope")
                        Text("Sign in as Demo Therapist")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isLoading)
                .accessibilityLabel("Sign in as Demo Therapist")
                .accessibilityHint("Quick sign in to view therapist features and manage patients")
            }

            // Loading Indicator
            if isLoading {
                ProgressView("Signing in...")
                    .padding()
            }

            // Error Message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding()
            }

            Spacer()

            // Demo Credentials Info
            VStack(spacing: 4) {
                Text("Demo Credentials")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Patient: demo-patient@ptperformance.app")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text("Therapist: demo-pt@ptperformance.app")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .padding()
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

    // MARK: - Authentication Methods

    private func signIn() async {
        isLoading = true
        errorMessage = nil

        do {
            try await supabase.signIn(email: email, password: password)

            // Update app state after successful login
            await MainActor.run {
                if let userRole = supabase.userRole {
                    appState.isAuthenticated = true
                    appState.userRole = userRole
                    appState.userId = supabase.userId
                }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Sign in failed: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    private func signInAsDemoPatient() async {
        isLoading = true
        errorMessage = nil

        do {
            try await supabase.signInAsDemoPatient()

            // Update app state
            await MainActor.run {
                appState.isAuthenticated = true
                appState.userRole = .patient
                appState.userId = supabase.userId
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Demo patient sign in failed: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    private func signInAsNicRoma() async {
        isLoading = true
        errorMessage = nil

        do {
            try await supabase.signInAsNicRoma()

            // Update app state
            await MainActor.run {
                appState.isAuthenticated = true
                appState.userRole = .patient
                appState.userId = supabase.userId
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Nic Roma sign in failed: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    private func signInAsDemoTherapist() async {
        isLoading = true
        errorMessage = nil

        do {
            try await supabase.signInAsDemoTherapist()

            // Update app state
            await MainActor.run {
                appState.isAuthenticated = true
                appState.userRole = .therapist
                appState.userId = supabase.userId
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Demo therapist sign in failed: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}
