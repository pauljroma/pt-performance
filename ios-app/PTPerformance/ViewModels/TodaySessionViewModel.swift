import Foundation
import SwiftUI

/// ViewModel for Today's Session screen
/// Fetches today's session and exercises from Supabase or backend API
@MainActor
class TodaySessionViewModel: ObservableObject {
    @Published var session: Session?
    @Published var exercises: [Exercise] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let supabase = PTSupabaseClient.shared

    /// Fetch today's session for the authenticated patient
    func fetchTodaySession() async {
        isLoading = true
        errorMessage = nil

        guard let patientId = supabase.userId else {
            errorMessage = "No patient ID available. Please log in again."
            isLoading = false
            return
        }

        print("📱 [TodaySession] Starting fetch for patient: \(patientId)")

        do {
            // Option 1: Call backend /today-session endpoint
            print("📱 [TodaySession] Trying backend API...")
            let response = try await fetchFromBackend(patientId: patientId)

            self.session = response.session
            self.exercises = response.exercises
            print("✅ [TodaySession] Backend API succeeded")
            isLoading = false
        } catch let backendError {
            // Fallback to direct Supabase query if backend unavailable
            print("⚠️ [TodaySession] Backend failed (\(backendError.localizedDescription)), trying Supabase...")

            do {
                try await fetchFromSupabase(patientId: patientId)
                print("✅ [TodaySession] Supabase fallback succeeded")
                isLoading = false
            } catch let supabaseError {
                print("❌ [TodaySession] Both backend and Supabase failed")
                print("   Backend error: \(backendError.localizedDescription)")
                print("   Supabase error: \(supabaseError.localizedDescription)")

                errorMessage = """
                Failed to load today's session.

                Please check:
                • Your internet connection
                • That you have an active program assigned

                Error: \(supabaseError.localizedDescription)
                """
                isLoading = false
            }
        }
    }

    /// Fetch from backend API (/today-session/:patientId)
    private func fetchFromBackend(patientId: String) async throws -> TodaySessionResponse {
        let backendURL = Config.backendURL
        print("📱 [TodaySession] Backend URL: \(backendURL)")

        guard let url = URL(string: "\(backendURL)/today-session/\(patientId)") else {
            print("❌ [TodaySession] Invalid backend URL: \(backendURL)")
            throw URLError(.badURL)
        }

        print("📱 [TodaySession] Calling: \(url.absoluteString)")
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ [TodaySession] No HTTP response")
            throw URLError(.badServerResponse)
        }

        print("📱 [TodaySession] Backend response status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ [TodaySession] Backend error response: \(responseString)")
            }
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(TodaySessionResponse.self, from: data)
    }

    /// Fetch directly from Supabase (fallback)
    private func fetchFromSupabase(patientId: String) async throws {
        print("📱 [TodaySession] Fetching session for patient: \(patientId)")
        print("📱 [TodaySession] Querying sessions table with filters:")
        print("   - phases.programs.patient_id = \(patientId)")
        print("   - phases.programs.status = active")

        // Query sessions via correct relationship chain: sessions -> phases -> programs
        // Use the first active session from the patient's active program
        let sessionsResponse: [Session] = try await supabase.client
            .from("sessions")
            .select("""
                *,
                phases!inner(
                    id,
                    name,
                    program_id,
                    programs!inner(
                        id,
                        name,
                        patient_id,
                        status
                    )
                )
            """)
            .eq("phases.programs.patient_id", value: patientId)
            .eq("phases.programs.status", value: "active")
            .order("sequence", ascending: true)
            .limit(1)
            .execute()
            .value

        print("📱 [TodaySession] Supabase returned \(sessionsResponse.count) sessions")

        guard let session = sessionsResponse.first else {
            print("⚠️ [TodaySession] No sessions found - possible causes:")
            print("   1. Patient has no active program (check programs table)")
            print("   2. Active program has no phases (check phases table)")
            print("   3. Phases have no sessions (check sessions table)")
            print("   4. Database relationship joins failing (check foreign keys)")
            // No active sessions found
            self.session = nil
            self.exercises = []
            return
        }

        print("✅ [TodaySession] Found session: \(session.name) (ID: \(session.id))")
        self.session = session

        // Fetch exercises for this session
        do {
            let exercisesResponse: [Exercise] = try await supabase.client
                .from("session_exercises")
                .select("""
                    *,
                    exercise_templates!inner(
                        id,
                        name,
                        category,
                        body_region
                    )
                """)
                .eq("session_id", value: session.id)
                .order("sequence", ascending: true)
                .execute()
                .value

            print("✅ [TodaySession] Found \(exercisesResponse.count) exercises")
            self.exercises = exercisesResponse
        } catch {
            // If exercise fetch fails, still show session but with empty exercises
            print("⚠️ [TodaySession] Failed to fetch exercises: \(error.localizedDescription)")
            self.exercises = []
        }
    }

    /// Refresh data
    func refresh() async {
        await fetchTodaySession()
    }
}
