//
//  BaseballPackPromoCard.swift
//  PTPerformance
//
//  Promotional card shown in the Programs hub for the Baseball Pack
//

import SwiftUI

/// Promotional card for the Baseball Pack displayed in the Programs Hub
/// Shows premium badge if user doesn't own the pack
struct BaseballPackPromoCard: View {
    @EnvironmentObject var storeKit: StoreKitService

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover image area
            coverImage

            // Content area
            contentSection
        }
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .shadow(color: Color(.systemGray4).opacity(0.1), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Baseball Pack promo, 12 plus programs for pitchers and position players")
    }

    // MARK: - Cover Image

    private var coverImage: some View {
        ZStack(alignment: .topTrailing) {
            // Baseball imagery placeholder
            ZStack {
                LinearGradient(
                    colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Image(systemName: "baseball.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(height: 120)
            .clipped()

            // Premium badge overlay
            if !storeKit.hasBaseballAccess {
                Text("PREMIUM")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, Spacing.xxs)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(CornerRadius.sm)
                    .padding(Spacing.xs)
            }
        }
    }

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title row
            HStack {
                Text("Baseball Pack")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                if storeKit.hasBaseballAccess {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.subheadline)
                }
            }

            // Description
            Text("12+ programs for pitchers & position players")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            // Features preview
            HStack(spacing: 12) {
                featureTag(icon: "figure.baseball", text: "Pitching")
                featureTag(icon: "figure.arms.open", text: "Arm Care")
                featureTag(icon: "bolt.fill", text: "Velocity")
            }
            .padding(.top, 4)
        }
        .padding(Spacing.sm)
    }

    // MARK: - Feature Tag

    private func featureTag(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
        }
        .foregroundColor(.orange)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(CornerRadius.sm)
    }
}

// MARK: - Compact Version for Grid Display

struct BaseballPackPromoCardCompact: View {
    @EnvironmentObject var storeKit: StoreKitService

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover image
            ZStack(alignment: .topTrailing) {
                ZStack {
                    LinearGradient(
                        colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Image(systemName: "baseball.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(height: 100)
                .clipped()

                // Premium badge
                if !storeKit.hasBaseballAccess {
                    Text("PREMIUM")
                        .font(.system(size: 9))
                        .fontWeight(.bold)
                        .padding(.horizontal, Spacing.xxs)
                        .padding(.vertical, 2)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(CornerRadius.sm)
                        .padding(Spacing.xxs)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Category badge
                HStack(spacing: 4) {
                    Image(systemName: "baseball.fill")
                        .font(.caption2)
                    Text("Baseball")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.orange)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, Spacing.xxs)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(CornerRadius.sm)

                // Title
                Text("Baseball Pack")
                    .font(.headline)
                    .lineLimit(2)

                // Description
                Text("12+ programs for pitchers & position players")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                Spacer(minLength: 4)

                // Bottom row
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "rectangle.stack.fill")
                            .font(.caption2)
                        Text("12+ Programs")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)

                    Spacer()

                    if storeKit.hasBaseballAccess {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }
            .padding(Spacing.sm)
        }
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .topLeading)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .clipped()
        .shadow(color: Color(.systemGray4).opacity(0.08), radius: 2, x: 0, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Baseball Pack compact, 12 plus programs")
    }
}

// MARK: - Preview

#Preview("Full Card") {
    BaseballPackPromoCard()
        .environmentObject(StoreKitService.shared)
        .padding()
}

#Preview("Compact Card") {
    BaseballPackPromoCardCompact()
        .environmentObject(StoreKitService.shared)
        .frame(width: 180)
        .padding()
}
