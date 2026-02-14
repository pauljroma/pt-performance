import Foundation
import HealthKit

// MARK: - HealthKit Wearable Adapter

/// Adapter that wraps the existing `HealthKitService` to conform to the
/// `WearableProvider` protocol, enabling unified multi-wearable management
/// for Apple Watch data.
///
/// This class uses the Adapter pattern -- it delegates all queries to the
/// underlying `HealthKitService` (which itself coordinates `HRVService`,
/// `SleepService`, and `ActivityService`) and translates HealthKit data
/// into the shared `WearableRecoveryData` format.
///
/// ## Authorization
/// Apple HealthKit uses iOS system permissions rather than OAuth.
/// Authorization is requested via `HKHealthStore.requestAuthorization`
/// and cannot be programmatically revoked (only the user can do this
/// in Settings > Privacy > Health).
///
/// ## Data Characteristics
/// - Apple Watch provides HRV as SDNN (not RMSSD like WHOOP)
/// - Sleep stages require iOS 16+ for granular breakdown
/// - Resting heart rate is a daily computed value
/// - No explicit "recovery score" -- estimated from HRV baseline deviation
@MainActor
class HealthKitWearableAdapter: WearableProvider {

    // MARK: - WearableProvider Properties

    var type: WearableType { .appleWatch }

    var isConnected: Bool {
        return healthKitService.isAuthorized
    }

    var lastSyncDate: Date? {
        return healthKitService.lastSyncDate
    }

    // MARK: - Private Properties

    private let healthKitService: HealthKitService
    private let logger = DebugLogger.shared
    private let errorLogger = ErrorLogger.shared

    // MARK: - Initialization

    /// Create a HealthKit adapter wrapping the shared `HealthKitService` singleton.
    ///
    /// - Parameter healthKitService: The `HealthKitService` instance to delegate to.
    ///   Defaults to `HealthKitService.shared`.
    init(healthKitService: HealthKitService = .shared) {
        self.healthKitService = healthKitService
    }

    // MARK: - WearableProvider Methods

    /// Request HealthKit authorization for all required data types.
    ///
    /// Presents the iOS system HealthKit permission sheet requesting access
    /// to HRV, sleep analysis, resting heart rate, active energy, exercise
    /// time, step count, oxygen saturation, and workout write permissions.
    ///
    /// - Throws: `WearableError.authorizationFailed` if HealthKit is not
    ///   available on this device or the permission request fails/is denied.
    func authorize() async throws {
        logger.log("[HealthKitWearableAdapter] Requesting HealthKit authorization", level: .diagnostic)

        guard HealthKitService.isHealthKitAvailable else {
            throw WearableError.authorizationFailed(
                "HealthKit is not available on this device"
            )
        }

        do {
            let authorized = try await healthKitService.requestAuthorization()

            if !authorized {
                throw WearableError.authorizationFailed(
                    "HealthKit permission was denied. Please grant access in Settings > Privacy & Security > Health."
                )
            }

            logger.log("[HealthKitWearableAdapter] HealthKit authorization granted", level: .success)
        } catch let error as WearableError {
            throw error
        } catch {
            errorLogger.logError(error, context: "HealthKitWearableAdapter.authorize")
            throw WearableError.authorizationFailed(
                "HealthKit authorization error: \(error.localizedDescription)"
            )
        }
    }

    /// Mark the HealthKit connection as inactive.
    ///
    /// - Important: iOS does not allow apps to programmatically revoke HealthKit
    ///   permissions. The user must go to Settings > Privacy & Security > Health
    ///   to remove access. This method is provided for protocol conformance and
    ///   logs a warning to that effect.
    func disconnect() async throws {
        logger.log("[HealthKitWearableAdapter] Disconnect requested", level: .diagnostic)

        // HealthKit permissions cannot be revoked programmatically.
        // We log the request. The WearableConnectionManager can update
        // its internal state to treat this provider as "inactive" even
        // though HealthKit access technically persists at the OS level.
        logger.log(
            "[HealthKitWearableAdapter] Note: HealthKit permissions cannot be revoked programmatically. "
            + "User must disable access in Settings > Privacy & Security > Health.",
            level: .warning
        )
    }

