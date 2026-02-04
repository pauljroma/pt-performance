//
//  PrescribeWorkoutViewModel.swift
//  PTPerformance
//
//  ViewModel for prescribing workouts to patients
//

import SwiftUI
import Supabase

@MainActor
class PrescribeWorkoutViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var systemTemplates: [SystemWorkoutTemplate] = []
    @Published var selectedTemplate: SystemWorkoutTemplate?
    @Published var dueDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @Published var priority: PrescriptionPriority = .medium
    @Published var instructions: String = ""

    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var isSuccess = false

    @Published var searchText: String = ""

    // MARK: - Dependencies

    private let workoutService = ManualWorkoutService()
    private let supabase = PTSupabaseClient.shared
    private let logger = DebugLogger.shared

    // MARK: - Computed Properties

    var filteredTemplates: [SystemWorkoutTemplate] {
        if searchText.isEmpty {
            return systemTemplates
        }
        let lowercasedSearch = searchText.lowercased()
        return systemTemplates.filter { template in
            template.name.lowercased().contains(lowercasedSearch) ||
            (template.category?.lowercased().contains(lowercasedSearch) ?? false) ||
            (template.tags?.contains { $0.lowercased().contains(lowercasedSearch) } ?? false)
        }
    }

    var canSubmit: Bool {
        selectedTemplate != nil && !isSubmitting
    }

    // MARK: - Load Templates

    func loadTemplates() async {
        guard systemTemplates.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        logger.log("PrescribeWorkoutVM: Loading system templates...", level: .diagnostic)

        do {
            systemTemplates = try await workoutService.fetchSystemTemplates()
            logger.log("PrescribeWorkoutVM: Loaded \(systemTemplates.count) templates", level: .success)
        } catch {
            logger.log("PrescribeWorkoutVM: Failed to load templates: \(error.localizedDescription)", level: .error)
            errorMessage = "Failed to load workout templates. Please try again."
            ErrorLogger.shared.logError(error, context: "PrescribeWorkoutViewModel.loadTemplates")
        }

        isLoading = false
    }

    // MARK: - Prescription Creation

    func createPrescription(patientId: UUID, therapistId: UUID) async -> Bool {
        guard let template = selectedTemplate else {
            errorMessage = "Please select a workout template."
            return false
        }

        isSubmitting = true
        errorMessage = nil
        logger.log("PrescribeWorkoutVM: Creating prescription for patient \(patientId)", level: .diagnostic)

        do {
            let dto = CreatePrescriptionDTO(
                patientId: patientId,
                therapistId: therapistId,
                templateId: template.id,
                templateType: "system",
                name: template.name,
                instructions: instructions.isEmpty ? nil : instructions,
                dueDate: dueDate,
                priority: priority.rawValue
            )

            try await supabase.client
                .from("workout_prescriptions")
                .insert(dto)
                .execute()

            logger.log("PrescribeWorkoutVM: Prescription created successfully", level: .success)
            isSuccess = true
            isSubmitting = false
            return true
        } catch {
            logger.log("PrescribeWorkoutVM: Failed to create prescription: \(error.localizedDescription)", level: .error)
            errorMessage = "Failed to prescribe workout. Please try again."
            ErrorLogger.shared.logError(error, context: "PrescribeWorkoutViewModel.createPrescription", metadata: [
                "patient_id": patientId.uuidString,
                "template_id": template.id.uuidString
            ])
            isSubmitting = false
            return false
        }
    }

    // MARK: - Reset

    func reset() {
        selectedTemplate = nil
        dueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        priority = .medium
        instructions = ""
        searchText = ""
        errorMessage = nil
        isSuccess = false
    }
}
