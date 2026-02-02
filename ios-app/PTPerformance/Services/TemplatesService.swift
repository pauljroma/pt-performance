//
//  TemplatesService.swift
//  PTPerformance
//
//  Created by Build 46 Swarm Agent 2
//  Business logic for workout templates management
//

import Foundation
import Supabase

/// Service for managing workout templates
class TemplatesService {

    // MARK: - Singleton

    static let shared = TemplatesService()

    private init() {}

    // MARK: - Dependencies

    private let supabase = PTSupabaseClient.shared.client
    private let errorLogger = ErrorLogger.shared

    // MARK: - Template CRUD

    /// Fetch all public templates and user's private templates
    /// - Parameter userId: The current user's UUID
    /// - Returns: Array of workout templates
    func fetchTemplates(for userId: String) async throws -> [WorkoutTemplate] {
        do {
            let templates: [WorkoutTemplate] = try await supabase
                .from("workout_templates")
                .select()
                .or("is_public.eq.true,created_by.eq.\(userId)")
                .order("usage_count", ascending: false)
                .order("created_at", ascending: false)
                .execute()
                .value

            return templates
        } catch {
            errorLogger.logError(
                error,
                context: "TemplatesService.fetchTemplates",
                metadata: ["user_id": userId]
            )
            throw TemplateError.fetchFailed(error)
        }
    }

    /// Fetch popular public templates
    /// - Parameter limit: Maximum number of templates to return
    /// - Returns: Array of popular templates
    func fetchPopularTemplates(limit: Int = 10) async throws -> [WorkoutTemplate] {
        do {
            let templates: [WorkoutTemplate] = try await supabase
                .from("workout_templates")
                .select()
                .eq("is_public", value: true)
                .order("usage_count", ascending: false)
                .limit(limit)
                .execute()
                .value

            return templates
        } catch {
            errorLogger.logError(
                error,
                context: "TemplatesService.fetchPopularTemplates"
            )
            throw TemplateError.fetchFailed(error)
        }
    }

    /// Fetch template details with phases and sessions
    /// - Parameter templateId: The template UUID
    /// - Returns: Template with all phases and sessions
    func fetchTemplateDetails(templateId: String) async throws -> WorkoutTemplateDetail {
        do {
            // Fetch template
            let template: WorkoutTemplate = try await supabase
                .from("workout_templates")
                .select()
                .eq("id", value: templateId)
                .single()
                .execute()
                .value

            // Fetch phases
            let phases: [TemplatePhase] = try await supabase
                .from("template_phases")
                .select()
                .eq("template_id", value: templateId)
                .order("sequence", ascending: true)
                .execute()
                .value

            // Fetch sessions for each phase
            var phaseDetails: [TemplatePhaseDetail] = []
            for phase in phases {
                let sessions: [TemplateSession] = try await supabase
                    .from("template_sessions")
                    .select()
                    .eq("phase_id", value: phase.id)
                    .order("sequence", ascending: true)
                    .execute()
                    .value

                phaseDetails.append(TemplatePhaseDetail(phase: phase, sessions: sessions))
            }

            return WorkoutTemplateDetail(template: template, phases: phaseDetails)
        } catch {
            errorLogger.logError(
                error,
                context: "TemplatesService.fetchTemplateDetails",
                metadata: ["template_id": templateId]
            )
            throw TemplateError.fetchFailed(error)
        }
    }

    /// Create a new workout template
    /// - Parameters:
    ///   - name: Template name
    ///   - description: Template description
    ///   - category: Template category
    ///   - difficultyLevel: Difficulty level
    ///   - durationWeeks: Expected duration in weeks
    ///   - createdBy: Creator's user ID
    ///   - isPublic: Whether template is public
    ///   - tags: Array of tags
    /// - Returns: The created template
    func createTemplate(
        name: String,
        description: String?,
        category: WorkoutTemplate.TemplateCategory,
        difficultyLevel: WorkoutTemplate.DifficultyLevel?,
        durationWeeks: Int?,
        createdBy: String,
        isPublic: Bool,
        tags: [String]
    ) async throws -> WorkoutTemplate {
        let newTemplate = WorkoutTemplateInsert(
            name: name,
            description: description,
            category: category.rawValue,
            difficultyLevel: difficultyLevel?.rawValue,
            durationWeeks: durationWeeks,
            createdBy: createdBy,
            isPublic: isPublic,
            tags: tags
        )

        do {
            let created: WorkoutTemplate = try await supabase
                .from("workout_templates")
                .insert(newTemplate)
                .select()
                .single()
                .execute()
                .value

            return created
        } catch {
            errorLogger.logError(
                error,
                context: "TemplatesService.createTemplate",
                metadata: ["name": name, "created_by": createdBy]
            )
            throw TemplateError.createFailed(error)
        }
    }

