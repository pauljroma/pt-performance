//
//  StrengthModeDashboardViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for StrengthModeDashboardViewModel
//  Tests initial state, computed properties, helper methods, SBD total calculation,
//  formatting, filtering (core vs accessory), streak logic, and edge cases.
//

import XCTest
@testable import PTPerformance

@MainActor
final class StrengthModeDashboardViewModelTests: XCTestCase {

    var sut: StrengthModeDashboardViewModel!

    override func setUp() async throws {
        try await super.setUp()
        sut = StrengthModeDashboardViewModel()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_BigLiftsIsEmpty() {
        XCTAssertTrue(sut.bigLifts.isEmpty, "bigLifts should be empty initially")
    }

    func testInitialState_RecentPRsIsEmpty() {
        XCTAssertTrue(sut.recentPRs.isEmpty, "recentPRs should be empty initially")
    }

    func testInitialState_WeeklyVolumeIsEmpty() {
        XCTAssertEqual(sut.weeklyVolume.totalVolume, 0, "weeklyVolume totalVolume should be 0 initially")
        XCTAssertEqual(sut.weeklyVolume.sessionCount, 0, "weeklyVolume sessionCount should be 0 initially")
        XCTAssertEqual(sut.weeklyVolume.averageVolumePerSession, 0, "weeklyVolume average should be 0 initially")
    }

    func testInitialState_CurrentStreakIsZero() {
        XCTAssertEqual(sut.currentStreak, 0, "currentStreak should be 0 initially")
    }

    func testInitialState_ProgressionSuggestionsIsEmpty() {
        XCTAssertTrue(sut.progressionSuggestions.isEmpty, "progressionSuggestions should be empty initially")
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading, "isLoading should be false initially")
    }

    func testInitialState_ErrorMessageIsNil() {
        XCTAssertNil(sut.errorMessage, "errorMessage should be nil initially")
    }

    func testInitialState_ShowErrorIsFalse() {
        XCTAssertFalse(sut.showError, "showError should be false initially")
    }

    func testInitialState_HasActivityTodayIsFalse() {
        XCTAssertFalse(sut.hasActivityToday, "hasActivityToday should be false initially")
    }

    // MARK: - isEmpty Computed Property

    func testIsEmpty_WhenBigLiftsEmptyAndNotLoading() {
        sut.bigLifts = []
        sut.isLoading = false
        XCTAssertTrue(sut.isEmpty, "isEmpty should be true when bigLifts is empty and not loading")
    }

    func testIsEmpty_WhenBigLiftsEmptyAndIsLoading() {
        sut.bigLifts = []
        sut.isLoading = true
        XCTAssertFalse(sut.isEmpty, "isEmpty should be false when loading (even if bigLifts empty)")
    }

    func testIsEmpty_WhenBigLiftsHasData() {
        sut.bigLifts = [createMockBigLift(name: "Bench Press")]
        sut.isLoading = false
        XCTAssertFalse(sut.isEmpty, "isEmpty should be false when bigLifts has data")
    }

    // MARK: - totalPRCount Computed Property

    func testTotalPRCount_WhenEmpty() {
        sut.bigLifts = []
        XCTAssertEqual(sut.totalPRCount, 0, "totalPRCount should be 0 when bigLifts is empty")
    }

    func testTotalPRCount_WithSingleLift() {
        sut.bigLifts = [createMockBigLift(name: "Bench Press", prCount: 5)]
        XCTAssertEqual(sut.totalPRCount, 5, "totalPRCount should sum PRs from all lifts")
    }

    func testTotalPRCount_WithMultipleLifts() {
        sut.bigLifts = [
            createMockBigLift(name: "Bench Press", prCount: 3),
            createMockBigLift(name: "Squat", prCount: 5),
            createMockBigLift(name: "Deadlift", prCount: 4)
        ]
        XCTAssertEqual(sut.totalPRCount, 12, "totalPRCount should sum all PR counts")
    }

    func testTotalPRCount_WithZeroPRs() {
        sut.bigLifts = [
            createMockBigLift(name: "Bench Press", prCount: 0),
            createMockBigLift(name: "Squat", prCount: 0)
        ]
        XCTAssertEqual(sut.totalPRCount, 0, "totalPRCount should be 0 when all lifts have 0 PRs")
    }

