//
//  HealthKitConflictResolver.swift
//  PTPerformance
//
//  ACP-1037: HealthKit Sync Reliability - Conflict Resolution
//  Handles conflicts between manual entries and HealthKit data
//

import Foundation
import HealthKit

// MARK: - Conflict Resolution Strategy

/// Strategy for resolving conflicts between manual and HealthKit data
enum HealthKitConflictStrategy {
    /// Prefer HealthKit for objective biometric data (HRV, HR, sleep)
    case preferHealthKit
    /// Prefer manual for subjective data (mood, perceived exertion)
    case preferManual
    /// Use most recent entry
    case mostRecent
    /// Average both values
    case average
    /// Keep both as separate entries
    case keepBoth
}

// MARK: - Conflict Data Types

/// Types of health data that can have conflicts
enum HealthDataType: String, CaseIterable {
    case hrv = "HRV"
    case restingHeartRate = "Resting Heart Rate"
    case sleep = "Sleep"
    case steps = "Steps"
    case activeEnergy = "Active Energy"
    case mood = "Mood"
    case perceivedExertion = "Perceived Exertion"
    case bodyWeight = "Body Weight"

    /// Recommended conflict resolution strategy for this data type
    var defaultStrategy: HealthKitConflictStrategy {
        switch self {
        case .hrv, .restingHeartRate, .sleep, .steps, .activeEnergy, .bodyWeight:
            // Objective biometric data - prefer HealthKit (more accurate sensors)
            return .preferHealthKit
        case .mood, .perceivedExertion:
            // Subjective data - prefer manual (user knows best)
            return .preferManual
        }
    }

    /// Whether this data type is objective (sensor-measured) or subjective (user-reported)
    var isObjective: Bool {
        switch self {
        case .hrv, .restingHeartRate, .sleep, .steps, .activeEnergy, .bodyWeight:
            return true
        case .mood, .perceivedExertion:
            return false
        }
    }
}

// MARK: - Conflict Detection Result

/// Result of conflict detection between manual and HealthKit data
struct HealthDataConflict: Identifiable {
    let id = UUID()
    let date: Date
    let dataType: HealthDataType
    let manualValue: Any?
    let healthKitValue: Any?
    let difference: Double?
    let significanceLevel: ConflictSignificance
    let recommendedStrategy: HealthKitConflictStrategy

    enum ConflictSignificance: String {
        case minor = "Minor"
        case moderate = "Moderate"
        case major = "Major"

        var color: String {
            switch self {
            case .minor: return "yellow"
            case .moderate: return "orange"
            case .major: return "red"
            }
        }
    }
}

// MARK: - HealthKit Conflict Resolver

/// Service for detecting and resolving conflicts between manual entries and HealthKit data
@MainActor
class HealthKitConflictResolver: ObservableObject {

    // MARK: - Singleton

    static let shared = HealthKitConflictResolver()

    // MARK: - Published State

    @Published var detectedConflicts: [HealthDataConflict] = []
    @Published var conflictResolutionHistory: [(date: Date, dataType: HealthDataType, strategy: HealthKitConflictStrategy)] = []

    // MARK: - Private Properties

    private let logger = DebugLogger.shared
    private let errorLogger = ErrorLogger.shared

    // MARK: - Conflict Detection Thresholds

    private struct ConflictThresholds {
        static let hrvMinorDiff: Double = 5.0      // 5ms
        static let hrvModerateDiff: Double = 10.0  // 10ms
        static let hrvMajorDiff: Double = 20.0     // 20ms

        static let rhrMinorDiff: Double = 3.0      // 3 bpm
        static let rhrModerateDiff: Double = 5.0   // 5 bpm
        static let rhrMajorDiff: Double = 10.0     // 10 bpm

        static let sleepMinorDiff: Double = 15.0   // 15 minutes
        static let sleepModerateDiff: Double = 30.0 // 30 minutes
        static let sleepMajorDiff: Double = 60.0   // 60 minutes

        static let stepsMinorDiff: Double = 500    // 500 steps
        static let stepsModerateDiff: Double = 1000 // 1000 steps
        static let stepsMajorDiff: Double = 2000   // 2000 steps
    }

    // MARK: - Initialization

    private init() {
        loadConflictHistory()
    }

    // MARK: - Conflict Detection

