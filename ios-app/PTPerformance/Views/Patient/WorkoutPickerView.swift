//
//  WorkoutPickerView.swift
//  PTPerformance
//
//  BUILD 327: Quick Pick Workout Finder
//  BUILD 352: AI Quick Pick Mode
//  Questionnaire-based workout recommendation UI with AI-powered suggestions
//

import SwiftUI

struct WorkoutPickerView: View {
    @StateObject private var viewModel = WorkoutPickerViewModel()
    @EnvironmentObject var appState: AppState

    // BUILD 328: Use sheet(item:) pattern for reliable first-tap behavior
    @State private var selectedTemplate: SystemWorkoutTemplate?

    // BUILD 352: AI recommendation selection
    @State private var selectedAIRecommendation: AIWorkoutRecommendation?

    // BUILD 328: Workout execution state
    @State private var createdSession: ManualSession?
    @State private var isCreatingSession: Bool = false
    @State private var creationError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    modeToggleSection
                    durationSection
                    categoryTogglesSection
                    findButtonSection
                    resultsSection

                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Quick Pick")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.resetAll()
                    } label: {
                        Text("Reset")
                            .font(.subheadline)
                    }
                }
            }
            .task {
                await viewModel.loadTemplatesIfNeeded()
            }
            // BUILD 352: Handle AI recommendation selection
            .onChange(of: selectedAIRecommendation) { _, recommendation in
                guard let recommendation = recommendation else { return }
                Task {
                    await viewModel.markAIRecommendationSelected(templateId: recommendation.templateId)
                    if let template = await viewModel.getTemplateForAIRecommendation(recommendation) {
                        selectedAIRecommendation = nil
                        selectedTemplate = template
                    }
                }
            }
            .sheet(item: $selectedTemplate) { template in
                WorkoutTemplateDetailSheet(
                    template: template,
                    isCreating: isCreatingSession,
                    onStartWorkout: {
                        startWorkout(from: template)
                    },
                    onDismiss: {
                        selectedTemplate = nil
                    }
                )
            }
            .fullScreenCover(item: $createdSession) { session in
                if let patientId = appState.userId,
                   let patientUUID = UUID(uuidString: patientId) {
                    ManualWorkoutExecutionView(
                        session: session,
                        patientId: patientUUID,
                        onComplete: {
                            createdSession = nil
                            selectedTemplate = nil
                        }
                    )
                }
            }
            .alert("Error", isPresented: Binding(
                get: { creationError != nil },
                set: { if !$0 { creationError = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                if let error = creationError {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Results Section (BUILD 352)

    @ViewBuilder
    private var resultsSection: some View {
        if viewModel.hasSearched {
            VStack(alignment: .leading, spacing: 12) {
                if viewModel.isAIMode {
                    aiResultsContent
                } else {
                    shuffleResultsContent
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var aiResultsContent: some View {
        // AI Context Banner
        if let context = viewModel.aiContext {
            AIContextBanner(context: context, isCached: viewModel.isAICached)
        }

        // AI Overall Reasoning
        if let reasoning = viewModel.aiReasoning {
            Text(reasoning)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.vertical, Spacing.xs)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(CornerRadius.sm)
        }

        HStack {
            Text("AI Recommendations")
                .font(.headline)

            Spacer()

            if !viewModel.aiRecommendations.isEmpty {
                Button {
                    Task {
                        if let patientId = appState.userId,
                           let patientUUID = UUID(uuidString: patientId) {
                            await viewModel.fetchAIRecommendations(patientId: patientUUID)
                        }
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
            }
        }

        if let error = viewModel.aiError {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Button("Try Shuffle Instead") {
                    viewModel.toggleMode()
                }
                .font(.caption)
                .foregroundColor(.orange)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
        } else if viewModel.aiRecommendations.isEmpty && !viewModel.isLoadingAI {
            VStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("No AI recommendations available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Try shuffling for random picks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
        } else {
            ForEach(viewModel.aiRecommendations) { recommendation in
                AIWorkoutRecommendationCard(recommendation: recommendation) {
                    selectedAIRecommendation = recommendation
                }
            }
        }
    }

    @ViewBuilder
    private var shuffleResultsContent: some View {
        HStack {
            Text("Recommendations")
                .font(.headline)

            Spacer()

            if !viewModel.recommendations.isEmpty {
                Button {
                    Task { await viewModel.findWorkouts() }
                } label: {
                    Label("Shuffle", systemImage: "shuffle")
                        .font(.caption)
                }
            }
        }

        if let error = viewModel.errorMessage {
            Text(error)
                .foregroundColor(.red)
                .font(.subheadline)
        } else if viewModel.recommendations.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("No matching workouts found")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Try adjusting your filters")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
        } else {
            ForEach(viewModel.recommendations) { template in
                WorkoutRecommendationCard(template: template) {
                    selectedTemplate = template
                }
            }
        }
    }

    // MARK: - Extracted View Sections (BUILD 352)

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("How long do you have?", systemImage: "clock")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(WorkoutPickerViewModel.DurationOption.allCases) { duration in
                    DurationChip(
                        duration: duration,
                        isSelected: viewModel.selectedDuration == duration
                    ) {
                        viewModel.selectedDuration = duration
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var categoryTogglesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("What do you want to train?", systemImage: "figure.strengthtraining.traditional")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    PresetButton(title: "Upper Body", icon: "figure.arms.open") {
                        viewModel.applyUpperBodyPreset()
                    }
                    PresetButton(title: "Lower Body", icon: "figure.walk") {
                        viewModel.applyLowerBodyPreset()
                    }
                    PresetButton(title: "Full Body", icon: "figure.mixed.cardio") {
                        viewModel.applyFullBodyPreset()
                    }
                    PresetButton(title: "Cardio", icon: "heart.fill") {
                        viewModel.applyCardioPreset()
                    }
                }
            }

            VStack(spacing: 8) {
                CategoryToggle(title: "Push", subtitle: "Chest, shoulders, triceps", icon: "arrow.up.circle.fill", isOn: $viewModel.includePush)
                CategoryToggle(title: "Pull", subtitle: "Back, biceps, rear delts", icon: "arrow.down.circle.fill", isOn: $viewModel.includePull)
                CategoryToggle(title: "Legs", subtitle: "Quads, hamstrings, glutes", icon: "figure.walk.circle.fill", isOn: $viewModel.includeLegs)
                CategoryToggle(title: "Core", subtitle: "Abs, obliques, stability", icon: "circle.circle.fill", isOn: $viewModel.includeCore)
                CategoryToggle(title: "Cardio", subtitle: "HIIT, conditioning, endurance", icon: "heart.circle.fill", isOn: $viewModel.includeCardio)
                CategoryToggle(title: "Mobility", subtitle: "Stretching, flexibility, recovery", icon: "figure.yoga", isOn: $viewModel.includeMobility)
            }
        }
        .padding(.horizontal)
    }

    private var findButtonSection: some View {
        let isLoading = viewModel.isLoading || viewModel.isLoadingAI
        let iconName = viewModel.isAIMode ? "brain.head.profile" : "sparkle.magnifyingglass"
        let buttonText = viewModel.isAIMode ? "Get AI Picks" : "Find Workouts"
        let gradientColors: [Color] = viewModel.isAIMode ? [.purple, .orange] : [.orange, .pink]

        return Button {
            Task {
                if viewModel.isAIMode {
                    if let patientId = appState.userId,
                       let patientUUID = UUID(uuidString: patientId) {
                        await viewModel.fetchAIRecommendations(patientId: patientUUID)
                    }
                } else {
                    await viewModel.findWorkouts()
                }
            }
        } label: {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: iconName)
                    Text(buttonText)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(CornerRadius.lg)
        }
        .disabled(isLoading)
        .padding(.horizontal)
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            let iconName = viewModel.isAIMode ? "brain.head.profile" : "sparkles"
            let gradientColors: [Color] = viewModel.isAIMode ? [.purple, .orange] : [.orange, .pink]

            Image(systemName: iconName)
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Quick Pick")
                .font(.title)
                .fontWeight(.bold)

            let subtitleText = viewModel.isAIMode
                ? "AI-powered recommendations based on your readiness, history, and goals"
                : "Answer a few questions and we'll find the perfect workout for you"

            Text(subtitleText)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top)
    }

    private var modeToggleSection: some View {
        HStack(spacing: 0) {
            ModeToggleButton(
                title: "AI Pick",
                icon: "brain.head.profile",
                isSelected: viewModel.isAIMode
            ) {
                if !viewModel.isAIMode {
                    viewModel.toggleMode()
                }
            }

            ModeToggleButton(
                title: "Shuffle",
                icon: "shuffle",
                isSelected: !viewModel.isAIMode
            ) {
                if viewModel.isAIMode {
                    viewModel.toggleMode()
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .padding(.horizontal)
    }

    // MARK: - Workout Creation

    private func startWorkout(from template: SystemWorkoutTemplate) {
        guard let patientId = appState.userId,
              let patientUUID = UUID(uuidString: patientId) else {
            creationError = "Unable to start workout: User not found"
            return
        }

        isCreatingSession = true
        creationError = nil

        Task {
            await createSession(from: template, patientId: patientUUID)
        }
    }

    private func createSession(from template: SystemWorkoutTemplate, patientId: UUID) async {
        let service = ManualWorkoutService()
        let logger = DebugLogger.shared

        do {
            logger.log("QuickPick: Creating session from template: \(template.name)", level: .diagnostic)

            // 1. Create manual session with quick_pick source
            let session = try await service.createManualSession(
                name: template.name,
                patientId: patientId,
                sourceTemplateId: template.id,
                sourceTemplateType: .system,
                sessionSource: .quickPick
            )

            logger.log("QuickPick: Session created: \(session.id)", level: .success)

            // 2. Add exercises from template blocks
            for (blockIndex, block) in template.blocks.enumerated() {
                for (exerciseIndex, exercise) in block.exercises.enumerated() {
                    let sequence = (blockIndex * 100) + exerciseIndex

                    let input = AddManualSessionExerciseInput(
                        manualSessionId: session.id,
                        exerciseTemplateId: nil, // Templates don't have valid FK references
                        exerciseName: exercise.name,
                        blockName: block.name,
                        sequence: sequence,
                        targetSets: exercise.sets ?? 3,
                        targetReps: exercise.reps ?? "10",
                        targetLoad: nil,
                        loadUnit: nil,
                        restPeriodSeconds: nil,
                        notes: exercise.notes
                    )

                    _ = try await service.addExercise(to: session.id, exercise: input)
                }
            }

            logger.log("QuickPick: Added \(template.exerciseCount) exercises to session", level: .success)

            // 3. Dismiss sheet and show workout execution
            await MainActor.run {
                isCreatingSession = false
                selectedTemplate = nil
                createdSession = session
            }

        } catch {
            logger.log("QuickPick: Failed to create session: \(error.localizedDescription)", level: .error)
            await MainActor.run {
                isCreatingSession = false
                creationError = "Failed to start workout: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Duration Chip

private struct DurationChip: View {
    let duration: WorkoutPickerViewModel.DurationOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(duration.displayText)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.orange : Color(.tertiarySystemGroupedBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(CornerRadius.sm)
        }
    }
}

// MARK: - Preset Button

private struct PresetButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.sm)
        }
        .foregroundColor(.primary)
    }
}

// MARK: - Category Toggle

private struct CategoryToggle: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isOn ? .orange : .secondary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isOn ? .orange : .secondary)
            }
            .padding(Spacing.sm)
            .background(isOn ? Color.orange.opacity(0.1) : Color(.tertiarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
        .foregroundColor(.primary)
    }
}

// MARK: - Workout Recommendation Card

private struct WorkoutRecommendationCard: View {
    let template: SystemWorkoutTemplate
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(template.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    if let duration = template.durationDisplay {
                        Text(duration)
                            .font(.caption)
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, Spacing.xxs)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(CornerRadius.sm)
                    }
                }

                if let description = template.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack {
                    if let difficulty = template.difficulty {
                        Label(difficulty.capitalized, systemImage: "chart.bar.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("\(template.exerciseCount) exercises")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.lg)
            .adaptiveShadow(Shadow.subtle)
        }
    }
}

// MARK: - Workout Template Detail Sheet

private struct WorkoutTemplateDetailSheet: View {
    let template: SystemWorkoutTemplate
    let isCreating: Bool
    let onStartWorkout: () -> Void
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showingStartConfirmation: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(template.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        if let description = template.description {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 16) {
                            if let duration = template.durationDisplay {
                                Label(duration, systemImage: "clock")
                            }
                            if let difficulty = template.difficulty {
                                Label(difficulty.capitalized, systemImage: "chart.bar.fill")
                            }
                            Label("\(template.exerciseCount) exercises", systemImage: "list.bullet")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    Divider()

                    // Exercise Blocks
                    ForEach(template.blocks) { block in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(block.name)
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(block.exercises) { exercise in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(exercise.name)
                                            .font(.subheadline)

                                        HStack(spacing: 8) {
                                            if let sets = exercise.sets {
                                                Text("\(sets) sets")
                                            }
                                            if let reps = exercise.reps {
                                                Text(reps)
                                            }
                                        }
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    }

                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 6)
                            }
                        }
                        .padding(.vertical, Spacing.xs)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        onDismiss()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if isCreating {
                        ProgressView()
                    } else {
                        Button {
                            showingStartConfirmation = true
                        } label: {
                            Text("Start")
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .alert("Start Workout?", isPresented: $showingStartConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Start") {
                    // BUILD 328: Actually start the workout
                    onStartWorkout()
                }
            } message: {
                Text("Begin \(template.name)?")
            }
        }
    }
}

// MARK: - Mode Toggle Button (BUILD 352)

private struct ModeToggleButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, Spacing.md)
            .frame(maxWidth: .infinity)
            .background(
                isSelected
                ? LinearGradient(
                    colors: title == "AI Pick" ? [.purple.opacity(0.8), .orange.opacity(0.8)] : [.orange, .pink],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                : LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing)
            )
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(CornerRadius.sm)
        }
    }
}

