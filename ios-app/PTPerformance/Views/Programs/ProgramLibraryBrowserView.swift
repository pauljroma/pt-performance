// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  ProgramLibraryBrowserView.swift
//  PTPerformance
//
//  Browse and discover programs from the program library
//
//  BUILD 320: Baseball Pack Integration
//  Added baseball category with premium gating for baseball programs
//
//  ACP-1031: Program Browser UX Enhancement
//  - Added filter chips for duration (4 week, 8 week, 12 week), equipment, and goal type
//  - Clear difficulty indicators (stars + badges: Beginner/Intermediate/Advanced)
//  - Preview button showing first week workout schedule before enrolling
//  - Enhanced program cards with duration, sessions/week, difficulty, equipment icons
//  - Sorting options (Popular, Newest, Duration, Difficulty)
//  - Modus brand colors throughout
//

import SwiftUI

// MARK: - Main View

struct ProgramLibraryBrowserView: View {

    // MARK: - Environment

    @EnvironmentObject var storeKit: StoreKitService

    // MARK: - State

    @StateObject private var viewModel = ProgramLibraryBrowserViewModel()
    @State private var selectedProgram: ProgramLibrary?
    @State private var showBaseballLocked = false
    @State private var programToDuplicate: ProgramLibrary?
    @State private var showFilters = false
    @State private var previewProgram: ProgramLibrary?

    // MARK: - Constants

    private let categories = ["All", "Annuals", "Strength", "Mobility", "Conditioning", "Baseball"]
    private let difficulties = ["All", "Beginner", "Intermediate", "Advanced"]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Search bar + sort
            searchAndSortBar

            // Category filter chips
            categoryFilters

            // ACP-1031: Collapsible advanced filters
            if showFilters {
                advancedFilters
            }

            // ACP-1031: Active filter summary + results count
            filterSummaryBar

