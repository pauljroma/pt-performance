//
//  MealLogViewModel.swift
//  PTPerformance
//
//  BUILD 222: Nutrition Module - Meal logging ViewModel
//

import Foundation
import SwiftUI

/// ViewModel for logging meals and managing food items
@MainActor
class MealLogViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var isSaving = false
    @Published var error: String?
    @Published var showError = false

    // Meal being logged
    @Published var mealType: MealType = .lunch
    @Published var loggedAt: Date = Date()
    @Published var foodItems: [LoggedFoodItem] = []
    @Published var notes: String = ""

    // Food search
    @Published var searchText = ""
    @Published var searchResults: [FoodSearchResult] = []
    @Published var isSearching = false
    @Published var recentFoods: [FoodSearchResult] = []
    @Published var popularFoods: [FoodSearchResult] = []

    // Selected food for editing
    @Published var selectedFood: LoggedFoodItem?
    @Published var showFoodDetailSheet = false
    @Published var showAddCustomFoodSheet = false

    // MARK: - Private Properties

    private let nutritionService = NutritionService.shared
    private let foodService = FoodDatabaseService.shared
    private let supabase = PTSupabaseClient.shared

    private var searchTask: Task<Void, Never>?

    // MARK: - Computed Properties

    var patientId: String? {
        supabase.userId
    }

    var totalCalories: Int {
        foodItems.reduce(0) { $0 + $1.totalCalories }
    }

    var totalProtein: Double {
        foodItems.reduce(0) { $0 + $1.totalProtein }
    }

    var totalCarbs: Double {
        foodItems.reduce(0) { $0 + $1.totalCarbs }
    }

    var totalFat: Double {
        foodItems.reduce(0) { $0 + $1.totalFat }
    }

    var canSave: Bool {
        !foodItems.isEmpty
    }

    var macroSummary: String {
        "P: \(Int(totalProtein))g | C: \(Int(totalCarbs))g | F: \(Int(totalFat))g"
    }

    // MARK: - Initialization

    init(mealType: MealType = .lunch) {
        self.mealType = mealType
    }

    // MARK: - Load Initial Data

    func loadInitialData() async {
        guard let patientId = patientId else { return }

        isLoading = true

        do {
            async let recentTask = foodService.fetchRecentlyLoggedFoods(patientId: patientId)
            async let popularTask = foodService.fetchPopularFoods()

            let (recent, popular) = try await (recentTask, popularTask)

            recentFoods = recent
            popularFoods = popular

            isLoading = false
        } catch {
            self.error = "Unable to load food options. Pull down to refresh."
            isLoading = false
        }
    }

    // MARK: - Food Search

    func searchFoods() {
        searchTask?.cancel()

        guard !searchText.isEmpty else {
            searchResults = []
            return
        }

        searchTask = Task {
            isSearching = true

            do {
                try await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce

                guard !Task.isCancelled else { return }

                let results = try await foodService.searchFoods(query: searchText)

                guard !Task.isCancelled else { return }

                searchResults = results
                isSearching = false
            } catch {
                if !Task.isCancelled {
                    isSearching = false
                }
            }
        }
    }

    func searchByCategory(_ category: FoodCategory) async {
        isSearching = true

        do {
            searchResults = try await foodService.searchByCategory(category)
            isSearching = false
        } catch {
            self.error = "Unable to search foods. Please try again."
            isSearching = false
        }
    }

    // MARK: - Add/Remove Food Items

    func addFood(_ result: FoodSearchResult, servings: Double = 1.0) {
        let item = LoggedFoodItem(
            foodItemId: result.id,
            name: result.name,
            servings: servings,
            servingSize: result.servingSize,
            calories: result.calories,
            proteinG: result.proteinG,
            carbsG: result.carbsG,
            fatG: result.fatG
        )
        foodItems.append(item)
    }

    func addFood(_ item: FoodItem, servings: Double = 1.0) {
        let loggedItem = item.toLoggedItem(servings: servings)
        foodItems.append(loggedItem)
    }

    func removeFood(at index: Int) {
        guard index < foodItems.count else { return }
        foodItems.remove(at: index)
    }

    func removeFood(_ item: LoggedFoodItem) {
        foodItems.removeAll { $0.id == item.id }
    }

    func updateServings(for item: LoggedFoodItem, servings: Double) {
        if let index = foodItems.firstIndex(where: { $0.id == item.id }) {
            foodItems[index].servings = servings
        }
    }

    func editFood(_ item: LoggedFoodItem) {
        selectedFood = item
        showFoodDetailSheet = true
    }

    // MARK: - Custom Food

    func addCustomFood(_ food: CreateFoodItemDTO) async -> Bool {
        do {
            let newFood = try await foodService.createCustomFood(food)
            addFood(newFood)
            return true
        } catch {
            self.error = "Unable to add custom food. Please try again."
            self.showError = true
            return false
        }
    }

    // MARK: - Save Meal Log

    func saveMealLog() async -> Bool {
        guard let patientId = patientId, canSave else {
            error = "Please add at least one food item before saving."
            showError = true
            return false
        }

        isSaving = true

        do {
            let dto = CreateNutritionLogDTO(
                patientId: patientId,
                loggedAt: loggedAt,
                mealType: mealType.rawValue,
                foodItems: foodItems,
                totalCalories: totalCalories,
                totalProteinG: totalProtein,
                totalCarbsG: totalCarbs,
                totalFatG: totalFat,
                totalFiberG: foodItems.compactMap { $0.fiberG }.reduce(0, +),
                notes: notes.isEmpty ? nil : notes,
                photoUrl: nil
            )

            _ = try await nutritionService.createNutritionLog(dto)

            isSaving = false
            return true
        } catch {
            self.error = "Unable to save your meal. Please try again."
            self.showError = true
            isSaving = false
            return false
        }
    }

    // MARK: - Quick Add from Recent

    func addFromRecent(_ food: FoodSearchResult) {
        addFood(food)
    }

    // MARK: - Reset

    func reset() {
        foodItems = []
        notes = ""
        searchText = ""
        searchResults = []
    }
}
