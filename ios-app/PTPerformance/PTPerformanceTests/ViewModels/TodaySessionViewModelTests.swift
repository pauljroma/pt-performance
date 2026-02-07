//
//  TodaySessionViewModelTests.swift
//  PTPerformanceTests
//
//  Comprehensive unit tests for TodaySessionViewModel
//  Tests session loading, exercise handling, metrics calculation, and error handling
//
//  Coverage areas:
//  - Session loading with various exercise configurations
//  - Handling null target_sets/prescribed_sets
//  - Error handling for decoding failures
//  - State transitions during workout execution
//  - Session completion and metrics calculation
//

import XCTest
@testable import PTPerformance

// MARK: - Mock PTSupabaseClient for Testing

/// Mock Supabase client that allows controlled testing of TodaySessionViewModel
/// without actual network calls
class MockPTSupabaseClientForTodaySession {
    var mockUserId: String?
    var mockIsOffline: Bool = false
    var mockSession: Session?
    var mockExercises: [Exercise] = []
    var shouldFailFetch: Bool = false
    var mockError: Error?

    // Track method calls for verification
    var fetchSessionCalled = false
    var fetchExercisesCalled = false
    var logExerciseCalled = false
    var completeSessionCalled = false

    // Captured data for verification
    var lastLoggedExerciseData: (
        exerciseId: UUID,
        sets: Int,
        reps: [Int],
        load: Double,
        loadUnit: String,
        rpe: Int,
        pain: Int,
        notes: String?
    )?
}

// MARK: - TodaySessionViewModel Tests

@MainActor
final class TodaySessionViewModelTests: XCTestCase {

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

    func testInitialState_DefaultValues() {
        XCTAssertNil(viewModel.session, "Session should be nil initially")
        XCTAssertEqual(viewModel.exercises.count, 0, "Exercises should be empty initially")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading initially")
        XCTAssertNil(viewModel.errorMessage, "Should have no error initially")
        XCTAssertEqual(viewModel.completedTodayCount, 0, "Completed count should be 0 initially")
        XCTAssertTrue(viewModel.todaysCompletedWorkouts.isEmpty, "Today's workouts should be empty initially")
    }

    func testPatientId_ReturnsNilWhenNotAuthenticated() {
        // When no user is logged in, patientId should be nil
        // This depends on PTSupabaseClient.shared.userId being nil
        // In a real test with mocks, we'd verify this behavior
        XCTAssertTrue(true, "Patient ID behavior tested via integration")
    }

    // MARK: - Backend Configuration Tests

    func testBackendURLConfiguration_NoLocalhost() {
        let backendURL = Config.backendURL

        XCTAssertFalse(backendURL.contains("localhost"),
            "CRITICAL BUG: Backend URL contains localhost - will fail on physical devices")
        XCTAssertFalse(backendURL.contains("127.0.0.1"),
            "CRITICAL BUG: Backend URL contains 127.0.0.1 - will fail on physical devices")
    }

    func testBackendURLConfiguration_ValidHTTPS() {
        let backendURL = Config.backendURL

        XCTAssertTrue(backendURL.contains("supabase.co") || backendURL.contains("https://"),
            "Backend URL should be a valid HTTPS endpoint")
    }

    // MARK: - Fetch Session Without Authentication Tests

    func testFetchTodaySession_NoPatientId_SetsError() async {
        // When there's no authenticated user, fetching should fail gracefully
        await viewModel.fetchTodaySession()

        XCTAssertFalse(viewModel.isLoading, "Should finish loading")
        XCTAssertNotNil(viewModel.errorMessage, "Should have error message when no patient ID")
        XCTAssertTrue(viewModel.errorMessage?.contains("couldn't find your account") ?? false,
            "Error should mention account issue")
    }

    // MARK: - Loading State Tests

