//
//  CalendarView.swift
//  PTPerformance
//
//  Created by Build 46 Swarm Agent 1
//  ACP-1033: Enhanced calendar with month/week/day views,
//  training load density, quick-add, and workout status indicators
//

import SwiftUI

// MARK: - Calendar View Mode

enum CalendarViewMode: String, CaseIterable, Identifiable {
    case month = "Month"
    case week = "Week"
    case day = "Day"

    var id: String { rawValue }
}

// MARK: - CalendarViewState

/// Dedicated state object for CalendarView, consolidating all @State properties
/// and helper methods that operate on them.
@MainActor
class CalendarViewState: ObservableObject {

    // MARK: - Published State

    @Published var selectedDate = Date()
    @Published var currentMonth = Date()
    @Published var viewMode: CalendarViewMode = .month
    @Published var scheduledSessions: [ScheduledSession] = [] {
        didSet { rebuildSessionsByDate() }
    }
    /// Cached dictionary mapping date strings ("yyyy-MM-dd") to sessions (Fix 4)
    @Published var sessionsByDate: [String: [ScheduledSession]] = [:]
    @Published var isLoading = false
    @Published var showScheduleSheet = false
    @Published var showDayDetailSheet = false
    @Published var quickAddDate: Date?
    /// Cached month dates grid, recalculated only when currentMonth changes (Fix 6)
    @Published var cachedMonthDates: [Date?] = []

    // ACP-1034: Smart Scheduling Suggestions
    @Published var todaySuggestion: SchedulingSuggestion?
    @Published var allSuggestions: [SchedulingSuggestion] = []
    @Published var bestTrainingTimes: [TrainingTimeWindow] = []
    @Published var missedWorkoutProposals: [ReschedulingProposal] = []
    @Published var calendarConflicts: [Date: [CalendarConflictInfo]] = [:]
    @Published var showBestTimesWidget = false
    @Published var showConflictDetails = false
    @Published var selectedConflictDate: Date?

    // MARK: - Constants

    let calendar = Calendar.current
    let columns = Array(repeating: GridItem(.flexible()), count: 7)

    // MARK: - Services

    let smartSchedulingService = SmartSchedulingService.shared

    // MARK: - Static DateFormatters (Fix 5: avoid repeated allocations)

