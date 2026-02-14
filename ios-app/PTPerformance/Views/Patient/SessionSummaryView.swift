import SwiftUI

/// Session Summary View - Build 60: Enhanced with PRs and motivational messages
/// BUILD 311: Shows stored session metrics (from completion) instead of recalculating
/// Shows metrics after completing a session: exercises, volume, duration, PRs, compliance
struct SessionSummaryView: View {
    let session: Session
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState

    // BUILD 311: Use session's stored metrics directly instead of recalculating
    // This prevents showing wrong data when exercise logs are from different sessions/times
    private var hasStoredMetrics: Bool {
        session.duration_minutes != nil || session.total_volume != nil
    }

    // BUILD 311: Motivational messages based on workout performance
    private var motivationalMessage: String {
        let messages = [
            "Great work completing your session!",
            "Another workout in the books!",
            "You're building strength one session at a time!",
            "Consistency is key - keep it up!",
            "Well done on finishing today's workout!"
        ]
        // Use session ID to pick a consistent message
        let index = abs(session.id.hashValue) % messages.count
        return messages[index]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Success Header
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.green)

                        Text("Session Complete!")
                            .font(.title)
                            .bold()

                        Text(session.name)
                            .font(.title3)
                            .foregroundColor(.secondary)

                        if let completedAt = session.completed_at {
                            Text(formatDate(completedAt))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        // Motivational Message
                        Text(motivationalMessage)
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.modusCyan.opacity(0.1))
                            .cornerRadius(CornerRadius.md)
                            .padding(.horizontal)
                            .padding(.top, Spacing.xs)
                    }
                    .padding(.top, Spacing.xl)

                    // BUILD 311: Stats Grid using stored session metrics
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        // Volume
                        StatCard(
                            title: "Volume",
                            value: formatVolume(session.total_volume ?? 0),
                            icon: "scalemass.fill",
                            color: .purple
                        )

                        // Duration
                        StatCard(
                            title: "Duration",
                            value: formatDuration(session.duration_minutes ?? 0),
                            icon: "clock.fill",
                            color: .orange
                        )

                        // RPE (if tracked)
                        if let rpe = session.avg_rpe {
                            StatCard(
                                title: "Avg RPE",
                                value: String(format: "%.1f", rpe),
                                icon: "bolt.fill",
                                color: rpeColor(rpe)
                            )
                        }

                        // Pain (if tracked)
                        if let pain = session.avg_pain {
                            StatCard(
                                title: "Avg Pain",
                                value: String(format: "%.1f", pain),
                                icon: "hand.raised.fill",
                                color: painColor(pain)
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Done Button
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Done")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.modusCyan)
                            .foregroundColor(.white)
                            .cornerRadius(CornerRadius.md)
                    }
                    .padding(.horizontal)
                    .padding(.top, Spacing.md)

                    Spacer()
                }
            }
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // BUILD 311: Format duration in human-readable form
    private func formatDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(mins)m"
        }
        return "\(minutes) min"
    }

    // Legacy metrics view (Build 33 format)
    @ViewBuilder
    private var legacyMetricsView: some View {
        VStack(spacing: 16) {
            if let volume = session.total_volume, volume > 0 {
                MetricCard(
                    title: "Total Volume",
                    value: formatVolume(volume),
                    icon: "scalemass.fill",
                    color: .blue
                )
            }

            if let rpe = session.avg_rpe {
                MetricCard(
                    title: "Average RPE",
                    value: formatScore(rpe),
                    subtitle: "out of 10",
                    icon: "bolt.fill",
                    color: rpeColor(rpe)
                )
            }

            if let pain = session.avg_pain {
                MetricCard(
                    title: "Average Pain",
                    value: formatScore(pain),
                    subtitle: "out of 10",
                    icon: "hand.raised.fill",
                    color: painColor(pain)
                )
            }

            if let duration = session.duration_minutes, duration > 0 {
                MetricCard(
                    title: "Duration",
                    value: "\(duration) min",
                    icon: "clock.fill",
                    color: .purple
                )
            }
        }
        .padding(.horizontal)
    }

    private static let mediumDateShortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    // MARK: - Formatting Helpers

    private func formatDate(_ date: Date) -> String {
        Self.mediumDateShortTimeFormatter.string(from: date)
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk lbs", volume / 1000)
        }
        return String(format: "%.0f lbs", volume)
    }

    private func formatScore(_ score: Double) -> String {
        return String(format: "%.1f", score)
    }

    // MARK: - Color Helpers

    private func rpeColor(_ rpe: Double) -> Color {
        switch rpe {
        case 0..<4:
            return .green
        case 4..<7:
            return .yellow
        case 7..<9:
            return .orange
        default:
            return .red
        }
    }

    private func painColor(_ pain: Double) -> Color {
        switch pain {
        case 0..<3:
            return .green
        case 3..<6:
            return .yellow
        case 6..<8:
            return .orange
        default:
            return .red
        }
    }

    private func complianceColor(_ compliance: Double) -> Color {
        switch compliance {
        case 95...:
            return .green
        case 80..<95:
            return .blue
        case 60..<80:
            return .yellow
        default:
            return .orange
        }
    }
}

// MARK: - Stat Card Component (Build 60)
// Made private to avoid conflict with Analytics chart StatCard views

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .bold()

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }
}

/// Metric Card Component
struct MetricCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
                .frame(width: 60, height: 60)
                .background(color.opacity(0.1))
                .cornerRadius(CornerRadius.md)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.title2)
                        .bold()

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator), lineWidth: 1)
        )
        .adaptiveShadow(Shadow.subtle)
    }
}

// MARK: - Preview

struct SessionSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        SessionSummaryView(session: Session(
            id: UUID(),
            phase_id: UUID(),
            name: "Upper Body Strength",
            sequence: 1,
            weekday: 1,
            notes: nil,
            created_at: Date(),
            completed: true,
            started_at: Date().addingTimeInterval(-2700), // BUILD 123: 45 min ago
            completed_at: Date(),
            total_volume: 12500.50,
            avg_rpe: 7.5,
            avg_pain: 3.2,
            duration_minutes: 45
        ))
    }
}
