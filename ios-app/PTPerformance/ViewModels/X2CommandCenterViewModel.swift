//
//  X2CommandCenterViewModel.swift
//  PTPerformance
//
//  Phase 3 Integration - X2 Command Center ViewModel
//  Manages state for the unified command center view
//

import Foundation
import SwiftUI
import Combine

// MARK: - X2 Command Center ViewModel

@MainActor
final class X2CommandCenterViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var activeEscalations: [SafetyIncident] = []
    @Published private(set) var pendingConflicts: [ConflictGroup] = []
    @Published private(set) var recentReports: [WeeklyReportSummary] = []
    @Published private(set) var isLoading = false
    @Published private(set) var hasLoaded = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var loadError: String?

    // MARK: - Private Properties

    private let safetyService = SafetyService.shared
    private let conflictService = ConflictResolutionService.shared
    private let reportService = WeeklyReportService.shared
    private let supabase = PTSupabaseClient.shared
    private var therapistId: String?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Demo Mode

    /// Whether to use demo data instead of live backend data
    /// Enabled via USE_DEMO_DATA environment variable or when not authenticated
    private var useDemoData: Bool {
        #if DEBUG
        return ProcessInfo.isDemoMode || supabase.currentSession == nil
        #else
        return false
        #endif
    }

    // MARK: - Initialization

    init() {
        setupObservers()
    }

    deinit {
        cancellables.removeAll()
    }

    // MARK: - Public Methods

    /// Load all command center data
    func load(therapistId: String) async {
        self.therapistId = therapistId
        isLoading = true

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadEscalations() }
            group.addTask { await self.loadConflicts() }
            group.addTask { await self.loadReports() }
        }

        isLoading = false
        hasLoaded = true
    }

    /// Refresh all data
    func refresh() async {
        guard let therapistId = therapistId else { return }
        await load(therapistId: therapistId)
    }

    /// Get badge count for a section
    func badgeCount(for section: X2CommandCenterView.CommandCenterSection) -> Int {
        switch section {
        case .overview:
            return 0
        case .escalations:
            return activeEscalations.count
        case .conflicts:
            return pendingConflicts.count
        case .reports:
            return recentReports.filter { !$0.isReady }.count
        }
    }

    /// Acknowledge an escalation with haptic feedback
    func acknowledgeEscalation(_ escalation: SafetyIncident) async {
        HapticService.success()

        do {
            guard let userId = UUID(uuidString: supabase.userId ?? "") else { return }

            try await safetyService.resolveIncident(
                incidentId: escalation.id,
                resolution: IncidentResolution(
                    incidentId: escalation.id,
                    resolvedBy: userId,
                    notes: "Acknowledged via Command Center"
                )
            )

            // Animate removal
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                activeEscalations.removeAll { $0.id == escalation.id }
            }
        } catch {
            HapticService.error()
            errorMessage = "Failed to acknowledge escalation: \(error.localizedDescription)"
        }
    }

    /// Resolve a conflict with haptic feedback
    func resolveConflict(_ conflict: ConflictGroup, resolution: ConflictResolution) async {
        HapticService.success()

        do {
            // Resolve the conflict based on resolution type
            switch resolution.resolution {
            case .useSource(let sourceId):
                // Find the source type string from the ID
                try await conflictService.userResolve(conflict.id, selectedSource: sourceId.uuidString)
            case .useAverage:
                // For average, we dismiss with a note
                try await conflictService.dismissConflict(conflict.id, reason: "Resolved with average value")
            case .dismiss:
                try await conflictService.dismissConflict(conflict.id, reason: resolution.notes)
            case .manual(let value):
                try await conflictService.userResolveWithCustomValue(conflict.id, customValue: .string(value))
            }

            // Remove from local state with animation
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                pendingConflicts.removeAll { $0.id == conflict.id }
            }
        } catch {
            HapticService.error()
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    // MARK: - Private Methods

    private func setupObservers() {
        // Listen for safety incidents updates
        NotificationCenter.default.publisher(for: .safetyIncidentUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.loadEscalations()
                }
            }
            .store(in: &cancellables)
    }

    private func loadEscalations() async {
        // Use demo data when in demo mode
        if useDemoData {
            activeEscalations = DemoDataProvider.sampleSafetyIncidents
            return
        }

        let incidents = await safetyService.getOpenIncidents()

        // Sort by severity (critical first) then by age (oldest first)
        let sorted = incidents.sorted { lhs, rhs in
            if lhs.severity.sortOrder != rhs.severity.sortOrder {
                return lhs.severity.sortOrder < rhs.severity.sortOrder
            }
            return lhs.createdAt < rhs.createdAt
        }

        activeEscalations = sorted
    }

    private func loadConflicts() async {
        // Use demo data when in demo mode
        if useDemoData {
            pendingConflicts = DemoDataProvider.sampleConflictGroups
            return
        }

        guard let therapistId = therapistId else { return }

        do {
            // Get pending conflicts for therapist's patients
            let conflicts = try await conflictService.getPendingConflicts(for: therapistId)
            pendingConflicts = conflicts.map { ConflictGroup(from: $0) }
        } catch {
            DebugLogger.shared.log("Failed to load conflicts: \(error)", level: .error)
        }
    }

    private func loadReports() async {
        // Use demo data when in demo mode
        if useDemoData {
            recentReports = DemoDataProvider.sampleReportSummaries
            return
        }

        guard let therapistId = therapistId else { return }

        do {
            let reports = try await reportService.getRecentReports(for: therapistId, limit: 5)
            recentReports = reports.map { WeeklyReportSummary(from: $0) }
            loadError = nil
        } catch {
            DebugLogger.shared.log("Failed to load reports: \(error)", level: .error)
            // Show empty state instead of mock data
            self.recentReports = []
            self.loadError = "Unable to load reports. Pull to refresh."
        }
    }
}

// MARK: - Conflict Resolution

struct ConflictResolution {
    let conflictId: UUID
    let resolution: ResolutionType
    let preferredSourceId: UUID?
    let notes: String?

    enum ResolutionType {
        case useSource(UUID)
        case useAverage
        case dismiss
        case manual(value: String)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let safetyIncidentUpdated = Notification.Name("safetyIncidentUpdated")
    static let conflictResolved = Notification.Name("conflictResolved")
    static let reportGenerated = Notification.Name("reportGenerated")
}
