//
//  WorkoutTemplateLibraryView.swift
//  PTPerformance
//
//  Browse and select workout templates to start a manual workout
//

import SwiftUI

// MARK: - ViewModel

@MainActor
class WorkoutTemplateLibraryViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var systemTemplates: [SystemWorkoutTemplate] = []
    @Published var patientTemplates: [PatientWorkoutTemplate] = []
    @Published var isLoadingSystem = false
    @Published var isLoadingPatient = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedCategory: TemplateCategory?
    @Published var selectedTemplate: AnyWorkoutTemplate?
    @Published var showingPreview = false

    // MARK: - Dependencies

    private let service: ManualWorkoutService
    private let patientId: UUID

    // MARK: - Initialization

    init(patientId: UUID, service: ManualWorkoutService = ManualWorkoutService()) {
        self.patientId = patientId
        self.service = service
    }

    // MARK: - Template Categories

    enum TemplateCategory: String, CaseIterable {
        case strength
        case mobility
        case cardio
        case rehab
        case hybrid
        case other

        var displayName: String {
            switch self {
            case .strength: return "Strength"
            case .mobility: return "Mobility"
            case .cardio: return "Cardio"
            case .rehab: return "Rehab"
            case .hybrid: return "Hybrid"
            case .other: return "Other"
            }
        }

        var icon: String {
            switch self {
            case .strength: return "dumbbell.fill"
            case .mobility: return "figure.flexibility"
            case .cardio: return "heart.fill"
            case .rehab: return "cross.case.fill"
            case .hybrid: return "sparkles"
            case .other: return "ellipsis.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .strength: return .blue
            case .mobility: return .green
            case .cardio: return .red
            case .rehab: return .orange
            case .hybrid: return .purple
            case .other: return .gray
            }
        }
    }

    // MARK: - Filtered Templates

    var filteredSystemTemplates: [SystemWorkoutTemplate] {
        systemTemplates.filter { template in
            let matchesSearch = searchText.isEmpty ||
                template.name.localizedCaseInsensitiveContains(searchText) ||
                template.description?.localizedCaseInsensitiveContains(searchText) == true

            let matchesCategory = selectedCategory == nil ||
                template.category?.lowercased() == selectedCategory?.rawValue

            return matchesSearch && matchesCategory
        }
    }

    var filteredPatientTemplates: [PatientWorkoutTemplate] {
        patientTemplates.filter { template in
            let matchesSearch = searchText.isEmpty ||
                template.name.localizedCaseInsensitiveContains(searchText) ||
                template.description?.localizedCaseInsensitiveContains(searchText) == true

            return matchesSearch
        }
    }

    // MARK: - Data Fetching

    func loadSystemTemplates() async {
        isLoadingSystem = true
        errorMessage = nil

        do {
            systemTemplates = try await service.fetchSystemTemplates(
                category: selectedCategory?.rawValue,
                search: searchText.isEmpty ? nil : searchText
            )
            isLoadingSystem = false
        } catch {
            errorMessage = "Failed to load system templates: \(error.localizedDescription)"
            isLoadingSystem = false
        }
    }

    func loadPatientTemplates() async {
        isLoadingPatient = true
        errorMessage = nil

        do {
            patientTemplates = try await service.fetchPatientTemplates(patientId: patientId)
            isLoadingPatient = false
        } catch {
            errorMessage = "Failed to load your templates: \(error.localizedDescription)"
            isLoadingPatient = false
        }
    }

    func loadAllTemplates() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadSystemTemplates() }
            group.addTask { await self.loadPatientTemplates() }
        }
    }

    // MARK: - Template Selection

    func selectSystemTemplate(_ template: SystemWorkoutTemplate) {
        selectedTemplate = AnyWorkoutTemplate(systemTemplate: template)
        showingPreview = true
    }

    func selectPatientTemplate(_ template: PatientWorkoutTemplate) {
        selectedTemplate = AnyWorkoutTemplate(patientTemplate: template)
        showingPreview = true
    }

    func clearSelection() {
        selectedTemplate = nil
        showingPreview = false
    }
}

