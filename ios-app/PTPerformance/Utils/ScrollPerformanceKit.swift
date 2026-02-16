//
//  ScrollPerformanceKit.swift
//  PTPerformance
//
//  ACP-942: 60fps Scroll Performance — Comprehensive scroll performance toolkit.
//  Provides prefetching lists, async image cells with downsampling, and scroll
//  optimization modifiers to achieve buttery smooth scrolling across all lists.
//

import SwiftUI
import UIKit
import ImageIO

// MARK: - PrefetchingList

/// A LazyVStack wrapper that prefetches data N items ahead of the visible area.
/// Enables preloading images/data before cells scroll into view, preventing
/// loading hitches during fast scrolling.
///
/// Usage:
/// ```swift
/// PrefetchingList(
///     data: workouts,
///     id: \.id,
///     prefetchDistance: 5,
///     prefetchAction: { workout in
///         ImageCacheService.shared.preloadImages(urls: [workout.thumbnailURL])
///     },
///     cancelPrefetchAction: { workout in
///         // Cancel any pending prefetch for this workout
///     }
/// ) { workout in
///     WorkoutRow(workout: workout)
/// }
/// ```
struct PrefetchingList<Data: RandomAccessCollection, ID: Hashable, Content: View>: View {
    let data: Data
    let idKeyPath: KeyPath<Data.Element, ID>
    let prefetchDistance: Int
    let prefetchAction: ((Data.Element) -> Void)?
    let cancelPrefetchAction: ((Data.Element) -> Void)?
    let spacing: CGFloat?
    let content: (Data.Element) -> Content

    @State private var visibleIndices: Set<Int> = []

    init(
        data: Data,
        id: KeyPath<Data.Element, ID>,
        prefetchDistance: Int = 5,
        spacing: CGFloat? = nil,
        prefetchAction: ((Data.Element) -> Void)? = nil,
        cancelPrefetchAction: ((Data.Element) -> Void)? = nil,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.idKeyPath = id
        self.prefetchDistance = prefetchDistance
        self.spacing = spacing
        self.prefetchAction = prefetchAction
        self.cancelPrefetchAction = cancelPrefetchAction
        self.content = content
    }

    var body: some View {
        LazyVStack(spacing: spacing ?? 0) {
            let dataArray = Array(data)
            ForEach(dataArray.indices, id: \.self) { index in
                content(dataArray[index])
                    .onAppear {
                        handleItemAppeared(at: index, in: dataArray)
                    }
                    .onDisappear {
                        handleItemDisappeared(at: index, in: dataArray)
                    }
            }
        }
    }

    private func handleItemAppeared(at index: Int, in dataArray: [Data.Element]) {
        visibleIndices.insert(index)

        // Prefetch items ahead of visible area
        guard let prefetchAction = prefetchAction else { return }

        let prefetchStart = index + 1
        let prefetchEnd = min(index + prefetchDistance + 1, dataArray.count)

        guard prefetchStart < prefetchEnd else { return }

        for prefetchIndex in prefetchStart..<prefetchEnd {
            if !visibleIndices.contains(prefetchIndex) {
                prefetchAction(dataArray[prefetchIndex])
            }
        }

        // Also prefetch behind (for upward scrolling)
        let behindStart = max(index - prefetchDistance, 0)
        let behindEnd = index

        guard behindStart < behindEnd else { return }

        for prefetchIndex in behindStart..<behindEnd {
            if !visibleIndices.contains(prefetchIndex) {
                prefetchAction(dataArray[prefetchIndex])
            }
        }
    }

    private func handleItemDisappeared(at index: Int, in dataArray: [Data.Element]) {
        visibleIndices.remove(index)

        // Cancel prefetch for items that scrolled far out of view
        guard let cancelPrefetchAction = cancelPrefetchAction else { return }

        let cancelThreshold = prefetchDistance * 2
        let isWellOutOfView = visibleIndices.allSatisfy { visibleIndex in
            abs(visibleIndex - index) > cancelThreshold
        }

        if isWellOutOfView || visibleIndices.isEmpty {
            cancelPrefetchAction(dataArray[index])
        }
    }
}

/// Convenience initializer when Data.Element is Identifiable
extension PrefetchingList where Data.Element: Identifiable, ID == Data.Element.ID {
    init(
        data: Data,
        prefetchDistance: Int = 5,
        spacing: CGFloat? = nil,
        prefetchAction: ((Data.Element) -> Void)? = nil,
        cancelPrefetchAction: ((Data.Element) -> Void)? = nil,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.idKeyPath = \Data.Element.id
        self.prefetchDistance = prefetchDistance
        self.spacing = spacing
        self.prefetchAction = prefetchAction
        self.cancelPrefetchAction = cancelPrefetchAction
        self.content = content
    }
}

