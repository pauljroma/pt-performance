//
//  ExerciseTemplatePicker.swift
//  PTPerformance
//
//  Build 88: Component for selecting exercise templates when building sessions
//

import SwiftUI

/// Component for selecting exercises from templates with multi-selection support
struct ExerciseTemplatePicker: View {
    @Binding var selectedExercises: [Exercise]
    @Environment(\.dismiss) private var dismiss

    @State private var availableTemplates: [ExerciseTemplateData] = []
    @State private var searchText = ""
    @State private var selectedCategory: String = "All"
    @State private var isLoading = false
    @State private var error: String?
    @State private var selectedTemplateIds = Set<UUID>()

    private let logger = DebugLogger.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView("Loading exercises...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Error loading exercises")
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task {
                                await loadTemplates()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(categories, id: \.self) { category in
                                Button {
                                    selectedCategory = category
                                } label: {
                                    Text(category)
                                        .font(.subheadline)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedCategory == category
                                                ? Color.blue
                                                : Color.gray.opacity(0.2)
                                        )
                                        .foregroundColor(
                                            selectedCategory == category
                                                ? .white
                                                : .primary
                                        )
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                    .background(Color(uiColor: .systemGroupedBackground))

                    // Exercise list
                    List {
                        if filteredTemplates.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("No exercises found")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if !searchText.isEmpty {
                                    Text("Try adjusting your search")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ForEach(filteredTemplates, id: \.id) { template in
                                TemplateSelectionRow(
                                    template: template,
                                    isSelected: selectedTemplateIds.contains(template.id)
                                ) {
                                    toggleSelection(template)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Select Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add (\(selectedTemplateIds.count))") {
                        addSelectedExercises()
                    }
                    .disabled(selectedTemplateIds.isEmpty)
                }
            }
            .task {
                await loadTemplates()
            }
        }
    }

    // MARK: - Computed Properties

    private var categories: [String] {
        var cats = Set<String>()
        for template in availableTemplates {
            if let category = template.category {
                cats.insert(category.capitalized)
            }
        }
        return ["All"] + cats.sorted()
    }

    private var filteredTemplates: [ExerciseTemplateData] {
        var templates = availableTemplates

        // Filter by category
        if selectedCategory != "All" {
            templates = templates.filter { template in
                template.category?.capitalized == selectedCategory
            }
        }

        // Filter by search text
        if !searchText.isEmpty {
            templates = templates.filter { template in
                template.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        return templates.sorted { $0.name < $1.name }
    }

    // MARK: - Data Loading

    private func loadTemplates() async {
        isLoading = true
        error = nil

        do {
            logger.info("DEBUG", "📚 Loading exercise templates")

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let result = try await PTSupabaseClient.shared.client
                .from("exercise_templates")
                .select()
                .order("name")
                .execute()

            let templates = try decoder.decode([ExerciseTemplateData].self, from: result.data)

            await MainActor.run {
                self.availableTemplates = templates
                self.isLoading = false
                logger.success("DEBUG", "✅ Loaded \(templates.count) exercise templates")
            }
        } catch {
            logger.error("DEBUG", "❌ Failed to load exercise templates: \(error)")
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    // MARK: - Selection Logic

    private func toggleSelection(_ template: ExerciseTemplateData) {
        if selectedTemplateIds.contains(template.id) {
            selectedTemplateIds.remove(template.id)
        } else {
            selectedTemplateIds.insert(template.id)
        }
    }

    private func addSelectedExercises() {
        logger.info("DEBUG", "➕ Adding \(selectedTemplateIds.count) exercises to session")

        // Convert selected templates to Exercise objects
        let newExercises = availableTemplates
            .filter { selectedTemplateIds.contains($0.id) }
            .enumerated()
            .map { index, template in
                createExerciseFromTemplate(template, sequence: selectedExercises.count + index + 1)
            }

        // Append to existing exercises
        selectedExercises.append(contentsOf: newExercises)

        logger.success("DEBUG", "✅ Added \(newExercises.count) exercises")
        dismiss()
    }

    private func createExerciseFromTemplate(_ template: ExerciseTemplateData, sequence: Int) -> Exercise {
        // Create an exercise from the template with default values
        // session_id uses a placeholder UUID — it will be replaced when the session is persisted
        Exercise(
            id: UUID(),
            session_id: UUID(),
            exercise_template_id: template.id,
            sequence: sequence,
            target_sets: 3,
            target_reps: 10,
            prescribed_sets: nil,
            prescribed_reps: "10",
            prescribed_load: nil,
            load_unit: "lbs",
            rest_period_seconds: 90,
            notes: nil,
            exercise_templates: Exercise.ExerciseTemplate(
                id: template.id,
                name: template.name,
                category: template.category,
                body_region: template.bodyRegion,
                videoUrl: template.videoUrl,
                videoThumbnailUrl: template.videoThumbnailUrl,
                videoDuration: template.videoDuration,
                formCues: template.formCues?.map { cue in
                    Exercise.ExerciseTemplate.FormCue(cue: cue.cue, timestamp: cue.timestamp)
                },
                techniqueCues: nil,
                commonMistakes: nil,
                safetyNotes: nil
            )
        )
    }
}

// MARK: - Template Selection Row

struct TemplateSelectionRow: View {
    let template: ExerciseTemplateData
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Exercise thumbnail with caching
                ExerciseThumbnailImage(
                    thumbnailUrl: template.videoThumbnailUrl,
                    exerciseName: template.name,
                    size: 50
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text(template.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        if let category = template.category {
                            Text(category.capitalized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if let bodyRegion = template.bodyRegion {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(bodyRegion.capitalized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if template.videoUrl != nil {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Image(systemName: "play.circle.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ExerciseTemplatePicker(selectedExercises: .constant([]))
}
