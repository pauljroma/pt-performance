//
//  WorkoutPickerViewModel.swift
//  PTPerformance
//
//  BUILD 327: Quick Pick Workout Finder
//  Questionnaire-based workout recommendation system
//

import Foundation
import SwiftUI

@MainActor
class WorkoutPickerViewModel: ObservableObject {

    // MARK: - Questionnaire State

    @Published var selectedDuration: DurationOption = .thirty
    @Published var includeCardio: Bool = false
    @Published var includePush: Bool = true
    @Published var includePull: Bool = true
    @Published var includeLegs: Bool = false
    @Published var includeCore: Bool = false
    @Published var includeMobility: Bool = false

    // MARK: - Results State

    @Published var recommendations: [SystemWorkoutTemplate] = []
    @Published var isLoading: Bool = false
    @Published var hasSearched: Bool = false
    @Published var errorMessage: String?

    // MARK: - All Templates Cache

    private var allTemplates: [SystemWorkoutTemplate] = []
    private let workoutService = ManualWorkoutService()
    private let logger = DebugLogger.shared

    // MARK: - Duration Options

    enum DurationOption: Int, CaseIterable, Identifiable {
        case fifteen = 15
        case thirty = 30
        case fortyFive = 45
        case sixty = 60
        case seventyFive = 75
        case ninety = 90

        var id: Int { rawValue }

        var displayText: String {
            "\(rawValue) min"
        }

        /// Range of acceptable durations (±10 minutes for flexibility)
        var range: ClosedRange<Int> {
            let lower = max(5, rawValue - 10)
            let upper = rawValue + 10
            return lower...upper
        }
    }

    // MARK: - Category Mapping

    /// Maps user selections to template categories and tags
    private struct CategoryFilter {
        let categories: [String]
        let tags: [String]
    }

    private var activeFilters: [CategoryFilter] {
        var filters: [CategoryFilter] = []

        if includeCardio {
            filters.append(CategoryFilter(
                categories: ["cardio", "hiit", "conditioning"],
                tags: ["cardio", "hiit", "conditioning", "endurance", "metabolic"]
            ))
        }

        if includePush {
            filters.append(CategoryFilter(
                categories: ["push", "upper", "chest"],
                tags: ["push", "chest", "shoulders", "triceps", "pressing", "upper_body"]
            ))
        }

        if includePull {
            filters.append(CategoryFilter(
                categories: ["pull", "upper", "back"],
                tags: ["pull", "back", "biceps", "rowing", "upper_body"]
            ))
        }

        if includeLegs {
            filters.append(CategoryFilter(
                categories: ["lower", "legs", "glutes"],
                tags: ["legs", "lower_body", "quads", "hamstrings", "glutes", "squat"]
            ))
        }

        if includeCore {
            filters.append(CategoryFilter(
                categories: ["core", "abs", "functional"],
                tags: ["core", "abs", "stability", "functional"]
            ))
        }

        if includeMobility {
            filters.append(CategoryFilter(
                categories: ["mobility", "flexibility", "recovery"],
                tags: ["mobility", "flexibility", "recovery", "stretching", "yoga"]
            ))
        }

        return filters
    }

    // MARK: - Load Templates

    func loadTemplatesIfNeeded() async {
        guard allTemplates.isEmpty else { return }

        logger.log("QuickPick: Loading all templates...", level: .diagnostic)

        do {
            allTemplates = try await workoutService.fetchSystemTemplates()
            logger.log("QuickPick: Loaded \(allTemplates.count) templates", level: .success)
        } catch {
            logger.log("QuickPick: Failed to load templates: \(error.localizedDescription)", level: .error)
            errorMessage = "Failed to load workouts"
        }
    }

    // MARK: - Find Workouts

    func findWorkouts() async {
        isLoading = true
        hasSearched = true
        errorMessage = nil
        recommendations = []

        // Ensure templates are loaded
        await loadTemplatesIfNeeded()

        guard !allTemplates.isEmpty else {
            errorMessage = "No workouts available"
            isLoading = false
            return
        }

        logger.log("QuickPick: Searching with duration=\(selectedDuration.rawValue), filters=\(activeFilters.count)", level: .diagnostic)

        // Filter by duration first
        let durationRange = selectedDuration.range
        var candidates = allTemplates.filter { template in
            guard let duration = template.durationMinutes else { return false }
            return durationRange.contains(duration)
        }

        logger.log("QuickPick: \(candidates.count) templates in duration range \(durationRange)", level: .diagnostic)

        // If no category filters selected, use all duration-matched templates
        if activeFilters.isEmpty {
            recommendations = pickRandom(from: candidates, count: 3)
            isLoading = false
            return
        }

        // Filter by categories/tags
        candidates = candidates.filter { template in
            matchesAnyFilter(template)
        }

        logger.log("QuickPick: \(candidates.count) templates match category filters", level: .diagnostic)

        // If too few results, relax duration constraint
        if candidates.count < 2 {
            logger.log("QuickPick: Relaxing duration constraint...", level: .diagnostic)
            candidates = allTemplates.filter { matchesAnyFilter($0) }
        }

        // Pick 2-3 random recommendations
        recommendations = pickRandom(from: candidates, count: 3)

        logger.log("QuickPick: Returning \(recommendations.count) recommendations", level: .success)
        isLoading = false
    }

    // MARK: - Filtering Logic

    private func matchesAnyFilter(_ template: SystemWorkoutTemplate) -> Bool {
        let templateCategory = template.category?.lowercased() ?? ""
        let templateTags = Set((template.tags ?? []).map { $0.lowercased() })

        for filter in activeFilters {
            // Check if category matches
            if filter.categories.contains(where: { templateCategory.contains($0) }) {
                return true
            }

            // Check if any tag matches
            if !filter.tags.filter({ templateTags.contains($0) }).isEmpty {
                return true
            }
        }

        return false
    }

    private func pickRandom(from templates: [SystemWorkoutTemplate], count: Int) -> [SystemWorkoutTemplate] {
        guard !templates.isEmpty else { return [] }

        // Shuffle and take up to count
        let shuffled = templates.shuffled()
        return Array(shuffled.prefix(min(count, shuffled.count)))
    }

    // MARK: - Reset

    func reset() {
        selectedDuration = .thirty
        includeCardio = false
        includePush = true
        includePull = true
        includeLegs = false
        includeCore = false
        includeMobility = false
        recommendations = []
        hasSearched = false
        errorMessage = nil
    }

    // MARK: - Quick Presets

    func applyUpperBodyPreset() {
        includePush = true
        includePull = true
        includeLegs = false
        includeCore = false
        includeCardio = false
        includeMobility = false
    }

    func applyLowerBodyPreset() {
        includePush = false
        includePull = false
        includeLegs = true
        includeCore = true
        includeCardio = false
        includeMobility = false
    }

    func applyFullBodyPreset() {
        includePush = true
        includePull = true
        includeLegs = true
        includeCore = true
        includeCardio = false
        includeMobility = false
    }

    func applyCardioPreset() {
        includePush = false
        includePull = false
        includeLegs = false
        includeCore = false
        includeCardio = true
        includeMobility = false
    }
}
