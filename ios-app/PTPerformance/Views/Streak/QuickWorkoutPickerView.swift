//
//  QuickWorkoutPickerView.swift
//  PTPerformance
//
//  ACP-842: Streak Protection Alerts
//  View for selecting quick workout duration and type
//

import SwiftUI

// MARK: - Quick Workout Picker View

/// View for selecting a quick workout to protect streak
struct QuickWorkoutPickerView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @StateObject private var streakService = StreakAlertService.shared

    @State private var selectedDuration: QuickWorkoutDuration = .tenMinutes
    @State private var selectedWorkout: QuickWorkout?
    @State private var showExecution = false

    let onWorkoutSelected: (QuickWorkout) -> Void

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with motivation
                    headerSection

                    // Duration picker
                    durationPicker

                    // Workout options
                    workoutOptions

                    // Start button
                    if selectedWorkout != nil {
                        startButton
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Quick Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $showExecution) {
                if let workout = selectedWorkout {
                    QuickWorkoutExecutionView(workout: workout) {
                        showExecution = false
                        dismiss()
                        onWorkoutSelected(workout)
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Streak info
            if let status = streakService.currentStatus {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)

                    Text("\(status.currentStreak)-day streak at risk")
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                Text("Pick a quick workout to keep your streak alive!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Choose a Quick Workout")
                    .font(.headline)

                Text("Short workouts that fit your schedule")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
    }

    private var durationPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How much time do you have?")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                ForEach(QuickWorkoutDuration.allCases) { duration in
                    durationButton(duration)
                }
            }
        }
    }

    private func durationButton(_ duration: QuickWorkoutDuration) -> some View {
        Button {
            HapticFeedback.light()
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDuration = duration
                selectedWorkout = nil // Reset selection when duration changes
            }
        } label: {
            VStack(spacing: 6) {
                Text("\(duration.rawValue)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                Text("min")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(selectedDuration == duration ? Color.orange : Color(.systemBackground))
            .foregroundColor(selectedDuration == duration ? .white : .primary)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(selectedDuration == duration ? Color.orange : Color(.systemGray4), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(duration.rawValue) minute duration")
        .accessibilityAddTraits(selectedDuration == duration ? [.isSelected] : [])
    }

    private var workoutOptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Workout")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            let filteredWorkouts = streakService.getQuickWorkoutOptions(duration: selectedDuration)

            if filteredWorkouts.isEmpty {
                noWorkoutsView
            } else {
                ForEach(filteredWorkouts) { workout in
                    workoutCard(workout)
                }
            }
        }
    }

    private var noWorkoutsView: some View {
        VStack(spacing: 8) {
            Image(systemName: "figure.run")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No workouts available for this duration")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
    }

    private func workoutCard(_ workout: QuickWorkout) -> some View {
        Button {
            HapticFeedback.light()
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedWorkout = workout
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                // Icon
                ZStack {
                    Circle()
                        .fill(workoutTypeColor(workout.type).opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: workout.type.iconName)
                        .font(.title2)
                        .foregroundColor(workoutTypeColor(workout.type))
                }

                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Label("\(workout.durationMinutes) min", systemImage: "clock")
                        Label("\(workout.exerciseCount) exercises", systemImage: "list.bullet")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    if let description = workout.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Selection indicator
                Image(systemName: selectedWorkout?.id == workout.id ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(selectedWorkout?.id == workout.id ? .orange : .secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(
                        selectedWorkout?.id == workout.id ? Color.orange : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(workout.name), \(workout.durationMinutes) minutes, \(workout.exerciseCount) exercises")
        .accessibilityAddTraits(selectedWorkout?.id == workout.id ? [.isSelected] : [])
    }

    private var startButton: some View {
        Button {
            HapticFeedback.medium()
            showExecution = true
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text("Start \(selectedWorkout?.name ?? "Workout")")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                LinearGradient(
                    colors: [.orange, .orange.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(CornerRadius.md)
        }
        .padding(.top, Spacing.xs)
        .accessibilityLabel("Start \(selectedWorkout?.name ?? "workout")")
    }

    // MARK: - Helper Methods

    private func workoutTypeColor(_ type: QuickWorkoutType) -> Color {
        switch type {
        case .armCare: return .orange
        case .mobility: return .green
        case .express: return .blue
        case .stretching: return .purple
        case .warmup: return .red
        }
    }
}

// MARK: - Quick Workout Detail Sheet

/// Detailed view of a quick workout before starting
struct QuickWorkoutDetailSheet: View {
    let workout: QuickWorkout
    let onStart: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    workoutHeader

                    // Exercise list
                    exerciseList

                    // Start button
                    startButton
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(workout.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var workoutHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(workoutTypeColor.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: workout.type.iconName)
                    .font(.system(size: 36))
                    .foregroundColor(workoutTypeColor)
            }

            HStack(spacing: 20) {
                VStack {
                    Text("\(workout.durationMinutes)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("minutes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .frame(height: 30)

                VStack {
                    Text("\(workout.exerciseCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("exercises")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let description = workout.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
    }

    private var exerciseList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercises")
                .font(.headline)

            ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                HStack {
                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(workoutTypeColor)
                        .clipShape(Circle())

                    Text(exercise.name)
                        .font(.subheadline)

                    Spacer()

                    Text(exercise.prescriptionDisplay)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, Spacing.xs)

                if index < workout.exercises.count - 1 {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
    }

    private var startButton: some View {
        Button {
            HapticFeedback.medium()
            onStart()
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text("Start Workout")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(workoutTypeColor)
            .cornerRadius(CornerRadius.md)
        }
        .accessibilityLabel("Start \(workout.name)")
    }

    private var workoutTypeColor: Color {
        switch workout.type {
        case .armCare: return .orange
        case .mobility: return .green
        case .express: return .blue
        case .stretching: return .purple
        case .warmup: return .red
        }
    }
}

// MARK: - Preview

struct QuickWorkoutPickerView_Previews: PreviewProvider {
    static var previews: some View {
        QuickWorkoutPickerView { workout in
            print("Selected: \(workout.name)")
        }
    }
}
