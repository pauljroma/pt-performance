//
//  StreakDashboardView.swift
//  PTPerformance
//
//  ACP-836: Streak Tracking Feature
//  ACP-1029: Streak System Gamification - Streak freezes, comeback mechanics, milestone celebrations
//  Main streak display with current and longest streaks
//

import SwiftUI
import Charts

/// Dashboard view displaying streak statistics, streak freeze management, and progress
/// ACP-1029: Enhanced with streak freezes, comeback banners, growing flame, and milestone celebrations
struct StreakDashboardView: View {
    // MARK: - Properties

    let patientId: UUID

    @StateObject private var viewModel: StreakDashboardViewModel
    @StateObject private var freezeService = StreakFreezeService.shared
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Initialization

    init(patientId: UUID) {
        self.patientId = patientId
        _viewModel = StateObject(wrappedValue: StreakDashboardViewModel(patientId: patientId))
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isLoading && viewModel.streaks.isEmpty {
                    loadingView
                } else if viewModel.hasData {
                    contentView
                } else {
                    emptyStateView
                }
            }
            .padding()
        }
        .navigationTitle("Streaks")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            HapticFeedback.light()
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadData()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        // ACP-1029: Streak freeze used confirmation
        .overlay(alignment: .top) {
            if freezeService.showFreezeUsedConfirmation {
                StreakFreezeUsedBanner(remainingFreezes: freezeService.inventory.availableCount)
                    .padding()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        VStack(spacing: 20) {
            // ACP-1029: Comeback banner (if returning after a break)
            if let comebackState = freezeService.comebackState {
                ComebackWelcomeBanner(comebackState: comebackState)
            }

            // Current streak hero card
            currentStreakCard

            // ACP-1029: Streak freeze management card
            streakFreezeCard

            // Streak type selector
            streakTypeSelector

            // Statistics row
            statisticsRow

            // Calendar preview (recent 14 days) with density colors
            calendarPreview

            // Badge progress
            badgeProgressCard

            // ACP-1029: Flame level progress
            flameLevelCard

            // Achievements link
            NavigationLink {
                AchievementsDashboardView(patientId: patientId)
            } label: {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                    Text("View All Achievements")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .adaptiveShadow(Shadow.subtle)
                )
            }
            .buttonStyle(.plain)

            // Navigation to full calendar
            NavigationLink {
                StreakCalendarView(patientId: patientId)
            } label: {
                HStack {
                    Image(systemName: "calendar")
                    Text("View Full Calendar")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .adaptiveShadow(Shadow.subtle)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Current Streak Card

    private var currentStreakCard: some View {
        VStack(spacing: 16) {
            // ACP-1029: Growing flame icon instead of static icon
            GrowingFlameIcon(streak: viewModel.currentStreak, size: 32, showLabel: true)
                .frame(height: 120)

            // Streak count
            VStack(spacing: 4) {
                Text("\(viewModel.currentStreak)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(viewModel.currentStreak == 1 ? "day" : "days")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Current streak: \(viewModel.currentStreak) \(viewModel.currentStreak == 1 ? "day" : "days")")

            // Motivational message
            Text(viewModel.motivationalMessage)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            // Streak status indicator
            HStack(spacing: 8) {
                if viewModel.isAtRisk {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(DesignTokens.statusWarning)
                    Text("Complete a workout to keep your streak!")
                        .font(.caption)
                        .foregroundColor(DesignTokens.statusWarning)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.modusTealAccent)
                    Text("Streak safe for today!")
                        .font(.caption)
                        .foregroundColor(Color.modusTealAccent)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(viewModel.isAtRisk ? DesignTokens.statusWarning.opacity(0.1) : Color.modusTealAccent.opacity(0.1))
            )

            // Longest streak
            HStack {
                Text("Longest Streak")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                    Text("\(viewModel.longestStreak) days")
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemGroupedBackground))
                .adaptiveShadow(Shadow.medium)
        )
    }

    // MARK: - ACP-1029: Streak Freeze Card

    private var streakFreezeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shield.checkered")
                    .foregroundColor(Color.modusTealAccent)
                Text("Streak Shields")
                    .font(.headline)
                Spacer()
            }

            // Freeze inventory display
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { index in
                    ZStack {
                        Circle()
                            .fill(index < freezeService.inventory.availableCount
                                  ? Color.modusTealAccent.opacity(0.2)
                                  : Color.gray.opacity(0.1))
                            .frame(width: 50, height: 50)

                        Image(systemName: "shield.checkered")
                            .font(.title2)
                            .foregroundColor(index < freezeService.inventory.availableCount
                                             ? Color.modusTealAccent
                                             : .gray.opacity(0.3))
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(freezeService.inventory.availableCount) of 3")
                        .font(.headline)
                        .foregroundColor(Color.modusTealAccent)
                    Text("Available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Use freeze button (only if streak is at risk)
            if viewModel.isAtRisk && freezeService.inventory.availableCount > 0 && viewModel.currentStreak > 0 {
                Button(action: {
                    HapticFeedback.medium()
                    _ = freezeService.useFreeze()
                }) {
                    HStack {
                        Image(systemName: "shield.checkered")
                        Text("Use Streak Shield Today")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        LinearGradient(
                            colors: [Color.modusCyan, Color.modusTealAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(CornerRadius.md)
                }
                .accessibilityLabel("Use streak shield. \(freezeService.inventory.availableCount) \(freezeService.inventory.availableCount == 1 ? "shield" : "shields") available")
            }

            // Next freeze earned info
            if let nextFreezeInfo = freezeService.nextFreezeEarnedDescription(currentStreak: viewModel.currentStreak) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "gift.fill")
                        .font(.caption)
                        .foregroundColor(Color.modusCyan)

                    Text(nextFreezeInfo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Description
            Text("Earn shields by reaching streak milestones. Use them to protect your streak on rest days.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemGroupedBackground))
                .adaptiveShadow(Shadow.medium)
        )
    }

    // MARK: - Streak Type Selector

    private var streakTypeSelector: some View {
        Picker("Streak Type", selection: $viewModel.selectedType) {
            ForEach(StreakType.allCases) { type in
                Label(type.displayName, systemImage: type.iconName)
                    .tag(type)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: viewModel.selectedType) { _, newValue in
            viewModel.selectStreakType(newValue)
        }
    }

    // MARK: - Statistics Row

    private var statisticsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                statisticCard(
                    title: "This Week",
                    value: "\(viewModel.thisWeekDays)",
                    icon: "calendar.badge.clock",
                    color: Color.modusCyan
                )

                statisticCard(
                    title: "This Month",
                    value: "\(viewModel.thisMonthDays)",
                    icon: "calendar",
                    color: Color.modusTealAccent
                )

                statisticCard(
                    title: "Total Days",
                    value: "\(viewModel.totalActivityDays)",
                    icon: "checkmark.circle.fill",
                    color: Color.modusDeepTeal
                )

                statisticCard(
                    title: "Badge Level",
                    value: viewModel.badgeLevel.displayName,
                    icon: viewModel.badgeLevel.iconName,
                    color: viewModel.badgeLevel.color
                )
            }
            .padding(.horizontal)
        }
    }

    private func statisticCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(.primary)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(width: 130, height: 100)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.secondarySystemGroupedBackground))
                .adaptiveShadow(Shadow.subtle)
        )
    }

    // MARK: - Calendar Preview (ACP-1029: Color-coded density)

    private var calendarPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                Spacer()
                Text("Last 14 days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(viewModel.recentActivityDays, id: \.self) { date in
                    let hasActivity = viewModel.hasActivity(on: date)
                    let density = viewModel.activityDensity(on: date)

                    VStack(spacing: 2) {
                        Text(dayLetter(for: date))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)

                        // ACP-1029: Color-coded density circles using Modus colors
                        Circle()
                            .fill(densityColor(for: density))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Group {
                                    if Calendar.current.isDateInToday(date) {
                                        Circle()
                                            .stroke(Color.modusCyan, lineWidth: 2)
                                    }
                                }
                            )
                            .overlay(
                                Text(String(Calendar.current.component(.day, from: date)))
                                    .font(.system(size: 12, weight: hasActivity ? .bold : .regular))
                                    .foregroundColor(hasActivity ? .white : .secondary)
                            )
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(dayLetter(for: date)), day \(Calendar.current.component(.day, from: date)). \(densityAccessibilityLabel(for: density))\(Calendar.current.isDateInToday(date) ? ". Today" : "")")
                }
            }

            // ACP-1029: Density legend
            HStack(spacing: 16) {
                densityLegendItem(density: .none, text: "Rest")
                densityLegendItem(density: .light, text: "Light")
                densityLegendItem(density: .moderate, text: "Moderate")
                densityLegendItem(density: .high, text: "Full")
            }
            .font(.caption)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemGroupedBackground))
                .adaptiveShadow(Shadow.medium)
        )
    }

    private static let dayLetterFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEEE" // Single letter day
        return f
    }()

    private func dayLetter(for date: Date) -> String {
        Self.dayLetterFormatter.string(from: date)
    }

    /// ACP-1029: Color based on activity density using Modus brand colors
    private func densityColor(for density: ActivityDensity) -> Color {
        switch density {
        case .none: return Color.gray.opacity(0.15)
        case .light: return Color.modusCyan.opacity(0.4)
        case .moderate: return Color.modusTealAccent.opacity(0.7)
        case .high: return Color.modusTealAccent
        }
    }

    private func densityAccessibilityLabel(for density: ActivityDensity) -> String {
        switch density {
        case .none: return "Rest day"
        case .light: return "Light activity"
        case .moderate: return "Moderate activity"
        case .high: return "Full activity"
        }
    }

    private func densityLegendItem(density: ActivityDensity, text: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(densityColor(for: density))
                .frame(width: 8, height: 8)
            Text(text)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Badge Progress Card

    private var badgeProgressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Badge Progress")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 16) {
                // Current badge
                VStack(spacing: 4) {
                    Image(systemName: viewModel.badgeLevel.iconName)
                        .font(.system(size: 32))
                        .foregroundColor(viewModel.badgeLevel.color)

                    Text(viewModel.badgeLevel.displayName)
                        .font(.caption.weight(.semibold))
                }

                // Progress to next badge
                if let nextBadge = viewModel.badgeLevel.nextBadge {
                    VStack(spacing: 4) {
                        let progress = viewModel.progressToNextBadge

                        ProgressView(value: progress)
                            .tint(Color.modusCyan)
                            .frame(width: 80)

                        Text("\(viewModel.daysToNextBadge) days to \(nextBadge.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Image(systemName: nextBadge.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(.secondary.opacity(0.5))
                } else {
                    Text("Maximum badge achieved!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemGroupedBackground))
                .adaptiveShadow(Shadow.medium)
        )
    }

    // MARK: - ACP-1029: Flame Level Card

    private var flameLevelCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Flame Level")
                    .font(.headline)
                Spacer()
                Text(StreakFlameLevel.level(for: viewModel.currentStreak).displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.modusCyan)
            }

            // All flame levels in a horizontal row
            HStack(spacing: 0) {
                ForEach(StreakFlameLevel.allCases, id: \.self) { level in
                    let isAchieved = viewModel.currentStreak >= level.rawValue
                    let isCurrent = StreakFlameLevel.level(for: viewModel.currentStreak) == level

                    VStack(spacing: 4) {
                        ZStack {
                            if isCurrent {
                                Circle()
                                    .fill(Color.modusCyan.opacity(0.15))
                                    .frame(width: 36, height: 36)
                            }

                            Image(systemName: level.iconName)
                                .font(.system(size: 16 * (isCurrent ? 1.2 : 1.0)))
                                .foregroundColor(isAchieved ? Color.modusCyan : .gray.opacity(0.3))
                        }
                        .frame(height: 36)

                        Text(level.displayName)
                            .font(.system(size: 8))
                            .foregroundColor(isAchieved ? .primary : .secondary)

                        Text("\(level.rawValue)d")
                            .font(.system(size: 7))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(level.displayName) flame level, \(level.rawValue) days. \(isCurrent ? "Current level" : isAchieved ? "Achieved" : "Locked")")
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemGroupedBackground))
                .adaptiveShadow(Shadow.medium)
        )
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading streak data...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        EmptyStateView(
            title: "Start Your Streak",
            message: "Complete workouts and arm care sessions to build your streak. Consistency is key to achieving your fitness and recovery goals.",
            icon: "flame",
            iconColor: Color.modusCyan,
            action: EmptyStateView.EmptyStateAction(
                title: "View Today's Workout",
                icon: "figure.strengthtraining.traditional",
                action: {
                    // Navigate back to today tab - this will be handled by the navigation stack
                }
            )
        )
        .padding(.top, 40)
    }
}

