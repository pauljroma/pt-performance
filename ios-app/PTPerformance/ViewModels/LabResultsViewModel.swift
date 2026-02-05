import SwiftUI

@MainActor
final class LabResultsViewModel: ObservableObject {
    @Published var labResults: [LabResult] = []
    @Published var selectedResult: LabResult?
    @Published var isLoading = false
    @Published var error: String?
    @Published var showingAddSheet = false
    @Published var showingDetailSheet = false

    // AI Analysis State
    @Published var labAnalysis: LabAnalysis?
    @Published var isAnalyzing = false
    @Published var analysisError: String?
    @Published var biomarkerTrendData: [BiomarkerTrendPoint] = []
    @Published var isLoadingTrends = false

    private let service = LabResultService.shared

    func loadResults() async {
        isLoading = true
        error = nil
        await service.fetchLabResults()
        labResults = service.labResults
        if let serviceError = service.error {
            error = serviceError.localizedDescription
        }
        isLoading = false
    }

    func selectResult(_ result: LabResult) {
        selectedResult = result
        showingDetailSheet = true
    }

    func deleteResult(_ result: LabResult) async {
        do {
            try await service.deleteLabResult(result.id)
            await loadResults()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func getAIAnalysis(for result: LabResult) async -> String {
        do {
            let analysis = try await fetchAIAnalysis(for: result)
            return analysis.analysisText
        } catch {
            return "Unable to generate analysis: \(error.localizedDescription)"
        }
    }

    // MARK: - AI Analysis Methods

    /// Fetches comprehensive AI analysis for a lab result
    ///
    /// - Parameter result: The lab result to analyze
    /// - Returns: LabAnalysis containing AI insights
    func fetchAIAnalysis(for result: LabResult) async throws -> LabAnalysis {
        isAnalyzing = true
        analysisError = nil

        defer { isAnalyzing = false }

        do {
            let analysis = try await service.analyzeLabResult(result)
            labAnalysis = analysis
            return analysis
        } catch {
            let errorMessage = error.localizedDescription
            analysisError = errorMessage
            throw error
        }
    }

    /// Fetches biomarker trend data for chart visualization
    ///
    /// - Parameter biomarkerType: The type of biomarker to fetch trends for
    func fetchBiomarkerTrends(for biomarkerType: String) async {
        isLoadingTrends = true
        defer { isLoadingTrends = false }

        do {
            biomarkerTrendData = try await service.fetchBiomarkerHistory(biomarkerType: biomarkerType)
        } catch {
            DebugLogger.shared.error("LabResultsViewModel", "Failed to fetch trends: \(error)")
            biomarkerTrendData = []
        }
    }

    /// Clears the current analysis state
    func clearAnalysis() {
        labAnalysis = nil
        analysisError = nil
        biomarkerTrendData = []
        service.clearAnalysis()
    }

    // MARK: - Computed Properties

    var groupedResults: [(LabTestType, [LabResult])] {
        let grouped = Dictionary(grouping: labResults, by: { $0.testTypeValue })
        return grouped.sorted { $0.key.displayName < $1.key.displayName }
    }

    var recentResults: [LabResult] {
        Array(labResults.prefix(5))
    }
}
