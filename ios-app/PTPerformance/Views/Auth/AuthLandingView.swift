// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  AuthLandingView.swift
//  PTPerformance
//
//  Auth landing: atmospheric background, strong brand, premium card depth
//

import SwiftUI

struct AuthLandingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var supabase = PTSupabaseClient.shared

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showEmailSignIn = false
    @State private var showRegistration = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0

    #if DEBUG
    @State private var showTestUserPicker = false
    #endif

    var body: some View {
        NavigationStack {
            ZStack {
                // Atmospheric teal-tinted background
                Color.modusAtmosphere
                    .ignoresSafeArea()

                // Radial glow behind logo area
                RadialGradient(
                    colors: [
                        Color.modusTealAccent.opacity(0.1),
                        Color.clear
                    ],
                    center: .init(x: 0.5, y: 0.22),
                    startRadius: 20,
                    endRadius: 260
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // MARK: - Hero Branding
                    VStack(spacing: Spacing.sm) {
                        ZStack {
                            // Outer glow
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.modusTealAccent.opacity(0.18), Color.clear],
                                        center: .center,
                                        startRadius: 40,
                                        endRadius: 80
                                    )
                                )
                                .frame(width: 140, height: 140)

                            // Icon circle with depth shadow
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.modusCyan, .modusTealAccent],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 96, height: 96)
                                .shadow(color: .modusTealAccent.opacity(0.3), radius: 20, y: 6)

                            Image(systemName: "figure.run")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                        .accessibilityHidden(true)

                        Text("Modus")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundColor(.modusDeepTeal)
                            .opacity(logoOpacity)

                        Text("Train smarter. Recover faster.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.modusMuted)
                            .opacity(logoOpacity)
                    }
                    .padding(.bottom, Spacing.xxl)

                    Spacer()

                    // MARK: - Auth Buttons
                    VStack(spacing: Spacing.sm) {
                        // Apple Sign-In — primary
                        Button(action: {
                            HapticFeedback.light()
                            Task { await signInWithApple() }
                        }) {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 18, weight: .medium))
                                Text("Sign in with Apple")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color(.label))
                            .foregroundColor(Color(.systemBackground))
                            .cornerRadius(CornerRadius.lg)
                        }
                        .disabled(isLoading)
                        .accessibilityIdentifier("signInWithAppleButton")
                        .accessibilityLabel("Sign in with Apple")
                        .accessibilityHint("Use your Apple ID to sign in")

                        // Email — secondary teal
                        Button(action: {
                            HapticFeedback.light()
                            showEmailSignIn = true
                        }) {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Continue with Email")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.modusCyan)
                            .foregroundColor(.white)
                            .cornerRadius(CornerRadius.lg)
                            .shadow(color: .modusCyan.opacity(0.25), radius: 8, y: 3)
                        }
                        .disabled(isLoading)
                        .accessibilityIdentifier("continueWithEmailButton")
                        .accessibilityLabel("Continue with Email")
                        .accessibilityHint("Sign in using your email and password")

                        // Create Account — tertiary text-only
                        Button(action: {
                            HapticFeedback.light()
                            showRegistration = true
                        }) {
                            Text("Create Account")
                                .font(.system(size: 16, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .foregroundColor(.modusCyan)
                        }
                        .disabled(isLoading)
                        .accessibilityIdentifier("createAccountButton")
                        .accessibilityLabel("Create Account")
                        .accessibilityHint("Register a new account")
                    }
                    .padding(.horizontal, Spacing.xxs)

                    // MARK: - Loading / Error
                    if isLoading {
                        ProgressView()
                            .tint(.modusCyan)
                            .padding(.top, Spacing.md)
                            .accessibilityLabel("Signing in, please wait")
                    }

                    if let errorMessage = errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(DesignTokens.statusError)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(DesignTokens.statusError)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, Spacing.sm)
                        .padding(.horizontal)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Error: \(errorMessage)")
                    }

                    Spacer()
                        .frame(height: Spacing.lg)

                    #if DEBUG
                    // MARK: - Demo Section
                    VStack(spacing: Spacing.xs) {
                        Rectangle()
                            .fill(Color(.separator).opacity(0.3))
                            .frame(height: 0.5)
                            .padding(.horizontal, Spacing.xl)

                        Text("Demo Accounts")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.modusMuted)
                            .padding(.top, Spacing.xxs)

                        HStack(spacing: Spacing.sm) {
                            Button(action: {
                                HapticFeedback.light()
                                loginAsDemoPatient()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "person.fill")
                                        .font(.caption)
                                    Text("Patient")
                                        .font(.caption.weight(.semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.xs)
                                .background(Color.modusTealAccent.opacity(0.1))
                                .foregroundColor(.modusTealAccent)
                                .cornerRadius(CornerRadius.sm)
                            }
                            .accessibilityLabel("Demo Patient")
                            .accessibilityHint("Sign in as a demo patient user for testing")

                            Button(action: {
                                HapticFeedback.light()
                                loginAsDemoTherapist()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "stethoscope")
                                        .font(.caption)
                                    Text("Therapist")
                                        .font(.caption.weight(.semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.xs)
                                .background(Color.modusCyan.opacity(0.1))
                                .foregroundColor(.modusCyan)
                                .cornerRadius(CornerRadius.sm)
                            }
                            .accessibilityLabel("Demo Therapist")
                            .accessibilityHint("Sign in as a demo therapist user for testing")
                        }

                        Button(action: {
                            HapticFeedback.light()
                            showTestUserPicker = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "person.3.fill")
                                    .font(.caption)
                                Text("10 Test Users")
                                    .font(.caption.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.xs)
                            .background(Color.modusDeepTeal.opacity(0.08))
                            .foregroundColor(.modusDeepTeal)
                            .cornerRadius(CornerRadius.sm)
                        }
                        .accessibilityLabel("Test Users")
                        .accessibilityHint("Browse and log in as any of 10 test user personas")
                        .sheet(isPresented: $showTestUserPicker) {
                            TestUserPickerView()
                                .environmentObject(appState)
                        }
                    }
                    #endif

                    // MARK: - Footer
                    (Text("By continuing, you agree to our ")
                        .foregroundColor(.modusMuted)
                    + Text("[Terms of Service](https://getmodus.app/terms)")
                        .foregroundColor(.modusCyan)
                    + Text(" and ")
                        .foregroundColor(.modusMuted)
                    + Text("[Privacy Policy](https://getmodus.app/privacy)")
                        .foregroundColor(.modusCyan)
                    + Text(".")
                        .foregroundColor(.modusMuted))
                        .font(.system(size: 11))
                        .multilineTextAlignment(.center)
                        .tint(.modusCyan)
                        .environment(\.openURL, OpenURLAction { url in
                            UIApplication.shared.open(url)
                            return .handled
                        })
                        .padding(.horizontal, Spacing.xl)
                        .padding(.top, Spacing.md)
                        .padding(.bottom, Spacing.md)
                }
                .padding(.horizontal, Spacing.lg)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                    logoScale = 1.0
                    logoOpacity = 1.0
                }
            }
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
            SessionManager.shared.startMonitoring()

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

    #if DEBUG
    private func loginAsDemoPatient() {
        let demoPatientId = "00000000-0000-0000-0000-000000000001"
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await supabase.signInAsDemoUser(demoUserId: demoPatientId, role: .patient)

                await MainActor.run {
                    appState.userId = supabase.userId
                    appState.userRole = .patient
                    appState.isAuthenticated = true
                    isLoading = false
                    SessionManager.shared.startMonitoring()
                    HapticFeedback.success()
                }

                DebugLogger.shared.info("Demo", "Logged in as demo patient via Supabase Auth (\(demoPatientId))")
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Demo login failed: \(error.localizedDescription)"
                    HapticFeedback.formSubmission(success: false)
                }
                DebugLogger.shared.error("Demo", "Demo patient login failed: \(error)")
            }
        }
    }

    private func loginAsDemoTherapist() {
        let demoTherapistId = "00000000-0000-0000-0000-000000000100"
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await supabase.signInAsDemoUser(demoUserId: demoTherapistId, role: .therapist)

                await MainActor.run {
                    appState.userId = supabase.userId
                    appState.userRole = .therapist
                    appState.isAuthenticated = true
                    isLoading = false
                    SessionManager.shared.startMonitoring()
                    HapticFeedback.success()
                }

                DebugLogger.shared.info("Demo", "Logged in as demo therapist via Supabase Auth (\(demoTherapistId))")
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Demo login failed: \(error.localizedDescription)"
                    HapticFeedback.formSubmission(success: false)
                }
                DebugLogger.shared.error("Demo", "Demo therapist login failed: \(error)")
            }
        }
    }
    #endif
}

#Preview {
    AuthLandingView()
        .environmentObject(AppState())
}
