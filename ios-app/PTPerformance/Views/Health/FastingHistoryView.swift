import SwiftUI

/// Calendar view of fasting history with stats and compliance tracking (ACP-1004)
struct FastingHistoryView: View {
    @StateObject private var viewModel = FastingHistoryViewModel()
    @State private var selectedDate: Date = Date()
    @State private var selectedPeriod: HistoryPeriod = .week

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.fastingLogs.isEmpty {
                    // Loading state - show skeleton
                    ScrollView {
                        VStack(spacing: Spacing.lg) {
                            periodSelector
                            loadingSkeletonView
                        }
                        .padding()
                    }
                } else if let error = viewModel.error {
                    // Error state with retry
                    errorView(error: error)
                } else {
                    // Content
                    ScrollView {
                        VStack(spacing: Spacing.lg) {
                            // Period Selector
                            periodSelector

                            // Calendar View
                            calendarSection

                            // Stats Overview
                            statsOverview

                            // Streak History
                            streakSection

                            // Detailed History List
                            historyListSection
                        }
                        .padding()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Fasting History")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadHistory()
            }
            .refreshable {
                await viewModel.loadHistory()
            }
        }
    }

    // MARK: - Loading Skeleton

    private var loadingSkeletonView: some View {
        VStack(spacing: Spacing.lg) {
            // Calendar skeleton
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemGroupedBackground))
                .frame(height: 320)
                .shimmer(isAnimating: true)

            // Stats skeleton
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .frame(height: 100)
                        .shimmer(isAnimating: true)
                }
            }

            // Streak skeleton
            HStack(spacing: Spacing.md) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .frame(height: 120)
                        .shimmer(isAnimating: true)
                }
            }
        }
    }

    // MARK: - Error View

    private func errorView(error: String) -> some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Unable to Load History")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                Task {
                    await viewModel.loadHistory()
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.md)
                .background(Color.modusCyan)
                .cornerRadius(CornerRadius.lg)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(HistoryPeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPeriod = period
                    }
                    HapticFeedback.selectionChanged()
                } label: {
                    Text(period.displayName)
                        .font(.subheadline)
                        .fontWeight(selectedPeriod == period ? .semibold : .regular)
                        .foregroundColor(selectedPeriod == period ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            selectedPeriod == period
                                ? Color.modusCyan
                                : Color.clear
                        )
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Calendar Section

    private var calendarSection: some View {
        VStack(spacing: Spacing.sm) {
            // Month Header
            HStack {
                Button {
                    withAnimation {
                        selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.modusCyan)
                }

                Spacer()

                Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)

                Spacer()

                Button {
                    withAnimation {
                        selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.modusCyan)
                }
            }
            .padding(.horizontal)

            // Weekday Headers
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: Spacing.xs) {
                ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }

            // Calendar Days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: Spacing.xs) {
                ForEach(calendarDays, id: \.self) { date in
                    if let date = date {
                        CalendarDayCell(
                            date: date,
                            fastingLog: viewModel.fastingLog(for: date),
                            isToday: Calendar.current.isDateInToday(date),
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate)
                        ) {
                            selectedDate = date
                        }
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private var calendarDays: [Date?] {
        let calendar = Calendar.current
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate)),
              let monthRange = calendar.range(of: .day, in: .month, for: selectedDate) else {
            return []
        }
        let firstWeekday = calendar.component(.weekday, from: monthStart)

        var days: [Date?] = []

        // Add empty cells for days before month start
        for _ in 1..<firstWeekday {
            days.append(nil)
        }

        // Add actual days
        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                days.append(date)
            }
        }

        return days
    }

    // MARK: - Stats Overview

    private var statsOverview: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(selectedPeriod == .week ? "This Week" : "This Month")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.md) {
                FastingStatBox(
                    title: "Completed",
                    value: "\(viewModel.completedFasts(for: selectedPeriod))",
                    subtitle: "of \(viewModel.plannedFasts(for: selectedPeriod)) planned",
                    icon: "checkmark.circle.fill",
                    color: .modusTealAccent
                )

                FastingStatBox(
                    title: "Average Duration",
                    value: String(format: "%.1fh", viewModel.averageDuration(for: selectedPeriod)),
                    subtitle: "per fast",
                    icon: "clock.fill",
                    color: .modusCyan
                )

                FastingStatBox(
                    title: "Compliance",
                    value: "\(Int(viewModel.compliance(for: selectedPeriod) * 100))%",
                    subtitle: "goal completion",
                    icon: "chart.bar.fill",
                    color: .purple
                )

                FastingStatBox(
                    title: "Longest Fast",
                    value: String(format: "%.1fh", viewModel.longestFast(for: selectedPeriod)),
                    subtitle: "this period",
                    icon: "trophy.fill",
                    color: .orange
                )
            }
        }
    }

    // MARK: - Streak Section

    private var streakSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Streaks")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)

            HStack(spacing: Spacing.md) {
                StreakCard(
                    title: "Current",
                    value: viewModel.currentStreak,
                    icon: "flame.fill",
                    color: .orange,
                    isActive: viewModel.currentStreak > 0
                )

                StreakCard(
                    title: "Best",
                    value: viewModel.bestStreak,
                    icon: "trophy.fill",
                    color: .yellow,
                    isActive: false
                )

                StreakCard(
                    title: "This Month",
                    value: viewModel.monthlyStreak,
                    icon: "calendar",
                    color: .modusCyan,
                    isActive: false
                )
            }
        }
    }

    // MARK: - History List Section

    private var historyListSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Recent Fasts")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)

            if viewModel.recentFasts.isEmpty {
                FastingEmptyHistoryView()
            } else {
                ForEach(viewModel.recentFasts) { fast in
                    FastingLogRow(fast: fast)
                }
            }
        }
    }
}

