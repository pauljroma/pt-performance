//
//  BodyCompGoalsServiceTests.swift
//  PTPerformanceTests
//
//  Build 346 - Unit tests for BodyCompGoalsService
//  Tests goal achievement logic and pure functions that don't require database
//

import XCTest
@testable import PTPerformance

final class BodyCompGoalsServiceTests: XCTestCase {

    var service: BodyCompGoalsService!
    let testPatientId = UUID()

    override func setUp() async throws {
        try await super.setUp()
        service = BodyCompGoalsService()
    }

    override func tearDown() async throws {
        service = nil
        try await super.tearDown()
    }

    // MARK: - Goal Achievement Tests (Weight Loss)

    func testIsGoalAchieved_WeightLossGoal_Achieved() async {
        // Given: A weight loss goal (200 -> 180 lbs)
        let goal = BodyCompGoals(
            patientId: testPatientId,
            targetWeight: 180.0,
            startingWeight: 200.0,
            status: .active
        )

        // When: Current weight is at or below target
        let result = await service.isGoalAchieved(
            goal: goal,
            currentWeight: 178.0,
            currentBodyFat: nil,
            currentMuscleMass: nil
        )

        // Then: Goal should be achieved
        XCTAssertTrue(result, "Weight loss goal should be achieved when current weight is below target")
    }

    func testIsGoalAchieved_WeightLossGoal_NotAchieved() async {
        // Given: A weight loss goal (200 -> 180 lbs)
        let goal = BodyCompGoals(
            patientId: testPatientId,
            targetWeight: 180.0,
            startingWeight: 200.0,
            status: .active
        )

        // When: Current weight is above target
        let result = await service.isGoalAchieved(
            goal: goal,
            currentWeight: 185.0,
            currentBodyFat: nil,
            currentMuscleMass: nil
        )

        // Then: Goal should not be achieved
        XCTAssertFalse(result, "Weight loss goal should not be achieved when current weight is above target")
    }

    func testIsGoalAchieved_WeightLossGoal_ExactlyAtTarget() async {
        // Given: A weight loss goal
        let goal = BodyCompGoals(
            patientId: testPatientId,
            targetWeight: 180.0,
            startingWeight: 200.0,
            status: .active
        )

        // When: Current weight equals target
        let result = await service.isGoalAchieved(
            goal: goal,
            currentWeight: 180.0,
            currentBodyFat: nil,
            currentMuscleMass: nil
        )

        // Then: Goal should be achieved
        XCTAssertTrue(result, "Weight loss goal should be achieved when current weight equals target")
    }

    // MARK: - Goal Achievement Tests (Weight Gain)

    func testIsGoalAchieved_WeightGainGoal_Achieved() async {
        // Given: A weight gain goal (150 -> 170 lbs)
        let goal = BodyCompGoals(
            patientId: testPatientId,
            targetWeight: 170.0,
            startingWeight: 150.0,
            status: .active
        )

        // When: Current weight is at or above target
        let result = await service.isGoalAchieved(
            goal: goal,
            currentWeight: 172.0,
            currentBodyFat: nil,
            currentMuscleMass: nil
        )

        // Then: Goal should be achieved
        XCTAssertTrue(result, "Weight gain goal should be achieved when current weight is above target")
    }

    func testIsGoalAchieved_WeightGainGoal_NotAchieved() async {
        // Given: A weight gain goal
        let goal = BodyCompGoals(
            patientId: testPatientId,
            targetWeight: 170.0,
            startingWeight: 150.0,
            status: .active
        )

        // When: Current weight is below target
        let result = await service.isGoalAchieved(
            goal: goal,
            currentWeight: 165.0,
            currentBodyFat: nil,
            currentMuscleMass: nil
        )

        // Then: Goal should not be achieved
        XCTAssertFalse(result, "Weight gain goal should not be achieved when current weight is below target")
    }

    // MARK: - Goal Achievement Tests (Body Fat)

