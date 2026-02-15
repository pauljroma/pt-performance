//
//  StreakView.swift
//  PTPerformance
//
//  ACP-1004: Streak & Habit Mechanics
//  Main streak display view with flame animation, calendar heatmap,
//  milestone progress, and streak freeze status.
//

import SwiftUI

// MARK: - Streak View

/// Full-screen streak display with animated flame, heatmap calendar,
/// milestone progress bar, and sharing functionality.
struct StreakView: View {

    // MARK: - Properties

    @StateObject private var streakService = StreakService.shared
    @StateObject private var freezeService = StreakFreezeService.shared
    @State private var selectedMonth = Date()
    @State private var flameAnimating = false
    @State private var headerAppeared = false
    @State private var calendarAppeared = false
    @State private var showMilestoneView = false
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Animated streak header
                streakHeader
                    .opacity(headerAppeared ? 1 : 0)
                    .offset(y: headerAppeared ? 0 : 20)

                // Current vs Longest comparison
                streakComparison

                // Streak freeze status
                streakFreezeCard

                // Next milestone progress
                milestoneProgressCard

                // Calendar heatmap
                calendarHeatmap
                    .opacity(calendarAppeared ? 1 : 0)
                    .offset(y: calendarAppeared ? 0 : 15)

                // Share button
                shareButton
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
        .navigationTitle("Streak")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await streakService.checkStreak()
            await streakService.loadCalendarData()

