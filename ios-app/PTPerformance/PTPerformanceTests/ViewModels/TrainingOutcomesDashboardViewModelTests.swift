//
//  TrainingOutcomesDashboardViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for TrainingOutcomesDashboardViewModel
//  Tests initial state, computed sorting/filtering helpers, and published properties
//

import XCTest
@testable import PTPerformance

// MARK: - Training Outcomes Dashboard ViewModel Tests

@MainActor
final class TrainingOutcomesDashboardViewModelTests: XCTestCase {

    var sut: TrainingOutcomesDashboardViewModel!

    override func setUp() async throws {
        try await super.setUp()
        sut = TrainingOutcomesDashboardViewModel()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_OutcomesIsNil() {
        XCTAssertNil(sut.outcomes, "outcomes should be nil initially")
    }

    func testInitialState_SummaryIsNil() {
        XCTAssertNil(sut.summary, "summary should be nil initially")
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading, "isLoading should be false initially")
    }

    func testInitialState_ErrorMessageIsNil() {
        XCTAssertNil(sut.errorMessage, "errorMessage should be nil initially")
    }

    func testInitialState_SelectedPatientIdIsNil() {
        XCTAssertNil(sut.selectedPatientId, "selectedPatientId should be nil initially")
    }

    // MARK: - Published Properties Settable Tests

    func testPublishedProperties_IsLoadingCanBeSet() {
        sut.isLoading = true
        XCTAssertTrue(sut.isLoading, "isLoading should be settable to true")
    }

    func testPublishedProperties_ErrorMessageCanBeSet() {
        sut.errorMessage = "Something went wrong"
        XCTAssertEqual(sut.errorMessage, "Something went wrong")
    }

    func testPublishedProperties_SelectedPatientIdCanBeSet() {
        sut.selectedPatientId = "patient-abc-123"
        XCTAssertEqual(sut.selectedPatientId, "patient-abc-123")
    }

    // MARK: - selectedPatientId Tracking Tests

    func testSelectedPatientId_CanBeSetAndCleared() {
        XCTAssertNil(sut.selectedPatientId)

        sut.selectedPatientId = "patient-001"
        XCTAssertEqual(sut.selectedPatientId, "patient-001")

        sut.selectedPatientId = "patient-002"
        XCTAssertEqual(sut.selectedPatientId, "patient-002")

        sut.selectedPatientId = nil
        XCTAssertNil(sut.selectedPatientId)
    }

    func testSelectedPatientId_TracksMultipleChanges() {
        let patientIds = ["p-1", "p-2", "p-3", "p-4"]

        for patientId in patientIds {
            sut.selectedPatientId = patientId
            XCTAssertEqual(sut.selectedPatientId, patientId,
                           "selectedPatientId should track changes to \(patientId)")
        }
    }

    // MARK: - sortedStrengthGains Tests

    func testSortedStrengthGains_WhenOutcomesIsNil_ReturnsEmpty() {
        sut.outcomes = nil
        XCTAssertTrue(sut.sortedStrengthGains.isEmpty,
                      "sortedStrengthGains should be empty when outcomes is nil")
    }

    func testSortedStrengthGains_WhenStrengthGainsIsNil_ReturnsEmpty() {
        sut.outcomes = TrainingOutcomeData(
            volumeProgression: nil,
            strengthGains: nil,
            painTrend: nil,
            adherence: nil,
            recoveryCorrelation: nil
        )
        XCTAssertTrue(sut.sortedStrengthGains.isEmpty,
                      "sortedStrengthGains should be empty when strengthGains is nil")
    }

    func testSortedStrengthGains_WhenStrengthGainsIsEmpty_ReturnsEmpty() {
        sut.outcomes = TrainingOutcomeData(
            volumeProgression: nil,
            strengthGains: [],
            painTrend: nil,
            adherence: nil,
            recoveryCorrelation: nil
        )
        XCTAssertTrue(sut.sortedStrengthGains.isEmpty,
                      "sortedStrengthGains should be empty when strengthGains is empty array")
    }

