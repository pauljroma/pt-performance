//
//  HealthCoachViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for HealthCoachViewModel
//  Tests initial state, computed properties, chat state, and score calculations
//

import XCTest
import SwiftUI
@testable import PTPerformance

@MainActor
final class HealthCoachViewModelTests: XCTestCase {

    var sut: HealthCoachViewModel!

    override func setUp() {
        super.setUp()
        sut = HealthCoachViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_HealthScoreIsNil() {
        XCTAssertNil(sut.healthScore, "healthScore should be nil initially")
    }

    func testInitialState_ScoreHistoryIsEmpty() {
        XCTAssertTrue(sut.scoreHistory.isEmpty, "scoreHistory should be empty initially")
    }

    func testInitialState_InsightsIsEmpty() {
        XCTAssertTrue(sut.insights.isEmpty, "insights should be empty initially")
    }

    func testInitialState_MessagesHasWelcomeMessage() {
        XCTAssertEqual(sut.messages.count, 1, "messages should have exactly 1 welcome message")
        XCTAssertEqual(sut.messages.first?.role, .assistant, "Welcome message should be from assistant")
        XCTAssertTrue(sut.messages.first?.content.contains("Health Coach") == true, "Welcome message should mention Health Coach")
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading, "isLoading should be false initially")
    }

    func testInitialState_ErrorIsNil() {
        XCTAssertNil(sut.error, "error should be nil initially")
    }

    // MARK: - Chat State Initial Values

    func testInitialState_InputMessageIsEmpty() {
        XCTAssertEqual(sut.inputMessage, "", "inputMessage should be empty initially")
    }

    func testInitialState_IsTypingIsFalse() {
        XCTAssertFalse(sut.isTyping, "isTyping should be false initially")
    }

    // MARK: - Computed Properties Tests - overallScore

    func testOverallScore_WhenHealthScoreIsNil_ReturnsZero() {
        sut.healthScore = nil
        XCTAssertEqual(sut.overallScore, 0, "overallScore should be 0 when healthScore is nil")
    }

    func testOverallScore_WhenHealthScoreExists_ReturnsCorrectValue() {
        sut.healthScore = createMockHealthScore(overallScore: 85)
        XCTAssertEqual(sut.overallScore, 85, "overallScore should match healthScore's overallScore")
    }

    // MARK: - Computed Properties Tests - scoreColor

    func testScoreColor_WhenExcellent_ReturnsGreen() {
        sut.healthScore = createMockHealthScore(overallScore: 85)
        XCTAssertEqual(sut.scoreColor, .green, "scoreColor should be green for scores 80-100")

        sut.healthScore = createMockHealthScore(overallScore: 100)
        XCTAssertEqual(sut.scoreColor, .green, "scoreColor should be green for score 100")

        sut.healthScore = createMockHealthScore(overallScore: 80)
        XCTAssertEqual(sut.scoreColor, .green, "scoreColor should be green for score 80")
    }

    func testScoreColor_WhenGood_ReturnsYellow() {
        sut.healthScore = createMockHealthScore(overallScore: 70)
        XCTAssertEqual(sut.scoreColor, .yellow, "scoreColor should be yellow for scores 60-79")

        sut.healthScore = createMockHealthScore(overallScore: 79)
        XCTAssertEqual(sut.scoreColor, .yellow, "scoreColor should be yellow for score 79")

        sut.healthScore = createMockHealthScore(overallScore: 60)
        XCTAssertEqual(sut.scoreColor, .yellow, "scoreColor should be yellow for score 60")
    }

    func testScoreColor_WhenFair_ReturnsOrange() {
        sut.healthScore = createMockHealthScore(overallScore: 50)
        XCTAssertEqual(sut.scoreColor, .orange, "scoreColor should be orange for scores 40-59")

        sut.healthScore = createMockHealthScore(overallScore: 59)
        XCTAssertEqual(sut.scoreColor, .orange, "scoreColor should be orange for score 59")

        sut.healthScore = createMockHealthScore(overallScore: 40)
        XCTAssertEqual(sut.scoreColor, .orange, "scoreColor should be orange for score 40")
    }

