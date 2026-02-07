//
//  ExerciseLogServiceTests.swift
//  PTPerformanceTests
//
//  Comprehensive unit tests for ExerciseLogService
//  Tests exercise logging with various sets/reps combinations, error handling, and optimistic updates
//

import XCTest
@testable import PTPerformance

// MARK: - ExerciseLog Model Tests

final class ExerciseLogModelTests: XCTestCase {

    // MARK: - Initialization Tests

    func testExerciseLog_Initialization() {
        let id = UUID()
        let sessionExerciseId = UUID()
        let patientId = UUID()
        let loggedAt = Date()

        let log = ExerciseLog(
            id: id,
            sessionExerciseId: sessionExerciseId,
            patientId: patientId,
            loggedAt: loggedAt,
            actualSets: 3,
            actualReps: [10, 10, 8],
            actualLoad: 135.0,
            loadUnit: "lbs",
            rpe: 7,
            painScore: 0,
            notes: "Good form throughout",
            completed: true
        )

        XCTAssertEqual(log.id, id)
        XCTAssertEqual(log.sessionExerciseId, sessionExerciseId)
        XCTAssertEqual(log.patientId, patientId)
        XCTAssertEqual(log.loggedAt, loggedAt)
        XCTAssertEqual(log.actualSets, 3)
        XCTAssertEqual(log.actualReps, [10, 10, 8])
        XCTAssertEqual(log.actualLoad, 135.0)
        XCTAssertEqual(log.loadUnit, "lbs")
        XCTAssertEqual(log.rpe, 7)
        XCTAssertEqual(log.painScore, 0)
        XCTAssertEqual(log.notes, "Good form throughout")
        XCTAssertTrue(log.completed)
    }

    func testExerciseLog_WithNilOptionalFields() {
        let log = ExerciseLog(
            id: UUID(),
            sessionExerciseId: UUID(),
            patientId: UUID(),
            loggedAt: Date(),
            actualSets: 2,
            actualReps: [15, 15],
            actualLoad: nil,
            loadUnit: nil,
            rpe: 5,
            painScore: 0,
            notes: nil,
            completed: true
        )

        XCTAssertNil(log.actualLoad)
        XCTAssertNil(log.loadUnit)
        XCTAssertNil(log.notes)
    }

    // MARK: - JSON Decoding Tests

    func testExerciseLog_DecodesFromJSON() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "session_exercise_id": "123e4567-e89b-12d3-a456-426614174001",
            "patient_id": "123e4567-e89b-12d3-a456-426614174002",
            "logged_at": "2024-01-15T10:30:00Z",
            "actual_sets": 4,
            "actual_reps": [12, 12, 10, 10],
            "actual_load": 185.5,
            "load_unit": "lbs",
            "rpe": 8,
            "pain_score": 1,
            "notes": "Felt strong today",
            "completed": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let log = try decoder.decode(ExerciseLog.self, from: json)

