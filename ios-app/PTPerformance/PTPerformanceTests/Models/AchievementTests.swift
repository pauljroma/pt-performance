//
//  AchievementTests.swift
//  PTPerformanceTests
//
//  Comprehensive tests for Achievement models including achievement unlocking logic,
//  progress tracking, badge types, tiers, and the achievement catalog.
//

import XCTest
import SwiftUI
@testable import PTPerformance

// MARK: - Achievement Type Tests

final class AchievementTypeTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testAchievementType_RawValues() {
        XCTAssertEqual(AchievementType.streak.rawValue, "streak")
        XCTAssertEqual(AchievementType.volume.rawValue, "volume")
        XCTAssertEqual(AchievementType.workouts.rawValue, "workouts")
        XCTAssertEqual(AchievementType.personalRecord.rawValue, "personal_record")
        XCTAssertEqual(AchievementType.consistency.rawValue, "consistency")
        XCTAssertEqual(AchievementType.special.rawValue, "special")
    }

    // MARK: - Display Name Tests

    func testAchievementType_DisplayNames() {
        XCTAssertEqual(AchievementType.streak.displayName, "Streak")
        XCTAssertEqual(AchievementType.volume.displayName, "Volume")
        XCTAssertEqual(AchievementType.workouts.displayName, "Workouts")
        XCTAssertEqual(AchievementType.personalRecord.displayName, "Personal Records")
        XCTAssertEqual(AchievementType.consistency.displayName, "Consistency")
        XCTAssertEqual(AchievementType.special.displayName, "Special")
    }

    // MARK: - Icon Tests

    func testAchievementType_Icons() {
        XCTAssertEqual(AchievementType.streak.iconName, "flame.fill")
        XCTAssertEqual(AchievementType.volume.iconName, "scalemass.fill")
        XCTAssertEqual(AchievementType.workouts.iconName, "figure.strengthtraining.traditional")
        XCTAssertEqual(AchievementType.personalRecord.iconName, "trophy.fill")
        XCTAssertEqual(AchievementType.consistency.iconName, "calendar.badge.checkmark")
        XCTAssertEqual(AchievementType.special.iconName, "star.fill")
    }

    // MARK: - Color Tests

    func testAchievementType_Colors() {
        XCTAssertEqual(AchievementType.streak.color, .orange)
        XCTAssertEqual(AchievementType.volume.color, .blue)
        XCTAssertEqual(AchievementType.workouts.color, .green)
        XCTAssertEqual(AchievementType.personalRecord.color, .yellow)
        XCTAssertEqual(AchievementType.consistency.color, .purple)
        XCTAssertEqual(AchievementType.special.color, .pink)
    }

    // MARK: - Identifiable Tests

    func testAchievementType_Identifiable() {
        for type in AchievementType.allCases {
            XCTAssertEqual(type.id, type.rawValue)
        }
    }

    // MARK: - CaseIterable Tests

    func testAchievementType_AllCases() {
        let allCases = AchievementType.allCases
        XCTAssertEqual(allCases.count, 6)
    }
}

// MARK: - Achievement Tier Tests

final class AchievementTierTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testAchievementTier_RawValues() {
        XCTAssertEqual(AchievementTier.bronze.rawValue, "bronze")
        XCTAssertEqual(AchievementTier.silver.rawValue, "silver")
        XCTAssertEqual(AchievementTier.gold.rawValue, "gold")
        XCTAssertEqual(AchievementTier.platinum.rawValue, "platinum")
        XCTAssertEqual(AchievementTier.diamond.rawValue, "diamond")
    }

    // MARK: - Display Name Tests

    func testAchievementTier_DisplayNames() {
        XCTAssertEqual(AchievementTier.bronze.displayName, "Bronze")
        XCTAssertEqual(AchievementTier.silver.displayName, "Silver")
        XCTAssertEqual(AchievementTier.gold.displayName, "Gold")
        XCTAssertEqual(AchievementTier.platinum.displayName, "Platinum")
        XCTAssertEqual(AchievementTier.diamond.displayName, "Diamond")
    }

    // MARK: - Points Tests

    func testAchievementTier_Points() {
        XCTAssertEqual(AchievementTier.bronze.points, 10)
        XCTAssertEqual(AchievementTier.silver.points, 25)
        XCTAssertEqual(AchievementTier.gold.points, 50)
        XCTAssertEqual(AchievementTier.platinum.points, 100)
        XCTAssertEqual(AchievementTier.diamond.points, 200)
    }

    // MARK: - Comparable Tests

    func testAchievementTier_Comparable() {
        XCTAssertLessThan(AchievementTier.bronze, AchievementTier.silver)
        XCTAssertLessThan(AchievementTier.silver, AchievementTier.gold)
        XCTAssertLessThan(AchievementTier.gold, AchievementTier.platinum)
        XCTAssertLessThan(AchievementTier.platinum, AchievementTier.diamond)
    }

    func testAchievementTier_ComparableTransitive() {
        XCTAssertLessThan(AchievementTier.bronze, AchievementTier.diamond)
        XCTAssertGreaterThan(AchievementTier.diamond, AchievementTier.bronze)
    }

    // MARK: - CaseIterable Tests

    func testAchievementTier_AllCases() {
        let allCases = AchievementTier.allCases
        XCTAssertEqual(allCases.count, 5)
    }
}

