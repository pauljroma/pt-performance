//
//  ViewOptimizations.swift
//  PTPerformance
//
//  Build 96: SwiftUI view rendering optimizations
//  Provides utilities to reduce unnecessary re-renders and improve scrolling performance
//

import SwiftUI

// MARK: - Equatable Conformance for Models
// Note: Patient Equatable conformance is defined in Patient.swift
// Note: Session Equatable conformance is defined in Exercise.swift (via Hashable)

/// Extension to make Exercise equatable for view diffing
extension Exercise: Equatable {
    static func == (lhs: Exercise, rhs: Exercise) -> Bool {
        lhs.id == rhs.id &&
        lhs.exercise_template_id == rhs.exercise_template_id &&
        lhs.prescribed_sets == rhs.prescribed_sets &&
        lhs.prescribed_reps == rhs.prescribed_reps
    }
}

// MARK: - Lazy Loading Utilities

/// Lazy image loader with built-in caching
/// Prevents blocking main thread when loading images
struct LazyAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var image: UIImage?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }

    private func loadImage() {
        guard let url = url, !isLoading else { return }

        isLoading = true

        // Check cache first
        if let cached = ImageCache.shared.get(url: url) {
            self.image = cached
            isLoading = false
            return
        }

        // Load asynchronously
        Task.detached(priority: .userInitiated) {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let loadedImage = UIImage(data: data) {
                    // Cache the image
                    await ImageCache.shared.set(url: url, image: loadedImage)

                    await MainActor.run {
                        self.image = loadedImage
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

/// Simple in-memory image cache
@MainActor
class ImageCache {
    static let shared = ImageCache()

    private var cache: [URL: UIImage] = [:]
    private let maxCacheSize = 50 // Maximum number of cached images
    private let maxMemoryMB = 100.0 // Maximum cache size in MB

    private init() {}

    func get(url: URL) -> UIImage? {
        cache[url]
    }

    func set(url: URL, image: UIImage) {
        // Evict if cache is too large
        if cache.count >= maxCacheSize {
            // Remove first item (FIFO)
            if let firstKey = cache.keys.first {
                cache.removeValue(forKey: firstKey)
            }
        }

        cache[url] = image
    }

    func clear() {
        cache.removeAll()
    }

    var size: Int {
        cache.count
    }
}

// MARK: - View Modifiers for Performance

/// Modifier to prevent unnecessary re-renders
struct OnlyRenderOnce: ViewModifier {
    @State private var hasRendered = false

    func body(content: Content) -> some View {
        if !hasRendered {
            content.onAppear {
                hasRendered = true
            }
        } else {
            content
        }
    }
}

extension View {
    /// Render this view only once, ignoring parent updates
    /// Useful for static content that doesn't need to re-render
    func renderOnce() -> some View {
        modifier(OnlyRenderOnce())
    }
}

/// Modifier to defer expensive computations
struct DeferredRendering<Content: View>: View {
    let delay: TimeInterval
    @ViewBuilder let content: () -> Content

    @State private var shouldRender = false

    var body: some View {
        Group {
            if shouldRender {
                content()
            } else {
                Color.clear
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            shouldRender = true
                        }
                    }
            }
        }
    }
}

extension View {
    /// Defer rendering of this view by specified delay
    /// Useful for views below the fold that can load lazily
    func deferRendering(by delay: TimeInterval = 0.1) -> some View {
        DeferredRendering(delay: delay) {
            self
        }
    }
}

// MARK: - List Performance Optimizations

/// Optimized list row that prevents excessive re-renders
struct OptimizedListRow<Content: View>: View {
    let id: String
    @ViewBuilder let content: () -> Content

    // Use @State to store row identity and prevent re-computation
    @State private var rowId: String

    init(id: String, @ViewBuilder content: @escaping () -> Content) {
        self.id = id
        self._rowId = State(initialValue: id)
        self.content = content
    }

    var body: some View {
        content()
            .id(rowId) // Stable identity prevents SwiftUI from recreating view
    }
}

// Note: ForEach optimization extension removed due to type compatibility issues
// Use standard ForEach with .id() modifier for similar behavior

// MARK: - Conditional View Updates

/// State wrapper that only updates when value actually changes
/// Prevents triggering view updates for identical values
@propertyWrapper
struct StableState<Value: Equatable>: DynamicProperty {
    @State private var value: Value

    var wrappedValue: Value {
        get { value }
        nonmutating set {
            // Only update if value actually changed
            if newValue != value {
                value = newValue
            }
        }
    }

    var projectedValue: Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }

    init(wrappedValue: Value) {
        self._value = State(wrappedValue: wrappedValue)
    }
}

// MARK: - Performance Tracking

/// View modifier to track rendering performance
struct PerformanceTracking: ViewModifier {
    let viewName: String

    func body(content: Content) -> some View {
        content
            .onAppear {
                PerformanceMonitor.shared.startViewLoad(viewName)
            }
            .task {
                // Intentional delay: wait for first render to complete before finishing measurement
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                PerformanceMonitor.shared.finishViewLoad(viewName)
            }
    }
}

extension View {
    /// Track rendering performance of this view
    func trackPerformance(name: String) -> some View {
        modifier(PerformanceTracking(viewName: name))
    }
}