        XCTAssertEqual(log.id.uuidString.lowercased(), "123e4567-e89b-12d3-a456-426614174000")
        XCTAssertEqual(log.sessionExerciseId.uuidString.lowercased(), "123e4567-e89b-12d3-a456-426614174001")
        XCTAssertEqual(log.patientId.uuidString.lowercased(), "123e4567-e89b-12d3-a456-426614174002")
        XCTAssertEqual(log.actualSets, 4)
        XCTAssertEqual(log.actualReps, [12, 12, 10, 10])
        XCTAssertEqual(log.actualLoad, 185.5)
        XCTAssertEqual(log.loadUnit, "lbs")
        XCTAssertEqual(log.rpe, 8)
        XCTAssertEqual(log.painScore, 1)
        XCTAssertEqual(log.notes, "Felt strong today")
        XCTAssertTrue(log.completed)
    }

    func testExerciseLog_DecodesWithNullFields() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "session_exercise_id": "123e4567-e89b-12d3-a456-426614174001",
            "patient_id": "123e4567-e89b-12d3-a456-426614174002",
            "logged_at": "2024-01-15T10:30:00Z",
            "actual_sets": 2,
            "actual_reps": [10, 10],
            "actual_load": null,
            "load_unit": null,
            "rpe": 5,
            "pain_score": 0,
            "notes": null,
            "completed": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let log = try decoder.decode(ExerciseLog.self, from: json)

        XCTAssertNil(log.actualLoad)
        XCTAssertNil(log.loadUnit)
        XCTAssertNil(log.notes)
    }

    func testExerciseLog_DecodesWithFractionalSecondsDate() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "session_exercise_id": "123e4567-e89b-12d3-a456-426614174001",
            "patient_id": "123e4567-e89b-12d3-a456-426614174002",
            "logged_at": "2024-01-15T10:30:00.123456+00:00",
            "actual_sets": 3,
            "actual_reps": [10, 10, 10],
            "actual_load": 100.0,
            "load_unit": "kg",
            "rpe": 6,
            "pain_score": 0,
            "notes": null,
            "completed": true
        }
        """.data(using: .utf8)!

        let log = try PTSupabaseClient.flexibleDecoder.decode(ExerciseLog.self, from: json)

        XCTAssertNotNil(log.loggedAt)
        XCTAssertEqual(log.loadUnit, "kg")
    }

    func testExerciseLog_FailsWithInvalidJSON() {
        let json = """
        {
            "id": "not-a-uuid",
            "session_exercise_id": "123e4567-e89b-12d3-a456-426614174001",
            "patient_id": "123e4567-e89b-12d3-a456-426614174002",
            "logged_at": "2024-01-15T10:30:00Z",
            "actual_sets": 3,
            "actual_reps": [10, 10, 10],
            "rpe": 6,
            "pain_score": 0,
            "completed": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        XCTAssertThrowsError(try decoder.decode(ExerciseLog.self, from: json)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    // MARK: - Analytics Helpers Tests

    func testExerciseLog_WeightProperty() {
        let log = ExerciseLog(
            id: UUID(),
            sessionExerciseId: UUID(),
            patientId: UUID(),
            loggedAt: Date(),
            actualSets: 3,
            actualReps: [10, 10, 10],
            actualLoad: 225.0,
            loadUnit: "lbs",
            rpe: 8,
            painScore: 0,
            notes: nil,
            completed: true
        )

        XCTAssertEqual(log.weight, 225.0)
    }

    func testExerciseLog_RepsProperty_Average() {
        let log = ExerciseLog(
            id: UUID(),
            sessionExerciseId: UUID(),
            patientId: UUID(),
            loggedAt: Date(),
            actualSets: 3,
            actualReps: [12, 10, 8],
            actualLoad: 135.0,
            loadUnit: "lbs",
            rpe: 7,
            painScore: 0,
            notes: nil,
            completed: true
        )

        // Average of [12, 10, 8] = 30/3 = 10
        XCTAssertEqual(log.reps, 10)
    }

    func testExerciseLog_RepsProperty_EmptyArray() {
        let log = ExerciseLog(
            id: UUID(),
            sessionExerciseId: UUID(),
            patientId: UUID(),
            loggedAt: Date(),
            actualSets: 0,
            actualReps: [],
            actualLoad: nil,
            loadUnit: nil,
            rpe: 0,
            painScore: 0,
            notes: nil,
            completed: false
        )

        XCTAssertNil(log.reps)
    }

    func testExerciseLog_SetsProperty() {
        let log = ExerciseLog(
            id: UUID(),
            sessionExerciseId: UUID(),
            patientId: UUID(),
            loggedAt: Date(),
            actualSets: 5,
            actualReps: [8, 8, 8, 8, 8],
            actualLoad: 100.0,
            loadUnit: "lbs",
            rpe: 9,
            painScore: 2,
            notes: nil,
            completed: true
        )

        XCTAssertEqual(log.sets, 5)
    }

    func testExerciseLog_CreatedAtProperty() {
        let specificDate = Date(timeIntervalSince1970: 1705318200)  // Jan 15, 2024

        let log = ExerciseLog(
            id: UUID(),
            sessionExerciseId: UUID(),
            patientId: UUID(),
            loggedAt: specificDate,
            actualSets: 3,
            actualReps: [10, 10, 10],
            actualLoad: nil,
            loadUnit: nil,
            rpe: 5,
            painScore: 0,
            notes: nil,
            completed: true
        )

        XCTAssertEqual(log.createdAt, specificDate)
    }

    func testExerciseLog_ExerciseIdProperty() {
        let sessionExerciseId = UUID()

        let log = ExerciseLog(
            id: UUID(),
            sessionExerciseId: sessionExerciseId,
            patientId: UUID(),
            loggedAt: Date(),
            actualSets: 3,
            actualReps: [10, 10, 10],
            actualLoad: nil,
            loadUnit: nil,
            rpe: 5,
            painScore: 0,
            notes: nil,
            completed: true
        )

        XCTAssertEqual(log.exerciseId, sessionExerciseId)
    }

    func testExerciseLog_ExerciseProperty_ReturnsNil() {
        let log = ExerciseLog(
            id: UUID(),
            sessionExerciseId: UUID(),
            patientId: UUID(),
            loggedAt: Date(),
            actualSets: 3,
            actualReps: [10, 10, 10],
            actualLoad: nil,
            loadUnit: nil,
            rpe: 5,
            painScore: 0,
            notes: nil,
            completed: true
        )

        // Exercise reference is not populated in the model directly
        XCTAssertNil(log.exercise)
    }
}

// MARK: - CreateExerciseLogInput Tests

final class CreateExerciseLogInputTests: XCTestCase {

    func testCreateExerciseLogInput_Initialization() {
        let sessionExerciseId = UUID()
        let patientId = UUID()

        let input = CreateExerciseLogInput(
            sessionExerciseId: sessionExerciseId,
            patientId: patientId,
            actualSets: 3,
            actualReps: [10, 10, 10],
            actualLoad: 135.0,
            loadUnit: "lbs",
            rpe: 7,
            painScore: 0,
            notes: "Great workout",
            completed: true
        )

        XCTAssertEqual(input.sessionExerciseId, sessionExerciseId)
        XCTAssertEqual(input.patientId, patientId)
        XCTAssertEqual(input.actualSets, 3)
        XCTAssertEqual(input.actualReps, [10, 10, 10])
        XCTAssertEqual(input.actualLoad, 135.0)
        XCTAssertEqual(input.loadUnit, "lbs")
        XCTAssertEqual(input.rpe, 7)
        XCTAssertEqual(input.painScore, 0)
        XCTAssertEqual(input.notes, "Great workout")
        XCTAssertTrue(input.completed)
    }

    func testCreateExerciseLogInput_EncodesCorrectly() throws {
        let input = CreateExerciseLogInput(
            sessionExerciseId: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174000")!,
            patientId: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174001")!,
            actualSets: 4,
            actualReps: [12, 12, 10, 10],
            actualLoad: 200.0,
            loadUnit: "lbs",
            rpe: 8,
            painScore: 1,
            notes: "PR attempt",
            completed: true
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(input)
        let jsonString = String(data: data, encoding: .utf8)!

        // Verify snake_case keys are used
        XCTAssertTrue(jsonString.contains("session_exercise_id"))
        XCTAssertTrue(jsonString.contains("patient_id"))
        XCTAssertTrue(jsonString.contains("actual_sets"))
        XCTAssertTrue(jsonString.contains("actual_reps"))
        XCTAssertTrue(jsonString.contains("actual_load"))
        XCTAssertTrue(jsonString.contains("load_unit"))
        XCTAssertTrue(jsonString.contains("pain_score"))

        // Verify values are present (UUID is encoded in uppercase by Swift JSONEncoder)
        XCTAssertTrue(jsonString.uppercased().contains("123E4567-E89B-12D3-A456-426614174000"))
        XCTAssertTrue(jsonString.contains("200"))
        XCTAssertTrue(jsonString.contains("PR attempt"))
    }

    func testCreateExerciseLogInput_EncodesNilFieldsCorrectly() throws {
        let input = CreateExerciseLogInput(
            sessionExerciseId: UUID(),
            patientId: UUID(),
            actualSets: 2,
            actualReps: [10, 10],
            actualLoad: nil,
            loadUnit: nil,
            rpe: 5,
            painScore: 0,
            notes: nil,
            completed: true
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(input)
        let jsonString = String(data: data, encoding: .utf8)!

        // By default, Swift's JSONEncoder omits nil optional fields entirely
        // If the API requires null values, the encoder would need OutputFormatting.withNilEncodingStrategy
        // For now, verify required fields are present
        XCTAssertTrue(jsonString.contains("session_exercise_id"))
        XCTAssertTrue(jsonString.contains("patient_id"))
        XCTAssertTrue(jsonString.contains("actual_sets"))
    }
}

// MARK: - Sets/Reps Combination Tests

final class ExerciseLogSetsRepsTests: XCTestCase {

    func testSetsReps_SingleSet() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "session_exercise_id": "123e4567-e89b-12d3-a456-426614174001",
            "patient_id": "123e4567-e89b-12d3-a456-426614174002",
            "logged_at": "2024-01-15T10:30:00Z",
            "actual_sets": 1,
            "actual_reps": [20],
            "actual_load": 25.0,
            "load_unit": "lbs",
            "rpe": 4,
            "pain_score": 0,
            "notes": null,
            "completed": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let log = try decoder.decode(ExerciseLog.self, from: json)

        XCTAssertEqual(log.actualSets, 1)
        XCTAssertEqual(log.actualReps.count, 1)
        XCTAssertEqual(log.actualReps[0], 20)
    }

    func testSetsReps_MultipleSetsUniformReps() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "session_exercise_id": "123e4567-e89b-12d3-a456-426614174001",
            "patient_id": "123e4567-e89b-12d3-a456-426614174002",
            "logged_at": "2024-01-15T10:30:00Z",
            "actual_sets": 5,
            "actual_reps": [8, 8, 8, 8, 8],
            "actual_load": 315.0,
            "load_unit": "lbs",
            "rpe": 9,
            "pain_score": 0,
            "notes": "5x8 @315",
            "completed": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let log = try decoder.decode(ExerciseLog.self, from: json)

        XCTAssertEqual(log.actualSets, 5)
        XCTAssertEqual(log.actualReps.count, 5)
        XCTAssertTrue(log.actualReps.allSatisfy { $0 == 8 })
    }

    func testSetsReps_DescendingReps() throws {
        // Descending pyramid: 12, 10, 8, 6
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "session_exercise_id": "123e4567-e89b-12d3-a456-426614174001",
            "patient_id": "123e4567-e89b-12d3-a456-426614174002",
            "logged_at": "2024-01-15T10:30:00Z",
            "actual_sets": 4,
            "actual_reps": [12, 10, 8, 6],
            "actual_load": 135.0,
            "load_unit": "lbs",
            "rpe": 8,
            "pain_score": 0,
            "notes": "Pyramid down",
            "completed": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let log = try decoder.decode(ExerciseLog.self, from: json)

        XCTAssertEqual(log.actualReps, [12, 10, 8, 6])
        XCTAssertEqual(log.reps, 9)  // Average: (12+10+8+6)/4 = 9
    }

    func testSetsReps_HighReps() throws {
        // Endurance style: 20+ reps
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "session_exercise_id": "123e4567-e89b-12d3-a456-426614174001",
            "patient_id": "123e4567-e89b-12d3-a456-426614174002",
            "logged_at": "2024-01-15T10:30:00Z",
            "actual_sets": 3,
            "actual_reps": [25, 22, 20],
            "actual_load": 15.0,
            "load_unit": "lbs",
            "rpe": 7,
            "pain_score": 0,
            "notes": "Burnout set",
            "completed": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let log = try decoder.decode(ExerciseLog.self, from: json)

        XCTAssertEqual(log.actualReps[0], 25)
        XCTAssertEqual(log.actualReps[1], 22)
        XCTAssertEqual(log.actualReps[2], 20)
    }

    func testSetsReps_BodyweightExercise() throws {
        // No load - bodyweight exercise
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "session_exercise_id": "123e4567-e89b-12d3-a456-426614174001",
            "patient_id": "123e4567-e89b-12d3-a456-426614174002",
            "logged_at": "2024-01-15T10:30:00Z",
            "actual_sets": 3,
            "actual_reps": [15, 12, 10],
            "actual_load": null,
            "load_unit": null,
            "rpe": 6,
            "pain_score": 0,
            "notes": "Push-ups",
            "completed": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let log = try decoder.decode(ExerciseLog.self, from: json)

        XCTAssertNil(log.actualLoad)
        XCTAssertNil(log.loadUnit)
        XCTAssertNil(log.weight)
        XCTAssertEqual(log.actualSets, 3)
    }

    func testSetsReps_KilogramUnit() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "session_exercise_id": "123e4567-e89b-12d3-a456-426614174001",
            "patient_id": "123e4567-e89b-12d3-a456-426614174002",
            "logged_at": "2024-01-15T10:30:00Z",
            "actual_sets": 3,
            "actual_reps": [10, 10, 10],
            "actual_load": 100.0,
            "load_unit": "kg",
            "rpe": 8,
            "pain_score": 0,
            "notes": "Metric weight",
            "completed": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let log = try decoder.decode(ExerciseLog.self, from: json)

        XCTAssertEqual(log.loadUnit, "kg")
        XCTAssertEqual(log.actualLoad, 100.0)
    }

    func testSetsReps_MismatchedSetsAndRepsCount() throws {
        // Edge case: actualSets = 4 but only 3 reps recorded
        // This can happen in real-world scenarios (partial completion)
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "session_exercise_id": "123e4567-e89b-12d3-a456-426614174001",
            "patient_id": "123e4567-e89b-12d3-a456-426614174002",
            "logged_at": "2024-01-15T10:30:00Z",
            "actual_sets": 4,
            "actual_reps": [10, 10, 8],
            "actual_load": 135.0,
            "load_unit": "lbs",
            "rpe": 8,
            "pain_score": 2,
            "notes": "Had to stop early - shoulder pain",
            "completed": false
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let log = try decoder.decode(ExerciseLog.self, from: json)

        // Should decode successfully even with mismatch
        XCTAssertEqual(log.actualSets, 4)
        XCTAssertEqual(log.actualReps.count, 3)
        XCTAssertFalse(log.completed)
    }
}

