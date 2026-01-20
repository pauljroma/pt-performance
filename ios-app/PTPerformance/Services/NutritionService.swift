//
//  NutritionService.swift
//  PTPerformance
//
//  BUILD 222: Nutrition Module - Core nutrition service
//

import Foundation
import Supabase

// MARK: - Input Models for Supabase

/// Input for deactivating goals
struct DeactivateGoalInput: Codable {
    let active: Bool
}

/// Input for updating nutrition log (subset of fields)
struct UpdateNutritionLogInput: Codable {
    let mealType: String?
    let foodItems: [LoggedFoodItem]?
    let totalCalories: Int?
    let totalProteinG: Double?
    let totalCarbsG: Double?
    let totalFatG: Double?
    let totalFiberG: Double?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case notes
        case mealType = "meal_type"
        case foodItems = "food_items"
        case totalCalories = "total_calories"
        case totalProteinG = "total_protein_g"
        case totalCarbsG = "total_carbs_g"
        case totalFatG = "total_fat_g"
        case totalFiberG = "total_fiber_g"
    }
}

/// Service for managing nutrition logging, goals, and analytics
@MainActor
class NutritionService {
    static let shared = NutritionService()
    private let supabase = PTSupabaseClient.shared

    private init() {}

    // MARK: - Nutrition Logs

