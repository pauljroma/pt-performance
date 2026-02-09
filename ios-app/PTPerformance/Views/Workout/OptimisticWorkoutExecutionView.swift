//
//  OptimisticWorkoutExecutionView.swift
//  PTPerformance
//
//  ACP-516: Sub-100ms Interaction Response
//  Example workout execution view demonstrating optimistic UI patterns
//

import SwiftUI
import Combine

/// Workout execution view with sub-100ms response times
///
/// This view demonstrates the optimistic update pattern where:
/// 1. All user interactions respond immediately (< 100ms)
/// 2. Server sync happens in the background
/// 3. UI shows sync status unobtrusively
/// 4. Rollback is handled gracefully on sync failure
struct OptimisticWorkoutExecutionView: View {
    @StateObject private var viewModel: OptimisticWorkoutViewModel

    @Environment(\.dismiss) var dismiss
    @State private var showCompletionSheet = false
    @State private var showExitConfirmation = false

    init(sessionId: UUID, patientId: UUID, exercises: [Exercise]) {
        _viewModel = StateObject(wrappedValue: OptimisticWorkoutViewModel(
            sessionId: sessionId,
            patientId: patientId,
            exercises: exercises
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Progress header
                    progressHeader

                    // Exercise content
                    exerciseContent

                    // Bottom action bar
                    bottomActionBar
                }

                // Sync status overlay (top right)
                VStack {
                    HStack {
                        Spacer()
                        SyncStatusIndicator()
                            .padding()
                    }
                    Spacer()
                }
            }
            .navigationTitle(currentExerciseName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Exit") {
                        HapticService.light()
                        showExitConfirmation = true
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    CompactSyncBadge()
                }
            }
            .confirmationDialog("Exit Workout?", isPresented: $showExitConfirmation, titleVisibility: .visible) {
                Button("Save & Exit", role: .destructive) {
                    Task {
                        HapticService.medium()
                        await viewModel.forceSync()
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your completed sets will be saved.")
            }
            .springSheet(isPresented: $showCompletionSheet) {
                WorkoutCompletionSummary(viewModel: viewModel) {
                    dismiss()
                }
            }
            .onChange(of: viewModel.workoutState.isWorkoutCompleted) { _, isCompleted in
                if isCompleted {
                    showCompletionSheet = true
                }
            }
            .onAppear {
                viewModel.startWorkout()
            }
        }
    }

    // MARK: - Components

    private var progressHeader: some View {
        VStack(spacing: 8) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)

