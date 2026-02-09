//
//  NextAchievementCard.swift
//  PTPerformance
//
//  Gamification Polish - Achievement Recommendations
//  Shows closest achievable milestones with progress and motivational messaging
//

import SwiftUI

// MARK: - Next Achievement Card

/// A motivational card showing the user's progress toward their next achievement
struct NextAchievementCard: View {
    let progress: AchievementProgress
    var onTap: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap?()
        }) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Header with badge and title
                HStack(spacing: Spacing.md) {
                    // Badge
                    AchievementBadgeView(
                        definition: progress.definition,
                        isUnlocked: false,
                        size: 50,
                        showTier: false
                    )

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        // Tier badge
                        Text(progress.definition.tier.displayName.uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(progress.definition.tier.color)
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(progress.definition.tier.color.opacity(0.15))
                            )

                        Text(progress.definition.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Text(progress.definition.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    // Points badge
                    VStack(spacing: 2) {
                        Text("+\(progress.definition.tier.points)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(progress.definition.tier.color)
                        Text("pts")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                }

                // Progress section
                VStack(spacing: Spacing.xs) {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(height: 8)

                            // Progress fill
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            progress.definition.type.color,
                                            progress.definition.type.color.opacity(0.7)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * progress.progress, height: 8)
                                .animation(.easeInOut(duration: 0.5), value: progress.progress)
                        }
                    }
                    .frame(height: 8)

                    // Progress text
                    HStack {
                        Text(motivationalMessage)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(progress.definition.type.color)

                        Spacer()

                        Text("\(progress.progressPercentage)%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        progress.definition.type.color.opacity(0.3),
                                        progress.definition.tier.color.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .adaptiveShadow(Shadow.subtle)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(progress.definition.title) achievement, \(progress.progressPercentage) percent complete, \(motivationalMessage)")
        .accessibilityHint("Tap for more details")
    }

    // MARK: - Motivational Message

    private var motivationalMessage: String {
        let remaining = progress.remainingValue
        let unit = progress.definition.requirementUnit

        if progress.progress >= 0.9 {
            return "Almost there! Just \(remaining) \(unit) to go!"
        } else if progress.progress >= 0.75 {
            return "So close! \(remaining) more \(unit)!"
        } else if progress.progress >= 0.5 {
            return "Halfway there! \(remaining) \(unit) left"
        } else if progress.progress >= 0.25 {
            return "Making progress! \(remaining) \(unit) to go"
        } else {
            return "\(remaining) more \(unit) to unlock"
        }
    }
}

// MARK: - Up Next Section

/// A section showing recommended next achievements
struct UpNextAchievementsSection: View {
    let achievements: [AchievementProgress]
    var onAchievementTap: ((AchievementProgress) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.orange)
                Text("Up Next")
                    .font(.headline)
                Spacer()
                if achievements.count > 3 {
                    Text("\(achievements.count) available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel("Up next, \(achievements.count) achievements available")

            // Achievement cards
            if achievements.isEmpty {
                emptyState
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(achievements.prefix(3)) { achievement in
                        NextAchievementCard(progress: achievement) {
                            onAchievementTap?(achievement)
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title)
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text("All caught up!")
                    .font(.headline)
                Text("You've unlocked all available achievements.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.green.opacity(0.1))
        )
    }
}

// MARK: - Compact Next Achievement Card

/// A smaller card for inline display
struct CompactNextAchievementCard: View {
    let progress: AchievementProgress
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap?()
        }) {
            HStack(spacing: Spacing.sm) {
                // Mini badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: progress.definition.iconName)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(progress.definition.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text("\(progress.remainingValue) \(progress.definition.requirementUnit) to go")
                        .font(.caption2)
                        .foregroundColor(progress.definition.type.color)
                }

                Spacer()

                // Progress circle
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 3)
                        .frame(width: 28, height: 28)

                    Circle()
                        .trim(from: 0, to: progress.progress)
                        .stroke(
                            progress.definition.type.color,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 28, height: 28)
                        .rotationEffect(.degrees(-90))

                    Text("\(progress.progressPercentage)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(Color(.tertiarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(progress.definition.title), \(progress.progressPercentage) percent complete, \(progress.remainingValue) \(progress.definition.requirementUnit) remaining")
    }
}

// MARK: - Achievement Recommendations Helper

/// Helper to compute recommended next achievements
enum AchievementRecommendations {
    /// Get the closest achievements to being unlocked
    /// - Parameters:
    ///   - achievements: All achievement progress
    ///   - limit: Maximum number to return
    /// - Returns: Sorted list of achievements closest to completion
    static func getClosestToUnlock(from achievements: [AchievementProgress], limit: Int = 3) -> [AchievementProgress] {
        achievements
            .filter { !$0.isUnlocked && $0.currentValue > 0 }
            .sorted { $0.progress > $1.progress }
            .prefix(limit)
            .map { $0 }
    }

    /// Get achievements that are just starting (good next goals)
    static func getNextGoals(from achievements: [AchievementProgress], limit: Int = 3) -> [AchievementProgress] {
        let inProgress = achievements
            .filter { !$0.isUnlocked && $0.currentValue > 0 }
            .sorted { $0.progress > $1.progress }

        if inProgress.count >= limit {
            return Array(inProgress.prefix(limit))
        }

        // Add some not-started achievements of lower tiers
        let notStarted = achievements
            .filter { !$0.isUnlocked && $0.currentValue == 0 }
            .sorted { $0.definition.tier < $1.definition.tier }
            .prefix(limit - inProgress.count)

        return inProgress + notStarted
    }

    /// Get achievements by category that are closest to unlock
    static func getClosestByCategory(from achievements: [AchievementProgress]) -> [AchievementType: AchievementProgress] {
        var result: [AchievementType: AchievementProgress] = [:]

        for type in AchievementType.allCases {
            let typeAchievements = achievements
                .filter { !$0.isUnlocked && $0.definition.type == type }
                .sorted { $0.progress > $1.progress }

            if let closest = typeAchievements.first {
                result[type] = closest
            }
        }

        return result
    }
}

// MARK: - Preview

#if DEBUG
struct NextAchievementCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Single card
                NextAchievementCard(
                    progress: AchievementProgress(
                        definition: AchievementCatalog.streak30Day,
                        currentValue: 25,
                        isUnlocked: false,
                        unlockedAt: nil
                    )
                )

                // Almost complete
                NextAchievementCard(
                    progress: AchievementProgress(
                        definition: AchievementCatalog.workouts100,
                        currentValue: 95,
                        isUnlocked: false,
                        unlockedAt: nil
                    )
                )

                // Up Next Section
                UpNextAchievementsSection(
                    achievements: [
                        AchievementProgress(
                            definition: AchievementCatalog.streak30Day,
                            currentValue: 25,
                            isUnlocked: false,
                            unlockedAt: nil
                        ),
                        AchievementProgress(
                            definition: AchievementCatalog.workouts50,
                            currentValue: 35,
                            isUnlocked: false,
                            unlockedAt: nil
                        ),
                        AchievementProgress(
                            definition: AchievementCatalog.volume100k,
                            currentValue: 75000,
                            isUnlocked: false,
                            unlockedAt: nil
                        )
                    ]
                )

                // Compact cards
                VStack(spacing: Spacing.xs) {
                    Text("Compact Style")
                        .font(.headline)

                    CompactNextAchievementCard(
                        progress: AchievementProgress(
                            definition: AchievementCatalog.streak14Day,
                            currentValue: 10,
                            isUnlocked: false,
                            unlockedAt: nil
                        )
                    )

                    CompactNextAchievementCard(
                        progress: AchievementProgress(
                            definition: AchievementCatalog.prs10,
                            currentValue: 7,
                            isUnlocked: false,
                            unlockedAt: nil
                        )
                    )
                }
            }
            .padding()
        }
    }
}
#endif
