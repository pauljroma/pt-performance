//
//  PremiumPackService.swift
//  PTPerformance
//
//  Service for managing premium pack subscriptions and access
//

import Foundation
import Supabase

/// Service for managing premium pack subscriptions and content access
@MainActor
class PremiumPackService: ObservableObject {

    // MARK: - Singleton

    static let shared = PremiumPackService()

    // MARK: - Dependencies

    private let supabase: PTSupabaseClient
    private let logger = DebugLogger.shared

    // MARK: - Published Properties

    @Published var packs: [PremiumPack] = []
    @Published var userSubscriptions: [UserPackSubscription] = []
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Initialization

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
        logger.info("PremiumPackService", "Initializing PremiumPackService")
    }

    // MARK: - Fetch All Packs

    /// Fetch all available premium packs
    func fetchAllPacks() async throws -> [PremiumPack] {
        logger.diagnostic("PremiumPackService: Fetching all premium packs")
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let response = try await supabase.client
                .from("premium_packs")
                .select()
                .order("sort_order", ascending: true)
                .limit(200)
                .execute()

            let decoder = PTSupabaseClient.flexibleDecoder
            let fetchedPacks = try decoder.decode([PremiumPack].self, from: response.data)

            await MainActor.run {
                self.packs = fetchedPacks
            }

            logger.success("PremiumPackService", "Fetched \(fetchedPacks.count) premium packs")
            return fetchedPacks
        } catch {
            let errorMessage = "Failed to fetch premium packs: \(error.localizedDescription)"
            logger.error("PremiumPackService", errorMessage)
            self.error = errorMessage
            throw error
        }
    }

    // MARK: - Fetch Featured Packs

    /// Fetch the core 6 featured packs
    func fetchFeaturedPacks() async throws -> [PremiumPack] {
        logger.diagnostic("PremiumPackService: Fetching featured packs")
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let response = try await supabase.client
                .from("premium_packs")
                .select()
                .eq("is_addon", value: false)
                .order("sort_order", ascending: true)
                .limit(6)
                .execute()

            let decoder = PTSupabaseClient.flexibleDecoder
            let fetchedPacks = try decoder.decode([PremiumPack].self, from: response.data)

            logger.success("PremiumPackService", "Fetched \(fetchedPacks.count) featured packs")
            return fetchedPacks
        } catch {
            let errorMessage = "Failed to fetch featured packs: \(error.localizedDescription)"
            logger.error("PremiumPackService", errorMessage)
            self.error = errorMessage
            throw error
        }
    }

    // MARK: - Fetch Addon Packs

    /// Fetch addon packs (supplementary content)
    func fetchAddonPacks() async throws -> [PremiumPack] {
        logger.diagnostic("PremiumPackService: Fetching addon packs")
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let response = try await supabase.client
                .from("premium_packs")
                .select()
                .eq("is_addon", value: true)
                .order("sort_order", ascending: true)
                .execute()

            let decoder = PTSupabaseClient.flexibleDecoder
            let fetchedPacks = try decoder.decode([PremiumPack].self, from: response.data)

            logger.success("PremiumPackService", "Fetched \(fetchedPacks.count) addon packs")
            return fetchedPacks
        } catch {
            let errorMessage = "Failed to fetch addon packs: \(error.localizedDescription)"
            logger.error("PremiumPackService", errorMessage)
            self.error = errorMessage
            throw error
        }
    }

    // MARK: - Fetch Single Pack

    /// Fetch a single pack by ID
    func fetchPack(id: UUID) async throws -> PremiumPack {
        logger.diagnostic("PremiumPackService: Fetching pack: \(id)")
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let response = try await supabase.client
                .from("premium_packs")
                .select()
                .eq("id", value: id.uuidString)
                .single()
                .execute()

            let decoder = PTSupabaseClient.flexibleDecoder
            let pack = try decoder.decode(PremiumPack.self, from: response.data)

            logger.success("PremiumPackService", "Fetched pack: \(pack.name)")
            return pack
        } catch {
            let errorMessage = "Failed to fetch pack: \(error.localizedDescription)"
            logger.error("PremiumPackService", errorMessage)
            self.error = errorMessage
            throw error
        }
    }

    // MARK: - Fetch Pack by Code

    /// Fetch a pack by its code (e.g., "BASEBALL", "BASE")
    func fetchPack(code: String) async throws -> PremiumPack {
        logger.diagnostic("PremiumPackService: Fetching pack by code: \(code)")
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let response = try await supabase.client
                .from("premium_packs")
                .select()
                .eq("code", value: code.uppercased())
                .single()
                .execute()

            let decoder = PTSupabaseClient.flexibleDecoder
            let pack = try decoder.decode(PremiumPack.self, from: response.data)

            logger.success("PremiumPackService", "Fetched pack: \(pack.name)")
            return pack
        } catch {
            let errorMessage = "Failed to fetch pack by code: \(error.localizedDescription)"
            logger.error("PremiumPackService", errorMessage)
            self.error = errorMessage
            throw error
        }
    }

    // MARK: - Fetch User Subscriptions

    /// Fetch all subscriptions for the current user
    func fetchUserSubscriptions() async throws -> [UserPackSubscription] {
        guard let userId = supabase.userId else {
            logger.warning("PremiumPackService", "No user logged in - cannot fetch subscriptions")
            return []
        }

        logger.diagnostic("PremiumPackService: Fetching subscriptions for user: \(userId)")
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let response = try await supabase.client
                .from("user_pack_subscriptions")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()

            let decoder = PTSupabaseClient.flexibleDecoder
            let subscriptions = try decoder.decode([UserPackSubscription].self, from: response.data)

            await MainActor.run {
                self.userSubscriptions = subscriptions
            }

            logger.success("PremiumPackService", "Fetched \(subscriptions.count) user subscriptions")
            return subscriptions
        } catch {
            let errorMessage = "Failed to fetch user subscriptions: \(error.localizedDescription)"
            logger.error("PremiumPackService", errorMessage)
            self.error = errorMessage
            throw error
        }
    }

    // MARK: - Fetch Active Subscriptions

    /// Fetch only active subscriptions for the current user
    func fetchActiveSubscriptions() async throws -> [UserPackSubscription] {
        guard let userId = supabase.userId else {
            logger.warning("PremiumPackService", "No user logged in - cannot fetch active subscriptions")
            return []
        }

        logger.diagnostic("PremiumPackService: Fetching active subscriptions for user: \(userId)")

        do {
            let response = try await supabase.client
                .from("user_pack_subscriptions")
                .select()
                .eq("user_id", value: userId)
                .eq("is_active", value: true)
                .execute()

            let decoder = PTSupabaseClient.flexibleDecoder
            let subscriptions = try decoder.decode([UserPackSubscription].self, from: response.data)

            logger.success("PremiumPackService", "Fetched \(subscriptions.count) active subscriptions")
            return subscriptions
        } catch {
            let errorMessage = "Failed to fetch active subscriptions: \(error.localizedDescription)"
            logger.error("PremiumPackService", errorMessage)
            throw error
        }
    }

    // MARK: - Check Access

    /// Check if the user has access to a specific pack
    func checkAccess(packCode: String) -> Bool {
        // First check StoreKit for one-time purchases (like Baseball Pack)
        if packCode.uppercased() == "BASEBALL" {
            if StoreKitService.shared.hasBaseballAccess {
                return true
            }
        }

        // Check premium subscription status
        if StoreKitService.shared.isPremium {
            // Premium users have access to base content
            if packCode.uppercased() == "BASE" {
                return true
            }
        }

        // Check database subscriptions
        let hasSubscription = userSubscriptions.contains { subscription in
            subscription.packCode.uppercased() == packCode.uppercased() &&
            subscription.isCurrentlyValid
        }

        logger.diagnostic("PremiumPackService: Access check for \(packCode): \(hasSubscription)")
        return hasSubscription
    }

    /// Check if user has access to a pack by ID
    func checkAccess(packId: UUID) -> Bool {
        guard let pack = packs.first(where: { $0.id == packId }) else {
            return false
        }
        return checkAccess(packCode: pack.code)
    }

    // MARK: - Get Subscribed Pack Codes

    /// Get a set of pack codes the user is subscribed to
    func getSubscribedPackCodes() -> Set<String> {
        var codes = Set<String>()

        // Add codes from database subscriptions
        for subscription in userSubscriptions where subscription.isCurrentlyValid {
            codes.insert(subscription.packCode.uppercased())
        }

        // Add Baseball if owned via StoreKit
        if StoreKitService.shared.hasBaseballAccess {
            codes.insert("BASEBALL")
        }

        // Add Base if premium subscriber
        if StoreKitService.shared.isPremium {
            codes.insert("BASE")
        }

        return codes
    }

    // MARK: - Fetch Programs for Pack

    /// Fetch all programs included in a specific pack
    func fetchProgramsForPack(packCode: String) async throws -> [ProgramLibrary] {
        logger.diagnostic("PremiumPackService: Fetching programs for pack: \(packCode)")

        do {
            // Map pack code to program category
            let category = packCode.lowercased()

            let response = try await supabase.client
                .from("program_library")
                .select()
                .eq("category", value: category)
                .order("title", ascending: true)
                .execute()

            let decoder = PTSupabaseClient.flexibleDecoder
            let programs = try decoder.decode([ProgramLibrary].self, from: response.data)

            logger.success("PremiumPackService", "Fetched \(programs.count) programs for pack '\(packCode)'")
            return programs
        } catch {
            let errorMessage = "Failed to fetch programs for pack: \(error.localizedDescription)"
            logger.error("PremiumPackService", errorMessage)
            throw error
        }
    }

    // MARK: - Fetch Pack with Programs

    /// Fetch a pack with its associated programs
    func fetchPackWithPrograms(packCode: String) async throws -> PackWithPrograms {
        logger.diagnostic("PremiumPackService: Fetching pack with programs: \(packCode)")

        async let packFetch = fetchPack(code: packCode)
        async let programsFetch = fetchProgramsForPack(packCode: packCode)

        let pack = try await packFetch
        let programs = try await programsFetch
        let isSubscribed = checkAccess(packCode: packCode)

        return PackWithPrograms(
            pack: pack,
            programs: programs,
            isSubscribed: isSubscribed
        )
    }

    // MARK: - Fetch All Packs with Subscription Status

    /// Fetch all packs and indicate which ones the user is subscribed to
    func fetchAllPacksWithStatus() async throws -> [(pack: PremiumPack, isSubscribed: Bool)] {
        logger.diagnostic("PremiumPackService: Fetching all packs with subscription status")

        // Fetch packs and subscriptions in parallel
        async let packsFetch = fetchAllPacks()
        async let subscriptionsFetch = fetchUserSubscriptions()

        let fetchedPacks = try await packsFetch
        _ = try await subscriptionsFetch

        // Map packs with subscription status
        let result = fetchedPacks.map { pack in
            (pack: pack, isSubscribed: checkAccess(packCode: pack.code))
        }

        logger.success("PremiumPackService", "Fetched \(result.count) packs with status")
        return result
    }

    // MARK: - Refresh Data

    /// Refresh all pack and subscription data
    func refreshData() async {
        logger.diagnostic("PremiumPackService: Refreshing all data")

        do {
            async let _ = fetchAllPacks()
            async let _ = fetchUserSubscriptions()
        } catch {
            logger.error("PremiumPackService", "Error refreshing data: \(error.localizedDescription)")
        }
    }

    // MARK: - Clear Error

    /// Clear any existing error state
    func clearError() {
        error = nil
    }
}
