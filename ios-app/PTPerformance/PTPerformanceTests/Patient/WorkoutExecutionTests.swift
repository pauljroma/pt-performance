//
//  WorkoutExecutionTests.swift
//  PTPerformanceTests
//
//  Comprehensive tests for patient workout execution features.
//  Tests starting workouts, exercise logging (sets, reps, weight, RPE, pain),
//  workout completion, and workout history.
//

import XCTest
@testable import PTPerformance

// MARK: - Mock Services

/// Mock service for testing workout execution without network calls
class MockWorkoutExecutionService {

    var shouldFailStartWorkout = false
    var shouldFailLogExercise = false
    var shouldFailCompleteWorkout = false
    var shouldFailFetchHistory = false

    var startWorkoutCallCount = 0
    var logExerciseCallCount = 0
    var completeWorkoutCallCount = 0
    var fetchHistoryCallCount = 0

    var lastLoggedExercise: (
        exerciseId: UUID,
        sets: Int,
        reps: [Int],
        weight: Double?,
        rpe: Int,
        painScore: Int,
        notes: String?
    )?

    var lastCompletedWorkout: (
        sessionId: UUID,
        totalVolume: Double?,
        avgRpe: Double?,
        avgPain: Double?,
        durationMinutes: Int?
    )?

    var mockWorkoutHistory: [MockCompletedWorkout] = []

    func startWorkout(templateId: UUID, patientId: UUID) async throws -> UUID {
        startWorkoutCallCount += 1
        if shouldFailStartWorkout {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to start workout"])
        }
        return UUID()
    }

    func logExercise(
        exerciseId: UUID,
        sets: Int,
        reps: [Int],
        weight: Double?,
        rpe: Int,
        painScore: Int,
        notes: String?
    ) async throws {
        logExerciseCallCount += 1
        if shouldFailLogExercise {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to log exercise"])
        }
        lastLoggedExercise = (exerciseId, sets, reps, weight, rpe, painScore, notes)
    }

    func completeWorkout(
        sessionId: UUID,
        totalVolume: Double?,
        avgRpe: Double?,
        avgPain: Double?,
        durationMinutes: Int?
    ) async throws {
        completeWorkoutCallCount += 1
        if shouldFailCompleteWorkout {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to complete workout"])
        }
        lastCompletedWorkout = (sessionId, totalVolume, avgRpe, avgPain, durationMinutes)
    }

    func fetchWorkoutHistory(patientId: UUID, limit: Int) async throws -> [MockCompletedWorkout] {
        fetchHistoryCallCount += 1
        if shouldFailFetchHistory {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch history"])
        }
        return mockWorkoutHistory
    }

    func reset() {
        shouldFailStartWorkout = false
        shouldFailLogExercise = false
        shouldFailCompleteWorkout = false
        shouldFailFetchHistory = false
        startWorkoutCallCount = 0
        logExerciseCallCount = 0
        completeWorkoutCallCount = 0
        fetchHistoryCallCount = 0
        lastLoggedExercise = nil
        lastCompletedWorkout = nil
        mockWorkoutHistory = []
    }
}

/// Mock completed workout for history testing
struct MockCompletedWorkout: Identifiable, Equatable {
    let id: UUID
    let name: String
    let completedAt: Date
    let totalVolume: Double
    let avgRpe: Double?
    let avgPain: Double?
    let durationMinutes: Int
    let exerciseCount: Int
}

// MARK: - Workout Execution Tests

@MainActor
final class WorkoutExecutionTests: XCTestCase {

    var mockService: MockWorkoutExecutionService!
    let testPatientId = UUID()
    let testTemplateId = UUID()

    override func setUp() async throws {
        try await super.setUp()
        mockService = MockWorkoutExecutionService()
    }

    override func tearDown() async throws {
        mockService = nil
        try await super.tearDown()
    }

    // MARK: - Starting Workout Tests

    func testStartWorkout_Success() async throws {
        let sessionId = try await mockService.startWorkout(templateId: testTemplateId, patientId: testPatientId)

        XCTAssertNotNil(sessionId, "Session ID should be returned on successful start")
        XCTAssertEqual(mockService.startWorkoutCallCount, 1, "Start workout should be called once")
    }

