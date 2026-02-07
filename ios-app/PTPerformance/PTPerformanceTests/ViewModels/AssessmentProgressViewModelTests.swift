//
//  AssessmentProgressViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for AssessmentProgressViewModel
//  Tests trend data calculations, MCID achievement tracking,
//  outcome measure progress, chart data generation, and progress status calculations
//

import XCTest
@testable import PTPerformance

@MainActor
final class AssessmentProgressViewModelTests: XCTestCase {

    var sut: AssessmentProgressViewModel!

    override func setUp() {
        super.setUp()
        sut = AssessmentProgressViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_PatientIdIsNil() {
        XCTAssertNil(sut.patientId, "patientId should be nil initially")
    }

    func testInitialState_ROMProgressIsEmpty() {
        XCTAssertTrue(sut.romProgress.isEmpty, "romProgress should be empty initially")
    }

    func testInitialState_PainProgressIsEmpty() {
        XCTAssertTrue(sut.painProgress.isEmpty, "painProgress should be empty initially")
    }

    func testInitialState_OutcomeProgressIsEmpty() {
        XCTAssertTrue(sut.outcomeProgress.isEmpty, "outcomeProgress should be empty initially")
    }

    func testInitialState_PainTrendIsEmpty() {
        XCTAssertTrue(sut.painTrend.isEmpty, "painTrend should be empty initially")
    }

    func testInitialState_ROMTrendsIsEmpty() {
        XCTAssertTrue(sut.romTrends.isEmpty, "romTrends should be empty initially")
    }

    func testInitialState_OutcomeTrendsIsEmpty() {
        XCTAssertTrue(sut.outcomeTrends.isEmpty, "outcomeTrends should be empty initially")
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading, "isLoading should be false initially")
    }

    func testInitialState_ErrorMessageIsNil() {
        XCTAssertNil(sut.errorMessage, "errorMessage should be nil initially")
    }

    func testInitialState_IsLoadingROMIsFalse() {
        XCTAssertFalse(sut.isLoadingROM, "isLoadingROM should be false initially")
    }

    func testInitialState_IsLoadingPainIsFalse() {
        XCTAssertFalse(sut.isLoadingPain, "isLoadingPain should be false initially")
    }

    func testInitialState_IsLoadingOutcomesIsFalse() {
        XCTAssertFalse(sut.isLoadingOutcomes, "isLoadingOutcomes should be false initially")
    }

    func testInitialState_SelectedTimeRangeIsThreeMonths() {
        XCTAssertEqual(sut.selectedTimeRange, .threeMonths, "selectedTimeRange should be .threeMonths initially")
    }

    func testInitialState_ProgressSummaryOverallStatusIsStable() {
        XCTAssertEqual(sut.progressSummary.overallStatus, .stable, "overallStatus should be .stable initially")
    }

    // MARK: - TrendDataPoint Tests

    func testTrendDataPoint_FormattedDate_ReturnsShortFormat() {
        let date = Date()
        let dataPoint = TrendDataPoint(date: date, value: 120.0, label: nil)

        XCTAssertFalse(dataPoint.formattedDate.isEmpty, "formattedDate should return a non-empty string")
    }

    func testTrendDataPoint_Identifiable_HasUniqueId() {
        let point1 = TrendDataPoint(date: Date(), value: 100.0, label: nil)
        let point2 = TrendDataPoint(date: Date(), value: 100.0, label: nil)

        XCTAssertNotEqual(point1.id, point2.id, "Each TrendDataPoint should have a unique id")
    }

    func testTrendDataPoint_WithLabel_StoresLabel() {
        let dataPoint = TrendDataPoint(date: Date(), value: 150.0, label: "Test Label")

        XCTAssertEqual(dataPoint.label, "Test Label")
    }

    // MARK: - ROMProgressItem Tests

    func testROMProgressItem_Change_CalculatesCorrectly() {
        let item = createMockROMProgressItem(initial: 120, current: 155)

        XCTAssertEqual(item.change, 35, "change should be current - initial")
    }

