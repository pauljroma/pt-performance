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
    nonisolated(unsafe) private let client: PTSupabaseClient

    // MARK: - Published State

    @Published var isLoading = false
    @Published var substitutions: [ExerciseSubstitution] = []
    @Published var error: String?
    @Published var currentRecommendationId: String?  // BUILD 183: Store for apply-substitution

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

            // Decode response - edge function returns different structures
            let decoder = JSONDecoder()
            // Don't use convertFromSnakeCase - we have explicit CodingKeys

            // First, check if this is a "no substitutions needed" response
            if let noSubstitutionsResponse = try? decoder.decode(NoSubstitutionsResponse.self, from: responseDataRaw) {
                DebugLogger.shared.warning("SUBSTITUTION", "BUILD 176 DEBUG: Decoded as NoSubstitutionsResponse!")
                DebugLogger.shared.success("SUBSTITUTION", noSubstitutionsResponse.message)
                DebugLogger.shared.info("SUBSTITUTION", "Exercises checked: \(noSubstitutionsResponse.exercisesChecked)")

                // No substitutions needed - return empty array
                substitutions = []
                return substitutions
            }

            DebugLogger.shared.info("SUBSTITUTION", "BUILD 176 DEBUG: NoSubstitutionsResponse decode failed, trying SubstitutionResponse...")

            // Otherwise, decode as substitution response
            let responseData = try decoder.decode(SubstitutionResponse.self, from: responseDataRaw)

            // Convert edge function response to display models
            let mappedSubstitutions = responseData.patch.exerciseSubstitutions.map { item in
                ExerciseSubstitution(from: item, confidence: 85)
            }

            DebugLogger.shared.info("SUBSTITUTION", "BUILD 181 DEBUG: About to set substitutions array with \(mappedSubstitutions.count) items")

            // BUILD 181 FIX: Explicitly notify SwiftUI before updating
            // This ensures the view observes the change
            objectWillChange.send()
            substitutions = mappedSubstitutions

            // Also explicitly set isLoading to false here (before defer runs)
            isLoading = false

            // BUILD 183: Store recommendation ID for apply-substitution
            currentRecommendationId = responseData.recommendationId

            DebugLogger.shared.success("SUBSTITUTION", "BUILD 181 DEBUG: substitutions.count is now \(substitutions.count), isLoading=\(isLoading)")
            DebugLogger.shared.success("SUBSTITUTION", "Found \(substitutions.count) substitutions")
            DebugLogger.shared.info("SUBSTITUTION", "Recommendation ID: \(responseData.recommendationId) (stored for apply)")
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
                let errorMessage = "We couldn't get exercise alternatives right now. Please try again later."
                self.error = errorMessage
                throw functionsError
            case .relayError:
                DebugLogger.shared.error("SUBSTITUTION", "Edge function relay error")
                let errorMessage = "We couldn't connect to our servers. Please check your internet connection."
                self.error = errorMessage
                throw functionsError
            }
        } catch {
            let errorMessage = "We couldn't get exercise alternatives. Please check your connection and try again."
            DebugLogger.shared.error("SUBSTITUTION", errorMessage)
            DebugLogger.shared.error("SUBSTITUTION", "Error type: \(type(of: error))")
            DebugLogger.shared.error("SUBSTITUTION", "Full error: \(error)")
            self.error = errorMessage
            throw error
        }
    }

    /// Apply all substitutions from the current recommendation (calls apply-substitution edge function)
    /// BUILD 183 FIX: Edge function expects recommendation_id, not individual exercise IDs
    func applySubstitution() async throws {
        guard let recommendationId = currentRecommendationId else {
            throw NSError(domain: "ExerciseSubstitutionService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Please get exercise suggestions first before applying changes."
            ])
        }

        let request: [String: Any] = [
            "recommendation_id": recommendationId
        ]

        DebugLogger.shared.info("SUBSTITUTION", "Applying substitution with recommendation_id: \(recommendationId)")

        do {
            let bodyData = try JSONSerialization.data(withJSONObject: request)

            let _: Data = try await client.client.functions.invoke(
                "apply-substitution",
                options: FunctionInvokeOptions(body: bodyData)
            ) { data, _ in
                data
            }

            DebugLogger.shared.success("SUBSTITUTION", "Substitution applied successfully")

            // Clear state after successful apply
            currentRecommendationId = nil
            substitutions = []

        } catch {
            let errorMessage = "We couldn't apply the exercise change. Please try again."
            DebugLogger.shared.error("SUBSTITUTION", errorMessage)
            throw error
        }
    }
}

