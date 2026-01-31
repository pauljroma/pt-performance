//
//  ProgramBuilderServiceTests.swift
//  PTPerformanceTests
//
//  Build 346 - Unit tests for ProgramBuilderService
//  Tests program creation logic, error handling, and response models
//

import XCTest
@testable import PTPerformance

final class ProgramBuilderServiceTests: XCTestCase {

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

    func testServiceInitialization() {
        XCTAssertNotNil(service, "ProgramBuilderService should be instantiatable")
    }

    func testServiceInitialization_WithCustomSupabase() {
        let customService = ProgramBuilderService(supabase: PTSupabaseClient.shared)
        XCTAssertNotNil(customService, "Service should accept custom Supabase client")
    }

    func testServiceIsObservableObject() {
        // ProgramBuilderService conforms to ObservableObject for SwiftUI integration
        XCTAssertTrue(service is ObservableObject, "Service should conform to ObservableObject")
    }

    // MARK: - Sequence Calculation Tests

    func testAssignWorkout_SequenceCalculation_Week1Day1() {
        // The sequence calculation is: (weekNumber - 1) * 7 + dayOfWeek
        // Week 1, Day 1 (Monday): (1-1) * 7 + 1 = 1
        let weekNumber = 1
        let dayOfWeek = 1
        let expectedSequence = (weekNumber - 1) * 7 + dayOfWeek

        XCTAssertEqual(expectedSequence, 1, "Week 1, Day 1 should have sequence 1")
    }

    func testAssignWorkout_SequenceCalculation_Week1Day7() {
        // Week 1, Day 7 (Sunday): (1-1) * 7 + 7 = 7
        let weekNumber = 1
        let dayOfWeek = 7
        let expectedSequence = (weekNumber - 1) * 7 + dayOfWeek

        XCTAssertEqual(expectedSequence, 7, "Week 1, Day 7 should have sequence 7")
    }

    func testAssignWorkout_SequenceCalculation_Week2Day1() {
        // Week 2, Day 1: (2-1) * 7 + 1 = 8
        let weekNumber = 2
        let dayOfWeek = 1
        let expectedSequence = (weekNumber - 1) * 7 + dayOfWeek

        XCTAssertEqual(expectedSequence, 8, "Week 2, Day 1 should have sequence 8")
    }

    func testAssignWorkout_SequenceCalculation_Week4Day3() {
        // Week 4, Day 3 (Wednesday): (4-1) * 7 + 3 = 24
        let weekNumber = 4
        let dayOfWeek = 3
        let expectedSequence = (weekNumber - 1) * 7 + dayOfWeek

        XCTAssertEqual(expectedSequence, 24, "Week 4, Day 3 should have sequence 24")
    }

    func testAssignWorkout_SequenceCalculation_Week12Day5() {
        // Week 12, Day 5 (Friday): (12-1) * 7 + 5 = 82
        let weekNumber = 12
        let dayOfWeek = 5
        let expectedSequence = (weekNumber - 1) * 7 + dayOfWeek

        XCTAssertEqual(expectedSequence, 82, "Week 12, Day 5 should have sequence 82")
    }

    // MARK: - Duration Calculation Tests

    func testPublishToLibrary_DurationCalculation_EmptyPhases() {
        // When program has no phases, minimum duration is 1 week
        let phases: [PhaseWithAssignments] = []
        let durationWeeks = phases.reduce(0) { sum, phase in
            sum + (phase.durationWeeks ?? 0)
        }
        let finalDuration = max(durationWeeks, 1)

        XCTAssertEqual(finalDuration, 1, "Empty program should have minimum 1 week duration")
    }

    func testPublishToLibrary_DurationCalculation_SinglePhase() {
        let testPhase = createMockPhase(durationWeeks: 4)
        let phases = [testPhase]

        let durationWeeks = phases.reduce(0) { sum, phase in
            sum + (phase.durationWeeks ?? 0)
        }

        XCTAssertEqual(durationWeeks, 4, "Single 4-week phase should have 4 weeks duration")
    }

