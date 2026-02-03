//
//  ExerciseSubstitutionService.swift
//  PTPerformance
//
//  Created by Swarm Agent (Substitution Integration)
//  Service for AI-powered exercise substitutions
//

import Foundation
import Supabase

/// Service for AI-powered exercise substitution recommendations
///
/// Calls the `ai-exercise-substitution` edge function to generate intelligent
/// exercise alternatives based on equipment availability, patient readiness,
/// and intensity preferences. Also handles applying approved substitutions.
///
/// ## Usage Example
/// ```swift
/// let service = ExerciseSubstitutionService()
///
/// // Get substitution suggestions
/// let subs = try await service.getSubstitutions(
///     patientId: patientId,
///     sessionId: sessionId,
///     scheduledDate: "2025-01-15",
///     equipmentAvailable: ["dumbbells", "bench"]
/// )
///
/// // Review and apply if approved
/// if !subs.isEmpty {
///     try await service.applySubstitution()
/// }
/// ```
@MainActor
class ExerciseSubstitutionService: ObservableObject {
    nonisolated(unsafe) private let client: PTSupabaseClient

    // MARK: - Published State

    /// Indicates whether a request is in progress
    @Published var isLoading = false

    /// Array of suggested exercise substitutions
    @Published var substitutions: [ExerciseSubstitution] = []

    /// Error message from the last failed request
    @Published var error: String?

    /// The recommendation ID for the current substitution batch (used when applying)
    @Published var currentRecommendationId: String?

    // MARK: - Initialization

    nonisolated init(client: PTSupabaseClient = .shared) {
        self.client = client
    }

    // MARK: - Get Substitutions

    /// Gets AI-powered exercise substitution suggestions
    ///
    /// Analyzes the scheduled workout session and generates intelligent
    /// substitutions based on equipment availability, readiness scores,
    /// and intensity preferences.
    ///
    /// - Parameters:
    ///   - patientId: The patient's unique identifier
    ///   - sessionId: The workout session ID to analyze
    ///   - scheduledDate: The scheduled date in "yyyy-MM-dd" format
    ///   - equipmentAvailable: Array of available equipment names
    ///   - intensityPreference: Intensity level ("light", "standard", "intense")
    ///   - readinessScore: Optional readiness score (0-100) to factor in
    ///
    /// - Returns: Array of `ExerciseSubstitution` suggestions, empty if none needed
    ///
    /// - Throws: `FunctionsError` if the edge function fails
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

        #if DEBUG
        DebugLogger.shared.info("SUBSTITUTION", "Calling ai-exercise-substitution edge function")
        DebugLogger.shared.info("SUBSTITUTION", "Request: \(request)")
        #endif

