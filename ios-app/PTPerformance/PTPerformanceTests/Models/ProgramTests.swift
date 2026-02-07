//
//  ProgramTests.swift
//  PTPerformanceTests
//
//  Unit tests for Program, Phase, ProgramSession, and ProgramExercise models.
//  Tests encoding/decoding, status transitions, and phase relationships.
//

import XCTest
@testable import PTPerformance

// MARK: - Program Model Tests

final class ProgramModelTests: XCTestCase {

    // MARK: - Basic Initialization Tests

    func testProgram_Initialization() {
        let id = UUID()
        let patientId = UUID()
        let program = createMockProgram(id: id, patientId: patientId)

        XCTAssertEqual(program.id, id)
        XCTAssertEqual(program.patientId, patientId)
        XCTAssertEqual(program.name, "Test Program")
        XCTAssertEqual(program.targetLevel, "intermediate")
        XCTAssertEqual(program.durationWeeks, 12)
    }

    func testProgram_Identifiable() {
        let program = createMockProgram()
        XCTAssertNotNil(program.id, "Program should have an id for Identifiable conformance")
    }

    func testProgram_Hashable() {
        let program1 = createMockProgram()
        let program2 = createMockProgram()

        var set = Set<Program>()
        set.insert(program1)
        set.insert(program2)

        XCTAssertEqual(set.count, 2, "Different programs should have different hashes")
    }

    func testProgram_Equatable_SameValues() {
        let id = UUID()
        let patientId = UUID()
        let date = Date()

        let program1 = Program(
            id: id,
            patientId: patientId,
            name: "Test",
            targetLevel: "beginner",
            durationWeeks: 8,
            createdAt: date,
            status: "active",
            programType: .rehab
        )

        let program2 = Program(
            id: id,
            patientId: patientId,
            name: "Test",
            targetLevel: "beginner",
            durationWeeks: 8,
            createdAt: date,
            status: "active",
            programType: .rehab
        )

        XCTAssertEqual(program1, program2, "Programs with same values should be equal")
    }

    func testProgram_Equatable_DifferentIds() {
        let program1 = createMockProgram()
        let program2 = createMockProgram()

        XCTAssertNotEqual(program1, program2, "Programs with different IDs should not be equal")
    }

    // MARK: - Status Tests

    func testProgram_Status_Active() {
        let program = createMockProgram(status: "active")
        XCTAssertEqual(program.status, "active")
    }

    func testProgram_Status_Completed() {
        let program = createMockProgram(status: "completed")
        XCTAssertEqual(program.status, "completed")
    }

    func testProgram_Status_Paused() {
        let program = createMockProgram(status: "paused")
        XCTAssertEqual(program.status, "paused")
    }

    func testProgram_Status_Draft() {
        let program = createMockProgram(status: "draft")
        XCTAssertEqual(program.status, "draft")
    }

    func testProgram_Status_Nil() {
        let program = createMockProgram(status: nil)
        XCTAssertNil(program.status, "Status should be nil for legacy programs")
    }

    // MARK: - Program Type Tests

    func testProgram_ProgramType_Rehab() {
        let program = createMockProgram(programType: .rehab)
        XCTAssertEqual(program.programType, .rehab)
        XCTAssertEqual(program.resolvedProgramType, .rehab)
    }

    func testProgram_ProgramType_Performance() {
        let program = createMockProgram(programType: .performance)
        XCTAssertEqual(program.programType, .performance)
        XCTAssertEqual(program.resolvedProgramType, .performance)
    }

    func testProgram_ProgramType_Lifestyle() {
        let program = createMockProgram(programType: .lifestyle)
        XCTAssertEqual(program.programType, .lifestyle)
        XCTAssertEqual(program.resolvedProgramType, .lifestyle)
    }

    func testProgram_ProgramType_Nil_DefaultsToRehab() {
        let program = createMockProgram(programType: nil)
        XCTAssertNil(program.programType)
        XCTAssertEqual(program.resolvedProgramType, .rehab, "Nil programType should default to rehab")
    }

    // MARK: - Encoding/Decoding Tests

