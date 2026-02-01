//
//  BaseballPackService.swift
//  PTPerformance
//
//  Service for managing Baseball Pack premium content access and program loading
//

import Foundation
import SwiftUI

/// Service for managing Baseball Pack premium content
@MainActor
class BaseballPackService: ObservableObject {
    static let shared = BaseballPackService()

    private let supabase = PTSupabaseClient.shared
    private let logger = DebugLogger.shared

    // MARK: - Published Properties

    @Published var programs: [BaseballProgram] = []
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Baseball Program Categories

    enum ProgramCategory: String, CaseIterable, Identifiable {
        case weightedBall = "weighted_ball"
        case armCare = "arm_care"
        case velocity = "velocity"
        case positionSpecific = "position_specific"
        case seasonal = "seasonal"
        case gameDay = "game_day"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .weightedBall: return "Weighted Ball"
            case .armCare: return "Arm Care"
            case .velocity: return "Velocity Development"
            case .positionSpecific: return "Position-Specific"
            case .seasonal: return "Seasonal Training"
            case .gameDay: return "Game Day"
            }
        }

        var icon: String {
            switch self {
            case .weightedBall: return "baseball.fill"
            case .armCare: return "figure.arms.open"
            case .velocity: return "bolt.fill"
            case .positionSpecific: return "person.fill.checkmark"
            case .seasonal: return "calendar.badge.clock"
            case .gameDay: return "flag.fill"
            }
        }

        var description: String {
            switch self {
            case .weightedBall:
                return "Weighted ball programs for arm strength and throwing mechanics"
            case .armCare:
                return "Comprehensive arm care routines for injury prevention and longevity"
            case .velocity:
                return "Evidence-based velocity development protocols"
            case .positionSpecific:
                return "Tailored training programs for each baseball position"
            case .seasonal:
                return "Periodized programs aligned with baseball seasons"
            case .gameDay:
                return "Pre-game warmup and preparation routines"
            }
        }
    }

    // MARK: - Position Types

    enum Position: String, CaseIterable, Identifiable {
        case pitcher
        case catcher
        case infielder
        case outfielder

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .pitcher: return "Pitcher"
            case .catcher: return "Catcher"
            case .infielder: return "Infielder"
            case .outfielder: return "Outfielder"
            }
        }

        var icon: String {
            switch self {
            case .pitcher: return "figure.baseball"
            case .catcher: return "figure.australian.football"
            case .infielder: return "figure.run"
            case .outfielder: return "figure.track.and.field"
            }
        }
    }

    // MARK: - Season Types

    enum SeasonType: String, CaseIterable {
        case offSeason = "off_season"
        case preseason = "preseason"
        case inSeason = "in_season"
        case postSeason = "post_season"

        var displayName: String {
            switch self {
            case .offSeason: return "Off-Season"
            case .preseason: return "Pre-Season"
            case .inSeason: return "In-Season"
            case .postSeason: return "Post-Season"
            }
        }

        var description: String {
            switch self {
            case .offSeason:
                return "Build strength and address weaknesses during the off-season"
            case .preseason:
                return "Ramp up baseball-specific conditioning and skills"
            case .inSeason:
                return "Maintain performance while managing workload during competition"
            case .postSeason:
                return "Recovery and preparation for playoffs or shutdown"
            }
        }

        var focusAreas: [String] {
            switch self {
            case .offSeason:
                return ["Strength Building", "Mobility Work", "Skill Development", "Body Composition"]
            case .preseason:
                return ["Baseball Conditioning", "Throwing Progression", "Batting Practice", "Defensive Drills"]
            case .inSeason:
                return ["Recovery", "Maintenance", "Game Preparation", "Arm Care"]
            case .postSeason:
                return ["Active Recovery", "Playoff Preparation", "Mental Conditioning", "Rest"]
            }
        }
    }

    // MARK: - Initialization

    private init() {
        logger.info("BaseballPackService", "Initializing BaseballPackService")
    }

    // MARK: - Access Control

    /// Check if user has access to baseball pack content
    func hasAccess() -> Bool {
        return StoreKitService.shared.hasBaseballAccess
    }

    // MARK: - Fetch All Programs

    /// Fetch all baseball programs from Supabase
    func fetchPrograms() async throws -> [BaseballProgram] {
        logger.diagnostic("BaseballPackService: Fetching all baseball programs")
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let response = try await supabase.client
                .from("program_library")
                .select()
                .eq("category", value: "baseball")
                .order("title", ascending: true)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let programs = try decoder.decode([BaseballProgram].self, from: response.data)

            await MainActor.run {
                self.programs = programs
            }

            logger.success("BaseballPackService", "Fetched \(programs.count) baseball programs")
            return programs
        } catch {
            let errorMessage = "Failed to fetch baseball programs: \(error.localizedDescription)"
            logger.error("BaseballPackService", errorMessage)
            self.error = errorMessage
            throw error
        }
    }

    // MARK: - Fetch by Category

    /// Fetch programs by category (e.g., weighted ball, arm care, velocity)
    func fetchPrograms(category: ProgramCategory) async throws -> [BaseballProgram] {
        logger.diagnostic("BaseballPackService: Fetching programs for category: \(category.displayName)")
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // Query programs that have the category tag or match subcategory
            let response = try await supabase.client
                .from("program_library")
                .select()
                .eq("category", value: "baseball")
                .contains("tags", value: [category.rawValue])
                .order("title", ascending: true)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let programs = try decoder.decode([BaseballProgram].self, from: response.data)

            logger.success("BaseballPackService", "Fetched \(programs.count) programs for category '\(category.displayName)'")
            return programs
        } catch {
            let errorMessage = "Failed to fetch programs by category: \(error.localizedDescription)"
            logger.error("BaseballPackService", errorMessage)
            self.error = errorMessage
            throw error
        }
    }

    // MARK: - Fetch by Position

    /// Fetch programs by position (pitcher, catcher, infielder, outfielder)
    func fetchPrograms(position: Position) async throws -> [BaseballProgram] {
        logger.diagnostic("BaseballPackService: Fetching programs for position: \(position.displayName)")
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // Query programs tagged with the position
            let response = try await supabase.client
                .from("program_library")
                .select()
                .eq("category", value: "baseball")
                .contains("tags", value: [position.rawValue])
                .order("title", ascending: true)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let programs = try decoder.decode([BaseballProgram].self, from: response.data)

            logger.success("BaseballPackService", "Fetched \(programs.count) programs for position '\(position.displayName)'")
            return programs
        } catch {
            let errorMessage = "Failed to fetch programs by position: \(error.localizedDescription)"
            logger.error("BaseballPackService", errorMessage)
            self.error = errorMessage
            throw error
        }
    }

    // MARK: - Fetch by Season

    /// Fetch programs by season type (off-season, preseason, in-season, post-season)
    func fetchPrograms(season: SeasonType) async throws -> [BaseballProgram] {
        logger.diagnostic("BaseballPackService: Fetching programs for season: \(season.displayName)")
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // Query programs tagged with the season type
            let response = try await supabase.client
                .from("program_library")
                .select()
                .eq("category", value: "baseball")
                .contains("tags", value: [season.rawValue])
                .order("title", ascending: true)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let programs = try decoder.decode([BaseballProgram].self, from: response.data)

            logger.success("BaseballPackService", "Fetched \(programs.count) programs for season '\(season.displayName)'")
            return programs
        } catch {
            let errorMessage = "Failed to fetch programs by season: \(error.localizedDescription)"
            logger.error("BaseballPackService", errorMessage)
            self.error = errorMessage
            throw error
        }
    }

    // MARK: - Featured Programs

    /// Get featured/recommended baseball programs
    func getFeaturedPrograms() async throws -> [BaseballProgram] {
        logger.diagnostic("BaseballPackService: Fetching featured baseball programs")
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let response = try await supabase.client
                .from("program_library")
                .select()
                .eq("category", value: "baseball")
                .eq("is_featured", value: true)
                .order("title", ascending: true)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let programs = try decoder.decode([BaseballProgram].self, from: response.data)

            logger.success("BaseballPackService", "Fetched \(programs.count) featured baseball programs")
            return programs
        } catch {
            let errorMessage = "Failed to fetch featured programs: \(error.localizedDescription)"
            logger.error("BaseballPackService", errorMessage)
            self.error = errorMessage
            throw error
        }
    }

    // MARK: - Search Programs

    /// Search baseball programs by title or description
    func searchPrograms(query: String) async throws -> [BaseballProgram] {
        logger.diagnostic("BaseballPackService: Searching programs with query: \(query)")
        isLoading = true
        error = nil
        defer { isLoading = false }

        guard !query.isEmpty else {
            return try await fetchPrograms()
        }

        do {
            let response = try await supabase.client
                .from("program_library")
                .select()
                .eq("category", value: "baseball")
                .ilike("title", pattern: "%\(query)%")
                .order("title", ascending: true)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let programs = try decoder.decode([BaseballProgram].self, from: response.data)

            logger.success("BaseballPackService", "Found \(programs.count) programs matching '\(query)'")
            return programs
        } catch {
            let errorMessage = "Failed to search programs: \(error.localizedDescription)"
            logger.error("BaseballPackService", errorMessage)
            self.error = errorMessage
            throw error
        }
    }

    // MARK: - Fetch Single Program

    /// Fetch a single baseball program by ID
    func fetchProgram(id: UUID) async throws -> BaseballProgram {
        logger.diagnostic("BaseballPackService: Fetching program: \(id)")
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let response = try await supabase.client
                .from("program_library")
                .select()
                .eq("id", value: id.uuidString)
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let program = try decoder.decode(BaseballProgram.self, from: response.data)

            logger.success("BaseballPackService", "Fetched program: \(program.title)")
            return program
        } catch {
            let errorMessage = "Failed to fetch program: \(error.localizedDescription)"
            logger.error("BaseballPackService", errorMessage)
            self.error = errorMessage
            throw error
        }
    }

    // MARK: - Filter Programs

    /// Fetch programs with multiple filters
    func fetchPrograms(
        category: ProgramCategory? = nil,
        position: Position? = nil,
        season: SeasonType? = nil,
        difficulty: String? = nil
    ) async throws -> [BaseballProgram] {
        logger.diagnostic("BaseballPackService: Fetching programs with filters")
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            var query = supabase.client
                .from("program_library")
                .select()
                .eq("category", value: "baseball")

            // Apply tag-based filters
            var requiredTags: [String] = []
            if let category = category {
                requiredTags.append(category.rawValue)
            }
            if let position = position {
                requiredTags.append(position.rawValue)
            }
            if let season = season {
                requiredTags.append(season.rawValue)
            }

            if !requiredTags.isEmpty {
                query = query.contains("tags", value: requiredTags)
            }

            // Apply difficulty filter
            if let difficulty = difficulty, !difficulty.isEmpty {
                query = query.eq("difficulty_level", value: difficulty)
            }

            let response = try await query
                .order("title", ascending: true)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let programs = try decoder.decode([BaseballProgram].self, from: response.data)

            logger.success("BaseballPackService", "Fetched \(programs.count) programs with filters")
            return programs
        } catch {
            let errorMessage = "Failed to fetch programs with filters: \(error.localizedDescription)"
            logger.error("BaseballPackService", errorMessage)
            self.error = errorMessage
            throw error
        }
    }

    // MARK: - Clear Error

    /// Clear any existing error state
    func clearError() {
        error = nil
    }
}

