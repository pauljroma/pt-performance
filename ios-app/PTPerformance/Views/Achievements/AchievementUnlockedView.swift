// DARK MODE: See ModeThemeModifier.swift for central theme control
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
    @State private var secondRingScale: CGFloat = 0.5
    @State private var secondRingOpacity: Double = 0
    @State private var thirdRingScale: CGFloat = 0.5
    @State private var thirdRingOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var buttonsOpacity: Double = 0
    @State private var sparkles: [SparkleParticle] = []
    @State private var showConfetti = false
    @State private var glowPulse = false

    private var achievement: AchievementDefinition { event.achievement }

    /// Whether this is a major achievement (gold tier or higher) that deserves confetti
    private var isMajorAchievement: Bool {
        achievement.tier >= .gold
    }

    var body: some View {
        ZStack {
            // Background
            backgroundGradient

            // Confetti for major achievements
            if showConfetti && isMajorAchievement {
                AchievementConfettiView(
                    colors: confettiColors,
                    particleCount: confettiCount
                )
                .ignoresSafeArea()
            }

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
                    .accessibilityAddTraits(.isHeader)

                // Badge with multi-ring glow
                ZStack {
                    // Third outer glow ring (for platinum/diamond)
                    if achievement.tier >= .platinum {
                        Circle()
                            .stroke(achievement.tier.glowColor.opacity(0.3), lineWidth: 2)
                            .frame(width: 220, height: 220)
                            .scaleEffect(thirdRingScale)
                            .opacity(thirdRingOpacity)
                    }

                    // Second outer glow ring (for gold+)
                    if achievement.tier >= .gold {
                        Circle()
                            .stroke(achievement.tier.glowColor.opacity(0.5), lineWidth: 2)
                            .frame(width: 200, height: 200)
                            .scaleEffect(secondRingScale)
                            .opacity(secondRingOpacity)
                    }

                    // Primary outer glow ring
                    Circle()
                        .stroke(achievement.tier.glowColor, lineWidth: 3)
                        .frame(width: 180, height: 180)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    // Animated inner glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [achievement.tier.color.opacity(glowPulse ? 0.5 : 0.3), Color.clear],
                                center: .center,
                                startRadius: 30,
                                endRadius: glowPulse ? 120 : 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .opacity(showBadge ? 1 : 0)

                    // Badge background with enhanced shadow
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
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: achievement.tier.glowColor, radius: glowPulse ? 25 : 20)
                        .shadow(color: achievement.tier.glowColor.opacity(0.5), radius: 40)
                        .scaleEffect(badgeScale)
                        .rotationEffect(.degrees(badgeRotation))

                    // Achievement icon with subtle bounce
                    Image(systemName: achievement.iconName)
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 5)
                        .scaleEffect(badgeScale * (glowPulse ? 1.05 : 1.0))
                        .rotationEffect(.degrees(badgeRotation))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(achievement.tier.displayName) tier badge")

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

                    // Points earned with animated appearance
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("+\(achievement.tier.points) points")
                            .fontWeight(.semibold)
                            .foregroundColor(.yellow)
                    }
                    .padding(.top, Spacing.sm)
                    .scaleEffect(textOpacity > 0.5 ? 1.0 : 0.8)
                }
                .opacity(textOpacity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(achievement.title). \(achievement.description). Plus \(achievement.tier.points) points")

                Spacer()

                // Buttons
                VStack(spacing: Spacing.md) {
                    // Share button (optional)
                    if onShare != nil {
                        Button(action: {
                            HapticFeedback.medium()
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
                        .accessibilityLabel("Share this achievement")
                    }

                    // Dismiss button
                    Button(action: {
                        HapticFeedback.light()
                        onDismiss()
                    }) {
                        Text("Awesome!")
                            .font(.headline)
                            .foregroundColor(Color(.systemBackground))
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
                            .shadow(color: achievement.tier.color.opacity(0.5), radius: 10)
                    }
                    .accessibilityLabel("Dismiss celebration")
                }
                .opacity(buttonsOpacity)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .onAppear {
            animateIn()
            generateSparkles()
            triggerTierHaptic()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Achievement unlocked: \(achievement.title)")
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

    // MARK: - Confetti Configuration

    private var confettiColors: [Color] {
        switch achievement.tier {
        case .gold:
            return [.yellow, .orange, Color(red: 1.0, green: 0.84, blue: 0)]
        case .platinum:
            return [.white, Color(red: 0.9, green: 0.9, blue: 1.0), .gray]
        case .diamond:
            return [.cyan, .blue, .white, Color(red: 0.5, green: 0.8, blue: 1.0)]
        default:
            return [achievement.tier.color]
        }
    }

    private var confettiCount: Int {
        switch achievement.tier {
        case .gold: return 50
        case .platinum: return 75
        case .diamond: return 100
        default: return 30
        }
    }

    // MARK: - Animations

    private func animateIn() {
        // Badge appearance with spring animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0).delay(0.1)) {
            showBadge = true
            badgeScale = 1.0
            badgeRotation = 0
        }

        // Primary ring pulse
        withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
            ringScale = 1.4
            ringOpacity = 0.9
        }
        withAnimation(.easeIn(duration: 0.5).delay(0.7)) {
            ringOpacity = 0
        }

        // Second ring pulse (for gold+)
        if achievement.tier >= .gold {
            withAnimation(.easeOut(duration: 0.7).delay(0.3)) {
                secondRingScale = 1.5
                secondRingOpacity = 0.7
            }
            withAnimation(.easeIn(duration: 0.4).delay(0.9)) {
                secondRingOpacity = 0
            }
        }

        // Third ring pulse (for platinum/diamond)
        if achievement.tier >= .platinum {
            withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
                thirdRingScale = 1.6
                thirdRingOpacity = 0.5
            }
            withAnimation(.easeIn(duration: 0.4).delay(1.1)) {
                thirdRingOpacity = 0
            }
        }

        // Text fade in
        withAnimation(.easeIn(duration: 0.4).delay(0.4)) {
            textOpacity = 1.0
        }

        // Buttons fade in
        withAnimation(.easeIn(duration: 0.3).delay(0.7)) {
            buttonsOpacity = 1.0
        }

        // Confetti for major achievements
        if isMajorAchievement {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }
        }

        // Start glow pulse animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                glowPulse = true
            }
        }
    }

    /// Triggers tier-specific haptic pattern
    private func triggerTierHaptic() {
        switch achievement.tier {
        case .bronze:
            // Simple success
            HapticFeedback.success()
        case .silver:
            // Double tap pattern
            HapticFeedback.success()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                HapticFeedback.light()
            }
        case .gold:
            // Triple tap with crescendo
            HapticFeedback.medium()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                HapticFeedback.heavy()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
                HapticFeedback.success()
            }
        case .platinum:
            // Dramatic build-up
            HapticFeedback.light()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                HapticFeedback.medium()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                HapticFeedback.heavy()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                HapticFeedback.success()
            }
        case .diamond:
            // Epic celebration pattern
            HapticFeedback.heavy()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                HapticFeedback.heavy()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                HapticFeedback.medium()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                HapticFeedback.medium()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                HapticFeedback.success()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                HapticFeedback.success()
            }
        }
    }

    private func generateSparkles() {
        let sparkleCount = isMajorAchievement ? 30 : 20
        sparkles = (0..<sparkleCount).map { _ in
            SparkleParticle(
                x: CGFloat.random(in: 50...350),
                y: CGFloat.random(in: 100...400),
                delay: Double.random(in: 0...0.8)
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
    let size: CGFloat
    let rotationSpeed: Double

    init(x: CGFloat, y: CGFloat, delay: Double) {
        self.x = x
        self.y = y
        self.delay = delay
        self.size = CGFloat.random(in: 8...18)
        self.rotationSpeed = Double.random(in: 0.5...2.0)
    }
}

struct SparkleView: View {
    let sparkle: SparkleParticle

    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.3
    @State private var rotation: Double = 0
    @State private var yOffset: CGFloat = 0

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: sparkle.size))
            .foregroundStyle(
                LinearGradient(
                    colors: [.white, .white.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .opacity(opacity)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .position(x: sparkle.x, y: sparkle.y + yOffset)
            .onAppear {
                // Fade and scale animation
                withAnimation(
                    .easeInOut(duration: 0.8)
                    .delay(sparkle.delay)
                    .repeatForever(autoreverses: true)
                ) {
                    opacity = Double.random(in: 0.4...1.0)
                    scale = CGFloat.random(in: 0.8...1.3)
                }

                // Rotation animation
                withAnimation(
                    .linear(duration: sparkle.rotationSpeed)
                    .repeatForever(autoreverses: false)
                ) {
                    rotation = 360
                }

                // Subtle floating animation
                withAnimation(
                    .easeInOut(duration: 2.0)
                    .delay(sparkle.delay)
                    .repeatForever(autoreverses: true)
                ) {
                    yOffset = CGFloat.random(in: -5...5)
                }
            }
    }
}

// MARK: - Achievement Confetti View

/// Multi-colored falling confetti effect for major achievements
struct AchievementConfettiView: View {
    let colors: [Color]
    let particleCount: Int

    @State private var particles: [AchievementConfettiParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    AchievementConfettiParticleView(
                        particle: particle,
                        screenHeight: geometry.size.height
                    )
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
            }
        }
    }

    private func generateParticles(in size: CGSize) {
        particles = (0..<particleCount).map { index in
            AchievementConfettiParticle(
                x: CGFloat.random(in: 0...size.width),
                color: colors[index % colors.count],
                delay: Double(index) * 0.02,
                size: CGFloat.random(in: 6...12),
                rotationSpeed: Double.random(in: 1...4),
                fallDuration: Double.random(in: 2.5...4.0),
                swayAmount: CGFloat.random(in: 20...60)
            )
        }
    }
}