// MARK: - Achievement Definition Tests

final class AchievementDefinitionTests: XCTestCase {

    // MARK: - Creation Tests

    func testAchievementDefinition_Creation() {
        let definition = AchievementDefinition(
            id: "test_achievement",
            title: "Test Achievement",
            description: "A test achievement",
            type: .streak,
            tier: .gold,
            iconName: "star.fill",
            requirement: 30,
            requirementUnit: "days"
        )

        XCTAssertEqual(definition.id, "test_achievement")
        XCTAssertEqual(definition.title, "Test Achievement")
        XCTAssertEqual(definition.description, "A test achievement")
        XCTAssertEqual(definition.type, .streak)
        XCTAssertEqual(definition.tier, .gold)
        XCTAssertEqual(definition.iconName, "star.fill")
        XCTAssertEqual(definition.requirement, 30)
        XCTAssertEqual(definition.requirementUnit, "days")
    }

    // MARK: - Formatted Requirement Tests

    func testAchievementDefinition_FormattedRequirement() {
        let definition = AchievementDefinition(
            id: "test",
            title: "Test",
            description: "Test",
            type: .workouts,
            tier: .bronze,
            iconName: "figure.walk",
            requirement: 100,
            requirementUnit: "workouts"
        )

        XCTAssertEqual(definition.formattedRequirement, "100 workouts")
    }

    // MARK: - Identifiable Tests

    func testAchievementDefinition_Identifiable() {
        let definition = AchievementCatalog.streak7Day
        XCTAssertEqual(definition.id, "streak_7_day")
    }

    // MARK: - Hashable Tests

    func testAchievementDefinition_Hashable() {
        let def1 = AchievementCatalog.streak7Day
        let def2 = AchievementCatalog.streak7Day

        XCTAssertEqual(def1, def2)
        XCTAssertEqual(def1.hashValue, def2.hashValue)
    }

    func testAchievementDefinition_HashableInSet() {
        var set: Set<AchievementDefinition> = []
        set.insert(AchievementCatalog.streak7Day)
        set.insert(AchievementCatalog.streak7Day)

        XCTAssertEqual(set.count, 1)
    }
}

// MARK: - Achievement Catalog Tests

final class AchievementCatalogTests: XCTestCase {

    // MARK: - Streak Achievements Tests

    func testCatalog_Streak7Day() {
        let achievement = AchievementCatalog.streak7Day

        XCTAssertEqual(achievement.id, "streak_7_day")
        XCTAssertEqual(achievement.title, "Week Warrior")
        XCTAssertEqual(achievement.type, .streak)
        XCTAssertEqual(achievement.tier, .bronze)
        XCTAssertEqual(achievement.requirement, 7)
    }

    func testCatalog_Streak14Day() {
        let achievement = AchievementCatalog.streak14Day

        XCTAssertEqual(achievement.id, "streak_14_day")
        XCTAssertEqual(achievement.title, "Fortnight Fighter")
        XCTAssertEqual(achievement.type, .streak)
        XCTAssertEqual(achievement.tier, .silver)
        XCTAssertEqual(achievement.requirement, 14)
    }

    func testCatalog_Streak30Day() {
        let achievement = AchievementCatalog.streak30Day

        XCTAssertEqual(achievement.id, "streak_30_day")
        XCTAssertEqual(achievement.title, "Monthly Master")
        XCTAssertEqual(achievement.type, .streak)
        XCTAssertEqual(achievement.tier, .gold)
        XCTAssertEqual(achievement.requirement, 30)
    }

