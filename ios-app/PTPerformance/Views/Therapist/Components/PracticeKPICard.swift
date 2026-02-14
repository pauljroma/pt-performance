//
//  PracticeKPICard.swift
//  PTPerformance
//
//  Reusable KPI card component for the Practice Intelligence dashboard
//  Displays a large number with trend indicator and comparison to last period
//

import SwiftUI

// MARK: - Practice KPI Card

struct PracticeKPICard: View {
    let kpi: PracticeKPI
    var onTap: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap?()
        }) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Header row with icon and trend
                HStack {
                    Image(systemName: kpi.icon)
                        .font(.title3)
                        .foregroundColor(kpi.color)

                    Spacer()

                    if let trend = kpi.trend {
                        PracticeKPITrendBadge(trend: trend)
                    }
                }

                Spacer()

                // Large value display
                Text(kpi.value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                // Title and comparison
                VStack(alignment: .leading, spacing: 2) {
                    Text(kpi.title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let trend = kpi.trend {
                        Text(trend.comparisonPeriod)
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                }
            }
            .frame(minWidth: 150, minHeight: 140)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.lg)
            .adaptiveShadow(Shadow.medium)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(onTap != nil ? "Double tap to view details" : "")
    }

    private var accessibilityLabel: String {
        var label = "\(kpi.title): \(kpi.value)"
        if let trend = kpi.trend {
            let direction = trend.direction == .up ? "up" : (trend.direction == .down ? "down" : "unchanged")
            label += ", \(direction) \(String(format: "%.1f", trend.percentage)) percent \(trend.comparisonPeriod)"
        }
        return label
    }
}

// MARK: - Practice KPI Trend Badge

struct PracticeKPITrendBadge: View {
    let trend: PracticeKPI.Trend

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: trend.direction.icon)
                .font(.caption2)
                .fontWeight(.semibold)

            Text("\(String(format: "%.1f", trend.percentage))%")
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .foregroundColor(trend.direction.color)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(trend.direction.color.opacity(0.15))
        .cornerRadius(CornerRadius.xs)
    }
}

// MARK: - KPI Card Grid

struct PracticeKPIGrid: View {
    let kpis: [PracticeKPI]
    var onKPITap: ((PracticeKPI) -> Void)?

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: Spacing.md),
            GridItem(.flexible(), spacing: Spacing.md)
        ], spacing: Spacing.md) {
            ForEach(kpis) { kpi in
                PracticeKPICard(kpi: kpi) {
                    onKPITap?(kpi)
                }
            }
        }
    }
}

// MARK: - Large KPI Display

/// Larger, more prominent KPI display for hero metrics
struct LargeKPIDisplay: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    let trend: PracticeKPI.Trend?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.8), color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)

                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
            }

            // Value with trend
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Text(value)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                if let trend = trend {
                    Image(systemName: trend.direction.icon)
                        .font(.title3)
                        .foregroundColor(trend.direction.color)
                }
            }

            // Title
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)

            // Subtitle with trend info
            if let subtitle = subtitle ?? trend?.comparisonPeriod {
                HStack(spacing: 4) {
                    if let trend = trend {
                        Text("\(String(format: "%.1f", trend.percentage))%")
                            .fontWeight(.semibold)
                            .foregroundColor(trend.direction.color)
                    }
                    Text(subtitle)
                        .foregroundColor(.secondary)
                }
                .font(.caption)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.medium)
    }
}

// MARK: - Compact KPI Row

/// Compact horizontal KPI display for smaller spaces
struct CompactKPIRow: View {
    let kpis: [PracticeKPI]

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(kpis) { kpi in
                CompactKPIItem(kpi: kpi)
                if kpi.id != kpis.last?.id {
                    Divider()
                        .frame(height: 40)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }
}

struct CompactKPIItem: View {
    let kpi: PracticeKPI

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: kpi.icon)
                    .font(.caption)
                    .foregroundColor(kpi.color)

                Text(kpi.value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                if let trend = kpi.trend {
                    Image(systemName: trend.direction.icon)
                        .font(.caption2)
                        .foregroundColor(trend.direction.color)
                }
            }

            Text(kpi.title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#if DEBUG
struct PracticeKPICard_Previews: PreviewProvider {
    static var sampleKPIs: [PracticeKPI] = [
        PracticeKPI(
            id: "patients",
            title: "Active Patients",
            value: "47",
            trend: PracticeKPI.Trend(
                direction: .up,
                percentage: 12.5,
                comparisonPeriod: "vs last week"
            ),
            trendValue: "+12.5%",
            icon: "person.2.fill",
            color: .blue
        ),
        PracticeKPI(
            id: "adherence",
            title: "Avg Adherence",
            value: "78%",
            trend: PracticeKPI.Trend(
                direction: .down,
                percentage: 3.2,
                comparisonPeriod: "vs last week"
            ),
            trendValue: "-3.2%",
            icon: "checkmark.circle.fill",
            color: .yellow
        ),
        PracticeKPI(
            id: "risk",
            title: "At Risk",
            value: "8",
            trend: nil,
            trendValue: nil,
            icon: "exclamationmark.triangle.fill",
            color: .red
        ),
        PracticeKPI(
            id: "programs",
            title: "Programs",
            value: "12",
            trend: nil,
            trendValue: nil,
            icon: "list.bullet.rectangle.portrait.fill",
            color: .purple
        )
    ]

    static var previews: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Grid layout
                Text("KPI Grid")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                PracticeKPIGrid(kpis: sampleKPIs) { kpi in
                    print("Tapped: \(kpi.title)")
                }

                // Large display
                Text("Large Display")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                LargeKPIDisplay(
                    title: "Average Adherence",
                    value: "78%",
                    subtitle: nil,
                    icon: "checkmark.circle.fill",
                    color: .green,
                    trend: PracticeKPI.Trend(
                        direction: .up,
                        percentage: 5.2,
                        comparisonPeriod: "vs last week"
                    )
                )

                // Compact row
                Text("Compact Row")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                CompactKPIRow(kpis: sampleKPIs)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
