//
//  MemoryEfficientCollections.swift
//  PTPerformance
//
//  ACP-935: Memory Footprint Reduction
//  Memory-efficient collection types for large data sets. Provides lazy-loading
//  collections that page data on demand, auto-purging arrays that evict under
//  memory pressure, and a SwiftUI BudgetAwareList that unloads off-screen
//  data to reduce resident memory in long scrolling views.
//

import SwiftUI
import Combine

// MARK: - PagedDataSource

/// A generic lazy-loading data source that fetches items in pages on demand.
///
/// Instead of loading an entire collection into memory at once (e.g., full workout
/// history or exercise library), `PagedDataSource` loads pages of a fixed size as
/// the consumer requests indices near the end of the currently loaded data.
///
/// Thread safety is provided by actor isolation. All mutations and fetches are
/// serialized automatically.
///
/// Usage:
/// ```swift
/// let history = PagedDataSource<WorkoutRecord>(pageSize: 25) { offset, limit in
///     try await api.fetchWorkouts(offset: offset, limit: limit)
/// }
///
/// // Load the first page
/// try await history.loadNextPage()
///
/// // Access items
/// let first = await history.item(at: 0)
/// ```
actor PagedDataSource<Element: Sendable> {

    // MARK: - Types

    /// Closure type for fetching a page of data.
    /// Receives the offset (number of items already loaded) and the page size.
    /// Returns an array of new items. An empty array signals that all data has been loaded.
    typealias PageFetcher = @Sendable (_ offset: Int, _ limit: Int) async throws -> [Element]

    // MARK: - Properties

    /// Number of items to fetch per page.
    let pageSize: Int

    /// The fetcher closure provided at initialization.
    private let fetcher: PageFetcher

    /// All loaded items, stored contiguously for O(1) index access.
    private var items: [Element] = []

    /// Whether we have reached the end of available data.
    private var isExhausted = false

    /// Whether a fetch is currently in progress (prevents duplicate concurrent fetches).
    private var isFetching = false

    /// Number of items from the end at which to trigger a prefetch.
    private let prefetchThreshold: Int

    // MARK: - Initialization

    /// Create a paged data source.
    ///
    /// - Parameters:
    ///   - pageSize: Number of items per page. Defaults to 25.
    ///   - prefetchThreshold: Number of items from the end to trigger automatic prefetch. Defaults to 10.
    ///   - fetcher: Async closure that fetches a page of data.
    init(
        pageSize: Int = 25,
        prefetchThreshold: Int = 10,
        fetcher: @escaping PageFetcher
    ) {
        self.pageSize = pageSize
        self.prefetchThreshold = prefetchThreshold
        self.fetcher = fetcher
    }

    // MARK: - Public API

    /// Load the next page of data.
    ///
    /// Safe to call multiple times — concurrent calls are coalesced and calls
    /// after exhaustion are no-ops.
    ///
    /// - Throws: Rethrows errors from the fetcher.
    func loadNextPage() async throws {
        guard !isExhausted, !isFetching else { return }

        isFetching = true
        defer { isFetching = false }

        let offset = items.count
        let newItems = try await fetcher(offset, pageSize)

        items.append(contentsOf: newItems)

        if newItems.count < pageSize {
            isExhausted = true
        }
    }

    /// Access an item at the given index. Automatically triggers a prefetch
    /// if the index is near the end of loaded data.
    ///
    /// - Parameter index: The zero-based index.
    /// - Returns: The item, or nil if the index is out of bounds.
    func item(at index: Int) -> Element? {
        guard index >= 0, index < items.count else { return nil }

        // Trigger prefetch if approaching the end
        if !isExhausted && index >= items.count - prefetchThreshold {
            Task { [weak self] in
                try? await self?.loadNextPage()
            }
        }

        return items[index]
    }

    /// The total number of currently loaded items.
    var loadedCount: Int {
        items.count
    }

    /// Whether all available data has been loaded.
    var hasLoadedAll: Bool {
        isExhausted
    }

    /// Whether a fetch is currently in progress.
    var isLoading: Bool {
        isFetching
    }

    /// Get a copy of all currently loaded items.
    var allLoadedItems: [Element] {
        items
    }

    /// Reset the data source, clearing all loaded data and allowing re-fetching.
    func reset() {
        items.removeAll()
        isExhausted = false
        isFetching = false
    }

    /// Approximate memory footprint of the loaded items in bytes.
    /// Uses MemoryLayout stride as a lower-bound estimate.
    var estimatedMemoryBytes: Int64 {
        Int64(items.count * MemoryLayout<Element>.stride)
    }
}

