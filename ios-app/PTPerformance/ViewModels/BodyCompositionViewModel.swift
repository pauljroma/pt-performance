//
//  BodyCompositionViewModel.swift
//  PTPerformance
//
//  Body Composition tracking ViewModel (ACP-510, ACP-509)
//

import SwiftUI

/// ViewModel for body composition entry form and timeline
@MainActor
class BodyCompositionViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var entries: [BodyComposition] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var showingSuccessAlert = false

    // MARK: - Form Fields (as Strings for TextField binding)

    @Published var weightLb: String = ""
    @Published var bodyFatPercent: String = ""
    @Published var muscleMassLb: String = ""
    @Published var waistIn: String = ""
    @Published var chestIn: String = ""
    @Published var armIn: String = ""
    @Published var legIn: String = ""
    @Published var notes: String = ""

    // MARK: - Private Properties

    private let supabase = PTSupabaseClient.shared

    // MARK: - Computed Properties (Statistics)

    /// Latest recorded weight
    var latestWeight: Double? {
        entries.first(where: { $0.weightLb != nil })?.weightLb
    }

    /// Average weight across all entries
    var averageWeight: Double? {
        let weights = entries.compactMap { $0.weightLb }
        guard !weights.isEmpty else { return nil }
        return weights.reduce(0, +) / Double(weights.count)
    }

    /// Minimum recorded weight
    var minWeight: Double? {
        entries.compactMap { $0.weightLb }.min()
    }

    /// Maximum recorded weight
    var maxWeight: Double? {
        entries.compactMap { $0.weightLb }.max()
    }

    /// Latest body fat percentage
    var latestBodyFat: Double? {
        entries.first(where: { $0.bodyFatPercent != nil })?.bodyFatPercent
    }

    /// Average body fat percentage
    var averageBodyFat: Double? {
        let values = entries.compactMap { $0.bodyFatPercent }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    /// Latest muscle mass
    var latestMuscleMass: Double? {
        entries.first(where: { $0.muscleMassLb != nil })?.muscleMassLb
    }

    /// Average muscle mass
    var averageMuscleMass: Double? {
        let values = entries.compactMap { $0.muscleMassLb }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    /// Whether the form has at least one numeric value filled in
    var hasValidInput: Bool {
        !weightLb.isEmpty || !bodyFatPercent.isEmpty || !muscleMassLb.isEmpty ||
        !waistIn.isEmpty || !chestIn.isEmpty || !armIn.isEmpty || !legIn.isEmpty
    }

    // MARK: - Data Loading

    /// Fetch body composition entries for a patient
    func loadEntries(patientId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let results: [BodyComposition] = try await supabase.client
                .from("body_compositions")
                .select()
                .eq("patient_id", value: patientId)
                .order("recorded_at", ascending: false)
                .limit(100)
                .execute()
                .value

            entries = results
            isLoading = false
        } catch {
            errorMessage = "We couldn't load your measurements. Please check your connection and try again."
            isLoading = false
            ErrorLogger.shared.logError(error, context: "Load Body Composition Entries")
        }
    }

    // MARK: - Save Entry

    /// Save a new body composition entry
    func saveEntry(patientId: String) async {
        // Validate that at least one numeric field is filled
        guard hasValidInput else {
            errorMessage = "Please fill in at least one measurement."
            return
        }

        // Validate numeric fields
        if !weightLb.isEmpty, Double(weightLb) == nil {
            errorMessage = "Please enter a valid number for weight (e.g., 150)."
            return
        }
        if !bodyFatPercent.isEmpty, Double(bodyFatPercent) == nil {
            errorMessage = "Please enter a valid number for body fat percentage (e.g., 15.5)."
            return
        }
        if !muscleMassLb.isEmpty, Double(muscleMassLb) == nil {
            errorMessage = "Please enter a valid number for muscle mass (e.g., 120)."
            return
        }
        if !waistIn.isEmpty, Double(waistIn) == nil {
            errorMessage = "Please enter a valid number for waist measurement (e.g., 32)."
            return
        }
        if !chestIn.isEmpty, Double(chestIn) == nil {
            errorMessage = "Please enter a valid number for chest measurement (e.g., 40)."
            return
        }
        if !armIn.isEmpty, Double(armIn) == nil {
            errorMessage = "Please enter a valid number for arm measurement (e.g., 14)."
            return
        }
        if !legIn.isEmpty, Double(legIn) == nil {
            errorMessage = "Please enter a valid number for leg measurement (e.g., 22)."
            return
        }

        guard let patientUUID = UUID(uuidString: patientId) else {
            errorMessage = "We couldn't identify your account. Please try signing out and back in."
            return
        }

        isSaving = true
        errorMessage = nil

        let weight = Double(weightLb)
        let bodyFat = Double(bodyFatPercent)
        let muscleMass = Double(muscleMassLb)
        let waist = Double(waistIn)
        let chest = Double(chestIn)
        let arm = Double(armIn)
        let leg = Double(legIn)

        // Calculate BMI if weight is provided (using a default height assumption is not ideal,
        // so we only set BMI if it can be externally computed; leave nil for now)
        let insertDTO = BodyCompositionInsert(
            patientId: patientUUID,
            recordedAt: Date(),
            weightLb: weight,
            bodyFatPercent: bodyFat,
            muscleMassLb: muscleMass,
            bmi: nil,
            waistIn: waist,
            chestIn: chest,
            armIn: arm,
            legIn: leg,
            notes: notes.isEmpty ? nil : notes
        )

        do {
            try await supabase.client
                .from("body_compositions")
                .insert(insertDTO)
                .execute()

            isSaving = false
            showingSuccessAlert = true
            resetForm()

            // Reload entries to include the new one
            await loadEntries(patientId: patientId)
        } catch {
            isSaving = false
            errorMessage = "We couldn't save your measurements. Please check your connection and try again."
            ErrorLogger.shared.logError(error, context: "Save Body Composition Entry")
        }
    }

    // MARK: - Delete Entry

    /// Delete a body composition entry by ID
    func deleteEntry(id: UUID) async {
        do {
            try await supabase.client
                .from("body_compositions")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()

            // Remove from local array
            entries.removeAll { $0.id == id }
        } catch {
            errorMessage = "We couldn't delete this entry. Please try again."
            ErrorLogger.shared.logError(error, context: "Delete Body Composition Entry")
        }
    }

    // MARK: - Reset Form

    /// Clear all form fields
    func resetForm() {
        weightLb = ""
        bodyFatPercent = ""
        muscleMassLb = ""
        waistIn = ""
        chestIn = ""
        armIn = ""
        legIn = ""
        notes = ""
    }
}
