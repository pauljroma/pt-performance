//
//  WorkoutTemplate.swift
//  PTPerformance
//
//  Manual Workout Entry - Models for workout template system
//

import Foundation

// MARK: - Workout Template

/// Represents a reusable workout program template
struct WorkoutTemplate: Codable, Identifiable, Hashable {

    let id: UUID
    let name: String
    let description: String?
    let category: TemplateCategory
    let difficultyLevel: DifficultyLevel?
    let durationWeeks: Int?
    let createdBy: UUID
    let isPublic: Bool
    let tags: [String]
    let usageCount: Int
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case category
        case difficultyLevel = "difficulty_level"
        case durationWeeks = "duration_weeks"
        case createdBy = "created_by"
        case isPublic = "is_public"
        case tags
        case usageCount = "usage_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID,
        name: String,
        description: String? = nil,
        category: TemplateCategory,
        difficultyLevel: DifficultyLevel? = nil,
        durationWeeks: Int? = nil,
        createdBy: UUID,
        isPublic: Bool = false,
        tags: [String] = [],
        usageCount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.difficultyLevel = difficultyLevel
        self.durationWeeks = durationWeeks
        self.createdBy = createdBy
        self.isPublic = isPublic
        self.tags = tags
        self.usageCount = usageCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required UUIDs with fallback
        id = container.safeUUID(forKey: .id)
        createdBy = container.safeUUID(forKey: .createdBy)

        // Required string with fallback
        name = container.safeString(forKey: .name, default: "Unknown Template")

        // Optional string
        description = container.safeOptionalString(forKey: .description)

        // Enum with fallback
        category = container.safeEnum(TemplateCategory.self, forKey: .category, default: .other)
        difficultyLevel = container.safeOptionalEnum(DifficultyLevel.self, forKey: .difficultyLevel)

        // Optional int
        durationWeeks = container.safeOptionalInt(forKey: .durationWeeks)

        // Bool with fallback
        isPublic = container.safeBool(forKey: .isPublic, default: false)

        // Array with fallback
        tags = container.safeArray(of: String.self, forKey: .tags)

        // Int with fallback
        usageCount = container.safeInt(forKey: .usageCount, default: 0)

        // Dates with fallback
        createdAt = container.safeDate(forKey: .createdAt)
        updatedAt = container.safeDate(forKey: .updatedAt)
    }

    enum TemplateCategory: String, Codable, CaseIterable {
        case strength
        case mobility
        case rehab
        case cardio
        case hybrid
        case other

        var displayName: String {
            switch self {
            case .strength: return "Strength"
            case .mobility: return "Mobility"
            case .rehab: return "Rehabilitation"
            case .cardio: return "Cardio"
            case .hybrid: return "Hybrid"
            case .other: return "Other"
            }
        }

        var icon: String {
            switch self {
            case .strength: return "dumbbell.fill"
            case .mobility: return "figure.flexibility"
            case .rehab: return "cross.case.fill"
            case .cardio: return "heart.fill"
            case .hybrid: return "sparkles"
            case .other: return "ellipsis.circle.fill"
            }
        }

        var color: String {
            switch self {
            case .strength: return "blue"
            case .mobility: return "green"
            case .rehab: return "orange"
            case .cardio: return "red"
            case .hybrid: return "purple"
            case .other: return "gray"
            }
        }
    }

    enum DifficultyLevel: String, Codable, CaseIterable {
        case beginner
        case intermediate
        case advanced

        var displayName: String {
            rawValue.capitalized
        }

        var icon: String {
            switch self {
            case .beginner: return "1.circle.fill"
            case .intermediate: return "2.circle.fill"
            case .advanced: return "3.circle.fill"
            }
        }

        var color: String {
            switch self {
            case .beginner: return "green"
            case .intermediate: return "orange"
            case .advanced: return "red"
            }
        }
    }

    // Computed properties
    var durationDescription: String {
        guard let weeks = durationWeeks else { return "Variable duration" }
        return "\(weeks) \(weeks == 1 ? "week" : "weeks")"
    }

    var isPopular: Bool {
        usageCount >= 10
    }
}

// MARK: - Template Phase

/// Represents a phase within a workout template
struct TemplatePhase: Codable, Identifiable, Hashable {

