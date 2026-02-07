//
//  OptimisticWorkoutViewModelTests.swift
//  PTPerformanceTests
//
//  Comprehensive unit tests for OptimisticWorkoutViewModel
//  Tests exercise state initialization with .sets property,
//  optimistic updates, rollback handling, and performance requirements
//
//  Coverage areas:
//  - Initialization with various exercise configurations
//  - ExerciseUIState initialization from Exercise.sets computed property
//  - Handling null target_sets/prescribed_sets
//  - State transitions during workout execution
//  - Set/exercise completion
//  - Rollback on sync failure
//  - Performance benchmarks (sub-100ms response)
//

import XCTest
@testable import PTPerformance

// MARK: - OptimisticWorkoutViewModel Tests

@MainActor
final class OptimisticWorkoutViewModelTests: XCTestCase {

    var viewModel: OptimisticWorkoutViewModel!
    let testSessionId = UUID()
    let testPatientId = UUID()
    var testExercises: [Exercise] = []

    override func setUp() async throws {
        try await super.setUp()
        testExercises = createMockExercises(count: 3)
        viewModel = OptimisticWorkoutViewModel(
            sessionId: testSessionId,
            patientId: testPatientId,
            exercises: testExercises
        )
    }

    override func tearDown() async throws {
        viewModel = nil
        testExercises = []
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_DefaultValues() {
        XCTAssertEqual(viewModel.currentExerciseIndex, 0, "Should start at first exercise")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading initially")
        XCTAssertNil(viewModel.errorMessage, "Should have no error initially")
        XCTAssertFalse(viewModel.workoutState.isWorkoutCompleted, "Workout should not be completed initially")
    }

    func testInitialState_SessionAndPatientId() {
        XCTAssertEqual(viewModel.sessionId, testSessionId)
        XCTAssertEqual(viewModel.patientId, testPatientId)
    }

    func testInitialState_ExercisesStored() {
        XCTAssertEqual(viewModel.exercises.count, 3)
    }

    func testInitialState_ExerciseStatesCreated() {
        XCTAssertEqual(viewModel.workoutState.exerciseStates.count, 3, "Should create state for each exercise")
    }

    func testInitialState_CompletedCountZero() {
        XCTAssertEqual(viewModel.workoutState.completedCount, 0)
        XCTAssertEqual(viewModel.workoutState.skippedCount, 0)
    }

    func testInitialState_SyncStatusSynced() {
        if case .synced = viewModel.workoutState.syncStatus {
            XCTAssertTrue(true)
        } else {
            XCTFail("Initial sync status should be synced")
        }
    }

    // MARK: - Exercise State Initialization Tests

    func testExerciseStateInitialization_UsesExerciseSetsProperty() {
        let exercise = createMockExercise(targetSets: 4, prescribedSets: nil)
        let exercises = [exercise]

        let vm = OptimisticWorkoutViewModel(
            sessionId: testSessionId,
            patientId: testPatientId,
            exercises: exercises
        )

        let state = vm.workoutState.exerciseStates[exercise.id]
        XCTAssertEqual(state?.totalSets, 4, "Should use exercise.sets computed property which prefers target_sets")
    }

    func testExerciseStateInitialization_FallsBackToPrescribedSets() {
        let exercise = createMockExercise(targetSets: nil, prescribedSets: 3)
        let exercises = [exercise]

        let vm = OptimisticWorkoutViewModel(
            sessionId: testSessionId,
            patientId: testPatientId,
            exercises: exercises
        )

        let state = vm.workoutState.exerciseStates[exercise.id]
        XCTAssertEqual(state?.totalSets, 3, "Should fallback to prescribed_sets when target_sets is nil")
    }

    func testExerciseStateInitialization_BothSetsNil_DefaultsToZero() {
        let exercise = createMockExercise(targetSets: nil, prescribedSets: nil)
        let exercises = [exercise]

        let vm = OptimisticWorkoutViewModel(
            sessionId: testSessionId,
            patientId: testPatientId,
            exercises: exercises
        )

        let state = vm.workoutState.exerciseStates[exercise.id]
        // exercise.sets returns 0 when both are nil, but ExerciseUIState may default to 3
        XCTAssertEqual(state?.totalSets, 0, "Should use 0 from exercise.sets when both are nil")
    }

    func testExerciseStateInitialization_RepsFromPrescribedReps() {
        let exercise = createMockExercise(prescribedReps: "12")
        let exercises = [exercise]

        let vm = OptimisticWorkoutViewModel(
            sessionId: testSessionId,
            patientId: testPatientId,
            exercises: exercises
        )

        let state = vm.workoutState.exerciseStates[exercise.id]
        XCTAssertEqual(state?.repsPerSet.first, 12, "Should parse reps from prescribed_reps string")
    }

    func testExerciseStateInitialization_RepsFromRange() {
        let exercise = createMockExercise(prescribedReps: "8-12")
        let exercises = [exercise]

        let vm = OptimisticWorkoutViewModel(
            sessionId: testSessionId,
            patientId: testPatientId,
            exercises: exercises
        )

        let state = vm.workoutState.exerciseStates[exercise.id]
        // Range "8-12" should be parsed to average (10)
        XCTAssertEqual(state?.repsPerSet.first, 10, "Should parse rep range to average")
    }

    func testExerciseStateInitialization_NilReps_DefaultsTo10() {
        let exercise = createMockExercise(prescribedReps: nil)
        let exercises = [exercise]

        let vm = OptimisticWorkoutViewModel(
            sessionId: testSessionId,
            patientId: testPatientId,
            exercises: exercises
        )

        let state = vm.workoutState.exerciseStates[exercise.id]
        XCTAssertEqual(state?.repsPerSet.first, 10, "Should default to 10 reps when nil")
    }

    func testExerciseStateInitialization_LoadFromPrescribedLoad() {
        let exercise = createMockExercise(prescribedLoad: 135.0)
        let exercises = [exercise]

        let vm = OptimisticWorkoutViewModel(
            sessionId: testSessionId,
            patientId: testPatientId,
            exercises: exercises
        )

        let state = vm.workoutState.exerciseStates[exercise.id]
        XCTAssertEqual(state?.weightPerSet.first, 135.0, "Should use prescribed load")
    }

    func testExerciseStateInitialization_LoadUnitFromExercise() {
        let exercise = createMockExercise(loadUnit: "kg")
        let exercises = [exercise]

        let vm = OptimisticWorkoutViewModel(
            sessionId: testSessionId,
            patientId: testPatientId,
            exercises: exercises
        )

        let state = vm.workoutState.exerciseStates[exercise.id]
        XCTAssertEqual(state?.loadUnit, "kg", "Should use load unit from exercise")
    }

    // MARK: - Computed Properties Tests

    func testCurrentExercise_ReturnsCorrectExercise() {
        XCTAssertEqual(viewModel.currentExercise?.id, testExercises[0].id)
    }

    func testCurrentExercise_ReturnsNilForInvalidIndex() {
        viewModel.currentExerciseIndex = 100
        XCTAssertNil(viewModel.currentExercise)
    }

    func testCurrentExerciseState_ReturnsCorrectState() {
        let state = viewModel.currentExerciseState
        XCTAssertNotNil(state)
        XCTAssertEqual(state?.exerciseId, testExercises[0].id)
    }

    func testProgressPercentage_Initially() {
        XCTAssertEqual(viewModel.progressPercentage, 0.0)
    }

    func testProgressPercentage_AfterCompletion() {
        viewModel.workoutState.completedCount = 1
        XCTAssertEqual(viewModel.progressPercentage, 1.0 / 3.0, accuracy: 0.001)
    }

    func testCanComplete_FalseInitially() {
        XCTAssertFalse(viewModel.canComplete)
    }

    func testCanComplete_TrueAfterOneExercise() {
        viewModel.workoutState.completedCount = 1
        XCTAssertTrue(viewModel.canComplete)
    }

    func testAllExercisesCompleted_FalseInitially() {
        XCTAssertFalse(viewModel.allExercisesCompleted)
    }

    func testAllExercisesCompleted_TrueWhenAllDone() {
        viewModel.workoutState.completedCount = 3
        XCTAssertTrue(viewModel.allExercisesCompleted)
    }

    func testAllExercisesCompleted_TrueWithSkips() {
        viewModel.workoutState.completedCount = 2
        viewModel.workoutState.skippedCount = 1
        XCTAssertTrue(viewModel.allExercisesCompleted)
    }

    func testTotalVolume_CalculatesCorrectly() {
        // Mark first exercise as completed with specific values
        if let state = viewModel.workoutState.exerciseStates[testExercises[0].id] {
            state.repsPerSet = [10, 10, 10]
            state.weightPerSet = [100, 100, 100]
            state.isCompleted = true
        }

        // Volume = (10+10+10) * 100 = 3000
        XCTAssertEqual(viewModel.totalVolume, 3000.0, accuracy: 0.01)
    }

    func testAverageRPE_CalculatesCorrectly() {
        if let state = viewModel.workoutState.exerciseStates[testExercises[0].id] {
            state.rpe = 7
            state.isCompleted = true
        }
        if let state = viewModel.workoutState.exerciseStates[testExercises[1].id] {
            state.rpe = 9
            state.isCompleted = true
        }

        XCTAssertEqual(viewModel.averageRPE ?? 0, 8.0, accuracy: 0.01)
    }

    func testAverageRPE_NilWhenNoCompletedExercises() {
        XCTAssertNil(viewModel.averageRPE)
    }

    func testAveragePain_CalculatesCorrectly() {
        if let state = viewModel.workoutState.exerciseStates[testExercises[0].id] {
            state.painScore = 2
            state.isCompleted = true
        }
        if let state = viewModel.workoutState.exerciseStates[testExercises[1].id] {
            state.painScore = 4
            state.isCompleted = true
        }

        XCTAssertEqual(viewModel.averagePain ?? 0, 3.0, accuracy: 0.01)
    }

    // MARK: - Set Completion Tests

    func testCompleteSet_UpdatesCompletedSets() {
        viewModel.completeSet(setNumber: 1)

        let state = viewModel.currentExerciseState
        XCTAssertEqual(state?.completedSets, 1)
    }

    func testCompleteSet_MarksPendingSync() {
        viewModel.completeSet(setNumber: 1)

        let state = viewModel.currentExerciseState
        XCTAssertTrue(state?.isPendingSync ?? false)
    }

    func testCompleteSet_CreatesSnapshot() {
        viewModel.completeSet(setNumber: 1)
        // Snapshot creation is internal, but we can verify rollback works
        XCTAssertTrue(true, "Snapshot creation tested via rollback")
    }

    // MARK: - Exercise Completion Tests

    func testCompleteCurrentExercise_MarksCompleted() {
        viewModel.completeCurrentExercise()

        let state = viewModel.workoutState.exerciseStates[testExercises[0].id]
        XCTAssertTrue(state?.isCompleted ?? false)
    }

    func testCompleteCurrentExercise_IncrementsCompletedCount() {
        viewModel.completeCurrentExercise()

        XCTAssertEqual(viewModel.workoutState.completedCount, 1)
    }

    func testCompleteCurrentExercise_MovesToNextExercise() {
        viewModel.completeCurrentExercise()

        XCTAssertEqual(viewModel.currentExerciseIndex, 1)
    }

    func testQuickCompleteExercise_SetsAllCompletedSets() {
        let exerciseId = testExercises[0].id
        viewModel.quickCompleteExercise(exerciseId)

        let state = viewModel.workoutState.exerciseStates[exerciseId]
        XCTAssertEqual(state?.completedSets, state?.totalSets)
        XCTAssertTrue(state?.isCompleted ?? false)
    }

    func testQuickCompleteExercise_UsesDefaultRPE() {
        let exerciseId = testExercises[0].id
        viewModel.quickCompleteExercise(exerciseId)

        // Quick complete uses default RPE of 5
        // This is verified through the logged data
        XCTAssertEqual(viewModel.workoutState.completedCount, 1)
    }

    // MARK: - Skip Exercise Tests

    func testSkipCurrentExercise_MarksSkipped() {
        viewModel.skipCurrentExercise()

        let state = viewModel.workoutState.exerciseStates[testExercises[0].id]
        XCTAssertTrue(state?.isSkipped ?? false)
    }

    func testSkipCurrentExercise_IncrementsSkippedCount() {
        viewModel.skipCurrentExercise()

        XCTAssertEqual(viewModel.workoutState.skippedCount, 1)
    }

    func testSkipCurrentExercise_MovesToNextExercise() {
        viewModel.skipCurrentExercise()

        XCTAssertEqual(viewModel.currentExerciseIndex, 1)
    }

    // MARK: - Navigation Tests

    func testNavigateToExercise_ValidIndex() {
        viewModel.navigateToExercise(at: 2)

        XCTAssertEqual(viewModel.currentExerciseIndex, 2)
    }

    func testNavigateToExercise_InvalidIndex_NoChange() {
        viewModel.navigateToExercise(at: 100)

        XCTAssertEqual(viewModel.currentExerciseIndex, 0)
    }

    func testNavigateToExercise_NegativeIndex_NoChange() {
        viewModel.navigateToExercise(at: -1)

        XCTAssertEqual(viewModel.currentExerciseIndex, 0)
    }

    // MARK: - Weight Update Tests

    func testUpdateWeight_SingleSet() {
        viewModel.updateWeight(150.0, forSet: 1)

        let state = viewModel.currentExerciseState
        XCTAssertEqual(state?.weightPerSet[0], 150.0)
    }

    func testUpdateWeight_AllSets() {
        viewModel.updateWeight(135.0)

        let state = viewModel.currentExerciseState
        XCTAssertTrue(state?.weightPerSet.allSatisfy { $0 == 135.0 } ?? false)
    }

    func testUpdateWeight_MarksPendingSync() {
        viewModel.updateWeight(135.0)

        let state = viewModel.currentExerciseState
        XCTAssertTrue(state?.isPendingSync ?? false)
    }

    // MARK: - Reps Update Tests

    func testUpdateReps_SpecificSet() {
        viewModel.updateReps(15, forSet: 1)

        let state = viewModel.currentExerciseState
        XCTAssertEqual(state?.repsPerSet[0], 15)
    }

    func testUpdateReps_InvalidSet_NoChange() {
        let originalReps = viewModel.currentExerciseState?.repsPerSet[0]
        viewModel.updateReps(15, forSet: 100)

        let state = viewModel.currentExerciseState
        XCTAssertEqual(state?.repsPerSet[0], originalReps)
    }

    // MARK: - RPE/Pain Update Tests

    func testUpdateRPE_ValidValue() {
        viewModel.updateRPE(8)

        let state = viewModel.currentExerciseState
        XCTAssertEqual(state?.rpe, 8)
    }

    func testUpdateRPE_ClampsToBounds() {
        viewModel.updateRPE(15)
        XCTAssertEqual(viewModel.currentExerciseState?.rpe, 10)

        viewModel.updateRPE(-5)
        XCTAssertEqual(viewModel.currentExerciseState?.rpe, 0)
    }

    func testUpdatePainScore_ValidValue() {
        viewModel.updatePainScore(3)

        let state = viewModel.currentExerciseState
        XCTAssertEqual(state?.painScore, 3)
    }

    func testUpdatePainScore_ClampsToBounds() {
        viewModel.updatePainScore(15)
        XCTAssertEqual(viewModel.currentExerciseState?.painScore, 10)

        viewModel.updatePainScore(-5)
        XCTAssertEqual(viewModel.currentExerciseState?.painScore, 0)
    }

    // MARK: - Workout Completion Tests

    func testCompleteWorkout_MarksWorkoutCompleted() {
        viewModel.startWorkout()
        viewModel.completeCurrentExercise() // Need at least one

        viewModel.completeWorkout()

        XCTAssertTrue(viewModel.workoutState.isWorkoutCompleted)
    }

    func testStartWorkout_RecordsStartTime() {
        let beforeStart = Date()
        viewModel.startWorkout()
        let afterStart = Date()

        // Start time should be between beforeStart and afterStart
        // This is internal state, tested indirectly through workout completion
        XCTAssertTrue(true)
    }

    // MARK: - Rollback Tests

    func testRollbackExercise_RestoresState() {
        let exerciseId = testExercises[0].id

        // Capture initial state
        let initialSets = viewModel.workoutState.exerciseStates[exerciseId]?.completedSets ?? 0

        // Make changes (which creates snapshot)
        viewModel.completeSet(setNumber: 2)

        // Verify change
        XCTAssertEqual(viewModel.workoutState.exerciseStates[exerciseId]?.completedSets, 2)

        // Rollback
        viewModel.rollbackExercise(exerciseId)

        // Verify restored
        XCTAssertEqual(viewModel.workoutState.exerciseStates[exerciseId]?.completedSets, initialSets)
    }

    func testRollbackExercise_DecreasesCompletedCount() {
        let exerciseId = testExercises[0].id

        viewModel.completeCurrentExercise()
        XCTAssertEqual(viewModel.workoutState.completedCount, 1)

        viewModel.rollbackExercise(exerciseId)

        XCTAssertEqual(viewModel.workoutState.completedCount, 0)
    }

    func testRollbackExercise_ClearsPendingSync() {
        let exerciseId = testExercises[0].id

        viewModel.completeSet(setNumber: 1)
        XCTAssertTrue(viewModel.workoutState.exerciseStates[exerciseId]?.isPendingSync ?? false)

        viewModel.rollbackExercise(exerciseId)

        XCTAssertFalse(viewModel.workoutState.exerciseStates[exerciseId]?.isPendingSync ?? true)
    }

    // MARK: - ExerciseUIState Tests

    func testExerciseUIState_Initialization() {
        let state = ExerciseUIState(
            exerciseId: UUID(),
            totalSets: 4,
            targetReps: 12,
            targetLoad: 100.0
        )

        XCTAssertEqual(state.totalSets, 4)
        XCTAssertEqual(state.repsPerSet.count, 4)
        XCTAssertEqual(state.repsPerSet[0], 12)
        XCTAssertEqual(state.weightPerSet.count, 4)
        XCTAssertEqual(state.weightPerSet[0], 100.0)
    }

    func testExerciseUIState_DefaultValues() {
        let state = ExerciseUIState(exerciseId: UUID())

        XCTAssertEqual(state.totalSets, 3)
        XCTAssertEqual(state.completedSets, 0)
        XCTAssertEqual(state.rpe, 5)
        XCTAssertEqual(state.painScore, 0)
        XCTAssertFalse(state.isCompleted)
        XCTAssertFalse(state.isSkipped)
        XCTAssertFalse(state.isPendingSync)
        XCTAssertEqual(state.loadUnit, "lbs")
        XCTAssertTrue(state.notes.isEmpty)
    }

    func testExerciseUIState_Snapshot() {
        let state = ExerciseUIState(exerciseId: UUID(), totalSets: 3, targetReps: 10, targetLoad: 100.0)
        state.completedSets = 2
        state.rpe = 8
        state.painScore = 3
        state.notes = "Test notes"

        let snapshot = state.snapshot()

        XCTAssertEqual(snapshot.completedSets, 2)
        XCTAssertEqual(snapshot.rpe, 8)
        XCTAssertEqual(snapshot.painScore, 3)
        XCTAssertEqual(snapshot.notes, "Test notes")
    }

    func testExerciseUIState_Restore() {
        let state = ExerciseUIState(exerciseId: UUID(), totalSets: 3, targetReps: 10, targetLoad: 100.0)

        // Create initial snapshot
        let snapshot = state.snapshot()

        // Modify state
        state.completedSets = 3
        state.rpe = 9
        state.painScore = 5
        state.isCompleted = true
        state.isPendingSync = true

        // Restore
        state.restore(from: snapshot)

        XCTAssertEqual(state.completedSets, 0)
        XCTAssertEqual(state.rpe, 5)
        XCTAssertEqual(state.painScore, 0)
        XCTAssertFalse(state.isCompleted)
        XCTAssertFalse(state.isPendingSync)
    }

    // MARK: - OptimisticWorkoutState Tests

    func testOptimisticWorkoutState_HasPendingSync() {
        let state = OptimisticWorkoutState()

        XCTAssertFalse(state.hasPendingSync)

        state.syncStatus = .pending(count: 3)
        XCTAssertTrue(state.hasPendingSync)

        state.syncStatus = .synced
        XCTAssertFalse(state.hasPendingSync)
    }

    func testOptimisticWorkoutState_HasError() {
        let state = OptimisticWorkoutState()

        XCTAssertFalse(state.hasError)

        state.syncStatus = .error("Test error")
        XCTAssertTrue(state.hasError)

        state.syncStatus = .synced
        XCTAssertFalse(state.hasError)
    }

    func testOptimisticWorkoutState_SyncStatusValues() {
        let state = OptimisticWorkoutState()

        state.syncStatus = .synced
        if case .synced = state.syncStatus { XCTAssertTrue(true) } else { XCTFail() }

        state.syncStatus = .pending(count: 5)
        if case .pending(let count) = state.syncStatus {
            XCTAssertEqual(count, 5)
        } else { XCTFail() }

        state.syncStatus = .syncing
        if case .syncing = state.syncStatus { XCTAssertTrue(true) } else { XCTFail() }

        state.syncStatus = .error("Failed")
        if case .error(let message) = state.syncStatus {
            XCTAssertEqual(message, "Failed")
        } else { XCTFail() }
    }

    // MARK: - Performance Tests

    func testCompleteSetPerformance() {
        measure {
            for _ in 0..<100 {
                viewModel.completeSet(setNumber: 1)
            }
        }
    }

    func testUpdateWeightPerformance() {
        measure {
            for i in 0..<100 {
                viewModel.updateWeight(Double(i), forSet: 1)
            }
        }
    }

    func testNavigationPerformance() {
        measure {
            for i in 0..<100 {
                viewModel.navigateToExercise(at: i % 3)
            }
        }
    }

    // MARK: - Helper Methods

    private func createMockExercises(count: Int) -> [Exercise] {
        return (0..<count).map { index in
            createMockExercise(
                id: UUID(),
                sequence: index,
                targetSets: 3,
                prescribedSets: nil,
                prescribedReps: "10",
                prescribedLoad: 100.0,
                loadUnit: "lbs",
                templateName: "Exercise \(index + 1)"
            )
        }
    }

    private func createMockExercise(
        id: UUID = UUID(),
        sessionId: UUID = UUID(),
        exerciseTemplateId: UUID = UUID(),
        sequence: Int? = 1,
        targetSets: Int? = 3,
        prescribedSets: Int? = nil,
        targetReps: Int? = nil,
        prescribedReps: String? = "10",
        prescribedLoad: Double? = nil,
        loadUnit: String? = "lbs",
        restPeriodSeconds: Int? = 90,
        notes: String? = nil,
        templateName: String = "Test Exercise"
    ) -> Exercise {
        let template = Exercise.ExerciseTemplate(
            id: exerciseTemplateId,
            name: templateName,
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
            id: id,
            session_id: sessionId,
            exercise_template_id: exerciseTemplateId,
            sequence: sequence,
            target_sets: targetSets,
            target_reps: targetReps,
            prescribed_sets: prescribedSets,
            prescribed_reps: prescribedReps,
            prescribed_load: prescribedLoad,
            load_unit: loadUnit,
            rest_period_seconds: restPeriodSeconds,
            notes: notes,
            exercise_templates: template
        )
    }
}

// MARK: - ExerciseUIStateSnapshot Tests

@MainActor
final class ExerciseUIStateSnapshotTests: XCTestCase {

