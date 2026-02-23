//
//  BodyCompGoalsViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for BodyCompGoalsViewModel
//  Tests initial state, computed properties, progress calculations,
//  projected completion dates, formatting, goal metric logic, and edge cases.
//

import XCTest
@testable import PTPerformance

@MainActor
final class BodyCompGoalsViewModelTests: XCTestCase {

    var sut: BodyCompGoalsViewModel!

    override func setUp() async throws {
        try await super.setUp()
        sut = BodyCompGoalsViewModel()
        // Reset state that may have been set during init's Task
        sut.isLoading = false
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_CurrentGoalsIsNil() {
        XCTAssertNil(sut.currentGoals, "currentGoals should be nil initially")
    }

    func testInitialState_CurrentProgressIsNil() {
        XCTAssertNil(sut.currentProgress, "currentProgress should be nil initially")
    }

    func testInitialState_AllGoalsIsEmpty() {
        XCTAssertTrue(sut.allGoals.isEmpty, "allGoals should be empty initially")
    }

    func testInitialState_IsSavingIsFalse() {
        XCTAssertFalse(sut.isSaving, "isSaving should be false initially")
    }

    func testInitialState_ErrorIsNil() {
        XCTAssertNil(sut.error, "error should be nil initially")
    }

    func testInitialState_ShowingSuccessAlertIsFalse() {
        XCTAssertFalse(sut.showingSuccessAlert, "showingSuccessAlert should be false initially")
    }

    func testInitialState_ShowingGoalAchievedAlertIsFalse() {
        XCTAssertFalse(sut.showingGoalAchievedAlert, "showingGoalAchievedAlert should be false initially")
    }

    func testInitialState_LatestWeightIsNil() {
        XCTAssertNil(sut.latestWeight, "latestWeight should be nil initially")
    }

    func testInitialState_LatestBodyFatIsNil() {
        XCTAssertNil(sut.latestBodyFat, "latestBodyFat should be nil initially")
    }

    func testInitialState_LatestMuscleMassIsNil() {
        XCTAssertNil(sut.latestMuscleMass, "latestMuscleMass should be nil initially")
    }

    // MARK: - hasActiveGoals Computed Property

    func testHasActiveGoals_WhenNoGoals() {
        sut.currentGoals = nil
        XCTAssertFalse(sut.hasActiveGoals, "Should be false when no goals")
    }

    func testHasActiveGoals_WhenActiveGoal() {
        sut.currentGoals = createMockGoal(status: .active)
        XCTAssertTrue(sut.hasActiveGoals, "Should be true when active goal exists")
    }

    func testHasActiveGoals_WhenPausedGoal() {
        sut.currentGoals = createMockGoal(status: .paused)
        XCTAssertFalse(sut.hasActiveGoals, "Should be false when goal is paused")
    }

    func testHasActiveGoals_WhenAchievedGoal() {
        sut.currentGoals = createMockGoal(status: .achieved)
        XCTAssertFalse(sut.hasActiveGoals, "Should be false when goal is achieved")
    }

    func testHasActiveGoals_WhenCancelledGoal() {
        sut.currentGoals = createMockGoal(status: .cancelled)
        XCTAssertFalse(sut.hasActiveGoals, "Should be false when goal is cancelled")
    }

    // MARK: - progressStatus Computed Property

    func testProgressStatus_WhenNoGoals() {
        sut.currentGoals = nil
        XCTAssertEqual(sut.progressStatus, .onTrack, "Should default to onTrack when no goals")
    }

    // MARK: - weightProgress Computed Property

    func testWeightProgress_WhenNoGoals() {
        sut.currentGoals = nil
        sut.currentProgress = nil
        XCTAssertEqual(sut.weightProgress, 0, "Should be 0 when no goals set")
    }

    func testWeightProgress_FromProgressView() {
        sut.currentProgress = createMockProgress(weightProgressPct: 75.0)
        XCTAssertEqual(sut.weightProgress, 0.75, accuracy: 0.01, "Should convert percentage to 0-1 range")
    }

    func testWeightProgress_FromProgressView_CappedAtOne() {
        sut.currentProgress = createMockProgress(weightProgressPct: 150.0)
        XCTAssertEqual(sut.weightProgress, 1.0, accuracy: 0.01, "Should cap at 1.0")
    }

    func testWeightProgress_FromProgressView_MinZero() {
        sut.currentProgress = createMockProgress(weightProgressPct: -10.0)
        XCTAssertEqual(sut.weightProgress, 0, accuracy: 0.01, "Should not go below 0")
    }

    func testWeightProgress_FromGoalCalculation() {
        sut.currentProgress = nil
        sut.currentGoals = createMockGoal(
            targetWeight: 180,
            startingWeight: 200
        )
        sut.latestWeight = 190

        // Progress: (190-200)/(180-200) = -10/-20 = 0.5
        XCTAssertEqual(sut.weightProgress, 0.5, accuracy: 0.01, "Should calculate 50% progress")
    }

    func testWeightProgress_FromGoalCalculation_WhenNoLatestWeight() {
        sut.currentProgress = nil
        sut.currentGoals = createMockGoal(targetWeight: 180, startingWeight: 200)
        sut.latestWeight = nil
        XCTAssertEqual(sut.weightProgress, 0, accuracy: 0.01, "Should be 0 when no current weight")
    }

    // MARK: - bodyFatProgress Computed Property

    func testBodyFatProgress_WhenNoGoals() {
        sut.currentGoals = nil
        sut.currentProgress = nil
        XCTAssertEqual(sut.bodyFatProgress, 0, "Should be 0 when no goals")
    }

    func testBodyFatProgress_FromProgressView() {
        sut.currentProgress = createMockProgress(bodyFatProgressPct: 60.0)
        XCTAssertEqual(sut.bodyFatProgress, 0.6, accuracy: 0.01)
    }

    func testBodyFatProgress_CappedAtOne() {
        sut.currentProgress = createMockProgress(bodyFatProgressPct: 200.0)
        XCTAssertEqual(sut.bodyFatProgress, 1.0, accuracy: 0.01)
    }

    func testBodyFatProgress_FromGoalCalculation() {
        sut.currentProgress = nil
        sut.currentGoals = createMockGoal(
            targetBodyFatPercentage: 12.0,
            startingBodyFatPercentage: 20.0
        )
        sut.latestBodyFat = 16.0

        // Progress: (16-20)/(12-20) = -4/-8 = 0.5
        XCTAssertEqual(sut.bodyFatProgress, 0.5, accuracy: 0.01)
    }

    // MARK: - muscleMassProgress Computed Property

    func testMuscleMassProgress_WhenNoGoals() {
        sut.currentGoals = nil
        sut.currentProgress = nil
        XCTAssertEqual(sut.muscleMassProgress, 0, "Should be 0 when no goals")
    }

    func testMuscleMassProgress_FromProgressView() {
        sut.currentProgress = createMockProgress(muscleMassProgressPct: 40.0)
        XCTAssertEqual(sut.muscleMassProgress, 0.4, accuracy: 0.01)
    }

    func testMuscleMassProgress_FromGoalCalculation() {
        sut.currentProgress = nil
        sut.currentGoals = createMockGoal(
            targetMuscleMass: 170.0,
            startingMuscleMass: 150.0
        )
        sut.latestMuscleMass = 160.0

        // Progress: (160-150)/(170-150) = 10/20 = 0.5
        XCTAssertEqual(sut.muscleMassProgress, 0.5, accuracy: 0.01)
    }

    // MARK: - weeklyWeightChange Computed Property

    func testWeeklyWeightChange_WhenNoGoals() {
        sut.currentGoals = nil
        XCTAssertNil(sut.weeklyWeightChange, "Should be nil when no goals")
    }

    func testWeeklyWeightChange_WhenNoLatestWeight() {
        sut.currentGoals = createMockGoal(targetWeight: 180)
        sut.latestWeight = nil
        XCTAssertNil(sut.weeklyWeightChange, "Should be nil when no current weight")
    }

    func testWeeklyWeightChange_WithValidData() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 70, to: Date())!
        sut.currentGoals = createMockGoal(
            targetWeight: 170,
            targetDate: futureDate
        )
        sut.latestWeight = 180

