//
//  ConflictResolutionViewModel.swift
//  PTPerformance
//
//  X2Index Command Center - Multi-Source Conflict Resolution (M5)
//  ViewModel for conflict resolution views
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for managing conflict resolution UI state and actions
@MainActor
class ConflictResolutionViewModel: ObservableObject {

    // MARK: - Dependencies

    private let conflictService: ConflictResolutionService
    private let patientId: UUID

    // MARK: - Published State

    @Published var pendingConflicts: [DataConflict] = []
    @Published var resolvedConflicts: [DataConflict] = []
    @Published var selectedConflict: DataConflict?
    @Published var conflictHistory: [ConflictAuditEntry] = []
    @Published var summary: ConflictSummary?

    // MARK: - Filter State

    @Published var selectedMetricFilter: ConflictMetricType?
    @Published var selectedStatusFilter: ConflictStatus?
    @Published var dateRange: TimelineDateRange = .week

    // MARK: - UI State

    @Published var isLoading = false
    @Published var isResolving = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showResolutionSuccess = false
    @Published var showDismissalSuccess = false
    @Published var showAutoResolveSuccess = false
    @Published var autoResolvedCount = 0

    // MARK: - Computed Properties

    /// Whether there are any pending conflicts
    var hasPendingConflicts: Bool {
        !pendingConflicts.isEmpty
    }

    /// Count of pending conflicts
    var pendingCount: Int {
        pendingConflicts.count
    }

    /// Filtered pending conflicts based on selected filters
    var filteredPendingConflicts: [DataConflict] {
        var conflicts = pendingConflicts

        if let metricFilter = selectedMetricFilter {
            conflicts = conflicts.filter { $0.metricType == metricFilter }
        }

        return conflicts
    }

    /// Filtered resolved conflicts based on selected filters
    var filteredResolvedConflicts: [DataConflict] {
        var conflicts = resolvedConflicts

        if let metricFilter = selectedMetricFilter {
            conflicts = conflicts.filter { $0.metricType == metricFilter }
        }

        if let statusFilter = selectedStatusFilter {
            conflicts = conflicts.filter { $0.status == statusFilter }
        }

        return conflicts
    }

    /// Group pending conflicts by date
    var groupedPendingConflicts: [(String, [DataConflict])] {
        let grouped = Dictionary(grouping: filteredPendingConflicts) { conflict in
            conflict.relativeDateString
        }

        return grouped.sorted { pair1, pair2 in
            // Sort by date (Today first, then Yesterday, then by date)
            let order = ["Today": 0, "Yesterday": 1]
            let order1 = order[pair1.key] ?? 2
            let order2 = order[pair2.key] ?? 2

            if order1 != order2 {
                return order1 < order2
            }

            // For dates, sort by actual date
            guard let first1 = pair1.value.first,
                  let first2 = pair2.value.first else {
                return pair1.key < pair2.key
            }
            return first1.conflictDate > first2.conflictDate
        }
    }

    /// Group resolved conflicts by date
    var groupedResolvedConflicts: [(String, [DataConflict])] {
        let grouped = Dictionary(grouping: filteredResolvedConflicts) { conflict in
            conflict.relativeDateString
        }

        return grouped.sorted { pair1, pair2 in
            guard let first1 = pair1.value.first,
                  let first2 = pair2.value.first else {
                return pair1.key < pair2.key
            }
            return first1.conflictDate > first2.conflictDate
        }
    }

    /// Metrics that have pending conflicts (for filter chips)
    var conflictedMetrics: [ConflictMetricType] {
        let metrics = Set(pendingConflicts.map { $0.metricType })
        return ConflictMetricType.allCases.filter { metrics.contains($0) }
    }

    /// Resolution statistics
    var resolutionStats: ResolutionStats {
        let total = pendingConflicts.count + resolvedConflicts.count
        let resolved = resolvedConflicts.count
        let auto = resolvedConflicts.filter { $0.status == .autoResolved }.count
        let manual = resolvedConflicts.filter { $0.status == .userResolved }.count

        return ResolutionStats(
            total: total,
            pending: pendingConflicts.count,
            resolved: resolved,
            autoResolved: auto,
            manuallyResolved: manual,
            resolutionRate: total > 0 ? Double(resolved) / Double(total) * 100 : 0
        )
    }

    // MARK: - Initialization

    init(patientId: UUID, conflictService: ConflictResolutionService = .shared) {
        self.patientId = patientId
        self.conflictService = conflictService
    }

    // MARK: - Load Data

