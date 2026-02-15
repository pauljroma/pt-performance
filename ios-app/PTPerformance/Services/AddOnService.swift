//
//  AddOnService.swift
//  PTPerformance
//
//  ACP-1009: Premium Add-Ons — Service for managing individual feature purchases
//  Uses StoreKit 2 non-consumable purchases and syncs with Supabase.
//

import Foundation
import StoreKit

// MARK: - Add-On Service

/// Manages premium add-on products: discovery, purchase, and ownership verification.
///
/// Add-ons are non-consumable StoreKit 2 products that unlock features beyond
/// the base subscription. The service fetches the catalog from Supabase,
/// handles purchases via StoreKit, and maintains ownership state.
///
/// ## Usage
/// ```swift
/// let service = AddOnService.shared
/// await service.fetchAddOns()
///
/// if let addOn = service.availableAddOns.first {
///     try await service.purchaseAddOn(addOn)
/// }
///
/// if service.hasAddOn("com.getmodus.app.addon.programbuilder") {
///     // Show program builder
/// }
/// ```
@MainActor
class AddOnService: ObservableObject {

    // MARK: - Singleton

    static let shared = AddOnService()

    // MARK: - Dependencies

    private let supabase: PTSupabaseClient
    private let storeKit: StoreKitService
    private let logger: DebugLogger

    // MARK: - Published Properties

    /// All available add-ons from the catalog
    @Published var availableAddOns: [PremiumAddOn] = []

    /// Product IDs of purchased add-ons
    @Published var purchasedAddOns: Set<String> = []

    /// Currently selected category filter (nil = show all)
    @Published var selectedCategory: AddOnCategory?

    /// Loading state
    @Published var isLoading = false

    /// Error message for display
    @Published var errorMessage: String?

    /// Whether a purchase is in progress
    @Published var isPurchasing = false

    // MARK: - Computed Properties

    /// Add-ons filtered by the selected category
    var filteredAddOns: [PremiumAddOn] {
        guard let category = selectedCategory else {
            return availableAddOns
        }
        return availableAddOns.filter { $0.category == category }
    }

    /// Number of purchased add-ons
    var purchasedCount: Int {
        purchasedAddOns.count
    }

    // MARK: - Initialization

    init(
        supabase: PTSupabaseClient = .shared,
        storeKit: StoreKitService = .shared,
        logger: DebugLogger = .shared
    ) {
        self.supabase = supabase
        self.storeKit = storeKit
        self.logger = logger
        logger.info("AddOnService", "Initializing AddOnService")

        // Restore purchases from entitlements on init
        Task {
            await restorePurchases()
        }
    }

    // MARK: - Fetch Add-Ons

    /// Fetches the add-on catalog from Supabase, falling back to demo data on failure.
    func fetchAddOns() async {
        logger.diagnostic("AddOnService: Fetching add-on catalog")
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await supabase.client
                .from("premium_addons")
                .select()
                .eq("is_available", value: true)
                .order("category", ascending: true)
                .execute()

            let decoder = PTSupabaseClient.flexibleDecoder
            let fetchedAddOns = try decoder.decode([PremiumAddOn].self, from: response.data)
            availableAddOns = fetchedAddOns
            logger.success("AddOnService", "Fetched \(fetchedAddOns.count) add-ons from server")
        } catch {
            logger.warning("AddOnService", "Failed to fetch add-ons from server: \(error.localizedDescription). Using demo catalog.")
            availableAddOns = PremiumAddOn.demoCatalog
        }
    }

    // MARK: - Purchase Add-On

    /// Purchases a premium add-on via StoreKit 2.
    ///
    /// - Parameter addOn: The add-on to purchase
    /// - Throws: StoreKit errors or verification failures
    func purchaseAddOn(_ addOn: PremiumAddOn) async throws {
        logger.info("AddOnService", "Initiating purchase for add-on: \(addOn.name) (\(addOn.productId))")
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }

        // Check if already purchased
        guard !hasAddOn(addOn.productId) else {
            logger.info("AddOnService", "Add-on already purchased: \(addOn.productId)")
            return
        }

        do {
            // Request product from StoreKit
            let products = try await Product.products(for: [addOn.productId])
            guard let product = products.first else {
                logger.error("AddOnService", "Product not found in App Store: \(addOn.productId)")
                throw StoreKitService.StoreError.productNotFound
            }

            // Initiate purchase
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try verifyTransaction(verification)
                await transaction.finish()

                // Update local state
                purchasedAddOns.insert(addOn.productId)

                // Sync to backend
                await syncPurchaseToBackend(productId: addOn.productId)

                logger.success("AddOnService", "Successfully purchased add-on: \(addOn.name)")

            case .userCancelled:
                logger.info("AddOnService", "User cancelled add-on purchase: \(addOn.name)")

            case .pending:
                logger.info("AddOnService", "Add-on purchase pending: \(addOn.name)")

            @unknown default:
                logger.warning("AddOnService", "Unknown purchase result for: \(addOn.name)")
            }
        } catch {
            let message = "Failed to purchase add-on: \(error.localizedDescription)"
            logger.error("AddOnService", message)
            errorMessage = message
            throw error
        }
    }

    // MARK: - Check Ownership

    /// Returns whether the user owns a specific add-on.
    ///
    /// - Parameter productId: The StoreKit product identifier
    /// - Returns: `true` if the user has purchased this add-on
    func hasAddOn(_ productId: String) -> Bool {
        purchasedAddOns.contains(productId)
    }

    // MARK: - Restore Purchases

    /// Scans current StoreKit entitlements to restore previously purchased add-ons.
    func restorePurchases() async {
        logger.diagnostic("AddOnService: Restoring add-on purchases from entitlements")

        var restored: Set<String> = []

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productType == .nonConsumable {
                    // Only track add-on product IDs (not baseball pack, etc.)
                    if transaction.productID.contains("addon") {
                        restored.insert(transaction.productID)
                    }
                }
            }
        }

        purchasedAddOns = restored
        logger.info("AddOnService", "Restored \(restored.count) add-on purchases")
    }

    // MARK: - Private Helpers

    /// Verifies a StoreKit transaction's cryptographic signature.
    private func verifyTransaction(_ result: VerificationResult<Transaction>) throws -> Transaction {
        switch result {
        case .unverified(_, let error):
            logger.error("AddOnService", "Transaction verification failed: \(error.localizedDescription)")
            throw StoreKitService.StoreError.failedVerification
        case .verified(let transaction):
            return transaction
        }
    }

    /// Syncs an add-on purchase to the Supabase backend for cross-device access.
    private func syncPurchaseToBackend(productId: String) async {
        logger.diagnostic("AddOnService: Syncing purchase to backend: \(productId)")

        guard let userId = supabase.userId else {
            logger.warning("AddOnService", "Cannot sync purchase - no authenticated user")
            return
        }

        do {
            try await supabase.client
                .from("user_addon_purchases")
                .upsert([
                    "user_id": userId,
                    "product_id": productId,
                    "purchased_at": ISO8601DateFormatter().string(from: Date())
                ])
                .execute()

            logger.success("AddOnService", "Synced add-on purchase to backend: \(productId)")
        } catch {
            logger.warning("AddOnService", "Failed to sync add-on purchase: \(error.localizedDescription)")
        }
    }
}
