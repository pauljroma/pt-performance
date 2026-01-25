//
//  PatientWorkoutTemplate.swift
//  PTPerformance
//
//  BUILD 240: Manual Workout Entry
//

import Foundation

// MARK: - Patient Workout Template

/// Represents a patient-specific workout template (customized from system template or created by clinician)
/// Maps to patient_workout_templates table in Supabase
struct PatientWorkoutTemplate: Codable, Identifiable {
    let id: UUID
    let patientId: UUID
    let name: String
    let description: String?
    let category: String?
    let exercises: [DatabaseBlock]?
    let usageCount: Int?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case name
        case description
        case category
        case exercises
        case usageCount = "usage_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID = UUID(),
        patientId: UUID,
        name: String,
        description: String? = nil,
        category: String? = nil,
        exercises: [DatabaseBlock]? = nil,
        usageCount: Int? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.patientId = patientId
        self.name = name
        self.description = description
        self.category = category
        self.exercises = exercises
        self.usageCount = usageCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Custom decoder to handle both block format and flat exercise format
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        patientId = try container.decode(UUID.self, forKey: .patientId)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        usageCount = try container.decodeIfPresent(Int.self, forKey: .usageCount)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)

        // Try to decode exercises - support both block format and flat format
        if let blocks = try? container.decodeIfPresent([DatabaseBlock].self, forKey: .exercises) {
            exercises = blocks
        } else if let flatExercises = try? container.decodeIfPresent([FlatPatientExercise].self, forKey: .exercises) {
            // Flat format: wrap in a single "Main" block
            var dbExercises: [DatabaseExercise] = []
            for (index, flat) in flatExercises.enumerated() {
                let exerciseId = flat.id ?? UUID()
                let exerciseSeq = flat.sequence ?? index
                let exerciseSets = flat.prescribedSets ?? flat.targetSets ?? 3
                let exerciseReps = flat.prescribedReps ?? flat.targetReps
                let dbExercise = DatabaseExercise(
                    id: exerciseId,
                    exerciseTemplateId: flat.exerciseTemplateId,
                    name: flat.name,
                    sequence: exerciseSeq,
                    prescribedSets: exerciseSets,
                    prescribedReps: exerciseReps,
                    notes: flat.notes
                )
                dbExercises.append(dbExercise)
            }
            let mainBlock = DatabaseBlock(
                id: UUID(),
                name: "Main",
                blockType: "strength",
                sequence: 0,
                exercises: dbExercises
            )
            exercises = [mainBlock]
        } else {
            exercises = nil
        }
    }

    // MARK: - Computed Properties

    /// Total exercise count across all blocks
    var exerciseCount: Int {
        (exercises ?? []).reduce(0) { $0 + $1.exercises.count }
    }

    /// Names of all blocks in the template
    var blockNames: [String] {
        (exercises ?? []).sorted { $0.sequence < $1.sequence }.map { $0.name }
    }

    /// Convert database blocks to WorkoutBlocks for UI display
    var blocks: [WorkoutBlock] {
        (exercises ?? []).sorted { $0.sequence < $1.sequence }.map { dbBlock in
            let blockExercises = dbBlock.exercises.map { dbExercise in
                BlockExercise(
                    id: dbExercise.id ?? UUID(),
                    name: dbExercise.name ?? "Unknown",
                    sets: dbExercise.prescribedSets,
                    reps: dbExercise.prescribedReps,
                    duration: dbExercise.duration,
                    rpe: dbExercise.rpe,
                    notes: dbExercise.notes
                )
            }
            return WorkoutBlock(
                id: dbBlock.id ?? UUID(),
                name: dbBlock.name,
                blockType: WorkoutBlockType(rawValue: dbBlock.blockType ?? "") ?? WorkoutBlockType.inferFromName(dbBlock.name),
                sequence: dbBlock.sequence,
                exercises: blockExercises
            )
        }
    }
}

// MARK: - Flat Patient Exercise (Legacy Format)

/// Flat exercise format for patient templates (legacy structure)
struct FlatPatientExercise: Codable {
    let id: UUID?
    let exerciseTemplateId: UUID?
    let name: String?
    let sequence: Int?
    let prescribedSets: Int?
    let prescribedReps: String?
    let targetSets: Int?
    let targetReps: String?
    let targetLoad: Double?
    let loadUnit: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseTemplateId = "exercise_template_id"
        case name
        case sequence
        case prescribedSets = "prescribed_sets"
        case prescribedReps = "prescribed_reps"
        case targetSets = "target_sets"
        case targetReps = "target_reps"
        case targetLoad = "target_load"
        case loadUnit = "load_unit"
        case notes
    }
}

// MARK: - Create Patient Template DTO

/// Data transfer object for creating a patient workout template
struct CreatePatientTemplateDTO: Codable {
    let patientId: UUID
    let name: String
    let description: String?
    let category: String?
    let exercises: [DatabaseBlock]

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case name
        case description
        case category
        case exercises
    }

    init(
        patientId: UUID,
        name: String,
        description: String? = nil,
        category: String? = nil,
        exercises: [DatabaseBlock] = []
    ) {
        self.patientId = patientId
        self.name = name
        self.description = description
        self.category = category
        self.exercises = exercises
    }

    /// Initialize from WorkoutBlocks
    init(patientId: UUID, name: String, description: String?, category: String? = nil, blocks: [WorkoutBlock]) {
        self.patientId = patientId
        self.name = name
        self.description = description
        self.category = category

        // Convert WorkoutBlocks to DatabaseBlocks
        self.exercises = blocks.enumerated().map { index, block in
            let dbExercises = block.exercises.map { exercise in
                DatabaseExercise(
                    id: exercise.id,
                    name: exercise.name,
                    sequence: nil,
                    prescribedSets: exercise.sets,
                    prescribedReps: exercise.reps,
                    notes: exercise.notes,
                    rpe: exercise.rpe,
                    duration: exercise.duration
                )
            }
            return DatabaseBlock(
                id: block.id,
                name: block.name,
                blockType: block.blockType.rawValue,
                sequence: index,
                exercises: dbExercises
            )
        }
    }
}
