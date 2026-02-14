// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  ExercisePickerView.swift
//  PTPerformance
//
//  Build 60: Pick and add exercises to a session (ACP-114)
//

import SwiftUI

struct ExercisePickerView: View {
    let sessionId: String
    let availableExercises: [Exercise]
    let onExerciseAdded: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: String = "All"
    @State private var selectedBodyRegion: String = "All"
    @State private var isAdding = false
    @State private var error: String?

    /// Available body regions for filtering
    private let bodyRegionOptions = ["All", "Upper", "Lower", "Core", "Full Body"]

    private var categories: [String] {
        var cats = Set<String>()
        for exercise in availableExercises {
            if let category = exercise.exercise_templates?.category {
                cats.insert(category.capitalized)
            }
        }
        return ["All"] + cats.sorted()
    }

    private var filteredExercises: [Exercise] {
        var exercises = availableExercises

        // Filter by category
        if selectedCategory != "All" {
            exercises = exercises.filter { exercise in
                exercise.exercise_templates?.category?.capitalized == selectedCategory
            }
        }

        // Filter by body region
        if selectedBodyRegion != "All" {
            exercises = exercises.filter { exercise in
                guard let bodyRegion = exercise.exercise_templates?.body_region else { return false }
                return bodyRegion.localizedCaseInsensitiveContains(selectedBodyRegion)
            }
        }

        // Filter by search text
        if !searchText.isEmpty {
            exercises = exercises.filter { exercise in
                exercise.exercise_name?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }

        return exercises.sorted { ($0.exercise_name ?? "") < ($1.exercise_name ?? "") }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                Text(category)
                                    .font(.subheadline)
                                    .padding(.horizontal, Spacing.md)
                                    .padding(.vertical, Spacing.xs)
                                    .background(
                                        selectedCategory == category
                                            ? Color.modusCyan
                                            : Color.gray.opacity(0.2)
                                    )
                                    .foregroundColor(
                                        selectedCategory == category
                                            ? .white
                                            : .primary
                                    )
                                    .cornerRadius(CornerRadius.xl)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, Spacing.xs)
                }

                // Body region filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(bodyRegionOptions, id: \.self) { region in
                            Button {
                                selectedBodyRegion = region
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: bodyRegionIcon(for: region))
                                        .font(.caption)
                                    Text(region)
                                        .font(.subheadline)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, Spacing.xs)
                                .background(
                                    selectedBodyRegion == region
                                        ? Color.green
                                        : Color.gray.opacity(0.2)
                                )
                                .foregroundColor(
                                    selectedBodyRegion == region
                                        ? .white
                                        : .primary
                                )
                                .cornerRadius(CornerRadius.xl)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, Spacing.xs)
                }
                .background(Color(uiColor: .systemGroupedBackground))

                // Exercise list
                List {
                    if filteredExercises.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No exercises found")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if !searchText.isEmpty || selectedCategory != "All" || selectedBodyRegion != "All" {
                                Text("Try adjusting your search or filters")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                if selectedCategory != "All" || selectedBodyRegion != "All" {
                                    Button("Clear Filters") {
                                        selectedCategory = "All"
                                        selectedBodyRegion = "All"
                                    }
                                    .buttonStyle(.bordered)
                                    .font(.caption)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(filteredExercises) { exercise in
                            Button {
                                Task {
                                    await addExercise(exercise)
                                }
                            } label: {
                                ExercisePickerRow(exercise: exercise)
                            }
                            .disabled(isAdding)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if isAdding {
                    ZStack {
                        Color(.label).opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Adding exercise...")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        .padding(Spacing.lg)
                        .background(Color(.systemBackground))
                        .cornerRadius(CornerRadius.md)
                    }
                }
            }
            .alert("Error", isPresented: Binding(
                get: { error != nil },
                set: { if !$0 { error = nil } }
            )) {
                Button("OK") { error = nil }
            } message: {
                if let error = error {
                    Text(error)
                }
            }
        }
    }

    private func bodyRegionIcon(for region: String) -> String {
        switch region.lowercased() {
        case "upper": return "figure.arms.open"
        case "lower": return "figure.walk"
        case "core": return "figure.core.training"
        case "full body": return "figure.strengthtraining.traditional"
        default: return "list.bullet"
        }
    }

    private func addExercise(_ exercise: Exercise) async {
        let logger = DebugLogger.shared
        isAdding = true
        error = nil
        defer { isAdding = false }

        do {
            logger.log("➕ Adding exercise to session: \(exercise.exercise_name ?? "Unknown")")

            // Get current max sequence for this session
            let existingExercises = try await PTSupabaseClient.shared.client
                .from("session_exercises")
                .select("sequence")
                .eq("session_id", value: sessionId)
                .execute()

            let decoder = JSONDecoder()
            let sequences = try? decoder.decode([SequenceOnly].self, from: existingExercises.data)
            let maxSequence = sequences?.compactMap { $0.sequence }.max() ?? 0

            let newExercise = InsertExerciseInput(
                sessionId: sessionId,
                exerciseTemplateId: exercise.exercise_template_id.uuidString,
                sequence: maxSequence + 1,
                prescribedSets: 3,
                prescribedReps: "10",
                prescribedLoad: nil,
                loadUnit: "lbs",
                restPeriodSeconds: 90,
                notes: nil
            )

            try await PTSupabaseClient.shared.client
                .from("session_exercises")
                .insert(newExercise)
                .execute()

            logger.log("✅ Exercise added successfully", level: .success)

            // Call callback and dismiss
            onExerciseAdded()
            dismiss()
        } catch {
            logger.log("❌ Failed to add exercise: \(error)", level: .error)
            self.error = "Failed to add exercise: \(error.localizedDescription)"
        }
    }
}

struct ExercisePickerRow: View {
    let exercise: Exercise
    @State private var showTechniqueGuide = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.exercise_name ?? "Unknown Exercise")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    if let category = exercise.exercise_templates?.category {
                        Text(category.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let bodyRegion = exercise.exercise_templates?.body_region {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(bodyRegion.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Technique guide button
            Button {
                showTechniqueGuide = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)

            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundColor(.modusCyan)
        }
        .contentShape(Rectangle())
        .padding(.vertical, Spacing.xxs)
        .sheet(isPresented: $showTechniqueGuide) {
            ExerciseTechniqueView(exercise: exercise)
        }
    }
}

struct InsertExerciseInput: Codable {
    let sessionId: String
    let exerciseTemplateId: String
    let sequence: Int
    let prescribedSets: Int
    let prescribedReps: String
    let prescribedLoad: Double?
    let loadUnit: String?
    let restPeriodSeconds: Int?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case exerciseTemplateId = "exercise_template_id"
        case sequence
        case prescribedSets = "prescribed_sets"
        case prescribedReps = "prescribed_reps"
        case prescribedLoad = "prescribed_load"
        case loadUnit = "load_unit"
        case restPeriodSeconds = "rest_period_seconds"
        case notes
    }
}

struct SequenceOnly: Codable {
    let sequence: Int?
}

#Preview {
    ExercisePickerView(
        sessionId: UUID().uuidString,
        availableExercises: Exercise.sampleExercises,
        onExerciseAdded: {}
    )
}
