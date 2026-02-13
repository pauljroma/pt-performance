import SwiftUI

/// Reusable circular adherence chart component
/// Respects @Environment(\.accessibilityReduceMotion) for accessibility
struct AdherenceChart: View {
    let adherencePercentage: Double
    var size: CGFloat = 200
    var lineWidth: CGFloat = 20
    var showLabel: Bool = true

    @State private var animatedProgress: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)

            // Progress circle with animated trim
            Circle()
                .trim(from: 0, to: animatedProgress / 100)
                .stroke(adherenceColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // Center label
            if showLabel {
                VStack(spacing: 4) {
                    Text("\(Int(adherencePercentage))%")
                        .font(.system(size: size * 0.25, weight: .bold))
                        .foregroundColor(adherenceColor)

                    Text("Complete")
                        .font(.system(size: size * 0.08))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            if reduceMotion {
                animatedProgress = adherencePercentage
            } else {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    animatedProgress = adherencePercentage
                }
            }
        }
        .onChange(of: adherencePercentage) { _, newValue in
            if reduceMotion {
                animatedProgress = newValue
            } else {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animatedProgress = newValue
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Adherence chart")
        .accessibilityValue("\(Int(adherencePercentage)) percent complete")
    }

    private var adherenceColor: Color {
        switch adherencePercentage {
        case 90...: return .green
        case 80..<90: return Color(red: 0.5, green: 0.8, blue: 0.3)
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
}

/// Bar chart version for weekly adherence breakdown
/// Respects @Environment(\.accessibilityReduceMotion) for accessibility
struct WeeklyAdherenceChart: View {
    let weeklyData: [WeeklyAdherence]
    var height: CGFloat = 150

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(weeklyData.enumerated()), id: \.element.id) { index, week in
                AnimatedAdherenceBar(
                    percentage: week.adherencePercentage,
                    weekNumber: week.weekNumber,
                    maxHeight: height,
                    delay: reduceMotion ? 0 : Double(index) * 0.1,
                    reduceMotion: reduceMotion
                )
            }
        }
        .frame(height: height + 40)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Weekly adherence chart")
    }
}

/// Animated bar for weekly adherence chart
private struct AnimatedAdherenceBar: View {
    let percentage: Double
    let weekNumber: Int
    let maxHeight: CGFloat
    let delay: Double
    let reduceMotion: Bool

    @State private var animatedHeight: CGFloat = 0

    private var targetHeight: CGFloat {
        CGFloat(percentage / 100) * maxHeight
    }

    private var barColor: Color {
        switch percentage {
        case 80...: return .green
        case 60..<80: return .yellow
        default: return .red
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            // Animated bar
            VStack {
                Spacer(minLength: 0)
                RoundedRectangle(cornerRadius: 4)
                    .fill(barColor)
                    .frame(width: 30, height: animatedHeight)
            }
            .frame(height: maxHeight)

            // Week label
            Text("W\(weekNumber)")
                .font(.caption2)
                .foregroundColor(.secondary)

            // Percentage
            Text("\(Int(percentage))%")
                .font(.caption2)
                .bold()
                .foregroundColor(barColor)
        }
        .onAppear {
            if reduceMotion {
                animatedHeight = targetHeight
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        animatedHeight = targetHeight
                    }
                }
            }
        }
        .onChange(of: percentage) { _, _ in
            if reduceMotion {
                animatedHeight = targetHeight
            } else {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    animatedHeight = targetHeight
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Week \(weekNumber)")
        .accessibilityValue("\(Int(percentage)) percent adherence")
    }
}

// MARK: - Compact Adherence Card

struct AdherenceCompactCard: View {
    let adherence: AdherenceData

    var body: some View {
        HStack(spacing: 16) {
            // Circular chart
            AdherenceChart(
                adherencePercentage: adherence.adherencePercentage,
                size: 80,
                lineWidth: 12,
                showLabel: false
            )

            // Stats
            VStack(alignment: .leading, spacing: 8) {
                Text("Adherence")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                HStack {
                    Text("\(adherence.completedSessions)/\(adherence.totalSessions)")
                        .font(.title3)
                        .bold()
                    Text("sessions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text("\(Int(adherence.adherencePercentage))% completion rate")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Adherence: \(adherence.completedSessions) of \(adherence.totalSessions) sessions completed, \(Int(adherence.adherencePercentage)) percent completion rate")
    }
}

// MARK: - Preview

#if DEBUG
struct AdherenceChart_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 32) {
            // Circular chart
            AdherenceChart(adherencePercentage: 85)

            // Weekly bar chart
            WeeklyAdherenceChart(weeklyData: [
                WeeklyAdherence(id: "1", weekNumber: 1, adherencePercentage: 100),
                WeeklyAdherence(id: "2", weekNumber: 2, adherencePercentage: 85),
                WeeklyAdherence(id: "3", weekNumber: 3, adherencePercentage: 70),
                WeeklyAdherence(id: "4", weekNumber: 4, adherencePercentage: 90),
                WeeklyAdherence(id: "5", weekNumber: 5, adherencePercentage: 75),
                WeeklyAdherence(id: "6", weekNumber: 6, adherencePercentage: 95),
                WeeklyAdherence(id: "7", weekNumber: 7, adherencePercentage: 80),
                WeeklyAdherence(id: "8", weekNumber: 8, adherencePercentage: 88)
            ])

            // Compact card
            AdherenceCompactCard(adherence: AdherenceData(
                adherencePercentage: 85.5,
                completedSessions: 17,
                totalSessions: 24,
                weeklyBreakdown: nil
            ))

            Spacer()
        }
        .padding()
    }
}
#endif
