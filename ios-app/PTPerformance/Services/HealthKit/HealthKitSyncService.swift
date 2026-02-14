//
//  HealthKitSyncService.swift
//  PTPerformance
//
//  ACP-474: HealthKit to Supabase Sync Service
//  Pushes aggregated HealthKit data to the sync-healthkit-data Edge Function
//  for storage in readiness_metrics table.
//
//  Unlike WHOOP (where the server pulls via OAuth), HealthKit data lives
//  on-device, so this service pushes data from iOS to Supabase.
//

import Foundation
import Supabase

// MARK: - Edge Function Request/Response Models

/// Payload sent to the sync-healthkit-data Edge Function
/// Matches the HealthKitPayload interface in the Edge Function
private struct HealthKitSyncPayload: Codable {
    let patientId: String
    let recordedAt: String
    let metricDate: String
    let hrvMs: Double?
    let restingHeartRate: Double?
    let sleepHours: Double?
    let deepSleepMinutes: Int?
    let remSleepMinutes: Int?
    let lightSleepMinutes: Int?
    let activeEnergyKcal: Double?
    let steps: Int?
    let workoutMinutes: Int?
    let deviceName: String?

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case recordedAt = "recorded_at"
        case metricDate = "metric_date"
        case hrvMs = "hrv_ms"
        case restingHeartRate = "resting_heart_rate"
        case sleepHours = "sleep_hours"
        case deepSleepMinutes = "deep_sleep_minutes"
        case remSleepMinutes = "rem_sleep_minutes"
        case lightSleepMinutes = "light_sleep_minutes"
        case activeEnergyKcal = "active_energy_kcal"
        case steps
        case workoutMinutes = "workout_minutes"
        case deviceName = "device_name"
    }
}

/// Response from the sync-healthkit-data Edge Function
struct HealthKitSyncResponse: Codable {
    let success: Bool
    let cached: Bool?
    let message: String?
    let data: SyncResponseData?

    struct SyncResponseData: Codable {
        let recoveryScore: Double?
        let hrvScore: Double?
        let sleepScore: Double?
        let syncedAt: String?

        enum CodingKeys: String, CodingKey {
            case recoveryScore = "recovery_score"
            case hrvScore = "hrv_score"
            case sleepScore = "sleep_score"
            case syncedAt = "synced_at"
        }
    }
}

// MARK: - HealthKitSyncService

/// Syncs local HealthKit data to Supabase readiness_metrics table
/// via the sync-healthkit-data Edge Function.
///
/// Coordinates between HealthKitService (on-device data) and Supabase (cloud storage).
/// Handles throttling, backfill, and auto-sync on app foreground.
///
/// ## Usage
/// ```swift
/// let syncService = HealthKitSyncService.shared
/// try await syncService.syncToday(patientId: myPatientId)
/// ```
///
/// ## Thread Safety
/// Marked `@MainActor` for safe UI state updates. All sync operations are async.
@MainActor
class HealthKitSyncService: ObservableObject {

    // MARK: - Singleton

    static let shared = HealthKitSyncService()

    // MARK: - Published Properties

    /// Date of the last successful sync
    @Published var lastSyncDate: Date?

    /// Whether a sync operation is currently in progress
    @Published var isSyncing = false

    /// Last recovery score returned from the Edge Function
    @Published var lastRecoveryScore: Double?

    /// Error message from the last failed sync attempt
    @Published var error: String?

    // MARK: - Private Properties

    private let healthKitService: HealthKitService
    private let supabase: PTSupabaseClient
    private let logger = DebugLogger.shared
    private let errorLogger = ErrorLogger.shared

    /// UserDefaults key for persisting last sync date
    private static let lastSyncDateKey = "PTPerformance.HealthKitSyncService.lastSyncDate"

    /// Throttle interval for auto-sync (1 hour)
    private static let syncThrottleInterval: TimeInterval = 3600

    // MARK: - Initialization

    private init() {
        self.healthKitService = HealthKitService.shared
        self.supabase = PTSupabaseClient.shared

        // Restore last sync date from UserDefaults
        if let storedDate = UserDefaults.standard.object(forKey: Self.lastSyncDateKey) as? Date {
            self.lastSyncDate = storedDate
        }
    }

