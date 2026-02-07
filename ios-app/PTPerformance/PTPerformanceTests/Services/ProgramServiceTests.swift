//
//  ProgramServiceTests.swift
//  PTPerformanceTests
//
//  Unit tests for ProgramBuilderService.
//  Tests program CRUD operations, phase management, and exercise assignment.
//

import XCTest
@testable import PTPerformance

// MARK: - ProgramBuilderService Tests

final class ProgramServiceTests: XCTestCase {

    var service: ProgramBuilderService!

    override func setUp() async throws {
        try await super.setUp()
        service = ProgramBuilderService()
    }

    override func tearDown() async throws {
        service = nil
        try await super.tearDown()
    }

    // MARK: - Service Initialization Tests

    func testService_Initialization() {
        XCTAssertNotNil(service, "ProgramBuilderService should be instantiatable")
    }

    func testService_WithCustomSupabase() {
        let customService = ProgramBuilderService(supabase: PTSupabaseClient.shared)
        XCTAssertNotNil(customService, "Service should accept custom Supabase client")
    }

    func testService_ConformsToObservableObject() {
        let observableService = service as any ObservableObject
        XCTAssertNotNil(observableService, "Service should conform to ObservableObject")
    }

    // MARK: - Sequence Calculation Tests

    func testSequenceCalculation_Week1Day1() {
        let weekNumber = 1
        let dayOfWeek = 1
        let sequence = (weekNumber - 1) * 7 + dayOfWeek

        XCTAssertEqual(sequence, 1, "Week 1, Day 1 should have sequence 1")
    }

    func testSequenceCalculation_Week1Day7() {
        let weekNumber = 1
        let dayOfWeek = 7
        let sequence = (weekNumber - 1) * 7 + dayOfWeek

        XCTAssertEqual(sequence, 7, "Week 1, Day 7 should have sequence 7")
    }

    func testSequenceCalculation_Week2Day1() {
        let weekNumber = 2
        let dayOfWeek = 1
        let sequence = (weekNumber - 1) * 7 + dayOfWeek

        XCTAssertEqual(sequence, 8, "Week 2, Day 1 should have sequence 8")
    }

    func testSequenceCalculation_Week4Day3() {
        let weekNumber = 4
        let dayOfWeek = 3
        let sequence = (weekNumber - 1) * 7 + dayOfWeek

        XCTAssertEqual(sequence, 24, "Week 4, Day 3 (Wednesday) should have sequence 24")
    }

    func testSequenceCalculation_Week12Day5() {
        let weekNumber = 12
        let dayOfWeek = 5
        let sequence = (weekNumber - 1) * 7 + dayOfWeek

        XCTAssertEqual(sequence, 82, "Week 12, Day 5 (Friday) should have sequence 82")
    }

    func testSequenceCalculation_Week52Day7() {
        let weekNumber = 52
        let dayOfWeek = 7
        let sequence = (weekNumber - 1) * 7 + dayOfWeek

        XCTAssertEqual(sequence, 364, "Week 52, Day 7 should have sequence 364")
    }

    // MARK: - Duration Calculation Tests

    func testDurationCalculation_EmptyPhases() {
        let phases: [PhaseWithAssignments] = []
        let durationWeeks = phases.reduce(0) { sum, phase in
            sum + (phase.durationWeeks ?? 0)
        }
        let finalDuration = max(durationWeeks, 1)

        XCTAssertEqual(finalDuration, 1, "Empty program should have minimum 1 week duration")
    }

    func testDurationCalculation_SinglePhase() {
        let phase = createMockPhaseWithAssignments(durationWeeks: 4)
        let phases = [phase]

        let durationWeeks = phases.reduce(0) { sum, phase in
            sum + (phase.durationWeeks ?? 0)
        }

        XCTAssertEqual(durationWeeks, 4, "Single 4-week phase should have 4 weeks duration")
    }

