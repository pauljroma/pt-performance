//
//  StrengthModeStatusCard.swift
//  PTPerformance
//
//  Status card for Strength Mode displaying big lifts, PRs, and volume trends
//  ACP-MODE: Mode-specific status card for strength-focused athletes
//

import SwiftUI

/// Status card component displaying strength mode metrics
/// Shows estimated total, top lifts, recent PRs, and volume trends
struct StrengthModeStatusCard: View {
    // MARK: - Properties

    var estimatedTotal: Double? = nil
    var topLifts: [TopLiftInfo] = []
    var recentPRs: [RecentPRInfo] = []
    var volumeTrend: VolumeTrend = .unknown
    var currentStreak: Int = 0
    var unit: String = "lbs"
    var onTapCard: (() -> Void)? = nil
    var onViewPRs: (() -> Void)? = nil
    var onViewVolume: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            headerSection

            // Content based on state
            if hasData {
                strengthMetricsSection
            } else {
                noDataPrompt
            }

            // Recent PRs section (if any)
            if !recentPRs.isEmpty {
                recentPRsSection
            }

            // Volume trend indicator
            if !volumeTrend.isUnknown {
                volumeTrendIndicator
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Computed Properties

    private var hasData: Bool {
        estimatedTotal != nil || !topLifts.isEmpty
    }

    private var formattedTotal: String {
        guard let total = estimatedTotal else { return "--" }
        return String(format: "%.0f", total)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        Button(action: {
            HapticFeedback.light()
            onTapCard?()
        }) {
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title2)
                    .foregroundColor(.orange)
                    .accessibilityHidden(true)

                Text("Strength Status")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                // Streak badge
                if currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("\(currentStreak)")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(CornerRadius.xs)
                }

                if onTapCard != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Strength status")
        .accessibilityHint(onTapCard != nil ? "Tap to view strength dashboard" : "")
    }

    // MARK: - Strength Metrics Section

    private var strengthMetricsSection: some View {
        VStack(spacing: Spacing.sm) {
            // Estimated total (SBD)
            if let _ = estimatedTotal {
                estimatedTotalCard
            }

            // Top lifts grid
            if !topLifts.isEmpty {
                topLiftsGrid
            }
        }
    }

    // MARK: - Estimated Total Card

    private var estimatedTotalCard: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Est. Total (SBD)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(formattedTotal)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .monospacedDigit()

                    Text(unit)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Trophy icon if recent PRs
            if !recentPRs.isEmpty {
                VStack {
                    Image(systemName: "trophy.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)

                    Text("\(recentPRs.count) PR\(recentPRs.count == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(Spacing.sm)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
    }

    // MARK: - Top Lifts Grid

    private var topLiftsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: Spacing.xs),
            GridItem(.flexible(), spacing: Spacing.xs),
            GridItem(.flexible(), spacing: Spacing.xs)
        ], spacing: Spacing.xs) {
            ForEach(topLifts.prefix(3)) { lift in
                topLiftCell(lift: lift)
            }
        }
    }

    private func topLiftCell(lift: TopLiftInfo) -> some View {
        VStack(spacing: 4) {
            Text(shortLiftName(lift.exerciseName))
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)

            Text(String(format: "%.0f", lift.weight))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .monospacedDigit()

            Text(lift.unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xs)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(lift.exerciseName): \(Int(lift.weight)) \(lift.unit)")
    }

    private func shortLiftName(_ name: String) -> String {
        switch name {
        case "Bench Press": return "Bench"
        case "Back Squat", "Squat": return "Squat"
        case "Deadlift": return "Dead"
        case "Overhead Press": return "OHP"
        default: return String(name.prefix(6))
        }
    }

    // MARK: - Recent PRs Section

    private var recentPRsSection: some View {
        Button(action: {
            HapticFeedback.light()
            onViewPRs?()
        }) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "star.fill")
                    .font(.subheadline)
                    .foregroundColor(.yellow)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Recent Personal Records")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(recentPRsSummary)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if onViewPRs != nil {
                    Text("View")
                        .font(.caption)
                        .foregroundColor(.modusCyan)
                }
            }
            .padding(Spacing.sm)
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(CornerRadius.sm)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Recent personal records")
        .accessibilityHint("Tap to view all PRs")
    }

    private var recentPRsSummary: String {
        let prNames = recentPRs.prefix(2).map { $0.exerciseName }
        let joined = prNames.joined(separator: ", ")
        if recentPRs.count > 2 {
            return "\(joined) +\(recentPRs.count - 2) more"
        }
        return joined
    }

    // MARK: - Volume Trend Indicator

    private var volumeTrendIndicator: some View {
        Button(action: {
            HapticFeedback.light()
            onViewVolume?()
        }) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: volumeTrend.icon)
                    .font(.subheadline)
                    .foregroundColor(volumeTrend.color)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Weekly Volume")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(volumeTrendDescription)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if onViewVolume != nil {
                    Image(systemName: "chart.bar.fill")
                        .font(.caption)
                        .foregroundColor(.modusCyan)
                }
            }
            .padding(Spacing.sm)
            .background(volumeTrend.color.opacity(0.1))
            .cornerRadius(CornerRadius.sm)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Weekly volume: \(volumeTrendDescription)")
    }

    private var volumeTrendDescription: String {
        switch volumeTrend {
        case .up(let percentage):
            return String(format: "Up %.0f%% from last week", percentage)
        case .down(let percentage):
            return String(format: "Down %.0f%% from last week", abs(percentage))
        case .stable:
            return "Consistent with last week"
        case .unknown:
            return "No trend data available"
        }
    }

    // MARK: - No Data Prompt

    private var noDataPrompt: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Start tracking your lifts")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Log compound lifts to see your strength stats")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            if let onTapCard = onTapCard {
                Button(action: {
                    HapticFeedback.light()
                    onTapCard()
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("View Dashboard")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(CornerRadius.sm)
                }
                .accessibilityLabel("View strength dashboard")
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct StrengthModeStatusCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                // With data
                StrengthModeStatusCard(
                    estimatedTotal: 1045,
                    topLifts: [
                        TopLiftInfo(exerciseName: "Bench Press", weight: 225, unit: "lbs"),
                        TopLiftInfo(exerciseName: "Squat", weight: 315, unit: "lbs"),
                        TopLiftInfo(exerciseName: "Deadlift", weight: 405, unit: "lbs")
                    ],
                    recentPRs: [
                        RecentPRInfo(
                            exerciseName: "Bench Press",
                            weight: 225,
                            unit: "lbs",
                            date: Date(),
                            improvement: 10
                        )
                    ],
                    volumeTrend: .up(percentage: 12.5),
                    currentStreak: 8,
                    onTapCard: {},
                    onViewPRs: {},
                    onViewVolume: {}
                )

                // No data
                StrengthModeStatusCard(
                    onTapCard: {}
                )

                // Minimal data
                StrengthModeStatusCard(
                    estimatedTotal: 800,
                    topLifts: [
                        TopLiftInfo(exerciseName: "Bench Press", weight: 185, unit: "lbs")
                    ],
                    volumeTrend: .down(percentage: 8.2),
                    onTapCard: {}
                )
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
