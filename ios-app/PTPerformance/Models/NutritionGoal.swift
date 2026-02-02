//
//  NutritionGoal.swift
//  PTPerformance
//
//  BUILD 222: Nutrition Module - Goals and targets model
//

import Foundation

/// Patient's nutritional goals and targets
struct NutritionGoal: Codable, Identifiable, Hashable, Equatable {
    let id: UUID
    let patientId: String
    let goalType: GoalType
    let targetCalories: Int?
    let targetProteinG: Double?
    let targetCarbsG: Double?
    let targetFatG: Double?
    let targetFiberG: Double?
    let targetWaterMl: Int?
    let proteinPerKg: Double?
    let active: Bool
    let startDate: Date
    let endDate: Date?
    let notes: String?
    let createdBy: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case goalType = "goal_type"
        case targetCalories = "target_calories"
        case targetProteinG = "target_protein_g"
        case targetCarbsG = "target_carbs_g"
        case targetFatG = "target_fat_g"
        case targetFiberG = "target_fiber_g"
        case targetWaterMl = "target_water_ml"
        case proteinPerKg = "protein_per_kg"
        case active
        case startDate = "start_date"
        case endDate = "end_date"
        case notes
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Type of nutrition goal
enum GoalType: String, Codable, CaseIterable, Hashable {
    case daily
    case weekly

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        }
    }
}

// MARK: - Goal Progress

/// Progress toward nutrition goals from vw_nutrition_goal_progress view
/// BUILD 280: Updated to match vw_nutrition_goal_progress view columns
struct NutritionGoalProgress: Codable, Identifiable, Hashable, Equatable {
    var id: String { goalId }
    let patientId: String
    let goalId: String
    let targetCalories: Int?
    let targetProteinG: Double?
    let consumedCalories: Int
    let consumedProteinG: Double
    let caloriesPercent: Double
    let proteinPercent: Double

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case goalId = "goal_id"
        case targetCalories = "target_calories"
        case targetProteinG = "target_protein_g"
        case consumedCalories = "consumed_calories"
        case consumedProteinG = "consumed_protein_g"
        case caloriesPercent = "calories_percent"
        case proteinPercent = "protein_percent"
    }

    /// Remaining calories to reach goal
    var remainingCalories: Int {
        guard let target = targetCalories else { return 0 }
        return max(0, target - consumedCalories)
    }

    /// Remaining protein to reach goal
    var remainingProtein: Double {
        guard let target = targetProteinG else { return 0 }
        return max(0, target - consumedProteinG)
    }

    /// Whether calorie goal is met
    var calorieGoalMet: Bool {
        guard let target = targetCalories else { return false }
        return consumedCalories >= target
    }

    /// Whether protein goal is met
    var proteinGoalMet: Bool {
        guard let target = targetProteinG else { return false }
        return consumedProteinG >= target
    }
}

// MARK: - Create/Update DTOs

struct CreateNutritionGoalDTO: Codable {
    let patientId: String
    let goalType: String
    let targetCalories: Int?
    let targetProteinG: Double?
    let targetCarbsG: Double?
    let targetFatG: Double?
    let targetFiberG: Double?
    let targetWaterMl: Int?
    let proteinPerKg: Double?
    let startDate: Date
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case goalType = "goal_type"
        case targetCalories = "target_calories"
        case targetProteinG = "target_protein_g"
        case targetCarbsG = "target_carbs_g"
        case targetFatG = "target_fat_g"
        case targetFiberG = "target_fiber_g"
        case targetWaterMl = "target_water_ml"
        case proteinPerKg = "protein_per_kg"
        case startDate = "start_date"
        case notes
    }
}

struct UpdateNutritionGoalDTO: Codable {
    let targetCalories: Int?
    let targetProteinG: Double?
    let targetCarbsG: Double?
    let targetFatG: Double?
    let targetFiberG: Double?
    let targetWaterMl: Int?
    let active: Bool?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case targetCalories = "target_calories"
        case targetProteinG = "target_protein_g"
        case targetCarbsG = "target_carbs_g"
        case targetFatG = "target_fat_g"
        case targetFiberG = "target_fiber_g"
        case targetWaterMl = "target_water_ml"
        case active
        case notes
    }
}