    // MARK: - improvingLiftsCount Computed Property

    func testImprovingLiftsCount_WhenEmpty() {
        sut.bigLifts = []
        XCTAssertEqual(sut.improvingLiftsCount, 0, "improvingLiftsCount should be 0 when empty")
    }

    func testImprovingLiftsCount_AllImproving() {
        sut.bigLifts = [
            createMockBigLift(name: "Bench Press", improvementPct30d: 5.0),
            createMockBigLift(name: "Squat", improvementPct30d: 3.0),
            createMockBigLift(name: "Deadlift", improvementPct30d: 1.0)
        ]
        XCTAssertEqual(sut.improvingLiftsCount, 3, "All lifts should be counted as improving")
    }

    func testImprovingLiftsCount_SomeImproving() {
        sut.bigLifts = [
            createMockBigLift(name: "Bench Press", improvementPct30d: 5.0),
            createMockBigLift(name: "Squat", improvementPct30d: -2.0),
            createMockBigLift(name: "Deadlift", improvementPct30d: nil)
        ]
        XCTAssertEqual(sut.improvingLiftsCount, 1, "Only lifts with positive improvement should count")
    }

    func testImprovingLiftsCount_NoneImproving() {
        sut.bigLifts = [
            createMockBigLift(name: "Bench Press", improvementPct30d: -2.0),
            createMockBigLift(name: "Squat", improvementPct30d: 0),
            createMockBigLift(name: "Deadlift", improvementPct30d: nil)
        ]
        XCTAssertEqual(sut.improvingLiftsCount, 0, "Zero or negative improvement should not count")
    }

    // MARK: - SBD Total Calculation

    func testSBDTotal_WhenEmpty() {
        sut.bigLifts = []
        XCTAssertEqual(sut.sbdTotal, 0, "SBD total should be 0 when no lifts")
    }

    func testSBDTotal_WithAllCoreLifts() {
        sut.bigLifts = [
            createMockBigLift(name: "Squat", estimated1rm: 400),
            createMockBigLift(name: "Bench Press", estimated1rm: 300),
            createMockBigLift(name: "Deadlift", estimated1rm: 500)
        ]
        XCTAssertEqual(sut.sbdTotal, 1200, "SBD total should sum estimated 1RMs for core lifts")
    }

    func testSBDTotal_IgnoresAccessoryLifts() {
        sut.bigLifts = [
            createMockBigLift(name: "Squat", estimated1rm: 400),
            createMockBigLift(name: "Bench Press", estimated1rm: 300),
            createMockBigLift(name: "Deadlift", estimated1rm: 500),
            createMockBigLift(name: "Overhead Press", estimated1rm: 150),
            createMockBigLift(name: "Barbell Row", estimated1rm: 200)
        ]
        XCTAssertEqual(sut.sbdTotal, 1200, "SBD total should exclude accessory lifts")
    }

    func testSBDTotal_WithOnlyAccessoryLifts() {
        sut.bigLifts = [
            createMockBigLift(name: "Overhead Press", estimated1rm: 150),
            createMockBigLift(name: "Barbell Row", estimated1rm: 200)
        ]
        XCTAssertEqual(sut.sbdTotal, 0, "SBD total should be 0 when only accessory lifts")
    }

    func testSBDTotal_WithPartialCoreLifts() {
        sut.bigLifts = [
            createMockBigLift(name: "Bench Press", estimated1rm: 300),
            createMockBigLift(name: "Deadlift", estimated1rm: 500)
        ]
        XCTAssertEqual(sut.sbdTotal, 800, "SBD total should work with partial core lifts")
    }

    // MARK: - formattedSBDTotal

    func testFormattedSBDTotal_WhenZero() {
        sut.bigLifts = []
        XCTAssertEqual(sut.formattedSBDTotal, "0 lbs")
    }

