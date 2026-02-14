//
//  RecentActivityFeed.swift
//  PTPerformance
//
//  Timeline component showing recent patient events
//  Displays completions, PRs, drop-offs, and milestones
//

import SwiftUI

// MARK: - Recent Activity Feed

struct RecentActivityFeed: View {
    let activities: [RecentActivityEvent]
    var onActivityTap: ((RecentActivityEvent) -> Void)?
    var onViewAll: (() -> Void)?
    var maxItems: Int = 10

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                Label {
                    Text("Recent Activity")
                        .font(.headline)
                } icon: {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.modusCyan)
                }

                Spacer()

                if activities.count > maxItems {
                    Button(action: { onViewAll?() }) {
                        Text("View All")
                            .font(.subheadline)
                            .foregroundColor(.modusCyan)
                    }
                }
            }
            .accessibilityAddTraits(.isHeader)

            if activities.isEmpty {
                // Empty state
                HStack {
                    Spacer()
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "tray")
                            .font(.largeTitle)
                            .foregroundColor(.secondary.opacity(0.5))

                        Text("No recent activity")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, Spacing.lg)
                    Spacer()
                }
            } else {
                // Activity timeline
                VStack(spacing: 0) {
                    ForEach(Array(activities.prefix(maxItems).enumerated()), id: \.element.id) { index, activity in
                        ActivityTimelineItem(
                            activity: activity,
                            isLast: index == min(maxItems - 1, activities.count - 1),
                            onTap: {
                                onActivityTap?(activity)
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.medium)
    }
}

// MARK: - Activity Timeline Item

struct ActivityTimelineItem: View {
    let activity: RecentActivityEvent
    let isLast: Bool
    var onTap: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(alignment: .top, spacing: Spacing.md) {
                // Timeline indicator
                VStack(spacing: 0) {
                    // Icon circle
                    ZStack {
                        Circle()
                            .fill(activity.eventType.color.opacity(0.2))
                            .frame(width: 36, height: 36)

                        Image(systemName: activity.eventType.icon)
                            .font(.subheadline)
                            .foregroundColor(activity.eventType.color)
                    }

                    // Connecting line
                    if !isLast {
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(width: 2)
                            .frame(maxHeight: .infinity)
                    }
                }
                .frame(width: 36)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    // Patient name and event type
                    HStack {
                        Text(activity.patientName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        Spacer()

                        Text(timeAgoText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Event description
                    Text(activity.eventType.displayName)
                        .font(.caption)
                        .foregroundColor(activity.eventType.color)

                    // Details if available
                    if let details = activity.details {
                        Text(details)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(.bottom, isLast ? 0 : Spacing.md)

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(activity.patientName), \(activity.eventType.displayName), \(timeAgoText)")
        .accessibilityHint("Double tap to view patient")
    }

    private var timeAgoText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: activity.timestamp, relativeTo: Date())
    }
}

// MARK: - Compact Activity Row

/// Simpler row format for compact displays
struct CompactActivityRow: View {
    let activity: RecentActivityEvent
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: Spacing.sm) {
                // Event type icon
                Image(systemName: activity.eventType.icon)
                    .font(.caption)
                    .foregroundColor(activity.eventType.color)
                    .frame(width: 20)

                // Patient name
                Text(activity.patientName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                // Event badge
                Text(activity.eventType.displayName)
                    .font(.caption2)
                    .foregroundColor(activity.eventType.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(activity.eventType.color.opacity(0.15))
                    .cornerRadius(CornerRadius.xs)

                Spacer()

                // Time
                Text(shortTimeAgo)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var shortTimeAgo: String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: activity.timestamp, to: now)

        if let days = components.day, days > 0 {
            return "\(days)d"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m"
        } else {
            return "now"
        }
    }
}

// MARK: - Activity Summary Bar

/// Horizontal scrolling summary of recent activities
struct ActivitySummaryBar: View {
    let activities: [RecentActivityEvent]
    var onActivityTap: ((RecentActivityEvent) -> Void)?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(activities.prefix(5)) { activity in
                    ActivitySummaryChip(activity: activity) {
                        onActivityTap?(activity)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct ActivitySummaryChip: View {
    let activity: RecentActivityEvent
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 6) {
                Image(systemName: activity.eventType.icon)
                    .font(.caption2)
                    .foregroundColor(activity.eventType.color)

                Text(activity.patientName.components(separatedBy: " ").first ?? activity.patientName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 6)
            .background(activity.eventType.color.opacity(0.1))
            .cornerRadius(CornerRadius.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Activity Filter Pills

/// Filter pills for activity types
struct ActivityFilterPills: View {
    @Binding var selectedTypes: Set<RecentActivityEvent.EventType>
    let availableTypes: [RecentActivityEvent.EventType]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                // All filter
                ActivityFilterPill(
                    title: "All",
                    isSelected: selectedTypes.isEmpty,
                    color: .blue
                ) {
                    selectedTypes.removeAll()
                }

                ForEach(availableTypes, id: \.self) { type in
                    ActivityFilterPill(
                        title: type.displayName,
                        isSelected: selectedTypes.contains(type),
                        color: type.color
                    ) {
                        if selectedTypes.contains(type) {
                            selectedTypes.remove(type)
                        } else {
                            selectedTypes.insert(type)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct ActivityFilterPill: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 6)
                .background(isSelected ? color : color.opacity(0.15))
                .cornerRadius(CornerRadius.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#if DEBUG
struct RecentActivityFeed_Previews: PreviewProvider {
    static var sampleActivities: [RecentActivityEvent] = [
        RecentActivityEvent(
            id: UUID(),
            patientId: UUID(),
            patientName: "John Brebbia",
            eventType: .sessionCompleted,
            timestamp: Date().addingTimeInterval(-1800),
            details: "Completed Upper Body Strength session"
        ),
        RecentActivityEvent(
            id: UUID(),
            patientId: UUID(),
            patientName: "Sarah Johnson",
            eventType: .personalRecord,
            timestamp: Date().addingTimeInterval(-7200),
            details: "New PR: Bench Press 185 lbs"
        ),
        RecentActivityEvent(
            id: UUID(),
            patientId: UUID(),
            patientName: "Mike Williams",
            eventType: .dropOff,
            timestamp: Date().addingTimeInterval(-86400),
            details: "Adherence dropped below 50%"
        ),
        RecentActivityEvent(
            id: UUID(),
            patientId: UUID(),
            patientName: "Emily Chen",
            eventType: .milestone,
            timestamp: Date().addingTimeInterval(-172800),
            details: "Completed 30-day streak!"
        ),
        RecentActivityEvent(
            id: UUID(),
            patientId: UUID(),
            patientName: "Tom Davis",
            eventType: .programStarted,
            timestamp: Date().addingTimeInterval(-259200),
            details: "Started ACL Recovery Phase 2"
        )
    ]

    static var previews: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Full feed
                RecentActivityFeed(
                    activities: sampleActivities,
                    onActivityTap: { activity in
                        print("Tapped: \(activity.patientName)")
                    },
                    onViewAll: {
                        print("View all activities")
                    }
                )

                // Summary bar
                Text("Summary Bar")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                ActivitySummaryBar(
                    activities: sampleActivities,
                    onActivityTap: { activity in
                        print("Tapped chip: \(activity.patientName)")
                    }
                )

                // Empty state
                RecentActivityFeed(
                    activities: [],
                    onActivityTap: nil,
                    onViewAll: nil
                )
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