    func testCatalog_Streak60Day() {
        let achievement = AchievementCatalog.streak60Day

        XCTAssertEqual(achievement.id, "streak_60_day")
        XCTAssertEqual(achievement.title, "Dedicated Athlete")
        XCTAssertEqual(achievement.type, .streak)
        XCTAssertEqual(achievement.tier, .platinum)
        XCTAssertEqual(achievement.requirement, 60)
    }

    func testCatalog_Streak100Day() {
        let achievement = AchievementCatalog.streak100Day

        XCTAssertEqual(achievement.id, "streak_100_day")
        XCTAssertEqual(achievement.title, "Century Champion")
        XCTAssertEqual(achievement.type, .streak)
        XCTAssertEqual(achievement.tier, .diamond)
        XCTAssertEqual(achievement.requirement, 100)
    }

    // MARK: - Workout Achievements Tests

    func testCatalog_FirstWorkout() {
        let achievement = AchievementCatalog.firstWorkout

        XCTAssertEqual(achievement.id, "first_workout")
        XCTAssertEqual(achievement.title, "First Steps")
        XCTAssertEqual(achievement.type, .workouts)
        XCTAssertEqual(achievement.tier, .bronze)
        XCTAssertEqual(achievement.requirement, 1)
    }

    func testCatalog_Workouts100() {
        let achievement = AchievementCatalog.workouts100

        XCTAssertEqual(achievement.id, "workouts_100")
        XCTAssertEqual(achievement.title, "Century Club")
        XCTAssertEqual(achievement.type, .workouts)
        XCTAssertEqual(achievement.tier, .gold)
        XCTAssertEqual(achievement.requirement, 100)
    }

    func testCatalog_Workouts500() {
        let achievement = AchievementCatalog.workouts500

        XCTAssertEqual(achievement.id, "workouts_500")
        XCTAssertEqual(achievement.title, "Legendary Lifter")
        XCTAssertEqual(achievement.type, .workouts)
        XCTAssertEqual(achievement.tier, .diamond)
        XCTAssertEqual(achievement.requirement, 500)
    }

    // MARK: - PR Achievements Tests

    func testCatalog_FirstPR() {
        let achievement = AchievementCatalog.firstPR

        XCTAssertEqual(achievement.id, "first_pr")
        XCTAssertEqual(achievement.title, "Record Breaker")
        XCTAssertEqual(achievement.type, .personalRecord)
        XCTAssertEqual(achievement.tier, .bronze)
        XCTAssertEqual(achievement.requirement, 1)
    }

    func testCatalog_PRs25() {
        let achievement = AchievementCatalog.prs25

        XCTAssertEqual(achievement.id, "prs_25")
        XCTAssertEqual(achievement.title, "PR Machine")
        XCTAssertEqual(achievement.type, .personalRecord)
        XCTAssertEqual(achievement.tier, .platinum)
        XCTAssertEqual(achievement.requirement, 25)
    }

    // MARK: - Volume Achievements Tests

    func testCatalog_Volume10k() {
        let achievement = AchievementCatalog.volume10k

        XCTAssertEqual(achievement.id, "volume_10k")
        XCTAssertEqual(achievement.title, "10K Club")
        XCTAssertEqual(achievement.type, .volume)
        XCTAssertEqual(achievement.tier, .bronze)
        XCTAssertEqual(achievement.requirement, 10000)
    }

    func testCatalog_Volume1m() {
        let achievement = AchievementCatalog.volume1m

        XCTAssertEqual(achievement.id, "volume_1m")
        XCTAssertEqual(achievement.title, "Million Pound Legend")
        XCTAssertEqual(achievement.type, .volume)
        XCTAssertEqual(achievement.tier, .diamond)
        XCTAssertEqual(achievement.requirement, 1000000)
    }

    // MARK: - Catalog Query Tests

    func testCatalog_GetById() {
        let achievement = AchievementCatalog.get("streak_7_day")

        XCTAssertNotNil(achievement)
        XCTAssertEqual(achievement?.id, "streak_7_day")
    }

    func testCatalog_GetById_NotFound() {
        let achievement = AchievementCatalog.get("nonexistent_achievement")
        XCTAssertNil(achievement)
    }

