import Foundation
import Supabase

/// Data point for pain trend chart
struct PainDataPoint: Codable, Identifiable {
    let id: String
    let date: Date
    let painScore: Double
    let sessionNumber: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case date = "logged_date"
        case painScore = "avg_pain"
        case sessionNumber = "session_number"
    }
}

/// Adherence data
struct AdherenceData: Codable {
    let adherencePercentage: Double
    let completedSessions: Int
    let totalSessions: Int
    let weeklyBreakdown: [WeeklyAdherence]?

    enum CodingKeys: String, CodingKey {
        case adherencePercentage = "adherence_pct"
        case completedSessions = "completed_sessions"
        case totalSessions = "total_sessions"
        case weeklyBreakdown = "weekly_breakdown"
    }
}

struct WeeklyAdherence: Codable, Identifiable {
    let id: String
    let weekNumber: Int
    let adherencePercentage: Double

    enum CodingKeys: String, CodingKey {
        case id
        case weekNumber = "week_number"
        case adherencePercentage = "adherence_pct"
    }
}

/// Session summary for history list
struct SessionSummary: Codable, Identifiable {
    let id: String
    let sessionNumber: Int
    let sessionDate: Date
    let completed: Bool
    let exerciseCount: Int
    let avgPainScore: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case sessionNumber = "session_number"
        case sessionDate = "session_date"
        case completed
        case exerciseCount = "exercise_count"
        case avgPainScore = "avg_pain_score"
    }
}

/// Service for fetching analytics data
class AnalyticsService {
    // MARK: - Singleton

    static let shared = AnalyticsService()

