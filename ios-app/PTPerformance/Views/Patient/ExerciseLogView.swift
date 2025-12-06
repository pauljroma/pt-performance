import SwiftUI

/// View for logging exercise performance details
struct ExerciseLogView: View {
    let exercise: Exercise
    let sessionExerciseId: String
    let patientId: String

    @Environment(\.dismiss) private var dismiss
    @StateObject private var service = ExerciseLogService()

    // Input fields
    @State private var actualSets: Int = 3
    @State private var repsPerSet: [Int] = [10, 10, 10]
    @State private var actualLoad: String = ""
    @State private var loadUnit: String = "lbs"
    @State private var rpe: Double = 5.0
    @State private var painScore: Double = 0.0
    @State private var notes: String = ""

    // UI state
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationView {
            Form {
                // Exercise header
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exercise.exerciseName)
                            .font(.headline)

                        HStack {
                            Label("\(exercise.prescribedSets) sets", systemImage: "number")
                            Spacer()
                            Label("\(exercise.prescribedReps) reps", systemImage: "repeat")
                            Spacer()
                            if let load = exercise.prescribedLoad {
                                Label("\(Int(load)) \(exercise.loadUnit ?? "lbs")", systemImage: "scalemass")
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                }

                // Sets completed
                Section(header: Text("Sets Completed")) {
                    Stepper("Sets: \(actualSets)", value: $actualSets, in: 1...10)
                        .onChange(of: actualSets) { newValue in
                            // Adjust reps array
                            if repsPerSet.count < newValue {
                                repsPerSet.append(contentsOf: Array(repeating: 10, count: newValue - repsPerSet.count))
                            } else if repsPerSet.count > newValue {
                                repsPerSet = Array(repsPerSet.prefix(newValue))
                            }
                        }
                }

                // Reps per set
                Section(header: Text("Reps Per Set")) {
                    ForEach(0..<actualSets, id: \.self) { index in
                        HStack {
                            Text("Set \(index + 1)")
                            Spacer()
                            TextField("Reps", value: Binding(
                                get: { repsPerSet[safe: index] ?? 0 },
                                set: { newValue in
                                    if index < repsPerSet.count {
                                        repsPerSet[index] = newValue
                                    }
                                }
                            ), format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        }
                    }
                }

                // Load
                Section(header: Text("Weight Used")) {
                    HStack {
                        TextField("Load", text: $actualLoad)
                            .keyboardType(.decimalPad)

                        Picker("Unit", selection: $loadUnit) {
                            Text("lbs").tag("lbs")
                            Text("kg").tag("kg")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                    }
                }

                // RPE slider
                Section(header: Text("Rating of Perceived Exertion (RPE)")) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("RPE: \(Int(rpe))")
                                .font(.headline)
                            Spacer()
                            Text(rpeDescription(Int(rpe)))
                                .font(.caption)
                                .foregroundColor(rpeColor(Int(rpe)))
                        }

                        Slider(value: $rpe, in: 0...10, step: 1)
                            .accentColor(rpeColor(Int(rpe)))
                    }
                }

                // Pain slider
                Section(header: Text("Pain Level")) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Pain: \(Int(painScore))")
                                .font(.headline)
                            Spacer()
                            Text(painDescription(Int(painScore)))
                                .font(.caption)
                                .foregroundColor(painColor(Int(painScore)))
                        }

                        Slider(value: $painScore, in: 0...10, step: 1)
                            .accentColor(painColor(Int(painScore)))

                        if Int(painScore) > 5 {
                            Label("⚠️ Pain above 5 - Therapist will be notified", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }

                // Notes
                Section(header: Text("Notes (Optional)")) {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }

                // Submit button
                Section {
                    Button(action: submitLog) {
                        if isSubmitting {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Submitting...")
                                Spacer()
                            }
                        } else {
                            HStack {
                                Spacer()
                                Label("Submit Exercise", systemImage: "checkmark.circle.fill")
                                    .font(.headline)
                                Spacer()
                            }
                        }
                    }
                    .disabled(isSubmitting || !isValidInput)
                }
            }
            .navigationTitle("Log Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Exercise Logged", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your exercise has been logged successfully!")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Failed to submit exercise log")
            }
        }
    }

    private var isValidInput: Bool {
        actualSets > 0 && !repsPerSet.isEmpty && repsPerSet.allSatisfy { $0 > 0 }
    }

    private func submitLog() {
        guard isValidInput else { return }

        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                let load = Double(actualLoad)

                _ = try await service.submitExerciseLog(
                    sessionExerciseId: sessionExerciseId,
                    patientId: patientId,
                    actualSets: actualSets,
                    actualReps: Array(repsPerSet.prefix(actualSets)),
                    actualLoad: load,
                    loadUnit: loadUnit,
                    rpe: Int(rpe),
                    painScore: Int(painScore),
                    notes: notes.isEmpty ? nil : notes
                )

                await MainActor.run {
                    isSubmitting = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func rpeDescription(_ value: Int) -> String {
        switch value {
        case 0...2: return "Very Easy"
        case 3...4: return "Easy"
        case 5...6: return "Moderate"
        case 7...8: return "Hard"
        case 9: return "Very Hard"
        case 10: return "Maximum Effort"
        default: return ""
        }
    }

    private func rpeColor(_ value: Int) -> Color {
        switch value {
        case 0...4: return .green
        case 5...7: return .yellow
        case 8...9: return .orange
        case 10: return .red
        default: return .gray
        }
    }

    private func painDescription(_ value: Int) -> String {
        switch value {
        case 0: return "No Pain"
        case 1...2: return "Minimal"
        case 3...4: return "Mild"
        case 5...6: return "Moderate"
        case 7...8: return "Severe"
        case 9...10: return "Extreme"
        default: return ""
        }
    }

    private func painColor(_ value: Int) -> Color {
        switch value {
        case 0...2: return .green
        case 3...4: return .yellow
        case 5...6: return .orange
        case 7...10: return .red
        default: return .gray
        }
    }
}

// Safe array subscript extension
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// Preview
struct ExerciseLogView_Previews: PreviewProvider {
    static var previews: some View {
        ExerciseLogView(
            exercise: Exercise(
                id: "1",
                sessionExerciseId: "se-1",
                exerciseName: "Back Squat",
                prescribedSets: 3,
                prescribedReps: 10,
                prescribedLoad: 185,
                loadUnit: "lbs",
                restPeriodSeconds: 120
            ),
            sessionExerciseId: "se-1",
            patientId: "patient-1"
        )
    }
}
