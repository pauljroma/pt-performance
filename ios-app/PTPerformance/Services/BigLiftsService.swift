import Foundation
import Supabase

// MARK: - RPC Parameters

/// RPC parameters for get_big_lifts_summary function
private struct GetBigLiftsSummaryParams: Encodable {
    let pPatientId: String

    enum CodingKeys: String, CodingKey {
        case pPatientId = "p_patient_id"
    }
}

// MARK: - Big Lifts Service

/// Service for fetching big lifts summary data from Supabase
/// Uses the get_big_lifts_summary RPC function for efficient aggregated data
class BigLiftsService {
    // MARK: - Singleton

    static let shared = BigLiftsService()

    private let supabase: PTSupabaseClient
    private let logger = DebugLogger.shared

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
    }

    // MARK: - Fetch Big Lifts Summary

    /// Fetch big lifts summary data for a patient
    /// - Parameter patientId: The patient's UUID
    /// - Returns: Array of BigLiftSummary for each big lift exercise
    /// - Throws: Network or decoding errors
    func fetchBigLiftsSummary(patientId: UUID) async throws -> [BigLiftSummary] {
        logger.log("BigLiftsService: Fetching big lifts summary for patient \(patientId)", level: .diagnostic)

        let params = GetBigLiftsSummaryParams(pPatientId: patientId.uuidString)

        let response = try await supabase.client
            .rpc("get_big_lifts_summary", params: params)
            .execute()

        // Debug log response
        #if DEBUG
        if let rawJSON = String(data: response.data, encoding: .utf8) {
            logger.log("BigLiftsService: Response data: \(rawJSON.prefix(500))", level: .diagnostic)
        }
        #endif

        // Use the shared flexible decoder from PTSupabaseClient
        let summaries = try PTSupabaseClient.flexibleDecoder.decode([BigLiftSummary].self, from: response.data)

        logger.log("BigLiftsService: Fetched \(summaries.count) big lifts", level: .success)

        return summaries
    }

    /// Fetch big lifts summary with optional filtering to core lifts only
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - coreLiftsOnly: If true, only returns Bench Press, Squat, and Deadlift
    /// - Returns: Filtered array of BigLiftSummary
    func fetchBigLiftsSummary(patientId: UUID, coreLiftsOnly: Bool) async throws -> [BigLiftSummary] {
        let allLifts = try await fetchBigLiftsSummary(patientId: patientId)

        if coreLiftsOnly {
            let coreNames = [
                BigLift.benchPress.rawValue,
                BigLift.squat.rawValue,
                BigLift.deadlift.rawValue
            ]
            return allLifts.filter { coreNames.contains($0.exerciseName) }
        }

        return allLifts
    }
}

// MARK: - Big Lifts Service Error

enum BigLiftsServiceError: LocalizedError {
    case invalidPatientId
    case noData
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidPatientId:
            return "Invalid patient ID provided"
        case .noData:
            return "No big lifts data available"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidPatientId:
            return "Please sign in again"
        case .noData:
            return "Log some exercises to see your big lifts progress"
        case .networkError:
            return "Check your internet connection and try again"
        }
    }
}
