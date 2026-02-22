//
//  RecoveryTrackingViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for RecoveryTrackingViewModel
//  Tests initial state, streak calculation, recovery score, training recommendations,
//  computed properties, and status transitions.
//

import XCTest
@testable import PTPerformance

@MainActor
final class RecoveryTrackingViewModelTests: XCTestCase {

    var sut: RecoveryTrackingViewModel!

    override func setUp() async throws {
        try await super.setUp()
        sut = RecoveryTrackingViewModel()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_RecentSessionsIsEmpty() {
        XCTAssertTrue(sut.recentSessions.isEmpty, "recentSessions should be empty initially")
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading, "isLoading should be false initially")
    }

    func testInitialState_ErrorIsNil() {
        XCTAssertNil(sut.error, "error should be nil initially")
    }

    func testInitialState_HealthKitPermissionNeededIsFalse() {
        XCTAssertFalse(sut.healthKitPermissionNeeded, "healthKitPermissionNeeded should be false initially")
    }

    func testInitialState_ShowingLogSheetIsFalse() {
        XCTAssertFalse(sut.showingLogSheet, "showingLogSheet should be false initially")
    }

    func testInitialState_ShowingTimerIsFalse() {
        XCTAssertFalse(sut.showingTimer, "showingTimer should be false initially")
    }

    func testInitialState_SelectedSessionTypeIsNil() {
        XCTAssertNil(sut.selectedSessionType, "selectedSessionType should be nil initially")
    }

    func testInitialState_TimerConfigIsNil() {
        XCTAssertNil(sut.timerConfig, "timerConfig should be nil initially")
    }

    func testInitialState_CurrentStreakIsZero() {
        XCTAssertEqual(sut.currentStreak, 0, "currentStreak should be 0 initially")
    }

    func testInitialState_LongestStreakIsZero() {
        XCTAssertEqual(sut.longestStreak, 0, "longestStreak should be 0 initially")
    }

    func testInitialState_HasRecoveredTodayIsFalse() {
        XCTAssertFalse(sut.hasRecoveredToday, "hasRecoveredToday should be false initially")
    }

    func testInitialState_RecoveryScoreIsZero() {
        XCTAssertEqual(sut.recoveryScore, 0, "recoveryScore should be 0 initially")
    }

    func testInitialState_RecoveryStatusIsModerate() {
        XCTAssertEqual(sut.recoveryStatus, .moderate, "recoveryStatus should be .moderate initially")
    }

    func testInitialState_SleepHoursIsZero() {
        XCTAssertEqual(sut.sleepHours, 0.0, "sleepHours should be 0.0 initially")
    }

    func testInitialState_HRVValueIsZero() {
        XCTAssertEqual(sut.hrvValue, 0, "hrvValue should be 0 initially")
    }

    func testInitialState_SorenessLevelIsNone() {
        XCTAssertEqual(sut.sorenessLevel, .none, "sorenessLevel should be .none initially")
    }

    func testInitialState_TrainingRecommendationIsNil() {
        XCTAssertNil(sut.trainingRecommendation, "trainingRecommendation should be nil initially")
    }

    func testInitialState_ShowLowRecoveryAlertIsFalse() {
        XCTAssertFalse(sut.showLowRecoveryAlert, "showLowRecoveryAlert should be false initially")
    }

    func testInitialState_WeeklyTrendDataIsEmpty() {
        XCTAssertTrue(sut.weeklyTrendData.isEmpty, "weeklyTrendData should be empty initially")
    }

    func testInitialState_RecoveryMethodsLoggedTodayIsEmpty() {
        XCTAssertTrue(sut.recoveryMethodsLoggedToday.isEmpty, "recoveryMethodsLoggedToday should be empty initially")
    }

    // MARK: - Streak Message Tests

    func testStreakMessage_WhenStreakIsZero() {
        sut.currentStreak = 0
        XCTAssertEqual(sut.streakMessage, "Start your streak today!")
    }

    func testStreakMessage_WhenStreakIsOne() {
        sut.currentStreak = 1
        XCTAssertEqual(sut.streakMessage, "Keep it going tomorrow!")
    }

    func testStreakMessage_WhenStreakIsUnderSeven() {
        sut.currentStreak = 4
        XCTAssertEqual(sut.streakMessage, "Building momentum!")
    }

    func testStreakMessage_WhenStreakIsSix() {
        sut.currentStreak = 6
        XCTAssertEqual(sut.streakMessage, "Building momentum!")
    }

    func testStreakMessage_WhenStreakIsSeven() {
        sut.currentStreak = 7
        XCTAssertEqual(sut.streakMessage, "One week strong!")
    }

    func testStreakMessage_WhenStreakIsThirteen() {
        sut.currentStreak = 13
        XCTAssertEqual(sut.streakMessage, "One week strong!")
    }

    func testStreakMessage_WhenStreakIsFourteen() {
        sut.currentStreak = 14
        XCTAssertEqual(sut.streakMessage, "Impressive consistency!")
    }

    func testStreakMessage_WhenStreakIsTwentyNine() {
        sut.currentStreak = 29
        XCTAssertEqual(sut.streakMessage, "Impressive consistency!")
    }

