//
//  LearningArticle.swift
//  PTPerformance
//
//  Learning article model for content library system
//

import Foundation

/// Category for learning articles (baseball content)
enum LearningCategory: String, Codable, CaseIterable, Hashable {
    case armCare = "Arm Care"
    case hitting = "Hitting"
    case injuryPrevention = "Injury Prevention"
    case mental = "Mental"
    case mobility = "Mobility"
    case nutrition = "Nutrition"
    case preparation = "Preparation"
    case recovery = "Recovery"
    case speed = "Speed"
    case training = "Training"
    case warmup = "Warmup"

    var icon: String {
        switch self {
        case .armCare:
            return "bandage.fill"
        case .hitting:
            return "figure.baseball"
        case .injuryPrevention:
            return "cross.circle.fill"
        case .mental:
            return "brain.head.profile"
        case .mobility:
            return "figure.flexibility"
        case .nutrition:
            return "leaf.fill"
        case .preparation:
            return "checklist"
        case .recovery:
            return "bed.double.fill"
        case .speed:
            return "hare.fill"
        case .training:
            return "dumbbell.fill"
        case .warmup:
            return "flame.fill"
        }
    }

    var color: String {
        switch self {
        case .armCare:
            return "blue"
        case .hitting:
            return "green"
        case .injuryPrevention:
            return "red"
        case .mental:
            return "purple"
        case .mobility:
            return "orange"
        case .nutrition:
            return "green"
        case .preparation:
            return "cyan"
        case .recovery:
            return "indigo"
        case .speed:
            return "yellow"
        case .training:
            return "red"
        case .warmup:
            return "orange"
        }
    }

    /// Map database category string to enum
    static func fromDatabaseString(_ str: String) -> LearningCategory? {
        let normalized = str.lowercased().replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")

        switch normalized {
        case "armcare":
            return .armCare
        case "hitting":
            return .hitting
        case "injuryprevention":
            return .injuryPrevention
        case "mental":
            return .mental
        case "mobility":
            return .mobility
        case "nutrition":
            return .nutrition
        case "preparation":
            return .preparation
        case "recovery":
            return .recovery
        case "speed":
            return .speed
        case "training":
            return .training
        case "warmup":
            return .warmup
        default:
            return nil
        }
    }
}

/// Learning article model for content library
struct LearningArticle: Identifiable, Codable, Hashable, Equatable {
    let id: String
    let title: String
    let content: String // Markdown content
    let category: LearningCategory
    let subcategory: String?
    let keywords: [String]
    let readingTimeMinutes: Int?
    let difficulty: String?
    let excerpt: String?

    /// Check if article matches search query
    func matches(searchText: String) -> Bool {
        if searchText.isEmpty { return true }

        let lowercased = searchText.lowercased()
        return title.lowercased().contains(lowercased) ||
               content.lowercased().contains(lowercased) ||
               (subcategory?.lowercased().contains(lowercased) ?? false) ||
               keywords.contains { $0.lowercased().contains(lowercased) }
    }
}
