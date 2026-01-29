//
//  ProgramTemplate.swift
//  PTPerformance
//
//  Program Template Library: Allows therapists to save and reuse program structures
//

import Foundation

/// A reusable program template that therapists can save and share
struct ProgramTemplate: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var programType: ProgramType
    var phases: [ProgramTemplatePhase]
    var createdBy: String?  // Therapist ID who created the template
    var isShared: Bool  // Whether this template is shared with other therapists
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        programType: ProgramType = .rehab,
        phases: [ProgramTemplatePhase] = [],
        createdBy: String? = nil,
        isShared: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.programType = programType
        self.phases = phases
        self.createdBy = createdBy
        self.isShared = isShared
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Total duration of all phases in weeks
    var totalDurationWeeks: Int {
        phases.reduce(0) { $0 + $1.durationWeeks }
    }

    /// Total number of sessions across all phases
    var totalSessionCount: Int {
        phases.reduce(0) { $0 + $1.sessionCount }
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case programType = "program_type"
        case phases
        case createdBy = "created_by"
        case isShared = "is_shared"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// A phase within a program template
struct ProgramTemplatePhase: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var durationWeeks: Int
    var goals: String?
    var sessionCount: Int
    var order: Int

    init(
        id: UUID = UUID(),
        name: String,
        durationWeeks: Int = 2,
        goals: String? = nil,
        sessionCount: Int = 0,
        order: Int = 0
    ) {
        self.id = id
        self.name = name
        self.durationWeeks = durationWeeks
        self.goals = goals
        self.sessionCount = sessionCount
        self.order = order
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case durationWeeks = "duration_weeks"
        case goals
        case sessionCount = "session_count"
        case order
    }
}

// MARK: - Sample Templates

extension ProgramTemplate {
    /// Sample templates for development and testing
    static let sampleTemplates: [ProgramTemplate] = [
        ProgramTemplate(
            name: "ACL Reconstruction Recovery",
            description: "Standard 4-phase ACL reconstruction rehabilitation protocol covering 16 weeks of progressive recovery.",
            programType: .rehab,
            phases: [
                ProgramTemplatePhase(name: "Protection Phase", durationWeeks: 2, goals: "Reduce swelling, restore ROM", sessionCount: 6, order: 1),
                ProgramTemplatePhase(name: "Early Strengthening", durationWeeks: 4, goals: "Quad activation, gait training", sessionCount: 12, order: 2),
                ProgramTemplatePhase(name: "Progressive Loading", durationWeeks: 6, goals: "Build strength, proprioception", sessionCount: 18, order: 3),
                ProgramTemplatePhase(name: "Return to Activity", durationWeeks: 4, goals: "Sport-specific training", sessionCount: 12, order: 4)
            ],
            isShared: true
        ),
        ProgramTemplate(
            name: "Rotator Cuff Repair",
            description: "Post-surgical rotator cuff rehabilitation with emphasis on protected healing and gradual strengthening.",
            programType: .rehab,
            phases: [
                ProgramTemplatePhase(name: "Immobilization", durationWeeks: 6, goals: "Protect repair, PROM only", sessionCount: 12, order: 1),
                ProgramTemplatePhase(name: "Early Motion", durationWeeks: 6, goals: "AROM, light strengthening", sessionCount: 18, order: 2),
                ProgramTemplatePhase(name: "Strengthening", durationWeeks: 6, goals: "Progressive resistance", sessionCount: 18, order: 3)
            ],
            isShared: true
        ),
        ProgramTemplate(
            name: "Athletic Performance",
            description: "8-week athletic performance program focusing on strength, power, and sport-specific conditioning.",
            programType: .performance,
            phases: [
                ProgramTemplatePhase(name: "Foundation", durationWeeks: 3, goals: "Build base strength and mobility", sessionCount: 12, order: 1),
                ProgramTemplatePhase(name: "Development", durationWeeks: 3, goals: "Power development, conditioning", sessionCount: 12, order: 2),
                ProgramTemplatePhase(name: "Peak Performance", durationWeeks: 2, goals: "Sport-specific optimization", sessionCount: 8, order: 3)
            ],
            isShared: false
        ),
        ProgramTemplate(
            name: "General Wellness",
            description: "12-week lifestyle program for general fitness and healthy living habits.",
            programType: .lifestyle,
            phases: [
                ProgramTemplatePhase(name: "Getting Started", durationWeeks: 4, goals: "Establish routine, build habits", sessionCount: 12, order: 1),
                ProgramTemplatePhase(name: "Building Momentum", durationWeeks: 4, goals: "Increase intensity, add variety", sessionCount: 12, order: 2),
                ProgramTemplatePhase(name: "Maintenance", durationWeeks: 4, goals: "Sustain progress, prevent plateaus", sessionCount: 12, order: 3)
            ],
            isShared: true
        )
    ]
}