    func testFormattedSBDTotal_WithValue() {
        sut.bigLifts = [
            createMockBigLift(name: "Squat", estimated1rm: 345),
            createMockBigLift(name: "Bench Press", estimated1rm: 245),
            createMockBigLift(name: "Deadlift", estimated1rm: 445)
        ]
        XCTAssertEqual(sut.formattedSBDTotal, "1035 lbs")
    }

    // MARK: - coreLifts Computed Property

    func testCoreLifts_FiltersCorrectly() {
        sut.bigLifts = [
            createMockBigLift(name: "Squat"),
            createMockBigLift(name: "Bench Press"),
            createMockBigLift(name: "Deadlift"),
            createMockBigLift(name: "Overhead Press"),
            createMockBigLift(name: "Barbell Row")
        ]
        let coreNames = sut.coreLifts.map { $0.exerciseName }
        XCTAssertEqual(coreNames.count, 3, "Should have 3 core lifts")
        XCTAssertTrue(coreNames.contains("Squat"))
        XCTAssertTrue(coreNames.contains("Bench Press"))
        XCTAssertTrue(coreNames.contains("Deadlift"))
    }

    func testCoreLifts_EmptyWhenNoLifts() {
        sut.bigLifts = []
        XCTAssertTrue(sut.coreLifts.isEmpty)
    }

    // MARK: - accessoryLifts Computed Property

    func testAccessoryLifts_FiltersCorrectly() {
        sut.bigLifts = [
            createMockBigLift(name: "Squat"),
            createMockBigLift(name: "Bench Press"),
            createMockBigLift(name: "Deadlift"),
            createMockBigLift(name: "Overhead Press"),
            createMockBigLift(name: "Barbell Row")
        ]
        let accessoryNames = sut.accessoryLifts.map { $0.exerciseName }
        XCTAssertEqual(accessoryNames.count, 2, "Should have 2 accessory lifts")
        XCTAssertTrue(accessoryNames.contains("Overhead Press"))
        XCTAssertTrue(accessoryNames.contains("Barbell Row"))
    }

    func testAccessoryLifts_EmptyWhenOnlyCoreLifts() {
        sut.bigLifts = [
            createMockBigLift(name: "Squat"),
            createMockBigLift(name: "Bench Press"),
            createMockBigLift(name: "Deadlift")
        ]
        XCTAssertTrue(sut.accessoryLifts.isEmpty)
    }

    // MARK: - hasSuggestions Computed Property

    func testHasSuggestions_WhenEmpty() {
        sut.progressionSuggestions = []
        XCTAssertFalse(sut.hasSuggestions, "hasSuggestions should be false when empty")
    }

    func testHasSuggestions_WhenNotEmpty() {
        sut.progressionSuggestions = [createMockSuggestion()]
        XCTAssertTrue(sut.hasSuggestions, "hasSuggestions should be true when suggestions exist")
    }

    // MARK: - isStreakAtRisk Computed Property

    func testIsStreakAtRisk_WhenStreakZero() {
        // hasActivityToday defaults to false
        sut.currentStreak = 0
        XCTAssertFalse(sut.isStreakAtRisk, "Streak of 0 is not at risk")
    }

    func testIsStreakAtRisk_WhenStreakActiveAndNoActivityToday() {
        // hasActivityToday defaults to false
        sut.currentStreak = 5
        XCTAssertTrue(sut.isStreakAtRisk, "Active streak without today's activity should be at risk")
    }

    func testIsStreakAtRisk_WhenStreakOneAndNoActivity() {
        // hasActivityToday defaults to false
        sut.currentStreak = 1
        XCTAssertTrue(sut.isStreakAtRisk, "Streak of 1 without activity should be at risk")
    }

    func testIsStreakAtRisk_DependsOnHasActivityToday() {
        // By default, hasActivityToday is false and streak > 0 means at risk
        sut.currentStreak = 3
        XCTAssertFalse(sut.hasActivityToday, "hasActivityToday should default to false")
        XCTAssertTrue(sut.isStreakAtRisk, "Should be at risk when hasActivityToday is false and streak > 0")
    }

    // MARK: - clearError Method

