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

    private let supabase = PTSupabaseClient.shared

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

    func loadPatients(therapistId: String? = nil) async {
        isLoading = true
        defer { isLoading = false }

        let logger = DebugLogger.shared

        logger.log("Starting loadPatients...")
        logger.log("Therapist ID: \(therapistId ?? "nil")")

        do {
            var query = supabase.client
                .from("patients")
                .select()

            // Filter by therapist_id if provided
            if let therapistId = therapistId {
                query = query.eq("therapist_id", value: therapistId)
                logger.log("Filtering by therapist_id: \(therapistId)")
            }

            logger.log("Executing query...")

            // Execute and get response with data
            let response = try await query.execute()

            // Log raw response data
            logger.log("Response received", level: .success)
            logger.log("Response data size: \(response.data.count) bytes")
            if let jsonString = String(data: response.data, encoding: .utf8) {
                logger.log("Raw JSON (first 500 chars): \(jsonString.prefix(500))")
            }

            logger.log("Attempting to decode [Patient] from response data...")
            // Manually decode using the configured decoder from Supabase client
            // The decoder should be configured with .iso8601 date strategy
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decodedPatients = try decoder.decode([Patient].self, from: response.data)

            patients = decodedPatients
            logger.log("Successfully decoded \(patients.count) patients", level: .success)
            if let therapistId = therapistId {
                logger.log("Loaded \(patients.count) patients for therapist \(therapistId)", level: .success)
            } else {
                logger.log("Loaded \(patients.count) patients from Supabase", level: .success)
            }
        } catch let decodingError as DecodingError {
            logger.log("DECODING ERROR:", level: .error)
            switch decodingError {
            case .typeMismatch(let type, let context):
                logger.log("Type mismatch: Expected \(type)", level: .error)
                logger.log("Context: \(context.debugDescription)", level: .error)
                logger.log("Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))", level: .error)
            case .valueNotFound(let type, let context):
                logger.log("Value not found: \(type)", level: .error)
                logger.log("Context: \(context.debugDescription)", level: .error)
                logger.log("Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))", level: .error)
            case .keyNotFound(let key, let context):
                logger.log("Key not found: \(key.stringValue)", level: .error)
                logger.log("Context: \(context.debugDescription)", level: .error)
                logger.log("Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))", level: .error)
            case .dataCorrupted(let context):
                logger.log("Data corrupted", level: .error)
                logger.log("Context: \(context.debugDescription)", level: .error)
                logger.log("Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))", level: .error)
            @unknown default:
                logger.log("Unknown decoding error: \(decodingError)", level: .error)
            }
            errorMessage = "Decoding error: \(decodingError.localizedDescription)"
            patients = Patient.samplePatients
        } catch {
            logger.log("OTHER ERROR:", level: .error)
            logger.log("Error type: \(type(of: error))", level: .error)
            logger.log("Error description: \(error.localizedDescription)", level: .error)
            logger.log("Error: \(error)", level: .error)
            errorMessage = "Failed to load patients: \(error.localizedDescription)"
            patients = Patient.samplePatients
        }
    }

    func loadActiveFlags(therapistId: String? = nil) async {
        let logger = DebugLogger.shared

        do {
            // Filter workload flags by therapist through patient relationship
            if let therapistId = therapistId {
                logger.log("Loading workload flags for therapist \(therapistId)", level: .diagnostic)

                // Query with join to filter by therapist_id
                let response = try await supabase.client
                    .from("workload_flags")
                    .select("*, patient:patients!inner(therapist_id)")
                    .eq("resolved", value: false)
                    .eq("patient.therapist_id", value: therapistId)
                    .order("severity", ascending: false)
                    .order("created_at", ascending: false)
                    .limit(10)
                    .execute()

                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                activeFlags = try decoder.decode([WorkloadFlag].self, from: response.data)

                logger.log("✅ Loaded \(activeFlags.count) active flags for therapist", level: .success)
            } else {
                // Load all unresolved flags if no therapist specified
                logger.log("Loading all workload flags", level: .diagnostic)
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
                logger.log("✅ Loaded \(activeFlags.count) active flags", level: .success)
            }
        } catch {
            logger.log("❌ Error loading flags: \(error.localizedDescription)", level: .error)
            // Fallback to empty array if query fails
            activeFlags = []
        }
    }

    func refresh(therapistId: String? = nil) async {
        await loadPatients(therapistId: therapistId)
        await loadActiveFlags(therapistId: therapistId)
    }

    func fetchPatients(for therapistId: String) async {
        await loadPatients(therapistId: therapistId)
    }

    func patient(for patientId: UUID) -> Patient? {
        patients.first { $0.id == patientId.uuidString }
    }
}
