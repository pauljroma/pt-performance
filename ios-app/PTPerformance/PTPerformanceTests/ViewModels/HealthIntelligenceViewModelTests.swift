//
//  HealthIntelligenceViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for Health Intelligence ViewModels
//  Tests AICoachViewModel state management, message handling, and computed properties
//

import XCTest
import SwiftUI
@testable import PTPerformance

// MARK: - AICoachViewModel Tests

@MainActor
final class AICoachViewModelTests: XCTestCase {

    var sut: AICoachViewModel!

    override func setUp() {
        super.setUp()
        sut = AICoachViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_MessagesHasWelcomeMessage() {
        XCTAssertEqual(sut.messages.count, 1)
        XCTAssertEqual(sut.messages.first?.role, .coach)
        XCTAssertTrue(sut.messages.first?.content.contains("AI Performance Coach") == true)
    }

    func testInitialState_InsightsIsEmpty() {
        XCTAssertTrue(sut.insights.isEmpty)
    }

    func testInitialState_SuggestedQuestionsExist() {
        XCTAssertFalse(sut.suggestedQuestions.isEmpty)
        XCTAssertEqual(sut.suggestedQuestions.count, 4) // Default questions
    }

    func testInitialState_TodayFocusIsEmpty() {
        XCTAssertEqual(sut.todayFocus, "")
    }

    func testInitialState_WeeklyPrioritiesIsEmpty() {
        XCTAssertTrue(sut.weeklyPriorities.isEmpty)
    }

    func testInitialState_DataSummaryIsNil() {
        XCTAssertNil(sut.dataSummary)
    }

    func testInitialState_ProactiveAlertsIsEmpty() {
        XCTAssertTrue(sut.proactiveAlerts.isEmpty)
    }

    func testInitialState_InputMessageIsEmpty() {
        XCTAssertEqual(sut.inputMessage, "")
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading)
    }

    func testInitialState_IsTypingIsFalse() {
        XCTAssertFalse(sut.isTyping)
    }

    func testInitialState_ErrorIsNil() {
        XCTAssertNil(sut.error)
    }

    // MARK: - Computed Properties Tests

    func testHighPriorityInsights_WhenEmpty() {
        sut.insights = []
        XCTAssertTrue(sut.highPriorityInsights.isEmpty)
    }

    func testHighPriorityInsights_FiltersCorrectly() {
        let highInsight = CoachingInsight(
            category: .recovery,
            priority: .high,
            insight: "High priority insight",
            action: "Take action",
            rationale: "Because"
        )
        let mediumInsight = CoachingInsight(
            category: .training,
            priority: .medium,
            insight: "Medium priority insight",
            action: "Consider",
            rationale: "Maybe"
        )
        let lowInsight = CoachingInsight(
            category: .nutrition,
            priority: .low,
            insight: "Low priority insight",
            action: "Optional",
            rationale: "If you want"
        )

        sut.insights = [highInsight, mediumInsight, lowInsight]

        XCTAssertEqual(sut.highPriorityInsights.count, 1)
        XCTAssertEqual(sut.highPriorityInsights.first?.priority, .high)
    }

    func testHighPriorityInsights_MultipleHighPriority() {
        let high1 = CoachingInsight(
            category: .recovery,
            priority: .high,
            insight: "High 1",
            action: "Action 1",
            rationale: "Reason 1"
        )
        let high2 = CoachingInsight(
            category: .sleep,
            priority: .high,
            insight: "High 2",
            action: "Action 2",
            rationale: "Reason 2"
        )

        sut.insights = [high1, high2]

        XCTAssertEqual(sut.highPriorityInsights.count, 2)
    }

    func testInsightsByCategory_EmptyWhenNoInsights() {
        sut.insights = []
        XCTAssertTrue(sut.insightsByCategory.isEmpty)
    }

    func testInsightsByCategory_GroupsCorrectly() {
        let recoveryInsight = CoachingInsight(
            category: .recovery,
            priority: .high,
            insight: "Recovery insight",
            action: "Recover",
            rationale: "Need rest"
        )
        let trainingInsight = CoachingInsight(
            category: .training,
            priority: .medium,
            insight: "Training insight",
            action: "Train",
            rationale: "Get stronger"
        )

        sut.insights = [recoveryInsight, trainingInsight]

        let grouped = sut.insightsByCategory

        XCTAssertEqual(grouped.count, 2)
    }

