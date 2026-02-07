//
//  StreakViewModelTests.swift
//  PTPerformanceTests
//
//  Comprehensive tests for streak display logic, milestone detection,
//  and animation triggers in the streak-related view models.
//

import XCTest
import SwiftUI
@testable import PTPerformance

// MARK: - Mock Streak Display ViewModel

/// A testable view model for streak display logic
/// This simulates the behavior that would be in a StreakViewModel
@MainActor
class MockStreakDisplayViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var streakType: StreakType = .combined
    @Published var lastActivityDate: Date?
    @Published var isLoading: Bool = false
    @Published var error: Error?

    // Animation triggers
    @Published var showStreakAnimation: Bool = false
    @Published var showMilestoneAnimation: Bool = false
    @Published var currentMilestone: StreakMilestone?
    @Published var showBadgeUpgrade: Bool = false
    @Published var previousBadge: StreakBadge?
    @Published var newBadge: StreakBadge?

    // MARK: - Computed Properties

    var isAtRisk: Bool {
        guard let lastDate = lastActivityDate else { return true }
        return !Calendar.current.isDateInToday(lastDate)
    }

    var badgeLevel: StreakBadge {
        StreakBadge.badge(for: longestStreak)
    }

    var motivationalMessage: String {
        switch currentStreak {
        case 0: return "Start your streak today!"
        case 1: return "Great start! Keep going!"
        case 2...6: return "Building momentum!"
        case 7...13: return "One week strong!"
        case 14...29: return "Two weeks! Amazing!"
        case 30...59: return "One month! Incredible!"
        case 60...89: return "Two months! Unstoppable!"
        default: return "Legendary consistency!"
        }
    }

    var daysUntilNextBadge: Int? {
        guard let nextBadge = badgeLevel.nextBadge else { return nil }
        return max(0, nextBadge.minDays - longestStreak)
    }

    var progressToNextBadge: Double {
        let currentBadgeMin = badgeLevel.minDays
        guard let nextBadge = badgeLevel.nextBadge else { return 1.0 }
        let nextBadgeMin = nextBadge.minDays

        let range = Double(nextBadgeMin - currentBadgeMin)
        let progress = Double(longestStreak - currentBadgeMin)

        return min(1.0, max(0.0, progress / range))
    }

    var streakDisplayText: String {
        switch currentStreak {
        case 0: return "0 days"
        case 1: return "1 day"
        default: return "\(currentStreak) days"
        }
    }

    // MARK: - Methods

    func updateStreak(current: Int, longest: Int) {
        let previousStreak = self.currentStreak
        let previousBadgeLevel = StreakBadge.badge(for: self.longestStreak)

        self.currentStreak = current
        self.longestStreak = longest

        // Check for streak animation
        if current > previousStreak && current > 0 {
            triggerStreakAnimation()
        }

        // Check for milestone
        if let milestone = StreakMilestone.milestone(for: current), current > previousStreak {
            triggerMilestoneAnimation(milestone)
        }

        // Check for badge upgrade
        let newBadgeLevel = StreakBadge.badge(for: longest)
        if newBadgeLevel != previousBadgeLevel && newBadgeLevel.rawValue > previousBadgeLevel.rawValue {
            triggerBadgeUpgrade(from: previousBadgeLevel, to: newBadgeLevel)
        }
    }

    func triggerStreakAnimation() {
        showStreakAnimation = true
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            showStreakAnimation = false
        }
    }

    func triggerMilestoneAnimation(_ milestone: StreakMilestone) {
        currentMilestone = milestone
        showMilestoneAnimation = true
    }

    func triggerBadgeUpgrade(from oldBadge: StreakBadge, to newBadge: StreakBadge) {
        previousBadge = oldBadge
        self.newBadge = newBadge
        showBadgeUpgrade = true
    }

    func dismissMilestone() {
        showMilestoneAnimation = false
        currentMilestone = nil
    }

    func dismissBadgeUpgrade() {
        showBadgeUpgrade = false
        previousBadge = nil
        newBadge = nil
    }
}

// MARK: - Streak ViewModel Tests

@MainActor
final class StreakViewModelTests: XCTestCase {

    var viewModel: MockStreakDisplayViewModel!

