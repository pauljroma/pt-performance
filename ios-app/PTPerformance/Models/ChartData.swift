//
//  ChartData.swift
//  PTPerformance
//
//  Created by Build 46 Swarm Agent 3
//  Data models for analytics charts
//

import Foundation

// MARK: - Volume Data

/// Data point for volume chart (total weight lifted over time)
struct VolumeDataPoint: Identifiable, Hashable {
    let date: Date
    let totalVolume: Double // Total weight in pounds
    let sessionCount: Int

    var id: String { "\(date.timeIntervalSince1970)-\(totalVolume)" }

    var volumeInKg: Double {
        totalVolume * 0.453592
    }

    var formattedVolume: String {
        String(format: "%.0f lbs", totalVolume)
    }
}

/// Aggregated volume data for a time period
struct VolumeChartData {
    let dataPoints: [VolumeDataPoint]
    let period: TimePeriod
    let totalVolume: Double
    let averageVolume: Double
    let peakVolume: Double
    let peakDate: Date?

    var formattedTotal: String {
        String(format: "%.0f lbs", totalVolume)
    }

    var formattedAverage: String {
        String(format: "%.0f lbs/week", averageVolume)
    }
}

// MARK: - Strength Data

/// Data point for strength progression chart
struct StrengthDataPoint: Identifiable, Hashable {
    let date: Date
    let exerciseName: String
    let weight: Double
    let reps: Int
    let estimatedOneRepMax: Double

    var id: String { "\(date.timeIntervalSince1970)-\(exerciseName)-\(weight)" }

    var formattedWeight: String {
        String(format: "%.1f lbs", weight)
    }

    var formattedOneRepMax: String {
        String(format: "%.1f lbs", estimatedOneRepMax)
    }
}

/// Strength progression data for a specific exercise
struct StrengthChartData {
    let exerciseId: String
    let exerciseName: String
    let dataPoints: [StrengthDataPoint]
    let period: TimePeriod
    let currentMax: Double
    let startingMax: Double
    let improvement: Double // Percentage improvement

    var improvementPercentage: String {
        String(format: "%.1f%%", improvement * 100)
    }

    var formattedCurrentMax: String {
        String(format: "%.1f lbs", currentMax)
    }
}

// MARK: - Consistency Data

/// Data point for workout consistency chart
struct ConsistencyDataPoint: Identifiable, Hashable {
    let weekStart: Date
    let weekEnd: Date
    let scheduledSessions: Int
    let completedSessions: Int
    let completionRate: Double

    var id: String { "\(weekStart.timeIntervalSince1970)-\(weekEnd.timeIntervalSince1970)" }

    var weekLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: weekStart)
    }

    var formattedCompletionRate: String {
        String(format: "%.0f%%", completionRate * 100)
    }

    var isGoodWeek: Bool {
        completionRate >= 0.8
    }
}

/// Overall consistency metrics
struct ConsistencyChartData {
    let dataPoints: [ConsistencyDataPoint]
    let period: TimePeriod
    let totalScheduled: Int
    let totalCompleted: Int
    let overallCompletionRate: Double
    let currentStreak: Int // Consecutive weeks with ≥80% completion
    let longestStreak: Int

    var formattedCompletionRate: String {
        String(format: "%.0f%%", overallCompletionRate * 100)
    }
}

// MARK: - Personal Records

/// Personal record achievement
struct PersonalRecord: Identifiable, Hashable {
    let exerciseId: String
    let exerciseName: String
    let recordType: RecordType
    let value: Double
    let achievedDate: Date
    let previousRecord: Double?

    var id: String { "\(exerciseId)-\(recordType.rawValue)-\(achievedDate.timeIntervalSince1970)" }

    enum RecordType: String, Codable {
        case maxWeight = "max_weight"
        case maxVolume = "max_volume"
        case maxReps = "max_reps"
        case estimatedOneRepMax = "estimated_1rm"

        var displayName: String {
            switch self {
            case .maxWeight: return "Max Weight"
            case .maxVolume: return "Max Volume"
            case .maxReps: return "Max Reps"
            case .estimatedOneRepMax: return "Estimated 1RM"
            }
        }
    }

    var formattedValue: String {
        switch recordType {
        case .maxWeight, .estimatedOneRepMax:
            return String(format: "%.1f lbs", value)
        case .maxVolume:
            return String(format: "%.0f lbs", value)
        case .maxReps:
            return String(format: "%.0f reps", value)
        }
    }

    var improvement: Double? {
        guard let previous = previousRecord, previous > 0 else { return nil }
        return ((value - previous) / previous)
    }

    var formattedImprovement: String? {
        guard let improvement = improvement else { return nil }
        return String(format: "+%.1f%%", improvement * 100)
    }
}