    let id: UUID
    let templateId: UUID
    let name: String
    let description: String?
    let sequence: Int
    let durationWeeks: Int?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case templateId = "template_id"
        case name
        case description
        case sequence
        case durationWeeks = "duration_weeks"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID,
        templateId: UUID,
        name: String,
        description: String? = nil,
        sequence: Int,
        durationWeeks: Int? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.templateId = templateId
        self.name = name
        self.description = description
        self.sequence = sequence
        self.durationWeeks = durationWeeks
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required UUIDs with fallback
        id = container.safeUUID(forKey: .id)
        templateId = container.safeUUID(forKey: .templateId)

        // Required string with fallback
        name = container.safeString(forKey: .name, default: "Phase")

        // Optional string
        description = container.safeOptionalString(forKey: .description)

        // Required int with fallback
        sequence = container.safeInt(forKey: .sequence, default: 0)

        // Optional int
        durationWeeks = container.safeOptionalInt(forKey: .durationWeeks)

        // Dates with fallback
        createdAt = container.safeDate(forKey: .createdAt)
        updatedAt = container.safeDate(forKey: .updatedAt)
    }

    // Computed properties
    var durationDescription: String {
        guard let weeks = durationWeeks else { return "Ongoing" }
        return "\(weeks) \(weeks == 1 ? "week" : "weeks")"
    }
}

// MARK: - Template Session

/// Represents a session within a template phase
struct TemplateSession: Codable, Identifiable, Hashable {

    let id: UUID
    let phaseId: UUID
    let name: String
    let description: String?
    let sequence: Int
    let exercises: [TemplateExercise]
    let notes: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case phaseId = "phase_id"
        case name
        case description
        case sequence
        case exercises
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID,
        phaseId: UUID,
        name: String,
        description: String? = nil,
        sequence: Int,
        exercises: [TemplateExercise] = [],
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.phaseId = phaseId
        self.name = name
        self.description = description
        self.sequence = sequence
        self.exercises = exercises
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required UUIDs with fallback
        id = container.safeUUID(forKey: .id)
        phaseId = container.safeUUID(forKey: .phaseId)

        // Required string with fallback
        name = container.safeString(forKey: .name, default: "Session")

        // Optional strings
        description = container.safeOptionalString(forKey: .description)
        notes = container.safeOptionalString(forKey: .notes)

        // Required int with fallback
        sequence = container.safeInt(forKey: .sequence, default: 0)

        // Array with fallback
        exercises = container.safeArray(of: TemplateExercise.self, forKey: .exercises)

        // Dates with fallback
        createdAt = container.safeDate(forKey: .createdAt)
        updatedAt = container.safeDate(forKey: .updatedAt)
    }

    // Computed properties
    var exerciseCount: Int {
        exercises.count
    }

    var estimatedDuration: Int {
        // Estimate ~3-5 minutes per exercise
        exerciseCount * 4
    }
}

// MARK: - Template Exercise

/// Represents an exercise configuration within a template session or workout block
struct TemplateExercise: Codable, Identifiable, Hashable {

    let id: UUID
    let exerciseTemplateId: UUID
    let name: String
    let sequence: Int
    let prescribedSets: Int
    let prescribedReps: String?
    let prescribedLoad: Double?
    let loadUnit: String?
    let restPeriodSeconds: Int?
    let notes: String?

    // Optional joined data from exercise_templates
    let category: String?
    let bodyRegion: String?
    let videoUrl: String?