    override func setUp() async throws {
        try await super.setUp()
        viewModel = MockStreakDisplayViewModel()
    }

    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertEqual(viewModel.currentStreak, 0)
        XCTAssertEqual(viewModel.longestStreak, 0)
        XCTAssertEqual(viewModel.streakType, .combined)
        XCTAssertNil(viewModel.lastActivityDate)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.showStreakAnimation)
        XCTAssertFalse(viewModel.showMilestoneAnimation)
        XCTAssertNil(viewModel.currentMilestone)
    }

    // MARK: - Streak Display Logic Tests

    func testStreakDisplayText_ZeroDays() {
        viewModel.currentStreak = 0
        XCTAssertEqual(viewModel.streakDisplayText, "0 days")
    }

    func testStreakDisplayText_OneDay() {
        viewModel.currentStreak = 1
        XCTAssertEqual(viewModel.streakDisplayText, "1 day")
    }

    func testStreakDisplayText_MultipleDays() {
        viewModel.currentStreak = 7
        XCTAssertEqual(viewModel.streakDisplayText, "7 days")

        viewModel.currentStreak = 100
        XCTAssertEqual(viewModel.streakDisplayText, "100 days")
    }

    func testMotivationalMessage_AllRanges() {
        let testCases: [(streak: Int, expectedMessage: String)] = [
            (0, "Start your streak today!"),
            (1, "Great start! Keep going!"),
            (3, "Building momentum!"),
            (6, "Building momentum!"),
            (7, "One week strong!"),
            (13, "One week strong!"),
            (14, "Two weeks! Amazing!"),
            (29, "Two weeks! Amazing!"),
            (30, "One month! Incredible!"),
            (59, "One month! Incredible!"),
            (60, "Two months! Unstoppable!"),
            (89, "Two months! Unstoppable!"),
            (90, "Legendary consistency!"),
            (365, "Legendary consistency!")
        ]

        for (streak, expectedMessage) in testCases {
            viewModel.currentStreak = streak
            XCTAssertEqual(
                viewModel.motivationalMessage,
                expectedMessage,
                "Streak \(streak) should show: \(expectedMessage)"
            )
        }
    }

    // MARK: - Badge Level Tests

    func testBadgeLevel_BasedOnLongestStreak() {
        viewModel.longestStreak = 5
        XCTAssertEqual(viewModel.badgeLevel, .starter)

        viewModel.longestStreak = 10
        XCTAssertEqual(viewModel.badgeLevel, .committed)

        viewModel.longestStreak = 20
        XCTAssertEqual(viewModel.badgeLevel, .dedicated)

        viewModel.longestStreak = 45
        XCTAssertEqual(viewModel.badgeLevel, .champion)

        viewModel.longestStreak = 75
        XCTAssertEqual(viewModel.badgeLevel, .elite)

        viewModel.longestStreak = 100
        XCTAssertEqual(viewModel.badgeLevel, .legend)
    }

    func testDaysUntilNextBadge() {
        viewModel.longestStreak = 5 // Starter, need 7 for Committed
        XCTAssertEqual(viewModel.daysUntilNextBadge, 2)

        viewModel.longestStreak = 10 // Committed, need 14 for Dedicated
        XCTAssertEqual(viewModel.daysUntilNextBadge, 4)

        viewModel.longestStreak = 100 // Legend, no next badge
        XCTAssertNil(viewModel.daysUntilNextBadge)
    }

    func testProgressToNextBadge() {
        // Starter (0-6) to Committed (7-13)
        viewModel.longestStreak = 0
        XCTAssertEqual(viewModel.progressToNextBadge, 0.0, accuracy: 0.01)

        viewModel.longestStreak = 3
        XCTAssertEqual(viewModel.progressToNextBadge, 3.0 / 7.0, accuracy: 0.01)

        viewModel.longestStreak = 6
        XCTAssertEqual(viewModel.progressToNextBadge, 6.0 / 7.0, accuracy: 0.01)

        // Legend has no next badge, progress should be 1.0
        viewModel.longestStreak = 100
        XCTAssertEqual(viewModel.progressToNextBadge, 1.0, accuracy: 0.01)
    }

    // MARK: - Is At Risk Tests

    func testIsAtRisk_NoActivityDate() {
        viewModel.lastActivityDate = nil
        XCTAssertTrue(viewModel.isAtRisk)
    }

    func testIsAtRisk_ActivityToday() {
        viewModel.lastActivityDate = Date()
        XCTAssertFalse(viewModel.isAtRisk)
    }

    func testIsAtRisk_ActivityYesterday() {
        viewModel.lastActivityDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        XCTAssertTrue(viewModel.isAtRisk)
    }

    // MARK: - Milestone Detection Tests

    func testMilestoneDetection_7Days() {
        let milestone = StreakMilestone.milestone(for: 7)
        XCTAssertEqual(milestone, .week)
    }

    func testMilestoneDetection_14Days() {
        let milestone = StreakMilestone.milestone(for: 14)
        XCTAssertEqual(milestone, .twoWeeks)
    }

    func testMilestoneDetection_30Days() {
        let milestone = StreakMilestone.milestone(for: 30)
        XCTAssertEqual(milestone, .month)
    }

    func testMilestoneDetection_60Days() {
        let milestone = StreakMilestone.milestone(for: 60)
        XCTAssertEqual(milestone, .twoMonths)
    }

    func testMilestoneDetection_90Days() {
        let milestone = StreakMilestone.milestone(for: 90)
        XCTAssertEqual(milestone, .threeMonths)
    }

    func testMilestoneDetection_100Days() {
        let milestone = StreakMilestone.milestone(for: 100)
        XCTAssertEqual(milestone, .hundred)
    }

    func testMilestoneDetection_NonMilestoneDay() {
        let milestone = StreakMilestone.milestone(for: 5)
        XCTAssertNil(milestone)

        let milestone15 = StreakMilestone.milestone(for: 15)
        XCTAssertNil(milestone15)
    }

    func testHighestAchievedMilestone() {
        XCTAssertNil(StreakMilestone.highestAchieved(for: 5))
        XCTAssertEqual(StreakMilestone.highestAchieved(for: 7), .week)
        XCTAssertEqual(StreakMilestone.highestAchieved(for: 10), .week)
        XCTAssertEqual(StreakMilestone.highestAchieved(for: 14), .twoWeeks)
        XCTAssertEqual(StreakMilestone.highestAchieved(for: 50), .month)
        XCTAssertEqual(StreakMilestone.highestAchieved(for: 100), .hundred)
        XCTAssertEqual(StreakMilestone.highestAchieved(for: 365), .hundred)
    }

    // MARK: - Animation Trigger Tests

    func testStreakIncrementTriggersAnimation() {
        viewModel.currentStreak = 5
        viewModel.updateStreak(current: 6, longest: 6)

        XCTAssertTrue(viewModel.showStreakAnimation)
    }

    func testStreakResetDoesNotTriggerAnimation() {
        viewModel.currentStreak = 10
        viewModel.longestStreak = 10
        viewModel.updateStreak(current: 0, longest: 10)

        XCTAssertFalse(viewModel.showStreakAnimation)
    }

    func testMilestoneTriggersAnimation() {
        viewModel.currentStreak = 6
        viewModel.longestStreak = 6
        viewModel.updateStreak(current: 7, longest: 7)

        XCTAssertTrue(viewModel.showMilestoneAnimation)
        XCTAssertEqual(viewModel.currentMilestone, .week)
    }

    func testBadgeUpgradeTriggers() {
        viewModel.currentStreak = 6
        viewModel.longestStreak = 6
        viewModel.updateStreak(current: 7, longest: 7)

        XCTAssertTrue(viewModel.showBadgeUpgrade)
        XCTAssertEqual(viewModel.previousBadge, .starter)
        XCTAssertEqual(viewModel.newBadge, .committed)
    }

    func testNoBadgeUpgradeWithinSameTier() {
        viewModel.currentStreak = 7
        viewModel.longestStreak = 7
        viewModel.updateStreak(current: 8, longest: 8)

        XCTAssertFalse(viewModel.showBadgeUpgrade)
    }

    // MARK: - Dismiss Animation Tests

    func testDismissMilestone() {
        viewModel.showMilestoneAnimation = true
        viewModel.currentMilestone = .week

        viewModel.dismissMilestone()

        XCTAssertFalse(viewModel.showMilestoneAnimation)
        XCTAssertNil(viewModel.currentMilestone)
    }

    func testDismissBadgeUpgrade() {
        viewModel.showBadgeUpgrade = true
        viewModel.previousBadge = .starter
        viewModel.newBadge = .committed

        viewModel.dismissBadgeUpgrade()

        XCTAssertFalse(viewModel.showBadgeUpgrade)
        XCTAssertNil(viewModel.previousBadge)
        XCTAssertNil(viewModel.newBadge)
    }

    // MARK: - Milestone Properties Tests

    func testMilestoneDisplayNames() {
        XCTAssertEqual(StreakMilestone.week.displayName, "1 Week")
        XCTAssertEqual(StreakMilestone.twoWeeks.displayName, "2 Weeks")
        XCTAssertEqual(StreakMilestone.month.displayName, "1 Month")
        XCTAssertEqual(StreakMilestone.twoMonths.displayName, "2 Months")
        XCTAssertEqual(StreakMilestone.threeMonths.displayName, "3 Months")
        XCTAssertEqual(StreakMilestone.hundred.displayName, "100 Days")
    }

    func testMilestoneCelebrationMessages() {
        XCTAssertEqual(StreakMilestone.week.celebrationMessage, "One week strong!")
        XCTAssertEqual(StreakMilestone.twoWeeks.celebrationMessage, "Two weeks of dedication!")
        XCTAssertEqual(StreakMilestone.month.celebrationMessage, "A full month! Incredible!")
        XCTAssertEqual(StreakMilestone.twoMonths.celebrationMessage, "Two months of consistency!")
        XCTAssertEqual(StreakMilestone.threeMonths.celebrationMessage, "Three months! You're unstoppable!")
        XCTAssertEqual(StreakMilestone.hundred.celebrationMessage, "100 DAYS! LEGENDARY!")
    }

    func testMilestoneConfettiCounts() {
        XCTAssertEqual(StreakMilestone.week.confettiCount, 20)
        XCTAssertEqual(StreakMilestone.twoWeeks.confettiCount, 35)
        XCTAssertEqual(StreakMilestone.month.confettiCount, 50)
        XCTAssertEqual(StreakMilestone.twoMonths.confettiCount, 75)
        XCTAssertEqual(StreakMilestone.threeMonths.confettiCount, 100)
        XCTAssertEqual(StreakMilestone.hundred.confettiCount, 150)
    }

    // MARK: - Edge Cases Tests

    func testUpdateStreakFromZero() {
        viewModel.currentStreak = 0
        viewModel.longestStreak = 0
        viewModel.updateStreak(current: 1, longest: 1)

        XCTAssertEqual(viewModel.currentStreak, 1)
        XCTAssertEqual(viewModel.longestStreak, 1)
        XCTAssertTrue(viewModel.showStreakAnimation)
    }

    func testUpdateStreakWithBrokenStreak() {
        viewModel.currentStreak = 50
        viewModel.longestStreak = 50
        viewModel.updateStreak(current: 0, longest: 50)

        XCTAssertEqual(viewModel.currentStreak, 0)
        XCTAssertEqual(viewModel.longestStreak, 50)
        XCTAssertFalse(viewModel.showStreakAnimation)
        XCTAssertFalse(viewModel.showMilestoneAnimation)
    }

    func testVeryLongStreakDisplay() {
        viewModel.currentStreak = 365
        viewModel.longestStreak = 365

        XCTAssertEqual(viewModel.streakDisplayText, "365 days")
        XCTAssertEqual(viewModel.motivationalMessage, "Legendary consistency!")
        XCTAssertEqual(viewModel.badgeLevel, .legend)
        XCTAssertNil(viewModel.daysUntilNextBadge)
    }

    func testCurrentExceedsLongest() {
        viewModel.currentStreak = 20
        viewModel.longestStreak = 15 // Longest should update when current exceeds
        viewModel.updateStreak(current: 21, longest: 21)

        XCTAssertEqual(viewModel.currentStreak, 21)
        XCTAssertEqual(viewModel.longestStreak, 21)
    }

    func testMultipleMilestonesInSequence() {
        // Day 6 -> Day 7 (Week milestone)
        viewModel.currentStreak = 6
        viewModel.longestStreak = 6
        viewModel.updateStreak(current: 7, longest: 7)
        XCTAssertEqual(viewModel.currentMilestone, .week)

        viewModel.dismissMilestone()

        // Day 13 -> Day 14 (Two weeks milestone)
        viewModel.currentStreak = 13
        viewModel.longestStreak = 13
        viewModel.updateStreak(current: 14, longest: 14)
        XCTAssertEqual(viewModel.currentMilestone, .twoWeeks)
    }
}

