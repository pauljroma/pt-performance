//
//  ProgramEffectivenessViewModel.swift
//  PTPerformance
//
//  ViewModel for Program Effectiveness Analytics
//  Manages state and business logic for effectiveness views
//

import SwiftUI
import Combine

/// ViewModel for the Program Effectiveness Analytics feature
/// Provides data management and business logic for therapists to analyze program outcomes
@MainActor
class ProgramEffectivenessViewModel: ObservableObject {

    // MARK: - Published Properties

    /// All program metrics for the therapist
    @Published var programMetrics: [ProgramMetrics] = []

    /// Currently selected program for detail view
    @Published var selectedProgram: ProgramMetrics?

    /// Programs selected for comparison
    @Published var selectedProgramsForComparison: [ProgramMetrics] = []

    /// Program comparison data
    @Published var comparison: ProgramComparison?

    /// Outcome distribution for selected program
    @Published var outcomeDistribution: OutcomeDistribution?

    /// Phase dropoff data for selected program
    @Published var dropoffData: [PhaseDropoffData] = []

    /// Heatmap data for visualization
    @Published var heatmapData: [HeatmapDataPoint] = []

    /// Patients in the selected program
    @Published var programPatients: [ProgramPatient] = []

    /// Loading state
    @Published var isLoading = false

    /// Loading state for detail data
    @Published var isLoadingDetails = false

    /// Error message for display
    @Published var errorMessage: String?

    /// Search text for filtering programs
    @Published var searchText = ""

    /// Selected program type filter
    @Published var selectedTypeFilter: ProgramType?

    /// Selected effectiveness rating filter
    @Published var selectedRatingFilter: EffectivenessRating?

    /// Selected heatmap metric type
    @Published var selectedHeatmapMetric: HeatmapMetricType = .completion

    /// Show comparison sheet
    @Published var showComparisonSheet = false

    /// Show export options
    @Published var showExportOptions = false

    // MARK: - Private Properties

    private let effectivenessService: ProgramEffectivenessService
    private var refreshTask: Task<Void, Never>?

    // MARK: - Computed Properties

    /// Filtered programs based on current filters
    var filteredPrograms: [ProgramMetrics] {
        var result = programMetrics

        // Apply search filter
        if !searchText.isEmpty {
            let search = searchText.lowercased()
            result = result.filter { program in
                program.programName.lowercased().contains(search)
            }
        }

        // Apply type filter
        if let typeFilter = selectedTypeFilter {
            result = result.filter { $0.resolvedProgramType == typeFilter }
        }

        // Apply rating filter
        if let ratingFilter = selectedRatingFilter {
            result = result.filter { $0.effectivenessRating == ratingFilter }
        }

        return result
    }

    /// Programs available for comparison (not already selected)
    var availableForComparison: [ProgramMetrics] {
        let selectedIds = Set(selectedProgramsForComparison.map { $0.id })
        return programMetrics.filter { !selectedIds.contains($0.id) }
    }

    /// Whether comparison can be made (2-3 programs selected)
    var canCompare: Bool {
        selectedProgramsForComparison.count >= 2 && selectedProgramsForComparison.count <= 3
    }

    /// Summary statistics
    var summaryStats: ProgramSummaryStats {
        let totalPrograms = programMetrics.count
        let avgCompletionRate = programMetrics.isEmpty ? 0 :
            programMetrics.map { $0.completionRateValue }.reduce(0, +) / Double(totalPrograms)
        let avgEffectiveness = programMetrics.isEmpty ? 0 :
            programMetrics.map { $0.effectivenessScore }.reduce(0, +) / Double(totalPrograms)
        let totalPatients = programMetrics.map { $0.totalEnrollmentsValue }.reduce(0, +)

        return ProgramSummaryStats(
            totalPrograms: totalPrograms,
            averageCompletionRate: avgCompletionRate,
            averageEffectiveness: avgEffectiveness,
            totalPatients: totalPatients
        )
    }

    /// Top performing programs
    var topPrograms: [ProgramMetrics] {
        Array(programMetrics.prefix(3))
    }

    /// Programs needing attention
    var programsNeedingAttention: [ProgramMetrics] {
        programMetrics.filter { $0.effectivenessRating == .needsImprovement }
    }

    // MARK: - Initialization

    init(effectivenessService: ProgramEffectivenessService = ProgramEffectivenessService()) {
        self.effectivenessService = effectivenessService
    }

    deinit {
        refreshTask?.cancel()
    }

    // MARK: - Public Methods

