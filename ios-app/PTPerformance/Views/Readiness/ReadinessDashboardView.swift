import SwiftUI
import Charts

/// Dashboard view displaying readiness trends and statistics
/// BUILD 116 - Agent 17: ReadinessDashboardView
///
/// Provides comprehensive readiness analytics with:
/// - 7-day and 30-day trend charts
/// - Current score with category indicator
/// - Statistical summaries (min, max, average)
/// - Trend direction indicators
/// - Daily check-in timeline
struct ReadinessDashboardView: View {
    // MARK: - Properties

    let patientId: UUID

    @StateObject private var viewModel: ReadinessDashboardViewModel
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Initialization

    init(patientId: UUID) {
        self.patientId = patientId
        _viewModel = StateObject(wrappedValue: ReadinessDashboardViewModel(patientId: patientId))
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isLoading && !viewModel.hasData {
                    loadingView
                } else if viewModel.hasData {
                    contentView
                } else {
                    emptyStateView
                }
            }
            .padding()
        }
        .navigationTitle("Readiness Trends")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            HapticFeedback.light()
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadTrendData()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        VStack(spacing: 20) {
            // Current score hero card
            currentScoreCard

            // Period selector
            periodSelector

            // Trend chart
            trendChart

            // Statistics cards
            statisticsRow

            // Daily timeline
            dailyTimeline
        }
    }

    // MARK: - Current Score Card

    private var currentScoreCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Readiness")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(viewModel.currentScoreText)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(viewModel.categoryColor)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Image(systemName: viewModel.trendDirection.icon)
                                    .font(.caption)
                                Text(viewModel.trendDirection.description)
                                    .font(.caption.weight(.medium))
                            }
                            .foregroundColor(viewModel.trendDirection.color)

                            Text(viewModel.currentCategory?.displayName ?? "--")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                // Category badge
                if let category = viewModel.currentCategory {
                    VStack(spacing: 4) {
                        Circle()
                            .fill(category.color)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(category.displayName.prefix(1))
                                    .font(.title.bold())
                                    .foregroundColor(.white)
                            )

                        Text(category.scoreRange)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Recommendation
            if !viewModel.currentRecommendation.isEmpty {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text(viewModel.currentRecommendation)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.yellow.opacity(0.1))
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .adaptiveShadow(Shadow.medium)
        )
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        Picker("Period", selection: $viewModel.selectedPeriod) {
            ForEach(ReadinessDashboardViewModel.TrendPeriod.allCases) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: viewModel.selectedPeriod) { _, newValue in
            Task {
                await viewModel.changePeriod(newValue)
            }
        }
    }

    // MARK: - Trend Chart

    private var trendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Readiness Trend")
                .font(.headline)

            Chart(viewModel.chartData) { dataPoint in
                // Area gradient fill
                AreaMark(
                    x: .value("Date", dataPoint.date, unit: .day),
                    y: .value("Score", dataPoint.score)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            dataPoint.category.color.opacity(0.3),
                            dataPoint.category.color.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Line
                LineMark(
                    x: .value("Date", dataPoint.date, unit: .day),
                    y: .value("Score", dataPoint.score)
                )
                .foregroundStyle(dataPoint.category.color)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)

                // Point markers
                PointMark(
                    x: .value("Date", dataPoint.date, unit: .day),
                    y: .value("Score", dataPoint.score)
                )
                .foregroundStyle(dataPoint.category.color)
                .symbolSize(60)
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .font(.caption)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: viewModel.selectedPeriod == .week ? 1 : 5)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .chartPlotStyle { plotArea in
                plotArea
                    .background(
                        Color(.separator)
                    )
                    .cornerRadius(CornerRadius.sm)
            }
            // Reference lines for categories
            .chartOverlay { _ in
                GeometryReader { geometry in
                    // Elite threshold (90)
                    Rectangle()
                        .fill(Color.green.opacity(0.1))
                        .frame(height: 1)
                        .position(y: yPosition(for: 90, in: geometry))

                    // High threshold (75)
                    Rectangle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(height: 1)
                        .position(y: yPosition(for: 75, in: geometry))

                    // Moderate threshold (60)
                    Rectangle()
                        .fill(Color.yellow.opacity(0.1))
                        .frame(height: 1)
                        .position(y: yPosition(for: 60, in: geometry))

                    // Low threshold (45)
                    Rectangle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(height: 1)
                        .position(y: yPosition(for: 45, in: geometry))
                }
            }
            .frame(height: 250)
            .accessibilityLabel("Readiness trend chart")
            .accessibilityValue("Shows \(viewModel.chartData.count) data points over \(viewModel.selectedPeriod.rawValue)")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .adaptiveShadow(Shadow.medium)
        )
    }

    // Helper to calculate Y position for reference lines
    private func yPosition(for score: Double, in geometry: GeometryProxy) -> CGFloat {
        let normalized = (100 - score) / 100.0
        return geometry.size.height * normalized
    }

    // MARK: - Statistics Row

    private var statisticsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                statisticCard(
                    title: "Average",
                    value: viewModel.averageScoreText,
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                )

                statisticCard(
                    title: "Minimum",
                    value: viewModel.minScoreText,
                    icon: "arrow.down.circle.fill",
                    color: .orange
                )

                statisticCard(
                    title: "Maximum",
                    value: viewModel.maxScoreText,
                    icon: "arrow.up.circle.fill",
                    color: .green
                )

                statisticCard(
                    title: "Check-ins",
                    value: "\(viewModel.trendData.count)",
                    icon: "checkmark.circle.fill",
                    color: .purple
                )
            }
            .padding(.horizontal)
        }
    }

    private func statisticCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(.primary)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(width: 140, height: 100)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
                .adaptiveShadow(Shadow.subtle)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: - Daily Timeline

    private var dailyTimeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Check-ins")
                .font(.headline)
                .padding(.horizontal)

            LazyVStack(spacing: 12) {
                ForEach(viewModel.trendData.prefix(10)) { entry in
                    dailyCheckInRow(entry: entry)
                }
            }
        }
    }

    private func dailyCheckInRow(entry: DailyReadiness) -> some View {
        HStack(spacing: 16) {
            // Date indicator
            VStack(spacing: 2) {
                Text(entry.date, format: .dateTime.day())
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                Text(entry.date, format: .dateTime.month(.abbreviated))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 50)

            // Score circle
            Circle()
                .fill(entry.scoreColor)
                .frame(width: 50, height: 50)
                .overlay(
                    Text(entry.scoreText)
                        .font(.system(.body, design: .rounded, weight: .bold))
                        .foregroundColor(.white)
                )

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.category?.displayName ?? "No Score")
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 12) {
                    Label("\(String(format: "%.1f", entry.sleepHours ?? 0))h", systemImage: "bed.double.fill")
                    Label("E:\(entry.energyLevel ?? 0)", systemImage: "bolt.fill")
                    Label("S:\(entry.sorenessLevel ?? 0)", systemImage: "figure.walk")
                }
                .font(.caption)
                .foregroundColor(.secondary)

                if let notes = entry.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Indicator
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
                .adaptiveShadow(Shadow.subtle)
        )
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Check-in for \(entry.formattedDate), score \(entry.scoreText), \(entry.category?.displayName ?? "no category")")
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading readiness data...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        EmptyStateView(
            title: "No Readiness Data",
            message: "Complete daily check-ins to track your readiness levels. View trends, identify patterns, and optimize your training based on how you feel.",
            icon: "heart.text.square",
            iconColor: .green,
            action: nil
        )
        .overlay(alignment: .bottom) {
            NavigationLink {
                ReadinessCheckInView(patientId: patientId)
            } label: {
                Label("Complete Check-in", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                    .background(Color.green)
                    .cornerRadius(CornerRadius.md)
            }
            .padding(.bottom, 60)
        }
        .padding(.top, 40)
    }
}

