//
//  CalendarPickerView.swift
//  PTPerformance
//
//  Created for ACP-832: Calendar Integration
//  View for selecting calendars to sync from/to
//

import SwiftUI
import EventKit

/// View for selecting one or more calendars.
///
/// Supports both single selection (for target calendar) and
/// multiple selection (for importing game schedules).
struct CalendarPickerView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    let calendars: [CalendarInfo]
    let title: String
    let subtitle: String
    let allowMultiple: Bool

    // Single selection binding
    @Binding var selectedCalendarId: String?

    // Multiple selection binding
    @Binding var selectedCalendarIds: [String]

    // MARK: - State

    @State private var searchText = ""

    // MARK: - Initializers

    /// Initialize for single calendar selection.
    init(
        calendars: [CalendarInfo],
        selectedCalendarId: Binding<String?>,
        title: String = "Select Calendar",
        subtitle: String = ""
    ) {
        self.calendars = calendars
        self._selectedCalendarId = selectedCalendarId
        self._selectedCalendarIds = .constant([])
        self.title = title
        self.subtitle = subtitle
        self.allowMultiple = false
    }

    /// Initialize for multiple calendar selection.
    init(
        calendars: [CalendarInfo],
        selectedCalendarIds: Binding<[String]>,
        title: String = "Select Calendars",
        subtitle: String = "",
        allowMultiple: Bool = true
    ) {
        self.calendars = calendars
        self._selectedCalendarId = .constant(nil)
        self._selectedCalendarIds = selectedCalendarIds
        self.title = title
        self.subtitle = subtitle
        self.allowMultiple = allowMultiple
    }

    // MARK: - Computed Properties

    private var filteredCalendars: [CalendarInfo] {
        if searchText.isEmpty {
            return calendars
        }
        return calendars.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.source.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedCalendars: [String: [CalendarInfo]] {
        Dictionary(grouping: filteredCalendars) { $0.source }
    }

    private var sortedSources: [String] {
        groupedCalendars.keys.sorted()
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                if !subtitle.isEmpty {
                    Section {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if allowMultiple {
                    multipleSelectionContent
                } else {
                    singleSelectionContent
                }
            }
            .searchable(text: $searchText, prompt: "Search calendars")
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                if allowMultiple && !selectedCalendarIds.isEmpty {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Clear") {
                            selectedCalendarIds = []
                        }
                    }
                }
            }
        }
    }

    // MARK: - Single Selection Content

    private var singleSelectionContent: some View {
        ForEach(sortedSources, id: \.self) { source in
            Section(source) {
                ForEach(groupedCalendars[source] ?? []) { calendar in
                    singleSelectionRow(calendar: calendar)
                }
            }
        }
    }

    private func singleSelectionRow(calendar: CalendarInfo) -> some View {
        Button(action: {
            selectedCalendarId = calendar.id
            dismiss()
        }) {
            HStack {
                calendarIcon(for: calendar)

                VStack(alignment: .leading, spacing: 2) {
                    Text(calendar.title)
                        .foregroundStyle(.primary)

                    if !calendar.isWritable {
                        Text("Read Only")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if selectedCalendarId == calendar.id {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                        .fontWeight(.semibold)
                }
            }
        }
        .disabled(!calendar.isWritable && !allowMultiple)
    }

    // MARK: - Multiple Selection Content

    private var multipleSelectionContent: some View {
        ForEach(sortedSources, id: \.self) { source in
            Section(source) {
                ForEach(groupedCalendars[source] ?? []) { calendar in
                    multipleSelectionRow(calendar: calendar)
                }
            }
        }
    }

    private func multipleSelectionRow(calendar: CalendarInfo) -> some View {
        Button(action: {
            toggleCalendarSelection(calendar.id)
        }) {
            HStack {
                calendarIcon(for: calendar)

                Text(calendar.title)
                    .foregroundStyle(.primary)

                Spacer()

                if selectedCalendarIds.contains(calendar.id) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Helper Views

    private func calendarIcon(for calendar: CalendarInfo) -> some View {
        Circle()
            .fill(Color(cgColor: calendar.color))
            .frame(width: 12, height: 12)
            .padding(.trailing, 8)
    }

    // MARK: - Actions

    private func toggleCalendarSelection(_ calendarId: String) {
        if let index = selectedCalendarIds.firstIndex(of: calendarId) {
            selectedCalendarIds.remove(at: index)
        } else {
            selectedCalendarIds.append(calendarId)
        }
    }
}

// MARK: - Calendar Row View

/// Individual calendar row for display in lists.
struct CalendarRowView: View {
    let calendar: CalendarInfo
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Circle()
                    .fill(Color(cgColor: calendar.color))
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(calendar.title)
                        .foregroundStyle(.primary)

                    Text(calendar.source)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                        .fontWeight(.semibold)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Calendar Badge View

/// Small badge showing calendar color and name.
struct CalendarBadgeView: View {
    let calendar: CalendarInfo

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color(cgColor: calendar.color))
                .frame(width: 8, height: 8)

            Text(calendar.title)
                .font(.caption)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.secondary.opacity(0.15))
        )
    }
}

// MARK: - Previews

#Preview("Single Selection") {
    CalendarPickerView(
        calendars: [
            CalendarInfo(from: EKCalendar(for: .event, eventStore: EKEventStore()))
        ],
        selectedCalendarId: .constant(nil),
        title: "Select Calendar",
        subtitle: "Choose where to add your workouts"
    )
}

#Preview("Multiple Selection") {
    CalendarPickerView(
        calendars: [],
        selectedCalendarIds: .constant([]),
        title: "Game Calendars",
        subtitle: "Select calendars containing your game schedule",
        allowMultiple: true
    )
}