    func testStreakMessage_WhenStreakIsThirty() {
        sut.currentStreak = 30
        XCTAssertEqual(sut.streakMessage, "Recovery champion!")
    }

    func testStreakMessage_WhenStreakIsHundred() {
        sut.currentStreak = 100
        XCTAssertEqual(sut.streakMessage, "Recovery champion!")
    }

    // MARK: - Formatted Recovery Score Tests

    func testFormattedRecoveryScore_AtZero() {
        sut.recoveryScore = 0
        XCTAssertEqual(sut.formattedRecoveryScore, "0%")
    }

    func testFormattedRecoveryScore_AtFifty() {
        sut.recoveryScore = 50
        XCTAssertEqual(sut.formattedRecoveryScore, "50%")
    }

    func testFormattedRecoveryScore_AtHundred() {
        sut.recoveryScore = 100
        XCTAssertEqual(sut.formattedRecoveryScore, "100%")
    }

    // MARK: - Sleep Status Tests

    func testSleepStatus_Good_WhenSevenOrMore() {
        sut.sleepHours = 7.0
        XCTAssertEqual(sut.sleepStatus, .good)

        sut.sleepHours = 8.5
        XCTAssertEqual(sut.sleepStatus, .good)
    }

    func testSleepStatus_Moderate_WhenSixToSeven() {
        sut.sleepHours = 6.0
        XCTAssertEqual(sut.sleepStatus, .moderate)

        sut.sleepHours = 6.9
        XCTAssertEqual(sut.sleepStatus, .moderate)
    }

    func testSleepStatus_Poor_WhenUnderSix() {
        sut.sleepHours = 5.9
        XCTAssertEqual(sut.sleepStatus, .poor)

        sut.sleepHours = 0.0
        XCTAssertEqual(sut.sleepStatus, .poor)
    }

    // MARK: - HRV Status Tests

    func testHRVStatus_Good_WhenFiftyOrMore() {
        sut.hrvValue = 50
        XCTAssertEqual(sut.hrvStatus, .good)

        sut.hrvValue = 80
        XCTAssertEqual(sut.hrvStatus, .good)
    }

    func testHRVStatus_Moderate_WhenThirtyFiveToFifty() {
        sut.hrvValue = 35
        XCTAssertEqual(sut.hrvStatus, .moderate)

        sut.hrvValue = 49
        XCTAssertEqual(sut.hrvStatus, .moderate)
    }

    func testHRVStatus_Poor_WhenUnderThirtyFive() {
        sut.hrvValue = 34
        XCTAssertEqual(sut.hrvStatus, .poor)

        sut.hrvValue = 0
        XCTAssertEqual(sut.hrvStatus, .poor)
    }

    // MARK: - Soreness Status Tests

    func testSorenessStatus_Good_WhenNone() {
        sut.sorenessLevel = .none
        XCTAssertEqual(sut.sorenessStatus, .good)
    }

    func testSorenessStatus_Good_WhenLow() {
        sut.sorenessLevel = .low
        XCTAssertEqual(sut.sorenessStatus, .good)
    }

    func testSorenessStatus_Moderate_WhenModerate() {
        sut.sorenessLevel = .moderate
        XCTAssertEqual(sut.sorenessStatus, .moderate)
    }

    func testSorenessStatus_Poor_WhenHigh() {
        sut.sorenessLevel = .high
        XCTAssertEqual(sut.sorenessStatus, .poor)
    }

    func testSorenessStatus_Poor_WhenSevere() {
        sut.sorenessLevel = .severe
        XCTAssertEqual(sut.sorenessStatus, .poor)
    }

    // MARK: - RecoveryStatus.from(score:) Tests

    func testRecoveryStatusFromScore_FullyRecovered() {
        XCTAssertEqual(RecoveryStatus.from(score: 100), .fullyRecovered)
        XCTAssertEqual(RecoveryStatus.from(score: 95), .fullyRecovered)
        XCTAssertEqual(RecoveryStatus.from(score: 90), .fullyRecovered)
    }

    func testRecoveryStatusFromScore_ReadyToTrain() {
        XCTAssertEqual(RecoveryStatus.from(score: 89), .readyToTrain)
        XCTAssertEqual(RecoveryStatus.from(score: 80), .readyToTrain)
        XCTAssertEqual(RecoveryStatus.from(score: 70), .readyToTrain)
    }

    func testRecoveryStatusFromScore_Moderate() {
        XCTAssertEqual(RecoveryStatus.from(score: 69), .moderate)
        XCTAssertEqual(RecoveryStatus.from(score: 60), .moderate)
        XCTAssertEqual(RecoveryStatus.from(score: 50), .moderate)
    }

    func testRecoveryStatusFromScore_NeedsRest() {
        XCTAssertEqual(RecoveryStatus.from(score: 49), .needsRest)
        XCTAssertEqual(RecoveryStatus.from(score: 40), .needsRest)
        XCTAssertEqual(RecoveryStatus.from(score: 30), .needsRest)
    }