// MARK: - ImageDownsampler

/// Actor-isolated singleton for memory-efficient background image downsampling.
/// Uses ImageIO framework (CGImageSource) to downsample images without loading
/// the full-resolution image into memory, which is critical for scroll performance.
actor ImageDownsampler {

    // MARK: - Singleton

    static let shared = ImageDownsampler()

    private init() {}

    // MARK: - Downsampling

    /// Downsample an image from a URL to the target display size.
    /// Uses CGImageSource for memory-efficient decoding — the full image is never
    /// loaded into memory; only the downsampled version is created.
    ///
    /// - Parameters:
    ///   - url: The file or remote URL of the image.
    ///   - pointSize: The target display size in points.
    ///   - scale: The screen scale factor (e.g., UITraitCollection.current.displayScale).
    /// - Returns: A downsampled UIImage, or nil if downsampling fails.
    func downsample(url: URL, to pointSize: CGSize, scale: CGFloat) async -> UIImage? {
        return await Task.detached(priority: .utility) {
            let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale

            let sourceOptions: [CFString: Any] = [
                kCGImageSourceShouldCache: false
            ]

            guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, sourceOptions as CFDictionary) else {
                return nil
            }

            let downsampleOptions: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
            ]

            guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(
                imageSource,
                0,
                downsampleOptions as CFDictionary
            ) else {
                return nil
            }

            return UIImage(cgImage: downsampledImage)
        }.value
    }

    /// Downsample an image from raw data to the target display size.
    /// Preferred when image data is already available in memory (e.g., from a network response).
    ///
    /// - Parameters:
    ///   - data: The raw image data.
    ///   - pointSize: The target display size in points.
    ///   - scale: The screen scale factor.
    /// - Returns: A downsampled UIImage, or nil if downsampling fails.
    func downsample(data: Data, to pointSize: CGSize, scale: CGFloat) async -> UIImage? {
        return await Task.detached(priority: .utility) {
            let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale

            let sourceOptions: [CFString: Any] = [
                kCGImageSourceShouldCache: false
            ]

            guard let imageSource = CGImageSourceCreateWithData(data as CFData, sourceOptions as CFDictionary) else {
                return nil
            }

            let downsampleOptions: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
            ]

            guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(
                imageSource,
                0,
                downsampleOptions as CFDictionary
            ) else {
                return nil
            }

            return UIImage(cgImage: downsampledImage)
        }.value
    }
}

// MARK: - AsyncImageCell

/// An optimized image cell designed for high-performance list scrolling.
/// Loads and decodes images on a background thread, downsamples to the exact
/// display size to minimize memory, and caches decoded results.
///
/// Key optimizations:
/// - Background thread decoding via Task.detached
/// - Downsampling to target size reduces memory by 10-100x vs full-resolution
/// - NSCache keyed by URL+size for automatic memory management
/// - Task cancellation on disappear prevents wasted work during fast scrolling
/// - Cross-fade transition for polished UX
///
/// Usage:
/// ```swift
/// AsyncImageCell(
///     url: workout.imageURL,
///     targetSize: CGSize(width: 80, height: 80),
///     placeholder: { Color.gray.opacity(0.2) }
/// )
/// ```
struct AsyncImageCell<Placeholder: View>: View {
    let url: URL?
    let targetSize: CGSize
    let cornerRadius: CGFloat
    let placeholder: () -> Placeholder

    @State private var loadedImage: UIImage?
    @State private var loadTask: Task<Void, Never>?
    @State private var hasAppeared = false

    private static var imageCache: NSCache<NSString, UIImage> {
        AsyncImageCellCache.shared.cache
    }

