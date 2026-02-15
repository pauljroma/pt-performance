//
//  Attribution.swift
//  PTPerformance
//
//  ACP-999: Deep Link Attribution — Attribution tracking models
//  ACP-998: App Store Optimization — ASO metadata models
//

import Foundation

// MARK: - Attribution Data

/// Captures the source of a user's app install or deep link entry.
/// Persisted to UserDefaults on first install and synced to Supabase for analytics.
struct AttributionData: Codable, Equatable {
    /// Marketing source (e.g. "google", "instagram", "referral")
    let source: String?

    /// Marketing medium (e.g. "cpc", "email", "social")
    let medium: String?

    /// Campaign name (e.g. "summer_promo_2026")
    let campaign: String?

    /// Specific content identifier (e.g. "hero_banner_v2")
    let content: String?

    /// Referral code from an invite link
    let referralCode: String?

    /// When the attribution was captured
    let timestamp: Date

    /// Whether this attribution was captured on first install
    let isFirstInstall: Bool

    enum CodingKeys: String, CodingKey {
        case source
        case medium
        case campaign
        case content
        case referralCode = "referral_code"
        case timestamp
        case isFirstInstall = "is_first_install"
    }

    /// Returns true when at least one UTM parameter is present
    var hasUTMParameters: Bool {
        source != nil || medium != nil || campaign != nil || content != nil
    }

    /// Dictionary representation for Supabase insert
    var asDictionary: [String: String] {
        var dict: [String: String] = [:]
        if let source { dict["source"] = source }
        if let medium { dict["medium"] = medium }
        if let campaign { dict["campaign"] = campaign }
        if let content { dict["content"] = content }
        if let referralCode { dict["referral_code"] = referralCode }
        dict["timestamp"] = ISO8601DateFormatter().string(from: timestamp)
        dict["is_first_install"] = isFirstInstall ? "true" : "false"
        return dict
    }
}

// MARK: - Deep Link Event

/// Records a deep link open event with full attribution context.
/// Used for analytics to track which links drive engagement.
struct DeepLinkEvent: Codable {
    /// The raw URL that was opened
    let url: String

    /// Resolved navigation destination
    let destination: String

    /// Attribution data extracted from the URL (if any)
    let attribution: AttributionData?

    /// When the deep link was opened
    let timestamp: Date

    /// The user ID if authenticated at time of event
    let userId: String?

    enum CodingKeys: String, CodingKey {
        case url
        case destination
        case attribution
        case timestamp
        case userId = "user_id"
    }
}

// MARK: - Deferred Deep Link

/// A deep link stored server-side that's retrieved after first app launch.
/// Enables attribution when a user clicks a link before installing the app.
struct DeferredDeepLink: Codable {
    /// Unique identifier
    let id: String

    /// The URL the user originally clicked
    let url: String

    /// Device fingerprint for matching (IP + user agent hash)
    let fingerprint: String

    /// When the deferred deep link was created
    let createdAt: Date

    /// When the deferred deep link was claimed (nil if unclaimed)
    let claimedAt: Date?

    /// Whether this link has been consumed
    let isClaimed: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case url
        case fingerprint
        case createdAt = "created_at"
        case claimedAt = "claimed_at"
        case isClaimed = "is_claimed"
    }
}

// MARK: - ASO Metadata

/// App Store Optimization metadata for keyword and subtitle management.
/// Used by ASOService to track and iterate on store listing performance.
struct ASOMetadata: Codable {
    /// Primary keywords for App Store search ranking (max 100 chars total)
    let keywords: [String]

    /// App subtitle displayed below the name (max 30 chars)
    let subtitle: String

    /// Promotional text shown at top of description (max 170 chars, can be updated without review)
    let promotionalText: String

    /// Version of the metadata for A/B tracking
    let version: Int

    /// When this metadata version was last updated
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case keywords
        case subtitle
        case promotionalText = "promotional_text"
        case version
        case updatedAt = "updated_at"
    }

    /// Total character count of keywords (App Store limit: 100)
    var keywordCharacterCount: Int {
        keywords.joined(separator: ",").count
    }

    /// Whether keywords are within the App Store character limit
    var keywordsWithinLimit: Bool {
        keywordCharacterCount <= 100
    }

    /// Whether subtitle is within the App Store character limit
    var subtitleWithinLimit: Bool {
        subtitle.count <= 30
    }
}

// MARK: - Review Prompt State

/// Tracks state for smart App Store review prompting.
/// Ensures review prompts respect Apple's guidelines and user experience.
struct ReviewPromptState: Codable {
    /// Total session count since install
    var sessionCount: Int

    /// Number of workouts completed
    var workoutsCompleted: Int

    /// Number of achievements unlocked
    var achievementsUnlocked: Int

    /// Last time the review prompt was shown
    var lastPromptDate: Date?

    /// Last time SKStoreReviewController was triggered
    var lastSystemReviewDate: Date?

    /// Whether the user has dismissed the prompt permanently
    var permanentlyDismissed: Bool

    /// Number of times the inline prompt has been shown
    var promptShownCount: Int

    /// User's last selected star rating (nil if never rated)
    var lastSelectedRating: Int?

    enum CodingKeys: String, CodingKey {
        case sessionCount = "session_count"
        case workoutsCompleted = "workouts_completed"
        case achievementsUnlocked = "achievements_unlocked"
        case lastPromptDate = "last_prompt_date"
        case lastSystemReviewDate = "last_system_review_date"
        case permanentlyDismissed = "permanently_dismissed"
        case promptShownCount = "prompt_shown_count"
        case lastSelectedRating = "last_selected_rating"
    }

    /// Default initial state
    static let initial = ReviewPromptState(
        sessionCount: 0,
        workoutsCompleted: 0,
        achievementsUnlocked: 0,
        lastPromptDate: nil,
        lastSystemReviewDate: nil,
        permanentlyDismissed: false,
        promptShownCount: 0,
        lastSelectedRating: nil
    )

    /// Whether enough sessions have been completed to justify a prompt
    var hasMinimumSessions: Bool {
        sessionCount >= 3
    }

    /// Whether the 60-day cooldown has elapsed since the last system review request
    var systemReviewCooldownElapsed: Bool {
        guard let lastDate = lastSystemReviewDate else { return true }
        let daysSinceLastReview = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        return daysSinceLastReview >= 60
    }

    /// Whether the 60-day cooldown has elapsed since the last inline prompt
    var inlinePromptCooldownElapsed: Bool {
        guard let lastDate = lastPromptDate else { return true }
        let daysSinceLastPrompt = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        return daysSinceLastPrompt >= 60
    }

    /// Whether the user is eligible for a review prompt
    var isEligibleForPrompt: Bool {
        !permanentlyDismissed
            && hasMinimumSessions
            && inlinePromptCooldownElapsed
    }
}