            withAnimation(.easeOut(duration: AnimationDuration.standard)) {
                headerAppeared = true
            }
            withAnimation(.easeOut(duration: AnimationDuration.slow).delay(0.2)) {
                calendarAppeared = true
            }
        }
        .fullScreenCover(isPresented: $showMilestoneView) {
            if let milestone = streakService.pendingMilestone {
                StreakMilestoneView(
                    milestone: milestone,
                    currentStreak: streakService.currentStreak,
                    onDismiss: {
                        streakService.clearPendingMilestone()
                        showMilestoneView = false
                    }
                )
            }
        }
        .onChange(of: streakService.pendingMilestone) { _, milestone in
            if milestone != nil {
                showMilestoneView = true
            }
        }
    }

    // MARK: - Streak Header

    private var streakHeader: some View {
        VStack(spacing: Spacing.sm) {
            // Animated flame icon
            ZStack {
                // Glow rings for higher streak levels
                if streakService.flameLevel.glowRings > 0 {
                    ForEach(0..<streakService.flameLevel.glowRings, id: \.self) { ring in
                        Circle()
                            .stroke(Color.orange.opacity(0.15 - Double(ring) * 0.05), lineWidth: 2)
                            .frame(
                                width: 80 + CGFloat(ring) * 20,
                                height: 80 + CGFloat(ring) * 20
                            )
                            .scaleEffect(flameAnimating ? 1.1 : 1.0)
                            .animation(
                                .easeInOut(duration: 1.5 + Double(ring) * 0.3)
                                    .repeatForever(autoreverses: true),
                                value: flameAnimating
                            )
                    }
                }

                Image(systemName: streakService.flameLevel.iconName)
                    .font(.system(size: 48 * streakService.flameLevel.sizeMultiplier))
                    .foregroundStyle(
                        streakService.currentStreak > 0
                            ? LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                            : LinearGradient(
                                colors: [.gray.opacity(0.5), .gray],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                    )
                    .scaleEffect(flameAnimating ? 1.05 : 1.0)
                    .animation(
                        streakService.flameLevel.shouldAnimate
                            ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true)
                            : .default,
                        value: flameAnimating
                    )
            }
            .onAppear {
                flameAnimating = true
            }
            .accessibilityHidden(true)

            // Streak count
            Text("\(streakService.currentStreak)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .contentTransition(.numericText())
                .accessibilityLabel("\(streakService.currentStreak) day streak")

            Text(streakService.currentStreak == 1 ? "Day Streak" : "Day Streak!")
                .font(.title3.weight(.medium))
                .foregroundColor(.secondary)

            // Risk badge or safe badge
            if streakService.todayCompleted {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(DesignTokens.statusSuccess)
                    Text("Streak Protected")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(DesignTokens.statusSuccess)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(DesignTokens.statusSuccess.opacity(0.1))
                .cornerRadius(CornerRadius.xl)
            } else if streakService.streakAtRisk {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(DesignTokens.statusWarning)
                    Text("Streak at Risk!")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(DesignTokens.statusWarning)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(DesignTokens.statusWarning.opacity(0.1))
                .cornerRadius(CornerRadius.xl)
            }

            // Motivational message
            Text(streakService.motivationalMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.md)
        }
        .padding(.vertical, Spacing.lg)
    }

    // MARK: - Streak Comparison

    private var streakComparison: some View {
        HStack(spacing: Spacing.md) {
            // Current streak
            VStack(spacing: Spacing.xxs) {
                Text("Current")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(streakService.currentStreak)")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.modusCyan)
                Text("days")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)

            // vs divider
            Text("vs")
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)

            // Longest streak
            VStack(spacing: Spacing.xxs) {
                Text("Longest")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(streakService.longestStreak)")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.orange)
                Text("days")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current streak \(streakService.currentStreak) days. Longest streak \(streakService.longestStreak) days.")
    }

    // MARK: - Streak Freeze Card

    private var streakFreezeCard: some View {
        Card {
            HStack {
                Image(systemName: "shield.fill")
                    .font(.title3)
                    .foregroundColor(DesignTokens.statusInfo)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Streak Shields")
                        .font(.subheadline.weight(.semibold))
                    Text(freezeStatusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Freeze count indicator
                HStack(spacing: Spacing.xxs) {
                    ForEach(0..<freezeService.inventory.maxFreezes, id: \.self) { index in
                        Image(systemName: index < streakService.freezesAvailable ? "shield.fill" : "shield")
                            .font(.caption)
                            .foregroundColor(index < streakService.freezesAvailable ? DesignTokens.statusInfo : .gray.opacity(0.3))
                    }
                }

                // Use freeze button (only when at risk)
                if streakService.streakAtRisk && streakService.freezesAvailable > 0 {
                    Button(action: {
                        HapticFeedback.medium()
                        _ = streakService.useStreakFreeze()
                    }) {
                        Text("Use")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background(DesignTokens.statusInfo)
                            .cornerRadius(CornerRadius.sm)
                    }
                    .accessibilityLabel("Use streak shield")
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Streak shields. \(freezeStatusText)")
    }

    private var freezeStatusText: String {
        let available = streakService.freezesAvailable
        if available == 0 {
            return "No shields available. Earn more at streak milestones."
        }
        let noun = available == 1 ? "shield" : "shields"
        if streakService.freezeUsedThisWeek {
            return "\(available) \(noun) available. 1 used this week."
        }
        return "\(available) \(noun) available to protect your streak."
    }

    // MARK: - Milestone Progress

    private var milestoneProgressCard: some View {
        Group {
            if let progress = streakService.nextMilestoneProgress() {
                Card {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(.orange)
                                .accessibilityHidden(true)
                            Text("Next Milestone")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("\(progress.milestone) Days")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.orange)
                        }

                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: CornerRadius.xs)
                                    .fill(Color(.tertiarySystemGroupedBackground))
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: CornerRadius.xs)
                                    .fill(
                                        LinearGradient(
                                            colors: [.modusCyan, .orange],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(
                                        width: geometry.size.width * CGFloat(progress.progress),
                                        height: 8
                                    )
                                    .animation(.easeInOut(duration: AnimationDuration.slow), value: progress.progress)
                            }
                        }
                        .frame(height: 8)

                        HStack {
                            Text("\(streakService.currentStreak) days")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(progress.milestone - streakService.currentStreak) days to go")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    "Next milestone at \(progress.milestone) days. \(progress.milestone - streakService.currentStreak) days to go."
                )
            }
        }
    }

    // MARK: - Calendar Heatmap

    private var calendarHeatmap: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Activity")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                // Month navigation
                HStack(spacing: Spacing.md) {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.modusCyan)
                    }
                    .accessibilityLabel("Previous month")

                    Text(monthYearString(for: selectedMonth))
                        .font(.subheadline.weight(.medium))
                        .frame(minWidth: 120)

                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.modusCyan)
                    }
                    .disabled(Calendar.current.isDate(selectedMonth, equalTo: Date(), toGranularity: .month))
                    .accessibilityLabel("Next month")
                }
            }

            // Weekday headers
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: Spacing.xxs) {
                ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { day in
                    Text(String(day.prefix(1)))
                        .font(.caption2.weight(.medium))
                        .foregroundColor(.secondary)
                        .frame(height: 20)
                }
            }

            // Calendar grid
            let monthData = calendarDaysForMonth(selectedMonth)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: Spacing.xxs) {
                ForEach(monthData, id: \.self) { date in
                    if let date = date {
                        calendarDayCell(date: date)
                    } else {
                        Color.clear
                            .frame(height: 32)
                    }
                }
            }

            // Legend
            HStack(spacing: Spacing.md) {
                legendItem(color: Color.modusCyan.opacity(0.15), label: "No activity")
                legendItem(color: Color.modusCyan, label: "Active")
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .padding(Spacing.md)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private func calendarDayCell(date: Date) -> some View {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let isToday = calendar.isDateInToday(date)
        let isActive = streakService.calendarData[startOfDay] ?? false
        let isFuture = date > Date()

        return ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.xs)
                .fill(
                    isFuture
                        ? Color.clear
                        : isActive
                            ? Color.modusCyan
                            : Color.modusCyan.opacity(0.08)
                )
                .frame(height: 32)

            Text("\(calendar.component(.day, from: date))")
                .font(.caption2.weight(isToday ? .bold : .regular))
                .foregroundColor(
                    isFuture
                        ? .secondary.opacity(0.3)
                        : isActive
                            ? .white
                            : .primary
                )

            if isToday {
                RoundedRectangle(cornerRadius: CornerRadius.xs)
                    .stroke(Color.modusCyan, lineWidth: 2)
                    .frame(height: 32)
            }
        }
        .accessibilityLabel(
            "\(calendar.component(.day, from: date)): \(isActive ? "Active" : "No activity")"
        )
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: Spacing.xxs) {
            RoundedRectangle(cornerRadius: Spacing.xxs)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Share Button

    private var shareButton: some View {
        ShareLink(
            item: "I'm on a \(streakService.currentStreak)-day training streak with Modus Performance! #ConsistencyWins"
        ) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Share Streak")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.modusCyan)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(Color.modusCyan.opacity(0.1))
            .cornerRadius(CornerRadius.md)
        }
        .accessibilityLabel("Share your streak")
    }

    // MARK: - Month Helpers

    private func previousMonth() {
        HapticFeedback.selectionChanged()
        withAnimation {
            selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
        }
    }

    private func nextMonth() {
        HapticFeedback.selectionChanged()
        withAnimation {
            selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
        }
    }

    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    private func monthYearString(for date: Date) -> String {
        Self.monthYearFormatter.string(from: date)
    }

    /// Build an array of optional Dates for the calendar grid.
    /// `nil` entries represent empty cells before the first day of the month.
    private func calendarDaysForMonth(_ month: Date) -> [Date?] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))
        else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        // Calendar.current.firstWeekday is typically 1 (Sunday) in US locale
        let leadingBlanks = (firstWeekday - calendar.firstWeekday + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        return days
    }
}

// MARK: - Preview

#if DEBUG
struct StreakView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            StreakView()
        }
    }
}
#endif