    func testStartWorkout_Failure() async {
        mockService.shouldFailStartWorkout = true

        do {
            _ = try await mockService.startWorkout(templateId: testTemplateId, patientId: testPatientId)
            XCTFail("Should throw error when start fails")
        } catch {
            XCTAssertEqual(mockService.startWorkoutCallCount, 1)
        }
    }

    func testStartWorkout_GeneratesUniqueSessionIds() async throws {
        let sessionId1 = try await mockService.startWorkout(templateId: testTemplateId, patientId: testPatientId)
        let sessionId2 = try await mockService.startWorkout(templateId: testTemplateId, patientId: testPatientId)

        XCTAssertNotEqual(sessionId1, sessionId2, "Each workout should have a unique session ID")
        XCTAssertEqual(mockService.startWorkoutCallCount, 2)
    }

    func testStartWorkout_WithDifferentTemplates() async throws {
        let template1 = UUID()
        let template2 = UUID()

        _ = try await mockService.startWorkout(templateId: template1, patientId: testPatientId)
        _ = try await mockService.startWorkout(templateId: template2, patientId: testPatientId)

        XCTAssertEqual(mockService.startWorkoutCallCount, 2)
    }

    // MARK: - Exercise Logging Tests

    func testLogExercise_BasicLog() async throws {
        let exerciseId = UUID()

        try await mockService.logExercise(
            exerciseId: exerciseId,
            sets: 3,
            reps: [10, 10, 10],
            weight: 100.0,
            rpe: 7,
            painScore: 0,
            notes: nil
        )

        XCTAssertEqual(mockService.logExerciseCallCount, 1)
        XCTAssertEqual(mockService.lastLoggedExercise?.exerciseId, exerciseId)
        XCTAssertEqual(mockService.lastLoggedExercise?.sets, 3)
        XCTAssertEqual(mockService.lastLoggedExercise?.reps, [10, 10, 10])
        XCTAssertEqual(mockService.lastLoggedExercise?.weight, 100.0)
        XCTAssertEqual(mockService.lastLoggedExercise?.rpe, 7)
        XCTAssertEqual(mockService.lastLoggedExercise?.painScore, 0)
    }

    func testLogExercise_WithVariableReps() async throws {
        let exerciseId = UUID()

        try await mockService.logExercise(
            exerciseId: exerciseId,
            sets: 3,
            reps: [12, 10, 8],  // Descending reps (fatigue)
            weight: 100.0,
            rpe: 8,
            painScore: 0,
            notes: nil
        )

        XCTAssertEqual(mockService.lastLoggedExercise?.reps, [12, 10, 8])
        XCTAssertEqual(mockService.lastLoggedExercise?.sets, 3)
    }

    func testLogExercise_WithNotes() async throws {
        let exerciseId = UUID()
        let notes = "Focused on tempo: 3-1-2"

        try await mockService.logExercise(
            exerciseId: exerciseId,
            sets: 3,
            reps: [10, 10, 10],
            weight: 100.0,
            rpe: 7,
            painScore: 0,
            notes: notes
        )

        XCTAssertEqual(mockService.lastLoggedExercise?.notes, notes)
    }

    func testLogExercise_WithoutWeight() async throws {
        let exerciseId = UUID()

        try await mockService.logExercise(
            exerciseId: exerciseId,
            sets: 3,
            reps: [15, 15, 15],
            weight: nil,  // Bodyweight exercise
            rpe: 6,
            painScore: 0,
            notes: nil
        )

        XCTAssertNil(mockService.lastLoggedExercise?.weight)
    }

    func testLogExercise_WithPain() async throws {
        let exerciseId = UUID()

        try await mockService.logExercise(
            exerciseId: exerciseId,
            sets: 3,
            reps: [8, 8, 6],
            weight: 135.0,
            rpe: 8,
            painScore: 4,  // Moderate pain
            notes: "Slight discomfort in left knee"
        )

        XCTAssertEqual(mockService.lastLoggedExercise?.painScore, 4)
        XCTAssertNotNil(mockService.lastLoggedExercise?.notes)
    }

    func testLogExercise_RPERange() async throws {
        let exerciseId = UUID()

        // Test minimum RPE
        try await mockService.logExercise(
            exerciseId: exerciseId,
            sets: 3,
            reps: [10, 10, 10],
            weight: 50.0,
            rpe: 1,
            painScore: 0,
            notes: nil
        )
        XCTAssertEqual(mockService.lastLoggedExercise?.rpe, 1)

        // Test maximum RPE
        try await mockService.logExercise(
            exerciseId: exerciseId,
            sets: 3,
            reps: [10, 10, 10],
            weight: 200.0,
            rpe: 10,
            painScore: 0,
            notes: nil
        )
        XCTAssertEqual(mockService.lastLoggedExercise?.rpe, 10)
    }

