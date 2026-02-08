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

// MARK: - Weekly Report Summary Model

struct WeeklyReportSummary: Identifiable, Codable {
    let id: UUID
    let title: String
    let dateRange: String
    let patientCount: Int
    let isReady: Bool
    let highlights: String?
    let generatedAt: Date?
    let pdfUrl: String?

    init(
        id: UUID = UUID(),
        title: String,
        dateRange: String,
        patientCount: Int,
        isReady: Bool = true,
        highlights: String? = nil,
        generatedAt: Date? = nil,
        pdfUrl: String? = nil
    ) {
        self.id = id
        self.title = title
        self.dateRange = dateRange
        self.patientCount = patientCount
        self.isReady = isReady
        self.highlights = highlights
        self.generatedAt = generatedAt
        self.pdfUrl = pdfUrl
    }
}

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

    // MARK: - Private Properties

    private let safetyService = SafetyService.shared
    private let supabase = PTSupabaseClient.shared
    private var therapistId: String?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        setupObservers()
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

        // TODO: Implement conflict resolution service
        // For now, just remove from local state
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            pendingConflicts.removeAll { $0.id == conflict.id }
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
        // TODO: Implement conflict loading from timeline service
        // For now, return empty or mock data
        pendingConflicts = []
    }

    private func loadReports() async {
        // TODO: Implement report loading from report service
        // For now, return mock data for development
        #if DEBUG
        recentReports = [
            WeeklyReportSummary(
                title: "Weekly Progress Report",
                dateRange: "Feb 1 - Feb 7, 2026",
                patientCount: 12,
                highlights: "8 patients improved adherence. 2 new PRs logged."
            ),
            WeeklyReportSummary(
                title: "Weekly Progress Report",
                dateRange: "Jan 25 - Jan 31, 2026",
                patientCount: 11,
                highlights: "Average adherence: 87%. 1 escalation resolved."
            )
        ]
        #endif
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
