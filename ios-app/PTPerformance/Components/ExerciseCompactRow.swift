import SwiftUI

/// BUILD 120: Enhanced workout execution component with quick-complete and inline editing
/// Replaces ExerciseRow with mobile-first inline editing UX
struct ExerciseCompactRow: View {
    let exercise: Exercise
    @Binding var isCompleted: Bool
    @Binding var isExpanded: Bool

    @EnvironmentObject var viewModel: TodaySessionViewModel
    @Environment(\.colorScheme) var colorScheme

    // Inline editing state
    @State private var editingField: EditingField? = nil
    @State private var actualSets: Int
    @State private var actualReps: [Int]
    @State private var actualLoad: Double
    @State private var loadUnit: String = "lbs"
    @State private var rpe: Int = 5
    @State private var painScore: Int = 0
    @State private var notes: String = ""

    // UI state
    @State private var showingSaveConfirmation = false
    @State private var isSaving = false
    @State private var showingSubstitutionSheet = false

    enum EditingField: Equatable {
        case sets, reps(Int), load, rpe, pain, notes
    }

    init(exercise: Exercise, isCompleted: Binding<Bool>, isExpanded: Binding<Bool>) {
        self.exercise = exercise
        self._isCompleted = isCompleted
        self._isExpanded = isExpanded

        // Initialize with prescribed values
        self._actualSets = State(initialValue: exercise.prescribed_sets)
        self._actualReps = State(initialValue: Array(repeating: exercise.prescribed_reps_int, count: exercise.prescribed_sets))
        self._actualLoad = State(initialValue: exercise.prescribed_load ?? 0.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Collapsed state - Always visible
            collapsedContent

            // Expanded state - Conditional
            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(backgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: isCompleted ? 2 : 1)
        )
        .adaptiveShadow(Shadow.subtle)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
        .sheet(isPresented: $showingSubstitutionSheet) {
            if let patientId = viewModel.patientId,
               let sessionId = viewModel.session?.id {
                AISubstitutionSheet(
                    sessionExerciseId: exercise.id,  // The session_exercise row ID
                    exerciseTemplateId: exercise.exercise_template_id,
                    exerciseName: exercise.exercise_name ?? "Exercise",
                    patientId: patientId,
                    sessionId: sessionId,
                    onSubstitutionApplied: {
                        // Refresh the session to show the new exercise
                        Task {
                            await viewModel.fetchTodaySession()
                        }
                    }
                )
            }
        }
    }

    // MARK: - Collapsed Content

    @ViewBuilder
    private var collapsedContent: some View {
        HStack(spacing: 12) {
            // Quick-complete checkbox
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isCompleted.toggle()
                    if isCompleted {
                        quickComplete()
                    }
                }
                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isCompleted ? .green : .gray)
                    .scaleEffect(isCompleted ? 1.1 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(isCompleted ? "Exercise completed" : "Mark exercise complete")
            .accessibilityHint("Double tap to quick-complete with prescribed values")

            // Exercise number badge
            Text("\(exercise.exercise_order)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(isCompleted ? Color.green : Color.blue)
                .clipShape(Circle())

            // Exercise details
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.exercise_name ?? "Exercise \(exercise.exercise_order)")
                    .font(.headline)
                    .foregroundColor(.primary)

                // Prescribed metrics (tappable for inline edit)
                HStack(spacing: 12) {
                    prescribedMetric(
                        icon: "repeat",
                        value: "\(exercise.prescribed_sets) sets",
                        field: .sets
                    )

                    prescribedMetric(
                        icon: "number",
                        value: exercise.repsDisplay,
                        field: .reps(0)
                    )

                    if let load = exercise.prescribed_load,
                       let unit = exercise.prescribed_load_unit {
                        prescribedMetric(
                            icon: "scalemass",
                            value: "\(Int(load)) \(unit)",
                            field: .load
                        )
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)

                // Completed indicator
                if isCompleted {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                        Text("Completed")
                            .font(.caption2)
                    }
                    .foregroundColor(.green)
                }
            }

