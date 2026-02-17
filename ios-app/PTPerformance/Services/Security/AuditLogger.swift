//
//  AuditLogger.swift
//  PTPerformance
//
//  ACP-1051: Health Data Access Logging
//  HIPAA-compliant audit trail for all health data access and security events.
//
//  Design decisions:
//  - Append-only local file in Library/AuditLogs/ (not backed up to iCloud)
//  - Never logs actual health data values, only access metadata
//  - Batch sync to Supabase audit_logs table periodically
//  - 90-day local retention; server handles long-term archival
//  - Thread-safe via actor isolation
//

import Foundation

// MARK: - AuditLogger

/// Singleton service for HIPAA-compliant audit logging.
///
/// Records who accessed what health data, when, and from where.
/// Stores entries locally in an append-only log file and periodically
/// syncs them to the Supabase `audit_logs` table.
///
/// ## Usage
/// ```swift
/// AuditLogger.shared.logDataAccess(
///     resource: "health_kit_data",
///     action: "sync_today",
///     details: "Synced HRV, sleep, and activity data"
/// )
/// ```
///
/// ## Important
/// Never pass actual health data values (PHI) into the `details` parameter.
/// Only log metadata about what was accessed, not the values themselves.
actor AuditLogger {

    // MARK: - Singleton

    static let shared = AuditLogger()

    // MARK: - Constants

    /// Maximum number of entries to batch before syncing to Supabase
    private static let syncBatchSize = 50

    /// Interval between automatic sync attempts (5 minutes)
    private static let syncInterval: TimeInterval = 300

    /// Local retention period (90 days)
    private static let retentionDays = 90

    /// Maximum local log file size before rotation (5 MB)
    private static let maxLogFileSize: UInt64 = 5 * 1024 * 1024

    // MARK: - Properties

    private let fileManager = FileManager.default
    private let logger = DebugLogger.shared
    private let encoder = JSONEncoder()

    /// Cached ISO8601 formatter to avoid repeated allocation
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        return f
    }()

    /// Cached DateFormatter for log file rotation timestamps
    private static let rotationDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd_HHmmss"
        return f
    }()
    private var pendingEntries: [AuditEntry] = []
    private var syncTimer: Timer?
    private var isSyncing = false

    /// Cached device identifier (hashed for privacy)
    private let deviceId: String

    /// Cached app version
    private let appVersion: String

    /// Directory for audit log files
    private let auditLogDirectory: URL

    /// Current audit log file path
    private var currentLogFile: URL {
        auditLogDirectory.appendingPathComponent("audit.log")
    }

    // MARK: - Initialization

    private init() {
        // Compute device ID hash for privacy
        // Use ProcessInfo hostname + model to avoid @MainActor UIDevice access in actor init
        let hostName = ProcessInfo.processInfo.hostName
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        self.deviceId = String("\(hostName)-\(osVersion)".hashValue)

        // Cache app version
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        self.appVersion = "\(version).\(build)"

        // Set up audit log directory in Library (not Documents, not backed up)
        guard let libraryDir = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            // Fallback to temporary directory if Library is unavailable (should never happen on iOS)
            self.auditLogDirectory = fileManager.temporaryDirectory.appendingPathComponent("AuditLogs", isDirectory: true)
            encoder.outputFormatting = [.sortedKeys]
            Task {
                await startPeriodicSync()
                await cleanupOldEntries()
            }
            return
        }
        self.auditLogDirectory = libraryDir.appendingPathComponent("AuditLogs", isDirectory: true)

        // Create directory if needed
        try? fileManager.createDirectory(at: auditLogDirectory, withIntermediateDirectories: true)

        // Exclude from iCloud backup
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var mutableDir = auditLogDirectory
        try? mutableDir.setResourceValues(resourceValues)

        encoder.outputFormatting = [.sortedKeys]

        // Schedule periodic sync and cleanup
        Task {
            await startPeriodicSync()
            await cleanupOldEntries()
        }
    }

    // MARK: - Public Logging Methods

    /// Log a health data access event.
    ///
    /// - Parameters:
    ///   - resource: The type of data accessed (e.g., "health_kit_data", "patient_record")
    ///   - action: The action performed (e.g., "read", "sync", "fetch_hrv")
    ///   - details: Additional context (never include actual health values / PHI)
    func logDataAccess(resource: String, action: String, details: String? = nil) {
        let entry = createEntry(
            eventType: .dataAccess,
            resource: resource,
            action: action,
            details: details
        )
        appendEntry(entry)
    }

    /// Log a data modification event.
    ///
    /// - Parameters:
    ///   - resource: The type of data modified
    ///   - action: The modification action (e.g., "update", "create")
    ///   - details: Additional context (never include actual health values / PHI)
    func logDataModification(resource: String, action: String, details: String? = nil) {
        let entry = createEntry(
            eventType: .dataModification,
            resource: resource,
            action: action,
            details: details
        )
        appendEntry(entry)
    }

    /// Log an authentication event.
    ///
    /// - Parameters:
    ///   - action: The auth action (e.g., "login", "logout", "token_refresh")
    ///   - success: Whether the action succeeded
    ///   - details: Additional context (e.g., "magic_link", "password")
    func logAuthentication(action: String, success: Bool, details: String? = nil) {
        let entry = createEntry(
            eventType: .authentication,
            resource: "auth",
            action: action,
            details: "success=\(success)\(details.map { "; \($0)" } ?? "")"
        )
        appendEntry(entry)
    }

    /// Log a security event.
    ///
    /// - Parameters:
    ///   - event: The security event name (e.g., "failed_login", "account_locked", "anomaly_detected")
    ///   - details: Additional context about the event
    func logSecurityEvent(event: String, details: String? = nil) {
        let entry = createEntry(
            eventType: .securityEvent,
            resource: "security",
            action: event,
            details: details
        )
        appendEntry(entry)
    }

    /// Log a data export event.
    ///
    /// - Parameters:
    ///   - resource: What was exported (e.g., "workout_history", "health_report")
    ///   - format: The export format (e.g., "pdf", "csv")
    ///   - details: Additional context
    func logExport(resource: String, format: String, details: String? = nil) {
        let entry = createEntry(
            eventType: .export,
            resource: resource,
            action: "export_\(format)",
            details: details
        )
        appendEntry(entry)
    }

    /// Log a data or account deletion event.
    ///
    /// - Parameters:
    ///   - resource: What was deleted (e.g., "account", "health_data")
    ///   - details: Additional context
    func logDeletion(resource: String, details: String? = nil) {
        let entry = createEntry(
            eventType: .deletion,
            resource: resource,
            action: "delete",
            details: details
        )
        appendEntry(entry)
    }

    /// Log a settings change event.
    ///
    /// - Parameters:
    ///   - setting: The setting that changed
    ///   - details: Additional context (e.g., "enabled", "disabled")
    func logSettingsChange(setting: String, details: String? = nil) {
        let entry = createEntry(
            eventType: .settingsChange,
            resource: "settings",
            action: setting,
            details: details
        )
        appendEntry(entry)
    }

    // MARK: - Read Methods (for SecurityLogView)

    /// Retrieve recent audit entries for display.
    ///
    /// - Parameters:
    ///   - limit: Maximum number of entries to return
    ///   - eventType: Optional filter by event type
    /// - Returns: Array of recent audit entries, newest first
    func getRecentEntries(limit: Int = 100, eventType: AuditEventType? = nil) -> [AuditEntry] {
        var entries = loadEntriesFromFile()

        if let eventType = eventType {
            entries = entries.filter { $0.operation == eventType }
        }

        // Return newest first, limited
        return Array(entries.reversed().prefix(limit))
    }

    /// Get total count of audit entries on disk.
    func getEntryCount() -> Int {
        return loadEntriesFromFile().count
    }

    // MARK: - Sync Methods

    /// Force sync pending entries to Supabase.
    func syncToSupabase() async {
        guard !isSyncing else { return }
        guard !pendingEntries.isEmpty else { return }

        isSyncing = true
        defer { isSyncing = false }

        let entriesToSync = Array(pendingEntries.prefix(Self.syncBatchSize))

        do {
            let insertModels = entriesToSync.map { AuditEntryInsert(from: $0) }

            try await PTSupabaseClient.shared.client
                .from("audit_logs")
                .insert(insertModels)
                .execute()

            // Remove synced entries from pending
            let syncedIds = Set(entriesToSync.map { $0.id })
            pendingEntries.removeAll { syncedIds.contains($0.id) }

            logger.log("[AuditLogger] Synced \(entriesToSync.count) audit entries to Supabase", level: .diagnostic)
        } catch {
            // Non-critical: entries remain on disk for next sync attempt
            logger.log("[AuditLogger] Failed to sync audit entries: \(error.localizedDescription)", level: .warning)
        }
    }

    // MARK: - Private Methods

    /// Create an audit entry with current context.
    private func createEntry(eventType: AuditEventType, resource: String, action: String, details: String?) -> AuditEntry {
        let userId = PTSupabaseClient.shared.userId

        return AuditEntry(
            id: UUID(),
            timestamp: Self.iso8601Formatter.string(from: Date()),
            userId: userId,
            actionType: action,
            resourceType: resource,
            operation: eventType,
            details: details,
            deviceId: deviceId,
            appVersion: appVersion
        )
    }

    /// Append an entry to the local log file and pending sync queue.
    private func appendEntry(_ entry: AuditEntry) {
        // Add to pending sync queue
        pendingEntries.append(entry)

        // Append to file (efficient append-only I/O)
        appendToFile(entry)

        // Auto-sync if batch is full
        if pendingEntries.count >= Self.syncBatchSize {
            Task {
                await syncToSupabase()
            }
        }
    }

    /// Append a single entry to the log file using efficient file append.
    private func appendToFile(_ entry: AuditEntry) {
        do {
            let data = try encoder.encode(entry)
            guard var line = String(data: data, encoding: .utf8) else { return }
            line.append("\n")

            let fileURL = currentLogFile

            if fileManager.fileExists(atPath: fileURL.path) {
                // Check file size, rotate if needed
                if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                   let fileSize = attributes[.size] as? UInt64,
                   fileSize >= Self.maxLogFileSize {
                    rotateLogFile()
                }

                // Append to existing file
                if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                    fileHandle.seekToEndOfFile()
                    if let lineData = line.data(using: .utf8) {
                        fileHandle.write(lineData)
                    }
                    fileHandle.closeFile()
                }
            } else {
                // Create new file
                try line.write(to: fileURL, atomically: true, encoding: .utf8)
            }
        } catch {
            logger.log("[AuditLogger] Failed to write audit entry to file: \(error.localizedDescription)", level: .warning)
        }
    }

    /// Rotate the current log file by renaming it with a timestamp.
    private func rotateLogFile() {
        let timestamp = Self.rotationDateFormatter.string(from: Date())
        let archivedFile = auditLogDirectory.appendingPathComponent("audit_\(timestamp).log")

        try? fileManager.moveItem(at: currentLogFile, to: archivedFile)
        logger.log("[AuditLogger] Log file rotated to \(archivedFile.lastPathComponent)", level: .diagnostic)
    }

    /// Load all entries from the current log file.
    private func loadEntriesFromFile() -> [AuditEntry] {
        let fileURL = currentLogFile

        guard fileManager.fileExists(atPath: fileURL.path),
              let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return []
        }

        let decoder = JSONDecoder()
        let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty }

        return lines.compactMap { line -> AuditEntry? in
            guard let data = line.data(using: .utf8) else { return nil }
            return try? decoder.decode(AuditEntry.self, from: data)
        }
    }

    /// Start periodic sync timer.
    private func startPeriodicSync() {
        // Use a repeating task instead of Timer (actor-safe)
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(Self.syncInterval * 1_000_000_000))
                await syncToSupabase()
            }
        }
    }

    /// Remove entries older than the retention period.
    private func cleanupOldEntries() {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -Self.retentionDays, to: Date()) ?? Date()
        let cutoffTimestamp = Self.iso8601Formatter.string(from: cutoffDate)

        var entries = loadEntriesFromFile()
        let originalCount = entries.count
        entries.removeAll { $0.timestamp < cutoffTimestamp }

        if entries.count < originalCount {
            // Rewrite the file with only retained entries
            rewriteLogFile(with: entries)
            logger.log("[AuditLogger] Cleaned up \(originalCount - entries.count) entries older than \(Self.retentionDays) days", level: .diagnostic)
        }

        // Also clean up rotated log files
        cleanupRotatedFiles(olderThan: cutoffDate)
    }

    /// Rewrite the log file with a filtered set of entries.
    private func rewriteLogFile(with entries: [AuditEntry]) {
        let lines = entries.compactMap { entry -> String? in
            guard let data = try? encoder.encode(entry),
                  let line = String(data: data, encoding: .utf8) else { return nil }
            return line
        }

        let content = lines.joined(separator: "\n") + (lines.isEmpty ? "" : "\n")
        do {
            try content.write(to: currentLogFile, atomically: true, encoding: .utf8)
        } catch {
            // Use print here since ErrorLogger might cause recursion
            print("[AuditLogger] Failed to write audit log: \(error.localizedDescription)")
        }
    }

    /// Remove rotated log files older than the specified date.
    private func cleanupRotatedFiles(olderThan date: Date) {
        guard let files = try? fileManager.contentsOfDirectory(at: auditLogDirectory, includingPropertiesForKeys: [.creationDateKey]) else {
            return
        }

        for file in files {
            guard file.lastPathComponent != "audit.log" else { continue }

            if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
               let creationDate = attributes[.creationDate] as? Date,
               creationDate < date {
                try? fileManager.removeItem(at: file)
            }
        }
    }
}
