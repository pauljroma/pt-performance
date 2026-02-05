import Foundation

/// Service for health score calculation and AI insights
///
/// Calculates composite health scores from multiple data sources:
/// - Sleep: HealthKit sleep data (duration, efficiency)
/// - Recovery: RecoveryService session tracking
/// - Activity: Workout completion and training load
/// - Stress: Readiness check-in data and HRV
/// - Nutrition: Nutrition log compliance (when available)
@MainActor
final class HealthScoreService: ObservableObject {
    static let shared = HealthScoreService()

    @Published private(set) var currentScore: HealthScore?
    @Published private(set) var scoreHistory: [HealthScore] = []
    @Published private(set) var insights: [HealthInsight] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    private let supabase = PTSupabaseClient.shared
    private let healthKitService = HealthKitService.shared
    private let readinessService = ReadinessService()

    private init() {}

    // MARK: - Fetch Score

    func fetchHealthScore() async {
        isLoading = true
        error = nil

        do {
            guard let patientId = try await getPatientId() else { return }

            // Fetch latest scores
            let scores: [HealthScore] = try await supabase.client
                .from("health_scores")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .order("date", ascending: false)
                .limit(30)
                .execute()
                .value

            self.scoreHistory = scores
            self.currentScore = scores.first

            if let current = currentScore {
                self.insights = current.insights
            }
        } catch {
            self.error = error
            DebugLogger.shared.error("HealthScoreService", "Failed to fetch health score: \(error)")
        }

        isLoading = false
    }

    // MARK: - Calculate Score

    func calculateTodayScore() async {
        // Gather data from various sources
        let sleepScore = await calculateSleepScore()
        let recoveryScore = await calculateRecoveryScore()
        let nutritionScore = await calculateNutritionScore()
        let activityScore = await calculateActivityScore()
        let stressScore = await calculateStressScore()

        // Weighted average
        let weights: [Double] = [0.25, 0.20, 0.20, 0.20, 0.15]
        let scores = [sleepScore, recoveryScore, nutritionScore, activityScore, stressScore]
        let overallScore = Int(zip(scores.map { Double($0) }, weights).map { $0 * $1 }.reduce(0, +))

        guard let patientId = try? await getPatientId() else { return }

        let breakdown = [
            HealthScoreComponent(id: UUID(), category: "Sleep", score: sleepScore, weight: weights[0], trend: .stable),
            HealthScoreComponent(id: UUID(), category: "Recovery", score: recoveryScore, weight: weights[1], trend: .stable),
            HealthScoreComponent(id: UUID(), category: "Nutrition", score: nutritionScore, weight: weights[2], trend: .stable),
            HealthScoreComponent(id: UUID(), category: "Activity", score: activityScore, weight: weights[3], trend: .stable),
            HealthScoreComponent(id: UUID(), category: "Stress", score: stressScore, weight: weights[4], trend: .stable)
        ]

        let generatedInsights = generateInsights(from: breakdown)

        let score = HealthScore(
            id: UUID(),
            patientId: patientId,
            date: Date(),
            overallScore: overallScore,
            sleepScore: sleepScore,
            recoveryScore: recoveryScore,
            nutritionScore: nutritionScore,
            activityScore: activityScore,
            stressScore: stressScore,
            breakdown: breakdown,
            insights: generatedInsights,
            createdAt: Date()
        )

        currentScore = score
        insights = generatedInsights
    }

    // MARK: - Score Calculations

    private func calculateSleepScore() async -> Int {
        // Integrate with HealthKit sleep data
        do {
            guard let sleepData = try await healthKitService.fetchSleepData(for: Date()) else {
                DebugLogger.shared.info("HealthScoreService", "No sleep data available, using baseline score")
                return 70 // Baseline when no data
            }

            var score: Double = 50.0

            // Sleep duration component (60% weight)
            // Optimal: 7-9 hours = 100, <5 or >10 hours scores lower
            let hours = sleepData.totalHours
            let durationScore: Double
            if hours >= 7 && hours <= 9 {
                durationScore = 100.0
            } else if hours >= 6 && hours < 7 {
                durationScore = 70.0 + (hours - 6) * 30  // 70-100
            } else if hours >= 5 && hours < 6 {
                durationScore = 50.0 + (hours - 5) * 20  // 50-70
            } else if hours > 9 && hours <= 10 {
                durationScore = 90.0 // Slightly oversleeping is okay
            } else {
                durationScore = max(20, hours * 10)
            }

            // Sleep efficiency component (40% weight)
            let efficiencyScore = sleepData.sleepEfficiency // Already 0-100

            score = (durationScore * 0.6) + (efficiencyScore * 0.4)

            DebugLogger.shared.info("HealthScoreService", "Sleep score: \(Int(score)) (hours: \(hours), efficiency: \(Int(efficiencyScore))%)")
            return Int(min(100, max(0, score)))
        } catch {
            DebugLogger.shared.warning("HealthScoreService", "Failed to calculate sleep score: \(error.localizedDescription)")
            return 70 // Fallback baseline
        }
    }