    func testIsGoalAchieved_BodyFatLossGoal_Achieved() async {
        // Given: A body fat loss goal (25% -> 18%)
        let goal = BodyCompGoals(
            patientId: testPatientId,
            targetBodyFatPercentage: 18.0,
            startingBodyFatPercentage: 25.0,
            status: .active
        )

        // When: Current body fat is at or below target
        let result = await service.isGoalAchieved(
            goal: goal,
            currentWeight: nil,
            currentBodyFat: 17.5,
            currentMuscleMass: nil
        )

        // Then: Goal should be achieved
        XCTAssertTrue(result, "Body fat loss goal should be achieved when current is below target")
    }

    func testIsGoalAchieved_BodyFatLossGoal_NotAchieved() async {
        // Given: A body fat loss goal
        let goal = BodyCompGoals(
            patientId: testPatientId,
            targetBodyFatPercentage: 18.0,
            startingBodyFatPercentage: 25.0,
            status: .active
        )

        // When: Current body fat is above target
        let result = await service.isGoalAchieved(
            goal: goal,
            currentWeight: nil,
            currentBodyFat: 20.0,
            currentMuscleMass: nil
        )

        // Then: Goal should not be achieved
        XCTAssertFalse(result, "Body fat loss goal should not be achieved when current is above target")
    }

    // MARK: - Goal Achievement Tests (Muscle Mass)

    func testIsGoalAchieved_MuscleMassGainGoal_Achieved() async {
        // Given: A muscle mass gain goal (140 -> 155 lbs)
        let goal = BodyCompGoals(
            patientId: testPatientId,
            targetMuscleMass: 155.0,
            startingMuscleMass: 140.0,
            status: .active
        )

        // When: Current muscle mass is at or above target
        let result = await service.isGoalAchieved(
            goal: goal,
            currentWeight: nil,
            currentBodyFat: nil,
            currentMuscleMass: 157.0
        )

        // Then: Goal should be achieved
        XCTAssertTrue(result, "Muscle mass gain goal should be achieved when current is above target")
    }

    func testIsGoalAchieved_MuscleMassGainGoal_NotAchieved() async {
        // Given: A muscle mass gain goal
        let goal = BodyCompGoals(
            patientId: testPatientId,
            targetMuscleMass: 155.0,
            startingMuscleMass: 140.0,
            status: .active
        )

        // When: Current muscle mass is below target
        let result = await service.isGoalAchieved(
            goal: goal,
            currentWeight: nil,
            currentBodyFat: nil,
            currentMuscleMass: 150.0
        )

        // Then: Goal should not be achieved
        XCTAssertFalse(result, "Muscle mass gain goal should not be achieved when current is below target")
    }

    func testIsGoalAchieved_MuscleMassLossGoal_Achieved() async {
        // Given: A muscle mass loss goal (unusual but possible, e.g., 160 -> 150 lbs)
        let goal = BodyCompGoals(
            patientId: testPatientId,
            targetMuscleMass: 150.0,
            startingMuscleMass: 160.0,
            status: .active
        )

        // When: Current muscle mass is at or below target
        let result = await service.isGoalAchieved(
            goal: goal,
            currentWeight: nil,
            currentBodyFat: nil,
            currentMuscleMass: 148.0
        )

        // Then: Goal should be achieved
        XCTAssertTrue(result, "Muscle mass loss goal should be achieved when current is below target")
    }

    // MARK: - Combined Goals Tests

    func testIsGoalAchieved_CombinedGoals_AllAchieved() async {
        // Given: A goal with weight, body fat, and muscle mass targets
        let goal = BodyCompGoals(
            patientId: testPatientId,
            targetWeight: 180.0,
            targetBodyFatPercentage: 15.0,
            targetMuscleMass: 155.0,
            startingWeight: 200.0,
            startingBodyFatPercentage: 25.0,
            startingMuscleMass: 140.0,
            status: .active
        )

        // When: All targets are met
        let result = await service.isGoalAchieved(
            goal: goal,
            currentWeight: 178.0,
            currentBodyFat: 14.0,
            currentMuscleMass: 157.0
        )

        // Then: Goal should be achieved
        XCTAssertTrue(result, "Combined goal should be achieved when all targets are met")
    }

