//
//  ManualSession.swift
//  PTPerformance
//
//  Manual Workout Entry
//

import Foundation

// MARK: - Session Source

/// Identifies how a workout session was initiated
enum SessionSource: String, Codable, CaseIterable {
    case program = "program"
    case prescribed = "prescribed"
    case chosen = "chosen"
    case quickPick = "quick_pick"

    /// Human-readable display name
    var displayName: String {
        switch self {
        case .program: return "Program"
        case .prescribed: return "Prescribed"
        case .chosen: return "Self-Selected"
        case .quickPick: return "Quick Pick"
        }
    }

    /// SF Symbol icon name for display
    var icon: String {
        switch self {
        case .program: return "calendar.badge.checkmark"
        case .prescribed: return "person.badge.clock"
        case .chosen: return "hand.tap"
        case .quickPick: return "bolt.fill"
        }
    }

    /// Icon color for display
    var iconColorName: String {
        switch self {
        case .program: return "blue"
        case .prescribed: return "purple"
        case .chosen: return "green"
        case .quickPick: return "orange"
        }
    }
}

// MARK: - Manual Session

/// Represents a manually logged workout session
/// Maps to manual_sessions table in Supabase
struct ManualSession: Codable, Identifiable, Equatable {
    let id: UUID
    let patientId: UUID
    let name: String?
    let notes: String?
    let sourceTemplateId: UUID?
    let sourceTemplateType: String?
    let startedAt: Date?
    let completedAt: Date?
    let completed: Bool
    let totalVolume: Double?
    let avgRpe: Double?
    let avgPain: Double?
    let durationMinutes: Int?
    let createdAt: Date

    /// User ID of trainer/therapist who assigned this workout (nil for self-selected)
    let assignedByUserId: UUID?

    /// How the workout was initiated (program, prescribed, chosen, quick_pick)
    let sessionSource: SessionSource?

    /// Exercises for this manual session (loaded separately or joined)
    var exercises: [ManualSessionExercise]

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case name
        case notes
        case sourceTemplateId = "source_template_id"
        case sourceTemplateType = "source_template_type"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case completed
        case totalVolume = "total_volume"
        case avgRpe = "avg_rpe"
        case avgPain = "avg_pain"
        case durationMinutes = "duration_minutes"
        case createdAt = "created_at"
        case assignedByUserId = "assigned_by_user_id"
        case sessionSource = "session_source"
        case exercises
    }

    init(
        id: UUID = UUID(),
        patientId: UUID,
        name: String? = nil,
        notes: String? = nil,
        sourceTemplateId: UUID? = nil,
        sourceTemplateType: String? = nil,
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        completed: Bool = false,
        totalVolume: Double? = nil,
        avgRpe: Double? = nil,
        avgPain: Double? = nil,
        durationMinutes: Int? = nil,
        createdAt: Date = Date(),
        assignedByUserId: UUID? = nil,
        sessionSource: SessionSource? = .chosen,
        exercises: [ManualSessionExercise] = []
    ) {
        self.id = id
        self.patientId = patientId
        self.name = name
        self.notes = notes
        self.sourceTemplateId = sourceTemplateId
        self.sourceTemplateType = sourceTemplateType
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.completed = completed
        self.totalVolume = totalVolume
        self.avgRpe = avgRpe
        self.avgPain = avgPain
        self.durationMinutes = durationMinutes
        self.createdAt = createdAt
        self.assignedByUserId = assignedByUserId
        self.sessionSource = sessionSource
        self.exercises = exercises
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required UUIDs with fallback
        id = container.safeUUID(forKey: .id)
        patientId = container.safeUUID(forKey: .patientId)

        // Optional strings
        name = container.safeOptionalString(forKey: .name)
        notes = container.safeOptionalString(forKey: .notes)

        // Optional UUIDs
        sourceTemplateId = container.safeOptionalUUID(forKey: .sourceTemplateId)
        assignedByUserId = container.safeOptionalUUID(forKey: .assignedByUserId)

        // Optional string
        sourceTemplateType = container.safeOptionalString(forKey: .sourceTemplateType)

        // Optional dates with safe parsing
        startedAt = container.safeOptionalDate(forKey: .startedAt)
        completedAt = container.safeOptionalDate(forKey: .completedAt)

        // Bool with fallback
        completed = container.safeBool(forKey: .completed, default: false)

        // Optional doubles with safe parsing (handles PostgreSQL numeric as string)
        totalVolume = container.safeOptionalDouble(forKey: .totalVolume)
        avgRpe = container.safeOptionalDouble(forKey: .avgRpe)
        avgPain = container.safeOptionalDouble(forKey: .avgPain)

        // Optional int
        durationMinutes = container.safeOptionalInt(forKey: .durationMinutes)

        // Date with fallback
        createdAt = container.safeDate(forKey: .createdAt)

        // Optional enum
        sessionSource = container.safeOptionalEnum(SessionSource.self, forKey: .sessionSource)

        // Array with fallback to empty
        exercises = container.safeArray(of: ManualSessionExercise.self, forKey: .exercises)
    }

    // MARK: - Computed Properties

    /// Whether the session is currently in progress (started but not completed)
    var isInProgress: Bool {
        startedAt != nil && !completed && completedAt == nil
    }

    var isCompleted: Bool {
        completed || completedAt != nil
    }

    var completionStatus: String {
        if isInProgress {
            return "In Progress"
        }
        return isCompleted ? "Completed" : "Not Started"
    }

    var dateDisplay: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        if let startedAt = startedAt {
            return formatter.string(from: startedAt)
        }
        return formatter.string(from: createdAt)
    }

    var durationDisplay: String? {
        guard let minutes = durationMinutes else { return nil }
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes > 0 {
                return "\(hours)h \(remainingMinutes)m"
            }
            return "\(hours)h"
        }
        return "\(minutes)m"
    }

    var volumeDisplay: String? {
        guard let volume = totalVolume else { return nil }
        if volume >= 1000 {
            return String(format: "%.1fk lbs", volume / 1000)
        }
        return "\(Int(volume)) lbs"
    }

    static func == (lhs: ManualSession, rhs: ManualSession) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Create Manual Session DTO

