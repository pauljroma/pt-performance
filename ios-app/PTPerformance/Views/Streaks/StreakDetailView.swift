//
//  StreakDetailView.swift
//  PTPerformance
//
//  ACP-836: Streak Tracking Feature
//  ACP-1029: Streak System Gamification - Growing flame icons, Modus brand colors
//  Detailed streak statistics and achievements
//

import SwiftUI
import Charts

/// Detailed view showing comprehensive streak statistics and achievements
struct StreakDetailView: View {
    // MARK: - Properties

    let patientId: UUID
    let streakType: StreakType

    @StateObject private var viewModel: StreakDetailViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    init(patientId: UUID, streakType: StreakType) {
        self.patientId = patientId
        self.streakType = streakType
        _viewModel = StateObject(wrappedValue: StreakDetailViewModel(patientId: patientId, streakType: streakType))
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero section with streak info
                heroSection

                // Weekly activity chart
                weeklyActivityChart

                // Streak milestones
                milestonesSection

                // Historical streaks
                historicalStreaksSection

                // Tips for maintaining streak
                tipsSection
            }
            .padding()
        }
        .navigationTitle("\(streakType.displayName) Streak")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 20) {
            // ACP-1029: Growing flame icon that upgrades at milestones
            GrowingFlameIcon(streak: viewModel.currentStreak, size: 36, showLabel: true)
                .frame(height: 140)

            // Streak count
            VStack(spacing: 4) {
                Text("\(viewModel.currentStreak)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Status message
            VStack(spacing: 8) {
                Text(viewModel.motivationalMessage)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)

                if let startDate = viewModel.streakStartDate {
                    Text("Started \(startDate, style: .date)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Key stats
            HStack(spacing: 32) {
                VStack(spacing: 4) {
                    Text("\(viewModel.longestStreak)")
                        .font(.title2.bold())
                    Text("Best")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text("\(viewModel.totalDays)")
                        .font(.title2.bold())
                    Text("Total Days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text("\(viewModel.thisMonthDays)")
                        .font(.title2.bold())
                    Text("This Month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
    }

    // MARK: - Weekly Activity Chart

    private var weeklyActivityChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Activity")
                .font(.headline)

            // Weekly breakdown
            HStack(spacing: 8) {
                ForEach(viewModel.weeklyActivity, id: \.date) { day in
                    VStack(spacing: 8) {
                        // ACP-1029: Day indicator with Modus colors
                        Circle()
                            .fill(day.hasActivity ? Color.modusTealAccent : Color.gray.opacity(0.2))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: day.hasActivity ? "checkmark" : "")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .overlay(
                                Group {
                                    if Calendar.current.isDateInToday(day.date) {
                                        Circle()
                                            .stroke(Color.accentColor, lineWidth: 2)
                                    }
                                }
                            )

                        Text(day.dayLetter)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // This week summary
            HStack {
                Text("\(viewModel.thisWeekDays) of 7 days completed")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(Double(viewModel.thisWeekDays) / 7.0 * 100))%")
                    .font(.subheadline.weight(.semibold))
            }

            ProgressView(value: Double(viewModel.thisWeekDays) / 7.0)
                .tint(Color.modusCyan)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .adaptiveShadow(Shadow.medium)
        )
    }

    // MARK: - Milestones Section

    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Milestones")
                .font(.headline)

            VStack(spacing: 12) {
                ForEach(StreakBadge.allCases, id: \.self) { badge in
                    milestoneRow(badge: badge)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .adaptiveShadow(Shadow.medium)
        )
    }

    private func milestoneRow(badge: StreakBadge) -> some View {
        let isAchieved = viewModel.longestStreak >= badge.minDays
        let isCurrent = viewModel.badgeLevel == badge

        return HStack(spacing: 12) {
            // Badge icon
            ZStack {
                Circle()
                    .fill(isAchieved ? badge.color.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: badge.iconName)
                    .font(.system(size: 20))
                    .foregroundColor(isAchieved ? badge.color : .gray)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(badge.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(isAchieved ? .primary : .secondary)

                    if isCurrent {
                        Text("Current")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(badge.color.opacity(0.2))
                            .foregroundColor(badge.color)
                            .cornerRadius(CornerRadius.xs)
                    }
                }

                Text("\(badge.minDays)+ days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isAchieved {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                let daysNeeded = badge.minDays - viewModel.longestStreak
                Text("\(daysNeeded) to go")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Historical Streaks Section

    private var historicalStreaksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Streaks")
                .font(.headline)

            if viewModel.recentStreakHistory.isEmpty {
                Text("Complete more activities to see your streak history")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(viewModel.recentStreakHistory.prefix(5), id: \.startDate) { streak in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(streak.length) days")
                                .font(.subheadline.weight(.semibold))

                            Text("\(streak.startDate, style: .date) - \(streak.endDate, style: .date)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // Streak length indicator
                        RoundedRectangle(cornerRadius: 4)
                            .fill(streakType.color.opacity(Double(streak.length) / Double(max(viewModel.longestStreak, 1))))
                            .frame(width: CGFloat(min(streak.length * 3, 80)), height: 8)
                    }
                    .padding(.vertical, 4)

                    if streak.startDate != viewModel.recentStreakHistory.last?.startDate {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .adaptiveShadow(Shadow.medium)
        )
    }

    // MARK: - Tips Section

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Tips for Success")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 8) {
                tipRow(icon: "clock.fill", text: "Set a consistent time each day for your \(streakType.displayName.lowercased())")
                tipRow(icon: "bell.badge.fill", text: "Enable notifications to remind you before the day ends")
                tipRow(icon: "calendar", text: "Plan your week ahead to maintain consistency")
                tipRow(icon: "person.2.fill", text: "Share your progress with friends for accountability")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.yellow.opacity(0.1))
        )
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 20)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - ViewModel

@MainActor
class StreakDetailViewModel: ObservableObject {
    // MARK: - Types

    struct WeekDay {
        let date: Date
        let dayLetter: String
        let hasActivity: Bool
    }

    struct StreakPeriod {
        let startDate: Date
        let endDate: Date
        let length: Int
    }

    // MARK: - Properties

    private let patientId: UUID
    private let streakType: StreakType
    private let service: StreakTrackingService
    private let calendar = Calendar.current

    @Published var currentStreak = 0
    @Published var longestStreak = 0
    @Published var totalDays = 0
    @Published var thisWeekDays = 0
    @Published var thisMonthDays = 0
    @Published var streakStartDate: Date?
    @Published var historyEntries: [CalendarHistoryEntry] = []

    // MARK: - Initialization

    init(patientId: UUID, streakType: StreakType, service: StreakTrackingService? = nil) {
        self.patientId = patientId
        self.streakType = streakType
        self.service = service ?? StreakTrackingService.shared
    }

    // MARK: - Computed Properties

    var motivationalMessage: String {
        StreakBadge.badge(for: currentStreak).description
    }

    var badgeLevel: StreakBadge {
        StreakBadge.badge(for: longestStreak)
    }

    var weeklyActivity: [WeekDay] {
        let today = calendar.startOfDay(for: Date())
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return []
        }

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: startOfWeek) else {
                return nil
            }
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEEE"

            let hasActivity = historyEntries.contains { entry in
                calendar.isDate(entry.activityDate, inSameDayAs: date) && activityMatchesType(entry)
            }

            return WeekDay(
                date: date,
                dayLetter: dayFormatter.string(from: date),
                hasActivity: hasActivity
            )
        }
    }

    var recentStreakHistory: [StreakPeriod] {
        // Analyze history to find streak periods
        var periods: [StreakPeriod] = []
        var currentPeriodStart: Date?
        var currentPeriodEnd: Date?
        var currentPeriodLength = 0

        let sortedEntries = historyEntries
            .filter { activityMatchesType($0) }
            .sorted { $0.activityDate < $1.activityDate }

        for entry in sortedEntries {
            if let lastEnd = currentPeriodEnd {
                let daysDiff = calendar.dateComponents([.day], from: lastEnd, to: entry.activityDate).day ?? 0

                if daysDiff == 1 {
                    // Consecutive day, extend streak
                    currentPeriodEnd = entry.activityDate
                    currentPeriodLength += 1
                } else {
                    // Gap found, save current streak and start new one
                    if let start = currentPeriodStart, currentPeriodLength > 0 {
                        periods.append(StreakPeriod(startDate: start, endDate: lastEnd, length: currentPeriodLength))
                    }
                    currentPeriodStart = entry.activityDate
                    currentPeriodEnd = entry.activityDate
                    currentPeriodLength = 1
                }
            } else {
                // Start first streak
                currentPeriodStart = entry.activityDate
                currentPeriodEnd = entry.activityDate
                currentPeriodLength = 1
            }
        }

        // Save last streak
        if let start = currentPeriodStart, let end = currentPeriodEnd, currentPeriodLength > 0 {
            periods.append(StreakPeriod(startDate: start, endDate: end, length: currentPeriodLength))
        }

        // Return sorted by most recent first
        return periods.sorted { $0.endDate > $1.endDate }
    }

    // MARK: - Methods

    func loadData() async {
        do {
            async let fetchStats = service.getStreakStatistics(for: patientId)
            async let fetchHistory = service.getStreakHistory(for: patientId, days: 90)

            let (stats, history) = try await (fetchStats, fetchHistory)

            if let typeStat = stats.first(where: { $0.type == streakType }) {
                currentStreak = typeStat.currentStreak
                longestStreak = typeStat.longestStreak
                totalDays = typeStat.totalActivityDays
                thisWeekDays = typeStat.thisWeekDays
                thisMonthDays = typeStat.thisMonthDays
                streakStartDate = typeStat.streakStartDate
            }

            historyEntries = history
        } catch {
            DebugLogger.shared.warning("StreakDetailView", "Error loading data: \(error.localizedDescription)")
        }
    }

    private func activityMatchesType(_ entry: CalendarHistoryEntry) -> Bool {
        switch streakType {
        case .workout: return entry.workoutCompleted
        case .armCare: return entry.armCareCompleted
        case .combined: return entry.hasAnyActivity
        }
    }
}

// MARK: - Previews

#Preview("Workout Streak") {
    NavigationStack {
        StreakDetailView(patientId: UUID(), streakType: .workout)
    }
}

#Preview("Arm Care Streak") {
    NavigationStack {
        StreakDetailView(patientId: UUID(), streakType: .armCare)
    }
}

#Preview("Combined Streak") {
    NavigationStack {
        StreakDetailView(patientId: UUID(), streakType: .combined)
    }
}
