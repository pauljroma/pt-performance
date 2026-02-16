//
//  WorkoutBlock.swift
//  PTPerformance
//
//  Manual Workout Entry
//

import SwiftUI

// MARK: - Workout Block Type

/// Types of workout blocks for organizing exercises
enum WorkoutBlockType: String, Codable, CaseIterable, Hashable, Sendable {
    case cardio = "cardio"
    case dynamicStretch = "dynamic_stretch"
    case prehab = "prehab"
    case push = "push"
    case pull = "pull"
    case hinge = "hinge"
    case lungeSquat = "lunge_squat"
    case functional = "functional"
    case recovery = "recovery"
    case unknown = "unknown"

    /// Custom decoder that falls back to `.unknown` for unrecognized values
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Self(rawValue: rawValue) ?? .unknown
    }

    var displayName: String {
        switch self {
        case .cardio:
            return "Cardio"
        case .dynamicStretch:
            return "Dynamic Stretch"
        case .prehab:
            return "Prehab"
        case .push:
            return "Push"
        case .pull:
            return "Pull"
        case .hinge:
            return "Hinge"
        case .lungeSquat:
            return "Lunge & Squat"
        case .functional:
            return "Functional"
        case .recovery:
            return "Recovery"
        case .unknown:
            return "Unknown"
        }
    }

    var icon: String {
        switch self {
        case .cardio:
            return "heart.circle.fill"
        case .dynamicStretch:
            return "figure.flexibility"
        case .prehab:
            return "cross.circle.fill"
        case .push:
            return "arrow.up.circle.fill"
        case .pull:
            return "arrow.down.circle.fill"
        case .hinge:
            return "arrow.triangle.2.circlepath"
        case .lungeSquat:
            return "figure.walk"
        case .functional:
            return "figure.mixed.cardio"
        case .recovery:
            return "leaf.circle.fill"
        case .unknown:
            return "questionmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .cardio:
            return .red
        case .dynamicStretch:
            return .orange
        case .prehab:
            return .pink
        case .push:
            return .blue
        case .pull:
            return .purple
        case .hinge:
            return .green
        case .lungeSquat:
            return .teal
        case .functional:
            return .indigo
        case .recovery:
            return .mint
        case .unknown:
            return .gray
        }
    }

    var description: String {
        switch self {
        case .cardio:
            return "Cardiovascular exercises to elevate heart rate"
        case .dynamicStretch:
            return "Dynamic stretching and mobility work"
        case .prehab:
            return "Preventive exercises for injury prevention"
        case .push:
            return "Pushing movements (chest, shoulders, triceps)"
        case .pull:
            return "Pulling movements (back, biceps)"
        case .hinge:
            return "Hip hinge movements (deadlifts, RDLs)"
        case .lungeSquat:
            return "Lower body compound movements"
        case .functional:
            return "Functional and multi-joint movements"
        case .recovery:
            return "Cool down and recovery exercises"
        case .unknown:
            return "Unknown exercise type"
        }
    }

    var sortOrder: Int {
        switch self {
        case .cardio:
            return 0
        case .dynamicStretch:
            return 1
        case .prehab:
            return 2
        case .push:
            return 3
        case .pull:
            return 4
        case .hinge:
            return 5
        case .lungeSquat:
            return 6
        case .functional:
            return 7
        case .recovery:
            return 8
        case .unknown:
            return 99
        }
    }

    /// Categories and body regions that are suggested for this block type
    /// Used to filter exercises in the exercise picker
    var suggestedCategories: [String] {
        switch self {
        case .cardio:
            return ["cardio", "conditioning", "warm-up"]
        case .dynamicStretch:
            return ["mobility", "stretch", "dynamic", "warm-up", "flexibility"]
        case .prehab:
            return ["prehab", "activation", "corrective", "stability"]
        case .push:
            return ["strength", "push", "press"]
        case .pull:
            return ["strength", "pull", "row"]
        case .hinge:
            return ["strength", "hinge", "deadlift"]
        case .lungeSquat:
            return ["strength", "squat", "lunge", "lower"]
        case .functional:
            return ["functional", "core", "plyometric", "power"]
        case .recovery:
            return ["recovery", "stretch", "foam roll", "cool-down", "mobility"]
        case .unknown:
            return []
        }
    }

    /// Body regions that are suggested for this block type
    var suggestedBodyRegions: [String] {
        switch self {
        case .cardio:
            return ["full body", "lower body", "cardio"]
        case .dynamicStretch:
            return ["full body", "hip", "shoulder", "thoracic", "ankle"]
        case .prehab:
            return ["shoulder", "hip", "core", "knee", "ankle"]
        case .push:
            return ["chest", "shoulder", "triceps", "upper body"]
        case .pull:
            return ["back", "biceps", "upper body", "lats"]
        case .hinge:
            return ["posterior chain", "hamstring", "glute", "lower back"]
        case .lungeSquat:
            return ["quad", "glute", "lower body", "leg"]
        case .functional:
            return ["core", "full body"]
        case .recovery:
            return ["full body", "hip", "shoulder", "back", "leg"]
        case .unknown:
            return []
        }
    }

    /// Check if an exercise matches this block type based on category and body region
    func matchesExercise(category: String?, bodyRegion: String?) -> Bool {
        let categoryMatch = category.map { cat in
            suggestedCategories.contains { suggested in
                cat.localizedCaseInsensitiveContains(suggested) ||
                suggested.localizedCaseInsensitiveContains(cat)
            }
        } ?? false

        let bodyRegionMatch = bodyRegion.map { region in
            suggestedBodyRegions.contains { suggested in
                region.localizedCaseInsensitiveContains(suggested) ||
                suggested.localizedCaseInsensitiveContains(region)
            }
        } ?? false

        return categoryMatch || bodyRegionMatch
    }

    /// Get sort order for a block name string
    static func sortOrder(for name: String) -> Int {
        let blockType = inferFromName(name)
        return blockType.sortOrder
    }

    /// Infer block type from a block name string
    static func inferFromName(_ name: String) -> WorkoutBlockType {
        let lowercased = name.lowercased()
        if lowercased.contains("cardio") || lowercased.contains("warm") || lowercased.contains("active") {
            return .cardio
        } else if lowercased.contains("dynamic") || lowercased.contains("stretch") || lowercased.contains("mobility") {
            return .dynamicStretch
        } else if lowercased.contains("prehab") || lowercased.contains("activation") {
            return .prehab
        } else if lowercased.contains("push") || lowercased.contains("press") || lowercased.contains("chest") {
            return .push
        } else if lowercased.contains("pull") || lowercased.contains("row") || lowercased.contains("back") {
            return .pull
        } else if lowercased.contains("hinge") || lowercased.contains("deadlift") || lowercased.contains("rdl") {
            return .hinge
        } else if lowercased.contains("lunge") || lowercased.contains("squat") || lowercased.contains("leg") {
            return .lungeSquat
        } else if lowercased.contains("functional") || lowercased.contains("conditioning") || lowercased.contains("finisher") {
            return .functional
        } else if lowercased.contains("recovery") || lowercased.contains("cool") || lowercased.contains("foam") {
            return .recovery
        } else if lowercased.contains("strength") {
            return .push // Default strength to push
        }
        return .functional // Default fallback
    }
}

