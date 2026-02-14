// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  ExerciseLibraryView.swift
//  PTPerformance
//
//  ACP-1032: Exercise Search & Discovery
//  Enhanced exercise library with muscle group browser, equipment filters,
//  difficulty levels, recently viewed, similar exercises, and search.
//

import SwiftUI

// MARK: - Exercise Library View

struct ExerciseLibraryView: View {
    @StateObject private var viewModel = ExerciseLibraryViewModel()
    @State private var showExerciseDetail = false
    @State private var showFilters = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        loadingView
                    } else if let error = viewModel.errorMessage {
                        errorView(error)
                    } else {
                        libraryContent
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .searchable(text: $viewModel.searchText, prompt: "Search exercises...")
            .navigationTitle("Exercise Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    filterButton
                }
            }
            .sheet(isPresented: $showExerciseDetail) {
                if let exercise = viewModel.selectedExercise {
                    ExerciseLibraryDetailSheet(
                        exercise: exercise,
                        similarExercises: viewModel.similarExercises,
                        onSelectExercise: { selected in
                            viewModel.selectedExercise = selected
                            viewModel.recordExerciseView(selected)
                        }
                    )
                }
            }
        }
        .task {
            await viewModel.loadExercises()
        }
    }

    // MARK: - Filter Button

    private var filterButton: some View {
        Button {
            showFilters.toggle()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    .foregroundColor(.modusCyan)
                if viewModel.hasActiveFilters {
                    Text("\(viewModel.activeFilterCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 18, height: 18)
                        .background(Color.modusCyan)
                        .clipShape(Circle())
                }
            }
        }
        .sheet(isPresented: $showFilters) {
            ExerciseFilterSheet(viewModel: viewModel)
        }
    }

    // MARK: - Library Content

    private var libraryContent: some View {
        LazyVStack(spacing: Spacing.md) {
            // Recently Viewed Section
            if !viewModel.recentlyViewed.isEmpty && viewModel.searchText.isEmpty && !viewModel.hasActiveFilters {
                recentlyViewedSection
            }

            // Muscle Group Visual Browser (show when no search or filters active)
            if viewModel.searchText.isEmpty && viewModel.selectedExerciseMuscleGroup == nil {
                muscleGroupBrowserSection
            }

            // Active Filters Display
            if viewModel.hasActiveFilters {
                activeFiltersBar
            }

            // Equipment Filter Chips
            equipmentFilterChips

            // Difficulty Filter
            difficultyFilterRow

            // Results Section
            if !viewModel.searchText.isEmpty || viewModel.hasActiveFilters {
                searchResultsSection
            } else {
                // Popular Exercises (when no search)
                if !viewModel.popularExercises.isEmpty {
                    popularExercisesSection
                }

                // All Exercises
                allExercisesSection
            }
        }
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading exercise library...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(DesignTokens.statusWarning)
            Text("Unable to Load Exercises")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again") {
                Task { await viewModel.loadExercises() }
            }
            .buttonStyle(.bordered)
            .tint(.modusCyan)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Recently Viewed Section

    private var recentlyViewedSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.modusCyan)
                Text("Recently Viewed")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(viewModel.recentlyViewed) { exercise in
                        RecentExerciseCard(exercise: exercise) {
                            viewModel.selectedExercise = exercise
                            viewModel.recordExerciseView(exercise)
                            showExerciseDetail = true
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    // MARK: - Muscle Group Browser

    private var muscleGroupBrowserSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "figure.arms.open")
                    .foregroundColor(.modusDeepTeal)
                Text("Browse by Muscle Group")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Spacing.sm),
                GridItem(.flexible(), spacing: Spacing.sm),
                GridItem(.flexible(), spacing: Spacing.sm),
                GridItem(.flexible(), spacing: Spacing.sm),
                GridItem(.flexible(), spacing: Spacing.sm)
            ], spacing: Spacing.sm) {
                ForEach(ExerciseMuscleGroup.allCases) { group in
                    ExerciseMuscleGroupCell(
                        group: group,
                        isSelected: viewModel.selectedExerciseMuscleGroup == group,
                        exerciseCount: viewModel.exerciseCountsByGroup[group] ?? 0
                    ) {
                        withAnimation(.easeInOut(duration: AnimationDuration.standard)) {
                            if viewModel.selectedExerciseMuscleGroup == group {
                                viewModel.selectedExerciseMuscleGroup = nil
                            } else {
                                viewModel.selectedExerciseMuscleGroup = group
                            }
                        }
                        HapticFeedback.selectionChanged()
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .padding(.vertical, Spacing.xs)
    }

    // MARK: - Active Filters Bar

    private var activeFiltersBar: some View {
        HStack {
            Image(systemName: "line.3.horizontal.decrease")
                .foregroundColor(.modusCyan)
                .font(.caption)

            Text("\(viewModel.filteredExercises.count) results")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Button("Clear All") {
                withAnimation {
                    viewModel.clearFilters()
                }
                HapticFeedback.light()
            }
            .font(.subheadline)
            .foregroundColor(.modusCyan)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
    }

    // MARK: - Equipment Filter Chips

    private var equipmentFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(EquipmentType.allCases) { equipment in
                    ExerciseEquipmentChip(
                        equipment: equipment,
                        isSelected: viewModel.selectedEquipment.contains(equipment)
                    ) {
                        withAnimation(.easeInOut(duration: AnimationDuration.quick)) {
                            viewModel.toggleEquipment(equipment)
                        }
                        HapticFeedback.selectionChanged()
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .padding(.vertical, Spacing.xxs)
    }

    // MARK: - Difficulty Filter Row

    private var difficultyFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(ExerciseDifficulty.allCases) { level in
                    DifficultyChip(
                        difficulty: level,
                        isSelected: viewModel.selectedDifficulty == level
                    ) {
                        withAnimation(.easeInOut(duration: AnimationDuration.quick)) {
                            if viewModel.selectedDifficulty == level {
                                viewModel.selectedDifficulty = nil
                            } else {
                                viewModel.selectedDifficulty = level
                            }
                        }
                        HapticFeedback.selectionChanged()
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .padding(.vertical, Spacing.xxs)
    }

    // MARK: - Search Results Section

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if viewModel.filteredExercises.isEmpty {
                emptySearchView
            } else {
                exerciseListContent(
                    exercises: viewModel.filteredExercises,
                    header: nil
                )
            }
        }
    }

    // MARK: - Popular Exercises Section

    private var popularExercisesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(DesignTokens.statusWarning)
                Text("Popular Exercises")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .accessibilityAddTraits(.isHeader)

            ForEach(viewModel.popularExercises) { exercise in
                ExerciseLibraryRow(exercise: exercise) {
                    viewModel.selectedExercise = exercise
                    viewModel.recordExerciseView(exercise)
                    showExerciseDetail = true
                }
                .padding(.horizontal, Spacing.md)
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    // MARK: - All Exercises Section

    private var allExercisesSection: some View {
        exerciseListContent(
            exercises: Array(viewModel.allExercises.prefix(50)),
            header: "All Exercises"
        )
    }

    // MARK: - Exercise List Content

    private func exerciseListContent(exercises: [LibraryExerciseItem], header: String?) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let header = header {
                HStack {
                    Image(systemName: "list.bullet")
                        .foregroundColor(.modusCyan)
                    Text(header)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(exercises.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, Spacing.md)
                .accessibilityAddTraits(.isHeader)
            }

            ForEach(exercises) { exercise in
                ExerciseLibraryRow(exercise: exercise) {
                    viewModel.selectedExercise = exercise
                    viewModel.recordExerciseView(exercise)
                    showExerciseDetail = true
                }
                .padding(.horizontal, Spacing.md)
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    // MARK: - Empty Search View

    private var emptySearchView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No exercises found")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if viewModel.hasActiveFilters {
                Button("Clear Filters") {
                    withAnimation {
                        viewModel.clearFilters()
                    }
                }
                .buttonStyle(.bordered)
                .tint(.modusCyan)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

}

// MARK: - Muscle Group Cell

struct ExerciseMuscleGroupCell: View {
    let group: ExerciseMuscleGroup
    let isSelected: Bool
    let exerciseCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: group.iconName)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .modusDeepTeal)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.modusCyan : Color.modusLightTeal)
                    )

                Text(group.displayName)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(isSelected ? .modusCyan : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(group.displayName), \(exerciseCount) exercises")
    }
}

// MARK: - Equipment Chip

private struct ExerciseEquipmentChip: View {
    let equipment: EquipmentType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: equipment.iconName)
                    .font(.caption2)
                Text(equipment.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 7)
            .background(
                isSelected
                    ? Color.modusCyan
                    : Color(.secondarySystemGroupedBackground)
            )
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.modusCyan : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(equipment.displayName) equipment filter")
    }
}