// MARK: - History Period

enum HistoryPeriod: String, CaseIterable {
    case week
    case month

    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        }
    }
}

// MARK: - Calendar Day Cell

private struct CalendarDayCell: View {
    let date: Date
    let fastingLog: FastingLog?
    let isToday: Bool
    let isSelected: Bool
    let onTap: () -> Void

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var completionStatus: CompletionStatus {
        guard let log = fastingLog else { return .none }
        guard let actualHours = log.actualHours else { return .inProgress }

        if actualHours >= Double(log.targetHours) * 0.9 {
            return .completed
        } else {
            return .partial
        }
    }

    private var accessibilityLabelText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        let dateString = formatter.string(from: date)

        switch completionStatus {
        case .completed:
            return "\(dateString), fast completed"
        case .partial:
            return "\(dateString), fast partially completed"
        case .inProgress:
            return "\(dateString), fast in progress"
        case .none:
            return dateString
        }
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 36, height: 36)

                // Day Number
                Text(dayNumber)
                    .font(.subheadline)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundColor(textColor)

                // Completion Indicator
                if completionStatus != .none {
                    Circle()
                        .fill(indicatorColor)
                        .frame(width: 6, height: 6)
                        .offset(y: 14)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(height: 40)
        .accessibilityLabel(accessibilityLabelText)
    }

    private var backgroundColor: Color {
        if isSelected {
            return .modusCyan
        } else if isToday {
            return .modusCyan.opacity(0.2)
        } else if completionStatus == .completed {
            return .modusTealAccent.opacity(0.2)
        }
        return .clear
    }

    private var textColor: Color {
        if isSelected {
            return .white
        } else if date > Date() {
            return .secondary
        }
        return .primary
    }

    private var indicatorColor: Color {
        switch completionStatus {
        case .completed: return .modusTealAccent
        case .partial: return .orange
        case .inProgress: return .modusCyan
        case .none: return .clear
        }
    }

    enum CompletionStatus {
        case completed
        case partial
        case inProgress
        case none
    }
}

// MARK: - Fasting Stat Box

private struct FastingStatBox: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Streak Card

private struct StreakCard: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color
    let isActive: Bool

    var body: some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                if isActive {
                    Circle()
                        .stroke(color, lineWidth: 2)
                        .frame(width: 50, height: 50)
                        .scaleEffect(1.2)
                        .opacity(0.5)
                }
            }

            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Fasting Log Row

private struct FastingLogRow: View {
    let fast: FastingLog

    private var completionPercentage: Double {
        guard let actualHours = fast.actualHours else {
            return fast.progressPercent
        }
        return min(actualHours / Double(fast.targetHours), 1.0)
    }

    private var isCompleted: Bool {
        completionPercentage >= 0.9
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Completion indicator
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                    .frame(width: 44, height: 44)

                Circle()
                    .trim(from: 0, to: completionPercentage)
                    .stroke(
                        isCompleted ? Color.modusTealAccent : Color.orange,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))

                Image(systemName: isCompleted ? "checkmark" : "clock")
                    .font(.caption)
                    .foregroundColor(isCompleted ? .modusTealAccent : .orange)
            }

            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(fast.fastingType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(fast.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Duration
            VStack(alignment: .trailing, spacing: 2) {
                if let actualHours = fast.actualHours {
                    Text(String(format: "%.1fh", actualHours))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isCompleted ? .modusTealAccent : .orange)
                } else {
                    Text("In Progress")
                        .font(.caption)
                        .foregroundColor(.modusCyan)
                }

                Text("of \(fast.targetHours)h goal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Fasting Empty History View

private struct FastingEmptyHistoryView: View {
    var body: some View {
        EmptyStateView(
            title: "Start Your First Fast",
            message: "Begin your intermittent fasting journey to track progress, build streaks, and optimize your health.",
            icon: "timer",
            iconColor: .modusCyan
        )
        .padding(.vertical, Spacing.md)
    }
}

// MARK: - Preview

#if DEBUG
struct FastingHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        FastingHistoryView()
    }
}
#endif