// MARK: - Models

/// Response when no substitutions are needed
struct NoSubstitutionsResponse: Codable {
    let message: String
    let exercisesChecked: Int

    enum CodingKeys: String, CodingKey {
        case message
        case exercisesChecked = "exercises_checked"
    }
}

/// Response from ai-exercise-substitution edge function when substitutions are available
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

// MARK: - Supporting Types for Exercise Instructions

struct TechniqueCues: Codable, Hashable {
    let setup: [String]
    let execution: [String]
    let breathing: [String]
}

struct FormCue: Codable, Hashable {
    let cue: String
    let timestamp: Int?
}

struct ExerciseSubstitutionItem: Codable {
    let originalExerciseId: String
    let originalExerciseName: String
    let substituteExerciseId: String
    let substituteExerciseName: String
    let reason: String

    // NEW: Video and instruction fields
    let videoUrl: String?
    let videoThumbnailUrl: String?
    let techniqueCues: TechniqueCues?
    let formCues: [FormCue]?
    let commonMistakes: String?
    let safetyNotes: String?
    let equipmentRequired: [String]?
    let musclesTargeted: [String]?
    let difficultyLevel: String?

    enum CodingKeys: String, CodingKey {
        case originalExerciseId = "original_exercise_id"
        case originalExerciseName = "original_exercise_name"
        case substituteExerciseId = "substitute_exercise_id"
        case substituteExerciseName = "substitute_exercise_name"
        case reason
        case videoUrl = "video_url"
        case videoThumbnailUrl = "video_thumbnail_url"
        case techniqueCues = "technique_cues"
        case formCues = "form_cues"
        case commonMistakes = "common_mistakes"
        case safetyNotes = "safety_notes"
        case equipmentRequired = "equipment_required"
        case musclesTargeted = "muscles_targeted"
        case difficultyLevel = "difficulty_level"
    }
}

struct IntensityAdjustment: Codable {
    let exerciseId: String
    let exerciseName: String
    let originalSets: Int?
    let adjustedSets: Int?
    let originalReps: Int?
    let adjustedReps: Int?
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

    // BUILD 184: Track which exercise this is a substitute FOR
    let originalExerciseId: UUID?
    let originalExerciseName: String?

    // Video and instruction fields
    let videoUrl: String?
    let videoThumbnailUrl: String?
    let techniqueCues: TechniqueCues?
    let formCues: [FormCue]?
    let commonMistakes: String?
    let safetyNotes: String?
    let difficultyLevel: String?

    init(from item: ExerciseSubstitutionItem, confidence: Int = 85) {
        self.id = UUID(uuidString: item.substituteExerciseId) ?? UUID()
        self.exerciseName = item.substituteExerciseName
        self.rationale = item.reason
        self.confidence = confidence
        self.equipment = item.equipmentRequired
        self.musclesTargeted = item.musclesTargeted
        self.originalExerciseId = UUID(uuidString: item.originalExerciseId)
        self.originalExerciseName = item.originalExerciseName
        self.videoUrl = item.videoUrl
        self.videoThumbnailUrl = item.videoThumbnailUrl
        self.techniqueCues = item.techniqueCues
        self.formCues = item.formCues
        self.commonMistakes = item.commonMistakes
        self.safetyNotes = item.safetyNotes
        self.difficultyLevel = item.difficultyLevel
    }
}
