//
//  BaseballPackService.swift
//  PTPerformance
//
//  Service for managing Baseball Pack premium content access and program loading
//

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

    // MARK: - Safe Accessors

    /// Featured status with false fallback
    var featured: Bool {
        isFeatured ?? false
    }

    /// Tags list with empty array fallback
    var tagsList: [String] {
        tags ?? []
    }

    /// Equipment list with empty array fallback
    var equipment: [String] {
        equipmentRequired ?? []
    }

    // MARK: - Computed Properties

    /// Get the baseball subcategory from tags
    var subcategoryEnum: BaseballPackService.ProgramCategory? {
        for tag in tagsList {
            if let category = BaseballPackService.ProgramCategory(rawValue: tag) {
                return category
            }
        }
        return nil
    }

    /// Get the position from tags
    var positionEnum: BaseballPackService.Position? {
        for tag in tagsList {
            if let position = BaseballPackService.Position(rawValue: tag) {
                return position
            }
        }
        return nil
    }

    /// Get the season type from tags
    var seasonEnum: BaseballPackService.SeasonType? {
        for tag in tagsList {
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
        if equipment.isEmpty {
            return "No equipment required"
        }
        return equipment.joined(separator: ", ")
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

// MARK: - Program Structure Models (for detailed view)

/// Phase within a baseball program
struct BaseballProgramPhaseDetail: Codable, Identifiable {
    let id: UUID
    let programId: UUID
    let name: String
    let sequence: Int
    let durationWeeks: Int?
    let goals: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case programId = "program_id"
        case name
        case sequence
        case durationWeeks = "duration_weeks"
        case goals
        case notes
    }
}

/// Session within a phase
struct BaseballSessionDetail: Codable, Identifiable {
    let id: UUID
    let phaseId: UUID
    let name: String
    let sequence: Int
    let weekday: Int?
    let isThrowingDay: Bool?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case phaseId = "phase_id"
        case name
        case sequence
        case weekday
        case isThrowingDay = "is_throwing_day"
        case notes
    }
}

/// Exercise within a session
struct BaseballSessionExercise: Codable, Identifiable {
    let id: UUID
    let sessionId: UUID
    let exerciseTemplateId: UUID
    let sequence: Int
    let blockNumber: Int?
    let blockLabel: String?
    let targetSets: Int?
    let targetReps: Int?
    let notes: String?
    let exerciseTemplate: BaseballExerciseTemplate?

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case exerciseTemplateId = "exercise_template_id"
        case sequence
        case blockNumber = "block_number"
        case blockLabel = "block_label"
        case targetSets = "target_sets"
        case targetReps = "target_reps"
        case notes
        case exerciseTemplate = "exercise_templates"
    }
}

/// Exercise template details
struct BaseballExerciseTemplate: Codable, Identifiable {
    let id: UUID
    let name: String
    let category: String?
    let bodyRegion: String?
    let equipmentType: String?
    let difficultyLevel: String?
    let techniqueCues: [String: [String]]?
    let commonMistakes: String?
    let safetyNotes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case bodyRegion = "body_region"
        case equipmentType = "equipment_type"
        case difficultyLevel = "difficulty_level"
        case techniqueCues = "technique_cues"
        case commonMistakes = "common_mistakes"
        case safetyNotes = "safety_notes"
    }
}

/// Complete program structure with phases, sessions, and exercises
struct BaseballProgramStructure {
    let program: BaseballProgram
    let phases: [PhaseWithSessions]

    struct PhaseWithSessions {
        let phase: BaseballProgramPhaseDetail
        let sessions: [SessionWithExercises]
    }

    struct SessionWithExercises {
        let session: BaseballSessionDetail
        let exercises: [BaseballSessionExercise]
    }
}

// MARK: - BaseballPackService Extension for Program Structure

extension BaseballPackService {

