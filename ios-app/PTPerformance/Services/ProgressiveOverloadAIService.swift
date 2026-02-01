//
//  ProgressiveOverloadAIService.swift
//  PTPerformance
//
//  AI-Powered Progressive Overload Suggestions
//  Provides intelligent load progression recommendations based on training history,
//  readiness state, and fatigue levels.
//

import Foundation
import SwiftUI
import Supabase

// MARK: - Models

/// Type of progression recommendation
enum ProgressionType: String, Codable {
    case increase
    case hold
    case decrease
    case deload

    /// Color for UI display
    var color: Color {
        switch self {
        case .increase:
            return .green
        case .hold:
            return .blue
        case .decrease:
            return .orange
        case .deload:
            return .red
        }
    }

    /// SF Symbol icon name
    var icon: String {
        switch self {
        case .increase:
            return "arrow.up.circle.fill"
        case .hold:
            return "equal.circle.fill"
        case .decrease:
            return "arrow.down.circle.fill"
        case .deload:
            return "bed.double.circle.fill"
        }
    }

    /// Human-readable display text
    var displayText: String {
        switch self {
        case .increase:
            return "Increase Load"
        case .hold:
            return "Maintain Load"
        case .decrease:
            return "Reduce Load"
        case .deload:
            return "Deload Week"
        }
    }
}

/// AI-generated progression suggestion
struct ProgressionSuggestion: Codable, Equatable {
    let nextLoad: Double
    let nextReps: Int
    let confidence: Int
    let reasoning: String
    let progressionType: ProgressionType

    enum CodingKeys: String, CodingKey {
        case nextLoad = "next_load"
        case nextReps = "next_reps"
        case confidence
        case reasoning
        case progressionType = "progression_type"
    }

    /// Confidence level description
    var confidenceLevel: String {
        if confidence >= 80 {
            return "High"
        } else if confidence >= 60 {
            return "Moderate"
        } else {
            return "Low"
        }
    }

    /// Confidence color for UI
    var confidenceColor: Color {
        if confidence >= 80 {
            return .green
        } else if confidence >= 60 {
            return .orange
        } else {
            return .gray
        }
    }

    /// Formatted load change description
    func loadChangeDescription(from currentLoad: Double) -> String {
        let diff = nextLoad - currentLoad
        if abs(diff) < 0.1 {
            return "No change"
        } else if diff > 0 {
            return "+\(String(format: "%.1f", diff)) lbs"
        } else {
            return "\(String(format: "%.1f", diff)) lbs"
        }
    }
}

/// Analysis of training progression
struct ProgressionAnalysis: Codable, Equatable {
    let trend: String
    let estimated1RM: Double
    let sessionsAtWeight: Int
    let fatigueImpact: String

    enum CodingKeys: String, CodingKey {
        case trend
        case estimated1RM = "estimated_1rm"
        case sessionsAtWeight = "sessions_at_weight"
        case fatigueImpact = "fatigue_impact"
    }

    /// Trend as enum for easier handling
    var trendType: TrendType {
        TrendType(rawValue: trend) ?? .improving
    }

    /// Formatted 1RM string
    var estimated1RMFormatted: String {
        "\(String(format: "%.1f", estimated1RM)) lbs"
    }
}

/// Training trend direction
enum TrendType: String {
    case improving
    case plateaued
    case declining

    var color: Color {
        switch self {
        case .improving:
            return .green
        case .plateaued:
            return .orange
        case .declining:
            return .red
        }
    }

    var icon: String {
        switch self {
        case .improving:
            return "arrow.up.right"
        case .plateaued:
            return "arrow.right"
        case .declining:
            return "arrow.down.right"
        }
    }

    var displayText: String {
        switch self {
        case .improving:
            return "Improving"
        case .plateaued:
            return "Plateaued"
        case .declining:
            return "Declining"
        }
    }
}

// MARK: - Response Models

/// Full response from the edge function
private struct ProgressiveOverloadResponse: Codable {
    let suggestion: ProgressionSuggestion
    let analysis: ProgressionAnalysis
}

/// Error response from edge function
private struct ProgressiveOverloadErrorResponse: Codable {
    let error: String?
    let details: String?
}

// MARK: - Service

/// Service for fetching AI-powered progressive overload suggestions
@MainActor
class ProgressiveOverloadAIService: ObservableObject {
    nonisolated(unsafe) private let client: PTSupabaseClient

    // MARK: - Published State

    @Published var suggestion: ProgressionSuggestion?
    @Published var analysis: ProgressionAnalysis?
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Initialization

    nonisolated init(client: PTSupabaseClient = .shared) {
        self.client = client
    }

    // MARK: - Public Methods