    func testScoreColor_WhenNeedsAttention_ReturnsRed() {
        sut.healthScore = createMockHealthScore(overallScore: 30)
        XCTAssertEqual(sut.scoreColor, .red, "scoreColor should be red for scores below 40")

        sut.healthScore = createMockHealthScore(overallScore: 0)
        XCTAssertEqual(sut.scoreColor, .red, "scoreColor should be red for score 0")

        sut.healthScore = createMockHealthScore(overallScore: 39)
        XCTAssertEqual(sut.scoreColor, .red, "scoreColor should be red for score 39")
    }

    func testScoreColor_WhenNoScore_ReturnsRed() {
        sut.healthScore = nil
        XCTAssertEqual(sut.scoreColor, .red, "scoreColor should be red when no score (0)")
    }

    // MARK: - Computed Properties Tests - scoreDescription

    func testScoreDescription_WhenExcellent_ReturnsExcellent() {
        sut.healthScore = createMockHealthScore(overallScore: 85)
        XCTAssertEqual(sut.scoreDescription, "Excellent", "scoreDescription should be 'Excellent' for scores 80-100")
    }

    func testScoreDescription_WhenGood_ReturnsGood() {
        sut.healthScore = createMockHealthScore(overallScore: 70)
        XCTAssertEqual(sut.scoreDescription, "Good", "scoreDescription should be 'Good' for scores 60-79")
    }

    func testScoreDescription_WhenFair_ReturnsFair() {
        sut.healthScore = createMockHealthScore(overallScore: 50)
        XCTAssertEqual(sut.scoreDescription, "Fair", "scoreDescription should be 'Fair' for scores 40-59")
    }

    func testScoreDescription_WhenNeedsAttention_ReturnsNeedsAttention() {
        sut.healthScore = createMockHealthScore(overallScore: 30)
        XCTAssertEqual(sut.scoreDescription, "Needs Attention", "scoreDescription should be 'Needs Attention' for scores below 40")
    }

    func testScoreDescription_WhenNoScore_ReturnsNeedsAttention() {
        sut.healthScore = nil
        XCTAssertEqual(sut.scoreDescription, "Needs Attention", "scoreDescription should be 'Needs Attention' when no score")
    }

    // MARK: - Computed Properties Tests - highPriorityInsights

    func testHighPriorityInsights_WhenEmpty_ReturnsEmpty() {
        sut.insights = []
        XCTAssertTrue(sut.highPriorityInsights.isEmpty, "highPriorityInsights should be empty when insights is empty")
    }

    func testHighPriorityInsights_FiltersHighPriority() {
        let highInsight = createMockInsight(priority: .high, title: "High Priority")
        let mediumInsight = createMockInsight(priority: .medium, title: "Medium Priority")
        let lowInsight = createMockInsight(priority: .low, title: "Low Priority")

        sut.insights = [highInsight, mediumInsight, lowInsight]

        XCTAssertEqual(sut.highPriorityInsights.count, 1, "highPriorityInsights should only include high priority")
        XCTAssertEqual(sut.highPriorityInsights.first?.title, "High Priority")
    }

    func testHighPriorityInsights_MultipleHighPriority() {
        let high1 = createMockInsight(priority: .high, title: "High 1")
        let high2 = createMockInsight(priority: .high, title: "High 2")
        let medium = createMockInsight(priority: .medium, title: "Medium")

        sut.insights = [high1, high2, medium]

        XCTAssertEqual(sut.highPriorityInsights.count, 2, "highPriorityInsights should include all high priority insights")
    }

    // MARK: - Computed Properties Tests - scoreTrend

    func testScoreTrend_WhenInsufficientHistory_ReturnsStable() {
        sut.scoreHistory = []
        XCTAssertEqual(sut.scoreTrend, .stable, "scoreTrend should be stable when no history")

        sut.scoreHistory = [createMockHealthScore(overallScore: 75)]
        XCTAssertEqual(sut.scoreTrend, .stable, "scoreTrend should be stable with only 1 history entry")
    }

