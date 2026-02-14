//
//  StreakCalendarView.swift
//  PTPerformance
//
//  ACP-836: Streak Tracking Feature
//  ACP-1029: Streak System Gamification - Color-coded activity density calendar
//  Calendar showing activity days and streak history with density visualization
//

import SwiftUI

/// Calendar view showing activity history for streak tracking
/// ACP-1029: Enhanced with color-coded activity density using Modus brand colors
struct StreakCalendarView: View {
    // MARK: - Properties

    let patientId: UUID

    @StateObject private var viewModel: StreakCalendarViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedDate: Date?

    // MARK: - Initialization

    init(patientId: UUID) {
        self.patientId = patientId
        _viewModel = StateObject(wrappedValue: StreakCalendarViewModel(patientId: patientId))
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Month navigation
                monthNavigator

                // Calendar grid
                calendarGrid

                // ACP-1029: Enhanced density legend
                densityLegendView

                // Selected day details
                if let date = selectedDate, let entry = viewModel.entry(for: date) {
                    selectedDayDetails(entry: entry, date: date)
                }

                // Monthly summary
                monthlySummary

                // ACP-1029: Streak freeze history for the month
                if viewModel.hasFreezeHistory {
                    freezeHistorySection
                }
            }
            .padding()
        }
        .navigationTitle("Activity Calendar")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            HapticFeedback.light()
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Month Navigator

    private var monthNavigator: some View {
        HStack {
            Button(action: {
                HapticFeedback.light()
                viewModel.previousMonth()
            }) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .foregroundColor(Color.modusCyan)
            }

            Spacer()

            Text(viewModel.currentMonthTitle)
                .font(.title2.bold())

            Spacer()

            Button(action: {
                HapticFeedback.light()
                viewModel.nextMonth()
            }) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(viewModel.canGoForward ? Color.modusCyan : .gray)
            }
            .disabled(!viewModel.canGoForward)
        }
        .padding(.horizontal)
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        VStack(spacing: 8) {
            // Day headers
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(viewModel.calendarDays, id: \.self) { date in
                    if let date = date {
                        calendarDayCell(date: date)
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color(.systemGray4).opacity(0.1), radius: 6, x: 0, y: 2)
        )
    }

    @ViewBuilder
    private func calendarDayCell(date: Date) -> some View {
        let entry = viewModel.entry(for: date)
        let hasWorkout = entry?.workoutCompleted ?? false
        let hasArmCare = entry?.armCareCompleted ?? false
        let hasAnyActivity = entry?.hasAnyActivity ?? false
        let isToday = Calendar.current.isDateInToday(date)
        let isSelected = selectedDate.map { Calendar.current.isDate(date, inSameDayAs: $0) } ?? false
        let isFuture = date > Date()
        let density = ActivityDensity.density(from: entry)

        Button(action: {
            HapticFeedback.light()
            if !isFuture && hasAnyActivity {
                selectedDate = date
            } else if !isFuture {
                selectedDate = nil
            }
        }) {
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 14, weight: isToday ? .bold : .regular))
                    .foregroundColor(isFuture ? .secondary.opacity(0.5) : .primary)

                // ACP-1029: Color-coded density indicators using Modus colors
                HStack(spacing: 2) {
                    if hasWorkout {
                        Circle()
                            .fill(Color.modusCyan)
                            .frame(width: 6, height: 6)
                    }
                    if hasArmCare {
                        Circle()
                            .fill(Color.modusTealAccent)
                            .frame(width: 6, height: 6)
                    }
                }
                .frame(height: 8)
            }
            .frame(width: 44, height: 44)
            .background(
                Group {
                    if isSelected {
                        Circle()
                            .fill(Color.modusCyan.opacity(0.25))
                    } else if hasAnyActivity {
                        // ACP-1029: Density-based background color
                        Circle()
                            .fill(densityCellColor(for: density))
                    } else {
                        Circle()
                            .fill(Color.clear)
                    }
                }
            )
            .overlay(
                Group {
                    if isToday {
                        Circle()
                            .stroke(Color.modusCyan, lineWidth: 2)
                    }
                }
            )
        }
        .disabled(isFuture)
    }

    /// ACP-1029: Cell background color based on density
    private func densityCellColor(for density: ActivityDensity) -> Color {
        switch density {
        case .none: return Color.clear
        case .light: return Color.modusCyan.opacity(0.15)
        case .moderate: return Color.modusTealAccent.opacity(0.25)
        case .high: return Color.modusTealAccent.opacity(0.4)
        }
    }

    // MARK: - ACP-1029: Enhanced Density Legend

    private var densityLegendView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 20) {
                legendItem(color: Color.modusCyan, text: "Workout")
                legendItem(color: Color.modusTealAccent, text: "Arm Care")
            }

            HStack(spacing: 12) {
                Text("Activity Level:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    ForEach([ActivityDensity.none, .light, .moderate, .high], id: \.rawValue) { density in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(densityLegendColor(for: density))
                            .frame(width: 16, height: 16)
                    }
                }

                Text("Low")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                Text("High")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .font(.caption)
    }

    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .foregroundColor(.secondary)
        }
    }

    /// ACP-1029: Legend swatch color
    private func densityLegendColor(for density: ActivityDensity) -> Color {
        switch density {
        case .none: return Color.gray.opacity(0.15)
        case .light: return Color.modusCyan.opacity(0.3)
        case .moderate: return Color.modusTealAccent.opacity(0.6)
        case .high: return Color.modusTealAccent
        }
    }

    // MARK: - Selected Day Details

    private func selectedDayDetails(entry: CalendarHistoryEntry, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(date, style: .date)
                    .font(.headline)
                Spacer()
                Button(action: {
                    selectedDate = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            if entry.workoutCompleted {
                HStack(spacing: 12) {
                    Image(systemName: StreakType.workout.iconName)
                        .foregroundColor(Color.modusCyan)
                        .frame(width: 24)
                    Text("Workout completed")
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.modusTealAccent)
                }
            }

            if entry.armCareCompleted {
                HStack(spacing: 12) {
                    Image(systemName: StreakType.armCare.iconName)
                        .foregroundColor(Color.modusTealAccent)
                        .frame(width: 24)
                    Text("Arm care completed")
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.modusTealAccent)
                }
            }

            if let notes = entry.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(notes)
                        .font(.subheadline)
                }
            }

            // ACP-1029: Activity density badge
            let density = ActivityDensity.density(from: entry)
            HStack(spacing: Spacing.xs) {
                Image(systemName: "chart.bar.fill")
                    .font(.caption)
                    .foregroundColor(Color.modusCyan)
                Text("Activity Level: \(densityLabel(for: density))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
                .adaptiveShadow(Shadow.subtle)
        )
    }

    private func densityLabel(for density: ActivityDensity) -> String {
        switch density {
        case .none: return "Rest Day"
        case .light: return "Light"
        case .moderate: return "Moderate"
        case .high: return "Full Session"
        }
    }

    // MARK: - Monthly Summary

    private var monthlySummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Month Summary")
                .font(.headline)

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.monthWorkoutCount)")
                        .font(.title.bold())
                        .foregroundColor(Color.modusCyan)
                    Text("Workouts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.monthArmCareCount)")
                        .font(.title.bold())
                        .foregroundColor(Color.modusTealAccent)
                    Text("Arm Care")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.monthActivityDays)")
                        .font(.title.bold())
                        .foregroundColor(Color.modusDeepTeal)
                    Text("Active Days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Consistency percentage
            HStack {
                Text("Consistency")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(viewModel.monthConsistencyPercent)%")
                    .font(.subheadline.weight(.semibold))
            }

            ProgressView(value: Double(viewModel.monthConsistencyPercent) / 100.0)
                .tint(Color.modusTealAccent)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color(.systemGray4).opacity(0.1), radius: 6, x: 0, y: 2)
        )
    }

    // MARK: - ACP-1029: Streak Freeze History

    private var freezeHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shield.checkered")
                    .foregroundColor(Color.modusTealAccent)
                Text("Streak Shields Used")
                    .font(.headline)
            }

            ForEach(viewModel.freezeUsageDates, id: \.self) { date in
                HStack(spacing: 12) {
                    Image(systemName: "shield.checkered")
                        .font(.caption)
                        .foregroundColor(Color.modusTealAccent)

                    Text(date, style: .date)
                        .font(.subheadline)

                    Spacer()

                    Text("Streak Protected")
                        .font(.caption)
                        .foregroundColor(Color.modusTealAccent)
                }
                .padding(.vertical, 4)
            }

            if viewModel.freezeUsageDates.isEmpty {
                Text("No streak shields used this month")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .adaptiveShadow(Shadow.subtle)
        )
    }
}

