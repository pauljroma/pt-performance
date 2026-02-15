//
//  ComparisonPaywallLayout.swift
//  PTPerformance
//
//  ACP-991: Feature comparison paywall layout with side-by-side tier comparison table
//  (Free / Pro / Elite). Highlighted "Most Popular" badge and per-tier CTAs.
//

import SwiftUI
import StoreKit

// MARK: - Comparison Paywall Layout

struct ComparisonPaywallLayout: View {
    let variant: PaywallVariant
    let isPurchasing: Bool
    let onSelectTier: (String) -> Void
    let onRestorePurchases: () -> Void

    @EnvironmentObject private var storeKit: StoreKitService
    @Environment(\.colorScheme) private var colorScheme

    @State private var animateTable: Bool = false

    private let tiers = ComparisonTier.defaultTiers
    private let featureRows = ComparisonFeatureRow.defaultRows

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // MARK: - Header
            headerSection

            // MARK: - Comparison Table
            comparisonTable

            // MARK: - Tier Selection Cards
            tierCards

            // MARK: - Footer
            footerSection
        }
        .padding(.horizontal, Spacing.md)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animateTable = true
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Spacing.xs) {
            Text(variant.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(variant.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }

    // MARK: - Comparison Table

    private var comparisonTable: some View {
        VStack(spacing: 0) {
            // Table header row
            tableHeaderRow

            Divider()
                .padding(.horizontal, Spacing.xs)

            // Feature rows
            ForEach(Array(featureRows.enumerated()), id: \.element.id) { index, row in
                featureRow(row, index: index)

                if index < featureRows.count - 1 {
                    Divider()
                        .padding(.horizontal, Spacing.xs)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(colorScheme == .dark
                    ? Color(.secondarySystemBackground)
                    : Color(.systemBackground))
                .shadow(color: Shadow.subtle.color(for: colorScheme), radius: Shadow.subtle.radius, x: 0, y: Shadow.subtle.y)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(Color(.separator).opacity(0.2), lineWidth: 1)
        )
        .opacity(animateTable ? 1 : 0)
        .offset(y: animateTable ? 0 : 15)
    }

    // MARK: - Table Header Row

    private var tableHeaderRow: some View {
        HStack(spacing: 0) {
            // Feature column header
            Text("Feature")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, Spacing.sm)

            // Tier column headers
            ForEach(tiers) { tier in
                VStack(spacing: Spacing.xxs) {
                    if let badge = tier.badge {
                        Text(badge)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(tier.isHighlighted ? Color.modusCyan : Color.modusTealAccent)
                            )
                    }

                    Text(tier.name)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(tier.isHighlighted ? Color.modusCyan : .primary)

                    Text(tier.price)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 70)
            }
        }
        .padding(.vertical, Spacing.sm)
        .padding(.trailing, Spacing.xs)
    }

    // MARK: - Feature Row

    private func featureRow(_ row: ComparisonFeatureRow, index: Int) -> some View {
        HStack(spacing: 0) {
            // Feature name
            Text(row.featureName)
                .font(.caption)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, Spacing.sm)
                .lineLimit(1)

            // Free column
            featureCheckmark(included: row.freeIncluded)
                .frame(width: 70)

            // Pro column
            featureCheckmark(included: row.proIncluded, isHighlighted: true)
                .frame(width: 70)

            // Elite column
            featureCheckmark(included: row.eliteIncluded)
                .frame(width: 70)
        }
        .padding(.vertical, Spacing.xs)
        .padding(.trailing, Spacing.xs)
        .background(
            index % 2 == 1
                ? (colorScheme == .dark
                    ? Color.white.opacity(0.02)
                    : Color.black.opacity(0.02))
                : Color.clear
        )
        .opacity(animateTable ? 1 : 0)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.8)
                .delay(Double(index) * 0.04),
            value: animateTable
        )
    }

    // MARK: - Checkmark

    private func featureCheckmark(included: Bool, isHighlighted: Bool = false) -> some View {
        Group {
            if included {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(isHighlighted ? Color.modusCyan : Color.modusTealAccent)
            } else {
                Image(systemName: "minus.circle")
                    .font(.caption)
                    .foregroundStyle(Color(.tertiaryLabel))
            }
        }
    }

    // MARK: - Tier Cards

    private var tierCards: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(tiers) { tier in
                tierCard(tier)
            }
        }
        .opacity(animateTable ? 1 : 0)
        .offset(y: animateTable ? 0 : 20)
    }

    private func tierCard(_ tier: ComparisonTier) -> some View {
        let isFree = tier.name == "Free"

        return Button {
            if !isFree {
                HapticFeedback.medium()
            }
            onSelectTier(tier.name)
        } label: {
            HStack(spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack(spacing: Spacing.xs) {
                        Text(tier.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(tier.isHighlighted ? Color.modusCyan : .primary)

                        if let badge = tier.badge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(tier.isHighlighted ? Color.modusCyan : Color.modusTealAccent)
                                )
                        }
                    }

                    Text(tier.price)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isPurchasing && !isFree {
                    ProgressView()
                        .tint(tier.isHighlighted ? Color.modusCyan : .primary)
                } else {
                    Text(tier.ctaText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isFree ? .secondary : .white)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.sm)
                                .fill(isFree
                                    ? Color(.tertiarySystemFill)
                                    : (tier.isHighlighted ? Color.modusCyan : Color.modusTealAccent))
                        )
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(colorScheme == .dark
                        ? Color(.secondarySystemBackground)
                        : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(
                        tier.isHighlighted
                            ? Color.modusCyan.opacity(0.5)
                            : Color(.separator).opacity(0.2),
                        lineWidth: tier.isHighlighted ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isPurchasing)
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: Spacing.xs) {
            if variant.showTrial {
                Text("Start with a 7-day free trial on Pro or Elite")
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
}

// MARK: - Preview

#if DEBUG
struct ComparisonPaywallLayout_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            ComparisonPaywallLayout(
                variant: .sessionLimitDefault,
                isPurchasing: false,
                onSelectTier: { _ in },
                onRestorePurchases: {}
            )
        }
        .environmentObject(StoreKitService.shared)
    }
}
#endif