// MARK: - Streak Badge Display Tests

@MainActor
final class StreakBadgeDisplayTests: XCTestCase {

    func testBadgeDisplayNames() {
        XCTAssertEqual(StreakBadge.starter.displayName, "Starter")
        XCTAssertEqual(StreakBadge.committed.displayName, "Committed")
        XCTAssertEqual(StreakBadge.dedicated.displayName, "Dedicated")
        XCTAssertEqual(StreakBadge.champion.displayName, "Champion")
        XCTAssertEqual(StreakBadge.elite.displayName, "Elite")
        XCTAssertEqual(StreakBadge.legend.displayName, "Legend")
    }

    func testBadgeDescriptions() {
        XCTAssertEqual(StreakBadge.starter.description, "Just getting started")
        XCTAssertEqual(StreakBadge.committed.description, "One week strong!")
        XCTAssertEqual(StreakBadge.dedicated.description, "Two weeks of dedication")
        XCTAssertEqual(StreakBadge.champion.description, "A full month!")
        XCTAssertEqual(StreakBadge.elite.description, "Two months of consistency")
        XCTAssertEqual(StreakBadge.legend.description, "Three months of excellence")
    }

    func testBadgeIcons() {
        XCTAssertEqual(StreakBadge.starter.iconName, "flame")
        XCTAssertEqual(StreakBadge.committed.iconName, "flame.fill")
        XCTAssertEqual(StreakBadge.dedicated.iconName, "star.fill")
        XCTAssertEqual(StreakBadge.champion.iconName, "crown.fill")
        XCTAssertEqual(StreakBadge.elite.iconName, "trophy.fill")
        XCTAssertEqual(StreakBadge.legend.iconName, "medal.fill")
    }

