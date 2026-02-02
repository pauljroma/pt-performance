//
//  StreakCalendarView.swift
//  PTPerformance
//
//  ACP-836: Streak Tracking Feature
//  Calendar showing activity days and streak history
//

import SwiftUI

/// Calendar view showing activity history for streak tracking
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

                // Legend
                legendView

                // Selected day details
                if let date = selectedDate, let entry = viewModel.entry(for: date) {
                    selectedDayDetails(entry: entry, date: date)
                }

                // Monthly summary
                monthlySummary
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
                    .foregroundColor(.accentColor)
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
                    .foregroundColor(viewModel.canGoForward ? .accentColor : .gray)
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
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 2)
        )
    }

    @ViewBuilder
    private func calendarDayCell(date: Date) -> some View {
        let entry = viewModel.entry(for: date)
        let hasWorkout = entry?.workoutCompleted ?? false
        let hasArmCare = entry?.armCareCompleted ?? false
        let hasAnyActivity = entry?.hasAnyActivity ?? false
        let isToday = Calendar.current.isDateInToday(date)
        let isSelected = selectedDate != nil && Calendar.current.isDate(date, inSameDayAs: selectedDate!)
        let isFuture = date > Date()

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

                // Activity indicators
                HStack(spacing: 2) {
                    if hasWorkout {
                        Circle()
                            .fill(StreakType.workout.color)
                            .frame(width: 6, height: 6)
                    }
                    if hasArmCare {
                        Circle()
                            .fill(StreakType.armCare.color)
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
                            .fill(Color.accentColor.opacity(0.2))
                    } else if hasAnyActivity {
                        Circle()
                            .fill(Color.green.opacity(0.2))
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
                            .stroke(Color.accentColor, lineWidth: 2)
                    }
                }
            )
        }
        .disabled(isFuture)
    }

    // MARK: - Legend View

    private var legendView: some View {
        HStack(spacing: 20) {
            legendItem(color: StreakType.workout.color, text: "Workout")
            legendItem(color: StreakType.armCare.color, text: "Arm Care")
            legendItem(color: .green.opacity(0.3), text: "Activity Day")
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
                        .foregroundColor(StreakType.workout.color)
                        .frame(width: 24)
                    Text("Workout completed")
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }

            if entry.armCareCompleted {
                HStack(spacing: 12) {
                    Image(systemName: StreakType.armCare.iconName)
                        .foregroundColor(StreakType.armCare.color)
                        .frame(width: 24)
                    Text("Arm care completed")
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
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
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .adaptiveShadow(Shadow.subtle)
        )
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
                        .foregroundColor(StreakType.workout.color)
                    Text("Workouts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.monthArmCareCount)")
                        .font(.title.bold())
                        .foregroundColor(StreakType.armCare.color)
                    Text("Arm Care")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.monthActivityDays)")
                        .font(.title.bold())
                        .foregroundColor(.green)
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
                .tint(.green)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 2)
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

    init(patientId: UUID, service: StreakTrackingService = .shared) {
        self.patientId = patientId
        self.service = service
    }

    // MARK: - Computed Properties

    var currentMonthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    var canGoForward: Bool {
        let today = Date()
        let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let todayMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
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
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!

        return historyEntries.filter { entry in
            entry.activityDate >= monthStart && entry.activityDate < monthEnd && entry.workoutCompleted
        }.count
    }

    var monthArmCareCount: Int {
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!

        return historyEntries.filter { entry in
            entry.activityDate >= monthStart && entry.activityDate < monthEnd && entry.armCareCompleted
        }.count
    }

    var monthActivityDays: Int {
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!

        return historyEntries.filter { entry in
            entry.activityDate >= monthStart && entry.activityDate < monthEnd && entry.hasAnyActivity
        }.count
    }

    var monthConsistencyPercent: Int {
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let today = Date()

        // Calculate days elapsed in month (or total days if viewing past month)
        let endDate = min(today, calendar.date(byAdding: .month, value: 1, to: monthStart)!)
        let daysInPeriod = calendar.dateComponents([.day], from: monthStart, to: endDate).day ?? 1

        guard daysInPeriod > 0 else { return 0 }
        return Int(Double(monthActivityDays) / Double(daysInPeriod) * 100)
    }

    // MARK: - Methods

    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Load 90 days of history to cover 3 months of navigation
            historyEntries = try await service.getStreakHistory(for: patientId, days: 90)
        } catch {
            #if DEBUG
            print("[StreakCalendar] Error loading data: \(error)")
            #endif
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