    static let monthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()
    static let dayOfWeekFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f
    }()
    static let daySubtitleFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM d, yyyy"
        return f
    }()
    static let fullDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        f.timeStyle = .none
        return f
    }()
    static let weekRangeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()
    static let dayNumberFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f
    }()
    static let sessionDateKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    static let mediumDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()
    static let accessibilityDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        return f
    }()

    // MARK: - Computed Properties

    var headerTitle: String {
        if viewMode == .day {
            return Self.dayOfWeekFormatter.string(from: selectedDate)
        }
        return Self.monthYearFormatter.string(from: currentMonth)
    }

    var daySubtitle: String {
        Self.daySubtitleFormatter.string(from: selectedDate)
    }

    var dayFullDateString: String {
        Self.fullDateFormatter.string(from: selectedDate)
    }

    var weekRangeString: String {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentMonth) else {
            return ""
        }
        let start = Self.weekRangeFormatter.string(from: weekInterval.start)
        let end = Self.weekRangeFormatter.string(from: weekInterval.end)
        return "\(start) - \(end)"
    }

    var weekdaySymbols: [String] {
        let symbols = calendar.shortWeekdaySymbols
        return Array(symbols.suffix(1) + symbols.prefix(6))
    }

    /// Computes month dates for the calendar grid
    var monthDates: [Date?] {
        cachedMonthDates
    }

    var currentWeekDates: [Date] {
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

    var sessionsForSelectedDate: [ScheduledSession] {
        sessionsForDate(selectedDate)
    }

    // MARK: - Session Lookup

    /// Looks up sessions by date string key (Fix 4: O(1) dictionary lookup instead of O(N) filter)
    func sessionsForDate(_ date: Date) -> [ScheduledSession] {
        let key = Self.sessionDateKeyFormatter.string(from: date)
        return sessionsByDate[key] ?? []
    }

    /// Rebuilds the sessionsByDate dictionary when scheduledSessions changes (Fix 4)
    func rebuildSessionsByDate() {
        var dict: [String: [ScheduledSession]] = [:]
        for session in scheduledSessions {
            let key = Self.sessionDateKeyFormatter.string(from: session.scheduledDate)
            dict[key, default: []].append(session)
        }
        sessionsByDate = dict
    }

    // MARK: - Month Dates Computation

    /// Recomputes month dates when currentMonth changes (Fix 6)
    static func computeMonthDates(for month: Date, calendar: Calendar) -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        var dates: [Date?] = []
        var currentDate = monthFirstWeek.start

        for _ in 0..<42 {
            dates.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        return dates
    }

    // MARK: - Training Load

    /// Compute a 0.0...1.0 training load for a date based on session count and status.
    /// 0 = rest day, 1.0 = heavy training day
    func trainingLoadForDate(_ date: Date) -> Double {
        let sessions = sessionsForDate(date)
        if sessions.isEmpty { return 0.0 }

        let activeSessions = sessions.filter { $0.status != .cancelled }
        if activeSessions.isEmpty { return 0.0 }

        // Scale: 1 session = 0.35, 2 = 0.65, 3+ = 0.9+
        let count = Double(activeSessions.count)
        return min(1.0, 0.15 + count * 0.25)
    }

    func trainingLoadColor(_ load: Double) -> Color {
        if load == 0 { return .modusCyan.opacity(0.08) }
        return .modusCyan.opacity(max(0.15, load))
    }

    func trainingLoadLabel(_ load: Double) -> String {
        switch load {
        case 0: return "Rest Day"
        case 0.01..<0.35: return "Light Training"
        case 0.35..<0.65: return "Moderate Training"
        default: return "Heavy Training"
        }
    }

    // MARK: - Navigation

    func previousPeriod() {
        switch viewMode {
        case .month:
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        case .week:
            currentMonth = calendar.date(byAdding: .weekOfYear, value: -1, to: currentMonth) ?? currentMonth
        case .day:
            selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        }
    }

    func nextPeriod() {
        switch viewMode {
        case .month:
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        case .week:
            currentMonth = calendar.date(byAdding: .weekOfYear, value: 1, to: currentMonth) ?? currentMonth
        case .day:
            selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        }
    }

    // MARK: - Data Loading

    func loadScheduledSessions() {
        isLoading = true

        Task {
            do {
                guard let patientId = PTSupabaseClient.shared.userId else {
                    isLoading = false
                    return
                }
                let sessions = try await SchedulingService.shared.fetchScheduledSessions(for: patientId)
                scheduledSessions = sessions
                isLoading = false
            } catch {
                isLoading = false
            }
        }
    }

    // ACP-1034: Load smart scheduling suggestions
    func loadSmartSuggestions() {
        Task {
            guard let patientIdString = PTSupabaseClient.shared.userId,
                  let patientId = UUID(uuidString: patientIdString) else {
                return
            }

            do {
                // Load suggestions concurrently
                async let todaySuggestionTask = smartSchedulingService.getTodaySuggestion(for: patientId)
                async let allSuggestionsTask = smartSchedulingService.generateSuggestions(for: patientId, days: 7)
                async let bestTimesTask = smartSchedulingService.analyzeBestTrainingTimes(for: patientId)
                async let missedWorkoutsTask = smartSchedulingService.autoAdjustMissedWorkouts(for: patientId, autoApply: false)

                let (today, all, times, missed) = try await (todaySuggestionTask, allSuggestionsTask, bestTimesTask, missedWorkoutsTask)

                todaySuggestion = today
                allSuggestions = all
                bestTrainingTimes = times
                missedWorkoutProposals = missed

                // Load calendar conflicts for suggested dates
                for suggestion in all {
                    let conflicts = await smartSchedulingService.getCalendarConflicts(on: suggestion.date)
                    calendarConflicts[suggestion.date] = conflicts
                }
            } catch {
                // Silently fail - suggestions are optional
            }
        }
    }

    // MARK: - Actions

    func rescheduleWorkout(proposal: ReschedulingProposal) {
        Task {
            do {
                let newDate = Calendar.current.date(
                    bySettingHour: proposal.suggestedTime.hour,
                    minute: proposal.suggestedTime.minute,
                    second: 0,
                    of: proposal.suggestedDate
                ) ?? proposal.suggestedDate

                _ = try await SchedulingService.shared.rescheduleSession(
                    scheduledSessionId: proposal.originalSession.id,
                    newDate: proposal.suggestedDate,
                    newTime: newDate
                )

                HapticFeedback.success()

                loadScheduledSessions()
                loadSmartSuggestions()
            } catch {
                HapticFeedback.error()
            }
        }
    }

    func dismissProposal(_ proposal: ReschedulingProposal) {
        missedWorkoutProposals.removeAll { $0.id == proposal.id }
    }
}