    /// Detect conflicts between manual and HealthKit data for a specific date
    /// - Parameters:
    ///   - date: The date to check for conflicts
    ///   - manualData: Manual entry data (if any)
    ///   - healthKitData: HealthKit data (if any)
    /// - Returns: Array of detected conflicts
    func detectConflicts(
        for date: Date,
        manualHRV: Double?,
        healthKitHRV: Double?,
        manualRHR: Double?,
        healthKitRHR: Double?,
        manualSleepMinutes: Int?,
        healthKitSleepMinutes: Int?,
        manualSteps: Int?,
        healthKitSteps: Int?
    ) -> [HealthDataConflict] {
        var conflicts: [HealthDataConflict] = []

        // HRV conflict detection
        if let manual = manualHRV, let healthKit = healthKitHRV {
            let diff = abs(manual - healthKit)
            if diff >= ConflictThresholds.hrvMinorDiff {
                let significance = significanceForHRV(difference: diff)
                conflicts.append(HealthDataConflict(
                    date: date,
                    dataType: .hrv,
                    manualValue: manual,
                    healthKitValue: healthKit,
                    difference: diff,
                    significanceLevel: significance,
                    recommendedStrategy: .preferHealthKit // HRV is objective
                ))
            }
        }

        // Resting Heart Rate conflict detection
        if let manual = manualRHR, let healthKit = healthKitRHR {
            let diff = abs(manual - healthKit)
            if diff >= ConflictThresholds.rhrMinorDiff {
                let significance = significanceForRHR(difference: diff)
                conflicts.append(HealthDataConflict(
                    date: date,
                    dataType: .restingHeartRate,
                    manualValue: manual,
                    healthKitValue: healthKit,
                    difference: diff,
                    significanceLevel: significance,
                    recommendedStrategy: .preferHealthKit // RHR is objective
                ))
            }
        }

        // Sleep conflict detection
        if let manual = manualSleepMinutes, let healthKit = healthKitSleepMinutes {
            let diff = abs(Double(manual - healthKit))
            if diff >= ConflictThresholds.sleepMinorDiff {
                let significance = significanceForSleep(difference: diff)
                conflicts.append(HealthDataConflict(
                    date: date,
                    dataType: .sleep,
                    manualValue: manual,
                    healthKitValue: healthKit,
                    difference: diff,
                    significanceLevel: significance,
                    recommendedStrategy: .preferHealthKit // Sleep is objective
                ))
            }
        }

        // Steps conflict detection
        if let manual = manualSteps, let healthKit = healthKitSteps {
            let diff = abs(Double(manual - healthKit))
            if diff >= ConflictThresholds.stepsMinorDiff {
                let significance = significanceForSteps(difference: diff)
                conflicts.append(HealthDataConflict(
                    date: date,
                    dataType: .steps,
                    manualValue: manual,
                    healthKitValue: healthKit,
                    difference: diff,
                    significanceLevel: significance,
                    recommendedStrategy: .preferHealthKit // Steps are objective
                ))
            }
        }

        if !conflicts.isEmpty {
            logger.log("[HealthKitConflictResolver] Detected \(conflicts.count) conflicts for \(date)", level: .warning)
            detectedConflicts.append(contentsOf: conflicts)
        }

        return conflicts
    }

    // MARK: - Conflict Resolution

    /// Resolve a conflict using the specified strategy
    /// - Parameters:
    ///   - conflict: The conflict to resolve
    ///   - strategy: The resolution strategy to use (defaults to recommended)
    /// - Returns: The resolved value
    func resolveConflict(_ conflict: HealthDataConflict, strategy: HealthKitConflictStrategy? = nil) -> Any? {
        let resolutionStrategy = strategy ?? conflict.recommendedStrategy

        logger.log("[HealthKitConflictResolver] Resolving \(conflict.dataType.rawValue) conflict using \(resolutionStrategy)", level: .diagnostic)

        let resolvedValue: Any?

        switch resolutionStrategy {
        case .preferHealthKit:
            resolvedValue = conflict.healthKitValue

        case .preferManual:
            resolvedValue = conflict.manualValue

        case .mostRecent:
            // In this implementation, HealthKit is typically more recent
            resolvedValue = conflict.healthKitValue

        case .average:
            resolvedValue = averageValues(conflict.manualValue, conflict.healthKitValue, dataType: conflict.dataType)

        case .keepBoth:
            // Return both values as a tuple
            resolvedValue = (manual: conflict.manualValue, healthKit: conflict.healthKitValue)
        }

        // Log the resolution
        recordConflictResolution(date: conflict.date, dataType: conflict.dataType, strategy: resolutionStrategy)

        return resolvedValue
    }