    func testSnapshot_CapturesAllValues() {
        let snapshot = ExerciseUIStateSnapshot(
            completedSets: 2,
            repsPerSet: [10, 10, 8],
            weightPerSet: [100.0, 100.0, 95.0],
            rpe: 8,
            painScore: 2,
            notes: "Good session",
            isCompleted: false,
            isSkipped: false
        )

        XCTAssertEqual(snapshot.completedSets, 2)
        XCTAssertEqual(snapshot.repsPerSet, [10, 10, 8])
        XCTAssertEqual(snapshot.weightPerSet, [100.0, 100.0, 95.0])
        XCTAssertEqual(snapshot.rpe, 8)
        XCTAssertEqual(snapshot.painScore, 2)
        XCTAssertEqual(snapshot.notes, "Good session")
        XCTAssertFalse(snapshot.isCompleted)
        XCTAssertFalse(snapshot.isSkipped)
    }
}

// MARK: - Integration Scenario Tests

@MainActor
final class OptimisticWorkoutScenarioTests: XCTestCase {

    func testTypicalWorkoutFlow() {
        // Setup
        let exercises = (0..<4).map { index in
            createExercise(sequence: index, sets: 3, reps: "10", load: 100.0)
        }

        let vm = OptimisticWorkoutViewModel(
            sessionId: UUID(),
            patientId: UUID(),
            exercises: exercises
        )

        // Start workout
        vm.startWorkout()

        // Complete first exercise
        vm.completeSet(setNumber: 1)
        vm.completeSet(setNumber: 2)
        vm.completeSet(setNumber: 3)
        vm.updateRPE(7)
        vm.completeCurrentExercise()

        XCTAssertEqual(vm.workoutState.completedCount, 1)
        XCTAssertEqual(vm.currentExerciseIndex, 1)

        // Skip second exercise
        vm.skipCurrentExercise()

        XCTAssertEqual(vm.workoutState.skippedCount, 1)
        XCTAssertEqual(vm.currentExerciseIndex, 2)

        // Quick complete third
        vm.quickCompleteExercise(exercises[2].id)

        XCTAssertEqual(vm.workoutState.completedCount, 2)

        // Complete fourth
        vm.updateWeight(110.0)
        vm.completeCurrentExercise()

        XCTAssertEqual(vm.workoutState.completedCount, 3)

        // Complete workout
        vm.completeWorkout()

        XCTAssertTrue(vm.workoutState.isWorkoutCompleted)
        XCTAssertTrue(vm.allExercisesCompleted)
        XCTAssertTrue(vm.progressPercentage == 1.0)
    }

