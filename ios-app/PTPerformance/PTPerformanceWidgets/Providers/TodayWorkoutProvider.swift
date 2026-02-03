import WidgetKit
import SwiftUI

struct TodayWorkoutEntry: TimelineEntry {
    let date: Date
    let workout: WidgetWorkout?
}

struct TodayWorkoutProvider: TimelineProvider {
    typealias Entry = TodayWorkoutEntry

    func placeholder(in context: Context) -> TodayWorkoutEntry {
        TodayWorkoutEntry(date: Date(), workout: .placeholder)
    }

    func getSnapshot(in context: Context) async -> TodayWorkoutEntry {
        let entry = TodayWorkoutEntry(
            date: Date(),
            workout: SharedDataStore.shared.getWorkout() ?? .placeholder
        )
        return entry
    }

    func getTimeline(in context: Context) async -> Timeline<TodayWorkoutEntry> {
        let currentDate = Date()
        let workout = SharedDataStore.shared.getWorkout()

        let entry = TodayWorkoutEntry(date: currentDate, workout: workout)

        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate) ?? currentDate.addingTimeInterval(900)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        return timeline
    }
}
