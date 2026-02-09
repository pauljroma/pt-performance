//
//  ProgressiveOverloadAIService.swift
//  PTPerformance
//
//  AI-Powered Progressive Overload Suggestions
//  Provides intelligent load progression recommendations based on training history,
//  readiness state, and fatigue levels.
//

import SwiftUI
import Supabase

// MARK: - Encodable Structs for Supabase Updates

/// Update for accepting a progression suggestion
private struct AcceptSuggestionUpdate: Encodable {
    let status: String
    let acceptedAt: String

    enum CodingKeys: String, CodingKey {
        case status
        case acceptedAt = "accepted_at"
    }
}

/// Update for dismissing a progression suggestion
private struct DismissSuggestionUpdate: Encodable {
    let status: String
    let dismissedAt: String

    enum CodingKeys: String, CodingKey {
        case status
        case dismissedAt = "dismissed_at"
    }
}

// MARK: - Models

/// Type of progression recommendation
enum ProgressionType: String, Codable {
    case increase
    case hold
    case decrease
    case deload

    /// Color for UI display
    var color: Color {
        switch self {
        case .increase:
            return .green
        case .hold:
            return .blue
        case .decrease:
            return .orange
        case .deload:
            return .red
        }
    }

    /// SF Symbol icon name
    var icon: String {
        switch self {
        case .increase:
            return "arrow.up.circle.fill"
        case .hold:
            return "equal.circle.fill"
        case .decrease:
            return "arrow.down.circle.fill"
        case .deload:
            return "bed.double.circle.fill"
        }
    }

    /// Human-readable display text
    var displayText: String {
        switch self {
        case .increase:
            return "Increase Load"
        case .hold:
            return "Maintain Load"
        case .decrease:
            return "Reduce Load"
        case .deload:
            return "Deload Week"
        }
    }
}

/// Training trend direction
enum PerformanceTrend: String, Codable {
    case improving
    case plateaued
    case declining

    var color: Color {
        switch self {
        case .improving:
            return .green
        case .plateaued:
            return .orange
        case .declining:
            return .red
        }
    }

    var icon: String {
        switch self {
        case .improving:
            return "arrow.up.right"
        case .plateaued:
            return "arrow.right"
        case .declining:
            return "arrow.down.right"
        }
    }

    var displayText: String {
        switch self {
        case .improving:
            return "Improving"
        case .plateaued:
            return "Plateaued"
        case .declining:
            return "Declining"
        }
    }
}

/// Performance entry for a single training session
struct ExercisePerformance: Codable, Equatable {
    let date: Date
    let load: Double
    let reps: [Int]
    let rpe: Double

    enum CodingKeys: String, CodingKey {
        case date
        case load
        case reps
        case rpe
    }

    /// Average reps across all sets
    var averageReps: Double {
        guard !reps.isEmpty else { return 0 }
        return Double(reps.reduce(0, +)) / Double(reps.count)
    }

    /// Total volume (load * total reps)
    var totalVolume: Double {
        return load * Double(reps.reduce(0, +))
    }

    /// Number of sets
    var setCount: Int {
        return reps.count
    }
}

/// Backward compatibility alias
typealias PerformanceEntry = ExercisePerformance

/// Analysis of training performance
struct PerformanceAnalysis: Codable, Equatable {
    let trend: PerformanceTrend
    let estimated1RM: Double?
    let velocityTrend: String?
    let fatigueImpact: String?
    let recentSessions: Int

    enum CodingKeys: String, CodingKey {
        case trend
        case estimated1RM = "estimated_1rm"
        case velocityTrend = "velocity_trend"
        case fatigueImpact = "fatigue_impact"
        case recentSessions = "recent_sessions"
    }

    /// Initialize with all fields (for local analysis)
    init(
        trend: PerformanceTrend,
        estimated1RM: Double?,
        velocityTrend: String?,
        fatigueImpact: String?,
        recentSessions: Int = 0
    ) {
        self.trend = trend
        self.estimated1RM = estimated1RM
        self.velocityTrend = velocityTrend
        self.fatigueImpact = fatigueImpact
        self.recentSessions = recentSessions
    }

    /// Formatted 1RM string
    var estimated1RMFormatted: String {
        guard let rm = estimated1RM else { return "N/A" }
        return "\(String(format: "%.1f", rm)) lbs"
    }

    /// Velocity trend color for UI
    var velocityTrendColor: Color {
        guard let velocity = velocityTrend?.lowercased() else { return .gray }
        switch velocity {
        case "increasing", "improving":
            return .green
        case "stable", "maintaining":
            return .blue
        case "decreasing", "declining":
            return .orange
        default:
            return .gray
        }
    }
}

