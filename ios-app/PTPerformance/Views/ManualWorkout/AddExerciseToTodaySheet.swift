//
//  AddExerciseToTodaySheet.swift
//  PTPerformance
//
//  BUILD 220: Add exercises to today's prescribed session
//

import SwiftUI

/// Sheet for adding exercises to today's prescribed session
struct AddExerciseToTodaySheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddExerciseViewModel()
    let onExerciseAdded: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search exercises...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding()

            // Exercise list
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading exercises...")
                Spacer()
            } else if viewModel.filteredExercises.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No exercises found")
                        .font(.headline)
                    Text("Try a different search term")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                List(viewModel.filteredExercises) { exercise in
                    AddExercisePickerRow(
                        exercise: exercise,
                        isSelected: viewModel.selectedExercise?.id == exercise.id
                    ) {
                        viewModel.selectedExercise = exercise
                    }
                }
                .listStyle(.plain)
            }

            // Add button
            if viewModel.selectedExercise != nil {
                VStack(spacing: 12) {
                    Divider()

                    // Exercise configuration
                    if let selected = viewModel.selectedExercise {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Adding: \(selected.name)")
                                .font(.headline)

                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Sets")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Stepper("\(viewModel.targetSets)", value: $viewModel.targetSets, in: 1...10)
                                }

                                Spacer()

                                VStack(alignment: .leading) {
                                    Text("Reps")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Stepper("\(viewModel.targetReps)", value: $viewModel.targetReps, in: 1...30)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    Button {
                        Task {
                            await viewModel.addExerciseToSession()
                            onExerciseAdded()
                        }
                    } label: {
                        HStack {
                            if viewModel.isAdding {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "plus.circle.fill")
                            }
                            Text("Add to Today's Session")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isAdding)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .background(Color(.systemBackground))
            }
        }
        .navigationTitle("Add Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .task {
            await viewModel.loadExercises()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }
}

// MARK: - Exercise Picker Row (for Add to Today)

struct AddExercisePickerRow: View {
    let exercise: AddExerciseItem
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        if let category = exercise.category {
                            Text(category)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }

                        if let bodyRegion = exercise.bodyRegion {
                            Text(bodyRegion)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
    }
}

// MARK: - View Model

@MainActor
class AddExerciseViewModel: ObservableObject {
    @Published var exercises: [AddExerciseItem] = []
    @Published var searchText = ""
    @Published var selectedExercise: AddExerciseItem?
    @Published var targetSets = 3
    @Published var targetReps = 10
    @Published var isLoading = false
    @Published var isAdding = false
    @Published var showError = false
    @Published var errorMessage: String?

    private let supabase = PTSupabaseClient.shared

    var filteredExercises: [AddExerciseItem] {
        if searchText.isEmpty {
            return exercises
        }
        return exercises.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.category?.localizedCaseInsensitiveContains(searchText) == true ||
            $0.bodyRegion?.localizedCaseInsensitiveContains(searchText) == true
        }
    }

    func loadExercises() async {
        isLoading = true
        do {
            let response = try await supabase.client
                .from("exercise_templates")
                .select("id, name, category, body_region")
                .order("name", ascending: true)
                .limit(200)
                .execute()

            let decoder = JSONDecoder()
            exercises = try decoder.decode([AddExerciseItem].self, from: response.data)
            isLoading = false
        } catch {
            errorMessage = "Failed to load exercises: \(error.localizedDescription)"
            showError = true
            isLoading = false
        }
    }

    func addExerciseToSession() async {
        guard let exercise = selectedExercise else { return }
        guard let patientId = supabase.userId else {
            errorMessage = "Not logged in"
            showError = true
            return
        }

        isAdding = true

        do {
            // Get today's scheduled session
            let today = ISO8601DateFormatter().string(from: Date()).prefix(10)

            let scheduledResponse = try await supabase.client
                .from("scheduled_sessions")
                .select("session_id")
                .eq("patient_id", value: patientId)
                .eq("scheduled_date", value: String(today))
                .eq("status", value: "scheduled")
                .limit(1)
                .execute()

            struct ScheduledRow: Codable {
                let session_id: String
            }

            let scheduled = try JSONDecoder().decode([ScheduledRow].self, from: scheduledResponse.data)

            guard let sessionId = scheduled.first?.session_id else {
                errorMessage = "No session scheduled for today"
                showError = true
                isAdding = false
                return
            }

            // Get the max sequence for existing exercises
            let seqResponse = try await supabase.client
                .from("session_exercises")
                .select("sequence")
                .eq("session_id", value: sessionId)
                .order("sequence", ascending: false)
                .limit(1)
                .execute()

            struct SeqRow: Codable {
                let sequence: Int
            }

            let sequences = try JSONDecoder().decode([SeqRow].self, from: seqResponse.data)
            let nextSequence = (sequences.first?.sequence ?? 0) + 1

            // Insert the new exercise
            struct NewExercise: Codable {
                let session_id: String
                let exercise_template_id: String
                let sequence: Int
                let prescribed_sets: Int
                let prescribed_reps: Int
                let notes: String?
            }

            let newExercise = NewExercise(
                session_id: sessionId,
                exercise_template_id: exercise.id.uuidString,
                sequence: nextSequence,
                prescribed_sets: targetSets,
                prescribed_reps: targetReps,
                notes: "Added manually"
            )

            _ = try await supabase.client
                .from("session_exercises")
                .insert(newExercise)
                .execute()

            DebugLogger.shared.log("Added exercise \(exercise.name) to session \(sessionId)", level: .success)
            isAdding = false

        } catch {
            errorMessage = "Failed to add exercise: \(error.localizedDescription)"
            showError = true
            isAdding = false
        }
    }
}

// MARK: - Exercise Item (simplified for picker, avoids conflict with AddExerciseItem model)

struct AddExerciseItem: Codable, Identifiable {
    let id: UUID
    let name: String
    let category: String?
    let bodyRegion: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case bodyRegion = "body_region"
    }
}
