//
//  LeaderboardView.swift
//  PTPerformance
//
//  ACP-997: Leaderboard & Competition
//  Rankings view with podium display, category tabs, and pinned current user
//

import SwiftUI

// MARK: - Leaderboard View

/// Main leaderboard screen with period/category tabs, podium, and scrollable rankings
struct LeaderboardView: View {

    // MARK: - Properties

    @StateObject private var service = LeaderboardService.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var animatePodium = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Period picker (Weekly / All-Time)
                periodPicker

                // Category picker
                categoryPicker

                // Main content
                if service.isLoading && service.activeLeaderboard.isEmpty {
                    loadingView
                } else if service.activeLeaderboard.isEmpty {
                    emptyStateView
                } else {
                    leaderboardContent
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        HapticFeedback.light()
                        dismiss()
                    }
                }
            }
            .task {
                await service.refreshLeaderboard()
                withAnimation(.easeOut(duration: AnimationDuration.slow).delay(0.2)) {
                    animatePodium = true
                }
            }
        }
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(LeaderboardPeriod.allCases) { period in
                Button {
                    Task {
                        await service.selectPeriod(period)
                    }
                } label: {
                    Text(period.displayName)
                        .font(.subheadline)
                        .fontWeight(service.selectedPeriod == period ? .semibold : .regular)
                        .foregroundColor(service.selectedPeriod == period ? .white : .primary)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background(
                            service.selectedPeriod == period
                                ? Color.modusCyan
                                : Color(.tertiarySystemFill)
                        )
                        .cornerRadius(CornerRadius.sm)
                }
                .accessibilityLabel("\(period.displayName) leaderboard")
                .accessibilityAddTraits(service.selectedPeriod == period ? .isSelected : [])
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color(.systemBackground))
    }

    // MARK: - Category Picker

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(LeaderboardType.allCases) { type in
                    Button {
                        Task {
                            await service.selectType(type)
                        }
                    } label: {
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: type.iconName)
                                .font(.caption)
                            Text(type.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(service.selectedType == type ? .modusCyan : .secondary)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(
                            service.selectedType == type
                                ? Color.modusCyan.opacity(0.12)
                                : Color(.tertiarySystemFill)
                        )
                        .cornerRadius(CornerRadius.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.sm)
                                .stroke(
                                    service.selectedType == type ? Color.modusCyan.opacity(0.3) : Color.clear,
                                    lineWidth: 1
                                )
                        )
                    }
                    .accessibilityLabel("\(type.displayName) category")
                    .accessibilityAddTraits(service.selectedType == type ? .isSelected : [])
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Leaderboard Content

    private var leaderboardContent: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Podium for top 3
                    if service.podiumEntries.count >= 3 {
                        podiumSection
                    }

                    // Remaining rankings
                    rankingsList

                    // Bottom padding for pinned user
                    if let _ = service.currentUserEntry, !service.isCurrentUserVisible {
                        Spacer().frame(height: 80)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)
            }
            .refreshableWithHaptic {
                service.invalidateCache()
                await service.refreshLeaderboard()
            }

            // Pinned current user at bottom
            if let userEntry = service.currentUserEntry,
               !isUserInTopEntries(userEntry) {
                pinnedCurrentUser(userEntry)
            }
        }
    }

    /// Check if user is already in the visible top entries
    private func isUserInTopEntries(_ entry: LeaderboardEntry) -> Bool {
        service.activeLeaderboard.prefix(20).contains { $0.isCurrentUser }
    }

    // MARK: - Podium Section

    private var podiumSection: some View {
        let entries = service.podiumEntries

        return VStack(spacing: Spacing.sm) {
            HStack(alignment: .bottom, spacing: Spacing.sm) {
                // 2nd place (left)
                if entries.count > 1 {
                    podiumEntry(entries[1], height: 100)
                }

                // 1st place (center, tallest)
                if entries.count > 0 {
                    podiumEntry(entries[0], height: 130)
                }

                // 3rd place (right)
                if entries.count > 2 {
                    podiumEntry(entries[2], height: 80)
                }
            }
            .padding(.top, Spacing.lg)
            .opacity(animatePodium ? 1 : 0)
            .offset(y: animatePodium ? 0 : 30)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.modusCyan.opacity(0.08),
                            Color(.systemBackground)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
    }

    private func podiumEntry(_ entry: LeaderboardEntry, height: CGFloat) -> some View {
        VStack(spacing: Spacing.xs) {
            // Medal
            if let medalColor = entry.medalColor {
                ZStack {
                    Circle()
                        .fill(medalColor.opacity(0.2))
                        .frame(width: entry.rank == 1 ? 56 : 48, height: entry.rank == 1 ? 56 : 48)

                    // Avatar / initial
                    Text(String(entry.displayName.prefix(1)).uppercased())
                        .font(entry.rank == 1 ? .title2 : .title3)
                        .fontWeight(.bold)
                        .foregroundColor(medalColor)
                }
            }

            // Name
            Text(entry.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .foregroundColor(entry.isCurrentUser ? .modusCyan : .primary)

            // Score
            Text(entry.formattedScore(for: service.selectedType))
                .font(.caption2)
                .foregroundColor(.secondary)

            // Podium bar
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(
                    entry.medalColor?.opacity(0.3) ?? Color(.tertiarySystemFill)
                )
                .frame(height: height)
                .overlay(alignment: .top) {
                    // Rank number
                    Text("\(entry.rank)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(entry.medalColor ?? .secondary)
                        .padding(.top, Spacing.sm)
                }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Rankings List

    private var rankingsList: some View {
        VStack(spacing: Spacing.xs) {
            // Show all entries (including top 3 in the list for completeness)
            let entriesToShow = service.activeLeaderboard.count > 3
                ? Array(service.activeLeaderboard.dropFirst(3))
                : service.activeLeaderboard

            ForEach(entriesToShow) { entry in
                rankingRow(entry)
            }
        }
    }

    private func rankingRow(_ entry: LeaderboardEntry) -> some View {
        HStack(spacing: Spacing.md) {
            // Rank number
            Text("\(entry.rank)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(entry.isCurrentUser ? .modusCyan : .secondary)
                .frame(width: 32, alignment: .center)

            // Avatar
            ZStack {
                Circle()
                    .fill(
                        entry.isCurrentUser
                            ? Color.modusCyan.opacity(0.15)
                            : Color(.tertiarySystemFill)
                    )
                    .frame(width: 40, height: 40)

                Text(String(entry.displayName.prefix(1)).uppercased())
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(entry.isCurrentUser ? .modusCyan : .secondary)
            }

            // Name and streak
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack(spacing: Spacing.xxs) {
                    Text(entry.displayName)
                        .font(.subheadline)
                        .fontWeight(entry.isCurrentUser ? .bold : .medium)
                        .foregroundColor(entry.isCurrentUser ? .modusCyan : .primary)

                    if entry.isCurrentUser {
                        Text("YOU")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, Spacing.xxs)
                            .padding(.vertical, 1)
                            .background(Color.modusCyan)
                            .cornerRadius(CornerRadius.xs)
                    }
                }

                if entry.streak > 0 {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text("\(entry.streak)d streak")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Score
            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text(entry.formattedScore(for: service.selectedType))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(entry.isCurrentUser ? .modusCyan : .primary)

                Text(service.selectedType.scoreUnit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            entry.isCurrentUser
                ? Color.modusCyan.opacity(0.06)
                : Color(.systemBackground)
        )
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(
                    entry.isCurrentUser ? Color.modusCyan.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
    }

    // MARK: - Pinned Current User

    private func pinnedCurrentUser(_ entry: LeaderboardEntry) -> some View {
        VStack(spacing: 0) {
            Divider()

            rankingRow(entry)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(
                    Color(.systemBackground)
                        .shadow(
                            color: Shadow.medium.color(for: colorScheme),
                            radius: Shadow.medium.radius,
                            x: Shadow.medium.x,
                            y: -Shadow.medium.y
                        )
                )
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
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
            message: "Complete workouts to appear on the leaderboard. Rankings update weekly.",
            icon: "trophy",
            iconColor: .modusCyan
        )
    }
}

// MARK: - Preview

#if DEBUG
struct LeaderboardView_Previews: PreviewProvider {
    static var previews: some View {
        LeaderboardView()
    }
}
#endif