    // Legacy fields for backward compatibility
    let exerciseId: UUID?
    let sets: Int?
    let reps: Int?
    let duration: Int? // Duration in seconds
    let rest: Int? // Rest in seconds
    let weight: Double? // Suggested weight
    let intensity: String? // e.g., "RPE 7-8", "70% 1RM"

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseTemplateId = "exercise_template_id"
        case name
        case sequence
        case prescribedSets = "prescribed_sets"
        case prescribedReps = "prescribed_reps"
        case prescribedLoad = "prescribed_load"
        case loadUnit = "load_unit"
        case restPeriodSeconds = "rest_period_seconds"
        case notes
        case category
        case bodyRegion = "body_region"
        case videoUrl = "video_url"
        // Legacy keys
        case exerciseId = "exercise_id"
        case sets
        case reps
        case duration
        case rest
        case weight
        case intensity
    }

    // Initialize with required fields (for new code)
    init(id: UUID = UUID(), exerciseTemplateId: UUID, name: String, sequence: Int, prescribedSets: Int, prescribedReps: String? = nil, prescribedLoad: Double? = nil, loadUnit: String? = nil, restPeriodSeconds: Int? = nil, notes: String? = nil, category: String? = nil, bodyRegion: String? = nil, videoUrl: String? = nil) {
        self.id = id
        self.exerciseTemplateId = exerciseTemplateId
        self.name = name
        self.sequence = sequence
        self.prescribedSets = prescribedSets
        self.prescribedReps = prescribedReps
        self.prescribedLoad = prescribedLoad
        self.loadUnit = loadUnit
        self.restPeriodSeconds = restPeriodSeconds
        self.notes = notes
        self.category = category
        self.bodyRegion = bodyRegion
        self.videoUrl = videoUrl
        // Legacy fields
        self.exerciseId = nil
        self.sets = nil
        self.reps = nil
        self.duration = nil
        self.rest = nil
        self.weight = nil
        self.intensity = nil
    }

    // Legacy initializer for backward compatibility
    init(exerciseId: UUID, sequence: Int, sets: Int, reps: Int?, duration: Int?, rest: Int?, notes: String?, weight: Double?, intensity: String?) {
        self.id = UUID()
        self.exerciseTemplateId = exerciseId
        self.name = ""
        self.sequence = sequence
        self.prescribedSets = sets
        self.prescribedReps = reps.map { String($0) }
        self.prescribedLoad = weight
        self.loadUnit = nil
        self.restPeriodSeconds = rest
        self.notes = notes
        self.category = nil
        self.bodyRegion = nil
        self.videoUrl = nil
        // Legacy fields
        self.exerciseId = exerciseId
        self.sets = sets
        self.reps = reps
        self.duration = duration
        self.rest = rest
        self.weight = weight
        self.intensity = intensity
    }

    // Computed properties
    var repsDisplay: String {
        prescribedReps ?? (reps.map { String($0) } ?? "0")
    }

    var loadDisplay: String {
        if let load = prescribedLoad ?? weight, let unit = loadUnit {
            return "\(Int(load)) \(unit)"
        } else if let load = prescribedLoad ?? weight {
            return "\(Int(load)) lbs"
        }
        return "Bodyweight"
    }

    var setsDisplay: String {
        "\(prescribedSets) sets"
    }

    var hasVideo: Bool {
        videoUrl != nil
    }

    var setsRepsDisplay: String {
        if let repsValue = prescribedReps {
            return "\(prescribedSets) x \(repsValue)"
        } else if let repsValue = reps {
            return "\(sets ?? prescribedSets) x \(repsValue)"
        } else if let duration = duration {
            let minutes = duration / 60
            let seconds = duration % 60
            if minutes > 0 {
                return "\(sets ?? prescribedSets) x \(minutes):\(String(format: "%02d", seconds))"
            } else {
                return "\(sets ?? prescribedSets) x \(seconds)s"
            }
        } else {
            return "\(prescribedSets) sets"
        }
    }

    var restDisplay: String? {
        guard let restSeconds = restPeriodSeconds ?? rest else { return nil }
        let minutes = restSeconds / 60
        let seconds = restSeconds % 60
        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", seconds)) rest"
        } else {
            return "\(seconds)s rest"
        }
    }
}

// MARK: - Template Exercise Data

/// Raw exercise data from database JSONB
struct TemplateExerciseData: Codable {
    let exerciseTemplateId: UUID?
    let exerciseName: String?
    let name: String?
    let blockName: String?
    let sequence: Int?
    let targetSets: Int?
    let targetReps: String?
    let targetLoad: Double?
    let loadUnit: String?
    let restPeriodSeconds: Int?
    let notes: String?
    // Legacy fields
    let sets: Int?
    let reps: Int?
    let load: Double?
    let rest: Int?

    enum CodingKeys: String, CodingKey {
        case exerciseTemplateId = "exercise_template_id"
        case exerciseName = "exercise_name"
        case name
        case blockName = "block_name"
        case sequence
        case targetSets = "target_sets"
        case targetReps = "target_reps"
        case targetLoad = "target_load"
        case loadUnit = "load_unit"
        case restPeriodSeconds = "rest_period_seconds"
        case notes
        case sets, reps, load, rest
    }

