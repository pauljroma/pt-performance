//
//  ModeService.swift
//  PTPerformance
//
//  Mode querying and feature visibility
//

import Foundation
import Combine

/// Service for managing patient mode and feature visibility
@MainActor
class ModeService: ObservableObject {
    static let shared = ModeService()

    @Published var currentMode: Mode = .rehab
    @Published var modeFeatures: [ModeFeature] = []
    @Published var isLoading = false

    private let supabase = PTSupabaseClient.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Load mode when user ID changes
        supabase.$userId
            .sink { [weak self] userId in
                if userId != nil {
                    Task { [weak self] in await self?.loadPatientMode() }
                }
            }
            .store(in: &cancellables)
    }

    /// Load current patient's mode from database
    func loadPatientMode() async {
        guard let userId = supabase.userId else {
            #if DEBUG
            print("⚠️ No user ID, cannot load mode")
            #endif
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Query patient mode using user_id (not id)
            let response = try await supabase.client
                .from("patients")
                .select("id, mode, mode_changed_at, mode_changed_by")
                .eq("user_id", value: userId)
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let patientMode = try decoder.decode(PatientMode.self, from: response.data)
            currentMode = patientMode.mode

            // Load features for this mode
            await loadModeFeatures(for: patientMode.mode)

            #if DEBUG
            print("✅ Loaded patient mode: \(patientMode.mode.displayName)")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to load patient mode: \(error)")
            #endif
            // Default to rehab mode on error
            currentMode = .rehab
            await loadModeFeatures(for: .rehab)
        }
    }

    /// Load features for a specific mode
    private func loadModeFeatures(for mode: Mode) async {
        do {
            let response = try await supabase.client
                .from("mode_features")
                .select()
                .eq("mode", value: mode.rawValue)
                .eq("enabled", value: true)
                .execute()

            let decoder = JSONDecoder()
            let features = try decoder.decode([ModeFeature].self, from: response.data)
            modeFeatures = features

            #if DEBUG
            print("✅ Loaded \(features.count) features for \(mode.displayName)")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to load mode features: \(error)")
            #endif
            modeFeatures = []
        }
    }

    /// Check if a feature is enabled for current mode
    func isFeatureEnabled(_ featureKey: FeatureKey) -> Bool {
        return modeFeatures.contains { $0.featureKey == featureKey.rawValue }
    }

    /// Get mode history for current patient
    func loadModeHistory() async -> [ModeHistoryEntry] {
        guard let userId = supabase.userId else {
            return []
        }

        do {
            let response = try await supabase.client
                .from("mode_history")
                .select()
                .eq("patient_id", value: userId)
                .order("created_at", ascending: false)
                .limit(10)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let history = try decoder.decode([ModeHistoryEntry].self, from: response.data)

            #if DEBUG
            print("✅ Loaded \(history.count) mode history entries")
            #endif

            return history
        } catch {
            #if DEBUG
            print("❌ Failed to load mode history: \(error)")
            #endif
            return []
        }
    }

    /// Change patient mode (therapist only - calls edge function)
    func changePatientMode(patientId: String, newMode: Mode, reason: String?) async throws {
        do {
            try await supabase.client.functions.invoke(
                "change-patient-mode",
                options: .init(
                    body: [
                        "patient_id": patientId,
                        "new_mode": newMode.rawValue,
                        "reason": reason ?? ""
                    ]
                )
            )
        } catch {
            throw NSError(
                domain: "ModeService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to change mode: \(error.localizedDescription)"]
            )
        }

        // Reload mode after change
        await loadPatientMode()

        #if DEBUG
        print("✅ Changed patient mode to \(newMode.displayName)")
        #endif
    }
}
