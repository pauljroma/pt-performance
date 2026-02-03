import Foundation
import HealthKit

// MARK: - HRV Reading Model

/// A single HRV reading with timestamp
struct HRVReading: Codable, Identifiable {
    let id: UUID
    let date: Date
    let hrvSDNN: Double

    init(id: UUID = UUID(), date: Date, hrvSDNN: Double) {
        self.id = id
        self.date = date
        self.hrvSDNN = hrvSDNN
    }

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case hrvSDNN = "hrv_sdnn"
    }
}

// MARK: - HRV Service

/// Focused service for HRV (Heart Rate Variability) data fetching from HealthKit
/// Handles SDNN measurements from Apple Watch
@MainActor
class HRVService {

    // MARK: - Properties

    private let healthStore: HKHealthStore

    /// HRV quantity type for HealthKit queries
    private var hrvType: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)
    }

    // MARK: - Initialization

    /// Initialize with a HealthKit store
    /// - Parameter healthStore: The HKHealthStore to use for queries
    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }

    // MARK: - Public Methods

    /// Fetch the latest HRV value for a specific date
    /// - Parameter date: The date to fetch HRV for
    /// - Returns: HRV value in milliseconds (SDNN), or nil if not available
    func fetchHRV(for date: Date) async throws -> Double? {
        guard let hrvType = hrvType else {
            return nil
        }

        let (startOfDay, endOfDay) = dayBoundaries(for: date)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: hrvType,
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

                let hrvValue = average.doubleValue(for: HKUnit.secondUnit(with: .milli))
                continuation.resume(returning: hrvValue)
            }

            healthStore.execute(query)
        }
    }

    /// Fetch HRV history for a specified number of days
    /// - Parameter days: Number of days to fetch (default 7)
    /// - Returns: Array of HRVReading sorted by date (newest first)
    func fetchHRVHistory(days: Int = 7) async throws -> [HRVReading] {
        guard let hrvType = hrvType else {
            return []
        }

        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            return []
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, queryError in
                if let queryError = queryError {
                    continuation.resume(throwing: HealthKitError.queryFailed(queryError.localizedDescription))
                    return
                }

                guard let quantitySamples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }

                let readings = quantitySamples.map { sample in
                    HRVReading(
                        date: sample.endDate,
                        hrvSDNN: sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                    )
                }

                continuation.resume(returning: readings)
            }

            healthStore.execute(query)
        }
    }

    /// Calculate HRV baseline as rolling average over specified days
    /// - Parameter days: Number of days to average (default 7)
    /// - Returns: Average HRV value, or nil if insufficient data (requires at least 3 days)
    func getHRVBaseline(days: Int = 7) async throws -> Double? {
        var hrvValues: [Double] = []
        let calendar = Calendar.current
        let today = Date()

        // Fetch HRV for each day (skip today, use previous days)
        for dayOffset in 1...days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                continue
            }

            if let hrv = try? await fetchHRV(for: date), hrv > 0 {
                hrvValues.append(hrv)
            }
        }

        // Need at least 3 days of data for a meaningful baseline
        guard hrvValues.count >= 3 else {
            return nil
        }

        let average = hrvValues.reduce(0, +) / Double(hrvValues.count)
        return average
    }

    /// Calculate deviation from baseline as percentage
    /// - Parameter currentHRV: Current HRV value to compare
    /// - Returns: Deviation percentage (positive = above baseline, negative = below)
    func getDeviationFromBaseline(currentHRV: Double) async throws -> Double? {
        guard let baseline = try await getHRVBaseline(), baseline > 0 else {
            return nil
        }

        return ((currentHRV - baseline) / baseline) * 100
    }

    /// Calculate suggested energy level based on HRV deviation from baseline
    /// - Parameters:
    ///   - currentHRV: Today's HRV value
    ///   - baseline: 7-day rolling average HRV
    /// - Returns: Suggested energy level (1-10) or nil if no data
    func calculateSuggestedEnergyLevel(currentHRV: Double?, baseline: Double?) -> Int? {
        guard let hrv = currentHRV, let base = baseline, base > 0 else {
            return nil
        }

        let deviationPercent = ((hrv - base) / base) * 100

        // HRV > baseline + 10% -> high energy (8-10)
        // HRV < baseline - 10% -> low energy (4-6)
        // Otherwise -> normal energy (6-8)
        if deviationPercent > 10 {
            // Good recovery - suggest high energy
            // Scale from 8-10 based on how much above baseline
            let scaledEnergy = min(10, 8 + Int(deviationPercent / 10))
            return scaledEnergy
        } else if deviationPercent < -10 {
            // Poor recovery - suggest low energy
            // Scale from 4-6 based on how much below baseline
            let scaledEnergy = max(4, 6 + Int(deviationPercent / 10))
            return scaledEnergy
        } else {
            // Normal range - suggest moderate energy (6-8)
            // Slight bias toward 7
            return 7
        }
    }

    // MARK: - Private Methods

    /// Get start and end of day for a given date
    /// - Parameter date: The date to get boundaries for
    /// - Returns: Tuple of (startOfDay, endOfDay)
    private func dayBoundaries(for date: Date) -> (Date, Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        return (startOfDay, endOfDay)
    }
}

// MARK: - Preview Support

#if DEBUG
extension HRVReading {
    /// Sample data for previews
    static var sample: HRVReading {
        HRVReading(date: Date(), hrvSDNN: 65.5)
    }

    /// Sample history for previews
    static var sampleHistory: [HRVReading] {
        let calendar = Calendar.current
        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else {
                return nil
            }
            return HRVReading(date: date, hrvSDNN: Double.random(in: 55...75))
        }
    }
}
#endif
