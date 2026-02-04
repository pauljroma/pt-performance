import SwiftUI

/// ACP-903: Recovery History View
/// Calendar view of recovery history with filtering and statistics
struct RecoveryHistoryView: View {
    @StateObject private var viewModel = RecoveryHistoryViewModel()
    @State private var selectedDate: Date = Date()
    @State private var selectedFilter: RecoveryProtocolType?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Stats Overview
                statsOverview

                // Calendar View
                calendarSection

                // Filter Pills
                filterSection

                // Sessions List
                sessionsListSection
            }
            .padding()
        }
        .navigationTitle("Recovery History")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadHistory()
        }
        .refreshable {
            await viewModel.loadHistory()
        }
    }

    // MARK: - Stats Overview

    private var statsOverview: some View {
        VStack(spacing: Spacing.md) {
            // Period selector
            Picker("Period", selection: $viewModel.selectedPeriod) {
                Text("Week").tag(StatsPeriod.week)
                Text("Month").tag(StatsPeriod.month)
                Text("Year").tag(StatsPeriod.year)
            }
            .pickerStyle(.segmented)

            // Stats cards
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.sm) {
                StatCard(
                    title: "Sessions",
                    value: "\(viewModel.periodStats.totalSessions)",
                    subtitle: viewModel.sessionsTrend,
                    icon: "figure.mind.and.body",
                    color: .modusCyan
                )

                StatCard(
                    title: "Total Time",
                    value: viewModel.formattedTotalTime,
                    subtitle: viewModel.timeTrend,
                    icon: "clock.fill",
                    color: .modusTealAccent
                )

                StatCard(
                    title: "Avg/Session",
                    value: "\(viewModel.periodStats.averageMinutes) min",
                    subtitle: "per session",
                    icon: "chart.bar.fill",
                    color: .modusDeepTeal
                )

                StatCard(
                    title: "Best Streak",
                    value: "\(viewModel.periodStats.longestStreak) days",
                    subtitle: viewModel.streakStatus,
                    icon: "flame.fill",
                    color: .orange
                )
            }
        }
    }

    // MARK: - Calendar Section

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Month navigation
            HStack {
                Button {
                    viewModel.previousMonth()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.modusCyan)
                }
                .accessibilityLabel("Previous month")

                Spacer()

                Text(viewModel.currentMonthString)
                    .font(.headline)

                Spacer()

                Button {
                    viewModel.nextMonth()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.modusCyan)
                }
                .accessibilityLabel("Next month")
            }

            // Weekday headers
            HStack(spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: Spacing.xs) {
                ForEach(viewModel.calendarDays, id: \.self) { date in
                    if let date = date {
                        CalendarDayCell(
                            date: date,
                            sessions: viewModel.sessionsForDate(date),
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            isToday: Calendar.current.isDateInToday(date)
                        ) {
                            withAnimation(.easeInOut(duration: AnimationDuration.quick)) {
                                selectedDate = date
                            }
                            HapticFeedback.selectionChanged()
                        }
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }

            // Legend
            HStack(spacing: Spacing.lg) {
                LegendItem(color: .orange, label: "Heat")
                LegendItem(color: .cyan, label: "Cold")
                LegendItem(color: .purple, label: "Contrast")
            }
            .font(.caption2)
            .padding(.top, Spacing.xs)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                FilterPill(
                    title: "All",
                    isSelected: selectedFilter == nil,
                    color: .modusCyan
                ) {
                    selectedFilter = nil
                }

                ForEach(RecoveryProtocolType.allCases, id: \.self) { type in
                    FilterPill(
                        title: type.displayName,
                        icon: type.icon,
                        isSelected: selectedFilter == type,
                        color: type.color
                    ) {
                        selectedFilter = type
                    }
                }
            }
        }
    }

    // MARK: - Sessions List

    private var sessionsListSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Selected date header
            HStack {
                Text(selectedDate.formatted(date: .complete, time: .omitted))
                    .font(.headline)
                Spacer()

                if !viewModel.sessionsForDate(selectedDate).isEmpty {
                    Text("\(viewModel.sessionsForDate(selectedDate).count) sessions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Sessions for selected date
            let filteredSessions = filteredSessionsForSelectedDate

            if filteredSessions.isEmpty {
                emptyDayView
            } else {
                ForEach(filteredSessions) { session in
                    SessionDetailCard(session: session)
                }
            }
        }
    }

    private var filteredSessionsForSelectedDate: [RecoverySession] {
        let dateSessions = viewModel.sessionsForDate(selectedDate)
        if let filter = selectedFilter {
            return dateSessions.filter { $0.protocolType == filter }
        }
        return dateSessions
    }

    private var emptyDayView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "calendar.badge.minus")
                .font(.system(size: 36))
                .foregroundColor(.secondary.opacity(0.5))
                .accessibilityHidden(true)

            Text("No sessions on this day")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if Calendar.current.isDateInToday(selectedDate) || selectedDate > Date() {
                Text("Tap a quick log button to start a session")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }
}

