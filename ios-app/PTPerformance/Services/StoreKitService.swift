import Foundation
import StoreKit

// MARK: - StoreKit 2 Subscription Service

@MainActor
class StoreKitService: ObservableObject {

    static let shared = StoreKitService()

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
            print("[StoreKitService] Premium override: \(override) (was: \(oldValue))")
        } else {
            isPremium = subscriptionStatus == .active || subscriptionStatus == .gracePeriod
            print("[StoreKitService] Premium from subscription: \(isPremium) (status: \(subscriptionStatus), was: \(oldValue))")
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
        updateListenerTask = listenForTransactions()

        Task {
            await updateSubscriptionStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let storeProducts = try await Product.products(for: StoreKitService.productIDs)
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            print("[StoreKitService] Failed to load products: \(error.localizedDescription)")
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updateSubscriptionStatus()

        case .userCancelled:
            break

        case .pending:
            break

        @unknown default:
            break
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            print("[StoreKitService] Failed to restore purchases: \(error.localizedDescription)")
        }
    }

    // MARK: - Update Subscription Status

    func updateSubscriptionStatus() async {
        var activePurchases: Set<String> = []
        var currentStatus: SubscriptionStatus = .none

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else {
                continue
            }

            // Skip revoked transactions
            if transaction.revocationDate != nil {
                continue
            }

            if StoreKitService.productIDs.contains(transaction.productID) {
                activePurchases.insert(transaction.productID)

                // Check for grace period via expiration and renewal info
                if let expirationDate = transaction.expirationDate {
                    if expirationDate > Date() {
                        currentStatus = .active
                    } else if transaction.isUpgraded == false {
                        // Transaction expired but not upgraded — check grace period
                        // StoreKit 2 keeps entitlement during billing grace period
                        currentStatus = .gracePeriod
                    }
                } else {
                    currentStatus = .active
                }
            }
        }

        purchasedProductIDs = activePurchases

        if activePurchases.isEmpty {
            subscriptionStatus = .none
        } else {
            subscriptionStatus = currentStatus == .none ? .active : currentStatus
        }
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { break }

                if let transaction = try? await self.checkVerified(result) {
                    await transaction.finish()
                    await self.updateSubscriptionStatus()
                }
            }
        }
    }

    // MARK: - Verification

    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}
