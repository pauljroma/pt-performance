import Foundation
import HealthKit
import Supabase
import SwiftUI

// MARK: - HealthKit Data Models

/// All health metrics for a single day from HealthKit
struct HealthKitDayData: Codable {
    let date: Date
    let hrv: Double?
    let restingHeartRate: Double?
    let sleepDuration: Double?  // Total hours
    let sleepData: SleepData?
    let activeEnergyBurned: Double?  // Calories
    let appleExerciseTime: Double?   // Minutes

    enum CodingKeys: String, CodingKey {
        case date
        case hrv
        case restingHeartRate = "resting_heart_rate"
        case sleepDuration = "sleep_duration"
        case sleepData = "sleep_data"
        case activeEnergyBurned = "active_energy_burned"
        case appleExerciseTime = "apple_exercise_time"
    }
}

/// Sleep stages breakdown from HealthKit
struct SleepData: Codable {
    let totalDuration: Double       // Hours
    let inBedDuration: Double       // Hours
    let asleepDuration: Double      // Hours (all sleep stages combined)
    let remDuration: Double?        // Hours
    let deepSleepDuration: Double?  // Hours (core sleep on Apple Watch)
    let lightSleepDuration: Double? // Hours
    let awakeDuration: Double?      // Hours (awake periods during sleep)
    let sleepEfficiency: Double?    // Percentage (0-100)

    enum CodingKeys: String, CodingKey {
        case totalDuration = "total_duration"
        case inBedDuration = "in_bed_duration"
        case asleepDuration = "asleep_duration"
        case remDuration = "rem_duration"
        case deepSleepDuration = "deep_sleep_duration"
        case lightSleepDuration = "light_sleep_duration"
        case awakeDuration = "awake_duration"
        case sleepEfficiency = "sleep_efficiency"
    }

    /// Calculate sleep efficiency if not provided
    var calculatedEfficiency: Double {
        guard inBedDuration > 0 else { return 0 }
        return (asleepDuration / inBedDuration) * 100
    }
}

/// Pre-fill data for readiness check-in from HealthKit
struct ReadinessAutoFill {
    let sleepHours: Double?
    let sleepQuality: Int?        // 1-5 scale based on efficiency
    let hrvValue: Double?
    let restingHeartRate: Double?
    let dataSource: String        // "HealthKit" or "AppleWatch"
    let lastSyncDate: Date?

    /// Convert sleep efficiency to 1-5 quality scale
    static func sleepQualityFromEfficiency(_ efficiency: Double) -> Int {
        switch efficiency {
        case 90...: return 5      // Excellent
        case 80..<90: return 4    // Good
        case 70..<80: return 3    // Fair
        case 60..<70: return 2    // Poor
        default: return 1         // Very Poor
        }
    }
}

// MARK: - HealthKit Errors

/// HealthKit service errors
enum HealthKitError: LocalizedError {
    case notAvailable
    case notAuthorized
    case noDataAvailable
    case queryFailed(String)
    case saveFailed(String)
    case invalidDate

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .notAuthorized:
            return "HealthKit access has not been authorized"
        case .noDataAvailable:
            return "No health data available for the requested period"
        case .queryFailed(let message):
            return "Failed to query HealthKit: \(message)"
        case .saveFailed(let message):
            return "Failed to save to database: \(message)"
        case .invalidDate:
            return "Invalid date provided"
        }
    }
}

// MARK: - HealthKitService

/// Service for integrating with Apple HealthKit
/// Provides access to HRV, sleep, heart rate, and activity data
/// Uses @MainActor for thread-safe UI updates
@MainActor
class HealthKitService: ObservableObject {

    // MARK: - Published Properties

    @Published var isAuthorized: Bool = false
    @Published var lastSyncDate: Date?
    @Published var todayHRV: Double?
    @Published var todaySleep: Double?
    @Published var todayRestingHR: Double?
    @Published var isLoading: Bool = false
    @Published var error: Error?

    // MARK: - Private Properties

    private var healthStore: HKHealthStore?
    private let supabaseClient: PTSupabaseClient

    /// Check if HealthKit is available on this device
    static var isHealthKitAvailable: Bool {
        return HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Health Data Types

    /// Types to read from HealthKit
    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()

        // HRV
        if let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            types.insert(hrvType)
        }