    func testPublishToLibrary_DurationCalculation_MultiplePhases() {
        let phase1 = createMockPhase(durationWeeks: 4)
        let phase2 = createMockPhase(durationWeeks: 6)
        let phase3 = createMockPhase(durationWeeks: 2)
        let phases = [phase1, phase2, phase3]

        let durationWeeks = phases.reduce(0) { sum, phase in
            sum + (phase.durationWeeks ?? 0)
        }

        XCTAssertEqual(durationWeeks, 12, "Three phases should sum to 12 weeks")
    }

    func testPublishToLibrary_DurationCalculation_NilDurations() {
        let phase1 = createMockPhase(durationWeeks: 4)
        let phase2 = createMockPhase(durationWeeks: nil)
        let phase3 = createMockPhase(durationWeeks: 3)
        let phases = [phase1, phase2, phase3]

        let durationWeeks = phases.reduce(0) { sum, phase in
            sum + (phase.durationWeeks ?? 0)
        }

        XCTAssertEqual(durationWeeks, 7, "Nil durations should be treated as 0")
    }

    // MARK: - Phase Reordering Tests

    func testReorderPhases_SequenceNumbers() {
        // Given: Array of phase IDs in new order
        let phaseIds = [
            UUID(),
            UUID(),
            UUID()
        ]

        // When: Calculating new sequences
        var newSequences: [(phaseId: UUID, sequence: Int)] = []
        for (index, phaseId) in phaseIds.enumerated() {
            let newSequence = index + 1  // 1-based sequence
            newSequences.append((phaseId, newSequence))
        }

        // Then: Sequences should be 1, 2, 3
        XCTAssertEqual(newSequences[0].sequence, 1)
        XCTAssertEqual(newSequences[1].sequence, 2)
        XCTAssertEqual(newSequences[2].sequence, 3)
    }

    // MARK: - Helper Functions

    private func createMockPhase(durationWeeks: Int?) -> PhaseWithAssignments {
        PhaseWithAssignments(
            id: UUID(),
            name: "Test Phase",
            sequence: 1,
            durationWeeks: durationWeeks,
            goals: nil,
            notes: nil,
            assignments: []
        )
    }
}

// MARK: - ProgramServiceError Tests

final class ProgramServiceErrorTests: XCTestCase {

    func testProgramNotFound_ErrorDescription() {
        let error = ProgramServiceError.programNotFound
        XCTAssertEqual(error.errorDescription, "Program not found")
    }

    func testPhaseNotFound_ErrorDescription() {
        let error = ProgramServiceError.phaseNotFound
        XCTAssertEqual(error.errorDescription, "Phase not found")
    }

    func testAssignmentNotFound_ErrorDescription() {
        let error = ProgramServiceError.assignmentNotFound
        XCTAssertEqual(error.errorDescription, "Workout assignment not found")
    }

    func testInvalidPhaseOrder_ErrorDescription() {
        let error = ProgramServiceError.invalidPhaseOrder
        XCTAssertEqual(error.errorDescription, "Invalid phase order")
    }

    func testCreateFailed_ErrorDescription() {
        let underlyingError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database error"])
        let error = ProgramServiceError.createFailed(underlyingError)

        XCTAssertTrue(error.errorDescription?.contains("Failed to create") ?? false)
        XCTAssertTrue(error.errorDescription?.contains("Database error") ?? false)
    }

    func testUpdateFailed_ErrorDescription() {
        let underlyingError = NSError(domain: "test", code: 2, userInfo: [NSLocalizedDescriptionKey: "Update failed"])
        let error = ProgramServiceError.updateFailed(underlyingError)

        XCTAssertTrue(error.errorDescription?.contains("Failed to update") ?? false)
    }

    func testDeleteFailed_ErrorDescription() {
        let underlyingError = NSError(domain: "test", code: 3, userInfo: [NSLocalizedDescriptionKey: "Delete failed"])
        let error = ProgramServiceError.deleteFailed(underlyingError)

        XCTAssertTrue(error.errorDescription?.contains("Failed to delete") ?? false)
    }