    func testClearError_ResetsErrorState() {
        sut.errorMessage = "Some error occurred"
        sut.showError = true

        sut.clearError()

        XCTAssertNil(sut.errorMessage, "errorMessage should be nil after clearError")
        XCTAssertFalse(sut.showError, "showError should be false after clearError")
    }

    func testClearError_WhenNoError() {
        sut.clearError()

        XCTAssertNil(sut.errorMessage, "errorMessage should remain nil")
        XCTAssertFalse(sut.showError, "showError should remain false")
    }

    // MARK: - isCoreLift Helper Method

    func testIsCoreLift_Squat() {
        XCTAssertTrue(sut.isCoreLift("Squat"), "Squat should be a core lift")
    }

    func testIsCoreLift_BenchPress() {
        XCTAssertTrue(sut.isCoreLift("Bench Press"), "Bench Press should be a core lift")
    }

    func testIsCoreLift_Deadlift() {
        XCTAssertTrue(sut.isCoreLift("Deadlift"), "Deadlift should be a core lift")
    }

    func testIsCoreLift_OverheadPress() {
        XCTAssertFalse(sut.isCoreLift("Overhead Press"), "Overhead Press should not be a core lift")
    }

    func testIsCoreLift_BarbellRow() {
        XCTAssertFalse(sut.isCoreLift("Barbell Row"), "Barbell Row should not be a core lift")
    }

    func testIsCoreLift_UnknownExercise() {
        XCTAssertFalse(sut.isCoreLift("Bicep Curl"), "Unknown exercise should not be a core lift")
    }

    func testIsCoreLift_EmptyString() {
        XCTAssertFalse(sut.isCoreLift(""), "Empty string should not be a core lift")
    }

    // MARK: - iconName Helper Method

    func testIconName_BenchPress() {
        XCTAssertEqual(sut.iconName(for: "Bench Press"), "figure.strengthtraining.traditional")
    }

    func testIconName_Squat() {
        XCTAssertEqual(sut.iconName(for: "Squat"), "figure.strengthtraining.functional")
    }

    func testIconName_Deadlift() {
        XCTAssertEqual(sut.iconName(for: "Deadlift"), "figure.cross.training")
    }

    func testIconName_OverheadPress() {
        XCTAssertEqual(sut.iconName(for: "Overhead Press"), "figure.arms.open")
    }

    func testIconName_BarbellRow() {
        XCTAssertEqual(sut.iconName(for: "Barbell Row"), "figure.rowing")
    }

    func testIconName_UnknownExercise() {
        XCTAssertEqual(sut.iconName(for: "Bicep Curl"), "dumbbell.fill", "Unknown exercise should use default icon")
    }

    func testIconName_EmptyString() {
        XCTAssertEqual(sut.iconName(for: ""), "dumbbell.fill", "Empty string should use default icon")
    }

    // MARK: - suggestion(for:) Helper Method

    func testSuggestion_ForExistingExercise() {
        let suggestion = createMockSuggestion()
        sut.bigLifts = [
            createMockBigLift(name: "Bench Press"),
            createMockBigLift(name: "Squat"),
            createMockBigLift(name: "Deadlift")
        ]
        sut.progressionSuggestions = [suggestion]

        let result = sut.suggestion(for: "Bench Press")
        XCTAssertNotNil(result, "Should return suggestion for first big lift")
    }

    func testSuggestion_ForSecondExercise() {
        let suggestion1 = createMockSuggestion()
        let suggestion2 = createMockSuggestion()
        sut.bigLifts = [
            createMockBigLift(name: "Bench Press"),
            createMockBigLift(name: "Squat"),
            createMockBigLift(name: "Deadlift")
        ]
        sut.progressionSuggestions = [suggestion1, suggestion2]

        let result = sut.suggestion(for: "Squat")
        XCTAssertNotNil(result, "Should return suggestion for second big lift")
    }

    func testSuggestion_ForExerciseNotInBigLifts() {
        sut.bigLifts = [
            createMockBigLift(name: "Bench Press")
        ]
        sut.progressionSuggestions = [createMockSuggestion()]

        let result = sut.suggestion(for: "Bicep Curl")
        XCTAssertNil(result, "Should return nil for exercise not in bigLifts")
    }

