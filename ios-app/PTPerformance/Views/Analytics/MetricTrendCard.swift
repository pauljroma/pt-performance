//
//  MetricTrendCard.swift
//  PTPerformance
//
//  Created for M8 - Historical Trend Analysis Feature
//  Compact trend display card with sparkline chart
//

import SwiftUI
import Charts

/// Compact card showing a metric trend with sparkline
struct MetricTrendCard: View {

    // MARK: - Properties

    let metricType: TrendMetricType
    let currentValue: Double
    let previousValue: Double
    let dataPoints: [AnalyticsTrendDataPoint]
    let onTap: () -> Void

    // MARK: - Computed Properties

    private var percentChange: Double {
        guard previousValue != 0 else { return 0 }
        return ((currentValue - previousValue) / abs(previousValue)) * 100
    }

    private var isPositiveChange: Bool {
        if metricType.higherIsBetter {
            return percentChange >= 0
        } else {
            return percentChange <= 0
        }
    }

    private var trendArrow: String {
        if abs(percentChange) < 1 {
            return "arrow.right"
        }
        return percentChange > 0 ? "arrow.up.right" : "arrow.down.right"
    }

    private var trendColor: Color {
        if abs(percentChange) < 1 {
            return .gray
        }
        return isPositiveChange ? .green : .red
    }

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: metricType.icon)
                        .foregroundColor(metricType.color)
                        .font(.system(size: 16))

                    Text(metricType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // Sparkline chart
                if !dataPoints.isEmpty {
                    sparklineChart
                        .frame(height: 40)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 40)
                        .cornerRadius(CornerRadius.xs)
                }

                // Value and change
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formattedValue)
                            .font(.title3.bold())
                            .foregroundColor(.primary)

                        Text(metricType.unit)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Trend indicator
                    HStack(spacing: 4) {
                        Image(systemName: trendArrow)
                            .font(.caption)
                            .foregroundColor(trendColor)

                        Text(formattedPercentChange)
                            .font(.caption.bold())
                            .foregroundColor(trendColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(trendColor.opacity(0.1))
                    .cornerRadius(CornerRadius.sm)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(CornerRadius.lg)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(metricType.displayName): \(formattedValue) \(metricType.unit)")
        .accessibilityValue("\(formattedPercentChange) change")
        .accessibilityHint("Double tap to view detailed trend")
    }

    // MARK: - Sparkline Chart

    private var sparklineChart: some View {
        Chart {
            ForEach(dataPoints) { point in
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(metricType.color.gradient)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2))

                AreaMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            metricType.color.opacity(0.2),
                            metricType.color.opacity(0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
    }

    // MARK: - Formatting

    private var formattedValue: String {
        switch metricType {
        case .sessionAdherence, .recoveryScore, .mobilityScore:
            return String(format: "%.0f", currentValue)
        case .painLevel:
            return String(format: "%.1f", currentValue)
        case .sleepQuality:
            return String(format: "%.1f", currentValue)
        case .workloadVolume:
            if currentValue >= 1000 {
                return String(format: "%.1fK", currentValue / 1000)
            }
            return String(format: "%.0f", currentValue)
        case .strengthProgress:
            return String(format: "%.0f", currentValue)
        }
    }

    private var formattedPercentChange: String {
        let sign = percentChange >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, percentChange)
    }
}

// MARK: - Metric Trend Card Row

/// A row of metric trend cards for dashboard display
struct MetricTrendCardRow: View {

    // MARK: - Properties

    let analyses: [TrendAnalysis]
    let onCardTap: (TrendMetricType) -> Void

    // MARK: - Body

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(analyses) { analysis in
                    MetricTrendCard(
                        metricType: analysis.metricType,
                        currentValue: analysis.summary.endValue,
                        previousValue: analysis.summary.startValue,
                        dataPoints: Array(analysis.dataPoints.suffix(14)),
                        onTap: {
                            onCardTap(analysis.metricType)
                        }
                    )
                    .frame(width: 180)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Quick Trend Overview

/// Quick overview of all trends for dashboard
struct QuickTrendOverview: View {

    // MARK: - Properties

    let patientId: UUID
    let onViewAllTapped: () -> Void

    // MARK: - State

    @StateObject private var viewModel = QuickTrendViewModel()

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("Performance Trends", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.headline)

                Spacer()

                Button("View All") {
                    onViewAllTapped()
                }
                .font(.subheadline)
            }
            .padding(.horizontal)

            if viewModel.isLoading {
                loadingView
            } else if viewModel.analyses.isEmpty {
                emptyState
            } else {
                MetricTrendCardRow(
                    analyses: viewModel.analyses,
                    onCardTap: { _ in
                        onViewAllTapped()
                    }
                )
            }
        }
        .task {
            await viewModel.loadQuickAnalyses(for: patientId)
        }
    }

    private var loadingView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 180, height: 140)
                        .shimmering()
                }
            }
            .padding(.horizontal)
        }
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "chart.line.downtrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(.secondary)

                Text("Complete sessions to see trends")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 30)
            Spacer()
        }
    }
}

// MARK: - Quick Trend ViewModel

@MainActor
class QuickTrendViewModel: ObservableObject {

    @Published var analyses: [TrendAnalysis] = []
    @Published var isLoading = false
    @Published var error: Error?

    private let service = TrendAnalysisService.shared

    func loadQuickAnalyses(for patientId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        let quickMetrics: [TrendMetricType] = [
            .sessionAdherence,
            .painLevel,
            .workloadVolume
        ]

        var loadedAnalyses: [TrendAnalysis] = []

        for metric in quickMetrics {
            do {
                let analysis = try await service.analyzeTrend(
                    patientId: patientId,
                    metric: metric,
                    range: .thirtyDays
                )
                loadedAnalyses.append(analysis)
            } catch {
                // Skip metrics without data
                continue
            }
        }

        analyses = loadedAnalyses
    }
}

// MARK: - Shimmer Effect

private struct MetricTrendShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(0.3),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + phase * geometry.size.width * 2)
                    .animation(
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                        value: phase
                    )
                }
            )
            .mask(content)
            .onAppear {
                phase = 1
            }
    }
}

private extension View {
    func shimmering() -> some View {
        modifier(MetricTrendShimmerModifier())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        MetricTrendCard(
            metricType: .sessionAdherence,
            currentValue: 85,
            previousValue: 72,
            dataPoints: (0..<14).map { day in
                AnalyticsTrendDataPoint(
                    date: Calendar.current.date(byAdding: .day, value: -13 + day, to: Date())!,
                    value: 70 + Double.random(in: -10...20),
                    movingAverage: nil
                )
            },
            onTap: {}
        )
        .frame(width: 180)

        MetricTrendCard(
            metricType: .painLevel,
            currentValue: 3.2,
            previousValue: 4.5,
            dataPoints: (0..<14).map { day in
                AnalyticsTrendDataPoint(
                    date: Calendar.current.date(byAdding: .day, value: -13 + day, to: Date())!,
                    value: 4.5 - Double(day) * 0.1 + Double.random(in: -0.5...0.5),
                    movingAverage: nil
                )
            },
            onTap: {}
        )
        .frame(width: 180)
    }
    .padding()
}