/// Data transfer object for creating a manual session
struct CreateManualSessionDTO: Codable {
    let patientId: UUID
    let name: String?
    let notes: String?
    let sourceTemplateId: UUID?
    let sourceTemplateType: String?
    let startedAt: Date?
    let assignedByUserId: UUID?
    let sessionSource: String?

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case name
        case notes
        case sourceTemplateId = "source_template_id"
        case sourceTemplateType = "source_template_type"
        case startedAt = "started_at"
        case assignedByUserId = "assigned_by_user_id"
        case sessionSource = "session_source"
    }

    init(
        patientId: UUID,
        name: String? = nil,
        notes: String? = nil,
        sourceTemplateId: UUID? = nil,
        sourceTemplateType: String? = nil,
        startedAt: Date? = nil,
        assignedByUserId: UUID? = nil,
        sessionSource: SessionSource? = .chosen
    ) {
        self.patientId = patientId
        self.name = name
        self.notes = notes
        self.sourceTemplateId = sourceTemplateId
        self.sourceTemplateType = sourceTemplateType
        self.startedAt = startedAt
        self.assignedByUserId = assignedByUserId
        self.sessionSource = sessionSource?.rawValue
    }
}

// MARK: - Update Manual Session DTO

/// Data transfer object for updating a manual session
struct UpdateManualSessionDTO: Codable {
    let name: String?
    let notes: String?
    let completedAt: Date?
    let completed: Bool?
    let totalVolume: Double?
    let avgRpe: Double?
    let avgPain: Double?
    let durationMinutes: Int?

    enum CodingKeys: String, CodingKey {
        case name
        case notes
        case completedAt = "completed_at"
        case completed
        case totalVolume = "total_volume"
        case avgRpe = "avg_rpe"
        case avgPain = "avg_pain"
        case durationMinutes = "duration_minutes"
    }

    init(
        name: String? = nil,
        notes: String? = nil,
        completedAt: Date? = nil,
        completed: Bool? = nil,
        totalVolume: Double? = nil,
        avgRpe: Double? = nil,
        avgPain: Double? = nil,
        durationMinutes: Int? = nil
    ) {
        self.name = name
        self.notes = notes
        self.completedAt = completedAt
        self.completed = completed
        self.totalVolume = totalVolume
        self.avgRpe = avgRpe
        self.avgPain = avgPain
        self.durationMinutes = durationMinutes
    }
}