    func testSuggestion_WhenNoSuggestions() {
        sut.bigLifts = [createMockBigLift(name: "Bench Press")]
        sut.progressionSuggestions = []

        let result = sut.suggestion(for: "Bench Press")
        XCTAssertNil(result, "Should return nil when no suggestions exist")
    }

    func testSuggestion_ForExerciseBeyondPrefix3() {
        sut.bigLifts = [
            createMockBigLift(name: "Bench Press"),
            createMockBigLift(name: "Squat"),
            createMockBigLift(name: "Deadlift"),
            createMockBigLift(name: "Overhead Press")
        ]
        sut.progressionSuggestions = [
            createMockSuggestion(),
            createMockSuggestion(),
            createMockSuggestion()
        ]

        let result = sut.suggestion(for: "Overhead Press")
        XCTAssertNil(result, "Should return nil for exercise beyond prefix(3)")
    }

    // MARK: - WeeklyVolumeData Tests

    func testWeeklyVolumeData_FormattedTotal_UnderThousand() {
        let data = WeeklyVolumeData(
            weekStart: Date(),
            totalVolume: 500,
            sessionCount: 2,
            averageVolumePerSession: 250
        )
        XCTAssertEqual(data.formattedTotal, "500 lbs")
    }

    func testWeeklyVolumeData_FormattedTotal_AtThousand() {
        let data = WeeklyVolumeData(
            weekStart: Date(),
            totalVolume: 1000,
            sessionCount: 2,
            averageVolumePerSession: 500
        )
        XCTAssertEqual(data.formattedTotal, "1.0K lbs")
    }

    func testWeeklyVolumeData_FormattedTotal_OverThousand() {
        let data = WeeklyVolumeData(
            weekStart: Date(),
            totalVolume: 45000,
            sessionCount: 4,
            averageVolumePerSession: 11250
        )
        XCTAssertEqual(data.formattedTotal, "45.0K lbs")
    }

    func testWeeklyVolumeData_FormattedTotal_Zero() {
        let data = WeeklyVolumeData(
            weekStart: Date(),
            totalVolume: 0,
            sessionCount: 0,
            averageVolumePerSession: 0
        )
        XCTAssertEqual(data.formattedTotal, "0 lbs")
    }

    func testWeeklyVolumeData_FormattedAverage() {
        let data = WeeklyVolumeData(
            weekStart: Date(),
            totalVolume: 45000,
            sessionCount: 4,
            averageVolumePerSession: 11250
        )
        XCTAssertEqual(data.formattedAverage, "11250 lbs/session")
    }

    func testWeeklyVolumeData_FormattedAverage_Zero() {
        let data = WeeklyVolumeData(
            weekStart: Date(),
            totalVolume: 0,
            sessionCount: 0,
            averageVolumePerSession: 0
        )
        XCTAssertEqual(data.formattedAverage, "0 lbs/session")
    }

    func testWeeklyVolumeData_Empty() {
        let data = WeeklyVolumeData.empty
        XCTAssertEqual(data.totalVolume, 0)
        XCTAssertEqual(data.sessionCount, 0)
        XCTAssertEqual(data.averageVolumePerSession, 0)
    }

    func testWeeklyVolumeData_Equatable() {
        let date = Date()
        let data1 = WeeklyVolumeData(weekStart: date, totalVolume: 1000, sessionCount: 2, averageVolumePerSession: 500)
        let data2 = WeeklyVolumeData(weekStart: date, totalVolume: 1000, sessionCount: 2, averageVolumePerSession: 500)
        XCTAssertEqual(data1, data2)
    }

    // MARK: - State Mutation Tests

    func testErrorMessage_CanBeSetAndCleared() {
        XCTAssertNil(sut.errorMessage)

        sut.errorMessage = "Error occurred"
        XCTAssertEqual(sut.errorMessage, "Error occurred")

        sut.errorMessage = nil
        XCTAssertNil(sut.errorMessage)
    }

    func testShowError_CanBeToggled() {
        XCTAssertFalse(sut.showError)

        sut.showError = true
        XCTAssertTrue(sut.showError)

        sut.showError = false
        XCTAssertFalse(sut.showError)
    }

