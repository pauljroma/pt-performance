//
//  SubscriptionDashboardView.swift
//  PTPerformance
//
//  ACP-989: Subscription Analytics Dashboard
//  Revenue dashboard for therapist/admin role showing MRR, subscribers,
//  churn rate, conversion funnel, revenue chart, and trial metrics.
//

import SwiftUI
import Charts

/// Subscription analytics dashboard for therapist and admin users
///
/// Displays key subscription metrics including MRR with trend, active subscribers,
/// churn rate with sparkline, conversion rate funnel, a 30-day revenue chart,
/// and trial conversion metrics. Uses design tokens and .modusCyan accent throughout.
///
/// ## Features
/// - MRR card with trend arrow indicator
/// - Active subscriber count
/// - Churn rate with inline sparkline
/// - Trial-to-paid conversion rate funnel visualization
/// - Interactive revenue chart (delegates to `RevenueChartView`)
/// - Recent churn event list
struct SubscriptionDashboardView: View {

    // MARK: - State

    @StateObject private var viewModel = SubscriptionDashboardViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    if viewModel.isLoading && viewModel.metrics == nil {
                        loadingState
                    } else if let metrics = viewModel.metrics {
                        // Metric cards grid
                        metricsGrid(metrics)

                        // Revenue chart
                        revenueChartSection

                        // Conversion funnel
                        conversionFunnelSection(metrics)

                        // Trial metrics
                        trialMetricsSection(metrics)

                        // Recent churn events
                        churnEventsSection
                    } else if viewModel.errorMessage != nil {
                        errorState
                    } else {
                        emptyState
                    }
                }
                .padding(Spacing.md)
            }
            .background(DesignTokens.backgroundGrouped)
            .navigationTitle("Subscription Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        Task { await viewModel.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadDashboard()
            }
        }
    }

    // MARK: - Metrics Grid

    private func metricsGrid(_ metrics: SubscriptionMetrics) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: Spacing.sm),
            GridItem(.flexible(), spacing: Spacing.sm)
        ], spacing: Spacing.sm) {
            // MRR Card
            MetricCardView(
                title: "MRR",
                value: metrics.formattedMRR,
                icon: "dollarsign.circle.fill",
                iconColor: .modusCyan,
                trend: metrics.mrrTrend,
                subtitle: "ARR: \(metrics.formattedARR)"
            )

            // Active Subscribers
            MetricCardView(
                title: "Subscribers",
                value: "\(metrics.totalSubscribers)",
                icon: "person.2.fill",
                iconColor: .modusTealAccent,
                trend: nil,
                subtitle: "ARPU: \(metrics.formattedARPU)"
            )

            // Churn Rate
            MetricCardView(
                title: "Churn Rate",
                value: metrics.formattedChurnRate,
                icon: "person.fill.xmark",
                iconColor: metrics.churnRate > 5.0 ? .red : .orange,
                trend: nil,
                subtitle: "Monthly",
                sparklineData: viewModel.churnSparklineData
            )

            // LTV
            MetricCardView(
                title: "Lifetime Value",
                value: metrics.formattedLTV,
                icon: "chart.bar.fill",
                iconColor: .modusCyan,
                trend: nil,
                subtitle: "Per subscriber"
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Subscription metrics overview")
    }

    // MARK: - Revenue Chart Section

    private var revenueChartSection: some View {
        RevenueChartView(
            dataPoints: viewModel.revenueHistory,
            selectedRange: $viewModel.selectedDateRange,
            onRangeChanged: { range in
                await viewModel.loadRevenueHistory(days: range.days)
            }
        )
    }

    // MARK: - Conversion Funnel

    private func conversionFunnelSection(_ metrics: SubscriptionMetrics) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Conversion Funnel", systemImage: "arrow.down.right.circle.fill")
                .font(.headline)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: Spacing.xs) {
                funnelRow(
                    label: "Active Trials",
                    value: metrics.activeTrials,
                    total: metrics.activeTrials + metrics.totalSubscribers,
                    color: .modusCyan.opacity(0.6)
                )

                Image(systemName: "arrow.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)

                funnelRow(
                    label: "Converted",
                    value: Int(Double(metrics.activeTrials) * metrics.conversionRate / 100.0),
                    total: metrics.activeTrials,
                    color: .modusCyan
                )

                Image(systemName: "arrow.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)

                funnelRow(
                    label: "Paid Subscribers",
                    value: metrics.totalSubscribers,
                    total: metrics.totalSubscribers,
                    color: .modusTealAccent
                )
            }

            // Conversion rate callout
            HStack {
                Spacer()
                VStack(spacing: Spacing.xxs) {
                    Text("Conversion Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(metrics.formattedConversionRate)
                        .font(.title2.bold())
                        .foregroundColor(.modusCyan)
                }
                Spacer()
            }
            .padding(.top, Spacing.xs)
        }
        .padding(Spacing.md)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.lg)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Conversion funnel: \(metrics.formattedConversionRate) conversion rate")
    }

    private func funnelRow(label: String, value: Int, total: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Spacer()

                Text("\(value)")
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
            }

            GeometryReader { geometry in
                let width = total > 0 ? CGFloat(value) / CGFloat(total) * geometry.size.width : 0
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .fill(color.opacity(0.15))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .fill(color)
                        .frame(width: max(width, 4), height: 8)
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Trial Metrics

    private func trialMetricsSection(_ metrics: SubscriptionMetrics) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Trial Metrics", systemImage: "clock.badge.checkmark")
                .font(.headline)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: Spacing.md) {
                // Active trials
                trialStatCard(
                    title: "Active Trials",
                    value: "\(metrics.activeTrials)",
                    icon: "person.badge.clock",
                    color: .modusCyan
                )

                // Conversion rate
                trialStatCard(
                    title: "Trial Conversion",
                    value: metrics.formattedConversionRate,
                    icon: "arrow.up.forward.circle",
                    color: .modusTealAccent
                )
            }

            // Trial conversion insight
            if metrics.conversionRate > 0 {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)

                    Text(trialInsightText(metrics))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .padding(Spacing.sm)
                .background(Color.yellow.opacity(0.08))
                .cornerRadius(CornerRadius.sm)
            }
        }
        .padding(Spacing.md)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private func trialStatCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2.bold())
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .background(color.opacity(0.08))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    private func trialInsightText(_ metrics: SubscriptionMetrics) -> String {
        if metrics.conversionRate >= 70 {
            return "Excellent trial conversion. Your onboarding is working well."
        } else if metrics.conversionRate >= 50 {
            return "Good conversion rate. Consider targeted engagement for trial users in days 3-5."
        } else if metrics.conversionRate >= 30 {
            return "Room for improvement. Consider extending trial duration or adding in-trial prompts."
        } else {
            return "Low conversion rate. Review trial experience and consider A/B testing pricing."
        }
    }

    // MARK: - Churn Events

    private var churnEventsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Label("Recent Churn", systemImage: "person.fill.xmark")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                if !viewModel.churnEvents.isEmpty {
                    Text("\(viewModel.churnEvents.count) events")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .accessibilityAddTraits(.isHeader)

            if viewModel.churnEvents.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: Spacing.xs) {
                        Image(systemName: "checkmark.circle")
                            .font(.title2)
                            .foregroundColor(.green)

                        Text("No recent churn events")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, Spacing.lg)
                    Spacer()
                }
            } else {
                ForEach(viewModel.churnEvents.prefix(5)) { event in
                    churnEventRow(event)

                    if event.id != viewModel.churnEvents.prefix(5).last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private func churnEventRow(_ event: ChurnEvent) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: event.reason.icon)
                .font(.body)
                .foregroundColor(.orange)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(event.reason.displayName)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                HStack(spacing: Spacing.xs) {
                    Text(event.tier.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("--")
                        .font(.caption)
                        .foregroundStyle(.quaternary)

                    Text("Subscribed \(event.formattedDuration)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text(event.date, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.reason.displayName), \(event.tier.displayName) tier, subscribed \(event.formattedDuration)")
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: Spacing.lg) {
            // Shimmer metric cards
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Spacing.sm),
                GridItem(.flexible(), spacing: Spacing.sm)
            ], spacing: Spacing.sm) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(Color(.secondarySystemBackground))
                        .frame(height: 120)
                        .pulse()
                }
            }

            // Shimmer chart
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemBackground))
                .frame(height: 300)
                .pulse()
        }
    }

    // MARK: - Error State

    private var errorState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Unable to Load Analytics")
                .font(.headline)

            if let message = viewModel.errorMessage {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("Try Again") {
                Task { await viewModel.refresh() }
            }
            .buttonStyle(.bordered)
            .tint(.modusCyan)
        }
        .padding(Spacing.xl)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Subscription Data", systemImage: "chart.bar.xaxis")
        } description: {
            Text("Subscription analytics will appear here once you have active subscribers.")
        }
    }
}

