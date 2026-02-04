import SwiftUI

/// View displayed when today's session has been completed
/// Shows success message, metrics summary, and options for next steps
struct SessionCompletedView: View {
    let session: Session?
    let onBrowseLibrary: () -> Void
    let onCreateCustomWorkout: () -> Void
    let onViewSummary: () -> Void
    var currentStreak: Int = 0
    var onViewAchievements: (() -> Void)?

    @State private var showConfetti = false
    @State private var celebrationScale: CGFloat = 0.8

    private var streakMilestone: StreakMilestone? {
        StreakMilestone.milestone(for: currentStreak)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                // Success icon and message
                successSection

                // Streak celebration (if milestone)
                if let milestone = streakMilestone {
                    streakMilestoneSection(milestone)
                } else if currentStreak > 0 {
                    streakSection
                }

                Divider()
                    .padding(.vertical, 8)

                // Options for next steps
                nextStepsSection
            }
            .padding(DesignTokens.spacingXLarge)
            .background(Color(.systemBackground))
            .cornerRadius(DesignTokens.cornerRadiusLarge)
            .adaptiveShadow(Shadow.medium)
            .padding()

            // Confetti overlay for milestones
            if showConfetti, let milestone = streakMilestone {
                ConfettiView(count: milestone.confettiCount)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            if streakMilestone != nil {
                withAnimation(.easeOut(duration: 0.3)) {
                    showConfetti = true
                }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    celebrationScale = 1.0
                }
                HapticFeedback.success()
            }
        }
    }

    // MARK: - Success Section

    @ViewBuilder
    private var successSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(.green)
                .scaleEffect(celebrationScale)

            Text("Session Complete!")
                .font(.title)
                .bold()

            if let session = session {
                Text(session.name)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }

            // Show metrics if available
            if let session = session {
                metricsRow(session)
            }
        }
    }

    // MARK: - Streak Section

    @ViewBuilder
    private var streakSection: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "flame.fill")
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text("\(currentStreak) day streak!")
                .fontWeight(.semibold)

            Spacer()

            if let nextMilestone = StreakMilestone.allCases.first(where: { $0.rawValue > currentStreak }) {
                Text("\(nextMilestone.rawValue - currentStreak) to \(nextMilestone.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.orange.opacity(0.1))
        )
    }

    // MARK: - Streak Milestone Section

    @ViewBuilder
    private func streakMilestoneSection(_ milestone: StreakMilestone) -> some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange, .red],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Text("\(currentStreak) DAY STREAK!")
                    .font(.title2)
                    .fontWeight(.black)
                    .foregroundColor(.orange)
            }
            .scaleEffect(celebrationScale)

            Text(milestone.celebrationMessage)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            if let onViewAchievements = onViewAchievements {
                Button(action: {
                    HapticFeedback.light()
                    onViewAchievements()
                }) {
                    HStack {
                        Image(systemName: "trophy.fill")
                        Text("View Achievements")
                    }
                    .font(.subheadline)
                    .foregroundColor(.yellow)
                }
                .padding(.top, Spacing.xs)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.2), Color.red.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private func metricsRow(_ session: Session) -> some View {
        HStack(spacing: 24) {
            if let volume = session.total_volume, volume > 0 {
                VStack {
                    Text(volume >= 1000 ? String(format: "%.1fk", volume / 1000) : "\(Int(volume))")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("lbs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let duration = session.duration_minutes {
                VStack {
                    Text("\(duration)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let rpe = session.avg_rpe {
                VStack {
                    Text(String(format: "%.1f", rpe))
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("RPE")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Next Steps Section

    @ViewBuilder
    private var nextStepsSection: some View {
        VStack(spacing: 12) {
            Text("Want to do more?")
                .font(.headline)
                .foregroundColor(.secondary)

            // Start another workout from library
            Button(action: {
                HapticFeedback.light()
                onBrowseLibrary()
            }) {
                HStack {
                    Image(systemName: "books.vertical.fill")
                    Text("Browse Workout Library")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(DesignTokens.cornerRadiusMedium)
            }
            .accessibilityLabel("Browse Workout Library")
            .accessibilityHint("Opens saved workout templates")

            // Create custom workout
            Button(action: {
                HapticFeedback.light()
                onCreateCustomWorkout()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Custom Workout")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.15))
                .foregroundColor(.green)
                .cornerRadius(DesignTokens.cornerRadiusMedium)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium)
                        .stroke(Color.green, lineWidth: 1)
                )
            }
            .accessibilityLabel("Create Custom Workout")
            .accessibilityHint("Opens workout builder to create a new workout")

            // View summary
            Button(action: onViewSummary) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                    Text("View Session Summary")
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            .padding(.top, 8)
            .accessibilityLabel("View Session Summary")
            .accessibilityHint("Shows detailed summary of completed workout")
        }
    }
}

#if DEBUG
struct SessionCompletedView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SessionCompletedView(
                session: nil,
                onBrowseLibrary: {},
                onCreateCustomWorkout: {},
                onViewSummary: {},
                currentStreak: 3
            )
            .previewDisplayName("Regular Completion")

            SessionCompletedView(
                session: nil,
                onBrowseLibrary: {},
                onCreateCustomWorkout: {},
                onViewSummary: {},
                currentStreak: 7,
                onViewAchievements: {}
            )
            .previewDisplayName("7 Day Milestone")

            SessionCompletedView(
                session: nil,
                onBrowseLibrary: {},
                onCreateCustomWorkout: {},
                onViewSummary: {},
                currentStreak: 30,
                onViewAchievements: {}
            )
            .previewDisplayName("30 Day Milestone")
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
