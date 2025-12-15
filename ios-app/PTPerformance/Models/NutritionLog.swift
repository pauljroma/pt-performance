//
//  NutritionLog.swift
//  PTPerformance
//
//  Created by Build 46 Swarm Agent 5
//  Models for nutrition tracking
//

import Foundation

// MARK: - Nutrition Log

/// Represents a logged meal or snack
struct NutritionLog: Codable, Identifiable, Hashable {

    let id: String
    let patientId: String
    let logDate: Date
    let mealType: MealType
    let description: String
    let calories: Int?
    let proteinGrams: Double?
    let carbsGrams: Double?
    let fatsGrams: Double?
    let photoUrl: String?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case logDate = "log_date"
        case mealType = "meal_type"
        case description
        case calories
        case proteinGrams = "protein_grams"
        case carbsGrams = "carbs_grams"
        case fatsGrams = "fats_grams"
        case photoUrl = "photo_url"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    enum MealType: String, Codable, CaseIterable {
        case breakfast
        case lunch
        case dinner
        case snack
        case other

        var displayName: String {
            rawValue.capitalized
        }

        var icon: String {
            switch self {
            case .breakfast: return "sunrise.fill"
            case .lunch: return "sun.max.fill"
            case .dinner: return "moon.stars.fill"
            case .snack: return "leaf.fill"
            case .other: return "fork.knife"
            }
        }

        var color: String {
            switch self {
            case .breakfast: return "orange"
            case .lunch: return "yellow"
            case .dinner: return "purple"
            case .snack: return "green"
            case .other: return "gray"
            }
        }
    }

    // Computed properties
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: logDate)
    }

    var formattedCalories: String? {
        guard let cals = calories else { return nil }
        return "\(cals) cal"
    }

    var macrosSummary: String {
        var parts: [String] = []

        if let protein = proteinGrams {
            parts.append(String(format: "%.0fg P", protein))
        }
        if let carbs = carbsGrams {
            parts.append(String(format: "%.0fg C", carbs))
        }
        if let fats = fatsGrams {
            parts.append(String(format: "%.0fg F", fats))
        }

        return parts.isEmpty ? "No macros logged" : parts.joined(separator: " • ")
    }
}

// MARK: - Nutrition Goal

/// Represents daily nutrition goals set by therapist
struct NutritionGoal: Codable, Identifiable, Hashable {

    let id: String
    let patientId: String
    let dailyCalories: Int?
    let dailyProteinGrams: Double?
    let dailyCarbsGrams: Double?
    let dailyFatsGrams: Double?
    let setBy: String?
    let notes: String?
    let active: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case dailyCalories = "daily_calories"
        case dailyProteinGrams = "daily_protein_grams"
        case dailyCarbsGrams = "daily_carbs_grams"
        case dailyFatsGrams = "daily_fats_grams"
        case setBy = "set_by"
        case notes
        case active
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Computed properties
    var formattedCalories: String? {
        guard let cals = dailyCalories else { return nil }
        return "\(cals) cal"
    }

    var macrosSummary: String {
        var parts: [String] = []

        if let protein = dailyProteinGrams {
            parts.append(String(format: "%.0fg P", protein))
        }
        if let carbs = dailyCarbsGrams {
            parts.append(String(format: "%.0fg C", carbs))
        }
        if let fats = dailyFatsGrams {
            parts.append(String(format: "%.0fg F", fats))
        }

        return parts.isEmpty ? "No goals set" : parts.joined(separator: " • ")
    }
}

// MARK: - Daily Nutrition Summary

/// Summary of nutrition for a single day
struct DailyNutritionSummary: Codable, Identifiable {

    let patientId: String
    let logDate: Date
    let mealCount: Int
    let totalCalories: Double?
    let totalProtein: Double?
    let totalCarbs: Double?
    let totalFats: Double?
    let goalCalories: Int?
    let goalProtein: Double?
    let goalCarbs: Double?
    let goalFats: Double?
    let caloriesPercentage: Double?
    let proteinPercentage: Double?
    let carbsPercentage: Double?
    let fatsPercentage: Double?

    var id: String { "\(patientId)_\(logDate)" }

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case logDate = "log_date"
        case mealCount = "meal_count"
        case totalCalories = "total_calories"
        case totalProtein = "total_protein"
        case totalCarbs = "total_carbs"
        case totalFats = "total_fats"
        case goalCalories = "goal_calories"
        case goalProtein = "goal_protein"
        case goalCarbs = "goal_carbs"
        case goalFats = "goal_fats"
        case caloriesPercentage = "calories_percentage"
        case proteinPercentage = "protein_percentage"
        case carbsPercentage = "carbs_percentage"
        case fatsPercentage = "fats_percentage"
    }

    // Computed properties
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: logDate)
    }

    var formattedCalories: String {
        let total = totalCalories ?? 0
        if let goal = goalCalories {
            return String(format: "%.0f / %d cal", total, goal)
        } else {
            return String(format: "%.0f cal", total)
        }
    }

    var caloriesProgress: Double {
        guard let total = totalCalories, let goal = goalCalories, goal > 0 else {
            return 0
        }
        return min(total / Double(goal), 1.5) // Cap at 150%
    }

    var proteinProgress: Double {
        guard let total = totalProtein, let goal = goalProtein, goal > 0 else {
            return 0
        }
        return min(total / goal, 1.5)
    }

    var carbsProgress: Double {
        guard let total = totalCarbs, let goal = goalCarbs, goal > 0 else {
            return 0
        }
        return min(total / goal, 1.5)
    }

    var fatsProgress: Double {
        guard let total = totalFats, let goal = goalFats, goal > 0 else {
            return 0
        }
        return min(total / goal, 1.5)
    }

    var isOnTrack: Bool {
        guard let calPercentage = caloriesPercentage else { return false }
        return calPercentage >= 80 && calPercentage <= 120
    }
}

// MARK: - Sample Data

extension NutritionLog {
    static var sample: NutritionLog {
        NutritionLog(
            id: UUID().uuidString,
            patientId: UUID().uuidString,
            logDate: Date(),
            mealType: .lunch,
            description: "Grilled chicken salad with quinoa",
            calories: 450,
            proteinGrams: 35,
            carbsGrams: 40,
            fatsGrams: 15,
            photoUrl: nil,
            notes: "Felt full and energized",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

extension NutritionGoal {
    static var sample: NutritionGoal {
        NutritionGoal(
            id: UUID().uuidString,
            patientId: UUID().uuidString,
            dailyCalories: 2000,
            dailyProteinGrams: 150,
            dailyCarbsGrams: 200,
            dailyFatsGrams: 65,
            setBy: UUID().uuidString,
            notes: "Focus on protein for recovery",
            active: true,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

extension DailyNutritionSummary {
    static var sample: DailyNutritionSummary {
        DailyNutritionSummary(
            patientId: UUID().uuidString,
            logDate: Date(),
            mealCount: 4,
            totalCalories: 1850,
            totalProtein: 145,
            totalCarbs: 185,
            totalFats: 62,
            goalCalories: 2000,
            goalProtein: 150,
            goalCarbs: 200,
            goalFats: 65,
            caloriesPercentage: 92.5,
            proteinPercentage: 96.7,
            carbsPercentage: 92.5,
            fatsPercentage: 95.4
        )
    }
}
