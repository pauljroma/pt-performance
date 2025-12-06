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
            errorMessage = "No patient ID available"
            isLoading = false
            return
        }

        do {
            // Option 1: Call backend /today-session endpoint
            let response = try await fetchFromBackend(patientId: patientId)

            self.session = response.session
            self.exercises = response.exercises
            isLoading = false
        } catch {
            // Fallback to direct Supabase query if backend unavailable
            do {
                try await fetchFromSupabase(patientId: patientId)
                isLoading = false
            } catch {
                errorMessage = "Failed to load today's session: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    /// Fetch from backend API (/today-session/:patientId)
    private func fetchFromBackend(patientId: String) async throws -> TodaySessionResponse {
        let backendURL = ProcessInfo.processInfo.environment["BACKEND_URL"] ?? "http://localhost:3000"

        guard let url = URL(string: "\(backendURL)/today-session/\(patientId)") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(TodaySessionResponse.self, from: data)
    }

    /// Fetch directly from Supabase (fallback)
    private func fetchFromSupabase(patientId: String) async throws {
        // Get today's date
        let today = Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let todayStr = formatter.string(from: today)

        // Query sessions for today
        let sessionsResponse: [Session] = try await supabase.client.database
            .from("sessions")
            .select("""
                *,
                programs!inner(patient_id)
            """)
            .eq("programs.patient_id", value: patientId)
            .eq("session_date", value: todayStr)
            .limit(1)
            .execute()
            .value

        guard let session = sessionsResponse.first else {
            // No session for today
            self.session = nil
            self.exercises = []
            return
        }

        self.session = session

        // Fetch exercises for this session
        let exercisesResponse: [Exercise] = try await supabase.client.database
            .from("session_exercises")
            .select("""
                *,
                exercise_templates!inner(
                    exercise_name,
                    movement_pattern,
                    equipment
                )
            """)
            .eq("session_id", value: session.id)
            .order("exercise_order")
            .execute()
            .value

        self.exercises = exercisesResponse
    }

    /// Refresh data
    func refresh() async {
        await fetchTodaySession()
    }
}