// MARK: - AutoPurgingArray

/// A thread-safe array that automatically purges its least-recently-accessed
/// entries when memory pressure is detected or when it exceeds a configurable
/// capacity limit.
///
/// Items are wrapped with access metadata to support LRU eviction. The array
/// listens for memory pressure notifications from ``MemoryBudgetManager`` and
/// can be manually purged.
///
/// This is ideal for caching decoded model objects (exercises, templates) where
/// re-fetching from disk or network is possible but expensive.
///
/// Usage:
/// ```swift
/// let exercises = AutoPurgingArray<Exercise>(maxCount: 200, evictionRatio: 0.5)
/// exercises.append(exercise)
/// exercises.appendContentsOf(moreExercises)
///
/// // Access updates LRU timestamp
/// let item = exercises[0]
///
/// // Manual purge
/// exercises.purge(ratio: 0.25) // Remove oldest 25%
/// ```
final class AutoPurgingArray<Element>: @unchecked Sendable {

    // MARK: - Entry Wrapper

    /// Internal wrapper that tracks access time for LRU eviction.
    private struct Entry {
        var value: Element
        var lastAccess: Date

        init(value: Element) {
            self.value = value
            self.lastAccess = Date()
        }

        mutating func touch() {
            lastAccess = Date()
        }
    }

    // MARK: - Properties

    /// Maximum number of items before automatic eviction kicks in.
    private let maxCount: Int

    /// Fraction of items to evict when capacity is exceeded (0.0 - 1.0).
    private let evictionRatio: Double

    /// Internal storage, protected by a lock for thread safety.
    private var entries: [Entry] = []

    /// Serial queue for synchronized access.
    private let lock = NSLock()

    /// Observer for memory warning notifications.
    private var memoryWarningObserver: NSObjectProtocol?

    // MARK: - Initialization

    /// Create an auto-purging array.
    ///
    /// - Parameters:
    ///   - maxCount: Maximum number of items. When exceeded, the oldest entries
    ///     are evicted. Defaults to 500.
    ///   - evictionRatio: Fraction of entries to evict per purge pass (0.0 - 1.0).
    ///     Defaults to 0.25 (evict 25% of entries).
    init(maxCount: Int = 500, evictionRatio: Double = 0.25) {
        self.maxCount = maxCount
        self.evictionRatio = Swift.min(Swift.max(evictionRatio, 0.05), 1.0)

        registerForMemoryWarnings()
    }

    deinit {
        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Public API: Mutation

    /// Append a single item.
    func append(_ item: Element) {
        lock.lock()
        entries.append(Entry(value: item))
        let needsPurge = entries.count > maxCount
        lock.unlock()

        if needsPurge {
            purge(ratio: evictionRatio)
        }
    }

    /// Append multiple items at once.
    func appendContentsOf(_ items: [Element]) {
        lock.lock()
        entries.append(contentsOf: items.map { Entry(value: $0) })
        let needsPurge = entries.count > maxCount
        lock.unlock()

        if needsPurge {
            purge(ratio: evictionRatio)
        }
    }

    /// Remove all items.
    func removeAll() {
        lock.lock()
        entries.removeAll()
        lock.unlock()
    }

    /// Remove items matching a predicate.
    func removeWhere(_ predicate: (Element) -> Bool) {
        lock.lock()
        entries.removeAll { predicate($0.value) }
        lock.unlock()
    }

    // MARK: - Public API: Access

    /// Access an item by index. Updates the LRU access timestamp.
    ///
    /// - Parameter index: Zero-based index.
    /// - Returns: The item, or nil if out of bounds.
    subscript(index: Int) -> Element? {
        lock.lock()
        defer { lock.unlock() }

        guard index >= 0, index < entries.count else { return nil }
        entries[index].touch()
        return entries[index].value
    }

    /// The number of currently stored items.
    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return entries.count
    }

