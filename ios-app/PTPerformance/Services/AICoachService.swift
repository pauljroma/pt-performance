import Foundation

/// Service for unified AI coaching functionality
@MainActor
final class AICoachService: ObservableObject {
    static let shared = AICoachService()

    @Published private(set) var currentResponse: UnifiedCoachResponse?
    @Published private(set) var proactiveInsights: [CoachingInsight] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    private let supabase = PTSupabaseClient.shared
    private let edgeFunctionUrl = "unified-ai-coach"

    // Note: Demo mode uses authenticated demo session via Supabase edge function.
    // No hardcoded patient IDs needed — getPatientId() returns nil for unauthenticated users.

    // MARK: - Response Caching

    /// Cache for AI responses to avoid redundant network calls
    private var responseCache: [String: CachedResponse] = [:]

    /// Cache expiration time in seconds (5 minutes)
    private let cacheExpirationSeconds: TimeInterval = 300

    /// Struct to hold cached responses with timestamp
    private struct CachedResponse {
        let response: UnifiedCoachResponse
        let timestamp: Date

        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > 300 // 5 minutes
        }
    }

    private init() {}

    // MARK: - Ask Coach

    /// Whether the user has granted AI personalization consent
    var hasAIConsent: Bool {
        ConsentManager.shared.isGranted(.aiPersonalization)
    }

    /// Sends a question to the AI coach and receives a contextual response
    /// Includes caching to avoid redundant requests for identical questions
    /// ACP-1023: Now passes client-side context for faster personalization
    func askCoach(question: String) async -> UnifiedCoachResponse? {
        guard hasAIConsent else {
            DebugLogger.shared.info("AICoachService", "AI consent not granted — skipping request")
            return nil
        }

        isLoading = true
        error = nil

        do {
            guard let patientId = try await getPatientId() else {
                error = AICoachError.noPatientId
                isLoading = false
                return nil
            }

            // Check cache for recent identical question
            let cacheKey = "\(patientId.uuidString)-\(question)"
            if let cached = responseCache[cacheKey], !cached.isExpired {
                DebugLogger.shared.info("AICoachService", "Returning cached response for question")
                self.currentResponse = cached.response
                isLoading = false
                return cached.response
            }

            var requestBody: [String: Any] = ["patient_id": patientId.uuidString]
            if !question.isEmpty {
                requestBody["question"] = question
            }

            // ACP-1023: Include client-side context for faster personalization
            let clientContext = await gatherClientContext()
            if !clientContext.isEmpty {
                requestBody["client_context"] = clientContext
            }

            let bodyData = try JSONSerialization.data(withJSONObject: requestBody)

            let response: UnifiedCoachResponse = try await supabase.client.functions
                .invoke(
                    edgeFunctionUrl,
                    options: .init(body: bodyData)
                )

            // Cache the response
            responseCache[cacheKey] = CachedResponse(response: response, timestamp: Date())

            // Clean up expired cache entries periodically
            cleanExpiredCache()

            self.currentResponse = response
            DebugLogger.shared.info("AICoachService", "Received coaching response with \(response.insights.count) insights")

            isLoading = false
            return response
        } catch {
            self.error = error
            DebugLogger.shared.error("AICoachService", "Failed to get coaching response: \(error)")

            // For demo mode or when edge function is unavailable, return demo response
            let demoResponse = AICoachService.generateDemoResponse(for: question.isEmpty ? nil : question)
            self.currentResponse = demoResponse
            DebugLogger.shared.warning("AICoachService", "DEMO MODE FALLBACK: Using demo coaching response")

            isLoading = false
            return demoResponse
        }
    }

    /// Clears expired entries from the response cache
    private func cleanExpiredCache() {
        responseCache = responseCache.filter { !$0.value.isExpired }
    }

    /// Clears all cached responses (useful when user data changes significantly)
    func clearCache() {
        responseCache.removeAll()
        DebugLogger.shared.info("AICoachService", "Response cache cleared")
    }

    // MARK: - Proactive Insights

    /// Fetches proactive insights without a specific question
    /// Includes caching to avoid redundant network calls
    /// ACP-1023: Now passes client-side context for faster personalization
    func getProactiveInsights() async {
        guard hasAIConsent else {
            DebugLogger.shared.info("AICoachService", "AI consent not granted — skipping proactive insights")
            return
        }

        isLoading = true
        error = nil

        do {
            guard let patientId = try await getPatientId() else {
                error = AICoachError.noPatientId
                isLoading = false
                return
            }

            // Check cache for recent proactive insights
            let cacheKey = "\(patientId.uuidString)-proactive"
            if let cached = responseCache[cacheKey], !cached.isExpired {
                DebugLogger.shared.info("AICoachService", "Returning cached proactive insights")
                self.currentResponse = cached.response
                self.proactiveInsights = cached.response.insights
                isLoading = false
                return
            }

            var requestBody: [String: Any] = ["patient_id": patientId.uuidString]

            // ACP-1023: Include client-side context for faster personalization
            let clientContext = await gatherClientContext()
            if !clientContext.isEmpty {
                requestBody["client_context"] = clientContext
            }

            let bodyData = try JSONSerialization.data(withJSONObject: requestBody)

            let response: UnifiedCoachResponse = try await supabase.client.functions
                .invoke(
                    edgeFunctionUrl,
                    options: .init(body: bodyData)
                )

            // Cache the proactive response
            responseCache[cacheKey] = CachedResponse(response: response, timestamp: Date())
            cleanExpiredCache()

            self.currentResponse = response
            self.proactiveInsights = response.insights

            DebugLogger.shared.info("AICoachService", "Fetched \(response.insights.count) proactive insights")
        } catch {
            self.error = error
            DebugLogger.shared.error("AICoachService", "Failed to fetch proactive insights: \(error)")

            // For demo mode or when edge function is unavailable, use demo response
            let demoResponse = AICoachService.generateDemoResponse(for: nil)
            self.currentResponse = demoResponse
            self.proactiveInsights = demoResponse.insights
            DebugLogger.shared.warning("AICoachService", "DEMO MODE FALLBACK: Using demo proactive insights")
        }

        isLoading = false
    }

    // MARK: - Client Context (ACP-1023)

    /// Gathers lightweight client-side context to send with the request
    /// This helps the edge function personalize faster by avoiding redundant DB queries
    private func gatherClientContext() async -> [String: Any] {
        var context: [String: Any] = [:]

        do {
            // Fetch recent workout names for context
            struct WorkoutRow: Decodable {
                let name: String?
            }
            let recentWorkouts: [WorkoutRow] = try await supabase.client
                .from("manual_sessions")
                .select("name")
                .eq("completed", value: true)
                .order("completed_at", ascending: false)
                .limit(5)
                .execute()
                .value

            let workoutNames = recentWorkouts.compactMap { $0.name }
            if !workoutNames.isEmpty {
                context["recent_workout_names"] = workoutNames
            }

            // Fetch latest readiness score
            struct ReadinessRow: Decodable {
                let readinessScore: Int?
                enum CodingKeys: String, CodingKey {
                    case readinessScore = "readiness_score"
                }
            }
            let readiness: [ReadinessRow] = try await supabase.client
                .from("daily_readiness")
                .select("readiness_score")
                .order("date", ascending: false)
                .limit(1)
                .execute()
                .value

            if let score = readiness.first?.readinessScore {
                context["current_readiness_score"] = score
            }

            // Fetch active goal titles
            struct GoalRow: Decodable {
                let title: String
            }
            let goals: [GoalRow] = try await supabase.client
                .from("patient_goals")
                .select("title")
                .eq("status", value: "active")
                .limit(5)
                .execute()
                .value

            let goalTitles = goals.map { $0.title }
            if !goalTitles.isEmpty {
                context["active_goal_titles"] = goalTitles
            }
        } catch {
            DebugLogger.shared.warning("AICoachService", "Failed to gather client context: \(error.localizedDescription)")
            // Non-fatal: edge function will still fetch context server-side
        }

        return context
    }

    // MARK: - Helpers

    private func getPatientId() async throws -> UUID? {
        // Check for authenticated user first
        if let userId = supabase.client.auth.currentUser?.id {
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

            if let patientId = patients.first?.id {
                return patientId
            }
        }

        DebugLogger.shared.warning("AICoachService", "No authenticated user, cannot resolve patient ID")
        return nil
    }

    // MARK: - Demo Mode Fallback Response

    /// Generates a demo response when the edge function is unavailable or user is in demo mode
    static func generateDemoResponse(for question: String?) -> UnifiedCoachResponse {
        let insights: [CoachingInsight] = [
            CoachingInsight(
                category: .training,
                priority: .high,
                insight: "Your training consistency this week has been excellent with 4 sessions completed.",
                action: "Consider adding a mobility day to balance your strength work.",
                rationale: "Based on your session logs showing high-intensity strength training."
            ),
            CoachingInsight(
                category: .recovery,
                priority: .medium,
                insight: "Your sauna and cold plunge sessions are supporting your recovery well.",
                action: "Try contrast therapy for enhanced circulation benefits.",
                rationale: "You've completed 3 sauna and 3 cold plunge sessions this week."
            ),
            CoachingInsight(
                category: .nutrition,
                priority: .medium,
                insight: "Your supplement compliance is at 80% - good consistency!",
                action: "Set a reminder for your evening supplements to boost compliance.",
                rationale: "Evening supplements show lower compliance than morning doses."
            ),
            CoachingInsight(
                category: .labs,
                priority: .low,
                insight: "Your recent biomarkers show 4 markers needing attention.",
                action: "Focus on ferritin and magnesium supplementation based on your lab results.",
                rationale: "Latest lab panel from February shows these markers below optimal range."
            )
        ]

        return UnifiedCoachResponse(
            coachingId: UUID().uuidString,
            greeting: "Hey John! Here's your personalized coaching summary.",
            primaryMessage: question != nil
                ? "Based on your question and your health data, here are my recommendations..."
                : "Your health metrics are looking solid. Keep up the great work with your recovery protocols!",
            insights: insights,
            todayFocus: "Complete your 16:8 fast and log your evening supplements.",
            weeklyPriorities: [
                "Maintain 3+ recovery sessions",
                "Hit 90% supplement compliance",
                "Address ferritin with dietary iron sources"
            ],
            dataSummary: DataSummary(
                readiness: "Good - 78% readiness score",
                training: "4 sessions this week, strong adherence",
                recovery: "7 sessions logged, good variety",
                labs: "4 biomarkers need attention"
            ),
            proactiveAlerts: [
                "Your ferritin is below optimal for athletic performance",
                "Consider adding magnesium-rich foods to your diet"
            ],
            followUpQuestions: [
                "Would you like specific recommendations for improving ferritin levels?",
                "Want me to suggest recovery protocols for your training intensity?",
                "Should I analyze your fasting patterns for optimization?"
            ],
            disclaimer: "This is AI-generated coaching advice. Always consult with healthcare professionals for medical decisions."
        )
    }
}

