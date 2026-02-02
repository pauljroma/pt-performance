//
//  ManualWorkoutExecutionViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for ManualWorkoutExecutionViewModel
//  Tests set logging, exercise navigation, fatigue adjustment, and rest timer logic
//

import XCTest
@testable import PTPerformance

// MARK: - Mock Services

/// Mock ManualWorkoutService for testing
class MockManualWorkoutService: ManualWorkoutService {

    var shouldFailLogManual = false
    var shouldFailLogPrescribed = false
    var shouldFailCompleteWorkout = false
    var shouldFailLoadExercises = false

    var lastLoggedManualData: (
        exerciseId: UUID,
        patientId: UUID,
        sets: Int,
        reps: [Int],
        load: Double?,
        unit: String,
        rpe: Int,
        pain: Int,
        notes: String?
    )?

    var lastLoggedPrescribedData: (
        sessionExerciseId: UUID,
        patientId: UUID,
        sets: Int,
        reps: [Int],
        load: Double?,
        unit: String,
        rpe: Int,
        pain: Int,
        notes: String?
    )?

    var completedSessionId: UUID?
    var mockExercises: [ManualSessionExercise] = []

    override func fetchSessionExercises(sessionId: UUID) async throws -> [ManualSessionExercise] {
        if shouldFailLoadExercises {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock load exercises error"])
        }
        return mockExercises
    }

    override func logManualExercise(
        manualSessionExerciseId: UUID,
        patientId: UUID,
        actualSets: Int,
        actualReps: [Int],
        actualLoad: Double?,
        loadUnit: String,
        rpe: Int,
        painScore: Int,
        notes: String?
    ) async throws {
        if shouldFailLogManual {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock log exercise error"])
        }
        lastLoggedManualData = (manualSessionExerciseId, patientId, actualSets, actualReps, actualLoad, loadUnit, rpe, painScore, notes)
    }

    override func logPrescribedExercise(
        sessionExerciseId: UUID,
        patientId: UUID,
        actualSets: Int,
        actualReps: [Int],
        actualLoad: Double?,
        loadUnit: String,
        rpe: Int,
        painScore: Int,
        notes: String?
    ) async throws {
        if shouldFailLogPrescribed {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock log prescribed error"])
        }
        lastLoggedPrescribedData = (sessionExerciseId, patientId, actualSets, actualReps, actualLoad, loadUnit, rpe, painScore, notes)
    }

    override func completeWorkout(
        _ sessionId: UUID,
        totalVolume: Double,
        avgRpe: Double?,
        avgPain: Double?,
        durationMinutes: Int
    ) async throws -> ManualSession {
        if shouldFailCompleteWorkout {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock complete workout error"])
        }
        completedSessionId = sessionId
        return createMockSession(id: sessionId)
    }

    private func createMockSession(id: UUID) -> ManualSession {
        return ManualSession(
            id: id,
            patientId: UUID(),
            name: "Test Workout",
            notes: nil,
            sourceTemplateId: nil,
            sourceTemplateType: nil,
            startedAt: Date(),
            completedAt: Date(),
            completed: true,
            totalVolume: 1000.0,
            avgRpe: 7.0,
            avgPain: 2.0,
            durationMinutes: 45,
            createdAt: Date(),
            exercises: []
        )
    }
}

// MARK: - Tests

@MainActor
final class ManualWorkoutExecutionViewModelTests: XCTestCase {

    var viewModel: ManualWorkoutExecutionViewModel!
    var mockService: MockManualWorkoutService!
    let testPatientId = UUID()
    var testSession: ManualSession!
    var testExercises: [ManualSessionExercise]!

    override func setUp() async throws {
        try await super.setUp()
        mockService = MockManualWorkoutService()

        testSession = createMockSession()
        testExercises = createMockExercises(count: 3)

        viewModel = ManualWorkoutExecutionViewModel(
            session: testSession,
            exercises: testExercises,
            patientId: testPatientId,
            service: mockService
        )
    }

