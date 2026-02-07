import Foundation
import SwiftUI

// MARK: - Range of Motion Measurement Model
// Captures joint mobility measurements for clinical documentation

/// Side of the body for measurement
enum Side: String, Codable, CaseIterable, Identifiable {
    case left = "left"
    case right = "right"
    case bilateral = "bilateral"

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .left: return "Left"
        case .right: return "Right"
        case .bilateral: return "Bilateral"
        }
    }

    /// Abbreviation for compact display
    var abbreviation: String {
        switch self {
        case .left: return "L"
        case .right: return "R"
        case .bilateral: return "B"
        }
    }
}

/// Common joint names for ROM measurements
enum JointType: String, Codable, CaseIterable, Identifiable {
    case shoulder = "shoulder"
    case elbow = "elbow"
    case wrist = "wrist"
    case hip = "hip"
    case knee = "knee"
    case ankle = "ankle"
    case cervical = "cervical"
    case thoracic = "thoracic"
    case lumbar = "lumbar"

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .shoulder: return "Shoulder"
        case .elbow: return "Elbow"
        case .wrist: return "Wrist"
        case .hip: return "Hip"
        case .knee: return "Knee"
        case .ankle: return "Ankle"
        case .cervical: return "Cervical Spine"
        case .thoracic: return "Thoracic Spine"
        case .lumbar: return "Lumbar Spine"
        }
    }

    /// Available movements for this joint
    var availableMovements: [MovementType] {
        switch self {
        case .shoulder:
            return [.flexion, .extension, .abduction, .adduction, .internalRotation, .externalRotation]
        case .elbow:
            return [.flexion, .extension, .supination, .pronation]
        case .wrist:
            return [.flexion, .extension, .radialDeviation, .ulnarDeviation]
        case .hip:
            return [.flexion, .extension, .abduction, .adduction, .internalRotation, .externalRotation]
        case .knee:
            return [.flexion, .extension]
        case .ankle:
            return [.dorsiflexion, .plantarflexion, .inversion, .eversion]
        case .cervical, .thoracic, .lumbar:
            return [.flexion, .extension, .lateralFlexion, .rotation]
        }
    }
}

/// Movement types for ROM measurements
enum MovementType: String, Codable, CaseIterable, Identifiable {
    case flexion = "flexion"
    case `extension` = "extension"
    case abduction = "abduction"
    case adduction = "adduction"
    case internalRotation = "internal_rotation"
    case externalRotation = "external_rotation"
    case supination = "supination"
    case pronation = "pronation"
    case radialDeviation = "radial_deviation"
    case ulnarDeviation = "ulnar_deviation"
    case dorsiflexion = "dorsiflexion"
    case plantarflexion = "plantarflexion"
    case inversion = "inversion"
    case eversion = "eversion"
    case lateralFlexion = "lateral_flexion"
    case rotation = "rotation"

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .flexion: return "Flexion"
        case .extension: return "Extension"
        case .abduction: return "Abduction"
        case .adduction: return "Adduction"
        case .internalRotation: return "Internal Rotation"
        case .externalRotation: return "External Rotation"
        case .supination: return "Supination"
        case .pronation: return "Pronation"
        case .radialDeviation: return "Radial Deviation"
        case .ulnarDeviation: return "Ulnar Deviation"
        case .dorsiflexion: return "Dorsiflexion"
        case .plantarflexion: return "Plantarflexion"
        case .inversion: return "Inversion"
        case .eversion: return "Eversion"
        case .lateralFlexion: return "Lateral Flexion"
        case .rotation: return "Rotation"
        }
    }
}

