import Foundation
import SwiftUI

/// Represents a workout block containing a group of related exercises
struct WorkoutBlock: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let blockType: WorkoutBlockType
    let sequence: Int
    let exercises: [TemplateExercise]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case blockType = "block_type"
        case sequence
        case exercises
    }

    init(id: UUID = UUID(), name: String, blockType: WorkoutBlockType, sequence: Int, exercises: [TemplateExercise] = []) {
        self.id = id
        self.name = name
        self.blockType = blockType
        self.sequence = sequence
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

/// Types of workout blocks for organizing exercises
enum WorkoutBlockType: String, Codable, CaseIterable, Hashable {
    case cardio = "cardio"
    case dynamicStretch = "dynamic_stretch"
    case prehab = "prehab"
    case push = "push"
    case pull = "pull"
    case hinge = "hinge"
    case lungeSquat = "lunge_squat"
    case functional = "functional"
    case recovery = "recovery"

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
        }
    }
}

// MARK: - Sample Data

extension WorkoutBlock {
    static let sampleBlocks: [WorkoutBlock] = [
        WorkoutBlock(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "Warm Up",
            blockType: .dynamicStretch,
            sequence: 1,
            exercises: []
        ),
        WorkoutBlock(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            name: "Main Workout",
            blockType: .push,
            sequence: 2,
            exercises: []
        ),
        WorkoutBlock(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            name: "Cool Down",
            blockType: .recovery,
            sequence: 3,
            exercises: []
        )
    ]
}
