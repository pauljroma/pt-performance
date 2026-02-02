import Foundation
import HealthKit
import Supabase
import SwiftUI

// MARK: - HealthKit Data Models

/// All health metrics for a single day from HealthKit
struct HealthKitDayData: Codable {
    let date: Date
    let hrvSDNN: Double?
    let hrvRMSSD: Double?
    let sleepDurationMinutes: Int?
    let sleepDeepMinutes: Int?
    let sleepREMMinutes: Int?
    let restingHeartRate: Double?
    let activeEnergyBurned: Double?
    let exerciseMinutes: Int?
    let stepCount: Int?

    enum CodingKeys: String, CodingKey {
        case date
        case hrvSDNN = "hrv_sdnn"
        case hrvRMSSD = "hrv_rmssd"
        case sleepDurationMinutes = "sleep_duration_minutes"
        case sleepDeepMinutes = "sleep_deep_minutes"
        case sleepREMMinutes = "sleep_rem_minutes"
        case restingHeartRate = "resting_heart_rate"
        case activeEnergyBurned = "active_energy_burned"
        case exerciseMinutes = "exercise_minutes"
        case stepCount = "step_count"
    }
}

/// Sleep stages breakdown from HealthKit
struct SleepData: Codable {
    let totalMinutes: Int
    let inBedMinutes: Int
    let deepMinutes: Int?
    let remMinutes: Int?
    let coreMinutes: Int?
    let awakeMinutes: Int?

    enum CodingKeys: String, CodingKey {
        case totalMinutes = "total_minutes"
        case inBedMinutes = "in_bed_minutes"
        case deepMinutes = "deep_minutes"
        case remMinutes = "rem_minutes"
        case coreMinutes = "core_minutes"
        case awakeMinutes = "awake_minutes"
    }

    /// Calculate sleep efficiency as percentage
    var sleepEfficiency: Double {
        guard inBedMinutes > 0 else { return 0 }
        let awakeMins = awakeMinutes ?? 0
        let asleepMinutes = totalMinutes - awakeMins
        return (Double(asleepMinutes) / Double(inBedMinutes)) * 100
    }

    /// Convert to hours for display
    var totalHours: Double {
        Double(totalMinutes) / 60.0
    }
}

/// Pre-fill data for readiness check-in from HealthKit
struct ReadinessAutoFill {
    let suggestedSleepHours: Double?
    let suggestedEnergyLevel: Int?  // Based on HRV deviation from baseline (1-10)
    let dataSource: String          // "apple_watch" or "manual"

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
    case noAuthenticatedUser

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
        case .noAuthenticatedUser:
            return "No authenticated user found"
        }
    }
}

// MARK: - HealthKitService

/// Service for integrating with Apple HealthKit
/// Provides access to HRV, sleep, heart rate, and activity data
/// Uses @MainActor for thread-safe UI updates
@MainActor
class HealthKitService: ObservableObject {

    // MARK: - Singleton

    /// Shared singleton instance
    static let shared = HealthKitService()

    // MARK: - Published Properties

    @Published var isAuthorized: Bool = false
    @Published var lastSyncDate: Date?
    @Published var todayHRV: Double?
    @Published var todaySleep: SleepData?
    @Published var todayRestingHR: Double?
    @Published var isLoading: Bool = false
    @Published var error: String?

    // MARK: - Private Properties

    private var healthStore: HKHealthStore?
    // Using nonisolated(unsafe) to allow initialization in nonisolated init
    // This is safe because supabaseClient is only read after initialization
    private nonisolated(unsafe) let supabaseClient: PTSupabaseClient

    /// Check if HealthKit is available on this device
    static var isHealthKitAvailable: Bool {
        return HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Health Data Types

    /// Types to read from HealthKit
    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()

        // HRV (SDNN)
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

        // Step Count
        if let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) {
            types.insert(stepType)
        }

