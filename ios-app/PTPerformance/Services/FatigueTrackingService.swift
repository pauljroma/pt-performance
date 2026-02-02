import Foundation
import Supabase
import SwiftUI

// MARK: - Encodable Structs for Supabase RPC

/// RPC parameters for fatigue calculation
private struct CalculateFatigueParams: Encodable {
    let pPatientId: String

    enum CodingKeys: String, CodingKey {
        case pPatientId = "p_patient_id"
    }
}

// MARK: - Fatigue Tracking Models

/// Fatigue band levels for display and recommendations
enum FatigueBand: String, Codable, CaseIterable {
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case critical = "critical"

    /// Color for UI display
    var color: Color {
        switch self {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }

    /// SF Symbol icon name
    var icon: String {
        switch self {
        case .low: return "battery.100"
        case .moderate: return "battery.75"
        case .high: return "battery.25"
        case .critical: return "battery.0"
        }
    }

    /// Human-readable description
    var description: String {
        switch self {
        case .low:
            return "Low fatigue - Ready for full training"
        case .moderate:
            return "Moderate fatigue - Monitor recovery"
        case .high:
            return "High fatigue - Consider reducing load"
        case .critical:
            return "Critical fatigue - Deload recommended"
        }
    }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
}

/// Deload urgency levels
enum DeloadUrgency: String, Codable, CaseIterable {
    case none = "none"
    case suggested = "suggested"
    case recommended = "recommended"
    case required = "required"

    /// Title for UI display
    var title: String {
        switch self {
        case .none: return "No Deload Needed"
        case .suggested: return "Deload Suggested"
        case .recommended: return "Deload Recommended"
        case .required: return "Deload Required"
        }
    }

    /// Subtitle with additional context
    var subtitle: String {
        switch self {
        case .none:
            return "Continue training as planned"
        case .suggested:
            return "Consider a lighter week if fatigue persists"
        case .recommended:
            return "A deload week would benefit recovery"
        case .required:
            return "Immediate deload needed to prevent overtraining"
        }
    }

    /// Color for UI display
    var color: Color {
        switch self {
        case .none: return .green
        case .suggested: return .yellow
        case .recommended: return .orange
        case .required: return .red
        }
    }

    /// SF Symbol icon name
    var icon: String {
        switch self {
        case .none: return "checkmark.circle"
        case .suggested: return "info.circle"
        case .recommended: return "exclamationmark.triangle"
        case .required: return "exclamationmark.octagon"
        }
    }
}

/// Accumulated fatigue data for a patient
struct FatigueAccumulation: Codable, Identifiable {
    let id: UUID
    let patientId: UUID
    let calculationDate: Date

    // Readiness averages
    let avgReadiness7d: Double?
    let avgReadiness14d: Double?

    // Training load metrics
    let trainingLoad7d: Double?
    let trainingLoad14d: Double?
    let acuteChronicRatio: Double?

    // Fatigue indicators
    let consecutiveLowReadiness: Int
    let missedRepsCount7d: Int
    let highRpeCount7d: Int
    let painReports7d: Int

    // Calculated fatigue
    let fatigueScore: Double
    let fatigueBand: FatigueBand
    let deloadRecommended: Bool
    let deloadUrgency: DeloadUrgency

    // Metadata
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case calculationDate = "calculation_date"
        case avgReadiness7d = "avg_readiness_7d"
        case avgReadiness14d = "avg_readiness_14d"
        case trainingLoad7d = "training_load_7d"
        case trainingLoad14d = "training_load_14d"
        case acuteChronicRatio = "acute_chronic_ratio"
        case consecutiveLowReadiness = "consecutive_low_readiness"
        case missedRepsCount7d = "missed_reps_count_7d"
        case highRpeCount7d = "high_rpe_count_7d"
        case painReports7d = "pain_reports_7d"
        case fatigueScore = "fatigue_score"
        case fatigueBand = "fatigue_band"
        case deloadRecommended = "deload_recommended"
        case deloadUrgency = "deload_urgency"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Custom decoder to handle PostgreSQL numeric types
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        patientId = try container.decode(UUID.self, forKey: .patientId)
        calculationDate = try container.decode(Date.self, forKey: .calculationDate)

