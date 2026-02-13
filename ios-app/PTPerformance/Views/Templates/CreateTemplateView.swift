//
//  CreateTemplateView.swift
//  PTPerformance
//
//  Created by Build 46 Swarm Agent 2
//  Create new workout template from scratch or existing program
//

import SwiftUI

struct CreateTemplateView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @State private var templateName = ""
    @State private var templateDescription = ""
    @State private var selectedCategory: WorkoutTemplate.TemplateCategory = .strength
    @State private var selectedDifficulty: WorkoutTemplate.DifficultyLevel = .intermediate
    @State private var durationWeeks: Int?
    @State private var isPublic = false
    @State private var tags: [String] = []
    @State private var newTag = ""

    @State private var creationMode: CreationMode = .fromScratch
    @State private var selectedProgram: Program?

    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var showingSuccessAlert = false

    enum CreationMode {
        case fromScratch
        case fromProgram
    }

    var body: some View {
        NavigationStack {
            Form {
                // Creation mode selector
                modeSection

                // Basic info
                basicInfoSection

                // Category and difficulty
                classificationSection

                // Duration
                durationSection

                // Tags
                tagsSection

                // Visibility
                visibilitySection

                // Error message
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Create Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: createTemplate) {
                        if isCreating {
                            ProgressView()
                        } else {
                            Text("Create")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isFormValid || isCreating)
                }
            }
            .alert("Template Created", isPresented: $showingSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your template \"\(templateName)\" has been created successfully")
            }
        }
    }

    // MARK: - Mode Section

    private var modeSection: some View {
        Section {
            Picker("Create From", selection: $creationMode) {
                Text("From Scratch").tag(CreationMode.fromScratch)
                Text("From Existing Program").tag(CreationMode.fromProgram)
            }
            .pickerStyle(SegmentedPickerStyle())

            if creationMode == .fromProgram {
                // Program selector
                Text("Program picker coming soon")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        } header: {
            Text("Creation Mode")
        } footer: {
            if creationMode == .fromProgram {
                Text("Converting an existing program will copy its structure and exercises into a reusable template")
                    .font(.caption)
            }
        }
    }

    // MARK: - Basic Info Section

    private var basicInfoSection: some View {
        Section("Basic Information") {
            TextField("Template Name", text: $templateName)
                .textInputAutocapitalization(.words)
                .accessibilityLabel("Template Name")
                .accessibilityHint("Enter a name for this template")

            TextField("Description", text: $templateDescription, axis: .vertical)
                .lineLimit(3...6)
                .accessibilityLabel("Template Description")
                .accessibilityHint("Optional description for the template")
        }
    }

    // MARK: - Classification Section

    private var classificationSection: some View {
        Section("Classification") {
            Picker("Category", selection: $selectedCategory) {
                ForEach(WorkoutTemplate.TemplateCategory.allCases, id: \.self) { category in
                    HStack {
                        Image(systemName: category.icon)
                        Text(category.displayName)
                    }
                    .tag(category)
                }
            }

            Picker("Difficulty Level", selection: $selectedDifficulty) {
                ForEach(WorkoutTemplate.DifficultyLevel.allCases, id: \.self) { difficulty in
                    HStack {
                        Image(systemName: difficulty.icon)
                        Text(difficulty.displayName)
                    }
                    .tag(difficulty)
                }
            }
        }
    }

    // MARK: - Duration Section

    private var durationSection: some View {
        Section {
            HStack {
                Text("Duration (weeks)")
                Spacer()

                TextField("Weeks", value: $durationWeeks, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
            }
        } header: {
            Text("Duration")
        } footer: {
            Text("Leave empty for variable duration programs")
                .font(.caption)
        }
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        Section {
            // Existing tags
            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            TagChip(
                                text: tag,
                                onRemove: {
                                    tags.removeAll { $0 == tag }
                                }
                            )
                        }
                    }
                }
            }

            // Add new tag
            HStack {
                TextField("Add tag", text: $newTag)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Button(action: addTag) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
                .disabled(newTag.isEmpty)
            }
        } header: {
            Text("Tags")
        } footer: {
            Text("Add tags to make your template easier to find")
                .font(.caption)
        }
    }

    // MARK: - Visibility Section

    private var visibilitySection: some View {
        Section {
            Toggle("Make Public", isOn: $isPublic)
                .accessibilityLabel("Make template public")
                .accessibilityHint(isPublic ? "Template is visible to all therapists" : "Template is only visible to you")
        } header: {
            Text("Visibility")
        } footer: {
            Text("Public templates can be used by all therapists. Private templates are only visible to you.")
                .font(.caption)
        }
    }

    // MARK: - Form Validation

    private var isFormValid: Bool {
        !templateName.isEmpty &&
        (creationMode == .fromScratch || selectedProgram != nil)
    }

    // MARK: - Actions

    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty, !tags.contains(trimmedTag) else { return }

        tags.append(trimmedTag)
        newTag = ""
    }

    private func createTemplate() {
        isCreating = true
        errorMessage = nil

        Task {
            do {
                guard let userId = appState.userId else {
                    await MainActor.run {
                        errorMessage = "You must be logged in to create a template."
                        isCreating = false
                    }
                    return
                }

                let _ = try await TemplatesService.shared.createTemplate(
                    name: templateName,
                    description: templateDescription.isEmpty ? nil : templateDescription,
                    category: selectedCategory,
                    difficultyLevel: selectedDifficulty,
                    durationWeeks: durationWeeks,
                    createdBy: userId,
                    isPublic: isPublic,
                    tags: tags
                )

                await MainActor.run {
                    isCreating = false
                    showingSuccessAlert = true
                }
            } catch {
                ErrorLogger.shared.logError(error, context: "CreateTemplateView.createTemplate")
                await MainActor.run {
                    isCreating = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Tag Chip

struct TagChip: View {
    let text: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.subheadline)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .accessibilityLabel("Remove tag \(text)")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Preview

struct CreateTemplateView_Previews: PreviewProvider {
    static var previews: some View {
        CreateTemplateView()
    }
}