    /// Whether the array is empty.
    var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        return entries.isEmpty
    }

    /// Get a snapshot of all current values (does not update access times).
    var allValues: [Element] {
        lock.lock()
        defer { lock.unlock() }
        return entries.map(\.value)
    }

    /// Approximate memory footprint in bytes.
    var estimatedMemoryBytes: Int64 {
        lock.lock()
        defer { lock.unlock() }
        return Int64(entries.count * MemoryLayout<Entry>.stride)
    }

    // MARK: - Public API: Purging

    /// Purge a fraction of the oldest (least-recently-accessed) entries.
    ///
    /// - Parameter ratio: Fraction to remove (0.0 - 1.0). For example, 0.25
    ///   removes the oldest 25% of entries.
    func purge(ratio: Double) {
        lock.lock()

        let countToRemove = Int(Double(entries.count) * Swift.min(Swift.max(ratio, 0), 1.0))
        guard countToRemove > 0 else {
            lock.unlock()
            return
        }

        // Sort by last access (oldest first), then remove the oldest entries
        entries.sort { $0.lastAccess < $1.lastAccess }
        entries.removeFirst(Swift.min(countToRemove, entries.count))

        lock.unlock()
    }

    /// Purge entries older than the given date.
    ///
    /// - Parameter date: Entries last accessed before this date are removed.
    func purgeOlderThan(_ date: Date) {
        lock.lock()
        entries.removeAll { $0.lastAccess < date }
        lock.unlock()
    }

    // MARK: - Private

    /// Register for system memory warning notifications for automatic purging.
    private func registerForMemoryWarnings() {
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // On memory warning, purge 50% of entries
            self?.purge(ratio: 0.5)
        }
    }
}

// MARK: - Sequence Conformance

extension AutoPurgingArray: Sequence {
    func makeIterator() -> IndexingIterator<[Element]> {
        allValues.makeIterator()
    }
}

// MARK: - WindowedCollection

/// A collection that maintains only a "window" of items around the currently
/// visible range, unloading items outside the window to save memory.
///
/// This is designed for large ordered data sets (e.g., workout history with
/// thousands of entries) where only a subset is visible at any time. Items
/// outside the window are released, and a `reload` closure is called to
/// re-fetch them when they scroll back into view.
///
/// Usage:
/// ```swift
/// let collection = WindowedCollection<WorkoutRecord>(
///     totalCount: 2000,
///     windowSize: 100
/// ) { range in
///     try await api.fetchWorkouts(range: range)
/// }
///
/// await collection.loadWindow(around: 500)
/// let item = await collection.item(at: 500)
/// ```
actor WindowedCollection<Element: Sendable> {

    // MARK: - Types

    /// Closure that loads items for a given index range.
    typealias WindowLoader = @Sendable (Range<Int>) async throws -> [Element]

    // MARK: - Properties

    /// The total number of items in the full data set (may be an estimate).
    private(set) var totalCount: Int

    /// How many items to keep loaded around the focus point.
    let windowSize: Int

    /// The currently loaded window range.
    private(set) var loadedRange: Range<Int> = 0..<0

    /// Sparse storage for loaded items.
    private var items: [Int: Element] = [:]

    /// The loader closure.
    private let loader: WindowLoader

    /// Whether a load is currently in progress.
    private var isLoading = false

    // MARK: - Initialization

    /// Create a windowed collection.
    ///
    /// - Parameters:
    ///   - totalCount: The total number of items in the data set.
    ///   - windowSize: Number of items to keep loaded. Defaults to 100.
    ///   - loader: Closure that loads items for a range of indices.
    init(
        totalCount: Int,
        windowSize: Int = 100,
        loader: @escaping WindowLoader
    ) {
        self.totalCount = totalCount
        self.windowSize = windowSize
        self.loader = loader
    }

    // MARK: - Public API

    /// Load a window of items centered around the given index.
    ///
    /// Items outside the new window are released. If the new window overlaps
    /// with the current window, only the non-overlapping portions are loaded.
    ///
    /// - Parameter centerIndex: The index to center the window around.
    func loadWindow(around centerIndex: Int) async throws {
        guard !isLoading else { return }

        let halfWindow = windowSize / 2
        let newStart = max(0, centerIndex - halfWindow)
        let newEnd = min(totalCount, centerIndex + halfWindow)
        let newRange = newStart..<newEnd

        // Skip if the new range is a subset of the current range
        guard !loadedRange.contains(newStart) || !loadedRange.contains(newEnd - 1) else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        // Determine which ranges need loading
        let rangesToLoad: [Range<Int>]
        if loadedRange.isEmpty || !loadedRange.overlaps(newRange) {
            // No overlap — load the entire new range
            rangesToLoad = [newRange]
        } else {
            // Partial overlap — only load the missing parts
            var ranges: [Range<Int>] = []
            if newRange.lowerBound < loadedRange.lowerBound {
                ranges.append(newRange.lowerBound..<loadedRange.lowerBound)
            }
            if newRange.upperBound > loadedRange.upperBound {
                ranges.append(loadedRange.upperBound..<newRange.upperBound)
            }
            rangesToLoad = ranges
        }

        // Load missing ranges
        for range in rangesToLoad where !range.isEmpty {
            let newItems = try await loader(range)
            for (offset, item) in newItems.enumerated() {
                let index = range.lowerBound + offset
                if index < totalCount {
                    items[index] = item
                }
            }
        }

        // Evict items outside the new window
        let keysToRemove = items.keys.filter { !newRange.contains($0) }
        for key in keysToRemove {
            items.removeValue(forKey: key)
        }

        loadedRange = newRange
    }

    /// Access an item by index. Returns nil if the index is outside the loaded window.
    ///
    /// - Parameter index: The zero-based index.
    /// - Returns: The item, or nil if not currently loaded.
    func item(at index: Int) -> Element? {
        items[index]
    }

    /// Whether the given index is within the currently loaded window.
    func isLoaded(_ index: Int) -> Bool {
        items[index] != nil
    }

    /// Number of items currently in memory.
    var loadedCount: Int {
        items.count
    }

    /// Update the total count (e.g., when new data becomes available).
    func updateTotalCount(_ count: Int) {
        totalCount = count
    }

    /// Clear all loaded data and reset the window.
    func reset() {
        items.removeAll()
        loadedRange = 0..<0
    }

    /// Approximate memory footprint of currently loaded items.
    var estimatedMemoryBytes: Int64 {
        Int64(items.count * MemoryLayout<Element>.stride)
    }
}

