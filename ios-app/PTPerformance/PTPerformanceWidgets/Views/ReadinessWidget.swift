import WidgetKit
import SwiftUI

struct ReadinessWidget: Widget {
    let kind: String = SharedDataStore.WidgetKind.readiness

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReadinessProvider()) { entry in
            ReadinessWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Readiness Score")
        .description("See your daily readiness at a glance.")
        .supportedFamilies([.systemSmall])
    }
}

struct ReadinessWidgetView: View {
    let entry: ReadinessEntry

    private var bandColor: Color {
        guard let readiness = entry.readiness else { return .gray }
        switch readiness.band.lowercased() {
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "red": return .red
        default: return .gray
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("Readiness")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let readiness = entry.readiness {
                Text("\(readiness.score)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(bandColor)

                HStack(spacing: 4) {
                    Circle()
                        .fill(bandColor)
                        .frame(width: 8, height: 8)
                    Text(readiness.bandLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("--")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)

                Text("No data")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "korza://readiness"))
    }
}

@available(iOS 17.0, *)
#Preview(as: .systemSmall) {
    ReadinessWidget()
} timeline: {
    ReadinessEntry(date: .now, readiness: .placeholder)
    ReadinessEntry(date: .now, readiness: WidgetReadiness(score: 45, band: "orange", date: Date()))
}
