//
//  PatientRankingTable.swift
//  PTPerformance
//
//  Sortable table component showing patient rankings with metrics
//  Supports sorting by adherence, progress, pain reduction, and more
//

import SwiftUI

// MARK: - Patient Ranking Table

/// Table showing patient rankings with sortable columns
struct PatientRankingTable: View {
    let rankings: [PatientRankingEntry]
    let sortKey: CohortAnalyticsService.PatientRankingSortKey
    let sortAscending: Bool
    let onSortChange: (CohortAnalyticsService.PatientRankingSortKey) -> Void
    let onPatientTap: (PatientRankingEntry) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            headerRow

            // Divider
            Divider()

            // Patient rows
            if rankings.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(rankings) { entry in
                        PatientRankingRow(
                            entry: entry,
                            onTap: { onPatientTap(entry) }
                        )

                        if entry.id != rankings.last?.id {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.medium)
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(spacing: 12) {
            // Rank column
            Text("#")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(width: 24)

            // Name column
            Text("Patient")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            Spacer()

            // Sortable columns
            sortableColumn(
                title: "Adherence",
                key: .adherence,
                width: 70
            )

            sortableColumn(
                title: "Progress",
                key: .progressScore,
                width: 70
            )

            sortableColumn(
                title: "Pain",
                key: .painReduction,
                width: 60
            )

            // Status column
            Text("Status")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(width: 28)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color(.secondarySystemGroupedBackground))
    }

    private func sortableColumn(
        title: String,
        key: CohortAnalyticsService.PatientRankingSortKey,
        width: CGFloat
    ) -> some View {
        Button(action: {
            HapticFeedback.selectionChanged()
            onSortChange(key)
        }) {
            HStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(sortKey == key ? .bold : .semibold)
                    .foregroundColor(sortKey == key ? .modusCyan : .secondary)

                if sortKey == key {
                    Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.modusCyan)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: width)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3")
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text("No patients found")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Patient Ranking Row

/// Individual row in the patient ranking table
struct PatientRankingRow: View {
    let entry: PatientRankingEntry
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap()
        }) {
            HStack(spacing: 12) {
                // Rank
                rankBadge

                // Avatar and name
                HStack(spacing: 10) {
                    patientAvatar

                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.patientName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        if let lastActivity = entry.lastActivityDate {
                            Text(lastActivity, style: .relative)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                // Metrics
                metricValue(entry.formattedAdherence, width: 70, isHighlighted: entry.adherence >= 80)
                metricValue(String(format: "%.0f", entry.progressScore), width: 70, isHighlighted: entry.progressScore >= 70)
                metricValue(entry.formattedPainReduction, width: 60, isHighlighted: entry.painReduction >= 30)

                // Status indicator
                statusIndicator
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(rowBackground)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap to view patient details")
    }

    // MARK: - Components

    private var rankBadge: some View {
        ZStack {
            if entry.rank <= 3 {
                Circle()
                    .fill(rankColor)
                    .frame(width: 24, height: 24)

                Text("\(entry.rank)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            } else {
                Text("\(entry.rank)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(width: 24)
            }
        }
    }

    private var rankColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return Color(.systemGray)
        case 3: return .orange
        default: return .clear
        }
    }

    private var patientAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.modusCyan, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 36)

            Text(entry.patientInitials)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }

    private func metricValue(_ value: String, width: CGFloat, isHighlighted: Bool) -> some View {
        Text(value)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(isHighlighted ? .green : .primary)
            .frame(width: width)
    }

    private var statusIndicator: some View {
        Image(systemName: entry.status.iconName)
            .font(.caption)
            .foregroundColor(statusColor)
            .frame(width: 28)
    }

    private var statusColor: Color {
        switch entry.status {
        case .onTrack: return .green
        case .needsAttention: return .orange
        case .atRisk: return .red
        case .inactive: return .gray
        }
    }

    private var rowBackground: Color {
        switch entry.status {
        case .atRisk:
            return Color.red.opacity(colorScheme == .dark ? 0.1 : 0.05)
        case .needsAttention:
            return Color.orange.opacity(colorScheme == .dark ? 0.05 : 0.03)
        default:
            return Color.clear
        }
    }

    private var accessibilityDescription: String {
        "Rank \(entry.rank): \(entry.patientName), " +
        "adherence \(entry.formattedAdherence), " +
        "progress score \(Int(entry.progressScore)), " +
        "pain reduction \(entry.formattedPainReduction), " +
        "status: \(entry.status.displayName)"
    }
}

// MARK: - Compact Ranking List

/// Compact list view for top/bottom performers
struct CompactRankingList: View {
    let title: String
    let icon: String
    let iconColor: Color
    let rankings: [PatientRankingEntry]
    let onPatientTap: (PatientRankingEntry) -> Void
    let onViewAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(iconColor)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: {
                    HapticFeedback.light()
                    onViewAll()
                }) {
                    Text("View All")
                        .font(.caption)
                        .foregroundColor(.modusCyan)
                }
            }

            // List
            if rankings.isEmpty {
                Text("No patients")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, Spacing.xs)
            } else {
                VStack(spacing: 8) {
                    ForEach(rankings.prefix(5)) { entry in
                        CompactRankingRow(entry: entry, onTap: { onPatientTap(entry) })
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.medium)
    }
}

/// Compact row for ranking list
struct CompactRankingRow: View {
    let entry: PatientRankingEntry
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap()
        }) {
            HStack(spacing: 10) {
                // Rank badge
                Text("\(entry.rank)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(entry.rank <= 3 ? Color.modusCyan : Color.gray)
                    .cornerRadius(CornerRadius.xs)

                // Name
                Text(entry.patientName)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()

                // Score
                Text(entry.formattedAdherence)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(entry.adherence >= 80 ? .green : (entry.adherence >= 50 ? .primary : .orange))

                // Status
                Image(systemName: entry.status.iconName)
                    .font(.caption2)
                    .foregroundColor(statusColor)
            }
            .padding(.vertical, Spacing.xxs)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var statusColor: Color {
        switch entry.status {
        case .onTrack: return .green
        case .needsAttention: return .orange
        case .atRisk: return .red
        case .inactive: return .gray
        }
    }
}

// MARK: - Preview

#if DEBUG
struct PatientRankingTable_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                PatientRankingTable(
                    rankings: PatientRankingEntry.sampleList,
                    sortKey: .progressScore,
                    sortAscending: false,
                    onSortChange: { _ in },
                    onPatientTap: { _ in }
                )

                CompactRankingList(
                    title: "Top Performers",
                    icon: "star.fill",
                    iconColor: .yellow,
                    rankings: PatientRankingEntry.sampleList,
                    onPatientTap: { _ in },
                    onViewAll: {}
                )

                CompactRankingList(
                    title: "Need Attention",
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .orange,
                    rankings: PatientRankingEntry.sampleList.filter { $0.status != .onTrack },
                    onPatientTap: { _ in },
                    onViewAll: {}
                )
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
