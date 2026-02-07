import SwiftUI

/// ACP-901, ACP-902, ACP-903: ViewModel for Recovery Tracking UI
/// Manages state for recovery dashboard, timer logic, and stats calculations
@MainActor
final class RecoveryTrackingViewModel: ObservableObject {

    // MARK: - Published State

    @Published var recentSessions: [RecoverySession] = []
    @Published var isLoading: Bool = false
    @Published var error: String?

    // Sheet/Navigation State
    @Published var showingLogSheet: Bool = false
    @Published var showingTimer: Bool = false
    @Published var selectedSessionType: RecoverySessionType?
    @Published var timerConfig: TimerConfiguration?

    // Streak State
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var hasRecoveredToday: Bool = false

    // MARK: - Dependencies

    private let recoveryService: RecoveryService
    private let streakService: StreakTrackingService

    // MARK: - Initialization

    init(
        recoveryService: RecoveryService,
        streakService: StreakTrackingService
    ) {
        self.recoveryService = recoveryService
        self.streakService = streakService
    }

    /// Convenience initializer using shared instances
    convenience init() {
        self.init(
            recoveryService: RecoveryService.shared,
            streakService: StreakTrackingService.shared
        )
    }

    // MARK: - Computed Properties

    /// Weekly statistics for the dashboard
    var weeklyStats: WeeklyRecoveryStats {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weeklySessions = recentSessions.filter { $0.loggedAt >= weekAgo }

        let totalMinutes = weeklySessions.reduce(0) { $0 + $1.durationMinutes }

        // Find most used protocol
        let protocolCounts = Dictionary(grouping: weeklySessions, by: { $0.protocolType })
        let favoriteType = protocolCounts.max(by: { $0.value.count < $1.value.count })?.key

        return WeeklyRecoveryStats(
            sessions: weeklySessions.count,
            totalMinutes: totalMinutes,
            favoriteType: favoriteType
        )
    }

    /// Weekly breakdown by recovery type
    var weeklyBreakdown: [RecoveryTypeBreakdown] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weeklySessions = recentSessions.filter { $0.loggedAt >= weekAgo }

        let grouped = Dictionary(grouping: weeklySessions, by: { $0.protocolType })