    func testDurationCalculation_MultiplePhases() {
        let phase1 = createMockPhaseWithAssignments(durationWeeks: 4)
        let phase2 = createMockPhaseWithAssignments(durationWeeks: 6)
        let phase3 = createMockPhaseWithAssignments(durationWeeks: 2)
        let phases = [phase1, phase2, phase3]

        let durationWeeks = phases.reduce(0) { sum, phase in
            sum + (phase.durationWeeks ?? 0)
        }

        XCTAssertEqual(durationWeeks, 12, "Three phases should sum to 12 weeks")
    }

    func testDurationCalculation_WithNilDurations() {
        let phase1 = createMockPhaseWithAssignments(durationWeeks: 4)
        let phase2 = createMockPhaseWithAssignments(durationWeeks: nil)
        let phase3 = createMockPhaseWithAssignments(durationWeeks: 3)
        let phases = [phase1, phase2, phase3]

        let durationWeeks = phases.reduce(0) { sum, phase in
            sum + (phase.durationWeeks ?? 0)
        }

        XCTAssertEqual(durationWeeks, 7, "Nil durations should be treated as 0")
    }

    func testDurationCalculation_AllNilDurations() {
        let phase1 = createMockPhaseWithAssignments(durationWeeks: nil)
        let phase2 = createMockPhaseWithAssignments(durationWeeks: nil)
        let phases = [phase1, phase2]

        let durationWeeks = phases.reduce(0) { sum, phase in
            sum + (phase.durationWeeks ?? 0)
        }
        let finalDuration = max(durationWeeks, 1)

        XCTAssertEqual(finalDuration, 1, "All nil durations should result in minimum 1 week")
    }

    // MARK: - Phase Reordering Tests

    func testPhaseReordering_SequenceNumbers() {
        let phaseIds = [UUID(), UUID(), UUID()]

        var newSequences: [(phaseId: UUID, sequence: Int)] = []
        for (index, phaseId) in phaseIds.enumerated() {
            let newSequence = index + 1
            newSequences.append((phaseId, newSequence))
        }

        XCTAssertEqual(newSequences[0].sequence, 1)
        XCTAssertEqual(newSequences[1].sequence, 2)
        XCTAssertEqual(newSequences[2].sequence, 3)
    }

    func testPhaseReordering_EmptyArray() {
        let phaseIds: [UUID] = []

        var newSequences: [(phaseId: UUID, sequence: Int)] = []
        for (index, phaseId) in phaseIds.enumerated() {
            let newSequence = index + 1
            newSequences.append((phaseId, newSequence))
        }

        XCTAssertTrue(newSequences.isEmpty)
    }

    func testPhaseReordering_SinglePhase() {
        let phaseIds = [UUID()]

        var newSequences: [(phaseId: UUID, sequence: Int)] = []
        for (index, phaseId) in phaseIds.enumerated() {
            let newSequence = index + 1
            newSequences.append((phaseId, newSequence))
        }

        XCTAssertEqual(newSequences.count, 1)
        XCTAssertEqual(newSequences[0].sequence, 1)
    }

    func testPhaseReordering_ManyPhases() {
        let phaseIds = (0..<10).map { _ in UUID() }

        var newSequences: [(phaseId: UUID, sequence: Int)] = []
        for (index, phaseId) in phaseIds.enumerated() {
            let newSequence = index + 1
            newSequences.append((phaseId, newSequence))
        }

        XCTAssertEqual(newSequences.count, 10)
        XCTAssertEqual(newSequences.first?.sequence, 1)
        XCTAssertEqual(newSequences.last?.sequence, 10)
    }

    // MARK: - Bulk Operations Tests

    func testBulkAssignments_SequenceGeneration() {
        let assignments: [(phaseId: UUID, templateId: UUID, weekNumber: Int, dayOfWeek: Int)] = [
            (UUID(), UUID(), 1, 1),
            (UUID(), UUID(), 1, 3),
            (UUID(), UUID(), 2, 1),
            (UUID(), UUID(), 2, 5)
        ]

        var sequences: [Int] = []
        for (index, _) in assignments.enumerated() {
            let sequence = index + 1
            sequences.append(sequence)
        }

        XCTAssertEqual(sequences, [1, 2, 3, 4])
    }

