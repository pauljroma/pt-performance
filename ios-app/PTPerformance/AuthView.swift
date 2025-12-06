import SwiftUI

struct AuthView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var supabase = PTSupabaseClient.shared

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

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
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Sign In") {
                    Task {
                        await signIn()
                    }
                }
                .disabled(email.isEmpty || password.isEmpty || isLoading)
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
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Demo patient sign in failed: \(error.localizedDescription)"
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
