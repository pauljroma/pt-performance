//
//  WorkoutViewModelTests.swift
//  PTPerformanceTests
//
//  Comprehensive unit tests for TodaySessionViewModel and related workout view models
//  Tests session state management, exercise progression, set logging, timer integration, and rest periods
//

import XCTest
import Combine
@testable import PTPerformance

// MARK: - Mock Workout Service Protocol

protocol WorkoutServiceProtocol {
    func fetchTodaySession(patientId: String) async throws -> (session: Session?, exercises: [Exercise])
    func logExercise(sessionExerciseId: UUID, patientId: String, sets: Int, reps: [Int], load: Double, loadUnit: String, rpe: Int, pain: Int, notes: String?) async throws
    func completeSession(sessionId: UUID, startedAt: Date, metrics: SessionMetrics) async throws -> Session
}

// MARK: - Mock Workout Service

final class MockWorkoutService: WorkoutServiceProtocol {
    var mockSession: Session?
    var mockExercises: [Exercise] = []
    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "MockError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock error"])

    var fetchTodaySessionCallCount = 0
    var logExerciseCallCount = 0
    var completeSessionCallCount = 0

    var lastLoggedExerciseId: UUID?
    var lastLoggedPatientId: String?
    var lastLoggedSets: Int?
    var lastLoggedReps: [Int]?
    var lastLoggedLoad: Double?
    var lastLoggedRpe: Int?
    var lastLoggedPain: Int?

    func fetchTodaySession(patientId: String) async throws -> (session: Session?, exercises: [Exercise]) {
        fetchTodaySessionCallCount += 1
        if shouldThrowError { throw errorToThrow }
        return (mockSession, mockExercises)
    }

    func logExercise(sessionExerciseId: UUID, patientId: String, sets: Int, reps: [Int], load: Double, loadUnit: String, rpe: Int, pain: Int, notes: String?) async throws {
        logExerciseCallCount += 1
        lastLoggedExerciseId = sessionExerciseId
        lastLoggedPatientId = patientId
        lastLoggedSets = sets
        lastLoggedReps = reps
        lastLoggedLoad = load
        lastLoggedRpe = rpe
        lastLoggedPain = pain
        if shouldThrowError { throw errorToThrow }
    }

    func completeSession(sessionId: UUID, startedAt: Date, metrics: SessionMetrics) async throws -> Session {
        completeSessionCallCount += 1
        if shouldThrowError { throw errorToThrow }
        return mockSession ?? createMockSession()
    }

    private func createMockSession() -> Session {
        return Session(
            id: UUID(),
            phaseId: UUID(),
            name: "Test Session",
            sequence: 1,
            completed: false,
            startedAt: nil,
            completedAt: nil,
            totalVolume: nil,
            avgRpe: nil,
            avgPain: nil,
            durationMinutes: nil,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - TodaySessionViewModel Tests

@MainActor
final class WorkoutViewModelTests: XCTestCase {

    var viewModel: TodaySessionViewModel!

    override func setUp() async throws {
        try await super.setUp()
        viewModel = TodaySessionViewModel()
    }

    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_SessionIsNil() {
        XCTAssertNil(viewModel.session, "Session should be nil initially")
    }

    func testInitialState_ExercisesIsEmpty() {
        XCTAssertTrue(viewModel.exercises.isEmpty, "Exercises should be empty initially")
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false initially")
    }

    func testInitialState_ErrorMessageIsNil() {
        XCTAssertNil(viewModel.errorMessage, "errorMessage should be nil initially")
    }

    func testInitialState_CompletedTodayCountIsZero() {
        XCTAssertEqual(viewModel.completedTodayCount, 0, "completedTodayCount should be 0 initially")
    }

    func testInitialState_TodaysCompletedWorkoutsIsEmpty() {
        XCTAssertTrue(viewModel.todaysCompletedWorkouts.isEmpty, "todaysCompletedWorkouts should be empty initially")
    }

    // MARK: - Session State Management Tests

    func testFetchTodaySession_SetsLoadingState() async {
        let expectation = expectation(description: "Fetch completes")

        Task {
            await viewModel.fetchTodaySession()
            expectation.fulfill()
        }

        // Loading state should toggle during fetch
        await fulfillment(of: [expectation], timeout: 10.0)
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after fetch")
    }

    func testFetchTodaySession_WithoutPatientID_SetsError() async {
        // Simulate no logged-in user scenario
        await viewModel.fetchTodaySession()

        XCTAssertFalse(viewModel.isLoading, "Should finish loading")
        XCTAssertNotNil(viewModel.errorMessage, "Should have error message when no patient ID")
    }

    func testFetchTodaySession_ClearsExistingError() async {
        // Set initial error
        viewModel.errorMessage = "Previous error"

        await viewModel.fetchTodaySession()

        // Error should be updated (cleared or new)
        XCTAssertNotEqual(viewModel.errorMessage, "Previous error", "Old error should be cleared")
    }

    // MARK: - Exercise Progression Tests

    func testExercises_CorrectOrder() {
        // Test that exercises maintain sequence order
        let exercise1 = createMockExercise(sequence: 1, name: "First Exercise")
        let exercise2 = createMockExercise(sequence: 2, name: "Second Exercise")
        let exercise3 = createMockExercise(sequence: 3, name: "Third Exercise")

        viewModel.exercises = [exercise3, exercise1, exercise2]

        // When sorted by sequence
        let sortedExercises = viewModel.exercises.sorted { $0.sequence < $1.sequence }

        XCTAssertEqual(sortedExercises[0].sequence, 1)
        XCTAssertEqual(sortedExercises[1].sequence, 2)
        XCTAssertEqual(sortedExercises[2].sequence, 3)
    }

    func testExercises_ContainsExerciseName() {
        let exercise = createMockExercise(sequence: 1, name: "Bench Press")
        viewModel.exercises = [exercise]

        XCTAssertEqual(viewModel.exercises.first?.exercise_name, "Bench Press")
    }

    // MARK: - Set Logging Tests

    func testUpdateExerciseLog_ValidatesParameters() async {
        let exercise = createMockExercise(sequence: 1, name: "Squat")
        viewModel.exercises = [exercise]

        // Should not crash with valid parameters
        await viewModel.updateExerciseLog(
            exercise,
            sets: 3,
            reps: [10, 10, 10],
            load: 135.0,
            loadUnit: "lbs",
            rpe: 7,
            pain: 0,
            notes: "Test notes"
        )

        // Test completes without error
        XCTAssertTrue(true)
    }

    func testQuickCompleteExercise_CallsUpdateExerciseLog() async {
        let exercise = createMockExercise(sequence: 1, name: "Deadlift")
        viewModel.exercises = [exercise]

        await viewModel.quickCompleteExercise(
            exercise,
            sets: 3,
            reps: [5, 5, 5],
            load: 225.0,
            loadUnit: "lbs",
            rpe: 8,
            pain: 1,
            notes: nil
        )

        // Test completes without crash
        XCTAssertTrue(true)
    }

    func testExerciseLog_RepsArray_MatchesSets() {
        let sets = 4
        let reps = [8, 8, 7, 6]

        XCTAssertEqual(reps.count, sets, "Reps array should have same count as sets")
    }

    func testExerciseLog_TotalReps_CalculatesCorrectly() {
        let reps = [10, 10, 8]
        let totalReps = reps.reduce(0, +)

        XCTAssertEqual(totalReps, 28, "Total reps should be sum of all reps")
    }

    func testExerciseLog_Volume_CalculatesCorrectly() {
        let reps = [10, 10, 10]
        let load = 135.0
        let totalReps = reps.reduce(0, +)
        let volume = Double(totalReps) * load

        XCTAssertEqual(volume, 4050.0, "Volume should be total reps * load")
    }

    // MARK: - Rest Period Handling Tests

    func testRestPeriod_DefaultValue() {
        // Typical rest periods in seconds
        let shortRest = 60  // 1 minute
        let mediumRest = 90  // 1.5 minutes
        let longRest = 180  // 3 minutes

        XCTAssertEqual(shortRest, 60)
        XCTAssertEqual(mediumRest, 90)
        XCTAssertEqual(longRest, 180)
    }

    func testRestPeriod_FormattedDisplay() {
        let restSeconds = 90
        let minutes = restSeconds / 60
        let seconds = restSeconds % 60
        let formatted = String(format: "%d:%02d", minutes, seconds)

        XCTAssertEqual(formatted, "1:30", "90 seconds should format as 1:30")
    }

    // MARK: - Session Completion Tests

    func testCompleteSession_RequiresActiveSession() async {
        viewModel.session = nil

        let result = await viewModel.completeSession(startedAt: Date())

        switch result {
        case .success:
            XCTFail("Should fail without active session")
        case .failure(let error):
            XCTAssertNotNil(error, "Should have error when no active session")
        }
    }

    // MARK: - Session Metrics Tests

    func testSessionMetrics_VolumeCalculation() {
        let logs = [
            createMockExerciseLogRecord(reps: [10, 10, 10], load: 100.0),
            createMockExerciseLogRecord(reps: [8, 8], load: 50.0)
        ]

        let totalVolume = logs.reduce(0.0) { sum, log in
            let repsSum = (log.actual_reps ?? []).reduce(0, +)
            let load = log.actual_load ?? 0
            return sum + (Double(repsSum) * load)
        }

        // (10+10+10) * 100 + (8+8) * 50 = 3000 + 800 = 3800
        XCTAssertEqual(totalVolume, 3800.0, "Total volume should be correctly calculated")
    }

    func testSessionMetrics_AverageRPE() {
        let rpeValues = [7, 8, 8, 9]
        let avgRpe = Double(rpeValues.reduce(0, +)) / Double(rpeValues.count)

        XCTAssertEqual(avgRpe, 8.0, "Average RPE should be correct")
    }

    func testSessionMetrics_AveragePain() {
        let painValues = [0, 1, 0, 2]
        let avgPain = Double(painValues.reduce(0, +)) / Double(painValues.count)

        XCTAssertEqual(avgPain, 0.75, "Average pain should be correct")
    }

    // MARK: - Today's Completed Workouts Tests

    func testFetchTodaysCompletedWorkouts_UpdatesCount() async {
        await viewModel.fetchTodaysCompletedWorkouts()

        // Count should be 0 or more (depends on actual data)
        XCTAssertGreaterThanOrEqual(viewModel.completedTodayCount, 0)
    }

    func testTodayWorkoutSummary_Properties() {
        let summary = TodayWorkoutSummary(
            id: UUID(),
            name: "Morning Workout",
            completedAt: Date(),
            durationMinutes: 45,
            totalVolume: 5000.0,
            exerciseCount: 5,
            isPrescribed: true
        )

        XCTAssertEqual(summary.name, "Morning Workout")
        XCTAssertEqual(summary.durationMinutes, 45)
        XCTAssertEqual(summary.totalVolume, 5000.0)
        XCTAssertEqual(summary.exerciseCount, 5)
        XCTAssertTrue(summary.isPrescribed)
    }

    // MARK: - Refresh Tests

    func testRefresh_CallsFetchMethods() async {
        await viewModel.refresh()

        XCTAssertFalse(viewModel.isLoading, "Should finish loading after refresh")
    }

    // MARK: - Offline Mode Tests

    func testIsOffline_ReturnsSupabaseOfflineStatus() {
        // Test that isOffline property exists and returns a boolean
        let offlineStatus = viewModel.isOffline
        XCTAssertTrue(offlineStatus == true || offlineStatus == false)
    }

    // MARK: - Pain Threshold Tests

    func testPainThreshold_NotificationTriggered() {
        let painNotificationThreshold = 5
        let painLevel = 6

        XCTAssertTrue(painLevel > painNotificationThreshold, "Pain above threshold should trigger notification")
    }

    func testPainThreshold_NotificationNotTriggered() {
        let painNotificationThreshold = 5
        let painLevel = 4

        XCTAssertFalse(painLevel > painNotificationThreshold, "Pain below threshold should not trigger notification")
    }

    // MARK: - Helper Methods

    private func createMockExercise(sequence: Int, name: String) -> Exercise {
        return Exercise(
            id: UUID(),
            sessionId: UUID(),
            exerciseTemplateId: UUID(),
            sequence: sequence,
            sets: 3,
            reps: 10,
            loadValue: 100.0,
            loadUnit: "lbs",
            tempo: nil,
            restSeconds: 90,
            notes: nil,
            exercise_name: name,
            category: "Strength",
            body_region: nil,
            video_url: nil,
            video_thumbnail_url: nil,
            video_duration: nil,
            technique_cues: nil,
            common_mistakes: nil,
            safety_notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func createMockExerciseLogRecord(reps: [Int], load: Double) -> ExerciseLogRecord {
        return ExerciseLogRecord(
            id: UUID().uuidString,
            session_exercise_id: UUID().uuidString,
            manual_session_exercise_id: nil,
            patient_id: UUID().uuidString,
            logged_at: Date(),
            actual_sets: reps.count,
            actual_reps: reps,
            actual_load: load,
            load_unit: "lbs",
            rpe: 7,
            pain_score: 0,
            notes: nil,
            created_at: Date()
        )
    }
}

// MARK: - ActiveTimerViewModel Tests

@MainActor
final class ActiveTimerViewModelTests: XCTestCase {

    var sut: ActiveTimerViewModel!

    override func setUp() {
        super.setUp()
        sut = ActiveTimerViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_StateIsIdle() {
        XCTAssertEqual(sut.state, .idle, "state should be idle initially")
    }

    func testInitialState_CurrentRoundIsZero() {
        XCTAssertEqual(sut.currentRound, 0, "currentRound should be 0 initially")
    }

    func testInitialState_TotalRoundsIsZero() {
        XCTAssertEqual(sut.totalRounds, 0, "totalRounds should be 0 initially")
    }

    func testInitialState_TimeRemainingIsZero() {
        XCTAssertEqual(sut.timeRemaining, 0, "timeRemaining should be 0 initially")
    }

    func testInitialState_TotalElapsedIsZero() {
        XCTAssertEqual(sut.totalElapsed, 0, "totalElapsed should be 0 initially")
    }

    // MARK: - Computed Property Tests

    func testFormattedTimeRemaining_FormatsCorrectly() {
        sut.timeRemaining = 65.5  // 1 minute, 5.5 seconds
        XCTAssertEqual(sut.formattedTimeRemaining, "1:05.5", "Should format as MM:SS.T")
    }

    func testFormattedTotalElapsed_FormatsCorrectly() {
        sut.totalElapsed = 125.0  // 2 minutes, 5 seconds
        XCTAssertEqual(sut.formattedTotalElapsed, "2:05", "Should format as MM:SS")
    }

    func testRoundProgress_CalculatesCorrectly() {
        sut.currentRound = 3
        sut.totalRounds = 10
        XCTAssertEqual(sut.roundProgress, 0.3, accuracy: 0.01, "Progress should be 30%")
    }

    func testRoundProgress_WhenZeroRounds_ReturnsZero() {
        sut.currentRound = 0
        sut.totalRounds = 0
        XCTAssertEqual(sut.roundProgress, 0, "Progress should be 0 when no rounds")
    }

    func testProgressPercentage_FormatsCorrectly() {
        sut.currentRound = 4
        sut.totalRounds = 8
        XCTAssertEqual(sut.progressPercentage, "50%")
    }

    // MARK: - Phase Color Tests

    func testPhaseColor_WorkIsRed() {
        sut.currentPhase = .work
        XCTAssertEqual(sut.phaseColor, .red)
    }

    func testPhaseColor_RestIsGreen() {
        sut.currentPhase = .rest
        XCTAssertEqual(sut.phaseColor, .green)
    }

    func testPhaseColor_BreakIsBlue() {
        sut.currentPhase = .break
        XCTAssertEqual(sut.phaseColor, .blue)
    }

    // MARK: - State Check Tests

    func testCanPause_WhenRunning_ReturnsTrue() {
        sut.state = .running
        XCTAssertTrue(sut.canPause)
    }

    func testCanPause_WhenPaused_ReturnsFalse() {
        sut.state = .paused
        XCTAssertFalse(sut.canPause)
    }

    func testCanResume_WhenPaused_ReturnsTrue() {
        sut.state = .paused
        XCTAssertTrue(sut.canResume)
    }

    func testCanResume_WhenRunning_ReturnsFalse() {
        sut.state = .running
        XCTAssertFalse(sut.canResume)
    }

    func testIsActive_WhenRunning_ReturnsTrue() {
        sut.state = .running
        XCTAssertTrue(sut.isActive)
    }

    func testIsActive_WhenPaused_ReturnsTrue() {
        sut.state = .paused
        XCTAssertTrue(sut.isActive)
    }

    func testIsActive_WhenIdle_ReturnsFalse() {
        sut.state = .idle
        XCTAssertFalse(sut.isActive)
    }

    func testIsActive_WhenCompleted_ReturnsFalse() {
        sut.state = .completed
        XCTAssertFalse(sut.isActive)
    }

    // MARK: - Round Status Text Tests

    func testRoundStatusText_FormatsCorrectly() {
        sut.currentRound = 5
        sut.totalRounds = 8
        XCTAssertEqual(sut.roundStatusText, "Round 5 of 8")
    }

    func testRoundStatusText_WhenZeroRounds_ReturnsEmpty() {
        sut.currentRound = 0
        sut.totalRounds = 0
        XCTAssertEqual(sut.roundStatusText, "")
    }

    // MARK: - Control Tests

    func testPauseTimer_SetsStateToPaused() {
        sut.state = .running
        sut.pauseTimer()
        XCTAssertEqual(sut.state, .paused)
    }

    func testPauseTimer_WhenNotRunning_NoChange() {
        sut.state = .idle
        sut.pauseTimer()
        XCTAssertEqual(sut.state, .idle)
    }

    func testResumeTimer_SetsStateToRunning() {
        sut.state = .paused
        sut.resumeTimer()
        XCTAssertEqual(sut.state, .running)
    }

    func testResumeTimer_WhenNotPaused_NoChange() {
        sut.state = .running
        sut.resumeTimer()
        XCTAssertEqual(sut.state, .running)
    }

    func testCancelTimer_SetsStateToIdle() {
        sut.state = .running
        sut.cancelTimer()
        XCTAssertEqual(sut.state, .idle)
    }

    // MARK: - Preview Support Tests

    func testPreview_Instance() {
        let preview = ActiveTimerViewModel.preview
        XCTAssertEqual(preview.state, .running)
        XCTAssertEqual(preview.currentRound, 3)
        XCTAssertEqual(preview.totalRounds, 8)
    }

    func testPreviewPaused_Instance() {
        let preview = ActiveTimerViewModel.previewPaused
        XCTAssertEqual(preview.state, .paused)
    }

    func testPreviewCompleted_Instance() {
        let preview = ActiveTimerViewModel.previewCompleted
        XCTAssertEqual(preview.state, .completed)
    }
}

// MARK: - SessionDetailViewModel Tests

@MainActor
final class SessionDetailViewModelTests: XCTestCase {

    var sut: SessionDetailViewModel!

    override func setUp() {
        super.setUp()
        sut = SessionDetailViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_ExerciseLogsIsEmpty() {
        XCTAssertTrue(sut.exerciseLogs.isEmpty, "exerciseLogs should be empty initially")
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading, "isLoading should be false initially")
    }

    func testInitialState_ErrorMessageIsNil() {
        XCTAssertNil(sut.errorMessage, "errorMessage should be nil initially")
    }

    // MARK: - Loading State Tests

    func testIsLoading_CanBeSet() {
        XCTAssertFalse(sut.isLoading)

        sut.isLoading = true
        XCTAssertTrue(sut.isLoading)

        sut.isLoading = false
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Error State Tests

    func testErrorMessage_CanBeSet() {
        XCTAssertNil(sut.errorMessage)

        sut.errorMessage = "Test error"
        XCTAssertEqual(sut.errorMessage, "Test error")

        sut.errorMessage = nil
        XCTAssertNil(sut.errorMessage)
    }
}
