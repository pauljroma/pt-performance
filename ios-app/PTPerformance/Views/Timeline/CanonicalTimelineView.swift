//
//  CanonicalTimelineView.swift
//  PTPerformance
//
//  X2Index Phase 2 - Canonical Timeline (M3)
//  Main timeline view showing all health events in chronological order
//

import SwiftUI

/// Main canonical timeline view displaying all health events
struct CanonicalTimelineView: View {

    // MARK: - Properties

    let patientId: UUID

    @StateObject private var viewModel: CanonicalTimelineViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showDatePicker = false

    // MARK: - Initialization

    init(patientId: UUID) {
        self.patientId = patientId
        _viewModel = StateObject(wrappedValue: CanonicalTimelineViewModel(patientId: patientId))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Filter bar
            TimelineFilterBar(viewModel: viewModel)
                .background(Color(.systemBackground))
                .shadow(color: Color(.systemGray4).opacity(0.05), radius: 2, y: 2)

            // Date range selector
            dateRangeHeader

            // Main content
            if viewModel.isLoading && !viewModel.hasLoaded {
                loadingView
            } else if !viewModel.hasEvents {
                emptyStateView
            } else {
                timelineContent
            }
        }
        .navigationTitle("Timeline")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                toolbarMenu
            }
        }
        .refreshable {
            HapticFeedback.light()
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadTimeline()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
            Button("Retry") {
                Task {
                    await viewModel.loadTimeline()
                }
            }
        } message: {
            Text(viewModel.errorMessage)
        }
        .sheet(isPresented: $showDatePicker) {
            CustomDateRangeSheet(viewModel: viewModel)
        }
    }

    // MARK: - Date Range Header

    private var dateRangeHeader: some View {
        HStack(spacing: Spacing.sm) {
            // Date range display
            Button {
                showDatePicker = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text(viewModel.dateRangeDisplayString)
                        .font(.subheadline.weight(.medium))
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.semibold))
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.tertiarySystemFill))
                )
            }
            .buttonStyle(.plain)

            Spacer()

            // Quick date range buttons
            HStack(spacing: 8) {
                quickDateButton(range: .today)
                quickDateButton(range: .week)
                quickDateButton(range: .month)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .background(Color(.systemBackground))
    }

    private func quickDateButton(range: TimelineDateRange) -> some View {
        let isSelected = viewModel.selectedDateRange == range

        return Button {
            HapticService.selection()
            viewModel.setDateRange(range)
        } label: {
            Text(range.displayName)
                .font(.caption.weight(.medium))
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.modusCyan : Color(.quaternarySystemFill))
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Toolbar Menu

    private var toolbarMenu: some View {
        Menu {
            Section("Filters") {
                Button {
                    viewModel.clearFilters()
                } label: {
                    Label("Show All", systemImage: "line.3.horizontal.decrease.circle")
                }

                ForEach(TimelineEventType.allCases) { type in
                    Button {
                        viewModel.toggleFilter(type)
                    } label: {
                        Label {
                            Text(type.pluralName)
                        } icon: {
                            Image(systemName: viewModel.selectedFilters.contains(type) ? "checkmark.circle.fill" : type.iconName)
                        }
                    }
                }
            }

            if viewModel.conflictEventCount > 0 {
                Section("Conflicts") {
                    Label("\(viewModel.conflictEventCount) events with conflicts", systemImage: "exclamationmark.triangle.fill")
                }
            }

            Section {
                Button {
                    Task {
                        await viewModel.refresh()
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.body)
        }
    }

    // MARK: - Timeline Content

    private var timelineContent: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(viewModel.groupedEvents, id: \.0) { section, events in
                    Section {
                        ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                            TimelineEventCard(
                                event: event,
                                isExpanded: viewModel.isExpanded(event),
                                isLastInSection: index == events.count - 1,
                                detail: viewModel.isExpanded(event) ? viewModel.expandedEventDetail : nil,
                                onTap: {
                                    viewModel.expandEvent(id: event.id)
                                }
                            )
                            .padding(.vertical, 4)
                        }
                    } header: {
                        TimelineSectionHeader(
                            title: section,
                            eventCount: events.count
                        )
                        .background(Color(.systemBackground))
                    }
                }

                // Bottom padding for scroll
                Color.clear
                    .frame(height: 100)
            }
            .padding(.top, Spacing.xs)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading timeline...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            // Icon
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            // Title
            Text("No Events Found")
                .font(.title2.weight(.bold))
                .foregroundColor(.primary)

            // Description
            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            // Action buttons
            VStack(spacing: Spacing.sm) {
                if viewModel.hasActiveFilters {
                    Button {
                        viewModel.clearFilters()
                    } label: {
                        Label("Clear Filters", systemImage: "xmark.circle.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.modusCyan)
                            .clipShape(Capsule())
                    }
                }

                Button {
                    viewModel.setDateRange(.month)
                } label: {
                    Text("Try Last Month")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.modusCyan)
                }
            }

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private var emptyStateMessage: String {
        if viewModel.hasActiveFilters {
            let filterNames = viewModel.selectedFilters.map { $0.pluralName.lowercased() }.joined(separator: ", ")
            return "No \(filterNames) found for \(viewModel.dateRangeDisplayString.lowercased())."
        }
        return "No health events recorded for \(viewModel.dateRangeDisplayString.lowercased()). Complete check-ins, log workouts, or sync with Apple Health to see your timeline."
    }
}

