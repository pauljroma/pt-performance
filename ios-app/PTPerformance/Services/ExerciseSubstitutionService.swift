//
//  ExerciseSubstitutionService.swift
//  PTPerformance
//
//  Created by Swarm Agent (Substitution Integration)
//  Service for AI-powered exercise substitutions
//

import Foundation
import Supabase

/// Service for calling AI exercise substitution edge function
@MainActor
class ExerciseSubstitutionService: ObservableObject {
    private let client: PTSupabaseClient

    // MARK: - Published State

    @Published var isLoading = false
    @Published var substitutions: [ExerciseSubstitution] = []
    @Published var error: String?

    // MARK: - Initialization

    nonisolated init(client: PTSupabaseClient = .shared) {
        self.client = client
    }

    // MARK: - Get Substitutions

    /// Get AI exercise substitution suggestions
    func getSubstitutions(
        patientId: UUID,
        sessionId: UUID,
        scheduledDate: String,
        equipmentAvailable: [String],
        intensityPreference: String = "standard",
        readinessScore: Double? = nil
    ) async throws -> [ExerciseSubstitution] {
        isLoading = true
        error = nil
        substitutions = []

        defer { isLoading = false }

        // Prepare request matching edge function API
        var request: [String: Any] = [
            "patient_id": patientId.uuidString,
            "session_id": sessionId.uuidString,
            "scheduled_date": scheduledDate,
            "equipment_available": equipmentAvailable,
            "intensity_preference": intensityPreference
        ]

        if let readiness = readinessScore {
            request["readiness_score"] = readiness
        }

        DebugLogger.shared.info("SUBSTITUTION", "Calling ai-exercise-substitution edge function")
        DebugLogger.shared.info("SUBSTITUTION", "Request: \(request)")

        do {
            // Call edge function
            let bodyData = try JSONSerialization.data(withJSONObject: request)

            let responseDataRaw: Data = try await client.client.functions.invoke(
                "ai-exercise-substitution",
                options: FunctionInvokeOptions(body: bodyData)
            ) { data, _ in
                data
            }

            DebugLogger.shared.success("SUBSTITUTION", "Edge function returned successfully")
            DebugLogger.shared.info("SUBSTITUTION", "Response data size: \(responseDataRaw.count) bytes")

            // Log full raw response for debugging
            if let responseString = String(data: responseDataRaw, encoding: .utf8) {
                DebugLogger.shared.info("SUBSTITUTION", "Full raw response: \(responseString)")
            }

            // Decode response
            let decoder = JSONDecoder()
            // Don't use convertFromSnakeCase - we have explicit CodingKeys

            let responseData = try decoder.decode(SubstitutionResponse.self, from: responseDataRaw)

            // Convert edge function response to display models
            substitutions = responseData.patch.exerciseSubstitutions.map { item in
                ExerciseSubstitution(from: item, confidence: 85)
            }

            DebugLogger.shared.success("SUBSTITUTION", "Found \(substitutions.count) substitutions")
            DebugLogger.shared.info("SUBSTITUTION", "Recommendation ID: \(responseData.recommendationId)")
            DebugLogger.shared.info("SUBSTITUTION", "Rationale: \(responseData.rationale)")

            return substitutions

        } catch let functionsError as Supabase.FunctionsError {
            // Supabase edge function error - extract error body
            switch functionsError {
            case .httpError(let statusCode, let data):
                DebugLogger.shared.error("SUBSTITUTION", "Edge function HTTP error: \(statusCode)")
                if let errorString = String(data: data, encoding: .utf8) {
                    DebugLogger.shared.error("SUBSTITUTION", "Error body: \(errorString)")
                } else {
                    DebugLogger.shared.error("SUBSTITUTION", "Error body (raw): \(data.count) bytes, unable to decode as UTF-8")
                }
                let errorMessage = "Failed to get exercise substitutions: HTTP \(statusCode)"
                self.error = errorMessage
                throw functionsError
            case .relayError:
                DebugLogger.shared.error("SUBSTITUTION", "Edge function relay error")
                let errorMessage = "Failed to get exercise substitutions: Relay error"
                self.error = errorMessage
                throw functionsError
            }
        } catch {
            let errorMessage = "Failed to get exercise substitutions: \(error.localizedDescription)"
            DebugLogger.shared.error("SUBSTITUTION", errorMessage)
            DebugLogger.shared.error("SUBSTITUTION", "Error type: \(type(of: error))")
            DebugLogger.shared.error("SUBSTITUTION", "Full error: \(error)")
            self.error = errorMessage
            throw error
        }
    }

