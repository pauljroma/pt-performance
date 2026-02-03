import WidgetKit
import SwiftUI

struct DailySummaryEntry: TimelineEntry {
    let date: Date
    let readiness: WidgetReadiness?
    let workout: WidgetWorkout?
    let fatigueBand: String?
}

struct DailySummaryProvider: TimelineProvider {
    typealias Entry = DailySummaryEntry

    func placeholder(in context: Context) -> DailySummaryEntry {
        DailySummaryEntry(
            date: Date(),
            readiness: .placeholder,
            workout: .placeholder,
            fatigueBand: "low"
        )
    }

    func getSnapshot(in context: Context) async -> DailySummaryEntry {
        let entry = DailySummaryEntry(
            date: Date(),
            readiness: SharedDataStore.shared.getReadiness() ?? .placeholder,
            workout: SharedDataStore.shared.getWorkout() ?? .placeholder,
            fatigueBand: "low"
        )
        return entry
    }

    func getTimeline(in context: Context) async -> Timeline<DailySummaryEntry> {
        let currentDate = Date()

        let entry = DailySummaryEntry(
            date: currentDate,
            readiness: SharedDataStore.shared.getReadiness(),
            workout: SharedDataStore.shared.getWorkout(),
            fatigueBand: nil // Will be fetched from fatigue data in future
        )

        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate) ?? currentDate.addingTimeInterval(1800)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        return timeline
    }
}
