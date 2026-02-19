//
//  UserTraits.swift
//  PTPerformance
//
//  ACP-961: User Properties & Traits
//  Defines user trait types, engagement segments, and computed behavioral
//  properties used for analytics enrichment and personalization.
//
//  Privacy: This model never stores PII. All traits are anonymised behavioral
//  signals (subscription tier, session counts, feature flags, etc.).
//

import Foundation
import UIKit

// MARK: - Engagement Segment

/// Behavioral segment derived from session frequency and recency.
///
/// Segments are computed automatically by `UserPropertyManager` based on
/// historical engagement data. They power lifecycle campaigns, in-app
/// messaging, and analytics cohort analysis.
///
/// ## Thresholds
/// | Segment     | Sessions / 7 days | Days Since Last Session |
/// |-------------|-------------------|------------------------|
/// | Power User  | >= 5              | <= 2                   |
/// | Active      | >= 2              | <= 7                   |
/// | Casual      | >= 1              | <= 14                  |
/// | At Risk     | 0                 | 15-30                  |
/// | Dormant     | 0                 | > 30                   |
/// | New         | (account < 7 days old)                     |
enum EngagementSegment: String, Codable, Sendable, CaseIterable {
    case powerUser = "power_user"
    case active = "active"
    case casual = "casual"
    case atRisk = "at_risk"
    case dormant = "dormant"
    case newUser = "new_user"

    var displayName: String {
        switch self {
        case .powerUser: return "Power User"
        case .active: return "Active"
        case .casual: return "Casual"
        case .atRisk: return "At Risk"
        case .dormant: return "Dormant"
        case .newUser: return "New User"
        }
    }

    /// Numeric priority for analytics ordering (higher = more engaged).
    var engagementLevel: Int {
        switch self {
        case .powerUser: return 5
        case .active: return 4
        case .casual: return 3
        case .newUser: return 2
        case .atRisk: return 1
        case .dormant: return 0
        }
    }
}

// MARK: - Feature Usage Flags

/// Boolean flags indicating which major features the user has ever used.
///
/// These flags are set once (latched) and never reset. They are persisted
/// alongside other user traits and synced to the analytics backend as part
/// of the user profile enrichment.
struct FeatureUsageFlags: Codable, Equatable, Sendable {

    /// User has completed at least one workout session.
    var hasCompletedWorkout: Bool = false

    /// User has opened the AI coaching chat at least once.
    var hasUsedAIChat: Bool = false

    /// User has logged at least one nutrition entry.
    var hasLoggedNutrition: Bool = false

    /// User has viewed the readiness score screen at least once.
    var hasViewedReadiness: Bool = false

    /// User has connected a HealthKit data source.
    var hasConnectedHealthKit: Bool = false

    /// User has connected a wearable device (e.g. WHOOP).
    var hasConnectedWearable: Bool = false

    /// User has used exercise substitution (AI or manual).
    var hasUsedSubstitution: Bool = false

    /// User has created or enrolled in a custom program.
    var hasUsedPrograms: Bool = false

    /// User has shared content from the app.
    var hasSharedContent: Bool = false

    /// User has enabled push notifications.
    var hasEnabledNotifications: Bool = false

    /// Serialises all flags to a `[String: String]` dictionary for analytics.
    var asDictionary: [String: String] {
        [
            "has_completed_workout": String(hasCompletedWorkout),
            "has_used_ai_chat": String(hasUsedAIChat),
            "has_logged_nutrition": String(hasLoggedNutrition),
            "has_viewed_readiness": String(hasViewedReadiness),
            "has_connected_healthkit": String(hasConnectedHealthKit),
            "has_connected_wearable": String(hasConnectedWearable),
            "has_used_substitution": String(hasUsedSubstitution),
            "has_used_programs": String(hasUsedPrograms),
            "has_shared_content": String(hasSharedContent),
            "has_enabled_notifications": String(hasEnabledNotifications)
        ]
    }

