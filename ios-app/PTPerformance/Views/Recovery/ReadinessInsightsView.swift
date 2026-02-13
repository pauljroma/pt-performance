import SwiftUI
import Charts

/// View showing weekly readiness trend chart, correlations, patterns, and periodization recommendations
/// Part of Recovery Intelligence feature
struct ReadinessInsightsView: View {

    // MARK: - Properties

    let patientId: UUID

    @StateObject private var viewModel: ReadinessIntelligenceViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedInsightTab: InsightTab = .trends

    enum InsightTab: String, CaseIterable {
        case trends = "Trends"
        case patterns = "Patterns"
        case correlations = "Correlations"
        case periodization = "Training"
    }

    // MARK: - Initialization

    init(patientId: UUID) {
        self.patientId = patientId
        _viewModel = StateObject(wrappedValue: ReadinessIntelligenceViewModel(patientId: patientId))
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary header
                summaryHeader

                // Tab picker
                insightTabPicker

                // Tab content
                insightTabContent
            }
            .padding()
        }
        .navigationTitle("Readiness Insights")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            HapticFeedback.light()
            await viewModel.refresh()
            await viewModel.loadReadinessAnalysis()
        }
        .task {
            await viewModel.loadData()
            await viewModel.loadReadinessAnalysis()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        HStack(spacing: 16) {
            // Average readiness
            VStack(alignment: .leading, spacing: 4) {
                Text("7-Day Average")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let avg = viewModel.weeklyAverageReadiness {
                    Text(String(format: "%.0f%%", avg))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(colorForScore(avg))
                } else {
                    Text("--")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            // Trend indicator
            VStack(alignment: .trailing, spacing: 4) {
                Text("Trend")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: viewModel.trendDirectionIcon)
                        .foregroundColor(viewModel.trendDirectionColor)

                    Text(viewModel.trendDirectionText)
                        .font(.headline)
                        .foregroundColor(viewModel.trendDirectionColor)
                }
            }

            // Volatility indicator
            if let analysis = viewModel.readinessAnalysis {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Variability")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(volatilityText(analysis.volatility))
                        .font(.headline)
                        .foregroundColor(volatilityColor(analysis.volatility))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .adaptiveShadow(Shadow.medium)
        )
    }

    // MARK: - Tab Picker

    private var insightTabPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(InsightTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedInsightTab = tab
                        }
                    } label: {
                        Text(tab.rawValue)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedInsightTab == tab
                                        ? Color.blue
                                        : Color(.tertiarySystemGroupedBackground)
                                    )
                            )
                            .foregroundColor(selectedInsightTab == tab ? .white : .primary)
                    }
                }
            }
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var insightTabContent: some View {
        switch selectedInsightTab {
        case .trends:
            trendsTab
        case .patterns:
            patternsTab
        case .correlations:
            correlationsTab
        case .periodization:
            periodizationTab
        }
    }

    // MARK: - Trends Tab

    private var trendsTab: some View {
        VStack(spacing: 20) {
            // Readiness trend chart
            if !viewModel.weeklyReadinessData.isEmpty {
                ReadinessTrendChart(data: viewModel.weeklyReadinessData)
            }

            // HRV trend chart
            if !viewModel.hrvTrend.isEmpty {
                HRVTrendChart(data: viewModel.hrvTrend)
            }

            // Sleep trend chart
            if !viewModel.sleepTrend.isEmpty {
                SleepTrendChart(data: viewModel.sleepTrend)
            }

            // Empty state if no data
            if viewModel.weeklyReadinessData.isEmpty && viewModel.hrvTrend.isEmpty && viewModel.sleepTrend.isEmpty {
                InsightEmptyState(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "No Trend Data",
                    message: "Complete daily readiness check-ins and sync your health data to see trends."
                )
            }
        }
    }

    // MARK: - Patterns Tab

    private var patternsTab: some View {
        VStack(spacing: 16) {
            // Day patterns
            if let dayPattern = viewModel.dayPatternText {
                PatternCard(
                    icon: "calendar",
                    title: "Weekly Pattern",
                    description: dayPattern,
                    color: .blue
                )
            }

            // Detected patterns
            if !viewModel.patternInsights.isEmpty {
                ForEach(viewModel.patternInsights, id: \.name) { pattern in
                    PatternCard(
                        icon: patternIcon(for: pattern.name),
                        title: pattern.name,
                        description: pattern.description,
                        recommendation: pattern.recommendation,
                        color: patternColor(for: pattern.name)
                    )
                }
            }

            // Empty state
            if viewModel.dayPatternText == nil && viewModel.patternInsights.isEmpty {
                InsightEmptyState(
                    icon: "waveform.path.ecg",
                    title: "No Patterns Detected",
                    message: "Continue tracking your readiness. Patterns typically emerge after 2-3 weeks of data."
                )
            }
        }
    }

    // MARK: - Correlations Tab

    private var correlationsTab: some View {
        VStack(spacing: 16) {
            if !viewModel.correlationInsights.isEmpty {
                ForEach(viewModel.correlationInsights, id: \.factor) { correlation in
                    CorrelationCard(
                        factor: correlation.factor,
                        description: correlation.description,
                        impact: correlation.impact
                    )
                }
            } else {
                InsightEmptyState(
                    icon: "link",
                    title: "No Correlations Found",
                    message: "Complete more check-ins with varied metrics to discover what affects your readiness."
                )
            }

            // Explanation card
            CorrelationExplanationCard()
        }
    }

    // MARK: - Periodization Tab

    private var periodizationTab: some View {
        VStack(spacing: 20) {
            // Current recommendation
            PeriodizationRecommendationCard(
                recommendation: viewModel.periodizationRecommendation,
                trend: viewModel.readinessAnalysis?.trend ?? .stable
            )

            // Training optimization tips
            TrainingOptimizationCard(analysis: viewModel.readinessAnalysis)

            // Forecasted training windows
            if !viewModel.readinessForecasts.isEmpty {
                TrainingWindowsCard(forecasts: viewModel.readinessForecasts)
            }
        }
    }

    // MARK: - Helper Methods

    private func colorForScore(_ score: Double) -> Color {
        if score >= 80 { return .green }
        if score >= 60 { return .yellow }
        if score >= 40 { return .orange }
        return .red
    }

    private func volatilityText(_ volatility: Double) -> String {
        if volatility < 10 { return "Low" }
        if volatility < 20 { return "Moderate" }
        return "High"
    }

    private func volatilityColor(_ volatility: Double) -> Color {
        if volatility < 10 { return .green }
        if volatility < 20 { return .yellow }
        return .orange
    }

    private func patternIcon(for name: String) -> String {
        switch name.lowercased() {
        case let n where n.contains("weekend"): return "sun.max"
        case let n where n.contains("weekday"): return "briefcase"
        case let n where n.contains("variability"): return "waveform.path.ecg"
        case let n where n.contains("fatigue"): return "battery.25"
        default: return "chart.bar"
        }
    }

    private func patternColor(for name: String) -> Color {
        switch name.lowercased() {
        case let n where n.contains("weekend"): return .orange
        case let n where n.contains("weekday"): return .blue
        case let n where n.contains("variability"): return .purple
        case let n where n.contains("fatigue"): return .red
        default: return .gray
        }
    }
}