    func testProgram_Encoding() throws {
        let program = createMockProgram()
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(program)
        let jsonString = String(data: data, encoding: .utf8)

        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("patient_id"), "Should use snake_case for patient_id")
        XCTAssertTrue(jsonString!.contains("target_level"), "Should use snake_case for target_level")
        XCTAssertTrue(jsonString!.contains("duration_weeks"), "Should use snake_case for duration_weeks")
        XCTAssertTrue(jsonString!.contains("created_at"), "Should use snake_case for created_at")
    }

    func testProgram_Decoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "550e8400-e29b-41d4-a716-446655440001",
            "name": "ACL Rehab Program",
            "target_level": "advanced",
            "duration_weeks": 16,
            "created_at": "2024-01-15T12:00:00Z",
            "status": "active",
            "program_type": "rehab"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        // Program has explicit CodingKeys that handle snake_case
        decoder.dateDecodingStrategy = .iso8601

        let program = try decoder.decode(Program.self, from: json)

        XCTAssertEqual(program.id.uuidString.uppercased(), "550E8400-E29B-41D4-A716-446655440000")
        XCTAssertEqual(program.name, "ACL Rehab Program")
        XCTAssertEqual(program.targetLevel, "advanced")
        XCTAssertEqual(program.durationWeeks, 16)
        XCTAssertEqual(program.status, "active")
        XCTAssertEqual(program.programType, .rehab)
    }

    func testProgram_Decoding_WithOptionalFieldsMissing() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "550e8400-e29b-41d4-a716-446655440001",
            "name": "Basic Program",
            "target_level": "beginner",
            "duration_weeks": 8,
            "created_at": "2024-01-15T12:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        // Program has explicit CodingKeys that handle snake_case
        decoder.dateDecodingStrategy = .iso8601

        let program = try decoder.decode(Program.self, from: json)

        XCTAssertNil(program.status, "Status should be nil when not provided")
        XCTAssertNil(program.programType, "ProgramType should be nil when not provided")
        XCTAssertEqual(program.resolvedProgramType, .rehab, "Should default to rehab")
    }

    func testProgram_RoundTrip() throws {
        let original = createMockProgram(
            status: "active",
            programType: .performance
        )

        // Program has explicit CodingKeys that handle snake_case encoding/decoding
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(Program.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.patientId, decoded.patientId)
        XCTAssertEqual(original.name, decoded.name)
        XCTAssertEqual(original.targetLevel, decoded.targetLevel)
        XCTAssertEqual(original.durationWeeks, decoded.durationWeeks)
        XCTAssertEqual(original.status, decoded.status)
        XCTAssertEqual(original.programType, decoded.programType)
    }

    // MARK: - Edge Cases

    func testProgram_EmptyName() {
        let program = Program(
            id: UUID(),
            patientId: UUID(),
            name: "",
            targetLevel: "beginner",
            durationWeeks: 4,
            createdAt: Date(),
            status: nil,
            programType: nil
        )

        XCTAssertEqual(program.name, "")
    }

    func testProgram_ZeroDurationWeeks() {
        let program = Program(
            id: UUID(),
            patientId: UUID(),
            name: "Quick Program",
            targetLevel: "beginner",
            durationWeeks: 0,
            createdAt: Date(),
            status: nil,
            programType: nil
        )

        XCTAssertEqual(program.durationWeeks, 0)
    }

    func testProgram_LargeDurationWeeks() {
        let program = Program(
            id: UUID(),
            patientId: UUID(),
            name: "Long Program",
            targetLevel: "advanced",
            durationWeeks: 52,
            createdAt: Date(),
            status: nil,
            programType: nil
        )

        XCTAssertEqual(program.durationWeeks, 52)
    }

    // MARK: - Helper Methods

    private func createMockProgram(
        id: UUID = UUID(),
        patientId: UUID = UUID(),
        name: String = "Test Program",
        targetLevel: String = "intermediate",
        durationWeeks: Int = 12,
        createdAt: Date = Date(),
        status: String? = "active",
        programType: ProgramType? = .rehab
    ) -> Program {
        Program(
            id: id,
            patientId: patientId,
            name: name,
            targetLevel: targetLevel,
            durationWeeks: durationWeeks,
            createdAt: createdAt,
            status: status,
            programType: programType
        )
    }
}

// MARK: - ProgramType Tests

final class ProgramTypeTests: XCTestCase {

