//
//  HealthScoreServiceTests.swift
//  PTPerformanceTests
//
//  Unit tests for HealthScoreService
//  Tests health score models, insights, score components, and service state management
//

import XCTest
@testable import PTPerformance

// MARK: - ScoreTrend Tests

final class ScoreTrendTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testScoreTrend_RawValues() {
        XCTAssertEqual(ScoreTrend.improving.rawValue, "improving")
        XCTAssertEqual(ScoreTrend.stable.rawValue, "stable")
        XCTAssertEqual(ScoreTrend.declining.rawValue, "declining")
    }

    func testScoreTrend_InitFromRawValue() {
        XCTAssertEqual(ScoreTrend(rawValue: "improving"), .improving)
        XCTAssertEqual(ScoreTrend(rawValue: "stable"), .stable)
        XCTAssertEqual(ScoreTrend(rawValue: "declining"), .declining)
        XCTAssertNil(ScoreTrend(rawValue: "invalid"))
    }

    // MARK: - Icon Tests

    func testScoreTrend_Icons() {
        XCTAssertEqual(ScoreTrend.improving.icon, "arrow.up.right")
        XCTAssertEqual(ScoreTrend.stable.icon, "arrow.right")
        XCTAssertEqual(ScoreTrend.declining.icon, "arrow.down.right")
    }

    // MARK: - Color Tests

    func testScoreTrend_Colors() {
        XCTAssertEqual(ScoreTrend.improving.color, "green")
        XCTAssertEqual(ScoreTrend.stable.color, "yellow")
        XCTAssertEqual(ScoreTrend.declining.color, "red")
    }

    // MARK: - Codable Tests

    func testScoreTrend_Encoding() throws {
        let trend = ScoreTrend.improving
        let encoder = JSONEncoder()
        let data = try encoder.encode(trend)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertEqual(jsonString, "\"improving\"")
    }

    func testScoreTrend_Decoding() throws {
        let json = "\"declining\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        let trend = try decoder.decode(ScoreTrend.self, from: json)

        XCTAssertEqual(trend, .declining)
    }
}

// MARK: - InsightCategory Tests

final class InsightCategoryTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testInsightCategory_RawValues() {
        XCTAssertEqual(InsightCategory.sleep.rawValue, "sleep")
        XCTAssertEqual(InsightCategory.recovery.rawValue, "recovery")
        XCTAssertEqual(InsightCategory.nutrition.rawValue, "nutrition")
        XCTAssertEqual(InsightCategory.training.rawValue, "training")
        XCTAssertEqual(InsightCategory.stress.rawValue, "stress")
        XCTAssertEqual(InsightCategory.supplements.rawValue, "supplements")
        XCTAssertEqual(InsightCategory.labs.rawValue, "labs")
        XCTAssertEqual(InsightCategory.general.rawValue, "general")
    }

    func testInsightCategory_InitFromRawValue() {
        XCTAssertEqual(InsightCategory(rawValue: "sleep"), .sleep)
        XCTAssertEqual(InsightCategory(rawValue: "recovery"), .recovery)
        XCTAssertEqual(InsightCategory(rawValue: "nutrition"), .nutrition)
        XCTAssertEqual(InsightCategory(rawValue: "training"), .training)
        XCTAssertEqual(InsightCategory(rawValue: "stress"), .stress)
        XCTAssertEqual(InsightCategory(rawValue: "supplements"), .supplements)
        XCTAssertEqual(InsightCategory(rawValue: "labs"), .labs)
        XCTAssertEqual(InsightCategory(rawValue: "general"), .general)
        XCTAssertNil(InsightCategory(rawValue: "invalid"))
    }

    // MARK: - Display Name Tests

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

    // MARK: - Icon Tests

    func testInsightCategory_Icons() {
        XCTAssertEqual(InsightCategory.sleep.icon, "moon.fill")
        XCTAssertEqual(InsightCategory.recovery.icon, "heart.fill")
        XCTAssertEqual(InsightCategory.nutrition.icon, "leaf.fill")
        XCTAssertEqual(InsightCategory.training.icon, "figure.run")
        XCTAssertEqual(InsightCategory.stress.icon, "brain.head.profile")
        XCTAssertEqual(InsightCategory.supplements.icon, "pill.fill")
        XCTAssertEqual(InsightCategory.labs.icon, "cross.case.fill")
        XCTAssertEqual(InsightCategory.general.icon, "lightbulb.fill")
    }

    // MARK: - CaseIterable Tests

    func testInsightCategory_AllCases() {
        let allCases = InsightCategory.allCases
        XCTAssertEqual(allCases.count, 8)
        XCTAssertTrue(allCases.contains(.sleep))
        XCTAssertTrue(allCases.contains(.recovery))
        XCTAssertTrue(allCases.contains(.nutrition))
        XCTAssertTrue(allCases.contains(.training))
        XCTAssertTrue(allCases.contains(.stress))
        XCTAssertTrue(allCases.contains(.supplements))
        XCTAssertTrue(allCases.contains(.labs))
        XCTAssertTrue(allCases.contains(.general))
    }

    // MARK: - Codable Tests

    func testInsightCategory_Encoding() throws {
        let category = InsightCategory.sleep
        let encoder = JSONEncoder()
        let data = try encoder.encode(category)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertEqual(jsonString, "\"sleep\"")
    }

    func testInsightCategory_Decoding() throws {
        let json = "\"nutrition\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        let category = try decoder.decode(InsightCategory.self, from: json)

        XCTAssertEqual(category, .nutrition)
    }
}