    /// Initializer for dependency injection (testing)
    init(healthKitService: HealthKitService, supabase: PTSupabaseClient) {
        self.healthKitService = healthKitService
        self.supabase = supabase

        if let storedDate = UserDefaults.standard.object(forKey: Self.lastSyncDateKey) as? Date {
            self.lastSyncDate = storedDate
        }
    }

    // MARK: - Public Methods

    /// Sync today's HealthKit data to Supabase via Edge Function
    ///
    /// Fetches all available health data from HealthKit for today,
    /// packages it into the Edge Function payload format, and pushes
    /// it to the sync-healthkit-data Edge Function.
    ///
    /// The Edge Function handles:
    /// - Cache checking (won't re-sync within 1 hour)
    /// - Recovery score calculation (HRV, sleep, RHR vs baseline)
    /// - Upsert into readiness_metrics
    ///
    /// - Parameter patientId: The patient UUID to associate the data with
    /// - Returns: The sync response from the Edge Function
    /// - Throws: HealthKitError or network errors
    @discardableResult
    func syncToday(patientId: UUID) async throws -> HealthKitSyncResponse {
        return try await syncDate(Date(), patientId: patientId)
    }

    /// Sync a specific date's HealthKit data to Supabase
    ///
    /// - Parameters:
    ///   - date: The date to sync data for
    ///   - patientId: The patient UUID to associate the data with
    /// - Returns: The sync response from the Edge Function
    /// - Throws: HealthKitError or network errors
    @discardableResult
    func syncDate(_ date: Date, patientId: UUID) async throws -> HealthKitSyncResponse {
        guard !isSyncing else {
            logger.log("[HealthKitSync] Sync already in progress, skipping", level: .warning)
            throw HealthKitError.queryFailed("Sync already in progress")
        }

        isSyncing = true
        error = nil
        defer { isSyncing = false }

        logger.log("[HealthKitSync] Starting sync for date: \(date)", level: .diagnostic)

        // 1. Fetch data from HealthKit sub-services in parallel with timezone normalization
        let isToday = Calendar.current.isDateInToday(date)

        // Normalize date to UTC for consistent storage
        let normalizedDate = normalizeToUTC(date)

        async let hrvTask: Double? = try? healthKitService.fetchHRV(for: date)
        async let sleepTask: SleepData? = try? healthKitService.fetchSleepData(for: date)
        async let rhrTask: Double? = try? healthKitService.fetchRestingHeartRate(for: date)
        async let stepsTask: Double = (try? healthKitService.fetchSteps(for: date)) ?? 0

        // Only fetch dayData for today — syncTodayData() always queries today's data,
        // so calling it for a historical date would mix data from wrong dates.
        let dayData: HealthKitDayData? = isToday ? try? await healthKitService.syncTodayData() : nil

        let hrv = await hrvTask
        let sleep = await sleepTask
        let rhr = await rhrTask
        let steps = await stepsTask

        // 2. Resolve sleep hours from individual fetch or dayData, avoiding force-unwraps
        let sleepHours: Double?
        if let sleepData = sleep {
            sleepHours = sleepData.totalHours
        } else if let dayDataSleepMinutes = dayData?.sleepDurationMinutes {
            sleepHours = Double(dayDataSleepMinutes) / 60.0
        } else {
            sleepHours = nil
        }

        // Resolve steps from dayData or individual fetch
        let resolvedSteps: Int? = dayData?.stepCount ?? (steps > 0 ? Int(steps) : nil)

        // 3. Detect data gaps and handle edge cases
        let hasAnyData = hrv != nil || sleep != nil || rhr != nil || resolvedSteps != nil
        if !hasAnyData {
            logger.log("[HealthKitSync] No data available for date: \(date). This may indicate a data gap.", level: .warning)
            // Continue syncing anyway to mark the date as "no data" in the backend
        }

        // 4. Package into payload matching Edge Function input with UTC-normalized date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")!
        let metricDate = dateFormatter.string(from: normalizedDate)

        let payload = HealthKitSyncPayload(
            patientId: patientId.uuidString,
            recordedAt: ISO8601DateFormatter().string(from: Date()),
            metricDate: metricDate,
            hrvMs: dayData?.hrvSDNN ?? hrv,
            restingHeartRate: dayData?.restingHeartRate ?? rhr,
            sleepHours: sleepHours,
            deepSleepMinutes: sleep?.deepMinutes ?? dayData?.sleepDeepMinutes,
            remSleepMinutes: sleep?.remMinutes ?? dayData?.sleepREMMinutes,
            lightSleepMinutes: sleep?.coreMinutes,  // Apple Watch "Core" sleep maps to light sleep
            activeEnergyKcal: dayData?.activeEnergyBurned,
            steps: resolvedSteps,
            workoutMinutes: dayData?.exerciseMinutes,
            deviceName: "Apple Watch"
        )

        // 5. Call sync-healthkit-data Edge Function
        let response = try await callSyncEdgeFunction(payload: payload)

        // 6. Update state
        lastSyncDate = Date()
        UserDefaults.standard.set(Date(), forKey: Self.lastSyncDateKey)

        if let score = response.data?.recoveryScore {
            lastRecoveryScore = score
        }

        logger.log("[HealthKitSync] Sync completed successfully. Recovery score: \(response.data?.recoveryScore?.description ?? "N/A")", level: .success)

        return response
    }