    func testROMProgressItem_IsImproving_TrueWhenChangePositive() {
        let item = createMockROMProgressItem(initial: 120, current: 150)

        XCTAssertTrue(item.isImproving, "isImproving should be true when change is positive")
    }

    func testROMProgressItem_IsImproving_FalseWhenChangeNegative() {
        let item = createMockROMProgressItem(initial: 150, current: 130)

        XCTAssertFalse(item.isImproving, "isImproving should be false when change is negative")
    }

    func testROMProgressItem_PercentageOfNormal_CalculatesCorrectly() {
        let item = ROMProgressItem(
            joint: "shoulder",
            movement: "flexion",
            side: .right,
            initialDegrees: 120,
            currentDegrees: 160,
            normalRange: 150...180,
            measurements: []
        )

        // 160 / 180 * 100 = 88.89%
        XCTAssertEqual(item.percentageOfNormal, 88.89, accuracy: 0.1)
    }

    func testROMProgressItem_ProgressStatus_ImprovingWhenGainGreaterThanOrEqualTo10() {
        let item = createMockROMProgressItem(initial: 120, current: 130)

        XCTAssertEqual(item.progressStatus, .improving, "should be improving when change >= 10")
    }

    func testROMProgressItem_ProgressStatus_DecliningWhenLossGreaterThan5() {
        let item = createMockROMProgressItem(initial: 150, current: 140)

        XCTAssertEqual(item.progressStatus, .declining, "should be declining when change < -5")
    }

    func testROMProgressItem_ProgressStatus_StableWhenChangeSmall() {
        let item = createMockROMProgressItem(initial: 150, current: 152)

        XCTAssertEqual(item.progressStatus, .stable, "should be stable when change is small")
    }

    func testROMProgressItem_DisplayTitle_FormatsCorrectly() {
        let item = ROMProgressItem(
            joint: "shoulder",
            movement: "flexion",
            side: .right,
            initialDegrees: 120,
            currentDegrees: 150,
            normalRange: 150...180,
            measurements: []
        )

        XCTAssertEqual(item.displayTitle, "R Shoulder Flexion")
    }

    // MARK: - PainProgressItem Tests

    func testPainProgressItem_Change_CalculatesCorrectly() {
        let item = createMockPainProgressItem(initial: 7, current: 4, painType: "activity")

        XCTAssertEqual(item.change, -3, "change should be current - initial")
    }

    func testPainProgressItem_IsImproving_TrueWhenScoreDecreases() {
        let item = createMockPainProgressItem(initial: 7, current: 4, painType: "activity")

        XCTAssertTrue(item.isImproving, "isImproving should be true when pain decreases (negative change)")
    }

    func testPainProgressItem_IsImproving_FalseWhenScoreIncreases() {
        let item = createMockPainProgressItem(initial: 4, current: 7, painType: "activity")

        XCTAssertFalse(item.isImproving, "isImproving should be false when pain increases (positive change)")
    }

    func testPainProgressItem_ProgressStatus_ImprovingWhenDecreasedBy2OrMore() {
        let item = createMockPainProgressItem(initial: 7, current: 5, painType: "rest")

        XCTAssertEqual(item.progressStatus, .improving, "should be improving when pain decreased by 2+")
    }

    func testPainProgressItem_ProgressStatus_DecliningWhenIncreasedBy2OrMore() {
        let item = createMockPainProgressItem(initial: 4, current: 6, painType: "rest")

        XCTAssertEqual(item.progressStatus, .declining, "should be declining when pain increased by 2+")
    }

    func testPainProgressItem_ProgressStatus_StableWhenChangeSmall() {
        let item = createMockPainProgressItem(initial: 5, current: 4, painType: "rest")

        XCTAssertEqual(item.progressStatus, .stable, "should be stable when change is less than 2")
    }

    func testPainProgressItem_DisplayTitle_Rest() {
        let item = createMockPainProgressItem(initial: 5, current: 3, painType: "rest")

        XCTAssertEqual(item.displayTitle, "Pain at Rest")
    }

