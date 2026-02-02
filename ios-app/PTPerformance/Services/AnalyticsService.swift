import Foundation
import Supabase

/// Data point for pain trend chart
struct PainDataPoint: Codable, Identifiable {
    let id: String
    let date: Date
    let painScore: Double
    let sessionNumber: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case date = "logged_date"
        case painScore = "avg_pain"
        case sessionNumber = "session_number"
    }
}

/// Adherence data
struct AdherenceData: Codable {
    let adherencePercentage: Double
    let completedSessions: Int
    let totalSessions: Int
    let weeklyBreakdown: [WeeklyAdherence]?

    enum CodingKeys: String, CodingKey {
        case adherencePercentage = "adherence_pct"
        case completedSessions = "completed_sessions"
        case totalSessions = "total_sessions"
        case weeklyBreakdown = "weekly_breakdown"
    }
}

struct WeeklyAdherence: Codable, Identifiable {
    let id: String
    let weekNumber: Int
    let adherencePercentage: Double

    enum CodingKeys: String, CodingKey {
        case id
        case weekNumber = "week_number"
        case adherencePercentage = "adherence_pct"
    }
}

/// Session summary for history list
/// BUILD 269: Added completion metrics for history display
struct SessionSummary: Codable, Identifiable {
    let id: String
    let sessionNumber: Int
    let sessionDate: Date
    let completed: Bool
    let exerciseCount: Int
    let avgPainScore: Double?
    // BUILD 269: Additional fields for completed session display
    let completedAt: Date?
    let totalVolume: Double?
    let avgRpe: Double?
    let durationMinutes: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case sessionNumber = "session_number"
        case sessionDate = "session_date"
        case completed
        case exerciseCount = "exercise_count"
        case avgPainScore = "avg_pain_score"
        case completedAt = "completed_at"
        case totalVolume = "total_volume"
        case avgRpe = "avg_rpe"
        case durationMinutes = "duration_minutes"
    }
}

/// Service for fetching analytics data
class AnalyticsService {
    // MARK: - Singleton

    static let shared = AnalyticsService()

