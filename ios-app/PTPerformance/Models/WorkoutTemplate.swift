//
//  WorkoutTemplate.swift
//  PTPerformance
//
//  Created by Build 46 Swarm Agent 2
//  Models for workout template system
//

import Foundation

// MARK: - Workout Template

/// Represents a reusable workout program template
struct WorkoutTemplate: Codable, Identifiable, Hashable {

    let id: String
    let name: String
    let description: String?
    let category: TemplateCategory
    let difficultyLevel: DifficultyLevel?
    let durationWeeks: Int?
    let createdBy: String
    let isPublic: Bool
    let tags: [String]
    let usageCount: Int
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case category
        case difficultyLevel = "difficulty_level"
        case durationWeeks = "duration_weeks"
        case createdBy = "created_by"
        case isPublic = "is_public"
        case tags
        case usageCount = "usage_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    enum TemplateCategory: String, Codable, CaseIterable {
        case strength
        case mobility
        case rehab
        case cardio
        case hybrid
        case other

        var displayName: String {
            switch self {
            case .strength: return "Strength"
            case .mobility: return "Mobility"
            case .rehab: return "Rehabilitation"
            case .cardio: return "Cardio"
            case .hybrid: return "Hybrid"
            case .other: return "Other"
            }
        }

        var icon: String {
            switch self {
            case .strength: return "dumbbell.fill"
            case .mobility: return "figure.flexibility"
            case .rehab: return "cross.case.fill"
            case .cardio: return "heart.fill"
            case .hybrid: return "sparkles"
            case .other: return "ellipsis.circle.fill"
            }
        }

        var color: String {
            switch self {
            case .strength: return "blue"
            case .mobility: return "green"
            case .rehab: return "orange"
            case .cardio: return "red"
            case .hybrid: return "purple"
            case .other: return "gray"
            }
        }
    }

    enum DifficultyLevel: String, Codable, CaseIterable {
        case beginner
        case intermediate
        case advanced

        var displayName: String {
            rawValue.capitalized
        }

        var icon: String {
            switch self {
            case .beginner: return "1.circle.fill"
            case .intermediate: return "2.circle.fill"
            case .advanced: return "3.circle.fill"
            }
        }

        var color: String {
            switch self {
            case .beginner: return "green"
            case .intermediate: return "orange"
            case .advanced: return "red"
            }
        }
    }

    // Computed properties
    var durationDescription: String {
        guard let weeks = durationWeeks else { return "Variable duration" }
        return "\(weeks) \(weeks == 1 ? "week" : "weeks")"
    }

    var isPopular: Bool {
        usageCount >= 10
    }
}

// MARK: - Template Phase

/// Represents a phase within a workout template
struct TemplatePhase: Codable, Identifiable, Hashable {

    let id: String
    let templateId: String
    let name: String
    let description: String?
    let sequence: Int
    let durationWeeks: Int?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case templateId = "template_id"
        case name
        case description
        case sequence
        case durationWeeks = "duration_weeks"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Computed properties
    var durationDescription: String {
        guard let weeks = durationWeeks else { return "Ongoing" }
        return "\(weeks) \(weeks == 1 ? "week" : "weeks")"
    }
}

// MARK: - Template Session

/// Represents a session within a template phase
struct TemplateSession: Codable, Identifiable, Hashable {

    let id: String
    let phaseId: String
    let name: String
    let description: String?
    let sequence: Int
    let exercises: [TemplateExercise]
    let notes: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case phaseId = "phase_id"
        case name
        case description
        case sequence
        case exercises
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Computed properties
    var exerciseCount: Int {
        exercises.count
    }

    var estimatedDuration: Int {
        // Estimate ~3-5 minutes per exercise
        exerciseCount * 4
    }
}

// MARK: - Template Exercise

/// Represents an exercise configuration within a template session
struct TemplateExercise: Codable, Hashable {

    let exerciseId: String
    let sequence: Int
    let sets: Int
    let reps: Int?
    let duration: Int? // Duration in seconds
    let rest: Int? // Rest in seconds
    let notes: String?
    let weight: Double? // Suggested weight
    let intensity: String? // e.g., "RPE 7-8", "70% 1RM"

    enum CodingKeys: String, CodingKey {
        case exerciseId = "exercise_id"
        case sequence
        case sets
        case reps
        case duration
        case rest
        case notes
        case weight
        case intensity
    }

