import Foundation
import Supabase
import SwiftUI

// MARK: - Encodable Structs for Supabase

/// RPC parameters for activating deload
private struct ActivateDeloadParams: Encodable {
    let pRecommendationId: String
    let pPatientId: String
    let pStartDate: String

    enum CodingKeys: String, CodingKey {
        case pRecommendationId = "p_recommendation_id"
        case pPatientId = "p_patient_id"
        case pStartDate = "p_start_date"
    }
}

/// Update for dismissing a deload recommendation
private struct DismissRecommendationUpdate: Encodable {
    let status: String
    let dismissedAt: String
    let dismissalReason: String

    enum CodingKeys: String, CodingKey {
        case status
        case dismissedAt = "dismissed_at"
        case dismissalReason = "dismissal_reason"
    }
}

/// RPC parameters for checking if in deload period
private struct IsInDeloadPeriodParams: Encodable {
    let pPatientId: String

    enum CodingKeys: String, CodingKey {
        case pPatientId = "p_patient_id"
    }
}

// MARK: - Deload Recommendation Models

/// Summary of fatigue factors contributing to deload recommendation
struct FatigueSummary: Codable {
    let fatigueScore: Double
    let fatigueBand: String
    let avgReadiness7d: Double
    let acuteChronicRatio: Double
    let consecutiveLowDays: Int
    let contributingFactors: [String]

    enum CodingKeys: String, CodingKey {
        case fatigueScore = "fatigue_score"
        case fatigueBand = "fatigue_band"
        case avgReadiness7d = "avg_readiness_7d"
        case acuteChronicRatio = "acute_chronic_ratio"
        case consecutiveLowDays = "consecutive_low_days"
        case contributingFactors = "contributing_factors"
    }

    // Custom decoder to handle PostgreSQL numeric types
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle fatigue score as string or double
        if let scoreString = try? container.decode(String.self, forKey: .fatigueScore) {
            fatigueScore = Double(scoreString) ?? 0.0
        } else {
            fatigueScore = try container.decodeIfPresent(Double.self, forKey: .fatigueScore) ?? 0.0
        }

        fatigueBand = try container.decode(String.self, forKey: .fatigueBand)

        // Handle avgReadiness7d as string or double
        if let readinessString = try? container.decode(String.self, forKey: .avgReadiness7d) {
            avgReadiness7d = Double(readinessString) ?? 0.0
        } else {
            avgReadiness7d = try container.decodeIfPresent(Double.self, forKey: .avgReadiness7d) ?? 0.0
        }

        // Handle acuteChronicRatio as string or double
        if let acrString = try? container.decode(String.self, forKey: .acuteChronicRatio) {
            acuteChronicRatio = Double(acrString) ?? 0.0
        } else {
            acuteChronicRatio = try container.decodeIfPresent(Double.self, forKey: .acuteChronicRatio) ?? 0.0
        }

        consecutiveLowDays = try container.decodeIfPresent(Int.self, forKey: .consecutiveLowDays) ?? 0
        contributingFactors = try container.decodeIfPresent([String].self, forKey: .contributingFactors) ?? []
    }

    // Memberwise initializer for testing
    init(
        fatigueScore: Double,
        fatigueBand: String,
        avgReadiness7d: Double,
        acuteChronicRatio: Double,
        consecutiveLowDays: Int,
        contributingFactors: [String]
    ) {
        self.fatigueScore = fatigueScore
        self.fatigueBand = fatigueBand
        self.avgReadiness7d = avgReadiness7d
        self.acuteChronicRatio = acuteChronicRatio
        self.consecutiveLowDays = consecutiveLowDays
        self.contributingFactors = contributingFactors
    }
}

/// Prescription for a deload period
struct DeloadPrescription: Codable {
    let durationDays: Int
    let loadReductionPct: Double
    let volumeReductionPct: Double
    let focus: String
    let suggestedStartDate: Date

    enum CodingKeys: String, CodingKey {
        case durationDays = "duration_days"
        case loadReductionPct = "load_reduction_pct"
        case volumeReductionPct = "volume_reduction_pct"
        case focus
        case suggestedStartDate = "suggested_start_date"
    }

    // Custom decoder to handle PostgreSQL numeric types
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        durationDays = try container.decode(Int.self, forKey: .durationDays)