        // Resting Heart Rate
        if let rhrType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) {
            types.insert(rhrType)
        }

        // Active Energy Burned
        if let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeEnergyType)
        }

        // Apple Exercise Time
        if let exerciseType = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) {
            types.insert(exerciseType)
        }

        // Sleep Analysis
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepType)
        }

        return types
    }

    // MARK: - Initialization

    nonisolated init(supabaseClient: PTSupabaseClient = .shared) {
        self.supabaseClient = supabaseClient

        // Initialize health store only if HealthKit is available
        if HKHealthStore.isHealthDataAvailable() {
            self.healthStore = HKHealthStore()
        }
    }

    // MARK: - Authorization

    /// Request HealthKit permissions for all required data types
    /// - Returns: True if authorization was granted
    func requestAuthorization() async throws -> Bool {
        guard let healthStore = healthStore else {
            throw HealthKitError.notAvailable
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Request authorization for read types only (we don't write to HealthKit)
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)

            // Check if we can actually read the data
            let authorized = checkAuthorizationStatus()
            isAuthorized = authorized

            return authorized
        } catch {
            self.error = error
            throw error
        }
    }

    /// Check if HealthKit authorization has been granted
    /// - Returns: True if at least HRV or sleep data can be read
    func checkAuthorizationStatus() -> Bool {
        guard let healthStore = healthStore else {
            return false
        }

        // Check HRV authorization
        var canReadHRV = false
        if let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            canReadHRV = healthStore.authorizationStatus(for: hrvType) == .sharingAuthorized
        }

        // Check sleep authorization
        var canReadSleep = false
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            canReadSleep = healthStore.authorizationStatus(for: sleepType) == .sharingAuthorized
        }

        // Consider authorized if we can read at least one key metric
        let authorized = canReadHRV || canReadSleep
        isAuthorized = authorized
        return authorized
    }

    // MARK: - Data Fetching

    /// Sync all today's health data
    /// - Returns: HealthKitDayData with all available metrics
    func syncTodayData() async throws -> HealthKitDayData {
        guard healthStore != nil else {
            throw HealthKitError.notAvailable
        }

        isLoading = true
        defer { isLoading = false }

        let today = Date()

        // Fetch all data in parallel
        async let hrvResult = fetchHRV(for: today)
        async let sleepResult = fetchSleepData(for: today)
        async let rhrResult = fetchRestingHeartRate(for: today)
        async let activeEnergyResult = fetchActiveEnergy(for: today)
        async let exerciseTimeResult = fetchExerciseTime(for: today)

        // Await all results
        let hrv = try? await hrvResult
        let sleep = try? await sleepResult
        let rhr = try? await rhrResult
        let activeEnergy = try? await activeEnergyResult
        let exerciseTime = try? await exerciseTimeResult

        // Update published properties
        todayHRV = hrv
        todaySleep = sleep?.totalDuration
        todayRestingHR = rhr
        lastSyncDate = Date()

        return HealthKitDayData(
            date: today,
            hrv: hrv,
            restingHeartRate: rhr,
            sleepDuration: sleep?.totalDuration,
            sleepData: sleep,
            activeEnergyBurned: activeEnergy,
            appleExerciseTime: exerciseTime
        )
    }

    /// Fetch HRV for a specific date
    /// - Parameter date: The date to fetch HRV for
    /// - Returns: HRV value in milliseconds (SDNN), or nil if not available
    func fetchHRV(for date: Date) async throws -> Double? {
        guard let healthStore = healthStore else {
            throw HealthKitError.notAvailable
        }

        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            return nil
        }

        let (startOfDay, endOfDay) = dayBoundaries(for: date)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: hrvType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error.localizedDescription))
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

    /// Fetch sleep data for a specific date (previous night's sleep)
    /// - Parameter date: The date to fetch sleep for (looks at sleep ending on this date)
    /// - Returns: SleepData with breakdown by stage, or nil if not available
    func fetchSleepData(for date: Date) async throws -> SleepData? {
        guard let healthStore = healthStore else {
            throw HealthKitError.notAvailable
        }

        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
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
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error.localizedDescription))
                    return
                }

                guard let sleepSamples = samples as? [HKCategorySample], !sleepSamples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                // Process sleep samples
                var inBedDuration: TimeInterval = 0
                var asleepDuration: TimeInterval = 0
                var remDuration: TimeInterval = 0
                var deepSleepDuration: TimeInterval = 0
                var lightSleepDuration: TimeInterval = 0
                var awakeDuration: TimeInterval = 0

                for sample in sleepSamples {
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
                                lightSleepDuration += duration
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

                // Convert to hours
                let hoursMultiplier = 1.0 / 3600.0
                let totalDuration = max(inBedDuration, asleepDuration + awakeDuration)

                let sleepData = SleepData(
                    totalDuration: totalDuration * hoursMultiplier,
                    inBedDuration: inBedDuration * hoursMultiplier,
                    asleepDuration: asleepDuration * hoursMultiplier,
                    remDuration: remDuration > 0 ? remDuration * hoursMultiplier : nil,
                    deepSleepDuration: deepSleepDuration > 0 ? deepSleepDuration * hoursMultiplier : nil,
                    lightSleepDuration: lightSleepDuration > 0 ? lightSleepDuration * hoursMultiplier : nil,
                    awakeDuration: awakeDuration > 0 ? awakeDuration * hoursMultiplier : nil,
                    sleepEfficiency: inBedDuration > 0 ? (asleepDuration / inBedDuration) * 100 : nil
                )

                continuation.resume(returning: sleepData)
            }

            healthStore.execute(query)
        }
    }

    /// Fetch resting heart rate for a specific date
    /// - Parameter date: The date to fetch RHR for
    /// - Returns: Resting heart rate in BPM, or nil if not available
    func fetchRestingHeartRate(for date: Date) async throws -> Double? {
        guard let healthStore = healthStore else {
            throw HealthKitError.notAvailable
        }

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
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error.localizedDescription))
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

    /// Fetch active energy burned for a specific date
    /// - Parameter date: The date to fetch active energy for
    /// - Returns: Active calories burned, or nil if not available
    private func fetchActiveEnergy(for date: Date) async throws -> Double? {
        guard let healthStore = healthStore else {
            throw HealthKitError.notAvailable
        }

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
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error.localizedDescription))
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
    private func fetchExerciseTime(for date: Date) async throws -> Double? {
        guard let healthStore = healthStore else {
            throw HealthKitError.notAvailable
        }

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
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error.localizedDescription))
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

    // MARK: - Readiness Auto-Fill

    /// Get auto-fill data for readiness check-in
    /// Pulls latest HealthKit data to pre-populate readiness form
    /// - Returns: ReadinessAutoFill with available health metrics
    func getReadinessAutoFill() async throws -> ReadinessAutoFill {
        guard healthStore != nil else {
            throw HealthKitError.notAvailable
        }

        let today = Date()

        // Fetch HRV and sleep data
        let hrv = try? await fetchHRV(for: today)
        let sleep = try? await fetchSleepData(for: today)
        let rhr = try? await fetchRestingHeartRate(for: today)

        // Calculate sleep quality from efficiency
        var sleepQuality: Int?
        if let efficiency = sleep?.sleepEfficiency ?? sleep?.calculatedEfficiency {
            sleepQuality = ReadinessAutoFill.sleepQualityFromEfficiency(efficiency)
        }

        return ReadinessAutoFill(
            sleepHours: sleep?.asleepDuration ?? sleep?.totalDuration,
            sleepQuality: sleepQuality,
            hrvValue: hrv,
            restingHeartRate: rhr,
            dataSource: "HealthKit",
            lastSyncDate: Date()
        )
    }

    // MARK: - HRV Baseline

    /// Calculate HRV baseline as average over specified days
    /// - Parameter days: Number of days to average (default 7)
    /// - Returns: Average HRV value, or nil if insufficient data
    func getHRVBaseline(days: Int = 7) async throws -> Double? {
        guard healthStore != nil else {
            throw HealthKitError.notAvailable
        }

        var hrvValues: [Double] = []
        let calendar = Calendar.current
        let today = Date()

        // Fetch HRV for each day
        for dayOffset in 0..<days {
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

    // MARK: - Database Sync

    /// Save HealthKit data to Supabase health_kit_data table
    /// - Parameter data: HealthKitDayData to save
    func saveToSupabase(data: HealthKitDayData) async throws {
        guard let patientId = supabaseClient.userId else {
            throw HealthKitError.saveFailed("No authenticated user")
        }

        isLoading = true
        defer { isLoading = false }

        // Format date for database
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: data.date)

        // Prepare data for upsert
        let dbData = HealthKitDBRecord(
            patientId: patientId,
            date: dateString,
            hrv: data.hrv,
            restingHeartRate: data.restingHeartRate,
            sleepDuration: data.sleepDuration,
            remSleep: data.sleepData?.remDuration,
            deepSleep: data.sleepData?.deepSleepDuration,
            lightSleep: data.sleepData?.lightSleepDuration,
            sleepEfficiency: data.sleepData?.sleepEfficiency,
            activeEnergyBurned: data.activeEnergyBurned,
            exerciseMinutes: data.appleExerciseTime,
            dataSource: "healthkit"
        )

        do {
            try await supabaseClient.client
                .from("health_kit_data")
                .upsert(dbData, onConflict: "patient_id,date")
                .execute()

            lastSyncDate = Date()
        } catch {
            self.error = error
            throw HealthKitError.saveFailed(error.localizedDescription)
        }
    }

    // MARK: - Helper Methods

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

// MARK: - Database Record Model

/// Model for upserting HealthKit data to Supabase
private struct HealthKitDBRecord: Codable {
    let patientId: String
    let date: String
    let hrv: Double?
    let restingHeartRate: Double?
    let sleepDuration: Double?
    let remSleep: Double?
    let deepSleep: Double?
    let lightSleep: Double?
    let sleepEfficiency: Double?
    let activeEnergyBurned: Double?
    let exerciseMinutes: Double?
    let dataSource: String

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case date
        case hrv
        case restingHeartRate = "resting_heart_rate"
        case sleepDuration = "sleep_duration"
        case remSleep = "rem_sleep"
        case deepSleep = "deep_sleep"
        case lightSleep = "light_sleep"
        case sleepEfficiency = "sleep_efficiency"
        case activeEnergyBurned = "active_energy_burned"
        case exerciseMinutes = "exercise_minutes"
        case dataSource = "data_source"
    }
}