                    Rectangle()
                        .fill(Color.green)
                        .frame(width: geometry.size.width * viewModel.progressPercentage, height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.progressPercentage)
                }
            }
            .frame(height: 8)
            .padding(.horizontal)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Workout progress")
            .accessibilityValue("\(Int(viewModel.progressPercentage * 100)) percent complete")

            // Exercise counter
            HStack {
                Text("Exercise \(viewModel.currentExerciseIndex + 1) of \(viewModel.exercises.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(viewModel.workoutState.completedCount) completed")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    private var exerciseContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let exercise = viewModel.currentExercise,
                   let state = viewModel.currentExerciseState {
                    // Exercise header
                    exerciseHeader(exercise: exercise)

                    // Sets list
                    setsSection(exercise: exercise, state: state)

                    // RPE and Pain inputs
                    feedbackSection(state: state)

                    // Notes
                    notesSection(state: state)
                }
            }
            .padding()
        }
    }

    private func exerciseHeader(exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.exercise_name ?? "Exercise")
                .font(.title2)
                .fontWeight(.bold)

            if let category = exercise.movement_pattern {
                Text(category.capitalized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Prescribed values
            HStack(spacing: 16) {
                Label("\(exercise.sets) sets", systemImage: "number")
                Label("\(exercise.prescribed_reps ?? "-") reps", systemImage: "arrow.counterclockwise")
                if let load = exercise.prescribed_load {
                    Label("\(Int(load)) \(exercise.load_unit ?? "lbs")", systemImage: "scalemass")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func setsSection(exercise: Exercise, state: ExerciseUIState) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sets")
                .font(.headline)

            ForEach(0..<state.totalSets, id: \.self) { index in
                OptimisticSetRow(
                    setNumber: index + 1,
                    reps: Binding(
                        get: { state.repsPerSet[safe: index] ?? 10 },
                        set: { newValue in
                            viewModel.updateReps(newValue, forSet: index + 1)
                        }
                    ),
                    weight: Binding(
                        get: { state.weightPerSet[safe: index] ?? 0 },
                        set: { newValue in
                            viewModel.updateWeight(newValue, forSet: index + 1)
                        }
                    ),
                    isCompleted: Binding(
                        get: { index < state.completedSets },
                        set: { _ in }
                    ),
                    loadUnit: state.loadUnit,
                    targetReps: parseReps(exercise.prescribed_reps),
                    targetWeight: exercise.prescribed_load ?? 0,
                    onComplete: {
                        viewModel.completeSet(setNumber: index + 1)
                    }
                )
            }
        }
    }

    private func feedbackSection(state: ExerciseUIState) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Feedback")
                .font(.headline)

            // RPE slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("RPE (Effort)")
                    Spacer()
                    Text("\(state.rpe)")
                        .fontWeight(.bold)
                }

                Slider(value: Binding(
                    get: { Double(state.rpe) },
                    set: { newValue in
                        HapticService.selection()
                        viewModel.updateRPE(Int(newValue))
                    }
                ), in: 1...10, step: 1)
                .tint(.blue)
                .accessibilityLabel("RPE Effort level")
                .accessibilityValue("\(state.rpe) out of 10")
                .accessibilityHint("Adjust to rate your perceived effort from 1 easy to 10 max effort")

                HStack {
                    Text("Easy")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Max Effort")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)

            // Pain slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Pain Level")
                    Spacer()
                    Text("\(state.painScore)")
                        .fontWeight(.bold)
                        .foregroundColor(state.painScore > 5 ? .red : .primary)
                }

                Slider(value: Binding(
                    get: { Double(state.painScore) },
                    set: { newValue in
                        HapticService.selection()
                        viewModel.updatePainScore(Int(newValue))
                    }
                ), in: 0...10, step: 1)
                .tint(state.painScore > 5 ? .red : .orange)
                .accessibilityLabel("Pain level")
                .accessibilityValue("\(state.painScore) out of 10")
                .accessibilityHint("Adjust to rate your pain level from 0 no pain to 10 severe")

                HStack {
                    Text("No Pain")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Severe")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }

    private func notesSection(state: ExerciseUIState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes (optional)")
                .font(.headline)

            TextField("Add notes...", text: Binding(
                get: { state.notes },
                set: { newValue in
                    state.notes = newValue
                }
            ), axis: .vertical)
            .textFieldStyle(.roundedBorder)
            .lineLimit(3...5)
        }
    }

    private var bottomActionBar: some View {
        VStack(spacing: 12) {
            // Main action buttons
            HStack(spacing: 12) {
                // Skip button
                Button {
                    HapticService.light()
                    viewModel.skipCurrentExercise()
                } label: {
                    Label("Skip", systemImage: "forward.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                // Complete button
                Button {
                    viewModel.completeCurrentExercise()
                } label: {
                    Label("Complete Exercise", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            // Quick complete option
            if viewModel.currentExerciseState?.completedSets == 0 {
                Button {
                    if let exercise = viewModel.currentExercise {
                        viewModel.quickCompleteExercise(exercise.id)
                    }
                } label: {
                    Text("Quick Complete (Prescribed Values)")
                        .font(.subheadline)
                }
            }

            // Finish workout button (when enough exercises done)
            if viewModel.canComplete {
                Button {
                    viewModel.completeWorkout()
                } label: {
                    Label("Finish Workout", systemImage: "flag.checkered")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - Computed

    private var currentExerciseName: String {
        viewModel.currentExercise?.exercise_name ?? "Workout"
    }

    private func parseReps(_ repsString: String?) -> Int {
        guard let str = repsString, let reps = Int(str) else { return 10 }
        return reps
    }
}

// MARK: - Workout Completion Summary

struct WorkoutCompletionSummary: View {
    @ObservedObject var viewModel: OptimisticWorkoutViewModel
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Success icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .accessibilityHidden(true)

                Text("Workout Complete!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .accessibilityAddTraits(.isHeader)

                // Stats
                VStack(spacing: 16) {
                    statRow(label: "Exercises", value: "\(viewModel.workoutState.completedCount)")
                    statRow(label: "Total Volume", value: String(format: "%.0f lbs", viewModel.totalVolume))

                    if let rpe = viewModel.averageRPE {
                        statRow(label: "Avg RPE", value: String(format: "%.1f", rpe))
                    }

                    if let pain = viewModel.averagePain {
                        statRow(label: "Avg Pain", value: String(format: "%.1f", pain))
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                // Sync status
                if PendingChangesQueue.shared.hasPendingChanges {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.blue)
                        Text("Syncing workout data...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("All data saved")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button("Done") {
                    HapticService.success()
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.bold)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Preview

#if DEBUG
struct OptimisticWorkoutExecutionView_Previews: PreviewProvider {
    static var previews: some View {
        OptimisticWorkoutExecutionView(
            sessionId: UUID(),
            patientId: UUID(),
            exercises: Exercise.sampleExercises
        )
    }
}
#endif