        // Handle loadReductionPct as string or double
        if let loadString = try? container.decode(String.self, forKey: .loadReductionPct) {
            loadReductionPct = Double(loadString) ?? 0.0
        } else {
            loadReductionPct = try container.decode(Double.self, forKey: .loadReductionPct)
        }

        // Handle volumeReductionPct as string or double
        if let volumeString = try? container.decode(String.self, forKey: .volumeReductionPct) {
            volumeReductionPct = Double(volumeString) ?? 0.0
        } else {
            volumeReductionPct = try container.decode(Double.self, forKey: .volumeReductionPct)
        }

        focus = try container.decode(String.self, forKey: .focus)
        suggestedStartDate = try container.decode(Date.self, forKey: .suggestedStartDate)
    }

    // Memberwise initializer for testing
    init(
        durationDays: Int,
        loadReductionPct: Double,
        volumeReductionPct: Double,
        focus: String,
        suggestedStartDate: Date
    ) {
        self.durationDays = durationDays
        self.loadReductionPct = loadReductionPct
        self.volumeReductionPct = volumeReductionPct
        self.focus = focus
        self.suggestedStartDate = suggestedStartDate
    }

    /// Formatted load reduction for display (e.g., "30%")
    var formattedLoadReduction: String {
        return String(format: "%.0f%%", loadReductionPct * 100)
    }

    /// Formatted volume reduction for display (e.g., "40%")
    var formattedVolumeReduction: String {
        return String(format: "%.0f%%", volumeReductionPct * 100)
    }

    /// Formatted date range for display
    var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let endDate = Calendar.current.date(byAdding: .day, value: durationDays, to: suggestedStartDate) ?? suggestedStartDate
        return "\(formatter.string(from: suggestedStartDate)) - \(formatter.string(from: endDate))"
    }
}

/// Full deload recommendation with reasoning and prescription
struct DeloadRecommendation: Codable, Identifiable {
    let id: UUID
    let patientId: UUID
    let deloadRecommended: Bool
    let urgency: DeloadUrgency
    let reasoning: String
    let fatigueSummary: FatigueSummary
    let deloadPrescription: DeloadPrescription?
    let createdAt: Date

    // Status tracking
    let status: DeloadRecommendationStatus?
    let activatedAt: Date?
    let dismissedAt: Date?
    let dismissalReason: String?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case deloadRecommended = "deload_recommended"
        case urgency
        case reasoning
        case fatigueSummary = "fatigue_summary"
        case deloadPrescription = "deload_prescription"
        case createdAt = "created_at"
        case status
        case activatedAt = "activated_at"
        case dismissedAt = "dismissed_at"
        case dismissalReason = "dismissal_reason"
    }

    // Memberwise initializer for testing
    init(
        id: UUID,
        patientId: UUID,
        deloadRecommended: Bool,
        urgency: DeloadUrgency,
        reasoning: String,
        fatigueSummary: FatigueSummary,
        deloadPrescription: DeloadPrescription?,
        createdAt: Date,
        status: DeloadRecommendationStatus? = nil,
        activatedAt: Date? = nil,
        dismissedAt: Date? = nil,
        dismissalReason: String? = nil
    ) {
        self.id = id
        self.patientId = patientId
        self.deloadRecommended = deloadRecommended
        self.urgency = urgency
        self.reasoning = reasoning
        self.fatigueSummary = fatigueSummary
        self.deloadPrescription = deloadPrescription
        self.createdAt = createdAt
        self.status = status
        self.activatedAt = activatedAt
        self.dismissedAt = dismissedAt
        self.dismissalReason = dismissalReason
    }
}

/// Status of a deload recommendation
enum DeloadRecommendationStatus: String, Codable {
    case pending = "pending"
    case activated = "activated"
    case dismissed = "dismissed"
    case expired = "expired"

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .activated: return "Activated"
        case .dismissed: return "Dismissed"
        case .expired: return "Expired"
        }
    }

    var color: Color {
        switch self {
        case .pending: return .yellow
        case .activated: return .blue
        case .dismissed: return .gray
        case .expired: return .secondary
        }
    }
}

