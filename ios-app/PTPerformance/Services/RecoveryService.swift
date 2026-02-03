import Foundation

/// Service for recovery protocol tracking
@MainActor
final class RecoveryService: ObservableObject {
    static let shared = RecoveryService()

    @Published private(set) var sessions: [RecoverySession] = []
    @Published private(set) var recommendations: [RecoveryRecommendation] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    private let supabase = PTSupabaseClient.shared

    private init() {}

    // MARK: - Fetch Sessions

    func fetchSessions(days: Int = 30) async {
        isLoading = true
        error = nil

        do {
            guard let patientId = try await getPatientId() else { return }

            let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

            let results: [RecoverySession] = try await supabase.client
                .from("recovery_sessions")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .gte("start_time", value: ISO8601DateFormatter().string(from: startDate))
                .order("start_time", ascending: false)
                .execute()
                .value

            self.sessions = results
        } catch {
            self.error = error
            DebugLogger.shared.error("RecoveryService", "Failed to fetch sessions: \(error)")
        }

        isLoading = false
    }

    // MARK: - Log Session

    func logSession(
        protocolType: RecoveryProtocolType,
        duration: Int,
        temperature: Double? = nil,
        heartRateAvg: Int? = nil,
        heartRateMax: Int? = nil,
        perceivedEffort: Int? = nil,
        notes: String? = nil
    ) async throws {
        guard let patientId = try await getPatientId() else {
            throw NSError(domain: "RecoveryService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No patient ID found"])
        }

        let session = RecoverySession(
            id: UUID(),
            patientId: patientId,
            protocolType: protocolType,
            startTime: Date(),
            duration: duration,
            temperature: temperature,
            heartRateAvg: heartRateAvg,
            heartRateMax: heartRateMax,
            perceivedEffort: perceivedEffort,
            notes: notes,
            createdAt: Date()
        )

        try await supabase.client
            .from("recovery_sessions")
            .insert(session)
            .execute()

        await fetchSessions()
    }

    // MARK: - Recommendations

    func generateRecommendations() async {
        // AI-based recommendations based on training load, sleep, readiness
        // For now, return static recommendations
        recommendations = [
            RecoveryRecommendation(
                id: UUID(),
                protocolType: .sauna,
                reason: "High training volume this week",
                priority: .high,
                suggestedDuration: 20
            ),
            RecoveryRecommendation(
                id: UUID(),
                protocolType: .coldPlunge,
                reason: "Optimize post-workout recovery",
                priority: .medium,
                suggestedDuration: 3
            )
        ]
    }

    // MARK: - Statistics

    func weeklyStats() -> (totalSessions: Int, totalMinutes: Int, favoriteProtocol: RecoveryProtocolType?) {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weeklySessions = sessions.filter { $0.startTime >= weekAgo }

        let totalMinutes = weeklySessions.reduce(0) { $0 + $1.duration / 60 }

        let protocolCounts = Dictionary(grouping: weeklySessions, by: { $0.protocolType })
        let favorite = protocolCounts.max(by: { $0.value.count < $1.value.count })?.key

        return (weeklySessions.count, totalMinutes, favorite)
    }

    // MARK: - Helpers

    private func getPatientId() async throws -> UUID? {
        guard let userId = supabase.client.auth.currentUser?.id else { return nil }

        struct PatientRow: Decodable {
            let id: UUID
        }

        let patients: [PatientRow] = try await supabase.client
            .from("patients")
            .select("id")
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        return patients.first?.id
    }
}