    func testCurrentStreak_CanBeSet() {
        sut.currentStreak = 42
        XCTAssertEqual(sut.currentStreak, 42)
    }

    func testBigLifts_CanBeSetAndCleared() {
        let lift = createMockBigLift(name: "Bench Press")
        sut.bigLifts = [lift]
        XCTAssertEqual(sut.bigLifts.count, 1)

        sut.bigLifts = []
        XCTAssertTrue(sut.bigLifts.isEmpty)
    }

    // MARK: - BigLift Enum Tests

    func testBigLift_AllCases() {
        let allCases = BigLift.allCases
        XCTAssertEqual(allCases.count, 5, "BigLift should have 5 cases")
    }

    func testBigLift_RawValues() {
        XCTAssertEqual(BigLift.benchPress.rawValue, "Bench Press")
        XCTAssertEqual(BigLift.squat.rawValue, "Squat")
        XCTAssertEqual(BigLift.deadlift.rawValue, "Deadlift")
        XCTAssertEqual(BigLift.overheadPress.rawValue, "Overhead Press")
        XCTAssertEqual(BigLift.barbellRow.rawValue, "Barbell Row")
    }

    func testBigLift_IsCoreLift() {
        XCTAssertTrue(BigLift.benchPress.isCoreLift)
        XCTAssertTrue(BigLift.squat.isCoreLift)
        XCTAssertTrue(BigLift.deadlift.isCoreLift)
        XCTAssertFalse(BigLift.overheadPress.isCoreLift)
        XCTAssertFalse(BigLift.barbellRow.isCoreLift)
    }

    func testBigLift_IconNames() {
        XCTAssertEqual(BigLift.benchPress.iconName, "figure.strengthtraining.traditional")
        XCTAssertEqual(BigLift.squat.iconName, "figure.strengthtraining.functional")
        XCTAssertEqual(BigLift.deadlift.iconName, "figure.cross.training")
        XCTAssertEqual(BigLift.overheadPress.iconName, "figure.arms.open")
        XCTAssertEqual(BigLift.barbellRow.iconName, "figure.rowing")
    }

    // MARK: - BigLiftSummary Computed Properties Tests

    func testBigLiftSummary_FormattedMaxWeight() {
        let lift = createMockBigLift(name: "Bench Press", currentMaxWeight: 225)
        XCTAssertEqual(lift.formattedMaxWeight, "225 lbs")
    }

    func testBigLiftSummary_FormattedEstimated1rm() {
        let lift = createMockBigLift(name: "Bench Press", estimated1rm: 245)
        XCTAssertEqual(lift.formattedEstimated1rm, "245 lbs")
    }

    func testBigLiftSummary_FormattedImprovement_Positive() {
        let lift = createMockBigLift(name: "Bench Press", improvementPct30d: 8.5)
        XCTAssertEqual(lift.formattedImprovement, "+8.5%")
    }

    func testBigLiftSummary_FormattedImprovement_Negative() {
        let lift = createMockBigLift(name: "Bench Press", improvementPct30d: -2.1)
        XCTAssertEqual(lift.formattedImprovement, "-2.1%")
    }

    func testBigLiftSummary_FormattedImprovement_Nil() {
        let lift = createMockBigLift(name: "Bench Press", improvementPct30d: nil)
        XCTAssertNil(lift.formattedImprovement)
    }

    func testBigLiftSummary_FormattedImprovement_Zero() {
        let lift = createMockBigLift(name: "Bench Press", improvementPct30d: 0)
        XCTAssertEqual(lift.formattedImprovement, "+0.0%")
    }

    func testBigLiftSummary_IsImproving_Positive() {
        let lift = createMockBigLift(name: "Bench Press", improvementPct30d: 5.0)
        XCTAssertTrue(lift.isImproving)
    }

    func testBigLiftSummary_IsImproving_Negative() {
        let lift = createMockBigLift(name: "Bench Press", improvementPct30d: -3.0)
        XCTAssertFalse(lift.isImproving)
    }

    func testBigLiftSummary_IsImproving_Nil() {
        let lift = createMockBigLift(name: "Bench Press", improvementPct30d: nil)
        XCTAssertFalse(lift.isImproving)
    }

