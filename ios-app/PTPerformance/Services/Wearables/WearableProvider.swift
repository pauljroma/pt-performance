import Foundation
import SwiftUI

// MARK: - ACP-472: Multi-Wearable Integration Protocol Layer
// Defines the unified interface for all wearable device integrations.
// Each wearable (WHOOP, Oura, Apple Watch, Garmin) implements WearableProvider
// to provide standardized recovery/readiness data to the readiness system.

// MARK: - Wearable Type

/// Supported wearable device types for recovery and readiness data
enum WearableType: String, Codable, CaseIterable, Identifiable, Sendable {
    var id: String { rawValue }

    case whoop
    case oura
    case appleWatch = "apple_watch"
    case garmin

    /// Human-readable display name for UI
    var displayName: String {
        switch self {
        case .whoop: return "WHOOP"
        case .oura: return "Oura Ring"
        case .appleWatch: return "Apple Watch"
        case .garmin: return "Garmin"
        }
    }

    /// SF Symbol name for device icon
    var iconName: String {
        switch self {
        case .whoop: return "waveform.path.ecg"
        case .oura: return "circle.circle"
        case .appleWatch: return "applewatch"
        case .garmin: return "watch.analog"
        }
    }

    /// Whether the wearable requires OAuth flow for authorization.
    /// Apple Watch uses HealthKit permissions instead.
    var requiresOAuth: Bool {
        switch self {
        case .whoop, .oura, .garmin: return true
        case .appleWatch: return false
        }
    }

    /// Brand color associated with this wearable device for UI consistency.
    /// Eliminates duplicate color switch statements across view files.
    var brandColor: Color {
        switch self {
        case .whoop: return .blue
        case .oura: return .purple
        case .appleWatch: return .green
        case .garmin: return .orange
        }
    }

    /// Brief description of what data this wearable provides
    var dataDescription: String {
        switch self {
        case .whoop: return "Recovery score, HRV, strain, and sleep data"
        case .oura: return "Readiness score, HRV, sleep stages, and activity"
        case .appleWatch: return "HRV, sleep, resting heart rate, and activity"
        case .garmin: return "Body Battery, HRV, sleep, and stress data"
        }
    }
}

// MARK: - Wearable Recovery Data

/// Standardized recovery/readiness data output from any wearable device.
///
/// All wearable providers normalize their data into this common format
/// so the readiness system can process data uniformly regardless of source.
/// Scores are normalized to consistent scales:
/// - Recovery/quality scores: 0-100
/// - HRV: milliseconds (RMSSD)
/// - Heart rate: BPM
/// - Sleep: hours and minutes
/// - Strain: 0-21 (WHOOP scale, normalized for others)
struct WearableRecoveryData: Sendable {
    /// Source wearable device
    let source: WearableType

    /// Overall recovery/readiness score (0-100 normalized)
    let recoveryScore: Double?

    /// Heart rate variability in milliseconds (RMSSD)
    let hrvMilliseconds: Double?

    /// Resting heart rate in BPM
    let restingHeartRate: Double?

    /// Total sleep duration in hours
    let sleepHours: Double?

    /// Overall sleep quality score (0-100)
    let sleepQuality: Double?

    /// Deep/slow-wave sleep duration in minutes
    let deepSleepMinutes: Double?

    /// REM sleep duration in minutes
    let remSleepMinutes: Double?

    /// Day strain score (0-21, WHOOP scale; other devices normalized to this range)
    let strain: Double?

    /// When this data was recorded by the device
    let recordedAt: Date

    /// Provider-specific extra data not captured in standard fields.
    /// Examples: WHOOP skin temp, Oura temperature deviation, Garmin stress score.
    /// Stored as a dictionary for flexibility.
    let rawData: [String: AnyCodableValue]?
}

// NOTE: AnyCodableValue is defined in Models/SupabaseContentModels.swift
// and reused here for rawData dictionary values.

// MARK: - Wearable Connection

/// Represents a patient's connection to a wearable device.
/// Maps to the `wearable_connections` database table.
struct WearableConnection: Identifiable, Codable, Sendable {
    let id: UUID
    let patientId: UUID
    let wearableType: WearableType
    var isPrimary: Bool
    var isActive: Bool
    var connectedAt: Date
    var lastSyncAt: Date?
    var deviceMetadata: [String: String]?
    var syncConfig: WearableSyncConfig?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case wearableType = "wearable_type"
        case isPrimary = "is_primary"
        case isActive = "is_active"
        case connectedAt = "connected_at"
        case lastSyncAt = "last_sync_at"
        case deviceMetadata = "device_metadata"
        case syncConfig = "sync_config"
    }
}

/// Sync configuration for a wearable connection
struct WearableSyncConfig: Codable, Sendable {
    var autoSync: Bool
    var syncIntervalMinutes: Int

    enum CodingKeys: String, CodingKey {
        case autoSync = "auto_sync"
        case syncIntervalMinutes = "sync_interval_minutes"
    }

    /// Default sync configuration: auto-sync every 60 minutes
    static let `default` = WearableSyncConfig(autoSync: true, syncIntervalMinutes: 60)
}

