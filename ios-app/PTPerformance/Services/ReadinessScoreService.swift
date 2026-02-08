import Foundation
import Combine

/// AR60 Readiness Score Service
/// Calculates composite readiness scores for the X2Index Performance & Recovery Command Center
///
/// Aggregates data from:
/// - RecoveryTrackingService: Sauna, cold plunge, contrast therapy
/// - FastingTrackerService: Fasting protocols and compliance
/// - SupplementService: Supplement adherence
/// - BiomarkerDashboardViewModel: Lab results and biomarker status
/// - HealthScoreService: Sleep, HRV, activity data
/// - DailyReadiness: Check-in data (soreness, stress, energy)
@MainActor
final class ReadinessScoreService: ObservableObject {
    static let shared = ReadinessScoreService()

    // MARK: - Published Properties

    @Published private(set) var currentScore: AR60ReadinessScore?
    @Published private(set) var scoreHistory: [AR60ReadinessScore] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published private(set) var lastCalculatedAt: Date?

    // MARK: - Configuration

    /// Maximum age for data to be considered fresh (24 hours)
    private let staleDataThreshold: TimeInterval = 24 * 60 * 60

    /// Minimum data sources required for high confidence
    private let minSourcesForHighConfidence = 4

    /// History window for trend calculation (7 days)
    private let trendWindowDays = 7

    // MARK: - Dependencies

