//
//  ProgramLibrary.swift
//  PTPerformance
//
//  Model representing a browsable program in the program_library table
//

import SwiftUI

/// A browsable program in the program library
struct ProgramLibrary: Codable, Identifiable, Hashable, Equatable {
    let id: UUID
    let title: String
    let description: String?
    let category: String
    let durationWeeks: Int
    let difficultyLevel: String
    let equipmentRequired: [String]?
    let coverImageUrl: String?
    let programId: UUID?
    let isFeatured: Bool?
    let tags: [String]?
    let author: String?
    let createdAt: Date?
    let updatedAt: Date?

    // New fields from premium packs migration
    let packId: UUID?
    let accessLevel: String?
    let sortOrder: Int?
    let previewVideoUrl: String?
    let requiresEquipment: Bool?

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
        case packId = "pack_id"
        case accessLevel = "access_level"
        case sortOrder = "sort_order"
        case previewVideoUrl = "preview_video_url"
        case requiresEquipment = "requires_equipment"
    }

    init(
        id: UUID,
        title: String,
        description: String? = nil,
        category: String,
        durationWeeks: Int,
        difficultyLevel: String,
        equipmentRequired: [String]? = nil,
        coverImageUrl: String? = nil,
        programId: UUID? = nil,
        isFeatured: Bool? = nil,
        tags: [String]? = nil,
        author: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        packId: UUID? = nil,
        accessLevel: String? = nil,
        sortOrder: Int? = nil,
        previewVideoUrl: String? = nil,
        requiresEquipment: Bool? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.durationWeeks = durationWeeks
        self.difficultyLevel = difficultyLevel
        self.equipmentRequired = equipmentRequired
        self.coverImageUrl = coverImageUrl
        self.programId = programId
        self.isFeatured = isFeatured
        self.tags = tags
        self.author = author
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.packId = packId
        self.accessLevel = accessLevel
        self.sortOrder = sortOrder
        self.previewVideoUrl = previewVideoUrl
        self.requiresEquipment = requiresEquipment
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required UUID with fallback
        id = container.safeUUID(forKey: .id)

        // Required strings with fallback
        title = container.safeString(forKey: .title, default: "Unknown Program")
        category = container.safeString(forKey: .category, default: "general")
        difficultyLevel = container.safeString(forKey: .difficultyLevel, default: "beginner")

        // Required int with fallback
        durationWeeks = container.safeInt(forKey: .durationWeeks, default: 1)

        // Optional strings
        description = container.safeOptionalString(forKey: .description)
        coverImageUrl = container.safeOptionalString(forKey: .coverImageUrl)
        author = container.safeOptionalString(forKey: .author)
        accessLevel = container.safeOptionalString(forKey: .accessLevel)
        previewVideoUrl = container.safeOptionalString(forKey: .previewVideoUrl)

        // Optional UUIDs
        programId = container.safeOptionalUUID(forKey: .programId)
        packId = container.safeOptionalUUID(forKey: .packId)

        // Optional arrays
        equipmentRequired = container.safeArray(of: String.self, forKey: .equipmentRequired)
        let tagsArray = container.safeArray(of: String.self, forKey: .tags)
        tags = tagsArray.isEmpty ? nil : tagsArray

        // Optional bool - preserve nil
        if container.contains(.isFeatured) {
            isFeatured = container.safeBool(forKey: .isFeatured, default: false)
        } else {
            isFeatured = nil
        }

        if container.contains(.requiresEquipment) {
            requiresEquipment = container.safeBool(forKey: .requiresEquipment, default: false)
        } else {
            requiresEquipment = nil
        }

        // Optional int
        sortOrder = container.safeOptionalInt(forKey: .sortOrder)

        // Optional dates
        createdAt = container.safeOptionalDate(forKey: .createdAt)
        updatedAt = container.safeOptionalDate(forKey: .updatedAt)
    }

    // MARK: - Safe Accessors (handle nil from database)

    /// Equipment list with empty array fallback
    var equipment: [String] {
        equipmentRequired ?? []
    }

    /// Tags list with empty array fallback
    var tagsList: [String] {
        tags ?? []
    }

    /// Featured status with false fallback
    var featured: Bool {
        isFeatured ?? false
    }

    /// Access level with free as default
    var access: String {
        accessLevel ?? "free"
    }

    /// Whether program requires premium subscription
    var isPremium: Bool {
        access == "premium" || access == "elite"
    }

    /// Whether program requires elite/pack subscription
    var isElite: Bool {
        access == "elite"
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
        case "baseball":
            return "baseball.fill"
        default:
            return "figure.run"
        }
    }

    /// Whether this program is part of the Baseball Pack (premium content)
    var isBaseballPack: Bool {
        category.lowercased() == "baseball"
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
    case baseball
    case rehab
    case performance

    var displayName: String {
        switch self {
        case .rehab: return "Rehab"
        case .performance: return "Performance"
        default: return rawValue.capitalized
        }
    }

    var icon: String {
        switch self {
        case .annuals: return "calendar"
        case .strength: return "dumbbell.fill"
        case .mobility: return "figure.flexibility"
        case .cardio: return "heart.fill"
        case .recovery: return "bed.double.fill"
        case .sport: return "sportscourt.fill"
        case .baseball: return "baseball.fill"
        case .rehab: return "cross.case.fill"
        case .performance: return "figure.run"
        }
    }

    /// Whether this category requires Baseball Pack purchase
    var requiresBaseballPack: Bool {
        self == .baseball
    }

    /// Color for the category
    var color: Color {
        switch self {
        case .annuals: return .purple
        case .strength: return .blue
        case .mobility: return .green
        case .cardio: return .red
        case .recovery: return .teal
        case .sport: return .orange
        case .baseball: return .orange
        case .rehab: return .blue
        case .performance: return .orange
        }
    }
}
