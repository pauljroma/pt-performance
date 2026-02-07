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

    func testInitialState_SelectedFastTypeIsIntermittent() {
        XCTAssertEqual(sut.selectedFastType, .intermittent, "selectedFastType should be .intermittent initially")
    }

    func testInitialState_ShowingStartSheetIsFalse() {
        XCTAssertFalse(sut.showingStartSheet, "showingStartSheet should be false initially")
    }

    // MARK: - End Fast Form Initial State

    func testInitialState_ShowingEndSheetIsFalse() {
        XCTAssertFalse(sut.showingEndSheet, "showingEndSheet should be false initially")
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
        XCTAssertEqual(sut.selectedFastType, .intermittent)

        sut.selectedFastType = .extended
        XCTAssertEqual(sut.selectedFastType, .extended, "selectedFastType should be changeable")

        sut.selectedFastType = .waterOnly
        XCTAssertEqual(sut.selectedFastType, .waterOnly, "selectedFastType should be changeable to any type")
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
        XCTAssertEqual(FastingType.intermittent.displayName, "Intermittent")
        XCTAssertEqual(FastingType.extended.displayName, "Extended")
        XCTAssertEqual(FastingType.waterOnly.displayName, "Water Only")
        XCTAssertEqual(FastingType.modified.displayName, "Modified")
        XCTAssertEqual(FastingType.custom.displayName, "Custom")
    }

    func testFastingType_TargetHours() {
        XCTAssertEqual(FastingType.intermittent.targetHours, 16)
        XCTAssertEqual(FastingType.extended.targetHours, 24)
        XCTAssertEqual(FastingType.waterOnly.targetHours, 24)
        XCTAssertEqual(FastingType.modified.targetHours, 18)
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
            trainingTime: nil,
            confidence: 0.85
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

    // MARK: - Timer Logic Tests

    func testTimer_UpdatesProgressOverTime() async throws {
        // Given: An active fast
        let startTime = Calendar.current.date(byAdding: .hour, value: -8, to: Date())!
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)

        // When: Timer fires (simulated by checking progress)
        let initialProgress = sut.currentProgress

        // Then: Progress should be approximately 50%
        XCTAssertEqual(initialProgress, 0.5, accuracy: 0.05)
    }

    func testTimer_ProgressIncreasesWithTime() async throws {
        // Given: An active fast started 4 hours ago
        let startTime = Calendar.current.date(byAdding: .hour, value: -4, to: Date())!
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)

        let progress4Hours = sut.currentProgress // Should be ~25%

        // Simulate 8 hours in (by creating new fast with earlier start)
        let startTime8Hours = Calendar.current.date(byAdding: .hour, value: -8, to: Date())!
        sut.currentFast = createMockFastingLog(startTime: startTime8Hours, endTime: nil, targetHours: 16)

        let progress8Hours = sut.currentProgress // Should be ~50%

        // Then: Progress should increase
        XCTAssertGreaterThan(progress8Hours, progress4Hours)
    }

    // MARK: - Goal Tracking Tests

    func testGoalTracking_WithStats() {
        let stats = FastingStats(
            totalFasts: 20,
            completedFasts: 18,
            averageHours: 16.5,
            longestFast: 24.0,
            currentStreak: 5,
            bestStreak: 10
        )
        sut.stats = stats

        XCTAssertEqual(sut.stats?.currentStreak, 5)
        XCTAssertEqual(sut.stats?.bestStreak, 10)
        XCTAssertEqual(sut.stats?.completedFasts, 18)
    }

    func testGoalTracking_CompletionRate_AllSuccessful() {
        let fasts = [
            createMockCompletedFast(targetHours: 16, actualHours: 16.0),
            createMockCompletedFast(targetHours: 16, actualHours: 17.0),
            createMockCompletedFast(targetHours: 16, actualHours: 16.5)
        ]
        sut.history = fasts

        XCTAssertEqual(sut.completionRate, 1.0, accuracy: 0.01)
    }

    func testGoalTracking_CompletionRate_PartialSuccess() {
        let fasts = [
            createMockCompletedFast(targetHours: 16, actualHours: 16.0), // Success
            createMockCompletedFast(targetHours: 16, actualHours: 8.0),  // Fail (50%)
            createMockCompletedFast(targetHours: 16, actualHours: 15.0), // Success (93.75%)
            createMockCompletedFast(targetHours: 16, actualHours: 10.0)  // Fail (62.5%)
        ]
        sut.history = fasts

        // 2 out of 4 successful
        XCTAssertEqual(sut.completionRate, 0.5, accuracy: 0.01)
    }

    // MARK: - Streak Calculation Tests

    func testStreakCalculation_ConsecutiveDays() {
        let stats = FastingStats(
            totalFasts: 10,
            completedFasts: 10,
            averageHours: 16.0,
            longestFast: 18.0,
            currentStreak: 10,
            bestStreak: 10
        )
        sut.stats = stats

        XCTAssertEqual(sut.stats?.currentStreak, 10)
        XCTAssertEqual(sut.stats?.bestStreak, 10)
    }

    func testStreakCalculation_BrokenStreak() {
        let stats = FastingStats(
            totalFasts: 15,
            completedFasts: 12,
            averageHours: 15.5,
            longestFast: 20.0,
            currentStreak: 2,
            bestStreak: 8
        )
        sut.stats = stats

        XCTAssertEqual(sut.stats?.currentStreak, 2)
        XCTAssertLessThan(sut.stats!.currentStreak, sut.stats!.bestStreak)
    }

    // MARK: - Workout Recommendation Tests

    func testWorkoutRecommendation_InitialState() {
        XCTAssertNil(sut.workoutRecommendation)
        XCTAssertFalse(sut.isLoadingWorkoutRec)
    }

    func testIsExtendedFast_WhenNotFasting() {
        sut.currentFast = nil
        XCTAssertFalse(sut.isExtendedFast)
    }

    func testIntensityPercentage_DefaultValue() {
        // When no workout recommendation is set
        XCTAssertEqual(sut.intensityPercentage, 100)
    }

    func testIsWorkoutRecommended_DefaultValue() {
        // When no workout recommendation is set
        XCTAssertTrue(sut.isWorkoutRecommended)
    }

    func testWarningsCount_DefaultValue() {
        // When no workout recommendation is set
        XCTAssertEqual(sut.warningsCount, 0)
    }

    // MARK: - Fast Interrupted Mid-Session Tests

    func testFast_InterruptedMidSession_ProgressPreserved() {
        // Given: A fast that started 10 hours ago
        let startTime = Calendar.current.date(byAdding: .hour, value: -10, to: Date())!
        let activeFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)
        sut.currentFast = activeFast

        // Progress should be preserved at ~62.5%
        XCTAssertEqual(sut.currentProgress, 0.625, accuracy: 0.05)
        XCTAssertTrue(sut.isFasting)
    }

    func testFast_InterruptedMidSession_CanBeCompleted() {
        // Given: An active fast
        let startTime = Calendar.current.date(byAdding: .hour, value: -10, to: Date())!
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)

        // When: Fast is ended
        sut.currentFast = nil

        // Then: No current fast
        XCTAssertFalse(sut.isFasting)
        XCTAssertEqual(sut.currentProgress, 0)
    }

    // MARK: - Edge Cases

    func testHistory_WithMixedFasts() {
        let activeFast = createMockActiveFast()
        let completedFast1 = createMockCompletedFast(targetHours: 16, actualHours: 16.0)
        let completedFast2 = createMockCompletedFast(targetHours: 18, actualHours: 12.0) // Broken early

        sut.history = [activeFast, completedFast1, completedFast2]

        // Only completed fasts (with endTime) should be in completedFasts
        XCTAssertEqual(sut.completedFasts.count, 2)
    }

    func testElapsedHours_VeryLongFast() {
        // Given: A 48-hour fast
        let startTime = Calendar.current.date(byAdding: .hour, value: -48, to: Date())!
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 48)

        XCTAssertEqual(sut.elapsedHours, 48, accuracy: 0.5)
        XCTAssertEqual(sut.remainingHours, 0, accuracy: 0.5)
    }

    func testRemainingHours_JustStartedFast() {
        // Given: A fast that just started
        let startTime = Date()
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)

        XCTAssertEqual(sut.elapsedHours, 0, accuracy: 0.1)
        XCTAssertEqual(sut.remainingHours, 16, accuracy: 0.1)
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
            fastingType: .intermittent,
            startedAt: startTime,
            endedAt: endTime,
            plannedEndAt: nil,
            targetHours: targetHours,
            actualHours: actualHours,
            wasBrokenEarly: endTime != nil && actualHours != nil && actualHours! < Double(targetHours) * 0.9,
            breakReason: nil,
            moodStart: nil,
            moodEnd: nil,
            hungerLevel: nil,
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
            fastingType: .intermittent,
            startedAt: startTime,
            endedAt: Date(),
            plannedEndAt: nil,
            targetHours: targetHours,
            actualHours: actualHours,
            wasBrokenEarly: actualHours < Double(targetHours) * 0.9,
            breakReason: nil,
            moodStart: nil,
            moodEnd: nil,
            hungerLevel: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )
    }
}
