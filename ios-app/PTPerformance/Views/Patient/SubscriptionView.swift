import SwiftUI
import StoreKit

// MARK: - Subscription Paywall View

struct SubscriptionView: View {
    @EnvironmentObject var storeKit: StoreKitService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProduct: Product?
    @State private var isPurchasing: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // MARK: - Header
                    VStack(spacing: 12) {
                        Image(systemName: storeKit.isPremium ? "checkmark.seal.fill" : "star.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: storeKit.isPremium ? [.green, .modusCyan] : [.modusCyan, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(.top, Spacing.md)

                        Text(storeKit.isPremium ? "Premium Active" : "Unlock Premium")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text(storeKit.isPremium
                            ? "You have access to all premium features"
                            : "Get the most out of your training with premium features")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // MARK: - Current Plan Status
                    if storeKit.isPremium {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                                Text("Current Plan")
                                    .font(.headline)
                            }

                            Text(currentPlanDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            if storeKit.subscriptionStatus == .gracePeriod {
                                Text("Billing issue - please update payment method")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                        .padding(.horizontal)
                    }

                    // MARK: - Feature List
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(
                            icon: "clock.arrow.circlepath",
                            title: "Workout History",
                            description: "Track all your sessions and progress over time"
                        )
                        FeatureRow(
                            icon: "chart.bar.fill",
                            title: "Analytics",
                            description: "Detailed performance insights and trends"
                        )
                        FeatureRow(
                            icon: "brain.head.profile",
                            title: "AI Coach",
                            description: "Personalized exercise recommendations and coaching"
                        )
                        FeatureRow(
                            icon: "fork.knife",
                            title: "Nutrition",
                            description: "Meal plans, food tracking, and nutrition guidance"
                        )
                        FeatureRow(
                            icon: "battery.100",
                            title: "Readiness",
                            description: "Daily readiness check-ins and recovery scoring"
                        )
                        FeatureRow(
                            icon: "book.fill",
                            title: "Learn",
                            description: "Educational content and exercise technique guides"
                        )
                    }
                    .padding(.horizontal)

                    // MARK: - Pricing Cards (only show when not subscribed)
                    if !storeKit.isPremium {
                        if !storeKit.products.isEmpty {
                            VStack(spacing: 12) {
                                if let annual = storeKit.annualProduct {
                                    PricingCard(
                                        product: annual,
                                        name: "Annual",
                                        badge: "Best Value",
                                        subtitle: "7-day free trial",
                                        isSelected: selectedProduct?.id == annual.id
                                    )
                                    .onTapGesture {
                                        selectedProduct = annual
                                    }
                                }

                                if let monthly = storeKit.monthlyProduct {
                                    PricingCard(
                                        product: monthly,
                                        name: "Monthly",
                                        badge: nil,
                                        subtitle: nil,
                                        isSelected: selectedProduct?.id == monthly.id
                                    )
                                    .onTapGesture {
                                        selectedProduct = monthly
                                    }
                                }
                            }
                            .padding(.horizontal)
                        } else if storeKit.isLoading {
                            ProgressView("Loading plans...")
                                .padding()
                        } else {
                            // Products failed to load — show retry
                            VStack(spacing: Spacing.sm) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                                Text("Unable to load subscription plans")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Button("Try Again") {
                                    Task { await storeKit.loadProducts() }
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.modusCyan)
                            }
                            .padding()
                            .accessibilityElement(children: .combine)
                        }

                        // MARK: - Purchase Button
                        if let product = selectedProduct {
                            Button {
                                Task {
                                    await purchaseSelected()
                                }
                            } label: {
                                HStack {
                                    if isPurchasing {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text(purchaseButtonTitle(for: product))
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.modusCyan, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(CornerRadius.md)
                            }
                            .disabled(isPurchasing)
                            .padding(.horizontal)
                            .accessibilityLabel("Subscribe to \(product.displayName)")
                        }
                    }

                    // MARK: - Error Message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // MARK: - Restore Purchases
                    Button {
                        HapticFeedback.light()
                        Task {
                            await storeKit.restorePurchases()
                        }
                    } label: {
                        Text("Restore Purchases")
                            .font(.subheadline)
                            .foregroundColor(.modusCyan)
                    }
                    .accessibilityLabel("Restore previous purchases")

                    // MARK: - Legal Text
                    Text("Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period. Your Apple ID account will be charged for renewal within 24 hours prior to the end of the current period. You can manage and cancel your subscriptions in your App Store account settings.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, Spacing.lg)
                }
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .task {
            await storeKit.loadProducts()
            if selectedProduct == nil {
                selectedProduct = storeKit.annualProduct
            }
        }
    }

    // MARK: - Computed Properties

    private var currentPlanDescription: String {
        if storeKit.purchasedProductIDs.contains(Config.Subscription.annualProductID) {
            return "Annual Premium - $59.99/year"
        } else if storeKit.purchasedProductIDs.contains(Config.Subscription.monthlyProductID) {
            return "Monthly Premium - $9.99/month"
        } else {
            return "Premium Subscription"
        }
    }

    // MARK: - Purchase Logic

    private func purchaseButtonTitle(for product: Product) -> String {
        if product.id == Config.Subscription.annualProductID {
            return "Start Free Trial"
        } else {
            return "Subscribe — \(product.displayPrice)/month"
        }
    }

    private func purchaseSelected() async {
        guard let product = selectedProduct else { return }
        isPurchasing = true
        errorMessage = nil

        do {
            try await storeKit.purchase(product)
            if storeKit.isPremium {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isPurchasing = false
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.modusCyan, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Pricing Card

private struct PricingCard: View {
    let product: Product
    let name: String
    let badge: String?
    let subtitle: String?
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(name)
                        .font(.headline)

                    if let badge = badge {
                        Text(badge)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, 3)
                            .background(
                                LinearGradient(
                                    colors: [.modusCyan, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(CornerRadius.sm)
                    }
                }

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text(product.displayPrice)
                .font(.title3)
                .fontWeight(.bold)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? Color.modusCyan : Color(.separator), lineWidth: isSelected ? 2 : 1)
        )
    }
}
