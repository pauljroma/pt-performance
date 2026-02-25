//
//  EscalationQueueViewModel.swift
//  PTPerformance
//
//  ViewModel for Escalation Queue management
//  Part of Risk Escalation System (M4) - X2Index Command Center
//

import SwiftUI
import Combine

// MARK: - Escalation Queue ViewModel

/// ViewModel for managing the escalation queue UI
@MainActor
class EscalationQueueViewModel: ObservableObject {

    // MARK: - Published Properties

    /// All active escalations
    @Published private(set) var escalations: [RiskEscalation] = []

    /// Patient data cache
    @Published private(set) var patients: [UUID: Patient] = [:]

    /// Current filter settings
    @Published var filter = EscalationFilter()

    /// Summary statistics
    @Published private(set) var summary: EscalationSummary = .empty

    /// Loading state
    @Published private(set) var isLoading = false

    /// Error message
    @Published var errorMessage: String?

    /// Selection mode for bulk actions
    @Published var isSelectionMode = false

    /// Selected escalation IDs for bulk actions
    @Published var selectedIds: Set<UUID> = []

    // MARK: - Computed Properties

    /// Escalations filtered by current filter settings
    var filteredEscalations: [RiskEscalation] {
        escalations.filter { escalation in
            // Filter by severity
            guard filter.severities.contains(escalation.severity) else { return false }

            // Filter by type
            guard filter.types.contains(escalation.escalationType) else { return false }

            // Filter by status
            guard filter.statuses.contains(escalation.status) else { return false }

            // Filter by patient if specified
            if let patientId = filter.patientId, escalation.patientId != patientId {
                return false
            }

            return true
        }
    }

    /// Escalations grouped by severity
    var groupedBySeverity: [EscalationSeverity: [RiskEscalation]] {
        Dictionary(grouping: filteredEscalations) { $0.severity }
    }

    /// Count of pending (unacknowledged) escalations
    var pendingCount: Int {
        escalations.filter { $0.acknowledgedAt == nil }.count
    }

    // MARK: - Dependencies

    private let escalationService: RiskEscalationService
    private let supabase: PTSupabaseClient
    private let debugLogger: DebugLogger
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        escalationService: RiskEscalationService = .shared,
        supabase: PTSupabaseClient = .shared,
        debugLogger: DebugLogger = .shared
    ) {
        self.escalationService = escalationService
        self.supabase = supabase
        self.debugLogger = debugLogger

        setupBindings()
    }

    deinit {
        cancellables.removeAll()
    }

    // MARK: - Setup

    private func setupBindings() {
        // Sync with service state
        escalationService.$activeEscalations
            .receive(on: DispatchQueue.main)
            .sink { [weak self] escalations in
                self?.escalations = escalations
            }
            .store(in: &cancellables)

        escalationService.$summary
            .receive(on: DispatchQueue.main)
            .sink { [weak self] summary in
                self?.summary = summary
            }
            .store(in: &cancellables)

        // Clear selection when exiting selection mode
        $isSelectionMode
            .dropFirst()
            .filter { !$0 }
            .sink { [weak self] _ in
                self?.selectedIds.removeAll()
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Loading

    /// Load all escalations for the current therapist
    func loadEscalations() async {
        guard let therapistId = supabase.userId else {
            errorMessage = "Please sign in to view escalations"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await escalationService.fetchActiveEscalations(for: therapistId)

            // Load patient data for all escalations
            await loadPatientData()

            debugLogger.log("[EscalationQueueVM] Loaded \(escalations.count) escalations", level: .success)
        } catch {
            errorMessage = "Couldn't load safety alerts. Please try again."
            debugLogger.log("[EscalationQueueVM] Failed to load escalations: \(error)", level: .error)
        }
    }

    /// Refresh escalations
    func refresh() async {
        await loadEscalations()
    }

    /// Load patient data for all unique patient IDs
    private func loadPatientData() async {
        let patientIds = Set(escalations.map { $0.patientId })
        let missingIds = patientIds.filter { patients[$0] == nil }

        guard !missingIds.isEmpty else { return }

        do {
            let response = try await supabase.client
                .from("patients")
                .select()
                .in("id", values: missingIds.map { $0.uuidString })
                .execute()

            let decoder = PTSupabaseClient.flexibleDecoder

            let loadedPatients = try decoder.decode([Patient].self, from: response.data)

            for patient in loadedPatients {
                patients[patient.id] = patient
            }

            debugLogger.log("[EscalationQueueVM] Loaded \(loadedPatients.count) patients", level: .success)
        } catch {
            debugLogger.log("[EscalationQueueVM] Failed to load patients: \(error)", level: .error)
        }
    }

    /// Get patient for a given ID
    func patient(for patientId: UUID) -> Patient? {
        patients[patientId]
    }

    // MARK: - Selection Actions

    /// Toggle selection for an escalation
    func toggleSelection(_ id: UUID) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
    }

    /// Select all visible escalations
    func selectAll() {
        selectedIds = Set(filteredEscalations.map { $0.id })
    }

    /// Deselect all escalations
    func deselectAll() {
        selectedIds.removeAll()
    }

    // MARK: - Escalation Actions

    /// Acknowledge a single escalation
    func acknowledge(_ id: UUID) async {
        do {
            _ = try await escalationService.acknowledgeEscalation(id)
            debugLogger.log("[EscalationQueueVM] Acknowledged escalation \(id)", level: .success)
        } catch {
            errorMessage = "Couldn't acknowledge alert. Please try again."
            debugLogger.log("[EscalationQueueVM] Failed to acknowledge: \(error)", level: .error)
        }
    }

    /// Acknowledge all pending escalations
    func acknowledgeAll() async {
        let pendingIds = escalations
            .filter { $0.acknowledgedAt == nil }
            .map { $0.id }

        guard !pendingIds.isEmpty else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await escalationService.bulkAcknowledge(ids: pendingIds)
            debugLogger.log("[EscalationQueueVM] Acknowledged \(pendingIds.count) escalations", level: .success)
        } catch {
            errorMessage = "Couldn't acknowledge all alerts. Please try again."
            debugLogger.log("[EscalationQueueVM] Failed to bulk acknowledge: \(error)", level: .error)
        }
    }

    /// Bulk acknowledge selected escalations
    func bulkAcknowledge() async {
        guard !selectedIds.isEmpty else { return }

        let unacknowledgedIds = selectedIds.filter { id in
            escalations.first { $0.id == id }?.acknowledgedAt == nil
        }

        guard !unacknowledgedIds.isEmpty else {
            isSelectionMode = false
            return
        }

        isLoading = true
        defer {
            isLoading = false
            isSelectionMode = false
        }

        do {
            try await escalationService.bulkAcknowledge(ids: Array(unacknowledgedIds))
            debugLogger.log("[EscalationQueueVM] Bulk acknowledged \(unacknowledgedIds.count) escalations", level: .success)
        } catch {
            errorMessage = "Couldn't acknowledge selected alerts. Please try again."
            debugLogger.log("[EscalationQueueVM] Failed to bulk acknowledge: \(error)", level: .error)
        }
    }

    /// Resolve an escalation with notes
    func resolve(_ id: UUID, notes: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await escalationService.resolveEscalation(id, notes: notes)
            debugLogger.log("[EscalationQueueVM] Resolved escalation \(id)", level: .success)
        } catch {
            errorMessage = "Couldn't resolve alert. Please try again."
            debugLogger.log("[EscalationQueueVM] Failed to resolve: \(error)", level: .error)
        }
    }

    /// Dismiss an escalation as false positive
    func dismiss(_ id: UUID, reason: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await escalationService.dismissEscalation(id, reason: reason)
            debugLogger.log("[EscalationQueueVM] Dismissed escalation \(id)", level: .success)
        } catch {
            errorMessage = "Couldn't dismiss alert. Please try again."
            debugLogger.log("[EscalationQueueVM] Failed to dismiss: \(error)", level: .error)
        }
    }

    // MARK: - Filter Actions

    /// Apply a preset filter
    func applyFilter(_ preset: EscalationFilterPreset) {
        switch preset {
        case .all:
            filter.reset()
        case .criticalOnly:
            filter = .criticalOnly
        case .pendingOnly:
            filter = .pendingOnly
        case .forPatient(let patientId):
            filter.patientId = patientId
        }
    }

    /// Reset all filters
    func resetFilters() {
        filter.reset()
    }
}