            Spacer()

            // Expand/collapse chevron
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(isExpanded ? "Collapse details" : "Expand details")
            .accessibilityHint("Double tap to \(isExpanded ? "hide" : "show") exercise details")
        }
        .padding()
    }

    @ViewBuilder
    private func prescribedMetric(icon: String, value: String, field: EditingField) -> some View {
        Button(action: {
            if isExpanded {
                editingField = field
            }
        }) {
            Label(value, systemImage: icon)
                .font(.caption)
                .foregroundColor(editingField == field ? .blue : .secondary)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Expanded Content

    @ViewBuilder
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
                .padding(.horizontal)

            // Quick Complete Button (if not already completed)
            if !isCompleted {
                quickCompleteButton
                    .padding(.horizontal)
            }

            // AI Substitution Button
            suggestSubstituteButton
                .padding(.horizontal)

            // Inline Weight & Reps Editor
            inlineWeightRepsEditor
                .padding(.horizontal)

            // Feedback Sliders (RPE & Pain)
            feedbackSliders
                .padding(.horizontal)

            // Notes Section
            notesSection
                .padding(.horizontal)

            // Save Changes Button
            if hasUnsavedChanges {
                saveChangesButton
                    .padding(.horizontal)
            }

            Divider()
                .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var quickCompleteButton: some View {
        Button(action: quickComplete) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)

                VStack(alignment: .leading, spacing: 2) {
                    Text("I did this as prescribed")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("\(exercise.prescribed_sets) sets × \(exercise.repsDisplay) @ \(exercise.loadDisplay)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Quick complete with prescribed values")
    }

    @ViewBuilder
    private var suggestSubstituteButton: some View {
        Button(action: {
            showingSubstitutionSheet = true
        }) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Need a substitute?")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Get AI-powered exercise alternatives")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Suggest exercise substitute")
    }

    @ViewBuilder
    private var inlineWeightRepsEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weight & Reps")
                .font(.headline)

            // Table header
            HStack {
                Text("Set")
                    .frame(width: 40, alignment: .leading)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Reps")
                    .frame(width: 60, alignment: .center)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Load (\(loadUnit))")
                    .frame(width: 80, alignment: .center)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
            }

            // Sets rows
            ForEach(0..<min(actualSets, actualReps.count), id: \.self) { index in
                HStack {
                    Text("\(index + 1)")
                        .frame(width: 40, alignment: .leading)
                        .font(.body)

                    TextField("Reps", value: $actualReps[index], format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                        .multilineTextAlignment(.center)

                    TextField("Load", value: $actualLoad, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .multilineTextAlignment(.center)

                    Spacer()
                }
            }

            // Add set button
            Button(action: addSet) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Set")
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    @ViewBuilder
    private var feedbackSliders: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Feedback")
                .font(.headline)

            // RPE Slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("😊 RPE")
                        .font(.subheadline)
                    Spacer()
                    Text("\(rpe)/10 - \(rpeDescription)")
                        .font(.caption)
                        .foregroundColor(rpeColor)
                }

                Slider(value: Binding(
                    get: { Double(rpe) },
                    set: { rpe = Int($0) }
                ), in: 0...10, step: 1)
                    .accentColor(rpeColor)
                    .accessibilityLabel("Rating of Perceived Exertion")
                    .accessibilityValue("\(rpe) out of 10, \(rpeDescription)")
            }

            // Pain Slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("🩹 Pain")
                        .font(.subheadline)
                    Spacer()
                    Text("\(painScore)/10 - \(painDescription)")
                        .font(.caption)
                        .foregroundColor(painColor)
                }

                Slider(value: Binding(
                    get: { Double(painScore) },
                    set: { painScore = Int($0) }
                ), in: 0...10, step: 1)
                    .accentColor(painColor)
                    .accessibilityLabel("Pain Level")
                    .accessibilityValue("\(painScore) out of 10, \(painDescription)")

                if painScore > 5 {
                    Label("High pain - Therapist will be notified", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
    }

    @ViewBuilder
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)

            TextEditor(text: $notes)
                .frame(height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .accessibilityLabel("Exercise notes")
        }
    }

    @ViewBuilder
    private var saveChangesButton: some View {
        Button(action: saveChanges) {
            HStack {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Saving...")
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Save Changes")
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isSaving)
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Helper Methods

    private func quickComplete() {
        isCompleted = true

        // Log with prescribed values
        Task {
            await viewModel.quickCompleteExercise(
                exercise,
                sets: exercise.prescribed_sets,
                reps: Array(repeating: exercise.prescribed_reps_int, count: exercise.prescribed_sets),
                load: exercise.prescribed_load ?? 0.0,
                loadUnit: exercise.prescribed_load_unit ?? "lbs",
                rpe: 5,
                pain: 0,
                notes: nil
            )
        }

        // Show success feedback
        withAnimation {
            showingSaveConfirmation = true
        }

        // Auto-collapse after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                isExpanded = false
                showingSaveConfirmation = false
            }
        }
    }

    private func saveChanges() {
        isSaving = true

        Task {
            await viewModel.updateExerciseLog(
                exercise,
                sets: actualSets,
                reps: actualReps,
                load: actualLoad,
                loadUnit: loadUnit,
                rpe: rpe,
                pain: painScore,
                notes: notes.isEmpty ? nil : notes
            )

            await MainActor.run {
                isSaving = false
                isCompleted = true

                withAnimation {
                    showingSaveConfirmation = true
                }

                // Auto-collapse after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        isExpanded = false
                        showingSaveConfirmation = false
                    }
                }
            }
        }
    }

    private func addSet() {
        withAnimation {
            actualSets += 1
            actualReps.append(exercise.prescribed_reps_int)
        }
    }

    // MARK: - Computed Properties

    private var hasUnsavedChanges: Bool {
        return !isCompleted
    }

    private var backgroundColor: Color {
        if isCompleted {
            return Color.green.opacity(colorScheme == .dark ? 0.2 : 0.1)
        } else if isExpanded {
            return Color.blue.opacity(colorScheme == .dark ? 0.15 : 0.05)
        } else {
            return Color(.systemBackground)
        }
    }

    private var borderColor: Color {
        if isCompleted {
            return Color.green
        } else if isExpanded {
            return Color.blue.opacity(0.5)
        } else {
            return Color(.separator)
        }
    }

    private var rpeDescription: String {
        switch rpe {
        case 0...2: return "Very Easy"
        case 3...4: return "Easy"
        case 5...6: return "Moderate"
        case 7...8: return "Hard"
        case 9: return "Very Hard"
        case 10: return "Maximum Effort"
        default: return ""
        }
    }

    private var rpeColor: Color {
        switch rpe {
        case 0...4: return .green
        case 5...7: return .yellow
        case 8...9: return .orange
        case 10: return .red
        default: return .gray
        }
    }

    private var painDescription: String {
        switch painScore {
        case 0: return "No Pain"
        case 1...2: return "Minimal"
        case 3...4: return "Mild"
        case 5...6: return "Moderate"
        case 7...8: return "Severe"
        case 9...10: return "Extreme"
        default: return ""
        }
    }

    private var painColor: Color {
        switch painScore {
        case 0...2: return .green
        case 3...4: return .yellow
        case 5...6: return .orange
        case 7...10: return .red
        default: return .gray
        }
    }
}

// MARK: - Exercise Extension

extension Exercise {
    var prescribed_reps_int: Int {
        if let reps = prescribed_reps {
            return Int(reps) ?? 10
        }
        return 10
    }
}

// MARK: - Preview

#if DEBUG
// Note: Preview disabled - Exercise.sample not available
// To test, use ExerciseCompactRow in TodaySessionView with real data
#endif
