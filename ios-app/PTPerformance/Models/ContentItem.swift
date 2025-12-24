//
//  ContentItem.swift
//  PTPerformance
//
//  Flexible Content System Models
//  Created: 2025-12-20
//

import Foundation

// MARK: - Content Item (Universal model for all content types)

struct ContentItem: Codable, Identifiable, Hashable {
    let id: UUID
    let contentTypeId: UUID
    let slug: String
    let title: String
    let category: String
    let subcategory: String?
    let tags: [String]
    let difficulty: Difficulty?
    let content: ArticleContent
    let metadata: ArticleMetadata
    let excerpt: String?
    let estimatedDurationMinutes: Int?
    let thumbnailUrl: String?
    let prerequisites: [UUID]?
    let relatedItems: [UUID]?
    let partOfSeries: UUID?
    let sequenceNumber: Int?
    let isPublished: Bool
    let publishedAt: Date?
    let author: String?
    let reviewedBy: String?
    let viewCount: Int
    let completionCount: Int
    let helpfulCount: Int
    let averageRating: Double?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, slug, title, category, subcategory, tags, difficulty
        case content, metadata, excerpt, prerequisites, author
        case contentTypeId = "content_type_id"
        case estimatedDurationMinutes = "estimated_duration_minutes"
        case thumbnailUrl = "thumbnail_url"
        case relatedItems = "related_items"
        case partOfSeries = "part_of_series"
        case sequenceNumber = "sequence_number"
        case isPublished = "is_published"
        case publishedAt = "published_at"
        case reviewedBy = "reviewed_by"
        case viewCount = "view_count"
        case completionCount = "completion_count"
        case helpfulCount = "helpful_count"
        case averageRating = "average_rating"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    enum Difficulty: String, Codable, CaseIterable {
        case beginner = "beginner"
        case intermediate = "intermediate"
        case advanced = "advanced"

        var displayName: String {
            rawValue.capitalized
        }

        var color: String {
            switch self {
            case .beginner: return "green"
            case .intermediate: return "orange"
            case .advanced: return "red"
            }
        }
    }
}

// MARK: - Article Content (JSONB structure)

struct ArticleContent: Codable, Hashable {
    let markdown: String
    let readingTime: String?
    let references: [Reference]?

    enum CodingKeys: String, CodingKey {
        case markdown
        case readingTime = "reading_time"
        case references
    }
}

struct Reference: Codable, Hashable, Identifiable {
    var id: Int { order }
    let citation: String
    let order: Int
}

// MARK: - Article Metadata (JSONB structure)

struct ArticleMetadata: Codable, Hashable {
    let author: String?
    let reviewedBy: String?
    let evidenceLevel: String?
    let lastReviewed: String?

    enum CodingKeys: String, CodingKey {
        case author
        case reviewedBy = "reviewed_by"
        case evidenceLevel = "evidence_level"
        case lastReviewed = "last_reviewed"
    }
}

// MARK: - Search Result (Lightweight for list views)

struct ContentSearchResult: Codable, Identifiable, Hashable {
    let id: UUID
    let slug: String
    let title: String
    let category: String
    let excerpt: String?
    let difficulty: ContentItem.Difficulty?
    let estimatedDurationMinutes: Int?
    let viewCount: Int
    let helpfulCount: Int
    let rank: Float?

    enum CodingKeys: String, CodingKey {
        case id, slug, title, category, excerpt, difficulty, rank
        case estimatedDurationMinutes = "estimated_duration_minutes"
        case viewCount = "view_count"
        case helpfulCount = "helpful_count"
    }
}

// MARK: - User Progress

struct UserProgress: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let contentItemId: UUID
    let status: ProgressStatus
    let progressPercentage: Int
    let timeSpentMinutes: Int
    let startedAt: Date?
    let completedAt: Date?
    let lastAccessedAt: Date
    let progressData: [String: String]?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, status
        case userId = "user_id"
        case contentItemId = "content_item_id"
        case progressPercentage = "progress_percentage"
        case timeSpentMinutes = "time_spent_minutes"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case lastAccessedAt = "last_accessed_at"
        case progressData = "progress_data"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    enum ProgressStatus: String, Codable {
        case notStarted = "not_started"
        case inProgress = "in_progress"
        case completed = "completed"
        case skipped = "skipped"
    }
}

// MARK: - Content Type

struct ContentType: Codable, Identifiable {
    let id: UUID
    let typeKey: String
    let displayName: String
    let description: String?
    let iconName: String?
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, description
        case typeKey = "type_key"
        case displayName = "display_name"
        case iconName = "icon_name"
        case isActive = "is_active"
    }
}

// MARK: - Category Enum

enum ArticleCategory: String, CaseIterable, Identifiable {
    case armCare = "arm-care"
    case hitting = "hitting"
    case injuryPrevention = "injury-prevention"
    case mental = "mental"
    case mobility = "mobility"
    case nutrition = "nutrition"
    case recovery = "recovery"
    case speed = "speed"
    case training = "training"
    case warmup = "warmup"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .armCare: return "Arm Care"
        case .hitting: return "Hitting"
        case .injuryPrevention: return "Injury Prevention"
        case .mental: return "Mental Performance"
        case .mobility: return "Mobility"
        case .nutrition: return "Nutrition"
        case .recovery: return "Recovery"
        case .speed: return "Speed"
        case .training: return "Training"
        case .warmup: return "Warm-up"
        }
    }

    var icon: String {
        switch self {
        case .armCare: return "figure.baseball"
        case .hitting: return "figure.batting"
        case .injuryPrevention: return "cross.case.fill"
        case .mental: return "brain.head.profile"
        case .mobility: return "figure.flexibility"
        case .nutrition: return "fork.knife"
        case .recovery: return "bed.double.fill"
        case .speed: return "figure.run"
        case .training: return "dumbbell.fill"
        case .warmup: return "flame.fill"
        }
    }

    var color: String {
        switch self {
        case .armCare: return "blue"
        case .hitting: return "orange"
        case .injuryPrevention: return "red"
        case .mental: return "purple"
        case .mobility: return "green"
        case .nutrition: return "yellow"
        case .recovery: return "indigo"
        case .speed: return "pink"
        case .training: return "brown"
        case .warmup: return "orange"
        }
    }
}