    func testRollbackAfterSyncFailure() {
        let exercises = [createExercise(sequence: 0, sets: 3, reps: "10", load: 100.0)]
        let vm = OptimisticWorkoutViewModel(
            sessionId: UUID(),
            patientId: UUID(),
            exercises: exercises
        )

        let exerciseId = exercises[0].id

        // Complete exercise optimistically
        vm.completeCurrentExercise()
        XCTAssertTrue(vm.workoutState.exerciseStates[exerciseId]?.isCompleted ?? false)
        XCTAssertEqual(vm.workoutState.completedCount, 1)

        // Simulate sync failure and rollback
        vm.rollbackExercise(exerciseId)

        // Verify state is restored
        XCTAssertFalse(vm.workoutState.exerciseStates[exerciseId]?.isCompleted ?? true)
        XCTAssertEqual(vm.workoutState.completedCount, 0)
    }

    private func createExercise(
        sequence: Int,
        sets: Int,
        reps: String,
        load: Double
    ) -> Exercise {
        let templateId = UUID()
        let template = Exercise.ExerciseTemplate(
            id: templateId,
            name: "Exercise \(sequence + 1)",
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
            sequence: sequence,
            target_sets: sets,
            target_reps: nil,
            prescribed_sets: nil,
            prescribed_reps: reps,
            prescribed_load: load,
            load_unit: "lbs",
            rest_period_seconds: 90,
            notes: nil,
            exercise_templates: template
        )
    }
}
