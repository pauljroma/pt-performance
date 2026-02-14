//
//  ProgressiveOverloadSuggestionsList.swift
//  PTPerformance
//
//  Scrollable list view for displaying multiple AI-powered
//  progressive overload suggestions across exercises.
//

import SwiftUI

/// Model representing an exercise with its progression suggestion
struct ExerciseSuggestionItem: Identifiable, Equatable {
    let id: UUID
    let exerciseName: String
    let exerciseTemplateId: UUID
    let currentWeight: Double
    let suggestion: ProgressionSuggestion

    init(
        id: UUID = UUID(),
        exerciseName: String,
        exerciseTemplateId: UUID,
        currentWeight: Double,
        suggestion: ProgressionSuggestion
    ) {
        self.id = id
        self.exerciseName = exerciseName
        self.exerciseTemplateId = exerciseTemplateId
        self.currentWeight = currentWeight
        self.suggestion = suggestion
    }
}

/// Scrollable list view displaying multiple progressive overload suggestions
/// Note: This view should be wrapped with .visibleIf(.progressiveOverload) when used
/// as it's a Strength mode feature
struct ProgressiveOverloadSuggestionsList: View {

    // MARK: - Properties

    let suggestions: [ExerciseSuggestionItem]
    let onApplySuggestion: (ExerciseSuggestionItem) -> Void
    let onDismissSuggestion: ((ExerciseSuggestionItem) -> Void)?
    let onRefresh: (() async -> Void)?

    @State private var selectedItem: ExerciseSuggestionItem?
    @State private var showDetailSheet = false

    // MARK: - Initialization

    init(
        suggestions: [ExerciseSuggestionItem],
        onApplySuggestion: @escaping (ExerciseSuggestionItem) -> Void,
        onDismissSuggestion: ((ExerciseSuggestionItem) -> Void)? = nil,
        onRefresh: (() async -> Void)? = nil
    ) {
        self.suggestions = suggestions
        self.onApplySuggestion = onApplySuggestion
        self.onDismissSuggestion = onDismissSuggestion
        self.onRefresh = onRefresh
    }

    // MARK: - Body

    var body: some View {
        Group {
            if suggestions.isEmpty {
                emptyState
            } else {
                suggestionsList
            }
        }
        .sheet(item: $selectedItem) { item in
            suggestionDetailSheet(for: item)
        }
    }

    // MARK: - Suggestions List

    private var suggestionsList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.sm) {
                // Summary header
                summaryHeader

                // Filter by progression type
                progressionTypeFilter

                // Suggestion cards
                ForEach(filteredSuggestions) { item in
                    ProgressiveOverloadCardCompact(
                        exerciseName: item.exerciseName,
                        currentWeight: item.currentWeight,
                        suggestion: item.suggestion,
                        onTap: {
                            HapticFeedback.light()
                            selectedItem = item
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .move(edge: .leading))
                    ))
                }
            }
            .padding(Spacing.md)
            .animation(.easeInOut(duration: AnimationDuration.standard), value: filteredSuggestions.count)
        }
        .refreshable {
            if let refresh = onRefresh {
                await refresh()
            }
        }
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.modusCyan)

                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Progression Suggestions")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("\(suggestions.count) exercise\(suggestions.count == 1 ? "" : "s") analyzed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Quick stats
            HStack(spacing: Spacing.md) {
                statBadge(
                    count: suggestions.filter { $0.suggestion.progressionType == .increase }.count,
                    label: "Increase",
                    color: .green
                )

                statBadge(
                    count: suggestions.filter { $0.suggestion.progressionType == .hold }.count,
                    label: "Hold",
                    color: .blue
                )

                statBadge(
                    count: suggestions.filter { $0.suggestion.progressionType == .decrease || $0.suggestion.progressionType == .deload }.count,
                    label: "Reduce",
                    color: .orange
                )
            }
            .padding(.top, Spacing.xxs)
        }
        .padding(Spacing.sm)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.md)
    }

    private func statBadge(count: Int, label: String, color: Color) -> some View {
        HStack(spacing: Spacing.xxs) {
            Text("\(count)")
                .font(.headline)
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Progression Type Filter

    @State private var selectedFilter: ProgressionType?

    private var progressionTypeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                filterChip(type: nil, label: "All")
                filterChip(type: .increase, label: "Increase")
                filterChip(type: .hold, label: "Hold")
                filterChip(type: .decrease, label: "Decrease")
                filterChip(type: .deload, label: "Deload")
            }
        }
    }

    private func filterChip(type: ProgressionType?, label: String) -> some View {
        let isSelected = selectedFilter == type
        let chipColor: Color = type?.color ?? .gray

        return Button(action: {
            HapticFeedback.light()
            withAnimation(.easeInOut(duration: AnimationDuration.quick)) {
                selectedFilter = isSelected ? nil : type
            }
        }) {
            HStack(spacing: Spacing.xxs) {
                if let progressionType = type {
                    Image(systemName: progressionType.icon)
                        .font(.system(size: 12))
                }

                Text(label)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .white : chipColor)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(isSelected ? chipColor : chipColor.opacity(0.15))
            .cornerRadius(CornerRadius.sm + 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Filter by \(label)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var filteredSuggestions: [ExerciseSuggestionItem] {
        guard let filter = selectedFilter else {
            return suggestions
        }
        return suggestions.filter { $0.suggestion.progressionType == filter }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Spacer()

            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            VStack(spacing: Spacing.xs) {
                Text("No Suggestions Yet")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Complete a few workouts to receive AI-powered progression recommendations for your exercises.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Detail Sheet

    private func suggestionDetailSheet(for item: ExerciseSuggestionItem) -> some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    ProgressiveOverloadCard(
                        exerciseName: item.exerciseName,
                        currentWeight: item.currentWeight,
                        suggestion: item.suggestion,
                        onApply: {
                            onApplySuggestion(item)
                            selectedItem = nil
                        },
                        onDismiss: onDismissSuggestion != nil ? {
                            onDismissSuggestion?(item)
                            selectedItem = nil
                        } : nil
                    )
                }
                .padding(Spacing.md)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Suggestion Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        selectedItem = nil
                    }
                }
            }
        }
    }
}