/// Thresholds for determining confidence level of progression suggestions
private enum ConfidenceThreshold {
    /// High confidence threshold (80+)
    static let high = 80.0
    /// Moderate confidence threshold (60+)
    static let moderate = 60.0
    // Below moderate = low confidence
}

/// AI-generated progression suggestion
struct ProgressionSuggestion: Codable, Identifiable, Equatable {
    let id: UUID
    let nextLoad: Double
    let nextReps: Int
    let confidence: Double  // 0-100
    let reasoning: String
    let progressionType: ProgressionType
    let analysis: PerformanceAnalysis

    enum CodingKeys: String, CodingKey {
        case id
        case nextLoad = "next_load"
        case nextReps = "next_reps"
        case confidence
        case reasoning
        case progressionType = "progression_type"
        case analysis
    }

    /// Convenience initializer for testing without analysis (creates default analysis)
    init(
        nextLoad: Double,
        nextReps: Int,
        confidence: Double,
        reasoning: String,
        progressionType: ProgressionType
    ) {
        self.id = UUID()
        self.nextLoad = nextLoad
        self.nextReps = nextReps
        self.confidence = confidence
        self.reasoning = reasoning
        self.progressionType = progressionType
        self.analysis = PerformanceAnalysis(
            trend: .plateaued,
            estimated1RM: nil,
            velocityTrend: nil,
            fatigueImpact: nil,
            recentSessions: 0
        )
    }

    /// Full initializer with all fields
    init(
        id: UUID,
        nextLoad: Double,
        nextReps: Int,
        confidence: Double,
        reasoning: String,
        progressionType: ProgressionType,
        analysis: PerformanceAnalysis
    ) {
        self.id = id
        self.nextLoad = nextLoad
        self.nextReps = nextReps
        self.confidence = confidence
        self.reasoning = reasoning
        self.progressionType = progressionType
        self.analysis = analysis
    }

    /// Confidence level description
    var confidenceLevel: String {
        if confidence >= ConfidenceThreshold.high {
            return "High"
        } else if confidence >= ConfidenceThreshold.moderate {
            return "Moderate"
        } else {
            return "Low"
        }
    }

    /// Confidence color for UI
    var confidenceColor: Color {
        if confidence >= ConfidenceThreshold.high {
            return .green
        } else if confidence >= ConfidenceThreshold.moderate {
            return .orange
        } else {
            return .gray
        }
    }

    /// Formatted load change description
    func loadChangeDescription(from currentLoad: Double) -> String {
        let diff = nextLoad - currentLoad
        if abs(diff) < 0.1 {
            return "No change"
        } else if diff > 0 {
            return "+\(String(format: "%.1f", diff)) lbs"
        } else {
            return "\(String(format: "%.1f", diff)) lbs"
        }
    }

    /// Percentage change from current load
    func percentageChange(from currentLoad: Double) -> Double {
        guard currentLoad > 0 else { return 0 }
        return ((nextLoad - currentLoad) / currentLoad) * 100
    }
}

/// Legacy trend type alias for backward compatibility
typealias TrendType = PerformanceTrend

// MARK: - Response Models

/// Full response from the edge function
private struct ProgressiveOverloadResponse: Codable {
    let id: UUID
    let nextLoad: Double
    let nextReps: Int
    let confidence: Double
    let reasoning: String
    let progressionType: ProgressionType
    let analysis: PerformanceAnalysis

    enum CodingKeys: String, CodingKey {
        case id
        case nextLoad = "next_load"
        case nextReps = "next_reps"
        case confidence
        case reasoning
        case progressionType = "progression_type"
        case analysis
    }

    /// Convert to ProgressionSuggestion
    func toSuggestion() -> ProgressionSuggestion {
        ProgressionSuggestion(
            id: id,
            nextLoad: nextLoad,
            nextReps: nextReps,
            confidence: confidence,
            reasoning: reasoning,
            progressionType: progressionType,
            analysis: analysis
        )
    }
}

/// Error response from edge function
private struct ProgressiveOverloadErrorResponse: Codable {
    let error: String?
    let details: String?
}

// MARK: - Service

/// Service for fetching AI-powered progressive overload suggestions
@MainActor
class ProgressiveOverloadAIService: ObservableObject {
    /// Shared singleton instance
    static let shared = ProgressiveOverloadAIService()

    nonisolated(unsafe) private let client: PTSupabaseClient

    // MARK: - Published State

    @Published var suggestion: ProgressionSuggestion?
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Initialization

    nonisolated init(client: PTSupabaseClient = .shared) {
        self.client = client
    }

    // MARK: - Public Methods

