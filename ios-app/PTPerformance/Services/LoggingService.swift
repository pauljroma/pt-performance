import Foundation
import Network
import Supabase

/// Service for logging workout events with offline queue support
/// Emits events to Supabase and handles offline scenarios with persistence
@MainActor
class LoggingService: ObservableObject {
    // MARK: - Published Properties

    @Published var isOnline = true
    @Published var queuedEventCount = 0
    @Published var isSyncing = false

    // MARK: - Private Properties

    private let supabaseClient: SupabaseClient
    private let networkMonitor: NWPathMonitor
    private let monitorQueue = DispatchQueue(label: "com.ptperformance.networkmonitor")

    private var eventQueue: [LogEvent] = []
    private var emittedEventIds: Set<UUID> = [] // For duplicate prevention
    private let maxEmittedIdsCache = 1000 // Limit cache size

    // Persistence keys
    private let queueStorageKey = "logging_service_event_queue"
    private let emittedIdsStorageKey = "logging_service_emitted_ids"

    // Batch sync configuration
    private let batchSize = 50
    private let maxRetries = 3

    // MARK: - Singleton

    static let shared = LoggingService()

    // MARK: - Initializer

    private init() {
        // Initialize Supabase client
        // Note: In production, load these from Config or environment
        let supabaseURL = URL(string: "https://your-project.supabase.co")!
        let supabaseKey = "your-anon-key"
        self.supabaseClient = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)

        // Initialize network monitor
        self.networkMonitor = NWPathMonitor()

        // Load persisted data
        loadPersistedQueue()
        loadEmittedIds()

        // Start network monitoring
        setupNetworkMonitoring()

