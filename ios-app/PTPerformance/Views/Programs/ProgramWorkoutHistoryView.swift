//
//  ProgramWorkoutHistoryView.swift
//  PTPerformance
//
//  View displaying workout history within a specific enrolled program.
//  Shows completed workouts with summary stats and detailed exercise info.
//

import SwiftUI

// MARK: - Program Workout History View

struct ProgramWorkoutHistoryView: View {
    let enrollment: EnrollmentWithProgram
    @StateObject private var viewModel: ProgramWorkoutHistoryViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedWorkout: ProgramWorkoutHistoryItem?

    init(enrollment: EnrollmentWithProgram) {
        self.enrollment = enrollment
        self._viewModel = StateObject(wrappedValue: ProgramWorkoutHistoryViewModel(enrollment: enrollment))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if viewModel.isLoading {
                        loadingView
                    } else if let error = viewModel.errorMessage {
                        errorView(error)
                    } else if viewModel.isEmpty {
                        emptyStateView
                    } else {
                        // Stats Summary
                        statsSection

                        // Streak Indicator
                        if viewModel.stats.currentStreak > 0 {
                            streakSection
                        }

                        // Workout History List
                        workoutHistorySection
                    }
                }
                .padding()
            }
            .navigationTitle("Workout History")
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
                    .accessibilityLabel("Close")
                }
            }
            .refreshable {
                HapticFeedback.light()
                await viewModel.refresh()
            }
            .sheet(item: $selectedWorkout) { workout in
                ProgramWorkoutDetailSheet(workout: workout, patientId: PTSupabaseClient.shared.userId ?? "")
            }
            .task {
                await viewModel.loadHistory()
            }
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 12) {
                // Workouts Completed
                StatCard(
                    icon: "checkmark.circle.fill",
                    value: "\(viewModel.stats.totalWorkoutsCompleted)",
                    label: "Workouts",
                    color: .green
                )

                // Total Volume
                StatCard(
                    icon: "scalemass.fill",
                    value: viewModel.stats.totalVolumeDisplay,
                    label: "Volume",
                    color: .blue
                )

                // Total Time
                StatCard(
                    icon: "clock.fill",
                    value: viewModel.stats.totalDurationDisplay,
                    label: "Time",
                    color: .orange
                )

                // Avg RPE
                if let rpe = viewModel.stats.averageRpeDisplay {
                    StatCard(
                        icon: "flame.fill",
                        value: rpe,
                        label: "Avg RPE",
                        color: .red
                    )
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Streak Section

    private var streakSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(viewModel.stats.currentStreak) day streak!")
                    .font(.headline)
                    .foregroundColor(.primary)

                if viewModel.stats.longestStreak > viewModel.stats.currentStreak {
                    Text("Best: \(viewModel.stats.longestStreak) days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Streak flames visualization
            HStack(spacing: 2) {
                ForEach(0..<min(viewModel.stats.currentStreak, 7), id: \.self) { _ in
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.15), Color.red.opacity(0.1)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current streak: \(viewModel.stats.currentStreak) days. Best streak: \(viewModel.stats.longestStreak) days")
    }

    // MARK: - Workout History Section

    private var workoutHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completed Workouts")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 10) {
                ForEach(viewModel.workouts) { workout in
                    WorkoutHistoryCard(workout: workout)
                        .onTapGesture {
                            HapticFeedback.light()
                            selectedWorkout = workout
                        }
                }

                // Load More
                if viewModel.hasMoreWorkouts {
                    if viewModel.isLoadingMore {
                        HStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Loading more...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        Button {
                            Task {
                                await viewModel.loadMoreWorkouts()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.down.circle")
                                Text("Load More")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.modusCyan)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(CornerRadius.sm)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading workout history...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text("Unable to Load History")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await viewModel.loadHistory()
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.6))

            Text("No Workouts Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Complete your first workout from \"\(viewModel.programTitle)\" to start tracking your progress here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .accessibilityHidden(true)

            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(color.opacity(0.1))
        .cornerRadius(CornerRadius.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Workout History Card

private struct WorkoutHistoryCard: View {
    let workout: ProgramWorkoutHistoryItem

    var body: some View {
        HStack(spacing: 12) {
            // Completion checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)
                .accessibilityHidden(true)

            // Workout Details
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 12) {
                    Text(workout.dateDisplay)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let duration = workout.durationDisplay {
                        HStack(spacing: 2) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text(duration)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }

                    Text("\(workout.exerciseCount) exercises")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Stats row
                HStack(spacing: 16) {
                    if let volume = workout.volumeDisplay {
                        HStack(spacing: 2) {
                            Image(systemName: "scalemass")
                                .font(.caption2)
                            Text(volume)
                                .font(.caption)
                        }
                        .foregroundColor(.modusCyan)
                    }

                    if let rpe = workout.rpeDisplay {
                        HStack(spacing: 2) {
                            Image(systemName: "flame")
                                .font(.caption2)
                            Text("RPE \(rpe)")
                                .font(.caption)
                        }
                        .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
        }
        .padding(Spacing.sm)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.sm)
        .adaptiveShadow(Shadow.subtle)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(workout.name), completed \(workout.dateDisplay), \(workout.exerciseCount) exercises\(workout.volumeDisplay.map { ", volume \($0)" } ?? "")")
        .accessibilityHint("Double tap to view workout details")
    }
}

// MARK: - Program Workout Detail Sheet

private struct ProgramWorkoutDetailSheet: View {
    let workout: ProgramWorkoutHistoryItem
    let patientId: String
    @Environment(\.dismiss) private var dismiss

    @State private var exercises: [ExerciseLogDetail] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    workoutHeader

                    // Stats
                    statsRow

                    // Exercises
                    if isLoading {
                        ProgressView("Loading exercises...")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else if let error = errorMessage {
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if exercises.isEmpty {
                        Text("No exercise details available")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        exercisesSection
                    }
                }
                .padding()
            }
            .navigationTitle("Workout Details")
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
                    .accessibilityLabel("Close")
                }
            }
            .task {
                await loadExercises()
            }
        }
    }

    private var workoutHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(workout.name)
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 16) {
                Label(workout.dateDisplay, systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let duration = workout.durationDisplay {
                    Label(duration, systemImage: "clock")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            if let phase = workout.phaseName {
                Label(phase, systemImage: "square.stack.3d.up")
                    .font(.caption)
                    .foregroundColor(.modusCyan)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            if let volume = workout.volumeDisplay {
                statPill(icon: "scalemass.fill", value: volume, color: .modusCyan)
            }

            if let rpe = workout.rpeDisplay {
                statPill(icon: "flame.fill", value: "RPE \(rpe)", color: .orange)
            }

            if let pain = workout.avgPain {
                statPill(icon: "heart.fill", value: String(format: "%.1f pain", pain), color: painColor(pain))
            }

            statPill(icon: "figure.strengthtraining.traditional", value: "\(workout.exerciseCount) exercises", color: .green)
        }
    }

    private func statPill(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .cornerRadius(CornerRadius.lg)
    }

    private func painColor(_ pain: Double) -> Color {
        switch pain {
        case 0...2: return .green
        case 2...5: return .yellow
        default: return .red
        }
    }

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercises")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 8) {
                ForEach(exercises) { exercise in
                    ExerciseDetailRow(exercise: exercise)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    private func loadExercises() async {
        do {
            let historyService = WorkoutHistoryService()
            exercises = try await historyService.fetchManualWorkoutExercises(workoutId: workout.id)
            isLoading = false
        } catch {
            errorMessage = "Unable to load exercise details"
            isLoading = false
        }
    }
}

// MARK: - Exercise Detail Row

private struct ExerciseDetailRow: View {
    let exercise: ExerciseLogDetail

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.exerciseName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    Text("\(exercise.actualSets) sets x \(exercise.repsDisplay) reps")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(exercise.loadDisplay)
                        .font(.caption)
                        .foregroundColor(.modusCyan)

                    if exercise.rpe > 0 {
                        Text("RPE \(exercise.rpe)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            if exercise.hasVideo {
                Image(systemName: "play.circle")
                    .font(.title3)
                    .foregroundColor(.modusCyan)
            }
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.sm)
    }
}

// MARK: - Preview

#if DEBUG
struct ProgramWorkoutHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Preview requires EnrollmentWithProgram data")
            .padding()
    }
}
#endif
