//
//  AffiliateService.swift
//  PTPerformance
//
//  ACP-1000: Influencer/Affiliate Program — Affiliate tracking and management
//  Handles affiliate code validation, application, and conversion tracking.
//

import Foundation

// MARK: - Affiliate Error

/// Errors specific to affiliate operations
enum AffiliateError: LocalizedError {
    case invalidCode
    case codeExpired
    case codeAlreadyApplied
    case networkError(underlying: Error)
    case userNotAuthenticated

    var errorDescription: String? {
        switch self {
        case .invalidCode:
            return "This affiliate code is not valid. Please check and try again."
        case .codeExpired:
            return "This affiliate code has expired."
        case .codeAlreadyApplied:
            return "An affiliate code has already been applied to your account."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .userNotAuthenticated:
            return "Please sign in to apply an affiliate code."
        }
    }
}

// MARK: - Affiliate Info

/// Details about the applied affiliate code, fetched from the backend.
struct AffiliateInfo: Codable, Equatable {
    /// The affiliate code string
    let code: String

    /// Display name of the influencer/affiliate
    let affiliateName: String

    /// Optional discount percentage offered through this affiliate
    let discountPercent: Int?

    /// When the code was applied
    let appliedAt: Date

    /// Whether the affiliate is currently active
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case code
        case affiliateName = "affiliate_name"
        case discountPercent = "discount_percent"
        case appliedAt = "applied_at"
        case isActive = "is_active"
    }
}

// MARK: - Affiliate Service

/// Manages the influencer/affiliate program for user acquisition and revenue attribution.
///
/// Supports applying affiliate codes during onboarding or from settings, validating
/// codes against the backend, and tracking conversions when affiliate-referred users
/// make subscription purchases.
///
/// ## Attribution Flow
/// 1. User enters affiliate code during onboarding or in settings
/// 2. Code is validated against Supabase `affiliate_codes` table
/// 3. Attribution is stored in UserDefaults (local) and Supabase (server)
/// 4. On subscription purchase, `trackAffiliateConversion()` is called
/// 5. Backend credits the affiliate's account
///
/// ## Usage
/// ```swift
/// let service = AffiliateService.shared
///
/// // Apply a code
/// try await service.applyAffiliateCode("COACH_MIKE_20")
///
/// // Check if a code is applied
/// if let code = service.affiliateCode {
///     print("Referred by: \(code)")
/// }
///
/// // Track conversion on purchase
/// service.trackAffiliateConversion()
/// ```
@MainActor
class AffiliateService: ObservableObject {

    // MARK: - Singleton

    static let shared = AffiliateService()

    // MARK: - Dependencies

    private let supabase: PTSupabaseClient
    private let logger: DebugLogger

    // MARK: - Constants

    private enum Constants {
        static let affiliateCodeKey = "applied_affiliate_code"
        static let affiliateInfoKey = "affiliate_info_data"
        static let affiliateCodesTable = "affiliate_codes"
        static let affiliateAttributionsTable = "affiliate_attributions"
        static let affiliateConversionsTable = "affiliate_conversions"
        static let edgeFunctionValidate = "validate-affiliate-code"
    }

    // MARK: - Published Properties

    /// The currently applied affiliate code, if any
    @Published var affiliateCode: String?

    /// Full affiliate info after validation
    @Published var affiliateInfo: AffiliateInfo?

    /// Loading state
    @Published var isLoading = false

    /// Error message for display
    @Published var errorMessage: String?

    /// Whether an affiliate code has been applied
    var hasAffiliateCode: Bool {
        affiliateCode != nil && !affiliateCode!.isEmpty
    }

    // MARK: - Initialization

    init(
        supabase: PTSupabaseClient = .shared,
        logger: DebugLogger = .shared
    ) {
        self.supabase = supabase
        self.logger = logger

        // Restore saved affiliate code
        self.affiliateCode = UserDefaults.standard.string(forKey: Constants.affiliateCodeKey)
        self.affiliateInfo = loadSavedAffiliateInfo()

        if let code = affiliateCode {
            logger.info("AffiliateService", "Restored affiliate code: \(code)")
        } else {
            logger.info("AffiliateService", "No affiliate code applied")
        }
    }

    // MARK: - Apply Affiliate Code