// MARK: - Previews

#Preview("With Data") {
    NavigationStack {
        ReadinessDashboardView(patientId: UUID())
    }
}

#Preview("Loading") {
    NavigationStack {
        ReadinessDashboardView(patientId: UUID())
    }
}

#Preview("Empty State") {
    NavigationStack {
        ReadinessDashboardView(patientId: UUID())
    }
}

#Preview("7 Days") {
    NavigationStack {
        ReadinessDashboardView(patientId: UUID())
    }
}

#Preview("30 Days") {
    let view = ReadinessDashboardView(patientId: UUID())

    return NavigationStack {
        view
            .onAppear {
                // Note: In real preview, would set selectedPeriod to .month
            }
    }
}

// MARK: - Accessibility Support

extension ReadinessDashboardView {
    /// Accessibility summary of dashboard data
    var accessibilitySummary: String {
        guard viewModel.hasData else {
            return "No readiness data available"
        }

        var summary = "Readiness dashboard. "

        if let current = viewModel.currentScore, let category = viewModel.currentCategory {
            summary += "Current score: \(String(format: "%.1f", current)), \(category.displayName). "
        }

        summary += "Trend is \(viewModel.trendDirection.description). "

        if let avg = viewModel.averageScore {
            summary += "Average score: \(String(format: "%.1f", avg)). "
        }

        summary += "Showing \(viewModel.trendData.count) check-ins over \(viewModel.selectedPeriod.rawValue)."

        return summary
    }
}
