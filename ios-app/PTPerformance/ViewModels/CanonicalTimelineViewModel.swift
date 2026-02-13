//
//  CanonicalTimelineViewModel.swift
//  PTPerformance
//
//  X2Index Phase 2 - Canonical Timeline (M3)
//  ViewModel for managing timeline state and interactions
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for the Canonical Timeline view
@MainActor
final class CanonicalTimelineViewModel: ObservableObject {

    // MARK: - Static Formatters
    private static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    // MARK: - Published Properties

    /// All events for current date range and filters
    @Published var events: [TimelineEvent] = []

    /// Currently selected event types to display
    @Published var selectedFilters: Set<TimelineEventType> = []

    /// Current date range for timeline
    @Published var dateRange: DateInterval

    /// Selected preset date range
    @Published var selectedDateRange: TimelineDateRange = .week

    /// Custom date range start (used when selectedDateRange is .custom)
    @Published var customStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()

    /// Custom date range end
    @Published var customEndDate: Date = Date()

    /// Event counts by type for filter badges
    @Published var eventCounts: [TimelineEventType: Int] = [:]

    /// Currently expanded event ID
    @Published var expandedEventId: UUID?

    /// Event detail for expanded view
    @Published var expandedEventDetail: TimelineEventDetail?

    /// Conflict groups detected in current events
    @Published var conflictGroups: [ConflictGroup] = []

    /// Loading state
    @Published var isLoading = false

    /// Error state
    @Published var showError = false
    @Published var errorMessage = ""

    /// Whether initial load has completed
    @Published var hasLoaded = false

    // MARK: - Private Properties

    private let patientId: UUID
    private let timelineService: TimelineService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(patientId: UUID, timelineService: TimelineService = .shared) {
        self.patientId = patientId
        self.timelineService = timelineService
        self.dateRange = TimelineDateRange.week.dateInterval()

        setupBindings()
    }

    deinit {
        cancellables.removeAll()
    }

    // MARK: - Private Methods

