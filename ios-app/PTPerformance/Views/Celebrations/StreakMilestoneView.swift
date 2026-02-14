//
//  StreakMilestoneView.swift
//  PTPerformance
//
//  ACP-836: Gamification Polish - Milestone Celebrations & Achievements
//  ACP-1029: Streak System Gamification - Enhanced milestone celebrations
//  Celebration animation for reaching streak milestones with confetti/animation
//

import SwiftUI

// MARK: - Streak Milestone View

/// Full-screen celebration view for reaching streak milestones
/// ACP-1029: Enhanced with Modus brand colors, growing flame icons, and streak freeze rewards
struct StreakMilestoneView: View {
    let milestone: StreakMilestone
    let currentStreak: Int
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var showConfetti = false
    @State private var flameScale: CGFloat = 0.1
    @State private var numberScale: CGFloat = 0.5
    @State private var numberOffset: CGFloat = 50
    @State private var messageOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var freezeRewardOpacity: Double = 0
    @State private var glowRotation: Double = 0

    private var flameLevel: StreakFlameLevel {
        StreakFlameLevel.level(for: currentStreak)
    }

    var body: some View {
        ZStack {
            // Background gradient using Modus brand colors
            LinearGradient(
                colors: [
                    Color.modusDeepTeal.opacity(0.9),
                    Color.modusCyan.opacity(0.4),
                    Color.black.opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Confetti particles
            if showConfetti {
                ConfettiView(count: milestone.confettiCount)
            }

            // Main content
            VStack(spacing: Spacing.xl) {
                Spacer()

                // Animated flame with glow rings
                ZStack {
                    // Outer glow rings based on flame level
                    ForEach(0..<flameLevel.glowRings, id: \.self) { ring in
                        Circle()
                            .stroke(
                                Color.modusTealAccent.opacity(0.2 - Double(ring) * 0.05),
                                lineWidth: 2
                            )
                            .frame(
                                width: 160 + CGFloat(ring) * 40,
                                height: 160 + CGFloat(ring) * 40
                            )
                            .scaleEffect(showContent ? 1.1 : 0.5)
                            .opacity(showContent ? 1 : 0)
                            .rotationEffect(.degrees(glowRotation + Double(ring) * 30))
                    }

                    // Inner glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.modusCyan.opacity(0.6), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(showContent ? 1.2 : 0.5)
                        .opacity(showContent ? 1 : 0)

                    // Flame icon with dynamic sizing based on milestone
                    Image(systemName: flameLevel.iconName)
                        .font(.system(size: 100 * flameLevel.sizeMultiplier))
                        .foregroundStyle(
                            LinearGradient(
                                colors: milestoneGradientColors,
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(flameScale)
                        .shadow(color: Color.modusCyan.opacity(0.8), radius: 20, x: 0, y: 10)
                }

                // Streak number
                VStack(spacing: Spacing.xs) {
                    Text("\(currentStreak)")
                        .font(.system(size: 80, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color.modusTealAccent],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.modusCyan.opacity(0.5), radius: 10)
                        .scaleEffect(numberScale)
                        .offset(y: numberOffset)

                    Text("DAY STREAK")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.9))
                        .tracking(4)
                        .scaleEffect(numberScale)
                        .offset(y: numberOffset)
                }

                // Milestone message
                VStack(spacing: Spacing.sm) {
                    Text(milestone.displayName)
                        .font(.title)
                        .fontWeight(.heavy)
                        .foregroundColor(Color.modusTealAccent)

                    Text(milestone.celebrationMessage)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)

                    // Flame level badge
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: flameLevel.iconName)
                            .font(.caption)
                        Text("Flame Level: \(flameLevel.displayName)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(Color.modusCyan)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xxs)
                    .background(
                        Capsule()
                            .fill(Color.modusCyan.opacity(0.15))
                    )
                }
                .opacity(messageOpacity)

                // Streak freeze reward notification
                if StreakFreezeReward.reward(for: currentStreak) != nil {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "shield.checkered")
                            .font(.title2)
                            .foregroundColor(Color.modusTealAccent)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Streak Shield Earned!")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text("You can use it to protect your streak during a rest day")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(Color.modusTealAccent.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.md)
                                    .stroke(Color.modusTealAccent.opacity(0.4), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, Spacing.lg)
                    .opacity(freezeRewardOpacity)
                }

                Spacer()

                // Dismiss button with Modus branding
                Button(action: {
                    HapticFeedback.light()
                    onDismiss()
                }) {
                    Text("Keep Going!")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.xxl)
                        .padding(.vertical, Spacing.md)
                        .background(
                            LinearGradient(
                                colors: [Color.modusCyan, Color.modusTealAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(CornerRadius.lg)
                        .shadow(color: Color.modusCyan.opacity(0.5), radius: 10)
                }
                .opacity(buttonOpacity)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .onAppear {
            animateIn()
            HapticFeedback.success()
        }
    }

    /// Gradient colors based on milestone tier
    private var milestoneGradientColors: [Color] {
        switch milestone {
        case .week, .twoWeeks:
            return [Color.modusCyan, Color.modusTealAccent]
        case .month, .twoMonths:
            return [Color.modusTealAccent, Color.modusCyan, Color.modusTealAccent]
        case .threeMonths, .hundred:
            return [.yellow, Color.modusCyan, Color.modusTealAccent]
        }
    }

    private func animateIn() {
        // Confetti immediately
        withAnimation(.easeOut(duration: 0.3)) {
            showConfetti = true
        }

        // Flame animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1)) {
            flameScale = 1.0
            showContent = true
        }

        // Glow rotation
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            glowRotation = 360
        }

        // Number animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3)) {
            numberScale = 1.0
            numberOffset = 0
        }

        // Message fade in
        withAnimation(.easeIn(duration: 0.4).delay(0.5)) {
            messageOpacity = 1.0
        }

        // Freeze reward fade in
        withAnimation(.easeIn(duration: 0.4).delay(0.7)) {
            freezeRewardOpacity = 1.0
        }

        // Button fade in
        withAnimation(.easeIn(duration: 0.3).delay(0.9)) {
            buttonOpacity = 1.0
        }

        // Celebratory haptics
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            HapticFeedback.heavy()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            HapticFeedback.medium()
        }
    }
}

