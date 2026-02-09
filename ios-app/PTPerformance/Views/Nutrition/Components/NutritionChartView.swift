//
//  NutritionChartView.swift
//  PTPerformance
//
//  ACP-1018: Visual upgrade - Improved chart/graph styling for trends
//

import SwiftUI
import Charts

// MARK: - Weekly Nutrition Chart

/// Polished weekly nutrition trend chart with Swift Charts
struct WeeklyNutritionChart: View {
    let trends: [WeeklyNutritionTrend]
    let calorieGoal: Int

    @State private var selectedTrend: WeeklyNutritionTrend?
    @State private var isAnimating = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weekly Trends")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)

                    if let latest = trends.first {
                        Text("Avg: \(Int(latest.avgDailyCalories)) cal/day")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Legend
                HStack(spacing: Spacing.sm) {
                    NutritionLegendItem(color: .blue, label: "Calories")
                    NutritionLegendItem(color: .red, label: "Protein")
                }
            }

            if trends.isEmpty {
                emptyStateView
            } else {
                chartView
            }

            // Selected trend detail
            if let selected = selectedTrend {
                TrendDetailCard(trend: selected)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.subtle)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isAnimating = true
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Data Yet")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Log meals to see your weekly trends")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.8))
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
    }

    private var chartView: some View {
        Chart {
            // Goal line
            RuleMark(y: .value("Goal", calorieGoal))
                .foregroundStyle(Color.green.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                .annotation(position: .top, alignment: .trailing) {
                    Text("Goal")
                        .font(.caption2)
                        .foregroundColor(.green)
                        .padding(.horizontal, 4)
                }

            ForEach(trends.reversed()) { trend in
                // Calorie bars
                BarMark(
                    x: .value("Week", weekLabel(trend.weekStart)),
                    y: .value("Calories", isAnimating ? trend.avgDailyCalories : 0)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.7), Color.blue],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(4)

                // Protein line overlay
                LineMark(
                    x: .value("Week", weekLabel(trend.weekStart)),
                    y: .value("Protein", isAnimating ? trend.avgDailyProteinG * 10 : 0) // Scale for visibility
                )
                .foregroundStyle(Color.red)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .symbol {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                }
            }
        }
        .frame(height: 180)
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .font(.caption2)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text("\(Int(doubleValue))")
                            .font(.caption2)
                    }
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                selectTrend(at: value.location, proxy: proxy, geometry: geometry)
                            }
                            .onEnded { _ in
                                // Keep selection visible for a moment
                            }
                    )
            }
        }
        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: isAnimating)
    }

    private func weekLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func selectTrend(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        let xPosition = location.x - geometry[proxy.plotAreaFrame].origin.x

        guard xPosition >= 0, xPosition < geometry[proxy.plotAreaFrame].width else {
            return
        }

        // Find closest trend based on x position
        let reversedTrends = trends.reversed()
        let index = Int(xPosition / (geometry[proxy.plotAreaFrame].width / CGFloat(trends.count)))

        if index >= 0 && index < reversedTrends.count {
            let trend = Array(reversedTrends)[index]
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTrend = trend
            }
            HapticFeedback.selectionChanged()
        }
    }
}

// MARK: - Legend Item

struct NutritionLegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Trend Detail Card

struct TrendDetailCard: View {
    let trend: WeeklyNutritionTrend

    var body: some View {
        HStack(spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: 2) {
                Text(formatDateRange(trend.weekStart))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text("\(trend.daysLogged) days logged")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)

                    Text("\(Int(trend.avgDailyCalories)) cal/day")
                        .font(.caption)
                        .fontWeight(.medium)
                }

                HStack(spacing: Spacing.xs) {
                    Image(systemName: "p.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.red)

                    Text("\(Int(trend.avgDailyProteinG))g protein")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(Color(.tertiarySystemBackground))
        )
    }

    private func formatDateRange(_ startDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: startDate)

        if let endDate = Calendar.current.date(byAdding: .day, value: 6, to: startDate) {
            let end = formatter.string(from: endDate)
            return "\(start) - \(end)"
        }
        return start
    }
}

