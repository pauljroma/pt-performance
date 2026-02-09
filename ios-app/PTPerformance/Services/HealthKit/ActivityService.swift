import Foundation
import HealthKit

// MARK: - Activity Data Model

/// Combined activity metrics for a single day
struct ActivityData: Codable {
    let date: Date
    let activeEnergyBurned: Double?
    let exerciseMinutes: Int?
    let stepCount: Int?

    enum CodingKeys: String, CodingKey {
        case date
        case activeEnergyBurned = "active_energy_burned"
        case exerciseMinutes = "exercise_minutes"
        case stepCount = "step_count"
    }
}

// MARK: - Activity Service

/// Focused service for activity data fetching from HealthKit
/// Handles active energy, exercise time, step count, and resting heart rate
@MainActor
class ActivityService {

    // MARK: - Properties

    private let healthStore: HKHealthStore

    // MARK: - Initialization

    /// Initialize with a HealthKit store
    /// - Parameter healthStore: The HKHealthStore to use for queries
    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }

    // MARK: - Public Methods

    /// Fetch all activity metrics for a specific date
    /// - Parameter date: The date to fetch activity for
    /// - Returns: ActivityData with all available metrics
    func fetchActivityData(for date: Date) async throws -> ActivityData {
        async let activeEnergyResult = fetchActiveEnergy(for: date)
        async let exerciseTimeResult = fetchExerciseTime(for: date)
        async let stepCountResult = fetchStepCount(for: date)

        let activeEnergy = try? await activeEnergyResult
        let exerciseTime = try? await exerciseTimeResult
        let stepCount = try? await stepCountResult

        return ActivityData(
            date: date,
            activeEnergyBurned: activeEnergy,
            exerciseMinutes: exerciseTime.map { Int($0) },
            stepCount: stepCount.map { Int($0) }
        )
    }

    /// Fetch active energy burned for a specific date
    /// - Parameter date: The date to fetch active energy for
    /// - Returns: Active calories burned, or nil if not available
    func fetchActiveEnergy(for date: Date) async throws -> Double? {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return nil
        }

        let (startOfDay, endOfDay) = dayBoundaries(for: date)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, queryError in
                if let queryError = queryError {
                    continuation.resume(throwing: HealthKitError.queryFailed(queryError.localizedDescription))
                    return
                }

                guard let result = result,
                      let sum = result.sumQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }

                let calories = sum.doubleValue(for: HKUnit.kilocalorie())
                continuation.resume(returning: calories)
            }

            healthStore.execute(query)
        }
    }

    /// Fetch Apple Exercise Time for a specific date
    /// - Parameter date: The date to fetch exercise time for
    /// - Returns: Exercise time in minutes, or nil if not available
    func fetchExerciseTime(for date: Date) async throws -> Double? {
        guard let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else {
            return nil
        }

        let (startOfDay, endOfDay) = dayBoundaries(for: date)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: exerciseType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, queryError in
                if let queryError = queryError {
                    continuation.resume(throwing: HealthKitError.queryFailed(queryError.localizedDescription))
                    return
                }

                guard let result = result,
                      let sum = result.sumQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }

                let minutes = sum.doubleValue(for: HKUnit.minute())
                continuation.resume(returning: minutes)
            }

            healthStore.execute(query)
        }
    }

    /// Fetch step count for a specific date
    /// - Parameter date: The date to fetch step count for
    /// - Returns: Step count, or nil if not available
    func fetchStepCount(for date: Date) async throws -> Double? {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return nil
        }

        let (startOfDay, endOfDay) = dayBoundaries(for: date)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, queryError in
                if let queryError = queryError {
                    continuation.resume(throwing: HealthKitError.queryFailed(queryError.localizedDescription))
                    return
                }

                guard let result = result,
                      let sum = result.sumQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }

                let steps = sum.doubleValue(for: HKUnit.count())
                continuation.resume(returning: steps)
            }

            healthStore.execute(query)
        }
    }

    /// Fetch resting heart rate for a specific date
    /// - Parameter date: The date to fetch RHR for
    /// - Returns: Resting heart rate in BPM, or nil if not available
    func fetchRestingHeartRate(for date: Date) async throws -> Double? {
        guard let rhrType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else {
            return nil
        }

        let (startOfDay, endOfDay) = dayBoundaries(for: date)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: rhrType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, result, queryError in
                if let queryError = queryError {
                    continuation.resume(throwing: HealthKitError.queryFailed(queryError.localizedDescription))
                    return
                }

                guard let result = result,
                      let average = result.averageQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }

                let rhrValue = average.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                continuation.resume(returning: rhrValue)
            }

            healthStore.execute(query)
        }
    }

    /// Fetch oxygen saturation for a specific date
    /// - Parameter date: The date to fetch oxygen saturation for
    /// - Returns: Oxygen saturation percentage (0-100), or nil if not available
    func fetchOxygenSaturation(for date: Date) async throws -> Double? {
        guard let oxygenType = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else {
            return nil
        }

        let (startOfDay, endOfDay) = dayBoundaries(for: date)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: oxygenType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, result, queryError in
                if let queryError = queryError {
                    continuation.resume(throwing: HealthKitError.queryFailed(queryError.localizedDescription))
                    return
                }

                guard let result = result,
                      let average = result.averageQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }

                // Convert from decimal (0.0-1.0) to percentage (0-100)
                let oxygenValue = average.doubleValue(for: HKUnit.percent()) * 100
                continuation.resume(returning: oxygenValue)
            }

            healthStore.execute(query)
        }
    }

    /// Fetch activity history for a specified number of days
    /// - Parameter days: Number of days to fetch (default 7)
    /// - Returns: Array of ActivityData sorted by date (newest first)
    func fetchActivityHistory(days: Int = 7) async throws -> [ActivityData] {
        var results: [ActivityData] = []
        let calendar = Calendar.current
        let today = Date()

        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                continue
            }

            let activityData = try await fetchActivityData(for: date)
            results.append(activityData)
        }

        return results
    }

    // MARK: - Private Methods

    /// Get start and end of day for a given date
    /// - Parameter date: The date to get boundaries for
    /// - Returns: Tuple of (startOfDay, endOfDay)
    private func dayBoundaries(for date: Date) -> (Date, Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay.addingTimeInterval(86400)
        return (startOfDay, endOfDay)
    }
}

// MARK: - Preview Support

#if DEBUG
extension ActivityData {
    /// Sample data for previews
    static var sample: ActivityData {
        ActivityData(
            date: Date(),
            activeEnergyBurned: 450.0,
            exerciseMinutes: 35,
            stepCount: 8500
        )
    }
}
#endif