// MARK: - Block Exercise

/// Represents an exercise within a workout block
struct BlockExercise: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let sets: Int?
    let reps: String?
    let duration: String?
    let rpe: Int?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case sets
        case reps
        case duration
        case rpe
        case notes
    }

    init(
        id: UUID = UUID(),
        name: String,
        sets: Int? = nil,
        reps: String? = nil,
        duration: String? = nil,
        rpe: Int? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.sets = sets
        self.reps = reps
        self.duration = duration
        self.rpe = rpe
        self.notes = notes
    }

    var setsRepsDisplay: String {
        if let sets = sets, let reps = reps {
            return "\(sets) x \(reps)"
        } else if let sets = sets {
            return "\(sets) sets"
        } else if let duration = duration {
            return duration
        }
        return ""
    }

    // MARK: - Backward Compatibility Properties

    /// Alias for sets (for compatibility with code expecting prescribedSets)
    var prescribedSets: Int? { sets }

    /// Alias for reps (for compatibility with code expecting prescribedReps)
    var prescribedReps: String? { reps }

    /// Load is not stored in BlockExercise (always nil)
    var prescribedLoad: Double? { nil }

    /// Load unit is not stored in BlockExercise (always nil)
    var loadUnit: String? { nil }

    /// Rest period is not stored in BlockExercise (always nil)
    var restPeriodSeconds: Int? { nil }
}

// MARK: - Workout Block

/// Represents a workout block containing a group of related exercises
struct WorkoutBlock: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let blockType: WorkoutBlockType
    let sequence: Int
    let exercises: [BlockExercise]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case blockType = "block_type"
        case sequence
        case exercises
    }

    init(
        id: UUID = UUID(),
        name: String,
        blockType: WorkoutBlockType,
        sequence: Int,
        exercises: [BlockExercise] = []
    ) {
        self.id = id
        self.name = name
        self.blockType = blockType
        self.sequence = sequence
        self.exercises = exercises
    }

    /// Convenience initializer for creating blocks from template data
    init(name: String, exercises: [BlockExercise]) {
        self.id = UUID()
        self.name = name
        self.blockType = WorkoutBlockType.inferFromName(name)
        self.sequence = 0
        self.exercises = exercises
    }

    var exerciseCount: Int {
        exercises.count
    }

    var displayName: String {
        name.isEmpty ? blockType.displayName : name
    }

    var icon: String {
        blockType.icon
    }

    var color: Color {
        blockType.color
    }
}

// MARK: - Type Alias

/// JSONB structure for workout blocks stored in templates
typealias WorkoutBlocks = [WorkoutBlock]

// MARK: - Sample Data

extension WorkoutBlock {
    static let sampleBlocks: [WorkoutBlock] = [
        WorkoutBlock(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "Warm Up",
            blockType: WorkoutBlockType.dynamicStretch,
            sequence: 1,
            exercises: []
        ),
        WorkoutBlock(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            name: "Main Workout",
            blockType: WorkoutBlockType.push,
            sequence: 2,
            exercises: []
        ),
        WorkoutBlock(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            name: "Cool Down",
            blockType: WorkoutBlockType.recovery,
            sequence: 3,
            exercises: []
        )
    ]
}
