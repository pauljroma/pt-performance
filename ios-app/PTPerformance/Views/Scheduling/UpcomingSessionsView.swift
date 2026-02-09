//
//  UpcomingSessionsView.swift
//  PTPerformance
//
//  Created by Build 46 Swarm Agent 1
//  List view of upcoming scheduled sessions
//

import SwiftUI

struct UpcomingSessionsView: View {

    @State private var scheduledSessions: [ScheduledSession] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingScheduleSheet = false
    @State private var selectedSession: ScheduledSession?
    @State private var showingSessionDetail = false

    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading && scheduledSessions.isEmpty {
                    ProgressView("Loading sessions...")
                } else if scheduledSessions.isEmpty {
                    emptyState
                } else {
                    sessionsList
                }
            }
            .navigationTitle("Scheduled Sessions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingScheduleSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                await loadScheduledSessions()
            }
            .sheet(isPresented: $showingScheduleSheet) {
                ScheduleSessionView()
            }
            .sheet(item: $selectedSession) { session in
                ScheduledSessionDetailView(session: session)
            }
            .onAppear {
                Task {
                    await loadScheduledSessions()
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            title: "No Scheduled Sessions",
            message: "Schedule your workout sessions in advance to stay on track with your program. Set reminders to keep yourself accountable.",
            icon: "calendar.badge.clock",
            iconColor: .blue,
            action: EmptyStateView.EmptyStateAction(
                title: "Schedule Session",
                icon: "plus.circle.fill",
                action: { showingScheduleSheet = true }
            )
        )
    }

    // MARK: - Sessions List

    private var sessionsList: some View {
        List {
            // Upcoming section
            if !upcomingSessions.isEmpty {
                Section("Upcoming") {
                    ForEach(upcomingSessions) { session in
                        UpcomingSessionRow(session: session)
                            .onTapGesture {
                                selectedSession = session
                                showingSessionDetail = true
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    cancelSession(session)
                                } label: {
                                    Label("Cancel", systemImage: "xmark.circle")
                                }

                                Button {
                                    rescheduleSession(session)
                                } label: {
                                    Label("Reschedule", systemImage: "calendar")
                                }
                                .tint(.orange)
                            }
                            .swipeActions(edge: .leading) {
                                if session.status == .scheduled {
                                    Button {
                                        markAsCompleted(session)
                                    } label: {
                                        Label("Complete", systemImage: "checkmark.circle")
                                    }
                                    .tint(.green)
                                }
                            }
                    }
                }
            }

            // Past due section
            if !pastDueSessions.isEmpty {
                Section("Past Due") {
                    ForEach(pastDueSessions) { session in
                        UpcomingSessionRow(session: session)
                            .onTapGesture {
                                selectedSession = session
                                showingSessionDetail = true
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    markAsCompleted(session)
                                } label: {
                                    Label("Complete", systemImage: "checkmark.circle")
                                }
                                .tint(.green)
                            }
                    }
                }
            }

            // Completed section (last 7 days)
            if !recentlyCompletedSessions.isEmpty {
                Section("Recently Completed") {
                    ForEach(recentlyCompletedSessions) { session in
                        UpcomingSessionRow(session: session)
                            .onTapGesture {
                                selectedSession = session
                                showingSessionDetail = true
                            }
                    }
                }
            }

            // Error message
            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }

    // MARK: - Filtered Sessions

    private var upcomingSessions: [ScheduledSession] {
        scheduledSessions
            .filter { $0.isUpcoming }
            .sorted { $0.scheduledDateTime < $1.scheduledDateTime }
    }

    private var pastDueSessions: [ScheduledSession] {
        scheduledSessions
            .filter { $0.isPastDue }
            .sorted { $0.scheduledDateTime < $1.scheduledDateTime }
    }

    private var recentlyCompletedSessions: [ScheduledSession] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        return scheduledSessions
            .filter { session in
                session.status == .completed &&
                session.scheduledDate >= sevenDaysAgo
            }
            .sorted { $0.scheduledDateTime > $1.scheduledDateTime }
    }

    // MARK: - Actions

    private func loadScheduledSessions() async {
        isLoading = true
        errorMessage = nil

        // BUILD 286: Wire to SchedulingService (ACP-595)
        do {
            guard let patientId = PTSupabaseClient.shared.userId else {
                errorMessage = "Not logged in"
                isLoading = false
                return
            }
            scheduledSessions = try await SchedulingService.shared.fetchUpcomingSessions(for: patientId)
        } catch {
            errorMessage = "Failed to load sessions: \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func cancelSession(_ session: ScheduledSession) {
        // BUILD 286: Wire to SchedulingService (ACP-595)
        Task {
            do {
                try await SchedulingService.shared.cancelSession(scheduledSessionId: session.id)
                if let index = scheduledSessions.firstIndex(where: { $0.id == session.id }) {
                    scheduledSessions.remove(at: index)
                }
            } catch {
                errorMessage = "Failed to cancel: \(error.localizedDescription)"
            }
        }
    }

    private func rescheduleSession(_ session: ScheduledSession) {
        selectedSession = session
        showingScheduleSheet = true
    }

    private func markAsCompleted(_ session: ScheduledSession) {
        // BUILD 286: Wire to SchedulingService (ACP-595)
        Task {
            do {
                let updated = try await SchedulingService.shared.completeSession(scheduledSessionId: session.id)
                if let index = scheduledSessions.firstIndex(where: { $0.id == session.id }) {
                    scheduledSessions[index] = updated
                }
            } catch {
                errorMessage = "Failed to complete: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Upcoming Session Row

struct UpcomingSessionRow: View {
    let session: ScheduledSession

    var body: some View {
        HStack(spacing: 12) {
            // Date badge
            VStack(spacing: 2) {
                Text(monthAbbreviation)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Text(dayNumber)
                    .font(.title3)
                    .fontWeight(.bold)

                Text(weekday)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 50)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(8)

            // Session details
            VStack(alignment: .leading, spacing: 4) {
                Text(session.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(session.relativeTimeString)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let notes = session.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Status badge
            VStack(alignment: .trailing, spacing: 4) {
                statusBadge

                if session.isPastDue && session.status == .scheduled {
                    Text("Past due")
                        .font(.caption2)
                        .foregroundColor(.red)
                }

                if session.reminderSent {
                    Image(systemName: "bell.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var statusBadge: some View {
        Text(session.status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.15))
            .cornerRadius(6)
    }

    private var statusColor: Color {
        switch session.status {
        case .scheduled:
            return session.isPastDue ? .orange : .blue
        case .completed:
            return .green
        case .cancelled:
            return .red
        case .rescheduled:
            return .orange
        }
    }

    private var monthAbbreviation: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: session.scheduledDate).uppercased()
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: session.scheduledDate)
    }

    private var weekday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: session.scheduledDate).uppercased()
    }
}

// MARK: - Scheduled Session Detail View (Placeholder)

struct ScheduledSessionDetailView: View {
    let session: ScheduledSession

    var body: some View {
        NavigationStack {
            List {
                Section("Details") {
                    LabeledContent("Session", value: session.sessionId.uuidString)
                    LabeledContent("Date", value: session.formattedDate)
                    LabeledContent("Time", value: session.formattedTime)
                    LabeledContent("Status", value: session.status.displayName)
                }

                if let notes = session.notes {
                    Section("Notes") {
                        Text(notes)
                    }
                }

                if let completedAt = session.completedAt {
                    Section("Completion") {
                        LabeledContent("Completed", value: completedAt.formatted())
                    }
                }
            }
            .navigationTitle("Session Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct UpcomingSessionsView_Previews: PreviewProvider {
    static var previews: some View {
        UpcomingSessionsView()
    }
}
