import Foundation
import Supabase

/// Data point for pain trend chart
struct PainDataPoint: Codable, Identifiable {
    let id: String
    let date: Date
    let painScore: Double
    let sessionNumber: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case date = "logged_date"
        case painScore = "avg_pain"
        case sessionNumber = "session_number"
    }
}

/// Adherence data
struct AdherenceData: Codable {
    let adherencePercentage: Double
    let completedSessions: Int
    let totalSessions: Int
    let weeklyBreakdown: [WeeklyAdherence]?

    enum CodingKeys: String, CodingKey {
        case adherencePercentage = "adherence_pct"
        case completedSessions = "completed_sessions"
        case totalSessions = "total_sessions"
        case weeklyBreakdown = "weekly_breakdown"
    }
}

struct WeeklyAdherence: Codable, Identifiable {
    let id: String
    let weekNumber: Int
    let adherencePercentage: Double

    enum CodingKeys: String, CodingKey {
        case id
        case weekNumber = "week_number"
        case adherencePercentage = "adherence_pct"
    }
}

/// Session summary for history list
struct SessionSummary: Codable, Identifiable {
    let id: String
    let sessionNumber: Int
    let sessionDate: Date
    let completed: Bool
    let exerciseCount: Int
    let avgPainScore: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case sessionNumber = "session_number"
        case sessionDate = "session_date"
        case completed
        case exerciseCount = "exercise_count"
        case avgPainScore = "avg_pain_score"
    }
}

/// Service for fetching analytics data
class AnalyticsService {
    private let supabase: SupabaseClient

    init(supabase: SupabaseClient = .shared) {
        self.supabase = supabase
    }

    /// Fetch pain trend data from vw_pain_trend view
    func fetchPainTrend(patientId: String, days: Int = 14) async throws -> [PainDataPoint] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        let response = try await supabase.client
            .from("vw_pain_trend")
            .select()
            .eq("patient_id", value: patientId)
            .gte("logged_date", value: ISO8601DateFormatter().string(from: startDate))
            .order("logged_date", ascending: true)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let dataPoints = try decoder.decode([PainDataPoint].self, from: response.data)
        return dataPoints
    }

    /// Fetch adherence data from vw_patient_adherence view
    func fetchAdherence(patientId: String, days: Int = 30) async throws -> AdherenceData {
        let response = try await supabase.client
            .from("vw_patient_adherence")
            .select()
            .eq("patient_id", value: patientId)
            .single()
            .execute()

        let adherence = try JSONDecoder().decode(AdherenceData.self, from: response.data)
        return adherence
    }

    /// Fetch recent session summaries
    func fetchRecentSessions(patientId: String, limit: Int = 10) async throws -> [SessionSummary] {
        let response = try await supabase.client
            .from("sessions")
            .select("""
                id,
                session_number,
                session_date,
                completed,
                exercise_count:session_exercises(count)
            """)
            .eq("patient_id", value: patientId)
            .order("session_date", ascending: false)
            .limit(limit)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let sessions = try decoder.decode([SessionSummary].self, from: response.data)
        return sessions
    }

    /// Fetch summary statistics
    func fetchSummaryStats(patientId: String) async throws -> SummaryStats {
        // Fetch adherence
        let adherence = try await fetchAdherence(patientId: patientId, days: 30)

        // Fetch recent pain trend
        let painTrend = try await fetchPainTrend(patientId: patientId, days: 7)
        let avgPain = painTrend.isEmpty ? 0.0 : painTrend.map { $0.painScore }.reduce(0, +) / Double(painTrend.count)

        return SummaryStats(
            adherencePercentage: adherence.adherencePercentage,
            avgPainScore: avgPain,
            completedSessions: adherence.completedSessions,
            totalSessions: adherence.totalSessions
        )
    }
}

/// Summary statistics
struct SummaryStats {
    let adherencePercentage: Double
    let avgPainScore: Double
    let completedSessions: Int
    let totalSessions: Int
}