// MARK: - Macro Distribution Pie Chart

/// Visual pie chart for macro nutrient distribution
struct MacroDistributionChart: View {
    let proteinPercent: Double
    let carbsPercent: Double
    let fatPercent: Double
    let proteinGrams: Double
    let carbsGrams: Double
    let fatGrams: Double

    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Macro Distribution")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: Spacing.lg) {
                // Pie chart
                ZStack {
                    ForEach(macroSlices.indices, id: \.self) { index in
                        MacroSlice(
                            startAngle: sliceStartAngle(for: index),
                            endAngle: sliceEndAngle(for: index),
                            color: macroSlices[index].color,
                            isAnimating: isAnimating
                        )
                    }

                    // Center label
                    VStack(spacing: 0) {
                        Text("\(Int(proteinGrams + carbsGrams + fatGrams))")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text("total g")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 100, height: 100)

                // Legend
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    MacroLegendRow(
                        macro: .protein,
                        grams: proteinGrams,
                        percent: proteinPercent
                    )

                    MacroLegendRow(
                        macro: .carbs,
                        grams: carbsGrams,
                        percent: carbsPercent
                    )

                    MacroLegendRow(
                        macro: .fat,
                        grams: fatGrams,
                        percent: fatPercent
                    )
                }
            }
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.subtle)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
    }

    private var macroSlices: [(color: Color, percent: Double)] {
        [
            (macroColor(.protein), proteinPercent),
            (macroColor(.carbs), carbsPercent),
            (macroColor(.fat), fatPercent)
        ]
    }

    private func macroColor(_ type: MacroType) -> Color {
        switch type {
        case .protein: return .red
        case .carbs: return .blue
        case .fat: return .yellow
        }
    }

    private func sliceStartAngle(for index: Int) -> Angle {
        let precedingPercents = macroSlices.prefix(index).reduce(0) { $0 + $1.percent }
        return .degrees(precedingPercents * 3.6 - 90) // 3.6 = 360/100
    }

    private func sliceEndAngle(for index: Int) -> Angle {
        let includingPercent = macroSlices.prefix(index + 1).reduce(0) { $0 + $1.percent }
        return .degrees(includingPercent * 3.6 - 90)
    }
}

// MARK: - Macro Slice

struct MacroSlice: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    let isAnimating: Bool

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = size / 2

            Path { path in
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: isAnimating ? endAngle : startAngle,
                    clockwise: false
                )
                path.closeSubpath()
            }
            .fill(color)
        }
    }
}

// MARK: - Macro Legend Row

struct MacroLegendRow: View {
    let macro: MacroType
    let grams: Double
    let percent: Double

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(macroColor)
                .frame(width: 10, height: 10)

            Text(macro.displayName)
                .font(.caption)
                .foregroundColor(.primary)

            Spacer()

            Text("\(Int(grams))g")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Text("(\(Int(percent))%)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var macroColor: Color {
        switch macro {
        case .protein: return .red
        case .carbs: return .blue
        case .fat: return .yellow
        }
    }
}

// MARK: - Preview

#if DEBUG
struct NutritionChartView_Previews: PreviewProvider {
    static var sampleTrends: [WeeklyNutritionTrend] {
        let calendar = Calendar.current
        return (0..<4).compactMap { weekOffset -> WeeklyNutritionTrend? in
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: Date()) else {
                return nil
            }
            return WeeklyNutritionTrend(
                patientId: "test",
                weekStart: weekStart,
                daysLogged: Int.random(in: 4...7),
                avgDailyCalories: Double.random(in: 1800...2400),
                avgDailyProteinG: Double.random(in: 100...160)
            )
        }
    }

    static var previews: some View {
        VStack(spacing: Spacing.lg) {
            WeeklyNutritionChart(
                trends: sampleTrends,
                calorieGoal: 2200
            )

            MacroDistributionChart(
                proteinPercent: 30,
                carbsPercent: 45,
                fatPercent: 25,
                proteinGrams: 150,
                carbsGrams: 225,
                fatGrams: 70
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
#endif
