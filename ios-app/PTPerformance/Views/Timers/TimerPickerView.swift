//
//  TimerPickerView.swift
//  PTPerformance
//
//  Created by BUILD 116 Agent 19 (Timer Picker View)
//  Timer preset picker with search, filtering, and preview
//

import SwiftUI

/// Timer preset picker view
/// Displays categorized timer presets with search and filtering
struct TimerPickerView: View {
    // MARK: - Dependencies

    let patientId: UUID

    // MARK: - ViewModel

    @StateObject private var viewModel: TimerPickerViewModel

    // MARK: - Navigation State

    @State private var showCustomBuilder = false
    @State private var showActiveTimer = false
    @State private var showPresetDetail = false

    // MARK: - UI State

    @State private var selectedPreset: TimerPreset?
    @Environment(\.dismiss) private var dismiss

    // MARK: - Layout Constants

    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    private let iPadGridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    // MARK: - Initialization

    init(patientId: UUID) {
        self.patientId = patientId
        _viewModel = StateObject(wrappedValue: TimerPickerViewModel(patientId: patientId))
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    loadingView
                } else if !viewModel.hasResults {
                    emptyStateView
                } else {
                    contentView
                }
            }
            .navigationTitle("Timer Presets")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                toolbarContent
            }
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search timers..."
            )
            .task {
                await viewModel.loadPresets()
            }
            .refreshable {
                HapticFeedback.light()
                await viewModel.refresh()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.dismissError()
                }
            } message: {
                Text(viewModel.errorMessage)
            }
            .sheet(isPresented: $showCustomBuilder) {
                customBuilderSheet
            }
            .sheet(isPresented: $showPresetDetail) {
                presetDetailSheet
            }
            .fullScreenCover(isPresented: $showActiveTimer) {
                activeTimerView
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Category Filter
                categoryFilterView

                // Results Count
                if viewModel.isSearching {
                    resultsCountView
                }

                // Preset Grid
                presetGridView

                // Create Custom Button
                createCustomButton

                // Selected Preset Preview
                if selectedPreset != nil {
                    selectedPresetPreview
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 100) // Space for floating button
        }
        .overlay(alignment: .bottom) {
            if selectedPreset != nil {
                startTimerButton
            }
        }
    }

    // MARK: - Category Filter

    private var categoryFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All category
                CategoryChip(
                    category: nil,
                    isSelected: viewModel.selectedCategory == nil,
                    count: viewModel.allPresets.count
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.clearCategoryFilter()
                    }
                }

                // Individual categories
                ForEach(TimerCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        category: category,
                        isSelected: viewModel.selectedCategory == category,
                        count: viewModel.categoryCounts[category] ?? 0
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.toggleCategory(category)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Results Count

    private var resultsCountView: some View {
        HStack {
            Text("\(viewModel.presetCount) result\(viewModel.presetCount == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            if viewModel.isSearching {
                Button {
                    withAnimation {
                        viewModel.clearSearch()
                    }
                } label: {
                    Label("Clear", systemImage: "xmark.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Preset Grid

    private var presetGridView: some View {
        LazyVGrid(columns: isIPad ? iPadGridColumns : gridColumns, spacing: 16) {
            ForEach(viewModel.filteredPresets) { preset in
                PresetCard(
                    preset: preset,
                    isSelected: selectedPreset?.id == preset.id
                ) {
                    handlePresetTap(preset)
                } onDoubleTap: {
                    handlePresetDoubleTap(preset)
                } onLongPress: {
                    handlePresetLongPress(preset)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(presetAccessibilityLabel(for: preset))
                .accessibilityHint("Tap to select, double-tap to start immediately")
                .accessibilityAddTraits(selectedPreset?.id == preset.id ? [.isSelected] : [])
            }
        }
    }

    // MARK: - Create Custom Button

    private var createCustomButton: some View {
        Button {
            showCustomBuilder = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Create Custom Timer")
                        .font(.headline)

                    Text("Build your own interval configuration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Create Custom Timer")
        .accessibilityHint("Opens custom timer builder")
    }

    // MARK: - Selected Preset Preview

    private var selectedPresetPreview: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Selected Timer")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedPreset = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Clear selection")
            }

            if let preset = selectedPreset {
                PresetPreview(preset: preset) {
                    showPresetDetail = true
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Start Timer Button

    private var startTimerButton: some View {
        Button {
            handleStartTimer()
        } label: {
            HStack {
                Image(systemName: "play.fill")
                    .font(.title3)

                Text("Start Timer")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
            .adaptiveShadow(Shadow.prominent)
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
        .transition(.move(edge: .bottom))
        .accessibilityLabel("Start Timer")
        .accessibilityHint("Starts the selected timer preset")
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading timer presets...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        Group {
            if viewModel.isSearching {
                EmptyStateView(
                    title: "No Timers Found",
                    message: "No timer presets match your search criteria. Try adjusting your search term or clearing filters.",
                    icon: "magnifyingglass",
                    iconColor: .secondary,
                    action: EmptyStateView.EmptyStateAction(
                        title: "Clear Filters",
                        icon: "xmark.circle",
                        action: {
                            withAnimation {
                                viewModel.clearSearch()
                                viewModel.clearCategoryFilter()
                            }
                        }
                    )
                )
            } else {
                EmptyStateView(
                    title: "No Timer Presets",
                    message: "Create custom timers for rest intervals, HIIT workouts, or stretching routines to enhance your training sessions.",
                    icon: "timer",
                    iconColor: .orange,
                    action: EmptyStateView.EmptyStateAction(
                        title: "Create Timer",
                        icon: "plus.circle.fill",
                        action: { showCustomBuilder = true }
                    )
                )
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button {
                    viewModel.sortByName()
                } label: {
                    Label("Sort by Name", systemImage: "textformat")
                }

                Button {
                    viewModel.sortByDuration()
                } label: {
                    Label("Sort by Duration", systemImage: "clock")
                }

                Button {
                    viewModel.sortByDifficulty()
                } label: {
                    Label("Sort by Difficulty", systemImage: "chart.bar")
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down.circle")
            }
            .accessibilityLabel("Sort options")
        }

        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .accessibilityLabel("Close")
            .accessibilityHint("Returns to the previous screen")
        }
    }

    // MARK: - Sheets

    // BUILD 280: Use actual CustomTimerBuilderView instead of placeholder
    private var customBuilderSheet: some View {
        CustomTimerBuilderView(patientId: patientId) { template in
            // Timer was created - close the sheet and optionally start the timer
            showCustomBuilder = false
            // Refresh presets to show the new custom timer
            Task {
                await viewModel.refresh()
            }
        }
    }

    private var presetDetailSheet: some View {
        Group {
            if let preset = selectedPreset {
                NavigationView {
                    PresetDetailView(preset: preset)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showPresetDetail = false
                                }
                            }
                        }
                }
            }
        }
    }

    private var activeTimerView: some View {
        Group {
            if let preset = selectedPreset {
                ActiveTimerView(
                    template: preset.toIntervalTemplate(createdBy: patientId),
                    patientId: patientId
                )
            }
        }
    }

    // MARK: - Actions

    private func handlePresetTap(_ preset: TimerPreset) {
        withAnimation(.spring(response: 0.3)) {
            if selectedPreset?.id == preset.id {
                selectedPreset = nil
            } else {
                selectedPreset = preset
                viewModel.selectPreset(preset)
            }
        }

        // Haptic feedback
        HapticFeedback.light()
    }

    private func handlePresetDoubleTap(_ preset: TimerPreset) {
        selectedPreset = preset
        viewModel.selectPreset(preset)
        handleStartTimer()

        // Haptic feedback
        HapticFeedback.medium()
    }

    private func handlePresetLongPress(_ preset: TimerPreset) {
        selectedPreset = preset
        viewModel.selectPreset(preset)
        showPresetDetail = true

        // Haptic feedback
        HapticFeedback.heavy()
    }

    private func handleStartTimer() {
        guard let preset = selectedPreset else { return }

        // Haptic feedback for starting timer
        HapticFeedback.medium()

        Task {
            await viewModel.startTimer(with: preset)
            showActiveTimer = true
        }
    }

    // MARK: - Helpers

    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private func presetAccessibilityLabel(for preset: TimerPreset) -> String {
        let name = preset.name
        let type = preset.templateJson.type.displayName
        let duration = preset.readableDuration
        let difficulty = preset.templateJson.difficulty?.displayName ?? "Unknown"
        let work = "\(preset.templateJson.workSeconds) seconds work"
        let rest = "\(preset.templateJson.restSeconds) seconds rest"
        let rounds = "\(preset.templateJson.rounds) rounds"

        return "\(name), \(type) timer, \(duration), \(difficulty) difficulty, \(work), \(rest), \(rounds)"
    }
}

// MARK: - Category Chip

private struct CategoryChip: View {
    let category: TimerCategory?
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let category = category {
                    Image(systemName: category.iconName)
                        .font(.caption)
                } else {
                    Image(systemName: "square.grid.2x2")
                        .font(.caption)
                }

                Text(category?.displayName ?? "All")
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                Text("(\(count))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(category?.displayName ?? "All") category, \(count) timers")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Preset Card

private struct PresetCard: View {
    let preset: TimerPreset
    let isSelected: Bool
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and type
            HStack {
                Image(systemName: preset.templateJson.type.iconName)
                    .font(.title2)
                    .foregroundColor(typeColor)

                Spacer()

                Image(systemName: preset.templateJson.difficulty?.iconName ?? "figure.walk")
                    .font(.caption)
                    .foregroundColor(difficultyColor)
            }

            // Preset name
            Text(preset.name)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Timer info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("\(preset.templateJson.workSeconds)s work / \(preset.templateJson.restSeconds)s rest")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "repeat")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("\(preset.templateJson.rounds) rounds")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text(preset.readableDuration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Difficulty badge
            HStack {
                Text(preset.templateJson.difficulty?.displayName ?? "Easy")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(difficultyColor.opacity(0.2))
                    .foregroundColor(difficultyColor)
                    .cornerRadius(4)

                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
        )
        .shadow(color: isSelected ? Color.accentColor.opacity(0.3) : Color.black.opacity(0.05), radius: isSelected ? 8 : 4)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress()
        }
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                onDoubleTap()
            }
        )
    }

    private var typeColor: Color {
        switch preset.templateJson.type {
        case .tabata:
            return .orange
        case .emom:
            return .blue
        case .amrap:
            return .red
        case .intervals:
            return .green
        case .custom:
            return .purple
        }
    }

    private var difficultyColor: Color {
        guard let difficulty = preset.templateJson.difficulty else {
            return .gray
        }
        switch difficulty.color {
        case "green":
            return .green
        case "yellow":
            return .yellow
        case "orange":
            return .orange
        case "red":
            return .red
        default:
            return .gray
        }
    }
}

// MARK: - Preset Preview

private struct PresetPreview: View {
    let preset: TimerPreset
    let onDetailTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: preset.templateJson.type.iconName)
                .font(.title)
                .foregroundColor(.accentColor)
                .frame(width: 44, height: 44)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(8)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(preset.name)
                    .font(.headline)

                Text("\(preset.templateJson.type.displayName) • \(preset.readableDuration)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Detail button
            Button(action: onDetailTap) {
                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundColor(.accentColor)
            }
            .accessibilityLabel("View details")
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preset Detail View

private struct PresetDetailView: View {
    let preset: TimerPreset

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: preset.templateJson.type.iconName)
                            .font(.largeTitle)
                            .foregroundColor(.accentColor)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(preset.templateJson.type.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(preset.readableDuration)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }

                    Text(preset.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    if let description = preset.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Timer Configuration") {
                LabeledContent("Work Duration", value: "\(preset.templateJson.workSeconds) seconds")
                LabeledContent("Rest Duration", value: "\(preset.templateJson.restSeconds) seconds")
                LabeledContent("Rounds", value: "\(preset.templateJson.rounds)")
                LabeledContent("Cycles", value: "\(preset.templateJson.cycles)")
            }

            Section("Details") {
                LabeledContent("Difficulty", value: preset.templateJson.difficulty?.displayName ?? "Not specified")
                LabeledContent("Equipment", value: preset.templateJson.equipment ?? "None")
                LabeledContent("Category", value: preset.category.displayName)
            }
        }
        .navigationTitle("Preset Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Removed duplicate iconName extensions
// iconName properties are already defined in TimerCategory.swift and TimerType.swift

// MARK: - Previews

#Preview("Default") {
    TimerPickerView(patientId: UUID())
}

#Preview("With Selection") {
    let view = TimerPickerView(patientId: UUID())
    return view
}

#Preview("iPad") {
    TimerPickerView(patientId: UUID())
}