    func testScoreTrend_WhenImproving_ReturnsImproving() {
        // Current score significantly higher than average
        sut.healthScore = createMockHealthScore(overallScore: 80)
        sut.scoreHistory = [
            createMockHealthScore(overallScore: 70),
            createMockHealthScore(overallScore: 68),
            createMockHealthScore(overallScore: 65),
            createMockHealthScore(overallScore: 63)
        ]

        XCTAssertEqual(sut.scoreTrend, .improving, "scoreTrend should be improving when current is > avg + 5")
    }

    func testScoreTrend_WhenDeclining_ReturnsDeclining() {
        // Current score significantly lower than average
        sut.healthScore = createMockHealthScore(overallScore: 60)
        sut.scoreHistory = [
            createMockHealthScore(overallScore: 70),
            createMockHealthScore(overallScore: 72),
            createMockHealthScore(overallScore: 75),
            createMockHealthScore(overallScore: 73)
        ]

        XCTAssertEqual(sut.scoreTrend, .declining, "scoreTrend should be declining when current is < avg - 5")
    }

    func testScoreTrend_WhenStable_ReturnsStable() {
        // Current score close to average
        sut.healthScore = createMockHealthScore(overallScore: 72)
        sut.scoreHistory = [
            createMockHealthScore(overallScore: 70),
            createMockHealthScore(overallScore: 71),
            createMockHealthScore(overallScore: 73),
            createMockHealthScore(overallScore: 72)
        ]

        XCTAssertEqual(sut.scoreTrend, .stable, "scoreTrend should be stable when current is within +/- 5 of avg")
    }

    // MARK: - Chat State Tests

    func testInputMessage_CanBeSet() {
        sut.inputMessage = "How can I improve my sleep?"
        XCTAssertEqual(sut.inputMessage, "How can I improve my sleep?", "inputMessage should be settable")
    }

    func testIsTyping_CanBeSet() {
        sut.isTyping = true
        XCTAssertTrue(sut.isTyping, "isTyping should be settable to true")

        sut.isTyping = false
        XCTAssertFalse(sut.isTyping, "isTyping should be settable to false")
    }

    func testMessages_CanBeAppended() {
        let initialCount = sut.messages.count
        let newMessage = HealthCoachMessage(
            id: UUID(),
            role: .user,
            content: "Test message",
            timestamp: Date(),
            category: nil
        )

        sut.messages.append(newMessage)

        XCTAssertEqual(sut.messages.count, initialCount + 1, "messages should be appendable")
    }

    // MARK: - Error State Tests

    func testError_CanBeSet() {
        XCTAssertNil(sut.error)

        sut.error = "Failed to calculate health score"
        XCTAssertEqual(sut.error, "Failed to calculate health score", "error should be settable")

        sut.error = nil
        XCTAssertNil(sut.error, "error should be clearable")
    }

    // MARK: - Loading State Tests

    func testIsLoading_CanBeSet() {
        XCTAssertFalse(sut.isLoading)

        sut.isLoading = true
        XCTAssertTrue(sut.isLoading, "isLoading should be settable to true")

        sut.isLoading = false
        XCTAssertFalse(sut.isLoading, "isLoading should be settable to false")
    }

    // MARK: - ScoreTrend Tests

    func testScoreTrend_AllCasesHaveIcon() {
        let trends: [ScoreTrend] = [.improving, .stable, .declining]
        for trend in trends {
            XCTAssertFalse(trend.icon.isEmpty, "Trend \(trend) should have an icon")
        }
    }

    func testScoreTrend_AllCasesHaveColor() {
        let trends: [ScoreTrend] = [.improving, .stable, .declining]
        for trend in trends {
            XCTAssertFalse(trend.color.isEmpty, "Trend \(trend) should have a color")
        }
    }

    func testScoreTrend_Icons() {
        XCTAssertEqual(ScoreTrend.improving.icon, "arrow.up.right")
        XCTAssertEqual(ScoreTrend.stable.icon, "arrow.right")
        XCTAssertEqual(ScoreTrend.declining.icon, "arrow.down.right")
    }

    func testScoreTrend_Colors() {
        XCTAssertEqual(ScoreTrend.improving.color, "green")
        XCTAssertEqual(ScoreTrend.stable.color, "yellow")
        XCTAssertEqual(ScoreTrend.declining.color, "red")
    }