    /// The total count of features the user has activated.
    var activatedFeatureCount: Int {
        let flags: [Bool] = [
            hasCompletedWorkout, hasUsedAIChat, hasLoggedNutrition,
            hasViewedReadiness, hasConnectedHealthKit, hasConnectedWearable,
            hasUsedSubstitution, hasUsedPrograms, hasSharedContent,
            hasEnabledNotifications
        ]
        return flags.filter { $0 }.count
    }
}

// MARK: - User Traits

/// Complete set of anonymised user traits for analytics enrichment.
///
/// `UserTraits` is the single source of truth for all user-level properties
/// that are synced to the analytics backend. It combines static attributes
/// (subscription tier, role), behavioural metrics (session counts, streak),
/// computed segments (engagement segment, feature adoption tier), and device
/// context (OS version, device model, app version).
///
/// ## Persistence
/// The struct is `Codable` and persisted to a JSON file in the caches
/// directory by `UserPropertyManager`. It is restored on app launch so that
/// traits are available immediately, even before network calls complete.
///
/// ## Privacy
/// No PII is stored. `userId` is the only identifier and is the same
/// opaque UUID used elsewhere in the app.
struct UserTraits: Codable, Equatable, Sendable {

    // MARK: - Identity

    /// Opaque user identifier (matches Supabase auth UID).
    var userId: String?

    /// The user's role within the app (e.g. "patient", "therapist").
    /// Stored as a raw string for Codable/Sendable compatibility with the
    /// existing `UserRole` enum defined in SupabaseClient.swift.
    var role: String = "unknown"

    // MARK: - Subscription

    /// Current subscription tier (free, pro, elite).
    var subscriptionTier: SubscriptionTier = .free

    /// Whether the user is in an active trial period.
    var isTrialActive: Bool = false

    /// ISO-8601 date string of when the subscription expires, if applicable.
    var subscriptionExpirationDate: String?

    // MARK: - Account Lifecycle

    /// ISO-8601 date string of when the account was created.
    var accountCreatedDate: String?

    /// Number of calendar days since account creation.
    var accountAgeDays: Int = 0

    /// ISO-8601 date string of the user's first session completion.
    var firstSessionDate: String?

    /// ISO-8601 date string of the user's most recent session.
    var lastSessionDate: String?

    // MARK: - Engagement Metrics

    /// Total number of sessions completed over the lifetime of the account.
    var totalSessionsCompleted: Int = 0

    /// Number of sessions completed in the last 7 days.
    var sessionsLast7Days: Int = 0

    /// Number of sessions completed in the last 30 days.
    var sessionsLast30Days: Int = 0

    /// Current consecutive-day workout streak.
    var currentStreak: Int = 0

    /// Longest streak ever achieved.
    var longestStreak: Int = 0

    /// Number of calendar days since the last session (0 if today).
    var daysSinceLastSession: Int = 0

    /// Total number of app launches recorded.
    var totalAppLaunches: Int = 0

    // MARK: - Feature Usage

    /// Boolean flags for feature activation (latched, never reset).
    var featureUsage: FeatureUsageFlags = FeatureUsageFlags()

    // MARK: - Computed Segments

    /// The user's current engagement segment (power user, active, casual, etc.).
    var engagementSegment: EngagementSegment = .newUser

    /// Feature adoption tier based on how many features the user has activated.
    /// Ranges from "explorer" (0-2) through "adopter" (3-5) to "champion" (6+).
    var featureAdoptionTier: String = "explorer"

    // MARK: - Device & App Context

    /// Marketing app version (CFBundleShortVersionString).
    var appVersion: String = ""

    /// Build number (CFBundleVersion).
    var buildNumber: String = ""

    /// iOS version string (e.g. "18.2").
    var osVersion: String = ""

    /// Device model identifier (e.g. "iPhone16,1").
    var deviceModel: String = ""

    /// User's preferred locale identifier (e.g. "en_US").
    var locale: String = ""