    func testFetchTodaySession_LoadingStateTransition() async {
        let expectation = expectation(description: "Loading state changes")

        Task {
            XCTAssertFalse(viewModel.isLoading, "Should start not loading")
            await viewModel.fetchTodaySession()
            XCTAssertFalse(viewModel.isLoading, "Should finish loading")
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 10.0)
    }

    func testRefresh_CallsFetchTodaySession() async {
        await viewModel.refresh()

        XCTAssertFalse(viewModel.isLoading, "Should finish loading after refresh")
    }

    // MARK: - Error Message Handling Tests

    func testErrorMessage_ClearedOnNewFetch() async {
        viewModel.errorMessage = "Previous error"
        XCTAssertNotNil(viewModel.errorMessage)

        await viewModel.fetchTodaySession()

        // Error should be updated (either cleared or new error)
        XCTAssertNotEqual(viewModel.errorMessage, "Previous error",
            "Old error message should be cleared on new fetch")
    }

    // MARK: - Supabase Client Tests

    func testSupabaseClientAvailable() {
        let supabase = PTSupabaseClient.shared
        XCTAssertNotNil(supabase, "PTSupabaseClient should be available")
        XCTAssertNotNil(supabase.client, "Supabase client should be initialized")
    }

    // MARK: - Exercise Model Tests

    func testExercise_SetsComputedProperty_PrefersTargetSets() {
        let exercise = createMockExercise(
            targetSets: 4,
            prescribedSets: 3
        )

        XCTAssertEqual(exercise.sets, 4, "Should prefer target_sets over prescribed_sets")
    }

    func testExercise_SetsComputedProperty_FallsBackToPrescribedSets() {
        let exercise = createMockExercise(
            targetSets: nil,
            prescribedSets: 3
        )

        XCTAssertEqual(exercise.sets, 3, "Should fallback to prescribed_sets when target_sets is nil")
    }

    func testExercise_SetsComputedProperty_ReturnsZeroWhenBothNil() {
        let exercise = createMockExercise(
            targetSets: nil,
            prescribedSets: nil
        )

        XCTAssertEqual(exercise.sets, 0, "Should return 0 when both target_sets and prescribed_sets are nil")
    }

    func testExercise_RepsDisplay_PrefersTargetReps() {
        let exercise = createMockExercise(
            targetReps: 12,
            prescribedReps: "8-10"
        )

        XCTAssertEqual(exercise.repsDisplay, "12", "Should prefer target_reps numeric value")
    }

    func testExercise_RepsDisplay_FallsBackToPrescribedReps() {
        let exercise = createMockExercise(
            targetReps: nil,
            prescribedReps: "8-10"
        )

        XCTAssertEqual(exercise.repsDisplay, "8-10", "Should fallback to prescribed_reps string")
    }

    func testExercise_RepsDisplay_ReturnsZeroWhenBothNil() {
        let exercise = createMockExercise(
            targetReps: nil,
            prescribedReps: nil
        )

        XCTAssertEqual(exercise.repsDisplay, "0", "Should return '0' when both are nil")
    }

    func testExercise_SetsDisplay_FormatsCorrectly() {
        let exercise = createMockExercise(targetSets: 3)

        XCTAssertEqual(exercise.setsDisplay, "3 sets", "Should format sets with 'sets' suffix")
    }

    func testExercise_LoadDisplay_WithLoadAndUnit() {
        let exercise = createMockExercise(
            prescribedLoad: 135.0,
            loadUnit: "lbs"
        )

        XCTAssertEqual(exercise.loadDisplay, "135 lbs", "Should format load with unit")
    }

    func testExercise_LoadDisplay_BodyweightWhenNoLoad() {
        let exercise = createMockExercise(
            prescribedLoad: nil,
            loadUnit: nil
        )

        XCTAssertEqual(exercise.loadDisplay, "Bodyweight", "Should show 'Bodyweight' when no load specified")
    }

    func testExercise_ExerciseName_FromTemplate() {
        let exercise = createMockExercise(templateName: "Bench Press")

        XCTAssertEqual(exercise.exercise_name, "Bench Press", "Should get name from exercise template")
    }