    /// Auto-resolve all detected conflicts using recommended strategies
    /// - Returns: Dictionary of data types to resolved values
    func autoResolveConflicts() -> [HealthDataType: Any] {
        var resolved: [HealthDataType: Any] = [:]

        for conflict in detectedConflicts {
            if let value = resolveConflict(conflict) {
                resolved[conflict.dataType] = value
            }
        }

        // Clear detected conflicts after resolution
        detectedConflicts.removeAll()

        logger.log("[HealthKitConflictResolver] Auto-resolved \(resolved.count) conflicts", level: .success)

        return resolved
    }

    // MARK: - Helper Methods

    private func significanceForHRV(difference: Double) -> HealthDataConflict.ConflictSignificance {
        if difference >= ConflictThresholds.hrvMajorDiff {
            return .major
        } else if difference >= ConflictThresholds.hrvModerateDiff {
            return .moderate
        } else {
            return .minor
        }
    }

    private func significanceForRHR(difference: Double) -> HealthDataConflict.ConflictSignificance {
        if difference >= ConflictThresholds.rhrMajorDiff {
            return .major
        } else if difference >= ConflictThresholds.rhrModerateDiff {
            return .moderate
        } else {
            return .minor
        }
    }

    private func significanceForSleep(difference: Double) -> HealthDataConflict.ConflictSignificance {
        if difference >= ConflictThresholds.sleepMajorDiff {
            return .major
        } else if difference >= ConflictThresholds.sleepModerateDiff {
            return .moderate
        } else {
            return .minor
        }
    }

    private func significanceForSteps(difference: Double) -> HealthDataConflict.ConflictSignificance {
        if difference >= ConflictThresholds.stepsMajorDiff {
            return .major
        } else if difference >= ConflictThresholds.stepsModerateDiff {
            return .moderate
        } else {
            return .minor
        }
    }

    private func averageValues(_ value1: Any?, _ value2: Any?, dataType: HealthDataType) -> Any? {
        guard let v1 = value1, let v2 = value2 else { return nil }

        switch dataType {
        case .hrv, .restingHeartRate:
            if let d1 = v1 as? Double, let d2 = v2 as? Double {
                return (d1 + d2) / 2.0
            }
        case .sleep, .steps, .activeEnergy:
            if let i1 = v1 as? Int, let i2 = v2 as? Int {
                return (i1 + i2) / 2
            }
        case .mood, .perceivedExertion, .bodyWeight:
            // These shouldn't be averaged
            return v1
        }

        return nil
    }

    private func recordConflictResolution(date: Date, dataType: HealthDataType, strategy: HealthKitConflictStrategy) {
        conflictResolutionHistory.append((date: date, dataType: dataType, strategy: strategy))
        saveConflictHistory()
    }

    // MARK: - Persistence

    private func loadConflictHistory() {
        // Load from UserDefaults if needed
        // For now, just initialize empty
    }

    private func saveConflictHistory() {
        // Save to UserDefaults if needed
        // For now, just keep in memory
    }

    // MARK: - Conflict Statistics

    /// Get statistics about conflict resolution
    func getConflictStatistics() -> (total: Int, byType: [HealthDataType: Int], byStrategy: [HealthKitConflictStrategy: Int]) {
        let total = conflictResolutionHistory.count

        var byType: [HealthDataType: Int] = [:]
        var byStrategy: [HealthKitConflictStrategy: Int] = [:]

        for (_, dataType, strategy) in conflictResolutionHistory {
            byType[dataType, default: 0] += 1
            byStrategy[strategy, default: 0] += 1
        }

        return (total: total, byType: byType, byStrategy: byStrategy)
    }
}

// MARK: - Extension: HealthKit Conflict Strategy Conformances

extension HealthKitConflictStrategy: CustomStringConvertible {
    var description: String {
        switch self {
        case .preferHealthKit:
            return "Prefer HealthKit Data"
        case .preferManual:
            return "Prefer Manual Entry"
        case .mostRecent:
            return "Use Most Recent"
        case .average:
            return "Average Both Values"
        case .keepBoth:
            return "Keep Both"
        }
    }
}