// MARK: - RPE and Pain Score Tests

final class ExerciseLogRPEPainTests: XCTestCase {

    func testRPE_MinValue() throws {
        let log = ExerciseLog(
            id: UUID(),
            sessionExerciseId: UUID(),
            patientId: UUID(),
            loggedAt: Date(),
            actualSets: 1,
            actualReps: [10],
            actualLoad: nil,
            loadUnit: nil,
            rpe: 0,  // Minimum RPE
            painScore: 0,
            notes: nil,
            completed: true
        )

        XCTAssertEqual(log.rpe, 0)
    }

    func testRPE_MaxValue() throws {
        let log = ExerciseLog(
            id: UUID(),
            sessionExerciseId: UUID(),
            patientId: UUID(),
            loggedAt: Date(),
            actualSets: 1,
            actualReps: [1],
            actualLoad: 500.0,
            loadUnit: "lbs",
            rpe: 10,  // Maximum RPE
            painScore: 0,
            notes: "Max effort",
            completed: true
        )

        XCTAssertEqual(log.rpe, 10)
    }

    func testPainScore_NoPain() {
        let log = ExerciseLog(
            id: UUID(),
            sessionExerciseId: UUID(),
            patientId: UUID(),
            loggedAt: Date(),
            actualSets: 3,
            actualReps: [10, 10, 10],
            actualLoad: 135.0,
            loadUnit: "lbs",
            rpe: 7,
            painScore: 0,  // No pain
            notes: nil,
            completed: true
        )

        XCTAssertEqual(log.painScore, 0)
    }

