//
//  NutritionService.swift
//  PTPerformance
//
//  Nutrition Module - Core nutrition service.
//  Manages nutrition logging, goals, analytics, and macro tracking.
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

/// Service for managing nutrition logging, goals, and analytics.
///
/// Provides comprehensive nutrition tracking functionality including:
/// - Meal logging with macro breakdown
/// - Daily/weekly analytics and trends
/// - Goal setting and progress tracking
/// - Dashboard data aggregation
///
/// Uses PTSupabaseClient.flexibleDecoder for all date handling to support
/// multiple PostgreSQL date formats (TIMESTAMPTZ, DATE, TIME).
///
/// ## Thread Safety
/// Marked `@MainActor` for safe UI updates. All methods are async.
@MainActor
class NutritionService {
    static let shared = NutritionService()
    private let supabase = PTSupabaseClient.shared
    private let logger = DebugLogger.shared
    private let errorLogger = ErrorLogger.shared

    private init() {}

    // MARK: - Nutrition Logs

    /// Fetch nutrition logs for a patient within a date range.
    ///
    /// - Parameters:
    ///   - patientId: The patient's ID string
    ///   - startDate: Optional start date filter (inclusive)
    ///   - endDate: Optional end date filter (inclusive)
    ///   - limit: Maximum number of logs to return (default: 50)
    /// - Returns: Array of nutrition logs, ordered by logged date (newest first)
    /// - Throws: Database errors if the query fails
    func fetchNutritionLogs(
        patientId: String,
        startDate: Date? = nil,
        endDate: Date? = nil,
        limit: Int = 50
    ) async throws -> [NutritionLog] {
        logger.log("[NutritionService] Fetching logs for patient: \(patientId)", level: .diagnostic)

        guard !patientId.isEmpty else {
            logger.log("[NutritionService] Empty patient ID provided", level: .warning)
            return []
        }

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
                logger.log("[NutritionService] Date range: \(startStr) to \(endStr)", level: .diagnostic)
                logs = try await baseQuery
                    .gte("logged_at", value: startStr)
                    .lte("logged_at", value: endStr)
                    .order("logged_at", ascending: false)
                    .limit(limit)
                    .execute()
                    .value
            } else if let start = startDate {
                let startStr = ISO8601DateFormatter().string(from: start)
                logger.log("[NutritionService] Start date filter: \(startStr)", level: .diagnostic)
                logs = try await baseQuery
                    .gte("logged_at", value: startStr)
                    .order("logged_at", ascending: false)
                    .limit(limit)
                    .execute()
                    .value
            } else if let end = endDate {
                let endStr = ISO8601DateFormatter().string(from: end)
                logger.log("[NutritionService] End date filter: \(endStr)", level: .diagnostic)
                logs = try await baseQuery
                    .lte("logged_at", value: endStr)
                    .order("logged_at", ascending: false)
                    .limit(limit)
                    .execute()
                    .value
            } else {
                logs = try await baseQuery
                    .order("logged_at", ascending: false)
                    .limit(limit)
                    .execute()
                    .value
            }