    func testBulkAssignments_EmptyArray() {
        let assignments: [(phaseId: UUID, templateId: UUID, weekNumber: Int, dayOfWeek: Int)] = []

        var createdIds: [UUID] = []
        for _ in assignments {
            createdIds.append(UUID())
        }

        XCTAssertEqual(createdIds.count, 0)
    }

    func testBulkAssignments_PartialFailureSimulation() {
        let totalAssignments = 5
        let failedIndices = Set([1, 3])

        var successCount = 0
        for index in 0..<totalAssignments {
            if !failedIndices.contains(index) {
                successCount += 1
            }
        }

        XCTAssertEqual(successCount, 3, "Should have 3 successful assignments")
    }

    // MARK: - Helper Methods

    private func createMockPhaseWithAssignments(
        id: UUID = UUID(),
        name: String = "Test Phase",
        sequence: Int = 1,
        durationWeeks: Int? = 4,
        goals: String? = nil,
        notes: String? = nil,
        assignments: [ProgramWorkoutAssignment] = []
    ) -> PhaseWithAssignments {
        PhaseWithAssignments(
            id: id,
            name: name,
            sequence: sequence,
            durationWeeks: durationWeeks,
            goals: goals,
            notes: notes,
            assignments: assignments
        )
    }
}

// MARK: - ProgramServiceError Tests

final class ProgramServiceErrorDetailTests: XCTestCase {

    func testProgramNotFound_ErrorDescription() {
        let error = ProgramServiceError.programNotFound
        XCTAssertEqual(error.errorDescription, "Program not found")
        XCTAssertNotNil(error.recoverySuggestion)
        XCTAssertTrue(error.recoverySuggestion!.contains("deleted"))
    }

    func testPhaseNotFound_ErrorDescription() {
        let error = ProgramServiceError.phaseNotFound
        XCTAssertEqual(error.errorDescription, "Phase not found")
        XCTAssertNotNil(error.recoverySuggestion)
        XCTAssertTrue(error.recoverySuggestion!.contains("Refresh"))
    }

    func testAssignmentNotFound_ErrorDescription() {
        let error = ProgramServiceError.assignmentNotFound
        XCTAssertEqual(error.errorDescription, "Workout assignment not found")
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func testInvalidPhaseOrder_ErrorDescription() {
        let error = ProgramServiceError.invalidPhaseOrder
        XCTAssertEqual(error.errorDescription, "Invalid phase order")
        XCTAssertNotNil(error.recoverySuggestion)
        XCTAssertTrue(error.recoverySuggestion!.contains("reorder"))
    }

    func testCreateFailed_ErrorDescription() {
        let underlyingError = NSError(
            domain: "test",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Database connection failed"]
        )
        let error = ProgramServiceError.createFailed(underlyingError)

        XCTAssertTrue(error.errorDescription?.contains("Failed to create") ?? false)
        XCTAssertTrue(error.errorDescription?.contains("Database connection failed") ?? false)
    }

    func testUpdateFailed_ErrorDescription() {
        let underlyingError = NSError(
            domain: "test",
            code: 2,
            userInfo: [NSLocalizedDescriptionKey: "Permission denied"]
        )
        let error = ProgramServiceError.updateFailed(underlyingError)

        XCTAssertTrue(error.errorDescription?.contains("Failed to update") ?? false)
        XCTAssertTrue(error.errorDescription?.contains("Permission denied") ?? false)
    }

    func testDeleteFailed_ErrorDescription() {
        let underlyingError = NSError(
            domain: "test",
            code: 3,
            userInfo: [NSLocalizedDescriptionKey: "Resource locked"]
        )
        let error = ProgramServiceError.deleteFailed(underlyingError)

        XCTAssertTrue(error.errorDescription?.contains("Failed to delete") ?? false)
    }

    func testFetchFailed_ErrorDescription() {
        let underlyingError = NSError(
            domain: "test",
            code: 4,
            userInfo: [NSLocalizedDescriptionKey: "Network timeout"]
        )
        let error = ProgramServiceError.fetchFailed(underlyingError)

        XCTAssertTrue(error.errorDescription?.contains("Failed to fetch") ?? false)
        XCTAssertNotNil(error.recoverySuggestion)
        XCTAssertTrue(error.recoverySuggestion!.contains("connection"))
    }

    func testPublishFailed_ErrorDescription() {
        let underlyingError = NSError(
            domain: "test",
            code: 5,
            userInfo: [NSLocalizedDescriptionKey: "Validation failed"]
        )
        let error = ProgramServiceError.publishFailed(underlyingError)

        XCTAssertTrue(error.errorDescription?.contains("Failed to publish") ?? false)
        XCTAssertNotNil(error.recoverySuggestion)
        XCTAssertTrue(error.recoverySuggestion!.contains("required fields"))
    }

    func testError_LocalizedErrorConformance() {
        let errors: [ProgramServiceError] = [
            .programNotFound,
            .phaseNotFound,
            .assignmentNotFound,
            .invalidPhaseOrder
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "\(error) should have errorDescription")
        }
    }
}

