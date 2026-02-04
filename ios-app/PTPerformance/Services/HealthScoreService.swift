import Foundation

/// Service for health score calculation and AI insights
@MainActor
final class HealthScoreService: ObservableObject {
    static let shared = HealthScoreService()

    @Published private(set) var currentScore: HealthScore?
    @Published private(set) var scoreHistory: [HealthScore] = []
    @Published private(set) var insights: [HealthInsight] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    private let supabase = PTSupabaseClient.shared

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
        // TODO: Integrate with HealthKit sleep data
        return 75
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
        // TODO: Integrate with nutrition tracking
        return 70
    }

    private func calculateActivityScore() async -> Int {
        // TODO: Integrate with workout completion data
        return 80
    }

    private func calculateStressScore() async -> Int {
        // TODO: Integrate with readiness/HRV data
        return 65
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
