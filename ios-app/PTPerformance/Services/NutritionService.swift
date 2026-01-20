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

    // MARK: - Flexible JSON Decoder

    /// Decoder that handles both ISO8601 and simple date formats
    private func flexibleDecode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try ISO8601 with fractional seconds
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }

            // Try ISO8601 without fractional seconds
            isoFormatter.formatOptions = [.withInternetDateTime]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }

            // Try simple date format (yyyy-MM-dd)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }

        do {
            return try decoder.decode(type, from: data)
        } catch {
            #if DEBUG
            print("🍎 [NUTRITION] Decode error: \(error)")
            if let json = String(data: data, encoding: .utf8) {
                print("🍎 [NUTRITION] Failed JSON: \(json)")
            }
            #endif
            throw error
        }
    }

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
        #if DEBUG
        print("🍎 [NUTRITION] Fetching goal progress for patient: \(patientId)")
        #endif

        let response = try await supabase.client
            .from("vw_nutrition_goal_progress")
            .select()
            .eq("patient_id", value: patientId)
            .limit(1)
            .execute()

        #if DEBUG
        if let json = String(data: response.data, encoding: .utf8) {
            print("🍎 [NUTRITION] Goal progress response: \(json)")
        }
        #endif

        let progress = try flexibleDecode([NutritionGoalProgress].self, from: response.data)
        return progress.first
    }

    // MARK: - Analytics

    /// Fetch daily nutrition summary
    func fetchDailySummary(patientId: String, date: Date) async throws -> DailyNutritionSummary? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: date)

        #if DEBUG
        print("🍎 [NUTRITION] Fetching daily summary for patient: \(patientId), date: \(dateStr)")
        #endif

        let response = try await supabase.client
            .from("vw_daily_nutrition")
            .select()
            .eq("patient_id", value: patientId)
            .eq("log_date", value: dateStr)
            .limit(1)
            .execute()

        #if DEBUG
        if let json = String(data: response.data, encoding: .utf8) {
            print("🍎 [NUTRITION] Daily summary response: \(json)")
        }
        #endif

        let decoder = JSONDecoder()
        // Use flexible date decoding for date-only fields
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try ISO8601 first
            if let date = ISO8601DateFormatter().date(from: dateString) {
                return date
            }
            // Try simple date format
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }
        let summaries = try decoder.decode([DailyNutritionSummary].self, from: response.data)
        return summaries.first
    }

    /// Fetch weekly nutrition trends
    func fetchWeeklyTrends(patientId: String, weeks: Int = 4) async throws -> [WeeklyNutritionTrend] {
        #if DEBUG
        print("🍎 [NUTRITION] Fetching weekly trends for patient: \(patientId)")
        #endif

        let response = try await supabase.client
            .from("vw_nutrition_trend")
            .select()
            .eq("patient_id", value: patientId)
            .order("week_start", ascending: false)
            .limit(weeks)
            .execute()

        #if DEBUG
        if let json = String(data: response.data, encoding: .utf8) {
            print("🍎 [NUTRITION] Weekly trends response: \(json)")
        }
        #endif

        return try flexibleDecode([WeeklyNutritionTrend].self, from: response.data)
    }

    /// Fetch macro distribution for a date
    func fetchMacroDistribution(patientId: String, date: Date) async throws -> MacroDistribution? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: date)

        #if DEBUG
        print("🍎 [NUTRITION] Fetching macro distribution for patient: \(patientId), date: \(dateStr)")
        #endif

        let response = try await supabase.client
            .from("vw_macro_distribution")
            .select()
            .eq("patient_id", value: patientId)
            .eq("log_date", value: dateStr)
            .limit(1)
            .execute()

        #if DEBUG
        if let json = String(data: response.data, encoding: .utf8) {
            print("🍎 [NUTRITION] Macro distribution response: \(json)")
        }
        #endif

        let distributions = try flexibleDecode([MacroDistribution].self, from: response.data)
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
