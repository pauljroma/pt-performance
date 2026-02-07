import SwiftUI

/// Card component displaying today's workout session with exercise preview
/// Includes session info, exercise list preview, and start workout button
struct TodayWorkoutCard: View {
    let session: Session
    let exercises: [Exercise]
    let onStartWorkout: () -> Void
    let onRefresh: () async -> Void
    let onExerciseSelected: (Exercise) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Session Info Header
            sessionHeader

            // Exercise preview (first 3)
            if !exercises.isEmpty {
                exercisePreview
            }

            Divider()

            // Start Workout Button
            startWorkoutButton
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(DesignTokens.cornerRadiusLarge)
        .adaptiveShadow(Shadow.medium)
        .contextMenu {
            Button {
                HapticFeedback.medium()
                onStartWorkout()
            } label: {
                Label("Start Workout", systemImage: "play.circle.fill")
            }

            Button {
                HapticFeedback.light()
                // Copy session name
                UIPasteboard.general.string = session.name
            } label: {
                Label("Copy Session Name", systemImage: "doc.on.doc")
            }

            Divider()

            Button {
                HapticFeedback.light()
                Task { await onRefresh() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
        }
    }

    // MARK: - Session Header

    @ViewBuilder
    private var sessionHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("TODAY'S WORKOUT")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Text(session.name)
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Spacer()

            // Exercise count badge
            VStack {
                Text("\(exercises.count)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                Text("exercises")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Exercise Preview

    @ViewBuilder
    private var exercisePreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(exercises.prefix(3)) { exercise in
                HStack(spacing: 12) {
                    Image(systemName: "circle")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(exercise.exercise_name ?? "Exercise")
                        .font(.subheadline)

                    Spacer()

                    Text("\(exercise.sets) x \(exercise.repsDisplay)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
                .contextMenu {
                    Button {
                        HapticFeedback.light()
                        onExerciseSelected(exercise)
                    } label: {
                        Label("View Details", systemImage: "info.circle")
                    }

                    Button {
                        HapticFeedback.light()
                        // Copy exercise name to clipboard
                        UIPasteboard.general.string = exercise.exercise_name ?? "Exercise"
                    } label: {
                        Label("Copy Name", systemImage: "doc.on.doc")
                    }
                }
            }

            if exercises.count > 3 {
                Text("+ \(exercises.count - 3) more exercises")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 24)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Start Workout Button

    @ViewBuilder
    private var startWorkoutButton: some View {
        Button(action: onStartWorkout) {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                Text("Start Workout")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(DesignTokens.cornerRadiusMedium)
        }
        .accessibilityLabel("Start Workout")
        .accessibilityHint("Begins today's prescribed workout session")
    }
}

#if DEBUG
struct TodayWorkoutCard_Previews: PreviewProvider {
    static var previews: some View {
        TodayWorkoutCard(
            session: Session(
                id: UUID(),
                phase_id: UUID(),
                name: "Upper Body Strength",
                sequence: 1,
                weekday: 1,
                notes: nil,
                created_at: Date(),
                completed: false,
                started_at: nil,
                completed_at: nil,
                total_volume: nil,
                avg_rpe: nil,
                avg_pain: nil,
                duration_minutes: nil
            ),
            exercises: [],
            onStartWorkout: {},
            onRefresh: {},
            onExerciseSelected: { _ in }
        )
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
#endif
