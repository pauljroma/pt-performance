import Foundation
import SwiftUI

// MARK: - RTSSport Model
// Sport definitions with default phase templates for Return-to-Sport protocols

/// Represents a sport type with associated phase templates for RTS protocols
struct RTSSport: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let category: RTSSportCategory
    let defaultPhases: [RTSPhaseTemplate]
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case defaultPhases = "default_phases"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        name: String,
        category: RTSSportCategory,
        defaultPhases: [RTSPhaseTemplate] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.defaultPhases = defaultPhases
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Sport Category

/// Categories of sports for Return-to-Sport protocols
enum RTSSportCategory: String, Codable, CaseIterable, Identifiable {
    case throwing
    case running
    case cutting

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .throwing: return "Throwing Sports"
        case .running: return "Running Sports"
        case .cutting: return "Cutting/Pivoting Sports"
        }
    }

    /// SF Symbol icon name
    var icon: String {
        switch self {
        case .throwing: return "baseball.fill"
        case .running: return "figure.run"
        case .cutting: return "arrow.triangle.branch"
        }
    }

    /// Color for UI display
    var color: Color {
        switch self {
        case .throwing: return .blue
        case .running: return .green
        case .cutting: return .orange
        }
    }
}

// MARK: - Phase Template

/// Template for defining default phases within a sport's RTS protocol
struct RTSPhaseTemplate: Codable, Hashable, Identifiable {
    var id: String { "\(phaseNumber)-\(phaseName)" }

    let phaseNumber: Int
    let phaseName: String
    let activityLevel: RTSTrafficLight
    let description: String
    let targetDurationWeeks: Int?

    enum CodingKeys: String, CodingKey {
        case phaseNumber = "phase_number"
        case phaseName = "phase_name"
        case activityLevel = "activity_level"
        case description
        case targetDurationWeeks = "target_duration_weeks"
    }

    // MARK: - Initializer

    init(
        phaseNumber: Int,
        phaseName: String,
        activityLevel: RTSTrafficLight,
        description: String,
        targetDurationWeeks: Int? = nil
    ) {
        self.phaseNumber = phaseNumber
        self.phaseName = phaseName
        self.activityLevel = activityLevel
        self.description = description
        self.targetDurationWeeks = targetDurationWeeks
    }
}

// MARK: - Sample Data

#if DEBUG
extension RTSSport {
    static let baseballSample = RTSSport(
        name: "Baseball",
        category: .throwing,
        defaultPhases: [
            RTSPhaseTemplate(
                phaseNumber: 1,
                phaseName: "Protected Motion",
                activityLevel: .red,
                description: "Pain-free ROM, no throwing",
                targetDurationWeeks: 2
            ),
            RTSPhaseTemplate(
                phaseNumber: 2,
                phaseName: "Light Tossing",
                activityLevel: .yellow,
                description: "Light catch at short distance",
                targetDurationWeeks: 2
            ),
            RTSPhaseTemplate(
                phaseNumber: 3,
                phaseName: "Long Toss",
                activityLevel: .yellow,
                description: "Progressive distance throwing",
                targetDurationWeeks: 3
            ),
            RTSPhaseTemplate(
                phaseNumber: 4,
                phaseName: "Return to Mound",
                activityLevel: .green,
                description: "Full velocity throwing, game simulation",
                targetDurationWeeks: 2
            )
        ]
    )

    static let soccerSample = RTSSport(
        name: "Soccer",
        category: .cutting,
        defaultPhases: [
            RTSPhaseTemplate(
                phaseNumber: 1,
                phaseName: "Linear Movement",
                activityLevel: .red,
                description: "Walking and light jogging only",
                targetDurationWeeks: 2
            ),
            RTSPhaseTemplate(
                phaseNumber: 2,
                phaseName: "Lateral Movement",
                activityLevel: .yellow,
                description: "Side shuffles, carioca drills",
                targetDurationWeeks: 2
            ),
            RTSPhaseTemplate(
                phaseNumber: 3,
                phaseName: "Sport-Specific Drills",
                activityLevel: .yellow,
                description: "Ball work, cutting at 50% intensity",
                targetDurationWeeks: 3
            ),
            RTSPhaseTemplate(
                phaseNumber: 4,
                phaseName: "Return to Play",
                activityLevel: .green,
                description: "Full practice, then game clearance",
                targetDurationWeeks: 2
            )
        ]
    )
}
#endif