// MARK: - Wearable Provider Protocol

/// Protocol that all wearable device integrations must conform to.
///
/// Each wearable (WHOOP, Oura, Apple Watch, Garmin) provides an implementation
/// that handles device-specific authentication, data fetching, and normalization.
/// The `WearableConnectionManager` coordinates across all registered providers.
///
/// ## Implementation Requirements
/// - `authorize()`: Begin the OAuth flow (or HealthKit permissions for Apple Watch)
/// - `disconnect()`: Revoke tokens, clear stored credentials
/// - `fetchRecoveryData()`: Return the latest normalized recovery data
/// - `validateConnection()`: Verify the current auth state is still valid
///
/// ## Thread Safety
/// All methods are async and may be called from any actor context.
/// Implementations should be thread-safe.
protocol WearableProvider: AnyObject {
    /// The wearable device type this provider handles
    var type: WearableType { get }

    /// Whether this provider currently has valid credentials/authorization
    var isConnected: Bool { get }

    /// Timestamp of the last successful data sync, if any
    var lastSyncDate: Date? { get }

    /// Begin the OAuth or authorization flow for this wearable.
    ///
    /// For OAuth-based wearables (WHOOP, Oura, Garmin), this initiates
    /// the OAuth 2.0 authorization code flow. For Apple Watch, this
    /// requests HealthKit permissions.
    ///
    /// - Throws: `WearableError.authorizationFailed` if the flow fails or is cancelled
    func authorize() async throws

    /// Disconnect from the wearable and revoke/clear stored tokens.
    ///
    /// After calling this, `isConnected` should return `false` and any
    /// stored credentials should be removed from the keychain.
    ///
    /// - Throws: `WearableError.disconnectionFailed` if cleanup fails
    func disconnect() async throws

    /// Fetch the latest recovery/readiness data from the wearable.
    ///
    /// Returns the most recent available data, typically from the current day
    /// or the most recently completed sleep cycle.
    ///
    /// - Returns: Normalized `WearableRecoveryData` with all available metrics
    /// - Throws: `WearableError.noDataAvailable` if no recent data exists,
    ///           `WearableError.fetchFailed` on API/query errors
    func fetchRecoveryData() async throws -> WearableRecoveryData

    /// Fetch recovery/readiness data for a specific date.
    ///
    /// - Parameter date: The date to fetch data for
    /// - Returns: Normalized `WearableRecoveryData` for the specified date
    /// - Throws: `WearableError.noDataAvailable` if no data exists for the date,
    ///           `WearableError.fetchFailed` on API/query errors
    func fetchRecoveryData(for date: Date) async throws -> WearableRecoveryData

    /// Validate that the current connection/authorization is still valid.
    ///
    /// For OAuth wearables, this checks token expiration and attempts a refresh
    /// if needed. For Apple Watch, this verifies HealthKit authorization status.
    ///
    /// - Returns: `true` if the connection is valid and data can be fetched
    /// - Throws: `WearableError.validationFailed` if the check itself fails
    func validateConnection() async throws -> Bool
}

// MARK: - Wearable Errors

/// Errors specific to wearable device integrations
enum WearableError: LocalizedError {
    /// OAuth or HealthKit authorization flow failed or was cancelled
    case authorizationFailed(String)
    /// Failed to disconnect or revoke tokens
    case disconnectionFailed(String)
    /// No recovery data available for the requested date
    case noDataAvailable
    /// API or query error during data fetch
    case fetchFailed(String)
    /// Connection validation check failed
    case validationFailed(String)
    /// The requested wearable type has no registered provider
    case providerNotRegistered(WearableType)
    /// No primary wearable is configured
    case noPrimaryWearable
    /// Token refresh failed
    case tokenRefreshFailed(String)
    /// The wearable is not connected
    case notConnected(WearableType)

    var errorDescription: String? {
        switch self {
        case .authorizationFailed(let message):
            return "Wearable Authorization Failed: \(message)"
        case .disconnectionFailed(let message):
            return "Wearable Disconnection Failed: \(message)"
        case .noDataAvailable:
            return "No Wearable Data Available"
        case .fetchFailed(let message):
            return "Wearable Data Fetch Failed: \(message)"
        case .validationFailed(let message):
            return "Wearable Validation Failed: \(message)"
        case .providerNotRegistered(let type):
            return "\(type.displayName) Provider Not Available"
        case .noPrimaryWearable:
            return "No Primary Wearable Configured"
        case .tokenRefreshFailed(let message):
            return "Token Refresh Failed: \(message)"
        case .notConnected(let type):
            return "\(type.displayName) Not Connected"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .authorizationFailed:
            return "Please try connecting your wearable again from Settings."
        case .disconnectionFailed:
            return "Please try disconnecting again. If the issue persists, sign out and back in."
        case .noDataAvailable:
            return "Make sure your wearable is synced and has recent data. Open the wearable's app to sync."
        case .fetchFailed:
            return "There was a problem fetching your wearable data. Please try again later."
        case .validationFailed:
            return "Your wearable connection may have expired. Please reconnect in Settings."
        case .providerNotRegistered(let type):
            return "\(type.displayName) integration is not yet available. It will be added in a future update."
        case .noPrimaryWearable:
            return "Connect a wearable device in Settings to enable automatic recovery tracking."
        case .tokenRefreshFailed:
            return "Please reconnect your wearable in Settings to refresh your authorization."
        case .notConnected(let type):
            return "Connect your \(type.displayName) in Settings to start syncing data."
        }
    }
}

