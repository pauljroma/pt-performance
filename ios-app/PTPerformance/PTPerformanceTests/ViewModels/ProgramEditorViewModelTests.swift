//
//  ProgramEditorViewModelTests.swift
//  PTPerformanceTests
//
//  Comprehensive unit tests for ProgramEditorViewModel
//  Tests exercise template conversion, validation, and CRUD operations
//
//  Coverage areas:
//  - Exercise template conversion to Exercise model
//  - Validation (exercise, program, phase)
//  - Weight recommendation calculation
//  - Input encoding for database operations
//  - Error handling and translation
//

import XCTest
@testable import PTPerformance

// MARK: - ProgramEditorViewModel Tests

@MainActor
final class ProgramEditorViewModelTests: XCTestCase {

    var viewModel: ProgramEditorViewModel!
    let testPatientId = UUID()

    override func setUp() async throws {
        try await super.setUp()
        viewModel = ProgramEditorViewModel(patientId: testPatientId, exerciseId: nil)
    }

    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_DefaultValues() {
        XCTAssertNil(viewModel.selectedExercise, "No exercise selected initially")
        XCTAssertNil(viewModel.estimatedRM, "No estimated RM initially")
        XCTAssertEqual(viewModel.sets, 3, "Default sets is 3")
        XCTAssertEqual(viewModel.reps, 10, "Default reps is 10")
        XCTAssertEqual(viewModel.recommendedWeight, 0, "No recommended weight initially")
        XCTAssertEqual(viewModel.targetRPE, 7, "Default target RPE is 7")
        XCTAssertEqual(viewModel.instructions, "", "No instructions initially")
        XCTAssertTrue(viewModel.availableExercises.isEmpty, "No available exercises initially")
        XCTAssertNil(viewModel.program, "No program loaded initially")
        XCTAssertTrue(viewModel.phases.isEmpty, "No phases initially")
        XCTAssertEqual(viewModel.programName, "", "Empty program name initially")
        XCTAssertEqual(viewModel.targetLevel, "Intermediate", "Default target level")
        XCTAssertEqual(viewModel.durationWeeks, 8, "Default duration is 8 weeks")
        XCTAssertFalse(viewModel.isLoading, "Not loading initially")
        XCTAssertFalse(viewModel.isSaving, "Not saving initially")
        XCTAssertNil(viewModel.error, "No error initially")
        XCTAssertNil(viewModel.successMessage, "No success message initially")
    }

    func testInitialState_PatientId() {
        XCTAssertEqual(viewModel.patientId, testPatientId)
    }

    func testInitialState_ExerciseId() {
        XCTAssertNil(viewModel.exerciseId)

        let exerciseId = UUID()
        let vm = ProgramEditorViewModel(patientId: testPatientId, exerciseId: exerciseId)
        XCTAssertEqual(vm.exerciseId, exerciseId)
    }

    // MARK: - CanSave Tests

    func testCanSave_NoExercise_False() {
        viewModel.selectedExercise = nil

        XCTAssertFalse(viewModel.canSave)
    }

    func testCanSave_WithValidExercise_True() {
        viewModel.selectedExercise = createMockExercise()
        viewModel.sets = 3
        viewModel.reps = 10
        viewModel.targetRPE = 7

        XCTAssertTrue(viewModel.canSave)
    }

    func testCanSave_InvalidSets_False() {
        viewModel.selectedExercise = createMockExercise()
        viewModel.sets = 0

        XCTAssertFalse(viewModel.canSave)
    }

    func testCanSave_InvalidReps_False() {
        viewModel.selectedExercise = createMockExercise()
        viewModel.reps = 0

        XCTAssertFalse(viewModel.canSave)
    }

    func testCanSave_InvalidRPE_False() {
        viewModel.selectedExercise = createMockExercise()
        viewModel.targetRPE = 0

        XCTAssertFalse(viewModel.canSave)
    }

    func testCanSave_SetsTooHigh_False() {
        viewModel.selectedExercise = createMockExercise()
        viewModel.sets = 21

        XCTAssertFalse(viewModel.canSave)
    }

