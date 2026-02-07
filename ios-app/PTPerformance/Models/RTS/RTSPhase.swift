import Foundation
import SwiftUI

// MARK: - RTSPhase Model
// Phase within a Return-to-Sport protocol

/// Represents a phase within an RTS protocol
struct RTSPhase: Identifiable, Codable {
    let id: UUID
    let protocolId: UUID
    let phaseNumber: Int
    let phaseName: String
    let activityLevel: RTSTrafficLight
    let description: String
    let entryCriteria: [String]
    let exitCriteria: [String]
    var startedAt: Date?
    var completedAt: Date?
    let targetDurationDays: Int?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case protocolId = "protocol_id"
        case phaseNumber = "phase_number"
        case phaseName = "phase_name"
        case activityLevel = "activity_level"
        case description
        case entryCriteria = "entry_criteria"
        case exitCriteria = "exit_criteria"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case targetDurationDays = "target_duration_days"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Computed Properties

    /// Whether the phase is currently active
    var isActive: Bool {
        startedAt != nil && completedAt == nil
    }

    /// Whether the phase has been completed
    var isCompleted: Bool {
        completedAt != nil
    }

    /// Whether the phase has not yet started
    var isPending: Bool {
        startedAt == nil
    }

    /// Number of days spent in this phase (nil if not started)
    var daysInPhase: Int? {
        guard let start = startedAt else { return nil }
        let endDate = completedAt ?? Date()
        return Calendar.current.dateComponents([.day], from: start, to: endDate).day
    }

    /// Progress percentage based on target duration
    var progressPercentage: Double? {
        guard let days = daysInPhase, let target = targetDurationDays, target > 0 else {
            return nil
        }
        return min(Double(days) / Double(target), 1.0)
    }

    /// Formatted start date string
    var formattedStartDate: String? {
        guard let date = startedAt else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    /// Formatted completion date string
    var formattedCompletionDate: String? {
        guard let date = completedAt else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    /// Target duration in weeks
    var targetDurationWeeks: Int? {
        guard let days = targetDurationDays else { return nil }
        return days / 7
    }

    /// Status display text
    var statusText: String {
        if isCompleted {
            return "Completed"
        } else if isActive {
            if let days = daysInPhase {
                return "Day \(days + 1)"
            }
            return "Active"
        } else {
            return "Pending"
        }
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        protocolId: UUID,
        phaseNumber: Int,
        phaseName: String,
        activityLevel: RTSTrafficLight,
        description: String,
        entryCriteria: [String] = [],
        exitCriteria: [String] = [],
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        targetDurationDays: Int? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.protocolId = protocolId
        self.phaseNumber = phaseNumber
        self.phaseName = phaseName
        self.activityLevel = activityLevel
        self.description = description
        self.entryCriteria = entryCriteria
        self.exitCriteria = exitCriteria
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.targetDurationDays = targetDurationDays
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Input Model

/// Input model for creating/updating RTS phases
struct RTSPhaseInput: Codable {
    var protocolId: String?
    var phaseNumber: Int?
    var phaseName: String?
    var activityLevel: String?
    var description: String?
    var entryCriteria: [String]?
    var exitCriteria: [String]?
    var startedAt: String?
    var completedAt: String?
    var targetDurationDays: Int?

    enum CodingKeys: String, CodingKey {
        case protocolId = "protocol_id"
        case phaseNumber = "phase_number"
        case phaseName = "phase_name"
        case activityLevel = "activity_level"
        case description
        case entryCriteria = "entry_criteria"
        case exitCriteria = "exit_criteria"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case targetDurationDays = "target_duration_days"
    }

    /// Validate input before submission
    func validate() throws {
        guard protocolId != nil else {
            throw RTSPhaseError.invalidInput("Protocol ID is required")
        }
        guard let number = phaseNumber, number > 0 else {
            throw RTSPhaseError.invalidInput("Valid phase number is required")
        }
        guard phaseName != nil && !phaseName!.isEmpty else {
            throw RTSPhaseError.invalidInput("Phase name is required")
        }
        guard activityLevel != nil else {
            throw RTSPhaseError.invalidInput("Activity level is required")
        }
    }
}

// MARK: - Errors

enum RTSPhaseError: LocalizedError {
    case invalidInput(String)
    case phaseNotFound
    case saveFailed
    case fetchFailed
    case cannotStartPhase
    case cannotCompletePhase
    case criteriaNotMet

    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return message
        case .phaseNotFound:
            return "RTS phase not found"
        case .saveFailed:
            return "Failed to save RTS phase"
        case .fetchFailed:
            return "Failed to fetch RTS phase"
        case .cannotStartPhase:
            return "Cannot start this phase"
        case .cannotCompletePhase:
            return "Cannot complete this phase"
        case .criteriaNotMet:
            return "Phase criteria have not been met"
        }
    }
}

// MARK: - Sample Data

#if DEBUG
extension RTSPhase {
    static let activeSample = RTSPhase(
        protocolId: UUID(),
        phaseNumber: 2,
        phaseName: "Light Tossing",
        activityLevel: .yellow,
        description: "Begin light tossing at short distances with emphasis on mechanics",
        entryCriteria: [
            "Pain-free ROM achieved",
            "No swelling or tenderness",
            "Medical clearance obtained"
        ],
        exitCriteria: [
            "Complete 10 sessions without pain",
            "LSI >= 80% on strength tests",
            "Negative clinical tests"
        ],
        startedAt: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
        targetDurationDays: 14
    )

    static let completedSample = RTSPhase(
        protocolId: UUID(),
        phaseNumber: 1,
        phaseName: "Protected Motion",
        activityLevel: .red,
        description: "Focus on pain-free range of motion and tissue healing",
        entryCriteria: ["Post-surgery clearance"],
        exitCriteria: [
            "Full passive ROM",
            "Pain <= 2/10",
            "No swelling"
        ],
        startedAt: Calendar.current.date(byAdding: .day, value: -21, to: Date()),
        completedAt: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
        targetDurationDays: 14
    )

    static let pendingSample = RTSPhase(
        protocolId: UUID(),
        phaseNumber: 3,
        phaseName: "Long Toss",
        activityLevel: .yellow,
        description: "Progressive distance throwing with increasing intensity",
        entryCriteria: [
            "Complete Phase 2 criteria",
            "LSI >= 85%",
            "Y-Balance composite >= 90%"
        ],
        exitCriteria: [
            "Throw at max distance without pain",
            "Complete velocity progression",
            "Pass psychological readiness"
        ],
        targetDurationDays: 21
    )
}
#endif
