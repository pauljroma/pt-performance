import WidgetKit
import SwiftUI

struct WeekOverviewWidget: Widget {
    let kind: String = SharedDataStore.WidgetKind.weekOverview

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeekOverviewProvider()) { entry in
            WeekOverviewWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Week Overview")
        .description("Track your weekly adherence and upcoming workouts.")
        .supportedFamilies([.systemMedium])
    }
}

struct WeekOverviewWidgetView: View {
    let entry: WeekOverviewEntry

    var body: some View {
        VStack(spacing: 8) {
            // Header with adherence percentage
            HStack {
                Text("This Week")
                    .font(.headline)

                Spacer()

                if let adherence = entry.adherence {
                    HStack(spacing: 4) {
                        Text("Adherence:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(Int(adherence.adherencePercent))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(adherenceColor(adherence.adherencePercent))
                    }
                }
            }

            // Week completion view
            if let adherence = entry.adherence {
                WeekCompletionView(days: adherence.weekDays)
            } else {
                HStack(spacing: 6) {
                    ForEach(0..<7, id: \.self) { _ in
                        VStack(spacing: 2) {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 20, height: 20)
                            Text("-")
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Divider()

            // Next workout
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.blue)

                if let workout = entry.nextWorkout, workout.status != .restDay {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Next: \(workout.name)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)

                        if let time = workout.formattedTime {
                            Text(time)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("No upcoming workouts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let adherence = entry.adherence {
                    Text("\(adherence.completedSessions)/\(adherence.totalSessions)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 4)
        .widgetURL(URL(string: "ptperformance://schedule"))
    }

    private func adherenceColor(_ percentage: Double) -> Color {
        switch percentage {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
}

@available(iOS 17.0, *)
#Preview(as: .systemMedium) {
    WeekOverviewWidget()
} timeline: {
    WeekOverviewEntry(date: .now, adherence: .placeholder, nextWorkout: .placeholder)
    WeekOverviewEntry(date: .now, adherence: nil, nextWorkout: nil)
}
