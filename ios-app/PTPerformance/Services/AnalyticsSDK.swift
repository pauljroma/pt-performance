//
//  AnalyticsSDK.swift
//  PTPerformance
//
//  ACP-959: Core analytics pipeline.
//  Actor-based singleton that captures events, batches them in a persistent
//  queue, and flushes to the Supabase `analytics_events` table.
//
//  Privacy: PII (email, name, etc.) is never logged. Only userId and
//  anonymised properties are persisted.
//

import Foundation
import UIKit
import Supabase

// MARK: - AnalyticsSDK

/// Core analytics pipeline for PT Performance.
///
/// `AnalyticsSDK` is an actor singleton that:
/// - Captures events with device / session context
/// - Maintains a persistent offline queue (via ``AnalyticsEventQueue``)
/// - Auto-flushes events to the Supabase `analytics_events` table on a timer
/// - Supports debug mode (events printed to console, not sent to backend)
///
/// ## Quick Start
/// ```swift
/// // On login
/// await AnalyticsSDK.shared.initialize(userId: user.id, userProperties: ["role": "patient"])
///
/// // Track an event
/// await AnalyticsSDK.shared.track("session_completed", properties: ["duration_seconds": "2700"])
///
/// // On logout
/// await AnalyticsSDK.shared.reset()
/// ```
actor AnalyticsSDK {

    // MARK: - Singleton

    static let shared = AnalyticsSDK()

    // MARK: - Configuration

    /// Tuning knobs for the analytics pipeline.
    struct Config: Sendable {
        /// Seconds between automatic flushes.
        var flushInterval: TimeInterval = 30

        /// Maximum number of events sent in a single batch insert.
        var maxBatchSize: Int = 25

        /// Hard cap on the local queue. Oldest events are dropped when exceeded.
        var maxQueueSize: Int = 1000

        /// When `true`, events are printed via `DebugLogger` instead of being sent to Supabase.
        var isDebugMode: Bool = {
            #if DEBUG
            return true
            #else
            return false
            #endif
        }()

        /// Master kill-switch. When `false` all tracking calls are no-ops.
        var isEnabled: Bool = true
    }

    // MARK: - Properties

    private var config = Config()
    private let queue = AnalyticsEventQueue()
    private let logger = DebugLogger.shared
    private let supabase: PTSupabaseClient

    /// Current authenticated user ID (nil before login).
    private var userId: String?

    /// Additional user traits set via `identify`.
    private var userProperties: [String: String] = [:]

    /// Persistent anonymous ID stored in UserDefaults (survives app installs only if
    /// UserDefaults are preserved).
    private let anonymousId: String

    /// Per-launch session ID.
    private let sessionId: String

    /// Reference to the auto-flush task so we can cancel it on `reset`.
    private var flushTask: Task<Void, Never>?

    // MARK: - UserDefaults Keys

    private enum DefaultsKeys {
        static let anonymousId = "analytics_sdk_anonymous_id"
    }

    // MARK: - Device Info (captured once)

    private nonisolated static let currentAppVersion: String = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }()

    private nonisolated static let currentBuildNumber: String = {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
    }()

    private nonisolated static let currentOSVersion: String = {
        ProcessInfo.processInfo.operatingSystemVersionString
    }()

    private nonisolated static let currentDeviceModel: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { result, element in
            guard let value = element.value as? Int8, value != 0 else { return result }
            return result + String(UnicodeScalar(UInt8(value)))
        }
    }()

    // MARK: - Shared Encoder

    private nonisolated static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    // MARK: - Initialisation

    private init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase

        // Restore or create a persistent anonymous ID
        if let stored = UserDefaults.standard.string(forKey: DefaultsKeys.anonymousId) {
            self.anonymousId = stored
        } else {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: DefaultsKeys.anonymousId)
            self.anonymousId = newId
        }

        // Fresh session ID per app launch
        self.sessionId = UUID().uuidString

        logger.info("AnalyticsSDK", "Initialized (anonymousId=\(self.anonymousId), sessionId=\(self.sessionId))")

        // Start auto-flush loop
        startFlushLoop()
    }

    // MARK: - Public API

    /// Set the authenticated user identity and start/restart the flush timer.
    ///
    /// Call this after successful authentication.
    /// - Parameters:
    ///   - userId: The authenticated user's unique identifier.
    ///   - userProperties: Anonymised key-value traits (e.g. `["role": "patient"]`).
    func initialize(userId: String?, userProperties: [String: String] = [:]) {
        self.userId = userId
        self.userProperties = userProperties
        logger.info("AnalyticsSDK", "Identity set: userId=\(userId ?? "nil"), traits=\(userProperties.count)")
    }

    /// Update the user identity (e.g. after sign-in or profile change).
    ///
    /// - Parameters:
    ///   - userId: The authenticated user's unique identifier.
    ///   - traits: Anonymised key-value traits to merge with existing properties.
    func identify(userId: String, traits: [String: String] = [:]) {
        self.userId = userId
        self.userProperties.merge(traits) { _, new in new }
        logger.info("AnalyticsSDK", "Identified: userId=\(userId), traits=\(traits.count)")
    }

    /// Enqueue a named event with optional properties.
    ///
    /// Properties are converted to `[String: String]` (non-string values are
    /// stringified via `String(describing:)`). PII keys are stripped automatically.
    ///
    /// - Parameters:
    ///   - event: Event name (e.g. `"session_completed"`).
    ///   - properties: Arbitrary metadata dictionary.
    func track(_ event: String, properties: [String: Any] = [:]) async {
        guard config.isEnabled else { return }

        let sanitised = sanitiseProperties(properties)
        let analyticsEvent = AnalyticsEvent(
            id: UUID(),
            event: event,
            properties: sanitised,
            timestamp: Date(),
            userId: userId,
            anonymousId: anonymousId,
            sessionId: sessionId,
            appVersion: Self.currentAppVersion,
            buildNumber: Self.currentBuildNumber,
            platform: "iOS",
            osVersion: Self.currentOSVersion,
            deviceModel: Self.currentDeviceModel
        )

        if config.isDebugMode {
            logger.info("AnalyticsSDK", "[DEBUG] track: \(event) | \(sanitised)")
            return
        }

        await queue.enqueue(analyticsEvent)

        // Enforce max queue size by dropping oldest events
        let currentCount = await queue.count
        if currentCount > config.maxQueueSize {
            let overflow = currentCount - config.maxQueueSize
            _ = await queue.dequeue(count: overflow)
            logger.warning("AnalyticsSDK", "Queue overflow: dropped \(overflow) oldest events")
        }
    }

    /// Convenience method for screen view events.
    ///
    /// Internally calls `track("screen_viewed", ...)` with the screen name
    /// merged into the properties.
    ///
    /// - Parameters:
    ///   - screenName: Identifier for the screen (e.g. `"TodayHub"`).
    ///   - properties: Additional metadata.
    func screen(_ screenName: String, properties: [String: Any] = [:]) async {
        var merged = properties
        merged["screen_name"] = screenName
        await track("screen_viewed", properties: merged)
    }

    /// Flush all queued events to Supabase immediately.
    ///
    /// Events are sent in batches of `config.maxBatchSize`. Successfully sent
    /// events are removed from the persistent queue.
    func flush() async {
        guard config.isEnabled, !config.isDebugMode else { return }

        let batchSize = config.maxBatchSize
        var totalFlushed = 0

        while true {
            let batch = await queue.peek(count: batchSize)
            guard !batch.isEmpty else { break }

            do {
                try await supabase.client
                    .from("analytics_events")
                    .insert(batch)
                    .execute()

                let ids = Set(batch.map { $0.id })
                await queue.removeEvents(ids: ids)
                totalFlushed += batch.count
            } catch {
                if error.isCancellation {
                    logger.diagnostic("[AnalyticsSDK] Flush cancelled")
                } else {
                    logger.warning("AnalyticsSDK", "Flush failed: \(error.localizedDescription). \(await queue.count) events remain queued.")
                }
                // Stop flushing on failure — events stay queued for retry
                break
            }
        }

        if totalFlushed > 0 {
            logger.info("AnalyticsSDK", "Flushed \(totalFlushed) events to Supabase")
        }
    }

    /// Clear identity and queued data (call on logout).
    func reset() {
        userId = nil
        userProperties = [:]
        logger.info("AnalyticsSDK", "Identity reset")
    }

    /// Replace the current configuration.
    func configure(_ config: Config) {
        self.config = config
        // Restart the flush loop with the new interval
        flushTask?.cancel()
        startFlushLoop()
    }

    // MARK: - Auto-Flush Loop

    private func startFlushLoop() {
        flushTask?.cancel()
        flushTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: UInt64((self?.config.flushInterval ?? 30) * 1_000_000_000))
                } catch {
                    // Task was cancelled
                    break
                }
                await self?.flush()
            }
        }
    }

    // MARK: - Privacy Helpers

    /// Keys that must never be sent to the analytics backend.
    private static let piiKeys: Set<String> = [
        "email", "e-mail", "mail",
        "name", "first_name", "last_name", "full_name", "username",
        "phone", "phone_number", "telephone",
        "address", "street", "zip", "postal_code",
        "ssn", "social_security",
        "password", "secret", "token",
        "credit_card", "card_number", "cvv"
    ]

    /// Convert `[String: Any]` to `[String: String]`, stripping PII keys.
    private func sanitiseProperties(_ raw: [String: Any]) -> [String: String] {
        var result: [String: String] = [:]
        for (key, value) in raw {
            let normalisedKey = key.lowercased().trimmingCharacters(in: .whitespaces)
            if Self.piiKeys.contains(normalisedKey) {
                continue
            }
            result[key] = String(describing: value)
        }
        return result
    }
}