/// User response status for deload recommendations as per Smart Recovery sprint specification
/// Note: Different from DeloadStatus in DeloadEvent.swift which tracks execution status
enum DeloadResponseStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case dismissed = "dismissed"
    case completed = "completed"

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .accepted: return "Accepted"
        case .dismissed: return "Dismissed"
        case .completed: return "Completed"
        }
    }

    var color: Color {
        switch self {
        case .pending: return .yellow
        case .accepted: return .blue
        case .dismissed: return .gray
        case .completed: return .green
        }
    }
}

/// Focus area during deload period
enum DeloadFocus: String, Codable, CaseIterable {
    case technique = "technique"
    case mobility = "mobility"
    case activeRecovery = "active_recovery"
    case completeRest = "complete_rest"

    var displayName: String {
        switch self {
        case .technique: return "Technique Work"
        case .mobility: return "Mobility Focus"
        case .activeRecovery: return "Active Recovery"
        case .completeRest: return "Complete Rest"
        }
    }

    var description: String {
        switch self {
        case .technique:
            return "Focus on movement quality with lighter loads"
        case .mobility:
            return "Emphasize flexibility and joint mobility work"
        case .activeRecovery:
            return "Light activity to promote blood flow and recovery"
        case .completeRest:
            return "Full rest from training to maximize recovery"
        }
    }

    var icon: String {
        switch self {
        case .technique: return "figure.stand"
        case .mobility: return "figure.flexibility"
        case .activeRecovery: return "figure.walk"
        case .completeRest: return "bed.double.fill"
        }
    }
}

/// Type alias for API compatibility with Smart Recovery sprint specification
typealias ActiveDeload = ActiveDeloadPeriod

/// Active deload period tracking
struct ActiveDeloadPeriod: Codable, Identifiable {
    let id: UUID
    let patientId: UUID
    let recommendationId: UUID?
    let startDate: Date
    let endDate: Date
    let loadReductionPct: Double
    let volumeReductionPct: Double
    let focus: String?
    let isActive: Bool
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case recommendationId = "recommendation_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case loadReductionPct = "load_reduction_pct"
        case volumeReductionPct = "volume_reduction_pct"
        case focus
        case isActive = "is_active"
        case createdAt = "created_at"
    }

    // Custom decoder to handle PostgreSQL numeric types
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        patientId = try container.decode(UUID.self, forKey: .patientId)
        recommendationId = try container.decodeIfPresent(UUID.self, forKey: .recommendationId)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decode(Date.self, forKey: .endDate)

        // Handle loadReductionPct as string or double
        if let loadString = try? container.decode(String.self, forKey: .loadReductionPct) {
            loadReductionPct = Double(loadString) ?? 0.0
        } else {
            loadReductionPct = try container.decode(Double.self, forKey: .loadReductionPct)
        }

        // Handle volumeReductionPct as string or double
        if let volumeString = try? container.decode(String.self, forKey: .volumeReductionPct) {
            volumeReductionPct = Double(volumeString) ?? 0.0
        } else {
            volumeReductionPct = try container.decode(Double.self, forKey: .volumeReductionPct)
        }

        focus = try container.decodeIfPresent(String.self, forKey: .focus)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
    }

    // Memberwise initializer for testing
    init(
        id: UUID,
        patientId: UUID,
        recommendationId: UUID? = nil,
        startDate: Date,
        endDate: Date,
        loadReductionPct: Double,
        volumeReductionPct: Double,
        focus: String? = nil,
        isActive: Bool = true,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.patientId = patientId
        self.recommendationId = recommendationId
        self.startDate = startDate
        self.endDate = endDate
        self.loadReductionPct = loadReductionPct
        self.volumeReductionPct = volumeReductionPct
        self.focus = focus
        self.isActive = isActive
        self.createdAt = createdAt
    }

    /// Days remaining in the deload period
    var daysRemaining: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: endDate)
        let components = calendar.dateComponents([.day], from: today, to: end)
        return max(0, components.day ?? 0)
    }

    /// Progress through the deload period (0.0 to 1.0)
    var progress: Double {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        let today = calendar.startOfDay(for: Date())

        let totalDays = calendar.dateComponents([.day], from: start, to: end).day ?? 1
        let elapsedDays = calendar.dateComponents([.day], from: start, to: today).day ?? 0

        guard totalDays > 0 else { return 1.0 }
        return min(1.0, max(0.0, Double(elapsedDays) / Double(totalDays)))
    }

    /// Formatted load reduction for display (e.g., "30%")
    var formattedLoadReduction: String {
        return String(format: "%.0f%%", loadReductionPct * 100)
    }

    /// Formatted volume reduction for display (e.g., "40%")
    var formattedVolumeReduction: String {
        return String(format: "%.0f%%", volumeReductionPct * 100)
    }
}