// MARK: - Conflict Summary View

/// Summary view showing all detected conflicts
struct TimelineConflictSummaryView: View {

    let conflicts: [ConflictGroup]
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            List {
                ForEach(conflicts) { conflict in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: conflict.conflictType.iconName)
                                .foregroundColor(conflict.conflictType.color)
                            Text(conflict.conflictType.displayName)
                                .font(.headline)
                        }

                        Text(conflict.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text(conflict.timestamp, style: .date)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Data Conflicts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Timeline - With Data") {
    NavigationStack {
        CanonicalTimelineView(patientId: UUID())
    }
}

#Preview("Timeline - Loading") {
    NavigationStack {
        let view = CanonicalTimelineView(patientId: UUID())
        view
    }
}

#Preview("Timeline - Empty") {
    NavigationStack {
        CanonicalTimelineView(patientId: UUID())
    }
}

#Preview("Timeline - With Filters") {
    NavigationStack {
        CanonicalTimelineView(patientId: UUID())
    }
}

// MARK: - Preview Provider for ViewModel

extension CanonicalTimelineView {
    /// Create a preview with pre-populated data
    static func previewWithData() -> some View {
        let viewModel = CanonicalTimelineViewModel.preview
        return NavigationStack {
            TimelinePreviewWrapper(viewModel: viewModel)
        }
    }
}

/// Wrapper for preview with injected view model
private struct TimelinePreviewWrapper: View {
    @StateObject var viewModel: CanonicalTimelineViewModel

    var body: some View {
        VStack(spacing: 0) {
            TimelineFilterBar(viewModel: viewModel)

            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    ForEach(viewModel.groupedEvents, id: \.0) { section, events in
                        Section {
                            ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                                TimelineEventCard(
                                    event: event,
                                    isExpanded: viewModel.isExpanded(event),
                                    isLastInSection: index == events.count - 1,
                                    detail: nil,
                                    onTap: {
                                        viewModel.expandEvent(id: event.id)
                                    }
                                )
                                .padding(.vertical, 4)
                            }
                        } header: {
                            TimelineSectionHeader(
                                title: section,
                                eventCount: events.count
                            )
                            .background(Color(.systemBackground))
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
        .navigationTitle("Timeline")
    }
}

#Preview("Timeline - Preview Data") {
    CanonicalTimelineView.previewWithData()
}