// MARK: - Response Models

/// Response from unified AI coach endpoint
struct UnifiedCoachResponse: Codable {
    let coachingId: String
    let greeting: String
    let primaryMessage: String
    let insights: [CoachingInsight]
    let todayFocus: String
    let weeklyPriorities: [String]
    let dataSummary: DataSummary
    let proactiveAlerts: [String]
    let followUpQuestions: [String]
    let disclaimer: String

    enum CodingKeys: String, CodingKey {
        case coachingId = "coaching_id"
        case greeting
        case primaryMessage = "primary_message"
        case insights
        case todayFocus = "today_focus"
        case weeklyPriorities = "weekly_priorities"
        case dataSummary = "data_summary"
        case proactiveAlerts = "proactive_alerts"
        case followUpQuestions = "follow_up_questions"
        case disclaimer
    }
}

/// Individual coaching insight
struct CoachingInsight: Identifiable, Codable, Hashable {
    var id: String { "\(category.rawValue)-\(insight.prefix(20))" }
    let category: CoachingCategory
    let priority: CoachingPriority
    let insight: String
    let action: String
    let rationale: String
}

/// Category for coaching insights
enum CoachingCategory: String, Codable, CaseIterable {
    case training
    case recovery
    case nutrition
    case sleep
    case labs
    case general

