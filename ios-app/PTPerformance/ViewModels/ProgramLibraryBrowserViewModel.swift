//
//  ProgramLibraryBrowserViewModel.swift
//  PTPerformance
//
//  ViewModel for browsing and discovering programs in the program library
//
//  ACP-1031: Enhanced program browser with duration/equipment/goal filters,
//  sorting options, and first-week preview support
//

import SwiftUI

// MARK: - Sort Option

enum ProgramSortOption: String, CaseIterable, Identifiable {
    case popular = "Popular"
    case newest = "Newest"
    case duration = "Duration"
    case difficulty = "Difficulty"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .popular: return "flame.fill"
        case .newest: return "clock.fill"
        case .duration: return "calendar"
        case .difficulty: return "chart.bar.fill"
        }
    }
}

// MARK: - Duration Filter

enum DurationFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case short = "4 Week"
    case medium = "8 Week"
    case long = "12 Week"

    var id: String { rawValue }

    /// Returns the range of weeks this filter accepts
    var weekRange: ClosedRange<Int>? {
        switch self {
        case .all: return nil
        case .short: return 1...5
        case .medium: return 6...9
        case .long: return 10...52
        }
    }
}

// MARK: - Equipment Filter

enum EquipmentFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case bodyweight = "Bodyweight"
    case dumbbells = "Dumbbells"
    case barbell = "Barbell"
    case bands = "Bands"
    case fullGym = "Full Gym"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .bodyweight: return "figure.walk"
        case .dumbbells: return "dumbbell.fill"
        case .barbell: return "figure.strengthtraining.traditional"
        case .bands: return "circle.dotted"
        case .fullGym: return "building.2.fill"
        }
    }
}

// MARK: - Goal Filter

enum GoalFilter: String, CaseIterable, Identifiable {
    case all = "All Goals"
    case strength = "Strength"
    case muscleBuilding = "Muscle Building"
    case fatLoss = "Fat Loss"
    case mobility = "Mobility"
    case performance = "Performance"
    case rehab = "Rehab"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "target"
        case .strength: return "bolt.fill"
        case .muscleBuilding: return "dumbbell.fill"
        case .fatLoss: return "flame.fill"
        case .mobility: return "figure.flexibility"
        case .performance: return "figure.run"
        case .rehab: return "cross.case.fill"
        }
    }

    /// Keywords to match against program category, tags, and description
    var matchKeywords: [String] {
        switch self {
        case .all: return []
        case .strength: return ["strength", "power", "strong"]
        case .muscleBuilding: return ["hypertrophy", "muscle", "building", "mass", "size"]
        case .fatLoss: return ["fat loss", "weight loss", "lean", "cut", "conditioning", "cardio"]
        case .mobility: return ["mobility", "flexibility", "stretch", "yoga", "recovery"]
        case .performance: return ["performance", "athletic", "sport", "speed", "agility", "baseball"]
        case .rehab: return ["rehab", "rehabilitation", "recovery", "injury", "prehab"]
        }
    }
}

// MARK: - ViewModel

