//
//  AchievementShowcaseView.swift
//  PTPerformance
//
//  ACP-1030: Achievement System Polish
//  Profile showcase displaying top achievements
//

import SwiftUI

/// Displays a user's top achievements on their profile
struct AchievementShowcaseView: View {
    let patientId: UUID
    @StateObject private var achievementService = AchievementService.shared
    @State private var selectedAchievement: AchievementProgress?
    @State private var showShareSheet = false
    @State private var shareText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header with navigation to full view
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Achievements")
                        .font(.headline)
                    Text("\(showcaseAchievements.count) unlocked")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                NavigationLink {
                    AchievementsDashboardView(patientId: patientId)
                } label: {
                    HStack(spacing: Spacing.xxs) {
                        Text("View All")
                            .font(.subheadline)
                            .foregroundColor(.modusCyan)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.modusCyan)
                    }
                }
                .accessibilityLabel("View all achievements")
            }
            .accessibilityElement(children: .contain)

            if showcaseAchievements.isEmpty {
                // Empty state
                EmptyShowcaseView()
            } else {
                // Achievement badges
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.md) {
                        ForEach(showcaseAchievements) { achievement in
                            ShowcaseAchievementBadge(progress: achievement) {
                                HapticFeedback.light()
                                selectedAchievement = achievement
                            }
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }

            // Points summary
            if achievementService.totalPoints > 0 {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                        .accessibilityHidden(true)
                    Text("\(achievementService.totalPoints) total points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("\(achievementService.totalPoints) total achievement points")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .adaptiveShadow(Shadow.subtle)
        .task {
            await achievementService.initialize(for: patientId)
        }
        .sheet(item: $selectedAchievement) { achievement in
            AchievementDetailSheet(progress: achievement, onShare: {
                shareText = AchievementShareHelper.shareText(
                    for: achievement.definition,
                    earnedDate: achievement.unlockedAt
                )
                selectedAchievement = nil
                showShareSheet = true
            })
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareText])
        }
    }

    /// Top 5 achievements to showcase (highest tier, most recent)
    private var showcaseAchievements: [AchievementProgress] {
        achievementService.achievementProgress
            .filter { $0.isUnlocked }
            .sorted { lhs, rhs in
                // Sort by tier (higher tier first), then by unlock date (most recent first)
                if lhs.definition.tier != rhs.definition.tier {
                    return lhs.definition.tier > rhs.definition.tier
                }
                let lhsDate = lhs.unlockedAt ?? .distantPast
                let rhsDate = rhs.unlockedAt ?? .distantPast
                return lhsDate > rhsDate
            }
            .prefix(5)
            .map { $0 }
    }
}

// MARK: - Showcase Achievement Badge

struct ShowcaseAchievementBadge: View {
    let progress: AchievementProgress
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.xs) {
                // Badge with glow
                AchievementBadgeView(
                    definition: progress.definition,
                    isUnlocked: true,
                    size: 64,
                    showTier: false,
                    animated: true
                )

                // Title
                Text(progress.definition.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .frame(width: 80)

                // Tier badge
                Text(progress.definition.tier.displayName)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(progress.definition.tier.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(progress.definition.tier.color.opacity(0.2))
                    )
            }
            .frame(width: 90)
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(progress.definition.title) achievement, \(progress.definition.tier.displayName) tier")
        .accessibilityHint("Tap for details")
    }
}

// MARK: - Empty Showcase View

struct EmptyShowcaseView: View {
    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "trophy")
                .font(.title)
                .foregroundColor(.secondary.opacity(0.5))
                .accessibilityHidden(true)

            Text("No achievements yet")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Complete workouts to unlock achievements!")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No achievements yet. Complete workouts to unlock achievements.")
    }
}

// MARK: - Preview

#if DEBUG
struct AchievementShowcaseView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack {
                AchievementShowcaseView(patientId: UUID())
                    .padding()
            }
        }
    }
}
#endif
