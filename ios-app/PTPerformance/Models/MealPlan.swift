//
//  MealPlan.swift
//  PTPerformance
//
//  BUILD 222: Nutrition Module - Meal planning model
//

import Foundation

/// A meal plan for scheduling nutrition
struct MealPlan: Codable, Identifiable, Hashable, Equatable {
    let id: UUID
    let patientId: String
    let name: String
    let description: String?
    let planType: MealPlanType?
    let isActive: Bool
    let startDate: Date?
    let endDate: Date?
    let createdBy: String?
    let createdAt: Date?
    let updatedAt: Date?
    var items: [MealPlanItem]?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case name
        case description
        case planType = "plan_type"
        case isActive = "is_active"
        case startDate = "start_date"
        case endDate = "end_date"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case items = "meal_plan_items"  // Supabase nested query returns table name
    }
}

/// Type of meal plan
enum MealPlanType: String, Codable, CaseIterable, Hashable {
    case daily
    case weekly

    var displayName: String {
        switch self {
        case .daily: return "Daily Plan"
        case .weekly: return "Weekly Plan"
        }
    }
}

/// Individual meal within a meal plan
struct MealPlanItem: Codable, Identifiable, Hashable, Equatable {
    let id: UUID
    let mealPlanId: UUID
    let dayOfWeek: DayOfWeek?
    let mealType: MealType
    let mealTime: String? // HH:mm format
    let foodItems: [LoggedFoodItem]
    let recipeName: String?
    let recipeInstructions: String?
    let estimatedCalories: Int?
    let estimatedProteinG: Double?
    let estimatedCarbsG: Double?
    let estimatedFatG: Double?
    let notes: String?
    let sequence: Int
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case mealPlanId = "meal_plan_id"
        case dayOfWeek = "day_of_week"
        case mealType = "meal_type"
        case mealTime = "meal_time"
        case foodItems = "food_items"
        case recipeName = "recipe_name"
        case recipeInstructions = "recipe_instructions"
        case estimatedCalories = "estimated_calories"
        case estimatedProteinG = "estimated_protein_g"
        case estimatedCarbsG = "estimated_carbs_g"
        case estimatedFatG = "estimated_fat_g"
        case notes
        case sequence
        case createdAt = "created_at"
    }
}

/// Day of the week for weekly meal plans
enum DayOfWeek: Int, Codable, CaseIterable, Hashable {
    case sunday = 0
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6

    var displayName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    /// Get current day of week
    static var today: DayOfWeek {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return DayOfWeek(rawValue: weekday - 1) ?? .sunday
    }
}

// MARK: - Convenience Extensions

extension MealPlan {
    /// Get items for a specific day
    func items(for day: DayOfWeek) -> [MealPlanItem] {
        items?.filter { $0.dayOfWeek == day }.sorted { $0.sequence < $1.sequence } ?? []
    }

    /// Get items for a specific meal type
    func items(for mealType: MealType) -> [MealPlanItem] {
        items?.filter { $0.mealType == mealType }.sorted { $0.sequence < $1.sequence } ?? []
    }

    /// Total estimated calories for the plan
    var totalCalories: Int {
        items?.compactMap { $0.estimatedCalories }.reduce(0, +) ?? 0
    }

    /// Total estimated protein for the plan
    var totalProtein: Double {
        items?.compactMap { $0.estimatedProteinG }.reduce(0, +) ?? 0
    }
}

extension MealPlanItem {
    /// Display time string
    var displayTime: String? {
        guard let time = mealTime else { return nil }
        // Convert HH:mm to 12-hour format
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let date = formatter.date(from: time) else { return time }
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    /// Total calories from all food items
    var calculatedCalories: Int {
        foodItems.reduce(0) { $0 + $1.totalCalories }
    }

    /// Total protein from all food items
    var calculatedProtein: Double {
        foodItems.reduce(0) { $0 + $1.totalProtein }
    }
}

// MARK: - Create/Update DTOs

struct CreateMealPlanDTO: Codable {
    let patientId: String
    let name: String
    let description: String?
    let planType: String?
    let startDate: Date?
    let endDate: Date?

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case name
        case description
        case planType = "plan_type"
        case startDate = "start_date"
        case endDate = "end_date"
    }
}

struct CreateMealPlanItemDTO: Codable {
    let mealPlanId: String
    let dayOfWeek: Int?
    let mealType: String
    let mealTime: String?
    let foodItems: [LoggedFoodItem]
    let recipeName: String?
    let recipeInstructions: String?
    let estimatedCalories: Int?
    let estimatedProteinG: Double?
    let estimatedCarbsG: Double?
    let estimatedFatG: Double?
    let notes: String?
    let sequence: Int

    enum CodingKeys: String, CodingKey {
        case mealPlanId = "meal_plan_id"
        case dayOfWeek = "day_of_week"
        case mealType = "meal_type"
        case mealTime = "meal_time"
        case foodItems = "food_items"
        case recipeName = "recipe_name"
        case recipeInstructions = "recipe_instructions"
        case estimatedCalories = "estimated_calories"
        case estimatedProteinG = "estimated_protein_g"
        case estimatedCarbsG = "estimated_carbs_g"
        case estimatedFatG = "estimated_fat_g"
        case notes
        case sequence
    }
}