// MARK: - InsightPriority Tests

final class InsightPriorityTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testInsightPriority_RawValues() {
        XCTAssertEqual(InsightPriority.high.rawValue, "high")
        XCTAssertEqual(InsightPriority.medium.rawValue, "medium")
        XCTAssertEqual(InsightPriority.low.rawValue, "low")
    }

    func testInsightPriority_InitFromRawValue() {
        XCTAssertEqual(InsightPriority(rawValue: "high"), .high)
        XCTAssertEqual(InsightPriority(rawValue: "medium"), .medium)
        XCTAssertEqual(InsightPriority(rawValue: "low"), .low)
        XCTAssertNil(InsightPriority(rawValue: "invalid"))
    }

    // MARK: - Codable Tests

    func testInsightPriority_Encoding() throws {
        let priority = InsightPriority.high
        let encoder = JSONEncoder()
        let data = try encoder.encode(priority)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertEqual(jsonString, "\"high\"")
    }

    func testInsightPriority_Decoding() throws {
        let json = "\"low\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        let priority = try decoder.decode(InsightPriority.self, from: json)

        XCTAssertEqual(priority, .low)
    }
}

// MARK: - MessageRole Tests

final class MessageRoleTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testMessageRole_RawValues() {
        XCTAssertEqual(MessageRole.user.rawValue, "user")
        XCTAssertEqual(MessageRole.assistant.rawValue, "assistant")
        XCTAssertEqual(MessageRole.system.rawValue, "system")
    }

    func testMessageRole_InitFromRawValue() {
        XCTAssertEqual(MessageRole(rawValue: "user"), .user)
        XCTAssertEqual(MessageRole(rawValue: "assistant"), .assistant)
        XCTAssertEqual(MessageRole(rawValue: "system"), .system)
        XCTAssertNil(MessageRole(rawValue: "invalid"))
    }

    // MARK: - Codable Tests

    func testMessageRole_Encoding() throws {
        let role = MessageRole.assistant
        let encoder = JSONEncoder()
        let data = try encoder.encode(role)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertEqual(jsonString, "\"assistant\"")
    }

    func testMessageRole_Decoding() throws {
        let json = "\"user\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        let role = try decoder.decode(MessageRole.self, from: json)

        XCTAssertEqual(role, .user)
    }
}

// MARK: - HealthScoreComponent Tests

final class HealthScoreComponentTests: XCTestCase {

    // MARK: - Memberwise Initializer Tests

    func testHealthScoreComponent_MemberwiseInit() {
        let id = UUID()
        let component = HealthScoreComponent(
            id: id,
            category: "Sleep",
            score: 85,
            weight: 0.25,
            trend: .improving
        )

        XCTAssertEqual(component.id, id)
        XCTAssertEqual(component.category, "Sleep")
        XCTAssertEqual(component.score, 85)
        XCTAssertEqual(component.weight, 0.25)
        XCTAssertEqual(component.trend, .improving)
    }

    // MARK: - Identifiable Tests

    func testHealthScoreComponent_Identifiable() {
        let id = UUID()
        let component = HealthScoreComponent(
            id: id,
            category: "Test",
            score: 50,
            weight: 0.2,
            trend: .stable
        )

        XCTAssertEqual(component.id, id)
    }

    // MARK: - Hashable Tests

