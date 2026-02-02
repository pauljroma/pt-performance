import Foundation
import SwiftUI

/// View Model for Session Summary
/// Build 60: UX Polish - Enhanced session summary with PRs and motivation
@MainActor
class SessionSummaryViewModel: ObservableObject {
    // MARK: - Compliance Thresholds

    /// Thresholds for determining compliance level in motivational messages
    private enum ComplianceThreshold {
        /// Exceptional performance threshold (95%+)
        static let exceptional = 95.0
        /// Solid performance threshold (80%+)
        static let solid = 80.0
        /// Good effort threshold (60%+)
        static let good = 60.0
    }
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var summary: SessionSummaryData?

    private let supabase = PTSupabaseClient.shared

    /// Calculate session summary from session and exercise logs
    func calculateSummary(for session: Session, patientId: String) async {
        isLoading = true
        errorMessage = nil

        // BUILD 132: Debug logging for session summary bug
        DebugLogger.shared.info("SESSION_SUMMARY", """
            Calculating summary for session:
            Session ID: \(session.id.uuidString)
            Patient ID: \(patientId)
            Session created: \(session.created_at ?? Date())
            Session started: \(session.started_at?.description ?? "nil")
            Session completed: \(session.completed_at?.description ?? "nil")
            """)

        do {
            // BUILD 133: Add time-based filtering to prevent retrieving logs from other session completions
            // Bug fix: session_id alone isn't enough - need to filter by time range too
            var queryParams: [String: String] = [
                "patient_id": patientId,
                "session_id": session.id.uuidString
            ]

            // Add time range if session has start/end times
            var timeRangeLog = "No time range filter (session times unavailable)"
            if let startedAt = session.started_at {
                queryParams["started_at_gte"] = startedAt.ISO8601Format()
                timeRangeLog = "started_at >= \(startedAt)"
            }
            if let completedAt = session.completed_at {
                queryParams["completed_at_lte"] = completedAt.ISO8601Format()
                timeRangeLog += ", completed_at <= \(completedAt)"
            }

            DebugLogger.shared.logQuery(
                table: "exercise_logs",
                query: "SELECT * WHERE patient_id = ? AND session_id = ? + time filters",
                params: queryParams
            )

            DebugLogger.shared.info("SESSION_SUMMARY", """
                Time-based filtering: \(timeRangeLog)
                This prevents retrieving logs from other completions of the same session
                """)

            // BUILD 286: Query via session_exercises join instead of session_id
            // exercise_logs use session_exercise_id (FK to session_exercises.id),
            // NOT session_id directly. First get the exercise IDs for this session.
            let exerciseIdsResponse = try await supabase.client
                .from("session_exercises")
                .select("id")
                .eq("session_id", value: session.id)
                .execute()

            struct SessionExerciseId: Codable { let id: String }
            let exerciseIds = try JSONDecoder().decode([SessionExerciseId].self, from: exerciseIdsResponse.data)
            let ids = exerciseIds.map { $0.id }

            DebugLogger.shared.info("SESSION_SUMMARY", "Found \(ids.count) session_exercise IDs for session \(session.id)")

            guard !ids.isEmpty else {
                DebugLogger.shared.warning("SESSION_SUMMARY", "No session_exercises found for session \(session.id)")
                summary = SessionSummaryData(
                    exercisesCompleted: 0,
                    totalVolume: 0,
                    duration: 0,
                    prCount: 0,
                    complianceScore: 0,
                    motivationalMessage: "No exercises found for this session."
                )
                isLoading = false
                return
            }

            // Query exercise_logs for these session_exercise_ids
            var query = supabase.client
                .from("exercise_logs")
                .select("*")
                .eq("patient_id", value: patientId)
                .in("session_exercise_id", values: ids)

            // Add time range filters if available to scope to THIS session completion only
            if let startedAt = session.started_at {
                query = query.gte("logged_at", value: startedAt.ISO8601Format())
            }
            if let completedAt = session.completed_at {
                query = query.lte("logged_at", value: completedAt.ISO8601Format())
            }

            let response = try await query.execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let exerciseLogs = try decoder.decode([ExerciseLogResponse].self, from: response.data)

            // BUILD 133: Enhanced logging to verify time-based filtering worked
            let sortedLogs = exerciseLogs.sorted { $0.logged_at < $1.logged_at }
            let dateRange: String
            if let firstLog = sortedLogs.first, let lastLog = sortedLogs.last {
                dateRange = "\(firstLog.logged_at) to \(lastLog.logged_at)"
            } else {
                dateRange = "N/A"
            }

            DebugLogger.shared.info("SESSION_SUMMARY", """
                Retrieved \(exerciseLogs.count) exercise logs
                Raw response size: \(response.data.count) bytes
                Date range of logs: \(dateRange)
                Expected range: \(session.started_at?.description ?? "nil") to \(session.completed_at?.description ?? "nil")
                """)

            if exerciseLogs.isEmpty {
                DebugLogger.shared.warning("SESSION_SUMMARY", """
                    NO EXERCISE LOGS FOUND!
                    This could mean:
                    1. session_id not populated in exercise_logs table
                    2. Time range filter excluded all logs
                    3. No exercises were actually logged
                    Raw response: \(String(data: response.data, encoding: .utf8) ?? "Unable to decode")
                    """)
            } else if let firstLog = sortedLogs.first, let lastLog = sortedLogs.last {
                // Log first, last, and count
                DebugLogger.shared.info("SESSION_SUMMARY", """
                    First log: \(firstLog.logged_at)
                    Last log: \(lastLog.logged_at)
                    Span: \(lastLog.logged_at.timeIntervalSince(firstLog.logged_at) / 60) minutes
                    """)

                // Log each exercise log (first 5 only to avoid spam)
                for (index, log) in exerciseLogs.prefix(5).enumerated() {
                    DebugLogger.shared.info("SESSION_SUMMARY", """
                        Log \(index + 1)/\(exerciseLogs.count):
                        - Exercise: \(log.session_exercise_id)
                        - Logged at: \(log.logged_at)
                        - Sets: \(log.actual_sets)
                        - Reps: \(log.actual_reps)
                        - Load: \(log.actual_load ?? 0)
                        """)
                }
                if exerciseLogs.count > 5 {
                    DebugLogger.shared.info("SESSION_SUMMARY", "... and \(exerciseLogs.count - 5) more logs")
                }
            }

            // Fetch historical PRs for comparison
            let prRecords = await fetchPersonalRecords(patientId: patientId)

            // Calculate metrics
            let exercisesCompleted = exerciseLogs.count
            let totalVolume = calculateTotalVolume(from: exerciseLogs)
            let duration = calculateDuration(from: exerciseLogs, session: session)
            let prCount = detectPersonalRecords(exerciseLogs: exerciseLogs, historicalPRs: prRecords)
            let complianceScore = await calculateCompliance(exerciseLogs: exerciseLogs, session: session)

            // DEBUG: Log calculated metrics
            DebugLogger.shared.success("SESSION_SUMMARY", """
                Calculated metrics:
                - Exercises: \(exercisesCompleted)
                - Volume: \(Int(totalVolume)) lbs
                - Duration: \(duration) seconds (\(Int(duration / 60)) minutes)
                - PRs: \(prCount)
                - Compliance: \(String(format: "%.0f%%", complianceScore))
                """)

            summary = SessionSummaryData(
                exercisesCompleted: exercisesCompleted,
                totalVolume: Int(totalVolume),
                duration: duration,
                prCount: prCount,
                complianceScore: complianceScore,
                motivationalMessage: generateMotivationalMessage(
                    compliance: complianceScore,
                    prCount: prCount,
                    volume: totalVolume
                )
            )

            isLoading = false
        } catch {
            DebugLogger.shared.error("SESSION_SUMMARY", """
                Error calculating summary:
                Error: \(error.localizedDescription)
                Type: \(type(of: error))
                Session ID: \(session.id.uuidString)
                """)
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    // MARK: - Calculation Helpers

    /// Calculate total volume (sets × reps × weight)
    private func calculateTotalVolume(from logs: [ExerciseLogResponse]) -> Double {
        logs.reduce(0.0) { sum, log in
            let totalReps = log.actual_reps.reduce(0, +)
            let load = log.actual_load ?? 0
            return sum + (Double(totalReps) * load)
        }
    }

    /// Calculate workout duration
    /// BUILD 123: Use actual session start/end times if available, fallback to exercise log timestamps
    private func calculateDuration(from logs: [ExerciseLogResponse], session: Session) -> TimeInterval {
        // Prefer actual session times if both exist
        if let startedAt = session.started_at, let completedAt = session.completed_at {
            return completedAt.timeIntervalSince(startedAt)
        }

        // Fallback to exercise log timestamps (legacy behavior)
        guard !logs.isEmpty else { return 0 }

        let sortedLogs = logs.sorted { $0.logged_at < $1.logged_at }
        if let firstLog = sortedLogs.first, let lastLog = sortedLogs.last {
            return lastLog.logged_at.timeIntervalSince(firstLog.logged_at)
        }
        return 0
    }

    /// Fetch historical personal records
    private func fetchPersonalRecords(patientId: String) async -> [SessionPersonalRecord] {
        do {
            let response = try await supabase.client
                .from("exercise_logs")
                .select("session_exercise_id, actual_reps, actual_load")
                .eq("patient_id", value: patientId)
                .order("logged_at", ascending: false)
                .limit(100)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let logs = try decoder.decode([ExerciseLogResponse].self, from: response.data)

            // Calculate PRs: max volume for each exercise
            var prMap: [String: SessionPersonalRecord] = [:]
            for log in logs {
                let totalReps = log.actual_reps.reduce(0, +)
                let load = log.actual_load ?? 0
                let volume = Double(totalReps) * load

                if let existingPR = prMap[log.session_exercise_id] {
                    if volume > existingPR.volume {
                        prMap[log.session_exercise_id] = SessionPersonalRecord(
                            exerciseId: log.session_exercise_id,
                            volume: volume,
                            reps: totalReps,
                            load: load
                        )
                    }
                } else {
                    prMap[log.session_exercise_id] = SessionPersonalRecord(
                        exerciseId: log.session_exercise_id,
                        volume: volume,
                        reps: totalReps,
                        load: load
                    )
                }
            }

            return Array(prMap.values)
        } catch {
            #if DEBUG
            print("Failed to fetch PRs: \(error.localizedDescription)")
            #endif
            return []
        }
    }

    /// Detect if any personal records were set this session
    private func detectPersonalRecords(
        exerciseLogs: [ExerciseLogResponse],
        historicalPRs: [SessionPersonalRecord]
    ) -> Int {
        var prCount = 0

        for log in exerciseLogs {
            let totalReps = log.actual_reps.reduce(0, +)
            let load = log.actual_load ?? 0
            let currentVolume = Double(totalReps) * load

            // Find historical PR for this exercise
            if let historicalPR = historicalPRs.first(where: { $0.exerciseId == log.session_exercise_id }) {
                if currentVolume > historicalPR.volume {
                    prCount += 1
                }
            } else {
                // First time doing this exercise = PR by default
                prCount += 1
            }
        }

        return prCount
    }

    /// Calculate compliance score (% of prescribed reps achieved)
    private func calculateCompliance(exerciseLogs: [ExerciseLogResponse], session: Session) async -> Double {
        guard !exerciseLogs.isEmpty else { return 0 }

        do {
            // Fetch prescribed exercises for this session
            let response = try await supabase.client
                .from("session_exercises")
                .select("id, prescribed_sets, prescribed_reps")
                .eq("session_id", value: session.id)
                .execute()

            let decoder = JSONDecoder()
            let prescribedExercises = try decoder.decode([PrescribedExercise].self, from: response.data)

            var totalComplianceScore = 0.0

            for log in exerciseLogs {
                // Find prescribed exercise
                guard let prescribed = prescribedExercises.first(where: { $0.id == log.session_exercise_id }) else {
                    continue
                }

                // Calculate actual vs prescribed
                let actualReps = log.actual_reps.reduce(0, +)
                let prescribedRepsValue = Int(prescribed.prescribed_reps.components(separatedBy: "-").first ?? "0") ?? 0
                let prescribedTotal = prescribed.prescribed_sets * prescribedRepsValue

                if prescribedTotal > 0 {
                    let compliance = min(Double(actualReps) / Double(prescribedTotal) * 100, 100)
                    totalComplianceScore += compliance
                }
            }

            return exerciseLogs.isEmpty ? 0 : totalComplianceScore / Double(exerciseLogs.count)
        } catch {
            #if DEBUG
            print("Failed to calculate compliance: \(error.localizedDescription)")
            #endif
            return 0
        }
    }

    /// Generate motivational message based on performance
    private func generateMotivationalMessage(compliance: Double, prCount: Int, volume: Double) -> String {
        // Exceptional performance (PR + high compliance)
        if prCount > 0 && compliance >= ComplianceThreshold.exceptional {
            let prText = prCount == 1 ? "a personal record" : "\(prCount) personal records"
            return "Outstanding! You crushed it today with \(prText) and near-perfect execution!"
        }

        // Personal records
        if prCount > 0 {
            let prText = prCount == 1 ? "PR" : "PRs"
            return "Great work! \(prCount) \(prText) today - you're getting stronger!"
        }

        // High compliance
        if compliance >= ComplianceThreshold.exceptional {
            return "Excellent work! You completed all prescribed reps with precision."
        }

        // Good compliance
        if compliance >= ComplianceThreshold.solid {
            return "Solid session! You're making consistent progress toward your goals."
        }

        // Moderate compliance
        if compliance >= ComplianceThreshold.good {
            return "Good effort today! Remember, consistency is key to progress."
        }

        // Lower compliance - encouraging message
        return "Every workout counts! Focus on form and recovery for your next session."
    }
}

// MARK: - Supporting Types

/// Session Summary Model (view-specific model for summary display)
struct SessionSummaryData {
    let exercisesCompleted: Int
    let totalVolume: Int
    let duration: TimeInterval
    let prCount: Int
    let complianceScore: Double
    let motivationalMessage: String

    var durationFormatted: String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))

        if minutes > 0 {
            return "\(minutes) min \(seconds) sec"
        } else {
            return "\(seconds) sec"
        }
    }

    var volumeFormatted: String {
        if totalVolume >= 1000 {
            return String(format: "%.1fk lbs", Double(totalVolume) / 1000)
        }
        return "\(totalVolume) lbs"
    }

    var complianceFormatted: String {
        return String(format: "%.0f%%", complianceScore)
    }
}

/// Exercise Log Response (local model for snake_case decoding from DB)
struct ExerciseLogResponse: Codable {
    let id: String
    let session_exercise_id: String
    let patient_id: String
    let logged_at: Date
    let actual_sets: Int
    let actual_reps: [Int]
    let actual_load: Double?
    let rpe: Int
    let pain_score: Int
}

/// Prescribed Exercise Model (local helper model)
struct PrescribedExercise: Codable {
    let id: String
    let prescribed_sets: Int
    let prescribed_reps: String
}

/// Session Personal Record Model (local helper model for session-specific PR tracking)
/// Note: Different from Models/ChartData.swift PersonalRecord which is for historical tracking
struct SessionPersonalRecord {
    let exerciseId: String
    let volume: Double
    let reps: Int
    let load: Double
}