// MARK: - ViewModel

@MainActor
class StreakDashboardViewModel: ObservableObject {
    // MARK: - Properties

    private let patientId: UUID
    private let service: StreakTrackingService

    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var streaks: [StreakRecord] = []
    @Published var statistics: [StreakStatistics] = []
    @Published var historyEntries: [CalendarHistoryEntry] = []
    @Published var selectedType: StreakType = .combined

    // MARK: - Initialization

    init(patientId: UUID, service: StreakTrackingService? = nil) {
        self.patientId = patientId
        self.service = service ?? StreakTrackingService.shared
    }

    // MARK: - Computed Properties

    var hasData: Bool {
        !streaks.isEmpty || !historyEntries.isEmpty
    }

    var currentStreak: Int {
        selectedStreakRecord?.currentStreak ?? 0
    }

    var longestStreak: Int {
        selectedStreakRecord?.longestStreak ?? 0
    }

    var isAtRisk: Bool {
        selectedStreakRecord?.isAtRisk ?? true
    }

    var motivationalMessage: String {
        selectedStreakRecord?.motivationalMessage ?? "Start your streak today!"
    }

    var badgeLevel: StreakBadge {
        StreakBadge.badge(for: longestStreak)
    }

    var thisWeekDays: Int {
        selectedStatistics?.thisWeekDays ?? 0
    }

