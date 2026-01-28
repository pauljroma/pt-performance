import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var onboardingCoordinator = OnboardingCoordinator.shared
    @AppStorage("hasAcceptedPrivacyNotice") private var hasAcceptedPrivacyNotice = false
    @State private var showPrivacyNotice = false
    @State private var isCheckingSession = true

    var body: some View {
        Group {
            if isCheckingSession {
                // Show loading while restoring session
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
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

    /// Restore existing Supabase session on app launch
    private func restoreSession() async {
        let supabase = PTSupabaseClient.shared

        do {
            let session = try await supabase.client.auth.session

            // Session exists — restore auth state
            await MainActor.run {
                supabase.currentSession = session
                supabase.currentUser = session.user
            }

            await supabase.fetchUserRole(userId: session.user.id.uuidString)

            await MainActor.run {
                appState.userId = supabase.userId
                appState.userRole = supabase.userRole ?? .patient
                appState.isAuthenticated = true
                isCheckingSession = false
            }

            // Start session monitoring for restored sessions
            SessionManager.shared.startMonitoring()
        } catch {
            // No valid session — show login screen
            print("No existing session: \(error.localizedDescription)")
            await MainActor.run {
                isCheckingSession = false
            }
        }
    }
}
