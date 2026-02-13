//
//  Achievement.swift
//  PTPerformance
//
//  Gamification Polish - Milestone Celebrations & Achievements
//  Model definitions for the achievement system
//

import Foundation

// MARK: - Achievement Type

/// Types of achievements that can be unlocked
enum AchievementType: String, Codable, CaseIterable, Identifiable {
    case streak = "streak"
    case volume = "volume"
    case workouts = "workouts"
    case personalRecord = "personal_record"
    case consistency = "consistency"
    case special = "special"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .streak: return "Streak"
        case .volume: return "Volume"
        case .workouts: return "Workouts"
        case .personalRecord: return "Personal Records"
        case .consistency: return "Consistency"
        case .special: return "Special"
        }
    }

    var iconName: String {
        switch self {
        case .streak: return "flame.fill"
        case .volume: return "scalemass.fill"
        case .workouts: return "figure.strengthtraining.traditional"
        case .personalRecord: return "trophy.fill"
        case .consistency: return "calendar.badge.checkmark"
        case .special: return "star.fill"
        }
    }

    var colorName: String {
        switch self {
        case .streak: return "orange"
        case .volume: return "blue"
        case .workouts: return "green"
        case .personalRecord: return "yellow"
        case .consistency: return "purple"
        case .special: return "pink"
        }
    }
}

// MARK: - Achievement Tier

/// Tiers for achievement rarity/difficulty
enum AchievementTier: String, Codable, CaseIterable, Comparable {
    case bronze = "bronze"
    case silver = "silver"
    case gold = "gold"
    case platinum = "platinum"
    case diamond = "diamond"

    var displayName: String {
        rawValue.capitalized
    }

    var colorName: String {
        switch self {
        case .bronze: return "bronze"
        case .silver: return "silver"
        case .gold: return "yellow"
        case .platinum: return "platinum"
        case .diamond: return "cyan"
        }
    }

    var glowColorName: String {
        switch self {
        case .bronze: return "bronze"
        case .silver: return "gray"
        case .gold: return "yellow"
        case .platinum: return "white"
        case .diamond: return "cyan"
        }
    }

    var points: Int {
        switch self {
        case .bronze: return 10
        case .silver: return 25
        case .gold: return 50
        case .platinum: return 100
        case .diamond: return 200
        }
    }

    static func < (lhs: AchievementTier, rhs: AchievementTier) -> Bool {
        let order: [AchievementTier] = [.bronze, .silver, .gold, .platinum, .diamond]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
}

// MARK: - Achievement Definition

/// Static definition of an achievement that can be unlocked
struct AchievementDefinition: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let type: AchievementType
    let tier: AchievementTier
    let iconName: String
    let requirement: Int
    let requirementUnit: String

    var formattedRequirement: String {
        "\(requirement) \(requirementUnit)"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: AchievementDefinition, rhs: AchievementDefinition) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Unlocked Achievement

/// Record of an unlocked achievement for a user
struct UnlockedAchievement: Codable, Identifiable, Hashable {
    let id: UUID
    let achievementId: String
    let patientId: UUID
    let unlockedAt: Date
    let currentValue: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case achievementId = "achievement_id"
        case patientId = "patient_id"
        case unlockedAt = "unlocked_at"
        case currentValue = "current_value"
    }

    init(id: UUID = UUID(), achievementId: String, patientId: UUID, unlockedAt: Date = Date(), currentValue: Int? = nil) {
        self.id = id
        self.achievementId = achievementId
        self.patientId = patientId
        self.unlockedAt = unlockedAt
        self.currentValue = currentValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required UUID with fallback
        id = container.safeUUID(forKey: .id)
        patientId = container.safeUUID(forKey: .patientId)

        // Required string with fallback
        achievementId = container.safeString(forKey: .achievementId, default: "unknown")

        // Date with fallback
        unlockedAt = container.safeDate(forKey: .unlockedAt)

        // Optional int
        currentValue = container.safeOptionalInt(forKey: .currentValue)
    }
}

// MARK: - Achievement Progress

/// Progress toward an achievement
struct AchievementProgress: Identifiable {
    let definition: AchievementDefinition
    var currentValue: Int
    var isUnlocked: Bool
    var unlockedAt: Date?

    var id: String { definition.id }

