import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    // ACP-999: Deep Link Attribution — observe pending destinations
    @EnvironmentObject var deepLinkService: DeepLinkService
    // ACP-998: ASO — observe review prompt state
    @EnvironmentObject var asoService: ASOService
    @StateObject private var onboardingCoordinator = OnboardingCoordinator.shared
    @StateObject private var modeService = ModeService.shared
    @StateObject private var badgeManager = TabBarBadgeManager.shared
    @StateObject private var consentManager = ConsentManager.shared
    @StateObject private var sessionManager = SessionManager.shared
    // ACP-1005: Re-engagement campaign service
    @StateObject private var reEngagementService = ReEngagementService.shared
    @AppStorage("hasAcceptedPrivacyNotice") private var hasAcceptedPrivacyNotice = false
    @AppStorage("hasCompletedQuickSetup") private var hasCompletedQuickSetup = false
    @State private var showPrivacyNotice = false
    @State private var showQuickSetup = false
    @State private var isCheckingSession = true
    // ACP-998: State for inline review prompt sheet
    @State private var showReviewPrompt = false

    // MARK: - Presentation Priority Gating
    // Priority order (highest first): consent > onboarding > quickSetup > welcomeBack > reviewPrompt
    // Only one presentation may be active at a time. Higher-priority presentations suppress lower ones.
    // Consent sheet must always win (HIPAA requirement).

    /// True when the consent sheet wants to present (highest priority — ungated).
    private var isConsentActive: Bool {
        consentManager.showConsentUpdateSheet
    }

    /// True when onboarding wants to present AND no higher-priority presentation is active.
    private var isOnboardingActive: Bool {
        onboardingCoordinator.shouldShowOnboarding && !isConsentActive
    }

    /// True when quick setup wants to present AND no higher-priority presentation is active.
    private var isQuickSetupActive: Bool {
        showQuickSetup && !isConsentActive && !onboardingCoordinator.shouldShowOnboarding
    }

    /// True when welcome-back wants to present AND no higher-priority presentation is active.
    private var isWelcomeBackActive: Bool {
        reEngagementService.showWelcomeBack
            && !isConsentActive
            && !onboardingCoordinator.shouldShowOnboarding
            && !showQuickSetup
    }

    /// True when review prompt wants to present AND no higher-priority presentation is active.
    private var isReviewPromptActive: Bool {
        showReviewPrompt
            && !isConsentActive
            && !onboardingCoordinator.shouldShowOnboarding
            && !showQuickSetup
            && !reEngagementService.showWelcomeBack
    }

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
                    .accessibilityLabel("Restoring session, please wait")
                    .transition(.opacity)
            } else if !appState.isAuthenticated {
                AuthLandingView()
                    .transition(.opacity.animation(.easeInOut(duration: AnimationDuration.standard)))
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
                    VStack(spacing: Spacing.md) {
                        ProgressView()
                        Text("Setting up your account...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Setting up your account, please wait")
                }
            }
        }
        .animation(.easeInOut(duration: AnimationDuration.standard), value: isCheckingSession)
        .animation(.easeInOut(duration: AnimationDuration.standard), value: appState.isAuthenticated)
        .environmentObject(modeService)
        .environmentObject(onboardingCoordinator)
        .environmentObject(badgeManager)
        // ACP-1049: Re-consent prompt when consent version changes
        // Priority 1 (highest) — HIPAA requirement: consent always wins, ungated.
        .sheet(isPresented: Binding(
            get: { isConsentActive },
            set: { consentManager.showConsentUpdateSheet = $0 }
        )) {
            ConsentUpdateSheet()
        }
        // Priority 2: Onboarding — gated by consent not being active.
        .fullScreenCover(isPresented: Binding(
            get: { isOnboardingActive },
            set: { onboardingCoordinator.shouldShowOnboarding = $0 }
        )) {
            OnboardingView()
        }
        // Priority 3: Quick setup — gated by consent and onboarding.
        .fullScreenCover(isPresented: Binding(
            get: { isQuickSetupActive },
            set: { showQuickSetup = $0 }
        )) {
            QuickSetupView()
        }
        // ACP-1005: Re-engagement welcome-back screen for returning inactive users
        // Priority 4: Welcome back — gated by consent, onboarding, and quick setup.
        .fullScreenCover(isPresented: Binding(
            get: { isWelcomeBackActive },
            set: { reEngagementService.showWelcomeBack = $0 }
        )) {
            WelcomeBackView(
                onStartWorkout: {
                    appState.pendingDeepLink = .startWorkout
                },
                onDismiss: nil
            )
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

            // ACP-999: Process queued deep links after authentication completes
            if isAuthenticated {
                deepLinkService.processQueuedDeepLink()

                // Sync DeepLinkService pending destination to appState
                if let destination = deepLinkService.pendingDestination {
                    appState.pendingDeepLink = destination
                    deepLinkService.clearPendingDestination()
                }
            }
        }
        // ACP-999: Observe DeepLinkService destinations and route to appState
        .onChange(of: deepLinkService.pendingDestination) { _, newDestination in
            guard let destination = newDestination else { return }

            if appState.isAuthenticated {
                appState.pendingDeepLink = destination
                deepLinkService.clearPendingDestination()
                DebugLogger.shared.info("[RootView] Routed deep link to: \(String(describing: destination))")
            } else {
                // User is not authenticated — destination stays queued in DeepLinkService
                DebugLogger.shared.info("[RootView] Deep link pending auth: \(String(describing: destination))")
            }
        }
        // ACP-998: Show inline review prompt when ASO service triggers it
        .onChange(of: asoService.shouldShowReviewPrompt) { _, shouldShow in
            if shouldShow && appState.isAuthenticated {
                showReviewPrompt = true
            }
        }
        // ACP-998: Priority 5 (lowest): Review prompt — gated by all higher-priority presentations.
        .sheet(isPresented: Binding(
            get: { isReviewPromptActive },
            set: { showReviewPrompt = $0 }
        )) {
            AppStoreReviewPromptView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: sessionManager.shouldLogout) { _, shouldLogout in
            guard shouldLogout else { return }
            // Session expired or was force-terminated — navigate to login
            // Clear both appState AND supabase client to keep them in sync
            appState.isAuthenticated = false
            appState.userId = nil
            appState.userRole = nil
            PTSupabaseClient.shared.currentSession = nil
            PTSupabaseClient.shared.currentUser = nil
            PTSupabaseClient.shared.userRole = nil
            PTSupabaseClient.shared.userId = nil
            sessionManager.resetSession()
        }
        // MARK: - Presentation Priority Enforcement
        // When a higher-priority presentation activates, dismiss all lower-priority ones
        // so they can re-present cleanly once the higher-priority flow completes.
        .onChange(of: consentManager.showConsentUpdateSheet) { _, needsConsent in
            guard needsConsent else { return }
            // Consent (P1) activated — dismiss everything below it
            if onboardingCoordinator.shouldShowOnboarding {
                onboardingCoordinator.shouldShowOnboarding = false
            }
            if showQuickSetup {
                showQuickSetup = false
            }
            if reEngagementService.showWelcomeBack {
                reEngagementService.showWelcomeBack = false
            }
            if showReviewPrompt {
                showReviewPrompt = false
            }
        }
        .onChange(of: onboardingCoordinator.shouldShowOnboarding) { _, needsOnboarding in
            guard needsOnboarding else { return }
            // Onboarding (P2) activated — dismiss P3–P5
            if showQuickSetup {
                showQuickSetup = false
            }
            if reEngagementService.showWelcomeBack {
                reEngagementService.showWelcomeBack = false
            }
            if showReviewPrompt {
                showReviewPrompt = false
            }
        }
        .onChange(of: showQuickSetup) { _, needsQuickSetup in
            guard needsQuickSetup else { return }
            // Quick setup (P3) activated — dismiss P4–P5
            if reEngagementService.showWelcomeBack {
                reEngagementService.showWelcomeBack = false
            }
            if showReviewPrompt {
                showReviewPrompt = false
            }
        }
        .onChange(of: reEngagementService.showWelcomeBack) { _, needsWelcomeBack in
            guard needsWelcomeBack else { return }
            // Welcome back (P4) activated — dismiss P5
            if showReviewPrompt {
                showReviewPrompt = false
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