    /// Get AI-powered progression suggestion for an exercise using recent performance data
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - exerciseTemplateId: The exercise template UUID
    ///   - recentPerformance: Array of recent performance entries
    /// - Returns: The progression suggestion
    @discardableResult
    func getSuggestion(
        patientId: UUID,
        exerciseTemplateId: UUID,
        recentPerformance: [PerformanceEntry]
    ) async throws -> ProgressionSuggestion {
        isLoading = true
        error = nil
        suggestion = nil

        defer { isLoading = false }

        // Format performance entries for the request
        let performanceData = recentPerformance.map { entry -> [String: Any] in
            let formatter = ISO8601DateFormatter()
            return [
                "date": formatter.string(from: entry.date),
                "load": entry.load,
                "reps": entry.reps,
                "rpe": entry.rpe
            ]
        }

        // Build request payload
        let request: [String: Any] = [
            "patient_id": patientId.uuidString,
            "exercise_template_id": exerciseTemplateId.uuidString,
            "recent_performance": performanceData
        ]

        DebugLogger.shared.info("PROGRESSION_AI", "Calling ai-progressive-overload edge function")
        DebugLogger.shared.info("PROGRESSION_AI", "Request for \(recentPerformance.count) performance entries")

        do {
            // Serialize request
            let bodyData = try JSONSerialization.data(withJSONObject: request)

            // Call edge function
            let responseDataRaw: Data = try await client.client.functions.invoke(
                "ai-progressive-overload",
                options: FunctionInvokeOptions(body: bodyData)
            ) { data, _ in
                data
            }

            DebugLogger.shared.success("PROGRESSION_AI", "Edge function returned successfully")

            // Log raw response for debugging
            if let responseString = String(data: responseDataRaw, encoding: .utf8) {
                DebugLogger.shared.info("PROGRESSION_AI", "Raw response: \(responseString)")
            }

            // Decode response
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            // Check for error response first
            if let errorResponse = try? decoder.decode(ProgressiveOverloadErrorResponse.self, from: responseDataRaw),
               let errorMessage = errorResponse.error {
                DebugLogger.shared.error("PROGRESSION_AI", "Error from edge function: \(errorMessage)")
                self.error = errorMessage
                throw ProgressionError.serverError(errorMessage)
            }

            // Decode successful response
            let response = try decoder.decode(ProgressiveOverloadResponse.self, from: responseDataRaw)

            // Convert to suggestion
            let progressionSuggestion = response.toSuggestion()

            // Update published state
            self.suggestion = progressionSuggestion

            DebugLogger.shared.success("PROGRESSION_AI", "Suggestion received: \(progressionSuggestion.progressionType.rawValue)")
            DebugLogger.shared.info("PROGRESSION_AI", "Next load: \(progressionSuggestion.nextLoad), confidence: \(progressionSuggestion.confidence)%")

            return progressionSuggestion

        } catch let functionsError as Supabase.FunctionsError {
            handleFunctionsError(functionsError)
            throw functionsError
        } catch let progressionError as ProgressionError {
            throw progressionError
        } catch {
            let errorMessage = "Failed to get progression suggestion. Please try again."
            DebugLogger.shared.error("PROGRESSION_AI", "Error: \(error)")
            self.error = errorMessage
            throw error
        }
    }

    /// Get AI-powered progression suggestion using current session data (legacy support)
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - exerciseTemplateId: The exercise template UUID
    ///   - currentLoad: Current load being used (in lbs)
    ///   - currentReps: Current rep count
    ///   - recentRPE: Most recent RPE rating (0-10)
    /// - Returns: The progression suggestion
    @discardableResult
    func getSuggestion(
        patientId: UUID,
        exerciseTemplateId: UUID,
        currentLoad: Double,
        currentReps: Int,
        recentRPE: Double
    ) async throws -> ProgressionSuggestion {
        // Convert to performance entry format
        let entry = PerformanceEntry(
            date: Date(),
            load: currentLoad,
            reps: [currentReps],
            rpe: recentRPE
        )
        return try await getSuggestion(
            patientId: patientId,
            exerciseTemplateId: exerciseTemplateId,
            recentPerformance: [entry]
        )
    }

    /// Get AI-powered progression suggestion for an exercise (simplified API)
    /// Uses the current authenticated user from PTSupabaseClient
    /// - Parameters:
    ///   - exerciseTemplateId: The exercise template UUID
    ///   - recentPerformance: Array of recent performance entries
    /// - Returns: The progression suggestion
    @discardableResult
    func getProgressionSuggestion(
        exerciseTemplateId: UUID,
        recentPerformance: [ExercisePerformance]
    ) async throws -> ProgressionSuggestion {
        // Get current patient ID from the Supabase client
        guard let patientId = PTSupabaseClient.shared.currentUser?.id else {
            throw ProgressionError.serverError("Not authenticated")
        }

        return try await getSuggestion(
            patientId: patientId,
            exerciseTemplateId: exerciseTemplateId,
            recentPerformance: recentPerformance
        )
    }

