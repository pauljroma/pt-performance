//
//  StandardPaywallLayout.swift
//  PTPerformance
//
//  ACP-991: Default paywall layout with hero area, feature checklist,
//  pricing cards (monthly/annual toggle), savings badge, and CTA.
//

import SwiftUI
import StoreKit

// MARK: - Standard Paywall Layout

struct StandardPaywallLayout: View {
    let variant: PaywallVariant
    @Binding var selectedPlan: PricingPlan
    let isPurchasing: Bool
    let onPurchase: () -> Void
    let onRestorePurchases: () -> Void

    @EnvironmentObject private var storeKit: StoreKitService
    @Environment(\.colorScheme) private var colorScheme

    @State private var animateHero: Bool = false
    @State private var animateFeatures: Bool = false
    @State private var animatePricing: Bool = false

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // MARK: - Hero Area
            heroSection

            // MARK: - Title + Subtitle
            titleSection

            // MARK: - Feature Checklist
            featureList

            // MARK: - Pricing Cards
            pricingSection

            // MARK: - CTA Button
            ctaButton

            // MARK: - Restore + Terms
            footerSection
        }
        .padding(.horizontal, Spacing.lg)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                animateHero = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
                animateFeatures = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5)) {
                animatePricing = true
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        ZStack {
            // Decorative circles
            Circle()
                .fill(Color.modusCyan.opacity(0.1))
                .frame(width: 120, height: 120)
                .scaleEffect(animateHero ? 1.0 : 0.5)

            Circle()
                .fill(Color.modusCyan.opacity(0.05))
                .frame(width: 160, height: 160)
                .scaleEffect(animateHero ? 1.0 : 0.3)

            Image(systemName: "star.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.modusCyan, .modusTealAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(animateHero ? 1.0 : 0.6)
                .rotationEffect(.degrees(animateHero ? 0 : -15))
        }
        .frame(height: 160)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: Spacing.xs) {
            Text(variant.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(variant.subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
    }

    // MARK: - Feature List

    private var featureList: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(Array(variant.features.enumerated()), id: \.element.id) { index, feature in
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.modusTealAccent)
                        .font(.body)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(feature.title)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        if let subtitle = feature.subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }

                    Spacer()
                }
                .opacity(animateFeatures ? 1 : 0)
                .offset(x: animateFeatures ? 0 : -20)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.8)
                        .delay(Double(index) * 0.05),
                    value: animateFeatures
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

    // MARK: - Pricing Section

    private var pricingSection: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                // Monthly Card
                pricingCard(
                    plan: .monthly,
                    title: "Monthly",
                    price: storeKit.monthlyProduct?.displayPrice ?? "$9.99",
                    period: "/month",
                    badge: nil
                )

                // Annual Card
                pricingCard(
                    plan: .annual,
                    title: "Annual",
                    price: storeKit.annualProduct?.displayPrice ?? "$59.99",
                    period: "/year",
                    badge: "Save 50%"
                )
            }

            // Savings callout
            if selectedPlan == .annual {
                savingsBadge
            }
        }
        .opacity(animatePricing ? 1 : 0)
        .offset(y: animatePricing ? 0 : 20)
    }

    // MARK: - Pricing Card

    private func pricingCard(plan: PricingPlan, title: String, price: String, period: String, badge: String?) -> some View {
        let isSelected = selectedPlan == plan

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedPlan = plan
            }
            HapticFeedback.selectionChanged()
        } label: {
            VStack(spacing: Spacing.xs) {
                // Badge
                if let badge = badge {
                    Text(badge)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, Spacing.xxs)
                        .background(
                            Capsule()
                                .fill(Color.modusTealAccent)
                        )
                }

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? Color.modusCyan : .secondary)

                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(price)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(isSelected ? .primary : .secondary)

                    Text(period)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if plan == .annual {
                    Text(monthlyEquivalent)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(isSelected
                        ? (colorScheme == .dark
                            ? Color.modusCyan.opacity(0.12)
                            : Color.modusCyan.opacity(0.06))
                        : (colorScheme == .dark
                            ? Color(.secondarySystemBackground)
                            : Color(.systemBackground)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(
                        isSelected ? Color.modusCyan : Color(.separator).opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Savings Badge

    private var savingsBadge: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: "tag.fill")
                .font(.caption)
                .foregroundStyle(Color.modusTealAccent)

            Text("Save over 50% compared to monthly billing")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(Color.modusTealAccent.opacity(0.1))
        )
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }

    // MARK: - CTA Button

    private var ctaButton: some View {
        Button {
            onPurchase()
        } label: {
            HStack(spacing: Spacing.xs) {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                }
                Text(variant.ctaText)
                    .fontWeight(.bold)
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md + 2)
            .background(
                LinearGradient(
                    colors: [variant.ctaColor, variant.ctaColor.opacity(0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .shadow(
                color: variant.ctaColor.opacity(0.3),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .disabled(isPurchasing)
        .scaleEffect(isPurchasing ? 0.98 : 1.0)
        .animation(.easeInOut(duration: AnimationDuration.quick), value: isPurchasing)
        .padding(.top, Spacing.xs)
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: Spacing.xs) {
            if variant.showTrial {
                Text("7-day free trial, then \(selectedPlanPriceText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

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

    // MARK: - Helpers

    private var monthlyEquivalent: String {
        if let annual = storeKit.annualProduct {
            let monthlyPrice = annual.price / 12
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = Locale.current
            return "(\(formatter.string(from: monthlyPrice as NSDecimalNumber) ?? "$5.00")/mo)"
        }
        return "($5.00/mo)"
    }

    private var selectedPlanPriceText: String {
        switch selectedPlan {
        case .monthly:
            return storeKit.monthlyProduct?.displayPrice ?? "$9.99" + "/month"
        case .annual:
            return storeKit.annualProduct?.displayPrice ?? "$59.99" + "/year"
        }
    }
}

// MARK: - Preview

#if DEBUG
struct StandardPaywallLayout_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            StandardPaywallLayout(
                variant: .featureGateDefault,
                selectedPlan: .constant(.annual),
                isPurchasing: false,
                onPurchase: {},
                onRestorePurchases: {}
            )
            .padding()
        }
        .environmentObject(StoreKitService.shared)
    }
}
#endif
