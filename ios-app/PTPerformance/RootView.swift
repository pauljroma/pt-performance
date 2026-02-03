import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var onboardingCoordinator = OnboardingCoordinator.shared
    @ObservedObject private var modeService = ModeService.shared
    @AppStorage("hasAcceptedPrivacyNotice") private var hasAcceptedPrivacyNotice = false
    @State private var showPrivacyNotice = false
    @State private var isCheckingSession = true

    var body: some View {
        Group {
            if isCheckingSession {
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
                    })
                } else if appState.userRole == .patient {
                    PatientTabView()
                        .withModeTheme()  // ACP-479: Apply mode-specific theming
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
        .task {
            await restoreSession()
        }
        .onAppear {
            // Check if we should show onboarding on first launch
            if onboardingCoordinator.isFirstLaunch && appState.isAuthenticated {
                onboardingCoordinator.shouldShowOnboarding = true
            }
        }
    }

    /// ACP-932: Restore existing Supabase session on app launch
    /// Optimized to minimize time to first meaningful paint
    private func restoreSession() async {
        let supabase = PTSupabaseClient.shared

        do {
            let session = try await supabase.client.auth.session

            // Session exists — restore auth state immediately
            await MainActor.run {
                supabase.currentSession = session
                supabase.currentUser = session.user
            }

            // ACP-932: Fetch role and update UI state in parallel where possible
            async let roleTask: () = supabase.fetchUserRole(userId: session.user.id.uuidString)
            await roleTask

            // Update UI state as soon as role is known
            await MainActor.run {
                appState.userId = supabase.userId
                appState.userRole = supabase.userRole ?? .patient
                appState.isAuthenticated = true
                isCheckingSession = false
            }

            // ACP-932/945: Defer non-critical work to after UI is displayed
            // These operations don't affect the initial UI render
            Task.detached(priority: .utility) {
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
            #if DEBUG
            print("No existing session: \(error.localizedDescription)")
            #endif
            await MainActor.run {
                isCheckingSession = false
            }
        }
    }
}