    var thisMonthDays: Int {
        selectedStatistics?.thisMonthDays ?? 0
    }

    var totalActivityDays: Int {
        selectedStatistics?.totalActivityDays ?? 0
    }

    var recentActivityDays: [Date] {
        // Return last 14 days
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<14).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: today)
        }.reversed()
    }

    var progressToNextBadge: Double {
        guard let nextBadge = badgeLevel.nextBadge else { return 1.0 }
        let currentDays = longestStreak
        let currentBadgeMin = badgeLevel.minDays
        let nextBadgeMin = nextBadge.minDays
        let progress = Double(currentDays - currentBadgeMin) / Double(nextBadgeMin - currentBadgeMin)
        return min(max(progress, 0), 1)
    }

    var daysToNextBadge: Int {
        guard let nextBadge = badgeLevel.nextBadge else { return 0 }
        return max(0, nextBadge.minDays - longestStreak)
    }

    private var selectedStreakRecord: StreakRecord? {
        streaks.first { $0.streakType == selectedType }
    }

    private var selectedStatistics: StreakStatistics? {
        statistics.first { $0.type == selectedType }
    }

    // MARK: - Methods

    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let fetchStreaks = service.fetchCurrentStreaks(for: patientId)
            async let fetchStats = service.getStreakStatistics(for: patientId)
            async let fetchHistory = service.getStreakHistory(for: patientId, days: 30)

            let (streakResults, statsResults, historyResults) = try await (fetchStreaks, fetchStats, fetchHistory)

            self.streaks = streakResults
            self.statistics = statsResults
            self.historyEntries = historyResults

            // ACP-1029: Evaluate comeback state and milestone checks
            if let combinedStreak = streakResults.first(where: { $0.streakType == .combined }) {
                StreakFreezeService.shared.evaluateComebackState(
                    currentStreak: combinedStreak.currentStreak,
                    lastActivityDate: combinedStreak.lastActivityDate
                )
                StreakFreezeService.shared.checkMilestone(for: combinedStreak.currentStreak)
                StreakFreezeService.shared.checkAndAwardFreezes(for: combinedStreak.currentStreak)
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func refresh() async {
        await loadData()
    }

    func selectStreakType(_ type: StreakType) {
        selectedType = type
    }

    func hasActivity(on date: Date) -> Bool {
        let calendar = Calendar.current
        return historyEntries.contains { entry in
            calendar.isDate(entry.activityDate, inSameDayAs: date) && entry.hasAnyActivity
        }
    }

    func activityType(on date: Date) -> StreakType {
        let calendar = Calendar.current
        guard let entry = historyEntries.first(where: { calendar.isDate($0.activityDate, inSameDayAs: date) }) else {
            return .combined
        }

        if entry.workoutCompleted && entry.armCareCompleted {
            return .combined
        } else if entry.workoutCompleted {
            return .workout
        } else if entry.armCareCompleted {
            return .armCare
        }
        return .combined
    }

    /// ACP-1029: Get activity density for a date
    func activityDensity(on date: Date) -> ActivityDensity {
        let calendar = Calendar.current
        let entry = historyEntries.first { calendar.isDate($0.activityDate, inSameDayAs: date) }
        return ActivityDensity.density(from: entry)
    }
}

// MARK: - Previews

#Preview("With Data") {
    NavigationStack {
        StreakDashboardView(patientId: UUID())
    }
}

#Preview("Empty State") {
    NavigationStack {
        StreakDashboardView(patientId: UUID())
    }
}
