//
//  AnalyticsEventCatalog.swift
//  PTPerformance
//
//  Single source of truth for all analytics event names and properties.
//  Every tracked event in the app should reference a case from this catalog
//  to ensure consistent naming and structured metadata.
//

import Foundation

// MARK: - Analytics Event Catalog

/// Namespace for all analytics event definitions.
///
/// Each nested enum represents a domain (e.g., Onboarding, Auth, Workout) and
/// each case within that enum represents a discrete event. Associated values
/// capture event-specific context that is serialized into the `properties`
/// dictionary sent alongside every event.
///
/// ## Naming Convention
/// Event names follow the pattern `domain_action` using snake_case.
/// For example: `onboarding_started`, `subscription_purchase_completed`.
///
/// ## Usage
/// ```swift
/// let event = AnalyticsEventCatalog.Workout.sessionCompleted(duration: 2700, exerciseCount: 8)
/// AnalyticsTracker.shared.track(event: event.eventName, properties: event.properties)
/// ```
enum AnalyticsEventCatalog {

    // MARK: - Onboarding

    /// Events related to the first-run onboarding flow.
    enum Onboarding {
        case started
        case pageViewed(page: Int)
        case quickStartTapped
        case setupCompleted
        case setupSkipped
        case profileCompleted
        case firstWorkoutCompleted

        /// Standardized snake_case event name.
        var eventName: String {
            switch self {
            case .started:
                return "onboarding_started"
            case .pageViewed:
                return "onboarding_page_viewed"
            case .quickStartTapped:
                return "onboarding_quick_start_tapped"
            case .setupCompleted:
                return "onboarding_setup_completed"
            case .setupSkipped:
                return "onboarding_setup_skipped"
            case .profileCompleted:
                return "onboarding_profile_completed"
            case .firstWorkoutCompleted:
                return "onboarding_first_workout_completed"
            }
        }

        /// Associated values serialized as a string dictionary.
        var properties: [String: String] {
            switch self {
            case .started:
                return [:]
            case .pageViewed(let page):
                return ["page": String(page)]
            case .quickStartTapped:
                return [:]
            case .setupCompleted:
                return [:]
            case .setupSkipped:
                return [:]
            case .profileCompleted:
                return [:]
            case .firstWorkoutCompleted:
                return [:]
            }
        }
    }

    // MARK: - Auth

    /// Events related to authentication and account management.
    enum Auth {
        case loginStarted(method: String)
        case loginCompleted
        case loginFailed(reason: String)
        case logoutCompleted
        case signupStarted
        case signupCompleted
        case passwordResetRequested

        var eventName: String {
            switch self {
            case .loginStarted:
                return "auth_login_started"
            case .loginCompleted:
                return "auth_login_completed"
            case .loginFailed:
                return "auth_login_failed"
            case .logoutCompleted:
                return "auth_logout_completed"
            case .signupStarted:
                return "auth_signup_started"
            case .signupCompleted:
                return "auth_signup_completed"
            case .passwordResetRequested:
                return "auth_password_reset_requested"
            }
        }

        var properties: [String: String] {
            switch self {
            case .loginStarted(let method):
                return ["method": method]
            case .loginCompleted:
                return [:]
            case .loginFailed(let reason):
                return ["reason": reason]
            case .logoutCompleted:
                return [:]
            case .signupStarted:
                return [:]
            case .signupCompleted:
                return [:]
            case .passwordResetRequested:
                return [:]
            }
        }
    }

    // MARK: - Subscription

    /// Events related to paywall interactions and in-app purchases.
    enum Subscription {
        case paywallViewed(source: String)
        case paywallDismissed
        case trialStarted(tier: String)
        case purchaseStarted(tier: String)
        case purchaseCompleted(tier: String, revenue: Double)
        case purchaseFailed(reason: String)
        case subscriptionCanceled
        case subscriptionRestored

