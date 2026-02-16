//
//  ImagePipeline.swift
//  PTPerformance
//
//  ACP-936: Image Loading Pipeline — Multi-tier caching, request coalescing,
//  progressive loading, image processing, and prefetch support.
//
//  Architecture:
//    Memory (NSCache) --> Disk (DiskImageCache) --> Network (URLSession)
//
//  Builds on top of the existing ImageDownsampler in ScrollPerformanceKit.swift
//  for memory-efficient image decoding and downsampling.
//

import SwiftUI
import UIKit
import ImageIO

// MARK: - ImageProcessing

/// Describes a set of image transformations to apply at cache time.
/// Processed results are cached under a key that includes the processing
/// parameters, so different transformations of the same source URL are
/// cached independently.
struct ImageProcessing: Hashable, Sendable {

    /// Target display size in points. When set, the image is downsampled
    /// to this size using ImageDownsampler for memory efficiency.
    var targetSize: CGSize?

    /// Corner radius to bake into the image (in points). Zero means no rounding.
    var cornerRadius: CGFloat = 0

    /// Gaussian blur radius (in points). Zero means no blur.
    var blurRadius: CGFloat = 0

    /// Screen scale factor used for downsampling. Defaults to main screen scale.
    var scale: CGFloat = 0

    /// Generate a stable string suffix that uniquely identifies these processing params.
    ///
    /// Note: When `scale` is 0 (the default), a scale of 2 is used in the key to avoid
    /// requiring MainActor access to UIScreen. The actual screen scale is resolved at
    /// processing time, not at key-generation time.
    var cacheKeySuffix: String {
        var parts: [String] = []
        if let size = targetSize {
            parts.append("s\(Int(size.width))x\(Int(size.height))")
        }
        if cornerRadius > 0 {
            parts.append("r\(Int(cornerRadius))")
        }
        if blurRadius > 0 {
            parts.append("b\(Int(blurRadius))")
        }
        // Use the explicit scale if set, otherwise default to 2x for cache key stability.
        // The actual scale is resolved from UITraitCollection.current.displayScale at processing time.
        let keyScale = scale > 0 ? scale : 2
        parts.append("@\(Int(keyScale))x")
        return parts.joined(separator: "_")
    }

    /// A processing configuration that only downsamples to a target size.
    static func resize(to size: CGSize) -> ImageProcessing {
        ImageProcessing(targetSize: size)
    }

    /// A processing configuration with resize and rounded corners.
    static func resizeAndRound(to size: CGSize, cornerRadius: CGFloat) -> ImageProcessing {
        ImageProcessing(targetSize: size, cornerRadius: cornerRadius)
    }
}

// MARK: - ImagePipelineError

/// Errors specific to the image loading pipeline.
enum ImagePipelineError: LocalizedError {
    case invalidURL
    case downloadFailed(statusCode: Int)
    case decodingFailed
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The image URL is invalid."
        case .downloadFailed(let code):
            return "Image download failed with status \(code)."
        case .decodingFailed:
            return "The image data could not be decoded."
        case .cancelled:
            return "The image request was cancelled."
        }
    }
}

// MARK: - ImagePipeline

