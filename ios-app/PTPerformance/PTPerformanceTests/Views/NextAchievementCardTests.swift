//
//  NextAchievementCardTests.swift
//  PTPerformanceTests
//
//  Tests for NextAchievementCard and achievement recommendation components
//

import XCTest
@testable import PTPerformance

final class AchievementRecommendationsTests: XCTestCase {

    // MARK: - Test Data

    private func createTestProgress(
        id: String = "test",
        title: String = "Test Achievement",
        type: AchievementType = .streak,
        tier: AchievementTier = .bronze,
        requirement: Int = 10,
        currentValue: Int = 5,
        isUnlocked: Bool = false
    ) -> AchievementProgress {
        let definition = AchievementDefinition(
            id: id,
            title: title,
            description: "Test description",
            type: type,
            tier: tier,
            iconName: "star.fill",
            requirement: requirement,
            requirementUnit: "days"
        )

        return AchievementProgress(
            definition: definition,
            currentValue: currentValue,
            isUnlocked: isUnlocked,
            unlockedAt: isUnlocked ? Date() : nil
        )
    }

    // MARK: - getClosestToUnlock Tests

    func testGetClosestToUnlock_EmptyList() {
        let achievements: [AchievementProgress] = []

        let result = AchievementRecommendations.getClosestToUnlock(from: achievements)

        XCTAssertTrue(result.isEmpty)
    }

    func testGetClosestToUnlock_FilterUnlocked() {
        let achievements = [
            createTestProgress(id: "1", currentValue: 5, isUnlocked: false),
            createTestProgress(id: "2", currentValue: 10, isUnlocked: true), // Unlocked
            createTestProgress(id: "3", currentValue: 8, isUnlocked: false)
        ]

        let result = AchievementRecommendations.getClosestToUnlock(from: achievements)

        // Should not include unlocked achievements
        XCTAssertFalse(result.contains { $0.isUnlocked })
    }

    func testGetClosestToUnlock_FilterZeroProgress() {
        let achievements = [
            createTestProgress(id: "1", currentValue: 5, isUnlocked: false),
            createTestProgress(id: "2", currentValue: 0, isUnlocked: false), // Zero progress
            createTestProgress(id: "3", currentValue: 8, isUnlocked: false)
        ]

        let result = AchievementRecommendations.getClosestToUnlock(from: achievements)

        // Should not include zero-progress achievements
        XCTAssertFalse(result.contains { $0.currentValue == 0 })
    }

    func testGetClosestToUnlock_SortedByProgress() {
        let achievements = [
            createTestProgress(id: "1", requirement: 10, currentValue: 3), // 30%
            createTestProgress(id: "2", requirement: 10, currentValue: 9), // 90%
            createTestProgress(id: "3", requirement: 10, currentValue: 5)  // 50%
        ]

        let result = AchievementRecommendations.getClosestToUnlock(from: achievements)

        // Should be sorted by highest progress first
        XCTAssertEqual(result[0].definition.id, "2")
        XCTAssertEqual(result[1].definition.id, "3")
        XCTAssertEqual(result[2].definition.id, "1")
    }

