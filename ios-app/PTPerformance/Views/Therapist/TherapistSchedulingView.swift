//
//  TherapistSchedulingView.swift
//  PTPerformance
//
//  Created by Build 291 Swarm Agent 1
//  Therapist-facing scheduling management view across entire caseload
//

import SwiftUI

// MARK: - View Model

@MainActor
final class TherapistSchedulingViewModel: ObservableObject {

    // MARK: - Published State

    @Published var sessions: [TherapistSessionItem] = []
    @Published var patients: [Patient] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedFilter: StatusFilter = .all
    @Published var showCancelConfirmation = false
    @Published var sessionToCancel: TherapistSessionItem?

    // MARK: - Dependencies

    private let schedulingService = SchedulingService.shared
    private let supabase = PTSupabaseClient.shared
    private let errorLogger = ErrorLogger.shared

    // MARK: - Filter Enum

    enum StatusFilter: String, CaseIterable {
        case all = "All"
        case upcoming = "Upcoming"
        case completed = "Completed"
        case cancelled = "Cancelled"
    }

    // MARK: - Computed Properties

    var filteredSessions: [TherapistSessionItem] {
        switch selectedFilter {
        case .all:
            return sessions
        case .upcoming:
            return sessions.filter { $0.session.status == .scheduled || $0.session.status == .rescheduled }
        case .completed:
            return sessions.filter { $0.session.status == .completed }
        case .cancelled:
            return sessions.filter { $0.session.status == .cancelled }
        }
    }

    var groupedSessions: [DateGroup: [TherapistSessionItem]] {
        let calendar = Calendar.current
        var groups: [DateGroup: [TherapistSessionItem]] = [:]

        for item in filteredSessions {
            let group: DateGroup
            let date = item.session.scheduledDate

            if calendar.isDateInToday(date) {
                group = .today
            } else if calendar.isDateInTomorrow(date) {
                group = .tomorrow
            } else if let daysUntil = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: date)).day,
                      daysUntil >= 0 && daysUntil <= 7 {
                group = .thisWeek
            } else {
                group = .later
            }

            groups[group, default: []].append(item)
        }

        return groups
    }

    var sortedDateGroups: [DateGroup] {
        DateGroup.allCases.filter { groupedSessions[$0] != nil }
    }

    // MARK: - Data Loading

    func loadAllSessions(therapistId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch all patients for this therapist
            let response = try await supabase.client
                .from("patients")
                .select()
                .eq("therapist_id", value: therapistId)
                .execute()

            let decoder = PTSupabaseClient.flexibleDecoder
            let fetchedPatients = try decoder.decode([Patient].self, from: response.data)

            patients = fetchedPatients

            // Fetch sessions for each patient and combine
            var allItems: [TherapistSessionItem] = []

            for patient in fetchedPatients {
                do {
                    let patientSessions = try await schedulingService.fetchScheduledSessions(
                        for: patient.id.uuidString
                    )
                    let items = patientSessions.map { session in
                        TherapistSessionItem(session: session, patient: patient)
                    }
                    allItems.append(contentsOf: items)
                } catch {
                    // Log but continue loading other patients
                    errorLogger.logError(error, context: "loadSessions(patient=\(patient.id.uuidString))")
                }
            }

            // Sort by scheduled date/time ascending
            sessions = allItems.sorted { $0.session.scheduledDateTime < $1.session.scheduledDateTime }
        } catch {
            errorLogger.logError(error, context: "loadAllSessions(therapist=\(therapistId))")
            errorMessage = "Failed to load schedule. Please try again."
        }

        isLoading = false
    }

    func refresh(therapistId: String) async {
        await loadAllSessions(therapistId: therapistId)
    }

    // MARK: - Actions

    func completeSession(_ item: TherapistSessionItem) async {
        do {
            let updated = try await schedulingService.completeSession(
                scheduledSessionId: item.session.id.uuidString
            )

            // Update the local list
            if let index = sessions.firstIndex(where: { $0.session.id == item.session.id }) {
                sessions[index] = TherapistSessionItem(session: updated, patient: item.patient)
            }
        } catch {
            errorLogger.logError(error, context: "completeSession(id=\(item.session.id.uuidString))")
            errorMessage = "Failed to mark session as completed."
        }
    }

    func cancelSession(_ item: TherapistSessionItem) async {
        do {
            try await schedulingService.cancelSession(
                scheduledSessionId: item.session.id.uuidString
            )

            // Update local state to reflect cancellation
            if let index = sessions.firstIndex(where: { $0.session.id == item.session.id }) {
                // Re-fetch this single patient's sessions to get the updated record
                let updatedSessions = try await schedulingService.fetchScheduledSessions(
                    for: item.patient.id.uuidString
                )
                if let updatedSession = updatedSessions.first(where: { $0.id == item.session.id }) {
                    sessions[index] = TherapistSessionItem(session: updatedSession, patient: item.patient)
                }
            }
        } catch {
            errorLogger.logError(error, context: "cancelSession(id=\(item.session.id.uuidString))")
            errorMessage = "Failed to cancel session."
        }
    }
}