// MARK: - Readiness Trend Chart

struct ReadinessTrendChart: View {
    let data: [ReadinessIntelligenceViewModel.DailyReadinessDataPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                Text("Readiness Trend")
                    .font(.headline)
                Spacer()
                Text("Last 7 Days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Chart(data) { point in
                // Area fill
                AreaMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Score", point.score)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [point.band.color.opacity(0.3), point.band.color.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Line
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Score", point.score)
                )
                .foregroundStyle(point.band.color)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                .interpolationMethod(.catmullRom)

                // Points
                PointMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Score", point.score)
                )
                .foregroundStyle(point.band.color)
                .symbolSize(40)
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 1)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .frame(height: 180)

            // Band legend
            HStack(spacing: 16) {
                ReadinessLegendItem(color: .green, label: "Green (80+)")
                ReadinessLegendItem(color: .yellow, label: "Yellow (60-79)")
                ReadinessLegendItem(color: .orange, label: "Orange (40-59)")
                ReadinessLegendItem(color: .red, label: "Red (<40)")
            }
            .font(.caption2)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - HRV Trend Chart

struct HRVTrendChart: View {
    let data: [ReadinessIntelligenceViewModel.HRVDataPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("HRV Trend")
                    .font(.headline)
                Spacer()

                if let baseline = data.first?.baseline {
                    Text("Baseline: \(String(format: "%.0f", baseline)) ms")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Chart {
                // Baseline line if available
                if let baseline = data.first?.baseline {
                    RuleMark(y: .value("Baseline", baseline))
                        .foregroundStyle(.red.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                }

                ForEach(data) { point in
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("HRV", point.value)
                    )
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("HRV", point.value)
                    )
                    .foregroundStyle(.red)
                    .symbolSize(30)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 1)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .frame(height: 150)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Sleep Trend Chart

struct SleepTrendChart: View {
    let data: [ReadinessIntelligenceViewModel.SleepDataPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "moon.fill")
                    .foregroundColor(.indigo)
                Text("Sleep Trend")
                    .font(.headline)
                Spacer()
            }

            Chart(data) { point in
                BarMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Hours", point.hours)
                )
                .foregroundStyle(
                    point.hours >= 7 ? Color.indigo :
                    point.hours >= 6 ? Color.yellow : Color.orange
                )
                .cornerRadius(CornerRadius.xs)
            }
            .chartYScale(domain: 0...12)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 4, 8, 12]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)h")
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 1)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .frame(height: 150)

            // Target line note
            HStack {
                Rectangle()
                    .fill(Color.green)
                    .frame(width: 20, height: 2)
                Text("7-9 hours recommended")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Supporting Views

private struct ReadinessLegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(.secondary)
        }
    }
}

