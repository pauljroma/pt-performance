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

    var recoverySuggestion: String? {
        switch self {
        case .notAvailable:
            return "HealthKit requires an iPhone or Apple Watch. This feature is not available on this device."
        case .notAuthorized:
            return "Go to Settings > Privacy > Health > Modus to grant access to your health data."
        case .noDataAvailable:
            return "Make sure you're wearing your Apple Watch and it's syncing data to your iPhone."
        case .queryFailed:
            return "There was a problem reading your health data. Please try again."
        case .saveFailed:
            return "Your health data couldn't be saved. Please check your connection and try again."
        case .invalidDate:
            return "Please select a valid date and try again."
        case .noAuthenticatedUser:
            return "Please sign in to sync your health data."
        }
    }
}

// MARK: - HealthKitService

/// Service for integrating with Apple HealthKit
/// Acts as a facade/coordinator that delegates to focused services:
/// - HRVService: Heart rate variability data
/// - SleepService: Sleep analysis data
/// - ActivityService: Energy, steps, resting heart rate
/// - WorkoutExportService: Workout export to Apple Health
///
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

    // ACP-827: Workout export tracking
    @Published var lastExportDate: Date?
    @Published var exportedWorkoutsCount: Int = 0
    @Published var syncConfig: HealthSyncConfig = HealthSyncConfig.load()

    // MARK: - Private Properties

    private var healthStore: HKHealthStore?
    // Using nonisolated(unsafe) to allow initialization in nonisolated init
    // This is safe because supabaseClient is only read after initialization
    private nonisolated(unsafe) let supabaseClient: PTSupabaseClient

    // MARK: - Focused Services (lazy initialization)

    private var _hrvService: HRVService?
    private var hrvService: HRVService? {
        guard let healthStore = healthStore else { return nil }
        if _hrvService == nil {
            _hrvService = HRVService(healthStore: healthStore)
        }
        return _hrvService
    }

    private var _sleepService: SleepService?
    private var sleepService: SleepService? {
        guard let healthStore = healthStore else { return nil }
        if _sleepService == nil {
            _sleepService = SleepService(healthStore: healthStore)
        }
        return _sleepService
    }

    private var _activityService: ActivityService?
    private var activityService: ActivityService? {
        guard let healthStore = healthStore else { return nil }
        if _activityService == nil {
            _activityService = ActivityService(healthStore: healthStore)
        }
        return _activityService
    }

    private var _workoutExportService: WorkoutExportService?
    private var workoutExportService: WorkoutExportService? {
        guard let healthStore = healthStore else { return nil }
        if _workoutExportService == nil {
            _workoutExportService = WorkoutExportService(healthStore: healthStore)
        }
        return _workoutExportService
    }

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

    /// Types to write to HealthKit (ACP-827: Workout export)
    private var writeTypes: Set<HKSampleType> {
        var types = Set<HKSampleType>()

        // Workout type for exporting completed sessions
        types.insert(HKObjectType.workoutType())

        // Active energy burned (for workout samples)
        if let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeEnergyType)
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
            // ACP-827: Request authorization for both read and write types (bidirectional sync)
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)

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

        // Fetch all data in parallel using focused services
        async let hrvResult = fetchHRV(for: today)
        async let sleepResult = fetchSleepData(for: today)
        async let rhrResult = fetchRestingHeartRate(for: today)
        async let activeEnergyResult = activityService?.fetchActiveEnergy(for: today)
        async let exerciseTimeResult = activityService?.fetchExerciseTime(for: today)
        async let stepCountResult = activityService?.fetchStepCount(for: today)

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
            activeEnergyBurned: activeEnergy ?? nil,
            exerciseMinutes: exerciseTime != nil ? Int(exerciseTime!) : nil,
            stepCount: stepCount != nil ? Int(stepCount!) : nil
        )
    }

    // MARK: - HRV Methods (delegated to HRVService)

    /// Fetch HRV (SDNN) for a specific date
    /// - Parameter date: The date to fetch HRV for
    /// - Returns: HRV value in milliseconds (SDNN), or nil if not available
    func fetchHRV(for date: Date) async throws -> Double? {
        guard let hrvService = hrvService else {
            throw HealthKitError.notAvailable
        }
        return try await hrvService.fetchHRV(for: date)
    }

    /// Calculate HRV baseline as 7-day rolling average
    /// - Parameter days: Number of days to average (default 7)
    /// - Returns: Average HRV value, or nil if insufficient data
    func getHRVBaseline(days: Int = 7) async throws -> Double? {
        guard let hrvService = hrvService else {
            throw HealthKitError.notAvailable
        }
        return try await hrvService.getHRVBaseline(days: days)
    }

    // MARK: - Sleep Methods (delegated to SleepService)

    /// Fetch sleep data for a specific date (previous night's sleep)
    /// - Parameter date: The date to fetch sleep for (looks at sleep ending on this date)
    /// - Returns: SleepData with breakdown by stage, or nil if not available
    func fetchSleepData(for date: Date) async throws -> SleepData? {
        guard let sleepService = sleepService else {
            throw HealthKitError.notAvailable
        }
        return try await sleepService.fetchSleepData(for: date)
    }

    // MARK: - Activity Methods (delegated to ActivityService)

    /// Fetch resting heart rate for a specific date
    /// - Parameter date: The date to fetch RHR for
    /// - Returns: Resting heart rate in BPM, or nil if not available
    func fetchRestingHeartRate(for date: Date) async throws -> Double? {
        guard let activityService = activityService else {
            throw HealthKitError.notAvailable
        }
        return try await activityService.fetchRestingHeartRate(for: date)
    }

    /// Fetch oxygen saturation for a specific date
    /// - Parameter date: The date to fetch oxygen saturation for
    /// - Returns: Oxygen saturation percentage (0-100), or nil if not available
    func fetchOxygenSaturation(for date: Date) async throws -> Double? {
        guard let activityService = activityService else {
            throw HealthKitError.notAvailable
        }
        return try await activityService.fetchOxygenSaturation(for: date)
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
        let suggestedEnergy = hrvService?.calculateSuggestedEnergyLevel(currentHRV: hrv, baseline: baseline)

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

    // MARK: - Workout Export (ACP-827) (delegated to WorkoutExportService)

    /// Export a completed workout session to Apple Health
    /// - Parameter session: The completed session with timing and metrics
    /// - Returns: The HKWorkout that was saved to HealthKit
    /// - Throws: HealthKitError if HealthKit is not available or save fails
    @discardableResult
    func exportWorkout(session: Session) async throws -> HKWorkout {
        guard let workoutExportService = workoutExportService else {
            throw HealthKitError.notAvailable
        }

        let workout = try await workoutExportService.exportWorkout(session: session)
        lastExportDate = Date()
        exportedWorkoutsCount += 1
        return workout
    }

    /// Export a completed manual workout session to Apple Health
    /// - Parameter session: The completed manual session
    /// - Returns: The HKWorkout that was saved to HealthKit
    /// - Throws: HealthKitError if HealthKit is not available or save fails
    @discardableResult
    func exportManualWorkout(session: ManualSession) async throws -> HKWorkout {
        guard let workoutExportService = workoutExportService else {
            throw HealthKitError.notAvailable
        }

        let workout = try await workoutExportService.exportManualWorkout(session: session)
        lastExportDate = Date()
        exportedWorkoutsCount += 1
        return workout
    }

    /// Check if a workout was already exported to HealthKit
    /// Prevents duplicate exports by checking metadata
    /// - Parameter sessionId: The PTPerformance session ID
    /// - Returns: True if workout with this session ID exists in HealthKit
    func isWorkoutExported(sessionId: UUID) async throws -> Bool {
        guard let workoutExportService = workoutExportService else {
            throw HealthKitError.notAvailable
        }
        return try await workoutExportService.isWorkoutExported(sessionId: sessionId)
    }

    /// Fetch recent workouts exported from PTPerformance
    /// - Parameter limit: Maximum number of workouts to fetch
    /// - Returns: Array of exported workouts with metadata
    func fetchExportedWorkouts(limit: Int = 10) async throws -> [HKWorkout] {
        guard let workoutExportService = workoutExportService else {
            throw HealthKitError.notAvailable
        }
        return try await workoutExportService.fetchExportedWorkouts(limit: limit)
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
