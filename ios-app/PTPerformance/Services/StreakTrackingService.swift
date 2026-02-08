//
//  StreakTrackingService.swift
//  PTPerformance
//
//  ACP-836: Streak Tracking Feature
//  Service for managing workout and arm care streaks
//

import SwiftUI

// MARK: - Encodable Structs for Supabase RPC

/// RPC parameters for getting streak statistics
private struct GetStreakStatisticsParams: Encodable {
    let pPatientId: String

    enum CodingKeys: String, CodingKey {
        case pPatientId = "p_patient_id"
    }
}

/// Service for managing streak tracking data
///
/// Tracks workout and arm care completion streaks to encourage consistent
/// engagement. Supports three streak types: workout-only, arm care-only,
/// and combined streaks. Provides calendar history for visual display and
/// comprehensive statistics.
///
/// ## Streak Types
/// - **Workout**: Consecutive days with completed workouts
/// - **Arm Care**: Consecutive days with arm care assessments
/// - **Combined**: Consecutive days with either activity
///
/// ## Usage Example
/// ```swift
/// let streakService = StreakTrackingService.shared
///
/// // Record a workout completion
/// try await streakService.recordWorkoutCompletion(for: patientId)
///
/// // Get current streaks
/// let streaks = try await streakService.fetchCurrentStreaks(for: patientId)
///
/// // Get calendar history for display
/// let history = try await streakService.getStreakHistory(for: patientId, days: 30)
/// ```
@MainActor
class StreakTrackingService: ObservableObject {

    // MARK: - Singleton

    static let shared = StreakTrackingService()

    // MARK: - Properties

    nonisolated(unsafe) private let client: PTSupabaseClient
    private let logger = DebugLogger.shared
    private let errorLogger = ErrorLogger.shared

    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var currentStreaks: [StreakRecord] = []
    @Published var streakHistory: [CalendarHistoryEntry] = []

    // MARK: - Initialization

    /// Initialize with a Supabase client.
    /// - Parameter client: The Supabase client to use (defaults to shared instance)
    nonisolated init(client: PTSupabaseClient = .shared) {
        self.client = client
    }

    // MARK: - Fetch Current Streaks

