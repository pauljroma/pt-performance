//
//  TemplateLibraryView.swift
//  PTPerformance
//
//  Created by Build 46 Swarm Agent 2
//  Browse and search workout templates
//

import SwiftUI

struct TemplateLibraryView: View {

    @EnvironmentObject var appState: AppState

    @State private var templates: [WorkoutTemplate] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var selectedCategory: WorkoutTemplate.TemplateCategory?
    @State private var selectedDifficulty: WorkoutTemplate.DifficultyLevel?
    @State private var selectedDurationRange: DurationRange? = nil
    @State private var showMyTemplatesOnly = false
    @State private var selectedTemplate: WorkoutTemplate?
    @State private var showingCreateSheet = false

    /// Duration range filter options
    enum DurationRange: String, CaseIterable {
        case short = "< 4 weeks"
        case medium = "4-8 weeks"
        case long = "8-12 weeks"
        case extended = "12+ weeks"

        var displayName: String { rawValue }

        func matches(weeks: Int?) -> Bool {
            guard let weeks = weeks else { return false }
            switch self {
            case .short: return weeks < 4
            case .medium: return weeks >= 4 && weeks <= 8
            case .long: return weeks > 8 && weeks <= 12
            case .extended: return weeks > 12
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and filters
                searchAndFilters

                if isLoading && templates.isEmpty {
                    Spacer()
                    ProgressView("Loading templates...")
                    Spacer()
                } else if filteredTemplates.isEmpty {
                    emptyState
                } else {
                    templatesList
                }
            }
            .navigationTitle("Templates")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateTemplateView()
            }
            .sheet(item: $selectedTemplate) { template in
                TemplateDetailView(template: template)
            }
            .onAppear {
                Task {
                    await loadTemplates()
                }
            }
        }
    }

    // MARK: - Search and Filters

    private var searchAndFilters: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search templates...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)

            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // My Templates toggle
                    FilterChip(
                        title: "My Templates",
                        isSelected: showMyTemplatesOnly,
                        action: { showMyTemplatesOnly.toggle() }
                    )

                    Divider()
                        .frame(height: 24)

                    // Category filters
                    ForEach(WorkoutTemplate.TemplateCategory.allCases, id: \.self) { category in
                        FilterChip(
                            title: category.displayName,
                            icon: category.icon,
                            isSelected: selectedCategory == category,
                            action: {
                                selectedCategory = selectedCategory == category ? nil : category
                            }
                        )
                    }

                    Divider()
                        .frame(height: 24)

                    // Difficulty filters
                    ForEach(WorkoutTemplate.DifficultyLevel.allCases, id: \.self) { difficulty in
                        FilterChip(
                            title: difficulty.displayName,
                            isSelected: selectedDifficulty == difficulty,
                            action: {
                                selectedDifficulty = selectedDifficulty == difficulty ? nil : difficulty
                            }
                        )
                    }

                    Divider()
                        .frame(height: 24)

                    // Duration range filters
                    ForEach(DurationRange.allCases, id: \.self) { range in
                        FilterChip(
                            title: range.displayName,
                            icon: "calendar",
                            isSelected: selectedDurationRange == range,
                            action: {
                                selectedDurationRange = selectedDurationRange == range ? nil : range
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - Templates List

    private var templatesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredTemplates) { template in
                    TemplateCard(template: template)
                        .onTapGesture {
                            selectedTemplate = template
                        }
                }
            }
            .padding()
        }
        .refreshable {
            await loadTemplates()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        let hasFilters = !searchText.isEmpty || selectedCategory != nil || selectedDifficulty != nil || selectedDurationRange != nil

        return Group {
            if hasFilters {
                EmptyStateView(
                    title: "No Matching Templates",
                    message: "No templates match your current filters. Try adjusting your search criteria or clearing the filters.",
                    icon: "doc.text.magnifyingglass",
                    iconColor: .secondary,
                    action: EmptyStateView.EmptyStateAction(
                        title: "Clear Filters",
                        icon: "xmark.circle",
                        action: {
                            searchText = ""
                            selectedCategory = nil
                            selectedDifficulty = nil
                            selectedDurationRange = nil
                            showMyTemplatesOnly = false
                        }
                    )
                )
            } else {
                EmptyStateView(
                    title: "No Templates Yet",
                    message: "Create workout templates to save and reuse your favorite routines. Templates make it easy to start workouts quickly.",
                    icon: "rectangle.stack.fill",
                    iconColor: .blue,
                    action: EmptyStateView.EmptyStateAction(
                        title: "Create Template",
                        icon: "plus.circle.fill",
                        action: { showingCreateSheet = true }
                    )
                )
            }
        }
    }

    // MARK: - Filtered Templates

    private var filteredTemplates: [WorkoutTemplate] {
        templates.filter { template in
            // Search filter
            let matchesSearch = searchText.isEmpty ||
                template.name.localizedCaseInsensitiveContains(searchText) ||
                template.description?.localizedCaseInsensitiveContains(searchText) == true ||
                template.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }

            // Category filter
            let matchesCategory = selectedCategory == nil || template.category == selectedCategory

            // Difficulty filter
            let matchesDifficulty = selectedDifficulty == nil || template.difficultyLevel == selectedDifficulty

            // Duration range filter
            let matchesDuration = selectedDurationRange == nil || selectedDurationRange?.matches(weeks: template.durationWeeks) == true

            // My templates filter
            let matchesOwnership = !showMyTemplatesOnly || template.createdBy.uuidString == appState.userId

            return matchesSearch && matchesCategory && matchesDifficulty && matchesDuration && matchesOwnership
        }
    }

    // MARK: - Actions

    private func loadTemplates() async {
        isLoading = true
        errorMessage = nil

        do {
            if let userId = appState.userId {
                templates = try await TemplatesService.shared.fetchTemplates(for: userId)
            } else {
                templates = try await TemplatesService.shared.fetchPopularTemplates()
            }
        } catch {
            ErrorLogger.shared.logError(error, context: "TemplateLibraryView.loadTemplates")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Template Card

struct TemplateCard: View {
    let template: WorkoutTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top) {
                // Category icon
                Image(systemName: template.category.icon)
                    .font(.title2)
                    .foregroundColor(categoryColor)
                    .frame(width: 44, height: 44)
                    .background(categoryColor.opacity(0.1))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        // Category badge
                        CategoryBadge(category: template.category)

                        // Difficulty badge
                        if let difficulty = template.difficultyLevel {
                            DifficultyBadge(difficulty: difficulty)
                        }

                        // Popular badge
                        if template.isPopular {
                            PopularBadge()
                        }
                    }
                }

                Spacer()

                // Usage count
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(template.usageCount)")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("uses")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Description
            if let description = template.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            // Tags
            if !template.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(template.tags.prefix(5), id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .cornerRadius(6)
                        }
                    }
                }
            }

            // Footer
            HStack {
                if let duration = template.durationWeeks {
                    Label("\(duration)w", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("View Details")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .adaptiveShadow(Shadow.subtle)
    }

    private var categoryColor: Color {
        switch template.category {
        case .strength: return .blue
        case .mobility: return .green
        case .rehab: return .orange
        case .cardio: return .red
        case .hybrid: return .purple
        case .other: return .gray
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    var icon: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }

                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
    }
}

// MARK: - Badges

struct CategoryBadge: View {
    let category: WorkoutTemplate.TemplateCategory

    var body: some View {
        Text(category.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .cornerRadius(4)
    }

    private var color: Color {
        switch category {
        case .strength: return .blue
        case .mobility: return .green
        case .rehab: return .orange
        case .cardio: return .red
        case .hybrid: return .purple
        case .other: return .gray
        }
    }
}

struct DifficultyBadge: View {
    let difficulty: WorkoutTemplate.DifficultyLevel

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: difficulty.icon)
                .font(.caption2)

            Text(difficulty.displayName)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.15))
        .cornerRadius(4)
    }

    private var color: Color {
        switch difficulty {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
}

struct PopularBadge: View {
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .font(.caption2)

            Text("Popular")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(.yellow)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.yellow.opacity(0.15))
        .cornerRadius(4)
    }
}

// MARK: - Preview

struct TemplateLibraryView_Previews: PreviewProvider {
    static var previews: some View {
        TemplateLibraryView()
    }
}
