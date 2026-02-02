//
//  ProgramLibraryBrowserViewModel.swift
//  PTPerformance
//
//  ViewModel for browsing and discovering programs in the program library
//

import Foundation
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
                    program.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }

                let matchesCategory = selectedCategory == nil ||
                    program.category.lowercased() == selectedCategory?.rawValue.lowercased()

                let matchesDifficulty = selectedDifficulty == nil ||
                    program.difficultyLevel.lowercased() == selectedDifficulty?.rawValue.lowercased()

                return matchesSearch && matchesCategory && matchesDifficulty
            }
            .sorted { lhs, rhs in
                // Featured programs first, then alphabetical
                if lhs.isFeatured != rhs.isFeatured {
                    return lhs.isFeatured
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
    func loadAllData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadPrograms() }
            group.addTask { await self.loadFeatured() }
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
}
