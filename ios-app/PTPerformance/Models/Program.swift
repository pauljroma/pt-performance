import Foundation

/// Program model
struct Program: Codable, Identifiable {
    let id: String
    let patientId: String
    let name: String
    let targetLevel: String
    let durationWeeks: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case name
        case targetLevel = "target_level"
        case durationWeeks = "duration_weeks"
        case createdAt = "created_at"
    }
}

/// Phase model
struct Phase: Codable, Identifiable {
    let id: String
    let programId: String
    let phaseNumber: Int
    let name: String
    let durationWeeks: Int
    let goals: String?

    enum CodingKeys: String, CodingKey {
        case id
        case programId = "program_id"
        case phaseNumber = "phase_number"
        case name
        case durationWeeks = "duration_weeks"
        case goals
    }
}

/// Session model (simplified for program viewer)
struct ProgramSession: Codable, Identifiable {
    let id: String
    let phaseId: String
    let sessionNumber: Int
    let sessionDate: Date?
    let completed: Bool
    let exerciseCount: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case phaseId = "phase_id"
        case sessionNumber = "session_number"
        case sessionDate = "session_date"
        case completed
        case exerciseCount = "exercise_count"
    }
}

/// Session exercise (for program viewer)
struct ProgramExercise: Codable, Identifiable {
    let id: String
    let sessionId: String
    let exerciseName: String
    let sets: Int
    let reps: Int
    let load: Double?
    let loadUnit: String?
    let restPeriod: Int?
    let orderIndex: Int

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case exerciseName = "exercise_name"
        case sets = "prescribed_sets"
        case reps = "prescribed_reps"
        case load = "prescribed_load"
        case loadUnit = "load_unit"
        case restPeriod = "rest_period_seconds"
        case orderIndex = "order_index"
    }
}
