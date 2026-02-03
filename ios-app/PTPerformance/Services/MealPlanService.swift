//
//  MealPlanService.swift
//  PTPerformance
//
//  Nutrition Module - Meal planning service
//  Fixed flexible date decoding for DATE vs TIMESTAMPTZ columns
//  Standardized to use PTSupabaseClient.flexibleDecoder for consistency
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

    private let logger = DebugLogger.shared

    /// Fetch all meal plans for a patient
    func fetchMealPlans(patientId: String, includeInactive: Bool = false) async throws -> [MealPlan] {
        logger.info("MEAL PLAN", "Fetching meal plans for patient: \(patientId), includeInactive: \(includeInactive)")

        // Remove explicit PostgrestResponse<Data> type to avoid SDK decoding issues
        // Use same pattern as fetchActiveMealPlan which works correctly
        do {
            let query = supabase.client
                .from("meal_plans")
                .select("*, meal_plan_items(*)")
                .eq("patient_id", value: patientId)

            let response = if includeInactive {
                try await query
                    .order("created_at", ascending: false)
                    .execute()
            } else {
                try await query
                    .eq("is_active", value: true)
                    .order("created_at", ascending: false)
                    .execute()
            }

            logger.info("MEAL PLAN", "Query executed successfully, data size: \(response.data.count) bytes")

            if let json = String(data: response.data, encoding: .utf8) {
                logger.info("MEAL PLAN", "Raw JSON: \(json.prefix(1000))")
            }

            // Uses shared flexible decoder that handles ISO8601 (with/without fractional seconds),
            // DATE (yyyy-MM-dd), and TIME (HH:mm:ss) formats from Supabase
            let plans = try PTSupabaseClient.flexibleDecoder.decode([MealPlan].self, from: response.data)
            logger.success("MEAL PLAN", "Fetched \(plans.count) meal plans")
            return plans
        } catch let decodingError as DecodingError {
            let errorMsg: String
            switch decodingError {
            case .keyNotFound(let key, let context):
                errorMsg = "Key '\(key.stringValue)' not found at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .typeMismatch(let type, let context):
                errorMsg = "Type mismatch for \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .valueNotFound(let type, let context):
                errorMsg = "Value of type \(type) not found at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .dataCorrupted(let context):
                errorMsg = "Data corrupted at \(context.codingPath.map { $0.stringValue }.joined(separator: ".")): \(context.debugDescription)"
            @unknown default:
                errorMsg = "Unknown: \(decodingError)"
            }
            logger.error("MEAL PLAN", "DECODING ERROR: \(errorMsg)")
            throw decodingError
        } catch {
            logger.error("MEAL PLAN", "Query/decode error: \(error)")
            throw error
        }
    }

    /// Fetch a single meal plan with items
    func fetchMealPlan(id: UUID) async throws -> MealPlan? {
        logger.info("MEAL PLAN", "Fetching meal plan by ID: \(id)")

        let response = try await supabase.client
            .from("meal_plans")
            .select("*, meal_plan_items(*)")
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()

        if let json = String(data: response.data, encoding: .utf8) {
            logger.info("MEAL PLAN", "Fetch plan response: \(json)")
        }

        let decoder = PTSupabaseClient.flexibleDecoder
        let plans = try decoder.decode([MealPlan].self, from: response.data)
        logger.success("MEAL PLAN", "Decoded plan with \(plans.first?.items?.count ?? 0) items")
        return plans.first
    }

    /// Fetch active meal plan for a patient
    func fetchActiveMealPlan(patientId: String) async throws -> MealPlan? {
        logger.info("MEAL PLAN", "Fetching active meal plan for patient: \(patientId)")

        let response = try await supabase.client
            .from("meal_plans")
            .select("*, meal_plan_items(*)")
            .eq("patient_id", value: patientId)
            .eq("is_active", value: true)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()

        if let json = String(data: response.data, encoding: .utf8) {
            logger.info("MEAL PLAN", "Active plan JSON: \(json.prefix(500))")
        }

        let decoder = PTSupabaseClient.flexibleDecoder
        do {
            let plans = try decoder.decode([MealPlan].self, from: response.data)
            logger.success("MEAL PLAN", "Active plan: \(plans.first?.name ?? "none")")
            return plans.first
        } catch let decodingError as DecodingError {
            let errorMsg: String
            switch decodingError {
            case .keyNotFound(let key, let context):
                errorMsg = "Key '\(key.stringValue)' not found at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .typeMismatch(let type, let context):
                errorMsg = "Type mismatch for \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .valueNotFound(let type, let context):
                errorMsg = "Value of type \(type) not found at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .dataCorrupted(let context):
                errorMsg = "Data corrupted at \(context.codingPath.map { $0.stringValue }.joined(separator: ".")): \(context.debugDescription)"
            @unknown default:
                errorMsg = "Unknown: \(decodingError)"
            }
            logger.error("MEAL PLAN", "ACTIVE PLAN DECODING ERROR: \(errorMsg)")
            throw decodingError
        }
    }

    /// Create a new meal plan
    func createMealPlan(_ plan: CreateMealPlanDTO) async throws -> MealPlan {
        logger.info("MEAL PLAN", "Creating meal plan: \(plan.name) for patient: \(plan.patientId)")
        logger.info("MEAL PLAN", "Plan type: \(plan.planType ?? "nil"), startDate: \(plan.startDate?.description ?? "nil")")

        do {
            let response = try await supabase.client
                .from("meal_plans")
                .insert(plan)
                .select()
                .single()
                .execute()

            logger.info("MEAL PLAN", "Insert response size: \(response.data.count) bytes")

            if let json = String(data: response.data, encoding: .utf8) {
                logger.info("MEAL PLAN", "Insert response: \(json.prefix(500))")
            }

            let decoder = PTSupabaseClient.flexibleDecoder
            let newPlan = try decoder.decode(MealPlan.self, from: response.data)
            logger.success("MEAL PLAN", "Created meal plan: \(newPlan.id)")
            return newPlan
        } catch {
            logger.error("MEAL PLAN", "CREATE FAILED: \(error)")
            logger.error("MEAL PLAN", "Error details: \(String(describing: error))")
            throw error
        }
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
        logger.info("MEAL PLAN", "Adding meal to plan: \(item.mealPlanId), type: \(item.mealType)")

        // Use the DTO directly since it's already Codable
        let response = try await supabase.client
            .from("meal_plan_items")
            .insert(item)
            .select()
            .single()
            .execute()

        if let json = String(data: response.data, encoding: .utf8) {
            logger.info("MEAL PLAN", "Insert meal response: \(json)")
        }

        let decoder = PTSupabaseClient.flexibleDecoder
        let result = try decoder.decode(MealPlanItem.self, from: response.data)
        logger.success("MEAL PLAN", "Added meal item: \(result.id)")
        return result
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

        let decoder = PTSupabaseClient.flexibleDecoder
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

/// Meal plan errors with user-friendly messages
enum MealPlanError: LocalizedError {
    case notFound
    case unauthorized
    case saveFailed(Error)
    case deleteFailed(Error)
    case loadFailed(Error)

    // MARK: - User-Friendly Error Titles

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Meal Plan Not Found"
        case .unauthorized:
            return "Access Denied"
        case .saveFailed:
            return "Couldn't Save Meal Plan"
        case .deleteFailed:
            return "Couldn't Delete Meal Plan"
        case .loadFailed:
            return "Couldn't Load Meal Plans"
        }
    }

    // MARK: - User-Friendly Recovery Suggestions

    var recoverySuggestion: String? {
        switch self {
        case .notFound:
            return "This meal plan may have been removed. Please refresh your meal plans."
        case .unauthorized:
            return "You don't have permission to modify this meal plan. Please contact your therapist."
        case .saveFailed:
            return "We couldn't save your meal plan right now. Please try again."
        case .deleteFailed:
            return "We couldn't remove this meal plan. Please try again."
        case .loadFailed:
            return "We couldn't load your meal plans. Please check your connection and try again."
        }
    }

    // MARK: - Retry Logic

    var shouldRetry: Bool {
        switch self {
        case .notFound, .unauthorized:
            return false
        case .saveFailed, .deleteFailed, .loadFailed:
            return true
        }
    }
}
