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

    func getSnapshot(in context: Context, completion: @escaping (ReadinessEntry) -> Void) {
        let entry = ReadinessEntry(
            date: Date(),
            readiness: SharedDataStore.shared.getReadiness() ?? .placeholder
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReadinessEntry>) -> Void) {
        let currentDate = Date()
        let readiness = SharedDataStore.shared.getReadiness()

        let entry = ReadinessEntry(date: currentDate, readiness: readiness)

        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
