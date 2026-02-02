//
//  ProgramLibraryBrowserView.swift
//  PTPerformance
//
//  Browse and discover programs from the program library
//
//  BUILD 320: Baseball Pack Integration
//  Added baseball category with premium gating for baseball programs
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

    // MARK: - Constants

    private let categories = ["All", "Annuals", "Strength", "Mobility", "Conditioning", "Baseball"]
    private let difficulties = ["All", "Beginner", "Intermediate", "Advanced"]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar

                // Category filter chips
                categoryFilters

                // Difficulty filter chips
                difficultyFilters

                // Content
                contentView
            }
            .navigationTitle("Programs")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedProgram) { program in
                ProgramDetailSheet(program: program)
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
            .task {
                await viewModel.loadAllData()
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search programs...", text: $viewModel.searchText)
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

    // MARK: - Difficulty Filters

    private var difficultyFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
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
            .padding(.bottom, 8)
        }
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
                ForEach(viewModel.cachedFilteredPrograms) { program in
                    ProgramLibraryCard(program: program)
                        .onTapGesture {
                            selectedProgram = program
                        }
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.loadAllData()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading programs...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: viewModel.hasActiveFilters ? "magnifyingglass" : "figure.strengthtraining.traditional")
                .font(.system(size: 56))
                .foregroundColor(viewModel.hasActiveFilters ? .secondary : .blue.opacity(0.6))

            Text(viewModel.hasActiveFilters ? "No Matching Programs" : "Explore Training Programs")
                .font(.headline)

            Text(viewModel.hasActiveFilters
                 ? "No programs match your current filters. Try adjusting your search criteria or browse all available programs."
                 : "Browse our library of professionally designed training programs for strength, mobility, conditioning, and more. New programs are added regularly.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if viewModel.hasActiveFilters {
                Button {
                    viewModel.clearFilters()
                } label: {
                    Label("Clear All Filters", systemImage: "xmark.circle")
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

                Text("Baseball")
                    .font(.subheadline)
                    .fontWeight(.medium)

                // Premium badge if not owned
                if isPremium {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .orange)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.orange : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
            .overlay(
                // Premium indicator border
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        isPremium && !isSelected ? Color.orange.opacity(0.5) : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
    }
}

// MARK: - Program Library Card

struct ProgramLibraryCard: View {
    let program: ProgramLibrary

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover image at top
            ProgramCoverImage(
                url: program.coverImageUrl,
                size: CGSize(width: CGFloat.infinity, height: 100),
                cornerRadius: 0
            )
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .clipped()

            VStack(alignment: .leading, spacing: 8) {
                // Header with category badge and featured star
                HStack {
                    // Category badge
                    ProgramCategoryBadge(category: program.category)

                    Spacer()

                    // Featured star
                    if program.isFeatured {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }

                // Program title
                Text(program.title)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Description preview (2 lines max)
                if let description = program.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 4)

                // Bottom row: duration and difficulty
                HStack(spacing: 8) {
                    // Duration
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(program.formattedDuration)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)

                    Spacer()

                    // Difficulty pill
                    ProgramDifficultyBadge(difficulty: program.difficultyLevel)
                }
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .topLeading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .clipped()
        .adaptiveShadow(Shadow.subtle)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                HapticFeedback.light()
                UIPasteboard.general.string = program.title
            } label: {
                Label("Copy Title", systemImage: "doc.on.doc")
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
        .cornerRadius(6)
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

// MARK: - Program Preview Sheet

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
                    if !program.equipmentRequired.isEmpty {
                        equipmentSection
                    }

                    // Tags section
                    if !program.tags.isEmpty {
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

                if program.isFeatured {
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
                    .cornerRadius(6)
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
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Equipment Section

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Equipment Required")
                .font(.headline)

            ProgramFlowLayout(spacing: 8) {
                ForEach(program.equipmentRequired, id: \.self) { equipment in
                    Text(equipment)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
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
                ForEach(program.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
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
                    Text("Enroll in Program")
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

// MARK: - Preview

#Preview {
    ProgramLibraryBrowserView()
}
