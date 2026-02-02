//
//  SessionIntervalBlock.swift
//  PTPerformance
//
//  Model for interval training blocks (warmups, Tabata, EMOM, etc.)
//  Used by IntervalTimerComponent and IntervalBlockView
//

import Foundation

/// Represents an exercise within an interval block
struct IntervalExercise: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let durationSeconds: Int?
    let reps: Int?
    let videoUrl: String?
    let notes: String?

    var hasVideo: Bool {
        videoUrl != nil && !videoUrl!.isEmpty
    }

    init(
        id: UUID = UUID(),
        name: String,
        durationSeconds: Int? = nil,
        reps: Int? = nil,
        videoUrl: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.durationSeconds = durationSeconds
        self.reps = reps
        self.videoUrl = videoUrl
        self.notes = notes
    }

    // MARK: - Sample Data

    static let sampleJumpingJacks = IntervalExercise(
        name: "Jumping Jacks",
        durationSeconds: 20
    )

    static let sampleBurpees = IntervalExercise(
        name: "Burpees",
        durationSeconds: 20
    )

    static let sampleHighKnees = IntervalExercise(
        name: "High Knees",
        durationSeconds: 20,
        videoUrl: "https://example.com/high-knees"
    )

    static let sampleMountainClimbers = IntervalExercise(
        name: "Mountain Climbers",
        durationSeconds: 20
    )
}

/// Represents an interval training block within a session
/// Can be used for warmups, cooldowns, or standalone interval workouts
struct SessionIntervalBlock: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let blockType: String  // "warmup", "cooldown", "tabata", "emom", "amrap", "mobility", "endurance", "recovery"
    let description: String?

    // Timing configuration
    let workDuration: Int       // Work interval in seconds
    let restDuration: Int       // Rest interval in seconds
    let rounds: Int             // Number of work/rest cycles

    // Exercises in this block
    let exercises: [IntervalExercise]

    // Completion tracking
    var isCompleted: Bool
    var sessionRpe: Int?        // RPE rating after completion (0-10)
    var totalDuration: Int?     // Actual duration in seconds when completed

    // MARK: - Computed Properties

    /// Display name for the block type
    var blockTypeDisplay: String {
        switch blockType.lowercased() {
        case "warmup": return "Warm-up"
        case "cooldown": return "Cool-down"
        case "tabata": return "Tabata"
        case "emom": return "EMOM"
        case "amrap": return "AMRAP"
        case "mobility": return "Mobility"
        case "endurance": return "Endurance"
        case "recovery": return "Recovery"
        default: return blockType.capitalized
        }
    }

    /// Formatted timing display (e.g., "20s work / 10s rest")
    var timingDisplay: String {
        if restDuration == 0 {
            return "\(workDuration)s continuous"
        }
        return "\(workDuration)s work / \(restDuration)s rest"
    }

    /// Formatted rounds display (e.g., "8 rounds")
    var roundsDisplay: String {
        return "\(rounds) round\(rounds == 1 ? "" : "s")"
    }

    /// Estimated total duration in seconds
    var estimatedDuration: Int {
        return (workDuration + restDuration) * rounds
    }

    /// Formatted estimated duration (MM:SS)
    var estimatedDurationDisplay: String {
        let minutes = estimatedDuration / 60
        let seconds = estimatedDuration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        name: String,
        blockType: String,
        description: String? = nil,
        workDuration: Int,
        restDuration: Int,
        rounds: Int,
        exercises: [IntervalExercise] = [],
        isCompleted: Bool = false,
        sessionRpe: Int? = nil,
        totalDuration: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.blockType = blockType
        self.description = description
        self.workDuration = workDuration
        self.restDuration = restDuration
        self.rounds = rounds
        self.exercises = exercises
        self.isCompleted = isCompleted
        self.sessionRpe = sessionRpe
        self.totalDuration = totalDuration
    }

    // MARK: - Sample Data

    static let sampleTabata = SessionIntervalBlock(
        name: "Tabata Circuit",
        blockType: "tabata",
        description: "High-intensity interval training with 20s work, 10s rest",
        workDuration: 20,
        restDuration: 10,
        rounds: 8,
        exercises: [
            .sampleJumpingJacks,
            .sampleBurpees,
            .sampleHighKnees,
            .sampleMountainClimbers
        ]
    )

    static let sampleCompleted = SessionIntervalBlock(
        name: "Dynamic Warm-up",
        blockType: "warmup",
        description: "Pre-workout mobility and activation",
        workDuration: 30,
        restDuration: 10,
        rounds: 5,
        exercises: [
            .sampleHighKnees,
            .sampleJumpingJacks
        ],
        isCompleted: true,
        sessionRpe: 4,
        totalDuration: 185
    )

    static let sampleWarmup = SessionIntervalBlock(
        name: "Dynamic Warm-up",
        blockType: "warmup",
        description: "5-minute dynamic warm-up routine",
        workDuration: 30,
        restDuration: 10,
        rounds: 6,
        exercises: [
            IntervalExercise(name: "Arm Circles", durationSeconds: 30),
            IntervalExercise(name: "Leg Swings", durationSeconds: 30),
            IntervalExercise(name: "Hip Circles", durationSeconds: 30)
        ]
    )

    static let sampleEMOM = SessionIntervalBlock(
        name: "10-Minute EMOM",
        blockType: "emom",
        description: "Every Minute On the Minute for 10 rounds",
        workDuration: 40,
        restDuration: 20,
        rounds: 10,
        exercises: [
            IntervalExercise(name: "Push-ups", reps: 10),
            IntervalExercise(name: "Air Squats", reps: 15)
        ]
    )
}
