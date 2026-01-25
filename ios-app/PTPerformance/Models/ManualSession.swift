//
//  ManualSession.swift
//  PTPerformance
//
//  BUILD 240: Manual Workout Entry
//

import Foundation

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
        self.exercises = exercises
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        patientId = try container.decode(UUID.self, forKey: .patientId)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        sourceTemplateId = try container.decodeIfPresent(UUID.self, forKey: .sourceTemplateId)
        sourceTemplateType = try container.decodeIfPresent(String.self, forKey: .sourceTemplateType)
        startedAt = try container.decodeIfPresent(Date.self, forKey: .startedAt)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        completed = try container.decodeIfPresent(Bool.self, forKey: .completed) ?? false
        totalVolume = try container.decodeIfPresent(Double.self, forKey: .totalVolume)
        avgRpe = try container.decodeIfPresent(Double.self, forKey: .avgRpe)
        avgPain = try container.decodeIfPresent(Double.self, forKey: .avgPain)
        durationMinutes = try container.decodeIfPresent(Int.self, forKey: .durationMinutes)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        exercises = try container.decodeIfPresent([ManualSessionExercise].self, forKey: .exercises) ?? []
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

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case name
        case notes
        case sourceTemplateId = "source_template_id"
        case sourceTemplateType = "source_template_type"
        case startedAt = "started_at"
    }

    init(
        patientId: UUID,
        name: String? = nil,
        notes: String? = nil,
        sourceTemplateId: UUID? = nil,
        sourceTemplateType: String? = nil,
        startedAt: Date? = nil
    ) {
        self.patientId = patientId
        self.name = name
        self.notes = notes
        self.sourceTemplateId = sourceTemplateId
        self.sourceTemplateType = sourceTemplateType
        self.startedAt = startedAt
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