// MARK: - Stats Period

enum StatsPeriod: String, CaseIterable {
    case week, month, year
}

// MARK: - Stat Card

private struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value). \(subtitle)")
    }
}

// MARK: - Calendar Day Cell

private struct CalendarDayCell: View {
    let date: Date
    let sessions: [RecoverySession]
    let isSelected: Bool
    let isToday: Bool
    let action: () -> Void

    private var calendar: Calendar { Calendar.current }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.subheadline)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundColor(textColor)

                // Activity indicators
                if !sessions.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(uniqueTypes.prefix(3), id: \.self) { type in
                            Circle()
                                .fill(type.color)
                                .frame(width: 5, height: 5)
                        }
                    }
                } else {
                    Color.clear
                        .frame(height: 5)
                }
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(isSelected ? Color.modusCyan : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var uniqueTypes: [RecoveryProtocolType] {
        Array(Set(sessions.map { $0.protocolType }))
    }

    private var textColor: Color {
        if isSelected {
            return .modusCyan
        } else if isToday {
            return .primary
        } else {
            return .primary
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.modusCyan.opacity(0.1)
        } else if isToday {
            return Color(.tertiarySystemGroupedBackground)
        } else {
            return Color.clear
        }
    }

    private var accessibilityLabel: String {
        let dateStr = date.formatted(date: .abbreviated, time: .omitted)
        if sessions.isEmpty {
            return dateStr
        } else {
            return "\(dateStr), \(sessions.count) sessions"
        }
    }
}

// MARK: - Legend Item

private struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Filter Pill

private struct FilterPill: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                isSelected ? color.opacity(0.2) : Color(.secondarySystemGroupedBackground)
            )
            .foregroundColor(isSelected ? color : .primary)
            .cornerRadius(CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) filter, \(isSelected ? "selected" : "not selected")")
    }
}

// MARK: - Session Detail Card

private struct SessionDetailCard: View {
    let session: RecoverySession

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                // Type icon
                ZStack {
                    Circle()
                        .fill(session.protocolType.color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: session.protocolType.icon)
                        .font(.title3)
                        .foregroundColor(session.protocolType.color)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(session.protocolType.displayName)
                        .font(.headline)

                    Text(session.loggedAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(session.durationMinutes) min")
                        .font(.headline)

                    if let temp = session.temperature {
                        Text("\(Int(temp))°F")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Additional details
            HStack(spacing: Spacing.lg) {
                if let effort = session.perceivedEffort {
                    DetailBadge(icon: "flame", value: "\(effort)/10", label: "Effort")
                }

                if let hrAvg = session.heartRateAvg {
                    DetailBadge(icon: "heart.fill", value: "\(hrAvg)", label: "Avg HR")
                }

                Spacer()
            }

            // Notes
            if let notes = session.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        var label = "\(session.protocolType.displayName), \(session.durationMinutes) minutes at \(session.loggedAt.formatted(date: .omitted, time: .shortened))"
        if let temp = session.temperature {
            label += ", \(Int(temp)) degrees"
        }
        if let effort = session.perceivedEffort {
            label += ", effort \(effort) out of 10"
        }
        return label
    }
}

// MARK: - Detail Badge

private struct DetailBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
    }
}

// MARK: - Recovery History ViewModel

@MainActor
class RecoveryHistoryViewModel: ObservableObject {
    @Published var sessions: [RecoverySession] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedPeriod: StatsPeriod = .week
    @Published var currentMonth: Date = Date()

    private let recoveryService = RecoveryService.shared

    struct PeriodStats {
        let totalSessions: Int
        let totalMinutes: Int
        let averageMinutes: Int
        let longestStreak: Int
    }

    var periodStats: PeriodStats {
        let periodSessions = sessionsForPeriod(selectedPeriod)
        let totalMinutes = periodSessions.reduce(0) { $0 + $1.durationMinutes }
        let average = periodSessions.isEmpty ? 0 : totalMinutes / periodSessions.count

        return PeriodStats(
            totalSessions: periodSessions.count,
            totalMinutes: totalMinutes,
            averageMinutes: average,
            longestStreak: calculateStreak(for: periodSessions)
        )
    }