/// High-performance, actor-isolated image loading pipeline with multi-tier caching,
/// request coalescing, progressive loading, and built-in image processing.
///
/// **Cache tiers** (checked in order):
/// 1. **Memory** — NSCache with automatic eviction under memory pressure.
/// 2. **Disk** — ``DiskImageCache`` with LRU eviction and configurable size limit.
/// 3. **Network** — URLSession download, followed by processing and caching.
///
/// **Request coalescing**: When multiple views request the same URL + processing
/// combination concurrently, only one network request is made. All waiters
/// receive the same result.
///
/// **Image processing**: Resize, round corners, and blur are applied once at
/// cache-insertion time. Subsequent loads serve the already-processed image.
///
/// **Prefetch API**: Warm the cache for URLs that will be needed soon (e.g.,
/// the next page of content in a scrolling list).
///
/// Usage:
/// ```swift
/// let image = try await ImagePipeline.shared.image(
///     for: url,
///     processing: .resizeAndRound(to: CGSize(width: 80, height: 80), cornerRadius: 12)
/// )
/// ```
actor ImagePipeline {

    // MARK: - Singleton

    static let shared = ImagePipeline()

    // MARK: - Configuration

    /// Pipeline configuration options.
    struct Configuration {
        /// Maximum number of processed images held in the memory cache.
        let memoryCacheCountLimit: Int

        /// Maximum total cost (estimated bytes) for the memory cache.
        let memoryCacheTotalCostLimit: Int

        /// URLSession configuration for network requests.
        let sessionConfiguration: URLSessionConfiguration

        static let `default` = Configuration(
            memoryCacheCountLimit: 300,
            memoryCacheTotalCostLimit: 80_000_000, // ~80 MB
            sessionConfiguration: {
                let config = URLSessionConfiguration.default
                config.httpMaximumConnectionsPerHost = 6
                config.timeoutIntervalForRequest = 30
                config.timeoutIntervalForResource = 120
                config.urlCache = nil // We manage our own cache
                return config
            }()
        )
    }

    // MARK: - In-Flight Request Tracking

    /// Represents a coalesced in-flight request. Multiple callers awaiting the same
    /// URL + processing combination share a single download task through continuations.
    /// Marked @unchecked Sendable because access is serialized by the enclosing actor.
    private final class CoalescedRequest: @unchecked Sendable {
        let task: Task<UIImage, Error>
        private(set) var subscriberCount: Int = 1

        init(task: Task<UIImage, Error>) {
            self.task = task
        }

        func addSubscriber() {
            subscriberCount += 1
        }
    }

    // MARK: - Properties

    private let config: Configuration
    private let memoryCache: NSCache<NSString, UIImage>
    private let diskCache: DiskImageCache
    private let session: URLSession

    /// Tracks in-flight requests keyed by (URL + processing) cache key.
    /// Enables request coalescing so duplicate requests share one download.
    private var inFlightRequests: [String: CoalescedRequest] = [:]

    /// Active prefetch tasks, keyed by URL string, so they can be cancelled.
    private var prefetchTasks: [String: Task<Void, Never>] = [:]

    // MARK: - Initialization

    init(
        configuration: Configuration = .default,
        diskCache: DiskImageCache = .shared
    ) {
        self.config = configuration
        self.diskCache = diskCache
        self.session = URLSession(configuration: configuration.sessionConfiguration)

        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = configuration.memoryCacheCountLimit
        cache.totalCostLimit = configuration.memoryCacheTotalCostLimit
        self.memoryCache = cache
    }

    // MARK: - Bootstrap

    /// Initialize the disk cache manifest. Call once at app launch
    /// (e.g., from LaunchOptimizer phase 3).
    func bootstrap() async {
        await diskCache.bootstrap()
        DebugLogger.shared.log("[ImagePipeline] Bootstrapped", level: .diagnostic)
    }

    // MARK: - Primary API

    /// Load an image from the multi-tier cache or network, applying the given processing.
    ///
    /// Lookup order: memory cache -> disk cache -> network.
    /// On a network fetch, the processed image is stored in both disk and memory caches.
    ///
    /// Multiple concurrent calls for the same URL + processing are coalesced into
    /// a single network request.
    ///
    /// - Parameters:
    ///   - url: The image URL (remote or local file URL).
    ///   - processing: Image transformations to apply. Pass `ImageProcessing()` for no processing.
    /// - Returns: The processed UIImage.
    /// - Throws: ``ImagePipelineError`` on failure.
    func image(for url: URL, processing: ImageProcessing = ImageProcessing()) async throws -> UIImage {
        let cacheKey = self.cacheKey(for: url, processing: processing)

        // --- Tier 1: Memory cache (fastest) ---
        if let cached = memoryCache.object(forKey: cacheKey as NSString) {
            return cached
        }

        // --- Tier 2: Disk cache ---
        if let diskImage = await diskCache.image(forKey: cacheKey) {
            let cost = Self.estimateMemoryCost(diskImage)
            memoryCache.setObject(diskImage, forKey: cacheKey as NSString, cost: cost)
            return diskImage
        }

        // --- Tier 3: Network (with request coalescing) ---
        return try await coalescedFetch(url: url, processing: processing, cacheKey: cacheKey)
    }

    /// Load an image, returning nil instead of throwing on failure.
    /// Convenience wrapper for use in contexts where failure is non-critical.
    ///
    /// - Parameters:
    ///   - url: The image URL.
    ///   - processing: Image transformations to apply.
    /// - Returns: The processed UIImage, or nil on any error.
    func imageOrNil(for url: URL, processing: ImageProcessing = ImageProcessing()) async -> UIImage? {
        try? await image(for: url, processing: processing)
    }

    // MARK: - Progressive Loading

    /// Load an image progressively: first deliver a low-res thumbnail quickly,
    /// then deliver the full-processed image.
    ///
    /// This enables showing a blurry placeholder almost immediately while the
    /// full-resolution image loads. The caller receives updates via the returned
    /// AsyncStream.
    ///
    /// - Parameters:
    ///   - url: The image URL.
    ///   - thumbnailSize: Size for the fast low-res thumbnail.
    ///   - processing: Full-resolution processing parameters.
    /// - Returns: An AsyncStream that yields 1-2 images (thumbnail, then full-res).
    func progressiveImage(
        for url: URL,
        thumbnailSize: CGSize = CGSize(width: 40, height: 40),
        processing: ImageProcessing = ImageProcessing()
    ) -> AsyncStream<UIImage> {
        AsyncStream { continuation in
            let task = Task {
                // Step 1: Try to deliver a tiny thumbnail quickly
                let thumbProcessing = ImageProcessing(targetSize: thumbnailSize, blurRadius: 4)
                if let thumbnail = await self.imageOrNil(for: url, processing: thumbProcessing) {
                    guard !Task.isCancelled else {
                        continuation.finish()
                        return
                    }
                    continuation.yield(thumbnail)
                }

                // Step 2: Deliver the full-resolution processed image
                do {
                    let fullImage = try await self.image(for: url, processing: processing)
                    guard !Task.isCancelled else {
                        continuation.finish()
                        return
                    }
                    continuation.yield(fullImage)
                } catch {
                    // Full image failed — the thumbnail (if delivered) remains
                    DebugLogger.shared.log(
                        "[ImagePipeline] Progressive full-res load failed: \(error.localizedDescription)",
                        level: .warning
                    )
                }

                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    // MARK: - Prefetch API

    /// Prefetch images into the cache for upcoming content.
    ///
    /// Downloads and processes images at a low priority so they are ready when
    /// the user scrolls to them. Prefetch tasks are tracked and can be cancelled
    /// via ``cancelPrefetch(for:)``.
    ///
    /// - Parameters:
    ///   - urls: The image URLs to prefetch.
    ///   - processing: Processing to apply (should match what the view will request).
    func prefetch(urls: [URL], processing: ImageProcessing = ImageProcessing()) {
        for url in urls {
            let urlKey = url.absoluteString

            // Skip if already prefetching this URL
            guard prefetchTasks[urlKey] == nil else { continue }

            // Skip if already cached in memory
            let cacheKey = self.cacheKey(for: url, processing: processing)
            if memoryCache.object(forKey: cacheKey as NSString) != nil { continue }

            let task = Task(priority: .utility) { [weak self] in
                guard let self = self else { return }
                _ = await self.imageOrNil(for: url, processing: processing)
                await self.removePrefetchTask(for: urlKey)
            }

            prefetchTasks[urlKey] = task
        }
    }

    /// Cancel prefetch tasks for the given URLs.
    ///
    /// Call this when content scrolls out of the prefetch window to avoid
    /// wasting bandwidth and CPU on images that may never be displayed.
    ///
    /// - Parameter urls: The URLs to cancel prefetching for.
    func cancelPrefetch(for urls: [URL]) {
        for url in urls {
            let urlKey = url.absoluteString
            prefetchTasks[urlKey]?.cancel()
            prefetchTasks.removeValue(forKey: urlKey)
        }
    }

    // MARK: - Cache Management

    /// Remove all images from memory and disk caches.
    func clearAllCaches() async {
        memoryCache.removeAllObjects()
        await diskCache.removeAll()
        DebugLogger.shared.log("[ImagePipeline] All caches cleared", level: .diagnostic)
    }

    /// Remove only the in-memory cache (disk cache is preserved).
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }

    /// Remove a specific image from all cache tiers.
    ///
    /// - Parameters:
    ///   - url: The image URL.
    ///   - processing: The processing that was applied (must match for correct key).
    func removeFromCache(url: URL, processing: ImageProcessing = ImageProcessing()) async {
        let key = cacheKey(for: url, processing: processing)
        memoryCache.removeObject(forKey: key as NSString)
        await diskCache.remove(forKey: key)
    }

    /// Current disk cache size in bytes.
    func diskCacheSizeBytes() async -> Int64 {
        await diskCache.totalSizeBytes
    }

    // MARK: - Request Coalescing

    /// Fetch an image from the network, coalescing duplicate concurrent requests.
    ///
    /// If another caller is already fetching the same URL + processing combination,
    /// this method awaits the existing task instead of starting a new download.
    private func coalescedFetch(
        url: URL,
        processing: ImageProcessing,
        cacheKey: String
    ) async throws -> UIImage {
        // Check for an in-flight request we can piggyback on
        if let existing = inFlightRequests[cacheKey] {
            existing.addSubscriber()
            return try await existing.task.value
        }

        // Create a new fetch task
        let fetchTask = Task<UIImage, Error> { [weak self] in
            guard let self = self else { throw ImagePipelineError.cancelled }

            do {
                let rawImage = try await self.downloadAndDecode(url: url)

                guard !Task.isCancelled else {
                    throw ImagePipelineError.cancelled
                }

                let processed = await self.applyProcessing(processing, to: rawImage)

                guard !Task.isCancelled else {
                    throw ImagePipelineError.cancelled
                }

                // Store in both cache tiers
                let cost = Self.estimateMemoryCost(processed)
                self.memoryCache.setObject(processed, forKey: cacheKey as NSString, cost: cost)
                await self.diskCache.store(processed, forKey: cacheKey)

                // Clean up in-flight tracking
                await self.removeInFlightRequest(for: cacheKey)

                return processed
            } catch {
                await self.removeInFlightRequest(for: cacheKey)
                throw error
            }
        }

        let coalesced = CoalescedRequest(task: fetchTask)
        inFlightRequests[cacheKey] = coalesced

        return try await fetchTask.value
    }

    /// Remove an in-flight request from the tracking dictionary.
    private func removeInFlightRequest(for key: String) {
        inFlightRequests.removeValue(forKey: key)
    }

    /// Remove a completed prefetch task from tracking.
    private func removePrefetchTask(for key: String) {
        prefetchTasks.removeValue(forKey: key)
    }

    // MARK: - Network

    /// Download image data from a URL and decode it into a UIImage.
    private func downloadAndDecode(url: URL) async throws -> UIImage {
        // Handle local file URLs directly
        if url.isFileURL {
            guard let image = UIImage(contentsOfFile: url.path) else {
                throw ImagePipelineError.decodingFailed
            }
            return image
        }

        let (data, response) = try await session.data(from: url)

        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw ImagePipelineError.downloadFailed(statusCode: httpResponse.statusCode)
        }

        guard let image = UIImage(data: data) else {
            throw ImagePipelineError.decodingFailed
        }

        return image
    }

    // MARK: - Image Processing

    /// Apply the requested processing transformations to a raw image.
    ///
    /// Uses ``ImageDownsampler`` from ScrollPerformanceKit for memory-efficient
    /// downsampling when a target size is specified. Corner rounding and blur
    /// are applied via Core Graphics / Core Image.
    private func applyProcessing(_ processing: ImageProcessing, to image: UIImage) async -> UIImage {
        var result = image
        let effectiveScale = processing.scale > 0 ? processing.scale : await MainActor.run { UITraitCollection.current.displayScale }

        // Step 1: Resize using ImageDownsampler for memory efficiency
        if let targetSize = processing.targetSize {
            if let imageData = image.jpegData(compressionQuality: 1.0),
               let downsampled = await ImageDownsampler.shared.downsample(
                   data: imageData,
                   to: targetSize,
                   scale: effectiveScale
               ) {
                result = downsampled
            }
        }

        // Step 2: Apply corner radius
        if processing.cornerRadius > 0 {
            result = applyCornerRadius(processing.cornerRadius, to: result, scale: effectiveScale)
        }

        // Step 3: Apply blur
        if processing.blurRadius > 0 {
            result = applyBlur(radius: processing.blurRadius, to: result)
        }

        return result
    }

    /// Render rounded corners into the image bitmap so the view layer doesn't
    /// need to clip at render time (which causes off-screen rendering passes).
    private func applyCornerRadius(_ radius: CGFloat, to image: UIImage, scale: CGFloat) -> UIImage {
        let size = image.size
        let renderer = UIGraphicsImageRenderer(size: size, format: {
            let format = UIGraphicsImageRendererFormat()
            format.scale = scale
            return format
        }())

        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
            path.addClip()
            image.draw(in: rect)
        }
    }

    /// Apply a Gaussian blur using Core Image.
    private func applyBlur(radius: CGFloat, to image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }

        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(radius, forKey: kCIInputRadiusKey)

        guard let output = filter?.outputImage else { return image }

        // CIGaussianBlur extends the image bounds; crop back to original
        let croppedOutput = output.cropped(to: ciImage.extent)

        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let cgImage = context.createCGImage(croppedOutput, from: croppedOutput.extent) else {
            return image
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    // MARK: - Cache Key Generation

    /// Build a unique cache key from a URL and processing parameters.
    private func cacheKey(for url: URL, processing: ImageProcessing) -> String {
        let suffix = processing.cacheKeySuffix
        return "\(url.absoluteString)|\(suffix)"
    }

    // MARK: - Memory Cost Estimation

    /// Estimate the in-memory byte cost of a decoded UIImage for NSCache cost tracking.
    private static func estimateMemoryCost(_ image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }
}

// MARK: - PipelinedImage SwiftUI View

/// A SwiftUI view that loads images through ``ImagePipeline`` with multi-tier caching,
/// progressive loading (low-res placeholder -> full-res), and automatic lifecycle management.
///
/// Features:
/// - Progressive loading: instantly shows a blurry thumbnail, then cross-fades to full-res
/// - Automatic task cancellation when the view disappears (saves bandwidth during fast scrolling)
/// - Integrates with the full pipeline: memory cache -> disk cache -> network
/// - Supports resize, corner rounding, and blur via ``ImageProcessing``
///
/// Usage:
/// ```swift
/// PipelinedImage(
///     url: workout.thumbnailURL,
///     targetSize: CGSize(width: 80, height: 80),
///     placeholder: { Color.gray.opacity(0.2) }
/// )
/// ```
struct PipelinedImage<Placeholder: View>: View {
    let url: URL?
    let processing: ImageProcessing
    let contentMode: ContentMode
    let placeholder: () -> Placeholder

    @State private var displayedImage: UIImage?
    @State private var isFullResolution = false
    @State private var loadTask: Task<Void, Never>?

    /// Create a pipelined image view.
    ///
    /// - Parameters:
    ///   - url: The image URL to load. Pass nil to show the placeholder permanently.
    ///   - targetSize: Display size in points. The image is downsampled to this size.
    ///   - cornerRadius: Corner radius baked into the image (avoids off-screen rendering).
    ///   - contentMode: How to fit the image in its frame. Defaults to `.fill`.
    ///   - placeholder: A view to show while the image loads.
    init(
        url: URL?,
        targetSize: CGSize,
        cornerRadius: CGFloat = 0,
        contentMode: ContentMode = .fill,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.processing = ImageProcessing(targetSize: targetSize, cornerRadius: cornerRadius)
        self.contentMode = contentMode
        self.placeholder = placeholder
    }

    /// Create a pipelined image view with full processing control.
    ///
    /// - Parameters:
    ///   - url: The image URL to load.
    ///   - processing: Full ``ImageProcessing`` configuration.
    ///   - contentMode: How to fit the image in its frame.
    ///   - placeholder: A view to show while the image loads.
    init(
        url: URL?,
        processing: ImageProcessing,
        contentMode: ContentMode = .fill,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.processing = processing
        self.contentMode = contentMode
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = displayedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            } else {
                placeholder()
            }
        }
        .frame(
            width: processing.targetSize?.width,
            height: processing.targetSize?.height
        )
        .clipped()
        .onAppear {
            startLoading()
        }
        .onDisappear {
            cancelLoading()
        }
    }

    // MARK: - Loading

    private func startLoading() {
        guard let url = url else { return }

        // Don't restart if we already have the full-resolution image
        guard !isFullResolution else { return }

        loadTask = Task {
            // Use progressive loading: thumbnail first, then full-res
            for await image in await ImagePipeline.shared.progressiveImage(
                for: url,
                thumbnailSize: CGSize(width: 40, height: 40),
                processing: processing
            ) {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        displayedImage = image
                    }
                }

                // The second image from the stream is full-res
                if displayedImage != nil {
                    await MainActor.run {
                        isFullResolution = true
                    }
                }
            }
        }
    }

    private func cancelLoading() {
        loadTask?.cancel()
        loadTask = nil
    }
}

