//
//  WinbackService.swift
//  PTPerformance
//
//  ACP-993: Winback Offers — Special pricing for churned subscribers.
//  Detects previously-subscribed users who cancelled, determines their
//  churn window, and surfaces a time-limited discount offer to win them back.
//

import Foundation
import StoreKit
import Combine

// MARK: - Winback Offer Model

/// A time-limited discount offer targeted at churned subscribers.
struct WinbackOffer: Codable, Identifiable, Sendable {
    let id: String
    let discountPercent: Int
    let durationMonths: Int
    let productId: String
    let expiresAt: Date
    let message: String

    /// Whether the offer is still valid (not expired)
    var isValid: Bool {
        expiresAt > Date()
    }

    /// Remaining seconds until the offer expires
    var remainingSeconds: TimeInterval {
        max(0, expiresAt.timeIntervalSince(Date()))
    }

    /// Human-readable discount label, e.g. "50% Off"
    var discountLabel: String {
        "\(discountPercent)% Off"
    }
}

// MARK: - Winback Eligibility

/// Criteria that determined a user's winback eligibility.
struct WinbackEligibility: Codable, Sendable {
    let isEligible: Bool
    let daysSinceChurn: Int?
    let previousTier: String?
    let lastSubscriptionDate: Date?
}

// MARK: - Winback Service

/// Coordinates winback offer detection, presentation, and redemption for churned users.
///
/// ## Offer Tiers
/// | Days Churned | Discount |
/// |:-------------|:---------|
/// | 30-59        | 20%      |
/// | 60-89        | 30%      |
/// | 90+          | 50%      |
///
/// The service attempts to fetch a server-configured offer from Supabase first,
/// falling back to locally-computed defaults based on the churn window.
@MainActor
class WinbackService: ObservableObject {

    // MARK: - Singleton

    static let shared = WinbackService()

    // MARK: - Published Properties

    @Published var winbackOffer: WinbackOffer?
    @Published var isCheckingEligibility: Bool = false
    @Published var isRedeeming: Bool = false
    @Published var redeemError: String?

    // MARK: - Private Properties

    private let logger = DebugLogger.shared
    private let storeKit = StoreKitService.shared

    /// UserDefaults keys for churn tracking
    private enum Keys {
        static let lastSubscriptionDate = "winback_last_subscription_date"
        static let lastSubscriptionTier = "winback_last_subscription_tier"
        static let lastChurnDate = "winback_last_churn_date"
        static let winbackOfferId = "winback_current_offer_id"
        static let winbackDismissed = "winback_offer_dismissed"
        static let winbackRedeemed = "winback_offer_redeemed"
        static let winbackLastCheckDate = "winback_last_check_date"
    }

    // MARK: - Init

    private init() {
        logger.info("Winback", "WinbackService initialized")
    }

    // MARK: - Eligibility Check

    /// Checks whether the current user is eligible for a winback offer.
    ///
    /// Eligibility requires:
    /// 1. User previously held an active subscription
    /// 2. User currently has no active subscription
    /// 3. User has not dismissed or redeemed a winback offer in this window
    /// 4. At least 30 days have passed since churn
    func checkWinbackEligibility() async {
        guard !isCheckingEligibility else { return }
        isCheckingEligibility = true
        defer { isCheckingEligibility = false }

        logger.info("Winback", "Checking winback eligibility")

        // Already redeemed? Skip.
        if UserDefaults.standard.bool(forKey: Keys.winbackRedeemed) {
            logger.info("Winback", "User already redeemed a winback offer")
            return
        }

        // Already dismissed recently? Throttle to once per 7 days.
        if let lastCheck = UserDefaults.standard.object(forKey: Keys.winbackLastCheckDate) as? Date,
           Date().timeIntervalSince(lastCheck) < 7 * 24 * 60 * 60,
           UserDefaults.standard.bool(forKey: Keys.winbackDismissed) {
            logger.info("Winback", "Winback check throttled — dismissed within last 7 days")
            return
        }

        UserDefaults.standard.set(Date(), forKey: Keys.winbackLastCheckDate)

        // If user is currently subscribed, record their subscription for future churn detection.
        if storeKit.isPremium {
            recordActiveSubscription()
            winbackOffer = nil
            logger.info("Winback", "User is currently subscribed — recording state, no winback needed")
            return
        }

        // User is not subscribed. Check if they *were* subscribed before.
        guard let lastSubDate = UserDefaults.standard.object(forKey: Keys.lastSubscriptionDate) as? Date else {
            logger.info("Winback", "No previous subscription on record — not eligible")
            return
        }

        let churnDate = UserDefaults.standard.object(forKey: Keys.lastChurnDate) as? Date ?? lastSubDate
        let daysSinceChurn = Calendar.current.dateComponents([.day], from: churnDate, to: Date()).day ?? 0

        guard daysSinceChurn >= 30 else {
            logger.info("Winback", "Only \(daysSinceChurn) days since churn — minimum 30 required")
            return
        }

        logger.info("Winback", "User eligible for winback — \(daysSinceChurn) days since churn")

        // Attempt server fetch, fall back to local defaults.
        await presentWinbackOffer(daysSinceChurn: daysSinceChurn)
    }

