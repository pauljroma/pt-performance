//
//  NutritionAnalytics.swift
//  PTPerformance
//
//  BUILD 222: Nutrition Module - Analytics and trend models
//

import Foundation

/// Daily nutrition summary from vw_daily_nutrition view
struct DailyNutritionSummary: Codable, Identifiable {
    var id: String { "\(patientId)-\(logDate)" }
    let patientId: String
    let logDate: Date
    let mealCount: Int
    let totalCalories: Int
    let totalProteinG: Double
    let totalCarbsG: Double
    let totalFatG: Double
    let totalFiberG: Double

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case logDate = "log_date"
        case mealCount = "meal_count"
        case totalCalories = "total_calories"
        case totalProteinG = "total_protein_g"
        case totalCarbsG = "total_carbs_g"
        case totalFatG = "total_fat_g"
        case totalFiberG = "total_fiber_g"
    }
}

/// Weekly nutrition trend from vw_nutrition_trend view
struct WeeklyNutritionTrend: Codable, Identifiable {
    var id: String { "\(patientId)-\(weekStart)" }
    let patientId: String
    let weekStart: Date
    let daysLogged: Int
    let avgDailyCalories: Double
    let avgDailyProteinG: Double
    let avgDailyCarbsG: Double
    let avgDailyFatG: Double

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case weekStart = "week_start"
        case daysLogged = "days_logged"
        case avgDailyCalories = "avg_daily_calories"
        case avgDailyProteinG = "avg_daily_protein_g"
        case avgDailyCarbsG = "avg_daily_carbs_g"
        case avgDailyFatG = "avg_daily_fat_g"
    }

    /// Consistency score (days logged / 7)
    var consistencyPercent: Double {
        Double(daysLogged) / 7.0 * 100
    }
}

/// Macro distribution from vw_macro_distribution view
struct MacroDistribution: Codable, Identifiable {
    var id: String { "\(patientId)-\(logDate)" }
    let patientId: String
    let logDate: Date
    let proteinCalories: Double
    let carbsCalories: Double
    let fatCalories: Double
    let proteinPercent: Double
    let carbsPercent: Double
    let fatPercent: Double

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case logDate = "log_date"
        case proteinCalories = "protein_calories"
        case carbsCalories = "carbs_calories"
        case fatCalories = "fat_calories"
        case proteinPercent = "protein_percent"
        case carbsPercent = "carbs_percent"
        case fatPercent = "fat_percent"
    }

    /// Total calories from macros
    var totalCalories: Double {
        proteinCalories + carbsCalories + fatCalories
    }
}

// MARK: - Dashboard Summary

/// Combined nutrition data for dashboard display
struct NutritionDashboardData {
    let todaySummary: DailyNutritionSummary?
    let goalProgress: NutritionGoalProgress?
    let weeklyTrend: [WeeklyNutritionTrend]
    let recentLogs: [NutritionLog]
    let macroDistribution: MacroDistribution?

    /// Whether user has logged today
    var hasLoggedToday: Bool {
        todaySummary != nil && (todaySummary?.mealCount ?? 0) > 0
    }

    /// Meals logged today
    var mealsLoggedToday: Int {
        todaySummary?.mealCount ?? 0
    }

    /// Calories consumed today
    var caloriesToday: Int {
        todaySummary?.totalCalories ?? 0
    }

    /// Protein consumed today
    var proteinToday: Double {
        todaySummary?.totalProteinG ?? 0
    }

    /// Average daily calories this week
    var avgCaloriesThisWeek: Double {
        weeklyTrend.first?.avgDailyCalories ?? 0
    }

    /// Logging streak (consecutive days)
    var loggingStreak: Int {
        // This would need to be calculated from daily data
        // For now, use days logged this week
        weeklyTrend.first?.daysLogged ?? 0
    }
}

// MARK: - Chart Data Points

/// Data point for nutrition charts
struct NutritionChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let label: String

    init(date: Date, value: Double, label: String = "") {
        self.date = date
        self.value = value
        self.label = label
    }
}

/// Macro breakdown for pie chart
struct MacroChartData: Identifiable {
    let id = UUID()
    let macro: MacroType
    let grams: Double
    let calories: Double
    let percent: Double

    var color: String {
        macro.color
    }
}

enum MacroType: String, CaseIterable {
    case protein
    case carbs
    case fat

    var displayName: String {
        switch self {
        case .protein: return "Protein"
        case .carbs: return "Carbs"
        case .fat: return "Fat"
        }
    }

    var color: String {
        switch self {
        case .protein: return "red"
        case .carbs: return "blue"
        case .fat: return "yellow"
        }
    }

    var caloriesPerGram: Double {
        switch self {
        case .protein: return 4
        case .carbs: return 4
        case .fat: return 9
        }
    }
}

// MARK: - Insights

/// Nutrition insight for recommendations
struct NutritionInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let message: String
    let priority: Int // 1 = high, 2 = medium, 3 = low

    enum InsightType {
        case warning
        case success
        case tip
        case goal
    }

    var icon: String {
        switch type {
        case .warning: return "exclamationmark.triangle.fill"
        case .success: return "checkmark.circle.fill"
        case .tip: return "lightbulb.fill"
        case .goal: return "target"
        }
    }

    var iconColor: String {
        switch type {
        case .warning: return "orange"
        case .success: return "green"
        case .tip: return "blue"
        case .goal: return "purple"
        }
    }
}