// MARK: - PipelinedImage Convenience: Default Placeholder

extension PipelinedImage where Placeholder == Color {
    /// Create a pipelined image with a default gray placeholder.
    ///
    /// - Parameters:
    ///   - url: The image URL to load.
    ///   - targetSize: Display size in points.
    ///   - cornerRadius: Corner radius baked into the image.
    ///   - contentMode: How to fit the image in its frame.
    init(
        url: URL?,
        targetSize: CGSize,
        cornerRadius: CGFloat = 0,
        contentMode: ContentMode = .fill
    ) {
        self.url = url
        self.processing = ImageProcessing(targetSize: targetSize, cornerRadius: cornerRadius)
        self.contentMode = contentMode
        self.placeholder = { Color.gray.opacity(0.2) }
    }
}

// MARK: - PipelinedImage Convenience: ProgressView Placeholder

extension PipelinedImage where Placeholder == ProgressView<EmptyView, EmptyView> {
    /// Create a pipelined image with a spinning progress indicator placeholder.
    ///
    /// - Parameters:
    ///   - url: The image URL to load.
    ///   - targetSize: Display size in points.
    ///   - cornerRadius: Corner radius baked into the image.
    ///   - contentMode: How to fit the image in its frame.
    init(
        url: URL?,
        targetSize: CGSize,
        cornerRadius: CGFloat = 0,
        contentMode: ContentMode = .fill
    ) {
        self.url = url
        self.processing = ImageProcessing(targetSize: targetSize, cornerRadius: cornerRadius)
        self.contentMode = contentMode
        self.placeholder = { ProgressView() }
    }
}
