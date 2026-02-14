import Foundation
import SwiftUI

// MARK: - ACP-472: Wearable Connection Manager
// Central orchestrator for multi-wearable device integration.
// Manages provider registration, connection lifecycle, primary device selection,
// and coordinated sync across all connected wearables.
//
// Used by ReadinessService to fetch recovery data from the patient's
// preferred (primary) wearable device.

// MARK: - Database Record Models

/// Model for inserting/updating wearable connections in Supabase
private struct WearableConnectionInsert: Encodable {
    let patientId: String
    let wearableType: String
    let isPrimary: Bool
    let isActive: Bool
    let connectedAt: String
    let deviceMetadata: [String: String]?
    let syncConfig: WearableSyncConfig

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case wearableType = "wearable_type"
        case isPrimary = "is_primary"
        case isActive = "is_active"
        case connectedAt = "connected_at"
        case deviceMetadata = "device_metadata"
        case syncConfig = "sync_config"
    }
}

/// Model for updating last_sync_at timestamp
private struct WearableSyncUpdate: Encodable {
    let lastSyncAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case lastSyncAt = "last_sync_at"
        case updatedAt = "updated_at"
    }
}

/// Model for updating the primary flag
private struct WearablePrimaryUpdate: Encodable {
    let isPrimary: Bool
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case isPrimary = "is_primary"
        case updatedAt = "updated_at"
    }
}

/// Model for soft-deleting (deactivating) a connection
private struct WearableDeactivateUpdate: Encodable {
    let isActive: Bool
    let isPrimary: Bool
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case isActive = "is_active"
        case isPrimary = "is_primary"
        case updatedAt = "updated_at"
    }
}

// MARK: - WearableConnectionManager

/// Central manager for all wearable device connections.
///
/// Maintains a registry of `WearableProvider` instances and coordinates
/// data fetching, connection management, and sync operations across all
/// connected wearable devices.
///
/// ## Architecture
/// - Providers are registered at app startup (e.g., WHOOPWearableProvider, AppleWatchWearableProvider)
/// - Connection state is persisted in the `wearable_connections` Supabase table
/// - One wearable is designated as "primary" for readiness calculations
/// - `fetchPrimaryRecoveryData()` is the main entry point used by `ReadinessService`
///
/// ## Usage
/// ```swift
/// let manager = WearableConnectionManager.shared
/// manager.registerProvider(WHOOPWearableProvider())
/// manager.registerProvider(AppleWatchWearableProvider())
///
/// await manager.loadConnections(patientId: patientId)
/// let recoveryData = try await manager.fetchPrimaryRecoveryData()
/// ```
///
/// ## Thread Safety
/// This class is `@MainActor` isolated. Published properties update on the main thread.
@MainActor
final class WearableConnectionManager: ObservableObject {

    // MARK: - Singleton

    /// Shared singleton instance
    static let shared = WearableConnectionManager()

    // MARK: - Published Properties

    /// All active wearable connections for the current patient
    @Published var connections: [WearableConnection] = []

    /// Whether a load/sync operation is in progress
    @Published var isLoading = false

    /// Most recent error, if any
    @Published var error: Error?

    /// Whether any wearable is currently connected
    @Published var hasConnectedWearable = false

    // MARK: - Private Properties

    /// Registry of wearable providers by type
    private var providers: [WearableType: WearableProvider] = [:]

    /// Supabase client for database operations
    private let supabaseClient: PTSupabaseClient

    /// Logger for diagnostic output
    private let logger = DebugLogger.shared

    /// Error logger for structured error tracking
    private let errorLogger = ErrorLogger.shared

    /// Current patient ID, set when connections are loaded
    private var currentPatientId: UUID?

    /// Cached ISO8601 date formatter (avoid allocating on every call)
    private static let isoFormatter = ISO8601DateFormatter()

    /// Cached relative date formatter for `lastSyncText`
    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    // MARK: - Initialization

    /// Private initializer for singleton pattern.
    /// Use `WearableConnectionManager.shared` to access the singleton.
    private init() {
        self.supabaseClient = PTSupabaseClient.shared
    }

    /// Initializer for dependency injection (testing)
    init(supabaseClient: PTSupabaseClient) {
        self.supabaseClient = supabaseClient
    }

    // MARK: - Provider Registration

