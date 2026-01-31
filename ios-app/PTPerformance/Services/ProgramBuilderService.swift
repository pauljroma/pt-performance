//
//  ProgramBuilderService.swift
//  PTPerformance
//
//  Service for therapists to create and manage training programs
//  Handles program CRUD, phase management, workout assignments, and publishing
//

import Foundation
import Supabase

// MARK: - Response Models

/// Program with all its phases and assignments for editing
struct ProgramWithPhases: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String?
    let status: String
    let patientId: UUID?
    let metadata: [String: AnyCodable]?
    let phases: [PhaseWithAssignments]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case status
        case patientId = "patient_id"
        case metadata
        case phases
    }
}

/// Phase with its workout assignments
struct PhaseWithAssignments: Codable, Identifiable {
    let id: UUID
    let name: String
    let sequence: Int
    let durationWeeks: Int?
    let goals: String?
    let notes: String?
    let assignments: [ProgramWorkoutAssignment]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case sequence
        case durationWeeks = "duration_weeks"
        case goals
        case notes
        case assignments
    }
}

/// Workout assignment within a program
struct ProgramWorkoutAssignment: Codable, Identifiable {
    let id: UUID
    let programId: UUID
    let templateId: UUID
    let phaseId: UUID?
    let weekNumber: Int
    let dayOfWeek: Int
    let sequence: Int
    let notes: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case programId = "program_id"
        case templateId = "template_id"
        case phaseId = "phase_id"
        case weekNumber = "week_number"
        case dayOfWeek = "day_of_week"
        case sequence
        case notes
        case createdAt = "created_at"
    }
}

// MARK: - Insert Models

/// Input for creating a new program
private struct ProgramInsert: Encodable {
    let name: String
    let description: String?
    let status: String
    let patientId: UUID?
    let metadata: [String: AnyCodable]

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case status
        case patientId = "patient_id"
        case metadata
    }
}

/// Input for updating a program
private struct ProgramUpdate: Encodable {
    let name: String
    let description: String?

    enum CodingKeys: String, CodingKey {
        case name
        case description
    }
}

/// Input for creating a new phase
private struct PhaseInsert: Encodable {
    let programId: UUID
    let name: String
    let sequence: Int
    let durationWeeks: Int?
    let goals: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case programId = "program_id"
        case name
        case sequence
        case durationWeeks = "duration_weeks"
        case goals
        case notes
    }
}

/// Input for updating a phase
private struct PhaseUpdate: Encodable {
    let name: String
    let durationWeeks: Int?
    let goals: String?

    enum CodingKeys: String, CodingKey {
        case name
        case durationWeeks = "duration_weeks"
        case goals
    }
}

/// Input for creating a workout assignment
private struct AssignmentInsert: Encodable {
    let programId: UUID
    let templateId: UUID
    let phaseId: UUID
    let weekNumber: Int
    let dayOfWeek: Int
    let sequence: Int

    enum CodingKeys: String, CodingKey {
        case programId = "program_id"
        case templateId = "template_id"
        case phaseId = "phase_id"
        case weekNumber = "week_number"
        case dayOfWeek = "day_of_week"
        case sequence
    }
}

/// Input for publishing to program library
private struct ProgramLibraryInsert: Encodable {
    let title: String
    let description: String?
    let category: String
    let durationWeeks: Int
    let difficultyLevel: String
    let equipmentRequired: [String]
    let programId: UUID
    let isFeatured: Bool
    let tags: [String]
    let author: String?

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case category
        case durationWeeks = "duration_weeks"
        case difficultyLevel = "difficulty_level"
        case equipmentRequired = "equipment_required"
        case programId = "program_id"
        case isFeatured = "is_featured"
        case tags
        case author
    }
}

// MARK: - Response Models for queries

/// Simplified program response from database
struct ProgramResponse: Codable {
    let id: UUID
    let name: String
    let description: String?
    let status: String
    let patientId: UUID?
    let metadata: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case status
        case patientId = "patient_id"
        case metadata
    }
}