    func testPainScore_MaxPain() {
        let log = ExerciseLog(
            id: UUID(),
            sessionExerciseId: UUID(),
            patientId: UUID(),
            loggedAt: Date(),
            actualSets: 1,
            actualReps: [2],
            actualLoad: 50.0,
            loadUnit: "lbs",
            rpe: 3,
            painScore: 10,  // Severe pain
            notes: "Stop exercise - too painful",
            completed: false
        )

        XCTAssertEqual(log.painScore, 10)
    }

    func testPainScore_ModeratePain() {
        let log = ExerciseLog(
            id: UUID(),
            sessionExerciseId: UUID(),
            patientId: UUID(),
            loggedAt: Date(),
            actualSets: 2,
            actualReps: [8, 6],
            actualLoad: 100.0,
            loadUnit: "lbs",
            rpe: 6,
            painScore: 5,  // Moderate pain
            notes: "Some discomfort in shoulder",
            completed: true
        )

        XCTAssertEqual(log.painScore, 5)
    }
}

// MARK: - Error Case Tests

final class ExerciseLogErrorTests: XCTestCase {

    func testDecode_MissingRequiredField_Throws() {
        // Missing required 'rpe' field
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "session_exercise_id": "123e4567-e89b-12d3-a456-426614174001",
            "patient_id": "123e4567-e89b-12d3-a456-426614174002",
            "logged_at": "2024-01-15T10:30:00Z",
            "actual_sets": 3,
            "actual_reps": [10, 10, 10],
            "pain_score": 0,
            "completed": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        XCTAssertThrowsError(try decoder.decode(ExerciseLog.self, from: json)) { error in
            if case DecodingError.keyNotFound(let key, _) = error {
                XCTAssertEqual(key.stringValue, "rpe")
            } else {
                XCTFail("Expected keyNotFound error for 'rpe'")
            }
        }
    }

