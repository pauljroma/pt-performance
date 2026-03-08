//
//  ConflictResolutionService.swift
//  PTPerformance
//
//  X2Index Command Center - Multi-Source Conflict Resolution (M5)
//  Service for detecting and resolving data conflicts between sources
//

import Foundation
import Supabase
import SwiftUI

// MARK: - Conflict Resolution Service

/// Service for detecting, resolving, and managing data conflicts between multiple sources
///
/// Handles conflicts between WHOOP, Apple Health, and manual entry data.
/// Provides both automatic and manual resolution options with full audit logging.
///
/// ## Priority Order (for auto-resolution)
/// 1. Manual entry (highest trust - user explicitly entered)
/// 2. WHOOP (validated medical-grade wearable)
/// 3. Apple Health (aggregated from multiple sources)
///
/// ## Usage
/// ```swift
/// let service = ConflictResolutionService.shared
/// await service.fetchPendingConflicts(patientId: patientId)
/// ```
@MainActor
final class ConflictResolutionService: ObservableObject {

    // MARK: - Singleton

    static let shared = ConflictResolutionService()

    // MARK: - Dependencies

    private let client: PTSupabaseClient

    // MARK: - Published State

    @Published private(set) var pendingConflicts: [DataConflict] = []
    @Published private(set) var recentlyResolved: [DataConflict] = []
    @Published private(set) var isLoading = false
    @Published var error: Error?
    @Published var showError = false
    @Published var errorMessage = ""

    // MARK: - Constants

    /// Source priority for auto-resolution (lower number = higher priority)
    static let sourcePriority: [String: Int] = [
        "manual": 1,
        "whoop": 2,
        "apple_health": 3,
        "oura": 4,
        "garmin": 5,
        "fitbit": 6
    ]

    /// Conflict detection thresholds
    static let sleepDifferenceThreshold: TimeInterval = 30 * 60  // 30 minutes
    static let recoveryDifferenceThreshold = 15  // 15 points difference
    static let hrvDifferenceThreshold = 10  // 10ms difference
    static let heartRateDifferenceThreshold = 5  // 5 bpm difference
    static let stepsDifferenceThreshold = 1000  // 1000 steps difference
    static let caloriesDifferenceThreshold = 200  // 200 kcal difference

    // MARK: - Initialization

    nonisolated init(client: PTSupabaseClient = .shared) {
        self.client = client
    }

    // MARK: - Fetch Conflicts

    /// Fetch all pending conflicts for a therapist (across all their patients)
    /// - Parameter therapistId: The therapist's ID string
    /// - Returns: Array of pending DataConflicts
    func getPendingConflicts(for therapistId: String) async throws -> [DataConflict] {
        do {
            let response = try await client.client
                .from("data_conflicts")
                .select()
                .eq("status", value: "pending")
                .order("conflict_date", ascending: false)
                .limit(100)
                .execute()

            let decoder = PTSupabaseClient.flexibleDecoder
            let conflicts = try decoder.decode([DataConflict].self, from: response.data)

            DebugLogger.shared.success("ConflictResolution", "Fetched \(conflicts.count) pending conflicts for therapist")
            return conflicts
        } catch {
            ErrorLogger.shared.logError(error, context: "ConflictResolutionService.getPendingConflicts(for:)")
            throw error
        }
    }

    /// Fetch all pending conflicts for a patient
    /// - Parameter patientId: The patient's UUID
    func fetchPendingConflicts(patientId: UUID) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await client.client
                .from("data_conflicts")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .eq("status", value: "pending")
                .order("conflict_date", ascending: false)
                .limit(100)
                .execute()

            let decoder = PTSupabaseClient.flexibleDecoder
            pendingConflicts = try decoder.decode([DataConflict].self, from: response.data)

