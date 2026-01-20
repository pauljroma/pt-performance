//
//  NutritionDashboardViewModel.swift
//  PTPerformance
//
//  BUILD 222: Nutrition Module - Dashboard ViewModel
//

import Foundation
import SwiftUI

/// ViewModel for the nutrition dashboard screen
@MainActor
class NutritionDashboardViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var error: String?
    @Published var showError = false

    // Dashboard Data
    @Published var todaySummary: DailyNutritionSummary?
    @Published var goalProgress: NutritionGoalProgress?
    @Published var weeklyTrends: [WeeklyNutritionTrend] = []
    @Published var todaysLogs: [NutritionLog] = []
    @Published var macroDistribution: MacroDistribution?
    @Published var activeGoal: NutritionGoal?

    // UI State
    @Published var selectedMealType: MealType?
    @Published var showLogMealSheet = false
    @Published var showGoalSheet = false
    @Published var showMealPlanSheet = false

    // MARK: - Private Properties

    private let nutritionService = NutritionService.shared
    private let supabase = PTSupabaseClient.shared

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
    var macroChartData: [MacroChartData] {
        guard let macro = macroDistribution else {
            return defaultMacroData
        }
        return [
            MacroChartData(
                macro: .protein,
                grams: todaySummary?.totalProteinG ?? 0,
                calories: macro.proteinCalories,
                percent: macro.proteinPercent
            ),
            MacroChartData(
                macro: .carbs,
                grams: todaySummary?.totalCarbsG ?? 0,
                calories: macro.carbsCalories,
                percent: macro.carbsPercent
            ),
            MacroChartData(
                macro: .fat,
                grams: todaySummary?.totalFatG ?? 0,
                calories: macro.fatCalories,
                percent: macro.fatPercent
            )
        ]
    }

    private var defaultMacroData: [MacroChartData] {
        [
            MacroChartData(macro: .protein, grams: proteinToday, calories: proteinToday * 4, percent: 30),
            MacroChartData(macro: .carbs, grams: carbsToday, calories: carbsToday * 4, percent: 40),
            MacroChartData(macro: .fat, grams: fatToday, calories: fatToday * 9, percent: 30)
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
        guard let patientId = patientId else {
            error = "Not logged in"
            showError = true
            return
        }

        isLoading = true

        do {
            // Load all dashboard data concurrently
            async let summaryTask = nutritionService.fetchDailySummary(patientId: patientId, date: Date())
            async let progressTask = nutritionService.fetchGoalProgress(patientId: patientId)
            async let trendsTask = nutritionService.fetchWeeklyTrends(patientId: patientId, weeks: 4)
            async let logsTask = nutritionService.fetchTodaysLogs(patientId: patientId)
            async let macroTask = nutritionService.fetchMacroDistribution(patientId: patientId, date: Date())
            async let goalTask = nutritionService.fetchActiveGoal(patientId: patientId)

            let (summary, progress, trends, logs, macro, goal) = try await (
                summaryTask,
                progressTask,
                trendsTask,
                logsTask,
                macroTask,
                goalTask
            )

            todaySummary = summary
            goalProgress = progress
            weeklyTrends = trends
            todaysLogs = logs
            macroDistribution = macro
            activeGoal = goal

            isLoading = false
        } catch {
            self.error = "Failed to load nutrition data: \(error.localizedDescription)"
            self.showError = true
            isLoading = false
        }
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
        } catch {
            self.error = "Failed to delete log: \(error.localizedDescription)"
            self.showError = true
        }
    }

    // MARK: - Goal Management

    func openGoalSettings() {
        showGoalSheet = true
    }

    func refreshAfterLogAdded() async {
        await loadDashboard()
    }
}
