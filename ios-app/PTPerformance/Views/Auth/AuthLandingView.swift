//
//  AuthLandingView.swift
//  PTPerformance
//
//  Auth redesign: Landing screen with Apple Sign In, Email Sign In, and Registration
//

import SwiftUI

struct AuthLandingView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var supabase = PTSupabaseClient.shared

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showEmailSignIn = false
    @State private var showRegistration = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // MARK: - App Logo & Branding
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .cyan],
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

                    Text("PT Performance")
                        .font(.largeTitle)
                        .bold()

                    Text("Physical Therapy Progress Tracking")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // MARK: - Authentication Buttons
                VStack(spacing: 16) {
                    // Sign in with Apple
                    Button(action: {
                        Task {
                            await signInWithApple()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "apple.logo")
                                .font(.title3)
                            Text("Sign in with Apple")
                                .font(.body.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.label))
                        .foregroundColor(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)
                    .accessibilityLabel("Sign in with Apple")
                    .accessibilityHint("Use your Apple ID to sign in")

                    // Continue with Email
                    Button(action: {
                        showEmailSignIn = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "envelope.fill")
                                .font(.title3)
                            Text("Continue with Email")
                                .font(.body.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)
                    .accessibilityLabel("Continue with Email")
                    .accessibilityHint("Sign in using your email and password")

                    // Create Account
                    Button(action: {
                        showRegistration = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.badge.plus")
                                .font(.title3)
                            Text("Create Account")
                                .font(.body.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                    }
                    .disabled(isLoading)
                    .accessibilityLabel("Create Account")
                    .accessibilityHint("Register a new account")
                }

                // MARK: - Loading Indicator
                if isLoading {
                    ProgressView("Signing in...")
                        .padding(.top, 8)
                }

                // MARK: - Error Display
                if let errorMessage = errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Error: \(errorMessage)")
                }

                Spacer()

                // MARK: - Footer
                Text("By continuing, you agree to our Terms of Service and Privacy Policy.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 16)
            }
            .padding(.horizontal, 24)
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
                appState.userRole = supabase.userRole ?? .patient
                appState.userId = supabase.userId
                appState.isAuthenticated = true
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

#Preview {
    AuthLandingView()
        .environmentObject(AppState())
}
