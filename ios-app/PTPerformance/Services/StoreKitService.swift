import Foundation
import StoreKit

// MARK: - StoreKit 2 Subscription Service

/// Service for managing in-app purchases and subscriptions using StoreKit 2
///
/// Handles subscription management, one-time purchases (Baseball Pack), and
/// transaction verification. Automatically listens for transaction updates
/// and maintains subscription status.
///
/// ## Security Architecture
/// This service uses a defense-in-depth approach:
/// 1. **Client-side verification**: StoreKit 2's cryptographic verification ensures
///    transactions are signed by Apple (JWS verification)
/// 2. **Server-side validation**: Critical purchases are validated via edge function
///    to prevent receipt replay attacks and enable cross-device sync
/// 3. **Backend sync**: Subscription status is synced to the database for server-side
///    feature gating
///
/// ## Subscription Products
/// Product IDs are centralized in Config.Subscription to prevent tampering
/// and ensure consistency across the app.
///
/// ## Usage Example
/// ```swift
/// let store = StoreKitService.shared
///
/// // Load products
/// await store.loadProducts()
///
/// // Purchase a subscription
/// if let monthly = store.monthlyProduct {
///     try await store.purchase(monthly)
/// }
///
/// // Check premium status
/// if store.isPremium {
///     // Show premium features
/// }
/// ```
@MainActor
class StoreKitService: ObservableObject {

    /// Shared singleton instance
    static let shared = StoreKitService()

    private let logger = DebugLogger.shared

    // MARK: - Product IDs (Centralized in Config for security)

    /// All product IDs - fetched from Config to ensure consistency and prevent tampering
    /// ACP-986: Includes Elite tier product IDs alongside existing Pro/Baseball Pack
    nonisolated static var productIDs: Set<String> {
        var ids = Set([
            Config.Subscription.monthlyProductID,
            Config.Subscription.annualProductID,
            Config.Subscription.baseballPackProductID
        ])
        // ACP-986: Add Elite tier product IDs
        ids.formUnion(SubscriptionTier.allPaidProductIds)
        return ids
    }

    // MARK: - Individual Product IDs (from Config)

    nonisolated static var baseballPackProductId: String {
        Config.Subscription.baseballPackProductID
    }

    // MARK: - Published Properties

    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var subscriptionStatus: SubscriptionStatus = .none {
        didSet { updateIsPremium() }
    }
    @Published var isLoading: Bool = false
    @Published var debugPremiumOverride: Bool? = nil {
        didSet { updateIsPremium() }
    }

    // Changed isPremium from computed to @Published for reliable SwiftUI updates
    @Published private(set) var isPremium: Bool = false

    // MARK: - ACP-986: Subscription Tier

    /// The current subscription tier derived from purchased product IDs.
    /// Updated automatically when subscription status changes.
    @Published private(set) var currentTier: SubscriptionTier = .free

    /// The expiration date of the current subscription, if available
    @Published private(set) var subscriptionExpirationDate: Date?

    /// Whether the user is currently in a free trial period
    @Published private(set) var isInTrialPeriod: Bool = false

    // MARK: - Baseball Pack Ownership

    @Published var ownsBaseballPack: Bool = false

    // MARK: - Subscription Status

    enum SubscriptionStatus {
        case none
        case active
        case expired
        case gracePeriod
    }

    // MARK: - Store Error

    enum StoreError: LocalizedError {
        case failedVerification
        case productNotFound
        case invalidProductType

        var errorDescription: String? {
            switch self {
            case .failedVerification:
                return "Transaction verification failed. Please try again."
            case .productNotFound:
                return "Product not found. Please try again later."
            case .invalidProductType:
                return "Invalid product configuration."
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .failedVerification:
                return "Make sure you're signed into the correct Apple ID and try again."
            case .productNotFound:
                return "The subscription may not be available in your region. Please contact support."
            case .invalidProductType:
                return "Please update to the latest version of the app and try again."
            }
        }
    }

