// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  BiomarkerDetailView.swift
//  PTPerformance
//
//  Detailed view for a single biomarker
//  Shows historical trend chart, reference ranges, and AI insights
//

import SwiftUI
import Charts
import UIKit

struct BiomarkerDetailView: View {
    let biomarker: BiomarkerSummary
    let historyData: [BiomarkerTrendPoint]
    let isLoadingHistory: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var showReferenceInfo = false

    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Current Value Card
                    currentValueCard

                    // Trend Chart
                    trendChartSection

                    // Reference Ranges
                    referenceRangesCard

                    // Historical Values
                    historicalValuesSection

                    // AI Insights Placeholder
                    aiInsightsSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(biomarker.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .tint(.modusCyan)
    }

    // MARK: - Current Value Card

    private var currentValueCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Value")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(biomarker.formattedValue)
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(statusColor)

                        Text(biomarker.unit)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Status Badge
                statusBadge
            }

            // Trend indicator
            if biomarker.trend != .unknown && biomarker.historyCount > 1 {
                HStack(spacing: 8) {
                    Image(systemName: biomarker.trend.icon)
                        .font(.subheadline)

                    Text(trendDescription)
                        .font(.subheadline)

                    Spacer()

                    Text("\(biomarker.historyCount) data points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .foregroundColor(trendColor)
                .padding(.top, 4)
            }

            // Last updated
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                Text("Last updated \(biomarker.lastUpdated.formatted(date: .long, time: .omitted))")
                    .font(.caption)
                Spacer()
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private var statusBadge: some View {
        VStack(spacing: 4) {
            Image(systemName: biomarker.status.iconName)
                .font(.title)
                .foregroundColor(statusColor)

            Text(biomarker.status.displayText)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(statusColor)
        }
        .padding()
        .background(statusColor.opacity(0.15))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Status: \(biomarker.status.displayText)")
    }

    // MARK: - Trend Chart Section

    private var trendChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Trend")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)

                Spacer()

                if isLoadingHistory {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            if isLoadingHistory {
                loadingChartPlaceholder
            } else if historyData.isEmpty {
                emptyChartPlaceholder
            } else {
                BiomarkerTrendChartView(
                    dataPoints: historyData,
                    biomarkerName: biomarker.displayName,
                    height: 250
                )
            }
        }
    }

    private var loadingChartPlaceholder: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading trend data...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private var emptyChartPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("No Historical Data")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Upload more lab results to see trends over time")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Reference Ranges Card

    private var referenceRangesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                impactFeedback.impactOccurred()
                withAnimation(.easeInOut(duration: 0.25)) {
                    showReferenceInfo.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.modusCyan)
                    Text("Reference Ranges")
                        .font(.headline)
                        .foregroundColor(.modusDeepTeal)

                    Spacer()

                    Image(systemName: showReferenceInfo ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Reference Ranges")
            .accessibilityHint(showReferenceInfo ? "Tap to collapse" : "Tap to expand")

            if showReferenceInfo {
                VStack(spacing: 16) {
                    // Visual Range Indicator
                    rangeIndicator

                    Divider()

                    // Range Details
                    VStack(spacing: 8) {
                        if let optLow = biomarker.optimalLow, let optHigh = biomarker.optimalHigh {
                            RangeRow(
                                label: "Optimal",
                                range: "\(formatValue(optLow)) - \(formatValue(optHigh)) \(biomarker.unit)",
                                color: .modusTealAccent
                            )
                        }

                        if let normLow = biomarker.normalLow, let normHigh = biomarker.normalHigh {
                            RangeRow(
                                label: "Normal",
                                range: "\(formatValue(normLow)) - \(formatValue(normHigh)) \(biomarker.unit)",
                                color: .modusCyan
                            )
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private var rangeIndicator: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let minVal = biomarker.normalLow ?? 0
            let maxVal = biomarker.normalHigh ?? 100
            let range = maxVal - minVal
            let padding = range * 0.2

            let displayMin = minVal - padding
            let displayMax = maxVal + padding
            let displayRange = displayMax - displayMin

            let normalStartX = ((minVal - displayMin) / displayRange) * width
            let normalEndX = ((maxVal - displayMin) / displayRange) * width
            let valueX = ((biomarker.currentValue - displayMin) / displayRange) * width

            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemRed).opacity(0.2))
                    .frame(height: 8)

                // Normal range
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.modusCyan.opacity(0.3))
                    .frame(width: max(0, normalEndX - normalStartX), height: 8)
                    .offset(x: normalStartX)

                // Current value marker
                Circle()
                    .fill(statusColor)
                    .frame(width: 16, height: 16)
                    .offset(x: min(max(valueX - 8, 0), width - 16))
                    .shadow(color: statusColor.opacity(0.5), radius: 4, x: 0, y: 2)
            }
        }
        .frame(height: 16)
        .accessibilityHidden(true)
    }

    // MARK: - Historical Values Section

    private var historicalValuesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Historical Values")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)

            if historyData.isEmpty && !isLoadingHistory {
                Text("No historical data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(historyData.reversed().prefix(10)) { point in
                    HistoricalValueRow(point: point, statusColor: colorForStatus(point.status))
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - AI Insights Section

    private var aiInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.modusCyan)
                Text("AI Insights")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)

                Spacer()

                Text("Coming Soon")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.modusCyan.opacity(0.2))
                    .foregroundColor(.modusCyan)
                    .cornerRadius(CornerRadius.sm)
            }

            Text("Personalized insights about your \(biomarker.displayName) levels, including recommendations based on your health goals and training data.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.modusTealAccent)
                Text("AI-powered analysis will help you understand what your biomarker levels mean for your performance and health.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.modusLightTeal)
            .cornerRadius(CornerRadius.md)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Helper Properties

    private var statusColor: Color {
        biomarker.status.statusColor
    }

    private var trendColor: Color {
        switch biomarker.trend {
        case .increasing: return .orange
        case .decreasing: return .blue
        case .stable: return .modusTealAccent
        case .unknown: return .secondary
        }
    }

    private var trendDescription: String {
        switch biomarker.trend {
        case .increasing: return "Trending upward"
        case .decreasing: return "Trending downward"
        case .stable: return "Stable"
        case .unknown: return ""
        }
    }

    private func formatValue(_ value: Double) -> String {
        if value >= 100 {
            return String(format: "%.0f", value)
        } else if value >= 10 {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }

    private func colorForStatus(_ status: BiomarkerStatus) -> Color {
        status.statusColor
    }
}

// MARK: - Range Row

struct RangeRow: View {
    let label: String
    let range: String
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(range)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) range: \(range)")
    }
}

