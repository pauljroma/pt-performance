import Foundation
import HealthKit

/// Service for recovery protocol tracking and impact analysis
@MainActor
final class RecoveryService: ObservableObject {
    static let shared = RecoveryService()

    @Published private(set) var sessions: [RecoverySession] = []
    @Published private(set) var recommendations: [RecoveryRecommendation] = []
    @Published private(set) var impactAnalysis: RecoveryImpactAnalysis?
    @Published private(set) var isLoading = false
    @Published private(set) var isAnalyzing = false
    @Published private(set) var error: Error?

    private let supabase = PTSupabaseClient.shared
    private let healthKitService = HealthKitService.shared

    private init() {}

    // MARK: - Fetch Sessions

    func fetchSessions(days: Int = 30) async {
        isLoading = true
        error = nil

        do {
            guard let patientId = try await getPatientId() else { return }

            let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

            let results: [RecoverySession] = try await supabase.client
                .from("recovery_sessions")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .gte("start_time", value: ISO8601DateFormatter().string(from: startDate))
                .order("start_time", ascending: false)
                .execute()
                .value

            self.sessions = results
        } catch {
            self.error = error
            DebugLogger.shared.error("RecoveryService", "Failed to fetch sessions: \(error)")
        }

        isLoading = false
    }

    // MARK: - Log Session

    func logSession(
        protocolType: RecoveryProtocolType,
        duration: Int,
        temperature: Double? = nil,
        heartRateAvg: Int? = nil,
        heartRateMax: Int? = nil,
        perceivedEffort: Int? = nil,
        notes: String? = nil
    ) async throws {
        guard let patientId = try await getPatientId() else {
            throw NSError(domain: "RecoveryService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No patient ID found"])
        }

        let session = RecoverySession(
            id: UUID(),
            patientId: patientId,
            protocolType: protocolType,
            startTime: Date(),
            duration: duration,
            temperature: temperature,
            heartRateAvg: heartRateAvg,
            heartRateMax: heartRateMax,
            perceivedEffort: perceivedEffort,
            notes: notes,
            createdAt: Date()
        )

        try await supabase.client
            .from("recovery_sessions")
            .insert(session)
            .execute()

