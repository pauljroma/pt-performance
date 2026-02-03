//
//  TimerHistoryViewModel.swift
//  PTPerformance
//
//  ViewModel for timer session history and weekly statistics
//

import SwiftUI

/// ViewModel for timer history view displaying completed sessions and statistics
@MainActor
class TimerHistoryViewModel: ObservableObject {
    // MARK: - Dependencies

    private let timerService: IntervalTimerService
    private let patientId: UUID

    // MARK: - Data State

    /// All timer sessions for this patient
    @Published var sessions: [WorkoutTimer] = []

    /// Template lookup by ID for session details
    @Published var templates: [UUID: IntervalTemplate] = [:]

    // MARK: - Statistics

    /// Weekly statistics summary
    @Published var weeklyStats: WeeklyStats?

    // MARK: - UI State

    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var selectedCategory: TimerCategory?

    // MARK: - Computed Properties

    /// Sessions grouped by date (start of day)
    var groupedSessions: [Date: [WorkoutTimer]] {
        Dictionary(grouping: sessions) { session in
            Calendar.current.startOfDay(for: session.startedAt)
        }
    }

    /// Sorted dates in descending order (most recent first)
    var sortedDates: [Date] {
        Array(groupedSessions.keys).sorted(by: >)
    }

    /// Whether there is any history to display
    var hasHistory: Bool {
        !sessions.isEmpty
    }

    /// Filtered sessions by selected category (if any)
    var filteredSessions: [WorkoutTimer] {
        guard let selectedCategory else {
            return sessions
        }

        // Filter sessions by mapping the template's TimerType to a TimerCategory
        return sessions.filter { session in
            guard let templateId = session.templateId,
                  let template = templates[templateId] else {
                // Sessions without a template cannot be categorized — exclude from filtered results
                return false
            }
            return categoryForTimerType(template.type) == selectedCategory
        }
    }

    /// Maps a TimerType to the closest TimerCategory for filtering purposes
    private func categoryForTimerType(_ type: TimerType) -> TimerCategory {
        switch type {
        case .tabata, .amrap:
            return .cardio
        case .emom, .intervals:
            return .strength
        case .custom:
            return .cardio
        }
    }

    /// Grouped filtered sessions
    var groupedFilteredSessions: [Date: [WorkoutTimer]] {
        Dictionary(grouping: filteredSessions) { session in
            Calendar.current.startOfDay(for: session.startedAt)
        }
    }

    /// Empty state message based on filters
    var emptyStateMessage: String {
        if let category = selectedCategory {
            return "No \(category.displayName.lowercased()) timer sessions yet"
        } else {
            return "No timer sessions yet"
        }
    }

    // MARK: - Initialization

    @MainActor init(
        patientId: UUID,
        timerService: IntervalTimerService? = nil
    ) {
        self.patientId = patientId
        self.timerService = timerService ?? .shared
    }

    // MARK: - Load History

    /// Load timer history for patient
    func loadHistory() async {
        isLoading = true
        showError = false

        do {
            // Fetch sessions from database
            sessions = try await timerService.fetchTimerHistory(
                for: patientId,
                limit: 50
            )

            // Load templates for each session
            await loadTemplates()

            // Calculate weekly stats
            calculateWeeklyStats()

        } catch {
            errorMessage = "We couldn't load your timer history. Please check your connection and try again."
            showError = true
            #if DEBUG
            print("❌ Error loading timer history: \(error)")
            #endif
        }

        isLoading = false
    }

    // MARK: - Load Templates

    /// Load templates for sessions that reference them
    private func loadTemplates() async {
        // Get unique template IDs from sessions
        let templateIds = Set(sessions.compactMap { $0.templateId })

        guard !templateIds.isEmpty else {
            #if DEBUG
            print("ℹ️ No templates to load")
            #endif
            return
        }

        do {
            // Fetch all templates (in production, we'd filter by IDs)
            let allTemplates = try await timerService.fetchTemplates(publicOnly: false)

            // Create lookup dictionary
            templates = Dictionary(
                uniqueKeysWithValues: allTemplates.map { ($0.id, $0) }
            )

            #if DEBUG
            print("✅ Loaded \(templates.count) templates")
            #endif
        } catch {
            DebugLogger.shared.warning("TimerHistoryViewModel", "Failed to load templates: \(error.localizedDescription)")
            // Continue without templates - not critical for display
        }
    }

    // MARK: - Calculate Weekly Stats

