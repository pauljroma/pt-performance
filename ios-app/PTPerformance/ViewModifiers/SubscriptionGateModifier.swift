//
//  SubscriptionGateModifier.swift
//  PTPerformance
//
//  ACP-986: Subscription Tier Architecture
//  ACP-987: StoreKit 2 Integration
//
//  View modifier that gates content behind a subscription tier.
//  Shows a blurred/locked overlay with upgrade prompt when the user
//  does not have access to the required feature.
//

import SwiftUI

// MARK: - Subscription Gate Modifier

/// A view modifier that gates content behind a subscription feature.
///
/// When the user's current tier grants access to the specified feature, the
/// content is displayed normally. When access is denied, the content is blurred
/// and overlaid with a lock icon and upgrade prompt. Tapping the overlay
/// presents the subscription paywall.
///
/// ## Usage
/// ```swift
/// AdvancedAnalyticsView()
///     .subscriptionGated(.advancedAnalytics)
///
/// // With custom message
/// AICoachView()
///     .subscriptionGated(.aiCoaching, message: "Unlock AI coaching for personalized recommendations")
/// ```
struct SubscriptionGateModifier: ViewModifier {

    // MARK: - Properties

    /// The feature required to view the content
    let requiredFeature: SubscriptionTier.Feature

    /// Optional custom message for the upgrade prompt
    let message: String?

    /// Whether to blur the content when gated (vs fully hiding it)
    let showBlurredPreview: Bool

    // MARK: - Environment

    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var storeKit: StoreKitService

    // MARK: - State

    @State private var showPaywall = false

    // MARK: - Body

    func body(content: Content) -> some View {
        let hasAccess = subscriptionManager.canAccess(requiredFeature)

        ZStack {
            content
                .blur(radius: hasAccess ? 0 : (showBlurredPreview ? 10 : 0))
                .opacity(hasAccess ? 1 : (showBlurredPreview ? 0.6 : 0))
                .disabled(!hasAccess)
                .allowsHitTesting(hasAccess)

            if !hasAccess {
                gatedOverlay
            }
        }
        .sheet(isPresented: $showPaywall) {
            SubscriptionView()
                .environmentObject(storeKit)
        }
        .accessibilityElement(children: hasAccess ? .contain : .combine)
        .accessibilityLabel(hasAccess ? "" : "\(requiredFeature.displayName) requires \(subscriptionManager.minimumTier(for: requiredFeature).displayName) subscription")
        .accessibilityHint(hasAccess ? "" : "Double tap to view upgrade options")
    }

    // MARK: - Gated Overlay

    private var gatedOverlay: some View {
        VStack(spacing: Spacing.md) {
            // Lock Icon
            ZStack {
                Circle()
                    .fill(Color.modusCyan.opacity(0.15))
                    .frame(width: 72, height: 72)

                Image(systemName: "lock.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.modusCyan)
            }
            .accessibilityHidden(true)

            // Feature Name
            Text(requiredFeature.displayName)
                .font(.title3)
                .fontWeight(.bold)

            // Message
            Text(message ?? defaultMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)

            // Required Tier Badge
            let minTier = subscriptionManager.minimumTier(for: requiredFeature)
            HStack(spacing: Spacing.xxs) {
                Image(systemName: minTier.icon)
                    .font(.caption)
                Text("\(minTier.displayName) feature")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(
                Capsule().fill(
                    LinearGradient(
                        colors: tierColors(for: minTier),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            )

            // Upgrade Button
            Button {
                HapticFeedback.medium()
                DebugLogger.shared.info("SubscriptionGate", "Upgrade tapped for feature: \(requiredFeature.rawValue)")
                showPaywall = true
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "star.fill")
                    Text("Upgrade Now")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: 240)
                .padding(.vertical, Spacing.sm)
                .background(
                    LinearGradient(
                        colors: [.modusCyan, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .cornerRadius(CornerRadius.md)
            }
            .padding(.top, Spacing.xs)
            .accessibilityLabel("Upgrade to unlock \(requiredFeature.displayName)")
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            DesignTokens.backgroundPrimary.opacity(showBlurredPreview ? 0.5 : 0.95)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            HapticFeedback.light()
            showPaywall = true
        }
    }

    // MARK: - Helpers

    private var defaultMessage: String {
        requiredFeature.featureDescription
    }

    private func tierColors(for tier: SubscriptionTier) -> [Color] {
        switch tier {
        case .free: return [.gray, .gray.opacity(0.7)]
        case .pro: return [.modusCyan, .purple]
        case .elite: return [.purple, .orange]
        }
    }
}

// MARK: - View Extension

extension View {

    /// Gates this view behind a subscription feature.
    ///
    /// When the user has access to the feature, the view is displayed normally.
    /// When the user does not have access, the view is blurred and overlaid with
    /// a lock icon and upgrade prompt. Tapping the overlay presents the paywall.
    ///
    /// - Parameters:
    ///   - feature: The subscription feature required to view this content
    ///   - message: Optional custom message for the upgrade prompt
    ///   - showBlurredPreview: Whether to show blurred content preview (default: true).
    ///     When false, the content is fully hidden behind the overlay.
    /// - Returns: A view that is gated by the subscription feature
    ///
    /// ## Example
    /// ```swift
    /// AdvancedAnalyticsView()
    ///     .subscriptionGated(.advancedAnalytics)
    ///
    /// AICoachView()
    ///     .subscriptionGated(.aiCoaching, message: "Get personalized AI coaching")
    /// ```
    func subscriptionGated(
        _ feature: SubscriptionTier.Feature,
        message: String? = nil,
        showBlurredPreview: Bool = true
    ) -> some View {
        modifier(
            SubscriptionGateModifier(
                requiredFeature: feature,
                message: message,
                showBlurredPreview: showBlurredPreview
            )
        )
    }
}

// MARK: - Preview

#Preview("Gated - No Access") {
    VStack {
        Text("Advanced Analytics Content")
            .font(.largeTitle)
            .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .subscriptionGated(.advancedAnalytics)
    .environmentObject(SubscriptionManager.shared)
    .environmentObject(StoreKitService.shared)
}