// MARK: - Metric Card View

/// Individual metric card for the dashboard grid
private struct MetricCardView: View {
    let title: String
    let value: String
    let icon: String
    let iconColor: Color
    let trend: MetricTrend?
    let subtitle: String?
    var sparklineData: [Double]?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Icon and title row
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(iconColor)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Spacer()

                // Trend arrow
                if let trend = trend {
                    Image(systemName: trend.icon)
                        .font(.caption)
                        .foregroundColor(trend.isPositive ? .green : .red)
                }
            }

            // Value
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Sparkline or subtitle
            if let sparkline = sparklineData, !sparkline.isEmpty {
                miniSparkline(data: sparkline)
                    .frame(height: 24)
            } else if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(Spacing.md)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
        .accessibilityValue(subtitle ?? "")
    }

    private func miniSparkline(data: [Double]) -> some View {
        Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Day", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(Color.orange.gradient)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 1.5))

                AreaMark(
                    x: .value("Day", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.15), Color.orange.opacity(0.02)],
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
}

// MARK: - View Model

/// View model for the Subscription Analytics Dashboard
@MainActor
final class SubscriptionDashboardViewModel: ObservableObject {

    // MARK: - Published State

    @Published var metrics: SubscriptionMetrics?
    @Published var revenueHistory: [RevenueDataPoint] = []
    @Published var churnEvents: [ChurnEvent] = []
    @Published var selectedDateRange: AnalyticsDateRange = .thirtyDays
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Churn rate sparkline data (last 14 days of churn percentages)
    @Published var churnSparklineData: [Double] = []

