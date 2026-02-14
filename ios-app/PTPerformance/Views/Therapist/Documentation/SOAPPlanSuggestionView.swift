// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  SOAPPlanSuggestionView.swift
//  PTPerformance
//
//  AI-powered plan suggestions component for SOAP notes
//

import SwiftUI

/// View that displays AI-generated plan suggestions for SOAP notes
///
/// Takes the current Subjective, Objective, and Assessment text as input,
/// calls an AI service to generate plan suggestions, and displays them
/// with one-tap insert functionality.
///
/// ## Usage
/// ```swift
/// SOAPPlanSuggestionView(
///     subjective: $viewModel.subjective,
///     objective: $viewModel.objective,
///     assessment: $viewModel.assessment,
///     plan: $viewModel.plan
/// )
/// ```
struct SOAPPlanSuggestionView: View {
    // MARK: - Properties

    /// The subjective section content
    let subjective: String

    /// The objective section content
    let objective: String

    /// The assessment section content
    let assessment: String

    /// Binding to the plan text for inserting suggestions
    @Binding var plan: String

    /// Optional patient ID for additional context
    var patientId: String?

    /// Callback when a suggestion is inserted
    var onSuggestionInserted: ((PlanSuggestion) -> Void)?

    // MARK: - State

    @StateObject private var service = SOAPPlanSuggestionService()
    @State private var selectedCategory: PlanSuggestionCategory?
    @State private var showRationale: String?
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                mainContent

                if service.isLoading {
                    loadingOverlay
                }
            }
            .navigationTitle("AI Plan Suggestions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel and close suggestions")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if !service.suggestions.isEmpty {
                        Button {
                            refreshSuggestions()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .disabled(service.isLoading)
                        .accessibilityLabel("Refresh suggestions")
                        .accessibilityHint("Generates new AI suggestions based on current note content")
                    }
                }
            }
            .task {
                await fetchSuggestions()
            }
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        if let error = service.error, service.suggestions.isEmpty {
            errorView(error)
        } else if service.suggestions.isEmpty && !service.isLoading {
            emptyStateView
        } else {
            suggestionsList
        }
    }

    // MARK: - Suggestions List

    private var suggestionsList: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Context summary
                contextSummary

                // Category filter
                categoryFilter

                // Suggestions
                ForEach(filteredSuggestions) { suggestion in
                    SuggestionCard(
                        suggestion: suggestion,
                        showRationale: showRationale == suggestion.id,
                        onToggleRationale: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if showRationale == suggestion.id {
                                    showRationale = nil
                                } else {
                                    showRationale = suggestion.id
                                }
                            }
                        },
                        onInsert: {
                            insertSuggestion(suggestion)
                        }
                    )
                }

                // Disclaimer
                disclaimerView
            }
            .padding()
        }
    }

    // MARK: - Context Summary

    private var contextSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "doc.text.magnifyingglass")
                    .foregroundColor(.modusCyan)
                Text("Based on your note content")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            HStack(spacing: 12) {
                if !subjective.isEmpty {
                    ContextBadge(letter: "S", color: .modusCyan, hasContent: true)
                }
                if !objective.isEmpty {
                    ContextBadge(letter: "O", color: .green, hasContent: true)
                }
                if !assessment.isEmpty {
                    ContextBadge(letter: "A", color: .purple, hasContent: true)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Suggestions based on \(contextDescription)")
    }

    private var contextDescription: String {
        var sections: [String] = []
        if !subjective.isEmpty { sections.append("Subjective") }
        if !objective.isEmpty { sections.append("Objective") }
        if !assessment.isEmpty { sections.append("Assessment") }
        return sections.joined(separator: ", ") + " sections"
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                PlanCategoryChip(
                    title: "All",
                    isSelected: selectedCategory == nil,
                    onTap: {
                        HapticService.selection()
                        selectedCategory = nil
                    }
                )

                ForEach(availableCategories, id: \.self) { category in
                    PlanCategoryChip(
                        title: category.displayName,
                        icon: category.icon,
                        isSelected: selectedCategory == category,
                        onTap: {
                            HapticService.selection()
                            selectedCategory = category
                        }
                    )
                }
            }
            .padding(.horizontal, Spacing.xxs)
        }
        .accessibilityLabel("Filter suggestions by category")
    }

    private var availableCategories: [PlanSuggestionCategory] {
        let categories = Set(service.suggestions.map { $0.category })
        return PlanSuggestionCategory.allCases.filter { categories.contains($0) }
    }

    private var filteredSuggestions: [PlanSuggestion] {
        if let category = selectedCategory {
            return service.suggestions.filter { $0.category == category }
        }
        return service.suggestions.sorted { $0.priority.sortOrder < $1.priority.sortOrder }
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color(.label).opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)

                Text("Generating suggestions...")
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Text("Analyzing your note content")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(Spacing.lg)
            .background(.ultraThinMaterial)
            .cornerRadius(CornerRadius.lg)
        }
        .accessibilityLabel("Loading AI suggestions")
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Suggestions Available")
                .font(.headline)

            Text("Add more content to the Subjective, Objective, or Assessment sections for better suggestions.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            Button {
                dismiss()
            } label: {
                Text("Return to Note")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .accessibilityElement(children: .combine)
    }

    // MARK: - Error View

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Unable to Generate Suggestions")
                .font(.headline)

            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            Button {
                refreshSuggestions()
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .accessibilityElement(children: .combine)
    }

    // MARK: - Disclaimer

    private var disclaimerView: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundColor(.secondary)
                .font(.caption)

            Text("AI suggestions are provided as clinical decision support. Always verify recommendations against your professional judgment and patient-specific factors.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
        .accessibilityLabel("Disclaimer: AI suggestions are clinical decision support tools. Always verify against professional judgment.")
    }

    // MARK: - Actions

    private func fetchSuggestions() async {
        do {
            _ = try await service.getSuggestions(
                subjective: subjective,
                objective: objective,
                assessment: assessment,
                patientId: patientId
            )
        } catch {
            // Error is already set in service
            #if DEBUG
            DebugLogger.shared.error("SOAPPlanSuggestionView", "Failed to fetch suggestions: \(error)")
            #endif
        }
    }

    private func refreshSuggestions() {
        HapticService.light()
        Task {
            await fetchSuggestions()
        }
    }

    private func insertSuggestion(_ suggestion: PlanSuggestion) {
        HapticService.success()

        // Add suggestion to plan with proper formatting
        if plan.isEmpty {
            plan = suggestion.content
        } else {
            // Add newline separator if needed
            if !plan.hasSuffix("\n") {
                plan += "\n"
            }
            plan += "\n" + suggestion.content
        }

        onSuggestionInserted?(suggestion)

        // Provide feedback and dismiss
        dismiss()
    }
}