/// Range of motion measurement with normal range comparison
struct ROMeasurement: Codable, Identifiable {
    var id: UUID
    var joint: String
    var movement: String
    var degrees: Int
    var normalRangeMin: Int
    var normalRangeMax: Int
    var side: Side
    var measurementMethod: String?
    var painWithMovement: Bool?
    var endFeel: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case joint
        case movement
        case degrees
        case normalRangeMin = "normal_range_min"
        case normalRangeMax = "normal_range_max"
        case side
        case measurementMethod = "measurement_method"
        case painWithMovement = "pain_with_movement"
        case endFeel = "end_feel"
        case notes
    }

    // MARK: - Computed Properties

    /// Normal range as ClosedRange
    var normalRange: ClosedRange<Int> {
        normalRangeMin...normalRangeMax
    }

    /// Whether the measurement indicates limited ROM
    var isLimited: Bool {
        degrees < normalRangeMin
    }

    /// Whether the measurement exceeds normal ROM (hypermobility)
    var isHypermobile: Bool {
        degrees > normalRangeMax
    }

    /// Percentage of normal range achieved
    var percentageOfNormal: Double {
        guard normalRangeMax > 0 else { return 0 }
        return min(100.0, (Double(degrees) / Double(normalRangeMax)) * 100.0)
    }

    /// Limitation severity based on percentage of normal
    var limitationSeverity: LimitationSeverity {
        let percentage = percentageOfNormal
        switch percentage {
        case 90...Double.infinity:
            return .none
        case 75..<90:
            return .mild
        case 50..<75:
            return .moderate
        default:
            return .severe
        }
    }

    /// Formatted measurement for display
    var formattedMeasurement: String {
        "\(degrees)\u{00B0}"
    }

    /// Formatted normal range for display
    var formattedNormalRange: String {
        "\(normalRangeMin)\u{00B0} - \(normalRangeMax)\u{00B0}"
    }

    /// Display title combining joint, movement, and side
    var displayTitle: String {
        "\(side.abbreviation) \(joint.capitalized) \(movement.replacingOccurrences(of: "_", with: " ").capitalized)"
    }

    /// Color based on limitation status
    var statusColor: Color {
        if isHypermobile {
            return .purple
        }
        switch limitationSeverity {
        case .none: return .green
        case .mild: return .yellow
        case .moderate: return .orange
        case .severe: return .red
        }
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        joint: String,
        movement: String,
        degrees: Int,
        normalRangeMin: Int,
        normalRangeMax: Int,
        side: Side,
        measurementMethod: String? = nil,
        painWithMovement: Bool? = nil,
        endFeel: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.joint = joint
        self.movement = movement
        self.degrees = degrees
        self.normalRangeMin = normalRangeMin
        self.normalRangeMax = normalRangeMax
        self.side = side
        self.measurementMethod = measurementMethod
        self.painWithMovement = painWithMovement
        self.endFeel = endFeel
        self.notes = notes
    }

    /// Convenience initializer with ClosedRange
    init(
        id: UUID = UUID(),
        joint: String,
        movement: String,
        degrees: Int,
        normalRange: ClosedRange<Int>,
        side: Side,
        measurementMethod: String? = nil,
        painWithMovement: Bool? = nil,
        endFeel: String? = nil,
        notes: String? = nil
    ) {
        self.init(
            id: id,
            joint: joint,
            movement: movement,
            degrees: degrees,
            normalRangeMin: normalRange.lowerBound,
            normalRangeMax: normalRange.upperBound,
            side: side,
            measurementMethod: measurementMethod,
            painWithMovement: painWithMovement,
            endFeel: endFeel,
            notes: notes
        )
    }
}

// MARK: - Limitation Severity

enum LimitationSeverity: String, Codable {
    case none = "none"
    case mild = "mild"
    case moderate = "moderate"
    case severe = "severe"

    var displayName: String {
        switch self {
        case .none: return "Within Normal Limits"
        case .mild: return "Mild Limitation"
        case .moderate: return "Moderate Limitation"
        case .severe: return "Severe Limitation"
        }
    }

    var color: Color {
        switch self {
        case .none: return .green
        case .mild: return .yellow
        case .moderate: return .orange
        case .severe: return .red
        }
    }
}

// MARK: - Normal ROM Reference

/// Reference values for normal ROM by joint and movement
struct ROMNormalReference {
    static func normalRange(joint: String, movement: String) -> ClosedRange<Int>? {
        let key = "\(joint.lowercased())_\(movement.lowercased())"
        return normalRanges[key]
    }

    private static let normalRanges: [String: ClosedRange<Int>] = [
        // Shoulder
        "shoulder_flexion": 150...180,
        "shoulder_extension": 40...60,
        "shoulder_abduction": 150...180,
        "shoulder_adduction": 30...50,
        "shoulder_internal_rotation": 70...90,
        "shoulder_external_rotation": 80...90,

        // Elbow
        "elbow_flexion": 140...150,
        "elbow_extension": 0...10,
        "elbow_supination": 80...90,
        "elbow_pronation": 80...90,

        // Wrist
        "wrist_flexion": 60...80,
        "wrist_extension": 60...70,
        "wrist_radial_deviation": 15...25,
        "wrist_ulnar_deviation": 30...45,

        // Hip
        "hip_flexion": 110...120,
        "hip_extension": 10...30,
        "hip_abduction": 40...50,
        "hip_adduction": 20...30,
        "hip_internal_rotation": 30...40,
        "hip_external_rotation": 40...60,

        // Knee
        "knee_flexion": 130...150,
        "knee_extension": 0...10,

        // Ankle
        "ankle_dorsiflexion": 10...20,
        "ankle_plantarflexion": 40...65,
        "ankle_inversion": 30...50,
        "ankle_eversion": 15...30,

        // Cervical Spine
        "cervical_flexion": 45...60,
        "cervical_extension": 45...75,
        "cervical_lateral_flexion": 45...60,
        "cervical_rotation": 70...90,

        // Thoracic Spine
        "thoracic_flexion": 20...45,
        "thoracic_extension": 0...25,
        "thoracic_rotation": 30...45,

        // Lumbar Spine
        "lumbar_flexion": 40...60,
        "lumbar_extension": 20...35,
        "lumbar_lateral_flexion": 15...20,
        "lumbar_rotation": 3...18
    ]
}

// MARK: - Sample Data

#if DEBUG
extension ROMeasurement {
    static let sample = ROMeasurement(
        joint: "shoulder",
        movement: "flexion",
        degrees: 140,
        normalRange: 150...180,
        side: .right,
        painWithMovement: true,
        endFeel: "Capsular",
        notes: "Pain at end range"
    )

    static let normalSample = ROMeasurement(
        joint: "knee",
        movement: "flexion",
        degrees: 145,
        normalRange: 130...150,
        side: .left
    )

    static let severeLimitationSample = ROMeasurement(
        joint: "shoulder",
        movement: "external_rotation",
        degrees: 30,
        normalRange: 80...90,
        side: .right,
        painWithMovement: true
    )
}
#endif