    /// Fetch all current streak records for a patient.
    ///
    /// - Parameter patientId: Patient UUID
    /// - Returns: Array of StreakRecord for each streak type
    /// - Throws: Database errors if the query fails
    func fetchCurrentStreaks(for patientId: UUID) async throws -> [StreakRecord] {
        logger.log("[StreakTrackingService] Fetching streaks for patient: \(patientId)", level: .diagnostic)
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await client.client
                .from("streak_records")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .execute()

            let decoder = createStreakDecoder()
            let records = try decoder.decode([StreakRecord].self, from: response.data)

            // Update published property
            self.currentStreaks = records
            logger.log("[StreakTrackingService] Fetched \(records.count) streak records", level: .success)

            return records
        } catch {
            errorLogger.logError(error, context: "StreakTrackingService.fetchCurrentStreaks", metadata: [
                "patient_id": patientId.uuidString
            ])
            self.error = error
            throw error
        }
    }

    /// Fetch streak for a specific type.
    ///
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - type: Type of streak to fetch
    /// - Returns: StreakRecord or nil if not found
    /// - Throws: Database errors if the query fails
    func fetchStreak(for patientId: UUID, type: StreakType) async throws -> StreakRecord? {
        logger.log("[StreakTrackingService] Fetching \(type.rawValue) streak for patient: \(patientId)", level: .diagnostic)

        do {
            let response = try await client.client
                .from("streak_records")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .eq("streak_type", value: type.rawValue)
                .limit(1)
                .execute()

            guard !response.data.isEmpty else {
                logger.log("[StreakTrackingService] No \(type.rawValue) streak found", level: .info)
                return nil
            }

            let decoder = createStreakDecoder()
            let records = try decoder.decode([StreakRecord].self, from: response.data)
            logger.log("[StreakTrackingService] Fetched \(type.rawValue) streak", level: .success)
            return records.first
        } catch {
            errorLogger.logError(error, context: "StreakTrackingService.fetchStreak", metadata: [
                "patient_id": patientId.uuidString,
                "streak_type": type.rawValue
            ])
            self.error = error
            throw error
        }
    }

    // MARK: - Record Activity

    /// Record daily activity (workout or arm care completion)
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - date: Activity date (defaults to today)
    ///   - workoutCompleted: Whether a workout was completed
    ///   - armCareCompleted: Whether arm care was completed
    ///   - sessionId: Optional scheduled session ID
    ///   - manualSessionId: Optional manual session ID
    ///   - notes: Optional notes
    /// - Returns: Created/updated StreakHistory record
    @discardableResult
    func recordActivity(
        for patientId: UUID,
        date: Date = Date(),
        workoutCompleted: Bool = false,
        armCareCompleted: Bool = false,
        sessionId: UUID? = nil,
        manualSessionId: UUID? = nil,
        notes: String? = nil
    ) async throws -> StreakHistory {
        isLoading = true
        defer { isLoading = false }

        // Format date as YYYY-MM-DD for PostgreSQL DATE column
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: date)

        let params: [String: String?] = [
            DatabaseConstants.RPCParams.patientId: patientId.uuidString,
            DatabaseConstants.RPCParams.activityDate: dateString,
            DatabaseConstants.RPCParams.workoutCompleted: workoutCompleted ? "true" : "false",
            DatabaseConstants.RPCParams.armCareCompleted: armCareCompleted ? "true" : "false",
            DatabaseConstants.RPCParams.sessionId: sessionId?.uuidString,
            "p_manual_session_id": manualSessionId?.uuidString,
            DatabaseConstants.RPCParams.notes: notes
        ]

        do {
            let response = try await client.client
                .rpc(DatabaseConstants.RPCFunctions.recordStreakActivity, params: params.compactMapValues { $0 })
                .execute()

            let decoder = createStreakDecoder()
            let history = try decoder.decode(StreakHistory.self, from: response.data)

            logger.log("[StreakTrackingService] Recorded activity for \(dateString): workout=\(workoutCompleted), arm_care=\(armCareCompleted)", level: .success)

            // Refresh streaks after recording activity
            _ = try? await fetchCurrentStreaks(for: patientId)

            // Notify widget bridge to update streak widget
            Task { @MainActor in
                await WidgetBridgeService.shared.refreshStreakWidget()
            }

            return history
        } catch {
            errorLogger.logError(error, context: "StreakTrackingService.recordActivity", metadata: [
                "patient_id": patientId.uuidString,
                "workout_completed": String(workoutCompleted),
                "arm_care_completed": String(armCareCompleted)
            ])
            self.error = error
            throw error
        }
    }

    // MARK: - Get Streak History

    /// Fetch streak history for calendar display
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - days: Number of days to fetch (default 30)
    /// - Returns: Array of CalendarHistoryEntry
    func getStreakHistory(
        for patientId: UUID,
        days: Int = 30
    ) async throws -> [CalendarHistoryEntry] {
        isLoading = true
        defer { isLoading = false }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current

        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate

        let params: [String: String] = [
            DatabaseConstants.RPCParams.patientId: patientId.uuidString,
            DatabaseConstants.RPCParams.startDate: dateFormatter.string(from: startDate),
            DatabaseConstants.RPCParams.endDate: dateFormatter.string(from: endDate)
        ]

        do {
            let response = try await client.client
                .rpc(DatabaseConstants.RPCFunctions.getStreakHistory, params: params)
                .execute()

            let decoder = createStreakDecoder()
            let history = try decoder.decode([CalendarHistoryEntry].self, from: response.data)

            // Update published property
            self.streakHistory = history
            logger.log("[StreakTrackingService] Fetched \(history.count) history entries for last \(days) days", level: .success)

            return history
        } catch {
            errorLogger.logError(error, context: "StreakTrackingService.getStreakHistory", metadata: [
                "patient_id": patientId.uuidString,
                "days": String(days)
            ])
            self.error = error
            throw error
        }
    }

    // MARK: - Get Streak Statistics

    /// Fetch comprehensive streak statistics.
    ///
    /// - Parameter patientId: Patient UUID
    /// - Returns: Array of StreakStatistics for each streak type
    /// - Throws: Database errors if the query fails
    func getStreakStatistics(for patientId: UUID) async throws -> [StreakStatistics] {
        logger.log("[StreakTrackingService] Fetching streak statistics for patient: \(patientId)", level: .diagnostic)

        do {
            let params = GetStreakStatisticsParams(pPatientId: patientId.uuidString)
            let response = try await client.client
                .rpc(DatabaseConstants.RPCFunctions.getStreakStatistics, params: params)
                .execute()

            let decoder = createStreakDecoder()
            let stats = try decoder.decode([StreakStatistics].self, from: response.data)
            logger.log("[StreakTrackingService] Fetched \(stats.count) streak statistics", level: .success)
            return stats
        } catch {
            errorLogger.logError(error, context: "StreakTrackingService.getStreakStatistics", metadata: [
                "patient_id": patientId.uuidString
            ])
            self.error = error
            throw error
        }
    }

    // MARK: - Convenience Methods

    /// Check if activity has been logged for today
    /// - Parameter patientId: Patient UUID
    /// - Returns: True if today's entry exists
    func hasActivityToday(for patientId: UUID) async -> Bool {
        do {
            let history = try await getStreakHistory(for: patientId, days: 1)
            let today = Calendar.current.startOfDay(for: Date())
            return history.contains { Calendar.current.isDate($0.activityDate, inSameDayAs: today) && $0.hasAnyActivity }
        } catch {
            return false
        }
    }

    /// Get combined streak (most commonly displayed)
    /// - Parameter patientId: Patient UUID
    /// - Returns: Combined streak record
    func getCombinedStreak(for patientId: UUID) async throws -> StreakRecord? {
        return try await fetchStreak(for: patientId, type: .combined)
    }

    /// Record workout completion
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - sessionId: Optional session ID
    func recordWorkoutCompletion(
        for patientId: UUID,
        sessionId: UUID? = nil,
        manualSessionId: UUID? = nil
    ) async throws {
        try await recordActivity(
            for: patientId,
            workoutCompleted: true,
            sessionId: sessionId,
            manualSessionId: manualSessionId
        )
    }

    /// Record arm care completion
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - sessionId: Optional session ID
    func recordArmCareCompletion(
        for patientId: UUID,
        sessionId: UUID? = nil
    ) async throws {
        try await recordActivity(
            for: patientId,
            armCareCompleted: true,
            sessionId: sessionId
        )
    }

    // MARK: - Private Helpers

    /// Create a JSON decoder configured for streak data
    /// Handles both DATE format (YYYY-MM-DD) and ISO8601 timestamps
    private func createStreakDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try ISO8601 with fractional seconds first (for created_at, updated_at)
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
}