// MARK: - WearableRecoveryData Convenience Extensions

extension WearableRecoveryData {
    /// Convert recovery data to a `BandCalculationInput` for the readiness system.
    ///
    /// Maps normalized wearable data into the input format expected by
    /// `ReadinessService.calculateReadinessBand(input:)`.
    func toBandCalculationInput() -> BandCalculationInput {
        // Convert sleep quality (0-100) to 1-5 scale
        let sleepQualityScale: Int?
        if let quality = sleepQuality {
            switch quality {
            case 85...: sleepQualityScale = 5
            case 70..<85: sleepQualityScale = 4
            case 50..<70: sleepQualityScale = 3
            case 30..<50: sleepQualityScale = 2
            default: sleepQualityScale = 1
            }
        } else {
            sleepQualityScale = nil
        }

        // Convert recovery score to WHOOP-compatible percentage
        let whoopPct: Int?
        if let score = recoveryScore {
            whoopPct = Int(score)
        } else {
            whoopPct = nil
        }

        return BandCalculationInput(
            sleepHours: sleepHours,
            sleepQuality: sleepQualityScale,
            hrvValue: hrvMilliseconds,
            whoopRecoveryPct: whoopPct,
            subjectiveReadiness: nil,  // Wearable data is objective; subjective is manual
            armSoreness: false,
            armSorenessSeverity: nil,
            jointPain: [],
            jointPainNotes: nil
        )
    }

    /// Returns true if this data has sufficient metrics for readiness calculation.
    /// At minimum, needs either a recovery score or HRV + sleep data.
    var hasSufficientData: Bool {
        if recoveryScore != nil { return true }
        if hrvMilliseconds != nil && sleepHours != nil { return true }
        return false
    }
}

// MARK: - Preview Support

#if DEBUG
extension WearableRecoveryData {
    /// Sample WHOOP recovery data for previews
    static var sampleWHOOP: WearableRecoveryData {
        WearableRecoveryData(
            source: .whoop,
            recoveryScore: 78,
            hrvMilliseconds: 65.5,
            restingHeartRate: 58,
            sleepHours: 7.5,
            sleepQuality: 82,
            deepSleepMinutes: 95,
            remSleepMinutes: 108,
            strain: 12.4,
            recordedAt: Date(),
            rawData: [
                "spo2_percentage": .double(97.5),
                "skin_temp_celsius": .double(33.2)
            ]
        )
    }

    /// Sample Apple Watch recovery data for previews
    static var sampleAppleWatch: WearableRecoveryData {
        WearableRecoveryData(
            source: .appleWatch,
            recoveryScore: nil,  // Apple Watch doesn't provide a recovery score
            hrvMilliseconds: 62.0,
            restingHeartRate: 56,
            sleepHours: 7.2,
            sleepQuality: 75,
            deepSleepMinutes: 88,
            remSleepMinutes: 95,
            strain: nil,
            recordedAt: Date(),
            rawData: [
                "step_count": .int(8500),
                "active_energy_burned": .double(450.0)
            ]
        )
    }

    /// Sample Oura recovery data for previews
    static var sampleOura: WearableRecoveryData {
        WearableRecoveryData(
            source: .oura,
            recoveryScore: 85,
            hrvMilliseconds: 72.0,
            restingHeartRate: 54,
            sleepHours: 8.1,
            sleepQuality: 88,
            deepSleepMinutes: 110,
            remSleepMinutes: 120,
            strain: nil,
            recordedAt: Date(),
            rawData: [
                "readiness_temperature_deviation": .double(-0.2),
                "readiness_previous_day_activity": .string("optimal")
            ]
        )
    }
}

extension WearableConnection {
    /// Sample WHOOP connection for previews
    static var sampleWHOOP: WearableConnection {
        WearableConnection(
            id: UUID(),
            patientId: UUID(),
            wearableType: .whoop,
            isPrimary: true,
            isActive: true,
            connectedAt: Date().addingTimeInterval(-86400 * 30),
            lastSyncAt: Date().addingTimeInterval(-3600),
            deviceMetadata: ["device_name": "WHOOP 4.0", "firmware_version": "4.0.2"],
            syncConfig: .default
        )
    }

    /// Sample Apple Watch connection for previews
    static var sampleAppleWatch: WearableConnection {
        WearableConnection(
            id: UUID(),
            patientId: UUID(),
            wearableType: .appleWatch,
            isPrimary: false,
            isActive: true,
            connectedAt: Date().addingTimeInterval(-86400 * 60),
            lastSyncAt: Date().addingTimeInterval(-1800),
            deviceMetadata: ["device_name": "Apple Watch Ultra 2", "firmware_version": "11.2"],
            syncConfig: .default
        )
    }
}
#endif