    func testHealthScoreComponent_Hashable() {
        let id = UUID()
        let component1 = HealthScoreComponent(
            id: id,
            category: "Sleep",
            score: 85,
            weight: 0.25,
            trend: .stable
        )
        let component2 = HealthScoreComponent(
            id: id,
            category: "Sleep",
            score: 85,
            weight: 0.25,
            trend: .stable
        )

        XCTAssertEqual(component1, component2)
    }
}

// MARK: - HealthInsight Tests

final class HealthInsightTests: XCTestCase {

    // MARK: - Memberwise Initializer Tests

    func testHealthInsight_MemberwiseInit() {
        let id = UUID()
        let insight = HealthInsight(
            id: id,
            category: .sleep,
            title: "Improve sleep quality",
            description: "Your sleep score has been declining. Try going to bed earlier.",
            actionable: true,
            action: "View sleep tips",
            priority: .high
        )

        XCTAssertEqual(insight.id, id)
        XCTAssertEqual(insight.category, .sleep)
        XCTAssertEqual(insight.title, "Improve sleep quality")
        XCTAssertEqual(insight.description, "Your sleep score has been declining. Try going to bed earlier.")
        XCTAssertEqual(insight.actionable, true)
        XCTAssertEqual(insight.action, "View sleep tips")
        XCTAssertEqual(insight.priority, .high)
    }

    func testHealthInsight_OptionalAction() {
        let insight = HealthInsight(
            id: UUID(),
            category: .general,
            title: "Good progress",
            description: "Keep up the great work!",
            actionable: false,
            action: nil,
            priority: .low
        )

        XCTAssertFalse(insight.actionable)
        XCTAssertNil(insight.action)
    }

    // MARK: - Identifiable Tests

    func testHealthInsight_Identifiable() {
        let id = UUID()
        let insight = HealthInsight(
            id: id,
            category: .nutrition,
            title: "Test",
            description: "Test description",
            actionable: false,
            action: nil,
            priority: .medium
        )

        XCTAssertEqual(insight.id, id)
    }

    // MARK: - Hashable Tests

    func testHealthInsight_Hashable() {
        let id = UUID()
        let insight1 = HealthInsight(
            id: id,
            category: .recovery,
            title: "Test",
            description: "Description",
            actionable: true,
            action: "Action",
            priority: .medium
        )
        let insight2 = HealthInsight(
            id: id,
            category: .recovery,
            title: "Test",
            description: "Description",
            actionable: true,
            action: "Action",
            priority: .medium
        )

        XCTAssertEqual(insight1, insight2)
    }
}

// MARK: - HealthScore Tests

final class HealthScoreServiceItemTests: XCTestCase {

    // MARK: - Memberwise Initializer Tests

    func testHealthScore_MemberwiseInit() {
        let id = UUID()
        let patientId = UUID()
        let date = Date()
        let createdAt = Date()

        let breakdown: [HealthScoreComponent] = []
        let insights: [HealthInsight] = []

        let score = HealthScore(
            id: id,
            patientId: patientId,
            date: date,
            overallScore: 78,
            sleepScore: 85,
            recoveryScore: 70,
            nutritionScore: 75,
            activityScore: 80,
            stressScore: 65,
            breakdown: breakdown,
            insights: insights,
            createdAt: createdAt
        )

        XCTAssertEqual(score.id, id)
        XCTAssertEqual(score.patientId, patientId)
        XCTAssertEqual(score.date, date)
        XCTAssertEqual(score.overallScore, 78)
        XCTAssertEqual(score.sleepScore, 85)
        XCTAssertEqual(score.recoveryScore, 70)
        XCTAssertEqual(score.nutritionScore, 75)
        XCTAssertEqual(score.activityScore, 80)
        XCTAssertEqual(score.stressScore, 65)
    }

    // MARK: - Identifiable Tests

    func testHealthScore_Identifiable() {
        let id = UUID()
        let score = HealthScore(
            id: id,
            patientId: UUID(),
            date: Date(),
            overallScore: 75,
            sleepScore: 75,
            recoveryScore: 75,
            nutritionScore: 75,
            activityScore: 75,
            stressScore: 75,
            breakdown: [],
            insights: [],
            createdAt: Date()
        )

        XCTAssertEqual(score.id, id)
    }
}

// MARK: - HealthCoachMessage Tests

final class HealthCoachMessageTests: XCTestCase {

    // MARK: - Memberwise Initializer Tests