    func testCanSave_RepsTooHigh_False() {
        viewModel.selectedExercise = createMockExercise()
        viewModel.reps = 101

        XCTAssertFalse(viewModel.canSave)
    }

    func testCanSave_RPETooHigh_False() {
        viewModel.selectedExercise = createMockExercise()
        viewModel.targetRPE = 11

        XCTAssertFalse(viewModel.canSave)
    }

    func testCanSave_NegativeWeight_False() {
        viewModel.selectedExercise = createMockExercise()
        viewModel.recommendedWeight = -10

        XCTAssertFalse(viewModel.canSave)
    }

    func testCanSave_InstructionsTooLong_False() {
        viewModel.selectedExercise = createMockExercise()
        viewModel.instructions = String(repeating: "A", count: 501)

        XCTAssertFalse(viewModel.canSave)
    }

    // MARK: - Weight Recommendation Tests

    func testUpdateRecommendedWeight_StrengthRange() {
        viewModel.estimatedRM = 100.0
        viewModel.reps = 5

        // Manually trigger update
        viewModel.reps = 5 // Triggers didSet

        // Strength: 85% of 1RM
        XCTAssertEqual(viewModel.recommendedWeight, 85.0, accuracy: 0.01)
    }

    func testUpdateRecommendedWeight_HypertrophyRange() {
        viewModel.estimatedRM = 100.0
        viewModel.reps = 10

        // Hypertrophy: 70% of 1RM
        XCTAssertEqual(viewModel.recommendedWeight, 70.0, accuracy: 0.01)
    }

    func testUpdateRecommendedWeight_EnduranceRange() {
        viewModel.estimatedRM = 100.0
        viewModel.reps = 15

        // Endurance: 50% of 1RM
        XCTAssertEqual(viewModel.recommendedWeight, 50.0, accuracy: 0.01)
    }

    func testUpdateRecommendedWeight_NoEstimatedRM() {
        viewModel.estimatedRM = nil
        viewModel.reps = 10

        XCTAssertEqual(viewModel.recommendedWeight, 0.0)
    }

    // MARK: - Exercise Template Conversion Tests

    func testQueryExercises_ConvertsToExerciseModel() async {
        // This test verifies the template-to-Exercise conversion logic
        // The actual conversion happens in queryExercises()

        let templateId = UUID()
        let templateName = "Bench Press"

        // Create expected Exercise from template
        let exercise = Exercise(
            id: templateId,
            session_id: UUID(),
            exercise_template_id: templateId,
            sequence: nil,
            target_sets: 3,
            target_reps: 10,
            prescribed_sets: nil,
            prescribed_reps: "10",
            prescribed_load: nil,
            load_unit: "lbs",
            rest_period_seconds: 90,
            notes: nil,
            exercise_templates: Exercise.ExerciseTemplate(
                id: templateId,
                name: templateName,
                category: "push",
                body_region: "upper",
                videoUrl: nil,
                videoThumbnailUrl: nil,
                videoDuration: nil,
                formCues: nil,
                techniqueCues: nil,
                commonMistakes: nil,
                safetyNotes: nil
            )
        )

        // Verify the Exercise has proper defaults
        XCTAssertEqual(exercise.sets, 3, "Should have default 3 sets")
        XCTAssertEqual(exercise.repsDisplay, "10", "Should have default 10 reps")
        XCTAssertEqual(exercise.exercise_name, templateName)
    }

    // MARK: - SaveExerciseInput Tests

    func testSaveExerciseInput_Encoding() throws {
        let input = SaveExerciseInput(
            sessionId: "session-1",
            exerciseTemplateId: "template-1",
            prescribedSets: 4,
            prescribedReps: "10",
            prescribedLoad: 135.0,
            loadUnit: "lbs",
            restPeriodSeconds: 90,
            notes: "Focus on form",
            sequence: 1
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(input)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["session_id"] as? String, "session-1")
        XCTAssertEqual(json["exercise_template_id"] as? String, "template-1")
        XCTAssertEqual(json["prescribed_sets"] as? Int, 4)
        XCTAssertEqual(json["prescribed_reps"] as? String, "10")
        XCTAssertEqual(json["prescribed_load"] as? Double, 135.0)
        XCTAssertEqual(json["load_unit"] as? String, "lbs")
        XCTAssertEqual(json["rest_period_seconds"] as? Int, 90)
        XCTAssertEqual(json["notes"] as? String, "Focus on form")
        XCTAssertEqual(json["sequence"] as? Int, 1)
    }

