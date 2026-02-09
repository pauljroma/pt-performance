import Foundation
import SwiftUI
import Combine

// MARK: - Readiness Intelligence View Model

/// ViewModel coordinating recovery intelligence features for readiness-based workout adaptation
/// Combines data from ReadinessService, WorkoutAdaptationService, and HealthKitService
@MainActor
class ReadinessIntelligenceViewModel: ObservableObject {

    // MARK: - Published Properties

    // Current state
    @Published var compositeReadiness: CompositeReadinessScore?
    @Published var workoutAdaptation: WorkoutAdaptation?
    @Published var readinessForecasts: [ReadinessForecast] = []
    @Published var readinessAnalysis: ReadinessAnalysis?

    // Historical data
    @Published var weeklyReadinessData: [DailyReadinessDataPoint] = []
    @Published var hrvTrend: [HRVDataPoint] = []
    @Published var sleepTrend: [SleepDataPoint] = []

    // Loading states
    @Published var isLoadingReadiness: Bool = false
    @Published var isLoadingAdaptation: Bool = false
    @Published var isLoadingForecast: Bool = false
    @Published var isLoadingAnalysis: Bool = false
    @Published var isLoadingTrends: Bool = false

    // Error handling
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    // MARK: - Data Models

    struct DailyReadinessDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let score: Double
        let band: ReadinessBand
    }

    struct HRVDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
        let baseline: Double?
    }

    struct SleepDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let hours: Double
        let efficiency: Double?
    }

    // MARK: - Dependencies

    private let readinessService: ReadinessService
    private let adaptationService: WorkoutAdaptationService
    private let healthKitService: HealthKitService
    private let patientId: UUID

    // MARK: - Initialization

    init(
        patientId: UUID,
        readinessService: ReadinessService = ReadinessService(),
        adaptationService: WorkoutAdaptationService,
        healthKitService: HealthKitService
    ) {
        self.patientId = patientId
        self.readinessService = readinessService
        self.adaptationService = adaptationService
        self.healthKitService = healthKitService
    }

    /// Convenience initializer using shared services
    convenience init(patientId: UUID) {
        self.init(
            patientId: patientId,
            readinessService: ReadinessService(),
            adaptationService: WorkoutAdaptationService.shared,
            healthKitService: HealthKitService.shared
        )
    }

    // MARK: - Computed Properties

    /// Quick recommendation message based on current readiness
    var quickRecommendation: String {
        guard let score = compositeReadiness?.overallScore else {
            return "Complete your readiness check-in to get personalized recommendations"
        }
        return adaptationService.getQuickRecommendation(for: score)
    }

    /// Current readiness band color
    var readinessColor: Color {
        compositeReadiness?.readinessBand.color ?? .gray
    }

    /// Formatted readiness score
    var readinessScoreText: String {
        guard let score = compositeReadiness?.overallScore else {
            return "--"
        }
        return String(format: "%.0f", score)
    }

    /// Readiness confidence level description
    var confidenceDescription: String {
        compositeReadiness?.confidence.description ?? "No data available"
    }

    /// Whether we have enough data to show insights
    var hasInsightsData: Bool {
        !weeklyReadinessData.isEmpty || readinessAnalysis != nil
    }

    /// Average weekly readiness
    var weeklyAverageReadiness: Double? {
        guard !weeklyReadinessData.isEmpty else { return nil }
        let total = weeklyReadinessData.reduce(0) { $0 + $1.score }
        return total / Double(weeklyReadinessData.count)
    }

    /// Trend direction text
    var trendDirectionText: String {
        guard let analysis = readinessAnalysis else { return "Unknown" }
        switch analysis.trend {
        case .improving: return "Improving"
        case .stable: return "Stable"
        case .declining: return "Declining"
        }
    }

    /// Trend direction icon
    var trendDirectionIcon: String {
        guard let analysis = readinessAnalysis else { return "minus" }
        switch analysis.trend {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }

    /// Trend direction color
    var trendDirectionColor: Color {
        guard let analysis = readinessAnalysis else { return .gray }
        switch analysis.trend {
        case .improving: return .green
        case .stable: return .blue
        case .declining: return .orange
        }
    }

    /// Whether any loading is in progress
    var isLoading: Bool {
        isLoadingReadiness || isLoadingAdaptation || isLoadingForecast || isLoadingAnalysis || isLoadingTrends
    }

    // MARK: - Public Methods

    /// Load all recovery data
    func loadData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadCompositeReadiness() }
            group.addTask { await self.loadWorkoutAdaptation() }
            group.addTask { await self.loadReadinessForecasts() }
            group.addTask { await self.loadWeeklyTrends() }
        }
    }

    /// Refresh all data
    func refresh() async {
        await loadData()
    }

    /// Load only the composite readiness score
    func loadCompositeReadiness() async {
        isLoadingReadiness = true
        defer { isLoadingReadiness = false }

        do {
            compositeReadiness = try await readinessService.calculateCompositeReadiness(
                for: patientId,
                using: healthKitService
            )
        } catch {
            handleError(error, context: "loading readiness")
        }
    }

    /// Load workout adaptation based on current readiness
    func loadWorkoutAdaptation() async {
        isLoadingAdaptation = true
        defer { isLoadingAdaptation = false }

        do {
            workoutAdaptation = try await adaptationService.getWorkoutAdaptation(for: patientId)
        } catch {
            handleError(error, context: "loading workout adaptation")
        }
    }

    /// Load 3-day readiness forecasts
    func loadReadinessForecasts() async {
        isLoadingForecast = true
        defer { isLoadingForecast = false }

        do {
            readinessForecasts = try await readinessService.predictReadiness(
                for: patientId,
                using: healthKitService
            )
        } catch {
            handleError(error, context: "loading forecasts")
        }
    }

    /// Load historical analysis
    func loadReadinessAnalysis() async {
        isLoadingAnalysis = true
        defer { isLoadingAnalysis = false }

        do {
            readinessAnalysis = try await readinessService.analyzeReadinessHistory(
                for: patientId,
                days: 30
            )
        } catch {
            handleError(error, context: "loading analysis")
        }
    }

    /// Load weekly trend data for charts
    func loadWeeklyTrends() async {
        isLoadingTrends = true
        defer { isLoadingTrends = false }

        let calendar = Calendar.current
        let today = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: today) else {
            return
        }

        do {
            // Load readiness data
            let readinessData = try await readinessService.fetchReadiness(
                for: patientId,
                from: startDate,
                to: today
            )

            weeklyReadinessData = readinessData.map { entry in
                DailyReadinessDataPoint(
                    date: entry.date,
                    score: entry.readinessScore ?? 50,
                    band: entry.readinessBand
                )
            }.sorted { $0.date < $1.date }

            // Try to load HRV trend (may not be available)
            var hrvPoints: [HRVDataPoint] = []
            let baseline = try? await healthKitService.getHRVBaseline(days: 7)

            for dayOffset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                    continue
                }
                if let hrv = try? await healthKitService.fetchHRV(for: date) {
                    hrvPoints.append(HRVDataPoint(
                        date: date,
                        value: hrv,
                        baseline: baseline
                    ))
                }
            }
            hrvTrend = hrvPoints.sorted { $0.date < $1.date }

            // Try to load sleep trend (may not be available)
            var sleepPoints: [SleepDataPoint] = []
            for dayOffset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                    continue
                }
                if let sleep = try? await healthKitService.fetchSleepData(for: date) {
                    sleepPoints.append(SleepDataPoint(
                        date: date,
                        hours: sleep.totalHours,
                        efficiency: sleep.sleepEfficiency
                    ))
                }
            }
            sleepTrend = sleepPoints.sorted { $0.date < $1.date }

        } catch {
            handleError(error, context: "loading trends")
        }
    }

    /// Get adjusted workout parameters based on current readiness
    /// - Parameters:
    ///   - sets: Original prescribed sets
    ///   - reps: Original prescribed reps
    ///   - weight: Original prescribed weight
    ///   - restSeconds: Original rest period
    /// - Returns: Tuple of adjusted values
    func getAdjustedWorkoutParameters(
        sets: Int,
        reps: Int,
        weight: Double,
        restSeconds: Int
    ) -> (sets: Int, reps: Int, weight: Double, restSeconds: Int) {
        guard let score = compositeReadiness?.overallScore else {
            return (sets, reps, weight, restSeconds)
        }

        let adjustedVolume = adaptationService.adjustVolume(sets: sets, reps: reps, for: score)
        let adjustedWeight = adaptationService.adjustWeight(weight, for: score)
        let adjustedRest = adaptationService.adjustRestPeriod(restSeconds, for: score)

        return (
            sets: adjustedVolume.sets,
            reps: adjustedVolume.reps,
            weight: adjustedWeight,
            restSeconds: adjustedRest
        )
    }

    /// Clear any displayed error
    func clearError() {
        errorMessage = nil
        showError = false
    }

    // MARK: - Private Methods

    private func handleError(_ error: Error, context: String) {
        DebugLogger.shared.error("READINESS_INTELLIGENCE", "Error \(context): \(error.localizedDescription)")
        errorMessage = "Failed \(context). Please try again."
        showError = true
    }
}

