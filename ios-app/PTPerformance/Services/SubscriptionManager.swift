//
//  SubscriptionManager.swift
//  PTPerformance
//
//  ACP-986: Subscription Tier Architecture
//  ACP-987: StoreKit 2 Integration
//
//  ObservableObject wrapper around StoreKitService that provides a clean
//  interface for subscription state management, feature gating, and tier caching.
//

import Foundation
import Combine
import SwiftUI
import StoreKit

// MARK: - Subscription Manager

/// Central manager for subscription state, tier management, and feature gating.
///
/// `SubscriptionManager` wraps `StoreKitService` and provides a simplified,
/// high-level API for the rest of the app to check subscription status and
/// feature access. It observes StoreKitService changes and maintains a local
/// cache in UserDefaults as a fallback for offline scenarios.
///
/// ## Usage
/// ```swift
/// // Check feature access
/// if SubscriptionManager.shared.canAccess(.aiCoaching) {
///     // Show AI coaching UI
/// }
///
/// // Use as environment object
/// .environmentObject(SubscriptionManager.shared)
/// ```
///
/// ## Thread Safety
/// All published properties are updated on MainActor via Combine observation
/// of the MainActor-isolated StoreKitService.
@MainActor
final class SubscriptionManager: ObservableObject {

    // MARK: - Singleton

    static let shared = SubscriptionManager()

    // MARK: - Published Properties

    /// The user's current subscription tier
    @Published private(set) var currentTier: SubscriptionTier = .free

    /// Whether the user has any active paid subscription (Pro or Elite)
    @Published private(set) var isSubscribed: Bool = false

    /// The expiration date of the current subscription, if available
    @Published private(set) var expirationDate: Date?

    /// Whether the user is currently in a free trial period
    @Published private(set) var isInTrialPeriod: Bool = false

    /// Whether the user is in a billing grace period
    @Published private(set) var isInGracePeriod: Bool = false

    /// Whether the subscription data is still being loaded
    @Published private(set) var isLoading: Bool = true

    // MARK: - Private Properties

    private let logger = DebugLogger.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UserDefaults Keys

    private enum CacheKeys {
        static let tier = "cached_subscription_tier"
        static let isSubscribed = "cached_is_subscribed"
        static let expirationDate = "cached_expiration_date"
        static let isInTrial = "cached_is_in_trial"
    }

    // MARK: - Initialization

    private init() {
        logger.info("SubscriptionManager", "Initializing SubscriptionManager")

        // Load cached tier from UserDefaults as initial state (offline fallback)
        loadCachedState()

        // Observe StoreKitService for real-time updates
        observeStoreKitService()

        logger.success("SubscriptionManager", "Initialized with cached tier: \(currentTier.displayName)")
    }

    // MARK: - Feature Gating

    /// Check whether the current subscription tier grants access to a feature.
    ///
    /// This is the primary API for feature gating throughout the app.
    ///
    /// - Parameter feature: The feature to check access for
    /// - Returns: True if the user's current tier includes the feature
    func canAccess(_ feature: SubscriptionTier.Feature) -> Bool {
        let hasAccess = currentTier.hasAccess(to: feature)
        logger.diagnostic("SubscriptionManager: canAccess(\(feature.rawValue)) = \(hasAccess) (tier: \(currentTier.displayName))")
        return hasAccess
    }

    /// Returns the minimum tier required for a given feature.
    ///
    /// Useful for displaying upgrade prompts with the correct target tier.
    ///
    /// - Parameter feature: The feature to check
    /// - Returns: The lowest tier that grants access to the feature
    func minimumTier(for feature: SubscriptionTier.Feature) -> SubscriptionTier {
        return SubscriptionTier.minimumTier(for: feature)
    }

    /// Check whether the user's tier is at least as high as the specified tier.
    ///
    /// - Parameter tier: The tier to compare against
    /// - Returns: True if the current tier meets or exceeds the specified tier
    func hasAtLeastTier(_ tier: SubscriptionTier) -> Bool {
        return currentTier.isAtLeast(tier)
    }

    // MARK: - Subscription Actions (Delegated to StoreKitService)

    /// Restore previous purchases from the App Store.
    func restorePurchases() async {
        logger.info("SubscriptionManager", "Restoring purchases")
        await StoreKitService.shared.restorePurchases()
    }