            logger.log("[NutritionService] Fetched \(logs.count) nutrition logs", level: .success)
            return logs
        } catch {
            errorLogger.logError(error, context: "NutritionService.fetchNutritionLogs", metadata: [
                "patient_id": patientId,
                "limit": String(limit)
            ])
            throw error
        }
    }

    /// Fetch today's nutrition logs for a patient.
    ///
    /// - Parameter patientId: The patient's ID string
    /// - Returns: Array of today's nutrition logs
    /// - Throws: Database errors if the query fails
    func fetchTodaysLogs(patientId: String) async throws -> [NutritionLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            logger.log("[NutritionService] Failed to calculate end of day", level: .warning)
            return []
        }

        return try await fetchNutritionLogs(
            patientId: patientId,
            startDate: startOfDay,
            endDate: endOfDay
        )
    }

    /// Create a new nutrition log.
    ///
    /// - Parameter log: The nutrition log data to create
    /// - Returns: The created nutrition log with server-assigned ID
    /// - Throws: Database errors if the insert fails
    func createNutritionLog(_ log: CreateNutritionLogDTO) async throws -> NutritionLog {
        logger.log("[NutritionService] Creating nutrition log", level: .diagnostic)

        do {
            let result: NutritionLog = try await supabase.client
                .from("nutrition_logs")
                .insert(log)
                .select()
                .single()
                .execute()
                .value

            logger.log("[NutritionService] Nutrition log created with ID: \(result.id)", level: .success)
            return result
        } catch {
            errorLogger.logError(error, context: "NutritionService.createNutritionLog")
            throw error
        }
    }

    /// Update an existing nutrition log.
    ///
    /// - Parameters:
    ///   - id: The nutrition log's UUID
    ///   - updates: The fields to update
    /// - Throws: Database errors if the update fails
    func updateNutritionLog(id: UUID, updates: UpdateNutritionLogInput) async throws {
        logger.log("[NutritionService] Updating nutrition log: \(id)", level: .diagnostic)

        do {
            _ = try await supabase.client
                .from("nutrition_logs")
                .update(updates)
                .eq("id", value: id.uuidString)
                .execute()

            logger.log("[NutritionService] Nutrition log updated successfully", level: .success)
        } catch {
            errorLogger.logError(error, context: "NutritionService.updateNutritionLog", metadata: [
                "log_id": id.uuidString
            ])
            throw error
        }
    }

    /// Delete a nutrition log.
    ///
    /// - Parameter id: The nutrition log's UUID
    /// - Throws: Database errors if the delete fails
    func deleteNutritionLog(id: UUID) async throws {
        logger.log("[NutritionService] Deleting nutrition log: \(id)", level: .diagnostic)

        do {
            _ = try await supabase.client
                .from("nutrition_logs")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()

            logger.log("[NutritionService] Nutrition log deleted successfully", level: .success)
        } catch {
            errorLogger.logError(error, context: "NutritionService.deleteNutritionLog", metadata: [
                "log_id": id.uuidString
            ])
            throw error
        }
    }

    // MARK: - Nutrition Goals

    /// Fetch active nutrition goal for a patient.
    ///
    /// - Parameter patientId: The patient's ID string
    /// - Returns: The active nutrition goal, or nil if none exists
    /// - Throws: Database errors if the query fails
    func fetchActiveGoal(patientId: String) async throws -> NutritionGoal? {
        logger.log("[NutritionService] Fetching active goal for patient: \(patientId)", level: .diagnostic)

        guard !patientId.isEmpty else {
            logger.log("[NutritionService] Empty patient ID provided", level: .warning)
            return nil
        }

        do {
            let goals: [NutritionGoal] = try await supabase.client
                .from("nutrition_goals")
                .select()
                .eq("patient_id", value: patientId)
                .eq("active", value: true)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value

            if let goal = goals.first {
                logger.log("[NutritionService] Found active goal: \(goal.id)", level: .success)
            } else {
                logger.log("[NutritionService] No active goal found", level: .info)
            }
            return goals.first
        } catch {
            errorLogger.logError(error, context: "NutritionService.fetchActiveGoal", metadata: [
                "patient_id": patientId
            ])
            throw error
        }
    }

    /// Fetch all nutrition goals for a patient.
    ///
    /// - Parameter patientId: The patient's ID string
    /// - Returns: Array of all goals, ordered by creation date (newest first)
    /// - Throws: Database errors if the query fails
    func fetchAllGoals(patientId: String) async throws -> [NutritionGoal] {
        logger.log("[NutritionService] Fetching all goals for patient: \(patientId)", level: .diagnostic)

        guard !patientId.isEmpty else {
            logger.log("[NutritionService] Empty patient ID provided", level: .warning)
            return []
        }

        do {
            let goals: [NutritionGoal] = try await supabase.client
                .from("nutrition_goals")
                .select()
                .eq("patient_id", value: patientId)
                .order("created_at", ascending: false)
                .execute()
                .value

            logger.log("[NutritionService] Fetched \(goals.count) goals", level: .success)
            return goals
        } catch {
            errorLogger.logError(error, context: "NutritionService.fetchAllGoals", metadata: [
                "patient_id": patientId
            ])
            throw error
        }
    }

    /// Create a new nutrition goal.
    ///
    /// Automatically deactivates any existing active goals for the patient
    /// before creating the new one.
    ///
    /// - Parameter goal: The nutrition goal data to create
    /// - Returns: The created nutrition goal with server-assigned ID
    /// - Throws: Database errors if the insert fails
    func createNutritionGoal(_ goal: CreateNutritionGoalDTO) async throws -> NutritionGoal {
        logger.log("[NutritionService] Creating nutrition goal for patient: \(goal.patientId)", level: .diagnostic)

        do {
            // First, deactivate any existing active goals
            let deactivate = DeactivateGoalInput(active: false)
            _ = try await supabase.client
                .from("nutrition_goals")
                .update(deactivate)
                .eq("patient_id", value: goal.patientId)
                .eq("active", value: true)
                .execute()

            logger.log("[NutritionService] Deactivated existing goals", level: .diagnostic)

            // Create new goal
            let result: NutritionGoal = try await supabase.client
                .from("nutrition_goals")
                .insert(goal)
                .select()
                .single()
                .execute()
                .value

            logger.log("[NutritionService] Nutrition goal created with ID: \(result.id)", level: .success)
            return result
        } catch {
            errorLogger.logError(error, context: "NutritionService.createNutritionGoal", metadata: [
                "patient_id": goal.patientId
            ])
            throw error
        }
    }

    /// Update a nutrition goal.
    ///
    /// - Parameters:
    ///   - id: The goal's UUID
    ///   - updates: The fields to update
    /// - Throws: Database errors if the update fails
    func updateNutritionGoal(id: UUID, updates: UpdateNutritionGoalDTO) async throws {
        logger.log("[NutritionService] Updating nutrition goal: \(id)", level: .diagnostic)

        do {
            _ = try await supabase.client
                .from("nutrition_goals")
                .update(updates)
                .eq("id", value: id.uuidString)
                .execute()

            logger.log("[NutritionService] Nutrition goal updated successfully", level: .success)
        } catch {
            errorLogger.logError(error, context: "NutritionService.updateNutritionGoal", metadata: [
                "goal_id": id.uuidString
            ])
            throw error
        }
    }

    // MARK: - Goal Progress

    /// Fetch current goal progress from view.
    ///
    /// - Parameter patientId: The patient's ID string
    /// - Returns: Goal progress data, or nil if no active goal
    /// - Throws: Database errors if the query fails
    func fetchGoalProgress(patientId: String) async throws -> NutritionGoalProgress? {
        logger.log("[NutritionService] Fetching goal progress for patient: \(patientId)", level: .diagnostic)

        guard !patientId.isEmpty else {
            return nil
        }

        do {
            let progress: [NutritionGoalProgress] = try await supabase.client
                .from("vw_nutrition_goal_progress")
                .select()
                .eq("patient_id", value: patientId)
                .limit(1)
                .execute()
                .value

            logger.log("[NutritionService] Goal progress fetched: \(progress.first != nil)", level: .success)
            return progress.first
        } catch {
            errorLogger.logError(error, context: "NutritionService.fetchGoalProgress", metadata: [
                "patient_id": patientId
            ])
            throw error
        }
    }

    // MARK: - Analytics

    /// Fetch daily nutrition summary.
    ///
    /// - Parameters:
    ///   - patientId: The patient's ID string
    ///   - date: The date to fetch summary for
    /// - Returns: Daily summary with macro totals, or nil if no data
    /// - Throws: Database errors if the query fails
    func fetchDailySummary(patientId: String, date: Date) async throws -> DailyNutritionSummary? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: date)

        logger.log("[NutritionService] Fetching daily summary for \(dateStr)", level: .diagnostic)

        guard !patientId.isEmpty else {
            return nil
        }

        do {
            let summaries: [DailyNutritionSummary] = try await supabase.client
                .from("vw_daily_nutrition")
                .select()
                .eq("patient_id", value: patientId)
                .eq("log_date", value: dateStr)
                .limit(1)
                .execute()
                .value

            logger.log("[NutritionService] Daily summary fetched: \(summaries.first != nil)", level: .success)
            return summaries.first
        } catch {
            errorLogger.logError(error, context: "NutritionService.fetchDailySummary", metadata: [
                "patient_id": patientId,
                "date": dateStr
            ])
            throw error
        }
    }

    /// Fetch weekly nutrition trends.
    ///
    /// - Parameters:
    ///   - patientId: The patient's ID string
    ///   - weeks: Number of weeks to fetch (default: 4)
    /// - Returns: Array of weekly trends, ordered by week (newest first)
    /// - Throws: Database errors if the query fails
    func fetchWeeklyTrends(patientId: String, weeks: Int = 4) async throws -> [WeeklyNutritionTrend] {
        logger.log("[NutritionService] Fetching weekly trends for past \(weeks) weeks", level: .diagnostic)

        guard !patientId.isEmpty else {
            return []
        }

        do {
            let trends: [WeeklyNutritionTrend] = try await supabase.client
                .from("vw_nutrition_trend")
                .select()
                .eq("patient_id", value: patientId)
                .order("week_start", ascending: false)
                .limit(weeks)
                .execute()
                .value

            logger.log("[NutritionService] Fetched \(trends.count) weekly trends", level: .success)
            return trends
        } catch {
            errorLogger.logError(error, context: "NutritionService.fetchWeeklyTrends", metadata: [
                "patient_id": patientId,
                "weeks": String(weeks)
            ])
            throw error
        }
    }

    /// Fetch macro distribution for a date.
    ///
    /// - Parameters:
    ///   - patientId: The patient's ID string
    ///   - date: The date to fetch distribution for
    /// - Returns: Macro distribution breakdown, or nil if no data
    /// - Throws: Database errors if the query fails
    func fetchMacroDistribution(patientId: String, date: Date) async throws -> MacroDistribution? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: date)

        logger.log("[NutritionService] Fetching macro distribution for \(dateStr)", level: .diagnostic)

        guard !patientId.isEmpty else {
            return nil
        }

        do {
            let distributions: [MacroDistribution] = try await supabase.client
                .from("vw_macro_distribution")
                .select()
                .eq("patient_id", value: patientId)
                .eq("log_date", value: dateStr)
                .limit(1)
                .execute()
                .value

            logger.log("[NutritionService] Macro distribution fetched: \(distributions.first != nil)", level: .success)
            return distributions.first
        } catch {
            errorLogger.logError(error, context: "NutritionService.fetchMacroDistribution", metadata: [
                "patient_id": patientId,
                "date": dateStr
            ])
            throw error
        }
    }

    // MARK: - Dashboard Data

    /// Fetch all data needed for nutrition dashboard.
    ///
    /// Aggregates multiple data sources for the nutrition dashboard display.
    /// Individual fetch failures are logged but do not fail the overall request.
    ///
    /// - Parameter patientId: The patient's ID string
    /// - Returns: Dashboard data with all available nutrition information
    /// - Note: Never throws - partial data is returned if individual fetches fail
    func fetchDashboardData(patientId: String) async throws -> NutritionDashboardData {
        logger.log("[NutritionService] Starting dashboard data fetch for patient: \(patientId)", level: .diagnostic)
        let startTime = Date()

        guard !patientId.isEmpty else {
            logger.log("[NutritionService] Empty patient ID, returning empty dashboard", level: .warning)
            return NutritionDashboardData(
                todaySummary: nil,
                goalProgress: nil,
                weeklyTrend: [],
                recentLogs: [],
                macroDistribution: nil
            )
        }

        // Fetch each component separately with error logging
        var todaySummaryResult: DailyNutritionSummary?
        var goalProgressResult: NutritionGoalProgress?
        var weeklyTrendResult: [WeeklyNutritionTrend] = []
        var recentLogsResult: [NutritionLog] = []
        var macroDistributionResult: MacroDistribution?

        do {
            todaySummaryResult = try await fetchDailySummary(patientId: patientId, date: Date())
            logger.log("[NutritionService] Daily summary fetched", level: .diagnostic)
        } catch {
            logger.log("[NutritionService] Daily summary error: \(error.localizedDescription)", level: .warning)
        }

        do {
            goalProgressResult = try await fetchGoalProgress(patientId: patientId)
            logger.log("[NutritionService] Goal progress fetched", level: .diagnostic)
        } catch {
            logger.log("[NutritionService] Goal progress error: \(error.localizedDescription)", level: .warning)
        }

        do {
            weeklyTrendResult = try await fetchWeeklyTrends(patientId: patientId, weeks: 4)
            logger.log("[NutritionService] Weekly trends fetched: \(weeklyTrendResult.count) weeks", level: .diagnostic)
        } catch {
            logger.log("[NutritionService] Weekly trends error: \(error.localizedDescription)", level: .warning)
        }

        do {
            recentLogsResult = try await fetchTodaysLogs(patientId: patientId)
            logger.log("[NutritionService] Today's logs fetched: \(recentLogsResult.count) logs", level: .diagnostic)
        } catch {
            logger.log("[NutritionService] Today's logs error: \(error.localizedDescription)", level: .warning)
        }

        do {
            macroDistributionResult = try await fetchMacroDistribution(patientId: patientId, date: Date())
            logger.log("[NutritionService] Macro distribution fetched", level: .diagnostic)
        } catch {
            logger.log("[NutritionService] Macro distribution error: \(error.localizedDescription)", level: .warning)
        }

        let duration = Date().timeIntervalSince(startTime)
        logger.log("[NutritionService] Dashboard data fetch complete in \(String(format: "%.2f", duration * 1000))ms", level: .success)

        return NutritionDashboardData(
            todaySummary: todaySummaryResult,
            goalProgress: goalProgressResult,
            weeklyTrend: weeklyTrendResult,
            recentLogs: recentLogsResult,
            macroDistribution: macroDistributionResult
        )
    }
}