    // Computed properties
    var setsRepsDisplay: String {
        if let reps = reps {
            return "\(sets) x \(reps)"
        } else if let duration = duration {
            let minutes = duration / 60
            let seconds = duration % 60
            if minutes > 0 {
                return "\(sets) x \(minutes):\(String(format: "%02d", seconds))"
            } else {
                return "\(sets) x \(seconds)s"
            }
        } else {
            return "\(sets) sets"
        }
    }

    var restDisplay: String? {
        guard let rest = rest else { return nil }
        let minutes = rest / 60
        let seconds = rest % 60
        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", seconds)) rest"
        } else {
            return "\(seconds)s rest"
        }
    }
}

// MARK: - Template with Details

/// Extended template model with phases and sessions
struct WorkoutTemplateDetail: Codable, Identifiable {
    let template: WorkoutTemplate
    let phases: [TemplatePhaseDetail]

    var id: String { template.id }

    // Computed properties
    var totalSessions: Int {
        phases.reduce(0) { $0 + $1.sessions.count }
    }

    var totalExercises: Int {
        phases.reduce(0) { total, phase in
            total + phase.sessions.reduce(0) { $0 + $1.exerciseCount }
        }
    }
}

/// Extended phase model with sessions
struct TemplatePhaseDetail: Codable, Identifiable {
    let phase: TemplatePhase
    let sessions: [TemplateSession]

    var id: String { phase.id }
}

// MARK: - Template Statistics

/// Statistics for a workout template
struct TemplateStatistics: Codable {
    let templateId: String
    let phaseCount: Int
    let totalSessions: Int
    let usageCount: Int
    let averageRating: Double?

    enum CodingKeys: String, CodingKey {
        case templateId = "template_id"
        case phaseCount = "phase_count"
        case totalSessions = "total_sessions"
        case usageCount = "usage_count"
        case averageRating = "average_rating"
    }
}

// MARK: - Sample Data

extension WorkoutTemplate {
    static var sample: WorkoutTemplate {
        WorkoutTemplate(
            id: UUID().uuidString,
            name: "ACL Rehabilitation Program",
            description: "Comprehensive post-surgery ACL rehabilitation focusing on strength, stability, and return to sport",
            category: .rehab,
            difficultyLevel: .intermediate,
            durationWeeks: 12,
            createdBy: UUID().uuidString,
            isPublic: true,
            tags: ["ACL", "Knee", "Post-Surgery", "Sport"],
            usageCount: 24,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    static var sampleStrength: WorkoutTemplate {
        WorkoutTemplate(
            id: UUID().uuidString,
            name: "Upper Body Strength Builder",
            description: "Progressive overload program for upper body strength development",
            category: .strength,
            difficultyLevel: .advanced,
            durationWeeks: 8,
            createdBy: UUID().uuidString,
            isPublic: true,
            tags: ["Strength", "Upper Body", "Progressive Overload"],
            usageCount: 15,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    static var sampleMobility: WorkoutTemplate {
        WorkoutTemplate(
            id: UUID().uuidString,
            name: "Daily Mobility Flow",
            description: "20-minute daily mobility routine for improved flexibility and joint health",
            category: .mobility,
            difficultyLevel: .beginner,
            durationWeeks: 4,
            createdBy: UUID().uuidString,
            isPublic: true,
            tags: ["Mobility", "Flexibility", "Daily", "Recovery"],
            usageCount: 42,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

extension TemplatePhase {
    static var sample: TemplatePhase {
        TemplatePhase(
            id: UUID().uuidString,
            templateId: UUID().uuidString,
            name: "Foundation Phase",
            description: "Build basic strength and stability",
            sequence: 1,
            durationWeeks: 4,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

extension TemplateSession {
    static var sample: TemplateSession {
        TemplateSession(
            id: UUID().uuidString,
            phaseId: UUID().uuidString,
            name: "Lower Body Strength",
            description: "Focus on compound movements",
            sequence: 1,
            exercises: [
                TemplateExercise(
                    exerciseId: UUID().uuidString,
                    sequence: 1,
                    sets: 3,
                    reps: 10,
                    duration: nil,
                    rest: 90,
                    notes: "Focus on controlled eccentric",
                    weight: 135,
                    intensity: "RPE 7-8"
                ),
                TemplateExercise(
                    exerciseId: UUID().uuidString,
                    sequence: 2,
                    sets: 3,
                    reps: 12,
                    duration: nil,
                    rest: 60,
                    notes: nil,
                    weight: 95,
                    intensity: nil
                )
            ],
            notes: "Warm up thoroughly before starting",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
