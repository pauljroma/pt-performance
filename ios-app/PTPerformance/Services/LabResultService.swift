import Foundation

/// Service for managing lab results
@MainActor
final class LabResultService: ObservableObject {
    static let shared = LabResultService()

    @Published private(set) var labResults: [LabResult] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    private let supabase = PTSupabaseClient.shared

    private init() {}

    // MARK: - CRUD Operations

    func fetchLabResults() async {
        isLoading = true
        error = nil

        do {
            guard let patientId = try await getPatientId() else { return }

            let results: [LabResult] = try await supabase.client
                .from("lab_results")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .order("test_date", ascending: false)
                .execute()
                .value

            self.labResults = results
        } catch {
            self.error = error
            DebugLogger.shared.error("LabResultService", "Failed to fetch lab results: \(error)")
        }

        isLoading = false
    }

    func addLabResult(_ result: LabResult) async throws {
        try await supabase.client
            .from("lab_results")
            .insert(result)
            .execute()

        await fetchLabResults()
    }

    func deleteLabResult(_ id: UUID) async throws {
        try await supabase.client
            .from("lab_results")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()

        await fetchLabResults()
    }

    // MARK: - AI Analysis

    func analyzeLabResult(_ result: LabResult) async throws -> String {
        // TODO: Integrate with AI service for lab analysis
        return "Analysis pending integration with AI service."
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
