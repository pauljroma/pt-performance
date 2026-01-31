//
//  ProgramLibrary.swift
//  PTPerformance
//
//  Model representing a browsable program in the program_library table
//

import Foundation
import SwiftUI

/// A browsable program in the program library
struct ProgramLibrary: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String?
    let category: String
    let durationWeeks: Int
    let difficultyLevel: String
    let equipmentRequired: [String]
    let coverImageUrl: String?
    let programId: UUID
    let isFeatured: Bool
    let tags: [String]
    let author: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case category
        case durationWeeks = "duration_weeks"
        case difficultyLevel = "difficulty_level"
        case equipmentRequired = "equipment_required"
        case coverImageUrl = "cover_image_url"
        case programId = "program_id"
        case isFeatured = "is_featured"
        case tags
        case author
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Computed Properties

    /// Color based on difficulty level
    var difficultyColor: Color {
        switch difficultyLevel.lowercased() {
        case "beginner":
            return .green
        case "intermediate":
            return .orange
        case "advanced":
            return .red
        default:
            return .gray
        }
    }

    /// SF Symbol based on category
    var categoryIcon: String {
        switch category.lowercased() {
        case "annuals":
            return "calendar"
        case "strength":
            return "dumbbell.fill"
        case "mobility":
            return "figure.flexibility"
        case "cardio":
            return "heart.fill"
        case "recovery":
            return "bed.double.fill"
        case "sport":
            return "sportscourt.fill"
        default:
            return "figure.run"
        }
    }

    /// Formatted duration string
    var formattedDuration: String {
        if durationWeeks == 1 {
            return "1 week"
        } else {
            return "\(durationWeeks) weeks"
        }
    }
}

// MARK: - Difficulty Level Enum (Optional helper)

enum DifficultyLevel: String, Codable, CaseIterable {
    case beginner
    case intermediate
    case advanced

    var displayName: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
}

// MARK: - Program Category Enum (Optional helper)

enum ProgramCategory: String, Codable, CaseIterable {
    case annuals
    case strength
    case mobility
    case cardio
    case recovery
    case sport

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .annuals: return "calendar"
        case .strength: return "dumbbell.fill"
        case .mobility: return "figure.flexibility"
        case .cardio: return "heart.fill"
        case .recovery: return "bed.double.fill"
        case .sport: return "sportscourt.fill"
        }
    }
}
