import Foundation
import StoreKit

// MARK: - StoreKit 2 Subscription Service

/// Service for managing in-app purchases and subscriptions using StoreKit 2
///
/// Handles subscription management, one-time purchases (Baseball Pack), and
/// transaction verification. Automatically listens for transaction updates
/// and maintains subscription status.
///
/// ## Subscription Products
/// - Monthly subscription: `com.ptperformance.app.monthly`
/// - Annual subscription: `com.ptperformance.app.annual`
///
/// ## One-Time Purchases
/// - Baseball Pack: `com.ptperformance.baseballpack`
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

    // MARK: - Product IDs

    nonisolated static let productIDs: Set<String> = [
        "com.ptperformance.app.monthly",
        "com.ptperformance.app.annual",
        "com.ptperformance.baseballpack"  // One-time purchase
    ]

    // MARK: - Individual Product IDs

    nonisolated static let baseballPackProductId = "com.ptperformance.baseballpack"

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

    /// Update isPremium whenever override or subscription status changes
    private func updateIsPremium() {
        let oldValue = isPremium
        if let override = debugPremiumOverride {
            isPremium = override
            logger.info("StoreKit", "Premium override: \(override) (was: \(oldValue))")
        } else {
            isPremium = subscriptionStatus == .active || subscriptionStatus == .gracePeriod
            logger.info("StoreKit", "Premium from subscription: \(isPremium) (status: \(subscriptionStatus), was: \(oldValue))")
        }
    }

    var monthlyProduct: Product? {
        products.first { $0.id == "com.ptperformance.app.monthly" }
    }

    var annualProduct: Product? {
        products.first { $0.id == "com.ptperformance.app.annual" }
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
            await updateSubscriptionStatus()
            await checkBaseballPackOwnership()
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
        logger.info("StoreKit", "Starting purchase for: \(product.id)")
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            logger.info("StoreKit", "Purchase successful, verifying transaction")
            let transaction = try checkVerified(verification)
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

                // Check for grace period via expiration and renewal info
                if let expirationDate = transaction.expirationDate {
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
}
