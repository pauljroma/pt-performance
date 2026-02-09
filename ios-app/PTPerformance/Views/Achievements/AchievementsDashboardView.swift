//
//  AchievementsDashboardView.swift
//  PTPerformance
//
//  Gamification Polish - Milestone Celebrations & Achievements
//  Dashboard showing all achievements, progress, and recent unlocks
//

import SwiftUI

// MARK: - Dashboard Tab

enum AchievementDashboardTab: String, CaseIterable, Identifiable {
    case achievements = "achievements"
    case leaderboard = "leaderboard"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .achievements: return "Achievements"
        case .leaderboard: return "Leaderboard"
        }
    }

    var icon: String {
        switch self {
        case .achievements: return "trophy.fill"
        case .leaderboard: return "chart.bar.fill"
        }
    }
}

// MARK: - Achievements Dashboard View

struct AchievementsDashboardView: View {
    let patientId: UUID

    @StateObject private var achievementService = AchievementService.shared
    @State private var selectedTab: AchievementDashboardTab = .achievements
    @State private var selectedFilter: AchievementFilter = .all
    @State private var selectedAchievement: AchievementProgress?
    @State private var showShareSheet = false
    @State private var shareText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            tabSelector
                .padding(.horizontal)
                .padding(.top, Spacing.sm)

            // Content based on selected tab
            if selectedTab == .achievements {
                achievementsContent
            } else {
                AchievementLeaderboardView(patientId: patientId)
            }
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            HapticFeedback.light()
            await achievementService.loadAchievements()
            await achievementService.checkAllAchievements()
        }
        .task {
            await achievementService.initialize(for: patientId)
        }
        .sheet(item: $selectedAchievement) { achievement in
            AchievementDetailSheet(progress: achievement, onShare: {
                shareText = AchievementService.shared.shareAchievement(achievement.definition)
                showShareSheet = true
            })
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareText])
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(AchievementDashboardTab.allCases) { tab in
                Button(action: {
                    HapticFeedback.selectionChanged()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: tab.icon)
                            .font(.subheadline)
                        Text(tab.displayName)
                            .font(.subheadline)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(selectedTab == tab ? Color.blue : Color(.tertiarySystemGroupedBackground))
                    )
                    .foregroundColor(selectedTab == tab ? .white : .primary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(tab.displayName) tab")
                .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Dashboard tabs")
    }

    // MARK: - Achievements Content

    private var achievementsContent: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Points and stats header
                statsHeader

                // Up Next recommendations section
                if !upNextAchievements.isEmpty {
                    UpNextAchievementsSection(
                        achievements: upNextAchievements
                    ) { achievement in
                        selectedAchievement = achievement
                    }
                }

                // Recent unlocks section
                if !recentUnlocks.isEmpty {
                    recentUnlocksSection
                }

                // Filter tabs
                filterTabs

                // Achievements grid/list
                achievementsSection
            }
            .padding()
        }
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        VStack(spacing: Spacing.md) {
            // Total points
            HStack(spacing: Spacing.lg) {
                VStack {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .accessibilityHidden(true)
                        Text("\(achievementService.totalPoints)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                    }
                    Text("Total Points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(achievementService.totalPoints) total points")

                Divider()
                    .frame(height: 50)
                    .accessibilityHidden(true)

                VStack {
                    Text("\(unlockedCount)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                    Text("Unlocked")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(unlockedCount) achievements unlocked")

                Divider()
                    .frame(height: 50)
                    .accessibilityHidden(true)

                VStack {
                    Text("\(AchievementCatalog.all.count - unlockedCount)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    Text("Remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(AchievementCatalog.all.count - unlockedCount) achievements remaining")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .adaptiveShadow(Shadow.medium)

            // Progress bar
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text("Overall Progress")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(Int(overallProgress * 100))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }

                ProgressView(value: overallProgress)
                    .tint(.blue)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Overall progress: \(Int(overallProgress * 100)) percent")
        }
    }

    // MARK: - Recent Unlocks Section

    private var recentUnlocksSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                    .accessibilityHidden(true)
                Text("Recently Unlocked")
                    .font(.headline)
                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel("Recently unlocked achievements")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(recentUnlocks.prefix(5)) { achievement in
                        RecentAchievementCard(progress: achievement) {
                            selectedAchievement = achievement
                        }
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }

    // MARK: - Filter Tabs

    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(AchievementFilter.allCases) { filter in
                    FilterChip(
                        label: filter.displayName,
                        icon: filter.icon,
                        color: filter.color,
                        isSelected: selectedFilter == filter
                    ) {
                        HapticFeedback.selectionChanged()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = filter
                        }
                    }
                    .accessibilityLabel("\(filter.displayName) filter")
                    .accessibilityAddTraits(selectedFilter == filter ? .isSelected : [])
                }
            }
            .padding(.horizontal, 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Achievement category filters")
    }

    // MARK: - Achievements Section

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text(selectedFilter == .all ? "All Achievements" : selectedFilter.displayName)
                    .font(.headline)
                Spacer()
                Text("\(filteredAchievements.count) achievements")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel("\(selectedFilter == .all ? "All Achievements" : selectedFilter.displayName), \(filteredAchievements.count) achievements")

            if filteredAchievements.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(filteredAchievements) { achievement in
                        AchievementCardView(progress: achievement) {
                            selectedAchievement = achievement
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: selectedFilter.icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No \(selectedFilter.displayName.lowercased()) achievements yet")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Keep working out to unlock achievements!")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }

    // MARK: - Computed Properties

    private var unlockedCount: Int {
        achievementService.achievementProgress.filter { $0.isUnlocked }.count
    }

    private var overallProgress: Double {
        guard !achievementService.achievementProgress.isEmpty else { return 0 }
        return Double(unlockedCount) / Double(AchievementCatalog.all.count)
    }

    private var recentUnlocks: [AchievementProgress] {
        achievementService.achievementProgress
            .filter { $0.isUnlocked }
            .sorted { ($0.unlockedAt ?? .distantPast) > ($1.unlockedAt ?? .distantPast) }
    }

    /// Achievements closest to being unlocked (for "Up Next" section)
    private var upNextAchievements: [AchievementProgress] {
        AchievementRecommendations.getNextGoals(
            from: achievementService.achievementProgress,
            limit: 3
        )
    }

    private var filteredAchievements: [AchievementProgress] {
        let achievements = achievementService.achievementProgress

        switch selectedFilter {
        case .all:
            return achievements.sorted { !$0.isUnlocked && $1.isUnlocked }
        case .unlocked:
            return achievements.filter { $0.isUnlocked }
                .sorted { ($0.unlockedAt ?? .distantPast) > ($1.unlockedAt ?? .distantPast) }
        case .inProgress:
            return achievements.filter { !$0.isUnlocked && $0.progress > 0 }
                .sorted { $0.progress > $1.progress }
        case .streak:
            return achievements.filter { $0.definition.type == .streak }
        case .workouts:
            return achievements.filter { $0.definition.type == .workouts }
        case .prs:
            return achievements.filter { $0.definition.type == .personalRecord }
        case .volume:
            return achievements.filter { $0.definition.type == .volume }
        }
    }
}

// MARK: - Achievement Filter

enum AchievementFilter: String, CaseIterable, Identifiable {
    case all
    case unlocked
    case inProgress
    case streak
    case workouts
    case prs
    case volume

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return "All"
        case .unlocked: return "Unlocked"
        case .inProgress: return "In Progress"
        case .streak: return "Streaks"
        case .workouts: return "Workouts"
        case .prs: return "PRs"
        case .volume: return "Volume"
        }
    }

    var icon: String {
        switch self {
        case .all: return "trophy.fill"
        case .unlocked: return "checkmark.circle.fill"
        case .inProgress: return "arrow.up.circle"
        case .streak: return "flame.fill"
        case .workouts: return "figure.strengthtraining.traditional"
        case .prs: return "trophy.fill"
        case .volume: return "scalemass.fill"
        }
    }

    var color: Color {
        switch self {
        case .all: return .blue
        case .unlocked: return .green
        case .inProgress: return .orange
        case .streak: return .orange
        case .workouts: return .green
        case .prs: return .yellow
        case .volume: return .blue
        }
    }
}

