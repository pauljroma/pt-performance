//
//  ReportMetricCard.swift
//  PTPerformance
//
//  M7 - PT Weekly Report System
//  Reusable metric display card for reports
//

import SwiftUI

// MARK: - Report Metric Card

/// Reusable card for displaying metrics in weekly reports
/// Supports trend indicators and color-coded status
struct ReportMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let trend: TrendDirection?
    let color: Color

    var previousValue: String?
    var showComparison: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Title
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)

            // Value with trend
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xxs) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if let trend = trend {
                    TrendIndicatorView(trend: trend)
                }
            }

            // Subtitle
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(trend?.color ?? .secondary)
                .lineLimit(1)

            // Previous comparison (optional)
            if showComparison, let previous = previousValue {
                Text("Previous: \(previous)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value), \(subtitle)")
    }
}

// MARK: - Trend Indicator View

/// Small trend indicator with arrow and color
struct TrendIndicatorView: View {
    let trend: TrendDirection

    var body: some View {
        Image(systemName: trend.iconName)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(trend.color)
            .accessibilityLabel(trend.accessibilityLabel)
    }
}

// MARK: - Large Metric Card

/// Larger metric card for prominent display
struct LargeReportMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let trend: TrendDirection?
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }

            // Content
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    Text(value)
                        .font(.title)
                        .fontWeight(.bold)

                    if let trend = trend {
                        TrendIndicatorView(trend: trend)
                    }
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(trend?.color ?? .secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value), \(subtitle)")
    }
}

// MARK: - Comparison Metric Card

/// Metric card that shows comparison between two values
struct ComparisonMetricCard: View {
    let title: String
    let currentValue: String
    let previousValue: String
    let trend: TrendDirection

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(alignment: .center, spacing: Spacing.md) {
                // Previous value
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Previous")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(previousValue)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }

                // Arrow
                Image(systemName: trend.iconName)
                    .font(.title3)
                    .foregroundColor(trend.color)

                // Current value
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Current")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(currentValue)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(trend.color)
                }

                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): Changed from \(previousValue) to \(currentValue), \(trend.displayName)")
    }
}

// MARK: - Mini Metric Badge

/// Compact metric badge for inline display
struct MiniMetricBadge: View {
    let value: String
    let trend: TrendDirection?
    let color: Color

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)

            if let trend = trend {
                Image(systemName: trend.iconName)
                    .font(.caption2)
            }
        }
        .foregroundColor(color)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(color.opacity(0.15))
        .cornerRadius(CornerRadius.sm)
    }
}

// MARK: - Progress Metric Card

/// Metric card with progress bar
struct ProgressMetricCard: View {
    let title: String
    let value: String
    let progress: Double
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.tertiarySystemGroupedBackground))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(
                            width: geometry.size.width * CGFloat(min(max(progress, 0), 1)),
                            height: 8
                        )
                }
            }
            .frame(height: 8)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value), \(subtitle)")
        .accessibilityValue("\(Int(progress * 100)) percent complete")
    }
}

// MARK: - Metric Card Row

/// Row of metric cards with equal spacing
struct MetricCardRow<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            content
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ReportMetricCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                Text("Standard Cards")
                    .font(.headline)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Spacing.sm) {
                    ReportMetricCard(
                        title: "Sessions",
                        value: "4/5",
                        subtitle: "80%",
                        trend: nil,
                        color: .blue
                    )

                    ReportMetricCard(
                        title: "Adherence",
                        value: "92%",
                        subtitle: "Improving",
                        trend: .improving,
                        color: .green
                    )

                    ReportMetricCard(
                        title: "Pain Level",
                        value: "3.5",
                        subtitle: "Declining",
                        trend: .declining,
                        color: .red
                    )

                    ReportMetricCard(
                        title: "Recovery",
                        value: "75",
                        subtitle: "Stable",
                        trend: .stable,
                        color: .orange
                    )
                }

                Text("Large Card")
                    .font(.headline)

                LargeReportMetricCard(
                    title: "Session Completion",
                    value: "85%",
                    subtitle: "4 of 5 sessions completed",
                    trend: .improving,
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                Text("Comparison Card")
                    .font(.headline)

                ComparisonMetricCard(
                    title: "Weekly Pain Average",
                    currentValue: "3.2",
                    previousValue: "4.5",
                    trend: .improving
                )

                Text("Progress Card")
                    .font(.headline)

                ProgressMetricCard(
                    title: "Goal Progress",
                    value: "78%",
                    progress: 0.78,
                    subtitle: "ROM Improvement",
                    color: .blue
                )

                Text("Mini Badges")
                    .font(.headline)

                HStack(spacing: Spacing.sm) {
                    MiniMetricBadge(value: "+15%", trend: .improving, color: .green)
                    MiniMetricBadge(value: "0%", trend: .stable, color: .modusCyan)
                    MiniMetricBadge(value: "-5%", trend: .declining, color: .red)
                }
            }
            .padding()
        }
    }
}
#endif