// MARK: - Confetti View

/// Animated confetti particles
/// Fix 8: Capped to max 60 particles and uses .drawingGroup() for flattened rendering
struct ConfettiView: View {
    let count: Int

    /// Maximum number of confetti particles to render (Fix 8)
    private static let maxParticleCount = 60

    @State private var particles: [StreakConfettiParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    StreakConfettiParticleView(particle: particle)
                }
            }
            .drawingGroup() // Fix 8: Flatten rendering into a single Metal/Core Graphics layer
            .onAppear {
                createParticles(in: geometry.size)
            }
        }
        .ignoresSafeArea()
    }

    private func createParticles(in size: CGSize) {
        let cappedCount = min(count, Self.maxParticleCount) // Fix 8: Cap particle count
        particles = (0..<cappedCount).map { _ in
            StreakConfettiParticle(
                x: CGFloat.random(in: 0...size.width),
                y: -20,
                targetY: size.height + 50,
                color: [
                    Color.modusCyan, Color.modusTealAccent, Color.modusDeepTeal,
                    Color.yellow, Color.orange, Color.mint, Color.cyan
                ].randomElement()!,
                size: CGFloat.random(in: 8...16),
                rotation: Double.random(in: 0...360),
                delay: Double.random(in: 0...0.5)
            )
        }
    }
}

struct StreakConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let targetY: CGFloat
    let color: Color
    let size: CGFloat
    let rotation: Double
    let delay: Double
}

struct StreakConfettiParticleView: View {
    let particle: StreakConfettiParticle

    @State private var currentY: CGFloat
    @State private var currentRotation: Double
    @State private var opacity: Double = 1

    init(particle: StreakConfettiParticle) {
        self.particle = particle
        _currentY = State(initialValue: particle.y)
        _currentRotation = State(initialValue: particle.rotation)
    }

    var body: some View {
        Rectangle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size * 0.6)
            .rotationEffect(.degrees(currentRotation))
            .position(x: particle.x + sin(currentY / 50) * 30, y: currentY)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeIn(duration: Double.random(in: 2...4))
                    .delay(particle.delay)
                ) {
                    currentY = particle.targetY
                    currentRotation = particle.rotation + Double.random(in: 360...720)
                }

                withAnimation(
                    .easeIn(duration: 0.5)
                    .delay(particle.delay + 2)
                ) {
                    opacity = 0
                }
            }
    }
}

