//
//  SubscriptionSettingsView.swift
//  PTPerformance
//
//  ACP-986: Subscription Tier Architecture
//  ACP-987: StoreKit 2 Integration
//
//  Manage subscription view with current tier display, feature comparison,
//  manage/cancel links, and restore purchases functionality.
//

import SwiftUI
import StoreKit

// MARK: - Subscription Settings View

/// Settings view for managing the user's subscription.
///
/// Displays the current tier with a visual badge, a feature comparison table
/// across Free/Pro/Elite tiers, subscription management controls, and a
/// restore purchases button.
struct SubscriptionSettingsView: View {

    // MARK: - Environment

    @EnvironmentObject var storeKit: StoreKitService
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var isRestoring = false
    @State private var showRestoreSuccess = false
    @State private var showRestoreError = false
    @State private var restoreErrorMessage = ""
    @State private var showPaywall = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Current Tier Badge
                currentTierSection

                // Status Details
                if subscriptionManager.isSubscribed {
                    statusDetailsSection
                }

                // Feature Comparison Table
                featureComparisonSection

                // Action Buttons
                actionButtonsSection

                // Legal Text
                legalTextSection
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.lg)
        }
        .background(DesignTokens.backgroundGrouped)
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            SubscriptionView()
                .environmentObject(storeKit)
        }
        .alert("Purchases Restored", isPresented: $showRestoreSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your purchases have been restored successfully.")
        }
        .alert("Restore Failed", isPresented: $showRestoreError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(restoreErrorMessage)
        }
    }

    // MARK: - Current Tier Section

    private var currentTierSection: some View {
        VStack(spacing: Spacing.md) {
            // Tier Icon
            ZStack {
                Circle()
                    .fill(tierGradient(for: subscriptionManager.currentTier))
                    .frame(width: 80, height: 80)

                Image(systemName: subscriptionManager.currentTier.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)

            // Tier Name
            Text(subscriptionManager.currentTier.displayName)
                .font(.title)
                .fontWeight(.bold)

            // Tier Badge
            Text(tierBadgeText)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(
                    Capsule().fill(tierGradient(for: subscriptionManager.currentTier))
                )

            // Status Summary
            Text(subscriptionManager.statusSummary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
        .padding(.horizontal, Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(DesignTokens.backgroundPrimary)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current plan: \(subscriptionManager.currentTier.displayName). \(subscriptionManager.statusSummary)")
    }

    // MARK: - Status Details Section

    private var statusDetailsSection: some View {
        VStack(spacing: Spacing.sm) {
            // Expiration Date
            if let expDate = subscriptionManager.formattedExpirationDate {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    Text("Renews")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(expDate)
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Subscription renews on \(expDate)")
            }

            // Trial Period
            if subscriptionManager.isInTrialPeriod {
                HStack {
                    Image(systemName: "gift.fill")
                        .foregroundStyle(Color.modusCyan)
                    Text("Free Trial")
                        .foregroundStyle(Color.modusCyan)
                        .fontWeight(.medium)
                    Spacer()
                    if let days = subscriptionManager.daysUntilExpiration {
                        Text("\(days) days remaining")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Free trial active. \(subscriptionManager.daysUntilExpiration.map { "\($0) days remaining" } ?? "")")
            }

            // Grace Period Warning
            if subscriptionManager.isInGracePeriod {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(DesignTokens.statusWarning)
                    Text("Billing issue - please update your payment method")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.statusWarning)
                }
                .padding(Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(DesignTokens.statusWarning.opacity(0.1))
                )
                .accessibilityLabel("Billing issue. Please update your payment method.")
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(DesignTokens.backgroundPrimary)
        )
    }

    // MARK: - Feature Comparison Section

    private var featureComparisonSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Compare Plans")
                .font(.headline)
                .padding(.horizontal, Spacing.xxs)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                // Header Row
                featureComparisonHeader

                Divider()

                // Feature Rows
                ForEach(comparisonFeatures, id: \.feature) { item in
                    featureComparisonRow(item)
                    if item.feature != comparisonFeatures.last?.feature {
                        Divider()
                            .padding(.horizontal, Spacing.sm)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(DesignTokens.backgroundPrimary)
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        }
    }

    private var featureComparisonHeader: some View {
        HStack {
            Text("Feature")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(SubscriptionTier.allCases) { tier in
                Text(tier.displayName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(tier == subscriptionManager.currentTier ? .modusCyan : .secondary)
                    .frame(width: 52)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(DesignTokens.backgroundSecondary)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Feature comparison header: Free, Pro, Elite")
    }

    private func featureComparisonRow(_ item: ComparisonItem) -> some View {
        HStack {
            HStack(spacing: Spacing.xs) {
                Image(systemName: item.icon)
                    .font(.caption2)
                    .foregroundStyle(Color.modusCyan)
                    .frame(width: 16)
                    .accessibilityHidden(true)

                Text(item.name)
                    .font(.caption)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(SubscriptionTier.allCases) { tier in
                tierAccessIcon(tier.hasAccess(to: item.feature))
                    .frame(width: 52)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name): \(accessibilityTierAccess(for: item.feature))")
    }

    @ViewBuilder
    private func tierAccessIcon(_ hasAccess: Bool) -> some View {
        if hasAccess {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(DesignTokens.statusSuccess)
        } else {
            Image(systemName: "minus.circle")
                .font(.caption)
                .foregroundStyle(Color(.tertiaryLabel))
        }
    }

    // MARK: - Action Buttons Section

    private var actionButtonsSection: some View {
        VStack(spacing: Spacing.sm) {
            // Upgrade / Manage Button
            if subscriptionManager.isSubscribed {
                // Manage Subscription
                Button {
                    HapticFeedback.light()
                    Task {
                        await subscriptionManager.openManageSubscriptions()
                    }
                } label: {
                    HStack {
                        Image(systemName: "gear")
                        Text("Manage Subscription")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color(.secondarySystemGroupedBackground))
                    .foregroundStyle(.primary)
                    .cornerRadius(CornerRadius.md)
                }
                .accessibilityLabel("Manage your subscription in the App Store")
            } else {
                // Upgrade Button
                Button {
                    HapticFeedback.medium()
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "star.fill")
                        Text("Upgrade to Pro")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
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
                .accessibilityLabel("Upgrade to Pro subscription")
            }

            // Restore Purchases
            Button {
                HapticFeedback.light()
                Task {
                    await restorePurchases()
                }
            } label: {
                HStack {
                    if isRestoring {
                        ProgressView()
                            .tint(.modusCyan)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                    Text("Restore Purchases")
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .foregroundStyle(Color.modusCyan)
            }
            .disabled(isRestoring)
            .accessibilityLabel(isRestoring ? "Restoring purchases" : "Restore previous purchases")
        }
    }

    // MARK: - Legal Text Section

    private var legalTextSection: some View {
        VStack(spacing: Spacing.xs) {
            Text("Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period. Your Apple ID account will be charged for renewal within 24 hours prior to the end of the current period.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: Spacing.md) {
                if let termsURL = URL(string: "https://getmodus.app/terms") {
                    Link("Terms", destination: termsURL)
                        .font(.caption2)
                        .foregroundStyle(Color.modusCyan)
                }
                if let privacyURL = URL(string: "https://getmodus.app/privacy") {
                    Link("Privacy", destination: privacyURL)
                        .font(.caption2)
                        .foregroundStyle(Color.modusCyan)
                }
            }
        }
        .padding(.top, Spacing.sm)
    }

    // MARK: - Actions

    private func restorePurchases() async {
        isRestoring = true
        defer { isRestoring = false }

        await subscriptionManager.restorePurchases()

        if subscriptionManager.isSubscribed {
            showRestoreSuccess = true
            HapticFeedback.success()
            DebugLogger.shared.success("SubscriptionSettings", "Purchases restored successfully")
        } else {
            restoreErrorMessage = "No previous purchases were found for this Apple ID."
            showRestoreError = true
            HapticFeedback.warning()
            DebugLogger.shared.info("SubscriptionSettings", "Restore completed but no subscriptions found")
        }
    }

    // MARK: - Helpers

    private var tierBadgeText: String {
        switch subscriptionManager.currentTier {
        case .free: return "FREE PLAN"
        case .pro: return "PRO MEMBER"
        case .elite: return "ELITE MEMBER"
        }
    }

    private func tierGradient(for tier: SubscriptionTier) -> LinearGradient {
        switch tier {
        case .free:
            return LinearGradient(
                colors: [.gray, .gray.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .pro:
            return LinearGradient(
                colors: [.modusCyan, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .elite:
            return LinearGradient(
                colors: [.purple, .orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func accessibilityTierAccess(for feature: SubscriptionTier.Feature) -> String {
        let tiers = SubscriptionTier.allCases.filter { $0.hasAccess(to: feature) }
        let tierNames = tiers.map { $0.displayName }.joined(separator: ", ")
        return "Available in \(tierNames)"
    }
}

// MARK: - Comparison Data

private struct ComparisonItem {
    let feature: SubscriptionTier.Feature
    let name: String
    let icon: String
}

private let comparisonFeatures: [ComparisonItem] = [
    ComparisonItem(feature: .basicWorkouts, name: "Basic Workouts", icon: "figure.strengthtraining.traditional"),
    ComparisonItem(feature: .exerciseLibrary, name: "Exercise Library", icon: "books.vertical.fill"),
    ComparisonItem(feature: .unlimitedWorkouts, name: "Unlimited Workouts", icon: "infinity"),
    ComparisonItem(feature: .advancedAnalytics, name: "Analytics", icon: "chart.bar.fill"),
    ComparisonItem(feature: .aiCoaching, name: "AI Coaching", icon: "brain.head.profile"),
    ComparisonItem(feature: .nutritionTracking, name: "Nutrition", icon: "fork.knife"),
    ComparisonItem(feature: .readinessScoring, name: "Readiness", icon: "battery.100"),
    ComparisonItem(feature: .workoutHistory, name: "Full History", icon: "clock.arrow.circlepath"),
    ComparisonItem(feature: .customPrograms, name: "Custom Programs", icon: "doc.badge.plus"),
    ComparisonItem(feature: .telehealth, name: "Telehealth", icon: "video.fill"),
    ComparisonItem(feature: .prioritySupport, name: "Priority Support", icon: "headphones"),
    ComparisonItem(feature: .exportData, name: "Data Export", icon: "square.and.arrow.up.fill"),
    ComparisonItem(feature: .wearableIntegration, name: "Wearables", icon: "applewatch"),
]

// MARK: - Preview

#Preview {
    NavigationStack {
        SubscriptionSettingsView()
            .environmentObject(StoreKitService.shared)
            .environmentObject(SubscriptionManager.shared)
    }
}