    func testSortedStrengthGains_SortedByPctChangeDescending() {
        let gains = [
            StrengthGain(exerciseName: "Squat", startLoad: 100, currentLoad: 120, pctChange: 20.0, dataPoints: 10),
            StrengthGain(exerciseName: "Deadlift", startLoad: 150, currentLoad: 225, pctChange: 50.0, dataPoints: 8),
            StrengthGain(exerciseName: "Bench", startLoad: 80, currentLoad: 88, pctChange: 10.0, dataPoints: 12),
            StrengthGain(exerciseName: "OHP", startLoad: 50, currentLoad: 67, pctChange: 35.0, dataPoints: 6)
        ]

        sut.outcomes = TrainingOutcomeData(
            volumeProgression: nil,
            strengthGains: gains,
            painTrend: nil,
            adherence: nil,
            recoveryCorrelation: nil
        )

        let sorted = sut.sortedStrengthGains

        XCTAssertEqual(sorted.count, 4, "Should have 4 sorted entries")
        XCTAssertEqual(sorted[0].exerciseName, "Deadlift", "Deadlift (50%) should be first")
        XCTAssertEqual(sorted[1].exerciseName, "OHP", "OHP (35%) should be second")
        XCTAssertEqual(sorted[2].exerciseName, "Squat", "Squat (20%) should be third")
        XCTAssertEqual(sorted[3].exerciseName, "Bench", "Bench (10%) should be fourth")
    }

    func testSortedStrengthGains_HandlesNilPctChangeValues() {
        let gains = [
            StrengthGain(exerciseName: "Squat", startLoad: 100, currentLoad: 120, pctChange: 20.0, dataPoints: 10),
            StrengthGain(exerciseName: "Deadlift", startLoad: 150, currentLoad: nil, pctChange: nil, dataPoints: 8),
            StrengthGain(exerciseName: "Bench", startLoad: 80, currentLoad: 88, pctChange: 10.0, dataPoints: 12)
        ]

        sut.outcomes = TrainingOutcomeData(
            volumeProgression: nil,
            strengthGains: gains,
            painTrend: nil,
            adherence: nil,
            recoveryCorrelation: nil
        )

        let sorted = sut.sortedStrengthGains

        XCTAssertEqual(sorted.count, 3, "Should have 3 sorted entries")
        XCTAssertEqual(sorted[0].exerciseName, "Squat", "Squat (20%) should be first")
        XCTAssertEqual(sorted[1].exerciseName, "Bench", "Bench (10%) should be second")
        XCTAssertEqual(sorted[2].exerciseName, "Deadlift", "Deadlift (nil -> 0) should be last")
    }

    func testSortedStrengthGains_HandlesNegativePctChange() {
        let gains = [
            StrengthGain(exerciseName: "Squat", startLoad: 100, currentLoad: 90, pctChange: -10.0, dataPoints: 5),
            StrengthGain(exerciseName: "Bench", startLoad: 80, currentLoad: 96, pctChange: 20.0, dataPoints: 8),
            StrengthGain(exerciseName: "Deadlift", startLoad: 150, currentLoad: 120, pctChange: -20.0, dataPoints: 4)
        ]

        sut.outcomes = TrainingOutcomeData(
            volumeProgression: nil,
            strengthGains: gains,
            painTrend: nil,
            adherence: nil,
            recoveryCorrelation: nil
        )

        let sorted = sut.sortedStrengthGains

        XCTAssertEqual(sorted[0].exerciseName, "Bench", "Bench (20%) should be first")
        XCTAssertEqual(sorted[1].exerciseName, "Squat", "Squat (-10%) should be second")
        XCTAssertEqual(sorted[2].exerciseName, "Deadlift", "Deadlift (-20%) should be last")
    }

    func testSortedStrengthGains_SingleItem() {
        let gains = [
            StrengthGain(exerciseName: "Squat", startLoad: 100, currentLoad: 130, pctChange: 30.0, dataPoints: 10)
        ]

        sut.outcomes = TrainingOutcomeData(
            volumeProgression: nil,
            strengthGains: gains,
            painTrend: nil,
            adherence: nil,
            recoveryCorrelation: nil
        )

        let sorted = sut.sortedStrengthGains

        XCTAssertEqual(sorted.count, 1)
        XCTAssertEqual(sorted[0].exerciseName, "Squat")
        XCTAssertEqual(sorted[0].pctChange, 30.0)
    }