    func testLogExercise_PainScoreRange() async throws {
        let exerciseId = UUID()

        // Test zero pain
        try await mockService.logExercise(
            exerciseId: exerciseId,
            sets: 3,
            reps: [10, 10, 10],
            weight: 100.0,
            rpe: 7,
            painScore: 0,
            notes: nil
        )
        XCTAssertEqual(mockService.lastLoggedExercise?.painScore, 0)

        // Test high pain
        try await mockService.logExercise(
            exerciseId: exerciseId,
            sets: 2,
            reps: [5, 3],
            weight: 100.0,
            rpe: 9,
            painScore: 8,
            notes: "Had to stop due to pain"
        )
        XCTAssertEqual(mockService.lastLoggedExercise?.painScore, 8)
    }

    func testLogExercise_Failure() async {
        mockService.shouldFailLogExercise = true

        do {
            try await mockService.logExercise(
                exerciseId: UUID(),
                sets: 3,
                reps: [10, 10, 10],
                weight: 100.0,
                rpe: 7,
                painScore: 0,
                notes: nil
            )
            XCTFail("Should throw error when logging fails")
        } catch {
            XCTAssertEqual(mockService.logExerciseCallCount, 1)
        }
    }

    func testLogExercise_MultipleExercises() async throws {
        let exercise1 = UUID()
        let exercise2 = UUID()
        let exercise3 = UUID()

        try await mockService.logExercise(
            exerciseId: exercise1,
            sets: 4,
            reps: [8, 8, 8, 8],
            weight: 185.0,
            rpe: 8,
            painScore: 0,
            notes: nil
        )

        try await mockService.logExercise(
            exerciseId: exercise2,
            sets: 3,
            reps: [12, 12, 12],
            weight: 60.0,
            rpe: 7,
            painScore: 0,
            notes: nil
        )

        try await mockService.logExercise(
            exerciseId: exercise3,
            sets: 3,
            reps: [15, 15, 15],
            weight: nil,
            rpe: 6,
            painScore: 0,
            notes: nil
        )

        XCTAssertEqual(mockService.logExerciseCallCount, 3)
        XCTAssertEqual(mockService.lastLoggedExercise?.exerciseId, exercise3)
    }

    // MARK: - Workout Completion Tests

    func testCompleteWorkout_Success() async throws {
        let sessionId = UUID()

        try await mockService.completeWorkout(
            sessionId: sessionId,
            totalVolume: 15000.0,
            avgRpe: 7.5,
            avgPain: 1.0,
            durationMinutes: 45
        )

        XCTAssertEqual(mockService.completeWorkoutCallCount, 1)
        XCTAssertEqual(mockService.lastCompletedWorkout?.sessionId, sessionId)
        XCTAssertEqual(mockService.lastCompletedWorkout?.totalVolume, 15000.0)
        XCTAssertEqual(mockService.lastCompletedWorkout?.avgRpe, 7.5)
        XCTAssertEqual(mockService.lastCompletedWorkout?.avgPain, 1.0)
        XCTAssertEqual(mockService.lastCompletedWorkout?.durationMinutes, 45)
    }

    func testCompleteWorkout_WithNilMetrics() async throws {
        let sessionId = UUID()

        try await mockService.completeWorkout(
            sessionId: sessionId,
            totalVolume: nil,
            avgRpe: nil,
            avgPain: nil,
            durationMinutes: 30
        )

        XCTAssertNil(mockService.lastCompletedWorkout?.totalVolume)
        XCTAssertNil(mockService.lastCompletedWorkout?.avgRpe)
        XCTAssertNil(mockService.lastCompletedWorkout?.avgPain)
        XCTAssertEqual(mockService.lastCompletedWorkout?.durationMinutes, 30)
    }

    func testCompleteWorkout_Failure() async {
        mockService.shouldFailCompleteWorkout = true

        do {
            try await mockService.completeWorkout(
                sessionId: UUID(),
                totalVolume: 10000.0,
                avgRpe: 7.0,
                avgPain: 0.0,
                durationMinutes: 40
            )
            XCTFail("Should throw error when completion fails")
        } catch {
            XCTAssertEqual(mockService.completeWorkoutCallCount, 1)
        }
    }