    override func tearDown() async throws {
        viewModel?.stopTimer()
        viewModel = nil
        mockService = nil
        testSession = nil
        testExercises = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_DefaultValues() {
        XCTAssertEqual(viewModel.currentExerciseIndex, 0, "Should start at first exercise")
        XCTAssertEqual(viewModel.elapsedTime, 0, "Elapsed time should be 0")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false")
        XCTAssertNil(viewModel.errorMessage, "errorMessage should be nil")
        XCTAssertFalse(viewModel.showError, "showError should be false")
        XCTAssertFalse(viewModel.showCompletionConfirmation, "showCompletionConfirmation should be false")
        XCTAssertFalse(viewModel.isWorkoutCompleted, "isWorkoutCompleted should be false")
        XCTAssertTrue(viewModel.isTimerVisible, "isTimerVisible should be true")
    }

    func testInitialState_InputFieldsFromFirstExercise() {
        let firstExercise = testExercises[0]
        let expectedSets = firstExercise.targetSets ?? 3
        let expectedReps = Int(firstExercise.targetReps ?? "10") ?? 10

        XCTAssertEqual(viewModel.actualSets, expectedSets, "actualSets should match first exercise")
        XCTAssertEqual(viewModel.repsPerSet.count, expectedSets, "repsPerSet should have correct count")
        XCTAssertEqual(viewModel.repsPerSet[0], expectedReps, "reps should match target reps")
        XCTAssertEqual(viewModel.loadUnit, firstExercise.loadUnit ?? "lbs", "loadUnit should match")
        XCTAssertEqual(viewModel.rpe, 5.0, "rpe should default to 5.0")
        XCTAssertEqual(viewModel.painScore, 0.0, "painScore should default to 0.0")
        XCTAssertEqual(viewModel.notes, "", "notes should be empty")
    }

    func testInitialState_TrackingSets() {
        XCTAssertTrue(viewModel.completedExerciseIds.isEmpty, "completedExerciseIds should be empty")
        XCTAssertTrue(viewModel.skippedExerciseIds.isEmpty, "skippedExerciseIds should be empty")
    }

    func testInitialState_ExercisesSorted() {
        // Exercises should be sorted by sequence
        for i in 0..<(viewModel.exercises.count - 1) {
            XCTAssertLessThanOrEqual(
                viewModel.exercises[i].sequence,
                viewModel.exercises[i + 1].sequence,
                "Exercises should be sorted by sequence"
            )
        }
    }

    // MARK: - Computed Properties Tests

    func testWorkoutName() {
        XCTAssertEqual(viewModel.workoutName, testSession.name ?? "Workout")
    }

    func testTotalExercises() {
        XCTAssertEqual(viewModel.totalExercises, testExercises.count)
    }

    func testCompletedCount_Initially() {
        XCTAssertEqual(viewModel.completedCount, 0, "completedCount should be 0 initially")
    }

    func testProgressText_Initially() {
        XCTAssertEqual(viewModel.progressText, "0 / \(testExercises.count)")
    }

    func testProgressPercentage_Initially() {
        XCTAssertEqual(viewModel.progressPercentage, 0.0)
    }

    func testProgressPercentage_AfterCompletion() {
        viewModel.completedExerciseIds.insert(testExercises[0].id)
        let expected = 1.0 / Double(testExercises.count)
        XCTAssertEqual(viewModel.progressPercentage, expected, accuracy: 0.001)
    }

    func testElapsedTimeDisplay_Initially() {
        XCTAssertEqual(viewModel.elapsedTimeDisplay, "00:00")
    }

    func testElapsedTimeDisplay_WithTime() {
        viewModel.elapsedTime = 65 // 1 minute 5 seconds
        XCTAssertEqual(viewModel.elapsedTimeDisplay, "01:05")
    }

    func testElapsedTimeDisplay_LongerTime() {
        viewModel.elapsedTime = 3665 // 61 minutes 5 seconds
        XCTAssertEqual(viewModel.elapsedTimeDisplay, "61:05")
    }

    func testCurrentExercise() {
        XCTAssertEqual(viewModel.currentExercise?.id, testExercises[0].id)
    }

    func testCurrentExercise_WhenIndexOutOfBounds() {
        viewModel.currentExerciseIndex = 100
        XCTAssertNil(viewModel.currentExercise)
    }

    func testCanCompleteWorkout_WhenNoExercisesDone() {
        // Can complete with at least 1 completed OR when all done
        // With 0 completed, should be false (since completedCount == 0)
        XCTAssertFalse(viewModel.canCompleteWorkout)
    }

    func testCanCompleteWorkout_AfterOneExercise() {
        viewModel.completedExerciseIds.insert(testExercises[0].id)
        XCTAssertTrue(viewModel.canCompleteWorkout)
    }

    func testAllExercisesCompleted_WhenNotAllDone() {
        viewModel.completedExerciseIds.insert(testExercises[0].id)
        XCTAssertFalse(viewModel.allExercisesCompleted)
    }

    func testAllExercisesCompleted_WhenAllDone() {
        for exercise in testExercises {
            viewModel.completedExerciseIds.insert(exercise.id)
        }
        XCTAssertTrue(viewModel.allExercisesCompleted)
    }

    // MARK: - ActualLoad Computed Property Tests

    func testActualLoad_WhenWeightPerSetEmpty() {
        viewModel.weightPerSet = []
        XCTAssertNil(viewModel.actualLoad, "Should return nil when no weights")
    }

    func testActualLoad_WhenAllZeroWeights() {
        viewModel.weightPerSet = [0, 0, 0]
        XCTAssertNil(viewModel.actualLoad, "Should return nil when all weights are zero")
    }

    func testActualLoad_Calculated() {
        viewModel.weightPerSet = [100, 100, 100]
        XCTAssertEqual(viewModel.actualLoad, 100.0, "Should calculate average weight")
    }

    func testActualLoad_MixedWeights() {
        viewModel.weightPerSet = [100, 90, 80]
        XCTAssertEqual(viewModel.actualLoad, 90.0, accuracy: 0.001, "Should average non-zero weights")
    }

    func testActualLoad_IgnoresZeros() {
        viewModel.weightPerSet = [100, 0, 80]
        XCTAssertEqual(viewModel.actualLoad, 90.0, accuracy: 0.001, "Should ignore zero weights in average")
    }

    // MARK: - Timer Tests

    func testStartTimer() async {
        viewModel.startTimer()

        // Wait a bit for timer to tick
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

        XCTAssertGreaterThan(viewModel.elapsedTime, 0, "Elapsed time should increase after starting timer")

        viewModel.stopTimer()
    }

    func testStopTimer() async {
        viewModel.startTimer()
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        viewModel.stopTimer()

        let timeAtStop = viewModel.elapsedTime
        try? await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertEqual(viewModel.elapsedTime, timeAtStop, "Elapsed time should not change after stopping timer")
    }

    // MARK: - Exercise Navigation Tests

    func testSelectExercise() {
        let secondExercise = testExercises[1]

        viewModel.selectExercise(secondExercise)

        XCTAssertEqual(viewModel.currentExerciseIndex, 1, "Should navigate to second exercise")
        XCTAssertEqual(viewModel.actualSets, secondExercise.targetSets ?? 3)
    }

    func testMoveToNextExercise_WhenNotAllCompleted() {
        viewModel.completedExerciseIds.insert(testExercises[0].id)

        viewModel.moveToNextExercise()

        XCTAssertEqual(viewModel.currentExerciseIndex, 1, "Should move to next incomplete exercise")
    }

    func testMoveToNextExercise_SkipsCompleted() {
        viewModel.completedExerciseIds.insert(testExercises[0].id)
        viewModel.completedExerciseIds.insert(testExercises[1].id)

        viewModel.moveToNextExercise()

        XCTAssertEqual(viewModel.currentExerciseIndex, 2, "Should skip to first incomplete exercise")
    }

    func testMoveToNextExercise_SkipsSkipped() {
        viewModel.skippedExerciseIds.insert(testExercises[0].id)

        viewModel.moveToNextExercise()

        XCTAssertEqual(viewModel.currentExerciseIndex, 1, "Should skip skipped exercises")
    }

    func testMoveToNextExercise_WhenAllCompleted_ShowsConfirmation() {
        for exercise in testExercises {
            viewModel.completedExerciseIds.insert(exercise.id)
        }

        viewModel.moveToNextExercise()

        XCTAssertTrue(viewModel.showCompletionConfirmation, "Should show completion confirmation when all done")
    }

    // MARK: - Setup Input Fields Tests

    func testSetupInputFields_SetsCorrectValues() {
        let exercise = ManualSessionExercise(
            id: UUID(),
            manualSessionId: testSession.id,
            exerciseTemplateId: nil,
            exerciseName: "Test Exercise",
            blockName: "Main",
            sequence: 0,
            targetSets: 5,
            targetReps: "12",
            targetLoad: 150.0,
            loadUnit: "kg",
            restPeriodSeconds: 120,
            notes: nil,
            createdAt: Date()
        )

        viewModel.setupInputFields(for: exercise)

        XCTAssertEqual(viewModel.actualSets, 5)
        XCTAssertEqual(viewModel.repsPerSet.count, 5)
        XCTAssertEqual(viewModel.repsPerSet[0], 12)
        XCTAssertEqual(viewModel.weightPerSet[0], 150.0)
        XCTAssertEqual(viewModel.loadUnit, "kg")
        XCTAssertEqual(viewModel.rpe, 5.0, "RPE should reset to 5.0")
        XCTAssertEqual(viewModel.painScore, 0.0, "Pain should reset to 0.0")
        XCTAssertEqual(viewModel.notes, "", "Notes should be cleared")
    }

    func testSetupInputFields_WithNilTargets() {
        let exercise = ManualSessionExercise(
            id: UUID(),
            manualSessionId: testSession.id,
            exerciseTemplateId: nil,
            exerciseName: "Test Exercise",
            blockName: nil,
            sequence: 0,
            targetSets: nil,
            targetReps: nil,
            targetLoad: nil,
            loadUnit: nil,
            restPeriodSeconds: nil,
            notes: nil,
            createdAt: Date()
        )

        viewModel.setupInputFields(for: exercise)

        XCTAssertEqual(viewModel.actualSets, 3, "Should default to 3 sets")
        XCTAssertEqual(viewModel.repsPerSet[0], 10, "Should default to 10 reps")
        XCTAssertEqual(viewModel.loadUnit, "lbs", "Should default to lbs")
    }

    // MARK: - Fatigue Adjustment Tests

    func testApplyFatigueAdjustment_ReducesWeight() {
        let exercise = ManualSessionExercise(
            id: UUID(),
            manualSessionId: testSession.id,
            exerciseTemplateId: nil,
            exerciseName: "Test Exercise",
            blockName: "Main",
            sequence: 0,
            targetSets: 3,
            targetReps: "10",
            targetLoad: 100.0,
            loadUnit: "lbs",
            restPeriodSeconds: 90,
            notes: nil,
            createdAt: Date()
        )
        viewModel.exercises = [exercise]
        viewModel.currentExerciseIndex = 0

        let adjustment = FatigueAdjustment(
            loadReductionPct: 0.3,
            volumeReductionPct: 0.25,
            reason: "High fatigue",
            fatigueBand: .high,
            isDeloadWeek: false
        )

        viewModel.applyFatigueAdjustment(adjustment)

        // 100 * (1 - 0.3) = 70, rounded to nearest 5 = 70
        XCTAssertEqual(viewModel.weightPerSet[0], 70.0, "Weight should be reduced by 30%")
    }

    func testApplyFatigueAdjustment_RoundsToNearest5() {
        let exercise = ManualSessionExercise(
            id: UUID(),
            manualSessionId: testSession.id,
            exerciseTemplateId: nil,
            exerciseName: "Test Exercise",
            blockName: "Main",
            sequence: 0,
            targetSets: 3,
            targetReps: "10",
            targetLoad: 97.0, // Odd number
            loadUnit: "lbs",
            restPeriodSeconds: 90,
            notes: nil,
            createdAt: Date()
        )
        viewModel.exercises = [exercise]
        viewModel.currentExerciseIndex = 0

        let adjustment = FatigueAdjustment(
            loadReductionPct: 0.1,
            volumeReductionPct: 0.1,
            reason: "Moderate fatigue",
            fatigueBand: .moderate,
            isDeloadWeek: false
        )

        viewModel.applyFatigueAdjustment(adjustment)

        // 97 * 0.9 = 87.3, rounded to nearest 5 = 85
        XCTAssertEqual(viewModel.weightPerSet[0], 85.0, "Weight should be rounded to nearest 5")
    }

    func testApplyFatigueAdjustment_NilClearsAdjustment() {
        viewModel.fatigueAdjustment = FatigueAdjustment(
            loadReductionPct: 0.3,
            volumeReductionPct: 0.25,
            reason: "Test",
            fatigueBand: .high,
            isDeloadWeek: false
        )

        viewModel.applyFatigueAdjustment(nil)

        XCTAssertNil(viewModel.fatigueAdjustment, "Adjustment should be cleared")
    }

    func testFatigueAdjustment_IsActive() {
        let activeAdjustment = FatigueAdjustment(
            loadReductionPct: 0.3,
            volumeReductionPct: 0.0,
            reason: "Test",
            fatigueBand: .high,
            isDeloadWeek: false
        )
        XCTAssertTrue(activeAdjustment.isActive)

        let noAdjustment = FatigueAdjustment(
            loadReductionPct: 0.0,
            volumeReductionPct: 0.0,
            reason: "Test",
            fatigueBand: .low,
            isDeloadWeek: false
        )
        XCTAssertFalse(noAdjustment.isActive)
    }

    func testFatigueAdjustment_ReductionPercents() {
        let adjustment = FatigueAdjustment(
            loadReductionPct: 0.30,
            volumeReductionPct: 0.25,
            reason: "Test",
            fatigueBand: .high,
            isDeloadWeek: false
        )

        XCTAssertEqual(adjustment.loadReductionPercent, 30)
        XCTAssertEqual(adjustment.volumeReductionPercent, 25)
    }

    // MARK: - Update Sets Count Tests

    func testUpdateSetsCount_Increase() {
        viewModel.actualSets = 3
        viewModel.repsPerSet = [10, 10, 10]
        viewModel.weightPerSet = [100, 100, 100]

        viewModel.updateSetsCount(5)

        XCTAssertEqual(viewModel.actualSets, 5)
        XCTAssertEqual(viewModel.repsPerSet.count, 5)
        XCTAssertEqual(viewModel.weightPerSet.count, 5)
        XCTAssertEqual(viewModel.repsPerSet[3], 10, "New sets should have last set's reps")
        XCTAssertEqual(viewModel.repsPerSet[4], 10)
        XCTAssertEqual(viewModel.weightPerSet[3], 100, "New sets should have last set's weight")
    }

    func testUpdateSetsCount_Decrease() {
        viewModel.actualSets = 5
        viewModel.repsPerSet = [10, 10, 10, 10, 10]
        viewModel.weightPerSet = [100, 100, 100, 100, 100]

        viewModel.updateSetsCount(3)

        XCTAssertEqual(viewModel.actualSets, 3)
        XCTAssertEqual(viewModel.repsPerSet.count, 3)
        XCTAssertEqual(viewModel.weightPerSet.count, 3)
    }

    // MARK: - Exercise Completion Tests

    func testCompleteCurrentExercise_Success() async {
        viewModel.actualSets = 3
        viewModel.repsPerSet = [10, 10, 10]
        viewModel.weightPerSet = [100, 100, 100]
        viewModel.rpe = 7.0
        viewModel.painScore = 2.0
        viewModel.notes = "Good set"

        await viewModel.completeCurrentExercise()

        XCTAssertTrue(viewModel.completedExerciseIds.contains(testExercises[0].id))
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)

        // Verify logged data
        XCTAssertNotNil(mockService.lastLoggedManualData)
        XCTAssertEqual(mockService.lastLoggedManualData?.sets, 3)
        XCTAssertEqual(mockService.lastLoggedManualData?.reps, [10, 10, 10])
        XCTAssertEqual(mockService.lastLoggedManualData?.rpe, 7)
        XCTAssertEqual(mockService.lastLoggedManualData?.pain, 2)
        XCTAssertEqual(mockService.lastLoggedManualData?.notes, "Good set")
    }