// MARK: - Baseball Program Model

/// Baseball-specific program model
struct BaseballProgram: Codable, Identifiable {
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

    /// Get the baseball subcategory from tags
    var subcategoryEnum: BaseballPackService.ProgramCategory? {
        for tag in tags {
            if let category = BaseballPackService.ProgramCategory(rawValue: tag) {
                return category
            }
        }
        return nil
    }

    /// Get the position from tags
    var positionEnum: BaseballPackService.Position? {
        for tag in tags {
            if let position = BaseballPackService.Position(rawValue: tag) {
                return position
            }
        }
        return nil
    }

    /// Get the season type from tags
    var seasonEnum: BaseballPackService.SeasonType? {
        for tag in tags {
            if let season = BaseballPackService.SeasonType(rawValue: tag) {
                return season
            }
        }
        return nil
    }

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

    /// Formatted duration string
    var formattedDuration: String {
        if durationWeeks == 1 {
            return "1 week"
        } else {
            return "\(durationWeeks) weeks"
        }
    }

    /// Equipment list as formatted string
    var formattedEquipment: String {
        if equipmentRequired.isEmpty {
            return "No equipment required"
        }
        return equipmentRequired.joined(separator: ", ")
    }

    /// Icon for the subcategory
    var categoryIcon: String {
        subcategoryEnum?.icon ?? "baseball.fill"
    }

    /// Display name for the subcategory
    var categoryDisplayName: String {
        subcategoryEnum?.displayName ?? "Baseball"
    }
}
