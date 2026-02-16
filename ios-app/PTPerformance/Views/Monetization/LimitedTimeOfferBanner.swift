//
//  LimitedTimeOfferBanner.swift
//  PTPerformance
//
//  ACP-1011: Limited Time Offers — Time-bound promotional offer banner
//  Urgency-driven banner with countdown timer and claim action.
//

import SwiftUI

// MARK: - Limited Time Offer Banner

/// A promotional banner displaying a limited-time offer with countdown timer.
///
/// Appears at the top of home/settings screens. Features:
/// - Gradient background for visual urgency
/// - Real-time countdown timer (HH:MM:SS)
/// - Discount percentage prominently displayed
/// - "Claim Offer" CTA button
/// - Dismiss X (re-appears next session)
///
/// ## Placement
/// Embed in a VStack at the top of your view:
/// ```swift
/// VStack {
///     LimitedTimeOfferBanner { productId in
///         // Present paywall for productId
///     }
///     // ... rest of content
/// }
/// ```
struct LimitedTimeOfferBanner: View {

    @StateObject private var service = LimitedTimeOfferService.shared

    /// Callback when the user taps "Claim Offer", receiving the product ID
    var onClaimOffer: ((String) -> Void)?

    var body: some View {
        if let offer = service.activeOffer, !service.isDismissedThisSession {
            bannerContent(offer: offer)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: service.isDismissedThisSession)
        }
    }

    // MARK: - Banner Content

    private func bannerContent(offer: LimitedTimeOffer) -> some View {
        VStack(spacing: Spacing.xs) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    // Offer title
                    Text(offer.title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    // Offer description
                    Text(offer.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                }

                Spacer()

                // Dismiss button
                Button {
                    HapticFeedback.light()
                    withAnimation {
                        service.dismissCurrentOffer()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: DesignTokens.iconSizeMedium, height: DesignTokens.iconSizeMedium)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss offer")
            }

            HStack(spacing: Spacing.md) {
                // Discount badge
                VStack(spacing: Spacing.xxs) {
                    Text(offer.formattedDiscount)
                        .font(.title3)
                        .fontWeight(.black)
                        .foregroundColor(.white)

                    if let subtitle = offer.subtitle {
                        Text(subtitle)
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                Spacer()

                // Countdown timer
                countdownDisplay

                Spacer()

                // Claim button
                Button {
                    HapticFeedback.medium()
                    if let productId = service.claimOffer() {
                        onClaimOffer?(productId)
                    }
                } label: {
                    Text("Claim Offer")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.modusCyan)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(Color.white)
                        .cornerRadius(CornerRadius.lg)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Claim limited time offer")
            }
        }
        .padding(Spacing.sm)
        .background(bannerGradient)
        .cornerRadius(CornerRadius.md)
        .shadow(color: Color.modusCyan.opacity(0.3), radius: 8, x: 0, y: 4)
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Countdown Display

    private var countdownDisplay: some View {
        HStack(spacing: Spacing.xxs) {
            countdownUnit(value: service.countdownHours, label: "HRS")
            Text(":")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.7))
            countdownUnit(value: service.countdownMinutes, label: "MIN")
            Text(":")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.7))
            countdownUnit(value: service.countdownSeconds, label: "SEC")
        }
    }

    private func countdownUnit(value: Int, label: String) -> some View {
        VStack(spacing: 0) {
            Text(String(format: "%02d", value))
                .font(.system(.subheadline, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 28)
                .padding(.vertical, Spacing.xxs)
                .background(Color.white.opacity(0.15))
                .cornerRadius(CornerRadius.xs)

            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, Spacing.xxs)
        }
    }

    // MARK: - Gradient Background

    private var bannerGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.modusCyan,
                Color.modusCyan.opacity(0.8),
                Color(red: 0.05, green: 0.45, blue: 0.55)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Compact Banner Variant

/// A more compact version of the LTO banner for embedding in settings or lists.
struct LimitedTimeOfferCompactBanner: View {

    @StateObject private var service = LimitedTimeOfferService.shared

    var onClaimOffer: ((String) -> Void)?

    var body: some View {
        if let offer = service.activeOffer, !service.isDismissedThisSession {
            HStack(spacing: Spacing.sm) {
                // Discount badge
                Text(offer.formattedDiscount)
                    .font(.caption)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, Spacing.xxs)
                    .background(Color.modusCyan)
                    .cornerRadius(CornerRadius.xs)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(offer.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    // Countdown inline
                    Text("Ends in \(formattedCountdown)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    HapticFeedback.medium()
                    if let productId = service.claimOffer() {
                        onClaimOffer?(productId)
                    }
                } label: {
                    Text("Claim")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color.modusCyan)
                        .cornerRadius(CornerRadius.sm)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Claim offer")
            }
            .padding(Spacing.sm)
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .strokeBorder(Color.modusCyan.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private var formattedCountdown: String {
        if service.countdownHours > 0 {
            return "\(service.countdownHours)h \(service.countdownMinutes)m"
        }
        return "\(service.countdownMinutes)m \(service.countdownSeconds)s"
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Full Banner") {
    VStack {
        LimitedTimeOfferBanner { productId in
            print("Claim: \(productId)")
        }
        Spacer()
    }
    .padding(.top)
}

#Preview("Compact Banner") {
    LimitedTimeOfferCompactBanner { productId in
        print("Claim: \(productId)")
    }
    .padding()
}
#endif
