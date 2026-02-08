//
//  TrendAnalysis.swift
//  PTPerformance
//
//  Created for M8 - Historical Trend Analysis Feature
//  Data models for long-term performance tracking with 30/90/180 day views
//

import Foundation
import SwiftUI

// MARK: - Trend Analysis

/// Main trend analysis result containing data points and summary statistics
struct TrendAnalysis: Identifiable, Codable {
    let id: UUID
    let patientId: UUID
    let metricType: TrendMetricType
    let timeRange: TrendTimeRange
    let dataPoints: [AnalyticsTrendDataPoint]
    let summary: TrendSummary
    let generatedAt: Date

    init(
        id: UUID = UUID(),
        patientId: UUID,
        metricType: TrendMetricType,
        timeRange: TrendTimeRange,
        dataPoints: [AnalyticsTrendDataPoint],
        summary: TrendSummary,
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.patientId = patientId
        self.metricType = metricType
        self.timeRange = timeRange
        self.dataPoints = dataPoints
        self.summary = summary
        self.generatedAt = generatedAt
    }

    /// Whether this analysis has sufficient data for meaningful insights
    var hasSignificantData: Bool {
        dataPoints.count >= 5
    }

    /// Date range covered by data points
    var dateRange: DateInterval? {
        guard let first = dataPoints.first?.date,
              let last = dataPoints.last?.date else { return nil }
        return DateInterval(start: min(first, last), end: max(first, last))
    }
}

// MARK: - Trend Data Point

/// Individual data point in a trend with optional moving average
struct AnalyticsTrendDataPoint: Codable, Identifiable, Hashable {
    let id: UUID
    let date: Date
    let value: Double
    let movingAverage: Double?

    init(id: UUID = UUID(), date: Date, value: Double, movingAverage: Double? = nil) {
        self.id = id
        self.date = date
        self.value = value
        self.movingAverage = movingAverage
    }

    /// Formatted value for display
    func formattedValue(for metricType: TrendMetricType) -> String {
        switch metricType {
        case .sessionAdherence:
            return String(format: "%.0f%%", value)
        case .painLevel:
            return String(format: "%.1f", value)
        case .recoveryScore:
            return String(format: "%.0f", value)
        case .sleepQuality:
            return String(format: "%.1f hrs", value)
        case .workloadVolume:
            if value >= 1000 {
                return String(format: "%.1fK", value / 1000)
            }
            return String(format: "%.0f", value)
        case .strengthProgress:
            return String(format: "%.0f lbs", value)
        case .mobilityScore:
            return String(format: "%.0f%%", value)
        }
    }
}

// MARK: - Trend Summary

/// Statistical summary of trend analysis
struct TrendSummary: Codable {
    let startValue: Double
    let endValue: Double
    let percentChange: Double
    let direction: TrendDirection
    let volatility: Double  // Standard deviation
    let bestValue: Double
    let bestDate: Date
    let worstValue: Double
    let worstDate: Date
    let insights: [String]

    /// Formatted percentage change with sign
    var formattedPercentChange: String {
        let sign = percentChange >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, percentChange)
    }

    /// Whether the change is considered significant (>5%)
    var isSignificant: Bool {
        abs(percentChange) > 5.0
    }

    /// Color representing the trend direction
    var trendColor: Color {
        switch direction {
        case .improving:
            return .green
        case .declining:
            return .red
        case .stable:
            return .blue
        case .fluctuating:
            return .orange
        }
    }

    /// Creates an empty summary for when there's no data
    static var empty: TrendSummary {
        TrendSummary(
            startValue: 0,
            endValue: 0,
            percentChange: 0,
            direction: .stable,
            volatility: 0,
            bestValue: 0,
            bestDate: Date(),
            worstValue: 0,
            worstDate: Date(),
            insights: []
        )
    }
}

// MARK: - Trend Direction

/// Direction/pattern of a trend over time
enum TrendDirection: String, Codable, CaseIterable, Sendable {
    case improving = "improving"
    case declining = "declining"
    case stable = "stable"
    case fluctuating = "fluctuating"

    var displayName: String {
        switch self {
        case .improving:
            return "Improving"
        case .declining:
            return "Declining"
        case .stable:
            return "Stable"
        case .fluctuating:
            return "Fluctuating"
        }
    }

    var icon: String {
        switch self {
        case .improving:
            return "arrow.up.right"
        case .declining:
            return "arrow.down.right"
        case .stable:
            return "arrow.right"
        case .fluctuating:
            return "waveform.path"
        }
    }

    /// Alias for icon property (for compatibility)
    var iconName: String { icon }

    var color: Color {
        switch self {
        case .improving:
            return .green
        case .declining:
            return .red
        case .stable:
            return .blue
        case .fluctuating:
            return .orange
        }
    }

    /// Accessibility label for VoiceOver
    var accessibilityLabel: String {
        switch self {
        case .improving:
            return "Trend improving"
        case .declining:
            return "Trend declining"
        case .stable:
            return "Trend stable"
        case .fluctuating:
            return "Trend fluctuating"
        }
    }
}

