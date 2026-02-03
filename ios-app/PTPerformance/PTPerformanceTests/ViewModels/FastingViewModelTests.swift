//
//  FastingViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for FastingViewModel
//  Tests initial state, computed properties, form state, and fasting calculations
//

import XCTest
@testable import PTPerformance

@MainActor
final class FastingViewModelTests: XCTestCase {

    var sut: FastingViewModel!

    override func setUp() {
        super.setUp()
        sut = FastingViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_CurrentFastIsNil() {
        XCTAssertNil(sut.currentFast, "currentFast should be nil initially")
    }

    func testInitialState_HistoryIsEmpty() {
        XCTAssertTrue(sut.history.isEmpty, "history should be empty initially")
    }

    func testInitialState_StatsIsNil() {
        XCTAssertNil(sut.stats, "stats should be nil initially")
    }

    func testInitialState_RecommendationIsNil() {
        XCTAssertNil(sut.recommendation, "recommendation should be nil initially")
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading, "isLoading should be false initially")
    }

    func testInitialState_ErrorIsNil() {
        XCTAssertNil(sut.error, "error should be nil initially")
    }

    // MARK: - Start Fast Form Initial State

    func testInitialState_SelectedFastTypeIsIntermittent16_8() {
        XCTAssertEqual(sut.selectedFastType, .intermittent16_8, "selectedFastType should be .intermittent16_8 initially")
    }

    func testInitialState_ShowingStartSheetIsFalse() {
        XCTAssertFalse(sut.showingStartSheet, "showingStartSheet should be false initially")
    }

    // MARK: - End Fast Form Initial State

    func testInitialState_ShowingEndSheetIsFalse() {
        XCTAssertFalse(sut.showingEndSheet, "showingEndSheet should be false initially")
    }

    func testInitialState_BreakfastFoodIsEmpty() {
        XCTAssertEqual(sut.breakfastFood, "", "breakfastFood should be empty initially")
    }

    func testInitialState_EnergyLevelIs5() {
        XCTAssertEqual(sut.energyLevel, 5, "energyLevel should be 5 initially")
    }

    func testInitialState_EndNotesIsEmpty() {
        XCTAssertEqual(sut.endNotes, "", "endNotes should be empty initially")
    }

    // MARK: - Computed Property Tests - isFasting

    func testIsFasting_WhenCurrentFastIsNil_ReturnsFalse() {
        sut.currentFast = nil
        XCTAssertFalse(sut.isFasting, "isFasting should be false when currentFast is nil")
    }

    func testIsFasting_WhenCurrentFastExists_ReturnsTrue() {
        sut.currentFast = createMockActiveFast()
        XCTAssertTrue(sut.isFasting, "isFasting should be true when currentFast exists")
    }

    // MARK: - Computed Property Tests - currentProgress

    func testCurrentProgress_WhenNotFasting_ReturnsZero() {
        sut.currentFast = nil
        XCTAssertEqual(sut.currentProgress, 0, "currentProgress should be 0 when not fasting")
    }

    func testCurrentProgress_WhenFasting_ReturnsProgressPercent() {
        let fast = createMockActiveFast()
        sut.currentFast = fast
        XCTAssertEqual(sut.currentProgress, fast.progressPercent, accuracy: 0.01, "currentProgress should match fast's progressPercent")
    }

    // MARK: - Computed Property Tests - elapsedHours

    func testElapsedHours_WhenNotFasting_ReturnsZero() {
        sut.currentFast = nil
        XCTAssertEqual(sut.elapsedHours, 0, "elapsedHours should be 0 when not fasting")
    }

    func testElapsedHours_WhenFasting_ReturnsCorrectValue() {
        let startTime = Calendar.current.date(byAdding: .hour, value: -4, to: Date())!
        let fast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)
        sut.currentFast = fast

