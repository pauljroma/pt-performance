//
//  WeeklySummaryCard.swift
//  PTPerformance
//
//  Weekly Summary Card component for HistoryView
//  Shows workout summary with comparison to previous week
//

import SwiftUI

// MARK: - Weekly Summary Data Model

/// Data model for weekly workout summary
struct WeeklySummaryData: Equatable {
    let sessionsCompleted: Int
    let totalVolume: Double // in lbs
    let totalTimeMinutes: Int
    let previousWeekSessions: Int?
    let previousWeekVolume: Double?
    let previousWeekTimeMinutes: Int?

    // MARK: - Computed Comparison Properties

    var sessionsDelta: Int? {
        guard let previous = previousWeekSessions else { return nil }
        return sessionsCompleted - previous
    }

    var sessionsPercentChange: Double? {
        guard let previous = previousWeekSessions, previous > 0 else { return nil }
        return Double(sessionsCompleted - previous) / Double(previous)
    }

    var volumeDelta: Double? {
        guard let previous = previousWeekVolume else { return nil }
        return totalVolume - previous
    }

    var volumePercentChange: Double? {
        guard let previous = previousWeekVolume, previous > 0 else { return nil }
        return (totalVolume - previous) / previous
    }

    var timeDelta: Int? {
        guard let previous = previousWeekTimeMinutes else { return nil }
        return totalTimeMinutes - previous
    }

    var timePercentChange: Double? {
        guard let previous = previousWeekTimeMinutes, previous > 0 else { return nil }
        return Double(totalTimeMinutes - previous) / Double(previous)
    }

    // MARK: - Empty State Check

    var isEmpty: Bool {
        sessionsCompleted == 0 && totalVolume == 0 && totalTimeMinutes == 0
    }

    // MARK: - Sample Data

    static let sample = WeeklySummaryData(
        sessionsCompleted: 4,
        totalVolume: 12500,
        totalTimeMinutes: 180,
        previousWeekSessions: 3,
        previousWeekVolume: 10200,
        previousWeekTimeMinutes: 150
    )

    static let empty = WeeklySummaryData(
        sessionsCompleted: 0,
        totalVolume: 0,
        totalTimeMinutes: 0,
        previousWeekSessions: nil,
        previousWeekVolume: nil,
        previousWeekTimeMinutes: nil
    )
}

// MARK: - Weekly Summary Card View

