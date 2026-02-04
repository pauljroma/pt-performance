//
//  WorkoutPrescription.swift
//  PTPerformance
//
//  Workout prescribed by therapist to patient
//

import Foundation

/// Priority level for prescribed workouts
enum PrescriptionPriority: String, Codable, CaseIterable {
    case low
    case medium
    case high
    case urgent

    var displayName: String {
        rawValue.capitalized
    }

    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "blue"
        case .high: return "orange"
        case .urgent: return "red"
        }
    }
}

/// Status of a workout prescription
enum PrescriptionStatus: String, Codable, CaseIterable {
    case pending
    case viewed
    case started
    case completed
    case expired
    case cancelled

    var displayName: String {
        rawValue.capitalized
    }
}

/// A workout prescribed by a therapist to a patient
struct WorkoutPrescription: Codable, Identifiable {
    let id: UUID
    let patientId: UUID
    let therapistId: UUID
    let templateId: UUID?
    let templateType: String?
    let name: String
    let instructions: String?
    let dueDate: Date?
    let priority: PrescriptionPriority
    let status: PrescriptionStatus
    let manualSessionId: UUID?
    let prescribedAt: Date
    let viewedAt: Date?
    let startedAt: Date?
    let completedAt: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case therapistId = "therapist_id"
        case templateId = "template_id"
        case templateType = "template_type"
        case name
        case instructions
        case dueDate = "due_date"
        case priority
        case status
        case manualSessionId = "manual_session_id"
        case prescribedAt = "prescribed_at"
        case viewedAt = "viewed_at"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case createdAt = "created_at"
    }

    /// Check if prescription is overdue
    var isOverdue: Bool {
        guard let due = dueDate else { return false }
        return due < Date() && status != .completed && status != .cancelled
    }

    /// Days until due (negative if overdue)
    var daysUntilDue: Int? {
        guard let due = dueDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: due).day
    }
}

/// DTO for creating a prescription
struct CreatePrescriptionDTO: Codable {
    let patientId: UUID
    let therapistId: UUID
    let templateId: UUID?
    let templateType: String?
    let name: String
    let instructions: String?
    let dueDate: Date?
    let priority: String

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case therapistId = "therapist_id"
        case templateId = "template_id"
        case templateType = "template_type"
        case name
        case instructions
        case dueDate = "due_date"
        case priority
    }
}
