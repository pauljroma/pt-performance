import SwiftUI

/// Summary display of session metrics for quick overview
struct QuickMetricsSummary: View {
    let metrics: QuickMetrics
    let compact: Bool

    init(metrics: QuickMetrics, compact: Bool = false) {
        self.metrics = metrics
        self.compact = compact
    }

    var body: some View {
        if compact {
            CompactMetricsView(metrics: metrics)
        } else {
            ExpandedMetricsView(metrics: metrics)
        }
    }
}

// MARK: - Compact Metrics View

struct CompactMetricsView: View {
    let metrics: QuickMetrics

    var body: some View {
        HStack(spacing: 16) {
            // Sets progress
            MetricPill(
                icon: "checkmark.circle.fill",
                value: "\(metrics.completedSets)/\(metrics.totalSets)",
                color: metrics.isComplete ? .green : .blue
            )

            // Volume
            if let formattedVolume = metrics.formattedVolume {
                MetricPill(
                    icon: "scalemass.fill",
                    value: formattedVolume,
                    color: .purple
                )
            }

            // Average RPE
            if let formattedRPE = metrics.formattedAverageRPE {
                MetricPill(
                    icon: "bolt.fill",
                    value: formattedRPE,
                    color: (metrics.averageRPE ?? 0) > 8 ? .red : .orange
                )
            }

            // Pain flags
            if metrics.hasPainFlags {
                MetricPill(
                    icon: "exclamationmark.triangle.fill",
                    value: "\(metrics.painFlags)",
                    color: .red,
                    isWarning: true
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Expanded Metrics View

struct ExpandedMetricsView: View {
    let metrics: QuickMetrics

    private var displayItems: [MetricDisplayItem] {
        MetricDisplayItem.from(metrics: metrics)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Overall progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Session Progress")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Spacer()

                    Text("\(Int(metrics.progress * 100))%")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.blue)
                }

                ProgressBar(progress: metrics.progress, color: .blue)
                    .frame(height: 8)
            }

            // Metrics grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(displayItems) { item in
                    MetricCard(item: item)
                }
            }

            // Completion status
            if metrics.isComplete {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)

                    Text("Session Complete!")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.green)
                }
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }

            // Warning banners
            if metrics.hasPainFlags {
                WarningBanner(
                    icon: "exclamationmark.triangle.fill",
                    message: "\(metrics.painFlags) pain flag\(metrics.painFlags > 1 ? "s" : "") reported during session",
                    color: .red
                )
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Metric Pill (Compact)

struct MetricPill: View {
    let icon: String
    let value: String
    let color: Color
    var isWarning: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isWarning ? color.opacity(0.5) : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Metric Card (Expanded)

struct MetricCard: View {
    let item: MetricDisplayItem

    private var color: Color {
        switch item.color {
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        case "red": return .red
        case "gray": return .gray
        default: return .blue
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: item.icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)

                Text(item.label)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Text(item.value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(item.isWarning ? color.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Warning Banner

struct WarningBanner: View {
    let icon: String
    let message: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)

            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)

            Spacer()
        }
        .padding(12)
        .background(color.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.3), lineWidth: 1.5)
        )
    }
}

// MARK: - Preview

struct QuickMetricsSummary_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            // Compact view
            QuickMetricsSummary(
                metrics: QuickMetrics(
                    totalSets: 15,
                    completedSets: 8,
                    totalVolume: 12500,
                    averageRPE: 7.5,
                    duration: 2400,
                    painFlags: 0
                ),
                compact: true
            )

            // Expanded view - in progress
            QuickMetricsSummary(
                metrics: QuickMetrics(
                    totalSets: 15,
                    completedSets: 8,
                    totalVolume: 12500,
                    averageRPE: 7.5,
                    duration: 2400,
                    painFlags: 1
                ),
                compact: false
            )

            // Expanded view - completed
            QuickMetricsSummary(
                metrics: QuickMetrics(
                    totalSets: 15,
                    completedSets: 15,
                    totalVolume: 18750,
                    averageRPE: 8.2,
                    duration: 3600,
                    painFlags: 0,
                    caloriesBurned: 450
                ),
                compact: false
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
    }
}
