//
//  ViewPerformanceModifiers.swift
//  PTPerformance
//
//  BUILD 95 - Agent 8: Performance optimization
//  SwiftUI view modifiers to reduce unnecessary re-renders and improve performance
//

import SwiftUI

// MARK: - Equatable View Modifier

/// Prevents view updates when content hasn't actually changed
/// Usage: .equatable() on any view that conforms to Equatable
extension View where Self: Equatable {
    func preventUnnecessaryUpdates() -> some View {
        EquatableView(content: self)
    }
}

private struct EquatableView<Content: View & Equatable>: View, Equatable {
    let content: Content

    static func == (lhs: EquatableView<Content>, rhs: EquatableView<Content>) -> Bool {
        lhs.content == rhs.content
    }

    var body: some View {
        content
    }
}

// MARK: - Debounced State

/// Property wrapper to debounce state changes and reduce re-renders
/// Usage: @DebouncedState(delay: 0.3) var searchText = ""
@propertyWrapper
struct DebouncedState<Value>: DynamicProperty {
    @State private var currentValue: Value
    @State private var debouncedValue: Value
    @State private var debounceTask: Task<Void, Never>?

    let delay: TimeInterval

    init(wrappedValue: Value, delay: TimeInterval = 0.3) {
        self.delay = delay
        self._currentValue = State(initialValue: wrappedValue)
        self._debouncedValue = State(initialValue: wrappedValue)
    }

    var wrappedValue: Value {
        get { currentValue }
        nonmutating set {
            currentValue = newValue

            debounceTask?.cancel()
            debounceTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                if !Task.isCancelled {
                    await MainActor.run {
                        debouncedValue = newValue
                    }
                }
            }
        }
    }

    var projectedValue: Value {
        debouncedValue
    }
}

// MARK: - Lazy Loading Modifier

/// Only loads view content when it appears on screen
/// Useful for lists with heavy content
struct LazyLoadModifier: ViewModifier {
    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        Group {
            if hasAppeared {
                content
            } else {
                Color.clear
                    .onAppear {
                        hasAppeared = true
                    }
            }
        }
    }
}

extension View {
    /// Defer view rendering until it appears on screen
    func lazyLoad() -> some View {
        modifier(LazyLoadModifier())
    }
}

// MARK: - Task Debouncer

/// Debounces async tasks to prevent redundant network calls
actor TaskDebouncer {
    private var pendingTask: Task<Void, Never>?
    private let delay: TimeInterval

    init(delay: TimeInterval = 0.3) {
        self.delay = delay
    }

    func debounce(action: @escaping () async -> Void) {
        pendingTask?.cancel()

        pendingTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

            if !Task.isCancelled {
                await action()
            }
        }
    }

    func cancel() {
        pendingTask?.cancel()
    }
}

// MARK: - Memory-Efficient List

/// Use this instead of ForEach for large lists
struct MemoryEfficientList<Data: RandomAccessCollection, ID: Hashable, Content: View>: View where Data.Element: Identifiable, Data.Element.ID == ID {
    let data: Data
    let content: (Data.Element) -> Content

    init(_ data: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) where ID == Data.Element.ID {
        self.data = data
        self.content = content
    }

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                content(item)
                    .id(item.id)
                    .lazyLoad()
            }
        }
    }
}

// MARK: - Throttled Action

/// Prevents rapid repeated actions (e.g., button taps)
struct ThrottledButton<Label: View>: View {
    let action: () -> Void
    let label: Label
    let throttleInterval: TimeInterval

    @State private var isThrottled = false

    init(throttleInterval: TimeInterval = 0.5, action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.throttleInterval = throttleInterval
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button {
            guard !isThrottled else { return }

            isThrottled = true
            action()

            Task {
                try? await Task.sleep(nanoseconds: UInt64(throttleInterval * 1_000_000_000))
                isThrottled = false
            }
        } label: {
            label
        }
        .disabled(isThrottled)
    }
}

