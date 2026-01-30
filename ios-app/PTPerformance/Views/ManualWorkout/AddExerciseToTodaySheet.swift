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

            // Category filter chips
            if !viewModel.availableCategories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All Categories", isSelected: viewModel.selectedCategory == nil) {
                            viewModel.selectedCategory = nil
                        }
                        ForEach(viewModel.availableCategories, id: \.self) { category in
                            FilterChip(label: category, isSelected: viewModel.selectedCategory == category) {
                                viewModel.selectedCategory = viewModel.selectedCategory == category ? nil : category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 4)
            }

            // Body region filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(label: "All Regions", color: .green, isSelected: viewModel.selectedBodyRegion == nil) {
                        viewModel.selectedBodyRegion = nil
                    }
                    ForEach(viewModel.bodyRegions, id: \.self) { region in
                        FilterChip(label: region, color: .green, isSelected: viewModel.selectedBodyRegion == region) {
                            viewModel.selectedBodyRegion = viewModel.selectedBodyRegion == region ? nil : region
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 8)

            // Exercise list
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading exercises...")
                Spacer()
            } else if viewModel.filteredExercises.isEmpty {
                let hasFilters = viewModel.selectedCategory != nil || viewModel.selectedBodyRegion != nil
                EmptyStateView(
                    title: "No Exercises Found",
                    message: hasFilters
                        ? "No exercises match your current filters. Try adjusting your category or body region selection."
                        : "No exercises match your search. Try a different search term.",
                    icon: "figure.run",
                    iconColor: .secondary,
                    action: hasFilters ? EmptyStateView.EmptyStateAction(
                        title: "Clear Filters",
                        icon: "xmark.circle",
                        action: {
                            viewModel.selectedCategory = nil
                            viewModel.selectedBodyRegion = nil
                        }
                    ) : nil
                )
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
    @Published var selectedCategory: String? = nil
    @Published var selectedBodyRegion: String? = nil
    @Published var selectedExercise: AddExerciseItem?
    @Published var targetSets = 3
    @Published var targetReps = 10
    @Published var isLoading = false
    @Published var isAdding = false
    @Published var showError = false
    @Published var errorMessage: String?

    private let supabase = PTSupabaseClient.shared

    /// Available categories extracted from exercises
    var availableCategories: [String] {
        let cats = Set(exercises.compactMap { $0.category?.capitalized })
        return cats.sorted()
    }

    /// Available body regions for filtering
    let bodyRegions = ["Upper", "Lower", "Core", "Full Body"]

    var filteredExercises: [AddExerciseItem] {
        var result = exercises

        // Category filter
        if let category = selectedCategory {
            result = result.filter { $0.category?.localizedCaseInsensitiveCompare(category) == .orderedSame }
        }

        // Body region filter
        if let region = selectedBodyRegion {
            result = result.filter { exercise in
                guard let bodyRegion = exercise.bodyRegion else { return false }
                return bodyRegion.localizedCaseInsensitiveContains(region)
            }
        }

        // Search text filter
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.category?.localizedCaseInsensitiveContains(searchText) == true ||
                $0.bodyRegion?.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        return result
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
            // Step 1: Try scheduled_sessions first
            let today = ISO8601DateFormatter().string(from: Date()).prefix(10)
            var sessionId: String? = nil

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
            sessionId = scheduled.first?.session_id

            // Step 2: Fallback to program-based session lookup
            if sessionId == nil {
                #if DEBUG
                print("📱 [AddToToday] No scheduled session, trying program-based lookup")
                #endif

                struct ProgramSession: Codable {
                    let id: String
                    let name: String
                }

                let programResponse = try await supabase.client
                    .from("sessions")
                    .select("""
                        id,
                        name,
                        phases!inner(
                            id,
                            programs!inner(
                                id,
                                patient_id,
                                status
                            )
                        )
                    """)
                    .eq("phases.programs.patient_id", value: patientId)
                    .eq("phases.programs.status", value: "active")
                    .order("sequence", ascending: true)
                    .limit(1)
                    .execute()

                let programSessions = try JSONDecoder().decode([ProgramSession].self, from: programResponse.data)
                sessionId = programSessions.first?.id

                if let id = sessionId {
                    #if DEBUG
                    print("✅ [AddToToday] Found program-based session: \(id)")
                    #endif
                }
            }

            guard let sessionId = sessionId else {
                errorMessage = "No active session found for today. Make sure you have an active program assigned."
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

#if DEBUG
            print("✅ [AddToToday] Added exercise \(exercise.name) to session \(sessionId)")
            #endif
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