// MARK: - Compact Streak Celebration

/// Compact celebration banner for inline display
struct StreakCelebrationBanner: View {
    let milestone: StreakMilestone
    let streak: Int
    var onTap: (() -> Void)?

    @State private var isAnimating = false

    private var flameLevel: StreakFlameLevel {
        StreakFlameLevel.level(for: streak)
    }

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap?()
        }) {
            HStack(spacing: Spacing.md) {
                // Flame with animation and dynamic level
                ZStack {
                    Circle()
                        .fill(Color.modusCyan.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: flameLevel.iconName)
                        .font(.system(size: 24 * flameLevel.sizeMultiplier))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.modusCyan, Color.modusTealAccent],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(milestone.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("\(streak) day streak!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "party.popper.fill")
                    .font(.title2)
                    .foregroundColor(Color.modusTealAccent)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.modusLightTeal)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Color.modusTealAccent.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 0.8)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}

// MARK: - ACP-1029: Streak Freeze Used Confirmation

/// Confirmation banner shown after a streak freeze is used
struct StreakFreezeUsedBanner: View {
    let remainingFreezes: Int

    @State private var shieldScale: CGFloat = 0.5
    @State private var contentOpacity: Double = 0

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.modusTealAccent.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: "shield.checkered")
                    .font(.title2)
                    .foregroundColor(Color.modusTealAccent)
                    .scaleEffect(shieldScale)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Streak Shield Activated!")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Your streak is protected today. \(remainingFreezes) shield\(remainingFreezes == 1 ? "" : "s") remaining.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(Color.modusTealAccent)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.modusLightTeal)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(Color.modusTealAccent.opacity(0.3), lineWidth: 1)
                )
        )
        .opacity(contentOpacity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                shieldScale = 1.0
            }
            withAnimation(.easeIn(duration: 0.3).delay(0.1)) {
                contentOpacity = 1.0
            }
            HapticFeedback.success()
        }
    }
}

// MARK: - ACP-1029: Comeback Welcome Banner

/// Welcome-back banner with motivational messaging for users returning after a break
struct ComebackWelcomeBanner: View {
    let comebackState: StreakComebackState
    var onStartWorkout: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header
            HStack(spacing: Spacing.sm) {
                Image(systemName: comebackIcon)
                    .font(.title2)
                    .foregroundColor(Color.modusCyan)

                Text(comebackTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            // Motivational message
            Text(comebackState.message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Reduced target indicator
            if comebackState.comebackPhase != .fresh {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.caption)
                        .foregroundColor(Color.modusTealAccent)

                    Text("Reduced targets for \(comebackState.comebackDuration) days to ease you back in")
                        .font(.caption)
                        .foregroundColor(Color.modusTealAccent)
                }
                .padding(.vertical, Spacing.xxs)
            }

            // Quick start button
            if let onStart = onStartWorkout {
                Button(action: {
                    HapticFeedback.light()
                    onStart()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start \(comebackState.comebackPhase.suggestedDuration)-Min Workout")
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
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color.modusLightTeal)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(Color.modusCyan.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private var comebackIcon: String {
        switch comebackState.comebackPhase {
        case .fresh: return "hand.wave.fill"
        case .shortBreak: return "arrow.counterclockwise.circle.fill"
        case .extended: return "figure.walk.motion"
        case .longAbsence: return "sun.max.fill"
        }
    }

    private var comebackTitle: String {
        switch comebackState.comebackPhase {
        case .fresh: return "Welcome Back!"
        case .shortBreak: return "Good to See You!"
        case .extended: return "Ready to Restart?"
        case .longAbsence: return "Fresh Start!"
        }
    }
}

// MARK: - ACP-1029: Growing Flame Icon

/// Animated flame icon that grows and upgrades based on streak level
struct GrowingFlameIcon: View {
    let streak: Int
    let size: CGFloat
    var showLabel: Bool = false

    @State private var isPulsing = false

    private var flameLevel: StreakFlameLevel {
        StreakFlameLevel.level(for: streak)
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Glow rings for higher levels
                if flameLevel.glowRings > 0 {
                    ForEach(0..<flameLevel.glowRings, id: \.self) { ring in
                        Circle()
                            .stroke(
                                flameGradient.opacity(0.15 - Double(ring) * 0.04),
                                lineWidth: 1.5
                            )
                            .frame(
                                width: size * 1.6 + CGFloat(ring) * 12,
                                height: size * 1.6 + CGFloat(ring) * 12
                            )
                            .scaleEffect(isPulsing ? 1.05 : 1.0)
                    }
                }

                // Background circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                flameColor.opacity(0.3),
                                flameColor.opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size * 1.4, height: size * 1.4)

                // Flame icon
                Image(systemName: flameLevel.iconName)
                    .font(.system(size: size * flameLevel.sizeMultiplier))
                    .foregroundStyle(flameGradient)
                    .scaleEffect(isPulsing && flameLevel.shouldAnimate ? 1.08 : 1.0)
                    .shadow(color: flameColor.opacity(0.6), radius: flameLevel >= .inferno ? 8 : 4)
            }

            if showLabel {
                Text(flameLevel.displayName)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(flameColor)
            }
        }
        .onAppear {
            if flameLevel.shouldAnimate {
                withAnimation(
                    .easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true)
                ) {
                    isPulsing = true
                }
            }
        }
    }