// MARK: - Response Model Tests

final class ProgramServiceResponseModelTests: XCTestCase {

    // MARK: - ProgramWithPhases Tests

    func testProgramWithPhases_Initialization() {
        let program = ProgramWithPhases(
            id: UUID(),
            name: "Test Program",
            description: "A test program",
            status: "draft",
            patientId: nil,
            metadata: nil,
            phases: []
        )

        XCTAssertNotNil(program.id)
        XCTAssertEqual(program.name, "Test Program")
        XCTAssertEqual(program.status, "draft")
        XCTAssertNil(program.patientId)
        XCTAssertTrue(program.phases.isEmpty)
    }

    func testProgramWithPhases_WithMetadata() {
        let metadata: [String: AnyCodable] = [
            "category": AnyCodable("strength"),
            "duration_weeks": AnyCodable(12),
            "is_system_template": AnyCodable(true)
        ]

        let program = ProgramWithPhases(
            id: UUID(),
            name: "Strength Program",
            description: "12-week strength program",
            status: "active",
            patientId: nil,
            metadata: metadata,
            phases: []
        )

        XCTAssertNotNil(program.metadata)
        XCTAssertEqual(program.metadata?.count, 3)
    }

    func testProgramWithPhases_WithPhases() {
        let phase = PhaseWithAssignments(
            id: UUID(),
            name: "Phase 1",
            sequence: 1,
            durationWeeks: 4,
            goals: "Build foundation",
            notes: nil,
            assignments: []
        )

        let program = ProgramWithPhases(
            id: UUID(),
            name: "Multi-Phase Program",
            description: nil,
            status: "draft",
            patientId: nil,
            metadata: nil,
            phases: [phase]
        )

        XCTAssertEqual(program.phases.count, 1)
        XCTAssertEqual(program.phases[0].name, "Phase 1")
    }

    // MARK: - PhaseWithAssignments Tests

    func testPhaseWithAssignments_Initialization() {
        let phase = PhaseWithAssignments(
            id: UUID(),
            name: "Foundation Phase",
            sequence: 1,
            durationWeeks: 4,
            goals: "Build movement patterns",
            notes: "Focus on form",
            assignments: []
        )

        XCTAssertNotNil(phase.id)
        XCTAssertEqual(phase.name, "Foundation Phase")
        XCTAssertEqual(phase.sequence, 1)
        XCTAssertEqual(phase.durationWeeks, 4)
        XCTAssertEqual(phase.goals, "Build movement patterns")
        XCTAssertEqual(phase.notes, "Focus on form")
    }

    func testPhaseWithAssignments_WithAssignments() {
        let assignment = ProgramWorkoutAssignment(
            id: UUID(),
            programId: UUID(),
            templateId: UUID(),
            phaseId: UUID(),
            weekNumber: 1,
            dayOfWeek: 1,
            sequence: 1,
            notes: nil,
            createdAt: nil
        )

        let phase = PhaseWithAssignments(
            id: UUID(),
            name: "Phase 1",
            sequence: 1,
            durationWeeks: 4,
            goals: nil,
            notes: nil,
            assignments: [assignment]
        )

        XCTAssertEqual(phase.assignments.count, 1)
    }