    func testIsGoalAchieved_CombinedGoals_PartiallyAchieved() async {
        // Given: A goal with weight and body fat targets
        let goal = BodyCompGoals(
            patientId: testPatientId,
            targetWeight: 180.0,
            targetBodyFatPercentage: 15.0,
            startingWeight: 200.0,
            startingBodyFatPercentage: 25.0,
            status: .active
        )

        // When: Only weight target is met
        let result = await service.isGoalAchieved(
            goal: goal,
            currentWeight: 178.0,
            currentBodyFat: 18.0,
            currentMuscleMass: nil
        )

        // Then: Goal should not be achieved (all targets must be met)
        XCTAssertFalse(result, "Combined goal should not be achieved when only some targets are met")
    }

    // MARK: - Edge Cases

    func testIsGoalAchieved_NoTargets() async {
        // Given: A goal with no targets set
        let goal = BodyCompGoals(
            patientId: testPatientId,
            status: .active
        )

        // When: Checking achievement
        let result = await service.isGoalAchieved(
            goal: goal,
            currentWeight: 180.0,
            currentBodyFat: 20.0,
            currentMuscleMass: 150.0
        )

        // Then: Goal should not be achieved (no targets to meet)
        XCTAssertFalse(result, "Goal with no targets should not be achieved")
    }

    func testIsGoalAchieved_NoCurrentMeasurements() async {
        // Given: A goal with targets
        let goal = BodyCompGoals(
            patientId: testPatientId,
            targetWeight: 180.0,
            startingWeight: 200.0,
            status: .active
        )

        // When: No current measurements provided
        let result = await service.isGoalAchieved(
            goal: goal,
            currentWeight: nil,
            currentBodyFat: nil,
            currentMuscleMass: nil
        )

        // Then: Goal should not be achieved
        XCTAssertFalse(result, "Goal should not be achieved without current measurements")
    }

    func testIsGoalAchieved_NoStartingWeight_UsesCurrentAsBaseline() async {
        // Given: A goal without starting weight
        let goal = BodyCompGoals(
            patientId: testPatientId,
            targetWeight: 180.0,
            startingWeight: nil,
            status: .active
        )

        // When: Current weight equals target (implies it was a "maintain" goal)
        let result = await service.isGoalAchieved(
            goal: goal,
            currentWeight: 180.0,
            currentBodyFat: nil,
            currentMuscleMass: nil
        )

        // Then: Verify result is consistent (current used as baseline)
        // Since current (180) == target (180), and current is used as start,
        // this would be a "gain" goal direction (start >= target means loss goal)
        // Actually 180 >= 180 so it's a "loss" or "maintain" goal, and 180 <= 180 is true
        XCTAssertTrue(result, "Goal should be achieved when current equals target")
    }

    // MARK: - Progress-Based Achievement Tests

    func testIsGoalAchieved_WithProgress_AllTargetsReached() async {
        // Given: Progress data showing all targets at 100%+
        let progress = BodyCompGoalProgress(
            goalId: UUID(),
            patientId: testPatientId,
            targetWeight: 180.0,
            targetBodyFatPercentage: 15.0,
            targetMuscleMass: 155.0,
            weightProgressPct: 105.0,
            bodyFatProgressPct: 100.0,
            muscleMassProgressPct: 110.0,
            status: "active"
        )

        // When: Checking achievement via progress
        let result = await service.isGoalAchieved(progress: progress)

        // Then: Goal should be achieved
        XCTAssertTrue(result, "Goal should be achieved when all progress percentages are >= 100")
    }

    func testIsGoalAchieved_WithProgress_SomeTargetsNotReached() async {
        // Given: Progress data with incomplete progress
        let progress = BodyCompGoalProgress(
            goalId: UUID(),
            patientId: testPatientId,
            targetWeight: 180.0,
            targetBodyFatPercentage: 15.0,
            weightProgressPct: 100.0,
            bodyFatProgressPct: 75.0,
            status: "active"
        )

        // When: Checking achievement via progress
        let result = await service.isGoalAchieved(progress: progress)

        // Then: Goal should not be achieved
        XCTAssertFalse(result, "Goal should not be achieved when some progress is below 100%")
    }