struct AchievementConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let color: Color
    let delay: Double
    let size: CGFloat
    let rotationSpeed: Double
    let fallDuration: Double
    let swayAmount: CGFloat
}

struct AchievementConfettiParticleView: View {
    let particle: AchievementConfettiParticle
    let screenHeight: CGFloat

    @State private var yPosition: CGFloat = -50
    @State private var xOffset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1

    var body: some View {
        confettiShape
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size * 1.5)
            .rotationEffect(.degrees(rotation))
            .rotation3DEffect(.degrees(rotation * 0.5), axis: (x: 1, y: 0, z: 0))
            .position(x: particle.x + xOffset, y: yPosition)
            .opacity(opacity)
            .onAppear {
                // Fall animation
                withAnimation(
                    .easeIn(duration: particle.fallDuration)
                    .delay(particle.delay)
                ) {
                    yPosition = screenHeight + 100
                }

                // Sway animation
                withAnimation(
                    .easeInOut(duration: 0.5)
                    .delay(particle.delay)
                    .repeatForever(autoreverses: true)
                ) {
                    xOffset = particle.swayAmount
                }

                // Rotation animation
                withAnimation(
                    .linear(duration: particle.rotationSpeed)
                    .delay(particle.delay)
                    .repeatForever(autoreverses: false)
                ) {
                    rotation = 360
                }

                // Fade out at end
                withAnimation(
                    .easeIn(duration: 0.5)
                    .delay(particle.delay + particle.fallDuration - 0.5)
                ) {
                    opacity = 0
                }
            }
    }

    private var confettiShape: some Shape {
        RoundedRectangle(cornerRadius: 2)
    }
}

