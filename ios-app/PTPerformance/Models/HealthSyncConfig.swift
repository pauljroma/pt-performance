//
//  HealthSyncConfig.swift
//  PTPerformance
//
//  ACP-827: Apple Health Deep Sync Configuration
//  Stores user preferences for bidirectional health data sync
//

import Foundation

/// Sync frequency options for health data synchronization
enum SyncFrequency: String, Codable, CaseIterable {
    case realtime = "realtime"
    case hourly = "hourly"
    case daily = "daily"
    case manual = "manual"

    var displayName: String {
        switch self {
        case .realtime: return "Real-time"
        case .hourly: return "Hourly"
        case .daily: return "Daily"
        case .manual: return "Manual Only"
        }
    }

    var description: String {
        switch self {
        case .realtime: return "Sync immediately when data changes"
        case .hourly: return "Sync every hour in the background"
        case .daily: return "Sync once per day"
        case .manual: return "Only sync when you request it"
        }
    }

    /// Background task interval in seconds (nil for realtime/manual)
    var backgroundInterval: TimeInterval? {
        switch self {
        case .realtime: return nil
        case .hourly: return 3600
        case .daily: return 86400
        case .manual: return nil
        }
    }
}

/// Configuration for Apple Health bidirectional sync
/// Stored in UserDefaults for persistence
struct HealthSyncConfig: Codable, Equatable {

    // MARK: - Export Settings (Write to Apple Health)

    /// Export completed workouts to Apple Health
    var exportWorkouts: Bool = true

    /// Export workout immediately after completion
    var exportOnCompletion: Bool = true

    // MARK: - Import Settings (Read from Apple Health)

    /// Import sleep data from Apple Health
    var importSleep: Bool = true

    /// Import HRV data from Apple Health
    var importHRV: Bool = true

    /// Import resting heart rate from Apple Health
    var importRestingHR: Bool = true

    /// Import active energy burned from Apple Health
    var importActiveEnergy: Bool = true

    /// Import exercise minutes from Apple Health
    var importExerciseMinutes: Bool = true

    /// Import step count from Apple Health
    var importStepCount: Bool = true

    // MARK: - Sync Settings

    /// How often to sync data in background
    var syncFrequency: SyncFrequency = .realtime

    /// Whether background sync is enabled
    var backgroundSyncEnabled: Bool = true

    /// Sync on app launch
    var syncOnLaunch: Bool = true

    // MARK: - Persistence

    private static let userDefaultsKey = "PTPerformance.HealthSyncConfig"

    /// Load configuration from UserDefaults
    static func load() -> HealthSyncConfig {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let config = try? JSONDecoder().decode(HealthSyncConfig.self, from: data) else {
            return HealthSyncConfig()
        }
        return config
    }

    /// Save configuration to UserDefaults
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        }
    }

    /// Reset to default configuration
    mutating func reset() {
        self = HealthSyncConfig()
        save()
    }

    // MARK: - Computed Properties

    /// Check if any import options are enabled
    var hasAnyImportEnabled: Bool {
        importSleep || importHRV || importRestingHR ||
        importActiveEnergy || importExerciseMinutes || importStepCount
    }

    /// Check if any export options are enabled
    var hasAnyExportEnabled: Bool {
        exportWorkouts
    }

    /// Check if sync is fully disabled
    var isSyncDisabled: Bool {
        !hasAnyImportEnabled && !hasAnyExportEnabled
    }

    /// Summary of enabled import types
    var enabledImportTypes: [String] {
        var types: [String] = []
        if importSleep { types.append("Sleep") }
        if importHRV { types.append("HRV") }
        if importRestingHR { types.append("Resting HR") }
        if importActiveEnergy { types.append("Active Energy") }
        if importExerciseMinutes { types.append("Exercise Time") }
        if importStepCount { types.append("Steps") }
        return types
    }

    /// Summary of enabled export types
    var enabledExportTypes: [String] {
        var types: [String] = []
        if exportWorkouts { types.append("Workouts") }
        return types
    }
}

// MARK: - Preview Support

#if DEBUG
extension HealthSyncConfig {
    /// Sample configuration for previews
    static var sample: HealthSyncConfig {
        var config = HealthSyncConfig()
        config.exportWorkouts = true
        config.importSleep = true
        config.importHRV = true
        config.syncFrequency = .realtime
        return config
    }

    /// Minimal configuration for testing
    static var minimal: HealthSyncConfig {
        var config = HealthSyncConfig()
        config.exportWorkouts = false
        config.importSleep = true
        config.importHRV = false
        config.importRestingHR = false
        config.importActiveEnergy = false
        config.importExerciseMinutes = false
        config.importStepCount = false
        config.syncFrequency = .manual
        config.backgroundSyncEnabled = false
        return config
    }
}
#endif