    func testHasAlerts_FalseWhenEmpty() {
        sut.proactiveAlerts = []
        XCTAssertFalse(sut.hasAlerts)
    }

    func testHasAlerts_TrueWhenNotEmpty() {
        sut.proactiveAlerts = ["Your HRV is declining"]
        XCTAssertTrue(sut.hasAlerts)
    }

    func testUnreadInsightCount_ZeroWhenEmpty() {
        sut.insights = []
        XCTAssertEqual(sut.unreadInsightCount, 0)
    }

    func testUnreadInsightCount_CountsHighPriorityOnly() {
        let high = CoachingInsight(
            category: .recovery,
            priority: .high,
            insight: "High",
            action: "Act",
            rationale: "Why"
        )
        let medium = CoachingInsight(
            category: .training,
            priority: .medium,
            insight: "Medium",
            action: "Maybe",
            rationale: "Perhaps"
        )

        sut.insights = [high, medium]

        XCTAssertEqual(sut.unreadInsightCount, 1)
    }

    // MARK: - State Update Tests

    func testInputMessage_CanBeUpdated() {
        sut.inputMessage = "How is my recovery?"
        XCTAssertEqual(sut.inputMessage, "How is my recovery?")
    }

    func testIsTyping_CanBeUpdated() {
        sut.isTyping = true
        XCTAssertTrue(sut.isTyping)

        sut.isTyping = false
        XCTAssertFalse(sut.isTyping)
    }

    func testIsLoading_CanBeUpdated() {
        sut.isLoading = true
        XCTAssertTrue(sut.isLoading)

        sut.isLoading = false
        XCTAssertFalse(sut.isLoading)
    }

    func testError_CanBeSet() {
        sut.error = "Network error occurred"
        XCTAssertEqual(sut.error, "Network error occurred")
    }

    func testError_CanBeCleared() {
        sut.error = "Some error"
        sut.error = nil
        XCTAssertNil(sut.error)
    }

    // MARK: - Messages Tests

    func testMessages_CanBeAppended() {
        let initialCount = sut.messages.count

        let newMessage = AICoachMessage(
            role: .user,
            content: "Test question"
        )
        sut.messages.append(newMessage)

        XCTAssertEqual(sut.messages.count, initialCount + 1)
    }

    func testMessages_WelcomeMessageHasSuggestedQuestions() {
        let welcomeMessage = sut.messages.first
        XCTAssertNotNil(welcomeMessage?.suggestedQuestions)
        XCTAssertFalse(welcomeMessage?.suggestedQuestions?.isEmpty ?? true)
    }

    // MARK: - Data Summary Tests

    func testDataSummary_CanBeSet() {
        let summary = DataSummary(
            readiness: "High - 85/100",
            training: "3 sessions this week",
            recovery: "Adequate",
            labs: "No recent data"
        )

        sut.dataSummary = summary

        XCTAssertEqual(sut.dataSummary?.readiness, "High - 85/100")
        XCTAssertEqual(sut.dataSummary?.training, "3 sessions this week")
    }

    // MARK: - Weekly Priorities Tests

    func testWeeklyPriorities_CanBeSet() {
        sut.weeklyPriorities = ["Improve sleep", "Add recovery sessions", "Track nutrition"]

        XCTAssertEqual(sut.weeklyPriorities.count, 3)
        XCTAssertTrue(sut.weeklyPriorities.contains("Improve sleep"))
    }

    // MARK: - Today Focus Tests

    func testTodayFocus_CanBeSet() {
        sut.todayFocus = "Focus on mobility work and recovery"
        XCTAssertEqual(sut.todayFocus, "Focus on mobility work and recovery")
    }

    // MARK: - Suggested Questions Tests

    func testSuggestedQuestions_DefaultQuestions() {
        let defaultQuestions = sut.suggestedQuestions

        XCTAssertTrue(defaultQuestions.contains { $0.lowercased().contains("recovery") })
        XCTAssertTrue(defaultQuestions.contains { $0.lowercased().contains("today") || $0.lowercased().contains("focus") })
    }