    /// Calculate statistics for the past 7 days
    private func calculateWeeklyStats() {
        let calendar = Calendar.current
        let now = Date()

        // Get date 7 days ago (start of day)
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else {
            weeklyStats = nil
            return
        }

        // Filter sessions from the past week
        let thisWeekSessions = sessions.filter { session in
            session.startedAt >= weekAgo && session.startedAt <= now
        }

        // Count total sessions
        let totalSessions = thisWeekSessions.count

        // Count completed sessions (have completedAt date)
        let completedSessions = thisWeekSessions.filter { $0.completedAt != nil }.count

        // Calculate total minutes (only for completed sessions)
        let totalMinutes = thisWeekSessions.reduce(0) { sum, session in
            guard let completed = session.completedAt else { return sum }

            // Calculate actual duration excluding paused time
            let duration = completed.timeIntervalSince(session.startedAt)
            let effectiveDuration = duration - Double(session.pausedSeconds)

            return sum + Int(effectiveDuration / 60)
        }

        // Calculate total rounds completed
        let totalRounds = thisWeekSessions.reduce(0) { sum, session in
            sum + session.roundsCompleted
        }

        // Create stats object
        weeklyStats = WeeklyStats(
            totalSessions: totalSessions,
            completedSessions: completedSessions,
            totalMinutes: totalMinutes,
            totalRounds: totalRounds
        )

        #if DEBUG
        print("📊 Weekly Stats: \(totalSessions) sessions, \(completedSessions) completed, \(totalMinutes) min, \(totalRounds) rounds")
        #endif
    }

    // MARK: - Session Details

    /// Get formatted duration for a session
    func duration(for session: WorkoutTimer) -> String {
        guard let completed = session.completedAt else {
            return "In Progress"
        }

        // Calculate actual duration excluding paused time
        let totalDuration = completed.timeIntervalSince(session.startedAt)
        let effectiveDuration = totalDuration - Double(session.pausedSeconds)

        let minutes = Int(effectiveDuration) / 60
        let seconds = Int(effectiveDuration) % 60

        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Get template for a session (if available)
    func template(for session: WorkoutTimer) -> IntervalTemplate? {
        guard let templateId = session.templateId else {
            return nil
        }
        return templates[templateId]
    }

    /// Get template name for a session
    func templateName(for session: WorkoutTimer) -> String {
        guard let templateId = session.templateId,
              let template = templates[templateId] else {
            return "Custom Timer"
        }
        return template.name
    }

    /// Get completion status text for a session
    func statusText(for session: WorkoutTimer) -> String {
        if session.completedAt != nil {
            return "Completed"
        } else {
            return "In Progress"
        }
    }

    /// Get completion percentage for a session (based on rounds)
    func completionPercentage(for session: WorkoutTimer) -> Double? {
        guard let templateId = session.templateId,
              let template = templates[templateId] else {
            return nil
        }

        guard template.rounds > 0 else {
            return nil
        }

        let percentage = Double(session.roundsCompleted) / Double(template.rounds) * 100
        return min(percentage, 100.0)
    }

    // MARK: - Date Formatting

    /// Format a date for display (e.g., "Today", "Yesterday", "Jan 1")
    func formattedDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            // This week - show day name
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"  // Full day name
            return formatter.string(from: date)
        } else {
            // Older - show date
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }

    /// Format a time for display (e.g., "2:30 PM")
    func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Format a full date and time (e.g., "Jan 1, 2024 at 2:30 PM")
    func formattedDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Category Filtering

    /// Set the category filter
    func setCategory(_ category: TimerCategory?) {
        selectedCategory = category
    }

    /// Clear all filters
    func clearFilters() {
        selectedCategory = nil
    }

    // MARK: - Refresh

    /// Refresh timer history
    func refresh() async {
        await loadHistory()
    }
}

// MARK: - Supporting Types

/// Weekly statistics summary for timer sessions
struct WeeklyStats {
    /// Total number of sessions started this week
    let totalSessions: Int

    /// Number of sessions completed this week
    let completedSessions: Int

    /// Total minutes of timer work this week (excluding paused time)
    let totalMinutes: Int

    /// Total rounds completed this week
    let totalRounds: Int

    /// Average session duration in minutes
    var averageSessionDuration: Int {
        guard completedSessions > 0 else { return 0 }
        return totalMinutes / completedSessions
    }

    /// Completion rate as a percentage (0-100)
    var completionRate: Double {
        guard totalSessions > 0 else { return 0 }
        return Double(completedSessions) / Double(totalSessions) * 100
    }

    /// Formatted completion rate string (e.g., "85%")
    var formattedCompletionRate: String {
        return String(format: "%.0f%%", completionRate)
    }

    /// Formatted total time string (e.g., "4h 30m")
    var formattedTotalTime: String {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(hours)h"
            }
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Preview Support

extension TimerHistoryViewModel {
    /// Create a preview instance with mock data
    static var preview: TimerHistoryViewModel {
        let vm = TimerHistoryViewModel(
            patientId: UUID(),
            timerService: .shared
        )

        // Mock sessions
        vm.sessions = WorkoutTimer.samples

        // Mock templates
        let sampleTemplates = IntervalTemplate.samples
        vm.templates = Dictionary(
            uniqueKeysWithValues: sampleTemplates.map { ($0.id, $0) }
        )

        // Mock stats
        vm.weeklyStats = WeeklyStats(
            totalSessions: 12,
            completedSessions: 10,
            totalMinutes: 240,
            totalRounds: 96
        )

        return vm
    }

    /// Create a preview instance with empty state
    static var emptyPreview: TimerHistoryViewModel {
        return TimerHistoryViewModel(
            patientId: UUID(),
            timerService: .shared
        )
    }
}