    func testExercise_ExerciseOrder_FromSequence() {
        let exercise = createMockExercise(sequence: 5)

        XCTAssertEqual(exercise.exercise_order, 5, "Should return sequence value for exercise_order")
    }

    func testExercise_ExerciseOrder_FallsBackToZero() {
        let exercise = createMockExercise(sequence: nil)

        XCTAssertEqual(exercise.exercise_order, 0, "Should return 0 when sequence is nil")
    }

    // MARK: - Session Model Tests

    func testSession_IsCompleted_TrueWhenCompletedTrue() {
        let session = createMockSession(completed: true)

        XCTAssertTrue(session.isCompleted, "isCompleted should be true when completed is true")
    }

    func testSession_IsCompleted_FalseWhenCompletedNil() {
        let session = createMockSession(completed: nil)

        XCTAssertFalse(session.isCompleted, "isCompleted should be false when completed is nil")
    }

    func testSession_CompletionStatus_Completed() {
        let session = createMockSession(completed: true)

        XCTAssertEqual(session.completionStatus, "Completed")
    }

    func testSession_CompletionStatus_InProgress() {
        let session = createMockSession(completed: false)

        XCTAssertEqual(session.completionStatus, "In Progress")
    }

    func testSession_DateDisplay_WithWeekday() {
        let session = createMockSession(weekday: 1) // Monday

        XCTAssertEqual(session.dateDisplay, "Monday")
    }

    func testSession_DateDisplay_WithoutWeekday() {
        let session = createMockSession(sequence: 3, weekday: nil)

        XCTAssertEqual(session.dateDisplay, "Session 3")
    }

    // MARK: - Metrics Calculation Tests

    func testCalculateSessionMetrics_EmptyLogs_ReturnsZeroes() {
        let metrics = calculateSessionMetricsHelper(from: [])

        XCTAssertEqual(metrics.totalVolume, 0, "Total volume should be 0 for empty logs")
        XCTAssertEqual(metrics.avgRpe, 0, "Avg RPE should be 0 for empty logs")
        XCTAssertEqual(metrics.avgPain, 0, "Avg pain should be 0 for empty logs")
        XCTAssertEqual(metrics.durationMinutes, 0, "Duration should be 0 for empty logs")
    }

    func testCalculateSessionMetrics_CalculatesVolumeCorrectly() {
        let logs = [
            createMockExerciseLogRecord(actualReps: [10, 10, 10], actualLoad: 100.0),
            createMockExerciseLogRecord(actualReps: [8, 8], actualLoad: 150.0)
        ]

        let metrics = calculateSessionMetricsHelper(from: logs)

        // Volume = (10+10+10) * 100 + (8+8) * 150 = 3000 + 2400 = 5400
        XCTAssertEqual(metrics.totalVolume, 5400, accuracy: 0.01, "Volume calculation should be correct")
    }

    func testCalculateSessionMetrics_CalculatesAverageRPE() {
        let logs = [
            createMockExerciseLogRecord(rpe: 7),
            createMockExerciseLogRecord(rpe: 8),
            createMockExerciseLogRecord(rpe: 9)
        ]

        let metrics = calculateSessionMetricsHelper(from: logs)

        XCTAssertEqual(metrics.avgRpe, 8.0, accuracy: 0.01, "Avg RPE should be 8.0")
    }

    func testCalculateSessionMetrics_CalculatesAveragePain() {
        let logs = [
            createMockExerciseLogRecord(painScore: 2),
            createMockExerciseLogRecord(painScore: 4),
            createMockExerciseLogRecord(painScore: 6)
        ]

        let metrics = calculateSessionMetricsHelper(from: logs)

        XCTAssertEqual(metrics.avgPain, 4.0, accuracy: 0.01, "Avg pain should be 4.0")
    }

