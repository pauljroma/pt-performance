//
//  PTBriefDeltaSection.swift
//  PTPerformance
//
//  PT Brief Delta Section - Shows top changes since last session
//  Part of the 60-Second Athlete Brief workflow
//
//  Features:
//  - Shows top 3 key changes since last session
//  - Each delta has: metric name, change direction, magnitude, source citation
//  - Tap any delta to see evidence detail
//  - Color-coded direction indicators
//

import SwiftUI

struct PTBriefDeltaSection: View {
    let deltas: [PTBriefDelta]
    let isLoading: Bool
    let onDeltaTap: (PTBriefDelta) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Section Header
            sectionHeader

            if isLoading {
                loadingState
            } else if deltas.isEmpty {
                emptyState
            } else {
                // Delta Cards
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(deltas) { delta in
                        DeltaCard(delta: delta, onTap: { onDeltaTap(delta) })
                    }
                }
            }
        }
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        HStack {
            Image(systemName: "arrow.triangle.swap")
                .foregroundColor(.modusCyan)
                .accessibilityHidden(true)

            Text("Key Changes")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)

            Spacer()

            if !deltas.isEmpty {
                Text("Since last session")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: Spacing.md) {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 36, height: 36)

                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 14)
                            .frame(maxWidth: 100)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 10)
                            .frame(maxWidth: 150)
                    }

                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(CornerRadius.md)
            }
        }
        .pulse()
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle")
                .font(.title2)
                .foregroundColor(.green)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("No Significant Changes")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("All metrics are stable since last session")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No significant changes. All metrics are stable since last session.")
    }
}

// MARK: - Delta Card

private struct DeltaCard: View {
    let delta: PTBriefDelta
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap()
        }) {
            HStack(spacing: Spacing.md) {
                // Direction indicator
                directionIndicator

                // Metric details
                VStack(alignment: .leading, spacing: 4) {
                    // Metric name and magnitude
                    HStack(spacing: Spacing.xs) {
                        Text(delta.metricName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        Text(delta.magnitude)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(delta.direction.color)
                    }

                    // Previous -> Current
                    HStack(spacing: 4) {
                        Text(delta.previousValue)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .accessibilityHidden(true)

                        Text(delta.currentValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                }

                Spacer()

                // Source and citation
                VStack(alignment: .trailing, spacing: 4) {
                    sourceIndicator

                    citationBadge
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Tap to view evidence")
    }

    // MARK: - Direction Indicator

    private var directionIndicator: some View {
        ZStack {
            Circle()
                .fill(delta.direction.color.opacity(0.15))
                .frame(width: 36, height: 36)

            Image(systemName: delta.direction.icon)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(delta.direction.color)
        }
        .accessibilityHidden(true)
    }

    // MARK: - Source Indicator

    private var sourceIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: delta.sourceType.icon)
                .font(.caption2)

            Text(delta.source)
                .font(.caption2)
        }
        .foregroundColor(.secondary)
    }

    // MARK: - Citation Badge

    private var citationBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: "doc.text")
                .font(.system(size: 8))

            Text("\(delta.citationCount)")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(.modusCyan)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.modusCyan.opacity(0.1))
        .cornerRadius(CornerRadius.xs)
    }

    private var accessibilityLabel: String {
        let direction = delta.direction == .up ? "increased" : (delta.direction == .down ? "decreased" : "unchanged")
        return "\(delta.metricName) \(direction) \(delta.magnitude), from \(delta.previousValue) to \(delta.currentValue), source: \(delta.source), \(delta.citationCount) citations"
    }
}

// MARK: - Preview

#if DEBUG
struct PTBriefDeltaSection_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // With deltas
            ScrollView {
                PTBriefDeltaSection(
                    deltas: [
                        PTBriefDelta(
                            id: UUID(),
                            metricName: "HRV",
                            direction: .up,
                            magnitude: "+15%",
                            previousValue: "45 ms",
                            currentValue: "52 ms",
                            source: "Apple Watch",
                            sourceType: .wearable,
                            citationCount: 2,
                            timestamp: Date()
                        ),
                        PTBriefDelta(
                            id: UUID(),
                            metricName: "Sleep Quality",
                            direction: .down,
                            magnitude: "-12%",
                            previousValue: "85%",
                            currentValue: "75%",
                            source: "Self-Report",
                            sourceType: .selfReport,
                            citationCount: 1,
                            timestamp: Date()
                        ),
                        PTBriefDelta(
                            id: UUID(),
                            metricName: "Arm Soreness",
                            direction: .unchanged,
                            magnitude: "0",
                            previousValue: "3/10",
                            currentValue: "3/10",
                            source: "Daily Check-in",
                            sourceType: .selfReport,
                            citationCount: 1,
                            timestamp: Date()
                        )
                    ],
                    isLoading: false,
                    onDeltaTap: { _ in }
                )
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .previewDisplayName("With Deltas")

            // Loading
            ScrollView {
                PTBriefDeltaSection(
                    deltas: [],
                    isLoading: true,
                    onDeltaTap: { _ in }
                )
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .previewDisplayName("Loading")

            // Empty
            ScrollView {
                PTBriefDeltaSection(
                    deltas: [],
                    isLoading: false,
                    onDeltaTap: { _ in }
                )
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .previewDisplayName("Empty")

            // Dark mode
            ScrollView {
                PTBriefDeltaSection(
                    deltas: [
                        PTBriefDelta(
                            id: UUID(),
                            metricName: "Recovery Score",
                            direction: .up,
                            magnitude: "+8%",
                            previousValue: "72%",
                            currentValue: "80%",
                            source: "WHOOP",
                            sourceType: .wearable,
                            citationCount: 3,
                            timestamp: Date()
                        )
                    ],
                    isLoading: false,
                    onDeltaTap: { _ in }
                )
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}
#endif
