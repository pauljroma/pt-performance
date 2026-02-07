//
//  ProgramBuilderViewModelTests.swift
//  PTPerformanceTests
//
//  Comprehensive unit tests for ProgramBuilderViewModel
//  Tests exercise creation with target_sets, program validation,
//  phase management, and error handling
//
//  Coverage areas:
//  - Exercise creation with target_sets
//  - Program validation
//  - Phase management (add/delete)
//  - Protocol constraints
//  - Error handling and translation
//

import XCTest
@testable import PTPerformance

// MARK: - ProgramBuilderViewModel Tests

@MainActor
final class ProgramBuilderViewModelTests: XCTestCase {

    var viewModel: ProgramBuilderViewModel!

    override func setUp() async throws {
        try await super.setUp()
        viewModel = ProgramBuilderViewModel()
    }

    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_DefaultValues() {
        XCTAssertEqual(viewModel.programName, "", "Program name should be empty initially")
        XCTAssertEqual(viewModel.selectedProgramType, .rehab, "Default program type should be rehab")
        XCTAssertNil(viewModel.selectedProtocol, "No protocol should be selected initially")
        XCTAssertTrue(viewModel.phases.isEmpty, "Phases should be empty initially")
        XCTAssertNil(viewModel.validationError, "No validation error initially")
        XCTAssertFalse(viewModel.isCreating, "Should not be creating initially")
        XCTAssertNil(viewModel.createError, "No create error initially")
        XCTAssertNil(viewModel.successMessage, "No success message initially")
        XCTAssertFalse(viewModel.isLoadingProtocols, "Should not be loading protocols initially")
    }

    // MARK: - Validation Tests

    func testIsValid_EmptyProgramName_False() {
        viewModel.programName = ""
        viewModel.phases = [createMockPhase()]

        XCTAssertFalse(viewModel.isValid)
        XCTAssertNotNil(viewModel.validationError)
    }

    func testIsValid_ProgramNameTooShort_False() {
        viewModel.programName = "AB"
        viewModel.phases = [createMockPhase()]

        XCTAssertFalse(viewModel.isValid)
        XCTAssertEqual(viewModel.validationError, ProgramBuilderError.programNameTooShort.errorDescription)
    }

    func testIsValid_ProgramNameTooLong_False() {
        viewModel.programName = String(repeating: "A", count: 101)
        viewModel.phases = [createMockPhase()]

        XCTAssertFalse(viewModel.isValid)
        XCTAssertEqual(viewModel.validationError, ProgramBuilderError.programNameTooLong.errorDescription)
    }

    func testIsValid_NoPhases_False() {
        viewModel.programName = "Valid Name"
        viewModel.phases = []

        XCTAssertFalse(viewModel.isValid)
        XCTAssertEqual(viewModel.validationError, ProgramBuilderError.noPhases.errorDescription)
    }

    func testIsValid_EmptyPhaseName_False() {
        viewModel.programName = "Valid Name"
        var phase = createMockPhase()
        phase.name = ""
        viewModel.phases = [phase]

        XCTAssertFalse(viewModel.isValid)
        XCTAssertTrue(viewModel.validationError?.contains("Phase 1") ?? false)
    }

    func testIsValid_InvalidPhaseDuration_False() {
        viewModel.programName = "Valid Name"
        var phase = createMockPhase()
        phase.durationWeeks = 0
        viewModel.phases = [phase]

        XCTAssertFalse(viewModel.isValid)
        XCTAssertTrue(viewModel.validationError?.contains("greater than 0") ?? false)
    }

    func testIsValid_PhaseDurationTooLong_False() {
        viewModel.programName = "Valid Name"
        var phase = createMockPhase()
        phase.durationWeeks = 53
        viewModel.phases = [phase]

        XCTAssertFalse(viewModel.isValid)
        XCTAssertTrue(viewModel.validationError?.contains("52 weeks") ?? false)
    }

    func testIsValid_TotalDurationTooLong_False() {
        viewModel.programName = "Valid Name"
        // Create enough phases to exceed 104 weeks
        viewModel.phases = (1...3).map { _ in
            var phase = createMockPhase()
            phase.durationWeeks = 40
            return phase
        }

        XCTAssertFalse(viewModel.isValid)
        XCTAssertTrue(viewModel.validationError?.contains("104 weeks") ?? false)
    }