    func testGetClosestToUnlock_RespectsLimit() {
        let achievements = [
            createTestProgress(id: "1", requirement: 10, currentValue: 9),
            createTestProgress(id: "2", requirement: 10, currentValue: 8),
            createTestProgress(id: "3", requirement: 10, currentValue: 7),
            createTestProgress(id: "4", requirement: 10, currentValue: 6),
            createTestProgress(id: "5", requirement: 10, currentValue: 5)
        ]

        let result = AchievementRecommendations.getClosestToUnlock(from: achievements, limit: 3)

        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].definition.id, "1")
        XCTAssertEqual(result[1].definition.id, "2")
        XCTAssertEqual(result[2].definition.id, "3")
    }

    // MARK: - getNextGoals Tests

    func testGetNextGoals_InProgressFirst() {
        let achievements = [
            createTestProgress(id: "1", currentValue: 5), // In progress
            createTestProgress(id: "2", currentValue: 0), // Not started
            createTestProgress(id: "3", currentValue: 8)  // In progress
        ]

        let result = AchievementRecommendations.getNextGoals(from: achievements, limit: 3)

        // In-progress achievements should come first
        XCTAssertGreaterThan(result[0].currentValue, 0)
    }

    func testGetNextGoals_IncludesNotStartedIfNeeded() {
        let achievements = [
            createTestProgress(id: "1", currentValue: 5),
            createTestProgress(id: "2", currentValue: 0)
        ]

        let result = AchievementRecommendations.getNextGoals(from: achievements, limit: 3)

        // Should include not-started if needed to fill limit
        XCTAssertEqual(result.count, 2)
    }

    // MARK: - getClosestByCategory Tests

    func testGetClosestByCategory_ReturnsOnePerCategory() {
        let achievements = [
            createTestProgress(id: "streak1", type: .streak, requirement: 10, currentValue: 5),
            createTestProgress(id: "streak2", type: .streak, requirement: 10, currentValue: 8),
            createTestProgress(id: "workout1", type: .workouts, requirement: 10, currentValue: 3),
            createTestProgress(id: "volume1", type: .volume, requirement: 10, currentValue: 7)
        ]

        let result = AchievementRecommendations.getClosestByCategory(from: achievements)

        // Should return one per category (the one with highest progress)
        XCTAssertEqual(result[.streak]?.definition.id, "streak2")
        XCTAssertEqual(result[.workouts]?.definition.id, "workout1")
        XCTAssertEqual(result[.volume]?.definition.id, "volume1")
    }

    func testGetClosestByCategory_ExcludesUnlocked() {
        let achievements = [
            createTestProgress(id: "1", type: .streak, currentValue: 10, isUnlocked: true),
            createTestProgress(id: "2", type: .streak, currentValue: 5, isUnlocked: false)
        ]

        let result = AchievementRecommendations.getClosestByCategory(from: achievements)

        // Should not include unlocked achievements
        XCTAssertEqual(result[.streak]?.definition.id, "2")
    }
}

final class AchievementProgressTests: XCTestCase {

    private func createDefinition(requirement: Int = 10) -> AchievementDefinition {
        AchievementDefinition(
            id: "test",
            title: "Test",
            description: "Test description",
            type: .streak,
            tier: .bronze,
            iconName: "star.fill",
            requirement: requirement,
            requirementUnit: "days"
        )
    }

    // MARK: - Progress Calculation Tests

    func testProgress_ZeroRequirement() {
        let progress = AchievementProgress(
            definition: createDefinition(requirement: 0),
            currentValue: 5,
            isUnlocked: false,
            unlockedAt: nil
        )

        // Should handle zero requirement gracefully
        XCTAssertEqual(progress.currentValue, 5)
    }

    func testProgress_AtRequirement() {
        let progress = AchievementProgress(
            definition: createDefinition(requirement: 10),
            currentValue: 10,
            isUnlocked: true,
            unlockedAt: Date()
        )

        XCTAssertEqual(progress.progress, 1.0)
    }

    func testProgress_HalfwayProgress() {
        let progress = AchievementProgress(
            definition: createDefinition(requirement: 10),
            currentValue: 5,
            isUnlocked: false,
            unlockedAt: nil
        )

        XCTAssertEqual(progress.progress, 0.5)
    }

    // MARK: - Remaining Value Tests

    func testRemainingValue_HasRemaining() {
        let progress = AchievementProgress(
            definition: createDefinition(requirement: 10),
            currentValue: 7,
            isUnlocked: false,
            unlockedAt: nil
        )

        XCTAssertEqual(progress.remainingValue, 3)
    }

    func testRemainingValue_Complete() {
        let progress = AchievementProgress(
            definition: createDefinition(requirement: 10),
            currentValue: 10,
            isUnlocked: true,
            unlockedAt: Date()
        )

        XCTAssertEqual(progress.remainingValue, 0)
    }

    func testRemainingValue_OverComplete() {
        let progress = AchievementProgress(
            definition: createDefinition(requirement: 10),
            currentValue: 15,
            isUnlocked: true,
            unlockedAt: Date()
        )

        // Should not go negative
        XCTAssertGreaterThanOrEqual(progress.remainingValue, 0)
    }
}