    private let supabase: PTSupabaseClient
    private let errorLogger = ErrorLogger.shared

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
    }

    /// Fetch pain trend data from vw_pain_trend view
    func fetchPainTrend(patientId: String, days: Int = 14) async throws -> [PainDataPoint] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        let response = try await supabase.client
            .from("vw_pain_trend")
            .select()
            .eq("patient_id", value: patientId)
            .gte("logged_date", value: ISO8601DateFormatter().string(from: startDate))
            .order("logged_date", ascending: true)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let dataPoints = try decoder.decode([PainDataPoint].self, from: response.data)
        return dataPoints
    }

    /// Fetch adherence data from vw_patient_adherence view
    func fetchAdherence(patientId: String, days: Int = 30) async throws -> AdherenceData {
        let response = try await supabase.client
            .from("vw_patient_adherence")
            .select()
            .eq("patient_id", value: patientId)
            .single()
            .execute()

        let adherence = try JSONDecoder().decode(AdherenceData.self, from: response.data)
        return adherence
    }

    /// Fetch recent session summaries
    func fetchRecentSessions(patientId: String, limit: Int = 10) async throws -> [SessionSummary] {
        let response = try await supabase.client
            .from("vw_patient_sessions")
            .select("""
                id,
                session_number,
                session_date,
                completed,
                exercise_count,
                avg_pain_score
            """)
            .eq("patient_id", value: patientId)
            .order("session_number", ascending: false)
            .limit(limit)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let sessions = try decoder.decode([SessionSummary].self, from: response.data)
        return sessions
    }

    /// Fetch summary statistics
    func fetchSummaryStats(patientId: String) async throws -> SummaryStats {
        // Fetch adherence
        let adherence = try await fetchAdherence(patientId: patientId, days: 30)

        // Fetch recent pain trend
        let painTrend = try await fetchPainTrend(patientId: patientId, days: 7)
        let avgPain = painTrend.isEmpty ? 0.0 : painTrend.map { $0.painScore }.reduce(0, +) / Double(painTrend.count)

        return SummaryStats(
            adherencePercentage: adherence.adherencePercentage,
            avgPainScore: avgPain,
            completedSessions: adherence.completedSessions,
            totalSessions: adherence.totalSessions
        )
    }

    // MARK: - Helper Methods for Build 46 Analytics

    /// Fetch exercise logs from database with optional filters
    private func fetchExerciseLogs(
        patientId: String,
        exerciseId: String? = nil,
        startDate: Date
    ) async throws -> [ExerciseLog] {
        // Build query conditionally
        let response: Data

        if let exerciseId = exerciseId {
            let result = try await supabase.client
                .from("exercise_logs")
                .select()
                .eq("patient_id", value: patientId)
                .eq("session_exercise_id", value: exerciseId)
                .gte("logged_at", value: startDate.iso8601String)
                .order("logged_at", ascending: true)
                .execute()
            response = result.data
        } else {
            let result = try await supabase.client
                .from("exercise_logs")
                .select()
                .eq("patient_id", value: patientId)
                .gte("logged_at", value: startDate.iso8601String)
                .order("logged_at", ascending: true)
                .execute()
            response = result.data
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let logs = try decoder.decode([ExerciseLog].self, from: response)
        return logs
    }

    /// Group exercise logs by week
    private func groupByWeek(logs: [ExerciseLog]) -> [[ExerciseLog]] {
        var weeklyLogs: [Date: [ExerciseLog]] = [:]

        for log in logs {
            let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: log.createdAt)?.start ?? log.createdAt
            weeklyLogs[weekStart, default: []].append(log)
        }

        return weeklyLogs
            .sorted { $0.key < $1.key }
            .map { $0.value }
    }

    /// Calculate estimated one-rep max using Epley formula
    private func calculateOneRepMax(weight: Double, reps: Int) -> Double {
        // Epley formula: 1RM = weight × (1 + reps/30)
        // For reps = 1, this returns the weight itself
        guard reps > 0 else { return weight }
        return weight * (1 + Double(reps) / 30.0)
    }

    // MARK: - Build 46 Analytics (Volume, Strength, Consistency)

    /// Calculate volume data for a time period
    func calculateVolumeData(
        for patientId: String,
        period: TimePeriod
    ) async throws -> VolumeChartData {
        let startDate = period.startDate
        let logs = try await fetchExerciseLogs(
            patientId: patientId,
            startDate: startDate
        )

        // Group logs by week
        let dataPoints = groupByWeek(logs: logs)
            .map { weekLogs -> VolumeDataPoint in
                let totalVolume = weekLogs.reduce(0.0) { total, log in
                    let weight = log.weight ?? 0
                    let reps = log.reps ?? 0
                    let sets = log.sets
                    return total + (weight * Double(reps) * Double(sets))
                }

                let sessionDates = Set(weekLogs.map { Calendar.current.startOfDay(for: $0.createdAt) })

                return VolumeDataPoint(
                    date: weekLogs.first?.createdAt ?? Date(),
                    totalVolume: totalVolume,
                    sessionCount: sessionDates.count
                )
            }
            .sorted { $0.date < $1.date }

        let totalVolume = dataPoints.reduce(0.0) { $0 + $1.totalVolume }
        let averageVolume = dataPoints.isEmpty ? 0 : totalVolume / Double(dataPoints.count)
        let peakVolume = dataPoints.max(by: { $0.totalVolume < $1.totalVolume })

        return VolumeChartData(
            dataPoints: dataPoints,
            period: period,
            totalVolume: totalVolume,
            averageVolume: averageVolume,
            peakVolume: peakVolume?.totalVolume ?? 0,
            peakDate: peakVolume?.date
        )
    }

    /// Calculate strength progression for a specific exercise
    func calculateStrengthData(
        for patientId: String,
        exerciseId: String,
        period: TimePeriod
    ) async throws -> StrengthChartData {
        let startDate = period.startDate
        let logs = try await fetchExerciseLogs(
            patientId: patientId,
            exerciseId: exerciseId,
            startDate: startDate
        )

        guard let exerciseName = logs.first?.exercise?.name ?? logs.first?.exerciseId.uuidString else {
            throw AnalyticsError.noData
        }

        let dataPoints = logs.compactMap { log -> StrengthDataPoint? in
            guard let weight = log.weight, let reps = log.reps else { return nil }
            let estimatedMax = calculateOneRepMax(weight: weight, reps: reps)

            return StrengthDataPoint(
                date: log.createdAt,
                exerciseName: exerciseName,
                weight: weight,
                reps: reps,
                estimatedOneRepMax: estimatedMax
            )
        }
        .sorted { $0.date < $1.date }

        guard !dataPoints.isEmpty else {
            throw AnalyticsError.noData
        }

        let currentMax = dataPoints.last?.estimatedOneRepMax ?? 0
        let startingMax = dataPoints.first?.estimatedOneRepMax ?? 0
        let improvement = startingMax > 0 ? (currentMax - startingMax) / startingMax : 0

        return StrengthChartData(
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            dataPoints: dataPoints,
            period: period,
            currentMax: currentMax,
            startingMax: startingMax,
            improvement: improvement
        )
    }

    /// Calculate workout consistency over time
    func calculateConsistencyData(
        for patientId: String,
        period: TimePeriod
    ) async throws -> ConsistencyChartData {
        let startDate = period.startDate

        // Fetch scheduled sessions
        let response = try await supabase.client
            .from("scheduled_sessions")
            .select()
            .eq("patient_id", value: patientId)
            .gte("scheduled_date", value: startDate.iso8601String)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let scheduledSessions = try decoder.decode([ScheduledSession].self, from: response.data)

        // Group by week
        var weeklyData: [Date: (scheduled: Int, completed: Int)] = [:]

        for session in scheduledSessions {
            let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: session.scheduledDate)?.start ?? session.scheduledDate

            var data = weeklyData[weekStart] ?? (scheduled: 0, completed: 0)
            data.scheduled += 1
            if session.status == ScheduledSession.ScheduleStatus.completed {
                data.completed += 1
            }
            weeklyData[weekStart] = data
        }

        let dataPoints = weeklyData.map { weekStart, data -> ConsistencyDataPoint in
            let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
            let rate = data.scheduled > 0 ? Double(data.completed) / Double(data.scheduled) : 0

            return ConsistencyDataPoint(
                weekStart: weekStart,
                weekEnd: weekEnd,
                scheduledSessions: data.scheduled,
                completedSessions: data.completed,
                completionRate: rate
            )
        }
        .sorted { $0.weekStart < $1.weekStart }

        let totalScheduled = dataPoints.reduce(0) { $0 + $1.scheduledSessions }
        let totalCompleted = dataPoints.reduce(0) { $0 + $1.completedSessions }
        let overallRate = totalScheduled > 0 ? Double(totalCompleted) / Double(totalScheduled) : 0

        let currentStreak = calculateCurrentStreak(from: dataPoints)
        let longestStreak = calculateLongestStreak(from: dataPoints)

        return ConsistencyChartData(
            dataPoints: dataPoints,
            period: period,
            totalScheduled: totalScheduled,
            totalCompleted: totalCompleted,
            overallCompletionRate: overallRate,
            currentStreak: currentStreak,
            longestStreak: longestStreak
        )
    }

    private func calculateCurrentStreak(from dataPoints: [ConsistencyDataPoint]) -> Int {
        var streak = 0
        for dataPoint in dataPoints.reversed() {
            if dataPoint.completionRate >= 0.8 {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    private func calculateLongestStreak(from dataPoints: [ConsistencyDataPoint]) -> Int {
        var longestStreak = 0
        var currentStreak = 0

        for dataPoint in dataPoints {
            if dataPoint.completionRate >= 0.8 {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }

        return longestStreak
    }
}

// MARK: - Analytics Error

enum AnalyticsError: LocalizedError {
    case calculationFailed(Error)
    case noData

    var errorDescription: String? {
        switch self {
        case .calculationFailed:
            return "Failed to calculate analytics"
        case .noData:
            return "No data available for the selected period"
        }
    }
}

// MARK: - Date Extensions

private extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}

/// Summary statistics
struct SummaryStats {
    let adherencePercentage: Double
    let avgPainScore: Double
    let completedSessions: Int
    let totalSessions: Int
}
