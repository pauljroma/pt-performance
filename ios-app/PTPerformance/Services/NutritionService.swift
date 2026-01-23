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
/// BUILD 251: Uses PTSupabaseClient.flexibleDecoder for all date handling
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
        // BUILD 251: Use .execute().value pattern with flexible decoder
        let logger = DebugLogger.shared
        logger.info("FETCH LOGS", "Starting for patient: \(patientId)")

        do {
            // Build base query
            let baseQuery = supabase.client
                .from("nutrition_logs")
                .select()
                .eq("patient_id", value: patientId)

            // Apply date filters and execute
            let logs: [NutritionLog]
            if let start = startDate, let end = endDate {
                let startStr = ISO8601DateFormatter().string(from: start)
                let endStr = ISO8601DateFormatter().string(from: end)
                logger.info("FETCH LOGS", "Date range: \(startStr) to \(endStr)")
                logs = try await baseQuery
                    .gte("logged_at", value: startStr)
                    .lte("logged_at", value: endStr)
                    .order("logged_at", ascending: false)
                    .limit(limit)
                    .execute()
                    .value
            } else if let start = startDate {
                let startStr = ISO8601DateFormatter().string(from: start)
                logger.info("FETCH LOGS", "Start date: \(startStr)")
                logs = try await baseQuery
                    .gte("logged_at", value: startStr)
                    .order("logged_at", ascending: false)
                    .limit(limit)
                    .execute()
                    .value
            } else if let end = endDate {
                let endStr = ISO8601DateFormatter().string(from: end)
                logger.info("FETCH LOGS", "End date: \(endStr)")
                logs = try await baseQuery
                    .lte("logged_at", value: endStr)
                    .order("logged_at", ascending: false)
                    .limit(limit)
                    .execute()
                    .value
            } else {
                logger.info("FETCH LOGS", "No date filter")
                logs = try await baseQuery
                    .order("logged_at", ascending: false)
                    .limit(limit)
                    .execute()
                    .value
            }

            logger.success("FETCH LOGS", "Fetched \(logs.count) logs")
            return logs
        } catch {
            logger.error("FETCH LOGS", "ERROR: \(error)")
            throw error
        }
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
        // BUILD 251: Use .execute().value with flexible decoder
        let result: NutritionLog = try await supabase.client
            .from("nutrition_logs")
            .insert(log)
            .select()
            .single()
            .execute()
            .value
        return result
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
        // BUILD 251: Use .execute().value with flexible decoder
        let goals: [NutritionGoal] = try await supabase.client
            .from("nutrition_goals")
            .select()
            .eq("patient_id", value: patientId)
            .eq("active", value: true)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value
        return goals.first
    }

    /// Fetch all nutrition goals for a patient
    func fetchAllGoals(patientId: String) async throws -> [NutritionGoal] {
        // BUILD 251: Use .execute().value with flexible decoder
        let goals: [NutritionGoal] = try await supabase.client
            .from("nutrition_goals")
            .select()
            .eq("patient_id", value: patientId)
            .order("created_at", ascending: false)
            .execute()
            .value
        return goals
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

        // BUILD 251: Use .execute().value with flexible decoder
        let result: NutritionGoal = try await supabase.client
            .from("nutrition_goals")
            .insert(goal)
            .select()
            .single()
            .execute()
            .value
        return result
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
        // BUILD 251: Use .execute().value with flexible decoder
        let progress: [NutritionGoalProgress] = try await supabase.client
            .from("vw_nutrition_goal_progress")
            .select()
            .eq("patient_id", value: patientId)
            .limit(1)
            .execute()
            .value
        return progress.first
    }

    // MARK: - Analytics

    /// Fetch daily nutrition summary
    func fetchDailySummary(patientId: String, date: Date) async throws -> DailyNutritionSummary? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: date)

        // BUILD 251: Use .execute().value with flexible decoder
        let summaries: [DailyNutritionSummary] = try await supabase.client
            .from("vw_daily_nutrition")
            .select()
            .eq("patient_id", value: patientId)
            .eq("log_date", value: dateStr)
            .limit(1)
            .execute()
            .value
        return summaries.first
    }

    /// Fetch weekly nutrition trends
    func fetchWeeklyTrends(patientId: String, weeks: Int = 4) async throws -> [WeeklyNutritionTrend] {
        // BUILD 251: Use .execute().value with flexible decoder
        let trends: [WeeklyNutritionTrend] = try await supabase.client
            .from("vw_nutrition_trend")
            .select()
            .eq("patient_id", value: patientId)
            .order("week_start", ascending: false)
            .limit(weeks)
            .execute()
            .value
        return trends
    }

    /// Fetch macro distribution for a date
    func fetchMacroDistribution(patientId: String, date: Date) async throws -> MacroDistribution? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: date)

        // BUILD 251: Use .execute().value with flexible decoder
        let distributions: [MacroDistribution] = try await supabase.client
            .from("vw_macro_distribution")
            .select()
            .eq("patient_id", value: patientId)
            .eq("log_date", value: dateStr)
            .limit(1)
            .execute()
            .value
        return distributions.first
    }

    // MARK: - Dashboard Data

    /// Fetch all data needed for nutrition dashboard
    func fetchDashboardData(patientId: String) async throws -> NutritionDashboardData {
        #if DEBUG
        print("🍎 [NUTRITION] Starting dashboard data fetch for patient: \(patientId)")
        #endif

        // Fetch each component separately with error logging
        var todaySummaryResult: DailyNutritionSummary?
        var goalProgressResult: NutritionGoalProgress?
        var weeklyTrendResult: [WeeklyNutritionTrend] = []
        var recentLogsResult: [NutritionLog] = []
        var macroDistributionResult: MacroDistribution?

        do {
            todaySummaryResult = try await fetchDailySummary(patientId: patientId, date: Date())
            #if DEBUG
            print("🍎 [NUTRITION] ✓ Daily summary fetched")
            #endif
        } catch {
            #if DEBUG
            print("🍎 [NUTRITION] ✗ Daily summary error: \(error)")
            #endif
        }

        do {
            goalProgressResult = try await fetchGoalProgress(patientId: patientId)
            #if DEBUG
            print("🍎 [NUTRITION] ✓ Goal progress fetched")
            #endif
        } catch {
            #if DEBUG
            print("🍎 [NUTRITION] ✗ Goal progress error: \(error)")
            #endif
        }

        do {
            weeklyTrendResult = try await fetchWeeklyTrends(patientId: patientId, weeks: 4)
            #if DEBUG
            print("🍎 [NUTRITION] ✓ Weekly trends fetched: \(weeklyTrendResult.count) weeks")
            #endif
        } catch {
            #if DEBUG
            print("🍎 [NUTRITION] ✗ Weekly trends error: \(error)")
            #endif
        }

        do {
            recentLogsResult = try await fetchTodaysLogs(patientId: patientId)
            #if DEBUG
            print("🍎 [NUTRITION] ✓ Today's logs fetched: \(recentLogsResult.count) logs")
            #endif
        } catch {
            #if DEBUG
            print("🍎 [NUTRITION] ✗ Today's logs error: \(error)")
            #endif
        }

        do {
            macroDistributionResult = try await fetchMacroDistribution(patientId: patientId, date: Date())
            #if DEBUG
            print("🍎 [NUTRITION] ✓ Macro distribution fetched")
            #endif
        } catch {
            #if DEBUG
            print("🍎 [NUTRITION] ✗ Macro distribution error: \(error)")
            #endif
        }

        #if DEBUG
        print("🍎 [NUTRITION] Dashboard data fetch complete")
        #endif

        return NutritionDashboardData(
            todaySummary: todaySummaryResult,
            goalProgress: goalProgressResult,
            weeklyTrend: weeklyTrendResult,
            recentLogs: recentLogsResult,
            macroDistribution: macroDistributionResult
        )
    }
}