    func testProgramType_AllCases() {
        let allCases = ProgramType.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.rehab))
        XCTAssertTrue(allCases.contains(.performance))
        XCTAssertTrue(allCases.contains(.lifestyle))
    }

    func testProgramType_RawValues() {
        XCTAssertEqual(ProgramType.rehab.rawValue, "rehab")
        XCTAssertEqual(ProgramType.performance.rawValue, "performance")
        XCTAssertEqual(ProgramType.lifestyle.rawValue, "lifestyle")
    }

    func testProgramType_DisplayNames() {
        XCTAssertEqual(ProgramType.rehab.displayName, "Rehab")
        XCTAssertEqual(ProgramType.performance.displayName, "Performance")
        XCTAssertEqual(ProgramType.lifestyle.displayName, "Lifestyle")
    }

    func testProgramType_Descriptions() {
        XCTAssertTrue(ProgramType.rehab.description.contains("Rehabilitation"))
        XCTAssertTrue(ProgramType.performance.description.contains("Athletic"))
        XCTAssertTrue(ProgramType.lifestyle.description.contains("wellness"))
    }

    func testProgramType_Icons() {
        XCTAssertFalse(ProgramType.rehab.icon.isEmpty)
        XCTAssertFalse(ProgramType.performance.icon.isEmpty)
        XCTAssertFalse(ProgramType.lifestyle.icon.isEmpty)
    }

    func testProgramType_Colors() {
        // Just verify colors are accessible without crashing
        _ = ProgramType.rehab.color
        _ = ProgramType.performance.color
        _ = ProgramType.lifestyle.color
    }

    func testProgramType_Identifiable() {
        XCTAssertEqual(ProgramType.rehab.id, "rehab")
        XCTAssertEqual(ProgramType.performance.id, "performance")
        XCTAssertEqual(ProgramType.lifestyle.id, "lifestyle")
    }

    func testProgramType_Encoding() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(ProgramType.performance)
        let string = String(data: data, encoding: .utf8)

        XCTAssertEqual(string, "\"performance\"")
    }

    func testProgramType_Decoding() throws {
        let json = "\"lifestyle\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        let programType = try decoder.decode(ProgramType.self, from: json)

        XCTAssertEqual(programType, .lifestyle)
    }

    func testProgramType_AllowedProtocolCategories() {
        XCTAssertTrue(ProgramType.rehab.allowedProtocolCategories.contains(.postSurgical))
        XCTAssertTrue(ProgramType.performance.allowedProtocolCategories.contains(.returnToSport))
        XCTAssertTrue(ProgramType.lifestyle.allowedProtocolCategories.contains(.lifestyle))
    }
}

// MARK: - ProgramSession Tests

final class ProgramSessionTests: XCTestCase {

    func testProgramSession_Initialization() {
        let id = UUID()
        let phaseId = UUID()

        let session = ProgramSession(
            id: id,
            phaseId: phaseId,
            sessionNumber: 1,
            sessionDate: Date(),
            completed: false,
            exerciseCount: 5
        )

        XCTAssertEqual(session.id, id)
        XCTAssertEqual(session.phaseId, phaseId)
        XCTAssertEqual(session.sessionNumber, 1)
        XCTAssertEqual(session.completed, false)
        XCTAssertEqual(session.exerciseCount, 5)
    }

    func testProgramSession_OptionalFields() {
        let session = ProgramSession(
            id: UUID(),
            phaseId: UUID(),
            sessionNumber: nil,
            sessionDate: nil,
            completed: nil,
            exerciseCount: nil
        )

        XCTAssertNil(session.sessionNumber)
        XCTAssertNil(session.sessionDate)
        XCTAssertNil(session.completed)
        XCTAssertNil(session.exerciseCount)
    }

    func testProgramSession_Decoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "phase_id": "550e8400-e29b-41d4-a716-446655440001",
            "session_number": 3,
            "session_date": "2024-01-20T10:00:00Z",
            "completed": true,
            "exercise_count": 8
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        // ProgramSession has explicit CodingKeys that handle snake_case
        decoder.dateDecodingStrategy = .iso8601

        let session = try decoder.decode(ProgramSession.self, from: json)

