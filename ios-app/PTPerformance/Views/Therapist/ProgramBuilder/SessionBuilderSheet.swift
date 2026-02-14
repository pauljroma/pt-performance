//
//  SessionBuilderSheet.swift
//  PTPerformance
//
//  Build 50: Modal sheet for adding/editing a session within a phase
//

import SwiftUI

struct SessionBuilderSheet: View {
    @Binding var session: ProgramPhase.Session
    @Binding var isPresented: Bool
    @State private var showExercisePicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Session Details") {
                    TextField("Session Name", text: $session.name)
                        .textInputAutocapitalization(.words)
                }

                Section {
                    if session.exercises.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 12) {
                                Image(systemName: "dumbbell")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("No exercises added")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Tap 'Add Exercise' to get started")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, Spacing.lg)
                            Spacer()
                        }
                    } else {
                        ForEach(session.exercises, id: \.id) { exercise in
                            ExerciseRowView(exercise: exercise)
                        }
                        .onDelete(perform: deleteExercise)
                    }

                    Button {
                        showExercisePicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Exercises (\(session.exercises.count))")
                }
            }
            .navigationTitle("Edit Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .sheet(isPresented: $showExercisePicker) {
                ExerciseTemplatePicker(selectedExercises: $session.exercises)
            }
        }
    }

    private func deleteExercise(at offsets: IndexSet) {
        session.exercises.remove(atOffsets: offsets)
    }
}

struct ExerciseRowView: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(exercise.exercise_name ?? "Unknown Exercise")
                    .font(.headline)
                Spacer()
                if exercise.exercise_templates?.hasVideo == true {
                    Image(systemName: "play.circle.fill")
                        .font(.caption)
                        .foregroundColor(.modusCyan)
                }
            }

            HStack(spacing: 12) {
                // Sets
                Label(
                    "\(exercise.sets) sets",
                    systemImage: "repeat"
                )
                .font(.caption)
                .foregroundColor(.secondary)

                // Reps
                if let reps = exercise.prescribed_reps {
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Label(
                        "\(reps) reps",
                        systemImage: "number"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                // Load
                if let load = exercise.prescribed_load, let unit = exercise.load_unit {
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Label(
                        "\(Int(load)) \(unit)",
                        systemImage: "scalemass"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                // Rest
                if let rest = exercise.rest_period_seconds {
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Label(
                        "\(rest)s rest",
                        systemImage: "clock"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }

            // Category and body region
            if let category = exercise.exercise_templates?.category,
               let bodyRegion = exercise.exercise_templates?.body_region {
                Text("\(category.capitalized) • \(bodyRegion.capitalized)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, Spacing.xxs)
    }
}

#Preview {
    SessionBuilderSheet(
        session: .constant(
            ProgramPhase.Session(
                id: UUID(),
                name: "Day 1: Upper Body",
                exercises: Exercise.sampleExercises
            )
        ),
        isPresented: .constant(true)
    )
}