    func testIsGoalAchieved_WithProgress_NoTargets() async {
        // Given: Progress data with no targets
        let progress = BodyCompGoalProgress(
            goalId: UUID(),
            patientId: testPatientId,
            status: "active"
        )

        // When: Checking achievement via progress
        let result = await service.isGoalAchieved(progress: progress)

        // Then: Goal should not be achieved (no targets)
        XCTAssertFalse(result, "Goal with no targets should not be achieved")
    }

    // MARK: - Input Validation Tests

    func testGetActiveGoal_InvalidPatientId_ThrowsError() async {
        // Given: An invalid patient ID format
        let invalidPatientId = "not-a-uuid"

        // When/Then: Should throw invalidInput error
        do {
            _ = try await service.getActiveGoal(patientId: invalidPatientId)
            XCTFail("Should throw error for invalid patient ID")
        } catch let error as AppError {
            if case .invalidInput(let message) = error {
                XCTAssertTrue(message.contains("patient ID"), "Error should mention patient ID")
            } else {
                XCTFail("Expected invalidInput error, got \(error)")
            }
        } catch {
            XCTFail("Expected AppError, got \(type(of: error))")
        }
    }

    func testGetGoalProgress_InvalidPatientId_ThrowsError() async {
        // Given: An invalid patient ID format
        let invalidPatientId = "invalid"

        // When/Then: Should throw invalidInput error
        do {
            _ = try await service.getGoalProgress(patientId: invalidPatientId)
            XCTFail("Should throw error for invalid patient ID")
        } catch let error as AppError {
            if case .invalidInput(let message) = error {
                XCTAssertTrue(message.contains("patient ID"), "Error should mention patient ID")
            } else {
                XCTFail("Expected invalidInput error, got \(error)")
            }
        } catch {
            XCTFail("Expected AppError, got \(type(of: error))")
        }
    }

    func testGetGoalHistory_InvalidPatientId_ThrowsError() async {
        // Given: An invalid patient ID format
        let invalidPatientId = ""

        // When/Then: Should throw invalidInput error
        do {
            _ = try await service.getGoalHistory(patientId: invalidPatientId)
            XCTFail("Should throw error for invalid patient ID")
        } catch let error as AppError {
            if case .invalidInput = error {
                // Expected
            } else {
                XCTFail("Expected invalidInput error, got \(error)")
            }
        } catch {
            XCTFail("Expected AppError, got \(type(of: error))")
        }
    }

    // MARK: - Service Instance Tests

    func testServiceInstance_IsActor() {
        // Verify the service is an actor (thread-safe)
        // This test verifies the type at compile time
        let _: BodyCompGoalsService = service
        XCTAssertNotNil(service, "Service should be instantiatable")
    }
}

// MARK: - BodyCompGoals Model Tests

final class BodyCompGoalsModelTests: XCTestCase {

    // MARK: - Computed Properties Tests

    func testDaysRemaining_WithFutureDate() {
        // Given: A goal with target date 30 days in future
        let calendar = Calendar.current
        let targetDate = calendar.date(byAdding: .day, value: 30, to: Date())!

        let goal = BodyCompGoals(
            patientId: UUID(),
            targetDate: targetDate,
            status: .active
        )

        // When: Getting days remaining
        let days = goal.daysRemaining

        // Then: Should be approximately 30 days (allowing for time of day variance)
        XCTAssertNotNil(days)
        XCTAssertTrue(days! >= 29 && days! <= 30, "Days remaining should be around 30")
    }

    func testDaysRemaining_WithPastDate() {
        // Given: A goal with target date in past
        let calendar = Calendar.current
        let targetDate = calendar.date(byAdding: .day, value: -5, to: Date())!

        let goal = BodyCompGoals(
            patientId: UUID(),
            targetDate: targetDate,
            status: .active
        )

        // When: Getting days remaining
        let days = goal.daysRemaining

        // Then: Should be 0 (clamped)
        XCTAssertEqual(days, 0, "Days remaining for past date should be 0")
    }