/// Card component displaying weekly workout summary with comparison to previous week
struct WeeklySummaryCard: View {
    let data: WeeklySummaryData

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.title3)
                    .foregroundColor(.blue)

                Text("This Week")
                    .font(.headline)

                Spacer()

                Text(weekDateRange)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if data.isEmpty {
                // Empty State
                emptyStateView
            } else {
                // Stats Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    // Sessions
                    WeeklySummaryStatItem(
                        icon: "figure.strengthtraining.traditional",
                        iconColor: .blue,
                        title: "Sessions",
                        value: "\(data.sessionsCompleted)",
                        percentChange: data.sessionsPercentChange
                    )

                    // Volume
                    WeeklySummaryStatItem(
                        icon: "scalemass.fill",
                        iconColor: .purple,
                        title: "Volume",
                        value: formatVolume(data.totalVolume),
                        percentChange: data.volumePercentChange
                    )

                    // Time
                    WeeklySummaryStatItem(
                        icon: "clock.fill",
                        iconColor: .orange,
                        title: "Time",
                        value: formatDuration(data.totalTimeMinutes),
                        percentChange: data.timePercentChange
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.medium)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.walk")
                .font(.system(size: 36))
                .foregroundColor(.secondary.opacity(0.6))

            Text("No workouts yet this week")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Complete a session to see your weekly summary")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Helper Functions

    private var weekDateRange: String {
        let calendar = Calendar.current
        let today = Date()
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return ""
        }
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? today

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        return "\(formatter.string(from: weekStart)) - \(formatter.string(from: weekEnd))"
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(mins)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - Stat Item Component

/// Individual stat item for the weekly summary card
private struct WeeklySummaryStatItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let percentChange: Double?

    var body: some View {
        VStack(spacing: 8) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)

            // Value
            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            // Title
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            // Comparison badge
            if let change = percentChange {
                ComparisonBadge(percentChange: change)
            } else {
                // Placeholder to maintain consistent height
                Text(" ")
                    .font(.caption2)
                    .frame(height: 16)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Comparison Badge

/// Badge showing percentage change with up/down arrow
private struct ComparisonBadge: View {
    let percentChange: Double

    private var isPositive: Bool {
        percentChange > 0
    }

    private var isNeutral: Bool {
        abs(percentChange) < 0.01
    }

    private var displayText: String {
        if isNeutral {
            return "Same"
        }
        let percentage = abs(percentChange * 100)
        if percentage < 1 {
            return String(format: "%.1f%%", percentage)
        }
        return String(format: "%.0f%%", percentage)
    }

    private var iconName: String {
        if isNeutral {
            return "minus"
        }
        return isPositive ? "arrow.up" : "arrow.down"
    }

    private var badgeColor: Color {
        if isNeutral {
            return .gray
        }
        return isPositive ? .green : .red
    }

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: iconName)
                .font(.system(size: 8, weight: .bold))

            Text(displayText)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(badgeColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(badgeColor.opacity(0.15))
        .cornerRadius(CornerRadius.xs)
    }
}

// MARK: - Compact Weekly Summary Card

/// Compact version of weekly summary card for smaller spaces
struct CompactWeeklySummaryCard: View {
    let data: WeeklySummaryData

    var body: some View {
        HStack(spacing: 20) {
            // Sessions
            CompactStatItem(
                icon: "figure.strengthtraining.traditional",
                iconColor: .blue,
                value: "\(data.sessionsCompleted)",
                label: "sessions",
                change: data.sessionsPercentChange
            )

            Divider()
                .frame(height: 40)

            // Volume
            CompactStatItem(
                icon: "scalemass.fill",
                iconColor: .purple,
                value: formatVolume(data.totalVolume),
                label: "volume",
                change: data.volumePercentChange
            )

            Divider()
                .frame(height: 40)

            // Time
            CompactStatItem(
                icon: "clock.fill",
                iconColor: .orange,
                value: formatDuration(data.totalTimeMinutes),
                label: "time",
                change: data.timePercentChange
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            }
            return "\(hours)h\(mins)m"
        }
        return "\(minutes)m"
    }
}

/// Compact stat item for horizontal layout
private struct CompactStatItem: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    let change: Double?

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(iconColor)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)

                if let change = change {
                    Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(change >= 0 ? .green : .red)
                }
            }

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct WeeklySummaryCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Full card with data
                WeeklySummaryCard(data: .sample)
                    .padding(.horizontal)

                // Full card with increases
                WeeklySummaryCard(data: WeeklySummaryData(
                    sessionsCompleted: 5,
                    totalVolume: 15000,
                    totalTimeMinutes: 210,
                    previousWeekSessions: 3,
                    previousWeekVolume: 10000,
                    previousWeekTimeMinutes: 150
                ))
                .padding(.horizontal)

                // Full card with decreases
                WeeklySummaryCard(data: WeeklySummaryData(
                    sessionsCompleted: 2,
                    totalVolume: 8000,
                    totalTimeMinutes: 90,
                    previousWeekSessions: 4,
                    previousWeekVolume: 12000,
                    previousWeekTimeMinutes: 180
                ))
                .padding(.horizontal)

                // Full card without comparison
                WeeklySummaryCard(data: WeeklySummaryData(
                    sessionsCompleted: 3,
                    totalVolume: 9500,
                    totalTimeMinutes: 120,
                    previousWeekSessions: nil,
                    previousWeekVolume: nil,
                    previousWeekTimeMinutes: nil
                ))
                .padding(.horizontal)

                // Empty state
                WeeklySummaryCard(data: .empty)
                    .padding(.horizontal)

                // Compact version
                CompactWeeklySummaryCard(data: .sample)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .previewDisplayName("Weekly Summary Cards")
    }
}
#endif