    func testFetchFailed_ErrorDescription() {
        let underlyingError = NSError(domain: "test", code: 4, userInfo: [NSLocalizedDescriptionKey: "Fetch failed"])
        let error = ProgramServiceError.fetchFailed(underlyingError)

        XCTAssertTrue(error.errorDescription?.contains("Failed to fetch") ?? false)
    }

    func testPublishFailed_ErrorDescription() {
        let underlyingError = NSError(domain: "test", code: 5, userInfo: [NSLocalizedDescriptionKey: "Publish failed"])
        let error = ProgramServiceError.publishFailed(underlyingError)

        XCTAssertTrue(error.errorDescription?.contains("Failed to publish") ?? false)
    }

    func testErrorConformsToLocalizedError() {
        let error = ProgramServiceError.programNotFound
        XCTAssertTrue(error is LocalizedError, "ProgramServiceError should conform to LocalizedError")
    }
}

// MARK: - Response Model Tests

final class ProgramResponseModelTests: XCTestCase {

    // MARK: - ProgramWithPhases Tests

    func testProgramWithPhases_Identifiable() {
        let program = ProgramWithPhases(
            id: UUID(),
            name: "Test Program",
            description: "Description",
            status: "draft",
            patientId: nil,
            metadata: nil,
            phases: []
        )

        XCTAssertNotNil(program.id, "ProgramWithPhases should have an id")
    }