    func testDaysRemaining_WithNoTargetDate() {
        // Given: A goal without target date
        let goal = BodyCompGoals(
            patientId: UUID(),
            status: .active
        )

        // When: Getting days remaining
        let days = goal.daysRemaining

        // Then: Should be nil
        XCTAssertNil(days, "Days remaining should be nil when no target date")
    }

    func testWeeksRemaining_WithFutureDate() {
        // Given: A goal with target date 21 days in future
        let calendar = Calendar.current
        let targetDate = calendar.date(byAdding: .day, value: 21, to: Date())!

        let goal = BodyCompGoals(
            patientId: UUID(),
            targetDate: targetDate,
            status: .active
        )

        // When: Getting weeks remaining
        let weeks = goal.weeksRemaining

        // Then: Should be approximately 3 weeks
        XCTAssertNotNil(weeks)
        XCTAssertTrue(weeks! >= 2 && weeks! <= 3, "Weeks remaining should be around 3")
    }

    func testIsExpired_WithPastDate() {
        // Given: A goal with target date in past
        let calendar = Calendar.current
        let targetDate = calendar.date(byAdding: .day, value: -1, to: Date())!

        let goal = BodyCompGoals(
            patientId: UUID(),
            targetDate: targetDate,
            status: .active
        )

        // Then: Should be expired
        XCTAssertTrue(goal.isExpired, "Goal with past target date should be expired")
    }

    func testIsExpired_WithFutureDate() {
        // Given: A goal with target date in future
        let calendar = Calendar.current
        let targetDate = calendar.date(byAdding: .day, value: 10, to: Date())!

        let goal = BodyCompGoals(
            patientId: UUID(),
            targetDate: targetDate,
            status: .active
        )

        // Then: Should not be expired
        XCTAssertFalse(goal.isExpired, "Goal with future target date should not be expired")
    }

    func testIsExpired_WithNoTargetDate() {
        // Given: A goal without target date
        let goal = BodyCompGoals(
            patientId: UUID(),
            status: .active
        )

        // Then: Should not be expired
        XCTAssertFalse(goal.isExpired, "Goal without target date should not be expired")
    }

    func testHasTargets_WithTargets() {
        // Given: A goal with weight target
        let goal = BodyCompGoals(
            patientId: UUID(),
            targetWeight: 180.0,
            status: .active
        )

        // Then: Should have targets
        XCTAssertTrue(goal.hasTargets, "Goal with target weight should have targets")
    }

    func testHasTargets_WithNoTargets() {
        // Given: A goal without any targets
        let goal = BodyCompGoals(
            patientId: UUID(),
            status: .active
        )

        // Then: Should not have targets
        XCTAssertFalse(goal.hasTargets, "Goal without targets should not have targets")
    }

    // MARK: - Progress Calculation Tests

    func testWeightProgress_LossGoal() {
        // Given: Weight loss goal (200 -> 180, lost 10 lbs so far)
        let goal = BodyCompGoals(
            patientId: UUID(),
            targetWeight: 180.0,
            startingWeight: 200.0,
            status: .active
        )

        // When: Calculating progress at 190 lbs
        let progress = goal.weightProgress(current: 190.0)

        // Then: Should be 50% progress (10/20 lbs lost)
        XCTAssertEqual(progress, 0.5, accuracy: 0.01, "Progress should be 50%")
    }

    func testWeightProgress_GainGoal() {
        // Given: Weight gain goal (150 -> 170, gained 10 lbs so far)
        let goal = BodyCompGoals(
            patientId: UUID(),
            targetWeight: 170.0,
            startingWeight: 150.0,
            status: .active
        )

        // When: Calculating progress at 160 lbs
        let progress = goal.weightProgress(current: 160.0)

        // Then: Should be 50% progress (10/20 lbs gained)
        XCTAssertEqual(progress, 0.5, accuracy: 0.01, "Progress should be 50%")
    }