    /// Fetch today's recovery data from HealthKit.
    ///
    /// Aggregates HRV (SDNN), sleep data (including stage breakdown),
    /// resting heart rate, and oxygen saturation from HealthKit to produce
    /// a unified `WearableRecoveryData`. Since Apple Watch does not provide
    /// an explicit recovery score, one is estimated from HRV deviation
    /// against a 7-day baseline.
    ///
    /// - Returns: `WearableRecoveryData` populated with Apple Watch metrics.
    /// - Throws: `WearableError.authorizationFailed` if HealthKit is not available,
    ///   `WearableError.notConnected` if not authorized,
    ///   `WearableError.noDataAvailable` if no health data is found.
    func fetchRecoveryData() async throws -> WearableRecoveryData {
        return try await fetchRecoveryData(for: Date())
    }

    /// Fetch recovery data for a specific date from HealthKit.
    ///
    /// - Important: Apple Watch provides HRV as **SDNN** (Standard Deviation of NN intervals),
    ///   not **RMSSD** (Root Mean Square of Successive Differences) like WHOOP and Oura.
    ///   SDNN and RMSSD measure different aspects of heart rate variability and are not
    ///   directly interchangeable. Downstream consumers (e.g., ReadinessService) should be
    ///   aware that `hrvMilliseconds` from this adapter represents SDNN. The `rawData`
    ///   dictionary includes `hrv_type: "SDNN"` to make this explicit.
    ///
    /// - Parameter date: The date to retrieve recovery data for.
    /// - Returns: `WearableRecoveryData` for the specified date.
    /// - Throws: `WearableError` on platform, connection, or data availability issues.
    func fetchRecoveryData(for date: Date) async throws -> WearableRecoveryData {
        logger.log("[HealthKitWearableAdapter] Fetching recovery data for \(date)", level: .diagnostic)

        guard HealthKitService.isHealthKitAvailable else {
            throw WearableError.authorizationFailed("HealthKit is not available on this device")
        }

        guard isConnected else {
            throw WearableError.notConnected(.appleWatch)
        }

        do {
            // Fetch all metrics in parallel, logging individual failures
            async let hrvTask = healthKitService.fetchHRV(for: date)
            async let sleepTask = healthKitService.fetchSleepData(for: date)
            async let rhrTask = healthKitService.fetchRestingHeartRate(for: date)
            async let spo2Task = healthKitService.fetchOxygenSaturation(for: date)
            async let baselineTask = healthKitService.getHRVBaseline(days: 7)

            var hrv: Double?
            do { hrv = try await hrvTask } catch {
                logger.log("[HealthKitWearableAdapter] HRV fetch failed: \(error.localizedDescription)", level: .warning)
            }
            var sleep: SleepData?
            do { sleep = try await sleepTask } catch {
                logger.log("[HealthKitWearableAdapter] Sleep fetch failed: \(error.localizedDescription)", level: .warning)
            }
            var rhr: Double?
            do { rhr = try await rhrTask } catch {
                logger.log("[HealthKitWearableAdapter] Resting HR fetch failed: \(error.localizedDescription)", level: .warning)
            }
            var spo2: Double?
            do { spo2 = try await spo2Task } catch {
                logger.log("[HealthKitWearableAdapter] SpO2 fetch failed: \(error.localizedDescription)", level: .warning)
            }
            var baseline: Double?
            do { baseline = try await baselineTask } catch {
                logger.log("[HealthKitWearableAdapter] HRV baseline fetch failed: \(error.localizedDescription)", level: .warning)
            }

            // Verify we have at least some data
            guard hrv != nil || sleep != nil || rhr != nil else {
                throw WearableError.noDataAvailable
            }

            let data = mapToRecoveryData(
                date: date,
                hrv: hrv,
                sleep: sleep,
                restingHeartRate: rhr,
                spo2: spo2,
                hrvBaseline: baseline
            )

            logger.log("[HealthKitWearableAdapter] Recovery data fetched successfully", level: .success)
            return data
        } catch let error as WearableError {
            throw error
        } catch {
            errorLogger.logError(error, context: "HealthKitWearableAdapter.fetchRecoveryData(for:)")
            throw WearableError.fetchFailed("HealthKit query error: \(error.localizedDescription)")
        }
    }

    /// Validate that the HealthKit connection is active and data is accessible.
    ///
    /// Performs an actual data query to verify that HealthKit authorization
    /// is still valid and data can be read (since iOS does not allow checking
    /// read permission status directly for privacy reasons).
    ///
    /// - Returns: `true` if HealthKit is available and authorized.
    func validateConnection() async throws -> Bool {
        logger.log("[HealthKitWearableAdapter] Validating connection", level: .diagnostic)

        guard HealthKitService.isHealthKitAvailable else {
            return false
        }

        let verified = await healthKitService.verifyConnection()

        if verified {
            logger.log("[HealthKitWearableAdapter] Connection validated successfully", level: .success)
        } else {
            logger.log("[HealthKitWearableAdapter] Connection validation failed", level: .warning)
        }

        return verified
    }