// MARK: - CalendarView

struct CalendarView: View {

    @StateObject private var state = CalendarViewState()

    let onDateSelected: ((Date) -> Void)?

    init(onDateSelected: ((Date) -> Void)? = nil) {
        self.onDateSelected = onDateSelected
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with month/year and navigation
            calendarHeader

            // View mode segmented control (Month / Week / Day)
            viewModeSegment

            // ACP-1034: Smart Scheduling Suggestions
            if state.viewMode == .month {
                smartSuggestionsSection
            }

            // Calendar content
            switch state.viewMode {
            case .month:
                monthView
            case .week:
                weekView
            case .day:
                dayView
            }

            // Training load legend
            trainingLoadLegend
        }
        .onAppear {
            state.cachedMonthDates = CalendarViewState.computeMonthDates(for: state.currentMonth, calendar: state.calendar)
            state.loadScheduledSessions()
            state.loadSmartSuggestions()
        }
        .onChange(of: state.currentMonth) { _, newMonth in
            state.cachedMonthDates = CalendarViewState.computeMonthDates(for: newMonth, calendar: state.calendar)
        }
        .sheet(isPresented: $state.showScheduleSheet) {
            if let date = state.quickAddDate {
                ScheduleSessionView(selectedDate: date)
            } else {
                ScheduleSessionView(selectedDate: state.selectedDate)
            }
        }
        .sheet(isPresented: $state.showDayDetailSheet) {
            DayDetailSheet(
                date: state.selectedDate,
                sessions: state.sessionsForSelectedDate,
                conflicts: state.calendarConflicts[state.selectedDate] ?? [],
                onSchedule: {
                    state.quickAddDate = state.selectedDate
                    state.showDayDetailSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        state.showScheduleSheet = true
                    }
                }
            )
        }
        .sheet(isPresented: $state.showBestTimesWidget) {
            NavigationStack {
                bestTimesView
            }
        }
        .sheet(isPresented: $state.showConflictDetails) {
            if let conflictDate = state.selectedConflictDate,
               let conflicts = state.calendarConflicts[conflictDate] {
                ConflictDetailsSheet(date: conflictDate, conflicts: conflicts)
            }
        }
        .onChange(of: state.showScheduleSheet) { _, isPresented in
            if !isPresented {
                state.quickAddDate = nil
                state.loadScheduledSessions()
                state.loadSmartSuggestions()
            }
        }
    }

    // MARK: - Header

    private var calendarHeader: some View {
        HStack {
            Button(action: {
                HapticFeedback.light()
                state.previousPeriod()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.modusCyan)
            }
            .accessibilityLabel("Previous \(state.viewMode.rawValue.lowercased())")

            Spacer()

            VStack(spacing: 4) {
                Text(state.headerTitle)
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)

                if state.viewMode == .week {
                    Text(state.weekRangeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if state.viewMode == .day {
                    Text(state.daySubtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: {
                HapticFeedback.light()
                state.nextPeriod()
            }) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.modusCyan)
            }
            .accessibilityLabel("Next \(state.viewMode.rawValue.lowercased())")
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - View Mode Segment

    private var viewModeSegment: some View {
        Picker("View Mode", selection: $state.viewMode) {
            ForEach(CalendarViewMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
        .padding(.bottom, Spacing.xs)
        .onChange(of: state.viewMode) { _, _ in
            HapticFeedback.selectionChanged()
        }
    }

    // MARK: - Month View

    private var monthView: some View {
        VStack(spacing: 0) {
            // Day headers
            LazyVGrid(columns: state.columns, spacing: 0) {
                ForEach(state.weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xs)
                }
            }

            Divider()

            // Calendar dates
            LazyVGrid(columns: state.columns, spacing: 0) {
                ForEach(state.monthDates, id: \.self) { date in
                    if let date = date {
                        EnhancedCalendarDateCell(
                            date: date,
                            isSelected: state.calendar.isDate(date, inSameDayAs: state.selectedDate),
                            isToday: state.calendar.isDateInToday(date),
                            isCurrentMonth: state.calendar.isDate(date, equalTo: state.currentMonth, toGranularity: .month),
                            sessions: state.sessionsForDate(date),
                            trainingLoad: state.trainingLoadForDate(date),
                            onTap: {
                                state.selectedDate = date
                                onDateSelected?(date)
                                HapticFeedback.light()
                                state.showDayDetailSheet = true
                            },
                            onQuickAdd: {
                                state.quickAddDate = date
                                HapticFeedback.medium()
                                state.showScheduleSheet = true
                            }
                        )
                    } else {
                        Color.clear
                            .frame(height: 68)
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
            LazyVGrid(columns: state.columns, spacing: 0) {
                ForEach(state.weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xs)
                }
            }

            Divider()

            // Current week dates with expanded detail
            LazyVGrid(columns: state.columns, spacing: 0) {
                ForEach(state.currentWeekDates, id: \.self) { date in
                    EnhancedCalendarDateCell(
                        date: date,
                        isSelected: state.calendar.isDate(date, inSameDayAs: state.selectedDate),
                        isToday: state.calendar.isDateInToday(date),
                        isCurrentMonth: true,
                        sessions: state.sessionsForDate(date),
                        trainingLoad: state.trainingLoadForDate(date),
                        onTap: {
                            state.selectedDate = date
                            onDateSelected?(date)
                            HapticFeedback.light()
                            state.showDayDetailSheet = true
                        },
                        onQuickAdd: {
                            state.quickAddDate = date
                            HapticFeedback.medium()
                            state.showScheduleSheet = true
                        }
                    )
                }
            }

            // Week session summary below the grid
            weekSessionSummary
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Day View

    private var dayView: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                // Day header card
                dayHeaderCard

                // Sessions for the day
                if state.sessionsForSelectedDate.isEmpty {
                    dayEmptyState
                } else {
                    ForEach(state.sessionsForSelectedDate) { session in
                        DaySessionCard(session: session)
                    }
                }
            }
            .padding()
        }
    }

    private var dayHeaderCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(state.dayFullDateString)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.modusDeepTeal)

                let load = state.trainingLoadForDate(state.selectedDate)
                HStack(spacing: 6) {
                    Circle()
                        .fill(state.trainingLoadColor(load))
                        .frame(width: 10, height: 10)
                    Text(state.trainingLoadLabel(load))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Quick-add button
            Button(action: {
                state.quickAddDate = state.selectedDate
                HapticFeedback.medium()
                state.showScheduleSheet = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.modusCyan)
            }
            .accessibilityLabel("Add workout for \(state.dayFullDateString)")
        }
        .padding()
        .background(Color.modusLightTeal)
        .cornerRadius(CornerRadius.md)
    }

    private var dayEmptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.modusTealAccent.opacity(0.5))

            Text("No workouts scheduled")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button(action: {
                state.quickAddDate = state.selectedDate
                HapticFeedback.medium()
                state.showScheduleSheet = true
            }) {
                Label("Schedule Workout", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.modusCyan)
                    .cornerRadius(CornerRadius.sm)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
    }

    // MARK: - Week Session Summary

    private var weekSessionSummary: some View {
        let weekSessions = state.currentWeekDates.flatMap { state.sessionsForDate($0) }
        let completed = weekSessions.filter { $0.status == .completed }.count
        let scheduled = weekSessions.filter { $0.status == .scheduled }.count
        let missed = weekSessions.filter { $0.isPastDue }.count

        return VStack(spacing: Spacing.sm) {
            Divider()

            HStack(spacing: Spacing.lg) {
                WeekSummaryBadge(
                    count: completed,
                    label: "Done",
                    color: .modusTealAccent
                )
                WeekSummaryBadge(
                    count: scheduled,
                    label: "Upcoming",
                    color: .modusCyan
                )
                WeekSummaryBadge(
                    count: missed,
                    label: "Missed",
                    color: DesignTokens.statusError
                )
            }
            .padding()
        }
    }

    // MARK: - Training Load Legend

    private var trainingLoadLegend: some View {
        VStack(spacing: 4) {
            Divider()
            HStack(spacing: Spacing.md) {
                legendDot(color: .modusCyan.opacity(0.15), label: "Rest")
                legendDot(color: .modusCyan.opacity(0.4), label: "Light")
                legendDot(color: .modusCyan.opacity(0.65), label: "Moderate")
                legendDot(color: .modusCyan.opacity(0.9), label: "Heavy")
                Spacer()
                HStack(spacing: 4) {
                    Circle().fill(Color.modusTealAccent).frame(width: 6, height: 6)
                    Text("Done")
                }
                HStack(spacing: 4) {
                    Circle().fill(Color.modusCyan).frame(width: 6, height: 6)
                    Text("Upcoming")
                }
                HStack(spacing: 4) {
                    Circle().fill(DesignTokens.statusError).frame(width: 6, height: 6)
                    Text("Missed")
                }
            }
            .font(.system(size: 10))
            .foregroundColor(.secondary)
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
        .background(Color(.systemBackground))
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
        }
    }
}

// MARK: - Smart Suggestions Section

extension CalendarView {

    @ViewBuilder
    var smartSuggestionsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                // Missed workout reschedule cards
                ForEach(state.missedWorkoutProposals.prefix(2)) { proposal in
                    MissedWorkoutRescheduleCard(
                        proposal: proposal,
                        onAccept: {
                            state.rescheduleWorkout(proposal: proposal)
                        },
                        onDismiss: {
                            state.dismissProposal(proposal)
                        }
                    )
                    .frame(width: 320)
                }

                // Today's suggestion
                if let suggestion = state.todaySuggestion {
                    SmartSchedulingSuggestionCard(
                        suggestion: suggestion,
                        onSchedule: {
                            state.quickAddDate = suggestion.date
                            state.showScheduleSheet = true
                        }
                    )
                    .frame(width: 320)
                }

                // Best times widget preview
                if !state.bestTrainingTimes.isEmpty {
                    bestTimesPreviewCard
                        .frame(width: 280)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var bestTimesPreviewCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "clock.badge.checkmark")
                    .font(.title3)
                    .foregroundColor(.modusCyan)
                    .accessibilityHidden(true)

                Text("Best Times to Train")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)

                Spacer()
            }

            if let firstWindow = state.bestTrainingTimes.first {
                VStack(alignment: .leading, spacing: 4) {
                    Text(firstWindow.timeOfDay)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("\(firstWindow.startHour):00 - \(firstWindow.endHour):00")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("\(Int(firstWindow.avgReadiness))% avg readiness")
                            .font(.caption2)
                            .foregroundColor(.modusTealAccent)

                        Spacer()
                    }
                }

                Button(action: {
                    HapticFeedback.light()
                    state.showBestTimesWidget = true
                }) {
                    HStack {
                        Text("View All Times")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundColor(.modusCyan)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xs)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    private var bestTimesView: some View {
        BestTimeToTrainWidget(timeWindows: state.bestTrainingTimes) { window in
            // Auto-schedule at this time
            let calendar = Calendar.current
            guard let targetDate = calendar.nextDate(after: Date(), matching: DateComponents(hour: window.startHour), matchingPolicy: .nextTime) else {
                return
            }
            state.quickAddDate = targetDate
            state.showBestTimesWidget = false
            state.showScheduleSheet = true
        }
        .padding()
        .navigationTitle("Best Times to Train")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    state.showBestTimesWidget = false
                }
                .foregroundColor(.modusCyan)
            }
        }
    }
}