// MARK: - Deload Recommendation Errors

enum DeloadRecommendationError: LocalizedError {
    case fetchFailed
    case activationFailed
    case dismissalFailed
    case noRecommendationFound
    case invalidPatientId
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Failed to fetch deload recommendation"
        case .activationFailed:
            return "Failed to activate deload"
        case .dismissalFailed:
            return "Failed to dismiss recommendation"
        case .noRecommendationFound:
            return "No deload recommendation found"
        case .invalidPatientId:
            return "Invalid patient ID provided"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .fetchFailed, .networkError:
            return "Please check your connection and try again."
        case .activationFailed:
            return "Your deload couldn't be started. Please try again or contact your therapist."
        case .dismissalFailed:
            return "The recommendation couldn't be dismissed. Please try again."
        case .noRecommendationFound:
            return "Keep training and we'll let you know when a deload is recommended."
        case .invalidPatientId:
            return "Please sign out and sign back in to refresh your session."
        }
    }
}

// MARK: - Deload Recommendation Service

/// Service for managing deload recommendations
/// Provides methods to fetch, activate, and dismiss deload recommendations
/// Integrates with edge functions for AI-powered recommendations
@MainActor
class DeloadRecommendationService: ObservableObject {
    static let shared = DeloadRecommendationService()

    nonisolated(unsafe) private let client: PTSupabaseClient

    @Published var recommendation: DeloadRecommendation?
    @Published var activeDeload: ActiveDeloadPeriod?
    @Published var isLoading: Bool = false
    @Published var error: String?

    nonisolated init(client: PTSupabaseClient = .shared) {
        self.client = client
    }

    // MARK: - Public API (matching requirements)

    /// Fetch the current deload recommendation for the logged-in patient
    /// - Returns: The current DeloadRecommendation if available
    /// - Throws: DeloadRecommendationError if fetch fails
    func fetchRecommendation() async throws -> DeloadRecommendation? {
        guard let patientId = UUID(uuidString: client.userId ?? "") else {
            throw DeloadRecommendationError.invalidPatientId
        }
        try await fetchRecommendation(patientId: patientId)
        return recommendation
    }

    /// Activate a deload from a recommendation
    /// - Parameters:
    ///   - recommendationId: The UUID of the recommendation to activate
    ///   - startDate: The start date for the deload period
    /// - Returns: The created ActiveDeloadPeriod
    /// - Throws: DeloadRecommendationError if activation fails
    func activateDeload(recommendationId: UUID, startDate: Date) async throws -> ActiveDeloadPeriod {
        guard let patientId = UUID(uuidString: client.userId ?? "") else {
            throw DeloadRecommendationError.invalidPatientId
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Call the RPC function to activate deload
            let params = ActivateDeloadParams(
                pRecommendationId: recommendationId.uuidString,
                pPatientId: patientId.uuidString,
                pStartDate: ISO8601DateFormatter().string(from: startDate)
            )
            let response = try await client.client
                .rpc("activate_deload", params: params)
                .execute()

            guard !response.data.isEmpty else {
                throw DeloadRecommendationError.activationFailed
            }

            let deloadPeriod = try PTSupabaseClient.flexibleDecoder.decode(
                ActiveDeloadPeriod.self,
                from: response.data
            )

            activeDeload = deloadPeriod

            #if DEBUG
            DebugLogger.shared.success("DELOAD", """
                Activated deload for patient \(patientId.uuidString.prefix(8)):
                Period ID: \(deloadPeriod.id.uuidString.prefix(8))
                Start: \(deloadPeriod.startDate)
                End: \(deloadPeriod.endDate)
                """)
            #endif

            return deloadPeriod
        } catch let deloadError as DeloadRecommendationError {
            self.error = deloadError.localizedDescription
            throw deloadError
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            DebugLogger.shared.error("DELOAD", "Failed to activate deload: \(error.localizedDescription)")
            #endif
            throw DeloadRecommendationError.activationFailed
        }
    }

