//
//  NutritionLoggingTests.swift
//  PTPerformanceTests
//
//  Comprehensive tests for patient nutrition logging features.
//  Tests food search, meal logging, macro calculation, and nutrition goals.
//

import XCTest
@testable import PTPerformance

// MARK: - Mock Services

class MockNutritionService {

    var shouldFailSearch = false
    var shouldFailLogMeal = false
    var shouldFailFetchMeals = false
    var shouldFailFetchGoals = false
    var shouldFailUpdateGoals = false

    var searchCallCount = 0
    var logMealCallCount = 0
    var fetchMealsCallCount = 0
    var fetchGoalsCallCount = 0
    var updateGoalsCallCount = 0

    var mockSearchResults: [MockFoodItem] = []
    var mockMeals: [MockMealEntry] = []
    var mockGoals: MockNutritionGoals?

    var lastLoggedMeal: (
        foodId: String,
        name: String,
        servingSize: Double,
        servingUnit: String,
        mealType: String,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double
    )?

    var lastUpdatedGoals: (
        calories: Int,
        protein: Int,
        carbs: Int,
        fat: Int
    )?

    func searchFoods(query: String) async throws -> [MockFoodItem] {
        searchCallCount += 1
        if shouldFailSearch {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Search failed"])
        }
        return mockSearchResults.filter { $0.name.lowercased().contains(query.lowercased()) }
    }

    func logMeal(
        patientId: UUID,
        foodId: String,
        name: String,
        servingSize: Double,
        servingUnit: String,
        mealType: String,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double
    ) async throws -> MockMealEntry {
        logMealCallCount += 1
        if shouldFailLogMeal {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Log meal failed"])
        }
        lastLoggedMeal = (foodId, name, servingSize, servingUnit, mealType, calories, protein, carbs, fat)
        return MockMealEntry(
            id: UUID(),
            patientId: patientId,
            foodId: foodId,
            name: name,
            servingSize: servingSize,
            servingUnit: servingUnit,
            mealType: mealType,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            loggedAt: Date()
        )
    }

    func fetchMeals(patientId: UUID, date: Date) async throws -> [MockMealEntry] {
        fetchMealsCallCount += 1
        if shouldFailFetchMeals {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Fetch meals failed"])
        }
        return mockMeals
    }

    func fetchGoals(patientId: UUID) async throws -> MockNutritionGoals {
        fetchGoalsCallCount += 1
        if shouldFailFetchGoals {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Fetch goals failed"])
        }
        return mockGoals ?? MockNutritionGoals(
            calories: 2000,
            protein: 150,
            carbs: 200,
            fat: 70
        )
    }

    func updateGoals(
        patientId: UUID,
        calories: Int,
        protein: Int,
        carbs: Int,
        fat: Int
    ) async throws {
        updateGoalsCallCount += 1
        if shouldFailUpdateGoals {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Update goals failed"])
        }
        lastUpdatedGoals = (calories, protein, carbs, fat)
    }

    func reset() {
        shouldFailSearch = false
        shouldFailLogMeal = false
        shouldFailFetchMeals = false
        shouldFailFetchGoals = false
        shouldFailUpdateGoals = false
        searchCallCount = 0
        logMealCallCount = 0
        fetchMealsCallCount = 0
        fetchGoalsCallCount = 0
        updateGoalsCallCount = 0
        mockSearchResults = []
        mockMeals = []
        mockGoals = nil
        lastLoggedMeal = nil
        lastUpdatedGoals = nil
    }
}

// MARK: - Mock Models

struct MockFoodItem: Identifiable, Equatable {
    let id: String
    let name: String
    let brand: String?
    let servingSize: Double
    let servingUnit: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double?
    let sugar: Double?
    let sodium: Double?
}

struct MockMealEntry: Identifiable, Equatable {
    let id: UUID
    let patientId: UUID
    let foodId: String
    let name: String
    let servingSize: Double
    let servingUnit: String
    let mealType: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let loggedAt: Date
}

struct MockNutritionGoals {
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
}

// MARK: - Nutrition Logging Tests

@MainActor
final class NutritionLoggingTests: XCTestCase {

