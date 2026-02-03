//
//  ProgramEnrollment.swift
//  PTPerformance
//
//  Model representing a user's enrollment in a program
//

import SwiftUI

/// A user's enrollment in a program from the program library
struct ProgramEnrollment: Codable, Identifiable, Hashable, Equatable {
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

// MARK: - Program Workout Schedule Models

/// A week in the program schedule
struct ProgramScheduleWeek: Identifiable {
    let weekNumber: Int
    let days: [ProgramScheduleDay]

    var id: Int { weekNumber }

    /// Total workouts in this week
    var workoutCount: Int {
        days.reduce(0) { $0 + $1.workouts.count }
    }

    /// Days that have workouts
    var activeDays: [ProgramScheduleDay] {
        days.filter { !$0.workouts.isEmpty }
    }
}

/// A day in the program schedule
struct ProgramScheduleDay: Identifiable {
    let dayOfWeek: Int
    let dayName: String
    let workouts: [ProgramScheduleWorkout]

    var id: Int { dayOfWeek }

    /// Short day name (Mon, Tue, etc.)
    var shortName: String {
        String(dayName.prefix(3))
    }

    /// Whether this is a rest day
    var isRestDay: Bool {
        workouts.isEmpty
    }
}

/// A workout in the program schedule
struct ProgramScheduleWorkout: Identifiable {
    let assignmentId: UUID
    let templateId: UUID
    let name: String
    let description: String?
    let durationMinutes: Int?
    let category: String?
    let difficulty: String?
    let notes: String?

    var id: UUID { assignmentId }

    /// Formatted duration
    var formattedDuration: String {
        guard let minutes = durationMinutes else { return "N/A" }
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remaining = minutes % 60
            return remaining > 0 ? "\(hours)h \(remaining)m" : "\(hours)h"
        }
    }
}

/// Assignment with template details (for decoding from Supabase join)
struct ProgramWorkoutAssignmentWithTemplate: Codable {
    let id: UUID
    let programId: UUID
    let templateId: UUID
    let phaseId: UUID?
    let weekNumber: Int
    let dayOfWeek: Int
    let sequence: Int
    let notes: String?
    let template: ScheduleTemplateInfo

    enum CodingKeys: String, CodingKey {
        case id
        case programId = "program_id"
        case templateId = "template_id"
        case phaseId = "phase_id"
        case weekNumber = "week_number"
        case dayOfWeek = "day_of_week"
        case sequence
        case notes
        case template = "system_workout_templates"
    }
}

/// Template info nested in assignment response
struct ScheduleTemplateInfo: Codable {
    let id: UUID
    let name: String
    let description: String?
    let durationMinutes: Int?
    let category: String?
    let difficulty: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case durationMinutes = "duration_minutes"
        case category
        case difficulty
    }
}
