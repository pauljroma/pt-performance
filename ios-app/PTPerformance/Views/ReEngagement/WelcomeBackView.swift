//
//  WelcomeBackView.swift
//  PTPerformance
//
//  ACP-1005: Re-engagement Campaigns
//  Welcome-back screen shown when a user returns after 7+ days of inactivity.
//  Provides a warm greeting, missed activity summary, quick-start option,
//  and optional special offer card.
//

import SwiftUI

// MARK: - Welcome Back View

/// Full-screen welcome back experience for returning inactive users.
///
/// Shown as a sheet or full-screen cover when `ReEngagementService.showWelcomeBack` is true.
/// Displays a personalized greeting, highlights what the user missed,
/// and provides a friction-free path back to training.
struct WelcomeBackView: View {

    // MARK: - Properties

    @StateObject private var reEngagementService = ReEngagementService.shared
    @State private var contentAppeared = false
    @State private var offerAppeared = false
    @Environment(\.dismiss) private var dismiss

    /// Callback when the user taps "Start Quick Workout".
    var onStartWorkout: (() -> Void)?

    /// Callback when the view is dismissed.
    var onDismiss: (() -> Void)?

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.modusCyan.opacity(0.15),
                    Color(.systemBackground)
                ]),
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    Spacer()
                        .frame(height: Spacing.xl)

                    // Welcome illustration
                    welcomeIllustration
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : -20)

                    // Greeting
                    greetingSection
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : 10)

                    // What you missed
                    if let summary = reEngagementService.missedSummary {
                        missedSection(summary: summary)
                            .opacity(contentAppeared ? 1 : 0)
                    }

                    // Special offer card
                    if let offer = reEngagementService.reEngagementOffer, !offer.isExpired {
                        offerCard(offer: offer)
                            .opacity(offerAppeared ? 1 : 0)
                            .offset(y: offerAppeared ? 0 : 15)
                    }

                    Spacer()
                        .frame(height: Spacing.md)

                    // Action buttons
                    actionButtons

                    Spacer()
                        .frame(height: Spacing.lg)
                }
                .padding(.horizontal, Spacing.md)
            }
        }
        .onAppear {
            DebugLogger.shared.info("WelcomeBackView", "Displayed for user inactive \(reEngagementService.daysSinceLastActivity) days")

            withAnimation(.easeOut(duration: AnimationDuration.slow)) {
                contentAppeared = true
            }
            withAnimation(.easeOut(duration: AnimationDuration.slow).delay(0.4)) {
                offerAppeared = true
            }

            ErrorLogger.shared.logUserAction(
                action: "welcome_back_shown",
                properties: [
                    "days_inactive": String(reEngagementService.daysSinceLastActivity),
                    "has_offer": String(reEngagementService.reEngagementOffer != nil)
                ]
            )
        }
    }

    // MARK: - Welcome Illustration

    private var welcomeIllustration: some View {
        ZStack {
            Circle()
                .fill(Color.modusCyan.opacity(0.1))
                .frame(width: 140, height: 140)

            Circle()
                .fill(Color.modusCyan.opacity(0.05))
                .frame(width: 180, height: 180)

            Image(systemName: "hand.wave.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.modusCyan, .modusCyan.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .accessibilityHidden(true)
    }

    // MARK: - Greeting Section

    private var greetingSection: some View {
        VStack(spacing: Spacing.sm) {
            Text("Welcome Back!")
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            if let summary = reEngagementService.missedSummary {
                Text(summary.greetingMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.md)
            }
        }
    }

    // MARK: - What You Missed

    private func missedSection(summary: MissedActivitySummary) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("While You Were Away")
                .font(.headline)
                .padding(.bottom, Spacing.xxs)
                .accessibilityAddTraits(.isHeader)

            ForEach(summary.featureHighlights, id: \.self) { highlight in
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Image(systemName: "sparkle")
                        .font(.caption)
                        .foregroundColor(.modusCyan)
                        .frame(width: 20, height: 20)
                        .accessibilityHidden(true)

                    Text(highlight)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Offer Card

    private func offerCard(offer: ReEngagementOffer) -> some View {
        VStack(spacing: Spacing.sm) {
            // Offer badge
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundColor(.white)
                Text("Special Offer")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(Color.orange)
            .cornerRadius(CornerRadius.xl)

            Text(offer.title)
                .font(.title3.weight(.bold))
                .multilineTextAlignment(.center)

            Text(offer.message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.sm)

            // Discount display
            HStack(spacing: Spacing.xs) {
                Text("\(offer.discountPercent)% OFF")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
            }

            if let promoCode = offer.promoCode {
                HStack(spacing: Spacing.xxs) {
                    Text("Code:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(promoCode)
                        .font(.caption.weight(.bold).monospaced())
                        .foregroundColor(.modusCyan)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, 2)
                        .background(Color.modusCyan.opacity(0.1))
                        .cornerRadius(CornerRadius.xs)
                }
            }

            Text(offer.expiryText)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.systemBackground))
                .shadow(
                    color: Color.orange.opacity(0.15),
                    radius: 12,
                    x: 0,
                    y: 4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: Spacing.sm) {
            // Primary: Quick Start
            Button(action: handleStartWorkout) {
                HStack {
                    Image(systemName: "bolt.fill")
                    Text("Start Quick Workout")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(Color.modusCyan)
                .cornerRadius(CornerRadius.md)
            }
            .accessibilityLabel("Start a quick workout")
            .accessibilityHint("Jump right into a short training session")

            // Secondary: Continue to app
            Button(action: handleDismiss) {
                Text("Continue to App")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, Spacing.xs)
            }
            .accessibilityLabel("Continue to the main app")
        }
    }

    // MARK: - Actions

    private func handleStartWorkout() {
        HapticFeedback.medium()
        DebugLogger.shared.info("WelcomeBackView", "User tapped Start Quick Workout")

        ErrorLogger.shared.logUserAction(
            action: "welcome_back_start_workout",
            properties: [
                "days_inactive": String(reEngagementService.daysSinceLastActivity)
            ]
        )

        // Record the user as active again
        reEngagementService.recordActivity()
        reEngagementService.dismissWelcomeBack()

        onStartWorkout?()
        dismiss()
    }

    private func handleDismiss() {
        HapticFeedback.light()
        DebugLogger.shared.info("WelcomeBackView", "User dismissed welcome back screen")

        ErrorLogger.shared.logUserAction(
            action: "welcome_back_dismissed",
            properties: [
                "days_inactive": String(reEngagementService.daysSinceLastActivity)
            ]
        )

        // Record the user as active again
        reEngagementService.recordActivity()
        reEngagementService.dismissWelcomeBack()

        onDismiss?()
        dismiss()
    }
}

// MARK: - Preview

#if DEBUG
struct WelcomeBackView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeBackView()
    }
}
#endif
