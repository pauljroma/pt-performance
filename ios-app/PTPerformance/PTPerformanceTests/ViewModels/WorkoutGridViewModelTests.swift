//
//  WorkoutGridViewModelTests.swift
//  PTPerformanceTests
//
//  Comprehensive unit tests for WorkoutGridViewModel
//  Tests SessionExerciseWithTemplate decoding, exercise grid operations,
//  validation, and real-time sync handling
//
//  Coverage areas:
//  - SessionExerciseWithTemplate decoding with target_sets/prescribed_sets
//  - Grid exercise CRUD operations
//  - Cell validation
//  - Error handling
//  - Optimistic updates
//

import XCTest
@testable import PTPerformance

// MARK: - Mock PTSupabaseClient for WorkoutGrid Testing

/// Mock Supabase client for controlled testing of WorkoutGridViewModel
class MockPTSupabaseClientForWorkoutGrid {
    var mockExercises: [SessionExerciseWithTemplate] = []
    var mockExerciseTemplates: [GridExerciseTemplate] = []
    var shouldFailLoad: Bool = false
    var shouldFailSave: Bool = false
    var mockError: Error?

    // Track method calls
    var loadExercisesCalled = false
    var loadTemplatesCalled = false
    var saveExerciseCalled = false
    var deleteExerciseCalled = false

    // Captured data
    var lastSavedExercise: WorkoutGridExercise?
    var lastDeletedExerciseId: String?
}

// MARK: - WorkoutGridViewModel Tests

@MainActor
final class WorkoutGridViewModelTests: XCTestCase {

    var viewModel: WorkoutGridViewModel!
    let testSessionId = "00000000-0000-0000-0000-000000000001"

    override func setUp() async throws {
        try await super.setUp()
        viewModel = WorkoutGridViewModel(sessionId: testSessionId)
    }