    /// Update an existing template
    /// - Parameters:
    ///   - templateId: Template UUID
    ///   - update: Template update with fields to change
    /// - Returns: The updated template
    func updateTemplate(
        templateId: String,
        update: WorkoutTemplateUpdate
    ) async throws -> WorkoutTemplate {
        do {
            let updated: WorkoutTemplate = try await supabase
                .from("workout_templates")
                .update(update)
                .eq("id", value: templateId)
                .select()
                .single()
                .execute()
                .value

            return updated
        } catch {
            errorLogger.logError(
                error,
                context: "TemplatesService.updateTemplate",
                metadata: ["template_id": templateId]
            )
            throw TemplateError.updateFailed(error)
        }
    }

    /// Delete a template
    /// - Parameter templateId: Template UUID
    func deleteTemplate(templateId: String) async throws {
        do {
            try await supabase
                .from("workout_templates")
                .delete()
                .eq("id", value: templateId)
                .execute()
        } catch {
            errorLogger.logError(
                error,
                context: "TemplatesService.deleteTemplate",
                metadata: ["template_id": templateId]
            )
            throw TemplateError.deleteFailed(error)
        }
    }

    // MARK: - Phase Operations

    /// Add a phase to a template
    /// - Parameters:
    ///   - templateId: Template UUID
    ///   - name: Phase name
    ///   - description: Phase description
    ///   - sequence: Phase sequence number
    ///   - durationWeeks: Phase duration in weeks
    /// - Returns: The created phase
    func addPhase(
        to templateId: String,
        name: String,
        description: String?,
        sequence: Int,
        durationWeeks: Int?
    ) async throws -> TemplatePhase {
        let newPhase = TemplatePhaseInsert(
            templateId: templateId,
            name: name,
            description: description,
            sequence: sequence,
            durationWeeks: durationWeeks
        )

        do {
            let created: TemplatePhase = try await supabase
                .from("template_phases")
                .insert(newPhase)
                .select()
                .single()
                .execute()
                .value

            return created
        } catch {
            errorLogger.logError(
                error,
                context: "TemplatesService.addPhase",
                metadata: ["template_id": templateId, "name": name]
            )
            throw TemplateError.createFailed(error)
        }
    }

    /// Delete a phase
    /// - Parameter phaseId: Phase UUID
    func deletePhase(phaseId: String) async throws {
        do {
            try await supabase
                .from("template_phases")
                .delete()
                .eq("id", value: phaseId)
                .execute()
        } catch {
            errorLogger.logError(
                error,
                context: "TemplatesService.deletePhase",
                metadata: ["phase_id": phaseId]
            )
            throw TemplateError.deleteFailed(error)
        }
    }

    // MARK: - Session Operations

    /// Add a session to a phase
    /// - Parameters:
    ///   - phaseId: Phase UUID
    ///   - name: Session name
    ///   - description: Session description
    ///   - sequence: Session sequence number
    ///   - exercises: Array of template exercises
    ///   - notes: Session notes
    /// - Returns: The created session
    func addSession(
        to phaseId: String,
        name: String,
        description: String?,
        sequence: Int,
        exercises: [TemplateExercise],
        notes: String?
    ) async throws -> TemplateSession {
        let newSession = TemplateSessionInsert(
            phaseId: phaseId,
            name: name,
            description: description,
            sequence: sequence,
            exercises: exercises,
            notes: notes
        )

        do {
            let created: TemplateSession = try await supabase
                .from("template_sessions")
                .insert(newSession)
                .select()
                .single()
                .execute()
                .value

            return created
        } catch {
            errorLogger.logError(
                error,
                context: "TemplatesService.addSession",
                metadata: ["phase_id": phaseId, "name": name]
            )
            throw TemplateError.createFailed(error)
        }
    }

    /// Delete a session
    /// - Parameter sessionId: Session UUID
    func deleteSession(sessionId: String) async throws {
        do {
            try await supabase
                .from("template_sessions")
                .delete()
                .eq("id", value: sessionId)
                .execute()
        } catch {
            errorLogger.logError(
                error,
                context: "TemplatesService.deleteSession",
                metadata: ["session_id": sessionId]
            )
            throw TemplateError.deleteFailed(error)
        }
    }

    // MARK: - Program Creation from Template