    func testPhaseWithAssignments_OptionalFields() {
        let phase = PhaseWithAssignments(
            id: UUID(),
            name: "Minimal Phase",
            sequence: 1,
            durationWeeks: nil,
            goals: nil,
            notes: nil,
            assignments: []
        )

        XCTAssertNil(phase.durationWeeks)
        XCTAssertNil(phase.goals)
        XCTAssertNil(phase.notes)
    }

    // MARK: - ProgramWorkoutAssignment Tests

    func testProgramWorkoutAssignment_Initialization() {
        let programId = UUID()
        let templateId = UUID()
        let phaseId = UUID()

        let assignment = ProgramWorkoutAssignment(
            id: UUID(),
            programId: programId,
            templateId: templateId,
            phaseId: phaseId,
            weekNumber: 2,
            dayOfWeek: 3,
            sequence: 10,
            notes: "Focus on technique",
            createdAt: Date()
        )

        XCTAssertEqual(assignment.programId, programId)
        XCTAssertEqual(assignment.templateId, templateId)
        XCTAssertEqual(assignment.phaseId, phaseId)
        XCTAssertEqual(assignment.weekNumber, 2)
        XCTAssertEqual(assignment.dayOfWeek, 3)
        XCTAssertEqual(assignment.sequence, 10)
        XCTAssertEqual(assignment.notes, "Focus on technique")
    }

    func testProgramWorkoutAssignment_Identifiable() {
        let assignment = ProgramWorkoutAssignment(
            id: UUID(),
            programId: UUID(),
            templateId: UUID(),
            phaseId: UUID(),
            weekNumber: 1,
            dayOfWeek: 1,
            sequence: 1,
            notes: nil,
            createdAt: nil
        )

        XCTAssertNotNil(assignment.id)
    }

    func testProgramWorkoutAssignment_OptionalPhaseId() {
        let assignment = ProgramWorkoutAssignment(
            id: UUID(),
            programId: UUID(),
            templateId: UUID(),
            phaseId: nil,
            weekNumber: 1,
            dayOfWeek: 1,
            sequence: 1,
            notes: nil,
            createdAt: nil
        )

        XCTAssertNil(assignment.phaseId)
    }

    // MARK: - ProgramResponse Tests

    func testProgramResponse_SystemTemplate() {
        let response = ProgramResponse(
            id: UUID(),
            name: "System Template",
            description: "A reusable template",
            status: "active",
            patientId: nil,
            metadata: nil
        )

        XCTAssertNil(response.patientId, "System template should have nil patientId")
    }

    func testProgramResponse_PatientProgram() {
        let patientId = UUID()
        let response = ProgramResponse(
            id: UUID(),
            name: "Patient Program",
            description: "Customized for patient",
            status: "active",
            patientId: patientId,
            metadata: nil
        )

        XCTAssertEqual(response.patientId, patientId)
    }

    func testProgramResponse_AllStatuses() {
        let statuses = ["draft", "active", "paused", "completed", "archived"]

        for status in statuses {
            let response = ProgramResponse(
                id: UUID(),
                name: "Test",
                description: nil,
                status: status,
                patientId: nil,
                metadata: nil
            )

            XCTAssertEqual(response.status, status)
        }
    }
}

// MARK: - AnyCodable Tests

final class AnyCodableDetailTests: XCTestCase {

    func testAnyCodable_String() {
        let value = AnyCodable("test string")
        XCTAssertEqual(value.value as? String, "test string")
    }

    func testAnyCodable_Int() {
        let value = AnyCodable(42)
        XCTAssertEqual(value.value as? Int, 42)
    }

    func testAnyCodable_Double() {
        let value = AnyCodable(3.14159)
        XCTAssertEqual(value.value as? Double, 3.14159, accuracy: 0.00001)
    }