    func testIsValid_ValidProgram_True() {
        viewModel.programName = "Valid Program"
        viewModel.phases = [createMockPhase()]

        XCTAssertTrue(viewModel.isValid)
        XCTAssertNil(viewModel.validationError)
    }

    // MARK: - Phase Management Tests

    func testAddPhase() {
        XCTAssertEqual(viewModel.phases.count, 0)

        viewModel.addPhase()

        XCTAssertEqual(viewModel.phases.count, 1)
        XCTAssertEqual(viewModel.phases[0].name, "Phase 1")
        XCTAssertEqual(viewModel.phases[0].durationWeeks, 2)
        XCTAssertEqual(viewModel.phases[0].order, 1)
    }

    func testAddPhase_IncrementsOrder() {
        viewModel.addPhase()
        viewModel.addPhase()
        viewModel.addPhase()

        XCTAssertEqual(viewModel.phases[0].order, 1)
        XCTAssertEqual(viewModel.phases[1].order, 2)
        XCTAssertEqual(viewModel.phases[2].order, 3)
    }

    func testDeletePhase() {
        viewModel.addPhase()
        viewModel.addPhase()
        XCTAssertEqual(viewModel.phases.count, 2)

        viewModel.deletePhase(at: IndexSet(integer: 0))

        XCTAssertEqual(viewModel.phases.count, 1)
    }

    func testDeletePhase_ReordersRemainingPhases() {
        viewModel.addPhase()
        viewModel.addPhase()
        viewModel.addPhase()

        viewModel.deletePhase(at: IndexSet(integer: 0))

        XCTAssertEqual(viewModel.phases[0].order, 1)
        XCTAssertEqual(viewModel.phases[1].order, 2)
    }

    func testCanAddPhase_NoProtocol_True() {
        viewModel.selectedProtocol = nil

        XCTAssertTrue(viewModel.canAddPhase)
    }

    // MARK: - Program Type Tests

    func testSelectedProgramType_ClearsProtocolOnChange() {
        // This test verifies the didSet behavior of selectedProgramType
        viewModel.selectedProgramType = .performance

        // When type changes, protocol and phases should be cleared
        XCTAssertNil(viewModel.selectedProtocol)
        XCTAssertTrue(viewModel.phases.isEmpty)
    }

    // MARK: - CreateSessionExerciseInput Tests

    func testCreateSessionExerciseInput_UsesTargetSets() throws {
        let input = CreateSessionExerciseInput(
            sessionId: "session-1",
            exerciseTemplateId: "template-1",
            sequence: 1,
            targetSets: 4,
            targetReps: "10",
            targetLoad: 135.0,
            loadUnit: "lbs",
            restPeriodSeconds: 90,
            notes: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(input)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["target_sets"] as? Int, 4)
        XCTAssertEqual(json["target_reps"] as? String, "10")
        XCTAssertEqual(json["target_load"] as? Double, 135.0)
    }