            DebugLogger.shared.success("ConflictResolution", "Fetched \(pendingConflicts.count) pending conflicts")
        } catch {
            self.error = error
            self.errorMessage = "Failed to fetch conflicts: \(error.localizedDescription)"
            self.showError = true
            ErrorLogger.shared.logError(error, context: "ConflictResolutionService.fetchPendingConflicts")
            throw error
        }
    }

    /// Fetch recently resolved conflicts for history view
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - limit: Maximum number of conflicts to fetch
    func fetchResolvedConflicts(patientId: UUID, limit: Int = 20) async throws -> [DataConflict] {
        do {
            let response = try await client.client
                .from("data_conflicts")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .neq("status", value: "pending")
                .order("resolved_at", ascending: false)
                .limit(limit)
                .execute()

            let decoder = PTSupabaseClient.flexibleDecoder
            let conflicts = try decoder.decode([DataConflict].self, from: response.data)

            await MainActor.run {
                self.recentlyResolved = conflicts
            }

            return conflicts
        } catch {
            ErrorLogger.shared.logError(error, context: "ConflictResolutionService.fetchResolvedConflicts")
            throw error
        }
    }

    /// Fetch conflict audit log for a specific conflict
    /// - Parameter conflictId: The conflict's UUID
    func fetchConflictAuditLog(conflictId: UUID) async throws -> [ConflictAuditEntry] {
        do {
            let response = try await client.client
                .from("conflict_audit_log")
                .select()
                .eq("conflict_id", value: conflictId.uuidString)
                .order("created_at", ascending: false)
                .limit(100)
                .execute()

            let decoder = PTSupabaseClient.flexibleDecoder
            return try decoder.decode([ConflictAuditEntry].self, from: response.data)
        } catch {
            ErrorLogger.shared.logError(error, context: "ConflictResolutionService.fetchConflictAuditLog")
            throw error
        }
    }

    // MARK: - Detect Conflicts

    /// Detect conflicts for a patient on a specific date
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - date: The date to check for conflicts
    /// - Returns: Array of detected conflicts
    func detectConflicts(patientId: UUID, date: Date) async throws -> [DataConflict] {
        // Format date for PostgreSQL
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: date)

        do {
            // Call the RPC function to detect conflicts
            let params = DetectConflictsParams(
                pPatientId: patientId.uuidString,
                pDate: dateString
            )

            let response = try await client.client
                .rpc("detect_data_conflicts", params: params)
                .execute()

            let decoder = PTSupabaseClient.flexibleDecoder
            let conflicts = try decoder.decode([DataConflict].self, from: response.data)

            DebugLogger.shared.log("Detected \(conflicts.count) conflicts for \(dateString)", level: .info)
            return conflicts
        } catch {
            ErrorLogger.shared.logError(error, context: "ConflictResolutionService.detectConflicts")
            throw error
        }
    }

    // MARK: - Auto-Resolution

    /// Attempt to automatically resolve a conflict using source priority and confidence
    /// - Parameter conflict: The conflict to resolve
    /// - Returns: The resolved conflict if auto-resolution was possible, nil otherwise
    func autoResolve(_ conflict: DataConflict) -> DataConflict? {
        guard conflict.status == .pending else {
            return nil
        }

        // Find the best source based on priority and confidence
        let sortedSources = conflict.sources.sorted { source1, source2 in
            let priority1 = Self.sourcePriority[source1.sourceType] ?? 99
            let priority2 = Self.sourcePriority[source2.sourceType] ?? 99

            // First sort by priority (lower is better)
            if priority1 != priority2 {
                return priority1 < priority2
            }

            // Then by confidence (higher is better)
            return source1.confidence > source2.confidence
        }

        guard let bestSource = sortedSources.first else {
            return nil
        }

        // Only auto-resolve if the best source has high confidence or clear priority
        let priority = Self.sourcePriority[bestSource.sourceType] ?? 99
        let shouldAutoResolve = priority <= 2 || bestSource.confidence >= 0.85

        guard shouldAutoResolve else {
            return nil
        }

        // Create resolved conflict
        return DataConflict(
            id: conflict.id,
            patientId: conflict.patientId,
            metricType: conflict.metricType,
            conflictDate: conflict.conflictDate,
            sources: conflict.sources,
            status: .autoResolved,
            resolvedValue: bestSource.value,
            resolvedSource: bestSource.sourceType,
            resolvedAt: Date(),
            resolvedBy: nil
        )
    }

    /// Save auto-resolution to database
    /// - Parameter conflict: The conflict to auto-resolve
    func saveAutoResolution(_ conflict: DataConflict) async throws {
        guard let resolved = autoResolve(conflict) else {
            throw ConflictResolutionError.cannotAutoResolve
        }

        try await updateConflictResolution(
            conflictId: resolved.id,
            status: .autoResolved,
            resolvedValue: resolved.resolvedValue,
            resolvedSource: resolved.resolvedSource,
            resolvedBy: nil
        )

        // Update local state
        await MainActor.run {
            if let index = pendingConflicts.firstIndex(where: { $0.id == conflict.id }) {
                pendingConflicts.remove(at: index)
            }
            recentlyResolved.insert(resolved, at: 0)
        }
    }

    // MARK: - User Resolution

    /// Resolve a conflict with user-selected source
    /// - Parameters:
    ///   - conflictId: The conflict's UUID
    ///   - selectedSource: The source type selected by the user
    func userResolve(_ conflictId: UUID, selectedSource: String) async throws {
        guard let conflict = pendingConflicts.first(where: { $0.id == conflictId }) else {
            throw ConflictResolutionError.conflictNotFound
        }

        guard let source = conflict.sources.first(where: { $0.sourceType == selectedSource }) else {
            throw ConflictResolutionError.invalidSource
        }

        let currentUserId = client.userId.flatMap { UUID(uuidString: $0) }

        try await updateConflictResolution(
            conflictId: conflictId,
            status: .userResolved,
            resolvedValue: source.value,
            resolvedSource: selectedSource,
            resolvedBy: currentUserId
        )

        // Update local state
        await MainActor.run {
            if let index = pendingConflicts.firstIndex(where: { $0.id == conflictId }) {
                let resolved = DataConflict(
                    id: conflict.id,
                    patientId: conflict.patientId,
                    metricType: conflict.metricType,
                    conflictDate: conflict.conflictDate,
                    sources: conflict.sources,
                    status: .userResolved,
                    resolvedValue: source.value,
                    resolvedSource: selectedSource,
                    resolvedAt: Date(),
                    resolvedBy: currentUserId
                )
                pendingConflicts.remove(at: index)
                recentlyResolved.insert(resolved, at: 0)
            }
        }

        DebugLogger.shared.success("ConflictResolution", "Resolved conflict \(conflictId) with source: \(selectedSource)")
    }

    /// Resolve a conflict with a custom value
    /// - Parameters:
    ///   - conflictId: The conflict's UUID
    ///   - customValue: The custom value to use
    func userResolveWithCustomValue(_ conflictId: UUID, customValue: AnyCodableValue) async throws {
        guard let conflict = pendingConflicts.first(where: { $0.id == conflictId }) else {
            throw ConflictResolutionError.conflictNotFound
        }

        let currentUserId = client.userId.flatMap { UUID(uuidString: $0) }

        try await updateConflictResolution(
            conflictId: conflictId,
            status: .userResolved,
            resolvedValue: customValue,
            resolvedSource: "custom",
            resolvedBy: currentUserId
        )

        // Update local state
        await MainActor.run {
            if let index = pendingConflicts.firstIndex(where: { $0.id == conflictId }) {
                let resolved = DataConflict(
                    id: conflict.id,
                    patientId: conflict.patientId,
                    metricType: conflict.metricType,
                    conflictDate: conflict.conflictDate,
                    sources: conflict.sources,
                    status: .userResolved,
                    resolvedValue: customValue,
                    resolvedSource: "custom",
                    resolvedAt: Date(),
                    resolvedBy: currentUserId
                )
                pendingConflicts.remove(at: index)
                recentlyResolved.insert(resolved, at: 0)
            }
        }
    }

    // MARK: - Dismiss Conflict

    /// Dismiss a conflict without resolving it
    /// - Parameters:
    ///   - conflictId: The conflict's UUID
    ///   - reason: Optional reason for dismissal
    func dismissConflict(_ conflictId: UUID, reason: String? = nil) async throws {
        guard let conflict = pendingConflicts.first(where: { $0.id == conflictId }) else {
            throw ConflictResolutionError.conflictNotFound
        }

        let currentUserId = client.userId.flatMap { UUID(uuidString: $0) }

        try await updateConflictStatus(
            conflictId: conflictId,
            status: .dismissed,
            resolvedBy: currentUserId,
            reason: reason
        )

        // Update local state
        await MainActor.run {
            if let index = pendingConflicts.firstIndex(where: { $0.id == conflictId }) {
                let dismissed = DataConflict(
                    id: conflict.id,
                    patientId: conflict.patientId,
                    metricType: conflict.metricType,
                    conflictDate: conflict.conflictDate,
                    sources: conflict.sources,
                    status: .dismissed,
                    resolvedValue: nil,
                    resolvedSource: nil,
                    resolvedAt: Date(),
                    resolvedBy: currentUserId
                )
                pendingConflicts.remove(at: index)
                recentlyResolved.insert(dismissed, at: 0)
            }
        }

        DebugLogger.shared.log("Dismissed conflict \(conflictId)", level: .info)
    }

    // MARK: - Bulk Operations

    /// Auto-resolve all eligible pending conflicts
    /// - Parameter patientId: The patient's UUID
    /// - Returns: Number of conflicts auto-resolved
    func autoResolveAll(patientId: UUID) async throws -> Int {
        var resolvedCount = 0

        for conflict in pendingConflicts {
            if autoResolve(conflict) != nil {
                try await saveAutoResolution(conflict)
                resolvedCount += 1
            }
        }

        return resolvedCount
    }

    /// Dismiss all pending conflicts
    /// - Parameter patientId: The patient's UUID
    func dismissAll(patientId: UUID) async throws {
        for conflict in pendingConflicts {
            try await dismissConflict(conflict.id)
        }
    }

    // MARK: - Summary

    /// Get conflict summary for a patient
    /// - Parameter patientId: The patient's UUID
    func getConflictSummary(patientId: UUID) async throws -> ConflictSummary {
        do {
            let response = try await client.client
                .from("data_conflicts")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .limit(500)
                .execute()

            let decoder = PTSupabaseClient.flexibleDecoder
            let allConflicts = try decoder.decode([DataConflict].self, from: response.data)

            let pending = allConflicts.filter { $0.status == .pending }.count
            let autoResolved = allConflicts.filter { $0.status == .autoResolved }.count
            let userResolved = allConflicts.filter { $0.status == .userResolved }.count
            let dismissed = allConflicts.filter { $0.status == .dismissed }.count

            // Find most common metric
            let metricCounts = allConflicts.safeGrouped(by: { $0.metricType })
            let mostCommon = metricCounts.max(by: { $0.value.count < $1.value.count })?.key

            // Find most frequent conflict source pair
            let sourcePairs = allConflicts.flatMap { conflict -> [String] in
                conflict.sources.map { $0.sourceType }
            }
            let sourceFrequency = sourcePairs.safeGrouped(by: { $0 })
            let mostFrequentSource = sourceFrequency.max(by: { $0.value.count < $1.value.count })?.key

            return ConflictSummary(
                pendingCount: pending,
                autoResolvedCount: autoResolved,
                userResolvedCount: userResolved,
                dismissedCount: dismissed,
                totalCount: allConflicts.count,
                mostCommonMetric: mostCommon,
                mostFrequentConflictSource: mostFrequentSource
            )
        } catch {
            ErrorLogger.shared.logError(error, context: "ConflictResolutionService.getConflictSummary")
            throw error
        }
    }

    // MARK: - Private Helpers

    /// Update conflict resolution in database
    private func updateConflictResolution(
        conflictId: UUID,
        status: ConflictStatus,
        resolvedValue: AnyCodableValue?,
        resolvedSource: String?,
        resolvedBy: UUID?
    ) async throws {
        let update = ConflictResolutionUpdate(
            status: status.rawValue,
            resolvedValue: resolvedValue,
            resolvedSource: resolvedSource,
            resolvedAt: Date(),
            resolvedBy: resolvedBy?.uuidString
        )

        try await client.client
            .from("data_conflicts")
            .update(update)
            .eq("id", value: conflictId.uuidString)
            .execute()
    }

    /// Update only the status of a conflict
    private func updateConflictStatus(
        conflictId: UUID,
        status: ConflictStatus,
        resolvedBy: UUID?,
        reason: String?
    ) async throws {
        let update = ConflictStatusUpdate(
            status: status.rawValue,
            resolvedAt: Date(),
            resolvedBy: resolvedBy?.uuidString
        )

        try await client.client
            .from("data_conflicts")
            .update(update)
            .eq("id", value: conflictId.uuidString)
            .execute()

        // Log to audit table
        if let reason = reason {
            let auditEntry = ConflictAuditInsert(
                conflictId: conflictId.uuidString,
                action: ConflictAction.dismissed.rawValue,
                newStatus: status.rawValue,
                resolvedBy: resolvedBy?.uuidString,
                reason: reason
            )

            try await client.client
                .from("conflict_audit_log")
                .insert(auditEntry)
                .execute()
        }
    }

    // MARK: - Error Handling

    /// Clear any stored error
    func clearError() {
        error = nil
        showError = false
        errorMessage = ""
    }
}

