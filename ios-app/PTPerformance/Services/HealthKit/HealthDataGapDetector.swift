//
//  HealthDataGapDetector.swift
//  PTPerformance
//
//  ACP-1037: HealthKit Sync Reliability - Data Gap Detection
//  Detects and handles missing data points in HealthKit sync
//

import Foundation
import HealthKit

// MARK: - Data Gap Types

/// Represents a gap in health data collection
struct HealthDataGap: Identifiable, Equatable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    let dataType: HealthDataType
    let severity: GapSeverity

    enum GapSeverity: String {
        case minor = "Minor"      // 1-2 days missing
        case moderate = "Moderate" // 3-7 days missing
        case major = "Major"       // 8+ days missing

        var color: String {
            switch self {
            case .minor: return "yellow"
            case .moderate: return "orange"
            case .major: return "red"
            }
        }
    }

    /// Duration of the gap in days
    var durationInDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }

    /// Duration of the gap in hours
    var durationInHours: Int {
        Calendar.current.dateComponents([.hour], from: startDate, to: endDate).hour ?? 0
    }
}

// MARK: - Gap Fill Strategy

/// Strategy for filling data gaps
enum GapFillStrategy {
    /// Mark as "no data" explicitly
    case markAsNoData
    /// Interpolate between surrounding values
    case interpolate
    /// Use average of previous week
    case useWeeklyAverage
    /// Leave gap unfilled
    case leaveUnfilled
}

// MARK: - Health Data Gap Detector

/// Service for detecting and analyzing gaps in HealthKit data
@MainActor
class HealthDataGapDetector: ObservableObject {

    // MARK: - Singleton

    static let shared = HealthDataGapDetector()

    // MARK: - Published State

    @Published var detectedGaps: [HealthDataGap] = []
    @Published var filledGaps: [HealthDataGap] = []

    // MARK: - Private Properties

    private let logger = DebugLogger.shared
    private let healthKitService = HealthKitService.shared

    // MARK: - Gap Detection Thresholds

    private struct GapThresholds {
        static let minorGapDays = 2
        static let moderateGapDays = 7
        static let majorGapDays = 14
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Gap Detection

    /// Detect data gaps in a date range for a specific data type
    /// - Parameters:
    ///   - startDate: Start of the range to check
    ///   - endDate: End of the range to check
    ///   - dataType: Type of health data to check
    /// - Returns: Array of detected gaps
    func detectGaps(from startDate: Date, to endDate: Date, for dataType: HealthDataType) async -> [HealthDataGap] {
        logger.log("[HealthDataGapDetector] Detecting gaps for \(dataType.rawValue) from \(startDate) to \(endDate)", level: .diagnostic)

        var gaps: [HealthDataGap] = []
        var currentGapStart: Date?
        let calendar = Calendar.current

        // Iterate through each day in the range
        var currentDate = startDate
        while currentDate <= endDate {
            let hasData = await checkForData(on: currentDate, dataType: dataType)

            if !hasData {
                // Start of a new gap or continuation
                if currentGapStart == nil {
                    currentGapStart = currentDate
                }
            } else {
                // End of a gap (if one was in progress)
                if let gapStart = currentGapStart {
                    let gap = createGap(from: gapStart, to: currentDate, dataType: dataType)
                    gaps.append(gap)
                    currentGapStart = nil
                }
            }

            // Move to next day
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        // Handle gap that extends to endDate
        if let gapStart = currentGapStart {
            let gap = createGap(from: gapStart, to: endDate, dataType: dataType)
            gaps.append(gap)
        }

        detectedGaps = gaps
        logger.log("[HealthDataGapDetector] Detected \(gaps.count) gaps for \(dataType.rawValue)", level: gaps.isEmpty ? .success : .warning)

        return gaps
    }

    /// Detect gaps across all data types for a date range
    /// - Parameters:
    ///   - startDate: Start of the range to check
    ///   - endDate: End of the range to check
    /// - Returns: Dictionary mapping data types to their gaps
    func detectAllGaps(from startDate: Date, to endDate: Date) async -> [HealthDataType: [HealthDataGap]] {
        var allGaps: [HealthDataType: [HealthDataGap]] = [:]

        for dataType in [HealthDataType.hrv, .restingHeartRate, .sleep, .steps] {
            let gaps = await detectGaps(from: startDate, to: endDate, for: dataType)
            if !gaps.isEmpty {
                allGaps[dataType] = gaps
            }
        }

        let totalGaps = allGaps.values.reduce(0) { $0 + $1.count }
        logger.log("[HealthDataGapDetector] Total gaps detected: \(totalGaps)", level: totalGaps == 0 ? .success : .warning)

        return allGaps
    }

    // MARK: - Gap Filling

    /// Fill a data gap using the specified strategy
    /// - Parameters:
    ///   - gap: The gap to fill
    ///   - strategy: Strategy to use for filling
    /// - Returns: Success boolean
    func fillGap(_ gap: HealthDataGap, strategy: GapFillStrategy) async -> Bool {
        logger.log("[HealthDataGapDetector] Filling gap for \(gap.dataType.rawValue) using \(strategy)", level: .diagnostic)

        switch strategy {
        case .markAsNoData:
            return await markGapAsNoData(gap)

        case .interpolate:
            return await interpolateGap(gap)

        case .useWeeklyAverage:
            return await fillGapWithWeeklyAverage(gap)

        case .leaveUnfilled:
            logger.log("[HealthDataGapDetector] Gap left unfilled as requested", level: .diagnostic)
            return true
        }
    }

    // MARK: - Private Helper Methods

    /// Check if data exists for a specific date and data type
    private func checkForData(on date: Date, dataType: HealthDataType) async -> Bool {
        switch dataType {
        case .hrv:
            let hrv = try? await healthKitService.fetchHRV(for: date)
            return hrv != nil

        case .restingHeartRate:
            let rhr = try? await healthKitService.fetchRestingHeartRate(for: date)
            return rhr != nil

        case .sleep:
            let sleep = try? await healthKitService.fetchSleepData(for: date)
            return sleep != nil

        case .steps:
            let steps = try? await healthKitService.fetchSteps(for: date)
            return (steps ?? 0) > 0

        case .activeEnergy, .mood, .perceivedExertion, .bodyWeight:
            // Not implemented for these types yet
            return true
        }
    }

    /// Create a HealthDataGap from date range
    private func createGap(from startDate: Date, to endDate: Date, dataType: HealthDataType) -> HealthDataGap {
        let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0

        let severity: HealthDataGap.GapSeverity
        if days >= GapThresholds.majorGapDays {
            severity = .major
        } else if days >= GapThresholds.moderateGapDays {
            severity = .moderate
        } else {
            severity = .minor
        }

        return HealthDataGap(
            startDate: startDate,
            endDate: endDate,
            dataType: dataType,
            severity: severity
        )
    }

    /// Mark a gap as explicitly "no data" in the database
    private func markGapAsNoData(_ gap: HealthDataGap) async -> Bool {
        // In a real implementation, this would insert "no data" markers into the database
        // For now, just log it
        logger.log("[HealthDataGapDetector] Marked gap as 'no data': \(gap.dataType.rawValue) from \(gap.startDate) to \(gap.endDate)", level: .diagnostic)
        filledGaps.append(gap)
        return true
    }

    /// Fill a gap using linear interpolation between surrounding values
    private func interpolateGap(_ gap: HealthDataGap) async -> Bool {
        logger.log("[HealthDataGapDetector] Interpolating gap for \(gap.dataType.rawValue)", level: .diagnostic)

        // Get values before and after gap
        let calendar = Calendar.current
        guard let dayBefore = calendar.date(byAdding: .day, value: -1, to: gap.startDate),
              let dayAfter = calendar.date(byAdding: .day, value: 1, to: gap.endDate) else {
            return false
        }

        let valueBefore = await getValueForDate(dayBefore, dataType: gap.dataType)
        let valueAfter = await getValueForDate(dayAfter, dataType: gap.dataType)

        guard let before = valueBefore, let after = valueAfter else {
            logger.log("[HealthDataGapDetector] Cannot interpolate: missing surrounding values", level: .warning)
            return false
        }

        // Calculate interpolated values for each day in the gap
        let gapDays = gap.durationInDays
        guard gapDays > 0 else { return false }

        for dayOffset in 0..<gapDays {
            let interpolationFactor = Double(dayOffset + 1) / Double(gapDays + 1)
            let interpolatedValue = before + (after - before) * interpolationFactor

            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: gap.startDate) else {
                continue
            }

            // In a real implementation, this would save the interpolated value
            logger.log("[HealthDataGapDetector] Interpolated value for \(targetDate): \(interpolatedValue)", level: .diagnostic)
        }

        filledGaps.append(gap)
        return true
    }

