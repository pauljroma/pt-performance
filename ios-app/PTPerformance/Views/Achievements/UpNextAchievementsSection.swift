//
//  UpNextAchievementsSection.swift
//  PTPerformance
//
//  ACP-1030: Achievement System Polish
//  "Up Next" section showing achievements closest to being unlocked
//

import SwiftUI

/// Displays recommended achievements for users to pursue next
struct UpNextAchievementsSection: View {
    let achievements: [AchievementProgress]
    let onTap: (AchievementProgress) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.modusCyan)
                    .accessibilityHidden(true)
                Text("Up Next")
                    .font(.headline)
                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel("Up Next achievements")

            VStack(spacing: Spacing.md) {
                ForEach(achievements) { achievement in
                    UpNextAchievementCard(progress: achievement) {
                        onTap(achievement)
                    }
                }
            }
        }
    }
}

/// Compact card showing an achievement close to being unlocked
struct UpNextAchievementCard: View {
    let progress: AchievementProgress
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap()
        }) {
            HStack(spacing: Spacing.md) {
                // Circular progress indicator
                CircularProgressIndicator(
                    progress: progress.progress,
                    color: progress.definition.type.color,
                    size: 60
                ) {
                    Image(systemName: progress.definition.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(progress.definition.type.color)
                }

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(progress.definition.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(progress.definition.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    HStack(spacing: Spacing.xs) {
                        Text("\(progress.progressPercentage)% complete")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(progress.definition.type.color)

                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("\(progress.remainingValue) more to go")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(progress.definition.type.color.opacity(0.2), lineWidth: 1)
                    )
            )
            .adaptiveShadow(Shadow.subtle)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(progress.definition.title), \(progress.progressPercentage) percent complete, \(progress.remainingValue) more to unlock")
        .accessibilityHint("Tap for details")
    }
}

/// Circular progress indicator with icon in center
struct CircularProgressIndicator: View {
    let progress: Double
    let color: Color
    var size: CGFloat = 60
    var lineWidth: CGFloat = 4
    let content: () -> any View

    init(
        progress: Double,
        color: Color,
        size: CGFloat = 60,
        lineWidth: CGFloat = 4,
        @ViewBuilder content: @escaping () -> some View
    ) {
        self.progress = progress
        self.color = color
        self.size = size
        self.lineWidth = lineWidth
        self.content = content
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color(.systemGray5), lineWidth: lineWidth)
                .frame(width: size, height: size)

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            // Content (icon)
            AnyView(content())
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress: \(Int(progress * 100)) percent")
    }
}

// MARK: - Preview

#if DEBUG
struct UpNextAchievementsSection_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack {
                UpNextAchievementsSection(
                    achievements: Array(AchievementProgress.sampleArray.prefix(3))
                ) { _ in }
                .padding()
            }
        }
    }
}
#endif