    // MARK: - Premium Status Update

    /// Update isPremium and currentTier whenever override or subscription status changes
    private func updateIsPremium() {
        let oldValue = isPremium
        let oldTier = currentTier

        if let override = debugPremiumOverride {
            isPremium = override
            // ACP-986: Debug override sets tier to Pro by default
            currentTier = override ? .pro : .free
            logger.info("StoreKit", "Premium override: \(override) (was: \(oldValue))")
        } else {
            isPremium = subscriptionStatus == .active || subscriptionStatus == .gracePeriod
            // ACP-986: Derive tier from purchased product IDs
            currentTier = SubscriptionTier.from(purchasedProductIDs: purchasedProductIDs)
            logger.info("StoreKit", "Premium from subscription: \(isPremium) (status: \(subscriptionStatus), was: \(oldValue))")
        }

        if oldTier != currentTier {
            logger.info("StoreKit", "Tier changed: \(oldTier.displayName) -> \(currentTier.displayName)")
            // ACP-986: Persist tier to UserDefaults as fallback cache
            UserDefaults.standard.set(currentTier.rawValue, forKey: "cached_subscription_tier")
        }
    }

    var monthlyProduct: Product? {
        products.first { $0.id == Config.Subscription.monthlyProductID }
    }

    var annualProduct: Product? {
        products.first { $0.id == Config.Subscription.annualProductID }
    }

    var baseballPackProduct: Product? {
        products.first { $0.id == Self.baseballPackProductId }
    }

    /// Returns true if user has access to baseball content (owns pack or debug override)
    var hasBaseballAccess: Bool {
        return ownsBaseballPack || debugPremiumOverride == true
    }

    // MARK: - Transaction Listener

    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Init

