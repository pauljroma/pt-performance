import SwiftUI
import Charts

/// Reusable pain trend chart component
struct PainTrendChart: View {
    let dataPoints: [PainDataPoint]
    var showThreshold: Bool = true
    var height: CGFloat = 200

    private var accessibilitySummary: String {
        guard !dataPoints.isEmpty else { return "No pain data available" }
        let latestScore = dataPoints.last?.painScore ?? 0
        let avgScore = dataPoints.map { $0.painScore }.reduce(0, +) / Double(dataPoints.count)
        return "Pain trend chart showing \(dataPoints.count) data points. Latest score: \(Int(latestScore)) out of 10. Average: \(String(format: "%.1f", avgScore)) out of 10"
    }

    var body: some View {
        Chart {
            ForEach(dataPoints) { point in
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Pain", point.painScore)
                )
                .foregroundStyle(.red.gradient)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 3))

                PointMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Pain", point.painScore)
                )
                .foregroundStyle(.red)
                .symbol(.circle)
                .symbolSize(50)

                // Area fill
                AreaMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Pain", point.painScore)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.red.opacity(0.3), .red.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            // Safety threshold line
            if showThreshold {
                RuleMark(y: .value("Threshold", 5))
                    .foregroundStyle(.orange.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Safety Threshold")
                            .font(.caption2)
                            .padding(4)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(4)
                            .foregroundColor(.orange)
                    }
            }
        }
        .chartYScale(domain: 0...10)
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 2, 5, 7, 10]) { value in
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
            AxisMarks(values: .stride(by: .day, count: 2)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month().day())
                    .font(.caption)
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Pain Trend Chart")
        .accessibilityValue(accessibilitySummary)
    }
}

// MARK: - Preview

#if DEBUG
struct PainTrendChart_Previews: PreviewProvider {
    static var previews: some View {
        let sampleData = (0..<14).map { day in
            PainDataPoint(
                id: UUID().uuidString,
                date: Calendar.current.date(byAdding: .day, value: -day, to: Date())!,
                painScore: Double.random(in: 0...8),
                sessionNumber: 14 - day
            )
        }

        return VStack {
            Text("Pain Trend Chart")
                .font(.headline)

            PainTrendChart(dataPoints: Array(sampleData.reversed()))
                .padding()

            Spacer()
        }
        .padding()
    }
}
#endif