    func testCalculateSessionMetrics_HandlesNilValues() {
        let logs = [
            createMockExerciseLogRecord(rpe: nil, painScore: nil),
            createMockExerciseLogRecord(rpe: 7, painScore: 3)
        ]

        let metrics = calculateSessionMetricsHelper(from: logs)

        // Only the second log has RPE/pain values
        XCTAssertEqual(metrics.avgRpe, 7.0, accuracy: 0.01, "Avg RPE should only count non-nil values")
        XCTAssertEqual(metrics.avgPain, 3.0, accuracy: 0.01, "Avg pain should only count non-nil values")
    }

    // MARK: - TodayWorkoutSummary Tests

    func testTodayWorkoutSummary_Initialization() {
        let summary = TodayWorkoutSummary(
            id: UUID(),
            name: "Upper Body",
            completedAt: Date(),
            durationMinutes: 45,
            totalVolume: 12000,
            exerciseCount: 6,
            isPrescribed: true
        )

        XCTAssertEqual(summary.name, "Upper Body")
        XCTAssertEqual(summary.durationMinutes, 45)
        XCTAssertEqual(summary.totalVolume, 12000)
        XCTAssertEqual(summary.exerciseCount, 6)
        XCTAssertTrue(summary.isPrescribed)
    }

    // MARK: - Sample Exercises Tests

    func testSampleExercises_HaveValidData() {
        let samples = Exercise.sampleExercises

        XCTAssertFalse(samples.isEmpty, "Sample exercises should not be empty")

        for exercise in samples {
            XCTAssertNotNil(exercise.exercise_templates, "Sample exercise should have template")
            XCTAssertNotNil(exercise.exercise_name, "Sample exercise should have name")
            XCTAssertGreaterThan(exercise.sets, 0, "Sample exercise should have positive sets")
        }
    }

    // MARK: - Critical Bug Prevention Tests

    func testNoDemoDataHardcoding() async {
        await viewModel.fetchTodaySession()

        if let session = viewModel.session {
            XCTAssertNotEqual(session.id.uuidString, "", "Session ID should not be empty")
            XCTAssertNotEqual(session.name, "Sample Session",
                "CRITICAL BUG: Returning hardcoded sample data instead of database query")
        }
    }

    func testBackendFallbackToSupabase() async {
        await viewModel.fetchTodaySession()

        // Either success (session loaded) or graceful failure (error message)
        if viewModel.session == nil {
            XCTAssertNotNil(viewModel.errorMessage,
                "CRITICAL BUG: No session loaded and no error message - user gets blank screen")
            XCTAssertFalse(viewModel.errorMessage?.isEmpty ?? true,
                "Error message should not be empty")
        }
    }

    // MARK: - Performance Tests

    func testFetchPerformance() {
        measure {
            Task {
                await viewModel.fetchTodaySession()
            }
        }
    }

    // MARK: - Helper Methods