// MARK: - Trend Metric Type

/// Types of metrics that can be tracked over time
enum TrendMetricType: String, Codable, CaseIterable, Identifiable {
    case sessionAdherence = "adherence"
    case painLevel = "pain"
    case recoveryScore = "recovery"
    case sleepQuality = "sleep"
    case workloadVolume = "volume"
    case strengthProgress = "strength"
    case mobilityScore = "mobility"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sessionAdherence:
            return "Session Adherence"
        case .painLevel:
            return "Pain Level"
        case .recoveryScore:
            return "Recovery Score"
        case .sleepQuality:
            return "Sleep Quality"
        case .workloadVolume:
            return "Training Volume"
        case .strengthProgress:
            return "Strength Progress"
        case .mobilityScore:
            return "Mobility Score"
        }
    }

    var unit: String {
        switch self {
        case .sessionAdherence:
            return "%"
        case .painLevel:
            return "/10"
        case .recoveryScore:
            return "pts"
        case .sleepQuality:
            return "hrs"
        case .workloadVolume:
            return "lbs"
        case .strengthProgress:
            return "lbs"
        case .mobilityScore:
            return "%"
        }
    }

    var icon: String {
        switch self {
        case .sessionAdherence:
            return "checkmark.circle.fill"
        case .painLevel:
            return "heart.slash.fill"
        case .recoveryScore:
            return "battery.100.bolt"
        case .sleepQuality:
            return "moon.zzz.fill"
        case .workloadVolume:
            return "scalemass.fill"
        case .strengthProgress:
            return "figure.strengthtraining.traditional"
        case .mobilityScore:
            return "figure.flexibility"
        }
    }

    var color: Color {
        switch self {
        case .sessionAdherence:
            return .green
        case .painLevel:
            return .red
        case .recoveryScore:
            return .cyan
        case .sleepQuality:
            return .purple
        case .workloadVolume:
            return .blue
        case .strengthProgress:
            return .orange
        case .mobilityScore:
            return .teal
        }
    }

    /// Whether higher values are better for this metric
    var higherIsBetter: Bool {
        switch self {
        case .sessionAdherence, .recoveryScore, .sleepQuality, .workloadVolume, .strengthProgress, .mobilityScore:
            return true
        case .painLevel:
            return false
        }
    }

    /// Typical range for this metric
    var typicalRange: ClosedRange<Double> {
        switch self {
        case .sessionAdherence:
            return 0...100
        case .painLevel:
            return 0...10
        case .recoveryScore:
            return 0...100
        case .sleepQuality:
            return 0...12
        case .workloadVolume:
            return 0...100000
        case .strengthProgress:
            return 0...1000
        case .mobilityScore:
            return 0...100
        }
    }
}

// MARK: - Trend Time Range

/// Time ranges for trend analysis
enum TrendTimeRange: String, Codable, CaseIterable, Identifiable {
    case thirtyDays = "30d"
    case ninetyDays = "90d"
    case oneEightyDays = "180d"
    case oneYear = "1y"
    case allTime = "all"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .thirtyDays:
            return "30 Days"
        case .ninetyDays:
            return "90 Days"
        case .oneEightyDays:
            return "180 Days"
        case .oneYear:
            return "1 Year"
        case .allTime:
            return "All Time"
        }
    }

    var shortName: String {
        switch self {
        case .thirtyDays:
            return "30D"
        case .ninetyDays:
            return "90D"
        case .oneEightyDays:
            return "180D"
        case .oneYear:
            return "1Y"
        case .allTime:
            return "All"
        }
    }

    var days: Int {
        switch self {
        case .thirtyDays:
            return 30
        case .ninetyDays:
            return 90
        case .oneEightyDays:
            return 180
        case .oneYear:
            return 365
        case .allTime:
            return 3650  // ~10 years for practical purposes
        }
    }

    var startDate: Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
    }

    /// Recommended aggregation period for this range
    var aggregationPeriod: AggregationPeriod {
        switch self {
        case .thirtyDays:
            return .daily
        case .ninetyDays:
            return .weekly
        case .oneEightyDays:
            return .weekly
        case .oneYear:
            return .monthly
        case .allTime:
            return .monthly
        }
    }
}

// MARK: - Aggregation Period

/// How data should be aggregated for display
enum AggregationPeriod: String, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"

    var displayName: String {
        switch self {
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        case .monthly:
            return "Monthly"
        }
    }
}

// MARK: - Range Comparison

/// Comparison between two time ranges
struct RangeComparison: Codable, Identifiable {
    let id: UUID
    let metricType: TrendMetricType
    let range1: DateInterval
    let range2: DateInterval
    let range1Summary: TrendSummary
    let range2Summary: TrendSummary
    let improvement: Double
    let significantDifference: Bool