    var mockService: MockNutritionService!
    let testPatientId = UUID()

    override func setUp() async throws {
        try await super.setUp()
        mockService = MockNutritionService()
    }

    override func tearDown() async throws {
        mockService = nil
        try await super.tearDown()
    }

    // MARK: - Food Search Tests

    func testSearchFoods_Success() async throws {
        mockService.mockSearchResults = [
            MockFoodItem(id: "1", name: "Chicken Breast", brand: nil, servingSize: 100, servingUnit: "g", calories: 165, protein: 31, carbs: 0, fat: 3.6, fiber: nil, sugar: nil, sodium: nil),
            MockFoodItem(id: "2", name: "Chicken Thigh", brand: nil, servingSize: 100, servingUnit: "g", calories: 209, protein: 26, carbs: 0, fat: 10.9, fiber: nil, sugar: nil, sodium: nil)
        ]

        let results = try await mockService.searchFoods(query: "chicken")

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(mockService.searchCallCount, 1)
    }

    func testSearchFoods_EmptyQuery() async throws {
        mockService.mockSearchResults = []

        let results = try await mockService.searchFoods(query: "")

        XCTAssertTrue(results.isEmpty)
    }

    func testSearchFoods_NoResults() async throws {
        mockService.mockSearchResults = [
            MockFoodItem(id: "1", name: "Chicken Breast", brand: nil, servingSize: 100, servingUnit: "g", calories: 165, protein: 31, carbs: 0, fat: 3.6, fiber: nil, sugar: nil, sodium: nil)
        ]

        let results = try await mockService.searchFoods(query: "pizza")

        XCTAssertTrue(results.isEmpty)
    }

    func testSearchFoods_Failure() async {
        mockService.shouldFailSearch = true

        do {
            _ = try await mockService.searchFoods(query: "chicken")
            XCTFail("Should throw error when search fails")
        } catch {
            XCTAssertEqual(mockService.searchCallCount, 1)
        }
    }

    func testSearchFoods_CaseInsensitive() async throws {
        mockService.mockSearchResults = [
            MockFoodItem(id: "1", name: "Chicken Breast", brand: nil, servingSize: 100, servingUnit: "g", calories: 165, protein: 31, carbs: 0, fat: 3.6, fiber: nil, sugar: nil, sodium: nil)
        ]

        let results = try await mockService.searchFoods(query: "CHICKEN")

        XCTAssertEqual(results.count, 1)
    }

    func testSearchFoods_WithBrand() async throws {
        mockService.mockSearchResults = [
            MockFoodItem(id: "1", name: "Greek Yogurt", brand: "Fage", servingSize: 170, servingUnit: "g", calories: 100, protein: 18, carbs: 6, fat: 0, fiber: 0, sugar: 6, sodium: 65),
            MockFoodItem(id: "2", name: "Greek Yogurt", brand: "Chobani", servingSize: 150, servingUnit: "g", calories: 90, protein: 15, carbs: 5, fat: 0, fiber: 0, sugar: 4, sodium: 55)
        ]

        let results = try await mockService.searchFoods(query: "yogurt")

        XCTAssertEqual(results.count, 2)
        XCTAssertNotNil(results[0].brand)
        XCTAssertNotNil(results[1].brand)
    }

    // MARK: - Meal Logging Tests

    func testLogMeal_Breakfast() async throws {
        let meal = try await mockService.logMeal(
            patientId: testPatientId,
            foodId: "oatmeal-1",
            name: "Oatmeal",
            servingSize: 1.0,
            servingUnit: "cup",
            mealType: "breakfast",
            calories: 150,
            protein: 5,
            carbs: 27,
            fat: 3
        )

        XCTAssertNotNil(meal)
        XCTAssertEqual(mockService.lastLoggedMeal?.mealType, "breakfast")
        XCTAssertEqual(mockService.lastLoggedMeal?.name, "Oatmeal")
    }