// MARK: - Loading State View

/// Loading state for suggestions list
struct ProgressiveOverloadSuggestionsListLoading: View {

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.sm) {
                // Header skeleton
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color(.secondarySystemBackground))
                    .frame(height: 100)
                    .shimmer(isAnimating: true)

                // Card skeletons
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(Color(.secondarySystemBackground))
                        .frame(height: 72)
                        .shimmer(isAnimating: true)
                }
            }
            .padding(Spacing.md)
        }
    }
}

// MARK: - ViewModel

/// ViewModel for managing progressive overload suggestions list
@MainActor
class ProgressiveOverloadSuggestionsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var suggestions: [ExerciseSuggestionItem] = []
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Private Properties

    private let service: ProgressiveOverloadAIService

    // MARK: - Initialization

    init(service: ProgressiveOverloadAIService = .shared) {
        self.service = service
    }

    // MARK: - Public Methods

    /// Load suggestions for a list of exercises
    /// - Parameter exercises: Array of tuples containing exercise info (name, templateId, currentWeight)
    func loadSuggestions(for exercises: [(name: String, templateId: UUID, currentWeight: Double)]) async {
        isLoading = true
        defer { isLoading = false }
        error = nil
        suggestions = []

        // Use TaskGroup to fetch all exercises in parallel instead of sequentially.
        // The nonisolated static helper ensures tasks run off the main actor.
        let loadedSuggestions = await withTaskGroup(of: ExerciseSuggestionItem?.self, returning: [ExerciseSuggestionItem].self) { group in
            for exercise in exercises {
                group.addTask {
                    await Self.fetchSuggestion(service: self.service, exercise: exercise)
                }
            }

            var results: [ExerciseSuggestionItem] = []
            for await result in group {
                if let item = result {
                    results.append(item)
                }
            }
            return results
        }

        suggestions = loadedSuggestions.sorted { first, second in
            // Sort by progression type priority: increase > hold > decrease > deload
            let priority: [ProgressionType: Int] = [.increase: 0, .hold: 1, .decrease: 2, .deload: 3]
            return (priority[first.suggestion.progressionType] ?? 4) < (priority[second.suggestion.progressionType] ?? 4)
        }
    }

    // MARK: - Private Helpers

    /// Fetch a single exercise's suggestion off the main actor.
    ///
    /// This is `nonisolated static` so that `TaskGroup.addTask` closures
    /// do not inherit `@MainActor` isolation, allowing true parallel execution.
    private nonisolated static func fetchSuggestion(
        service: ProgressiveOverloadAIService,
        exercise: (name: String, templateId: UUID, currentWeight: Double)
    ) async -> ExerciseSuggestionItem? {
        do {
            let history = try await service.getExerciseHistory(
                exerciseTemplateId: exercise.templateId,
                days: 30
            )
            guard !history.isEmpty else { return nil }
            let suggestion = try await service.getProgressionSuggestion(
                exerciseTemplateId: exercise.templateId,
                recentPerformance: history
            )
            return ExerciseSuggestionItem(
                exerciseName: exercise.name,
                exerciseTemplateId: exercise.templateId,
                currentWeight: exercise.currentWeight,
                suggestion: suggestion
            )
        } catch {
            return nil
        }
    }

    /// Apply a suggestion by accepting it in the service
    func applySuggestion(_ item: ExerciseSuggestionItem) async {
        do {
            try await service.acceptSuggestion(suggestionId: item.suggestion.id)
            // Remove from local list
            suggestions.removeAll { $0.id == item.id }
        } catch {
            self.error = "Failed to apply suggestion"
        }
    }

    /// Dismiss a suggestion
    func dismissSuggestion(_ item: ExerciseSuggestionItem) async {
        do {
            try await service.dismissSuggestion(suggestionId: item.suggestion.id)
            // Remove from local list
            suggestions.removeAll { $0.id == item.id }
        } catch {
            self.error = "Failed to dismiss suggestion"
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ProgressiveOverloadSuggestionsList_Previews: PreviewProvider {
    static var sampleSuggestions: [ExerciseSuggestionItem] {
        [
            ExerciseSuggestionItem(
                exerciseName: "Barbell Back Squat",
                exerciseTemplateId: UUID(),
                currentWeight: 185,
                suggestion: ProgressionSuggestion(
                    id: UUID(),
                    nextLoad: 190,
                    nextReps: 8,
                    confidence: 85,
                    reasoning: "Consistent performance across 4 sessions indicates readiness for progression.",
                    progressionType: .increase,
                    analysis: PerformanceAnalysis(
                        trend: .improving,
                        estimated1RM: 225,
                        velocityTrend: "stable",
                        fatigueImpact: "low",
                        recentSessions: 4
                    )
                )
            ),
            ExerciseSuggestionItem(
                exerciseName: "Romanian Deadlift",
                exerciseTemplateId: UUID(),
                currentWeight: 135,
                suggestion: ProgressionSuggestion(
                    id: UUID(),
                    nextLoad: 135,
                    nextReps: 10,
                    confidence: 72,
                    reasoning: "RPE of 8 indicates optimal training stimulus. Maintain current load.",
                    progressionType: .hold,
                    analysis: PerformanceAnalysis(
                        trend: .plateaued,
                        estimated1RM: 175,
                        velocityTrend: "stable",
                        fatigueImpact: "moderate",
                        recentSessions: 3
                    )
                )
            ),
            ExerciseSuggestionItem(
                exerciseName: "Bench Press",
                exerciseTemplateId: UUID(),
                currentWeight: 165,
                suggestion: ProgressionSuggestion(
                    id: UUID(),
                    nextLoad: 155,
                    nextReps: 8,
                    confidence: 78,
                    reasoning: "High RPE and missed reps indicate load is too high.",
                    progressionType: .decrease,
                    analysis: PerformanceAnalysis(
                        trend: .declining,
                        estimated1RM: 185,
                        velocityTrend: "decreasing",
                        fatigueImpact: "high",
                        recentSessions: 3
                    )
                )
            ),
            ExerciseSuggestionItem(
                exerciseName: "Overhead Press",
                exerciseTemplateId: UUID(),
                currentWeight: 95,
                suggestion: ProgressionSuggestion(
                    id: UUID(),
                    nextLoad: 80,
                    nextReps: 6,
                    confidence: 88,
                    reasoning: "Accumulated fatigue detected. Deload recommended for recovery.",
                    progressionType: .deload,
                    analysis: PerformanceAnalysis(
                        trend: .declining,
                        estimated1RM: 115,
                        velocityTrend: "decreasing",
                        fatigueImpact: "high - consider deload",
                        recentSessions: 5
                    )
                )
            )
        ]
    }

    static var previews: some View {
        Group {
            // With suggestions
            NavigationStack {
                ProgressiveOverloadSuggestionsList(
                    suggestions: sampleSuggestions,
                    onApplySuggestion: { _ in },
                    onDismissSuggestion: { _ in },
                    onRefresh: {}
                )
                .navigationTitle("Progression")
            }

            // Empty state
            NavigationStack {
                ProgressiveOverloadSuggestionsList(
                    suggestions: [],
                    onApplySuggestion: { _ in }
                )
                .navigationTitle("Progression")
            }

            // Loading state
            NavigationStack {
                ProgressiveOverloadSuggestionsListLoading()
                    .navigationTitle("Progression")
            }
        }
    }
}
#endif