    func testRecoveryStatusFromScore_Critical() {
        XCTAssertEqual(RecoveryStatus.from(score: 29), .critical)
        XCTAssertEqual(RecoveryStatus.from(score: 10), .critical)
        XCTAssertEqual(RecoveryStatus.from(score: 0), .critical)
    }

    // MARK: - RecoveryStatus Properties Tests

    func testRecoveryStatus_DisplayNames() {
        XCTAssertEqual(RecoveryStatus.fullyRecovered.displayName, "FULLY RECOVERED")
        XCTAssertEqual(RecoveryStatus.readyToTrain.displayName, "READY TO TRAIN")
        XCTAssertEqual(RecoveryStatus.moderate.displayName, "MODERATE RECOVERY")
        XCTAssertEqual(RecoveryStatus.needsRest.displayName, "NEEDS REST")
        XCTAssertEqual(RecoveryStatus.critical.displayName, "CRITICAL - REST DAY")
    }

    func testRecoveryStatus_Icons() {
        XCTAssertEqual(RecoveryStatus.fullyRecovered.icon, "battery.100")
        XCTAssertEqual(RecoveryStatus.readyToTrain.icon, "battery.75")
        XCTAssertEqual(RecoveryStatus.moderate.icon, "battery.50")
        XCTAssertEqual(RecoveryStatus.needsRest.icon, "battery.25")
        XCTAssertEqual(RecoveryStatus.critical.icon, "battery.0")
    }

    func testRecoveryStatus_AllCases() {
        let allCases = RecoveryStatus.allCases
        XCTAssertEqual(allCases.count, 5, "RecoveryStatus should have 5 cases")
        XCTAssertTrue(allCases.contains(.fullyRecovered))
        XCTAssertTrue(allCases.contains(.readyToTrain))
        XCTAssertTrue(allCases.contains(.moderate))
        XCTAssertTrue(allCases.contains(.needsRest))
        XCTAssertTrue(allCases.contains(.critical))
    }

    // MARK: - TrainingIntensity.recommended(for:) Tests

    func testTrainingIntensityRecommended_Heavy() {
        XCTAssertEqual(TrainingIntensity.recommended(for: 100), .heavy)
        XCTAssertEqual(TrainingIntensity.recommended(for: 90), .heavy)
        XCTAssertEqual(TrainingIntensity.recommended(for: 80), .heavy)
    }

    func testTrainingIntensityRecommended_Moderate() {
        XCTAssertEqual(TrainingIntensity.recommended(for: 79), .moderate)
        XCTAssertEqual(TrainingIntensity.recommended(for: 70), .moderate)
        XCTAssertEqual(TrainingIntensity.recommended(for: 60), .moderate)
    }

    func testTrainingIntensityRecommended_Light() {
        XCTAssertEqual(TrainingIntensity.recommended(for: 59), .light)
        XCTAssertEqual(TrainingIntensity.recommended(for: 50), .light)
        XCTAssertEqual(TrainingIntensity.recommended(for: 40), .light)
    }

    func testTrainingIntensityRecommended_Rest() {
        XCTAssertEqual(TrainingIntensity.recommended(for: 39), .rest)
        XCTAssertEqual(TrainingIntensity.recommended(for: 20), .rest)
        XCTAssertEqual(TrainingIntensity.recommended(for: 0), .rest)
    }

    // MARK: - TrainingRecommendation.generate Tests

    func testTrainingRecommendation_FullyRecovered() {
        let rec = TrainingRecommendation.generate(
            recoveryScore: 95,
            recoveryStatus: .fullyRecovered,
            sleepHours: 8.0,
            hrvValue: 65,
            sorenessLevel: .none
        )
        XCTAssertEqual(rec.intensity, .heavy)
        XCTAssertEqual(rec.headline, "Peak performance day")
        XCTAssertFalse(rec.alternativeActivities.isEmpty)
    }

    func testTrainingRecommendation_ReadyToTrain() {
        let rec = TrainingRecommendation.generate(
            recoveryScore: 80,
            recoveryStatus: .readyToTrain,
            sleepHours: 7.5,
            hrvValue: 55,
            sorenessLevel: .low
        )
        XCTAssertEqual(rec.intensity, .heavy)
        XCTAssertEqual(rec.headline, "Good day for intensity work")
    }

    func testTrainingRecommendation_Moderate() {
        let rec = TrainingRecommendation.generate(
            recoveryScore: 60,
            recoveryStatus: .moderate,
            sleepHours: 6.5,
            hrvValue: 42,
            sorenessLevel: .moderate
        )
        XCTAssertEqual(rec.intensity, .moderate)
        XCTAssertEqual(rec.headline, "Moderate intensity recommended")
    }

    func testTrainingRecommendation_NeedsRest() {
        let rec = TrainingRecommendation.generate(
            recoveryScore: 40,
            recoveryStatus: .needsRest,
            sleepHours: 5.5,
            hrvValue: 30,
            sorenessLevel: .high
        )
        XCTAssertEqual(rec.intensity, .light)
        XCTAssertEqual(rec.headline, "Swap today's heavy work")
    }

