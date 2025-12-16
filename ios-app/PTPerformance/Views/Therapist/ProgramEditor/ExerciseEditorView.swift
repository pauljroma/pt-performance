//
//  ExerciseEditorView.swift
//  PTPerformance
//
//  Build 60: Edit individual exercise prescription (ACP-114)
//

import SwiftUI

struct ExerciseEditorView: View {
    @ObservedObject var viewModel: ProgramEditorViewModel
    let exercise: Exercise
    let sessionId: String

    // Mutable state for editing (initialized from exercise)
    @State private var prescribedSets: Int
    @State private var prescribedReps: String
    @State private var prescribedLoad: Double?
    @State private var loadUnit: String
    @State private var restPeriodSeconds: Int
    @State private var exerciseNotes: String

    @State private var isSaving = false
    @State private var error: String?
    @Environment(\.dismiss) private var dismiss

    init(viewModel: ProgramEditorViewModel, exercise: Exercise, sessionId: String) {
        self.viewModel = viewModel
        self.exercise = exercise
        self.sessionId = sessionId
        _prescribedSets = State(initialValue: exercise.prescribed_sets)
        _prescribedReps = State(initialValue: exercise.prescribed_reps ?? "10")
        _prescribedLoad = State(initialValue: exercise.prescribed_load)
        _loadUnit = State(initialValue: exercise.load_unit ?? "lbs")
        _restPeriodSeconds = State(initialValue: exercise.rest_period_seconds ?? 90)
        _exerciseNotes = State(initialValue: exercise.notes ?? "")
    }

    var body: some View {
        Form {
            Section("Exercise") {
                Text(exercise.exercise_name ?? "Unknown Exercise")
                    .font(.headline)

                if let category = exercise.exercise_templates?.category {
                    LabeledContent("Category", value: category.capitalized)
                }

                if let bodyRegion = exercise.exercise_templates?.body_region {
                    LabeledContent("Body Region", value: bodyRegion.capitalized)
                }
            }

            Section("Prescription") {
                Stepper("Sets: \(prescribedSets)", value: $prescribedSets, in: 1...20)

                HStack {
                    Text("Reps")
                    Spacer()
                    TextField("Reps", text: $prescribedReps)
                        .keyboardType(.numbersAndPunctuation)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }

                HStack {
                    Text("Load")
                    Spacer()
                    TextField("Load", value: Binding(
                        get: { prescribedLoad ?? 0 },
                        set: { prescribedLoad = $0 > 0 ? $0 : nil }
                    ), format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)

                    Picker("Unit", selection: $loadUnit) {
                        Text("lbs").tag("lbs")
                        Text("kg").tag("kg")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 100)
                }

                Stepper("Rest: \(restPeriodSeconds)s", value: $restPeriodSeconds, in: 0...300, step: 15)
            }

            Section("Notes") {
                TextEditor(text: $exerciseNotes)
                    .frame(minHeight: 100)
            }

            if let error = error {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle("Edit Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        await saveExercise()
                    }
                }
                .disabled(isSaving)
            }
        }
    }

    private func saveExercise() async {
        let logger = DebugLogger.shared
        isSaving = true
        error = nil
        defer { isSaving = false }

        do {
            logger.log("💾 Saving exercise: \(exercise.exercise_name ?? "Unknown")")

            let updateInput = UpdateExerciseInput(
                prescribedSets: prescribedSets,
                prescribedReps: prescribedReps,
                prescribedLoad: prescribedLoad,
                loadUnit: loadUnit,
                restPeriodSeconds: restPeriodSeconds,
                notes: exerciseNotes.isEmpty ? nil : exerciseNotes
            )

            try await PTSupabaseClient.shared.client
                .from("session_exercises")
                .update(updateInput)
                .eq("id", value: exercise.id)
                .execute()

            logger.log("✅ Exercise saved successfully", level: .success)
            dismiss()
        } catch {
            logger.log("❌ Failed to save exercise: \(error)", level: .error)
            self.error = "Failed to save exercise: \(error.localizedDescription)"
        }
    }
}

struct UpdateExerciseInput: Codable {
    let prescribedSets: Int
    let prescribedReps: String
    let prescribedLoad: Double?
    let loadUnit: String?
    let restPeriodSeconds: Int?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case prescribedSets = "prescribed_sets"
        case prescribedReps = "prescribed_reps"
        case prescribedLoad = "prescribed_load"
        case loadUnit = "load_unit"
        case restPeriodSeconds = "rest_period_seconds"
        case notes
    }
}

#Preview {
    NavigationView {
        ExerciseEditorView(
            viewModel: ProgramEditorViewModel(
                patientId: UUID(),
                exerciseId: nil
            ),
            exercise: Exercise.sampleExercises[0],
            sessionId: UUID().uuidString
        )
    }
}