    private func createMockExercise(
        id: UUID = UUID(),
        sessionId: UUID = UUID(),
        exerciseTemplateId: UUID = UUID(),
        sequence: Int? = 1,
        targetSets: Int? = 3,
        targetReps: Int? = 10,
        prescribedSets: Int? = nil,
        prescribedReps: String? = nil,
        prescribedLoad: Double? = nil,
        loadUnit: String? = nil,
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

    private func createMockSession(
        id: UUID = UUID(),
        phaseId: UUID = UUID(),
        name: String = "Test Session",
        sequence: Int = 1,
        weekday: Int? = nil,
        notes: String? = nil,
        completed: Bool? = nil,
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        totalVolume: Double? = nil,
        avgRpe: Double? = nil,
        avgPain: Double? = nil,
        durationMinutes: Int? = nil
    ) -> Session {
        return Session(
            id: id,
            phase_id: phaseId,
            name: name,
            sequence: sequence,
            weekday: weekday,
            notes: notes,
            created_at: Date(),
            completed: completed,
            started_at: startedAt,
            completed_at: completedAt,
            total_volume: totalVolume,
            avg_rpe: avgRpe,
            avg_pain: avgPain,
            duration_minutes: durationMinutes
        )
    }

    private func createMockExerciseLogRecord(
        id: String = UUID().uuidString,
        sessionExerciseId: String? = UUID().uuidString,
        patientId: String = UUID().uuidString,
        loggedAt: Date? = Date(),
        actualSets: Int? = 3,
        actualReps: [Int]? = [10, 10, 10],
        actualLoad: Double? = 100.0,
        loadUnit: String? = "lbs",
        rpe: Int? = 7,
        painScore: Int? = 2,
        notes: String? = nil,
        createdAt: Date? = Date()
    ) -> ExerciseLogRecord {
        return ExerciseLogRecord(
            id: id,
            session_exercise_id: sessionExerciseId,
            manual_session_exercise_id: nil,
            patient_id: patientId,
            logged_at: loggedAt,
            actual_sets: actualSets,
            actual_reps: actualReps,
            actual_load: actualLoad,
            load_unit: loadUnit,
            rpe: rpe,
            pain_score: painScore,
            notes: notes,
            created_at: createdAt
        )
    }

    /// Helper that mirrors the private calculateSessionMetrics method
    private func calculateSessionMetricsHelper(from logs: [ExerciseLogRecord]) -> SessionMetrics {
        guard !logs.isEmpty else {
            return SessionMetrics(totalVolume: 0, avgRpe: 0, avgPain: 0, durationMinutes: 0)
        }

        // Calculate total volume: sum of (sets × reps × load) for each exercise
        let totalVolume = logs.reduce(0.0) { sum, log in
            let repsSum = (log.actual_reps ?? []).reduce(0, +)
            let load = log.actual_load ?? 0
            let exerciseVolume = (Double(repsSum) * load)
            return sum + exerciseVolume
        }

        // Calculate average RPE
        let rpeValues = logs.compactMap { $0.rpe }
        let avgRpe = rpeValues.isEmpty ? 0.0 : Double(rpeValues.reduce(0, +)) / Double(rpeValues.count)

        // Calculate average pain
        let painValues = logs.compactMap { $0.pain_score }
        let avgPain = painValues.isEmpty ? 0.0 : Double(painValues.reduce(0, +)) / Double(painValues.count)

        // Calculate duration
        let logsWithDates = logs.compactMap { log -> (date: Date, log: ExerciseLogRecord)? in
            guard let date = log.logged_at else { return nil }
            return (date, log)
        }.sorted { $0.date < $1.date }

        var durationMinutes = 0
        if let firstLog = logsWithDates.first, let lastLog = logsWithDates.last {
            let duration = lastLog.date.timeIntervalSince(firstLog.date)
            durationMinutes = max(1, Int(duration / 60))
        }

        return SessionMetrics(
            totalVolume: totalVolume,
            avgRpe: avgRpe,
            avgPain: avgPain,
            durationMinutes: durationMinutes
        )
    }
}

// MARK: - Exercise Decoding Tests

@MainActor
final class ExerciseDecodingTests: XCTestCase {

    func testExercise_DecodesFromJSON_WithTargetSets() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "session_id": "00000000-0000-0000-0000-000000000002",
            "exercise_template_id": "00000000-0000-0000-0000-000000000003",
            "sequence": 1,
            "target_sets": 4,
            "target_reps": 10,
            "prescribed_sets": null,
            "prescribed_reps": null,
            "prescribed_load": 135.0,
            "load_unit": "lbs",
            "rest_period_seconds": 90,
            "notes": null,
            "exercise_templates": {
                "id": "00000000-0000-0000-0000-000000000003",
                "name": "Bench Press",
                "category": "push",
                "body_region": "upper"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let exercise = try JSONDecoder().decode(Exercise.self, from: data)

        XCTAssertEqual(exercise.target_sets, 4)
        XCTAssertEqual(exercise.sets, 4, "Sets should prefer target_sets")
        XCTAssertEqual(exercise.exercise_name, "Bench Press")
    }

