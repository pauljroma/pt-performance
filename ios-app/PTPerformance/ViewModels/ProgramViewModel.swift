import Foundation
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

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
    }

    /// Fetch program structure
    func fetchProgram(for patientId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 1. Fetch program
            let programResponse = try await supabase.client
                .from("programs")
                .select()
                .eq("patient_id", value: patientId)
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            program = try decoder.decode(Program.self, from: programResponse.data)

            guard let programId = program?.id else {
                throw NSError(domain: "ProgramViewModel", code: 404, userInfo: [NSLocalizedDescriptionKey: "No program found"])
            }

            // 2. Fetch phases
            let phasesResponse = try await supabase.client
                .from("phases")
                .select()
                .eq("program_id", value: programId)
                .order("phase_number", ascending: true)
                .execute()

            phases = try decoder.decode([Phase].self, from: phasesResponse.data)

            // 3. Fetch sessions for all phases
            for phase in phases {
                let sessionsResponse = try await supabase.client
                    .from("sessions")
                    .select()
                    .eq("phase_id", value: phase.id)
                    .order("session_number", ascending: true)
                    .execute()

                let sessions = try decoder.decode([ProgramSession].self, from: sessionsResponse.data)
                sessionsByPhase[phase.id] = sessions

                // 4. Fetch exercises for each session
                for session in sessions {
                    let exercisesResponse = try await supabase.client
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
                    exercisesBySession[session.id] = exercises
                }
            }

            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    /// Get sessions for a phase
    func sessions(for phase: Phase) -> [ProgramSession] {
        sessionsByPhase[phase.id] ?? []
    }

    /// Get exercises for a session
    func exercises(for session: ProgramSession) -> [ProgramExercise] {
        exercisesBySession[session.id] ?? []
    }
}
