import Foundation
import SwiftUI

// MARK: - Unified Workout History Item

/// Represents either a prescribed session or manual workout in history
enum WorkoutHistoryItem: Identifiable {
    case prescribed(SessionSummary)
    case manual(ManualWorkoutSummary)

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
            return "Session \(session.sessionNumber)"
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
        case .prescribed(let session):
            return session.totalVolume
        case .manual(let workout):
            return workout.totalVolume
        }
    }

    var duration: Int? {
        switch self {
        case .prescribed(let session):
            return session.durationMinutes
        case .manual(let workout):
            return workout.durationMinutes
        }
    }
}

/// ViewModel for History view with pagination support
@MainActor
class HistoryViewModel: ObservableObject {
    @Published var painTrend: [PainDataPoint] = []
    @Published var adherence: AdherenceData?
    @Published var recentSessions: [SessionSummary] = []
    @Published var manualWorkouts: [ManualWorkoutSummary] = []
    @Published var summaryStats: SummaryStats?

    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Pagination State
    @Published var hasMoreWorkouts = true
    @Published var isLoadingMore = false

    private var currentSessionsPage = 0
    private var currentManualPage = 0
    private let pageSize = 20
    private var cachedPatientId: String?

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

    /// Fetch initial history data with pagination
    func fetchData(for patientId: String) async {
        isLoading = true
        errorMessage = nil
        cachedPatientId = patientId

        // Reset pagination state
        currentSessionsPage = 0
        currentManualPage = 0
        hasMoreWorkouts = true
        recentSessions = []
        manualWorkouts = []

        do {
            // Fetch all data in parallel (including manual workouts)
            // Initial load uses pageSize for workouts
            async let painTask = analyticsService.fetchPainTrend(patientId: patientId, days: 14)
            async let adherenceTask = analyticsService.fetchAdherence(patientId: patientId, days: 30)
            async let sessionsTask = analyticsService.fetchRecentSessions(patientId: patientId, limit: pageSize)
            async let manualTask = analyticsService.fetchRecentManualWorkouts(patientId: patientId, limit: pageSize)
            async let statsTask = analyticsService.fetchSummaryStats(patientId: patientId)

            let (pain, adh, sessions, manual, stats) = try await (painTask, adherenceTask, sessionsTask, manualTask, statsTask)

            painTrend = pain
            adherence = adh
            recentSessions = sessions
            manualWorkouts = manual
            summaryStats = stats

            // Check if there might be more data
            hasMoreWorkouts = sessions.count >= pageSize || manual.count >= pageSize

            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    /// Load more workouts for pagination
    func loadMoreWorkouts() async {
        guard hasMoreWorkouts && !isLoadingMore else { return }
        guard let patientId = cachedPatientId else { return }

        isLoadingMore = true

        do {
            // Increment pages and fetch next batch
            currentSessionsPage += 1
            currentManualPage += 1

            let offset = currentSessionsPage * pageSize

            async let sessionsTask = analyticsService.fetchRecentSessionsPaginated(
                patientId: patientId,
                limit: pageSize,
                offset: offset
            )
            async let manualTask = analyticsService.fetchRecentManualWorkoutsPaginated(
                patientId: patientId,
                limit: pageSize,
                offset: offset
            )

            let (newSessions, newManual) = try await (sessionsTask, manualTask)

            // Append new data
            recentSessions.append(contentsOf: newSessions)
            manualWorkouts.append(contentsOf: newManual)

            // Check if we've reached the end
            hasMoreWorkouts = newSessions.count >= pageSize || newManual.count >= pageSize

            isLoadingMore = false
        } catch {
            // Don't show error for pagination failures, just stop loading
            isLoadingMore = false
            hasMoreWorkouts = false
        }
    }

    /// Refresh data
    func refresh(for patientId: String) async {
        await fetchData(for: patientId)
    }
}