// MARK: - Historical Value Row

struct HistoricalValueRow: View {
    let point: BiomarkerTrendPoint
    let statusColor: Color

    var body: some View {
        HStack {
            Text(point.date.formatted(date: .abbreviated, time: .omitted))
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            HStack(spacing: 8) {
                Text(formatValue(point.value))
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(point.unit)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Image(systemName: point.status.iconName)
                    .font(.caption)
                    .foregroundColor(statusColor)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(point.date.formatted(date: .long, time: .omitted)), \(formatValue(point.value)) \(point.unit), \(point.status.displayText)")
    }

    private func formatValue(_ value: Double) -> String {
        if value >= 100 {
            return String(format: "%.0f", value)
        } else if value >= 10 {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct BiomarkerDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleBiomarker = BiomarkerSummary(
            name: "vitamin_d",
            displayName: "Vitamin D",
            category: .vitamins,
            currentValue: 45.5,
            unit: "ng/mL",
            status: .normal,
            trend: .increasing,
            lastUpdated: Date(),
            historyCount: 5,
            optimalLow: 50,
            optimalHigh: 70,
            normalLow: 30,
            normalHigh: 100
        )

        let sampleHistory = (0..<5).map { week in
            BiomarkerTrendPoint(
                date: Calendar.current.date(byAdding: .month, value: -week, to: Date())!,
                value: Double.random(in: 35...55),
                biomarkerType: "vitamin_d",
                unit: "ng/mL",
                optimalLow: 50,
                optimalHigh: 70,
                normalLow: 30,
                normalHigh: 100
            )
        }.reversed()

        return BiomarkerDetailView(
            biomarker: sampleBiomarker,
            historyData: Array(sampleHistory),
            isLoadingHistory: false
        )
    }
}
#endif