// MARK: - Difficulty Chip

struct DifficultyChip: View {
    let difficulty: ExerciseDifficulty
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: difficulty.iconName)
                    .font(.caption2)
                Text(difficulty.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 7)
            .background(
                isSelected
                    ? difficulty.color
                    : Color(.secondarySystemGroupedBackground)
            )
            .foregroundColor(isSelected ? .white : difficulty.color)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : difficulty.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(difficulty.rawValue) difficulty filter")
    }
}

// MARK: - Recent Exercise Card

struct RecentExerciseCard: View {
    let exercise: LibraryExerciseItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                // Thumbnail or icon
                ZStack {
                    if let thumbnailUrl = exercise.videoThumbnailUrl, let url = URL(string: thumbnailUrl) {
                        CachedAsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            thumbnailPlaceholder
                        }
                    } else {
                        thumbnailPlaceholder
                    }

                    // Play icon if video available
                    if exercise.hasVideo {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "play.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .shadow(radius: 2)
                                    .padding(Spacing.xxs)
                            }
                        }
                    }
                }
                .frame(width: 120, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))

                Text(exercise.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .frame(width: 120, alignment: .leading)

                // Difficulty indicator
                ExerciseDifficultyBadge(difficulty: exercise.difficulty)
            }
        }
        .buttonStyle(.plain)
    }

    private var thumbnailPlaceholder: some View {
        ZStack {
            Color.modusLightTeal
            Image(systemName: exercise.muscleGroup?.iconName ?? "figure.strengthtraining.traditional")
                .font(.title3)
                .foregroundColor(.modusCyan.opacity(0.6))
        }
    }
}

