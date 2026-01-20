//
//  MealPlanService.swift
//  PTPerformance
//
//  BUILD 222: Nutrition Module - Meal planning service
//

import Foundation
import Supabase

// MARK: - Simple Supabase Input Models

/// Simple update input for sequence changes
struct UpdateSequenceInput: Codable {
    let sequence: Int
}

/// Simple update input for active status
struct UpdateActiveInput: Codable {
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case isActive = "is_active"
    }
}

/// Simple update for meal plan fields
struct UpdateMealPlanInput: Codable {
    let name: String?
    let description: String?
    let isActive: Bool?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case name, description
        case isActive = "is_active"
        case updatedAt = "updated_at"
    }
}

/// Service for managing meal plans and scheduled meals
@MainActor
class MealPlanService {
    static let shared = MealPlanService()
    private let supabase = PTSupabaseClient.shared

    private init() {}

    // MARK: - Meal Plans

    /// Fetch all meal plans for a patient
    func fetchMealPlans(patientId: String, includeInactive: Bool = false) async throws -> [MealPlan] {
        #if DEBUG
        print("🍎 [MEAL PLAN] Fetching meal plans for patient: \(patientId), includeInactive: \(includeInactive)")
        #endif

        do {
            // Build query with filters applied before transforms
            let baseQuery = supabase.client
                .from("meal_plans")
                .select("*, meal_plan_items(*)")
                .eq("patient_id", value: patientId)

            let response: PostgrestResponse<Data>
            if includeInactive {
                response = try await baseQuery
                    .order("created_at", ascending: false)
                    .execute()
            } else {
                response = try await baseQuery
                    .eq("is_active", value: true)
                    .order("created_at", ascending: false)
                    .execute()
            }

            #if DEBUG
            if let json = String(data: response.data, encoding: .utf8) {
                print("🍎 [MEAL PLAN] Response: \(json.prefix(500))")
            }
            #endif

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let plans = try decoder.decode([MealPlan].self, from: response.data)

            #if DEBUG
            print("🍎 [MEAL PLAN] ✓ Fetched \(plans.count) meal plans")
            #endif

            return plans
        } catch {
            #if DEBUG
            print("🍎 [MEAL PLAN] ✗ Error fetching meal plans: \(error)")
            #endif
            throw error
        }
    }

    /// Fetch a single meal plan with items
    func fetchMealPlan(id: UUID) async throws -> MealPlan? {
        let response = try await supabase.client
            .from("meal_plans")
            .select("*, meal_plan_items(*)")
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let plans = try decoder.decode([MealPlan].self, from: response.data)
        return plans.first
    }

    /// Fetch active meal plan for a patient
    func fetchActiveMealPlan(patientId: String) async throws -> MealPlan? {
        let response = try await supabase.client
            .from("meal_plans")
            .select("*, meal_plan_items(*)")
            .eq("patient_id", value: patientId)
            .eq("is_active", value: true)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let plans = try decoder.decode([MealPlan].self, from: response.data)
        return plans.first
    }

    /// Create a new meal plan
    func createMealPlan(_ plan: CreateMealPlanDTO) async throws -> MealPlan {
        // Use the DTO directly since it's already Codable
        let response = try await supabase.client
            .from("meal_plans")
            .insert(plan)
            .select()
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(MealPlan.self, from: response.data)
    }