    init(
        exerciseTemplateId: UUID? = nil,
        exerciseName: String? = nil,
        name: String? = nil,
        blockName: String? = nil,
        sequence: Int? = nil,
        targetSets: Int? = nil,
        targetReps: String? = nil,
        targetLoad: Double? = nil,
        loadUnit: String? = nil,
        restPeriodSeconds: Int? = nil,
        notes: String? = nil,
        sets: Int? = nil,
        reps: Int? = nil,
        load: Double? = nil,
        rest: Int? = nil
    ) {
        self.exerciseTemplateId = exerciseTemplateId
        self.exerciseName = exerciseName
        self.name = name
        self.blockName = blockName
        self.sequence = sequence
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetLoad = targetLoad
        self.loadUnit = loadUnit
        self.restPeriodSeconds = restPeriodSeconds
        self.notes = notes
        self.sets = sets
        self.reps = reps
        self.load = load
        self.rest = rest
    }
}

// MARK: - Template with Details

/// Extended template model with phases and sessions
struct WorkoutTemplateDetail: Codable, Identifiable {
    let template: WorkoutTemplate
    let phases: [TemplatePhaseDetail]

    var id: UUID { template.id }

    // Computed properties
    var totalSessions: Int {
        phases.reduce(0) { $0 + $1.sessions.count }
    }

    var totalExercises: Int {
        phases.reduce(0) { total, phase in
            total + phase.sessions.reduce(0) { $0 + $1.exerciseCount }
        }
    }
}

/// Extended phase model with sessions
struct TemplatePhaseDetail: Codable, Identifiable {
    let phase: TemplatePhase
    let sessions: [TemplateSession]

    var id: UUID { phase.id }
}

// MARK: - Template Statistics

/// Statistics for a workout template
struct TemplateStatistics: Codable {
    let templateId: UUID
    let phaseCount: Int
    let totalSessions: Int
    let usageCount: Int
    let averageRating: Double?

    enum CodingKeys: String, CodingKey {
        case templateId = "template_id"
        case phaseCount = "phase_count"
        case totalSessions = "total_sessions"
        case usageCount = "usage_count"
        case averageRating = "average_rating"
    }
}

// MARK: - Sample Data

extension WorkoutTemplate {
    static var sample: WorkoutTemplate {
        WorkoutTemplate(
            id: UUID(),
            name: "ACL Rehabilitation Program",
            description: "Comprehensive post-surgery ACL rehabilitation focusing on strength, stability, and return to sport",
            category: .rehab,
            difficultyLevel: .intermediate,
            durationWeeks: 12,
            createdBy: UUID(),
            isPublic: true,
            tags: ["ACL", "Knee", "Post-Surgery", "Sport"],
            usageCount: 24,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    static var sampleStrength: WorkoutTemplate {
        WorkoutTemplate(
            id: UUID(),
            name: "Upper Body Strength Builder",
            description: "Progressive overload program for upper body strength development",
            category: .strength,
            difficultyLevel: .advanced,
            durationWeeks: 8,
            createdBy: UUID(),
            isPublic: true,
            tags: ["Strength", "Upper Body", "Progressive Overload"],
            usageCount: 15,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    static var sampleMobility: WorkoutTemplate {
        WorkoutTemplate(
            id: UUID(),
            name: "Daily Mobility Flow",
            description: "20-minute daily mobility routine for improved flexibility and joint health",
            category: .mobility,
            difficultyLevel: .beginner,
            durationWeeks: 4,
            createdBy: UUID(),
            isPublic: true,
            tags: ["Mobility", "Flexibility", "Daily", "Recovery"],
            usageCount: 42,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

extension TemplatePhase {
    static var sample: TemplatePhase {
        TemplatePhase(
            id: UUID(),
            templateId: UUID(),
            name: "Foundation Phase",
            description: "Build basic strength and stability",
            sequence: 1,
            durationWeeks: 4,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

extension TemplateSession {
    static var sample: TemplateSession {
        TemplateSession(
            id: UUID(),
            phaseId: UUID(),
            name: "Lower Body Strength",
            description: "Focus on compound movements",
            sequence: 1,
            exercises: [
                TemplateExercise(
                    exerciseId: UUID(),
                    sequence: 1,
                    sets: 3,
                    reps: 10,
                    duration: nil,
                    rest: 90,
                    notes: "Focus on controlled eccentric",
                    weight: 135,
                    intensity: "RPE 7-8"
                ),
                TemplateExercise(
                    exerciseId: UUID(),
                    sequence: 2,
                    sets: 3,
                    reps: 12,
                    duration: nil,
                    rest: 60,
                    notes: nil,
                    weight: 95,
                    intensity: nil
                )
            ],
            notes: "Warm up thoroughly before starting",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