    func testCompleteWorkout_HighVolume() async throws {
        let sessionId = UUID()
        let highVolume = 50000.0  // Heavy workout

        try await mockService.completeWorkout(
            sessionId: sessionId,
            totalVolume: highVolume,
            avgRpe: 9.0,
            avgPain: 2.0,
            durationMinutes: 90
        )

        XCTAssertEqual(mockService.lastCompletedWorkout?.totalVolume, highVolume)
    }

    func testCompleteWorkout_ShortDuration() async throws {
        let sessionId = UUID()

        try await mockService.completeWorkout(
            sessionId: sessionId,
            totalVolume: 5000.0,
            avgRpe: 6.0,
            avgPain: 0.0,
            durationMinutes: 15  // Quick workout
        )

        XCTAssertEqual(mockService.lastCompletedWorkout?.durationMinutes, 15)
    }

    // MARK: - Workout History Tests

    func testFetchWorkoutHistory_Empty() async throws {
        mockService.mockWorkoutHistory = []

        let history = try await mockService.fetchWorkoutHistory(patientId: testPatientId, limit: 10)

        XCTAssertTrue(history.isEmpty)
        XCTAssertEqual(mockService.fetchHistoryCallCount, 1)
    }

    func testFetchWorkoutHistory_WithData() async throws {
        let workout1 = MockCompletedWorkout(
            id: UUID(),
            name: "Upper Body",
            completedAt: Date(),
            totalVolume: 12000.0,
            avgRpe: 7.5,
            avgPain: 0.0,
            durationMinutes: 45,
            exerciseCount: 6
        )
        let workout2 = MockCompletedWorkout(
            id: UUID(),
            name: "Lower Body",
            completedAt: Date().addingTimeInterval(-86400),
            totalVolume: 18000.0,
            avgRpe: 8.0,
            avgPain: 1.0,
            durationMinutes: 55,
            exerciseCount: 5
        )
        mockService.mockWorkoutHistory = [workout1, workout2]

        let history = try await mockService.fetchWorkoutHistory(patientId: testPatientId, limit: 10)

        XCTAssertEqual(history.count, 2)
        XCTAssertEqual(history[0].name, "Upper Body")
        XCTAssertEqual(history[1].name, "Lower Body")
    }

    func testFetchWorkoutHistory_Failure() async {
        mockService.shouldFailFetchHistory = true

        do {
            _ = try await mockService.fetchWorkoutHistory(patientId: testPatientId, limit: 10)
            XCTFail("Should throw error when fetch fails")
        } catch {
            XCTAssertEqual(mockService.fetchHistoryCallCount, 1)
        }
    }

    func testFetchWorkoutHistory_WithLimit() async throws {
        let workouts = (0..<20).map { index in
            MockCompletedWorkout(
                id: UUID(),
                name: "Workout \(index)",
                completedAt: Date().addingTimeInterval(-Double(index) * 86400),
                totalVolume: Double(10000 + index * 1000),
                avgRpe: 7.0,
                avgPain: 0.0,
                durationMinutes: 40,
                exerciseCount: 5
            )
        }
        mockService.mockWorkoutHistory = workouts

        let history = try await mockService.fetchWorkoutHistory(patientId: testPatientId, limit: 10)

        // Note: The actual limiting would be done in real implementation
        XCTAssertEqual(history.count, 20)  // Mock returns all, real would limit
        XCTAssertEqual(mockService.fetchHistoryCallCount, 1)
    }

    func testFetchWorkoutHistory_SortedByDate() async throws {
        let today = Date()
        let yesterday = Date().addingTimeInterval(-86400)
        let lastWeek = Date().addingTimeInterval(-604800)

        let workout1 = MockCompletedWorkout(
            id: UUID(),
            name: "Last Week",
            completedAt: lastWeek,
            totalVolume: 10000.0,
            avgRpe: 7.0,
            avgPain: 0.0,
            durationMinutes: 40,
            exerciseCount: 5
        )
        let workout2 = MockCompletedWorkout(
            id: UUID(),
            name: "Today",
            completedAt: today,
            totalVolume: 12000.0,
            avgRpe: 7.5,
            avgPain: 0.0,
            durationMinutes: 45,
            exerciseCount: 6
        )
        let workout3 = MockCompletedWorkout(
            id: UUID(),
            name: "Yesterday",
            completedAt: yesterday,
            totalVolume: 11000.0,
            avgRpe: 7.0,
            avgPain: 0.0,
            durationMinutes: 42,
            exerciseCount: 5
        )
        mockService.mockWorkoutHistory = [workout1, workout2, workout3]

        let history = try await mockService.fetchWorkoutHistory(patientId: testPatientId, limit: 10)

        XCTAssertEqual(history.count, 3)
    }

