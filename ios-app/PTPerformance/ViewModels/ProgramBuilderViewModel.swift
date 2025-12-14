//
//  ProgramBuilderViewModel.swift
//  PTPerformance
//

import Foundation
import SwiftUI

@MainActor
class ProgramBuilderViewModel: ObservableObject {
    @Published var programName: String = ""
    @Published var selectedProtocol: TherapyProtocol? {
        didSet {
            if let therapyProtocol = selectedProtocol {
                loadProtocolPhases(therapyProtocol)
            }
        }
    }
    @Published var phases: [ProgramPhase] = []
    @Published var availableProtocols: [TherapyProtocol] = []
    @Published var validationError: String?
    @Published var isCreating = false
    @Published var createError: String?
    @Published var successMessage: String?
    @Published var isLoadingProtocols = false

    private let supabase: PTSupabaseClient
    private var isSubmitting = false // Prevent double-submission

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
    }
    
    var isValid: Bool {
        do {
            try validateProgram()
            validationError = nil
            return true
        } catch let error as ProgramBuilderError {
            validationError = error.errorDescription
            return false
        } catch {
            validationError = "An unexpected error occurred"
            return false
        }
    }

    // MARK: - Validation

    /// Comprehensive validation of program data before creation
    private func validateProgram() throws {
        // Validate program name
        guard !programName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ProgramBuilderError.emptyProgramName
        }

        guard programName.count >= 3 else {
            throw ProgramBuilderError.programNameTooShort
        }

        guard programName.count <= 100 else {
            throw ProgramBuilderError.programNameTooLong
        }

        // Validate phases
        guard !phases.isEmpty else {
            throw ProgramBuilderError.noPhases
        }

        // Validate protocol constraints if protocol is selected
        if let therapyProtocol = selectedProtocol {
            let constraints = therapyProtocol.constraints

            if phases.count < constraints.minPhases {
                throw ProgramBuilderError.tooFewPhases(min: constraints.minPhases)
            }

            if phases.count > constraints.maxPhases {
                throw ProgramBuilderError.tooManyPhases(max: constraints.maxPhases)
            }
        }

        // Validate each phase
        for (index, phase) in phases.enumerated() {
            guard !phase.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw ProgramBuilderError.emptyPhaseName(phaseNumber: index + 1)
            }

            guard phase.durationWeeks > 0 else {
                throw ProgramBuilderError.invalidPhaseDuration(phaseNumber: index + 1)
            }

            guard phase.durationWeeks <= 52 else {
                throw ProgramBuilderError.phaseDurationTooLong(phaseNumber: index + 1)
            }
        }

        // Validate total duration
        let totalWeeks = phases.reduce(0) { $0 + $1.durationWeeks }
        guard totalWeeks > 0 else {
            throw ProgramBuilderError.invalidTotalDuration
        }

        guard totalWeeks <= 104 else { // Max 2 years
            throw ProgramBuilderError.totalDurationTooLong
        }
    }
    
    var canAddPhase: Bool {
        guard let therapyProtocol = selectedProtocol else { return true }
        return phases.count < therapyProtocol.constraints.maxPhases
    }
    
    func loadProtocols() async {
        isLoadingProtocols = true
        createError = nil

        do {
            // For MVP, use sample protocols
            // In production, fetch from Supabase:
            // let response = try await supabase.from("protocol_templates").select().execute()

            availableProtocols = TherapyProtocol.sampleProtocols
            isLoadingProtocols = false
        } catch {
            createError = "Failed to load protocols. Please try again."
            isLoadingProtocols = false
        }
    }
    
    func loadProtocolPhases(_ therapyProtocol: TherapyProtocol) {
        // Load phases from protocol
        phases = therapyProtocol.phases.map { protocolPhase in
            ProgramPhase(
                name: protocolPhase.name,
                durationWeeks: protocolPhase.durationWeeks,
                sessions: [],
                order: protocolPhase.order
            )
        }
    }
    
    func addPhase() {
        let newPhase = ProgramPhase(
            name: "Phase \(phases.count + 1)",
            durationWeeks: 2,
            sessions: [],
            order: phases.count + 1
        )
        phases.append(newPhase)
    }
    
    func deletePhase(at offsets: IndexSet) {
        // Only allow deletion if not using protocol with fixed phases
        guard selectedProtocol == nil || selectedProtocol?.constraints.canModifyDuration == true else {
            return
        }
        
        phases.remove(atOffsets: offsets)
        
        // Reorder remaining phases
        for (index, _) in phases.enumerated() {
            phases[index].order = index + 1
        }
    }
    
    func createProgram(patientId: String?, targetLevel: String = "Intermediate") async throws -> String {
        let logger = DebugLogger.shared

        // Prevent double-submission
        guard !isSubmitting else {
            logger.log("⚠️ Program creation already in progress", level: .diagnostic)
            throw ProgramBuilderError.operationInProgress
        }

        isSubmitting = true
        isCreating = true
        createError = nil
        successMessage = nil

        defer {
            isSubmitting = false
            isCreating = false
        }

        logger.log("📝 Creating program: \(programName)", level: .diagnostic)

        do {
            // Validate before creating
            try validateProgram()

            // Validate target level
            guard !targetLevel.isEmpty else {
                throw ProgramBuilderError.emptyTargetLevel
            }

            // Calculate total duration
            let totalWeeks = phases.reduce(0) { $0 + $1.durationWeeks }

            // Step 1: Create program record
            let programInput = CreateProgramInput(
                patientId: patientId,
                name: programName.trimmingCharacters(in: .whitespacesAndNewlines),
                targetLevel: targetLevel,
                durationWeeks: totalWeeks
            )

            logger.log("📝 Inserting program into programs table...", level: .diagnostic)

            let programResponse = try await supabase.client
                .from("programs")
                .insert(programInput)
                .select()
                .single()
                .execute()

            logger.log("✅ Program created successfully", level: .success)

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let program: Program

            do {
                program = try decoder.decode(Program.self, from: programResponse.data)
            } catch {
                logger.log("❌ Failed to decode program response: \(error)", level: .error)
                throw ProgramBuilderError.databaseDecodingError
            }

            logger.log("✅ Program ID: \(program.id)", level: .success)

            // Step 2: Create phase records and get their IDs
            for (phaseIndex, phase) in phases.enumerated() {
                let phaseInput = CreatePhaseInput(
                    programId: program.id,
                    phaseNumber: phaseIndex + 1,
                    name: phase.name.trimmingCharacters(in: .whitespacesAndNewlines),
                    durationWeeks: phase.durationWeeks,
                    goals: nil
                )

                logger.log("📝 Creating phase \(phaseIndex + 1): \(phase.name)", level: .diagnostic)

                let phaseResponse: Phase
                do {
                    let response = try await supabase.client
                        .from("phases")
                        .insert(phaseInput)
                        .select()
                        .single()
                        .execute()

                    phaseResponse = try decoder.decode(Phase.self, from: response.data)
                    logger.log("✅ Phase \(phaseIndex + 1) created with ID: \(phaseResponse.id)", level: .success)
                } catch {
                    logger.log("❌ Failed to create phase \(phaseIndex + 1): \(error)", level: .error)
                    throw ProgramBuilderError.phaseCreationFailed(phaseNumber: phaseIndex + 1)
                }

                // Step 3: Create session records for this phase
                for (sessionIndex, session) in phase.sessions.enumerated() {
                    let sessionInput = CreateSessionInput(
                        phaseId: phaseResponse.id,
                        name: session.name.trimmingCharacters(in: .whitespacesAndNewlines),
                        sequence: sessionIndex + 1,
                        weekday: nil,
                        notes: nil
                    )

                    logger.log("📝 Creating session \(sessionIndex + 1): \(session.name)", level: .diagnostic)

                    let sessionResponse: Session
                    do {
                        let response = try await supabase.client
                            .from("sessions")
                            .insert(sessionInput)
                            .select()
                            .single()
                            .execute()

                        sessionResponse = try decoder.decode(Session.self, from: response.data)
                        logger.log("✅ Session \(sessionIndex + 1) created with ID: \(sessionResponse.id)", level: .success)
                    } catch {
                        logger.log("❌ Failed to create session \(sessionIndex + 1): \(error)", level: .error)
                        throw ProgramBuilderError.sessionCreationFailed(
                            phaseNumber: phaseIndex + 1,
                            sessionNumber: sessionIndex + 1
                        )
                    }

                    // Step 4: Create session_exercises for this session
                    for (exerciseIndex, exercise) in session.exercises.enumerated() {
                        let exerciseInput = CreateSessionExerciseInput(
                            sessionId: sessionResponse.id,
                            exerciseTemplateId: exercise.exerciseTemplateId,
                            sequence: exerciseIndex + 1,
                            targetSets: exercise.sets,
                            targetReps: exercise.reps,
                            targetLoad: exercise.load,
                            loadUnit: exercise.loadUnit,
                            restPeriodSeconds: exercise.restSeconds,
                            notes: exercise.notes
                        )

                        logger.log("📝 Creating exercise \(exerciseIndex + 1): \(exercise.name ?? "Unknown")", level: .diagnostic)

                        do {
                            try await supabase.client
                                .from("session_exercises")
                                .insert(exerciseInput)
                                .execute()

                            logger.log("✅ Exercise \(exerciseIndex + 1) created", level: .success)
                        } catch {
                            logger.log("❌ Failed to create exercise \(exerciseIndex + 1): \(error)", level: .error)
                            throw ProgramBuilderError.exerciseCreationFailed(
                                phaseNumber: phaseIndex + 1,
                                sessionNumber: sessionIndex + 1,
                                exerciseNumber: exerciseIndex + 1
                            )
                        }
                    }
                }
            }

            logger.log("✅ Program creation complete!", level: .success)

            // Calculate totals for success message
            let totalSessions = phases.reduce(0) { $0 + $1.sessions.count }
            let totalExercises = phases.reduce(0) { phaseSum, phase in
                phaseSum + phase.sessions.reduce(0) { sessionSum, session in
                    sessionSum + session.exercises.count
                }
            }

            if totalSessions > 0 {
                successMessage = "Program '\(programName)' created successfully with \(phases.count) phase(s), \(totalSessions) session(s), and \(totalExercises) exercise(s)"
            } else {
                successMessage = "Program '\(programName)' created successfully with \(phases.count) phase(s)"
            }

            return program.id

        } catch let error as ProgramBuilderError {
            logger.log("❌ Validation error: \(error.errorDescription ?? "Unknown")", level: .error)
            createError = error.errorDescription
            throw error
        } catch {
            logger.log("❌ Error creating program: \(error)", level: .error)

            // Translate common Supabase errors to user-friendly messages
            let userFriendlyError = translateError(error)
            createError = userFriendlyError

            throw ProgramBuilderError.databaseError(message: userFriendlyError)
        }
    }

    // MARK: - Error Translation

    /// Translates technical errors into user-friendly messages
    private func translateError(_ error: Error) -> String {
        let errorString = error.localizedDescription.lowercased()

        if errorString.contains("network") || errorString.contains("connection") {
            return "Unable to connect to the server. Please check your internet connection and try again."
        }

        if errorString.contains("timeout") {
            return "The request timed out. Please try again."
        }

        if errorString.contains("unauthorized") || errorString.contains("authentication") {
            return "You don't have permission to perform this action. Please sign in again."
        }

        if errorString.contains("duplicate") || errorString.contains("unique") {
            return "A program with this name already exists. Please choose a different name."
        }

        if errorString.contains("foreign key") || errorString.contains("reference") {
            return "Invalid patient or therapist selected. Please try again."
        }

        if errorString.contains("not found") {
            return "The requested resource was not found. Please refresh and try again."
        }

        // Default fallback
        return "An unexpected error occurred. Please try again or contact support if the problem persists."
    }
}