    // MARK: - Timezone Normalization

    /// Normalize a date to UTC to ensure consistent storage regardless of timezone
    /// This handles edge cases when users travel across timezones
    private func normalizeToUTC(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: TimeZone.current, from: date)
        var utcComponents = DateComponents()
        utcComponents.year = components.year
        utcComponents.month = components.month
        utcComponents.day = components.day
        utcComponents.timeZone = TimeZone(identifier: "UTC")

        return Calendar.current.date(from: utcComponents) ?? date
    }

    /// Backfill historical data for the last N days
    ///
    /// Fetches and syncs HealthKit data for each day in the range.
    /// Useful for initial setup or recovering from missed syncs.
    ///
    /// - Parameters:
    ///   - patientId: The patient UUID to associate the data with
    ///   - days: Number of days to backfill (default 7)
    /// - Returns: Number of days successfully synced
    /// - Throws: HealthKitError if HealthKit is not available
    @discardableResult
    func backfill(patientId: UUID, days: Int = 7) async throws -> Int {
        guard healthKitService.isAuthorized else {
            throw HealthKitError.notAuthorized
        }

        // Clamp days to a reasonable range to prevent excessive queries
        let safeDays = min(max(days, 0), 30)

        guard safeDays > 0 else {
            logger.log("[HealthKitSync] Backfill skipped: 0 days requested", level: .diagnostic)
            return 0
        }

        logger.log("[HealthKitSync] Starting backfill for \(safeDays) days", level: .diagnostic)

        isSyncing = true
        error = nil
        defer { isSyncing = false }

        let calendar = Calendar.current
        var successCount = 0

        for dayOffset in 0..<safeDays {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else {
                continue
            }

            do {
                // Temporarily allow syncing without the isSyncing guard
                // by calling the internal method directly
                let _ = try await syncDateInternal(date, patientId: patientId)
                successCount += 1
                logger.log("[HealthKitSync] Backfill day \(dayOffset + 1)/\(safeDays) synced", level: .diagnostic)
            } catch {
                // Log but continue backfilling other days
                logger.log("[HealthKitSync] Backfill day \(dayOffset + 1)/\(safeDays) failed: \(error.localizedDescription)", level: .warning)
            }
        }

        lastSyncDate = Date()
        UserDefaults.standard.set(Date(), forKey: Self.lastSyncDateKey)

        logger.log("[HealthKitSync] Backfill completed: \(successCount)/\(safeDays) days synced", level: .success)
        return successCount
    }

    /// Auto-sync on app foreground, throttled to once per hour
    ///
    /// Call this from ScenePhase changes or AppDelegate lifecycle.
    /// Will silently skip if:
    /// - Sync was performed within the last hour
    /// - HealthKit is not authorized
    /// - No authenticated user
    ///
    /// - Parameter patientId: The patient UUID to associate the data with
    func autoSyncIfNeeded(patientId: UUID) async {
        guard shouldSync() else {
            logger.log("[HealthKitSync] Auto-sync skipped (throttled)", level: .diagnostic)
            return
        }

        guard healthKitService.isAuthorized || healthKitService.checkAuthorizationStatus() else {
            logger.log("[HealthKitSync] Auto-sync skipped (not authorized)", level: .diagnostic)
            return
        }

        do {
            try await syncToday(patientId: patientId)
        } catch {
            // Auto-sync failures are non-critical
            logger.log("[HealthKitSync] Auto-sync failed: \(error.localizedDescription)", level: .warning)
        }
    }

    // MARK: - Private Methods

    /// Check if enough time has passed since the last sync
    /// - Returns: True if we should sync (last sync was more than 1 hour ago, or never)
    private func shouldSync() -> Bool {
        guard let last = lastSyncDate else { return true }
        return Date().timeIntervalSince(last) > Self.syncThrottleInterval
    }

    /// Internal sync method that skips the isSyncing guard (for backfill)
    private func syncDateInternal(_ date: Date, patientId: UUID) async throws -> HealthKitSyncResponse {
        // Fetch data from HealthKit
        let hrv = try? await healthKitService.fetchHRV(for: date)
        let sleep = try? await healthKitService.fetchSleepData(for: date)
        let rhr = try? await healthKitService.fetchRestingHeartRate(for: date)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let metricDate = dateFormatter.string(from: date)

        let payload = HealthKitSyncPayload(
            patientId: patientId.uuidString,
            recordedAt: ISO8601DateFormatter().string(from: Date()),
            metricDate: metricDate,
            hrvMs: hrv,
            restingHeartRate: rhr,
            sleepHours: sleep?.totalHours,
            deepSleepMinutes: sleep?.deepMinutes,
            remSleepMinutes: sleep?.remMinutes,
            lightSleepMinutes: sleep?.coreMinutes,
            activeEnergyKcal: nil,  // Simplified for backfill
            steps: nil,
            workoutMinutes: nil,
            deviceName: "Apple Watch"
        )

        return try await callSyncEdgeFunction(payload: payload)
    }

    /// Call the sync-healthkit-data Edge Function
    ///
    /// Uses the same pattern as ExerciseSubstitutionService and registerPatient:
    /// JSONSerialization for the body, FunctionInvokeOptions for the call.
    ///
    /// - Parameter payload: The HealthKitSyncPayload to send
    /// - Returns: Decoded HealthKitSyncResponse
    /// - Throws: Network or decoding errors
    private func callSyncEdgeFunction(payload: HealthKitSyncPayload) async throws -> HealthKitSyncResponse {
        let encoder = JSONEncoder()
        let bodyData = try encoder.encode(payload)

        #if DEBUG
        if let bodyString = String(data: bodyData, encoding: .utf8) {
            logger.log("[HealthKitSync] Edge function request: \(bodyString)", level: .diagnostic)
        }
        #endif

        let responseDataRaw: Data = try await supabase.client.functions.invoke(
            "sync-healthkit-data",
            options: FunctionInvokeOptions(body: bodyData)
        ) { data, _ in
            data
        }

        #if DEBUG
        if let responseString = String(data: responseDataRaw, encoding: .utf8) {
            logger.log("[HealthKitSync] Edge function response: \(responseString)", level: .diagnostic)
        }
        #endif

        let decoder = JSONDecoder()
        let response = try decoder.decode(HealthKitSyncResponse.self, from: responseDataRaw)

        if !response.success {
            let message = response.message ?? "Unknown sync error"
            error = message
            errorLogger.logError(
                HealthKitError.saveFailed(message),
                context: "HealthKitSyncService.callSyncEdgeFunction"
            )
            throw HealthKitError.saveFailed(message)
        }

        return response
    }
}

// MARK: - Convenience Extensions

extension HealthKitSyncService {
    /// Formatted string for last sync time
    var lastSyncText: String {
        guard let date = lastSyncDate else {
            return "Never synced"
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// Whether there is a recovery score available
    var hasRecoveryScore: Bool {
        lastRecoveryScore != nil
    }

    /// Recovery score formatted as percentage string
    var recoveryScoreText: String {
        guard let score = lastRecoveryScore else {
            return "--"
        }
        return "\(Int(score))%"
    }
}

// MARK: - Preview Support

#if DEBUG
extension HealthKitSyncService {
    /// Create a mock service for previews with sample data
    static var preview: HealthKitSyncService {
        let service = HealthKitSyncService()
        service.lastSyncDate = Date().addingTimeInterval(-1800) // 30 min ago
        service.lastRecoveryScore = 78.5
        service.isSyncing = false
        return service
    }
}
#endif