// MARK: - Achievement Badge View

/// Compact badge display for achievement lists with animated glow effects
struct AchievementBadgeView: View {
    let definition: AchievementDefinition
    let isUnlocked: Bool
    var size: CGFloat = 60
    var showTier: Bool = true
    var animated: Bool = false

    @State private var glowPulse = false
    @State private var shimmerOffset: CGFloat = -1

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            ZStack {
                // Outer glow ring (for unlocked badges)
                if isUnlocked && animated {
                    Circle()
                        .stroke(definition.tier.glowColor.opacity(0.4), lineWidth: 2)
                        .frame(width: size + 10, height: size + 10)
                        .scaleEffect(glowPulse ? 1.1 : 1.0)
                        .opacity(glowPulse ? 0.3 : 0.6)
                }

                // Background circle with enhanced gradient
                Circle()
                    .fill(
                        isUnlocked
                            ? LinearGradient(
                                colors: [
                                    definition.tier.color,
                                    definition.tier.color.opacity(0.8),
                                    definition.tier.color.opacity(0.6)
                                ],
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
                                isUnlocked
                                    ? LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.5),
                                            definition.tier.color.opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: isUnlocked ? definition.tier.glowColor : Color.clear,
                        radius: glowPulse ? 8 : 5
                    )

                // Shimmer effect for high-tier unlocked badges
                if isUnlocked && definition.tier >= .gold {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: size, height: size)
                        .offset(x: shimmerOffset * size)
                        .mask(Circle().frame(width: size, height: size))
                }