    var progress: Double {
        min(Double(currentValue) / Double(definition.requirement), 1.0)
    }

    var progressPercentage: Int {
        Int(progress * 100)
    }

    var remainingValue: Int {
        max(0, definition.requirement - currentValue)
    }
}

// MARK: - Achievement Catalog

/// Static catalog of all available achievements
enum AchievementCatalog {

    // MARK: - Streak Achievements

    static let streak7Day = AchievementDefinition(
        id: "streak_7_day",
        title: "Week Warrior",
        description: "Complete a 7-day workout streak",
        type: .streak,
        tier: .bronze,
        iconName: "flame.fill",
        requirement: 7,
        requirementUnit: "days"
    )

    static let streak14Day = AchievementDefinition(
        id: "streak_14_day",
        title: "Fortnight Fighter",
        description: "Complete a 14-day workout streak",
        type: .streak,
        tier: .silver,
        iconName: "flame.fill",
        requirement: 14,
        requirementUnit: "days"
    )

    static let streak30Day = AchievementDefinition(
        id: "streak_30_day",
        title: "Monthly Master",
        description: "Complete a 30-day workout streak",
        type: .streak,
        tier: .gold,
        iconName: "flame.fill",
        requirement: 30,
        requirementUnit: "days"
    )

    static let streak60Day = AchievementDefinition(
        id: "streak_60_day",
        title: "Dedicated Athlete",
        description: "Complete a 60-day workout streak",
        type: .streak,
        tier: .platinum,
        iconName: "flame.fill",
        requirement: 60,
        requirementUnit: "days"
    )

    static let streak100Day = AchievementDefinition(
        id: "streak_100_day",
        title: "Century Champion",
        description: "Complete a 100-day workout streak",
        type: .streak,
        tier: .diamond,
        iconName: "flame.fill",
        requirement: 100,
        requirementUnit: "days"
    )

    // MARK: - Workout Achievements

    static let firstWorkout = AchievementDefinition(
        id: "first_workout",
        title: "First Steps",
        description: "Complete your first workout",
        type: .workouts,
        tier: .bronze,
        iconName: "figure.walk",
        requirement: 1,
        requirementUnit: "workout"
    )

    static let workouts10 = AchievementDefinition(
        id: "workouts_10",
        title: "Getting Started",
        description: "Complete 10 workouts",
        type: .workouts,
        tier: .bronze,
        iconName: "figure.strengthtraining.traditional",
        requirement: 10,
        requirementUnit: "workouts"
    )

    static let workouts25 = AchievementDefinition(
        id: "workouts_25",
        title: "Quarter Century",
        description: "Complete 25 workouts",
        type: .workouts,
        tier: .silver,
        iconName: "figure.strengthtraining.traditional",
        requirement: 25,
        requirementUnit: "workouts"
    )

    static let workouts50 = AchievementDefinition(
        id: "workouts_50",
        title: "Halfway Hero",
        description: "Complete 50 workouts",
        type: .workouts,
        tier: .silver,
        iconName: "figure.strengthtraining.traditional",
        requirement: 50,
        requirementUnit: "workouts"
    )

    static let workouts100 = AchievementDefinition(
        id: "workouts_100",
        title: "Century Club",
        description: "Complete 100 workouts",
        type: .workouts,
        tier: .gold,
        iconName: "figure.strengthtraining.traditional",
        requirement: 100,
        requirementUnit: "workouts"
    )

    static let workouts250 = AchievementDefinition(
        id: "workouts_250",
        title: "Iron Devotee",
        description: "Complete 250 workouts",
        type: .workouts,
        tier: .platinum,
        iconName: "figure.strengthtraining.traditional",
        requirement: 250,
        requirementUnit: "workouts"
    )

    static let workouts500 = AchievementDefinition(
        id: "workouts_500",
        title: "Legendary Lifter",
        description: "Complete 500 workouts",
        type: .workouts,
        tier: .diamond,
        iconName: "figure.strengthtraining.traditional",
        requirement: 500,
        requirementUnit: "workouts"
    )

    // MARK: - Personal Record Achievements

    static let firstPR = AchievementDefinition(
        id: "first_pr",
        title: "Record Breaker",
        description: "Set your first personal record",
        type: .personalRecord,
        tier: .bronze,
        iconName: "trophy.fill",
        requirement: 1,
        requirementUnit: "PR"
    )

