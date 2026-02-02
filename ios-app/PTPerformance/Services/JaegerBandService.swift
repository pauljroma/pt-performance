//
//  JaegerBandService.swift
//  PTPerformance
//
//  ACP-521: Jaeger Band Protocol Integration
//  Service for managing J-Band protocols, session logging, and arm care schedule integration
//

import Foundation
import Supabase

// MARK: - JaegerBandService

/// Service for managing Jaeger Band protocols and logging sessions to Supabase
@MainActor
class JaegerBandService: ObservableObject {
    private let supabase: PTSupabaseClient
    private let logger = DebugLogger.shared

    @Published var isLoading = false
    @Published var error: Error?
    @Published var recentSessions: [JaegerBandSessionLog] = []
    @Published var weeklyCompletions: Int = 0
    @Published var currentStreak: Int = 0

    // MARK: - Initialization

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
    }

    // MARK: - Protocol Retrieval

    /// Get the full J-Band protocol
    func getFullProtocol() -> JaegerBandProtocol {
        return JaegerBandProtocol.fullProtocol
    }

    /// Get the quick J-Band protocol
    func getQuickProtocol() -> JaegerBandProtocol {
        return JaegerBandProtocol.quickProtocol
    }

    /// Get the travel J-Band protocol
    func getTravelProtocol() -> JaegerBandProtocol {
        return JaegerBandProtocol.travelProtocol
    }

    /// Get the pre-throwing warm-up protocol
    func getPreThrowProtocol() -> JaegerBandProtocol {
        return JaegerBandProtocol.preThrowProtocol
    }

    /// Get protocol for a specific variation
    func getProtocol(for variation: JaegerBandVariation) -> JaegerBandProtocol {
        return JaegerBandProtocol.protocolFor(variation: variation)
    }

    /// Get all available protocols
    func getAllProtocols() -> [JaegerBandProtocol] {
        return JaegerBandProtocol.allProtocols
    }

    // MARK: - Recommended Protocol

    /// Get recommended protocol based on context
    /// - Parameters:
    ///   - isPreThrowing: Whether this is before a throwing session
    ///   - availableMinutes: Available time in minutes
    ///   - isTravel: Whether user is traveling
    /// - Returns: Recommended protocol variation
    func getRecommendedProtocol(
        isPreThrowing: Bool = false,
        availableMinutes: Int = 15,
        isTravel: Bool = false
    ) -> JaegerBandVariation {
        if isPreThrowing {
            return .preThrow
        }

        if isTravel {
            return .travel
        }

        if availableMinutes < 8 {
            return .quick
        }

        return .full
    }

    // MARK: - Session Logging

    /// Log a completed J-Band session to Supabase
    /// - Parameters:
    ///   - variation: The protocol variation completed
    ///   - durationMinutes: Actual duration in minutes
    ///   - exercisesCompleted: Number of exercises completed
    ///   - exercisesSkipped: Number of exercises skipped
    ///   - notes: Optional session notes
    ///   - armSorenessBefore: Arm soreness level before (1-10)
    ///   - armSorenessAfter: Arm soreness level after (1-10)
    ///   - wasPreThrowingWarmup: Whether this was used as pre-throwing warm-up
    func logSession(
        variation: JaegerBandVariation,
        durationMinutes: Int,
        exercisesCompleted: Int,
        exercisesSkipped: Int = 0,
        notes: String? = nil,
        armSorenessBefore: Int? = nil,
        armSorenessAfter: Int? = nil,
        wasPreThrowingWarmup: Bool = false
    ) async throws {
        guard let patientId = supabase.userId else {
            logger.log("No patient ID available for logging J-Band session", level: .error)
            throw JaegerBandError.noPatientId
        }

        isLoading = true
        defer { isLoading = false }

        logger.log("Logging J-Band session: \(variation.rawValue), \(durationMinutes) min", level: .diagnostic)

        struct JaegerSessionInsert: Encodable {
            let patientId: String
            let variation: String
            let completedAt: String
            let durationMinutes: Int
            let exercisesCompleted: Int
            let exercisesSkipped: Int
            let notes: String?
            let armSorenessBefore: Int?
            let armSorenessAfter: Int?
            let wasPreThrowingWarmup: Bool

            enum CodingKeys: String, CodingKey {
                case patientId = "patient_id"
                case variation
                case completedAt = "completed_at"
                case durationMinutes = "duration_minutes"
                case exercisesCompleted = "exercises_completed"
                case exercisesSkipped = "exercises_skipped"
                case notes
                case armSorenessBefore = "arm_soreness_before"
                case armSorenessAfter = "arm_soreness_after"
                case wasPreThrowingWarmup = "was_pre_throwing_warmup"
            }
        }

        let sessionLog = JaegerSessionInsert(
            patientId: patientId,
            variation: variation.rawValue,
            completedAt: ISO8601DateFormatter().string(from: Date()),
            durationMinutes: durationMinutes,
            exercisesCompleted: exercisesCompleted,
            exercisesSkipped: exercisesSkipped,
            notes: notes,
            armSorenessBefore: armSorenessBefore,
            armSorenessAfter: armSorenessAfter,
            wasPreThrowingWarmup: wasPreThrowingWarmup
        )

        do {
            try await supabase.client
                .from("jaeger_band_logs")
                .insert(sessionLog)
                .execute()

            logger.log("J-Band session logged successfully", level: .success)

            // Refresh stats after logging
            await fetchWeeklyStats()
        } catch {
            logger.log("Error logging J-Band session: \(error.localizedDescription)", level: .error)
            self.error = error
            throw error
        }
    }

    // MARK: - Session History

    /// Fetch recent J-Band sessions for the current user
    /// - Parameter limit: Maximum number of sessions to fetch
    /// - Returns: Array of session logs
    func fetchRecentSessions(limit: Int = 10) async throws -> [JaegerBandSessionLog] {
        guard let patientId = supabase.userId else {
            throw JaegerBandError.noPatientId
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await supabase.client
                .from("jaeger_band_logs")
                .select()
                .eq("patient_id", value: patientId)
                .order("completed_at", ascending: false)
                .limit(limit)
                .execute()

            let decoder = PTSupabaseClient.flexibleDecoder
            let sessions = try decoder.decode([JaegerBandSessionLog].self, from: response.data)

            await MainActor.run {
                self.recentSessions = sessions
            }

            return sessions
        } catch {
            logger.log("Error fetching J-Band sessions: \(error.localizedDescription)", level: .error)
            self.error = error
            throw error
        }
    }

    /// Fetch sessions for a specific date range
    func fetchSessions(from startDate: Date, to endDate: Date) async throws -> [JaegerBandSessionLog] {
        guard let patientId = supabase.userId else {
            throw JaegerBandError.noPatientId
        }

        let formatter = ISO8601DateFormatter()
        let startString = formatter.string(from: startDate)
        let endString = formatter.string(from: endDate)

        do {
            let response = try await supabase.client
                .from("jaeger_band_logs")
                .select()
                .eq("patient_id", value: patientId)
                .gte("completed_at", value: startString)
                .lte("completed_at", value: endString)
                .order("completed_at", ascending: false)
                .execute()

            let decoder = PTSupabaseClient.flexibleDecoder
            return try decoder.decode([JaegerBandSessionLog].self, from: response.data)
        } catch {
            logger.log("Error fetching J-Band sessions for date range: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    // MARK: - Statistics

    /// Fetch weekly J-Band completion stats
    func fetchWeeklyStats() async {
        guard supabase.userId != nil else { return }

        // Get start of current week
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return
        }

        do {
            let sessions = try await fetchSessions(from: weekStart, to: now)
            weeklyCompletions = sessions.count

            // Calculate streak (consecutive days with J-Band)
            currentStreak = await calculateStreak()
        } catch {
            logger.log("Error fetching weekly stats: \(error.localizedDescription)", level: .warning)
        }
    }

    /// Calculate current J-Band streak (consecutive days)
    private func calculateStreak() async -> Int {
        guard supabase.userId != nil else { return 0 }

        do {
            // Fetch last 30 days of sessions
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            let sessions = try await fetchSessions(from: thirtyDaysAgo, to: Date())

            // Group by date
            let calendar = Calendar.current
            var sessionDates = Set<String>()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            for session in sessions {
                let dateString = dateFormatter.string(from: session.completedAt)
                sessionDates.insert(dateString)
            }

            // Count consecutive days from today
            var streak = 0
            var currentDate = Date()

            while true {
                let dateString = dateFormatter.string(from: currentDate)
                if sessionDates.contains(dateString) {
                    streak += 1
                    currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                } else {
                    break
                }
            }

            return streak
        } catch {
            return 0
        }
    }

    /// Check if J-Band has been completed today
    func hasCompletedToday() async -> Bool {
        guard supabase.userId != nil else { return false }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        do {
            let sessions = try await fetchSessions(from: startOfDay, to: endOfDay)
            return !sessions.isEmpty
        } catch {
            return false
        }
    }

    // MARK: - Arm Care Schedule Integration

    /// Check if J-Band is scheduled for today based on arm care protocol
    /// - Parameter throwingDaysPerWeek: Number of throwing days per week
    /// - Returns: Whether J-Band should be done today
    func isScheduledForToday(throwingDaysPerWeek: Int = 4) -> Bool {
        // J-Band is recommended:
        // - Every throwing day (before throwing)
        // - Active recovery days
        // For simplicity, we recommend it daily for arm care
        return true
    }

    /// Get recommended time of day for J-Band based on schedule
    /// - Parameter hasThrowingToday: Whether there's a throwing session today
    /// - Returns: Recommended time description
    func getRecommendedTime(hasThrowingToday: Bool) -> String {
        if hasThrowingToday {
            return "Before your throwing session"
        } else {
            return "Morning or evening as part of arm care"
        }
    }

    // MARK: - Protocol Customization

    /// Filter exercises by category
    func getExercises(for category: JaegerBandExerciseCategory, from protocol: JaegerBandProtocol? = nil) -> [JaegerBandExercise] {
        let targetProtocol = `protocol` ?? JaegerBandProtocol.fullProtocol
        return targetProtocol.exercises.filter { $0.category == category }
    }

    /// Get exercises that target specific muscles
    func getExercises(targeting muscle: String, from protocol: JaegerBandProtocol? = nil) -> [JaegerBandExercise] {
        let targetProtocol = `protocol` ?? JaegerBandProtocol.fullProtocol
        return targetProtocol.exercises.filter { exercise in
            exercise.targetMuscles.contains { $0.lowercased().contains(muscle.lowercased()) }
        }
    }
}

// MARK: - Errors

enum JaegerBandError: LocalizedError {
    case noPatientId
    case sessionNotFound
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .noPatientId:
            return "No patient ID available. Please sign in."
        case .sessionNotFound:
            return "Session not found."
        case .saveFailed(let message):
            return "Failed to save session: \(message)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noPatientId:
            return "Sign out and sign back in to refresh your session."
        case .sessionNotFound:
            return "This J-Band session may have been deleted. Start a new session."
        case .saveFailed:
            return "Please check your connection and try again. Your progress has been saved locally."
        }
    }
}