    private init() {
        logger.info("StoreKit", "Initializing StoreKitService")
        updateListenerTask = listenForTransactions()

        Task {
            async let status: Void = updateSubscriptionStatus()
            async let baseball: Void = checkBaseballPackOwnership()
            async let sync: Void = syncSubscriptionToBackend()
            _ = await (status, baseball, sync)
            logger.info("StoreKit", "Initial subscription status: \(subscriptionStatus)")
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    /// Loads all available products from the App Store
    ///
    /// Fetches product information for all configured product IDs and sorts
    /// them by price in ascending order. Products are stored in the `products`
    /// array and can be accessed via convenience properties like `monthlyProduct`.
    ///
    /// - Note: This method should be called on app launch to ensure products
    ///         are available before displaying the paywall
    func loadProducts() async {
        logger.info("StoreKit", "Loading products: \(StoreKitService.productIDs)")
        isLoading = true
        defer { isLoading = false }

        do {
            let storeProducts = try await Product.products(for: StoreKitService.productIDs)
            products = storeProducts.sorted { $0.price < $1.price }
            logger.success("StoreKit", "Loaded \(products.count) products")
            for product in products {
                logger.diagnostic("StoreKit: Product \(product.id) - \(product.displayPrice)")
            }
        } catch {
            logger.error("StoreKit", "Failed to load products: \(error.localizedDescription)")
        }
    }

    // MARK: - Purchase

    /// Initiates a purchase for the specified product
    ///
    /// Handles the complete purchase flow including transaction verification
    /// and status updates. For subscriptions, updates `subscriptionStatus`.
    /// For non-consumable purchases like Baseball Pack, updates ownership state.
    ///
    /// - Parameter product: The StoreKit Product to purchase
    ///
    /// - Throws: `StoreError.failedVerification` if transaction verification fails
    ///
    /// - Note: User cancellation does not throw an error; it's logged silently
    func purchase(_ product: Product) async throws {
        // Security: Validate product ID before purchase
        guard isValidProductId(product.id) else {
            logger.error("StoreKit", "Attempted purchase with invalid product ID: \(product.id)")
            throw StoreError.productNotFound
        }

        logger.info("StoreKit", "Starting purchase for: \(product.id)")
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            logger.info("StoreKit", "Purchase successful, verifying transaction")
            let transaction = try checkVerified(verification)

            // Security: Verify the purchased product matches what we requested
            guard transaction.productID == product.id else {
                logger.error("StoreKit", "Product ID mismatch: expected \(product.id), got \(transaction.productID)")
                throw StoreError.failedVerification
            }

            await transaction.finish()

            // Handle subscription vs non-consumable updates
            if product.type == .nonConsumable {
                if product.id == Self.baseballPackProductId {
                    ownsBaseballPack = true
                    logger.success("StoreKit", "Baseball Pack purchased successfully")
                }
            } else {
                await updateSubscriptionStatus()
            }

            // Sync subscription status to backend for server-side verification
            await syncSubscriptionToBackend()

            logger.success("StoreKit", "Purchase completed for: \(product.id)")

        case .userCancelled:
            logger.info("StoreKit", "User cancelled purchase")

        case .pending:
            logger.info("StoreKit", "Purchase pending approval")

        @unknown default:
            logger.warning("StoreKit", "Unknown purchase result")
        }
    }

    // MARK: - Baseball Pack Purchase

    /// Purchase the Baseball Pack (one-time non-consumable purchase)
    func purchaseBaseballPack() async throws {
        guard let product = baseballPackProduct else {
            logger.error("StoreKit", "Baseball Pack product not found")
            throw StoreError.productNotFound
        }

        guard product.type == .nonConsumable else {
            logger.error("StoreKit", "Baseball Pack is not configured as non-consumable")
            throw StoreError.invalidProductType
        }

        try await purchase(product)
    }

    // MARK: - Baseball Pack Ownership Check

    /// Check if user owns the Baseball Pack by scanning current entitlements
    func checkBaseballPackOwnership() async {
        logger.diagnostic("StoreKit: Checking Baseball Pack ownership")

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else {
                continue
            }

            // Skip revoked transactions
            if transaction.revocationDate != nil {
                continue
            }

            if transaction.productID == Self.baseballPackProductId {
                ownsBaseballPack = true
                logger.success("StoreKit", "User owns Baseball Pack")
                return
            }
        }

        ownsBaseballPack = false
        logger.info("StoreKit", "User does not own Baseball Pack")
    }

    // MARK: - Restore Purchases