// MARK: - Input Models for Supabase

struct CreateProgramInput: Codable {
    let patientId: String?
    let name: String
    let targetLevel: String
    let durationWeeks: Int

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case name
        case targetLevel = "target_level"
        case durationWeeks = "duration_weeks"
    }
}

struct CreatePhaseInput: Codable {
    let programId: String
    let phaseNumber: Int
    let name: String
    let durationWeeks: Int?
    let goals: String?

    enum CodingKeys: String, CodingKey {
        case programId = "program_id"
        case phaseNumber = "phase_number"
        case name
        case durationWeeks = "duration_weeks"
        case goals
    }
}

struct CreateSessionInput: Codable {
    let phaseId: String
    let name: String
    let sequence: Int
    let weekday: Int?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case phaseId = "phase_id"
        case name
        case sequence
        case weekday
        case notes
    }
}

struct CreateSessionExerciseInput: Codable {
    let sessionId: String
    let exerciseTemplateId: String
    let sequence: Int
    let targetSets: Int
    let targetReps: String
    let targetLoad: Double?
    let loadUnit: String?
    let restPeriodSeconds: Int?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case exerciseTemplateId = "exercise_template_id"
        case sequence
        case targetSets = "target_sets"
        case targetReps = "target_reps"
        case targetLoad = "target_load"
        case loadUnit = "load_unit"
        case restPeriodSeconds = "rest_period_seconds"
        case notes
    }
}