// MARK: - AI Context Banner (BUILD 352)

private struct AIContextBanner: View {
    let context: RecommendationContext
    let isCached: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Readiness Band
                if let band = context.readinessBand {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(band.color)
                            .frame(width: 10, height: 10)
                        Text(band.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, Spacing.xxs)
                    .background(band.color.opacity(0.15))
                    .cornerRadius(CornerRadius.sm)
                }

                Spacer()

                // Cached indicator
                if isCached {
                    Label("Cached", systemImage: "clock.arrow.circlepath")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 16) {
                // Readiness Score
                if let score = context.readinessScore {
                    Label("\(Int(score))% ready", systemImage: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Recent Workouts
                Label("\(context.recentWorkoutCount) workouts this week", systemImage: "figure.run")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Active Goals
                if !context.activeGoals.isEmpty {
                    Label("\(context.activeGoals.count) goals", systemImage: "target")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - AI Workout Recommendation Card (BUILD 352)

private struct AIWorkoutRecommendationCard: View {
    let recommendation: AIWorkoutRecommendation
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(recommendation.templateName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    // Match Score Badge
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                        Text("\(recommendation.matchScore)%")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, Spacing.xxs)
                    .background(matchScoreColor.opacity(0.2))
                    .foregroundColor(matchScoreColor)
                    .cornerRadius(CornerRadius.sm)
                }

                // AI Reasoning
                Text(recommendation.reasoning)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack {
                    // Category
                    if let category = recommendation.category {
                        Label(category.capitalized, systemImage: "tag.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // Duration
                    if let duration = recommendation.durationMinutes {
                        Label("\(duration) min", systemImage: "clock.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // Difficulty
                    if let difficulty = recommendation.difficulty {
                        Label(difficulty.capitalized, systemImage: "chart.bar.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), matchScoreColor.opacity(0.05)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(CornerRadius.lg)
            .adaptiveShadow(Shadow.subtle)
        }
    }

    private var matchScoreColor: Color {
        if recommendation.matchScore >= 80 {
            return .green
        } else if recommendation.matchScore >= 60 {
            return .orange
        } else {
            return .gray
        }
    }
}

#Preview {
    WorkoutPickerView()
        .environmentObject(AppState())
}