@MainActor
class ProgramLibraryBrowserViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var programs: [ProgramLibrary] = []
    @Published var featuredPrograms: [ProgramLibrary] = []
    @Published var isLoading = false
    @Published var isLoadingFeatured = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isDuplicating = false
    @Published var duplicatedProgramId: UUID?

    // MARK: - Filter State

    @Published var searchText = "" {
        didSet { updateFilteredPrograms() }
    }
    @Published var selectedCategory: ProgramCategory? {
        didSet { updateFilteredPrograms() }
    }
    @Published var selectedDifficulty: DifficultyLevel? {
        didSet { updateFilteredPrograms() }
    }

    // ACP-1031: New filters
    @Published var selectedDuration: DurationFilter = .all {
        didSet { updateFilteredPrograms() }
    }
    @Published var selectedEquipment: EquipmentFilter = .all {
        didSet { updateFilteredPrograms() }
    }
    @Published var selectedGoal: GoalFilter = .all {
        didSet { updateFilteredPrograms() }
    }
    @Published var sortOption: ProgramSortOption = .popular {
        didSet { updateFilteredPrograms() }
    }

    // ACP-1031: First-week preview state
    @Published var previewWeek: [ProgramScheduleDay]?
    @Published var isLoadingPreview = false
    @Published var previewProgramId: UUID?

    // MARK: - Cached Filtered Arrays (Performance Optimization)

    @Published private(set) var cachedFilteredPrograms: [ProgramLibrary] = []
    @Published private(set) var cachedFilteredFeaturedPrograms: [ProgramLibrary] = []

    // MARK: - Program Visibility

    /// Categories that are hidden from the program browser
    private static let hiddenCategories: Set<String> = [
        "baseball", "recovery"
    ]

    /// Tags that indicate sport-specific or therapist-required programs
    private static let hiddenTags: Set<String> = [
        "baseball", "golf", "pickleball", "tactical", "running", "rehab",
        "catcher", "pitcher", "infielder", "outfielder", "position_specific",
        "arm-care", "arm_care", "throwing_prep", "velocity"
    ]

    /// Filter programs to only show general-purpose fitness programs
    private func filterToAvailablePrograms(_ allPrograms: [ProgramLibrary]) -> [ProgramLibrary] {
        let filtered = allPrograms.filter { program in
            let category = program.category.lowercased()
            let tags = Set(program.tagsList.map { $0.lowercased() })
            let title = program.title.lowercased()

            // Hide by category
            if Self.hiddenCategories.contains(category) { return false }

            // Hide by tag
            if !tags.isDisjoint(with: Self.hiddenTags) { return false }

            // Hide by title keywords (catch-all for programs that slipped through)
            let hiddenTitleWords = ["baseball", "pitcher", "catcher", "outfield", "infield",
                                    "arm care", "throw", "ucl", "golf", "pickleball",
                                    "tactical", "combat", "rehab", "return-to-throw"]
            if hiddenTitleWords.contains(where: { title.contains($0) }) { return false }

            return true
        }
        DebugLogger.shared.log("ProgramLibrary: Showing \(filtered.count) of \(allPrograms.count) programs (hiding sport-specific/rehab)", level: .diagnostic)
        return filtered
    }

    // MARK: - Dependencies

    private let service: ProgramLibraryService

    // MARK: - Initialization

    init(service: ProgramLibraryService = ProgramLibraryService()) {
        self.service = service
    }

    // MARK: - Update Cached Filtered Programs

    private func updateFilteredPrograms() {
        cachedFilteredPrograms = computeFilteredPrograms()
        cachedFilteredFeaturedPrograms = computeFilteredFeaturedPrograms()
    }

    // MARK: - Filtered Programs Computation

    private func computeFilteredPrograms() -> [ProgramLibrary] {
        programs
            .filter { program in
                let matchesSearch = searchText.isEmpty ||
                    program.title.localizedCaseInsensitiveContains(searchText) ||
                    program.description?.localizedCaseInsensitiveContains(searchText) == true ||
                    program.tagsList.contains { $0.localizedCaseInsensitiveContains(searchText) }

                let matchesCategory = selectedCategory == nil ||
                    program.category.lowercased() == selectedCategory?.rawValue.lowercased()

                let matchesDifficulty = selectedDifficulty == nil ||
                    program.difficultyLevel.lowercased() == selectedDifficulty?.rawValue.lowercased()

                // ACP-1031: Duration filter
                let matchesDuration: Bool
                if let range = selectedDuration.weekRange {
                    matchesDuration = range.contains(program.durationWeeks)
                } else {
                    matchesDuration = true
                }

                // ACP-1031: Equipment filter
                let matchesEquipment: Bool
                switch selectedEquipment {
                case .all:
                    matchesEquipment = true
                case .bodyweight:
                    matchesEquipment = program.equipment.isEmpty ||
                        program.equipment.contains { $0.localizedCaseInsensitiveContains("bodyweight") || $0.localizedCaseInsensitiveContains("none") }
                case .dumbbells:
                    matchesEquipment = program.equipment.contains { $0.localizedCaseInsensitiveContains("dumbbell") }
                case .barbell:
                    matchesEquipment = program.equipment.contains { $0.localizedCaseInsensitiveContains("barbell") }
                case .bands:
                    matchesEquipment = program.equipment.contains { $0.localizedCaseInsensitiveContains("band") || $0.localizedCaseInsensitiveContains("resistance") }
                case .fullGym:
                    matchesEquipment = program.equipment.count >= 3
                }

                // ACP-1031: Goal filter
                let matchesGoal: Bool
                if selectedGoal == .all {
                    matchesGoal = true
                } else {
                    let keywords = selectedGoal.matchKeywords
                    let searchableText = [
                        program.category,
                        program.description ?? "",
                        program.tagsList.joined(separator: " ")
                    ].joined(separator: " ").lowercased()

                    matchesGoal = keywords.contains { searchableText.contains($0) }
                }

                return matchesSearch && matchesCategory && matchesDifficulty && matchesDuration && matchesEquipment && matchesGoal
            }
            .sorted { lhs, rhs in
                // ACP-1031: Apply selected sort option
                switch sortOption {
                case .popular:
                    // Featured programs first, then alphabetical
                    if lhs.featured != rhs.featured {
                        return lhs.featured
                    }
                    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                case .newest:
                    // Newest first by creation date
                    let lhsDate = lhs.createdAt ?? Date.distantPast
                    let rhsDate = rhs.createdAt ?? Date.distantPast
                    return lhsDate > rhsDate
                case .duration:
                    // Shortest first
                    return lhs.durationWeeks < rhs.durationWeeks
                case .difficulty:
                    // Easiest first
                    let order: [String: Int] = ["beginner": 0, "intermediate": 1, "advanced": 2]
                    let lhsOrder = order[lhs.difficultyLevel.lowercased()] ?? 1
                    let rhsOrder = order[rhs.difficultyLevel.lowercased()] ?? 1
                    return lhsOrder < rhsOrder
                }
            }
    }

    private func computeFilteredFeaturedPrograms() -> [ProgramLibrary] {
        featuredPrograms
            .filter { program in
                let matchesSearch = searchText.isEmpty ||
                    program.title.localizedCaseInsensitiveContains(searchText) ||
                    program.description?.localizedCaseInsensitiveContains(searchText) == true

                let matchesCategory = selectedCategory == nil ||
                    program.category.lowercased() == selectedCategory?.rawValue.lowercased()

                let matchesDifficulty = selectedDifficulty == nil ||
                    program.difficultyLevel.lowercased() == selectedDifficulty?.rawValue.lowercased()

                return matchesSearch && matchesCategory && matchesDifficulty
            }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    // MARK: - Data Fetching

    /// Load all programs from the library
    func loadPrograms() async {
        isLoading = true
        errorMessage = nil

        do {
            let allPrograms = try await service.fetchPrograms()
            programs = filterToAvailablePrograms(allPrograms)
            updateFilteredPrograms()
            isLoading = false
        } catch {
            errorMessage = "Unable to load programs. Pull down to refresh."
            isLoading = false
        }
    }

    /// Load programs filtered by category
    func loadByCategory(_ category: String) async {
        isLoading = true
        errorMessage = nil

        do {
            programs = try await service.fetchProgramsByCategory(category)
            updateFilteredPrograms()
            isLoading = false
        } catch {
            errorMessage = "Unable to load programs. Pull down to refresh."
            isLoading = false
        }
    }

    /// Load featured programs
    func loadFeatured() async {
        isLoadingFeatured = true

        do {
            featuredPrograms = try await service.fetchFeaturedPrograms()
            updateFilteredPrograms()
            isLoadingFeatured = false
        } catch {
            // Silently handle - featured is optional
            DebugLogger.shared.log("Failed to load featured programs: \(error)", level: .warning)
            isLoadingFeatured = false
        }
    }

    /// Search programs by query
    func searchPrograms(query: String) async {
        isLoading = true
        errorMessage = nil

        do {
            programs = try await service.fetchPrograms(search: query)
            updateFilteredPrograms()
            isLoading = false
        } catch {
            errorMessage = "Unable to search programs. Please try again."
            isLoading = false
        }
    }

    /// Load all data (programs + featured)
    /// ACP-937: Fixed memory leak - use [weak self] in TaskGroup closures
    func loadAllData() async {
        await withTaskGroup(of: Void.self) { [weak self] group in
            group.addTask { [weak self] in
                await self?.loadPrograms()
            }
            group.addTask { [weak self] in
                await self?.loadFeatured()
            }
        }
    }

    // MARK: - ACP-1031: First Week Preview

    /// Load the first week's workout schedule for a program preview
    func loadFirstWeekPreview(for program: ProgramLibrary) async {
        guard let programId = program.programId else {
            previewWeek = nil
            previewProgramId = program.id
            isLoadingPreview = false
            return
        }

        isLoadingPreview = true
        previewProgramId = program.id

        do {
            let weeks = try await service.fetchProgramWorkoutSchedule(programLibraryId: program.id)
            if let firstWeek = weeks.first {
                previewWeek = firstWeek.activeDays
            } else {
                previewWeek = nil
            }
        } catch {
            DebugLogger.shared.log("Failed to load first week preview: \(error)", level: .warning)
            previewWeek = nil
        }

        isLoadingPreview = false
    }

    // MARK: - Filter Helpers

    /// Clear all filters
    func clearFilters() {
        searchText = ""
        selectedCategory = nil
        selectedDifficulty = nil
        selectedDuration = .all
        selectedEquipment = .all
        selectedGoal = .all
        sortOption = .popular
    }

    /// Check if any filters are active
    var hasActiveFilters: Bool {
        !searchText.isEmpty || selectedCategory != nil || selectedDifficulty != nil ||
        selectedDuration != .all || selectedEquipment != .all || selectedGoal != .all
    }

    /// Count of active filters (for badge display)
    var activeFilterCount: Int {
        var count = 0
        if !searchText.isEmpty { count += 1 }
        if selectedCategory != nil { count += 1 }
        if selectedDifficulty != nil { count += 1 }
        if selectedDuration != .all { count += 1 }
        if selectedEquipment != .all { count += 1 }
        if selectedGoal != .all { count += 1 }
        return count
    }

    // MARK: - Duplicate Program

    /// Duplicates a program from the library
    /// Creates a new program_library entry with " (Copy)" suffix and copies all phases and workout assignments
    /// - Parameter program: The program to duplicate
    /// - Returns: The ID of the newly created program library entry
    func duplicateProgram(_ program: ProgramLibrary) async throws -> UUID {
        let logger = DebugLogger.shared
        logger.log("Duplicating program: \(program.title)", level: .diagnostic)

        isDuplicating = true
        errorMessage = nil
        successMessage = nil

        defer { isDuplicating = false }

        let supabase = PTSupabaseClient.shared
        let programBuilderService = ProgramBuilderService()

        // Step 1: If the template has a linked program_id, fetch and duplicate the full structure
        var newProgramId: UUID?

        if let sourceProgramId = program.programId {
            do {
                // Fetch the full program structure
                let sourceProgram = try await programBuilderService.getProgram(id: sourceProgramId)

                // Create a new program with copied data
                newProgramId = try await programBuilderService.createProgram(
                    name: "\(program.title) (Copy)",
                    description: program.description ?? "",
                    category: program.category,
                    durationWeeks: program.durationWeeks
                )

                guard let programId = newProgramId else {
                    throw ProgramServiceError.createFailed(NSError(domain: "ProgramLibraryBrowserViewModel", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to create program"]))
                }

                // Copy phases and assignments
                for phase in sourceProgram.phases {
                    let newPhaseId = try await programBuilderService.addPhase(
                        programId: programId,
                        name: phase.name,
                        sequence: phase.sequence,
                        durationWeeks: phase.durationWeeks ?? 4,
                        goals: phase.goals
                    )

                    // Copy workout assignments for this phase
                    for assignment in phase.assignments {
                        _ = try await programBuilderService.assignWorkout(
                            programId: programId,
                            phaseId: newPhaseId,
                            templateId: assignment.templateId,
                            weekNumber: assignment.weekNumber,
                            dayOfWeek: assignment.dayOfWeek
                        )
                    }
                }

                logger.log("Duplicated program structure with \(sourceProgram.phases.count) phases", level: .success)

            } catch {
                logger.log("Failed to duplicate program structure: \(error.localizedDescription)", level: .warning)
                // Continue to create library entry even if structure copy fails
            }
        }

        // Step 2: Create the program_library entry
        struct ProgramLibraryInsert: Encodable {
            let title: String
            let description: String?
            let category: String
            let durationWeeks: Int
            let difficultyLevel: String
            let equipmentRequired: [String]
            let programId: UUID?
            let isFeatured: Bool
            let tags: [String]
            let author: String?

            enum CodingKeys: String, CodingKey {
                case title
                case description
                case category
                case durationWeeks = "duration_weeks"
                case difficultyLevel = "difficulty_level"
                case equipmentRequired = "equipment_required"
                case programId = "program_id"
                case isFeatured = "is_featured"
                case tags
                case author
            }
        }

        struct LibraryResponse: Codable {
            let id: UUID
        }

        let insert = ProgramLibraryInsert(
            title: "\(program.title) (Copy)",
            description: program.description,
            category: program.category,
            durationWeeks: program.durationWeeks,
            difficultyLevel: program.difficultyLevel,
            equipmentRequired: program.equipment,
            programId: newProgramId,
            isFeatured: false, // Duplicated programs are not featured by default
            tags: program.tagsList,
            author: program.author
        )

        do {
            let response = try await supabase.client
                .from("program_library")
                .insert(insert)
                .select("id")
                .single()
                .execute()

            let decoder = JSONDecoder()
            let libraryEntry = try decoder.decode(LibraryResponse.self, from: response.data)

            logger.log("Created program library entry: \(libraryEntry.id)", level: .success)

            duplicatedProgramId = libraryEntry.id
            successMessage = "Program '\(program.title)' duplicated successfully!"

            // Refresh the programs list to show the new entry
            await loadPrograms()

            return libraryEntry.id

        } catch {
            logger.log("Failed to create program library entry: \(error.localizedDescription)", level: .error)
            errorMessage = "Failed to duplicate program. Please try again."
            throw error
        }
    }
}
