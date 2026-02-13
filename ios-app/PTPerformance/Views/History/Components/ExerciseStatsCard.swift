//
//  ExerciseStatsCard.swift
//  PTPerformance
//
//  Reusable stat card components for displaying exercise statistics
//  Extracted from ExerciseProgressView.swift for modularity
//

import SwiftUI

// MARK: - Progress Stat Card

/// A compact card displaying a single statistic with icon and color accent
struct ProgressStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .accessibilityHidden(true)

            Text(value)
                .font(.title3)
                .bold()

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Stat Item

/// A minimalist stat display with label and value
struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Summary Stats Row

/// A horizontal row of exercise summary statistics
struct SummaryStatsRow: View {
    let averageWeight: Double
    let totalVolume: Double
    let sessionCount: Int
    let displayUnit: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            StatItem(
                label: "Avg Weight",
                value: String(format: "%.1f %@", averageWeight, displayUnit)
            )

            Divider()
                .frame(height: 30)

            StatItem(
                label: "Total Volume",
                value: formatVolume(totalVolume)
            )

            Divider()
                .frame(height: 30)

            StatItem(
                label: "Sessions",
                value: "\(sessionCount)"
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Exercise summary: Average weight \(String(format: "%.1f", averageWeight)) \(displayUnit), Total volume \(formatVolume(totalVolume)), \(sessionCount) sessions")
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fK", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }
}

// MARK: - Progress Summary Header

/// A header section displaying overall progress overview with stat cards
struct ProgressSummaryHeader: View {
    let exerciseCount: Int
    let totalPersonalRecords: Int
    let improvingCount: Int
    let thisWeekCount: Int

    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Text("Progress Overview")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text("\(exerciseCount) exercises")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Progress Overview, \(exerciseCount) exercises tracked")

            HStack(spacing: Spacing.md) {
                ProgressStatCard(
                    title: "Total PRs",
                    value: "\(totalPersonalRecords)",
                    icon: "trophy.fill",
                    color: .yellow
                )

                ProgressStatCard(
                    title: "Improving",
                    value: "\(improvingCount)",
                    icon: "arrow.up.right",
                    color: .green
                )

                ProgressStatCard(
                    title: "This Week",
                    value: "\(thisWeekCount)",
                    icon: "calendar",
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Preview

#if DEBUG
struct ExerciseStatsCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.md) {
                ProgressStatCard(
                    title: "Total PRs",
                    value: "12",
                    icon: "trophy.fill",
                    color: .yellow
                )

                ProgressStatCard(
                    title: "Improving",
                    value: "8",
                    icon: "arrow.up.right",
                    color: .green
                )

                ProgressStatCard(
                    title: "This Week",
                    value: "5",
                    icon: "calendar",
                    color: .blue
                )
            }

            SummaryStatsRow(
                averageWeight: 185.0,
                totalVolume: 24500,
                sessionCount: 12,
                displayUnit: "lbs"
            )

            ProgressSummaryHeader(
                exerciseCount: 24,
                totalPersonalRecords: 12,
                improvingCount: 8,
                thisWeekCount: 5
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