// MARK: - Exercise Trends

/// Trend data for a specific exercise
struct ExerciseTrend: Identifiable {
    let exerciseId: String
    let exerciseName: String
    let dataPoints: [ExerciseDataPoint]
    let period: TimePeriod
    let trend: TrendDirection
    let averageWeight: Double
    let totalVolume: Double
    let sessionCount: Int

    var id: String { exerciseId }

    /// Use the canonical top-level TrendDirection enum
    typealias TrendDirection = PTPerformance.TrendDirection
}

/// Individual data point for exercise trend
struct ExerciseDataPoint: Identifiable, Hashable {
    let date: Date
    let weight: Double
    let reps: Int
    let sets: Int
    let volume: Double

    var id: String { "\(date.timeIntervalSince1970)-\(weight)-\(reps)-\(sets)" }
}

// MARK: - Body Metrics (Optional)

/// Body measurement data point
struct BodyMetricDataPoint: Identifiable, Hashable {
    let date: Date
    let metricType: BodyMetricType
    let value: Double
    let unit: String

    var id: String { "\(date.timeIntervalSince1970)-\(metricType.rawValue)-\(value)" }

    enum BodyMetricType: String, Codable, CaseIterable {
        case weight
        case bodyFat = "body_fat"
        case muscleMass = "muscle_mass"
        case waist
        case chest
        case arms
        case legs

        var displayName: String {
            switch self {
            case .weight: return "Weight"
            case .bodyFat: return "Body Fat %"
            case .muscleMass: return "Muscle Mass"
            case .waist: return "Waist"
            case .chest: return "Chest"
            case .arms: return "Arms"
            case .legs: return "Legs"
            }
        }

        var defaultUnit: String {
            switch self {
            case .weight: return "lbs"
            case .bodyFat: return "%"
            case .muscleMass: return "lbs"
            case .waist, .chest, .arms, .legs: return "inches"
            }
        }
    }

    var formattedValue: String {
        if metricType == .bodyFat {
            return String(format: "%.1f%@", value, unit)
        } else {
            return String(format: "%.1f %@", value, unit)
        }
    }
}

// MARK: - Time Period

/// Time period for analytics queries
enum TimePeriod: String, CaseIterable, Codable {
    case week = "7d"
    case month = "30d"
    case threeMonths = "90d"
    case sixMonths = "180d"
    case year = "365d"
    case allTime = "all"

    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .threeMonths: return "3 Months"
        case .sixMonths: return "6 Months"
        case .year: return "Year"
        case .allTime: return "All Time"
        }
    }

    var days: Int? {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .sixMonths: return 180
        case .year: return 365
        case .allTime: return nil
        }
    }

    var startDate: Date {
        guard let days = days else {
            // Return a very old date for "all time"
            return Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date()
        }
        return Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
    }
}

// MARK: - Dashboard Summary

/// Overall analytics summary for dashboard
struct AnalyticsSummary {
    let period: TimePeriod
    let totalVolume: Double
    let totalSessions: Int
    let averageSessionDuration: Int // Minutes
    let completionRate: Double
    let personalRecords: [PersonalRecord]
    let topExercises: [ExerciseTrend]
    let currentStreak: Int

    var formattedTotalVolume: String {
        if totalVolume >= 1000 {
            return String(format: "%.1fK lbs", totalVolume / 1000)
        } else {
            return String(format: "%.0f lbs", totalVolume)
        }
    }

    var formattedCompletionRate: String {
        String(format: "%.0f%%", completionRate * 100)
    }

    var recentPRs: [PersonalRecord] {
        Array(personalRecords.prefix(5))
    }
}

// MARK: - Sample Data

extension VolumeDataPoint {
    static var sample: VolumeDataPoint {
        VolumeDataPoint(
            date: Date(),
            totalVolume: 12500,
            sessionCount: 4
        )
    }
}

extension StrengthDataPoint {
    static var sample: StrengthDataPoint {
        StrengthDataPoint(
            date: Date(),
            exerciseName: "Squat",
            weight: 225,
            reps: 5,
            estimatedOneRepMax: 253
        )
    }
}

extension ConsistencyDataPoint {
    static var sample: ConsistencyDataPoint {
        ConsistencyDataPoint(
            weekStart: Date(),
            weekEnd: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
            scheduledSessions: 4,
            completedSessions: 3,
            completionRate: 0.75
        )
    }
}

extension PersonalRecord {
    static var sample: PersonalRecord {
        PersonalRecord(
            exerciseId: UUID().uuidString,
            exerciseName: "Bench Press",
            recordType: .maxWeight,
            value: 225,
            achievedDate: Date(),
            previousRecord: 205
        )
    }
}
