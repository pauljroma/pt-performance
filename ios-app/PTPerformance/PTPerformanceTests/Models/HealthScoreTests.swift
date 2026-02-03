//
//  HealthScoreTests.swift
//  PTPerformanceTests
//
//  Unit tests for HealthScore, HealthScoreComponent, ScoreTrend, HealthInsight,
//  InsightCategory, InsightPriority, HealthCoachMessage, and MessageRole models
//

import XCTest
@testable import PTPerformance

final class HealthScoreTests: XCTestCase {

    // MARK: - HealthScore Initialization Tests

    func testHealthScoreInitialization() {
        let id = UUID()
        let patientId = UUID()
        let date = Date()
        let createdAt = Date()
        let component = createHealthScoreComponent()
        let insight = createHealthInsight()

        let score = HealthScore(
            id: id,
            patientId: patientId,
            date: date,
            overallScore: 85,
            sleepScore: 90,
            recoveryScore: 80,
            nutritionScore: 85,
            activityScore: 88,
            stressScore: 75,
            breakdown: [component],
            insights: [insight],
            createdAt: createdAt
        )

        XCTAssertEqual(score.id, id)
        XCTAssertEqual(score.patientId, patientId)
        XCTAssertEqual(score.date, date)
        XCTAssertEqual(score.overallScore, 85)
        XCTAssertEqual(score.sleepScore, 90)
        XCTAssertEqual(score.recoveryScore, 80)
        XCTAssertEqual(score.nutritionScore, 85)
        XCTAssertEqual(score.activityScore, 88)
        XCTAssertEqual(score.stressScore, 75)
        XCTAssertEqual(score.breakdown.count, 1)
        XCTAssertEqual(score.insights.count, 1)
        XCTAssertEqual(score.createdAt, createdAt)
    }

    func testHealthScoreWithEmptyBreakdownAndInsights() {
        let score = HealthScore(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            overallScore: 70,
            sleepScore: 65,
            recoveryScore: 72,
            nutritionScore: 68,
            activityScore: 75,
            stressScore: 70,
            breakdown: [],
            insights: [],
            createdAt: Date()
        )

        XCTAssertTrue(score.breakdown.isEmpty)
        XCTAssertTrue(score.insights.isEmpty)
    }

    // MARK: - HealthScore Codable Tests

    func testHealthScoreEncodeDecode() throws {
        let original = createHealthScore()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(HealthScore.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.patientId, decoded.patientId)
        XCTAssertEqual(original.overallScore, decoded.overallScore)
        XCTAssertEqual(original.sleepScore, decoded.sleepScore)
        XCTAssertEqual(original.recoveryScore, decoded.recoveryScore)
        XCTAssertEqual(original.nutritionScore, decoded.nutritionScore)
        XCTAssertEqual(original.activityScore, decoded.activityScore)
        XCTAssertEqual(original.stressScore, decoded.stressScore)
        XCTAssertEqual(original.breakdown.count, decoded.breakdown.count)
        XCTAssertEqual(original.insights.count, decoded.insights.count)
    }

    func testHealthScoreCodingKeysMapping() throws {
        let score = createHealthScore()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(score)
        let jsonObject = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Verify snake_case keys
        XCTAssertNotNil(jsonObject["patient_id"])
        XCTAssertNotNil(jsonObject["overall_score"])
        XCTAssertNotNil(jsonObject["sleep_score"])
        XCTAssertNotNil(jsonObject["recovery_score"])
        XCTAssertNotNil(jsonObject["nutrition_score"])
        XCTAssertNotNil(jsonObject["activity_score"])
        XCTAssertNotNil(jsonObject["stress_score"])
        XCTAssertNotNil(jsonObject["created_at"])

        // Verify camelCase keys are NOT present
        XCTAssertNil(jsonObject["patientId"])
        XCTAssertNil(jsonObject["overallScore"])
        XCTAssertNil(jsonObject["sleepScore"])
        XCTAssertNil(jsonObject["recoveryScore"])
    }