    private func setupBindings() {
        // Update date range when preset changes
        $selectedDateRange
            .dropFirst()
            .sink { [weak self] range in
                guard let self = self else { return }
                if range != .custom {
                    self.dateRange = range.dateInterval()
                    Task {
                        await self.loadTimeline()
                    }
                }
            }
            .store(in: &cancellables)

        // Update date range when custom dates change
        Publishers.CombineLatest($customStartDate, $customEndDate)
            .dropFirst()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] start, end in
                guard let self = self, self.selectedDateRange == .custom else { return }
                self.dateRange = DateInterval(start: start, end: end)
                Task {
                    await self.loadTimeline()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Public API

    /// Load timeline events for current date range and filters
    func loadTimeline() async {
        isLoading = true
        showError = false

        do {
            let types = selectedFilters.isEmpty ? nil : Array(selectedFilters)
            events = try await timelineService.getTimeline(
                patientId: patientId,
                dateRange: dateRange,
                types: types
            )

            // Get event counts for all types (unfiltered)
            eventCounts = try await timelineService.getEventCounts(
                patientId: patientId,
                dateRange: dateRange
            )

            // Detect conflicts
            conflictGroups = timelineService.detectConflicts(events: events)

            hasLoaded = true
        } catch {
            handleError(error)
        }

        isLoading = false
    }

    /// Refresh timeline data
    func refresh() async {
        await loadTimeline()
    }

    /// Toggle filter for event type
    func toggleFilter(_ type: TimelineEventType) {
        if selectedFilters.contains(type) {
            selectedFilters.remove(type)
        } else {
            selectedFilters.insert(type)
        }

        // Apply filter immediately
        Task {
            await loadTimeline()
        }
    }

    /// Clear all filters
    func clearFilters() {
        selectedFilters.removeAll()
        Task {
            await loadTimeline()
        }
    }

    /// Select all event types
    func selectAllFilters() {
        selectedFilters = Set(TimelineEventType.allCases)
        Task {
            await loadTimeline()
        }
    }

    /// Check if a filter is selected
    func isFilterSelected(_ type: TimelineEventType) -> Bool {
        selectedFilters.isEmpty || selectedFilters.contains(type)
    }

    /// Expand an event to show details
    func expandEvent(id: UUID) {
        if expandedEventId == id {
            // Toggle off if already expanded
            collapseEvent()
        } else {
            expandedEventId = id
            loadEventDetail(id: id)
        }
    }

    /// Collapse expanded event
    func collapseEvent() {
        withAnimation(.easeInOut(duration: 0.2)) {
            expandedEventId = nil
            expandedEventDetail = nil
        }
    }

    /// Check if an event is expanded
    func isExpanded(_ event: TimelineEvent) -> Bool {
        expandedEventId == event.id
    }

    /// Set custom date range
    func setCustomDateRange(start: Date, end: Date) {
        selectedDateRange = .custom
        customStartDate = start
        customEndDate = end
        dateRange = DateInterval(start: start, end: end)

        Task {
            await loadTimeline()
        }
    }

    /// Set preset date range
    func setDateRange(_ range: TimelineDateRange) {
        selectedDateRange = range
        if range != .custom {
            dateRange = range.dateInterval()
        }
    }

    // MARK: - Computed Properties

    /// Events grouped by section date for display
    var groupedEvents: [(String, [TimelineEvent])] {
        let grouped = Dictionary(grouping: events) { $0.sectionDate }

        // Sort sections: Today first, then Yesterday, etc.
        let sectionOrder = ["Today", "Yesterday", "This Week", "This Month"]

        return grouped.sorted { first, second in
            let firstIndex = sectionOrder.firstIndex(of: first.key) ?? Int.max
            let secondIndex = sectionOrder.firstIndex(of: second.key) ?? Int.max

            if firstIndex == Int.max && secondIndex == Int.max {
                // Both are date strings, sort chronologically (newest first)
                return first.value.first?.timestamp ?? Date() > second.value.first?.timestamp ?? Date()
            }

            return firstIndex < secondIndex
        }
    }

    /// Total number of events
    var totalEventCount: Int {
        events.count
    }

    /// Number of events with conflicts
    var conflictEventCount: Int {
        events.filter { $0.hasConflicts }.count
    }

    /// Whether there are any events to display
    var hasEvents: Bool {
        !events.isEmpty
    }

    /// Whether any filters are active
    var hasActiveFilters: Bool {
        !selectedFilters.isEmpty
    }

    /// Date range display string
    var dateRangeDisplayString: String {
        if selectedDateRange != .custom {
            return selectedDateRange.displayName
        }

        return "\(Self.mediumDateFormatter.string(from: dateRange.start)) - \(Self.mediumDateFormatter.string(from: dateRange.end))"
    }

    // MARK: - Private Helpers

    private func loadEventDetail(id: UUID) {
        Task {
            do {
                let detail = try await timelineService.getEventDetail(eventId: id)
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedEventDetail = detail
                }
            } catch {
                DebugLogger.shared.warning("TIMELINE", "Failed to load event detail: \(error.localizedDescription)")
            }
        }
    }

    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
        DebugLogger.shared.error("TIMELINE", "Timeline error: \(error.localizedDescription)")
    }
}

// MARK: - Preview Helpers

extension CanonicalTimelineViewModel {
    /// Create a preview view model with sample data
    static var preview: CanonicalTimelineViewModel {
        let viewModel = CanonicalTimelineViewModel(patientId: UUID())
        viewModel.events = TimelineEvent.generateSampleEvents(count: 15)
        viewModel.hasLoaded = true

        // Set sample counts
        for type in TimelineEventType.allCases {
            viewModel.eventCounts[type] = viewModel.events.filter { $0.eventType == type }.count
        }

        return viewModel
    }

    /// Create an empty preview view model
    static var emptyPreview: CanonicalTimelineViewModel {
        let viewModel = CanonicalTimelineViewModel(patientId: UUID())
        viewModel.hasLoaded = true
        return viewModel
    }

    /// Create a loading preview view model
    static var loadingPreview: CanonicalTimelineViewModel {
        let viewModel = CanonicalTimelineViewModel(patientId: UUID())
        viewModel.isLoading = true
        return viewModel
    }
}
