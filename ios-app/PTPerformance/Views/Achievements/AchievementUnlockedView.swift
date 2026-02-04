//
//  AchievementUnlockedView.swift
//  PTPerformance
//
//  Gamification Polish - Milestone Celebrations & Achievements
//  Badge unlock animation and celebration view
//

import SwiftUI

// MARK: - Achievement Unlocked View

/// Full-screen celebration when an achievement is unlocked
struct AchievementUnlockedView: View {
    let event: AchievementUnlockEvent
    let onDismiss: () -> Void
    var onShare: (() -> Void)?

    @State private var showBadge = false
    @State private var badgeScale: CGFloat = 0.1
    @State private var badgeRotation: Double = -30
    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var buttonsOpacity: Double = 0
    @State private var sparkles: [SparkleParticle] = []

    private var achievement: AchievementDefinition { event.achievement }

    var body: some View {
        ZStack {
            // Background
            backgroundGradient

            // Sparkle particles
            ForEach(sparkles) { sparkle in
                SparkleView(sparkle: sparkle)
            }

            // Main content
            VStack(spacing: Spacing.xl) {
                Spacer()

                // "Achievement Unlocked" header
                Text("ACHIEVEMENT UNLOCKED")
                    .font(.caption)
                    .fontWeight(.bold)
                    .tracking(4)
                    .foregroundColor(achievement.tier.color.opacity(0.8))
                    .opacity(textOpacity)

                // Badge with glow
                ZStack {
                    // Outer glow ring
                    Circle()
                        .stroke(achievement.tier.glowColor, lineWidth: 3)
                        .frame(width: 180, height: 180)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    // Inner glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [achievement.tier.color.opacity(0.4), Color.clear],
                                center: .center,
                                startRadius: 30,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .opacity(showBadge ? 1 : 0)

                    // Badge background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    achievement.tier.color,
                                    achievement.tier.color.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                        .shadow(color: achievement.tier.glowColor, radius: 20)
                        .scaleEffect(badgeScale)
                        .rotationEffect(.degrees(badgeRotation))

                    // Achievement icon
                    Image(systemName: achievement.iconName)
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 5)
                        .scaleEffect(badgeScale)
                        .rotationEffect(.degrees(badgeRotation))
                }

                // Tier badge
                Text(achievement.tier.displayName.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(achievement.tier.color)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xxs)
                    .background(
                        Capsule()
                            .fill(achievement.tier.color.opacity(0.2))
                    )
                    .opacity(textOpacity)

                // Achievement info
                VStack(spacing: Spacing.sm) {
                    Text(achievement.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(achievement.description)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)

                    // Points earned
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("+\(achievement.tier.points) points")
                            .fontWeight(.semibold)
                            .foregroundColor(.yellow)
                    }
                    .padding(.top, Spacing.sm)
                }
                .opacity(textOpacity)

                Spacer()

                // Buttons
                VStack(spacing: Spacing.md) {
                    // Share button (optional)
                    if onShare != nil {
                        Button(action: {
                            HapticFeedback.light()
                            onShare?()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Achievement")
                            }
                            .font(.headline)
                            .foregroundColor(achievement.tier.color)
                            .padding(.horizontal, Spacing.xl)
                            .padding(.vertical, Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.md)
                                    .stroke(achievement.tier.color, lineWidth: 2)
                            )
                        }
                    }

                    // Dismiss button
                    Button(action: {
                        HapticFeedback.light()
                        onDismiss()
                    }) {
                        Text("Awesome!")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.horizontal, Spacing.xxl)
                            .padding(.vertical, Spacing.md)
                            .background(
                                LinearGradient(
                                    colors: [achievement.tier.color, achievement.tier.color.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(CornerRadius.lg)
                    }
                }
                .opacity(buttonsOpacity)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .onAppear {
            animateIn()
            generateSparkles()
            HapticFeedback.success()
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            Color.black

            RadialGradient(
                colors: [
                    achievement.tier.color.opacity(0.3),
                    achievement.type.color.opacity(0.1),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Animations

    private func animateIn() {
        // Badge appearance
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.1)) {
            showBadge = true
            badgeScale = 1.0
            badgeRotation = 0
        }

        // Ring pulse
        withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
            ringScale = 1.5
            ringOpacity = 0.8
        }

        withAnimation(.easeIn(duration: 0.4).delay(0.8)) {
            ringOpacity = 0
        }

        // Text fade in
        withAnimation(.easeIn(duration: 0.4).delay(0.4)) {
            textOpacity = 1.0
        }

        // Buttons fade in
        withAnimation(.easeIn(duration: 0.3).delay(0.7)) {
            buttonsOpacity = 1.0
        }

        // Haptic sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            HapticFeedback.heavy()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            HapticFeedback.medium()
        }
    }

    private func generateSparkles() {
        sparkles = (0..<20).map { _ in
            SparkleParticle(
                x: CGFloat.random(in: 100...300),
                y: CGFloat.random(in: 150...350),
                delay: Double.random(in: 0...0.5)
            )
        }
    }
}

// MARK: - Sparkle Particle

struct SparkleParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let delay: Double
}