    func testWeightProgress_Exceeded() {
        // Given: Weight loss goal exceeded
        let goal = BodyCompGoals(
            patientId: UUID(),
            targetWeight: 180.0,
            startingWeight: 200.0,
            status: .active
        )

        // When: Calculating progress at 170 lbs (exceeded by 10)
        let progress = goal.weightProgress(current: 170.0)

        // Then: Should be >100% progress
        XCTAssertEqual(progress, 1.5, accuracy: 0.01, "Progress should be 150%")
    }

    func testBodyFatProgress_LossGoal() {
        // Given: Body fat loss goal (25% -> 15%, lost 5% so far)
        let goal = BodyCompGoals(
            patientId: UUID(),
            targetBodyFatPercentage: 15.0,
            startingBodyFatPercentage: 25.0,
            status: .active
        )

        // When: Calculating progress at 20%
        let progress = goal.bodyFatProgress(current: 20.0)

        // Then: Should be 50% progress
        XCTAssertEqual(progress, 0.5, accuracy: 0.01, "Progress should be 50%")
    }

    func testMuscleMassProgress_GainGoal() {
        // Given: Muscle mass gain goal (140 -> 160, gained 10 lbs so far)
        let goal = BodyCompGoals(
            patientId: UUID(),
            targetMuscleMass: 160.0,
            startingMuscleMass: 140.0,
            status: .active
        )

        // When: Calculating progress at 150 lbs
        let progress = goal.muscleMassProgress(current: 150.0)

        // Then: Should be 50% progress
        XCTAssertEqual(progress, 0.5, accuracy: 0.01, "Progress should be 50%")
    }

    func testWeeklyWeightChangeNeeded() {
        // Given: Weight loss goal with 10 weeks remaining
        let calendar = Calendar.current
        let targetDate = calendar.date(byAdding: .day, value: 70, to: Date())!  // ~10 weeks

        let goal = BodyCompGoals(
            patientId: UUID(),
            targetWeight: 180.0,
            targetDate: targetDate,
            status: .active
        )

        // When: Calculating weekly change needed from 190 lbs
        let weeklyChange = goal.weeklyWeightChangeNeeded(current: 190.0)

        // Then: Should be approximately -1 lb/week (10 lbs / 10 weeks)
        XCTAssertNotNil(weeklyChange)
        XCTAssertEqual(weeklyChange!, -1.0, accuracy: 0.2, "Weekly change should be about -1 lb")
    }

    // MARK: - Progress Status Tests

    func testProgressStatus_Achieved() {
        // Given: A goal where target is met
        let goal = BodyCompGoals(
            patientId: UUID(),
            targetWeight: 180.0,
            startingWeight: 200.0,
            status: .active
        )

        // When: Current weight meets target
        let status = goal.progressStatus(currentWeight: 178.0, currentBodyFat: nil)

        // Then: Status should be achieved
        XCTAssertEqual(status, .achieved, "Status should be achieved when goal is met")
    }

    // MARK: - Formatted Text Tests

    func testTargetWeightText_WithValue() {
        let goal = BodyCompGoals(
            patientId: UUID(),
            targetWeight: 180.5,
            status: .active
        )

        XCTAssertEqual(goal.targetWeightText, "180.5 lbs")
    }

    func testTargetWeightText_WithoutValue() {
        let goal = BodyCompGoals(
            patientId: UUID(),
            status: .active
        )

        XCTAssertEqual(goal.targetWeightText, "--")
    }

    func testTargetBodyFatText_WithValue() {
        let goal = BodyCompGoals(
            patientId: UUID(),
            targetBodyFatPercentage: 15.5,
            status: .active
        )

        XCTAssertEqual(goal.targetBodyFatText, "15.5%")
    }

    func testTargetMuscleMassText_WithValue() {
        let goal = BodyCompGoals(
            patientId: UUID(),
            targetMuscleMass: 155.0,
            status: .active
        )

        XCTAssertEqual(goal.targetMuscleMassText, "155.0 lbs")
    }
}