// MARK: - Enhanced Calendar Date Cell

struct EnhancedCalendarDateCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let sessions: [ScheduledSession]
    let trainingLoad: Double
    let onTap: () -> Void
    let onQuickAdd: () -> Void

    @State private var showQuickAdd = false

    private static let dayNumberFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f
    }()

    private var dayNumber: String {
        Self.dayNumberFormatter.string(from: date)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 2) {
                // Day number with training load background
                Text(dayNumber)
                    .font(.system(size: 14, weight: isToday ? .bold : .regular))
                    .foregroundColor(textColor)
                    .frame(width: 30, height: 30)
                    .background(dayBackground)
                    .clipShape(Circle())

                // Workout status indicators
                statusIndicators
            }
            .frame(maxWidth: .infinity)
            .frame(height: 68)
            .background(cellBackground)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
            .onLongPressGesture {
                onQuickAdd()
            }

            // Quick-add "+" button (visible on hover/selected)
            if isSelected || showQuickAdd {
                Button(action: onQuickAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.modusCyan)
                        .background(Circle().fill(Color(.systemBackground)).frame(width: 12, height: 12))
                }
                .offset(x: -2, y: 2)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Tap to view details. Long press to add workout.")
    }

    // MARK: - Visual Styling

    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return .modusCyan
        } else if !isCurrentMonth {
            return .secondary.opacity(0.5)
        } else {
            return .primary
        }
    }

    @ViewBuilder
    private var dayBackground: some View {
        if isSelected {
            Color.modusCyan
        } else if isToday {
            Color.modusCyan.opacity(0.2)
        } else {
            Color.clear
        }
    }

    /// Cell background represents training load density:
    /// lighter = rest, darker = heavy
    @ViewBuilder
    private var cellBackground: some View {
        if trainingLoad > 0 && isCurrentMonth {
            Color.modusCyan.opacity(trainingLoad * 0.18)
        } else {
            Color.clear
        }
    }

    // MARK: - Status Indicators

    @ViewBuilder
    private var statusIndicators: some View {
        if !sessions.isEmpty {
            HStack(spacing: 3) {
                ForEach(sessions.prefix(3)) { session in
                    statusDot(for: session)
                }
                if sessions.count > 3 {
                    Text("+\(sessions.count - 3)")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 8)
        } else {
            Spacer()
                .frame(height: 8)
        }
    }

    @ViewBuilder
    private func statusDot(for session: ScheduledSession) -> some View {
        switch session.status {
        case .completed:
            // Completed: filled teal accent circle with checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 6))
                .foregroundColor(.modusTealAccent)
        case .scheduled:
            if session.isPastDue {
                // Missed: red warning dot
                Circle()
                    .fill(DesignTokens.statusError)
                    .frame(width: 5, height: 5)
            } else {
                // Upcoming: cyan dot
                Circle()
                    .fill(Color.modusCyan)
                    .frame(width: 5, height: 5)
            }
        case .cancelled:
            // Cancelled: gray dot with line
            Circle()
                .strokeBorder(Color.secondary.opacity(0.5), lineWidth: 1)
                .frame(width: 5, height: 5)
        case .rescheduled:
            // Rescheduled: orange dot
            Circle()
                .fill(DesignTokens.statusWarning)
                .frame(width: 5, height: 5)
        }
    }

    // MARK: - Accessibility

    private static let accessibilityDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        return f
    }()

    private var accessibilityDescription: String {
        var desc = Self.accessibilityDateFormatter.string(from: date)

        if isToday { desc += ", Today" }

        let completed = sessions.filter { $0.status == .completed }.count
        let upcoming = sessions.filter { $0.status == .scheduled && !$0.isPastDue }.count
        let missed = sessions.filter { $0.isPastDue }.count

        if completed > 0 { desc += ", \(completed) completed" }
        if upcoming > 0 { desc += ", \(upcoming) upcoming" }
        if missed > 0 { desc += ", \(missed) missed" }
        if sessions.isEmpty { desc += ", rest day" }

        return desc
    }
}

