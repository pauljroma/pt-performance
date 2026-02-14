import SwiftUI

/// Section component displaying today's completed workouts
/// Shows a summary count and list of completed workouts with context menus
struct CompletedWorkoutsSection: View {
    let completedCount: Int
    let completedWorkouts: [TodayWorkoutSummary]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Summary header
            summaryHeader

            // List of completed workouts today with context menus
            if !completedWorkouts.isEmpty {
                ForEach(completedWorkouts) { workout in
                    completedWorkoutRow(workout)
                }
            }
        }
    }

    // MARK: - Summary Header

    @ViewBuilder
    private var summaryHeader: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title2)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(completedCount) workout\(completedCount == 1 ? "" : "s") completed today")
                    .font(.headline)
                    .foregroundColor(.primary)

                if let lastWorkout = completedWorkouts.first {
                    Text("Last: \(lastWorkout.name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(completedCount) workout\(completedCount == 1 ? "" : "s") completed today")
    }

    // MARK: - Completed Workout Row

    @ViewBuilder
    private func completedWorkoutRow(_ workout: TodayWorkoutSummary) -> some View {
        HStack(spacing: 12) {
            Image(systemName: workout.isPrescribed ? "clipboard.fill" : "dumbbell.fill")
                .foregroundColor(workout.isPrescribed ? .modusCyan : .orange)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(workout.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    if let duration = workout.durationMinutes {
                        Text("\(duration) min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let volume = workout.totalVolume, volume > 0 {
                        Text(volume >= 1000 ? String(format: "%.1fk lbs", volume / 1000) : "\(Int(volume)) lbs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(workout.completedAt, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
                .accessibilityHidden(true)
        }
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.sm)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.sm)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(workoutAccessibilityLabel(workout))
        .accessibilityHint("Long press for more options")
        .contextMenu {
            Button {
                HapticFeedback.light()
                // Copy workout summary to clipboard
                var summary = workout.name
                if let duration = workout.durationMinutes {
                    summary += " - \(duration) min"
                }
                if let volume = workout.totalVolume, volume > 0 {
                    summary += " - \(Int(volume)) lbs"
                }
                UIPasteboard.general.string = summary
            } label: {
                Label("Copy Summary", systemImage: "doc.on.doc")
            }

            Button {
                HapticFeedback.light()
                // Share workout details
                let summary = "Completed \(workout.name) at \(workout.completedAt.formatted(date: .omitted, time: .shortened))"
                UIPasteboard.general.string = summary
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
    }

    private func workoutAccessibilityLabel(_ workout: TodayWorkoutSummary) -> String {
        var label = workout.name
        if let duration = workout.durationMinutes {
            label += ", \(duration) minutes"
        }
        if let volume = workout.totalVolume, volume > 0 {
            label += ", \(Int(volume)) pounds"
        }
        label += ", completed at \(workout.completedAt.formatted(date: .omitted, time: .shortened))"
        return label
    }
}

#if DEBUG
struct CompletedWorkoutsSection_Previews: PreviewProvider {
    static var previews: some View {
        CompletedWorkoutsSection(
            completedCount: 2,
            completedWorkouts: []
        )
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
#endif