    /// Fetch exercise history for a given exercise template
    /// - Parameters:
    ///   - exerciseTemplateId: The exercise template UUID
    ///   - days: Number of days of history to fetch (default 30)
    /// - Returns: Array of performance entries sorted by date descending
    func getExerciseHistory(
        exerciseTemplateId: UUID,
        days: Int = 30
    ) async throws -> [ExercisePerformance] {
        // Get current patient ID from the Supabase client
        guard let patientId = PTSupabaseClient.shared.currentUser?.id else {
            throw ProgressionError.serverError("Not authenticated")
        }

        DebugLogger.shared.info("PROGRESSION_AI", "Fetching exercise history for template \(exerciseTemplateId)")

        // Calculate the date range
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let dateFormatter = ISO8601DateFormatter()

        do {
            // Fetch from load_progression_history table
            let response = try await client.client
                .from("load_progression_history")
                .select("logged_at, current_load, reps_completed, actual_rpe")
                .eq("patient_id", value: patientId.uuidString)
                .eq("exercise_template_id", value: exerciseTemplateId.uuidString)
                .gte("logged_at", value: dateFormatter.string(from: startDate))
                .order("logged_at", ascending: false)
                .execute()

            // Decode the response
            struct HistoryEntry: Codable {
                let loggedAt: Date
                let currentLoad: Double
                let repsCompleted: Int?
                let actualRpe: Double?

                enum CodingKeys: String, CodingKey {
                    case loggedAt = "logged_at"
                    case currentLoad = "current_load"
                    case repsCompleted = "reps_completed"
                    case actualRpe = "actual_rpe"
                }
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let entries = try decoder.decode([HistoryEntry].self, from: response.data)

            // Convert to ExercisePerformance format
            let performance = entries.map { entry in
                ExercisePerformance(
                    date: entry.loggedAt,
                    load: entry.currentLoad,
                    reps: [entry.repsCompleted ?? 8],  // Default to 8 if not recorded
                    rpe: entry.actualRpe ?? 7.0  // Default to RPE 7 if not recorded
                )
            }

            DebugLogger.shared.success("PROGRESSION_AI", "Fetched \(performance.count) history entries")
            return performance

        } catch {
            DebugLogger.shared.error("PROGRESSION_AI", "Failed to fetch exercise history: \(error)")
            throw ProgressionError.serverError("Failed to fetch exercise history")
        }
    }

    /// Accept a progression suggestion
    /// - Parameter suggestionId: The UUID of the suggestion to accept
    func acceptSuggestion(suggestionId: UUID) async throws {
        DebugLogger.shared.info("PROGRESSION_AI", "Accepting suggestion: \(suggestionId)")

        do {
            // Update suggestion status in database
            let updateInput = AcceptSuggestionUpdate(
                status: "accepted",
                acceptedAt: ISO8601DateFormatter().string(from: Date())
            )
            try await client.client
                .from("progression_suggestions")
                .update(updateInput)
                .eq("id", value: suggestionId.uuidString)
                .execute()

            DebugLogger.shared.success("PROGRESSION_AI", "Suggestion accepted successfully")

            // Clear local suggestion if it matches
            if suggestion?.id == suggestionId {
                suggestion = nil
            }
        } catch {
            DebugLogger.shared.error("PROGRESSION_AI", "Failed to accept suggestion: \(error)")
            throw ProgressionError.serverError("Failed to accept suggestion")
        }
    }

    /// Dismiss a progression suggestion
    /// - Parameter suggestionId: The UUID of the suggestion to dismiss
    func dismissSuggestion(suggestionId: UUID) async throws {
        DebugLogger.shared.info("PROGRESSION_AI", "Dismissing suggestion: \(suggestionId)")

        do {
            // Update suggestion status in database
            let updateInput = DismissSuggestionUpdate(
                status: "dismissed",
                dismissedAt: ISO8601DateFormatter().string(from: Date())
            )
            try await client.client
                .from("progression_suggestions")
                .update(updateInput)
                .eq("id", value: suggestionId.uuidString)
                .execute()

            DebugLogger.shared.success("PROGRESSION_AI", "Suggestion dismissed successfully")

            // Clear local suggestion if it matches
            if suggestion?.id == suggestionId {
                suggestion = nil
            }
        } catch {
            DebugLogger.shared.error("PROGRESSION_AI", "Failed to dismiss suggestion: \(error)")
            throw ProgressionError.serverError("Failed to dismiss suggestion")
        }
    }

    /// Clear the current suggestion and reset state
    func clearSuggestion() {
        suggestion = nil
        error = nil
        isLoading = false
    }

    // MARK: - Performance Analysis

    /// Analyze performance trend for an exercise based on recent history
    /// Analyzes the last 3-5 sessions to determine if performance is improving, plateaued, or declining
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - exerciseTemplateId: The exercise template UUID
    /// - Returns: Performance analysis with trend, estimated 1RM, and session count
    func analyzePerformanceTrend(
        patientId: UUID,
        exerciseTemplateId: UUID
    ) async throws -> PerformanceAnalysis {
        isLoading = true
        defer { isLoading = false }

        // Fetch recent performance history (last 30 days)
        let history = try await fetchPerformanceHistory(
            patientId: patientId,
            exerciseTemplateId: exerciseTemplateId,
            days: 30
        )

        // Need at least 2 sessions to analyze trend
        guard history.count >= 2 else {
            return PerformanceAnalysis(
                trend: .plateaued,
                estimated1RM: history.first.map { calculateEstimated1RM(weight: $0.load, reps: Int($0.averageReps), rpe: $0.rpe) },
                velocityTrend: nil,
                fatigueImpact: nil,
                recentSessions: history.count
            )
        }

        // Take the most recent 3-5 sessions for analysis
        let sessionsToAnalyze = Array(history.prefix(5))
        let recentSessions = sessionsToAnalyze.count

        // Calculate trend based on volume progression
        let trend = calculateTrend(from: sessionsToAnalyze)

        // Calculate estimated 1RM from most recent session
        let mostRecent = sessionsToAnalyze[0]
        let estimated1RM = calculateEstimated1RM(
            weight: mostRecent.load,
            reps: Int(mostRecent.averageReps),
            rpe: mostRecent.rpe
        )

        // Determine velocity trend based on RPE changes
        let velocityTrend = calculateVelocityTrend(from: sessionsToAnalyze)

        // Assess fatigue impact based on RPE and rep performance
        let fatigueImpact = assessFatigueImpact(from: sessionsToAnalyze)

        let analysis = PerformanceAnalysis(
            trend: trend,
            estimated1RM: estimated1RM,
            velocityTrend: velocityTrend,
            fatigueImpact: fatigueImpact,
            recentSessions: recentSessions
        )

        DebugLogger.shared.success("PROGRESSION_AI", """
            Performance analysis complete:
            Trend: \(trend.displayText)
            Estimated 1RM: \(analysis.estimated1RMFormatted)
            Sessions analyzed: \(recentSessions)
            """)

        return analysis
    }

    /// Calculate estimated 1RM using the Epley formula
    /// Formula: weight * (1 + reps/30)
    /// Optionally adjusts for RPE if provided
    /// - Parameters:
    ///   - weight: The weight lifted (in lbs)
    ///   - reps: Number of repetitions performed
    ///   - rpe: Optional Rate of Perceived Exertion (0-10 scale)
    /// - Returns: Estimated one-rep max
    nonisolated func calculateEstimated1RM(
        weight: Double,
        reps: Int,
        rpe: Double? = nil
    ) -> Double {
        guard reps > 0 else { return weight }

        // Epley formula: weight * (1 + reps/30)
        var estimated1RM = weight * (1.0 + Double(reps) / 30.0)

        // Adjust for RPE if provided (RPE 10 = true max, lower RPE means more in tank)
        if let rpe = rpe, rpe > 0 && rpe < 10 {
            // Estimate reps in reserve based on RPE (10 - RPE = RIR)
            let repsInReserve = 10.0 - rpe
            // Adjust 1RM estimate upward based on RIR
            let adjustmentFactor = 1.0 + (repsInReserve * 0.033)
            estimated1RM *= adjustmentFactor
        }

        return estimated1RM
    }

    /// Generate a local progression suggestion based on RPE-based rules
    /// Use this when offline or as a fallback to the AI edge function
    /// - Parameters:
    ///   - recentPerformance: Array of recent performance entries (most recent first)
    ///   - targetReps: Target rep count for the exercise (default 8)
    ///   - deloadActive: Whether a deload period is currently active
    ///   - deloadReductionPct: Deload load reduction percentage (default 0.15 = 15%)
    /// - Returns: A progression suggestion based on local rules
    nonisolated func generateLocalSuggestion(
        recentPerformance: [ExercisePerformance],
        targetReps: Int = 8,
        deloadActive: Bool = false,
        deloadReductionPct: Double = 0.15
    ) -> ProgressionSuggestion {
        guard let mostRecent = recentPerformance.first else {
            // No data - suggest starting weight
            return ProgressionSuggestion(
                id: UUID(),
                nextLoad: 0,
                nextReps: targetReps,
                confidence: 0,
                reasoning: "No previous performance data available. Start with a weight that allows you to complete all reps with good form.",
                progressionType: .hold,
                analysis: PerformanceAnalysis(
                    trend: .plateaued,
                    estimated1RM: nil,
                    velocityTrend: nil,
                    fatigueImpact: nil,
                    recentSessions: 0
                )
            )
        }

        let currentLoad = mostRecent.load
        let currentRPE = mostRecent.rpe
        let hitTargetReps = mostRecent.reps.allSatisfy { $0 >= targetReps }

        // Calculate base metrics
        let sessionsCount = min(recentPerformance.count, 5)
        let trend = sessionsCount >= 2 ? calculateTrendSync(from: Array(recentPerformance.prefix(5))) : PerformanceTrend.plateaued
        let estimated1RM = calculateEstimated1RM(weight: currentLoad, reps: Int(mostRecent.averageReps), rpe: currentRPE)

        // Confidence based on data quality (more sessions = higher confidence)
        let baseConfidence: Double
        switch sessionsCount {
        case 0...1: baseConfidence = 40
        case 2: baseConfidence = 55
        case 3: baseConfidence = 70
        case 4: baseConfidence = 80
        default: baseConfidence = 85
        }

        // Apply deload if active
        if deloadActive {
            let deloadLoad = currentLoad * (1.0 - deloadReductionPct)
            return ProgressionSuggestion(
                id: UUID(),
                nextLoad: deloadLoad,
                nextReps: targetReps,
                confidence: baseConfidence + 5,  // High confidence for deload
                reasoning: "Deload period active. Reducing load by \(Int(deloadReductionPct * 100))% to support recovery.",
                progressionType: .deload,
                analysis: PerformanceAnalysis(
                    trend: trend,
                    estimated1RM: estimated1RM,
                    velocityTrend: "deload",
                    fatigueImpact: "recovery focus",
                    recentSessions: sessionsCount
                )
            )
        }

        // Progressive overload rules based on RPE
        let progressionType: ProgressionType
        let nextLoad: Double
        let reasoning: String

        if currentRPE < 7 && hitTargetReps {
            // RPE < 7 and hit target reps: suggest +2.5-5% load increase
            let increasePercent = currentRPE < 6 ? 0.05 : 0.025  // 5% if RPE very low, 2.5% otherwise
            nextLoad = currentLoad * (1.0 + increasePercent)
            progressionType = .increase
            reasoning = "RPE of \(String(format: "%.1f", currentRPE)) with all target reps completed indicates room for progression. Increasing load by \(Int(increasePercent * 100))%."
        } else if currentRPE >= 7 && currentRPE <= 8 && hitTargetReps {
            // RPE 7-8 and hit target: hold or small increase
            if currentRPE <= 7.5 {
                nextLoad = currentLoad * 1.025  // Small 2.5% increase
                progressionType = .increase
                reasoning = "RPE of \(String(format: "%.1f", currentRPE)) with target reps completed. Small load increase appropriate."
            } else {
                nextLoad = currentLoad
                progressionType = .hold
                reasoning = "RPE of \(String(format: "%.1f", currentRPE)) is optimal. Maintain current load to solidify adaptation."
            }
        } else if currentRPE > 8 || !hitTargetReps {
            // RPE > 8 or missed reps: hold or decrease
            if currentRPE > 9 || mostRecent.reps.contains(where: { $0 < targetReps - 2 }) {
                nextLoad = currentLoad * 0.95  // 5% decrease
                progressionType = .decrease
                reasoning = "RPE of \(String(format: "%.1f", currentRPE)) or significantly missed reps indicates load may be too high. Reducing by 5%."
            } else {
                nextLoad = currentLoad
                progressionType = .hold
                reasoning = "RPE of \(String(format: "%.1f", currentRPE)) or slightly missed reps. Hold current load until adaptation occurs."
            }
        } else {
            nextLoad = currentLoad
            progressionType = .hold
            reasoning = "Maintaining current load based on recent performance."
        }

        // Assess fatigue impact
        let averageRPE = recentPerformance.prefix(3).reduce(0.0) { $0 + $1.rpe } / Double(min(3, recentPerformance.count))
        let fatigueImpact: String
        if averageRPE > 8.5 {
            fatigueImpact = "high - monitor recovery"
        } else if averageRPE > 7.5 {
            fatigueImpact = "moderate - good training stimulus"
        } else {
            fatigueImpact = "low - good for progression"
        }

        return ProgressionSuggestion(
            id: UUID(),
            nextLoad: nextLoad,
            nextReps: targetReps,
            confidence: baseConfidence,
            reasoning: reasoning,
            progressionType: progressionType,
            analysis: PerformanceAnalysis(
                trend: trend,
                estimated1RM: estimated1RM,
                velocityTrend: trend == .improving ? "stable" : (trend == .declining ? "decreasing" : "stable"),
                fatigueImpact: fatigueImpact,
                recentSessions: sessionsCount
            )
        )
    }

    // MARK: - Private Analysis Helpers

    /// Fetch performance history for a patient and exercise
    private func fetchPerformanceHistory(
        patientId: UUID,
        exerciseTemplateId: UUID,
        days: Int
    ) async throws -> [ExercisePerformance] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let dateFormatter = ISO8601DateFormatter()

        do {
            let response = try await client.client
                .from("load_progression_history")
                .select("logged_at, current_load, reps_completed, actual_rpe")
                .eq("patient_id", value: patientId.uuidString)
                .eq("exercise_template_id", value: exerciseTemplateId.uuidString)
                .gte("logged_at", value: dateFormatter.string(from: startDate))
                .order("logged_at", ascending: false)
                .execute()

            struct HistoryEntry: Codable {
                let loggedAt: Date
                let currentLoad: Double
                let repsCompleted: Int?
                let actualRpe: Double?

                enum CodingKeys: String, CodingKey {
                    case loggedAt = "logged_at"
                    case currentLoad = "current_load"
                    case repsCompleted = "reps_completed"
                    case actualRpe = "actual_rpe"
                }
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let entries = try decoder.decode([HistoryEntry].self, from: response.data)

            return entries.map { entry in
                ExercisePerformance(
                    date: entry.loggedAt,
                    load: entry.currentLoad,
                    reps: [entry.repsCompleted ?? 8],
                    rpe: entry.actualRpe ?? 7.0
                )
            }
        } catch {
            DebugLogger.shared.error("PROGRESSION_AI", "Failed to fetch performance history: \(error)")
            throw ProgressionError.serverError("Failed to fetch performance history")
        }
    }

    /// Calculate trend from performance sessions (async version)
    private func calculateTrend(from sessions: [ExercisePerformance]) -> PerformanceTrend {
        calculateTrendSync(from: sessions)
    }

    /// Calculate trend from performance sessions (sync version for local suggestions)
    private nonisolated func calculateTrendSync(from sessions: [ExercisePerformance]) -> PerformanceTrend {
        guard sessions.count >= 2 else { return .plateaued }

        // Compare volume over time (most recent vs oldest in window)
        let recentVolume = sessions[0].totalVolume
        let olderVolume = sessions[sessions.count - 1].totalVolume

        let volumeChange = (recentVolume - olderVolume) / olderVolume

        // Also consider load progression
        let recentLoad = sessions[0].load
        let olderLoad = sessions[sessions.count - 1].load
        let loadChange = (recentLoad - olderLoad) / olderLoad

        // Combined metric
        let combinedChange = (volumeChange + loadChange) / 2.0

        if combinedChange > 0.02 {  // >2% improvement
            return .improving
        } else if combinedChange < -0.02 {  // >2% decline
            return .declining
        } else {
            return .plateaued
        }
    }

    /// Calculate velocity trend based on RPE changes
    private func calculateVelocityTrend(from sessions: [ExercisePerformance]) -> String {
        guard sessions.count >= 2 else { return "insufficient data" }

        let recentRPE = sessions[0].rpe
        let olderRPE = sessions[sessions.count - 1].rpe

        // Same or more reps at same/higher load with lower RPE = improving velocity
        // Higher RPE for same work = declining velocity
        if recentRPE < olderRPE - 0.5 {
            return "improving"
        } else if recentRPE > olderRPE + 0.5 {
            return "declining"
        } else {
            return "stable"
        }
    }

    /// Assess fatigue impact based on recent sessions
    private func assessFatigueImpact(from sessions: [ExercisePerformance]) -> String {
        let averageRPE = sessions.reduce(0.0) { $0 + $1.rpe } / Double(sessions.count)

        // Check for declining rep performance
        let recentReps = sessions[0].averageReps
        let hasDecreasingReps = sessions.count >= 2 && recentReps < sessions[1].averageReps

        if averageRPE > 8.5 || hasDecreasingReps {
            return "high - consider recovery"
        } else if averageRPE > 7.5 {
            return "moderate - good training stimulus"
        } else {
            return "low - good for progression"
        }
    }

    // MARK: - Private Methods

    private func handleFunctionsError(_ error: Supabase.FunctionsError) {
        switch error {
        case .httpError(let statusCode, let data):
            DebugLogger.shared.error("PROGRESSION_AI", "HTTP error \(statusCode)")
            if let errorString = String(data: data, encoding: .utf8) {
                DebugLogger.shared.error("PROGRESSION_AI", "Error body: \(errorString)")
            }
            self.error = "Server error occurred. Please try again later."
        case .relayError:
            DebugLogger.shared.error("PROGRESSION_AI", "Relay error - connection issue")
            self.error = "Connection failed. Please check your internet connection."
        }
    }
}

// MARK: - Errors

enum ProgressionError: LocalizedError {
    case serverError(String)
    case invalidResponse
    case noData

