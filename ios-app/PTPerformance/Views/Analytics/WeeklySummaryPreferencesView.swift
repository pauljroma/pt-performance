//
//  WeeklySummaryPreferencesView.swift
//  PTPerformance
//
//  Created by BUILD ACP-843 - Weekly Progress Summary Feature
//  Settings view for weekly notification preferences
//

import SwiftUI

/// Settings view for configuring weekly summary notifications
struct WeeklySummaryPreferencesView: View {
    // MARK: - Properties

    let patientId: UUID

    // MARK: - State

    @State private var notificationEnabled: Bool = true
    @State private var selectedDay: WeeklySummaryPreferences.NotificationDay = .sunday
    @State private var selectedHour: Int = 19
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var showSavedAlert = false
    @State private var error: Error?

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        Form {
            // Enable/Disable Section
            Section {
                Toggle("Enable Weekly Summary", isOn: $notificationEnabled)
                    .tint(.blue)
            } footer: {
                Text("Receive a push notification with your weekly workout recap")
            }

            // Schedule Section
            if notificationEnabled {
                Section("Notification Schedule") {
                    // Day picker
                    Picker("Day", selection: $selectedDay) {
                        ForEach(WeeklySummaryPreferences.NotificationDay.allCases, id: \.self) { day in
                            Text(day.displayName).tag(day)
                        }
                    }

                    // Hour picker
                    Picker("Time", selection: $selectedHour) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                }
            }

            // Preview Section
            if notificationEnabled {
                Section("Notification Preview") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "app.badge.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 32))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Modus")
                                    .font(.caption.bold())
                                    .foregroundColor(.secondary)

                                Text("Your Week in Review")
                                    .font(.subheadline.bold())

                                Text("5/5 workouts | 12-day streak | Volume up 8%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }

            // Save Button
            Section {
                Button(action: savePreferences) {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Save Preferences")
                                .font(.headline)
                        }
                        Spacer()
                    }
                }
                .listRowBackground(Color.blue)
                .foregroundColor(.white)
                .disabled(isSaving)
            }
        }
        .navigationTitle("Notification Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Preferences Saved", isPresented: $showSavedAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your weekly summary will be sent \(selectedDay.displayName.lowercased()) at \(formatHour(selectedHour)).")
        }
        .alert("Error", isPresented: .constant(error != nil)) {
            Button("OK") {
                error = nil
            }
        } message: {
            if let error = error {
                Text(error.localizedDescription)
            }
        }
        .task {
            await loadPreferences()
        }
        .overlay {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
            }
        }
    }

    // MARK: - Helper Methods

    private func formatHour(_ hour: Int) -> String {
        let hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        let amPm = hour >= 12 ? "PM" : "AM"
        return "\(hour12):00 \(amPm)"
    }

    private func loadPreferences() async {
        isLoading = true

        do {
            let prefs = try await WeeklySummaryService.shared.fetchPreferences(for: patientId)
            await MainActor.run {
                notificationEnabled = prefs.notificationEnabled
                selectedDay = prefs.notificationDay
                selectedHour = prefs.notificationHour
            }
        } catch {
            await MainActor.run {
                self.error = error
            }
        }

        await MainActor.run {
            isLoading = false
        }
    }

    private func savePreferences() {
        Task {
            await MainActor.run {
                isSaving = true
            }

            let prefs = WeeklySummaryPreferences(
                id: nil,
                patientId: patientId,
                notificationEnabled: notificationEnabled,
                notificationDay: selectedDay,
                notificationHour: selectedHour
            )

            do {
                try await WeeklySummaryService.shared.updatePreferences(prefs)
                await MainActor.run {
                    isSaving = false
                    showSavedAlert = true
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    self.error = error
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WeeklySummaryPreferencesView(patientId: UUID())
    }
}