// MARK: - Day Session Card

struct DaySessionCard: View {
    let session: ScheduledSession

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Status stripe
            RoundedRectangle(cornerRadius: 2)
                .fill(statusColor)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(session.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer()

                    statusBadge
                }

                Text(session.formattedTime)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let notes = session.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(session.displayName), \(session.formattedTime), \(session.status.displayName)")
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
                .font(.system(size: 10))
            Text(statusLabel)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(statusColor)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, 3)
        .background(statusColor.opacity(0.12))
        .cornerRadius(CornerRadius.xs)
    }

    private var statusColor: Color {
        switch session.status {
        case .completed: return .modusTealAccent
        case .scheduled: return session.isPastDue ? DesignTokens.statusError : .modusCyan
        case .cancelled: return .secondary
        case .rescheduled: return DesignTokens.statusWarning
        }
    }

    private var statusIcon: String {
        switch session.status {
        case .completed: return "checkmark.circle.fill"
        case .scheduled: return session.isPastDue ? "exclamationmark.circle.fill" : "clock.fill"
        case .cancelled: return "xmark.circle"
        case .rescheduled: return "arrow.triangle.2.circlepath"
        }
    }

    private var statusLabel: String {
        if session.status == .scheduled && session.isPastDue {
            return "Missed"
        }
        return session.status.displayName
    }
}