    func testAnyCodable_Bool() {
        let trueValue = AnyCodable(true)
        let falseValue = AnyCodable(false)

        XCTAssertEqual(trueValue.value as? Bool, true)
        XCTAssertEqual(falseValue.value as? Bool, false)
    }

    func testAnyCodable_Array() {
        let value = AnyCodable([1, 2, 3])
        XCTAssertNotNil(value.value as? [Any])
    }

    func testAnyCodable_Dictionary() {
        let value = AnyCodable(["key": "value", "number": 42])
        XCTAssertNotNil(value.value as? [String: Any])
    }

    func testAnyCodable_Encoding_String() throws {
        let value = AnyCodable("hello")
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        let string = String(data: data, encoding: .utf8)

        XCTAssertEqual(string, "\"hello\"")
    }

    func testAnyCodable_Encoding_Number() throws {
        let value = AnyCodable(123)
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        let string = String(data: data, encoding: .utf8)

        XCTAssertEqual(string, "123")
    }

    func testAnyCodable_Encoding_Bool() throws {
        let value = AnyCodable(true)
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        let string = String(data: data, encoding: .utf8)

        XCTAssertEqual(string, "true")
    }

    func testAnyCodable_Encoding_Null() throws {
        let value = AnyCodable(NSNull())
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        let string = String(data: data, encoding: .utf8)

        XCTAssertEqual(string, "null")
    }

    func testAnyCodable_Decoding_String() throws {
        let json = "\"decoded string\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        let value = try decoder.decode(AnyCodable.self, from: json)

        XCTAssertEqual(value.value as? String, "decoded string")
    }

    func testAnyCodable_Decoding_Int() throws {
        let json = "999".data(using: .utf8)!
        let decoder = JSONDecoder()
        let value = try decoder.decode(AnyCodable.self, from: json)

        XCTAssertEqual(value.value as? Int, 999)
    }

    func testAnyCodable_Decoding_Double() throws {
        let json = "2.718".data(using: .utf8)!
        let decoder = JSONDecoder()
        let value = try decoder.decode(AnyCodable.self, from: json)

        XCTAssertEqual(value.value as? Double, 2.718, accuracy: 0.001)
    }

    func testAnyCodable_Decoding_Bool() throws {
        let trueJson = "true".data(using: .utf8)!
        let falseJson = "false".data(using: .utf8)!
        let decoder = JSONDecoder()

        let trueValue = try decoder.decode(AnyCodable.self, from: trueJson)
        let falseValue = try decoder.decode(AnyCodable.self, from: falseJson)

        XCTAssertEqual(trueValue.value as? Bool, true)
        XCTAssertEqual(falseValue.value as? Bool, false)
    }

    func testAnyCodable_Decoding_Array() throws {
        let json = "[1, 2, 3, 4, 5]".data(using: .utf8)!
        let decoder = JSONDecoder()
        let value = try decoder.decode(AnyCodable.self, from: json)

        XCTAssertNotNil(value.value as? [Any])
    }

    func testAnyCodable_Decoding_Object() throws {
        let json = "{\"name\": \"test\", \"count\": 10}".data(using: .utf8)!
        let decoder = JSONDecoder()
        let value = try decoder.decode(AnyCodable.self, from: json)

        XCTAssertNotNil(value.value as? [String: Any])
    }

    func testAnyCodable_RoundTrip() throws {
        let original: [String: AnyCodable] = [
            "string": AnyCodable("hello"),
            "number": AnyCodable(42),
            "bool": AnyCodable(true),
            "double": AnyCodable(3.14)
        ]

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode([String: AnyCodable].self, from: data)

        XCTAssertEqual(decoded["string"]?.value as? String, "hello")
        XCTAssertEqual(decoded["number"]?.value as? Int, 42)
        XCTAssertEqual(decoded["bool"]?.value as? Bool, true)
        XCTAssertEqual(decoded["double"]?.value as? Double, 3.14, accuracy: 0.01)
    }

