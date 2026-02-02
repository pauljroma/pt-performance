//
//  BigLiftsScorecard.swift
//  PTPerformance
//
//  Displays big lift (SBD + optional accessories) progress in a card-based scorecard
//  Shows current max, estimated 1RM, PRs, and improvement trends
//

import SwiftUI

// MARK: - Big Lifts Scorecard

/// Main scorecard view displaying big lifts progress
/// Shows each lift as a card with current max, estimated 1RM, PRs, and trends
struct BigLiftsScorecard: View {
    let patientId: String

    @StateObject private var viewModel = BigLiftsViewModel()
    @AppStorage("preferredWeightUnit") private var preferredWeightUnit: String = "lbs"

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Section Header
            sectionHeader

            // Content
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.errorMessage {
                errorView(message: error)
            } else if viewModel.isEmpty {
                emptyStateView
            } else {
                liftsContent
            }
        }
        .task {
            guard let uuid = UUID(uuidString: patientId) else { return }
            await viewModel.fetchData(for: uuid)
        }
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Big Lifts")
                    .font(.title2)
                    .fontWeight(.bold)
                    .accessibilityAddTraits(.isHeader)

                if !viewModel.isEmpty && viewModel.estimatedTotal > 0 {
                    Text("Est. Total: \(Int(viewModel.estimatedTotal)) \(preferredWeightUnit)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if !viewModel.isEmpty {
                summaryBadges
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Summary Badges

    private var summaryBadges: some View {
        HStack(spacing: Spacing.sm) {
            if viewModel.totalPRCount > 0 {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                    Text("\(viewModel.totalPRCount)")
                        .fontWeight(.semibold)
                }
                .font(.caption)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, Spacing.xxs)
                .background(Color.yellow.opacity(0.15))
                .cornerRadius(CornerRadius.xs)
            }

            if viewModel.improvingCount > 0 {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(.green)
                    Text("\(viewModel.improvingCount)")
                        .fontWeight(.semibold)
                }
                .font(.caption)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, Spacing.xxs)
                .background(Color.green.opacity(0.15))
                .cornerRadius(CornerRadius.xs)
            }
        }
    }

    // MARK: - Lifts Content

    private var liftsContent: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                ForEach(viewModel.bigLifts) { lift in
                    BigLiftCard(lift: lift, iconName: viewModel.iconName(for: lift.exerciseName))
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                ForEach(0..<3, id: \.self) { _ in
                    BigLiftCardSkeleton()
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
        }
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundColor(.orange)

            Text("Unable to load lifts")
                .font(.subheadline)
                .fontWeight(.medium)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                Task {
                    await viewModel.retryFetch()
                }
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .background(Color(.systemGray6))
        .cornerRadius(CornerRadius.md)
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "dumbbell")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            VStack(spacing: Spacing.xxs) {
                Text("No Big Lifts Yet")
                    .font(.headline)

                Text("Log Bench Press, Squat, or Deadlift to see your progress here")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
        .background(Color(.systemGray6))
        .cornerRadius(CornerRadius.md)
        .padding(.horizontal, Spacing.md)
    }
}

// MARK: - Big Lift Card

/// Individual card displaying a single big lift's stats
struct BigLiftCard: View {
    let lift: BigLiftSummary
    let iconName: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header with icon and name
            cardHeader

            // Current max (large, prominent)
            currentMaxDisplay

            // Estimated 1RM
            estimated1rmDisplay

            Divider()

            // PR and trend info
            bottomStats
        }
        .padding(Spacing.md)
        .frame(width: 160)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .shadow(
            color: Shadow.medium.color(for: colorScheme),
            radius: Shadow.medium.radius,
            x: Shadow.medium.x,
            y: Shadow.medium.y
        )
    }

    // MARK: - Card Header

    private var cardHeader: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: iconName)
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 20, height: 20)

            Text(lift.exerciseName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)

            Spacer()

            // Recent PR badge
            if lift.hasRecentPR {
                Image(systemName: "trophy.fill")
                    .font(.caption2)
                    .foregroundColor(.yellow)
            }
        }
    }

    // MARK: - Current Max Display

    private var currentMaxDisplay: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text("Current Max")
                .font(.caption2)
                .foregroundColor(.secondary)

            Text(lift.formattedMaxWeight)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
    }

    // MARK: - Estimated 1RM Display

    private var estimated1rmDisplay: some View {
        HStack {
            Text("Est. 1RM")
                .font(.caption2)
                .foregroundColor(.secondary)

            Spacer()

            Text(lift.formattedEstimated1rm)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    // MARK: - Bottom Stats

    private var bottomStats: some View {
        HStack {
            // Last PR info
            if lift.prCount > 0 {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 2) {
                        Image(systemName: "trophy")
                            .font(.caption2)
                        Text("\(lift.prCount) PRs")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)

                    if let days = lift.daysSinceLastPR {
                        Text("\(days)d ago")
                            .font(.caption2)
                            .foregroundColor(lift.hasRecentPR ? .yellow : .secondary)
                    }
                }
            }

            Spacer()

            // Improvement trend
            if let improvement = lift.formattedImprovement {
                trendBadge(improvement: improvement, isImproving: lift.isImproving)
            }
        }
    }

    // MARK: - Trend Badge

    private func trendBadge(improvement: String, isImproving: Bool) -> some View {
        HStack(spacing: 2) {
            Image(systemName: isImproving ? "arrow.up.right" : "arrow.down.right")
                .font(.caption2)

            Text(improvement)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(isImproving ? .green : .red)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, 2)
        .background(
            (isImproving ? Color.green : Color.red).opacity(0.15)
        )
        .cornerRadius(CornerRadius.xs)
    }
}

