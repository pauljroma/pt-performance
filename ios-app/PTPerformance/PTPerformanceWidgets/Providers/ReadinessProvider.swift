import WidgetKit
import SwiftUI

struct ReadinessEntry: TimelineEntry {
    let date: Date
    let readiness: WidgetReadiness?
}

struct ReadinessProvider: TimelineProvider {
    typealias Entry = ReadinessEntry

    func placeholder(in context: Context) -> ReadinessEntry {
        ReadinessEntry(date: Date(), readiness: .placeholder)
    }

    func getSnapshot(in context: Context) async -> ReadinessEntry {
        let entry = ReadinessEntry(
            date: Date(),
            readiness: SharedDataStore.shared.getReadiness() ?? .placeholder
        )
        return entry
    }

    func getTimeline(in context: Context) async -> Timeline<ReadinessEntry> {
        let currentDate = Date()
        let readiness = SharedDataStore.shared.getReadiness()

        let entry = ReadinessEntry(date: currentDate, readiness: readiness)

        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate) ?? currentDate.addingTimeInterval(900)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        return timeline
    }
}