struct SparkleView: View {
    let sparkle: SparkleParticle

    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.5

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: CGFloat.random(in: 8...16)))
            .foregroundColor(.white)
            .opacity(opacity)
            .scaleEffect(scale)
            .position(x: sparkle.x, y: sparkle.y)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.6)
                    .delay(sparkle.delay)
                    .repeatForever(autoreverses: true)
                ) {
                    opacity = Double.random(in: 0.3...1.0)
                    scale = CGFloat.random(in: 0.8...1.2)
                }
            }
    }
}

// MARK: - Achievement Badge View

/// Compact badge display for achievement lists
struct AchievementBadgeView: View {
    let definition: AchievementDefinition
    let isUnlocked: Bool
    var size: CGFloat = 60
    var showTier: Bool = true

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            ZStack {
                // Background circle
                Circle()
                    .fill(
                        isUnlocked
                            ? LinearGradient(
                                colors: [definition.tier.color, definition.tier.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .stroke(
                                isUnlocked ? definition.tier.color.opacity(0.5) : Color.gray.opacity(0.2),
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: isUnlocked ? definition.tier.glowColor : Color.clear,
                        radius: 5
                    )

                // Icon
                Image(systemName: definition.iconName)
                    .font(.system(size: size * 0.4))
                    .foregroundColor(isUnlocked ? .white : .gray.opacity(0.5))

                // Lock overlay if not unlocked
                if !isUnlocked {
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: size, height: size)

                    Image(systemName: "lock.fill")
                        .font(.system(size: size * 0.25))
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            // Tier indicator
            if showTier && isUnlocked {
                Text(definition.tier.displayName)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(definition.tier.color)
            }
        }
    }
}

// MARK: - Achievement Card View

/// Card display for achievement with progress
struct AchievementCardView: View {
    let progress: AchievementProgress
    var onTap: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap?()
        }) {
            HStack(spacing: Spacing.md) {
                // Badge
                AchievementBadgeView(
                    definition: progress.definition,
                    isUnlocked: progress.isUnlocked,
                    size: 50
                )

                // Info
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack {
                        Text(progress.definition.title)
                            .font(.headline)
                            .foregroundColor(progress.isUnlocked ? .primary : .secondary)

                        if progress.isUnlocked {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }

                    Text(progress.definition.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    // Progress bar (if not unlocked)
                    if !progress.isUnlocked {
                        ProgressView(value: progress.progress)
                            .tint(progress.definition.type.color)

                        Text("\(progress.currentValue)/\(progress.definition.requirement) \(progress.definition.requirementUnit)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else if let date = progress.unlockedAt {
                        Text("Unlocked \(date.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Points badge
                VStack {
                    Text("+\(progress.definition.tier.points)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(progress.isUnlocked ? progress.definition.tier.color : .gray)
                    Text("pts")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(
                                progress.isUnlocked ? progress.definition.tier.color.opacity(0.3) : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
            .adaptiveShadow(Shadow.subtle)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#if DEBUG
struct AchievementUnlockedView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AchievementUnlockedView(
                event: AchievementUnlockEvent.sample,
                onDismiss: {},
                onShare: {}
            )
            .previewDisplayName("Unlocked View")

            AchievementBadgeView(
                definition: AchievementCatalog.streak7Day,
                isUnlocked: true
            )
            .padding()
            .previewDisplayName("Badge Unlocked")

            AchievementBadgeView(
                definition: AchievementCatalog.streak30Day,
                isUnlocked: false
            )
            .padding()
            .previewDisplayName("Badge Locked")

            AchievementCardView(progress: AchievementProgress.sampleUnlocked)
                .padding()
                .previewDisplayName("Card Unlocked")

            AchievementCardView(progress: AchievementProgress.sampleLocked)
                .padding()
                .previewDisplayName("Card Locked")
        }
    }
}
#endif
