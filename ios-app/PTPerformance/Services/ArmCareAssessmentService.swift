import Foundation
import Supabase

/// Service for managing arm care assessments
/// ACP-522: Provides CRUD operations and trend analysis for arm health tracking
@MainActor
class ArmCareAssessmentService: ObservableObject {
    // MARK: - Properties

    nonisolated(unsafe) private let client: PTSupabaseClient
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Initialization

    nonisolated init(client: PTSupabaseClient = .shared) {
        self.client = client
    }

    // MARK: - Submit Assessment

    /// Submit or update arm care assessment
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - shoulderPainScore: 0-10 (10 = no pain)
    ///   - shoulderStiffnessScore: 0-10 (10 = no stiffness)
    ///   - shoulderStrengthScore: 0-10 (10 = full strength)
    ///   - elbowPainScore: 0-10 (10 = no pain)
    ///   - elbowTightnessScore: 0-10 (10 = no tightness)
    ///   - valgusStressScore: 0-10 (10 = no discomfort)
    ///   - painLocations: Optional array of pain locations
    ///   - notes: Optional notes
    /// - Returns: Created/updated ArmCareAssessment
    func submitAssessment(
        patientId: UUID,
        shoulderPainScore: Int,
        shoulderStiffnessScore: Int,
        shoulderStrengthScore: Int,
        elbowPainScore: Int,
        elbowTightnessScore: Int,
        valgusStressScore: Int,
        painLocations: [ArmPainLocation]? = nil,
        notes: String? = nil
    ) async throws -> ArmCareAssessment {
        isLoading = true
        defer { isLoading = false }

        // Format date as YYYY-MM-DD for PostgreSQL DATE column
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: Date())

        // Create input with calculated scores
        var input = ArmCareAssessmentInput(
            patientId: patientId.uuidString,
            date: dateString,
            shoulderPainScore: shoulderPainScore,
            shoulderStiffnessScore: shoulderStiffnessScore,
            shoulderStrengthScore: shoulderStrengthScore,
            elbowPainScore: elbowPainScore,
            elbowTightnessScore: elbowTightnessScore,
            valgusStressScore: valgusStressScore,
            painLocations: painLocations?.map { $0.rawValue },
            notes: notes
        )

        // Calculate scores before submission
        input.calculateScores()

        // Validate input
        try input.validate()