// MARK: - ViewModel

@MainActor
class StreakCalendarViewModel: ObservableObject {
    // MARK: - Properties

    private let patientId: UUID
    private let service: StreakTrackingService
    private let calendar = Calendar.current

    @Published var currentMonth: Date = Date()
    @Published var historyEntries: [CalendarHistoryEntry] = []
    @Published var isLoading = false

    // MARK: - Initialization

    init(patientId: UUID, service: StreakTrackingService? = nil) {
        self.patientId = patientId
        self.service = service ?? StreakTrackingService.shared
    }

    // MARK: - Computed Properties

    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    var currentMonthTitle: String {
        Self.monthYearFormatter.string(from: currentMonth)
    }

    var canGoForward: Bool {
        let today = Date()
        guard let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)),
              let todayMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) else {
            return false
        }
        return currentMonthStart < todayMonthStart
    }

    var calendarDays: [Date?] {
        var days: [Date?] = []

        // Get the first day of the month
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        guard let firstDayOfMonth = calendar.date(from: components) else { return days }

        // Get the weekday of the first day (0 = Sunday)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1

        // Add empty cells for days before the first day of the month
        for _ in 0..<firstWeekday {
            days.append(nil)
        }

        // Get the range of days in the month
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth) else { return days }

        // Add each day of the month
        for day in range {
            if let date = calendar.date(bySetting: .day, value: day, of: firstDayOfMonth) {
                days.append(date)
            }
        }

        return days
    }

    var monthWorkoutCount: Int {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)),
              let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
            return 0
        }

        return historyEntries.filter { entry in
            entry.activityDate >= monthStart && entry.activityDate < monthEnd && entry.workoutCompleted
        }.count
    }

    var monthArmCareCount: Int {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)),
              let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
            return 0
        }

        return historyEntries.filter { entry in
            entry.activityDate >= monthStart && entry.activityDate < monthEnd && entry.armCareCompleted
        }.count
    }

    var monthActivityDays: Int {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)),
              let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
            return 0
        }

        return historyEntries.filter { entry in
            entry.activityDate >= monthStart && entry.activityDate < monthEnd && entry.hasAnyActivity
        }.count
    }

    var monthConsistencyPercent: Int {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else {
            return 0
        }
        let today = Date()

        // Calculate days elapsed in month (or total days if viewing past month)
        guard let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
            return 0
        }
        let endDate = min(today, nextMonthStart)
        let daysInPeriod = calendar.dateComponents([.day], from: monthStart, to: endDate).day ?? 1

        guard daysInPeriod > 0 else { return 0 }
        return Int(Double(monthActivityDays) / Double(daysInPeriod) * 100)
    }

    /// ACP-1029: Check if there are any freeze usage dates to show
    var hasFreezeHistory: Bool {
        !StreakFreezeService.shared.inventory.freezes.filter { $0.isUsed }.isEmpty
    }

    /// ACP-1029: Dates when streak freezes were used
    var freezeUsageDates: [Date] {
        StreakFreezeService.shared.inventory.freezes
            .filter { $0.isUsed }
            .compactMap { $0.usedForDate }
            .filter { date in
                guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)),
                      let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
                    return false
                }
                return date >= monthStart && date < monthEnd
            }
            .sorted()
    }

    // MARK: - Methods

    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Load 90 days of history to cover 3 months of navigation
            historyEntries = try await service.getStreakHistory(for: patientId, days: 90)
        } catch {
            DebugLogger.shared.warning("StreakCalendarView", "Error loading data: \(error.localizedDescription)")
        }
    }

    func refresh() async {
        await loadData()
    }

    func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    func nextMonth() {
        if canGoForward, let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    func entry(for date: Date) -> CalendarHistoryEntry? {
        historyEntries.first { calendar.isDate($0.activityDate, inSameDayAs: date) }
    }
}

// MARK: - Previews

#Preview("Calendar View") {
    NavigationStack {
        StreakCalendarView(patientId: UUID())
    }
}