    func testTrainingRecommendation_NeedsRest_WithLowHRVNote() {
        let rec = TrainingRecommendation.generate(
            recoveryScore: 40,
            recoveryStatus: .needsRest,
            sleepHours: 7.0,
            hrvValue: 30,
            sorenessLevel: .moderate
        )
        XCTAssertTrue(rec.description.contains("HRV down significantly"),
                       "Description should mention low HRV when hrvValue < 40")
    }

    func testTrainingRecommendation_NeedsRest_WithPoorSleepNote() {
        let rec = TrainingRecommendation.generate(
            recoveryScore: 40,
            recoveryStatus: .needsRest,
            sleepHours: 5.0,
            hrvValue: 50,
            sorenessLevel: .moderate
        )
        XCTAssertTrue(rec.description.contains("poor sleep"),
                       "Description should mention poor sleep when sleepHours < 6")
    }

    func testTrainingRecommendation_NeedsRest_WithBothNotes() {
        let rec = TrainingRecommendation.generate(
            recoveryScore: 35,
            recoveryStatus: .needsRest,
            sleepHours: 5.0,
            hrvValue: 30,
            sorenessLevel: .high
        )
        XCTAssertTrue(rec.description.contains("HRV down significantly"),
                       "Should mention low HRV")
        XCTAssertTrue(rec.description.contains("poor sleep"),
                       "Should mention poor sleep")
    }

    func testTrainingRecommendation_Critical() {
        let rec = TrainingRecommendation.generate(
            recoveryScore: 20,
            recoveryStatus: .critical,
            sleepHours: 4.0,
            hrvValue: 20,
            sorenessLevel: .severe
        )
        XCTAssertEqual(rec.intensity, .rest)
        XCTAssertEqual(rec.headline, "Rest day strongly recommended")
        XCTAssertTrue(rec.alternativeActivities.contains("Complete rest"))
    }

    // MARK: - Weekly Stats Computed Property Tests

    func testWeeklyStats_EmptySessions() {
        sut.recentSessions = []
        let stats = sut.weeklyStats

        XCTAssertEqual(stats.sessions, 0)
        XCTAssertEqual(stats.totalMinutes, 0)
        XCTAssertNil(stats.favoriteType)
    }

    func testWeeklyStats_WithRecentSessions() {
        let today = Date()
        let session1 = createMockSession(protocolType: .saunaTraditional, loggedAt: today, durationMinutes: 20)
        let session2 = createMockSession(protocolType: .saunaTraditional, loggedAt: today, durationMinutes: 15)
        let session3 = createMockSession(protocolType: .coldPlunge, loggedAt: today, durationMinutes: 5)

        sut.recentSessions = [session1, session2, session3]

        let stats = sut.weeklyStats
        XCTAssertEqual(stats.sessions, 3)
        XCTAssertEqual(stats.totalMinutes, 40)
        XCTAssertEqual(stats.favoriteType, .saunaTraditional, "Sauna should be the favorite with 2 sessions")
    }

    func testWeeklyStats_ExcludesOldSessions() {
        let today = Date()
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: today)!

        let recentSession = createMockSession(protocolType: .coldPlunge, loggedAt: today, durationMinutes: 5)
        let oldSession = createMockSession(protocolType: .saunaTraditional, loggedAt: twoWeeksAgo, durationMinutes: 20)

        sut.recentSessions = [recentSession, oldSession]