    /// Create a program from a template
    /// - Parameters:
    ///   - templateId: Template UUID
    ///   - patientId: Patient UUID
    ///   - programName: Name for the new program
    ///   - startDate: Program start date
    /// - Returns: The created program UUID
    func createProgramFromTemplate(
        templateId: String,
        patientId: String,
        programName: String,
        startDate: Date
    ) async throws -> String {
        do {
            // Call the database function to create program from template
            struct ProgramResult: Codable {
                let programId: String

                enum CodingKeys: String, CodingKey {
                    case programId = "create_program_from_template"
                }
            }

            let result: [ProgramResult] = try await supabase
                .rpc("create_program_from_template", params: [
                    "p_template_id": templateId,
                    "p_patient_id": patientId,
                    "p_program_name": programName,
                    "p_start_date": startDate.iso8601String
                ])
                .execute()
                .value

            guard let programId = result.first?.programId else {
                throw TemplateError.programCreationFailed
            }

            return programId
        } catch {
            errorLogger.logError(
                error,
                context: "TemplatesService.createProgramFromTemplate",
                metadata: [
                    "template_id": templateId,
                    "patient_id": patientId,
                    "program_name": programName
                ]
            )
            throw TemplateError.programCreationFailed
        }
    }

    // MARK: - Search and Filter

    /// Search templates by text
    /// - Parameters:
    ///   - searchText: Text to search for
    ///   - userId: Current user ID (to include private templates)
    /// - Returns: Array of matching templates
    func searchTemplates(
        searchText: String,
        userId: String
    ) async throws -> [WorkoutTemplate] {
        do {
            let templates: [WorkoutTemplate] = try await supabase
                .from("workout_templates")
                .select()
                .or("is_public.eq.true,created_by.eq.\(userId)")
                .or("name.ilike.%\(searchText)%,description.ilike.%\(searchText)%,tags.cs.{\(searchText)}")
                .execute()
                .value

            return templates
        } catch {
            errorLogger.logError(
                error,
                context: "TemplatesService.searchTemplates",
                metadata: ["search_text": searchText]
            )
            throw TemplateError.fetchFailed(error)
        }
    }
}

// MARK: - Supporting Types

/// Insert model for creating templates
private struct WorkoutTemplateInsert: Encodable {
    let name: String
    let description: String?
    let category: String
    let difficultyLevel: String?
    let durationWeeks: Int?
    let createdBy: String
    let isPublic: Bool
    let tags: [String]

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case category
        case difficultyLevel = "difficulty_level"
        case durationWeeks = "duration_weeks"
        case createdBy = "created_by"
        case isPublic = "is_public"
        case tags
    }
}

/// Update model for templates - all fields optional
struct WorkoutTemplateUpdate: Encodable {
    var name: String?
    var description: String?
    var category: String?
    var difficultyLevel: String?
    var durationWeeks: Int?
    var isPublic: Bool?
    var tags: [String]?

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case category
        case difficultyLevel = "difficulty_level"
        case durationWeeks = "duration_weeks"
        case isPublic = "is_public"
        case tags
    }

    init(
        name: String? = nil,
        description: String? = nil,
        category: String? = nil,
        difficultyLevel: String? = nil,
        durationWeeks: Int? = nil,
        isPublic: Bool? = nil,
        tags: [String]? = nil
    ) {
        self.name = name
        self.description = description
        self.category = category
        self.difficultyLevel = difficultyLevel
        self.durationWeeks = durationWeeks
        self.isPublic = isPublic
        self.tags = tags
    }
}

/// Insert model for creating phases
private struct TemplatePhaseInsert: Encodable {
    let templateId: String
    let name: String
    let description: String?
    let sequence: Int
    let durationWeeks: Int?

    enum CodingKeys: String, CodingKey {
        case templateId = "template_id"
        case name
        case description
        case sequence
        case durationWeeks = "duration_weeks"
    }
}

/// Insert model for creating sessions
private struct TemplateSessionInsert: Encodable {
    let phaseId: String
    let name: String
    let description: String?
    let sequence: Int
    let exercises: [TemplateExercise]
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case phaseId = "phase_id"
        case name
        case description
        case sequence
        case exercises
        case notes
    }
}

/// Template errors
enum TemplateError: LocalizedError {
    case fetchFailed(Error)
    case createFailed(Error)
    case updateFailed(Error)
    case deleteFailed(Error)
    case programCreationFailed

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Failed to fetch templates"
        case .createFailed:
            return "Failed to create template"
        case .updateFailed:
            return "Failed to update template"
        case .deleteFailed:
            return "Failed to delete template"
        case .programCreationFailed:
            return "Failed to create program from template"
        }
    }
}

// MARK: - Date Extensions

private extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}