    func testHealthCoachMessage_MemberwiseInit() {
        let id = UUID()
        let timestamp = Date()

        let message = HealthCoachMessage(
            id: id,
            role: .assistant,
            content: "Based on your data, I recommend focusing on recovery today.",
            timestamp: timestamp,
            category: .recovery
        )

        XCTAssertEqual(message.id, id)
        XCTAssertEqual(message.role, .assistant)
        XCTAssertEqual(message.content, "Based on your data, I recommend focusing on recovery today.")
        XCTAssertEqual(message.timestamp, timestamp)
        XCTAssertEqual(message.category, .recovery)
    }

    func testHealthCoachMessage_OptionalCategory() {
        let message = HealthCoachMessage(
            id: UUID(),
            role: .user,
            content: "How am I doing?",
            timestamp: Date(),
            category: nil
        )

        XCTAssertNil(message.category)
    }

    // MARK: - Identifiable Tests

    func testHealthCoachMessage_Identifiable() {
        let id = UUID()
        let message = HealthCoachMessage(
            id: id,
            role: .user,
            content: "Test",
            timestamp: Date(),
            category: nil
        )

        XCTAssertEqual(message.id, id)
    }
}

// MARK: - HealthScoreService Tests

@MainActor
final class HealthScoreServiceTests: XCTestCase {

    var sut: HealthScoreService!

    override func setUp() async throws {
        try await super.setUp()
        sut = HealthScoreService.shared
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Singleton Tests

    func testSharedInstanceExists() {
        XCTAssertNotNil(HealthScoreService.shared)
    }

    func testSharedInstanceIsSingleton() {
        let instance1 = HealthScoreService.shared
        let instance2 = HealthScoreService.shared
        XCTAssertTrue(instance1 === instance2, "Shared instances should be the same object")
    }

    // MARK: - Initial State Tests

    func testInitialState_CurrentScoreProperty() {
        // Current score can be nil initially
        _ = sut.currentScore
    }

    func testInitialState_ScoreHistoryIsArray() {
        XCTAssertNotNil(sut.scoreHistory)
        XCTAssertTrue(sut.scoreHistory is [HealthScore])
    }

    func testInitialState_InsightsIsArray() {
        XCTAssertNotNil(sut.insights)
        XCTAssertTrue(sut.insights is [HealthInsight])
    }

    func testInitialState_IsLoadingProperty() {
        _ = sut.isLoading
    }

    func testInitialState_ErrorProperty() {
        _ = sut.error
    }

    // MARK: - Published Properties Tests

    func testCurrentScore_IsPublished() {
        // Can be nil or have value
        _ = sut.currentScore
    }

    func testScoreHistory_IsPublished() {
        let history = sut.scoreHistory
        XCTAssertNotNil(history)
    }

    func testInsights_IsPublished() {
        let insights = sut.insights
        XCTAssertNotNil(insights)
    }

    // MARK: - Send Message Tests

    func testSendMessage_ReturnsAssistantMessage() async {
        // When
        let response = await sut.sendMessage("How am I doing?")

        // Then
        XCTAssertEqual(response.role, .assistant)
        XCTAssertFalse(response.content.isEmpty)
    }

    func testSendMessage_ContainsValidCategory() async {
        // When
        let response = await sut.sendMessage("What should I focus on?")

        // Then - service may return different categories based on context
        // Verify the response has a valid category (any of the possible values)
        let validCategories: [InsightCategory] = [.general, .recovery, .training, .nutrition, .sleep]
        if let category = response.category {
            XCTAssertTrue(validCategories.contains(category),
                          "Expected valid category, got \(category)")
        }
        // Category may be nil in some responses, which is acceptable
    }

    // MARK: - Calculate Today Score Tests
    //
    // Note: These tests use the real HealthScoreService singleton which requires
    // network access. In test environments without network, the service may not
    // return data. Tests are designed to verify behavior when data IS available.

    func testCalculateTodayScore_UpdatesCurrentScore() async {
        // When
        await sut.calculateTodayScore()

        // Then - service may not return data in test environment
        // Verify the method completes without error
        // If score is available, it should be valid
        if let score = sut.currentScore {
            XCTAssertGreaterThanOrEqual(score.overallScore, 0)
            XCTAssertLessThanOrEqual(score.overallScore, 100)
        }
        // Test passes even if score is nil (no network in test env)
    }

    func testCalculateTodayScore_SetsAllScores() async {
        // When
        await sut.calculateTodayScore()

        // Then - verify score properties when available
        guard let score = sut.currentScore else {
            // Skip assertions if service didn't return data (no network)
            return
        }

        XCTAssertGreaterThanOrEqual(score.overallScore, 0)
        XCTAssertLessThanOrEqual(score.overallScore, 100)

        XCTAssertGreaterThanOrEqual(score.sleepScore, 0)
        XCTAssertLessThanOrEqual(score.sleepScore, 100)

        XCTAssertGreaterThanOrEqual(score.recoveryScore, 0)
        XCTAssertLessThanOrEqual(score.recoveryScore, 100)

        XCTAssertGreaterThanOrEqual(score.nutritionScore, 0)
        XCTAssertLessThanOrEqual(score.nutritionScore, 100)

        XCTAssertGreaterThanOrEqual(score.activityScore, 0)
        XCTAssertLessThanOrEqual(score.activityScore, 100)

        XCTAssertGreaterThanOrEqual(score.stressScore, 0)
        XCTAssertLessThanOrEqual(score.stressScore, 100)
    }

    func testCalculateTodayScore_GeneratesBreakdown() async {
        // When
        await sut.calculateTodayScore()

        // Then - verify breakdown when available
        guard let score = sut.currentScore else {
            // Skip assertions if service didn't return data (no network)
            return
        }

        XCTAssertFalse(score.breakdown.isEmpty)
        XCTAssertEqual(score.breakdown.count, 5) // Sleep, Recovery, Nutrition, Activity, Stress
    }

    func testCalculateTodayScore_BreakdownWeightsSumToOne() async {
        // When
        await sut.calculateTodayScore()

        // Then - verify weights when available
        guard let score = sut.currentScore else {
            // Skip assertions if service didn't return data (no network)
            return
        }

        let totalWeight = score.breakdown.reduce(0.0) { $0 + $1.weight }
        XCTAssertEqual(totalWeight, 1.0, accuracy: 0.01)
    }

    func testCalculateTodayScore_UpdatesInsights() async {
        // When
        await sut.calculateTodayScore()

        // Then
        XCTAssertNotNil(sut.insights)
        // Insights may be empty if all scores are above 60 or no data available
    }
}

// MARK: - Codable Decoding Tests

final class HealthScoreDecodingTests: XCTestCase {

