//
//  SupplementRecommendationView.swift
//  PTPerformance
//
//  ACP-1008: Momentous Supplement Revenue — Contextual supplement recommendation cards
//  Non-intrusive partner content with affiliate link tracking.
//

import SwiftUI
import SafariServices

// MARK: - Supplement Recommendation View

/// Displays contextual Momentous supplement recommendations.
///
/// Appears in recovery/nutrition sections as non-intrusive partner content.
/// Each card shows product details, benefits, and opens an affiliate link
/// in SFSafariViewController when tapped.
///
/// ## Partner Content Transparency
/// All content is clearly labeled as "Partner Content" and "Recommended
/// for your training" to maintain user trust.
struct SupplementRecommendationView: View {

    @StateObject private var service = MomentousSupplementService.shared

    /// The training goal context for filtering recommendations
    let goal: TrainingGoalContext

    /// Optional max number of cards to show
    var maxCards: Int = 3

    @State private var safariURL: URL?
    @State private var showingSafari = false

    var body: some View {
        let recommendations = Array(service.getRecommendations(for: goal).prefix(maxCards))

        if recommendations.isEmpty && !service.isLoading {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Partner content header
                partnerHeader

                if service.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                } else {
                    // Recommendation cards
                    ForEach(recommendations) { recommendation in
                        SupplementCardView(
                            recommendation: recommendation,
                            onLearnMore: {
                                openAffiliateLink(for: recommendation)
                            }
                        )
                    }
                }
            }
            .task {
                if service.recommendations.isEmpty {
                    await service.fetchRecommendations()
                }
            }
            .sheet(isPresented: $showingSafari) {
                if let url = safariURL {
                    SafariView(url: url)
                        .ignoresSafeArea()
                }
            }
        }
    }

    // MARK: - Partner Header

    private var partnerHeader: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "leaf.fill")
                .font(.caption)
                .foregroundColor(.green)

            Text("Partner Content")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            Spacer()

            Text("Momentous")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding(.horizontal, Spacing.xs)
    }

    // MARK: - Affiliate Link

    private func openAffiliateLink(for recommendation: MomentousRecommendation) {
        service.recordSupplementClick(recommendation)

        if let url = service.affiliateURL(for: recommendation) {
            safariURL = url
            showingSafari = true
        }
    }
}

// MARK: - Supplement Card View

/// Individual supplement recommendation card with product details.
struct SupplementCardView: View {
    let recommendation: MomentousRecommendation
    let onLearnMore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                // Product icon placeholder (would be image in production)
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 56, height: 56)

                    Image(systemName: "leaf.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    // Product name
                    Text(recommendation.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    // Description
                    Text(recommendation.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    // Context label
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 9))
                        Text("Recommended for your \(recommendation.context.lowercased()) goals")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.modusCyan)
                    .padding(.top, Spacing.xxs)
                }

                Spacer(minLength: 0)
            }

            // Benefits
            if !recommendation.benefits.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    ForEach(recommendation.benefits.prefix(2), id: \.self) { benefit in
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(DesignTokens.statusSuccess)
                            Text(benefit)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.leading, Spacing.xxs)
            }

            // Bottom row: price + learn more
            HStack {
                Text(recommendation.formattedPrice)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                // Evidence rating
                Text(recommendation.evidenceStars)
                    .font(.caption2)
                    .foregroundColor(.orange)

                Spacer()

                Button(action: onLearnMore) {
                    HStack(spacing: Spacing.xxs) {
                        Text("Learn More")
                            .font(.caption)
                            .fontWeight(.medium)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.modusCyan)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.modusCyan.opacity(0.1))
                    .cornerRadius(CornerRadius.lg)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.sm)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .strokeBorder(Color(.systemGray5), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Safari View (SFSafariViewController Wrapper)

/// UIViewControllerRepresentable wrapper for SFSafariViewController.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        config.barCollapsingEnabled = true

        let safari = SFSafariViewController(url: url, configuration: config)
        safari.preferredControlTintColor = UIColor(Color.modusCyan)
        return safari
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - Inline Supplement Section

/// A compact section for embedding supplement recommendations within other views.
///
/// Use this in recovery dashboards, nutrition views, etc. for contextual placement.
struct InlineSupplementSection: View {
    let goal: TrainingGoalContext

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Supplements for You")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                NavigationLink {
                    SupplementRecommendationView(goal: goal, maxCards: 10)
                        .navigationTitle("Supplement Recommendations")
                } label: {
                    Text("See All")
                        .font(.caption)
                        .foregroundColor(.modusCyan)
                }
            }

            SupplementRecommendationView(goal: goal, maxCards: 2)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    NavigationStack {
        ScrollView {
            SupplementRecommendationView(goal: .recovery)
                .padding()
        }
    }
}
#endif