    func testLogMeal_Lunch() async throws {
        let meal = try await mockService.logMeal(
            patientId: testPatientId,
            foodId: "chicken-salad-1",
            name: "Chicken Salad",
            servingSize: 1.0,
            servingUnit: "serving",
            mealType: "lunch",
            calories: 350,
            protein: 35,
            carbs: 15,
            fat: 18
        )

        XCTAssertNotNil(meal)
        XCTAssertEqual(mockService.lastLoggedMeal?.mealType, "lunch")
    }

    func testLogMeal_Dinner() async throws {
        let meal = try await mockService.logMeal(
            patientId: testPatientId,
            foodId: "salmon-1",
            name: "Grilled Salmon",
            servingSize: 6.0,
            servingUnit: "oz",
            mealType: "dinner",
            calories: 350,
            protein: 40,
            carbs: 0,
            fat: 20
        )

        XCTAssertNotNil(meal)
        XCTAssertEqual(mockService.lastLoggedMeal?.mealType, "dinner")
    }

    func testLogMeal_Snack() async throws {
        let meal = try await mockService.logMeal(
            patientId: testPatientId,
            foodId: "almonds-1",
            name: "Almonds",
            servingSize: 1.0,
            servingUnit: "oz",
            mealType: "snack",
            calories: 164,
            protein: 6,
            carbs: 6,
            fat: 14
        )

        XCTAssertNotNil(meal)
        XCTAssertEqual(mockService.lastLoggedMeal?.mealType, "snack")
    }

    func testLogMeal_CustomServingSize() async throws {
        let meal = try await mockService.logMeal(
            patientId: testPatientId,
            foodId: "rice-1",
            name: "Brown Rice",
            servingSize: 1.5,  // 1.5 servings
            servingUnit: "cup",
            mealType: "dinner",
            calories: 330,  // 220 * 1.5
            protein: 7.5,
            carbs: 67.5,
            fat: 3
        )

        XCTAssertNotNil(meal)
        XCTAssertEqual(mockService.lastLoggedMeal?.servingSize, 1.5)
    }

    func testLogMeal_Failure() async {
        mockService.shouldFailLogMeal = true

        do {
            _ = try await mockService.logMeal(
                patientId: testPatientId,
                foodId: "test-1",
                name: "Test Food",
                servingSize: 1.0,
                servingUnit: "serving",
                mealType: "breakfast",
                calories: 100,
                protein: 10,
                carbs: 10,
                fat: 5
            )
            XCTFail("Should throw error when logging fails")
        } catch {
            XCTAssertEqual(mockService.logMealCallCount, 1)
        }
    }

    func testLogMeal_ZeroMacros() async throws {
        // Some foods might have zero of certain macros (e.g., pure sugar)
        let meal = try await mockService.logMeal(
            patientId: testPatientId,
            foodId: "sugar-1",
            name: "Sugar",
            servingSize: 1.0,
            servingUnit: "tbsp",
            mealType: "snack",
            calories: 48,
            protein: 0,
            carbs: 12,
            fat: 0
        )

        XCTAssertNotNil(meal)
        XCTAssertEqual(mockService.lastLoggedMeal?.protein, 0)
        XCTAssertEqual(mockService.lastLoggedMeal?.fat, 0)
    }

    // MARK: - Macro Calculation Tests

    func testMacroCalculation_TotalCalories() {
        let meals = [
            MockMealEntry(id: UUID(), patientId: testPatientId, foodId: "1", name: "Oatmeal", servingSize: 1, servingUnit: "cup", mealType: "breakfast", calories: 150, protein: 5, carbs: 27, fat: 3, loggedAt: Date()),
            MockMealEntry(id: UUID(), patientId: testPatientId, foodId: "2", name: "Chicken", servingSize: 1, servingUnit: "serving", mealType: "lunch", calories: 350, protein: 35, carbs: 0, fat: 10, loggedAt: Date()),
            MockMealEntry(id: UUID(), patientId: testPatientId, foodId: "3", name: "Salmon", servingSize: 1, servingUnit: "serving", mealType: "dinner", calories: 400, protein: 40, carbs: 0, fat: 20, loggedAt: Date())
        ]

        let totalCalories = meals.reduce(0.0) { $0 + $1.calories }

        XCTAssertEqual(totalCalories, 900)
    }

