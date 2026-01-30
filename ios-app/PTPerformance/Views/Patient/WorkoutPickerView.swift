//
//  WorkoutPickerView.swift
//  PTPerformance
//
//  BUILD 327: Quick Pick Workout Finder
//  Questionnaire-based workout recommendation UI
//

import SwiftUI

struct WorkoutPickerView: View {
    @StateObject private var viewModel = WorkoutPickerViewModel()
    @EnvironmentObject var appState: AppState

    // BUILD 328: Use sheet(item:) pattern for reliable first-tap behavior
    @State private var selectedTemplate: SystemWorkoutTemplate?

    // BUILD 328: Workout execution state
    @State private var createdSession: ManualSession?
    @State private var isCreatingSession: Bool = false
    @State private var creationError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // MARK: - Header
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("Quick Pick")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Answer a few questions and we'll find the perfect workout for you")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top)

                    // MARK: - Duration Selector
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

                    // MARK: - Category Toggles
                    VStack(alignment: .leading, spacing: 12) {
                        Label("What do you want to train?", systemImage: "figure.strengthtraining.traditional")
                            .font(.headline)

                        // Quick Presets
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

                        // Individual Toggles
                        VStack(spacing: 8) {
                            CategoryToggle(
                                title: "Push",
                                subtitle: "Chest, shoulders, triceps",
                                icon: "arrow.up.circle.fill",
                                isOn: $viewModel.includePush
                            )

                            CategoryToggle(
                                title: "Pull",
                                subtitle: "Back, biceps, rear delts",
                                icon: "arrow.down.circle.fill",
                                isOn: $viewModel.includePull
                            )

                            CategoryToggle(
                                title: "Legs",
                                subtitle: "Quads, hamstrings, glutes",
                                icon: "figure.walk.circle.fill",
                                isOn: $viewModel.includeLegs
                            )

                            CategoryToggle(
                                title: "Core",
                                subtitle: "Abs, obliques, stability",
                                icon: "circle.circle.fill",
                                isOn: $viewModel.includeCore
                            )

                            CategoryToggle(
                                title: "Cardio",
                                subtitle: "HIIT, conditioning, endurance",
                                icon: "heart.circle.fill",
                                isOn: $viewModel.includeCardio
                            )

                            CategoryToggle(
                                title: "Mobility",
                                subtitle: "Stretching, flexibility, recovery",
                                icon: "figure.yoga",
                                isOn: $viewModel.includeMobility
                            )
                        }
                    }
                    .padding(.horizontal)

                    // MARK: - Find Button
                    Button {
                        Task {
                            await viewModel.findWorkouts()
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "sparkle.magnifyingglass")
                                Text("Find Workouts")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.orange, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .disabled(viewModel.isLoading)
                    .padding(.horizontal)

                    // MARK: - Results
                    if viewModel.hasSearched {
                        VStack(alignment: .leading, spacing: 12) {
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
                                .padding(.vertical, 24)
                            } else {
                                ForEach(viewModel.recommendations) { template in
                                    WorkoutRecommendationCard(template: template) {
                                        // BUILD 328: Direct assignment triggers sheet(item:)
                                        selectedTemplate = template
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Quick Pick")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.reset()
                    } label: {
                        Text("Reset")
                            .font(.subheadline)
                    }
                }
            }
            .task {
                await viewModel.loadTemplatesIfNeeded()
            }
            // BUILD 328: Use sheet(item:) pattern for reliable first-tap behavior
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
            // BUILD 328: Full screen workout execution
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

            // 1. Create manual session
            let session = try await service.createManualSession(
                name: template.name,
                patientId: patientId,
                sourceTemplateId: template.id,
                sourceTemplateType: .system
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
                .background(isSelected ? Color.orange : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(10)
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
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
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
            .padding(12)
            .background(isOn ? Color.orange.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
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
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(6)
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
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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
                        .padding(.vertical, 8)
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

#Preview {
    WorkoutPickerView()
        .environmentObject(AppState())
}