        do {
            #if DEBUG
            print("Submitting arm care assessment for patient: \(patientId.uuidString), date: \(dateString)")
            print("Scores: shoulder=\(input.shoulderScore ?? 0), elbow=\(input.elbowScore ?? 0), overall=\(input.overallScore ?? 0)")
            print("Traffic light: \(input.trafficLight ?? "unknown")")
            #endif

            // Upsert to database
            let response = try await client.client
                .from("arm_care_assessments")
                .upsert(input, onConflict: "patient_id,date")
                .select()
                .single()
                .execute()

            let decoder = createDecoder()
            let assessment = try decoder.decode(ArmCareAssessment.self, from: response.data)

            #if DEBUG
            print("Arm care assessment saved: traffic_light=\(assessment.trafficLight.rawValue)")
            #endif

            return assessment
        } catch {
            #if DEBUG
            print("Error saving arm care assessment: \(error)")
            #endif
            self.error = error
            throw ArmCareError.saveFailed
        }
    }

    // MARK: - Get Today's Assessment

    /// Fetch today's assessment for a patient
    /// - Parameter patientId: Patient UUID
    /// - Returns: Today's assessment or nil if not found
    func getTodayAssessment(for patientId: UUID) async throws -> ArmCareAssessment? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let today = dateFormatter.string(from: Date())

        do {
            let response = try await client.client
                .from("arm_care_assessments")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .eq("date", value: today)
                .limit(1)
                .execute()

            guard !response.data.isEmpty else {
                return nil
            }

            let decoder = createDecoder()
            let results = try decoder.decode([ArmCareAssessment].self, from: response.data)
            return results.first
        } catch {
            #if DEBUG
            print("Error fetching today's arm care assessment: \(error)")
            #endif
            return nil
        }
    }

    // MARK: - Fetch Recent Assessments

    /// Fetch recent assessments for a patient
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - limit: Maximum number of records (default 7)
    /// - Returns: Array of assessments ordered by date descending
    func fetchRecentAssessments(
        for patientId: UUID,
        limit: Int = 7
    ) async throws -> [ArmCareAssessment] {
        do {
            let response = try await client.client
                .from("arm_care_assessments")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .order("date", ascending: false)
                .limit(limit)
                .execute()

            let decoder = createDecoder()
            return try decoder.decode([ArmCareAssessment].self, from: response.data)
        } catch {
            self.error = error
            throw ArmCareError.fetchFailed
        }
    }

    // MARK: - Calculate Trend

    /// Get arm care trend data over N days
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - days: Number of days to analyze (default 7)
    /// - Returns: Trend data with statistics
    func getArmCareTrend(
        for patientId: UUID,
        days: Int = 7
    ) async throws -> ArmCareTrend {
        do {
            // Fetch assessments for the period
            let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let startString = dateFormatter.string(from: startDate)

            let response = try await client.client
                .from("arm_care_assessments")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .gte("date", value: startString)
                .order("date", ascending: true)
                .execute()

            let decoder = createDecoder()
            let assessments = try decoder.decode([ArmCareAssessment].self, from: response.data)

            // Calculate statistics
            let summaries = assessments.map { assessment in
                ArmCareTrend.ArmCareAssessmentSummary(
                    date: assessment.date,
                    overallScore: assessment.overallScore,
                    shoulderScore: assessment.shoulderScore,
                    elbowScore: assessment.elbowScore,
                    trafficLight: assessment.trafficLight
                )
            }

            let greenDays = assessments.filter { $0.trafficLight == .green }.count
            let yellowDays = assessments.filter { $0.trafficLight == .yellow }.count
            let redDays = assessments.filter { $0.trafficLight == .red }.count

            // Calculate averages
            let avgOverall: Double? = assessments.isEmpty ? nil : assessments.reduce(0) { $0 + $1.overallScore } / Double(assessments.count)
            let avgShoulder: Double? = assessments.isEmpty ? nil : assessments.reduce(0) { $0 + $1.shoulderScore } / Double(assessments.count)
            let avgElbow: Double? = assessments.isEmpty ? nil : assessments.reduce(0) { $0 + $1.elbowScore } / Double(assessments.count)

            // Calculate trend direction
            let trendDirection = calculateTrendDirection(assessments: assessments)

            let statistics = ArmCareTrend.ArmCareTrendStatistics(
                avgOverallScore: avgOverall,
                avgShoulderScore: avgShoulder,
                avgElbowScore: avgElbow,
                greenDays: greenDays,
                yellowDays: yellowDays,
                redDays: redDays,
                totalAssessments: assessments.count,
                trendDirection: trendDirection
            )

            return ArmCareTrend(
                patientId: patientId,
                daysAnalyzed: days,
                assessments: summaries,
                statistics: statistics
            )
        } catch {
            self.error = error
            throw ArmCareError.trendCalculationFailed
        }
    }

    // MARK: - Generate Workout Modifications

    /// Generate workout modifications based on today's assessment
    /// - Parameter patientId: Patient UUID
    /// - Returns: Workout modification recommendations or nil if no assessment
    func getWorkoutModifications(for patientId: UUID) async throws -> ArmCareWorkoutModification? {
        guard let assessment = try await getTodayAssessment(for: patientId) else {
            return nil
        }

        return ArmCareWorkoutModification.from(
            trafficLight: assessment.trafficLight,
            shoulderScore: assessment.shoulderScore,
            elbowScore: assessment.elbowScore
        )
    }

    /// Check if patient should be allowed to throw based on today's assessment
    /// - Parameter patientId: Patient UUID
    /// - Returns: Tuple of (canThrow, volumeMultiplier)
    func canThrowToday(for patientId: UUID) async throws -> (canThrow: Bool, volumeMultiplier: Double) {
        guard let assessment = try await getTodayAssessment(for: patientId) else {
            // No assessment - default to caution
            return (canThrow: true, volumeMultiplier: 0.75)
        }

        switch assessment.trafficLight {
        case .green:
            return (canThrow: true, volumeMultiplier: 1.0)
        case .yellow:
            return (canThrow: true, volumeMultiplier: 0.5)
        case .red:
            return (canThrow: false, volumeMultiplier: 0.0)
        }
    }

    // MARK: - Delete Assessment

    /// Delete an assessment
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - date: Date of assessment to delete
    func deleteAssessment(
        for patientId: UUID,
        on date: Date
    ) async throws {
        isLoading = true
        defer { isLoading = false }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)

        do {
            try await client.client
                .from("arm_care_assessments")
                .delete()
                .eq("patient_id", value: patientId.uuidString)
                .eq("date", value: dateString)
                .execute()
        } catch {
            self.error = error
            throw error
        }
    }

    // MARK: - Private Methods

    /// Create decoder for arm care assessments
    private func createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try ISO8601 with fractional seconds
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }

            // Try ISO8601 without fractional seconds
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }

            // Try DATE format (YYYY-MM-DD)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone.current
            if let date = dateFormatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string: \(dateString)"
            )
        }
        return decoder
    }

    /// Calculate trend direction from assessments
    private func calculateTrendDirection(assessments: [ArmCareAssessment]) -> ArmCareTrend.TrendDirection {
        guard assessments.count >= 3 else {
            return .stable
        }

        // Compare first half average to second half average
        let midpoint = assessments.count / 2
        let firstHalf = Array(assessments.prefix(midpoint))
        let secondHalf = Array(assessments.suffix(assessments.count - midpoint))

        let firstAvg = firstHalf.reduce(0) { $0 + $1.overallScore } / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0) { $0 + $1.overallScore } / Double(secondHalf.count)

        let difference = secondAvg - firstAvg

        if difference > 0.5 {
            return .improving
        } else if difference < -0.5 {
            return .declining
        } else {
            return .stable
        }
    }
}

