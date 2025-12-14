import Foundation
import SwiftUI

/// ViewModel for History view
@MainActor
class HistoryViewModel: ObservableObject {
    @Published var painTrend: [PainDataPoint] = []
    @Published var adherence: AdherenceData?
    @Published var recentSessions: [SessionSummary] = []
    @Published var summaryStats: SummaryStats?

    @Published var isLoading = false
    @Published var errorMessage: String?

    private let analyticsService: AnalyticsService

    /// Check if history is completely empty
    var isEmpty: Bool {
        summaryStats == nil &&
        painTrend.isEmpty &&
        adherence == nil &&
        recentSessions.isEmpty
    }

    init(analyticsService: AnalyticsService = AnalyticsService()) {
        self.analyticsService = analyticsService
    }

    /// Fetch all history data
    func fetchData(for patientId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch all data in parallel
            async let painTask = analyticsService.fetchPainTrend(patientId: patientId, days: 14)
            async let adherenceTask = analyticsService.fetchAdherence(patientId: patientId, days: 30)
            async let sessionsTask = analyticsService.fetchRecentSessions(patientId: patientId, limit: 10)
            async let statsTask = analyticsService.fetchSummaryStats(patientId: patientId)

            let (pain, adh, sessions, stats) = try await (painTask, adherenceTask, sessionsTask, statsTask)

            painTrend = pain
            adherence = adh
            recentSessions = sessions
            summaryStats = stats

            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    /// Refresh data
    func refresh(for patientId: String) async {
        await fetchData(for: patientId)
    }
}