// MARK: - Filter Presets

enum EscalationFilterPreset {
    case all
    case criticalOnly
    case pendingOnly
    case forPatient(UUID)
}

// MARK: - Escalation Statistics

extension EscalationQueueViewModel {

    /// Get statistics for the current escalation set
    var statistics: EscalationStatistics {
        EscalationStatistics(
            total: escalations.count,
            bySeverity: Dictionary(grouping: escalations) { $0.severity }
                .mapValues { $0.count },
            byType: Dictionary(grouping: escalations) { $0.escalationType }
                .mapValues { $0.count },
            pendingCount: escalations.filter { $0.acknowledgedAt == nil }.count,
            acknowledgedCount: escalations.filter { $0.acknowledgedAt != nil && $0.resolvedAt == nil }.count,
            averageResponseTime: calculateAverageResponseTime(),
            oldestPending: escalations
                .filter { $0.acknowledgedAt == nil }
                .min(by: { $0.createdAt < $1.createdAt })?.createdAt
        )
    }

    private func calculateAverageResponseTime() -> TimeInterval? {
        let acknowledgedEscalations = escalations.filter { $0.acknowledgedAt != nil }

        guard !acknowledgedEscalations.isEmpty else { return nil }

        let totalTime = acknowledgedEscalations.reduce(0.0) { total, escalation in
            if let acknowledgedAt = escalation.acknowledgedAt {
                return total + acknowledgedAt.timeIntervalSince(escalation.createdAt)
            }
            return total
        }

        return totalTime / Double(acknowledgedEscalations.count)
    }
}

/// Statistics for escalation analysis
struct EscalationStatistics {
    let total: Int
    let bySeverity: [EscalationSeverity: Int]
    let byType: [EscalationType: Int]
    let pendingCount: Int
    let acknowledgedCount: Int
    let averageResponseTime: TimeInterval?
    let oldestPending: Date?

    /// Formatted average response time
    var formattedResponseTime: String? {
        guard let time = averageResponseTime else { return nil }

        let hours = Int(time / 3600)
        let minutes = Int((time.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