// MARK: - Error Types

enum ProgramBuilderError: LocalizedError {
    case emptyProgramName
    case programNameTooShort
    case programNameTooLong
    case emptyTargetLevel
    case noPhases
    case tooFewPhases(min: Int)
    case tooManyPhases(max: Int)
    case emptyPhaseName(phaseNumber: Int)
    case invalidPhaseDuration(phaseNumber: Int)
    case phaseDurationTooLong(phaseNumber: Int)
    case invalidTotalDuration
    case totalDurationTooLong
    case phaseCreationFailed(phaseNumber: Int)
    case sessionCreationFailed(phaseNumber: Int, sessionNumber: Int)
    case exerciseCreationFailed(phaseNumber: Int, sessionNumber: Int, exerciseNumber: Int)
    case databaseError(message: String)
    case databaseDecodingError
    case operationInProgress

    var errorDescription: String? {
        switch self {
        case .emptyProgramName:
            return "Please enter a program name"
        case .programNameTooShort:
            return "Program name must be at least 3 characters"
        case .programNameTooLong:
            return "Program name must be 100 characters or less"
        case .emptyTargetLevel:
            return "Please select a target level"
        case .noPhases:
            return "Please add at least one phase to the program"
        case .tooFewPhases(let min):
            return "This protocol requires at least \(min) phase(s)"
        case .tooManyPhases(let max):
            return "This protocol allows a maximum of \(max) phase(s)"
        case .emptyPhaseName(let phaseNumber):
            return "Please enter a name for phase \(phaseNumber)"
        case .invalidPhaseDuration(let phaseNumber):
            return "Phase \(phaseNumber) must have a duration greater than 0 weeks"
        case .phaseDurationTooLong(let phaseNumber):
            return "Phase \(phaseNumber) duration cannot exceed 52 weeks (1 year)"
        case .invalidTotalDuration:
            return "Total program duration must be greater than 0 weeks"
        case .totalDurationTooLong:
            return "Total program duration cannot exceed 104 weeks (2 years)"
        case .phaseCreationFailed(let phaseNumber):
            return "Failed to create phase \(phaseNumber). Please try again."
        case .sessionCreationFailed(let phaseNumber, let sessionNumber):
            return "Failed to create session \(sessionNumber) in phase \(phaseNumber). Please try again."
        case .exerciseCreationFailed(let phaseNumber, let sessionNumber, let exerciseNumber):
            return "Failed to create exercise \(exerciseNumber) in session \(sessionNumber) of phase \(phaseNumber). Please try again."
        case .databaseError(let message):
            return message
        case .databaseDecodingError:
            return "Failed to process server response. Please try again."
        case .operationInProgress:
            return "Program creation already in progress. Please wait."
        }
    }
}