    func testCatalog_ByType_Streak() {
        let streakAchievements = AchievementCatalog.byType(.streak)

        XCTAssertEqual(streakAchievements.count, 5)
        XCTAssertTrue(streakAchievements.allSatisfy { $0.type == .streak })
    }

    func testCatalog_ByType_Workouts() {
        let workoutAchievements = AchievementCatalog.byType(.workouts)

        XCTAssertEqual(workoutAchievements.count, 7)
        XCTAssertTrue(workoutAchievements.allSatisfy { $0.type == .workouts })
    }

    func testCatalog_ByTier_Bronze() {
        let bronzeAchievements = AchievementCatalog.byTier(.bronze)

        XCTAssertTrue(bronzeAchievements.count > 0)
        XCTAssertTrue(bronzeAchievements.allSatisfy { $0.tier == .bronze })
    }

    func testCatalog_ByTier_Diamond() {
        let diamondAchievements = AchievementCatalog.byTier(.diamond)

        XCTAssertTrue(diamondAchievements.count > 0)
        XCTAssertTrue(diamondAchievements.allSatisfy { $0.tier == .diamond })
    }

    func testCatalog_AllAchievements() {
        let all = AchievementCatalog.all

        // Verify count matches expected
        XCTAssertEqual(all.count, 21) // 5 streak + 7 workout + 4 PR + 5 volume

        // Verify all have unique IDs
        let ids = all.map { $0.id }
        XCTAssertEqual(ids.count, Set(ids).count, "All achievements should have unique IDs")
    }
}

// MARK: - Unlocked Achievement Tests

final class UnlockedAchievementTests: XCTestCase {

    func testUnlockedAchievement_Initialization() {
        let patientId = UUID()
        let unlocked = UnlockedAchievement(
            achievementId: "streak_7_day",
            patientId: patientId,
            unlockedAt: Date(),
            currentValue: 7
        )

        XCTAssertEqual(unlocked.achievementId, "streak_7_day")
        XCTAssertEqual(unlocked.patientId, patientId)
        XCTAssertEqual(unlocked.currentValue, 7)
    }

    func testUnlockedAchievement_Codable() throws {
        let original = UnlockedAchievement(
            achievementId: "workouts_10",
            patientId: UUID(),
            currentValue: 10
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let decoded = try decoder.decode(UnlockedAchievement.self, from: data)

        XCTAssertEqual(decoded.achievementId, original.achievementId)
        XCTAssertEqual(decoded.patientId, original.patientId)
        XCTAssertEqual(decoded.currentValue, original.currentValue)
    }

    func testUnlockedAchievement_Hashable() {
        let unlocked1 = UnlockedAchievement(
            id: UUID(),
            achievementId: "streak_7_day",
            patientId: UUID()
        )

        var set: Set<UnlockedAchievement> = []
        set.insert(unlocked1)

        XCTAssertEqual(set.count, 1)
        XCTAssertTrue(set.contains(unlocked1))
    }
}

// MARK: - Achievement Progress Tests

final class AchievementProgressTests: XCTestCase {

    // MARK: - Progress Calculation Tests

    func testAchievementProgress_Calculation() {
        let progress = AchievementProgress(
            definition: AchievementCatalog.streak30Day,
            currentValue: 15,
            isUnlocked: false,
            unlockedAt: nil
        )

        XCTAssertEqual(progress.progress, 0.5, accuracy: 0.01)
        XCTAssertEqual(progress.progressPercentage, 50)
        XCTAssertEqual(progress.remainingValue, 15)
    }

    func testAchievementProgress_AtZero() {
        let progress = AchievementProgress(
            definition: AchievementCatalog.streak7Day,
            currentValue: 0,
            isUnlocked: false,
            unlockedAt: nil
        )

        XCTAssertEqual(progress.progress, 0.0, accuracy: 0.01)
        XCTAssertEqual(progress.progressPercentage, 0)
        XCTAssertEqual(progress.remainingValue, 7)
    }

    func testAchievementProgress_Complete() {
        let progress = AchievementProgress(
            definition: AchievementCatalog.streak7Day,
            currentValue: 7,
            isUnlocked: true,
            unlockedAt: Date()
        )

        XCTAssertEqual(progress.progress, 1.0, accuracy: 0.01)
        XCTAssertEqual(progress.progressPercentage, 100)
        XCTAssertEqual(progress.remainingValue, 0)
    }

