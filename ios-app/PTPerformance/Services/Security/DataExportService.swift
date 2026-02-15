//
//  DataExportService.swift
//  PTPerformance
//
//  ACP-1047: Data Export (GDPR/CCPA)
//  Complete data export service for portable user data in JSON/CSV format.
//  Fetches all user data from Supabase and packages into a downloadable file.
//

import Foundation

// MARK: - Data Export Service

/// Service responsible for exporting all user data in GDPR/CCPA-compliant formats.
///
/// Gathers data from all Supabase tables associated with the user and produces
/// a structured JSON or CSV file suitable for data portability requests.
///
/// ## Supported Data Categories
/// - Profile information (patients table)
/// - Workout sessions (scheduled_sessions, manual_sessions)
/// - Exercise logs (exercise_logs)
/// - Nutrition logs (nutrition_logs)
/// - Daily check-ins (check_ins)
/// - AI chat history (ai_chat_sessions, ai_chat_messages)
/// - Achievements (patient_achievements)
///
/// ## Usage
/// ```swift
/// let url = try await DataExportService.shared.exportAllData(format: .json) { progress in
///     self.exportProgress = progress
/// }
/// ```
@MainActor
final class DataExportService {

    // MARK: - Singleton

    static let shared = DataExportService()

    // MARK: - Types

    /// Supported export formats
    enum ExportFormat: String, CaseIterable, Identifiable {
        case json = "JSON"
        case csv = "CSV"

        var id: String { rawValue }

        var fileExtension: String {
            switch self {
            case .json: return "json"
            case .csv: return "csv"
            }
        }

        var mimeType: String {
            switch self {
            case .json: return "application/json"
            case .csv: return "text/csv"
            }
        }
    }

