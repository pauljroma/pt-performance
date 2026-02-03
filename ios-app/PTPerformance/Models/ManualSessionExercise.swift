//
//  ManualSessionExercise.swift
//  PTPerformance
//
//  Manual Workout Entry
//

import Foundation

// MARK: - Manual Session Exercise

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

    init(
        id: UUID = UUID(),
        manualSessionId: UUID,
        exerciseTemplateId: UUID? = nil,
        exerciseName: String,
        blockName: String? = nil,
        sequence: Int,
        targetSets: Int? = nil,
        targetReps: String? = nil,
        targetLoad: Double? = nil,
        loadUnit: String? = nil,
        restPeriodSeconds: Int? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        actualSets: Int? = nil,
        actualReps: [Int]? = nil,
        actualLoad: Double? = nil,
        rpe: Double? = nil,
        painScore: Double? = nil
    ) {
        self.id = id
        self.manualSessionId = manualSessionId
        self.exerciseTemplateId = exerciseTemplateId
        self.exerciseName = exerciseName
        self.blockName = blockName
        self.sequence = sequence
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetLoad = targetLoad
        self.loadUnit = loadUnit
        self.restPeriodSeconds = restPeriodSeconds
        self.notes = notes
        self.createdAt = createdAt
        self.actualSets = actualSets
        self.actualReps = actualReps
        self.actualLoad = actualLoad
        self.rpe = rpe
        self.painScore = painScore
    }

    // MARK: - Computed Properties

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
        } else if let load = targetLoad {
            return "\(Int(load)) lbs"
        }
        return "Bodyweight"
    }

    var setsDisplay: String {
        "\(targetSets ?? 0) sets"
    }

    var setsRepsDisplay: String {
        if let sets = targetSets, let reps = targetReps {
            return "\(sets) x \(reps)"
        } else if let sets = targetSets {
            return "\(sets) sets"
        }
        return ""
    }

    var restDisplay: String? {
        guard let restSeconds = restPeriodSeconds else { return nil }
        let minutes = restSeconds / 60
        let seconds = restSeconds % 60
        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", seconds)) rest"
        } else {
            return "\(seconds)s rest"
        }
    }

    // Hashable conformance (excluding transient properties)
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ManualSessionExercise, rhs: ManualSessionExercise) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Create Manual Session Exercise DTO

/// Data transfer object for creating a manual session exercise
struct CreateManualSessionExerciseDTO: Codable {
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

    enum CodingKeys: String, CodingKey {
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
    }

    init(
        manualSessionId: UUID,
        exerciseTemplateId: UUID? = nil,
        exerciseName: String,
        blockName: String? = nil,
        sequence: Int,
        targetSets: Int? = nil,
        targetReps: String? = nil,
        targetLoad: Double? = nil,
        loadUnit: String? = nil,
        restPeriodSeconds: Int? = nil,
        notes: String? = nil
    ) {
        self.manualSessionId = manualSessionId
        self.exerciseTemplateId = exerciseTemplateId
        self.exerciseName = exerciseName
        self.blockName = blockName
        self.sequence = sequence
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetLoad = targetLoad
        self.loadUnit = loadUnit
        self.restPeriodSeconds = restPeriodSeconds
        self.notes = notes
    }

    /// Initialize from a block exercise
    init(manualSessionId: UUID, from exercise: BlockExercise, blockName: String?, sequence: Int) {
        self.manualSessionId = manualSessionId
        self.exerciseTemplateId = nil
        self.exerciseName = exercise.name
        self.blockName = blockName
        self.sequence = sequence
        self.targetSets = exercise.sets
        self.targetReps = exercise.reps
        self.targetLoad = nil
        self.loadUnit = nil
        self.restPeriodSeconds = nil
        self.notes = exercise.notes
    }
}

// MARK: - Update Manual Session Exercise DTO

/// Data transfer object for updating a manual session exercise
struct UpdateManualSessionExerciseDTO: Codable {
    let exerciseName: String?
    let blockName: String?
    let sequence: Int?
    let targetSets: Int?
    let targetReps: String?
    let targetLoad: Double?
    let loadUnit: String?
    let restPeriodSeconds: Int?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case exerciseName = "exercise_name"
        case blockName = "block_name"
        case sequence
        case targetSets = "target_sets"
        case targetReps = "target_reps"
        case targetLoad = "target_load"
        case loadUnit = "load_unit"
        case restPeriodSeconds = "rest_period_seconds"
        case notes
    }

    init(
        exerciseName: String? = nil,
        blockName: String? = nil,
        sequence: Int? = nil,
        targetSets: Int? = nil,
        targetReps: String? = nil,
        targetLoad: Double? = nil,
        loadUnit: String? = nil,
        restPeriodSeconds: Int? = nil,
        notes: String? = nil
    ) {
        self.exerciseName = exerciseName
        self.blockName = blockName
        self.sequence = sequence
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetLoad = targetLoad
        self.loadUnit = loadUnit
        self.restPeriodSeconds = restPeriodSeconds
        self.notes = notes
    }
}