    static let prs5 = AchievementDefinition(
        id: "prs_5",
        title: "PR Chaser",
        description: "Set 5 personal records",
        type: .personalRecord,
        tier: .silver,
        iconName: "trophy.fill",
        requirement: 5,
        requirementUnit: "PRs"
    )

    static let prs10 = AchievementDefinition(
        id: "prs_10",
        title: "PR Hunter",
        description: "Set 10 personal records",
        type: .personalRecord,
        tier: .gold,
        iconName: "trophy.fill",
        requirement: 10,
        requirementUnit: "PRs"
    )

    static let prs25 = AchievementDefinition(
        id: "prs_25",
        title: "PR Machine",
        description: "Set 25 personal records",
        type: .personalRecord,
        tier: .platinum,
        iconName: "trophy.fill",
        requirement: 25,
        requirementUnit: "PRs"
    )

    // MARK: - Volume Achievements

    static let volume10k = AchievementDefinition(
        id: "volume_10k",
        title: "10K Club",
        description: "Lift 10,000 lbs total volume",
        type: .volume,
        tier: .bronze,
        iconName: "scalemass.fill",
        requirement: 10000,
        requirementUnit: "lbs"
    )

    static let volume50k = AchievementDefinition(
        id: "volume_50k",
        title: "50K Strong",
        description: "Lift 50,000 lbs total volume",
        type: .volume,
        tier: .silver,
        iconName: "scalemass.fill",
        requirement: 50000,
        requirementUnit: "lbs"
    )

    static let volume100k = AchievementDefinition(
        id: "volume_100k",
        title: "100K Titan",
        description: "Lift 100,000 lbs total volume",
        type: .volume,
        tier: .gold,
        iconName: "scalemass.fill",
        requirement: 100000,
        requirementUnit: "lbs"
    )

    static let volume500k = AchievementDefinition(
        id: "volume_500k",
        title: "Half Million",
        description: "Lift 500,000 lbs total volume",
        type: .volume,
        tier: .platinum,
        iconName: "scalemass.fill",
        requirement: 500000,
        requirementUnit: "lbs"
    )

    static let volume1m = AchievementDefinition(
        id: "volume_1m",
        title: "Million Pound Legend",
        description: "Lift 1,000,000 lbs total volume",
        type: .volume,
        tier: .diamond,
        iconName: "scalemass.fill",
        requirement: 1000000,
        requirementUnit: "lbs"
    )

    // MARK: - All Achievements

    static let all: [AchievementDefinition] = [
        // Streaks
        streak7Day, streak14Day, streak30Day, streak60Day, streak100Day,
        // Workouts
        firstWorkout, workouts10, workouts25, workouts50, workouts100, workouts250, workouts500,
        // Personal Records
        firstPR, prs5, prs10, prs25,
        // Volume
        volume10k, volume50k, volume100k, volume500k, volume1m
    ]

    /// Get achievement definition by ID
    static func get(_ id: String) -> AchievementDefinition? {
        all.first { $0.id == id }
    }

    /// Get achievements by type
    static func byType(_ type: AchievementType) -> [AchievementDefinition] {
        all.filter { $0.type == type }
    }

    /// Get achievements by tier
    static func byTier(_ tier: AchievementTier) -> [AchievementDefinition] {
        all.filter { $0.tier == tier }
    }
}

// MARK: - Achievement Event

/// Event representing an achievement unlock
struct AchievementUnlockEvent: Identifiable, Equatable {
    let achievement: AchievementDefinition
    let unlockedAt: Date
    let previousValue: Int?
    let newValue: Int

    var id: String { "\(achievement.id)-\(unlockedAt.timeIntervalSince1970)" }

    init(achievement: AchievementDefinition, unlockedAt: Date = Date(), previousValue: Int? = nil, newValue: Int) {
        self.achievement = achievement
        self.unlockedAt = unlockedAt
        self.previousValue = previousValue
        self.newValue = newValue
    }

    static func == (lhs: AchievementUnlockEvent, rhs: AchievementUnlockEvent) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Streak Milestone

/// Milestone values for streak celebrations
enum StreakMilestone: Int, CaseIterable {
    case week = 7
    case twoWeeks = 14
    case month = 30
    case twoMonths = 60
    case threeMonths = 90
    case hundred = 100