// MARK: - Type Eraser for Templates

struct AnyWorkoutTemplate: Identifiable {
    let id: UUID
    let name: String
    let description: String?
    let category: String?
    let difficulty: String?
    let durationDisplay: String?
    let exerciseCount: Int
    let blocks: WorkoutBlocks
    let isSystemTemplate: Bool
    let sourceTemplateId: UUID?

    init(systemTemplate: SystemWorkoutTemplate) {
        self.id = systemTemplate.id
        self.name = systemTemplate.name
        self.description = systemTemplate.description
        self.category = systemTemplate.category
        self.difficulty = systemTemplate.difficulty
        self.durationDisplay = systemTemplate.durationDisplay
        self.exerciseCount = systemTemplate.exerciseCount
        self.blocks = systemTemplate.blocks
        self.isSystemTemplate = true
        self.sourceTemplateId = nil
    }

    init(patientTemplate: PatientWorkoutTemplate) {
        self.id = patientTemplate.id
        self.name = patientTemplate.name
        self.description = patientTemplate.description
        self.category = patientTemplate.category
        self.difficulty = nil
        self.durationDisplay = nil
        self.exerciseCount = patientTemplate.exerciseCount
        self.blocks = patientTemplate.blocks
        self.isSystemTemplate = false
        self.sourceTemplateId = nil // Patient templates don't track source
    }
}

// MARK: - Main View

struct WorkoutTemplateLibraryView: View {

    @StateObject private var viewModel: WorkoutTemplateLibraryViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab = 0

    let patientId: UUID
    let onStartWorkout: (AnyWorkoutTemplate) -> Void

