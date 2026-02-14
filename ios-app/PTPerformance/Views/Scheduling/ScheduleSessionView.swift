//
//  ScheduleSessionView.swift
//  PTPerformance
//
//  Created by Build 46 Swarm Agent 1
//  UI to pick date/time and schedule a workout session
//

import SwiftUI

struct ScheduleSessionView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var selectedSession: Session?
    @State private var selectedDate: Date
    @State private var selectedTime = Date()
    @State private var notes = ""
    @State private var reminderEnabled = true

    @State private var availableSessions: [Session] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingConfirmation = false

    init(selectedDate: Date = Date()) {
        _selectedDate = State(initialValue: selectedDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Session selection
                sessionSection

                // Date and time selection
                dateTimeSection

                // Reminder settings
                reminderSection

                // Notes
                notesSection

                // Error message
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Schedule Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Schedule") {
                        scheduleSession()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadAvailableSessions()
            }
            .alert("Session Scheduled", isPresented: $showingConfirmation) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your session has been scheduled for \(formattedScheduledDateTime)")
            }
        }
    }

    // MARK: - Form Sections

    private var sessionSection: some View {
        Section {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if availableSessions.isEmpty {
                Text("No sessions available to schedule")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            } else {
                Picker("Session", selection: $selectedSession) {
                    Text("Select a session").tag(nil as Session?)
                    ForEach(availableSessions) { session in
                        Text(session.name).tag(session as Session?)
                    }
                }
            }
        } header: {
            Text("Workout Session")
        } footer: {
            if let session = selectedSession {
                VStack(alignment: .leading, spacing: 8) {
                    if let notes = session.notes {
                        Text(notes)
                            .font(.caption)
                    }

                    HStack {
                        Label("\(session.exercises.count) exercises", systemImage: "figure.strengthtraining.traditional")
                        Spacer()
                        Label("~\(estimatedDuration(for: session)) min", systemImage: "clock")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
        }
    }

    private var dateTimeSection: some View {
        Section("Date & Time") {
            DatePicker(
                "Date",
                selection: $selectedDate,
                in: Date()...,
                displayedComponents: .date
            )

            DatePicker(
                "Time",
                selection: $selectedTime,
                displayedComponents: .hourAndMinute
            )

            // Suggested times
            VStack(alignment: .leading, spacing: 8) {
                Text("Suggested Times")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    ForEach(suggestedTimes, id: \.self) { time in
                        Button(action: {
                            selectedTime = time
                        }) {
                            Text(formatTime(time))
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(calendar.isDate(selectedTime, equalTo: time, toGranularity: .minute) ? Color.blue : Color(.tertiarySystemGroupedBackground))
                                .foregroundColor(calendar.isDate(selectedTime, equalTo: time, toGranularity: .minute) ? .white : .primary)
                                .cornerRadius(CornerRadius.sm)
                        }
                    }
                }
            }
        }
    }

    private var reminderSection: some View {
        Section {
            Toggle("Send Reminder", isOn: $reminderEnabled)

            if reminderEnabled {
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.orange)
                        .font(.caption)

                    Text("You'll receive a notification 1 hour before the session")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Reminders")
        }
    }

    private var notesSection: some View {
        Section {
            TextField("Add notes (optional)", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        } header: {
            Text("Notes")
        }
    }

    // MARK: - Helper Properties

    private var isFormValid: Bool {
        selectedSession != nil && !isLoading
    }

    private static let mediumDateShortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private static let shortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    private var formattedScheduledDateTime: String {
        Self.mediumDateShortTimeFormatter.string(from: combinedDateTime)
    }

    private var combinedDateTime: Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)

        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute

        return calendar.date(from: combined) ?? selectedDate
    }

    private var suggestedTimes: [Date] {
        let calendar = Calendar.current
        let baseDate = calendar.startOfDay(for: Date())

        return [
            calendar.date(byAdding: .hour, value: 6, to: baseDate),  // 6:00 AM
            calendar.date(byAdding: .hour, value: 9, to: baseDate),  // 9:00 AM
            calendar.date(byAdding: .hour, value: 12, to: baseDate), // 12:00 PM
            calendar.date(byAdding: .hour, value: 17, to: baseDate), // 5:00 PM
            calendar.date(byAdding: .hour, value: 18, to: baseDate) // 6:00 PM
        ].compactMap { $0 }
    }

    private let calendar = Calendar.current

    // MARK: - Helper Methods

    private func formatTime(_ date: Date) -> String {
        Self.shortTimeFormatter.string(from: date)
    }

    private func estimatedDuration(for session: Session) -> Int {
        // Estimate ~3 minutes per exercise
        return session.exercises.count * 3
    }

    // MARK: - Actions

    private func loadAvailableSessions() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                guard let patientId = PTSupabaseClient.shared.userId else {
                    await MainActor.run {
                        errorMessage = "Not logged in"
                        isLoading = false
                    }
                    return
                }
                let sessions = try await SchedulingService.shared.fetchAvailableProgramSessions(for: patientId)
                await MainActor.run {
                    availableSessions = sessions
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load sessions: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }

    private func scheduleSession() {
        guard let session = selectedSession else { return }

        isLoading = true
        errorMessage = nil

        // BUILD 286: Wire to SchedulingService (ACP-595)
        Task {
            do {
                guard let patientId = PTSupabaseClient.shared.userId else {
                    await MainActor.run {
                        errorMessage = "Not logged in"
                        isLoading = false
                    }
                    return
                }
                let _ = try await SchedulingService.shared.scheduleSession(
                    patientId: patientId,
                    sessionId: session.id.uuidString,
                    date: selectedDate,
                    time: selectedTime,
                    notes: notes.isEmpty ? nil : notes
                )
                await MainActor.run {
                    isLoading = false
                    showingConfirmation = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Preview

struct ScheduleSessionView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleSessionView()
    }
}
