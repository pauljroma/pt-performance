import Foundation
import SwiftUI
import Supabase

/// ViewModel for patient detail view
@MainActor
class PatientDetailViewModel: ObservableObject {
    @Published var flags: [PatientFlag] = []
    @Published var painTrend: [PainDataPoint] = []
    @Published var adherence: AdherenceData?
    @Published var recentSessions: [SessionSummary] = []

    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase: PTSupabaseClient
    private let analyticsService: AnalyticsService

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
        self.analyticsService = AnalyticsService(supabase: supabase)
    }

    /// Fetch all patient detail data
    func fetchData(for patientId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch all data in parallel
            async let flagsTask = fetchFlags(patientId: patientId)
            async let painTask = analyticsService.fetchPainTrend(patientId: patientId, days: 14)
            async let adherenceTask = analyticsService.fetchAdherence(patientId: patientId, days: 30)
            async let sessionsTask = analyticsService.fetchRecentSessions(patientId: patientId, limit: 5)

            let (f, p, a, s) = try await (flagsTask, painTask, adherenceTask, sessionsTask)

            flags = f
            painTrend = p
            adherence = a
            recentSessions = s

            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    /// Fetch patient flags
    private func fetchFlags(patientId: String) async throws -> [PatientFlag] {
        let response = try await supabase.client
            .from("patient_flags")
            .select()
            .eq("patient_id", value: patientId)
            .is("resolved_at", value: "null")
            .order("severity", ascending: false)
            .order("created_at", ascending: false)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode([PatientFlag].self, from: response.data)
    }

    /// Get top 3 highest severity flags
    var topFlags: [PatientFlag] {
        Array(flags.prefix(3))
    }

    /// Check if patient has any high severity flags
    var hasHighSeverityFlags: Bool {
        flags.contains { $0.severity == "HIGH" }
    }
}