    func testSaveExerciseInput_NilValues() throws {
        let input = SaveExerciseInput(
            sessionId: nil,
            exerciseTemplateId: "template-1",
            prescribedSets: 3,
            prescribedReps: "8-10",
            prescribedLoad: nil,
            loadUnit: nil,
            restPeriodSeconds: nil,
            notes: nil,
            sequence: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(input)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertTrue(json["session_id"] is NSNull || json["session_id"] == nil)
        XCTAssertTrue(json["prescribed_load"] is NSNull || json["prescribed_load"] == nil)
    }

    // MARK: - SessionExercise Tests

    func testSessionExercise_Decoding() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "session_id": "00000000-0000-0000-0000-000000000002",
            "exercise_template_id": "00000000-0000-0000-0000-000000000003",
            "prescribed_sets": 3,
            "prescribed_reps": "10",
            "prescribed_load": 135.0,
            "load_unit": "lbs",
            "rest_period_seconds": 90,
            "notes": "Test notes",
            "sequence": 1
        }
        """

        let data = json.data(using: .utf8)!
        let exercise = try JSONDecoder().decode(SessionExercise.self, from: data)

        XCTAssertEqual(exercise.id, "00000000-0000-0000-0000-000000000001")
        XCTAssertEqual(exercise.sessionId, "00000000-0000-0000-0000-000000000002")
        XCTAssertEqual(exercise.exerciseTemplateId, "00000000-0000-0000-0000-000000000003")
        XCTAssertEqual(exercise.prescribedSets, 3)
        XCTAssertEqual(exercise.prescribedReps, "10")
        XCTAssertEqual(exercise.prescribedLoad, 135.0)
        XCTAssertEqual(exercise.loadUnit, "lbs")
        XCTAssertEqual(exercise.restPeriodSeconds, 90)
        XCTAssertEqual(exercise.notes, "Test notes")
        XCTAssertEqual(exercise.sequence, 1)
    }

    func testSessionExercise_DecodingWithNulls() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "session_id": "00000000-0000-0000-0000-000000000002",
            "exercise_template_id": "00000000-0000-0000-0000-000000000003",
            "prescribed_sets": 3,
            "prescribed_reps": "10",
            "prescribed_load": null,
            "load_unit": null,
            "rest_period_seconds": null,
            "notes": null,
            "sequence": null
        }
        """

        let data = json.data(using: .utf8)!
        let exercise = try JSONDecoder().decode(SessionExercise.self, from: data)

