import Foundation

/// Program model
struct Program: Codable, Identifiable, Hashable, Equatable {
    let id: UUID
    let patientId: UUID
    let name: String
    let targetLevel: String
    let durationWeeks: Int
    let createdAt: Date
    let status: String?  // Optional - may be "active", "completed", "paused", etc.
    let programType: ProgramType?  // Optional for backward compat with existing programs

    /// Resolved program type (defaults to .rehab for legacy programs)
    var resolvedProgramType: ProgramType {
        programType ?? .rehab
    }

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case name
        case targetLevel = "target_level"
        case durationWeeks = "duration_weeks"
        case createdAt = "created_at"
        case status
        case programType = "program_type"
    }

    init(
        id: UUID,
        patientId: UUID,
        name: String,
        targetLevel: String,
        durationWeeks: Int,
        createdAt: Date = Date(),
        status: String? = nil,
        programType: ProgramType? = nil
    ) {
        self.id = id
        self.patientId = patientId
        self.name = name
        self.targetLevel = targetLevel
        self.durationWeeks = durationWeeks
        self.createdAt = createdAt
        self.status = status
        self.programType = programType
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required UUIDs with fallback
        id = container.safeUUID(forKey: .id)
        patientId = container.safeUUID(forKey: .patientId)

        // Required strings with fallback
        name = container.safeString(forKey: .name, default: "Unknown Program")
        targetLevel = container.safeString(forKey: .targetLevel, default: "General")

        // Required int with fallback
        durationWeeks = container.safeInt(forKey: .durationWeeks, default: 1)

        // Date with fallback
        createdAt = container.safeDate(forKey: .createdAt)

        // Optional string
        status = container.safeOptionalString(forKey: .status)

        // Optional enum
        programType = container.safeOptionalEnum(ProgramType.self, forKey: .programType)
    }
}

/// Phase model
struct Phase: Codable, Identifiable, Hashable, Equatable {
    let id: UUID
    let programId: UUID
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

    init(
        id: UUID,
        programId: UUID,
        phaseNumber: Int,
        name: String,
        durationWeeks: Int? = nil,
        goals: String? = nil
    ) {
        self.id = id
        self.programId = programId
        self.phaseNumber = phaseNumber
        self.name = name
        self.durationWeeks = durationWeeks
        self.goals = goals
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required UUIDs with fallback
        id = container.safeUUID(forKey: .id)
        programId = container.safeUUID(forKey: .programId)

        // Required int with fallback
        phaseNumber = container.safeInt(forKey: .phaseNumber, default: 1)

        // Required string with fallback
        name = container.safeString(forKey: .name, default: "Phase")

        // Optional int
        durationWeeks = container.safeOptionalInt(forKey: .durationWeeks)

        // Optional string
        goals = container.safeOptionalString(forKey: .goals)
    }
}

/// Session model (simplified for program viewer)
struct ProgramSession: Codable, Identifiable, Hashable, Equatable {
    let id: UUID
    let phaseId: UUID
    let sessionNumber: Int?
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

    init(
        id: UUID,
        phaseId: UUID,
        sessionNumber: Int? = nil,
        sessionDate: Date? = nil,
        completed: Bool? = nil,
        exerciseCount: Int? = nil
    ) {
        self.id = id
        self.phaseId = phaseId
        self.sessionNumber = sessionNumber
        self.sessionDate = sessionDate
        self.completed = completed
        self.exerciseCount = exerciseCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required UUIDs with fallback
        id = container.safeUUID(forKey: .id)
        phaseId = container.safeUUID(forKey: .phaseId)

        // Optional int
        sessionNumber = container.safeOptionalInt(forKey: .sessionNumber)
        exerciseCount = container.safeOptionalInt(forKey: .exerciseCount)

        // Optional date
        sessionDate = container.safeOptionalDate(forKey: .sessionDate)

        // Optional bool - use nil-preserving approach
        if container.contains(.completed) {
            completed = container.safeBool(forKey: .completed, default: false)
        } else {
            completed = nil
        }
    }
}

/// Session exercise (for program viewer)
struct ProgramExercise: Decodable, Identifiable, Hashable, Equatable {
    let id: UUID
    let sessionId: UUID
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
    struct ExerciseTemplate: Codable, Hashable, Equatable {
        let exerciseName: String

        enum CodingKeys: String, CodingKey {
            case exerciseName = "exercise_name"
        }
    }

    // Custom decoder to extract exercise_name from nested object with defensive patterns
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required UUIDs with fallback
        id = container.safeUUID(forKey: .id)
        sessionId = container.safeUUID(forKey: .sessionId)

        // Required ints with fallback
        sets = container.safeInt(forKey: .sets, default: 1)
        orderIndex = container.safeInt(forKey: .orderIndex, default: 0)

        // Required string with fallback
        reps = container.safeString(forKey: .reps, default: "0")

        // Optional double (handles PostgreSQL numeric as string)
        load = container.safeOptionalDouble(forKey: .load)

        // Optional string
        loadUnit = container.safeOptionalString(forKey: .loadUnit)

        // Optional int
        restPeriod = container.safeOptionalInt(forKey: .restPeriod)

        // Extract exercise_name from nested exercise_templates object with fallback
        if let template = try? container.decode(ExerciseTemplate.self, forKey: .exerciseTemplates) {
            exerciseName = template.exerciseName
        } else {
            exerciseName = "Unknown Exercise"
        }
    }
}
