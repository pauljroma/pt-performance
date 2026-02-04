//
//  StreakDashboardView.swift
//  PTPerformance
//
//  ACP-836: Streak Tracking Feature
//  Main streak display with current and longest streaks
//

import SwiftUI
import Charts

/// Dashboard view displaying streak statistics and progress
struct StreakDashboardView: View {
    // MARK: - Properties

    let patientId: UUID

    @StateObject private var viewModel: StreakDashboardViewModel
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
    }

    // MARK: - Content View

    private var contentView: some View {
        VStack(spacing: 20) {
            // Current streak hero card
            currentStreakCard

            // Streak type selector
            streakTypeSelector

            // Statistics row
            statisticsRow

            // Calendar preview (recent 14 days)
            calendarPreview

            // Badge progress
            badgeProgressCard

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
                    RoundedRectangle(cornerRadius: 12)
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
                    RoundedRectangle(cornerRadius: 12)
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
            // Streak flame animation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [viewModel.selectedType.color.opacity(0.3), viewModel.selectedType.color.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 120, height: 120)

                VStack(spacing: 4) {
                    Image(systemName: viewModel.selectedType.iconName)
                        .font(.system(size: 32))
                        .foregroundColor(viewModel.selectedType.color)

                    Text("\(viewModel.currentStreak)")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text(viewModel.currentStreak == 1 ? "day" : "days")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Motivational message
            Text(viewModel.motivationalMessage)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            // Streak status indicator
            HStack(spacing: 8) {
                if viewModel.isAtRisk {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Complete a workout to keep your streak!")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Streak safe for today!")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(viewModel.isAtRisk ? Color.orange.opacity(0.1) : Color.green.opacity(0.1))
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
            RoundedRectangle(cornerRadius: 16)
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
                    color: .blue
                )

                statisticCard(
                    title: "This Month",
                    value: "\(viewModel.thisMonthDays)",
                    icon: "calendar",
                    color: .green
                )

                statisticCard(
                    title: "Total Days",
                    value: "\(viewModel.totalActivityDays)",
                    icon: "checkmark.circle.fill",
                    color: .purple
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
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
                .adaptiveShadow(Shadow.subtle)
        )
    }

    // MARK: - Calendar Preview

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
                    let activityType = viewModel.activityType(on: date)

                    VStack(spacing: 2) {
                        Text(dayLetter(for: date))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)

                        Circle()
                            .fill(hasActivity ? activityType.color : Color.gray.opacity(0.2))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Group {
                                    if Calendar.current.isDateInToday(date) {
                                        Circle()
                                            .stroke(Color.primary, lineWidth: 2)
                                    }
                                }
                            )
                            .overlay(
                                Text(String(Calendar.current.component(.day, from: date)))
                                    .font(.system(size: 12, weight: hasActivity ? .bold : .regular))
                                    .foregroundColor(hasActivity ? .white : .secondary)
                            )
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

    private func dayLetter(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE" // Single letter day
        return formatter.string(from: date)
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
                            .tint(nextBadge.color)
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
            RoundedRectangle(cornerRadius: 16)
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
            iconColor: .orange,
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