// MARK: - Supporting Types

struct TherapistSessionItem: Identifiable, Hashable {
    let session: ScheduledSession
    let patient: Patient

    var id: UUID { session.id }

    func hash(into hasher: inout Hasher) {
        hasher.combine(session.id)
    }

    static func == (lhs: TherapistSessionItem, rhs: TherapistSessionItem) -> Bool {
        lhs.session.id == rhs.session.id
    }
}

enum DateGroup: String, CaseIterable, Hashable {
    case today = "Today"
    case tomorrow = "Tomorrow"
    case thisWeek = "This Week"
    case later = "Later"
}

// MARK: - Main View

struct TherapistSchedulingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = TherapistSchedulingViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.sessions.isEmpty {
                    loadingView
                } else if let error = viewModel.errorMessage, viewModel.sessions.isEmpty {
                    errorView(message: error)
                } else {
                    scheduleContent
                }
            }
            .navigationTitle("Schedule")
            .alert("Cancel Session", isPresented: $viewModel.showCancelConfirmation) {
                Button("Cancel Session", role: .destructive) {
                    if let item = viewModel.sessionToCancel {
                        Task {
                            await viewModel.cancelSession(item)
                        }
                    }
                }
                Button("Keep", role: .cancel) {
                    viewModel.sessionToCancel = nil
                }
            } message: {
                if let item = viewModel.sessionToCancel {
                    Text("Are you sure you want to cancel \(item.patient.fullName)'s session on \(item.session.formattedDate)?")
                }
            }
            .task {
                guard let therapistId = appState.userId else {
                    // SECURITY: Do NOT load sessions without therapist ID
                    viewModel.errorMessage = "Unable to identify therapist. Please sign in again."
                    ErrorLogger.shared.logError(
                        NSError(domain: "TherapistSchedulingView", code: 401, userInfo: [
                            NSLocalizedDescriptionKey: "No therapist ID available"
                        ]),
                        context: "TherapistSchedulingView.task - missing therapistId"
                    )
                    return
                }
                await viewModel.loadAllSessions(therapistId: therapistId)
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading schedule...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        ErrorStateView(
            title: "Unable to Load",
            message: message,
            icon: "exclamationmark.triangle.fill",
            iconColor: .orange,
            primaryAction: ErrorAction(
                title: "Try Again",
                icon: "arrow.clockwise",
                action: {
                    Task {
                        if let therapistId = appState.userId {
                            await viewModel.loadAllSessions(therapistId: therapistId)
                        }
                    }
                }
            )
        )
    }

    // MARK: - Schedule Content

    private var scheduleContent: some View {
        VStack(spacing: 0) {
            // Filter bar
            filterBar
                .padding(.horizontal)
                .padding(.vertical, Spacing.xs)

            // Session list
            if viewModel.filteredSessions.isEmpty {
                emptyStateView
            } else {
                sessionList
            }
        }
        .refreshable {
            if let therapistId = appState.userId {
                await viewModel.refresh(therapistId: therapistId)
            } else {
                // SECURITY: Do NOT refresh without therapist ID
                viewModel.errorMessage = "Unable to identify therapist. Please sign in again."
            }
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        Picker("Filter", selection: $viewModel.selectedFilter) {
            ForEach(TherapistSchedulingViewModel.StatusFilter.allCases, id: \.self) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        let (title, message) = emptyStateContent
        return EmptyStateView(
            title: title,
            message: message,
            icon: "calendar.badge.clock",
            iconColor: .orange,
            action: nil
        )
    }

    private var emptyStateContent: (title: String, message: String) {
        switch viewModel.selectedFilter {
        case .all:
            return (
                "No Sessions Found",
                "No scheduled sessions found across your caseload. Sessions will appear here when patients schedule appointments."
            )
        case .upcoming:
            return (
                "No Upcoming Sessions",
                "All sessions have been completed or cancelled. Check back when new sessions are scheduled."
            )
        case .completed:
            return (
                "No Completed Sessions",
                "Completed sessions will appear here after patients finish their scheduled appointments."
            )
        case .cancelled:
            return (
                "No Cancelled Sessions",
                "No sessions have been cancelled. This is a good sign for patient engagement."
            )
        }
    }

    // MARK: - Session List

    private var sessionList: some View {
        List {
            ForEach(viewModel.sortedDateGroups, id: \.self) { group in
                Section {
                    if let items = viewModel.groupedSessions[group] {
                        ForEach(items) { item in
                            sessionRow(item: item)
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    if item.session.status == .scheduled || item.session.status == .rescheduled {
                                        Button {
                                            Task {
                                                await viewModel.completeSession(item)
                                            }
                                        } label: {
                                            Label("Complete", systemImage: "checkmark.circle.fill")
                                        }
                                        .tint(.green)
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    if item.session.status == .scheduled || item.session.status == .rescheduled {
                                        Button(role: .destructive) {
                                            viewModel.sessionToCancel = item
                                            viewModel.showCancelConfirmation = true
                                        } label: {
                                            Label("Cancel", systemImage: "xmark.circle.fill")
                                        }
                                        .tint(.red)
                                    }
                                }
                        }
                    }
                } header: {
                    Text(group.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Session Row

    private func sessionRow(item: TherapistSessionItem) -> some View {
        HStack(spacing: 12) {
            // Patient avatar
            Circle()
                .fill(avatarColor(for: item.patient).gradient)
                .frame(width: 44, height: 44)
                .overlay(
                    Text(item.patient.initials)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                )

            // Session details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.patient.fullName)
                    .font(.headline)

                Text(item.session.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(item.session.relativeTimeString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status badge
            statusBadge(for: item.session.status)
        }
        .padding(.vertical, Spacing.xxs)
    }

    // MARK: - Status Badge

    private func statusBadge(for status: ScheduledSession.ScheduleStatus) -> some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background(statusColor(for: status).opacity(0.15))
            .foregroundColor(statusColor(for: status))
            .clipShape(Capsule())
    }

    // MARK: - Helpers

    private func statusColor(for status: ScheduledSession.ScheduleStatus) -> Color {
        switch status {
        case .scheduled:
            return .blue
        case .completed:
            return .green
        case .cancelled:
            return .red
        case .rescheduled:
            return .orange
        }
    }

    private func avatarColor(for patient: Patient) -> Color {
        let colors: [Color] = [.modusCyan, .purple, .green, .orange, .pink, .indigo]
        let index = abs(patient.id.hashValue) % colors.count
        return colors[index]
    }
}

// MARK: - Preview

#if DEBUG
struct TherapistSchedulingView_Previews: PreviewProvider {
    static var previews: some View {
        TherapistSchedulingView()
            .environmentObject(AppState())
    }
}
#endif
