//
//  RTSMilestoneCelebrationView.swift
//  PTPerformance
//
//  Phase completion celebration for Return-to-Sport protocols
//  Shows celebration animation with confetti and next phase preview
//

import SwiftUI

// MARK: - RTS Milestone Celebration View

/// Phase completion celebration view
struct RTSMilestoneCelebrationView: View {
    let phase: RTSPhase
    let nextPhase: RTSPhase?
    var onDismiss: (() -> Void)?
    var onContinue: (() -> Void)?

    @State private var showContent = false
    @State private var showConfetti = false
    @State private var checkmarkScale: CGFloat = 0.1
    @State private var phaseNameScale: CGFloat = 0.5
    @State private var phaseNameOffset: CGFloat = 50
    @State private var messageOpacity: Double = 0
    @State private var nextPhaseOpacity: Double = 0
    @State private var buttonOpacity: Double = 0

    var body: some View {
        ZStack {
            // Background gradient based on traffic light
            backgroundGradient

            // Confetti particles
            if showConfetti {
                RTSConfettiView(count: 60, colors: confettiColors)
            }

            // Main content
            VStack(spacing: Spacing.xl) {
                Spacer()

                // Animated checkmark with traffic light
                checkmarkAnimation

                // Phase completed text
                phaseCompletedText

                // Traffic light progression
                trafficLightProgression

                // Next phase preview
                if let nextPhase = nextPhase {
                    nextPhasePreview(nextPhase)
                }

                Spacer()

                // Action buttons
                actionButtons
            }
        }
        .onAppear {
            animateIn()
            HapticFeedback.success()
        }
    }

    // MARK: - Background Gradient

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                phase.activityLevel.color.opacity(0.3),
                phase.activityLevel.color.opacity(0.1),
                Color.black.opacity(0.9)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var confettiColors: [Color] {
        switch phase.activityLevel {
        case .green:
            return [.green, .mint, .cyan, .white, .yellow]
        case .yellow:
            return [.yellow, .orange, .gold, .white, .green]
        case .red:
            return [.red, .orange, .pink, .white, .yellow]
        }
    }

    // MARK: - Checkmark Animation

