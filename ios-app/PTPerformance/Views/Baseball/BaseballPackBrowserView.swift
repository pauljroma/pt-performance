//
//  BaseballPackBrowserView.swift
//  PTPerformance
//
//  Content browser for the Baseball Pack - displays programs organized by
//  category, position, and season with filtering capabilities.
//

import SwiftUI

// MARK: - Baseball Program Categories

enum BaseballCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case weightedBall = "Weighted Ball"
    case armCare = "Arm Care"
    case velocity = "Velocity"
    case conditioning = "Conditioning"
    case recovery = "Recovery"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .weightedBall: return "scalemass.fill"
        case .armCare: return "bandage.fill"
        case .velocity: return "gauge.with.needle.fill"
        case .conditioning: return "figure.run"
        case .recovery: return "bed.double.fill"
        }
    }

    var color: Color {
        switch self {
        case .all: return .gray
        case .weightedBall: return .orange
        case .armCare: return .green
        case .velocity: return .red
        case .conditioning: return .blue
        case .recovery: return .teal
        }
    }
}

// MARK: - Baseball Position

enum BaseballPosition: String, CaseIterable, Identifiable {
    case all = "All Positions"
    case pitcher = "Pitcher"
    case catcher = "Catcher"
    case infielder = "Infielder"
    case outfielder = "Outfielder"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "person.3.fill"
        case .pitcher: return "figure.baseball"
        case .catcher: return "figure.american.football"
        case .infielder: return "figure.run"
        case .outfielder: return "figure.walk"
        }
    }
}

// MARK: - Baseball Season

enum BaseballSeason: String, CaseIterable, Identifiable {
    case all = "All Seasons"
    case offSeason = "Off-Season"
    case preSeason = "Pre-Season"
    case inSeason = "In-Season"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "calendar"
        case .offSeason: return "snowflake"
        case .preSeason: return "sun.max.fill"
        case .inSeason: return "sportscourt.fill"
        }
    }

    var color: Color {
        switch self {
        case .all: return .gray
        case .offSeason: return .blue
        case .preSeason: return .orange
        case .inSeason: return .green
        }
    }
}

// MARK: - BaseballProgram UI Extensions

extension BaseballProgram {
    /// Map category string to UI enum
    var categoryEnum: BaseballCategory {
        // Map from service category string to UI enum
        switch category.lowercased() {
        case "weighted_ball", "weighted ball": return .weightedBall
        case "arm_care", "arm care": return .armCare
        case "velocity": return .velocity
        case "conditioning": return .conditioning
        case "recovery": return .recovery
        default:
            // Check tags for category
            for tag in tagsList {
                switch tag.lowercased() {
                case "weighted_ball", "weighted ball": return .weightedBall
                case "arm_care", "arm care": return .armCare
                case "velocity": return .velocity
                case "conditioning": return .conditioning
                case "recovery": return .recovery
                default: continue
                }
            }
            return .all
        }
    }

    /// Map position from tags to UI enum
    var positionUIEnum: BaseballPosition {
        for tag in tagsList {
            switch tag.lowercased() {
            case "pitcher": return .pitcher
            case "catcher": return .catcher
            case "infielder": return .infielder
            case "outfielder": return .outfielder
            default: continue
            }
        }
        return .all
    }

    /// Map season from tags to UI enum
    var seasonUIEnum: BaseballSeason {
        for tag in tagsList {
            switch tag.lowercased() {
            case "off_season", "off-season", "offseason": return .offSeason
            case "pre_season", "pre-season", "preseason": return .preSeason
            case "in_season", "in-season", "inseason": return .inSeason
            default: continue
            }
        }
        return .all
    }

    /// Safe description access
    var safeDescription: String {
        description ?? "No description available"
    }
}

// MARK: - View Model

@MainActor
class BaseballPackBrowserViewModel: ObservableObject {
    @Published var programs: [BaseballProgram] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    @Published var searchText: String = ""
    @Published var selectedCategory: BaseballCategory = .all
    @Published var selectedPosition: BaseballPosition = .all
    @Published var selectedSeason: BaseballSeason = .all

    private let baseballPackService = BaseballPackService.shared

    var filteredPrograms: [BaseballProgram] {
        programs.filter { program in
            // Category filter - use computed property to map String to enum
            let matchesCategory = selectedCategory == .all || program.categoryEnum == selectedCategory

            // Position filter - use tags-based computed property
            let matchesPosition = selectedPosition == .all || program.positionUIEnum == selectedPosition

            // Season filter - use tags-based computed property
            let matchesSeason = selectedSeason == .all || program.seasonUIEnum == selectedSeason

            // Search filter - handle optional description
            let matchesSearch = searchText.isEmpty ||
                program.title.localizedCaseInsensitiveContains(searchText) ||
                program.safeDescription.localizedCaseInsensitiveContains(searchText)

            return matchesCategory && matchesPosition && matchesSeason && matchesSearch
        }
    }

    var hasActiveFilters: Bool {
        selectedCategory != .all || selectedPosition != .all || selectedSeason != .all || !searchText.isEmpty
    }

    func clearFilters() {
        selectedCategory = .all
        selectedPosition = .all
        selectedSeason = .all
        searchText = ""
    }

    func loadPrograms() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedPrograms = try await baseballPackService.fetchPrograms()
            programs = fetchedPrograms
        } catch {
            errorMessage = "Failed to load programs: \(error.localizedDescription)"
            // Provide empty array on error
            programs = []
        }

        isLoading = false
    }
}

// MARK: - Main View