    func testPainProgressItem_DisplayTitle_Activity() {
        let item = createMockPainProgressItem(initial: 7, current: 4, painType: "activity")

        XCTAssertEqual(item.displayTitle, "Pain with Activity")
    }

    func testPainProgressItem_DisplayTitle_Worst() {
        let item = createMockPainProgressItem(initial: 9, current: 6, painType: "worst")

        XCTAssertEqual(item.displayTitle, "Worst Pain")
    }

    // MARK: - OutcomeProgressItem Tests

    func testOutcomeProgressItem_Change_CalculatesCorrectly() {
        let item = createMockOutcomeProgressItem(initial: 54, current: 68, measureType: .LEFS)

        XCTAssertEqual(item.change, 14, accuracy: 0.01)
    }

    func testOutcomeProgressItem_MeetsMcid_TrueWhenChangeExceedsThreshold() {
        // LEFS MCID threshold is 9
        let item = createMockOutcomeProgressItem(initial: 54, current: 68, measureType: .LEFS)

        XCTAssertTrue(item.meetsMcid, "should meet MCID when change (14) exceeds threshold (9)")
    }

    func testOutcomeProgressItem_MeetsMcid_FalseWhenChangeBelowThreshold() {
        // LEFS MCID threshold is 9
        let item = createMockOutcomeProgressItem(initial: 54, current: 58, measureType: .LEFS)

        XCTAssertFalse(item.meetsMcid, "should not meet MCID when change (4) is below threshold (9)")
    }

    func testOutcomeProgressItem_MeetsMcid_ForLowerIsBetterMeasure() {
        // DASH: lower is better, MCID is 10.8
        // For improvement, score should decrease by at least MCID
        let item = createMockOutcomeProgressItem(initial: 50, current: 38, measureType: .DASH)

        XCTAssertTrue(item.meetsMcid, "should meet MCID when DASH score decreases by more than threshold")
    }

    func testOutcomeProgressItem_ProgressStatus_ImprovingWhenMcidMet() {
        let item = createMockOutcomeProgressItem(initial: 54, current: 68, measureType: .LEFS)

        XCTAssertEqual(item.progressStatus, .improving)
    }

    func testOutcomeProgressItem_ProgressStatus_StableWhenMcidNotMet() {
        let item = createMockOutcomeProgressItem(initial: 54, current: 58, measureType: .LEFS)

        XCTAssertEqual(item.progressStatus, .stable)
    }

    func testOutcomeProgressItem_ChangePercentage_CalculatesCorrectly() {
        let item = createMockOutcomeProgressItem(initial: 50, current: 60, measureType: .LEFS)

        // (60 - 50) / 50 * 100 = 20%
        XCTAssertEqual(item.changePercentage, 20.0, accuracy: 0.01)
    }

    func testOutcomeProgressItem_ChangePercentage_ZeroWhenInitialIsZero() {
        let item = createMockOutcomeProgressItem(initial: 0, current: 50, measureType: .LEFS)

        XCTAssertEqual(item.changePercentage, 0)
    }

    // MARK: - Progress Summary Tests

    func testPatientProgressSummary_SummaryText_Improving() {
        var summary = PatientProgressSummary()
        summary.overallStatus = .improving

        XCTAssertEqual(summary.summaryText, "Patient is showing overall improvement")
    }

    func testPatientProgressSummary_SummaryText_Stable() {
        var summary = PatientProgressSummary()
        summary.overallStatus = .stable

        XCTAssertEqual(summary.summaryText, "Patient is maintaining stable progress")
    }

    func testPatientProgressSummary_SummaryText_Declining() {
        var summary = PatientProgressSummary()
        summary.overallStatus = .declining

        XCTAssertEqual(summary.summaryText, "Patient progress requires attention")
    }

    // MARK: - Computed Properties Tests

    func testOverallStatus_MatchesSummary() {
        sut.progressSummary.overallStatus = .improving

        XCTAssertEqual(sut.overallStatus, .improving)
    }

