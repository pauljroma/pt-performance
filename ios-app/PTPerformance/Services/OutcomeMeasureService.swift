//
//  OutcomeMeasureService.swift
//  PTPerformance
//
//  Service for managing patient-reported outcome measures (LEFS, DASH, QuickDASH, PSFS)
//  with automatic score calculation and MCID tracking
//

import Foundation
import Supabase

// MARK: - DTOs for Supabase Operations

/// Input for creating a new outcome measure
struct CreateOutcomeMeasureDTO: Encodable {
    let id: UUID
    let patientId: UUID
    let therapistId: UUID
    let clinicalAssessmentId: UUID?
    let measureType: String
    let assessmentDate: String
    let responses: [String: Int]
    let rawScore: Double
    let normalizedScore: Double
    let interpretation: String
    let previousScore: Double?
    let changeFromPrevious: Double?
    let meetsMcid: Bool
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case therapistId = "therapist_id"
        case clinicalAssessmentId = "clinical_assessment_id"
        case measureType = "measure_type"
        case assessmentDate = "assessment_date"
        case responses
        case rawScore = "raw_score"
        case normalizedScore = "normalized_score"
        case interpretation
        case previousScore = "previous_score"
        case changeFromPrevious = "change_from_previous"
        case meetsMcid = "meets_mcid"
        case notes
    }
}

/// Input for updating an existing outcome measure
struct UpdateOutcomeMeasureDTO: Encodable {
    var responses: [String: Int]?
    var rawScore: Double?
    var normalizedScore: Double?
    var interpretation: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case responses
        case rawScore = "raw_score"
        case normalizedScore = "normalized_score"
        case interpretation
        case notes
    }
}

// MARK: - Patient Progress Summary

/// Summary of patient progress across all outcome measures
struct PatientOutcomeProgress: Codable {
    let patientId: UUID
    let measures: [PatientMeasureSummary]
    let overallProgressStatus: ProgressStatus
    let mcidAchievementCount: Int
    let lastAssessmentDate: Date?

    /// Summary of a single outcome measure for a patient.
    /// Distinct from OutcomeMeasureTrend.OutcomeMeasureSummary which tracks individual data points.
    struct PatientMeasureSummary: Codable, Identifiable {
        let id: UUID
        let measureType: OutcomeMeasureType
        let latestScore: Double
        let previousScore: Double?
        let change: Double?
        let meetsMcid: Bool
        let assessmentDate: Date
        let progressStatus: ProgressStatus

        enum CodingKeys: String, CodingKey {
            case id
            case measureType = "measure_type"
            case latestScore = "latest_score"
            case previousScore = "previous_score"
            case change
            case meetsMcid = "meets_mcid"
            case assessmentDate = "assessment_date"
            case progressStatus = "progress_status"
        }
    }

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case measures
        case overallProgressStatus = "overall_progress_status"
        case mcidAchievementCount = "mcid_achievement_count"
        case lastAssessmentDate = "last_assessment_date"
    }
}

// MARK: - OutcomeMeasureService

/// Service for managing patient-reported outcome measures
/// Supports LEFS, DASH, QuickDASH, and PSFS with automatic scoring and MCID tracking
@MainActor
final class OutcomeMeasureService: ObservableObject {
    static let shared = OutcomeMeasureService()

    // MARK: - Published Properties

    @Published private(set) var outcomeMeasures: [OutcomeMeasure] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published private(set) var patientProgress: PatientOutcomeProgress?

    // MARK: - Private Properties

    private let supabase = PTSupabaseClient.shared

    // MARK: - MCID Thresholds (Minimal Clinically Important Difference)
    // These are evidence-based thresholds for meaningful clinical change

    static let mcidThresholds: [OutcomeMeasureType: Double] = [
        .LEFS: 9.0,        // 9 points for Lower Extremity Functional Scale
        .DASH: 10.8,       // 10.8 points for full DASH
        .QuickDASH: 8.0,   // 8 points for QuickDASH
        .PSFS: 2.0         // 2 points for Patient-Specific Functional Scale
    ]

    private init() {}

    // MARK: - Fetch Operations