    init(
        url: URL?,
        targetSize: CGSize = CGSize(width: 60, height: 60),
        cornerRadius: CGFloat = 8,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.targetSize = targetSize
        self.cornerRadius = cornerRadius
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: targetSize.width, height: targetSize.height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            } else {
                placeholder()
                    .frame(width: targetSize.width, height: targetSize.height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
        }
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            startLoading()
        }
        .onDisappear {
            cancelLoading()
        }
    }

    private func startLoading() {
        guard let url = url else { return }

        let cacheKey = cacheKeyFor(url: url, size: targetSize)

        // Check cache first
        if let cached = Self.imageCache.object(forKey: cacheKey as NSString) {
            loadedImage = cached
            return
        }

        // Load on background thread
        loadTask = Task {
            guard !Task.isCancelled else { return }

            // Try loading via ImageDownsampler for local URLs or download first for remote
            let image: UIImage?

            if url.isFileURL {
                image = await ImageDownsampler.shared.downsample(
                    url: url,
                    to: targetSize,
                    scale: await MainActor.run { UITraitCollection.current.displayScale }
                )
            } else {
                // Download data first, then downsample
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    guard !Task.isCancelled else { return }

                    image = await ImageDownsampler.shared.downsample(
                        data: data,
                        to: targetSize,
                        scale: await MainActor.run { UITraitCollection.current.displayScale }
                    )
                } catch {
                    return
                }
            }

            guard !Task.isCancelled, let finalImage = image else { return }

            // Cache the downsampled image
            Self.imageCache.setObject(finalImage, forKey: cacheKey as NSString)

            // Update UI on main thread
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    loadedImage = finalImage
                }
            }
        }
    }

    private func cancelLoading() {
        loadTask?.cancel()
        loadTask = nil
    }

    private func cacheKeyFor(url: URL, size: CGSize) -> String {
        "\(url.absoluteString)_\(Int(size.width))x\(Int(size.height))"
    }
}

/// Convenience initializer with default Color placeholder
extension AsyncImageCell where Placeholder == Color {
    init(
        url: URL?,
        targetSize: CGSize = CGSize(width: 60, height: 60),
        cornerRadius: CGFloat = 8
    ) {
        self.url = url
        self.targetSize = targetSize
        self.cornerRadius = cornerRadius
        self.placeholder = { Color.gray.opacity(0.2) }
    }
}

// MARK: - AsyncImageCellCache

/// Shared NSCache for AsyncImageCell, configured for scroll performance.
/// NSCache automatically evicts entries under memory pressure.
private final class AsyncImageCellCache: @unchecked Sendable {
    static let shared = AsyncImageCellCache()

    let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 200            // Max 200 downsampled images
        cache.totalCostLimit = 50_000_000 // ~50MB for downsampled thumbnails
        return cache
    }()

    private init() {}
}

// MARK: - ScrollPerformanceModifier

/// View modifier that optimizes a cell for smooth scrolling.
/// Applies `.drawingGroup()` to flatten complex view hierarchies into a single
/// rendered bitmap, and disables animations during rapid scrolling to prevent
/// animation-related frame drops.
///
/// Usage:
/// ```swift
/// WorkoutCell(workout: workout)
///     .optimizeForScroll()
/// ```
struct ScrollPerformanceModifier: ViewModifier {

    @State private var isRapidScrolling = false
    @State private var scrollDebounceTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .drawingGroup()
            .transaction { transaction in
                if isRapidScrolling {
                    transaction.animation = nil
                }
            }
            .onAppear {
                markScrollActivity()
            }
            .onDisappear {
                markScrollActivity()
            }
    }

    private func markScrollActivity() {
        // If cells are appearing/disappearing rapidly, disable animations
        isRapidScrolling = true

        scrollDebounceTask?.cancel()
        scrollDebounceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000) // 150ms of inactivity
            if !Task.isCancelled {
                isRapidScrolling = false
            }
        }
    }
}

extension View {
    /// Optimize this view for smooth scrolling in lists.
    /// Applies drawing group flattening and disables animations during rapid scrolling.
    func optimizeForScroll() -> some View {
        modifier(ScrollPerformanceModifier())
    }
}

// MARK: - Prefetch Item Modifier

/// View modifier that triggers a prefetch action when the item appears,
/// and a cancel action when it disappears. Designed for individual items
/// within a standard ForEach or List.
///
/// Usage:
/// ```swift
/// ForEach(items) { item in
///     ItemRow(item: item)
///         .prefetch(distance: 0) {
///             preloadData(for: item)
///         } cancel: {
///             cancelPreload(for: item)
///         }
/// }
/// ```
struct PrefetchItemModifier: ViewModifier {
    let onPrefetch: () -> Void
    let onCancel: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .onAppear {
                onPrefetch()
            }
            .onDisappear {
                onCancel?()
            }
    }
}

extension View {
    /// Attach prefetch and cancel-prefetch actions to a view.
    /// Triggers prefetch on appear and cancel on disappear.
    ///
    /// - Parameters:
    ///   - distance: Reserved for future use (currently triggers on appear).
    ///   - action: Action to execute when the view appears (prefetch).
    ///   - cancel: Action to execute when the view disappears (cancel prefetch).
    func prefetch(
        distance: Int = 0,
        action: @escaping () -> Void,
        cancel: (() -> Void)? = nil
    ) -> some View {
        modifier(PrefetchItemModifier(onPrefetch: action, onCancel: cancel))
    }
}
