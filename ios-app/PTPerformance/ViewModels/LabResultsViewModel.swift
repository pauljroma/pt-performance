import SwiftUI

@MainActor
final class LabResultsViewModel: ObservableObject {
    @Published var labResults: [LabResult] = []
    @Published var selectedResult: LabResult?
    @Published var isLoading = false
    @Published var error: String?
    @Published var showingAddSheet = false
    @Published var showingDetailSheet = false

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
            return try await service.analyzeLabResult(result)
        } catch {
            return "Unable to generate analysis: \(error.localizedDescription)"
        }
    }

    // MARK: - Computed Properties

    var groupedResults: [(LabTestType, [LabResult])] {
        let grouped = Dictionary(grouping: labResults, by: { $0.testType })
        return grouped.sorted { $0.key.displayName < $1.key.displayName }
    }

    var recentResults: [LabResult] {
        Array(labResults.prefix(5))
    }
}