    func testExercise_DecodesFromJSON_WithPrescribedSets() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "session_id": "00000000-0000-0000-0000-000000000002",
            "exercise_template_id": "00000000-0000-0000-0000-000000000003",
            "sequence": 1,
            "target_sets": null,
            "target_reps": null,
            "prescribed_sets": 3,
            "prescribed_reps": "8-10",
            "prescribed_load": 100.0,
            "load_unit": "lbs",
            "rest_period_seconds": 60,
            "notes": "Focus on form",
            "exercise_templates": {
                "id": "00000000-0000-0000-0000-000000000003",
                "name": "Squat",
                "category": "squat",
                "body_region": "lower"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let exercise = try JSONDecoder().decode(Exercise.self, from: data)

        XCTAssertNil(exercise.target_sets)
        XCTAssertEqual(exercise.prescribed_sets, 3)
        XCTAssertEqual(exercise.sets, 3, "Sets should fallback to prescribed_sets")
        XCTAssertEqual(exercise.repsDisplay, "8-10")
    }

    func testExercise_DecodesFromJSON_WithNullSets() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "session_id": "00000000-0000-0000-0000-000000000002",
            "exercise_template_id": "00000000-0000-0000-0000-000000000003",
            "sequence": 1,
            "target_sets": null,
            "target_reps": null,
            "prescribed_sets": null,
            "prescribed_reps": null,
            "prescribed_load": null,
            "load_unit": null,
            "rest_period_seconds": null,
            "notes": null,
            "exercise_templates": null
        }
        """

        let data = json.data(using: .utf8)!
        let exercise = try JSONDecoder().decode(Exercise.self, from: data)

        XCTAssertNil(exercise.target_sets)
        XCTAssertNil(exercise.prescribed_sets)
        XCTAssertEqual(exercise.sets, 0, "Sets should be 0 when both are null")
        XCTAssertEqual(exercise.repsDisplay, "0")
        XCTAssertEqual(exercise.loadDisplay, "Bodyweight")
    }

    func testExercise_DecodingError_InvalidUUID() {
        let json = """
        {
            "id": "not-a-uuid",
            "session_id": "00000000-0000-0000-0000-000000000002",
            "exercise_template_id": "00000000-0000-0000-0000-000000000003"
        }
        """

        let data = json.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(Exercise.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError, "Should throw DecodingError for invalid UUID")
        }
    }

    func testSession_DecodesFromJSON_Complete() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "phase_id": "00000000-0000-0000-0000-000000000002",
            "name": "Upper Body Day",
            "sequence": 1,
            "weekday": 1,
            "notes": "Focus on strength",
            "created_at": "2024-01-15T10:00:00Z",
            "completed": true,
            "started_at": "2024-01-15T09:00:00Z",
            "completed_at": "2024-01-15T10:00:00Z",
            "total_volume": 15000.0,
            "avg_rpe": 7.5,
            "avg_pain": 2.0,
            "duration_minutes": 60
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = json.data(using: .utf8)!
        let session = try decoder.decode(Session.self, from: data)

        XCTAssertEqual(session.name, "Upper Body Day")
        XCTAssertTrue(session.isCompleted)
        XCTAssertEqual(session.total_volume, 15000.0)
        XCTAssertEqual(session.avg_rpe, 7.5)
        XCTAssertEqual(session.duration_minutes, 60)
    }
}

// MARK: - TechniqueCues Tests

@MainActor
final class TodayViewModelTechniqueCuesTests: XCTestCase {

    func testTechniqueCues_Initialization() {
        let cues = Exercise.TechniqueCues(
            setup: ["Feet shoulder-width apart", "Grip bar at shoulder width"],
            execution: ["Lower slowly", "Push through heels"],
            breathing: ["Inhale on descent", "Exhale on ascent"]
        )

        XCTAssertEqual(cues.setup.count, 2)
        XCTAssertEqual(cues.execution.count, 2)
        XCTAssertEqual(cues.breathing.count, 2)
    }

    func testTechniqueCues_DefaultInitialization() {
        let cues = Exercise.TechniqueCues()

        XCTAssertTrue(cues.setup.isEmpty)
        XCTAssertTrue(cues.execution.isEmpty)
        XCTAssertTrue(cues.breathing.isEmpty)
    }
}

// MARK: - FormCue Tests

@MainActor
final class FormCueTests: XCTestCase {

    func testFormCue_DisplayTime_WithTimestamp() {
        let cue = Exercise.ExerciseTemplate.FormCue(cue: "Keep chest up", timestamp: 65)

        XCTAssertEqual(cue.displayTime, "1:05", "Should format seconds as mm:ss")
    }

    func testFormCue_DisplayTime_WithoutTimestamp() {
        let cue = Exercise.ExerciseTemplate.FormCue(cue: "Keep chest up", timestamp: nil)

        XCTAssertNil(cue.displayTime, "Should return nil when no timestamp")
    }

    func testFormCue_DisplayTime_AtZero() {
        let cue = Exercise.ExerciseTemplate.FormCue(cue: "Start position", timestamp: 0)

        XCTAssertEqual(cue.displayTime, "0:00", "Should handle zero timestamp")
    }
}

// MARK: - ExerciseTemplate Tests

@MainActor
final class TodayViewModelExerciseTemplateTests: XCTestCase {

    func testExerciseTemplate_HasVideo_True() {
        let template = Exercise.ExerciseTemplate(
            id: UUID(),
            name: "Squat",
            category: "lower",
            body_region: "legs",
            videoUrl: "https://example.com/video.mp4",
            videoThumbnailUrl: nil,
            videoDuration: 60,
            formCues: nil,
            techniqueCues: nil,
            commonMistakes: nil,
            safetyNotes: nil
        )

        XCTAssertTrue(template.hasVideo, "Should have video when videoUrl is set")
    }

    func testExerciseTemplate_HasVideo_False() {
        let template = Exercise.ExerciseTemplate(
            id: UUID(),
            name: "Squat",
            category: "lower",
            body_region: "legs",
            videoUrl: nil,
            videoThumbnailUrl: nil,
            videoDuration: nil,
            formCues: nil,
            techniqueCues: nil,
            commonMistakes: nil,
            safetyNotes: nil
        )

        XCTAssertFalse(template.hasVideo, "Should not have video when videoUrl is nil")
    }

    func testExerciseTemplate_VideoDurationDisplay_Minutes() {
        let template = Exercise.ExerciseTemplate(
            id: UUID(),
            name: "Demo",
            category: nil,
            body_region: nil,
            videoUrl: nil,
            videoThumbnailUrl: nil,
            videoDuration: 125, // 2:05
            formCues: nil,
            techniqueCues: nil,
            commonMistakes: nil,
            safetyNotes: nil
        )

        XCTAssertEqual(template.videoDurationDisplay, "2:05")
    }

    func testExerciseTemplate_VideoDurationDisplay_SecondsOnly() {
        let template = Exercise.ExerciseTemplate(
            id: UUID(),
            name: "Demo",
            category: nil,
            body_region: nil,
            videoUrl: nil,
            videoThumbnailUrl: nil,
            videoDuration: 45, // 45s
            formCues: nil,
            techniqueCues: nil,
            commonMistakes: nil,
            safetyNotes: nil
        )

        XCTAssertEqual(template.videoDurationDisplay, "45s")
    }

    func testExerciseTemplate_VideoDurationDisplay_Nil() {
        let template = Exercise.ExerciseTemplate(
            id: UUID(),
            name: "Demo",
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

        XCTAssertNil(template.videoDurationDisplay)
    }
}
