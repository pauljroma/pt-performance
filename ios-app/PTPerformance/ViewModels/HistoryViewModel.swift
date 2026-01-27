import Foundation
import SwiftUI

// MARK: - BUILD 219: Unified Workout History Item

/// Represents either a prescribed session or manual workout in history
enum WorkoutHistoryItem: Identifiable {
    case prescribed(SessionSummary)
    case manual(AnalyticsService.ManualWorkoutSummary)

    var id: String {
        switch self {
        case .prescribed(let session):
            return "prescribed-\(session.id)"
        case .manual(let workout):
            return "manual-\(workout.id)"
        }
    }

    var date: Date {
        switch self {
        case .prescribed(let session):
            return session.sessionDate
        case .manual(let workout):
            return workout.workoutDate
        }
    }

    var name: String {
        switch self {
        case .prescribed(let session):
            return "Session \(session.sessionNumber ?? 0)"
        case .manual(let workout):
            return workout.displayName
        }
    }

    var isCompleted: Bool {
        switch self {
        case .prescribed(let session):
            return session.completed
        case .manual(let workout):
            return workout.completed
        }
    }

    var isManual: Bool {
        if case .manual = self { return true }
        return false
    }

    var exerciseCount: Int? {
        switch self {
        case .prescribed(let session):
            return session.exerciseCount
        case .manual(let workout):
            return workout.exerciseCount
        }
    }

    var avgPain: Double? {
        switch self {
        case .prescribed(let session):
            return session.avgPainScore
        case .manual(let workout):
            return workout.avgPain
        }
    }

    var volume: Double? {
        switch self {
        case .prescribed:
            return nil
        case .manual(let workout):
            return workout.totalVolume
        }
    }

    var duration: Int? {
        switch self {
        case .prescribed:
            return nil
        case .manual(let workout):
            return workout.durationMinutes
        }
    }
}

/// ViewModel for History view
@MainActor
class HistoryViewModel: ObservableObject {
    @Published var painTrend: [PainDataPoint] = []
    @Published var adherence: AdherenceData?
    @Published var recentSessions: [SessionSummary] = []
    @Published var manualWorkouts: [AnalyticsService.ManualWorkoutSummary] = []
    @Published var summaryStats: SummaryStats?

    @Published var isLoading = false
    @Published var errorMessage: String?

    private let analyticsService: AnalyticsService

    /// Check if history is completely empty
    var isEmpty: Bool {
        summaryStats == nil &&
        painTrend.isEmpty &&
        adherence == nil &&
        recentSessions.isEmpty &&
        manualWorkouts.isEmpty
    }

    /// Combined workout history sorted by date (newest first)
    var allWorkouts: [WorkoutHistoryItem] {
        var items: [WorkoutHistoryItem] = []
        items.append(contentsOf: recentSessions.map { .prescribed($0) })
        items.append(contentsOf: manualWorkouts.map { .manual($0) })
        return items.sorted { $0.date > $1.date }
    }

    /// Count of manual workouts for display
    var manualWorkoutCount: Int {
        manualWorkouts.count
    }

    init(analyticsService: AnalyticsService = AnalyticsService()) {
        self.analyticsService = analyticsService
    }

    /// Fetch all history data
    func fetchData(for patientId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch all data in parallel (including manual workouts)
            async let painTask = analyticsService.fetchPainTrend(patientId: patientId, days: 14)
            async let adherenceTask = analyticsService.fetchAdherence(patientId: patientId, days: 30)
            async let sessionsTask = analyticsService.fetchRecentSessions(patientId: patientId, limit: 10)
            async let manualTask = analyticsService.fetchRecentManualWorkouts(patientId: patientId, limit: 10)
            async let statsTask = analyticsService.fetchSummaryStats(patientId: patientId)

            let (pain, adh, sessions, manual, stats) = try await (painTask, adherenceTask, sessionsTask, manualTask, statsTask)

            painTrend = pain
            adherence = adh
            recentSessions = sessions
            manualWorkouts = manual
            summaryStats = stats

            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    /// Refresh data
    func refresh(for patientId: String) async {
        await fetchData(for: patientId)
    }
}
