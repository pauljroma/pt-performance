//
//  ASOService.swift
//  PTPerformance
//
//  ACP-998: App Store Optimization — Metadata, keywords, review prompt timing
//
//  Manages App Store review prompting with smart timing, tracks ASO-relevant
//  user engagement metrics, and provides SKStoreReviewController integration
//  with a 60-day cooldown.
//

import Foundation
import StoreKit
import SwiftUI

// MARK: - ASO Service

/// Service for App Store Optimization features including smart review prompting
/// and impression tracking.
///
/// ## Smart Review Prompting
/// Reviews are requested at positive moments:
/// - After 3+ app sessions AND a successful workout completion
/// - After an achievement unlock
/// - Never more than once per 60 days
///
/// ## Usage
/// ```swift
/// // Track session start
/// ASOService.shared.trackSessionStart()
///
/// // After workout completion
/// ASOService.shared.trackWorkoutCompleted()
///
/// // Check if review prompt is appropriate
/// if ASOService.shared.shouldShowReviewPrompt {
///     // Show inline review prompt view
/// }
/// ```
@MainActor
class ASOService: ObservableObject {

    // MARK: - Singleton

    static let shared = ASOService()

    // MARK: - Published Properties

    /// Whether the inline review prompt should be shown
    @Published var shouldShowReviewPrompt = false

    /// Current review prompt state for UI binding
    @Published private(set) var reviewState: ReviewPromptState

    // MARK: - Private Properties

    private let logger = DebugLogger.shared
    private let tag = "ASOService"

    /// UserDefaults key for persisting review prompt state
    private let reviewStateKey = "com.getmodus.aso.reviewState"

    /// UserDefaults key for App Store impression tracking
    private let impressionKey = "com.getmodus.aso.impressions"

    /// Current ASO metadata — updated from remote config or hardcoded defaults
    let currentMetadata = ASOMetadata(
        keywords: [
            "physical therapy",
            "PT exercises",
            "workout tracker",
            "rehab",
            "recovery",
            "strength training",
            "arm care",
            "baseball training",
            "shoulder health",
            "exercise plan"
        ],
        subtitle: "Your PT & Training Partner",
        promotionalText: "Personalized rehab and strength programs built by physical therapists. Track workouts, monitor recovery, and train smarter with AI-powered coaching.",
        version: 1,
        updatedAt: Date()
    )

    // MARK: - Initialization

    private init() {
        // Load persisted review state with defensive decoding.
        // Corrupted UserDefaults data can cause EXC_BREAKPOINT traps in the
        // synthesized Codable init, which bypass try? error handling.
        if let data = UserDefaults.standard.data(forKey: reviewStateKey) {
            // Validate JSON structure before attempting Codable decode
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Pre-validate Date fields are numeric (deferredToDate encodes as Double).
                // Non-numeric values (strings, nulls stored as non-nil) cause runtime traps.
                let dateKeys = ["last_prompt_date", "last_system_review_date"]
                let datesValid = dateKeys.allSatisfy { key in
                    guard let value = json[key] else { return true } // absent is fine
                    return value is NSNull || value is Double || value is Int
                }

                if datesValid, let state = try? JSONDecoder().decode(ReviewPromptState.self, from: data) {
                    self.reviewState = state
                } else {
                    // Data is corrupted — clear it and start fresh
                    UserDefaults.standard.removeObject(forKey: reviewStateKey)
                    self.reviewState = .initial
                }
            } else {
                // Not valid JSON — clear it
                UserDefaults.standard.removeObject(forKey: reviewStateKey)
                self.reviewState = .initial
            }
        } else {
            self.reviewState = .initial
        }