struct BaseballPackBrowserView: View {
    @StateObject private var viewModel = BaseballPackBrowserViewModel()
    @State private var selectedProgram: BaseballProgram?

    private let baseballNavy = Color(red: 0.07, green: 0.14, blue: 0.28)

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            searchBar

            // Filter sections
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Category filter
                    categoryMenu

                    // Position filter
                    positionMenu

                    // Season filter
                    seasonMenu

                    // Clear filters button
                    if viewModel.hasActiveFilters {
                        Button {
                            HapticFeedback.selectionChanged()
                            viewModel.clearFilters()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                Text("Clear")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.15))
                            .foregroundColor(.red)
                            .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            // Content
            contentView
        }
        .sheet(item: $selectedProgram) { program in
            BaseballProgramDetailView(program: program)
        }
        .task {
            await viewModel.loadPrograms()
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
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Category Menu

    private var categoryMenu: some View {
        Menu {
            ForEach(BaseballCategory.allCases) { category in
                Button {
                    HapticFeedback.selectionChanged()
                    viewModel.selectedCategory = category
                } label: {
                    Label(category.rawValue, systemImage: category.icon)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: viewModel.selectedCategory.icon)
                    .font(.caption)
                Text(viewModel.selectedCategory.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(viewModel.selectedCategory != .all ? viewModel.selectedCategory.color : Color(.tertiarySystemGroupedBackground))
            .foregroundColor(viewModel.selectedCategory != .all ? .white : .primary)
            .cornerRadius(20)
        }
    }

    // MARK: - Position Menu

    private var positionMenu: some View {
        Menu {
            ForEach(BaseballPosition.allCases) { position in
                Button {
                    HapticFeedback.selectionChanged()
                    viewModel.selectedPosition = position
                } label: {
                    Label(position.rawValue, systemImage: position.icon)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: viewModel.selectedPosition.icon)
                    .font(.caption)
                Text(viewModel.selectedPosition == .all ? "Position" : viewModel.selectedPosition.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(viewModel.selectedPosition != .all ? baseballNavy : Color(.tertiarySystemGroupedBackground))
            .foregroundColor(viewModel.selectedPosition != .all ? .white : .primary)
            .cornerRadius(20)
        }
    }

    // MARK: - Season Menu

    private var seasonMenu: some View {
        Menu {
            ForEach(BaseballSeason.allCases) { season in
                Button {
                    HapticFeedback.selectionChanged()
                    viewModel.selectedSeason = season
                } label: {
                    Label(season.rawValue, systemImage: season.icon)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: viewModel.selectedSeason.icon)
                    .font(.caption)
                Text(viewModel.selectedSeason == .all ? "Season" : viewModel.selectedSeason.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(viewModel.selectedSeason != .all ? viewModel.selectedSeason.color : Color(.tertiarySystemGroupedBackground))
            .foregroundColor(viewModel.selectedSeason != .all ? .white : .primary)
            .cornerRadius(20)
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            loadingView
        } else if viewModel.filteredPrograms.isEmpty {
            emptyStateView
        } else {
            programsGrid
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
            Image(systemName: viewModel.hasActiveFilters ? "magnifyingglass" : "baseball.fill")
                .font(.system(size: 56))
                .foregroundColor(viewModel.hasActiveFilters ? .secondary : baseballNavy.opacity(0.6))

            Text(viewModel.hasActiveFilters ? "No Matching Programs" : "Explore Baseball Programs")
                .font(.headline)

            Text(viewModel.hasActiveFilters
                 ? "No programs match your current filters. Try adjusting your search criteria."
                 : "Browse our library of baseball-specific training programs designed for athletes at every level.")
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

    // MARK: - Programs Grid

    private var programsGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.filteredPrograms) { program in
                    BaseballProgramCard(program: program)
                        .onTapGesture {
                            HapticFeedback.light()
                            selectedProgram = program
                        }
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.loadPrograms()
        }
    }
}

// MARK: - Baseball Program Card

struct BaseballProgramCard: View {
    let program: BaseballProgram

    private let baseballNavy = Color(red: 0.07, green: 0.14, blue: 0.28)
    private let baseballRed = Color(red: 0.80, green: 0.16, blue: 0.22)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover image placeholder
            ZStack {
                LinearGradient(
                    colors: [baseballNavy.opacity(0.8), baseballNavy],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Image(systemName: program.categoryEnum.icon)
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.3))

                // Featured badge
                if program.featured {
                    VStack {
                        HStack {
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                Text("Featured")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(baseballRed)
                            .cornerRadius(4)
                            .padding(8)
                        }
                        Spacer()
                    }
                }
            }
            .frame(height: 100)
            .clipped()

            VStack(alignment: .leading, spacing: 8) {
                // Category and position badges
                HStack(spacing: 6) {
                    BaseballCategoryBadge(category: program.categoryEnum)

                    if program.positionUIEnum != .all {
                        Text(program.positionUIEnum.rawValue)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(4)
                    }
                }

                // Title
                Text(program.title)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Description
                Text(program.safeDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                Spacer(minLength: 4)

                // Bottom row
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

                    // Difficulty
                    Text(program.difficultyLevel.capitalized)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(program.difficultyColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(program.difficultyColor.opacity(0.15))
                        .cornerRadius(6)
                }
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, minHeight: 240, alignment: .topLeading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Baseball Category Badge

private struct BaseballCategoryBadge: View {
    let category: BaseballCategory

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.caption2)

            Text(category.rawValue)
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .foregroundColor(category.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(category.color.opacity(0.15))
        .cornerRadius(6)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BaseballPackBrowserView()
            .navigationTitle("Baseball Pack")
    }
}
