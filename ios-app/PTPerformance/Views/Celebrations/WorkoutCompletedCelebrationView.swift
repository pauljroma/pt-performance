//
//  WorkoutCompletedCelebrationView.swift
//  PTPerformance
//
//  Gamification Polish - Milestone Celebrations & Achievements
//  Celebration overlay shown after completing a workout
//

import SwiftUI

// MARK: - Workout Completed Celebration View

/// Celebration view shown after completing a workout
/// Checks for streak milestones and new achievements
struct WorkoutCompletedCelebrationView: View {
    let workoutName: String
    let duration: Int? // in minutes
    let volume: Double? // total volume lifted
    let exerciseCount: Int
    let currentStreak: Int
    let onDismiss: () -> Void
    let onViewAchievements: (() -> Void)?

    @State private var showContent = false
    @State private var checkScale: CGFloat = 0.1
    @State private var statsOpacity: Double = 0
    @State private var streakOpacity: Double = 0
    @State private var buttonsOpacity: Double = 0
    @State private var showConfetti = false

    private var streakMilestone: StreakMilestone? {
        StreakMilestone.milestone(for: currentStreak)
    }

    private var isMilestone: Bool {
        streakMilestone != nil
    }

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            // Confetti for milestones
            if showConfetti && isMilestone {
                ConfettiView(count: streakMilestone?.confettiCount ?? 30)
            }

            // Content
            VStack(spacing: Spacing.xl) {
                Spacer()

                // Checkmark animation
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.green.opacity(0.5), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 100
                            )
                        )
                        .frame(width: 180, height: 180)
                        .opacity(showContent ? 1 : 0)

                    Circle()
                        .fill(Color.green)
                        .frame(width: 100, height: 100)
                        .scaleEffect(checkScale)
                        .shadow(color: .green.opacity(0.5), radius: 20)

                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(checkScale)
                }

                // Workout complete text
                VStack(spacing: Spacing.sm) {
                    Text("WORKOUT COMPLETE")
                        .font(.title2)
                        .fontWeight(.black)
                        .foregroundColor(.green)
                        .tracking(2)

                    Text(workoutName)
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                }
                .opacity(showContent ? 1 : 0)

                // Stats row
                HStack(spacing: Spacing.xl) {
                    if let duration = duration {
                        StatBubble(
                            value: "\(duration)",
                            unit: "min",
                            icon: "clock.fill"
                        )
                    }

                    StatBubble(
                        value: "\(exerciseCount)",
                        unit: exerciseCount == 1 ? "exercise" : "exercises",
                        icon: "figure.strengthtraining.traditional"
                    )

                    if let volume = volume, volume > 0 {
                        StatBubble(
                            value: formatVolume(volume),
                            unit: "volume",
                            icon: "scalemass.fill"
                        )
                    }
                }
                .opacity(statsOpacity)

                // Streak section
                if currentStreak > 0 {
                    VStack(spacing: Spacing.sm) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.yellow, .orange, .red],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                            Text("\(currentStreak) Day Streak")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .font(.title2)

                        if let milestone = streakMilestone {
                            Text(milestone.celebrationMessage)
                                .font(.subheadline)
                                .foregroundColor(.orange)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.xs)
                                .background(
                                    Capsule()
                                        .fill(Color.orange.opacity(0.2))
                                )
                        }
                    }
                    .opacity(streakOpacity)
                }

                Spacer()

                // Buttons
                VStack(spacing: Spacing.md) {
                    if onViewAchievements != nil {
                        Button(action: {
                            HapticFeedback.light()
                            onViewAchievements?()
                        }) {
                            HStack {
                                Image(systemName: "trophy.fill")
                                Text("View Achievements")
                            }
                            .font(.headline)
                            .foregroundColor(.yellow)
                            .padding(.horizontal, Spacing.xl)
                            .padding(.vertical, Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.md)
                                    .stroke(Color.yellow, lineWidth: 2)
                            )
                        }
                    }

                    Button(action: {
                        HapticFeedback.light()
                        onDismiss()
                    }) {
                        Text("Done")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.horizontal, Spacing.xxl)
                            .padding(.vertical, Spacing.md)
                            .background(
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.8)],
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
            HapticFeedback.success()
        }
    }

    // MARK: - Animation

    private func animateIn() {
        // Confetti for milestones
        if isMilestone {
            withAnimation(.easeOut(duration: 0.2)) {
                showConfetti = true
            }
        }

        // Checkmark
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
            checkScale = 1.0
            showContent = true
        }

        // Stats
        withAnimation(.easeIn(duration: 0.4).delay(0.3)) {
            statsOpacity = 1.0
        }

        // Streak
        withAnimation(.easeIn(duration: 0.4).delay(0.5)) {
            streakOpacity = 1.0
        }

        // Buttons
        withAnimation(.easeIn(duration: 0.3).delay(0.7)) {
            buttonsOpacity = 1.0
        }

        // Haptic sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            HapticFeedback.heavy()
        }
        if isMilestone {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                HapticFeedback.heavy()
            }
        }
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }
}