    func testAchievementProgress_OverComplete() {
        // When current value exceeds requirement
        let progress = AchievementProgress(
            definition: AchievementCatalog.streak7Day,
            currentValue: 15,
            isUnlocked: true,
            unlockedAt: Date()
        )

        XCTAssertEqual(progress.progress, 1.0, accuracy: 0.01) // Capped at 1.0
        XCTAssertEqual(progress.progressPercentage, 100)
        XCTAssertEqual(progress.remainingValue, 0)
    }

    func testAchievementProgress_Identifiable() {
        let progress = AchievementProgress(
            definition: AchievementCatalog.streak30Day,
            currentValue: 10,
            isUnlocked: false,
            unlockedAt: nil
        )

        XCTAssertEqual(progress.id, "streak_30_day")
    }

    // MARK: - Unlocking Logic Tests

    func testAchievementUnlocking_RequirementMet() {
        let definition = AchievementCatalog.streak7Day

        let currentValue = 7
        let shouldUnlock = currentValue >= definition.requirement

        XCTAssertTrue(shouldUnlock)
    }

    func testAchievementUnlocking_RequirementNotMet() {
        let definition = AchievementCatalog.streak7Day

        let currentValue = 5
        let shouldUnlock = currentValue >= definition.requirement

        XCTAssertFalse(shouldUnlock)
    }

    func testAchievementUnlocking_ExactlyMeetsRequirement() {
        let definition = AchievementCatalog.workouts100

        let currentValue = 100
        let shouldUnlock = currentValue >= definition.requirement

        XCTAssertTrue(shouldUnlock)
    }

    func testAchievementUnlocking_ExceedsRequirement() {
        let definition = AchievementCatalog.workouts100

        let currentValue = 150
        let shouldUnlock = currentValue >= definition.requirement

        XCTAssertTrue(shouldUnlock)
    }
}

// MARK: - Achievement Unlock Event Tests

final class AchievementUnlockEventTests: XCTestCase {

    func testAchievementUnlockEvent_Creation() {
        let event = AchievementUnlockEvent(
            achievement: AchievementCatalog.streak7Day,
            previousValue: 6,
            newValue: 7
        )

        XCTAssertEqual(event.achievement.id, "streak_7_day")
        XCTAssertEqual(event.previousValue, 6)
        XCTAssertEqual(event.newValue, 7)
        XCTAssertNotNil(event.unlockedAt)
    }

    func testAchievementUnlockEvent_Identifiable() {
        let event1 = AchievementUnlockEvent(
            achievement: AchievementCatalog.streak7Day,
            previousValue: 6,
            newValue: 7
        )

        let event2 = AchievementUnlockEvent(
            achievement: AchievementCatalog.streak7Day,
            previousValue: 6,
            newValue: 7
        )

        // Each event should have unique ID
        XCTAssertNotEqual(event1.id, event2.id)
    }

    func testAchievementUnlockEvent_Equatable() {
        let event = AchievementUnlockEvent(
            achievement: AchievementCatalog.streak7Day,
            previousValue: 6,
            newValue: 7
        )

        XCTAssertEqual(event, event) // Same instance
    }
}

// MARK: - Streak Milestone Tests

final class StreakMilestoneTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testStreakMilestone_RawValues() {
        XCTAssertEqual(StreakMilestone.week.rawValue, 7)
        XCTAssertEqual(StreakMilestone.twoWeeks.rawValue, 14)
        XCTAssertEqual(StreakMilestone.month.rawValue, 30)
        XCTAssertEqual(StreakMilestone.twoMonths.rawValue, 60)
        XCTAssertEqual(StreakMilestone.threeMonths.rawValue, 90)
        XCTAssertEqual(StreakMilestone.hundred.rawValue, 100)
    }

    // MARK: - Display Name Tests

    func testStreakMilestone_DisplayNames() {
        XCTAssertEqual(StreakMilestone.week.displayName, "1 Week")
        XCTAssertEqual(StreakMilestone.twoWeeks.displayName, "2 Weeks")
        XCTAssertEqual(StreakMilestone.month.displayName, "1 Month")
        XCTAssertEqual(StreakMilestone.twoMonths.displayName, "2 Months")
        XCTAssertEqual(StreakMilestone.threeMonths.displayName, "3 Months")
        XCTAssertEqual(StreakMilestone.hundred.displayName, "100 Days")
    }

