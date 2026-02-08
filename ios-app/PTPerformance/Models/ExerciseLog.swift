import Foundation

/// Represents a completed exercise log submitted by a patient
struct ExerciseLog: Codable, Identifiable, Sendable {
    let id: UUID
    let sessionExerciseId: UUID
    let patientId: UUID
    let loggedAt: Date
    let actualSets: Int
    let actualReps: [Int]
    let actualLoad: Double?
    let loadUnit: String?
    let rpe: Int  // Rating of Perceived Exertion (0-10)
    let painScore: Int  // Pain level (0-10)
    let notes: String?
    let completed: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case sessionExerciseId = "session_exercise_id"
        case patientId = "patient_id"
        case loggedAt = "logged_at"
        case actualSets = "actual_sets"
        case actualReps = "actual_reps"
        case actualLoad = "actual_load"
        case loadUnit = "load_unit"
        case rpe
        case painScore = "pain_score"
        case notes
        case completed
    }

    /// Memberwise initializer for creating placeholder logs (e.g., offline queue)
    init(
        id: UUID,
        sessionExerciseId: UUID,
        patientId: UUID,
        loggedAt: Date,
        actualSets: Int,
        actualReps: [Int],
        actualLoad: Double?,
        loadUnit: String?,
        rpe: Int,
        painScore: Int,
        notes: String?,
        completed: Bool
    ) {
        self.id = id
        self.sessionExerciseId = sessionExerciseId
        self.patientId = patientId
        self.loggedAt = loggedAt
        self.actualSets = actualSets
        self.actualReps = actualReps
        self.actualLoad = actualLoad
        self.loadUnit = loadUnit
        self.rpe = rpe
        self.painScore = painScore
        self.notes = notes
        self.completed = completed
    }

    /// Defensive decoder for database values
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required UUIDs with fallback
        id = container.safeUUID(forKey: .id)
        sessionExerciseId = container.safeUUID(forKey: .sessionExerciseId)
        patientId = container.safeUUID(forKey: .patientId)

        // Date with fallback
        loggedAt = container.safeDate(forKey: .loggedAt)

        // Required ints with fallback
        actualSets = container.safeInt(forKey: .actualSets, default: 0)
        rpe = container.safeInt(forKey: .rpe, default: 5)
        painScore = container.safeInt(forKey: .painScore, default: 0)

        // Array with fallback to empty
        actualReps = container.safeArray(of: Int.self, forKey: .actualReps)

        // Optional double (handles PostgreSQL numeric as string)
        actualLoad = container.safeOptionalDouble(forKey: .actualLoad)

        // Optional string
        loadUnit = container.safeOptionalString(forKey: .loadUnit)
        notes = container.safeOptionalString(forKey: .notes)

        // Bool with fallback
        completed = container.safeBool(forKey: .completed, default: false)
    }
}

/// Input model for creating a new exercise log
struct CreateExerciseLogInput: Codable, Sendable {
    let sessionExerciseId: UUID
    let patientId: UUID
    let actualSets: Int
    let actualReps: [Int]
    let actualLoad: Double?
    let loadUnit: String?
    let rpe: Int
    let painScore: Int
    let notes: String?
    let completed: Bool

    enum CodingKeys: String, CodingKey {
        case sessionExerciseId = "session_exercise_id"
        case patientId = "patient_id"
        case actualSets = "actual_sets"
        case actualReps = "actual_reps"
        case actualLoad = "actual_load"
        case loadUnit = "load_unit"
        case rpe
        case painScore = "pain_score"
        case notes
        case completed
    }
}

// MARK: - Analytics Helpers

extension ExerciseLog {
    /// Weight for analytics (maps to actualLoad)
    var weight: Double? {
        actualLoad
    }

    /// Reps for analytics (average of all sets)
    var reps: Int? {
        guard !actualReps.isEmpty else { return nil }
        let total = actualReps.reduce(0, +)
        return total / actualReps.count
    }

    /// Sets for analytics (maps to actualSets)
    var sets: Int {
        actualSets
    }

    /// Created date for analytics (maps to loggedAt)
    var createdAt: Date {
        loggedAt
    }

    /// Exercise ID for analytics
    var exerciseId: UUID {
        sessionExerciseId
    }

    /// Optional exercise reference (populated by join queries)
    /// Note: Returns nil - exercise name will be fetched from database when needed
    var exercise: ExerciseReference? {
        nil
    }
}

/// Simplified exercise reference for analytics (avoids conflict with main Exercise model)
struct ExerciseReference: Codable, Sendable {
    let id: UUID
    let name: String
}