    /// Validates and applies an affiliate code.
    ///
    /// The code is validated against the Supabase backend. If valid, it is
    /// persisted locally and attributed to the user's account.
    ///
    /// - Parameter code: The affiliate code to apply (case-insensitive)
    /// - Throws: `AffiliateError` if the code is invalid, expired, or already applied
    func applyAffiliateCode(_ code: String) async throws {
        let normalizedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        logger.info("AffiliateService", "Applying affiliate code: \(normalizedCode)")
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // Check for existing code
        guard affiliateCode == nil else {
            let error = AffiliateError.codeAlreadyApplied
            logger.warning("AffiliateService", "Code already applied: \(affiliateCode ?? "unknown")")
            errorMessage = error.errorDescription
            throw error
        }

        // Validate code is not empty
        guard !normalizedCode.isEmpty else {
            let error = AffiliateError.invalidCode
            logger.warning("AffiliateService", "Empty affiliate code submitted")
            errorMessage = error.errorDescription
            throw error
        }

        // Validate against backend
        do {
            let response = try await supabase.client
                .from(Constants.affiliateCodesTable)
                .select()
                .eq("code", value: normalizedCode)
                .eq("is_active", value: true)
                .single()
                .execute()

            let decoder = PTSupabaseClient.flexibleDecoder

            struct AffiliateCodeRecord: Decodable {
                let code: String
                let affiliateName: String
                let discountPercent: Int?
                let isActive: Bool
                let expiresAt: Date?

                enum CodingKeys: String, CodingKey {
                    case code
                    case affiliateName = "affiliate_name"
                    case discountPercent = "discount_percent"
                    case isActive = "is_active"
                    case expiresAt = "expires_at"
                }
            }

            let record = try decoder.decode(AffiliateCodeRecord.self, from: response.data)

            // Check expiry
            if let expiresAt = record.expiresAt, expiresAt < Date() {
                let error = AffiliateError.codeExpired
                logger.warning("AffiliateService", "Affiliate code expired: \(normalizedCode)")
                errorMessage = error.errorDescription
                throw error
            }

            // Apply the code
            let info = AffiliateInfo(
                code: normalizedCode,
                affiliateName: record.affiliateName,
                discountPercent: record.discountPercent,
                appliedAt: Date(),
                isActive: true
            )

            affiliateCode = normalizedCode
            affiliateInfo = info

            // Persist locally
            UserDefaults.standard.set(normalizedCode, forKey: Constants.affiliateCodeKey)
            saveAffiliateInfo(info)

            // Record attribution on backend
            await recordAttribution(code: normalizedCode)

            logger.success("AffiliateService", "Applied affiliate code: \(normalizedCode) (affiliate: \(record.affiliateName))")

        } catch let error as AffiliateError {
            throw error
        } catch {
            // Handle as invalid code (could be network error or no matching record)
            logger.warning("AffiliateService", "Failed to validate affiliate code: \(error.localizedDescription)")

            if error.isCancellation {
                return
            }

            let affiliateError = AffiliateError.invalidCode
            errorMessage = affiliateError.errorDescription
            throw affiliateError
        }
    }

    // MARK: - Track Conversion

    /// Records an affiliate conversion when a referred user makes a subscription purchase.
    ///
    /// Should be called immediately after a successful subscription purchase.
    /// The backend uses this to credit the affiliate's account.
    func trackAffiliateConversion() {
        guard let code = affiliateCode else {
            logger.diagnostic("AffiliateService: No affiliate code to track conversion for")
            return
        }

        guard let userId = supabase.userId else {
            logger.warning("AffiliateService", "Cannot track conversion - no authenticated user")
            return
        }

        logger.info("AffiliateService", "Tracking affiliate conversion for code: \(code)")

        Task {
            do {
                try await supabase.client
                    .from(Constants.affiliateConversionsTable)
                    .insert([
                        "user_id": userId,
                        "affiliate_code": code,
                        "converted_at": ISO8601DateFormatter().string(from: Date()),
                        "source": "subscription_purchase"
                    ])
                    .execute()

                logger.success("AffiliateService", "Tracked affiliate conversion: \(code)")
            } catch {
                logger.error("AffiliateService", "Failed to track affiliate conversion: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Remove Affiliate Code

    /// Clears the applied affiliate code (admin use or testing).
    func clearAffiliateCode() {
        logger.info("AffiliateService", "Clearing affiliate code: \(affiliateCode ?? "none")")
        affiliateCode = nil
        affiliateInfo = nil
        UserDefaults.standard.removeObject(forKey: Constants.affiliateCodeKey)
        UserDefaults.standard.removeObject(forKey: Constants.affiliateInfoKey)
    }

    // MARK: - Private Helpers

    /// Records the affiliate attribution to the backend for the current user.
    private func recordAttribution(code: String) async {
        guard let userId = supabase.userId else {
            logger.warning("AffiliateService", "Cannot record attribution - no authenticated user")
            return
        }

        do {
            try await supabase.client
                .from(Constants.affiliateAttributionsTable)
                .upsert([
                    "user_id": userId,
                    "affiliate_code": code,
                    "attributed_at": ISO8601DateFormatter().string(from: Date()),
                    "source": "in_app"
                ])
                .execute()

            logger.success("AffiliateService", "Recorded affiliate attribution: \(code)")
        } catch {
            logger.warning("AffiliateService", "Failed to record attribution: \(error.localizedDescription)")
        }
    }

    /// Persists affiliate info to UserDefaults for offline access.
    private func saveAffiliateInfo(_ info: AffiliateInfo) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(info)
            UserDefaults.standard.set(data, forKey: Constants.affiliateInfoKey)
        } catch {
            logger.warning("AffiliateService", "Failed to save affiliate info: \(error.localizedDescription)")
        }
    }

    /// Loads affiliate info from UserDefaults.
    private func loadSavedAffiliateInfo() -> AffiliateInfo? {
        guard let data = UserDefaults.standard.data(forKey: Constants.affiliateInfoKey) else {
            return nil
        }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(AffiliateInfo.self, from: data)
        } catch {
            return nil
        }
    }
}
