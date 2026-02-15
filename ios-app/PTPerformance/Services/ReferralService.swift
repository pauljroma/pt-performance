//
//  ReferralService.swift
//  PTPerformance
//
//  ACP-994: Referral Program
//  Service for managing referral codes, tracking referrals, and reward tiers
//

import SwiftUI
import Combine

// MARK: - Referral Reward

/// A reward earned through the referral program
struct ReferralReward: Identifiable, Codable, Hashable {
    let id: UUID
    let tier: ReferralTier
    let title: String
    let description: String
    let isUnlocked: Bool
    let unlockedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case tier
        case title
        case description
        case isUnlocked = "is_unlocked"
        case unlockedAt = "unlocked_at"
    }
}

// MARK: - Referral Tier

/// Reward tiers for the referral program
enum ReferralTier: String, Codable, CaseIterable, Comparable {
    case starter = "starter"       // 1 referral
    case advocate = "advocate"     // 3 referrals
    case champion = "champion"     // 5 referrals

    var requiredReferrals: Int {
        switch self {
        case .starter: return 1
        case .advocate: return 3
        case .champion: return 5
        }
    }

    var displayName: String {
        rawValue.capitalized
    }

    var rewardDescription: String {
        switch self {
        case .starter: return "1 Week Free Premium"
        case .advocate: return "1 Month Free Premium"
        case .champion: return "Lifetime Champion Badge"
        }
    }

    var iconName: String {
        switch self {
        case .starter: return "gift.fill"
        case .advocate: return "star.fill"
        case .champion: return "crown.fill"
        }
    }

    var color: Color {
        switch self {
        case .starter: return .modusCyanStatic
        case .advocate: return .modusTealAccentStatic
        case .champion: return .yellow
        }
    }

    static func < (lhs: ReferralTier, rhs: ReferralTier) -> Bool {
        lhs.requiredReferrals < rhs.requiredReferrals
    }
}

// MARK: - Referred Friend

/// A friend who was referred to the app
struct ReferredFriend: Identifiable, Codable {
    let id: UUID
    let displayName: String // Anonymized (e.g., "J***n")
    let joinedAt: Date
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case joinedAt = "joined_at"
        case isActive = "is_active"
    }
}

// MARK: - Referral Service

/// Service for managing the referral program
@MainActor
class ReferralService: ObservableObject {

    // MARK: - Singleton

    static let shared = ReferralService()

    // MARK: - Published Properties

    /// The user's unique referral code
    @Published var referralCode: String = ""

    /// Total number of successful referrals
    @Published var referralCount: Int = 0

    /// Rewards earned and available
    @Published var referralRewards: [ReferralReward] = []

    /// List of referred friends (anonymized)
    @Published var referredFriends: [ReferredFriend] = []

    /// Loading state
    @Published var isLoading = false

    /// Error state
    @Published var error: Error?

    /// Whether the referral code has been copied
    @Published var codeCopied = false

    // MARK: - Private Properties

    private let client: PTSupabaseClient
    private let logger = DebugLogger.shared
    private var patientId: UUID?

    // MARK: - Computed Properties

    /// The next reward tier to achieve
    var nextTier: ReferralTier? {
        for tier in ReferralTier.allCases {
            if referralCount < tier.requiredReferrals {
                return tier
            }
        }
        return nil
    }

    /// Progress toward the next reward tier (0.0 to 1.0)
    var progressToNextTier: Double {
        guard let next = nextTier else { return 1.0 }

        let previousThreshold: Int
        if let currentIndex = ReferralTier.allCases.firstIndex(of: next), currentIndex > 0 {
            previousThreshold = ReferralTier.allCases[currentIndex - 1].requiredReferrals
        } else {
            previousThreshold = 0
        }

        let range = Double(next.requiredReferrals - previousThreshold)
        let progress = Double(referralCount - previousThreshold)
        return min(max(progress / range, 0), 1.0)
    }

    /// Referrals needed to reach the next tier
    var referralsToNextTier: Int {
        guard let next = nextTier else { return 0 }
        return max(0, next.requiredReferrals - referralCount)
    }

    /// The current highest unlocked tier
    var currentTier: ReferralTier? {
        ReferralTier.allCases.reversed().first { referralCount >= $0.requiredReferrals }
    }

    // MARK: - Initialization

    nonisolated init(client: PTSupabaseClient = .shared) {
        self.client = client
    }

    // MARK: - Public Methods

    /// Initialize the referral service for a user
    func initialize(for patientId: UUID) async {
        self.patientId = patientId
        logger.info("Referral", "Initializing referral service for patient: \(patientId)")

        await fetchReferralStats()
    }

    /// Generate the user's referral link
    func generateReferralLink() -> URL {
        let code = referralCode.isEmpty ? "MODUS" : referralCode
        let urlString = "https://app.moduspt.com/invite/\(code)"
        logger.info("Referral", "Generated referral link: \(urlString)")
        guard let url = URL(string: urlString) else {
            // Percent-encode the code in case it contains special characters
            let fallback = "https://app.moduspt.com/invite/MODUS"
            return URL(string: fallback)!  // Known-valid literal
        }
        return url
    }

