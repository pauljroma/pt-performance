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

    func getSnapshot(in context: Context, completion: @escaping (RecoveryDashboardEntry) -> Void) {
        let entry = RecoveryDashboardEntry(
            date: Date(),
            readiness: SharedDataStore.shared.getReadiness() ?? .placeholder,
            weekTrend: SharedDataStore.shared.getWeekTrend() ?? generatePlaceholderTrend(),
            workout: SharedDataStore.shared.getWorkout()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RecoveryDashboardEntry>) -> Void) {
        let currentDate = Date()

        let entry = RecoveryDashboardEntry(
            date: currentDate,
            readiness: SharedDataStore.shared.getReadiness(),
            weekTrend: SharedDataStore.shared.getWeekTrend(),
            workout: SharedDataStore.shared.getWorkout()
        )

        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func generatePlaceholderTrend() -> [WidgetReadiness] {
        let calendar = Calendar.current
        let today = Date()

        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: -6 + offset, to: today)!
            let scores = [85, 72, 90, 65, 78, 55, 88]
            let bands = ["green", "yellow", "green", "orange", "yellow", "red", "green"]
            return WidgetReadiness(
                score: scores[offset],
                band: bands[offset],
                hrv: Double.random(in: 50...80),
                sleepHours: Double.random(in: 6...9),
                restingHR: Int.random(in: 48...62),
                date: date
            )
        }
    }
}