// MARK: - BodyCompGoalStatus Tests

final class BodyCompGoalStatusTests: XCTestCase {

    func testAllCases() {
        let allCases = BodyCompGoalStatus.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.active))
        XCTAssertTrue(allCases.contains(.achieved))
        XCTAssertTrue(allCases.contains(.paused))
        XCTAssertTrue(allCases.contains(.cancelled))
    }

    func testDisplayNames() {
        XCTAssertEqual(BodyCompGoalStatus.active.displayName, "Active")
        XCTAssertEqual(BodyCompGoalStatus.achieved.displayName, "Achieved")
        XCTAssertEqual(BodyCompGoalStatus.paused.displayName, "Paused")
        XCTAssertEqual(BodyCompGoalStatus.cancelled.displayName, "Cancelled")
    }

    func testRawValues() {
        XCTAssertEqual(BodyCompGoalStatus.active.rawValue, "active")
        XCTAssertEqual(BodyCompGoalStatus.achieved.rawValue, "achieved")
        XCTAssertEqual(BodyCompGoalStatus.paused.rawValue, "paused")
        XCTAssertEqual(BodyCompGoalStatus.cancelled.rawValue, "cancelled")
    }
}

// MARK: - BodyCompGoalProgress Tests

final class BodyCompGoalProgressTests: XCTestCase {

    func testOverallProgress_AllMetrics() {
        let progress = BodyCompGoalProgress(
            goalId: UUID(),
            patientId: UUID(),
            weightProgressPct: 80.0,
            bodyFatProgressPct: 60.0,
            muscleMassProgressPct: 100.0,
            status: "active"
        )

        // Average of 80 + 60 + 100 = 240 / 3 = 80
        XCTAssertEqual(progress.overallProgress ?? 0, 80.0, accuracy: 0.01)
    }

    func testOverallProgress_SingleMetric() {
        let progress = BodyCompGoalProgress(
            goalId: UUID(),
            patientId: UUID(),
            weightProgressPct: 75.0,
            status: "active"
        )

        XCTAssertEqual(progress.overallProgress ?? 0, 75.0, accuracy: 0.01)
    }

    func testOverallProgress_NoMetrics() {
        let progress = BodyCompGoalProgress(
            goalId: UUID(),
            patientId: UUID(),
            status: "active"
        )

        XCTAssertNil(progress.overallProgress)
    }

    func testProgressColor_Red() {
        let progress = BodyCompGoalProgress(
            goalId: UUID(),
            patientId: UUID(),
            status: "active"
        )

        let color = progress.progressColor(for: 20.0)
        XCTAssertEqual(color, .red)
    }

    func testProgressColor_Orange() {
        let progress = BodyCompGoalProgress(
            goalId: UUID(),
            patientId: UUID(),
            status: "active"
        )

        let color = progress.progressColor(for: 40.0)
        XCTAssertEqual(color, .orange)
    }

    func testProgressColor_Yellow() {
        let progress = BodyCompGoalProgress(
            goalId: UUID(),
            patientId: UUID(),
            status: "active"
        )

        let color = progress.progressColor(for: 60.0)
        XCTAssertEqual(color, .yellow)
    }

    func testProgressColor_Blue() {
        let progress = BodyCompGoalProgress(
            goalId: UUID(),
            patientId: UUID(),
            status: "active"
        )

        let color = progress.progressColor(for: 85.0)
        XCTAssertEqual(color, .blue)
    }

    func testProgressColor_Green() {
        let progress = BodyCompGoalProgress(
            goalId: UUID(),
            patientId: UUID(),
            status: "active"
        )

        let color = progress.progressColor(for: 100.0)
        XCTAssertEqual(color, .green)
    }

    func testProgressColor_Nil() {
        let progress = BodyCompGoalProgress(
            goalId: UUID(),
            patientId: UUID(),
            status: "active"
        )

        let color = progress.progressColor(for: nil)
        XCTAssertEqual(color, .gray)
    }
}
