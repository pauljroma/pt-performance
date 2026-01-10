//
//  HelpArticle.swift
//  PTPerformance
//
//  Help article model for in-app help system
//

import Foundation

/// Category for help articles
enum HelpCategory: String, Codable, CaseIterable {
    case gettingStarted = "Getting Started"
    case programs = "Programs"
    case workouts = "Workouts"
    case analytics = "Analytics"

    var icon: String {
        switch self {
        case .gettingStarted:
            return "play.circle.fill"
        case .programs:
            return "doc.text.fill"
        case .workouts:
            return "figure.strengthtraining.traditional"
        case .analytics:
            return "chart.line.uptrend.xyaxis"
        }
    }
}

/// Help article model
struct HelpArticle: Identifiable, Codable {
    let id: UUID
    let title: String
    let content: String // Markdown content
    let category: HelpCategory
    let keywords: [String]

    /// Check if article matches search query
    func matches(searchText: String) -> Bool {
        if searchText.isEmpty { return true }

        let lowercased = searchText.lowercased()
        return title.lowercased().contains(lowercased) ||
               content.lowercased().contains(lowercased) ||
               keywords.contains { $0.lowercased().contains(lowercased) }
    }
}