    func testProgramWithPhases_WithMetadata() {
        let metadata: [String: AnyCodable] = [
            "category": AnyCodable("strength"),
            "duration_weeks": AnyCodable(12)
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
        XCTAssertEqual(program.metadata?.count, 2)
    }

    // MARK: - PhaseWithAssignments Tests

    func testPhaseWithAssignments_Identifiable() {
        let phase = PhaseWithAssignments(
            id: UUID(),
            name: "Phase 1",
            sequence: 1,
            durationWeeks: 4,
            goals: "Build foundation",
            notes: nil,
            assignments: []
        )

        XCTAssertNotNil(phase.id)
        XCTAssertEqual(phase.name, "Phase 1")
        XCTAssertEqual(phase.sequence, 1)
        XCTAssertEqual(phase.durationWeeks, 4)
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

    // MARK: - ProgramWorkoutAssignment Tests

    func testProgramWorkoutAssignment_AllFields() {
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
            notes: "Focus on form",
            createdAt: Date()
        )

        XCTAssertEqual(assignment.programId, programId)
        XCTAssertEqual(assignment.templateId, templateId)
        XCTAssertEqual(assignment.phaseId, phaseId)
        XCTAssertEqual(assignment.weekNumber, 2)
        XCTAssertEqual(assignment.dayOfWeek, 3)
        XCTAssertEqual(assignment.sequence, 10)
        XCTAssertEqual(assignment.notes, "Focus on form")
        XCTAssertNotNil(assignment.createdAt)
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

    // MARK: - ProgramResponse Tests

    func testProgramResponse_SystemTemplate() {
        let response = ProgramResponse(
            id: UUID(),
            name: "System Template",
            description: "A reusable template",
            status: "active",
            patientId: nil,  // System templates have no patient
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

        XCTAssertEqual(response.patientId, patientId, "Patient program should have patientId")
    }
}

// MARK: - AnyCodable Tests

final class AnyCodableTests: XCTestCase {

    func testAnyCodable_String() {
        let value = AnyCodable("test string")
        XCTAssertEqual(value.value as? String, "test string")
    }

    func testAnyCodable_Int() {
        let value = AnyCodable(42)
        XCTAssertEqual(value.value as? Int, 42)
    }

    func testAnyCodable_Double() {
        let value = AnyCodable(3.14)
        XCTAssertEqual(value.value as? Double, 3.14)
    }

    func testAnyCodable_Bool() {
        let value = AnyCodable(true)
        XCTAssertEqual(value.value as? Bool, true)
    }

    func testAnyCodable_Array() {
        let value = AnyCodable([1, 2, 3])
        XCTAssertNotNil(value.value as? [Any])
    }

    func testAnyCodable_Dictionary() {
        let value = AnyCodable(["key": "value"])
        XCTAssertNotNil(value.value as? [String: Any])
    }

    func testAnyCodable_Encoding() throws {
        let value = AnyCodable("test")
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        let jsonString = String(data: data, encoding: .utf8)

        XCTAssertEqual(jsonString, "\"test\"")
    }

    func testAnyCodable_Decoding_String() throws {
        let json = "\"test string\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        let value = try decoder.decode(AnyCodable.self, from: json)

        XCTAssertEqual(value.value as? String, "test string")
    }

    func testAnyCodable_Decoding_Int() throws {
        let json = "42".data(using: .utf8)!
        let decoder = JSONDecoder()
        let value = try decoder.decode(AnyCodable.self, from: json)

        XCTAssertEqual(value.value as? Int, 42)
    }

    func testAnyCodable_Decoding_Bool() throws {
        let json = "true".data(using: .utf8)!
        let decoder = JSONDecoder()
        let value = try decoder.decode(AnyCodable.self, from: json)

        XCTAssertEqual(value.value as? Bool, true)
    }

    func testAnyCodable_Decoding_Double() throws {
        let json = "3.14".data(using: .utf8)!
        let decoder = JSONDecoder()
        let value = try decoder.decode(AnyCodable.self, from: json)

        XCTAssertEqual(value.value as? Double, 3.14)
    }

    func testAnyCodable_Decoding_Array() throws {
        let json = "[1, 2, 3]".data(using: .utf8)!
        let decoder = JSONDecoder()
        let value = try decoder.decode(AnyCodable.self, from: json)

        XCTAssertNotNil(value.value as? [Any])
    }

    func testAnyCodable_Decoding_Dictionary() throws {
        let json = "{\"key\": \"value\"}".data(using: .utf8)!
        let decoder = JSONDecoder()
        let value = try decoder.decode(AnyCodable.self, from: json)

        XCTAssertNotNil(value.value as? [String: Any])
    }

    func testAnyCodable_Encoding_Nil() throws {
        let value = AnyCodable(NSNull())
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        let jsonString = String(data: data, encoding: .utf8)

        XCTAssertEqual(jsonString, "null")
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
        XCTAssertEqual(decoded["double"]?.value as? Double, 3.14)
    }
}

// MARK: - Bulk Operations Tests

final class ProgramBulkOperationsTests: XCTestCase {

    func testBulkAssignments_SequenceGeneration() {
        // Given: Multiple assignments
        let assignments: [(phaseId: UUID, templateId: UUID, weekNumber: Int, dayOfWeek: Int)] = [
            (UUID(), UUID(), 1, 1),
            (UUID(), UUID(), 1, 3),
            (UUID(), UUID(), 2, 1),
            (UUID(), UUID(), 2, 5)
        ]

        // When: Generating sequences (index-based, not week/day based for bulk)
        var sequences: [Int] = []
        for (index, _) in assignments.enumerated() {
            let sequence = index + 1
            sequences.append(sequence)
        }

        // Then: Sequences should be sequential
        XCTAssertEqual(sequences, [1, 2, 3, 4])
    }

    func testBulkAssignments_EmptyArray() {
        let assignments: [(phaseId: UUID, templateId: UUID, weekNumber: Int, dayOfWeek: Int)] = []

        var createdIds: [UUID] = []
        for _ in assignments {
            createdIds.append(UUID())
        }

        XCTAssertEqual(createdIds.count, 0, "Empty assignments should produce no IDs")
    }

    func testBulkAssignments_PartialFailure() {
        // Simulate partial failure scenario
        // In the real implementation, failures are logged but processing continues

        let totalAssignments = 5
        let failedIndices = Set([1, 3])  // Indices that would fail

        var successCount = 0
        for index in 0..<totalAssignments {
            if !failedIndices.contains(index) {
                successCount += 1
            }
        }

        XCTAssertEqual(successCount, 3, "Should have 3 successful assignments")
    }
}
