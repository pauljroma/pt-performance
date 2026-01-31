//
//  AIWorkoutRecommendationService.swift
//  PTPerformance
//
//  Build 352: AI Quick Pick Feature
//  Service for calling AI workout recommendation edge function
//

import Foundation
import Supabase

/// Service for calling AI workout recommendation edge function
@MainActor
class AIWorkoutRecommendationService: ObservableObject {
    nonisolated(unsafe) private let client: PTSupabaseClient

    // MARK: - Published State

    @Published var isLoading = false
    @Published var recommendations: [AIWorkoutRecommendation] = []
    @Published var reasoning: String?
    @Published var contextSummary: RecommendationContext?
    @Published var error: String?
    @Published var currentRecommendationId: String?
    @Published var isCached = false

    // MARK: - Initialization

    nonisolated init(client: PTSupabaseClient = .shared) {
        self.client = client
    }

    // MARK: - Get Recommendations

    /// Get AI workout recommendations based on patient context
    func getRecommendations(
        patientId: UUID,
        categoryPreferences: [String]? = nil,
        durationPreference: Int? = nil,
        timeOfDay: String? = nil
    ) async throws -> [AIWorkoutRecommendation] {
        isLoading = true
        error = nil
        recommendations = []
        reasoning = nil
        contextSummary = nil
        isCached = false

        defer { isLoading = false }

        // Prepare request matching edge function API
        var request: [String: Any] = [
            "patient_id": patientId.uuidString
        ]

        if let categories = categoryPreferences, !categories.isEmpty {
            request["category_preferences"] = categories
        }

        if let duration = durationPreference {
            request["duration_preference"] = duration
        }

        if let time = timeOfDay {
            request["time_of_day"] = time
        }

        DebugLogger.shared.info("AI_WORKOUT", "Calling ai-workout-recommendation edge function")
        DebugLogger.shared.info("AI_WORKOUT", "Request: \(request)")

        do {
            // Call edge function
            let bodyData = try JSONSerialization.data(withJSONObject: request)

            let responseDataRaw: Data = try await client.client.functions.invoke(
                "ai-workout-recommendation",
                options: FunctionInvokeOptions(body: bodyData)
            ) { data, _ in
                data
            }

            DebugLogger.shared.success("AI_WORKOUT", "Edge function returned successfully")
            DebugLogger.shared.info("AI_WORKOUT", "Response data size: \(responseDataRaw.count) bytes")

            // Log full raw response for debugging
            if let responseString = String(data: responseDataRaw, encoding: .utf8) {
                DebugLogger.shared.info("AI_WORKOUT", "Full raw response: \(responseString)")
            }

            // Decode response
            let decoder = JSONDecoder()

            // First check for error response
            if let errorResponse = try? decoder.decode(WorkoutRecommendationErrorResponse.self, from: responseDataRaw),
               errorResponse.error != nil {
                DebugLogger.shared.warning("AI_WORKOUT", "No recommendations: \(errorResponse.error ?? "Unknown error")")

                // Store context even on error
                if let context = errorResponse.contextSummary {
                    self.contextSummary = RecommendationContext(from: context)
                }

                recommendations = []
                reasoning = errorResponse.reasoning
                return recommendations
            }

            // Decode successful response
            let responseData = try decoder.decode(WorkoutRecommendationResponse.self, from: responseDataRaw)

            // Convert edge function response to display models
            let mappedRecommendations = responseData.recommendations.map { item in
                AIWorkoutRecommendation(from: item)
            }

            DebugLogger.shared.info("AI_WORKOUT", "About to set recommendations array with \(mappedRecommendations.count) items")

            // Explicitly notify SwiftUI before updating
            objectWillChange.send()
            recommendations = mappedRecommendations
            reasoning = responseData.reasoning
            contextSummary = RecommendationContext(from: responseData.contextSummary)
            currentRecommendationId = responseData.recommendationId
            isCached = responseData.cached ?? false

            // Explicitly set isLoading to false here (before defer runs)
            isLoading = false

            DebugLogger.shared.success("AI_WORKOUT", "Found \(recommendations.count) recommendations")
            DebugLogger.shared.info("AI_WORKOUT", "Recommendation ID: \(responseData.recommendationId)")
            DebugLogger.shared.info("AI_WORKOUT", "Reasoning: \(responseData.reasoning)")
            DebugLogger.shared.info("AI_WORKOUT", "Cached: \(responseData.cached ?? false)")

            return recommendations

        } catch let functionsError as Supabase.FunctionsError {
            // Supabase edge function error - extract error body
            switch functionsError {
            case .httpError(let statusCode, let data):
                DebugLogger.shared.error("AI_WORKOUT", "Edge function HTTP error: \(statusCode)")
                if let errorString = String(data: data, encoding: .utf8) {
                    DebugLogger.shared.error("AI_WORKOUT", "Error body: \(errorString)")
                }
                let errorMessage = "We couldn't get workout recommendations right now. Please try again later."
                self.error = errorMessage
                throw functionsError
            case .relayError:
                DebugLogger.shared.error("AI_WORKOUT", "Edge function relay error")
                let errorMessage = "We couldn't connect to our servers. Please check your internet connection."
                self.error = errorMessage
                throw functionsError
            }
        } catch {
            let errorMessage = "We couldn't get workout recommendations. Please check your connection and try again."
            DebugLogger.shared.error("AI_WORKOUT", errorMessage)
            DebugLogger.shared.error("AI_WORKOUT", "Error type: \(type(of: error))")
            DebugLogger.shared.error("AI_WORKOUT", "Full error: \(error)")
            self.error = errorMessage
            throw error
        }
    }