        let change = sut.weeklyWeightChange
        XCTAssertNotNil(change, "Should calculate weekly change")
        if let change = change {
            XCTAssertTrue(change < 0, "Weekly change should be negative for weight loss goal")
        }
    }

    // MARK: - weeklyBodyFatChange Computed Property

    func testWeeklyBodyFatChange_WhenNoGoals() {
        sut.currentGoals = nil
        XCTAssertNil(sut.weeklyBodyFatChange, "Should be nil when no goals")
    }

    func testWeeklyBodyFatChange_WhenNoLatestBodyFat() {
        sut.currentGoals = createMockGoal(targetBodyFatPercentage: 12.0)
        sut.latestBodyFat = nil
        XCTAssertNil(sut.weeklyBodyFatChange, "Should be nil when no current body fat")
    }

    // MARK: - daysRemaining Computed Property

    func testDaysRemaining_FromProgress() {
        sut.currentProgress = createMockProgress(daysRemaining: 45)
        XCTAssertEqual(sut.daysRemaining, 45)
    }

    func testDaysRemaining_FromGoalWhenNoProgress() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        sut.currentProgress = nil
        sut.currentGoals = createMockGoal(targetDate: futureDate)

        let days = sut.daysRemaining
        XCTAssertNotNil(days)
        // Should be approximately 30 (depending on exact timing)
        if let days = days {
            XCTAssertTrue(days >= 29 && days <= 31, "Days remaining should be approximately 30, got \(days)")
        }
    }

    func testDaysRemaining_NilWhenNoGoalsOrProgress() {
        sut.currentProgress = nil
        sut.currentGoals = nil
        XCTAssertNil(sut.daysRemaining)
    }

    func testDaysRemaining_ProgressTakesPrecedence() {
        sut.currentProgress = createMockProgress(daysRemaining: 10)
        let futureDate = Calendar.current.date(byAdding: .day, value: 50, to: Date())!
        sut.currentGoals = createMockGoal(targetDate: futureDate)

        XCTAssertEqual(sut.daysRemaining, 10, "Progress daysRemaining should take precedence")
    }

    // MARK: - targetDateText Computed Property

    func testTargetDateText_WhenNoGoals() {
        sut.currentGoals = nil
        XCTAssertEqual(sut.targetDateText, "No target date")
    }

    func testTargetDateText_WhenGoalHasNoTargetDate() {
        sut.currentGoals = createMockGoal(targetDate: nil)
        XCTAssertEqual(sut.targetDateText, "No target date")
    }

    func testTargetDateText_WhenGoalHasTargetDate() {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 15))!
        sut.currentGoals = createMockGoal(targetDate: date)

        let text = sut.targetDateText
        XCTAssertNotEqual(text, "No target date", "Should show formatted date")
        XCTAssertTrue(text.contains("Jun") || text.contains("June"), "Should contain month name")
        XCTAssertTrue(text.contains("2026"), "Should contain year")
    }

    // MARK: - projectedCompletionDate Tests

    func testProjectedCompletionDate_WhenNoGoals() {
        sut.currentGoals = nil
        let result = sut.projectedCompletionDate(for: .weight, recentEntries: [])
        XCTAssertNil(result, "Should be nil when no goals")
    }

    func testProjectedCompletionDate_InsufficientEntries() {
        sut.currentGoals = createMockGoal(targetWeight: 180)
        let entry = createMockBodyComp(weightLb: 185)
        let result = sut.projectedCompletionDate(for: .weight, recentEntries: [entry])
        XCTAssertNil(result, "Should be nil with less than 2 entries")
    }

    func testProjectedCompletionDate_EmptyEntries() {
        sut.currentGoals = createMockGoal(targetWeight: 180)
        let result = sut.projectedCompletionDate(for: .weight, recentEntries: [])
        XCTAssertNil(result, "Should be nil with empty entries")
    }

    func testProjectedCompletionDate_WeightLoss() {
        sut.currentGoals = createMockGoal(targetWeight: 170)

        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let entry1 = createMockBodyComp(recordedAt: tenDaysAgo, weightLb: 190)
        let entry2 = createMockBodyComp(recordedAt: Date(), weightLb: 185)

        let result = sut.projectedCompletionDate(for: .weight, recentEntries: [entry1, entry2])
        XCTAssertNotNil(result, "Should calculate a projected date for weight loss")
        if let result = result {
            XCTAssertTrue(result > Date(), "Projected date should be in the future")
        }
    }

    func testProjectedCompletionDate_WeightGain() {
        sut.currentGoals = createMockGoal(targetWeight: 200)

        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let entry1 = createMockBodyComp(recordedAt: tenDaysAgo, weightLb: 180)
        let entry2 = createMockBodyComp(recordedAt: Date(), weightLb: 185)

        let result = sut.projectedCompletionDate(for: .weight, recentEntries: [entry1, entry2])
        XCTAssertNotNil(result, "Should calculate a projected date for weight gain")
        if let result = result {
            XCTAssertTrue(result > Date(), "Projected date should be in the future")
        }
    }

    func testProjectedCompletionDate_NoProgress_SameWeight() {
        sut.currentGoals = createMockGoal(targetWeight: 170)

        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let entry1 = createMockBodyComp(recordedAt: tenDaysAgo, weightLb: 185)
        let entry2 = createMockBodyComp(recordedAt: Date(), weightLb: 185)

        let result = sut.projectedCompletionDate(for: .weight, recentEntries: [entry1, entry2])
        XCTAssertNil(result, "Should be nil when no rate of change")
    }

    func testProjectedCompletionDate_WrongDirection() {
        // Target: lose weight to 170, but gaining weight
        sut.currentGoals = createMockGoal(targetWeight: 170)

        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let entry1 = createMockBodyComp(recordedAt: tenDaysAgo, weightLb: 185)
        let entry2 = createMockBodyComp(recordedAt: Date(), weightLb: 190)

        let result = sut.projectedCompletionDate(for: .weight, recentEntries: [entry1, entry2])
        XCTAssertNil(result, "Should be nil when progressing in wrong direction")
    }

    func testProjectedCompletionDate_BodyFat() {
        sut.currentGoals = createMockGoal(targetBodyFatPercentage: 12.0)

        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let entry1 = createMockBodyComp(recordedAt: tenDaysAgo, bodyFatPercent: 18.0)
        let entry2 = createMockBodyComp(recordedAt: Date(), bodyFatPercent: 16.0)

        let result = sut.projectedCompletionDate(for: .bodyFat, recentEntries: [entry1, entry2])
        XCTAssertNotNil(result, "Should calculate projected date for body fat reduction")
    }

    func testProjectedCompletionDate_MuscleMass() {
        sut.currentGoals = createMockGoal(targetMuscleMass: 170.0)

        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let entry1 = createMockBodyComp(recordedAt: tenDaysAgo, muscleMassLb: 155.0)
        let entry2 = createMockBodyComp(recordedAt: Date(), muscleMassLb: 158.0)

        let result = sut.projectedCompletionDate(for: .muscleMass, recentEntries: [entry1, entry2])
        XCTAssertNotNil(result, "Should calculate projected date for muscle mass gain")
    }

    func testProjectedCompletionDate_EntriesSortedByDate() {
        sut.currentGoals = createMockGoal(targetWeight: 170)

        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let entry1 = createMockBodyComp(recordedAt: Date(), weightLb: 185)
        let entry2 = createMockBodyComp(recordedAt: tenDaysAgo, weightLb: 190)

        // Pass entries out of order -- should still work
        let result = sut.projectedCompletionDate(for: .weight, recentEntries: [entry1, entry2])
        XCTAssertNotNil(result, "Should sort entries and calculate correctly")
    }

    func testProjectedCompletionDate_MissingWeightData() {
        sut.currentGoals = createMockGoal(targetWeight: 170)

        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let entry1 = createMockBodyComp(recordedAt: tenDaysAgo, weightLb: nil)
        let entry2 = createMockBodyComp(recordedAt: Date(), weightLb: 185)

        let result = sut.projectedCompletionDate(for: .weight, recentEntries: [entry1, entry2])
        XCTAssertNil(result, "Should return nil when first entry has nil weight")
    }

    func testProjectedCompletionDate_SameDayEntries() {
        sut.currentGoals = createMockGoal(targetWeight: 170)

        let entry1 = createMockBodyComp(recordedAt: Date(), weightLb: 185)
        let entry2 = createMockBodyComp(recordedAt: Date(), weightLb: 180)

        let result = sut.projectedCompletionDate(for: .weight, recentEntries: [entry1, entry2])
        XCTAssertNil(result, "Should return nil when entries are on the same day (0 days between)")
    }

    // MARK: - GoalMetric Enum Tests

    func testGoalMetric_AllCases() {
        let weightMetric = BodyCompGoalsViewModel.GoalMetric.weight
        let bodyFatMetric = BodyCompGoalsViewModel.GoalMetric.bodyFat
        let muscleMassMetric = BodyCompGoalsViewModel.GoalMetric.muscleMass

        XCTAssertNotNil(weightMetric)
        XCTAssertNotNil(bodyFatMetric)
        XCTAssertNotNil(muscleMassMetric)
    }

    // MARK: - BodyCompGoals Model Tests

    func testBodyCompGoals_DaysRemaining_FutureDate() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        let goal = createMockGoal(targetDate: futureDate)
        XCTAssertNotNil(goal.daysRemaining)
        if let days = goal.daysRemaining {
            XCTAssertTrue(days >= 29 && days <= 31)
        }
    }

    func testBodyCompGoals_DaysRemaining_PastDate() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let goal = createMockGoal(targetDate: pastDate)
        XCTAssertEqual(goal.daysRemaining, 0, "Past dates should clamp to 0")
    }

    func testBodyCompGoals_DaysRemaining_NilDate() {
        let goal = createMockGoal(targetDate: nil)
        XCTAssertNil(goal.daysRemaining)
    }

    func testBodyCompGoals_WeeksRemaining() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 70, to: Date())!
        let goal = createMockGoal(targetDate: futureDate)
        XCTAssertNotNil(goal.weeksRemaining)
        if let weeks = goal.weeksRemaining {
            XCTAssertTrue(weeks >= 9 && weeks <= 11)
        }
    }

    func testBodyCompGoals_WeeksRemaining_NilDate() {
        let goal = createMockGoal(targetDate: nil)
        XCTAssertNil(goal.weeksRemaining)
    }

    func testBodyCompGoals_IsExpired_FutureDate() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        let goal = createMockGoal(targetDate: futureDate)
        XCTAssertFalse(goal.isExpired)
    }

    func testBodyCompGoals_IsExpired_PastDate() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let goal = createMockGoal(targetDate: pastDate)
        XCTAssertTrue(goal.isExpired)
    }

    func testBodyCompGoals_IsExpired_NilDate() {
        let goal = createMockGoal(targetDate: nil)
        XCTAssertFalse(goal.isExpired, "Should not be expired when no target date")
    }

    func testBodyCompGoals_FormattedTargetDate_WithDate() {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 15))!
        let goal = createMockGoal(targetDate: date)
        let text = goal.formattedTargetDate
        XCTAssertNotEqual(text, "No target date")
        XCTAssertTrue(text.contains("2026"))
    }

    func testBodyCompGoals_FormattedTargetDate_NilDate() {
        let goal = createMockGoal(targetDate: nil)
        XCTAssertEqual(goal.formattedTargetDate, "No target date")
    }

    func testBodyCompGoals_TargetWeightText_WithValue() {
        let goal = createMockGoal(targetWeight: 180.5)
        XCTAssertEqual(goal.targetWeightText, "180.5 lbs")
    }

    func testBodyCompGoals_TargetWeightText_NilValue() {
        let goal = createMockGoal(targetWeight: nil)
        XCTAssertEqual(goal.targetWeightText, "--")
    }

    func testBodyCompGoals_TargetBodyFatText_WithValue() {
        let goal = createMockGoal(targetBodyFatPercentage: 15.5)
        XCTAssertEqual(goal.targetBodyFatText, "15.5%")
    }

    func testBodyCompGoals_TargetBodyFatText_NilValue() {
        let goal = createMockGoal(targetBodyFatPercentage: nil)
        XCTAssertEqual(goal.targetBodyFatText, "--")
    }

    func testBodyCompGoals_TargetMuscleMassText_WithValue() {
        let goal = createMockGoal(targetMuscleMass: 165.0)
        XCTAssertEqual(goal.targetMuscleMassText, "165.0 lbs")
    }

    func testBodyCompGoals_TargetMuscleMassText_NilValue() {
        let goal = createMockGoal(targetMuscleMass: nil)
        XCTAssertEqual(goal.targetMuscleMassText, "--")
    }

    func testBodyCompGoals_HasTargets_AllNil() {
        let goal = createMockGoal(targetWeight: nil, targetBodyFatPercentage: nil, targetMuscleMass: nil)
        XCTAssertFalse(goal.hasTargets, "Should be false when no targets set")
    }

    func testBodyCompGoals_HasTargets_WeightOnly() {
        let goal = createMockGoal(targetWeight: 180)
        XCTAssertTrue(goal.hasTargets, "Should be true when weight target set")
    }

    func testBodyCompGoals_HasTargets_BodyFatOnly() {
        let goal = createMockGoal(targetBodyFatPercentage: 15.0)
        XCTAssertTrue(goal.hasTargets)
    }

    func testBodyCompGoals_HasTargets_MuscleMassOnly() {
        let goal = createMockGoal(targetMuscleMass: 170.0)
        XCTAssertTrue(goal.hasTargets)
    }

    // MARK: - BodyCompGoals Progress Calculation Tests

    func testWeightProgress_LossGoal_Halfway() {
        let goal = createMockGoal(targetWeight: 180, startingWeight: 200)
        let progress = goal.weightProgress(current: 190)
        XCTAssertEqual(progress, 0.5, accuracy: 0.01, "50% progress toward weight loss")
    }

    func testWeightProgress_LossGoal_Complete() {
        let goal = createMockGoal(targetWeight: 180, startingWeight: 200)
        let progress = goal.weightProgress(current: 180)
        XCTAssertEqual(progress, 1.0, accuracy: 0.01, "100% progress when at target")
    }

    func testWeightProgress_LossGoal_NoProgress() {
        let goal = createMockGoal(targetWeight: 180, startingWeight: 200)
        let progress = goal.weightProgress(current: 200)
        XCTAssertEqual(progress, 0, accuracy: 0.01, "0% progress at starting weight")
    }

    func testWeightProgress_GainGoal() {
        let goal = createMockGoal(targetWeight: 200, startingWeight: 180)
        let progress = goal.weightProgress(current: 190)
        XCTAssertEqual(progress, 0.5, accuracy: 0.01, "50% progress toward weight gain")
    }

    func testWeightProgress_SameStartAndTarget() {
        let goal = createMockGoal(targetWeight: 180, startingWeight: 180)
        let progress = goal.weightProgress(current: 180)
        XCTAssertEqual(progress, 0, "Should return 0 when start equals target")
    }

    func testWeightProgress_NilCurrent() {
        let goal = createMockGoal(targetWeight: 180, startingWeight: 200)
        let progress = goal.weightProgress(current: nil)
        XCTAssertEqual(progress, 0, "Should return 0 when current is nil")
    }

    func testWeightProgress_NilStarting() {
        let goal = createMockGoal(targetWeight: 180, startingWeight: nil)
        let progress = goal.weightProgress(current: 190)
        XCTAssertEqual(progress, 0, "Should return 0 when starting is nil")
    }

    func testBodyFatProgress_Reduction() {
        let goal = createMockGoal(targetBodyFatPercentage: 12.0, startingBodyFatPercentage: 20.0)
        let progress = goal.bodyFatProgress(current: 16.0)
        XCTAssertEqual(progress, 0.5, accuracy: 0.01)
    }

    func testMuscleMassProgress_Gain() {
        let goal = createMockGoal(targetMuscleMass: 170, startingMuscleMass: 150)
        let progress = goal.muscleMassProgress(current: 160)
        XCTAssertEqual(progress, 0.5, accuracy: 0.01)
    }

    // MARK: - BodyCompGoalProgress Model Tests

    func testBodyCompGoalProgress_OverallProgress_AllMetrics() {
        let progress = createMockProgress(
            weightProgressPct: 80.0,
            bodyFatProgressPct: 60.0,
            muscleMassProgressPct: 40.0
        )
        XCTAssertEqual(progress.overallProgress ?? 0, 60.0, accuracy: 0.01, "Should average all metrics")
    }

    func testBodyCompGoalProgress_OverallProgress_SingleMetric() {
        let progress = createMockProgress(weightProgressPct: 80.0)
        XCTAssertEqual(progress.overallProgress ?? 0, 80.0, accuracy: 0.01)
    }

    func testBodyCompGoalProgress_OverallProgress_NoMetrics() {
        let progress = createMockProgress()
        XCTAssertNil(progress.overallProgress, "Should be nil when no progress values")
    }

    func testBodyCompGoalProgress_ProgressColor_Red() {
        let progress = createMockProgress()
        let color = progress.progressColor(for: 10.0)
        XCTAssertEqual(color, .red)
    }

    func testBodyCompGoalProgress_ProgressColor_Orange() {
        let progress = createMockProgress()
        let color = progress.progressColor(for: 30.0)
        XCTAssertEqual(color, .orange)
    }

    func testBodyCompGoalProgress_ProgressColor_Yellow() {
        let progress = createMockProgress()
        let color = progress.progressColor(for: 55.0)
        XCTAssertEqual(color, .yellow)
    }

    func testBodyCompGoalProgress_ProgressColor_Blue() {
        let progress = createMockProgress()
        let color = progress.progressColor(for: 80.0)
        XCTAssertEqual(color, .blue)
    }

    func testBodyCompGoalProgress_ProgressColor_Green() {
        let progress = createMockProgress()
        let color = progress.progressColor(for: 100.0)
        XCTAssertEqual(color, .green)
    }

    func testBodyCompGoalProgress_ProgressColor_Nil() {
        let progress = createMockProgress()
        let color = progress.progressColor(for: nil)
        XCTAssertEqual(color, .gray)
    }

    // MARK: - BodyCompGoalStatus Enum Tests

    func testBodyCompGoalStatus_AllCases() {
        let allCases = BodyCompGoalStatus.allCases
        XCTAssertEqual(allCases.count, 5)
    }

    func testBodyCompGoalStatus_DisplayNames() {
        XCTAssertEqual(BodyCompGoalStatus.active.displayName, "Active")
        XCTAssertEqual(BodyCompGoalStatus.achieved.displayName, "Achieved")
        XCTAssertEqual(BodyCompGoalStatus.paused.displayName, "Paused")
        XCTAssertEqual(BodyCompGoalStatus.cancelled.displayName, "Cancelled")
        XCTAssertEqual(BodyCompGoalStatus.unknown.displayName, "Unknown")
    }

    func testBodyCompGoalStatus_Icons() {
        XCTAssertEqual(BodyCompGoalStatus.active.icon, "target")
        XCTAssertEqual(BodyCompGoalStatus.achieved.icon, "checkmark.seal.fill")
        XCTAssertEqual(BodyCompGoalStatus.paused.icon, "pause.circle.fill")
        XCTAssertEqual(BodyCompGoalStatus.cancelled.icon, "xmark.circle.fill")
        XCTAssertEqual(BodyCompGoalStatus.unknown.icon, "questionmark.circle")
    }

    func testBodyCompGoalStatus_RawValues() {
        XCTAssertEqual(BodyCompGoalStatus.active.rawValue, "active")
        XCTAssertEqual(BodyCompGoalStatus.achieved.rawValue, "achieved")
        XCTAssertEqual(BodyCompGoalStatus.paused.rawValue, "paused")
        XCTAssertEqual(BodyCompGoalStatus.cancelled.rawValue, "cancelled")
        XCTAssertEqual(BodyCompGoalStatus.unknown.rawValue, "unknown")
    }

    // MARK: - GoalProgressStatus Enum Tests

    func testGoalProgressStatus_DisplayNames() {
        XCTAssertEqual(GoalProgressStatus.onTrack.displayName, "On Track")
        XCTAssertEqual(GoalProgressStatus.ahead.displayName, "Ahead")
        XCTAssertEqual(GoalProgressStatus.behind.displayName, "Behind")
        XCTAssertEqual(GoalProgressStatus.achieved.displayName, "Achieved")
    }

    func testGoalProgressStatus_Icons() {
        XCTAssertEqual(GoalProgressStatus.onTrack.icon, "checkmark.circle")
        XCTAssertEqual(GoalProgressStatus.ahead.icon, "arrow.up.circle.fill")
        XCTAssertEqual(GoalProgressStatus.behind.icon, "exclamationmark.triangle")
        XCTAssertEqual(GoalProgressStatus.achieved.icon, "star.fill")
    }

    // MARK: - State Mutation Tests

    func testError_CanBeSetAndCleared() {
        XCTAssertNil(sut.error)

        sut.error = AppError.notAuthenticated
        XCTAssertNotNil(sut.error)

        sut.error = nil
        XCTAssertNil(sut.error)
    }

    func testLatestMeasurements_CanBeSet() {
        sut.latestWeight = 185.5
        XCTAssertEqual(sut.latestWeight, 185.5)

        sut.latestBodyFat = 18.5
        XCTAssertEqual(sut.latestBodyFat, 18.5)

        sut.latestMuscleMass = 155.0
        XCTAssertEqual(sut.latestMuscleMass, 155.0)
    }

    func testAllGoals_CanBeSetAndCleared() {
        let goal = createMockGoal(status: .active)
        sut.allGoals = [goal]
        XCTAssertEqual(sut.allGoals.count, 1)

        sut.allGoals = []
        XCTAssertTrue(sut.allGoals.isEmpty)
    }

    func testShowingSuccessAlert_CanBeToggled() {
        XCTAssertFalse(sut.showingSuccessAlert)
        sut.showingSuccessAlert = true
        XCTAssertTrue(sut.showingSuccessAlert)
    }

    func testShowingGoalAchievedAlert_CanBeToggled() {
        XCTAssertFalse(sut.showingGoalAchievedAlert)
        sut.showingGoalAchievedAlert = true
        XCTAssertTrue(sut.showingGoalAchievedAlert)
    }

    // MARK: - Helper Methods

    private func createMockGoal(
        status: BodyCompGoalStatus = .active,
        targetWeight: Double? = nil,
        targetBodyFatPercentage: Double? = nil,
        targetMuscleMass: Double? = nil,
        startingWeight: Double? = nil,
        startingBodyFatPercentage: Double? = nil,
        startingMuscleMass: Double? = nil,
        targetDate: Date? = nil
    ) -> BodyCompGoals {
        BodyCompGoals(
            id: UUID(),
            patientId: UUID(),
            targetWeight: targetWeight,
            targetBodyFatPercentage: targetBodyFatPercentage,
            targetMuscleMass: targetMuscleMass,
            targetBmi: nil,
            startingWeight: startingWeight,
            startingBodyFatPercentage: startingBodyFatPercentage,
            startingMuscleMass: startingMuscleMass,
            targetDate: targetDate,
            startedAt: Date(),
            status: status,
            achievedAt: nil,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func createMockProgress(
        weightProgressPct: Double? = nil,
        bodyFatProgressPct: Double? = nil,
        muscleMassProgressPct: Double? = nil,
        daysRemaining: Int? = nil
    ) -> BodyCompGoalProgress {
        BodyCompGoalProgress(
            goalId: UUID(),
            patientId: UUID(),
            targetWeight: weightProgressPct != nil ? 180.0 : nil,
            targetBodyFatPercentage: bodyFatProgressPct != nil ? 15.0 : nil,
            targetMuscleMass: muscleMassProgressPct != nil ? 170.0 : nil,
            startingWeight: 200.0,
            startingBodyFatPercentage: 20.0,
            startingMuscleMass: 150.0,
            currentWeight: 190.0,
            currentBodyFat: 17.0,
            currentMuscleMass: 160.0,
            lastMeasured: Date(),
            weightProgressPct: weightProgressPct,
            bodyFatProgressPct: bodyFatProgressPct,
            muscleMassProgressPct: muscleMassProgressPct,
            targetDate: Calendar.current.date(byAdding: .day, value: 60, to: Date()),
            status: "active",
            startedAt: Date(),
            notes: nil,
            daysRemaining: daysRemaining
        )
    }

    private func createMockBodyComp(
        recordedAt: Date = Date(),
        weightLb: Double? = nil,
        bodyFatPercent: Double? = nil,
        muscleMassLb: Double? = nil
    ) -> BodyComposition {
        BodyComposition(
            id: UUID(),
            patientId: UUID(),
            recordedAt: recordedAt,
            weightLb: weightLb,
            bodyFatPercent: bodyFatPercent,
            muscleMassLb: muscleMassLb,
            bmi: nil,
            waistIn: nil,
            chestIn: nil,
            armIn: nil,
            legIn: nil,
            notes: nil,
            createdAt: Date()
        )
    }
}
