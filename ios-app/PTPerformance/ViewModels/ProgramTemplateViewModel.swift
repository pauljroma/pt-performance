//
//  ProgramTemplateViewModel.swift
//  PTPerformance
//
//  ViewModel for managing program templates with local storage
//

import Foundation
import SwiftUI

@MainActor
class ProgramTemplateViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var templates: [ProgramTemplate] = []
    @Published var searchText: String = ""
    @Published var selectedProgramType: ProgramType? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    // MARK: - Private Properties

    private let userDefaultsKey = "pt_performance_program_templates"

    // MARK: - Computed Properties

    /// Templates filtered by search text and program type
    var filteredTemplates: [ProgramTemplate] {
        var result = templates

        // Filter by program type if selected
        if let programType = selectedProgramType {
            result = result.filter { $0.programType == programType }
        }

        // Filter by search text
        if !searchText.isEmpty {
            let lowercasedSearch = searchText.lowercased()
            result = result.filter { template in
                template.name.lowercased().contains(lowercasedSearch) ||
                template.description.lowercased().contains(lowercasedSearch) ||
                template.phases.contains { $0.name.lowercased().contains(lowercasedSearch) }
            }
        }

        // Sort by most recently updated
        return result.sorted { $0.updatedAt > $1.updatedAt }
    }

    /// Check if there are any templates
    var hasTemplates: Bool {
        !templates.isEmpty
    }

    /// Check if filtered results are empty
    var isFilteredEmpty: Bool {
        filteredTemplates.isEmpty && hasTemplates
    }

    // MARK: - Initialization

    init() {
        loadTemplates()
    }

    // MARK: - CRUD Operations

    /// Load templates from UserDefaults
    func loadTemplates() {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            // First launch - load sample templates
            templates = ProgramTemplate.sampleTemplates
            saveTemplates()
            return
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            templates = try decoder.decode([ProgramTemplate].self, from: data)
        } catch {
            errorMessage = "We couldn't load your templates. Using default templates instead."
            // Fall back to sample templates on error
            templates = ProgramTemplate.sampleTemplates
        }
    }

    /// Save templates to UserDefaults
    private func saveTemplates() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(templates)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            errorMessage = "We couldn't save your templates. Please try again."
        }
    }

    /// Save a new template from current program builder state
    func saveTemplate(
        name: String,
        description: String,
        programType: ProgramType,
        phases: [ProgramPhase],
        createdBy: String? = nil
    ) {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a name for your template."
            return
        }

        // Convert ProgramPhase to ProgramTemplatePhase
        let templatePhases = phases.enumerated().map { index, phase in
            ProgramTemplatePhase(
                name: phase.name,
                durationWeeks: phase.durationWeeks,
                goals: nil,
                sessionCount: phase.sessions.count,
                order: index + 1
            )
        }

        let template = ProgramTemplate(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            programType: programType,
            phases: templatePhases,
            createdBy: createdBy,
            isShared: false
        )

        templates.append(template)
        saveTemplates()
        successMessage = "Template '\(template.name)' saved successfully"
    }

    /// Update an existing template
    func updateTemplate(_ template: ProgramTemplate) {
        guard let index = templates.firstIndex(where: { $0.id == template.id }) else {
            errorMessage = "We couldn't find that template. It may have been deleted."
            return
        }

        var updatedTemplate = template
        updatedTemplate.updatedAt = Date()
        templates[index] = updatedTemplate
        saveTemplates()
        successMessage = "Template updated successfully"
    }

    /// Delete a template
    func deleteTemplate(_ template: ProgramTemplate) {
        templates.removeAll { $0.id == template.id }
        saveTemplates()
        successMessage = "Template deleted"
    }

    /// Delete templates at specified offsets (for swipe-to-delete)
    func deleteTemplates(at offsets: IndexSet) {
        // Map offsets from filtered list to actual templates
        let templatesToDelete = offsets.map { filteredTemplates[$0] }
        for template in templatesToDelete {
            templates.removeAll { $0.id == template.id }
        }
        saveTemplates()
    }

    /// Toggle shared status
    func toggleShared(_ template: ProgramTemplate) {
        guard let index = templates.firstIndex(where: { $0.id == template.id }) else {
            return
        }

        templates[index].isShared.toggle()
        templates[index].updatedAt = Date()
        saveTemplates()
    }

    // MARK: - Create Program from Template

    /// Convert a template back to ProgramPhase array for the builder
    func createPhasesFromTemplate(_ template: ProgramTemplate) -> [ProgramPhase] {
        template.phases.map { templatePhase in
            ProgramPhase(
                name: templatePhase.name,
                durationWeeks: templatePhase.durationWeeks,
                sessions: [],
                order: templatePhase.order
            )
        }
    }

    // MARK: - Filter Management

    /// Clear all filters
    func clearFilters() {
        searchText = ""
        selectedProgramType = nil
    }

    /// Reset to sample templates (for debugging/testing)
    func resetToSampleTemplates() {
        templates = ProgramTemplate.sampleTemplates
        saveTemplates()
        successMessage = "Templates reset to defaults"
    }
}