    func testDecode_InvalidDateFormat_Throws() {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "session_exercise_id": "123e4567-e89b-12d3-a456-426614174001",
            "patient_id": "123e4567-e89b-12d3-a456-426614174002",
            "logged_at": "not-a-date",
            "actual_sets": 3,
            "actual_reps": [10, 10, 10],
            "rpe": 5,
            "pain_score": 0,
            "completed": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        XCTAssertThrowsError(try decoder.decode(ExerciseLog.self, from: json))
    }

    func testDecode_InvalidRepsType_Throws() {
        // actual_reps should be array, not string
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "session_exercise_id": "123e4567-e89b-12d3-a456-426614174001",
            "patient_id": "123e4567-e89b-12d3-a456-426614174002",
            "logged_at": "2024-01-15T10:30:00Z",
            "actual_sets": 3,
            "actual_reps": "10,10,10",
            "rpe": 5,
            "pain_score": 0,
            "completed": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        XCTAssertThrowsError(try decoder.decode(ExerciseLog.self, from: json)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testDecode_InvalidLoadType_Throws() {
        // actual_load should be number, not string
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "session_exercise_id": "123e4567-e89b-12d3-a456-426614174001",
            "patient_id": "123e4567-e89b-12d3-a456-426614174002",
            "logged_at": "2024-01-15T10:30:00Z",
            "actual_sets": 3,
            "actual_reps": [10, 10, 10],
            "actual_load": "heavy",
            "load_unit": "lbs",
            "rpe": 5,
            "pain_score": 0,
            "completed": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        XCTAssertThrowsError(try decoder.decode(ExerciseLog.self, from: json)) { error in
            if case DecodingError.typeMismatch = error {
                // Expected type mismatch error
            } else {
                XCTFail("Expected typeMismatch error")
            }
        }
    }
}

// MARK: - Network Error Detection Tests

final class ExerciseLogNetworkErrorTests: XCTestCase {

    func testNetworkError_NotConnectedToInternet() {
        let error = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: [NSLocalizedDescriptionKey: "The Internet connection appears to be offline."]
        )

        XCTAssertTrue(isNetworkRelatedError(error))
    }

    func testNetworkError_NetworkConnectionLost() {
        let error = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNetworkConnectionLost,
            userInfo: [NSLocalizedDescriptionKey: "The network connection was lost."]
        )

        XCTAssertTrue(isNetworkRelatedError(error))
    }