    // MARK: - Private Helpers

    /// Map HealthKit data to the shared `WearableRecoveryData` format.
    ///
    /// - Parameters:
    ///   - date: The date for the recovery data.
    ///   - hrv: HRV value in milliseconds (SDNN from Apple Watch).
    ///   - sleep: Sleep data with stage breakdown.
    ///   - restingHeartRate: Resting heart rate in BPM.
    ///   - spo2: Blood oxygen saturation percentage (0-100).
    ///   - hrvBaseline: 7-day rolling average HRV for recovery estimation.
    /// - Returns: A `WearableRecoveryData` instance populated from HealthKit metrics.
    private func mapToRecoveryData(
        date: Date,
        hrv: Double?,
        sleep: SleepData?,
        restingHeartRate: Double?,
        spo2: Double?,
        hrvBaseline: Double?
    ) -> WearableRecoveryData {
        // Calculate sleep quality from efficiency, clamped to 0-100 scale
        let sleepQuality: Double?
        if let efficiency = sleep?.sleepEfficiency {
            sleepQuality = min(100, max(0, efficiency))
        } else {
            sleepQuality = nil
        }

        // Estimate a recovery score from HRV deviation (Apple Watch has no native score)
        let estimatedRecoveryScore = estimateRecoveryScore(currentHRV: hrv, baseline: hrvBaseline)

        // Build rawData for Apple Watch-specific fields not in the standard format
        var rawData: [String: AnyCodableValue] = [:]
        rawData["hrv_type"] = .string("SDNN")  // Apple Watch uses SDNN, not RMSSD
        if let spo2 = spo2 {
            rawData["spo2_percentage"] = .double(spo2)
        }
        if let coreMinutes = sleep?.coreMinutes {
            rawData["core_sleep_minutes"] = .int(coreMinutes)
        }
        if let awakeMinutes = sleep?.awakeMinutes {
            rawData["awake_minutes"] = .int(awakeMinutes)
        }
        if let inBedMinutes = sleep?.inBedMinutes {
            rawData["in_bed_minutes"] = .int(inBedMinutes)
        }
        if let hrvBaseline = hrvBaseline {
            rawData["hrv_baseline_7day"] = .double(hrvBaseline)
        }

        return WearableRecoveryData(
            source: .appleWatch,
            recoveryScore: estimatedRecoveryScore,
            hrvMilliseconds: hrv,
            restingHeartRate: restingHeartRate,
            sleepHours: sleep?.totalHours,
            sleepQuality: sleepQuality,
            deepSleepMinutes: sleep?.deepMinutes.map { Double($0) },
            remSleepMinutes: sleep?.remMinutes.map { Double($0) },
            strain: nil,  // Apple Watch does not have a strain metric
            recordedAt: date,
            rawData: rawData.isEmpty ? nil : rawData
        )
    }

    /// Estimate a 0-100 recovery score from HRV deviation against baseline.
    ///
    /// Apple Watch does not provide a native recovery score like WHOOP.
    /// This method estimates one using the percentage deviation of today's
    /// HRV from the 7-day rolling average baseline:
    ///
    /// - HRV at baseline -> 60% (moderate recovery)
    /// - HRV 20%+ above baseline -> up to 100% (excellent recovery)
    /// - HRV 20%+ below baseline -> down to 20% (poor recovery)
    ///
    /// - Parameters:
    ///   - currentHRV: Today's HRV measurement (SDNN, ms).
    ///   - baseline: 7-day rolling average HRV.
    /// - Returns: Estimated recovery score (0-100), or `nil` if insufficient data.
    private func estimateRecoveryScore(currentHRV: Double?, baseline: Double?) -> Double? {
        guard let hrv = currentHRV, let base = baseline, base > 0 else {
            return nil
        }

        let deviationPercent = ((hrv - base) / base) * 100.0

        // Map deviation to a 0-100 recovery score
        // Baseline (0% deviation) = 60 points
        // +20% deviation = 100 points (capped)
        // -20% deviation = 20 points (floored)
        let baseScore = 60.0
        let scaledDeviation = deviationPercent * 2.0  // 1% HRV deviation = 2 recovery points
        let rawScore = baseScore + scaledDeviation

        return min(100.0, max(0.0, rawScore))
    }
}