    /// Apply a substitution (calls apply-substitution edge function)
    func applySubstitution(
        sessionExerciseId: UUID,
        newExerciseTemplateId: UUID,
        reason: String
    ) async throws {
        let request: [String: Any] = [
            "session_exercise_id": sessionExerciseId.uuidString,
            "new_exercise_template_id": newExerciseTemplateId.uuidString,
            "reason": reason
        ]

        DebugLogger.shared.info("SUBSTITUTION", "Applying substitution")

        do {
            let bodyData = try JSONSerialization.data(withJSONObject: request)

            let _: Data = try await client.client.functions.invoke(
                "apply-substitution",
                options: FunctionInvokeOptions(body: bodyData)
            ) { data, _ in
                data
            }

            DebugLogger.shared.success("SUBSTITUTION", "Substitution applied successfully")

        } catch {
            let errorMessage = "Failed to apply substitution: \(error.localizedDescription)"
            DebugLogger.shared.error("SUBSTITUTION", errorMessage)
            throw error
        }
    }
}

// MARK: - Models

/// Response from ai-exercise-substitution edge function
struct SubstitutionResponse: Codable {
    let success: Bool
    let recommendationId: String
    let patch: SubstitutionPatch
    let rationale: String
    let status: String
    let tokensUsed: Int?
    let exercisesSubstituted: Int

    enum CodingKeys: String, CodingKey {
        case success
        case recommendationId = "recommendation_id"
        case patch
        case rationale
        case status
        case tokensUsed = "tokens_used"
        case exercisesSubstituted = "exercises_substituted"
    }
}

struct SubstitutionPatch: Codable {
    let exerciseSubstitutions: [ExerciseSubstitutionItem]
    let intensityAdjustments: [IntensityAdjustment]

    enum CodingKeys: String, CodingKey {
        case exerciseSubstitutions = "exercise_substitutions"
        case intensityAdjustments = "intensity_adjustments"
    }
}

struct ExerciseSubstitutionItem: Codable {
    let originalExerciseId: String
    let originalExerciseName: String
    let substituteExerciseId: String
    let substituteExerciseName: String
    let reason: String

    enum CodingKeys: String, CodingKey {
        case originalExerciseId = "original_exercise_id"
        case originalExerciseName = "original_exercise_name"
        case substituteExerciseId = "substitute_exercise_id"
        case substituteExerciseName = "substitute_exercise_name"
        case reason
    }
}

struct IntensityAdjustment: Codable {
    let exerciseId: String
    let exerciseName: String
    let originalSets: Int
    let adjustedSets: Int
    let originalReps: Int
    let adjustedReps: Int
    let originalRpe: Int?
    let adjustedRpe: Int?
    let reason: String

    enum CodingKeys: String, CodingKey {
        case exerciseId = "exercise_id"
        case exerciseName = "exercise_name"
        case originalSets = "original_sets"
        case adjustedSets = "adjusted_sets"
        case originalReps = "original_reps"
        case adjustedReps = "adjusted_reps"
        case originalRpe = "original_rpe"
        case adjustedRpe = "adjusted_rpe"
        case reason
    }
}

/// Display model for UI
struct ExerciseSubstitution: Identifiable {
    let id: UUID
    let exerciseName: String
    let rationale: String
    let confidence: Int
    let equipment: [String]?
    let musclesTargeted: [String]?

    init(from item: ExerciseSubstitutionItem, confidence: Int = 85) {
        self.id = UUID(uuidString: item.substituteExerciseId) ?? UUID()
        self.exerciseName = item.substituteExerciseName
        self.rationale = item.reason
        self.confidence = confidence
        self.equipment = nil
        self.musclesTargeted = nil
    }
}