    override func tearDown() async throws {
        viewModel?.unsubscribeFromRealtimeUpdates()
        viewModel = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_DefaultValues() {
        XCTAssertTrue(viewModel.exercises.isEmpty, "Exercises should be empty initially")
        XCTAssertTrue(viewModel.availableExercises.isEmpty, "Available exercises should be empty initially")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading initially")
        XCTAssertFalse(viewModel.isSyncing, "Should not be syncing initially")
        XCTAssertNil(viewModel.error, "Should have no error initially")
        XCTAssertNil(viewModel.successMessage, "Should have no success message initially")
        XCTAssertFalse(viewModel.hasUnsavedChanges, "Should have no unsaved changes initially")
    }

    func testInitialState_SessionId() {
        XCTAssertEqual(viewModel.sessionId, testSessionId, "Session ID should be set")
    }

    // MARK: - SessionExerciseWithTemplate Decoding Tests

    func testSessionExerciseWithTemplate_SetsComputedProperty_PrefersTargetSets() {
        let exercise = createMockSessionExerciseWithTemplate(
            targetSets: 4,
            prescribedSets: 3
        )

        XCTAssertEqual(exercise.sets, 4, "Should prefer target_sets over prescribed_sets")
    }

    func testSessionExerciseWithTemplate_SetsComputedProperty_FallsBackToPrescribedSets() {
        let exercise = createMockSessionExerciseWithTemplate(
            targetSets: nil,
            prescribedSets: 3
        )

        XCTAssertEqual(exercise.sets, 3, "Should fallback to prescribed_sets when target_sets is nil")
    }

    func testSessionExerciseWithTemplate_SetsComputedProperty_ReturnsZeroWhenBothNil() {
        let exercise = createMockSessionExerciseWithTemplate(
            targetSets: nil,
            prescribedSets: nil
        )

        XCTAssertEqual(exercise.sets, 0, "Should return 0 when both target_sets and prescribed_sets are nil")
    }

    func testSessionExerciseWithTemplate_DecodesFromJSON_WithTargetSets() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "session_id": "00000000-0000-0000-0000-000000000002",
            "exercise_template_id": "00000000-0000-0000-0000-000000000003",
            "target_sets": 4,
            "target_reps": 10,
            "prescribed_sets": null,
            "prescribed_reps": "8-10",
            "prescribed_load": 135.0,
            "load_unit": "lbs",
            "rest_period_seconds": 90,
            "notes": null,
            "sequence": 1,
            "exercise_templates": {
                "id": "00000000-0000-0000-0000-000000000003",
                "name": "Bench Press",
                "category": "push",
                "body_region": "upper"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let exercise = try JSONDecoder().decode(SessionExerciseWithTemplate.self, from: data)

        XCTAssertEqual(exercise.target_sets, 4)
        XCTAssertNil(exercise.prescribed_sets)
        XCTAssertEqual(exercise.sets, 4, "Sets computed property should use target_sets")
        XCTAssertEqual(exercise.exercise_templates?.name, "Bench Press")
    }

    func testSessionExerciseWithTemplate_DecodesFromJSON_WithPrescribedSets() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "session_id": "00000000-0000-0000-0000-000000000002",
            "exercise_template_id": "00000000-0000-0000-0000-000000000003",
            "target_sets": null,
            "target_reps": null,
            "prescribed_sets": 3,
            "prescribed_reps": "8-10",
            "prescribed_load": 100.0,
            "load_unit": "lbs",
            "rest_period_seconds": 60,
            "notes": "Focus on form",
            "sequence": 1,
            "exercise_templates": {
                "id": "00000000-0000-0000-0000-000000000003",
                "name": "Squat",
                "category": "lower",
                "body_region": "legs"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let exercise = try JSONDecoder().decode(SessionExerciseWithTemplate.self, from: data)

        XCTAssertNil(exercise.target_sets)
        XCTAssertEqual(exercise.prescribed_sets, 3)
        XCTAssertEqual(exercise.sets, 3, "Sets computed property should fallback to prescribed_sets")
    }

    func testSessionExerciseWithTemplate_DecodesFromJSON_WithNullSets() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "session_id": "00000000-0000-0000-0000-000000000002",
            "exercise_template_id": "00000000-0000-0000-0000-000000000003",
            "target_sets": null,
            "target_reps": null,
            "prescribed_sets": null,
            "prescribed_reps": null,
            "prescribed_load": null,
            "load_unit": null,
            "rest_period_seconds": null,
            "notes": null,
            "sequence": null,
            "exercise_templates": null
        }
        """

        let data = json.data(using: .utf8)!
        let exercise = try JSONDecoder().decode(SessionExerciseWithTemplate.self, from: data)

        XCTAssertNil(exercise.target_sets)
        XCTAssertNil(exercise.prescribed_sets)
        XCTAssertEqual(exercise.sets, 0, "Sets should be 0 when both are null")
        XCTAssertNil(exercise.exercise_templates)
    }

    func testSessionExerciseWithTemplate_DecodesFromJSON_WithExerciseTemplate() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "session_id": "00000000-0000-0000-0000-000000000002",
            "exercise_template_id": "00000000-0000-0000-0000-000000000003",
            "target_sets": 3,
            "target_reps": 10,
            "prescribed_sets": null,
            "prescribed_reps": null,
            "prescribed_load": null,
            "load_unit": null,
            "rest_period_seconds": null,
            "notes": null,
            "sequence": 1,
            "exercise_templates": {
                "id": "00000000-0000-0000-0000-000000000003",
                "name": "Deadlift",
                "category": "hinge",
                "body_region": "posterior"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let exercise = try JSONDecoder().decode(SessionExerciseWithTemplate.self, from: data)

        XCTAssertNotNil(exercise.exercise_templates)
        XCTAssertEqual(exercise.exercise_templates?.name, "Deadlift")
        XCTAssertEqual(exercise.exercise_templates?.category, "hinge")
        XCTAssertEqual(exercise.exercise_templates?.body_region, "posterior")
    }

    // MARK: - WorkoutGridExercise Tests

    func testWorkoutGridExercise_Initialization() {
        let exercise = createMockWorkoutGridExercise(
            exerciseName: "Squat",
            prescribedSets: 3,
            prescribedReps: "10",
            prescribedLoad: 185.0
        )

        XCTAssertEqual(exercise.exerciseName, "Squat")
        XCTAssertEqual(exercise.prescribedSets, 3)
        XCTAssertEqual(exercise.prescribedReps, "10")
        XCTAssertEqual(exercise.prescribedLoad, 185.0)
    }

    func testWorkoutGridExercise_Equatable() {
        // Use consistent values for ALL properties to ensure equality
        let sharedSessionId = UUID().uuidString
        let sharedTemplateId = UUID().uuidString

        let exercise1 = createMockWorkoutGridExercise(
            id: "test-id",
            sessionId: sharedSessionId,
            exerciseTemplateId: sharedTemplateId,
            exerciseName: "Squat"
        )
        let exercise2 = createMockWorkoutGridExercise(
            id: "test-id",
            sessionId: sharedSessionId,
            exerciseTemplateId: sharedTemplateId,
            exerciseName: "Squat"
        )
        let exercise3 = createMockWorkoutGridExercise(
            id: "different-id",
            sessionId: sharedSessionId,
            exerciseTemplateId: sharedTemplateId,
            exerciseName: "Squat"
        )

        XCTAssertEqual(exercise1, exercise2, "Exercises with same properties should be equal")
        XCTAssertNotEqual(exercise1, exercise3, "Exercises with different IDs should not be equal")
    }

    // MARK: - Cell Update Tests

    func testUpdateCell_Exercise() {
        let exercise = createMockWorkoutGridExercise(exerciseName: "Squat")
        viewModel.exercises = [exercise]

        let newTemplateId = UUID().uuidString
        viewModel.availableExercises = [
            GridExerciseTemplate(id: newTemplateId, name: "Deadlift", category: "hinge", body_region: "posterior")
        ]

        viewModel.updateCell(exerciseId: exercise.id, field: .exercise, value: newTemplateId)

        XCTAssertEqual(viewModel.exercises[0].exerciseTemplateId, newTemplateId)
        XCTAssertEqual(viewModel.exercises[0].exerciseName, "Deadlift")
        XCTAssertTrue(viewModel.hasUnsavedChanges)
    }

    func testUpdateCell_Sets() {
        let exercise = createMockWorkoutGridExercise(prescribedSets: 3)
        viewModel.exercises = [exercise]

        viewModel.updateCell(exerciseId: exercise.id, field: .sets, value: 5)

        XCTAssertEqual(viewModel.exercises[0].prescribedSets, 5)
        XCTAssertTrue(viewModel.hasUnsavedChanges)
    }

    func testUpdateCell_Reps() {
        let exercise = createMockWorkoutGridExercise(prescribedReps: "10")
        viewModel.exercises = [exercise]

        viewModel.updateCell(exerciseId: exercise.id, field: .reps, value: "8-12")

        XCTAssertEqual(viewModel.exercises[0].prescribedReps, "8-12")
        XCTAssertTrue(viewModel.hasUnsavedChanges)
    }

    func testUpdateCell_Weight_Double() {
        let exercise = createMockWorkoutGridExercise(prescribedLoad: 100.0)
        viewModel.exercises = [exercise]

        viewModel.updateCell(exerciseId: exercise.id, field: .weight, value: 135.0)

        XCTAssertEqual(viewModel.exercises[0].prescribedLoad, 135.0)
        XCTAssertTrue(viewModel.hasUnsavedChanges)
    }

    func testUpdateCell_Weight_String() {
        let exercise = createMockWorkoutGridExercise(prescribedLoad: 100.0)
        viewModel.exercises = [exercise]

        viewModel.updateCell(exerciseId: exercise.id, field: .weight, value: "150")

        XCTAssertEqual(viewModel.exercises[0].prescribedLoad, 150.0)
        XCTAssertTrue(viewModel.hasUnsavedChanges)
    }

    func testUpdateCell_Notes() {
        let exercise = createMockWorkoutGridExercise(notes: nil)
        viewModel.exercises = [exercise]

        viewModel.updateCell(exerciseId: exercise.id, field: .notes, value: "Focus on form")

        XCTAssertEqual(viewModel.exercises[0].notes, "Focus on form")
        XCTAssertTrue(viewModel.hasUnsavedChanges)
    }

    func testUpdateCell_Notes_EmptyStringBecomesNil() {
        let exercise = createMockWorkoutGridExercise(notes: "Some notes")
        viewModel.exercises = [exercise]

        viewModel.updateCell(exerciseId: exercise.id, field: .notes, value: "")

        XCTAssertNil(viewModel.exercises[0].notes)
        XCTAssertTrue(viewModel.hasUnsavedChanges)
    }

    func testUpdateCell_InvalidExerciseId_NoChange() {
        let exercise = createMockWorkoutGridExercise(prescribedSets: 3)
        viewModel.exercises = [exercise]

        viewModel.updateCell(exerciseId: "invalid-id", field: .sets, value: 5)

        XCTAssertEqual(viewModel.exercises[0].prescribedSets, 3, "Should not change when ID not found")
        XCTAssertFalse(viewModel.hasUnsavedChanges)
    }

    func testUpdateCell_InvalidSetsValue_NoChange() {
        let exercise = createMockWorkoutGridExercise(prescribedSets: 3)
        viewModel.exercises = [exercise]

        viewModel.updateCell(exerciseId: exercise.id, field: .sets, value: 0)

        XCTAssertEqual(viewModel.exercises[0].prescribedSets, 3, "Should not accept 0 sets")
    }

    // MARK: - Add/Remove Exercise Tests

    func testAddExerciseRow() {
        XCTAssertEqual(viewModel.exercises.count, 0)

        viewModel.addExerciseRow()

        XCTAssertEqual(viewModel.exercises.count, 1)
        XCTAssertEqual(viewModel.exercises[0].exerciseName, "Select Exercise")
        XCTAssertEqual(viewModel.exercises[0].prescribedSets, 3)
        XCTAssertEqual(viewModel.exercises[0].prescribedReps, "10")
        XCTAssertTrue(viewModel.hasUnsavedChanges)
    }

    func testAddExerciseRow_SetsCorrectSequence() {
        viewModel.exercises = [
            createMockWorkoutGridExercise(sequence: 0),
            createMockWorkoutGridExercise(sequence: 1)
        ]

        viewModel.addExerciseRow()

        XCTAssertEqual(viewModel.exercises[2].sequence, 2)
    }

    func testRemoveExerciseRow() {
        let exercise = createMockWorkoutGridExercise()
        viewModel.exercises = [exercise]

        viewModel.removeExerciseRow(exerciseId: exercise.id)

        XCTAssertTrue(viewModel.exercises.isEmpty)
        XCTAssertTrue(viewModel.hasUnsavedChanges)
    }

    func testRemoveExerciseRow_InvalidId_NoChange() {
        let exercise = createMockWorkoutGridExercise()
        viewModel.exercises = [exercise]

        viewModel.removeExerciseRow(exerciseId: "invalid-id")

        XCTAssertEqual(viewModel.exercises.count, 1)
    }

    // MARK: - Validation Tests

    func testValidation_NoExerciseSelected_Error() {
        let exercise = createMockWorkoutGridExercise(exerciseTemplateId: "")

        XCTAssertThrowsError(try validateExercise(exercise)) { error in
            XCTAssertEqual(error as? WorkoutGridError, .noExerciseSelected)
        }
    }

    func testValidation_InvalidSets_Error() {
        let exercise = createMockWorkoutGridExercise(prescribedSets: 0)

        XCTAssertThrowsError(try validateExercise(exercise)) { error in
            XCTAssertEqual(error as? WorkoutGridError, .invalidSets)
        }
    }

    func testValidation_SetsTooHigh_Error() {
        let exercise = createMockWorkoutGridExercise(prescribedSets: 21)

        XCTAssertThrowsError(try validateExercise(exercise)) { error in
            XCTAssertEqual(error as? WorkoutGridError, .setsTooHigh)
        }
    }

    func testValidation_InvalidReps_Error() {
        let exercise = createMockWorkoutGridExercise(prescribedReps: "")

        XCTAssertThrowsError(try validateExercise(exercise)) { error in
            XCTAssertEqual(error as? WorkoutGridError, .invalidReps)
        }
    }

    func testValidation_InvalidRepsFormat_Error() {
        let exercise = createMockWorkoutGridExercise(prescribedReps: "abc")

        XCTAssertThrowsError(try validateExercise(exercise)) { error in
            XCTAssertEqual(error as? WorkoutGridError, .invalidRepsFormat)
        }
    }

    func testValidation_NegativeWeight_Error() {
        let exercise = createMockWorkoutGridExercise(prescribedLoad: -10.0)

        XCTAssertThrowsError(try validateExercise(exercise)) { error in
            XCTAssertEqual(error as? WorkoutGridError, .negativeWeight)
        }
    }

    func testValidation_ValidExercise_NoError() {
        let exercise = createMockWorkoutGridExercise(
            exerciseTemplateId: UUID().uuidString,
            prescribedSets: 3,
            prescribedReps: "10",
            prescribedLoad: 100.0
        )

        XCTAssertNoThrow(try validateExercise(exercise))
    }

    func testValidation_ValidRepsRange_NoError() {
        let exercise = createMockWorkoutGridExercise(
            exerciseTemplateId: UUID().uuidString,
            prescribedSets: 3,
            prescribedReps: "8-10",
            prescribedLoad: nil
        )

        XCTAssertNoThrow(try validateExercise(exercise))
    }

    // MARK: - WorkoutGridError Tests

    func testWorkoutGridError_ErrorDescriptions() {
        XCTAssertEqual(WorkoutGridError.noExerciseSelected.errorDescription, "Please select an exercise")
        XCTAssertEqual(WorkoutGridError.invalidSets.errorDescription, "Sets must be greater than 0")
        XCTAssertEqual(WorkoutGridError.setsTooHigh.errorDescription, "Sets cannot exceed 20")
        XCTAssertEqual(WorkoutGridError.invalidReps.errorDescription, "Reps cannot be empty")
        XCTAssertEqual(WorkoutGridError.invalidRepsFormat.errorDescription, "Reps must be a number or range (e.g., '10' or '8-10')")
        XCTAssertEqual(WorkoutGridError.negativeWeight.errorDescription, "Weight cannot be negative")
    }

    // MARK: - GridExerciseTemplate Tests

    func testGridExerciseTemplate_DecodesFromJSON() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "name": "Bench Press",
            "category": "push",
            "body_region": "upper"
        }
        """

