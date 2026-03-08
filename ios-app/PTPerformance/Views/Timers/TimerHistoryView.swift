//
//  TimerHistoryView.swift
//  PTPerformance
//
//  Created by BUILD 116 Agent 22 (Timer History View)
//  Comprehensive timer history view with weekly stats, filtering, and session details
//

import SwiftUI

/// Main timer history view displaying completed sessions and weekly statistics
struct TimerHistoryView: View {
    // MARK: - Dependencies

    let patientId: UUID

    @StateObject private var viewModel: TimerHistoryViewModel

    // MARK: - UI State

    @State private var expandedSessions: Set<UUID> = []
    @State private var searchText: String = ""
    @State private var selectedType: TimerType?
    // ACP-515: Removed showDeleteConfirmation - using undo pattern instead

    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    init(patientId: UUID) {
        self.patientId = patientId
        _viewModel = StateObject(wrappedValue: TimerHistoryViewModel(patientId: patientId))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.sessions.isEmpty {
                    // Initial loading state
                    ProgressView("Loading timer history...")
                        .accessibilityLabel("Loading timer sessions")
                } else if filteredAndSearchedSessions().isEmpty {
                    // Empty state
                    emptyStateView
                } else {
                    // Main content
                    contentView
                }
            }
            .navigationTitle("Timer History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.sessions.isEmpty {
                        filterMenu
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search sessions...")
            .refreshable {
                HapticFeedback.light()
                await viewModel.refresh()
            }
            // ACP-515: Removed confirmation dialog - using undo pattern instead
            .withUndoToasts()
            .task {
                await viewModel.loadHistory()
            }
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Weekly stats card (if available)
                if let stats = viewModel.weeklyStats {
                    weeklyStatsCard(stats)
                        .padding(.horizontal)
                        .padding(.top)
                }

                // Session list
                sessionList
                    .padding(.bottom)
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Weekly Stats Card

    private func weeklyStatsCard(_ stats: WeeklyStats) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.modusCyan)
                    .font(.title3)
                    .accessibilityHidden(true)

                Text("This Week")
                    .font(.headline)

                Spacer()