    // MARK: - Present Offer

    /// Fetches a winback offer from the backend or builds one locally based on churn duration.
    func presentWinbackOffer(daysSinceChurn: Int? = nil) async {
        let days = daysSinceChurn ?? computeDaysSinceChurn()
        logger.info("Winback", "Presenting winback offer for \(days) days churned")

        // Try server-side offer first.
        if let serverOffer = await fetchServerOffer() {
            self.winbackOffer = serverOffer
            logger.success("Winback", "Loaded server winback offer: \(serverOffer.discountPercent)% off")
            return
        }

        // Fallback: compute local offer.
        let offer = buildLocalOffer(daysSinceChurn: days)
        self.winbackOffer = offer
        UserDefaults.standard.set(offer.id, forKey: Keys.winbackOfferId)
        logger.success("Winback", "Built local winback offer: \(offer.discountPercent)% off for \(offer.durationMonths) months")
    }

    // MARK: - Redeem Offer

    /// Redeems a winback offer by initiating a StoreKit purchase with the associated promotional offer.
    ///
    /// - Parameter offer: The winback offer to redeem.
    /// - Throws: StoreKit purchase errors or verification failures.
    func redeemWinbackOffer(_ offer: WinbackOffer) async throws {
        guard offer.isValid else {
            logger.warning("Winback", "Attempted to redeem expired offer \(offer.id)")
            redeemError = "This offer has expired. Please check back for new offers."
            return
        }

        isRedeeming = true
        redeemError = nil
        defer { isRedeeming = false }

        logger.info("Winback", "Redeeming winback offer \(offer.id) — \(offer.discountPercent)% off")
        HapticFeedback.medium()

        do {
            // Load products if not already loaded.
            if storeKit.products.isEmpty {
                await storeKit.loadProducts()
            }

            // Find the matching StoreKit product.
            guard let product = storeKit.products.first(where: { $0.id == offer.productId }) else {
                logger.error("Winback", "Product not found for ID: \(offer.productId)")
                redeemError = "Unable to find subscription product. Please try again."
                HapticFeedback.error()
                return
            }

            // Purchase using StoreKit 2.
            try await storeKit.purchase(product)

            // Mark redeemed.
            UserDefaults.standard.set(true, forKey: Keys.winbackRedeemed)
            self.winbackOffer = nil

            // Track conversion.
            await trackWinbackConversion(offer: offer)

            HapticFeedback.success()
            logger.success("Winback", "Winback offer redeemed successfully")

        } catch {
            logger.error("Winback", "Failed to redeem winback offer: \(error.localizedDescription)")
            redeemError = error.localizedDescription
            HapticFeedback.error()
            throw error
        }
    }

    // MARK: - Dismiss

    /// Records that the user dismissed the current winback offer.
    func dismissOffer() {
        logger.info("Winback", "User dismissed winback offer")
        UserDefaults.standard.set(true, forKey: Keys.winbackDismissed)
        UserDefaults.standard.set(Date(), forKey: Keys.winbackLastCheckDate)
        winbackOffer = nil
        HapticFeedback.light()
    }

    // MARK: - Private Helpers