    /// Register a wearable provider for a specific device type.
    ///
    /// Providers should be registered at app startup before any
    /// connection or sync operations are attempted.
    ///
    /// - Parameter provider: The provider instance to register
    func registerProvider(_ provider: WearableProvider) {
        providers[provider.type] = provider
        logger.log("[WearableConnectionManager] Registered provider: \(provider.type.displayName)", level: .diagnostic)
    }

    /// Get the registered provider for a specific wearable type.
    ///
    /// - Parameter type: The wearable type to look up
    /// - Returns: The registered provider, or nil if not registered
    func provider(for type: WearableType) -> WearableProvider? {
        return providers[type]
    }

    /// All registered wearable types
    var registeredTypes: [WearableType] {
        Array(providers.keys).sorted { $0.rawValue < $1.rawValue }
    }

    // MARK: - Load Connections

    /// Load all active wearable connections for a patient from the database.
    ///
    /// This should be called after sign-in to populate the connections list.
    /// Updates `connections`, `hasConnectedWearable`, and validates each
    /// connection against its registered provider.
    ///
    /// - Parameter patientId: The patient's UUID
    func loadConnections(patientId: UUID) async {
        logger.log("[WearableConnectionManager] Loading connections for patient: \(patientId)", level: .diagnostic)

        currentPatientId = patientId
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let response = try await supabaseClient.client
                .from("wearable_connections")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .eq("is_active", value: true)
                .order("is_primary", ascending: false)
                .execute()

            let decoder = PTSupabaseClient.flexibleDecoder
            let loadedConnections = try decoder.decode([WearableConnection].self, from: response.data)

            connections = loadedConnections
            hasConnectedWearable = !loadedConnections.isEmpty

            logger.log("[WearableConnectionManager] Loaded \(loadedConnections.count) connections", level: .success)

            // Validate each connection against its provider using a tracked TaskGroup
            await withTaskGroup(of: Void.self) { group in
                for connection in loadedConnections {
                    if let provider = providers[connection.wearableType] {
                        group.addTask { [logger] in
                            do {
                                let isValid = try await provider.validateConnection()
                                if !isValid {
                                    await MainActor.run {
                                        logger.log("[WearableConnectionManager] Connection validation failed for \(connection.wearableType.displayName)", level: .warning)
                                    }
                                }
                            } catch {
                                await MainActor.run {
                                    logger.log("[WearableConnectionManager] Error validating \(connection.wearableType.displayName): \(error.localizedDescription)", level: .warning)
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            self.error = error
            errorLogger.logError(error, context: "WearableConnectionManager.loadConnections", metadata: [
                "patient_id": patientId.uuidString
            ])
            logger.log("[WearableConnectionManager] Failed to load connections: \(error.localizedDescription)", level: .error)
        }
    }

    // MARK: - Connect Wearable

    /// Connect a new wearable device.
    ///
    /// Initiates the authorization flow for the wearable, creates a database
    /// record on success, and sets the device as primary if it's the first
    /// connected wearable.
    ///
    /// - Parameter type: The wearable device type to connect
    /// - Throws: `WearableError.providerNotRegistered` if no provider exists,
    ///           `WearableError.authorizationFailed` if auth flow fails
    func connect(type: WearableType) async throws {
        logger.log("[WearableConnectionManager] Connecting \(type.displayName)...", level: .diagnostic)

        guard let provider = providers[type] else {
            throw WearableError.providerNotRegistered(type)
        }

        guard let patientId = currentPatientId else {
            throw WearableError.authorizationFailed("No patient ID available. Please sign in first.")
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        // Run the provider's authorization flow (OAuth or HealthKit)
        do {
            try await provider.authorize()
        } catch {
            self.error = error
            throw WearableError.authorizationFailed(error.localizedDescription)
        }

        // Determine if this should be the primary wearable
        let shouldBePrimary = connections.isEmpty || !connections.contains(where: { $0.isPrimary })

        // Create the database record
        let now = Self.isoFormatter.string(from: Date())
        let insertRecord = WearableConnectionInsert(
            patientId: patientId.uuidString,
            wearableType: type.rawValue,
            isPrimary: shouldBePrimary,
            isActive: true,
            connectedAt: now,
            deviceMetadata: nil,
            syncConfig: .default
        )

        do {
            try await supabaseClient.client
                .from("wearable_connections")
                .upsert(insertRecord, onConflict: "patient_id,wearable_type")
                .execute()

            logger.log("[WearableConnectionManager] \(type.displayName) connected successfully (primary: \(shouldBePrimary))", level: .success)

            // Reload connections to get the full record from DB
            await loadConnections(patientId: patientId)
        } catch {
            // Rollback: disconnect the provider since the DB insert failed
            try? await provider.disconnect()

            self.error = error
            errorLogger.logError(error, context: "WearableConnectionManager.connect", metadata: [
                "wearable_type": type.rawValue,
                "patient_id": patientId.uuidString
            ])
            throw WearableError.authorizationFailed("Connected to \(type.displayName) but failed to save: \(error.localizedDescription)")
        }
    }

    // MARK: - Disconnect Wearable

    /// Disconnect a wearable device.
    ///
    /// Revokes the provider's authorization, soft-deletes the database record
    /// (sets `is_active = false`), and promotes another wearable to primary
    /// if the disconnected one was primary.
    ///
    /// - Parameter type: The wearable device type to disconnect
    /// - Throws: `WearableError.providerNotRegistered` if no provider exists,
    ///           `WearableError.disconnectionFailed` if cleanup fails
    func disconnect(type: WearableType) async throws {
        logger.log("[WearableConnectionManager] Disconnecting \(type.displayName)...", level: .diagnostic)

        guard let patientId = currentPatientId else {
            throw WearableError.disconnectionFailed("No patient ID available.")
        }

        // Find the connection record
        guard let connection = connections.first(where: { $0.wearableType == type }) else {
            throw WearableError.notConnected(type)
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        // Disconnect the provider (revoke tokens, clear keychain)
        if let provider = providers[type] {
            do {
                try await provider.disconnect()
            } catch {
                logger.log("[WearableConnectionManager] Provider disconnect warning: \(error.localizedDescription)", level: .warning)
                // Continue with database cleanup even if provider disconnect fails
            }
        }

        // Soft-delete in database (set is_active = false)
        let now = Self.isoFormatter.string(from: Date())
        let deactivateUpdate = WearableDeactivateUpdate(
            isActive: false,
            isPrimary: false,
            updatedAt: now
        )

        do {
            try await supabaseClient.client
                .from("wearable_connections")
                .update(deactivateUpdate)
                .eq("id", value: connection.id.uuidString)
                .execute()

            logger.log("[WearableConnectionManager] \(type.displayName) disconnected", level: .success)

            // If this was the primary, promote the next available wearable
            if connection.isPrimary {
                let remaining = connections.filter { $0.wearableType != type && $0.isActive }
                if let nextPrimary = remaining.first {
                    try? await setPrimary(type: nextPrimary.wearableType)
                }
            }

            // Reload connections
            await loadConnections(patientId: patientId)
        } catch {
            self.error = error
            errorLogger.logError(error, context: "WearableConnectionManager.disconnect", metadata: [
                "wearable_type": type.rawValue,
                "connection_id": connection.id.uuidString
            ])
            throw WearableError.disconnectionFailed(error.localizedDescription)
        }
    }

    // MARK: - Set Primary Wearable

    /// Set a connected wearable as the primary device for readiness data.
    ///
    /// Only one wearable can be primary at a time. This clears the primary
    /// flag on all other connections before setting the new primary.
    ///
    /// - Parameter type: The wearable type to set as primary
    /// - Throws: `WearableError.notConnected` if the type is not connected
    func setPrimary(type: WearableType) async throws {
        logger.log("[WearableConnectionManager] Setting \(type.displayName) as primary...", level: .diagnostic)

        guard let patientId = currentPatientId else {
            throw WearableError.authorizationFailed("No patient ID available.")
        }

        guard let targetConnection = connections.first(where: { $0.wearableType == type && $0.isActive }) else {
            throw WearableError.notConnected(type)
        }

        let now = Self.isoFormatter.string(from: Date())

        // Clear primary flag on all current connections
        let clearPrimary = WearablePrimaryUpdate(isPrimary: false, updatedAt: now)

        do {
            try await supabaseClient.client
                .from("wearable_connections")
                .update(clearPrimary)
                .eq("patient_id", value: patientId.uuidString)
                .eq("is_active", value: true)
                .execute()

            // Set the new primary
            let setPrimary = WearablePrimaryUpdate(isPrimary: true, updatedAt: now)
            try await supabaseClient.client
                .from("wearable_connections")
                .update(setPrimary)
                .eq("id", value: targetConnection.id.uuidString)
                .execute()

            logger.log("[WearableConnectionManager] \(type.displayName) set as primary", level: .success)

            // Reload connections
            await loadConnections(patientId: patientId)
        } catch {
            self.error = error
            errorLogger.logError(error, context: "WearableConnectionManager.setPrimary", metadata: [
                "wearable_type": type.rawValue
            ])
            throw error
        }
    }

    // MARK: - Fetch Primary Recovery Data

    /// Fetch recovery data from the primary wearable device.
    ///
    /// This is the main entry point used by `ReadinessService` to get
    /// wearable recovery data for readiness calculations.
    ///
    /// - Returns: Normalized `WearableRecoveryData` from the primary wearable
    /// - Throws: `WearableError.noPrimaryWearable` if no primary is configured,
    ///           `WearableError.providerNotRegistered` if provider is missing,
    ///           or the provider's fetch error
    func fetchPrimaryRecoveryData() async throws -> WearableRecoveryData {
        logger.log("[WearableConnectionManager] Fetching primary recovery data...", level: .diagnostic)

        guard let primaryConnection = connections.first(where: { $0.isPrimary && $0.isActive }) else {
            throw WearableError.noPrimaryWearable
        }

        guard let provider = providers[primaryConnection.wearableType] else {
            throw WearableError.providerNotRegistered(primaryConnection.wearableType)
        }

        let data = try await provider.fetchRecoveryData()

        // Update last_sync_at in the database
        await updateLastSyncTimestamp(connectionId: primaryConnection.id)

        logger.log("[WearableConnectionManager] Primary recovery data fetched from \(primaryConnection.wearableType.displayName)", level: .success)

        return data
    }

    /// Fetch recovery data from the primary wearable for a specific date.
    ///
    /// - Parameter date: The date to fetch data for
    /// - Returns: Normalized `WearableRecoveryData` from the primary wearable
    /// - Throws: Same errors as `fetchPrimaryRecoveryData()`
    func fetchPrimaryRecoveryData(for date: Date) async throws -> WearableRecoveryData {
        guard let primaryConnection = connections.first(where: { $0.isPrimary && $0.isActive }) else {
            throw WearableError.noPrimaryWearable
        }

        guard let provider = providers[primaryConnection.wearableType] else {
            throw WearableError.providerNotRegistered(primaryConnection.wearableType)
        }

        return try await provider.fetchRecoveryData(for: date)
    }

    // MARK: - Fetch Recovery Data from Specific Wearable

    /// Fetch recovery data from a specific wearable type.
    ///
    /// Useful for comparing data across multiple wearables.
    ///
    /// - Parameter type: The wearable type to fetch from
    /// - Returns: Normalized `WearableRecoveryData`
    /// - Throws: `WearableError.providerNotRegistered` or `WearableError.notConnected`
    func fetchRecoveryData(from type: WearableType) async throws -> WearableRecoveryData {
        guard let provider = providers[type] else {
            throw WearableError.providerNotRegistered(type)
        }

        guard connections.contains(where: { $0.wearableType == type && $0.isActive }) else {
            throw WearableError.notConnected(type)
        }

        return try await provider.fetchRecoveryData()
    }

    // MARK: - Sync All

    /// Sync data from all connected wearable devices.
    ///
    /// Fetches the latest data from each connected provider concurrently.
    /// Errors from individual providers are logged but don't prevent
    /// other providers from syncing.
    ///
    /// - Returns: Dictionary mapping wearable types to their fetched data (only successful fetches)
    @discardableResult
    func syncAll() async -> [WearableType: WearableRecoveryData] {
        logger.log("[WearableConnectionManager] Starting sync for all connected wearables...", level: .diagnostic)

        isLoading = true
        defer { isLoading = false }

        var results: [WearableType: WearableRecoveryData] = [:]

        // Sync each connected wearable concurrently
        await withTaskGroup(of: (WearableType, WearableRecoveryData?).self) { group in
            for connection in connections where connection.isActive {
                guard let provider = providers[connection.wearableType] else { continue }

                group.addTask { [weak self] in
                    do {
                        let data = try await provider.fetchRecoveryData()
                        // Update sync timestamp
                        await self?.updateLastSyncTimestamp(connectionId: connection.id)
                        return (connection.wearableType, data)
                    } catch {
                        await MainActor.run {
                            DebugLogger.shared.log("[WearableConnectionManager] Sync failed for \(connection.wearableType.displayName): \(error.localizedDescription)", level: .warning)
                        }
                        return (connection.wearableType, nil)
                    }
                }
            }

            for await (type, data) in group {
                if let data = data {
                    results[type] = data
                }
            }
        }

        logger.log("[WearableConnectionManager] Sync complete: \(results.count)/\(connections.count) successful", level: .success)

        // Reload connections to refresh last_sync_at timestamps
        if let patientId = currentPatientId {
            await loadConnections(patientId: patientId)
        }

        return results
    }

    // MARK: - Helper Methods

    /// Update the last_sync_at timestamp for a connection in the database.
    ///
    /// - Parameter connectionId: The UUID of the connection to update
    private func updateLastSyncTimestamp(connectionId: UUID) async {
        let now = Self.isoFormatter.string(from: Date())
        let update = WearableSyncUpdate(lastSyncAt: now, updatedAt: now)

        do {
            try await supabaseClient.client
                .from("wearable_connections")
                .update(update)
                .eq("id", value: connectionId.uuidString)
                .execute()
        } catch {
            // Non-critical: log but don't propagate
            logger.log("[WearableConnectionManager] Failed to update sync timestamp: \(error.localizedDescription)", level: .warning)
        }
    }

    /// Get the primary wearable connection, if any.
    var primaryConnection: WearableConnection? {
        connections.first(where: { $0.isPrimary && $0.isActive })
    }

    /// Get the primary wearable type, if any.
    var primaryType: WearableType? {
        primaryConnection?.wearableType
    }

    /// Check if a specific wearable type is connected and active.
    ///
    /// - Parameter type: The wearable type to check
    /// - Returns: `true` if the type has an active connection
    func isConnected(type: WearableType) -> Bool {
        connections.contains(where: { $0.wearableType == type && $0.isActive })
    }

    /// Get the connection record for a specific wearable type.
    ///
    /// - Parameter type: The wearable type to look up
    /// - Returns: The active connection, or nil if not connected
    func connection(for type: WearableType) -> WearableConnection? {
        connections.first(where: { $0.wearableType == type && $0.isActive })
    }

    /// Formatted text describing when the last sync occurred for the primary wearable.
    var lastSyncText: String {
        guard let lastSync = primaryConnection?.lastSyncAt else {
            return "Never synced"
        }

        return Self.relativeDateFormatter.localizedString(for: lastSync, relativeTo: Date())
    }

    /// Clear all state (call on sign-out)
    func reset() {
        connections = []
        hasConnectedWearable = false
        currentPatientId = nil
        error = nil
        logger.log("[WearableConnectionManager] State reset", level: .diagnostic)
    }
}

// MARK: - Convenience Extensions

extension WearableConnectionManager {

    /// Fetch recovery data from the primary wearable and convert to BandCalculationInput.
    ///
    /// Convenience method for `ReadinessService` integration. Returns nil if no
    /// primary wearable is configured or if the fetch fails.
    ///
    /// - Returns: `BandCalculationInput` from primary wearable data, or nil
    func fetchPrimaryBandInput() async -> BandCalculationInput? {
        do {
            let data = try await fetchPrimaryRecoveryData()
            return data.toBandCalculationInput()
        } catch {
            logger.log("[WearableConnectionManager] Failed to fetch primary band input: \(error.localizedDescription)", level: .warning)
            return nil
        }
    }

    /// Get a sorted list of all wearable types with their connection status.
    ///
    /// Useful for displaying the wearable settings/management UI. Returns all
    /// supported types with a flag indicating if each is currently connected.
    ///
    /// - Returns: Array of tuples (type, isConnected, isPrimary)
    func allWearableStatuses() -> [(type: WearableType, isConnected: Bool, isPrimary: Bool)] {
        return WearableType.allCases.map { type in
            let conn = connection(for: type)
            return (type: type, isConnected: conn != nil, isPrimary: conn?.isPrimary ?? false)
        }
    }
}

// MARK: - Preview Support

#if DEBUG
extension WearableConnectionManager {
    /// Create a mock manager with sample connections for previews
    static var preview: WearableConnectionManager {
        let manager = WearableConnectionManager()
        manager.connections = [.sampleWHOOP, .sampleAppleWatch]
        manager.hasConnectedWearable = true
        return manager
    }
}
#endif