    /// User's timezone identifier (e.g. "America/New_York").
    var timezone: String = ""

    // MARK: - Custom Properties

    /// Arbitrary key-value properties that can be set by calling code.
    /// These are merged into the analytics traits dictionary on sync.
    var customProperties: [String: String] = [:]

    // MARK: - Timestamps

    /// ISO-8601 timestamp of the last time traits were synced to the analytics backend.
    var lastSyncedAt: String?

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case role
        case subscriptionTier = "subscription_tier"
        case isTrialActive = "is_trial_active"
        case subscriptionExpirationDate = "subscription_expiration_date"
        case accountCreatedDate = "account_created_date"
        case accountAgeDays = "account_age_days"
        case firstSessionDate = "first_session_date"
        case lastSessionDate = "last_session_date"
        case totalSessionsCompleted = "total_sessions_completed"
        case sessionsLast7Days = "sessions_last_7_days"
        case sessionsLast30Days = "sessions_last_30_days"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case daysSinceLastSession = "days_since_last_session"
        case totalAppLaunches = "total_app_launches"
        case featureUsage = "feature_usage"
        case engagementSegment = "engagement_segment"
        case featureAdoptionTier = "feature_adoption_tier"
        case appVersion = "app_version"
        case buildNumber = "build_number"
        case osVersion = "os_version"
        case deviceModel = "device_model"
        case locale
        case timezone
        case customProperties = "custom_properties"
        case lastSyncedAt = "last_synced_at"
    }

    // MARK: - Computed Analytics Dictionary

    /// Flattens all traits into a `[String: String]` dictionary suitable for
    /// the `AnalyticsSDK.identify(userId:traits:)` call.
    ///
    /// Feature usage flags are inlined with their `has_` prefix. Custom
    /// properties are merged last so they can override any auto-computed key.
    func asDictionary() -> [String: String] {
        var dict: [String: String] = [:]

        // Identity
        if let userId = userId { dict["user_id"] = userId }
        dict["role"] = role

        // Subscription
        dict["subscription_tier"] = subscriptionTier.rawValue
        dict["is_trial_active"] = String(isTrialActive)
        if let exp = subscriptionExpirationDate { dict["subscription_expiration_date"] = exp }

        // Account lifecycle
        if let created = accountCreatedDate { dict["account_created_date"] = created }
        dict["account_age_days"] = String(accountAgeDays)
        if let first = firstSessionDate { dict["first_session_date"] = first }
        if let last = lastSessionDate { dict["last_session_date"] = last }

        // Engagement
        dict["total_sessions_completed"] = String(totalSessionsCompleted)
        dict["sessions_last_7_days"] = String(sessionsLast7Days)
        dict["sessions_last_30_days"] = String(sessionsLast30Days)
        dict["current_streak"] = String(currentStreak)
        dict["longest_streak"] = String(longestStreak)
        dict["days_since_last_session"] = String(daysSinceLastSession)
        dict["total_app_launches"] = String(totalAppLaunches)

        // Feature usage
        dict.merge(featureUsage.asDictionary) { _, new in new }
        dict["activated_feature_count"] = String(featureUsage.activatedFeatureCount)

        // Computed segments
        dict["engagement_segment"] = engagementSegment.rawValue
        dict["feature_adoption_tier"] = featureAdoptionTier

        // Device & App
        dict["app_version"] = appVersion
        dict["build_number"] = buildNumber
        dict["os_version"] = osVersion
        dict["device_model"] = deviceModel
        dict["locale"] = locale
        dict["timezone"] = timezone

        // Sync metadata
        if let synced = lastSyncedAt { dict["last_synced_at"] = synced }

        // Custom properties (merged last, can override auto-computed keys)
        dict.merge(customProperties) { _, new in new }

        return dict
    }
}

// MARK: - Engagement Segment Computation

extension UserTraits {

