//
//  DiskImageCache.swift
//  PTPerformance
//
//  ACP-936: Image Loading Pipeline — Disk-based image cache with LRU eviction.
//  Stores processed images on disk keyed by URL + processing parameters.
//  Automatically evicts least-recently-used entries when the cache exceeds
//  its configurable size limit.
//

import Foundation
import UIKit
import CryptoKit

// MARK: - DiskImageCache

/// Actor-isolated disk cache for processed images with LRU eviction.
///
/// Images are stored as JPEG files in a dedicated cache directory. An in-memory
/// manifest tracks access times for LRU ordering without hitting the filesystem
/// on every lookup. The manifest is persisted to disk periodically and on
/// significant mutations so it survives app restarts.
///
/// Thread safety is guaranteed by Swift's actor isolation — all mutable state
/// is protected without explicit locks.
actor DiskImageCache {

    // MARK: - Configuration

    /// Configuration for the disk cache.
    struct Configuration {
        /// Maximum total size of cached files in bytes. Defaults to 150 MB.
        let maxSizeBytes: Int64

        /// JPEG compression quality for cached images (0.0–1.0). Defaults to 0.85.
        let compressionQuality: CGFloat

        /// Subdirectory name within the system Caches folder.
        let directoryName: String

        /// How many bytes over the limit to evict in a single pass.
        /// Evicting a buffer beyond the limit avoids thrashing when the cache
        /// hovers near capacity.
        let evictionHeadroomBytes: Int64

        static let `default` = Configuration(
            maxSizeBytes: 150_000_000,
            compressionQuality: 0.85,
            directoryName: "ImagePipelineCache",
            evictionHeadroomBytes: 20_000_000
        )
    }

    // MARK: - Manifest Entry

    /// Metadata for a single cached file, used for LRU ordering and size tracking.
    private struct ManifestEntry: Codable {
        let key: String
        let sizeBytes: Int64
        var lastAccessDate: Date

        // Custom Codable to prevent runtime traps (EXC_BREAKPOINT/brk 1)
        // on corrupted Date values in the manifest JSON file.
        init(key: String, sizeBytes: Int64, lastAccessDate: Date) {
            self.key = key
            self.sizeBytes = sizeBytes
            self.lastAccessDate = lastAccessDate
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.key = try container.decode(String.self, forKey: .key)
            self.sizeBytes = (try? container.decode(Int64.self, forKey: .sizeBytes)) ?? 0
            self.lastAccessDate = (try? container.decodeIfPresent(Double.self, forKey: .lastAccessDate))
                .map { Date(timeIntervalSinceReferenceDate: $0) } ?? Date()
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(key, forKey: .key)
            try container.encode(sizeBytes, forKey: .sizeBytes)
            try container.encode(lastAccessDate.timeIntervalSinceReferenceDate, forKey: .lastAccessDate)
        }

        enum CodingKeys: String, CodingKey {
            case key, sizeBytes, lastAccessDate
        }
    }

    // MARK: - Properties

    private let config: Configuration
    private let cacheDirectory: URL
    private let manifestURL: URL
    private let fileManager = FileManager.default

    /// In-memory LRU manifest keyed by cache key.
    private var manifest: [String: ManifestEntry] = [:]

    /// Running total of all cached file sizes.
    private var currentSizeBytes: Int64 = 0

    /// Tracks whether the manifest has unsaved changes.
    private var manifestDirty = false

    // MARK: - Singleton

    /// Shared instance with default configuration.
    static let shared = DiskImageCache(configuration: .default)

    // MARK: - Initialization

    /// Create a disk cache with the given configuration.
    ///
    /// - Parameter configuration: Cache sizing and directory options.
    init(configuration: Configuration) {
        self.config = configuration

        let baseCacheDir: URL
        if let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            baseCacheDir = cachesDir
        } else {
            baseCacheDir = FileManager.default.temporaryDirectory
        }

        self.cacheDirectory = baseCacheDir.appendingPathComponent(configuration.directoryName, isDirectory: true)
        self.manifestURL = baseCacheDir.appendingPathComponent("\(configuration.directoryName)_manifest.json")

        // Create the cache directory synchronously — this is fast and required
        // before any reads/writes.
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Bootstrap

    /// Load the manifest from disk. Call once after init (outside the initializer
    /// because actor-isolated async work cannot run in init).
    func bootstrap() {
        loadManifest()
        reconcileManifestWithDisk()
    }

    // MARK: - Public API

    /// Retrieve a cached image for the given key.
    ///
    /// Updates the LRU access time on hit.
    ///
    /// - Parameter key: The cache key (typically URL + processing params hash).
    /// - Returns: The cached UIImage, or nil on miss.
    func image(forKey key: String) -> UIImage? {
        let hashedKey = Self.hashedFilename(for: key)
        let fileURL = cacheDirectory.appendingPathComponent(hashedKey)

        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }

        // Update LRU access time
        manifest[key]?.lastAccessDate = Date()
        manifestDirty = true

        return image
    }

    /// Store a processed image in the disk cache.
    ///
    /// Encodes the image as JPEG, writes to disk, and updates the manifest.
    /// Triggers LRU eviction if the cache exceeds its size limit.
    ///
    /// - Parameters:
    ///   - image: The UIImage to cache.
    ///   - key: The cache key.
    func store(_ image: UIImage, forKey key: String) {
        guard let data = image.jpegData(compressionQuality: config.compressionQuality) else {
            return
        }

        let hashedKey = Self.hashedFilename(for: key)
        let fileURL = cacheDirectory.appendingPathComponent(hashedKey)

        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            ErrorLogger.shared.logError(error, context: "DiskImageCache.store")
            return
        }

        let sizeBytes = Int64(data.count)

        // Remove old entry size if overwriting
        if let existing = manifest[key] {
            currentSizeBytes -= existing.sizeBytes
        }

        manifest[key] = ManifestEntry(
            key: key,
            sizeBytes: sizeBytes,
            lastAccessDate: Date()
        )
        currentSizeBytes += sizeBytes
        manifestDirty = true

        // Evict if over limit
        if currentSizeBytes > config.maxSizeBytes {
            evictLRU()
        }

        // Persist manifest periodically
        persistManifestIfNeeded()
    }

    /// Remove a specific entry from the cache.
    ///
    /// - Parameter key: The cache key to remove.
    func remove(forKey key: String) {
        let hashedKey = Self.hashedFilename(for: key)
        let fileURL = cacheDirectory.appendingPathComponent(hashedKey)

        try? fileManager.removeItem(at: fileURL)

        if let entry = manifest.removeValue(forKey: key) {
            currentSizeBytes -= entry.sizeBytes
        }
        manifestDirty = true
    }

    /// Remove all cached images and reset the manifest.
    func removeAll() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        manifest.removeAll()
        currentSizeBytes = 0
        manifestDirty = true
        persistManifest()
    }

    /// Current total size of the disk cache in bytes.
    var totalSizeBytes: Int64 {
        currentSizeBytes
    }

    /// Number of entries currently in the cache.
    var entryCount: Int {
        manifest.count
    }

    // MARK: - LRU Eviction

    /// Evict least-recently-used entries until the cache is within its size limit
    /// minus the configured headroom.
    private func evictLRU() {
        let targetSize = config.maxSizeBytes - config.evictionHeadroomBytes

        // Sort entries by last access date, oldest first
        let sorted = manifest.values.sorted { $0.lastAccessDate < $1.lastAccessDate }

        for entry in sorted {
            guard currentSizeBytes > targetSize else { break }

            let hashedKey = Self.hashedFilename(for: entry.key)
            let fileURL = cacheDirectory.appendingPathComponent(hashedKey)
            try? fileManager.removeItem(at: fileURL)

            currentSizeBytes -= entry.sizeBytes
            manifest.removeValue(forKey: entry.key)
        }

        DebugLogger.shared.log(
            "[DiskImageCache] LRU eviction complete. Size: \(currentSizeBytes / 1_000_000)MB, entries: \(manifest.count)",
            level: .diagnostic
        )
    }

    // MARK: - Manifest Persistence

    /// Load the manifest from disk into memory.
    private func loadManifest() {
        guard let data = try? Data(contentsOf: manifestURL) else {
            manifest = [:]
            currentSizeBytes = 0
            return
        }

        // Validate JSON is parseable before attempting Codable decode.
        // Corrupted manifest files can cause runtime traps in synthesized Codable.
        guard (try? JSONSerialization.jsonObject(with: data)) != nil,
              let entries = try? SafeJSON.decoder().decode([ManifestEntry].self, from: data) else {
            // Corrupted manifest — delete and start fresh
            try? fileManager.removeItem(at: manifestURL)
            manifest = [:]
            currentSizeBytes = 0
            return
        }

        manifest = Dictionary(uniqueKeysWithValues: entries.map { ($0.key, $0) })
        currentSizeBytes = entries.reduce(0) { $0 + $1.sizeBytes }
    }

    /// Reconcile the in-memory manifest with actual files on disk.
    /// Removes manifest entries whose files no longer exist (e.g., system cleared Caches).
    private func reconcileManifestWithDisk() {
        var keysToRemove: [String] = []

        for (key, _) in manifest {
            let hashedKey = Self.hashedFilename(for: key)
            let fileURL = cacheDirectory.appendingPathComponent(hashedKey)
            if !fileManager.fileExists(atPath: fileURL.path) {
                keysToRemove.append(key)
            }
        }

        for key in keysToRemove {
            if let entry = manifest.removeValue(forKey: key) {
                currentSizeBytes -= entry.sizeBytes
            }
        }

        if !keysToRemove.isEmpty {
            manifestDirty = true
            persistManifest()
            DebugLogger.shared.log(
                "[DiskImageCache] Reconciled manifest, removed \(keysToRemove.count) orphaned entries",
                level: .diagnostic
            )
        }
    }

    /// Persist the manifest to disk only if there are unsaved changes.
    private func persistManifestIfNeeded() {
        guard manifestDirty else { return }

        // Batch writes: only persist every 10 mutations to reduce I/O.
        // The manifest is always persisted on eviction and removeAll.
        if manifest.count % 10 == 0 {
            persistManifest()
        }
    }

    /// Write the current manifest to disk.
    private func persistManifest() {
        let entries = Array(manifest.values)
        guard let data = try? SafeJSON.encoder().encode(entries) else { return }

        do {
            try data.write(to: manifestURL, options: .atomic)
            manifestDirty = false
        } catch {
            ErrorLogger.shared.logError(error, context: "DiskImageCache.saveManifest")
        }
    }

    // MARK: - Key Hashing

    /// Generate a filesystem-safe filename from a cache key using SHA256.
    ///
    /// - Parameter key: The original cache key string.
    /// - Returns: A hex-encoded SHA256 hash suitable for use as a filename.
    static func hashedFilename(for key: String) -> String {
        let data = Data(key.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