        // Handle numeric fields that might come as strings from PostgreSQL
        avgReadiness7d = try Self.decodeOptionalDouble(container: container, key: .avgReadiness7d)
        avgReadiness14d = try Self.decodeOptionalDouble(container: container, key: .avgReadiness14d)
        trainingLoad7d = try Self.decodeOptionalDouble(container: container, key: .trainingLoad7d)
        trainingLoad14d = try Self.decodeOptionalDouble(container: container, key: .trainingLoad14d)
        acuteChronicRatio = try Self.decodeOptionalDouble(container: container, key: .acuteChronicRatio)

        consecutiveLowReadiness = try container.decodeIfPresent(Int.self, forKey: .consecutiveLowReadiness) ?? 0
        missedRepsCount7d = try container.decodeIfPresent(Int.self, forKey: .missedRepsCount7d) ?? 0
        highRpeCount7d = try container.decodeIfPresent(Int.self, forKey: .highRpeCount7d) ?? 0
        painReports7d = try container.decodeIfPresent(Int.self, forKey: .painReports7d) ?? 0

        // Handle fatigue score
        if let scoreString = try? container.decode(String.self, forKey: .fatigueScore) {
            fatigueScore = Double(scoreString) ?? 0.0
        } else {
            fatigueScore = try container.decodeIfPresent(Double.self, forKey: .fatigueScore) ?? 0.0
        }

        fatigueBand = try container.decode(FatigueBand.self, forKey: .fatigueBand)
        deloadRecommended = try container.decodeIfPresent(Bool.self, forKey: .deloadRecommended) ?? false
        deloadUrgency = try container.decode(DeloadUrgency.self, forKey: .deloadUrgency)

        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }

    private static func decodeOptionalDouble(
        container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) throws -> Double? {
        if let stringValue = try? container.decode(String.self, forKey: key) {
            return Double(stringValue)
        }
        return try container.decodeIfPresent(Double.self, forKey: key)
    }

    // Memberwise initializer for testing
    init(
        id: UUID,
        patientId: UUID,
        calculationDate: Date,
        avgReadiness7d: Double? = nil,
        avgReadiness14d: Double? = nil,
        trainingLoad7d: Double? = nil,
        trainingLoad14d: Double? = nil,
        acuteChronicRatio: Double? = nil,
        consecutiveLowReadiness: Int = 0,
        missedRepsCount7d: Int = 0,
        highRpeCount7d: Int = 0,
        painReports7d: Int = 0,
        fatigueScore: Double = 0.0,
        fatigueBand: FatigueBand = .low,
        deloadRecommended: Bool = false,
        deloadUrgency: DeloadUrgency = .none,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.patientId = patientId
        self.calculationDate = calculationDate
        self.avgReadiness7d = avgReadiness7d
        self.avgReadiness14d = avgReadiness14d
        self.trainingLoad7d = trainingLoad7d
        self.trainingLoad14d = trainingLoad14d
        self.acuteChronicRatio = acuteChronicRatio
        self.consecutiveLowReadiness = consecutiveLowReadiness
        self.missedRepsCount7d = missedRepsCount7d
        self.highRpeCount7d = highRpeCount7d
        self.painReports7d = painReports7d
        self.fatigueScore = fatigueScore
        self.fatigueBand = fatigueBand
        self.deloadRecommended = deloadRecommended
        self.deloadUrgency = deloadUrgency
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Fatigue Tracking Errors

enum FatigueTrackingError: LocalizedError {
    case fatigueCalculationFailed
    case noFatigueDataFound
    case trendFetchFailed
    case invalidPatientId
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .fatigueCalculationFailed:
            return "Failed to calculate fatigue accumulation"
        case .noFatigueDataFound:
            return "No fatigue data found for this patient"
        case .trendFetchFailed:
            return "Failed to fetch fatigue trend data"
        case .invalidPatientId:
            return "Invalid patient ID provided"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .fatigueCalculationFailed:
            return "Your fatigue data couldn't be calculated. Please try again later."
        case .noFatigueDataFound:
            return "Complete a few workouts to start seeing your fatigue trends."
        case .trendFetchFailed, .networkError:
            return "Please check your connection and try again."
        case .invalidPatientId:
            return "Please sign out and sign back in to refresh your session."
        }
    }
}

// MARK: - Fatigue Tracking Service