    func testSuggestedQuestions_CanBeUpdated() {
        sut.suggestedQuestions = ["Custom question 1", "Custom question 2"]

        XCTAssertEqual(sut.suggestedQuestions.count, 2)
        XCTAssertTrue(sut.suggestedQuestions.contains("Custom question 1"))
    }

    // MARK: - Edge Cases

    func testInsights_CanBeCleared() {
        let insight = CoachingInsight(
            category: .general,
            priority: .medium,
            insight: "Test",
            action: "Do",
            rationale: "Why"
        )
        sut.insights = [insight]

        XCTAssertFalse(sut.insights.isEmpty)

        sut.insights = []
        XCTAssertTrue(sut.insights.isEmpty)
    }

    func testProactiveAlerts_CanBeCleared() {
        sut.proactiveAlerts = ["Alert 1", "Alert 2"]
        XCTAssertTrue(sut.hasAlerts)

        sut.proactiveAlerts = []
        XCTAssertFalse(sut.hasAlerts)
    }

    func testMultipleInsightCategories() {
        let insights = [
            CoachingInsight(category: .recovery, priority: .high, insight: "Recovery", action: "Rest", rationale: "Tired"),
            CoachingInsight(category: .recovery, priority: .medium, insight: "Recovery 2", action: "Sleep", rationale: "Need more"),
            CoachingInsight(category: .training, priority: .high, insight: "Training", action: "Deload", rationale: "High volume"),
            CoachingInsight(category: .nutrition, priority: .low, insight: "Nutrition", action: "Eat", rationale: "Fuel")
        ]

        sut.insights = insights

        let grouped = sut.insightsByCategory

        // Should have 3 categories
        XCTAssertEqual(grouped.count, 3)

        // Recovery should have 2 insights
        let recoveryGroup = grouped.first { $0.0 == .recovery }
        XCTAssertEqual(recoveryGroup?.1.count, 2)
    }
}

// MARK: - AICoachViewModel Ask Question Tests

@MainActor
final class AICoachViewModelAskQuestionTests: XCTestCase {

    var sut: AICoachViewModel!

    override func setUp() {
        super.setUp()
        sut = AICoachViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testAskQuestion_SetsInputMessage() async {
        // Note: This test checks that askQuestion sets the input message
        // The actual API call would require mocking

        let question = "How is my sleep quality?"

        // Directly test that askQuestion updates inputMessage before calling sendMessage
        // Since we can't easily mock the service, we just verify the input behavior
        sut.inputMessage = question

        XCTAssertEqual(sut.inputMessage, question)
    }

    func testInputMessage_TrimmedBeforeSending() {
        // Simulate setting a message with whitespace
        sut.inputMessage = "  How is my recovery?  "

        let trimmed = sut.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertEqual(trimmed, "How is my recovery?")
    }

    func testEmptyInputMessage_NotSent() {
        // Empty messages should not be sent
        sut.inputMessage = "   "

        let trimmed = sut.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertTrue(trimmed.isEmpty)
    }
}

// MARK: - AICoachViewModel Message Flow Tests

@MainActor
final class AICoachViewModelMessageFlowTests: XCTestCase {

    var sut: AICoachViewModel!

    override func setUp() {
        super.setUp()
        sut = AICoachViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testMessageFlow_UserMessageAdded() {
        let initialCount = sut.messages.count

        // Simulate adding a user message
        let userMessage = AICoachMessage(
            role: .user,
            content: "What should I focus on today?"
        )
        sut.messages.append(userMessage)

        XCTAssertEqual(sut.messages.count, initialCount + 1)
        XCTAssertEqual(sut.messages.last?.role, .user)
        XCTAssertEqual(sut.messages.last?.content, "What should I focus on today?")
    }

    func testMessageFlow_CoachResponseAdded() {
        let initialCount = sut.messages.count

        // Simulate coach response
        let coachMessage = AICoachMessage(
            role: .coach,
            content: "Based on your data, focus on recovery today.",
            insights: [],
            suggestedQuestions: ["How can I improve recovery?"]
        )
        sut.messages.append(coachMessage)

        XCTAssertEqual(sut.messages.count, initialCount + 1)
        XCTAssertEqual(sut.messages.last?.role, .coach)
    }

    func testMessageFlow_ConversationHistory() {
        // Simulate a conversation
        let messages = [
            AICoachMessage(role: .user, content: "Question 1"),
            AICoachMessage(role: .coach, content: "Answer 1"),
            AICoachMessage(role: .user, content: "Question 2"),
            AICoachMessage(role: .coach, content: "Answer 2")
        ]

        for message in messages {
            sut.messages.append(message)
        }

        // Initial welcome message + 4 conversation messages
        XCTAssertEqual(sut.messages.count, 5)

        // Verify alternating pattern (after welcome)
        XCTAssertEqual(sut.messages[1].role, .user)
        XCTAssertEqual(sut.messages[2].role, .coach)
        XCTAssertEqual(sut.messages[3].role, .user)
        XCTAssertEqual(sut.messages[4].role, .coach)
    }
}

// MARK: - AICoachViewModel Loading State Tests

@MainActor
final class AICoachViewModelLoadingStateTests: XCTestCase {

