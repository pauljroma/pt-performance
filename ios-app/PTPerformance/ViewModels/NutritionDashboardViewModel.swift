//
//  NutritionDashboardViewModel.swift
//  PTPerformance
//
//  Nutrition Module - Dashboard ViewModel
//

import SwiftUI

/// ViewModel for the nutrition dashboard screen
@MainActor
class NutritionDashboardViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var error: AppError?
    @Published var showError = false

    // Dashboard Data
    @Published var todaySummary: DailyNutritionSummary?
    @Published var goalProgress: NutritionGoalProgress?
    @Published var weeklyTrends: [WeeklyNutritionTrend] = []
    @Published var todaysLogs: [NutritionLog] = []
    @Published var todaysPlannedMeals: [MealPlanItem] = []  // Today's planned meals
    @Published var macroDistribution: MacroDistribution?
    @Published var activeGoal: NutritionGoal?

    // UI State
    @Published var selectedMealType: MealType?
    @Published var showLogMealSheet = false
    @Published var showGoalSheet = false
    @Published var showMealPlanSheet = false

    // MARK: - Private Properties

    private let nutritionService = NutritionService.shared
    private let mealPlanService = MealPlanService.shared  // For today's planned meals
    private let supabase = PTSupabaseClient.shared

    // Track if data has been loaded to prevent duplicate fetches
    private var hasLoadedInitialData = false

    // MARK: - Computed Properties

    var patientId: String? {
        supabase.userId
    }

    var hasLoggedToday: Bool {
        !todaysLogs.isEmpty
    }

    var mealsLoggedToday: Int {
        todaysLogs.count
    }

    var caloriesToday: Int {
        todaySummary?.totalCalories ?? 0
    }

    var proteinToday: Double {
        todaySummary?.totalProteinG ?? 0
    }

    var carbsToday: Double {
        todaySummary?.totalCarbsG ?? 0
    }

    var fatToday: Double {
        todaySummary?.totalFatG ?? 0
    }

    var calorieGoal: Int {
        activeGoal?.targetCalories ?? goalProgress?.targetCalories ?? 2000
    }

    var proteinGoal: Double {
        activeGoal?.targetProteinG ?? goalProgress?.targetProteinG ?? 150
    }

    var calorieProgress: Double {
        guard calorieGoal > 0 else { return 0 }
        return min(Double(caloriesToday) / Double(calorieGoal), 1.0)
    }

    var proteinProgress: Double {
        guard proteinGoal > 0 else { return 0 }
        return min(proteinToday / proteinGoal, 1.0)
    }

    var remainingCalories: Int {
        max(0, calorieGoal - caloriesToday)
    }

    var remainingProtein: Double {
        max(0, proteinGoal - proteinToday)
    }

    // Macro chart data
    // Calculate calories from grams since view only provides percentages
    var macroChartData: [MacroChartData] {
        guard let macro = macroDistribution else {
            return defaultMacroData
        }
        let proteinGrams = todaySummary?.totalProteinG ?? 0
        let carbsGrams = todaySummary?.totalCarbsG ?? 0
        let fatGrams = todaySummary?.totalFatG ?? 0

        return [
            MacroChartData(
                macro: .protein,
                grams: proteinGrams,
                calories: proteinGrams * MacroType.protein.caloriesPerGram,
                percent: macro.proteinPercent
            ),
            MacroChartData(
                macro: .carbs,
                grams: carbsGrams,
                calories: carbsGrams * MacroType.carbs.caloriesPerGram,
                percent: macro.carbsPercent
            ),
            MacroChartData(
                macro: .fat,
                grams: fatGrams,
                calories: fatGrams * MacroType.fat.caloriesPerGram,
                percent: macro.fatPercent
            )
        ]
    }

    private var defaultMacroData: [MacroChartData] {
        [
            MacroChartData(macro: .protein, grams: proteinToday, calories: proteinToday * MacroType.protein.caloriesPerGram, percent: 30),
            MacroChartData(macro: .carbs, grams: carbsToday, calories: carbsToday * MacroType.carbs.caloriesPerGram, percent: 40),
            MacroChartData(macro: .fat, grams: fatToday, calories: fatToday * MacroType.fat.caloriesPerGram, percent: 30)
        ]
    }

    // Weekly trend chart data
    var weeklyChartData: [NutritionChartPoint] {
        weeklyTrends.reversed().map { trend in
            NutritionChartPoint(
                date: trend.weekStart,
                value: trend.avgDailyCalories,
                label: "\(Int(trend.avgDailyCalories)) cal"
            )
        }
    }

    // MARK: - Load Data

    func loadDashboard() async {
        // Prevent duplicate fetches when switching tabs
        guard !hasLoadedInitialData else {
            #if DEBUG
            print("🍎 [NUTRITION VM] Skipping reload - data already loaded")
            #endif
            return
        }

        guard let patientId = patientId else {
            error = AppError.notAuthenticated
            showError = true
            return
        }

        isLoading = true
        hasLoadedInitialData = true  // Mark as loaded to prevent future duplicate calls

        #if DEBUG
        print("🍎 [NUTRITION VM] Loading dashboard for patient: \(patientId)")
        #endif

        // Load each component individually to prevent one failure from stopping others
        do {
            todaySummary = try await nutritionService.fetchDailySummary(patientId: patientId, date: Date())
            #if DEBUG
            print("🍎 [NUTRITION VM] ✓ Daily summary loaded")
            #endif
        } catch {
            DebugLogger.shared.warning("NutritionDashboardViewModel", "Daily summary error: \(error.localizedDescription)")
        }

        do {
            goalProgress = try await nutritionService.fetchGoalProgress(patientId: patientId)
            #if DEBUG
            print("🍎 [NUTRITION VM] ✓ Goal progress loaded")
            #endif
        } catch {
            DebugLogger.shared.warning("NutritionDashboardViewModel", "Goal progress error: \(error.localizedDescription)")
        }

        do {
            weeklyTrends = try await nutritionService.fetchWeeklyTrends(patientId: patientId, weeks: 4)
            #if DEBUG
            print("🍎 [NUTRITION VM] ✓ Weekly trends loaded: \(weeklyTrends.count) weeks")
            #endif
        } catch {
            DebugLogger.shared.warning("NutritionDashboardViewModel", "Weekly trends error: \(error.localizedDescription)")
        }

        do {
            todaysLogs = try await nutritionService.fetchTodaysLogs(patientId: patientId)
            #if DEBUG
            print("🍎 [NUTRITION VM] ✓ Today's logs loaded: \(todaysLogs.count) logs")
            #endif
        } catch {
            DebugLogger.shared.warning("NutritionDashboardViewModel", "Today's logs error: \(error.localizedDescription)")
        }

        do {
            macroDistribution = try await nutritionService.fetchMacroDistribution(patientId: patientId, date: Date())
            #if DEBUG
            print("🍎 [NUTRITION VM] ✓ Macro distribution loaded")
            #endif
        } catch {
            DebugLogger.shared.warning("NutritionDashboardViewModel", "Macro distribution error: \(error.localizedDescription)")
        }

        do {
            activeGoal = try await nutritionService.fetchActiveGoal(patientId: patientId)
            #if DEBUG
            print("🍎 [NUTRITION VM] ✓ Active goal loaded")
            #endif
        } catch {
            DebugLogger.shared.warning("NutritionDashboardViewModel", "Active goal error: \(error.localizedDescription)")
        }

        // Fetch today's planned meals from active meal plan
        do {
            todaysPlannedMeals = try await mealPlanService.fetchTodaysMeals(patientId: patientId)
            #if DEBUG
            print("🍎 [NUTRITION VM] ✓ Today's planned meals loaded: \(todaysPlannedMeals.count) meals")
            #endif
        } catch {
            DebugLogger.shared.warning("NutritionDashboardViewModel", "Today's planned meals error: \(error.localizedDescription)")
        }

        #if DEBUG
        print("🍎 [NUTRITION VM] Dashboard load complete")
        #endif

        isLoading = false
    }

    // MARK: - Quick Log Actions

    func logQuickMeal(type: MealType) {
        selectedMealType = type
        showLogMealSheet = true
    }

    func deleteLog(_ log: NutritionLog) async {
        do {
            try await nutritionService.deleteNutritionLog(id: log.id)
            todaysLogs.removeAll { $0.id == log.id }
            // Refresh summary
            if let patientId = patientId {
                todaySummary = try await nutritionService.fetchDailySummary(patientId: patientId, date: Date())
                macroDistribution = try await nutritionService.fetchMacroDistribution(patientId: patientId, date: Date())
            }
        } catch let catchError {
            self.error = AppError.from(catchError)
            self.showError = true
        }
    }

    // MARK: - Goal Management

    func openGoalSettings() {
        showGoalSheet = true
    }

    func refreshAfterLogAdded() async {
        // Force refresh after logging a meal
        hasLoadedInitialData = false
        await loadDashboard()
    }

    // Force refresh for pull-to-refresh
    func forceRefresh() async {
        hasLoadedInitialData = false
        await loadDashboard()
    }

    /// Retry loading dashboard after an error
    func retryLoadDashboard() async {
        error = nil
        showError = false
        hasLoadedInitialData = false
        await loadDashboard()
    }
}
