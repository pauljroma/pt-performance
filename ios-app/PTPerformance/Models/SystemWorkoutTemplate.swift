//
//  SystemWorkoutTemplate.swift
//  PTPerformance
//
//  Manual Workout Entry
//

import Foundation

// MARK: - Workout Exercises Structure

/// Wrapper for exercises JSONB structure: {"blocks": [...]}
struct WorkoutExercises: Codable {
    let blocks: [DatabaseBlock]

    init(blocks: [DatabaseBlock]) {
        self.blocks = blocks
    }
}

// MARK: - System Workout Template

/// Represents a system-defined workout template
/// Maps to system_workout_templates table in Supabase
struct SystemWorkoutTemplate: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String?
    let category: String?
    let difficulty: String?
    let durationMinutes: Int?
    let exerciseBlocks: [DatabaseBlock]
    let tags: [String]?
    let sourceFile: String?
    let createdAt: Date?
    let displayOrder: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case category
        case difficulty
        case durationMinutes = "duration_minutes"
        case exercises
        case tags
        case sourceFile = "source_file"
        case createdAt = "created_at"
        case displayOrder = "display_order"
    }

    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        category: String? = nil,
        difficulty: String? = nil,
        durationMinutes: Int? = nil,
        exerciseBlocks: [DatabaseBlock] = [],
        tags: [String]? = nil,
        sourceFile: String? = nil,
        createdAt: Date? = nil,
        displayOrder: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.difficulty = difficulty
        self.durationMinutes = durationMinutes
        self.exerciseBlocks = exerciseBlocks
        self.tags = tags
        self.sourceFile = sourceFile
        self.createdAt = createdAt
        self.displayOrder = displayOrder
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        difficulty = try container.decodeIfPresent(String.self, forKey: .difficulty)
        durationMinutes = try container.decodeIfPresent(Int.self, forKey: .durationMinutes)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)
        sourceFile = try container.decodeIfPresent(String.self, forKey: .sourceFile)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        displayOrder = try container.decodeIfPresent(Int.self, forKey: .displayOrder)

        // Decode exercises - handle multiple formats:
        // 1. {"blocks": [...]} wrapper structure
        // 2. Direct [DatabaseBlock] array (nested blocks)
        // 3. Flat [FlatExercise] array (grouped by block_name)
        if let wrapper = try? container.decodeIfPresent(WorkoutExercises.self, forKey: .exercises) {
            exerciseBlocks = wrapper.blocks
        } else if let directBlocks = try? container.decodeIfPresent([DatabaseBlock].self, forKey: .exercises) {
            exerciseBlocks = directBlocks
        } else if let flatExercises = try? container.decodeIfPresent([FlatExercise].self, forKey: .exercises) {
            // Group flat exercises by block_name and convert to DatabaseBlock
            exerciseBlocks = Self.groupExercisesIntoBlocks(flatExercises)
        } else {
            exerciseBlocks = []
        }
    }

    /// Group flat exercises by block_name into DatabaseBlock array
    private static func groupExercisesIntoBlocks(_ exercises: [FlatExercise]) -> [DatabaseBlock] {
        // Group exercises by block_name, maintaining order
        var blockOrder: [String] = []
        var blockExercises: [String: [FlatExercise]] = [:]

        for exercise in exercises.sorted(by: { ($0.sequence ?? 0) < ($1.sequence ?? 0) }) {
            let blockName = exercise.blockName ?? "Main"
            if !blockOrder.contains(blockName) {
                blockOrder.append(blockName)
            }
            blockExercises[blockName, default: []].append(exercise)
        }

        // Convert to DatabaseBlocks
        return blockOrder.enumerated().map { index, blockName in
            let exercises = blockExercises[blockName] ?? []
            return DatabaseBlock(
                id: UUID(),
                name: blockName,
                blockType: WorkoutBlockType.inferFromName(blockName).rawValue,
                sequence: index,
                exercises: exercises.sorted { ($0.sequence ?? 0) < ($1.sequence ?? 0) }.map { flat in
                    DatabaseExercise(
                        id: UUID(),
                        exerciseTemplateId: flat.exerciseTemplateId,
                        name: flat.exerciseName,
                        sequence: flat.sequence,
                        prescribedSets: flat.targetSets,
                        prescribedReps: flat.targetReps,
                        notes: flat.notes,
                        rpe: nil,
                        duration: nil
                    )
                }
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encodeIfPresent(difficulty, forKey: .difficulty)
        try container.encodeIfPresent(durationMinutes, forKey: .durationMinutes)
        try container.encode(WorkoutExercises(blocks: exerciseBlocks), forKey: .exercises)
        try container.encodeIfPresent(tags, forKey: .tags)
        try container.encodeIfPresent(sourceFile, forKey: .sourceFile)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(displayOrder, forKey: .displayOrder)
    }

    // MARK: - Computed Properties

    /// Total exercise count across all blocks
    var exerciseCount: Int {
        exerciseBlocks.reduce(0) { $0 + $1.exercises.count }
    }

    /// Names of all blocks in the template
    var blockNames: [String] {
        exerciseBlocks.sorted { $0.sequence < $1.sequence }.map { $0.name }
    }

    var durationDisplay: String? {
        guard let minutes = durationMinutes else { return nil }
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes > 0 {
                return "\(hours)h\(remainingMinutes)m"
            }
            return "\(hours)hr"
        }
        return "\(minutes)m"
    }

    var difficultyDisplay: String {
        difficulty?.capitalized ?? "Moderate"
    }

    /// Convert database blocks to WorkoutBlocks for UI display
    var blocks: [WorkoutBlock] {
        exerciseBlocks.sorted { $0.sequence < $1.sequence }.enumerated().map { blockIndex, dbBlock in
            let blockExercises = dbBlock.exercises
                .enumerated()
                .sorted { lhs, rhs in
                    // Sort by sequence if available, otherwise preserve original array order
                    let lSeq = lhs.element.sequence ?? lhs.offset
                    let rSeq = rhs.element.sequence ?? rhs.offset
                    return lSeq < rSeq
                }
                .map { exerciseIndex, dbExercise in
                    BlockExercise(
                        // Use deterministic ID based on template + block + exercise index to prevent
                        // SwiftUI re-render instability from generating new UUIDs each access
                        id: dbExercise.id ?? deterministicUUID(blockIndex: blockIndex, exerciseIndex: exerciseIndex),
                        name: dbExercise.name ?? "Unknown",
                        sets: dbExercise.prescribedSets,
                        reps: dbExercise.prescribedReps,
                        duration: dbExercise.duration,
                        rpe: dbExercise.rpe,
                        notes: dbExercise.notes
                    )
                }
            return WorkoutBlock(
                id: dbBlock.id ?? deterministicUUID(blockIndex: blockIndex, exerciseIndex: -1),
                name: dbBlock.name,
                blockType: WorkoutBlockType(rawValue: dbBlock.blockType ?? "") ?? WorkoutBlockType.inferFromName(dbBlock.name),
                sequence: dbBlock.sequence,
                exercises: blockExercises
            )
        }
    }

    /// Generate a deterministic UUID from template ID + indices to avoid SwiftUI instability
    private func deterministicUUID(blockIndex: Int, exerciseIndex: Int) -> UUID {
        let seed = "\(id)-block\(blockIndex)-ex\(exerciseIndex)"
        let hash = seed.utf8.reduce(into: [UInt8](repeating: 0, count: 16)) { result, byte in
            let idx = Int(byte) % 16
            result[idx] = result[idx] &+ byte
        }
        return UUID(uuid: (hash[0], hash[1], hash[2], hash[3], hash[4], hash[5], hash[6], hash[7],
                           hash[8], hash[9], hash[10], hash[11], hash[12], hash[13], hash[14], hash[15]))
    }
}