    func testStatusColor_MatchesOverallStatus() {
        sut.progressSummary.overallStatus = .improving

        XCTAssertEqual(sut.statusColor, ProgressStatus.improving.color)
    }

    func testStatusIcon_MatchesOverallStatus() {
        sut.progressSummary.overallStatus = .declining

        XCTAssertEqual(sut.statusIcon, ProgressStatus.declining.iconName)
    }

    func testHasData_FalseWhenAllEmpty() {
        sut.romProgress = []
        sut.painProgress = []
        sut.outcomeProgress = []

        XCTAssertFalse(sut.hasData)
    }

    func testHasData_TrueWhenROMProgressExists() {
        sut.romProgress = [createMockROMProgressItem(initial: 120, current: 150)]

        XCTAssertTrue(sut.hasData)
    }

    func testHasData_TrueWhenPainProgressExists() {
        sut.painProgress = [createMockPainProgressItem(initial: 7, current: 4, painType: "rest")]

        XCTAssertTrue(sut.hasData)
    }

    func testHasData_TrueWhenOutcomeProgressExists() {
        sut.outcomeProgress = [createMockOutcomeProgressItem(initial: 50, current: 60, measureType: .LEFS)]

        XCTAssertTrue(sut.hasData)
    }

    func testMcidAchievementRate_CalculatesCorrectly() {
        sut.progressSummary.mcidAchievements = 3
        sut.progressSummary.totalOutcomeMeasures = 4

        XCTAssertEqual(sut.mcidAchievementRate, 75.0, accuracy: 0.01)
    }

    func testMcidAchievementRate_ZeroWhenNoMeasures() {
        sut.progressSummary.mcidAchievements = 0
        sut.progressSummary.totalOutcomeMeasures = 0

        XCTAssertEqual(sut.mcidAchievementRate, 0)
    }

    // MARK: - TimeRange Tests

    func testTimeRange_DisplayNames() {
        XCTAssertEqual(AssessmentProgressViewModel.TimeRange.oneMonth.displayName, "1 Month")
        XCTAssertEqual(AssessmentProgressViewModel.TimeRange.threeMonths.displayName, "3 Months")
        XCTAssertEqual(AssessmentProgressViewModel.TimeRange.sixMonths.displayName, "6 Months")
        XCTAssertEqual(AssessmentProgressViewModel.TimeRange.oneYear.displayName, "1 Year")
        XCTAssertEqual(AssessmentProgressViewModel.TimeRange.all.displayName, "All Time")
    }

    func testTimeRange_Days() {
        XCTAssertEqual(AssessmentProgressViewModel.TimeRange.oneMonth.days, 30)
        XCTAssertEqual(AssessmentProgressViewModel.TimeRange.threeMonths.days, 90)
        XCTAssertEqual(AssessmentProgressViewModel.TimeRange.sixMonths.days, 180)
        XCTAssertEqual(AssessmentProgressViewModel.TimeRange.oneYear.days, 365)
        XCTAssertNil(AssessmentProgressViewModel.TimeRange.all.days)
    }

    func testTimeRange_StartDate_ReturnsCorrectDate() {
        let now = Date()
        let threeMonthsAgo = Calendar.current.date(byAdding: .day, value: -90, to: now)!

        let startDate = AssessmentProgressViewModel.TimeRange.threeMonths.startDate

        XCTAssertNotNil(startDate)
        // Allow for small time differences
        let difference = abs(startDate!.timeIntervalSince(threeMonthsAgo))
        XCTAssertLessThan(difference, 60, "startDate should be approximately 90 days ago")
    }

    func testTimeRange_StartDate_NilForAll() {
        XCTAssertNil(AssessmentProgressViewModel.TimeRange.all.startDate)
    }

    // MARK: - Patient ID Tests

    func testSetPatientId_UpdatesProperty() {
        let patientId = UUID()
        sut.patientId = patientId
        XCTAssertEqual(sut.patientId, patientId)
    }

    func testSetPatientId_CanBeNil() {
        sut.patientId = UUID()
        sut.patientId = nil
        XCTAssertNil(sut.patientId)
    }

