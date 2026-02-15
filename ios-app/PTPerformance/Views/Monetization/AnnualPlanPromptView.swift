//
//  AnnualPlanPromptView.swift
//  PTPerformance
//
//  ACP-1010: Annual Plan Optimization — Annual vs monthly conversion prompt.
//  Appears to monthly subscribers after 2+ months, especially after positive
//  moments like workout PRs or streak milestones. Shows the savings clearly
//  with a visual comparison.
//

import SwiftUI
import StoreKit

// MARK: - Annual Plan Prompt View

struct AnnualPlanPromptView: View {
    @EnvironmentObject var storeKit: StoreKitService
    @ObservedObject var coordinator = MonetizationCoordinator.shared
    @Environment(\.dismiss) private var dismiss

    @State private var isPurchasing: Bool = false
    @State private var errorMessage: String?
    @State private var animateIn: Bool = false

    /// The current tier of the user (Pro or Elite) determines pricing.
    private var currentTier: SubscriptionTier {
        storeKit.currentTier
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {

                    // MARK: - Header
                    headerSection

                    // MARK: - Savings Visual
                    savingsComparisonCard

                    // MARK: - Months Free Callout
                    monthsFreeCallout

                    // MARK: - Benefits List
                    benefitsSection

                    // MARK: - CTA
                    switchPlanButton

                    // MARK: - Error
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(DesignTokens.statusError)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.lg)
                    }

                    // MARK: - Dismiss
                    Button {
                        coordinator.dismissActivePrompt()
                        dismiss()
                    } label: {
                        Text("I will stick with monthly for now")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, Spacing.md)

                    // MARK: - Legal
                    Text("Switching to annual billing takes effect at your next renewal date. You will not be double-charged. Your subscription features remain the same.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.bottom, Spacing.lg)
                }
                .padding(.top, Spacing.md)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.green.opacity(0.03),
                        Color(.systemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        coordinator.dismissActivePrompt()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Close annual plan prompt")
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

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .modusCyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(animateIn ? 1.0 : 0.7)
                .animation(.spring(response: 0.5, dampingFraction: 0.65), value: animateIn)

            Text("Save \(savingsPercentDisplay) with Annual")
                .font(.title)
                .fontWeight(.bold)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 15)
                .animation(.easeOut(duration: 0.5).delay(0.15), value: animateIn)

            Text("You have been loving \(currentTier.displayName) for months. Lock in a better rate.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)
                .opacity(animateIn ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.25), value: animateIn)
        }
    }

    // MARK: - Savings Comparison

    private var savingsComparisonCard: some View {
        HStack(spacing: Spacing.md) {
            // Monthly column
            VStack(spacing: Spacing.xs) {
                Text("Monthly")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Text(monthlyAnnualizedPrice)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .strikethrough(true, color: .red)

                Text("per year")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color(.secondarySystemGroupedBackground))
            )

            // VS
            Text("vs")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)

            // Annual column
            VStack(spacing: Spacing.xs) {
                Text("Annual")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignTokens.statusSuccess)

                Text(annualPrice)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DesignTokens.statusSuccess, .modusCyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("per year")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(DesignTokens.statusSuccess.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .strokeBorder(DesignTokens.statusSuccess.opacity(0.3), lineWidth: 1.5)
                    )
            )
        }
        .padding(.horizontal, Spacing.md)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.3), value: animateIn)
    }

    // MARK: - Months Free Callout

    private var monthsFreeCallout: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "gift.fill")
                .foregroundColor(DesignTokens.statusSuccess)

            Text("That is like getting \(monthsFree) months free!")
                .font(.headline)
                .foregroundColor(DesignTokens.statusSuccess)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(DesignTokens.statusSuccess.opacity(0.08))
        )
        .padding(.horizontal, Spacing.md)
        .scaleEffect(animateIn ? 1.0 : 0.9)
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: animateIn)
    }

    // MARK: - Benefits Section

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Why switch to annual?")
                .font(.headline)
                .padding(.horizontal, Spacing.md)

            VStack(spacing: Spacing.xs) {
                AnnualBenefitRow(icon: "dollarsign.circle.fill", color: .green, text: "Save \(savingsAmount) every year")
                AnnualBenefitRow(icon: "lock.fill", color: .modusCyan, text: "Lock in today's price")
                AnnualBenefitRow(icon: "arrow.clockwise.circle.fill", color: .blue, text: "No monthly renewals to think about")
                AnnualBenefitRow(icon: "heart.fill", color: .pink, text: "Support continued app development")
            }
            .padding(.horizontal, Spacing.md)
        }
    }

    // MARK: - Switch Plan Button

    private var switchPlanButton: some View {
        Button {
            Task {
                await switchToAnnual()
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Switch to Annual Plan")
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                LinearGradient(
                    colors: [.green, .modusCyan],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(CornerRadius.lg)
        }
        .disabled(isPurchasing)
        .padding(.horizontal, Spacing.md)
        .accessibilityLabel("Switch to annual plan and save \(savingsPercentDisplay)")
    }

    // MARK: - Computed Properties

    private var savingsPercentDisplay: String {
        currentTier == .elite ? "33%" : "50%"
    }

    private var monthlyAnnualizedPrice: String {
        switch currentTier {
        case .elite:
            return "$299.88" // $24.99 x 12
        case .pro:
            return "$119.88" // $9.99 x 12
        default:
            return "$119.88"
        }
    }

    private var annualPrice: String {
        switch currentTier {
        case .elite:
            return "$199.99"
        case .pro:
            return "$59.99"
        default:
            return "$59.99"
        }
    }

    private var savingsAmount: String {
        switch currentTier {
        case .elite:
            return "$99.89"
        case .pro:
            return "$59.89"
        default:
            return "$59.89"
        }
    }

    private var monthsFree: String {
        switch currentTier {
        case .elite:
            return "4"  // ~33% off = ~4 months
        case .pro:
            return "6"  // ~50% off = ~6 months
        default:
            return "6"
        }
    }

    // MARK: - Purchase Logic

    private func switchToAnnual() async {
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }

        HapticFeedback.medium()

        let productId: String
        switch currentTier {
        case .elite:
            productId = SubscriptionTier.elite.annualProductId ?? "com.getmodus.app.elite.annual"
        case .pro:
            productId = Config.Subscription.annualProductID
        default:
            productId = Config.Subscription.annualProductID
        }

        guard let product = storeKit.products.first(where: { $0.id == productId }) else {
            errorMessage = "Annual plan not available. Please try again later."
            HapticFeedback.error()
            return
        }

        do {
            try await storeKit.purchase(product)

            // Check if the purchase was successful by seeing if annual product is now in purchased set.
            if storeKit.purchasedProductIDs.contains(productId) {
                HapticFeedback.success()
                coordinator.dismissActivePrompt()
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            HapticFeedback.error()
        }
    }
}

// MARK: - Annual Benefit Row

private struct AnnualBenefitRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 28, height: 28)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.vertical, Spacing.xxs)
    }
}

// MARK: - Preview

#if DEBUG
struct AnnualPlanPromptView_Previews: PreviewProvider {
    static var previews: some View {
        AnnualPlanPromptView()
            .environmentObject(StoreKitService.shared)
    }
}
#endif