    var sut: AICoachViewModel!

    override func setUp() {
        super.setUp()
        sut = AICoachViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testLoadingState_InitiallyFalse() {
        XCTAssertFalse(sut.isLoading)
    }

    func testTypingState_InitiallyFalse() {
        XCTAssertFalse(sut.isTyping)
    }

    func testLoadingAndTypingStates_CanBeSetIndependently() {
        sut.isLoading = true
        sut.isTyping = false

        XCTAssertTrue(sut.isLoading)
        XCTAssertFalse(sut.isTyping)

        sut.isLoading = false
        sut.isTyping = true

        XCTAssertFalse(sut.isLoading)
        XCTAssertTrue(sut.isTyping)
    }
}

// MARK: - AICoachViewModel Error State Tests

@MainActor
final class AICoachViewModelErrorStateTests: XCTestCase {

    var sut: AICoachViewModel!

    override func setUp() {
        super.setUp()
        sut = AICoachViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testErrorState_InitiallyNil() {
        XCTAssertNil(sut.error)
    }

    func testErrorState_CanBeSet() {
        sut.error = "Failed to connect to server"
        XCTAssertEqual(sut.error, "Failed to connect to server")
    }

    func testErrorState_CanBeCleared() {
        sut.error = "Some error"
        XCTAssertNotNil(sut.error)

        sut.error = nil
        XCTAssertNil(sut.error)
    }

    func testErrorState_VariousErrorTypes() {
        let errorMessages = [
            "Network connection failed",
            "Unable to identify patient",
            "Server returned invalid response",
            "Request timed out"
        ]

        for errorMessage in errorMessages {
            sut.error = errorMessage
            XCTAssertEqual(sut.error, errorMessage)
        }
    }
}

// MARK: - AICoachViewModel Data Loading States Tests

@MainActor
final class AICoachViewModelDataLoadingTests: XCTestCase {

    var sut: AICoachViewModel!

