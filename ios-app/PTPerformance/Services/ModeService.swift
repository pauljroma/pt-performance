//
//  ModeService.swift
//  PTPerformance
//
//  Mode querying and feature visibility
//

import Foundation
import Combine

// MARK: - ModeService Errors

enum ModeServiceError: LocalizedError {
    case modeChangeFailed(underlying: Error)
    case loadFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .modeChangeFailed(let e): return "Failed to change mode: \(e.localizedDescription)"
        case .loadFailed(let e): return "Failed to load mode: \(e.localizedDescription)"
        }
    }
}

/// Service for managing patient mode and feature visibility
@MainActor
class ModeService: ObservableObject {
    static let shared = ModeService()

    @Published var currentMode: Mode = .rehab
    @Published var modeFeatures: [ModeFeature] = []
    @Published var isLoading = false
    @Published var loadError: String?

    private let supabase = PTSupabaseClient.shared
    private let debugLogger = DebugLogger.shared
    private var cancellables = Set<AnyCancellable>()
    private var loadTask: Task<Void, Never>?
    private var lastUserId: String?

    private init() {
        // Load mode when user ID changes
        supabase.$userId
            .sink { [weak self] userId in
                guard let self else { return }
                // Only cancel/restart if the userId actually changed
                guard userId != self.lastUserId else { return }
                self.lastUserId = userId
                if userId != nil {
                    self.loadTask?.cancel()
                    self.loadTask = Task { [weak self] in await self?.loadPatientMode() }
                }
            }
            .store(in: &cancellables)
    }

    /// Load current patient's mode from database
    func loadPatientMode() async {
        guard let userId = supabase.authUserId else {
            debugLogger.log("[ModeService] No auth user ID, cannot load mode", level: .warning)
            return
        }

        // Therapists don't have a record in the patients table — skip the query
        // and default to performance mode (broadest feature set for clinical use).
        if supabase.userRole == .therapist {
            currentMode = .performance
            loadError = nil
            await loadModeFeatures(for: .performance)
            debugLogger.log("[ModeService] Therapist user, defaulting to performance mode", level: .success)
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Query patient mode using user_id — use execute() + limit(1) instead
            // of .single() to gracefully handle 0 or multiple rows instead of
            // throwing "Cannot coerce the result to a single JSON object".
            let response = try await supabase.client
                .from("patients")
                .select("id, mode, mode_changed_at, mode_changed_by")
                .eq("user_id", value: userId)
                .limit(1)
                .execute()

            let results = try PTSupabaseClient.flexibleDecoder.decode([PatientMode].self, from: response.data)

            if let patientMode = results.first {
                currentMode = patientMode.mode
                loadError = nil

                // Load features for this mode
                await loadModeFeatures(for: patientMode.mode)

                debugLogger.log("[ModeService] Loaded patient mode: \(patientMode.mode.displayName)", level: .success)
            } else {
                debugLogger.log("[ModeService] No patient record found for user, defaulting to rehab mode", level: .warning)
                currentMode = .rehab
                loadError = nil
                await loadModeFeatures(for: .rehab)
            }
        } catch {
            debugLogger.log("[ModeService] Failed to load patient mode: \(error)", level: .error)
            loadError = ModeServiceError.loadFailed(underlying: error).localizedDescription
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

            if features.isEmpty {
                // Using defaults is normal behavior — only log once per mode
                debugLogger.logOnce(key: "mode_features_empty_\(mode.rawValue)", "[ModeService] No features in mode_features table for \(mode.displayName), using defaults", level: .diagnostic)
                modeFeatures = Self.defaultFeatures(for: mode)
            } else {
                modeFeatures = features
            }

            debugLogger.log("[ModeService] Loaded \(modeFeatures.count) features for \(mode.displayName)", level: .success)
        } catch {
            debugLogger.log("[ModeService] Failed to load mode features: \(error), using defaults", level: .error)
            modeFeatures = Self.defaultFeatures(for: mode)
        }
    }

