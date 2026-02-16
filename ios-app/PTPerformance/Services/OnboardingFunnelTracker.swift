// ACP-967: Onboarding Funnel Analytics
// Tracks every onboarding step with funnel analytics, measures drop-off, and time to first value.

import SwiftUI
import os.log

/// Dedicated onboarding funnel analytics service.
///
/// Tracks each step of the onboarding funnel, persists timestamps across app restarts,
/// and provides metrics like drop-off step and time-to-first-value.
@MainActor
final class OnboardingFunnelTracker: ObservableObject {

    // MARK: - Singleton

    static let shared = OnboardingFunnelTracker()

    // MARK: - Funnel Step Definition

    /// Each step in the onboarding funnel, ordered by expected progression.
    enum FunnelStep: Int, CaseIterable, Comparable {
        case appInstalled = 0
        case onboardingStarted
        case onboardingPage1Viewed
        case onboardingPage2Viewed
        case onboardingPage3Viewed
        case quickStartTapped
        case signupStarted
        case signupCompleted
        case profileSetupStarted
        case profileSetupCompleted
        case firstWorkoutStarted
        case firstWorkoutCompleted
        case subscriptionPromptViewed
        case subscriptionStarted

        /// Snake-case event name for analytics logging
        var name: String {
            switch self {
            case .appInstalled:              return "app_installed"
            case .onboardingStarted:         return "onboarding_started"
            case .onboardingPage1Viewed:      return "onboarding_page1_viewed"
            case .onboardingPage2Viewed:      return "onboarding_page2_viewed"
            case .onboardingPage3Viewed:      return "onboarding_page3_viewed"
            case .quickStartTapped:          return "quick_start_tapped"
            case .signupStarted:             return "signup_started"
            case .signupCompleted:           return "signup_completed"
            case .profileSetupStarted:       return "profile_setup_started"
            case .profileSetupCompleted:     return "profile_setup_completed"
            case .firstWorkoutStarted:       return "first_workout_started"
            case .firstWorkoutCompleted:     return "first_workout_completed"
            case .subscriptionPromptViewed:  return "subscription_prompt_viewed"
            case .subscriptionStarted:       return "subscription_started"
            }
        }

        /// Human-readable display name
        var displayName: String {
            switch self {
            case .appInstalled:              return "App Installed"
            case .onboardingStarted:         return "Onboarding Started"
            case .onboardingPage1Viewed:      return "Onboarding Page 1 Viewed"
            case .onboardingPage2Viewed:      return "Onboarding Page 2 Viewed"
            case .onboardingPage3Viewed:      return "Onboarding Page 3 Viewed"
            case .quickStartTapped:          return "Quick Start Tapped"
            case .signupStarted:             return "Signup Started"
            case .signupCompleted:           return "Signup Completed"
            case .profileSetupStarted:       return "Profile Setup Started"
            case .profileSetupCompleted:     return "Profile Setup Completed"
            case .firstWorkoutStarted:       return "First Workout Started"
            case .firstWorkoutCompleted:     return "First Workout Completed"
            case .subscriptionPromptViewed:  return "Subscription Prompt Viewed"
            case .subscriptionStarted:       return "Subscription Started"
            }
        }

        static func < (lhs: FunnelStep, rhs: FunnelStep) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.getmodus.app", category: "OnboardingFunnel")

    /// UserDefaults key prefix for persisted step timestamps
    private let timestampKeyPrefix = "onboarding_funnel_step_timestamp_"
    private let funnelStartTimeKey = "onboarding_funnel_start_time"

    /// The set of funnel steps that have been reached
    @Published var completedSteps: Set<FunnelStep> = []

    /// When the funnel began (app install / first launch)
    var funnelStartTime: Date? {
        get {
            guard let interval = UserDefaults.standard.object(forKey: funnelStartTimeKey) as? TimeInterval else {
                return nil
            }
            return Date(timeIntervalSince1970: interval)
        }
        set {
            if let date = newValue {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: funnelStartTimeKey)
            } else {
                UserDefaults.standard.removeObject(forKey: funnelStartTimeKey)
            }
        }
    }

    /// In-memory cache of step timestamps (also persisted to UserDefaults)
    private var stepTimestamps: [FunnelStep: Date] = [:]

    // MARK: - Initialization

    private init() {
        restorePersistedState()
        ensureFunnelStarted()
        logger.info("OnboardingFunnelTracker initialized with \(self.completedSteps.count) completed steps")
    }

    // MARK: - Public API

    /// Records a funnel step with a timestamp.
    ///
    /// If the step has already been recorded, this is a no-op (steps are only recorded once).
    /// The step timestamp is persisted to UserDefaults and an analytics event is fired.
    ///
    /// - Parameter step: The funnel step to record
    func recordStep(_ step: FunnelStep) {
        guard !completedSteps.contains(step) else {
            logger.debug("Step \(step.name) already recorded, skipping")
            return
        }

        let now = Date()
        completedSteps.insert(step)
        stepTimestamps[step] = now
        persistTimestamp(now, for: step)

        let timeSinceStart = timeToStep(step)

        var properties: [String: Any] = [
            "funnel_step": step.name,
            "funnel_step_ordinal": step.rawValue,
            "funnel_step_display_name": step.displayName
        ]

        if let elapsed = timeSinceStart {
            properties["time_since_funnel_start_seconds"] = Int(elapsed)
        }

        if let previousStep = previousCompletedStep(before: step),
           let previousTime = stepTimestamps[previousStep] {
            let delta = now.timeIntervalSince(previousTime)
            properties["time_since_previous_step_seconds"] = Int(delta)
            properties["previous_step"] = previousStep.name
        }

        AnalyticsTracker.shared.track(event: "onboarding_funnel_\(step.name)", properties: properties)

        logger.info("Funnel step recorded: \(step.displayName) (ordinal \(step.rawValue))")
    }