// MARK: - Week Summary Badge

struct WeekSummaryBadge: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.title3.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) \(label)")
    }
}

// MARK: - Day Detail Sheet

struct DayDetailSheet: View {
    let date: Date
    let sessions: [ScheduledSession]
    let conflicts: [CalendarConflictInfo]
    let onSchedule: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showConflictDetails = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // Summary header
                    daySummaryHeader

                    // ACP-1034: Calendar conflicts warning
                    if !conflicts.isEmpty {
                        calendarConflictsSection
                    }

                    if sessions.isEmpty {
                        emptyDayView
                    } else {
                        // Session cards
                        ForEach(sessions) { session in
                            DaySessionCard(session: session)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(formattedDate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.modusCyan)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onSchedule) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.modusCyan)
                    }
                    .accessibilityLabel("Add workout")
                }
            }
            .sheet(isPresented: $showConflictDetails) {
                ConflictDetailsSheet(date: date, conflicts: conflicts)
            }
        }
        .presentationDetents([.medium, .large])
    }

    // ACP-1034: Calendar conflicts section
    private var calendarConflictsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            CalendarConflictBadge(conflicts: conflicts) {
                showConflictDetails = true
            }

            if conflicts.count <= 2 {
                ForEach(conflicts.prefix(2)) { conflict in
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(conflict.title)
                                .font(.caption)
                                .foregroundColor(.primary)

                            Text(conflict.timeRange)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.xs)
                }
            }
        }
    }

    private static let mediumDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    private var formattedDate: String {
        Self.mediumDateFormatter.string(from: date)
    }

    private var daySummaryHeader: some View {
        HStack(spacing: Spacing.md) {
            let completed = sessions.filter { $0.status == .completed }.count
            let upcoming = sessions.filter { $0.status == .scheduled && !$0.isPastDue }.count
            let missed = sessions.filter { $0.isPastDue }.count

            if completed > 0 {
                Label("\(completed) completed", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.modusTealAccent)
            }
            if upcoming > 0 {
                Label("\(upcoming) upcoming", systemImage: "clock.fill")
                    .font(.caption)
                    .foregroundColor(.modusCyan)
            }
            if missed > 0 {
                Label("\(missed) missed", systemImage: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(DesignTokens.statusError)
            }
            if sessions.isEmpty {
                Label("Rest day", systemImage: "bed.double")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.modusLightTeal)
        .cornerRadius(CornerRadius.md)
    }

    private var emptyDayView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 40))
                .foregroundColor(.modusTealAccent.opacity(0.4))

            Text("No workouts on this day")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button(action: onSchedule) {
                Label("Schedule Workout", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.modusCyan)
                    .cornerRadius(CornerRadius.sm)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
    }
}

