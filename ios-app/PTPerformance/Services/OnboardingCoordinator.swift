import SwiftUI

/// Manages the onboarding flow state and persistence
@MainActor
final class OnboardingCoordinator: ObservableObject {
    static let shared = OnboardingCoordinator()

    // UserDefaults key for onboarding status
    private let hasSeenOnboardingKey = "hasSeenOnboarding"

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

    private init() {
        // Load saved onboarding status from UserDefaults
        self.hasSeenOnboarding = UserDefaults.standard.bool(forKey: hasSeenOnboardingKey)

        // On first launch, show onboarding
        if !hasSeenOnboarding {
            self.shouldShowOnboarding = true
            ErrorLogger.shared.logUserAction(
                action: "first_launch_detected",
                properties: [:]
            )
        }
    }

    /// Mark onboarding as completed
    func completeOnboarding() {
        hasSeenOnboarding = true
        shouldShowOnboarding = false

        ErrorLogger.shared.logUserAction(
            action: "onboarding_completed",
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

    /// Check if this is the first launch
    var isFirstLaunch: Bool {
        return !hasSeenOnboarding
    }
}