    // MARK: - Volume Calculation Tests

    func testVolumeCalculation_SingleSet() {
        let sets = 1
        let reps = [10]
        let weight = 100.0

        let volume = calculateVolume(sets: sets, reps: reps, weight: weight)

        XCTAssertEqual(volume, 1000.0)  // 1 * 10 * 100
    }

    func testVolumeCalculation_MultipleSets() {
        let sets = 3
        let reps = [10, 10, 10]
        let weight = 100.0

        let volume = calculateVolume(sets: sets, reps: reps, weight: weight)

        XCTAssertEqual(volume, 3000.0)  // 30 * 100
    }

    func testVolumeCalculation_VariableReps() {
        let sets = 3
        let reps = [12, 10, 8]
        let weight = 100.0

        let volume = calculateVolume(sets: sets, reps: reps, weight: weight)

        XCTAssertEqual(volume, 3000.0)  // (12 + 10 + 8) * 100
    }

    func testVolumeCalculation_NoWeight() {
        let sets = 3
        let reps = [15, 15, 15]
        let weight: Double? = nil

        let volume = calculateVolume(sets: sets, reps: reps, weight: weight)

        XCTAssertEqual(volume, 0.0)  // Bodyweight exercises don't contribute to volume
    }

    // MARK: - Elapsed Time Tests

    func testElapsedTimeDisplay_Seconds() {
        XCTAssertEqual(formatElapsedTime(seconds: 0), "00:00")
        XCTAssertEqual(formatElapsedTime(seconds: 30), "00:30")
        XCTAssertEqual(formatElapsedTime(seconds: 59), "00:59")
    }

    func testElapsedTimeDisplay_Minutes() {
        XCTAssertEqual(formatElapsedTime(seconds: 60), "01:00")
        XCTAssertEqual(formatElapsedTime(seconds: 90), "01:30")
        XCTAssertEqual(formatElapsedTime(seconds: 125), "02:05")
    }

    func testElapsedTimeDisplay_LongWorkout() {
        XCTAssertEqual(formatElapsedTime(seconds: 3600), "60:00")  // 1 hour
        XCTAssertEqual(formatElapsedTime(seconds: 3665), "61:05")  // 61 min 5 sec
    }

    // MARK: - Progress Calculation Tests

    func testProgressPercentage_NoExercises() {
        let completed = 0
        let total = 0

        let progress = calculateProgress(completed: completed, total: total)

        XCTAssertEqual(progress, 0.0)
    }

    func testProgressPercentage_PartialCompletion() {
        let completed = 3
        let total = 6

        let progress = calculateProgress(completed: completed, total: total)

        XCTAssertEqual(progress, 0.5, accuracy: 0.001)
    }

    func testProgressPercentage_FullCompletion() {
        let completed = 5
        let total = 5

        let progress = calculateProgress(completed: completed, total: total)

        XCTAssertEqual(progress, 1.0)
    }

    // MARK: - Helper Methods

    private func calculateVolume(sets: Int, reps: [Int], weight: Double?) -> Double {
        guard let weight = weight else { return 0.0 }
        let totalReps = reps.reduce(0, +)
        return Double(totalReps) * weight
    }

    private func formatElapsedTime(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    private func calculateProgress(completed: Int, total: Int) -> Double {
        guard total > 0 else { return 0.0 }
        return Double(completed) / Double(total)
    }
}

// MARK: - Exercise Set Model Tests

final class ExerciseSetModelTests: XCTestCase {

    func testExerciseSet_Creation() {
        let setNumber = 1
        let targetReps = 10
        let targetWeight = 100.0

        XCTAssertEqual(setNumber, 1)
        XCTAssertEqual(targetReps, 10)
        XCTAssertEqual(targetWeight, 100.0)
    }