                // Icon with subtle shadow
                Image(systemName: definition.iconName)
                    .font(.system(size: size * 0.4))
                    .foregroundColor(isUnlocked ? .white : .gray.opacity(0.5))
                    .shadow(color: isUnlocked ? .black.opacity(0.2) : .clear, radius: 2, y: 1)

                // Lock overlay if not unlocked
                if !isUnlocked {
                    Circle()
                        .fill(Color.black.opacity(0.35))
                        .frame(width: size, height: size)

                    Image(systemName: "lock.fill")
                        .font(.system(size: size * 0.25))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(isUnlocked ? "\(definition.title) badge, \(definition.tier.displayName) tier" : "\(definition.title) badge, locked")

            // Tier indicator
            if showTier && isUnlocked {
                Text(definition.tier.displayName)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(definition.tier.color)
            }
        }
        .onAppear {
            if animated && isUnlocked {
                // Start glow pulse animation
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    glowPulse = true
                }

                // Start shimmer animation for high-tier badges
                if definition.tier >= .gold {
                    withAnimation(
                        .easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: false)
                        .delay(1.0)
                    ) {
                        shimmerOffset = 1
                    }
                }
            }
        }
    }
}

// MARK: - Achievement Card View

/// Card display for achievement with animated progress bar
struct AchievementCardView: View {
    let progress: AchievementProgress
    var onTap: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @State private var animatedProgress: Double = 0
    @State private var showCompletionBounce = false

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
                                .scaleEffect(showCompletionBounce ? 1.2 : 1.0)
                        }
                    }

                    Text(progress.definition.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    // Animated progress bar (if not unlocked)
                    if !progress.isUnlocked {
                        AnimatedProgressBar(
                            progress: progress.progress,
                            color: progress.definition.type.color,
                            height: 6
                        )

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
        .onAppear {
            if progress.isUnlocked {
                // Bounce animation for unlocked checkmark
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.2)) {
                    showCompletionBounce = true
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.5)) {
                    showCompletionBounce = false
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(progress.definition.title), \(progress.isUnlocked ? "unlocked" : "\(progress.progressPercentage) percent complete")")
        .accessibilityHint("Tap for details")
    }
}

// MARK: - Animated Progress Bar

/// Smooth animated progress bar with optional bounce on completion
struct AnimatedProgressBar: View {
    let progress: Double
    let color: Color
    var height: CGFloat = 8
    var showBounce: Bool = true

    @State private var animatedProgress: Double = 0
    @State private var bounceScale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color(.systemGray5))
                    .frame(height: height)

                // Progress fill with gradient
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, geometry.size.width * animatedProgress), height: height)
                    .scaleEffect(x: 1, y: bounceScale, anchor: .leading)

                // Shine overlay
                if animatedProgress > 0 {
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: max(0, geometry.size.width * animatedProgress), height: height / 2)
                        .offset(y: -height / 4)
                        .mask(
                            RoundedRectangle(cornerRadius: height / 2)
                                .frame(width: max(0, geometry.size.width * animatedProgress), height: height)
                        )
                }
            }
        }
        .frame(height: height)
        .onAppear {
            // Animate progress fill
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                animatedProgress = progress
            }

            // Bounce effect when near or at completion
            if showBounce && progress >= 0.9 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                        bounceScale = 1.15
                    }
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6).delay(0.15)) {
                        bounceScale = 1.0
                    }
                }
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress: \(Int(progress * 100)) percent")
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
