// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  AuthLandingView.swift
//  PTPerformance
//
//  Auth redesign: Landing screen with Apple Sign In, Email Sign In, and Registration
//

import SwiftUI

struct AuthLandingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var supabase = PTSupabaseClient.shared

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showEmailSignIn = false
    @State private var showRegistration = false

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                Spacer()

                // MARK: - App Logo & Branding
                VStack(spacing: Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.modusCyan, .modusTealAccent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)

                        Image(systemName: "figure.run")
                            .font(.system(size: 44))
                            .foregroundColor(.white)
                    }
                    .accessibilityHidden(true)

                    Text("Modus")
                        .font(.largeTitle)
                        .bold()

                    Text("Stop Guessing. Start Recovering.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // MARK: - Authentication Buttons
                VStack(spacing: Spacing.md) {
                    // Sign in with Apple
                    Button(action: {
                        HapticFeedback.light()
                        Task {
                            await signInWithApple()
                        }
                    }) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "apple.logo")
                                .font(.title3)
                            Text("Sign in with Apple")
                                .font(.body.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.label))
                        .foregroundColor(Color(.systemBackground))
                        .cornerRadius(CornerRadius.md)
                    }
                    .disabled(isLoading)
                    .accessibilityIdentifier("signInWithAppleButton")
                    .accessibilityLabel("Sign in with Apple")
                    .accessibilityHint("Use your Apple ID to sign in")

                    // Continue with Email
                    Button(action: {
                        HapticFeedback.light()
                        showEmailSignIn = true
                    }) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "envelope.fill")
                                .font(.title3)
                            Text("Continue with Email")
                                .font(.body.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.modusCyan)
                        .foregroundColor(.white)
                        .cornerRadius(CornerRadius.md)
                    }
                    .disabled(isLoading)
                    .accessibilityIdentifier("continueWithEmailButton")
                    .accessibilityLabel("Continue with Email")
                    .accessibilityHint("Sign in using your email and password")

                    // Create Account
                    Button(action: {
                        HapticFeedback.light()
                        showRegistration = true
                    }) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "person.badge.plus")
                                .font(.title3)
                            Text("Create Account")
                                .font(.body.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(CornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                    }
                    .disabled(isLoading)
                    .accessibilityIdentifier("createAccountButton")
                    .accessibilityLabel("Create Account")
                    .accessibilityHint("Register a new account")
                }

                // MARK: - Loading Indicator
                if isLoading {
                    ProgressView("Signing in...")
                        .padding(.top, Spacing.xs)
                        .accessibilityLabel("Signing in, please wait")
                }

                // MARK: - Error Display
                if let errorMessage = errorMessage {
                    HStack(spacing: Spacing.xxs + 2) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(DesignTokens.statusError)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(DesignTokens.statusError)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Error: \(errorMessage)")
                }

                Spacer()

                // MARK: - Demo Login (For Testing)
                VStack(spacing: Spacing.sm) {
                    Divider()
                        .padding(.vertical, Spacing.xs)

                    Text("Demo Accounts")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: Spacing.sm) {
                        // Demo Patient
                        Button(action: {
                            HapticFeedback.light()
                            loginAsDemoPatient()
                        }) {
                            HStack(spacing: Spacing.xxs + 2) {
                                Image(systemName: "person.fill")
                                    .font(.caption)
                                Text("Demo Patient")
                                    .font(.caption.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .background(DesignTokens.statusSuccess.opacity(0.15))
                            .foregroundColor(DesignTokens.statusSuccess)
                            .cornerRadius(CornerRadius.sm)
                        }
                        .accessibilityLabel("Demo Patient")
                        .accessibilityHint("Sign in as a demo patient user for testing")

                        // Demo Therapist
                        Button(action: {
                            HapticFeedback.light()
                            loginAsDemoTherapist()
                        }) {
                            HStack(spacing: Spacing.xxs + 2) {
                                Image(systemName: "stethoscope")
                                    .font(.caption)
                                Text("Demo Therapist")
                                    .font(.caption.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.modusCyan.opacity(0.15))
                            .foregroundColor(.modusCyan)
                            .cornerRadius(CornerRadius.sm)
                        }
                        .accessibilityLabel("Demo Therapist")
                        .accessibilityHint("Sign in as a demo therapist user for testing")
                    }
                }

                // MARK: - Footer
                Text("By continuing, you agree to our Terms of Service and Privacy Policy.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, Spacing.md)
            }
            .padding(.horizontal, Spacing.lg)
            .navigationDestination(isPresented: $showEmailSignIn) {
                EmailSignInView()
                    .environmentObject(appState)
            }
            .navigationDestination(isPresented: $showRegistration) {
                RegistrationView()
                    .environmentObject(appState)
            }
        }
    }

    // MARK: - Sign in with Apple

    private func signInWithApple() async {
        isLoading = true
        errorMessage = nil

        do {
            try await AppleSignInService.shared.signIn()

            // Start session monitoring (HIPAA automatic logoff requirement)
            SessionManager.shared.startMonitoring()

            // Update app state after successful login
            // Apple Sign In through the app is always a patient (therapists use separate portal)
            await MainActor.run {
                HapticFeedback.formSubmission(success: true)
                appState.userRole = supabase.userRole ?? .patient
                appState.userId = supabase.userId
                appState.isAuthenticated = true
                isLoading = false
            }
        } catch {
            await MainActor.run {
                HapticFeedback.formSubmission(success: false)
                let errorString = String(describing: error)
                if errorString.contains("canceled") || errorString.contains("cancelled") {
                    // User cancelled — no error message needed
                    errorMessage = nil
                } else if errorString.contains("network") || errorString.contains("connection") {
                    errorMessage = "Unable to sign in. Please check your internet connection and try again."
                } else {
                    errorMessage = "Apple Sign In failed. Please try again."
                }
                isLoading = false
            }
        }
    }

    // MARK: - Demo Login Functions

    /// Login as demo patient (John Brebbia) - bypasses auth for testing
    private func loginAsDemoPatient() {
        // Demo patient UUID from seed data
        let demoPatientId = "00000000-0000-0000-0000-000000000001"

        // Set both appState AND supabase client (view models read from supabase)
        appState.userId = demoPatientId
        appState.userRole = .patient
        appState.isAuthenticated = true

        supabase.userId = demoPatientId
        supabase.userRole = .patient

        // Start session monitoring
        SessionManager.shared.startMonitoring()

        DebugLogger.shared.info("Demo", "Logged in as demo patient: John Brebbia (\(demoPatientId))")
    }

    /// Login as demo therapist (Sarah Thompson) - bypasses auth for testing
    private func loginAsDemoTherapist() {
        // Demo therapist UUID from seed data
        let demoTherapistId = "00000000-0000-0000-0000-000000000100"

        // Set both appState AND supabase client (view models read from supabase)
        appState.userId = demoTherapistId
        appState.userRole = .therapist
        appState.isAuthenticated = true

        supabase.userId = demoTherapistId
        supabase.userRole = .therapist

        // Start session monitoring
        SessionManager.shared.startMonitoring()

        DebugLogger.shared.info("Demo", "Logged in as demo therapist: Sarah Thompson (\(demoTherapistId))")
    }
}

#Preview {
    AuthLandingView()
        .environmentObject(AppState())
}
