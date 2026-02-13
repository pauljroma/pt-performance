import Foundation
import SwiftUI

// MARK: - RTSProtocol Model
// Main Return-to-Sport journey for a patient

/// Represents a patient's Return-to-Sport protocol journey
struct RTSProtocol: Identifiable, Codable, Hashable {
    let id: UUID
    let patientId: UUID
    let therapistId: UUID
    let sportId: UUID
    let injuryType: String
    let surgeryDate: Date?
    let injuryDate: Date
    let targetReturnDate: Date
    var actualReturnDate: Date?
    var status: RTSProtocolStatus
    var currentPhaseId: UUID?
    var notes: String?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case therapistId = "therapist_id"
        case sportId = "sport_id"
        case injuryType = "injury_type"
        case surgeryDate = "surgery_date"
        case injuryDate = "injury_date"
        case targetReturnDate = "target_return_date"
        case actualReturnDate = "actual_return_date"
        case status
        case currentPhaseId = "current_phase_id"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Computed Properties

    /// Number of days until target return date (negative if past due)
    var daysUntilTarget: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: targetReturnDate).day ?? 0
    }

    /// Progress percentage based on time elapsed
    var progressPercentage: Double {
        let totalDays = Calendar.current.dateComponents([.day], from: injuryDate, to: targetReturnDate).day ?? 1
        let elapsedDays = Calendar.current.dateComponents([.day], from: injuryDate, to: Date()).day ?? 0

        guard totalDays > 0 else { return 0 }
        return min(max(Double(elapsedDays) / Double(totalDays), 0), 1.0)
    }

    /// Formatted target return date string
    var formattedTargetDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: targetReturnDate)
    }

    /// Formatted injury date string
    var formattedInjuryDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: injuryDate)
    }

    /// Days since injury
    var daysSinceInjury: Int {
        Calendar.current.dateComponents([.day], from: injuryDate, to: Date()).day ?? 0
    }

    /// Whether the protocol is currently active
    var isActive: Bool {
        status == .active
    }

    /// Whether the protocol has been completed
    var isCompleted: Bool {
        status == .completed
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        patientId: UUID,
        therapistId: UUID,
        sportId: UUID,
        injuryType: String,
        surgeryDate: Date? = nil,
        injuryDate: Date,
        targetReturnDate: Date,
        actualReturnDate: Date? = nil,
        status: RTSProtocolStatus = .draft,
        currentPhaseId: UUID? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.patientId = patientId
        self.therapistId = therapistId
        self.sportId = sportId
        self.injuryType = injuryType
        self.surgeryDate = surgeryDate
        self.injuryDate = injuryDate
        self.targetReturnDate = targetReturnDate
        self.actualReturnDate = actualReturnDate
        self.status = status
        self.currentPhaseId = currentPhaseId
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Protocol Status

/// Status of an RTS protocol
enum RTSProtocolStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case draft
    case active
    case completed
    case discontinued

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .active: return "Active"
        case .completed: return "Completed"
        case .discontinued: return "Discontinued"
        }
    }

    /// Color for UI display
    var color: Color {
        switch self {
        case .draft: return .gray
        case .active: return .blue
        case .completed: return .green
        case .discontinued: return .red
        }
    }

    /// SF Symbol icon name
    var icon: String {
        switch self {
        case .draft: return "doc.badge.ellipsis"
        case .active: return "play.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .discontinued: return "xmark.circle.fill"
        }
    }

    /// Whether the protocol can be edited
    var isEditable: Bool {
        return self == .draft || self == .active
    }
}

// MARK: - Input Model

/// Input model for creating/updating RTS protocols
struct RTSProtocolInput: Codable {
    var patientId: String?
    var therapistId: String?
    var sportId: String?
    var injuryType: String?
    var surgeryDate: String?
    var injuryDate: String?
    var targetReturnDate: String?
    var actualReturnDate: String?
    var status: String?
    var currentPhaseId: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case therapistId = "therapist_id"
        case sportId = "sport_id"
        case injuryType = "injury_type"
        case surgeryDate = "surgery_date"
        case injuryDate = "injury_date"
        case targetReturnDate = "target_return_date"
        case actualReturnDate = "actual_return_date"
        case status
        case currentPhaseId = "current_phase_id"
        case notes
    }

    /// Validate input before submission
    func validate() throws {
        guard patientId != nil else {
            throw RTSProtocolError.invalidInput("Patient ID is required")
        }
        guard therapistId != nil else {
            throw RTSProtocolError.invalidInput("Therapist ID is required")
        }
        guard sportId != nil else {
            throw RTSProtocolError.invalidInput("Sport ID is required")
        }
        guard let injuryType = injuryType, !injuryType.isEmpty else {
            throw RTSProtocolError.invalidInput("Injury type is required")
        }
        guard injuryDate != nil else {
            throw RTSProtocolError.invalidInput("Injury date is required")
        }
        guard targetReturnDate != nil else {
            throw RTSProtocolError.invalidInput("Target return date is required")
        }
    }
}

// MARK: - Errors

enum RTSProtocolError: LocalizedError {
    case invalidInput(String)
    case protocolNotFound
    case saveFailed
    case fetchFailed
    case cannotEditCompleted
    case invalidStateTransition

    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return message
        case .protocolNotFound:
            return "RTS protocol not found"
        case .saveFailed:
            return "Failed to save RTS protocol"
        case .fetchFailed:
            return "Failed to fetch RTS protocol"
        case .cannotEditCompleted:
            return "Cannot edit a completed protocol"
        case .invalidStateTransition:
            return "Invalid protocol status transition"
        }
    }
}

// MARK: - Sample Data

#if DEBUG
extension RTSProtocol {
    static let sample = RTSProtocol(
        patientId: UUID(),
        therapistId: UUID(),
        sportId: UUID(),
        injuryType: "ACL Reconstruction",
        surgeryDate: Calendar.current.date(byAdding: .month, value: -3, to: Date()),
        injuryDate: Calendar.current.date(byAdding: .month, value: -4, to: Date())!,
        targetReturnDate: Calendar.current.date(byAdding: .month, value: 6, to: Date())!,
        status: .active,
        notes: "Post-operative ACL reconstruction protocol. Patient is progressing well."
    )

    static let completedSample = RTSProtocol(
        patientId: UUID(),
        therapistId: UUID(),
        sportId: UUID(),
        injuryType: "UCL Sprain Grade II",
        injuryDate: Calendar.current.date(byAdding: .month, value: -6, to: Date())!,
        targetReturnDate: Calendar.current.date(byAdding: .month, value: -1, to: Date())!,
        actualReturnDate: Calendar.current.date(byAdding: .day, value: -14, to: Date()),
        status: .completed
    )
}
#endif