        XCTAssertEqual(session.sessionNumber, 3)
        XCTAssertEqual(session.completed, true)
        XCTAssertEqual(session.exerciseCount, 8)
    }

    func testProgramSession_Identifiable() {
        let session = ProgramSession(
            id: UUID(),
            phaseId: UUID(),
            sessionNumber: 1,
            sessionDate: nil,
            completed: nil,
            exerciseCount: nil
        )

        XCTAssertNotNil(session.id)
    }

    func testProgramSession_Hashable() {
        let session1 = ProgramSession(
            id: UUID(),
            phaseId: UUID(),
            sessionNumber: 1,
            sessionDate: nil,
            completed: nil,
            exerciseCount: nil
        )

        let session2 = ProgramSession(
            id: UUID(),
            phaseId: UUID(),
            sessionNumber: 2,
            sessionDate: nil,
            completed: nil,
            exerciseCount: nil
        )

        var set = Set<ProgramSession>()
        set.insert(session1)
        set.insert(session2)

        XCTAssertEqual(set.count, 2)
    }
}

// MARK: - ProgramExercise Tests

final class ProgramExerciseTests: XCTestCase {

    func testProgramExercise_Decoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "session_id": "550e8400-e29b-41d4-a716-446655440001",
            "exercise_templates": {
                "exercise_name": "Barbell Squat"
            },
            "prescribed_sets": 4,
            "prescribed_reps": "8-10",
            "prescribed_load": 135.0,
            "load_unit": "lbs",
            "rest_period_seconds": 90,
            "order_index": 0
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        // ProgramExercise has explicit CodingKeys and custom decoder

        let exercise = try decoder.decode(ProgramExercise.self, from: json)

        XCTAssertEqual(exercise.exerciseName, "Barbell Squat")
        XCTAssertEqual(exercise.sets, 4)
        XCTAssertEqual(exercise.reps, "8-10")
        XCTAssertEqual(exercise.load, 135.0)
        XCTAssertEqual(exercise.loadUnit, "lbs")
        XCTAssertEqual(exercise.restPeriod, 90)
        XCTAssertEqual(exercise.orderIndex, 0)
    }

    func testProgramExercise_Decoding_WithOptionalFieldsNil() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "session_id": "550e8400-e29b-41d4-a716-446655440001",
            "exercise_templates": {
                "exercise_name": "Bodyweight Squat"
            },
            "prescribed_sets": 3,
            "prescribed_reps": "15",
            "order_index": 1
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        // ProgramExercise has explicit CodingKeys and custom decoder

        let exercise = try decoder.decode(ProgramExercise.self, from: json)

        XCTAssertEqual(exercise.exerciseName, "Bodyweight Squat")
        XCTAssertNil(exercise.load)
        XCTAssertNil(exercise.loadUnit)
        XCTAssertNil(exercise.restPeriod)
    }

    func testProgramExercise_Identifiable() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "session_id": "550e8400-e29b-41d4-a716-446655440001",
            "exercise_templates": { "exercise_name": "Test" },
            "prescribed_sets": 3,
            "prescribed_reps": "10",
            "order_index": 0
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        // ProgramExercise has explicit CodingKeys and custom decoder

        let exercise = try decoder.decode(ProgramExercise.self, from: json)

        XCTAssertNotNil(exercise.id)
    }

    func testProgramExercise_Hashable() throws {
        let json1 = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "session_id": "550e8400-e29b-41d4-a716-446655440001",
            "exercise_templates": { "exercise_name": "Exercise 1" },
            "prescribed_sets": 3,
            "prescribed_reps": "10",
            "order_index": 0
        }
        """.data(using: .utf8)!

        let json2 = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440002",
            "session_id": "550e8400-e29b-41d4-a716-446655440001",
            "exercise_templates": { "exercise_name": "Exercise 2" },
            "prescribed_sets": 4,
            "prescribed_reps": "8",
            "order_index": 1
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        // ProgramExercise has explicit CodingKeys and custom decoder

        let exercise1 = try decoder.decode(ProgramExercise.self, from: json1)
        let exercise2 = try decoder.decode(ProgramExercise.self, from: json2)

        var set = Set<ProgramExercise>()
        set.insert(exercise1)
        set.insert(exercise2)

        XCTAssertEqual(set.count, 2)
    }
}
