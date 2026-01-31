//
//  AIWorkoutRecommendationServiceTests.swift
//  PTPerformanceTests
//
//  Build 358 - Unit tests for AIWorkoutRecommendationService
//  Tests response model decoding, display model computed properties, and error handling
//

import XCTest
@testable import PTPerformance

// MARK: - Response Model Decoding Tests

final class WorkoutRecommendationResponseDecodingTests: XCTestCase {

    // MARK: - WorkoutRecommendationResponse Tests

    func testWorkoutRecommendationResponseDecoding_FullResponse() throws {
        let json = """
        {
            "recommendation_id": "rec-123-abc",
            "recommendations": [
                {
                    "template_id": "550e8400-e29b-41d4-a716-446655440000",
                    "template_name": "Full Body Strength",
                    "match_score": 92,
                    "reasoning": "Great match for your goals",
                    "category": "strength",
                    "duration_minutes": 45,
                    "difficulty": "intermediate"
                }
            ],
            "reasoning": "Based on your readiness and recent activity",
            "context_summary": {
                "readiness_band": "green",
                "readiness_score": 85.5,
                "recent_workout_count": 3,
                "active_goals": ["Build strength", "Improve endurance"]
            },
            "cached": false
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(WorkoutRecommendationResponse.self, from: json)

        XCTAssertEqual(response.recommendationId, "rec-123-abc")
        XCTAssertEqual(response.recommendations.count, 1)
        XCTAssertEqual(response.reasoning, "Based on your readiness and recent activity")
        XCTAssertEqual(response.cached, false)
        XCTAssertEqual(response.contextSummary.readinessBand, "green")
        XCTAssertEqual(response.contextSummary.readinessScore, 85.5)
        XCTAssertEqual(response.contextSummary.recentWorkoutCount, 3)
        XCTAssertEqual(response.contextSummary.activeGoals.count, 2)
    }

    func testWorkoutRecommendationResponseDecoding_WithoutCached() throws {
        let json = """
        {
            "recommendation_id": "rec-456",
            "recommendations": [],
            "reasoning": "No matching workouts found",
            "context_summary": {
                "recent_workout_count": 0,
                "active_goals": []
            }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(WorkoutRecommendationResponse.self, from: json)

        XCTAssertEqual(response.recommendationId, "rec-456")
        XCTAssertEqual(response.recommendations.count, 0)
        XCTAssertNil(response.cached, "Cached should be nil when not provided")
    }

    func testWorkoutRecommendationResponseDecoding_MultipleRecommendations() throws {
        let json = """
        {
            "recommendation_id": "rec-multi",
            "recommendations": [
                {
                    "template_id": "550e8400-e29b-41d4-a716-446655440001",
                    "template_name": "Morning Cardio",
                    "match_score": 95,
                    "reasoning": "Perfect for your morning routine"
                },
                {
                    "template_id": "550e8400-e29b-41d4-a716-446655440002",
                    "template_name": "HIIT Session",
                    "match_score": 88,
                    "reasoning": "Good intensity match"
                },
                {
                    "template_id": "550e8400-e29b-41d4-a716-446655440003",
                    "template_name": "Recovery Yoga",
                    "match_score": 72,
                    "reasoning": "Alternative for lower intensity"
                }
            ],
            "reasoning": "Three options based on your preferences",
            "context_summary": {
                "recent_workout_count": 5,
                "active_goals": ["Weight loss"]
            }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(WorkoutRecommendationResponse.self, from: json)

        XCTAssertEqual(response.recommendations.count, 3)
        XCTAssertEqual(response.recommendations[0].matchScore, 95)
        XCTAssertEqual(response.recommendations[1].matchScore, 88)
        XCTAssertEqual(response.recommendations[2].matchScore, 72)
    }

    // MARK: - WorkoutRecommendationItem Tests

    func testWorkoutRecommendationItemDecoding_AllFields() throws {
        let json = """
        {
            "template_id": "550e8400-e29b-41d4-a716-446655440000",
            "template_name": "Power Lifting Session",
            "match_score": 87,
            "reasoning": "Matches your strength goals",
            "category": "strength",
            "duration_minutes": 60,
            "difficulty": "advanced"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let item = try decoder.decode(WorkoutRecommendationItem.self, from: json)

        XCTAssertEqual(item.templateId, "550e8400-e29b-41d4-a716-446655440000")
        XCTAssertEqual(item.templateName, "Power Lifting Session")
        XCTAssertEqual(item.matchScore, 87)
        XCTAssertEqual(item.reasoning, "Matches your strength goals")
        XCTAssertEqual(item.category, "strength")
        XCTAssertEqual(item.durationMinutes, 60)
        XCTAssertEqual(item.difficulty, "advanced")
    }

    func testWorkoutRecommendationItemDecoding_RequiredFieldsOnly() throws {
        let json = """
        {
            "template_id": "550e8400-e29b-41d4-a716-446655440000",
            "template_name": "Quick Workout",
            "match_score": 75,
            "reasoning": "Basic recommendation"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let item = try decoder.decode(WorkoutRecommendationItem.self, from: json)

        XCTAssertEqual(item.templateId, "550e8400-e29b-41d4-a716-446655440000")
        XCTAssertEqual(item.templateName, "Quick Workout")
        XCTAssertEqual(item.matchScore, 75)
        XCTAssertNil(item.category)
        XCTAssertNil(item.durationMinutes)
        XCTAssertNil(item.difficulty)
    }

    func testWorkoutRecommendationItemDecoding_VariousDifficulties() throws {
        let difficulties = ["beginner", "intermediate", "advanced", "expert"]

        for difficulty in difficulties {
            let json = """
            {
                "template_id": "550e8400-e29b-41d4-a716-446655440000",
                "template_name": "Test Workout",
                "match_score": 80,
                "reasoning": "Test",
                "difficulty": "\(difficulty)"
            }
            """.data(using: .utf8)!

            let decoder = JSONDecoder()
            let item = try decoder.decode(WorkoutRecommendationItem.self, from: json)

            XCTAssertEqual(item.difficulty, difficulty)
        }
    }

    // MARK: - WorkoutRecommendationContextSummary Tests

    func testContextSummaryDecoding_AllFields() throws {
        let json = """
        {
            "readiness_band": "yellow",
            "readiness_score": 72.5,
            "recent_workout_count": 4,
            "active_goals": ["Muscle gain", "Flexibility", "Cardio endurance"]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let summary = try decoder.decode(WorkoutRecommendationContextSummary.self, from: json)

        XCTAssertEqual(summary.readinessBand, "yellow")
        XCTAssertEqual(summary.readinessScore, 72.5)
        XCTAssertEqual(summary.recentWorkoutCount, 4)
        XCTAssertEqual(summary.activeGoals.count, 3)
        XCTAssertTrue(summary.activeGoals.contains("Muscle gain"))
    }

    func testContextSummaryDecoding_NilReadiness() throws {
        let json = """
        {
            "recent_workout_count": 0,
            "active_goals": []
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let summary = try decoder.decode(WorkoutRecommendationContextSummary.self, from: json)

        XCTAssertNil(summary.readinessBand)
        XCTAssertNil(summary.readinessScore)
        XCTAssertEqual(summary.recentWorkoutCount, 0)
        XCTAssertEqual(summary.activeGoals.count, 0)
    }

    func testContextSummaryDecoding_AllReadinessBands() throws {
        let bands = ["green", "yellow", "orange", "red"]

        for band in bands {
            let json = """
            {
                "readiness_band": "\(band)",
                "recent_workout_count": 2,
                "active_goals": []
            }
            """.data(using: .utf8)!

            let decoder = JSONDecoder()
            let summary = try decoder.decode(WorkoutRecommendationContextSummary.self, from: json)

            XCTAssertEqual(summary.readinessBand, band)
        }
    }
}

// MARK: - Error Response Decoding Tests

final class WorkoutRecommendationErrorResponseTests: XCTestCase {

    func testErrorResponseDecoding_WithError() throws {
        let json = """
        {
            "error": "No workout templates available for patient",
            "recommendation_id": "rec-error-123",
            "recommendations": [],
            "reasoning": "Unable to generate recommendations due to missing templates",
            "context_summary": {
                "readiness_band": "green",
                "readiness_score": 90.0,
                "recent_workout_count": 2,
                "active_goals": ["Strength training"]
            }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(WorkoutRecommendationErrorResponse.self, from: json)

        XCTAssertEqual(response.error, "No workout templates available for patient")
        XCTAssertEqual(response.recommendationId, "rec-error-123")
        XCTAssertEqual(response.recommendations?.count, 0)
        XCTAssertNotNil(response.reasoning)
        XCTAssertNotNil(response.contextSummary)
    }

    func testErrorResponseDecoding_MinimalError() throws {
        let json = """
        {
            "error": "Internal server error"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(WorkoutRecommendationErrorResponse.self, from: json)

        XCTAssertEqual(response.error, "Internal server error")
        XCTAssertNil(response.recommendationId)
        XCTAssertNil(response.recommendations)
        XCTAssertNil(response.reasoning)
        XCTAssertNil(response.contextSummary)
    }

    func testErrorResponseDecoding_NullError() throws {
        let json = """
        {
            "error": null,
            "recommendation_id": "rec-valid",
            "recommendations": []
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(WorkoutRecommendationErrorResponse.self, from: json)

        XCTAssertNil(response.error, "Null error should decode as nil")
    }

    func testErrorResponseDecoding_PatientNotFound() throws {
        let json = """
        {
            "error": "Patient not found or no access",
            "reasoning": "The specified patient ID does not exist or you don't have access"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(WorkoutRecommendationErrorResponse.self, from: json)

        XCTAssertEqual(response.error, "Patient not found or no access")
        XCTAssertNotNil(response.reasoning)
    }
}

// MARK: - AIWorkoutRecommendation Display Model Tests

final class AIWorkoutRecommendationDisplayModelTests: XCTestCase {

    // MARK: - matchScoreColor Tests

    func testMatchScoreColor_Green_HighScore() {
        let item = createMockRecommendationItem(matchScore: 95)
        let recommendation = AIWorkoutRecommendation(from: item)

        XCTAssertEqual(recommendation.matchScoreColor, "green", "Score 95 should be green")
    }

    func testMatchScoreColor_Green_ExactlyAt80() {
        let item = createMockRecommendationItem(matchScore: 80)
        let recommendation = AIWorkoutRecommendation(from: item)

        XCTAssertEqual(recommendation.matchScoreColor, "green", "Score 80 should be green")
    }

    func testMatchScoreColor_Green_At100() {
        let item = createMockRecommendationItem(matchScore: 100)
        let recommendation = AIWorkoutRecommendation(from: item)

        XCTAssertEqual(recommendation.matchScoreColor, "green", "Score 100 should be green")
    }

    func testMatchScoreColor_Orange_UpperBound() {
        let item = createMockRecommendationItem(matchScore: 79)
        let recommendation = AIWorkoutRecommendation(from: item)

        XCTAssertEqual(recommendation.matchScoreColor, "orange", "Score 79 should be orange")
    }

    func testMatchScoreColor_Orange_ExactlyAt60() {
        let item = createMockRecommendationItem(matchScore: 60)
        let recommendation = AIWorkoutRecommendation(from: item)

        XCTAssertEqual(recommendation.matchScoreColor, "orange", "Score 60 should be orange")
    }

    func testMatchScoreColor_Orange_MidRange() {
        let item = createMockRecommendationItem(matchScore: 70)
        let recommendation = AIWorkoutRecommendation(from: item)

        XCTAssertEqual(recommendation.matchScoreColor, "orange", "Score 70 should be orange")
    }

    func testMatchScoreColor_Gray_UpperBound() {
        let item = createMockRecommendationItem(matchScore: 59)
        let recommendation = AIWorkoutRecommendation(from: item)

        XCTAssertEqual(recommendation.matchScoreColor, "gray", "Score 59 should be gray")
    }

    func testMatchScoreColor_Gray_LowScore() {
        let item = createMockRecommendationItem(matchScore: 30)
        let recommendation = AIWorkoutRecommendation(from: item)

        XCTAssertEqual(recommendation.matchScoreColor, "gray", "Score 30 should be gray")
    }

    func testMatchScoreColor_Gray_ZeroScore() {
        let item = createMockRecommendationItem(matchScore: 0)
        let recommendation = AIWorkoutRecommendation(from: item)

        XCTAssertEqual(recommendation.matchScoreColor, "gray", "Score 0 should be gray")
    }

    // MARK: - durationText Tests

    func testDurationText_WithValue() {
        let item = createMockRecommendationItem(durationMinutes: 45)
        let recommendation = AIWorkoutRecommendation(from: item)

        XCTAssertEqual(recommendation.durationText, "45 min")
    }

    func testDurationText_ShortDuration() {
        let item = createMockRecommendationItem(durationMinutes: 15)
        let recommendation = AIWorkoutRecommendation(from: item)

        XCTAssertEqual(recommendation.durationText, "15 min")
    }

    func testDurationText_LongDuration() {
        let item = createMockRecommendationItem(durationMinutes: 120)
        let recommendation = AIWorkoutRecommendation(from: item)

        XCTAssertEqual(recommendation.durationText, "120 min")
    }

    func testDurationText_NilDuration() {
        let item = createMockRecommendationItem(durationMinutes: nil)
        let recommendation = AIWorkoutRecommendation(from: item)

        XCTAssertEqual(recommendation.durationText, "", "Nil duration should return empty string")
    }

    // MARK: - categoryText Tests

    func testCategoryText_Strength() {
        let item = createMockRecommendationItem(category: "strength")
        let recommendation = AIWorkoutRecommendation(from: item)

        XCTAssertEqual(recommendation.categoryText, "Strength")
    }

    func testCategoryText_Cardio() {
        let item = createMockRecommendationItem(category: "cardio")
        let recommendation = AIWorkoutRecommendation(from: item)

        XCTAssertEqual(recommendation.categoryText, "Cardio")
    }

    func testCategoryText_Flexibility() {
        let item = createMockRecommendationItem(category: "flexibility")
        let recommendation = AIWorkoutRecommendation(from: item)

        XCTAssertEqual(recommendation.categoryText, "Flexibility")
    }

    func testCategoryText_MultiWord() {
        let item = createMockRecommendationItem(category: "high intensity")
        let recommendation = AIWorkoutRecommendation(from: item)

        XCTAssertEqual(recommendation.categoryText, "High Intensity")
    }

    func testCategoryText_NilCategory() {
        let item = createMockRecommendationItem(category: nil)
        let recommendation = AIWorkoutRecommendation(from: item)

        XCTAssertEqual(recommendation.categoryText, "General", "Nil category should return 'General'")
    }

    // MARK: - difficultyText Tests

    func testDifficultyText_Beginner() {
        let item = createMockRecommendationItem(difficulty: "beginner")
        let recommendation = AIWorkoutRecommendation(from: item)

        XCTAssertEqual(recommendation.difficultyText, "Beginner")
    }

    func testDifficultyText_Intermediate() {
        let item = createMockRecommendationItem(difficulty: "intermediate")
        let recommendation = AIWorkoutRecommendation(from: item)

        XCTAssertEqual(recommendation.difficultyText, "Intermediate")
    }

    func testDifficultyText_Advanced() {
        let item = createMockRecommendationItem(difficulty: "advanced")
        let recommendation = AIWorkoutRecommendation(from: item)

        XCTAssertEqual(recommendation.difficultyText, "Advanced")
    }

    func testDifficultyText_NilDifficulty() {
        let item = createMockRecommendationItem(difficulty: nil)
        let recommendation = AIWorkoutRecommendation(from: item)

        XCTAssertEqual(recommendation.difficultyText, "Moderate", "Nil difficulty should return 'Moderate'")
    }

    // MARK: - Initialization Tests

    func testAIWorkoutRecommendation_Identifiable() {
        let item = createMockRecommendationItem()
        let recommendation = AIWorkoutRecommendation(from: item)

        XCTAssertNotNil(recommendation.id, "Recommendation should have a unique ID")
    }

    func testAIWorkoutRecommendation_TemplateIdConversion() {
        let validUUID = "550e8400-e29b-41d4-a716-446655440000"
        let item = WorkoutRecommendationItem(
            templateId: validUUID,
            templateName: "Test",
            matchScore: 80,
            reasoning: "Test",
            category: nil,
            durationMinutes: nil,
            difficulty: nil
        )
        let recommendation = AIWorkoutRecommendation(from: item)

        XCTAssertEqual(recommendation.templateId.uuidString.lowercased(), validUUID.lowercased())
    }

    func testAIWorkoutRecommendation_InvalidTemplateId() {
        let item = WorkoutRecommendationItem(
            templateId: "invalid-uuid",
            templateName: "Test",
            matchScore: 80,
            reasoning: "Test",
            category: nil,
            durationMinutes: nil,
            difficulty: nil
        )
        let recommendation = AIWorkoutRecommendation(from: item)

        // Should still have a valid UUID (fallback to new UUID)
        XCTAssertNotNil(recommendation.templateId)
    }

    func testAIWorkoutRecommendation_Equatable() {
        let item1 = createMockRecommendationItem()
        let item2 = createMockRecommendationItem()

        let rec1 = AIWorkoutRecommendation(from: item1)
        let rec2 = AIWorkoutRecommendation(from: item2)

        // Different instances should not be equal (different IDs)
        XCTAssertNotEqual(rec1, rec2, "Different recommendations should not be equal")

        // Same instance should be equal to itself
        XCTAssertEqual(rec1, rec1, "Recommendation should equal itself")
    }

    // MARK: - Helper Functions

    private func createMockRecommendationItem(
        matchScore: Int = 85,
        category: String? = "strength",
        durationMinutes: Int? = 45,
        difficulty: String? = "intermediate"
    ) -> WorkoutRecommendationItem {
        WorkoutRecommendationItem(
            templateId: UUID().uuidString,
            templateName: "Mock Workout",
            matchScore: matchScore,
            reasoning: "Mock reasoning",
            category: category,
            durationMinutes: durationMinutes,
            difficulty: difficulty
        )
    }
}

// MARK: - RecommendationContext Tests

final class RecommendationContextTests: XCTestCase {

    func testRecommendationContext_InitFromResponse_AllFields() {
        let contextSummary = WorkoutRecommendationContextSummary(
            readinessBand: "green",
            readinessScore: 88.5,
            recentWorkoutCount: 5,
            activeGoals: ["Build muscle", "Improve cardio"]
        )

        let context = RecommendationContext(from: contextSummary)

        XCTAssertEqual(context.readinessBand, .green)
        XCTAssertEqual(context.readinessScore, 88.5)
        XCTAssertEqual(context.recentWorkoutCount, 5)
        XCTAssertEqual(context.activeGoals.count, 2)
        XCTAssertTrue(context.activeGoals.contains("Build muscle"))
    }

    func testRecommendationContext_InitFromResponse_GreenBand() {
        let contextSummary = WorkoutRecommendationContextSummary(
            readinessBand: "green",
            readinessScore: nil,
            recentWorkoutCount: 0,
            activeGoals: []
        )

        let context = RecommendationContext(from: contextSummary)

        XCTAssertEqual(context.readinessBand, .green)
    }

    func testRecommendationContext_InitFromResponse_YellowBand() {
        let contextSummary = WorkoutRecommendationContextSummary(
            readinessBand: "yellow",
            readinessScore: nil,
            recentWorkoutCount: 0,
            activeGoals: []
        )

        let context = RecommendationContext(from: contextSummary)

        XCTAssertEqual(context.readinessBand, .yellow)
    }

    func testRecommendationContext_InitFromResponse_OrangeBand() {
        let contextSummary = WorkoutRecommendationContextSummary(
            readinessBand: "orange",
            readinessScore: nil,
            recentWorkoutCount: 0,
            activeGoals: []
        )

        let context = RecommendationContext(from: contextSummary)

        XCTAssertEqual(context.readinessBand, .orange)
    }

    func testRecommendationContext_InitFromResponse_RedBand() {
        let contextSummary = WorkoutRecommendationContextSummary(
            readinessBand: "red",
            readinessScore: nil,
            recentWorkoutCount: 0,
            activeGoals: []
        )

        let context = RecommendationContext(from: contextSummary)

        XCTAssertEqual(context.readinessBand, .red)
    }

    func testRecommendationContext_InitFromResponse_NilBand() {
        let contextSummary = WorkoutRecommendationContextSummary(
            readinessBand: nil,
            readinessScore: nil,
            recentWorkoutCount: 3,
            activeGoals: []
        )

        let context = RecommendationContext(from: contextSummary)

        XCTAssertNil(context.readinessBand)
    }

    func testRecommendationContext_InitFromResponse_InvalidBand() {
        let contextSummary = WorkoutRecommendationContextSummary(
            readinessBand: "invalid_band",
            readinessScore: nil,
            recentWorkoutCount: 0,
            activeGoals: []
        )

        let context = RecommendationContext(from: contextSummary)

        XCTAssertNil(context.readinessBand, "Invalid band string should result in nil")
    }

    func testRecommendationContext_InitFromResponse_EmptyGoals() {
        let contextSummary = WorkoutRecommendationContextSummary(
            readinessBand: nil,
            readinessScore: nil,
            recentWorkoutCount: 0,
            activeGoals: []
        )

        let context = RecommendationContext(from: contextSummary)

        XCTAssertEqual(context.activeGoals.count, 0)
    }

    func testRecommendationContext_InitFromResponse_ManyGoals() {
        let goals = ["Goal 1", "Goal 2", "Goal 3", "Goal 4", "Goal 5"]
        let contextSummary = WorkoutRecommendationContextSummary(
            readinessBand: nil,
            readinessScore: nil,
            recentWorkoutCount: 0,
            activeGoals: goals
        )

        let context = RecommendationContext(from: contextSummary)

        XCTAssertEqual(context.activeGoals.count, 5)
        XCTAssertEqual(context.activeGoals, goals)
    }

    func testRecommendationContext_ReadinessScorePreserved() {
        let contextSummary = WorkoutRecommendationContextSummary(
            readinessBand: nil,
            readinessScore: 67.89,
            recentWorkoutCount: 0,
            activeGoals: []
        )

        let context = RecommendationContext(from: contextSummary)

        XCTAssertEqual(context.readinessScore, 67.89, accuracy: 0.001)
    }

    func testRecommendationContext_RecentWorkoutCountPreserved() {
        let contextSummary = WorkoutRecommendationContextSummary(
            readinessBand: nil,
            readinessScore: nil,
            recentWorkoutCount: 10,
            activeGoals: []
        )

        let context = RecommendationContext(from: contextSummary)

        XCTAssertEqual(context.recentWorkoutCount, 10)
    }
}

// MARK: - JSON Encoding Tests

final class WorkoutRecommendationEncodingTests: XCTestCase {

    func testWorkoutRecommendationItem_CodingKeysRoundTrip() throws {
        let original = WorkoutRecommendationItem(
            templateId: "550e8400-e29b-41d4-a716-446655440000",
            templateName: "Test Workout",
            matchScore: 85,
            reasoning: "Great match",
            category: "strength",
            durationMinutes: 45,
            difficulty: "intermediate"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WorkoutRecommendationItem.self, from: data)

        XCTAssertEqual(decoded.templateId, original.templateId)
        XCTAssertEqual(decoded.templateName, original.templateName)
        XCTAssertEqual(decoded.matchScore, original.matchScore)
        XCTAssertEqual(decoded.reasoning, original.reasoning)
        XCTAssertEqual(decoded.category, original.category)
        XCTAssertEqual(decoded.durationMinutes, original.durationMinutes)
        XCTAssertEqual(decoded.difficulty, original.difficulty)
    }

    func testWorkoutRecommendationContextSummary_CodingKeysRoundTrip() throws {
        let original = WorkoutRecommendationContextSummary(
            readinessBand: "yellow",
            readinessScore: 75.5,
            recentWorkoutCount: 3,
            activeGoals: ["Goal A", "Goal B"]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WorkoutRecommendationContextSummary.self, from: data)

        XCTAssertEqual(decoded.readinessBand, original.readinessBand)
        XCTAssertEqual(decoded.readinessScore, original.readinessScore)
        XCTAssertEqual(decoded.recentWorkoutCount, original.recentWorkoutCount)
        XCTAssertEqual(decoded.activeGoals, original.activeGoals)
    }

    func testEncodedJSON_UsesSnakeCaseKeys() throws {
        let item = WorkoutRecommendationItem(
            templateId: "test-id",
            templateName: "Test",
            matchScore: 80,
            reasoning: "Test",
            category: nil,
            durationMinutes: 30,
            difficulty: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(item)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertTrue(jsonString.contains("template_id"), "Should use snake_case for template_id")
        XCTAssertTrue(jsonString.contains("template_name"), "Should use snake_case for template_name")
        XCTAssertTrue(jsonString.contains("match_score"), "Should use snake_case for match_score")
        XCTAssertTrue(jsonString.contains("duration_minutes"), "Should use snake_case for duration_minutes")
    }
}

// MARK: - Edge Cases and Boundary Tests

final class WorkoutRecommendationEdgeCaseTests: XCTestCase {

    func testDecoding_ExtremeMatchScores() throws {
        // Test negative score (edge case)
        let negativeJson = """
        {
            "template_id": "test",
            "template_name": "Test",
            "match_score": -10,
            "reasoning": "Test"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let negativeItem = try decoder.decode(WorkoutRecommendationItem.self, from: negativeJson)
        XCTAssertEqual(negativeItem.matchScore, -10)

        // Test score over 100 (edge case)
        let highJson = """
        {
            "template_id": "test",
            "template_name": "Test",
            "match_score": 150,
            "reasoning": "Test"
        }
        """.data(using: .utf8)!

        let highItem = try decoder.decode(WorkoutRecommendationItem.self, from: highJson)
        XCTAssertEqual(highItem.matchScore, 150)
    }

    func testDecoding_ZeroDuration() throws {
        let json = """
        {
            "template_id": "test",
            "template_name": "Test",
            "match_score": 80,
            "reasoning": "Test",
            "duration_minutes": 0
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let item = try decoder.decode(WorkoutRecommendationItem.self, from: json)

        XCTAssertEqual(item.durationMinutes, 0)

        let recommendation = AIWorkoutRecommendation(from: item)
        XCTAssertEqual(recommendation.durationText, "0 min")
    }

    func testDecoding_VeryLongTemplateName() throws {
        let longName = String(repeating: "A", count: 500)
        let json = """
        {
            "template_id": "test",
            "template_name": "\(longName)",
            "match_score": 80,
            "reasoning": "Test"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let item = try decoder.decode(WorkoutRecommendationItem.self, from: json)

        XCTAssertEqual(item.templateName.count, 500)
    }

    func testDecoding_EmptyActiveGoals() throws {
        let json = """
        {
            "recent_workout_count": 5,
            "active_goals": []
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let summary = try decoder.decode(WorkoutRecommendationContextSummary.self, from: json)

        XCTAssertEqual(summary.activeGoals.count, 0)
    }

    func testDecoding_SpecialCharactersInReasoning() throws {
        let json = """
        {
            "template_id": "test",
            "template_name": "Test",
            "match_score": 80,
            "reasoning": "Great for building strength! 💪 100% recommended."
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let item = try decoder.decode(WorkoutRecommendationItem.self, from: json)

        XCTAssertTrue(item.reasoning.contains("💪"))
        XCTAssertTrue(item.reasoning.contains("100%"))
    }

    func testMatchScoreColor_BoundaryAt80() {
        // Test the exact boundary between green and orange
        let greenItem = createMockItem(matchScore: 80)
        let orangeItem = createMockItem(matchScore: 79)

        let greenRec = AIWorkoutRecommendation(from: greenItem)
        let orangeRec = AIWorkoutRecommendation(from: orangeItem)

        XCTAssertEqual(greenRec.matchScoreColor, "green")
        XCTAssertEqual(orangeRec.matchScoreColor, "orange")
    }

    func testMatchScoreColor_BoundaryAt60() {
        // Test the exact boundary between orange and gray
        let orangeItem = createMockItem(matchScore: 60)
        let grayItem = createMockItem(matchScore: 59)

        let orangeRec = AIWorkoutRecommendation(from: orangeItem)
        let grayRec = AIWorkoutRecommendation(from: grayItem)

        XCTAssertEqual(orangeRec.matchScoreColor, "orange")
        XCTAssertEqual(grayRec.matchScoreColor, "gray")
    }

    private func createMockItem(matchScore: Int) -> WorkoutRecommendationItem {
        WorkoutRecommendationItem(
            templateId: UUID().uuidString,
            templateName: "Test",
            matchScore: matchScore,
            reasoning: "Test",
            category: nil,
            durationMinutes: nil,
            difficulty: nil
        )
    }
}