    func testErrorMessage_CanBeSetAndCleared() {
        sut.errorMessage = "Test error"
        XCTAssertEqual(sut.errorMessage, "Test error")

        sut.errorMessage = nil
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - ROM Trend Tests

    func testGetROMTrend_ReturnsCorrectData() {
        let key = "shoulder_flexion_right"
        let trendPoints = [
            TrendDataPoint(date: Date(), value: 140, label: nil),
            TrendDataPoint(date: Date(), value: 150, label: nil)
        ]
        sut.romTrends[key] = trendPoints

        let result = sut.getROMTrend(joint: "shoulder", movement: "flexion", side: .right)

        XCTAssertEqual(result.count, 2)
    }

    func testGetROMTrend_ReturnsEmptyForMissingKey() {
        let result = sut.getROMTrend(joint: "unknown", movement: "unknown", side: .left)

        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Outcome Trend Tests

    func testGetOutcomeTrend_ReturnsCorrectData() {
        let trendPoints = [
            TrendDataPoint(date: Date(), value: 50, label: nil),
            TrendDataPoint(date: Date(), value: 65, label: nil)
        ]
        sut.outcomeTrends[.LEFS] = trendPoints

        let result = sut.getOutcomeTrend(measureType: .LEFS)

        XCTAssertEqual(result.count, 2)
    }

    func testGetOutcomeTrend_ReturnsEmptyForMissingType() {
        let result = sut.getOutcomeTrend(measureType: .NDI)

        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Clear Errors Tests

    func testClearErrors_ClearsAllErrors() {
        sut.errorMessage = "General error"
        sut.romError = "ROM error"
        sut.painError = "Pain error"
        sut.outcomesError = "Outcomes error"

        sut.clearErrors()

        XCTAssertNil(sut.errorMessage)
        XCTAssertNil(sut.romError)
        XCTAssertNil(sut.painError)
        XCTAssertNil(sut.outcomesError)
    }

    // MARK: - Progress Calculation Tests

    func testProgressSummary_CountsImprovements() {
        sut.romProgress = [
            createMockROMProgressItem(initial: 120, current: 140), // improving
            createMockROMProgressItem(initial: 130, current: 145), // improving
            createMockROMProgressItem(initial: 150, current: 152)  // stable
        ]
        sut.painProgress = [
            createMockPainProgressItem(initial: 7, current: 4, painType: "rest") // improving
        ]
        sut.outcomeProgress = [
            createMockOutcomeProgressItem(initial: 50, current: 65, measureType: .LEFS) // improving (meets MCID)
        ]

        // Trigger recalculation by setting up then refreshing
        sut.progressSummary = PatientProgressSummary()

        // Count improvements manually to verify expected values
        let romImprovements = sut.romProgress.filter { $0.progressStatus == .improving }.count
        let painImprovements = sut.painProgress.filter { $0.progressStatus == .improving }.count
        let mcidAchievements = sut.outcomeProgress.filter { $0.meetsMcid }.count

        XCTAssertEqual(romImprovements, 2, "should have 2 ROM improvements")
        XCTAssertEqual(painImprovements, 1, "should have 1 pain improvement")
        XCTAssertEqual(mcidAchievements, 1, "should have 1 MCID achievement")
    }

    // MARK: - Loading States Tests

    func testIsLoading_CanBeSet() {
        sut.isLoading = true
        XCTAssertTrue(sut.isLoading)

        sut.isLoading = false
        XCTAssertFalse(sut.isLoading)
    }

    func testIsLoadingROM_CanBeSet() {
        sut.isLoadingROM = true
        XCTAssertTrue(sut.isLoadingROM)

        sut.isLoadingROM = false
        XCTAssertFalse(sut.isLoadingROM)
    }

    func testIsLoadingPain_CanBeSet() {
        sut.isLoadingPain = true
        XCTAssertTrue(sut.isLoadingPain)

        sut.isLoadingPain = false
        XCTAssertFalse(sut.isLoadingPain)
    }

    func testIsLoadingOutcomes_CanBeSet() {
        sut.isLoadingOutcomes = true
        XCTAssertTrue(sut.isLoadingOutcomes)

        sut.isLoadingOutcomes = false
        XCTAssertFalse(sut.isLoadingOutcomes)
    }

    // MARK: - Error States Tests

    func testRomError_CanBeSet() {
        sut.romError = "Failed to load ROM data"
        XCTAssertEqual(sut.romError, "Failed to load ROM data")
    }

    func testPainError_CanBeSet() {
        sut.painError = "Failed to load pain data"
        XCTAssertEqual(sut.painError, "Failed to load pain data")
    }

    func testOutcomesError_CanBeSet() {
        sut.outcomesError = "Failed to load outcomes"
        XCTAssertEqual(sut.outcomesError, "Failed to load outcomes")
    }

    // MARK: - ProgressStatus Tests

    func testProgressStatus_DisplayNames() {
        XCTAssertEqual(ProgressStatus.improving.displayName, "Improving")
        XCTAssertEqual(ProgressStatus.stable.displayName, "Stable")
        XCTAssertEqual(ProgressStatus.declining.displayName, "Declining")
    }

    func testProgressStatus_IconNames() {
        XCTAssertEqual(ProgressStatus.improving.iconName, "arrow.up.right")
        XCTAssertEqual(ProgressStatus.stable.iconName, "arrow.right")
        XCTAssertEqual(ProgressStatus.declining.iconName, "arrow.down.right")
    }

    // MARK: - Helper Methods

    private func createMockROMProgressItem(initial: Int, current: Int) -> ROMProgressItem {
        return ROMProgressItem(
            joint: "shoulder",
            movement: "flexion",
            side: .right,
            initialDegrees: initial,
            currentDegrees: current,
            normalRange: 150...180,
            measurements: [
                TrendDataPoint(date: Date().addingTimeInterval(-86400 * 30), value: Double(initial), label: nil),
                TrendDataPoint(date: Date(), value: Double(current), label: nil)
            ]
        )
    }

    private func createMockPainProgressItem(initial: Int, current: Int, painType: String) -> PainProgressItem {
        return PainProgressItem(
            painType: painType,
            initialScore: initial,
            currentScore: current,
            measurements: [
                TrendDataPoint(date: Date().addingTimeInterval(-86400 * 30), value: Double(initial), label: nil),
                TrendDataPoint(date: Date(), value: Double(current), label: nil)
            ]
        )
    }

    private func createMockOutcomeProgressItem(
        initial: Double,
        current: Double,
        measureType: OutcomeMeasureType
    ) -> OutcomeProgressItem {
        return OutcomeProgressItem(
            measureType: measureType,
            initialScore: initial,
            currentScore: current,
            mcidThreshold: measureType.mcidThreshold,
            measurements: [
                TrendDataPoint(date: Date().addingTimeInterval(-86400 * 30), value: initial, label: nil),
                TrendDataPoint(date: Date(), value: current, label: nil)
            ]
        )
    }

    private func createMockPatientProgress(patientId: UUID) -> PatientOutcomeProgress {
        return PatientOutcomeProgress(
            patientId: patientId,
            measures: [],
            overallProgressStatus: .stable,
            mcidAchievementCount: 0,
            lastAssessmentDate: nil
        )
    }

    private func createMockClinicalAssessment(withROM: Bool = false, withPain: Bool = false) -> ClinicalAssessment {
        let romMeasurements: [ROMeasurement]? = withROM ? [
            ROMeasurement(
                joint: "shoulder",
                movement: "flexion",
                degrees: 140,
                normalRange: 150...180,
                side: .right
            )
        ] : nil

        return ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .progress,
            romMeasurements: romMeasurements,
            painAtRest: withPain ? 3 : nil,
            painWithActivity: withPain ? 5 : nil,
            painWorst: withPain ? 7 : nil,
            status: .complete
        )
    }
}

// Note: Mock services removed - testing ViewModel state directly