// MARK: - Streak Display Helpers

extension StreakTrackingService {
    /// Create WidgetStreak from StreakRecord for widget display
    func createWidgetStreak(from record: StreakRecord) -> WidgetStreak {
        let widgetType: WidgetStreak.StreakType
        switch record.streakType {
        case .workout: widgetType = .workout
        case .armCare: widgetType = .armCare
        case .combined: widgetType = .combined
        }

        return WidgetStreak(
            currentStreak: record.currentStreak,
            longestStreak: record.longestStreak,
            streakType: widgetType,
            lastActivityDate: record.lastActivityDate,
            lastUpdated: Date()
        )
    }

    /// Get formatted streak display text
    func formatStreakDisplay(_ streak: Int) -> String {
        switch streak {
        case 0: return "0 days"
        case 1: return "1 day"
        default: return "\(streak) days"
        }
    }
}

// MARK: - Error Types

enum StreakError: LocalizedError {
    case noPatientFound
    case activityRecordFailed
    case fetchFailed

    var errorDescription: String? {
        switch self {
        case .noPatientFound:
            return "No patient found for the current user"
        case .activityRecordFailed:
            return "Failed to record activity"
        case .fetchFailed:
            return "Failed to fetch streak data"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noPatientFound:
            return "Please sign out and sign back in to refresh your account."
        case .activityRecordFailed:
            return "Your workout was saved, but the streak couldn't be updated. It will sync automatically later."
        case .fetchFailed:
            return "Please check your internet connection and try again."
        }
    }
}
