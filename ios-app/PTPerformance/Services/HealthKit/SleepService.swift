import Foundation
import HealthKit

// MARK: - Sleep Service

/// Focused service for sleep data fetching from HealthKit
/// Handles sleep analysis including stages (deep, REM, core, awake)
@MainActor
class SleepService {

    // MARK: - Properties

    private let healthStore: HKHealthStore

    /// Sleep category type for HealthKit queries
    private var sleepType: HKCategoryType? {
        HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)
    }

    // MARK: - Initialization

    /// Initialize with a HealthKit store
    /// - Parameter healthStore: The HKHealthStore to use for queries
    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }

    // MARK: - Public Methods

    /// Fetch sleep data for a specific date (previous night's sleep)
    /// - Parameter date: The date to fetch sleep for (looks at sleep ending on this date)
    /// - Returns: SleepData with breakdown by stage, or nil if not available
    func fetchSleepData(for date: Date) async throws -> SleepData? {
        guard let sleepType = sleepType else {
            return nil
        }

        // For sleep, look at the previous night (sleep ending on the given date)
        let calendar = Calendar.current
        let endOfDay = calendar.startOfDay(for: date).addingTimeInterval(12 * 60 * 60) // Noon
        let startTime = calendar.date(byAdding: .hour, value: -18, to: endOfDay)! // 6 PM previous day

        let predicate = HKQuery.predicateForSamples(withStart: startTime, end: endOfDay, options: .strictEndDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, queryError in
                if let queryError = queryError {
                    continuation.resume(throwing: HealthKitError.queryFailed(queryError.localizedDescription))
                    return
                }

                guard let sleepSamples = samples as? [HKCategorySample], !sleepSamples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                let sleepData = self.processSleepSamples(sleepSamples)
                continuation.resume(returning: sleepData)
            }

            healthStore.execute(query)
        }
    }

    /// Fetch sleep history for a specified number of days
    /// - Parameter days: Number of days to fetch (default 7)
    /// - Returns: Array of SleepData sorted by date (newest first)
    func fetchSleepHistory(days: Int = 7) async throws -> [(date: Date, data: SleepData)] {
        var results: [(date: Date, data: SleepData)] = []
        let calendar = Calendar.current
        let today = Date()

        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                continue
            }

            if let sleepData = try? await fetchSleepData(for: date) {
                results.append((date: date, data: sleepData))
            }
        }

        return results
    }

    /// Calculate average sleep duration over specified days
    /// - Parameter days: Number of days to average (default 7)
    /// - Returns: Average sleep duration in minutes, or nil if no data
    func getAverageSleepDuration(days: Int = 7) async throws -> Int? {
        let history = try await fetchSleepHistory(days: days)

        guard !history.isEmpty else {
            return nil
        }

        let totalMinutes = history.reduce(0) { $0 + $1.data.totalMinutes }
        return totalMinutes / history.count
    }

    /// Calculate average sleep efficiency over specified days
    /// - Parameter days: Number of days to average (default 7)
    /// - Returns: Average sleep efficiency percentage, or nil if no data
    func getAverageSleepEfficiency(days: Int = 7) async throws -> Double? {
        let history = try await fetchSleepHistory(days: days)

        guard !history.isEmpty else {
            return nil
        }

        let totalEfficiency = history.reduce(0.0) { $0 + $1.data.sleepEfficiency }
        return totalEfficiency / Double(history.count)
    }

    // MARK: - Private Methods

    /// Process sleep samples into SleepData structure
    /// - Parameter samples: Array of HKCategorySample for sleep analysis
    /// - Returns: SleepData with all stage breakdowns
    private nonisolated func processSleepSamples(_ samples: [HKCategorySample]) -> SleepData {
        // All durations in seconds initially
        var inBedDuration: TimeInterval = 0
        var asleepDuration: TimeInterval = 0
        var remDuration: TimeInterval = 0
        var deepSleepDuration: TimeInterval = 0
        var coreSleepDuration: TimeInterval = 0
        var awakeDuration: TimeInterval = 0

        for sample in samples {
            let duration = sample.endDate.timeIntervalSince(sample.startDate)

            switch sample.value {
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                inBedDuration += duration
            case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                asleepDuration += duration
            case HKCategoryValueSleepAnalysis.awake.rawValue:
                awakeDuration += duration
            default:
                // Handle newer sleep stages (iOS 16+)
                if #available(iOS 16.0, *) {
                    switch sample.value {
                    case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                        remDuration += duration
                        asleepDuration += duration
                    case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                        coreSleepDuration += duration
                        asleepDuration += duration
                    case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                        deepSleepDuration += duration
                        asleepDuration += duration
                    default:
                        break
                    }
                }
            }
        }

        // Convert to minutes
        let minutesDivisor = 60.0

        return SleepData(
            totalMinutes: Int(asleepDuration / minutesDivisor),
            inBedMinutes: Int(inBedDuration / minutesDivisor),
            deepMinutes: deepSleepDuration > 0 ? Int(deepSleepDuration / minutesDivisor) : nil,
            remMinutes: remDuration > 0 ? Int(remDuration / minutesDivisor) : nil,
            coreMinutes: coreSleepDuration > 0 ? Int(coreSleepDuration / minutesDivisor) : nil,
            awakeMinutes: awakeDuration > 0 ? Int(awakeDuration / minutesDivisor) : nil
        )
    }
}
