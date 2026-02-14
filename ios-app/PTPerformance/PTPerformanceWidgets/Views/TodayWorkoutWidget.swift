import WidgetKit
import SwiftUI

struct TodayWorkoutWidget: Widget {
    let kind: String = SharedDataStore.WidgetKind.todayWorkout

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayWorkoutProvider()) { entry in
            TodayWorkoutWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's Workout")
        .description("Quick access to your scheduled workout.")
        .supportedFamilies([.systemSmall])
    }
}

struct TodayWorkoutWidgetView: View {
    let entry: TodayWorkoutEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(.modusCyan)
                Text("Today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let workout = entry.workout {
                Text(workout.name)
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Spacer()

                HStack {
                    if let minutes = workout.estimatedMinutes {
                        Label("\(minutes) min", systemImage: "clock")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: workout.status.iconName)
                        Text(workout.status.displayText)
                    }
                    .font(.caption2)
                    .foregroundStyle(statusColor(workout.status))
                }
            } else {
                Text("No workout scheduled")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Enjoy your rest day!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(workoutURL)
    }

    private var workoutURL: URL? {
        if let sessionId = entry.workout?.sessionId {
            return URL(string: "modus://workout/\(sessionId.uuidString)")
        }
        return URL(string: "modus://today")
    }

    private func statusColor(_ status: WidgetWorkout.WorkoutStatus) -> Color {
        switch status {
        case .scheduled: return .blue
        case .inProgress: return .orange
        case .completed: return .green
        case .skipped: return .red
        case .restDay: return .purple
        }
    }
}

@available(iOS 17.0, *)
#Preview(as: .systemSmall) {
    TodayWorkoutWidget()
} timeline: {
    TodayWorkoutEntry(date: .now, workout: .placeholder)
    TodayWorkoutEntry(date: .now, workout: .restDay)
}
