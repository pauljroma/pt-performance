//
//  CelebrationOverlayModifier.swift
//  PTPerformance
//
//  Gamification Polish - Milestone Celebrations & Achievements
//  View modifier for adding celebration overlays to any view
//

import SwiftUI

// MARK: - Celebration Overlay Modifier

/// View modifier that adds celebration overlays for achievements, streaks, and PRs
struct CelebrationOverlayModifier: ViewModifier {
    @ObservedObject var achievementService: AchievementService

    @State private var showAchievementCelebration = false
    @State private var showStreakCelebration = false
    @State private var showPRCelebration = false

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $showAchievementCelebration) {
                if let event = achievementService.pendingCelebration {
                    AchievementUnlockedView(
                        event: event,
                        onDismiss: {
                            achievementService.clearPendingCelebration()
                            showAchievementCelebration = false
                        },
                        onShare: {
                            // Share functionality
                        }
                    )
                }
            }
            .fullScreenCover(isPresented: $showStreakCelebration) {
                if let milestone = achievementService.pendingStreakMilestone {
                    StreakMilestoneView(
                        milestone: milestone,
                        currentStreak: milestone.rawValue,
                        onDismiss: {
                            achievementService.clearStreakMilestone()
                            showStreakCelebration = false
                        }
                    )
                }
            }
            .fullScreenCover(isPresented: $showPRCelebration) {
                if let prData = achievementService.pendingPRCelebration {
                    PRCelebrationView(
                        data: prData,
                        onDismiss: {
                            achievementService.clearPRCelebration()
                            showPRCelebration = false
                        },
                        onShare: {
                            // Share functionality
                        }
                    )
                }
            }
            .onChange(of: achievementService.pendingCelebration) { _, newValue in
                if newValue != nil {
                    showAchievementCelebration = true
                }
            }
            .onChange(of: achievementService.pendingStreakMilestone) { _, newValue in
                if newValue != nil {
                    showStreakCelebration = true
                }
            }
            .onChange(of: achievementService.pendingPRCelebration) { _, newValue in
                if newValue != nil {
                    showPRCelebration = true
                }
            }
    }
}

// MARK: - View Extension

extension View {
    /// Adds celebration overlays for achievements, streaks, and PRs
    func celebrationOverlay(achievementService: AchievementService = .shared) -> some View {
        modifier(CelebrationOverlayModifier(achievementService: achievementService))
    }
}

// MARK: - Celebration Toast View

/// Toast-style celebration notification for less intrusive celebrations
struct CelebrationToast: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let onTap: () -> Void
    let onDismiss: () -> Void

    @State private var offset: CGFloat = -100
    @State private var opacity: Double = 0

    var body: some View {
        VStack {
            Button(action: {
                HapticFeedback.light()
                onTap()
            }) {
                HStack(spacing: Spacing.md) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.2))
                            .frame(width: 44, height: 44)

                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(color)
                    }

                    // Text
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Dismiss button
                    Button(action: {
                        dismissToast()
                    }) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(8)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(Color(.systemBackground))
                        .shadow(color: color.opacity(0.3), radius: 10, y: 5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal)

            Spacer()
        }
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            showToast()
        }
    }

    private func showToast() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            offset = 0
            opacity = 1
        }

        // Auto-dismiss after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            dismissToast()
        }
    }

    private func dismissToast() {
        withAnimation(.easeOut(duration: 0.3)) {
            offset = -100
            opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Inline Celebration Banner

/// Inline celebration banner for showing in list views
struct CelebrationBanner: View {
    let title: String
    let message: String
    let icon: String
    let color: Color
    var action: (() -> Void)?

    @State private var isAnimating = false

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action?()
        }) {
            HStack(spacing: Spacing.md) {
                // Animated icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)

                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.1), color.opacity(0.05)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.0)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Mini Celebration Effect

/// Small celebration particle effect for inline use
struct MiniCelebrationEffect: View {
    let isActive: Bool
    let color: Color

    @State private var particles: [(id: UUID, offset: CGPoint, opacity: Double)] = []

    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { particle in
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                    .offset(x: particle.offset.x, y: particle.offset.y)
                    .opacity(particle.opacity)
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                triggerEffect()
            }
        }
    }

    private func triggerEffect() {
        let newParticles = (0..<8).map { _ -> (id: UUID, offset: CGPoint, opacity: Double) in
            (UUID(), .zero, 1.0)
        }
        particles = newParticles

        for (index, _) in particles.enumerated() {
            let angle = Double(index) * (360.0 / 8.0) * .pi / 180
            let distance: CGFloat = 30

            withAnimation(.easeOut(duration: 0.5)) {
                particles[index].offset = CGPoint(
                    x: cos(angle) * distance,
                    y: sin(angle) * distance
                )
                particles[index].opacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            particles = []
        }
    }
}

// MARK: - Achievements Link Card

/// Card that links to the achievements dashboard
struct AchievementsLinkCard: View {
    let patientId: UUID
    @ObservedObject var achievementService: AchievementService

    var body: some View {
        NavigationLink {
            AchievementsDashboardView(patientId: patientId)
        } label: {
            HStack(spacing: Spacing.md) {
                // Trophy icon with badge count
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "trophy.fill")
                        .font(.title)
                        .foregroundColor(.yellow)

                    if recentCount > 0 {
                        Text("\(recentCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Circle().fill(Color.red))
                            .offset(x: 8, y: -8)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Achievements")
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text("\(achievementService.totalPoints) points")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("-")
                            .foregroundColor(.secondary)

                        Text("\(unlockedCount)/\(AchievementCatalog.all.count) unlocked")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .adaptiveShadow(Shadow.subtle)
        }
        .buttonStyle(.plain)
    }

    private var unlockedCount: Int {
        achievementService.achievementProgress.filter { $0.isUnlocked }.count
    }

    private var recentCount: Int {
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return achievementService.achievementProgress.filter {
            $0.isUnlocked && ($0.unlockedAt ?? .distantPast) > oneDayAgo
        }.count
    }
}

// MARK: - Preview

#if DEBUG
struct CelebrationOverlay_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CelebrationToast(
                title: "Achievement Unlocked!",
                subtitle: "You've completed your 7-day streak",
                icon: "trophy.fill",
                color: .yellow,
                onTap: {},
                onDismiss: {}
            )
            .previewDisplayName("Toast")

            CelebrationBanner(
                title: "New Personal Record!",
                message: "Bench Press: 225 lbs",
                icon: "trophy.fill",
                color: .yellow
            )
            .padding()
            .previewDisplayName("Banner")

            AchievementsLinkCard(
                patientId: UUID(),
                achievementService: .preview
            )
            .padding()
            .previewDisplayName("Link Card")
        }
    }
}
#endif
