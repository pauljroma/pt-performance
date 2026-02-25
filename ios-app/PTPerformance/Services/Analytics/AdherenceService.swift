//
//  AdherenceService.swift
//  PTPerformance
//
//  Service for workout adherence and consistency analytics
//  Extracted from AnalyticsService for single responsibility
//

import Foundation
import Supabase

/// Service responsible for adherence and consistency metrics
///
/// Provides methods for tracking workout consistency, calculating adherence
/// percentages, and monitoring pain trends over time. Essential for
/// understanding patient engagement and recovery patterns.
///
/// ## Usage Example
/// ```swift
/// let adherenceService = AdherenceService()
///
/// // Get adherence data
/// let adherence = try await adherenceService.fetchAdherence(
///     patientId: patientId,
///     days: 30
/// )
/// print("Adherence: \(adherence.adherencePercentage)%")
///
/// // Get consistency with streaks
/// let consistency = try await adherenceService.calculateConsistencyData(
///     for: patientId,
///     period: .lastMonth
/// )
/// print("Current streak: \(consistency.currentStreak) weeks")
/// ```
final class AdherenceService {

    // MARK: - Dependencies

    private let supabase: PTSupabaseClient
    private let errorLogger = ErrorLogger.shared

    // MARK: - Initialization

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
    }

    // MARK: - Public Methods

    /// Fetch adherence data from vw_patient_adherence view
    /// - Parameters:
    ///   - patientId: The patient UUID
    ///   - days: Number of days to query (default 30)
    /// - Returns: Adherence data with completion metrics
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

    /// Calculate workout consistency over time
    /// - Parameters:
    ///   - patientId: The patient UUID
    ///   - period: Time period for the query
    /// - Returns: Consistency chart data with streak information
    func calculateConsistencyData(for patientId: String, period: TimePeriod) async throws -> ConsistencyChartData {
        let startDate = period.startDate

        // Fetch scheduled sessions
        let response = try await supabase.client
            .from("scheduled_sessions")
            .select()
            .eq("patient_id", value: patientId)
            .gte("scheduled_date", value: startDate.iso8601String)
            .execute()

        let scheduledSessions = try PTSupabaseClient.flexibleDecoder.decode([ScheduledSession].self, from: response.data)

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

    /// Calculate pain trend data from vw_pain_trend view
    /// - Parameters:
    ///   - patientId: The patient UUID
    ///   - days: Number of days to query (default 14)
    /// - Returns: Array of pain data points for charting
    func fetchPainTrend(patientId: String, days: Int = 14) async throws -> [PainDataPoint] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        let response = try await supabase.client
            .from("vw_pain_trend")
            .select()
            .eq("patient_id", value: patientId)
            .gte("logged_date", value: ISO8601DateFormatter().string(from: startDate))
            .order("logged_date", ascending: true)
            .execute()

        return try PTSupabaseClient.flexibleDecoder.decode([PainDataPoint].self, from: response.data)
    }

    /// Fetch summary statistics combining adherence and pain data
    /// - Parameter patientId: The patient UUID
    /// - Returns: Summary stats for dashboard display
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

    // MARK: - Private Methods

    /// Calculate current streak of weeks with 80%+ completion
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

    /// Calculate longest streak of weeks with 80%+ completion
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

// MARK: - Date Extension

private extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}