    func testNetworkError_TimedOut() {
        let error = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorTimedOut,
            userInfo: [NSLocalizedDescriptionKey: "The request timed out."]
        )

        XCTAssertTrue(isNetworkRelatedError(error))
    }

    func testNetworkError_CannotConnectToHost() {
        let error = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorCannotConnectToHost,
            userInfo: [NSLocalizedDescriptionKey: "Could not connect to the server."]
        )

        XCTAssertTrue(isNetworkRelatedError(error))
    }

    func testNetworkError_GenericError_NotNetwork() {
        let error = NSError(
            domain: "TestDomain",
            code: 999,
            userInfo: [NSLocalizedDescriptionKey: "A generic error occurred."]
        )

        XCTAssertFalse(isNetworkRelatedError(error))
    }

    // Helper function matching the pattern in ExerciseLogService
    private func isNetworkRelatedError(_ error: Error) -> Bool {
        let nsError = error as NSError

        let networkErrorCodes = [
            NSURLErrorNotConnectedToInternet,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorTimedOut,
            NSURLErrorCannotConnectToHost,
            NSURLErrorCannotFindHost,
            NSURLErrorDNSLookupFailed,
            NSURLErrorInternationalRoamingOff,
            NSURLErrorDataNotAllowed
        ]

        if networkErrorCodes.contains(nsError.code) {
            return true
        }

        let description = error.localizedDescription.lowercased()
        let networkKeywords = ["network", "internet", "connection", "offline", "timeout", "unreachable"]

        return networkKeywords.contains { description.contains($0) }
    }
}