// MARK: - Statistics Model

/// Statistics for J-Band completion
struct JaegerBandStatistics: Codable {
    let totalSessions: Int
    let sessionsThisWeek: Int
    let currentStreak: Int
    let longestStreak: Int
    let averageDurationMinutes: Double
    let mostUsedVariation: JaegerBandVariation?
    let totalMinutes: Int

    enum CodingKeys: String, CodingKey {
        case totalSessions = "total_sessions"
        case sessionsThisWeek = "sessions_this_week"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case averageDurationMinutes = "average_duration_minutes"
        case mostUsedVariation = "most_used_variation"
        case totalMinutes = "total_minutes"
    }
}

// MARK: - Soreness Tracking

extension JaegerBandService {
    /// Track arm soreness improvement from J-Band sessions
    /// - Returns: Array of soreness data points
    func getSorenessImprovementData() async throws -> [SorenessDataPoint] {
        let sessions = try await fetchRecentSessions(limit: 30)

        return sessions.compactMap { session -> SorenessDataPoint? in
            guard let before = session.armSorenessBefore,
                  let after = session.armSorenessAfter else {
                return nil
            }
            return SorenessDataPoint(
                date: session.completedAt,
                before: before,
                after: after,
                improvement: before - after
            )
        }
    }
}

/// Data point for soreness tracking
struct SorenessDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let before: Int
    let after: Int
    let improvement: Int
}

