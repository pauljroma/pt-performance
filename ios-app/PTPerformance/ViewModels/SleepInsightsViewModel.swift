import Foundation
import Combine
import HealthKit

/// ViewModel for Sleep Insights View (ACP-1022)
/// Manages sleep data loading, analysis, and insights generation
@MainActor
class SleepInsightsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var lastNightSleep: SleepData?
    @Published var sleepEfficiency: Double?
    @Published var sleepHistory: [SleepNight] = []
    @Published var sleepDebt: Int? // in minutes (negative = debt, positive = surplus)
    @Published var consistencyScore: Double?
    @Published var weekComparison: SleepWeekComparison?
    @Published var qualityFactors: [SleepQualityFactor] = []
    @Published var readinessImpact: ReadinessImpact?
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Dependencies

    private let patientId: UUID
    private let healthKitService: HealthKitService
    private let sleepService: SleepService?

    // MARK: - Constants

    private let targetSleepMinutes = 480 // 8 hours

    // MARK: - Initialization

    init(patientId: UUID, healthKitService: HealthKitService = .shared) {
        self.patientId = patientId
        self.healthKitService = healthKitService

        // Initialize sleep service if HealthKit is available
        if HKHealthStore.isHealthDataAvailable() {
            let store = HKHealthStore()
            self.sleepService = SleepService(healthStore: store)
        } else {
            self.sleepService = nil
        }
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true
        error = nil

        do {
            // Fetch sleep data
            async let lastNightTask = fetchLastNightSleep()
            async let historyTask = fetchSleepHistory()

            lastNightSleep = try await lastNightTask
            sleepHistory = try await historyTask

            // Calculate metrics
            calculateSleepEfficiency()
            calculateSleepDebt()
            calculateConsistencyScore()
            calculateSleepWeekComparison()
            generateQualityFactors()
            calculateReadinessImpact()

        } catch {
            self.error = error.localizedDescription
            DebugLogger.shared.error("SleepInsights", "Failed to load sleep data: \(error)")
        }

        isLoading = false
    }

    // MARK: - Data Fetching

    private func fetchLastNightSleep() async throws -> SleepData? {
        guard let service = sleepService else { return nil }
        return try await service.fetchSleepData(for: Date())
    }

    private func fetchSleepHistory() async throws -> [SleepNight] {
        guard let service = sleepService else { return [] }
        let history = try await service.fetchSleepHistory(days: 14)
        return history.map { SleepNight(date: $0.date, data: $0.data) }
    }

    // MARK: - Calculations

    private func calculateSleepEfficiency() {
        sleepEfficiency = lastNightSleep?.sleepEfficiency
    }

    private func calculateSleepDebt() {
        guard sleepHistory.count >= 7 else {
            sleepDebt = nil
            return
        }

        // Calculate debt as: actual sleep - target sleep over past 7 days
        let recentWeek = sleepHistory.prefix(7)
        let totalActual = recentWeek.reduce(0) { $0 + $1.data.totalMinutes }
        let totalTarget = targetSleepMinutes * recentWeek.count

        sleepDebt = totalActual - totalTarget
    }

    private func calculateConsistencyScore() {
        guard sleepHistory.count >= 7 else {
            consistencyScore = nil
            return
        }

        // Calculate bedtime consistency based on variance in sleep duration
        let recentWeek = sleepHistory.prefix(7).map { Double($0.data.totalMinutes) }

        let mean = recentWeek.reduce(0, +) / Double(recentWeek.count)
        let variance = recentWeek.reduce(0.0) { $0 + pow($1 - mean, 2) } / Double(recentWeek.count)
        let stdDev = sqrt(variance)

        // Score: 100 - (stdDev as percentage of mean)
        // Lower variance = higher score
        let coefficientOfVariation = (stdDev / mean) * 100
        consistencyScore = max(0, min(100, 100 - coefficientOfVariation * 2))
    }

    private func calculateSleepWeekComparison() {
        guard sleepHistory.count >= 14 else {
            weekComparison = nil
            return
        }

        let thisWeek = sleepHistory.prefix(7)
        let lastWeek = sleepHistory.dropFirst(7).prefix(7)

        // Average sleep duration
        let thisWeekAvg = Double(thisWeek.reduce(0) { $0 + $1.data.totalMinutes }) / Double(thisWeek.count)
        let lastWeekAvg = Double(lastWeek.reduce(0) { $0 + $1.data.totalMinutes }) / Double(lastWeek.count)

        // Average efficiency
        let thisWeekEfficiency = thisWeek.reduce(0.0) { $0 + $1.data.sleepEfficiency } / Double(thisWeek.count)
        let lastWeekEfficiency = lastWeek.reduce(0.0) { $0 + $1.data.sleepEfficiency } / Double(lastWeek.count)

        // Deep sleep percentage
        let thisWeekDeep = thisWeek.compactMap { $0.data.deepMinutes }.reduce(0, +)
        let thisWeekTotal = thisWeek.reduce(0) { $0 + $1.data.totalMinutes }
        let thisWeekDeepPercent = thisWeekTotal > 0 ? (Double(thisWeekDeep) / Double(thisWeekTotal)) * 100 : 0

        let lastWeekDeep = lastWeek.compactMap { $0.data.deepMinutes }.reduce(0, +)
        let lastWeekTotal = lastWeek.reduce(0) { $0 + $1.data.totalMinutes }
        let lastWeekDeepPercent = lastWeekTotal > 0 ? (Double(lastWeekDeep) / Double(lastWeekTotal)) * 100 : 0

        // Determine trend
        let sleepChange = thisWeekAvg - lastWeekAvg
        let efficiencyChange = thisWeekEfficiency - lastWeekEfficiency
        let deepChange = thisWeekDeepPercent - lastWeekDeepPercent

        let trend: SleepWeekComparison.SleepTrend
        if sleepChange > 30 && efficiencyChange > 5 {
            trend = .improving
        } else if sleepChange < -30 && efficiencyChange < -5 {
            trend = .declining
        } else {
            trend = .stable
        }

        let trendMessage: String
        switch trend {
        case .improving:
            trendMessage = "Your sleep is improving compared to last week"
        case .declining:
            trendMessage = "Your sleep quality has decreased from last week"
        case .stable:
            trendMessage = "Your sleep is consistent with last week"
        }

        weekComparison = SleepWeekComparison(
            thisWeekAvg: thisWeekAvg,
            lastWeekAvg: lastWeekAvg,
            thisWeekEfficiency: thisWeekEfficiency,
            lastWeekEfficiency: lastWeekEfficiency,
            thisWeekDeepPercent: thisWeekDeepPercent,
            lastWeekDeepPercent: lastWeekDeepPercent,
            trend: trend,
            trendMessage: trendMessage
        )
    }

    private func generateQualityFactors() {
        var factors: [SleepQualityFactor] = []

        guard let lastNight = lastNightSleep else {
            qualityFactors = []
            return
        }

        // Factor 1: Sleep duration
        let durationStatus: SleepQualityFactor.Status
        let durationExplanation: String
        if lastNight.totalMinutes >= 420 { // 7+ hours
            durationStatus = .good
            durationExplanation = "You got \(lastNight.totalMinutes / 60) hours of sleep, meeting the recommended 7-9 hours for adults."
        } else if lastNight.totalMinutes >= 360 { // 6-7 hours
            durationStatus = .neutral
            durationExplanation = "You got \(lastNight.totalMinutes / 60) hours of sleep. Aim for 7+ hours for optimal recovery."
        } else {
            durationStatus = .poor
            durationExplanation = "You only got \(lastNight.totalMinutes / 60) hours of sleep. This is below the recommended amount."
        }
        factors.append(SleepQualityFactor(
            icon: "clock.fill",
            title: "Sleep Duration",
            explanation: durationExplanation,
            status: durationStatus
        ))

        // Factor 2: Sleep efficiency
        let efficiency = lastNight.sleepEfficiency
        let efficiencyStatus: SleepQualityFactor.Status
        let efficiencyExplanation: String
        if efficiency >= 85 {
            efficiencyStatus = .good
            efficiencyExplanation = "Sleep efficiency of \(Int(efficiency))% is excellent. You spent most of your time in bed actually sleeping."
        } else if efficiency >= 75 {
            efficiencyStatus = .neutral
            efficiencyExplanation = "Sleep efficiency of \(Int(efficiency))% is acceptable but could be improved."
        } else {
            efficiencyStatus = .poor
            efficiencyExplanation = "Sleep efficiency of \(Int(efficiency))% indicates frequent wake-ups or difficulty falling asleep."
        }
        factors.append(SleepQualityFactor(
            icon: "gauge.medium",
            title: "Sleep Efficiency",
            explanation: efficiencyExplanation,
            status: efficiencyStatus
        ))

        // Factor 3: Deep sleep
        if let deepMinutes = lastNight.deepMinutes {
            let deepPercent = (Double(deepMinutes) / Double(lastNight.totalMinutes)) * 100
            let deepStatus: SleepQualityFactor.Status
            let deepExplanation: String
            if deepPercent >= 20 {
                deepStatus = .good
                deepExplanation = "Deep sleep accounted for \(Int(deepPercent))% of your sleep. This supports physical recovery."
            } else if deepPercent >= 13 {
                deepStatus = .neutral
                deepExplanation = "Deep sleep was \(Int(deepPercent))% of your sleep, which is within normal range (13-23%)."
            } else {
                deepStatus = .poor
                deepExplanation = "Only \(Int(deepPercent))% deep sleep. Try avoiding caffeine late in the day and exercising earlier."
            }
            factors.append(SleepQualityFactor(
                icon: "moon.zzz.fill",
                title: "Deep Sleep",
                explanation: deepExplanation,
                status: deepStatus
            ))
        }

        // Factor 4: REM sleep
        if let remMinutes = lastNight.remMinutes {
            let remPercent = (Double(remMinutes) / Double(lastNight.totalMinutes)) * 100
            let remStatus: SleepQualityFactor.Status
            let remExplanation: String
            if remPercent >= 20 {
                remStatus = .good
                remExplanation = "REM sleep was \(Int(remPercent))% of your sleep, supporting memory and learning."
            } else if remPercent >= 15 {
                remStatus = .neutral
                remExplanation = "REM sleep was \(Int(remPercent))%, which is within normal range (15-25%)."
            } else {
                remStatus = .poor
                remExplanation = "Only \(Int(remPercent))% REM sleep. Consistent sleep schedules help optimize REM cycles."
            }
            factors.append(SleepQualityFactor(
                icon: "brain.head.profile",
                title: "REM Sleep",
                explanation: remExplanation,
                status: remStatus
            ))
        }

        // Factor 5: Consistency (if we have history)
        if let score = consistencyScore {
            let consistencyStatus: SleepQualityFactor.Status
            let consistencyExplanation: String
            if score >= 80 {
                consistencyStatus = .good
                consistencyExplanation = "Your sleep schedule is highly consistent, which improves sleep quality."
            } else if score >= 60 {
                consistencyStatus = .neutral
                consistencyExplanation = "Moderate consistency. Try going to bed and waking up at the same time daily."
            } else {
                consistencyStatus = .poor
                consistencyExplanation = "Inconsistent sleep schedule. Establishing a routine can significantly improve sleep quality."
            }
            factors.append(SleepQualityFactor(
                icon: "calendar.circle",
                title: "Schedule Consistency",
                explanation: consistencyExplanation,
                status: consistencyStatus
            ))
        }

        qualityFactors = factors
    }

    private func calculateReadinessImpact() {
        guard let lastNight = lastNightSleep else {
            readinessImpact = nil
            return
        }

        // Sleep contributes 35% to readiness score (from ReadinessCheckInViewModel)
        let contribution = 35.0

        // Calculate sleep score component
        let sleepHours = Double(lastNight.totalMinutes) / 60.0
        let sleepScore = min((sleepHours / 8.0) * 100, 100)

        let message: String
        if sleepScore >= 90 {
            message = "Your excellent sleep last night is strongly boosting your readiness score. You're well-prepared for high-intensity training."
        } else if sleepScore >= 75 {
            message = "Good sleep last night is positively contributing to your readiness. You're ready for moderate to high intensity work."
        } else if sleepScore >= 60 {
            message = "Adequate sleep is supporting your readiness, but there's room for improvement. Aim for 7-8 hours tonight."
        } else {
            message = "Limited sleep is reducing your readiness score. Prioritize getting more sleep to optimize recovery and performance."
        }

        readinessImpact = ReadinessImpact(contribution: contribution, message: message)
    }
}