    // MARK: - Celebration Message Tests

    func testStreakMilestone_CelebrationMessages() {
        XCTAssertEqual(StreakMilestone.week.celebrationMessage, "One week strong!")
        XCTAssertEqual(StreakMilestone.twoWeeks.celebrationMessage, "Two weeks of dedication!")
        XCTAssertEqual(StreakMilestone.month.celebrationMessage, "A full month! Incredible!")
        XCTAssertEqual(StreakMilestone.twoMonths.celebrationMessage, "Two months of consistency!")
        XCTAssertEqual(StreakMilestone.threeMonths.celebrationMessage, "Three months! You're unstoppable!")
        XCTAssertEqual(StreakMilestone.hundred.celebrationMessage, "100 DAYS! LEGENDARY!")
    }

    // MARK: - Confetti Count Tests

    func testStreakMilestone_ConfettiCounts() {
        // Higher milestones should have more confetti
        XCTAssertLessThan(StreakMilestone.week.confettiCount, StreakMilestone.twoWeeks.confettiCount)
        XCTAssertLessThan(StreakMilestone.twoWeeks.confettiCount, StreakMilestone.month.confettiCount)
        XCTAssertLessThan(StreakMilestone.month.confettiCount, StreakMilestone.twoMonths.confettiCount)
        XCTAssertLessThan(StreakMilestone.twoMonths.confettiCount, StreakMilestone.threeMonths.confettiCount)
        XCTAssertLessThan(StreakMilestone.threeMonths.confettiCount, StreakMilestone.hundred.confettiCount)
    }

    // MARK: - Milestone Detection Tests

    func testStreakMilestone_MilestoneForStreak() {
        XCTAssertEqual(StreakMilestone.milestone(for: 7), .week)
        XCTAssertEqual(StreakMilestone.milestone(for: 14), .twoWeeks)
        XCTAssertEqual(StreakMilestone.milestone(for: 30), .month)
        XCTAssertEqual(StreakMilestone.milestone(for: 60), .twoMonths)
        XCTAssertEqual(StreakMilestone.milestone(for: 90), .threeMonths)
        XCTAssertEqual(StreakMilestone.milestone(for: 100), .hundred)
    }

    func testStreakMilestone_NonMilestoneStreaks() {
        XCTAssertNil(StreakMilestone.milestone(for: 0))
        XCTAssertNil(StreakMilestone.milestone(for: 5))
        XCTAssertNil(StreakMilestone.milestone(for: 8))
        XCTAssertNil(StreakMilestone.milestone(for: 15))
        XCTAssertNil(StreakMilestone.milestone(for: 50))
        XCTAssertNil(StreakMilestone.milestone(for: 365))
    }

    // MARK: - Highest Achieved Tests

    func testStreakMilestone_HighestAchieved() {
        XCTAssertNil(StreakMilestone.highestAchieved(for: 0))
        XCTAssertNil(StreakMilestone.highestAchieved(for: 6))
        XCTAssertEqual(StreakMilestone.highestAchieved(for: 7), .week)
        XCTAssertEqual(StreakMilestone.highestAchieved(for: 13), .week)
        XCTAssertEqual(StreakMilestone.highestAchieved(for: 14), .twoWeeks)
        XCTAssertEqual(StreakMilestone.highestAchieved(for: 29), .twoWeeks)
        XCTAssertEqual(StreakMilestone.highestAchieved(for: 30), .month)
        XCTAssertEqual(StreakMilestone.highestAchieved(for: 59), .month)
        XCTAssertEqual(StreakMilestone.highestAchieved(for: 60), .twoMonths)
        XCTAssertEqual(StreakMilestone.highestAchieved(for: 89), .twoMonths)
        XCTAssertEqual(StreakMilestone.highestAchieved(for: 90), .threeMonths)
        XCTAssertEqual(StreakMilestone.highestAchieved(for: 99), .threeMonths)
        XCTAssertEqual(StreakMilestone.highestAchieved(for: 100), .hundred)
        XCTAssertEqual(StreakMilestone.highestAchieved(for: 365), .hundred)
    }
}

// MARK: - PR Celebration Type Tests

final class PRCelebrationTypeTests: XCTestCase {