        var eventName: String {
            switch self {
            case .paywallViewed:
                return "subscription_paywall_viewed"
            case .paywallDismissed:
                return "subscription_paywall_dismissed"
            case .trialStarted:
                return "subscription_trial_started"
            case .purchaseStarted:
                return "subscription_purchase_started"
            case .purchaseCompleted:
                return "subscription_purchase_completed"
            case .purchaseFailed:
                return "subscription_purchase_failed"
            case .subscriptionCanceled:
                return "subscription_canceled"
            case .subscriptionRestored:
                return "subscription_restored"
            }
        }

        var properties: [String: String] {
            switch self {
            case .paywallViewed(let source):
                return ["source": source]
            case .paywallDismissed:
                return [:]
            case .trialStarted(let tier):
                return ["tier": tier]
            case .purchaseStarted(let tier):
                return ["tier": tier]
            case .purchaseCompleted(let tier, let revenue):
                return ["tier": tier, "revenue": String(revenue)]
            case .purchaseFailed(let reason):
                return ["reason": reason]
            case .subscriptionCanceled:
                return [:]
            case .subscriptionRestored:
                return [:]
            }
        }
    }

    // MARK: - Workout

    /// Events related to workout sessions and exercise tracking.
    enum Workout {
        case sessionStarted
        case sessionCompleted(duration: Int, exerciseCount: Int)
        case sessionAbandoned
        case exerciseCompleted(name: String)
        case setCompleted
        case restTimerStarted
        case restTimerSkipped

        var eventName: String {
            switch self {
            case .sessionStarted:
                return "workout_session_started"
            case .sessionCompleted:
                return "workout_session_completed"
            case .sessionAbandoned:
                return "workout_session_abandoned"
            case .exerciseCompleted:
                return "workout_exercise_completed"
            case .setCompleted:
                return "workout_set_completed"
            case .restTimerStarted:
                return "workout_rest_timer_started"
            case .restTimerSkipped:
                return "workout_rest_timer_skipped"
            }
        }

        var properties: [String: String] {
            switch self {
            case .sessionStarted:
                return [:]
            case .sessionCompleted(let duration, let exerciseCount):
                return [
                    "duration": String(duration),
                    "exercise_count": String(exerciseCount)
                ]
            case .sessionAbandoned:
                return [:]
            case .exerciseCompleted(let name):
                return ["name": name]
            case .setCompleted:
                return [:]
            case .restTimerStarted:
                return [:]
            case .restTimerSkipped:
                return [:]
            }
        }
    }

    // MARK: - AI

    /// Events related to AI coaching, chat, and exercise substitution.
    enum AI {
        case chatOpened
        case messageSent
        case responseReceived
        case substitutionSuggested
        case substitutionAccepted
        case substitutionRejected
        case coachingInsightViewed

        var eventName: String {
            switch self {
            case .chatOpened:
                return "ai_chat_opened"
            case .messageSent:
                return "ai_message_sent"
            case .responseReceived:
                return "ai_response_received"
            case .substitutionSuggested:
                return "ai_substitution_suggested"
            case .substitutionAccepted:
                return "ai_substitution_accepted"
            case .substitutionRejected:
                return "ai_substitution_rejected"
            case .coachingInsightViewed:
                return "ai_coaching_insight_viewed"
            }
        }

        var properties: [String: String] {
            switch self {
            case .chatOpened,
                 .messageSent,
                 .responseReceived,
                 .substitutionSuggested,
                 .substitutionAccepted,
                 .substitutionRejected,
                 .coachingInsightViewed:
                return [:]
            }
        }
    }

    // MARK: - Health

    /// Events related to HealthKit integration, readiness, and recovery.
    enum Health {
        case healthKitConnected
        case healthKitSynced(dataType: String)
        case readinessViewed
        case readinessScoreCalculated(score: Int)
        case recoveryViewed
        case sleepDataViewed
        case hrvDataViewed

