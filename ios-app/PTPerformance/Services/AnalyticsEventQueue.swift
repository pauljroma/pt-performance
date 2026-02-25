//
//  AnalyticsEventQueue.swift
//  PTPerformance
//
//  ACP-959: Persistent event queue for the analytics pipeline.
//  Stores events in memory and persists to disk (caches directory)
//  so that queued events survive app termination.
//

import Foundation
import UIKit

// MARK: - Analytics Event Model

/// A single analytics event ready for backend ingestion.
///
/// All properties are `Codable` so the queue can be serialized to JSON on disk.
/// The `properties` dictionary is `[String: String]` to guarantee codability;
/// callers must convert non-string values before enqueuing.
struct AnalyticsEvent: Codable, Identifiable, Sendable {

    /// Unique event identifier
    let id: UUID

    /// Event name (e.g. "session_completed", "screen_viewed")
    let event: String

    /// Flat key-value metadata associated with the event
    let properties: [String: String]

    /// ISO-8601 timestamp of when the event was captured
    let timestamp: Date

    /// Authenticated user ID, if available
    let userId: String?

    /// Persistent anonymous identifier (pre-auth tracking)
    let anonymousId: String

    /// Identifier for the current app-launch session
    let sessionId: String

    // MARK: - Device / App Context

    /// Marketing version (CFBundleShortVersionString)
    let appVersion: String

    /// Build number (CFBundleVersion)
    let buildNumber: String

    /// Always "iOS"
    let platform: String

    /// e.g. "18.2"
    let osVersion: String

    /// e.g. "iPhone16,1"
    let deviceModel: String
}

// MARK: - Analytics Event Queue Actor

/// Actor-isolated persistent event queue.
///
/// Events are held in an in-memory array and mirrored to a JSON file in the
/// caches directory. On initialisation the queue is restored from disk so
/// events that were enqueued but not yet flushed survive app termination.
actor AnalyticsEventQueue {

    // MARK: - Properties

    private var events: [AnalyticsEvent] = []
    private let logger = DebugLogger.shared
    private let fileURL: URL

    private static let fileName = "analytics_queue.json"

    // MARK: - Shared Encoder / Decoder

    private nonisolated static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    private nonisolated static let decoder: JSONDecoder = PTSupabaseClient.flexibleDecoder

    // MARK: - Initialisation

    init() {
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.fileURL = cachesDir.appendingPathComponent(Self.fileName)
        loadFromDisk()
    }

    // MARK: - Public API

    /// Add an event to the tail of the queue and persist to disk.
    func enqueue(_ event: AnalyticsEvent) {
        events.append(event)
        saveToDisk()
    }

    /// Remove and return up to `count` events from the head of the queue.
    func dequeue(count: Int) -> [AnalyticsEvent] {
        let n = min(count, events.count)
        let batch = Array(events.prefix(n))
        events.removeFirst(n)
        saveToDisk()
        return batch
    }

    /// Return up to `count` events from the head of the queue without removing them.
    func peek(count: Int) -> [AnalyticsEvent] {
        let n = min(count, events.count)
        return Array(events.prefix(n))
    }

    /// Remove events whose IDs are in the provided set (used after successful flush).
    func removeEvents(ids: Set<UUID>) {
        events.removeAll { ids.contains($0.id) }
        saveToDisk()
    }

    /// Current number of events in the queue.
    var count: Int {
        events.count
    }

    // MARK: - Persistence

    private func saveToDisk() {
        do {
            let data = try Self.encoder.encode(events)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            logger.warning("AnalyticsEventQueue", "Failed to persist queue to disk: \(error.localizedDescription)")
        }
    }

    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            let restored = try Self.decoder.decode([AnalyticsEvent].self, from: data)
            events = restored
            if !restored.isEmpty {
                logger.info("AnalyticsEventQueue", "Restored \(restored.count) events from disk")
            }
        } catch {
            logger.warning("AnalyticsEventQueue", "Failed to restore queue from disk: \(error.localizedDescription)")
            // Remove the corrupted file so we start fresh next time
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
}