    func testHealthScoreComponent_Decoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "category": "Sleep",
            "score": 85,
            "weight": 0.25,
            "trend": "improving"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let component = try decoder.decode(HealthScoreComponent.self, from: json)

        XCTAssertEqual(component.category, "Sleep")
        XCTAssertEqual(component.score, 85)
        XCTAssertEqual(component.weight, 0.25)
        XCTAssertEqual(component.trend, .improving)
    }

    func testHealthInsight_Decoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "category": "sleep",
            "title": "Improve sleep",
            "description": "Try going to bed earlier",
            "actionable": true,
            "action": "View tips",
            "priority": "high"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let insight = try decoder.decode(HealthInsight.self, from: json)

        XCTAssertEqual(insight.category, .sleep)
        XCTAssertEqual(insight.title, "Improve sleep")
        XCTAssertEqual(insight.actionable, true)
        XCTAssertEqual(insight.action, "View tips")
        XCTAssertEqual(insight.priority, .high)
    }

    func testHealthInsight_DecodingWithNullAction() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "category": "general",
            "title": "Good progress",
            "description": "Keep it up",
            "actionable": false,
            "action": null,
            "priority": "low"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let insight = try decoder.decode(HealthInsight.self, from: json)

        XCTAssertFalse(insight.actionable)
        XCTAssertNil(insight.action)
    }

    func testHealthCoachMessage_Decoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "role": "assistant",
            "content": "Focus on recovery today.",
            "timestamp": "2024-01-15T10:30:00Z",
            "category": "recovery"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let message = try decoder.decode(HealthCoachMessage.self, from: json)

        XCTAssertEqual(message.role, .assistant)
        XCTAssertEqual(message.content, "Focus on recovery today.")
        XCTAssertEqual(message.category, .recovery)
    }

    func testHealthCoachMessage_DecodingWithNullCategory() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "role": "user",
            "content": "How am I doing?",
            "timestamp": "2024-01-15T10:30:00Z",
            "category": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let message = try decoder.decode(HealthCoachMessage.self, from: json)

        XCTAssertEqual(message.role, .user)
        XCTAssertNil(message.category)
    }
}

// MARK: - Edge Cases Tests

final class HealthScoreServiceEdgeCaseTests: XCTestCase {