    /// Dismiss a deload recommendation
    /// - Parameters:
    ///   - recommendationId: The UUID of the recommendation to dismiss
    ///   - reason: The reason for dismissal
    /// - Throws: DeloadRecommendationError if dismissal fails
    func dismissRecommendation(recommendationId: UUID, reason: String) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            // Update recommendation status in database
            let updateInput = DismissRecommendationUpdate(
                status: "dismissed",
                dismissedAt: ISO8601DateFormatter().string(from: Date()),
                dismissalReason: reason
            )
            try await client.client
                .from("deload_recommendations")
                .update(updateInput)
                .eq("id", value: recommendationId.uuidString)
                .execute()

            // Clear local recommendation if it matches
            if recommendation?.id == recommendationId {
                recommendation = nil
            }

            #if DEBUG
            DebugLogger.shared.info("DELOAD", """
                Dismissed recommendation \(recommendationId.uuidString.prefix(8))
                Reason: \(reason)
                """)
            #endif
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            DebugLogger.shared.error("DELOAD", "Failed to dismiss recommendation: \(error.localizedDescription)")
            #endif
            throw DeloadRecommendationError.dismissalFailed
        }
    }

    /// Check if there is an active deload period for the logged-in patient
    /// - Returns: The active deload period if one exists
    /// - Throws: DeloadRecommendationError if check fails
    func checkActiveDeload() async throws -> ActiveDeloadPeriod? {
        guard let patientId = UUID(uuidString: client.userId ?? "") else {
            throw DeloadRecommendationError.invalidPatientId
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Call the RPC function to check if in deload period
            let params = IsInDeloadPeriodParams(pPatientId: patientId.uuidString)
            let response = try await client.client
                .rpc("is_in_deload_period", params: params)
                .execute()

            // Parse the response - could be boolean or full period data
            if response.data.isEmpty {
                activeDeload = nil
                return nil
            }

            // Try to decode as ActiveDeloadPeriod first
            if let deloadPeriod = try? PTSupabaseClient.flexibleDecoder.decode(
                ActiveDeloadPeriod.self,
                from: response.data
            ) {
                activeDeload = deloadPeriod
                return deloadPeriod
            }

            // Fallback: fetch from deload_periods table directly
            let periodsResponse = try await client.client
                .from("deload_periods")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .eq("is_active", value: true)
                .lte("start_date", value: ISO8601DateFormatter().string(from: Date()))
                .gte("end_date", value: ISO8601DateFormatter().string(from: Date()))
                .limit(1)
                .execute()

            guard !periodsResponse.data.isEmpty else {
                activeDeload = nil
                return nil
            }

            let periods = try PTSupabaseClient.flexibleDecoder.decode(
                [ActiveDeloadPeriod].self,
                from: periodsResponse.data
            )

            activeDeload = periods.first

            #if DEBUG
            if let period = activeDeload {
                DebugLogger.shared.info("DELOAD", """
                    Found active deload for patient \(patientId.uuidString.prefix(8)):
                    Days remaining: \(period.daysRemaining)
                    Progress: \(Int(period.progress * 100))%
                    """)
            }
            #endif

            return activeDeload
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            DebugLogger.shared.error("DELOAD", "Failed to check active deload: \(error.localizedDescription)")
            #endif
            throw DeloadRecommendationError.fetchFailed
        }
    }

    /// Complete/end an active deload period
    /// - Parameter periodId: The UUID of the deload period to complete
    /// - Throws: DeloadRecommendationError if completion fails
    func completeDeload(periodId: UUID) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            // Update the deload period to mark as inactive
            struct DeloadComplete: Encodable {
                let is_active: Bool
                let completed_at: String
            }
            let updateData = DeloadComplete(
                is_active: false,
                completed_at: ISO8601DateFormatter().string(from: Date())
            )
            try await client.client
                .from("deload_periods")
                .update(updateData)
                .eq("id", value: periodId.uuidString)
                .execute()

            // Clear active deload if it matches
            if activeDeload?.id == periodId {
                activeDeload = nil
            }

            #if DEBUG
            DebugLogger.shared.success("DELOAD", "Completed deload period \(periodId.uuidString.prefix(8))")
            #endif
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            DebugLogger.shared.error("DELOAD", "Failed to complete deload: \(error.localizedDescription)")
            #endif
            throw DeloadRecommendationError.activationFailed
        }
    }

    // MARK: - Fetch Recommendation

    /// Fetch the current/latest deload recommendation for a patient
    /// Calls an edge function that analyzes fatigue data and generates recommendations
    /// - Parameter patientId: The patient's UUID
    /// - Throws: DeloadRecommendationError if fetch fails
    func fetchRecommendation(patientId: UUID) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            // Create request body
            let bodyData = try JSONEncoder().encode(["patientId": patientId.uuidString])

            // Call edge function to get/generate recommendation
            let responseData: Data = try await client.client.functions.invoke(
                "ai-deload-recommendation",
                options: FunctionInvokeOptions(body: bodyData)
            ) { data, _ in
                data
            }

            // Decode the response
            let deloadRecommendation = try PTSupabaseClient.flexibleDecoder.decode(
                DeloadRecommendation.self,
                from: responseData
            )

            recommendation = deloadRecommendation

            #if DEBUG
            DebugLogger.shared.success("DELOAD", """
                Fetched recommendation for patient \(patientId.uuidString.prefix(8)):
                Deload: \(deloadRecommendation.deloadRecommended ? "Yes" : "No")
                Urgency: \(deloadRecommendation.urgency.title)
                Reason: \(deloadRecommendation.reasoning.prefix(50))...
                """)
            #endif
        } catch {
            // If edge function fails, try fetching from database directly
            do {
                try await fetchRecommendationFromDatabase(patientId: patientId)
            } catch {
                self.error = error.localizedDescription
                #if DEBUG
                DebugLogger.shared.error("DELOAD", "Failed to fetch recommendation: \(error.localizedDescription)")
                #endif
                throw DeloadRecommendationError.fetchFailed
            }
        }
    }

    /// Fetch recommendation directly from database (fallback)
    private func fetchRecommendationFromDatabase(patientId: UUID) async throws {
        let response = try await client.client
            .from("deload_recommendations")
            .select()
            .eq("patient_id", value: patientId.uuidString)
            .eq("status", value: "pending")
            .order("created_at", ascending: false)
            .limit(1)
            .execute()

        guard !response.data.isEmpty else {
            recommendation = nil
            return
        }

        let results = try PTSupabaseClient.flexibleDecoder.decode(
            [DeloadRecommendation].self,
            from: response.data
        )
        recommendation = results.first
    }

    // MARK: - Activate Deload

    /// Activate a deload recommendation, creating a deload event
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - prescription: The deload prescription to activate
    /// - Throws: DeloadRecommendationError if activation fails
    func activateDeload(patientId: UUID, prescription: DeloadPrescription) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            // Create request body with proper encoding
            struct ActivateDeloadRequest: Encodable {
                let patientId: String
                let durationDays: Int
                let loadReductionPct: Double
                let volumeReductionPct: Double
                let focus: String
                let startDate: String
            }

            let requestBody = ActivateDeloadRequest(
                patientId: patientId.uuidString,
                durationDays: prescription.durationDays,
                loadReductionPct: prescription.loadReductionPct,
                volumeReductionPct: prescription.volumeReductionPct,
                focus: prescription.focus,
                startDate: ISO8601DateFormatter().string(from: prescription.suggestedStartDate)
            )

            let bodyData = try JSONEncoder().encode(requestBody)

            // Call edge function to activate deload
            let _: Data = try await client.client.functions.invoke(
                "activate-deload",
                options: FunctionInvokeOptions(body: bodyData)
            ) { data, _ in
                data
            }

            // Update local state
            if let currentRecommendation = recommendation {
                // Create updated recommendation with activated status
                recommendation = DeloadRecommendation(
                    id: currentRecommendation.id,
                    patientId: currentRecommendation.patientId,
                    deloadRecommended: currentRecommendation.deloadRecommended,
                    urgency: currentRecommendation.urgency,
                    reasoning: currentRecommendation.reasoning,
                    fatigueSummary: currentRecommendation.fatigueSummary,
                    deloadPrescription: currentRecommendation.deloadPrescription,
                    createdAt: currentRecommendation.createdAt,
                    status: .activated,
                    activatedAt: Date(),
                    dismissedAt: nil,
                    dismissalReason: nil
                )
            }

            #if DEBUG
            DebugLogger.shared.success("DELOAD", """
                Activated deload for patient \(patientId.uuidString.prefix(8)):
                Duration: \(prescription.durationDays) days
                Load reduction: \(prescription.formattedLoadReduction)
                Volume reduction: \(prescription.formattedVolumeReduction)
                """)
            #endif
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            DebugLogger.shared.error("DELOAD", "Failed to activate deload: \(error.localizedDescription)")
            #endif
            throw DeloadRecommendationError.activationFailed
        }
    }

    // MARK: - Dismiss Recommendation (Legacy)

    /// Dismiss a deload recommendation (legacy method with patientId parameter)
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - reason: Optional reason for dismissal
    /// - Throws: DeloadRecommendationError if dismissal fails
    func dismissRecommendation(patientId: UUID, reason: String? = nil) async throws {
        guard let currentRecommendation = recommendation else {
            throw DeloadRecommendationError.noRecommendationFound
        }
        try await dismissRecommendation(recommendationId: currentRecommendation.id, reason: reason ?? "")
    }

    // MARK: - Check Pending Recommendation

    /// Check if a patient has a pending deload recommendation
    /// - Parameter patientId: The patient's UUID
    /// - Returns: True if there is a pending recommendation
    /// - Throws: DeloadRecommendationError if check fails
    func hasPendingRecommendation(patientId: UUID) async throws -> Bool {
        do {
            let response = try await client.client
                .from("deload_recommendations")
                .select("id")
                .eq("patient_id", value: patientId.uuidString)
                .eq("status", value: "pending")
                .eq("deload_recommended", value: true)
                .limit(1)
                .execute()

            let count = response.data.count
            let hasPending = count > 2 // Empty array "[]" is 2 characters

            #if DEBUG
            DebugLogger.shared.info("DELOAD", """
                Checked pending recommendations for patient \(patientId.uuidString.prefix(8)):
                Has pending: \(hasPending)
                """)
            #endif

            return hasPending
        } catch {
            #if DEBUG
            DebugLogger.shared.error("DELOAD", "Failed to check pending recommendations: \(error.localizedDescription)")
            #endif
            throw DeloadRecommendationError.networkError(error)
        }
    }

    // MARK: - Helper Methods

    /// Get display information for the current recommendation
    /// - Returns: Tuple with urgency color, icon, and title if recommendation exists
    func getRecommendationDisplay() -> (color: Color, icon: String, title: String, subtitle: String)? {
        guard let rec = recommendation, rec.deloadRecommended else { return nil }
        return (
            rec.urgency.color,
            rec.urgency.icon,
            rec.urgency.title,
            rec.urgency.subtitle
        )
    }

    /// Clear any stored error
    func clearError() {
        error = nil
    }

    /// Reset the service state
    func reset() {
        recommendation = nil
        isLoading = false
        error = nil
    }

    // MARK: - Load Adjustment

    /// Apply deload adjustment to a base load value
    /// Uses the active deload's load reduction percentage
    /// - Parameter baseLoad: The original load value to adjust
    /// - Returns: The adjusted load value (reduced by active deload percentage)
    func applyDeloadAdjustment(baseLoad: Double) -> Double {
        guard let deload = activeDeload, deload.isActive else {
            return baseLoad
        }
        // Apply load reduction percentage
        let reductionFactor = 1.0 - deload.loadReductionPct
        return baseLoad * reductionFactor
    }

    /// Apply volume adjustment for deload period
    /// Uses the active deload's volume reduction percentage
    /// - Parameter baseVolume: The original volume (e.g., sets * reps)
    /// - Returns: The adjusted volume value
    func applyVolumeAdjustment(baseVolume: Int) -> Int {
        guard let deload = activeDeload, deload.isActive else {
            return baseVolume
        }
        // Apply volume reduction percentage
        let reductionFactor = 1.0 - deload.volumeReductionPct
        return max(1, Int(Double(baseVolume) * reductionFactor))
    }

    // MARK: - Fetch Active Deload (Alias)

    /// Fetch the active deload period for the logged-in patient
    /// This is an alias for checkActiveDeload() to match API requirements
    /// - Parameter patientId: The patient's UUID
    /// - Returns: The active deload period if one exists
    /// - Throws: DeloadRecommendationError if fetch fails
    func fetchActiveDeload(patientId: UUID) async throws -> ActiveDeloadPeriod? {
        // Store the patient ID temporarily for the check
        guard let _ = client.userId else {
            throw DeloadRecommendationError.invalidPatientId
        }
        return try await checkActiveDeload()
    }
}

