//
//  WorkoutPickerViewModel.swift
//  PTPerformance
//
//  Quick Pick Workout Finder with AI Quick Pick Mode
//  Questionnaire-based workout recommendation system with AI-powered suggestions
//

import SwiftUI

@MainActor
class WorkoutPickerViewModel: ObservableObject {

    // MARK: - Mode State

    /// AI mode uses intelligent recommendations; Shuffle mode uses random selection
    @Published var isAIMode: Bool = true

    // MARK: - AI State

    @Published var aiRecommendations: [AIWorkoutRecommendation] = []
    @Published var aiReasoning: String?
    @Published var aiContext: RecommendationContext?
    @Published var isLoadingAI: Bool = false
    @Published var aiError: String?
    @Published var isAICached: Bool = false

    private let aiService = AIWorkoutRecommendationService()

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

    /// Maps user selections to template categories, tags, and content keywords
    private struct CategoryFilter {
        let categories: [String]
        let tags: [String]
        /// Keywords to search for in template name, block names, and exercise names
        let contentKeywords: [String]
        /// WorkoutBlockTypes that match this filter
        let blockTypes: [WorkoutBlockType]
    }

    private var activeFilters: [CategoryFilter] {
        var filters: [CategoryFilter] = []

        if includeCardio {
            filters.append(CategoryFilter(
                categories: ["cardio", "hiit", "conditioning"],
                tags: ["cardio", "hiit", "conditioning", "endurance", "metabolic"],
                contentKeywords: ["cardio", "hiit", "run", "bike", "sprint", "burpee", "jump", "conditioning", "metabolic", "endurance"],
                blockTypes: [.cardio]
            ))
        }

        if includePush {
            filters.append(CategoryFilter(
                categories: ["push", "upper", "chest"],
                tags: ["push", "chest", "shoulders", "triceps", "pressing", "upper_body"],
                contentKeywords: ["push", "press", "bench", "chest", "shoulder", "tricep", "dip", "fly", "overhead"],
                blockTypes: [.push]
            ))
        }

        if includePull {
            filters.append(CategoryFilter(
                categories: ["pull", "upper", "back"],
                tags: ["pull", "back", "biceps", "rowing", "upper_body"],
                contentKeywords: ["pull", "row", "back", "bicep", "lat", "chin", "pulldown", "pullup", "curl"],
                blockTypes: [.pull]
            ))
        }

        if includeLegs {
            filters.append(CategoryFilter(
                categories: ["lower", "legs", "glutes"],
                tags: ["legs", "lower_body", "quads", "hamstrings", "glutes", "squat"],
                contentKeywords: ["leg", "squat", "lunge", "quad", "hamstring", "glute", "calf", "deadlift", "rdl", "hip", "lower body", "hinge"],
                blockTypes: [.lungeSquat, .hinge]
            ))
        }

        if includeCore {
            filters.append(CategoryFilter(
                categories: ["core", "abs", "functional"],
                tags: ["core", "abs", "stability", "functional"],
                contentKeywords: ["core", "abs", "plank", "crunch", "twist", "rotate", "oblique", "stability", "anti-rotation"],
                blockTypes: [.functional]
            ))
        }

        if includeMobility {
            filters.append(CategoryFilter(
                categories: ["mobility", "flexibility", "recovery"],
                tags: ["mobility", "flexibility", "recovery", "stretching", "yoga"],
                contentKeywords: ["mobility", "flexibility", "stretch", "recovery", "yoga", "foam", "cool down", "warm up", "dynamic"],
                blockTypes: [.dynamicStretch, .recovery]
            ))
        }

        return filters
    }

    // MARK: - Load Templates

    /// Track whether initial template load is in progress
    @Published var isLoadingTemplates: Bool = false

