//
//  HealthIntelligenceServiceTests.swift
//  PTPerformanceTests
//
//  Unit tests for Health Intelligence services
//  Tests AICoachService, FastingService, RecoveryService, and SupplementService
//

import XCTest
@testable import PTPerformance

// MARK: - AICoachService Tests

@MainActor
final class AICoachServiceTests: XCTestCase {

    var sut: AICoachService!

    override func setUp() async throws {
        try await super.setUp()
        sut = AICoachService.shared
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Singleton Tests

    func testSharedInstanceExists() {
        XCTAssertNotNil(AICoachService.shared)
    }

    func testSharedInstanceIsSingleton() {
        let instance1 = AICoachService.shared
        let instance2 = AICoachService.shared
        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - Initial State Tests

    func testInitialState_CurrentResponseIsNil() {
        XCTAssertNil(sut.currentResponse)
    }

    func testInitialState_ProactiveInsightsIsEmpty() {
        XCTAssertTrue(sut.proactiveInsights.isEmpty)
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading)
    }

    func testInitialState_ErrorIsNil() {
        XCTAssertNil(sut.error)
    }

    // MARK: - Published Properties

    func testPublishedProperties_Exist() {
        _ = sut.currentResponse
        _ = sut.proactiveInsights
        _ = sut.isLoading
        _ = sut.error
    }
}

// MARK: - AICoachError Tests

final class AICoachErrorTests: XCTestCase {

    func testAICoachError_NoPatientId_Description() {
        let error = AICoachError.noPatientId
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("patient") == true)
    }

    func testAICoachError_InvalidResponse_Description() {
        let error = AICoachError.invalidResponse
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("invalid") == true)
    }

    func testAICoachError_NetworkError_Description() {
        let underlyingError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Connection failed"])
        let error = AICoachError.networkError(underlyingError)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("Network") == true)
    }
}

// MARK: - UnifiedCoachResponse Tests

final class UnifiedCoachResponseTests: XCTestCase {

    func testUnifiedCoachResponse_Decoding() throws {
        let json = """
        {
            "coaching_id": "coach-123",
            "greeting": "Good morning!",
            "primary_message": "Your recovery looks good today.",
            "insights": [],
            "today_focus": "Focus on mobility work",
            "weekly_priorities": ["Increase sleep", "Add recovery sessions"],
            "data_summary": {
                "readiness": "High",
                "training": "On track",
                "recovery": "Adequate",
                "labs": "No recent data"
            },
            "proactive_alerts": ["Your HRV is declining"],
            "follow_up_questions": ["How did you sleep?", "Any soreness?"],
            "disclaimer": "Not medical advice"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(UnifiedCoachResponse.self, from: json)

        XCTAssertEqual(response.coachingId, "coach-123")
        XCTAssertEqual(response.greeting, "Good morning!")
        XCTAssertEqual(response.primaryMessage, "Your recovery looks good today.")
        XCTAssertEqual(response.todayFocus, "Focus on mobility work")
        XCTAssertEqual(response.weeklyPriorities.count, 2)
        XCTAssertEqual(response.proactiveAlerts.count, 1)
        XCTAssertEqual(response.followUpQuestions.count, 2)
    }

    func testUnifiedCoachResponse_WithInsights() throws {
        let json = """
        {
            "coaching_id": "coach-456",
            "greeting": "Hello",
            "primary_message": "Here are your insights",
            "insights": [
                {
                    "category": "recovery",
                    "priority": "high",
                    "insight": "Your HRV improved",
                    "action": "Continue current routine",
                    "rationale": "Data shows consistent improvement"
                }
            ],
            "today_focus": "Rest",
            "weekly_priorities": [],
            "data_summary": {
                "readiness": "High",
                "training": "Light",
                "recovery": "Good",
                "labs": "N/A"
            },
            "proactive_alerts": [],
            "follow_up_questions": [],
            "disclaimer": "Disclaimer"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(UnifiedCoachResponse.self, from: json)

        XCTAssertEqual(response.insights.count, 1)
        XCTAssertEqual(response.insights.first?.category, .recovery)
        XCTAssertEqual(response.insights.first?.priority, .high)
    }
}

// MARK: - CoachingInsight Tests

final class CoachingInsightTests: XCTestCase {

