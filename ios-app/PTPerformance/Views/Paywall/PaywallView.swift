//
//  PaywallView.swift
//  PTPerformance
//
//  ACP-991: Main paywall container that dispatches to the appropriate layout
//  based on the current PaywallVariant. Presented as a sheet with animated entrance.
//

import SwiftUI
import StoreKit

// MARK: - Paywall View

/// Main paywall container that renders the appropriate layout based on the variant configuration.
///
/// ## Presentation
/// Present as a sheet from any view that observes `PaywallService.shared.shouldShowPaywall`.
///
/// ## Layout Dispatch
/// Routes to the correct layout view based on `variant.layout`:
/// - `.standard` -> `StandardPaywallLayout`
/// - `.comparison` -> `ComparisonPaywallLayout`
/// - `.trial` -> `TrialPaywallLayout`
/// - `.minimal` -> Inline minimal layout
struct PaywallView: View {
    @EnvironmentObject private var storeKit: StoreKitService
    @StateObject private var paywallService = PaywallService.shared
    @StateObject private var freeTrialService = FreeTrialService.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let variant: PaywallVariant

    // MARK: - State

    @State private var selectedPlan: PricingPlan = .annual
    @State private var isPurchasing: Bool = false
    @State private var purchaseError: String?
    @State private var showError: Bool = false
    @State private var animateContent: Bool = false

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Background
            backgroundGradient

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Layout dispatch
                    switch variant.layout {
                    case .standard:
                        StandardPaywallLayout(
                            variant: variant,
                            selectedPlan: $selectedPlan,
                            isPurchasing: isPurchasing,
                            onPurchase: handlePurchase,
                            onRestorePurchases: handleRestore
                        )

                    case .comparison:
                        ComparisonPaywallLayout(
                            variant: variant,
                            isPurchasing: isPurchasing,
                            onSelectTier: handleTierSelection,
                            onRestorePurchases: handleRestore
                        )

                    case .trial:
                        TrialPaywallLayout(
                            variant: variant,
                            isPurchasing: isPurchasing,
                            onStartTrial: handleStartTrial,
                            onRestorePurchases: handleRestore
                        )

                    case .minimal:
                        minimalLayout
                    }
                }
                .padding(.top, Spacing.xxl)
                .padding(.bottom, Spacing.xl)
            }

            // Close button
            closeButton
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 30)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                animateContent = true
            }
        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(purchaseError ?? "An unknown error occurred. Please try again.")
        }
        .onDisappear {
            paywallService.recordDismissal()
        }
        .interactiveDismissDisabled(isPurchasing)
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(.systemBackground), Color(red: 0.03, green: 0.15, blue: 0.18)]
                : [Color(.systemBackground), Color.modusLightTeal],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Close Button

    private var closeButton: some View {
        Button {
            HapticFeedback.light()
            paywallService.recordDismissal()
            paywallService.dismissPaywall()
            dismiss()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
                .padding(Spacing.md)
        }
        .accessibilityLabel("Close paywall")
        .disabled(isPurchasing)
    }

    // MARK: - Minimal Layout

    private var minimalLayout: some View {
        VStack(spacing: Spacing.lg) {
            // Icon
            Image(systemName: "lock.open.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.modusCyan)
                .padding(.top, Spacing.xl)

            // Title
            Text(variant.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)

            // Subtitle
            Text(variant.subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)

            // Quick feature list (top 3)
            VStack(spacing: Spacing.sm) {
                ForEach(Array(variant.features.prefix(3))) { feature in
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.modusTealAccent)
                            .font(.body)
                        Text(feature.title)
                            .font(.subheadline)
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)

            // Pricing
            if let annualProduct = storeKit.annualProduct {
                Text(annualProduct.displayPrice + "/year")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.modusCyan)
            }

            // CTA
            Button {
                handlePurchase()
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
                .padding(.vertical, Spacing.md)
                .background(variant.ctaColor)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            }
            .disabled(isPurchasing)
            .padding(.horizontal, Spacing.lg)

            // Restore + Terms
            footerLinks
        }
    }

    // MARK: - Footer Links

    private var footerLinks: some View {
        VStack(spacing: Spacing.xs) {
            Button("Restore Purchases") {
                handleRestore()
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
        }
        .padding(.top, Spacing.sm)
    }

    // MARK: - Purchase Actions

    private func handlePurchase() {
        Task {
            isPurchasing = true
            HapticFeedback.medium()

            do {
                let product: Product?
                switch selectedPlan {
                case .monthly:
                    product = storeKit.monthlyProduct
                case .annual:
                    product = storeKit.annualProduct
                }

                guard let selectedProduct = product else {
                    purchaseError = "Product not available. Please try again later."
                    showError = true
                    isPurchasing = false
                    return
                }

                try await storeKit.purchase(selectedProduct)

                if storeKit.isPremium {
                    HapticFeedback.success()
                    paywallService.recordConversion()
                    freeTrialService.cancelTrialNotifications()
                    dismiss()
                }
            } catch {
                HapticFeedback.error()
                purchaseError = error.localizedDescription
                showError = true
            }

            isPurchasing = false
        }
    }

    private func handleStartTrial() {
        Task {
            isPurchasing = true
            HapticFeedback.medium()

            // Start the trial via FreeTrialService
            await freeTrialService.startTrial()

            // Also attempt to purchase the annual plan with trial offer
            if let annualProduct = storeKit.annualProduct {
                do {
                    try await storeKit.purchase(annualProduct)
                    if storeKit.isPremium {
                        HapticFeedback.success()
                        paywallService.recordConversion()
                        dismiss()
                    }
                } catch {
                    // Trial still started locally even if StoreKit purchase fails
                    HapticFeedback.warning()
                    DebugLogger.shared.warning("Paywall", "Trial purchase failed: \(error.localizedDescription)")
                }
            } else {
                // No product available — trial started locally
                HapticFeedback.success()
                paywallService.recordConversion()
                dismiss()
            }

            isPurchasing = false
        }
    }

    private func handleTierSelection(_ tier: String) {
        switch tier.lowercased() {
        case "pro":
            selectedPlan = .monthly
            handlePurchase()
        case "elite":
            selectedPlan = .annual
            handlePurchase()
        default:
            // "Free" tier selected — dismiss
            paywallService.recordDismissal()
            dismiss()
        }
    }

    private func handleRestore() {
        Task {
            isPurchasing = true
            HapticFeedback.medium()

            await storeKit.restorePurchases()

            if storeKit.isPremium {
                HapticFeedback.success()
                paywallService.recordConversion()
                dismiss()
            } else {
                HapticFeedback.warning()
                purchaseError = "No active subscriptions found. If you believe this is an error, please contact support."
                showError = true
            }

            isPurchasing = false
        }
    }
}

// MARK: - Pricing Plan

enum PricingPlan: String, CaseIterable {
    case monthly
    case annual
}

// MARK: - Preview

#if DEBUG
struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PaywallView(variant: .featureGateDefault)
            .environmentObject(StoreKitService.shared)
    }
}
#endif