    func loadTemplatesIfNeeded() async {
        guard allTemplates.isEmpty else { return }

        isLoadingTemplates = true
        logger.log("QuickPick: Loading all templates...", level: .diagnostic)

        do {
            allTemplates = try await workoutService.fetchSystemTemplates()
            logger.log("QuickPick: Loaded \(allTemplates.count) templates", level: .success)
        } catch {
            logger.log("QuickPick: Failed to load templates: \(error.localizedDescription)", level: .error)
            errorMessage = "We couldn't load workout options. Please check your connection and try again."
        }

        isLoadingTemplates = false
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
            errorMessage = "No workouts match your preferences. Try adjusting your filters or duration."
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

    /// Enhanced filtering to check category, tags, block types, and content keywords
    private func matchesAnyFilter(_ template: SystemWorkoutTemplate) -> Bool {
        let templateCategory = template.category?.lowercased() ?? ""
        let templateTags = Set((template.tags ?? []).map { $0.lowercased() })
        let templateName = template.name.lowercased()

        // Collect all searchable text from the template
        let blockNames = template.blocks.map { $0.name.lowercased() }
        let blockTypes = template.blocks.map { $0.blockType }
        let exerciseNames = template.blocks.flatMap { $0.exercises.map { $0.name.lowercased() } }

        for filter in activeFilters {
            // 1. Check if category matches (substring match)
            if filter.categories.contains(where: { templateCategory.contains($0) }) {
                return true
            }

            // 2. Check if any tag matches (exact match after lowercasing)
            if !filter.tags.filter({ templateTags.contains($0) }).isEmpty {
                return true
            }

            // 3. Check if any block type matches
            if !filter.blockTypes.isEmpty {
                for blockType in blockTypes {
                    if filter.blockTypes.contains(blockType) {
                        return true
                    }
                }
            }

            // 4. Check if template name contains any content keyword
            if filter.contentKeywords.contains(where: { templateName.contains($0) }) {
                return true
            }

            // 5. Check if any block name contains content keywords
            for blockName in blockNames {
                if filter.contentKeywords.contains(where: { blockName.contains($0) }) {
                    return true
                }
            }

            // 6. Check if exercise names collectively suggest this workout matches
            // Require at least 30% of exercises to match for content-based matching
            let matchingExerciseCount = exerciseNames.filter { exerciseName in
                filter.contentKeywords.contains(where: { exerciseName.contains($0) })
            }.count

            if !exerciseNames.isEmpty && matchingExerciseCount >= max(1, exerciseNames.count / 3) {
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

    // MARK: - AI Mode

    /// Toggle between AI and Shuffle modes
    func toggleMode() {
        isAIMode.toggle()
        // Clear results when switching modes
        if isAIMode {
            recommendations = []
        } else {
            aiRecommendations = []
            aiReasoning = nil
            aiContext = nil
        }
        hasSearched = false
    }

    /// Get AI-powered workout recommendations
    func fetchAIRecommendations(patientId: UUID) async {
        isLoadingAI = true
        hasSearched = true
        aiError = nil
        aiRecommendations = []
        aiReasoning = nil
        aiContext = nil

        logger.log("QuickPick AI: Fetching recommendations for patient \(patientId)", level: .diagnostic)

        // Build category preferences from toggles
        var categoryPreferences: [String] = []
        if includePush { categoryPreferences.append("push") }
        if includePull { categoryPreferences.append("pull") }
        if includeLegs { categoryPreferences.append("legs") }
        if includeCore { categoryPreferences.append("core") }
        if includeCardio { categoryPreferences.append("cardio") }
        if includeMobility { categoryPreferences.append("mobility") }

        // Determine time of day
        let hour = Calendar.current.component(.hour, from: Date())
        let timeOfDay: String
        if hour < 12 {
            timeOfDay = "morning"
        } else if hour < 17 {
            timeOfDay = "afternoon"
        } else {
            timeOfDay = "evening"
        }

        do {
            let results = try await aiService.getRecommendations(
                patientId: patientId,
                categoryPreferences: categoryPreferences.isEmpty ? nil : categoryPreferences,
                durationPreference: selectedDuration.rawValue,
                timeOfDay: timeOfDay
            )

            aiRecommendations = results
            aiReasoning = aiService.reasoning
            aiContext = aiService.contextSummary
            isAICached = aiService.isCached

            logger.log("QuickPick AI: Got \(results.count) recommendations", level: .success)
            if let reasoning = aiReasoning {
                logger.log("QuickPick AI: Reasoning: \(reasoning)", level: .diagnostic)
            }

        } catch {
            logger.log("QuickPick AI: Error: \(error.localizedDescription)", level: .error)
            aiError = aiService.error ?? "We couldn't get AI recommendations. Try shuffling instead."
        }

        isLoadingAI = false
    }

    /// Mark an AI recommendation as selected (for analytics)
    func markAIRecommendationSelected(templateId: UUID) async {
        await aiService.markAsSelected(templateId: templateId)
    }

    /// Get template from AI recommendation for workout start
    func getTemplateForAIRecommendation(_ recommendation: AIWorkoutRecommendation) async -> SystemWorkoutTemplate? {
        // Ensure templates are loaded
        await loadTemplatesIfNeeded()

        // Find the template by ID
        return allTemplates.first { $0.id == recommendation.templateId }
    }

    // MARK: - Reset (Updated for AI)

    func resetAll() {
        reset()
        aiRecommendations = []
        aiReasoning = nil
        aiContext = nil
        aiError = nil
        isAICached = false
        aiService.clearRecommendations()
    }
}