    // MARK: - Dependencies

    private let analyticsService = SubscriptionAnalyticsService.shared
    private let logger = DebugLogger.shared

    // MARK: - Loading

    /// Load all dashboard data
    func loadDashboard() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        logger.info("SubscriptionDashboard", "Loading dashboard data")

        // Load metrics and revenue in parallel
        async let metricsResult = analyticsService.fetchMetrics()
        async let revenueResult = analyticsService.fetchRevenueHistory(days: selectedDateRange.days)
        async let churnResult = analyticsService.fetchChurnEvents(limit: 10)

        let fetchedMetrics = await metricsResult
        let fetchedRevenue = await revenueResult
        let fetchedChurn = await churnResult

        metrics = fetchedMetrics
        revenueHistory = fetchedRevenue
        churnEvents = fetchedChurn

        // Generate churn sparkline from revenue history subscriber changes
        generateChurnSparkline()

        isLoading = false

        if fetchedMetrics.totalSubscribers == 0 && fetchedMetrics.mrr == 0 && fetchedRevenue.isEmpty {
            logger.info("SubscriptionDashboard", "Dashboard loaded with empty data")
        } else {
            logger.success("SubscriptionDashboard", "Dashboard loaded: MRR=\(fetchedMetrics.formattedMRR), \(fetchedRevenue.count) revenue points, \(fetchedChurn.count) churn events")
        }
    }

    /// Load revenue history for a specific number of days
    func loadRevenueHistory(days: Int) async {
        logger.info("SubscriptionDashboard", "Loading revenue history for \(days) days")
        revenueHistory = await analyticsService.fetchRevenueHistory(days: days)
    }

    /// Refresh all dashboard data
    func refresh() async {
        isLoading = true
        errorMessage = nil
        logger.info("SubscriptionDashboard", "Refreshing dashboard data")
        await loadDashboard()
    }

    // MARK: - Private Helpers

    /// Generate sparkline data from revenue history for churn visualization
    private func generateChurnSparkline() {
        // Use last 14 days of revenue data to create a churn sparkline approximation
        let recentPoints = Array(revenueHistory.suffix(14))
        guard recentPoints.count > 1 else {
            churnSparklineData = []
            return
        }

        var sparkline: [Double] = []
        for i in 1..<recentPoints.count {
            let prev = recentPoints[i - 1].subscribers
            let curr = recentPoints[i].subscribers
            let loss = max(0, prev - curr)
            let rate = prev > 0 ? (Double(loss) / Double(prev)) * 100.0 : 0
            sparkline.append(rate)
        }
        churnSparklineData = sparkline
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Dashboard - With Data") {
    SubscriptionDashboardView()
}
#endif
