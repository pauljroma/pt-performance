//
//  ProgramWorkoutHistoryViewModel.swift
//  PTPerformance
//
//  ViewModel for displaying workout history within a specific enrolled program.
//  Shows completed workouts from the program with summary stats and details.
//

import SwiftUI

// MARK: - Program Workout History Item

/// Represents a completed workout within a program
struct ProgramWorkoutHistoryItem: Identifiable {
    let id: UUID
    let name: String
    let completedAt: Date
    let durationMinutes: Int?
    let totalVolume: Double?
    let avgRpe: Double?
    let avgPain: Double?
    let exerciseCount: Int
    let phaseName: String?
    let weekNumber: Int?

    // MARK: - Static Formatters (Performance Optimization)

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    // MARK: - Computed Display Properties

    var dateDisplay: String {
        Self.dateFormatter.string(from: completedAt)
    }

    var durationDisplay: String? {
        guard let minutes = durationMinutes else { return nil }
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes > 0 {
                return "\(hours)h \(remainingMinutes)m"
            }
            return "\(hours)h"
        }
        return "\(minutes)m"
    }

    var volumeDisplay: String? {
        guard let volume = totalVolume else { return nil }
        if volume >= 1000 {
            return String(format: "%.1fk lbs", volume / 1000)
        }
        return "\(Int(volume)) lbs"
    }

    var rpeDisplay: String? {
        guard let rpe = avgRpe else { return nil }
        return String(format: "%.1f", rpe)
    }
}

// MARK: - Program History Stats

/// Summary statistics for workout history within a program
struct ProgramHistoryStats {
    let totalWorkoutsCompleted: Int
    let totalVolumeLifted: Double
    let averageRpe: Double?
    let averagePain: Double?
    let totalDurationMinutes: Int
    let currentStreak: Int
    let longestStreak: Int

    var totalVolumeDisplay: String {
        if totalVolumeLifted >= 1000 {
            return String(format: "%.1fk lbs", totalVolumeLifted / 1000)
        }
        return "\(Int(totalVolumeLifted)) lbs"
    }

    var totalDurationDisplay: String {
        if totalDurationMinutes >= 60 {
            let hours = totalDurationMinutes / 60
            let minutes = totalDurationMinutes % 60
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(hours)h"
        }
        return "\(totalDurationMinutes)m"
    }

    var averageRpeDisplay: String? {
        guard let rpe = averageRpe else { return nil }
        return String(format: "%.1f", rpe)
    }

    static var empty: ProgramHistoryStats {
        ProgramHistoryStats(
            totalWorkoutsCompleted: 0,
            totalVolumeLifted: 0,
            averageRpe: nil,
            averagePain: nil,
            totalDurationMinutes: 0,
            currentStreak: 0,
            longestStreak: 0
        )
    }
}

// MARK: - ViewModel