// MARK: - Widget Support

extension JaegerBandService {
    /// Get data for J-Band widget
    func getWidgetData() async -> JaegerBandWidgetData {
        let hasCompletedToday = await hasCompletedToday()
        let streak = await calculateStreak()

        return JaegerBandWidgetData(
            hasCompletedToday: hasCompletedToday,
            currentStreak: streak,
            recommendedVariation: getRecommendedProtocol(),
            lastCompletedDate: recentSessions.first?.completedAt
        )
    }
}

/// Widget data model
struct JaegerBandWidgetData {
    let hasCompletedToday: Bool
    let currentStreak: Int
    let recommendedVariation: JaegerBandVariation
    let lastCompletedDate: Date?

    var statusText: String {
        if hasCompletedToday {
            return "Completed today"
        } else {
            return "Not completed yet"
        }
    }

    var streakText: String {
        if currentStreak == 0 {
            return "Start your streak!"
        } else if currentStreak == 1 {
            return "1 day streak"
        } else {
            return "\(currentStreak) day streak"
        }
    }
}

// MARK: - Notification Integration

extension JaegerBandService {
    /// Get notification content for J-Band reminder
    func getReminderNotificationContent() -> (title: String, body: String) {
        // Static message for notification content
        let title = "J-Band Reminder"
        let body = "Time for your daily arm care routine. Keep that streak going!"

        return (title, body)
    }
}