    /// Load all conflict data
    func loadData() async {
        isLoading = true
        showError = false
        errorMessage = ""

        do {
            // Load pending and resolved conflicts in parallel
            async let fetchPending: () = conflictService.fetchPendingConflicts(patientId: patientId)
            async let fetchResolved = conflictService.fetchResolvedConflicts(patientId: patientId)
            async let fetchSummary = conflictService.getConflictSummary(patientId: patientId)

            let (_, resolved, summaryData) = try await (fetchPending, fetchResolved, fetchSummary)

            pendingConflicts = conflictService.pendingConflicts
            resolvedConflicts = resolved
            summary = summaryData

        } catch {
            errorMessage = "Failed to load conflicts: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    /// Refresh data
    func refresh() async {
        await loadData()
    }

    // MARK: - Resolution Actions

    /// Resolve a conflict with selected source
    /// - Parameters:
    ///   - conflict: The conflict to resolve
    ///   - source: The selected source type
    func resolveConflict(_ conflict: DataConflict, with source: String) async {
        isResolving = true

        do {
            try await conflictService.userResolve(conflict.id, selectedSource: source)
            pendingConflicts = conflictService.pendingConflicts
            resolvedConflicts = conflictService.recentlyResolved
            showResolutionSuccess = true
            HapticFeedback.success()
        } catch {
            errorMessage = "Failed to resolve conflict: \(error.localizedDescription)"
            showError = true
            HapticFeedback.error()
        }

        isResolving = false
    }

    /// Resolve a conflict with custom value
    /// - Parameters:
    ///   - conflict: The conflict to resolve
    ///   - value: The custom value
    func resolveConflictWithCustomValue(_ conflict: DataConflict, value: AnyCodableValue) async {
        isResolving = true

        do {
            try await conflictService.userResolveWithCustomValue(conflict.id, customValue: value)
            pendingConflicts = conflictService.pendingConflicts
            resolvedConflicts = conflictService.recentlyResolved
            showResolutionSuccess = true
            HapticFeedback.success()
        } catch {
            errorMessage = "Failed to resolve conflict: \(error.localizedDescription)"
            showError = true
            HapticFeedback.error()
        }

        isResolving = false
    }

    /// Dismiss a conflict
    /// - Parameters:
    ///   - conflict: The conflict to dismiss
    ///   - reason: Optional reason for dismissal
    func dismissConflict(_ conflict: DataConflict, reason: String? = nil) async {
        isResolving = true

        do {
            try await conflictService.dismissConflict(conflict.id, reason: reason)
            pendingConflicts = conflictService.pendingConflicts
            resolvedConflicts = conflictService.recentlyResolved
            showDismissalSuccess = true
            HapticFeedback.light()
        } catch {
            errorMessage = "Failed to dismiss conflict: \(error.localizedDescription)"
            showError = true
            HapticFeedback.error()
        }

        isResolving = false
    }

    /// Auto-resolve all eligible conflicts
    func autoResolveAll() async {
        isResolving = true

        do {
            let count = try await conflictService.autoResolveAll(patientId: patientId)
            pendingConflicts = conflictService.pendingConflicts
            resolvedConflicts = conflictService.recentlyResolved
            autoResolvedCount = count
            showAutoResolveSuccess = true
            HapticFeedback.success()
        } catch {
            errorMessage = "Failed to auto-resolve conflicts: \(error.localizedDescription)"
            showError = true
            HapticFeedback.error()
        }

        isResolving = false
    }

    /// Use highest confidence source for a conflict
    /// - Parameter conflict: The conflict to resolve
    func useHighestConfidence(_ conflict: DataConflict) async {
        guard let bestSource = conflict.highestConfidenceSource else {
            errorMessage = "No sources available"
            showError = true
            return
        }

        await resolveConflict(conflict, with: bestSource.sourceType)
    }

    // MARK: - Conflict History

    /// Load audit history for a specific conflict
    /// - Parameter conflict: The conflict to load history for
    func loadConflictHistory(_ conflict: DataConflict) async {
        do {
            conflictHistory = try await conflictService.fetchConflictAuditLog(conflictId: conflict.id)
        } catch {
            errorMessage = "Failed to load conflict history"
            showError = true
        }
    }

    /// Select a conflict for detail view
    /// - Parameter conflict: The conflict to select
    func selectConflict(_ conflict: DataConflict) {
        selectedConflict = conflict
        Task {
            await loadConflictHistory(conflict)
        }
    }

    /// Clear selected conflict
    func clearSelection() {
        selectedConflict = nil
        conflictHistory = []
    }

    // MARK: - Filters

    /// Toggle metric filter
    /// - Parameter metric: The metric to filter by
    func toggleMetricFilter(_ metric: ConflictMetricType) {
        if selectedMetricFilter == metric {
            selectedMetricFilter = nil
        } else {
            selectedMetricFilter = metric
        }
    }

    /// Clear all filters
    func clearFilters() {
        selectedMetricFilter = nil
        selectedStatusFilter = nil
    }

    // MARK: - Error Handling

    /// Clear error state
    func clearError() {
        showError = false
        errorMessage = ""
    }
}

// MARK: - Resolution Stats

/// Statistics about conflict resolution
struct ResolutionStats {
    let total: Int
    let pending: Int
    let resolved: Int
    let autoResolved: Int
    let manuallyResolved: Int
    let resolutionRate: Double

    /// Formatted resolution rate
    var formattedResolutionRate: String {
        String(format: "%.0f%%", resolutionRate)
    }
}

// MARK: - Preview Support

extension ConflictResolutionViewModel {
    /// Preview instance with mock data
    static var preview: ConflictResolutionViewModel {
        let vm = ConflictResolutionViewModel(patientId: UUID())
        vm.pendingConflicts = DataConflict.generateSampleConflicts(count: 3).filter { $0.status == .pending }
        vm.resolvedConflicts = DataConflict.generateSampleConflicts(count: 5).filter { $0.status != .pending }
        vm.summary = ConflictSummary(
            pendingCount: 3,
            autoResolvedCount: 10,
            userResolvedCount: 15,
            dismissedCount: 2,
            totalCount: 30,
            mostCommonMetric: .sleepDuration,
            mostFrequentConflictSource: "whoop"
        )
        return vm
    }

    /// Preview instance with no conflicts
    static var emptyPreview: ConflictResolutionViewModel {
        let vm = ConflictResolutionViewModel(patientId: UUID())
        vm.pendingConflicts = []
        vm.resolvedConflicts = []
        vm.summary = ConflictSummary(
            pendingCount: 0,
            autoResolvedCount: 0,
            userResolvedCount: 0,
            dismissedCount: 0,
            totalCount: 0,
            mostCommonMetric: nil,
            mostFrequentConflictSource: nil
        )
        return vm
    }
}
