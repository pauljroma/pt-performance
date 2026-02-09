//
//  AchievementLeaderboardView.swift
//  PTPerformance
//
//  Gamification Polish - Leaderboard for patient rankings
//  Shows top performers with points and achievement counts
//

import SwiftUI

// MARK: - Leaderboard Time Filter

enum LeaderboardTimeFilter: String, CaseIterable, Identifiable {
    case weekly = "weekly"
    case monthly = "monthly"
    case allTime = "all_time"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weekly: return "This Week"
        case .monthly: return "This Month"
        case .allTime: return "All Time"
        }
    }

    var icon: String {
        switch self {
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar"
        case .allTime: return "star.fill"
        }
    }
}

// MARK: - Leaderboard Entry Model

struct LeaderboardEntry: Identifiable, Equatable {
    let id: UUID
    let rank: Int
    let displayName: String
    let avatarInitials: String
    let totalPoints: Int
    let achievementCount: Int
    let isCurrentUser: Bool
    let isOptedIn: Bool

    /// Anonymized display name for privacy
    var displayNameFormatted: String {
        if isCurrentUser {
            return "You"
        } else if isOptedIn {
            return displayName
        } else {
            return "Patient \(rank)"
        }
    }
}

// MARK: - Leaderboard Achievement Record

private struct LeaderboardAchievementRecord: Decodable {
    let patient_id: String
    let achievement_id: String
    let unlocked_at: String?
}

// MARK: - Leaderboard View Model

@MainActor
class LeaderboardViewModel: ObservableObject {
    @Published var entries: [LeaderboardEntry] = []
    @Published var currentUserEntry: LeaderboardEntry?
    @Published var selectedFilter: LeaderboardTimeFilter = .weekly
    @Published var isLoading = false
    @Published var error: Error?

    private let client = PTSupabaseClient.shared
    private let logger = DebugLogger.shared
    private var patientId: UUID?

    func initialize(for patientId: UUID) {
        self.patientId = patientId
        Task {
            await loadLeaderboard()
        }
    }

    func loadLeaderboard() async {
        guard let patientId = patientId else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch leaderboard data from server
            // In a real implementation, this would be a server-side aggregation
            let response = try await client.client
                .from("patient_achievements")
                .select("patient_id, achievement_id, unlocked_at")
                .execute()

            // Process and aggregate the data
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let records = try decoder.decode([LeaderboardAchievementRecord].self, from: response.data)

            // Filter by time period
            let filteredRecords = filterRecordsByTime(records)

            // Aggregate by patient
            var patientStats: [String: (points: Int, count: Int)] = [:]

            for record in filteredRecords {
                let points = AchievementCatalog.get(record.achievement_id)?.tier.points ?? 0
                let current = patientStats[record.patient_id] ?? (points: 0, count: 0)
                patientStats[record.patient_id] = (points: current.points + points, count: current.count + 1)
            }

            // Sort and rank
            let sorted = patientStats.sorted { $0.value.points > $1.value.points }

            var entries: [LeaderboardEntry] = []
            for (index, item) in sorted.prefix(50).enumerated() {
                let isCurrentUser = item.key == patientId.uuidString
                let entry = LeaderboardEntry(
                    id: UUID(uuidString: item.key) ?? UUID(),
                    rank: index + 1,
                    displayName: isCurrentUser ? "You" : "Patient",
                    avatarInitials: isCurrentUser ? "ME" : "P\(index + 1)",
                    totalPoints: item.value.points,
                    achievementCount: item.value.count,
                    isCurrentUser: isCurrentUser,
                    isOptedIn: false // Would be fetched from user preferences
                )
                entries.append(entry)

                if isCurrentUser {
                    currentUserEntry = entry
                }
            }

            // If current user not in top 50, find their position
            if currentUserEntry == nil {
                if let userStats = patientStats[patientId.uuidString] {
                    let userRank = sorted.firstIndex { $0.key == patientId.uuidString }.map { $0 + 1 } ?? (sorted.count + 1)
                    currentUserEntry = LeaderboardEntry(
                        id: patientId,
                        rank: userRank,
                        displayName: "You",
                        avatarInitials: "ME",
                        totalPoints: userStats.points,
                        achievementCount: userStats.count,
                        isCurrentUser: true,
                        isOptedIn: true
                    )
                } else {
                    // User has no achievements yet
                    currentUserEntry = LeaderboardEntry(
                        id: patientId,
                        rank: sorted.count + 1,
                        displayName: "You",
                        avatarInitials: "ME",
                        totalPoints: 0,
                        achievementCount: 0,
                        isCurrentUser: true,
                        isOptedIn: true
                    )
                }
            }

            self.entries = entries

            logger.log("LeaderboardViewModel: Loaded \(entries.count) leaderboard entries", level: .success)
        } catch {
            self.error = error
            logger.log("LeaderboardViewModel: Failed to load leaderboard: \(error)", level: .warning)

            // Load sample data for preview/fallback
            loadSampleData(patientId: patientId)
        }
    }

    private func filterRecordsByTime(_ records: [LeaderboardAchievementRecord]) -> [LeaderboardAchievementRecord] {
        // In a real implementation, filter by unlocked_at date based on selectedFilter
        // For now, return all records
        return records
    }

    private func loadSampleData(patientId: UUID) {
        entries = LeaderboardEntry.sampleEntries
        currentUserEntry = entries.first { $0.isCurrentUser }
    }
}

