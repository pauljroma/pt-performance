//
//  TimelineEventCard.swift
//  PTPerformance
//
//  X2Index Phase 2 - Canonical Timeline (M3)
//  Expandable event card with timeline indicator
//

import SwiftUI

/// Expandable card displaying a timeline event
struct TimelineEventCard: View {

    // MARK: - Properties

    let event: TimelineEvent
    let isExpanded: Bool
    let isLastInSection: Bool
    let detail: TimelineEventDetail?
    let onTap: () -> Void

    // MARK: - State

    @State private var animateConflict = false

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            // Timeline indicator
            timelineIndicator

            // Event content
            VStack(alignment: .leading, spacing: 0) {
                // Main card content
                cardContent
                    .padding(Spacing.sm)
                    .background(cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            onTap()
                        }
                    }

                // Expanded detail view
                if isExpanded, let detail = detail {
                    expandedContent(detail: detail)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity
                        ))
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .onAppear {
            if event.hasConflicts {
                startConflictAnimation()
            }
        }
    }

    // MARK: - Timeline Indicator

    private var timelineIndicator: some View {
        VStack(spacing: 0) {
            // Event type dot
            ZStack {
                Circle()
                    .fill(event.eventType.color)
                    .frame(width: 12, height: 12)

                if event.hasConflicts {
                    Circle()
                        .stroke(ConflictGroup.ConflictType.sourceDisagreement.color, lineWidth: 2)
                        .frame(width: 16, height: 16)
                        .scaleEffect(animateConflict ? 1.3 : 1.0)
                        .opacity(animateConflict ? 0 : 1)
                }
            }

            // Connecting line
            if !isLastInSection {
                Rectangle()
                    .fill(Color(.separator))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 20)
    }

    // MARK: - Card Content

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Header row
            HStack(alignment: .center, spacing: Spacing.xs) {
                // Event icon
                Image(systemName: event.eventType.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(event.eventType.color)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(event.eventType.color.opacity(0.15))
                    )

                // Title
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()

                // Conflict badge
                if event.hasConflicts {
                    conflictBadge
                }

                // Time
                Text(event.formattedTime)
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Expand indicator
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }

            // Summary
            Text(event.summary)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(isExpanded ? nil : 2)

            // Source indicator
            HStack(spacing: 4) {
                Image(systemName: event.sourceType.iconName)
                    .font(.caption2)
                Text(event.sourceType.displayName)
                    .font(.caption2)
            }
            .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Conflict Badge

    private var conflictBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption2)
            Text("\(event.conflictCount)")
                .font(.caption2.weight(.semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color.orange)
        )
        .accessibilityLabel("\(event.conflictCount) conflict\(event.conflictCount == 1 ? "" : "s")")
    }

    // MARK: - Expanded Content

    private func expandedContent(detail: TimelineEventDetail) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Divider()
                .padding(.top, Spacing.xs)

            // Detail sections
            ForEach(detail.detailSections) { section in
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(section.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)

                    ForEach(section.items) { item in
                        detailItemRow(item: item)
                    }
                }
                .padding(.horizontal, Spacing.xs)
            }

            // Conflicting events section
            if let conflicts = detail.conflictingEvents, !conflicts.isEmpty {
                conflictingEventsSection(conflicts: conflicts)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.bottom, Spacing.sm)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(
            UnevenRoundedRectangle(
                bottomLeadingRadius: CornerRadius.md,
                bottomTrailingRadius: CornerRadius.md
            )
        )
    }

    private func detailItemRow(item: TimelineEventDetail.DetailItem) -> some View {
        HStack(spacing: Spacing.xs) {
            if let icon = item.icon {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
            }

            Text(item.label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(item.value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(item.valueColor.flatMap { Color($0) } ?? .primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 2)
    }

    private func conflictingEventsSection(conflicts: [TimelineEvent]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Conflicting Data")
                    .font(.subheadline.weight(.semibold))
            }

            ForEach(conflicts) { conflict in
                HStack(spacing: Spacing.xs) {
                    Image(systemName: conflict.sourceType.iconName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 20)

                    Text(conflict.sourceType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(conflict.summary)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.orange.opacity(0.1))
                )
            }
        }
        .padding(.horizontal, Spacing.xs)
    }

    // MARK: - Card Background

    private var cardBackground: some View {
        Group {
            if event.hasConflicts {
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color(.secondarySystemGroupedBackground))
            }
        }
    }

    // MARK: - Helpers

    private func startConflictAnimation() {
        withAnimation(
            Animation
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: false)
        ) {
            animateConflict = true
        }
    }
}

// MARK: - Section Header

/// Section header for grouped timeline events
struct TimelineSectionHeader: View {

    let title: String
    let eventCount: Int

    var body: some View {
        HStack {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundColor(.primary)

            Spacer()

            Text("\(eventCount) event\(eventCount == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .padding(.leading, 20 + Spacing.sm) // Align with card content
    }
}

// MARK: - Previews

#Preview("Event Card - Collapsed") {
    ScrollView {
        VStack(spacing: 0) {
            TimelineEventCard(
                event: .sample,
                isExpanded: false,
                isLastInSection: false,
                detail: nil,
                onTap: {}
            )

            TimelineEventCard(
                event: .sampleWorkout,
                isExpanded: false,
                isLastInSection: false,
                detail: nil,
                onTap: {}
            )

            TimelineEventCard(
                event: .sampleSleep,
                isExpanded: false,
                isLastInSection: true,
                detail: nil,
                onTap: {}
            )
        }
    }
}

#Preview("Event Card - Expanded") {
    ScrollView {
        TimelineEventCard(
            event: .sample,
            isExpanded: true,
            isLastInSection: true,
            detail: .sample,
            onTap: {}
        )
    }
}

#Preview("Event Card - With Conflict") {
    ScrollView {
        TimelineEventCard(
            event: .sampleWithConflict,
            isExpanded: false,
            isLastInSection: true,
            detail: nil,
            onTap: {}
        )
    }
}

#Preview("Section Header") {
    VStack {
        TimelineSectionHeader(title: "Today", eventCount: 5)
        TimelineSectionHeader(title: "Yesterday", eventCount: 3)
        TimelineSectionHeader(title: "This Week", eventCount: 12)
    }
}