    private let supabase = PTSupabaseClient.shared
    private let recoveryService = RecoveryTrackingService.shared
    private let fastingService = FastingTrackerService.shared
    private let supplementService = SupplementService.shared
    private let healthScoreService = HealthScoreService.shared

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Calculate the current AR60 readiness score for an athlete
    /// - Parameter athleteId: The UUID of the athlete
    /// - Returns: Calculated AR60ReadinessScore
    func calculateReadinessScore(for athleteId: UUID) async throws -> AR60ReadinessScore {
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            // Gather all contributors in parallel
            async let sleepContributor = calculateSleepContributor(for: athleteId)
            async let recoveryContributor = calculateRecoveryContributor(for: athleteId)
            async let stressContributor = calculateStressContributor(for: athleteId)
            async let sorenessContributor = calculateSorenessContributor(for: athleteId)
            async let nutritionContributor = calculateNutritionContributor(for: athleteId)
            async let trainingContributor = calculateTrainingContributor(for: athleteId)
            async let biomarkerContributor = calculateBiomarkerContributor(for: athleteId)

            // Await all contributors
            let contributors = await [
                sleepContributor,
                recoveryContributor,
                stressContributor,
                sorenessContributor,
                nutritionContributor,
                trainingContributor,
                biomarkerContributor
            ].compactMap { $0 }

            // Calculate composite score
            let compositeScore = calculateCompositeScore(from: contributors)

            // Calculate confidence
            let confidence = calculateConfidence(from: contributors)

            // Determine trend
            let trend = await calculateTrend(for: athleteId, currentScore: compositeScore)

            // Check for uncertainty
            let uncertaintyFlag = checkUncertainty(contributors: contributors, confidence: confidence)

            let score = AR60ReadinessScore(
                athleteId: athleteId,
                score: compositeScore,
                confidence: confidence,
                trend: trend,
                contributors: contributors,
                timestamp: Date(),
                uncertaintyFlag: uncertaintyFlag
            )

            // Update state
            currentScore = score
            lastCalculatedAt = Date()

            // Persist to history
            await persistScore(score)

            DebugLogger.shared.info("ReadinessScoreService", "Calculated AR60 score: \(compositeScore) (confidence: \(String(format: "%.0f%%", confidence * 100)))")

            return score
        } catch {
            self.error = error
            DebugLogger.shared.error("ReadinessScoreService", "Failed to calculate readiness score: \(error)")
            throw error
        }
    }

    /// Refresh the current score
    func refreshScore() async {
        guard let athleteId = await getCurrentAthleteId() else {
            DebugLogger.shared.warning("ReadinessScoreService", "No athlete ID available for refresh")
            return
        }

        _ = try? await calculateReadinessScore(for: athleteId)
    }

    /// Load score history for trend analysis
    /// - Parameters:
    ///   - athleteId: The athlete's UUID
    ///   - days: Number of days of history to load
    func loadScoreHistory(for athleteId: UUID, days: Int = 7) async {
        isLoading = true

        do {
            let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

            struct ScoreRecord: Decodable {
                let id: UUID
                let athleteId: UUID
                let score: Int
                let confidence: Double
                let trend: String
                let timestamp: Date
                let uncertaintyFlag: Bool

                enum CodingKeys: String, CodingKey {
                    case id
                    case athleteId = "athlete_id"
                    case score
                    case confidence
                    case trend
                    case timestamp
                    case uncertaintyFlag = "uncertainty_flag"
                }
            }

            let records: [ScoreRecord] = try await supabase.client
                .from("ar60_readiness_scores")
                .select()
                .eq("athlete_id", value: athleteId.uuidString)
                .gte("timestamp", value: ISO8601DateFormatter().string(from: startDate))
                .order("timestamp", ascending: false)
                .limit(days * 4) // Multiple scores per day possible
                .execute()
                .value

            scoreHistory = records.map { record in
                AR60ReadinessScore(
                    id: record.id,
                    athleteId: record.athleteId,
                    score: record.score,
                    confidence: record.confidence,
                    trend: AR60ReadinessScore.ReadinessTrend(rawValue: record.trend) ?? .unknown,
                    contributors: [], // History records don't need full contributors
                    timestamp: record.timestamp,
                    uncertaintyFlag: record.uncertaintyFlag
                )
            }

            DebugLogger.shared.info("ReadinessScoreService", "Loaded \(scoreHistory.count) historical scores")
        } catch {
            // Silently handle - history is optional
            DebugLogger.shared.warning("ReadinessScoreService", "Failed to load score history: \(error.localizedDescription)")
            scoreHistory = []
        }

        isLoading = false
    }

    /// Get contributor details for a specific domain
    func getContributorDetails(for domain: ReadinessContributor.ReadinessDomain) -> ReadinessContributor? {
        currentScore?.contributors.first { $0.domain == domain }
    }

    // MARK: - Private Calculation Methods

    /// Calculate sleep contributor from HealthKit and check-in data
    private func calculateSleepContributor(for athleteId: UUID) async -> ReadinessContributor? {
        var sourceRefs: [EvidenceSourceRef] = []
        var sleepScore: Double = 70 // Baseline

        // Try to get sleep data from health service
        if let healthScore = healthScoreService.currentScore {
            sleepScore = Double(healthScore.sleepScore)
            sourceRefs.append(EvidenceSourceRef(
                sourceType: .wearableMetric,
                sourceId: "health_sleep",
                timestamp: healthScore.date,
                snippet: "Sleep score: \(healthScore.sleepScore)"
            ))
        }

        // Get daily readiness check-in sleep data
        if let checkInSleep = await fetchLatestCheckInSleep(for: athleteId) {
            let hoursScore = calculateSleepHoursScore(hours: checkInSleep.hours)
            sleepScore = sourceRefs.isEmpty ? hoursScore : (sleepScore + hoursScore) / 2
            sourceRefs.append(EvidenceSourceRef(
                sourceType: .dailyCheckIn,
                sourceId: checkInSleep.checkInId,
                timestamp: checkInSleep.date,
                snippet: String(format: "%.1f hours sleep", checkInSleep.hours)
            ))
        }

        guard !sourceRefs.isEmpty else { return nil }

        let impact = classifyImpact(score: sleepScore)

        return ReadinessContributor(
            domain: .sleep,
            value: sleepScore,
            impact: impact,
            sourceRefs: sourceRefs
        )
    }

    /// Calculate recovery contributor from RecoveryTrackingService
    private func calculateRecoveryContributor(for athleteId: UUID) async -> ReadinessContributor? {
        var sourceRefs: [EvidenceSourceRef] = []
        var recoveryScore: Double = 70 // Baseline

        // Get recovery stats
        let weeklyStats = await recoveryService.calculateWeeklyStats()
        let streakInfo = await recoveryService.calculateStreakInfo()

        // Score based on recovery activities this week
        if weeklyStats.totalSessions > 0 {
            // Base score from session count (0-3 sessions = 50-80, 4+ = 80-100)
            let sessionScore = min(100, 50 + Double(weeklyStats.totalSessions) * 12.5)

            // Bonus for streak
            let streakBonus = min(20, Double(streakInfo.currentStreak) * 2)

            recoveryScore = min(100, sessionScore + streakBonus)

            sourceRefs.append(EvidenceSourceRef(
                sourceType: .dailyCheckIn,
                sourceId: "recovery_weekly",
                timestamp: Date(),
                snippet: "\(weeklyStats.totalSessions) sessions, \(weeklyStats.totalMinutes) min this week"
            ))

            if streakInfo.currentStreak > 0 {
                sourceRefs.append(EvidenceSourceRef(
                    sourceType: .dailyCheckIn,
                    sourceId: "recovery_streak",
                    timestamp: Date(),
                    snippet: "\(streakInfo.currentStreak) day streak"
                ))
            }
        }

        // Get HRV data from health score if available
        if let healthScore = healthScoreService.currentScore {
            let hrvRecoveryScore = Double(healthScore.recoveryScore)
            recoveryScore = sourceRefs.isEmpty ? hrvRecoveryScore : (recoveryScore * 0.6 + hrvRecoveryScore * 0.4)

            sourceRefs.append(EvidenceSourceRef(
                sourceType: .wearableMetric,
                sourceId: "health_recovery",
                timestamp: healthScore.date,
                snippet: "HRV recovery: \(healthScore.recoveryScore)"
            ))
        }

        guard !sourceRefs.isEmpty else { return nil }

        let impact = classifyImpact(score: recoveryScore)

        return ReadinessContributor(
            domain: .recovery,
            value: recoveryScore,
            impact: impact,
            sourceRefs: sourceRefs
        )
    }

    /// Calculate stress contributor from check-in data
    private func calculateStressContributor(for athleteId: UUID) async -> ReadinessContributor? {
        var sourceRefs: [EvidenceSourceRef] = []
        var stressScore: Double = 70 // Baseline (higher = less stress)

        // Get latest check-in stress level
        if let stressData = await fetchLatestCheckInStress(for: athleteId) {
            // Convert 1-10 stress level to 0-100 score (inverted: low stress = high score)
            stressScore = 100 - (Double(stressData.level) * 10)
            sourceRefs.append(EvidenceSourceRef(
                sourceType: .dailyCheckIn,
                sourceId: stressData.checkInId,
                timestamp: stressData.date,
                snippet: "Stress level: \(stressData.level)/10"
            ))
        }

        // Integrate health score stress data
        if let healthScore = healthScoreService.currentScore {
            let healthStressScore = Double(healthScore.stressScore)
            stressScore = sourceRefs.isEmpty ? healthStressScore : (stressScore + healthStressScore) / 2

            if sourceRefs.isEmpty {
                sourceRefs.append(EvidenceSourceRef(
                    sourceType: .wearableMetric,
                    sourceId: "health_stress",
                    timestamp: healthScore.date,
                    snippet: "Stress score: \(healthScore.stressScore)"
                ))
            }
        }

        guard !sourceRefs.isEmpty else { return nil }

        let impact = classifyImpact(score: stressScore)

        return ReadinessContributor(
            domain: .stress,
            value: stressScore,
            impact: impact,
            sourceRefs: sourceRefs
        )
    }

    /// Calculate soreness contributor from check-in data
    private func calculateSorenessContributor(for athleteId: UUID) async -> ReadinessContributor? {
        var sourceRefs: [EvidenceSourceRef] = []

        // Get latest check-in soreness level
        guard let sorenessData = await fetchLatestCheckInSoreness(for: athleteId) else {
            return nil
        }

        // Convert 1-10 soreness to 0-100 score (inverted: low soreness = high score)
        let sorenessScore = 100 - (Double(sorenessData.level) * 10)

        sourceRefs.append(EvidenceSourceRef(
            sourceType: .dailyCheckIn,
            sourceId: sorenessData.checkInId,
            timestamp: sorenessData.date,
            snippet: "Soreness: \(sorenessData.level)/10"
        ))

        let impact = classifyImpact(score: sorenessScore)

        return ReadinessContributor(
            domain: .soreness,
            value: sorenessScore,
            impact: impact,
            sourceRefs: sourceRefs
        )
    }

    /// Calculate nutrition contributor from fasting and supplement data
    private func calculateNutritionContributor(for athleteId: UUID) async -> ReadinessContributor? {
        var sourceRefs: [EvidenceSourceRef] = []
        var nutritionScore: Double = 70 // Baseline

        // Get fasting compliance
        await fastingService.fetchFastingData()
        let (weeklyCompleted, avgHours, compliance) = fastingService.weeklyStats()

        if weeklyCompleted > 0 {
            // Score based on fasting compliance
            let fastingScore = compliance * 100

            nutritionScore = fastingScore

            sourceRefs.append(EvidenceSourceRef(
                sourceType: .dailyCheckIn,
                sourceId: "fasting_weekly",
                timestamp: Date(),
                snippet: "\(weeklyCompleted) fasts, \(String(format: "%.0f%%", compliance * 100)) compliance"
            ))
        }

        // Get supplement compliance
        if let supplementCompliance = supplementService.todayCompliance {
            let supplementScore = supplementCompliance.complianceRate * 100

            // Average with fasting score if both available
            nutritionScore = sourceRefs.isEmpty ? supplementScore : (nutritionScore + supplementScore) / 2

            sourceRefs.append(EvidenceSourceRef(
                sourceType: .dailyCheckIn,
                sourceId: "supplement_today",
                timestamp: Date(),
                snippet: "\(supplementCompliance.takenCount)/\(supplementCompliance.totalCount) supplements"
            ))
        }

        guard !sourceRefs.isEmpty else { return nil }

        let impact = classifyImpact(score: nutritionScore)

        return ReadinessContributor(
            domain: .nutrition,
            value: nutritionScore,
            impact: impact,
            sourceRefs: sourceRefs
        )
    }

    /// Calculate training load contributor
    private func calculateTrainingContributor(for athleteId: UUID) async -> ReadinessContributor? {
        var sourceRefs: [EvidenceSourceRef] = []

        // Get training load from health score
        if let healthScore = healthScoreService.currentScore {
            let activityScore = Double(healthScore.activityScore)

            sourceRefs.append(EvidenceSourceRef(
                sourceType: .wearableMetric,
                sourceId: "health_activity",
                timestamp: healthScore.date,
                snippet: "Activity score: \(healthScore.activityScore)"
            ))

            let impact = classifyImpact(score: activityScore)

            return ReadinessContributor(
                domain: .training,
                value: activityScore,
                impact: impact,
                sourceRefs: sourceRefs
            )
        }

        return nil
    }

    /// Calculate biomarker contributor from lab results
    private func calculateBiomarkerContributor(for athleteId: UUID) async -> ReadinessContributor? {
        var sourceRefs: [EvidenceSourceRef] = []

        // This would integrate with BiomarkerDashboardViewModel
        // For now, return a baseline if lab data exists
        // Full implementation would fetch from lab_results table

        do {
            struct LabCheck: Decodable {
                let count: Int
            }

            let labResults: [LabCheck] = try await supabase.client
                .from("lab_results")
                .select("id", head: true, count: .exact)
                .eq("patient_id", value: athleteId.uuidString)
                .limit(1)
                .execute()
                .value

            // If we have recent labs, add a baseline biomarker score
            // Full implementation would analyze specific markers
            if !labResults.isEmpty {
                sourceRefs.append(EvidenceSourceRef(
                    sourceType: .labResult,
                    sourceId: "lab_recent",
                    timestamp: Date(),
                    snippet: "Lab results on file"
                ))

                return ReadinessContributor(
                    domain: .biomarkers,
                    value: 75, // Baseline when labs exist
                    impact: .neutral,
                    sourceRefs: sourceRefs
                )
            }
        } catch {
            // Silently handle - biomarkers are optional
            DebugLogger.shared.debug("ReadinessScoreService", "No biomarker data available")
        }

        return nil
    }

    // MARK: - Composite Score Calculation

    /// Calculate weighted composite score from contributors
    private func calculateCompositeScore(from contributors: [ReadinessContributor]) -> Int {
        guard !contributors.isEmpty else { return 50 } // Default middle score

        var totalWeight: Double = 0
        var weightedSum: Double = 0

        for contributor in contributors {
            weightedSum += contributor.value * contributor.weight
            totalWeight += contributor.weight
        }

        guard totalWeight > 0 else { return 50 }

        return Int(weightedSum / totalWeight)
    }

    /// Calculate confidence based on data completeness and recency
    private func calculateConfidence(from contributors: [ReadinessContributor]) -> Double {
        guard !contributors.isEmpty else { return 0.0 }

        var confidence: Double = 0.0

        // Base confidence from number of data sources
        let sourceCount = contributors.count
        let sourceConfidence = min(1.0, Double(sourceCount) / Double(minSourcesForHighConfidence))
        confidence += sourceConfidence * 0.4

        // Add confidence from evidence recency
        var recencyScore: Double = 0
        var evidenceCount = 0

        for contributor in contributors {
            for source in contributor.sourceRefs {
                evidenceCount += 1
                if !source.isStale {
                    recencyScore += 1.0
                } else {
                    recencyScore += 0.3 // Stale data still has some value
                }
            }
        }

        if evidenceCount > 0 {
            let avgRecency = recencyScore / Double(evidenceCount)
            confidence += avgRecency * 0.4
        }

        // Add confidence from evidence coverage (multiple sources per contributor)
        let avgSourcesPerContributor = contributors.isEmpty ? 0 : Double(evidenceCount) / Double(contributors.count)
        let coverageConfidence = min(1.0, avgSourcesPerContributor / 2.0)
        confidence += coverageConfidence * 0.2

        return min(1.0, max(0.0, confidence))
    }

    /// Calculate trend from historical data
    private func calculateTrend(for athleteId: UUID, currentScore: Int) async -> AR60ReadinessScore.ReadinessTrend {
        // Load recent history if not already loaded
        if scoreHistory.isEmpty {
            await loadScoreHistory(for: athleteId, days: trendWindowDays)
        }

        guard scoreHistory.count >= 2 else { return .unknown }

        // Calculate average of recent scores
        let recentScores = scoreHistory.prefix(5).map { $0.score }
        let avgRecent = Double(recentScores.reduce(0, +)) / Double(recentScores.count)

        // Calculate average of older scores
        let olderScores = scoreHistory.dropFirst(5).prefix(5).map { $0.score }
        guard !olderScores.isEmpty else { return .stable }

        let avgOlder = Double(olderScores.reduce(0, +)) / Double(olderScores.count)

        // Determine trend
        let difference = avgRecent - avgOlder
        if difference > 5 {
            return .improving
        } else if difference < -5 {
            return .declining
        } else {
            return .stable
        }
    }

    /// Check for uncertainty conditions
    private func checkUncertainty(contributors: [ReadinessContributor], confidence: Double) -> Bool {
        // Flag uncertainty if confidence is low
        if confidence < 0.5 {
            return true
        }

        // Flag if all evidence is stale
        let allStale = contributors.allSatisfy { $0.hasStaleEvidence }
        if allStale && !contributors.isEmpty {
            return true
        }

        // Flag if there are conflicting critical impacts
        let criticalContributors = contributors.filter { $0.impact == .critical }
        let positiveContributors = contributors.filter { $0.impact == .positive }

        if criticalContributors.count > 0 && positiveContributors.count >= 2 {
            // Conflicting signals
            return true
        }

        return false
    }

    // MARK: - Helper Methods

    /// Classify impact based on score
    private func classifyImpact(score: Double) -> ReadinessContributor.ContributorImpact {
        switch score {
        case 80...100: return .positive
        case 60..<80: return .neutral
        case 40..<60: return .negative
        default: return .critical
        }
    }

    /// Calculate sleep score from hours
    private func calculateSleepHoursScore(hours: Double) -> Double {
        switch hours {
        case 7...9: return 90 + (hours - 7) * 5 // 90-100
        case 6..<7: return 70 + (hours - 6) * 20 // 70-90
        case 5..<6: return 50 + (hours - 5) * 20 // 50-70
        case 9..<10: return 85 // Slightly oversleeping
        default: return max(20, hours * 10)
        }
    }

    /// Get current athlete ID
    private func getCurrentAthleteId() async -> UUID? {
        guard let userId = supabase.client.auth.currentUser?.id else { return nil }

        struct PatientRow: Decodable {
            let id: UUID
        }

        do {
            let patients: [PatientRow] = try await supabase.client
                .from("patients")
                .select("id")
                .eq("user_id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value

            return patients.first?.id
        } catch {
            DebugLogger.shared.error("ReadinessScoreService", "Failed to get athlete ID: \(error)")
            return nil
        }
    }

    /// Persist score to database
    private func persistScore(_ score: AR60ReadinessScore) async {
        struct ScoreInsert: Encodable {
            let id: UUID
            let athlete_id: UUID
            let score: Int
            let confidence: Double
            let trend: String
            let timestamp: String
            let uncertainty_flag: Bool
        }

        let insert = ScoreInsert(
            id: score.id,
            athlete_id: score.athleteId,
            score: score.score,
            confidence: score.confidence,
            trend: score.trend.rawValue,
            timestamp: ISO8601DateFormatter().string(from: score.timestamp),
            uncertainty_flag: score.uncertaintyFlag
        )

        do {
            try await supabase.client
                .from("ar60_readiness_scores")
                .insert(insert)
                .execute()
        } catch {
            // Silently handle - persistence is nice to have
            DebugLogger.shared.debug("ReadinessScoreService", "Could not persist score: \(error.localizedDescription)")
        }
    }

    // MARK: - Check-in Data Fetching

    private struct CheckInSleep {
        let checkInId: String
        let hours: Double
        let date: Date
    }

    private struct CheckInStress {
        let checkInId: String
        let level: Int
        let date: Date
    }

    private struct CheckInSoreness {
        let checkInId: String
        let level: Int
        let date: Date
    }

    private func fetchLatestCheckInSleep(for athleteId: UUID) async -> CheckInSleep? {
        struct ReadinessRecord: Decodable {
            let id: UUID
            let sleepHours: Double?
            let createdAt: Date

            enum CodingKeys: String, CodingKey {
                case id
                case sleepHours = "sleep_hours"
                case createdAt = "created_at"
            }
        }

        do {
            let records: [ReadinessRecord] = try await supabase.client
                .from("daily_readiness")
                .select("id, sleep_hours, created_at")
                .eq("patient_id", value: athleteId.uuidString)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value

            if let record = records.first, let hours = record.sleepHours {
                return CheckInSleep(
                    checkInId: record.id.uuidString,
                    hours: hours,
                    date: record.createdAt
                )
            }
        } catch {
            DebugLogger.shared.debug("ReadinessScoreService", "No sleep check-in data")
        }

        return nil
    }

    private func fetchLatestCheckInStress(for athleteId: UUID) async -> CheckInStress? {
        struct ReadinessRecord: Decodable {
            let id: UUID
            let stressLevel: Int?
            let createdAt: Date

            enum CodingKeys: String, CodingKey {
                case id
                case stressLevel = "stress_level"
                case createdAt = "created_at"
            }
        }

        do {
            let records: [ReadinessRecord] = try await supabase.client
                .from("daily_readiness")
                .select("id, stress_level, created_at")
                .eq("patient_id", value: athleteId.uuidString)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value

            if let record = records.first, let level = record.stressLevel {
                return CheckInStress(
                    checkInId: record.id.uuidString,
                    level: level,
                    date: record.createdAt
                )
            }
        } catch {
            DebugLogger.shared.debug("ReadinessScoreService", "No stress check-in data")
        }

        return nil
    }

    private func fetchLatestCheckInSoreness(for athleteId: UUID) async -> CheckInSoreness? {
        struct ReadinessRecord: Decodable {
            let id: UUID
            let sorenessLevel: Int?
            let createdAt: Date

            enum CodingKeys: String, CodingKey {
                case id
                case sorenessLevel = "soreness_level"
                case createdAt = "created_at"
            }
        }

        do {
            let records: [ReadinessRecord] = try await supabase.client
                .from("daily_readiness")
                .select("id, soreness_level, created_at")
                .eq("patient_id", value: athleteId.uuidString)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value

            if let record = records.first, let level = record.sorenessLevel {
                return CheckInSoreness(
                    checkInId: record.id.uuidString,
                    level: level,
                    date: record.createdAt
                )
            }
        } catch {
            DebugLogger.shared.debug("ReadinessScoreService", "No soreness check-in data")
        }

        return nil
    }
}

// MARK: - Error Types

enum ReadinessScoreError: Error, LocalizedError {
    case noAthleteId
    case insufficientData
    case calculationFailed(String)

    var errorDescription: String? {
        switch self {
        case .noAthleteId:
            return "No athlete ID available"
        case .insufficientData:
            return "Insufficient data to calculate readiness score"
        case .calculationFailed(let reason):
            return "Score calculation failed: \(reason)"
        }
    }
}
