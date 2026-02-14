//
//  TimelineFilterBar.swift
//  PTPerformance
//
//  X2Index Phase 2 - Canonical Timeline (M3)
//  Horizontal scrolling filter chips for timeline event types
//

import SwiftUI

/// Horizontal scrolling bar of filter chips for timeline events
struct TimelineFilterBar: View {

    // MARK: - Properties

    @ObservedObject var viewModel: CanonicalTimelineViewModel

    // MARK: - Body

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                // All filter
                allFilterChip

                // Divider
                Rectangle()
                    .fill(Color(.separator))
                    .frame(width: 1, height: 24)
                    .padding(.horizontal, 4)

                // Individual type filters
                ForEach(TimelineEventType.allCases) { type in
                    filterChip(for: type)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Subviews

    /// "All" filter chip
    private var allFilterChip: some View {
        Button {
            HapticService.selection()
            viewModel.clearFilters()
        } label: {
            HStack(spacing: 6) {
                Text("All")
                    .font(.subheadline.weight(.medium))

                if !viewModel.hasActiveFilters {
                    Text("\(viewModel.totalEventCount)")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            .foregroundColor(viewModel.hasActiveFilters ? .primary : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(viewModel.hasActiveFilters ? Color(.tertiarySystemFill) : Color.modusCyan)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("All events")
        .accessibilityValue(viewModel.hasActiveFilters ? "Not selected" : "Selected, \(viewModel.totalEventCount) events")
        .accessibilityHint("Double tap to show all event types")
    }

    /// Filter chip for a specific event type
    private func filterChip(for type: TimelineEventType) -> some View {
        let isSelected = viewModel.selectedFilters.contains(type)
        let count = viewModel.eventCounts[type] ?? 0
        let showAsActive = viewModel.selectedFilters.isEmpty || isSelected

        return Button {
            HapticService.selection()
            viewModel.toggleFilter(type)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: type.iconName)
                    .font(.caption)

                Text(type.pluralName)
                    .font(.subheadline.weight(.medium))

                if count > 0 {
                    Text("\(count)")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            showAsActive
                                ? Color.white.opacity(0.2)
                                : Color(.tertiarySystemFill)
                        )
                        .clipShape(Capsule())
                }
            }
            .foregroundColor(showAsActive ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(showAsActive ? type.color : Color(.tertiarySystemFill))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(type.pluralName)
        .accessibilityValue("\(isSelected ? "Selected" : "Not selected"), \(count) events")
        .accessibilityHint("Double tap to \(isSelected ? "hide" : "show") \(type.pluralName.lowercased())")
    }
}

// MARK: - Compact Filter Bar

/// Compact version of the filter bar showing only icons
struct TimelineFilterBarCompact: View {

    @ObservedObject var viewModel: CanonicalTimelineViewModel

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(TimelineEventType.allCases) { type in
                compactFilterButton(for: type)
            }

            Spacer()

            if viewModel.hasActiveFilters {
                Button {
                    HapticService.selection()
                    viewModel.clearFilters()
                } label: {
                    Text("Clear")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.modusCyan)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
    }

    private func compactFilterButton(for type: TimelineEventType) -> some View {
        let isSelected = viewModel.selectedFilters.contains(type)
        let showAsActive = viewModel.selectedFilters.isEmpty || isSelected

        return Button {
            HapticService.selection()
            viewModel.toggleFilter(type)
        } label: {
            Image(systemName: type.iconName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(showAsActive ? .white : .secondary)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(showAsActive ? type.color : Color(.tertiarySystemFill))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(type.pluralName)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}

// MARK: - Date Range Picker

/// Date range picker for timeline filtering
struct TimelineDateRangePicker: View {

    @ObservedObject var viewModel: CanonicalTimelineViewModel
    @State private var showCustomPicker = false

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Preset buttons
            ForEach([TimelineDateRange.today, .week, .month], id: \.id) { range in
                dateRangeButton(for: range)
            }

            // Custom button
            Button {
                showCustomPicker = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text(viewModel.selectedDateRange == .custom ? "Custom" : "More")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundColor(viewModel.selectedDateRange == .custom ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(viewModel.selectedDateRange == .custom ? Color.modusCyan : Color(.tertiarySystemFill))
                )
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .sheet(isPresented: $showCustomPicker) {
            CustomDateRangeSheet(viewModel: viewModel)
        }
    }

    private func dateRangeButton(for range: TimelineDateRange) -> some View {
        let isSelected = viewModel.selectedDateRange == range

        return Button {
            HapticService.selection()
            viewModel.setDateRange(range)
        } label: {
            Text(range.displayName)
                .font(.subheadline.weight(.medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.modusCyan : Color(.tertiarySystemFill))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Custom Date Range Sheet

/// Sheet for selecting custom date range
struct CustomDateRangeSheet: View {

    @ObservedObject var viewModel: CanonicalTimelineViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var startDate: Date
    @State private var endDate: Date

    init(viewModel: CanonicalTimelineViewModel) {
        self.viewModel = viewModel
        _startDate = State(initialValue: viewModel.customStartDate)
        _endDate = State(initialValue: viewModel.customEndDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Date Range") {
                    DatePicker(
                        "From",
                        selection: $startDate,
                        in: ...endDate,
                        displayedComponents: .date
                    )

                    DatePicker(
                        "To",
                        selection: $endDate,
                        in: startDate...,
                        displayedComponents: .date
                    )
                }

                Section("Quick Select") {
                    ForEach([TimelineDateRange.threeMonths, .year], id: \.id) { range in
                        Button {
                            let interval = range.dateInterval()
                            startDate = interval.start
                            endDate = interval.end
                        } label: {
                            Text(range.displayName)
                        }
                    }
                }
            }
            .navigationTitle("Select Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        viewModel.setCustomDateRange(start: startDate, end: endDate)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Previews

#Preview("Filter Bar") {
    VStack {
        TimelineFilterBar(viewModel: .preview)
        Spacer()
    }
}

#Preview("Filter Bar - With Selection") {
    let viewModel = CanonicalTimelineViewModel.preview
    viewModel.selectedFilters = [.workout, .checkIn]

    return VStack {
        TimelineFilterBar(viewModel: viewModel)
        Spacer()
    }
}

#Preview("Compact Filter Bar") {
    VStack {
        TimelineFilterBarCompact(viewModel: .preview)
        Spacer()
    }
}

#Preview("Date Range Picker") {
    VStack {
        TimelineDateRangePicker(viewModel: .preview)
        Spacer()
    }
}