// MARK: - Achievement Leaderboard View

struct AchievementLeaderboardView: View {
    let patientId: UUID

    @StateObject private var viewModel = LeaderboardViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Time filter tabs
            filterTabs
                .padding(.horizontal)
                .padding(.top, Spacing.sm)

            if viewModel.isLoading {
                loadingView
            } else if viewModel.entries.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    VStack(spacing: Spacing.md) {
                        // Current user rank card (if not in top 3)
                        if let userEntry = viewModel.currentUserEntry, userEntry.rank > 3 {
                            currentUserRankCard(entry: userEntry)
                                .padding(.horizontal)
                        }

                        // Top 3 podium
                        if viewModel.entries.count >= 3 {
                            podiumView
                                .padding(.horizontal)
                        }

                        // Leaderboard list
                        leaderboardList
                            .padding(.horizontal)
                    }
                    .padding(.vertical, Spacing.md)
                }
            }
        }
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.initialize(for: patientId)
        }
        .refreshable {
            HapticFeedback.light()
            await viewModel.loadLeaderboard()
        }
    }

    // MARK: - Filter Tabs

    private var filterTabs: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(LeaderboardTimeFilter.allCases) { filter in
                FilterChip(
                    label: filter.displayName,
                    icon: filter.icon,
                    color: .blue,
                    isSelected: viewModel.selectedFilter == filter
                ) {
                    HapticFeedback.selectionChanged()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedFilter = filter
                    }
                    Task {
                        await viewModel.loadLeaderboard()
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Time period filter")
    }

    // MARK: - Podium View

    private var podiumView: some View {
        HStack(alignment: .bottom, spacing: Spacing.md) {
            // Second place
            if viewModel.entries.count > 1 {
                podiumSpot(entry: viewModel.entries[1], height: 80, medalColor: .gray)
            }

            // First place
            podiumSpot(entry: viewModel.entries[0], height: 100, medalColor: .yellow)

            // Third place
            if viewModel.entries.count > 2 {
                podiumSpot(entry: viewModel.entries[2], height: 60, medalColor: colorFromName("bronze"))
            }
        }
        .padding(.vertical, Spacing.lg)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Top 3 performers")
    }

    private func podiumSpot(entry: LeaderboardEntry, height: CGFloat, medalColor: Color) -> some View {
        VStack(spacing: Spacing.xs) {
            // Avatar with medal
            ZStack {
                Circle()
                    .fill(
                        entry.isCurrentUser
                            ? LinearGradient(colors: [.blue, .blue.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [Color(.systemGray4), Color(.systemGray5)], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: entry.rank == 1 ? 70 : 55, height: entry.rank == 1 ? 70 : 55)
                    .overlay(
                        Circle()
                            .stroke(medalColor, lineWidth: 3)
                    )
                    .shadow(color: medalColor.opacity(0.5), radius: 8)

                Text(entry.avatarInitials)
                    .font(entry.rank == 1 ? .title2 : .headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                // Medal badge
                Image(systemName: "medal.fill")
                    .font(.caption)
                    .foregroundColor(medalColor)
                    .offset(x: entry.rank == 1 ? 25 : 20, y: entry.rank == 1 ? -25 : -20)
            }

            // Name
            Text(entry.displayNameFormatted)
                .font(.caption)
                .fontWeight(entry.isCurrentUser ? .bold : .medium)
                .foregroundColor(entry.isCurrentUser ? .blue : .primary)
                .lineLimit(1)

            // Points
            HStack(spacing: 2) {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.yellow)
                Text("\(entry.totalPoints)")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }

            // Podium block
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(medalColor.opacity(0.3))
                .frame(width: 70, height: height)
                .overlay(
                    Text("#\(entry.rank)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(medalColor)
                )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.displayNameFormatted), rank \(entry.rank), \(entry.totalPoints) points")
    }

    // MARK: - Current User Rank Card

    private func currentUserRankCard(entry: LeaderboardEntry) -> some View {
        HStack(spacing: Spacing.md) {
            // Rank
            Text("#\(entry.rank)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .frame(width: 50)

            // Avatar
            Circle()
                .fill(LinearGradient(colors: [.blue, .blue.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                .frame(width: 45, height: 45)
                .overlay(
                    Text(entry.avatarInitials)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text("Your Ranking")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("\(entry.achievementCount) achievements")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Points
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("\(entry.totalPoints)")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                Text("points")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your ranking: \(entry.rank), \(entry.totalPoints) points, \(entry.achievementCount) achievements")
    }

    // MARK: - Leaderboard List

    private var leaderboardList: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Rankings")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            LazyVStack(spacing: Spacing.xs) {
                ForEach(viewModel.entries.dropFirst(3)) { entry in
                    leaderboardRow(entry: entry)
                }
            }
        }
    }

    private func leaderboardRow(entry: LeaderboardEntry) -> some View {
        HStack(spacing: Spacing.md) {
            // Rank
            Text("#\(entry.rank)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(entry.isCurrentUser ? .blue : .secondary)
                .frame(width: 40, alignment: .leading)

            // Avatar
            Circle()
                .fill(
                    entry.isCurrentUser
                        ? LinearGradient(colors: [.blue, .blue.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [Color(.systemGray4), Color(.systemGray5)], startPoint: .top, endPoint: .bottom)
                )
                .frame(width: 36, height: 36)
                .overlay(
                    Text(entry.avatarInitials)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )

            // Name and achievements
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayNameFormatted)
                    .font(.subheadline)
                    .fontWeight(entry.isCurrentUser ? .bold : .medium)
                    .foregroundColor(entry.isCurrentUser ? .blue : .primary)

                Text("\(entry.achievementCount) achievements")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Points
            HStack(spacing: 2) {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundColor(.yellow)
                Text("\(entry.totalPoints)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(entry.isCurrentUser ? Color.blue.opacity(0.1) : Color(.secondarySystemGroupedBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.displayNameFormatted), rank \(entry.rank), \(entry.totalPoints) points, \(entry.achievementCount) achievements")
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading leaderboard...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        EmptyStateView(
            title: "No Rankings Yet",
            message: "Complete achievements to appear on the leaderboard!",
            icon: "trophy.fill",
            iconColor: .yellow
        )
    }
}

// MARK: - Preview Support

#if DEBUG
extension LeaderboardEntry {
    static let sampleEntries: [LeaderboardEntry] = [
        LeaderboardEntry(
            id: UUID(),
            rank: 1,
            displayName: "Champion",
            avatarInitials: "CH",
            totalPoints: 485,
            achievementCount: 15,
            isCurrentUser: false,
            isOptedIn: true
        ),
        LeaderboardEntry(
            id: UUID(),
            rank: 2,
            displayName: "Runner Up",
            avatarInitials: "RU",
            totalPoints: 410,
            achievementCount: 12,
            isCurrentUser: false,
            isOptedIn: true
        ),
        LeaderboardEntry(
            id: UUID(),
            rank: 3,
            displayName: "Bronze Star",
            avatarInitials: "BS",
            totalPoints: 350,
            achievementCount: 10,
            isCurrentUser: false,
            isOptedIn: true
        ),
        LeaderboardEntry(
            id: UUID(),
            rank: 4,
            displayName: "You",
            avatarInitials: "ME",
            totalPoints: 295,
            achievementCount: 8,
            isCurrentUser: true,
            isOptedIn: true
        ),
        LeaderboardEntry(
            id: UUID(),
            rank: 5,
            displayName: "Competitor",
            avatarInitials: "P5",
            totalPoints: 240,
            achievementCount: 7,
            isCurrentUser: false,
            isOptedIn: false
        ),
        LeaderboardEntry(
            id: UUID(),
            rank: 6,
            displayName: "Athlete",
            avatarInitials: "P6",
            totalPoints: 185,
            achievementCount: 6,
            isCurrentUser: false,
            isOptedIn: false
        ),
        LeaderboardEntry(
            id: UUID(),
            rank: 7,
            displayName: "Performer",
            avatarInitials: "P7",
            totalPoints: 150,
            achievementCount: 5,
            isCurrentUser: false,
            isOptedIn: false
        ),
        LeaderboardEntry(
            id: UUID(),
            rank: 8,
            displayName: "Trainee",
            avatarInitials: "P8",
            totalPoints: 120,
            achievementCount: 4,
            isCurrentUser: false,
            isOptedIn: false
        )
    ]
}

struct AchievementLeaderboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AchievementLeaderboardView(patientId: UUID())
        }
    }
}
#endif