// MARK: - Recent Achievement Card

struct RecentAchievementCard: View {
    let progress: AchievementProgress
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap()
        }) {
            VStack(spacing: Spacing.sm) {
                AchievementBadgeView(
                    definition: progress.definition,
                    isUnlocked: true,
                    size: 50,
                    showTier: false
                )

                Text(progress.definition.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)

                if let date = progress.unlockedAt {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 100)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(progress.definition.tier.color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(progress.definition.title), \(progress.definition.tier.displayName) tier, unlocked \(progress.unlockedAt?.formatted(date: .abbreviated, time: .omitted) ?? "recently")")
        .accessibilityHint("Tap for details")
    }
}

// MARK: - Achievement Detail Sheet

struct AchievementDetailSheet: View {
    let progress: AchievementProgress
    let onShare: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Badge
                    AchievementBadgeView(
                        definition: progress.definition,
                        isUnlocked: progress.isUnlocked,
                        size: 120
                    )
                    .padding(.top, Spacing.xl)

                    // Info
                    VStack(spacing: Spacing.sm) {
                        // Tier badge
                        Text(progress.definition.tier.displayName.uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(progress.definition.tier.color)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.xxs)
                            .background(
                                Capsule()
                                    .fill(progress.definition.tier.color.opacity(0.2))
                            )

                        Text(progress.definition.title)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(progress.definition.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Progress or unlock date
                    if progress.isUnlocked {
                        VStack(spacing: Spacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.green)

                            if let date = progress.unlockedAt {
                                Text("Unlocked on \(date.formatted(date: .long, time: .omitted))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("\(progress.definition.tier.points) points earned")
                                    .fontWeight(.medium)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .fill(Color.green.opacity(0.1))
                        )
                    } else {
                        VStack(spacing: Spacing.sm) {
                            Text("Progress")
                                .font(.headline)

                            ProgressView(value: progress.progress)
                                .tint(progress.definition.type.color)
                                .frame(height: 8)
                                .clipShape(Capsule())

                            Text("\(progress.currentValue) / \(progress.definition.requirement) \(progress.definition.requirementUnit)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text("\(progress.remainingValue) more to unlock!")
                                .font(.caption)
                                .foregroundColor(progress.definition.type.color)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                    }

                    // Share button (if unlocked)
                    if progress.isUnlocked {
                        Button(action: {
                            HapticFeedback.light()
                            onShare()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Achievement")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(progress.definition.tier.color)
                            .cornerRadius(CornerRadius.md)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
            .navigationTitle("Achievement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct AchievementsDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AchievementsDashboardView(patientId: UUID())
        }
    }
}
#endif
