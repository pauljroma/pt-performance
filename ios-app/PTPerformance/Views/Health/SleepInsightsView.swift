import SwiftUI
import Charts

/// ACP-1022: Sleep Data Presentation Upgrade View
/// Provides comprehensive sleep visualization with stage breakdown, sleep debt tracking,
/// bedtime consistency scoring, and quality factor explanations
struct SleepInsightsView: View {
    @StateObject private var viewModel: SleepInsightsViewModel
    @Environment(\.colorScheme) private var colorScheme

    init(patientId: UUID) {
        _viewModel = StateObject(wrappedValue: SleepInsightsViewModel(patientId: patientId))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Last night's sleep summary
                sleepSummaryCard

                // Sleep stage visualization (stacked bar chart)
                sleepStagesCard

                // Sleep debt tracker
                sleepDebtCard

                // Bedtime consistency score
                bedtimeConsistencyCard

                // Week-over-week comparison
                weekComparisonCard

                // Sleep quality factors
                qualityFactorsCard

                // Readiness integration
                readinessIntegrationCard
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Sleep Insights")
        .navigationBarTitleDisplayMode(.large)
        .refreshableWithHaptic {
            await viewModel.loadData()
        }
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Sleep Summary Card

    private var sleepSummaryCard: some View {
        Card(shadow: Shadow.medium) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "bed.double.fill")
                        .font(.title2)
                        .foregroundColor(.modusCyan)
                        .accessibilityHidden(true)

                    Text("Last Night")
                        .font(.headline)
                        .accessibleHeader()

                    Spacer()

                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }

                if let lastNight = viewModel.lastNightSleep {
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                        Text(formatHoursMinutes(lastNight.totalMinutes))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.modusCyan)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("total sleep")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            if let efficiency = viewModel.sleepEfficiency {
                                Text("\(Int(efficiency))% efficiency")
                                    .font(.caption)
                                    .foregroundColor(efficiencyColor(efficiency))
                            }
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Total sleep: \(formatHoursMinutes(lastNight.totalMinutes))")

