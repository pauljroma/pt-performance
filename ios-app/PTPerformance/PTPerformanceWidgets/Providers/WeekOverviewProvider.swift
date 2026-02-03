import WidgetKit
import SwiftUI

struct WeekOverviewEntry: TimelineEntry {
    let date: Date
    let adherence: WidgetAdherence?
    let nextWorkout: WidgetWorkout?
}

struct WeekOverviewProvider: TimelineProvider {
    typealias Entry = WeekOverviewEntry

    func placeholder(in context: Context) -> WeekOverviewEntry {
        WeekOverviewEntry(
            date: Date(),
            adherence: .placeholder,
            nextWorkout: .placeholder
        )
    }

    func getSnapshot(in context: Context) async -> WeekOverviewEntry {
        let entry = WeekOverviewEntry(
            date: Date(),
            adherence: SharedDataStore.shared.getAdherence() ?? .placeholder,
            nextWorkout: SharedDataStore.shared.getWorkout() ?? .placeholder
        )
        return entry
    }

    func getTimeline(in context: Context) async -> Timeline<WeekOverviewEntry> {
        let currentDate = Date()

        let entry = WeekOverviewEntry(
            date: currentDate,
            adherence: SharedDataStore.shared.getAdherence(),
            nextWorkout: SharedDataStore.shared.getWorkout()
        )

        // Refresh every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate) ?? currentDate.addingTimeInterval(3600)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        return timeline
    }
}
