import SwiftUI
import Supabase

/// ViewModel for program viewer
@MainActor
class ProgramViewModel: ObservableObject {
    @Published var program: Program?
    @Published var phases: [Phase] = []
    @Published var sessionsByPhase: [String: [ProgramSession]] = [:]
    @Published var exercisesBySession: [String: [ProgramExercise]] = [:]

    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase: PTSupabaseClient

    @MainActor
    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
    }

    /// Fetch program structure
    func fetchProgram(for patientId: String) async {
        let logger = DebugLogger.shared
        isLoading = true
        errorMessage = nil

        logger.log("🏋️ Starting fetchProgram for patient: \(patientId)")

        do {
            // 1. Fetch program(s) - Handle 0 or multiple programs gracefully
            logger.log("🏋️ Step 1: Fetching program...")
            let programResponse = try await supabase.client
                .from("programs")
                .select()
                .eq("patient_id", value: patientId)
                .order("created_at", ascending: false)  // Most recent first
                .limit(1)
                .execute()

            logger.log("🏋️ Program response size: \(programResponse.data.count) bytes")
            if let jsonString = String(data: programResponse.data, encoding: .utf8) {
                logger.log("🏋️ Program JSON: \(jsonString.prefix(500))")
            }

            let decoder = PTSupabaseClient.flexibleDecoder

            // Decode as array and get first
            let programs = try decoder.decode([Program].self, from: programResponse.data)

            guard let firstProgram = programs.first else {
                logger.log("No program found for patient", level: .warning)
                self.program = nil
                self.phases = []
                self.sessionsByPhase = [:]
                self.exercisesBySession = [:]
                isLoading = false
                return  // No program - exit gracefully without error
            }

            program = firstProgram
            logger.log("✅ Program decoded successfully: \(program?.name ?? "unknown")", level: .success)

            guard let programId = program?.id else {
                logger.log("No program found for patient", level: .error)
                throw NSError(domain: "ProgramViewModel", code: 404, userInfo: [NSLocalizedDescriptionKey: "No program found"])
            }

            // 2. Fetch phases
            logger.log("🏋️ Step 2: Fetching phases for program: \(programId)")
            let phasesResponse = try await supabase.client
                .from("phases")
                .select()
                .eq("program_id", value: programId)
                .order("phase_number", ascending: true)
                .execute()

            logger.log("🏋️ Phases response size: \(phasesResponse.data.count) bytes")
            if let jsonString = String(data: phasesResponse.data, encoding: .utf8) {
                logger.log("🏋️ Phases JSON: \(jsonString.prefix(500))")
            }

            phases = try decoder.decode([Phase].self, from: phasesResponse.data)
            logger.log("✅ Decoded \(phases.count) phases", level: .success)

            // 3. Fetch sessions for all phases in parallel using async let
            logger.log("🏋️ Step 3: Fetching sessions for all phases in parallel")
            try await withThrowingTaskGroup(of: (String, [ProgramSession]).self) { group in
                for phase in phases {
                    group.addTask {
                        let sessionsResponse = try await self.supabase.client
                            .from("sessions")
                            .select()
                            .eq("phase_id", value: phase.id)
                            .order("session_number", ascending: true)
                            .execute()

                        let sessions = try decoder.decode([ProgramSession].self, from: sessionsResponse.data)
                        return (phase.id.uuidString, sessions)
                    }
                }

                for try await (phaseId, sessions) in group {
                    sessionsByPhase[phaseId] = sessions
                    logger.log("✅ Decoded \(sessions.count) sessions for phase: \(phaseId)", level: .success)
                }
            }

            // 4. Fetch exercises for all sessions in parallel
            logger.log("🏋️ Step 4: Fetching exercises for all sessions in parallel")
            let allSessions = sessionsByPhase.values.flatMap { $0 }
            try await withThrowingTaskGroup(of: (String, [ProgramExercise]).self) { group in
                for session in allSessions {
                    group.addTask {
                        let exercisesResponse = try await self.supabase.client
                            .from("session_exercises")
                            .select("""
                                id,
                                session_id,
                                exercise_templates!inner(exercise_name),
                                prescribed_sets,
                                prescribed_reps,
                                prescribed_load,
                                load_unit,
                                rest_period_seconds,
                                order_index
                            """)
                            .eq("session_id", value: session.id)
                            .order("order_index", ascending: true)
                            .execute()

                        let exercises = try decoder.decode([ProgramExercise].self, from: exercisesResponse.data)
                        return (session.id.uuidString, exercises)
                    }
                }

                for try await (sessionId, exercises) in group {
                    exercisesBySession[sessionId] = exercises
                    logger.log("✅ Decoded \(exercises.count) exercises for session: \(sessionId)", level: .success)
                }
            }

            logger.log("✅ ✅ ✅ PROGRAM FULLY LOADED", level: .success)
            isLoading = false
        } catch let decodingError as DecodingError {
            logger.log("❌ PROGRAM DECODING ERROR:", level: .error)
            switch decodingError {
            case .typeMismatch(let type, let context):
                logger.log("Type mismatch: Expected \(type)", level: .error)
                logger.log("Context: \(context.debugDescription)", level: .error)
                logger.log("Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))", level: .error)
            case .valueNotFound(let type, let context):
                logger.log("Value not found: \(type)", level: .error)
                logger.log("Context: \(context.debugDescription)", level: .error)
            case .keyNotFound(let key, let context):
                logger.log("Key not found: \(key.stringValue)", level: .error)
                logger.log("Context: \(context.debugDescription)", level: .error)
            case .dataCorrupted(let context):
                logger.log("Data corrupted: \(context.debugDescription)", level: .error)
            @unknown default:
                logger.log("Unknown decoding error: \(decodingError)", level: .error)
            }
            errorMessage = decodingError.localizedDescription
            isLoading = false
        } catch {
            logger.log("❌ PROGRAM OTHER ERROR: \(error)", level: .error)
            logger.log("Error type: \(type(of: error))", level: .error)
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    /// Get sessions for a phase
    func sessions(for phase: Phase) -> [ProgramSession] {
        sessionsByPhase[phase.id.uuidString] ?? []
    }

    /// Get exercises for a session
    func exercises(for session: ProgramSession) -> [ProgramExercise] {
        exercisesBySession[session.id.uuidString] ?? []
    }
}