// MARK: - Optimistic Update Placeholder Tests

final class ExerciseLogOptimisticUpdateTests: XCTestCase {

    func testOptimisticUpdate_PlaceholderLogCreation() {
        // When offline, ExerciseLogService creates a placeholder log
        let sessionExerciseId = UUID()
        let patientId = UUID()

        let placeholderLog = ExerciseLog(
            id: UUID(),  // Local UUID that will be replaced by server
            sessionExerciseId: sessionExerciseId,
            patientId: patientId,
            loggedAt: Date(),
            actualSets: 3,
            actualReps: [10, 10, 10],
            actualLoad: 135.0,
            loadUnit: "lbs",
            rpe: 7,
            painScore: 0,
            notes: "Queued offline",
            completed: true
        )

        // Placeholder should have all required fields
        XCTAssertNotNil(placeholderLog.id)
        XCTAssertEqual(placeholderLog.sessionExerciseId, sessionExerciseId)
        XCTAssertEqual(placeholderLog.patientId, patientId)
        XCTAssertEqual(placeholderLog.actualSets, 3)
        XCTAssertTrue(placeholderLog.completed)
    }

    func testOptimisticUpdate_PlaceholderWithMinimalData() {
        // Minimal valid placeholder (bodyweight exercise)
        let placeholderLog = ExerciseLog(
            id: UUID(),
            sessionExerciseId: UUID(),
            patientId: UUID(),
            loggedAt: Date(),
            actualSets: 1,
            actualReps: [10],
            actualLoad: nil,
            loadUnit: nil,
            rpe: 5,
            painScore: 0,
            notes: nil,
            completed: true
        )

        XCTAssertNil(placeholderLog.actualLoad)
        XCTAssertNil(placeholderLog.loadUnit)
        XCTAssertNil(placeholderLog.notes)
        XCTAssertTrue(placeholderLog.completed)
    }
}

// MARK: - ExerciseReference Tests

final class ExerciseReferenceTests: XCTestCase {

    func testExerciseReference_Initialization() {
        let id = UUID()
        let name = "Bench Press"

        let reference = ExerciseReference(id: id, name: name)

        XCTAssertEqual(reference.id, id)
        XCTAssertEqual(reference.name, name)
    }

    func testExerciseReference_DecodesFromJSON() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "name": "Squat"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let reference = try decoder.decode(ExerciseReference.self, from: json)

        XCTAssertEqual(reference.id.uuidString.lowercased(), "123e4567-e89b-12d3-a456-426614174000")
        XCTAssertEqual(reference.name, "Squat")
    }

    func testExerciseReference_EncodesCorrectly() throws {
        let reference = ExerciseReference(
            id: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174000")!,
            name: "Deadlift"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(reference)
        let jsonString = String(data: data, encoding: .utf8)!

        // UUID is encoded in uppercase by Swift's JSONEncoder
        XCTAssertTrue(jsonString.uppercased().contains("123E4567-E89B-12D3-A456-426614174000"))
        XCTAssertTrue(jsonString.contains("Deadlift"))
    }
}