    var displayName: String {
        switch self {
        case .training: return "Training"
        case .recovery: return "Recovery"
        case .nutrition: return "Nutrition"
        case .sleep: return "Sleep"
        case .labs: return "Labs"
        case .general: return "General"
        }
    }

    var icon: String {
        switch self {
        case .training: return "figure.run"
        case .recovery: return "heart.fill"
        case .nutrition: return "leaf.fill"
        case .sleep: return "moon.fill"
        case .labs: return "cross.case.fill"
        case .general: return "lightbulb.fill"
        }
    }

    var color: String {
        switch self {
        case .training: return "blue"
        case .recovery: return "pink"
        case .nutrition: return "green"
        case .sleep: return "purple"
        case .labs: return "red"
        case .general: return "orange"
        }
    }
}

/// Priority level for coaching insights
enum CoachingPriority: String, Codable {
    case high
    case medium
    case low

    var sortOrder: Int {
        switch self {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }
}

/// Summary of patient data
struct DataSummary: Codable, Hashable {
    let readiness: String
    let training: String
    let recovery: String
    let labs: String
}

// MARK: - Errors

enum AICoachError: LocalizedError {
    case noPatientId
    case invalidResponse
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .noPatientId:
            return "Unable to identify patient. Please ensure you are logged in."
        case .invalidResponse:
            return "Received an invalid response from the AI coach."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Chat Message Model

/// Message in the AI coach chat
struct AICoachMessage: Identifiable, Equatable {
    let id: UUID
    let role: AICoachMessageRole
    let content: String
    let timestamp: Date
    let insights: [CoachingInsight]?
    let suggestedQuestions: [String]?

    init(
        id: UUID = UUID(),
        role: AICoachMessageRole,
        content: String,
        timestamp: Date = Date(),
        insights: [CoachingInsight]? = nil,
        suggestedQuestions: [String]? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.insights = insights
        self.suggestedQuestions = suggestedQuestions
    }

    static func == (lhs: AICoachMessage, rhs: AICoachMessage) -> Bool {
        lhs.id == rhs.id
    }
}

/// Role of a chat message
enum AICoachMessageRole: String, Codable {
    case user
    case coach
    case system
}