    /// Open the App Store subscription management page.
    func openManageSubscriptions() async {
        logger.info("SubscriptionManager", "Opening subscription management")
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            do {
                try await AppStore.showManageSubscriptions(in: windowScene)
            } catch {
                logger.error("SubscriptionManager", "Failed to open manage subscriptions: \(error.localizedDescription)")
                // Fallback: Open the Settings app subscription management URL
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    await UIApplication.shared.open(url)
                }
            }
        }
    }

    // MARK: - Cache Management

    /// Load cached subscription state from UserDefaults.
    ///
    /// This provides immediate tier info on cold start before StoreKit
    /// has finished verifying entitlements with Apple servers.
    private func loadCachedState() {
        let defaults = UserDefaults.standard

        if let tierString = defaults.string(forKey: CacheKeys.tier),
           let cachedTier = SubscriptionTier(rawValue: tierString) {
            currentTier = cachedTier
            logger.diagnostic("SubscriptionManager: Loaded cached tier: \(cachedTier.displayName)")
        }

        isSubscribed = defaults.bool(forKey: CacheKeys.isSubscribed)

        if let expirationInterval = defaults.object(forKey: CacheKeys.expirationDate) as? TimeInterval {
            expirationDate = Date(timeIntervalSince1970: expirationInterval)
        }

        isInTrialPeriod = defaults.bool(forKey: CacheKeys.isInTrial)
    }

    /// Persist current subscription state to UserDefaults.
    ///
    /// Called whenever StoreKitService state changes. Provides offline
    /// fallback for tier checking when StoreKit is unavailable.
    private func persistState() {
        let defaults = UserDefaults.standard
        defaults.set(currentTier.rawValue, forKey: CacheKeys.tier)
        defaults.set(isSubscribed, forKey: CacheKeys.isSubscribed)
        defaults.set(isInTrialPeriod, forKey: CacheKeys.isInTrial)

        if let expDate = expirationDate {
            defaults.set(expDate.timeIntervalSince1970, forKey: CacheKeys.expirationDate)
        } else {
            defaults.removeObject(forKey: CacheKeys.expirationDate)
        }

        logger.diagnostic("SubscriptionManager: Persisted state to UserDefaults (tier: \(currentTier.displayName))")
    }

    // MARK: - StoreKitService Observation

    /// Observe changes from StoreKitService and sync to local state.
    private func observeStoreKitService() {
        let storeKit = StoreKitService.shared

        // Observe tier changes
        storeKit.$currentTier
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newTier in
                guard let self = self else { return }
                let oldTier = self.currentTier
                self.currentTier = newTier
                if oldTier != newTier {
                    self.logger.info("SubscriptionManager", "Tier updated: \(oldTier.displayName) -> \(newTier.displayName)")
                }
                self.persistState()
            }
            .store(in: &cancellables)

        // Observe premium status (maps to isSubscribed)
        storeKit.$isPremium
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPremium in
                guard let self = self else { return }
                self.isSubscribed = isPremium
                self.persistState()
            }
            .store(in: &cancellables)

        // Observe expiration date
        storeKit.$subscriptionExpirationDate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] date in
                guard let self = self else { return }
                self.expirationDate = date
                self.persistState()
            }
            .store(in: &cancellables)

        // Observe trial period
        storeKit.$isInTrialPeriod
            .receive(on: DispatchQueue.main)
            .sink { [weak self] inTrial in
                guard let self = self else { return }
                self.isInTrialPeriod = inTrial
                self.persistState()
            }
            .store(in: &cancellables)

        // Observe grace period from subscription status
        storeKit.$subscriptionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                self.isInGracePeriod = (status == .gracePeriod)
                self.isLoading = false
            }
            .store(in: &cancellables)

        // Observe loading state
        storeKit.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                guard let self = self else { return }
                self.isLoading = loading
            }
            .store(in: &cancellables)
    }

    // MARK: - Formatted Display Helpers

    private static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// Formatted string for the subscription expiration date.
    var formattedExpirationDate: String? {
        guard let date = expirationDate else { return nil }
        return Self.mediumDateFormatter.string(from: date)
    }

    /// Human-readable status summary.
    var statusSummary: String {
        if isInGracePeriod {
            return "Billing issue - update payment method"
        }
        if isInTrialPeriod {
            return "Free trial active"
        }
        if isSubscribed {
            if let expDate = formattedExpirationDate {
                return "\(currentTier.displayName) - renews \(expDate)"
            }
            return "\(currentTier.displayName) active"
        }
        return "Free plan"
    }

    /// Returns the days remaining until subscription expires, or nil if no expiration.
    var daysUntilExpiration: Int? {
        guard let date = expirationDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: date)
        return components.day
    }
}