// MARK: - RPC Parameters

private struct DetectConflictsParams: Encodable {
    let pPatientId: String
    let pDate: String

    enum CodingKeys: String, CodingKey {
        case pPatientId = "p_patient_id"
        case pDate = "p_date"
    }
}

// MARK: - Update Models

private struct ConflictResolutionUpdate: Encodable {
    let status: String
    let resolvedValue: AnyCodableValue?
    let resolvedSource: String?
    let resolvedAt: Date
    let resolvedBy: String?

    enum CodingKeys: String, CodingKey {
        case status
        case resolvedValue = "resolved_value"
        case resolvedSource = "resolved_source"
        case resolvedAt = "resolved_at"
        case resolvedBy = "resolved_by"
    }
}

private struct ConflictStatusUpdate: Encodable {
    let status: String
    let resolvedAt: Date
    let resolvedBy: String?

    enum CodingKeys: String, CodingKey {
        case status
        case resolvedAt = "resolved_at"
        case resolvedBy = "resolved_by"
    }
}

private struct ConflictAuditInsert: Encodable {
    let conflictId: String
    let action: String
    let newStatus: String
    let resolvedBy: String?
    let reason: String?

    enum CodingKeys: String, CodingKey {
        case conflictId = "conflict_id"
        case action
        case newStatus = "new_status"
        case resolvedBy = "resolved_by"
        case reason
    }
}