struct PatternCard: View {
    let icon: String
    let title: String
    let description: String
    var recommendation: String? = nil
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }

            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let recommendation = recommendation {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text(recommendation)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.yellow.opacity(0.1))
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

struct CorrelationCard: View {
    let factor: String
    let description: String
    let impact: String

    private var impactColor: Color {
        switch impact.lowercased() {
        case let i where i.contains("strong positive"): return .green
        case let i where i.contains("moderate positive"): return .blue
        case let i where i.contains("strong negative"): return .red
        case let i where i.contains("moderate negative"): return .orange
        default: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(factor)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(impact)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(impactColor.opacity(0.2))
                )
                .foregroundColor(impactColor)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

struct CorrelationExplanationCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("Understanding Correlations")
                    .font(.subheadline.weight(.medium))
            }

            Text("Correlations show how different factors relate to your readiness. A strong positive correlation means the factor helps your readiness, while a negative correlation means it tends to reduce it.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
    }
}

struct PeriodizationRecommendationCard: View {
    let recommendation: String
    let trend: ReadinessAnalysis.ReadinessTrendDirection

    private var trendIcon: String {
        switch trend {
        case .improving: return "arrow.up.right.circle.fill"
        case .stable: return "equal.circle.fill"
        case .declining: return "arrow.down.right.circle.fill"
        }
    }

    private var trendColor: Color {
        switch trend {
        case .improving: return .green
        case .stable: return .blue
        case .declining: return .orange
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: trendIcon)
                    .foregroundColor(trendColor)
                Text("Training Recommendation")
                    .font(.headline)
            }

            Text(recommendation)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(trendColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct TrainingOptimizationCard: View {
    let analysis: ReadinessAnalysis?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.blue)
                Text("Training Optimization")
                    .font(.headline)
            }

            if let analysis = analysis {
                VStack(alignment: .leading, spacing: 12) {
                    if let bestDay = analysis.bestDay {
                        OptimizationRow(
                            icon: "star.fill",
                            title: "Best Training Day",
                            value: bestDay.name,
                            color: .green
                        )
                    }

                    if let worstDay = analysis.worstDay {
                        OptimizationRow(
                            icon: "moon.zzz.fill",
                            title: "Best Recovery Day",
                            value: worstDay.name,
                            color: .indigo
                        )
                    }

                    OptimizationRow(
                        icon: "waveform.path.ecg",
                        title: "Score Variability",
                        value: String(format: "%.1f points", analysis.volatility),
                        color: analysis.volatility > 15 ? .orange : .green
                    )
                }
            } else {
                Text("Complete more check-ins to see optimization insights.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

struct OptimizationRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(color)
        }
    }
}

struct TrainingWindowsCard: View {
    let forecasts: [ReadinessForecast]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.blue)
                Text("Upcoming Training Windows")
                    .font(.headline)
            }

            ForEach(forecasts, id: \.date) { forecast in
                TrainingWindowRow(forecast: forecast)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

struct TrainingWindowRow: View {
    let forecast: ReadinessForecast

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: forecast.date)
    }

    private var recommendation: String {
        if forecast.predictedScore >= 80 {
            return "Great day for hard training"
        } else if forecast.predictedScore >= 60 {
            return "Good for moderate training"
        } else if forecast.predictedScore >= 40 {
            return "Light training recommended"
        } else {
            return "Consider rest or active recovery"
        }
    }

    private var color: Color {
        if forecast.predictedScore >= 80 { return .green }
        if forecast.predictedScore >= 60 { return .blue }
        if forecast.predictedScore >= 40 { return .orange }
        return .red
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(dayName)
                    .font(.subheadline.weight(.medium))

                Text(recommendation)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(String(format: "~%.0f%%", forecast.predictedScore))
                .font(.subheadline.monospacedDigit())
                .foregroundColor(color)
        }
    }
}

struct InsightEmptyState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Previews

#Preview("Readiness Insights View") {
    NavigationStack {
        ReadinessInsightsView(patientId: UUID())
    }
}