    // MARK: - HealthScoreComponent Tests

    func testHealthScoreComponentInitialization() {
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

    func testHealthScoreComponentCodable() throws {
        let original = createHealthScoreComponent()

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(HealthScoreComponent.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.category, decoded.category)
        XCTAssertEqual(original.score, decoded.score)
        XCTAssertEqual(original.weight, decoded.weight)
        XCTAssertEqual(original.trend, decoded.trend)
    }

    func testHealthScoreComponentHashable() {
        let component1 = createHealthScoreComponent()
        let component2 = createHealthScoreComponent()

        var set = Set<HealthScoreComponent>()
        set.insert(component1)
        set.insert(component2)

        XCTAssertEqual(set.count, 2)
    }

    // MARK: - ScoreTrend Tests

    func testScoreTrendRawValues() {
        XCTAssertEqual(ScoreTrend.improving.rawValue, "improving")
        XCTAssertEqual(ScoreTrend.stable.rawValue, "stable")
        XCTAssertEqual(ScoreTrend.declining.rawValue, "declining")
    }

    func testScoreTrendIcons() {
        XCTAssertEqual(ScoreTrend.improving.icon, "arrow.up.right")
        XCTAssertEqual(ScoreTrend.stable.icon, "arrow.right")
        XCTAssertEqual(ScoreTrend.declining.icon, "arrow.down.right")
    }

    func testScoreTrendColors() {
        XCTAssertEqual(ScoreTrend.improving.color, "green")
        XCTAssertEqual(ScoreTrend.stable.color, "yellow")
        XCTAssertEqual(ScoreTrend.declining.color, "red")
    }

    func testScoreTrendInitFromRawValue() {
        XCTAssertEqual(ScoreTrend(rawValue: "improving"), .improving)
        XCTAssertEqual(ScoreTrend(rawValue: "stable"), .stable)
        XCTAssertEqual(ScoreTrend(rawValue: "declining"), .declining)
        XCTAssertNil(ScoreTrend(rawValue: "invalid"))
    }

    func testScoreTrendCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let trends: [ScoreTrend] = [.improving, .stable, .declining]
        for trend in trends {
            let data = try encoder.encode(trend)
            let decoded = try decoder.decode(ScoreTrend.self, from: data)
            XCTAssertEqual(decoded, trend)
        }
    }

    // MARK: - HealthInsight Tests

    func testHealthInsightInitialization() {
        let id = UUID()
        let insight = HealthInsight(
            id: id,
            category: .sleep,
            title: "Sleep Quality Improving",
            description: "Your sleep quality has improved by 15% this week",
            actionable: true,
            action: "Keep maintaining your current sleep schedule",
            priority: .high
        )

        XCTAssertEqual(insight.id, id)
        XCTAssertEqual(insight.category, .sleep)
        XCTAssertEqual(insight.title, "Sleep Quality Improving")
        XCTAssertEqual(insight.description, "Your sleep quality has improved by 15% this week")
        XCTAssertTrue(insight.actionable)
        XCTAssertEqual(insight.action, "Keep maintaining your current sleep schedule")
        XCTAssertEqual(insight.priority, .high)
    }

    func testHealthInsightWithNilAction() {
        let insight = HealthInsight(
            id: UUID(),
            category: .general,
            title: "General Observation",
            description: "Your metrics are consistent",
            actionable: false,
            action: nil,
            priority: .low
        )

        XCTAssertFalse(insight.actionable)
        XCTAssertNil(insight.action)
    }

    func testHealthInsightCodable() throws {
        let original = createHealthInsight()

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(HealthInsight.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.category, decoded.category)
        XCTAssertEqual(original.title, decoded.title)
        XCTAssertEqual(original.description, decoded.description)
        XCTAssertEqual(original.actionable, decoded.actionable)
        XCTAssertEqual(original.action, decoded.action)
        XCTAssertEqual(original.priority, decoded.priority)
    }

