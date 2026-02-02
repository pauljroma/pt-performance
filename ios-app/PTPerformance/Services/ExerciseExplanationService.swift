//
//  ExerciseExplanationService.swift
//  PTPerformance
//
//  Created by Content & Polish Sprint Agent 4
//  Service for fetching "Why This Exercise" educational content
//

import Foundation
import Supabase

/// Service for fetching exercise explanation content from the database
/// Provides context for why exercises are included in programs
@MainActor
class ExerciseExplanationService: ObservableObject {

    // MARK: - Singleton

    static let shared = ExerciseExplanationService()

    // MARK: - Published State

    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Dependencies

    private let client = PTSupabaseClient.shared
    private let errorLogger = ErrorLogger.shared

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Fetch explanation for an exercise, optionally in context of a program
    /// - Parameters:
    ///   - exerciseTemplateId: The UUID of the exercise template
    ///   - programId: Optional program UUID for program-specific explanations
    /// - Returns: The exercise explanation if found
    func fetchExplanation(
        exerciseTemplateId: UUID,
        programId: UUID? = nil
    ) async throws -> ExerciseExplanation? {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let query = client.client
                .from("exercise_explanations")
                .select()
                .eq("exercise_template_id", value: exerciseTemplateId.uuidString)

            if let programId = programId {
                // First try to find program-specific explanation
                let programExplanations: [ExerciseExplanation] = try await query
                    .eq("program_id", value: programId.uuidString)
                    .execute()
                    .value

                if let programExplanation = programExplanations.first {
                    return programExplanation
                }

                // Fall back to generic explanation (no program_id)
                let genericExplanations: [ExerciseExplanation] = try await client.client
                    .from("exercise_explanations")
                    .select()
                    .eq("exercise_template_id", value: exerciseTemplateId.uuidString)
                    .is("program_id", value: nil)
                    .execute()
                    .value

                return genericExplanations.first
            } else {
                // No program specified, get generic explanation
                let explanations: [ExerciseExplanation] = try await query
                    .is("program_id", value: nil)
                    .execute()
                    .value

                return explanations.first
            }
        } catch {
            let errorMessage = "Failed to fetch exercise explanation"
            self.error = errorMessage
            errorLogger.logDatabaseError(error, table: "exercise_explanations")
            throw ExerciseExplanationError.fetchFailed(error)
        }
    }

    /// Fetch all explanations for a program's exercises
    /// - Parameter programId: The program UUID
    /// - Returns: Array of exercise explanations for the program
    func fetchProgramExplanations(programId: UUID) async throws -> [ExerciseExplanation] {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let explanations: [ExerciseExplanation] = try await client.client
                .from("exercise_explanations")
                .select()
                .eq("program_id", value: programId.uuidString)
                .execute()
                .value

            return explanations
        } catch {
            let errorMessage = "Failed to fetch program explanations"
            self.error = errorMessage
            errorLogger.logDatabaseError(error, table: "exercise_explanations")
            throw ExerciseExplanationError.fetchFailed(error)
        }
    }

    /// Get combined exercise data with explanation
    /// Fetches exercise template data along with its explanation
    /// - Parameter exerciseTemplateId: The exercise template UUID
    /// - Returns: Combined exercise data with explanation
    func fetchExerciseWithExplanation(exerciseTemplateId: UUID) async throws -> ExerciseWithExplanation? {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // Fetch exercise template with new columns
            let templates: [ExerciseTemplateWithEducation] = try await client.client
                .from("exercise_templates")
                .select()
                .eq("id", value: exerciseTemplateId.uuidString)
                .execute()
                .value

            guard let template = templates.first else {
                return nil
            }

            // Fetch explanation
            let explanation = try await fetchExplanation(exerciseTemplateId: exerciseTemplateId)

            return ExerciseWithExplanation(
                id: template.id,
                name: template.name,
                description: template.description,
                category: template.category,
                whyThisExercise: template.whyThisExercise,
                targetMuscles: template.targetMuscles,
                secondaryMuscles: template.secondaryMuscles,
                difficultyLevel: template.difficultyLevel,
                techniqueCues: template.techniqueCues,
                commonMistakes: template.commonMistakes,
                safetyNotes: template.safetyNotes,
                explanation: explanation
            )
        } catch let explanationError as ExerciseExplanationError {
            throw explanationError
        } catch {
            let errorMessage = "Failed to fetch exercise with explanation"
            self.error = errorMessage
            errorLogger.logDatabaseError(error, table: "exercise_templates")
            throw ExerciseExplanationError.fetchFailed(error)
        }
    }

    /// Fetch explanations for multiple exercises by their template IDs
    /// - Parameter exerciseTemplateIds: Array of exercise template UUIDs
    /// - Returns: Dictionary mapping exercise template IDs to their explanations
    func fetchExplanations(for exerciseTemplateIds: [UUID]) async throws -> [UUID: ExerciseExplanation] {
        isLoading = true
        error = nil
        defer { isLoading = false }

        guard !exerciseTemplateIds.isEmpty else {
            return [:]
        }

        do {
            let idStrings = exerciseTemplateIds.map { $0.uuidString }

            let explanations: [ExerciseExplanation] = try await client.client
                .from("exercise_explanations")
                .select()
                .in("exercise_template_id", values: idStrings)
                .execute()
                .value

            // Build dictionary mapping template ID to explanation
            var result: [UUID: ExerciseExplanation] = [:]
            for explanation in explanations {
                result[explanation.exerciseTemplateId] = explanation
            }

            return result
        } catch {
            let errorMessage = "Failed to fetch explanations for exercises"
            self.error = errorMessage
            errorLogger.logDatabaseError(error, table: "exercise_explanations")
            throw ExerciseExplanationError.fetchFailed(error)
        }
    }
}

