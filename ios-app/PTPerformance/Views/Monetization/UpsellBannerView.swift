//
//  UpsellBannerView.swift
//  PTPerformance
//
//  ACP-1006: In-App Upsell Prompts — Compact contextual upgrade banner.
//  Slides in from top, displays a trigger-specific icon and message,
//  and provides a pill-style "Upgrade" CTA. Swipe to dismiss.
//

import SwiftUI

// MARK: - Upsell Banner View

struct UpsellBannerView: View {
    @ObservedObject var upsellService = UpsellService.shared
    @EnvironmentObject var storeKit: StoreKitService

    let prompt: UpsellPrompt
    var onUpgradeTapped: (() -> Void)?

    @State private var offset: CGFloat = -120
    @State private var dragOffset: CGFloat = 0
    @State private var isVisible: Bool = false

    var body: some View {
        if isVisible {
            bannerContent
                .offset(y: offset + dragOffset)
                .gesture(dismissGesture)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                        offset = 0
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Upgrade to \(prompt.targetTier.displayName). \(prompt.message)")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction(named: "Dismiss") {
                    dismissBanner()
                }
        }
    }

    // MARK: - Banner Content

    private var bannerContent: some View {
        HStack(spacing: Spacing.sm) {
            // Trigger icon
            iconView

            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(prompt.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(prompt.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: Spacing.xs)

            // Upgrade pill
            upgradePill
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(bannerBackground)
        .padding(.horizontal, Spacing.sm)
    }

    // MARK: - Icon

    private var iconView: some View {
        Image(systemName: prompt.trigger.icon)
            .font(.title3)
            .foregroundStyle(iconGradient)
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(iconBackgroundColor.opacity(0.12))
            )
    }

    private var iconGradient: LinearGradient {
        LinearGradient(
            colors: iconGradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var iconGradientColors: [Color] {
        switch prompt.trigger {
        case .featureLimitReached:
            return [.orange, .red]
        case .workoutMilestone:
            return [.modusCyan, .blue]
        case .aiUsageLimit:
            return [.purple, .pink]
        case .analyticsPreview:
            return [.modusCyan, .purple]
        case .exportAttempt:
            return [.purple, .modusCyan]
        }
    }

    private var iconBackgroundColor: Color {
        switch prompt.trigger {
        case .featureLimitReached: return .orange
        case .workoutMilestone: return .modusCyan
        case .aiUsageLimit: return .purple
        case .analyticsPreview: return .modusCyan
        case .exportAttempt: return .purple
        }
    }

    // MARK: - Upgrade Pill

    private var upgradePill: some View {
        Button {
            HapticFeedback.medium()
            upsellService.recordConversion()
            onUpgradeTapped?()
        } label: {
            Text("Upgrade")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs + 2)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.modusCyan, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
        }
        .accessibilityLabel("Upgrade to \(prompt.targetTier.displayName)")
    }

    // MARK: - Background

    private var bannerBackground: some View {
        RoundedRectangle(cornerRadius: CornerRadius.md)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .strokeBorder(Color.modusCyan.opacity(0.15), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    // MARK: - Dismiss Gesture

    private var dismissGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // Only allow upward swipe to dismiss
                if value.translation.height < 0 {
                    dragOffset = value.translation.height
                }
            }
            .onEnded { value in
                if value.translation.height < -50 {
                    dismissBanner()
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dragOffset = 0
                    }
                }
            }
    }

    private func dismissBanner() {
        withAnimation(.easeIn(duration: 0.25)) {
            offset = -120
            dragOffset = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isVisible = false
            upsellService.dismissUpsell()
        }
    }

    // MARK: - Lifecycle

    func onAppear() {
        isVisible = true
    }
}

// MARK: - Banner Modifier

/// View modifier to conveniently overlay an upsell banner at the top of any view.
struct UpsellBannerModifier: ViewModifier {
    @ObservedObject var upsellService = UpsellService.shared
    @EnvironmentObject var storeKit: StoreKitService
    var onUpgradeTapped: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let prompt = upsellService.activeUpsell {
                    UpsellBannerView(
                        prompt: prompt,
                        onUpgradeTapped: onUpgradeTapped
                    )
                    .environmentObject(storeKit)
                    .padding(.top, Spacing.xs)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(response: 0.5, dampingFraction: 0.75), value: upsellService.activeUpsell?.id)
                }
            }
    }
}

extension View {
    /// Overlays a contextual upsell banner at the top of this view.
    func upsellBanner(onUpgradeTapped: (() -> Void)? = nil) -> some View {
        modifier(UpsellBannerModifier(onUpgradeTapped: onUpgradeTapped))
    }
}

// MARK: - Preview

#if DEBUG
struct UpsellBannerView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack {
                UpsellBannerView(
                    prompt: UpsellPrompt(
                        trigger: .workoutMilestone,
                        title: "You are on Fire",
                        message: "Keep the momentum going with advanced analytics and AI coaching.",
                        feature: .advancedAnalytics,
                        targetTier: .pro
                    )
                )

                Spacer().frame(height: 20)

                UpsellBannerView(
                    prompt: UpsellPrompt(
                        trigger: .aiUsageLimit,
                        title: "Unlock AI Coaching",
                        message: "Get unlimited personalized AI coaching recommendations.",
                        feature: .aiCoaching,
                        targetTier: .pro
                    )
                )

                Spacer().frame(height: 20)

                UpsellBannerView(
                    prompt: UpsellPrompt(
                        trigger: .exportAttempt,
                        title: "Export Your Data",
                        message: "Elite members can export all training data in multiple formats.",
                        feature: .exportData,
                        targetTier: .elite
                    )
                )

                Spacer()
            }
            .padding(.top, 60)
        }
        .environmentObject(StoreKitService.shared)
    }
}
#endif