    func testBadgeColors() {
        XCTAssertEqual(StreakBadge.starter.color, .gray)
        XCTAssertEqual(StreakBadge.committed.color, .blue)
        XCTAssertEqual(StreakBadge.dedicated.color, .green)
        XCTAssertEqual(StreakBadge.champion.color, .orange)
        XCTAssertEqual(StreakBadge.elite.color, .purple)
        XCTAssertEqual(StreakBadge.legend.color, .yellow)
    }

    func testAllBadgeCases() {
        let allCases = StreakBadge.allCases
        XCTAssertEqual(allCases.count, 6)

        // Verify order
        XCTAssertEqual(allCases[0], .starter)
        XCTAssertEqual(allCases[1], .committed)
        XCTAssertEqual(allCases[2], .dedicated)
        XCTAssertEqual(allCases[3], .champion)
        XCTAssertEqual(allCases[4], .elite)
        XCTAssertEqual(allCases[5], .legend)
    }
}

// MARK: - Widget Streak Tests

@MainActor
final class WidgetStreakTests: XCTestCase {

    func testWidgetStreakInitialization() {
        let widgetStreak = WidgetStreak(
            currentStreak: 15,
            longestStreak: 20,
            streakType: .combined,
            lastActivityDate: Date(),
            lastUpdated: Date()
        )

        XCTAssertEqual(widgetStreak.currentStreak, 15)
        XCTAssertEqual(widgetStreak.longestStreak, 20)
        XCTAssertEqual(widgetStreak.streakType, .combined)
        XCTAssertNotNil(widgetStreak.lastActivityDate)
    }