// MARK: - Models

/// Exercise explanation content from the exercise_explanations table
/// ACP-816: Extended with baseball-specific fields
struct ExerciseExplanation: Codable, Identifiable, Hashable {
    let id: UUID
    let exerciseTemplateId: UUID
    let programId: UUID?
    let whyIncluded: String
    let whatItTargets: String?
    let howItHelps: String?
    let whenToFeelIt: String?
    let signsOfProgress: [String]?
    let warningSigns: [String]?
    let easierVariation: String?
    let harderVariation: String?
    let equipmentAlternatives: String?

    // ACP-816: Baseball-specific fields
    let baseballBenefit: String?           // "Improves rotational power for hitting"
    let performanceConnection: String?     // "Stronger hips = faster bat speed"
    let primaryMuscles: [String]?          // ['glutes', 'core', 'obliques']
    let secondaryMuscles: [String]?        // ['hip flexors', 'lower back']
    let movementPattern: String?           // 'hip_hinge', 'rotation', 'push', 'pull'
    let researchNote: String?              // Brief research reference

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseTemplateId = "exercise_template_id"
        case programId = "program_id"
        case whyIncluded = "why_included"
        case whatItTargets = "what_it_targets"
        case howItHelps = "how_it_helps"
        case whenToFeelIt = "when_to_feel_it"
        case signsOfProgress = "signs_of_progress"
        case warningSigns = "warning_signs"
        case easierVariation = "easier_variation"
        case harderVariation = "harder_variation"
        case equipmentAlternatives = "equipment_alternatives"
        // ACP-816: Baseball-specific coding keys
        case baseballBenefit = "baseball_benefit"
        case performanceConnection = "performance_connection"
        case primaryMuscles = "primary_muscles"
        case secondaryMuscles = "secondary_muscles"
        case movementPattern = "movement_pattern"
        case researchNote = "research_note"
    }

    // MARK: - Computed Properties (ACP-816)

    /// Returns formatted primary muscles as a comma-separated string
    var formattedPrimaryMuscles: String {
        guard let muscles = primaryMuscles, !muscles.isEmpty else { return "" }
        return muscles.map { $0.replacingOccurrences(of: "_", with: " ").capitalized }.joined(separator: ", ")
    }

    /// Returns formatted secondary muscles as a comma-separated string
    var formattedSecondaryMuscles: String {
        guard let muscles = secondaryMuscles, !muscles.isEmpty else { return "" }
        return muscles.map { $0.replacingOccurrences(of: "_", with: " ").capitalized }.joined(separator: ", ")
    }

    /// Returns all muscles (primary + secondary) formatted
    var allMusclesFormatted: String {
        var allMuscles: [String] = []
        if let primary = primaryMuscles {
            allMuscles.append(contentsOf: primary)
        }
        if let secondary = secondaryMuscles {
            allMuscles.append(contentsOf: secondary)
        }
        return allMuscles.map { $0.replacingOccurrences(of: "_", with: " ").capitalized }.joined(separator: ", ")
    }

    /// Returns human-readable movement pattern
    var movementPatternDisplay: String? {
        guard let pattern = movementPattern else { return nil }
        switch pattern.lowercased() {
        case "hip_hinge": return "Hip Hinge"
        case "rotation": return "Rotation"
        case "push": return "Push"
        case "pull": return "Pull"
        case "squat": return "Squat"
        case "lunge": return "Lunge"
        case "carry": return "Carry"
        case "core": return "Core Stability"
        case "accessory": return "Accessory"
        default: return pattern.capitalized
        }
    }

    /// Returns true if this explanation has baseball-specific content
    var hasBaseballContent: Bool {
        baseballBenefit != nil || performanceConnection != nil
    }

    /// Returns true if this explanation has muscle targeting info
    var hasMuscleInfo: Bool {
        (primaryMuscles != nil && !(primaryMuscles?.isEmpty ?? true)) ||
        (secondaryMuscles != nil && !(secondaryMuscles?.isEmpty ?? true))
    }
}