// MARK: - Recovery Insights Helper

extension ReadinessIntelligenceViewModel {

    /// Get correlation insights formatted for display
    var correlationInsights: [(factor: String, description: String, impact: String)] {
        guard let analysis = readinessAnalysis else { return [] }

        return analysis.correlations.map { correlation in
            let impactText: String
            if correlation.correlation > 0.5 {
                impactText = "Strong positive"
            } else if correlation.correlation > 0.2 {
                impactText = "Moderate positive"
            } else if correlation.correlation < -0.5 {
                impactText = "Strong negative"
            } else if correlation.correlation < -0.2 {
                impactText = "Moderate negative"
            } else {
                impactText = "Minimal"
            }

            return (
                factor: correlation.factor,
                description: correlation.description,
                impact: impactText
            )
        }
    }

    /// Get patterns formatted for display
    var patternInsights: [(name: String, description: String, recommendation: String)] {
        guard let analysis = readinessAnalysis else { return [] }

        return analysis.patterns.map { pattern in
            (
                name: pattern.name,
                description: pattern.description,
                recommendation: pattern.recommendation
            )
        }
    }

    /// Best and worst day text
    var dayPatternText: String? {
        guard let analysis = readinessAnalysis else { return nil }

        if let best = analysis.bestDay, let worst = analysis.worstDay, best != worst {
            return "\(best.name)s tend to be your best recovery days, while \(worst.name)s are typically lower."
        }
        return nil
    }