    /// Fetch the complete program structure including phases, sessions, and exercises
    func fetchProgramStructure(programId: UUID) async throws -> BaseballProgramStructure {
        logger.diagnostic("BaseballPackService: Fetching program structure for: \(programId)")
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // First, fetch the program library entry
            let programResponse = try await supabase.client
                .from("program_library")
                .select()
                .eq("program_id", value: programId.uuidString)
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let program = try decoder.decode(BaseballProgram.self, from: programResponse.data)

            // Fetch phases
            let phasesResponse = try await supabase.client
                .from("phases")
                .select()
                .eq("program_id", value: programId.uuidString)
                .order("sequence", ascending: true)
                .execute()

            let phases = try decoder.decode([BaseballProgramPhaseDetail].self, from: phasesResponse.data)
            logger.diagnostic("Fetched \(phases.count) phases")

            // Build structure with sessions and exercises
            var phasesWithSessions: [BaseballProgramStructure.PhaseWithSessions] = []

            for phase in phases {
                // Fetch sessions for this phase
                let sessionsResponse = try await supabase.client
                    .from("sessions")
                    .select()
                    .eq("phase_id", value: phase.id.uuidString)
                    .order("sequence", ascending: true)
                    .execute()

                let sessions = try decoder.decode([BaseballSessionDetail].self, from: sessionsResponse.data)
                logger.diagnostic("Phase '\(phase.name)' has \(sessions.count) sessions")

                var sessionsWithExercises: [BaseballProgramStructure.SessionWithExercises] = []

                for session in sessions {
                    // Fetch exercises with template details
                    let exercisesResponse = try await supabase.client
                        .from("session_exercises")
                        .select("""
                            id,
                            session_id,
                            exercise_template_id,
                            sequence,
                            block_number,
                            block_label,
                            target_sets,
                            target_reps,
                            notes,
                            exercise_templates (
                                id,
                                name,
                                category,
                                body_region,
                                equipment_type,
                                difficulty_level,
                                technique_cues,
                                common_mistakes,
                                safety_notes
                            )
                        """)
                        .eq("session_id", value: session.id.uuidString)
                        .order("sequence", ascending: true)
                        .execute()

                    let exercises = try decoder.decode([BaseballSessionExercise].self, from: exercisesResponse.data)
                    logger.diagnostic("Session '\(session.name)' has \(exercises.count) exercises")

                    sessionsWithExercises.append(
                        BaseballProgramStructure.SessionWithExercises(
                            session: session,
                            exercises: exercises
                        )
                    )
                }

                phasesWithSessions.append(
                    BaseballProgramStructure.PhaseWithSessions(
                        phase: phase,
                        sessions: sessionsWithExercises
                    )
                )
            }

            let structure = BaseballProgramStructure(
                program: program,
                phases: phasesWithSessions
            )

            logger.success("BaseballPackService", "Fetched complete program structure: \(phases.count) phases, \(phasesWithSessions.flatMap { $0.sessions }.count) sessions")
            return structure
        } catch {
            let errorMessage = "Failed to fetch program structure: \(error.localizedDescription)"
            logger.error("BaseballPackService", errorMessage)
            self.error = errorMessage
            throw error
        }
    }

    /// Fetch phases for a program (lightweight version)
    func fetchProgramPhases(programId: UUID) async throws -> [BaseballProgramPhaseDetail] {
        logger.diagnostic("BaseballPackService: Fetching phases for program: \(programId)")

        let response = try await supabase.client
            .from("phases")
            .select()
            .eq("program_id", value: programId.uuidString)
            .order("sequence", ascending: true)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let phases = try decoder.decode([BaseballProgramPhaseDetail].self, from: response.data)

        logger.success("BaseballPackService", "Fetched \(phases.count) phases")
        return phases
    }

    /// Fetch sessions with exercises for a phase
    func fetchPhaseSessions(phaseId: UUID) async throws -> [BaseballProgramStructure.SessionWithExercises] {
        logger.diagnostic("BaseballPackService: Fetching sessions for phase: \(phaseId)")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Fetch sessions
        let sessionsResponse = try await supabase.client
            .from("sessions")
            .select()
            .eq("phase_id", value: phaseId.uuidString)
            .order("sequence", ascending: true)
            .execute()

        let sessions = try decoder.decode([BaseballSessionDetail].self, from: sessionsResponse.data)

        var result: [BaseballProgramStructure.SessionWithExercises] = []

        for session in sessions {
            // Fetch exercises with template
            let exercisesResponse = try await supabase.client
                .from("session_exercises")
                .select("""
                    id,
                    session_id,
                    exercise_template_id,
                    sequence,
                    block_number,
                    block_label,
                    target_sets,
                    target_reps,
                    notes,
                    exercise_templates (
                        id,
                        name,
                        category,
                        body_region,
                        equipment_type,
                        difficulty_level,
                        technique_cues,
                        common_mistakes,
                        safety_notes
                    )
                """)
                .eq("session_id", value: session.id.uuidString)
                .order("sequence", ascending: true)
                .execute()

            let exercises = try decoder.decode([BaseballSessionExercise].self, from: exercisesResponse.data)

            result.append(
                BaseballProgramStructure.SessionWithExercises(
                    session: session,
                    exercises: exercises
                )
            )
        }

        logger.success("BaseballPackService", "Fetched \(result.count) sessions with exercises")
        return result
    }
}
