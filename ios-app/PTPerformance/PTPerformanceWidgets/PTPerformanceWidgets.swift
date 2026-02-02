import WidgetKit
import SwiftUI

@main
struct PTPerformanceWidgets: WidgetBundle {
    var body: some Widget {
        ReadinessWidget()
        TodayWorkoutWidget()
        StreakWidget()
        DailySummaryWidget()
        WeekOverviewWidget()
        RecoveryDashboardWidget()
    }
}