@MainActor
class ProgramWorkoutHistoryViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var workouts: [ProgramWorkoutHistoryItem] = []
    @Published var stats: ProgramHistoryStats = .empty
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var hasMoreWorkouts = true

    // MARK: - Properties

    let enrollment: EnrollmentWithProgram
    private let supabase: PTSupabaseClient
    private let pageSize = 20
    private var currentOffset = 0

    // MARK: - Initialization

    init(
        enrollment: EnrollmentWithProgram,
        supabase: PTSupabaseClient = .shared
    ) {
        self.enrollment = enrollment
        self.supabase = supabase
    }

    // MARK: - Computed Properties

    var isEmpty: Bool {
        workouts.isEmpty && !isLoading
    }

    var programTitle: String {
        enrollment.program.title
    }

    // MARK: - Data Loading

    /// Load initial workout history data
    func loadHistory() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        currentOffset = 0

        let logger = DebugLogger.shared
        logger.log("Loading program workout history for: \(programTitle)", level: .diagnostic)

        do {
            // Fetch workouts and stats in parallel
            async let workoutsTask = fetchWorkouts(offset: 0, limit: pageSize)
            async let statsTask = fetchStats()

            let (fetchedWorkouts, fetchedStats) = try await (workoutsTask, statsTask)

            workouts = fetchedWorkouts
            stats = fetchedStats
            hasMoreWorkouts = fetchedWorkouts.count >= pageSize

            isLoading = false
            logger.log("Loaded \(workouts.count) program workouts", level: .diagnostic)

        } catch {
            logger.log("Failed to load program history: \(error.localizedDescription)", level: .error)
            errorMessage = "Unable to load workout history. Please try again."
            isLoading = false
        }
    }

    /// Load more workouts for pagination
    func loadMoreWorkouts() async {
        guard hasMoreWorkouts && !isLoadingMore && !isLoading else { return }

        isLoadingMore = true
        let previousOffset = currentOffset
        currentOffset += pageSize

        do {
            let moreWorkouts = try await fetchWorkouts(offset: currentOffset, limit: pageSize)
            workouts.append(contentsOf: moreWorkouts)
            hasMoreWorkouts = moreWorkouts.count >= pageSize
            isLoadingMore = false
        } catch {
            DebugLogger.shared.log("Failed to load more workouts: \(error.localizedDescription)", level: .warning)
            currentOffset = previousOffset  // Reset offset on failure to allow retry
            isLoadingMore = false
            // Don't set hasMoreWorkouts = false, allow user to retry
        }
    }

    /// Refresh all data
    func refresh() async {
        await loadHistory()
    }

    // MARK: - Private Methods

    /// Fetch completed workouts for this program
    private func fetchWorkouts(offset: Int, limit: Int) async throws -> [ProgramWorkoutHistoryItem] {
        guard let patientId = supabase.userId else { return [] }

        // Get all template IDs from program assignments
        let templateIds = try await fetchProgramTemplateIds()

        guard !templateIds.isEmpty else { return [] }

        // Fetch completed manual sessions that originated from this program's templates
        let response = try await supabase.client
            .from("manual_sessions")
            .select("""
                id,
                name,
                completed_at,
                duration_minutes,
                total_volume,
                avg_rpe,
                avg_pain,
                session_source,
                manual_session_exercises(count)
            """)
            .eq("patient_id", value: patientId)
            .eq("completed", value: true)
            .eq("session_source", value: "program")
            .in("source_template_id", values: templateIds.map { $0.uuidString })
            .order("completed_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()

        return try decodeWorkouts(from: response.data)
    }

    /// Fetch all template IDs associated with this program
    private func fetchProgramTemplateIds() async throws -> [UUID] {
        // Try to get template IDs from program_workout_assignments
        let response = try await supabase.client
            .from("program_workout_assignments")
            .select("template_id")
            .eq("program_id", value: enrollment.program.id)
            .execute()

        struct TemplateRow: Codable {
            let template_id: UUID
        }

        let decoder = JSONDecoder()
        let rows = try decoder.decode([TemplateRow].self, from: response.data)
        return rows.map { $0.template_id }
    }

    /// Decode workout response data
    private func decodeWorkouts(from data: Data) throws -> [ProgramWorkoutHistoryItem] {
        struct WorkoutRow: Codable {
            let id: UUID
            let name: String?
            let completed_at: Date?
            let duration_minutes: Int?
            let total_volume: Double?
            let avg_rpe: Double?
            let avg_pain: Double?
            let session_source: String?
            let manual_session_exercises: [CountResult]?

            struct CountResult: Codable {
                let count: Int
            }
        }

        let decoder = PTSupabaseClient.flexibleDecoder

        let rows = try decoder.decode([WorkoutRow].self, from: data)

        return rows.compactMap { row in
            guard let completedAt = row.completed_at else { return nil }

            return ProgramWorkoutHistoryItem(
                id: row.id,
                name: row.name ?? "Workout",
                completedAt: completedAt,
                durationMinutes: row.duration_minutes,
                totalVolume: row.total_volume,
                avgRpe: row.avg_rpe,
                avgPain: row.avg_pain,
                exerciseCount: row.manual_session_exercises?.first?.count ?? 0,
                phaseName: nil,
                weekNumber: nil
            )
        }
    }

    /// Fetch summary statistics for this program's workout history
    private func fetchStats() async throws -> ProgramHistoryStats {
        guard let patientId = supabase.userId else { return .empty }

        let templateIds = try await fetchProgramTemplateIds()

        guard !templateIds.isEmpty else { return .empty }

        // Aggregate stats from completed sessions
        let response = try await supabase.client
            .from("manual_sessions")
            .select("""
                id,
                completed_at,
                duration_minutes,
                total_volume,
                avg_rpe,
                avg_pain
            """)
            .eq("patient_id", value: patientId)
            .eq("completed", value: true)
            .eq("session_source", value: "program")
            .in("source_template_id", values: templateIds.map { $0.uuidString })
            .order("completed_at", ascending: true)
            .execute()

        struct StatsRow: Codable {
            let id: UUID
            let completed_at: Date?
            let duration_minutes: Int?
            let total_volume: Double?
            let avg_rpe: Double?
            let avg_pain: Double?
        }

        let decoder = PTSupabaseClient.flexibleDecoder

        let rows = try decoder.decode([StatsRow].self, from: response.data)

        guard !rows.isEmpty else { return .empty }

        // Calculate aggregates
        let totalWorkouts = rows.count
        let totalVolume = rows.compactMap { $0.total_volume }.reduce(0, +)
        let totalDuration = rows.compactMap { $0.duration_minutes }.reduce(0, +)

        let rpeValues = rows.compactMap { $0.avg_rpe }
        let avgRpe = rpeValues.isEmpty ? nil : rpeValues.reduce(0, +) / Double(rpeValues.count)

        let painValues = rows.compactMap { $0.avg_pain }
        let avgPain = painValues.isEmpty ? nil : painValues.reduce(0, +) / Double(painValues.count)

        // Calculate streaks
        let (currentStreak, longestStreak) = calculateStreaks(from: rows.compactMap { $0.completed_at })

        return ProgramHistoryStats(
            totalWorkoutsCompleted: totalWorkouts,
            totalVolumeLifted: totalVolume,
            averageRpe: avgRpe,
            averagePain: avgPain,
            totalDurationMinutes: totalDuration,
            currentStreak: currentStreak,
            longestStreak: longestStreak
        )
    }

    /// Calculate workout streaks from completion dates
    private func calculateStreaks(from dates: [Date]) -> (current: Int, longest: Int) {
        guard !dates.isEmpty else { return (0, 0) }

        let calendar = Calendar.current
        let sortedDates = dates.sorted()

        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 1

        // Check if today or yesterday has a workout for current streak
        let today = calendar.startOfDay(for: Date())
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
            return (0, 0)
        }

        for i in 1..<sortedDates.count {
            let prevDay = calendar.startOfDay(for: sortedDates[i-1])
            let currDay = calendar.startOfDay(for: sortedDates[i])

            let daysDiff = calendar.dateComponents([.day], from: prevDay, to: currDay).day ?? 0

            if daysDiff <= 1 {
                tempStreak += 1
            } else {
                longestStreak = max(longestStreak, tempStreak)
                tempStreak = 1
            }
        }

        longestStreak = max(longestStreak, tempStreak)

        // Check if current streak is active (last workout was today or yesterday)
        if let lastDate = sortedDates.last {
            let lastDay = calendar.startOfDay(for: lastDate)
            if lastDay >= yesterday {
                currentStreak = tempStreak
            }
        }

        return (currentStreak, longestStreak)
    }
}