    /// Data categories available for export
    enum DataCategory: String, CaseIterable, Identifiable {
        case profile = "Profile"
        case workoutSessions = "Workout Sessions"
        case exerciseLogs = "Exercise Logs"
        case nutritionLogs = "Nutrition Logs"
        case checkIns = "Daily Check-Ins"
        case aiConversations = "AI Conversations"
        case achievements = "Achievements"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .profile: return "person.fill"
            case .workoutSessions: return "figure.strengthtraining.traditional"
            case .exerciseLogs: return "list.bullet.clipboard"
            case .nutritionLogs: return "fork.knife"
            case .checkIns: return "checkmark.circle.fill"
            case .aiConversations: return "bubble.left.and.bubble.right.fill"
            case .achievements: return "trophy.fill"
            }
        }

        var tableName: String {
            switch self {
            case .profile: return "patients"
            case .workoutSessions: return "scheduled_sessions"
            case .exerciseLogs: return "exercise_logs"
            case .nutritionLogs: return "nutrition_logs"
            case .checkIns: return "check_ins"
            case .aiConversations: return "ai_chat_sessions"
            case .achievements: return "patient_achievements"
            }
        }
    }

    /// Errors specific to data export
    enum DataExportError: LocalizedError {
        case notAuthenticated
        case noUserId
        case fetchFailed(category: String, underlying: Error)
        case encodingFailed
        case fileWriteFailed
        case noDataToExport
        case exportCancelled

        var errorDescription: String? {
            switch self {
            case .notAuthenticated:
                return "You must be signed in to export your data."
            case .noUserId:
                return "Unable to determine your user ID."
            case .fetchFailed(let category, let error):
                return "Failed to fetch \(category): \(error.localizedDescription)"
            case .encodingFailed:
                return "Failed to encode export data."
            case .fileWriteFailed:
                return "Failed to write export file."
            case .noDataToExport:
                return "No data found to export."
            case .exportCancelled:
                return "Export was cancelled."
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .notAuthenticated:
                return "Please sign in and try again."
            case .noUserId:
                return "Please sign out and sign back in."
            case .fetchFailed:
                return "Check your internet connection and try again."
            case .encodingFailed, .fileWriteFailed:
                return "Please try again. If the problem persists, contact support."
            case .noDataToExport:
                return "Use the app to create some data first."
            case .exportCancelled:
                return "Start a new export when you are ready."
            }
        }
    }

    // MARK: - Export Metadata

    /// Metadata included at the top of every export file
    struct ExportMetadata: Codable {
        let exportDate: String
        let exportFormat: String
        let userId: String
        let dataVersion: String
        let appVersion: String
        let platform: String
        let categoriesIncluded: [String]
        let totalRecords: Int

        enum CodingKeys: String, CodingKey {
            case exportDate = "export_date"
            case exportFormat = "export_format"
            case userId = "user_id"
            case dataVersion = "data_version"
            case appVersion = "app_version"
            case platform
            case categoriesIncluded = "categories_included"
            case totalRecords = "total_records"
        }
    }

    // MARK: - Lightweight Export Models
    // These use [String: ExportAnyCodable] for flexible Supabase data

    /// Complete export payload
    struct ExportPayload: Codable {
        let metadata: ExportMetadata
        let profile: [[String: ExportAnyCodable]]?
        let workoutSessions: [[String: ExportAnyCodable]]?
        let exerciseLogs: [[String: ExportAnyCodable]]?
        let nutritionLogs: [[String: ExportAnyCodable]]?
        let checkIns: [[String: ExportAnyCodable]]?
        let aiConversations: ExportAIData?
        let achievements: [[String: ExportAnyCodable]]?

        enum CodingKeys: String, CodingKey {
            case metadata
            case profile
            case workoutSessions = "workout_sessions"
            case exerciseLogs = "exercise_logs"
            case nutritionLogs = "nutrition_logs"
            case checkIns = "check_ins"
            case aiConversations = "ai_conversations"
            case achievements
        }
    }

    /// AI conversation data with sessions and their messages
    struct ExportAIData: Codable {
        let sessions: [[String: ExportAnyCodable]]
        let messages: [[String: ExportAnyCodable]]
    }

    // MARK: - Properties

    private let supabase = PTSupabaseClient.shared
    private let logger = DebugLogger.shared

    /// Cached ISO8601 formatter for export metadata timestamps
    private static let iso8601Formatter = ISO8601DateFormatter()

    /// Cached DateFormatter for filename date strings
    private static let filenameDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd_HHmmss"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    /// Key for storing last export date
    private let lastExportDateKey = "dataExport_lastExportDate"

    /// Date of last successful export
    var lastExportDate: Date? {
        get {
            UserDefaults.standard.object(forKey: lastExportDateKey) as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: lastExportDateKey)
        }
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Export Methods

    /// Exports all user data in the specified format.
    ///
    /// - Parameters:
    ///   - format: The desired export format (.json or .csv)
    ///   - categories: Which data categories to include (defaults to all)
    ///   - progressHandler: Callback with progress value between 0.0 and 1.0
    /// - Returns: URL to the exported file
    /// - Throws: `DataExportError` if export fails
    func exportAllData(
        format: ExportFormat = .json,
        categories: Set<DataCategory> = Set(DataCategory.allCases),
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> URL {
        logger.info("DataExportService", "Starting data export (format: \(format.rawValue))")

        // Validate authentication
        guard supabase.currentSession != nil else {
            throw DataExportError.notAuthenticated
        }

        guard let userId = supabase.userId else {
            throw DataExportError.noUserId
        }

        progressHandler?(0.05)

        // Fetch all requested data categories
        let totalSteps = Double(categories.count) + 1 // +1 for file creation
        var completedSteps = 0.0

        var profileData: [[String: ExportAnyCodable]]?
        var workoutData: [[String: ExportAnyCodable]]?
        var manualSessionData: [[String: ExportAnyCodable]]?
        var exerciseData: [[String: ExportAnyCodable]]?
        var nutritionData: [[String: ExportAnyCodable]]?
        var checkInData: [[String: ExportAnyCodable]]?
        var aiData: ExportAIData?
        var achievementData: [[String: ExportAnyCodable]]?

        // Fetch each category
        for category in DataCategory.allCases {
            guard categories.contains(category) else { continue }

            do {
                switch category {
                case .profile:
                    profileData = try await fetchTableData(
                        table: "patients",
                        filterColumn: "id",
                        filterValue: userId
                    )
                    // Also try by user_id for auth-linked records
                    if profileData?.isEmpty ?? true,
                       let authUserId = supabase.currentUser?.id.uuidString {
                        profileData = try await fetchTableData(
                            table: "patients",
                            filterColumn: "user_id",
                            filterValue: authUserId
                        )
                    }

                case .workoutSessions:
                    workoutData = try await fetchTableData(
                        table: "scheduled_sessions",
                        filterColumn: "patient_id",
                        filterValue: userId
                    )
                    manualSessionData = try await fetchTableData(
                        table: "manual_sessions",
                        filterColumn: "patient_id",
                        filterValue: userId
                    )

                case .exerciseLogs:
                    exerciseData = try await fetchTableData(
                        table: "exercise_logs",
                        filterColumn: "patient_id",
                        filterValue: userId
                    )

                case .nutritionLogs:
                    nutritionData = try await fetchTableData(
                        table: "nutrition_logs",
                        filterColumn: "patient_id",
                        filterValue: userId
                    )

                case .checkIns:
                    checkInData = try await fetchTableData(
                        table: "check_ins",
                        filterColumn: "athlete_id",
                        filterValue: userId
                    )

                case .aiConversations:
                    aiData = try await fetchAIConversationData(userId: userId)

                case .achievements:
                    achievementData = try await fetchTableData(
                        table: "patient_achievements",
                        filterColumn: "patient_id",
                        filterValue: userId
                    )
                }

                logger.info("DataExportService", "Fetched \(category.rawValue) data")
            } catch {
                logger.warning("DataExportService", "Failed to fetch \(category.rawValue): \(error.localizedDescription)")
                // Continue with other categories rather than failing entire export
            }

            completedSteps += 1
            progressHandler?(min(completedSteps / totalSteps, 0.9))
        }

        // Merge manual sessions into workout data
        if let manual = manualSessionData, !manual.isEmpty {
            if workoutData != nil {
                workoutData?.append(contentsOf: manual)
            } else {
                workoutData = manual
            }
        }

        // Calculate total records
        let profileCount: Int = profileData?.count ?? 0
        let workoutCount: Int = workoutData?.count ?? 0
        let exerciseCount: Int = exerciseData?.count ?? 0
        let nutritionCount: Int = nutritionData?.count ?? 0
        let checkInCount: Int = checkInData?.count ?? 0
        let aiSessionCount: Int = aiData?.sessions.count ?? 0
        let aiMessageCount: Int = aiData?.messages.count ?? 0
        let achievementCount: Int = achievementData?.count ?? 0
        let subtotal1: Int = profileCount + workoutCount + exerciseCount + nutritionCount
        let subtotal2: Int = checkInCount + aiSessionCount + aiMessageCount + achievementCount
        let totalRecords: Int = subtotal1 + subtotal2

        // Build metadata
        let appVersion: String = {
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
            return "\(version) (\(build))"
        }()

        let metadata = ExportMetadata(
            exportDate: Self.iso8601Formatter.string(from: Date()),
            exportFormat: format.rawValue,
            userId: userId,
            dataVersion: "1.0",
            appVersion: appVersion,
            platform: "iOS",
            categoriesIncluded: categories.map(\.rawValue).sorted(),
            totalRecords: totalRecords
        )

        // Generate file
        let fileURL: URL
        switch format {
        case .json:
            let payload = ExportPayload(
                metadata: metadata,
                profile: profileData,
                workoutSessions: workoutData,
                exerciseLogs: exerciseData,
                nutritionLogs: nutritionData,
                checkIns: checkInData,
                aiConversations: aiData,
                achievements: achievementData
            )
            fileURL = try writeJSONExport(payload: payload)

        case .csv:
            fileURL = try writeCSVExport(
                metadata: metadata,
                profile: profileData,
                workoutSessions: workoutData,
                exerciseLogs: exerciseData,
                nutritionLogs: nutritionData,
                checkIns: checkInData,
                aiMessages: aiData?.messages,
                achievements: achievementData
            )
        }

        progressHandler?(1.0)

        // Record export in audit trail
        lastExportDate = Date()
        await recordExportAudit(userId: userId, format: format, recordCount: totalRecords)

        logger.success("DataExportService", "Export complete: \(totalRecords) records, format: \(format.rawValue)")

        return fileURL
    }

    // MARK: - Private Data Fetching

    /// Generic table fetch that returns raw dictionaries for maximum flexibility
    private func fetchTableData(
        table: String,
        filterColumn: String,
        filterValue: String
    ) async throws -> [[String: ExportAnyCodable]] {
        let response = try await supabase.client
            .from(table)
            .select()
            .eq(filterColumn, value: filterValue)
            .execute()

        let decoded = try JSONDecoder().decode([[String: ExportAnyCodable]].self, from: response.data)
        return decoded
    }

    /// Fetches AI chat sessions and their messages
    private func fetchAIConversationData(userId: String) async throws -> ExportAIData {
        // Fetch sessions
        let sessionsResponse = try await supabase.client
            .from("ai_chat_sessions")
            .select()
            .eq("athlete_id", value: userId)
            .order("started_at", ascending: false)
            .execute()

        let sessions = try JSONDecoder().decode([[String: ExportAnyCodable]].self, from: sessionsResponse.data)

        // Fetch messages for all sessions
        var allMessages: [[String: ExportAnyCodable]] = []

        for session in sessions {
            if let sessionId = session["id"]?.stringValue {
                let messagesResponse = try await supabase.client
                    .from("ai_chat_messages")
                    .select()
                    .eq("session_id", value: sessionId)
                    .order("created_at", ascending: true)
                    .execute()

                let messages = try JSONDecoder().decode([[String: ExportAnyCodable]].self, from: messagesResponse.data)
                allMessages.append(contentsOf: messages)
            }
        }

        return ExportAIData(sessions: sessions, messages: allMessages)
    }

    // MARK: - File Writing

    /// Writes a JSON export file with pretty printing
    private func writeJSONExport(payload: ExportPayload) throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(payload) else {
            throw DataExportError.encodingFailed
        }

        let fileName = "Modus_DataExport_\(filenameDateString()).json"
        let fileURL = exportDirectory().appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            logger.error("DataExportService", "Failed to write JSON file: \(error.localizedDescription)")
            throw DataExportError.fileWriteFailed
        }
    }

    /// Writes a CSV export file with all data categories as separate sections
    private func writeCSVExport(
        metadata: ExportMetadata,
        profile: [[String: ExportAnyCodable]]?,
        workoutSessions: [[String: ExportAnyCodable]]?,
        exerciseLogs: [[String: ExportAnyCodable]]?,
        nutritionLogs: [[String: ExportAnyCodable]]?,
        checkIns: [[String: ExportAnyCodable]]?,
        aiMessages: [[String: ExportAnyCodable]]?,
        achievements: [[String: ExportAnyCodable]]?
    ) throws -> URL {
        var csv = ""

        // Metadata header
        csv += "# Modus Data Export\n"
        csv += "# Export Date: \(metadata.exportDate)\n"
        csv += "# User ID: \(metadata.userId)\n"
        csv += "# Format: CSV\n"
        csv += "# Data Version: \(metadata.dataVersion)\n"
        csv += "# App Version: \(metadata.appVersion)\n"
        csv += "# Total Records: \(metadata.totalRecords)\n"
        csv += "\n"

        // Write each section
        if let data = profile, !data.isEmpty {
            csv += csvSection(title: "PROFILE", data: data)
        }

        if let data = workoutSessions, !data.isEmpty {
            csv += csvSection(title: "WORKOUT SESSIONS", data: data)
        }

        if let data = exerciseLogs, !data.isEmpty {
            csv += csvSection(title: "EXERCISE LOGS", data: data)
        }

        if let data = nutritionLogs, !data.isEmpty {
            csv += csvSection(title: "NUTRITION LOGS", data: data)
        }

        if let data = checkIns, !data.isEmpty {
            csv += csvSection(title: "DAILY CHECK-INS", data: data)
        }

        if let data = aiMessages, !data.isEmpty {
            csv += csvSection(title: "AI CONVERSATIONS", data: data)
        }

        if let data = achievements, !data.isEmpty {
            csv += csvSection(title: "ACHIEVEMENTS", data: data)
        }

        let fileName = "Modus_DataExport_\(filenameDateString()).csv"
        let fileURL = exportDirectory().appendingPathComponent(fileName)

        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            logger.error("DataExportService", "Failed to write CSV file: \(error.localizedDescription)")
            throw DataExportError.fileWriteFailed
        }
    }

    /// Converts a section of dictionary data into CSV rows
    private func csvSection(title: String, data: [[String: ExportAnyCodable]]) -> String {
        guard let first = data.first else { return "" }

        var section = "# --- \(title) ---\n"

        // Header row from sorted keys
        let keys = first.keys.sorted()
        section += keys.map { escapeCSV($0) }.joined(separator: ",") + "\n"

        // Data rows
        for row in data {
            let values = keys.map { key -> String in
                guard let value = row[key] else { return "" }
                return escapeCSV(value.displayString)
            }
            section += values.joined(separator: ",") + "\n"
        }

        section += "\n"
        return section
    }

    /// Escapes a CSV field value
    private func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }

    // MARK: - Audit Trail

    /// Records the export event for audit purposes
    private func recordExportAudit(userId: String, format: ExportFormat, recordCount: Int) async {
        do {
            let auditEntry: [String: String] = [
                "patient_id": userId,
                "action": "data_export",
                "details": "Exported \(recordCount) records in \(format.rawValue) format",
                "ip_address": "device"
            ]
            try await supabase.client
                .from("audit_logs")
                .insert(auditEntry)
                .execute()

            logger.info("DataExportService", "Audit trail recorded for data export")
        } catch {
            // Non-critical: log but do not fail the export
            logger.warning("DataExportService", "Failed to record audit trail: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    /// Returns a date string suitable for filenames
    private func filenameDateString() -> String {
        return Self.filenameDateFormatter.string(from: Date())
    }

    /// Creates and returns the export directory in the temporary folder
    private func exportDirectory() -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("ModusExports", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Cleans up old export files to free disk space
    func cleanupOldExports() {
        let dir = exportDirectory()
        guard let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.creationDateKey]) else {
            return
        }

        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        for file in files {
            if let attributes = try? FileManager.default.attributesOfItem(atPath: file.path),
               let creationDate = attributes[.creationDate] as? Date,
               creationDate < cutoff {
                try? FileManager.default.removeItem(at: file)
                logger.diagnostic("[DataExportService] Cleaned up old export: \(file.lastPathComponent)")
            }
        }
    }
}

// MARK: - ExportAnyCodable Helper

/// A type-erased Codable wrapper for handling dynamic Supabase JSON responses.
///
/// Supports encoding and decoding of common JSON value types including
/// strings, numbers, booleans, arrays, and nested objects.
struct ExportAnyCodable: Codable, Hashable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([ExportAnyCodable].self) {
            value = array.map(\.value)
        } else if let dict = try? container.decode([String: ExportAnyCodable].self) {
            value = dict.mapValues(\.value)
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        if value is NSNull {
            try container.encodeNil()
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let string = value as? String {
            try container.encode(string)
        } else if let array = value as? [Any] {
            let codableArray = array.map { ExportAnyCodable($0) }
            try container.encode(codableArray)
        } else if let dict = value as? [String: Any] {
            let codableDict = dict.mapValues { ExportAnyCodable($0) }
            try container.encode(codableDict)
        } else {
            try container.encodeNil()
        }
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(displayString)
    }

    static func == (lhs: ExportAnyCodable, rhs: ExportAnyCodable) -> Bool {
        lhs.displayString == rhs.displayString
    }

    // MARK: - Display

    /// Returns a string representation for CSV or display
    var displayString: String {
        if value is NSNull {
            return ""
        } else if let bool = value as? Bool {
            return bool ? "true" : "false"
        } else if let int = value as? Int {
            return String(int)
        } else if let double = value as? Double {
            return String(double)
        } else if let string = value as? String {
            return string
        } else if let array = value as? [Any] {
            let items = array.map { ExportAnyCodable($0).displayString }
            return items.joined(separator: "; ")
        } else if let dict = value as? [String: Any] {
            let pairs = dict.sorted(by: { $0.key < $1.key }).map { "\($0.key): \(ExportAnyCodable($0.value).displayString)" }
            return pairs.joined(separator: "; ")
        }
        return String(describing: value)
    }

    /// Attempts to return the value as a String
    var stringValue: String? {
        value as? String
    }
}
