//
//  UpgradePathView.swift
//  PTPerformance
//
//  ACP-1007: Pro -> Elite Upgrade Path — Smooth tier upgrade experience.
//  Displays a side-by-side comparison of Pro vs Elite features, prorated
//  pricing, and a compelling CTA to upgrade.
//

import SwiftUI
import StoreKit

// MARK: - Upgrade Path View

struct UpgradePathView: View {
    @EnvironmentObject var storeKit: StoreKitService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedBillingCycle: BillingCycle = .monthly
    @State private var isPurchasing: Bool = false
    @State private var errorMessage: String?
    @State private var animateIn: Bool = false

    enum BillingCycle: String, CaseIterable {
        case monthly = "Monthly"
        case annual = "Annual"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {

                    // MARK: - Current Plan Summary
                    currentPlanCard

                    // MARK: - Headline
                    VStack(spacing: Spacing.xs) {
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.purple)
                            Text("Unlock Elite")
                                .font(.title)
                                .fontWeight(.bold)
                        }

                        Text("Take your training to the next level")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 15)
                    .animation(.easeOut(duration: 0.5).delay(0.1), value: animateIn)

                    // MARK: - Feature Comparison
                    featureComparisonSection

                    // MARK: - Price Difference
                    priceDifferenceCard

                    // MARK: - Billing Cycle Selector
                    billingCycleSelector

                    // MARK: - CTA
                    upgradeButton

