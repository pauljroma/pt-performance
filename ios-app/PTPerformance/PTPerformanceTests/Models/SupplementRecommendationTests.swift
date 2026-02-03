//
//  SupplementRecommendationTests.swift
//  PTPerformanceTests
//
//  Unit tests for SupplementRecommendation and related AI recommendation models
//

import XCTest
@testable import PTPerformance

// MARK: - SupplementRecommendationResponse Tests

final class SupplementRecommendationResponseTests: XCTestCase {

    // MARK: - Decoding Tests

    func testSupplementRecommendationResponse_Decoding() throws {
        let json = """
        {
            "recommendation_id": "rec-123",
            "recommendations": [],
            "stack_summary": "Optimized for muscle building and recovery",
            "total_daily_cost_estimate": "$2.50",
            "goal_coverage": {
                "muscle_building": ["Creatine", "Protein"],
                "recovery": ["Omega-3"]
            },
            "interaction_warnings": ["Do not take with iron"],
            "timing_schedule": {
                "morning": [],
                "pre_workout": [],
                "post_workout": [],
                "evening": [],
                "with_meals": []
            },
            "disclaimer": "Consult your doctor",
            "cached": false
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(SupplementRecommendationResponse.self, from: json)

        XCTAssertEqual(response.recommendationId, "rec-123")
        XCTAssertEqual(response.stackSummary, "Optimized for muscle building and recovery")
        XCTAssertEqual(response.totalDailyCostEstimate, "$2.50")
        XCTAssertEqual(response.goalCoverage.count, 2)
        XCTAssertEqual(response.interactionWarnings.count, 1)
        XCTAssertFalse(response.cached)
    }

    func testSupplementRecommendationResponse_FullDecoding() throws {
        let json = """
        {
            "recommendation_id": "rec-456",
            "recommendations": [
                {
                    "supplement_id": "supp-1",
                    "name": "Creatine Monohydrate",
                    "brand": "Momentous",
                    "category": "performance",
                    "dosage": "5g daily",
                    "timing": "Post-workout",
                    "evidence_rating": 5,
                    "rationale": "Most studied supplement for strength",
                    "goal_alignment": ["muscle_building", "recovery"],
                    "purchase_url": "https://example.com",
                    "priority": "essential",
                    "warnings": []
                }
            ],
            "stack_summary": "Foundation stack",
            "total_daily_cost_estimate": "$1.00",
            "goal_coverage": {},
            "interaction_warnings": [],
            "timing_schedule": {
                "morning": [{"name": "Vitamin D", "dosage": "5000 IU", "notes": "With food"}],
                "pre_workout": [],
                "post_workout": [{"name": "Creatine", "dosage": "5g", "notes": "With carbs"}],
                "evening": [],
                "with_meals": []
            },
            "disclaimer": "Not medical advice",
            "cached": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(SupplementRecommendationResponse.self, from: json)

        XCTAssertEqual(response.recommendations.count, 1)
        XCTAssertEqual(response.recommendations.first?.name, "Creatine Monohydrate")
        XCTAssertEqual(response.timingSchedule.morning.count, 1)
        XCTAssertEqual(response.timingSchedule.postWorkout.count, 1)
        XCTAssertTrue(response.cached)
    }

    func testSupplementRecommendationResponse_Encoding() throws {
        let timingSchedule = SupplementTimingSchedule(
            morning: [],
            preWorkout: [],
            postWorkout: [],
            evening: [],
            withMeals: []
        )

        let response = SupplementRecommendationResponse(
            recommendationId: "test-id",
            recommendations: [],
            stackSummary: "Test stack",
            totalDailyCostEstimate: "$0.00",
            goalCoverage: [:],
            interactionWarnings: [],
            timingSchedule: timingSchedule,
            disclaimer: "Test disclaimer",
            cached: false
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(response)
        let jsonObject = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertNotNil(jsonObject["recommendation_id"])
        XCTAssertNotNil(jsonObject["stack_summary"])
        XCTAssertNotNil(jsonObject["total_daily_cost_estimate"])
        XCTAssertNotNil(jsonObject["timing_schedule"])
    }
}

// MARK: - AISupplementRecommendation Tests

final class AISupplementRecommendationTests: XCTestCase {

    func testAISupplementRecommendation_Decoding() throws {
        let json = """
        {
            "supplement_id": "omega-3-fish-oil",
            "name": "Omega-3 Fish Oil",
            "brand": "Nordic Naturals",
            "category": "essential_fatty_acids",
            "dosage": "2g EPA/DHA daily",
            "timing": "With meals",
            "evidence_rating": 4,
            "rationale": "Supports inflammation reduction and heart health",
            "goal_alignment": ["recovery", "longevity"],
            "purchase_url": "https://example.com/omega3",
            "priority": "recommended",
            "warnings": ["May increase bleeding risk"]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let recommendation = try decoder.decode(AISupplementRecommendation.self, from: json)

        XCTAssertEqual(recommendation.supplementId, "omega-3-fish-oil")
        XCTAssertEqual(recommendation.name, "Omega-3 Fish Oil")
        XCTAssertEqual(recommendation.brand, "Nordic Naturals")
        XCTAssertEqual(recommendation.category, "essential_fatty_acids")
        XCTAssertEqual(recommendation.dosage, "2g EPA/DHA daily")
        XCTAssertEqual(recommendation.timing, "With meals")
        XCTAssertEqual(recommendation.evidenceRating, 4)
        XCTAssertEqual(recommendation.goalAlignment.count, 2)
        XCTAssertEqual(recommendation.purchaseUrl, "https://example.com/omega3")
        XCTAssertEqual(recommendation.priority, .recommended)
        XCTAssertEqual(recommendation.warnings.count, 1)
    }

    func testAISupplementRecommendation_NilSupplementId() throws {
        let json = """
        {
            "name": "Custom Supplement",
            "brand": "Generic",
            "category": "other",
            "dosage": "100mg",
            "timing": "Morning",
            "evidence_rating": 2,
            "rationale": "May help",
            "goal_alignment": [],
            "priority": "optional",
            "warnings": []
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let recommendation = try decoder.decode(AISupplementRecommendation.self, from: json)

        XCTAssertNil(recommendation.supplementId)
        XCTAssertNil(recommendation.purchaseUrl)
        // ID should still work via computed property
        XCTAssertFalse(recommendation.id.isEmpty)
    }

    func testAISupplementRecommendation_Identifiable() {
        let recommendation = AISupplementRecommendation(
            supplementId: "test-id",
            name: "Test",
            brand: "Brand",
            category: "category",
            dosage: "1g",
            timing: "Morning",
            evidenceRating: 3,
            rationale: "Test",
            goalAlignment: [],
            purchaseUrl: nil,
            priority: .optional,
            warnings: []
        )

        XCTAssertEqual(recommendation.id, "test-id")
    }

    func testAISupplementRecommendation_Hashable() {
        let recommendation1 = AISupplementRecommendation(
            supplementId: "id-1",
            name: "Supp 1",
            brand: "Brand",
            category: "cat",
            dosage: "1g",
            timing: "AM",
            evidenceRating: 5,
            rationale: "Reason",
            goalAlignment: [],
            purchaseUrl: nil,
            priority: .essential,
            warnings: []
        )

        let recommendation2 = AISupplementRecommendation(
            supplementId: "id-2",
            name: "Supp 2",
            brand: "Brand",
            category: "cat",
            dosage: "1g",
            timing: "AM",
            evidenceRating: 5,
            rationale: "Reason",
            goalAlignment: [],
            purchaseUrl: nil,
            priority: .essential,
            warnings: []
        )

        var set = Set<AISupplementRecommendation>()
        set.insert(recommendation1)
        set.insert(recommendation2)

        XCTAssertEqual(set.count, 2)
    }
}

// MARK: - SupplementPriority Tests

final class SupplementPriorityTests: XCTestCase {

    func testSupplementPriority_RawValues() {
        XCTAssertEqual(SupplementPriority.essential.rawValue, "essential")
        XCTAssertEqual(SupplementPriority.recommended.rawValue, "recommended")
        XCTAssertEqual(SupplementPriority.optional.rawValue, "optional")
    }

    func testSupplementPriority_DisplayNames() {
        XCTAssertEqual(SupplementPriority.essential.displayName, "Essential")
        XCTAssertEqual(SupplementPriority.recommended.displayName, "Recommended")
        XCTAssertEqual(SupplementPriority.optional.displayName, "Optional")
    }

    func testSupplementPriority_Colors() {
        XCTAssertEqual(SupplementPriority.essential.color, "red")
        XCTAssertEqual(SupplementPriority.recommended.color, "orange")
        XCTAssertEqual(SupplementPriority.optional.color, "blue")
    }

    func testSupplementPriority_SortOrder() {
        XCTAssertEqual(SupplementPriority.essential.sortOrder, 0)
        XCTAssertEqual(SupplementPriority.recommended.sortOrder, 1)
        XCTAssertEqual(SupplementPriority.optional.sortOrder, 2)

        let priorities: [SupplementPriority] = [.optional, .essential, .recommended]
        let sorted = priorities.sorted { $0.sortOrder < $1.sortOrder }

        XCTAssertEqual(sorted, [.essential, .recommended, .optional])
    }

    func testSupplementPriority_AllCases() {
        let allCases = SupplementPriority.allCases
        XCTAssertEqual(allCases.count, 3)
    }
}

// MARK: - SupplementTimingSchedule Tests

final class SupplementTimingScheduleTests: XCTestCase {

    func testSupplementTimingSchedule_Decoding() throws {
        let json = """
        {
            "morning": [
                {"name": "Vitamin D", "dosage": "5000 IU", "notes": "With breakfast"}
            ],
            "pre_workout": [
                {"name": "Caffeine", "dosage": "200mg", "notes": "30 min before"}
            ],
            "post_workout": [
                {"name": "Protein", "dosage": "30g", "notes": "Within 30 min"}
            ],
            "evening": [
                {"name": "Magnesium", "dosage": "400mg", "notes": "Before bed"}
            ],
            "with_meals": [
                {"name": "Fish Oil", "dosage": "2g", "notes": "Reduces nausea"}
            ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let schedule = try decoder.decode(SupplementTimingSchedule.self, from: json)

        XCTAssertEqual(schedule.morning.count, 1)
        XCTAssertEqual(schedule.preWorkout.count, 1)
        XCTAssertEqual(schedule.postWorkout.count, 1)
        XCTAssertEqual(schedule.evening.count, 1)
        XCTAssertEqual(schedule.withMeals.count, 1)
    }

    func testSupplementTimingSchedule_AllTimings() {
        let schedule = SupplementTimingSchedule(
            morning: [SupplementTimingItem(name: "Vitamin D", dosage: "5000 IU", notes: "")],
            preWorkout: [],
            postWorkout: [SupplementTimingItem(name: "Creatine", dosage: "5g", notes: "")],
            evening: [],
            withMeals: []
        )

        let allTimings = schedule.allTimings

        // Should only include non-empty arrays
        XCTAssertEqual(allTimings.count, 2)
        XCTAssertTrue(allTimings.contains { $0.0 == "Morning" })
        XCTAssertTrue(allTimings.contains { $0.0 == "Post-Workout" })
    }

    func testSupplementTimingSchedule_AllTimings_Empty() {
        let schedule = SupplementTimingSchedule(
            morning: [],
            preWorkout: [],
            postWorkout: [],
            evening: [],
            withMeals: []
        )

        XCTAssertTrue(schedule.allTimings.isEmpty)
    }

    func testSupplementTimingSchedule_Hashable() {
        let schedule1 = SupplementTimingSchedule(
            morning: [SupplementTimingItem(name: "A", dosage: "1g", notes: "")],
            preWorkout: [],
            postWorkout: [],
            evening: [],
            withMeals: []
        )

        let schedule2 = SupplementTimingSchedule(
            morning: [SupplementTimingItem(name: "A", dosage: "1g", notes: "")],
            preWorkout: [],
            postWorkout: [],
            evening: [],
            withMeals: []
        )

        XCTAssertEqual(schedule1, schedule2)
    }
}

// MARK: - SupplementTimingItem Tests

final class SupplementTimingItemTests: XCTestCase {

    func testSupplementTimingItem_Initialization() {
        let item = SupplementTimingItem(
            name: "Creatine",
            dosage: "5g",
            notes: "Mix with water"
        )

        XCTAssertEqual(item.name, "Creatine")
        XCTAssertEqual(item.dosage, "5g")
        XCTAssertEqual(item.notes, "Mix with water")
    }

    func testSupplementTimingItem_Identifiable() {
        let item = SupplementTimingItem(
            name: "TestSupplement",
            dosage: "1g",
            notes: ""
        )

        XCTAssertEqual(item.id, "TestSupplement")
    }

    func testSupplementTimingItem_Codable() throws {
        let original = SupplementTimingItem(
            name: "Vitamin C",
            dosage: "1000mg",
            notes: "Take with citrus"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SupplementTimingItem.self, from: data)

        XCTAssertEqual(original.name, decoded.name)
        XCTAssertEqual(original.dosage, decoded.dosage)
        XCTAssertEqual(original.notes, decoded.notes)
    }

    func testSupplementTimingItem_Hashable() {
        let item1 = SupplementTimingItem(name: "A", dosage: "1g", notes: "")
        let item2 = SupplementTimingItem(name: "A", dosage: "1g", notes: "")
        let item3 = SupplementTimingItem(name: "B", dosage: "1g", notes: "")

        XCTAssertEqual(item1, item2)
        XCTAssertNotEqual(item1, item3)
    }
}

// MARK: - SupplementGoal Tests

final class SupplementGoalTests: XCTestCase {

    func testSupplementGoal_RawValues() {
        XCTAssertEqual(SupplementGoal.muscleBuilding.rawValue, "muscle_building")
        XCTAssertEqual(SupplementGoal.fatLoss.rawValue, "fat_loss")
        XCTAssertEqual(SupplementGoal.sleep.rawValue, "sleep")
        XCTAssertEqual(SupplementGoal.cognitive.rawValue, "cognitive")
        XCTAssertEqual(SupplementGoal.recovery.rawValue, "recovery")
        XCTAssertEqual(SupplementGoal.testosterone.rawValue, "testosterone")
        XCTAssertEqual(SupplementGoal.energy.rawValue, "energy")
        XCTAssertEqual(SupplementGoal.longevity.rawValue, "longevity")
        XCTAssertEqual(SupplementGoal.general.rawValue, "general")
    }

    func testSupplementGoal_DisplayNames() {
        XCTAssertEqual(SupplementGoal.muscleBuilding.displayName, "Muscle Building")
        XCTAssertEqual(SupplementGoal.fatLoss.displayName, "Fat Loss")
        XCTAssertEqual(SupplementGoal.sleep.displayName, "Sleep Quality")
        XCTAssertEqual(SupplementGoal.cognitive.displayName, "Cognitive Performance")
        XCTAssertEqual(SupplementGoal.recovery.displayName, "Recovery")
        XCTAssertEqual(SupplementGoal.testosterone.displayName, "Hormone Optimization")
        XCTAssertEqual(SupplementGoal.energy.displayName, "Energy & Endurance")
        XCTAssertEqual(SupplementGoal.longevity.displayName, "Longevity")
        XCTAssertEqual(SupplementGoal.general.displayName, "General Health")
    }

    func testSupplementGoal_Icons() {
        for goal in SupplementGoal.allCases {
            XCTAssertFalse(goal.icon.isEmpty, "Goal \(goal) should have an icon")
        }
    }

    func testSupplementGoal_Descriptions() {
        for goal in SupplementGoal.allCases {
            XCTAssertFalse(goal.description.isEmpty, "Goal \(goal) should have a description")
            XCTAssertTrue(goal.description.count > 10, "Goal \(goal) should have a meaningful description")
        }
    }

    func testSupplementGoal_AllCases() {
        let allCases = SupplementGoal.allCases
        XCTAssertEqual(allCases.count, 9)
    }

    func testSupplementGoal_Identifiable() {
        let goal = SupplementGoal.muscleBuilding
        XCTAssertEqual(goal.id, "muscle_building")
    }
}

// MARK: - Edge Cases Tests

final class SupplementRecommendationEdgeCasesTests: XCTestCase {

    func testEmptyRecommendations() throws {
        let json = """
        {
            "recommendation_id": "empty-test",
            "recommendations": [],
            "stack_summary": "",
            "total_daily_cost_estimate": "$0.00",
            "goal_coverage": {},
            "interaction_warnings": [],
            "timing_schedule": {
                "morning": [],
                "pre_workout": [],
                "post_workout": [],
                "evening": [],
                "with_meals": []
            },
            "disclaimer": "",
            "cached": false
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(SupplementRecommendationResponse.self, from: json)

        XCTAssertTrue(response.recommendations.isEmpty)
        XCTAssertTrue(response.stackSummary.isEmpty)
        XCTAssertTrue(response.goalCoverage.isEmpty)
        XCTAssertTrue(response.interactionWarnings.isEmpty)
        XCTAssertTrue(response.timingSchedule.allTimings.isEmpty)
    }

    func testRecommendationWithMaxEvidenceRating() throws {
        let json = """
        {
            "name": "Creatine",
            "brand": "Brand",
            "category": "performance",
            "dosage": "5g",
            "timing": "Any",
            "evidence_rating": 5,
            "rationale": "Most studied",
            "goal_alignment": ["muscle_building"],
            "priority": "essential",
            "warnings": []
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let recommendation = try decoder.decode(AISupplementRecommendation.self, from: json)

        XCTAssertEqual(recommendation.evidenceRating, 5)
    }

    func testRecommendationWithMinEvidenceRating() throws {
        let json = """
        {
            "name": "Unproven Supplement",
            "brand": "Brand",
            "category": "other",
            "dosage": "1g",
            "timing": "Any",
            "evidence_rating": 1,
            "rationale": "Limited evidence",
            "goal_alignment": [],
            "priority": "optional",
            "warnings": ["Limited research"]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let recommendation = try decoder.decode(AISupplementRecommendation.self, from: json)

        XCTAssertEqual(recommendation.evidenceRating, 1)
    }

    func testMultipleWarnings() throws {
        let json = """
        {
            "name": "Complex Supplement",
            "brand": "Brand",
            "category": "other",
            "dosage": "1g",
            "timing": "Morning",
            "evidence_rating": 3,
            "rationale": "Multiple interactions",
            "goal_alignment": [],
            "priority": "optional",
            "warnings": [
                "Do not take with blood thinners",
                "May cause stomach upset",
                "Not for pregnant women",
                "Consult doctor if on medication"
            ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let recommendation = try decoder.decode(AISupplementRecommendation.self, from: json)

        XCTAssertEqual(recommendation.warnings.count, 4)
    }

    func testGoalAlignmentWithAllGoals() throws {
        let allGoals = SupplementGoal.allCases.map { $0.rawValue }
        let goalsJson = allGoals.map { "\"\($0)\"" }.joined(separator: ", ")

        let json = """
        {
            "name": "Universal Supplement",
            "brand": "Brand",
            "category": "vitamins",
            "dosage": "1 serving",
            "timing": "Daily",
            "evidence_rating": 4,
            "rationale": "Broad benefits",
            "goal_alignment": [\(goalsJson)],
            "priority": "essential",
            "warnings": []
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let recommendation = try decoder.decode(AISupplementRecommendation.self, from: json)

        XCTAssertEqual(recommendation.goalAlignment.count, allGoals.count)
    }
}
