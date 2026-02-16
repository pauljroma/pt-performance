import SwiftUI

/// ACP-1035: Manages the onboarding flow state and persistence
/// Supports: full onboarding, quick start (skip setup), and tutorial replay
@MainActor
final class OnboardingCoordinator: ObservableObject {
    static let shared = OnboardingCoordinator()

    // UserDefaults keys
    private let hasSeenOnboardingKey = "hasSeenOnboarding"
    private let quickStartedKey = "onboarding_quickStarted"
    private let deferredSetupPendingKey = "onboarding_deferredSetupPending"

    /// Whether the user has seen the onboarding flow
    @Published var hasSeenOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasSeenOnboarding, forKey: hasSeenOnboardingKey)
            ErrorLogger.shared.logUserAction(
                action: "onboarding_status_changed",
                properties: ["has_seen": hasSeenOnboarding]
            )
        }
    }

    /// Whether to show the onboarding view
    @Published var shouldShowOnboarding: Bool = false

    /// ACP-1035: Whether the user chose "Quick Start" (skipped setup)
    /// Used to show gentle nudges to complete setup later
    @Published var quickStarted: Bool {
        didSet {
            UserDefaults.standard.set(quickStarted, forKey: quickStartedKey)
        }
    }

    /// ACP-1035: Whether there is deferred setup still pending
    /// (readiness check-in, therapist link, etc.)
    @Published var deferredSetupPending: Bool {
        didSet {
            UserDefaults.standard.set(deferredSetupPending, forKey: deferredSetupPendingKey)
        }
    }

    private init() {
        // Load saved state from UserDefaults
        self.hasSeenOnboarding = UserDefaults.standard.bool(forKey: hasSeenOnboardingKey)
        self.quickStarted = UserDefaults.standard.bool(forKey: quickStartedKey)
        self.deferredSetupPending = UserDefaults.standard.bool(forKey: deferredSetupPendingKey)

        // On first launch, show onboarding
        if !hasSeenOnboarding {
            self.shouldShowOnboarding = true
            ErrorLogger.shared.logUserAction(
                action: "first_launch_detected",
                properties: [:]
            )
            // ACP-967: Record onboarding funnel start
            OnboardingFunnelTracker.shared.recordStep(.onboardingStarted)
        }
    }

    /// Mark onboarding as completed — user will proceed to Quick Setup
    func completeOnboarding() {
        hasSeenOnboarding = true
        shouldShowOnboarding = false
        deferredSetupPending = true

        // ACP-967: Record profile setup started in onboarding funnel
        OnboardingFunnelTracker.shared.recordStep(.profileSetupStarted)

        ErrorLogger.shared.logUserAction(
            action: "onboarding_completed",
            properties: [:]
        )
    }

    /// ACP-1035: Quick start — skip all setup, jump straight into the app
    /// Marks onboarding as seen, skips Quick Setup, sets flag for later nudge
    func quickStartOnboarding() {
        hasSeenOnboarding = true
        shouldShowOnboarding = false
        quickStarted = true
        deferredSetupPending = true

        // Also mark QuickSetup as "completed" so it doesn't block app entry
        UserDefaults.standard.set(true, forKey: "hasCompletedQuickSetup")

        // ACP-967: Record quick start in onboarding funnel
        OnboardingFunnelTracker.shared.recordStep(.quickStartTapped)

        ErrorLogger.shared.logUserAction(
            action: "onboarding_quick_start",
            properties: [:]
        )
    }

    /// Skip onboarding without marking it as completed
    func skipOnboarding() {
        hasSeenOnboarding = true
        shouldShowOnboarding = false

        ErrorLogger.shared.logUserAction(
            action: "onboarding_skipped",
            properties: [:]
        )
    }

    /// Reset onboarding to show it again (for tutorial replay)
    func resetOnboarding() {
        hasSeenOnboarding = false
        shouldShowOnboarding = true

        ErrorLogger.shared.logUserAction(
            action: "onboarding_reset",
            properties: ["reason": "tutorial_replay"]
        )
    }

    /// ACP-1035: Mark deferred setup as completed (user finished setup later)
    func completeDeferredSetup() {
        deferredSetupPending = false
        quickStarted = false

        // ACP-967: Record profile setup completed in onboarding funnel
        OnboardingFunnelTracker.shared.recordStep(.profileSetupCompleted)

        ErrorLogger.shared.logUserAction(
            action: "deferred_setup_completed",
            properties: [:]
        )
    }

    /// Check if this is the first launch
    var isFirstLaunch: Bool {
        return !hasSeenOnboarding
    }
}
