import Foundation
import SwiftUI

/// View Model for Session Summary
/// Build 60: UX Polish - Enhanced session summary with PRs and motivation
@MainActor
class SessionSummaryViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var summary: SessionSummaryData?

    private let supabase = PTSupabaseClient.shared

    /// Calculate session summary from session and exercise logs
    func calculateSummary(for session: Session, patientId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch exercise logs for this session
            let response = try await supabase.client
                .from("exercise_logs")
                .select("*")
                .eq("patient_id", value: patientId)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let exerciseLogs = try decoder.decode([ExerciseLogResponse].self, from: response.data)

            // Fetch historical PRs for comparison
            let prRecords = await fetchPersonalRecords(patientId: patientId)

            // Calculate metrics
            let exercisesCompleted = exerciseLogs.count
            let totalVolume = calculateTotalVolume(from: exerciseLogs)
            let duration = calculateDuration(from: exerciseLogs)
            let prCount = detectPersonalRecords(exerciseLogs: exerciseLogs, historicalPRs: prRecords)
            let complianceScore = await calculateCompliance(exerciseLogs: exerciseLogs, session: session)

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
    private func calculateDuration(from logs: [ExerciseLogResponse]) -> TimeInterval {
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
            print("Failed to fetch PRs: \(error.localizedDescription)")
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
            print("Failed to calculate compliance: \(error.localizedDescription)")
            return 0
        }
    }

    /// Generate motivational message based on performance
    private func generateMotivationalMessage(compliance: Double, prCount: Int, volume: Double) -> String {
        // Exceptional performance (PR + high compliance)
        if prCount > 0 && compliance >= 95 {
            let prText = prCount == 1 ? "a personal record" : "\(prCount) personal records"
            return "Outstanding! You crushed it today with \(prText) and near-perfect execution!"
        }

        // Personal records
        if prCount > 0 {
            let prText = prCount == 1 ? "PR" : "PRs"
            return "Great work! \(prCount) \(prText) today - you're getting stronger!"
        }

        // High compliance
        if compliance >= 95 {
            return "Excellent work! You completed all prescribed reps with precision."
        }

        // Good compliance
        if compliance >= 80 {
            return "Solid session! You're making consistent progress toward your goals."
        }

        // Moderate compliance
        if compliance >= 60 {
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
