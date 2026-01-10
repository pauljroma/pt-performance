//
//  IntervalTimer.swift
//  PTPerformance
//
//  Created by BUILD 116 Agent 7 (Timer Models)
//  Timer data models for interval training system
//

import Foundation

// MARK: - Timer Type Enum

/// Timer protocol type
enum TimerType: String, Codable, CaseIterable {
    case tabata = "tabata"           // 20s work / 10s rest classic
    case emom = "emom"                // Every Minute On the Minute
    case amrap = "amrap"              // As Many Rounds As Possible
    case intervals = "intervals"      // Custom interval training
    case custom = "custom"            // Fully customizable

    var displayName: String {
        switch self {
        case .tabata: return "Tabata"
        case .emom: return "EMOM"
        case .amrap: return "AMRAP"
        case .intervals: return "Intervals"
        case .custom: return "Custom"
        }
    }

    var description: String {
        switch self {
        case .tabata: return "20s work / 10s rest classic protocol"
        case .emom: return "Every minute on the minute"
        case .amrap: return "As many rounds as possible"
        case .intervals: return "Custom interval training"
        case .custom: return "Fully customizable timer"
        }
    }
}

// MARK: - Timer Category Enum

/// Timer category for organization
enum TimerCategory: String, Codable, CaseIterable {
    case cardio = "cardio"           // Cardiovascular conditioning
    case strength = "strength"       // Strength training intervals
    case warmup = "warmup"           // Pre-workout warmup
    case cooldown = "cooldown"       // Post-workout cooldown
    case recovery = "recovery"       // Active recovery sessions

    var displayName: String {
        switch self {
        case .cardio: return "Cardio"
        case .strength: return "Strength"
        case .warmup: return "Warm Up"
        case .cooldown: return "Cool Down"
        case .recovery: return "Recovery"
        }
    }

    var icon: String {
        switch self {
        case .cardio: return "heart.fill"
        case .strength: return "figure.strengthtraining.traditional"
        case .warmup: return "flame.fill"
        case .cooldown: return "snowflake"
        case .recovery: return "bed.double.fill"
        }
    }
}

// MARK: - Timer State Enum

/// Current state of the timer
enum TimerState: String, Codable {
    case idle = "idle"               // Not started
    case running = "running"         // Actively counting down
    case paused = "paused"           // Paused by user
    case completed = "completed"     // Finished all rounds

    var displayName: String {
        switch self {
        case .idle: return "Ready"
        case .running: return "Running"
        case .paused: return "Paused"
        case .completed: return "Complete"
        }
    }
}

// MARK: - Interval Template Model

/// Reusable interval timer template
struct IntervalTemplate: Codable, Identifiable {
    let id: UUID
    let name: String
    let type: TimerType
    let workSeconds: Int
    let restSeconds: Int
    let rounds: Int
    let cycles: Int
    let createdBy: UUID?
    let isPublic: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case workSeconds = "work_seconds"
        case restSeconds = "rest_seconds"
        case rounds
        case cycles
        case createdBy = "created_by"
        case isPublic = "is_public"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Total duration in seconds
    var totalDuration: Int {
        (workSeconds + restSeconds) * rounds * cycles
    }

    /// Formatted duration display
    var durationDisplay: String {
        let minutes = totalDuration / 60
        let seconds = totalDuration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Workout Timer Model

/// Patient timer session record
struct WorkoutTimer: Codable, Identifiable {
    let id: UUID
    let patientId: UUID
    let templateId: UUID?
    let startedAt: Date
    let completedAt: Date?
    let roundsCompleted: Int
    let pausedSeconds: Int
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case templateId = "template_id"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case roundsCompleted = "rounds_completed"
        case pausedSeconds = "paused_seconds"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Is this session complete?
    var isComplete: Bool {
        completedAt != nil
    }

    /// Active duration (excluding paused time)
    var activeDuration: Int {
        guard let completed = completedAt else { return 0 }
        let total = Int(completed.timeIntervalSince(startedAt))
        return total - pausedSeconds
    }
}

// MARK: - Timer Preset Model

/// Curated timer preset configuration
struct TimerPreset: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String?
    let templateJSON: TemplateConfig
    let category: TimerCategory
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case templateJSON = "template_json"
        case category
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Template configuration from JSON
    struct TemplateConfig: Codable {
        let type: TimerType
        let workSeconds: Int
        let restSeconds: Int
        let rounds: Int
        let cycles: Int

        enum CodingKeys: String, CodingKey {
            case type
            case workSeconds = "work_seconds"
            case restSeconds = "rest_seconds"
            case rounds
            case cycles
        }
    }

    /// Total duration in seconds
    var totalDuration: Int {
        (templateJSON.workSeconds + templateJSON.restSeconds) * templateJSON.rounds * templateJSON.cycles
    }

    /// Formatted duration display
    var durationDisplay: String {
        let minutes = totalDuration / 60
        let seconds = totalDuration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Create Template Input

/// Input for creating a new interval template
struct CreateIntervalTemplateInput: Codable {
    let name: String
    let type: TimerType
    let workSeconds: Int
    let restSeconds: Int
    let rounds: Int
    let cycles: Int
    let createdBy: UUID
    let isPublic: Bool

    enum CodingKeys: String, CodingKey {
        case name
        case type
        case workSeconds = "work_seconds"
        case restSeconds = "rest_seconds"
        case rounds
        case cycles
        case createdBy = "created_by"
        case isPublic = "is_public"
    }
}

// MARK: - Create Workout Timer Input

/// Input for creating a new workout timer session
struct CreateWorkoutTimerInput: Codable {
    let patientId: UUID
    let templateId: UUID?
    let startedAt: Date
    let roundsCompleted: Int
    let pausedSeconds: Int

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case templateId = "template_id"
        case startedAt = "started_at"
        case roundsCompleted = "rounds_completed"
        case pausedSeconds = "paused_seconds"
    }
}

// MARK: - Update Workout Timer Input

/// Input for updating a workout timer session
struct UpdateWorkoutTimerInput: Codable {
    let completedAt: Date?
    let roundsCompleted: Int?
    let pausedSeconds: Int?

    enum CodingKeys: String, CodingKey {
        case completedAt = "completed_at"
        case roundsCompleted = "rounds_completed"
        case pausedSeconds = "paused_seconds"
    }
}

// MARK: - Sample Data (for previews)

#if DEBUG
extension IntervalTemplate {
    static let sampleTabata = IntervalTemplate(
        id: UUID(),
        name: "Classic Tabata",
        type: .tabata,
        workSeconds: 20,
        restSeconds: 10,
        rounds: 8,
        cycles: 1,
        createdBy: nil,
        isPublic: true,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let sampleEMOM = IntervalTemplate(
        id: UUID(),
        name: "EMOM 10",
        type: .emom,
        workSeconds: 50,
        restSeconds: 10,
        rounds: 10,
        cycles: 1,
        createdBy: nil,
        isPublic: true,
        createdAt: Date(),
        updatedAt: Date()
    )
}

extension TimerPreset {
    static let sampleCardio = TimerPreset(
        id: UUID(),
        name: "Classic Tabata",
        description: "20 seconds work, 10 seconds rest, 8 rounds",
        templateJSON: TemplateConfig(
            type: .tabata,
            workSeconds: 20,
            restSeconds: 10,
            rounds: 8,
            cycles: 1
        ),
        category: .cardio,
        createdAt: Date(),
        updatedAt: Date()
    )
}
#endif
