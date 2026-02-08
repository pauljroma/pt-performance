//
//  NutritionLog.swift
//  PTPerformance
//
//  Nutrition Module - Meal logging model
//

import Foundation

/// Represents a logged meal or snack with nutritional information
struct NutritionLog: Codable, Identifiable, Hashable, Equatable {
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
    let description: String?  // Added for DB compatibility
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
        case description
        case photoUrl = "photo_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID,
        patientId: String,
        loggedAt: Date,
        mealType: MealType? = nil,
        foodItems: [LoggedFoodItem] = [],
        totalCalories: Int? = nil,
        totalProteinG: Double? = nil,
        totalCarbsG: Double? = nil,
        totalFatG: Double? = nil,
        totalFiberG: Double? = nil,
        notes: String? = nil,
        description: String? = nil,
        photoUrl: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.patientId = patientId
        self.loggedAt = loggedAt
        self.mealType = mealType
        self.foodItems = foodItems
        self.totalCalories = totalCalories
        self.totalProteinG = totalProteinG
        self.totalCarbsG = totalCarbsG
        self.totalFatG = totalFatG
        self.totalFiberG = totalFiberG
        self.notes = notes
        self.description = description
        self.photoUrl = photoUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required UUID with fallback
        id = container.safeUUID(forKey: .id)

        // Required string with fallback
        patientId = container.safeString(forKey: .patientId, default: "")

        // Date with fallback
        loggedAt = container.safeDate(forKey: .loggedAt)

        // Optional enum
        mealType = container.safeOptionalEnum(MealType.self, forKey: .mealType)

        // Array with fallback to empty
        foodItems = container.safeArray(of: LoggedFoodItem.self, forKey: .foodItems)

        // Optional ints (handles PostgreSQL numeric as string)
        totalCalories = container.safeOptionalInt(forKey: .totalCalories)

        // Optional doubles (handles PostgreSQL numeric as string)
        totalProteinG = container.safeOptionalDouble(forKey: .totalProteinG)
        totalCarbsG = container.safeOptionalDouble(forKey: .totalCarbsG)
        totalFatG = container.safeOptionalDouble(forKey: .totalFatG)
        totalFiberG = container.safeOptionalDouble(forKey: .totalFiberG)

        // Optional strings
        notes = container.safeOptionalString(forKey: .notes)
        description = container.safeOptionalString(forKey: .description)
        photoUrl = container.safeOptionalString(forKey: .photoUrl)

        // Optional dates
        createdAt = container.safeOptionalDate(forKey: .createdAt)
        updatedAt = container.safeOptionalDate(forKey: .updatedAt)
    }
}

/// Types of meals that can be logged
enum MealType: String, Codable, CaseIterable, Hashable {
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
struct LoggedFoodItem: Codable, Identifiable, Hashable, Equatable {
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required UUID with fallback
        id = container.safeUUID(forKey: .id)

        // Optional UUID
        foodItemId = container.safeOptionalUUID(forKey: .foodItemId)

        // Required string with fallback
        name = container.safeString(forKey: .name, default: "Unknown Food")

        // Required double with fallback (handles PostgreSQL numeric as string)
        servings = container.safeDouble(forKey: .servings, default: 1.0)

        // Optional string
        servingSize = container.safeOptionalString(forKey: .servingSize)

        // Required int with fallback
        calories = container.safeInt(forKey: .calories, default: 0)

        // Required doubles with fallback (handles PostgreSQL numeric as string)
        proteinG = container.safeDouble(forKey: .proteinG, default: 0.0)
        carbsG = container.safeDouble(forKey: .carbsG, default: 0.0)
        fatG = container.safeDouble(forKey: .fatG, default: 0.0)

        // Optional double
        fiberG = container.safeOptionalDouble(forKey: .fiberG)
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