    /// Mark a recommendation as selected (for analytics)
    func markAsSelected(templateId: UUID) async {
        guard let recommendationId = currentRecommendationId else {
            DebugLogger.shared.warning("AI_WORKOUT", "No recommendation ID to mark as selected")
            return
        }

        DebugLogger.shared.info("AI_WORKOUT", "Marking template \(templateId) as selected for recommendation \(recommendationId)")

        do {
            let updateData = RecommendationUpdateData(
                wasSelected: true,
                selectedTemplateId: templateId.uuidString
            )

            try await client.client.from("workout_recommendations")
                .update(updateData)
                .eq("id", value: recommendationId)
                .execute()

            DebugLogger.shared.success("AI_WORKOUT", "Marked recommendation as selected")
        } catch {
            DebugLogger.shared.error("AI_WORKOUT", "Failed to mark as selected: \(error)")
            // Don't throw - this is analytics, not critical
        }
    }

    /// Clear current recommendations
    func clearRecommendations() {
        recommendations = []
        reasoning = nil
        contextSummary = nil
        currentRecommendationId = nil
        isCached = false
        error = nil
    }
}

// MARK: - Update Models

/// Data for updating recommendation selection
private struct RecommendationUpdateData: Encodable {
    let wasSelected: Bool
    let selectedTemplateId: String

    enum CodingKeys: String, CodingKey {
        case wasSelected = "was_selected"
        case selectedTemplateId = "selected_template_id"
    }
}

// MARK: - Response Models

/// Response from ai-workout-recommendation edge function
struct WorkoutRecommendationResponse: Codable {
    let recommendationId: String
    let recommendations: [WorkoutRecommendationItem]
    let reasoning: String
    let contextSummary: WorkoutRecommendationContextSummary
    let cached: Bool?

    enum CodingKeys: String, CodingKey {
        case recommendationId = "recommendation_id"
        case recommendations
        case reasoning
        case contextSummary = "context_summary"
        case cached
    }
}

/// Error response from edge function
struct WorkoutRecommendationErrorResponse: Codable {
    let error: String?
    let recommendationId: String?
    let recommendations: [WorkoutRecommendationItem]?
    let reasoning: String?
    let contextSummary: WorkoutRecommendationContextSummary?

    enum CodingKeys: String, CodingKey {
        case error
        case recommendationId = "recommendation_id"
        case recommendations
        case reasoning
        case contextSummary = "context_summary"
    }
}

/// Individual recommendation item from edge function
struct WorkoutRecommendationItem: Codable {
    let templateId: String
    let templateName: String
    let matchScore: Int
    let reasoning: String
    let category: String?
    let durationMinutes: Int?
    let difficulty: String?

    enum CodingKeys: String, CodingKey {
        case templateId = "template_id"
        case templateName = "template_name"
        case matchScore = "match_score"
        case reasoning
        case category
        case durationMinutes = "duration_minutes"
        case difficulty
    }
}

/// Context summary from edge function
struct WorkoutRecommendationContextSummary: Codable {
    let readinessBand: String?
    let readinessScore: Double?
    let recentWorkoutCount: Int
    let activeGoals: [String]

    enum CodingKeys: String, CodingKey {
        case readinessBand = "readiness_band"
        case readinessScore = "readiness_score"
        case recentWorkoutCount = "recent_workout_count"
        case activeGoals = "active_goals"
    }
}

// MARK: - Display Models

/// Display model for recommendation context
struct RecommendationContext {
    let readinessBand: ReadinessBand?
    let readinessScore: Double?
    let recentWorkoutCount: Int
    let activeGoals: [String]

    init(from response: WorkoutRecommendationContextSummary) {
        self.readinessScore = response.readinessScore
        self.recentWorkoutCount = response.recentWorkoutCount
        self.activeGoals = response.activeGoals

        // Convert string to ReadinessBand enum
        if let bandString = response.readinessBand {
            self.readinessBand = ReadinessBand(rawValue: bandString)
        } else {
            self.readinessBand = nil
        }
    }
}

/// Display model for AI workout recommendation
struct AIWorkoutRecommendation: Identifiable, Equatable {
    let id: UUID
    let templateId: UUID
    let templateName: String
    let matchScore: Int
    let reasoning: String
    let category: String?
    let durationMinutes: Int?
    let difficulty: String?

    init(from item: WorkoutRecommendationItem) {
        self.id = UUID()  // Unique ID for SwiftUI list
        self.templateId = UUID(uuidString: item.templateId) ?? UUID()
        self.templateName = item.templateName
        self.matchScore = item.matchScore
        self.reasoning = item.reasoning
        self.category = item.category
        self.durationMinutes = item.durationMinutes
        self.difficulty = item.difficulty
    }

    /// Color for match score badge
    var matchScoreColor: String {
        if matchScore >= 80 {
            return "green"
        } else if matchScore >= 60 {
            return "orange"
        } else {
            return "gray"
        }
    }

    /// Formatted duration text
    var durationText: String {
        guard let minutes = durationMinutes else { return "" }
        return "\(minutes) min"
    }

    /// Formatted category text
    var categoryText: String {
        guard let cat = category else { return "General" }
        return cat.capitalized
    }

    /// Formatted difficulty text
    var difficultyText: String {
        guard let diff = difficulty else { return "Moderate" }
        return diff.capitalized
    }
}
