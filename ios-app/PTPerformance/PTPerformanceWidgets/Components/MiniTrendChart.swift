import SwiftUI

/// A compact 7-day trend chart for widgets
struct MiniTrendChart: View {
    let data: [Int]  // 7 values (0-100 scores)
    let labels: [String]  // Day labels (M, T, W, etc.)
    let highlightToday: Bool

    init(data: [Int], labels: [String] = ["M", "T", "W", "T", "F", "S", "S"], highlightToday: Bool = true) {
        self.data = data
        self.labels = labels
        self.highlightToday = highlightToday
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(Array(zip(data.indices, data)), id: \.0) { index, value in
                VStack(spacing: 2) {
                    // Bar
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colorForValue(value))
                        .frame(width: barWidth, height: barHeight(for: value))

                    // Label
                    if index < labels.count {
                        Text(labels[index])
                            .font(.system(size: 8))
                            .foregroundStyle(isToday(index) ? .primary : .secondary)
                    }
                }
                .opacity(isToday(index) && highlightToday ? 1.0 : 0.7)
            }
        }
    }

    private var barWidth: CGFloat { 20 }
    private var maxBarHeight: CGFloat { 40 }

    private func barHeight(for value: Int) -> CGFloat {
        max(4, CGFloat(value) / 100 * maxBarHeight)
    }

    private func colorForValue(_ value: Int) -> Color {
        WidgetColors.colorForScore(value)
    }

    private func isToday(_ index: Int) -> Bool {
        let todayIndex = Calendar.current.component(.weekday, from: Date()) - 2 // Mon = 0
        let adjustedIndex = todayIndex < 0 ? 6 : todayIndex
        return index == adjustedIndex
    }
}

/// A line chart variant for the recovery dashboard
struct MiniLineChart: View {
    let data: [Int]
    let lineColor: Color
    let fillColor: Color

    init(data: [Int], lineColor: Color = .blue, fillColor: Color = .blue.opacity(0.2)) {
        self.data = data
        self.lineColor = lineColor
        self.fillColor = fillColor
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let stepX = width / CGFloat(max(1, data.count - 1))

            let points = data.enumerated().map { index, value in
                CGPoint(
                    x: CGFloat(index) * stepX,
                    y: height - (CGFloat(value) / 100 * height)
                )
            }

            ZStack {
                // Fill area
                if points.count > 1 {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: height))
                        path.addLine(to: points[0])
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                        path.addLine(to: CGPoint(x: width, y: height))
                        path.closeSubpath()
                    }
                    .fill(fillColor)
                }

                // Line
                if points.count > 1 {
                    Path { path in
                        path.move(to: points[0])
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(lineColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }

                // Points
                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                    Circle()
                        .fill(lineColor)
                        .frame(width: 4, height: 4)
                        .position(point)
                }
            }
        }
    }
}

/// A week view showing completion status for each day
struct WeekCompletionView: View {
    let days: [WidgetAdherence.DayStatus]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                VStack(spacing: 2) {
                    // Status indicator
                    statusIcon(for: day.status)
                        .frame(width: 20, height: 20)

                    // Day label
                    Text(dayLabel(for: day.date))
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func statusIcon(for status: WidgetAdherence.DayStatus.Status) -> some View {
        switch status {
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .scheduled:
            Circle()
                .strokeBorder(Color.blue, lineWidth: 1.5)
        case .skipped:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red.opacity(0.7))
        case .restDay:
            Text("-")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .future:
            Circle()
                .fill(Color.gray.opacity(0.2))
        }
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }
}

#Preview {
    VStack(spacing: 30) {
        MiniTrendChart(data: [85, 72, 90, 65, 78, 55, 88])
            .frame(height: 60)

        MiniLineChart(data: [85, 72, 90, 65, 78, 55, 88])
            .frame(height: 60)

        WeekCompletionView(days: WidgetAdherence.placeholder.weekDays)
    }
    .padding()
}
