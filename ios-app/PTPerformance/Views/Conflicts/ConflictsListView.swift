//
//  ConflictsListView.swift
//  PTPerformance
//
//  X2Index Command Center - Multi-Source Conflict Resolution (M5)
//  Main list view for managing data conflicts
//

import SwiftUI

/// Main view for viewing and managing all data conflicts
struct ConflictsListView: View {
    let patientId: UUID

    @StateObject private var viewModel: ConflictResolutionViewModel
    @State private var selectedConflict: DataConflict?
    @State private var showResolutionSheet = false
    @State private var showHistoryView = false

    init(patientId: UUID) {
        self.patientId = patientId
        _viewModel = StateObject(wrappedValue: ConflictResolutionViewModel(patientId: patientId))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if viewModel.isLoading && !viewModel.hasPendingConflicts {
                    loadingView
                } else if !viewModel.hasPendingConflicts {
                    emptyStateView
                } else {
                    contentView
                }
            }
            .padding()
        }
        .navigationTitle("Data Conflicts")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showHistoryView = true }) {
                        Label("View History", systemImage: "clock.arrow.circlepath")
                    }

                    if viewModel.hasPendingConflicts {
                        Divider()

                        Button(action: {
                            Task {
                                await viewModel.autoResolveAll()
                            }
                        }) {
                            Label("Auto-Resolve All", systemImage: "sparkles")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .refreshable {
            HapticFeedback.light()
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadData()
        }
        .sheet(item: $selectedConflict) { conflict in
            ConflictResolutionSheet(
                conflict: conflict,
                viewModel: viewModel
            )
        }
        .sheet(isPresented: $showHistoryView) {
            NavigationStack {
                ConflictHistoryView(patientId: patientId)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showHistoryView = false
                            }
                        }
                    }
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("Conflicts Resolved", isPresented: $viewModel.showAutoResolveSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("\(viewModel.autoResolvedCount) conflict\(viewModel.autoResolvedCount == 1 ? " was" : "s were") automatically resolved.")
        }
        .alert("Success", isPresented: $viewModel.showResolutionSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Conflict resolved successfully.")
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        VStack(spacing: 24) {
            // Summary header
            summaryHeader

            // Quick actions
            quickActionsSection

            // Filter chips
            if !viewModel.conflictedMetrics.isEmpty {
                filterSection
            }

            // Pending conflicts
            pendingConflictsSection
        }
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        HStack(spacing: 16) {
            // Pending count
            VStack(spacing: 4) {
                Text("\(viewModel.pendingCount)")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.orange)

                Text("Pending")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            // Divider
            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 1, height: 50)

            // Resolution rate
            VStack(spacing: 4) {
                Text(viewModel.resolutionStats.formattedResolutionRate)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.green)

                Text("Resolved")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .adaptiveShadow(Shadow.medium)
        )
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            // Auto-resolve button
            Button(action: {
                Task {
                    await viewModel.autoResolveAll()
                }
            }) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Auto-Resolve")
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(.modusCyan)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.modusCyan.opacity(0.1))
                )
            }
            .disabled(viewModel.isResolving)

            // View history button
            Button(action: { showHistoryView = true }) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("History")
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All filter
                FilterChip(
                    label: "All",
                    icon: "square.grid.2x2",
                    color: .gray,
                    isSelected: viewModel.selectedMetricFilter == nil
                ) {
                    viewModel.selectedMetricFilter = nil
                }

                // Metric filters
                ForEach(viewModel.conflictedMetrics) { metric in
                    FilterChip(
                        label: metric.shortName,
                        icon: metric.iconName,
                        color: metric.color,
                        isSelected: viewModel.selectedMetricFilter == metric
                    ) {
                        viewModel.toggleMetricFilter(metric)
                    }
                }
            }
            .padding(.horizontal, Spacing.xxs)
        }
    }

    // MARK: - Pending Conflicts Section

    private var pendingConflictsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Pending Conflicts")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Text("\(viewModel.filteredPendingConflicts.count) conflict\(viewModel.filteredPendingConflicts.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Grouped by date
            ForEach(viewModel.groupedPendingConflicts, id: \.0) { dateGroup, conflicts in
                VStack(alignment: .leading, spacing: 12) {
                    Text(dateGroup)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                        .padding(.leading, Spacing.xxs)

                    ForEach(conflicts) { conflict in
                        ConflictCard(conflict: conflict) {
                            selectedConflict = conflict
                        }
                    }
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading conflicts...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            // Success icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
            }

            Text("No Conflicts")
                .font(.title2.bold())
                .foregroundColor(.primary)

            Text("All your health data sources are in sync. We'll notify you if any conflicts arise.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // View history button
            Button(action: { showHistoryView = true }) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("View Resolution History")
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(.modusCyan)
            }
            .padding(.top, Spacing.xs)
        }
        .padding(.top, 60)
    }
}

// MARK: - Conflicts Settings Section

/// Section for Settings view showing conflict resolution options
struct ConflictsSettingsSection: View {
    let patientId: UUID
    @ObservedObject var conflictService: ConflictResolutionService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.orange)

                Text("Data Conflicts")
                    .font(.headline)
            }

            // Pending conflicts indicator
            if !conflictService.pendingConflicts.isEmpty {
                NavigationLink {
                    ConflictsListView(patientId: patientId)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                ConflictBadge(count: conflictService.pendingConflicts.count, size: .small)

                                Text("pending conflict\(conflictService.pendingConflicts.count == 1 ? "" : "s")")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }

                            Text("Different sources report different values")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
            } else {
                // All clear
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)

                    Text("All data sources are in sync")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.1))
                )
            }

            // View history link
            NavigationLink {
                ConflictHistoryView(patientId: patientId)
            } label: {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.secondary)

                    Text("View Resolution History")
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.tertiarySystemGroupedBackground))
                )
            }
        }
    }
}

// MARK: - Daily Check-in Conflicts Banner

/// Banner to show in daily check-in if there are pending conflicts
struct DailyCheckInConflictsBanner: View {
    let pendingCount: Int
    let onResolve: () -> Void

    var body: some View {
        if pendingCount > 0 {
            Button(action: onResolve) {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title3)
                        .foregroundColor(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(pendingCount) Data Conflict\(pendingCount == 1 ? "" : "s")")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)

                        Text("Tap to resolve")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Previews

#Preview("ConflictsListView") {
    NavigationStack {
        ConflictsListView(patientId: UUID())
    }
}

#Preview("ConflictsListView - Empty") {
    NavigationStack {
        ConflictsListView(patientId: UUID())
    }
}

#Preview("ConflictsSettingsSection - With Conflicts") {
    let service = ConflictResolutionService.preview
    return ConflictsSettingsSection(
        patientId: UUID(),
        conflictService: service
    )
    .padding()
}

#Preview("DailyCheckInConflictsBanner") {
    VStack(spacing: 16) {
        DailyCheckInConflictsBanner(pendingCount: 3) { }
        DailyCheckInConflictsBanner(pendingCount: 1) { }
    }
    .padding()
}