// MARK: - Preview Helpers

extension DeloadRecommendation {
    /// Sample recommendation for SwiftUI previews
    static var sample: DeloadRecommendation {
        DeloadRecommendation(
            id: UUID(),
            patientId: UUID(),
            deloadRecommended: true,
            urgency: .recommended,
            reasoning: "Based on your training data from the past 2 weeks, your acute:chronic workload ratio is elevated at 1.4 and you've had 3 consecutive days of low readiness scores. A deload week would help optimize your recovery and prevent overtraining.",
            fatigueSummary: FatigueSummary(
                fatigueScore: 68.0,
                fatigueBand: "high",
                avgReadiness7d: 58.0,
                acuteChronicRatio: 1.4,
                consecutiveLowDays: 3,
                contributingFactors: ["High ACR", "Low readiness streak", "Elevated RPE"]
            ),
            deloadPrescription: DeloadPrescription(
                durationDays: 7,
                loadReductionPct: 0.30,
                volumeReductionPct: 0.40,
                focus: "Recovery and mobility work",
                suggestedStartDate: Date()
            ),
            createdAt: Date(),
            status: .pending
        )
    }

    /// Sample with no deload needed for testing
    static var noDeloadSample: DeloadRecommendation {
        DeloadRecommendation(
            id: UUID(),
            patientId: UUID(),
            deloadRecommended: false,
            urgency: .none,
            reasoning: "Your training metrics look healthy. Your acute:chronic workload ratio is within optimal range at 1.1 and your readiness scores have been consistently high. Continue with your current program.",
            fatigueSummary: FatigueSummary(
                fatigueScore: 32.0,
                fatigueBand: "low",
                avgReadiness7d: 78.0,
                acuteChronicRatio: 1.1,
                consecutiveLowDays: 0,
                contributingFactors: []
            ),
            deloadPrescription: nil,
            createdAt: Date(),
            status: nil
        )
    }
}