    init(
        id: UUID = UUID(),
        metricType: TrendMetricType,
        range1: DateInterval,
        range2: DateInterval,
        range1Summary: TrendSummary,
        range2Summary: TrendSummary,
        improvement: Double,
        significantDifference: Bool
    ) {
        self.id = id
        self.metricType = metricType
        self.range1 = range1
        self.range2 = range2
        self.range1Summary = range1Summary
        self.range2Summary = range2Summary
        self.improvement = improvement
        self.significantDifference = significantDifference
    }

    /// Formatted improvement percentage
    var formattedImprovement: String {
        let sign = improvement >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, improvement)
    }

    /// Insight message based on comparison
    var comparisonInsight: String {
        if !significantDifference {
            return "No significant change between the two periods"
        }

        let direction = improvement > 0 ? "improved" : "declined"
        return "Performance \(direction) by \(String(format: "%.1f%%", abs(improvement))) between periods"
    }
}

// MARK: - Best Period

/// Represents the best performing period of a given length
struct BestPeriod: Codable, Identifiable {
    let id: UUID
    let dateInterval: DateInterval
    let metricType: TrendMetricType
    let averageValue: Double
    let peakValue: Double
    let peakDate: Date

    init(
        id: UUID = UUID(),
        dateInterval: DateInterval,
        metricType: TrendMetricType,
        averageValue: Double,
        peakValue: Double,
        peakDate: Date
    ) {
        self.id = id
        self.dateInterval = dateInterval
        self.metricType = metricType
        self.averageValue = averageValue
        self.peakValue = peakValue
        self.peakDate = peakDate
    }

    var dateRangeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: dateInterval.start)) - \(formatter.string(from: dateInterval.end))"
    }
}

// MARK: - Trend Insight

/// AI-generated or rule-based insight about a trend
struct TrendInsight: Identifiable, Codable {
    let id: UUID
    let type: InsightType
    let title: String
    let message: String
    let severity: InsightSeverity
    let metricType: TrendMetricType?
    let relatedDate: Date?
    let actionable: Bool
    let recommendation: String?

    enum InsightType: String, Codable {
        case bestEver = "best_ever"
        case personalRecord = "personal_record"
        case warning = "warning"
        case pattern = "pattern"
        case recommendation = "recommendation"
        case milestone = "milestone"
        case recovery = "recovery"
    }

    enum InsightSeverity: String, Codable {
        case positive
        case neutral
        case warning
        case critical

        var color: Color {
            switch self {
            case .positive:
                return .green
            case .neutral:
                return .blue
            case .warning:
                return .orange
            case .critical:
                return .red
            }
        }

        var icon: String {
            switch self {
            case .positive:
                return "star.fill"
            case .neutral:
                return "info.circle.fill"
            case .warning:
                return "exclamationmark.triangle.fill"
            case .critical:
                return "exclamationmark.octagon.fill"
            }
        }
    }
}

// MARK: - Sample Data

#if DEBUG
extension TrendAnalysis {
    static var sample: TrendAnalysis {
        let dataPoints = (0..<30).map { day in
            AnalyticsTrendDataPoint(
                date: Calendar.current.date(byAdding: .day, value: -29 + day, to: Date())!,
                value: 70 + Double.random(in: -10...20),
                movingAverage: 75 + Double(day) * 0.3
            )
        }

        return TrendAnalysis(
            patientId: UUID(),
            metricType: .sessionAdherence,
            timeRange: .thirtyDays,
            dataPoints: dataPoints,
            summary: TrendSummary(
                startValue: 68,
                endValue: 85,
                percentChange: 25,
                direction: .improving,
                volatility: 8.5,
                bestValue: 95,
                bestDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
                worstValue: 55,
                worstDate: Calendar.current.date(byAdding: .day, value: -20, to: Date())!,
                insights: [
                    "Strong upward trend in adherence",
                    "Best week was 5 days ago",
                    "Consider maintaining current routine"
                ]
            )
        )
    }
}

extension AnalyticsTrendDataPoint {
    static var sample: AnalyticsTrendDataPoint {
        AnalyticsTrendDataPoint(
            date: Date(),
            value: 82.5,
            movingAverage: 78.0
        )
    }
}

extension TrendInsight {
    static var samplePositive: TrendInsight {
        TrendInsight(
            id: UUID(),
            type: .bestEver,
            title: "Best Week Ever!",
            message: "Your adherence rate hit 95% this week - your highest ever!",
            severity: .positive,
            metricType: .sessionAdherence,
            relatedDate: Date(),
            actionable: false,
            recommendation: nil
        )
    }

    static var sampleWarning: TrendInsight {
        TrendInsight(
            id: UUID(),
            type: .warning,
            title: "Pain Level Increasing",
            message: "Your average pain level has increased 20% over the past 2 weeks",
            severity: .warning,
            metricType: .painLevel,
            relatedDate: Date(),
            actionable: true,
            recommendation: "Consider reducing workout intensity or consulting with your therapist"
        )
    }
}
#endif