    var formattedTotalTime: String {
        let minutes = periodStats.totalMinutes
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMins = minutes % 60
            return "\(hours)h \(remainingMins)m"
        }
        return "\(minutes) min"
    }

    var sessionsTrend: String {
        let current = sessionsForPeriod(selectedPeriod).count
        let previous = sessionsForPreviousPeriod(selectedPeriod).count
        if previous == 0 { return "First \(selectedPeriod.rawValue)" }
        let change = current - previous
        if change > 0 {
            return "+\(change) vs last \(selectedPeriod.rawValue)"
        } else if change < 0 {
            return "\(change) vs last \(selectedPeriod.rawValue)"
        }
        return "Same as last \(selectedPeriod.rawValue)"
    }

    var timeTrend: String {
        let current = sessionsForPeriod(selectedPeriod).reduce(0) { $0 + $1.durationMinutes }
        let previous = sessionsForPreviousPeriod(selectedPeriod).reduce(0) { $0 + $1.durationMinutes }
        if previous == 0 { return "this \(selectedPeriod.rawValue)" }
        let changePercent = previous > 0 ? ((current - previous) * 100 / previous) : 0
        if changePercent > 0 {
            return "+\(changePercent)% vs last"
        } else if changePercent < 0 {
            return "\(changePercent)% vs last"
        }
        return "same as last"
    }

    var streakStatus: String {
        let streak = periodStats.longestStreak
        if streak >= 7 {
            return "Excellent consistency!"
        } else if streak >= 3 {
            return "Good progress"
        }
        return "Keep building"
    }

    var currentMonthString: String {
        currentMonth.formatted(.dateTime.month(.wide).year())
    }

    var calendarDays: [Date?] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let firstDayOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let leadingEmptyDays = firstWeekday - 1

        var days: [Date?] = Array(repeating: nil, count: leadingEmptyDays)

        var currentDate = firstDayOfMonth
        while currentDate < monthInterval.end {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        // Pad to complete weeks
        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    func loadHistory() async {
        isLoading = true
        await recoveryService.fetchSessions(days: 365)
        sessions = recoveryService.sessions
        isLoading = false
    }

    func sessionsForDate(_ date: Date) -> [RecoverySession] {
        let calendar = Calendar.current
        return sessions.filter { calendar.isDate($0.loggedAt, inSameDayAs: date) }
    }

    func previousMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    func nextMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    private func sessionsForPeriod(_ period: StatsPeriod) -> [RecoverySession] {
        let calendar = Calendar.current
        let now = Date()

        let startDate: Date
        switch period {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }

        return sessions.filter { $0.loggedAt >= startDate }
    }

    private func sessionsForPreviousPeriod(_ period: StatsPeriod) -> [RecoverySession] {
        let calendar = Calendar.current
        let now = Date()

        let (start, end): (Date, Date)
        switch period {
        case .week:
            end = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            start = calendar.date(byAdding: .day, value: -14, to: now) ?? now
        case .month:
            end = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            start = calendar.date(byAdding: .month, value: -2, to: now) ?? now
        case .year:
            end = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            start = calendar.date(byAdding: .year, value: -2, to: now) ?? now
        }

        return sessions.filter { $0.loggedAt >= start && $0.loggedAt < end }
    }

    private func calculateStreak(for sessions: [RecoverySession]) -> Int {
        guard !sessions.isEmpty else { return 0 }

        let calendar = Calendar.current
        let sessionDates = Set(sessions.map { calendar.startOfDay(for: $0.loggedAt) })
        let sortedDates = sessionDates.sorted(by: >)

        var streak = 1
        var maxStreak = 1
        var previousDate = sortedDates[0]

        for date in sortedDates.dropFirst() {
            if let dayBefore = calendar.date(byAdding: .day, value: -1, to: previousDate),
               calendar.isDate(date, inSameDayAs: dayBefore) {
                streak += 1
                maxStreak = max(maxStreak, streak)
            } else {
                streak = 1
            }
            previousDate = date
        }

        return maxStreak
    }
}

// MARK: - Recovery Protocol Type Extension

extension RecoveryProtocolType {
    var color: Color {
        switch self {
        case .saunaTraditional: return .orange
        case .saunaInfrared: return .red
        case .saunaSteam: return .mint
        case .coldPlunge: return .cyan
        case .coldShower: return .blue
        case .iceBath: return .indigo
        case .contrast: return .purple
        }
    }
}

// MARK: - Preview

#if DEBUG
struct RecoveryHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RecoveryHistoryView()
        }
        .previewDisplayName("Recovery History")
    }
}
#endif