// MARK: - Database Block

/// Represents a block as stored in the database JSONB
struct DatabaseBlock: Codable {
    let id: UUID?
    let name: String
    let blockType: String?
    let sequence: Int
    let exercises: [DatabaseExercise]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case blockType = "block_type"
        case sequence
        case exercises
    }

    init(
        id: UUID? = nil,
        name: String,
        blockType: String?,
        sequence: Int,
        exercises: [DatabaseExercise]
    ) {
        self.id = id
        self.name = name
        self.blockType = blockType
        self.sequence = sequence
        self.exercises = exercises
    }
}

// MARK: - Database Exercise

/// Represents an exercise within a database block
struct DatabaseExercise: Codable {
    let id: UUID?
    let exerciseTemplateId: UUID?
    let name: String?
    let sequence: Int?
    let prescribedSets: Int?
    let prescribedReps: String?
    let notes: String?
    let rpe: Int?
    let duration: String?

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseTemplateId = "exercise_template_id"
        case name
        case sequence
        case prescribedSets = "prescribed_sets"
        case prescribedReps = "prescribed_reps"
        case notes
        case rpe
        case duration
        case sets
        case reps
    }

    init(
        id: UUID? = nil,
        exerciseTemplateId: UUID? = nil,
        name: String? = nil,
        sequence: Int? = nil,
        prescribedSets: Int? = nil,
        prescribedReps: String? = nil,
        notes: String? = nil,
        rpe: Int? = nil,
        duration: String? = nil
    ) {
        self.id = id
        self.exerciseTemplateId = exerciseTemplateId
        self.name = name
        self.sequence = sequence
        self.prescribedSets = prescribedSets
        self.prescribedReps = prescribedReps
        self.notes = notes
        self.rpe = rpe
        self.duration = duration
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id)
        exerciseTemplateId = try container.decodeIfPresent(UUID.self, forKey: .exerciseTemplateId)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        sequence = try container.decodeIfPresent(Int.self, forKey: .sequence)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        rpe = try container.decodeIfPresent(Int.self, forKey: .rpe)
        duration = try container.decodeIfPresent(String.self, forKey: .duration)

        // Handle sets: try prescribed_sets first, then sets
        if let sets = try container.decodeIfPresent(Int.self, forKey: .prescribedSets) {
            prescribedSets = sets
        } else if let sets = try container.decodeIfPresent(Int.self, forKey: .sets) {
            prescribedSets = sets
        } else {
            prescribedSets = nil
        }

        // Handle reps: try prescribed_reps first, then reps (can be String or Int)
        if let reps = try container.decodeIfPresent(String.self, forKey: .prescribedReps) {
            prescribedReps = reps
        } else if let reps = try container.decodeIfPresent(String.self, forKey: .reps) {
            prescribedReps = reps
        } else if let repsInt = try container.decodeIfPresent(Int.self, forKey: .reps) {
            prescribedReps = String(repsInt)
        } else if let repsInt = try container.decodeIfPresent(Int.self, forKey: .prescribedReps) {
            prescribedReps = String(repsInt)
        } else {
            prescribedReps = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(exerciseTemplateId, forKey: .exerciseTemplateId)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(sequence, forKey: .sequence)
        try container.encodeIfPresent(prescribedSets, forKey: .prescribedSets)
        try container.encodeIfPresent(prescribedReps, forKey: .prescribedReps)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(rpe, forKey: .rpe)
        try container.encodeIfPresent(duration, forKey: .duration)
    }
}

// MARK: - Flat Exercise (Database Format)

/// Represents an exercise in the flat database format (with block_name)
/// Used for decoding exercises from system_workout_templates
struct FlatExercise: Codable {
    let exerciseTemplateId: UUID?
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
}