        logger.diagnostic("[\(tag)]Initialized — sessions: \(reviewState.sessionCount), workouts: \(reviewState.workoutsCompleted)")
    }

    // MARK: - Session Tracking

    /// Track an app session start. Called when the app becomes active.
    func trackSessionStart() {
        reviewState.sessionCount += 1
        persistReviewState()
        logger.diagnostic("[\(tag)]Session tracked — total: \(reviewState.sessionCount)")
    }

    // MARK: - Workout Tracking

    /// Track a successful workout completion. This is one of the positive moments
    /// where a review prompt may be shown.
    func trackWorkoutCompleted() {
        reviewState.workoutsCompleted += 1
        persistReviewState()
        logger.info(tag, "Workout completed — total: \(reviewState.workoutsCompleted)")

        // Check if this is a good moment for a review prompt
        evaluateReviewPromptTiming(trigger: .workoutCompleted)
    }

    // MARK: - Achievement Tracking

    /// Track an achievement unlock. Another positive moment for review prompting.
    func trackAchievementUnlocked() {
        reviewState.achievementsUnlocked += 1
        persistReviewState()
        logger.info(tag, "Achievement unlocked — total: \(reviewState.achievementsUnlocked)")

        // Achievements are strong positive moments
        evaluateReviewPromptTiming(trigger: .achievementUnlocked)
    }

    // MARK: - App Store Impression Tracking

    /// Record when a user arrived from the App Store (detected via attribution).
    /// Useful for correlating ASO changes with install rates.
    func trackAppStoreImpression() {
        var impressions = UserDefaults.standard.integer(forKey: impressionKey)
        impressions += 1
        UserDefaults.standard.set(impressions, forKey: impressionKey)

        ErrorLogger.shared.logUserAction(
            action: "app_store_impression",
            properties: [
                "total_impressions": String(impressions),
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        )

        logger.info(tag, "App Store impression tracked — total: \(impressions)")
    }

    /// Total App Store impressions recorded
    var totalImpressions: Int {
        UserDefaults.standard.integer(forKey: impressionKey)
    }

    // MARK: - Review Prompting

    /// Trigger types that can initiate a review prompt evaluation
    enum ReviewTrigger: String {
        case workoutCompleted = "workout_completed"
        case achievementUnlocked = "achievement_unlocked"
        case manualCheck = "manual_check"
    }

    /// Evaluate whether a review prompt should be shown based on the current trigger.
    func evaluateReviewPromptTiming(trigger: ReviewTrigger) {
        guard reviewState.isEligibleForPrompt else {
            logger.diagnostic("[\(tag)]Not eligible for review prompt — dismissed: \(reviewState.permanentlyDismissed), sessions: \(reviewState.sessionCount), cooldown: \(!reviewState.inlinePromptCooldownElapsed)")
            return
        }

        switch trigger {
        case .workoutCompleted:
            // Only show after completing at least one workout AND having 3+ sessions
            guard reviewState.workoutsCompleted >= 1 && reviewState.hasMinimumSessions else {
                return
            }

        case .achievementUnlocked:
            // Achievements are always a good moment (if other criteria met)
            guard reviewState.hasMinimumSessions else {
                return
            }

        case .manualCheck:
            // Manual check requires all criteria
            guard reviewState.hasMinimumSessions && reviewState.workoutsCompleted >= 1 else {
                return
            }
        }

        logger.info(tag, "Review prompt eligible — trigger: \(trigger.rawValue)")
        shouldShowReviewPrompt = true
    }

    /// Request the system App Store review dialog via SKStoreReviewController.
    /// Respects the 60-day cooldown. Apple may choose not to show the dialog.
    func requestAppStoreReview() {
        guard reviewState.systemReviewCooldownElapsed else {
            logger.warning(tag, "System review cooldown has not elapsed — skipping SKStoreReviewController")
            return
        }

        // Find the active window scene for the review controller
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else {
            logger.warning(tag, "No active window scene found for review request")
            return
        }

        SKStoreReviewController.requestReview(in: windowScene)

        // Record the system review request
        reviewState.lastSystemReviewDate = Date()
        persistReviewState()

        ErrorLogger.shared.logUserAction(
            action: "app_store_review_requested",
            properties: [
                "trigger": "system_dialog",
                "session_count": String(reviewState.sessionCount),
                "workouts_completed": String(reviewState.workoutsCompleted)
            ]
        )

        logger.success(tag, "SKStoreReviewController.requestReview called")
    }

    /// Record that the inline review prompt was shown.
    func recordInlinePromptShown() {
        reviewState.lastPromptDate = Date()
        reviewState.promptShownCount += 1
        shouldShowReviewPrompt = false
        persistReviewState()

        ErrorLogger.shared.logUserAction(
            action: "inline_review_prompt_shown",
            properties: [
                "prompt_count": String(reviewState.promptShownCount),
                "session_count": String(reviewState.sessionCount)
            ]
        )

        logger.info(tag, "Inline review prompt shown — count: \(reviewState.promptShownCount)")
    }

    /// Record the user's star rating selection from the inline prompt.
    /// If 4-5 stars, triggers the system review dialog.
    /// If 1-3 stars, the UI should show a feedback form instead.
    func recordStarRating(_ rating: Int) {
        reviewState.lastSelectedRating = rating
        persistReviewState()

        ErrorLogger.shared.logUserAction(
            action: "inline_review_rating",
            properties: [
                "rating": String(rating),
                "session_count": String(reviewState.sessionCount)
            ]
        )

        logger.info(tag, "User selected \(rating) star(s)")

        if rating >= 4 {
            // Positive rating — trigger system review dialog
            requestAppStoreReview()
        }
        // For 1-3 stars, the calling view should show the feedback form
    }

    /// Permanently dismiss the review prompt (user selected "Don't ask again").
    func permanentlyDismissPrompt() {
        reviewState.permanentlyDismissed = true
        shouldShowReviewPrompt = false
        persistReviewState()

        ErrorLogger.shared.logUserAction(
            action: "review_prompt_permanently_dismissed",
            properties: [:]
        )

        logger.info(tag, "Review prompt permanently dismissed by user")
    }

    /// Dismiss the current review prompt without permanent dismissal.
    /// The prompt may appear again after the cooldown period.
    func dismissPrompt() {
        reviewState.lastPromptDate = Date()
        shouldShowReviewPrompt = false
        persistReviewState()

        logger.info(tag, "Review prompt dismissed — will re-evaluate after cooldown")
    }

    // MARK: - Persistence

    /// Persist the review prompt state to UserDefaults.
    private func persistReviewState() {
        do {
            let data = try JSONEncoder().encode(reviewState)
            UserDefaults.standard.set(data, forKey: reviewStateKey)
        } catch {
            logger.error(tag, "Failed to persist review state: \(error.localizedDescription)")
        }
    }

    // MARK: - Debug / Testing

    #if DEBUG
    /// Reset all review state for testing purposes.
    func resetReviewState() {
        reviewState = .initial
        shouldShowReviewPrompt = false
        persistReviewState()
        logger.warning(tag, "Review state reset (DEBUG only)")
    }
    #endif
}