// MARK: - Difficulty Badge

struct ExerciseDifficultyBadge: View {
    let difficulty: ExerciseDifficulty

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(index < difficultyDotCount ? difficulty.color : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
            Text(difficulty.rawValue)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(difficulty.color)
        }
    }

    private var difficultyDotCount: Int {
        switch difficulty {
        case .beginner: return 1
        case .intermediate: return 2
        case .advanced: return 3
        }
    }
}

// MARK: - Exercise Library Row

struct ExerciseLibraryRow: View {
    let exercise: LibraryExerciseItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.sm) {
                // Thumbnail
                exerciseThumbnail

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        if let category = exercise.category {
                            Text(category.capitalized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if let bodyRegion = exercise.bodyRegion {
                            Text("|")
                                .font(.caption2)
                                .foregroundColor(.secondary.opacity(0.5))
                            Text(bodyRegion.capitalized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack(spacing: 8) {
                        // Difficulty
                        ExerciseDifficultyBadge(difficulty: exercise.difficulty)

                        // Equipment badge
                        if let equipment = exercise.equipment {
                            Text(equipment.displayName)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.modusCyan)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.modusCyan.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }

                Spacer()

                // Video indicator
                if exercise.hasVideo {
                    VStack(spacing: 2) {
                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                            .foregroundColor(.modusCyan)

                        if let duration = exercise.videoDurationDisplay {
                            Text(duration)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(Spacing.sm)
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.md)
            .adaptiveShadow(Shadow.subtle)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exercise.name), \(exercise.difficulty.rawValue) difficulty")
    }

    private var exerciseThumbnail: some View {
        ZStack {
            if let thumbnailUrl = exercise.videoThumbnailUrl, let url = URL(string: thumbnailUrl) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    thumbnailPlaceholder
                }
            } else {
                thumbnailPlaceholder
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
    }

    private var thumbnailPlaceholder: some View {
        ZStack {
            Color.modusLightTeal
            Image(systemName: exercise.muscleGroup?.iconName ?? "figure.strengthtraining.traditional")
                .font(.title3)
                .foregroundColor(.modusCyan.opacity(0.5))
        }
    }
}

// MARK: - Filter Sheet

struct ExerciseFilterSheet: View {
    @ObservedObject var viewModel: ExerciseLibraryViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Muscle Groups
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Muscle Group")
                            .font(.headline)
                            .foregroundColor(.modusDeepTeal)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: Spacing.sm) {
                            ForEach(ExerciseMuscleGroup.allCases) { group in
                                Button {
                                    if viewModel.selectedExerciseMuscleGroup == group {
                                        viewModel.selectedExerciseMuscleGroup = nil
                                    } else {
                                        viewModel.selectedExerciseMuscleGroup = group
                                    }
                                    HapticFeedback.selectionChanged()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: group.iconName)
                                            .font(.caption)
                                        Text(group.displayName)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        viewModel.selectedExerciseMuscleGroup == group
                                            ? Color.modusCyan
                                            : Color(.secondarySystemGroupedBackground)
                                    )
                                    .foregroundColor(
                                        viewModel.selectedExerciseMuscleGroup == group
                                            ? .white
                                            : .primary
                                    )
                                    .cornerRadius(CornerRadius.sm)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Divider()

                    // Equipment
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Equipment")
                            .font(.headline)
                            .foregroundColor(.modusDeepTeal)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: Spacing.sm) {
                            ForEach(EquipmentType.allCases) { equip in
                                Button {
                                    viewModel.toggleEquipment(equip)
                                    HapticFeedback.selectionChanged()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: equip.iconName)
                                            .font(.caption)
                                        Text(equip.displayName)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        viewModel.selectedEquipment.contains(equip)
                                            ? Color.modusTealAccent
                                            : Color(.secondarySystemGroupedBackground)
                                    )
                                    .foregroundColor(
                                        viewModel.selectedEquipment.contains(equip)
                                            ? .white
                                            : .primary
                                    )
                                    .cornerRadius(CornerRadius.sm)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Divider()

                    // Difficulty
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Difficulty Level")
                            .font(.headline)
                            .foregroundColor(.modusDeepTeal)

                        HStack(spacing: Spacing.sm) {
                            ForEach(ExerciseDifficulty.allCases) { level in
                                Button {
                                    if viewModel.selectedDifficulty == level {
                                        viewModel.selectedDifficulty = nil
                                    } else {
                                        viewModel.selectedDifficulty = level
                                    }
                                    HapticFeedback.selectionChanged()
                                } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: level.iconName)
                                            .font(.title3)
                                        Text(level.rawValue)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.sm)
                                    .background(
                                        viewModel.selectedDifficulty == level
                                            ? level.color
                                            : Color(.secondarySystemGroupedBackground)
                                    )
                                    .foregroundColor(
                                        viewModel.selectedDifficulty == level
                                            ? .white
                                            : level.color
                                    )
                                    .cornerRadius(CornerRadius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: CornerRadius.md)
                                            .stroke(level.color.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Results count
                    HStack {
                        Spacer()
                        Text("\(viewModel.filteredExercises.count) exercises match")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.top, Spacing.md)
                }
                .padding(Spacing.md)
            }
            .navigationTitle("Filter Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear") {
                        viewModel.clearFilters()
                    }
                    .foregroundColor(.modusCyan)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.modusCyan)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Exercise Library Detail Sheet

struct ExerciseLibraryDetailSheet: View {
    let exercise: LibraryExerciseItem
    let similarExercises: [LibraryExerciseItem]
    var onSelectExercise: ((LibraryExerciseItem) -> Void)?

    @StateObject private var infoViewModel = ExerciseInfoViewModel()
    @State private var hdVideos: [ExerciseVideo] = []
    @State private var isLoadingVideos = false
    @State private var showFullScreenPlayer = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Video Section
                    videoSection

                    // Exercise Info
                    exerciseInfoSection

                    // Technique Cues
                    if let cues = infoViewModel.template?.techniqueCues {
                        techniqueCuesSection(cues)
                    }

                    // Safety Notes
                    if let notes = infoViewModel.template?.safetyNotes, !notes.isEmpty {
                        safetySection(notes)
                    }

                    // Similar Exercises
                    if !similarExercises.isEmpty {
                        similarExercisesSection
                    }

                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.xs)
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.modusCyan)
                }
            }
        }
        .task {
            await infoViewModel.fetchTemplate(id: exercise.id.uuidString)
            await loadHDVideos()
        }
        .fullScreenCover(isPresented: $showFullScreenPlayer) {
            if !hdVideos.isEmpty {
                ExerciseVideoPlayerView(
                    videos: hdVideos,
                    exerciseName: exercise.name,
                    patientId: nil,
                    onDismiss: { showFullScreenPlayer = false }
                )
            }
        }
    }

    // MARK: - Video Section

    @ViewBuilder
    private var videoSection: some View {
        if !hdVideos.isEmpty {
            if let primaryVideo = hdVideos.first(where: { $0.isPrimary }) ?? hdVideos.first {
                PrimaryVideoCardView(
                    video: primaryVideo,
                    exerciseName: exercise.name
                ) {
                    showFullScreenPlayer = true
                }
            }
        } else if isLoadingVideos {
            VStack(spacing: Spacing.md) {
                ProgressView()
                Text("Loading video...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(height: 180)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        } else if let thumbnailUrl = exercise.videoThumbnailUrl, let url = URL(string: thumbnailUrl) {
            // Show thumbnail with play button
            ZStack {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                } placeholder: {
                    videoPlaceholder
                }

                // Play overlay
                Color.black.opacity(0.3)
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        } else {
            videoPlaceholder
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        }
    }

    private var videoPlaceholder: some View {
        ZStack {
            Color.modusLightTeal

            VStack(spacing: Spacing.sm) {
                Image(systemName: exercise.muscleGroup?.iconName ?? "figure.strengthtraining.traditional")
                    .font(.system(size: 48))
                    .foregroundColor(.modusCyan.opacity(0.4))

                Text("Video Coming Soon")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Exercise Info Section

    private var exerciseInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Badges row
            HStack(spacing: Spacing.xs) {
                // Difficulty
                HStack(spacing: 4) {
                    Image(systemName: exercise.difficulty.iconName)
                        .font(.caption)
                    Text(exercise.difficulty.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(exercise.difficulty.color)
                .cornerRadius(CornerRadius.sm)

                // Category
                if let category = exercise.category {
                    Text(category.capitalized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.modusCyan)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.modusCyan.opacity(0.1))
                        .cornerRadius(CornerRadius.sm)
                }

                // Body Region
                if let bodyRegion = exercise.bodyRegion {
                    Text(bodyRegion.capitalized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.modusDeepTeal)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.modusDeepTeal.opacity(0.1))
                        .cornerRadius(CornerRadius.sm)
                }

                // Equipment
                if let equip = exercise.equipment {
                    HStack(spacing: 4) {
                        Image(systemName: equip.iconName)
                            .font(.caption2)
                        Text(equip.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.modusTealAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.modusTealAccent.opacity(0.1))
                    .cornerRadius(CornerRadius.sm)
                }
            }

            // Muscle group
            if let group = exercise.muscleGroup {
                HStack(spacing: 6) {
                    Image(systemName: group.iconName)
                        .font(.subheadline)
                        .foregroundColor(.modusDeepTeal)
                    Text("Primary: \(group.displayName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, Spacing.xxs)
            }
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Technique Cues Section

    private func techniqueCuesSection(_ cues: TechniqueCues) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("How to Perform")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)

            if !cues.setup.isEmpty {
                cueGroup(title: "Setup", icon: "figure.stand", cues: cues.setup, color: .modusCyan)
            }

            if !cues.execution.isEmpty {
                cueGroup(title: "Execution", icon: "figure.strengthtraining.traditional", cues: cues.execution, color: .modusTealAccent)
            }

            if !cues.breathing.isEmpty {
                cueGroup(title: "Breathing", icon: "lungs.fill", cues: cues.breathing, color: .modusDeepTeal)
            }
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    private func cueGroup(title: String, icon: String, cues: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(cues.enumerated()), id: \.offset) { index, cue in
                    HStack(alignment: .top, spacing: 6) {
                        Text("\(index + 1).")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 18, alignment: .trailing)
                        Text(cue)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(.leading, Spacing.lg)
        }
    }

    // MARK: - Safety Section

    private func safetySection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(DesignTokens.statusWarning)
                Text("Safety Notes")
                    .font(.headline)
                    .foregroundColor(DesignTokens.statusWarning)
            }

            Text(notes)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding(Spacing.md)
        .background(DesignTokens.statusWarning.opacity(0.05))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(DesignTokens.statusWarning.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Similar Exercises Section

    private var similarExercisesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "arrow.triangle.branch")
                    .foregroundColor(.modusTealAccent)
                Text("Similar Exercises")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(similarExercises) { similar in
                        SimilarExerciseCard(exercise: similar) {
                            onSelectExercise?(similar)
                        }
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - HD Video Loading

    private func loadHDVideos() async {
        isLoadingVideos = true
        do {
            hdVideos = try await ExerciseVideoService.shared.fetchVideos(exerciseId: exercise.id)
        } catch {
            // Non-fatal
            DebugLogger.shared.log(
                "Failed to load HD videos for library: \(error.localizedDescription)",
                level: .warning
            )
        }
        isLoadingVideos = false
    }
}

// MARK: - Similar Exercise Card

struct SimilarExerciseCard: View {
    let exercise: LibraryExerciseItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                // Icon
                ZStack {
                    Color.modusLightTeal
                    Image(systemName: exercise.muscleGroup?.iconName ?? "figure.strengthtraining.traditional")
                        .font(.title3)
                        .foregroundColor(.modusCyan.opacity(0.6))
                }
                .frame(width: 110, height: 65)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))

                Text(exercise.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .frame(width: 110, alignment: .leading)

                ExerciseDifficultyBadge(difficulty: exercise.difficulty)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ExerciseLibraryView()
}
