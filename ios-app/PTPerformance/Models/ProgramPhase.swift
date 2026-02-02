//
//  ProgramPhase.swift
//  PTPerformance
//
//  Model representing a phase preview for program details
//

import Foundation

/// Preview data for a program phase, used to show users what's included before enrollment
struct ProgramPhasePreview: Codable, Identifiable, Hashable, Equatable {
    let id: UUID
    let phaseName: String
    let phaseNumber: Int
    let weekStart: Int
    let weekEnd: Int
    let workoutCount: Int
    let description: String?

    enum CodingKeys: String, CodingKey {
        case id
        case phaseName = "phase_name"
        case phaseNumber = "phase_number"
        case weekStart = "week_start"
        case weekEnd = "week_end"
        case workoutCount = "workout_count"
        case description
    }

    /// Formatted week range string (e.g., "Weeks 1-4" or "Week 1")
    var formattedWeekRange: String {
        if weekStart == weekEnd {
            return "Week \(weekStart)"
        } else {
            return "Weeks \(weekStart)-\(weekEnd)"
        }
    }

    /// Duration in weeks
    var durationWeeks: Int {
        weekEnd - weekStart + 1
    }
}
