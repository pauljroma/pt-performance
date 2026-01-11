//
//  NutritionService.swift
//  PTPerformance
//
//  Created by Swarm Agent (Nutrition Integration)
//  Service for AI-powered nutrition recommendations
//

import Foundation
import Supabase

/// Service for calling AI nutrition recommendation edge function
@MainActor
class NutritionService: ObservableObject {
    private let client: PTSupabaseClient

    // MARK: - Published State

    @Published var isLoading = false
    @Published var lastRecommendation: NutritionRecommendation?
    @Published var error: String?

    // MARK: - Initialization

    nonisolated init(client: PTSupabaseClient = .shared) {
        self.client = client
    }

    // MARK: - Get Recommendation

    /// Get AI nutrition recommendation based on current context
    func getRecommendation(
        patientId: UUID,
        timeOfDay: String,
        availableFoods: [String]? = nil,
        nextWorkoutTime: String? = nil,
        workoutType: String? = nil
    ) async throws -> NutritionRecommendation {
        isLoading = true
        error = nil

        defer { isLoading = false }

        // Prepare request
        var request: [String: Any] = [
            "patient_id": patientId.uuidString,
            "time_of_day": timeOfDay
        ]

        if let foods = availableFoods {
            request["available_foods"] = foods
        }

        if let workoutTime = nextWorkoutTime, let type = workoutType {
            request["context"] = [
                "next_workout_time": workoutTime,
                "workout_type": type
            ]
        }

        DebugLogger.shared.info("NUTRITION", "Calling ai-nutrition-recommendation edge function")
        DebugLogger.shared.info("NUTRITION", "Request: \(request)")

        do {
            // Call edge function
            let bodyData = try JSONSerialization.data(withJSONObject: request)

            let responseData: Data = try await client.client.functions.invoke(
                "ai-nutrition-recommendation",
                options: FunctionInvokeOptions(body: bodyData)
            ) { data, _ in
                data
            }

            DebugLogger.shared.success("NUTRITION", "Edge function returned successfully")
            DebugLogger.shared.info("NUTRITION", "Response data size: \(responseData.count) bytes")

            // Log raw response for debugging
            if let responseString = String(data: responseData, encoding: .utf8) {
                DebugLogger.shared.info("NUTRITION", "Raw response: \(responseString.prefix(500))")
            }

            // Decode response
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601

            let recommendation = try decoder.decode(NutritionRecommendation.self, from: responseData)

            lastRecommendation = recommendation

            DebugLogger.shared.success("NUTRITION", "Recommendation decoded: \(recommendation.recommendationText)")

            return recommendation

        } catch {
            let errorMessage = "Failed to get nutrition recommendation: \(error.localizedDescription)"
            DebugLogger.shared.error("NUTRITION", errorMessage)
            self.error = errorMessage
            throw error
        }
    }
}

// MARK: - Models

/// Response from ai-nutrition-recommendation edge function
struct NutritionRecommendation: Codable, Identifiable {
    let recommendationId: String
    let recommendationText: String
    let targetMacros: TargetMacros
    let reasoning: String
    let suggestedTiming: String?  // Optional - edge function may not return this

    var id: String { recommendationId }

    enum CodingKeys: String, CodingKey {
        case recommendationId = "recommendation_id"
        case recommendationText = "recommendation_text"
        case targetMacros = "target_macros"
        case reasoning
        case suggestedTiming = "suggested_timing"
    }
}

struct TargetMacros: Codable {
    let protein: Double
    let carbs: Double
    let fats: Double
    let calories: Double
}