    /// Fetch all outcome measures for a patient
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - measureType: Optional filter for specific measure type
    ///   - limit: Maximum number of results to return
    /// - Returns: Array of outcome measures sorted by assessment date (newest first)
    func fetchOutcomeMeasures(
        patientId: UUID,
        measureType: OutcomeMeasureType? = nil,
        limit: Int = 50
    ) async throws -> [OutcomeMeasure] {
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            var query = supabase.client
                .from("outcome_measures")
                .select()
                .eq("patient_id", value: patientId.uuidString)

            if let type = measureType {
                query = query.eq("measure_type", value: type.rawValue)
            }

            let measures: [OutcomeMeasure] = try await query
                .order("assessment_date", ascending: false)
                .limit(limit)
                .execute()
                .value

            self.outcomeMeasures = measures
            DebugLogger.shared.success("OutcomeMeasureService", "Fetched \(measures.count) outcome measures for patient")
            return measures
        } catch {
            self.error = error
            DebugLogger.shared.error("OutcomeMeasureService", "Failed to fetch outcome measures: \(error)")
            throw error
        }
    }

    /// Fetch a single outcome measure by ID
    /// - Parameter id: The outcome measure UUID
    /// - Returns: The outcome measure if found
    func fetchOutcomeMeasure(id: UUID) async throws -> OutcomeMeasure? {
        let measures: [OutcomeMeasure] = try await supabase.client
            .from("outcome_measures")
            .select()
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value

        return measures.first
    }

    /// Fetch the most recent outcome measure of a specific type for a patient
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - measureType: The type of outcome measure
    /// - Returns: The most recent outcome measure if found
    func fetchLatestMeasure(
        patientId: UUID,
        measureType: OutcomeMeasureType
    ) async throws -> OutcomeMeasure? {
        let measures: [OutcomeMeasure] = try await supabase.client
            .from("outcome_measures")
            .select()
            .eq("patient_id", value: patientId.uuidString)
            .eq("measure_type", value: measureType.rawValue)
            .order("assessment_date", ascending: false)
            .limit(1)
            .execute()
            .value

        return measures.first
    }

    // MARK: - Create & Update Operations

    /// Submit a new outcome measure with automatic score calculation
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - therapistId: The therapist's UUID
    ///   - measureType: Type of outcome measure (LEFS, DASH, QuickDASH, PSFS)
    ///   - responses: Dictionary of question ID to answer value
    ///   - clinicalAssessmentId: Optional linked clinical assessment
    ///   - notes: Optional notes
    /// - Returns: The created outcome measure with calculated scores
    func submitOutcomeMeasure(
        patientId: UUID,
        therapistId: UUID,
        measureType: OutcomeMeasureType,
        responses: [String: Int],
        clinicalAssessmentId: UUID? = nil,
        notes: String? = nil
    ) async throws -> OutcomeMeasure {
        isLoading = true
        error = nil

        defer { isLoading = false }

        DebugLogger.shared.info("OutcomeMeasureService", "Submitting \(measureType.rawValue) with \(responses.count) responses")

        // Validate responses
        try validateResponses(responses, for: measureType)

        // Calculate scores
        let rawScore = calculateRawScore(responses: responses, measureType: measureType)
        let normalizedScore = calculateNormalizedScore(rawScore: rawScore, measureType: measureType)
        let interpretation = generateInterpretation(normalizedScore: normalizedScore, measureType: measureType)

        // Fetch previous score for MCID calculation
        let previousMeasure = try await fetchLatestMeasure(patientId: patientId, measureType: measureType)
        let previousScore = previousMeasure?.normalizedScore ?? previousMeasure?.rawScore
        let changeFromPrevious = previousScore.map { normalizedScore - $0 }
        let meetsMcid = calculateMcidAchievement(
            change: changeFromPrevious,
            measureType: measureType
        )

        // Prepare DTO
        let dateFormatter = ISO8601DateFormatter()
        let dto = CreateOutcomeMeasureDTO(
            id: UUID(),
            patientId: patientId,
            therapistId: therapistId,
            clinicalAssessmentId: clinicalAssessmentId,
            measureType: measureType.rawValue,
            assessmentDate: dateFormatter.string(from: Date()),
            responses: responses,
            rawScore: rawScore,
            normalizedScore: normalizedScore,
            interpretation: interpretation,
            previousScore: previousScore,
            changeFromPrevious: changeFromPrevious,
            meetsMcid: meetsMcid,
            notes: notes
        )

        do {
            let createdMeasure: OutcomeMeasure = try await supabase.client
                .from("outcome_measures")
                .insert(dto)
                .select()
                .single()
                .execute()
                .value

            DebugLogger.shared.success("OutcomeMeasureService", "Created outcome measure: \(createdMeasure.id)")
            DebugLogger.shared.info("OutcomeMeasureService", "Score: \(normalizedScore), MCID met: \(meetsMcid)")

            // Refresh the list
            _ = try? await fetchOutcomeMeasures(patientId: patientId)

            return createdMeasure
        } catch {
            self.error = error
            DebugLogger.shared.error("OutcomeMeasureService", "Failed to create outcome measure: \(error)")
            throw OutcomeMeasureError.saveFailed
        }
    }

    /// Update an existing outcome measure
    /// - Parameters:
    ///   - id: The outcome measure UUID
    ///   - updates: The fields to update
    func updateOutcomeMeasure(id: UUID, updates: UpdateOutcomeMeasureDTO) async throws {
        try await supabase.client
            .from("outcome_measures")
            .update(updates)
            .eq("id", value: id.uuidString)
            .execute()

        DebugLogger.shared.success("OutcomeMeasureService", "Updated outcome measure: \(id)")
    }

    /// Delete an outcome measure
    /// - Parameter id: The outcome measure UUID
    func deleteOutcomeMeasure(id: UUID) async throws {
        try await supabase.client
            .from("outcome_measures")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()

        DebugLogger.shared.success("OutcomeMeasureService", "Deleted outcome measure: \(id)")
    }

    // MARK: - Patient Progress Tracking

    /// Fetch comprehensive progress summary for a patient
    /// - Parameter patientId: The patient's UUID
    /// - Returns: Progress summary across all outcome measure types
    func fetchPatientProgress(patientId: UUID) async throws -> PatientOutcomeProgress {
        isLoading = true
        error = nil

        defer { isLoading = false }

        // Fetch all measures for the patient
        let allMeasures = try await fetchOutcomeMeasures(patientId: patientId, limit: 100)

        // Group by measure type and get latest for each
        var measuresByType: [OutcomeMeasureType: [OutcomeMeasure]] = [:]
        for measure in allMeasures {
            measuresByType[measure.measureType, default: []].append(measure)
        }

        // Build summaries for each measure type
        var summaries: [PatientOutcomeProgress.PatientMeasureSummary] = []
        var mcidCount = 0
        var latestDate: Date?

        for (measureType, measures) in measuresByType {
            guard let latest = measures.first else { continue }

            let summary = PatientOutcomeProgress.PatientMeasureSummary(
                id: latest.id,
                measureType: measureType,
                latestScore: latest.normalizedScore ?? latest.rawScore ?? 0,
                previousScore: latest.previousScore,
                change: latest.changeFromPrevious,
                meetsMcid: latest.meetsMcid ?? false,
                assessmentDate: latest.assessmentDate,
                progressStatus: latest.progressStatus
            )

            summaries.append(summary)

            if latest.meetsMcid == true {
                mcidCount += 1
            }

            if let existingLatestDate = latestDate {
                if latest.assessmentDate > existingLatestDate {
                    latestDate = latest.assessmentDate
                }
            } else {
                latestDate = latest.assessmentDate
            }
        }

        // Determine overall progress status
        let overallStatus: ProgressStatus
        if summaries.isEmpty {
            overallStatus = .stable
        } else {
            let improvingCount = summaries.filter { $0.progressStatus == .improving }.count
            let decliningCount = summaries.filter { $0.progressStatus == .declining }.count

            if improvingCount > decliningCount && improvingCount > 0 {
                overallStatus = .improving
            } else if decliningCount > improvingCount && decliningCount > 0 {
                overallStatus = .declining
            } else {
                overallStatus = .stable
            }
        }

        let progress = PatientOutcomeProgress(
            patientId: patientId,
            measures: summaries.sorted { $0.assessmentDate > $1.assessmentDate },
            overallProgressStatus: overallStatus,
            mcidAchievementCount: mcidCount,
            lastAssessmentDate: latestDate
        )

        self.patientProgress = progress
        DebugLogger.shared.success("OutcomeMeasureService", "Fetched patient progress: \(summaries.count) measure types, \(mcidCount) MCID achievements")

        return progress
    }

    /// Fetch trend data for a specific outcome measure type
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - measureType: The type of outcome measure
    ///   - limit: Maximum number of data points
    /// - Returns: Trend data for charting
    func fetchMeasureTrend(
        patientId: UUID,
        measureType: OutcomeMeasureType,
        limit: Int = 10
    ) async throws -> OutcomeMeasureTrend {
        let measures = try await fetchOutcomeMeasures(
            patientId: patientId,
            measureType: measureType,
            limit: limit
        )

        let sortedMeasures = measures.sorted { $0.assessmentDate < $1.assessmentDate }

        let summaries = sortedMeasures.map { measure in
            OutcomeMeasureTrend.OutcomeMeasureSummary(
                id: measure.id,
                date: measure.assessmentDate,
                score: measure.normalizedScore ?? measure.rawScore ?? 0,
                changeFromPrevious: measure.changeFromPrevious
            )
        }

        // Calculate overall change
        let overallChange: Double?
        if let first = sortedMeasures.first, let last = sortedMeasures.last,
           let firstScore = first.normalizedScore ?? first.rawScore,
           let lastScore = last.normalizedScore ?? last.rawScore {
            overallChange = lastScore - firstScore
        } else {
            overallChange = nil
        }

        // Determine trend direction
        let trendDirection: ProgressStatus
        if let change = overallChange {
            let mcidThreshold = Self.mcidThresholds[measureType] ?? measureType.mcidThreshold
            if measureType.higherIsBetter {
                if change >= mcidThreshold { trendDirection = .improving }
                else if change <= -mcidThreshold { trendDirection = .declining }
                else { trendDirection = .stable }
            } else {
                if change <= -mcidThreshold { trendDirection = .improving }
                else if change >= mcidThreshold { trendDirection = .declining }
                else { trendDirection = .stable }
            }
        } else {
            trendDirection = .stable
        }

        // Check if MCID achieved overall
        let achievedMcid = overallChange.map { change in
            let threshold = Self.mcidThresholds[measureType] ?? measureType.mcidThreshold
            return measureType.higherIsBetter ? change >= threshold : change <= -threshold
        } ?? false

        return OutcomeMeasureTrend(
            patientId: patientId,
            measureType: measureType,
            measurements: summaries,
            overallChange: overallChange,
            trendDirection: trendDirection,
            achievedMcid: achievedMcid
        )
    }

    // MARK: - Score Calculation

    /// Calculate raw score from responses
    /// - Parameters:
    ///   - responses: Dictionary of question ID to answer value
    ///   - measureType: The type of outcome measure
    /// - Returns: The calculated raw score
    func calculateRawScore(responses: [String: Int], measureType: OutcomeMeasureType) -> Double {
        switch measureType {
        case .LEFS:
            return calculateLEFSScore(responses: responses)
        case .DASH:
            return calculateDASHScore(responses: responses)
        case .QuickDASH:
            return calculateQuickDASHScore(responses: responses)
        case .PSFS:
            return calculatePSFSScore(responses: responses)
        default:
            // For other measure types, sum the responses
            return Double(responses.values.reduce(0, +))
        }
    }

    /// Calculate normalized score (0-100 scale where applicable)
    /// - Parameters:
    ///   - rawScore: The raw score
    ///   - measureType: The type of outcome measure
    /// - Returns: The normalized score
    func calculateNormalizedScore(rawScore: Double, measureType: OutcomeMeasureType) -> Double {
        switch measureType {
        case .LEFS:
            // LEFS: 0-80 scale, higher is better
            // Normalize to percentage of max function
            return (rawScore / 80.0) * 100.0

        case .DASH, .QuickDASH:
            // DASH/QuickDASH: Formula already produces 0-100 disability score
            // Lower is better (0 = no disability, 100 = complete disability)
            return rawScore

        case .PSFS:
            // PSFS: 0-10 scale, higher is better
            // Return as-is since it's already normalized
            return rawScore

        default:
            return rawScore
        }
    }

    /// Calculate LEFS score (Lower Extremity Functional Scale)
    /// 20 questions, each scored 0-4, higher = better function
    /// Max score = 80
    private func calculateLEFSScore(responses: [String: Int]) -> Double {
        // Sum all responses (0-4 scale per question)
        let total = responses.values.reduce(0, +)
        return Double(total)
    }

    /// Calculate DASH score (Disabilities of Arm, Shoulder and Hand)
    /// 30 questions, each scored 1-5
    /// Formula: ((sum of n responses / n) - 1) * 25
    /// Result is 0-100 disability score (lower = better)
    private func calculateDASHScore(responses: [String: Int]) -> Double {
        guard !responses.isEmpty else { return 0 }

        let sum = responses.values.reduce(0, +)
        let n = Double(responses.count)

        // DASH formula: ((sum/n) - 1) * 25
        let score = ((Double(sum) / n) - 1.0) * 25.0
        return max(0, min(100, score))
    }

    /// Calculate QuickDASH score
    /// 11 questions, same formula as DASH
    /// At least 10 of 11 items must be answered
    private func calculateQuickDASHScore(responses: [String: Int]) -> Double {
        // QuickDASH requires at least 10 responses
        guard responses.count >= 10 else {
            DebugLogger.shared.warning("OutcomeMeasureService", "QuickDASH requires at least 10 responses, got \(responses.count)")
            return 0
        }

        let sum = responses.values.reduce(0, +)
        let n = Double(responses.count)

        // Same formula as DASH
        let score = ((Double(sum) / n) - 1.0) * 25.0
        return max(0, min(100, score))
    }

    /// Calculate PSFS score (Patient-Specific Functional Scale)
    /// 3-5 patient-identified activities, each scored 0-10
    /// Final score is average of all activities
    /// Higher = better function
    private func calculatePSFSScore(responses: [String: Int]) -> Double {
        guard !responses.isEmpty else { return 0 }

        let sum = responses.values.reduce(0, +)
        let average = Double(sum) / Double(responses.count)
        return average
    }

    // MARK: - MCID Calculation

    /// Determine if change meets MCID threshold
    /// - Parameters:
    ///   - change: The change in score from previous assessment
    ///   - measureType: The type of outcome measure
    /// - Returns: True if MCID threshold is met
    func calculateMcidAchievement(change: Double?, measureType: OutcomeMeasureType) -> Bool {
        guard let change = change else { return false }

        let threshold = Self.mcidThresholds[measureType] ?? measureType.mcidThreshold

        // For measures where higher is better (LEFS, PSFS), positive change = improvement
        // For measures where lower is better (DASH, QuickDASH), negative change = improvement
        if measureType.higherIsBetter {
            return change >= threshold
        } else {
            return change <= -threshold
        }
    }

    /// Get the MCID threshold for a measure type
    /// - Parameter measureType: The type of outcome measure
    /// - Returns: The MCID threshold value
    func getMcidThreshold(for measureType: OutcomeMeasureType) -> Double {
        return Self.mcidThresholds[measureType] ?? measureType.mcidThreshold
    }

    // MARK: - Interpretation

    /// Generate clinical interpretation of score
    /// - Parameters:
    ///   - normalizedScore: The normalized score (0-100 scale)
    ///   - measureType: The type of outcome measure
    /// - Returns: A human-readable interpretation string
    func generateInterpretation(normalizedScore: Double, measureType: OutcomeMeasureType) -> String {
        switch measureType {
        case .LEFS:
            return interpretLEFSScore(normalizedScore)
        case .DASH, .QuickDASH:
            return interpretDASHScore(normalizedScore)
        case .PSFS:
            return interpretPSFSScore(normalizedScore)
        default:
            return "Score: \(String(format: "%.1f", normalizedScore))"
        }
    }

    private func interpretLEFSScore(_ percentScore: Double) -> String {
        // LEFS normalized to percentage (0-100)
        // Higher = better function
        switch percentScore {
        case 90...100:
            return "Excellent lower extremity function with minimal limitations"
        case 75..<90:
            return "Good lower extremity function with mild limitations"
        case 50..<75:
            return "Moderate lower extremity functional limitations"
        case 25..<50:
            return "Significant lower extremity functional limitations"
        default:
            return "Severe lower extremity functional limitations"
        }
    }

    private func interpretDASHScore(_ disabilityScore: Double) -> String {
        // DASH: 0-100 disability score
        // Lower = better (less disability)
        switch disabilityScore {
        case 0..<10:
            return "Minimal upper extremity disability"
        case 10..<25:
            return "Mild upper extremity disability"
        case 25..<50:
            return "Moderate upper extremity disability"
        case 50..<75:
            return "Significant upper extremity disability"
        default:
            return "Severe upper extremity disability"
        }
    }

    private func interpretPSFSScore(_ averageScore: Double) -> String {
        // PSFS: 0-10 scale
        // Higher = better function
        switch averageScore {
        case 8...10:
            return "Near-normal function for identified activities"
        case 6..<8:
            return "Mild difficulty with identified activities"
        case 4..<6:
            return "Moderate difficulty with identified activities"
        case 2..<4:
            return "Significant difficulty with identified activities"
        default:
            return "Severe difficulty or unable to perform identified activities"
        }
    }

    // MARK: - Validation

    /// Validate that responses are complete and valid
    /// - Parameters:
    ///   - responses: The response dictionary
    ///   - measureType: The type of outcome measure
    private func validateResponses(_ responses: [String: Int], for measureType: OutcomeMeasureType) throws {
        // Check minimum response count based on measure type
        let minimumResponses: Int
        switch measureType {
        case .LEFS:
            minimumResponses = 18  // Allow up to 2 N/A responses
        case .DASH:
            minimumResponses = 27  // Allow up to 3 N/A responses
        case .QuickDASH:
            minimumResponses = 10  // At least 10 of 11 required
        case .PSFS:
            minimumResponses = 1   // At least 1 activity required
        default:
            minimumResponses = 1
        }

        if responses.count < minimumResponses {
            throw OutcomeMeasureError.incompleteResponses(
                "Please complete at least \(minimumResponses) items for \(measureType.displayName)"
            )
        }

        // Validate response values are within expected range
        for (questionId, value) in responses {
            let maxValue: Int
            switch measureType {
            case .LEFS:
                maxValue = 4  // 0-4 scale
            case .DASH, .QuickDASH:
                maxValue = 5  // 1-5 scale
            case .PSFS:
                maxValue = 10 // 0-10 scale
            default:
                maxValue = 10
            }

            if value < 0 || value > maxValue {
                throw OutcomeMeasureError.incompleteResponses(
                    "Invalid response value for question \(questionId): \(value)"
                )
            }
        }
    }

    // MARK: - Helpers

    /// Clear any cached error state
    func clearError() {
        error = nil
    }

    /// Get available outcome measure types for a body region
    /// - Parameter bodyRegion: The body region (e.g., "Upper Extremity", "Lower Extremity")
    /// - Returns: Array of applicable outcome measure types
    func getAvailableMeasures(for bodyRegion: String) -> [OutcomeMeasureType] {
        switch bodyRegion.lowercased() {
        case "lower extremity", "leg", "knee", "hip", "ankle", "foot":
            return [.LEFS, .PSFS]
        case "upper extremity", "arm", "shoulder", "elbow", "wrist", "hand":
            return [.DASH, .QuickDASH, .PSFS]
        default:
            return [.PSFS]  // PSFS is applicable to any body region
        }
    }
}

// MARK: - Service Error Extension

extension OutcomeMeasureError {
    /// User-friendly message for display in UI
    var userMessage: String {
        switch self {
        case .incompleteResponses(let message):
            return message
        case .measureNotFound:
            return "The requested outcome measure could not be found."
        case .saveFailed:
            return "Unable to save the outcome measure. Please try again."
        case .fetchFailed:
            return "Unable to load outcome measures. Please check your connection."
        case .invalidMeasureType:
            return "The selected measure type is not supported."
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension OutcomeMeasureService {
    /// Create a mock service for SwiftUI previews
    static var preview: OutcomeMeasureService {
        let service = OutcomeMeasureService.shared
        service.outcomeMeasures = [OutcomeMeasure.sample, OutcomeMeasure.dashSample]
        return service
    }
}
#endif
