//
//  CalendarView.swift
//  PTPerformance
//
//  Created by Build 46 Swarm Agent 1
//  Weekly/monthly calendar view for scheduled sessions
//

import SwiftUI

struct CalendarView: View {

    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var viewMode: CalendarViewMode = .month
    @State private var scheduledSessions: [ScheduledSession] = []
    @State private var isLoading = false
    @State private var showScheduleSheet = false

    let onDateSelected: ((Date) -> Void)?

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    init(onDateSelected: ((Date) -> Void)? = nil) {
        self.onDateSelected = onDateSelected
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with month/year and navigation
            calendarHeader

            // View mode toggle
            viewModeToggle

            // Calendar grid
            if viewMode == .month {
                monthView
            } else {
                weekView
            }

            // Session details for selected date
            if !sessionsForSelectedDate.isEmpty {
                sessionsList
            }
        }
        .onAppear {
            loadScheduledSessions()
        }
        .sheet(isPresented: $showScheduleSheet) {
            ScheduleSessionView(selectedDate: selectedDate)
        }
    }

    // MARK: - Header

    private var calendarHeader: some View {
        HStack {
            Button(action: {
                HapticFeedback.light()
                previousPeriod()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            .accessibilityLabel("Previous \(viewMode == .month ? "month" : "week")")

            Spacer()

            VStack(spacing: 4) {
                Text(monthYearString)
                    .font(.headline)

                if viewMode == .week {
                    Text(weekRangeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: {
                HapticFeedback.light()
                nextPeriod()
            }) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            .accessibilityLabel("Next \(viewMode == .month ? "month" : "week")")
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var viewModeToggle: some View {
        Picker("View Mode", selection: $viewMode) {
            Text("Week").tag(CalendarViewMode.week)
            Text("Month").tag(CalendarViewMode.month)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: - Month View

    private var monthView: some View {
        VStack(spacing: 0) {
            // Day headers (Sun, Mon, Tue, etc.)
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }

            Divider()

            // Calendar dates
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(monthDates, id: \.self) { date in
                    if let date = date {
                        CalendarDateCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month),
                            sessions: sessionsForDate(date)
                        )
                        .onTapGesture {
                            selectedDate = date
                            onDateSelected?(date)
                        }
                    } else {
                        Color.clear
                            .frame(height: 60)
                    }
                }
            }
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Week View

    private var weekView: some View {
        VStack(spacing: 0) {
            // Day headers
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }

            Divider()

            // Current week dates
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(currentWeekDates, id: \.self) { date in
                    CalendarDateCell(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date),
                        isCurrentMonth: true,
                        sessions: sessionsForDate(date)
                    )
                    .onTapGesture {
                        selectedDate = date
                        onDateSelected?(date)
                    }
                }
            }
            .frame(height: 80)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Sessions List

    private var sessionsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Scheduled Sessions")
                    .font(.headline)

                Spacer()

                Button(action: { showScheduleSheet = true }) {
                    Label("Schedule", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                }
            }
            .padding(.horizontal)
            .padding(.top)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(sessionsForSelectedDate) { session in
                        ScheduledSessionRow(session: session)
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(maxHeight: 300)
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Helper Properties

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    private var weekRangeString: String {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentMonth) else {
            return ""
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        let start = formatter.string(from: weekInterval.start)
        let end = formatter.string(from: weekInterval.end)

        return "\(start) - \(end)"
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.shortWeekdaySymbols
        // Reorder to start with Sunday
        return Array(symbols.suffix(1) + symbols.prefix(6))
    }

    private var monthDates: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        var dates: [Date?] = []
        var currentDate = monthFirstWeek.start

        // Generate 6 weeks of dates (42 days)
        for _ in 0..<42 {
            dates.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        return dates
    }

    private var currentWeekDates: [Date] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentMonth) else {
            return []
        }

        var dates: [Date] = []
        var currentDate = weekInterval.start

        for _ in 0..<7 {
            dates.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        return dates
    }

    private var sessionsForSelectedDate: [ScheduledSession] {
        sessionsForDate(selectedDate)
    }

    private func sessionsForDate(_ date: Date) -> [ScheduledSession] {
        scheduledSessions.filter { session in
            calendar.isDate(session.scheduledDate, inSameDayAs: date)
        }
    }

    // MARK: - Actions

    private func previousPeriod() {
        if viewMode == .month {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        } else {
            currentMonth = calendar.date(byAdding: .weekOfYear, value: -1, to: currentMonth) ?? currentMonth
        }
    }

    private func nextPeriod() {
        if viewMode == .month {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        } else {
            currentMonth = calendar.date(byAdding: .weekOfYear, value: 1, to: currentMonth) ?? currentMonth
        }
    }

    private func loadScheduledSessions() {
        // BUILD 286: Wire to SchedulingService (ACP-595)
        isLoading = true

        Task {
            do {
                guard let patientId = PTSupabaseClient.shared.userId else {
                    await MainActor.run { isLoading = false }
                    return
                }
                let sessions = try await SchedulingService.shared.fetchScheduledSessions(for: patientId)
                await MainActor.run {
                    scheduledSessions = sessions
                    isLoading = false
                }
            } catch {
                await MainActor.run { isLoading = false }
            }
        }
    }
}

// MARK: - Calendar Date Cell

struct CalendarDateCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let sessions: [ScheduledSession]

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(dayNumber)
                .font(.system(size: 16, weight: isToday ? .bold : .regular))
                .foregroundColor(textColor)
                .frame(width: 32, height: 32)
                .background(backgroundColor)
                .clipShape(Circle())

            // Session indicators
            if !sessions.isEmpty {
                HStack(spacing: 2) {
                    ForEach(sessions.prefix(3)) { session in
                        Circle()
                            .fill(statusColor(for: session.status))
                            .frame(width: 4, height: 4)
                    }

                    if sessions.count > 3 {
                        Text("+\(sessions.count - 3)")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .contentShape(Rectangle())
    }

    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return .blue
        } else if !isCurrentMonth {
            return .secondary
        } else {
            return .primary
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return .blue
        } else if isToday {
            return .blue.opacity(0.2)
        } else {
            return .clear
        }
    }

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
}

// MARK: - Scheduled Session Row

struct ScheduledSessionRow: View {
    let session: ScheduledSession

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(session.formattedTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(session.status.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(statusColor)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, Spacing.xxs)
                .background(statusColor.opacity(0.1))
                .cornerRadius(CornerRadius.sm)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(session.displayName), \(session.formattedTime), \(session.status.displayName)")
    }

    private var statusColor: Color {
        switch session.status {
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
}

// MARK: - Supporting Types

enum CalendarViewMode {
    case week
    case month
}

// MARK: - Preview

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView { date in
            print("Selected date: \(date)")
        }
    }
}
