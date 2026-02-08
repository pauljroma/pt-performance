//
//  ConflictHistoryView.swift
//  PTPerformance
//
//  X2Index Command Center - Multi-Source Conflict Resolution (M5)
//  Audit log of past conflict resolutions
//

import SwiftUI

/// View showing history of conflict resolutions with audit trail
struct ConflictHistoryView: View {
    let patientId: UUID

    @StateObject private var viewModel: ConflictResolutionViewModel
    @Environment(\.colorScheme) private var colorScheme

    init(patientId: UUID) {
        self.patientId = patientId
        _viewModel = StateObject(wrappedValue: ConflictResolutionViewModel(patientId: patientId))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if viewModel.isLoading && viewModel.resolvedConflicts.isEmpty {
                    loadingView
                } else if viewModel.resolvedConflicts.isEmpty {
                    emptyStateView
                } else {
                    contentView
                }
            }
            .padding()
        }
        .navigationTitle("Resolution History")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            HapticFeedback.light()
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadData()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        VStack(spacing: 24) {
            // Summary stats
            if let summary = viewModel.summary {
                summaryCard(summary: summary)
            }

            // Resolution statistics
            resolutionStatsCard

            // Filter chips
            filterSection

            // Grouped history
            ForEach(viewModel.groupedResolvedConflicts, id: \.0) { dateGroup, conflicts in
                VStack(alignment: .leading, spacing: 12) {
                    Text(dateGroup)
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)

                    ForEach(conflicts) { conflict in
                        ConflictHistoryCard(conflict: conflict)
                    }
                }
            }
        }
    }

    // MARK: - Summary Card

    private func summaryCard(summary: ConflictSummary) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Conflict Summary")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Text("\(summary.totalCount) total")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 16) {
                summaryMetric(
                    value: "\(summary.pendingCount)",
                    label: "Pending",
                    color: .orange
                )

                summaryMetric(
                    value: "\(summary.autoResolvedCount)",
                    label: "Auto",
                    color: .blue
                )

                summaryMetric(
                    value: "\(summary.userResolvedCount)",
                    label: "Manual",
                    color: .green
                )

                summaryMetric(
                    value: "\(summary.dismissedCount)",
                    label: "Dismissed",
                    color: .gray
                )
            }

            // Most common metric
            if let mostCommon = summary.mostCommonMetric {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.purple)

                    Text("Most conflicts: \(mostCommon.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .adaptiveShadow(Shadow.medium)
        )
    }

    private func summaryMetric(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Resolution Stats Card

    private var resolutionStatsCard: some View {
        let stats = viewModel.resolutionStats

        return VStack(spacing: 12) {
            HStack {
                Text("Resolution Rate")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)

                Spacer()

                Text(stats.formattedResolutionRate)
                    .font(.headline)
                    .foregroundColor(.green)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.green.opacity(0.8), .green],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(stats.resolutionRate / 100), height: 8)
                }
            }
            .frame(height: 8)

            // Breakdown
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                    Text("\(stats.autoResolved) auto")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("\(stats.manuallyResolved) manual")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Clear filter
                if viewModel.selectedMetricFilter != nil || viewModel.selectedStatusFilter != nil {
                    Button(action: viewModel.clearFilters) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                            Text("Clear")
                        }
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                    }
                }

                // Metric filters
                ForEach(ConflictMetricType.allCases) { metric in
                    ConflictFilterChip(
                        label: metric.shortName,
                        icon: metric.iconName,
                        isSelected: viewModel.selectedMetricFilter == metric,
                        color: metric.color
                    ) {
                        viewModel.toggleMetricFilter(metric)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading history...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green.opacity(0.6))

            Text("No Resolution History")
                .font(.title2.bold())
                .foregroundColor(.primary)

            Text("Conflicts you resolve will appear here so you can track patterns and learn from past decisions.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 60)
    }
}

// MARK: - Conflict History Card