    func testPRCelebrationType_Titles() {
        XCTAssertEqual(PRCelebrationType.firstPR.title, "First PR!")
        XCTAssertEqual(PRCelebrationType.newPR.title, "New PR!")
        XCTAssertEqual(PRCelebrationType.majorPR.title, "Major PR!")
        XCTAssertEqual(PRCelebrationType.milestonePR.title, "Milestone PR!")
    }

    func testPRCelebrationType_Subtitles() {
        XCTAssertEqual(PRCelebrationType.firstPR.subtitle, "You've set your first personal record!")
        XCTAssertEqual(PRCelebrationType.newPR.subtitle, "You've beaten your previous best!")
        XCTAssertEqual(PRCelebrationType.majorPR.subtitle, "Massive improvement!")
        XCTAssertEqual(PRCelebrationType.milestonePR.subtitle, "You've hit a major milestone!")
    }

    func testPRCelebrationType_Icons() {
        XCTAssertEqual(PRCelebrationType.firstPR.iconName, "trophy.fill")
        XCTAssertEqual(PRCelebrationType.newPR.iconName, "star.fill")
        XCTAssertEqual(PRCelebrationType.majorPR.iconName, "crown.fill")
        XCTAssertEqual(PRCelebrationType.milestonePR.iconName, "medal.fill")
    }

    func testPRCelebrationType_Colors() {
        XCTAssertEqual(PRCelebrationType.firstPR.color, .yellow)
        XCTAssertEqual(PRCelebrationType.newPR.color, .orange)
        XCTAssertEqual(PRCelebrationType.majorPR.color, .purple)
        XCTAssertEqual(PRCelebrationType.milestonePR.color, .cyan)
    }
}

// MARK: - Achievement Progress Preview Tests

#if DEBUG
final class AchievementProgressPreviewTests: XCTestCase {

    func testAchievementProgress_SampleLocked() {
        let sample = AchievementProgress.sampleLocked

        XCTAssertEqual(sample.definition.id, "streak_30_day")
        XCTAssertEqual(sample.currentValue, 12)
        XCTAssertFalse(sample.isUnlocked)
        XCTAssertNil(sample.unlockedAt)
    }

    func testAchievementProgress_SampleUnlocked() {
        let sample = AchievementProgress.sampleUnlocked

        XCTAssertEqual(sample.definition.id, "streak_7_day")
        XCTAssertEqual(sample.currentValue, 7)
        XCTAssertTrue(sample.isUnlocked)
        XCTAssertNotNil(sample.unlockedAt)
    }

    func testAchievementProgress_SampleArray() {
        let samples = AchievementProgress.sampleArray

        XCTAssertEqual(samples.count, 6)

        // Verify mix of locked and unlocked
        let unlockedCount = samples.filter { $0.isUnlocked }.count
        let lockedCount = samples.filter { !$0.isUnlocked }.count

        XCTAssertTrue(unlockedCount > 0, "Sample should contain unlocked achievements")
        XCTAssertTrue(lockedCount > 0, "Sample should contain locked achievements")
    }
}
#endif

// MARK: - Total Points Calculation Tests

final class AchievementPointsCalculationTests: XCTestCase {

    func testTotalPoints_SingleAchievement() {
        let bronzePoints = AchievementTier.bronze.points
        XCTAssertEqual(bronzePoints, 10)
    }

    func testTotalPoints_MultipleAchievements() {
        let unlockedIds = ["streak_7_day", "first_workout", "workouts_10"]
        var totalPoints = 0

        for id in unlockedIds {
            if let definition = AchievementCatalog.get(id) {
                totalPoints += definition.tier.points
            }
        }

        // streak_7_day = bronze (10) + first_workout = bronze (10) + workouts_10 = bronze (10)
        XCTAssertEqual(totalPoints, 30)
    }

    func testTotalPoints_AllTiers() {
        // One of each tier
        let achievements = [
            AchievementCatalog.streak7Day,      // Bronze: 10
            AchievementCatalog.streak14Day,    // Silver: 25
            AchievementCatalog.streak30Day,    // Gold: 50
            AchievementCatalog.streak60Day,    // Platinum: 100
            AchievementCatalog.streak100Day    // Diamond: 200
        ]

        let totalPoints = achievements.reduce(0) { $0 + $1.tier.points }

        XCTAssertEqual(totalPoints, 385)
    }
}