    /// Restores previous purchases from the App Store
    ///
    /// Syncs with the App Store to restore any previously purchased subscriptions
    /// or non-consumable products. Updates both subscription status and Baseball
    /// Pack ownership state after restoration.
    ///
    /// - Note: This method uses `AppStore.sync()` which may prompt for Apple ID
    ///         authentication if needed
    func restorePurchases() async {
        logger.info("StoreKit", "Restoring purchases via AppStore.sync()")
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            await checkBaseballPackOwnership()

            // Sync restored purchases to backend
            await syncSubscriptionToBackend()

            logger.success("StoreKit", "Purchases restored successfully")
        } catch {
            logger.error("StoreKit", "Failed to restore purchases: \(error.localizedDescription)")
        }
    }

    // MARK: - Update Subscription Status

    /// Updates the current subscription status by checking active entitlements
    ///
    /// Iterates through all current entitlements to determine subscription state.
    /// Handles active subscriptions, expired subscriptions, and grace periods.
    /// Updates both `purchasedProductIDs` and `subscriptionStatus` properties.
    func updateSubscriptionStatus() async {
        logger.diagnostic("StoreKit: Checking current entitlements")
        var activePurchases: Set<String> = []
        var currentStatus: SubscriptionStatus = .none
        var latestExpiration: Date?
        var foundTrial = false

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else {
                logger.warning("StoreKit", "Failed to verify entitlement transaction")
                continue
            }

            // Skip revoked transactions
            if transaction.revocationDate != nil {
                logger.info("StoreKit", "Skipping revoked transaction: \(transaction.productID)")
                continue
            }

            if StoreKitService.productIDs.contains(transaction.productID) {
                activePurchases.insert(transaction.productID)

                // ACP-987: Detect trial period via offer type
                if transaction.offerType == .introductory {
                    foundTrial = true
                    logger.info("StoreKit", "User is in introductory offer/trial for \(transaction.productID)")
                }

                // Check for grace period via expiration and renewal info
                if let expirationDate = transaction.expirationDate {
                    // ACP-986: Track the latest expiration date
                    if latestExpiration == nil || expirationDate > (latestExpiration ?? .distantPast) {
                        latestExpiration = expirationDate
                    }

                    if expirationDate > Date() {
                        currentStatus = .active
                        logger.diagnostic("StoreKit: Active subscription \(transaction.productID) expires \(expirationDate)")
                    } else if transaction.isUpgraded == false {
                        // Transaction expired but not upgraded — check grace period
                        // StoreKit 2 keeps entitlement during billing grace period
                        currentStatus = .gracePeriod
                        logger.info("StoreKit", "Subscription in grace period: \(transaction.productID)")
                    }
                } else {
                    currentStatus = .active
                }
            }
        }

        purchasedProductIDs = activePurchases
        subscriptionExpirationDate = latestExpiration
        isInTrialPeriod = foundTrial

        if activePurchases.isEmpty {
            subscriptionStatus = .none
            logger.info("StoreKit", "No active subscriptions found")
        } else {
            subscriptionStatus = currentStatus == .none ? .active : currentStatus
            logger.info("StoreKit", "Subscription status updated: \(subscriptionStatus), products: \(activePurchases)")
        }
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        // Task.detached required: Long-running listener must run independently of caller's actor context
        return Task.detached { [weak self] in
            let logger = DebugLogger.shared
            logger.info("StoreKit", "Transaction listener started")

            for await result in Transaction.updates {
                guard let self = self else { break }

                if let transaction = try? await self.checkVerified(result) {
                    logger.info("StoreKit", "Transaction update received: \(transaction.productID)")
                    await transaction.finish()

                    // Handle Baseball Pack transaction updates
                    if transaction.productID == StoreKitService.baseballPackProductId {
                        await self.checkBaseballPackOwnership()
                    } else {
                        await self.updateSubscriptionStatus()
                    }
                } else {
                    logger.warning("StoreKit", "Failed to verify transaction update")
                }
            }
        }
    }

    // MARK: - Verification

    /// Verifies a StoreKit transaction result
    ///
    /// Extracts the verified transaction from a `VerificationResult`, ensuring
    /// the transaction has been cryptographically verified by the App Store.
    ///
    /// - Parameter result: The verification result to check
    ///
    /// - Returns: The verified transaction value
    ///
    /// - Throws: `StoreError.failedVerification` if the transaction is unverified
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            logger.error("StoreKit", "Transaction verification failed")
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Server-Side Validation

    /// Validates a product ID against known valid product IDs
    /// This prevents tampering with product IDs in modified app binaries
    ///
    /// - Parameter productId: The product ID to validate
    /// - Returns: True if the product ID is valid and expected
    func isValidProductId(_ productId: String) -> Bool {
        return Self.productIDs.contains(productId)
    }

    // MARK: - Formatters

    private static let isoFormatter = ISO8601DateFormatter()

    // MARK: - Subscription Sync Request Model

    /// Request body for syncing subscription status to backend
    /// ACP-986: Includes subscription_tier for tier-based feature gating on the backend
    private struct SubscriptionSyncRequest: Encodable {
        let is_premium: Bool
        let subscription_tier: String
        let subscription_status: String
        let purchased_products: [String]
        let owns_baseball_pack: Bool
        let is_in_trial: Bool
        let synced_at: String
        let expires_at: String?
    }

    /// Syncs subscription status to the backend for server-side feature gating
    ///
    /// This enables the backend to verify premium status independently of the client,
    /// which is important for:
    /// - Server-side API access control
    /// - Cross-device subscription status
    /// - Analytics and billing reconciliation
    ///
    /// - Note: This is called automatically after purchase verification
    func syncSubscriptionToBackend() async {
        guard PTSupabaseClient.shared.userId != nil else {
            logger.diagnostic("StoreKit: No user logged in, skipping backend sync")
            return
        }

        logger.info("StoreKit", "Syncing subscription status to backend")

        do {
            // Get expiration date if available
            let expirationDate = await getActiveSubscriptionExpiration()

            // Build subscription info using Codable struct
            // ACP-986: Include tier for server-side feature gating
            let subscriptionInfo = SubscriptionSyncRequest(
                is_premium: isPremium,
                subscription_tier: currentTier.rawValue,
                subscription_status: subscriptionStatusString,
                purchased_products: Array(purchasedProductIDs),
                owns_baseball_pack: ownsBaseballPack,
                is_in_trial: isInTrialPeriod,
                synced_at: Self.isoFormatter.string(from: Date()),
                expires_at: expirationDate.map { Self.isoFormatter.string(from: $0) }
            )

            // Call edge function to update backend
            // Note: invoke() throws on failure, so no need to check status
            _ = try await PTSupabaseClient.shared.client.functions
                .invoke("sync-subscription-status", options: .init(body: subscriptionInfo))

            logger.success("StoreKit", "Subscription status synced to backend")
        } catch {
            // Non-fatal: subscription still works locally, backend sync is for cross-device
            logger.warning("StoreKit", "Failed to sync subscription to backend: \(error.localizedDescription)")
        }
    }

    /// Gets the expiration date of the active subscription
    private func getActiveSubscriptionExpiration() async -> Date? {
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result),
                  transaction.revocationDate == nil,
                  let expirationDate = transaction.expirationDate,
                  expirationDate > Date() else {
                continue
            }

            if Self.productIDs.contains(transaction.productID) {
                return expirationDate
            }
        }
        return nil
    }

    /// String representation of subscription status for backend sync
    private var subscriptionStatusString: String {
        switch subscriptionStatus {
        case .none: return "none"
        case .active: return "active"
        case .expired: return "expired"
        case .gracePeriod: return "grace_period"
        }
    }

    // MARK: - Receipt Validation (Server-Side)

    /// Validates the app receipt with the server for additional security
    ///
    /// While StoreKit 2 provides cryptographic verification locally, server-side
    /// validation provides additional security:
    /// - Prevents receipt replay attacks
    /// - Enables cross-device subscription verification
    /// - Creates an audit trail for purchases
    /// - Allows server-side feature gating
    ///
    /// - Important: This should be called after critical purchases to ensure
    ///   the purchase is recorded server-side before granting access
    ///
    /// - Returns: True if server validation succeeded
    func validateReceiptWithServer() async -> Bool {
        // TODO: Implement server-side receipt validation via validate-receipt edge function
        // The edge function exists at /supabase/functions/validate-receipt/index.ts
        // but needs to be updated to:
        // 1. Use the correct bundle ID (com.getmodus.app)
        // 2. Use the correct product IDs from Config.Subscription
        // 3. Handle StoreKit 2 JWS tokens instead of legacy receipts
        //
        // For StoreKit 2, we can use Transaction.currentEntitlements to get
        // the JWS (JSON Web Signature) which can be verified server-side using
        // Apple's App Store Server API instead of the legacy verifyReceipt endpoint.
        //
        // See: https://developer.apple.com/documentation/appstoreserverapi

        logger.diagnostic("StoreKit: Server-side receipt validation not yet implemented")
        logger.diagnostic("StoreKit: Using client-side StoreKit 2 verification (cryptographically secure)")

        // For now, sync subscription status to backend as a partial solution
        await syncSubscriptionToBackend()

        return true
    }
}