    func testCreateSessionExerciseInput_EncodingKeys() throws {
        let input = CreateSessionExerciseInput(
            sessionId: "session-1",
            exerciseTemplateId: "template-1",
            sequence: 1,
            targetSets: 3,
            targetReps: "8-10",
            targetLoad: nil,
            loadUnit: "kg",
            restPeriodSeconds: 120,
            notes: "Test notes"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(input)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Verify snake_case encoding
        XCTAssertNotNil(json["session_id"])
        XCTAssertNotNil(json["exercise_template_id"])
        XCTAssertNotNil(json["target_sets"])
        XCTAssertNotNil(json["target_reps"])
        XCTAssertNotNil(json["load_unit"])
        XCTAssertNotNil(json["rest_period_seconds"])
    }

    // MARK: - CreateProgramInput Tests

    func testCreateProgramInput_Encoding() throws {
        let input = CreateProgramInput(
            patientId: "patient-1",
            name: "Test Program",
            targetLevel: "Intermediate",
            durationWeeks: 8,
            programType: "rehab"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(input)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["patient_id"] as? String, "patient-1")
        XCTAssertEqual(json["name"] as? String, "Test Program")
        XCTAssertEqual(json["target_level"] as? String, "Intermediate")
        XCTAssertEqual(json["duration_weeks"] as? Int, 8)
        XCTAssertEqual(json["program_type"] as? String, "rehab")
    }

    func testCreateProgramInput_NilPatientId() throws {
        let input = CreateProgramInput(
            patientId: nil,
            name: "Test Program",
            targetLevel: "Beginner",
            durationWeeks: 4,
            programType: "performance"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(input)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertTrue(json["patient_id"] is NSNull || json["patient_id"] == nil)
    }

    // MARK: - CreatePhaseInput Tests

    func testCreatePhaseInput_Encoding() throws {
        let input = CreatePhaseInput(
            programId: "program-1",
            phaseNumber: 2,
            name: "Development",
            durationWeeks: 4,
            goals: "Build strength"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(input)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["program_id"] as? String, "program-1")
        XCTAssertEqual(json["phase_number"] as? Int, 2)
        XCTAssertEqual(json["name"] as? String, "Development")
        XCTAssertEqual(json["duration_weeks"] as? Int, 4)
        XCTAssertEqual(json["goals"] as? String, "Build strength")
    }

    // MARK: - CreateSessionInput Tests

    func testCreateSessionInput_Encoding() throws {
        let input = CreateSessionInput(
            phaseId: "phase-1",
            name: "Upper Body",
            sequence: 1,
            weekday: 1,
            notes: "Focus on compound movements"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(input)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["phase_id"] as? String, "phase-1")
        XCTAssertEqual(json["name"] as? String, "Upper Body")
        XCTAssertEqual(json["sequence"] as? Int, 1)
        XCTAssertEqual(json["weekday"] as? Int, 1)
    }

    // MARK: - ProgramBuilderError Tests

    func testProgramBuilderError_ErrorDescriptions() {
        XCTAssertEqual(
            ProgramBuilderError.emptyProgramName.errorDescription,
            "Please enter a program name"
        )

        XCTAssertEqual(
            ProgramBuilderError.programNameTooShort.errorDescription,
            "Program name must be at least 3 characters"
        )

        XCTAssertEqual(
            ProgramBuilderError.programNameTooLong.errorDescription,
            "Program name must be 100 characters or less"
        )

        XCTAssertEqual(
            ProgramBuilderError.emptyTargetLevel.errorDescription,
            "Please select a target level"
        )

        XCTAssertEqual(
            ProgramBuilderError.noPhases.errorDescription,
            "Please add at least one phase to the program"
        )

        XCTAssertEqual(
            ProgramBuilderError.tooFewPhases(min: 3).errorDescription,
            "This protocol requires at least 3 phase(s)"
        )

        XCTAssertEqual(
            ProgramBuilderError.tooManyPhases(max: 5).errorDescription,
            "This protocol allows a maximum of 5 phase(s)"
        )

        XCTAssertEqual(
            ProgramBuilderError.emptyPhaseName(phaseNumber: 2).errorDescription,
            "Please enter a name for phase 2"
        )

        XCTAssertEqual(
            ProgramBuilderError.invalidPhaseDuration(phaseNumber: 1).errorDescription,
            "Phase 1 must have a duration greater than 0 weeks"
        )

        XCTAssertEqual(
            ProgramBuilderError.phaseDurationTooLong(phaseNumber: 3).errorDescription,
            "Phase 3 duration cannot exceed 52 weeks (1 year)"
        )

        XCTAssertEqual(
            ProgramBuilderError.invalidTotalDuration.errorDescription,
            "Total program duration must be greater than 0 weeks"
        )

        XCTAssertEqual(
            ProgramBuilderError.totalDurationTooLong.errorDescription,
            "Total program duration cannot exceed 104 weeks (2 years)"
        )

        XCTAssertEqual(
            ProgramBuilderError.phaseCreationFailed(phaseNumber: 1).errorDescription,
            "Failed to create phase 1. Please try again."
        )

        XCTAssertEqual(
            ProgramBuilderError.sessionCreationFailed(phaseNumber: 1, sessionNumber: 2).errorDescription,
            "Failed to create session 2 in phase 1. Please try again."
        )

        XCTAssertEqual(
            ProgramBuilderError.exerciseCreationFailed(phaseNumber: 1, sessionNumber: 2, exerciseNumber: 3).errorDescription,
            "Failed to create exercise 3 in session 2 of phase 1. Please try again."
        )

        XCTAssertEqual(
            ProgramBuilderError.databaseError(message: "Custom error").errorDescription,
            "Custom error"
        )

        XCTAssertEqual(
            ProgramBuilderError.databaseDecodingError.errorDescription,
            "Failed to process server response. Please try again."
        )

        XCTAssertEqual(
            ProgramBuilderError.operationInProgress.errorDescription,
            "Program creation already in progress. Please wait."
        )
    }

    // MARK: - Helper Methods

    private func createMockPhase(
        name: String = "Test Phase",
        durationWeeks: Int = 4,
        order: Int = 1
    ) -> ProgramPhase {
        return ProgramPhase(
            name: name,
            durationWeeks: durationWeeks,
            sessions: [],
            order: order
        )
    }
}

// MARK: - ProgramPhase Tests

@MainActor
final class ProgramPhaseTests: XCTestCase {

    func testProgramPhase_Initialization() {
        let phase = ProgramPhase(
            name: "Foundation",
            durationWeeks: 4,
            sessions: [],
            order: 1
        )

        XCTAssertEqual(phase.name, "Foundation")
        XCTAssertEqual(phase.durationWeeks, 4)
        XCTAssertTrue(phase.sessions.isEmpty)
        XCTAssertEqual(phase.order, 1)
    }
}

// MARK: - Exercise in Session Tests

@MainActor
final class ExerciseInSessionTests: XCTestCase {

    func testExercise_SetsProperty_UsedInProgramCreation() {
        // This test verifies that when creating a session exercise,
        // the Exercise.sets computed property is used correctly

        let exercise = createMockExercise(targetSets: 4, prescribedSets: 3)

        // In ProgramBuilderViewModel.createProgram, exercise.sets is used
        // to create the CreateSessionExerciseInput
        let input = CreateSessionExerciseInput(
            sessionId: UUID().uuidString,
            exerciseTemplateId: exercise.exercise_template_id.uuidString,
            sequence: 1,
            targetSets: exercise.sets, // This uses the computed property
            targetReps: exercise.prescribed_reps ?? "10",
            targetLoad: exercise.prescribed_load,
            loadUnit: exercise.load_unit,
            restPeriodSeconds: exercise.rest_period_seconds,
            notes: exercise.notes
        )

        XCTAssertEqual(input.targetSets, 4, "Should use target_sets from exercise.sets computed property")
    }

    func testExercise_SetsProperty_FallsBackToPrescribedSets() {
        let exercise = createMockExercise(targetSets: nil, prescribedSets: 3)

        let input = CreateSessionExerciseInput(
            sessionId: UUID().uuidString,
            exerciseTemplateId: exercise.exercise_template_id.uuidString,
            sequence: 1,
            targetSets: exercise.sets,
            targetReps: exercise.prescribed_reps ?? "10",
            targetLoad: exercise.prescribed_load,
            loadUnit: exercise.load_unit,
            restPeriodSeconds: exercise.rest_period_seconds,
            notes: exercise.notes
        )

        XCTAssertEqual(input.targetSets, 3, "Should fallback to prescribed_sets")
    }

    private func createMockExercise(
        targetSets: Int?,
        prescribedSets: Int?
    ) -> Exercise {
        let templateId = UUID()
        let template = Exercise.ExerciseTemplate(
            id: templateId,
            name: "Test",
            category: nil,
            body_region: nil,
            videoUrl: nil,
            videoThumbnailUrl: nil,
            videoDuration: nil,
            formCues: nil,
            techniqueCues: nil,
            commonMistakes: nil,
            safetyNotes: nil
        )

        return Exercise(
            id: UUID(),
            session_id: UUID(),
            exercise_template_id: templateId,
            sequence: 1,
            target_sets: targetSets,
            target_reps: 10,
            prescribed_sets: prescribedSets,
            prescribed_reps: "10",
            prescribed_load: 100.0,
            load_unit: "lbs",
            rest_period_seconds: 90,
            notes: nil,
            exercise_templates: template
        )
    }
}