                    // MARK: - Error
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(DesignTokens.statusError)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.lg)
                    }

                    // MARK: - Testimonial
                    testimonialCard

                    // MARK: - Legal
                    Text("Upgrade takes effect immediately. You will be charged a prorated amount for the remainder of your current billing period. Your subscription will renew at the Elite rate.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.bottom, Spacing.lg)
                }
                .padding(.top, Spacing.md)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Close upgrade view")
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animateIn = true
            }
        }
        .task {
            if storeKit.products.isEmpty {
                await storeKit.loadProducts()
            }
        }
    }

    // MARK: - Current Plan Card

    private var currentPlanCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.modusCyan)
                        .font(.caption)
                    Text("Current Plan")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text("Pro")
                    .font(.title3)
                    .fontWeight(.bold)

                Text(currentPriceDisplay)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundColor(.modusCyan)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.systemBackground))
        )
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Feature Comparison

    private var featureComparisonSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("What you get with Elite")
                .font(.headline)
                .padding(.horizontal, Spacing.md)

            VStack(spacing: 0) {
                // Header row
                HStack {
                    Text("Feature")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Pro")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.modusCyan)
                        .frame(width: 50)

                    Text("Elite")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                        .frame(width: 50)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(Color(.tertiarySystemGroupedBackground))

                // Feature rows
                ForEach(comparisonFeatures, id: \.name) { feature in
                    FeatureComparisonRow(
                        name: feature.name,
                        icon: feature.icon,
                        proIncluded: feature.proIncluded,
                        eliteIncluded: feature.eliteIncluded,
                        isEliteExclusive: feature.isEliteExclusive
                    )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color(.systemBackground))
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            .padding(.horizontal, Spacing.md)
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.2), value: animateIn)
    }

    // MARK: - Price Difference Card

    private var priceDifferenceCard: some View {
        VStack(spacing: Spacing.xs) {
            Text("Just \(priceDifference) more")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.modusCyan, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text(prorationExplanation)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.purple.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .strokeBorder(Color.purple.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Billing Cycle Selector

    private var billingCycleSelector: some View {
        HStack(spacing: 0) {
            ForEach(BillingCycle.allCases, id: \.self) { cycle in
                Button {
                    HapticFeedback.selectionChanged()
                    withAnimation(.easeInOut(duration: AnimationDuration.quick)) {
                        selectedBillingCycle = cycle
                    }
                } label: {
                    VStack(spacing: Spacing.xxs) {
                        Text(cycle.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedBillingCycle == cycle ? .bold : .regular)

                        if cycle == .annual {
                            Text(SubscriptionTier.elite.annualSavingsDisplay ?? "Save 33%")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(DesignTokens.statusSuccess)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .fill(selectedBillingCycle == cycle ? Color.purple.opacity(0.1) : Color.clear)
                    )
                    .foregroundColor(selectedBillingCycle == cycle ? .purple : .secondary)
                }
            }
        }
        .padding(Spacing.xxs)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Upgrade Button

    private var upgradeButton: some View {
        Button {
            Task {
                await performUpgrade()
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "crown.fill")
                    Text("Upgrade to Elite")
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                LinearGradient(
                    colors: [.purple, .modusCyan],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(CornerRadius.lg)
        }
        .disabled(isPurchasing)
        .padding(.horizontal, Spacing.md)
        .accessibilityLabel("Upgrade to Elite subscription")
    }

    // MARK: - Testimonial

    private var testimonialCard: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                ForEach(0..<5) { _ in
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }

            Text("\"Elite changed everything for me. The custom programs and data export alone are worth it. My training has never been more dialed in.\"")
                .font(.subheadline)
                .italic()
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text("-- Alex M., Elite member since 2024")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.systemBackground))
        )
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Computed Properties

    private var currentPriceDisplay: String {
        if storeKit.purchasedProductIDs.contains(Config.Subscription.annualProductID) {
            return SubscriptionTier.pro.annualPriceDisplay
        }
        return SubscriptionTier.pro.monthlyPriceDisplay
    }

    private var priceDifference: String {
        switch selectedBillingCycle {
        case .monthly:
            return "$15.00/mo"
        case .annual:
            return "$140.00/yr"
        }
    }

    private var prorationExplanation: String {
        switch selectedBillingCycle {
        case .monthly:
            return "Your next charge will be prorated based on your current billing cycle. After that, Elite renews at $24.99/mo."
        case .annual:
            return "Annual billing saves you 33% compared to monthly. Your next charge will be prorated. After that, Elite renews at $199.99/yr."
        }
    }

    private var comparisonFeatures: [ComparisonFeature] {
        [
            ComparisonFeature(name: "Unlimited Workouts", icon: "infinity", proIncluded: true, eliteIncluded: true, isEliteExclusive: false),
            ComparisonFeature(name: "Advanced Analytics", icon: "chart.bar.fill", proIncluded: true, eliteIncluded: true, isEliteExclusive: false),
            ComparisonFeature(name: "AI Coaching", icon: "brain.head.profile", proIncluded: true, eliteIncluded: true, isEliteExclusive: false),
            ComparisonFeature(name: "Nutrition Tracking", icon: "fork.knife", proIncluded: true, eliteIncluded: true, isEliteExclusive: false),
            ComparisonFeature(name: "Custom Programs", icon: "doc.badge.plus", proIncluded: false, eliteIncluded: true, isEliteExclusive: true),
            ComparisonFeature(name: "Telehealth", icon: "video.fill", proIncluded: false, eliteIncluded: true, isEliteExclusive: true),
            ComparisonFeature(name: "Priority Support", icon: "headphones", proIncluded: false, eliteIncluded: true, isEliteExclusive: true),
            ComparisonFeature(name: "Data Export", icon: "square.and.arrow.up.fill", proIncluded: false, eliteIncluded: true, isEliteExclusive: true),
            ComparisonFeature(name: "Wearable Integration", icon: "applewatch", proIncluded: false, eliteIncluded: true, isEliteExclusive: true)
        ]
    }

    // MARK: - Purchase Logic

    private func performUpgrade() async {
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }

        HapticFeedback.medium()

        let productId: String
        switch selectedBillingCycle {
        case .monthly:
            productId = SubscriptionTier.elite.monthlyProductId ?? "com.getmodus.app.elite.monthly"
        case .annual:
            productId = SubscriptionTier.elite.annualProductId ?? "com.getmodus.app.elite.annual"
        }

        guard let product = storeKit.products.first(where: { $0.id == productId }) else {
            errorMessage = "Elite product not available. Please try again later."
            HapticFeedback.error()
            return
        }

        do {
            try await storeKit.purchase(product)
            if storeKit.currentTier == .elite {
                HapticFeedback.success()
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            HapticFeedback.error()
        }
    }
}

// MARK: - Comparison Feature Model

private struct ComparisonFeature {
    let name: String
    let icon: String
    let proIncluded: Bool
    let eliteIncluded: Bool
    let isEliteExclusive: Bool
}

// MARK: - Feature Comparison Row

private struct FeatureComparisonRow: View {
    let name: String
    let icon: String
    let proIncluded: Bool
    let eliteIncluded: Bool
    let isEliteExclusive: Bool

    var body: some View {
        HStack {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(isEliteExclusive ? .purple : .modusCyan)
                    .frame(width: 20)

                Text(name)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                if isEliteExclusive {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                        .foregroundColor(.purple)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Pro column
            accessIndicator(included: proIncluded)
                .frame(width: 50)

            // Elite column
            accessIndicator(included: eliteIncluded)
                .frame(width: 50)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .background(
            isEliteExclusive
                ? Color.purple.opacity(0.03)
                : Color.clear
        )
    }

    @ViewBuilder
    private func accessIndicator(included: Bool) -> some View {
        if included {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(DesignTokens.statusSuccess)
        } else {
            Image(systemName: "minus.circle")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.4))
        }
    }
}

// MARK: - Preview

#if DEBUG
struct UpgradePathView_Previews: PreviewProvider {
    static var previews: some View {
        UpgradePathView()
            .environmentObject(StoreKitService.shared)
    }
}
#endif
