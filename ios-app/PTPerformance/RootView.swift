import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var onboardingCoordinator = OnboardingCoordinator.shared
    @StateObject private var modeService = ModeService.shared
    @StateObject private var consentManager = ConsentManager.shared
    @AppStorage("hasAcceptedPrivacyNotice") private var hasAcceptedPrivacyNotice = false
    @AppStorage("hasCompletedQuickSetup") private var hasCompletedQuickSetup = false
    @State private var showPrivacyNotice = false
    @State private var showQuickSetup = false
    @State private var isCheckingSession = true

    var body: some View {
        Group {
            // Password reset flow takes priority - don't show normal UI
            if appState.showSetNewPassword {
                // SetNewPasswordView is shown via fullScreenCover in PTPerformanceApp
                // Show minimal placeholder while cover appears
                Color.clear
            } else if isCheckingSession {
                // ACP-932: Show minimal loading while restoring session
                // Keep this view lightweight to reduce initial render time
                ProgressView()
                    .scaleEffect(1.2)
            } else if !appState.isAuthenticated {
                AuthLandingView()
            } else {
                // Show privacy notice if not accepted (HIPAA requirement)
                if !hasAcceptedPrivacyNotice {
                    PrivacyNoticeView(onAccept: {
                        hasAcceptedPrivacyNotice = true
                        showPrivacyNotice = false
                        // Trigger Quick Setup after privacy notice
                        if !hasCompletedQuickSetup {
                            showQuickSetup = true
                        }
                    })
                } else if appState.userRole == .patient {
                    PatientTabView()
                        .withModeTheme()  // ACP-479: Apply mode-specific theming
                        .onAppear {
                            // Show Quick Setup if not completed
                            if !hasCompletedQuickSetup {
                                showQuickSetup = true
                            }
                        }
                } else if appState.userRole == .therapist {
                    TherapistTabView()
                } else {
                    // Role not yet determined — show loading with timeout
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Setting up your account...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $onboardingCoordinator.shouldShowOnboarding) {
            OnboardingView()
        }
        .fullScreenCover(isPresented: $showQuickSetup) {
            QuickSetupView()
        }
        // ACP-1049: Re-consent prompt when consent version changes
        .sheet(isPresented: $consentManager.showConsentUpdateSheet) {
            ConsentUpdateSheet()
        }
        .task {
            await restoreSession()
        }
        .onAppear {
            // Check if we should show onboarding on first launch
            if onboardingCoordinator.isFirstLaunch && appState.isAuthenticated {
                onboardingCoordinator.shouldShowOnboarding = true
            }
        }
        .onChange(of: appState.isAuthenticated) { _, isAuthenticated in
            // ACP-1049: Check for re-consent when user becomes authenticated
            if isAuthenticated && hasAcceptedPrivacyNotice && consentManager.needsReConsent() {
                consentManager.showConsentUpdateSheet = true
            }
        }
    }

    /// ACP-932: Restore existing Supabase session on app launch
    /// Optimized to minimize time to first meaningful paint
    private func restoreSession() async {
        // Skip normal session restore during password reset flow
        // SetNewPasswordView handles its own authentication
        if appState.showSetNewPassword {
            await MainActor.run {
                isCheckingSession = false
            }
            return
        }

        let supabase = PTSupabaseClient.shared

        do {
            let session = try await supabase.client.auth.session

            // Session exists — restore auth state immediately
            await MainActor.run {
                supabase.currentSession = session
                supabase.currentUser = session.user
            }

            // Check again if password reset started during session fetch
            if appState.showSetNewPassword {
                await MainActor.run {
                    isCheckingSession = false
                }
                return
            }

            // ACP-932: Fetch role and update UI state in parallel where possible
            async let roleTask: () = supabase.fetchUserRole(userId: session.user.id.uuidString)
            await roleTask

            // Final check before updating auth state - password reset takes priority
            if appState.showSetNewPassword {
                await MainActor.run {
                    isCheckingSession = false
                }
                return
            }

            // Update UI state as soon as role is known
            await MainActor.run {
                appState.userId = supabase.userId
                appState.userRole = supabase.userRole ?? .patient
                appState.isAuthenticated = true
                isCheckingSession = false
            }

            // ACP-932/945: Defer non-critical work to after UI is displayed
            // These operations don't affect the initial UI render
            Task(priority: .utility) {
                // ACP-479: Load patient mode after session restore
                if supabase.userRole == .patient {
                    await modeService.loadPatientMode()
                }

                // Start session monitoring for restored sessions
                await MainActor.run {
                    SessionManager.shared.startMonitoring()
                }
            }
        } catch {
            // No valid session — show login screen immediately
            DebugLogger.shared.log("[RootView] No existing session: \(error.localizedDescription)", level: .diagnostic)
            await MainActor.run {
                isCheckingSession = false
            }
        }
    }
}