// MARK: - BudgetAwareListDataSource

/// An ObservableObject that bridges ``PagedDataSource`` to SwiftUI views.
///
/// Provides `@Published` properties for the loaded items and loading state,
/// handles paging automatically as the user scrolls, and reports memory usage
/// to ``MemoryBudgetManager``.
///
/// Usage:
/// ```swift
/// @StateObject var dataSource = BudgetAwareListDataSource<Exercise>(
///     subsystem: .exerciseLibrary,
///     pageSize: 30
/// ) { offset, limit in
///     try await ExerciseService.shared.fetchExercises(offset: offset, limit: limit)
/// }
/// ```
@MainActor
final class BudgetAwareListDataSource<Element: Identifiable & Sendable>: ObservableObject {

    // MARK: - Published State

    /// The currently loaded items, safe to bind to SwiftUI views.
    @Published private(set) var items: [Element] = []

    /// Whether a page load is currently in progress.
    @Published private(set) var isLoading = false

    /// Whether all available data has been loaded.
    @Published private(set) var hasLoadedAll = false

    /// Error from the most recent load attempt, if any.
    @Published private(set) var loadError: Error?

    // MARK: - Properties

    /// The subsystem identifier for memory budget tracking.
    let subsystem: SubsystemID

    /// The backing paged data source.
    private let pagedSource: PagedDataSource<Element>

    // MARK: - Initialization

    /// Create a memory-efficient list data source.
    ///
    /// - Parameters:
    ///   - subsystem: The subsystem to report memory usage under.
    ///   - pageSize: Number of items per page.
    ///   - prefetchThreshold: Items from end to trigger prefetch.
    ///   - fetcher: Async closure that fetches a page of data.
    init(
        subsystem: SubsystemID,
        pageSize: Int = 25,
        prefetchThreshold: Int = 10,
        fetcher: @escaping PagedDataSource<Element>.PageFetcher
    ) {
        self.subsystem = subsystem
        self.pagedSource = PagedDataSource(
            pageSize: pageSize,
            prefetchThreshold: prefetchThreshold,
            fetcher: fetcher
        )
    }

    // MARK: - Public API

    /// Load the initial page of data.
    func loadInitialPage() async {
        guard items.isEmpty else { return }
        await loadNextPage()
    }

    /// Load the next page of data.
    func loadNextPage() async {
        guard !isLoading, !hasLoadedAll else { return }

        isLoading = true
        loadError = nil

        do {
            try await pagedSource.loadNextPage()

            let allItems = await pagedSource.allLoadedItems
            let exhausted = await pagedSource.hasLoadedAll

            items = allItems
            hasLoadedAll = exhausted

            // Report memory usage
            let memoryBytes = await pagedSource.estimatedMemoryBytes
            await MemoryBudgetManager.shared.updateSubsystemUsage(subsystem, bytes: memoryBytes)
        } catch {
            if !error.isCancellation {
                loadError = error
                DebugLogger.shared.log(
                    "[BudgetAwareListDataSource] Load failed: \(error.localizedDescription)",
                    level: .warning
                )
            }
        }

        isLoading = false
    }

