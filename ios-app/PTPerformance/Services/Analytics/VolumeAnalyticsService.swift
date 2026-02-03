//
//  VolumeAnalyticsService.swift
//  PTPerformance
//
//  Service for volume analytics calculations
//  Extracted from AnalyticsService for single responsibility
//

import Foundation
import Supabase

/// Service responsible for volume-related analytics calculations
///
/// Provides methods for calculating and aggregating workout volume data
/// (weight x reps x sets) over time periods. Used for tracking training
/// progression and identifying peak performance periods.
///
/// ## Usage Example
/// ```swift
/// let volumeService = VolumeAnalyticsService()
/// let chartData = try await volumeService.calculateVolumeData(
///     for: patientId,
///     period: .lastMonth
/// )
/// print("Total volume: \(chartData.totalVolume) lbs")
/// print("Peak: \(chartData.peakVolume) lbs on \(chartData.peakDate)")
/// ```
final class VolumeAnalyticsService {

    // MARK: - Dependencies

    private let supabase: PTSupabaseClient
    private let errorLogger = ErrorLogger.shared

    // MARK: - Initialization

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
    }

    // MARK: - Public Methods

    /// Fetch volume time-series data for charts
    /// - Parameters:
    ///   - patientId: The patient UUID
    ///   - period: Time period for the query
    /// - Returns: Array of volume data points for charting
    func fetchVolumeTimeSeries(patientId: String, period: TimePeriod) async throws -> [VolumeDataPoint] {
        let logs = try await fetchExerciseLogs(patientId: patientId, startDate: period.startDate)
        return groupByWeek(logs: logs)
            .map { weekLogs -> VolumeDataPoint in
                let totalVolume = calculateTotalVolume(for: weekLogs)
                let sessionDates = Set(weekLogs.map { Calendar.current.startOfDay(for: $0.createdAt) })

                return VolumeDataPoint(
                    date: weekLogs.first?.createdAt ?? Date(),
                    totalVolume: totalVolume,
                    sessionCount: sessionDates.count
                )
            }
            .sorted { $0.date < $1.date }
    }

    /// Calculate total volume from exercise logs
    /// - Parameter logs: Array of exercise logs
    /// - Returns: Total volume (weight x reps x sets)
    func calculateTotalVolume(for logs: [ExerciseLog]) -> Double {
        logs.reduce(0.0) { total, log in
            let weight = log.weight ?? 0
            let reps = log.reps ?? 0
            let sets = log.sets
            return total + (weight * Double(reps) * Double(sets))
        }
    }

    /// Calculate volume chart data for a time period
    /// - Parameters:
    ///   - patientId: The patient UUID
    ///   - period: Time period for the query
    /// - Returns: Aggregated volume chart data with stats
    func calculateVolumeData(for patientId: String, period: TimePeriod) async throws -> VolumeChartData {
        let dataPoints = try await fetchVolumeTimeSeries(patientId: patientId, period: period)

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

    // MARK: - Private Methods

    /// Fetch exercise logs from database
    private func fetchExerciseLogs(patientId: String, startDate: Date) async throws -> [ExerciseLog] {
        let result = try await supabase.client
            .from("exercise_logs")
            .select()
            .eq("patient_id", value: patientId)
            .gte("logged_at", value: startDate.iso8601String)
            .order("logged_at", ascending: true)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode([ExerciseLog].self, from: result.data)
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
}

// MARK: - Date Extension

private extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}