        let data = json.data(using: .utf8)!
        let template = try JSONDecoder().decode(GridExerciseTemplate.self, from: data)

        XCTAssertEqual(template.id, "00000000-0000-0000-0000-000000000001")
        XCTAssertEqual(template.name, "Bench Press")
        XCTAssertEqual(template.category, "push")
        XCTAssertEqual(template.body_region, "upper")
    }

    func testGridExerciseTemplate_Hashable() {
        let template1 = GridExerciseTemplate(id: "1", name: "Squat", category: nil, body_region: nil)
        let template2 = GridExerciseTemplate(id: "1", name: "Squat", category: nil, body_region: nil)

        XCTAssertEqual(template1, template2)
        XCTAssertEqual(template1.hashValue, template2.hashValue)
    }

    // MARK: - GridField Tests

    func testGridField_AllCases() {
        let fields: [GridField] = [.exercise, .sets, .reps, .weight, .notes]
        XCTAssertEqual(fields.count, 5, "Should have all grid field types")
    }

    // MARK: - Discard Changes Tests

    func testDiscardChanges_ClearsUnsavedChanges() async {
        let exercise = createMockWorkoutGridExercise()
        viewModel.exercises = [exercise]
        viewModel.updateCell(exerciseId: exercise.id, field: .sets, value: 5)

        XCTAssertTrue(viewModel.hasUnsavedChanges)

        await viewModel.discardChanges()

        XCTAssertFalse(viewModel.hasUnsavedChanges)
    }

    // MARK: - Input Models Tests

    func testGridSaveExerciseInput_EncodesCorrectly() throws {
        let input = GridSaveExerciseInput(
            sessionId: "session-1",
            exerciseTemplateId: "template-1",
            prescribedSets: 3,
            prescribedReps: "10",
            prescribedLoad: 135.0,
            loadUnit: "lbs",
            restPeriodSeconds: 90,
            notes: "Test notes",
            sequence: 1
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(input)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["session_id"] as? String, "session-1")
        XCTAssertEqual(json["exercise_template_id"] as? String, "template-1")
        XCTAssertEqual(json["prescribed_sets"] as? Int, 3)
        XCTAssertEqual(json["prescribed_reps"] as? String, "10")
        XCTAssertEqual(json["prescribed_load"] as? Double, 135.0)
        XCTAssertEqual(json["load_unit"] as? String, "lbs")
        XCTAssertEqual(json["rest_period_seconds"] as? Int, 90)
    }

    func testGridUpdateExerciseInput_EncodesCorrectly() throws {
        let input = GridUpdateExerciseInput(
            prescribedSets: 4,
            prescribedReps: "8-12",
            prescribedLoad: 150.0,
            loadUnit: "kg",
            restPeriodSeconds: 120,
            notes: "Updated notes"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(input)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["prescribed_sets"] as? Int, 4)
        XCTAssertEqual(json["prescribed_reps"] as? String, "8-12")
        XCTAssertEqual(json["prescribed_load"] as? Double, 150.0)
        XCTAssertEqual(json["load_unit"] as? String, "kg")
        XCTAssertEqual(json["rest_period_seconds"] as? Int, 120)
    }

    // MARK: - Helper Methods

    private func createMockSessionExerciseWithTemplate(
        id: String = UUID().uuidString,
        sessionId: String = UUID().uuidString,
        exerciseTemplateId: String = UUID().uuidString,
        targetSets: Int? = nil,
        targetReps: Int? = nil,
        prescribedSets: Int? = nil,
        prescribedReps: String? = nil,
        prescribedLoad: Double? = nil,
        loadUnit: String? = nil,
        restPeriodSeconds: Int? = nil,
        notes: String? = nil,
        sequence: Int? = nil,
        templateName: String = "Test Exercise"
    ) -> SessionExerciseWithTemplate {
        let template = SessionExerciseWithTemplate.ExerciseTemplateBasic(
            id: exerciseTemplateId,
            name: templateName,
            category: "test",
            body_region: "upper"
        )

        return SessionExerciseWithTemplate(
            id: id,
            session_id: sessionId,
            exercise_template_id: exerciseTemplateId,
            target_sets: targetSets,
            target_reps: targetReps,
            prescribed_sets: prescribedSets,
            prescribed_reps: prescribedReps,
            prescribed_load: prescribedLoad,
            load_unit: loadUnit,
            rest_period_seconds: restPeriodSeconds,
            notes: notes,
            sequence: sequence,
            exercise_templates: template
        )
    }

    private func createMockWorkoutGridExercise(
        id: String = UUID().uuidString,
        sessionId: String = UUID().uuidString,
        exerciseTemplateId: String = UUID().uuidString,
        exerciseName: String = "Test Exercise",
        prescribedSets: Int = 3,
        prescribedReps: String = "10",
        prescribedLoad: Double? = nil,
        loadUnit: String? = "lbs",
        restPeriodSeconds: Int? = 90,
        notes: String? = nil,
        sequence: Int = 0
    ) -> WorkoutGridExercise {
        return WorkoutGridExercise(
            id: id,
            sessionId: sessionId,
            exerciseTemplateId: exerciseTemplateId,
            exerciseName: exerciseName,
            prescribedSets: prescribedSets,
            prescribedReps: prescribedReps,
            prescribedLoad: prescribedLoad,
            loadUnit: loadUnit,
            restPeriodSeconds: restPeriodSeconds,
            notes: notes,
            sequence: sequence
        )
    }

    /// Helper that mirrors the private validateExercise method from WorkoutGridViewModel
    private func validateExercise(_ exercise: WorkoutGridExercise) throws {
        guard !exercise.exerciseTemplateId.isEmpty else {
            throw WorkoutGridError.noExerciseSelected
        }

        guard exercise.prescribedSets > 0 else {
            throw WorkoutGridError.invalidSets
        }

        guard exercise.prescribedSets <= 20 else {
            throw WorkoutGridError.setsTooHigh
        }

        guard !exercise.prescribedReps.isEmpty else {
            throw WorkoutGridError.invalidReps
        }

        // Validate reps format
        let repsComponents = exercise.prescribedReps.split(separator: "-")
        for component in repsComponents {
            guard Int(component.trimmingCharacters(in: .whitespaces)) != nil else {
                throw WorkoutGridError.invalidRepsFormat
            }
        }

        if let load = exercise.prescribedLoad, load < 0 {
            throw WorkoutGridError.negativeWeight
        }
    }
}

// MARK: - ExerciseTemplateBasic Decoding Tests

@MainActor
final class ExerciseTemplateBasicDecodingTests: XCTestCase {

    func testExerciseTemplateBasic_DecodesComplete() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "name": "Squat",
            "category": "lower",
            "body_region": "legs"
        }
        """

        let data = json.data(using: .utf8)!
        let template = try JSONDecoder().decode(SessionExerciseWithTemplate.ExerciseTemplateBasic.self, from: data)

        XCTAssertEqual(template.id, "00000000-0000-0000-0000-000000000001")
        XCTAssertEqual(template.name, "Squat")
        XCTAssertEqual(template.category, "lower")
        XCTAssertEqual(template.body_region, "legs")
    }

    func testExerciseTemplateBasic_DecodesWithNulls() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "name": "Unknown Exercise",
            "category": null,
            "body_region": null
        }
        """

        let data = json.data(using: .utf8)!
        let template = try JSONDecoder().decode(SessionExerciseWithTemplate.ExerciseTemplateBasic.self, from: data)

        XCTAssertEqual(template.name, "Unknown Exercise")
        XCTAssertNil(template.category)
        XCTAssertNil(template.body_region)
    }
}