    private var checkmarkAnimation: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [phase.activityLevel.color.opacity(0.6), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .scaleEffect(showContent ? 1.2 : 0.5)
                .opacity(showContent ? 1 : 0)

            // Traffic light circle
            Circle()
                .fill(phase.activityLevel.color)
                .frame(width: 120, height: 120)
                .scaleEffect(checkmarkScale)
                .shadow(color: phase.activityLevel.color.opacity(0.5), radius: 20, x: 0, y: 10)

            // Checkmark icon
            Image(systemName: "checkmark")
                .font(.system(size: 56, weight: .bold))
                .foregroundColor(.white)
                .scaleEffect(checkmarkScale)
        }
        .accessibilityLabel("Phase completed checkmark")
    }

    // MARK: - Phase Completed Text

    private var phaseCompletedText: some View {
        VStack(spacing: Spacing.xs) {
            Text("Phase Complete!")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, phase.activityLevel.color],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: phase.activityLevel.color.opacity(0.5), radius: 10)
                .scaleEffect(phaseNameScale)
                .offset(y: phaseNameOffset)

            Text(phase.phaseName)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.9))
                .scaleEffect(phaseNameScale)
                .offset(y: phaseNameOffset)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Phase complete: \(phase.phaseName)")
    }

    // MARK: - Traffic Light Progression

    private var trafficLightProgression: some View {
        HStack(spacing: Spacing.lg) {
            // Completed phases (represented by previous traffic lights)
            ForEach(RTSTrafficLight.allCases.reversed(), id: \.self) { light in
                VStack(spacing: Spacing.xs) {
                    ZStack {
                        Circle()
                            .fill(light.color.opacity(isCurrentOrPast(light) ? 1.0 : 0.3))
                            .frame(width: 40, height: 40)

                        if isCurrentOrPast(light) && light != phase.activityLevel {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        } else if light == phase.activityLevel {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }

                    Text(light.displayName)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(isCurrentOrPast(light) ? 0.9 : 0.4))
                }
            }
        }
        .opacity(messageOpacity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress: Completed \(phase.activityLevel.displayName) phase")
    }

    private func isCurrentOrPast(_ light: RTSTrafficLight) -> Bool {
        switch phase.activityLevel {
        case .green:
            return true
        case .yellow:
            return light == .yellow || light == .red
        case .red:
            return light == .red
        }
    }

    // MARK: - Next Phase Preview

    private func nextPhasePreview(_ nextPhase: RTSPhase) -> some View {
        VStack(spacing: Spacing.sm) {
            Text("Up Next")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            HStack(spacing: Spacing.md) {
                RTSTrafficLightBadge(
                    level: nextPhase.activityLevel,
                    size: .medium
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(nextPhase.phaseName)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(nextPhase.activityLevel.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(Spacing.md)
            .background(Color.white.opacity(0.15))
            .cornerRadius(CornerRadius.md)
            .padding(.horizontal, Spacing.lg)
        }
        .opacity(nextPhaseOpacity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Next phase: \(nextPhase.phaseName), \(nextPhase.activityLevel.displayName)")
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: Spacing.sm) {
            // Continue button
            Button(action: {
                HapticFeedback.light()
                onContinue?()
            }) {
                HStack {
                    Text(nextPhase != nil ? "Continue to Next Phase" : "View Progress")
                    Image(systemName: "arrow.right")
                }
                .font(.headline)
                .foregroundColor(.black)
                .padding(.horizontal, Spacing.xxl)
                .padding(.vertical, Spacing.md)
                .background(
                    LinearGradient(
                        colors: [.white, phase.activityLevel.color.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(CornerRadius.lg)
                .shadow(color: phase.activityLevel.color.opacity(0.5), radius: 10)
            }
            .accessibilityLabel(nextPhase != nil ? "Continue to next phase" : "View progress")

            // Dismiss button
            Button(action: {
                HapticFeedback.light()
                onDismiss?()
            }) {
                Text("Dismiss")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .accessibilityLabel("Dismiss celebration")
        }
        .opacity(buttonOpacity)
        .padding(.bottom, Spacing.xxl)
    }

    // MARK: - Animation

    private func animateIn() {
        // Confetti immediately
        withAnimation(.easeOut(duration: 0.3)) {
            showConfetti = true
        }

        // Checkmark animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1)) {
            checkmarkScale = 1.0
            showContent = true
        }

        // Phase name animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3)) {
            phaseNameScale = 1.0
            phaseNameOffset = 0
        }

        // Message fade in
        withAnimation(.easeIn(duration: 0.4).delay(0.5)) {
            messageOpacity = 1.0
        }

        // Next phase fade in
        withAnimation(.easeIn(duration: 0.4).delay(0.7)) {
            nextPhaseOpacity = 1.0
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

// MARK: - RTS Confetti View

/// Animated confetti particles for celebration
struct RTSConfettiView: View {
    let count: Int
    let colors: [Color]

    @State private var particles: [RTSConfettiParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    RTSConfettiParticleView(particle: particle)
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
            RTSConfettiParticle(
                x: CGFloat.random(in: 0...size.width),
                y: -20,
                targetY: size.height + 50,
                color: colors.randomElement() ?? .white,
                size: CGFloat.random(in: 6...14),
                rotation: Double.random(in: 0...360),
                delay: Double.random(in: 0...0.6),
                shape: RTSConfettiShape.allCases.randomElement() ?? .rectangle
            )
        }
    }
}

// MARK: - Confetti Particle

struct RTSConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let targetY: CGFloat
    let color: Color
    let size: CGFloat
    let rotation: Double
    let delay: Double
    let shape: RTSConfettiShape
}

enum RTSConfettiShape: CaseIterable {
    case rectangle
    case circle
    case triangle
}

struct RTSConfettiParticleView: View {
    let particle: RTSConfettiParticle

    @State private var currentY: CGFloat
    @State private var currentRotation: Double
    @State private var opacity: Double = 1

    init(particle: RTSConfettiParticle) {
        self.particle = particle
        _currentY = State(initialValue: particle.y)
        _currentRotation = State(initialValue: particle.rotation)
    }

    var body: some View {
        Group {
            switch particle.shape {
            case .rectangle:
                Rectangle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size * 0.6)

            case .circle:
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size * 0.8, height: particle.size * 0.8)

            case .triangle:
                Triangle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
            }
        }
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
                .delay(particle.delay + 2.5)
            ) {
                opacity = 0
            }
        }
    }
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Gold Color Extension

extension Color {
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
}

// MARK: - Preview

#if DEBUG
struct RTSMilestoneCelebrationView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Green phase complete with next phase
            RTSMilestoneCelebrationView(
                phase: RTSPhase(
                    protocolId: UUID(),
                    phaseNumber: 3,
                    phaseName: "Progressive Activity",
                    activityLevel: .yellow,
                    description: "Increased intensity training",
                    completedAt: Date()
                ),
                nextPhase: RTSPhase(
                    protocolId: UUID(),
                    phaseNumber: 4,
                    phaseName: "Full Clearance",
                    activityLevel: .green,
                    description: "Return to unrestricted activity"
                ),
                onDismiss: {},
                onContinue: {}
            )
            .previewDisplayName("Yellow to Green")

            // Final phase complete
            RTSMilestoneCelebrationView(
                phase: RTSPhase(
                    protocolId: UUID(),
                    phaseNumber: 4,
                    phaseName: "Full Return to Sport",
                    activityLevel: .green,
                    description: "Complete clearance achieved",
                    completedAt: Date()
                ),
                nextPhase: nil,
                onDismiss: {},
                onContinue: {}
            )
            .previewDisplayName("Final Phase Complete")

            // Red phase complete
            RTSMilestoneCelebrationView(
                phase: RTSPhase(
                    protocolId: UUID(),
                    phaseNumber: 1,
                    phaseName: "Protected Motion",
                    activityLevel: .red,
                    description: "Initial recovery phase",
                    completedAt: Date()
                ),
                nextPhase: RTSPhase(
                    protocolId: UUID(),
                    phaseNumber: 2,
                    phaseName: "Light Activity",
                    activityLevel: .yellow,
                    description: "Begin controlled movements"
                ),
                onDismiss: {},
                onContinue: {}
            )
            .previewDisplayName("Red to Yellow")
        }
    }
}
#endif