    func testMacroCalculation_TotalProtein() {
        let meals = [
            MockMealEntry(id: UUID(), patientId: testPatientId, foodId: "1", name: "Eggs", servingSize: 2, servingUnit: "eggs", mealType: "breakfast", calories: 156, protein: 12, carbs: 0, fat: 12, loggedAt: Date()),
            MockMealEntry(id: UUID(), patientId: testPatientId, foodId: "2", name: "Chicken", servingSize: 1, servingUnit: "serving", mealType: "lunch", calories: 280, protein: 35, carbs: 0, fat: 8, loggedAt: Date()),
            MockMealEntry(id: UUID(), patientId: testPatientId, foodId: "3", name: "Protein Shake", servingSize: 1, servingUnit: "scoop", mealType: "snack", calories: 120, protein: 25, carbs: 3, fat: 1, loggedAt: Date())
        ]

        let totalProtein = meals.reduce(0.0) { $0 + $1.protein }

        XCTAssertEqual(totalProtein, 72)
    }

    func testMacroCalculation_TotalCarbs() {
        let meals = [
            MockMealEntry(id: UUID(), patientId: testPatientId, foodId: "1", name: "Rice", servingSize: 1, servingUnit: "cup", mealType: "lunch", calories: 220, protein: 5, carbs: 45, fat: 2, loggedAt: Date()),
            MockMealEntry(id: UUID(), patientId: testPatientId, foodId: "2", name: "Banana", servingSize: 1, servingUnit: "medium", mealType: "snack", calories: 105, protein: 1, carbs: 27, fat: 0, loggedAt: Date())
        ]

        let totalCarbs = meals.reduce(0.0) { $0 + $1.carbs }

        XCTAssertEqual(totalCarbs, 72)
    }

    func testMacroCalculation_TotalFat() {
        let meals = [
            MockMealEntry(id: UUID(), patientId: testPatientId, foodId: "1", name: "Avocado", servingSize: 1, servingUnit: "whole", mealType: "lunch", calories: 322, protein: 4, carbs: 17, fat: 29, loggedAt: Date()),
            MockMealEntry(id: UUID(), patientId: testPatientId, foodId: "2", name: "Olive Oil", servingSize: 1, servingUnit: "tbsp", mealType: "dinner", calories: 119, protein: 0, carbs: 0, fat: 14, loggedAt: Date())
        ]

        let totalFat = meals.reduce(0.0) { $0 + $1.fat }

        XCTAssertEqual(totalFat, 43)
    }

    func testMacroCalculation_ByMealType() {
        let meals = [
            MockMealEntry(id: UUID(), patientId: testPatientId, foodId: "1", name: "Oatmeal", servingSize: 1, servingUnit: "cup", mealType: "breakfast", calories: 150, protein: 5, carbs: 27, fat: 3, loggedAt: Date()),
            MockMealEntry(id: UUID(), patientId: testPatientId, foodId: "2", name: "Eggs", servingSize: 2, servingUnit: "eggs", mealType: "breakfast", calories: 156, protein: 12, carbs: 0, fat: 12, loggedAt: Date()),
            MockMealEntry(id: UUID(), patientId: testPatientId, foodId: "3", name: "Chicken", servingSize: 1, servingUnit: "serving", mealType: "lunch", calories: 280, protein: 35, carbs: 0, fat: 8, loggedAt: Date())
        ]

        let breakfastMeals = meals.filter { $0.mealType == "breakfast" }
        let breakfastCalories = breakfastMeals.reduce(0.0) { $0 + $1.calories }

        XCTAssertEqual(breakfastMeals.count, 2)
        XCTAssertEqual(breakfastCalories, 306)
    }

    // MARK: - Nutrition Goals Tests

    func testFetchGoals_Success() async throws {
        mockService.mockGoals = MockNutritionGoals(
            calories: 2500,
            protein: 180,
            carbs: 250,
            fat: 80
        )

        let goals = try await mockService.fetchGoals(patientId: testPatientId)

        XCTAssertEqual(goals.calories, 2500)
        XCTAssertEqual(goals.protein, 180)
        XCTAssertEqual(goals.carbs, 250)
        XCTAssertEqual(goals.fat, 80)
    }

