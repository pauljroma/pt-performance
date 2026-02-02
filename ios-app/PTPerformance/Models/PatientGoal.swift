//
//  PatientGoal.swift
//  PTPerformance
//
//  ACP-523: Patient Profile Goals & Progress
//

import Foundation
import SwiftUI

// MARK: - Goal Category

/// Categories for patient goals
enum GoalCategory: String, Codable, CaseIterable, Identifiable {
    case strength
    case mobility
    case endurance
    case painReduction = "pain_reduction"
    case bodyComposition = "body_composition"
    case rehabilitation
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .strength: return "Strength"
        case .mobility: return "Mobility"
        case .endurance: return "Endurance"
        case .painReduction: return "Pain Reduction"
        case .bodyComposition: return "Body Composition"
        case .rehabilitation: return "Rehabilitation"
        case .custom: return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .strength: return "dumbbell.fill"
        case .mobility: return "figure.flexibility"
        case .endurance: return "heart.circle.fill"
        case .painReduction: return "cross.circle.fill"
        case .bodyComposition: return "scalemass.fill"
        case .rehabilitation: return "bandage.fill"
        case .custom: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .strength: return .red
        case .mobility: return .blue
        case .endurance: return .green
        case .painReduction: return .purple
        case .bodyComposition: return .orange
        case .rehabilitation: return .teal
        case .custom: return .indigo
        }
    }
}

// MARK: - Goal Status

/// Status of a patient goal
enum GoalStatus: String, Codable, CaseIterable, Identifiable {
    case active
    case completed
    case paused
    case cancelled

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .active: return "Active"
        case .completed: return "Completed"
        case .paused: return "Paused"
        case .cancelled: return "Cancelled"
        }
    }
}

// MARK: - Patient Goal Model

/// A goal set by or for a patient, with measurable progress tracking
struct PatientGoal: Codable, Identifiable, Hashable, Equatable {
    let id: UUID
    let patientId: UUID
    let title: String
    let description: String?
    let category: GoalCategory
    let targetValue: Double?
    let currentValue: Double?
    let unit: String?
    let targetDate: Date?
    let status: GoalStatus
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case title
        case description
        case category
        case targetValue = "target_value"
        case currentValue = "current_value"
        case unit
        case targetDate = "target_date"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Computed Properties

    /// Progress as a value from 0.0 to 1.0, clamped
    var progress: Double {
        guard let target = targetValue, target > 0 else { return 0 }
        let current = currentValue ?? 0
        return min(max(current / target, 0), 1)
    }

    /// Whether the goal has been completed (status or progress-based)
    var isCompleted: Bool {
        status == .completed || progress >= 1.0
    }

    /// Number of days remaining until the target date, or nil if no target date
    var daysRemaining: Int? {
        guard let targetDate = targetDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: targetDate)
        return components.day
    }

    /// Formatted progress percentage string
    var progressPercentageText: String {
        let percentage = Int(progress * 100)
        return "\(percentage)%"
    }
}

// MARK: - Patient Goal Insert DTO

/// Data transfer object for creating new patient goals (excludes server-generated fields)
struct PatientGoalInsert: Codable {
    let patientId: UUID
    let title: String
    let description: String?
    let category: GoalCategory
    let targetValue: Double?
    let currentValue: Double?
    let unit: String?
    let targetDate: Date?
    let status: GoalStatus

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case title
        case description
        case category
        case targetValue = "target_value"
        case currentValue = "current_value"
        case unit
        case targetDate = "target_date"
        case status
    }
}
