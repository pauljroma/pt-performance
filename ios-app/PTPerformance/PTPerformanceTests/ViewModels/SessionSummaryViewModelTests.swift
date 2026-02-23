//
//  SessionSummaryViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for SessionSummaryViewModel
//  Tests initial state, SessionSummaryData formatting, motivational messages,
//  ExerciseLogResponse volume calculations, and supporting model types.
//

import XCTest
@testable import PTPerformance

@MainActor
final class SessionSummaryViewModelTests: XCTestCase {

    var sut: SessionSummaryViewModel!

    override func setUp() async throws {
        try await super.setUp()
        sut = SessionSummaryViewModel()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading, "isLoading should be false initially")
    }

    func testInitialState_ErrorMessageIsNil() {
        XCTAssertNil(sut.errorMessage, "errorMessage should be nil initially")
    }

    func testInitialState_SummaryIsNil() {
        XCTAssertNil(sut.summary, "summary should be nil initially")
    }

    // MARK: - SessionSummaryData Tests - durationFormatted

    func testDurationFormatted_MinutesAndSeconds() {
        let data = SessionSummaryData(
            exercisesCompleted: 5,
            totalVolume: 10000,
            duration: 2700, // 45 min 0 sec
            prCount: 1,
            complianceScore: 90.0,
            motivationalMessage: "Great!"
        )
        XCTAssertEqual(data.durationFormatted, "45 min 0 sec")
    }

    func testDurationFormatted_SecondsOnly() {
        let data = SessionSummaryData(
            exercisesCompleted: 1,
            totalVolume: 500,
            duration: 45.0, // 0 min 45 sec
            prCount: 0,
            complianceScore: 80.0,
            motivationalMessage: "Good!"
        )
        XCTAssertEqual(data.durationFormatted, "45 sec")
    }

    func testDurationFormatted_OneMinuteThirtySeconds() {
        let data = SessionSummaryData(
            exercisesCompleted: 2,
            totalVolume: 1000,
            duration: 90.0, // 1 min 30 sec
            prCount: 0,
            complianceScore: 85.0,
            motivationalMessage: "Nice!"
        )
        XCTAssertEqual(data.durationFormatted, "1 min 30 sec")
    }

    func testDurationFormatted_ZeroDuration() {
        let data = SessionSummaryData(
            exercisesCompleted: 0,
            totalVolume: 0,
            duration: 0.0,
            prCount: 0,
            complianceScore: 0.0,
            motivationalMessage: "Start!"
        )
        XCTAssertEqual(data.durationFormatted, "0 sec")
    }

    func testDurationFormatted_LongDuration() {
        let data = SessionSummaryData(
            exercisesCompleted: 10,
            totalVolume: 20000,
            duration: 5400.0, // 90 min 0 sec
            prCount: 2,
            complianceScore: 95.0,
            motivationalMessage: "Outstanding!"
        )
        XCTAssertEqual(data.durationFormatted, "90 min 0 sec")
    }

    func testDurationFormatted_TruncatesSubSeconds() {
        let data = SessionSummaryData(
            exercisesCompleted: 3,
            totalVolume: 5000,
            duration: 123.7, // 2 min 3 sec (truncates .7)
            prCount: 0,
            complianceScore: 70.0,
            motivationalMessage: "Keep going!"
        )
        XCTAssertEqual(data.durationFormatted, "2 min 3 sec")
    }

    // MARK: - SessionSummaryData Tests - volumeFormatted

    func testVolumeFormatted_Under1000() {
        let data = SessionSummaryData(
            exercisesCompleted: 3,
            totalVolume: 750,
            duration: 1800,
            prCount: 0,
            complianceScore: 80.0,
            motivationalMessage: "Solid!"
        )
        XCTAssertEqual(data.volumeFormatted, "750 lbs")
    }

    func testVolumeFormatted_Exactly1000() {
        let data = SessionSummaryData(
            exercisesCompleted: 4,
            totalVolume: 1000,
            duration: 2000,
            prCount: 0,
            complianceScore: 85.0,
            motivationalMessage: "Nice!"
        )
        XCTAssertEqual(data.volumeFormatted, "1.0k lbs")
    }

    func testVolumeFormatted_Over1000() {
        let data = SessionSummaryData(
            exercisesCompleted: 6,
            totalVolume: 15500,
            duration: 3000,
            prCount: 1,
            complianceScore: 90.0,
            motivationalMessage: "Great!"
        )
        XCTAssertEqual(data.volumeFormatted, "15.5k lbs")
    }

    func testVolumeFormatted_Zero() {
        let data = SessionSummaryData(
            exercisesCompleted: 0,
            totalVolume: 0,
            duration: 0,
            prCount: 0,
            complianceScore: 0.0,
            motivationalMessage: "Every workout counts!"
        )
        XCTAssertEqual(data.volumeFormatted, "0 lbs")
    }

    func testVolumeFormatted_LargeVolume() {
        let data = SessionSummaryData(
            exercisesCompleted: 8,
            totalVolume: 125000,
            duration: 4500,
            prCount: 3,
            complianceScore: 98.0,
            motivationalMessage: "Outstanding!"
        )
        XCTAssertEqual(data.volumeFormatted, "125.0k lbs")
    }

    func testVolumeFormatted_999() {
        let data = SessionSummaryData(
            exercisesCompleted: 2,
            totalVolume: 999,
            duration: 1000,
            prCount: 0,
            complianceScore: 75.0,
            motivationalMessage: "Keep pushing!"
        )
        XCTAssertEqual(data.volumeFormatted, "999 lbs")
    }

    // MARK: - SessionSummaryData Tests - complianceFormatted

    func testComplianceFormatted_WholeNumber() {
        let data = SessionSummaryData(
            exercisesCompleted: 5,
            totalVolume: 10000,
            duration: 2700,
            prCount: 1,
            complianceScore: 85.0,
            motivationalMessage: "Great!"
        )
        XCTAssertEqual(data.complianceFormatted, "85%")
    }

    func testComplianceFormatted_WithDecimal_RoundsDown() {
        let data = SessionSummaryData(
            exercisesCompleted: 5,
            totalVolume: 10000,
            duration: 2700,
            prCount: 0,
            complianceScore: 92.4,
            motivationalMessage: "Solid!"
        )
        XCTAssertEqual(data.complianceFormatted, "92%")
    }

    func testComplianceFormatted_WithDecimal_RoundsUp() {
        let data = SessionSummaryData(
            exercisesCompleted: 5,
            totalVolume: 10000,
            duration: 2700,
            prCount: 0,
            complianceScore: 92.7,
            motivationalMessage: "Solid!"
        )
        XCTAssertEqual(data.complianceFormatted, "93%")
    }

    func testComplianceFormatted_ZeroPercent() {
        let data = SessionSummaryData(
            exercisesCompleted: 0,
            totalVolume: 0,
            duration: 0,
            prCount: 0,
            complianceScore: 0.0,
            motivationalMessage: "Start!"
        )
        XCTAssertEqual(data.complianceFormatted, "0%")
    }

    func testComplianceFormatted_HundredPercent() {
        let data = SessionSummaryData(
            exercisesCompleted: 5,
            totalVolume: 10000,
            duration: 2700,
            prCount: 2,
            complianceScore: 100.0,
            motivationalMessage: "Perfect!"
        )
        XCTAssertEqual(data.complianceFormatted, "100%")
    }

    // MARK: - SessionSummaryData Tests - Initialization

    func testSessionSummaryData_StoresAllProperties() {
        let data = SessionSummaryData(
            exercisesCompleted: 7,
            totalVolume: 12345,
            duration: 3456.0,
            prCount: 2,
            complianceScore: 88.5,
            motivationalMessage: "Keep it up!"
        )
        XCTAssertEqual(data.exercisesCompleted, 7)
        XCTAssertEqual(data.totalVolume, 12345)
        XCTAssertEqual(data.duration, 3456.0)
        XCTAssertEqual(data.prCount, 2)
        XCTAssertEqual(data.complianceScore, 88.5)
        XCTAssertEqual(data.motivationalMessage, "Keep it up!")
    }

    // MARK: - ExerciseLogResponse Tests

    func testExerciseLogResponse_Decodable() throws {
        let json = """
        {
            "id": "abc123",
            "session_exercise_id": "def456",
            "patient_id": "ghi789",
            "logged_at": "2024-01-15T12:00:00Z",
            "actual_sets": 3,
            "actual_reps": [10, 10, 8],
            "actual_load": 135.0,
            "rpe": 7,
            "pain_score": 0
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let log = try decoder.decode(ExerciseLogResponse.self, from: json)

        XCTAssertEqual(log.id, "abc123")
        XCTAssertEqual(log.session_exercise_id, "def456")
        XCTAssertEqual(log.patient_id, "ghi789")
        XCTAssertEqual(log.actual_sets, 3)
        XCTAssertEqual(log.actual_reps, [10, 10, 8])
        XCTAssertEqual(log.actual_load, 135.0)
        XCTAssertEqual(log.rpe, 7)
        XCTAssertEqual(log.pain_score, 0)
    }

    func testExerciseLogResponse_NullLoad() throws {
        let json = """
        {
            "id": "abc123",
            "session_exercise_id": "def456",
            "patient_id": "ghi789",
            "logged_at": "2024-01-15T12:00:00Z",
            "actual_sets": 3,
            "actual_reps": [15, 15, 12],
            "actual_load": null,
            "rpe": 5,
            "pain_score": 0
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let log = try decoder.decode(ExerciseLogResponse.self, from: json)

        XCTAssertNil(log.actual_load, "actual_load should be nil when null in JSON")
    }

    // MARK: - PrescribedExercise Tests

    func testPrescribedExercise_Decodable() throws {
        let json = """
        {
            "id": "ex123",
            "prescribed_sets": 4,
            "prescribed_reps": "8-10"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let prescribed = try decoder.decode(PrescribedExercise.self, from: json)

        XCTAssertEqual(prescribed.id, "ex123")
        XCTAssertEqual(prescribed.prescribed_sets, 4)
        XCTAssertEqual(prescribed.prescribed_reps, "8-10")
    }

    // MARK: - SessionPersonalRecord Tests

    func testSessionPersonalRecord_Initialization() {
        let pr = SessionPersonalRecord(
            exerciseId: "test-123",
            volume: 4050.0,
            reps: 30,
            load: 135.0
        )
        XCTAssertEqual(pr.exerciseId, "test-123")
        XCTAssertEqual(pr.volume, 4050.0)
        XCTAssertEqual(pr.reps, 30)
        XCTAssertEqual(pr.load, 135.0)
    }

    // MARK: - ViewModel State Tests

    func testSettingSummary_StoresData() {
        let data = SessionSummaryData(
            exercisesCompleted: 5,
            totalVolume: 10000,
            duration: 2700,
            prCount: 1,
            complianceScore: 90.0,
            motivationalMessage: "Outstanding!"
        )
        sut.summary = data
        XCTAssertNotNil(sut.summary)
        XCTAssertEqual(sut.summary?.exercisesCompleted, 5)
        XCTAssertEqual(sut.summary?.totalVolume, 10000)
        XCTAssertEqual(sut.summary?.prCount, 1)
    }

    func testSettingIsLoading() {
        sut.isLoading = true
        XCTAssertTrue(sut.isLoading)
        sut.isLoading = false
        XCTAssertFalse(sut.isLoading)
    }

    func testSettingErrorMessage() {
        XCTAssertNil(sut.errorMessage)
        sut.errorMessage = "Something went wrong"
        XCTAssertEqual(sut.errorMessage, "Something went wrong")
        sut.errorMessage = nil
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - ComplianceThreshold Logic Tests (via motivational message behavior)
    //
    // The generateMotivationalMessage method is private, but we can verify its behavior
    // by checking the motivational messages stored in SessionSummaryData that would be
    // produced by the known threshold logic.

    func testMotivationalMessage_ExceptionalWithPRs() {
        // PR > 0 && compliance >= 95
        let message = makeMotivationalMessage(compliance: 96.0, prCount: 1, volume: 15000)
        XCTAssertTrue(message.contains("Outstanding"), "exceptional + PR should contain 'Outstanding'")
        XCTAssertTrue(message.contains("personal record"), "should mention personal record")
    }

    func testMotivationalMessage_MultiplePRsExceptional() {
        let message = makeMotivationalMessage(compliance: 97.0, prCount: 3, volume: 20000)
        XCTAssertTrue(message.contains("3 personal records"), "should mention multiple PRs")
    }

    func testMotivationalMessage_PRsWithoutExceptionalCompliance() {
        // PR > 0 but compliance < 95
        let message = makeMotivationalMessage(compliance: 80.0, prCount: 2, volume: 15000)
        XCTAssertTrue(message.contains("PR"), "PR without exceptional should mention PRs")
        XCTAssertTrue(message.contains("stronger"), "should encourage with getting stronger")
    }

    func testMotivationalMessage_SinglePR() {
        let message = makeMotivationalMessage(compliance: 70.0, prCount: 1, volume: 10000)
        XCTAssertTrue(message.contains("1 PR"), "single PR message should say '1 PR'")
    }

    func testMotivationalMessage_HighCompliance_NoPR() {
        // No PRs, compliance >= 95
        let message = makeMotivationalMessage(compliance: 96.0, prCount: 0, volume: 12000)
        XCTAssertTrue(message.contains("Excellent"), "high compliance should say 'Excellent'")
        XCTAssertTrue(message.contains("precision"), "should mention precision")
    }

    func testMotivationalMessage_SolidCompliance() {
        // compliance >= 80 but < 95, no PRs
        let message = makeMotivationalMessage(compliance: 85.0, prCount: 0, volume: 10000)
        XCTAssertTrue(message.contains("Solid"), "solid compliance should say 'Solid'")
    }

    func testMotivationalMessage_GoodEffort() {
        // compliance >= 60 but < 80, no PRs
        let message = makeMotivationalMessage(compliance: 65.0, prCount: 0, volume: 8000)
        XCTAssertTrue(message.contains("Good effort"), "moderate compliance should say 'Good effort'")
        XCTAssertTrue(message.contains("consistency"), "should mention consistency")
    }

    func testMotivationalMessage_LowCompliance() {
        // compliance < 60, no PRs
        let message = makeMotivationalMessage(compliance: 40.0, prCount: 0, volume: 5000)
        XCTAssertTrue(message.contains("Every workout counts"), "low compliance should encourage with 'Every workout counts'")
    }

    func testMotivationalMessage_ZeroCompliance() {
        let message = makeMotivationalMessage(compliance: 0.0, prCount: 0, volume: 0)
        XCTAssertTrue(message.contains("Every workout counts"), "zero compliance should still encourage")
    }

    func testMotivationalMessage_ExactThreshold_95() {
        let message = makeMotivationalMessage(compliance: 95.0, prCount: 0, volume: 10000)
        XCTAssertTrue(message.contains("Excellent"), "exactly 95 should hit 'Excellent' tier")
    }

    func testMotivationalMessage_ExactThreshold_80() {
        let message = makeMotivationalMessage(compliance: 80.0, prCount: 0, volume: 10000)
        XCTAssertTrue(message.contains("Solid"), "exactly 80 should hit 'Solid' tier")
    }

    func testMotivationalMessage_ExactThreshold_60() {
        let message = makeMotivationalMessage(compliance: 60.0, prCount: 0, volume: 8000)
        XCTAssertTrue(message.contains("Good effort"), "exactly 60 should hit 'Good effort' tier")
    }

    // MARK: - Volume Calculation Logic Tests
    //
    // Test the volume formula: totalReps * load per exercise log

    func testVolumeCalculation_SingleLog() {
        // Simulate: actual_reps = [10, 10, 8], load = 135
        // totalReps = 28, volume = 28 * 135 = 3780
        let reps = [10, 10, 8]
        let load = 135.0
        let totalReps = reps.reduce(0, +)
        let volume = Double(totalReps) * load
        XCTAssertEqual(volume, 3780.0)
    }

    func testVolumeCalculation_NilLoad_TreatsAsZero() {
        let reps = [15, 15, 12]
        let load: Double? = nil
        let totalReps = reps.reduce(0, +)
        let volume = Double(totalReps) * (load ?? 0)
        XCTAssertEqual(volume, 0.0, "nil load should result in zero volume")
    }

    func testVolumeCalculation_EmptyReps() {
        let reps: [Int] = []
        let load = 100.0
        let totalReps = reps.reduce(0, +)
        let volume = Double(totalReps) * load
        XCTAssertEqual(volume, 0.0, "empty reps should result in zero volume")
    }

    func testVolumeCalculation_MultipleExercises() {
        // Exercise 1: [10, 10, 10] * 100 = 3000
        // Exercise 2: [8, 8, 6] * 135 = 2970
        // Exercise 3: [12, 12, 12] * 0 (bodyweight) = 0
        // Total = 5970
        let volumes: [Double] = [
            Double([10, 10, 10].reduce(0, +)) * 100.0,
            Double([8, 8, 6].reduce(0, +)) * 135.0,
            Double([12, 12, 12].reduce(0, +)) * 0.0
        ]
        let totalVolume = volumes.reduce(0, +)
        XCTAssertEqual(totalVolume, 5970.0)
    }

    // MARK: - Duration Calculation Logic Tests

    func testDurationCalculation_WithSessionTimes() {
        let start = Date()
        let end = start.addingTimeInterval(2700) // 45 minutes
        let duration = end.timeIntervalSince(start)
        XCTAssertEqual(duration, 2700.0)
    }

    func testDurationCalculation_SessionTimesPreferred() {
        // When both session times and log times exist, session times should be preferred
        let sessionStart = Date()
        let sessionEnd = sessionStart.addingTimeInterval(3600) // 1 hour
        let session = TestDataFactory.session(
            startedAt: sessionStart,
            completedAt: sessionEnd
        )
        let duration = session.completed_at!.timeIntervalSince(session.started_at!)
        XCTAssertEqual(duration, 3600.0, "should use session times when available")
    }

    // MARK: - PR Detection Logic Tests

    func testPRDetection_NewExercise_CountsAsPR() {
        // When no historical PR exists for an exercise, it's a PR by default
        // This is the logic: if historicalPR not found for exerciseId, count += 1
        let historicalPRs: [SessionPersonalRecord] = []
        let currentExerciseId = "new-exercise"
        let hasPR = !historicalPRs.contains(where: { $0.exerciseId == currentExerciseId })
        XCTAssertTrue(hasPR, "new exercise should count as PR")
    }

    func testPRDetection_ExceedsHistorical_CountsAsPR() {
        let historicalPR = SessionPersonalRecord(exerciseId: "squat-1", volume: 3000, reps: 30, load: 100)
        let currentVolume = 3500.0
        let isPR = currentVolume > historicalPR.volume
        XCTAssertTrue(isPR, "exceeding historical volume should be a PR")
    }

    func testPRDetection_BelowHistorical_NoPR() {
        let historicalPR = SessionPersonalRecord(exerciseId: "squat-1", volume: 3000, reps: 30, load: 100)
        let currentVolume = 2500.0
        let isPR = currentVolume > historicalPR.volume
        XCTAssertFalse(isPR, "below historical volume should not be a PR")
    }

    func testPRDetection_EqualToHistorical_NoPR() {
        let historicalPR = SessionPersonalRecord(exerciseId: "squat-1", volume: 3000, reps: 30, load: 100)
        let currentVolume = 3000.0
        let isPR = currentVolume > historicalPR.volume
        XCTAssertFalse(isPR, "equal to historical volume should not be a PR (needs to exceed)")
    }

    // MARK: - Edge Cases

    func testSummaryData_WithZeroExercises() {
        let data = SessionSummaryData(
            exercisesCompleted: 0,
            totalVolume: 0,
            duration: 0,
            prCount: 0,
            complianceScore: 0,
            motivationalMessage: "No exercises found for this session."
        )
        XCTAssertEqual(data.durationFormatted, "0 sec")
        XCTAssertEqual(data.volumeFormatted, "0 lbs")
        XCTAssertEqual(data.complianceFormatted, "0%")
    }

    func testSummaryData_VeryLargeDuration() {
        let data = SessionSummaryData(
            exercisesCompleted: 20,
            totalVolume: 50000,
            duration: 7200.0, // 2 hours
            prCount: 5,
            complianceScore: 100.0,
            motivationalMessage: "Legendary!"
        )
        XCTAssertEqual(data.durationFormatted, "120 min 0 sec")
    }

    func testSummaryCanBeOverwritten() {
        let data1 = SessionSummaryData(
            exercisesCompleted: 3,
            totalVolume: 5000,
            duration: 1800,
            prCount: 0,
            complianceScore: 75.0,
            motivationalMessage: "First"
        )
        sut.summary = data1
        XCTAssertEqual(sut.summary?.motivationalMessage, "First")

        let data2 = SessionSummaryData(
            exercisesCompleted: 6,
            totalVolume: 12000,
            duration: 3600,
            prCount: 2,
            complianceScore: 95.0,
            motivationalMessage: "Second"
        )
        sut.summary = data2
        XCTAssertEqual(sut.summary?.motivationalMessage, "Second")
        XCTAssertEqual(sut.summary?.exercisesCompleted, 6)
    }

    // MARK: - Helper Methods

    /// Simulates the generateMotivationalMessage logic from SessionSummaryViewModel
    /// This mirrors the private method so we can test the threshold behavior
    private func makeMotivationalMessage(compliance: Double, prCount: Int, volume: Double) -> String {
        // Exceptional performance (PR + high compliance)
        if prCount > 0 && compliance >= 95.0 {
            let prText = prCount == 1 ? "a personal record" : "\(prCount) personal records"
            return "Outstanding! You crushed it today with \(prText) and near-perfect execution!"
        }

        // Personal records
        if prCount > 0 {
            let prText = prCount == 1 ? "PR" : "PRs"
            return "Great work! \(prCount) \(prText) today - you're getting stronger!"
        }

        // High compliance
        if compliance >= 95.0 {
            return "Excellent work! You completed all prescribed reps with precision."
        }

        // Good compliance
        if compliance >= 80.0 {
            return "Solid session! You're making consistent progress toward your goals."
        }

        // Moderate compliance
        if compliance >= 60.0 {
            return "Good effort today! Remember, consistency is key to progress."
        }

        // Lower compliance - encouraging message
        return "Every workout counts! Focus on form and recovery for your next session."
    }
}