    /// Update a meal plan
    func updateMealPlan(id: UUID, name: String? = nil, description: String? = nil, isActive: Bool? = nil) async throws {
        let updates = UpdateMealPlanInput(
            name: name,
            description: description,
            isActive: isActive,
            updatedAt: Date()
        )

        _ = try await supabase.client
            .from("meal_plans")
            .update(updates)
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Delete a meal plan (and all its items via cascade)
    func deleteMealPlan(id: UUID) async throws {
        _ = try await supabase.client
            .from("meal_plans")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Activate a meal plan (and deactivate others)
    func activateMealPlan(id: UUID, patientId: String) async throws {
        let deactivate = UpdateActiveInput(isActive: false)
        let activate = UpdateActiveInput(isActive: true)

        // Deactivate all other plans
        _ = try await supabase.client
            .from("meal_plans")
            .update(deactivate)
            .eq("patient_id", value: patientId)
            .neq("id", value: id.uuidString)
            .execute()

        // Activate this plan
        _ = try await supabase.client
            .from("meal_plans")
            .update(activate)
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Meal Plan Items

    /// Add a meal to a plan
    func addMealToPlan(_ item: CreateMealPlanItemDTO) async throws -> MealPlanItem {
        // Use the DTO directly since it's already Codable
        let response = try await supabase.client
            .from("meal_plan_items")
            .insert(item)
            .select()
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(MealPlanItem.self, from: response.data)
    }

    /// Update a meal plan item (simplified - use sequence update only)
    func updateMealPlanItem(id: UUID, sequence: Int) async throws {
        let sequenceUpdate = UpdateSequenceInput(sequence: sequence)
        _ = try await supabase.client
            .from("meal_plan_items")
            .update(sequenceUpdate)
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Delete a meal plan item
    func deleteMealPlanItem(id: UUID) async throws {
        _ = try await supabase.client
            .from("meal_plan_items")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Reorder meal plan items
    func reorderMealPlanItems(planId: UUID, itemIds: [UUID]) async throws {
        for (index, itemId) in itemIds.enumerated() {
            let sequenceUpdate = UpdateSequenceInput(sequence: index)
            _ = try await supabase.client
                .from("meal_plan_items")
                .update(sequenceUpdate)
                .eq("id", value: itemId.uuidString)
                .eq("meal_plan_id", value: planId.uuidString)
                .execute()
        }
    }

    // MARK: - Today's Meals

    /// Get today's scheduled meals from active plan
    func fetchTodaysMeals(patientId: String) async throws -> [MealPlanItem] {
        guard let activePlan = try await fetchActiveMealPlan(patientId: patientId),
              let items = activePlan.items else {
            return []
        }

        let today = DayOfWeek.today

        // For daily plans, return all items
        // For weekly plans, return items for today's day of week
        if activePlan.planType == .daily {
            return items.sorted { $0.sequence < $1.sequence }
        } else {
            return items
                .filter { $0.dayOfWeek == today }
                .sorted { $0.sequence < $1.sequence }
        }
    }

    /// Get meals for a specific day
    func fetchMealsForDay(planId: UUID, day: DayOfWeek) async throws -> [MealPlanItem] {
        let response = try await supabase.client
            .from("meal_plan_items")
            .select()
            .eq("meal_plan_id", value: planId.uuidString)
            .eq("day_of_week", value: day.rawValue)
            .order("sequence", ascending: true)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([MealPlanItem].self, from: response.data)
    }

    // MARK: - Duplication

    /// Duplicate a meal plan
    func duplicateMealPlan(id: UUID, newName: String) async throws -> MealPlan {
        guard let original = try await fetchMealPlan(id: id) else {
            throw MealPlanError.notFound
        }

        // Create new plan
        let newPlanDTO = CreateMealPlanDTO(
            patientId: original.patientId,
            name: newName,
            description: original.description,
            planType: original.planType?.rawValue,
            startDate: nil,
            endDate: nil
        )

        let newPlan = try await createMealPlan(newPlanDTO)

        // Duplicate all items
        if let items = original.items {
            for item in items {
                let newItemDTO = CreateMealPlanItemDTO(
                    mealPlanId: newPlan.id.uuidString,
                    dayOfWeek: item.dayOfWeek?.rawValue,
                    mealType: item.mealType.rawValue,
                    mealTime: item.mealTime,
                    foodItems: item.foodItems,
                    recipeName: item.recipeName,
                    recipeInstructions: item.recipeInstructions,
                    estimatedCalories: item.estimatedCalories,
                    estimatedProteinG: item.estimatedProteinG,
                    estimatedCarbsG: item.estimatedCarbsG,
                    estimatedFatG: item.estimatedFatG,
                    notes: item.notes,
                    sequence: item.sequence
                )

                _ = try await addMealToPlan(newItemDTO)
            }
        }

        // Fetch and return the complete new plan
        return try await fetchMealPlan(id: newPlan.id) ?? newPlan
    }
}

// MARK: - Errors

enum MealPlanError: LocalizedError {
    case notFound
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Meal plan not found"
        case .unauthorized:
            return "You don't have permission to modify this meal plan"
        }
    }
}
