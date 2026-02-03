import WidgetKit
import SwiftUI

struct StreakWidget: Widget {
    let kind: String = SharedDataStore.WidgetKind.streak

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Training Streak")
        .description("Track your consecutive training days.")
        .supportedFamilies([.systemSmall])
    }
}

struct StreakWidgetView: View {
    let entry: StreakEntry

    var body: some View {
        VStack(spacing: 8) {
            if let streak = entry.streak {
                // Flame icon with streak count
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.title)
                        .foregroundStyle(flameGradient)

                    Text("\(streak.currentStreak)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                }

                Text(streak.currentStreak == 1 ? "Day" : "Days")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(streak.motivationalMessage)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                if streak.isAtRisk {
                    Text("Train today to keep it!")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            } else {
                Image(systemName: "flame")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)

                Text("No streak yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Start training today!")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "modus://streak"))
    }

    private var flameGradient: LinearGradient {
        LinearGradient(
            colors: [.orange, .red],
            startPoint: .bottom,
            endPoint: .top
        )
    }
}

@available(iOS 17.0, *)
#Preview(as: .systemSmall) {
    StreakWidget()
} timeline: {
    StreakEntry(date: .now, streak: .placeholder)
    StreakEntry(date: .now, streak: WidgetStreak(currentStreak: 30, longestStreak: 45))
}