/// Service for managing fatigue tracking and accumulation data
/// Provides methods to fetch, calculate, and monitor fatigue levels
/// Uses database RPCs for fatigue calculations
@MainActor
class FatigueTrackingService: ObservableObject {
    static let shared = FatigueTrackingService()

    nonisolated(unsafe) private let client: PTSupabaseClient

    @Published var currentFatigue: FatigueAccumulation?
    @Published var isLoading: Bool = false
    @Published var error: String?

    nonisolated init(client: PTSupabaseClient = .shared) {
        self.client = client
    }

    // MARK: - Public API (matching requirements)

    /// Fetch the current fatigue accumulation for the logged-in patient
    /// - Returns: The current FatigueAccumulation if available
    /// - Throws: FatigueTrackingError if fetch fails
    func fetchCurrentFatigue() async throws -> FatigueAccumulation? {
        guard let patientId = UUID(uuidString: client.userId ?? "") else {
            throw FatigueTrackingError.invalidPatientId
        }
        try await fetchCurrentFatigue(patientId: patientId)
        return currentFatigue
    }

    /// Calculate fatigue accumulation for the logged-in patient
    /// - Returns: The calculated FatigueAccumulation
    /// - Throws: FatigueTrackingError if calculation fails
    func calculateFatigue() async throws -> FatigueAccumulation {
        guard let patientId = UUID(uuidString: client.userId ?? "") else {
            throw FatigueTrackingError.invalidPatientId
        }
        return try await calculateFatigue(patientId: patientId)
    }

    /// Get fatigue trend for the logged-in patient
    /// - Parameter days: Number of days to fetch (default 14)
    /// - Returns: Array of FatigueAccumulation records ordered by date
    /// - Throws: FatigueTrackingError if fetch fails
    func getFatigueTrend(days: Int = 14) async throws -> [FatigueAccumulation] {
        guard let patientId = UUID(uuidString: client.userId ?? "") else {
            throw FatigueTrackingError.invalidPatientId
        }
        return try await getFatigueTrend(patientId: patientId, days: days)
    }

    // MARK: - Fetch Current Fatigue

    /// Fetch the current/latest fatigue accumulation for a patient
    /// - Parameter patientId: The patient's UUID
    /// - Throws: FatigueTrackingError if fetch fails
    func fetchCurrentFatigue(patientId: UUID) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await client.client
                .from("fatigue_accumulation")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .order("calculation_date", ascending: false)
                .limit(1)
                .execute()

            guard !response.data.isEmpty else {
                currentFatigue = nil
                return
            }

            let results = try PTSupabaseClient.flexibleDecoder.decode(
                [FatigueAccumulation].self,
                from: response.data
            )
            currentFatigue = results.first

