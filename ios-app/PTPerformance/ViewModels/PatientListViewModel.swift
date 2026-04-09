//
//  PatientListViewModel.swift
//  PTPerformance
//
//  ViewModel for therapist patient list with workload flags
//

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

    // MARK: - Multi-Select State

    /// Whether multi-select mode is active
    @Published var isSelectionModeActive = false

    /// Set of selected patient IDs
    @Published var selectedPatientIds: Set<UUID> = []

    /// Available programs for bulk assignment
    @Published var availablePrograms: [DatabaseProgramTemplate] = []

    /// Loading state for bulk operations
    @Published var isBulkOperationInProgress = false

    /// Error message for bulk operations
    @Published var bulkOperationError: String?

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

    /// Whether the patient list is empty (after loading)
    var isEmpty: Bool {
        !isLoading && patients.isEmpty
    }

    /// Whether search returned no results
    var isSearchEmpty: Bool {
        !searchText.isEmpty && filteredPatients.isEmpty
    }

    /// Empty state message for UI display
    var emptyStateMessage: String {
        if errorMessage != nil {
            return errorMessage ?? "Unable to load patients."
        }
        if isSearchEmpty {
            return "No patients match '\(searchText)'. Try a different search term."
        }
        if isEmpty {
            return "You don't have any patients yet. Add a patient to get started."
        }
        return ""
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

        // SECURITY: Enforce therapist_id filter to prevent HIPAA violations
        // Therapists must ONLY see their assigned patients
        guard let therapistId = therapistId else {
            logger.log("❌ SECURITY VIOLATION: loadPatients called without therapist_id", level: .error)
            errorMessage = "Unable to verify your account. Please sign out and sign back in to view your patients."
            patients = []  // SECURITY: Never show patients without proper authorization
            return
        }

        do {
            // SECURITY: Always filter by therapist_id - no exceptions
            let query = supabase.client
                .from("patients")
                .select()
                .eq("therapist_id", value: therapistId)  // HIPAA compliance filter

            logger.log("Filtering by therapist_id: \(therapistId)")
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
            let decoder = PTSupabaseClient.flexibleDecoder
            let decodedPatients = try decoder.decode([Patient].self, from: response.data)

            patients = decodedPatients
            logger.log("Successfully decoded \(patients.count) patients", level: .success)
            logger.log("✅ Loaded \(patients.count) patients for therapist \(therapistId) (HIPAA compliant)", level: .success)
        } catch let decodingError as DecodingError {
            ErrorLogger.shared.logError(decodingError, context: "PatientListViewModel.loadPatients - decoding")
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
            errorMessage = "We couldn't load your patient list. Please check your internet connection and try again."
            patients = []  // SECURITY: Never fall back to sample data - show empty list on error
            logger.log("Set patients to empty array due to decoding error (security)", level: .error)
        } catch {
            ErrorLogger.shared.logError(error, context: "PatientListViewModel.loadPatients")
            logger.log("OTHER ERROR:", level: .error)
            logger.log("Error type: \(type(of: error))", level: .error)
            logger.log("Error description: \(error.localizedDescription)", level: .error)
            logger.log("Error: \(error)", level: .error)
            errorMessage = "We couldn't load your patient list. Please check your connection and try again."
            patients = []  // SECURITY: Never fall back to sample data - show empty list on error
            logger.log("Set patients to empty array due to error (security)", level: .error)
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
                    .eq("is_resolved", value: false)
                    .eq("patient.therapist_id", value: therapistId)
                    .order("severity", ascending: false)
                    .order("created_at", ascending: false)
                    .limit(10)
                    .execute()

                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase  // WorkloadFlag has no explicit CodingKeys
                decoder.dateDecodingStrategy = PTSupabaseClient.flexibleDecoder.dateDecodingStrategy

                // Handle empty array or missing data gracefully
                if response.data.isEmpty || String(data: response.data, encoding: .utf8) == "[]" {
                    activeFlags = []
                    logger.log("No workload flags found for therapist", level: .diagnostic)
                } else {
                    activeFlags = try decoder.decode([WorkloadFlag].self, from: response.data)
                    logger.log("✅ Loaded \(activeFlags.count) active flags for therapist", level: .success)
                }
            } else {
                // Load all unresolved flags if no therapist specified
                logger.log("Loading all workload flags", level: .diagnostic)
                let response: [WorkloadFlag] = try await supabase.client
                    .from("workload_flags")
                    .select()
                    .eq("is_resolved", value: false)
                    .order("severity", ascending: false)
                    .order("created_at", ascending: false)
                    .limit(10)
                    .execute()
                    .value

                activeFlags = response
                logger.log("✅ Loaded \(activeFlags.count) active flags", level: .success)
            }
        } catch {
            ErrorLogger.shared.logError(error, context: "PatientListViewModel.loadActiveFlags")
            logger.log("Error loading flags: \(error.localizedDescription)", level: .error)
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
        patients.first { $0.id == patientId }
    }

    // MARK: - Multi-Select Operations

    /// Toggle selection mode on/off
    func toggleSelectionMode() {
        isSelectionModeActive.toggle()
        if !isSelectionModeActive {
            // Clear selections when exiting selection mode
            selectedPatientIds.removeAll()
        }
    }

    /// Toggle selection state for a specific patient
    /// - Parameter patientId: The UUID of the patient to toggle
    func toggleSelection(patientId: UUID) {
        if selectedPatientIds.contains(patientId) {
            selectedPatientIds.remove(patientId)
        } else {
            selectedPatientIds.insert(patientId)
        }
    }

    /// Check if a patient is selected
    /// - Parameter patientId: The UUID of the patient to check
    /// - Returns: True if the patient is selected
    func isSelected(patientId: UUID) -> Bool {
        selectedPatientIds.contains(patientId)
    }

    /// Select all currently filtered patients
    func selectAll() {
        selectedPatientIds = Set(filteredPatients.map { $0.id })
    }

    /// Deselect all patients
    func deselectAll() {
        selectedPatientIds.removeAll()
    }

    /// Get the list of selected patients
    var selectedPatients: [Patient] {
        patients.filter { selectedPatientIds.contains($0.id) }
    }

    /// Number of selected patients
    var selectedCount: Int {
        selectedPatientIds.count
    }

    /// Whether all filtered patients are selected
    var allFilteredPatientsSelected: Bool {
        !filteredPatients.isEmpty && filteredPatients.allSatisfy { selectedPatientIds.contains($0.id) }
    }

    // MARK: - Bulk Operations

    /// Load available program templates for bulk assignment
    func loadAvailablePrograms(therapistId: String) async {
        let logger = DebugLogger.shared

        do {
            logger.log("Loading program templates for bulk assignment...")

            let response = try await supabase.client
                .from("program_templates")
                .select()
                .eq("therapist_id", value: therapistId)
                .order("name", ascending: true)
                .execute()

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = PTSupabaseClient.flexibleDecoder.dateDecodingStrategy

            if let jsonString = String(data: response.data, encoding: .utf8),
               jsonString != "[]" && !jsonString.isEmpty {
                availablePrograms = try decoder.decode([DatabaseProgramTemplate].self, from: response.data)
                logger.log("Loaded \(availablePrograms.count) program templates", level: .success)
            } else {
                availablePrograms = []
                logger.log("No program templates found", level: .diagnostic)
            }
        } catch {
            ErrorLogger.shared.logError(error, context: "PatientListViewModel.loadAvailablePrograms")
            logger.log("Failed to load program templates: \(error.localizedDescription)", level: .error)
            availablePrograms = []
        }
    }

    /// Assign a program to multiple patients
    /// - Parameters:
    ///   - programTemplateId: The UUID of the program template to assign
    ///   - patientIds: Set of patient IDs to assign the program to
    ///   - therapistId: The therapist performing the assignment
    func bulkAssignProgram(programTemplateId: UUID, patientIds: Set<UUID>, therapistId: String) async -> Bool {
        let logger = DebugLogger.shared
        isBulkOperationInProgress = true
        bulkOperationError = nil

        defer { isBulkOperationInProgress = false }

        logger.log("Starting bulk program assignment for \(patientIds.count) patients...")

        // Create program assignments for each patient
        var successCount = 0
        var failedPatients: [String] = []

        for patientId in patientIds {
            do {
                // Create a new program for the patient based on the template
                let programData = PatientProgramInsert(
                    patientId: patientId.uuidString,
                    templateId: programTemplateId.uuidString,
                    therapistId: therapistId,
                    status: "active",
                    createdAt: ISO8601DateFormatter().string(from: Date())
                )

                try await supabase.client
                    .from("patient_programs")
                    .insert(programData)
                    .execute()

                successCount += 1
                logger.log("Assigned program to patient \(patientId)", level: .success)
            } catch {
                let patientName = patients.first { $0.id == patientId }?.fullName ?? patientId.uuidString
                failedPatients.append(patientName)
                logger.log("Failed to assign program to patient \(patientId): \(error.localizedDescription)", level: .error)
            }
        }

        if failedPatients.isEmpty {
            logger.log("Bulk assignment completed successfully for \(successCount) patients", level: .success)
            return true
        } else if successCount > 0 {
            bulkOperationError = "Assigned to \(successCount) patients. Failed for: \(failedPatients.joined(separator: ", "))"
            return true
        } else {
            bulkOperationError = "We couldn't assign the program. Please check your connection and try again."
            return false
        }
    }

    /// Generate a summary export for selected patients
    /// - Parameter patientIds: Set of patient IDs to include in the summary
    /// - Returns: A formatted summary string
    func generateBulkSummary(patientIds: Set<UUID>) -> String {
        let selectedPatients = patients.filter { patientIds.contains($0.id) }

        guard !selectedPatients.isEmpty else {
            return "No patients selected."
        }

        var summary = "Korza - Patient Summary\n"
        summary += "Generated: \(DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .short))\n"
        summary += "Total Patients: \(selectedPatients.count)\n"
        summary += String(repeating: "=", count: 50) + "\n\n"

        // Group by sport if available
        let patientsBySport = selectedPatients.safeGrouped { $0.sport ?? "No Sport" }

        for (sport, sportPatients) in patientsBySport.sorted(by: { $0.key < $1.key }) {
            summary += "[\(sport)]\n"

            for patient in sportPatients.sorted(by: { $0.lastName < $1.lastName }) {
                summary += "  - \(patient.fullName)"

                if let position = patient.position {
                    summary += " (\(position))"
                }

                if let adherence = patient.adherencePercentage {
                    summary += " | Adherence: \(Int(adherence))%"
                }

                if let flagCount = patient.flagCount, flagCount > 0 {
                    summary += " | Flags: \(flagCount)"
                    if patient.hasHighSeverityFlags {
                        summary += " (HIGH)"
                    }
                }

                summary += "\n"
            }
            summary += "\n"
        }

        // Summary statistics
        summary += String(repeating: "-", count: 50) + "\n"
        summary += "Statistics:\n"

        let avgAdherence = selectedPatients.compactMap { $0.adherencePercentage }.reduce(0, +) / Double(max(1, selectedPatients.compactMap { $0.adherencePercentage }.count))
        if avgAdherence > 0 {
            summary += "  Average Adherence: \(Int(avgAdherence))%\n"
        }

        let totalFlags = selectedPatients.compactMap { $0.flagCount }.reduce(0, +)
        let highSeverityFlags = selectedPatients.compactMap { $0.highSeverityFlagCount }.reduce(0, +)
        summary += "  Total Flags: \(totalFlags) (\(highSeverityFlags) high severity)\n"

        return summary
    }

    /// Clear selection and exit selection mode
    func clearSelectionAndExit() {
        selectedPatientIds.removeAll()
        isSelectionModeActive = false
    }
}

// MARK: - Database Program Template Model

/// A template for creating programs from database (used in bulk assignment)
/// Note: Different from Models/ProgramTemplate which is for local template library storage
struct DatabaseProgramTemplate: Codable, Identifiable {
    let id: UUID
    let therapistId: UUID
    let name: String
    let description: String?
    let durationWeeks: Int
    let programType: ProgramType?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case therapistId = "therapist_id"
        case name
        case description
        case durationWeeks = "duration_weeks"
        case programType = "program_type"
        case createdAt = "created_at"
    }
}

// MARK: - Patient Program Insert Model

/// Data structure for inserting a patient program assignment
struct PatientProgramInsert: Codable {
    let patientId: String
    let templateId: String
    let therapistId: String
    let status: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case templateId = "template_id"
        case therapistId = "therapist_id"
        case status
        case createdAt = "created_at"
    }
}