    func testCompleteCurrentExercise_Failure() async {
        mockService.shouldFailLogManual = true

        await viewModel.completeCurrentExercise()

        XCTAssertFalse(viewModel.completedExerciseIds.contains(testExercises[0].id))
        XCTAssertTrue(viewModel.showError)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testCompleteCurrentExercise_MovesToNext() async {
        await viewModel.completeCurrentExercise()

        XCTAssertEqual(viewModel.currentExerciseIndex, 1, "Should move to next exercise")
    }

    // MARK: - Skip Exercise Tests

    func testSkipCurrentExercise() {
        viewModel.skipCurrentExercise()

        XCTAssertTrue(viewModel.skippedExerciseIds.contains(testExercises[0].id))
        XCTAssertEqual(viewModel.currentExerciseIndex, 1, "Should move to next exercise")
    }

    func testSkipExercise_SpecificExercise() {
        viewModel.skipExercise(testExercises[1])

        XCTAssertTrue(viewModel.skippedExerciseIds.contains(testExercises[1].id))
    }

    func testSkipExercise_CurrentExercise_MoveToNext() {
        viewModel.skipExercise(testExercises[0])

        XCTAssertEqual(viewModel.currentExerciseIndex, 1, "Should move to next when skipping current")
    }

    func testSkipExercise_NotCurrent_DoesNotMove() {
        viewModel.skipExercise(testExercises[2])

        XCTAssertEqual(viewModel.currentExerciseIndex, 0, "Should not move when skipping non-current")
    }

    // MARK: - Quick Complete Tests

    func testQuickCompleteExercise_Success() async {
        let exercise = testExercises[1]

        await viewModel.quickCompleteExercise(exercise)

        XCTAssertTrue(viewModel.completedExerciseIds.contains(exercise.id))
        XCTAssertFalse(viewModel.isLoading)

        // Verify logged with prescribed values
        XCTAssertNotNil(mockService.lastLoggedManualData)
        XCTAssertEqual(mockService.lastLoggedManualData?.sets, exercise.targetSets ?? 3)
        XCTAssertEqual(mockService.lastLoggedManualData?.rpe, 5, "Quick complete uses default RPE of 5")
        XCTAssertEqual(mockService.lastLoggedManualData?.pain, 0, "Quick complete uses default pain of 0")
    }

    func testQuickCompleteExercise_Failure() async {
        mockService.shouldFailLogManual = true

        await viewModel.quickCompleteExercise(testExercises[0])

        XCTAssertFalse(viewModel.completedExerciseIds.contains(testExercises[0].id))
        XCTAssertTrue(viewModel.showError)
    }

    func testQuickComplete_CurrentExercise_MovesToNext() async {
        await viewModel.quickCompleteExercise(testExercises[0])

        XCTAssertEqual(viewModel.currentExerciseIndex, 1)
    }

    func testQuickComplete_NotCurrentExercise_DoesNotMove() async {
        await viewModel.quickCompleteExercise(testExercises[2])

        XCTAssertEqual(viewModel.currentExerciseIndex, 0, "Should not move when quick completing non-current")
    }

    func testQuickComplete_AllDone_ShowsConfirmation() async {
        for exercise in testExercises.dropLast() {
            await viewModel.quickCompleteExercise(exercise)
        }

        await viewModel.quickCompleteExercise(testExercises.last!)

        XCTAssertTrue(viewModel.showCompletionConfirmation)
    }

    // MARK: - Complete Workout Tests

    func testCompleteWorkout_Success() async {
        // Complete some exercises first
        viewModel.completedExerciseIds.insert(testExercises[0].id)
        viewModel.completedExerciseIds.insert(testExercises[1].id)

        await viewModel.completeWorkout()

        XCTAssertTrue(viewModel.isWorkoutCompleted)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(mockService.completedSessionId, testSession.id)
    }

    func testCompleteWorkout_Failure() async {
        mockService.shouldFailCompleteWorkout = true

        await viewModel.completeWorkout()

        XCTAssertFalse(viewModel.isWorkoutCompleted)
        XCTAssertTrue(viewModel.showError)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testCompleteWorkout_StopsTimer() async {
        viewModel.startTimer()
        try? await Task.sleep(nanoseconds: 100_000_000)

        await viewModel.completeWorkout()

        let timeAtComplete = viewModel.elapsedTime
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(viewModel.elapsedTime, timeAtComplete, "Timer should stop on workout completion")
    }

    // MARK: - Volume Calculation Tests

    func testTotalVolume_Initially() {
        XCTAssertEqual(viewModel.totalVolume, 0.0, "Volume should be 0 with no completed exercises")
    }

    func testTotalVolume_WithCompletedExercises() {
        // Create exercise with actual logged data
        var exercise = testExercises[0]
        exercise.actualReps = [10, 10, 10] // 30 total reps
        exercise.actualLoad = 100.0

        viewModel.exercises[0] = exercise
        viewModel.completedExerciseIds.insert(exercise.id)

        // Volume = 30 reps * 100 lbs = 3000
        XCTAssertEqual(viewModel.totalVolume, 3000.0)
    }

    func testVolumeDisplay_SmallVolume() {
        viewModel.exercises[0].actualReps = [5, 5, 5]
        viewModel.exercises[0].actualLoad = 10.0
        viewModel.completedExerciseIds.insert(testExercises[0].id)

        let display = viewModel.volumeDisplay
        XCTAssertTrue(display.contains("lbs"))
        XCTAssertFalse(display.contains("k"), "Small volume should not use 'k' format")
    }

    func testVolumeDisplay_LargeVolume() {
        viewModel.exercises[0].actualReps = [10, 10, 10, 10, 10, 10, 10, 10, 10, 10]
        viewModel.exercises[0].actualLoad = 100.0
        viewModel.completedExerciseIds.insert(testExercises[0].id)

        let display = viewModel.volumeDisplay
        XCTAssertTrue(display.contains("k"), "Large volume should use 'k' format")
    }

    // MARK: - Average RPE and Pain Tests

    func testAverageRPE_NoCompletedExercises() {
        XCTAssertNil(viewModel.averageRPE, "Should be nil with no completed exercises")
    }

    func testAverageRPE_WithCompletedExercises() {
        viewModel.exercises[0].rpe = 7.0
        viewModel.exercises[1].rpe = 8.0
        viewModel.completedExerciseIds.insert(testExercises[0].id)
        viewModel.completedExerciseIds.insert(testExercises[1].id)

        XCTAssertEqual(viewModel.averageRPE, 7.5, accuracy: 0.01)
    }

    func testAveragePain_NoCompletedExercises() {
        XCTAssertNil(viewModel.averagePain, "Should be nil with no completed exercises")
    }

    func testAveragePain_WithCompletedExercises() {
        viewModel.exercises[0].painScore = 2.0
        viewModel.exercises[1].painScore = 4.0
        viewModel.completedExerciseIds.insert(testExercises[0].id)
        viewModel.completedExerciseIds.insert(testExercises[1].id)

        XCTAssertEqual(viewModel.averagePain, 3.0, accuracy: 0.01)
    }

    // MARK: - Exercise Block Tests

    func testExercisesByBlock_GroupsCorrectly() {
        let exercises = [
            createExercise(name: "Squat", blockType: "Main"),
            createExercise(name: "Bench", blockType: "Main"),
            createExercise(name: "Stretch", blockType: "Warm-up"),
            createExercise(name: "Foam Roll", blockType: "Recovery")
        ]

        viewModel = ManualWorkoutExecutionViewModel(
            session: testSession,
            exercises: exercises,
            patientId: testPatientId,
            service: mockService
        )

        let blocks = viewModel.exercisesByBlock

        XCTAssertGreaterThanOrEqual(blocks.count, 1, "Should have at least one block")

        // Check that warm-up comes before main
        if let warmUpIndex = blocks.firstIndex(where: { $0.blockType == "Warm-up" }),
           let mainIndex = blocks.firstIndex(where: { $0.blockType == "Main" }) {
            XCTAssertLessThan(warmUpIndex, mainIndex, "Warm-up should come before Main")
        }
    }

    func testIsBlockCompleted_AllDone() {
        let exercises = [
            createExercise(name: "Ex1", blockType: "Main", sequence: 0),
            createExercise(name: "Ex2", blockType: "Main", sequence: 1)
        ]

        viewModel = ManualWorkoutExecutionViewModel(
            session: testSession,
            exercises: exercises,
            patientId: testPatientId,
            service: mockService
        )

        for exercise in exercises {
            viewModel.completedExerciseIds.insert(exercise.id)
        }

        XCTAssertTrue(viewModel.isBlockCompleted("Main"))
    }

    func testIsBlockCompleted_PartiallyDone() {
        let exercises = [
            createExercise(name: "Ex1", blockType: "Main", sequence: 0),
            createExercise(name: "Ex2", blockType: "Main", sequence: 1)
        ]

        viewModel = ManualWorkoutExecutionViewModel(
            session: testSession,
            exercises: exercises,
            patientId: testPatientId,
            service: mockService
        )

        viewModel.completedExerciseIds.insert(exercises[0].id)

        XCTAssertFalse(viewModel.isBlockCompleted("Main"))
    }

    func testIsBlockCompleted_IncludesSkipped() {
        let exercises = [
            createExercise(name: "Ex1", blockType: "Main", sequence: 0),
            createExercise(name: "Ex2", blockType: "Main", sequence: 1)
        ]

        viewModel = ManualWorkoutExecutionViewModel(
            session: testSession,
            exercises: exercises,
            patientId: testPatientId,
            service: mockService
        )

        viewModel.completedExerciseIds.insert(exercises[0].id)
        viewModel.skippedExerciseIds.insert(exercises[1].id)

        XCTAssertTrue(viewModel.isBlockCompleted("Main"), "Skipped exercises count as 'done' for block completion")
    }

    // MARK: - Exercise Management Tests

    func testReplaceExercise() {
        let oldExercise = testExercises[0]
        let newExercise = ManualSessionExercise(
            id: UUID(),
            manualSessionId: testSession.id,
            exerciseTemplateId: nil,
            exerciseName: "New Exercise",
            blockName: "Main",
            sequence: 0,
            targetSets: 4,
            targetReps: "8",
            targetLoad: 120.0,
            loadUnit: "lbs",
            restPeriodSeconds: 90,
            notes: nil,
            createdAt: Date()
        )

        viewModel.replaceExercise(oldExercise, with: newExercise)

        XCTAssertEqual(viewModel.exercises[0].exerciseName, "New Exercise")
        XCTAssertEqual(viewModel.exercises[0].id, newExercise.id)
    }

    func testAddExerciseFromTemplate() {
        let template = PickerExerciseTemplate(
            id: UUID(),
            name: "Romanian Deadlift",
            category: "Posterior Chain",
            bodyRegion: "Lower"
        )

        let initialCount = viewModel.exercises.count

        viewModel.addExerciseFromTemplate(template)

        XCTAssertEqual(viewModel.exercises.count, initialCount + 1)
        XCTAssertEqual(viewModel.exercises.last?.exerciseName, "Romanian Deadlift")
        XCTAssertEqual(viewModel.exercises.last?.blockName, "Posterior Chain")
        XCTAssertEqual(viewModel.exercises.last?.targetSets, 3, "Default sets should be 3")
        XCTAssertEqual(viewModel.exercises.last?.targetReps, "10", "Default reps should be 10")
    }

    // MARK: - Load Exercises Tests

    func testLoadExercisesIfNeeded_WhenExercisesExist() async {
        await viewModel.loadExercisesIfNeeded()

        XCTAssertNil(mockService.mockExercises.first, "Should not load when exercises already exist")
    }

    func testLoadExercisesIfNeeded_WhenEmpty() async {
        viewModel = ManualWorkoutExecutionViewModel(
            session: testSession,
            exercises: [],
            patientId: testPatientId,
            service: mockService
        )

        mockService.mockExercises = testExercises

        await viewModel.loadExercisesIfNeeded()

        XCTAssertEqual(viewModel.exercises.count, testExercises.count)
    }

    func testLoadExercisesIfNeeded_Failure() async {
        viewModel = ManualWorkoutExecutionViewModel(
            session: testSession,
            exercises: [],
            patientId: testPatientId,
            service: mockService
        )

        mockService.shouldFailLoadExercises = true

        await viewModel.loadExercisesIfNeeded()

        XCTAssertTrue(viewModel.showError)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - Helper Methods

    private func createMockSession() -> ManualSession {
        return ManualSession(
            id: UUID(),
            patientId: testPatientId,
            name: "Test Workout",
            notes: nil,
            sourceTemplateId: nil,
            sourceTemplateType: nil,
            startedAt: Date(),
            completedAt: nil,
            completed: false,
            totalVolume: nil,
            avgRpe: nil,
            avgPain: nil,
            durationMinutes: nil,
            createdAt: Date(),
            exercises: []
        )
    }

    private func createMockExercises(count: Int) -> [ManualSessionExercise] {
        return (0..<count).map { index in
            ManualSessionExercise(
                id: UUID(),
                manualSessionId: testSession.id,
                exerciseTemplateId: nil,
                exerciseName: "Exercise \(index + 1)",
                blockName: "Main",
                sequence: index,
                targetSets: 3,
                targetReps: "10",
                targetLoad: 100.0,
                loadUnit: "lbs",
                restPeriodSeconds: 90,
                notes: nil,
                createdAt: Date()
            )
        }
    }

    private func createExercise(
        name: String,
        blockType: String,
        sequence: Int = 0
    ) -> ManualSessionExercise {
        return ManualSessionExercise(
            id: UUID(),
            manualSessionId: testSession.id,
            exerciseTemplateId: nil,
            exerciseName: name,
            blockName: blockType,
            sequence: sequence,
            targetSets: 3,
            targetReps: "10",
            targetLoad: 100.0,
            loadUnit: "lbs",
            restPeriodSeconds: 90,
            notes: nil,
            createdAt: Date()
        )
    }
}

// MARK: - FatigueAdjustment.from Tests

@MainActor
final class FatigueAdjustmentFromAccumulationTests: XCTestCase {

    func testFrom_CriticalFatigue() {
        let accumulation = createMockAccumulation(fatigueBand: .critical)

        let adjustment = FatigueAdjustment.from(fatigue: accumulation)

        XCTAssertNotNil(adjustment)
        XCTAssertEqual(adjustment?.loadReductionPct, 0.5)
        XCTAssertEqual(adjustment?.volumeReductionPct, 0.4)
        XCTAssertEqual(adjustment?.fatigueBand, .critical)
    }

    func testFrom_HighFatigue() {
        let accumulation = createMockAccumulation(fatigueBand: .high)

        let adjustment = FatigueAdjustment.from(fatigue: accumulation)

        XCTAssertNotNil(adjustment)
        XCTAssertEqual(adjustment?.loadReductionPct, 0.3)
        XCTAssertEqual(adjustment?.volumeReductionPct, 0.25)
        XCTAssertEqual(adjustment?.fatigueBand, .high)
    }

    func testFrom_ModerateFatigue() {
        let accumulation = createMockAccumulation(fatigueBand: .moderate)

        let adjustment = FatigueAdjustment.from(fatigue: accumulation)

        XCTAssertNotNil(adjustment)
        XCTAssertEqual(adjustment?.loadReductionPct, 0.1)
        XCTAssertEqual(adjustment?.volumeReductionPct, 0.1)
        XCTAssertEqual(adjustment?.fatigueBand, .moderate)
    }

    func testFrom_LowFatigue() {
        let accumulation = createMockAccumulation(fatigueBand: .low)

        let adjustment = FatigueAdjustment.from(fatigue: accumulation)

        XCTAssertNil(adjustment, "Low fatigue should not create adjustment")
    }

    private func createMockAccumulation(fatigueBand: FatigueBand) -> FatigueAccumulation {
        return FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            avgReadiness7d: 65.0,
            avgReadiness14d: 68.0,
            trainingLoad7d: 1200,
            trainingLoad14d: 2400,
            acuteChronicRatio: 1.2,
            consecutiveLowReadiness: 0,
            missedRepsCount7d: 0,
            highRpeCount7d: 1,
            painReports7d: 0,
            fatigueScore: 50.0,
            fatigueBand: fatigueBand,
            deloadRecommended: false,
            deloadUrgency: .none,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