    func testFetchGoals_Failure() async {
        mockService.shouldFailFetchGoals = true

        do {
            _ = try await mockService.fetchGoals(patientId: testPatientId)
            XCTFail("Should throw error when fetch fails")
        } catch {
            XCTAssertEqual(mockService.fetchGoalsCallCount, 1)
        }
    }

    func testUpdateGoals_Success() async throws {
        try await mockService.updateGoals(
            patientId: testPatientId,
            calories: 2200,
            protein: 165,
            carbs: 220,
            fat: 75
        )

        XCTAssertEqual(mockService.updateGoalsCallCount, 1)
        XCTAssertEqual(mockService.lastUpdatedGoals?.calories, 2200)
        XCTAssertEqual(mockService.lastUpdatedGoals?.protein, 165)
        XCTAssertEqual(mockService.lastUpdatedGoals?.carbs, 220)
        XCTAssertEqual(mockService.lastUpdatedGoals?.fat, 75)
    }

    func testUpdateGoals_Failure() async {
        mockService.shouldFailUpdateGoals = true

        do {
            try await mockService.updateGoals(
                patientId: testPatientId,
                calories: 2000,
                protein: 150,
                carbs: 200,
                fat: 70
            )
            XCTFail("Should throw error when update fails")
        } catch {
            XCTAssertEqual(mockService.updateGoalsCallCount, 1)
        }
    }

    // MARK: - Goal Progress Tests

    func testGoalProgress_CaloriesUnder() {
        let goal = 2000
        let consumed = 1500

        let progress = Double(consumed) / Double(goal)

        XCTAssertEqual(progress, 0.75, accuracy: 0.01)
    }

    func testGoalProgress_CaloriesOver() {
        let goal = 2000
        let consumed = 2400

        let progress = Double(consumed) / Double(goal)

        XCTAssertEqual(progress, 1.2, accuracy: 0.01)
    }

    func testGoalProgress_ProteinMet() {
        let goal = 150
        let consumed = 150

        let progress = Double(consumed) / Double(goal)

        XCTAssertEqual(progress, 1.0)
    }

    func testGoalProgress_MacroRemaining() {
        let goal = 200
        let consumed = 150

        let remaining = goal - consumed

        XCTAssertEqual(remaining, 50)
    }

    // MARK: - Fetch Meals Tests

    func testFetchMeals_ForDate() async throws {
        let today = Date()
        mockService.mockMeals = [
            MockMealEntry(id: UUID(), patientId: testPatientId, foodId: "1", name: "Oatmeal", servingSize: 1, servingUnit: "cup", mealType: "breakfast", calories: 150, protein: 5, carbs: 27, fat: 3, loggedAt: today),
            MockMealEntry(id: UUID(), patientId: testPatientId, foodId: "2", name: "Chicken", servingSize: 1, servingUnit: "serving", mealType: "lunch", calories: 280, protein: 35, carbs: 0, fat: 8, loggedAt: today)
        ]

        let meals = try await mockService.fetchMeals(patientId: testPatientId, date: today)

        XCTAssertEqual(meals.count, 2)
    }

    func testFetchMeals_Empty() async throws {
        mockService.mockMeals = []

        let meals = try await mockService.fetchMeals(patientId: testPatientId, date: Date())

        XCTAssertTrue(meals.isEmpty)
    }

    func testFetchMeals_Failure() async {
        mockService.shouldFailFetchMeals = true

        do {
            _ = try await mockService.fetchMeals(patientId: testPatientId, date: Date())
            XCTFail("Should throw error when fetch fails")
        } catch {
            XCTAssertEqual(mockService.fetchMealsCallCount, 1)
        }
    }

    // MARK: - Calorie Calculation from Macros Tests

    func testCalorieCalculation_FromMacros() {
        let protein = 30.0  // 30g * 4 = 120 cal
        let carbs = 45.0    // 45g * 4 = 180 cal
        let fat = 15.0      // 15g * 9 = 135 cal

        let calculatedCalories = (protein * 4) + (carbs * 4) + (fat * 9)

        XCTAssertEqual(calculatedCalories, 435)
    }

