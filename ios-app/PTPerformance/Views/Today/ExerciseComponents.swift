import SwiftUI

/// Row component for displaying an exercise in a list
/// Shows exercise order, name, sets/reps/load, and optional notes
struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 16) {
            // Exercise order badge
            Text("\(exercise.exercise_order)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Color.blue)
                .clipShape(Circle())

            // Exercise details
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.exercise_name ?? "Exercise \(exercise.exercise_order)")
                    .font(.headline)

                HStack(spacing: 12) {
                    Label(exercise.setsDisplay, systemImage: "repeat")
                    Label(exercise.repsDisplay + " reps", systemImage: "number")
                    Label(exercise.loadDisplay, systemImage: "scalemass")
                }
                .font(.caption)
                .foregroundColor(.secondary)

                if let notes = exercise.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .lineLimit(2)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .accessibilityHidden(true)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(DesignTokens.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium)
                .stroke(Color(.separator), lineWidth: 1)
        )
        .adaptiveShadow(Shadow.subtle)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(exerciseAccessibilityLabel)
        .accessibilityHint("Tap to view exercise details. Long press for more options")
        .contextMenu {
            Button {
                HapticFeedback.light()
                // Copy exercise prescription
                var prescription = exercise.exercise_name ?? "Exercise"
                prescription += ": \(exercise.setsDisplay) x \(exercise.repsDisplay)"
                if let load = exercise.prescribed_load {
                    prescription += " @ \(Int(load)) \(exercise.load_unit ?? "lbs")"
                }
                UIPasteboard.general.string = prescription
            } label: {
                Label("Copy Prescription", systemImage: "doc.on.doc")
            }

            if let notes = exercise.notes, !notes.isEmpty {
                Button {
                    HapticFeedback.light()
                    UIPasteboard.general.string = notes
                } label: {
                    Label("Copy Notes", systemImage: "note.text")
                }
            }
        }
    }

    private var exerciseAccessibilityLabel: String {
        var label = "Exercise \(exercise.exercise_order): \(exercise.exercise_name ?? "Exercise")"
        label += ", \(exercise.setsDisplay) sets, \(exercise.repsDisplay) reps"
        label += ", \(exercise.loadDisplay)"
        if let notes = exercise.notes, !notes.isEmpty {
            label += ", Note: \(notes)"
        }
        return label
    }
}

/// Detail view for a single exercise
/// Shows full exercise info with technique guide and logging options
struct ExerciseDetailView: View {
    let exercise: Exercise
    @EnvironmentObject var appState: AppState
    @State private var showTechniqueGuide = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(exercise.exercise_name ?? "Exercise")
                    .font(.largeTitle)
                    .bold()

                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(label: "Sets", value: exercise.setsDisplay)
                    DetailRow(label: "Reps", value: exercise.repsDisplay)
                    DetailRow(label: "Load", value: exercise.loadDisplay)

                    if let rest = exercise.rest_seconds {
                        DetailRow(label: "Rest", value: "\(rest) seconds")
                    }

                    if let notes = exercise.notes {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                            Text(notes)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // View Technique Guide button
                Button(action: {
                    showTechniqueGuide = true
                }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("View Technique Guide")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(DesignTokens.cornerRadiusMedium)
                }
                .accessibilityLabel("View Technique Guide")
                .accessibilityHint("Shows video and instructions for proper exercise form")

                Spacer()

                // Log exercise button - navigates to exercise logging form
                if let patientId = appState.userId {
                    NavigationLink(destination: ExerciseLogView(
                        exercise: exercise,
                        sessionExerciseId: exercise.id.uuidString,
                        patientId: patientId
                    )) {
                        Text("Log This Exercise")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(DesignTokens.cornerRadiusMedium)
                    }
                } else {
                    Text("Log This Exercise")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(DesignTokens.cornerRadiusMedium)
                        .overlay(
                            Text("Sign in to log exercises")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        )
                }
            }
            .padding()
        }
        .navigationTitle("Exercise Detail")
        .sheet(isPresented: $showTechniqueGuide) {
            ExerciseTechniqueView(exercise: exercise)
        }
    }
}

/// Helper row for displaying label-value pairs in exercise details
struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.headline)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - One-Tap Start Button

/// Floating action button for quick workout start - always visible when session available
struct OneTapStartButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.medium()
            action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.title2)
                Text("Start Workout")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(Color.green)
                    .shadow(color: .green.opacity(0.4), radius: 8, y: 4)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Start Workout")
        .accessibilityHint("Tap to begin today's workout session")
    }
}

#if DEBUG
struct ExerciseComponents_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            OneTapStartButton(action: {})
        }
        .padding()
    }
}
#endif
