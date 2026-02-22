//
//  FastingTrackerViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for FastingTrackerViewModel
//  Tests initial state, timer logic, zone tracking, computed properties,
//  and state transitions for the fasting tracker feature (ACP-1001).
//

import XCTest
@testable import PTPerformance

@MainActor
final class FastingTrackerViewModelTests: XCTestCase {

    var sut: FastingTrackerViewModel!

    override func setUp() async throws {
        try await super.setUp()
        sut = FastingTrackerViewModel()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_CurrentFastIsNil() {
        XCTAssertNil(sut.currentFast, "currentFast should be nil initially")
    }

    func testInitialState_FastingHistoryIsEmpty() {
        XCTAssertTrue(sut.fastingHistory.isEmpty, "fastingHistory should be empty initially")
    }

    func testInitialState_StatsIsNil() {
        XCTAssertNil(sut.stats, "stats should be nil initially")
    }

    func testInitialState_SelectedProtocolIsSixteen8() {
        XCTAssertEqual(sut.selectedProtocol, .sixteen8, "selectedProtocol should default to .sixteen8")
    }

    func testInitialState_ElapsedSecondsIsZero() {
        XCTAssertEqual(sut.elapsedSeconds, 0, "elapsedSeconds should be 0 initially")
    }

    func testInitialState_TargetSecondsIsZero() {
        XCTAssertEqual(sut.targetSeconds, 0, "targetSeconds should be 0 initially")
    }

    func testInitialState_CurrentZoneIsBurningSugar() {
        XCTAssertEqual(sut.currentZone, .burningSugar, "currentZone should be .burningSugar initially")
    }

    func testInitialState_NextZoneIsFatBurning() {
        XCTAssertEqual(sut.nextZone, .fatBurning, "nextZone should be .fatBurning initially")
    }

    func testInitialState_TimeToNextZoneIsZero() {
        XCTAssertEqual(sut.timeToNextZone, 0, "timeToNextZone should be 0 initially")
    }

    func testInitialState_UpcomingWorkoutIsNil() {
        XCTAssertNil(sut.upcomingWorkout, "upcomingWorkout should be nil initially")
    }

    func testInitialState_TrainingSyncRecommendationIsNil() {
        XCTAssertNil(sut.trainingSyncRecommendation, "trainingSyncRecommendation should be nil initially")
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading, "isLoading should be false initially")
    }

    func testInitialState_ErrorIsNil() {
        XCTAssertNil(sut.error, "error should be nil initially")
    }

    func testInitialState_ShowCelebrationIsFalse() {
        XCTAssertFalse(sut.showCelebration, "showCelebration should be false initially")
    }

    func testInitialState_JustReachedGoalIsFalse() {
        XCTAssertFalse(sut.justReachedGoal, "justReachedGoal should be false initially")
    }

    func testInitialState_IsFastingIsFalse() {
        XCTAssertFalse(sut.isFasting, "isFasting should be false initially")
    }

    func testInitialState_FastStartTimeIsNil() {
        XCTAssertNil(sut.fastStartTime, "fastStartTime should be nil initially")
    }

    func testInitialState_ProgressIsZero() {
        XCTAssertEqual(sut.progress, 0, "progress should be 0 initially")
    }

