//
//  EngagementScoreDashboardViewModel.swift
//  PTPerformance
//
//  ViewModel for the Engagement Score Dashboard
//  Loads engagement scores, summary data, and supports batch recalculation
//

import Foundation

// MARK: - Engagement Score Dashboard ViewModel

@MainActor
final class EngagementScoreDashboardViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var scores: [EngagementScoreRow] = []
    @Published var summary: EngagementSummary?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isRecalculating = false

    // MARK: - Private Properties

    private let service = EdgeFunctionAnalyticsService.shared

    // MARK: - Public Methods

    /// Load all engagement scores and summary from the edge function
    func loadScores() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await service.fetchEngagementScores()
            scores = (response.data ?? []).sorted { ($0.score ?? 0) < ($1.score ?? 0) }
            summary = response.summary
        } catch {
            errorMessage = error.localizedDescription
            ErrorLogger.shared.logError(error, context: "EngagementScoreDashboardViewModel.loadScores")
        }

        isLoading = false
    }

    /// Trigger batch recalculation of all engagement scores
    func recalculate() async {
        isRecalculating = true
        errorMessage = nil

        do {
            let response = try await service.recalculateEngagementScores()
            scores = (response.data ?? []).sorted { ($0.score ?? 0) < ($1.score ?? 0) }
            summary = response.summary
        } catch {
            errorMessage = error.localizedDescription
            ErrorLogger.shared.logError(error, context: "EngagementScoreDashboardViewModel.recalculate")
        }

        isRecalculating = false
    }

    // MARK: - Computed Helpers

    /// Color for a given score value (0-100)
    static func scoreColor(_ score: Double) -> String {
        switch score {
        case 80...100: return "highly_engaged"
        case 60..<80: return "engaged"
        case 40..<60: return "moderate"
        case 20..<40: return "at_risk"
        default: return "high_risk"
        }
    }
}
