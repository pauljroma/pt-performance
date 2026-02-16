//
//  TrendAnalysisService.swift
//  PTPerformance
//
//  Created for M8 - Historical Trend Analysis Feature
//  Service for analyzing long-term performance trends
//

import Foundation
import Supabase

// MARK: - Trend Analysis Service

/// Service for fetching and analyzing long-term performance trends
@MainActor
final class TrendAnalysisService: ObservableObject {

    // MARK: - Singleton

    static let shared = TrendAnalysisService()

    // MARK: - Dependencies

    private let supabase: PTSupabaseClient
    private let errorLogger = ErrorLogger.shared

    // MARK: - Cache

    private var analysisCache: [String: (analysis: TrendAnalysis, timestamp: Date)] = [:]
    private let cacheValidityDuration: TimeInterval = 300  // 5 minutes

    // MARK: - Initialization

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
    }

    // MARK: - Public Methods

    /// Analyze trend for a specific metric and time range
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - metric: The metric type to analyze
    ///   - range: The time range to analyze
    /// - Returns: Complete trend analysis with data points and summary
    func analyzeTrend(
        patientId: UUID,
        metric: TrendMetricType,
        range: TrendTimeRange
    ) async throws -> TrendAnalysis {
        // Check cache
        let cacheKey = "\(patientId.uuidString)_\(metric.rawValue)_\(range.rawValue)"
        if let cached = analysisCache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < cacheValidityDuration {
            return cached.analysis
        }

        // Fetch raw data
        let dataPoints = try await fetchDataPoints(
            patientId: patientId,
            metric: metric,
            range: range
        )

        // Calculate summary statistics
        let summary = calculateSummary(dataPoints: dataPoints, metric: metric)

        // Generate insights
        let insights = generateInsights(dataPoints: dataPoints, summary: summary, metric: metric)

        // Create analysis result
        var summaryWithInsights = summary
        summaryWithInsights = TrendSummary(
            startValue: summary.startValue,
            endValue: summary.endValue,
            percentChange: summary.percentChange,
            direction: summary.direction,
            volatility: summary.volatility,
            bestValue: summary.bestValue,
            bestDate: summary.bestDate,
            worstValue: summary.worstValue,
            worstDate: summary.worstDate,
            insights: insights
        )

        let analysis = TrendAnalysis(
            patientId: patientId,
            metricType: metric,
            timeRange: range,
            dataPoints: dataPoints,
            summary: summaryWithInsights
        )

        // Cache result
        analysisCache[cacheKey] = (analysis, Date())

        return analysis
    }

    /// Compare two date ranges for a metric
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - metric: The metric type to compare
    ///   - range1: First date range
    ///   - range2: Second date range
    /// - Returns: Comparison between the two ranges
    func compareRanges(
        patientId: UUID,
        metric: TrendMetricType,
        range1: DateInterval,
        range2: DateInterval
    ) async throws -> RangeComparison {
        // Fetch data for both ranges
        async let dataPoints1Task = fetchDataPointsForInterval(
            patientId: patientId,
            metric: metric,
            interval: range1
        )
        async let dataPoints2Task = fetchDataPointsForInterval(
            patientId: patientId,
            metric: metric,
            interval: range2
        )

        let (dataPoints1, dataPoints2) = try await (dataPoints1Task, dataPoints2Task)

        // Calculate summaries
        let summary1 = calculateSummary(dataPoints: dataPoints1, metric: metric)
        let summary2 = calculateSummary(dataPoints: dataPoints2, metric: metric)

        // Calculate improvement
        let improvement: Double
        if summary1.endValue != 0 {
            let rawImprovement = ((summary2.endValue - summary1.endValue) / abs(summary1.endValue)) * 100
            improvement = metric.higherIsBetter ? rawImprovement : -rawImprovement
        } else {
            improvement = 0
        }

        // Determine significance (>10% change is significant)
        let significantDifference = abs(improvement) > 10.0

        return RangeComparison(
            metricType: metric,
            range1: range1,
            range2: range2,
            range1Summary: summary1,
            range2Summary: summary2,
            improvement: improvement,
            significantDifference: significantDifference
        )
    }

    /// Find the best performing period of a given length
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - metric: The metric type to analyze
    ///   - periodLength: Length of the period in days
    /// - Returns: The best performing date interval
    func findBestPeriod(
        patientId: UUID,
        metric: TrendMetricType,
        periodLength: Int
    ) async throws -> BestPeriod {
        // Fetch all available data
        let allDataPoints = try await fetchDataPoints(
            patientId: patientId,
            metric: metric,
            range: .allTime
        )

        guard allDataPoints.count >= periodLength else {
            throw TrendAnalysisError.insufficientData
        }

        // Sliding window to find best period
        var bestAverage: Double = metric.higherIsBetter ? Double.leastNormalMagnitude : Double.greatestFiniteMagnitude
        var bestStartIndex = 0

        for i in 0...(allDataPoints.count - periodLength) {
            let windowPoints = Array(allDataPoints[i..<(i + periodLength)])
            let average = windowPoints.map { $0.value }.reduce(0, +) / Double(windowPoints.count)

            if metric.higherIsBetter {
                if average > bestAverage {
                    bestAverage = average
                    bestStartIndex = i
                }
            } else {
                if average < bestAverage {
                    bestAverage = average
                    bestStartIndex = i
                }
            }
        }

        let bestWindowPoints = Array(allDataPoints[bestStartIndex..<(bestStartIndex + periodLength)])
        let peakValue = metric.higherIsBetter
            ? bestWindowPoints.map { $0.value }.max() ?? 0
            : bestWindowPoints.map { $0.value }.min() ?? 0
        let peakPoint = bestWindowPoints.first { $0.value == peakValue }

        return BestPeriod(
            dateInterval: DateInterval(
                start: bestWindowPoints.first?.date ?? Date(),
                end: bestWindowPoints.last?.date ?? Date()
            ),
            metricType: metric,
            averageValue: bestAverage,
            peakValue: peakValue,
            peakDate: peakPoint?.date ?? Date()
        )
    }

    /// Export trend data to CSV format
    /// - Parameter analysis: The trend analysis to export
    /// - Returns: CSV data
    func exportTrendData(analysis: TrendAnalysis) -> Data {
        var csv = "Date,Value,Moving Average\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for point in analysis.dataPoints {
            let dateStr = dateFormatter.string(from: point.date)
            let maStr = point.movingAverage.map { String(format: "%.2f", $0) } ?? ""
            csv += "\(dateStr),\(String(format: "%.2f", point.value)),\(maStr)\n"
        }

        // Add summary section
        csv += "\nSummary\n"
        csv += "Start Value,\(String(format: "%.2f", analysis.summary.startValue))\n"
        csv += "End Value,\(String(format: "%.2f", analysis.summary.endValue))\n"
        csv += "Change %,\(String(format: "%.2f", analysis.summary.percentChange))\n"
        csv += "Direction,\(analysis.summary.direction.displayName)\n"
        csv += "Volatility,\(String(format: "%.2f", analysis.summary.volatility))\n"
        csv += "Best Value,\(String(format: "%.2f", analysis.summary.bestValue))\n"
        csv += "Best Date,\(dateFormatter.string(from: analysis.summary.bestDate))\n"
        csv += "Worst Value,\(String(format: "%.2f", analysis.summary.worstValue))\n"
        csv += "Worst Date,\(dateFormatter.string(from: analysis.summary.worstDate))\n"

        return csv.data(using: .utf8) ?? Data()
    }

    /// Generate insights for a patient based on recent trends
    /// - Parameter patientId: The patient's UUID
    /// - Returns: Array of trend insights
    func generatePatientInsights(patientId: UUID) async throws -> [TrendInsight] {
        var insights: [TrendInsight] = []

        // Analyze key metrics
        let metricsToAnalyze: [TrendMetricType] = [
            .sessionAdherence,
            .painLevel,
            .workloadVolume,
            .recoveryScore
        ]

        for metric in metricsToAnalyze {
            do {
                let analysis = try await analyzeTrend(
                    patientId: patientId,
                    metric: metric,
                    range: .thirtyDays
                )

                // Generate metric-specific insights
                let metricInsights = generateMetricInsights(analysis: analysis)
                insights.append(contentsOf: metricInsights)
            } catch {
                // Skip metrics that don't have data
                continue
            }
        }

        // Sort by severity (critical first)
        return insights.sorted { insight1, insight2 in
            let order: [TrendInsight.InsightSeverity] = [.critical, .warning, .positive, .neutral]
            let index1 = order.firstIndex(of: insight1.severity) ?? 3
            let index2 = order.firstIndex(of: insight2.severity) ?? 3
            return index1 < index2
        }
    }

    /// Clear the analysis cache
    func clearCache() {
        analysisCache.removeAll()
    }

    // MARK: - Private Methods

    private func fetchDataPoints(
        patientId: UUID,
        metric: TrendMetricType,
        range: TrendTimeRange
    ) async throws -> [AnalyticsTrendDataPoint] {
        let startDate = range.startDate
        let aggregation = range.aggregationPeriod

        do {
            let response = try await supabase.client
                .rpc("get_trend_data", params: [
                    "p_patient_id": patientId.uuidString,
                    "p_metric_type": metric.rawValue,
                    "p_start_date": ISO8601DateFormatter().string(from: startDate),
                    "p_aggregation": aggregation.rawValue
                ])
                .execute()

            let rawData = try PTSupabaseClient.flexibleDecoder.decode(
                [TrendDataPointDTO].self,
                from: response.data
            )

            // Convert DTOs to domain models and calculate moving averages
            return calculateMovingAverages(for: rawData.map { dto in
                AnalyticsTrendDataPoint(
                    id: UUID(),
                    date: dto.date,
                    value: dto.value,
                    movingAverage: nil
                )
            })
        } catch {
            DebugLogger.shared.log("Failed to fetch trend data: \(error)", level: .warning)
            return []
        }
    }

    private func fetchDataPointsForInterval(
        patientId: UUID,
        metric: TrendMetricType,
        interval: DateInterval
    ) async throws -> [AnalyticsTrendDataPoint] {
        do {
            let response = try await supabase.client
                .rpc("get_trend_data_for_interval", params: [
                    "p_patient_id": patientId.uuidString,
                    "p_metric_type": metric.rawValue,
                    "p_start_date": ISO8601DateFormatter().string(from: interval.start),
                    "p_end_date": ISO8601DateFormatter().string(from: interval.end)
                ])
                .execute()

            let rawData = try PTSupabaseClient.flexibleDecoder.decode(
                [TrendDataPointDTO].self,
                from: response.data
            )

            return calculateMovingAverages(for: rawData.map { dto in
                AnalyticsTrendDataPoint(
                    id: UUID(),
                    date: dto.date,
                    value: dto.value,
                    movingAverage: nil
                )
            })
        } catch {
            errorLogger.logError(error, context: "TrendAnalysisService.fetchDataPointsForInterval")
            throw TrendAnalysisError.fetchFailed(error)
        }
    }

    private func calculateMovingAverages(for points: [AnalyticsTrendDataPoint], window: Int = 7) -> [AnalyticsTrendDataPoint] {
        guard points.count >= window else {
            return points
        }

        return points.enumerated().map { index, point in
            let startIndex = max(0, index - window + 1)
            let windowPoints = Array(points[startIndex...index])
            let average = windowPoints.map { $0.value }.reduce(0, +) / Double(windowPoints.count)

            return AnalyticsTrendDataPoint(
                id: point.id,
                date: point.date,
                value: point.value,
                movingAverage: average
            )
        }
    }

    private func calculateSummary(dataPoints: [AnalyticsTrendDataPoint], metric: TrendMetricType) -> TrendSummary {
        guard !dataPoints.isEmpty else {
            return .empty
        }

        let sortedPoints = dataPoints.sorted { $0.date < $1.date }
        let values = sortedPoints.map { $0.value }

        let startValue = values.first ?? 0
        let endValue = values.last ?? 0

        // Calculate percent change
        let percentChange: Double
        if startValue != 0 {
            percentChange = ((endValue - startValue) / abs(startValue)) * 100
        } else {
            percentChange = 0
        }

        // Calculate volatility (standard deviation)
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        let volatility = sqrt(variance)

        // Find best/worst values
        let bestValue: Double
        let worstValue: Double

        if metric.higherIsBetter {
            bestValue = values.max() ?? 0
            worstValue = values.min() ?? 0
        } else {
            bestValue = values.min() ?? 0
            worstValue = values.max() ?? 0
        }

        let bestPoint = sortedPoints.first { $0.value == bestValue }
        let worstPoint = sortedPoints.first { $0.value == worstValue }

        // Determine direction
        let direction = determineTrendDirection(
            percentChange: percentChange,
            volatility: volatility,
            higherIsBetter: metric.higherIsBetter
        )

        return TrendSummary(
            startValue: startValue,
            endValue: endValue,
            percentChange: percentChange,
            direction: direction,
            volatility: volatility,
            bestValue: bestValue,
            bestDate: bestPoint?.date ?? Date(),
            worstValue: worstValue,
            worstDate: worstPoint?.date ?? Date(),
            insights: []
        )
    }

    private func determineTrendDirection(
        percentChange: Double,
        volatility: Double,
        higherIsBetter: Bool
    ) -> TrendDirection {
        // High volatility suggests fluctuating trend
        if volatility > 20 {
            return .fluctuating
        }

        // Small change means stable
        if abs(percentChange) < 5 {
            return .stable
        }

        // Positive change
        if percentChange > 0 {
            return higherIsBetter ? .improving : .declining
        } else {
            return higherIsBetter ? .declining : .improving
        }
    }

    private func generateInsights(
        dataPoints: [AnalyticsTrendDataPoint],
        summary: TrendSummary,
        metric: TrendMetricType
    ) -> [String] {
        var insights: [String] = []

        // Trend direction insight
        switch summary.direction {
        case .improving:
            insights.append("Strong \(metric.displayName.lowercased()) improvement of \(summary.formattedPercentChange)")
        case .declining:
            insights.append("\(metric.displayName) has declined by \(String(format: "%.1f%%", abs(summary.percentChange)))")
        case .stable:
            insights.append("\(metric.displayName) has remained stable")
        case .fluctuating:
            insights.append("\(metric.displayName) has been variable - consider consistency")
        }

        // Best period insight
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        insights.append("Best \(metric.displayName.lowercased()): \(String(format: "%.1f", summary.bestValue))\(metric.unit) on \(dateFormatter.string(from: summary.bestDate))")

        // Volatility insight
        if summary.volatility > 15 {
            insights.append("High variability detected - focus on consistency")
        } else if summary.volatility < 5 {
            insights.append("Very consistent performance")
        }

        return insights
    }

    private func generateMetricInsights(analysis: TrendAnalysis) -> [TrendInsight] {
        var insights: [TrendInsight] = []
        let summary = analysis.summary

        // Check for significant improvement
        if summary.direction == .improving && summary.percentChange > 15 {
            insights.append(TrendInsight(
                id: UUID(),
                type: .milestone,
                title: "Great Progress!",
                message: "Your \(analysis.metricType.displayName.lowercased()) has improved by \(summary.formattedPercentChange) this month",
                severity: .positive,
                metricType: analysis.metricType,
                relatedDate: Date(),
                actionable: false,
                recommendation: nil
            ))
        }

        // Check for concerning decline
        if summary.direction == .declining && abs(summary.percentChange) > 10 {
            let recommendation = generateRecommendation(for: analysis.metricType, direction: .declining)
            insights.append(TrendInsight(
                id: UUID(),
                type: .warning,
                title: "Needs Attention",
                message: "Your \(analysis.metricType.displayName.lowercased()) has declined by \(String(format: "%.1f%%", abs(summary.percentChange)))",
                severity: .warning,
                metricType: analysis.metricType,
                relatedDate: Date(),
                actionable: true,
                recommendation: recommendation
            ))
        }

        // Check if near personal best
        let currentValue = analysis.dataPoints.last?.value ?? 0
        if analysis.metricType.higherIsBetter && currentValue >= summary.bestValue * 0.95 {
            insights.append(TrendInsight(
                id: UUID(),
                type: .personalRecord,
                title: "Near Personal Best!",
                message: "You're within 5% of your best \(analysis.metricType.displayName.lowercased()) ever",
                severity: .positive,
                metricType: analysis.metricType,
                relatedDate: Date(),
                actionable: false,
                recommendation: nil
            ))
        }

        return insights
    }

    private func generateRecommendation(for metric: TrendMetricType, direction: TrendDirection) -> String {
        switch metric {
        case .sessionAdherence:
            return "Try scheduling workouts at consistent times to build a routine"
        case .painLevel:
            return direction == .declining
                ? "Great job managing pain levels!"
                : "Consider adjusting workout intensity or consulting your therapist"
        case .recoveryScore:
            return "Focus on sleep quality and active recovery days"
        case .sleepQuality:
            return "Try maintaining a consistent sleep schedule"
        case .workloadVolume:
            return "Gradual progression is key - avoid sudden increases"
        case .strengthProgress:
            return "Ensure adequate protein intake and recovery time"
        case .mobilityScore:
            return "Include daily stretching and mobility work"
        }
    }

}

// MARK: - Data Transfer Objects

private struct TrendDataPointDTO: Codable {
    let date: Date
    let value: Double

    enum CodingKeys: String, CodingKey {
        case date = "data_date"
        case value = "metric_value"
    }
}

// MARK: - Errors

enum TrendAnalysisError: LocalizedError {
    case fetchFailed(Error)
    case insufficientData
    case invalidMetricType
    case invalidDateRange

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Failed to fetch trend data"
        case .insufficientData:
            return "Not enough data for analysis"
        case .invalidMetricType:
            return "Invalid metric type"
        case .invalidDateRange:
            return "Invalid date range"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .fetchFailed:
            return "Check your connection and try again"
        case .insufficientData:
            return "Continue tracking to see trends"
        case .invalidMetricType:
            return "Select a different metric"
        case .invalidDateRange:
            return "Select a valid date range"
        }
    }
}
