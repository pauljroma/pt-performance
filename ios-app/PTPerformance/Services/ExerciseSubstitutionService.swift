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
        exerciseId: UUID,
        exerciseName: String,
        reason: String,
        patientId: UUID
    ) async throws -> [ExerciseSubstitution] {
        isLoading = true
        error = nil
        substitutions = []

        defer { isLoading = false }

        // Prepare request
        let request: [String: Any] = [
            "exercise_id": exerciseId.uuidString,
            "exercise_name": exerciseName,
            "reason": reason,
            "patient_id": patientId.uuidString
        ]

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

            // Decode response
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            let responseData = try decoder.decode(SubstitutionResponse.self, from: responseDataRaw)

            substitutions = responseData.substitutions

            DebugLogger.shared.success("SUBSTITUTION", "Found \(substitutions.count) substitutions")

            return substitutions

        } catch {
            let errorMessage = "Failed to get exercise substitutions: \(error.localizedDescription)"
            DebugLogger.shared.error("SUBSTITUTION", errorMessage)
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

struct SubstitutionResponse: Codable {
    let substitutions: [ExerciseSubstitution]
}

struct ExerciseSubstitution: Codable, Identifiable {
    let exerciseTemplateId: UUID
    let exerciseName: String
    let rationale: String
    let confidence: Int
    let equipment: [String]?
    let musclesTargeted: [String]?

    var id: UUID { exerciseTemplateId }

    enum CodingKeys: String, CodingKey {
        case exerciseTemplateId = "exercise_template_id"
        case exerciseName = "exercise_name"
        case rationale
        case confidence
        case equipment
        case musclesTargeted = "muscles_targeted"
    }
}