    private let supabase: PTSupabaseClient
    private let errorLogger = ErrorLogger.shared

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
    }

    /// Fetch pain trend data from vw_pain_trend view
    func fetchPainTrend(patientId: String, days: Int = 14) async throws -> [PainDataPoint] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        let response = try await supabase.client
            .from("vw_pain_trend")
            .select()
            .eq("patient_id", value: patientId)
            .gte("logged_date", value: ISO8601DateFormatter().string(from: startDate))
            .order("logged_date", ascending: true)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let dataPoints = try decoder.decode([PainDataPoint].self, from: response.data)
        return dataPoints
    }

    /// Fetch adherence data from vw_patient_adherence view
    func fetchAdherence(patientId: String, days: Int = 30) async throws -> AdherenceData {
        let response = try await supabase.client
            .from("vw_patient_adherence")
            .select()
            .eq("patient_id", value: patientId)
            .single()
            .execute()

        let adherence = try JSONDecoder().decode(AdherenceData.self, from: response.data)
        return adherence
    }

    /// Fetch recent completed session summaries for history view
    /// BUILD 269: Filter to only show completed sessions in history
    func fetchRecentSessions(patientId: String, limit: Int = 10) async throws -> [SessionSummary] {
        let response = try await supabase.client
            .from("vw_patient_sessions")
            .select("""
                id,
                session_number,
                session_date,
                completed,
                exercise_count,
                avg_pain_score,
                completed_at,
                total_volume,
                avg_rpe,
                duration_minutes
            """)
            .eq("patient_id", value: patientId)
            .eq("completed", value: true)  // BUILD 269: Only show completed sessions
            .order("completed_at", ascending: false)  // BUILD 269: Order by completion time
            .limit(limit)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let sessions = try decoder.decode([SessionSummary].self, from: response.data)
        return sessions
    }

    /// Fetch recent completed sessions with pagination support
    func fetchRecentSessionsPaginated(patientId: String, limit: Int = 20, offset: Int = 0) async throws -> [SessionSummary] {
        let response = try await supabase.client
            .from("vw_patient_sessions")
            .select("""
                id,
                session_number,
                session_date,
                completed,
                exercise_count,
                avg_pain_score,
                completed_at,
                total_volume,
                avg_rpe,
                duration_minutes
            """)
            .eq("patient_id", value: patientId)
            .eq("completed", value: true)
            .order("completed_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let sessions = try decoder.decode([SessionSummary].self, from: response.data)
        return sessions
    }

    // MARK: - BUILD 219: Manual Workout History

    /// Summary of a completed manual workout for history display
    struct ManualWorkoutSummary: Codable, Identifiable {
        let id: UUID
        let name: String?
        let completedAt: Date?
        let createdAt: Date
        let completed: Bool
        let totalVolume: Double?
        let avgRpe: Double?
        let avgPain: Double?
        let durationMinutes: Int?
        let exerciseCount: Int?

        enum CodingKeys: String, CodingKey {
            case id
            case name
            case completedAt = "completed_at"
            case createdAt = "created_at"
            case completed
            case totalVolume = "total_volume"
            case avgRpe = "avg_rpe"
            case avgPain = "avg_pain"
            case durationMinutes = "duration_minutes"
            case exerciseCount = "exercise_count"
        }

        var displayName: String {
            name ?? "Manual Workout"
        }

        var workoutDate: Date {
            completedAt ?? createdAt
        }
    }

    /// Fetch recent completed manual workouts
    func fetchRecentManualWorkouts(patientId: String, limit: Int = 10) async throws -> [ManualWorkoutSummary] {
        // Query manual_sessions with exercise count subquery
        let response = try await supabase.client
            .from("manual_sessions")
            .select("""
                id,
                name,
                completed_at,
                created_at,
                completed,
                total_volume,
                avg_rpe,
                avg_pain,
                duration_minutes,
                manual_session_exercises(count)
            """)
            .eq("patient_id", value: patientId)
            .eq("completed", value: true)
            .order("completed_at", ascending: false)
            .limit(limit)
            .execute()

        // Custom decoder to handle the nested count
        struct ManualSessionWithCount: Codable {
            let id: UUID
            let name: String?
            let completed_at: Date?
            let created_at: Date
            let completed: Bool
            let total_volume: Double?
            let avg_rpe: Double?
            let avg_pain: Double?
            let duration_minutes: Int?
            let manual_session_exercises: [CountResult]?

            struct CountResult: Codable {
                let count: Int
            }
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let rawSessions = try decoder.decode([ManualSessionWithCount].self, from: response.data)

        // Map to ManualWorkoutSummary
        return rawSessions.map { raw in
            ManualWorkoutSummary(
                id: raw.id,
                name: raw.name,
                completedAt: raw.completed_at,
                createdAt: raw.created_at,
                completed: raw.completed,
                totalVolume: raw.total_volume,
                avgRpe: raw.avg_rpe,
                avgPain: raw.avg_pain,
                durationMinutes: raw.duration_minutes,
                exerciseCount: raw.manual_session_exercises?.first?.count
            )
        }
    }

    /// Fetch recent completed manual workouts with pagination support
    func fetchRecentManualWorkoutsPaginated(patientId: String, limit: Int = 20, offset: Int = 0) async throws -> [ManualWorkoutSummary] {
        let response = try await supabase.client
            .from("manual_sessions")
            .select("""
                id,
                name,
                completed_at,
                created_at,
                completed,
                total_volume,
                avg_rpe,
                avg_pain,
                duration_minutes,
                manual_session_exercises(count)
            """)
            .eq("patient_id", value: patientId)
            .eq("completed", value: true)
            .order("completed_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()

        struct ManualSessionWithCount: Codable {
            let id: UUID
            let name: String?
            let completed_at: Date?
            let created_at: Date
            let completed: Bool
            let total_volume: Double?
            let avg_rpe: Double?
            let avg_pain: Double?
            let duration_minutes: Int?
            let manual_session_exercises: [CountResult]?

            struct CountResult: Codable {
                let count: Int
            }
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let rawSessions = try decoder.decode([ManualSessionWithCount].self, from: response.data)

        return rawSessions.map { raw in
            ManualWorkoutSummary(
                id: raw.id,
                name: raw.name,
                completedAt: raw.completed_at,
                createdAt: raw.created_at,
                completed: raw.completed,
                totalVolume: raw.total_volume,
                avgRpe: raw.avg_rpe,
                avgPain: raw.avg_pain,
                durationMinutes: raw.duration_minutes,
                exerciseCount: raw.manual_session_exercises?.first?.count
            )
        }
    }

    /// Fetch summary statistics
    func fetchSummaryStats(patientId: String) async throws -> SummaryStats {
        // Fetch adherence
        let adherence = try await fetchAdherence(patientId: patientId, days: 30)

        // Fetch recent pain trend
        let painTrend = try await fetchPainTrend(patientId: patientId, days: 7)
        let avgPain = painTrend.isEmpty ? 0.0 : painTrend.map { $0.painScore }.reduce(0, +) / Double(painTrend.count)

        return SummaryStats(
            adherencePercentage: adherence.adherencePercentage,
            avgPainScore: avgPain,
            completedSessions: adherence.completedSessions,
            totalSessions: adherence.totalSessions
        )
    }

    // MARK: - Helper Methods for Build 46 Analytics

    /// Fetch exercise logs from database with optional filters
    private func fetchExerciseLogs(
        patientId: String,
        exerciseId: String? = nil,
        startDate: Date
    ) async throws -> [ExerciseLog] {
        // Build query conditionally
        let response: Data

        if let exerciseId = exerciseId {
            let result = try await supabase.client
                .from("exercise_logs")
                .select()
                .eq("patient_id", value: patientId)
                .eq("session_exercise_id", value: exerciseId)
                .gte("logged_at", value: startDate.iso8601String)
                .order("logged_at", ascending: true)
                .execute()
            response = result.data
        } else {
            let result = try await supabase.client
                .from("exercise_logs")
                .select()
                .eq("patient_id", value: patientId)
                .gte("logged_at", value: startDate.iso8601String)
                .order("logged_at", ascending: true)
                .execute()
            response = result.data
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let logs = try decoder.decode([ExerciseLog].self, from: response)
        return logs
    }

    /// Group exercise logs by week
    private func groupByWeek(logs: [ExerciseLog]) -> [[ExerciseLog]] {
        var weeklyLogs: [Date: [ExerciseLog]] = [:]

        for log in logs {
            let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: log.createdAt)?.start ?? log.createdAt
            weeklyLogs[weekStart, default: []].append(log)
        }

        return weeklyLogs
            .sorted { $0.key < $1.key }
            .map { $0.value }
    }

    /// Calculate estimated one-rep max using Epley formula
    private func calculateOneRepMax(weight: Double, reps: Int) -> Double {
        // Epley formula: 1RM = weight × (1 + reps/30)
        // For reps = 1, this returns the weight itself
        guard reps > 0 else { return weight }
        return weight * (1 + Double(reps) / 30.0)
    }

    // MARK: - Build 46 Analytics (Volume, Strength, Consistency)

    /// Calculate volume data for a time period
    func calculateVolumeData(
        for patientId: String,
        period: TimePeriod
    ) async throws -> VolumeChartData {
        let startDate = period.startDate
        let logs = try await fetchExerciseLogs(
            patientId: patientId,
            startDate: startDate
        )

        // Group logs by week
        let dataPoints = groupByWeek(logs: logs)
            .map { weekLogs -> VolumeDataPoint in
                let totalVolume = weekLogs.reduce(0.0) { total, log in
                    let weight = log.weight ?? 0
                    let reps = log.reps ?? 0
                    let sets = log.sets
                    return total + (weight * Double(reps) * Double(sets))
                }

                let sessionDates = Set(weekLogs.map { Calendar.current.startOfDay(for: $0.createdAt) })

                return VolumeDataPoint(
                    date: weekLogs.first?.createdAt ?? Date(),
                    totalVolume: totalVolume,
                    sessionCount: sessionDates.count
                )
            }
            .sorted { $0.date < $1.date }

        let totalVolume = dataPoints.reduce(0.0) { $0 + $1.totalVolume }
        let averageVolume = dataPoints.isEmpty ? 0 : totalVolume / Double(dataPoints.count)
        let peakVolume = dataPoints.max(by: { $0.totalVolume < $1.totalVolume })

        return VolumeChartData(
            dataPoints: dataPoints,
            period: period,
            totalVolume: totalVolume,
            averageVolume: averageVolume,
            peakVolume: peakVolume?.totalVolume ?? 0,
            peakDate: peakVolume?.date
        )
    }

    /// Calculate strength progression for a specific exercise
    func calculateStrengthData(
        for patientId: String,
        exerciseId: String,
        period: TimePeriod
    ) async throws -> StrengthChartData {
        let startDate = period.startDate
        let logs = try await fetchExerciseLogs(
            patientId: patientId,
            exerciseId: exerciseId,
            startDate: startDate
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

    /// Calculate workout consistency over time
    func calculateConsistencyData(
        for patientId: String,
        period: TimePeriod
    ) async throws -> ConsistencyChartData {
        let startDate = period.startDate

        // Fetch scheduled sessions
        let response = try await supabase.client
            .from("scheduled_sessions")
            .select()
            .eq("patient_id", value: patientId)
            .gte("scheduled_date", value: startDate.iso8601String)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let scheduledSessions = try decoder.decode([ScheduledSession].self, from: response.data)

        // Group by week
        var weeklyData: [Date: (scheduled: Int, completed: Int)] = [:]

        for session in scheduledSessions {
            let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: session.scheduledDate)?.start ?? session.scheduledDate

            var data = weeklyData[weekStart] ?? (scheduled: 0, completed: 0)
            data.scheduled += 1
            if session.status == ScheduledSession.ScheduleStatus.completed {
                data.completed += 1
            }
            weeklyData[weekStart] = data
        }

        let dataPoints = weeklyData.map { weekStart, data -> ConsistencyDataPoint in
            let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
            let rate = data.scheduled > 0 ? Double(data.completed) / Double(data.scheduled) : 0

            return ConsistencyDataPoint(
                weekStart: weekStart,
                weekEnd: weekEnd,
                scheduledSessions: data.scheduled,
                completedSessions: data.completed,
                completionRate: rate
            )
        }
        .sorted { $0.weekStart < $1.weekStart }

        let totalScheduled = dataPoints.reduce(0) { $0 + $1.scheduledSessions }
        let totalCompleted = dataPoints.reduce(0) { $0 + $1.completedSessions }
        let overallRate = totalScheduled > 0 ? Double(totalCompleted) / Double(totalScheduled) : 0

        let currentStreak = calculateCurrentStreak(from: dataPoints)
        let longestStreak = calculateLongestStreak(from: dataPoints)

        return ConsistencyChartData(
            dataPoints: dataPoints,
            period: period,
            totalScheduled: totalScheduled,
            totalCompleted: totalCompleted,
            overallCompletionRate: overallRate,
            currentStreak: currentStreak,
            longestStreak: longestStreak
        )
    }

    private func calculateCurrentStreak(from dataPoints: [ConsistencyDataPoint]) -> Int {
        var streak = 0
        for dataPoint in dataPoints.reversed() {
            if dataPoint.completionRate >= 0.8 {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    private func calculateLongestStreak(from dataPoints: [ConsistencyDataPoint]) -> Int {
        var longestStreak = 0
        var currentStreak = 0

        for dataPoint in dataPoints {
            if dataPoint.completionRate >= 0.8 {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }

        return longestStreak
    }

    // MARK: - BUILD 296: Session Detail (ACP-588)

    /// Fetch exercise logs for a prescribed session with exercise names
    func fetchSessionExerciseLogs(sessionId: String, patientId: String) async throws -> [ExerciseLogDetail] {
        // Query exercise_logs joined through session_exercises to get exercise names
        let response = try await supabase.client
            .from("exercise_logs")
            .select("""
                id,
                actual_sets,
                actual_reps,
                actual_load,
                load_unit,
                rpe,
                pain_score,
                notes,
                logged_at,
                session_exercises!inner(
                    exercise_templates!inner(
                        exercise_name,
                        id,
                        video_url
                    )
                )
            """)
            .eq("patient_id", value: patientId)
            .eq("session_exercises.session_id", value: sessionId)
            .order("logged_at", ascending: true)
            .execute()

        // Custom decoder for the nested join response
        struct ExerciseLogJoined: Codable {
            let id: UUID
            let actual_sets: Int
            let actual_reps: [Int]
            let actual_load: Double?
            let load_unit: String?
            let rpe: Int
            let pain_score: Int
            let notes: String?
            let logged_at: Date
            let session_exercises: SessionExerciseJoin

            struct SessionExerciseJoin: Codable {
                let exercise_templates: ExerciseTemplateJoin
            }

            struct ExerciseTemplateJoin: Codable {
                let exercise_name: String
                let id: UUID
                let video_url: String?
            }
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let joined = try decoder.decode([ExerciseLogJoined].self, from: response.data)

        return joined.map { log in
            ExerciseLogDetail(
                id: log.id.uuidString,
                exerciseName: log.session_exercises.exercise_templates.exercise_name,
                actualSets: log.actual_sets,
                actualReps: log.actual_reps,
                actualLoad: log.actual_load,
                loadUnit: log.load_unit,
                rpe: log.rpe,
                painScore: log.pain_score,
                notes: log.notes,
                loggedAt: log.logged_at,
                exerciseTemplateId: log.session_exercises.exercise_templates.id.uuidString,
                videoUrl: log.session_exercises.exercise_templates.video_url
            )
        }
    }

    // MARK: - BUILD 333: Exercise Progress Time-Series Data

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

    /// Fetch time-series exercise progress data for charting
    /// Queries both exercise_logs (prescribed workouts) and manual_session_exercises (manual workouts)
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - exerciseName: The name of the exercise to query
    ///   - limit: Maximum number of data points to return (default 50)
    /// - Returns: Array of data points sorted by date ascending (oldest first for chart display)
    func fetchExerciseProgressTimeSeries(
        patientId: String,
        exerciseName: String,
        limit: Int = 50
    ) async throws -> [ExerciseProgressDataPoint] {
        var allDataPoints: [ExerciseProgressDataPoint] = []

        // Query 1: Fetch from exercise_logs (prescribed sessions)
        // Join through session_exercises to get exercise name from exercise_templates
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

            // Custom decoder for nested response
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
            // Log but don't fail - we can still try manual sessions
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
                // Parse target_reps which may be "8" or "8,8,8"
                let reps: Int
                if let repsStr = row.target_reps {
                    let parsed = repsStr.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                    reps = parsed.first ?? (Int(repsStr) ?? 0)
                } else {
                    reps = 0
                }
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

        // Sort all data points by date ascending and limit
        allDataPoints.sort { $0.date < $1.date }

        // Mark personal records (highest weight achieved)
        if !allDataPoints.isEmpty {
            var maxWeight: Double = 0
            allDataPoints = allDataPoints.map { point in
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

        return Array(allDataPoints.suffix(limit))
    }

    /// Fetch recent session history for a specific exercise
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - exerciseName: The name of the exercise
    ///   - limit: Maximum sessions to return (default 10)
    /// - Returns: Array of session records sorted by date descending (most recent first)
    func fetchExerciseRecentHistory(
        patientId: String,
        exerciseName: String,
        limit: Int = 10
    ) async throws -> [ExerciseSessionRecord] {
        // Fetch time-series data and transform to session records
        let dataPoints = try await fetchExerciseProgressTimeSeries(
            patientId: patientId,
            exerciseName: exerciseName,
            limit: limit
        )

        // Convert to session records (reverse order for most recent first)
        return dataPoints.reversed().map { point in
            ExerciseSessionRecord(
                id: point.id,
                date: point.date,
                sets: point.sets,
                reps: point.reps,
                weight: point.weight > 0 ? point.weight : nil,
                volume: point.volume,
                isPersonalRecord: point.isPersonalRecord,
                loadUnit: nil
            )
        }
    }

    /// Fetch exercises for a manual workout
    func fetchManualWorkoutExercises(workoutId: UUID) async throws -> [ExerciseLogDetail] {
        let response = try await supabase.client
            .from("manual_session_exercises")
            .select("""
                id,
                exercise_name,
                target_sets,
                target_reps,
                target_load,
                load_unit,
                notes,
                created_at,
                exercise_template_id
            """)
            .eq("manual_session_id", value: workoutId)
            .order("sequence", ascending: true)
            .execute()

        struct ManualExerciseRow: Codable {
            let id: UUID
            let exercise_name: String
            let target_sets: Int?
            let target_reps: String?
            let target_load: Double?
            let load_unit: String?
            let notes: String?
            let created_at: Date
            let exercise_template_id: UUID?
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let rows = try decoder.decode([ManualExerciseRow].self, from: response.data)

        return rows.map { row in
            // Parse target_reps string into [Int] array
            let repsArray: [Int]
            if let repsStr = row.target_reps {
                let parsed = repsStr.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                repsArray = parsed.isEmpty ? (row.target_sets.map { Array(repeating: Int(repsStr) ?? 0, count: $0) } ?? []) : parsed
            } else {
                repsArray = []
            }

            return ExerciseLogDetail(
                id: row.id.uuidString,
                exerciseName: row.exercise_name,
                actualSets: row.target_sets ?? 0,
                actualReps: repsArray,
                actualLoad: row.target_load,
                loadUnit: row.load_unit,
                rpe: 0,
                painScore: 0,
                notes: row.notes,
                loggedAt: row.created_at,
                exerciseTemplateId: row.exercise_template_id?.uuidString,
                videoUrl: nil
            )
        }
    }
}

// MARK: - Analytics Error

enum AnalyticsError: LocalizedError {
    case calculationFailed(Error)
    case noData

    var errorDescription: String? {
        switch self {
        case .calculationFailed:
            return "Failed to calculate analytics"
        case .noData:
            return "No data available for the selected period"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .calculationFailed:
            return "Please try again. If the problem persists, contact support."
        case .noData:
            return "Complete some workouts to see your analytics here."
        }
    }
}

// MARK: - Date Extensions

private extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}

/// Summary statistics
struct SummaryStats {
    let adherencePercentage: Double
    let avgPainScore: Double
    let completedSessions: Int
    let totalSessions: Int
}
