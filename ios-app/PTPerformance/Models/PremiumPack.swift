//
//  PremiumPack.swift
//  PTPerformance
//
//  Model representing a premium content pack subscription
//

import SwiftUI

/// A premium content pack available for subscription
struct PremiumPack: Codable, Identifiable, Hashable, Equatable {
    let id: UUID
    let code: String
    let name: String
    let description: String
    let iconName: String
    let basePriceMonthly: Decimal
    let bundlePriceMonthly: Decimal?
    let isAddon: Bool
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case code
        case name
        case description
        case iconName = "icon_name"
        case basePriceMonthly = "base_price_monthly"
        case bundlePriceMonthly = "bundle_price_monthly"
        case isAddon = "is_addon"
        case sortOrder = "sort_order"
    }

    // MARK: - Computed Properties

    /// SF Symbol for the pack icon
    var icon: String {
        iconName
    }

    /// Formatted monthly price string
    var formattedMonthlyPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: basePriceMonthly as NSDecimalNumber) ?? "$\(basePriceMonthly)/mo"
    }

    /// Formatted bundle price string (if available)
    var formattedBundlePrice: String? {
        guard let bundlePrice = bundlePriceMonthly else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: bundlePrice as NSDecimalNumber)
    }

    /// Whether this pack has a bundle pricing option
    var hasBundlePricing: Bool {
        bundlePriceMonthly != nil
    }

    /// Savings amount when using bundle pricing
    var bundleSavings: Decimal? {
        guard let bundlePrice = bundlePriceMonthly else { return nil }
        return basePriceMonthly - bundlePrice
    }

    /// Color associated with this pack
    var themeColor: Color {
        switch code.uppercased() {
        case "BASE":
            return .blue
        case "BASEBALL":
            return .orange
        case "NUTRITION":
            return .green
        case "RECOVERY":
            return .teal
        case "PERFORMANCE":
            return .purple
        case "COACHING":
            return .red
        default:
            return .gray
        }
    }

    /// Whether this is the base/core pack
    var isCorePack: Bool {
        code.uppercased() == "BASE"
    }
}

// MARK: - Pack Code Enum

/// Known pack codes for type-safe access
enum PackCode: String, CaseIterable, Identifiable {
    case base = "BASE"
    case baseball = "BASEBALL"
    case nutrition = "NUTRITION"
    case recovery = "RECOVERY"
    case performance = "PERFORMANCE"
    case coaching = "COACHING"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .base: return "Base Pack"
        case .baseball: return "Baseball Pack"
        case .nutrition: return "Nutrition Pack"
        case .recovery: return "Recovery Pack"
        case .performance: return "Performance Pack"
        case .coaching: return "Coaching Pack"
        }
    }

    var icon: String {
        switch self {
        case .base: return "star.fill"
        case .baseball: return "baseball.fill"
        case .nutrition: return "leaf.fill"
        case .recovery: return "bed.double.fill"
        case .performance: return "bolt.fill"
        case .coaching: return "person.fill.checkmark"
        }
    }

    var description: String {
        switch self {
        case .base:
            return "Core training programs and workout tracking essentials"
        case .baseball:
            return "Specialized baseball training, arm care, and velocity programs"
        case .nutrition:
            return "Meal planning, macro tracking, and nutrition guidance"
        case .recovery:
            return "Recovery protocols, sleep optimization, and injury prevention"
        case .performance:
            return "Advanced analytics, AI coaching, and performance insights"
        case .coaching:
            return "Direct access to professional coaching and personalized feedback"
        }
    }

    var color: Color {
        switch self {
        case .base: return .blue
        case .baseball: return .orange
        case .nutrition: return .green
        case .recovery: return .teal
        case .performance: return .purple
        case .coaching: return .red
        }
    }
}

// MARK: - User Pack Subscription

/// A user's subscription to a premium pack
struct UserPackSubscription: Codable, Identifiable, Hashable, Equatable {
    let id: UUID
    let userId: UUID
    let packId: UUID
    let packCode: String
    let status: String
    let startDate: Date
    let endDate: Date?
    let isActive: Bool
    let autoRenew: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case packId = "pack_id"
        case packCode = "pack_code"
        case status
        case startDate = "start_date"
        case endDate = "end_date"
        case isActive = "is_active"
        case autoRenew = "auto_renew"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Computed Properties

    /// Parsed subscription status
    var subscriptionStatus: SubscriptionStatus {
        SubscriptionStatus(rawValue: status) ?? .active
    }

    /// Whether the subscription is currently valid
    var isCurrentlyValid: Bool {
        guard isActive else { return false }
        if let end = endDate {
            return end > Date()
        }
        return true
    }

    /// Days remaining in subscription (if applicable)
    var daysRemaining: Int? {
        guard let end = endDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: end)
        return max(0, components.day ?? 0)
    }

    /// Subscription status enumeration
    enum SubscriptionStatus: String, Codable, CaseIterable {
        case active
        case expired
        case cancelled
        case pending
        case trial

        var displayName: String {
            switch self {
            case .active: return "Active"
            case .expired: return "Expired"
            case .cancelled: return "Cancelled"
            case .pending: return "Pending"
            case .trial: return "Trial"
            }
        }

        var icon: String {
            switch self {
            case .active: return "checkmark.circle.fill"
            case .expired: return "clock.badge.exclamationmark.fill"
            case .cancelled: return "xmark.circle.fill"
            case .pending: return "clock.fill"
            case .trial: return "gift.fill"
            }
        }

        var color: Color {
            switch self {
            case .active: return .green
            case .expired: return .red
            case .cancelled: return .gray
            case .pending: return .orange
            case .trial: return .purple
            }
        }
    }
}

// MARK: - Pack with Programs

/// Combined pack data with its associated programs
struct PackWithPrograms: Identifiable {
    let pack: PremiumPack
    let programs: [ProgramLibrary]
    let isSubscribed: Bool

    var id: UUID { pack.id }

    /// Number of programs in this pack
    var programCount: Int {
        programs.count
    }
}

// MARK: - Preview Support

#if DEBUG
extension PremiumPack {
    static let preview = PremiumPack(
        id: UUID(),
        code: "BASEBALL",
        name: "Baseball Pack",
        description: "Specialized baseball training programs including arm care, velocity development, and position-specific workouts designed by professional coaches.",
        iconName: "baseball.fill",
        basePriceMonthly: Decimal(9.99),
        bundlePriceMonthly: Decimal(7.99),
        isAddon: true,
        sortOrder: 2
    )

    static let previewBase = PremiumPack(
        id: UUID(),
        code: "BASE",
        name: "Base Pack",
        description: "Core training programs and workout tracking essentials for strength, mobility, and conditioning.",
        iconName: "star.fill",
        basePriceMonthly: Decimal(14.99),
        bundlePriceMonthly: nil,
        isAddon: false,
        sortOrder: 1
    )
}

extension UserPackSubscription {
    static let preview = UserPackSubscription(
        id: UUID(),
        userId: UUID(),
        packId: UUID(),
        packCode: "BASEBALL",
        status: "active",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
        isActive: true,
        autoRenew: true,
        createdAt: Date(),
        updatedAt: Date()
    )
}
#endif
