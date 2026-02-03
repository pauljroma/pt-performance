import WidgetKit
import SwiftUI

struct StreakEntry: TimelineEntry {
    let date: Date
    let streak: WidgetStreak?
}

struct StreakProvider: TimelineProvider {
    typealias Entry = StreakEntry

    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: Date(), streak: .placeholder)
    }

    func getSnapshot(in context: Context) async -> StreakEntry {
        let entry = StreakEntry(
            date: Date(),
            streak: SharedDataStore.shared.getStreak() ?? .placeholder
        )
        return entry
    }

    func getTimeline(in context: Context) async -> Timeline<StreakEntry> {
        let currentDate = Date()
        let streak = SharedDataStore.shared.getStreak()

        let entry = StreakEntry(date: currentDate, streak: streak)

        // Refresh every hour (streaks don't change frequently)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate) ?? currentDate.addingTimeInterval(3600)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        return timeline
    }
}
