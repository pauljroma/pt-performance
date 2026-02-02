//
//  CalendarSettingsView.swift
//  PTPerformance
//
//  Created for ACP-832: Calendar Integration
//  Settings view for calendar synchronization preferences
//

import SwiftUI
import EventKit

/// Settings view for configuring calendar synchronization.
///
/// Allows users to:
/// - Enable/disable calendar sync
/// - Select target calendar for workouts
/// - Configure sync preferences
/// - Import game schedules from external calendars
struct CalendarSettingsView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @StateObject private var calendarService = CalendarSyncService.shared
    @State private var showingCalendarPicker = false
    @State private var showingGameCalendarPicker = false
    @State private var showingPermissionAlert = false
    @State private var isRequestingAccess = false
    @State private var syncError: CalendarSyncError?
    @State private var showingSyncResult = false
    @State private var availableCalendars: [CalendarInfo] = []

    // MARK: - Body

    var body: some View {
        List {
            // Permission Section
            permissionSection

            // Sync Settings Section
            if calendarService.hasCalendarAccess {
                syncSettingsSection
                targetCalendarSection
                reminderSection
                gameImportSection
                syncStatusSection
            }
        }
        .navigationTitle("Calendar Sync")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCalendarPicker) {
            CalendarPickerView(
                calendars: calendarService.getWritableCalendars(),
                selectedCalendarId: $calendarService.settings.targetCalendarId,
                title: "Select Calendar",
                subtitle: "Choose where to add your workouts"
            )
        }
        .sheet(isPresented: $showingGameCalendarPicker) {
            CalendarPickerView(
                calendars: calendarService.getAvailableCalendars(),
                selectedCalendarIds: $calendarService.settings.importGameCalendarIds,
                title: "Game Calendars",
                subtitle: "Select calendars containing your game schedule",
                allowMultiple: true
            )
        }
        .alert("Calendar Access Required", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                openAppSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To sync your workouts, please enable calendar access in Settings.")
        }
        .alert("Sync Complete", isPresented: $showingSyncResult) {
            Button("OK", role: .cancel) { }
        } message: {
            if let result = calendarService.lastSyncResult {
                Text(result.summary)
            }
        }
        .onAppear {
            loadCalendars()
        }
    }

    // MARK: - Permission Section

    private var permissionSection: some View {
        Section {
            HStack {
                Image(systemName: permissionIcon)
                    .foregroundStyle(permissionColor)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(permissionTitle)
                        .font(.headline)
                    Text(permissionSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !calendarService.hasCalendarAccess {
                    Button(action: requestCalendarAccess) {
                        if isRequestingAccess {
                            ProgressView()
                        } else {
                            Text("Enable")
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isRequestingAccess)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Calendar Access")
        } footer: {
            if !calendarService.hasCalendarAccess {
                Text("Enable calendar access to sync your workouts and import game schedules.")
            }
        }
    }

    private var permissionIcon: String {
        calendarService.hasCalendarAccess ? "checkmark.circle.fill" : "calendar.badge.exclamationmark"
    }

    private var permissionColor: Color {
        calendarService.hasCalendarAccess ? .green : .orange
    }

    private var permissionTitle: String {
        calendarService.hasCalendarAccess ? "Calendar Access Enabled" : "Calendar Access Required"
    }

    private var permissionSubtitle: String {
        calendarService.hasCalendarAccess ? "Your workouts can be synced to your calendar" : "Tap Enable to allow calendar sync"
    }

    // MARK: - Sync Settings Section

    private var syncSettingsSection: some View {
        Section {
            Toggle("Sync Workouts", isOn: $calendarService.settings.syncWorkouts)
            Toggle("Include Rest Days", isOn: $calendarService.settings.syncRestDays)

            Picker("Default Duration", selection: $calendarService.settings.defaultWorkoutDuration) {
                Text("30 minutes").tag(30)
                Text("45 minutes").tag(45)
                Text("60 minutes").tag(60)
                Text("90 minutes").tag(90)
                Text("120 minutes").tag(120)
            }
        } header: {
            Text("Sync Settings")
        } footer: {
            Text("Workouts will be added to your calendar with the selected duration.")
        }
    }

    // MARK: - Target Calendar Section

    private var targetCalendarSection: some View {
        Section {
            Button(action: { showingCalendarPicker = true }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Target Calendar")
                            .foregroundStyle(.primary)
                        Text(targetCalendarName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Calendar")
        } footer: {
            Text("Your workouts will be added to this calendar.")
        }
    }

    private var targetCalendarName: String {
        if let targetId = calendarService.settings.targetCalendarId,
           let calendar = availableCalendars.first(where: { $0.id == targetId }) {
            return calendar.title
        }
        return "PT Performance (Default)"
    }

    // MARK: - Reminder Section

    private var reminderSection: some View {
        Section {
            Toggle("Add Reminder", isOn: Binding(
                get: { calendarService.settings.reminderMinutesBefore != nil },
                set: { calendarService.settings.reminderMinutesBefore = $0 ? 30 : nil }
            ))

            if calendarService.settings.reminderMinutesBefore != nil {
                Picker("Reminder Time", selection: Binding(
                    get: { calendarService.settings.reminderMinutesBefore ?? 30 },
                    set: { calendarService.settings.reminderMinutesBefore = $0 }
                )) {
                    Text("15 minutes before").tag(15)
                    Text("30 minutes before").tag(30)
                    Text("1 hour before").tag(60)
                    Text("2 hours before").tag(120)
                }
            }
        } header: {
            Text("Reminders")
        }
    }

    // MARK: - Game Import Section

    private var gameImportSection: some View {
        Section {
            Button(action: { showingGameCalendarPicker = true }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Import Game Schedule")
                            .foregroundStyle(.primary)
                        Text(gameCalendarsSubtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !calendarService.settings.importGameCalendarIds.isEmpty {
                Toggle("Auto-Adjust Training", isOn: $calendarService.settings.autoAdjustForGames)
            }
        } header: {
            Text("Game Schedule")
        } footer: {
            if calendarService.settings.autoAdjustForGames {
                Text("Training intensity will be automatically adjusted around game days.")
            } else {
                Text("Import your game schedule to see upcoming games alongside your workouts.")
            }
        }
    }

    private var gameCalendarsSubtitle: String {
        let count = calendarService.settings.importGameCalendarIds.count
        if count == 0 {
            return "Select calendars with your games"
        } else if count == 1 {
            return "1 calendar selected"
        } else {
            return "\(count) calendars selected"
        }
    }

    // MARK: - Sync Status Section

    private var syncStatusSection: some View {
        Section {
            if let lastSync = calendarService.settings.lastSyncDate {
                HStack {
                    Text("Last Synced")
                    Spacer()
                    Text(lastSync, style: .relative)
                        .foregroundStyle(.secondary)
                }
            }

            Button(action: performSync) {
                HStack {
                    if calendarService.isSyncing {
                        ProgressView()
                            .padding(.trailing, 8)
                    }
                    Text(calendarService.isSyncing ? "Syncing..." : "Sync Now")
                }
            }
            .disabled(calendarService.isSyncing)

            if let result = calendarService.lastSyncResult, result.hasErrors {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Some events failed to sync")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Status")
        }
    }

    // MARK: - Actions

    private func requestCalendarAccess() {
        isRequestingAccess = true

        Task {
            do {
                _ = try await calendarService.requestAccess()
                loadCalendars()
            } catch {
                showingPermissionAlert = true
            }
            isRequestingAccess = false
        }
    }

    private func loadCalendars() {
        if calendarService.hasCalendarAccess {
            availableCalendars = calendarService.getAvailableCalendars()
        }
    }

    private func performSync() {
        Task {
            // In a real implementation, you would fetch sessions here
            // For now, we just show the sync result
            // do {
            //     let sessions = try await SchedulingService.shared.fetchUpcomingSessions(for: patientId)
            //     _ = try await calendarService.syncSessionsToCalendar(sessions: sessions)
            //     showingSyncResult = true
            // } catch let error as CalendarSyncError {
            //     syncError = error
            // } catch {
            //     syncError = .syncFailed(error)
            // }
            showingSyncResult = true
        }
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CalendarSettingsView()
    }
}