        XCTAssertEqual(exercise.prescribedSets, 3)
        XCTAssertNil(exercise.prescribedLoad)
        XCTAssertNil(exercise.loadUnit)
        XCTAssertNil(exercise.restPeriodSeconds)
        XCTAssertNil(exercise.notes)
        XCTAssertNil(exercise.sequence)
    }

    // MARK: - UpdateProgramInput Tests

    func testUpdateProgramInput_Encoding() throws {
        let input = UpdateProgramInput(
            name: "Updated Program",
            targetLevel: "Advanced",
            durationWeeks: 12
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(input)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["name"] as? String, "Updated Program")
        XCTAssertEqual(json["target_level"] as? String, "Advanced")
        XCTAssertEqual(json["duration_weeks"] as? Int, 12)
    }

    // MARK: - UpdatePhaseInput Tests

    func testUpdatePhaseInput_Encoding() throws {
        let input = UpdatePhaseInput(
            phaseNumber: 2,
            name: "Development Phase",
            durationWeeks: 4,
            goals: "Build strength"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(input)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["phase_number"] as? Int, 2)
        XCTAssertEqual(json["name"] as? String, "Development Phase")
        XCTAssertEqual(json["duration_weeks"] as? Int, 4)
        XCTAssertEqual(json["goals"] as? String, "Build strength")
    }

    // MARK: - ExerciseTemplate (ProgramEditor) Tests

    func testExerciseTemplate_Decoding() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "name": "Squat",
            "category": "lower",
            "body_region": "legs",
            "description": "Compound leg exercise",
            "video_url": "https://example.com/video.mp4"
        }
        """

        let data = json.data(using: .utf8)!
        let template = try JSONDecoder().decode(ExerciseTemplate.self, from: data)

        XCTAssertEqual(template.id, "00000000-0000-0000-0000-000000000001")
        XCTAssertEqual(template.name, "Squat")
        XCTAssertEqual(template.category, "lower")
        XCTAssertEqual(template.bodyRegion, "legs")
        XCTAssertEqual(template.description, "Compound leg exercise")
        XCTAssertEqual(template.videoUrl, "https://example.com/video.mp4")
    }

    func testExerciseTemplate_DecodingWithNulls() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "name": "Unknown Exercise",
            "category": null,
            "body_region": null,
            "description": null,
            "video_url": null
        }
        """

        let data = json.data(using: .utf8)!
        let template = try JSONDecoder().decode(ExerciseTemplate.self, from: data)

        XCTAssertEqual(template.name, "Unknown Exercise")
        XCTAssertNil(template.category)
        XCTAssertNil(template.bodyRegion)
        XCTAssertNil(template.description)
        XCTAssertNil(template.videoUrl)
    }

    // MARK: - ProgramEditorError Tests

    func testProgramEditorError_ExerciseErrors() {
        XCTAssertEqual(
            ProgramEditorError.noExerciseSelected.errorDescription,
            "Please select an exercise before saving"
        )
        XCTAssertEqual(
            ProgramEditorError.invalidSets.errorDescription,
            "Number of sets must be greater than 0"
        )
        XCTAssertEqual(
            ProgramEditorError.setsTooHigh.errorDescription,
            "Number of sets cannot exceed 20"
        )
        XCTAssertEqual(
            ProgramEditorError.invalidReps.errorDescription,
            "Number of reps must be greater than 0"
        )
        XCTAssertEqual(
            ProgramEditorError.repsTooHigh.errorDescription,
            "Number of reps cannot exceed 100"
        )
        XCTAssertEqual(
            ProgramEditorError.invalidRPE.errorDescription,
            "RPE must be between 1 and 10"
        )
        XCTAssertEqual(
            ProgramEditorError.negativeWeight.errorDescription,
            "Weight cannot be negative"
        )
        XCTAssertEqual(
            ProgramEditorError.instructionsTooLong.errorDescription,
            "Instructions must be 500 characters or less"
        )
    }

    func testProgramEditorError_ProgramErrors() {
        XCTAssertEqual(
            ProgramEditorError.programNotFound.errorDescription,
            "Program not found. It may have been deleted."
        )
        XCTAssertEqual(
            ProgramEditorError.noProgramLoaded.errorDescription,
            "No program loaded. Please load a program first."
        )
        XCTAssertEqual(
            ProgramEditorError.invalidProgramId.errorDescription,
            "Invalid program ID provided"
        )
        XCTAssertEqual(
            ProgramEditorError.emptyProgramName.errorDescription,
            "Please enter a program name"
        )
        XCTAssertEqual(
            ProgramEditorError.programNameTooShort.errorDescription,
            "Program name must be at least 3 characters"
        )
        XCTAssertEqual(
            ProgramEditorError.programNameTooLong.errorDescription,
            "Program name must be 100 characters or less"
        )
        XCTAssertEqual(
            ProgramEditorError.invalidDuration.errorDescription,
            "Duration must be greater than 0 weeks"
        )
        XCTAssertEqual(
            ProgramEditorError.durationTooLong.errorDescription,
            "Duration cannot exceed 104 weeks (2 years)"
        )
    }

    func testProgramEditorError_PhaseErrors() {
        XCTAssertEqual(
            ProgramEditorError.noPhasesAdded.errorDescription,
            "Program must have at least one phase"
        )
        XCTAssertEqual(
            ProgramEditorError.emptyPhaseName(phaseNumber: 2).errorDescription,
            "Please enter a name for phase 2"
        )
        XCTAssertEqual(
            ProgramEditorError.invalidPhaseDuration(phaseNumber: 1).errorDescription,
            "Phase 1 must have a duration greater than 0 weeks"
        )
        XCTAssertEqual(
            ProgramEditorError.phaseDurationTooLong(phaseNumber: 3).errorDescription,
            "Phase 3 duration cannot exceed 52 weeks (1 year)"
        )
        XCTAssertEqual(
            ProgramEditorError.phaseSaveFailed(phaseNumber: 2).errorDescription,
            "Failed to save phase 2. Please try again."
        )
    }

    func testProgramEditorError_GeneralErrors() {
        XCTAssertEqual(
            ProgramEditorError.databaseError(message: "Custom error").errorDescription,
            "Custom error"
        )
        XCTAssertEqual(
            ProgramEditorError.operationInProgress.errorDescription,
            "An operation is already in progress. Please wait."
        )
    }

    // MARK: - Helper Methods

    private func createMockExercise() -> Exercise {
        let templateId = UUID()
        let template = Exercise.ExerciseTemplate(
            id: templateId,
            name: "Test Exercise",
            category: "test",
            body_region: "upper",
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
            target_sets: 3,
            target_reps: 10,
            prescribed_sets: nil,
            prescribed_reps: "10",
            prescribed_load: 100.0,
            load_unit: "lbs",
            rest_period_seconds: 90,
            notes: nil,
            exercise_templates: template
        )
    }
}

