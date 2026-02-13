//
//  ModeSwitchingViewModel.swift
//  PTPerformance
//
//  ViewModel for mode switching panel
//

import Foundation
import Combine

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

    /// Check if current user is a therapist (can change modes)
    var canChangeMode: Bool {
        // Check if user has therapist role
        guard supabase.userId != nil else { return false }

        // In production, check user role from database
        // For now, allow all authenticated users (will be restricted by RLS)
        return true
    }

    init(patientId: String) {
        self.patientId = patientId
    }

    /// Load patient's current mode
    func loadPatientMode() async {
        do {
            let response = try await supabase.client
                .from("patients")
                .select("id, mode, mode_changed_at, first_name, last_name")
                .eq("id", value: patientId)
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let data = try JSONSerialization.jsonObject(with: response.data) as? [String: Any]

            if let modeString = data?["mode"] as? String,
               let mode = Mode(rawValue: modeString) {
                currentMode = mode
                selectedMode = mode
            }

            if let changedAtString = data?["mode_changed_at"] as? String,
               let date = ISO8601DateFormatter().date(from: changedAtString) {
                modeChangedAt = date
            }

            let firstName = data?["first_name"] as? String ?? ""
            let lastName = data?["last_name"] as? String ?? ""
            patientName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)

            DebugLogger.shared.log("[ModeSwitching] Loaded patient mode: \(currentMode.displayName)", level: .success)
        } catch {
            DebugLogger.shared.error("ModeSwitchingViewModel", "Failed to load patient mode: \(error.localizedDescription)")
            errorMessage = "We couldn't load the patient's current mode. Please try again."
            showingError = true
        }
    }

    /// Load mode change history
    func loadModeHistory() async {
        modeHistory = await modeService.loadModeHistory()
    }

    /// Confirm and execute mode change
    func confirmModeChange() async {
        guard selectedMode != currentMode else { return }

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
        }
    }
}