// MARK: - Conflict Resolution Error

/// Errors specific to conflict resolution
enum ConflictResolutionError: LocalizedError {
    case conflictNotFound
    case invalidSource
    case cannotAutoResolve
    case resolutionFailed(Error)
    case fetchFailed(Error)

    var errorDescription: String? {
        switch self {
        case .conflictNotFound:
            return "Conflict not found"
        case .invalidSource:
            return "Invalid source selected"
        case .cannotAutoResolve:
            return "Cannot automatically resolve this conflict"
        case .resolutionFailed(let error):
            return "Failed to resolve conflict: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch conflicts: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .conflictNotFound:
            return "The conflict may have been resolved by another device."
        case .invalidSource:
            return "Please select a valid data source."
        case .cannotAutoResolve:
            return "Please manually select the correct value."
        case .resolutionFailed:
            return "Please try again. If the problem persists, contact support."
        case .fetchFailed:
            return "Check your internet connection and try again."
        }
    }
}

// MARK: - Preview Support

extension ConflictResolutionService {
    /// Preview instance with mock data
    static var preview: ConflictResolutionService {
        let service = ConflictResolutionService()
        service.pendingConflicts = DataConflict.generateSampleConflicts(count: 3).filter { $0.status == .pending }
        service.recentlyResolved = DataConflict.generateSampleConflicts(count: 5).filter { $0.status != .pending }
        return service
    }
}