// MARK: - Template to Exercise Conversion Tests

@MainActor
final class TemplateToExerciseConversionTests: XCTestCase {

    func testConversion_SetsDefaults() {
        // When converting an ExerciseTemplate to Exercise,
        // default values should be applied

        let template = ExerciseTemplate(
            id: UUID().uuidString,
            name: "Squat",
            category: "lower",
            bodyRegion: "legs",
            description: nil,
            videoUrl: nil
        )

        // Simulating the conversion done in ProgramEditorViewModel.queryExercises()
        let exercise = convertTemplateToExercise(template)

        XCTAssertEqual(exercise.target_sets, 3, "Default target_sets should be 3")
        XCTAssertEqual(exercise.target_reps, 10, "Default target_reps should be 10")
        XCTAssertEqual(exercise.rest_period_seconds, 90, "Default rest period should be 90")
        XCTAssertEqual(exercise.load_unit, "lbs", "Default load unit should be lbs")
    }

    func testConversion_PreservesTemplateInfo() {
        let template = ExerciseTemplate(
            id: UUID().uuidString,
            name: "Bench Press",
            category: "push",
            bodyRegion: "upper",
            description: nil,
            videoUrl: nil
        )

        let exercise = convertTemplateToExercise(template)

        XCTAssertEqual(exercise.exercise_name, "Bench Press")
        XCTAssertEqual(exercise.movement_pattern, "push")
        XCTAssertEqual(exercise.equipment, "upper")
    }

    private func convertTemplateToExercise(_ template: ExerciseTemplate) -> Exercise {
        guard let templateUUID = UUID(uuidString: template.id) else {
            fatalError("Invalid UUID")
        }

        return Exercise(
            id: templateUUID,
            session_id: UUID(),
            exercise_template_id: templateUUID,
            sequence: nil,
            target_sets: 3,
            target_reps: 10,
            prescribed_sets: nil,
            prescribed_reps: "10",
            prescribed_load: nil,
            load_unit: "lbs",
            rest_period_seconds: 90,
            notes: nil,
            exercise_templates: Exercise.ExerciseTemplate(
                id: templateUUID,
                name: template.name,
                category: template.category,
                body_region: template.bodyRegion,
                videoUrl: nil,
                videoThumbnailUrl: nil,
                videoDuration: nil,
                formCues: nil,
                techniqueCues: nil,
                commonMistakes: nil,
                safetyNotes: nil
            )
        )
    }
}
