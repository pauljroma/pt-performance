//
//  Mode.swift
//  PTPerformance
//
//  Mode system for 3-mode UX architecture
//

import Foundation

/// Patient training mode enum
/// Matches database patient_mode enum
enum Mode: String, Codable, CaseIterable, Hashable {
    case rehab = "rehab"
    case strength = "strength"
    case performance = "performance"

    /// Display name for UI
    var displayName: String {
        switch self {
        case .rehab:
            return "Rehab Mode"
        case .strength:
            return "Strength Mode"
        case .performance:
            return "Performance Mode"
        }
    }

    /// Mode description
    var description: String {
        switch self {
        case .rehab:
            return "Injury Recovery"
        case .strength:
            return "General Fitness"
        case .performance:
            return "Elite Athletes"
        }
    }

    /// Primary focus areas for this mode
    var primaryMetrics: [String] {
        switch self {
        case .rehab:
            return ["Pain Score", "ROM", "Function"]
        case .strength:
            return ["Volume", "Tonnage", "PRs"]
        case .performance:
            return ["Readiness", "Fatigue", "Load"]
        }
    }

    /// Icon system name for UI
    var iconName: String {
        switch self {
        case .rehab:
            return "cross.case.fill"  // Medical
        case .strength:
            return "dumbbell.fill"  // Strength
        case .performance:
            return "medal.fill"  // Performance
        }
    }
}

/// Patient mode info with history
struct PatientMode: Codable, Identifiable, Hashable, Equatable {
    let id: String
    let mode: Mode
    let modeChangedAt: Date?
    let modeChangedBy: String?  // Therapist ID

    enum CodingKeys: String, CodingKey {
        case id
        case mode
        case modeChangedAt = "mode_changed_at"
        case modeChangedBy = "mode_changed_by"
    }
}

/// Mode change history entry
struct ModeHistoryEntry: Codable, Identifiable, Hashable, Equatable {
    let id: String
    let patientId: String
    let previousMode: Mode?
    let newMode: Mode
    let changedBy: String  // Therapist ID
    let reason: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case previousMode = "previous_mode"
        case newMode = "new_mode"
        case changedBy = "changed_by"
        case reason
        case createdAt = "created_at"
    }
}
