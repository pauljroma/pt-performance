//
//  AnalyticsEventSchema.swift
//  PTPerformance
//
//  Schema versioning and validation for analytics events.
//  Provides machine-readable definitions of every event in the catalog,
//  enabling runtime validation and tooling support.
//

import Foundation

// MARK: - Analytics Event Schema

/// Schema registry that pairs each event name from `AnalyticsEventCatalog`
/// with a formal definition describing its category, required and optional
/// properties, and a human-readable description.
///
/// ## Versioning
/// The `version` constant follows semantic versioning. Increment the major
/// version when removing events or renaming properties, the minor version
/// when adding new events, and the patch version for description-only changes.
///
/// ## Validation
/// Call `validate(event:properties:)` at debug/staging time to ensure every
/// tracked event conforms to its schema before shipping to production.
///
/// ## Usage
/// ```swift
/// let isValid = AnalyticsEventSchema.validate(
///     event: "subscription_purchase_completed",
///     properties: ["tier": "pro", "revenue": "9.99"]
/// )
/// ```
enum AnalyticsEventSchema {

    // MARK: - Version

    /// Semantic version of the event schema.
    /// Increment major for breaking changes, minor for new events, patch for docs.
    static let version = "1.0.0"

    // MARK: - Event Definition

    /// Formal definition of a single analytics event.
    struct EventDefinition {
        /// The canonical snake_case event name (must match `eventName` on the catalog case).
        let name: String

        /// Domain category the event belongs to (e.g., "onboarding", "auth").
        let category: String

        /// Property keys that **must** be present when the event is tracked.
        let requiredProperties: [String]

        /// Property keys that **may** be present but are not mandatory.
        let optionalProperties: [String]

        /// Human-readable explanation of when and why this event fires.
        let description: String
    }

    // MARK: - Definitions Registry