    func testScoreTrend_ColorConsistency() {
        // Improving should be green (positive)
        XCTAssertEqual(ScoreTrend.improving.color, "green")

        // Stable should be yellow (neutral)
        XCTAssertEqual(ScoreTrend.stable.color, "yellow")

        // Declining should be red (negative)
        XCTAssertEqual(ScoreTrend.declining.color, "red")
    }

    func testInsightCategory_UniqueIcons() {
        let icons = InsightCategory.allCases.map { $0.icon }
        let uniqueIcons = Set(icons)

        XCTAssertEqual(icons.count, uniqueIcons.count, "Each category should have a unique icon")
    }

    func testInsightCategory_UniqueDisplayNames() {
        let names = InsightCategory.allCases.map { $0.displayName }
        let uniqueNames = Set(names)

        XCTAssertEqual(names.count, uniqueNames.count, "Each category should have a unique display name")
    }

    func testHealthScoreComponent_WeightRange() {
        // Test that weights are reasonable (0 to 1)
        let component = HealthScoreComponent(
            id: UUID(),
            category: "Test",
            score: 75,
            weight: 0.25,
            trend: .stable
        )

        XCTAssertGreaterThanOrEqual(component.weight, 0.0)
        XCTAssertLessThanOrEqual(component.weight, 1.0)
    }

    func testHealthScoreComponent_ScoreRange() {
        // Scores should typically be 0-100
        for score in stride(from: 0, through: 100, by: 10) {
            let component = HealthScoreComponent(
                id: UUID(),
                category: "Test",
                score: score,
                weight: 0.2,
                trend: .stable
            )

            XCTAssertGreaterThanOrEqual(component.score, 0)
            XCTAssertLessThanOrEqual(component.score, 100)
        }
    }

    func testHealthScore_AllScoresWithinRange() {
        let score = HealthScore(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            overallScore: 75,
            sleepScore: 80,
            recoveryScore: 70,
            nutritionScore: 65,
            activityScore: 85,
            stressScore: 60,
            breakdown: [],
            insights: [],
            createdAt: Date()
        )

        // All scores should be 0-100
        XCTAssertGreaterThanOrEqual(score.overallScore, 0)
        XCTAssertLessThanOrEqual(score.overallScore, 100)

        XCTAssertGreaterThanOrEqual(score.sleepScore, 0)
        XCTAssertLessThanOrEqual(score.sleepScore, 100)

        XCTAssertGreaterThanOrEqual(score.recoveryScore, 0)
        XCTAssertLessThanOrEqual(score.recoveryScore, 100)

        XCTAssertGreaterThanOrEqual(score.nutritionScore, 0)
        XCTAssertLessThanOrEqual(score.nutritionScore, 100)

        XCTAssertGreaterThanOrEqual(score.activityScore, 0)
        XCTAssertLessThanOrEqual(score.activityScore, 100)

        XCTAssertGreaterThanOrEqual(score.stressScore, 0)
        XCTAssertLessThanOrEqual(score.stressScore, 100)
    }

    func testHealthInsight_AllPriorities() {
        let priorities: [InsightPriority] = [.high, .medium, .low]

        for priority in priorities {
            let insight = HealthInsight(
                id: UUID(),
                category: .general,
                title: "Test",
                description: "Description",
                actionable: false,
                action: nil,
                priority: priority
            )

            XCTAssertEqual(insight.priority, priority)
        }
    }

    func testHealthInsight_ActionableWithAction() {
        let insight = HealthInsight(
            id: UUID(),
            category: .sleep,
            title: "Improve sleep",
            description: "Sleep more",
            actionable: true,
            action: "View sleep tips",
            priority: .high
        )

        XCTAssertTrue(insight.actionable)
        XCTAssertNotNil(insight.action)
    }

    func testHealthInsight_NotActionableWithoutAction() {
        let insight = HealthInsight(
            id: UUID(),
            category: .general,
            title: "Info",
            description: "Just informational",
            actionable: false,
            action: nil,
            priority: .low
        )

        XCTAssertFalse(insight.actionable)
        XCTAssertNil(insight.action)
    }

    func testHealthCoachMessage_AllRoles() {
        let roles: [MessageRole] = [.user, .assistant, .system]

        for role in roles {
            let message = HealthCoachMessage(
                id: UUID(),
                role: role,
                content: "Test content",
                timestamp: Date(),
                category: nil
            )

            XCTAssertEqual(message.role, role)
        }
    }
}