// MARK: - Conditional Update

/// Only updates view when condition is true
/// Reduces unnecessary re-renders
struct ConditionalUpdateModifier<T: Equatable>: ViewModifier {
    let value: T
    let condition: (T, T) -> Bool

    @State private var lastValue: T

    init(value: T, updateWhen condition: @escaping (T, T) -> Bool) {
        self.value = value
        self.condition = condition
        self._lastValue = State(initialValue: value)
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: value) { oldValue, newValue in
                if condition(oldValue, newValue) {
                    lastValue = newValue
                }
            }
    }
}

extension View {
    /// Only trigger updates when the condition is met
    func conditionalUpdate<T: Equatable>(_ value: T, when condition: @escaping (T, T) -> Bool) -> some View {
        modifier(ConditionalUpdateModifier(value: value, updateWhen: condition))
    }
}

// MARK: - Rendering Metrics

/// Debug helper to track view rendering performance
struct RenderMetricsModifier: ViewModifier {
    let viewName: String

    @State private var renderCount = 0
    @State private var lastRenderTime = Date()

    func body(content: Content) -> some View {
        content
            .onAppear {
                renderCount += 1
                let now = Date()
                let timeSinceLastRender = now.timeIntervalSince(lastRenderTime)
                lastRenderTime = now

                #if DEBUG
                print("🔄 [\(viewName)] Render #\(renderCount) | Time since last: \(String(format: "%.2f", timeSinceLastRender * 1000))ms")
                #endif
            }
    }
}

extension View {
    /// Track rendering metrics for performance debugging
    func trackRendering(viewName: String) -> some View {
        #if DEBUG
        return modifier(RenderMetricsModifier(viewName: viewName))
        #else
        return self
        #endif
    }
}

// MARK: - Batch Update

/// Batches multiple state changes into a single update
@MainActor
class BatchStateManager: ObservableObject {
    @Published private(set) var needsUpdate = false
    private var pendingUpdates: [() -> Void] = []

    func batch(_ update: @escaping () -> Void) {
        pendingUpdates.append(update)

        if !needsUpdate {
            needsUpdate = true
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_000_000) // 1ms delay
                applyUpdates()
            }
        }
    }

    private func applyUpdates() {
        let updates = pendingUpdates
        pendingUpdates = []
        needsUpdate = false

        updates.forEach { $0() }
    }
}

// MARK: - View Size Preference

/// Efficiently track view size without causing re-layout
struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

extension View {
    func measureSize(_ size: Binding<CGSize>) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear.preference(
                    key: SizePreferenceKey.self,
                    value: geometry.size
                )
            }
        )
        .onPreferenceChange(SizePreferenceKey.self) { newSize in
            size.wrappedValue = newSize
        }
    }
}

// MARK: - Screen View Tracking

/// Automatically track screen views for analytics
struct ScreenViewTrackingModifier: ViewModifier {
    let screenName: String
    @State private var appearTime: Date?

    func body(content: Content) -> some View {
        content
            .onAppear {
                let startTime = Date()
                appearTime = startTime

                // Track screen appeared
                AnalyticsTracker.shared.trackScreenViewed(
                    screenName: screenName,
                    loadTime: nil
                )

                // Track performance
                PerformanceMonitor.shared.startViewLoad(screenName)
            }
            .onDisappear {
                // Finish performance tracking
                PerformanceMonitor.shared.finishViewLoad(screenName)
            }
    }
}

extension View {
    /// Track screen view for analytics and performance monitoring
    /// - Parameter screenName: Name of the screen (e.g., "program_builder", "today_session")
    /// - Returns: Modified view with screen tracking
    ///
    /// Usage:
    /// ```swift
    /// var body: some View {
    ///     VStack {
    ///         // content
    ///     }
    ///     .trackScreenView("program_builder")
    /// }
    /// ```
    func trackScreenView(_ screenName: String) -> some View {
        modifier(ScreenViewTrackingModifier(screenName: screenName))
    }
}
