//
//  WorkoutGridView.swift
//  PTPerformance
//
//  Build 96: Collaborative workout grid editing view (Agent 6)
//
//  Google Sheets-like interface for editing program exercises with:
//  - Grid layout with editable cells
//  - Dropdown for exercise selection
//  - Number inputs for sets, reps, weight
//  - Text field for notes
//  - Add/remove rows
//  - Save/discard changes
//  - Real-time sync indicators
//

import SwiftUI

struct WorkoutGridView: View {
    @StateObject private var viewModel: WorkoutGridViewModel
    @Environment(\.dismiss) private var dismiss

    // UI State
    @State private var showExercisePicker = false
    @State private var selectedExerciseIndex: Int?

    init(sessionId: String) {
        _viewModel = StateObject(wrappedValue: WorkoutGridViewModel(sessionId: sessionId))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    loadingView
                } else {
                    gridContent
                }
            }
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.hasUnsavedChanges {
                        Button("Discard") {
                            Task {
                                await viewModel.discardChanges()
                            }
                        }
                        .foregroundColor(.red)
                    } else {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.hasUnsavedChanges {
                        Button {
                            Task {
                                await viewModel.saveChanges()
                            }
                        } label: {
                            if viewModel.isSyncing {
                                ProgressView()
                            } else {
                                Text("Save")
                                    .fontWeight(.semibold)
                            }
                        }
                        .disabled(viewModel.isSyncing)
                    }
                }
            }
            .task {
                await viewModel.loadExercises()
                await viewModel.loadAvailableExercises()
                viewModel.subscribeToRealtimeUpdates()
            }
            .onDisappear {
                viewModel.unsubscribeFromRealtimeUpdates()
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error)
                }
            }
        }
        .sheet(isPresented: $showExercisePicker) {
            if let index = selectedExerciseIndex {
                GridExercisePickerView(
                    availableExercises: viewModel.availableExercises,
                    selectedExerciseId: viewModel.exercises[index].exerciseTemplateId
                ) { selectedTemplate in
                    viewModel.updateCell(
                        exerciseId: viewModel.exercises[index].id,
                        field: .exercise,
                        value: selectedTemplate.id
                    )
                    showExercisePicker = false
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading workout...")
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Grid Content

    private var gridContent: some View {
        VStack(spacing: 0) {
            // Status banner
            if viewModel.isSyncing {
                syncingBanner
            } else if let success = viewModel.successMessage {
                successBanner(success)
            }

            // Grid header
            gridHeader
                .background(Color(.secondarySystemGroupedBackground))

            Divider()

            // Grid rows
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.exercises.enumerated()), id: \.element.id) { index, exercise in
                        gridRow(exercise: exercise, index: index)
                        Divider()
                    }
                }
            }

            // Add row button
            addRowButton
        }
    }

    // MARK: - Syncing Banner

    private var syncingBanner: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text("Syncing changes...")
                .font(.subheadline)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, Spacing.xs)
        .background(Color.modusCyan.opacity(0.1))
    }

    private func successBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(message)
                .font(.subheadline)
            Spacer()
            Button(action: {
                viewModel.successMessage = nil
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, Spacing.xs)
        .background(Color.green.opacity(0.1))
    }

    // MARK: - Grid Header

    private var gridHeader: some View {
        HStack(spacing: 0) {
            Text("Exercise")
                .frame(width: 200, alignment: .leading)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text("Sets")
                .frame(width: 60, alignment: .center)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, Spacing.xs)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text("Reps")
                .frame(width: 80, alignment: .center)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, Spacing.xs)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text("Weight")
                .frame(width: 80, alignment: .center)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, Spacing.xs)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text("Notes")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .font(.subheadline)
                .fontWeight(.semibold)

            // Delete column
            Spacer()
                .frame(width: 44)
        }
    }

    // MARK: - Grid Row

    private func gridRow(exercise: WorkoutGridExercise, index: Int) -> some View {
        HStack(spacing: 0) {
            // Exercise name (tappable to show picker)
            Button(action: {
                selectedExerciseIndex = index
                showExercisePicker = true
            }) {
                HStack {
                    Text(exercise.exerciseName)
                        .foregroundColor(exercise.exerciseTemplateId.isEmpty ? .secondary : .primary)
                        .lineLimit(2)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(width: 200, alignment: .leading)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
            }
            .buttonStyle(PlainButtonStyle())

            // Sets
            TextField("0", value: Binding(
                get: { exercise.prescribedSets },
                set: { newValue in
                    viewModel.updateCell(exerciseId: exercise.id, field: .sets, value: newValue as Any)
                }
            ), format: .number)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .frame(width: 60)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xs)
            .textFieldStyle(RoundedBorderTextFieldStyle())

            // Reps
            TextField("0", text: Binding(
                get: { exercise.prescribedReps },
                set: { newValue in
                    viewModel.updateCell(exerciseId: exercise.id, field: .reps, value: newValue)
                }
            ))
            .keyboardType(.numbersAndPunctuation)
            .multilineTextAlignment(.center)
            .frame(width: 80)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xs)
            .textFieldStyle(RoundedBorderTextFieldStyle())

            // Weight
            TextField("0", value: Binding(
                get: { exercise.prescribedLoad ?? 0 },
                set: { newValue in
                    viewModel.updateCell(exerciseId: exercise.id, field: .weight, value: newValue)
                }
            ), format: .number)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .frame(width: 80)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xs)
            .textFieldStyle(RoundedBorderTextFieldStyle())

            // Notes
            TextField("Add notes...", text: Binding(
                get: { exercise.notes ?? "" },
                set: { newValue in
                    viewModel.updateCell(exerciseId: exercise.id, field: .notes, value: newValue)
                }
            ))
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .textFieldStyle(RoundedBorderTextFieldStyle())

            // Delete button
            Button(action: {
                viewModel.removeExerciseRow(exerciseId: exercise.id)
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(viewModel.hasUnsavedChanges && viewModel.exercises[index].id == exercise.id ? Color.yellow.opacity(0.1) : Color.clear)
    }

    // MARK: - Add Row Button

    private var addRowButton: some View {
        Button(action: {
            viewModel.addExerciseRow()
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Exercise")
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.modusCyan)
            .frame(maxWidth: .infinity)
            .padding()
        }
        .background(Color(.secondarySystemGroupedBackground))
    }
}

// MARK: - Exercise Picker

struct GridExercisePickerView: View {
    let availableExercises: [GridExerciseTemplate]
    let selectedExerciseId: String
    let onSelect: (GridExerciseTemplate) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var filteredExercises: [GridExerciseTemplate] {
        if searchText.isEmpty {
            return availableExercises
        }
        return availableExercises.filter { exercise in
            exercise.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredExercises) { exercise in
                    Button(action: {
                        onSelect(exercise)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name)
                                    .font(.body)
                                if let category = exercise.category {
                                    Text(category)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            if exercise.id == selectedExerciseId {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.modusCyan)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search exercises")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    WorkoutGridView(sessionId: "test-session-id")
}
