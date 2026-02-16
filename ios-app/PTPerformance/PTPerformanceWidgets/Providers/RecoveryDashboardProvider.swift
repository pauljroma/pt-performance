import WidgetKit
import SwiftUI

struct RecoveryDashboardEntry: TimelineEntry {
    let date: Date
    let readiness: WidgetReadiness?
    let weekTrend: [WidgetReadiness]?
    let workout: WidgetWorkout?
}

struct RecoveryDashboardProvider: TimelineProvider {
    typealias Entry = RecoveryDashboardEntry

    func placeholder(in context: Context) -> RecoveryDashboardEntry {
        RecoveryDashboardEntry(
            date: Date(),
            readiness: .placeholder,
            weekTrend: generatePlaceholderTrend(),
            workout: .placeholder
        )
    }

    func getSnapshot(in context: Context) async -> RecoveryDashboardEntry {
        let entry = RecoveryDashboardEntry(
            date: Date(),
            readiness: SharedDataStore.shared.getReadiness() ?? .placeholder,
            weekTrend: SharedDataStore.shared.getWeekTrend() ?? generatePlaceholderTrend(),
            workout: SharedDataStore.shared.getWorkout()
        )
        return entry
    }

    func getTimeline(in context: Context) async -> Timeline<RecoveryDashboardEntry> {
        let currentDate = Date()

        let entry = RecoveryDashboardEntry(
            date: currentDate,
            readiness: SharedDataStore.shared.getReadiness(),
            weekTrend: SharedDataStore.shared.getWeekTrend(),
            workout: SharedDataStore.shared.getWorkout()
        )

        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate) ?? currentDate.addingTimeInterval(1800)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        return timeline
    }

    private func generatePlaceholderTrend() -> [WidgetReadiness] {
        let calendar = Calendar.current
        let today = Date()

        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: -6 + offset, to: today) ?? today
            let scores = [85, 72, 90, 65, 78, 55, 88]
            let bands = ["green", "yellow", "green", "orange", "yellow", "red", "green"]
            let hrvValues = [65.0, 58.0, 72.0, 52.0, 60.0, 45.0, 70.0]
            let sleepValues = [7.5, 6.8, 8.0, 6.2, 7.0, 5.5, 7.8]
            let hrValues = [62, 58, 55, 65, 60, 68, 56]
            return WidgetReadiness(
                score: scores[offset],
                band: bands[offset],
                hrv: hrvValues[offset],
                sleepHours: sleepValues[offset],
                restingHR: hrValues[offset],
                date: date
            )
        }
    }
}
