//
//  ConflictResolutionView.swift
//  PTPerformance
//
//  X2Index Command Center - Multi-Source Conflict Resolution (M5)
//  Side-by-side comparison view for resolving data conflicts
//

import SwiftUI

/// Main view for resolving a single data conflict
struct ConflictResolutionView: View {
    let conflict: DataConflict
    let onResolve: (String) -> Void
    let onDismiss: () -> Void
    let onUseHighestConfidence: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedSource: String?
    @State private var isResolving = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection

                // Conflict details
                conflictInfoSection

                // Source comparison
                sourceComparisonSection

                // Resolution actions
                actionButtons

                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle("Resolve Conflict")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Metric icon
            ZStack {
                Circle()
                    .fill(conflict.metricType.color.opacity(0.15))
                    .frame(width: 72, height: 72)

                Image(systemName: conflict.metricType.iconName)
                    .font(.system(size: 32))
                    .foregroundColor(conflict.metricType.color)
            }

            Text(conflict.metricType.displayName)
                .font(.title2.bold())
                .foregroundColor(.primary)

            Text(conflict.formattedDate)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Conflict Info Section

    private var conflictInfoSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)

                Text("Multiple sources report different values")
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.1))
            )

            // Source count and confidence info
            HStack(spacing: 16) {
                infoChip(
                    icon: "arrow.triangle.2.circlepath",
                    label: "\(conflict.sourceCount) sources",
                    color: .blue
                )

                if let highestConfidence = conflict.highestConfidenceSource {
                    infoChip(
                        icon: "checkmark.seal.fill",
                        label: "\(highestConfidence.displayName) most confident",
                        color: .green
                    )
                }
            }
        }
    }

    private func infoChip(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
    }

    // MARK: - Source Comparison Section

    private var sourceComparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Which value is correct?")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                ForEach(conflict.sources) { source in
                    SourceComparisonCard(
                        source: source,
                        metricType: conflict.metricType,
                        isSelected: selectedSource == source.sourceType,
                        onSelect: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedSource = source.sourceType
                            }
                            HapticFeedback.selectionChanged()
                        }
                    )
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Use selected source button
            if let selected = selectedSource {
                Button(action: {
                    isResolving = true
                    onResolve(selected)
                }) {
                    HStack {
                        if isResolving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text("Use \(conflict.sources.first { $0.sourceType == selected }?.displayName ?? selected)")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.green)
                    )
                }
                .disabled(isResolving)
            }

            // Auto-resolve with highest confidence
            Button(action: onUseHighestConfidence) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Use Highest Confidence")
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 1)
                )
            }

            // Dismiss button
            Button(action: onDismiss) {
                HStack {
                    Image(systemName: "xmark.circle")
                    Text("Dismiss Conflict")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
    }
}

// MARK: - Source Comparison Card

/// Card showing a single source's value with selection state
struct SourceComparisonCard: View {
    let source: ConflictingSource
    let metricType: ConflictMetricType
    let isSelected: Bool
    let onSelect: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Source icon
                ZStack {
                    Circle()
                        .fill(source.color.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: source.iconName)
                        .font(.title3)
                        .foregroundColor(source.color)
                }

                // Source details
                VStack(alignment: .leading, spacing: 4) {
                    Text(source.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        // Confidence badge
                        HStack(spacing: 4) {
                            Circle()
                                .fill(source.confidenceColor)
                                .frame(width: 6, height: 6)

                            Text("\(source.confidenceLevel) confidence")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Text("at \(source.formattedTimestamp)")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }

                Spacer()

                // Value
                VStack(alignment: .trailing, spacing: 2) {
                    Text(source.formattedValue(for: metricType))
                        .font(.title3.bold())
                        .foregroundColor(isSelected ? .green : .primary)

                    Text(metricType.unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.green : Color.secondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Visual Diff Component

/// Shows the difference between two values visually
struct ValueDiffIndicator: View {
    let value1: Double
    let value2: Double
    let unit: String

    var difference: Double {
        abs(value1 - value2)
    }

    var percentDifference: Double {
        guard value1 > 0 else { return 0 }
        return (difference / value1) * 100
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.caption2)

                Text(String(format: "%.1f %@ diff", difference, unit))
                    .font(.caption2.weight(.medium))
            }
            .foregroundColor(.orange)

            if percentDifference > 0 {
                Text(String(format: "(%.0f%%)", percentDifference))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.orange.opacity(0.1))
        )
    }
}

// MARK: - Conflict Resolution Sheet

/// Sheet for quick conflict resolution
struct ConflictResolutionSheet: View {
    let conflict: DataConflict
    @ObservedObject var viewModel: ConflictResolutionViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ConflictResolutionView(
                conflict: conflict,
                onResolve: { source in
                    Task {
                        await viewModel.resolveConflict(conflict, with: source)
                        dismiss()
                    }
                },
                onDismiss: {
                    Task {
                        await viewModel.dismissConflict(conflict)
                        dismiss()
                    }
                },
                onUseHighestConfidence: {
                    Task {
                        await viewModel.useHighestConfidence(conflict)
                        dismiss()
                    }
                }
            )
        }
    }
}

// MARK: - Previews

#Preview("ConflictResolutionView") {
    NavigationStack {
        ConflictResolutionView(
            conflict: .sample,
            onResolve: { source in print("Resolved with: \(source)") },
            onDismiss: { print("Dismissed") },
            onUseHighestConfidence: { print("Use highest confidence") }
        )
    }
}

#Preview("SourceComparisonCard - Unselected") {
    SourceComparisonCard(
        source: DataConflict.sample.sources[0],
        metricType: .sleepDuration,
        isSelected: false,
        onSelect: { }
    )
    .padding()
}

#Preview("SourceComparisonCard - Selected") {
    SourceComparisonCard(
        source: DataConflict.sample.sources[0],
        metricType: .sleepDuration,
        isSelected: true,
        onSelect: { }
    )
    .padding()
}

#Preview("ValueDiffIndicator") {
    VStack(spacing: 16) {
        ValueDiffIndicator(value1: 7.5, value2: 8.2, unit: "hrs")
        ValueDiffIndicator(value1: 72, value2: 85, unit: "%")
        ValueDiffIndicator(value1: 58, value2: 62, unit: "ms")
    }
    .padding()
}