            // Content
            contentView
        }
        .sheet(item: $selectedProgram) { program in
            ProgramDetailSheet(program: program)
        }
        .sheet(item: $previewProgram) { program in
            ProgramFirstWeekPreviewSheet(program: program, viewModel: viewModel)
        }
        .sheet(isPresented: $showBaseballLocked) {
            NavigationStack {
                BaseballPackLockedView()
                    .environmentObject(storeKit)
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
        .alert("Success", isPresented: Binding(
            get: { viewModel.successMessage != nil },
            set: { if !$0 { viewModel.successMessage = nil } }
        )) {
            Button("OK") { viewModel.successMessage = nil }
        } message: {
            if let message = viewModel.successMessage {
                Text(message)
            }
        }
        .confirmationDialog(
            "Duplicate Program",
            isPresented: Binding(
                get: { programToDuplicate != nil },
                set: { if !$0 { programToDuplicate = nil } }
            ),
            presenting: programToDuplicate
        ) { program in
            Button("Duplicate") {
                Task {
                    do {
                        _ = try await viewModel.duplicateProgram(program)
                    } catch {
                        // Error is handled by viewModel
                    }
                    programToDuplicate = nil
                }
            }
            Button("Cancel", role: .cancel) {
                programToDuplicate = nil
            }
        } message: { program in
            Text("Create a copy of '\(program.title)'? The copy will include all phases and workout assignments.")
        }
        .overlay {
            if viewModel.isDuplicating {
                ZStack {
                    Color(.label).opacity(0.3)
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Duplicating program...")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .padding(24)
                    .background(Color(.systemBackground))
                    .cornerRadius(CornerRadius.md)
                    .shadow(radius: 10)
                }
            }
        }
        .task {
            await viewModel.loadAllData()
        }
    }

    // MARK: - Search and Sort Bar

    private var searchAndSortBar: some View {
        HStack(spacing: 8) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)

                TextField("Search programs...", text: $viewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .autocorrectionDisabled()
                    .accessibilityLabel("Search programs")
                    .accessibilityHint("Enter text to filter programs by name")

                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Clear search")
                    .accessibilityHint("Removes search text and shows all programs")
                }
            }
            .padding(10)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.sm)

            // ACP-1031: Filter toggle button
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showFilters.toggle()
                }
                HapticFeedback.selectionChanged()
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: showFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.title3)
                        .foregroundColor(showFilters ? .modusCyan : .secondary)

                    // Active filter count badge
                    if viewModel.activeFilterCount > 0 {
                        Text("\(viewModel.activeFilterCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 16, height: 16)
                            .background(Color.modusCyan)
                            .clipShape(Circle())
                            .offset(x: 4, y: -4)
                    }
                }
            }
            .accessibilityLabel("Filters")
            .accessibilityValue(showFilters ? "Open, \(viewModel.activeFilterCount) active" : "Closed")
            .accessibilityHint("Double tap to \(showFilters ? "hide" : "show") advanced filters")

            // ACP-1031: Sort menu
            Menu {
                ForEach(ProgramSortOption.allCases) { option in
                    Button {
                        viewModel.sortOption = option
                        HapticFeedback.selectionChanged()
                    } label: {
                        Label(option.rawValue, systemImage: option.icon)
                        if viewModel.sortOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down.circle")
                    .font(.title3)
                    .foregroundColor(viewModel.sortOption != .popular ? .modusCyan : .secondary)
            }
            .accessibilityLabel("Sort by \(viewModel.sortOption.rawValue)")
            .accessibilityHint("Double tap to change sort order")
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Category Filters

    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { category in
                    let isSelected = (category == "All" && viewModel.selectedCategory == nil) ||
                        (category != "All" && viewModel.selectedCategory?.rawValue.lowercased() == category.lowercased())

                    // Special handling for baseball category with premium badge
                    if category == "Baseball" {
                        BaseballCategoryChip(
                            isSelected: isSelected,
                            isPremium: !storeKit.hasBaseballAccess
                        ) {
                            handleBaseballCategoryTap()
                        }
                    } else {
                        ProgramFilterChip(
                            title: category,
                            icon: iconForCategory(category),
                            isSelected: isSelected,
                            color: colorForCategory(category)
                        ) {
                            if category == "All" {
                                viewModel.selectedCategory = nil
                            } else {
                                let newCategory = ProgramCategory(rawValue: category.lowercased())
                                viewModel.selectedCategory = viewModel.selectedCategory == newCategory ? nil : newCategory
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Baseball Category Tap Handler

    private func handleBaseballCategoryTap() {
        if storeKit.hasBaseballAccess {
            // User owns baseball pack - filter to baseball programs
            let newCategory = ProgramCategory(rawValue: "baseball")
            viewModel.selectedCategory = viewModel.selectedCategory == newCategory ? nil : newCategory
        } else {
            // User doesn't own baseball pack - show locked view
            showBaseballLocked = true
        }
    }

    // MARK: - ACP-1031: Advanced Filters (Collapsible)

    private var advancedFilters: some View {
        VStack(spacing: 8) {
            // Difficulty filter row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Text("Difficulty")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .leading)

                    ForEach(difficulties, id: \.self) { difficulty in
                        let isSelected = (difficulty == "All" && viewModel.selectedDifficulty == nil) ||
                            (difficulty != "All" && viewModel.selectedDifficulty?.rawValue.lowercased() == difficulty.lowercased())

                        ProgramFilterChip(
                            title: difficulty,
                            icon: iconForDifficulty(difficulty),
                            isSelected: isSelected,
                            color: colorForDifficulty(difficulty)
                        ) {
                            if difficulty == "All" {
                                viewModel.selectedDifficulty = nil
                            } else {
                                let newDifficulty = DifficultyLevel(rawValue: difficulty.lowercased())
                                viewModel.selectedDifficulty = viewModel.selectedDifficulty == newDifficulty ? nil : newDifficulty
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Duration filter row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Text("Duration")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .leading)

                    ForEach(DurationFilter.allCases) { duration in
                        ProgramFilterChip(
                            title: duration.rawValue,
                            icon: duration == .all ? "clock" : "calendar.badge.clock",
                            isSelected: viewModel.selectedDuration == duration,
                            color: .modusCyan
                        ) {
                            viewModel.selectedDuration = viewModel.selectedDuration == duration ? .all : duration
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Equipment filter row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Text("Equip")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .leading)

                    ForEach(EquipmentFilter.allCases) { equip in
                        ProgramFilterChip(
                            title: equip.rawValue,
                            icon: equip.icon,
                            isSelected: viewModel.selectedEquipment == equip,
                            color: .modusTealAccent
                        ) {
                            viewModel.selectedEquipment = viewModel.selectedEquipment == equip ? .all : equip
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Goal filter row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Text("Goal")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .leading)

                    ForEach(GoalFilter.allCases) { goal in
                        ProgramFilterChip(
                            title: goal.rawValue,
                            icon: goal.icon,
                            isSelected: viewModel.selectedGoal == goal,
                            color: .modusDeepTeal
                        ) {
                            viewModel.selectedGoal = viewModel.selectedGoal == goal ? .all : goal
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom, 8)
        .background(Color(.systemGroupedBackground))
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - ACP-1031: Filter Summary Bar

    private var filterSummaryBar: some View {
        HStack {
            // Results count
            Text("\(viewModel.cachedFilteredPrograms.count) program\(viewModel.cachedFilteredPrograms.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.secondary)

            // Sort indicator
            HStack(spacing: 4) {
                Image(systemName: viewModel.sortOption.icon)
                    .font(.caption2)
                Text(viewModel.sortOption.rawValue)
                    .font(.caption)
            }
            .foregroundColor(.modusCyan)

            Spacer()

            // Clear filters button (when filters active)
            if viewModel.hasActiveFilters {
                Button {
                    viewModel.clearFilters()
                    HapticFeedback.selectionChanged()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption2)
                        Text("Clear")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.modusCyan)
                }
                .accessibilityLabel("Clear all filters")
                .accessibilityHint("Removes all active filters and shows all programs")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemGroupedBackground).opacity(0.5))
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.programs.isEmpty {
            loadingView
        } else if viewModel.cachedFilteredPrograms.isEmpty {
            emptyStateView
        } else {
            programsGrid
        }
    }

    // MARK: - Programs Grid

    private var programsGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(viewModel.cachedFilteredPrograms.enumerated()), id: \.element.id) { index, program in
                    EnhancedProgramLibraryCard(
                        program: program,
                        onDuplicate: {
                            programToDuplicate = program
                        },
                        onPreview: {
                            previewProgram = program
                        }
                    )
                    .onTapGesture {
                        selectedProgram = program
                    }
                    .staggeredAnimation(index: index)
                }
            }
            .padding()
        }
        .refreshableWithHaptic {
            await viewModel.loadAllData()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        ProgramLibrarySkeletonView()
            .accessibilityLabel("Loading programs, please wait")
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        EmptyStateView(
            title: viewModel.hasActiveFilters ? "No Matching Programs" : "No Programs Assigned Yet",
            message: viewModel.hasActiveFilters
                ? "No programs match your current filters. Try adjusting your search criteria or browse all available programs."
                : "Browse our library of professionally designed training programs for strength, mobility, conditioning, and more.",
            icon: viewModel.hasActiveFilters ? "magnifyingglass" : "figure.strengthtraining.traditional",
            iconColor: viewModel.hasActiveFilters ? .secondary : .modusCyan,
            action: viewModel.hasActiveFilters ? EmptyStateView.EmptyStateAction(
                title: "Clear All Filters",
                icon: "xmark.circle",
                action: {
                    viewModel.clearFilters()
                }
            ) : nil
        )
    }

    // MARK: - Helper Functions

    private func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "all": return "list.bullet"
        case "annuals": return "calendar"
        case "strength": return "dumbbell.fill"
        case "mobility": return "figure.flexibility"
        case "conditioning": return "heart.fill"
        case "baseball": return "baseball.fill"
        default: return "figure.run"
        }
    }

    private func colorForCategory(_ category: String) -> Color {
        switch category.lowercased() {
        case "all": return .gray
        case "annuals": return .purple
        case "strength": return .blue
        case "mobility": return .green
        case "conditioning": return .red
        case "baseball": return .orange
        default: return .gray
        }
    }

    private func iconForDifficulty(_ difficulty: String) -> String {
        switch difficulty.lowercased() {
        case "all": return "slider.horizontal.3"
        case "beginner": return "1.circle.fill"
        case "intermediate": return "2.circle.fill"
        case "advanced": return "3.circle.fill"
        default: return "circle.fill"
        }
    }

    private func colorForDifficulty(_ difficulty: String) -> Color {
        switch difficulty.lowercased() {
        case "all": return .gray
        case "beginner": return .green
        case "intermediate": return .orange
        case "advanced": return .red
        default: return .gray
        }
    }
}

// MARK: - Program Filter Chip

private struct ProgramFilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.selectionChanged()
            action()
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : Color(.tertiarySystemGroupedBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(CornerRadius.xl)
        }
        .accessibilityLabel("\(title) filter")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint("Double tap to \(isSelected ? "deselect" : "select") this filter")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Baseball Category Chip (with Premium Badge)

private struct BaseballCategoryChip: View {
    let isSelected: Bool
    let isPremium: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.selectionChanged()
            action()
        }) {
            HStack(spacing: 4) {
                Image(systemName: "baseball.fill")
                    .font(.caption)
                    .accessibilityHidden(true)

                Text("Baseball")
                    .font(.subheadline)
                    .fontWeight(.medium)

                // Premium badge if not owned
                if isPremium {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .orange)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.orange : Color(.tertiarySystemGroupedBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(CornerRadius.xl)
            .overlay(
                // Premium indicator border
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        isPremium && !isSelected ? Color.orange.opacity(0.5) : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .accessibilityLabel("Baseball filter\(isPremium ? ", premium content" : "")")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint(isPremium ? "Double tap to view Baseball Pack purchase options" : "Double tap to \(isSelected ? "deselect" : "select") this filter")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - ACP-1031: Enhanced Program Library Card

struct EnhancedProgramLibraryCard: View {
    let program: ProgramLibrary
    var onDuplicate: (() -> Void)? = nil
    var onPreview: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover image at top with difficulty overlay
            ZStack(alignment: .topTrailing) {
                ProgramCoverImage(
                    url: program.coverImageUrl,
                    size: CGSize(width: CGFloat.infinity, height: 100),
                    cornerRadius: 0
                )
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .clipped()
                .accessibilityHidden(true)

                // ACP-1031: Difficulty stars overlay
                HStack(spacing: 2) {
                    ForEach(1...3, id: \.self) { star in
                        Image(systemName: star <= program.difficultyStars ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundColor(star <= program.difficultyStars ? .yellow : .white.opacity(0.5))
                    }
                }
                .padding(6)
                .background(Color.black.opacity(0.5))
                .cornerRadius(CornerRadius.sm)
                .padding(8)
            }

            VStack(alignment: .leading, spacing: 6) {
                // Header with category badge and featured star
                HStack {
                    // Category badge
                    ProgramCategoryBadge(category: program.category)

                    Spacer()

                    // Featured star
                    if program.featured {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                            .accessibilityHidden(true)
                    }
                }

                // Program title
                Text(program.title)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.modusDeepTeal)

                // ACP-1031: Enhanced info row with duration, sessions/week, and equipment
                HStack(spacing: 6) {
                    // Duration
                    HStack(spacing: 2) {
                        Image(systemName: "calendar")
                            .font(.system(size: 9))
                        Text(program.formattedDuration)
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.secondary)

                    Text("|")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary.opacity(0.5))

                    // Sessions per week
                    HStack(spacing: 2) {
                        Image(systemName: "repeat")
                            .font(.system(size: 9))
                        Text("\(program.estimatedSessionsPerWeek)x/wk")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.secondary)

                    Text("|")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary.opacity(0.5))

                    // Equipment
                    HStack(spacing: 2) {
                        Image(systemName: program.equipmentIcon)
                            .font(.system(size: 9))
                        Text(program.equipmentSummary)
                            .font(.system(size: 10))
                            .lineLimit(1)
                    }
                    .foregroundColor(.secondary)
                }

                Spacer(minLength: 4)

                // ACP-1031: Bottom row with difficulty badge and preview button
                HStack(spacing: 6) {
                    // Enhanced difficulty badge
                    ProgramDifficultyBadge(difficulty: program.difficultyLevel)

                    Spacer()

                    // Preview button
                    if program.programId != nil {
                        Button {
                            HapticFeedback.light()
                            onPreview?()
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "eye.fill")
                                    .font(.system(size: 9))
                                Text("Preview")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(.modusCyan)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.modusCyan.opacity(0.12))
                            .cornerRadius(CornerRadius.sm)
                        }
                        .accessibilityLabel("Preview first week of \(program.title)")
                        .accessibilityHint("Shows the first week workout schedule before enrolling")
                    }
                }
            }
            .padding(10)
        }
        .frame(maxWidth: .infinity, minHeight: 230, alignment: .topLeading)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .clipped()
        .adaptiveShadow(Shadow.subtle)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(program.title)\(program.featured ? ", featured program" : ""), \(program.category.capitalized) category, \(program.formattedDuration), \(program.difficultyLevel.capitalized) difficulty, \(program.estimatedSessionsPerWeek) sessions per week, \(program.equipmentSummary)")
        .accessibilityHint("Double tap to view program details")
        .contextMenu {
            if let onPreview = onPreview, program.programId != nil {
                Button {
                    HapticFeedback.light()
                    onPreview()
                } label: {
                    Label("Preview First Week", systemImage: "eye.fill")
                }
            }

            if let onDuplicate = onDuplicate {
                Button {
                    HapticFeedback.medium()
                    onDuplicate()
                } label: {
                    Label("Duplicate Program", systemImage: "doc.on.doc")
                }
            }

            Divider()

            Button {
                HapticFeedback.light()
                UIPasteboard.general.string = program.title
            } label: {
                Label("Copy Title", systemImage: "doc.on.clipboard")
            }

            if let description = program.description, !description.isEmpty {
                Button {
                    HapticFeedback.light()
                    UIPasteboard.general.string = description
                } label: {
                    Label("Copy Description", systemImage: "text.alignleft")
                }
            }

            Divider()

            Button {
                HapticFeedback.light()
                var summary = "\(program.title) - \(program.category.capitalized)"
                summary += " (\(program.formattedDuration), \(program.difficultyLevel.capitalized))"
                if let description = program.description {
                    summary += "\n\n\(description)"
                }
                UIPasteboard.general.string = summary
            } label: {
                Label("Share Program", systemImage: "square.and.arrow.up")
            }
        }
    }
}

// MARK: - Program Category Badge

struct ProgramCategoryBadge: View {
    let category: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: categoryIcon)
                .font(.caption2)

            Text(category.capitalized)
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .foregroundColor(categoryColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(categoryColor.opacity(0.15))
        .cornerRadius(CornerRadius.sm)
    }

    private var categoryIcon: String {
        switch category.lowercased() {
        case "annuals": return "calendar"
        case "strength": return "dumbbell.fill"
        case "mobility": return "figure.flexibility"
        case "cardio", "conditioning": return "heart.fill"
        case "recovery": return "bed.double.fill"
        case "sport": return "sportscourt.fill"
        case "baseball": return "baseball.fill"
        default: return "figure.run"
        }
    }

    private var categoryColor: Color {
        switch category.lowercased() {
        case "annuals": return .purple
        case "strength": return .blue
        case "mobility": return .green
        case "cardio", "conditioning": return .red
        case "recovery": return .teal
        case "sport": return .orange
        case "baseball": return .orange
        default: return .gray
        }
    }
}

// MARK: - Program Difficulty Badge

struct ProgramDifficultyBadge: View {
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
        .cornerRadius(CornerRadius.sm)
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

// MARK: - ACP-1031: First Week Preview Sheet

struct ProgramFirstWeekPreviewSheet: View {
    let program: ProgramLibrary
    @ObservedObject var viewModel: ProgramLibraryBrowserViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Program header
                    programHeader

                    Divider()

                    // First week schedule
                    firstWeekContent
                }
                .padding()
            }
            .navigationTitle("Week 1 Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Close preview")
                }
            }
        }
        .task {
            await viewModel.loadFirstWeekPreview(for: program)
        }
    }

    // MARK: - Program Header

    private var programHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(program.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.modusDeepTeal)

            HStack(spacing: 12) {
                ProgramCategoryBadge(category: program.category)
                ProgramDifficultyBadge(difficulty: program.difficultyLevel)

                // Difficulty stars
                HStack(spacing: 2) {
                    ForEach(1...3, id: \.self) { star in
                        Image(systemName: star <= program.difficultyStars ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(star <= program.difficultyStars ? .yellow : .gray.opacity(0.3))
                    }
                }
            }

            // Quick stats
            HStack(spacing: 16) {
                Label(program.formattedDuration, systemImage: "calendar")
                Label("\(program.estimatedSessionsPerWeek)x/week", systemImage: "repeat")
                Label(program.equipmentSummary, systemImage: program.equipmentIcon)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }

    // MARK: - First Week Content

    @ViewBuilder
    private var firstWeekContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "1.square.fill")
                    .font(.title3)
                    .foregroundColor(.modusCyan)
                Text("Week 1 Schedule")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)
            }

            if viewModel.isLoadingPreview {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Loading week 1 schedule...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 30)
            } else if let days = viewModel.previewWeek, !days.isEmpty {
                VStack(spacing: 10) {
                    ForEach(days, id: \.dayOfWeek) { day in
                        PreviewDayRow(day: day)
                    }
                }

                // Encouragement text
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.modusCyan)
                    Text("This is what your first week looks like. Enroll to get started with the full \(program.formattedDuration) program.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.modusLightTeal)
                .cornerRadius(CornerRadius.md)
            } else {
                // No schedule data available
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.modusCyan.opacity(0.5))

                    Text("Week 1 Preview Not Available")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Enroll in this program to see the full workout schedule. Your therapist may customize the workouts for your specific needs.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            }
        }
    }
}