    /// Get periodization recommendation based on analysis
    var periodizationRecommendation: String {
        guard let analysis = readinessAnalysis else {
            return "Complete more readiness check-ins to receive periodization recommendations."
        }

        switch analysis.trend {
        case .declining:
            if analysis.volatility > 15 {
                return "Your readiness has been declining with high variability. Consider a structured deload week followed by a gradual return to training."
            }
            return "Your readiness trend is declining. Consider reducing training volume by 20-30% for the next week."

        case .stable:
            if let avg = weeklyAverageReadiness, avg < 60 {
                return "Your readiness is stable but below optimal. Focus on improving sleep and recovery to break through this plateau."
            }
            return "Your readiness is stable. Consider a slight increase in training stimulus to drive adaptation."

        case .improving:
            return "Your readiness is improving! This is a good time to progressively increase training intensity or volume."
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension ReadinessIntelligenceViewModel {
    static var preview: ReadinessIntelligenceViewModel {
        let vm = ReadinessIntelligenceViewModel(patientId: UUID())

        // Set up mock data
        vm.compositeReadiness = CompositeReadinessScore(
            overallScore: 72,
            hrvScore: 68,
            sleepScore: 80,
            restingHRScore: 75,
            subjectiveScore: 65,
            readinessBand: .yellow,
            breakdown: CompositeReadinessScore.ReadinessBreakdown(
                hrvValue: 55,
                hrvBaseline: 58,
                hrvDeviation: -5.2,
                sleepHours: 7.2,
                sleepEfficiency: 88,
                restingHR: 58,
                restingHRBaseline: 55,
                energyLevel: 6,
                sorenessLevel: 4,
                stressLevel: 5
            ),
            confidence: .high
        )

        vm.workoutAdaptation = .sampleHighReadiness

        let calendar = Calendar.current
        let today = Date()
        vm.weeklyReadinessData = (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let score = Double.random(in: 55...85)
            let band: ReadinessBand = score >= 80 ? .green : score >= 60 ? .yellow : .orange
            return DailyReadinessDataPoint(date: date, score: score, band: band)
        }.reversed()

        return vm
    }
}
#endif
