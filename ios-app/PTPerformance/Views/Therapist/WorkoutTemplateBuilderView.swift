//
//  WorkoutTemplateBuilderView.swift
//  PTPerformance
//
//  UI for therapists to create custom workout templates
//  Saves to system_workout_templates table in Supabase
//

import SwiftUI

/// View for building custom workout templates
struct WorkoutTemplateBuilderView: View {
    // MARK: - Dependencies

    @Environment(\.dismiss) private var dismiss
    @Environment(\.editMode) private var editMode
    @StateObject private var viewModel = WorkoutTemplateBuilderViewModel()

    /// Callback when template is successfully created
    var onTemplateCreated: ((UUID) -> Void)?

    // MARK: - Body

    var body: some View {
        NavigationView {
            Form {
                basicInfoSection
                classificationSection
                descriptionSection
                equipmentSection
                tagsSection
                exercisesSection
            }
            .navigationTitle("Create Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel")
                    .accessibilityHint("Discards template and returns to previous screen")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveTemplate()
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isSaving)
                    .fontWeight(.semibold)
                    .accessibilityLabel("Save template")
                    .accessibilityHint(viewModel.isValid ? "Saves the workout template" : "Complete the required fields to save")
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {
                    viewModel.dismissError()
                }
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert("Success", isPresented: $viewModel.showSuccess) {
                Button("OK", role: .cancel) {
                    viewModel.dismissSuccess()
                    dismiss()
                }
            } message: {
                Text(viewModel.successMessage)
            }
            .overlay {
                if viewModel.isSaving {
                    savingOverlay
                }
            }
        }
    }

    // MARK: - Basic Info Section

    private var basicInfoSection: some View {
        Section {
            TextField("Template Name", text: $viewModel.name)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .accessibilityLabel("Template name")
                .accessibilityHint("Enter a descriptive name for your workout template")
        } header: {
            Text("Template Name")
        } footer: {
            if let error = viewModel.validationMessage, !viewModel.name.isEmpty {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            } else {
                Text("Required. 3-100 characters.")
                    .font(.caption)
            }
        }
    }

    // MARK: - Classification Section

    private var classificationSection: some View {
        Section {
            // Category Picker
            Picker("Category", selection: $viewModel.category) {
                ForEach(WorkoutCategory.allCases) { category in
                    Label(category.displayName, systemImage: category.iconName)
                        .tag(category)
                }
            }
            .pickerStyle(.menu)
            .accessibilityLabel("Workout category")
            .accessibilityHint("Select the type of workout")

            // Difficulty Picker
            Picker("Difficulty", selection: $viewModel.difficulty) {
                ForEach(WorkoutDifficulty.allCases) { difficulty in
                    HStack {
                        Circle()
                            .fill(difficulty.color)
                            .frame(width: 10, height: 10)
                        Text(difficulty.displayName)
                    }
                    .tag(difficulty)
                }
            }
            .pickerStyle(.menu)
            .accessibilityLabel("Difficulty level")
            .accessibilityHint("Select the target skill level")

            // Duration
            HStack {
                Label("Duration", systemImage: "clock")
                    .foregroundColor(.primary)
                Spacer()
                Stepper(
                    value: $viewModel.durationMinutes,
                    in: 5...180,
                    step: 5
                ) {
                    Text("\(viewModel.durationMinutes) min")
                        .font(.body.monospacedDigit())
                        .foregroundColor(.primary)
                }
                .accessibilityLabel("Duration")
                .accessibilityValue("\(viewModel.durationMinutes) minutes")
                .accessibilityHint("Adjust workout duration in 5-minute increments")
            }
        } header: {
            Text("Classification")
        } footer: {
            Text("Categorize your workout to help with organization and discovery.")
                .font(.caption)
        }
    }

    // MARK: - Description Section

    private var descriptionSection: some View {
        Section {
            TextEditor(text: $viewModel.description)
                .frame(minHeight: 80)
                .accessibilityLabel("Description")
                .accessibilityHint("Optional description of the workout goals and instructions")
        } header: {
            Text("Description (Optional)")
        } footer: {
            HStack {
                Text("Describe the workout goals and any special instructions.")
                Spacer()
                Text("\(viewModel.description.count)/500")
                    .foregroundColor(viewModel.description.count > 500 ? .red : .secondary)
            }
            .font(.caption)
        }
    }

    // MARK: - Equipment Section

    private var equipmentSection: some View {
        Section {
            TextField("Equipment", text: $viewModel.equipmentText)
                .textInputAutocapitalization(.words)
                .accessibilityLabel("Equipment required")
                .accessibilityHint("Enter equipment separated by commas")
        } header: {
            Text("Equipment (Optional)")
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Separate items with commas (e.g., Barbell, Dumbbells, Bench)")
                    .font(.caption)

                if !viewModel.equipmentList.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(viewModel.equipmentList, id: \.self) { item in
                                EquipmentTag(text: item)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        Section {
            TextField("Tags", text: $viewModel.tagsText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityLabel("Tags")
                .accessibilityHint("Enter searchable tags separated by commas")
        } header: {
            Text("Tags (Optional)")
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Separate tags with commas for searchability (e.g., upper_body, compound, strength)")
                    .font(.caption)

                if !viewModel.tagsList.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(viewModel.tagsList, id: \.self) { tag in
                                TagBadge(text: tag)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    // MARK: - Exercises Section

    private var exercisesSection: some View {
        Section {
            if viewModel.exercises.isEmpty {
                emptyExercisesView
            } else {
                ForEach(Array(viewModel.exercises.enumerated()), id: \.element.id) { index, exercise in
                    TemplateExerciseRowView(
                        exercise: exercise,
                        index: index,
                        onUpdate: { name, sets, reps, notes in
                            viewModel.updateExercise(at: index, name: name, sets: sets, reps: reps, notes: notes)
                        },
                        onSelectFromLibrary: { template in
                            viewModel.selectExerciseFromLibrary(template, forExerciseAt: index)
                        },
                        filteredExercises: viewModel.filteredExercises,
                        searchText: $viewModel.exerciseSearchText,
                        onMoveUp: index > 0 ? {
                            viewModel.moveExercise(from: IndexSet(integer: index), to: index - 1)
                        } : nil,
                        onMoveDown: index < viewModel.exercises.count - 1 ? {
                            viewModel.moveExercise(from: IndexSet(integer: index), to: index + 2)
                        } : nil
                    )
                }
                .onDelete(perform: viewModel.removeExercise)
                .onMove(perform: viewModel.moveExercise)
            }

            Button(action: viewModel.addExercise) {
                Label("Add Exercise", systemImage: "plus.circle.fill")
                    .font(.body)
                    .foregroundColor(.blue)
            }
            .accessibilityLabel("Add exercise")
            .accessibilityHint("Adds a new exercise to the template")
        } header: {
            HStack {
                Text("Exercises")
                Spacer()
                if !viewModel.exercises.isEmpty {
                    EditButton()
                        .font(.caption)
                        .accessibilityLabel("Reorder exercises")
                        .accessibilityHint("Enables drag and drop reordering of exercises")
                }
            }
        } footer: {
            if viewModel.exercises.isEmpty {
                Text("Add exercises with sets and reps.")
                    .font(.caption)
            } else {
                Text("\(viewModel.exerciseCount) exercise\(viewModel.exerciseCount == 1 ? "" : "s"). Tap Edit to reorder, swipe to delete.")
                    .font(.caption)
            }
        }
    }

    // MARK: - Empty Exercises View

    private var emptyExercisesView: some View {
        VStack(spacing: 8) {
            Image(systemName: "dumbbell")
                .font(.largeTitle)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            Text("No exercises added")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Tap 'Add Exercise' to get started")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Saving Overlay

    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)

                Text("Saving Template...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(Color(.systemBackground).opacity(0.95))
            .cornerRadius(16)
            .shadow(radius: 10)
        }
    }

    // MARK: - Actions

    /// Save template via ViewModel
    private func saveTemplate() async {
        do {
            let templateId = try await viewModel.saveTemplate()
            onTemplateCreated?(templateId)
        } catch {
            // Error is handled by ViewModel
            DebugLogger.shared.log("Template save failed: \(error)", level: .error)
        }
    }
}

// MARK: - Exercise Row View

/// Row view for editing an individual exercise with autocomplete
private struct TemplateExerciseRowView: View {
    let exercise: TemplateExerciseItem
    let index: Int
    let onUpdate: (String?, Int?, String?, String?) -> Void
    let onSelectFromLibrary: (ExerciseTemplateData) -> Void
    let filteredExercises: [ExerciseTemplateData]
    @Binding var searchText: String
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?

    @State private var isExpanded: Bool = false
    @State private var showingSuggestions: Bool = false
    @FocusState private var isNameFieldFocused: Bool
    @Environment(\.editMode) private var editMode

    private var isEditing: Bool {
        editMode?.wrappedValue.isEditing == true
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(spacing: 12) {
                    // Sets and Reps
                    HStack {
                        // Sets stepper
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sets")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Stepper(
                                value: Binding(
                                    get: { exercise.sets },
                                    set: { onUpdate(nil, $0, nil, nil) }
                                ),
                                in: 1...20
                            ) {
                                Text("\(exercise.sets)")
                                    .font(.body.monospacedDigit())
                                    .frame(minWidth: 24)
                            }
                        }

                        Divider()
                            .frame(height: 40)
                            .padding(.horizontal, 8)

                        // Reps input
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reps")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Reps", text: Binding(
                                get: { exercise.reps },
                                set: { onUpdate(nil, nil, $0, nil) }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                            .keyboardType(.default)
                        }
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes (Optional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Exercise notes...", text: Binding(
                            get: { exercise.notes },
                            set: { onUpdate(nil, nil, nil, $0) }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(.vertical, 8)
            } label: {
                HStack(spacing: 8) {
                    // Drag handle indicator (visible when in edit mode)
                    if isEditing {
                        Image(systemName: "line.3.horizontal")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .accessibilityHidden(true)
                    }

                    Text("\(index + 1).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        TextField("Search or type exercise name", text: Binding(
                            get: { exercise.name },
                            set: { newValue in
                                onUpdate(newValue, nil, nil, nil)
                                searchText = newValue
                                showingSuggestions = !newValue.isEmpty
                            }
                        ))
                        .font(.body)
                        .focused($isNameFieldFocused)
                        .onChange(of: isNameFieldFocused) { _, focused in
                            if focused && !exercise.name.isEmpty {
                                searchText = exercise.name
                                showingSuggestions = true
                            } else if !focused {
                                // Delay hiding suggestions to allow tap to register
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    showingSuggestions = false
                                }
                            }
                        }

                        // Show category/body region for library exercises
                        if exercise.isFromLibrary {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                if let category = exercise.category {
                                    Text(category.capitalized)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                if let bodyRegion = exercise.bodyRegion {
                                    if exercise.category != nil {
                                        Text("*")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Text(bodyRegion.capitalized)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    Spacer()

                    Text("\(exercise.sets) x \(exercise.reps)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(exerciseAccessibilityLabel)
            .accessibilityHint("Double tap to expand and edit exercise details")
            .accessibilityActions {
                if let onMoveUp = onMoveUp {
                    Button("Move Up") {
                        onMoveUp()
                    }
                }
                if let onMoveDown = onMoveDown {
                    Button("Move Down") {
                        onMoveDown()
                    }
                }
            }

            // Suggestions dropdown
            if showingSuggestions && !filteredExercises.isEmpty && isNameFieldFocused {
                ExerciseSuggestionsView(
                    suggestions: filteredExercises,
                    onSelect: { template in
                        onSelectFromLibrary(template)
                        showingSuggestions = false
                        isNameFieldFocused = false
                    }
                )
                .padding(.leading, 32)
                .padding(.top, 4)
            }
        }
    }

    private var exerciseAccessibilityLabel: String {
        let name = exercise.name.isEmpty ? "Unnamed exercise" : exercise.name
        let libraryIndicator = exercise.isFromLibrary ? ", from library" : ""
        return "Exercise \(index + 1): \(name), \(exercise.sets) sets of \(exercise.reps) reps\(libraryIndicator)"
    }
}

// MARK: - Exercise Suggestions View

/// View showing exercise suggestions from the library
private struct ExerciseSuggestionsView: View {
    let suggestions: [ExerciseTemplateData]
    let onSelect: (ExerciseTemplateData) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Suggestions from library")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)

            Divider()

            ForEach(suggestions, id: \.id) { template in
                Button {
                    onSelect(template)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(template.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)

                            HStack(spacing: 4) {
                                if let category = template.category {
                                    Text(category.capitalized)
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)
                                }
                                if let bodyRegion = template.bodyRegion {
                                    Text(bodyRegion.capitalized)
                                        .font(.caption2)
                                        .foregroundColor(.purple)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.purple.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                        }

                        Spacer()

                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if template.id != suggestions.last?.id {
                    Divider()
                        .padding(.leading, 12)
                }
            }
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(uiColor: .separator), lineWidth: 0.5)
        )
    }
}

// MARK: - Equipment Tag

/// Small tag view for equipment items
private struct EquipmentTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.blue)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(6)
    }
}

// MARK: - Tag Badge

/// Small badge view for tags
private struct TagBadge: View {
    let text: String

    var body: some View {
        Text("#\(text)")
            .font(.caption)
            .foregroundColor(.purple)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.purple.opacity(0.1))
            .cornerRadius(6)
    }
}

// MARK: - Preview

#if DEBUG
struct WorkoutTemplateBuilderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Empty state
            WorkoutTemplateBuilderView()
                .previewDisplayName("Empty")

            // With sample data (simulated)
            WorkoutTemplateBuilderView()
                .previewDisplayName("Default")

            // Dark mode
            WorkoutTemplateBuilderView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
#endif