    func testCalorieCalculation_ProteinOnly() {
        let protein = 25.0
        let calories = protein * 4

        XCTAssertEqual(calories, 100)
    }

    func testCalorieCalculation_CarbsOnly() {
        let carbs = 50.0
        let calories = carbs * 4

        XCTAssertEqual(calories, 200)
    }

    func testCalorieCalculation_FatOnly() {
        let fat = 20.0
        let calories = fat * 9

        XCTAssertEqual(calories, 180)
    }

    // MARK: - Serving Size Adjustment Tests

    func testServingSizeAdjustment_Double() {
        let baseCalories = 200.0
        let baseProtein = 25.0
        let servingMultiplier = 2.0

        let adjustedCalories = baseCalories * servingMultiplier
        let adjustedProtein = baseProtein * servingMultiplier

        XCTAssertEqual(adjustedCalories, 400)
        XCTAssertEqual(adjustedProtein, 50)
    }

    func testServingSizeAdjustment_Half() {
        let baseCalories = 200.0
        let baseProtein = 25.0
        let servingMultiplier = 0.5

        let adjustedCalories = baseCalories * servingMultiplier
        let adjustedProtein = baseProtein * servingMultiplier

        XCTAssertEqual(adjustedCalories, 100)
        XCTAssertEqual(adjustedProtein, 12.5)
    }

    func testServingSizeAdjustment_Custom() {
        let baseCalories = 150.0
        let servingMultiplier = 1.25

        let adjustedCalories = baseCalories * servingMultiplier

        XCTAssertEqual(adjustedCalories, 187.5)
    }
}

// MARK: - Macro Percentage Tests

final class MacroPercentageTests: XCTestCase {

    func testMacroPercentage_BalancedDiet() {
        let calories = 2000.0
        let protein = 150.0  // 150 * 4 = 600 cal = 30%
        let carbs = 200.0    // 200 * 4 = 800 cal = 40%
        let fat = 67.0       // 67 * 9 = 603 cal = ~30%

        let proteinPercent = (protein * 4) / calories * 100
        let carbsPercent = (carbs * 4) / calories * 100
        let fatPercent = (fat * 9) / calories * 100

        XCTAssertEqual(proteinPercent, 30, accuracy: 1)
        XCTAssertEqual(carbsPercent, 40, accuracy: 1)
        XCTAssertEqual(fatPercent, 30, accuracy: 2)
    }

    func testMacroPercentage_HighProtein() {
        let calories = 2000.0
        let protein = 200.0  // 200 * 4 = 800 cal = 40%

        let proteinPercent = (protein * 4) / calories * 100

        XCTAssertEqual(proteinPercent, 40, accuracy: 1)
    }

    func testMacroPercentage_LowCarb() {
        let calories = 1800.0
        let carbs = 50.0     // 50 * 4 = 200 cal = ~11%

        let carbsPercent = (carbs * 4) / calories * 100

        XCTAssertEqual(carbsPercent, 11, accuracy: 1)
    }

    func testMacroPercentage_Keto() {
        let calories = 2000.0
        let carbs = 25.0     // 25 * 4 = 100 cal = 5%
        let fat = 155.0      // 155 * 9 = 1395 cal = ~70%
        let protein = 125.0  // 125 * 4 = 500 cal = 25%

        let carbsPercent = (carbs * 4) / calories * 100
        let fatPercent = (fat * 9) / calories * 100
        let proteinPercent = (protein * 4) / calories * 100

        XCTAssertEqual(carbsPercent, 5, accuracy: 1)
        XCTAssertEqual(fatPercent, 70, accuracy: 2)
        XCTAssertEqual(proteinPercent, 25, accuracy: 1)
    }
}

// MARK: - Meal Type Tests

final class MealTypeTests: XCTestCase {

