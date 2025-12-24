import Foundation

/// Help article model for in-app help system
struct HelpArticle: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let category: String
    let content: String
    let tags: [String]
    let relatedArticleIds: [String]?
    let lastUpdated: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case category
        case content
        case tags
        case relatedArticleIds = "related_article_ids"
        case lastUpdated = "last_updated"
    }

    /// Computed relevance score for search results
    func relevanceScore(for searchTerm: String) -> Double {
        guard !searchTerm.isEmpty else { return 0.0 }

        let lowercasedSearch = searchTerm.lowercased()
        var score = 0.0

        // Title match (highest weight)
        if title.lowercased().contains(lowercasedSearch) {
            score += 10.0
            // Exact title match gets bonus
            if title.lowercased() == lowercasedSearch {
                score += 15.0
            }
        }

        // Category match
        if category.lowercased().contains(lowercasedSearch) {
            score += 5.0
        }

        // Tags match
        for tag in tags {
            if tag.lowercased().contains(lowercasedSearch) {
                score += 3.0
            }
        }

        // Content match (lower weight)
        if content.lowercased().contains(lowercasedSearch) {
            score += 1.0
        }

        return score
    }

    /// Check if article matches search term
    func matches(searchTerm: String) -> Bool {
        guard !searchTerm.isEmpty else { return true }

        let lowercasedSearch = searchTerm.lowercased()
        return title.lowercased().contains(lowercasedSearch) ||
               category.lowercased().contains(lowercasedSearch) ||
               tags.contains(where: { $0.lowercased().contains(lowercasedSearch) }) ||
               content.lowercased().contains(lowercasedSearch)
    }

    /// Format last updated date for display
    var formattedLastUpdated: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        if let date = dateFormatter.date(from: lastUpdated) {
            dateFormatter.dateStyle = .medium
            return dateFormatter.string(from: date)
        }

        return lastUpdated
    }
}

// MARK: - Category Enumeration

extension HelpArticle {
    enum Category: String, CaseIterable, Identifiable {
        case gettingStarted = "Getting Started"
        case exercises = "Exercises"
        case programs = "Programs"
        case readiness = "Readiness"
        case scheduling = "Scheduling"
        case troubleshooting = "Troubleshooting"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .gettingStarted: return "star.fill"
            case .exercises: return "figure.walk"
            case .programs: return "list.bullet.clipboard.fill"
            case .readiness: return "heart.fill"
            case .scheduling: return "calendar"
            case .troubleshooting: return "wrench.fill"
            }
        }

        var color: String {
            switch self {
            case .gettingStarted: return "blue"
            case .exercises: return "green"
            case .programs: return "purple"
            case .readiness: return "red"
            case .scheduling: return "orange"
            case .troubleshooting: return "gray"
            }
        }
    }
}
