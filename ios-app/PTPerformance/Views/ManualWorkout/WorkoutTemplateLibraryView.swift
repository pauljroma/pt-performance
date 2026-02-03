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
    @Published var trainerRecommendations: [SystemWorkoutTemplate] = []  // BUILD 282
    @Published var isLoadingSystem = false
    @Published var isLoadingPatient = false
    @Published var isLoadingRecommendations = false  // BUILD 282
    @Published var errorMessage: String?
    @Published var searchText = "" {
        didSet { updateFilteredTemplates() }
    }
    @Published var selectedCategory: TemplateCategory? {
        didSet { updateFilteredTemplates() }
    }
    @Published var selectedTemplate: AnyWorkoutTemplate?
    @Published var showingPreview = false

    // BUILD 282: Favorites tracking
    @Published var favoriteSystemIds: Set<UUID> = [] {
        didSet { updateFilteredTemplates() }
    }
    @Published var favoritePatientIds: Set<UUID> = [] {
        didSet { updateFilteredTemplates() }
    }

    // MARK: - Cached Filtered Arrays (Performance Optimization)
    // Pre-computed to avoid re-computation on every view render
    @Published private(set) var cachedFilteredSystemTemplates: [SystemWorkoutTemplate] = []
    @Published private(set) var cachedFilteredPatientTemplates: [PatientWorkoutTemplate] = []
    @Published private(set) var cachedFavoriteSystemTemplates: [SystemWorkoutTemplate] = []
    @Published private(set) var cachedFavoritePatientTemplates: [PatientWorkoutTemplate] = []
    @Published private(set) var cachedFilteredTrainerRecommendations: [SystemWorkoutTemplate] = []

    // MARK: - Pagination Support
    private static let pageSize = 20
    @Published var displayedSystemTemplateCount = 20
    @Published var displayedTrainerRecommendationCount = 20
    @Published var isLoadingMore = false

    // MARK: - Dependencies

    private let service: ManualWorkoutService
    let patientId: UUID  // Made public for favorites toggle

    // MARK: - Initialization

    init(patientId: UUID, service: ManualWorkoutService = ManualWorkoutService()) {
        self.patientId = patientId
        self.service = service
    }

    // MARK: - Update Cached Filtered Templates
    // Called when search, category, or favorites change

    private func updateFilteredTemplates() {
        // Reset pagination when filters change
        displayedSystemTemplateCount = Self.pageSize
        displayedTrainerRecommendationCount = Self.pageSize

        // Update all cached arrays
        cachedFilteredSystemTemplates = computeFilteredSystemTemplates()
        cachedFilteredPatientTemplates = computeFilteredPatientTemplates()
        cachedFavoriteSystemTemplates = computeFavoriteSystemTemplates()
        cachedFavoritePatientTemplates = computeFavoritePatientTemplates()
        cachedFilteredTrainerRecommendations = computeFilteredTrainerRecommendations()
    }

    // MARK: - Load More Support

    func loadMoreSystemTemplates() {
        guard !isLoadingMore else { return }
        let totalAvailable = cachedFilteredSystemTemplates.count
        if displayedSystemTemplateCount < totalAvailable {
            isLoadingMore = true
            displayedSystemTemplateCount = min(displayedSystemTemplateCount + Self.pageSize, totalAvailable)
            isLoadingMore = false
        }
    }

    func loadMoreTrainerRecommendations() {
        guard !isLoadingMore else { return }
        let totalAvailable = cachedFilteredTrainerRecommendations.count
        if displayedTrainerRecommendationCount < totalAvailable {
            isLoadingMore = true
            displayedTrainerRecommendationCount = min(displayedTrainerRecommendationCount + Self.pageSize, totalAvailable)
            isLoadingMore = false
        }
    }

    // Paginated accessors
    var paginatedSystemTemplates: [SystemWorkoutTemplate] {
        Array(cachedFilteredSystemTemplates.prefix(displayedSystemTemplateCount))
    }

    var paginatedTrainerRecommendations: [SystemWorkoutTemplate] {
        Array(cachedFilteredTrainerRecommendations.prefix(displayedTrainerRecommendationCount))
    }

    var hasMoreSystemTemplates: Bool {
        displayedSystemTemplateCount < cachedFilteredSystemTemplates.count
    }

    var hasMoreTrainerRecommendations: Bool {
        displayedTrainerRecommendationCount < cachedFilteredTrainerRecommendations.count
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

    // MARK: - Filtered Templates Computation
    // BUILD 275: Added stable sorting to prevent reordering while viewing
    // Performance: These are called once when data changes, results cached in @Published properties

    // BUILD 331: Sort by display_order first (intended sequence), then name as tiebreaker
    private func computeFilteredSystemTemplates() -> [SystemWorkoutTemplate] {
        systemTemplates
            .filter { template in
                let matchesSearch = searchText.isEmpty ||
                    template.name.localizedCaseInsensitiveContains(searchText) ||
                    template.description?.localizedCaseInsensitiveContains(searchText) == true

                let matchesCategory = selectedCategory == nil ||
                    template.category?.lowercased() == selectedCategory?.rawValue

                return matchesSearch && matchesCategory
            }
            .sorted { lhs, rhs in
                // Sort by display_order first (intended workout sequence)
                let lhsOrder = lhs.displayOrder ?? Int.max
                let rhsOrder = rhs.displayOrder ?? Int.max
                if lhsOrder != rhsOrder {
                    return lhsOrder < rhsOrder
                }
                // Tiebreaker: alphabetical by name
                let nameComparison = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
                if nameComparison != .orderedSame {
                    return nameComparison == .orderedAscending
                }
                return lhs.id.uuidString < rhs.id.uuidString
            }
    }

    private func computeFilteredPatientTemplates() -> [PatientWorkoutTemplate] {
        patientTemplates
            .filter { template in
                let matchesSearch = searchText.isEmpty ||
                    template.name.localizedCaseInsensitiveContains(searchText) ||
                    template.description?.localizedCaseInsensitiveContains(searchText) == true

                return matchesSearch
            }
            .sorted { lhs, rhs in
                let nameComparison = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
                if nameComparison != .orderedSame {
                    return nameComparison == .orderedAscending
                }
                return lhs.id.uuidString < rhs.id.uuidString
            }
    }

    // BUILD 282/331: Favorite system templates sorted by display_order
    private func computeFavoriteSystemTemplates() -> [SystemWorkoutTemplate] {
        systemTemplates
            .filter { favoriteSystemIds.contains($0.id) }
            .filter { template in
                let matchesSearch = searchText.isEmpty ||
                    template.name.localizedCaseInsensitiveContains(searchText) ||
                    template.description?.localizedCaseInsensitiveContains(searchText) == true
                return matchesSearch
            }
            .sorted { lhs, rhs in
                let lhsOrder = lhs.displayOrder ?? Int.max
                let rhsOrder = rhs.displayOrder ?? Int.max
                if lhsOrder != rhsOrder {
                    return lhsOrder < rhsOrder
                }
                let nameComparison = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
                if nameComparison != .orderedSame {
                    return nameComparison == .orderedAscending
                }
                return lhs.id.uuidString < rhs.id.uuidString
            }
    }

    // BUILD 282: Favorite patient templates
    private func computeFavoritePatientTemplates() -> [PatientWorkoutTemplate] {
        patientTemplates
            .filter { favoritePatientIds.contains($0.id) }
            .filter { template in
                let matchesSearch = searchText.isEmpty ||
                    template.name.localizedCaseInsensitiveContains(searchText) ||
                    template.description?.localizedCaseInsensitiveContains(searchText) == true
                return matchesSearch
            }
            .sorted { lhs, rhs in
                let nameComparison = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
                if nameComparison != .orderedSame {
                    return nameComparison == .orderedAscending
                }
                return lhs.id.uuidString < rhs.id.uuidString
            }
    }

    // BUILD 282/331: Trainer recommendations filtered, sorted by display_order
    private func computeFilteredTrainerRecommendations() -> [SystemWorkoutTemplate] {
        trainerRecommendations
            .filter { template in
                let matchesSearch = searchText.isEmpty ||
                    template.name.localizedCaseInsensitiveContains(searchText) ||
                    template.description?.localizedCaseInsensitiveContains(searchText) == true
                return matchesSearch
            }
            .sorted { lhs, rhs in
                let lhsOrder = lhs.displayOrder ?? Int.max
                let rhsOrder = rhs.displayOrder ?? Int.max
                if lhsOrder != rhsOrder {
                    return lhsOrder < rhsOrder
                }
                let nameComparison = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
                if nameComparison != .orderedSame {
                    return nameComparison == .orderedAscending
                }
                return lhs.id.uuidString < rhs.id.uuidString
            }
    }

    // BUILD 282: Check if template is favorited
    func isFavorite(_ template: AnyWorkoutTemplate) -> Bool {
        if template.isSystemTemplate {
            return favoriteSystemIds.contains(template.id)
        } else {
            return favoritePatientIds.contains(template.id)
        }
    }

    func isFavoriteSystem(_ templateId: UUID) -> Bool {
        favoriteSystemIds.contains(templateId)
    }

    func isFavoritePatient(_ templateId: UUID) -> Bool {
        favoritePatientIds.contains(templateId)
    }

    // MARK: - Data Fetching
    // BUILD 278: Always fetch all templates, filter locally to prevent reordering

    func loadSystemTemplates() async {
        isLoadingSystem = true
        errorMessage = nil

        do {
            // Fetch ALL templates - filtering is done locally via cachedFilteredSystemTemplates
            systemTemplates = try await service.fetchSystemTemplates(
                category: nil,
                search: nil
            )
            updateFilteredTemplates()
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
            updateFilteredTemplates()
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
            group.addTask { await self.loadFavorites() }
            group.addTask { await self.loadTrainerRecommendations() }
        }
    }

    // BUILD 282: Load favorites
    func loadFavorites() async {
        do {
            let (sysIds, patIds) = try await service.fetchFavoriteTemplateIds(patientId: patientId)
            favoriteSystemIds = sysIds
            favoritePatientIds = patIds
        } catch {
            // Silently handle - favorites are optional
            DebugLogger.shared.log("Failed to load favorites: \(error)", level: .warning)
        }
    }

    // BUILD 282: Load trainer recommendations
    func loadTrainerRecommendations() async {
        isLoadingRecommendations = true
        do {
            trainerRecommendations = try await service.fetchTrainerRecommendations(patientId: patientId)
            updateFilteredTemplates()
            isLoadingRecommendations = false
        } catch {
            // Silently handle - recommendations are optional
            DebugLogger.shared.log("Failed to load trainer recommendations: \(error)", level: .warning)
            isLoadingRecommendations = false
        }
    }

    // BUILD 282: Toggle favorite for system template
    func toggleFavoriteSystem(_ templateId: UUID) async {
        if favoriteSystemIds.contains(templateId) {
            // Remove from favorites
            favoriteSystemIds.remove(templateId)
            do {
                try await service.removeSystemTemplateFromFavorites(patientId: patientId, templateId: templateId)
            } catch {
                // Revert on error
                favoriteSystemIds.insert(templateId)
                errorMessage = "Failed to remove from favorites"
            }
        } else {
            // Add to favorites
            favoriteSystemIds.insert(templateId)
            do {
                try await service.addSystemTemplateToFavorites(patientId: patientId, templateId: templateId)
            } catch {
                // Revert on error
                favoriteSystemIds.remove(templateId)
                errorMessage = "Failed to add to favorites"
            }
        }
    }

    // BUILD 282: Toggle favorite for patient template
    func toggleFavoritePatient(_ templateId: UUID) async {
        if favoritePatientIds.contains(templateId) {
            // Remove from favorites
            favoritePatientIds.remove(templateId)
            do {
                try await service.removePatientTemplateFromFavorites(patientId: patientId, templateId: templateId)
            } catch {
                // Revert on error
                favoritePatientIds.insert(templateId)
                errorMessage = "Failed to remove from favorites"
            }
        } else {
            // Add to favorites
            favoritePatientIds.insert(templateId)
            do {
                try await service.addPatientTemplateToFavorites(patientId: patientId, templateId: templateId)
            } catch {
                // Revert on error
                favoritePatientIds.remove(templateId)
                errorMessage = "Failed to add to favorites"
            }
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

                // Content - BUILD 282: 3 tabs
                TabView(selection: $selectedTab) {
                    myWorkoutsTab
                        .tag(0)

                    ptTrainerTab
                        .tag(1)

                    fullLibraryTab
                        .tag(2)
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
                    .accessibilityLabel("Cancel")
                    .accessibilityHint("Closes template library without selecting")
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

    // MARK: - Search Bar (uses TemplateSearchBar component)

    private var searchBar: some View {
        TemplateSearchBar(searchText: $viewModel.searchText)
    }

    // MARK: - Category Filters (uses TemplateCategoryFilters component)

    private var categoryFilters: some View {
        TemplateCategoryFilters(selectedCategory: $viewModel.selectedCategory)
    }

    // MARK: - Tab Picker (uses TemplateTabPicker component)

    private var tabPicker: some View {
        TemplateTabPicker(selectedTab: $selectedTab)
    }

    // MARK: - My Workouts Tab (BUILD 282)
    // Shows: Favorites + User-created templates

    @ViewBuilder
    private var myWorkoutsTab: some View {
        Group {
            let favoriteSystem = viewModel.cachedFavoriteSystemTemplates
            let favoritePatient = viewModel.cachedFavoritePatientTemplates
            let userCreated = viewModel.cachedFilteredPatientTemplates.filter { !viewModel.favoritePatientIds.contains($0.id) }

            if viewModel.isLoadingSystem && viewModel.systemTemplates.isEmpty {
                loadingView
            } else if favoriteSystem.isEmpty && favoritePatient.isEmpty && userCreated.isEmpty {
                emptyStateView(
                    title: "No Saved Workouts Yet",
                    message: "Tap the heart icon on any workout to save it to your favorites for quick access. You can also create your own custom workout templates.",
                    showClearButton: false,
                    icon: "heart.slash",
                    iconColor: .red.opacity(0.6)
                )
            } else {
                myWorkoutsGrid(
                    favoriteSystemTemplates: favoriteSystem,
                    favoritePatientTemplates: favoritePatient,
                    userCreatedTemplates: userCreated
                )
            }
        }
    }

    // MARK: - PT/Trainer Tab (BUILD 282)
    // Shows: Trainer recommendations + Prescribed workouts

    @ViewBuilder
    private var ptTrainerTab: some View {
        Group {
            if viewModel.isLoadingRecommendations && viewModel.trainerRecommendations.isEmpty {
                loadingView
            } else if viewModel.cachedFilteredTrainerRecommendations.isEmpty {
                emptyStateView(
                    title: "No Trainer Recommendations Yet",
                    message: "Workouts prescribed or recommended by your physical therapist or trainer will appear here. Contact your provider to get personalized workout plans.",
                    showClearButton: false,
                    icon: "person.badge.shield.checkmark",
                    iconColor: .blue.opacity(0.6)
                )
            } else {
                PaginatedTemplateGrid(
                    templates: viewModel.paginatedTrainerRecommendations.map { AnyWorkoutTemplate(systemTemplate: $0) },
                    showFavoriteButton: true,
                    hasMore: viewModel.hasMoreTrainerRecommendations,
                    isLoadingMore: viewModel.isLoadingMore,
                    isFavorite: { viewModel.isFavorite($0) },
                    onFavoriteToggle: { template in
                        Task {
                            if template.isSystemTemplate {
                                await viewModel.toggleFavoriteSystem(template.id)
                            } else {
                                await viewModel.toggleFavoritePatient(template.id)
                            }
                        }
                    },
                    onTemplateSelect: { template in
                        selectTemplate(template)
                    },
                    onLoadMore: { viewModel.loadMoreTrainerRecommendations() },
                    onRefresh: { await viewModel.loadAllTemplates() }
                )
            }
        }
    }

    // MARK: - Full Library Tab (BUILD 282)
    // Shows: All system templates (paginated for performance)

    @ViewBuilder
    private var fullLibraryTab: some View {
        Group {
            if viewModel.isLoadingSystem && viewModel.systemTemplates.isEmpty {
                loadingView
            } else if viewModel.cachedFilteredSystemTemplates.isEmpty {
                emptyStateView(
                    title: "No Matching Templates",
                    message: viewModel.searchText.isEmpty && viewModel.selectedCategory == nil
                        ? "Browse our comprehensive workout library with hundreds of professionally designed templates for strength, mobility, cardio, and more."
                        : "No templates match your current filters. Try adjusting your search criteria or clearing the filters.",
                    showClearButton: !viewModel.searchText.isEmpty || viewModel.selectedCategory != nil,
                    icon: "magnifyingglass",
                    iconColor: .secondary
                )
            } else {
                PaginatedTemplateGrid(
                    templates: viewModel.paginatedSystemTemplates.map { AnyWorkoutTemplate(systemTemplate: $0) },
                    showFavoriteButton: true,
                    hasMore: viewModel.hasMoreSystemTemplates,
                    isLoadingMore: viewModel.isLoadingMore,
                    isFavorite: { viewModel.isFavorite($0) },
                    onFavoriteToggle: { template in
                        Task {
                            if template.isSystemTemplate {
                                await viewModel.toggleFavoriteSystem(template.id)
                            } else {
                                await viewModel.toggleFavoritePatient(template.id)
                            }
                        }
                    },
                    onTemplateSelect: { template in
                        selectTemplate(template)
                    },
                    onLoadMore: { viewModel.loadMoreSystemTemplates() },
                    onRefresh: { await viewModel.loadAllTemplates() }
                )
            }
        }
    }

    // MARK: - My Workouts Grid (uses MyWorkoutsGrid component)

    private func myWorkoutsGrid(
        favoriteSystemTemplates: [SystemWorkoutTemplate],
        favoritePatientTemplates: [PatientWorkoutTemplate],
        userCreatedTemplates: [PatientWorkoutTemplate]
    ) -> some View {
        MyWorkoutsGrid(
            favoriteSystemTemplates: favoriteSystemTemplates,
            favoritePatientTemplates: favoritePatientTemplates,
            userCreatedTemplates: userCreatedTemplates,
            isFavoriteSystem: { viewModel.isFavoriteSystem($0) },
            isFavoritePatient: { viewModel.isFavoritePatient($0) },
            onToggleFavoriteSystem: { id in
                Task { await viewModel.toggleFavoriteSystem(id) }
            },
            onToggleFavoritePatient: { id in
                Task { await viewModel.toggleFavoritePatient(id) }
            },
            onSelectSystemTemplate: { viewModel.selectSystemTemplate($0) },
            onSelectPatientTemplate: { viewModel.selectPatientTemplate($0) },
            onRefresh: { await viewModel.loadAllTemplates() }
        )
    }

    // MARK: - Helper: Select Template

    private func selectTemplate(_ template: AnyWorkoutTemplate) {
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

    private func emptyStateView(title: String, message: String, showClearButton: Bool, icon: String = "doc.text.magnifyingglass", iconColor: Color = .secondary) -> some View {
        EmptyStateView(
            title: title,
            message: message,
            icon: icon,
            iconColor: iconColor,
            action: showClearButton ? EmptyStateView.EmptyStateAction(
                title: "Clear Filters",
                icon: "xmark.circle",
                action: {
                    viewModel.searchText = ""
                    viewModel.selectedCategory = nil
                    Task { await viewModel.loadAllTemplates() }
                }
            ) : nil
        )
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
                .accessibilityHidden(true)

            Text(value)
                .font(.headline)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
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
                    .background(Color(.secondarySystemGroupedBackground))
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
            .accessibilityLabel("Start workout")
            .accessibilityHint("Begins \(template.name) with \(template.exerciseCount) exercises")
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

                            // Use notes as display name if exercise name is just a number (strength block)
                            let exerciseDisplayName = exercise.name.count <= 2 && Int(exercise.name) != nil
                                ? (exercise.notes ?? exercise.name)
                                : (exercise.name.isEmpty ? "Exercise" : exercise.name)
                            Text(exerciseDisplayName)
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
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(block.displayName) block, \(block.exerciseCount) exercises")
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