    func testInitialState_GoalReachedIsFalse() {
        XCTAssertFalse(sut.goalReached, "goalReached should be false initially")
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

    // MARK: - Computed Property Tests - fastStartTime

    func testFastStartTime_WhenNotFasting_ReturnsNil() {
        sut.currentFast = nil
        XCTAssertNil(sut.fastStartTime, "fastStartTime should be nil when not fasting")
    }

    func testFastStartTime_WhenFasting_ReturnsStartedAt() {
        let startDate = Date().addingTimeInterval(-3600)
        let fast = createMockFastingLog(startTime: startDate, endTime: nil, targetHours: 16)
        sut.currentFast = fast
        XCTAssertEqual(sut.fastStartTime, startDate, "fastStartTime should return the fast's startedAt")
    }

    // MARK: - Computed Property Tests - currentProtocol

    func testCurrentProtocol_WhenNotFasting_ReturnsSelectedProtocol() {
        sut.currentFast = nil
        sut.selectedProtocol = .eighteen6
        XCTAssertEqual(sut.currentProtocol, .eighteen6, "currentProtocol should return selectedProtocol when not fasting")
    }

    func testCurrentProtocol_WhenFasting_ReturnsSelectedProtocol() {
        sut.currentFast = createMockActiveFast()
        sut.selectedProtocol = .twenty4
        XCTAssertEqual(sut.currentProtocol, .twenty4, "currentProtocol should return selectedProtocol when fasting")
    }

    // MARK: - Timer-Driven Computed Properties

    func testTimerUpdate_ElapsedSecondsReflectsFastDuration() async throws {
        // Create a fast that started 4 hours ago
        let startTime = Date().addingTimeInterval(-14400) // 4 hours
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)

        // Wait for the timer to fire and update state
        try await Task.sleep(nanoseconds: 1_200_000_000) // 1.2 seconds

        // elapsedSeconds should be approximately 4 hours
        XCTAssertEqual(sut.elapsedSeconds, 14400, accuracy: 5, "elapsedSeconds should reflect ~4 hours of fasting")
    }

    func testTimerUpdate_TargetSecondsMatchesFastTarget() async throws {
        let fast = createMockFastingLog(
            startTime: Date().addingTimeInterval(-3600),
            endTime: nil,
            targetHours: 16
        )
        sut.currentFast = fast

        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertEqual(sut.targetSeconds, 57600, "targetSeconds should be 16 * 3600 = 57600")
    }

