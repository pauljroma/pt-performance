//
//  StrengthAnalyticsService.swift
//  PTPerformance
//
//  Service for strength progression and PR tracking analytics
//  Extracted from AnalyticsService for single responsibility
//

import Foundation
import Supabase

/// Service responsible for strength progression and personal record tracking
///
/// Provides methods for analyzing exercise-specific strength progression over time,
/// calculating estimated one-rep maxes using the Epley formula, and identifying
/// personal records. Queries data from both prescribed and manual workout sessions.
///
/// ## Usage Example
/// ```swift
/// let strengthService = StrengthAnalyticsService()
///
/// // Get strength progression for an exercise
/// let chartData = try await strengthService.calculateStrengthData(
///     for: patientId,
///     exerciseId: benchPressId,
///     period: .lastMonth
/// )
///
/// // Calculate estimated 1RM
/// let oneRepMax = strengthService.calculateOneRepMax(weight: 185, reps: 5)
/// // Returns ~213 lbs
/// ```
final class StrengthAnalyticsService {

    // MARK: - Dependencies

    private let supabase: PTSupabaseClient
    private let errorLogger = ErrorLogger.shared

    // MARK: - Initialization

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
    }

    // MARK: - Public Methods

    /// Calculate strength progression for a specific exercise
    /// - Parameters:
    ///   - patientId: The patient UUID
    ///   - exerciseId: The exercise UUID to track
    ///   - period: Time period for the query
    /// - Returns: Strength chart data with progression metrics
    func calculateStrengthData(
        for patientId: String,
        exerciseId: String,
        period: TimePeriod
    ) async throws -> StrengthChartData {
        let logs = try await fetchExerciseLogs(
            patientId: patientId,
            exerciseId: exerciseId,
            startDate: period.startDate
        )

        guard let exerciseName = logs.first?.exercise?.name ?? logs.first?.exerciseId.uuidString else {
            throw AnalyticsError.noData
        }

        let dataPoints = logs.compactMap { log -> StrengthDataPoint? in
            guard let weight = log.weight, let reps = log.reps else { return nil }
            let estimatedMax = calculateOneRepMax(weight: weight, reps: reps)

            return StrengthDataPoint(
                date: log.createdAt,
                exerciseName: exerciseName,
                weight: weight,
                reps: reps,
                estimatedOneRepMax: estimatedMax
            )
        }
        .sorted { $0.date < $1.date }

        guard !dataPoints.isEmpty else {
            throw AnalyticsError.noData
        }

        let currentMax = dataPoints.last?.estimatedOneRepMax ?? 0
        let startingMax = dataPoints.first?.estimatedOneRepMax ?? 0
        let improvement = startingMax > 0 ? (currentMax - startingMax) / startingMax : 0

        return StrengthChartData(
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            dataPoints: dataPoints,
            period: period,
            currentMax: currentMax,
            startingMax: startingMax,
            improvement: improvement
        )
    }

    /// Fetch exercise progress time-series data for charting
    /// Queries both exercise_logs (prescribed workouts) and manual_session_exercises (manual workouts)
    /// - Parameters:
    ///   - patientId: The patient UUID
    ///   - exerciseName: The exercise name to query
    ///   - limit: Maximum number of data points (default 50)
    /// - Returns: Array of progress data points sorted by date
    func fetchExerciseProgressTimeSeries(
        patientId: String,
        exerciseName: String,
        limit: Int = 50
    ) async throws -> [ExerciseProgressDataPoint] {
        var allDataPoints: [ExerciseProgressDataPoint] = []

        // Query 1: Fetch from exercise_logs (prescribed sessions)
        do {
            let prescribedResponse = try await supabase.client
                .from("exercise_logs")
                .select("""
                    id,
                    logged_at,
                    actual_load,
                    actual_reps,
                    actual_sets,
                    session_exercises!inner(
                        exercise_templates!inner(
                            exercise_name
                        )
                    )
                """)
                .eq("patient_id", value: patientId)
                .eq("session_exercises.exercise_templates.exercise_name", value: exerciseName)
                .order("logged_at", ascending: true)
                .limit(limit)
                .execute()

            struct PrescribedLogRow: Codable {
                let id: UUID
                let logged_at: Date
                let actual_load: Double?
                let actual_reps: [Int]
                let actual_sets: Int

                struct SessionExerciseJoin: Codable {
                    let exercise_templates: ExerciseTemplateJoin
                }
                struct ExerciseTemplateJoin: Codable {
                    let exercise_name: String
                }
                let session_exercises: SessionExerciseJoin
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let rows = try decoder.decode([PrescribedLogRow].self, from: prescribedResponse.data)

            for row in rows {
                let weight = row.actual_load ?? 0
                let reps = row.actual_reps.first ?? 0
                let sets = row.actual_sets
                allDataPoints.append(ExerciseProgressDataPoint(
                    id: row.id.uuidString,
                    date: row.logged_at,
                    weight: weight,
                    reps: reps,
                    sets: sets,
                    volume: weight * Double(reps) * Double(sets),
                    isPersonalRecord: false
                ))
            }
        } catch {
            errorLogger.logError(error, context: "Fetching prescribed exercise logs for \(exerciseName)")
        }

        // Query 2: Fetch from manual_session_exercises (manual workouts)
        do {
            let manualResponse = try await supabase.client
                .from("manual_session_exercises")
                .select("""
                    id,
                    created_at,
                    target_load,
                    target_reps,
                    target_sets,
                    manual_sessions!inner(
                        patient_id,
                        completed
                    )
                """)
                .eq("manual_sessions.patient_id", value: patientId)
                .eq("manual_sessions.completed", value: true)
                .ilike("exercise_name", pattern: exerciseName)
                .order("created_at", ascending: true)
                .limit(limit)
                .execute()

            struct ManualExerciseRow: Codable {
                let id: UUID
                let created_at: Date
                let target_load: Double?
                let target_reps: String?
                let target_sets: Int?

                struct ManualSessionJoin: Codable {
                    let patient_id: String
                    let completed: Bool
                }
                let manual_sessions: ManualSessionJoin
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let rows = try decoder.decode([ManualExerciseRow].self, from: manualResponse.data)

            for row in rows {
                let weight = row.target_load ?? 0
                let reps = parseRepsString(row.target_reps)
                let sets = row.target_sets ?? 1

                allDataPoints.append(ExerciseProgressDataPoint(
                    id: row.id.uuidString,
                    date: row.created_at,
                    weight: weight,
                    reps: reps,
                    sets: sets,
                    volume: weight * Double(reps) * Double(sets),
                    isPersonalRecord: false
                ))
            }
        } catch {
            errorLogger.logError(error, context: "Fetching manual exercise logs for \(exerciseName)")
        }

        // Sort all data points by date ascending
        allDataPoints.sort { $0.date < $1.date }

        // Mark personal records (highest weight achieved)
        allDataPoints = markPersonalRecords(in: allDataPoints)

        return Array(allDataPoints.suffix(limit))
    }

    /// Calculate estimated one-rep max using Epley formula
    /// - Parameters:
    ///   - weight: Weight lifted
    ///   - reps: Number of repetitions
    /// - Returns: Estimated 1RM
    func calculateOneRepMax(weight: Double, reps: Int) -> Double {
        guard reps > 0 else { return weight }
        return weight * (1 + Double(reps) / 30.0)
    }

    // MARK: - Private Methods

    /// Fetch exercise logs for a specific exercise
    private func fetchExerciseLogs(
        patientId: String,
        exerciseId: String,
        startDate: Date
    ) async throws -> [ExerciseLog] {
        let result = try await supabase.client
            .from("exercise_logs")
            .select()
            .eq("patient_id", value: patientId)
            .eq("session_exercise_id", value: exerciseId)
            .gte("logged_at", value: startDate.iso8601String)
            .order("logged_at", ascending: true)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode([ExerciseLog].self, from: result.data)
    }

    /// Parse reps from string format (e.g., "8" or "8,8,8")
    private func parseRepsString(_ repsStr: String?) -> Int {
        guard let repsStr = repsStr else { return 0 }
        let parsed = repsStr.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        if let firstParsed = parsed.first {
            return firstParsed
        } else if let directParsed = Int(repsStr) {
            return directParsed
        }
        #if DEBUG
        DebugLogger.shared.warning("ANALYTICS", "Failed to parse reps from string: '\(repsStr)', using default 0")
        #endif
        return 0
    }

    /// Mark personal records in data points
    private func markPersonalRecords(in dataPoints: [ExerciseProgressDataPoint]) -> [ExerciseProgressDataPoint] {
        guard !dataPoints.isEmpty else { return dataPoints }

        var maxWeight: Double = 0
        return dataPoints.map { point in
            if point.weight > maxWeight {
                maxWeight = point.weight
                return ExerciseProgressDataPoint(
                    id: point.id,
                    date: point.date,
                    weight: point.weight,
                    reps: point.reps,
                    sets: point.sets,
                    volume: point.volume,
                    isPersonalRecord: true
                )
            }
            return point
        }
    }
}

// MARK: - Date Extension

private extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}