// MARK: - Big Lift Card Skeleton

/// Loading skeleton for the big lift card
struct BigLiftCardSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header skeleton
            HStack(spacing: Spacing.xs) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 20, height: 20)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 14)

                Spacer()
            }

            // Max weight skeleton
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 10)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 28)
            }

            // Est 1RM skeleton
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 10)

                Spacer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 14)
            }

            Divider()

            // Bottom stats skeleton
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 24)

                Spacer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 20)
            }
        }
        .padding(Spacing.md)
        .frame(width: 160)
        .background(Color(.systemGray6))
        .cornerRadius(CornerRadius.md)
        .shimmer(isAnimating: isAnimating)
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Shimmer Modifier

extension View {
    func shimmer(isAnimating: Bool) -> some View {
        self.modifier(ShimmerModifier(isAnimating: isAnimating))
    }
}

struct ShimmerModifier: ViewModifier {
    let isAnimating: Bool

    func body(content: Content) -> some View {
        content
            .redacted(reason: .placeholder)
            .opacity(isAnimating ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
    }
}

// MARK: - Alternative Grid Layout

/// Grid-based layout for bigger screens or full-page view
struct BigLiftsScorecardGrid: View {
    let patientId: String

    @StateObject private var viewModel = BigLiftsViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.md),
        GridItem(.flexible(), spacing: Spacing.md)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.isEmpty {
                EmptyStateView(
                    title: "No Big Lifts Yet",
                    message: "Log exercises like Bench Press, Squat, or Deadlift to track your strength progress",
                    icon: "dumbbell.fill",
                    iconColor: .secondary
                )
            } else {
                ScrollView {
                    // Summary Header
                    if viewModel.estimatedTotal > 0 {
                        totalSummaryHeader
                    }

                    // Grid of lift cards
                    LazyVGrid(columns: columns, spacing: Spacing.md) {
                        ForEach(viewModel.bigLifts) { lift in
                            BigLiftCard(lift: lift, iconName: viewModel.iconName(for: lift.exerciseName))
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                }
            }
        }
        .task {
            guard let uuid = UUID(uuidString: patientId) else { return }
            await viewModel.fetchData(for: uuid)
        }
        .refreshable {
            guard let uuid = UUID(uuidString: patientId) else { return }
            await viewModel.refresh(for: uuid)
        }
    }

    private var totalSummaryHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Estimated Total")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("\(Int(viewModel.estimatedTotal)) lbs")
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text("Total PRs")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                    Text("\(viewModel.totalPRCount)")
                        .fontWeight(.bold)
                }
                .font(.title3)
            }
        }
        .padding(Spacing.md)
        .background(Color(.systemGray6))
        .cornerRadius(CornerRadius.md)
        .padding(.horizontal, Spacing.md)
    }
}

// MARK: - Preview

#if DEBUG
struct BigLiftsScorecard_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Horizontal scroll preview
            VStack {
                BigLiftsScorecard(patientId: "preview-patient-1")
            }
            .previewDisplayName("Horizontal Scroll")

            // Grid layout preview
            NavigationStack {
                BigLiftsScorecardGrid(patientId: "preview-patient-1")
                    .navigationTitle("Big Lifts")
            }
            .previewDisplayName("Grid Layout")

            // Individual card preview
            ScrollView(.horizontal) {
                HStack(spacing: Spacing.md) {
                    BigLiftCard(
                        lift: BigLiftSummary.sample,
                        iconName: "figure.strengthtraining.traditional"
                    )

                    BigLiftCard(
                        lift: BigLiftSummary.sampleArray[1],
                        iconName: "figure.strengthtraining.functional"
                    )

                    BigLiftCard(
                        lift: BigLiftSummary.sampleArray[2],
                        iconName: "figure.cross.training"
                    )
                }
                .padding()
            }
            .previewDisplayName("Individual Cards")

            // Loading state
            ScrollView(.horizontal) {
                HStack(spacing: Spacing.md) {
                    BigLiftCardSkeleton()
                    BigLiftCardSkeleton()
                    BigLiftCardSkeleton()
                }
                .padding()
            }
            .previewDisplayName("Loading Skeleton")

            // Dark mode
            VStack {
                BigLiftsScorecard(patientId: "preview-patient-1")
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}
#endif
