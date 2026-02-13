//
//  BaseballPackLockedView.swift
//  PTPerformance
//
//  Shown when trying to access baseball content without owning the Baseball Pack
//

import SwiftUI

/// View shown when user attempts to access baseball content without purchasing the pack
struct BaseballPackLockedView: View {
    @EnvironmentObject var storeKit: StoreKitService
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            iconSection

            // Title and description
            textSection

            // Features list
            featuresSection

            // CTA Button
            ctaSection

            Spacer()
        }
        .padding()
        .navigationTitle("Baseball Pack")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Icon Section

    private var iconSection: some View {
        ZStack {
            Circle()
                .fill(Color.orange.opacity(0.15))
                .frame(width: 120, height: 120)

            Image(systemName: "baseball.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
        }
    }

    // MARK: - Text Section

    private var textSection: some View {
        VStack(spacing: 12) {
            Text("Baseball Pack Required")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Unlock 12+ baseball-specific programs including weighted ball progressions, arm care, and position-specific training.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            featureRow(icon: "figure.baseball", title: "Weighted Ball Programs", description: "Progressive arm strength protocols")
            featureRow(icon: "figure.arms.open", title: "Arm Care Routines", description: "Injury prevention and longevity")
            featureRow(icon: "bolt.fill", title: "Velocity Development", description: "Evidence-based throwing programs")
            featureRow(icon: "person.fill.checkmark", title: "Position-Specific", description: "Tailored for pitchers and position players")
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Feature Row

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.orange)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - CTA Section

    private var ctaSection: some View {
        VStack(spacing: 12) {
            NavigationLink(destination: BaseballPackView()) {
                HStack {
                    Image(systemName: "lock.open.fill")
                    Text("View Baseball Pack")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(CornerRadius.md)
            }

            // Restore purchases button
            Button {
                Task {
                    await storeKit.restorePurchases()
                }
            } label: {
                Text("Restore Purchases")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Inline Locked Banner

/// Compact banner shown inline when baseball content is locked
struct BaseballPackLockedBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.title3)
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Baseball Pack Required")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("Unlock baseball-specific training programs")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            NavigationLink(destination: BaseballPackView()) {
                Text("View")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(CornerRadius.sm)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Premium Badge for Baseball Programs

struct BaseballPremiumBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(.caption2)
            Text("BASEBALL PACK")
                .font(.caption2)
                .fontWeight(.bold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.orange)
        .cornerRadius(CornerRadius.xs)
    }
}

// MARK: - Preview

#Preview("Locked View") {
    NavigationStack {
        BaseballPackLockedView()
            .environmentObject(StoreKitService.shared)
    }
}

#Preview("Locked Banner") {
    BaseballPackLockedBanner()
        .padding()
}

#Preview("Premium Badge") {
    BaseballPremiumBadge()
        .padding()
}
