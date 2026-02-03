//
//  NutritionViewModelTests.swift
//  PTPerformanceTests
//
//  Comprehensive unit tests for NutritionDashboardViewModel and MealLogViewModel
//  Tests meal logging, macro calculations, goal tracking, and meal plan generation
//

import XCTest
import Combine
@testable import PTPerformance

// MARK: - Mock Nutrition Service Protocol

protocol NutritionServiceProtocol {
    func fetchDailySummary(patientId: String, date: Date) async throws -> DailyNutritionSummary?
    func fetchGoalProgress(patientId: String) async throws -> NutritionGoalProgress?
    func fetchWeeklyTrends(patientId: String, weeks: Int) async throws -> [WeeklyNutritionTrend]
    func fetchTodaysLogs(patientId: String) async throws -> [NutritionLog]
    func createNutritionLog(_ dto: CreateNutritionLogDTO) async throws -> NutritionLog
    func deleteNutritionLog(id: UUID) async throws
}

// MARK: - Mock Nutrition Service

final class MockNutritionService: NutritionServiceProtocol {
    var mockDailySummary: DailyNutritionSummary?
    var mockGoalProgress: NutritionGoalProgress?
    var mockWeeklyTrends: [WeeklyNutritionTrend] = []
    var mockTodaysLogs: [NutritionLog] = []
    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "MockError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock error"])

    var fetchDailySummaryCallCount = 0
    var fetchGoalProgressCallCount = 0
    var createNutritionLogCallCount = 0
    var deleteNutritionLogCallCount = 0

    var lastCreatedLogDTO: CreateNutritionLogDTO?
    var lastDeletedLogId: UUID?

    func fetchDailySummary(patientId: String, date: Date) async throws -> DailyNutritionSummary? {
        fetchDailySummaryCallCount += 1
        if shouldThrowError { throw errorToThrow }
        return mockDailySummary
    }

    func fetchGoalProgress(patientId: String) async throws -> NutritionGoalProgress? {
        fetchGoalProgressCallCount += 1
        if shouldThrowError { throw errorToThrow }
        return mockGoalProgress
    }

    func fetchWeeklyTrends(patientId: String, weeks: Int) async throws -> [WeeklyNutritionTrend] {
        if shouldThrowError { throw errorToThrow }
        return mockWeeklyTrends
    }

    func fetchTodaysLogs(patientId: String) async throws -> [NutritionLog] {
        if shouldThrowError { throw errorToThrow }
        return mockTodaysLogs
    }

    func createNutritionLog(_ dto: CreateNutritionLogDTO) async throws -> NutritionLog {
        createNutritionLogCallCount += 1
        lastCreatedLogDTO = dto
        if shouldThrowError { throw errorToThrow }
        return createMockNutritionLog()
    }

    func deleteNutritionLog(id: UUID) async throws {
        deleteNutritionLogCallCount += 1
        lastDeletedLogId = id
        if shouldThrowError { throw errorToThrow }
    }

    private func createMockNutritionLog() -> NutritionLog {
        return NutritionLog(
            id: UUID(),
            patientId: UUID().uuidString,
            loggedAt: Date(),
            mealType: .lunch,
            foodItems: [],
            totalCalories: 500,
            totalProteinG: 30,
            totalCarbsG: 50,
            totalFatG: 20,
            totalFiberG: 5,
            notes: nil,
            photoUrl: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - NutritionDashboardViewModel Tests

@MainActor
final class NutritionViewModelTests: XCTestCase {

    var sut: NutritionDashboardViewModel!

    override func setUp() {
        super.setUp()
        sut = NutritionDashboardViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading, "isLoading should be false initially")
    }

    func testInitialState_ErrorIsNil() {
        XCTAssertNil(sut.error, "error should be nil initially")
    }

    func testInitialState_ShowErrorIsFalse() {
        XCTAssertFalse(sut.showError, "showError should be false initially")
    }

    func testInitialState_TodaySummaryIsNil() {
        XCTAssertNil(sut.todaySummary, "todaySummary should be nil initially")
    }

    func testInitialState_GoalProgressIsNil() {
        XCTAssertNil(sut.goalProgress, "goalProgress should be nil initially")
    }

    func testInitialState_WeeklyTrendsIsEmpty() {
        XCTAssertTrue(sut.weeklyTrends.isEmpty, "weeklyTrends should be empty initially")
    }

    func testInitialState_TodaysLogsIsEmpty() {
        XCTAssertTrue(sut.todaysLogs.isEmpty, "todaysLogs should be empty initially")
    }

    func testInitialState_ActiveGoalIsNil() {
        XCTAssertNil(sut.activeGoal, "activeGoal should be nil initially")
    }

    // MARK: - Computed Property Tests - hasLoggedToday

    func testHasLoggedToday_WhenEmpty_ReturnsFalse() {
        sut.todaysLogs = []
        XCTAssertFalse(sut.hasLoggedToday)
    }

    func testHasLoggedToday_WhenLogsExist_ReturnsTrue() {
        sut.todaysLogs = [createMockNutritionLog()]
        XCTAssertTrue(sut.hasLoggedToday)
    }

    // MARK: - Computed Property Tests - mealsLoggedToday

    func testMealsLoggedToday_ReturnsCorrectCount() {
        sut.todaysLogs = [createMockNutritionLog(), createMockNutritionLog(), createMockNutritionLog()]
        XCTAssertEqual(sut.mealsLoggedToday, 3)
    }

    // MARK: - Computed Property Tests - Daily Totals

    func testCaloriesToday_WhenNil_ReturnsZero() {
        sut.todaySummary = nil
        XCTAssertEqual(sut.caloriesToday, 0)
    }

    func testCaloriesToday_WhenSet_ReturnsValue() {
        sut.todaySummary = createMockDailySummary(calories: 1500)
        XCTAssertEqual(sut.caloriesToday, 1500)
    }

    func testProteinToday_WhenNil_ReturnsZero() {
        sut.todaySummary = nil
        XCTAssertEqual(sut.proteinToday, 0)
    }

    func testProteinToday_WhenSet_ReturnsValue() {
        sut.todaySummary = createMockDailySummary(protein: 120.0)
        XCTAssertEqual(sut.proteinToday, 120.0)
    }

    func testCarbsToday_WhenNil_ReturnsZero() {
        sut.todaySummary = nil
        XCTAssertEqual(sut.carbsToday, 0)
    }

    func testFatToday_WhenNil_ReturnsZero() {
        sut.todaySummary = nil
        XCTAssertEqual(sut.fatToday, 0)
    }

    // MARK: - Computed Property Tests - Goals

    func testCalorieGoal_WhenNoGoal_ReturnsDefault() {
        sut.activeGoal = nil
        sut.goalProgress = nil
        XCTAssertEqual(sut.calorieGoal, 2000)
    }

    func testProteinGoal_WhenNoGoal_ReturnsDefault() {
        sut.activeGoal = nil
        sut.goalProgress = nil
        XCTAssertEqual(sut.proteinGoal, 150)
    }

    // MARK: - Computed Property Tests - Progress

    func testCalorieProgress_WhenZeroGoal_ReturnsZero() {
        sut.activeGoal = createMockNutritionGoal(calories: 0)
        XCTAssertEqual(sut.calorieProgress, 0)
    }

    func testCalorieProgress_CalculatesCorrectly() {
        sut.todaySummary = createMockDailySummary(calories: 1000)
        sut.activeGoal = createMockNutritionGoal(calories: 2000)
        XCTAssertEqual(sut.calorieProgress, 0.5, accuracy: 0.01)
    }

    func testCalorieProgress_CapsAtOne() {
        sut.todaySummary = createMockDailySummary(calories: 3000)
        sut.activeGoal = createMockNutritionGoal(calories: 2000)
        XCTAssertEqual(sut.calorieProgress, 1.0)
    }

    func testProteinProgress_CalculatesCorrectly() {
        sut.todaySummary = createMockDailySummary(protein: 75)
        sut.activeGoal = createMockNutritionGoal(protein: 150)
        XCTAssertEqual(sut.proteinProgress, 0.5, accuracy: 0.01)
    }

    // MARK: - Computed Property Tests - Remaining

    func testRemainingCalories_CalculatesCorrectly() {
        sut.todaySummary = createMockDailySummary(calories: 1200)
        sut.activeGoal = createMockNutritionGoal(calories: 2000)
        XCTAssertEqual(sut.remainingCalories, 800)
    }

    func testRemainingCalories_NeverNegative() {
        sut.todaySummary = createMockDailySummary(calories: 2500)
        sut.activeGoal = createMockNutritionGoal(calories: 2000)
        XCTAssertEqual(sut.remainingCalories, 0)
    }

    func testRemainingProtein_CalculatesCorrectly() {
        sut.todaySummary = createMockDailySummary(protein: 100)
        sut.activeGoal = createMockNutritionGoal(protein: 150)
        XCTAssertEqual(sut.remainingProtein, 50)
    }

    // MARK: - UI State Tests

    func testSelectedMealType_CanBeSet() {
        XCTAssertNil(sut.selectedMealType)

        sut.selectedMealType = .breakfast
        XCTAssertEqual(sut.selectedMealType, .breakfast)

        sut.selectedMealType = .dinner
        XCTAssertEqual(sut.selectedMealType, .dinner)
    }

    func testShowLogMealSheet_CanBeToggled() {
        XCTAssertFalse(sut.showLogMealSheet)

        sut.showLogMealSheet = true
        XCTAssertTrue(sut.showLogMealSheet)

        sut.showLogMealSheet = false
        XCTAssertFalse(sut.showLogMealSheet)
    }

    func testShowGoalSheet_CanBeToggled() {
        XCTAssertFalse(sut.showGoalSheet)

        sut.showGoalSheet = true
        XCTAssertTrue(sut.showGoalSheet)
    }

    // MARK: - Quick Log Action Tests

    func testLogQuickMeal_SetsSelectedMealType() {
        sut.logQuickMeal(type: .breakfast)

        XCTAssertEqual(sut.selectedMealType, .breakfast)
        XCTAssertTrue(sut.showLogMealSheet)
    }

    func testLogQuickMeal_ShowsSheet() {
        sut.logQuickMeal(type: .lunch)

        XCTAssertTrue(sut.showLogMealSheet)
    }

    // MARK: - Goal Management Tests

    func testOpenGoalSettings_ShowsSheet() {
        sut.openGoalSettings()
        XCTAssertTrue(sut.showGoalSheet)
    }

    // MARK: - Refresh Tests

    func testForceRefresh_ResetsLoadedState() async {
        await sut.forceRefresh()
        XCTAssertFalse(sut.isLoading)
    }

    func testRetryLoadDashboard_ClearsError() async {
        sut.error = AppError.networkError
        sut.showError = true

        await sut.retryLoadDashboard()

        XCTAssertNil(sut.error)
        XCTAssertFalse(sut.showError)
    }

    // MARK: - Macro Chart Data Tests

    func testMacroChartData_DefaultValues() {
        let chartData = sut.macroChartData

        XCTAssertEqual(chartData.count, 3)
        XCTAssertTrue(chartData.contains { $0.macro == .protein })
        XCTAssertTrue(chartData.contains { $0.macro == .carbs })
        XCTAssertTrue(chartData.contains { $0.macro == .fat })
    }

    // MARK: - Weekly Chart Data Tests

    func testWeeklyChartData_ReversesOrder() {
        let trend1 = createMockWeeklyTrend(weekStart: Date(), avgCalories: 1800)
        let trend2 = createMockWeeklyTrend(
            weekStart: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
            avgCalories: 2000
        )

        sut.weeklyTrends = [trend1, trend2]

        let chartData = sut.weeklyChartData

        XCTAssertEqual(chartData.count, 2)
        // Reversed order: trend2 should be first
        XCTAssertEqual(chartData.first?.value, 2000)
    }

    // MARK: - Helper Methods

    private func createMockNutritionLog() -> NutritionLog {
        return NutritionLog(
            id: UUID(),
            patientId: UUID().uuidString,
            loggedAt: Date(),
            mealType: .lunch,
            foodItems: [],
            totalCalories: 500,
            totalProteinG: 30,
            totalCarbsG: 50,
            totalFatG: 20,
            totalFiberG: 5,
            notes: nil,
            photoUrl: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func createMockDailySummary(calories: Int = 0, protein: Double = 0, carbs: Double = 0, fat: Double = 0) -> DailyNutritionSummary {
        return DailyNutritionSummary(
            id: UUID(),
            patientId: UUID().uuidString,
            date: Date(),
            totalCalories: calories,
            totalProteinG: protein,
            totalCarbsG: carbs,
            totalFatG: fat,
            totalFiberG: 0,
            mealCount: 1,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func createMockNutritionGoal(calories: Int = 2000, protein: Double = 150) -> NutritionGoal {
        return NutritionGoal(
            id: UUID(),
            patientId: UUID().uuidString,
            goalType: .daily,
            targetCalories: calories,
            targetProteinG: protein,
            targetCarbsG: 200,
            targetFatG: 65,
            targetFiberG: 30,
            targetWaterMl: 2500,
            notes: nil,
            isActive: true,
            startDate: Date(),
            endDate: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func createMockWeeklyTrend(weekStart: Date, avgCalories: Double) -> WeeklyNutritionTrend {
        return WeeklyNutritionTrend(
            weekStart: weekStart,
            avgDailyCalories: avgCalories,
            avgDailyProtein: 150,
            avgDailyCarbs: 200,
            avgDailyFat: 65,
            daysLogged: 7,
            targetCalories: 2000
        )
    }
}

// MARK: - MealLogViewModel Tests

@MainActor
final class MealLogViewModelTests: XCTestCase {

    var sut: MealLogViewModel!

    override func setUp() {
        super.setUp()
        sut = MealLogViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading)
    }

    func testInitialState_IsSavingIsFalse() {
        XCTAssertFalse(sut.isSaving)
    }

    func testInitialState_ErrorIsNil() {
        XCTAssertNil(sut.error)
    }

    func testInitialState_MealTypeIsLunch() {
        XCTAssertEqual(sut.mealType, .lunch)
    }

    func testInitialState_FoodItemsIsEmpty() {
        XCTAssertTrue(sut.foodItems.isEmpty)
    }

    func testInitialState_NotesIsEmpty() {
        XCTAssertEqual(sut.notes, "")
    }

    func testInitialState_SearchTextIsEmpty() {
        XCTAssertEqual(sut.searchText, "")
    }

    func testInitialState_SearchResultsIsEmpty() {
        XCTAssertTrue(sut.searchResults.isEmpty)
    }

    // MARK: - Initialization Tests

    func testInit_WithMealType() {
        let vm = MealLogViewModel(mealType: .breakfast)
        XCTAssertEqual(vm.mealType, .breakfast)
    }

    // MARK: - Computed Property Tests - Totals

    func testTotalCalories_WhenEmpty_ReturnsZero() {
        sut.foodItems = []
        XCTAssertEqual(sut.totalCalories, 0)
    }

    func testTotalCalories_SumsCorrectly() {
        sut.foodItems = [
            createMockFoodItem(calories: 200),
            createMockFoodItem(calories: 300),
            createMockFoodItem(calories: 150)
        ]
        XCTAssertEqual(sut.totalCalories, 650)
    }

    func testTotalProtein_SumsCorrectly() {
        sut.foodItems = [
            createMockFoodItem(protein: 25),
            createMockFoodItem(protein: 30)
        ]
        XCTAssertEqual(sut.totalProtein, 55)
    }

    func testTotalCarbs_SumsCorrectly() {
        sut.foodItems = [
            createMockFoodItem(carbs: 40),
            createMockFoodItem(carbs: 50)
        ]
        XCTAssertEqual(sut.totalCarbs, 90)
    }

    func testTotalFat_SumsCorrectly() {
        sut.foodItems = [
            createMockFoodItem(fat: 10),
            createMockFoodItem(fat: 15)
        ]
        XCTAssertEqual(sut.totalFat, 25)
    }

    // MARK: - Computed Property Tests - canSave

    func testCanSave_WhenEmpty_ReturnsFalse() {
        sut.foodItems = []
        XCTAssertFalse(sut.canSave)
    }

    func testCanSave_WhenHasFoodItems_ReturnsTrue() {
        sut.foodItems = [createMockFoodItem()]
        XCTAssertTrue(sut.canSave)
    }

    // MARK: - Computed Property Tests - macroSummary

    func testMacroSummary_FormatsCorrectly() {
        sut.foodItems = [createMockFoodItem(protein: 30, carbs: 50, fat: 20)]

        let summary = sut.macroSummary
        XCTAssertTrue(summary.contains("P:"))
        XCTAssertTrue(summary.contains("C:"))
        XCTAssertTrue(summary.contains("F:"))
    }

    // MARK: - Add Food Tests

    func testAddFood_FromSearchResult() {
        let searchResult = createMockFoodSearchResult()

        sut.addFood(searchResult)

        XCTAssertEqual(sut.foodItems.count, 1)
        XCTAssertEqual(sut.foodItems.first?.name, searchResult.name)
    }

    func testAddFood_WithServings() {
        let searchResult = createMockFoodSearchResult()

        sut.addFood(searchResult, servings: 2.0)

        XCTAssertEqual(sut.foodItems.first?.servings, 2.0)
    }

    // MARK: - Remove Food Tests

    func testRemoveFood_AtIndex() {
        sut.foodItems = [
            createMockFoodItem(name: "Food 1"),
            createMockFoodItem(name: "Food 2"),
            createMockFoodItem(name: "Food 3")
        ]

        sut.removeFood(at: 1)

        XCTAssertEqual(sut.foodItems.count, 2)
        XCTAssertEqual(sut.foodItems[0].name, "Food 1")
        XCTAssertEqual(sut.foodItems[1].name, "Food 3")
    }

    func testRemoveFood_AtInvalidIndex_DoesNotCrash() {
        sut.foodItems = [createMockFoodItem()]

        sut.removeFood(at: 10)  // Invalid index

        XCTAssertEqual(sut.foodItems.count, 1)  // Unchanged
    }

    func testRemoveFood_ByItem() {
        let food1 = createMockFoodItem(name: "Food 1")
        let food2 = createMockFoodItem(name: "Food 2")
        sut.foodItems = [food1, food2]

        sut.removeFood(food1)

        XCTAssertEqual(sut.foodItems.count, 1)
        XCTAssertEqual(sut.foodItems.first?.name, "Food 2")
    }

    // MARK: - Update Servings Tests

    func testUpdateServings_UpdatesCorrectItem() {
        let food = createMockFoodItem(name: "Test Food")
        sut.foodItems = [food]

        sut.updateServings(for: food, servings: 3.0)

        XCTAssertEqual(sut.foodItems.first?.servings, 3.0)
    }

    // MARK: - Edit Food Tests

    func testEditFood_SetsSelectedFood() {
        let food = createMockFoodItem()
        sut.editFood(food)

        XCTAssertEqual(sut.selectedFood?.id, food.id)
        XCTAssertTrue(sut.showFoodDetailSheet)
    }

    // MARK: - Search Tests

    func testSearchFoods_WithEmptyText_ClearsResults() {
        sut.searchResults = [createMockFoodSearchResult()]
        sut.searchText = ""

        sut.searchFoods()

        XCTAssertTrue(sut.searchResults.isEmpty)
    }

    // MARK: - Reset Tests

    func testReset_ClearsAllFields() {
        sut.foodItems = [createMockFoodItem()]
        sut.notes = "Test notes"
        sut.searchText = "chicken"
        sut.searchResults = [createMockFoodSearchResult()]

        sut.reset()

        XCTAssertTrue(sut.foodItems.isEmpty)
        XCTAssertEqual(sut.notes, "")
        XCTAssertEqual(sut.searchText, "")
        XCTAssertTrue(sut.searchResults.isEmpty)
    }

    // MARK: - Sheet State Tests

    func testShowFoodDetailSheet_CanBeToggled() {
        XCTAssertFalse(sut.showFoodDetailSheet)

        sut.showFoodDetailSheet = true
        XCTAssertTrue(sut.showFoodDetailSheet)

        sut.showFoodDetailSheet = false
        XCTAssertFalse(sut.showFoodDetailSheet)
    }

    func testShowAddCustomFoodSheet_CanBeToggled() {
        XCTAssertFalse(sut.showAddCustomFoodSheet)

        sut.showAddCustomFoodSheet = true
        XCTAssertTrue(sut.showAddCustomFoodSheet)
    }

    // MARK: - Helper Methods

    private func createMockFoodItem(
        name: String = "Test Food",
        calories: Int = 200,
        protein: Double = 20,
        carbs: Double = 25,
        fat: Double = 10
    ) -> LoggedFoodItem {
        return LoggedFoodItem(
            foodItemId: UUID(),
            name: name,
            servings: 1.0,
            servingSize: "1 cup",
            calories: calories,
            proteinG: protein,
            carbsG: carbs,
            fatG: fat
        )
    }

    private func createMockFoodSearchResult() -> FoodSearchResult {
        return FoodSearchResult(
            id: UUID(),
            name: "Test Food",
            servingSize: "1 cup",
            calories: 200,
            proteinG: 20,
            carbsG: 25,
            fatG: 10,
            fiberG: 5,
            source: "custom"
        )
    }
}

// MARK: - MealType Tests

final class MealTypeTests: XCTestCase {

    func testAllCasesExist() {
        XCTAssertTrue(MealType.allCases.contains(.breakfast))
        XCTAssertTrue(MealType.allCases.contains(.lunch))
        XCTAssertTrue(MealType.allCases.contains(.dinner))
        XCTAssertTrue(MealType.allCases.contains(.snack))
    }

    func testRawValues() {
        XCTAssertEqual(MealType.breakfast.rawValue, "breakfast")
        XCTAssertEqual(MealType.lunch.rawValue, "lunch")
        XCTAssertEqual(MealType.dinner.rawValue, "dinner")
        XCTAssertEqual(MealType.snack.rawValue, "snack")
    }
}

// MARK: - MacroType Tests

final class MacroTypeTests: XCTestCase {

    func testCaloriesPerGram_Protein() {
        XCTAssertEqual(MacroType.protein.caloriesPerGram, 4.0)
    }

    func testCaloriesPerGram_Carbs() {
        XCTAssertEqual(MacroType.carbs.caloriesPerGram, 4.0)
    }

    func testCaloriesPerGram_Fat() {
        XCTAssertEqual(MacroType.fat.caloriesPerGram, 9.0)
    }
}