    /// Fetch nutrition logs for a patient within a date range
    func fetchNutritionLogs(
        patientId: String,
        startDate: Date? = nil,
        endDate: Date? = nil,
        limit: Int = 50
    ) async throws -> [NutritionLog] {
        // Build query - apply filters before transforms
        let baseQuery = supabase.client
            .from("nutrition_logs")
            .select()
            .eq("patient_id", value: patientId)

        let response: PostgrestResponse<Data>
        if let start = startDate, let end = endDate {
            let startStr = ISO8601DateFormatter().string(from: start)
            let endStr = ISO8601DateFormatter().string(from: end)
            response = try await baseQuery
                .gte("logged_at", value: startStr)
                .lte("logged_at", value: endStr)
                .order("logged_at", ascending: false)
                .limit(limit)
                .execute()
        } else if let start = startDate {
            let startStr = ISO8601DateFormatter().string(from: start)
            response = try await baseQuery
                .gte("logged_at", value: startStr)
                .order("logged_at", ascending: false)
                .limit(limit)
                .execute()
        } else if let end = endDate {
            let endStr = ISO8601DateFormatter().string(from: end)
            response = try await baseQuery
                .lte("logged_at", value: endStr)
                .order("logged_at", ascending: false)
                .limit(limit)
                .execute()
        } else {
            response = try await baseQuery
                .order("logged_at", ascending: false)
                .limit(limit)
                .execute()
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([NutritionLog].self, from: response.data)
    }

    /// Fetch today's nutrition logs for a patient
    func fetchTodaysLogs(patientId: String) async throws -> [NutritionLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return try await fetchNutritionLogs(
            patientId: patientId,
            startDate: startOfDay,
            endDate: endOfDay
        )
    }

    /// Create a new nutrition log
    func createNutritionLog(_ log: CreateNutritionLogDTO) async throws -> NutritionLog {
        // Use the DTO directly since it's already Codable
        let response = try await supabase.client
            .from("nutrition_logs")
            .insert(log)
            .select()
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(NutritionLog.self, from: response.data)
    }

    /// Update an existing nutrition log
    func updateNutritionLog(id: UUID, updates: UpdateNutritionLogInput) async throws {
        _ = try await supabase.client
            .from("nutrition_logs")
            .update(updates)
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Delete a nutrition log
    func deleteNutritionLog(id: UUID) async throws {
        _ = try await supabase.client
            .from("nutrition_logs")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Nutrition Goals

    /// Fetch active nutrition goal for a patient
    func fetchActiveGoal(patientId: String) async throws -> NutritionGoal? {
        let response = try await supabase.client
            .from("nutrition_goals")
            .select()
            .eq("patient_id", value: patientId)
            .eq("active", value: true)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let goals = try decoder.decode([NutritionGoal].self, from: response.data)
        return goals.first
    }

    /// Fetch all nutrition goals for a patient
    func fetchAllGoals(patientId: String) async throws -> [NutritionGoal] {
        let response = try await supabase.client
            .from("nutrition_goals")
            .select()
            .eq("patient_id", value: patientId)
            .order("created_at", ascending: false)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([NutritionGoal].self, from: response.data)
    }

    /// Create a new nutrition goal
    func createNutritionGoal(_ goal: CreateNutritionGoalDTO) async throws -> NutritionGoal {
        // First, deactivate any existing active goals
        let deactivate = DeactivateGoalInput(active: false)
        _ = try await supabase.client
            .from("nutrition_goals")
            .update(deactivate)
            .eq("patient_id", value: goal.patientId)
            .eq("active", value: true)
            .execute()

        // Use the DTO directly since it's already Codable
        let response = try await supabase.client
            .from("nutrition_goals")
            .insert(goal)
            .select()
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(NutritionGoal.self, from: response.data)
    }

    /// Update a nutrition goal
    func updateNutritionGoal(id: UUID, updates: UpdateNutritionGoalDTO) async throws {
        _ = try await supabase.client
            .from("nutrition_goals")
            .update(updates)
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Goal Progress

    /// Fetch current goal progress from view
    func fetchGoalProgress(patientId: String) async throws -> NutritionGoalProgress? {
        let response = try await supabase.client
            .from("vw_nutrition_goal_progress")
            .select()
            .eq("patient_id", value: patientId)
            .limit(1)
            .execute()

        let decoder = JSONDecoder()
        let progress = try decoder.decode([NutritionGoalProgress].self, from: response.data)
        return progress.first
    }

    // MARK: - Analytics

    /// Fetch daily nutrition summary
    func fetchDailySummary(patientId: String, date: Date) async throws -> DailyNutritionSummary? {
        let dateStr = ISO8601DateFormatter().string(from: date).prefix(10)

        let response = try await supabase.client
            .from("vw_daily_nutrition")
            .select()
            .eq("patient_id", value: patientId)
            .eq("log_date", value: String(dateStr))
            .limit(1)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let summaries = try decoder.decode([DailyNutritionSummary].self, from: response.data)
        return summaries.first
    }

    /// Fetch weekly nutrition trends
    func fetchWeeklyTrends(patientId: String, weeks: Int = 4) async throws -> [WeeklyNutritionTrend] {
        let response = try await supabase.client
            .from("vw_nutrition_trend")
            .select()
            .eq("patient_id", value: patientId)
            .order("week_start", ascending: false)
            .limit(weeks)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([WeeklyNutritionTrend].self, from: response.data)
    }

    /// Fetch macro distribution for a date
    func fetchMacroDistribution(patientId: String, date: Date) async throws -> MacroDistribution? {
        let dateStr = ISO8601DateFormatter().string(from: date).prefix(10)

        let response = try await supabase.client
            .from("vw_macro_distribution")
            .select()
            .eq("patient_id", value: patientId)
            .eq("log_date", value: String(dateStr))
            .limit(1)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let distributions = try decoder.decode([MacroDistribution].self, from: response.data)
        return distributions.first
    }

    // MARK: - Dashboard Data

    /// Fetch all data needed for nutrition dashboard
    func fetchDashboardData(patientId: String) async throws -> NutritionDashboardData {
        async let todaySummary = fetchDailySummary(patientId: patientId, date: Date())
        async let goalProgress = fetchGoalProgress(patientId: patientId)
        async let weeklyTrend = fetchWeeklyTrends(patientId: patientId, weeks: 4)
        async let recentLogs = fetchTodaysLogs(patientId: patientId)
        async let macroDistribution = fetchMacroDistribution(patientId: patientId, date: Date())

        return try await NutritionDashboardData(
            todaySummary: todaySummary,
            goalProgress: goalProgress,
            weeklyTrend: weeklyTrend,
            recentLogs: recentLogs,
            macroDistribution: macroDistribution
        )
    }
}