// MARK: - Convenience Extensions

extension ArmCareAssessmentService {
    /// Check if assessment has been logged today
    /// - Parameter patientId: Patient UUID
    /// - Returns: True if today's assessment exists
    func hasLoggedToday(patientId: UUID) async -> Bool {
        do {
            let assessment = try await getTodayAssessment(for: patientId)
            return assessment != nil
        } catch {
            return false
        }
    }

    /// Get comprehensive arm care summary for a patient
    /// Includes today's assessment, recent history, and 7-day trend
    func getArmCareSummary(for patientId: UUID) async throws -> ArmCareSummary {
        async let todayAssessment = getTodayAssessment(for: patientId)
        async let recentAssessments = fetchRecentAssessments(for: patientId, limit: 7)
        async let trend = getArmCareTrend(for: patientId, days: 7)

        return try await ArmCareSummary(
            today: todayAssessment,
            recent: recentAssessments,
            trend: trend
        )
    }
}

// MARK: - Arm Care Summary

/// Comprehensive arm care summary
struct ArmCareSummary {
    let today: ArmCareAssessment?
    let recent: [ArmCareAssessment]
    let trend: ArmCareTrend

    var hasLoggedToday: Bool {
        today != nil
    }

    var currentTrafficLight: ArmCareTrafficLight? {
        today?.trafficLight
    }

    var averageScore: Double? {
        trend.statistics.avgOverallScore
    }

    var canThrowToday: Bool {
        guard let trafficLight = currentTrafficLight else {
            return true // Default to allowing if no assessment
        }
        return trafficLight != .red
    }

    var throwingVolumeMultiplier: Double {
        guard let trafficLight = currentTrafficLight else {
            return 0.75 // Default to 75% if no assessment
        }
        return trafficLight.throwingVolumeMultiplier
    }
}