        // Allow for small time differences during test execution
        XCTAssertEqual(sut.elapsedHours, 4, accuracy: 0.02, "elapsedHours should be approximately 4 hours")
    }

    // MARK: - Computed Property Tests - remainingHours

    func testRemainingHours_WhenNotFasting_ReturnsZero() {
        sut.currentFast = nil
        XCTAssertEqual(sut.remainingHours, 0, "remainingHours should be 0 when not fasting")
    }

    func testRemainingHours_WhenFasting_ReturnsCorrectValue() {
        let startTime = Calendar.current.date(byAdding: .hour, value: -4, to: Date())!
        let fast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)
        sut.currentFast = fast

        // 16 hours target - 4 hours elapsed = 12 hours remaining
        XCTAssertEqual(sut.remainingHours, 12, accuracy: 0.02, "remainingHours should be approximately 12 hours")
    }

    func testRemainingHours_WhenExceededTarget_ReturnsZero() {
        let startTime = Calendar.current.date(byAdding: .hour, value: -20, to: Date())!
        let fast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)
        sut.currentFast = fast

        XCTAssertEqual(sut.remainingHours, 0, "remainingHours should be 0 when exceeded target")
    }

    // MARK: - Computed Property Tests - completedFasts

    func testCompletedFasts_WhenEmpty_ReturnsEmpty() {
        sut.history = []
        XCTAssertTrue(sut.completedFasts.isEmpty, "completedFasts should be empty when history is empty")
    }

    func testCompletedFasts_FiltersOnlyCompleted() {
        let completedFast = createMockFastingLog(startTime: Date(), endTime: Date(), targetHours: 16)
        let activeFast = createMockActiveFast()

        sut.history = [completedFast, activeFast]

        XCTAssertEqual(sut.completedFasts.count, 1, "completedFasts should only include fasts with endTime")
        XCTAssertEqual(sut.completedFasts.first?.id, completedFast.id)
    }

    // MARK: - Computed Property Tests - completionRate

    func testCompletionRate_WhenEmpty_ReturnsZero() {
        sut.history = []
        XCTAssertEqual(sut.completionRate, 0, "completionRate should be 0 when history is empty")
    }

    func testCompletionRate_CalculatesCorrectly() {
        // Create completed fasts with various actual hours
        let successfulFast = createMockCompletedFast(targetHours: 16, actualHours: 16.0) // 100% of target
        let almostCompletedFast = createMockCompletedFast(targetHours: 16, actualHours: 15.0) // 93.75% (> 90%)
        let failedFast = createMockCompletedFast(targetHours: 16, actualHours: 10.0) // 62.5% (< 90%)

        sut.history = [successfulFast, almostCompletedFast, failedFast]

        // 2 out of 3 completed successfully (>= 90% of target)
        XCTAssertEqual(sut.completionRate, 2.0/3.0, accuracy: 0.01, "completionRate should be 2/3")
    }

    func testCompletionRate_WhenAllSuccessful_ReturnsOne() {
        let fast1 = createMockCompletedFast(targetHours: 16, actualHours: 16.0)
        let fast2 = createMockCompletedFast(targetHours: 18, actualHours: 18.0)

        sut.history = [fast1, fast2]

        XCTAssertEqual(sut.completionRate, 1.0, "completionRate should be 1.0 when all fasts are successful")
    }

    // MARK: - Form State Tests

    func testSelectedFastType_CanBeChanged() {
        XCTAssertEqual(sut.selectedFastType, .intermittent16_8)

        sut.selectedFastType = .intermittent18_6
        XCTAssertEqual(sut.selectedFastType, .intermittent18_6, "selectedFastType should be changeable")

        sut.selectedFastType = .omad
        XCTAssertEqual(sut.selectedFastType, .omad, "selectedFastType should be changeable to any type")
    }

    func testBreakfastFood_CanBeSet() {
        sut.breakfastFood = "Eggs and avocado"
        XCTAssertEqual(sut.breakfastFood, "Eggs and avocado", "breakfastFood should be settable")
    }

    func testEnergyLevel_CanBeSet() {
        sut.energyLevel = 8
        XCTAssertEqual(sut.energyLevel, 8, "energyLevel should be settable")
    }

    func testEndNotes_CanBeSet() {
        sut.endNotes = "Felt great"
        XCTAssertEqual(sut.endNotes, "Felt great", "endNotes should be settable")
    }

    // MARK: - Sheet State Tests

    func testShowingStartSheet_CanBeToggled() {
        XCTAssertFalse(sut.showingStartSheet)

        sut.showingStartSheet = true
        XCTAssertTrue(sut.showingStartSheet, "showingStartSheet should be togglable to true")

        sut.showingStartSheet = false
        XCTAssertFalse(sut.showingStartSheet, "showingStartSheet should be togglable to false")
    }

    func testShowingEndSheet_CanBeToggled() {
        XCTAssertFalse(sut.showingEndSheet)

        sut.showingEndSheet = true
        XCTAssertTrue(sut.showingEndSheet, "showingEndSheet should be togglable to true")

        sut.showingEndSheet = false
        XCTAssertFalse(sut.showingEndSheet, "showingEndSheet should be togglable to false")
    }

    // MARK: - Error State Tests

    func testError_CanBeSet() {
        XCTAssertNil(sut.error)

        sut.error = "Failed to start fast"
        XCTAssertEqual(sut.error, "Failed to start fast", "error should be settable")

        sut.error = nil
        XCTAssertNil(sut.error, "error should be clearable")
    }

    // MARK: - Loading State Tests

    func testIsLoading_CanBeSet() {
        XCTAssertFalse(sut.isLoading)

        sut.isLoading = true
        XCTAssertTrue(sut.isLoading, "isLoading should be settable to true")

        sut.isLoading = false
        XCTAssertFalse(sut.isLoading, "isLoading should be settable to false")
    }

    // MARK: - FastingType Tests

    func testFastingType_AllCasesHaveDisplayName() {
        for fastingType in FastingType.allCases {
            XCTAssertFalse(fastingType.displayName.isEmpty, "FastingType \(fastingType) should have a display name")
        }
    }

    func testFastingType_AllCasesHaveTargetHours() {
        for fastingType in FastingType.allCases {
            XCTAssertGreaterThan(fastingType.targetHours, 0, "FastingType \(fastingType) should have positive target hours")
        }
    }

    func testFastingType_DisplayNames() {
        XCTAssertEqual(FastingType.intermittent16_8.displayName, "16:8")
        XCTAssertEqual(FastingType.intermittent18_6.displayName, "18:6")
        XCTAssertEqual(FastingType.intermittent20_4.displayName, "20:4")
        XCTAssertEqual(FastingType.omad.displayName, "OMAD (23:1)")
        XCTAssertEqual(FastingType.extended24.displayName, "24 Hour")
        XCTAssertEqual(FastingType.extended36.displayName, "36 Hour")
        XCTAssertEqual(FastingType.extended48.displayName, "48 Hour")
        XCTAssertEqual(FastingType.custom.displayName, "Custom")
    }

    func testFastingType_TargetHours() {
        XCTAssertEqual(FastingType.intermittent16_8.targetHours, 16)
        XCTAssertEqual(FastingType.intermittent18_6.targetHours, 18)
        XCTAssertEqual(FastingType.intermittent20_4.targetHours, 20)
        XCTAssertEqual(FastingType.omad.targetHours, 23)
        XCTAssertEqual(FastingType.extended24.targetHours, 24)
        XCTAssertEqual(FastingType.extended36.targetHours, 36)
        XCTAssertEqual(FastingType.extended48.targetHours, 48)
        XCTAssertEqual(FastingType.custom.targetHours, 16)
    }

    // MARK: - FastingLog Model Tests

    func testFastingLog_IsActive_WhenEndTimeNil() {
        let fast = createMockActiveFast()
        XCTAssertTrue(fast.isActive, "FastingLog should be active when endTime is nil")
    }

    func testFastingLog_IsNotActive_WhenEndTimeSet() {
        let fast = createMockFastingLog(startTime: Date(), endTime: Date(), targetHours: 16)
        XCTAssertFalse(fast.isActive, "FastingLog should not be active when endTime is set")
    }

    func testFastingLog_ProgressPercent_CapsAtOne() {
        let startTime = Calendar.current.date(byAdding: .hour, value: -20, to: Date())!
        let endTime = Date()
        let fast = createMockFastingLog(startTime: startTime, endTime: endTime, targetHours: 16)

        XCTAssertLessThanOrEqual(fast.progressPercent, 1.0, "progressPercent should be capped at 1.0")
    }

    // MARK: - Stats State Tests

    func testStats_CanBeSet() {
        let stats = FastingStats(
            totalFasts: 10,
            completedFasts: 8,
            averageHours: 16.5,
            longestFast: 24.0,
            currentStreak: 5,
            bestStreak: 10
        )
        sut.stats = stats

        XCTAssertEqual(sut.stats?.totalFasts, 10)
        XCTAssertEqual(sut.stats?.completedFasts, 8)
        XCTAssertEqual(sut.stats?.averageHours, 16.5)
    }

    // MARK: - Recommendation State Tests

    func testRecommendation_CanBeSet() {
        let recommendation = EatingWindowRecommendation(
            id: UUID(),
            suggestedStart: Date(),
            suggestedEnd: Date(),
            reason: "Based on your training schedule",
            trainingTime: nil
        )
        sut.recommendation = recommendation

        XCTAssertNotNil(sut.recommendation)
        XCTAssertEqual(sut.recommendation?.reason, "Based on your training schedule")
    }

    // MARK: - Edge Cases

    func testHistory_CanBeCleared() {
        let fast = createMockCompletedFast(targetHours: 16, actualHours: 16.0)
        sut.history = [fast]

        XCTAssertFalse(sut.history.isEmpty)

        sut.history = []
        XCTAssertTrue(sut.history.isEmpty, "history should be clearable")
    }

    func testCurrentFast_CanBeCleared() {
        sut.currentFast = createMockActiveFast()
        XCTAssertNotNil(sut.currentFast)

        sut.currentFast = nil
        XCTAssertNil(sut.currentFast, "currentFast should be clearable")
    }

    // MARK: - Helper Methods

    private func createMockActiveFast() -> FastingLog {
        return createMockFastingLog(
            startTime: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
            endTime: nil,
            targetHours: 16
        )
    }

    private func createMockFastingLog(startTime: Date, endTime: Date?, targetHours: Int) -> FastingLog {
        var actualHours: Double? = nil
        if let end = endTime {
            actualHours = end.timeIntervalSince(startTime) / 3600
        }
        return FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent16_8,
            startTime: startTime,
            endTime: endTime,
            targetHours: targetHours,
            actualHours: actualHours,
            breakfastFood: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )
    }

    private func createMockCompletedFast(targetHours: Int, actualHours: Double) -> FastingLog {
        let startTime = Calendar.current.date(byAdding: .hour, value: -Int(actualHours), to: Date())!
        return FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent16_8,
            startTime: startTime,
            endTime: Date(),
            targetHours: targetHours,
            actualHours: actualHours,
            breakfastFood: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )
    }
}