    /// Called when a row at the given index appears. Triggers prefetch if needed.
    func onItemAppeared(at index: Int) {
        let threshold = max(items.count - 10, 0)
        if index >= threshold && !hasLoadedAll && !isLoading {
            Task {
                await loadNextPage()
            }
        }
    }

    /// Reset the data source and reload from scratch.
    func reset() async {
        await pagedSource.reset()
        items = []
        hasLoadedAll = false
        loadError = nil
        await loadNextPage()
    }
}

// MARK: - BudgetAwareList

/// A SwiftUI List wrapper that uses ``BudgetAwareListDataSource`` for
/// lazy loading with automatic paging and memory-budget-aware data management.
///
/// As the user scrolls, new pages are loaded automatically. The list shows
/// a loading indicator at the bottom while fetching, and placeholder cells
/// for a polished experience.
///
/// Usage:
/// ```swift
/// BudgetAwareList(dataSource: exerciseDataSource) { exercise in
///     ExerciseRow(exercise: exercise)
/// }
/// ```
struct BudgetAwareList<Element: Identifiable & Sendable, RowContent: View>: View {

    @ObservedObject var dataSource: BudgetAwareListDataSource<Element>
    let rowContent: (Element) -> RowContent

    init(
        dataSource: BudgetAwareListDataSource<Element>,
        @ViewBuilder rowContent: @escaping (Element) -> RowContent
    ) {
        self.dataSource = dataSource
        self.rowContent = rowContent
    }

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(dataSource.items.enumerated()), id: \.element.id) { index, item in
                rowContent(item)
                    .onAppear {
                        dataSource.onItemAppeared(at: index)
                    }
            }

            if dataSource.isLoading {
                loadingFooter
            }

            if let error = dataSource.loadError {
                errorFooter(error: error)
            }
        }
        .task {
            await dataSource.loadInitialPage()
        }
    }

    // MARK: - Subviews

    private var loadingFooter: some View {
        HStack {
            Spacer()
            ProgressView()
                .padding()
            Spacer()
        }
    }

    private func errorFooter(error: Error) -> some View {
        VStack(spacing: 8) {
            Text("Failed to load more items")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button("Retry") {
                Task {
                    await dataSource.loadNextPage()
                }
            }
            .font(.subheadline)
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

// MARK: - OffscreenUnloadingModifier

/// A view modifier that tracks visibility and notifies a coordinator when a view
/// goes off-screen, enabling data unloading for views that are no longer visible.
///
/// Pairs with ``MemoryBudgetManager`` to reduce the memory footprint of long
/// scrolling lists by releasing data for cells that have scrolled far out of view.
///
/// Usage:
/// ```swift
/// ExerciseRow(exercise: exercise)
///     .unloadWhenOffscreen(id: exercise.id) {
///         // Release heavy data
///         exercise.clearCachedImages()
///     } onReload: {
///         // Reload when scrolling back
///         exercise.loadThumbnail()
///     }
/// ```
struct OffscreenUnloadingModifier: ViewModifier {

    let onUnload: () -> Void
    let onReload: (() -> Void)?

    @State private var isVisible = false
    @State private var unloadTask: Task<Void, Never>?

    /// Delay before unloading after disappearing, to avoid unloading during
    /// brief off-screen moments (e.g., small scrolls or keyboard appearance).
    private let unloadDelay: TimeInterval = 3.0

    func body(content: Content) -> some View {
        content
            .onAppear {
                isVisible = true
                unloadTask?.cancel()
                unloadTask = nil
                onReload?()
            }
            .onDisappear {
                isVisible = false
                unloadTask = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: UInt64(unloadDelay * 1_000_000_000))
                    guard !Task.isCancelled, !isVisible else { return }
                    onUnload()
                }
            }
    }
}

extension View {
    /// Unload heavy data when this view scrolls off screen, and optionally
    /// reload it when it scrolls back into view.
    ///
    /// A 3-second delay prevents unnecessary unload/reload cycles during
    /// brief visibility changes.
    ///
    /// - Parameters:
    ///   - onUnload: Closure called when the view has been off-screen for 3 seconds.
    ///   - onReload: Optional closure called when the view reappears.
    func unloadWhenOffscreen(
        onUnload: @escaping () -> Void,
        onReload: (() -> Void)? = nil
    ) -> some View {
        modifier(OffscreenUnloadingModifier(
            onUnload: onUnload,
            onReload: onReload
        ))
    }
}