    // MARK: - InsightCategory Tests

    func testInsightCategory_AllCasesHaveDisplayName() {
        for category in InsightCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty, "Category \(category) should have a display name")
        }
    }

    func testInsightCategory_AllCasesHaveIcon() {
        for category in InsightCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty, "Category \(category) should have an icon")
        }
    }

    func testInsightCategory_DisplayNames() {
        XCTAssertEqual(InsightCategory.sleep.displayName, "Sleep")
        XCTAssertEqual(InsightCategory.recovery.displayName, "Recovery")
        XCTAssertEqual(InsightCategory.nutrition.displayName, "Nutrition")
        XCTAssertEqual(InsightCategory.training.displayName, "Training")
        XCTAssertEqual(InsightCategory.stress.displayName, "Stress")
        XCTAssertEqual(InsightCategory.supplements.displayName, "Supplements")
        XCTAssertEqual(InsightCategory.labs.displayName, "Lab Results")
        XCTAssertEqual(InsightCategory.general.displayName, "General")
    }

    // MARK: - InsightPriority Tests

    func testInsightPriority_AllCasesExist() {
        let priorities: [InsightPriority] = [.high, .medium, .low]
        for priority in priorities {
            XCTAssertNotNil(priority.rawValue, "Priority \(priority) should have a raw value")
        }
    }

    // MARK: - MessageRole Tests

    func testMessageRole_AllCasesExist() {
        let roles: [MessageRole] = [.user, .assistant, .system]
        for role in roles {
            XCTAssertNotNil(role.rawValue, "Role \(role) should have a raw value")
        }
    }

    // MARK: - Edge Cases

    func testHealthScore_CanBeCleared() {
        sut.healthScore = createMockHealthScore(overallScore: 75)
        XCTAssertNotNil(sut.healthScore)

        sut.healthScore = nil
        XCTAssertNil(sut.healthScore, "healthScore should be clearable")
    }

    func testScoreHistory_CanBeSet() {
        let history = [
            createMockHealthScore(overallScore: 70),
            createMockHealthScore(overallScore: 75)
        ]
        sut.scoreHistory = history

        XCTAssertEqual(sut.scoreHistory.count, 2, "scoreHistory should be settable")
    }

    func testInsights_CanBeCleared() {
        let insight = createMockInsight(priority: .high, title: "Test")
        sut.insights = [insight]

        XCTAssertFalse(sut.insights.isEmpty)

        sut.insights = []
        XCTAssertTrue(sut.insights.isEmpty, "insights should be clearable")
    }

    func testScoreBoundaries() {
        // Test exactly at boundaries
        sut.healthScore = createMockHealthScore(overallScore: 80)
        XCTAssertEqual(sut.scoreDescription, "Excellent")

        sut.healthScore = createMockHealthScore(overallScore: 79)
        XCTAssertEqual(sut.scoreDescription, "Good")

        sut.healthScore = createMockHealthScore(overallScore: 60)
        XCTAssertEqual(sut.scoreDescription, "Good")

        sut.healthScore = createMockHealthScore(overallScore: 59)
        XCTAssertEqual(sut.scoreDescription, "Fair")

        sut.healthScore = createMockHealthScore(overallScore: 40)
        XCTAssertEqual(sut.scoreDescription, "Fair")

        sut.healthScore = createMockHealthScore(overallScore: 39)
        XCTAssertEqual(sut.scoreDescription, "Needs Attention")
    }

    // MARK: - Helper Methods

    private func createMockHealthScore(overallScore: Int) -> HealthScore {
        return HealthScore(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            overallScore: overallScore,
            sleepScore: 70,
            recoveryScore: 75,
            nutritionScore: 80,
            activityScore: 65,
            stressScore: 70,
            breakdown: [],
            insights: [],
            createdAt: Date()
        )
    }

    private func createMockInsight(priority: InsightPriority, title: String) -> HealthInsight {
        return HealthInsight(
            id: UUID(),
            category: .general,
            title: title,
            description: "Test description",
            actionable: true,
            action: "Take action",
            priority: priority
        )
    }
}
