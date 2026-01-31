//
//  ProgramEnrollment.swift
//  PTPerformance
//
//  Model representing a user's enrollment in a program
//

import Foundation
import SwiftUI

/// A user's enrollment in a program from the program library
struct ProgramEnrollment: Codable, Identifiable {
    let id: UUID
    let patientId: UUID
    let programLibraryId: UUID
    let enrolledAt: Date
    let startedAt: Date?
    let completedAt: Date?
    let status: String
    let progressPercentage: Int
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case programLibraryId = "program_library_id"
        case enrolledAt = "enrolled_at"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case status
        case progressPercentage = "progress_percentage"
        case notes
    }

    // MARK: - Computed Properties

    /// Parsed enrollment status
    var enrollmentStatus: EnrollmentStatus {
        EnrollmentStatus(rawValue: status) ?? .active
    }

    /// Whether the enrollment is currently active
    var isActive: Bool {
        enrollmentStatus == .active
    }

    /// Whether the program has been started
    var hasStarted: Bool {
        startedAt != nil
    }

    /// Whether the program is complete
    var isComplete: Bool {
        enrollmentStatus == .completed || completedAt != nil
    }
}

// MARK: - Enrollment Status Enum

enum EnrollmentStatus: String, Codable, CaseIterable {
    case active
    case completed
    case paused
    case cancelled

    var displayName: String {
        switch self {
        case .active: return "Active"
        case .completed: return "Completed"
        case .paused: return "Paused"
        case .cancelled: return "Cancelled"
        }
    }

    var icon: String {
        switch self {
        case .active: return "play.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .paused: return "pause.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .active: return .green
        case .completed: return .blue
        case .paused: return .orange
        case .cancelled: return .gray
        }
    }

    var description: String {
        switch self {
        case .active: return "Currently in progress"
        case .completed: return "Successfully finished"
        case .paused: return "Temporarily on hold"
        case .cancelled: return "No longer enrolled"
        }
    }
}

// MARK: - Enrollment with Program (for joined queries)

/// Combined enrollment and program data for display
struct EnrollmentWithProgram: Identifiable {
    let enrollment: ProgramEnrollment
    let program: ProgramLibrary

    var id: UUID { enrollment.id }
}