    func testBigLiftSummary_IsImproving_Zero() {
        let lift = createMockBigLift(name: "Bench Press", improvementPct30d: 0)
        XCTAssertFalse(lift.isImproving)
    }

    func testBigLiftSummary_IsDeclining_Negative() {
        let lift = createMockBigLift(name: "Bench Press", improvementPct30d: -3.0)
        XCTAssertTrue(lift.isDeclining)
    }

    func testBigLiftSummary_IsDeclining_Positive() {
        let lift = createMockBigLift(name: "Bench Press", improvementPct30d: 5.0)
        XCTAssertFalse(lift.isDeclining)
    }

    func testBigLiftSummary_IsDeclining_Nil() {
        let lift = createMockBigLift(name: "Bench Press", improvementPct30d: nil)
        XCTAssertFalse(lift.isDeclining)
    }

    func testBigLiftSummary_Id_IsExerciseName() {
        let lift = createMockBigLift(name: "Squat")
        XCTAssertEqual(lift.id, "Squat")
    }

    // MARK: - calculateSBDTotal Method

    func testCalculateSBDTotal_DirectCall() {
        sut.bigLifts = [
            createMockBigLift(name: "Squat", estimated1rm: 400),
            createMockBigLift(name: "Bench Press", estimated1rm: 300),
            createMockBigLift(name: "Deadlift", estimated1rm: 500)
        ]
        XCTAssertEqual(sut.calculateSBDTotal(), 1200)
    }

    func testCalculateSBDTotal_MatchesSBDTotalProperty() {
        sut.bigLifts = [
            createMockBigLift(name: "Squat", estimated1rm: 350),
            createMockBigLift(name: "Bench Press", estimated1rm: 225),
            createMockBigLift(name: "Deadlift", estimated1rm: 450)
        ]
        XCTAssertEqual(sut.calculateSBDTotal(), sut.sbdTotal,
                        "calculateSBDTotal() should match sbdTotal computed property")
    }

    // MARK: - Edge Cases

    func testMultipleSameNameLifts() {
        sut.bigLifts = [
            createMockBigLift(name: "Squat", estimated1rm: 300),
            createMockBigLift(name: "Squat", estimated1rm: 350)
        ]
        XCTAssertEqual(sut.sbdTotal, 650, "Should include both lifts with same name")
    }

    func testWeeklyVolumeData_FormattedTotal_FractionalKiloPounds() {
        let data = WeeklyVolumeData(
            weekStart: Date(),
            totalVolume: 1500,
            sessionCount: 3,
            averageVolumePerSession: 500
        )
        XCTAssertEqual(data.formattedTotal, "1.5K lbs")
    }

    func testWeeklyVolumeData_FormattedTotal_LargeValue() {
        let data = WeeklyVolumeData(
            weekStart: Date(),
            totalVolume: 123456,
            sessionCount: 10,
            averageVolumePerSession: 12345.6
        )
        XCTAssertEqual(data.formattedTotal, "123.5K lbs")
    }

    // MARK: - Helper Methods

    private func createMockBigLift(
        name: String,
        currentMaxWeight: Double = 225.0,
        estimated1rm: Double = 245.0,
        lastPrDate: Date? = nil,
        prCount: Int = 0,
        lastPerformed: Date? = nil,
        improvementPct30d: Double? = nil,
        totalVolume: Double = 10000.0
    ) -> BigLiftSummary {
        BigLiftSummary(
            exerciseName: name,
            currentMaxWeight: currentMaxWeight,
            estimated1rm: estimated1rm,
            lastPrDate: lastPrDate,
            prCount: prCount,
            lastPerformed: lastPerformed,
            improvementPct30d: improvementPct30d,
            totalVolume: totalVolume,
            loadUnit: "lbs"
        )
    }

    private func createMockSuggestion() -> ProgressionSuggestion {
        ProgressionSuggestion(
            nextLoad: 230.0,
            nextReps: 5,
            confidence: 85.0,
            reasoning: "Steady progression observed",
            progressionType: .increase
        )
    }
}