/// Exercise template with education columns from the exercise_templates table
private struct ExerciseTemplateWithEducation: Codable {
    let id: UUID
    let name: String
    let description: String?
    let category: String?
    let whyThisExercise: String?
    let targetMuscles: [String]?
    let secondaryMuscles: [String]?
    let difficultyLevel: Int?
    let techniqueCues: TechniqueCues?
    let commonMistakes: [String]?
    let safetyNotes: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case category
        case whyThisExercise = "why_this_exercise"
        case targetMuscles = "target_muscles"
        case secondaryMuscles = "secondary_muscles"
        case difficultyLevel = "difficulty_level"
        case techniqueCues = "technique_cues"
        case commonMistakes = "common_mistakes"
        case safetyNotes = "safety_notes"
    }
}

/// Combined exercise data with explanation for display
/// ACP-816: Enhanced with baseball-specific fields
struct ExerciseWithExplanation: Identifiable, Hashable {
    let id: UUID
    let name: String
    let description: String?
    let category: String?
    let whyThisExercise: String?
    let targetMuscles: [String]?
    let secondaryMuscles: [String]?
    let difficultyLevel: Int?
    let techniqueCues: TechniqueCues?
    let commonMistakes: [String]?
    let safetyNotes: [String]?
    let explanation: ExerciseExplanation?

    /// Returns the best available explanation text
    /// Prefers program-specific explanation, falls back to template's why_this_exercise
    var bestExplanation: String? {
        explanation?.whyIncluded ?? whyThisExercise
    }

    /// Returns all target muscles (primary + secondary)
    var allTargetMuscles: [String] {
        var muscles = targetMuscles ?? []
        if let secondary = secondaryMuscles {
            muscles.append(contentsOf: secondary)
        }
        return muscles
    }

    /// Difficulty level as a human-readable string
    var difficultyString: String? {
        guard let level = difficultyLevel else { return nil }
        switch level {
        case 1: return "Beginner"
        case 2: return "Intermediate"
        case 3: return "Advanced"
        case 4: return "Expert"
        default: return "Level \(level)"
        }
    }

    // MARK: - Baseball-Specific Accessors (ACP-816)

    /// Returns the baseball benefit from explanation
    var baseballBenefit: String? {
        explanation?.baseballBenefit
    }

    /// Returns the performance connection from explanation
    var performanceConnection: String? {
        explanation?.performanceConnection
    }

    /// Returns primary muscles from explanation or falls back to template muscles
    var primaryMusclesDisplay: [String] {
        explanation?.primaryMuscles ?? targetMuscles ?? []
    }

    /// Returns secondary muscles from explanation or falls back to template muscles
    var secondaryMusclesDisplay: [String] {
        explanation?.secondaryMuscles ?? secondaryMuscles ?? []
    }

    /// Returns the movement pattern
    var movementPattern: String? {
        explanation?.movementPatternDisplay
    }

    /// Returns the research note
    var researchNote: String? {
        explanation?.researchNote
    }

    /// Returns true if baseball-specific content is available
    var hasBaseballContent: Bool {
        explanation?.hasBaseballContent ?? false
    }
}

// MARK: - Errors

/// Errors for ExerciseExplanationService operations
enum ExerciseExplanationError: LocalizedError {
    case fetchFailed(Error)
    case notFound

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "Failed to fetch exercise explanation: \(error.localizedDescription)"
        case .notFound:
            return "Exercise explanation not found"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .fetchFailed:
            return "Please check your connection and try again."
        case .notFound:
            return "This exercise doesn't have a detailed explanation yet. Watch the video for guidance."
        }
    }
}