    /// Records the current subscription state for future churn detection.
    private func recordActiveSubscription() {
        UserDefaults.standard.set(Date(), forKey: Keys.lastSubscriptionDate)
        UserDefaults.standard.set(storeKit.currentTier.rawValue, forKey: Keys.lastSubscriptionTier)
        // Clear any previous churn/dismiss state.
        UserDefaults.standard.removeObject(forKey: Keys.lastChurnDate)
        UserDefaults.standard.set(false, forKey: Keys.winbackDismissed)
        UserDefaults.standard.set(false, forKey: Keys.winbackRedeemed)
    }

    /// Computes days since the user churned, falling back to 0.
    private func computeDaysSinceChurn() -> Int {
        guard let churnDate = UserDefaults.standard.object(forKey: Keys.lastChurnDate) as? Date
                ?? UserDefaults.standard.object(forKey: Keys.lastSubscriptionDate) as? Date else {
            return 0
        }
        return Calendar.current.dateComponents([.day], from: churnDate, to: Date()).day ?? 0
    }

    /// Builds a local winback offer based on churn duration.
    private func buildLocalOffer(daysSinceChurn: Int) -> WinbackOffer {
        let discount: Int
        let duration: Int
        let message: String

        switch daysSinceChurn {
        case 30..<60:
            discount = 20
            duration = 1
            message = "We have missed you! Come back and save 20% on your first month."
        case 60..<90:
            discount = 30
            duration = 2
            message = "A lot has changed since you left. Enjoy 30% off for 2 months."
        default: // 90+
            discount = 50
            duration = 3
            message = "Welcome back! Here is an exclusive 50% discount for 3 months."
        }

        let previousTier = UserDefaults.standard.string(forKey: Keys.lastSubscriptionTier) ?? "pro"
        let productId: String
        if previousTier == "elite" {
            productId = SubscriptionTier.elite.monthlyProductId ?? Config.Subscription.monthlyProductID
        } else {
            productId = Config.Subscription.monthlyProductID
        }

        // Offer expires in 72 hours.
        let expiresAt = Calendar.current.date(byAdding: .hour, value: 72, to: Date()) ?? Date()

        return WinbackOffer(
            id: UUID().uuidString,
            discountPercent: discount,
            durationMonths: duration,
            productId: productId,
            expiresAt: expiresAt,
            message: message
        )
    }

    /// Attempts to fetch a server-configured winback offer from Supabase.
    private func fetchServerOffer() async -> WinbackOffer? {
        guard let userId = PTSupabaseClient.shared.userId else {
            logger.diagnostic("Winback: No userId — skipping server offer fetch")
            return nil
        }

        do {
            let response: [WinbackOffer] = try await PTSupabaseClient.shared.client
                .from("winback_offers")
                .select()
                .eq("user_id", value: userId)
                .eq("status", value: "active")
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value

            return response.first
        } catch {
            logger.warning("Winback", "Failed to fetch server winback offer: \(error.localizedDescription)")
            return nil
        }
    }

    /// Tracks a successful winback conversion for analytics.
    private func trackWinbackConversion(offer: WinbackOffer) async {
        guard let userId = PTSupabaseClient.shared.userId else { return }

        do {
            let event: [String: String] = [
                "user_id": userId,
                "offer_id": offer.id,
                "discount_percent": "\(offer.discountPercent)",
                "product_id": offer.productId,
                "event": "winback_redeemed"
            ]

            try await PTSupabaseClient.shared.client
                .from("monetization_events")
                .insert(event)
                .execute()

            logger.success("Winback", "Winback conversion tracked")
        } catch {
            logger.warning("Winback", "Failed to track winback conversion: \(error.localizedDescription)")
        }
    }

    // MARK: - Churn Detection (called when subscription lapses)

    /// Call this when the subscription status changes to expired or none
    /// to record the churn date for future winback eligibility.
    func recordChurn() {
        guard !storeKit.isPremium else { return }

        if UserDefaults.standard.object(forKey: Keys.lastSubscriptionDate) != nil,
           UserDefaults.standard.object(forKey: Keys.lastChurnDate) == nil {
            UserDefaults.standard.set(Date(), forKey: Keys.lastChurnDate)
            logger.info("Winback", "Churn date recorded")
        }
    }
}
