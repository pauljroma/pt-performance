//
//  TrialPaywallLayout.swift
//  PTPerformance
//
//  ACP-992: Free trial focused paywall layout with timeline visualization,
//  "Cancel anytime" reassurance, trial benefits list, and single CTA.
//

import SwiftUI
import StoreKit

// MARK: - Trial Paywall Layout

struct TrialPaywallLayout: View {
    let variant: PaywallVariant
    let isPurchasing: Bool
    let onStartTrial: () -> Void
    let onRestorePurchases: () -> Void

    @EnvironmentObject private var storeKit: StoreKitService
    @Environment(\.colorScheme) private var colorScheme

    @State private var animateTimeline: Bool = false
    @State private var animateBenefits: Bool = false
    @State private var pulseButton: Bool = false

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // MARK: - Hero
            heroSection

            // MARK: - Title
            titleSection

            // MARK: - Timeline
            trialTimeline

            // MARK: - Cancel Anytime Badge
            cancelAnytimeBadge

            // MARK: - Benefits List
            benefitsList

            // MARK: - CTA
            ctaSection

            // MARK: - Small Print
            smallPrint

            // MARK: - Footer
            footerSection
        }
        .padding(.horizontal, Spacing.lg)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animateTimeline = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4)) {
                animateBenefits = true
            }
            // Delayed pulse for CTA button
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulseButton = true
                }
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.modusCyan.opacity(0.15), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)

            // Shield icon
            Image(systemName: "gift.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.modusCyan, .modusTealAccent],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .symbolEffect(.bounce, options: .speed(0.5))
        }
        .frame(height: 140)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: Spacing.xs) {
            Text(variant.title.isEmpty ? "Start Your 7-Day Free Trial" : variant.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(variant.subtitle.isEmpty
                ? "Experience everything Korza has to offer"
                : variant.subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }

    // MARK: - Trial Timeline

    private var trialTimeline: some View {
        VStack(spacing: 0) {
            // Timeline container
            HStack(alignment: .top, spacing: 0) {
                // Today - Trial Starts
                timelineStep(
                    icon: "play.circle.fill",
                    iconColor: .modusCyan,
                    title: "Today",
                    subtitle: "Start free trial",
                    isFirst: true,
                    isActive: true
                )

                // Day 5 - Reminder
                timelineStep(
                    icon: "bell.circle.fill",
                    iconColor: .orange,
                    title: "Day 5",
                    subtitle: "Reminder sent",
                    isFirst: false,
                    isActive: false
                )

                // Day 7 - Billing Starts
                timelineStep(
                    icon: "creditcard.circle.fill",
                    iconColor: .modusTealAccent,
                    title: "Day 7",
                    subtitle: "Billing starts",
                    isFirst: false,
                    isActive: false
                )
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(colorScheme == .dark
                        ? Color(.secondarySystemBackground)
                        : Color(.systemBackground))
                    .shadow(color: Shadow.subtle.color(for: colorScheme), radius: Shadow.subtle.radius, x: 0, y: Shadow.subtle.y)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(Color.modusCyan.opacity(0.2), lineWidth: 1)
            )
        }
        .opacity(animateTimeline ? 1 : 0)
        .scaleEffect(animateTimeline ? 1.0 : 0.95)
    }

    // MARK: - Timeline Step

    private func timelineStep(icon: String, iconColor: Color, title: String, subtitle: String, isFirst: Bool, isActive: Bool) -> some View {
        VStack(spacing: Spacing.xs) {
            // Icon
            ZStack {
                if isActive {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                }

                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)
            }
            .frame(width: 44, height: 44)

            // Text
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(isActive ? .primary : .secondary)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Cancel Anytime Badge

    private var cancelAnytimeBadge: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "shield.checkered")
                .font(.subheadline)
                .foregroundStyle(Color.modusTealAccent)

            Text("Cancel anytime before trial ends — no charge")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.modusTealAccent.opacity(colorScheme == .dark ? 0.12 : 0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.modusTealAccent.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Benefits List

    private var benefitsList: some View {
        VStack(spacing: Spacing.sm) {
            Text("What you'll get")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(Array(variant.features.enumerated()), id: \.element.id) { index, feature in
                HStack(spacing: Spacing.sm) {
                    Image(systemName: feature.icon)
                        .font(.body)
                        .foregroundStyle(Color.modusCyan)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.modusCyan.opacity(0.1))
                        )

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(feature.title)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        if let subtitle = feature.subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()
                }
                .opacity(animateBenefits ? 1 : 0)
                .offset(x: animateBenefits ? 0 : -15)
                .animation(
                    .spring(response: 0.4, dampingFraction: 0.8)
                        .delay(Double(index) * 0.06),
                    value: animateBenefits
                )
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(colorScheme == .dark
                    ? Color(.secondarySystemBackground)
                    : Color(.systemBackground))
                .shadow(color: Shadow.subtle.color(for: colorScheme), radius: Shadow.subtle.radius, x: 0, y: Shadow.subtle.y)
        )
    }

    // MARK: - CTA Section

    private var ctaSection: some View {
        VStack(spacing: Spacing.sm) {
            Button {
                onStartTrial()
            } label: {
                HStack(spacing: Spacing.xs) {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "gift")
                            .font(.headline)
                    }
                    Text(variant.ctaText.isEmpty ? "Start Free Trial" : variant.ctaText)
                        .fontWeight(.bold)
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
                .background(
                    LinearGradient(
                        colors: [.modusCyan, .modusTealAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                .shadow(
                    color: Color.modusCyan.opacity(pulseButton ? 0.4 : 0.2),
                    radius: pulseButton ? 12 : 6,
                    x: 0,
                    y: pulseButton ? 6 : 3
                )
            }
            .disabled(isPurchasing)
            .scaleEffect(isPurchasing ? 0.98 : 1.0)
            .animation(.easeInOut(duration: AnimationDuration.quick), value: isPurchasing)

            // Pricing info below button
            if let annualProduct = storeKit.annualProduct {
                Text("After trial: \(annualProduct.displayPrice)/year")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Small Print

    private var smallPrint: some View {
        VStack(spacing: Spacing.xxs) {
            Text("Your subscription will begin after the 7-day trial period.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            Text("You can cancel anytime in Settings > Subscriptions.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Spacing.sm)
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: Spacing.xs) {
            Button("Restore Purchases") {
                onRestorePurchases()
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            HStack(spacing: Spacing.md) {
                Link("Terms of Service", destination: URL(string: "https://getmodus.app/terms")!)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Text("|")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)

                Link("Privacy Policy", destination: URL(string: "https://getmodus.app/privacy")!)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, Spacing.xxs)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct TrialPaywallLayout_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            TrialPaywallLayout(
                variant: .onboardingDefault,
                isPurchasing: false,
                onStartTrial: {},
                onRestorePurchases: {}
            )
        }
        .environmentObject(StoreKitService.shared)
    }
}
#endif