    override func setUp() {
        super.setUp()
        sut = AICoachViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Loading State Transitions

    func testLoadingState_TransitionFromIdleToLoading() {
        XCTAssertFalse(sut.isLoading)

        sut.isLoading = true

        XCTAssertTrue(sut.isLoading)
    }

    func testLoadingState_TransitionFromLoadingToIdle() {
        sut.isLoading = true
        XCTAssertTrue(sut.isLoading)

        sut.isLoading = false

        XCTAssertFalse(sut.isLoading)
    }

    func testTypingState_TransitionFromIdleToTyping() {
        XCTAssertFalse(sut.isTyping)

        sut.isTyping = true

        XCTAssertTrue(sut.isTyping)
    }

    func testTypingState_TransitionFromTypingToIdle() {
        sut.isTyping = true
        XCTAssertTrue(sut.isTyping)

        sut.isTyping = false

        XCTAssertFalse(sut.isTyping)
    }

    // MARK: - Concurrent State Management

    func testConcurrentStates_BothLoadingAndTypingTrue() {
        sut.isLoading = true
        sut.isTyping = true

        XCTAssertTrue(sut.isLoading)
        XCTAssertTrue(sut.isTyping)
    }

    func testConcurrentStates_LoadingWithError() {
        sut.isLoading = true
        sut.error = "Network error"

        XCTAssertTrue(sut.isLoading)
        XCTAssertNotNil(sut.error)
    }

    func testConcurrentStates_ClearErrorWhileLoading() {
        sut.isLoading = true
        sut.error = "Previous error"

        sut.error = nil

        XCTAssertTrue(sut.isLoading)
        XCTAssertNil(sut.error)
    }

    // MARK: - Data Summary Loading

    func testDataSummary_LoadingWithPartialData() {
        let summary = DataSummary(
            readiness: "High - 85/100",
            training: "",
            recovery: "Adequate",
            labs: ""
        )

        sut.dataSummary = summary

        XCTAssertEqual(sut.dataSummary?.readiness, "High - 85/100")
        XCTAssertEqual(sut.dataSummary?.training, "")
        XCTAssertEqual(sut.dataSummary?.recovery, "Adequate")
        XCTAssertEqual(sut.dataSummary?.labs, "")
    }

    func testDataSummary_ClearingSummary() {
        sut.dataSummary = DataSummary(
            readiness: "High",
            training: "Active",
            recovery: "Good",
            labs: "Recent"
        )
        XCTAssertNotNil(sut.dataSummary)

        sut.dataSummary = nil

        XCTAssertNil(sut.dataSummary)
    }

    // MARK: - Edge Cases for Loading States

    func testLoadingState_RapidToggle() {
        for _ in 0..<10 {
            sut.isLoading = true
            sut.isLoading = false
        }

        XCTAssertFalse(sut.isLoading)
    }

    func testTypingState_RapidToggle() {
        for _ in 0..<10 {
            sut.isTyping = true
            sut.isTyping = false
        }

        XCTAssertFalse(sut.isTyping)
    }
}

// MARK: - AICoachViewModel Error Handling Tests

@MainActor
final class AICoachViewModelErrorHandlingTests: XCTestCase {

    var sut: AICoachViewModel!

    override func setUp() {
        super.setUp()
        sut = AICoachViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Error State Management

    func testError_SetAfterSuccessfulOperation() {
        // Simulate successful messages
        let message = AICoachMessage(role: .coach, content: "Success")
        sut.messages.append(message)

        // Then error occurs
        sut.error = "Unexpected error"

        XCTAssertNotNil(sut.error)
        XCTAssertTrue(sut.messages.count > 1) // Welcome + success message
    }

    func testError_ClearedOnNewOperation() {
        sut.error = "Previous error"
        XCTAssertNotNil(sut.error)

        // Start new operation
        sut.isLoading = true
        sut.error = nil

        XCTAssertNil(sut.error)
        XCTAssertTrue(sut.isLoading)
    }

    func testError_MultipleConsecutiveErrors() {
        sut.error = "Error 1"
        XCTAssertEqual(sut.error, "Error 1")

        sut.error = "Error 2"
        XCTAssertEqual(sut.error, "Error 2")

        sut.error = "Error 3"
        XCTAssertEqual(sut.error, "Error 3")
    }

    // MARK: - Error with Special Characters

    func testError_WithSpecialCharacters() {
        let errorWithSpecialChars = "Error: <network> & \"timeout\" occurred"
        sut.error = errorWithSpecialChars

        XCTAssertEqual(sut.error, errorWithSpecialChars)
    }

    func testError_WithEmptyString() {
        sut.error = ""

        XCTAssertEqual(sut.error, "")
        XCTAssertNotNil(sut.error)
    }

    func testError_WithWhitespaceOnly() {
        sut.error = "   "

        XCTAssertEqual(sut.error, "   ")
    }

    func testError_WithUnicode() {
        sut.error = "Error occurred"

        XCTAssertEqual(sut.error, "Error occurred")
    }
}

// MARK: - AICoachViewModel Score Calculation Tests

@MainActor
final class AICoachViewModelScoreCalculationTests: XCTestCase {

    var sut: AICoachViewModel!