    /// Fill a gap using the average of the previous week
    private func fillGapWithWeeklyAverage(_ gap: HealthDataGap) async -> Bool {
        logger.log("[HealthDataGapDetector] Filling gap with weekly average for \(gap.dataType.rawValue)", level: .diagnostic)

        let calendar = Calendar.current
        guard let weekBefore = calendar.date(byAdding: .day, value: -7, to: gap.startDate) else {
            return false
        }

        // Calculate average from the week before the gap
        var values: [Double] = []
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekBefore),
                  let value = await getValueForDate(date, dataType: gap.dataType) else {
                continue
            }
            values.append(value)
        }

        guard !values.isEmpty else {
            logger.log("[HealthDataGapDetector] No data available for weekly average", level: .warning)
            return false
        }

        let average = values.reduce(0, +) / Double(values.count)
        logger.log("[HealthDataGapDetector] Weekly average: \(average)", level: .diagnostic)

        // In a real implementation, this would fill each day with the average
        filledGaps.append(gap)
        return true
    }

    /// Get numeric value for a specific date and data type
    private func getValueForDate(_ date: Date, dataType: HealthDataType) async -> Double? {
        switch dataType {
        case .hrv:
            return try? await healthKitService.fetchHRV(for: date)

        case .restingHeartRate:
            return try? await healthKitService.fetchRestingHeartRate(for: date)

        case .sleep:
            if let sleep = try? await healthKitService.fetchSleepData(for: date) {
                return Double(sleep.totalMinutes)
            }
            return nil

        case .steps:
            return try? await healthKitService.fetchSteps(for: date)

        case .activeEnergy, .mood, .perceivedExertion, .bodyWeight:
            return nil
        }
    }

    // MARK: - Gap Statistics

    /// Get statistics about detected gaps
    func getGapStatistics() -> (total: Int, byType: [HealthDataType: Int], bySeverity: [HealthDataGap.GapSeverity: Int]) {
        let total = detectedGaps.count

        var byType: [HealthDataType: Int] = [:]
        var bySeverity: [HealthDataGap.GapSeverity: Int] = [:]

        for gap in detectedGaps {
            byType[gap.dataType, default: 0] += 1
            bySeverity[gap.severity, default: 0] += 1
        }

        return (total: total, byType: byType, bySeverity: bySeverity)
    }

    /// Clear all detected gaps
    func clearDetectedGaps() {
        detectedGaps.removeAll()
        logger.log("[HealthDataGapDetector] Cleared detected gaps", level: .diagnostic)
    }
}