    func testCoachingInsight_Decoding() throws {
        let json = """
        {
            "category": "training",
            "priority": "medium",
            "insight": "You've been training hard",
            "action": "Consider a deload",
            "rationale": "Volume has been high for 3 weeks"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let insight = try decoder.decode(CoachingInsight.self, from: json)

        XCTAssertEqual(insight.category, .training)
        XCTAssertEqual(insight.priority, .medium)
        XCTAssertEqual(insight.insight, "You've been training hard")
        XCTAssertEqual(insight.action, "Consider a deload")
    }

    func testCoachingInsight_Identifiable() throws {
        let json = """
        {
            "category": "sleep",
            "priority": "high",
            "insight": "Sleep has declined",
            "action": "Improve sleep hygiene",
            "rationale": "Average sleep dropped by 1 hour"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let insight = try decoder.decode(CoachingInsight.self, from: json)

        // ID should be composed of category and insight prefix
        XCTAssertTrue(insight.id.contains("sleep"))
    }

    func testCoachingInsight_Hashable() throws {
        let json1 = """
        {
            "category": "nutrition",
            "priority": "low",
            "insight": "Protein intake is adequate",
            "action": "Maintain current diet",
            "rationale": "Meeting daily targets"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let insight1 = try decoder.decode(CoachingInsight.self, from: json1)
        let insight2 = try decoder.decode(CoachingInsight.self, from: json1)

        XCTAssertEqual(insight1, insight2)
    }
}

// MARK: - CoachingCategory Tests

final class CoachingCategoryTests: XCTestCase {

    func testCoachingCategory_RawValues() {
        XCTAssertEqual(CoachingCategory.training.rawValue, "training")
        XCTAssertEqual(CoachingCategory.recovery.rawValue, "recovery")
        XCTAssertEqual(CoachingCategory.nutrition.rawValue, "nutrition")
        XCTAssertEqual(CoachingCategory.sleep.rawValue, "sleep")
        XCTAssertEqual(CoachingCategory.labs.rawValue, "labs")
        XCTAssertEqual(CoachingCategory.general.rawValue, "general")
    }

    func testCoachingCategory_DisplayNames() {
        XCTAssertEqual(CoachingCategory.training.displayName, "Training")
        XCTAssertEqual(CoachingCategory.recovery.displayName, "Recovery")
        XCTAssertEqual(CoachingCategory.nutrition.displayName, "Nutrition")
        XCTAssertEqual(CoachingCategory.sleep.displayName, "Sleep")
        XCTAssertEqual(CoachingCategory.labs.displayName, "Labs")
        XCTAssertEqual(CoachingCategory.general.displayName, "General")
    }

    func testCoachingCategory_Icons() {
        for category in CoachingCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty)
        }
    }

    func testCoachingCategory_Colors() {
        for category in CoachingCategory.allCases {
            XCTAssertFalse(category.color.isEmpty)
        }
    }
}

// MARK: - CoachingPriority Tests

final class CoachingPriorityTests: XCTestCase {

    func testCoachingPriority_RawValues() {
        XCTAssertEqual(CoachingPriority.high.rawValue, "high")
        XCTAssertEqual(CoachingPriority.medium.rawValue, "medium")
        XCTAssertEqual(CoachingPriority.low.rawValue, "low")
    }

    func testCoachingPriority_SortOrder() {
        XCTAssertEqual(CoachingPriority.high.sortOrder, 0)
        XCTAssertEqual(CoachingPriority.medium.sortOrder, 1)
        XCTAssertEqual(CoachingPriority.low.sortOrder, 2)
    }

    func testCoachingPriority_Sorting() {
        let priorities: [CoachingPriority] = [.low, .high, .medium]
        let sorted = priorities.sorted { $0.sortOrder < $1.sortOrder }

        XCTAssertEqual(sorted, [.high, .medium, .low])
    }
}

// MARK: - DataSummary Tests

final class DataSummaryTests: XCTestCase {

    func testDataSummary_Decoding() throws {
        let json = """
        {
            "readiness": "High - 85/100",
            "training": "3 sessions this week",
            "recovery": "2 sauna sessions",
            "labs": "Last test: 2 weeks ago"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let summary = try decoder.decode(DataSummary.self, from: json)

        XCTAssertEqual(summary.readiness, "High - 85/100")
        XCTAssertEqual(summary.training, "3 sessions this week")
        XCTAssertEqual(summary.recovery, "2 sauna sessions")
        XCTAssertEqual(summary.labs, "Last test: 2 weeks ago")
    }

    func testDataSummary_Hashable() throws {
        let summary1 = DataSummary(
            readiness: "High",
            training: "Good",
            recovery: "Adequate",
            labs: "N/A"
        )
        let summary2 = DataSummary(
            readiness: "High",
            training: "Good",
            recovery: "Adequate",
            labs: "N/A"
        )

        XCTAssertEqual(summary1, summary2)
    }
}

// MARK: - AICoachMessage Tests

final class AICoachMessageTests: XCTestCase {

    func testAICoachMessage_UserMessage() {
        let message = AICoachMessage(
            role: .user,
            content: "How is my recovery?"
        )

        XCTAssertNotNil(message.id)
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content, "How is my recovery?")
        XCTAssertNotNil(message.timestamp)
        XCTAssertNil(message.insights)
        XCTAssertNil(message.suggestedQuestions)
    }

    func testAICoachMessage_CoachMessage() {
        let insights = [
            CoachingInsight(
                category: .recovery,
                priority: .high,
                insight: "Test insight",
                action: "Take action",
                rationale: "Because"
            )
        ]

        let message = AICoachMessage(
            role: .coach,
            content: "Your recovery is excellent!",
            insights: insights,
            suggestedQuestions: ["What should I do next?"]
        )

        XCTAssertEqual(message.role, .coach)
        XCTAssertEqual(message.insights?.count, 1)
        XCTAssertEqual(message.suggestedQuestions?.count, 1)
    }

    func testAICoachMessage_SystemMessage() {
        let message = AICoachMessage(
            role: .system,
            content: "Session started"
        )

        XCTAssertEqual(message.role, .system)
    }

    func testAICoachMessage_Equatable() {
        let id = UUID()
        let message1 = AICoachMessage(
            id: id,
            role: .user,
            content: "Test"
        )
        let message2 = AICoachMessage(
            id: id,
            role: .user,
            content: "Different content"
        )

        // Equality based on ID only
        XCTAssertEqual(message1, message2)
    }
}

// MARK: - AICoachMessageRole Tests

final class AICoachMessageRoleTests: XCTestCase {

    func testAICoachMessageRole_RawValues() {
        XCTAssertEqual(AICoachMessageRole.user.rawValue, "user")
        XCTAssertEqual(AICoachMessageRole.coach.rawValue, "coach")
        XCTAssertEqual(AICoachMessageRole.system.rawValue, "system")
    }

    func testAICoachMessageRole_Codable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for role in [AICoachMessageRole.user, .coach, .system] {
            let data = try encoder.encode(role)
            let decoded = try decoder.decode(AICoachMessageRole.self, from: data)
            XCTAssertEqual(decoded, role)
        }
    }
}