    // MARK: - volumeProgression Tests

    func testVolumeProgression_WhenOutcomesIsNil_ReturnsEmpty() {
        sut.outcomes = nil
        XCTAssertTrue(sut.volumeProgression.isEmpty,
                      "volumeProgression should be empty when outcomes is nil")
    }

    func testVolumeProgression_WhenVolumeIsNil_ReturnsEmpty() {
        sut.outcomes = TrainingOutcomeData(
            volumeProgression: nil,
            strengthGains: nil,
            painTrend: nil,
            adherence: nil,
            recoveryCorrelation: nil
        )
        XCTAssertTrue(sut.volumeProgression.isEmpty,
                      "volumeProgression should be empty when volumeProgression data is nil")
    }

    func testVolumeProgression_ReturnsDataWhenPresent() {
        let volumes = [
            WeeklyVolume(weekStart: "2026-01-06", totalVolume: 12000, logCount: 5),
            WeeklyVolume(weekStart: "2026-01-13", totalVolume: 14500, logCount: 6),
            WeeklyVolume(weekStart: "2026-01-20", totalVolume: 13200, logCount: 4)
        ]

        sut.outcomes = TrainingOutcomeData(
            volumeProgression: volumes,
            strengthGains: nil,
            painTrend: nil,
            adherence: nil,
            recoveryCorrelation: nil
        )

        XCTAssertEqual(sut.volumeProgression.count, 3, "Should return 3 volume entries")
        XCTAssertEqual(sut.volumeProgression[0].totalVolume, 12000)
        XCTAssertEqual(sut.volumeProgression[1].weekStart, "2026-01-13")
        XCTAssertEqual(sut.volumeProgression[2].logCount, 4)
    }

    // MARK: - painTrend Tests

    func testPainTrend_WhenOutcomesIsNil_ReturnsEmpty() {
        sut.outcomes = nil
        XCTAssertTrue(sut.painTrend.isEmpty,
                      "painTrend should be empty when outcomes is nil")
    }

    func testPainTrend_WhenPainTrendIsNil_ReturnsEmpty() {
        sut.outcomes = TrainingOutcomeData(
            volumeProgression: nil,
            strengthGains: nil,
            painTrend: nil,
            adherence: nil,
            recoveryCorrelation: nil
        )
        XCTAssertTrue(sut.painTrend.isEmpty,
                      "painTrend should be empty when painTrend data is nil")
    }

    func testPainTrend_ReturnsDataWhenPresent() {
        let pains = [
            WeeklyPain(weekStart: "2026-01-06", avgPain: 4.2, sampleCount: 3),
            WeeklyPain(weekStart: "2026-01-13", avgPain: 3.5, sampleCount: 4),
            WeeklyPain(weekStart: "2026-01-20", avgPain: 2.8, sampleCount: 5)
        ]

        sut.outcomes = TrainingOutcomeData(
            volumeProgression: nil,
            strengthGains: nil,
            painTrend: pains,
            adherence: nil,
            recoveryCorrelation: nil
        )

        XCTAssertEqual(sut.painTrend.count, 3, "Should return 3 pain entries")
        XCTAssertEqual(sut.painTrend[0].avgPain, 4.2)
        XCTAssertEqual(sut.painTrend[2].sampleCount, 5)
    }

    // MARK: - adherenceData Tests

    func testAdherenceData_WhenOutcomesIsNil_ReturnsEmpty() {
        sut.outcomes = nil
        XCTAssertTrue(sut.adherenceData.isEmpty,
                      "adherenceData should be empty when outcomes is nil")
    }

    func testAdherenceData_WhenAdherenceIsNil_ReturnsEmpty() {
        sut.outcomes = TrainingOutcomeData(
            volumeProgression: nil,
            strengthGains: nil,
            painTrend: nil,
            adherence: nil,
            recoveryCorrelation: nil
        )
        XCTAssertTrue(sut.adherenceData.isEmpty,
                      "adherenceData should be empty when adherence data is nil")
    }