// MARK: - Preview Day Row

private struct PreviewDayRow: View {
    let day: ProgramScheduleDay

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Day header
            HStack {
                Text(day.dayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.modusDeepTeal)

                Spacer()

                Text("\(day.workouts.count) workout\(day.workouts.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Workouts for this day
            ForEach(day.workouts, id: \.assignmentId) { workout in
                HStack(spacing: 10) {
                    // Category icon
                    Image(systemName: workoutCategoryIcon(workout.category))
                        .font(.caption)
                        .foregroundColor(.modusCyan)
                        .frame(width: 28, height: 28)
                        .background(Color.modusCyan.opacity(0.12))
                        .cornerRadius(CornerRadius.xs)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(workout.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)

                        HStack(spacing: 8) {
                            if let duration = workout.durationMinutes {
                                Text("\(duration) min")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            if let difficulty = workout.difficulty {
                                Text(difficulty.capitalized)
                                    .font(.caption2)
                                    .foregroundColor(difficultyColor(difficulty))
                            }
                        }
                    }

                    Spacer()
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    private func workoutCategoryIcon(_ category: String?) -> String {
        switch category?.lowercased() {
        case "strength": return "dumbbell.fill"
        case "cardio": return "heart.fill"
        case "mobility": return "figure.flexibility"
        case "recovery": return "bed.double.fill"
        default: return "figure.run"
        }
    }

    private func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty.lowercased() {
        case "beginner": return .green
        case "intermediate": return .orange
        case "advanced": return .red
        default: return .gray
        }
    }
}

// MARK: - Program Preview Sheet (Legacy - kept for backward compatibility)

struct ProgramPreviewSheet: View {
    let program: ProgramLibrary
    let onEnroll: () -> Void
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header section
                    headerSection

                    // Description
                    if let description = program.description, !description.isEmpty {
                        descriptionSection(description)
                    }

                    // Stats section
                    statsSection

                    // Equipment section
                    if !program.equipment.isEmpty {
                        equipmentSection
                    }

                    // Tags section
                    if !program.tagsList.isEmpty {
                        tagsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Program Details")
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
                enrollButton
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(program.title)
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 8) {
                ProgramCategoryBadge(category: program.category)
                ProgramDifficultyBadge(difficulty: program.difficultyLevel)

                if program.featured {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                        Text("Featured")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.15))
                    .cornerRadius(CornerRadius.sm)
                }
            }

            if let author = program.author {
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.caption)
                    Text("By \(author)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Description Section

    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About This Program")
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
                value: program.formattedDuration,
                label: "Duration",
                icon: "calendar",
                color: .blue
            )

            statCard(
                value: program.difficultyLevel.capitalized,
                label: "Difficulty",
                icon: "chart.bar.fill",
                color: program.difficultyColor
            )

            statCard(
                value: program.category.capitalized,
                label: "Category",
                icon: program.categoryIcon,
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
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Equipment Section

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Equipment Required")
                .font(.headline)

            ProgramFlowLayout(spacing: 8) {
                ForEach(program.equipment, id: \.self) { equipment in
                    Text(equipment)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(CornerRadius.sm)
                }
            }
        }
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.headline)

            ProgramFlowLayout(spacing: 8) {
                ForEach(program.tagsList, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(CornerRadius.sm)
                }
            }
        }
    }

    // MARK: - Enroll Button

    private var enrollButton: some View {
        VStack(spacing: 0) {
            Divider()

            Button(action: onEnroll) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .accessibilityHidden(true)
                    Text("Enroll in Program")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(CornerRadius.md)
            }
            .accessibilityLabel("Enroll in \(program.title)")
            .accessibilityHint("Starts this program and adds workouts to your schedule")
            .padding()
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Flow Layout (for tags and equipment)

private struct ProgramFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )

        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Legacy Card (kept for backward compatibility)

struct ProgramLibraryCard: View {
    let program: ProgramLibrary
    var onDuplicate: (() -> Void)? = nil

    var body: some View {
        EnhancedProgramLibraryCard(program: program, onDuplicate: onDuplicate)
    }
}

// MARK: - Preview

#Preview {
    ProgramLibraryBrowserView()
}