        var eventName: String {
            switch self {
            case .healthKitConnected:
                return "health_healthkit_connected"
            case .healthKitSynced:
                return "health_healthkit_synced"
            case .readinessViewed:
                return "health_readiness_viewed"
            case .readinessScoreCalculated:
                return "health_readiness_score_calculated"
            case .recoveryViewed:
                return "health_recovery_viewed"
            case .sleepDataViewed:
                return "health_sleep_data_viewed"
            case .hrvDataViewed:
                return "health_hrv_data_viewed"
            }
        }

        var properties: [String: String] {
            switch self {
            case .healthKitConnected:
                return [:]
            case .healthKitSynced(let dataType):
                return ["data_type": dataType]
            case .readinessViewed:
                return [:]
            case .readinessScoreCalculated(let score):
                return ["score": String(score)]
            case .recoveryViewed:
                return [:]
            case .sleepDataViewed:
                return [:]
            case .hrvDataViewed:
                return [:]
            }
        }
    }

    // MARK: - Navigation

    /// Events related to screen views, tab switches, and deep links.
    enum Navigation {
        case screenViewed(name: String)
        case tabSwitched(tab: String)
        case deepLinkOpened(destination: String)
        case notificationTapped(type: String)

        var eventName: String {
            switch self {
            case .screenViewed:
                return "navigation_screen_viewed"
            case .tabSwitched:
                return "navigation_tab_switched"
            case .deepLinkOpened:
                return "navigation_deep_link_opened"
            case .notificationTapped:
                return "navigation_notification_tapped"
            }
        }

        var properties: [String: String] {
            switch self {
            case .screenViewed(let name):
                return ["name": name]
            case .tabSwitched(let tab):
                return ["tab": tab]
            case .deepLinkOpened(let destination):
                return ["destination": destination]
            case .notificationTapped(let type):
                return ["type": type]
            }
        }
    }

    // MARK: - Engagement

    /// Events related to app lifecycle, streaks, achievements, and sharing.
    enum Engagement {
        case appOpened(source: String)
        case appBackgrounded
        case sessionDuration(seconds: Int)
        case streakUpdated(count: Int)
        case achievementUnlocked(name: String)
        case shareCompleted(type: String)

        var eventName: String {
            switch self {
            case .appOpened:
                return "engagement_app_opened"
            case .appBackgrounded:
                return "engagement_app_backgrounded"
            case .sessionDuration:
                return "engagement_session_duration"
            case .streakUpdated:
                return "engagement_streak_updated"
            case .achievementUnlocked:
                return "engagement_achievement_unlocked"
            case .shareCompleted:
                return "engagement_share_completed"
            }
        }

        var properties: [String: String] {
            switch self {
            case .appOpened(let source):
                return ["source": source]
            case .appBackgrounded:
                return [:]
            case .sessionDuration(let seconds):
                return ["seconds": String(seconds)]
            case .streakUpdated(let count):
                return ["count": String(count)]
            case .achievementUnlocked(let name):
                return ["name": name]
            case .shareCompleted(let type):
                return ["type": type]
            }
        }
    }

    // MARK: - Error

    /// Events related to errors, failures, and crash prevention.
    enum Error {
        case apiError(endpoint: String, statusCode: Int)
        case decodingError(context: String)
        case networkTimeout(endpoint: String)
        case crashPrevented(context: String)

        var eventName: String {
            switch self {
            case .apiError:
                return "error_api_error"
            case .decodingError:
                return "error_decoding_error"
            case .networkTimeout:
                return "error_network_timeout"
            case .crashPrevented:
                return "error_crash_prevented"
            }
        }

        var properties: [String: String] {
            switch self {
            case .apiError(let endpoint, let statusCode):
                return [
                    "endpoint": endpoint,
                    "status_code": String(statusCode)
                ]
            case .decodingError(let context):
                return ["context": context]
            case .networkTimeout(let endpoint):
                return ["endpoint": endpoint]
            case .crashPrevented(let context):
                return ["context": context]
            }
        }
    }
}