        // Oxygen Saturation (if available)
        if let oxygenType = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) {
            types.insert(oxygenType)
        }

        // Sleep Analysis
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepType)
        }

        return types
    }

    // MARK: - Initialization

    /// Private initializer for singleton pattern
    /// Use HealthKitService.shared to access the singleton
    private nonisolated init() {
        self.supabaseClient = PTSupabaseClient.shared

        // Initialize health store only if HealthKit is available
        if HKHealthStore.isHealthDataAvailable() {
            self.healthStore = HKHealthStore()
        }
    }

    /// Initializer for dependency injection (testing)
    nonisolated init(supabaseClient: PTSupabaseClient) {
        self.supabaseClient = supabaseClient

        // Initialize health store only if HealthKit is available
        if HKHealthStore.isHealthDataAvailable() {
            self.healthStore = HKHealthStore()
        }
    }

    // MARK: - Authorization

    /// Request HealthKit permissions for all required data types
    /// - Returns: True if authorization was granted
    /// - Throws: HealthKitError if HealthKit is not available
    func requestAuthorization() async throws -> Bool {
        guard let healthStore = healthStore else {
            throw HealthKitError.notAvailable
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // Request authorization for read types only (we don't write to HealthKit)
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)

            // Check if we can actually read the data
            let authorized = checkAuthorizationStatus()
            isAuthorized = authorized

            return authorized
        } catch let authError {
            self.error = authError.localizedDescription
            throw authError
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
    /// - Throws: HealthKitError if HealthKit is not available
    func syncTodayData() async throws -> HealthKitDayData {
        guard healthStore != nil else {
            throw HealthKitError.notAvailable
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        let today = Date()

        // Fetch all data in parallel
        async let hrvResult = fetchHRV(for: today)
        async let sleepResult = fetchSleepData(for: today)
        async let rhrResult = fetchRestingHeartRate(for: today)
        async let activeEnergyResult = fetchActiveEnergy(for: today)
        async let exerciseTimeResult = fetchExerciseTime(for: today)
        async let stepCountResult = fetchStepCount(for: today)

        // Await all results
        let hrv = try? await hrvResult
        let sleep = try? await sleepResult
        let rhr = try? await rhrResult
        let activeEnergy = try? await activeEnergyResult
        let exerciseTime = try? await exerciseTimeResult
        let stepCount = try? await stepCountResult

        // Update published properties
        todayHRV = hrv
        todaySleep = sleep
        todayRestingHR = rhr
        lastSyncDate = Date()

        return HealthKitDayData(
            date: today,
            hrvSDNN: hrv,
            hrvRMSSD: nil, // Apple Watch provides SDNN, not RMSSD
            sleepDurationMinutes: sleep?.totalMinutes,
            sleepDeepMinutes: sleep?.deepMinutes,
            sleepREMMinutes: sleep?.remMinutes,
            restingHeartRate: rhr,
            activeEnergyBurned: activeEnergy,
            exerciseMinutes: exerciseTime != nil ? Int(exerciseTime!) : nil,
            stepCount: stepCount != nil ? Int(stepCount!) : nil
        )
    }

    /// Fetch HRV (SDNN) for a specific date
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
            ) { _, samples, queryError in
                if let queryError = queryError {
                    continuation.resume(throwing: HealthKitError.queryFailed(queryError.localizedDescription))
                    return
                }

                guard let sleepSamples = samples as? [HKCategorySample], !sleepSamples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                // Process sleep samples - all durations in seconds initially
                var inBedDuration: TimeInterval = 0
                var asleepDuration: TimeInterval = 0
                var remDuration: TimeInterval = 0
                var deepSleepDuration: TimeInterval = 0
                var coreSleepDuration: TimeInterval = 0
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

                let sleepData = SleepData(
                    totalMinutes: Int(asleepDuration / minutesDivisor),
                    inBedMinutes: Int(inBedDuration / minutesDivisor),
                    deepMinutes: deepSleepDuration > 0 ? Int(deepSleepDuration / minutesDivisor) : nil,
                    remMinutes: remDuration > 0 ? Int(remDuration / minutesDivisor) : nil,
                    coreMinutes: coreSleepDuration > 0 ? Int(coreSleepDuration / minutesDivisor) : nil,
                    awakeMinutes: awakeDuration > 0 ? Int(awakeDuration / minutesDivisor) : nil
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
    private func fetchStepCount(for date: Date) async throws -> Double? {
        guard let healthStore = healthStore else {
            throw HealthKitError.notAvailable
        }

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

    /// Fetch oxygen saturation for a specific date
    /// - Parameter date: The date to fetch oxygen saturation for
    /// - Returns: Oxygen saturation percentage (0-100), or nil if not available
    func fetchOxygenSaturation(for date: Date) async throws -> Double? {
        guard let healthStore = healthStore else {
            throw HealthKitError.notAvailable
        }

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

    // MARK: - Readiness Auto-Fill

    /// Get auto-fill data for readiness check-in
    /// Pulls latest HealthKit data to pre-populate readiness form
    /// Suggests energy level based on HRV deviation from baseline
    /// - Returns: ReadinessAutoFill with available health metrics
    func getReadinessAutoFill() async throws -> ReadinessAutoFill {
        guard healthStore != nil else {
            throw HealthKitError.notAvailable
        }

        let today = Date()

        // Fetch HRV, sleep data, and baseline in parallel
        async let hrvTask = fetchHRV(for: today)
        async let sleepTask = fetchSleepData(for: today)
        async let baselineTask = getHRVBaseline(days: 7)

        let hrv = try? await hrvTask
        let sleep = try? await sleepTask
        let baseline = try? await baselineTask

        // Calculate suggested energy level based on HRV deviation from baseline
        let suggestedEnergy = calculateSuggestedEnergyLevel(currentHRV: hrv, baseline: baseline)

        // Determine data source
        let dataSource: String
        if hrv != nil || sleep != nil {
            dataSource = "apple_watch"
        } else {
            dataSource = "manual"
        }

        return ReadinessAutoFill(
            suggestedSleepHours: sleep?.totalHours,
            suggestedEnergyLevel: suggestedEnergy,
            dataSource: dataSource
        )
    }

    /// Calculate suggested energy level based on HRV deviation from baseline
    /// - Parameters:
    ///   - currentHRV: Today's HRV value
    ///   - baseline: 7-day rolling average HRV
    /// - Returns: Suggested energy level (1-10) or nil if no data
    private func calculateSuggestedEnergyLevel(currentHRV: Double?, baseline: Double?) -> Int? {
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

    // MARK: - HRV Baseline

    /// Calculate HRV baseline as 7-day rolling average
    /// - Parameter days: Number of days to average (default 7)
    /// - Returns: Average HRV value, or nil if insufficient data
    func getHRVBaseline(days: Int = 7) async throws -> Double? {
        guard healthStore != nil else {
            throw HealthKitError.notAvailable
        }

        var hrvValues: [Double] = []
        let calendar = Calendar.current
        let today = Date()

        // Fetch HRV for each day (skip today, use previous 7 days)
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

    // MARK: - Database Sync

    /// Upload HealthKit data to Supabase health_kit_data table
    /// - Parameter data: HealthKitDayData to upload
    /// - Throws: HealthKitError if no authenticated user or save fails
    func uploadToSupabase(data: HealthKitDayData) async throws {
        guard let patientIdString = supabaseClient.userId,
              let patientId = UUID(uuidString: patientIdString) else {
            throw HealthKitError.noAuthenticatedUser
        }

        try await syncToSupabase(patientId: patientId, data: data)
    }

    /// Sync HealthKit data to Supabase health_kit_data table
    /// - Parameters:
    ///   - patientId: Patient UUID to associate the data with
    ///   - data: HealthKitDayData to save
    func syncToSupabase(patientId: UUID, data: HealthKitDayData) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        // Format date for database
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: data.date)

        // Prepare data for upsert
        let dbData = HealthKitDBRecord(
            patientId: patientId.uuidString,
            date: dateString,
            hrvSdnn: data.hrvSDNN,
            hrvRmssd: data.hrvRMSSD,
            restingHeartRate: data.restingHeartRate,
            sleepDurationMinutes: data.sleepDurationMinutes,
            sleepDeepMinutes: data.sleepDeepMinutes,
            sleepRemMinutes: data.sleepREMMinutes,
            activeEnergyBurned: data.activeEnergyBurned,
            exerciseMinutes: data.exerciseMinutes,
            stepCount: data.stepCount,
            dataSource: "apple_watch",
            syncedAt: ISO8601DateFormatter().string(from: Date())
        )

        do {
            try await supabaseClient.client
                .from("health_kit_data")
                .upsert(dbData, onConflict: "patient_id,date")
                .execute()

            lastSyncDate = Date()
        } catch let saveError {
            self.error = saveError.localizedDescription
            throw HealthKitError.saveFailed(saveError.localizedDescription)
        }
    }

    /// Save HealthKit data to Supabase for the current authenticated user
    /// Convenience method that uses the current user's patient ID
    /// - Parameter data: HealthKitDayData to save
    @available(*, deprecated, renamed: "uploadToSupabase(data:)", message: "Use uploadToSupabase instead")
    func saveToSupabase(data: HealthKitDayData) async throws {
        try await uploadToSupabase(data: data)
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
    let hrvSdnn: Double?
    let hrvRmssd: Double?
    let restingHeartRate: Double?
    let sleepDurationMinutes: Int?
    let sleepDeepMinutes: Int?
    let sleepRemMinutes: Int?
    let activeEnergyBurned: Double?
    let exerciseMinutes: Int?
    let stepCount: Int?
    let dataSource: String
    let syncedAt: String

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case date
        case hrvSdnn = "hrv_sdnn"
        case hrvRmssd = "hrv_rmssd"
        case restingHeartRate = "resting_heart_rate"
        case sleepDurationMinutes = "sleep_duration_minutes"
        case sleepDeepMinutes = "sleep_deep_minutes"
        case sleepRemMinutes = "sleep_rem_minutes"
        case activeEnergyBurned = "active_energy_burned"
        case exerciseMinutes = "exercise_minutes"
        case stepCount = "step_count"
        case dataSource = "data_source"
        case syncedAt = "synced_at"
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
        try await uploadToSupabase(data: data)
        return data
    }

    /// Sync and save today's data for a specific patient
    func syncAndSave(patientId: UUID) async throws -> HealthKitDayData {
        let data = try await syncTodayData()
        try await syncToSupabase(patientId: patientId, data: data)
        return data
    }

    /// Get HRV deviation from baseline as percentage
    /// Useful for displaying recovery status
    /// - Returns: Deviation percentage (positive = above baseline, negative = below)
    func getHRVDeviationFromBaseline() async throws -> Double? {
        // Get current HRV - prefer cached, otherwise fetch
        let currentHRV: Double
        if let cached = todayHRV {
            currentHRV = cached
        } else if let fetched = try await fetchHRV(for: Date()) {
            currentHRV = fetched
        } else {
            return nil
        }

        guard let baseline = try await getHRVBaseline(), baseline > 0 else {
            return nil
        }

        return ((currentHRV - baseline) / baseline) * 100
    }
}

// MARK: - Preview Support

#if DEBUG
extension HealthKitService {
    /// Create a mock service for previews
    static var preview: HealthKitService {
        let service = HealthKitService(supabaseClient: .shared)
        service.isAuthorized = true
        service.todayHRV = 65.5
        service.todaySleep = SleepData.sample
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
            hrvSDNN: 65.5,
            hrvRMSSD: nil,
            sleepDurationMinutes: 450,
            sleepDeepMinutes: 90,
            sleepREMMinutes: 108,
            restingHeartRate: 58.0,
            activeEnergyBurned: 450.0,
            exerciseMinutes: 35,
            stepCount: 8500
        )
    }
}

extension SleepData {
    /// Sample data for previews
    static var sample: SleepData {
        SleepData(
            totalMinutes: 450,
            inBedMinutes: 510,
            deepMinutes: 90,
            remMinutes: 108,
            coreMinutes: 252,
            awakeMinutes: 30
        )
    }
}

extension ReadinessAutoFill {
    /// Sample data for previews
    static var sample: ReadinessAutoFill {
        ReadinessAutoFill(
            suggestedSleepHours: 7.5,
            suggestedEnergyLevel: 8,
            dataSource: "apple_watch"
        )
    }
}
#endif
