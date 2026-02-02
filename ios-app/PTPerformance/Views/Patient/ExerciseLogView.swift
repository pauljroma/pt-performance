import SwiftUI

/// View for logging exercise performance details with validation and accessibility
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

    // Validation state
    @State private var weightValidation: ValidationResult?
    @State private var repsValidations: [ValidationResult?] = []

    // UI state
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var showQueuedOffline = false  // New: for offline queue feedback
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showTechniqueGuide = false
    @State private var showExerciseHistory = false  // BUILD 333: Exercise history lookup

    var body: some View {
        NavigationView {
            Form {
                // Exercise header
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(exercise.exercise_name ?? "Exercise")
                            .font(.headline)

                        HStack {
                            Label("\(exercise.prescribed_sets) sets", systemImage: "number")
                            Spacer()
                            Label("\(exercise.repsDisplay)", systemImage: "repeat")
                            Spacer()
                            if let load = exercise.prescribed_load, let unit = exercise.prescribed_load_unit {
                                Label("\(Int(load)) \(unit)", systemImage: "scalemass")
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                        // View Technique and History buttons
                        HStack(spacing: 16) {
                            Button {
                                showTechniqueGuide = true
                            } label: {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                    Text("Technique")
                                        .fontWeight(.medium)
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            }
                            .accessibilityLabel("View Technique Guide")
                            .accessibilityHint("Open guide with exercise instructions and form tips")

                            // BUILD 333: View Exercise History button
                            Button {
                                showExerciseHistory = true
                            } label: {
                                HStack {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                    Text("History")
                                        .fontWeight(.medium)
                                }
                                .font(.subheadline)
                                .foregroundColor(.green)
                            }
                            .accessibilityLabel("View Exercise History")
                            .accessibilityHint("View your past performance on this exercise")
                        }
                    }
                }

                // Sets completed
                Section(header: Text("Sets Completed")) {
                    Stepper("Sets: \(actualSets)", value: $actualSets, in: 1...10)
                        .accessibilityLabel("Sets completed")
                        .accessibilityValue("\(actualSets) sets")
                        .accessibilityHint("Adjust number of sets completed")
                        .onChange(of: actualSets) { _, newValue in
                            // Adjust reps array
                            if repsPerSet.count < newValue {
                                repsPerSet.append(contentsOf: Array(repeating: 10, count: newValue - repsPerSet.count))
                            } else if repsPerSet.count > newValue {
                                repsPerSet = Array(repsPerSet.prefix(newValue))
                            }
                            // Adjust validation array
                            if repsValidations.count < newValue {
                                repsValidations.append(contentsOf: Array(repeating: nil, count: newValue - repsValidations.count))
                            } else if repsValidations.count > newValue {
                                repsValidations = Array(repsValidations.prefix(newValue))
                            }
                        }
                }

                // Reps per set with validation
                Section(header: Text("Reps Per Set")) {
                    ForEach(0..<actualSets, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Set \(index + 1)")
                                Spacer()
                                TextField("Reps", value: Binding(
                                    get: { repsPerSet[safe: index] ?? 0 },
                                    set: { newValue in
                                        if index < repsPerSet.count {
                                            repsPerSet[index] = newValue
                                            validateReps(at: index, value: newValue)
                                        }
                                    }
                                ), format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                                .accessibilityLabel("Set \(index + 1) reps")
                                .accessibilityHint("Enter number of reps completed for set \(index + 1)")
                            }

                            // Show validation error if present
                            if let validation = repsValidations[safe: index],
                               let errorMessage = validation?.errorMessage,
                               (repsPerSet[safe: index] ?? 0) > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.caption2)
                                    Text(errorMessage)
                                        .font(.caption2)
                                }
                                .foregroundColor(.red)
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Error: \(errorMessage)")
                            }
                        }
                    }
                }

                // Load with validation
                Section(header: Text("Weight Used")) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            TextField("Load", text: $actualLoad)
                                .keyboardType(.decimalPad)
                                .accessibilityLabel("Weight used")
                                .accessibilityHint("Enter the weight you used for this exercise")
                                .onChange(of: actualLoad) { _, newValue in
                                    if !newValue.isEmpty {
                                        weightValidation = ValidationHelpers.validateExerciseWeight(newValue)
                                    } else {
                                        weightValidation = nil
                                    }
                                }

                            Picker("Unit", selection: $loadUnit) {
                                Text("lbs").tag("lbs")
                                Text("kg").tag("kg")
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 120)
                            .accessibilityLabel("Weight unit")
                            .accessibilityHint("Select pounds or kilograms")
                        }

                        // Show validation error if present
                        if let errorMessage = weightValidation?.errorMessage, !actualLoad.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.caption)
                                Text(errorMessage)
                                    .font(.caption)
                            }
                            .foregroundColor(.red)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Error: \(errorMessage)")
                        }
                    }
                }

                // RPE slider with accessibility
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
                            .accessibilityLabel("Rating of Perceived Exertion")
                            .accessibilityValue("\(Int(rpe)) out of 10, \(rpeDescription(Int(rpe)))")
                            .accessibilityHint("Adjust slider to rate how hard the exercise felt")
                    }
                }

                // Pain slider with accessibility
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
                            .accessibilityLabel("Pain Level")
                            .accessibilityValue("\(Int(painScore)) out of 10, \(painDescription(Int(painScore)))")
                            .accessibilityHint("Adjust slider to rate pain experienced during exercise")

                        if Int(painScore) > 5 {
                            Label("Pain above 5 - Therapist will be notified", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Warning: High pain level. Your therapist will be notified.")
                        }
                    }
                }

                // Notes with accessibility
                Section(header: Text("Notes (Optional)")) {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                        .accessibilityLabel("Notes")
                        .accessibilityHint("Enter any additional notes about this exercise")
                }

                // Submit button with validation check
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
                    .accessibilityLabel("Submit Exercise")
                    .accessibilityHint(isValidInput ? "Submit your exercise log" : "Complete all required fields correctly to submit")
                }
            }
            .navigationTitle("Log Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel")
                    .accessibilityHint("Discard changes and return")
                }
            }
            .alert("Exercise Logged", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your exercise has been logged successfully!")
            }
            .alert("Saved Offline", isPresented: $showQueuedOffline) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your exercise log has been saved and will sync automatically when you're back online.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Failed to submit exercise log")
            }
            // BUILD 174: Add missing sheet for technique guide with video
            .sheet(isPresented: $showTechniqueGuide) {
                ExerciseTechniqueView(exercise: exercise)
            }
            // BUILD 333: Add sheet for exercise history lookup
            .sheet(isPresented: $showExerciseHistory) {
                ExerciseHistorySheet(
                    exerciseName: exercise.exercise_name ?? "Exercise",
                    patientId: patientId
                )
            }
            .onAppear {
                // Initialize validation arrays
                repsValidations = Array(repeating: nil, count: actualSets)
            }
        }
    }

    // MARK: - Validation

    private var isValidInput: Bool {
        // Check basic requirements
        guard actualSets > 0 && !repsPerSet.isEmpty && repsPerSet.allSatisfy({ $0 > 0 }) else {
            return false
        }

        // Check weight validation if weight is provided
        if !actualLoad.isEmpty {
            guard weightValidation?.isValid ?? false else {
                return false
            }
        }

        // Check reps validations
        for validation in repsValidations {
            if let result = validation, !result.isValid {
                return false
            }
        }

        // RPE and pain are sliders so always valid
        return true
    }

    private func validateReps(at index: Int, value: Int) {
        // Ensure array is large enough
        while repsValidations.count <= index {
            repsValidations.append(nil)
        }

        // Validate the reps value
        repsValidations[index] = ValidationHelpers.validateExerciseReps(String(value))
    }

    // MARK: - Submit

    private func submitLog() {
        guard isValidInput else { return }

        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                let load = Double(actualLoad)

                guard let sessionExerciseUUID = UUID(uuidString: sessionExerciseId),
                      let patientUUID = UUID(uuidString: patientId) else {
                    // Handle invalid UUIDs
                    return
                }

                _ = try await service.submitExerciseLog(
                    sessionExerciseId: sessionExerciseUUID,
                    patientId: patientUUID,
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
                    // Check if it was queued offline vs synced immediately
                    if service.wasQueuedOffline {
                        HapticFeedback.warning()  // Warning haptic for offline queue
                        showQueuedOffline = true
                    } else {
                        HapticFeedback.success()  // Success haptic for logged exercise
                        showSuccess = true
                    }
                }
            } catch {
                DebugLogger.shared.error("EXERCISE_SAVE", """
                    Failed to save exercise log:
                    Error: \(error.localizedDescription)
                    Type: \(type(of: error))
                    Sets: \(actualSets), Reps: \(Array(repsPerSet.prefix(actualSets)))
                    RPE: \(Int(rpe)), Pain: \(Int(painScore))
                    """)

                await MainActor.run {
                    isSubmitting = false
                    // Check if error was handled by offline queue
                    if service.wasQueuedOffline {
                        HapticFeedback.warning()
                        showQueuedOffline = true
                    } else {
                        HapticFeedback.error()  // Error haptic for failed submission
                        errorMessage = error.localizedDescription
                        showError = true
                    }
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
#if DEBUG
struct ExerciseLogView_Previews: PreviewProvider {
    static var previews: some View {
        ExerciseLogView(
            exercise: Exercise(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                session_id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                exercise_template_id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
                sequence: 1,
                prescribed_sets: 3,
                prescribed_reps: "10",
                prescribed_load: 185,
                load_unit: "lbs",
                rest_period_seconds: 120,
                notes: nil,
                exercise_templates: Exercise.ExerciseTemplate(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
                    name: "Back Squat",
                    category: "squat",
                    body_region: "lower",
                    videoUrl: nil,
                    videoThumbnailUrl: nil,
                    videoDuration: nil,
                    formCues: nil,
                    techniqueCues: nil,
                    commonMistakes: nil,
                    safetyNotes: nil
                )
            ),
            sessionExerciseId: "se-1",
            patientId: "patient-1"
        )
    }
}
#endif
