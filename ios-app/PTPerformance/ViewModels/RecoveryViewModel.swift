import SwiftUI

@MainActor
final class RecoveryViewModel: ObservableObject {
    @Published var sessions: [RecoverySession] = []
    @Published var recommendations: [RecoveryRecommendation] = []
    @Published var impactAnalysis: RecoveryImpactAnalysis?
    @Published var isLoading = false
    @Published var isAnalyzing = false
    @Published var error: String?
    @Published var showingLogSheet = false
    @Published var showingInsightsSheet = false
    @Published var selectedProtocol: RecoveryProtocolType = .saunaTraditional

    // Log session form
    @Published var logDuration: Int = 15
    @Published var logTemperature: Double?
    @Published var logHeartRate: Int?
    @Published var logEffort: Int = 5
    @Published var logNotes: String = ""

    private let service = RecoveryService.shared

    func loadData() async {
        isLoading = true
        error = nil
        await service.fetchSessions()
        await service.generateRecommendations()
        sessions = service.sessions
        recommendations = service.recommendations
        if let serviceError = service.error {
            error = serviceError.localizedDescription
        }
        isLoading = false

        // Fetch impact analysis in background
        await loadImpactAnalysis()
    }

    func loadImpactAnalysis() async {
        isAnalyzing = true
        await service.analyzeRecoveryImpact(days: 30)
        impactAnalysis = service.impactAnalysis
        isAnalyzing = service.isAnalyzing
    }

    func refreshAnalysis() async {
        isAnalyzing = true
        await service.analyzeRecoveryImpact(days: 30)
        impactAnalysis = service.impactAnalysis
        isAnalyzing = false
    }

    func logSession() async {
        do {
            try await service.logSession(
                protocolType: selectedProtocol,
                durationSeconds: logDuration * 60, // Convert to seconds
                temperature: logTemperature,
                heartRateAvg: logHeartRate,
                perceivedEffort: logEffort,
                notes: logNotes.isEmpty ? nil : logNotes
            )
            resetForm()
            showingLogSheet = false
            await loadData()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func resetForm() {
        logDuration = 15
        logTemperature = nil
        logHeartRate = nil
        logEffort = 5
        logNotes = ""
    }

    // MARK: - Computed Properties

    var weeklyStats: (sessions: Int, minutes: Int, favorite: RecoveryProtocolType?) {
        let stats = service.weeklyStats()
        return (sessions: stats.totalSessions, minutes: stats.totalMinutes, favorite: stats.favoriteProtocol)
    }

    var todaySessions: [RecoverySession] {
        sessions.filter { Calendar.current.isDateInToday($0.loggedAt) }
    }

    var thisWeekSessions: [RecoverySession] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sessions.filter { $0.loggedAt >= weekAgo }
    }

    func sessionsForProtocol(_ type: RecoveryProtocolType) -> [RecoverySession] {
        sessions.filter { $0.protocolType == type }
    }

    // MARK: - Impact Analysis Computed Properties

    /// Top insight for display in summary
    var topInsight: RecoveryInsight? {
        impactAnalysis?.topInsight
    }

    /// Top 3 positive insights
    var topPositiveInsights: [RecoveryInsight] {
        Array((impactAnalysis?.positiveInsights ?? []).prefix(3))
    }

    /// Whether we have sufficient data for insights
    var hasInsightsData: Bool {
        impactAnalysis?.hasSufficientData ?? false
    }

    /// Number of data points analyzed
    var dataPointsAnalyzed: Int {
        impactAnalysis?.dataPointsAnalyzed ?? 0
    }

    /// Start log session for a specific protocol (for use from recommendations)
    func startLogSession(for protocolType: RecoveryProtocolType) {
        selectedProtocol = protocolType
        showingLogSheet = true
    }
}