    func testTimerUpdate_ProgressCalculatesCorrectly() async throws {
        // 8 hours into a 16 hour fast = 50%
        let startTime = Date().addingTimeInterval(-28800) // 8 hours
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)

        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertEqual(sut.progress, 0.5, accuracy: 0.01, "progress should be ~50% at 8 hours into a 16-hour fast")
    }

    func testTimerUpdate_RemainingSecondsCalculatesCorrectly() async throws {
        // 4 hours into a 16 hour fast = 12 hours remaining
        let startTime = Date().addingTimeInterval(-14400) // 4 hours
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)

        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertEqual(sut.remainingSeconds, 43200, accuracy: 5, "remainingSeconds should be ~43200 (12 hours)")
    }

    func testTimerUpdate_ElapsedHoursConvertsCorrectly() async throws {
        let startTime = Date().addingTimeInterval(-18000) // 5 hours
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)

        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertEqual(sut.elapsedHours, 5.0, accuracy: 0.01, "elapsedHours should be ~5.0")
    }

    func testTimerUpdate_TargetHoursConvertsCorrectly() async throws {
        sut.currentFast = createMockFastingLog(
            startTime: Date().addingTimeInterval(-3600),
            endTime: nil,
            targetHours: 18
        )

        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertEqual(sut.targetHours, 18, "targetHours should be 18")
    }

    func testTimerUpdate_GoalReached_WhenExceededTarget() async throws {
        // 20 hours into a 16 hour fast
        let startTime = Date().addingTimeInterval(-72000) // 20 hours
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)

        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertTrue(sut.goalReached, "goalReached should be true when elapsed exceeds target")
        XCTAssertEqual(sut.remainingSeconds, 0, "remainingSeconds should be 0 when goal reached")
    }

    func testTimerUpdate_GoalNotReached_WhenUnderTarget() async throws {
        let startTime = Date().addingTimeInterval(-14400) // 4 hours
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)

        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertFalse(sut.goalReached, "goalReached should be false when target not reached")
    }

    func testTimerUpdate_ProgressCapsAtOne() async throws {
        // 20 hours into a 16 hour fast
        let startTime = Date().addingTimeInterval(-72000) // 20 hours
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)

        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertEqual(sut.progress, 1.0, "progress should cap at 1.0 even when exceeded")
    }

    func testTimerUpdate_GoalReachedIsFalse_WhenNotFasting() async throws {
        sut.currentFast = nil

        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertFalse(sut.goalReached, "goalReached should be false when not fasting")
    }

    // MARK: - Zone Tracking Tests

    func testTimerUpdate_Zone_BurningSugar() async throws {
        // 2 hours into fast
        let startTime = Date().addingTimeInterval(-7200)
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)

        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertEqual(sut.currentZone, .burningSugar, "Zone should be burningSugar at 2 hours")
    }

    func testTimerUpdate_Zone_FatBurning() async throws {
        // 8 hours into fast
        let startTime = Date().addingTimeInterval(-28800)
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)

        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertEqual(sut.currentZone, .fatBurning, "Zone should be fatBurning at 8 hours")
    }

    func testTimerUpdate_Zone_Ketosis() async throws {
        // 15 hours into fast
        let startTime = Date().addingTimeInterval(-54000)
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 18)

        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertEqual(sut.currentZone, .ketosis, "Zone should be ketosis at 15 hours")
    }

    func testTimerUpdate_Zone_DeepKetosis() async throws {
        // 24 hours into fast
        let startTime = Date().addingTimeInterval(-86400)
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 48)

        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertEqual(sut.currentZone, .deepKetosis, "Zone should be deepKetosis at 24 hours")
    }

    func testTimerUpdate_Zone_Autophagy() async throws {
        // 50 hours into fast
        let startTime = Date().addingTimeInterval(-180000)
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 72)

        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertEqual(sut.currentZone, .autophagy, "Zone should be autophagy at 50 hours")
    }

    // MARK: - Zone Status Helpers Tests

    func testIsFatBurningActive_AtFourHours() async throws {
        let startTime = Date().addingTimeInterval(-14400) // 4 hours
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)

        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertTrue(sut.isFatBurningActive, "Fat burning should be active at 4 hours")
    }

    func testIsFatBurningActive_BeforeFourHours() async throws {
        let startTime = Date().addingTimeInterval(-10800) // 3 hours
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)

        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertFalse(sut.isFatBurningActive, "Fat burning should not be active before 4 hours")
    }

    func testIsKetosisActive_AtTwelveHours() async throws {
        let startTime = Date().addingTimeInterval(-43200) // 12 hours
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 18)

        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertTrue(sut.isKetosisActive, "Ketosis should be active at 12 hours")
    }

    func testIsKetosisActive_BeforeTwelveHours() async throws {
        let startTime = Date().addingTimeInterval(-39600) // 11 hours
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)

        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertFalse(sut.isKetosisActive, "Ketosis should not be active before 12 hours")
    }

    func testIsKetosisSoon_AtTenHours() async throws {
        let startTime = Date().addingTimeInterval(-36000) // 10 hours
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)

        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertTrue(sut.isKetosisSoon, "Ketosis should be 'soon' at 10 hours")
    }

    func testIsKetosisSoon_BeforeTenHours() async throws {
        let startTime = Date().addingTimeInterval(-32400) // 9 hours
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)

        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertFalse(sut.isKetosisSoon, "Ketosis should not be 'soon' before 10 hours")
    }

    func testIsKetosisSoon_AtTwelveHours_ReturnsFalse() async throws {
        let startTime = Date().addingTimeInterval(-43200) // 12 hours
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 18)

        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertFalse(sut.isKetosisSoon, "Ketosis should not be 'soon' at 12h (already active)")
    }

    // MARK: - currentPhase Tests

    func testCurrentPhase_FedState() async throws {
        // Less than 0.5 hours
        let startTime = Date().addingTimeInterval(-600) // 10 minutes
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)

        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertEqual(sut.currentPhase, .fed, "Phase should be fed under 0.5 hours")
    }

    func testCurrentPhase_EarlyFast() async throws {
        let startTime = Date().addingTimeInterval(-7200) // 2 hours
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)

        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertEqual(sut.currentPhase, .earlyFast, "Phase should be earlyFast at 2 hours")
    }

    func testCurrentPhase_FatBurning() async throws {
        let startTime = Date().addingTimeInterval(-28800) // 8 hours
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)

        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertEqual(sut.currentPhase, .fatBurning, "Phase should be fatBurning at 8 hours")
    }

    func testCurrentPhase_Ketosis() async throws {
        let startTime = Date().addingTimeInterval(-64800) // 18 hours
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 24)

        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertEqual(sut.currentPhase, .ketosis, "Phase should be ketosis at 18 hours")
    }

    func testCurrentPhase_DeepKetosis() async throws {
        let startTime = Date().addingTimeInterval(-108000) // 30 hours
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 48)

        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertEqual(sut.currentPhase, .deepKetosis, "Phase should be deepKetosis at 30 hours")
    }

    func testCurrentPhase_Autophagy() async throws {
        let startTime = Date().addingTimeInterval(-180000) // 50 hours
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 72)

        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertEqual(sut.currentPhase, .autophagy, "Phase should be autophagy at 50 hours")
    }

    // MARK: - Formatted Time Tests

    func testFormattedRemainingTime_GoalReached() async throws {
        let startTime = Date().addingTimeInterval(-72000) // 20h into 16h
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)

        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertEqual(sut.formattedRemainingTime, "Goal reached!", "Should show goal reached text")
    }

    func testFormattedRemainingTime_TimeRemaining() async throws {
        let startTime = Date().addingTimeInterval(-3600) // 1h into 16h
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)

        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertTrue(sut.formattedRemainingTime.contains("h"), "Should contain hours when time remaining")
    }

    // MARK: - Extend Fast Tests

    func testExtendFast_IncreasesTargetSeconds() async throws {
        let startTime = Date().addingTimeInterval(-14400) // 4h
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)

        try await Task.sleep(nanoseconds: 1_200_000_000)

        await sut.extendFast(byHours: 4)

        XCTAssertEqual(sut.targetSeconds, 72000, "Target should increase to 20h (72000 seconds)")
    }

    func testExtendFast_UpdatesCustomFastingHours() async throws {
        let startTime = Date().addingTimeInterval(-14400) // 4h
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)

        try await Task.sleep(nanoseconds: 1_200_000_000)

        await sut.extendFast(byHours: 4)

        XCTAssertEqual(sut.customFastingHours, 20, "Custom fasting hours should update to 20")
    }

    func testExtendFast_ResetsGoalReachedState() async throws {
        // Fast that exceeded its target
        let startTime = Date().addingTimeInterval(-72000) // 20h into 16h
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)

        try await Task.sleep(nanoseconds: 1_200_000_000)

        await sut.extendFast(byHours: 8)

        XCTAssertFalse(sut.justReachedGoal, "justReachedGoal should be reset after extending")
        XCTAssertFalse(sut.showCelebration, "showCelebration should be reset after extending")
    }

    func testExtendFast_WhenNotFasting_DoesNothing() async throws {
        sut.currentFast = nil

        await sut.extendFast(byHours: 4)

        XCTAssertEqual(sut.targetSeconds, 0, "Target should remain 0 when not fasting")
    }

    // MARK: - Dismiss Celebration Tests

    func testDismissCelebration_SetsShowCelebrationToFalse() {
        sut.dismissCelebration()
        XCTAssertFalse(sut.showCelebration, "showCelebration should be false after dismissal")
    }

    // MARK: - State Transition Tests

    func testStateTransition_FromNotFastingToFasting() {
        XCTAssertFalse(sut.isFasting, "Should not be fasting initially")

        sut.currentFast = createMockActiveFast()
        XCTAssertTrue(sut.isFasting, "Should be fasting after setting currentFast")
    }

    func testStateTransition_FromFastingToNotFasting() {
        sut.currentFast = createMockActiveFast()
        XCTAssertTrue(sut.isFasting)

        sut.currentFast = nil
        XCTAssertFalse(sut.isFasting, "Should not be fasting after clearing currentFast")
    }

    func testStateTransition_TimerResetsWhenFastCleared() async throws {
        // Start with an active fast
        let startTime = Date().addingTimeInterval(-14400) // 4h
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 16)

        try await Task.sleep(nanoseconds: 1_200_000_000)
        XCTAssertGreaterThan(sut.elapsedSeconds, 0, "Elapsed should be > 0 while fasting")

        // Clear the fast
        sut.currentFast = nil
        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertEqual(sut.elapsedSeconds, 0, "Elapsed should reset to 0 when fast is cleared")
        XCTAssertEqual(sut.targetSeconds, 0, "Target should reset to 0 when fast is cleared")
    }

    // MARK: - Protocol Selection Tests

    func testSelectedProtocol_CanBeChanged() {
        XCTAssertEqual(sut.selectedProtocol, .sixteen8)

        sut.selectedProtocol = .eighteen6
        XCTAssertEqual(sut.selectedProtocol, .eighteen6)

        sut.selectedProtocol = .twenty4
        XCTAssertEqual(sut.selectedProtocol, .twenty4)

        sut.selectedProtocol = .omad
        XCTAssertEqual(sut.selectedProtocol, .omad)

        sut.selectedProtocol = .custom
        XCTAssertEqual(sut.selectedProtocol, .custom)
    }

    func testCustomFastingHours_CanBeChanged() {
        sut.customFastingHours = 20
        XCTAssertEqual(sut.customFastingHours, 20, "customFastingHours should be settable")
    }

    // MARK: - Error State Tests

    func testError_CanBeSet() {
        XCTAssertNil(sut.error)

        sut.error = "Failed to start fast"
        XCTAssertEqual(sut.error, "Failed to start fast")

        sut.error = nil
        XCTAssertNil(sut.error, "error should be clearable")
    }

    // MARK: - FastingZone.fromHours Tests

    func testFastingZone_FromHours_BurningSugar() {
        XCTAssertEqual(FastingZone.fromHours(0), .burningSugar)
        XCTAssertEqual(FastingZone.fromHours(2), .burningSugar)
        XCTAssertEqual(FastingZone.fromHours(3.9), .burningSugar)
    }

    func testFastingZone_FromHours_FatBurning() {
        XCTAssertEqual(FastingZone.fromHours(4), .fatBurning)
        XCTAssertEqual(FastingZone.fromHours(8), .fatBurning)
        XCTAssertEqual(FastingZone.fromHours(11.9), .fatBurning)
    }

    func testFastingZone_FromHours_Ketosis() {
        XCTAssertEqual(FastingZone.fromHours(12), .ketosis)
        XCTAssertEqual(FastingZone.fromHours(15), .ketosis)
        XCTAssertEqual(FastingZone.fromHours(17.9), .ketosis)
    }

    func testFastingZone_FromHours_DeepKetosis() {
        XCTAssertEqual(FastingZone.fromHours(18), .deepKetosis)
        XCTAssertEqual(FastingZone.fromHours(24), .deepKetosis)
        XCTAssertEqual(FastingZone.fromHours(47.9), .deepKetosis)
    }

    func testFastingZone_FromHours_Autophagy() {
        XCTAssertEqual(FastingZone.fromHours(48), .autophagy)
        XCTAssertEqual(FastingZone.fromHours(72), .autophagy)
    }

    // MARK: - FastingZone Properties Tests

    func testFastingZone_DisplayNames() {
        XCTAssertEqual(FastingZone.fed.displayName, "Fed")
        XCTAssertEqual(FastingZone.burningSugar.displayName, "Burning Sugar")
        XCTAssertEqual(FastingZone.fatBurning.displayName, "Fat Burning")
        XCTAssertEqual(FastingZone.ketosis.displayName, "Ketosis")
        XCTAssertEqual(FastingZone.deepKetosis.displayName, "Deep Ketosis")
        XCTAssertEqual(FastingZone.autophagy.displayName, "Autophagy")
    }

    func testFastingZone_ShortNames() {
        XCTAssertEqual(FastingZone.fed.shortName, "Fed")
        XCTAssertEqual(FastingZone.burningSugar.shortName, "Sugar")
        XCTAssertEqual(FastingZone.fatBurning.shortName, "Fat")
        XCTAssertEqual(FastingZone.ketosis.shortName, "Ketosis")
        XCTAssertEqual(FastingZone.deepKetosis.shortName, "Deep")
        XCTAssertEqual(FastingZone.autophagy.shortName, "Autophagy")
    }

    func testFastingZone_TimelineZones_ExcludesFed() {
        let timelineZones = FastingZone.timelineZones
        XCTAssertFalse(timelineZones.contains(.fed), "Timeline zones should not include fed state")
        XCTAssertEqual(timelineZones.count, 5, "Timeline zones should have 5 entries")
        XCTAssertEqual(timelineZones.first, .burningSugar)
        XCTAssertEqual(timelineZones.last, .autophagy)
    }

    func testFastingZone_StartHours() {
        XCTAssertEqual(FastingZone.fed.startHour, 0)
        XCTAssertEqual(FastingZone.burningSugar.startHour, 0)
        XCTAssertEqual(FastingZone.fatBurning.startHour, 4)
        XCTAssertEqual(FastingZone.ketosis.startHour, 12)
        XCTAssertEqual(FastingZone.deepKetosis.startHour, 18)
        XCTAssertEqual(FastingZone.autophagy.startHour, 48)
    }

    func testFastingZone_HourMarkers() {
        XCTAssertEqual(FastingZone.fed.hourMarker, 0)
        XCTAssertEqual(FastingZone.burningSugar.hourMarker, 4)
        XCTAssertEqual(FastingZone.fatBurning.hourMarker, 12)
        XCTAssertEqual(FastingZone.ketosis.hourMarker, 18)
        XCTAssertEqual(FastingZone.deepKetosis.hourMarker, 24)
        XCTAssertEqual(FastingZone.autophagy.hourMarker, 48)
    }

    func testFastingZone_AllCasesHaveIcons() {
        for zone in FastingZone.allCases {
            XCTAssertFalse(zone.icon.isEmpty, "\(zone) should have an icon")
        }
    }

    func testFastingZone_AllCasesHaveDescriptions() {
        for zone in FastingZone.allCases {
            XCTAssertFalse(zone.description.isEmpty, "\(zone) should have a description")
        }
    }

    // MARK: - FastingPhase.fromHours Tests

    func testFastingPhase_FromHours_Fed() {
        XCTAssertEqual(FastingPhase.fromHours(0), .fed)
        XCTAssertEqual(FastingPhase.fromHours(0.3), .fed)
    }

    func testFastingPhase_FromHours_EarlyFast() {
        XCTAssertEqual(FastingPhase.fromHours(0.5), .earlyFast)
        XCTAssertEqual(FastingPhase.fromHours(2), .earlyFast)
        XCTAssertEqual(FastingPhase.fromHours(3.9), .earlyFast)
    }

    func testFastingPhase_FromHours_FatBurning() {
        XCTAssertEqual(FastingPhase.fromHours(4), .fatBurning)
        XCTAssertEqual(FastingPhase.fromHours(10), .fatBurning)
        XCTAssertEqual(FastingPhase.fromHours(15.9), .fatBurning)
    }

    func testFastingPhase_FromHours_Ketosis() {
        XCTAssertEqual(FastingPhase.fromHours(16), .ketosis)
        XCTAssertEqual(FastingPhase.fromHours(20), .ketosis)
        XCTAssertEqual(FastingPhase.fromHours(23.9), .ketosis)
    }

    func testFastingPhase_FromHours_DeepKetosis() {
        XCTAssertEqual(FastingPhase.fromHours(24), .deepKetosis)
        XCTAssertEqual(FastingPhase.fromHours(36), .deepKetosis)
        XCTAssertEqual(FastingPhase.fromHours(47.9), .deepKetosis)
    }

    func testFastingPhase_FromHours_Autophagy() {
        XCTAssertEqual(FastingPhase.fromHours(48), .autophagy)
        XCTAssertEqual(FastingPhase.fromHours(72), .autophagy)
    }

    // MARK: - FastingProtocolType Tests

    func testFastingProtocolType_FastingHours() {
        XCTAssertEqual(FastingProtocolType.sixteen8.fastingHours, 16)
        XCTAssertEqual(FastingProtocolType.eighteen6.fastingHours, 18)
        XCTAssertEqual(FastingProtocolType.twenty4.fastingHours, 20)
        XCTAssertEqual(FastingProtocolType.omad.fastingHours, 23)
        XCTAssertEqual(FastingProtocolType.fiveTwo.fastingHours, 24)
        XCTAssertEqual(FastingProtocolType.custom.fastingHours, 16)
    }

    func testFastingProtocolType_EatingHours() {
        XCTAssertEqual(FastingProtocolType.sixteen8.eatingHours, 8)
        XCTAssertEqual(FastingProtocolType.eighteen6.eatingHours, 6)
        XCTAssertEqual(FastingProtocolType.twenty4.eatingHours, 4)
        XCTAssertEqual(FastingProtocolType.omad.eatingHours, 1)
        XCTAssertEqual(FastingProtocolType.fiveTwo.eatingHours, 0)
        XCTAssertEqual(FastingProtocolType.custom.eatingHours, 8)
    }

    func testFastingProtocolType_DisplayNames() {
        XCTAssertEqual(FastingProtocolType.sixteen8.displayName, "16:8")
        XCTAssertEqual(FastingProtocolType.eighteen6.displayName, "18:6")
        XCTAssertEqual(FastingProtocolType.twenty4.displayName, "20:4")
        XCTAssertEqual(FastingProtocolType.omad.displayName, "OMAD (One Meal A Day)")
        XCTAssertEqual(FastingProtocolType.fiveTwo.displayName, "5:2 Method")
        XCTAssertEqual(FastingProtocolType.custom.displayName, "Custom")
    }

    func testFastingProtocolType_OnlySixteen8IsPopular() {
        XCTAssertTrue(FastingProtocolType.sixteen8.isPopular)
        for protocol_ in FastingProtocolType.allCases where protocol_ != .sixteen8 {
            XCTAssertFalse(protocol_.isPopular, "\(protocol_) should not be marked as popular")
        }
    }

    // MARK: - UpcomingWorkout Tests

    func testUpcomingWorkout_FastedTrainingOK_ForLowIntensity() {
        let workout = UpcomingWorkout(
            id: UUID(),
            name: "Morning Yoga",
            scheduledTime: Date().addingTimeInterval(3600),
            workoutType: "yoga"
        )
        XCTAssertTrue(workout.fastedTrainingOK, "Yoga should be OK for fasted training")
    }

    func testUpcomingWorkout_FastedTrainingOK_ForRecovery() {
        let workout = UpcomingWorkout(
            id: UUID(),
            name: "Recovery Session",
            scheduledTime: Date().addingTimeInterval(3600),
            workoutType: "recovery"
        )
        XCTAssertTrue(workout.fastedTrainingOK, "Recovery should be OK for fasted training")
    }

    func testUpcomingWorkout_FastedTrainingOK_ForMobility() {
        let workout = UpcomingWorkout(
            id: UUID(),
            name: "Mobility Work",
            scheduledTime: Date().addingTimeInterval(3600),
            workoutType: "mobility"
        )
        XCTAssertTrue(workout.fastedTrainingOK, "Mobility should be OK for fasted training")
    }

    func testUpcomingWorkout_FastedTrainingOK_ForHighIntensityFarAway() {
        let workout = UpcomingWorkout(
            id: UUID(),
            name: "Heavy Squats",
            scheduledTime: Date().addingTimeInterval(10800), // 3 hours away
            workoutType: "heavy_lifting"
        )
        XCTAssertTrue(workout.fastedTrainingOK, "Heavy lifting > 2h away should be OK")
    }

    func testUpcomingWorkout_FormattedTimeUntil_HoursAndMinutes() {
        let workout = UpcomingWorkout(
            id: UUID(),
            name: "Workout",
            scheduledTime: Date().addingTimeInterval(5400), // 1.5 hours
            workoutType: "strength"
        )
        let formatted = workout.formattedTimeUntil
        XCTAssertTrue(formatted.contains("h"), "Should contain hours marker")
        XCTAssertTrue(formatted.contains("m"), "Should contain minutes marker")
    }

    func testUpcomingWorkout_FormattedTimeUntil_MinutesOnly() {
        let workout = UpcomingWorkout(
            id: UUID(),
            name: "Warmup",
            scheduledTime: Date().addingTimeInterval(1800), // 30 minutes
            workoutType: "warmup"
        )
        let formatted = workout.formattedTimeUntil
        XCTAssertTrue(formatted.contains("m"), "Should contain minutes marker")
    }

    // MARK: - ApplyTrainingSyncSchedule Tests

    func testApplyTrainingSyncSchedule_WhenNoRecommendation_DoesNothing() {
        let initialProtocol = sut.selectedProtocol
        sut.applyTrainingSyncSchedule()
        XCTAssertEqual(sut.selectedProtocol, initialProtocol, "Protocol should not change without recommendation")
    }

    // MARK: - Edge Cases

    func testVeryLongFast_ProgressAndPhase() async throws {
        let startTime = Date().addingTimeInterval(-259200) // 72 hours
        sut.currentFast = createMockFastingLog(startTime: startTime, endTime: nil, targetHours: 72)

        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertEqual(sut.progress, 1.0, accuracy: 0.01, "Progress should be ~1.0 for completed 72h fast")
        XCTAssertEqual(sut.currentPhase, .autophagy, "Phase should be autophagy at 72 hours")
    }

    func testFastingHistory_CanBeSet() {
        let fast = createMockFastingLog(
            startTime: Date().addingTimeInterval(-57600),
            endTime: Date(),
            targetHours: 16
        )
        sut.fastingHistory = [fast]
        XCTAssertEqual(sut.fastingHistory.count, 1)

        sut.fastingHistory = []
        XCTAssertTrue(sut.fastingHistory.isEmpty)
    }

    // MARK: - Helper Methods

    /// Creates a mock active fasting log (not ended) with a start time 2 hours ago
    private func createMockActiveFast() -> FastingLog {
        return createMockFastingLog(
            startTime: Date().addingTimeInterval(-7200),
            endTime: nil,
            targetHours: 16
        )
    }

    /// Creates a mock FastingLog matching the current model initializer
    private func createMockFastingLog(startTime: Date, endTime: Date?, targetHours: Int) -> FastingLog {
        var actualHours: Double?
        if let end = endTime {
            actualHours = end.timeIntervalSince(startTime) / 3600
        }
        return FastingLog(
            id: UUID(),
            patientId: TestUUIDs.patient,
            protocolType: "intermittent",
            startedAt: startTime,
            endedAt: endTime,
            plannedHours: targetHours,
            actualHours: actualHours,
            completed: endTime != nil,
            notes: nil,
            createdAt: Date(),
            updatedAt: nil
        )
    }
}