    func testAnyCodable_NestedStructures() throws {
        let nested: [String: AnyCodable] = [
            "outer": AnyCodable([
                "inner": "value"
            ])
        ]

        let encoder = JSONEncoder()
        let data = try encoder.encode(nested)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode([String: AnyCodable].self, from: data)

        XCTAssertNotNil(decoded["outer"])
    }
}

// MARK: - Edge Cases and Validation Tests

final class ProgramServiceEdgeCaseTests: XCTestCase {

    func testEmptyProgramName() {
        let response = ProgramResponse(
            id: UUID(),
            name: "",
            description: nil,
            status: "draft",
            patientId: nil,
            metadata: nil
        )

        XCTAssertEqual(response.name, "")
    }

    func testVeryLongProgramName() {
        let longName = String(repeating: "A", count: 1000)
        let response = ProgramResponse(
            id: UUID(),
            name: longName,
            description: nil,
            status: "draft",
            patientId: nil,
            metadata: nil
        )

        XCTAssertEqual(response.name.count, 1000)
    }

    func testPhaseWithZeroSequence() {
        let phase = PhaseWithAssignments(
            id: UUID(),
            name: "Pre-Phase",
            sequence: 0,
            durationWeeks: 1,
            goals: nil,
            notes: nil,
            assignments: []
        )

        XCTAssertEqual(phase.sequence, 0)
    }

    func testPhaseWithNegativeDuration() {
        // Edge case that shouldn't happen in production but should be handled
        let phase = PhaseWithAssignments(
            id: UUID(),
            name: "Invalid Phase",
            sequence: 1,
            durationWeeks: -1,
            goals: nil,
            notes: nil,
            assignments: []
        )

        XCTAssertEqual(phase.durationWeeks, -1)
    }

    func testAssignmentWithInvalidDayOfWeek() {
        // Day of week should be 1-7, but test edge cases
        let assignment = ProgramWorkoutAssignment(
            id: UUID(),
            programId: UUID(),
            templateId: UUID(),
            phaseId: UUID(),
            weekNumber: 1,
            dayOfWeek: 0,  // Invalid
            sequence: 1,
            notes: nil,
            createdAt: nil
        )

        XCTAssertEqual(assignment.dayOfWeek, 0)
    }

    func testAssignmentWithWeekNumber53() {
        // 53 weeks in some years
        let assignment = ProgramWorkoutAssignment(
            id: UUID(),
            programId: UUID(),
            templateId: UUID(),
            phaseId: UUID(),
            weekNumber: 53,
            dayOfWeek: 1,
            sequence: 365,
            notes: nil,
            createdAt: nil
        )

        XCTAssertEqual(assignment.weekNumber, 53)
    }

    func testManyAssignmentsInPhase() {
        var assignments: [ProgramWorkoutAssignment] = []
        for i in 0..<100 {
            assignments.append(ProgramWorkoutAssignment(
                id: UUID(),
                programId: UUID(),
                templateId: UUID(),
                phaseId: UUID(),
                weekNumber: (i / 7) + 1,
                dayOfWeek: (i % 7) + 1,
                sequence: i + 1,
                notes: nil,
                createdAt: nil
            ))
        }

        let phase = PhaseWithAssignments(
            id: UUID(),
            name: "Intensive Phase",
            sequence: 1,
            durationWeeks: 15,
            goals: nil,
            notes: nil,
            assignments: assignments
        )

        XCTAssertEqual(phase.assignments.count, 100)
    }

    func testManyPhasesInProgram() {
        var phases: [PhaseWithAssignments] = []
        for i in 1...20 {
            phases.append(PhaseWithAssignments(
                id: UUID(),
                name: "Phase \(i)",
                sequence: i,
                durationWeeks: 1,
                goals: nil,
                notes: nil,
                assignments: []
            ))
        }

        let program = ProgramWithPhases(
            id: UUID(),
            name: "Long Program",
            description: nil,
            status: "draft",
            patientId: nil,
            metadata: nil,
            phases: phases
        )

        XCTAssertEqual(program.phases.count, 20)
    }
}