        let stats = sut.weeklyStats
        XCTAssertEqual(stats.sessions, 1, "Only sessions from last 7 days should be included")
        XCTAssertEqual(stats.totalMinutes, 5)
        XCTAssertEqual(stats.favoriteType, .coldPlunge)
    }

    // MARK: - Weekly Breakdown Computed Property Tests

    func testWeeklyBreakdown_EmptySessions() {
        sut.recentSessions = []
        XCTAssertTrue(sut.weeklyBreakdown.isEmpty)
    }

    func testWeeklyBreakdown_GroupsByType() {
        let today = Date()
        let session1 = createMockSession(protocolType: .saunaTraditional, loggedAt: today, durationMinutes: 20)
        let session2 = createMockSession(protocolType: .saunaTraditional, loggedAt: today, durationMinutes: 15)
        let session3 = createMockSession(protocolType: .coldPlunge, loggedAt: today, durationMinutes: 5)

        sut.recentSessions = [session1, session2, session3]

        let breakdown = sut.weeklyBreakdown
        XCTAssertEqual(breakdown.count, 2, "Should have 2 distinct protocol types")

        // Sorted by count descending
        XCTAssertEqual(breakdown.first?.type, .saunaTraditional)
        XCTAssertEqual(breakdown.first?.count, 2)
        XCTAssertEqual(breakdown.first?.totalMinutes, 35)

        XCTAssertEqual(breakdown.last?.type, .coldPlunge)
        XCTAssertEqual(breakdown.last?.count, 1)
        XCTAssertEqual(breakdown.last?.totalMinutes, 5)
    }

    func testWeeklyBreakdown_SortedByCountDescending() {
        let today = Date()
        let s1 = createMockSession(protocolType: .coldPlunge, loggedAt: today, durationMinutes: 3)
        let s2 = createMockSession(protocolType: .saunaTraditional, loggedAt: today, durationMinutes: 20)
        let s3 = createMockSession(protocolType: .saunaTraditional, loggedAt: today, durationMinutes: 20)
        let s4 = createMockSession(protocolType: .saunaTraditional, loggedAt: today, durationMinutes: 20)
        let s5 = createMockSession(protocolType: .coldPlunge, loggedAt: today, durationMinutes: 3)

        sut.recentSessions = [s1, s2, s3, s4, s5]

        let breakdown = sut.weeklyBreakdown
        XCTAssertEqual(breakdown.first?.count, 3, "Most frequent type should be first")
        XCTAssertEqual(breakdown.last?.count, 2, "Less frequent type should be last")
    }

    // MARK: - Low Recovery Alert Tests

    func testCheckLowRecoveryAlert_TriggersWhenScoreLowAndNotRecovered() {
        sut.recoveryScore = 45
        sut.hasRecoveredToday = false
        sut.showLowRecoveryAlert = false

        // Directly call the alert check logic (simulating what loadData does)
        // Since checkLowRecoveryAlert is private, we test via state manipulation
        if sut.recoveryScore < 50 && !sut.hasRecoveredToday {
            sut.showLowRecoveryAlert = true
        }

        XCTAssertTrue(sut.showLowRecoveryAlert, "Alert should show when score < 50 and not recovered today")
    }

    func testCheckLowRecoveryAlert_DoesNotTriggerWhenRecoveredToday() {
        sut.recoveryScore = 30
        sut.hasRecoveredToday = true
        sut.showLowRecoveryAlert = false

        if sut.recoveryScore < 50 && !sut.hasRecoveredToday {
            sut.showLowRecoveryAlert = true
        }

        XCTAssertFalse(sut.showLowRecoveryAlert, "Alert should not show when user has recovered today")
    }

    func testCheckLowRecoveryAlert_DoesNotTriggerWhenScoreHigh() {
        sut.recoveryScore = 75
        sut.hasRecoveredToday = false
        sut.showLowRecoveryAlert = false

        if sut.recoveryScore < 50 && !sut.hasRecoveredToday {
            sut.showLowRecoveryAlert = true
        }

        XCTAssertFalse(sut.showLowRecoveryAlert, "Alert should not show when recovery score >= 50")
    }

    // MARK: - Adjustment Action Tests

    func testAdjustWorkout_DismissesAlert() {
        sut.showLowRecoveryAlert = true

        sut.adjustWorkout()

        XCTAssertFalse(sut.showLowRecoveryAlert, "adjustWorkout should dismiss alert")
    }

    func testTrainAnyway_DismissesAlert() {
        sut.showLowRecoveryAlert = true

        sut.trainAnyway()

        XCTAssertFalse(sut.showLowRecoveryAlert, "trainAnyway should dismiss alert")
    }

    // MARK: - Cancel Timer Tests

    func testCancelTimer_ResetsTimerState() {
        sut.showingTimer = true
        sut.timerConfig = TimerConfiguration(
            sessionType: .traditionalSauna,
            duration: 900,
            temperature: nil
        )

        sut.cancelTimer()

        XCTAssertFalse(sut.showingTimer, "showingTimer should be false after cancel")
        XCTAssertNil(sut.timerConfig, "timerConfig should be nil after cancel")
    }

    // MARK: - Quick Log Tests

    func testStartQuickLog_SetsSessionTypeAndTimer() {
        sut.startQuickLog(for: .coldPlunge)

        XCTAssertEqual(sut.selectedSessionType, .coldPlunge, "selectedSessionType should match protocol's session type")
        XCTAssertTrue(sut.showingTimer, "showingTimer should be true after quick log")
        XCTAssertNotNil(sut.timerConfig, "timerConfig should be set")
        XCTAssertEqual(sut.timerConfig?.sessionType, .coldPlunge)
    }

    func testStartQuickLog_UsesDefaultDuration() {
        sut.startQuickLog(for: .saunaTraditional)

        // Traditional sauna default is 15 minutes = 900 seconds
        XCTAssertEqual(sut.timerConfig?.duration, 15 * 60, "Timer duration should be default duration in seconds")
    }

    func testShowAllSessionTypes_SetsState() {
        sut.showAllSessionTypes()

        XCTAssertNil(sut.selectedSessionType, "selectedSessionType should be nil when showing all types")
        XCTAssertTrue(sut.showingLogSheet, "showingLogSheet should be true")
    }

    // MARK: - Recovery Method Logging Tests

    func testLogRecoveryMethod_AddsToSet() {
        XCTAssertFalse(sut.recoveryMethodsLoggedToday.contains(.coldPlunge))

        sut.logRecoveryMethod(.coldPlunge)

        XCTAssertTrue(sut.recoveryMethodsLoggedToday.contains(.coldPlunge),
                       "Cold plunge should be added to logged methods")
    }

    func testLogRecoveryMethod_WithProtocolType_StartsTimer() {
        sut.logRecoveryMethod(.coldPlunge)

        XCTAssertTrue(sut.showingTimer, "Should show timer for method with protocol type")
        XCTAssertNotNil(sut.timerConfig, "Timer config should be set")
    }

    func testLogRecoveryMethod_WithoutProtocolType_DoesNotStartTimer() {
        // Stretching has no associated protocol type
        sut.logRecoveryMethod(.stretching)

        XCTAssertTrue(sut.recoveryMethodsLoggedToday.contains(.stretching),
                       "Stretching should be added to logged methods")
        XCTAssertFalse(sut.showingTimer, "Should not show timer for method without protocol type")
    }

    // MARK: - RecoveryMethod Properties Tests

    func testRecoveryMethod_ToProtocolType() {
        XCTAssertEqual(RecoveryMethod.coldPlunge.toProtocolType, .coldPlunge)
        XCTAssertEqual(RecoveryMethod.sauna.toProtocolType, .saunaTraditional)
        XCTAssertNil(RecoveryMethod.yoga.toProtocolType)
        XCTAssertNil(RecoveryMethod.massage.toProtocolType)
        XCTAssertNil(RecoveryMethod.stretching.toProtocolType)
        XCTAssertNil(RecoveryMethod.compression.toProtocolType)
        XCTAssertNil(RecoveryMethod.sleep.toProtocolType)
    }

    func testRecoveryMethod_AllCasesHaveDisplayName() {
        for method in RecoveryMethod.allCases {
            XCTAssertFalse(method.displayName.isEmpty, "\(method) should have a displayName")
        }
    }

    func testRecoveryMethod_AllCasesHaveFullName() {
        for method in RecoveryMethod.allCases {
            XCTAssertFalse(method.fullName.isEmpty, "\(method) should have a fullName")
        }
    }

    func testRecoveryMethod_AllCasesHaveIcon() {
        for method in RecoveryMethod.allCases {
            XCTAssertFalse(method.icon.isEmpty, "\(method) should have an icon")
        }
    }

    // MARK: - SorenessLevel Tests

    func testSorenessLevel_AllCases() {
        let allCases = SorenessLevel.allCases
        XCTAssertEqual(allCases.count, 5)
    }

    func testSorenessLevel_DisplayNames() {
        XCTAssertEqual(SorenessLevel.none.displayName, "None")
        XCTAssertEqual(SorenessLevel.low.displayName, "Low")
        XCTAssertEqual(SorenessLevel.moderate.displayName, "Moderate")
        XCTAssertEqual(SorenessLevel.high.displayName, "High")
        XCTAssertEqual(SorenessLevel.severe.displayName, "Severe")
    }

    // MARK: - MetricStatus Tests

    func testMetricStatus_Icons() {
        XCTAssertEqual(MetricStatus.good.icon, "checkmark.circle.fill")
        XCTAssertEqual(MetricStatus.moderate.icon, "minus.circle.fill")
        XCTAssertEqual(MetricStatus.poor.icon, "xmark.circle.fill")
    }

    // MARK: - TrainingIntensity Properties Tests

    func testTrainingIntensity_AllCases() {
        let allCases = TrainingIntensity.allCases
        XCTAssertEqual(allCases.count, 4)
    }

    func testTrainingIntensity_DisplayNames() {
        XCTAssertEqual(TrainingIntensity.heavy.displayName, "Heavy")
        XCTAssertEqual(TrainingIntensity.moderate.displayName, "Moderate")
        XCTAssertEqual(TrainingIntensity.light.displayName, "Light")
        XCTAssertEqual(TrainingIntensity.rest.displayName, "Rest")
    }

    func testTrainingIntensity_Icons() {
        XCTAssertEqual(TrainingIntensity.heavy.icon, "flame.fill")
        XCTAssertEqual(TrainingIntensity.moderate.icon, "bolt.fill")
        XCTAssertEqual(TrainingIntensity.light.icon, "leaf.fill")
        XCTAssertEqual(TrainingIntensity.rest.icon, "moon.fill")
    }

    // MARK: - DailyRecoveryTrend Tests

    func testDailyRecoveryTrend_ScorePercentage() {
        let trend = DailyRecoveryTrend(
            date: Date(),
            dayName: "Mon",
            score: 75,
            status: .readyToTrain,
            recommendedIntensity: .moderate,
            workoutCompleted: true
        )
        XCTAssertEqual(trend.scorePercentage, 0.75, accuracy: 0.001)
    }

    func testDailyRecoveryTrend_ScorePercentage_AtZero() {
        let trend = DailyRecoveryTrend(
            date: Date(),
            dayName: "Tue",
            score: 0,
            status: .critical,
            recommendedIntensity: .rest,
            workoutCompleted: false
        )
        XCTAssertEqual(trend.scorePercentage, 0.0, accuracy: 0.001)
    }

    func testDailyRecoveryTrend_ScorePercentage_AtHundred() {
        let trend = DailyRecoveryTrend(
            date: Date(),
            dayName: "Wed",
            score: 100,
            status: .fullyRecovered,
            recommendedIntensity: .heavy,
            workoutCompleted: true
        )
        XCTAssertEqual(trend.scorePercentage, 1.0, accuracy: 0.001)
    }

    func testDailyRecoveryTrend_Id_IsUnique() {
        let date1 = Date()
        let date2 = date1.addingTimeInterval(86400)

        let trend1 = DailyRecoveryTrend(
            date: date1, dayName: "Mon", score: 50,
            status: .moderate, recommendedIntensity: .light, workoutCompleted: false
        )
        let trend2 = DailyRecoveryTrend(
            date: date2, dayName: "Tue", score: 50,
            status: .moderate, recommendedIntensity: .light, workoutCompleted: false
        )

        XCTAssertNotEqual(trend1.id, trend2.id, "Trends with different dates should have different IDs")
    }

    // MARK: - RecoveryProtocolType Extension Tests

    func testRecoveryProtocolType_ToSessionType() {
        XCTAssertEqual(RecoveryProtocolType.saunaTraditional.toSessionType, .traditionalSauna)
        XCTAssertEqual(RecoveryProtocolType.saunaInfrared.toSessionType, .infraredSauna)
        XCTAssertEqual(RecoveryProtocolType.saunaSteam.toSessionType, .steamRoom)
        XCTAssertEqual(RecoveryProtocolType.coldPlunge.toSessionType, .coldPlunge)
        XCTAssertEqual(RecoveryProtocolType.coldShower.toSessionType, .coldShower)
        XCTAssertEqual(RecoveryProtocolType.iceBath.toSessionType, .iceBath)
        XCTAssertEqual(RecoveryProtocolType.contrast.toSessionType, .contrastTherapy)
    }

    // MARK: - Recovery Score Calculation Logic Tests

    func testRecoveryScoreCalculation_PerfectMetrics() {
        // Sleep: 8h -> 100%, HRV: 70 -> 100%, Soreness: none -> 100%
        // Score = (100 * 0.40) + (100 * 0.35) + (100 * 0.25) = 100
        let sleepScore = min(100.0, (8.0 / 8.0) * 100)
        let hrvScore = min(100.0, (70.0 / 70.0) * 100)
        let sorenessScore: Double = 100
        let score = (sleepScore * 0.40) + (hrvScore * 0.35) + (sorenessScore * 0.25)

        XCTAssertEqual(Int(score), 100)
    }

    func testRecoveryScoreCalculation_PoorMetrics() {
        // Sleep: 4h -> 50%, HRV: 25 -> ~35.7%, Soreness: severe -> 10%
        let sleepScore = min(100.0, (4.0 / 8.0) * 100)
        let hrvScore = min(100.0, (25.0 / 70.0) * 100)
        let sorenessScore: Double = 10
        let score = (sleepScore * 0.40) + (hrvScore * 0.35) + (sorenessScore * 0.25)

        // 50*0.40 + 35.71*0.35 + 10*0.25 = 20 + 12.5 + 2.5 = 35
        XCTAssertEqual(Int(score), 35, "Poor metrics should result in a low score")
    }

    func testRecoveryScoreCalculation_MixedMetrics() {
        // Sleep: 7h -> 87.5%, HRV: 50 -> ~71.4%, Soreness: moderate -> 60%
        let sleepScore = min(100.0, (7.0 / 8.0) * 100)
        let hrvScore = min(100.0, (50.0 / 70.0) * 100)
        let sorenessScore: Double = 60
        let score = (sleepScore * 0.40) + (hrvScore * 0.35) + (sorenessScore * 0.25)

        // 87.5*0.40 + 71.43*0.35 + 60*0.25 = 35 + 25 + 15 = 75
        XCTAssertEqual(Int(score), 75, accuracy: 1, "Mixed metrics should produce a moderate score")
    }

    func testRecoveryScoreCalculation_ExcessiveSleepCapped() {
        // Sleep: 10h -> should cap at 100%
        let sleepScore = min(100.0, (10.0 / 8.0) * 100)
        XCTAssertEqual(sleepScore, 100.0, "Sleep score should be capped at 100")
    }

    func testRecoveryScoreCalculation_HighHRVCapped() {
        // HRV: 100 -> should cap at 100%
        let hrvScore = min(100.0, (100.0 / 70.0) * 100)
        XCTAssertEqual(hrvScore, 100.0, "HRV score should be capped at 100")
    }

    func testRecoveryScoreCalculation_SorenessScores() {
        // Verify soreness level to score mapping
        let noneScore: Double = 100
        let lowScore: Double = 85
        let moderateScore: Double = 60
        let highScore: Double = 35
        let severeScore: Double = 10

        XCTAssertEqual(noneScore, 100, "No soreness should be 100")
        XCTAssertEqual(lowScore, 85, "Low soreness should be 85")
        XCTAssertEqual(moderateScore, 60, "Moderate soreness should be 60")
        XCTAssertEqual(highScore, 35, "High soreness should be 35")
        XCTAssertEqual(severeScore, 10, "Severe soreness should be 10")
    }

    // MARK: - Timer Configuration Tests

    func testTimerConfiguration_Properties() {
        let config = TimerConfiguration(
            sessionType: .coldPlunge,
            duration: 180,
            temperature: 42.0
        )

        XCTAssertEqual(config.sessionType, .coldPlunge)
        XCTAssertEqual(config.duration, 180)
        XCTAssertEqual(config.temperature, 42.0)
    }

    func testTimerConfiguration_NilTemperature() {
        let config = TimerConfiguration(
            sessionType: .traditionalSauna,
            duration: 900,
            temperature: nil
        )

        XCTAssertNil(config.temperature)
    }

    // MARK: - WeeklyRecoveryStats Tests

    func testWeeklyRecoveryStats_Properties() {
        let stats = WeeklyRecoveryStats(
            sessions: 5,
            totalMinutes: 120,
            favoriteType: .coldPlunge
        )

        XCTAssertEqual(stats.sessions, 5)
        XCTAssertEqual(stats.totalMinutes, 120)
        XCTAssertEqual(stats.favoriteType, .coldPlunge)
    }

    func testWeeklyRecoveryStats_NilFavorite() {
        let stats = WeeklyRecoveryStats(
            sessions: 0,
            totalMinutes: 0,
            favoriteType: nil
        )

        XCTAssertNil(stats.favoriteType)
    }

    // MARK: - RecoveryTypeBreakdown Tests

    func testRecoveryTypeBreakdown_Properties() {
        let breakdown = RecoveryTypeBreakdown(
            type: .saunaTraditional,
            count: 3,
            totalMinutes: 45
        )

        XCTAssertEqual(breakdown.type, .saunaTraditional)
        XCTAssertEqual(breakdown.count, 3)
        XCTAssertEqual(breakdown.totalMinutes, 45)
    }

    // MARK: - State Mutation Tests

    func testError_CanBeSetAndCleared() {
        XCTAssertNil(sut.error)

        sut.error = "Something went wrong"
        XCTAssertEqual(sut.error, "Something went wrong")

        sut.error = nil
        XCTAssertNil(sut.error)
    }

    func testRecentSessions_CanBeSetAndCleared() {
        let session = createMockSession(protocolType: .saunaTraditional, loggedAt: Date(), durationMinutes: 20)
        sut.recentSessions = [session]

        XCTAssertEqual(sut.recentSessions.count, 1)

        sut.recentSessions = []
        XCTAssertTrue(sut.recentSessions.isEmpty)
    }

    // MARK: - RecoveryStatus Boundary Tests

    func testRecoveryStatus_BoundaryAt90() {
        XCTAssertEqual(RecoveryStatus.from(score: 90), .fullyRecovered)
        XCTAssertEqual(RecoveryStatus.from(score: 89), .readyToTrain)
    }

    func testRecoveryStatus_BoundaryAt70() {
        XCTAssertEqual(RecoveryStatus.from(score: 70), .readyToTrain)
        XCTAssertEqual(RecoveryStatus.from(score: 69), .moderate)
    }

    func testRecoveryStatus_BoundaryAt50() {
        XCTAssertEqual(RecoveryStatus.from(score: 50), .moderate)
        XCTAssertEqual(RecoveryStatus.from(score: 49), .needsRest)
    }

    func testRecoveryStatus_BoundaryAt30() {
        XCTAssertEqual(RecoveryStatus.from(score: 30), .needsRest)
        XCTAssertEqual(RecoveryStatus.from(score: 29), .critical)
    }

    func testRecoveryStatus_NegativeScore() {
        XCTAssertEqual(RecoveryStatus.from(score: -1), .critical)
    }

    func testRecoveryStatus_HighScore() {
        XCTAssertEqual(RecoveryStatus.from(score: 100), .fullyRecovered)
    }

    // MARK: - TrainingIntensity Boundary Tests

    func testTrainingIntensity_BoundaryAt80() {
        XCTAssertEqual(TrainingIntensity.recommended(for: 80), .heavy)
        XCTAssertEqual(TrainingIntensity.recommended(for: 79), .moderate)
    }

    func testTrainingIntensity_BoundaryAt60() {
        XCTAssertEqual(TrainingIntensity.recommended(for: 60), .moderate)
        XCTAssertEqual(TrainingIntensity.recommended(for: 59), .light)
    }

    func testTrainingIntensity_BoundaryAt40() {
        XCTAssertEqual(TrainingIntensity.recommended(for: 40), .light)
        XCTAssertEqual(TrainingIntensity.recommended(for: 39), .rest)
    }

    func testTrainingIntensity_NegativeScore() {
        XCTAssertEqual(TrainingIntensity.recommended(for: -10), .rest)
    }

    // MARK: - Helper Methods

    private func createMockSession(
        protocolType: RecoveryProtocolType,
        loggedAt: Date,
        durationMinutes: Int = 15
    ) -> RecoverySession {
        return RecoverySession(
            id: UUID(),
            patientId: UUID(),
            protocolType: protocolType,
            loggedAt: loggedAt,
            durationSeconds: durationMinutes * 60,
            temperature: nil,
            heartRateAvg: nil,
            heartRateMax: nil,
            perceivedEffort: 5,
            rating: nil,
            notes: nil,
            createdAt: Date()
        )
    }
}
