//
//  SubstitutionFilteringTests.swift
//  PTPerformanceTests
//
//  Build 186 - Test substitution filtering logic
//

import XCTest
@testable import PTPerformance

final class SubstitutionFilteringTests: XCTestCase {

    /// Test that we can correctly filter substitutions by originalExerciseId
    func testSubstitutionFilteringByExerciseTemplateId() throws {
        // Given: A specific exercise template ID we're looking for
        let targetExerciseTemplateId = UUID(uuidString: "00000000-0000-0000-0000-0000000000e2")!

        // And: A list of substitutions from the AI (simulating what edge function returns)
        let substitutions = [
            createMockSubstitution(
                originalExerciseId: "00000000-0000-0000-0000-0000000000e2",
                originalExerciseName: "Barbell Squat",
                substituteExerciseName: "Bodyweight Squat"
            ),
            createMockSubstitution(
                originalExerciseId: "cb7cbaec-78ee-4a50-b497-e53b83b7016a",
                originalExerciseName: "Barbell Bench Press",
                substituteExerciseName: "Push-ups"
            ),
            createMockSubstitution(
                originalExerciseId: "00000000-0000-0000-0000-0000000000f2",
                originalExerciseName: "Barbell Row",
                substituteExerciseName: "Prone Y Raise"
            ),
        ]

        // When: We filter for the target exercise
        let relevantSubstitution = substitutions.first { sub in
            sub.originalExerciseId == targetExerciseTemplateId
        }

        // Then: We should find the Barbell Squat -> Bodyweight Squat substitution
        XCTAssertNotNil(relevantSubstitution, "Should find a matching substitution")
        XCTAssertEqual(relevantSubstitution?.exerciseName, "Bodyweight Squat")
        XCTAssertEqual(relevantSubstitution?.originalExerciseName, "Barbell Squat")
    }

    /// Test that filtering returns nil when no match exists
    func testSubstitutionFilteringNoMatch() throws {
        // Given: An exercise template ID that's NOT in the substitutions
        let targetExerciseTemplateId = UUID(uuidString: "99999999-9999-9999-9999-999999999999")!

        // And: Substitutions that don't include that ID
        let substitutions = [
            createMockSubstitution(
                originalExerciseId: "00000000-0000-0000-0000-0000000000e2",
                originalExerciseName: "Barbell Squat",
                substituteExerciseName: "Bodyweight Squat"
            ),
        ]

        // When: We filter for the target exercise
        let relevantSubstitution = substitutions.first { sub in
            sub.originalExerciseId == targetExerciseTemplateId
        }

        // Then: No match should be found
        XCTAssertNil(relevantSubstitution, "Should NOT find a matching substitution")
    }

    /// Test UUID parsing from string
    func testUUIDParsingFromString() throws {
        // Test that UUID(uuidString:) works correctly
        let uuidString = "00000000-0000-0000-0000-0000000000e2"
        let parsedUUID = UUID(uuidString: uuidString)

        XCTAssertNotNil(parsedUUID, "Should parse valid UUID string")
        XCTAssertEqual(parsedUUID?.uuidString.lowercased(), uuidString.lowercased())
    }

    /// Test comparing Optional<UUID> with UUID
    func testOptionalUUIDComparison() throws {
        let uuid1: UUID = UUID(uuidString: "00000000-0000-0000-0000-0000000000e2")!
        let uuid2: UUID? = UUID(uuidString: "00000000-0000-0000-0000-0000000000e2")

        // This is the exact comparison we do in relevantSubstitution
        XCTAssertTrue(uuid2 == uuid1, "Optional UUID should equal non-optional UUID with same value")

        let uuid3: UUID? = nil
        XCTAssertFalse(uuid3 == uuid1, "nil should not equal any UUID")
    }

    /// Test the actual ExerciseSubstitutionItem decoding and mapping
    func testExerciseSubstitutionItemDecoding() throws {
        // Given: JSON that matches what the edge function returns
        let json = """
        {
            "original_exercise_id": "00000000-0000-0000-0000-0000000000e2",
            "original_exercise_name": "Barbell Squat",
            "substitute_exercise_id": "00000000-0000-0000-0000-000000000013",
            "substitute_exercise_name": "Bodyweight Squat",
            "reason": "Selected for no equipment requirement"
        }
        """.data(using: .utf8)!

        // When: We decode it
        let decoder = JSONDecoder()
        let item = try decoder.decode(ExerciseSubstitutionItem.self, from: json)

        // Then: The values should be correct
        XCTAssertEqual(item.originalExerciseId, "00000000-0000-0000-0000-0000000000e2")
        XCTAssertEqual(item.originalExerciseName, "Barbell Squat")
        XCTAssertEqual(item.substituteExerciseName, "Bodyweight Squat")

        // And when we create an ExerciseSubstitution from it
        let substitution = ExerciseSubstitution(from: item, confidence: 85)

        // The originalExerciseId should be a valid UUID
        XCTAssertNotNil(substitution.originalExerciseId, "originalExerciseId should parse to UUID")
        XCTAssertEqual(
            substitution.originalExerciseId?.uuidString.lowercased(),
            "00000000-0000-0000-0000-0000000000e2"
        )
    }

    // MARK: - Helpers

    private func createMockSubstitution(
        originalExerciseId: String,
        originalExerciseName: String,
        substituteExerciseName: String
    ) -> ExerciseSubstitution {
        let item = ExerciseSubstitutionItem(
            originalExerciseId: originalExerciseId,
            originalExerciseName: originalExerciseName,
            substituteExerciseId: UUID().uuidString,
            substituteExerciseName: substituteExerciseName,
            reason: "Test reason",
            videoUrl: nil,
            videoThumbnailUrl: nil,
            techniqueCues: nil,
            formCues: nil,
            commonMistakes: nil,
            safetyNotes: nil,
            equipmentRequired: nil,
            musclesTargeted: nil,
            difficultyLevel: nil
        )
        return ExerciseSubstitution(from: item, confidence: 85)
    }
}