    func testHealthInsightHashable() {
        let insight1 = createHealthInsight()
        let insight2 = createHealthInsight()

        var set = Set<HealthInsight>()
        set.insert(insight1)
        set.insert(insight2)

        XCTAssertEqual(set.count, 2)
    }

    // MARK: - InsightCategory Tests

    func testInsightCategoryAllCases() {
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

    func testInsightCategoryRawValues() {
        XCTAssertEqual(InsightCategory.sleep.rawValue, "sleep")
        XCTAssertEqual(InsightCategory.recovery.rawValue, "recovery")
        XCTAssertEqual(InsightCategory.nutrition.rawValue, "nutrition")
        XCTAssertEqual(InsightCategory.training.rawValue, "training")
        XCTAssertEqual(InsightCategory.stress.rawValue, "stress")
        XCTAssertEqual(InsightCategory.supplements.rawValue, "supplements")
        XCTAssertEqual(InsightCategory.labs.rawValue, "labs")
        XCTAssertEqual(InsightCategory.general.rawValue, "general")
    }

    func testInsightCategoryDisplayNames() {
        XCTAssertEqual(InsightCategory.sleep.displayName, "Sleep")
        XCTAssertEqual(InsightCategory.recovery.displayName, "Recovery")
        XCTAssertEqual(InsightCategory.nutrition.displayName, "Nutrition")
        XCTAssertEqual(InsightCategory.training.displayName, "Training")
        XCTAssertEqual(InsightCategory.stress.displayName, "Stress")
        XCTAssertEqual(InsightCategory.supplements.displayName, "Supplements")
        XCTAssertEqual(InsightCategory.labs.displayName, "Lab Results")
        XCTAssertEqual(InsightCategory.general.displayName, "General")
    }

    func testInsightCategoryDisplayNamesNotEmpty() {
        for category in InsightCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty)
            XCTAssertTrue(category.displayName.first?.isUppercase == true,
                          "Display name should start with uppercase: \(category.displayName)")
        }
    }

    func testInsightCategoryIcons() {
        XCTAssertEqual(InsightCategory.sleep.icon, "moon.fill")
        XCTAssertEqual(InsightCategory.recovery.icon, "heart.fill")
        XCTAssertEqual(InsightCategory.nutrition.icon, "leaf.fill")
        XCTAssertEqual(InsightCategory.training.icon, "figure.run")
        XCTAssertEqual(InsightCategory.stress.icon, "brain.head.profile")
        XCTAssertEqual(InsightCategory.supplements.icon, "pill.fill")
        XCTAssertEqual(InsightCategory.labs.icon, "cross.case.fill")
        XCTAssertEqual(InsightCategory.general.icon, "lightbulb.fill")
    }

    func testInsightCategoryIconsNotEmpty() {
        for category in InsightCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty)
        }
    }

    func testInsightCategoryInitFromRawValue() {
        XCTAssertEqual(InsightCategory(rawValue: "sleep"), .sleep)
        XCTAssertEqual(InsightCategory(rawValue: "training"), .training)
        XCTAssertEqual(InsightCategory(rawValue: "labs"), .labs)
        XCTAssertNil(InsightCategory(rawValue: "invalid"))
        XCTAssertNil(InsightCategory(rawValue: ""))
    }

    func testInsightCategoryCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for category in InsightCategory.allCases {
            let data = try encoder.encode(category)
            let decoded = try decoder.decode(InsightCategory.self, from: data)
            XCTAssertEqual(decoded, category)
        }
    }

    // MARK: - InsightPriority Tests

    func testInsightPriorityRawValues() {
        XCTAssertEqual(InsightPriority.high.rawValue, "high")
        XCTAssertEqual(InsightPriority.medium.rawValue, "medium")
        XCTAssertEqual(InsightPriority.low.rawValue, "low")
    }

    func testInsightPriorityInitFromRawValue() {
        XCTAssertEqual(InsightPriority(rawValue: "high"), .high)
        XCTAssertEqual(InsightPriority(rawValue: "medium"), .medium)
        XCTAssertEqual(InsightPriority(rawValue: "low"), .low)
        XCTAssertNil(InsightPriority(rawValue: "invalid"))
    }

    func testInsightPriorityCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let priorities: [InsightPriority] = [.high, .medium, .low]
        for priority in priorities {
            let data = try encoder.encode(priority)
            let decoded = try decoder.decode(InsightPriority.self, from: data)
            XCTAssertEqual(decoded, priority)
        }
    }

    // MARK: - HealthCoachMessage Tests

    func testHealthCoachMessageInitialization() {
        let id = UUID()
        let timestamp = Date()

        let message = HealthCoachMessage(
            id: id,
            role: .assistant,
            content: "Based on your recent data, I recommend increasing your sleep duration.",
            timestamp: timestamp,
            category: .sleep
        )

        XCTAssertEqual(message.id, id)
        XCTAssertEqual(message.role, .assistant)
        XCTAssertEqual(message.content, "Based on your recent data, I recommend increasing your sleep duration.")
        XCTAssertEqual(message.timestamp, timestamp)
        XCTAssertEqual(message.category, .sleep)
    }

    func testHealthCoachMessageWithNilCategory() {
        let message = HealthCoachMessage(
            id: UUID(),
            role: .user,
            content: "How am I doing?",
            timestamp: Date(),
            category: nil
        )

        XCTAssertEqual(message.role, .user)
        XCTAssertNil(message.category)
    }

    func testHealthCoachMessageCodable() throws {
        let original = HealthCoachMessage(
            id: UUID(),
            role: .assistant,
            content: "Test message",
            timestamp: Date(),
            category: .training
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(HealthCoachMessage.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.role, decoded.role)
        XCTAssertEqual(original.content, decoded.content)
        XCTAssertEqual(original.category, decoded.category)
    }

    // MARK: - MessageRole Tests

    func testMessageRoleRawValues() {
        XCTAssertEqual(MessageRole.user.rawValue, "user")
        XCTAssertEqual(MessageRole.assistant.rawValue, "assistant")
        XCTAssertEqual(MessageRole.system.rawValue, "system")
    }

    func testMessageRoleInitFromRawValue() {
        XCTAssertEqual(MessageRole(rawValue: "user"), .user)
        XCTAssertEqual(MessageRole(rawValue: "assistant"), .assistant)
        XCTAssertEqual(MessageRole(rawValue: "system"), .system)
        XCTAssertNil(MessageRole(rawValue: "invalid"))
    }

    func testMessageRoleCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let roles: [MessageRole] = [.user, .assistant, .system]
        for role in roles {
            let data = try encoder.encode(role)
            let decoded = try decoder.decode(MessageRole.self, from: data)
            XCTAssertEqual(decoded, role)
        }
    }

    // MARK: - Helpers

    private func createHealthScoreComponent() -> HealthScoreComponent {
        HealthScoreComponent(
            id: UUID(),
            category: "Sleep",
            score: 85,
            weight: 0.25,
            trend: .improving
        )
    }

    private func createHealthInsight() -> HealthInsight {
        HealthInsight(
            id: UUID(),
            category: .sleep,
            title: "Sleep Quality Improving",
            description: "Your sleep quality has improved by 15% this week",
            actionable: true,
            action: "Keep maintaining your current sleep schedule",
            priority: .high
        )
    }

    private func createHealthScore() -> HealthScore {
        HealthScore(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            overallScore: 85,
            sleepScore: 90,
            recoveryScore: 80,
            nutritionScore: 85,
            activityScore: 88,
            stressScore: 75,
            breakdown: [createHealthScoreComponent()],
            insights: [createHealthInsight()],
            createdAt: Date()
        )
    }
}