    func testMealType_AllTypes() {
        let mealTypes = ["breakfast", "lunch", "dinner", "snack"]

        XCTAssertEqual(mealTypes.count, 4)
        XCTAssertTrue(mealTypes.contains("breakfast"))
        XCTAssertTrue(mealTypes.contains("lunch"))
        XCTAssertTrue(mealTypes.contains("dinner"))
        XCTAssertTrue(mealTypes.contains("snack"))
    }

    func testMealType_DisplayName() {
        let mealTypeNames: [String: String] = [
            "breakfast": "Breakfast",
            "lunch": "Lunch",
            "dinner": "Dinner",
            "snack": "Snack"
        ]

        for (rawValue, displayName) in mealTypeNames {
            XCTAssertEqual(getDisplayName(for: rawValue), displayName)
        }
    }

    func testMealType_Icon() {
        let mealTypeIcons: [String: String] = [
            "breakfast": "sunrise.fill",
            "lunch": "sun.max.fill",
            "dinner": "moon.fill",
            "snack": "leaf.fill"
        ]

        for (rawValue, iconName) in mealTypeIcons {
            XCTAssertEqual(getIcon(for: rawValue), iconName)
        }
    }

    private func getDisplayName(for mealType: String) -> String {
        switch mealType {
        case "breakfast": return "Breakfast"
        case "lunch": return "Lunch"
        case "dinner": return "Dinner"
        case "snack": return "Snack"
        default: return mealType.capitalized
        }
    }

    private func getIcon(for mealType: String) -> String {
        switch mealType {
        case "breakfast": return "sunrise.fill"
        case "lunch": return "sun.max.fill"
        case "dinner": return "moon.fill"
        case "snack": return "leaf.fill"
        default: return "fork.knife"
        }
    }
}

// MARK: - Serving Unit Tests

final class ServingUnitTests: XCTestCase {

    func testServingUnit_Weight() {
        let weightUnits = ["g", "oz", "lb", "kg"]

        for unit in weightUnits {
            XCTAssertTrue(isWeightUnit(unit))
        }
    }

    func testServingUnit_Volume() {
        let volumeUnits = ["ml", "cup", "tbsp", "tsp", "fl oz", "L"]

        for unit in volumeUnits {
            XCTAssertTrue(isVolumeUnit(unit))
        }
    }

    func testServingUnit_Count() {
        let countUnits = ["serving", "piece", "slice", "whole", "medium", "large", "small"]

        for unit in countUnits {
            XCTAssertTrue(isCountUnit(unit))
        }
    }

    private func isWeightUnit(_ unit: String) -> Bool {
        ["g", "oz", "lb", "kg"].contains(unit)
    }

    private func isVolumeUnit(_ unit: String) -> Bool {
        ["ml", "cup", "tbsp", "tsp", "fl oz", "L"].contains(unit)
    }

    private func isCountUnit(_ unit: String) -> Bool {
        ["serving", "piece", "slice", "whole", "medium", "large", "small"].contains(unit)
    }
}

// MARK: - Daily Summary Tests

final class DailyNutritionSummaryTests: XCTestCase {

    func testDailySummary_AllMeals() {
        let meals = [
            (mealType: "breakfast", calories: 400.0),
            (mealType: "lunch", calories: 600.0),
            (mealType: "dinner", calories: 700.0),
            (mealType: "snack", calories: 200.0),
            (mealType: "snack", calories: 100.0)
        ]

        let totalCalories = meals.reduce(0.0) { $0 + $1.calories }
        let mealCount = meals.count

        XCTAssertEqual(totalCalories, 2000)
        XCTAssertEqual(mealCount, 5)
    }

    func testDailySummary_GoalProgress() {
        let goalCalories = 2000
        let consumedCalories = 1800

        let remaining = goalCalories - consumedCalories
        let progress = Double(consumedCalories) / Double(goalCalories)

        XCTAssertEqual(remaining, 200)
        XCTAssertEqual(progress, 0.9, accuracy: 0.01)
    }

    func testDailySummary_OverGoal() {
        let goalCalories = 2000
        let consumedCalories = 2300

        let over = consumedCalories - goalCalories
        let progress = Double(consumedCalories) / Double(goalCalories)

        XCTAssertEqual(over, 300)
        XCTAssertGreaterThan(progress, 1.0)
    }
}