/// Card showing a resolved conflict with resolution details
struct ConflictHistoryCard: View {
    let conflict: DataConflict

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Metric icon
                ZStack {
                    Circle()
                        .fill(conflict.metricType.color.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: conflict.metricType.iconName)
                        .font(.system(size: 16))
                        .foregroundColor(conflict.metricType.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(conflict.metricType.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)

                    Text(conflict.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Status badge
                statusBadge
            }

            // Resolution details
            if conflict.status != .pending {
                Divider()

                HStack(spacing: 16) {
                    // Original sources
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sources")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        HStack(spacing: 4) {
                            ForEach(conflict.sources) { source in
                                Image(systemName: source.iconName)
                                    .font(.caption)
                                    .foregroundColor(source.color)
                            }
                        }
                    }

                    // Arrow
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Resolved value
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Resolved")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        if let source = conflict.resolvedSource,
                           let resolvedSource = conflict.sources.first(where: { $0.sourceType == source }) {
                            HStack(spacing: 4) {
                                Image(systemName: resolvedSource.iconName)
                                    .font(.caption)
                                    .foregroundColor(resolvedSource.color)

                                Text(resolvedSource.formattedValue(for: conflict.metricType))
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.primary)
                            }
                        } else if let value = conflict.resolvedValue {
                            Text(formatResolvedValue(value))
                                .font(.caption.weight(.medium))
                                .foregroundColor(.primary)
                        }
                    }

                    Spacer()

                    // Resolved time
                    if let resolvedAt = conflict.resolvedAt {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("When")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Text(formatResolvedTime(resolvedAt))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: conflict.status.iconName)
                .font(.caption2)

            Text(conflict.status.displayName)
                .font(.caption.weight(.medium))
        }
        .foregroundColor(conflict.status.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(conflict.status.color.opacity(0.15))
        )
    }

    private func formatResolvedValue(_ value: AnyCodableValue) -> String {
        if let stringVal = value.stringValue {
            return stringVal
        }
        if let intVal = value.intValue {
            return "\(intVal)"
        }
        if case .double(let doubleVal) = value {
            return String(format: "%.1f", doubleVal)
        }
        return "Unknown"
    }

    private func formatResolvedTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Filter Chip

/// Selectable filter chip for conflict filtering
struct ConflictFilterChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)

                Text(label)
                    .font(.caption.weight(.medium))
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? color : color.opacity(0.15))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("ConflictHistoryView") {
    NavigationStack {
        ConflictHistoryView(patientId: UUID())
    }
}

#Preview("ConflictHistoryCard - Resolved") {
    ConflictHistoryCard(conflict: .sampleResolved)
        .padding()
}

#Preview("ConflictHistoryCard - Auto-Resolved") {
    ConflictHistoryCard(
        conflict: DataConflict(
            id: UUID(),
            patientId: UUID(),
            metricType: .hrv,
            conflictDate: Date(),
            sources: [
                ConflictingSource(
                    sourceType: "whoop",
                    value: .int(58),
                    timestamp: Date(),
                    confidence: 0.95
                ),
                ConflictingSource(
                    sourceType: "apple_health",
                    value: .int(52),
                    timestamp: Date(),
                    confidence: 0.8
                )
            ],
            status: .autoResolved,
            resolvedValue: .int(58),
            resolvedSource: "whoop",
            resolvedAt: Date(),
            resolvedBy: nil
        )
    )
    .padding()
}

#Preview("FilterChip") {
    HStack(spacing: 8) {
        ConflictFilterChip(label: "Sleep", icon: "bed.double.fill", isSelected: false, color: .indigo) { }
        ConflictFilterChip(label: "HR", icon: "heart.fill", isSelected: true, color: .red) { }
        ConflictFilterChip(label: "HRV", icon: "waveform.path.ecg", isSelected: false, color: .purple) { }
    }
    .padding()
}
