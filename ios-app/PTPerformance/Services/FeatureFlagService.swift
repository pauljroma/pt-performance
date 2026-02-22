//
//  FeatureFlagService.swift
//  PTPerformance
//
//  Remote feature flag service that fetches flag state from Supabase.
//  Falls back to local defaults when offline or before the first fetch completes.
//
//  ## Architecture
//  - Singleton accessed via `FeatureFlagService.shared`
//  - Flags are cached in UserDefaults with a 5-minute TTL
//  - On launch, cached values load synchronously so the UI never blocks
//  - `fetchFlags()` is called after auth to refresh from the backend
//  - If the network call fails, cached or hardcoded defaults are used
//
//  ## Usage
//  ```swift
//  // Check a flag (synchronous, safe from any context)
//  if FeatureFlagService.shared.isEnabled("ai_chat_enabled") { ... }
//
//  // Trigger a refresh (e.g., after login)
//  await FeatureFlagService.shared.fetchFlags()
//  ```
//

import Foundation

@MainActor
final class FeatureFlagService: ObservableObject {
    static let shared = FeatureFlagService()

    @Published private(set) var flags: [String: Bool] = [:]
    @Published private(set) var isLoaded = false

    /// Thread-safe snapshot of current flags for nonisolated reads.
    /// Updated whenever `flags` changes on MainActor.
    nonisolated(unsafe) private static var flagSnapshot: [String: Bool] = [:]

    // MARK: - Local Defaults

    /// Hardcoded defaults used before remote fetch completes or when offline.
    /// These must stay in sync with the seed data in the feature_flags migration.
    private static let defaults: [String: Bool] = [
        "ai_chat_enabled": true,
        "ai_substitution_enabled": true,
        "ai_safety_enabled": true,
        "ai_progressive_overload_enabled": true,
        "ai_soap_suggestions_enabled": true,
        "ai_nutrition_enabled": true,
        "whoop_integration_enabled": false,
        "baseball_pack_enabled": true,
        "elite_tier_enabled": true
    ]

    // MARK: - Cache Configuration

    private let cacheKey = "pt_feature_flags_cache"
    private let cacheTimestampKey = "pt_feature_flags_timestamp"
    private let cacheDuration: TimeInterval = 300 // 5 minutes

    // MARK: - Init

    private init() {
        loadFromCache()
        Self.flagSnapshot = flags
    }

    // MARK: - Public API

    /// Returns whether the given flag is enabled.
    /// Callable from any isolation context (Config.AIConfig computed properties, etc.).
    /// Falls back to the local default, then to `false` if the key is unknown.
    nonisolated func isEnabled(_ key: String) -> Bool {
        Self.flagSnapshot[key] ?? Self.defaults[key] ?? false
    }

    /// Fetches the latest flag values from the Supabase edge function.
    /// Skips the network call if the cache is still fresh.
    func fetchFlags() async {
        // Check cache freshness
        if let timestamp = UserDefaults.standard.object(forKey: cacheTimestampKey) as? Date,
           Date().timeIntervalSince(timestamp) < cacheDuration {
            return
        }

        do {
            let responseData: Data = try await PTSupabaseClient.shared.client
                .functions.invoke("feature-flags") { data, _ in
                    data
                }
            let decoder = JSONDecoder()
            let result = try decoder.decode(FlagResponse.self, from: responseData)
            self.flags = result.flags
            Self.flagSnapshot = result.flags
            self.isLoaded = true
            saveToCache()
        } catch {
            // Silently fail -- use cached or default values
            DebugLogger.shared.log(
                "[FeatureFlagService] Failed to fetch flags: \(error.localizedDescription)",
                level: .warning
            )
            if !isLoaded {
                flags = Self.defaults
                Self.flagSnapshot = Self.defaults
                isLoaded = true
            }
        }
    }

    // MARK: - Cache Persistence

    private func loadFromCache() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cached = try? JSONDecoder().decode([String: Bool].self, from: data) {
            flags = cached
            isLoaded = true
        } else {
            flags = Self.defaults
        }
    }

    private func saveToCache() {
        if let data = try? JSONEncoder().encode(flags) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: cacheTimestampKey)
        }
    }

    // MARK: - Response Model

    private struct FlagResponse: Codable {
        let flags: [String: Bool]
    }
}
