//
//  CheckInCompletionView.swift
//  PTPerformance
//
//  X2Index M8: Check-In Completion View
//  Success animation with streak count and readiness preview
//

import SwiftUI

// MARK: - Check-In Completion View

/// Displays completion celebration after successful check-in
///
/// Features:
/// - Animated success indicator
/// - Streak count with badge
/// - Readiness preview based on input
/// - "View Your Plan" CTA
struct CheckInCompletionView: View {

    // MARK: - Properties

    let checkIn: DailyCheckIn?
    let streak: CheckInStreak?
    let onViewPlan: () -> Void
    let onDismiss: () -> Void

    // Animation states
    @State private var showCheckmark = false
    @State private var showContent = false
    @State private var showButtons = false
    @State private var pulseAnimation = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    readinessColor.opacity(0.3),
                    Color(.systemBackground)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Success animation
                successAnimation

                // Content
                if showContent {
                    contentSection
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()

                // Buttons
                if showButtons {
                    buttonsSection
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding()
        }
        .onAppear {
            animateIn()
        }
    }

    // MARK: - Success Animation

    private var successAnimation: some View {
        ZStack {
            // Pulsing background circle
            Circle()
                .fill(readinessColor.opacity(0.2))
                .frame(width: 160, height: 160)
                .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                .animation(
                    .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                    value: pulseAnimation
                )

            // Main circle
            Circle()
                .fill(readinessColor)
                .frame(width: 120, height: 120)

            // Checkmark
            if showCheckmark {
                Image(systemName: "checkmark")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.white)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(spacing: 24) {
            // Success message
            VStack(spacing: 8) {
                Text("Check-In Complete!")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Great job staying consistent")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Readiness preview
            readinessPreview

            // Streak display
            if let streak = streak {
                streakDisplay(streak)
            }
        }
    }

    // MARK: - Readiness Preview

    private var readinessPreview: some View {
        VStack(spacing: 12) {
            Text("Today's Readiness")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                // Score circle
                ZStack {
                    Circle()
                        .fill(readinessColor.opacity(0.2))
                        .frame(width: 80, height: 80)

                    VStack(spacing: 2) {
                        Text(String(format: "%.0f", checkIn?.estimatedReadiness ?? 50))
                            .font(.title.bold())
                            .foregroundColor(readinessColor)

                        Text("/100")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Readiness band info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Circle()
                            .fill(readinessColor)
                            .frame(width: 12, height: 12)

                        Text(readinessBandName)
                            .font(.headline)
                            .foregroundColor(readinessColor)
                    }

                    Text(readinessDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    // MARK: - Streak Display

    private func streakDisplay(_ streak: CheckInStreak) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundColor(.orange)

                Text("\(streak.currentStreak)")
                    .font(.title.bold())

                Text("day streak!")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            // Progress to next milestone
            VStack(spacing: 4) {
                let nextMilestone = streak.nextMilestone
                let progress = streak.progressToNextMilestone

                ProgressView(value: progress)
                    .tint(.orange)

                Text("\(nextMilestone - streak.currentStreak) days to \(nextMilestone)-day milestone")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, Spacing.xl)

            // Motivational message
            Text(streak.motivationalMessage)
                .font(.subheadline)
                .foregroundColor(.orange)
                .fontWeight(.medium)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.1))
        )
    }

    // MARK: - Buttons Section

    private var buttonsSection: some View {
        VStack(spacing: 12) {
            // Primary CTA
            Button {
                HapticService.medium()
                onViewPlan()
            } label: {
                HStack {
                    Image(systemName: "figure.run")
                    Text("View Your Plan")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(readinessColor)
                .cornerRadius(CornerRadius.md)
            }
            .accessibilityLabel("View your training plan")
            .accessibilityHint("Opens today's workout based on your readiness")

            // Secondary button
            Button {
                HapticService.light()
                onDismiss()
            } label: {
                Text("Done")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .accessibilityLabel("Close check-in")
        }
        .padding(.bottom, Spacing.md)
    }

    // MARK: - Computed Properties

    private var readinessColor: Color {
        guard let checkIn = checkIn else { return .yellow }

        switch checkIn.readinessBand {
        case .green: return .green
        case .yellow: return .yellow
        case .orange: return .orange
        case .red: return .red
        }
    }

    private var readinessBandName: String {
        guard let checkIn = checkIn else { return "Ready" }

        switch checkIn.readinessBand {
        case .green: return "Ready to Train"
        case .yellow: return "Train with Caution"
        case .orange: return "Reduced Intensity"
        case .red: return "Recovery Day"
        }
    }

    private var readinessDescription: String {
        guard let checkIn = checkIn else { return "" }

        switch checkIn.readinessBand {
        case .green:
            return "You're recovered and ready for a full workout"
        case .yellow:
            return "Minor fatigue detected - consider slight modifications"
        case .orange:
            return "Elevated fatigue - reduce intensity and volume"
        case .red:
            return "High fatigue or pain - focus on recovery today"
        }
    }

    // MARK: - Animation

    private func animateIn() {
        // Checkmark appears first
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            showCheckmark = true
        }

        // Start pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            pulseAnimation = true
        }

        // Content appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.4)) {
                showContent = true
            }
        }

        // Buttons appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.3)) {
                showButtons = true
            }
        }

        // Haptic feedback
        HapticService.success()
    }
}

// MARK: - Preview

#if DEBUG
struct CheckInCompletionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Green readiness
            CheckInCompletionView(
                checkIn: DailyCheckIn(
                    athleteId: UUID(),
                    sleepQuality: 5,
                    soreness: 2,
                    stress: 2,
                    energy: 9,
                    mood: 5
                ),
                streak: CheckInStreak(
                    currentStreak: 7,
                    longestStreak: 14,
                    lastCheckInDate: Date(),
                    totalCheckIns: 30
                ),
                onViewPlan: {},
                onDismiss: {}
            )
            .previewDisplayName("Green Readiness")

            // Yellow readiness
            CheckInCompletionView(
                checkIn: DailyCheckIn(
                    athleteId: UUID(),
                    sleepQuality: 3,
                    soreness: 5,
                    stress: 4,
                    energy: 6,
                    mood: 3
                ),
                streak: CheckInStreak(
                    currentStreak: 3,
                    longestStreak: 7,
                    lastCheckInDate: Date(),
                    totalCheckIns: 10
                ),
                onViewPlan: {},
                onDismiss: {}
            )
            .previewDisplayName("Yellow Readiness")

            // Red readiness
            CheckInCompletionView(
                checkIn: DailyCheckIn(
                    athleteId: UUID(),
                    sleepQuality: 1,
                    soreness: 9,
                    stress: 8,
                    energy: 2,
                    painScore: 7,
                    mood: 2
                ),
                streak: nil,
                onViewPlan: {},
                onDismiss: {}
            )
            .previewDisplayName("Red Readiness - No Streak")
        }
    }
}
#endif