    func testAdherenceData_ReturnsDataWhenPresent() {
        let adherence = [
            EFWeeklyAdherence(weekStart: "2026-01-06", sessionsCompleted: 4, sessionsScheduled: 5, adherencePct: 80.0),
            EFWeeklyAdherence(weekStart: "2026-01-13", sessionsCompleted: 5, sessionsScheduled: 5, adherencePct: 100.0),
            EFWeeklyAdherence(weekStart: "2026-01-20", sessionsCompleted: 3, sessionsScheduled: 5, adherencePct: 60.0)
        ]

        sut.outcomes = TrainingOutcomeData(
            volumeProgression: nil,
            strengthGains: nil,
            painTrend: nil,
            adherence: adherence,
            recoveryCorrelation: nil
        )

        XCTAssertEqual(sut.adherenceData.count, 3, "Should return 3 adherence entries")
        XCTAssertEqual(sut.adherenceData[0].adherencePct, 80.0)
        XCTAssertEqual(sut.adherenceData[1].sessionsCompleted, 5)
        XCTAssertEqual(sut.adherenceData[2].sessionsScheduled, 5)
    }

    // MARK: - All Computed Properties Return Empty When Outcomes Nil

    func testAllComputedProperties_ReturnEmptyWhenOutcomesIsNil() {
        sut.outcomes = nil

        XCTAssertTrue(sut.sortedStrengthGains.isEmpty, "sortedStrengthGains should be empty")
        XCTAssertTrue(sut.volumeProgression.isEmpty, "volumeProgression should be empty")
        XCTAssertTrue(sut.painTrend.isEmpty, "painTrend should be empty")
        XCTAssertTrue(sut.adherenceData.isEmpty, "adherenceData should be empty")
    }

    // MARK: - Summary Properties Tests

    func testSummary_CanBeSetWithAllFields() {
        let mockSummary = TrainingOutcomeSummary(
            totalExercisesTracked: 12,
            exercisesWithGains: 9,
            avgStrengthGainPct: 18.5,
            bestStrengthGain: StrengthGain(
                exerciseName: "Deadlift",
                startLoad: 150,
                currentLoad: 225,
                pctChange: 50.0,
                dataPoints: 8
            ),
            volumeTrend: "increasing",
            painTrend: "decreasing",
            overallAdherencePct: 85.0,
            weeksOfData: 8
        )

        sut.summary = mockSummary

        XCTAssertNotNil(sut.summary)
        XCTAssertEqual(sut.summary?.totalExercisesTracked, 12)
        XCTAssertEqual(sut.summary?.exercisesWithGains, 9)
        XCTAssertEqual(sut.summary?.avgStrengthGainPct ?? 0, 18.5, accuracy: 0.01)
        XCTAssertEqual(sut.summary?.bestStrengthGain?.exerciseName, "Deadlift")
        XCTAssertEqual(sut.summary?.volumeTrend, "increasing")
        XCTAssertEqual(sut.summary?.painTrend, "decreasing")
        XCTAssertEqual(sut.summary?.overallAdherencePct, 85.0)
        XCTAssertEqual(sut.summary?.weeksOfData, 8)
    }

    // MARK: - Outcomes With Full Data Tests

    func testOutcomes_AllDataPopulated() {
        let outcomes = TrainingOutcomeData(
            volumeProgression: [
                WeeklyVolume(weekStart: "2026-01-06", totalVolume: 12000, logCount: 5)
            ],
            strengthGains: [
                StrengthGain(exerciseName: "Squat", startLoad: 100, currentLoad: 130, pctChange: 30.0, dataPoints: 10)
            ],
            painTrend: [
                WeeklyPain(weekStart: "2026-01-06", avgPain: 3.0, sampleCount: 4)
            ],
            adherence: [
                EFWeeklyAdherence(weekStart: "2026-01-06", sessionsCompleted: 4, sessionsScheduled: 5, adherencePct: 80.0)
            ],
            recoveryCorrelation: nil
        )

        sut.outcomes = outcomes

        XCTAssertEqual(sut.volumeProgression.count, 1)
        XCTAssertEqual(sut.sortedStrengthGains.count, 1)
        XCTAssertEqual(sut.painTrend.count, 1)
        XCTAssertEqual(sut.adherenceData.count, 1)
    }
}