    /// Complete dictionary of event definitions keyed by event name.
    static let definitions: [String: EventDefinition] = {
        var defs: [String: EventDefinition] = [:]

        // -- Onboarding --------------------------------------------------

        defs["onboarding_started"] = EventDefinition(
            name: "onboarding_started",
            category: "onboarding",
            requiredProperties: [],
            optionalProperties: [],
            description: "User launched the onboarding flow for the first time."
        )

        defs["onboarding_page_viewed"] = EventDefinition(
            name: "onboarding_page_viewed",
            category: "onboarding",
            requiredProperties: ["page"],
            optionalProperties: [],
            description: "User viewed a specific page within the onboarding carousel."
        )

        defs["onboarding_quick_start_tapped"] = EventDefinition(
            name: "onboarding_quick_start_tapped",
            category: "onboarding",
            requiredProperties: [],
            optionalProperties: [],
            description: "User tapped the quick-start button to skip detailed onboarding."
        )

        defs["onboarding_setup_completed"] = EventDefinition(
            name: "onboarding_setup_completed",
            category: "onboarding",
            requiredProperties: [],
            optionalProperties: [],
            description: "User completed the full onboarding setup flow."
        )

        defs["onboarding_setup_skipped"] = EventDefinition(
            name: "onboarding_setup_skipped",
            category: "onboarding",
            requiredProperties: [],
            optionalProperties: [],
            description: "User explicitly skipped the onboarding setup."
        )

        defs["onboarding_profile_completed"] = EventDefinition(
            name: "onboarding_profile_completed",
            category: "onboarding",
            requiredProperties: [],
            optionalProperties: [],
            description: "User finished filling out their profile during onboarding."
        )

        defs["onboarding_first_workout_completed"] = EventDefinition(
            name: "onboarding_first_workout_completed",
            category: "onboarding",
            requiredProperties: [],
            optionalProperties: [],
            description: "User completed their very first workout after onboarding."
        )

        // -- Auth --------------------------------------------------------

        defs["auth_login_started"] = EventDefinition(
            name: "auth_login_started",
            category: "auth",
            requiredProperties: ["method"],
            optionalProperties: [],
            description: "User initiated the login process using a specific method (e.g., email, Apple)."
        )

        defs["auth_login_completed"] = EventDefinition(
            name: "auth_login_completed",
            category: "auth",
            requiredProperties: [],
            optionalProperties: [],
            description: "User successfully authenticated and entered the app."
        )

        defs["auth_login_failed"] = EventDefinition(
            name: "auth_login_failed",
            category: "auth",
            requiredProperties: ["reason"],
            optionalProperties: [],
            description: "Login attempt failed; reason captures the failure category."
        )

        defs["auth_logout_completed"] = EventDefinition(
            name: "auth_logout_completed",
            category: "auth",
            requiredProperties: [],
            optionalProperties: [],
            description: "User successfully logged out of the app."
        )

        defs["auth_signup_started"] = EventDefinition(
            name: "auth_signup_started",
            category: "auth",
            requiredProperties: [],
            optionalProperties: [],
            description: "User began the account creation flow."
        )

        defs["auth_signup_completed"] = EventDefinition(
            name: "auth_signup_completed",
            category: "auth",
            requiredProperties: [],
            optionalProperties: [],
            description: "User successfully created a new account."
        )

        defs["auth_password_reset_requested"] = EventDefinition(
            name: "auth_password_reset_requested",
            category: "auth",
            requiredProperties: [],
            optionalProperties: [],
            description: "User requested a password reset email."
        )

        // -- Subscription ------------------------------------------------

        defs["subscription_paywall_viewed"] = EventDefinition(
            name: "subscription_paywall_viewed",
            category: "subscription",
            requiredProperties: ["source"],
            optionalProperties: [],
            description: "User saw the paywall screen; source indicates the trigger point."
        )

        defs["subscription_paywall_dismissed"] = EventDefinition(
            name: "subscription_paywall_dismissed",
            category: "subscription",
            requiredProperties: [],
            optionalProperties: [],
            description: "User dismissed the paywall without taking action."
        )

        defs["subscription_trial_started"] = EventDefinition(
            name: "subscription_trial_started",
            category: "subscription",
            requiredProperties: ["tier"],
            optionalProperties: [],
            description: "User started a free trial for the given subscription tier."
        )

        defs["subscription_purchase_started"] = EventDefinition(
            name: "subscription_purchase_started",
            category: "subscription",
            requiredProperties: ["tier"],
            optionalProperties: [],
            description: "User initiated a subscription purchase for the given tier."
        )

        defs["subscription_purchase_completed"] = EventDefinition(
            name: "subscription_purchase_completed",
            category: "subscription",
            requiredProperties: ["tier", "revenue"],
            optionalProperties: [],
            description: "Subscription purchase was confirmed; revenue is in USD."
        )

        defs["subscription_purchase_failed"] = EventDefinition(
            name: "subscription_purchase_failed",
            category: "subscription",
            requiredProperties: ["reason"],
            optionalProperties: [],
            description: "Subscription purchase failed; reason describes the failure."
        )

        defs["subscription_canceled"] = EventDefinition(
            name: "subscription_canceled",
            category: "subscription",
            requiredProperties: [],
            optionalProperties: [],
            description: "User canceled their active subscription."
        )

        defs["subscription_restored"] = EventDefinition(
            name: "subscription_restored",
            category: "subscription",
            requiredProperties: [],
            optionalProperties: [],
            description: "User restored a previously purchased subscription."
        )

        // -- Workout -----------------------------------------------------

        defs["workout_session_started"] = EventDefinition(
            name: "workout_session_started",
            category: "workout",
            requiredProperties: [],
            optionalProperties: [],
            description: "User started a new workout session."
        )

        defs["workout_session_completed"] = EventDefinition(
            name: "workout_session_completed",
            category: "workout",
            requiredProperties: ["duration", "exercise_count"],
            optionalProperties: [],
            description: "User finished a workout session; duration is in seconds."
        )

        defs["workout_session_abandoned"] = EventDefinition(
            name: "workout_session_abandoned",
            category: "workout",
            requiredProperties: [],
            optionalProperties: [],
            description: "User left a workout session before completing all exercises."
        )

        defs["workout_exercise_completed"] = EventDefinition(
            name: "workout_exercise_completed",
            category: "workout",
            requiredProperties: ["name"],
            optionalProperties: [],
            description: "User completed all sets for a single exercise."
        )

        defs["workout_set_completed"] = EventDefinition(
            name: "workout_set_completed",
            category: "workout",
            requiredProperties: [],
            optionalProperties: [],
            description: "User completed a single set within an exercise."
        )

        defs["workout_rest_timer_started"] = EventDefinition(
            name: "workout_rest_timer_started",
            category: "workout",
            requiredProperties: [],
            optionalProperties: [],
            description: "Rest timer began between sets."
        )

        defs["workout_rest_timer_skipped"] = EventDefinition(
            name: "workout_rest_timer_skipped",
            category: "workout",
            requiredProperties: [],
            optionalProperties: [],
            description: "User skipped the rest timer to start the next set early."
        )

        // -- AI ----------------------------------------------------------

        defs["ai_chat_opened"] = EventDefinition(
            name: "ai_chat_opened",
            category: "ai",
            requiredProperties: [],
            optionalProperties: [],
            description: "User opened the AI coaching chat interface."
        )

        defs["ai_message_sent"] = EventDefinition(
            name: "ai_message_sent",
            category: "ai",
            requiredProperties: [],
            optionalProperties: [],
            description: "User sent a message to the AI coach."
        )

        defs["ai_response_received"] = EventDefinition(
            name: "ai_response_received",
            category: "ai",
            requiredProperties: [],
            optionalProperties: [],
            description: "AI coach returned a response to the user."
        )

        defs["ai_substitution_suggested"] = EventDefinition(
            name: "ai_substitution_suggested",
            category: "ai",
            requiredProperties: [],
            optionalProperties: [],
            description: "AI suggested an alternative exercise substitution."
        )

        defs["ai_substitution_accepted"] = EventDefinition(
            name: "ai_substitution_accepted",
            category: "ai",
            requiredProperties: [],
            optionalProperties: [],
            description: "User accepted the AI-suggested exercise substitution."
        )

        defs["ai_substitution_rejected"] = EventDefinition(
            name: "ai_substitution_rejected",
            category: "ai",
            requiredProperties: [],
            optionalProperties: [],
            description: "User rejected the AI-suggested exercise substitution."
        )

        defs["ai_coaching_insight_viewed"] = EventDefinition(
            name: "ai_coaching_insight_viewed",
            category: "ai",
            requiredProperties: [],
            optionalProperties: [],
            description: "User viewed an AI-generated coaching insight or recommendation."
        )

        // -- Health ------------------------------------------------------

        defs["health_healthkit_connected"] = EventDefinition(
            name: "health_healthkit_connected",
            category: "health",
            requiredProperties: [],
            optionalProperties: [],
            description: "User granted HealthKit permissions and connected the integration."
        )

        defs["health_healthkit_synced"] = EventDefinition(
            name: "health_healthkit_synced",
            category: "health",
            requiredProperties: ["data_type"],
            optionalProperties: [],
            description: "HealthKit data was synced for a specific data type (e.g., steps, heart_rate)."
        )

        defs["health_readiness_viewed"] = EventDefinition(
            name: "health_readiness_viewed",
            category: "health",
            requiredProperties: [],
            optionalProperties: [],
            description: "User viewed the readiness score screen."
        )

        defs["health_readiness_score_calculated"] = EventDefinition(
            name: "health_readiness_score_calculated",
            category: "health",
            requiredProperties: ["score"],
            optionalProperties: [],
            description: "A readiness score was calculated and displayed to the user."
        )

        defs["health_recovery_viewed"] = EventDefinition(
            name: "health_recovery_viewed",
            category: "health",
            requiredProperties: [],
            optionalProperties: [],
            description: "User viewed the recovery metrics screen."
        )

        defs["health_sleep_data_viewed"] = EventDefinition(
            name: "health_sleep_data_viewed",
            category: "health",
            requiredProperties: [],
            optionalProperties: [],
            description: "User viewed their sleep data summary."
        )

        defs["health_hrv_data_viewed"] = EventDefinition(
            name: "health_hrv_data_viewed",
            category: "health",
            requiredProperties: [],
            optionalProperties: [],
            description: "User viewed their heart rate variability data."
        )

        // -- Navigation --------------------------------------------------

        defs["navigation_screen_viewed"] = EventDefinition(
            name: "navigation_screen_viewed",
            category: "navigation",
            requiredProperties: ["name"],
            optionalProperties: [],
            description: "User navigated to a screen; name identifies the screen."
        )

        defs["navigation_tab_switched"] = EventDefinition(
            name: "navigation_tab_switched",
            category: "navigation",
            requiredProperties: ["tab"],
            optionalProperties: [],
            description: "User switched to a different tab in the tab bar."
        )

        defs["navigation_deep_link_opened"] = EventDefinition(
            name: "navigation_deep_link_opened",
            category: "navigation",
            requiredProperties: ["destination"],
            optionalProperties: [],
            description: "App was opened via a deep link to a specific destination."
        )

        defs["navigation_notification_tapped"] = EventDefinition(
            name: "navigation_notification_tapped",
            category: "navigation",
            requiredProperties: ["type"],
            optionalProperties: [],
            description: "User tapped a push notification to open the app."
        )

        // -- Engagement --------------------------------------------------

        defs["engagement_app_opened"] = EventDefinition(
            name: "engagement_app_opened",
            category: "engagement",
            requiredProperties: ["source"],
            optionalProperties: [],
            description: "App was brought to the foreground; source indicates how (e.g., direct, notification, widget)."
        )

        defs["engagement_app_backgrounded"] = EventDefinition(
            name: "engagement_app_backgrounded",
            category: "engagement",
            requiredProperties: [],
            optionalProperties: [],
            description: "App was moved to the background by the user."
        )

        defs["engagement_session_duration"] = EventDefinition(
            name: "engagement_session_duration",
            category: "engagement",
            requiredProperties: ["seconds"],
            optionalProperties: [],
            description: "Recorded total foreground time for an app session in seconds."
        )

        defs["engagement_streak_updated"] = EventDefinition(
            name: "engagement_streak_updated",
            category: "engagement",
            requiredProperties: ["count"],
            optionalProperties: [],
            description: "User's workout streak count was updated."
        )

        defs["engagement_achievement_unlocked"] = EventDefinition(
            name: "engagement_achievement_unlocked",
            category: "engagement",
            requiredProperties: ["name"],
            optionalProperties: [],
            description: "User unlocked a new achievement or milestone."
        )

        defs["engagement_share_completed"] = EventDefinition(
            name: "engagement_share_completed",
            category: "engagement",
            requiredProperties: ["type"],
            optionalProperties: [],
            description: "User shared content from the app; type describes what was shared."
        )

        // -- Error -------------------------------------------------------

        defs["error_api_error"] = EventDefinition(
            name: "error_api_error",
            category: "error",
            requiredProperties: ["endpoint", "status_code"],
            optionalProperties: [],
            description: "An API request returned a non-success HTTP status code."
        )

        defs["error_decoding_error"] = EventDefinition(
            name: "error_decoding_error",
            category: "error",
            requiredProperties: ["context"],
            optionalProperties: [],
            description: "JSON or model decoding failed; context describes where it happened."
        )

        defs["error_network_timeout"] = EventDefinition(
            name: "error_network_timeout",
            category: "error",
            requiredProperties: ["endpoint"],
            optionalProperties: [],
            description: "A network request timed out before receiving a response."
        )

        defs["error_crash_prevented"] = EventDefinition(
            name: "error_crash_prevented",
            category: "error",
            requiredProperties: ["context"],
            optionalProperties: [],
            description: "A potential crash was caught and handled gracefully."
        )

        return defs
    }()

    // MARK: - Validation

    /// Validates that a tracked event conforms to its schema definition.
    ///
    /// Checks that the event name exists in the definitions registry and that
    /// all required properties are present in the supplied dictionary.
    ///
    /// - Parameters:
    ///   - event: The snake_case event name to validate.
    ///   - properties: The property dictionary accompanying the event.
    /// - Returns: `true` if the event is defined and all required properties are present;
    ///            `false` otherwise.
    static func validate(event: String, properties: [String: Any]) -> Bool {
        guard let definition = definitions[event] else {
            return false
        }

        for requiredKey in definition.requiredProperties {
            guard properties[requiredKey] != nil else {
                return false
            }
        }

        return true
    }
}
