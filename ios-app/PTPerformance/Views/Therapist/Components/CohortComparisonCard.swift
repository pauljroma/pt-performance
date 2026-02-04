//
//  CohortComparisonCard.swift
//  PTPerformance
//
//  Card component showing patient vs cohort comparison
//  Displays metric, cohort average, and percentile ranking with visual indicators
//

import SwiftUI

// MARK: - Cohort Comparison Card

/// Card component comparing a patient's metric to cohort average
struct CohortComparisonCard: View {
    let patientName: String
    let patientValue: Double
    let cohortAverage: Double
    let percentile: Int
    let metricName: String
    let unit: String
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Computed Properties

    private var isAboveAverage: Bool {
        patientValue >= cohortAverage
    }

    private var delta: Double {
        patientValue - cohortAverage
    }

    private var deltaPercentage: Double {
        guard cohortAverage > 0 else { return 0 }
        return (delta / cohortAverage) * 100
    }

    private var statusColor: Color {
        if percentile >= 75 {
            return .green
        } else if percentile >= 50 {
            return .blue
        } else if percentile >= 25 {
            return .orange
        } else {
            return .red
        }
    }

    private var statusIcon: String {
        if percentile >= 75 {
            return "arrow.up.circle.fill"
        } else if percentile >= 50 {
            return "equal.circle.fill"
        } else if percentile >= 25 {
            return "arrow.down.circle.fill"
        } else {
            return "exclamationmark.triangle.fill"
        }
    }

    private var statusLabel: String {
        if percentile >= 75 {
            return "Above Average"
        } else if percentile >= 50 {
            return "Average"
        } else if percentile >= 25 {
            return "Below Average"
        } else {
            return "Needs Attention"
        }
    }

    // MARK: - Body

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with patient name and status
                headerSection

                // Metric comparison
                metricSection

                // Percentile bar
                percentileSection

                // Delta indicator
                deltaSection
            }
            .padding(16)
            .background(cardBackground)
            .cornerRadius(CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(statusColor.opacity(0.3), lineWidth: 1)
            )
            .adaptiveShadow(Shadow.medium)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap to view patient details")
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(patientName)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(metricName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status badge
            HStack(spacing: 4) {
                Image(systemName: statusIcon)
                    .font(.caption)

                Text(statusLabel)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.15))
            .foregroundColor(statusColor)
            .cornerRadius(CornerRadius.sm)
        }
    }

    private var metricSection: some View {
        HStack(alignment: .bottom, spacing: 16) {
            // Patient value
            VStack(alignment: .leading, spacing: 2) {
                Text("Patient")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: "%.1f", patientValue))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(statusColor)

                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // VS indicator
            Text("vs")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)

            Spacer()

            // Cohort average
            VStack(alignment: .trailing, spacing: 2) {
                Text("Cohort Avg")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: "%.1f", cohortAverage))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary.opacity(0.7))

                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var percentileSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Percentile Rank")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(percentile)th")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(statusColor)
            }

            // Percentile progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [statusColor.opacity(0.8), statusColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(percentile) / 100)
                }
            }
            .frame(height: 8)
        }
    }

    private var deltaSection: some View {
        HStack {
            Image(systemName: isAboveAverage ? "arrow.up.right" : "arrow.down.right")
                .font(.caption)
                .foregroundColor(isAboveAverage ? .green : .red)

            Text(isAboveAverage ? "+" : "")
                .font(.caption)
                .foregroundColor(isAboveAverage ? .green : .red)
            +
            Text(String(format: "%.1f%@", delta, unit))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isAboveAverage ? .green : .red)

            Text("(\(String(format: "%+.1f%%", deltaPercentage)))")
                .font(.caption2)
                .foregroundColor(.secondary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 4)
    }

    private var cardBackground: Color {
        Color(.systemBackground)
    }

    private var accessibilityDescription: String {
        "\(patientName), \(metricName): \(String(format: "%.1f", patientValue))\(unit), " +
        "cohort average: \(String(format: "%.1f", cohortAverage))\(unit), " +
        "\(percentile)th percentile, \(statusLabel)"
    }
}