// MARK: - Suggestion Card

private struct SuggestionCard: View {
    let suggestion: PlanSuggestion
    let showRationale: Bool
    let onToggleRationale: () -> Void
    let onInsert: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Category badge
                HStack(spacing: 4) {
                    Image(systemName: suggestion.category.icon)
                        .font(.caption)
                    Text(suggestion.category.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(categoryColor)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, Spacing.xxs)
                .background(categoryColor.opacity(0.15))
                .cornerRadius(CornerRadius.sm)

                Spacer()

                // Priority indicator
                if suggestion.priority == .high {
                    HStack(spacing: 2) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption2)
                        Text("High Priority")
                            .font(.caption2)
                    }
                    .foregroundColor(.red)
                }
            }

            // Content
            Text(suggestion.content)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            // Rationale (expandable)
            if !suggestion.rationale.isEmpty {
                Button(action: onToggleRationale) {
                    HStack(spacing: 4) {
                        Image(systemName: showRationale ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                        Text(showRationale ? "Hide rationale" : "Show rationale")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(showRationale ? "Hide rationale" : "Show rationale")
                .accessibilityHint("Expands to show why this suggestion was made")

                if showRationale {
                    Text(suggestion.rationale)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, Spacing.xxs)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            // Insert button
            Button(action: onInsert) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Insert into Plan")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.modusCyan)
                .foregroundColor(.white)
                .cornerRadius(CornerRadius.sm)
            }
            .accessibilityLabel("Insert suggestion into plan")
            .accessibilityHint("Adds this suggestion to your treatment plan")
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .contain)
    }

    private var categoryColor: Color {
        switch suggestion.category.color {
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "red": return .red
        case "teal": return .teal
        case "indigo": return .indigo
        case "brown": return .brown
        default: return .gray
        }
    }
}

// MARK: - Context Badge

private struct ContextBadge: View {
    let letter: String
    let color: Color
    let hasContent: Bool

    var body: some View {
        Text(letter)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(width: 22, height: 22)
            .background(hasContent ? color : Color.gray)
            .clipShape(Circle())
            .accessibilityLabel("\(sectionName) section \(hasContent ? "has content" : "is empty")")
    }

    private var sectionName: String {
        switch letter {
        case "S": return "Subjective"
        case "O": return "Objective"
        case "A": return "Assessment"
        default: return letter
        }
    }
}

// MARK: - Category Filter Chip

private struct PlanCategoryChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption2)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 6)
            .background(isSelected ? Color.modusCyan : Color(.tertiarySystemGroupedBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(CornerRadius.lg)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) filter")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Preview

#if DEBUG
struct SOAPPlanSuggestionView_Previews: PreviewProvider {
    static var previews: some View {
        SOAPPlanSuggestionView(
            subjective: "Patient reports knee pain for 2 weeks following a hiking trip. Pain is 6/10, worse with stairs.",
            objective: "ROM: Flexion 110/130, Extension 0/0. Strength: Quads 4/5. Positive patellar grind test.",
            assessment: "Patellofemoral pain syndrome, likely due to overuse. Good rehabilitation potential.",
            plan: .constant("")
        )
        .preferredColorScheme(.light)

        SOAPPlanSuggestionView(
            subjective: "Patient reports knee pain for 2 weeks.",
            objective: "ROM limited. Strength 4/5.",
            assessment: "Patellofemoral pain syndrome.",
            plan: .constant("")
        )
        .preferredColorScheme(.dark)
    }
}
#endif