        await fetchSessions()
    }

    // MARK: - Recommendations

    func generateRecommendations() async {
        // AI-based recommendations based on training load, sleep, readiness
        // For now, return static recommendations
        recommendations = [
            RecoveryRecommendation(
                id: UUID(),
                protocolType: .sauna,
                reason: "High training volume this week",
                priority: .high,
                suggestedDuration: 20
            ),
            RecoveryRecommendation(
                id: UUID(),
                protocolType: .coldPlunge,
                reason: "Optimize post-workout recovery",
                priority: .medium,
                suggestedDuration: 3
            )
        ]
    }

    // MARK: - Statistics

    func weeklyStats() -> (totalSessions: Int, totalMinutes: Int, favoriteProtocol: RecoveryProtocolType?) {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weeklySessions = sessions.filter { $0.startTime >= weekAgo }

        let totalMinutes = weeklySessions.reduce(0) { $0 + $1.duration / 60 }

        let protocolCounts = Dictionary(grouping: weeklySessions, by: { $0.protocolType })
        let favorite = protocolCounts.max(by: { $0.value.count < $1.value.count })?.key

        return (weeklySessions.count, totalMinutes, favorite)
    }

    // MARK: - Impact Analysis

    /// Analyze recovery impact by correlating sessions with HealthKit data
    /// - Parameter days: Number of days to analyze (default 30)
    func analyzeRecoveryImpact(days: Int = 30) async {
        isAnalyzing = true
        error = nil

        do {
            guard !sessions.isEmpty else {
                // No sessions to analyze
                impactAnalysis = RecoveryImpactAnalysis(
                    insights: [],
                    correlations: [],
                    personalizedRecommendations: [],
                    analysisDate: Date(),
                    dataPointsAnalyzed: 0
                )
                isAnalyzing = false
                return
            }

            // Fetch HealthKit data for correlation
            let healthData = try await fetchHealthDataForAnalysis(days: days)

            // Calculate correlations between recovery sessions and health metrics
            let correlations = calculateCorrelations(sessions: sessions, healthData: healthData)

            // Generate insights from correlations
            let insights = generateInsights(correlations: correlations, sessions: sessions, healthData: healthData)

            // Create personalized recommendations
            let recommendations = generatePersonalizedRecommendations(
                insights: insights,
                correlations: correlations,
                sessions: sessions
            )

            impactAnalysis = RecoveryImpactAnalysis(
                insights: insights,
                correlations: correlations,
                personalizedRecommendations: recommendations,
                analysisDate: Date(),
                dataPointsAnalyzed: sessions.count + healthData.count
            )
        } catch {
            self.error = error
            DebugLogger.shared.error("RecoveryService", "Failed to analyze recovery impact: \(error)")
        }

        isAnalyzing = false
    }

    // MARK: - Private Analysis Methods

    /// Fetch HealthKit data for correlation analysis
    private func fetchHealthDataForAnalysis(days: Int) async throws -> [HealthDataPoint] {
        var dataPoints: [HealthDataPoint] = []
        let calendar = Calendar.current
        let today = Date()

        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                continue
            }

            // Fetch HRV
            if let hrv = try? await healthKitService.fetchHRV(for: date), hrv > 0 {
                dataPoints.append(HealthDataPoint(date: date, metric: .hrv, value: hrv))
            }

            // Fetch sleep data
            if let sleepData = try? await healthKitService.fetchSleepData(for: date) {
                dataPoints.append(HealthDataPoint(
                    date: date,
                    metric: .sleepDuration,
                    value: Double(sleepData.totalMinutes) / 60.0
                ))

                if let deepMinutes = sleepData.deepMinutes {
                    dataPoints.append(HealthDataPoint(
                        date: date,
                        metric: .deepSleep,
                        value: Double(deepMinutes)
                    ))
                }

                if let remMinutes = sleepData.remMinutes {
                    dataPoints.append(HealthDataPoint(
                        date: date,
                        metric: .remSleep,
                        value: Double(remMinutes)
                    ))
                }

                // Sleep quality/efficiency
                let efficiency = sleepData.sleepEfficiency
                if efficiency > 0 {
                    dataPoints.append(HealthDataPoint(
                        date: date,
                        metric: .sleepQuality,
                        value: efficiency
                    ))
                }
            }

            // Fetch resting heart rate
            if let rhr = try? await healthKitService.fetchRestingHeartRate(for: date), rhr > 0 {
                dataPoints.append(HealthDataPoint(date: date, metric: .restingHeartRate, value: rhr))
            }
        }

        return dataPoints
    }

    /// Calculate correlations between recovery protocols and health metrics
    private func calculateCorrelations(
        sessions: [RecoverySession],
        healthData: [HealthDataPoint]
    ) -> [RecoveryCorrelation] {
        var correlations: [RecoveryCorrelation] = []
        let calendar = Calendar.current

        // Group sessions by protocol type
        let sessionsByProtocol = Dictionary(grouping: sessions, by: { $0.protocolType })

        // Group health data by metric
        let healthByMetric = Dictionary(grouping: healthData, by: { $0.metric })

        for (protocolType, protocolSessions) in sessionsByProtocol {
            for (metric, metricData) in healthByMetric {
                // Calculate average metric value on days after recovery sessions
                var postRecoveryValues: [Double] = []
                var nonRecoveryValues: [Double] = []

                for dataPoint in metricData {
                    let dataDate = calendar.startOfDay(for: dataPoint.date)

                    // Check if there was a recovery session the day before
                    let hadSessionDayBefore = protocolSessions.contains { session in
                        let sessionDate = calendar.startOfDay(for: session.startTime)
                        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: sessionDate) else {
                            return false
                        }
                        return calendar.isDate(dataDate, inSameDayAs: nextDay)
                    }

                    if hadSessionDayBefore {
                        postRecoveryValues.append(dataPoint.value)
                    } else {
                        nonRecoveryValues.append(dataPoint.value)
                    }
                }

                // Need sufficient data for meaningful correlation
                guard postRecoveryValues.count >= 3 && nonRecoveryValues.count >= 3 else {
                    continue
                }

                let postAvg = postRecoveryValues.reduce(0, +) / Double(postRecoveryValues.count)
                let nonAvg = nonRecoveryValues.reduce(0, +) / Double(nonRecoveryValues.count)

                // Calculate impact percentage
                let impact: Double
                if metric == .restingHeartRate {
                    // Lower RHR is better
                    impact = ((nonAvg - postAvg) / nonAvg) * 100
                } else {
                    // Higher is better for HRV, sleep, etc.
                    impact = ((postAvg - nonAvg) / nonAvg) * 100
                }

                // Calculate correlation coefficient (simplified Pearson)
                let correlation = calculatePearsonCorrelation(
                    x: postRecoveryValues,
                    xMean: postAvg,
                    y: nonRecoveryValues,
                    yMean: nonAvg
                )

                // Estimate p-value (simplified - based on sample size and correlation strength)
                let sampleSize = postRecoveryValues.count + nonRecoveryValues.count
                let pValue = estimatePValue(correlation: abs(correlation), sampleSize: sampleSize)

                correlations.append(RecoveryCorrelation(
                    protocolType: protocolType,
                    metric: metric,
                    correlationCoefficient: correlation,
                    pValue: pValue,
                    sampleSize: sampleSize,
                    averageImpact: impact
                ))
            }
        }

        return correlations.sorted { abs($0.averageImpact) > abs($1.averageImpact) }
    }

    /// Calculate Pearson correlation coefficient (simplified)
    private func calculatePearsonCorrelation(x: [Double], xMean: Double, y: [Double], yMean: Double) -> Double {
        // Simplified correlation based on means difference
        let allValues = x + y
        guard !allValues.isEmpty else { return 0 }

        let overallMean = allValues.reduce(0, +) / Double(allValues.count)

        // Calculate variance
        let variance = allValues.map { pow($0 - overallMean, 2) }.reduce(0, +) / Double(allValues.count)
        guard variance > 0 else { return 0 }

        // Effect size as proxy for correlation
        let effectSize = (xMean - yMean) / sqrt(variance)

        // Convert to correlation range [-1, 1]
        return max(-1, min(1, effectSize / 2))
    }

    /// Estimate p-value based on correlation and sample size
    private func estimatePValue(correlation: Double, sampleSize: Int) -> Double {
        // Simplified p-value estimation
        // Strong correlation with large sample = low p-value
        let basePValue = 1.0 - correlation
        let sampleFactor = max(0.1, 1.0 - Double(sampleSize) / 50.0)
        return max(0.001, basePValue * sampleFactor)
    }

    /// Generate insights from correlation analysis
    private func generateInsights(
        correlations: [RecoveryCorrelation],
        sessions: [RecoverySession],
        healthData: [HealthDataPoint]
    ) -> [RecoveryInsight] {
        var insights: [RecoveryInsight] = []

        for correlation in correlations where correlation.isSignificant {
            let insightType: RecoveryInsightType
            let description: String

            // Determine insight type based on metric and impact direction
            switch correlation.metric {
            case .hrv:
                if correlation.averageImpact > 0 {
                    insightType = .hrvImprovement
                    description = "Your HRV improved \(Int(correlation.averageImpact))% after \(correlation.protocolType.displayName.lowercased()) sessions"
                } else {
                    insightType = .hrvDecline
                    description = "Your HRV decreased \(abs(Int(correlation.averageImpact)))% after \(correlation.protocolType.displayName.lowercased()) sessions"
                }

            case .sleepDuration:
                if correlation.averageImpact > 0 {
                    insightType = .sleepImprovement
                    description = "Sleep duration increased \(Int(correlation.averageImpact))% after \(correlation.protocolType.displayName.lowercased())"
                } else {
                    insightType = .sleepDecline
                    description = "Sleep duration decreased \(abs(Int(correlation.averageImpact)))% after \(correlation.protocolType.displayName.lowercased())"
                }

            case .deepSleep, .remSleep, .sleepQuality:
                insightType = .sleepQualityBoost
                let metricName = correlation.metric.displayName.lowercased()
                if correlation.averageImpact > 0 {
                    description = "\(correlation.metric.displayName) increased \(Int(correlation.averageImpact))% after \(correlation.protocolType.displayName.lowercased())"
                } else {
                    description = "\(correlation.metric.displayName) decreased \(abs(Int(correlation.averageImpact)))% after \(correlation.protocolType.displayName.lowercased())"
                }

            case .restingHeartRate:
                insightType = .recoveryEffectiveness
                if correlation.averageImpact > 0 {
                    description = "Resting heart rate dropped \(Int(correlation.averageImpact))% with \(correlation.protocolType.displayName.lowercased())"
                } else {
                    description = "Resting heart rate increased \(abs(Int(correlation.averageImpact)))% after \(correlation.protocolType.displayName.lowercased())"
                }
            }

            // Calculate baseline and average values
            let metricData = healthData.filter { $0.metric == correlation.metric }
            let baselineValue = metricData.isEmpty ? nil : metricData.map { $0.value }.reduce(0, +) / Double(metricData.count)

            // Confidence based on p-value and sample size
            let confidence = min(1.0, (1.0 - correlation.pValue) * (Double(correlation.sampleSize) / 20.0))

            insights.append(RecoveryInsight(
                type: insightType,
                metric: correlation.metric,
                protocolType: correlation.protocolType,
                impactPercentage: correlation.averageImpact,
                confidence: confidence,
                description: description,
                dataPoints: correlation.sampleSize,
                averageValue: nil,
                baselineValue: baselineValue
            ))
        }

        // Sort by absolute impact and confidence
        return insights.sorted {
            abs($0.impactPercentage) * $0.confidence > abs($1.impactPercentage) * $1.confidence
        }
    }

    /// Generate personalized recommendations based on insights
    private func generatePersonalizedRecommendations(
        insights: [RecoveryInsight],
        correlations: [RecoveryCorrelation],
        sessions: [RecoverySession]
    ) -> [PersonalizedRecoveryRecommendation] {
        var recommendations: [PersonalizedRecoveryRecommendation] = []

        // Group positive insights by protocol
        let positiveInsights = insights.filter { $0.impactPercentage > 3 && $0.confidence > 0.5 }
        let insightsByProtocol = Dictionary(grouping: positiveInsights, by: { $0.protocolType })

        for (protocolType, protocolInsights) in insightsByProtocol {
            guard let topInsight = protocolInsights.first else { continue }

            // Calculate average session duration for this protocol
            let protocolSessions = sessions.filter { $0.protocolType == protocolType }
            let avgDuration = protocolSessions.isEmpty ? nil : protocolSessions.map { $0.duration / 60 }.reduce(0, +) / protocolSessions.count

            // Determine suggested frequency based on session count
            let sessionCount = protocolSessions.count
            let suggestedFrequency: String
            if sessionCount >= 12 {
                suggestedFrequency = "Continue 3-4x per week"
            } else if sessionCount >= 6 {
                suggestedFrequency = "Try increasing to 3-4x per week"
            } else {
                suggestedFrequency = "Try 2-3x per week"
            }

            // Determine time of day based on session patterns
            let timeOfDay = determineOptimalTimeOfDay(sessions: protocolSessions)

            // Build expected benefit string
            let benefitStrings = protocolInsights.prefix(2).map { insight in
                "\(insight.formattedImpact) \(insight.metric.displayName)"
            }
            let expectedBenefit = benefitStrings.joined(separator: ", ")

            recommendations.append(PersonalizedRecoveryRecommendation(
                protocolType: protocolType,
                title: "Continue \(protocolType.displayName)",
                reason: topInsight.description,
                expectedBenefit: expectedBenefit,
                suggestedFrequency: suggestedFrequency,
                suggestedDuration: avgDuration,
                suggestedTimeOfDay: timeOfDay,
                priority: topInsight.impactPercentage > 10 ? .high : .medium,
                basedOnInsights: protocolInsights.map { $0.id }
            ))
        }

        // Add recommendations for unused protocols with known benefits
        let usedProtocols = Set(sessions.map { $0.protocolType })
        let unusedProtocols = RecoveryProtocolType.allCases.filter { !usedProtocols.contains($0) }

        for protocolType in unusedProtocols.prefix(2) {
            let (benefit, duration) = defaultBenefitForProtocol(protocolType)

            recommendations.append(PersonalizedRecoveryRecommendation(
                protocolType: protocolType,
                title: "Try \(protocolType.displayName)",
                reason: "You haven't tried this yet - many athletes report benefits",
                expectedBenefit: benefit,
                suggestedFrequency: "Start with 1-2x per week",
                suggestedDuration: duration,
                suggestedTimeOfDay: nil,
                priority: .low
            ))
        }

        return recommendations.sorted { $0.priority.rawValue < $1.priority.rawValue }
    }

    /// Determine optimal time of day based on session patterns
    private func determineOptimalTimeOfDay(sessions: [RecoverySession]) -> TimeOfDay? {
        guard !sessions.isEmpty else { return nil }

        let calendar = Calendar.current
        var timeDistribution: [TimeOfDay: Int] = [:]

        for session in sessions {
            let hour = calendar.component(.hour, from: session.startTime)
            let timeOfDay: TimeOfDay
            switch hour {
            case 5..<12: timeOfDay = .morning
            case 12..<17: timeOfDay = .afternoon
            case 17..<21: timeOfDay = .evening
            default: timeOfDay = .night
            }
            timeDistribution[timeOfDay, default: 0] += 1
        }

        return timeDistribution.max(by: { $0.value < $1.value })?.key
    }

    /// Get default benefit description for a protocol
    private func defaultBenefitForProtocol(_ protocolType: RecoveryProtocolType) -> (String, Int) {
        switch protocolType {
        case .sauna:
            return ("Improved HRV, better sleep quality", 20)
        case .coldPlunge:
            return ("Reduced inflammation, faster recovery", 3)
        case .contrast:
            return ("Enhanced circulation, muscle recovery", 15)
        case .cryotherapy:
            return ("Rapid inflammation reduction", 3)
        case .floatTank:
            return ("Deep relaxation, stress reduction", 60)
        case .massage:
            return ("Muscle tension relief, improved sleep", 60)
        case .stretching:
            return ("Improved flexibility, injury prevention", 15)
        case .meditation:
            return ("Stress reduction, improved HRV", 15)
        }
    }

    // MARK: - Helpers

    private func getPatientId() async throws -> UUID? {
        guard let userId = supabase.client.auth.currentUser?.id else { return nil }

        struct PatientRow: Decodable {
            let id: UUID
        }

        let patients: [PatientRow] = try await supabase.client
            .from("patients")
            .select("id")
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        return patients.first?.id
    }
}

// MARK: - Health Data Point

/// Internal struct for health data correlation analysis
private struct HealthDataPoint {
    let date: Date
    let metric: HealthMetricType
    let value: Double
}
