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

    func getSnapshot(in context: Context, completion: @escaping (TodayWorkoutEntry) -> Void) {
        let entry = TodayWorkoutEntry(
            date: Date(),
            workout: SharedDataStore.shared.getWorkout() ?? .placeholder
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayWorkoutEntry>) -> Void) {
        let currentDate = Date()
        let workout = SharedDataStore.shared.getWorkout()

        let entry = TodayWorkoutEntry(date: currentDate, workout: workout)

        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