    /// Sensible default features per mode when the mode_features table is empty or unavailable
    static func defaultFeatures(for mode: Mode) -> [ModeFeature] {
        switch mode {
        case .rehab:
            return [
                ModeFeature(mode: .rehab, featureKey: FeatureKey.painTracking.rawValue, featureName: "Pain Tracking"),
                ModeFeature(mode: .rehab, featureKey: FeatureKey.romExercises.rawValue, featureName: "ROM Exercises"),
                ModeFeature(mode: .rehab, featureKey: FeatureKey.safetyAlerts.rawValue, featureName: "Recovery & Deload Alerts"),
                ModeFeature(mode: .rehab, featureKey: FeatureKey.ptMessaging.rawValue, featureName: "PT Messaging"),
                ModeFeature(mode: .rehab, featureKey: FeatureKey.progressPhotos.rawValue, featureName: "Progress Photos"),
                ModeFeature(mode: .rehab, featureKey: FeatureKey.functionTests.rawValue, featureName: "Function Tests")
            ]
        case .strength:
            return [
                ModeFeature(mode: .strength, featureKey: FeatureKey.prTracking.rawValue, featureName: "PR Tracking"),
                ModeFeature(mode: .strength, featureKey: FeatureKey.volumeTrends.rawValue, featureName: "Volume Tracking"),
                ModeFeature(mode: .strength, featureKey: FeatureKey.progressiveOverload.rawValue, featureName: "Progressive Overload"),
                ModeFeature(mode: .strength, featureKey: FeatureKey.habitStreaks.rawValue, featureName: "Habit Streaks"),
                ModeFeature(mode: .strength, featureKey: FeatureKey.workoutCalendar.rawValue, featureName: "Workout Calendar"),
                ModeFeature(mode: .strength, featureKey: FeatureKey.bodyComp.rawValue, featureName: "Body Composition")
            ]
        case .performance:
            return [
                ModeFeature(mode: .performance, featureKey: FeatureKey.readinessScore.rawValue, featureName: "Readiness Score"),
                ModeFeature(mode: .performance, featureKey: FeatureKey.advancedAnalytics.rawValue, featureName: "ACWR & Fatigue Tracking"),
                ModeFeature(mode: .performance, featureKey: FeatureKey.periodization.rawValue, featureName: "Training Load & Periodization"),
                ModeFeature(mode: .performance, featureKey: FeatureKey.teamManagement.rawValue, featureName: "Team Management"),
                ModeFeature(mode: .performance, featureKey: FeatureKey.competitionPrep.rawValue, featureName: "Competition Prep"),
                ModeFeature(mode: .performance, featureKey: FeatureKey.videoAnalysis.rawValue, featureName: "Video Analysis")
            ]
        }
    }

    /// Check if a feature is enabled for current mode
    func isFeatureEnabled(_ featureKey: FeatureKey) -> Bool {
        return modeFeatures.contains { $0.featureKey == featureKey.rawValue }
    }

    /// Get mode history for a patient
    /// - Parameter patientId: The patient's ID. If nil, falls back to the current user's ID.
    func loadModeHistory(patientId: String? = nil) async -> [ModeHistoryEntry] {
        guard let resolvedId = patientId ?? supabase.userId else {
            return []
        }

        do {
            let response = try await supabase.client
                .from("mode_history")
                .select()
                .eq("patient_id", value: resolvedId)
                .order("created_at", ascending: false)
                .limit(10)
                .execute()

            let history = try PTSupabaseClient.flexibleDecoder.decode([ModeHistoryEntry].self, from: response.data)

            debugLogger.log("[ModeService] Loaded \(history.count) mode history entries", level: .success)

            return history
        } catch {
            debugLogger.log("[ModeService] Failed to load mode history: \(error)", level: .error)
            return []
        }
    }

    /// Change patient mode (therapist only - calls edge function)
    /// Note: The caller is responsible for reloading the correct patient's mode after this succeeds.
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
            throw ModeServiceError.modeChangeFailed(underlying: error)
        }

        debugLogger.log("[ModeService] Changed patient mode to \(newMode.displayName)", level: .success)
    }
}
