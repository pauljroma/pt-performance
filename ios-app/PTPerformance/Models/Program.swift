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
    let durationWeeks: Int?  // Optional - can be null in database
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
    let completed: Bool?  // Optional - may not exist in database
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
struct ProgramExercise: Decodable, Identifiable {
    let id: String
    let sessionId: String
    let exerciseName: String
    let sets: Int
    let reps: String
    let load: Double?
    let loadUnit: String?
    let restPeriod: Int?
    let orderIndex: Int

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case exerciseTemplates = "exercise_templates"
        case sets = "prescribed_sets"
        case reps = "prescribed_reps"
        case load = "prescribed_load"
        case loadUnit = "load_unit"
        case restPeriod = "rest_period_seconds"
        case orderIndex = "order_index"
    }

    // Nested structure for exercise_templates join
    struct ExerciseTemplate: Codable {
        let exerciseName: String

        enum CodingKeys: String, CodingKey {
            case exerciseName = "exercise_name"
        }
    }

    // Custom decoder to extract exercise_name from nested object
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        sets = try container.decode(Int.self, forKey: .sets)
        reps = try container.decode(String.self, forKey: .reps)
        load = try container.decodeIfPresent(Double.self, forKey: .load)
        loadUnit = try container.decodeIfPresent(String.self, forKey: .loadUnit)
        restPeriod = try container.decodeIfPresent(Int.self, forKey: .restPeriod)
        orderIndex = try container.decode(Int.self, forKey: .orderIndex)

        // Extract exercise_name from nested exercise_templates object
        let template = try container.decode(ExerciseTemplate.self, forKey: .exerciseTemplates)
        exerciseName = template.exerciseName
    }
}