extension FatigueSummary {
    /// Sample fatigue summary for previews
    static var sample: FatigueSummary {
        FatigueSummary(
            fatigueScore: 65.0,
            fatigueBand: "moderate",
            avgReadiness7d: 62.0,
            acuteChronicRatio: 1.3,
            consecutiveLowDays: 2,
            contributingFactors: ["Elevated ACR", "Low sleep quality"]
        )
    }
}

extension DeloadPrescription {
    /// Sample prescription for previews
    static var sample: DeloadPrescription {
        DeloadPrescription(
            durationDays: 7,
            loadReductionPct: 0.30,
            volumeReductionPct: 0.40,
            focus: "Active recovery and mobility",
            suggestedStartDate: Date()
        )
    }
}

extension ActiveDeloadPeriod {
    /// Sample active deload period for SwiftUI previews
    static var sample: ActiveDeloadPeriod {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        let endDate = calendar.date(byAdding: .day, value: 4, to: Date()) ?? Date()

        return ActiveDeloadPeriod(
            id: UUID(),
            patientId: UUID(),
            recommendationId: UUID(),
            startDate: startDate,
            endDate: endDate,
            loadReductionPct: 0.30,
            volumeReductionPct: 0.40,
            focus: "Recovery and mobility work",
            isActive: true,
            createdAt: startDate
        )
    }

    /// Sample completed deload period for testing
    static var completedSample: ActiveDeloadPeriod {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -10, to: Date()) ?? Date()
        let endDate = calendar.date(byAdding: .day, value: -3, to: Date()) ?? Date()

        return ActiveDeloadPeriod(
            id: UUID(),
            patientId: UUID(),
            recommendationId: UUID(),
            startDate: startDate,
            endDate: endDate,
            loadReductionPct: 0.25,
            volumeReductionPct: 0.35,
            focus: "Active recovery",
            isActive: false,
            createdAt: startDate
        )
    }
}