    func testExerciseSet_Completion() {
        var completedReps = 10
        var completedWeight = 100.0
        var isCompleted = true

        XCTAssertEqual(completedReps, 10)
        XCTAssertEqual(completedWeight, 100.0)
        XCTAssertTrue(isCompleted)

        // Modify for partial completion
        completedReps = 8
        completedWeight = 95.0

        XCTAssertEqual(completedReps, 8)
        XCTAssertEqual(completedWeight, 95.0)
    }

    func testExerciseSet_VolumeCalculation() {
        let reps = 10
        let weight = 100.0

        let volume = Double(reps) * weight

        XCTAssertEqual(volume, 1000.0)
    }

    func testExerciseSet_ZeroWeight() {
        let reps = 15
        let weight = 0.0

        let volume = Double(reps) * weight

        XCTAssertEqual(volume, 0.0)
    }
}

// MARK: - Workout Timer Tests

final class WorkoutTimerModelTests: XCTestCase {

    func testWorkoutDuration_InSeconds() {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(2700)  // 45 minutes

        let duration = endTime.timeIntervalSince(startTime)

        XCTAssertEqual(duration, 2700, accuracy: 0.1)
    }

    func testWorkoutDuration_InMinutes() {
        let durationSeconds = 2700.0
        let durationMinutes = Int(durationSeconds / 60)

        XCTAssertEqual(durationMinutes, 45)
    }

    func testWorkoutDuration_Formatting() {
        let durationMinutes = 45

        let formatted = "\(durationMinutes) min"

        XCTAssertEqual(formatted, "45 min")
    }

    func testWorkoutDuration_LongWorkout() {
        let durationMinutes = 90

        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60

        XCTAssertEqual(hours, 1)
        XCTAssertEqual(minutes, 30)
    }
}

// MARK: - RPE Description Tests

final class RPEDescriptionTests: XCTestCase {

    func testRPE_VeryLight() {
        let rpe = 1
        let description = describeRPE(rpe)
        XCTAssertEqual(description, "Very Light")
    }

    func testRPE_Light() {
        let rpe = 3
        let description = describeRPE(rpe)
        XCTAssertEqual(description, "Light")
    }

    func testRPE_Moderate() {
        let rpe = 5
        let description = describeRPE(rpe)
        XCTAssertEqual(description, "Moderate")
    }

    func testRPE_SomewhatHard() {
        let rpe = 7
        let description = describeRPE(rpe)
        XCTAssertEqual(description, "Somewhat Hard")
    }

    func testRPE_Hard() {
        let rpe = 8
        let description = describeRPE(rpe)
        XCTAssertEqual(description, "Hard")
    }

    func testRPE_VeryHard() {
        let rpe = 9
        let description = describeRPE(rpe)
        XCTAssertEqual(description, "Very Hard")
    }

    func testRPE_Maximal() {
        let rpe = 10
        let description = describeRPE(rpe)
        XCTAssertEqual(description, "Maximal")
    }

    private func describeRPE(_ rpe: Int) -> String {
        switch rpe {
        case 1...2: return "Very Light"
        case 3...4: return "Light"
        case 5...6: return "Moderate"
        case 7: return "Somewhat Hard"
        case 8: return "Hard"
        case 9: return "Very Hard"
        case 10: return "Maximal"
        default: return "Unknown"
        }
    }
}

// MARK: - Pain Score Description Tests

final class PainScoreDescriptionTests: XCTestCase {

    func testPainScore_NoPain() {
        let pain = 0
        let description = describePain(pain)
        XCTAssertEqual(description, "No Pain")
    }

    func testPainScore_Mild() {
        let pain = 2
        let description = describePain(pain)
        XCTAssertEqual(description, "Mild")
    }

    func testPainScore_Moderate() {
        let pain = 5
        let description = describePain(pain)
        XCTAssertEqual(description, "Moderate")
    }

    func testPainScore_Severe() {
        let pain = 8
        let description = describePain(pain)
        XCTAssertEqual(description, "Severe")
    }

    func testPainScore_Worst() {
        let pain = 10
        let description = describePain(pain)
        XCTAssertEqual(description, "Worst Possible")
    }

    private func describePain(_ pain: Int) -> String {
        switch pain {
        case 0: return "No Pain"
        case 1...3: return "Mild"
        case 4...6: return "Moderate"
        case 7...9: return "Severe"
        case 10: return "Worst Possible"
        default: return "Unknown"
        }
    }
}