/// Simplified phase response from database
private struct PhaseResponse: Codable {
    let id: UUID
    let programId: UUID
    let name: String
    let sequence: Int
    let durationWeeks: Int?
    let goals: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case programId = "program_id"
        case name
        case sequence
        case durationWeeks = "duration_weeks"
        case goals
        case notes
    }
}

/// Response from program library insert
private struct ProgramLibraryResponse: Codable {
    let id: UUID
}

// MARK: - AnyCodable for flexible JSONB handling

/// Type-erased Codable wrapper for JSONB metadata
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

// MARK: - Errors

/// Errors specific to program builder service operations
enum ProgramServiceError: LocalizedError {
    case programNotFound
    case phaseNotFound
    case assignmentNotFound
    case createFailed(Error)
    case updateFailed(Error)
    case deleteFailed(Error)
    case fetchFailed(Error)
    case publishFailed(Error)
    case invalidPhaseOrder

    var errorDescription: String? {
        switch self {
        case .programNotFound:
            return "Program not found"
        case .phaseNotFound:
            return "Phase not found"
        case .assignmentNotFound:
            return "Workout assignment not found"
        case .createFailed(let error):
            return "Failed to create: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch: \(error.localizedDescription)"
        case .publishFailed(let error):
            return "Failed to publish: \(error.localizedDescription)"
        case .invalidPhaseOrder:
            return "Invalid phase order"
        }
    }
}

// MARK: - Service

