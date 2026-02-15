//
//  LimitedTimeOfferService.swift
//  PTPerformance
//
//  ACP-1011: Limited Time Offers — Time-bound promotional offers engine
//  Manages fetching, display, expiry, and dismissal of promotional offers.
//

import Foundation
import Combine

// MARK: - Limited Time Offer Service

/// Manages time-bound promotional offers for subscription and add-on products.
///
/// Fetches active offers from Supabase, displays them as banners, and
/// automatically dismisses expired offers. Supports countdown timer display
/// and session-based dismiss/re-show behavior.
///
/// ## Offer Lifecycle
/// 1. Fetch active offers from backend on app launch
/// 2. Display banner if an active offer exists
/// 3. Countdown timer ticks in real-time
/// 4. Offer auto-dismissed when expired
/// 5. Dismissed offers re-appear next app session
///
/// ## Usage
/// ```swift
/// let service = LimitedTimeOfferService.shared
/// await service.fetchActiveOffers()
///
/// if let offer = service.activeOffer {
///     // Show LimitedTimeOfferBanner
/// }
/// ```
@MainActor
class LimitedTimeOfferService: ObservableObject {

    // MARK: - Singleton

    static let shared = LimitedTimeOfferService()

    // MARK: - Dependencies

    private let supabase: PTSupabaseClient
    private let logger: DebugLogger

    // MARK: - Constants

    private enum Constants {
        static let offersTable = "limited_time_offers"
        static let dismissedOffersKey = "dismissed_lto_ids_session"
        static let expiryCheckInterval: TimeInterval = 60 // Check every minute
    }

    // MARK: - Published Properties

    /// The currently active offer to display, if any
    @Published var activeOffer: LimitedTimeOffer?

    /// All active offers (may be more than one; we show the most relevant)
    @Published var allActiveOffers: [LimitedTimeOffer] = []

    /// Loading state
    @Published var isLoading = false

    /// Countdown components for the active offer
    @Published var countdownHours: Int = 0
    @Published var countdownMinutes: Int = 0
    @Published var countdownSeconds: Int = 0

    /// Whether the active offer banner has been dismissed this session
    @Published var isDismissedThisSession = false

    // MARK: - Private Properties

    private var expiryTimer: Timer?
    private var countdownTimer: Timer?
    private var dismissedOfferIds: Set<String> = []

    // MARK: - Initialization

    init(
        supabase: PTSupabaseClient = .shared,
        logger: DebugLogger = .shared
    ) {
        self.supabase = supabase
        self.logger = logger
        logger.info("LimitedTimeOfferService", "Initializing LTO engine")
    }

    deinit {
        expiryTimer?.invalidate()
        countdownTimer?.invalidate()
    }

    // MARK: - Fetch Active Offers

    /// Fetches currently active offers from Supabase.
    ///
    /// Filters for offers where the current date falls between `startDate` and `endDate`.
    /// Falls back to demo data if the server request fails.
    func fetchActiveOffers() async {
        logger.diagnostic("LimitedTimeOfferService: Fetching active offers")
        isLoading = true
        defer { isLoading = false }

        do {
            let now = ISO8601DateFormatter().string(from: Date())

            let response = try await supabase.client
                .from(Constants.offersTable)
                .select()
                .lte("start_date", value: now)
                .gte("end_date", value: now)
                .order("discount_percent", ascending: false)
                .execute()

            let decoder = PTSupabaseClient.flexibleDecoder
            let offers = try decoder.decode([LimitedTimeOffer].self, from: response.data)
            allActiveOffers = offers

            // Select the best offer (highest discount, not dismissed)
            selectBestOffer()

            logger.success("LimitedTimeOfferService", "Fetched \(offers.count) active offers")
        } catch {
            logger.warning("LimitedTimeOfferService", "Failed to fetch offers: \(error.localizedDescription). Using demo offer.")
            allActiveOffers = [LimitedTimeOffer.demoOffer]
            selectBestOffer()
        }

        startExpiryChecks()
        startCountdownTimer()
    }

    // MARK: - Offer Expiry

    /// Checks if the active offer has expired and dismisses it if so.
    func checkOfferExpiry() {
        guard let offer = activeOffer else { return }

        if offer.hasExpired {
            logger.info("LimitedTimeOfferService", "Offer expired: \(offer.title)")
            activeOffer = nil
            stopCountdownTimer()
            selectBestOffer()
        }
    }

    // MARK: - Dismiss Offer

    /// Dismisses the active offer banner for the current session.
    /// The offer will re-appear on the next app launch.
    func dismissCurrentOffer() {
        guard let offer = activeOffer else { return }

        logger.info("LimitedTimeOfferService", "User dismissed offer: \(offer.title)")
        dismissedOfferIds.insert(offer.id)
        isDismissedThisSession = true
        stopCountdownTimer()
    }

    /// Resets session-based dismissals (call on app foreground).
    func resetSessionDismissals() {
        logger.diagnostic("LimitedTimeOfferService: Resetting session dismissals")
        dismissedOfferIds.removeAll()
        isDismissedThisSession = false
        selectBestOffer()
        startCountdownTimer()
    }

    // MARK: - Claim Offer

    /// Returns the product ID for the active offer so the paywall can be presented.
    ///
    /// - Returns: The product ID string, or nil if no active offer
    func claimOffer() -> String? {
        guard let offer = activeOffer else { return nil }
        logger.info("LimitedTimeOfferService", "User claiming offer: \(offer.title) for product: \(offer.productId)")

        // Track the claim event
        Task {
            await trackOfferClaim(offer)
        }

        return offer.productId
    }

    // MARK: - Private: Offer Selection

    /// Selects the best available offer that has not been dismissed.
    private func selectBestOffer() {
        let eligibleOffers = allActiveOffers.filter {
            $0.isActive && !dismissedOfferIds.contains($0.id)
        }

        activeOffer = eligibleOffers.first
        if let offer = activeOffer {
            logger.info("LimitedTimeOfferService", "Selected active offer: \(offer.title) (\(offer.formattedDiscount))")
            updateCountdown()
        }
    }

    // MARK: - Private: Countdown Timer

    private func startCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateCountdown()
            }
        }
    }

    private func stopCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        countdownHours = 0
        countdownMinutes = 0
        countdownSeconds = 0
    }

    private func updateCountdown() {
        guard let offer = activeOffer else {
            stopCountdownTimer()
            return
        }

        let remaining = offer.timeRemaining
        if remaining <= 0 {
            checkOfferExpiry()
            return
        }

        countdownHours = Int(remaining) / 3600
        countdownMinutes = (Int(remaining) % 3600) / 60
        countdownSeconds = Int(remaining) % 60
    }

    // MARK: - Private: Expiry Checks

    private func startExpiryChecks() {
        expiryTimer?.invalidate()
        expiryTimer = Timer.scheduledTimer(withTimeInterval: Constants.expiryCheckInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkOfferExpiry()
            }
        }
    }

    // MARK: - Private: Analytics

    private func trackOfferClaim(_ offer: LimitedTimeOffer) async {
        guard let userId = supabase.userId else { return }

        do {
            try await supabase.client
                .from("lto_claim_events")
                .insert([
                    "user_id": userId,
                    "offer_id": offer.id,
                    "product_id": offer.productId,
                    "discount_percent": String(offer.discountPercent),
                    "claimed_at": ISO8601DateFormatter().string(from: Date())
                ])
                .execute()

            logger.success("LimitedTimeOfferService", "Tracked offer claim: \(offer.id)")
        } catch {
            logger.warning("LimitedTimeOfferService", "Failed to track offer claim: \(error.localizedDescription)")
        }
    }
}
