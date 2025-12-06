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
        
        // TODO: Load from Supabase
        /*
        do {
            let response = try await supabase
                .from("patients")
                .select()
                .execute()
            
            patients = try JSONDecoder().decode([Patient].self, from: response.data)
        } catch {
            print("Error loading patients: \(error)")
        }
        */
        
        // For demo: use sample data
        patients = Patient.samplePatients
    }
    
    func loadActiveFlags() async {
        // TODO: Load from Supabase
        /*
        do {
            let response = try await supabase
                .from("workload_flags")
                .select()
                .eq("is_resolved", value: false)
                .order("severity", ascending: false)
                .order("timestamp", ascending: false)
                .execute()
            
            activeFlags = try JSONDecoder().decode([WorkloadFlag].self, from: response.data)
        } catch {
            print("Error loading flags: \(error)")
        }
        */
        
        // For demo: use sample data
        activeFlags = WorkloadFlag.sampleFlags
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
