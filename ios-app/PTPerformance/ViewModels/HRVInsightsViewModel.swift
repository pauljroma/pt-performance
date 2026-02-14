import Foundation
import Combine
import HealthKit

/// ViewModel for HRV Insights View (ACP-1021)
/// Manages HRV data loading, trend calculation, baseline comparison, and insights generation
@MainActor
class HRVInsightsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var currentHRV: Double?
    @Published var baseline: Double?
    @Published var baselineDeviation: Double?
    @Published var hrvHistory: [HRVReading] = []
    @Published var rollingAverageData: [HRVChartDataPoint] = []
    @Published var significantChanges: [SignificantHRVChange] = []
    @Published var trainingLoadCorrelation: Double?
    @Published var insights: [String] = []
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Dependencies

    private let patientId: UUID
    private let healthKitService: HealthKitService
    private let hrvService: HRVService?

    // MARK: - Initialization

    init(patientId: UUID, healthKitService: HealthKitService = .shared) {
        self.patientId = patientId
        self.healthKitService = healthKitService

        // Initialize HRV service if HealthKit is available
        if HKHealthStore.isHealthDataAvailable() {
            let store = HKHealthStore()
            self.hrvService = HRVService(healthStore: store)
        } else {
            self.hrvService = nil
        }
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true
        error = nil

        do {
            // Fetch HRV data in parallel
            async let currentTask = fetchCurrentHRV()
            async let baselineTask = fetchBaseline()
            async let historyTask = fetchHistory()

            currentHRV = try await currentTask
            baseline = try await baselineTask
            hrvHistory = try await historyTask

            // Calculate derived data
            calculateBaselineDeviation()
            calculateRollingAverage()
            detectSignificantChanges()
            await analyzeTrainingLoadCorrelation()
            generateInsights()

        } catch {
            self.error = error.localizedDescription
            DebugLogger.shared.error("HRVInsights", "Failed to load HRV data: \(error)")
        }

        isLoading = false
    }

    // MARK: - Data Fetching

    private func fetchCurrentHRV() async throws -> Double? {
        guard let service = hrvService else { return nil }
        return try await service.fetchHRV(for: Date())
    }

    private func fetchBaseline() async throws -> Double? {
        guard let service = hrvService else { return nil }
        return try await service.getHRVBaseline(days: 7)
    }

    private func fetchHistory() async throws -> [HRVReading] {
        guard let service = hrvService else { return [] }
        return try await service.fetchHRVHistory(days: 30)
    }

    // MARK: - Calculations

    private func calculateBaselineDeviation() {
        guard let current = currentHRV, let base = baseline, base > 0 else {
            baselineDeviation = nil
            return
        }

        baselineDeviation = ((current - base) / base) * 100
    }

    private func calculateRollingAverage() {
        guard hrvHistory.count >= 7 else {
            rollingAverageData = []
            return
        }

        var averagePoints: [HRVChartDataPoint] = []
        let sorted = hrvHistory.sorted { $0.date < $1.date }

        for i in 6..<sorted.count {
            let window = sorted[max(0, i-6)...i]
            let average = window.reduce(0.0) { $0 + $1.hrvSDNN } / Double(window.count)
            averagePoints.append(HRVChartDataPoint(date: sorted[i].date, value: average))
        }

        rollingAverageData = averagePoints
    }

    private func detectSignificantChanges() {
        guard hrvHistory.count >= 2 else {
            significantChanges = []
            return
        }

        var changes: [SignificantHRVChange] = []
        let sorted = hrvHistory.sorted { $0.date < $1.date }

        for i in 1..<sorted.count {
            let previous = sorted[i-1].hrvSDNN
            let current = sorted[i].hrvSDNN
            let percentChange = ((current - previous) / previous) * 100

            // Detect drops > 15% or spikes > 20%
            if percentChange < -15 {
                changes.append(SignificantHRVChange(
                    date: sorted[i].date,
                    value: current,
                    label: "Sharp Drop"
                ))
            } else if percentChange > 20 {
                changes.append(SignificantHRVChange(
                    date: sorted[i].date,
                    value: current,
                    label: "Sharp Rise"
                ))
            }
        }

        // Limit to most recent 3 significant changes
        significantChanges = Array(changes.suffix(3))
    }

    private func analyzeTrainingLoadCorrelation() async {
        // Placeholder for training load correlation
        // This would integrate with workout/training data when available
        // For now, generate a simulated correlation based on HRV variability

        guard hrvHistory.count >= 10 else {
            trainingLoadCorrelation = nil
            return
        }

        // Calculate HRV trend (simplified)
        let recentHRV = hrvHistory.prefix(7).map { $0.hrvSDNN }
        let olderHRV = hrvHistory.dropFirst(7).prefix(7).map { $0.hrvSDNN }

        if !recentHRV.isEmpty && !olderHRV.isEmpty {
            let recentAvg = recentHRV.reduce(0, +) / Double(recentHRV.count)
            let olderAvg = olderHRV.reduce(0, +) / Double(olderHRV.count)

            // Negative correlation suggests higher training load = lower HRV
            let trendChange = (recentAvg - olderAvg) / olderAvg

            // Simulate correlation (in real app, would correlate with actual training data)
            trainingLoadCorrelation = -trendChange * 0.5
        }
    }

    private func generateInsights() {
        var newInsights: [String] = []

        // Insight 1: Current status vs baseline
        if let deviation = baselineDeviation {
            if deviation > 10 {
                newInsights.append("Your HRV is significantly above baseline, indicating excellent recovery and readiness for intense training.")
            } else if deviation > 5 {
                newInsights.append("Your HRV is slightly above baseline, suggesting good recovery status.")
            } else if deviation > -5 {
                newInsights.append("Your HRV is within normal range of your baseline.")
            } else if deviation > -10 {
                newInsights.append("Your HRV is below baseline, which may indicate accumulated fatigue or stress.")
            } else {
                newInsights.append("Your HRV is significantly below baseline. Consider prioritizing rest and recovery today.")
            }
        }

        // Insight 2: Trend analysis
        if hrvHistory.count >= 7 {
            let recentWeek = hrvHistory.prefix(7).map { $0.hrvSDNN }
            let recentAvg = recentWeek.reduce(0, +) / Double(recentWeek.count)

            if let baseline = baseline {
                let weekTrend = ((recentAvg - baseline) / baseline) * 100

                if weekTrend > 10 {
                    newInsights.append("Your HRV has been trending upward over the past week, showing positive adaptation to training.")
                } else if weekTrend < -10 {
                    newInsights.append("Your HRV has been declining this week. Ensure you're getting adequate sleep and managing stress.")
                }
            }
        }

        // Insight 3: Variability assessment
        if hrvHistory.count >= 7 {
            let recentValues = hrvHistory.prefix(7).map { $0.hrvSDNN }
            let mean = recentValues.reduce(0, +) / Double(recentValues.count)
            let variance = recentValues.reduce(0.0) { $0 + pow($1 - mean, 2) } / Double(recentValues.count)
            let stdDev = sqrt(variance)
            let coefficient = (stdDev / mean) * 100

            if coefficient > 15 {
                newInsights.append("Your HRV shows high day-to-day variability, which is normal but suggests fluctuating recovery status.")
            } else if coefficient < 8 {
                newInsights.append("Your HRV is very consistent, indicating stable recovery patterns.")
            }
        }

        // Insight 4: Actionable recommendations
        if let current = currentHRV {
            if current < 40 {
                newInsights.append("Low HRV detected. Focus on stress management, quality sleep, and lighter training intensity today.")
            } else if current > 70 {
                newInsights.append("Excellent HRV indicates strong autonomic balance. Your body is ready for challenging workouts.")
            }
        }

        // Default insight if no data
        if newInsights.isEmpty {
            newInsights.append("Connect your Apple Watch to start tracking HRV and receive personalized insights.")
        }

        insights = newInsights
    }
}
