import Foundation
import StoreKit

// MARK: - StoreKit 2 Subscription Service

@MainActor
class StoreKitService: ObservableObject {

    static let shared = StoreKitService()

    private let logger = DebugLogger.shared

    // MARK: - Product IDs

    static let productIDs: Set<String> = [
        "com.ptperformance.app.monthly",
        "com.ptperformance.app.annual"
    ]

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

    // BUILD 309: Changed isPremium from computed to @Published for reliable SwiftUI updates
    @Published private(set) var isPremium: Bool = false

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

        var errorDescription: String? {
            switch self {
            case .failedVerification:
                return "Transaction verification failed. Please try again."
            }
        }
    }

    // MARK: - Premium Status Update

    /// BUILD 312: Update isPremium whenever override or subscription status changes
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

    // MARK: - Transaction Listener

    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Init

    private init() {
        logger.info("StoreKit", "Initializing StoreKitService")
        updateListenerTask = listenForTransactions()

        Task {
            await updateSubscriptionStatus()
            logger.info("StoreKit", "Initial subscription status: \(subscriptionStatus)")
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

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

    func purchase(_ product: Product) async throws {
        logger.info("StoreKit", "Starting purchase for: \(product.id)")
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            logger.info("StoreKit", "Purchase successful, verifying transaction")
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updateSubscriptionStatus()
            logger.success("StoreKit", "Purchase completed for: \(product.id)")

        case .userCancelled:
            logger.info("StoreKit", "User cancelled purchase")

        case .pending:
            logger.info("StoreKit", "Purchase pending approval")

        @unknown default:
            logger.warning("StoreKit", "Unknown purchase result")
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        logger.info("StoreKit", "Restoring purchases via AppStore.sync()")
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            logger.success("StoreKit", "Purchases restored successfully")
        } catch {
            logger.error("StoreKit", "Failed to restore purchases: \(error.localizedDescription)")
        }
    }

    // MARK: - Update Subscription Status

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
                    await self.updateSubscriptionStatus()
                } else {
                    logger.warning("StoreKit", "Failed to verify transaction update")
                }
            }
        }
    }

    // MARK: - Verification

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
