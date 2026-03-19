import WidgetKit
import SwiftUI

struct DailySummaryWidget: Widget {
    let kind: String = SharedDataStore.WidgetKind.dailySummary

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailySummaryProvider()) { entry in
            DailySummaryWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Daily Summary")
        .description("Readiness, fatigue, and today's workout at a glance.")
        .supportedFamilies([.systemMedium])
    }
}

struct DailySummaryWidgetView: View {
    let entry: DailySummaryEntry

    var body: some View {
        HStack(spacing: 12) {
            // Readiness Section
            VStack(alignment: .center, spacing: 4) {
                Label("Readiness", systemImage: "heart.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if let readiness = entry.readiness {
                    Text("\(readiness.score)%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(WidgetColors.colorForBand(readiness.band))

                    HStack(spacing: 2) {
                        Circle()
                            .fill(WidgetColors.colorForBand(readiness.band))
                            .frame(width: 6, height: 6)
                        Text(shortBandLabel(readiness.band))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("--")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)

            Divider()

            // Fatigue Section
            VStack(alignment: .center, spacing: 4) {
                Label("Fatigue", systemImage: "waveform.path.ecg")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if let fatigueBand = entry.fatigueBand {
                    Text(fatigueBand.uppercased())
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(WidgetColors.colorForFatigueBand(fatigueBand))
                } else {
                    Text("--")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }

                Text("Monitor")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()

            // Workout Section
            VStack(alignment: .center, spacing: 4) {
                Label("Workout", systemImage: "figure.strengthtraining.traditional")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if let workout = entry.workout {
                    Text(workout.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.8)

                    if let time = workout.formattedTime {
                        Text(time)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Rest Day")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Recover")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, Spacing.xs)
        .widgetURL(URL(string: "korza://today"))
    }

    private func shortBandLabel(_ band: String) -> String {
        switch band.lowercased() {
        case "green": return "Ready"
        case "yellow": return "Caution"
        case "orange": return "Reduce"
        case "red": return "Rest"
        default: return "Unknown"
        }
    }
}

@available(iOS 17.0, *)
#Preview(as: .systemMedium) {
    DailySummaryWidget()
} timeline: {
    DailySummaryEntry(date: .now, readiness: .placeholder, workout: .placeholder, fatigueBand: "low")
    DailySummaryEntry(date: .now, readiness: nil, workout: nil, fatigueBand: nil)
}