    /// Returns elapsed time from funnel start to the given step, if both timestamps exist.
    ///
    /// - Parameter step: The funnel step to measure
    /// - Returns: Time interval from funnel start to the step, or nil if data is unavailable
    func timeToStep(_ step: FunnelStep) -> TimeInterval? {
        guard let start = funnelStartTime,
              let stepTime = stepTimestamps[step] else {
            return nil
        }
        return stepTime.timeIntervalSince(start)
    }

    /// Time from install to first workout completed.
    ///
    /// This is the key "time to first value" metric — how long it takes a new user
    /// to complete their first workout after installing the app.
    var timeToFirstValue: TimeInterval? {
        return timeToStep(.firstWorkoutCompleted)
    }

    /// The last (highest ordinal) step the user has reached.
    ///
    /// Useful for identifying where users drop off in the funnel.
    var currentDropOffStep: FunnelStep? {
        return completedSteps.max()
    }

    /// Generates a markdown-formatted funnel report.
    ///
    /// Shows each step, its timestamp, and time deltas (from funnel start and from
    /// the previous step). Useful for debugging and diagnostics.
    ///
    /// - Returns: A markdown-formatted string with the funnel report
    func getFunnelReport() -> String {
        var report = "# Onboarding Funnel Report\n\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium

        if let startTime = funnelStartTime {
            report += "**Funnel Start:** \(dateFormatter.string(from: startTime))\n\n"
        } else {
            report += "**Funnel Start:** Not recorded\n\n"
        }

        report += "| Step | Status | Timestamp | Time from Start | Time from Previous |\n"
        report += "|------|--------|-----------|-----------------|--------------------|\n"

        var previousStepTime: Date? = funnelStartTime

        for step in FunnelStep.allCases {
            let status = completedSteps.contains(step) ? "Done" : "---"
            let timestamp: String
            let timeFromStart: String
            let timeFromPrevious: String

            if let stepTime = stepTimestamps[step] {
                timestamp = dateFormatter.string(from: stepTime)

                if let elapsed = timeToStep(step) {
                    timeFromStart = formatDuration(elapsed)
                } else {
                    timeFromStart = "---"
                }

                if let prev = previousStepTime {
                    let delta = stepTime.timeIntervalSince(prev)
                    timeFromPrevious = formatDuration(delta)
                } else {
                    timeFromPrevious = "---"
                }

                previousStepTime = stepTime
            } else {
                timestamp = "---"
                timeFromStart = "---"
                timeFromPrevious = "---"
            }

            report += "| \(step.displayName) | \(status) | \(timestamp) | \(timeFromStart) | \(timeFromPrevious) |\n"
        }

        report += "\n"

        if let dropOff = currentDropOffStep {
            report += "**Current Drop-Off:** \(dropOff.displayName) (step \(dropOff.rawValue))\n"
        }

        if let ttfv = timeToFirstValue {
            report += "**Time to First Value:** \(formatDuration(ttfv))\n"
        } else {
            report += "**Time to First Value:** Not yet reached\n"
        }

        return report
    }

    // MARK: - Private Helpers

    /// Ensures the funnel start time is set on first launch.
    private func ensureFunnelStarted() {
        if funnelStartTime == nil {
            funnelStartTime = Date()
            recordStep(.appInstalled)
        }
    }

    /// Persists a step timestamp to UserDefaults.
    private func persistTimestamp(_ date: Date, for step: FunnelStep) {
        let key = timestampKeyPrefix + "\(step.rawValue)"
        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: key)
    }

    /// Restores all persisted step timestamps from UserDefaults.
    private func restorePersistedState() {
        for step in FunnelStep.allCases {
            let key = timestampKeyPrefix + "\(step.rawValue)"
            if let interval = UserDefaults.standard.object(forKey: key) as? TimeInterval {
                let date = Date(timeIntervalSince1970: interval)
                stepTimestamps[step] = date
                completedSteps.insert(step)
            }
        }
    }

    /// Finds the most recent completed step before the given step (by ordinal).
    private func previousCompletedStep(before step: FunnelStep) -> FunnelStep? {
        return completedSteps
            .filter { $0.rawValue < step.rawValue }
            .max()
    }

    /// Formats a time interval as a human-readable duration string.
    private func formatDuration(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        if totalSeconds < 60 {
            return "\(totalSeconds)s"
        } else if totalSeconds < 3600 {
            let minutes = totalSeconds / 60
            let seconds = totalSeconds % 60
            return "\(minutes)m \(seconds)s"
        } else {
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            return "\(hours)h \(minutes)m"
        }
    }
}
