//
//  NutritionGoalViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for NutritionGoalViewModel
//  Tests macro calculations, preset application, and computed properties
//

import XCTest
@testable import PTPerformance

@MainActor
final class NutritionGoalViewModelTests: XCTestCase {

    var viewModel: NutritionGoalViewModel!

    override func setUp() async throws {
        try await super.setUp()
        viewModel = NutritionGoalViewModel()
    }

    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertFalse(viewModel.isLoading, "Should not be loading initially")
        XCTAssertFalse(viewModel.isSaving, "Should not be saving initially")
        XCTAssertNil(viewModel.error, "Should have no error initially")
        XCTAssertFalse(viewModel.showError, "Should not show error initially")
        XCTAssertNil(viewModel.currentGoal, "Should have no current goal initially")
        XCTAssertTrue(viewModel.allGoals.isEmpty, "All goals should be empty initially")
    }

    func testDefaultFormValues() {
        XCTAssertEqual(viewModel.goalType, .daily, "Default goal type should be daily")
        XCTAssertEqual(viewModel.targetCalories, 2000, "Default calories should be 2000")
        XCTAssertEqual(viewModel.targetProtein, 150, "Default protein should be 150g")
        XCTAssertEqual(viewModel.targetCarbs, 200, "Default carbs should be 200g")
        XCTAssertEqual(viewModel.targetFat, 65, "Default fat should be 65g")
        XCTAssertEqual(viewModel.targetFiber, 30, "Default fiber should be 30g")
        XCTAssertEqual(viewModel.targetWater, 2500, "Default water should be 2500ml")
        XCTAssertEqual(viewModel.proteinPerKg, 1.6, "Default protein per kg should be 1.6")
        XCTAssertEqual(viewModel.notes, "", "Notes should be empty initially")
    }

    // MARK: - Macro Calorie Calculation Tests

    func testMacroCalories_DefaultValues() {
        // Default: 150g protein (600 cal) + 200g carbs (800 cal) + 65g fat (585 cal) = 1985 cal
        let expectedCals = (150 * 4) + (200 * 4) + (65 * 9)
        XCTAssertEqual(viewModel.macroCalories, expectedCals,
            "macroCalories should sum protein*4 + carbs*4 + fat*9")
    }

    func testMacroCalories_CustomValues() {
        viewModel.targetProtein = 200
        viewModel.targetCarbs = 300
        viewModel.targetFat = 80

        // 200*4 + 300*4 + 80*9 = 800 + 1200 + 720 = 2720
        XCTAssertEqual(viewModel.macroCalories, 2720,
            "macroCalories should correctly calculate with custom values")
    }

    func testMacroCalories_ZeroValues() {
        viewModel.targetProtein = 0
        viewModel.targetCarbs = 0
        viewModel.targetFat = 0

        XCTAssertEqual(viewModel.macroCalories, 0,
            "macroCalories should be 0 when all macros are 0")
    }

    func testMacroCalories_ProteinOnly() {
        viewModel.targetProtein = 100
        viewModel.targetCarbs = 0
        viewModel.targetFat = 0

        XCTAssertEqual(viewModel.macroCalories, 400,
            "100g protein should equal 400 calories")
    }

    func testMacroCalories_CarbsOnly() {
        viewModel.targetProtein = 0
        viewModel.targetCarbs = 100
        viewModel.targetFat = 0

        XCTAssertEqual(viewModel.macroCalories, 400,
            "100g carbs should equal 400 calories")
    }

    func testMacroCalories_FatOnly() {
        viewModel.targetProtein = 0
        viewModel.targetCarbs = 0
        viewModel.targetFat = 100

        XCTAssertEqual(viewModel.macroCalories, 900,
            "100g fat should equal 900 calories")
    }

    // MARK: - Calories Difference Tests

    func testCaloriesDifference_Balanced() {
        // Set macros to exactly match target calories
        viewModel.targetCalories = 2000
        viewModel.targetProtein = 125  // 500 cal
        viewModel.targetCarbs = 250    // 1000 cal
        viewModel.targetFat = 56       // 504 cal (rounding: 2004 total)

        let diff = viewModel.caloriesDifference
        // 2000 - (125*4 + 250*4 + 56*9) = 2000 - 2004 = -4
        XCTAssertEqual(diff, -4, "Calories difference should be target minus macro calories")
    }

    func testCaloriesDifference_Deficit() {
        viewModel.targetCalories = 1500
        viewModel.targetProtein = 150
        viewModel.targetCarbs = 200
        viewModel.targetFat = 65

        // 1500 - 1985 = -485
        XCTAssertTrue(viewModel.caloriesDifference < 0,
            "Should have negative difference when macros exceed target")
    }

    func testCaloriesDifference_Surplus() {
        viewModel.targetCalories = 3000
        viewModel.targetProtein = 150
        viewModel.targetCarbs = 200
        viewModel.targetFat = 65

        // 3000 - 1985 = 1015
        XCTAssertTrue(viewModel.caloriesDifference > 0,
            "Should have positive difference when target exceeds macros")
    }

    // MARK: - Macros Balanced Tests

    func testMacrosBalanced_WithinThreshold() {
        // Set values so difference is within 100 calories
        viewModel.targetCalories = 2000
        viewModel.targetProtein = 125
        viewModel.targetCarbs = 250
        viewModel.targetFat = 56  // Total macro cals = 2004

        XCTAssertTrue(viewModel.macrosBalanced,
            "Macros should be considered balanced when within 100 calories")
    }

    func testMacrosBalanced_ExactMatch() {
        viewModel.targetCalories = 1985  // Matches default macro calories exactly
        XCTAssertTrue(viewModel.macrosBalanced,
            "Macros should be balanced when exact match")
    }

    func testMacrosBalanced_OutsideThreshold() {
        viewModel.targetCalories = 1500
        // Default macros = 1985, difference = 485

        XCTAssertFalse(viewModel.macrosBalanced,
            "Macros should not be balanced when difference exceeds 100 calories")
    }

    func testMacrosBalanced_BoundaryExactly100() {
        // Macro calories = 1985 with defaults
        viewModel.targetCalories = 2084  // difference = 99, just under 100

        XCTAssertTrue(viewModel.macrosBalanced,
            "Should be balanced when difference is exactly 99")
    }

    func testMacrosBalanced_BoundaryOver100() {
        // Macro calories = 1985 with defaults
        viewModel.targetCalories = 2086  // difference = 101

        XCTAssertFalse(viewModel.macrosBalanced,
            "Should not be balanced when difference is 101")
    }

    // MARK: - Macro Percent Tests

    func testProteinPercent_DefaultValues() {
        // 150g * 4 = 600 calories / 2000 = 30%
        XCTAssertEqual(viewModel.proteinPercent, 30,
            "Protein percent should be 30% with default values")
    }

    func testCarbsPercent_DefaultValues() {
        // 200g * 4 = 800 calories / 2000 = 40%
        XCTAssertEqual(viewModel.carbsPercent, 40,
            "Carbs percent should be 40% with default values")
    }

    func testFatPercent_DefaultValues() {
        // 65g * 9 = 585 calories / 2000 = 29.25% -> 29%
        XCTAssertEqual(viewModel.fatPercent, 29,
            "Fat percent should be 29% with default values")
    }

    func testProteinPercent_ZeroCalories() {
        viewModel.targetCalories = 0
        XCTAssertEqual(viewModel.proteinPercent, 0,
            "Protein percent should be 0 when target calories is 0")
    }

    func testCarbsPercent_ZeroCalories() {
        viewModel.targetCalories = 0
        XCTAssertEqual(viewModel.carbsPercent, 0,
            "Carbs percent should be 0 when target calories is 0")
    }

    func testFatPercent_ZeroCalories() {
        viewModel.targetCalories = 0
        XCTAssertEqual(viewModel.fatPercent, 0,
            "Fat percent should be 0 when target calories is 0")
    }

    func testMacroPercents_Sum() {
        // Total percentages should be close to 100%
        let total = viewModel.proteinPercent + viewModel.carbsPercent + viewModel.fatPercent
        // 30 + 40 + 29 = 99 (rounding causes 1% loss)
        XCTAssertTrue(total >= 95 && total <= 105,
            "Macro percentages should sum close to 100%")
    }

    func testMacroPercents_HighProteinDiet() {
        viewModel.targetCalories = 2000
        viewModel.targetProtein = 250  // 1000 cal = 50%
        viewModel.targetCarbs = 150    // 600 cal = 30%
        viewModel.targetFat = 44       // 396 cal = ~20%

        XCTAssertEqual(viewModel.proteinPercent, 50)
        XCTAssertEqual(viewModel.carbsPercent, 30)
        XCTAssertEqual(viewModel.fatPercent, 19)
    }

    // MARK: - Has Active Goal Tests

    func testHasActiveGoal_WhenNil() {
        viewModel.currentGoal = nil
        XCTAssertFalse(viewModel.hasActiveGoal,
            "Should not have active goal when currentGoal is nil")
    }

    // MARK: - Apply Preset Tests

    func testApplyPreset_Maintenance() {
        let maintenancePreset = GoalPreset.presets.first { $0.name == "Maintenance" }!
        viewModel.applyPreset(maintenancePreset)

        XCTAssertEqual(viewModel.targetCalories, 2000)
        XCTAssertEqual(viewModel.targetProtein, 150)
        XCTAssertEqual(viewModel.targetCarbs, 200)
        XCTAssertEqual(viewModel.targetFat, 65)
        XCTAssertEqual(viewModel.targetFiber, 30)
        XCTAssertEqual(viewModel.selectedPreset?.name, "Maintenance")
    }

    func testApplyPreset_MuscleGain() {
        let muscleGainPreset = GoalPreset.presets.first { $0.name == "Muscle Gain" }!
        viewModel.applyPreset(muscleGainPreset)

        XCTAssertEqual(viewModel.targetCalories, 2500)
        XCTAssertEqual(viewModel.targetProtein, 200)
        XCTAssertEqual(viewModel.targetCarbs, 250)
        XCTAssertEqual(viewModel.targetFat, 70)
        XCTAssertEqual(viewModel.targetFiber, 35)
    }

    func testApplyPreset_FatLoss() {
        let fatLossPreset = GoalPreset.presets.first { $0.name == "Fat Loss" }!
        viewModel.applyPreset(fatLossPreset)

        XCTAssertEqual(viewModel.targetCalories, 1600)
        XCTAssertEqual(viewModel.targetProtein, 160)
        XCTAssertEqual(viewModel.targetCarbs, 120)
        XCTAssertEqual(viewModel.targetFat, 55)
        XCTAssertEqual(viewModel.targetFiber, 30)
    }

    func testApplyPreset_AthleticPerformance() {
        let athleticPreset = GoalPreset.presets.first { $0.name == "Athletic Performance" }!
        viewModel.applyPreset(athleticPreset)

        XCTAssertEqual(viewModel.targetCalories, 2800)
        XCTAssertEqual(viewModel.targetProtein, 175)
        XCTAssertEqual(viewModel.targetCarbs, 350)
        XCTAssertEqual(viewModel.targetFat, 75)
        XCTAssertEqual(viewModel.targetFiber, 40)
    }

    func testApplyPreset_RecoveryFocus() {
        let recoveryPreset = GoalPreset.presets.first { $0.name == "Recovery Focus" }!
        viewModel.applyPreset(recoveryPreset)

        XCTAssertEqual(viewModel.targetCalories, 2200)
        XCTAssertEqual(viewModel.targetProtein, 165)
        XCTAssertEqual(viewModel.targetCarbs, 220)
        XCTAssertEqual(viewModel.targetFat, 75)
        XCTAssertEqual(viewModel.targetFiber, 35)
    }

    // MARK: - Calculate From Body Weight Tests

    func testCalculateFromBodyWeight() {
        viewModel.targetCalories = 2400
        viewModel.proteinPerKg = 2.0  // 2g protein per kg

        viewModel.calculateFromBodyWeight(80.0)  // 80 kg person

        // Protein: 80 * 2.0 = 160g
        XCTAssertEqual(viewModel.targetProtein, 160,
            "Protein should be weight * proteinPerKg")

        // Protein calories: 160 * 4 = 640
        // Remaining: 2400 - 640 = 1760
        // Carbs: 1760 * 0.55 / 4 = 242
        // Fat: 1760 * 0.45 / 9 = 88

        XCTAssertEqual(Int(viewModel.targetCarbs), 242,
            "Carbs should be 55% of remaining calories / 4")
        XCTAssertEqual(Int(viewModel.targetFat), 88,
            "Fat should be 45% of remaining calories / 9")
    }

    func testCalculateFromBodyWeight_LightweightAthlete() {
        viewModel.targetCalories = 1800
        viewModel.proteinPerKg = 1.8

        viewModel.calculateFromBodyWeight(55.0)  // 55 kg person

        // Protein: 55 * 1.8 = 99g
        XCTAssertEqual(viewModel.targetProtein, 99)

        // Protein calories: 99 * 4 = 396
        // Remaining: 1800 - 396 = 1404
        let remainingCals = 1800.0 - (99.0 * 4)
        let expectedCarbs = (remainingCals * 0.55) / 4
        let expectedFat = (remainingCals * 0.45) / 9

        XCTAssertEqual(Int(viewModel.targetCarbs), Int(expectedCarbs))
        XCTAssertEqual(Int(viewModel.targetFat), Int(expectedFat))
    }

    func testCalculateFromBodyWeight_HighProteinPerKg() {
        viewModel.targetCalories = 3000
        viewModel.proteinPerKg = 2.5

        viewModel.calculateFromBodyWeight(100.0)  // 100 kg person

        // Protein: 100 * 2.5 = 250g
        XCTAssertEqual(viewModel.targetProtein, 250)
    }

    // MARK: - Goal Preset Tests

    func testGoalPresets_AllHaveRequiredFields() {
        for preset in GoalPreset.presets {
            XCTAssertFalse(preset.name.isEmpty, "Preset name should not be empty")
            XCTAssertFalse(preset.description.isEmpty, "Preset description should not be empty")
            XCTAssertGreaterThan(preset.calories, 0, "Preset calories should be positive")
            XCTAssertGreaterThan(preset.protein, 0, "Preset protein should be positive")
            XCTAssertGreaterThan(preset.carbs, 0, "Preset carbs should be positive")
            XCTAssertGreaterThan(preset.fat, 0, "Preset fat should be positive")
            XCTAssertGreaterThan(preset.fiber, 0, "Preset fiber should be positive")
        }
    }

    func testGoalPresets_Count() {
        XCTAssertEqual(GoalPreset.presets.count, 5,
            "Should have 5 preset options")
    }

    func testGoalPresets_UniqueNames() {
        let names = GoalPreset.presets.map { $0.name }
        let uniqueNames = Set(names)
        XCTAssertEqual(names.count, uniqueNames.count,
            "All preset names should be unique")
    }

    func testGoalPresets_UniqueIds() {
        let ids = GoalPreset.presets.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count,
            "All preset IDs should be unique")
    }

    // MARK: - GoalType Tests

    func testGoalType_DisplayNames() {
        XCTAssertEqual(GoalType.daily.displayName, "Daily")
        XCTAssertEqual(GoalType.weekly.displayName, "Weekly")
    }

    func testGoalType_AllCases() {
        XCTAssertEqual(GoalType.allCases.count, 2)
        XCTAssertTrue(GoalType.allCases.contains(.daily))
        XCTAssertTrue(GoalType.allCases.contains(.weekly))
    }

    // MARK: - Edge Cases

    func testMacroCalculations_VeryHighValues() {
        viewModel.targetCalories = 10000
        viewModel.targetProtein = 500
        viewModel.targetCarbs = 1000
        viewModel.targetFat = 400

        // 500*4 + 1000*4 + 400*9 = 2000 + 4000 + 3600 = 9600
        XCTAssertEqual(viewModel.macroCalories, 9600)
        XCTAssertEqual(viewModel.caloriesDifference, 400)
    }

    func testMacroCalculations_DecimalValues() {
        viewModel.targetProtein = 150.5
        viewModel.targetCarbs = 200.7
        viewModel.targetFat = 65.3

        // Int casting: (150*4 + 200*4 + 65*9) = 600 + 800 + 585 = 1985
        // With decimals: (150.5*4 + 200.7*4 + 65.3*9) = 602 + 802.8 + 587.7 = 1992.5
        let expected = Int(150.5 * 4) + Int(200.7 * 4) + Int(65.3 * 9)
        XCTAssertEqual(viewModel.macroCalories, expected)
    }
}
