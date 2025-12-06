import SwiftUI

/// Reusable circular adherence chart component
struct AdherenceChart: View {
    let adherencePercentage: Double
    var size: CGFloat = 200
    var lineWidth: CGFloat = 20
    var showLabel: Bool = true

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)

            // Progress circle
            Circle()
                .trim(from: 0, to: adherencePercentage / 100)
                .stroke(adherenceColor, lineWidth: lineWidth)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: adherencePercentage)

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
struct WeeklyAdherenceChart: View {
    let weeklyData: [WeeklyAdherence]
    var height: CGFloat = 150

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(weeklyData) { week in
                VStack(spacing: 4) {
                    // Bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor(week.adherencePercentage))
                        .frame(width: 30, height: CGFloat(week.adherencePercentage / 100) * height)

                    // Week label
                    Text("W\(week.weekNumber)")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    // Percentage
                    Text("\(Int(week.adherencePercentage))%")
                        .font(.caption2)
                        .bold()
                        .foregroundColor(barColor(week.adherencePercentage))
                }
            }
        }
        .frame(height: height + 40)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func barColor(_ percentage: Double) -> Color {
        switch percentage {
        case 80...: return .green
        case 60..<80: return .yellow
        default: return .red
        }
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
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Preview

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
