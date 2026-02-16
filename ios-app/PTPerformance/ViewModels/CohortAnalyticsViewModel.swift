//
//  CohortAnalyticsViewModel.swift
//  PTPerformance
//
//  ViewModel for the Cohort Analytics Dashboard
//  Manages cohort data, patient comparisons, and analytics state
//

import SwiftUI
import Combine

/// ViewModel for the Cohort Analytics Dashboard
/// Provides real-time cohort metrics and patient benchmarking
@MainActor
class CohortAnalyticsViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Cohort benchmark data
    @Published var benchmarks: CohortBenchmarks?

    /// Patient rankings list
    @Published var patientRankings: [PatientRankingEntry] = []

    /// Compliance distribution histogram data
    @Published var complianceDistribution: ComplianceDistribution?

    /// Retention curve data
    @Published var retentionData: RetentionData?

    /// Program outcomes data
    @Published var programOutcomes: ProgramOutcomes?

    /// Individual patient comparisons (cached)
    @Published var patientComparisons: [UUID: PatientComparison] = [:]

    /// Selected patient for detail view
    @Published var selectedPatientComparison: PatientComparison?

    /// Loading state
    @Published var isLoading = false

    /// Loading states for individual sections
    @Published var isLoadingBenchmarks = false
    @Published var isLoadingRankings = false
    @Published var isLoadingDistribution = false
    @Published var isLoadingRetention = false
    @Published var isLoadingPrograms = false

    /// Error message for display
    @Published var errorMessage: String?

    /// Current sort key for rankings
    @Published var rankingSortKey: CohortAnalyticsService.PatientRankingSortKey = .progressScore

    /// Sort order (ascending or descending)
    @Published var rankingSortAscending = false

    /// Search text for filtering rankings
    @Published var searchText = ""

    /// Selected time period for metrics
    @Published var selectedPeriod: TimePeriod = .threeMonths

    /// Last refresh timestamp
    @Published var lastRefreshDate: Date?

    /// Count of patients below benchmark
    @Published var patientsBelowBenchmark = 0

    // MARK: - Private Properties

    private let cohortService: CohortAnalyticsService
    private var refreshTask: Task<Void, Never>?

    // MARK: - Computed Properties

    /// Filtered patient rankings based on search text
    var filteredRankings: [PatientRankingEntry] {
        guard !searchText.isEmpty else { return patientRankings }

        let search = searchText.lowercased()
        return patientRankings.filter {
            $0.patientName.lowercased().contains(search)
        }
    }

    /// Patients needing attention (below average performance)
    var patientsNeedingAttention: [PatientRankingEntry] {
        patientRankings.filter { $0.status == .needsAttention || $0.status == .atRisk }
    }

    /// Top performing patients
    var topPerformers: [PatientRankingEntry] {
        Array(patientRankings.filter { $0.status == .onTrack }.prefix(5))
    }

    /// Has any data loaded
    var hasData: Bool {
        benchmarks != nil || !patientRankings.isEmpty
    }

    /// User-friendly message when there is no cohort data to display
    var noDataMessage: String? {
        // Only show the message after loading has completed and there is no data
        guard !isLoading else { return nil }
        if benchmarks == nil && patientRankings.isEmpty && complianceDistribution == nil
            && retentionData == nil && programOutcomes == nil {
            return "Cohort analytics will appear once patients begin completing sessions and logging progress."
        }
        return nil
    }

    /// Overall cohort health indicator
    var cohortHealthStatus: CohortHealthStatus {
        guard let benchmarks = benchmarks else { return .unknown }

        if benchmarks.averageAdherence >= 80 && benchmarks.averagePainReduction >= 40 {
            return .excellent
        } else if benchmarks.averageAdherence >= 60 && benchmarks.averagePainReduction >= 25 {
            return .good
        } else if benchmarks.averageAdherence >= 40 {
            return .needsAttention
        } else {
            return .critical
        }
    }

    enum CohortHealthStatus {
        case excellent
        case good
        case needsAttention
        case critical
        case unknown

        var displayName: String {
            switch self {
            case .excellent: return "Excellent"
            case .good: return "Good"
            case .needsAttention: return "Needs Attention"
            case .critical: return "Critical"
            case .unknown: return "Unknown"
            }
        }

        var iconName: String {
            switch self {
            case .excellent: return "star.fill"
            case .good: return "checkmark.circle.fill"
            case .needsAttention: return "exclamationmark.circle.fill"
            case .critical: return "exclamationmark.triangle.fill"
            case .unknown: return "questionmark.circle"
            }
        }

        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .blue
            case .needsAttention: return .orange
            case .critical: return .red
            case .unknown: return .gray
            }
        }
    }

    // MARK: - Initialization

    init(cohortService: CohortAnalyticsService = CohortAnalyticsService()) {
        self.cohortService = cohortService
    }

    deinit {
        refreshTask?.cancel()
    }

    // MARK: - Public Methods

    /// Load all cohort analytics data
    func loadAllData(therapistId: String) async {
        guard !therapistId.isEmpty else {
            errorMessage = "Unable to verify your account. Please sign in again."
            return
        }

        isLoading = true
        errorMessage = nil

        // Load all data concurrently
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadBenchmarks(therapistId: therapistId) }
            group.addTask { await self.loadPatientRankings(therapistId: therapistId) }
            group.addTask { await self.loadComplianceDistribution(therapistId: therapistId) }
            group.addTask { await self.loadRetentionData(therapistId: therapistId) }
            group.addTask { await self.loadProgramOutcomes(therapistId: therapistId) }
            group.addTask { await self.loadPatientsBelowBenchmark(therapistId: therapistId) }
        }

        isLoading = false
        lastRefreshDate = Date()
    }

    /// Load cohort benchmarks
    func loadBenchmarks(therapistId: String) async {
        isLoadingBenchmarks = true
        defer { isLoadingBenchmarks = false }

        do {
            benchmarks = try await cohortService.fetchCohortBenchmarks(therapistId: therapistId)
        } catch {
            DebugLogger.shared.log("Failed to load benchmarks: \(error.localizedDescription)", level: .error)
            errorMessage = "Failed to load benchmarks. Pull to refresh to try again."
        }
    }

    /// Load patient rankings
    func loadPatientRankings(therapistId: String) async {
        isLoadingRankings = true
        defer { isLoadingRankings = false }

        do {
            patientRankings = try await cohortService.fetchPatientRankings(
                therapistId: therapistId,
                sortBy: rankingSortKey,
                ascending: rankingSortAscending
            )
        } catch {
            DebugLogger.shared.log("Failed to load rankings: \(error.localizedDescription)", level: .error)
            errorMessage = "Failed to load rankings. Pull to refresh to try again."
        }
    }

    /// Load compliance distribution
    func loadComplianceDistribution(therapistId: String) async {
        isLoadingDistribution = true
        defer { isLoadingDistribution = false }

        do {
            complianceDistribution = try await cohortService.fetchComplianceDistribution(therapistId: therapistId)
        } catch {
            DebugLogger.shared.log("Failed to load distribution: \(error.localizedDescription)", level: .error)
            errorMessage = "Failed to load compliance distribution. Pull to refresh to try again."
        }
    }

    /// Load retention data
    func loadRetentionData(therapistId: String) async {
        isLoadingRetention = true
        defer { isLoadingRetention = false }

        do {
            retentionData = try await cohortService.fetchRetentionCurve(therapistId: therapistId)
        } catch {
            DebugLogger.shared.log("Failed to load retention: \(error.localizedDescription)", level: .error)
            errorMessage = "Failed to load retention data. Pull to refresh to try again."
        }
    }

    /// Load program outcomes
    func loadProgramOutcomes(therapistId: String) async {
        isLoadingPrograms = true
        defer { isLoadingPrograms = false }

        do {
            programOutcomes = try await cohortService.fetchOutcomesByProgram(therapistId: therapistId)
        } catch {
            DebugLogger.shared.log("Failed to load programs: \(error.localizedDescription)", level: .error)
            errorMessage = "Failed to load program outcomes. Pull to refresh to try again."
        }
    }

    /// Load patients below benchmark count
    func loadPatientsBelowBenchmark(therapistId: String) async {
        do {
            patientsBelowBenchmark = try await cohortService.fetchPatientsBelowBenchmark(therapistId: therapistId)
        } catch {
            DebugLogger.shared.log("Failed to load patients below benchmark: \(error.localizedDescription)", level: .error)
            errorMessage = "Failed to load patients below benchmark. Pull to refresh to try again."
        }
    }

    /// Load comparison for a specific patient
    func loadPatientComparison(patientId: String) async {
        guard !patientId.isEmpty else { return }

        // Check cache first
        if let uuid = UUID(uuidString: patientId), let cached = patientComparisons[uuid] {
            selectedPatientComparison = cached
            return
        }

        do {
            let comparison = try await cohortService.fetchPatientVsCohort(patientId: patientId)
            patientComparisons[comparison.patientId] = comparison
            selectedPatientComparison = comparison
        } catch {
            DebugLogger.shared.log("Failed to load patient comparison: \(error.localizedDescription)", level: .error)
            errorMessage = "Failed to load patient comparison"
        }
    }

    /// Refresh all data
    func refresh(therapistId: String) async {
        await loadAllData(therapistId: therapistId)
    }

    /// Update sort key and reload rankings
    func updateSort(sortKey: CohortAnalyticsService.PatientRankingSortKey, therapistId: String) async {
        if rankingSortKey == sortKey {
            rankingSortAscending.toggle()
        } else {
            rankingSortKey = sortKey
            rankingSortAscending = false
        }

        await loadPatientRankings(therapistId: therapistId)
    }

    /// Start auto-refresh for real-time updates
    func startAutoRefresh(therapistId: String, interval: TimeInterval = 60) {
        refreshTask?.cancel()
        refreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                if !Task.isCancelled {
                    await refresh(therapistId: therapistId)
                }
            }
        }
    }

    /// Stop auto-refresh
    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    /// Clear selected patient comparison
    func clearSelectedPatient() {
        selectedPatientComparison = nil
    }

    /// Get comparison for a patient (from cache or fetch)
    func getPatientComparison(patientId: UUID) -> PatientComparison? {
        return patientComparisons[patientId]
    }
}
