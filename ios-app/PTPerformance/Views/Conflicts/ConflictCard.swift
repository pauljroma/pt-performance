//
//  ConflictCard.swift
//  PTPerformance
//
//  X2Index Command Center - Multi-Source Conflict Resolution (M5)
//  Compact conflict indicator for timeline/dashboard
//

import SwiftUI

/// Compact card displaying a data conflict with resolve action
struct ConflictCard: View {
    let conflict: DataConflict
    let onResolve: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            // Warning icon with source count badge
            ZStack(alignment: .topTrailing) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.orange)

                // Source count badge
                if conflict.sourceCount > 2 {
                    Text("\(conflict.sourceCount)")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                        .background(Circle().fill(Color.red))
                        .offset(x: 6, y: -6)
                }
            }
            .frame(width: 32)

            // Conflict details
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: conflict.metricType.iconName)
                        .font(.caption)
                        .foregroundColor(conflict.metricType.color)

                    Text(conflict.metricType.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                }

                // Sources summary
                HStack(spacing: 4) {
                    ForEach(conflict.sources.prefix(3)) { source in
                        HStack(spacing: 2) {
                            Image(systemName: source.iconName)
                                .font(.caption2)
                                .foregroundColor(source.color)

                            Text(source.formattedValue(for: conflict.metricType))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        if source.id != conflict.sources.prefix(3).last?.id {
                            Text("vs")
                                .font(.caption2)
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                    }
                }
            }

            Spacer()

            // Resolve button
            Button(action: onResolve) {
                Text("Resolve")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.orange)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

/// Minimal conflict badge for inline display
struct ConflictBadge: View {
    let count: Int
    var size: BadgeSize = .medium

    /// Use the canonical top-level BadgeSize enum
    typealias BadgeSize = PTPerformance.BadgeSize

    /// Count label font based on size
    private var countFont: Font {
        switch size {
        case .small: return .system(size: 9, weight: .bold)
        case .medium: return .caption2.weight(.bold)
        case .large: return .caption.weight(.bold)
        }
    }

    /// Conflict badge padding based on size
    private var badgePadding: CGFloat {
        switch size {
        case .small: return 4
        case .medium: return 6
        case .large: return 8
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(size.iconFont)

            if count > 1 {
                Text("\(count)")
                    .font(countFont)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, badgePadding)
        .padding(.vertical, badgePadding - 2)
        .background(
            Capsule()
                .fill(Color.orange)
        )
    }
}

/// Conflict indicator for timeline events
struct TimelineConflictIndicator: View {
    let conflictCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)

                Text("\(conflictCount) conflict\(conflictCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.orange.opacity(0.15))
            )
        }
        .buttonStyle(.plain)
    }
}

/// Small conflict card for dashboard sections
struct MiniConflictCard: View {
    let conflict: DataConflict
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                // Metric icon
                ZStack {
                    Circle()
                        .fill(conflict.metricType.color.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: conflict.metricType.iconName)
                        .font(.system(size: 14))
                        .foregroundColor(conflict.metricType.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(conflict.metricType.shortName)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.primary)

                    Text(conflict.relativeDateString)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Conflict icon
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, Spacing.xs)
            .padding(.horizontal, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.tertiarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

/// Section showing pending conflicts summary
struct ConflictsSummarySection: View {
    let pendingCount: Int
    let onViewAll: () -> Void

    var body: some View {
        if pendingCount > 0 {
            VStack(spacing: 0) {
                Button(action: onViewAll) {
                    HStack(spacing: 12) {
                        // Warning icon
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.15))
                                .frame(width: 44, height: 44)

                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title3)
                                .foregroundColor(.orange)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(pendingCount) Data Conflict\(pendingCount == 1 ? "" : "s")")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text("Different sources report different values")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text("Resolve")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.orange)

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemGroupedBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Previews

#Preview("ConflictCard") {
    VStack(spacing: 16) {
        ConflictCard(conflict: .sample) {
        }

        ConflictCard(conflict: .sampleResolved) {
        }
    }
    .padding()
}

#Preview("ConflictBadge") {
    HStack(spacing: 20) {
        ConflictBadge(count: 1, size: .small)
        ConflictBadge(count: 3, size: .medium)
        ConflictBadge(count: 12, size: .large)
    }
    .padding()
}

#Preview("TimelineConflictIndicator") {
    VStack(spacing: 16) {
        TimelineConflictIndicator(conflictCount: 1) { }
        TimelineConflictIndicator(conflictCount: 3) { }
    }
    .padding()
}

#Preview("MiniConflictCard") {
    VStack(spacing: 8) {
        MiniConflictCard(conflict: .sample) { }
        if let conflict = DataConflict.generateSampleConflicts(count: 1).first {
            MiniConflictCard(conflict: conflict) { }
        }
    }
    .padding()
}

#Preview("ConflictsSummarySection") {
    VStack(spacing: 16) {
        ConflictsSummarySection(pendingCount: 3) { }
        ConflictsSummarySection(pendingCount: 1) { }
    }
    .padding()
}