    private var flameColor: Color {
        switch flameLevel {
        case .spark: return .gray
        case .ember: return .orange
        case .flame: return Color.modusCyan
        case .blaze: return Color.modusTealAccent
        case .inferno: return Color.modusCyan
        case .wildfire: return Color.modusTealAccent
        case .supernova: return .yellow
        }
    }

    private var flameGradient: LinearGradient {
        switch flameLevel {
        case .spark:
            return LinearGradient(colors: [.gray, .gray.opacity(0.7)], startPoint: .top, endPoint: .bottom)
        case .ember:
            return LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom)
        case .flame:
            return LinearGradient(colors: [Color.modusCyan, Color.modusTealAccent], startPoint: .top, endPoint: .bottom)
        case .blaze:
            return LinearGradient(colors: [Color.modusTealAccent, Color.modusCyan], startPoint: .top, endPoint: .bottom)
        case .inferno:
            return LinearGradient(colors: [.yellow, Color.modusCyan, Color.modusTealAccent], startPoint: .top, endPoint: .bottom)
        case .wildfire:
            return LinearGradient(colors: [.yellow, Color.modusTealAccent, Color.modusDeepTeal], startPoint: .top, endPoint: .bottom)
        case .supernova:
            return LinearGradient(colors: [.white, .yellow, Color.modusCyan], startPoint: .top, endPoint: .bottom)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct StreakMilestoneView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StreakMilestoneView(
                milestone: .week,
                currentStreak: 7,
                onDismiss: {}
            )
            .previewDisplayName("7 Day")

            StreakMilestoneView(
                milestone: .month,
                currentStreak: 30,
                onDismiss: {}
            )
            .previewDisplayName("30 Day")

            StreakMilestoneView(
                milestone: .hundred,
                currentStreak: 100,
                onDismiss: {}
            )
            .previewDisplayName("100 Day")

            StreakCelebrationBanner(
                milestone: .week,
                streak: 7
            )
            .padding()
            .previewDisplayName("Banner")

            StreakFreezeUsedBanner(remainingFreezes: 2)
                .padding()
                .previewDisplayName("Freeze Used")

            ComebackWelcomeBanner(
                comebackState: StreakComebackState(
                    previousStreak: 15,
                    daysSinceLastActivity: 4,
                    comebackPhase: .shortBreak
                )
            )
            .padding()
            .previewDisplayName("Comeback Banner")

            HStack(spacing: 20) {
                GrowingFlameIcon(streak: 0, size: 18, showLabel: true)
                GrowingFlameIcon(streak: 3, size: 18, showLabel: true)
                GrowingFlameIcon(streak: 7, size: 18, showLabel: true)
                GrowingFlameIcon(streak: 14, size: 18, showLabel: true)
                GrowingFlameIcon(streak: 30, size: 18, showLabel: true)
                GrowingFlameIcon(streak: 60, size: 18, showLabel: true)
                GrowingFlameIcon(streak: 100, size: 18, showLabel: true)
            }
            .padding()
            .previewDisplayName("Flame Levels")
        }
    }
}
#endif
