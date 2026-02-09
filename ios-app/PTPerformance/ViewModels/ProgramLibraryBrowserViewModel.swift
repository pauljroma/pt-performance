//
//  ProgramLibraryBrowserViewModel.swift
//  PTPerformance
//
//  ViewModel for browsing and discovering programs in the program library
//

import SwiftUI

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

    // MARK: - Cached Filtered Arrays (Performance Optimization)

    @Published private(set) var cachedFilteredPrograms: [ProgramLibrary] = []
    @Published private(set) var cachedFilteredFeaturedPrograms: [ProgramLibrary] = []

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

                return matchesSearch && matchesCategory && matchesDifficulty
            }
            .sorted { lhs, rhs in
                // Featured programs first, then alphabetical
                if lhs.featured != rhs.featured {
                    return lhs.featured
                }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
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
            programs = try await service.fetchPrograms()
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

    // MARK: - Filter Helpers

    /// Clear all filters
    func clearFilters() {
        searchText = ""
        selectedCategory = nil
        selectedDifficulty = nil
    }

    /// Check if any filters are active
    var hasActiveFilters: Bool {
        !searchText.isEmpty || selectedCategory != nil || selectedDifficulty != nil
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