        do {
            // Call edge function
            let bodyData = try JSONSerialization.data(withJSONObject: request)

            let responseDataRaw: Data = try await client.client.functions.invoke(
                "ai-exercise-substitution",
                options: FunctionInvokeOptions(body: bodyData)
            ) { data, _ in
                data
            }

            #if DEBUG
            DebugLogger.shared.success("SUBSTITUTION", "Edge function returned successfully")
            DebugLogger.shared.info("SUBSTITUTION", "Response data size: \(responseDataRaw.count) bytes")

            // Log full raw response for debugging
            if let responseString = String(data: responseDataRaw, encoding: .utf8) {
                DebugLogger.shared.info("SUBSTITUTION", "Full raw response: \(responseString)")
            }
            #endif

            // Decode response - edge function returns different structures
            let decoder = JSONDecoder()
            // Don't use convertFromSnakeCase - we have explicit CodingKeys

            // First, check if this is a "no substitutions needed" response
            if let noSubstitutionsResponse = try? decoder.decode(NoSubstitutionsResponse.self, from: responseDataRaw) {
                #if DEBUG
                DebugLogger.shared.success("SUBSTITUTION", noSubstitutionsResponse.message)
                DebugLogger.shared.info("SUBSTITUTION", "Exercises checked: \(noSubstitutionsResponse.exercisesChecked)")
                #endif

                // No substitutions needed - return empty array
                substitutions = []
                return substitutions
            }

            // Otherwise, decode as substitution response
            let responseData = try decoder.decode(SubstitutionResponse.self, from: responseDataRaw)

            // Convert edge function response to display models
            let mappedSubstitutions = responseData.patch.exerciseSubstitutions.map { item in
                ExerciseSubstitution(from: item, confidence: 85)
            }

            substitutions = mappedSubstitutions
            currentRecommendationId = responseData.recommendationId

            #if DEBUG
            DebugLogger.shared.success("SUBSTITUTION", "Found \(substitutions.count) substitutions")
            DebugLogger.shared.info("SUBSTITUTION", "Recommendation ID: \(responseData.recommendationId)")
            DebugLogger.shared.info("SUBSTITUTION", "Rationale: \(responseData.rationale)")
            #endif

            return substitutions

        } catch let functionsError as Supabase.FunctionsError {
            // Supabase edge function error - extract error body
            switch functionsError {
            case .httpError(let statusCode, let data):
                #if DEBUG
                DebugLogger.shared.error("SUBSTITUTION", "Edge function HTTP error: \(statusCode)")
                if let errorString = String(data: data, encoding: .utf8) {
                    DebugLogger.shared.error("SUBSTITUTION", "Error body: \(errorString)")
                } else {
                    DebugLogger.shared.error("SUBSTITUTION", "Error body (raw): \(data.count) bytes, unable to decode as UTF-8")
                }
                #endif
                let errorMessage = "We couldn't get exercise alternatives right now. Please try again later."
                self.error = errorMessage
                throw functionsError
            case .relayError:
                #if DEBUG
                DebugLogger.shared.error("SUBSTITUTION", "Edge function relay error")
                #endif
                let errorMessage = "We couldn't connect to our servers. Please check your internet connection."
                self.error = errorMessage
                throw functionsError
            }
        } catch {
            let errorMessage = "We couldn't get exercise alternatives. Please check your connection and try again."
            #if DEBUG
            DebugLogger.shared.error("SUBSTITUTION", errorMessage)
            DebugLogger.shared.error("SUBSTITUTION", "Error type: \(type(of: error))")
            DebugLogger.shared.error("SUBSTITUTION", "Full error: \(error)")
            #endif
            self.error = errorMessage
            throw error
        }
    }

    /// Applies all substitutions from the current recommendation
    ///
    /// Calls the `apply-substitution` edge function to permanently apply the
    /// suggested substitutions to the workout session. This updates the session
    /// exercises in the database.
    ///
    /// - Throws: `NSError` if no recommendation ID is available (call `getSubstitutions` first),
    ///           or if the edge function fails
    ///
    /// - Important: After calling this method, the session should be refreshed
    ///              to display the updated exercises
    ///
    /// - Note: Clears `currentRecommendationId` and `substitutions` on success
    func applySubstitution() async throws {
        guard let recommendationId = currentRecommendationId else {
            throw NSError(domain: "ExerciseSubstitutionService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Please get exercise suggestions first before applying changes."
            ])
        }

        let request: [String: Any] = [
            "recommendation_id": recommendationId
        ]

        #if DEBUG
        DebugLogger.shared.info("SUBSTITUTION", "Applying substitution with recommendation_id: \(recommendationId)")
        #endif

        do {
            let bodyData = try JSONSerialization.data(withJSONObject: request)

            let _: Data = try await client.client.functions.invoke(
                "apply-substitution",
                options: FunctionInvokeOptions(body: bodyData)
            ) { data, _ in
                data
            }

            #if DEBUG
            DebugLogger.shared.success("SUBSTITUTION", "Substitution applied successfully")
            #endif

            // Clear state after successful apply
            currentRecommendationId = nil
            substitutions = []

        } catch {
            let errorMessage = "We couldn't apply the exercise change. Please try again."
            #if DEBUG
            DebugLogger.shared.error("SUBSTITUTION", errorMessage)
            #endif
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