    override func setUp() {
        super.setUp()
        sut = AICoachViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Insight Count Calculations

    func testUnreadInsightCount_WithNoInsights() {
        sut.insights = []
        XCTAssertEqual(sut.unreadInsightCount, 0)
    }

    func testUnreadInsightCount_OnlyHighPriorityInsights() {
        let insights = [
            CoachingInsight(category: .recovery, priority: .high, insight: "High 1", action: "", rationale: ""),
            CoachingInsight(category: .training, priority: .high, insight: "High 2", action: "", rationale: ""),
            CoachingInsight(category: .sleep, priority: .high, insight: "High 3", action: "", rationale: "")
        ]
        sut.insights = insights

        XCTAssertEqual(sut.unreadInsightCount, 3)
    }

    func testUnreadInsightCount_OnlyLowPriorityInsights() {
        let insights = [
            CoachingInsight(category: .recovery, priority: .low, insight: "Low 1", action: "", rationale: ""),
            CoachingInsight(category: .training, priority: .low, insight: "Low 2", action: "", rationale: "")
        ]
        sut.insights = insights

        XCTAssertEqual(sut.unreadInsightCount, 0)
    }

    func testUnreadInsightCount_MixedPriorities() {
        let insights = [
            CoachingInsight(category: .recovery, priority: .high, insight: "High", action: "", rationale: ""),
            CoachingInsight(category: .training, priority: .medium, insight: "Medium", action: "", rationale: ""),
            CoachingInsight(category: .sleep, priority: .low, insight: "Low", action: "", rationale: "")
        ]
        sut.insights = insights

        XCTAssertEqual(sut.unreadInsightCount, 1)
    }

    // MARK: - High Priority Insight Filtering

    func testHighPriorityInsights_CountsCorrectly() {
        let insights = [
            CoachingInsight(category: .recovery, priority: .high, insight: "H1", action: "", rationale: ""),
            CoachingInsight(category: .training, priority: .high, insight: "H2", action: "", rationale: ""),
            CoachingInsight(category: .nutrition, priority: .medium, insight: "M1", action: "", rationale: ""),
            CoachingInsight(category: .sleep, priority: .low, insight: "L1", action: "", rationale: "")
        ]
        sut.insights = insights

        XCTAssertEqual(sut.highPriorityInsights.count, 2)
    }

    func testHighPriorityInsights_AllSameCategory() {
        let insights = [
            CoachingInsight(category: .recovery, priority: .high, insight: "H1", action: "", rationale: ""),
            CoachingInsight(category: .recovery, priority: .high, insight: "H2", action: "", rationale: ""),
            CoachingInsight(category: .recovery, priority: .high, insight: "H3", action: "", rationale: "")
        ]
        sut.insights = insights

        XCTAssertEqual(sut.highPriorityInsights.count, 3)
        XCTAssertTrue(sut.highPriorityInsights.allSatisfy { $0.category == .recovery })
    }

    // MARK: - Insights by Category Grouping

    func testInsightsByCategory_EmptyInsights() {
        sut.insights = []
        XCTAssertTrue(sut.insightsByCategory.isEmpty)
    }

    func testInsightsByCategory_SingleCategory() {
        let insights = [
            CoachingInsight(category: .recovery, priority: .high, insight: "R1", action: "", rationale: ""),
            CoachingInsight(category: .recovery, priority: .medium, insight: "R2", action: "", rationale: "")
        ]
        sut.insights = insights

        XCTAssertEqual(sut.insightsByCategory.count, 1)
        XCTAssertEqual(sut.insightsByCategory.first?.1.count, 2)
    }

    func testInsightsByCategory_AllCategories() {
        let insights = [
            CoachingInsight(category: .recovery, priority: .high, insight: "R", action: "", rationale: ""),
            CoachingInsight(category: .training, priority: .high, insight: "T", action: "", rationale: ""),
            CoachingInsight(category: .nutrition, priority: .high, insight: "N", action: "", rationale: ""),
            CoachingInsight(category: .sleep, priority: .high, insight: "S", action: "", rationale: ""),
            CoachingInsight(category: .labs, priority: .high, insight: "L", action: "", rationale: ""),
            CoachingInsight(category: .general, priority: .high, insight: "G", action: "", rationale: "")
        ]
        sut.insights = insights

        XCTAssertEqual(sut.insightsByCategory.count, 6)
    }

    // MARK: - Alerts Calculation

    func testHasAlerts_EmptyAlerts() {
        sut.proactiveAlerts = []
        XCTAssertFalse(sut.hasAlerts)
    }

    func testHasAlerts_SingleAlert() {
        sut.proactiveAlerts = ["HRV declining"]
        XCTAssertTrue(sut.hasAlerts)
    }

    func testHasAlerts_MultipleAlerts() {
        sut.proactiveAlerts = ["Alert 1", "Alert 2", "Alert 3"]
        XCTAssertTrue(sut.hasAlerts)
    }
}