    init(patientId: UUID, onStartWorkout: @escaping (AnyWorkoutTemplate) -> Void) {
        self.patientId = patientId
        self.onStartWorkout = onStartWorkout
        _viewModel = StateObject(wrappedValue: WorkoutTemplateLibraryViewModel(patientId: patientId))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar

                // Category filter chips
                categoryFilters

                // Tab navigation
                tabPicker

                // Content
                TabView(selection: $selectedTab) {
                    systemTemplatesTab
                        .tag(0)

                    patientTemplatesTab
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Workout Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingPreview) {
                if let template = viewModel.selectedTemplate {
                    TemplatePreviewSheet(
                        template: template,
                        onStartWorkout: {
                            onStartWorkout(template)
                            dismiss()
                        },
                        onDismiss: {
                            viewModel.clearSelection()
                        }
                    )
                }
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .task {
                await viewModel.loadAllTemplates()
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search templates...", text: $viewModel.searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .autocorrectionDisabled()

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Category Filters

    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All categories chip
                TemplateCategoryChip(
                    title: "All",
                    icon: "list.bullet",
                    isSelected: viewModel.selectedCategory == nil,
                    color: .gray
                ) {
                    viewModel.selectedCategory = nil
                    Task { await viewModel.loadSystemTemplates() }
                }

                ForEach(WorkoutTemplateLibraryViewModel.TemplateCategory.allCases, id: \.self) { category in
                    TemplateCategoryChip(
                        title: category.displayName,
                        icon: category.icon,
                        isSelected: viewModel.selectedCategory == category,
                        color: category.color
                    ) {
                        viewModel.selectedCategory = viewModel.selectedCategory == category ? nil : category
                        Task { await viewModel.loadSystemTemplates() }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        HStack(spacing: 0) {
            TabButton(
                title: "PT Library",
                icon: "building.2.fill",
                isSelected: selectedTab == 0
            ) {
                withAnimation { selectedTab = 0 }
            }

            TabButton(
                title: "My Templates",
                icon: "person.fill",
                isSelected: selectedTab == 1
            ) {
                withAnimation { selectedTab = 1 }
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: - System Templates Tab

    private var systemTemplatesTab: some View {
        Group {
            if viewModel.isLoadingSystem && viewModel.systemTemplates.isEmpty {
                loadingView
            } else if viewModel.filteredSystemTemplates.isEmpty {
                emptyStateView(
                    title: "No Templates Found",
                    message: viewModel.searchText.isEmpty && viewModel.selectedCategory == nil
                        ? "System templates will appear here"
                        : "Try adjusting your search or filters",
                    showClearButton: !viewModel.searchText.isEmpty || viewModel.selectedCategory != nil
                )
            } else {
                templateGrid(templates: viewModel.filteredSystemTemplates.map { AnyWorkoutTemplate(systemTemplate: $0) })
            }
        }
    }

    // MARK: - Patient Templates Tab

    private var patientTemplatesTab: some View {
        Group {
            if viewModel.isLoadingPatient && viewModel.patientTemplates.isEmpty {
                loadingView
            } else if viewModel.filteredPatientTemplates.isEmpty {
                emptyStateView(
                    title: "No Custom Templates",
                    message: viewModel.searchText.isEmpty
                        ? "Templates you create or customize will appear here"
                        : "No templates match your search",
                    showClearButton: !viewModel.searchText.isEmpty
                )
            } else {
                templateGrid(templates: viewModel.filteredPatientTemplates.map { AnyWorkoutTemplate(patientTemplate: $0) })
            }
        }
    }

    // MARK: - Template Grid

    private func templateGrid(templates: [AnyWorkoutTemplate]) -> some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(templates) { template in
                    TemplateCardView(template: template)
                        .onTapGesture {
                            if template.isSystemTemplate {
                                if let systemTemplate = viewModel.systemTemplates.first(where: { $0.id == template.id }) {
                                    viewModel.selectSystemTemplate(systemTemplate)
                                }
                            } else {
                                if let patientTemplate = viewModel.patientTemplates.first(where: { $0.id == template.id }) {
                                    viewModel.selectPatientTemplate(patientTemplate)
                                }
                            }
                        }
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.loadAllTemplates()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading templates...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State View

    private func emptyStateView(title: String, message: String, showClearButton: Bool) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(title)
                .font(.title3)
                .fontWeight(.semibold)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if showClearButton {
                Button("Clear Filters") {
                    viewModel.searchText = ""
                    viewModel.selectedCategory = nil
                    Task { await viewModel.loadAllTemplates() }
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Template Category Chip

private struct TemplateCategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.blue : Color.clear)
            .foregroundColor(isSelected ? .white : .secondary)
            .cornerRadius(8)
        }
        .padding(4)
    }
}

// MARK: - Template Card View

struct TemplateCardView: View {
    let template: AnyWorkoutTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with category badge
            HStack {
                if let category = template.category {
                    TemplateCategoryBadge(category: category)
                }
                Spacer()
                if template.isSystemTemplate {
                    Image(systemName: "building.2.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Template name
            Text(template.name)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Description preview
            if let description = template.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            // Exercise list - show first 5 exercises with sets/reps
            let allExercises = template.blocks.flatMap { $0.exercises }
            if !allExercises.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(allExercises.prefix(5).enumerated()), id: \.offset) { _, exercise in
                        HStack(spacing: 4) {
                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text(exercise.name)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            Spacer()
                            Text(exercise.setsRepsDisplay)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    if allExercises.count > 5 {
                        Text("+ \(allExercises.count - 5) more exercises")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.vertical, 4)
            }

            Spacer(minLength: 4)

            // Stats row
            HStack(spacing: 12) {
                // Exercise count
                Label("\(template.exerciseCount)", systemImage: "figure.strengthtraining.traditional")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Block count
                Label("\(template.blocks.count)", systemImage: "square.stack.3d.up")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Duration if available
                if let duration = template.durationDisplay {
                    Label(duration, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Difficulty badge if available
                if let difficulty = template.difficulty {
                    TemplateDifficultyBadge(difficulty: difficulty)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 200, alignment: .topLeading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
    }
}

// MARK: - Template Category Badge

struct TemplateCategoryBadge: View {
    let category: String

    var body: some View {
        Text(category.capitalized)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(categoryColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(categoryColor.opacity(0.15))
            .cornerRadius(6)
    }

    private var categoryColor: Color {
        switch category.lowercased() {
        case "strength": return .blue
        case "mobility": return .green
        case "cardio": return .red
        case "rehab": return .orange
        case "hybrid": return .purple
        default: return .gray
        }
    }
}

// MARK: - Template Difficulty Badge

struct TemplateDifficultyBadge: View {
    let difficulty: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: difficultyIcon)
                .font(.caption2)

            Text(difficulty.capitalized)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(difficultyColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(difficultyColor.opacity(0.15))
        .cornerRadius(6)
    }

    private var difficultyIcon: String {
        switch difficulty.lowercased() {
        case "beginner": return "1.circle.fill"
        case "intermediate": return "2.circle.fill"
        case "advanced": return "3.circle.fill"
        default: return "circle.fill"
        }
    }

    private var difficultyColor: Color {
        switch difficulty.lowercased() {
        case "beginner": return .green
        case "intermediate": return .orange
        case "advanced": return .red
        default: return .gray
        }
    }
}

// MARK: - Template Preview Sheet

struct TemplatePreviewSheet: View {
    let template: AnyWorkoutTemplate
    let onStartWorkout: () -> Void
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header section
                    headerSection

                    // Description
                    if let description = template.description, !description.isEmpty {
                        descriptionSection(description)
                    }

                    // Stats section
                    statsSection

                    // Exercises section
                    exercisesSection
                }
                .padding()
            }
            .navigationTitle("Template Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        onDismiss()
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                startWorkoutButton
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(template.name)
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 8) {
                if let category = template.category {
                    TemplateCategoryBadge(category: category)
                }

                if let difficulty = template.difficulty {
                    TemplateDifficultyBadge(difficulty: difficulty)
                }

                if template.isSystemTemplate {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                        Text("PT Library")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(6)
                }
            }
        }
    }

    // MARK: - Description Section

    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)

            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: 16) {
            statCard(
                value: "\(template.exerciseCount)",
                label: "Exercises",
                icon: "figure.strengthtraining.traditional",
                color: .blue
            )

            if let duration = template.durationDisplay {
                statCard(
                    value: duration,
                    label: "Duration",
                    icon: "clock.fill",
                    color: .green
                )
            }

            statCard(
                value: "\(template.blocks.count)",
                label: "Blocks",
                icon: "square.stack.3d.up.fill",
                color: .purple
            )
        }
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.headline)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Exercises Section

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Workout Structure")
                .font(.headline)

            if template.blocks.isEmpty {
                Text("No exercises in this template")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            } else {
                ForEach(template.blocks) { block in
                    BlockPreviewCard(block: block)
                }
            }
        }
    }

    // MARK: - Start Workout Button

    private var startWorkoutButton: some View {
        VStack(spacing: 0) {
            Divider()

            Button(action: onStartWorkout) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Workout")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Block Preview Card

struct BlockPreviewCard: View {
    let block: WorkoutBlock

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Block header
            HStack {
                Image(systemName: block.icon)
                    .font(.title3)
                    .foregroundColor(block.color)
                    .frame(width: 32, height: 32)
                    .background(block.color.opacity(0.15))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(block.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("\(block.exerciseCount) exercises")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Exercise list
            if !block.exercises.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(block.exercises.prefix(5)) { exercise in
                        HStack {
                            Circle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(width: 6, height: 6)

                            Text(exercise.name.isEmpty ? "Exercise" : exercise.name)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text(exercise.setsRepsDisplay)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if block.exercises.count > 5 {
                        Text("+ \(block.exercises.count - 5) more exercises")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.leading, 40)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    WorkoutTemplateLibraryView(
        patientId: UUID(),
        onStartWorkout: { template in
            print("Starting workout: \(template.name)")
        }
    )
}