// MARK: - Convenience Extensions

extension HealthKitService {
    /// Check if any health data is available for today
    var hasHealthData: Bool {
        return todayHRV != nil || todaySleep != nil || todayRestingHR != nil
    }

    /// Formatted string for last sync time
    var lastSyncText: String {
        guard let date = lastSyncDate else {
            return "Never synced"
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// Sync and save today's data in one call
    func syncAndSave() async throws -> HealthKitDayData {
        let data = try await syncTodayData()
        try await saveToSupabase(data: data)
        return data
    }
}

// MARK: - Preview Support

#if DEBUG
extension HealthKitService {
    /// Create a mock service for previews
    static var preview: HealthKitService {
        let service = HealthKitService()
        service.isAuthorized = true
        service.todayHRV = 65.5
        service.todaySleep = 7.5
        service.todayRestingHR = 58.0
        service.lastSyncDate = Date()
        return service
    }
}

extension HealthKitDayData {
    /// Sample data for previews
    static var sample: HealthKitDayData {
        HealthKitDayData(
            date: Date(),
            hrv: 65.5,
            restingHeartRate: 58.0,
            sleepDuration: 7.5,
            sleepData: SleepData.sample,
            activeEnergyBurned: 450.0,
            appleExerciseTime: 35.0
        )
    }
}

extension SleepData {
    /// Sample data for previews
    static var sample: SleepData {
        SleepData(
            totalDuration: 8.0,
            inBedDuration: 8.5,
            asleepDuration: 7.5,
            remDuration: 1.8,
            deepSleepDuration: 1.5,
            lightSleepDuration: 4.2,
            awakeDuration: 0.5,
            sleepEfficiency: 88.2
        )
    }
}

extension ReadinessAutoFill {
    /// Sample data for previews
    static var sample: ReadinessAutoFill {
        ReadinessAutoFill(
            sleepHours: 7.5,
            sleepQuality: 4,
            hrvValue: 65.5,
            restingHeartRate: 58.0,
            dataSource: "HealthKit",
            lastSyncDate: Date()
        )
    }
}
#endif
