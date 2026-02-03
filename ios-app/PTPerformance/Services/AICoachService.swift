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

    private init() {}

    // MARK: - Ask Coach

    /// Sends a question to the AI coach and receives a contextual response
    func askCoach(question: String) async -> UnifiedCoachResponse? {
        isLoading = true
        error = nil

        do {
            guard let patientId = try await getPatientId() else {
                error = AICoachError.noPatientId
                isLoading = false
                return nil
            }

            var requestBody: [String: Any] = ["patient_id": patientId.uuidString]
            if !question.isEmpty {
                requestBody["question"] = question
            }

            let bodyData = try JSONSerialization.data(withJSONObject: requestBody)

            let response: UnifiedCoachResponse = try await supabase.client.functions
                .invoke(
                    edgeFunctionUrl,
                    options: .init(body: bodyData)
                )

            self.currentResponse = response
            DebugLogger.shared.info("AICoachService", "Received coaching response with \(response.insights.count) insights")

            isLoading = false
            return response
        } catch {
            self.error = error
            DebugLogger.shared.error("AICoachService", "Failed to get coaching response: \(error)")
            isLoading = false
            return nil
        }
    }

    // MARK: - Proactive Insights

    /// Fetches proactive insights without a specific question
    func getProactiveInsights() async {
        isLoading = true
        error = nil

        do {
            guard let patientId = try await getPatientId() else {
                error = AICoachError.noPatientId
                isLoading = false
                return
            }

            let requestBody: [String: Any] = ["patient_id": patientId.uuidString]
            let bodyData = try JSONSerialization.data(withJSONObject: requestBody)

            let response: UnifiedCoachResponse = try await supabase.client.functions
                .invoke(
                    edgeFunctionUrl,
                    options: .init(body: bodyData)
                )

            self.currentResponse = response
            self.proactiveInsights = response.insights

            DebugLogger.shared.info("AICoachService", "Fetched \(response.insights.count) proactive insights")
        } catch {
            self.error = error
            DebugLogger.shared.error("AICoachService", "Failed to fetch proactive insights: \(error)")
        }

        isLoading = false
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
