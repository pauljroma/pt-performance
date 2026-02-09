//
//  BiomarkerDashboardView.swift
//  PTPerformance
//
//  Biomarker Dashboard - Overview of all health biomarkers
//  Groups biomarkers by category with traffic light status system
//  Includes training impact callouts and system-level insights
//

import SwiftUI

struct BiomarkerDashboardView: View {
    @StateObject private var viewModel = BiomarkerDashboardViewModel()
    @State private var showingBiomarkerDetail = false
    @State private var showingProgramAdjustment = false
    @State private var showingGlossary = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.biomarkerSummaries.isEmpty {
                    emptyState
                } else {
                    dashboardContent
                }
            }
            .navigationTitle("Biomarkers")
            .searchable(text: $viewModel.searchText, prompt: "Search biomarkers")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingGlossary = true
                    } label: {
                        Image(systemName: "book.fill")
                    }
                    .accessibilityLabel("Biomarker Glossary")
                    .accessibilityHint("Learn about what each biomarker means")
                }
            }
            .refreshable {
                await viewModel.refreshDashboard()
            }
            .task {
                await viewModel.loadDashboard()
            }
            .sheet(isPresented: $showingBiomarkerDetail) {
                if let biomarker = viewModel.selectedBiomarker {
                    BiomarkerDetailView(
                        biomarker: biomarker,
                        historyData: viewModel.biomarkerHistory,
                        isLoadingHistory: viewModel.isLoadingHistory
                    )
                }
            }
            .sheet(isPresented: $showingGlossary) {
                BiomarkerGlossaryView()
            }
            .onChange(of: viewModel.selectedBiomarker) { _, newValue in
                showingBiomarkerDetail = newValue != nil
            }
            .onChange(of: showingBiomarkerDetail) { _, isShowing in
                if !isShowing {
                    viewModel.clearSelection()
                }
            }
        }
        .tint(.modusCyan)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading biomarkers...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Biomarkers", systemImage: "chart.bar.doc.horizontal")
                .foregroundColor(.modusDeepTeal)
        } description: {
            Text("Upload your lab results to see your biomarker dashboard with trends and insights.")
        } actions: {
            NavigationLink {
                LabResultsView()
            } label: {
                Label("View Lab Results", systemImage: "cross.case.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(.modusCyan)
        }
    }

    // MARK: - Dashboard Content

    private var dashboardContent: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Status Summary Bar
                statusSummaryBar

                // Training Impact Callout (if any)
                if let impact = viewModel.primaryTrainingImpact {
                    TrainingImpactCalloutCard(
                        impact: impact,
                        onDismiss: {
                            withAnimation {
                                viewModel.dismissTrainingImpact(impact)
                            }
                        },
                        onActionTap: {
                            showingProgramAdjustment = true
                        }
                    )
                }

                // Status Overview Cards
                statusOverview

                // Concerning Biomarkers (if any)
                if !viewModel.concerningBiomarkers.isEmpty {
                    attentionSection
                }

                // Category Filter
                categoryFilter

                // Biomarkers by Category with System Status
                biomarkersListSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Status Summary Bar

    private var statusSummaryBar: some View {
        HStack(spacing: Spacing.sm) {
            // Attention markers
            if viewModel.statusCounts.concern > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("\(viewModel.statusCounts.concern) marker\(viewModel.statusCounts.concern == 1 ? "" : "s") need\(viewModel.statusCounts.concern == 1 ? "s" : "") attention")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
            }

            // Optimal markers
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.modusTealAccent)
                    .font(.caption)
                Text("\(viewModel.statusCounts.optimal + viewModel.statusCounts.normal) marker\(viewModel.statusCounts.optimal + viewModel.statusCounts.normal == 1 ? "" : "s") optimal")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.modusTealAccent)
            }

            Spacer()

            // Last labs date
            if let days = viewModel.daysSinceLastLab {
                Text("Last labs: \(days) day\(days == 1 ? "" : "s") ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(viewModel.statusSummaryText)
    }

    // MARK: - Status Overview

    private var statusOverview: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Overview")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)

                Spacer()

                if let lastDate = viewModel.lastLabDate {
                    Text("Updated \(lastDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 12) {
                StatusCountCard(
                    count: viewModel.statusCounts.optimal,
                    label: "Optimal",
                    color: .modusTealAccent,
                    icon: "checkmark.circle.fill"
                )

                StatusCountCard(
                    count: viewModel.statusCounts.normal,
                    label: "Normal",
                    color: .modusCyan,
                    icon: "circle.fill"
                )

                StatusCountCard(
                    count: viewModel.statusCounts.concern,
                    label: "Attention",
                    color: .orange,
                    icon: "exclamationmark.circle.fill"
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Attention Section

    private var attentionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Needs Attention")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)

                Spacer()

                Text("\(viewModel.concerningBiomarkers.count) markers")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ForEach(viewModel.concerningBiomarkers.prefix(3)) { biomarker in
                BiomarkerRowCompact(biomarker: biomarker) {
                    Task {
                        await viewModel.loadBiomarkerHistory(for: biomarker)
                    }
                }
            }

            if viewModel.concerningBiomarkers.count > 3 {
                Text("+ \(viewModel.concerningBiomarkers.count - 3) more")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryFilterChip(
                    title: "All",
                    isSelected: viewModel.selectedCategory == nil,
                    count: viewModel.biomarkerSummaries.count
                ) {
                    withAnimation {
                        viewModel.selectedCategory = nil
                    }
                }

                ForEach(viewModel.categoriesWithBiomarkers) { category in
                    let count = viewModel.groupedBiomarkers[category]?.count ?? 0
                    let status = viewModel.systemStatus(for: category)
                    CategoryFilterChip(
                        title: category.rawValue,
                        icon: category.icon,
                        isSelected: viewModel.selectedCategory == category,
                        count: count,
                        systemStatus: status?.status
                    ) {
                        withAnimation {
                            viewModel.selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Biomarkers List

    private var biomarkersListSection: some View {
        LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
            ForEach(viewModel.categoriesWithBiomarkers) { category in
                if let biomarkers = viewModel.groupedBiomarkers[category], !biomarkers.isEmpty {
                    Section {
                        ForEach(biomarkers) { biomarker in
                            BiomarkerRowEnhanced(biomarker: biomarker) {
                                Task {
                                    await viewModel.loadBiomarkerHistory(for: biomarker)
                                }
                            }
                        }
                    } header: {
                        CategoryHeaderEnhanced(
                            category: category,
                            count: biomarkers.count,
                            systemStatus: viewModel.systemStatus(for: category)
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Training Impact Callout Card

struct TrainingImpactCalloutCard: View {
    let impact: TrainingImpact
    let onDismiss: () -> Void
    let onActionTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                Image(systemName: impact.severity.icon)
                    .foregroundColor(impact.severity.color)
                    .font(.title3)

                Text("TRAINING INSIGHT")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(impact.severity.color)
                    .tracking(1)

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
                .accessibilityLabel("Dismiss insight")
            }

            // Insight text
            Text(impact.insight)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            // Recommendations
            VStack(alignment: .leading, spacing: Spacing.xs) {
                ForEach(impact.recommendations, id: \.self) { recommendation in
                    HStack(alignment: .top, spacing: Spacing.xs) {
                        Text("\u{2022}")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(recommendation)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Action button (if available)
            if let actionTitle = impact.actionButtonTitle {
                Button(action: onActionTap) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(impact.severity.color)
                        .cornerRadius(CornerRadius.sm)
                }
                .accessibilityLabel(actionTitle)
            }
        }
        .padding()
        .background(impact.severity.color.opacity(0.1))
        .cornerRadius(CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(impact.severity.color.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Training insight for \(impact.biomarkerName)")
    }
}

// MARK: - Status Count Card

struct StatusCountCard: View {
    let count: Int
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text("\(count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) \(label) biomarkers")
    }
}

// MARK: - Category Filter Chip

struct CategoryFilterChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let count: Int
    var systemStatus: SystemStatusLevel? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                // System status indicator
                if let status = systemStatus, !isSelected {
                    Image(systemName: status.emoji)
                        .font(.caption2)
                        .foregroundColor(status.color)
                }

                Text("\(count)")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.3) : Color.secondary.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.modusCyan : Color(.secondarySystemGroupedBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
        .accessibilityLabel("\(title), \(count) biomarkers")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Category Header Enhanced

struct CategoryHeaderEnhanced: View {
    let category: BiomarkerCategory
    let count: Int
    let systemStatus: CategorySystemStatus?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.subheadline)
                    .foregroundColor(category.color)

                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.modusDeepTeal)

                // System status indicator
                if let status = systemStatus {
                    Image(systemName: status.status.emoji)
                        .font(.caption)
                        .foregroundColor(status.status.color)
                }

                Spacer()

                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .cornerRadius(8)
            }

            // Training relevance explanation
            Text(category.trainingExplanation)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color(.systemGroupedBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.rawValue) category, \(count) biomarkers, \(systemStatus?.status.displayText ?? "status unknown")")
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Category Header (Legacy for compatibility)

struct CategoryHeader: View {
    let category: BiomarkerCategory
    let count: Int

    var body: some View {
        CategoryHeaderEnhanced(category: category, count: count, systemStatus: nil)
    }
}

// MARK: - Biomarker Row Enhanced

struct BiomarkerRowEnhanced: View {
    let biomarker: BiomarkerSummary
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: 12) {
                    // Status indicator
                    Circle()
                        .fill(statusColor)
                        .frame(width: 10, height: 10)
                        .accessibilityHidden(true)

                    // Name and value
                    VStack(alignment: .leading, spacing: 2) {
                        Text(biomarker.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.modusDeepTeal)

                        if let low = biomarker.normalLow, let high = biomarker.normalHigh {
                            Text("Ref: \(formatValue(low)) - \(formatValue(high)) \(biomarker.unit)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Trend indicator
                    if biomarker.trend != .unknown && biomarker.historyCount > 1 {
                        Image(systemName: biomarker.trend.icon)
                            .font(.caption)
                            .foregroundColor(trendColor)
                            .accessibilityLabel(biomarker.trend.accessibilityLabel)
                    }

                    // Current value
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(biomarker.formattedValue) \(biomarker.unit)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(statusColor)

                        Text(biomarker.status.displayText)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                }

                // Training relevance (if available)
                if let relevance = biomarker.trainingRelevance {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "figure.run")
                            .font(.caption2)
                            .foregroundColor(.modusCyan)
                        Text(relevance)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.leading, 22) // Align with name
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(biomarker.displayName), \(biomarker.formattedValue) \(biomarker.unit), \(biomarker.status.displayText)")
        .accessibilityHint("Tap to view detailed history and trends")
    }

    private var statusColor: Color {
        biomarker.status.statusColor
    }

    private var trendColor: Color {
        switch biomarker.trend {
        case .increasing: return .orange
        case .decreasing: return .blue
        case .stable: return .modusTealAccent
        case .unknown: return .secondary
        }
    }

    private func formatValue(_ value: Double) -> String {
        if value >= 100 {
            return String(format: "%.0f", value)
        } else if value >= 10 {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
}

// MARK: - Biomarker Row (Legacy for compatibility)

struct BiomarkerRow: View {
    let biomarker: BiomarkerSummary
    let onTap: () -> Void

    var body: some View {
        BiomarkerRowEnhanced(biomarker: biomarker, onTap: onTap)
    }
}

// MARK: - Compact Biomarker Row

struct BiomarkerRowCompact: View {
    let biomarker: BiomarkerSummary
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: biomarker.status.iconName)
                    .font(.subheadline)
                    .foregroundColor(statusColor)

                Text(biomarker.displayName)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Spacer()

                Text("\(biomarker.formattedValue) \(biomarker.unit)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(statusColor)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(biomarker.displayName), \(biomarker.formattedValue) \(biomarker.unit), \(biomarker.status.displayText)")
    }

    private var statusColor: Color {
        biomarker.status.statusColor
    }
}

// MARK: - Preview

#if DEBUG
struct BiomarkerDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        BiomarkerDashboardView()
    }
}
#endif
