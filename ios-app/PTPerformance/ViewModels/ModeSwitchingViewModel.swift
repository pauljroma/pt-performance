//
//  ModeSwitchingViewModel.swift
//  PTPerformance
//
//  ViewModel for mode switching panel
//

import Foundation

@MainActor
class ModeSwitchingViewModel: ObservableObject {
    let patientId: String

    @Published var currentMode: Mode = .rehab
    @Published var selectedMode: Mode = .rehab
    @Published var modeChangedAt: Date?
    @Published var patientName: String?

    @Published var reasonForChange: String = ""
    @Published var modeHistory: [ModeHistoryEntry] = []

    @Published var isChangingMode = false
    @Published var showingConfirmation = false
    @Published var showingError = false
    @Published var errorMessage = ""

    private let modeService = ModeService.shared
    private let supabase = PTSupabaseClient.shared

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()

    /// Codable response for patient mode query
    private struct PatientModeResponse: Codable {
        let mode: String
        let mode_changed_at: String?
        let first_name: String?
        let last_name: String?
    }

    /// Check if current user is a therapist (can change modes)
    var canChangeMode: Bool {
        guard supabase.userId != nil else { return false }

        // Only therapists can change patient modes.
        // Additionally, a therapist must be viewing another user's profile
        // (not their own) to change the mode.
        if supabase.userRole == .therapist {
            return supabase.userId != patientId
        }

        return false
    }

    init(patientId: String) {
        self.patientId = patientId
    }

    /// Load patient's current mode
    func loadPatientMode() async {
        do {
            let response = try await supabase.client
                .from("patients")
                .select("mode, mode_changed_at, first_name, last_name")
                .eq("id", value: patientId)
                .single()
                .execute()

            let decoded = try JSONDecoder().decode(PatientModeResponse.self, from: response.data)

            if let mode = Mode(rawValue: decoded.mode) {
                currentMode = mode
                selectedMode = mode
            }

            if let changedAtString = decoded.mode_changed_at,
               let date = Self.iso8601Formatter.date(from: changedAtString) {
                modeChangedAt = date
            }

            let firstName = decoded.first_name ?? ""
            let lastName = decoded.last_name ?? ""
            patientName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)

            DebugLogger.shared.log("[ModeSwitching] Loaded patient mode: \(currentMode.displayName)", level: .success)
        } catch {
            DebugLogger.shared.error("ModeSwitchingViewModel", "Failed to load patient mode: \(error.localizedDescription)")
            errorMessage = "We couldn't load the patient's current mode. Please try again."
            showingError = true
        }
    }

    /// Load mode change history for the patient being viewed
    func loadModeHistory() async {
        modeHistory = await modeService.loadModeHistory(patientId: patientId)
    }

    /// Confirm and execute mode change
    func confirmModeChange() async {
        guard selectedMode != currentMode else { return }
        guard canChangeMode else {
            errorMessage = "You do not have permission to change this patient's mode."
            showingError = true
            return
        }

        isChangingMode = true
        defer { isChangingMode = false }

        do {
            // Call ModeService to change mode (uses edge function)
            try await modeService.changePatientMode(
                patientId: patientId,
                newMode: selectedMode,
                reason: reasonForChange.isEmpty ? nil : reasonForChange
            )

            // Reload mode and history
            await loadPatientMode()
            await loadModeHistory()

            // Reset reason field
            reasonForChange = ""

            DebugLogger.shared.log("[ModeSwitching] Mode changed successfully to \(selectedMode.displayName)", level: .success)
        } catch {
            DebugLogger.shared.error("ModeSwitchingViewModel", "Failed to change mode: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            showingError = true
            // Reset selection back to current mode on failure
            selectedMode = currentMode
        }
    }
}
