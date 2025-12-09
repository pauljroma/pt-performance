//
//  PatientListViewModel.swift
//  PTPerformance
//
//  ViewModel for therapist patient list with workload flags
//

import Foundation
import SwiftUI

@MainActor
class PatientListViewModel: ObservableObject {
    @Published var patients: [Patient] = []
    @Published var activeFlags: [WorkloadFlag] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    @Published var selectedFlagFilter: FlagFilter = .all
    @Published var selectedSport: String? = nil

    private let supabase = SupabaseClient.shared

    enum FlagFilter: String, CaseIterable {
        case all = "All"
        case high = "High Risk"
        case medium = "Medium Risk"
        case low = "Low Risk"
    }

    var availableSports: [String] {
        Array(Set(patients.compactMap { $0.sport })).sorted()
    }

    var filteredPatients: [Patient] {
        if searchText.isEmpty {
            return patients
        }
        return patients.filter { patient in
            patient.fullName.localizedCaseInsensitiveContains(searchText) ||
            patient.email.localizedCaseInsensitiveContains(searchText) ||
            (patient.sport?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    func applyFilters() {
        // Filters are computed via filteredPatients
    }

    func loadPatients() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response: [Patient] = try await supabase.client
                .from("patients")
                .select()
                .execute()
                .value

            patients = response
            print("✅ [PatientList] Loaded \(patients.count) patients from Supabase")
        } catch {
            print("❌ [PatientList] Error loading patients: \(error.localizedDescription)")
            errorMessage = "Failed to load patients: \(error.localizedDescription)"
            // Fallback to sample data only if query fails
            patients = Patient.samplePatients
        }
    }

    func loadActiveFlags() async {
        do {
            let response: [WorkloadFlag] = try await supabase.client
                .from("workload_flags")
                .select()
                .eq("resolved", value: false)
                .order("severity", ascending: false)
                .order("created_at", ascending: false)
                .limit(10)
                .execute()
                .value

            activeFlags = response
            print("✅ [PatientList] Loaded \(activeFlags.count) active flags from Supabase")
        } catch {
            print("❌ [PatientList] Error loading flags: \(error.localizedDescription)")
            // Fallback to empty array if query fails
            activeFlags = []
        }
    }
    
    func refresh() async {
        await loadPatients()
        await loadActiveFlags()
    }

    func fetchPatients(for therapistId: String) async {
        await loadPatients()
    }

    func patient(for patientId: UUID) -> Patient? {
        patients.first { $0.id == patientId.uuidString }
    }
}
