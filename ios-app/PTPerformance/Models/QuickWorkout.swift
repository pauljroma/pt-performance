//
//  QuickWorkout.swift
//  PTPerformance
//
//  ACP-842: Streak Protection Alerts
//  Quick workout model for streak protection feature
//

import Foundation

// MARK: - Quick Workout Type

/// Types of quick workouts available for streak protection
enum QuickWorkoutType: String, Codable, CaseIterable {
    case armCare = "arm_care"
    case mobility = "mobility"
    case express = "express"
    case stretching = "stretching"
    case warmup = "warmup"

    var displayName: String {
        switch self {
        case .armCare: return "Arm Care"
        case .mobility: return "Mobility"
        case .express: return "Express"
        case .stretching: return "Stretching"
        case .warmup: return "Warm-up"
        }
    }

    var iconName: String {
        switch self {
        case .armCare: return "arm.flexed.fill"
        case .mobility: return "figure.flexibility"
        case .express: return "bolt.fill"
        case .stretching: return "figure.cooldown"
        case .warmup: return "flame.fill"
        }
    }

    var color: String {
        switch self {
        case .armCare: return "orange"
        case .mobility: return "green"
        case .express: return "blue"
        case .stretching: return "purple"
        case .warmup: return "red"
        }
    }
}

// MARK: - Quick Workout Duration

/// Preset durations for quick workouts
enum QuickWorkoutDuration: Int, CaseIterable, Identifiable {
    case fiveMinutes = 5
    case tenMinutes = 10
    case fifteenMinutes = 15

    var id: Int { rawValue }

    var displayName: String {
        "\(rawValue) min"
    }

    var fullDisplayName: String {
        "\(rawValue) minutes"
    }
}

// MARK: - Quick Workout

/// Represents a quick workout option for streak protection
struct QuickWorkout: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let description: String?
    let durationMinutes: Int
    let exerciseCount: Int
    let type: QuickWorkoutType
    let exercises: [QuickWorkoutExercise]
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case durationMinutes = "duration_minutes"
        case exerciseCount = "exercise_count"
        case type
        case exercises
        case createdAt = "created_at"
    }

    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        durationMinutes: Int,
        exerciseCount: Int,
        type: QuickWorkoutType,
        exercises: [QuickWorkoutExercise] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.durationMinutes = durationMinutes
        self.exerciseCount = exerciseCount
        self.type = type
        self.exercises = exercises
        self.createdAt = createdAt
    }

    // MARK: - Computed Properties

    var durationDisplay: String {
        "\(durationMinutes) min"
    }

    var exerciseDisplay: String {
        "\(exerciseCount) exercise\(exerciseCount == 1 ? "" : "s")"
    }

    var typeIcon: String {
        type.iconName
    }
}

// MARK: - Quick Workout Exercise

/// Represents an exercise within a quick workout
struct QuickWorkoutExercise: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let durationSeconds: Int?
    let reps: Int?
    let sets: Int
    let notes: String?
    let videoUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case durationSeconds = "duration_seconds"
        case reps
        case sets
        case notes
        case videoUrl = "video_url"
    }

    init(
        id: UUID = UUID(),
        name: String,
        durationSeconds: Int? = nil,
        reps: Int? = nil,
        sets: Int = 1,
        notes: String? = nil,
        videoUrl: String? = nil
    ) {
        self.id = id
        self.name = name
        self.durationSeconds = durationSeconds
        self.reps = reps
        self.sets = sets
        self.notes = notes
        self.videoUrl = videoUrl
    }

    var prescriptionDisplay: String {
        if let duration = durationSeconds {
            let minutes = duration / 60
            let seconds = duration % 60
            if minutes > 0 {
                return sets > 1 ? "\(sets) x \(minutes):\(String(format: "%02d", seconds))" : "\(minutes):\(String(format: "%02d", seconds))"
            } else {
                return sets > 1 ? "\(sets) x \(seconds)s" : "\(seconds)s"
            }
        } else if let reps = reps {
            return sets > 1 ? "\(sets) x \(reps)" : "\(reps) reps"
        }
        return "\(sets) set\(sets == 1 ? "" : "s")"
    }
}

// MARK: - Sample Data

extension QuickWorkout {
    /// Sample 5-minute arm care routine
    static var sample5MinArmCare: QuickWorkout {
        QuickWorkout(
            name: "5-Min Arm Care",
            description: "Quick arm care routine to maintain your streak",
            durationMinutes: 5,
            exerciseCount: 4,
            type: .armCare,
            exercises: [
                QuickWorkoutExercise(name: "Wrist Circles", durationSeconds: 30, sets: 1),
                QuickWorkoutExercise(name: "Arm Circles", durationSeconds: 30, sets: 1),
                QuickWorkoutExercise(name: "Band Pull-Aparts", reps: 15, sets: 2),
                QuickWorkoutExercise(name: "Shoulder Stretch", durationSeconds: 30, sets: 2)
            ]
        )
    }

    /// Sample 10-minute mobility routine
    static var sample10MinMobility: QuickWorkout {
        QuickWorkout(
            name: "10-Min Mobility Flow",
            description: "Full body mobility to keep your streak alive",
            durationMinutes: 10,
            exerciseCount: 6,
            type: .mobility,
            exercises: [
                QuickWorkoutExercise(name: "Cat-Cow", durationSeconds: 60, sets: 1),
                QuickWorkoutExercise(name: "World's Greatest Stretch", reps: 5, sets: 2),
                QuickWorkoutExercise(name: "Hip Circles", durationSeconds: 30, sets: 2),
                QuickWorkoutExercise(name: "Thoracic Rotations", reps: 10, sets: 2),
                QuickWorkoutExercise(name: "Ankle Circles", durationSeconds: 30, sets: 2),
                QuickWorkoutExercise(name: "Deep Squat Hold", durationSeconds: 60, sets: 1)
            ]
        )
    }

    /// Sample 15-minute express workout
    static var sample15MinExpress: QuickWorkout {
        QuickWorkout(
            name: "15-Min Express Workout",
            description: "Quick full-body session when time is tight",
            durationMinutes: 15,
            exerciseCount: 5,
            type: .express,
            exercises: [
                QuickWorkoutExercise(name: "Jumping Jacks", durationSeconds: 60, sets: 1),
                QuickWorkoutExercise(name: "Push-ups", reps: 10, sets: 3),
                QuickWorkoutExercise(name: "Bodyweight Squats", reps: 15, sets: 3),
                QuickWorkoutExercise(name: "Plank", durationSeconds: 30, sets: 3),
                QuickWorkoutExercise(name: "Lunges", reps: 10, sets: 2)
            ]
        )
    }

    /// Collection of all sample quick workouts
    static var allSamples: [QuickWorkout] {
        [sample5MinArmCare, sample10MinMobility, sample15MinExpress]
    }
}
