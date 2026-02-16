//
//  UserPropertyManager.swift
//  PTPerformance
//
//  ACP-961: User Properties & Traits
//  Manages user trait collection, computation, persistence, and synchronisation
//  with the AnalyticsSDK. Acts as the single entry point for reading and
//  writing user-level properties throughout the app.
//
//  ## Architecture
//  - Traits are persisted to a JSON file in the caches directory.
//  - On each `syncToAnalytics()` call, the flattened trait dictionary is
//    forwarded to `AnalyticsSDK.identify(userId:traits:)`.
//  - Derived properties (engagement segment, feature adoption tier, account
//    age, days-since-last-session) are recomputed before every sync.
//  - Thread safety is guaranteed by the actor isolation model.
//
//  ## Privacy
//  No PII (email, name, etc.) is ever stored or transmitted. Only anonymised
//  behavioural signals and opaque identifiers are persisted.
//

import Foundation
import UIKit

// MARK: - UserPropertyManager

/// Actor-based manager for user properties and traits.
///
/// `UserPropertyManager` owns the lifecycle of ``UserTraits``:
/// 1. **Restore** — traits are loaded from disk on init.
/// 2. **Enrich** — callers update traits via strongly-typed setters.
/// 3. **Compute** — derived segments are recalculated before sync.
/// 4. **Persist** — traits are saved to disk after every mutation.
/// 5. **Sync** — the flattened dictionary is pushed to `AnalyticsSDK`.
///
/// ## Quick Start
/// ```swift
/// // On app launch
/// await UserPropertyManager.shared.onAppLaunch(userId: "abc-123", role: "patient")
///
/// // After a session is completed
/// await UserPropertyManager.shared.recordSessionCompleted()
///
/// // Set a feature flag
/// await UserPropertyManager.shared.markFeatureUsed(.aiChat)
///
/// // Set custom property
/// await UserPropertyManager.shared.setCustomProperty("preferred_sport", value: "baseball")
///
/// // Read current traits snapshot
/// let traits = await UserPropertyManager.shared.currentTraits
/// ```
actor UserPropertyManager {

    // MARK: - Singleton

    static let shared = UserPropertyManager()

    // MARK: - Properties

    /// The current in-memory user traits.
    private var traits = UserTraits()

    /// Logger instance matching the codebase convention.
    private let logger = DebugLogger.shared

    /// ISO-8601 formatter shared across the actor (no fractional seconds for writes).
    private nonisolated static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    /// File URL for the persisted traits JSON.
    private let fileURL: URL

    /// File name for the persisted traits.
    private nonisolated static let fileName = "user_traits.json"

    // MARK: - JSON Encoder / Decoder

    private nonisolated static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private nonisolated static let decoder: JSONDecoder = {
        JSONDecoder()
    }()

    // MARK: - Initialisation

    private init() {
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.fileURL = cachesDir.appendingPathComponent(Self.fileName)
        loadFromDisk()
        logger.info("UserPropertyManager", "Initialized (userId=\(traits.userId ?? "nil"), segment=\(traits.engagementSegment.rawValue))")
    }

    // MARK: - Public Read API

    /// Returns a snapshot of the current user traits.
    ///
    /// This is a value-type copy; mutations to the returned value do not
    /// affect the manager's internal state.
    var currentTraits: UserTraits {
        traits
    }

    /// Returns the current engagement segment.
    var engagementSegment: EngagementSegment {
        traits.engagementSegment
    }

    /// Returns the current subscription tier stored in traits.
    var subscriptionTier: SubscriptionTier {
        traits.subscriptionTier
    }

    /// Returns the flattened traits dictionary, ready for analytics.
    var traitsDictionary: [String: String] {
        traits.asDictionary()
    }

    // MARK: - Lifecycle

    /// Call on every app launch to initialise identity, refresh device info,
    /// increment launch count, recompute derived properties, and sync.
    ///
    /// - Parameters:
    ///   - userId: The authenticated user's opaque identifier.
    ///   - role: The user's role as a raw string (e.g. "patient", "therapist").
    ///     Pass `UserRole.rawValue` from the existing `UserRole` enum.
    ///   - accountCreatedDate: Optional account creation date. When provided for
    ///     the first time, it is persisted and used for account-age calculations.
    ///   - subscriptionTier: The user's current subscription tier.
    ///   - isTrialActive: Whether the user is currently in a free trial.
    ///   - subscriptionExpirationDate: Optional expiration date for the subscription.
    func onAppLaunch(
        userId: String,
        role: String = "unknown",
        accountCreatedDate: Date? = nil,
        subscriptionTier: SubscriptionTier = .free,
        isTrialActive: Bool = false,
        subscriptionExpirationDate: Date? = nil
    ) async {
        traits.userId = userId
        traits.role = role

        // Subscription
        traits.subscriptionTier = subscriptionTier
        traits.isTrialActive = isTrialActive
        if let expDate = subscriptionExpirationDate {
            traits.subscriptionExpirationDate = Self.isoFormatter.string(from: expDate)
        }

        // Account creation (set once, never overwritten)
        if traits.accountCreatedDate == nil, let created = accountCreatedDate {
            traits.accountCreatedDate = Self.isoFormatter.string(from: created)
        }

        // Device info (refreshed every launch in case of OS / app update)
        traits.populateDeviceInfo()

        // Increment launch counter
        traits.totalAppLaunches += 1

        // Recompute all derived properties
        traits.recomputeAllDerived()

        // Persist and sync
        saveToDisk()
        await syncToAnalytics()

        logger.info("UserPropertyManager", "onAppLaunch completed (launches=\(traits.totalAppLaunches), segment=\(traits.engagementSegment.rawValue))")
    }

    /// Call on logout to clear identity-specific data while preserving device info.
    ///
    /// Feature usage flags and launch counts are preserved because they are
    /// device-scoped. Identity, subscription, and engagement metrics are cleared.
    func onLogout() {
        traits.userId = nil
        traits.role = "unknown"
        traits.subscriptionTier = .free
        traits.isTrialActive = false
        traits.subscriptionExpirationDate = nil
        traits.accountCreatedDate = nil
        traits.accountAgeDays = 0
        traits.firstSessionDate = nil
        traits.lastSessionDate = nil
        traits.totalSessionsCompleted = 0
        traits.sessionsLast7Days = 0
        traits.sessionsLast30Days = 0
        traits.currentStreak = 0
        traits.longestStreak = 0
        traits.daysSinceLastSession = 0
        traits.engagementSegment = .newUser
        traits.customProperties = [:]
        traits.lastSyncedAt = nil

        saveToDisk()
        logger.info("UserPropertyManager", "User traits reset on logout")
    }

    // MARK: - Subscription Updates

    /// Update the user's subscription tier.
    ///
    /// Persists immediately and triggers an analytics sync so the backend
    /// reflects the tier change in near-real-time.
    ///
    /// - Parameters:
    ///   - tier: The new subscription tier.
    ///   - isTrialActive: Whether the user is on a trial for this tier.
    ///   - expirationDate: Optional subscription expiration date.
    func updateSubscription(
        tier: SubscriptionTier,
        isTrialActive: Bool = false,
        expirationDate: Date? = nil
    ) async {
        traits.subscriptionTier = tier
        traits.isTrialActive = isTrialActive
        if let exp = expirationDate {
            traits.subscriptionExpirationDate = Self.isoFormatter.string(from: exp)
        } else {
            traits.subscriptionExpirationDate = nil
        }

        saveToDisk()
        await syncToAnalytics()

        logger.info("UserPropertyManager", "Subscription updated: tier=\(tier.rawValue), trial=\(isTrialActive)")
    }

    // MARK: - Session Tracking

    /// Record that the user completed a workout session.
    ///
    /// Increments `totalSessionsCompleted`, updates `lastSessionDate`,
    /// sets `firstSessionDate` if this is the first session, marks the
    /// `hasCompletedWorkout` feature flag, and recomputes derived segments.
    func recordSessionCompleted() async {
        let now = Date()
        let nowString = Self.isoFormatter.string(from: now)

        traits.totalSessionsCompleted += 1

        if traits.firstSessionDate == nil {
            traits.firstSessionDate = nowString
        }
        traits.lastSessionDate = nowString

        // Feature flag (latched)
        traits.featureUsage.hasCompletedWorkout = true

        // Recompute derived properties
        traits.recomputeAllDerived()

        saveToDisk()
        await syncToAnalytics()

        logger.info("UserPropertyManager", "Session recorded (total=\(traits.totalSessionsCompleted), segment=\(traits.engagementSegment.rawValue))")
    }

    /// Bulk-update session window counters (e.g. from a backend query).
    ///
    /// Use this when fetching aggregated session counts from the server to
    /// keep local traits accurate without relying solely on local increments.
    ///
    /// - Parameters:
    ///   - last7Days: Sessions completed in the trailing 7-day window.
    ///   - last30Days: Sessions completed in the trailing 30-day window.
    ///   - total: Total lifetime sessions (optional; only updates if provided).
    func updateSessionCounts(last7Days: Int, last30Days: Int, total: Int? = nil) async {
        traits.sessionsLast7Days = last7Days
        traits.sessionsLast30Days = last30Days
        if let total = total {
            traits.totalSessionsCompleted = total
        }

        traits.recomputeAllDerived()
        saveToDisk()
        await syncToAnalytics()
    }

    // MARK: - Streak Updates

    /// Update the current and longest streak values.
    ///
    /// Typically called by `StreakService` after a streak change.
    ///
    /// - Parameters:
    ///   - current: The current consecutive-day streak.
    ///   - longest: The all-time longest streak.
    func updateStreak(current: Int, longest: Int) {
        traits.currentStreak = current
        traits.longestStreak = max(traits.longestStreak, longest)
        saveToDisk()
    }

    // MARK: - Feature Usage

    /// Named feature keys for type-safe feature flag updates.
    enum FeatureKey: String, Sendable {
        case workout = "workout"
        case aiChat = "ai_chat"
        case nutrition = "nutrition"
        case readiness = "readiness"
        case healthKit = "healthkit"
        case wearable = "wearable"
        case substitution = "substitution"
        case programs = "programs"
        case share = "share"
        case notifications = "notifications"
    }

    /// Mark a feature as used (latched — never resets to false).
    ///
    /// After setting the flag, the feature adoption tier is recomputed
    /// and traits are persisted.
    ///
    /// - Parameter feature: The feature that was used.
    func markFeatureUsed(_ feature: FeatureKey) {
        switch feature {
        case .workout:
            traits.featureUsage.hasCompletedWorkout = true
        case .aiChat:
            traits.featureUsage.hasUsedAIChat = true
        case .nutrition:
            traits.featureUsage.hasLoggedNutrition = true
        case .readiness:
            traits.featureUsage.hasViewedReadiness = true
        case .healthKit:
            traits.featureUsage.hasConnectedHealthKit = true
        case .wearable:
            traits.featureUsage.hasConnectedWearable = true
        case .substitution:
            traits.featureUsage.hasUsedSubstitution = true
        case .programs:
            traits.featureUsage.hasUsedPrograms = true
        case .share:
            traits.featureUsage.hasSharedContent = true
        case .notifications:
            traits.featureUsage.hasEnabledNotifications = true
        }

        traits.recomputeFeatureAdoptionTier()
        saveToDisk()

        logger.info("UserPropertyManager", "Feature used: \(feature.rawValue) (adoption=\(traits.featureAdoptionTier))")
    }

    // MARK: - Custom Properties

    /// Set a custom key-value property.
    ///
    /// Custom properties are merged into the analytics traits dictionary
    /// and can override auto-computed keys. Use sparingly for experiment
    /// bucketing, A/B test variants, and similar ad-hoc annotations.
    ///
    /// - Parameters:
    ///   - key: The property key (snake_case recommended).
    ///   - value: The property value as a string.
    func setCustomProperty(_ key: String, value: String) {
        traits.customProperties[key] = value
        saveToDisk()
    }

    /// Remove a custom property by key.
    ///
    /// - Parameter key: The property key to remove.
    func removeCustomProperty(_ key: String) {
        traits.customProperties.removeValue(forKey: key)
        saveToDisk()
    }

    /// Set multiple custom properties at once.
    ///
    /// Existing keys are overwritten; keys not present in `properties` are
    /// left unchanged.
    ///
    /// - Parameter properties: Dictionary of custom properties to merge.
    func setCustomProperties(_ properties: [String: String]) {
        traits.customProperties.merge(properties) { _, new in new }
        saveToDisk()
    }

    /// Returns the value of a custom property, or `nil` if not set.
    ///
    /// - Parameter key: The property key to look up.
    /// - Returns: The string value, or `nil`.
    func customProperty(forKey key: String) -> String? {
        traits.customProperties[key]
    }

    // MARK: - Analytics Sync

    /// Recomputes all derived properties and pushes the full trait set
    /// to `AnalyticsSDK.identify(userId:traits:)`.
    ///
    /// This is automatically called by `onAppLaunch`, `recordSessionCompleted`,
    /// `updateSubscription`, and `updateSessionCounts`. You can also call it
    /// manually after batching multiple trait mutations.
    func syncToAnalytics() async {
        // Recompute before sync
        traits.recomputeAllDerived()

        // Timestamp the sync
        traits.lastSyncedAt = Self.isoFormatter.string(from: Date())
        saveToDisk()

        // Build the flat dictionary
        let flatTraits = traits.asDictionary()

        // Forward to AnalyticsSDK
        guard let userId = traits.userId else {
            logger.warning("UserPropertyManager", "syncToAnalytics skipped: no userId set")
            return
        }

        await AnalyticsSDK.shared.identify(userId: userId, traits: flatTraits)

        logger.info("UserPropertyManager", "Synced \(flatTraits.count) traits to AnalyticsSDK")
    }

    // MARK: - Persistence

    /// Saves the current traits to disk as JSON.
    private func saveToDisk() {
        do {
            let data = try Self.encoder.encode(traits)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            logger.warning("UserPropertyManager", "Failed to persist traits to disk: \(error.localizedDescription)")
        }
    }

    /// Loads traits from the on-disk JSON file.
    ///
    /// If the file does not exist or is corrupted, the manager starts with
    /// default (empty) traits and the corrupted file is deleted.
    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            let restored = try Self.decoder.decode(UserTraits.self, from: data)
            traits = restored
            logger.info("UserPropertyManager", "Restored traits from disk (userId=\(traits.userId ?? "nil"), segment=\(traits.engagementSegment.rawValue))")
        } catch {
            logger.warning("UserPropertyManager", "Failed to restore traits from disk: \(error.localizedDescription)")
            // Remove the corrupted file so we start fresh
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    // MARK: - Debug / Testing

    /// Returns a human-readable summary of key traits for debug logging.
    var debugSummary: String {
        """
        UserTraits Summary:
          userId: \(traits.userId ?? "nil")
          role: \(traits.role)
          tier: \(traits.subscriptionTier.rawValue)
          segment: \(traits.engagementSegment.rawValue)
          adoption: \(traits.featureAdoptionTier)
          sessions: \(traits.totalSessionsCompleted) total, \(traits.sessionsLast7Days) (7d), \(traits.sessionsLast30Days) (30d)
          streak: \(traits.currentStreak) current, \(traits.longestStreak) best
          launches: \(traits.totalAppLaunches)
          features: \(traits.featureUsage.activatedFeatureCount)/10 activated
          daysSinceLastSession: \(traits.daysSinceLastSession)
          accountAgeDays: \(traits.accountAgeDays)
          appVersion: \(traits.appVersion) (\(traits.buildNumber))
          device: \(traits.deviceModel) / iOS \(traits.osVersion)
          custom: \(traits.customProperties.count) keys
          lastSynced: \(traits.lastSyncedAt ?? "never")
        """
    }

    /// Clears all persisted traits and resets to defaults.
    ///
    /// This is intended for development and testing only. In production,
    /// use `onLogout()` which preserves device-scoped data.
    func resetForTesting() {
        traits = UserTraits()
        try? FileManager.default.removeItem(at: fileURL)
        logger.warning("UserPropertyManager", "Traits reset for testing — all data cleared")
    }
}