    private func calculateRecoveryScore() async -> Int {
        let sessions = RecoveryService.shared.sessions
        let weeklyCount = sessions.filter {
            Calendar.current.isDate($0.loggedAt, equalTo: Date(), toGranularity: .weekOfYear)
        }.count

        // Target: 3-5 recovery sessions per week
        return min(100, weeklyCount * 20)
    }

    private func calculateNutritionScore() async -> Int {
        // Integrate with nutrition logging data
        do {
            guard let patientId = try await getPatientId() else {
                return 70 // Baseline when no patient
            }

            // Get nutrition logs from the past 7 days
            let calendar = Calendar.current
            let today = Date()
            guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) else {
                return 70
            }

            let logs = try await NutritionService.shared.fetchNutritionLogs(
                patientId: patientId.uuidString,
                startDate: weekAgo,
                endDate: today
            )

            // Calculate nutrition score based on:
            // 1. Logging consistency (40% weight) - target: log at least 2 meals/day
            // 2. Protein target (30% weight) - based on hitting daily protein goals
            // 3. Overall calorie balance (30% weight)

            guard !logs.isEmpty else {
                DebugLogger.shared.info("HealthScoreService", "No nutrition logs found, using baseline score")
                return 60 // Lower baseline when not tracking
            }

            // 1. Logging consistency score
            let uniqueDays = Set(logs.compactMap { log in
                calendar.startOfDay(for: log.loggedAt)
            }).count
            let consistencyScore = min(100.0, Double(uniqueDays) / 7.0 * 100.0)

            // 2. Average daily protein (assume target of 1g per lb bodyweight ≈ 150g for average athlete)
            let proteinTarget = 150.0 // Default target, could be personalized
            let totalProtein = logs.compactMap { $0.totalProteinG }.reduce(0, +)
            let avgDailyProtein = totalProtein / max(1, Double(uniqueDays))
            let proteinScore = min(100.0, (avgDailyProtein / proteinTarget) * 100.0)

            // 3. Calorie tracking score (reward consistent logging, not under/over eating)
            let loggedMeals = logs.count
            let mealsPerDay = Double(loggedMeals) / max(1, Double(uniqueDays))
            let calorieTrackingScore = min(100.0, (mealsPerDay / 3.0) * 100.0) // Target: 3 meals/day logged

            // Weighted average
            let finalScore = (consistencyScore * 0.4) + (proteinScore * 0.3) + (calorieTrackingScore * 0.3)

            DebugLogger.shared.info("HealthScoreService", "Nutrition score: \(Int(finalScore)) (consistency: \(Int(consistencyScore)), protein: \(Int(proteinScore)), tracking: \(Int(calorieTrackingScore)))")
            return Int(min(100, max(0, finalScore)))
        } catch {
            DebugLogger.shared.warning("HealthScoreService", "Failed to calculate nutrition score: \(error.localizedDescription)")
            return 70 // Fallback baseline
        }
    }

    private func calculateActivityScore() async -> Int {
        // Integrate with workout completion and HealthKit activity data
        do {
            guard let patientId = try await getPatientId() else {
                return 70 // Baseline when no patient
            }

            // Get completed workouts this week
            let calendar = Calendar.current
            let today = Date()
            guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
                return 70
            }

            // Query completed sessions from this week
            struct CompletedSession: Decodable {
                let completedAt: Date?

                enum CodingKeys: String, CodingKey {
                    case completedAt = "completed_at"
                }
            }

            let completedSessions: [CompletedSession] = try await supabase.client
                .from("patient_scheduled_sessions")
                .select("completed_at")
                .eq("patient_id", value: patientId.uuidString)
                .gte("scheduled_date", value: ISO8601DateFormatter().string(from: weekStart))
                .not("completed_at", operator: .is, value: "null")
                .execute()
                .value

            let weeklyCompletedCount = completedSessions.count

            // Also get HealthKit step data for baseline activity
            let steps = try await healthKitService.fetchSteps(for: today)

            // Activity score calculation:
            // - Workout completion: 60% weight (target: 4-5 sessions/week = 100)
            // - Daily steps: 40% weight (target: 8000 steps = 100)

            let workoutScore = min(100.0, Double(weeklyCompletedCount) * 20.0)
            let stepsScore = min(100.0, (steps / 8000.0) * 100.0)

            let score = (workoutScore * 0.6) + (stepsScore * 0.4)

            DebugLogger.shared.info("HealthScoreService", "Activity score: \(Int(score)) (workouts: \(weeklyCompletedCount), steps: \(Int(steps)))")
            return Int(min(100, max(0, score)))
        } catch {
            DebugLogger.shared.warning("HealthScoreService", "Failed to calculate activity score: \(error.localizedDescription)")
            return 70 // Fallback baseline
        }
    }

    private func calculateStressScore() async -> Int {
        // Integrate with readiness check-in and HRV data
        // Note: This is an inverse stress score (higher = LESS stressed = better)
        do {
            guard let patientId = try await getPatientId() else {
                return 70 // Baseline when no patient
            }

            var totalWeight: Double = 0
            var weightedScore: Double = 0

            // 1. Readiness check-in stress level (40% weight when available)
            if let readiness = try await readinessService.getTodayReadiness(for: patientId),
               let stressLevel = readiness.stressLevel {
                // stressLevel is 1-10 where 1 = no stress, 10 = very stressed
                // Invert: stress=1 → score=100, stress=10 → score=10
                let stressScore = Double(110 - stressLevel * 10)
                weightedScore += stressScore * 0.4
                totalWeight += 0.4
            }

            // 2. HRV-based stress indicator (35% weight when available)
            let hrvValue = try await healthKitService.fetchHRV(for: Date())
            let hrvBaseline = try await healthKitService.getHRVBaseline(days: 7)

            if let hrv = hrvValue, let baseline = hrvBaseline, baseline > 0 {
                // HRV above baseline indicates good recovery/low stress
                let deviation = ((hrv - baseline) / baseline) * 100
                // Score: +20% deviation = 100, baseline = 70, -30% deviation = 30
                let hrvScore = min(100, max(0, 70 + (deviation * 1.5)))
                weightedScore += hrvScore * 0.35
                totalWeight += 0.35
            }

            // 3. Resting heart rate stress indicator (25% weight when available)
            if let rhr = try await healthKitService.fetchRestingHeartRate(for: Date()) {
                // Lower RHR = better recovery/less stress
                // Score: <50 = 100, 50-60 = 80-100, 60-70 = 60-80, >70 = lower
                let rhrScore: Double
                if rhr <= 50 {
                    rhrScore = 100
                } else if rhr <= 60 {
                    rhrScore = 80 + (60 - rhr) * 2
                } else if rhr <= 70 {
                    rhrScore = 60 + (70 - rhr) * 2
                } else {
                    rhrScore = max(20, 60 - (rhr - 70) * 2)
                }
                weightedScore += rhrScore * 0.25
                totalWeight += 0.25
            }

            // Calculate final score (normalize if we have partial data)
            let finalScore: Double
            if totalWeight > 0 {
                finalScore = weightedScore / totalWeight
            } else {
                finalScore = 70 // Default when no data
            }

            DebugLogger.shared.info("HealthScoreService", "Stress score: \(Int(finalScore)) (weight: \(Int(totalWeight * 100))%)")
            return Int(min(100, max(0, finalScore)))
        } catch {
            DebugLogger.shared.warning("HealthScoreService", "Failed to calculate stress score: \(error.localizedDescription)")
            return 70 // Fallback baseline
        }
    }

    // MARK: - Insights Generation

    private func generateInsights(from breakdown: [HealthScoreComponent]) -> [HealthInsight] {
        var insights: [HealthInsight] = []

        for component in breakdown {
            if component.score < 60 {
                let insight = HealthInsight(
                    id: UUID(),
                    category: categoryFromString(component.category),
                    title: "Improve your \(component.category.lowercased())",
                    description: "Your \(component.category.lowercased()) score is below optimal. Focus on this area.",
                    actionable: true,
                    action: "View recommendations",
                    priority: .high
                )
                insights.append(insight)
            }
        }

        return insights
    }

    private func categoryFromString(_ string: String) -> InsightCategory {
        switch string.lowercased() {
        case "sleep": return .sleep
        case "recovery": return .recovery
        case "nutrition": return .nutrition
        case "activity": return .training
        case "stress": return .stress
        default: return .general
        }
    }

    // MARK: - AI Chat

    func sendMessage(_ message: String) async -> HealthCoachMessage {
        // TODO: Integrate with AI backend
        let response = HealthCoachMessage(
            id: UUID(),
            role: .assistant,
            content: "Based on your health data, I recommend focusing on recovery. Your recent training load has been high.",
            timestamp: Date(),
            category: .recovery
        )
        return response
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