        print("[LoggingService] Initialized with \(queuedEventCount) queued events")
    }

    // MARK: - Public Methods

    /// Emit a log event
    /// - Parameter event: The event to emit
    /// - Returns: Success status
    @discardableResult
    func emit(_ event: LogEvent) async -> Bool {
        // Validate event
        guard event.isValid else {
            print("[LoggingService] Invalid event: \(event.description)")
            return false
        }

        // Check for duplicate
        if emittedEventIds.contains(event.id) {
            print("[LoggingService] Duplicate event detected: \(event.id)")
            return false
        }

        print("[LoggingService] Emitting event: \(event.description)")

        // If online, try to emit immediately
        if isOnline {
            let success = await sendEventToSupabase(event)
            if success {
                markEventAsEmitted(event.id)
                return true
            } else {
                // Failed to send, queue it
                queueEvent(event)
                return false
            }
        } else {
            // Offline, queue immediately
            queueEvent(event)
            return false
        }
    }

    /// Emit block completion event
    func emitBlockCompletion(
        patientId: UUID,
        sessionId: UUID,
        blockNumber: Int,
        exerciseId: UUID? = nil,
        metadata: [String: String]? = nil
    ) async {
        let event = LogEvent.blockCompleted(
            patientId: patientId,
            sessionId: sessionId,
            blockNumber: blockNumber,
            exerciseId: exerciseId,
            metadata: metadata
        )
        await emit(event)
    }

    /// Emit pain reported event
    func emitPainReport(
        patientId: UUID,
        sessionId: UUID?,
        painLevel: Int,
        location: String? = nil,
        metadata: [String: String]? = nil
    ) async {
        let event = LogEvent.painReported(
            patientId: patientId,
            sessionId: sessionId,
            painLevel: painLevel,
            location: location,
            metadata: metadata
        )
        await emit(event)
    }

    /// Emit readiness check-in event
    func emitReadinessCheckIn(
        patientId: UUID,
        readinessScore: Double,
        hrv: Double? = nil,
        sleepHours: Double? = nil,
        metadata: [String: String]? = nil
    ) async {
        let event = LogEvent.readinessCheckIn(
            patientId: patientId,
            readinessScore: readinessScore,
            hrv: hrv,
            sleepHours: sleepHours,
            metadata: metadata
        )
        await emit(event)
    }

    /// Manually trigger sync of queued events
    func syncQueuedEvents() async {
        guard !isSyncing && !eventQueue.isEmpty else { return }

        isSyncing = true
        print("[LoggingService] Starting sync of \(eventQueue.count) queued events")

        await processBatchSync()

        isSyncing = false
        print("[LoggingService] Sync completed. Remaining queued events: \(queuedEventCount)")
    }

    /// Clear all queued events (use with caution)
    func clearQueue() {
        eventQueue.removeAll()
        saveQueueToStorage()
        queuedEventCount = 0
        print("[LoggingService] Event queue cleared")
    }

    /// Get queue statistics
    func getQueueStats() -> (total: Int, oldest: Date?, newest: Date?) {
        guard !eventQueue.isEmpty else {
            return (0, nil, nil)
        }

        let sorted = eventQueue.sorted { $0.timestamp < $1.timestamp }
        return (
            eventQueue.count,
            sorted.first?.timestamp,
            sorted.last?.timestamp
        )
    }

    // MARK: - Private Methods - Network Monitoring

    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                let wasOnline = self.isOnline
                self.isOnline = path.status == .satisfied

                print("[LoggingService] Network status: \(self.isOnline ? "Online" : "Offline")")

                // If we just came online and have queued events, sync them
                if !wasOnline && self.isOnline && !self.eventQueue.isEmpty {
                    print("[LoggingService] Connection restored. Auto-syncing queued events...")
                    await self.syncQueuedEvents()
                }
            }
        }

        networkMonitor.start(queue: monitorQueue)
    }

    // MARK: - Private Methods - Event Emission

    private func sendEventToSupabase(_ event: LogEvent) async -> Bool {
        do {
            let eventDict = event.toDatabaseDict()

            // Insert into workout_events table
            try await supabaseClient
                .from("workout_events")
                .insert(eventDict)
                .execute()

            print("[LoggingService] Successfully sent event: \(event.id)")
            return true
        } catch {
            print("[LoggingService] Failed to send event: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Private Methods - Queue Management

    private func queueEvent(_ event: LogEvent) {
        eventQueue.append(event)
        queuedEventCount = eventQueue.count
        saveQueueToStorage()
        print("[LoggingService] Event queued: \(event.description). Queue size: \(queuedEventCount)")
    }

    private func removeEventFromQueue(_ event: LogEvent) {
        eventQueue.removeAll { $0.id == event.id }
        queuedEventCount = eventQueue.count
        saveQueueToStorage()
    }

    private func processBatchSync() async {
        var retryCount = 0
        var eventsToProcess = eventQueue

        while !eventsToProcess.isEmpty && retryCount < maxRetries {
            // Take batch
            let batch = Array(eventsToProcess.prefix(batchSize))
            var successfulEvents: [LogEvent] = []

            // Send each event in batch
            for event in batch {
                let success = await sendEventToSupabase(event)
                if success {
                    successfulEvents.append(event)
                    markEventAsEmitted(event.id)
                }
            }

            // Remove successful events from queue
            for event in successfulEvents {
                removeEventFromQueue(event)
            }

            // Update events to process
            eventsToProcess = eventQueue

            // If we had failures, increment retry count
            if successfulEvents.count < batch.count {
                retryCount += 1
                print("[LoggingService] Batch sync partial failure. Retry \(retryCount)/\(maxRetries)")

                // Wait before retry (exponential backoff)
                if retryCount < maxRetries {
                    try? await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(retryCount)) * 1_000_000_000))
                }
            } else {
                // All succeeded, reset retry count
                retryCount = 0
            }
        }
    }

    // MARK: - Private Methods - Duplicate Prevention

    private func markEventAsEmitted(_ eventId: UUID) {
        emittedEventIds.insert(eventId)

        // Limit cache size to prevent unbounded growth
        if emittedEventIds.count > maxEmittedIdsCache {
            // Remove oldest IDs (simple approach: remove random 20%)
            let idsToRemove = emittedEventIds.prefix(maxEmittedIdsCache / 5)
            emittedEventIds.subtract(idsToRemove)
        }

        saveEmittedIds()
    }

    // MARK: - Private Methods - Persistence

    private func saveQueueToStorage() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(eventQueue)

            UserDefaults.standard.set(data, forKey: queueStorageKey)
            print("[LoggingService] Saved \(eventQueue.count) events to storage")
        } catch {
            print("[LoggingService] Failed to save queue: \(error.localizedDescription)")
        }
    }

    private func loadPersistedQueue() {
        guard let data = UserDefaults.standard.data(forKey: queueStorageKey) else {
            print("[LoggingService] No persisted queue found")
            return
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            eventQueue = try decoder.decode([LogEvent].self, from: data)
            queuedEventCount = eventQueue.count
            print("[LoggingService] Loaded \(eventQueue.count) events from storage")
        } catch {
            print("[LoggingService] Failed to load queue: \(error.localizedDescription)")
            // Clear corrupted data
            UserDefaults.standard.removeObject(forKey: queueStorageKey)
        }
    }

    private func saveEmittedIds() {
        do {
            let encoder = JSONEncoder()
            let idsArray = Array(emittedEventIds)
            let data = try encoder.encode(idsArray)

            UserDefaults.standard.set(data, forKey: emittedIdsStorageKey)
        } catch {
            print("[LoggingService] Failed to save emitted IDs: \(error.localizedDescription)")
        }
    }

    private func loadEmittedIds() {
        guard let data = UserDefaults.standard.data(forKey: emittedIdsStorageKey) else {
            return
        }

        do {
            let decoder = JSONDecoder()
            let idsArray = try decoder.decode([UUID].self, from: data)
            emittedEventIds = Set(idsArray)
            print("[LoggingService] Loaded \(emittedEventIds.count) emitted event IDs")
        } catch {
            print("[LoggingService] Failed to load emitted IDs: \(error.localizedDescription)")
            UserDefaults.standard.removeObject(forKey: emittedIdsStorageKey)
        }
    }

    // MARK: - Cleanup

    deinit {
        networkMonitor.cancel()
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension LoggingService {
    /// Get all queued events (for debugging)
    func getQueuedEvents() -> [LogEvent] {
        return eventQueue
    }

    /// Get emitted event IDs count (for debugging)
    func getEmittedIdsCount() -> Int {
        return emittedEventIds.count
    }

    /// Simulate offline mode (for testing)
    func setOfflineMode(_ offline: Bool) {
        isOnline = !offline
    }
}
#endif

// MARK: - Performance Monitoring

extension LoggingService {
    /// Get performance metrics
    func getPerformanceMetrics() -> LoggingMetrics {
        let stats = getQueueStats()

        return LoggingMetrics(
            queuedEvents: queuedEventCount,
            emittedEventsCached: emittedEventIds.count,
            isOnline: isOnline,
            isSyncing: isSyncing,
            oldestQueuedEvent: stats.oldest,
            newestQueuedEvent: stats.newest
        )
    }
}

// MARK: - Metrics Model

struct LoggingMetrics {
    let queuedEvents: Int
    let emittedEventsCached: Int
    let isOnline: Bool
    let isSyncing: Bool
    let oldestQueuedEvent: Date?
    let newestQueuedEvent: Date?

    var description: String {
        """
        Logging Service Metrics:
        - Queued Events: \(queuedEvents)
        - Emitted IDs Cached: \(emittedEventsCached)
        - Network Status: \(isOnline ? "Online" : "Offline")
        - Syncing: \(isSyncing ? "Yes" : "No")
        - Queue Age: \(queueAgeDescription)
        """
    }

    private var queueAgeDescription: String {
        guard let oldest = oldestQueuedEvent else {
            return "Empty"
        }

        let age = Date().timeIntervalSince(oldest)
        let hours = Int(age / 3600)
        let minutes = Int((age.truncatingRemainder(dividingBy: 3600)) / 60)

        return "\(hours)h \(minutes)m"
    }
}
