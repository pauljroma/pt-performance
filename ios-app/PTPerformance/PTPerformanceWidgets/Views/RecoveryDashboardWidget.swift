import WidgetKit
import SwiftUI

struct RecoveryDashboardWidget: Widget {
    let kind: String = SharedDataStore.WidgetKind.recoveryDashboard

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecoveryDashboardProvider()) { entry in
            RecoveryDashboardWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Recovery Dashboard")
        .description("Complete recovery overview with HRV, sleep, and trends.")
        .supportedFamilies([.systemLarge])
    }
}

struct RecoveryDashboardWidgetView: View {
    let entry: RecoveryDashboardEntry

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Recovery Dashboard")
                    .font(.headline)
                Spacer()
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Main content
            HStack(spacing: 16) {
                // Readiness Circle
                if let readiness = entry.readiness {
                    ReadinessBadge(score: readiness.score, band: readiness.band, size: .large)
                } else {
                    ReadinessBadge(score: 0, band: "gray", size: .large)
                }

                // Metrics Grid
                VStack(alignment: .leading, spacing: 8) {
                    MetricRow(
                        icon: "waveform.path.ecg",
                        label: "HRV",
                        value: entry.readiness?.hrv.map { "\(Int($0)) ms" } ?? "--",
                        color: .purple
                    )

                    MetricRow(
                        icon: "moon.fill",
                        label: "Sleep",
                        value: entry.readiness?.sleepHours.map { String(format: "%.1fh", $0) } ?? "--",
                        color: .indigo
                    )

                    MetricRow(
                        icon: "heart.fill",
                        label: "RHR",
                        value: entry.readiness?.restingHR.map { "\($0) bpm" } ?? "--",
                        color: .red
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            // 7-Day Trend
            VStack(alignment: .leading, spacing: 4) {
                Text("7-Day Trend")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let trend = entry.weekTrend, !trend.isEmpty {
                    let scores = trend.map { $0.score }
                    MiniTrendChart(data: scores)
                        .frame(height: 50)
                } else {
                    MiniTrendChart(data: [50, 50, 50, 50, 50, 50, 50])
                        .frame(height: 50)
                        .opacity(0.3)
                }
            }

            Divider()

            // Today's Workout
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(.blue)

                if let workout = entry.workout {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Today: \(workout.name)")
                            .font(.caption)
                            .fontWeight(.medium)

                        HStack(spacing: 8) {
                            if let minutes = workout.estimatedMinutes {
                                Label("\(minutes) min", systemImage: "clock")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            HStack(spacing: 2) {
                                Image(systemName: workout.status.iconName)
                                Text(workout.status.displayText)
                            }
                            .font(.caption2)
                            .foregroundStyle(statusColor(workout.status))
                        }
                    }
                } else {
                    Text("Rest Day - Recovery Focus")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .padding(.horizontal, 4)
        .widgetURL(URL(string: "modus://recovery"))
    }

    private func statusColor(_ status: WidgetWorkout.WorkoutStatus) -> Color {
        switch status {
        case .scheduled: return .blue
        case .inProgress: return .orange
        case .completed: return .green
        case .skipped: return .red
        case .restDay: return .purple
        }
    }
}

// MARK: - Metric Row Component

struct MetricRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 16)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

@available(iOS 17.0, *)
#Preview(as: .systemLarge) {
    RecoveryDashboardWidget()
} timeline: {
    RecoveryDashboardEntry(
        date: .now,
        readiness: .placeholder,
        weekTrend: nil,
        workout: .placeholder
    )
}