                    // Quick stats
                    HStack(spacing: Spacing.lg) {
                        sleepStat(icon: "moon.zzz.fill", label: "Deep", value: lastNight.deepMinutes, color: .indigo)
                        sleepStat(icon: "brain.head.profile", label: "REM", value: lastNight.remMinutes, color: .purple)
                        sleepStat(icon: "heart.fill", label: "Light", value: lastNight.coreMinutes, color: .modusCyan)
                    }
                } else {
                    Text("No sleep data available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Sleep Stages Card

    private var sleepStagesCard: some View {
        Card(shadow: Shadow.medium) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Text("7-Day Sleep Stages")
                        .font(.headline)
                        .accessibleHeader()

                    Spacer()

                    // Legend
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Circle().fill(.red.opacity(0.7)).frame(width: 8, height: 8)
                            Text("Awake").font(.caption2)
                        }
                        HStack(spacing: 4) {
                            Circle().fill(.purple.opacity(0.7)).frame(width: 8, height: 8)
                            Text("REM").font(.caption2)
                        }
                        HStack(spacing: 4) {
                            Circle().fill(.blue.opacity(0.7)).frame(width: 8, height: 8)
                            Text("Light").font(.caption2)
                        }
                        HStack(spacing: 4) {
                            Circle().fill(.indigo.opacity(0.7)).frame(width: 8, height: 8)
                            Text("Deep").font(.caption2)
                        }
                    }
                    .font(.caption)
                }

                if !viewModel.sleepHistory.isEmpty {
                    Chart {
                        ForEach(viewModel.sleepHistory) { night in
                            // Deep sleep (bottom layer)
                            if let deep = night.data.deepMinutes, deep > 0 {
                                BarMark(
                                    x: .value("Date", night.date, unit: .day),
                                    y: .value("Minutes", deep)
                                )
                                .foregroundStyle(.indigo.opacity(0.7))
                                .accessibilityLabel("Deep sleep on \(night.date.formatted(date: .abbreviated, time: .omitted))")
                                .accessibilityValue("\(deep) minutes")
                            }

                            // Light/Core sleep (second layer)
                            if let core = night.data.coreMinutes, core > 0 {
                                BarMark(
                                    x: .value("Date", night.date, unit: .day),
                                    y: .value("Minutes", core)
                                )
                                .foregroundStyle(.blue.opacity(0.7))
                                .accessibilityLabel("Light sleep on \(night.date.formatted(date: .abbreviated, time: .omitted))")
                                .accessibilityValue("\(core) minutes")
                            }

                            // REM sleep (third layer)
                            if let rem = night.data.remMinutes, rem > 0 {
                                BarMark(
                                    x: .value("Date", night.date, unit: .day),
                                    y: .value("Minutes", rem)
                                )
                                .foregroundStyle(.purple.opacity(0.7))
                                .accessibilityLabel("REM sleep on \(night.date.formatted(date: .abbreviated, time: .omitted))")
                                .accessibilityValue("\(rem) minutes")
                            }

                            // Awake time (top layer)
                            if let awake = night.data.awakeMinutes, awake > 0 {
                                BarMark(
                                    x: .value("Date", night.date, unit: .day),
                                    y: .value("Minutes", awake)
                                )
                                .foregroundStyle(.red.opacity(0.5))
                                .accessibilityLabel("Awake time on \(night.date.formatted(date: .abbreviated, time: .omitted))")
                                .accessibilityValue("\(awake) minutes")
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.weekday(.narrow))
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let mins = value.as(Int.self) {
                                    Text("\(mins / 60)h")
                                }
                            }
                        }
                    }
                    .frame(height: 200)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Sleep stage breakdown chart for the past 7 days")
                } else {
                    EmptyStateView(
                        title: "No Sleep Data",
                        message: "Connect your Apple Watch to track sleep stages",
                        icon: "bed.double.fill"
                    )
                    .frame(height: 200)
                }
            }
        }
    }

    // MARK: - Sleep Debt Card

    private var sleepDebtCard: some View {
        Card(shadow: Shadow.medium) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "gauge.medium")
                        .foregroundColor(.orange)
                        .accessibilityHidden(true)

                    Text("Sleep Debt")
                        .font(.headline)
                        .accessibleHeader()

                    Spacer()

                    if let debt = viewModel.sleepDebt {
                        Text(formatDebt(debt))
                            .font(.title3.bold())
                            .foregroundColor(debtColor(debt))
                    }
                }

                if let debt = viewModel.sleepDebt {
                    VStack(spacing: Spacing.sm) {
                        // Visual debt meter
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(height: 32)

                                // Debt indicator
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(debtGradient(debt))
                                    .frame(width: debtWidth(debt, maxWidth: geometry.size.width), height: 32)
                            }
                        }
                        .frame(height: 32)
                        .accessibilityLabel("Sleep debt meter")
                        .accessibilityValue(formatDebt(debt))

                        HStack {
                            Text("Well Rested")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text("Sleep Deprived")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Divider()

                        // Explanation
                        Text(debtExplanation(debt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    Text("Tracking sleep debt (need 7+ days of data)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Bedtime Consistency Card

    private var bedtimeConsistencyCard: some View {
        Card(shadow: Shadow.medium) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.modusTealAccent)
                        .accessibilityHidden(true)

                    Text("Bedtime Consistency")
                        .font(.headline)
                        .accessibleHeader()

                    Spacer()

                    if let score = viewModel.consistencyScore {
                        VStack(alignment: .trailing, spacing: 0) {
                            Text("\(Int(score))")
                                .font(.title2.bold())
                                .foregroundColor(consistencyColor(score))
                            Text("/ 100")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if let score = viewModel.consistencyScore {
                    VStack(spacing: Spacing.sm) {
                        // Progress ring visualization
                        ZStack {
                            Circle()
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 12)

                            Circle()
                                .trim(from: 0, to: score / 100)
                                .stroke(consistencyColor(score), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                        }
                        .frame(width: 100, height: 100)
                        .accessibilityLabel("Bedtime consistency score: \(Int(score)) out of 100")

                        Text(consistencyLabel(score))
                            .font(.subheadline.bold())
                            .foregroundColor(consistencyColor(score))

                        Text("Based on bedtime variation over the past 7 days. Consistent sleep schedules improve sleep quality.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Text("Tracking bedtime patterns...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Week Comparison Card

    private var weekComparisonCard: some View {
        Card(shadow: Shadow.medium) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "chart.bar.xaxis")
                        .foregroundColor(.modusDeepTeal)
                        .accessibilityHidden(true)

                    Text("Week-over-Week")
                        .font(.headline)
                        .accessibleHeader()
                }

                if let comparison = viewModel.weekComparison {
                    VStack(spacing: Spacing.sm) {
                        comparisonRow(label: "Average Sleep", thisWeek: comparison.thisWeekAvg, lastWeek: comparison.lastWeekAvg, isMinutes: true)
                        comparisonRow(label: "Sleep Efficiency", thisWeek: comparison.thisWeekEfficiency, lastWeek: comparison.lastWeekEfficiency, isMinutes: false)
                        comparisonRow(label: "Deep Sleep %", thisWeek: comparison.thisWeekDeepPercent, lastWeek: comparison.lastWeekDeepPercent, isMinutes: false)

                        Divider()

                        HStack(spacing: Spacing.xs) {
                            Image(systemName: comparison.trend == .improving ? "arrow.up.circle.fill" : comparison.trend == .declining ? "arrow.down.circle.fill" : "minus.circle.fill")
                                .foregroundColor(comparison.trend == .improving ? .green : comparison.trend == .declining ? .orange : .secondary)

                            Text(comparison.trendMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text("Need 14+ days of data for comparison")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Quality Factors Card

    private var qualityFactorsCard: some View {
        Card(shadow: Shadow.medium) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .accessibilityHidden(true)

                    Text("Sleep Quality Factors")
                        .font(.headline)
                        .accessibleHeader()
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    ForEach(viewModel.qualityFactors, id: \.title) { factor in
                        qualityFactorRow(factor: factor)
                    }
                }
            }
        }
    }

    // MARK: - Readiness Integration Card

    private var readinessIntegrationCard: some View {
        Card(shadow: Shadow.medium) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "bolt.heart.fill")
                        .foregroundColor(.red)
                        .accessibilityHidden(true)

                    Text("Impact on Readiness")
                        .font(.headline)
                        .accessibleHeader()
                }

                if let impact = viewModel.readinessImpact {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Text("Sleep contributes")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text("\(Int(impact.contribution))%")
                                .font(.title3.bold())
                                .foregroundColor(.modusCyan)
                        }

                        Text("to your overall readiness score")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Divider()

                        Text(impact.message)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    Text("Complete a readiness check-in to see sleep impact")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Helper Views

    private func sleepStat(icon: String, label: String, value: Int?, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .accessibilityHidden(true)

            if let value = value {
                Text("\(value)m")
                    .font(.caption.bold())
                    .foregroundColor(.primary)
            } else {
                Text("--")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value.map { "\($0) minutes" } ?? "not available")")
    }

    private func comparisonRow(label: String, thisWeek: Double, lastWeek: Double, isMinutes: Bool) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(formatValue(thisWeek, isMinutes: isMinutes))
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)

                let change = thisWeek - lastWeek
                let changeText = change > 0 ? "+\(formatValue(abs(change), isMinutes: isMinutes))" : "-\(formatValue(abs(change), isMinutes: isMinutes))"

                HStack(spacing: 2) {
                    Image(systemName: change > 0 ? "arrow.up" : change < 0 ? "arrow.down" : "minus")
                        .font(.caption2)
                    Text(changeText)
                }
                .font(.caption2)
                .foregroundColor(change > 0 ? .green : change < 0 ? .red : .secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(formatValue(thisWeek, isMinutes: isMinutes)), change from last week: \(formatValue(abs(thisWeek - lastWeek), isMinutes: isMinutes))")
    }

    private func qualityFactorRow(factor: SleepQualityFactor) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: factor.icon)
                .foregroundColor(factor.status == .good ? .green : factor.status == .poor ? .orange : .secondary)
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(factor.title)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)

                Text(factor.explanation)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Circle()
                .fill(factor.status == .good ? Color.green : factor.status == .poor ? Color.orange : Color.secondary)
                .frame(width: 8, height: 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(factor.title): \(factor.status == .good ? "Good" : factor.status == .poor ? "Needs attention" : "Neutral"). \(factor.explanation)")
    }

    // MARK: - Helper Methods

    private func formatHoursMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours)h \(mins)m"
    }

    private func formatValue(_ value: Double, isMinutes: Bool) -> String {
        if isMinutes {
            return formatHoursMinutes(Int(value))
        } else {
            return String(format: "%.1f%%", value)
        }
    }

    private func formatDebt(_ debt: Int) -> String {
        if debt > 0 {
            return "+\(formatHoursMinutes(debt))"
        } else if debt < 0 {
            return formatHoursMinutes(abs(debt))
        } else {
            return "0h"
        }
    }

    private func efficiencyColor(_ efficiency: Double) -> Color {
        if efficiency >= 85 {
            return .green
        } else if efficiency >= 75 {
            return .yellow
        } else {
            return .orange
        }
    }

    private func debtColor(_ debt: Int) -> Color {
        if debt <= -120 {
            return .red
        } else if debt <= -60 {
            return .orange
        } else if debt >= 60 {
            return .green
        } else {
            return .modusCyan
        }
    }

    private func debtGradient(_ debt: Int) -> LinearGradient {
        let color: Color
        if debt <= -120 {
            color = .red
        } else if debt <= -60 {
            color = .orange
        } else if debt >= 60 {
            color = .green
        } else {
            color = .modusCyan
        }

        return LinearGradient(colors: [color.opacity(0.6), color], startPoint: .leading, endPoint: .trailing)
    }

    private func debtWidth(_ debt: Int, maxWidth: CGFloat) -> CGFloat {
        let maxDebt: Double = 240.0 // ±4 hours
        let normalized = min(abs(Double(debt)) / maxDebt, 1.0)
        return maxWidth * normalized
    }

    private func debtExplanation(_ debt: Int) -> String {
        if debt <= -120 {
            return "Significant sleep debt accumulated. Prioritize getting extra rest this week."
        } else if debt <= -60 {
            return "Moderate sleep debt. Try to get an extra hour of sleep for the next few nights."
        } else if debt >= 60 {
            return "Sleep surplus! You're well-rested. Maintain this schedule."
        } else {
            return "Sleep balance is neutral. Continue your current sleep routine."
        }
    }

    private func consistencyColor(_ score: Double) -> Color {
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .modusTealAccent
        } else {
            return .orange
        }
    }

    private func consistencyLabel(_ score: Double) -> String {
        if score >= 80 {
            return "Excellent"
        } else if score >= 60 {
            return "Good"
        } else if score >= 40 {
            return "Fair"
        } else {
            return "Needs Improvement"
        }
    }
}

// MARK: - Supporting Models

struct SleepNight: Identifiable {
    let id = UUID()
    let date: Date
    let data: SleepData
}

struct SleepWeekComparison {
    let thisWeekAvg: Double
    let lastWeekAvg: Double
    let thisWeekEfficiency: Double
    let lastWeekEfficiency: Double
    let thisWeekDeepPercent: Double
    let lastWeekDeepPercent: Double
    let trend: SleepTrend
    let trendMessage: String

    enum SleepTrend {
        case improving
        case declining
        case stable
    }
}

struct SleepQualityFactor {
    let icon: String
    let title: String
    let explanation: String
    let status: Status

    enum Status {
        case good
        case neutral
        case poor
    }
}

struct ReadinessImpact {
    let contribution: Double
    let message: String
}

// MARK: - Preview

#if DEBUG
struct SleepInsightsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SleepInsightsView(patientId: UUID())
        }
        .preferredColorScheme(.light)
        .previewDisplayName("Light Mode")

        NavigationStack {
            SleepInsightsView(patientId: UUID())
        }
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")
    }
}
#endif
