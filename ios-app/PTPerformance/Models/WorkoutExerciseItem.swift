//
//  WorkoutExerciseItem.swift
//  PTPerformance
//
//  Unified exercise model for both prescribed and manual workouts
//  Enables single execution view for all workout types
//

import Foundation

/// Represents the source of a workout exercise
enum WorkoutExerciseSource {
    case prescribed(sessionExerciseId: UUID)
    case manual(manualSessionExerciseId: UUID)
}

/// Unified exercise model that can represent both prescribed and manual exercises
/// Used by the unified workout execution view
struct WorkoutExerciseItem: Identifiable {
    let id: UUID
    let name: String
    let blockType: String?
    let sequence: Int
    let targetSets: Int
    let targetReps: String
    let targetLoad: Double?
    let loadUnit: String
    let restPeriodSeconds: Int?
    let notes: String?
    let source: WorkoutExerciseSource

    // Mutable properties for tracking completion
    var actualSets: Int?
    var actualReps: [Int]?
    var actualLoad: Double?
    var rpe: Int?
    var painScore: Int?
    var completionNotes: String?

    /// Create from a prescribed Exercise
    init(from exercise: Exercise) {
        self.id = exercise.id
        self.name = exercise.exercise_name ?? "Exercise"
        self.blockType = exercise.movement_pattern
        self.sequence = exercise.sequence ?? 0
        self.targetSets = exercise.sets
        self.targetReps = exercise.prescribed_reps ?? "10"
        self.targetLoad = exercise.prescribed_load
        self.loadUnit = exercise.load_unit ?? "lbs"
        self.restPeriodSeconds = exercise.rest_period_seconds
        self.notes = exercise.notes
        self.source = .prescribed(sessionExerciseId: exercise.id)
    }

    /// Create from a ManualSessionExercise
    init(from exercise: ManualSessionExercise) {
        self.id = exercise.id
        self.name = exercise.exerciseName
        self.blockType = exercise.blockType
        self.sequence = exercise.sequence
        self.targetSets = exercise.targetSets ?? 3
        self.targetReps = exercise.targetReps ?? "10"
        self.targetLoad = exercise.targetLoad
        self.loadUnit = exercise.loadUnit ?? "lbs"
        self.restPeriodSeconds = exercise.restPeriodSeconds
        self.notes = exercise.notes
        self.source = .manual(manualSessionExerciseId: exercise.id)
    }
}

/// Represents the source of a workout session
enum WorkoutSessionSource {
    case prescribed(sessionId: UUID)
    case manual(manualSessionId: UUID)
}

/// Unified session model for both prescribed and manual workouts
struct WorkoutSessionItem: Identifiable {
    let id: UUID
    let name: String
    let notes: String?
    let source: WorkoutSessionSource
    var exercises: [WorkoutExerciseItem]

    /// Create from a prescribed Session
    init(from session: Session, exercises: [Exercise]) {
        self.id = session.id
        self.name = session.name
        self.notes = session.notes
        self.source = .prescribed(sessionId: session.id)
        self.exercises = exercises.map { WorkoutExerciseItem(from: $0) }
    }

    /// Create from a ManualSession
    init(from session: ManualSession, exercises: [ManualSessionExercise]) {
        self.id = session.id
        self.name = session.name ?? "Workout"
        self.notes = session.notes
        self.source = .manual(manualSessionId: session.id)
        self.exercises = exercises.map { WorkoutExerciseItem(from: $0) }
    }
}