    func testWidgetStreakMotivationalMessage() {
        let zeroStreak = WidgetStreak(currentStreak: 0, longestStreak: 0)
        XCTAssertEqual(zeroStreak.motivationalMessage, "Start your streak today!")

        let weekStreak = WidgetStreak(currentStreak: 7, longestStreak: 7)
        XCTAssertEqual(weekStreak.motivationalMessage, "One week strong!")

        let legendStreak = WidgetStreak(currentStreak: 100, longestStreak: 100)
        XCTAssertEqual(legendStreak.motivationalMessage, "Legendary consistency!")
    }

    func testWidgetStreakIsAtRisk() {
        let atRiskStreak = WidgetStreak(
            currentStreak: 10,
            longestStreak: 10,
            lastActivityDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())
        )
        XCTAssertTrue(atRiskStreak.isAtRisk)

        let safeStreak = WidgetStreak(
            currentStreak: 10,
            longestStreak: 10,
            lastActivityDate: Date()
        )
        XCTAssertFalse(safeStreak.isAtRisk)
    }

    func testWidgetStreakPlaceholder() {
        let placeholder = WidgetStreak.placeholder

        XCTAssertEqual(placeholder.currentStreak, 12)
        XCTAssertEqual(placeholder.longestStreak, 21)
        XCTAssertNotNil(placeholder.lastActivityDate)
    }

    func testWidgetStreakTypeDisplayNames() {
        XCTAssertEqual(WidgetStreak.StreakType.workout.displayName, "Workout")
        XCTAssertEqual(WidgetStreak.StreakType.armCare.displayName, "Arm Care")
        XCTAssertEqual(WidgetStreak.StreakType.combined.displayName, "Training")
    }

    func testWidgetStreakTypeIcons() {
        XCTAssertEqual(WidgetStreak.StreakType.workout.iconName, "figure.strengthtraining.traditional")
        XCTAssertEqual(WidgetStreak.StreakType.armCare.iconName, "arm.flexed.fill")
        XCTAssertEqual(WidgetStreak.StreakType.combined.iconName, "flame.fill")
    }
}