// MARK: - Legacy Support: ScheduledSessionRow (used by other views)

struct ScheduledSessionRow: View {
    let session: ScheduledSession

    var body: some View {
        HStack(spacing: 12) {
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
        case .scheduled: return .modusCyan
        case .completed: return .modusTealAccent
        case .cancelled: return DesignTokens.statusError
        case .rescheduled: return DesignTokens.statusWarning
        }
    }
}

// MARK: - Conflict Details Sheet

/// Sheet displaying detailed calendar conflicts
struct ConflictDetailsSheet: View {
    let date: Date
    let conflicts: [CalendarConflictInfo]

    @Environment(\.dismiss) private var dismiss

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(DesignTokens.statusWarning)
                                .accessibilityHidden(true)

                            Text("\(conflicts.count) Calendar Event\(conflicts.count > 1 ? "s" : "")")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }

                        Text("You have existing commitments on this day. Consider scheduling your workout at a different time.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, Spacing.xs)
                }

                Section("Events") {
                    ForEach(conflicts) { conflict in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "calendar")
                                    .font(.caption)
                                    .foregroundColor(.modusCyan)
                                    .accessibilityHidden(true)

                                Text(conflict.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }

                            HStack {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .accessibilityHidden(true)

                                Text(conflict.timeRange)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, Spacing.xxs)
                    }
                }
            }
            .navigationTitle(Self.dateFormatter.string(from: date))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.modusCyan)
                }
            }
        }
    }
}

// MARK: - Preview

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView { date in
            print("Selected date: \(date)")
        }
    }
}