// MARK: - Stat Bubble

struct StatBubble: View {
    let value: String
    let unit: String
    let icon: String

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(unit)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(width: 80)
    }
}

// MARK: - Workout Summary Card with Celebration

/// Card shown after workout completion with optional celebration elements
/// Tappable to show enhanced summary
struct WorkoutSummaryCard: View {
    let workoutName: String
    let completedAt: Date
    let duration: Int?
    let volume: Double?
    let exerciseCount: Int
    let newPRs: [String] // Exercise names with new PRs
    let currentStreak: Int
    let onTap: (() -> Void)?

    @State private var showEnhancedSummary = false

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            if let onTap = onTap {
                onTap()
            } else {
                showEnhancedSummary = true
            }
        }) {
            cardContent
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showEnhancedSummary) {
            // Enhanced summary placeholder - will be populated with actual data
            Text("Enhanced Summary Coming Soon")
        }
    }

    private var cardContent: some View {
        VStack(spacing: Spacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Workout Complete")
                        .font(.headline)

                    Text(workoutName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.green)
            }

            Divider()

            // Stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.md) {
                if let duration = duration {
                    CelebrationStatCell(label: "Duration", value: "\(duration) min", icon: "clock.fill", color: .modusCyan)
                }

                CelebrationStatCell(label: "Exercises", value: "\(exerciseCount)", icon: "figure.strengthtraining.traditional", color: .green)

                if let volume = volume, volume > 0 {
                    CelebrationStatCell(label: "Volume", value: formatVolume(volume), icon: "scalemass.fill", color: .purple)
                }
            }

            // New PRs section
            if !newPRs.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.yellow)
                        Text("New Personal Records!")
                            .font(.headline)
                    }

                    ForEach(newPRs, id: \.self) { exercise in
                        HStack {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text(exercise)
                                .font(.subheadline)
                        }
                    }
                }
            }

            // Streak indicator
            if currentStreak > 0 {
                Divider()

                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(currentStreak) day streak")
                        .fontWeight(.medium)

                    Spacer()

                    if let milestone = StreakMilestone.highestAchieved(for: currentStreak) {
                        Text(milestone.displayName)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background(Color.orange)
                            .cornerRadius(CornerRadius.xs)
                    }
                }
            }

            // Tap to view detail indicator
            HStack {
                Spacer()
                Text("Tap for detailed summary")
                    .font(.caption)
                    .foregroundColor(.modusCyan)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.modusCyan)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .adaptiveShadow(Shadow.medium)
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk lbs", volume / 1000)
        }
        return "\(Int(volume)) lbs"
    }
}

private struct CelebrationStatCell: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.headline)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct WorkoutCompletedCelebrationView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WorkoutCompletedCelebrationView(
                workoutName: "Push Day",
                duration: 45,
                volume: 12500,
                exerciseCount: 6,
                currentStreak: 7,
                onDismiss: {},
                onViewAchievements: {}
            )
            .previewDisplayName("7 Day Milestone")

            WorkoutCompletedCelebrationView(
                workoutName: "Full Body Workout",
                duration: 60,
                volume: 18000,
                exerciseCount: 8,
                currentStreak: 15,
                onDismiss: {},
                onViewAchievements: nil
            )
            .previewDisplayName("Regular Completion")

            WorkoutSummaryCard(
                workoutName: "Upper Body",
                completedAt: Date(),
                duration: 45,
                volume: 15000,
                exerciseCount: 7,
                newPRs: ["Bench Press", "Overhead Press"],
                currentStreak: 14,
                onTap: nil
            )
            .padding()
            .previewDisplayName("Summary Card")
        }
    }
}
#endif