    /// Load all program metrics for the therapist
    func loadProgramMetrics(therapistId: String) async {
        guard !therapistId.isEmpty else {
            DebugLogger.shared.log("SECURITY: Cannot load metrics without therapist ID", level: .error)
            errorMessage = "Unable to verify your account. Please sign in again."
            return
        }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            programMetrics = try await effectivenessService.fetchProgramMetrics(therapistId: therapistId)
            DebugLogger.shared.log("Loaded \(programMetrics.count) program metrics", level: .success)
        } catch {
            DebugLogger.shared.log("Failed to load program metrics: \(error.localizedDescription)", level: .error)
            errorMessage = "Failed to load program metrics. Please try again."
        }
    }

    /// Load detailed data for a specific program
    func loadProgramDetails(programId: UUID) async {
        isLoadingDetails = true
        errorMessage = nil

        defer { isLoadingDetails = false }

        do {
            // Load all details in parallel
            async let outcomes = effectivenessService.fetchProgramOutcomes(programId: programId)
            async let dropoff = effectivenessService.fetchProgramDropoffAnalysis(programId: programId)
            async let patients = effectivenessService.fetchProgramPatients(programId: programId)
            async let heatmap = effectivenessService.fetchHeatmapData(
                programId: programId,
                metricType: selectedHeatmapMetric
            )

            outcomeDistribution = try await outcomes
            dropoffData = try await dropoff
            programPatients = try await patients
            heatmapData = try await heatmap

            DebugLogger.shared.log("Loaded program details successfully", level: .success)
        } catch {
            DebugLogger.shared.log("Failed to load program details: \(error.localizedDescription)", level: .error)
            errorMessage = "Failed to load program details."
        }
    }

    /// Load comparison data for selected programs
    func loadComparison() async {
        guard canCompare else {
            errorMessage = "Please select 2-3 programs to compare."
            return
        }

        isLoadingDetails = true
        errorMessage = nil

        defer { isLoadingDetails = false }

        do {
            let programIds = selectedProgramsForComparison.compactMap { $0.programId }
            comparison = try await effectivenessService.fetchProgramComparison(programIds: programIds)
            DebugLogger.shared.log("Loaded comparison for \(programIds.count) programs", level: .success)
        } catch {
            DebugLogger.shared.log("Failed to load comparison: \(error.localizedDescription)", level: .error)
            errorMessage = "Failed to load comparison data."
        }
    }

    /// Update heatmap data for a new metric type
    func updateHeatmapMetric(_ metricType: HeatmapMetricType) async {
        guard let program = selectedProgram else { return }

        selectedHeatmapMetric = metricType

        guard let programId = program.programId else { return }
        do {
            heatmapData = try await effectivenessService.fetchHeatmapData(
                programId: programId,
                metricType: metricType
            )
        } catch {
            DebugLogger.shared.log("Failed to update heatmap: \(error.localizedDescription)", level: .error)
        }
    }

    /// Select a program for detailed view
    func selectProgram(_ program: ProgramMetrics) {
        selectedProgram = program
        guard let programId = program.programId else { return }
        Task {
            await loadProgramDetails(programId: programId)
        }
    }

    /// Toggle program selection for comparison
    func toggleProgramForComparison(_ program: ProgramMetrics) {
        if let index = selectedProgramsForComparison.firstIndex(where: { $0.id == program.id }) {
            selectedProgramsForComparison.remove(at: index)
        } else if selectedProgramsForComparison.count < 3 {
            selectedProgramsForComparison.append(program)
        }
        HapticFeedback.selectionChanged()
    }

    /// Clear comparison selection
    func clearComparisonSelection() {
        selectedProgramsForComparison.removeAll()
        comparison = nil
    }

    /// Clear all filters
    func clearFilters() {
        searchText = ""
        selectedTypeFilter = nil
        selectedRatingFilter = nil
    }

    /// Refresh data
    func refresh(therapistId: String) async {
        await loadProgramMetrics(therapistId: therapistId)
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

    /// Generate export image for comparison
    @MainActor
    func generateComparisonImage() -> UIImage? {
        guard let comparison = comparison else { return nil }

        // Create a renderer to capture the comparison view
        let renderer = ImageRenderer(content: ComparisonExportView(comparison: comparison))
        renderer.scale = UIScreen.main.scale

        return renderer.uiImage
    }

    /// Share comparison image
    func shareComparison() {
        showExportOptions = true
    }
}

// MARK: - Supporting Types

/// Summary statistics for all programs
struct ProgramSummaryStats {
    let totalPrograms: Int
    let averageCompletionRate: Double
    let averageEffectiveness: Double
    let totalPatients: Int

    var formattedCompletionRate: String {
        String(format: "%.0f%%", averageCompletionRate * 100)
    }

    var formattedEffectiveness: String {
        String(format: "%.0f%%", averageEffectiveness * 100)
    }
}

// MARK: - Export View for Image Generation

private struct ComparisonExportView: View {
    let comparison: ProgramComparison

    var body: some View {
        VStack(spacing: 16) {
            Text("Program Comparison")
                .font(.title2)
                .fontWeight(.bold)

            Text("Generated \(comparison.comparisonDate, style: .date)")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(comparison.programs) { program in
                VStack(alignment: .leading, spacing: 8) {
                    Text(program.programName)
                        .font(.headline)

                    HStack(spacing: 16) {
                        VStack {
                            Text("Completion")
                                .font(.caption)
                            Text(program.formattedCompletionRate)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }

                        VStack {
                            Text("Adherence")
                                .font(.caption)
                            Text(program.formattedAdherence)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }

                        VStack {
                            Text("Effectiveness")
                                .font(.caption)
                            Text(String(format: "%.0f%%", program.effectivenessScore * 100))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
            }

            Text("Modus")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