    /// Get AI-powered progression suggestion for an exercise
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - exerciseTemplateId: The exercise template UUID
    ///   - currentLoad: Current load being used (in lbs)
    ///   - currentReps: Current rep count
    ///   - recentRPE: Most recent RPE rating (0-10)
    /// - Returns: The progression suggestion
    @discardableResult
    func getSuggestion(
        patientId: UUID,
        exerciseTemplateId: UUID,
        currentLoad: Double,
        currentReps: Int,
        recentRPE: Double
    ) async throws -> ProgressionSuggestion {
        isLoading = true
        error = nil
        suggestion = nil
        analysis = nil

        defer { isLoading = false }

        // Build request payload
        let request: [String: Any] = [
            "patient_id": patientId.uuidString,
            "exercise_template_id": exerciseTemplateId.uuidString,
            "current_load": currentLoad,
            "current_reps": currentReps,
            "recent_rpe": recentRPE
        ]

        DebugLogger.shared.info("PROGRESSION_AI", "Calling ai-progressive-overload edge function")
        DebugLogger.shared.info("PROGRESSION_AI", "Request: \(request)")

        do {
            // Serialize request
            let bodyData = try JSONSerialization.data(withJSONObject: request)

            // Call edge function
            let responseDataRaw: Data = try await client.client.functions.invoke(
                "ai-progressive-overload",
                options: FunctionInvokeOptions(body: bodyData)
            ) { data, _ in
                data
            }

            DebugLogger.shared.success("PROGRESSION_AI", "Edge function returned successfully")

            // Log raw response for debugging
            if let responseString = String(data: responseDataRaw, encoding: .utf8) {
                DebugLogger.shared.info("PROGRESSION_AI", "Raw response: \(responseString)")
            }

            // Decode response
            let decoder = JSONDecoder()

            // Check for error response first
            if let errorResponse = try? decoder.decode(ProgressiveOverloadErrorResponse.self, from: responseDataRaw),
               let errorMessage = errorResponse.error {
                DebugLogger.shared.error("PROGRESSION_AI", "Error from edge function: \(errorMessage)")
                self.error = errorMessage
                throw ProgressionError.serverError(errorMessage)
            }

            // Decode successful response
            let response = try decoder.decode(ProgressiveOverloadResponse.self, from: responseDataRaw)

            // Update published state
            self.suggestion = response.suggestion
            self.analysis = response.analysis

            DebugLogger.shared.success("PROGRESSION_AI", "Suggestion received: \(response.suggestion.progressionType.rawValue)")
            DebugLogger.shared.info("PROGRESSION_AI", "Next load: \(response.suggestion.nextLoad), confidence: \(response.suggestion.confidence)%")

            return response.suggestion

        } catch let functionsError as Supabase.FunctionsError {
            handleFunctionsError(functionsError)
            throw functionsError
        } catch let progressionError as ProgressionError {
            throw progressionError
        } catch {
            let errorMessage = "Failed to get progression suggestion. Please try again."
            DebugLogger.shared.error("PROGRESSION_AI", "Error: \(error)")
            self.error = errorMessage
            throw error
        }
    }

    /// Clear the current suggestion and reset state
    func clearSuggestion() {
        suggestion = nil
        analysis = nil
        error = nil
        isLoading = false
    }

    // MARK: - Private Methods

    private func handleFunctionsError(_ error: Supabase.FunctionsError) {
        switch error {
        case .httpError(let statusCode, let data):
            DebugLogger.shared.error("PROGRESSION_AI", "HTTP error \(statusCode)")
            if let errorString = String(data: data, encoding: .utf8) {
                DebugLogger.shared.error("PROGRESSION_AI", "Error body: \(errorString)")
            }
            self.error = "Server error occurred. Please try again later."
        case .relayError:
            DebugLogger.shared.error("PROGRESSION_AI", "Relay error - connection issue")
            self.error = "Connection failed. Please check your internet connection."
        }
    }
}

// MARK: - Errors

enum ProgressionError: LocalizedError {
    case serverError(String)
    case invalidResponse
    case noData

    var errorDescription: String? {
        switch self {
        case .serverError(let message):
            return message
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .noData:
            return "No progression data available."
        }
    }
}

// MARK: - Preview Support

#if DEBUG
extension ProgressiveOverloadAIService {
    /// Create a mock service with sample data for previews
    static var preview: ProgressiveOverloadAIService {
        let service = ProgressiveOverloadAIService()
        service.suggestion = ProgressionSuggestion(
            nextLoad: 137.5,
            nextReps: 8,
            confidence: 82,
            reasoning: "Based on consistent RPE of 7.5 across 3 sessions at 135 lbs, a 2.5 lb increase is appropriate for continued progressive overload.",
            progressionType: .increase
        )
        service.analysis = ProgressionAnalysis(
            trend: "improving",
            estimated1RM: 172.5,
            sessionsAtWeight: 3,
            fatigueImpact: "low - good for progression"
        )
        return service
    }

    /// Create a mock deload suggestion for previews
    static var previewDeload: ProgressiveOverloadAIService {
        let service = ProgressiveOverloadAIService()
        service.suggestion = ProgressionSuggestion(
            nextLoad: 115,
            nextReps: 6,
            confidence: 88,
            reasoning: "High fatigue detected with declining readiness scores. A deload week with 15% load reduction is recommended to support recovery.",
            progressionType: .deload
        )
        service.analysis = ProgressionAnalysis(
            trend: "declining",
            estimated1RM: 155,
            sessionsAtWeight: 5,
            fatigueImpact: "high - consider deload"
        )
        return service
    }
}
#endif