            #if DEBUG
            if let fatigue = currentFatigue {
                DebugLogger.shared.success("FATIGUE", """
                    Fetched current fatigue for patient \(patientId.uuidString.prefix(8)):
                    Score: \(fatigue.fatigueScore)
                    Band: \(fatigue.fatigueBand.displayName)
                    Deload: \(fatigue.deloadRecommended ? "Yes" : "No")
                    """)
            }
            #endif
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            DebugLogger.shared.error("FATIGUE", "Failed to fetch current fatigue: \(error.localizedDescription)")
            #endif
            throw FatigueTrackingError.networkError(error)
        }
    }

    // MARK: - Calculate Fatigue

    /// Trigger fatigue calculation for a patient via database RPC
    /// - Parameter patientId: The patient's UUID
    /// - Returns: The calculated FatigueAccumulation
    /// - Throws: FatigueTrackingError if calculation fails
    func calculateFatigue(patientId: UUID) async throws -> FatigueAccumulation {
        isLoading = true
        defer { isLoading = false }

        do {
            let params = CalculateFatigueParams(pPatientId: patientId.uuidString)
            let response = try await client.client
                .rpc("calculate_fatigue_accumulation", params: params)
                .execute()

            // Try to decode the result
            guard !response.data.isEmpty else {
                throw FatigueTrackingError.fatigueCalculationFailed
            }

            let fatigue = try PTSupabaseClient.flexibleDecoder.decode(
                FatigueAccumulation.self,
                from: response.data
            )

            currentFatigue = fatigue

            #if DEBUG
            DebugLogger.shared.success("FATIGUE", """
                Calculated fatigue for patient \(patientId.uuidString.prefix(8)):
                Score: \(fatigue.fatigueScore)
                Band: \(fatigue.fatigueBand.displayName)
                ACR: \(fatigue.acuteChronicRatio ?? 0.0)
                Deload: \(fatigue.deloadRecommended ? "Yes (\(fatigue.deloadUrgency.title))" : "No")
                """)
            #endif

            return fatigue
        } catch let fatigueError as FatigueTrackingError {
            self.error = fatigueError.localizedDescription
            throw fatigueError
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            DebugLogger.shared.error("FATIGUE", "Failed to calculate fatigue: \(error.localizedDescription)")
            #endif
            throw FatigueTrackingError.fatigueCalculationFailed
        }
    }

    // MARK: - Get Fatigue Trend

    /// Get fatigue trend data over a specified number of days
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - days: Number of days to fetch (default 14)
    /// - Returns: Array of FatigueAccumulation records ordered by date
    /// - Throws: FatigueTrackingError if fetch fails
    func getFatigueTrend(patientId: UUID, days: Int = 14) async throws -> [FatigueAccumulation] {
        isLoading = true
        defer { isLoading = false }

        // Calculate the start date
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else {
            throw FatigueTrackingError.trendFetchFailed
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDateString = dateFormatter.string(from: startDate)

        do {
            let response = try await client.client
                .from("fatigue_accumulation")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .gte("calculation_date", value: startDateString)
                .order("calculation_date", ascending: true)
                .execute()

            let results = try PTSupabaseClient.flexibleDecoder.decode(
                [FatigueAccumulation].self,
                from: response.data
            )

            #if DEBUG
            DebugLogger.shared.info("FATIGUE", """
                Fetched \(results.count) fatigue records for past \(days) days
                Patient: \(patientId.uuidString.prefix(8))
                """)
            #endif

            return results
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            DebugLogger.shared.error("FATIGUE", "Failed to fetch fatigue trend: \(error.localizedDescription)")
            #endif
            throw FatigueTrackingError.trendFetchFailed
        }
    }

    // MARK: - Helper Methods

    /// Check if a patient has high fatigue that needs attention
    /// - Parameter patientId: The patient's UUID
    /// - Returns: True if fatigue band is high or critical
    func hasHighFatigue(patientId: UUID) async -> Bool {
        do {
            try await fetchCurrentFatigue(patientId: patientId)
            guard let fatigue = currentFatigue else { return false }
            return fatigue.fatigueBand == .high || fatigue.fatigueBand == .critical
        } catch {
            return false
        }
    }

    /// Get a summary of current fatigue status
    /// - Returns: Optional tuple with fatigue band and score if available
    func getFatigueSummary() -> (band: FatigueBand, score: Double, urgency: DeloadUrgency)? {
        guard let fatigue = currentFatigue else { return nil }
        return (fatigue.fatigueBand, fatigue.fatigueScore, fatigue.deloadUrgency)
    }

    /// Clear any stored error
    func clearError() {
        error = nil
    }
}

// MARK: - Preview Helpers

extension FatigueAccumulation {
    /// Sample fatigue for SwiftUI previews
    static var sample: FatigueAccumulation {
        FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            avgReadiness7d: 65.0,
            avgReadiness14d: 70.0,
            trainingLoad7d: 1200.0,
            trainingLoad14d: 2200.0,
            acuteChronicRatio: 1.1,
            consecutiveLowReadiness: 2,
            missedRepsCount7d: 3,
            highRpeCount7d: 4,
            painReports7d: 1,
            fatigueScore: 55.0,
            fatigueBand: .moderate,
            deloadRecommended: false,
            deloadUrgency: .suggested,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    /// High fatigue sample for testing
    static var highFatigueSample: FatigueAccumulation {
        FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            avgReadiness7d: 45.0,
            avgReadiness14d: 55.0,
            trainingLoad7d: 1800.0,
            trainingLoad14d: 2400.0,
            acuteChronicRatio: 1.5,
            consecutiveLowReadiness: 4,
            missedRepsCount7d: 6,
            highRpeCount7d: 8,
            painReports7d: 3,
            fatigueScore: 78.0,
            fatigueBand: .critical,
            deloadRecommended: true,
            deloadUrgency: .required,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
