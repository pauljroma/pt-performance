import Foundation

/// Represents a manually logged workout session
/// Maps to manual_sessions table in Supabase
struct ManualSession: Codable, Identifiable, Equatable {
    let id: UUID
    let patientId: UUID
    let templateId: UUID?
    let name: String
    let notes: String?
    let startedAt: Date
    let completedAt: Date?
    let durationMinutes: Int?
    let totalVolume: Double?
    let avgRpe: Double?
    let avgPain: Double?
    let createdAt: Date
    let updatedAt: Date?

    // Exercises for this manual session (loaded separately or joined)
    var exercises: [ManualSessionExercise] = []

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case templateId = "template_id"
        case name
        case notes
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case durationMinutes = "duration_minutes"
        case totalVolume = "total_volume"
        case avgRpe = "avg_rpe"
        case avgPain = "avg_pain"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        // exercises is NOT in CodingKeys - will use default value
    }

    var isCompleted: Bool {
        completedAt != nil
    }

    var completionStatus: String {
        isCompleted ? "Completed" : "In Progress"
    }

    var dateDisplay: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startedAt)
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
    let exerciseTemplateId: UUID
    let blockType: String?
    let sequence: Int
    let prescribedSets: Int
    let prescribedReps: String?
    let prescribedLoad: Double?
    let loadUnit: String?
    let restPeriodSeconds: Int?
    let actualSets: Int?
    let actualReps: [Int]?
    let actualLoad: Double?
    let rpe: Int?
    let painScore: Int?
    let notes: String?
    let completed: Bool
    let createdAt: Date

    // From exercise_templates (joined data)
    let exerciseTemplates: Exercise.ExerciseTemplate?

    enum CodingKeys: String, CodingKey {
        case id
        case manualSessionId = "manual_session_id"
        case exerciseTemplateId = "exercise_template_id"
        case blockType = "block_type"
        case sequence
        case prescribedSets = "prescribed_sets"
        case prescribedReps = "prescribed_reps"
        case prescribedLoad = "prescribed_load"
        case loadUnit = "load_unit"
        case restPeriodSeconds = "rest_period_seconds"
        case actualSets = "actual_sets"
        case actualReps = "actual_reps"
        case actualLoad = "actual_load"
        case rpe
        case painScore = "pain_score"
        case notes
        case completed
        case createdAt = "created_at"
        case exerciseTemplates = "exercise_templates"
    }

    var exerciseName: String? {
        exerciseTemplates?.name
    }

    var repsDisplay: String {
        prescribedReps ?? "0"
    }

    var loadDisplay: String {
        if let load = prescribedLoad, let unit = loadUnit {
            return "\(Int(load)) \(unit)"
        }
        return "Bodyweight"
    }

    var setsDisplay: String {
        "\(prescribedSets) sets"
    }

    var actualRepsDisplay: String? {
        guard let reps = actualReps, !reps.isEmpty else { return nil }
        return reps.map { String($0) }.joined(separator: ", ")
    }

    var actualLoadDisplay: String? {
        guard let load = actualLoad else { return nil }
        let unit = loadUnit ?? "lbs"
        return "\(Int(load)) \(unit)"
    }
}

// Input models are defined in ManualWorkoutService.swift