    var displayName: String {
        switch self {
        case .week: return "1 Week"
        case .twoWeeks: return "2 Weeks"
        case .month: return "1 Month"
        case .twoMonths: return "2 Months"
        case .threeMonths: return "3 Months"
        case .hundred: return "100 Days"
        }
    }

    var celebrationMessage: String {
        switch self {
        case .week: return "One week strong!"
        case .twoWeeks: return "Two weeks of dedication!"
        case .month: return "A full month! Incredible!"
        case .twoMonths: return "Two months of consistency!"
        case .threeMonths: return "Three months! You're unstoppable!"
        case .hundred: return "100 DAYS! LEGENDARY!"
        }
    }

    var confettiCount: Int {
        switch self {
        case .week: return 20
        case .twoWeeks: return 35
        case .month: return 50
        case .twoMonths: return 75
        case .threeMonths: return 100
        case .hundred: return 150
        }
    }

    static func milestone(for streak: Int) -> StreakMilestone? {
        allCases.first { $0.rawValue == streak }
    }

    static func highestAchieved(for streak: Int) -> StreakMilestone? {
        allCases.reversed().first { streak >= $0.rawValue }
    }
}

// MARK: - PR Celebration Type

/// Types of personal record celebrations
enum PRCelebrationType {
    case firstPR
    case newPR
    case majorPR // Significant improvement
    case milestonePR // e.g., 100kg, 225lbs

    var title: String {
        switch self {
        case .firstPR: return "First PR!"
        case .newPR: return "New PR!"
        case .majorPR: return "Major PR!"
        case .milestonePR: return "Milestone PR!"
        }
    }

    var subtitle: String {
        switch self {
        case .firstPR: return "You've set your first personal record!"
        case .newPR: return "You've beaten your previous best!"
        case .majorPR: return "Massive improvement!"
        case .milestonePR: return "You've hit a major milestone!"
        }
    }

    var iconName: String {
        switch self {
        case .firstPR: return "trophy.fill"
        case .newPR: return "star.fill"
        case .majorPR: return "crown.fill"
        case .milestonePR: return "medal.fill"
        }
    }

    var colorName: String {
        switch self {
        case .firstPR: return "yellow"
        case .newPR: return "orange"
        case .majorPR: return "purple"
        case .milestonePR: return "cyan"
        }
    }
}

// MARK: - Preview Support

#if DEBUG
extension AchievementProgress {
    static let sampleLocked = AchievementProgress(
        definition: AchievementCatalog.streak30Day,
        currentValue: 12,
        isUnlocked: false,
        unlockedAt: nil
    )

    static let sampleUnlocked = AchievementProgress(
        definition: AchievementCatalog.streak7Day,
        currentValue: 7,
        isUnlocked: true,
        unlockedAt: Calendar.current.date(byAdding: .day, value: -5, to: Date())
    )

    static let sampleArray: [AchievementProgress] = [
        AchievementProgress(
            definition: AchievementCatalog.firstWorkout,
            currentValue: 1,
            isUnlocked: true,
            unlockedAt: Calendar.current.date(byAdding: .month, value: -2, to: Date())
        ),
        AchievementProgress(
            definition: AchievementCatalog.streak7Day,
            currentValue: 7,
            isUnlocked: true,
            unlockedAt: Calendar.current.date(byAdding: .day, value: -5, to: Date())
        ),
        AchievementProgress(
            definition: AchievementCatalog.workouts10,
            currentValue: 10,
            isUnlocked: true,
            unlockedAt: Calendar.current.date(byAdding: .day, value: -3, to: Date())
        ),
        AchievementProgress(
            definition: AchievementCatalog.streak30Day,
            currentValue: 18,
            isUnlocked: false,
            unlockedAt: nil
        ),
        AchievementProgress(
            definition: AchievementCatalog.workouts100,
            currentValue: 45,
            isUnlocked: false,
            unlockedAt: nil
        ),
        AchievementProgress(
            definition: AchievementCatalog.volume100k,
            currentValue: 67500,
            isUnlocked: false,
            unlockedAt: nil
        )
    ]
}

extension AchievementUnlockEvent {
    static let sample = AchievementUnlockEvent(
        achievement: AchievementCatalog.streak7Day,
        previousValue: 6,
        newValue: 7
    )
}
#endif