    /// Copy referral code to clipboard
    func copyReferralCode() {
        UIPasteboard.general.string = referralCode
        codeCopied = true
        HapticFeedback.success()
        logger.info("Referral", "Referral code copied to clipboard: \(referralCode)")

        // Reset the copied state after 2 seconds
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            codeCopied = false
        }
    }

    /// Redeem a referral code during sign-up or in settings
    func redeemReferralCode(_ code: String) async throws {
        logger.info("Referral", "Attempting to redeem referral code: \(code)")

        guard let patientId = patientId else {
            logger.error("Referral", "Cannot redeem code: no patient ID")
            throw ReferralError.notAuthenticated
        }

        guard !code.isEmpty else {
            logger.warning("Referral", "Empty referral code provided")
            throw ReferralError.invalidCode
        }

        guard code != referralCode else {
            logger.warning("Referral", "User tried to use their own referral code")
            throw ReferralError.selfReferral
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Call Supabase RPC to validate and redeem the code
            try await client.client
                .rpc("redeem_referral_code", params: [
                    "p_code": code,
                    "p_patient_id": patientId.uuidString
                ])
                .execute()

            HapticFeedback.success()
            logger.success("Referral", "Successfully redeemed referral code: \(code)")

            // Refresh stats after redemption
            await fetchReferralStats()
        } catch {
            if error.isCancellation { return }
            self.error = error
            HapticFeedback.error()
            logger.error("Referral", "Failed to redeem referral code: \(error.localizedDescription)")
            throw ReferralError.redemptionFailed(error.localizedDescription)
        }
    }

    /// Fetch referral statistics from the server
    func fetchReferralStats() async {
        guard let patientId = patientId else {
            logger.warning("Referral", "Cannot fetch stats: no patient ID")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch referral code
            let codeResponse: [ReferralCodeResponse] = try await client.client
                .from("referral_codes")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .execute()
                .value

            if let existingCode = codeResponse.first {
                referralCode = existingCode.code
            } else {
                // Generate a new code if none exists
                referralCode = generateUniqueCode(for: patientId)
                try await saveReferralCode(referralCode, for: patientId)
            }

            // Fetch referral count and friends
            let referralsResponse: [ReferredFriend] = try await client.client
                .from("referrals")
                .select()
                .eq("referrer_id", value: patientId.uuidString)
                .order("joined_at", ascending: false)
                .execute()
                .value

            referralCount = referralsResponse.count
            referredFriends = referralsResponse

            // Build rewards list
            updateRewards()

            logger.success("Referral", "Fetched referral stats: \(referralCount) referrals, code: \(referralCode)")
        } catch {
            if error.isCancellation { return }
            self.error = error
            logger.error("Referral", "Failed to fetch referral stats: \(error.localizedDescription)")

            // Provide fallback data for offline mode
            if referralCode.isEmpty {
                referralCode = generateUniqueCode(for: patientId)
            }
            updateRewards()
        }
    }

    /// Share the referral link via the system share sheet
    func shareReferralLink() {
        let link = generateReferralLink()
        let text = "Join me on Modus PT! Use my referral code \(referralCode) to get started. \(link.absoluteString)"

        let content = ShareContent(
            title: "Join Modus PT",
            text: text,
            image: nil,
            url: link
        )

        SocialSharingService.shared.presentShareSheet(content: content)
        logger.info("Referral", "Sharing referral link")
    }

    // MARK: - Private Methods

    /// Generate a unique referral code based on patient ID
    private func generateUniqueCode(for patientId: UUID) -> String {
        let uuidString = patientId.uuidString.replacingOccurrences(of: "-", with: "")
        let prefix = String(uuidString.prefix(6)).uppercased()
        return "MODUS\(prefix)"
    }

    /// Save a new referral code to the database
    private func saveReferralCode(_ code: String, for patientId: UUID) async throws {
        try await client.client
            .from("referral_codes")
            .insert([
                "patient_id": patientId.uuidString,
                "code": code
            ])
            .execute()

        logger.info("Referral", "Saved new referral code: \(code)")
    }

    /// Update the rewards list based on current referral count
    private func updateRewards() {
        referralRewards = ReferralTier.allCases.map { tier in
            ReferralReward(
                id: UUID(),
                tier: tier,
                title: tier.displayName,
                description: tier.rewardDescription,
                isUnlocked: referralCount >= tier.requiredReferrals,
                unlockedAt: referralCount >= tier.requiredReferrals ? Date() : nil
            )
        }
    }
}

// MARK: - Referral Error

/// Errors specific to the referral system
enum ReferralError: LocalizedError {
    case notAuthenticated
    case invalidCode
    case selfReferral
    case alreadyRedeemed
    case redemptionFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to use referral codes."
        case .invalidCode:
            return "The referral code is invalid."
        case .selfReferral:
            return "You cannot use your own referral code."
        case .alreadyRedeemed:
            return "You have already redeemed a referral code."
        case .redemptionFailed(let reason):
            return "Failed to redeem code: \(reason)"
        }
    }
}

// MARK: - Referral Code Response

/// Response model for referral code queries
private struct ReferralCodeResponse: Codable {
    let id: UUID
    let patientId: UUID
    let code: String

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case code
    }
}