    /// Recomputes `engagementSegment` based on current metric values.
    ///
    /// Call this after updating session counts, streak, or account age.
    /// The method applies the thresholds documented on ``EngagementSegment``.
    mutating func recomputeEngagementSegment() {
        // New users: account less than 7 days old
        if accountAgeDays < 7 {
            engagementSegment = .newUser
            return
        }

        // Power user: 5+ sessions in last 7 days and active within 2 days
        if sessionsLast7Days >= 5 && daysSinceLastSession <= 2 {
            engagementSegment = .powerUser
            return
        }

        // Active: 2+ sessions in last 7 days and active within 7 days
        if sessionsLast7Days >= 2 && daysSinceLastSession <= 7 {
            engagementSegment = .active
            return
        }

        // Casual: at least 1 session in last 30 days and active within 14 days
        if sessionsLast30Days >= 1 && daysSinceLastSession <= 14 {
            engagementSegment = .casual
            return
        }

        // At risk: no recent sessions but came back within 30 days
        if daysSinceLastSession <= 30 {
            engagementSegment = .atRisk
            return
        }

        // Dormant: no activity for over 30 days
        engagementSegment = .dormant
    }

    /// Recomputes `featureAdoptionTier` based on the count of activated features.
    ///
    /// | Count | Tier       |
    /// |-------|------------|
    /// | 0-2   | explorer   |
    /// | 3-5   | adopter    |
    /// | 6-7   | engaged    |
    /// | 8+    | champion   |
    mutating func recomputeFeatureAdoptionTier() {
        let count = featureUsage.activatedFeatureCount
        switch count {
        case 0...2:
            featureAdoptionTier = "explorer"
        case 3...5:
            featureAdoptionTier = "adopter"
        case 6...7:
            featureAdoptionTier = "engaged"
        default:
            featureAdoptionTier = "champion"
        }
    }

    /// Recomputes `accountAgeDays` from the stored `accountCreatedDate`.
    ///
    /// Uses the ISO-8601 date formatter. If the date is nil or unparseable,
    /// `accountAgeDays` is left unchanged.
    mutating func recomputeAccountAge() {
        guard let dateString = accountCreatedDate else { return }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        // Try with fractional seconds first, then without
        if let date = formatter.date(from: dateString) {
            accountAgeDays = max(0, Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0)
            return
        }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            accountAgeDays = max(0, Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0)
        }
    }

    /// Recomputes `daysSinceLastSession` from the stored `lastSessionDate`.
    ///
    /// Uses the ISO-8601 date formatter. If the date is nil or unparseable,
    /// `daysSinceLastSession` is set to `Int.max` to signal unknown/never.
    mutating func recomputeDaysSinceLastSession() {
        guard let dateString = lastSessionDate else {
            // No session ever recorded — treat as very high
            if totalSessionsCompleted == 0 {
                daysSinceLastSession = accountAgeDays
            }
            return
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            daysSinceLastSession = max(0, Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0)
            return
        }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            daysSinceLastSession = max(0, Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0)
        }
    }

    /// Convenience method that recomputes all derived properties at once.
    ///
    /// Call this after bulk-updating raw metrics (e.g. on app launch after
    /// loading persisted traits and fresh data from the backend).
    mutating func recomputeAllDerived() {
        recomputeAccountAge()
        recomputeDaysSinceLastSession()
        recomputeEngagementSegment()
        recomputeFeatureAdoptionTier()
    }
}

// MARK: - Device Info Helpers

extension UserTraits {

    /// Returns a new `UserTraits` with device and app context fields populated
    /// from the current runtime environment.
    ///
    /// This is called once on initialisation and on each app launch to capture
    /// any OS or app version changes.
    mutating func populateDeviceInfo() {
        appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        locale = Locale.current.identifier
        timezone = TimeZone.current.identifier

        // Device model (same approach as AnalyticsSDK)
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        deviceModel = machineMirror.children.reduce("") { result, element in
            guard let value = element.value as? Int8, value != 0 else { return result }
            return result + String(UnicodeScalar(UInt8(value)))
        }
    }
}