// MARK: - Exercise Progress Data Point

/// Data point for exercise progress chart
struct ExerciseProgressDataPoint: Codable, Identifiable {
    let id: String
    let date: Date
    let weight: Double
    let reps: Int
    let sets: Int
    let volume: Double
    let isPersonalRecord: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case date = "logged_at"
        case weight = "actual_load"
        case reps = "actual_reps"
        case sets = "actual_sets"
        case volume
        case isPersonalRecord = "is_pr"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.date = try container.decode(Date.self, forKey: .date)
        self.weight = try container.decodeIfPresent(Double.self, forKey: .weight) ?? 0
        // Handle reps as either Int or [Int] (takes first value or sum)
        if let repsArray = try? container.decode([Int].self, forKey: .reps) {
            self.reps = repsArray.first ?? 0
        } else if let repsInt = try? container.decode(Int.self, forKey: .reps) {
            self.reps = repsInt
        } else {
            self.reps = 0
        }
        self.sets = try container.decodeIfPresent(Int.self, forKey: .sets) ?? 1
        // Calculate volume if not provided
        if let vol = try? container.decode(Double.self, forKey: .volume) {
            self.volume = vol
        } else {
            self.volume = self.weight * Double(self.reps) * Double(self.sets)
        }
        self.isPersonalRecord = try container.decodeIfPresent(Bool.self, forKey: .isPersonalRecord) ?? false
    }

    init(id: String, date: Date, weight: Double, reps: Int, sets: Int, volume: Double, isPersonalRecord: Bool) {
        self.id = id
        self.date = date
        self.weight = weight
        self.reps = reps
        self.sets = sets
        self.volume = volume
        self.isPersonalRecord = isPersonalRecord
    }
}
