//
//  ImageCacheService.swift
//  PTPerformance
//
//  BUILD 95 - Agent 8: Performance optimization
//  Efficient image caching service to reduce network requests and memory usage
//

import Foundation
import UIKit
import SwiftUI

/// High-performance image caching service
/// Provides memory + disk caching with automatic cleanup
@MainActor
class ImageCacheService: ObservableObject {

    // MARK: - Singleton

    static let shared = ImageCacheService()

    // MARK: - Properties

    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let maxDiskCacheSize: Int64 = 100_000_000  // 100MB
    private let maxMemoryCacheSize: Int = 50_000_000    // 50MB

    // MARK: - Initialization

    private init() {
        // Configure memory cache
        memoryCache.totalCostLimit = maxMemoryCacheSize
        memoryCache.countLimit = 100  // Max 100 images in memory

        // Setup disk cache directory
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("ImageCache", isDirectory: true)

        // Create cache directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // Setup automatic cleanup on memory warning
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )

        // Cleanup old cache on init
        Task.detached(priority: .utility) {
            await self.cleanupOldCache()
        }
    }

    // MARK: - Public API

    /// Load image from URL with caching
    /// - Parameter url: Image URL
    /// - Returns: Cached or downloaded UIImage
    func loadImage(from url: URL) async throws -> UIImage {
        let cacheKey = url.absoluteString as NSString

        // Check memory cache first (fastest)
        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            return cachedImage
        }

        // Check disk cache second (fast)
        if let diskImage = await loadFromDisk(url: url) {
            // Store in memory cache for next access
            memoryCache.setObject(diskImage, forKey: cacheKey, cost: estimateImageSize(diskImage))
            return diskImage
        }

        // Download from network (slowest)
        let image = try await downloadImage(from: url)

        // Cache in memory and disk
        memoryCache.setObject(image, forKey: cacheKey, cost: estimateImageSize(image))
        await saveToDisk(image: image, url: url)

        return image
    }

    /// Preload images in background for better UX
    /// - Parameter urls: Array of image URLs to preload
    func preloadImages(urls: [URL]) {
        Task.detached(priority: .utility) {
            for url in urls {
                _ = try? await self.loadImage(from: url)
            }
        }
    }

    /// Clear all cached images
    func clearCache() async {
        memoryCache.removeAllObjects()

        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    /// Get current cache size
    /// - Returns: Total cache size in bytes
    func getCacheSize() async -> Int64 {
        var totalSize: Int64 = 0

        guard let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        // Collect URLs synchronously to avoid makeIterator in async context
        let fileURLs = enumerator.allObjects.compactMap { $0 as? URL }
        for fileURL in fileURLs {
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(fileSize)
            }
        }

        return totalSize
    }

    // MARK: - Private Methods

    private func downloadImage(from url: URL) async throws -> UIImage {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ImageCacheError.downloadFailed
        }

        guard let image = UIImage(data: data) else {
            throw ImageCacheError.invalidImageData
        }

        return image
    }

    private func loadFromDisk(url: URL) async -> UIImage? {
        let filename = url.absoluteString.sha256Hash
        let fileURL = cacheDirectory.appendingPathComponent(filename)

        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }

        return image
    }

    private func saveToDisk(image: UIImage, url: URL) async {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            return
        }

        let filename = url.absoluteString.sha256Hash
        let fileURL = cacheDirectory.appendingPathComponent(filename)

        try? data.write(to: fileURL)

        // Check if we need to cleanup
        let cacheSize = await getCacheSize()
        if cacheSize > maxDiskCacheSize {
            await cleanupOldCache()
        }
    }

    private func cleanupOldCache() async {
        guard let enumerator = fileManager.enumerator(
            at: cacheDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]
        ) else {
            return
        }

        var files: [(url: URL, date: Date, size: Int64)] = []

        // Collect URLs synchronously to avoid makeIterator in async context
        let fileURLs = enumerator.allObjects.compactMap { $0 as? URL }
        for fileURL in fileURLs {
            if let values = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]),
               let date = values.contentModificationDate,
               let size = values.fileSize {
                files.append((url: fileURL, date: date, size: Int64(size)))
            }
        }

        // Sort by date (oldest first)
        files.sort { $0.date < $1.date }

        // Remove oldest files until we're under the limit
        var currentSize = files.reduce(0) { $0 + $1.size }

        for file in files {
            if currentSize <= maxDiskCacheSize {
                break
            }

            try? fileManager.removeItem(at: file.url)
            currentSize -= file.size
        }
    }

    @objc private func handleMemoryWarning() {
        // Clear memory cache on memory warning
        memoryCache.removeAllObjects()
    }

    private func estimateImageSize(_ image: UIImage) -> Int {
        guard let cgImage = image.cgImage else {
            return 0
        }

        let bytesPerRow = cgImage.bytesPerRow
        let height = cgImage.height
        return bytesPerRow * height
    }
}

// MARK: - Supporting Types

enum ImageCacheError: LocalizedError {
    case downloadFailed
    case invalidImageData
    case cacheWriteFailed

    var errorDescription: String? {
        switch self {
        case .downloadFailed:
            return "Failed to download image"
        case .invalidImageData:
            return "Invalid image data"
        case .cacheWriteFailed:
            return "Failed to write to cache"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .downloadFailed:
            return "Please check your connection and try again."
        case .invalidImageData:
            return "The image couldn't be loaded. Please try again later."
        case .cacheWriteFailed:
            return "There wasn't enough storage space. Try clearing some space on your device."
        }
    }
}

// MARK: - String Extension for Hashing

private extension String {
    var sha256Hash: String {
        // Simple hash for filename generation
        // In production, use CryptoKit for proper SHA256
        return String(self.hashValue)
    }
}

// MARK: - SwiftUI View Extension

/// SwiftUI view extension for cached image loading
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL
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
                    .task {
                        await loadImage()
                    }
            }
        }
    }

    private func loadImage() async {
        guard !isLoading else { return }
        isLoading = true

        do {
            image = try await ImageCacheService.shared.loadImage(from: url)
        } catch {
            print("Failed to load image: \(error)")
        }

        isLoading = false
    }
}

/// Convenience initializer for CachedAsyncImage
extension CachedAsyncImage where Content == Image, Placeholder == Color {
    init(url: URL) {
        self.url = url
        self.content = { $0.resizable() }
        self.placeholder = { Color.gray.opacity(0.3) }
    }
}