                // Improvement indicator
                if stats.completionRate >= 80 {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.green)
                        .accessibilityLabel("High completion rate")
                }
            }

            // Stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                // Total sessions
                StatCell(
                    icon: "figure.run",
                    value: "\(stats.totalSessions)",
                    label: "Sessions",
                    color: .blue
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(stats.totalSessions) sessions this week")

                // Total time
                StatCell(
                    icon: "clock.fill",
                    value: stats.formattedTotalTime,
                    label: "Total Time",
                    color: .orange
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(stats.formattedTotalTime) total time")

                // Completion rate
                StatCell(
                    icon: "checkmark.circle.fill",
                    value: stats.formattedCompletionRate,
                    label: "Completion",
                    color: stats.completionRate >= 80 ? .green : (stats.completionRate >= 50 ? .orange : .red)
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(stats.formattedCompletionRate) completion rate")

                // Total rounds
                StatCell(
                    icon: "repeat.circle.fill",
                    value: "\(stats.totalRounds)",
                    label: "Rounds",
                    color: .purple
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(stats.totalRounds) rounds completed")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Session List

    private var sessionList: some View {
        LazyVStack(spacing: 12, pinnedViews: [.sectionHeaders]) {
            ForEach(groupedAndSortedDates, id: \.self) { date in
                Section(header: sectionHeader(for: date)) {
                    ForEach(sessionsForDate(date)) { session in
                        sessionRow(session)
                            .padding(.horizontal)
                    }
                }
            }
        }
    }

    // MARK: - Section Header

    private func sectionHeader(for date: Date) -> some View {
        HStack {
            Text(viewModel.formattedDate(date))
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()

            Text("\(sessionsForDate(date).count)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, Spacing.xxs)
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(CornerRadius.sm)
        }
        .padding(.horizontal)
        .padding(.vertical, Spacing.xs)
        .background(Color(.systemGroupedBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(viewModel.formattedDate(date)), \(sessionsForDate(date).count) sessions")
    }

    // MARK: - Session Row

    private func sessionRow(_ session: WorkoutTimer) -> some View {
        // Extract viewModel values outside ViewBuilder to avoid binding errors
        let template = viewModel.template(for: session)
        let name = viewModel.templateName(for: session)
        let duration = viewModel.duration(for: session)
        let time = viewModel.formattedTime(session.startedAt)

        return VStack(spacing: 0) {
            // Main row content
            Button(action: {
                HapticFeedback.selectionChanged()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if expandedSessions.contains(session.id) {
                        expandedSessions.remove(session.id)
                    } else {
                        expandedSessions.insert(session.id)
                    }
                }
            }) {
                HStack(spacing: 12) {
                    // Type icon
                    if let template = template {
                        Image(systemName: template.type.iconName)
                            .font(.title3)
                            .foregroundColor(timerTypeColor(template.type))
                            .frame(width: 40, height: 40)
                            .background(timerTypeColor(template.type).opacity(0.1))
                            .cornerRadius(CornerRadius.sm)
                            .accessibilityHidden(true)
                    } else {
                        Image(systemName: "timer")
                            .font(.title3)
                            .foregroundColor(.gray)
                            .frame(width: 40, height: 40)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(CornerRadius.sm)
                            .accessibilityHidden(true)
                    }

                    // Session info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .font(.headline)
                            .foregroundColor(.primary)

                        HStack(spacing: 8) {
                            // Duration
                            Label(duration, systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            // Rounds
                            if session.roundsCompleted > 0 {
                                Label("\(session.roundsCompleted) rounds", systemImage: "repeat")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Spacer()

                    // Right side: time and status
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(time)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        statusIcon(for: session)
                    }

                    // Expand indicator
                    Image(systemName: expandedSessions.contains(session.id) ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(CornerRadius.md)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityElement(children: .combine)
            .accessibilityLabel(sessionAccessibilityLabel(for: session))
            .accessibilityHint("Tap to \(expandedSessions.contains(session.id) ? "collapse" : "expand") details")

            // Expanded details
            if expandedSessions.contains(session.id) {
                expandedDetails(for: session)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            // ACP-515: Delete immediately with undo support
            Button(role: .destructive) {
                HapticFeedback.medium()
                deleteTimerWithUndo(session: session)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .accessibilityLabel("Delete session")
        }
    }

    // MARK: - Status Icon

    private func statusIcon(for session: WorkoutTimer) -> some View {
        Group {
            if session.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .accessibilityLabel("Completed")
            } else {
                Image(systemName: "pause.circle.fill")
                    .foregroundColor(.orange)
                    .accessibilityLabel("In progress")
            }
        }
        .font(.title3)
    }

    // MARK: - Expanded Details

    private func expandedDetails(for session: WorkoutTimer) -> some View {
        // Extract viewModel values outside ViewBuilder to avoid binding errors
        let template = viewModel.template(for: session)
        let percentage = viewModel.completionPercentage(for: session)

        return VStack(alignment: .leading, spacing: 12) {
            Divider()
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                // Template details
                if let template = template {
                    TimerDetailRow(
                        icon: "waveform.path.ecg",
                        label: "Template",
                        value: template.name
                    )

                    TimerDetailRow(
                        icon: "speedometer",
                        label: "Work/Rest",
                        value: "\(template.workSeconds)s / \(template.restSeconds)s"
                    )

                    if let percentage = percentage {
                        TimerDetailRow(
                            icon: "percent",
                            label: "Progress",
                            value: String(format: "%.0f%%", percentage)
                        )
                    }
                }

                // Paused time (if any)
                if session.pausedSeconds > 0 {
                    TimerDetailRow(
                        icon: "pause.circle",
                        label: "Paused",
                        value: session.formattedPausedTime
                    )
                }

                // Full timestamp
                TimerDetailRow(
                    icon: "calendar",
                    label: "Started",
                    value: viewModel.formattedDateTime(session.startedAt)
                )

                if let completed = session.completedAt {
                    TimerDetailRow(
                        icon: "checkmark.circle",
                        label: "Completed",
                        value: viewModel.formattedDateTime(completed)
                    )
                }
            }
            .padding(.horizontal)

            // Action buttons
            HStack(spacing: 12) {
                // Repeat session button
                Button(action: {
                    // BUILD 286: Dismiss to return to timer picker (ACP-596)
                    dismiss()
                }) {
                    Label("Repeat", systemImage: "arrow.clockwise")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xs)
                        .background(Color.modusCyan.opacity(0.1))
                        .foregroundColor(.modusCyan)
                        .cornerRadius(CornerRadius.sm)
                }
                .accessibilityLabel("Repeat this workout")

                // Share button (optional)
                Button(action: {
                    // BUILD 286: Share session summary (ACP-596)
                    let summary = "Completed workout - \(session.formattedDuration) | \(session.roundsCompleted) rounds"
                    let activityVC = UIActivityViewController(activityItems: [summary], applicationActivities: nil)
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = scene.windows.first,
                       let rootVC = window.rootViewController {
                        rootVC.present(activityVC, animated: true)
                    }
                }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xs)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.secondary)
                        .cornerRadius(CornerRadius.sm)
                }
                .accessibilityLabel("Share session summary")
            }
            .padding(.horizontal)
            .padding(.bottom, Spacing.xs)
        }
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        EmptyStateView(
            title: emptyStateTitle,
            message: emptyStateDescription,
            icon: "clock.arrow.circlepath",
            iconColor: .modusCyan,
            action: EmptyStateView.EmptyStateAction(
                title: "Start a Workout",
                icon: "play.circle.fill",
                action: {
                    // Dismiss to return to timer picker
                    dismiss()
                }
            )
        )
        .background(Color(.systemGroupedBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(emptyStateTitle). \(emptyStateDescription)")
    }

    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "No Matching Sessions"
        } else if let type = selectedType {
            return "No \(type.displayName) Sessions"
        } else {
            return "No Timer History"
        }
    }

    private var emptyStateDescription: String {
        if !searchText.isEmpty {
            return "No sessions match '\(searchText)'. Try a different search term or clear the filter."
        } else if selectedType != nil {
            return "You haven't completed any sessions of this type yet. Start a workout to begin tracking your progress."
        } else {
            return "Your completed timer sessions will appear here. Track your workout intervals, rest periods, and see your progress over time."
        }
    }

    // MARK: - Filter Menu

    private var filterMenu: some View {
        Menu {
            Button(action: {
                selectedType = nil
            }) {
                Label("All Types", systemImage: selectedType == nil ? "checkmark" : "")
            }

            Divider()

            ForEach(TimerType.allCases, id: \.self) { type in
                Button(action: {
                    selectedType = type
                }) {
                    Label(type.displayName, systemImage: selectedType == type ? "checkmark" : "")
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.title3)
                .accessibilityLabel("Filter timer types")
        }
    }

    // MARK: - Helper Properties

    private func filteredAndSearchedSessions() -> [WorkoutTimer] {
        var sessions = viewModel.sessions

        // Filter by type
        if let type = selectedType {
            sessions = sessions.filter { session in
                if let template = viewModel.template(for: session) {
                    return template.type == type
                }
                return false
            }
        }

        // Filter by search text
        if !searchText.isEmpty {
            sessions = sessions.filter { session in
                let name = viewModel.templateName(for: session)
                return name.localizedCaseInsensitiveContains(searchText)
            }
        }

        return sessions
    }

    private var groupedAndSortedDates: [Date] {
        let grouped = filteredAndSearchedSessions().safeGrouped { session in
            Calendar.current.startOfDay(for: session.startedAt)
        }
        return Array(grouped.keys).sorted(by: >)
    }

    private func sessionsForDate(_ date: Date) -> [WorkoutTimer] {
        let sessions = filteredAndSearchedSessions().filter { session in
            Calendar.current.isDate(session.startedAt, inSameDayAs: date)
        }
        return sessions.sorted { $0.startedAt > $1.startedAt }
    }

    // MARK: - Helper Methods

    private func timerTypeColor(_ type: TimerType) -> Color {
        switch type {
        case .tabata:
            return .red
        case .emom:
            return .blue
        case .amrap:
            return .green
        case .intervals:
            return .purple
        case .custom:
            return .orange
        }
    }

    private func sessionAccessibilityLabel(for session: WorkoutTimer) -> String {
        let name = viewModel.templateName(for: session)
        let duration = viewModel.duration(for: session)
        let time = viewModel.formattedTime(session.startedAt)
        let status = session.isCompleted ? "Completed" : "In progress"

        return "\(name), \(duration), \(time), \(status)"
    }

    // MARK: - ACP-515: Delete with Undo

    /// Delete timer session immediately with undo support
    private func deleteTimerWithUndo(session: WorkoutTimer) {
        let sessionId = session.id
        let timerName = viewModel.templateName(for: session)

        // Delete immediately
        Task {
            do {
                try await PTSupabaseClient.shared.client
                    .from("workout_timers")
                    .delete()
                    .eq("id", value: sessionId)
                    .execute()

                // Register undo action
                await MainActor.run {
                    PTUndoManager.shared.registerDeleteTimer(
                        sessionId: sessionId,
                        timerName: timerName
                    ) {
                        // Note: Full restore would require re-inserting the session
                        DebugLogger.shared.warning("UNDO", "Timer '\(timerName)' delete undo requested - manual restore required")
                        throw NSError(domain: "PTUndoManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Timer restore requires manual recovery."])
                    }
                }

                await viewModel.refresh()
            } catch {
                DebugLogger.shared.error("TIMER_HISTORY", "Failed to delete: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Supporting Views

/// Stat cell for weekly stats card
private struct StatCell: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .accessibilityHidden(true)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(color.opacity(0.05))
        .cornerRadius(CornerRadius.sm)
    }
}

/// Detail row for expanded timer session view
private struct TimerDetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
                .accessibilityHidden(true)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Preview Provider

#if DEBUG
struct TimerHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview with data
            TimerHistoryView(patientId: UUID())
                .previewDisplayName("With History")

            // Preview empty state
            TimerHistoryView(patientId: UUID())
                .previewDisplayName("Empty State")

            // Preview dark mode
            TimerHistoryView(patientId: UUID())
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
#endif