        return grouped.map { type, sessions in
            RecoveryTypeBreakdown(
                type: type,
                count: sessions.count,
                totalMinutes: sessions.reduce(0) { $0 + $1.durationMinutes }
            )
        }.sorted { $0.count > $1.count }
    }

    /// Streak message based on current streak
    var streakMessage: String {
        if currentStreak == 0 {
            return "Start your streak today!"
        } else if currentStreak == 1 {
            return "Keep it going tomorrow!"
        } else if currentStreak < 7 {
            return "Building momentum!"
        } else if currentStreak < 14 {
            return "One week strong!"
        } else if currentStreak < 30 {
            return "Impressive consistency!"
        } else {
            return "Recovery champion!"
        }
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true
        error = nil

        do {
            // Fetch recent sessions
            await recoveryService.fetchSessions(days: 30)
            recentSessions = recoveryService.sessions

            // Calculate streak data
            await calculateStreakData()

            // Check if recovered today
            hasRecoveredToday = recentSessions.contains { session in
                Calendar.current.isDateInToday(session.loggedAt)
            }
        } catch {
            self.error = error.localizedDescription
            DebugLogger.shared.error("RecoveryTrackingViewModel", "Failed to load data: \(error)")
        }

        isLoading = false
    }

    private func calculateStreakData() async {
        let calendar = Calendar.current
        var streak = 0
        var maxStreak = 0
        var currentDate = calendar.startOfDay(for: Date())

        // Check today first
        let todaySessions = recentSessions.filter { calendar.isDateInToday($0.loggedAt) }
        if !todaySessions.isEmpty {
            streak = 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }

        // Go backwards checking each day
        while true {
            let daySessions = recentSessions.filter {
                calendar.isDate($0.loggedAt, inSameDayAs: currentDate)
            }

            if daySessions.isEmpty {
                break
            }

            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }

        currentStreak = streak

        // Calculate longest streak (look through all sessions)
        let sessionDates = Set(recentSessions.map { calendar.startOfDay(for: $0.loggedAt) })
        let sortedDates = sessionDates.sorted()

        var tempStreak = 1
        for i in 1..<sortedDates.count {
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: sortedDates[i - 1]),
               calendar.isDate(sortedDates[i], inSameDayAs: nextDay) {
                tempStreak += 1
                maxStreak = max(maxStreak, tempStreak)
            } else {
                tempStreak = 1
            }
        }

        longestStreak = max(maxStreak, streak)
    }

    // MARK: - Quick Log Actions

    func startQuickLog(for type: RecoveryProtocolType) {
        let sessionType = type.toSessionType
        selectedSessionType = sessionType

        // For quick logs, go directly to timer
        timerConfig = TimerConfiguration(
            sessionType: sessionType,
            duration: sessionType.defaultDuration * 60,
            temperature: nil
        )
        showingTimer = true
    }

    func showAllSessionTypes() {
        selectedSessionType = nil
        showingLogSheet = true
    }

    // MARK: - Session Management

    func saveSession(_ input: RecoverySessionInput) async {
        isLoading = true

        do {
            try await recoveryService.logSession(
                protocolType: input.protocolType,
                durationSeconds: input.duration,
                temperature: input.temperature,
                perceivedEffort: input.perceivedEffort,
                notes: input.notes
            )

            // Record streak activity
            if let patientId = await getPatientId() {
                try? await streakService.recordActivity(
                    for: patientId,
                    workoutCompleted: false,
                    armCareCompleted: false // Recovery sessions tracked separately
                )
            }

            await loadData()
            HapticFeedback.success()
        } catch {
            self.error = error.localizedDescription
            HapticFeedback.error()
            DebugLogger.shared.error("RecoveryTrackingViewModel", "Failed to save session: \(error)")
        }

        isLoading = false
    }

    func completeTimerSession(duration: Int, notes: String) async {
        guard let config = timerConfig else { return }

        let input = RecoverySessionInput(
            sessionType: config.sessionType,
            duration: duration,
            temperature: config.temperature,
            perceivedEffort: 5, // Default effort, user can edit later
            notes: notes.isEmpty ? nil : notes
        )

        await saveSession(input)
        showingTimer = false
        timerConfig = nil
    }

    func cancelTimer() {
        showingTimer = false
        timerConfig = nil
    }

    // MARK: - Helpers

    private func getPatientId() async -> UUID? {
        guard let userId = PTSupabaseClient.shared.client.auth.currentUser?.id else {
            return nil
        }

        struct PatientRow: Decodable {
            let id: UUID
        }

        do {
            let patients: [PatientRow] = try await PTSupabaseClient.shared.client
                .from("patients")
                .select("id")
                .eq("user_id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value

            return patients.first?.id
        } catch {
            return nil
        }
    }
}

// MARK: - Supporting Types

struct WeeklyRecoveryStats {
    let sessions: Int
    let totalMinutes: Int
    let favoriteType: RecoveryProtocolType?
}

struct RecoveryTypeBreakdown {
    let type: RecoveryProtocolType
    let count: Int
    let totalMinutes: Int
}

struct TimerConfiguration {
    let sessionType: RecoverySessionType
    let duration: Int // seconds
    let temperature: Double?
}

// MARK: - RecoveryProtocolType Extension

extension RecoveryProtocolType {
    /// Converts RecoveryProtocolType to RecoverySessionType for the UI
    var toSessionType: RecoverySessionType {
        switch self {
        case .saunaTraditional: return .traditionalSauna
        case .saunaInfrared: return .infraredSauna
        case .saunaSteam: return .steamRoom
        case .coldPlunge: return .coldPlunge
        case .coldShower: return .coldShower
        case .iceBath: return .iceBath
        case .contrast: return .contrastTherapy
        }
    }
}

// MARK: - Preview Support

#if DEBUG
extension RecoveryTrackingViewModel {
    static var preview: RecoveryTrackingViewModel {
        let viewModel = RecoveryTrackingViewModel()
        viewModel.currentStreak = 5
        viewModel.longestStreak = 12
        viewModel.hasRecoveredToday = true
        // Sessions would be populated from the service in real usage
        return viewModel
    }
}
#endif
