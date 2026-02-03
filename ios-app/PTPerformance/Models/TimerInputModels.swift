//
//  TimerInputModels.swift
//  PTPerformance
//
//  Input models for timer database operations
//

import Foundation

// MARK: - Create Interval Template Input

/// Input for creating a new interval template
struct CreateIntervalTemplateInput: Codable {
    let name: String
    let type: TimerType
    let workSeconds: Int
    let restSeconds: Int
    let rounds: Int
    let cycles: Int
    let createdBy: UUID
    let isPublic: Bool

    enum CodingKeys: String, CodingKey {
        case name
        case type
        case rounds
        case cycles
        case workSeconds = "work_seconds"
        case restSeconds = "rest_seconds"
        case createdBy = "created_by"
        case isPublic = "is_public"
    }
}

// MARK: - Create Workout Timer Input

/// Input for creating a new workout timer session
struct CreateWorkoutTimerInput: Codable {
    let patientId: UUID
    let templateId: UUID?  // Optional - NULL when starting from preset
    let startedAt: Date
    let roundsCompleted: Int
    let pausedSeconds: Int

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case templateId = "template_id"
        case startedAt = "started_at"
        case roundsCompleted = "rounds_completed"
        case pausedSeconds = "paused_seconds"
    }
}

// MARK: - Update Workout Timer Input

/// Input for updating a workout timer session
struct UpdateWorkoutTimerInput: Codable {
    let completedAt: Date
    let roundsCompleted: Int
    let pausedSeconds: Int

    enum CodingKeys: String, CodingKey {
        case completedAt = "completed_at"
        case roundsCompleted = "rounds_completed"
        case pausedSeconds = "paused_seconds"
    }
}
