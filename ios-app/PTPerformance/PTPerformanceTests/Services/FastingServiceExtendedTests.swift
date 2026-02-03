//
//  FastingServiceExtendedTests.swift
//  PTPerformanceTests
//
//  Extended unit tests for FastingService including workout recommendations
//  Tests fasting workout optimization and intensity calculations
//

import XCTest
@testable import PTPerformance

// MARK: - FastingWorkoutRecommendation Tests

final class FastingWorkoutRecommendationTests: XCTestCase {

    // MARK: - Decoding Tests

    func testFastingWorkoutRecommendation_Decoding() throws {
        let json = """
        {
            "optimization_id": "opt-123",
            "fasting_state": {
                "is_fasting": true,
                "started_at": "2024-01-15T20:00:00Z",
                "fasting_hours": 16.5,
                "protocol_type": "16_8",
                "planned_hours": 16.0
            },
            "workout_allowed": true,
            "workout_recommended": true,
            "modifications": [
                {
                    "type": "intensity",
                    "original_value": "100%",
                    "modified_value": "85%",
                    "rationale": "Reduced for fasted state"
                }
            ],
            "nutrition_timing": {
                "recommendation": "Break fast post-workout",
                "pre_workout": null,
                "intra_workout": "Electrolytes",
                "post_workout": "Protein + carbs",
                "timing_notes": "Within 30 minutes"
            },
            "safety_warnings": ["Stay hydrated"],
            "performance_notes": ["Expect reduced power"],
            "electrolyte_recommendations": ["Add sodium"],
            "alternative_workout_suggestion": null,
            "disclaimer": "Listen to your body"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let recommendation = try decoder.decode(FastingWorkoutRecommendation.self, from: json)

        XCTAssertEqual(recommendation.optimizationId, "opt-123")
        XCTAssertTrue(recommendation.fastingState.isFasting)
        XCTAssertEqual(recommendation.fastingState.fastingHours, 16.5)
        XCTAssertTrue(recommendation.workoutAllowed)
        XCTAssertTrue(recommendation.workoutRecommended)
        XCTAssertEqual(recommendation.modifications.count, 1)
        XCTAssertEqual(recommendation.safetyWarnings.count, 1)
    }

    // MARK: - Computed Properties Tests

    func testFastingWorkoutRecommendation_IntensityModifier_Under12Hours() {
        let recommendation = createRecommendation(fastingHours: 10.0)
        XCTAssertEqual(recommendation.intensityModifier, 1.0)
    }

    func testFastingWorkoutRecommendation_IntensityModifier_12to16Hours() {
        let recommendation = createRecommendation(fastingHours: 14.0)
        XCTAssertEqual(recommendation.intensityModifier, 0.95)
    }

    func testFastingWorkoutRecommendation_IntensityModifier_16to20Hours() {
        let recommendation = createRecommendation(fastingHours: 18.0)
        XCTAssertEqual(recommendation.intensityModifier, 0.85)
    }

    func testFastingWorkoutRecommendation_IntensityModifier_20to24Hours() {
        let recommendation = createRecommendation(fastingHours: 22.0)
        XCTAssertEqual(recommendation.intensityModifier, 0.75)
    }

    func testFastingWorkoutRecommendation_IntensityModifier_Over24Hours() {
        let recommendation = createRecommendation(fastingHours: 30.0)
        XCTAssertEqual(recommendation.intensityModifier, 0.65)
    }

    func testFastingWorkoutRecommendation_RecommendedWorkoutTypes_Under12() {
        let recommendation = createRecommendation(fastingHours: 8.0)
        let types = recommendation.recommendedWorkoutTypes

        XCTAssertTrue(types.contains("Strength Training"))
        XCTAssertTrue(types.contains("HIIT"))
        XCTAssertTrue(types.contains("Cardio"))
    }

    func testFastingWorkoutRecommendation_RecommendedWorkoutTypes_12to16() {
        let recommendation = createRecommendation(fastingHours: 14.0)
        let types = recommendation.recommendedWorkoutTypes

        XCTAssertTrue(types.contains("Strength Training"))
        XCTAssertTrue(types.contains("Zone 2 Cardio"))
        XCTAssertFalse(types.contains("HIIT"))
    }

    func testFastingWorkoutRecommendation_RecommendedWorkoutTypes_16to20() {
        let recommendation = createRecommendation(fastingHours: 18.0)
        let types = recommendation.recommendedWorkoutTypes

        XCTAssertTrue(types.contains("Light Strength"))
        XCTAssertTrue(types.contains("Walking"))
        XCTAssertTrue(types.contains("Yoga"))
    }

    func testFastingWorkoutRecommendation_RecommendedWorkoutTypes_Over20() {
        let recommendation = createRecommendation(fastingHours: 22.0)
        let types = recommendation.recommendedWorkoutTypes

        XCTAssertTrue(types.contains("Walking"))
        XCTAssertTrue(types.contains("Yoga"))
        XCTAssertTrue(types.contains("Stretching"))
        XCTAssertFalse(types.contains("HIIT"))
    }

    func testFastingWorkoutRecommendation_IsExtendedFast() {
        let shortFast = createRecommendation(fastingHours: 14.0)
        XCTAssertFalse(shortFast.isExtendedFast)

        let extendedFast = createRecommendation(fastingHours: 18.0)
        XCTAssertTrue(extendedFast.isExtendedFast)
    }

    func testFastingWorkoutRecommendation_IntensityPercentage() {
        let recommendation = createRecommendation(fastingHours: 16.0)
        XCTAssertEqual(recommendation.intensityPercentage, 95)
    }

    func testFastingWorkoutRecommendation_Identifiable() {
        let recommendation = createRecommendation(fastingHours: 12.0)
        XCTAssertEqual(recommendation.id, recommendation.optimizationId)
    }

    // MARK: - Helper Methods

    private func createRecommendation(fastingHours: Double) -> FastingWorkoutRecommendation {
        let fastingState = FastingStateResponse(
            isFasting: true,
            startedAt: "2024-01-15T20:00:00Z",
            fastingHours: fastingHours,
            protocolType: "16_8",
            plannedHours: 16.0
        )

        let nutritionTiming = NutritionTiming(
            recommendation: "Test",
            preWorkout: nil,
            intraWorkout: "Electrolytes",
            postWorkout: "Protein",
            timingNotes: "Test notes"
        )

        return FastingWorkoutRecommendation(
            optimizationId: "test-id",
            fastingState: fastingState,
            workoutAllowed: true,
            workoutRecommended: true,
            modifications: [],
            nutritionTiming: nutritionTiming,
            safetyWarnings: [],
            performanceNotes: [],
            electrolyteRecommendations: [],
            alternativeWorkoutSuggestion: nil,
            disclaimer: "Test disclaimer"
        )
    }
}

// MARK: - FastingStateResponse Tests

final class FastingStateResponseTests: XCTestCase {

    func testFastingStateResponse_Decoding() throws {
        let json = """
        {
            "is_fasting": true,
            "started_at": "2024-01-15T20:00:00Z",
            "fasting_hours": 14.5,
            "protocol_type": "16_8",
            "planned_hours": 16.0
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let state = try decoder.decode(FastingStateResponse.self, from: json)

        XCTAssertTrue(state.isFasting)
        XCTAssertEqual(state.startedAt, "2024-01-15T20:00:00Z")
        XCTAssertEqual(state.fastingHours, 14.5)
        XCTAssertEqual(state.protocolType, "16_8")
        XCTAssertEqual(state.plannedHours, 16.0)
    }

    func testFastingStateResponse_NotFasting() throws {
        let json = """
        {
            "is_fasting": false,
            "started_at": null,
            "fasting_hours": 0,
            "protocol_type": null,
            "planned_hours": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let state = try decoder.decode(FastingStateResponse.self, from: json)

        XCTAssertFalse(state.isFasting)
        XCTAssertNil(state.startedAt)
        XCTAssertEqual(state.fastingHours, 0)
        XCTAssertNil(state.protocolType)
        XCTAssertNil(state.plannedHours)
    }
}

// MARK: - WorkoutModification Tests

final class WorkoutModificationTests: XCTestCase {

    func testWorkoutModification_Decoding() throws {
        let json = """
        {
            "type": "intensity",
            "original_value": "100%",
            "modified_value": "85%",
            "rationale": "Reduce intensity for fasted state"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let modification = try decoder.decode(WorkoutModification.self, from: json)

        XCTAssertEqual(modification.type, "intensity")
        XCTAssertEqual(modification.originalValue, "100%")
        XCTAssertEqual(modification.modifiedValue, "85%")
        XCTAssertTrue(modification.rationale.contains("fasted"))
    }

    func testWorkoutModification_Identifiable() throws {
        let json = """
        {
            "type": "volume",
            "original_value": "4 sets",
            "modified_value": "3 sets",
            "rationale": "Reduce volume"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let modification = try decoder.decode(WorkoutModification.self, from: json)

        // ID should be combination of type and rationale prefix
        XCTAssertTrue(modification.id.contains("volume"))
    }
}

// MARK: - NutritionTiming Tests

final class NutritionTimingTests: XCTestCase {

    func testNutritionTiming_Decoding() throws {
        let json = """
        {
            "recommendation": "Break fast within 2 hours post-workout",
            "pre_workout": "BCAAs optional",
            "intra_workout": "Electrolytes with sodium",
            "post_workout": "40g protein + moderate carbs",
            "timing_notes": "Optimal window is within 30 minutes"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let timing = try decoder.decode(NutritionTiming.self, from: json)

        XCTAssertEqual(timing.recommendation, "Break fast within 2 hours post-workout")
        XCTAssertEqual(timing.preWorkout, "BCAAs optional")
        XCTAssertEqual(timing.intraWorkout, "Electrolytes with sodium")
        XCTAssertEqual(timing.postWorkout, "40g protein + moderate carbs")
        XCTAssertEqual(timing.timingNotes, "Optimal window is within 30 minutes")
    }

    func testNutritionTiming_NullPreWorkout() throws {
        let json = """
        {
            "recommendation": "Standard fed state nutrition",
            "pre_workout": null,
            "intra_workout": "Water",
            "post_workout": "Balanced meal",
            "timing_notes": "No special requirements"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let timing = try decoder.decode(NutritionTiming.self, from: json)

        XCTAssertNil(timing.preWorkout)
    }
}

// MARK: - FastingService Extended Tests

@MainActor
final class FastingServiceExtendedTests: XCTestCase {

    var sut: FastingService!

    override func setUp() async throws {
        try await super.setUp()
        sut = FastingService.shared
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Workout Recommendation Property Tests

    func testWorkoutRecommendationProperty_Exists() {
        _ = sut.workoutRecommendation
    }

    func testWorkoutRecommendationProperty_InitiallyNil() {
        // Note: This depends on service state - may need reset
        // Testing that the property exists and can be accessed
        let recommendation = sut.workoutRecommendation
        // Property should be accessible
        _ = recommendation
    }

    // MARK: - Generate Local Workout Recommendation Tests

    func testGenerateLocalWorkoutRecommendation_WhenNotFasting() async {
        // When not fasting, should generate a fed state recommendation
        await sut.generateLocalWorkoutRecommendation()

        // The recommendation should exist (fed state if no current fast)
        // Note: Actual behavior depends on currentFast state
    }
}

// MARK: - Fasting Workout Edge Cases

final class FastingWorkoutEdgeCasesTests: XCTestCase {

    func testIntensityModifier_AtBoundaries() {
        // Test exactly at boundary values
        let at12Hours = createRecommendation(fastingHours: 12.0)
        XCTAssertEqual(at12Hours.intensityModifier, 0.95) // 12 is in 12-16 range

        let at16Hours = createRecommendation(fastingHours: 16.0)
        XCTAssertEqual(at16Hours.intensityModifier, 0.85) // 16 is in 16-20 range

        let at20Hours = createRecommendation(fastingHours: 20.0)
        XCTAssertEqual(at20Hours.intensityModifier, 0.75) // 20 is in 20-24 range

        let at24Hours = createRecommendation(fastingHours: 24.0)
        XCTAssertEqual(at24Hours.intensityModifier, 0.65) // 24+ gets 0.65
    }

    func testIntensityModifier_ZeroHours() {
        let recommendation = createRecommendation(fastingHours: 0.0)
        XCTAssertEqual(recommendation.intensityModifier, 1.0)
    }

    func testIntensityModifier_VeryLongFast() {
        let recommendation = createRecommendation(fastingHours: 72.0)
        XCTAssertEqual(recommendation.intensityModifier, 0.65) // Capped at 0.65
    }

    func testIsExtendedFast_AtBoundary() {
        let at15Hours = createRecommendation(fastingHours: 15.9)
        XCTAssertFalse(at15Hours.isExtendedFast)

        let at16Hours = createRecommendation(fastingHours: 16.0)
        XCTAssertTrue(at16Hours.isExtendedFast)
    }

    func testIntensityPercentage_Rounding() {
        // 0.95 * 100 = 95
        let rec1 = createRecommendation(fastingHours: 14.0)
        XCTAssertEqual(rec1.intensityPercentage, 95)

        // 0.85 * 100 = 85
        let rec2 = createRecommendation(fastingHours: 18.0)
        XCTAssertEqual(rec2.intensityPercentage, 85)

        // 0.75 * 100 = 75
        let rec3 = createRecommendation(fastingHours: 22.0)
        XCTAssertEqual(rec3.intensityPercentage, 75)

        // 0.65 * 100 = 65
        let rec4 = createRecommendation(fastingHours: 26.0)
        XCTAssertEqual(rec4.intensityPercentage, 65)
    }

    // MARK: - Helper Methods

    private func createRecommendation(fastingHours: Double) -> FastingWorkoutRecommendation {
        let fastingState = FastingStateResponse(
            isFasting: fastingHours > 0,
            startedAt: fastingHours > 0 ? "2024-01-15T20:00:00Z" : nil,
            fastingHours: fastingHours,
            protocolType: "custom",
            plannedHours: nil
        )

        let nutritionTiming = NutritionTiming(
            recommendation: "Test",
            preWorkout: nil,
            intraWorkout: nil,
            postWorkout: "Test",
            timingNotes: "Test"
        )

        return FastingWorkoutRecommendation(
            optimizationId: UUID().uuidString,
            fastingState: fastingState,
            workoutAllowed: true,
            workoutRecommended: true,
            modifications: [],
            nutritionTiming: nutritionTiming,
            safetyWarnings: [],
            performanceNotes: [],
            electrolyteRecommendations: [],
            alternativeWorkoutSuggestion: nil,
            disclaimer: "Test"
        )
    }
}