/// Service for therapists to create and manage training programs
class ProgramBuilderService: ObservableObject {
    private let supabase: PTSupabaseClient
    private let logger = DebugLogger.shared
    private let errorLogger = ErrorLogger.shared

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
    }

    // MARK: - Program CRUD

    /// Create a new program (returns program ID)
    /// - Parameters:
    ///   - name: Program name
    ///   - description: Program description
    ///   - category: Program category (e.g., "strength", "mobility")
    ///   - durationWeeks: Total program duration in weeks
    /// - Returns: UUID of the created program
    func createProgram(
        name: String,
        description: String,
        category: String,
        durationWeeks: Int
    ) async throws -> UUID {
        logger.log("Creating program: \(name)", level: .diagnostic)

        let metadata: [String: AnyCodable] = [
            "duration_weeks": AnyCodable(durationWeeks),
            "category": AnyCodable(category),
            "is_system_template": AnyCodable(true)
        ]

        let insert = ProgramInsert(
            name: name,
            description: description,
            status: "draft",
            patientId: nil,  // System template, not patient-specific
            metadata: metadata
        )

        do {
            let response: ProgramResponse = try await supabase.client
                .from("programs")
                .insert(insert)
                .select()
                .single()
                .execute()
                .value

            logger.log("Created program with ID: \(response.id)", level: .success)
            return response.id
        } catch {
            errorLogger.logError(error, context: "ProgramBuilderService.createProgram")
            throw ProgramServiceError.createFailed(error)
        }
    }

    /// Update program metadata
    /// - Parameters:
    ///   - id: Program UUID
    ///   - name: New program name
    ///   - description: New program description
    func updateProgram(id: UUID, name: String, description: String) async throws {
        logger.log("Updating program: \(id)", level: .diagnostic)

        let update = ProgramUpdate(name: name, description: description)

        do {
            try await supabase.client
                .from("programs")
                .update(update)
                .eq("id", value: id.uuidString)
                .execute()

            logger.log("Updated program: \(id)", level: .success)
        } catch {
            errorLogger.logError(error, context: "ProgramBuilderService.updateProgram")
            throw ProgramServiceError.updateFailed(error)
        }
    }

    /// Delete a program and all its phases/assignments
    /// - Parameter id: Program UUID
    func deleteProgram(id: UUID) async throws {
        logger.log("Deleting program: \(id)", level: .diagnostic)

        do {
            // CASCADE delete will handle phases and assignments
            try await supabase.client
                .from("programs")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()

            logger.log("Deleted program: \(id)", level: .success)
        } catch {
            errorLogger.logError(error, context: "ProgramBuilderService.deleteProgram")
            throw ProgramServiceError.deleteFailed(error)
        }
    }

    /// Get program with phases for editing
    /// - Parameter id: Program UUID
    /// - Returns: Program with all phases and assignments
    func getProgram(id: UUID) async throws -> ProgramWithPhases {
        logger.log("Fetching program: \(id)", level: .diagnostic)

        do {
            // Fetch program
            let program: ProgramResponse = try await supabase.client
                .from("programs")
                .select()
                .eq("id", value: id.uuidString)
                .single()
                .execute()
                .value

            // Fetch phases
            let phases: [PhaseResponse] = try await supabase.client
                .from("phases")
                .select()
                .eq("program_id", value: id.uuidString)
                .order("sequence", ascending: true)
                .execute()
                .value

            // Fetch assignments
            let assignments: [ProgramWorkoutAssignment] = try await supabase.client
                .from("program_workout_assignments")
                .select()
                .eq("program_id", value: id.uuidString)
                .order("sequence", ascending: true)
                .execute()
                .value

            // Group assignments by phase
            let assignmentsByPhase = Dictionary(grouping: assignments) { $0.phaseId }

            // Build phases with assignments
            let phasesWithAssignments = phases.map { phase -> PhaseWithAssignments in
                PhaseWithAssignments(
                    id: phase.id,
                    name: phase.name,
                    sequence: phase.sequence,
                    durationWeeks: phase.durationWeeks,
                    goals: phase.goals,
                    notes: phase.notes,
                    assignments: assignmentsByPhase[phase.id] ?? []
                )
            }

            let result = ProgramWithPhases(
                id: program.id,
                name: program.name,
                description: program.description,
                status: program.status,
                patientId: program.patientId,
                metadata: program.metadata,
                phases: phasesWithAssignments
            )

            logger.log("Fetched program with \(phases.count) phases and \(assignments.count) assignments", level: .success)
            return result
        } catch {
            errorLogger.logError(error, context: "ProgramBuilderService.getProgram")
            throw ProgramServiceError.fetchFailed(error)
        }
    }

    // MARK: - Phase CRUD

    /// Add a phase to a program
    /// - Parameters:
    ///   - programId: Program UUID
    ///   - name: Phase name
    ///   - sequence: Phase sequence number (order within program)
    ///   - durationWeeks: Duration of phase in weeks
    ///   - goals: Phase goals description
    /// - Returns: UUID of the created phase
    func addPhase(
        programId: UUID,
        name: String,
        sequence: Int,
        durationWeeks: Int,
        goals: String?
    ) async throws -> UUID {
        logger.log("Adding phase '\(name)' to program: \(programId)", level: .diagnostic)

        let insert = PhaseInsert(
            programId: programId,
            name: name,
            sequence: sequence,
            durationWeeks: durationWeeks,
            goals: goals,
            notes: nil
        )

        do {
            let response: PhaseResponse = try await supabase.client
                .from("phases")
                .insert(insert)
                .select()
                .single()
                .execute()
                .value

            logger.log("Created phase with ID: \(response.id)", level: .success)
            return response.id
        } catch {
            errorLogger.logError(error, context: "ProgramBuilderService.addPhase")
            throw ProgramServiceError.createFailed(error)
        }
    }

    /// Update phase
    /// - Parameters:
    ///   - id: Phase UUID
    ///   - name: New phase name
    ///   - durationWeeks: New duration in weeks
    ///   - goals: New goals description
    func updatePhase(id: UUID, name: String, durationWeeks: Int, goals: String?) async throws {
        logger.log("Updating phase: \(id)", level: .diagnostic)

        let update = PhaseUpdate(name: name, durationWeeks: durationWeeks, goals: goals)

        do {
            try await supabase.client
                .from("phases")
                .update(update)
                .eq("id", value: id.uuidString)
                .execute()

            logger.log("Updated phase: \(id)", level: .success)
        } catch {
            errorLogger.logError(error, context: "ProgramBuilderService.updatePhase")
            throw ProgramServiceError.updateFailed(error)
        }
    }

    /// Delete phase
    /// - Parameter id: Phase UUID
    func deletePhase(id: UUID) async throws {
        logger.log("Deleting phase: \(id)", level: .diagnostic)

        do {
            try await supabase.client
                .from("phases")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()

            logger.log("Deleted phase: \(id)", level: .success)
        } catch {
            errorLogger.logError(error, context: "ProgramBuilderService.deletePhase")
            throw ProgramServiceError.deleteFailed(error)
        }
    }

    /// Reorder phases within a program
    /// - Parameters:
    ///   - programId: Program UUID
    ///   - phaseIds: Array of phase UUIDs in new order
    func reorderPhases(programId: UUID, phaseIds: [UUID]) async throws {
        logger.log("Reordering \(phaseIds.count) phases for program: \(programId)", level: .diagnostic)

        do {
            // Update each phase's sequence in order
            for (index, phaseId) in phaseIds.enumerated() {
                let newSequence = index + 1  // 1-based sequence

                try await supabase.client
                    .from("phases")
                    .update(["sequence": newSequence])
                    .eq("id", value: phaseId.uuidString)
                    .eq("program_id", value: programId.uuidString)
                    .execute()
            }

            logger.log("Reordered phases successfully", level: .success)
        } catch {
            errorLogger.logError(error, context: "ProgramBuilderService.reorderPhases")
            throw ProgramServiceError.updateFailed(error)
        }
    }

    // MARK: - Workout Assignments

    /// Assign a workout template to a program
    /// - Parameters:
    ///   - programId: Program UUID
    ///   - phaseId: Phase UUID
    ///   - templateId: System workout template UUID
    ///   - weekNumber: Week number within the program (1-52)
    ///   - dayOfWeek: Day of week (1=Monday, 7=Sunday)
    /// - Returns: UUID of the created assignment
    func assignWorkout(
        programId: UUID,
        phaseId: UUID,
        templateId: UUID,
        weekNumber: Int,
        dayOfWeek: Int
    ) async throws -> UUID {
        logger.log("Assigning workout template \(templateId) to program \(programId)", level: .diagnostic)

        // Calculate sequence based on week and day
        let sequence = (weekNumber - 1) * 7 + dayOfWeek

        let insert = AssignmentInsert(
            programId: programId,
            templateId: templateId,
            phaseId: phaseId,
            weekNumber: weekNumber,
            dayOfWeek: dayOfWeek,
            sequence: sequence
        )

        do {
            let response: ProgramWorkoutAssignment = try await supabase.client
                .from("program_workout_assignments")
                .insert(insert)
                .select()
                .single()
                .execute()
                .value

            logger.log("Created assignment with ID: \(response.id)", level: .success)
            return response.id
        } catch {
            errorLogger.logError(error, context: "ProgramBuilderService.assignWorkout")
            throw ProgramServiceError.createFailed(error)
        }
    }

    /// Remove workout assignment
    /// - Parameter id: Assignment UUID
    func removeAssignment(id: UUID) async throws {
        logger.log("Removing assignment: \(id)", level: .diagnostic)

        do {
            try await supabase.client
                .from("program_workout_assignments")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()

            logger.log("Removed assignment: \(id)", level: .success)
        } catch {
            errorLogger.logError(error, context: "ProgramBuilderService.removeAssignment")
            throw ProgramServiceError.deleteFailed(error)
        }
    }

    /// Get assignments for a phase
    /// - Parameter phaseId: Phase UUID
    /// - Returns: Array of workout assignments
    func getAssignments(phaseId: UUID) async throws -> [ProgramWorkoutAssignment] {
        logger.log("Fetching assignments for phase: \(phaseId)", level: .diagnostic)

        do {
            let assignments: [ProgramWorkoutAssignment] = try await supabase.client
                .from("program_workout_assignments")
                .select()
                .eq("phase_id", value: phaseId.uuidString)
                .order("sequence", ascending: true)
                .execute()
                .value

            logger.log("Fetched \(assignments.count) assignments", level: .success)
            return assignments
        } catch {
            errorLogger.logError(error, context: "ProgramBuilderService.getAssignments")
            throw ProgramServiceError.fetchFailed(error)
        }
    }

    // MARK: - Publishing

    /// Publish program to library (creates program_library entry)
    /// - Parameters:
    ///   - programId: Program UUID
    ///   - title: Display title for the library
    ///   - description: Description for the library
    ///   - category: Category (e.g., "strength", "mobility", "annuals")
    ///   - difficultyLevel: Difficulty level ("beginner", "intermediate", "advanced")
    ///   - equipmentRequired: Array of required equipment
    ///   - tags: Array of searchable tags
    ///   - isFeatured: Whether to feature this program
    /// - Returns: UUID of the created program library entry
    func publishToLibrary(
        programId: UUID,
        title: String,
        description: String,
        category: String,
        difficultyLevel: String,
        equipmentRequired: [String],
        tags: [String],
        isFeatured: Bool
    ) async throws -> UUID {
        logger.log("Publishing program \(programId) to library as '\(title)'", level: .diagnostic)

        // Get program to calculate duration
        let program = try await getProgram(id: programId)

        // Calculate total duration from phases
        let durationWeeks = program.phases.reduce(0) { sum, phase in
            sum + (phase.durationWeeks ?? 0)
        }

        let insert = ProgramLibraryInsert(
            title: title,
            description: description,
            category: category,
            durationWeeks: max(durationWeeks, 1),  // At least 1 week
            difficultyLevel: difficultyLevel,
            equipmentRequired: equipmentRequired,
            programId: programId,
            isFeatured: isFeatured,
            tags: tags,
            author: "PT Performance"
        )

        do {
            let response: ProgramLibraryResponse = try await supabase.client
                .from("program_library")
                .insert(insert)
                .select("id")
                .single()
                .execute()
                .value

            // Update program status to "active"
            try await supabase.client
                .from("programs")
                .update(["status": "active"])
                .eq("id", value: programId.uuidString)
                .execute()

            logger.log("Published to library with ID: \(response.id)", level: .success)
            return response.id
        } catch {
            errorLogger.logError(error, context: "ProgramBuilderService.publishToLibrary")
            throw ProgramServiceError.publishFailed(error)
        }
    }

    // MARK: - Bulk Operations

    /// Assign multiple workouts to a program at once
    /// - Parameters:
    ///   - programId: Program UUID
    ///   - assignments: Array of tuples (phaseId, templateId, weekNumber, dayOfWeek)
    /// - Returns: Array of created assignment UUIDs
    func bulkAssignWorkouts(
        programId: UUID,
        assignments: [(phaseId: UUID, templateId: UUID, weekNumber: Int, dayOfWeek: Int)]
    ) async throws -> [UUID] {
        logger.log("Bulk assigning \(assignments.count) workouts to program: \(programId)", level: .diagnostic)

        var createdIds: [UUID] = []

        for (index, assignment) in assignments.enumerated() {
            let sequence = index + 1

            let insert = AssignmentInsert(
                programId: programId,
                templateId: assignment.templateId,
                phaseId: assignment.phaseId,
                weekNumber: assignment.weekNumber,
                dayOfWeek: assignment.dayOfWeek,
                sequence: sequence
            )

            do {
                let response: ProgramWorkoutAssignment = try await supabase.client
                    .from("program_workout_assignments")
                    .insert(insert)
                    .select()
                    .single()
                    .execute()
                    .value

                createdIds.append(response.id)
            } catch {
                logger.log("Failed to create assignment \(index + 1): \(error.localizedDescription)", level: .warning)
                // Continue with remaining assignments
            }
        }

        logger.log("Created \(createdIds.count) of \(assignments.count) assignments", level: .success)
        return createdIds
    }

    /// Fetch all system programs (templates) available for editing
    /// - Returns: Array of programs with basic info
    func fetchSystemPrograms() async throws -> [ProgramResponse] {
        logger.log("Fetching system programs", level: .diagnostic)

        do {
            let programs: [ProgramResponse] = try await supabase.client
                .from("programs")
                .select()
                .is("patient_id", value: nil)  // System templates have no patient
                .order("name", ascending: true)
                .execute()
                .value

            logger.log("Fetched \(programs.count) system programs", level: .success)
            return programs
        } catch {
            errorLogger.logError(error, context: "ProgramBuilderService.fetchSystemPrograms")
            throw ProgramServiceError.fetchFailed(error)
        }
    }
}
