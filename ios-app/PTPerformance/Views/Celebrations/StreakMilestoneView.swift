//
//  StreakMilestoneView.swift
//  PTPerformance
//
//  Gamification Polish - Milestone Celebrations & Achievements
//  Celebration animation for reaching streak milestones
//

import SwiftUI

// MARK: - Streak Milestone View

/// Full-screen celebration view for reaching streak milestones
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

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.orange.opacity(0.3),
                    Color.red.opacity(0.2),
                    Color.black.opacity(0.9)
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

                // Animated flame
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.orange.opacity(0.6), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(showContent ? 1.2 : 0.5)
                        .opacity(showContent ? 1 : 0)

                    // Flame icon
                    Image(systemName: "flame.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange, .red],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(flameScale)
                        .shadow(color: .orange.opacity(0.8), radius: 20, x: 0, y: 10)
                }

                // Streak number
                VStack(spacing: Spacing.xs) {
                    Text("\(currentStreak)")
                        .font(.system(size: 80, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .orange.opacity(0.5), radius: 10)
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
                        .foregroundColor(.orange)

                    Text(milestone.celebrationMessage)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }
                .opacity(messageOpacity)

                Spacer()

                // Dismiss button
                Button(action: {
                    HapticFeedback.light()
                    onDismiss()
                }) {
                    Text("Keep Going!")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.horizontal, Spacing.xxl)
                        .padding(.vertical, Spacing.md)
                        .background(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(CornerRadius.lg)
                        .shadow(color: .orange.opacity(0.5), radius: 10)
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

        // Number animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3)) {
            numberScale = 1.0
            numberOffset = 0
        }

        // Message fade in
        withAnimation(.easeIn(duration: 0.4).delay(0.5)) {
            messageOpacity = 1.0
        }

        // Button fade in
        withAnimation(.easeIn(duration: 0.3).delay(0.8)) {
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
struct ConfettiView: View {
    let count: Int

    @State private var particles: [StreakConfettiParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    StreakConfettiParticleView(particle: particle)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
            }
        }
        .ignoresSafeArea()
    }

    private func createParticles(in size: CGSize) {
        particles = (0..<count).map { _ in
            StreakConfettiParticle(
                x: CGFloat.random(in: 0...size.width),
                y: -20,
                targetY: size.height + 50,
                color: [Color.red, .orange, .yellow, .green, .blue, .purple, .pink].randomElement()!,
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

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap?()
        }) {
            HStack(spacing: Spacing.md) {
                // Flame with animation
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: "flame.fill")
                        .font(.title)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange, .red],
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
                    .foregroundColor(.orange)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.orange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
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
        }
    }
}
#endif