// MARK: - Mini Comparison Card

/// Compact card for comparison metrics in a grid
struct MiniComparisonCard: View {
    let title: String
    let patientValue: Double
    let cohortValue: Double
    let unit: String
    let isHigherBetter: Bool

    private var isAboveAverage: Bool {
        isHigherBetter ? patientValue >= cohortValue : patientValue <= cohortValue
    }

    private var statusColor: Color {
        isAboveAverage ? .green : .orange
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(alignment: .bottom, spacing: 4) {
                Text(String(format: "%.1f", patientValue))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(statusColor)

                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 2)
            }

            HStack(spacing: 4) {
                Image(systemName: isAboveAverage ? "arrow.up" : "arrow.down")
                    .font(.caption2)

                Text("Avg: \(String(format: "%.1f", cohortValue))")
                    .font(.caption2)
            }
            .foregroundColor(statusColor)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Comparison Summary Card

/// Summary card showing overall patient vs cohort comparison
struct ComparisonSummaryCard: View {
    let comparison: PatientComparison
    let benchmarks: CohortBenchmarks
    let onViewDetails: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(comparison.patientName)
                        .font(.headline)

                    Text("vs Cohort Benchmarks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Overall score badge
                overallScoreBadge
            }

            // Metrics grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MiniComparisonCard(
                    title: "Adherence",
                    patientValue: comparison.adherence,
                    cohortValue: benchmarks.averageAdherence,
                    unit: "%",
                    isHigherBetter: true
                )

                MiniComparisonCard(
                    title: "Pain Reduction",
                    patientValue: comparison.painReduction,
                    cohortValue: benchmarks.averagePainReduction,
                    unit: "%",
                    isHigherBetter: true
                )

                MiniComparisonCard(
                    title: "Strength Gains",
                    patientValue: comparison.strengthGains,
                    cohortValue: benchmarks.averageStrengthGains,
                    unit: "%",
                    isHigherBetter: true
                )

                MiniComparisonCard(
                    title: "Sessions/Week",
                    patientValue: comparison.sessionsPerWeek,
                    cohortValue: benchmarks.averageSessionsPerWeek,
                    unit: "",
                    isHigherBetter: true
                )
            }

            // View details button
            Button(action: {
                HapticFeedback.light()
                onViewDetails()
            }) {
                HStack {
                    Text("View Full Comparison")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Image(systemName: "arrow.right")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(CornerRadius.md)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.medium)
    }

    private var overallScoreBadge: some View {
        VStack(spacing: 2) {
            Text("\(comparison.overallPercentile)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(comparison.comparisonStatus == .aboveAverage ? .green :
                               comparison.comparisonStatus == .average ? .blue : .orange)

            Text("percentile")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Preview

#if DEBUG
struct CohortComparisonCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Above average
                CohortComparisonCard(
                    patientName: "John Brebbia",
                    patientValue: 92.0,
                    cohortAverage: 78.5,
                    percentile: 85,
                    metricName: "Adherence Rate",
                    unit: "%",
                    onTap: {}
                )

                // Average
                CohortComparisonCard(
                    patientName: "Sarah Johnson",
                    patientValue: 75.0,
                    cohortAverage: 78.5,
                    percentile: 48,
                    metricName: "Adherence Rate",
                    unit: "%",
                    onTap: {}
                )

                // Below average
                CohortComparisonCard(
                    patientName: "Mike Thompson",
                    patientValue: 45.0,
                    cohortAverage: 78.5,
                    percentile: 15,
                    metricName: "Adherence Rate",
                    unit: "%",
                    onTap: {}
                )

                // Summary card
                ComparisonSummaryCard(
                    comparison: PatientComparison.sample,
                    benchmarks: CohortBenchmarks.sample,
                    onViewDetails: {}
                )
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