    var errorDescription: String? {
        switch self {
        case .serverError(let message):
            return message
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .noData:
            return "No progression data available."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .serverError:
            return "Please try again. If the problem persists, contact support."
        case .invalidResponse:
            return "There was a problem processing the AI recommendation. Please try again."
        case .noData:
            return "Complete a few workouts with this exercise to get progression suggestions."
        }
    }
}

// MARK: - Preview Support

#if DEBUG
extension ProgressiveOverloadAIService {
    /// Create a mock service with sample data for previews
    static var preview: ProgressiveOverloadAIService {
        let service = ProgressiveOverloadAIService()
        service.suggestion = ProgressionSuggestion(
            id: UUID(),
            nextLoad: 137.5,
            nextReps: 8,
            confidence: 82,
            reasoning: "Based on consistent RPE of 7.5 across 3 sessions at 135 lbs, a 2.5 lb increase is appropriate for continued progressive overload.",
            progressionType: .increase,
            analysis: PerformanceAnalysis(
                trend: .improving,
                estimated1RM: 172.5,
                velocityTrend: "stable",
                fatigueImpact: "low - good for progression",
                recentSessions: 3
            )
        )
        return service
    }

    /// Create a mock deload suggestion for previews
    static var previewDeload: ProgressiveOverloadAIService {
        let service = ProgressiveOverloadAIService()
        service.suggestion = ProgressionSuggestion(
            id: UUID(),
            nextLoad: 115,
            nextReps: 6,
            confidence: 88,
            reasoning: "High fatigue detected with declining readiness scores. A deload week with 15% load reduction is recommended to support recovery.",
            progressionType: .deload,
            analysis: PerformanceAnalysis(
                trend: .declining,
                estimated1RM: 155,
                velocityTrend: "decreasing",
                fatigueImpact: "high - consider deload",
                recentSessions: 5
            )
        )
        return service
    }
}
#endif

// MARK: - Sample Data

extension ExercisePerformance {
    /// Sample performance entries for testing
    static var sampleEntries: [ExercisePerformance] {
        let calendar = Calendar.current
        var entries: [ExercisePerformance] = []

        if let date1 = calendar.date(byAdding: .day, value: -1, to: Date()) {
            entries.append(ExercisePerformance(date: date1, load: 135, reps: [8, 8, 7], rpe: 7.5))
        }
        if let date2 = calendar.date(byAdding: .day, value: -4, to: Date()) {
            entries.append(ExercisePerformance(date: date2, load: 135, reps: [8, 8, 8], rpe: 7.0))
        }
        if let date3 = calendar.date(byAdding: .day, value: -7, to: Date()) {
            entries.append(ExercisePerformance(date: date3, load: 132.5, reps: [8, 8, 8], rpe: 7.0))
        }

        return entries
    }
}

extension ProgressionSuggestion {
    /// Sample suggestion for testing
    static var sample: ProgressionSuggestion {
        ProgressionSuggestion(
            id: UUID(),
            nextLoad: 137.5,
            nextReps: 8,
            confidence: 82,
            reasoning: "Based on consistent RPE of 7.5 across 3 sessions at 135 lbs, a 2.5 lb increase is appropriate for continued progressive overload.",
            progressionType: .increase,
            analysis: PerformanceAnalysis(
                trend: .improving,
                estimated1RM: 172.5,
                velocityTrend: "stable",
                fatigueImpact: "low - good for progression",
                recentSessions: 3
            )
        )
    }
}

extension PerformanceAnalysis {
    /// Sample analysis for testing
    static var sample: PerformanceAnalysis {
        PerformanceAnalysis(
            trend: .improving,
            estimated1RM: 172.5,
            velocityTrend: "stable",
            fatigueImpact: "low - good for progression",
            recentSessions: 3
        )
    }

    /// Sample declining analysis for testing
    static var decliningsSample: PerformanceAnalysis {
        PerformanceAnalysis(
            trend: .declining,
            estimated1RM: 155.0,
            velocityTrend: "decreasing",
            fatigueImpact: "high - consider deload",
            recentSessions: 5
        )
    }
}
