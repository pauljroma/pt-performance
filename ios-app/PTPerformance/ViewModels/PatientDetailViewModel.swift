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

    // Section-specific error tracking for partial loading
    @Published var flagsError: String?
    @Published var painTrendError: String?
    @Published var adherenceError: String?
    @Published var recentSessionsError: String?

    private let supabase: PTSupabaseClient
    private let analyticsService: AnalyticsService

    @MainActor
    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
        self.analyticsService = AnalyticsService(supabase: supabase)
    }

    /// Fetch all patient detail data with graceful degradation
    /// Each section loads independently - failures don't block other sections
    func fetchData(for patientId: String) async {
        isLoading = true
        errorMessage = nil

        // Clear previous section errors
        flagsError = nil
        painTrendError = nil
        adherenceError = nil
        recentSessionsError = nil

        DebugLogger.shared.log("[PatientDetail] Starting data fetch for patient: \(patientId)", level: .diagnostic)

        // Fetch each section in parallel - failures are isolated
        async let flags: Void = fetchFlagsSection(patientId: patientId)
        async let pain: Void = fetchPainTrendSection(patientId: patientId)
        async let adherence: Void = fetchAdherenceSection(patientId: patientId)
        async let sessions: Void = fetchRecentSessionsSection(patientId: patientId)
        _ = await (flags, pain, adherence, sessions)

        // Check if all sections failed
        let allFailed = flagsError != nil && painTrendError != nil && adherenceError != nil && recentSessionsError != nil
        if allFailed {
            errorMessage = "Unable to load patient data. Please check your connection and try again."
        }

        isLoading = false
        DebugLogger.shared.log("[PatientDetail] Data fetch complete", level: .success)
    }

    // MARK: - Individual Section Fetchers

    private func fetchFlagsSection(patientId: String) async {
        do {
            flags = try await fetchFlags(patientId: patientId)
            DebugLogger.shared.log("[PatientDetail] Loaded \(flags.count) flags", level: .success)
        } catch {
            DebugLogger.shared.error("PatientDetailViewModel", "Flags error: \(error.localizedDescription)")
            flagsError = "Unable to load flags"
            flags = []
        }
    }

    private func fetchPainTrendSection(patientId: String) async {
        do {
            painTrend = try await analyticsService.fetchPainTrend(patientId: patientId, days: 14)
            DebugLogger.shared.log("[PatientDetail] Loaded pain trend (\(painTrend.count) points)", level: .success)
        } catch {
            DebugLogger.shared.error("PatientDetailViewModel", "Pain trend error: \(error.localizedDescription)")
            painTrendError = "Unable to load pain trend"
            painTrend = []
        }
    }

    private func fetchAdherenceSection(patientId: String) async {
        do {
            adherence = try await analyticsService.fetchAdherence(patientId: patientId, days: 30)
            DebugLogger.shared.log("[PatientDetail] Loaded adherence data", level: .success)
        } catch {
            DebugLogger.shared.error("PatientDetailViewModel", "Adherence error: \(error.localizedDescription)")
            adherenceError = "Unable to load adherence"
            adherence = nil
        }
    }

    private func fetchRecentSessionsSection(patientId: String) async {
        do {
            recentSessions = try await analyticsService.fetchRecentSessions(patientId: patientId, limit: 5)
            DebugLogger.shared.log("[PatientDetail] Loaded \(recentSessions.count) recent sessions", level: .success)
        } catch {
            DebugLogger.shared.error("PatientDetailViewModel", "Recent sessions error: \(error.localizedDescription)")
            recentSessionsError = "Unable to load recent sessions"
            recentSessions = []
        }
    }

    /// Fetch patient flags
    private func fetchFlags(patientId: String) async throws -> [PatientFlag] {
        let response = try await supabase.client
            .from("patient_flags")
            .select()
            .eq("patient_id", value: patientId)
            .is("resolved_at", value: nil)
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
