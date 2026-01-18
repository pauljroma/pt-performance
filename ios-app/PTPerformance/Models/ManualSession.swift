import Foundation

/// Represents a manually logged workout session
/// Maps to manual_sessions table in Supabase
struct ManualSession: Codable, Identifiable, Equatable {
    let id: UUID
    let patientId: UUID
    let name: String?
    let notes: String?
    let sourceTemplateId: UUID?
    let sourceTemplateType: String?
    let startedAt: Date?
    let completedAt: Date?
    let completed: Bool
    let totalVolume: Double?
    let avgRpe: Double?
    let avgPain: Double?
    let durationMinutes: Int?
    let createdAt: Date

    // Exercises for this manual session (loaded separately or joined)
    var exercises: [ManualSessionExercise] = []

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case name
        case notes
        case sourceTemplateId = "source_template_id"
        case sourceTemplateType = "source_template_type"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case completed
        case totalVolume = "total_volume"
        case avgRpe = "avg_rpe"
        case avgPain = "avg_pain"
        case durationMinutes = "duration_minutes"
        case createdAt = "created_at"
        // exercises is NOT in CodingKeys - will use default value
    }

    var isCompleted: Bool {
        completed || completedAt != nil
    }

    var completionStatus: String {
        isCompleted ? "Completed" : "In Progress"
    }

    var dateDisplay: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        if let startedAt = startedAt {
            return formatter.string(from: startedAt)
        }
        return formatter.string(from: createdAt)
    }

    var durationDisplay: String? {
        guard let minutes = durationMinutes else { return nil }
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes > 0 {
                return "\(hours)h \(remainingMinutes)m"
            }
            return "\(hours)h"
        }
        return "\(minutes)m"
    }

    var volumeDisplay: String? {
        guard let volume = totalVolume else { return nil }
        if volume >= 1000 {
            return String(format: "%.1fk lbs", volume / 1000)
        }
        return "\(Int(volume)) lbs"
    }
}

/// Represents an exercise within a manual workout session
/// Maps to manual_session_exercises table in Supabase
struct ManualSessionExercise: Codable, Identifiable, Hashable {
    let id: UUID
    let manualSessionId: UUID
    let exerciseTemplateId: UUID?
    let exerciseName: String
    let blockName: String?
    let sequence: Int
    let targetSets: Int?
    let targetReps: String?
    let targetLoad: Double?
    let loadUnit: String?
    let restPeriodSeconds: Int?
    let notes: String?
    let createdAt: Date

    // Transient properties for tracking logged exercise data during workout execution
    // These are NOT persisted to database - they're stored in exercise_logs table
    var actualSets: Int?
    var actualReps: [Int]?
    var actualLoad: Double?
    var rpe: Double?
    var painScore: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case manualSessionId = "manual_session_id"
        case exerciseTemplateId = "exercise_template_id"
        case exerciseName = "exercise_name"
        case blockName = "block_name"
        case sequence
        case targetSets = "target_sets"
        case targetReps = "target_reps"
        case targetLoad = "target_load"
        case loadUnit = "load_unit"
        case restPeriodSeconds = "rest_period_seconds"
        case notes
        case createdAt = "created_at"
        // Transient properties NOT in CodingKeys - they won't be encoded/decoded
    }

    var name: String {
        exerciseName
    }

    var blockType: String? {
        blockName
    }

    var repsDisplay: String {
        targetReps ?? "0"
    }

    var loadDisplay: String {
        if let load = targetLoad, let unit = loadUnit {
            return "\(Int(load)) \(unit)"
        }
        return "Bodyweight"
    }

    var setsDisplay: String {
        "\(targetSets ?? 0) sets"
    }
}

// Input models are defined in ManualWorkoutService.swift
