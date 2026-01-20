//
//  NutritionLog.swift
//  PTPerformance
//
//  BUILD 222: Nutrition Module - Meal logging model
//

import Foundation

/// Represents a logged meal or snack with nutritional information
struct NutritionLog: Codable, Identifiable {
    let id: UUID
    let patientId: String
    let loggedAt: Date
    let mealType: MealType?
    let foodItems: [LoggedFoodItem]
    let totalCalories: Int?
    let totalProteinG: Double?
    let totalCarbsG: Double?
    let totalFatG: Double?
    let totalFiberG: Double?
    let notes: String?
    let photoUrl: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case loggedAt = "logged_at"
        case mealType = "meal_type"
        case foodItems = "food_items"
        case totalCalories = "total_calories"
        case totalProteinG = "total_protein_g"
        case totalCarbsG = "total_carbs_g"
        case totalFatG = "total_fat_g"
        case totalFiberG = "total_fiber_g"
        case notes
        case photoUrl = "photo_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Types of meals that can be logged
enum MealType: String, Codable, CaseIterable {
    case breakfast
    case lunch
    case dinner
    case snack
    case preWorkout = "pre_workout"
    case postWorkout = "post_workout"

    var displayName: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        case .preWorkout: return "Pre-Workout"
        case .postWorkout: return "Post-Workout"
        }
    }

    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "carrot.fill"
        case .preWorkout: return "figure.run"
        case .postWorkout: return "figure.cooldown"
        }
    }
}

/// Individual food item within a logged meal
struct LoggedFoodItem: Codable, Identifiable {
    var id: UUID
    let foodItemId: UUID?
    var name: String
    var servings: Double
    var servingSize: String?
    var calories: Int
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    var fiberG: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case foodItemId = "food_item_id"
        case name
        case servings
        case servingSize = "serving_size"
        case calories
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
        case fiberG = "fiber_g"
    }

    init(id: UUID = UUID(), foodItemId: UUID? = nil, name: String, servings: Double = 1.0, servingSize: String? = nil, calories: Int, proteinG: Double, carbsG: Double, fatG: Double, fiberG: Double? = nil) {
        self.id = id
        self.foodItemId = foodItemId
        self.name = name
        self.servings = servings
        self.servingSize = servingSize
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.fiberG = fiberG
    }

    /// Calculated total calories based on servings
    var totalCalories: Int {
        Int(Double(calories) * servings)
    }

    /// Calculated total protein based on servings
    var totalProtein: Double {
        proteinG * servings
    }

    /// Calculated total carbs based on servings
    var totalCarbs: Double {
        carbsG * servings
    }

    /// Calculated total fat based on servings
    var totalFat: Double {
        fatG * servings
    }
}

// MARK: - Create/Update DTOs

struct CreateNutritionLogDTO: Codable {
    let patientId: String
    let loggedAt: Date
    let mealType: String?
    let foodItems: [LoggedFoodItem]
    let totalCalories: Int
    let totalProteinG: Double
    let totalCarbsG: Double
    let totalFatG: Double
    let totalFiberG: Double?
    let notes: String?
    let photoUrl: String?

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case loggedAt = "logged_at"
        case mealType = "meal_type"
        case foodItems = "food_items"
        case totalCalories = "total_calories"
        case totalProteinG = "total_protein_g"
        case totalCarbsG = "total_carbs_g"
        case totalFatG = "total_fat_g"
        case totalFiberG = "total_fiber_g"
        case notes
        case photoUrl = "photo_url"
    }
}
