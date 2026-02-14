//
//  ProteinTimingChart.swift
//  PTPerformance
//
//  ACP-1018: Protein timing visualization
//

import SwiftUI
import Charts

// MARK: - Protein Timing Chart

/// Displays protein distribution across meals throughout the day
struct ProteinTimingChart: View {
    let logs: [NutritionLog]
    let proteinGoal: Double

    @State private var isAnimating = false

    private var mealProteinData: [(mealType: MealType, protein: Double, time: Date)] {
        logs.compactMap { log in
            guard let mealType = log.mealType,
                  let protein = log.totalProteinG else { return nil }
            return (mealType, protein, log.loggedAt)
        }
        .sorted { $0.time < $1.time }
    }

    private var totalProtein: Double {
        mealProteinData.reduce(0) { $0 + $1.protein }
    }

    private var averageProteinPerMeal: Double {
        guard !mealProteinData.isEmpty else { return 0 }
        return totalProtein / Double(mealProteinData.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Protein Distribution")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)

                    Text("\(Int(totalProtein))g across \(mealProteinData.count) meals")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Avg/Meal")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("\(Int(averageProteinPerMeal))g")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
            }

            if mealProteinData.isEmpty {
                emptyStateView
            } else {
                chartView
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
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 24))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No meals logged")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
    }

    private var chartView: some View {
        Chart {
            ForEach(Array(mealProteinData.enumerated()), id: \.offset) { index, data in
                BarMark(
                    x: .value("Meal", mealTypeShortName(data.mealType)),
                    y: .value("Protein", isAnimating ? data.protein : 0)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.red.opacity(0.7), Color.red],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(CornerRadius.xs)
                .annotation(position: .top) {
                    Text("\(Int(data.protein))g")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                        .opacity(isAnimating ? 1 : 0)
                }
            }

            // Average line
            if !mealProteinData.isEmpty {
                RuleMark(y: .value("Average", averageProteinPerMeal))
                    .foregroundStyle(Color.red.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
            }
        }
        .frame(height: 120)
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
                        Text("\(Int(doubleValue))g")
                            .font(.caption2)
                    }
                }
            }
        }
        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: isAnimating)
    }

    private func mealTypeShortName(_ mealType: MealType) -> String {
        switch mealType {
        case .breakfast: return "Bfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        case .preWorkout: return "Pre"
        case .postWorkout: return "Post"
        }
    }
}

// MARK: - Protein Timing Sparkline

/// Compact sparkline visualization for weekly protein timing trends
struct ProteinTimingSparkline: View {
    let dailyLogs: [(date: Date, logs: [NutritionLog])]
    let height: CGFloat = 40

    @State private var isAnimating = false

    private var dataPoints: [Double] {
        dailyLogs.map { day in
            day.logs.compactMap { $0.totalProteinG }.reduce(0, +)
        }
    }

    private var maxProtein: Double {
        dataPoints.max() ?? 1
    }

    var body: some View {
        GeometryReader { geometry in
            let points = sparklinePoints(in: geometry.size)

            ZStack(alignment: .bottomLeading) {
                // Area fill
                Path { path in
                    guard !points.isEmpty else { return }

                    path.move(to: CGPoint(x: points[0].x, y: geometry.size.height))

                    for point in points {
                        path.addLine(to: point)
                    }

                    path.addLine(to: CGPoint(x: points[points.count - 1].x, y: geometry.size.height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Color.red.opacity(0.3), Color.red.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(isAnimating ? 1 : 0)

                // Line
                Path { path in
                    guard !points.isEmpty else { return }

                    path.move(to: points[0])

                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .trim(from: 0, to: isAnimating ? 1 : 0)
                .stroke(Color.red, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(height: height)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }

    private func sparklinePoints(in size: CGSize) -> [CGPoint] {
        guard !dataPoints.isEmpty else { return [] }

        let xSpacing = size.width / CGFloat(max(dataPoints.count - 1, 1))

        return dataPoints.enumerated().map { index, value in
            let x = CGFloat(index) * xSpacing
            let normalizedValue = value / maxProtein
            let y = size.height - (CGFloat(normalizedValue) * size.height * 0.8) - (size.height * 0.1)
            return CGPoint(x: x, y: y)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ProteinTimingChart_Previews: PreviewProvider {
    static var sampleLogs: [NutritionLog] {
        let now = Date()
        let calendar = Calendar.current

        return [
            NutritionLog(
                id: UUID(),
                patientId: "test",
                loggedAt: calendar.date(byAdding: .hour, value: -8, to: now)!,
                mealType: .breakfast,
                foodItems: [],
                totalCalories: 450,
                totalProteinG: 35
            ),
            NutritionLog(
                id: UUID(),
                patientId: "test",
                loggedAt: calendar.date(byAdding: .hour, value: -4, to: now)!,
                mealType: .lunch,
                foodItems: [],
                totalCalories: 600,
                totalProteinG: 45
            ),
            NutritionLog(
                id: UUID(),
                patientId: "test",
                loggedAt: calendar.date(byAdding: .hour, value: -1, to: now)!,
                mealType: .dinner,
                foodItems: [],
                totalCalories: 700,
                totalProteinG: 50
            )
        ]
    }

    static var previews: some View {
        VStack(spacing: Spacing.lg) {
            ProteinTimingChart(
                logs: sampleLogs,
                proteinGoal: 150
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
#endif
