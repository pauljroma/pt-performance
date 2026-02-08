//
//  TimelineService.swift
//  PTPerformance
//
//  X2Index Phase 2 - Canonical Timeline (M3)
//  Service for aggregating and managing timeline events from multiple sources
//

import Foundation
import Supabase

// MARK: - Timeline Service Errors

enum TimelineServiceError: Error, LocalizedError {
    case fetchFailed(Error)
    case invalidDateRange
    case eventNotFound(UUID)
    case aggregationFailed
    case conflictDetectionFailed

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "Failed to fetch timeline: \(error.localizedDescription)"
        case .invalidDateRange:
            return "Invalid date range specified"
        case .eventNotFound(let id):
            return "Event not found: \(id)"
        case .aggregationFailed:
            return "Failed to aggregate timeline events"
        case .conflictDetectionFailed:
            return "Failed to detect conflicts between events"
        }
    }
}

// MARK: - Timeline Service

/// Service for managing the canonical timeline view
/// Aggregates events from: daily_readiness, exercise_logs, sleep data, check-ins
@MainActor
final class TimelineService: ObservableObject {

    // MARK: - Singleton

    static let shared = TimelineService()

    // MARK: - Properties

    private let client: PTSupabaseClient
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Cache

    private var cachedEvents: [UUID: [TimelineEvent]] = [:]
    private var cacheTimestamps: [UUID: Date] = [:]
    private let cacheValidityDuration: TimeInterval = 120 // 2 minutes

    // MARK: - Initialization

    nonisolated init(client: PTSupabaseClient = .shared) {
        self.client = client
    }

    // MARK: - Public API

    /// Fetch timeline events for a patient within a date range
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - dateRange: Date interval to fetch events for
    ///   - types: Optional filter for specific event types
    /// - Returns: Array of timeline events sorted by timestamp descending
    func getTimeline(
        patientId: UUID,
        dateRange: DateInterval,
        types: [TimelineEventType]? = nil
    ) async throws -> [TimelineEvent] {
        isLoading = true
        defer { isLoading = false }

        // Validate date range
        guard dateRange.start <= dateRange.end else {
            throw TimelineServiceError.invalidDateRange
        }

        do {
            // Fetch events from multiple sources concurrently
            async let readinessEvents = fetchReadinessEvents(patientId: patientId, dateRange: dateRange)
            async let workoutEvents = fetchWorkoutEvents(patientId: patientId, dateRange: dateRange)
            async let sleepEvents = fetchSleepEvents(patientId: patientId, dateRange: dateRange)
            async let recoveryEvents = fetchRecoveryEvents(patientId: patientId, dateRange: dateRange)
            async let vitalEvents = fetchVitalEvents(patientId: patientId, dateRange: dateRange)
            async let noteEvents = fetchNoteEvents(patientId: patientId, dateRange: dateRange)

            // Combine all events
            var allEvents: [TimelineEvent] = []
            allEvents.append(contentsOf: try await readinessEvents)
            allEvents.append(contentsOf: try await workoutEvents)
            allEvents.append(contentsOf: try await sleepEvents)
            allEvents.append(contentsOf: try await recoveryEvents)
            allEvents.append(contentsOf: try await vitalEvents)
            allEvents.append(contentsOf: try await noteEvents)

            // Filter by types if specified
            if let types = types, !types.isEmpty {
                allEvents = allEvents.filter { types.contains($0.eventType) }
            }

            // Sort by timestamp descending (newest first)
            allEvents.sort { $0.timestamp > $1.timestamp }

            // Detect and mark conflicts
            allEvents = markConflicts(in: allEvents)

            // Cache the results
            cachedEvents[patientId] = allEvents
            cacheTimestamps[patientId] = Date()

            return allEvents
        } catch {
            self.error = error
            throw TimelineServiceError.fetchFailed(error)
        }
    }

    /// Get detailed information about a specific event
    /// - Parameter eventId: Event UUID
    /// - Returns: Detailed event information including related events
    func getEventDetail(eventId: UUID) async throws -> TimelineEventDetail {
        // Search cache for the event
        for (patientId, events) in cachedEvents {
            if let event = events.first(where: { $0.id == eventId }) {
                return try await buildEventDetail(event: event, patientId: patientId)
            }
        }

        throw TimelineServiceError.eventNotFound(eventId)
    }

    /// Detect conflicts between events
    /// - Parameter events: Array of timeline events to analyze
    /// - Returns: Array of conflict groups
    func detectConflicts(events: [TimelineEvent]) -> [ConflictGroup] {
        var conflicts: [ConflictGroup] = []
        let calendar = Calendar.current

        // Group events by date
        let eventsByDate = Dictionary(grouping: events) { event in
            calendar.startOfDay(for: event.timestamp)
        }

        for (date, dateEvents) in eventsByDate {
            // Check for conflicts within each event type on the same date
            let eventsByType = Dictionary(grouping: dateEvents) { $0.eventType }

            for (type, typeEvents) in eventsByType {
                // Check for duplicate entries from different sources
                let sourceGroups = Dictionary(grouping: typeEvents) { $0.sourceType }
                if sourceGroups.count > 1 {
                    // Multiple sources for same event type on same day
                    let eventIds = typeEvents.map { $0.id }
                    let sources = sourceGroups.keys.map { $0.displayName }.joined(separator: ", ")

                    conflicts.append(ConflictGroup(
                        eventIds: eventIds,
                        conflictType: .sourceDisagreement,
                        description: "\(type.displayName) data from multiple sources: \(sources)",
                        timestamp: date
                    ))
                }

                // Check for value discrepancies (e.g., different sleep durations)
                if type == .sleep && typeEvents.count > 1 {
                    let sleepHours = typeEvents.compactMap { $0.metadataDouble(for: "total_hours") }
                    if let min = sleepHours.min(), let max = sleepHours.max(), max - min > 1.0 {
                        conflicts.append(ConflictGroup(
                            eventIds: typeEvents.map { $0.id },
                            conflictType: .valueDiscrepancy,
                            description: "Sleep duration differs by more than 1 hour between sources",
                            timestamp: date
                        ))
                    }
                }

                // Check for vital discrepancies
                if type == .vital && typeEvents.count > 1 {
                    let hrValues = typeEvents.compactMap { $0.metadataInt(for: "resting_hr") }
                    if let min = hrValues.min(), let max = hrValues.max(), max - min > 10 {
                        conflicts.append(ConflictGroup(
                            eventIds: typeEvents.map { $0.id },
                            conflictType: .valueDiscrepancy,
                            description: "Resting heart rate differs by more than 10 bpm",
                            timestamp: date
                        ))
                    }
                }
            }
        }

        return conflicts
    }

    /// Get event counts by type for filter badges
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - dateRange: Date interval to count events in
    /// - Returns: Dictionary mapping event types to counts
    func getEventCounts(
        patientId: UUID,
        dateRange: DateInterval
    ) async throws -> [TimelineEventType: Int] {
        let events = try await getTimeline(patientId: patientId, dateRange: dateRange, types: nil)

        var counts: [TimelineEventType: Int] = [:]
        for type in TimelineEventType.allCases {
            counts[type] = events.filter { $0.eventType == type }.count
        }

        return counts
    }

    /// Clear cached data for a patient
    func clearCache(for patientId: UUID) {
        cachedEvents.removeValue(forKey: patientId)
        cacheTimestamps.removeValue(forKey: patientId)
    }

    /// Clear all cached data
    func clearAllCache() {
        cachedEvents.removeAll()
        cacheTimestamps.removeAll()
    }

    // MARK: - Private Methods - Data Fetching

    /// Fetch readiness/check-in events
    private func fetchReadinessEvents(patientId: UUID, dateRange: DateInterval) async throws -> [TimelineEvent] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDate = dateFormatter.string(from: dateRange.start)
        let endDate = dateFormatter.string(from: dateRange.end)

        do {
            let response = try await client.client
                .from("daily_readiness")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .gte("date", value: startDate)
                .lte("date", value: endDate)
                .order("date", ascending: false)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)

                // Try multiple date formats
                let formatters: [DateFormatter] = [
                    {
                        let f = DateFormatter()
                        f.dateFormat = "yyyy-MM-dd"
                        return f
                    }(),
                    {
                        let f = DateFormatter()
                        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                        return f
                    }()
                ]

                for formatter in formatters {
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                }

                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
            }

            let readinessRecords = try decoder.decode([DailyReadiness].self, from: response.data)

            return readinessRecords.map { record in
                TimelineEvent(
                    id: record.id,
                    patientId: patientId,
                    eventType: .checkIn,
                    timestamp: record.date,
                    title: "Daily Check-in",
                    summary: buildReadinessSummary(record),
                    sourceType: .supabase,
                    conflictsWith: nil,
                    metadata: [
                        "readiness_score": record.readinessScore.map { .double($0) } ?? .null,
                        "sleep_hours": record.sleepHours.map { .double($0) } ?? .null,
                        "energy_level": record.energyLevel.map { .int($0) } ?? .null,
                        "soreness_level": record.sorenessLevel.map { .int($0) } ?? .null,
                        "stress_level": record.stressLevel.map { .int($0) } ?? .null
                    ]
                )
            }
        } catch {
            DebugLogger.shared.warning("TIMELINE", "Failed to fetch readiness events: \(error.localizedDescription)")
            return []
        }
    }

    /// Fetch workout/exercise events
    private func fetchWorkoutEvents(patientId: UUID, dateRange: DateInterval) async throws -> [TimelineEvent] {
        let dateFormatter = ISO8601DateFormatter()
        let startDate = dateFormatter.string(from: dateRange.start)
        let endDate = dateFormatter.string(from: dateRange.end)

        do {
            let response = try await client.client
                .from("exercise_logs")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .gte("logged_at", value: startDate)
                .lte("logged_at", value: endDate)
                .order("logged_at", ascending: false)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            // Decode raw response
            guard let json = try? JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] else {
                return []
            }

            var events: [TimelineEvent] = []

            // Group by workout session
            let sessionGroups = Dictionary(grouping: json) { record -> String in
                (record["workout_id"] as? String) ?? (record["scheduled_workout_id"] as? String) ?? UUID().uuidString
            }

            for (workoutId, exercises) in sessionGroups {
                guard let firstExercise = exercises.first,
                      let loggedAtString = firstExercise["logged_at"] as? String,
                      let loggedAt = ISO8601DateFormatter().date(from: loggedAtString) else {
                    continue
                }

                let exerciseCount = exercises.count
                let totalVolume = exercises.compactMap { exercise -> Double? in
                    guard let sets = exercise["sets_completed"] as? Int,
                          let reps = exercise["reps_completed"] as? Int,
                          let weight = exercise["weight_used"] as? Double else {
                        return nil
                    }
                    return Double(sets * reps) * weight
                }.reduce(0, +)

                events.append(TimelineEvent(
                    id: UUID(uuidString: workoutId) ?? UUID(),
                    patientId: patientId,
                    eventType: .workout,
                    timestamp: loggedAt,
                    title: (firstExercise["workout_name"] as? String) ?? "Workout Session",
                    summary: "\(exerciseCount) exercises, \(formatVolume(totalVolume)) volume",
                    sourceType: .supabase,
                    conflictsWith: nil,
                    metadata: [
                        "exercise_count": .int(exerciseCount),
                        "total_volume": .double(totalVolume)
                    ]
                ))
            }

            return events
        } catch {
            DebugLogger.shared.warning("TIMELINE", "Failed to fetch workout events: \(error.localizedDescription)")
            return []
        }
    }

    /// Fetch sleep events (from HealthKit sync table)
    private func fetchSleepEvents(patientId: UUID, dateRange: DateInterval) async throws -> [TimelineEvent] {
        let dateFormatter = ISO8601DateFormatter()
        let startDate = dateFormatter.string(from: dateRange.start)
        let endDate = dateFormatter.string(from: dateRange.end)

        do {
            let response = try await client.client
                .from("health_sync_data")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .eq("data_type", value: "sleep")
                .gte("recorded_at", value: startDate)
                .lte("recorded_at", value: endDate)
                .order("recorded_at", ascending: false)
                .execute()

            guard let json = try? JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] else {
                return []
            }

            return json.compactMap { record -> TimelineEvent? in
                guard let idString = record["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let recordedAtString = record["recorded_at"] as? String,
                      let recordedAt = ISO8601DateFormatter().date(from: recordedAtString),
                      let data = record["data"] as? [String: Any] else {
                    return nil
                }

                let totalHours = (data["total_hours"] as? Double) ?? 0
                let efficiency = (data["efficiency"] as? Int) ?? 0
                let deepSleep = (data["deep_sleep_hours"] as? Double) ?? 0
                let source = (record["source"] as? String) ?? "health_kit"

                return TimelineEvent(
                    id: id,
                    patientId: patientId,
                    eventType: .sleep,
                    timestamp: recordedAt,
                    title: "Sleep Session",
                    summary: String(format: "%.1fh total, %d%% efficiency, %.1fh deep", totalHours, efficiency, deepSleep),
                    sourceType: TimelineDataSource(rawValue: source) ?? .healthKit,
                    conflictsWith: nil,
                    metadata: [
                        "total_hours": .double(totalHours),
                        "efficiency": .int(efficiency),
                        "deep_sleep_hours": .double(deepSleep)
                    ]
                )
            }
        } catch {
            DebugLogger.shared.warning("TIMELINE", "Failed to fetch sleep events: \(error.localizedDescription)")
            return []
        }
    }

    /// Fetch recovery events
    private func fetchRecoveryEvents(patientId: UUID, dateRange: DateInterval) async throws -> [TimelineEvent] {
        let dateFormatter = ISO8601DateFormatter()
        let startDate = dateFormatter.string(from: dateRange.start)
        let endDate = dateFormatter.string(from: dateRange.end)

        do {
            let response = try await client.client
                .from("health_sync_data")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .eq("data_type", value: "recovery")
                .gte("recorded_at", value: startDate)
                .lte("recorded_at", value: endDate)
                .order("recorded_at", ascending: false)
                .execute()

            guard let json = try? JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] else {
                return []
            }

            return json.compactMap { record -> TimelineEvent? in
                guard let idString = record["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let recordedAtString = record["recorded_at"] as? String,
                      let recordedAt = ISO8601DateFormatter().date(from: recordedAtString),
                      let data = record["data"] as? [String: Any] else {
                    return nil
                }

                let recoveryScore = (data["recovery_score"] as? Int) ?? 0
                let hrvValue = (data["hrv"] as? Double) ?? 0
                let source = (record["source"] as? String) ?? "health_kit"

                return TimelineEvent(
                    id: id,
                    patientId: patientId,
                    eventType: .recovery,
                    timestamp: recordedAt,
                    title: "Recovery Score",
                    summary: "\(recoveryScore)% recovery, HRV: \(Int(hrvValue))ms",
                    sourceType: TimelineDataSource(rawValue: source) ?? .healthKit,
                    conflictsWith: nil,
                    metadata: [
                        "recovery_score": .int(recoveryScore),
                        "hrv": .double(hrvValue)
                    ]
                )
            }
        } catch {
            DebugLogger.shared.warning("TIMELINE", "Failed to fetch recovery events: \(error.localizedDescription)")
            return []
        }
    }

    /// Fetch vital events (heart rate, HRV, etc.)
    private func fetchVitalEvents(patientId: UUID, dateRange: DateInterval) async throws -> [TimelineEvent] {
        let dateFormatter = ISO8601DateFormatter()
        let startDate = dateFormatter.string(from: dateRange.start)
        let endDate = dateFormatter.string(from: dateRange.end)

        do {
            let response = try await client.client
                .from("health_sync_data")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .eq("data_type", value: "vitals")
                .gte("recorded_at", value: startDate)
                .lte("recorded_at", value: endDate)
                .order("recorded_at", ascending: false)
                .execute()

            guard let json = try? JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] else {
                return []
            }

            return json.compactMap { record -> TimelineEvent? in
                guard let idString = record["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let recordedAtString = record["recorded_at"] as? String,
                      let recordedAt = ISO8601DateFormatter().date(from: recordedAtString),
                      let data = record["data"] as? [String: Any] else {
                    return nil
                }

                let restingHR = (data["resting_hr"] as? Int) ?? 0
                let hrvValue = (data["hrv"] as? Double) ?? 0
                let source = (record["source"] as? String) ?? "health_kit"

                return TimelineEvent(
                    id: id,
                    patientId: patientId,
                    eventType: .vital,
                    timestamp: recordedAt,
                    title: "Daily Vitals",
                    summary: "Resting HR: \(restingHR) bpm, HRV: \(Int(hrvValue))ms",
                    sourceType: TimelineDataSource(rawValue: source) ?? .healthKit,
                    conflictsWith: nil,
                    metadata: [
                        "resting_hr": .int(restingHR),
                        "hrv": .double(hrvValue)
                    ]
                )
            }
        } catch {
            DebugLogger.shared.warning("TIMELINE", "Failed to fetch vital events: \(error.localizedDescription)")
            return []
        }
    }

    /// Fetch note events
    private func fetchNoteEvents(patientId: UUID, dateRange: DateInterval) async throws -> [TimelineEvent] {
        let dateFormatter = ISO8601DateFormatter()
        let startDate = dateFormatter.string(from: dateRange.start)
        let endDate = dateFormatter.string(from: dateRange.end)

        do {
            let response = try await client.client
                .from("session_notes")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .gte("created_at", value: startDate)
                .lte("created_at", value: endDate)
                .order("created_at", ascending: false)
                .execute()

            guard let json = try? JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] else {
                return []
            }

            return json.compactMap { record -> TimelineEvent? in
                guard let idString = record["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let createdAtString = record["created_at"] as? String,
                      let createdAt = ISO8601DateFormatter().date(from: createdAtString) else {
                    return nil
                }

                let noteText = (record["note_text"] as? String) ?? ""
                let noteType = (record["note_type"] as? String) ?? "general"

                return TimelineEvent(
                    id: id,
                    patientId: patientId,
                    eventType: .note,
                    timestamp: createdAt,
                    title: noteType.capitalized + " Note",
                    summary: String(noteText.prefix(100)) + (noteText.count > 100 ? "..." : ""),
                    sourceType: .supabase,
                    conflictsWith: nil,
                    metadata: [
                        "note_type": .string(noteType),
                        "full_text": .string(noteText)
                    ]
                )
            }
        } catch {
            DebugLogger.shared.warning("TIMELINE", "Failed to fetch note events: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Private Methods - Helpers

    /// Build summary string for readiness record
    private func buildReadinessSummary(_ record: DailyReadiness) -> String {
        var parts: [String] = []

        if let score = record.readinessScore {
            parts.append("Score: \(Int(score))%")
        }

        if let sleep = record.sleepHours {
            parts.append(String(format: "%.1fh sleep", sleep))
        }

        if let energy = record.energyLevel {
            parts.append("Energy: \(energy)/10")
        }

        return parts.isEmpty ? "No data recorded" : parts.joined(separator: ", ")
    }

    /// Format volume for display
    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fK lbs", volume / 1000)
        }
        return String(format: "%.0f lbs", volume)
    }

    /// Mark events with conflict information
    private func markConflicts(in events: [TimelineEvent]) -> [TimelineEvent] {
        let conflictGroups = detectConflicts(events: events)
        var eventConflicts: [UUID: [UUID]] = [:]

        // Build conflict map
        for group in conflictGroups {
            for eventId in group.eventIds {
                let otherIds = group.eventIds.filter { $0 != eventId }
                eventConflicts[eventId, default: []].append(contentsOf: otherIds)
            }
        }

        // Update events with conflict information
        return events.map { event in
            if let conflicts = eventConflicts[event.id], !conflicts.isEmpty {
                return TimelineEvent(
                    id: event.id,
                    patientId: event.patientId,
                    eventType: event.eventType,
                    timestamp: event.timestamp,
                    title: event.title,
                    summary: event.summary,
                    sourceType: event.sourceType,
                    conflictsWith: conflicts,
                    metadata: event.metadata
                )
            }
            return event
        }
    }

    /// Build detailed event information
    private func buildEventDetail(event: TimelineEvent, patientId: UUID) async throws -> TimelineEventDetail {
        var sections: [TimelineEventDetail.DetailSection] = []

        // Build sections based on event type
        switch event.eventType {
        case .checkIn:
            var items: [TimelineEventDetail.DetailItem] = []

            if let score = event.metadataDouble(for: "readiness_score") {
                items.append(TimelineEventDetail.DetailItem(
                    label: "Readiness Score",
                    value: "\(Int(score))%",
                    icon: "chart.pie.fill"
                ))
            }

            if let sleep = event.metadataDouble(for: "sleep_hours") {
                items.append(TimelineEventDetail.DetailItem(
                    label: "Sleep",
                    value: String(format: "%.1f hours", sleep),
                    icon: "bed.double.fill"
                ))
            }

            if let energy = event.metadataInt(for: "energy_level") {
                items.append(TimelineEventDetail.DetailItem(
                    label: "Energy Level",
                    value: "\(energy)/10",
                    icon: "bolt.fill"
                ))
            }

            if let soreness = event.metadataInt(for: "soreness_level") {
                items.append(TimelineEventDetail.DetailItem(
                    label: "Soreness",
                    value: "\(soreness)/10",
                    icon: "figure.walk"
                ))
            }

            if let stress = event.metadataInt(for: "stress_level") {
                items.append(TimelineEventDetail.DetailItem(
                    label: "Stress",
                    value: "\(stress)/10",
                    icon: "brain.head.profile"
                ))
            }

            if !items.isEmpty {
                sections.append(TimelineEventDetail.DetailSection(title: "Metrics", items: items))
            }

        case .workout:
            var items: [TimelineEventDetail.DetailItem] = []

            if let count = event.metadataInt(for: "exercise_count") {
                items.append(TimelineEventDetail.DetailItem(
                    label: "Exercises",
                    value: "\(count)",
                    icon: "list.bullet"
                ))
            }

            if let volume = event.metadataDouble(for: "total_volume") {
                items.append(TimelineEventDetail.DetailItem(
                    label: "Total Volume",
                    value: formatVolume(volume),
                    icon: "scalemass.fill"
                ))
            }

            if !items.isEmpty {
                sections.append(TimelineEventDetail.DetailSection(title: "Workout Summary", items: items))
            }

        case .sleep:
            var items: [TimelineEventDetail.DetailItem] = []

            if let hours = event.metadataDouble(for: "total_hours") {
                items.append(TimelineEventDetail.DetailItem(
                    label: "Total Sleep",
                    value: String(format: "%.1f hours", hours),
                    icon: "bed.double.fill"
                ))
            }

            if let efficiency = event.metadataInt(for: "efficiency") {
                items.append(TimelineEventDetail.DetailItem(
                    label: "Efficiency",
                    value: "\(efficiency)%",
                    icon: "percent"
                ))
            }

            if let deep = event.metadataDouble(for: "deep_sleep_hours") {
                items.append(TimelineEventDetail.DetailItem(
                    label: "Deep Sleep",
                    value: String(format: "%.1f hours", deep),
                    icon: "moon.zzz.fill"
                ))
            }

            if !items.isEmpty {
                sections.append(TimelineEventDetail.DetailSection(title: "Sleep Analysis", items: items))
            }

        case .recovery:
            var items: [TimelineEventDetail.DetailItem] = []

            if let score = event.metadataInt(for: "recovery_score") {
                items.append(TimelineEventDetail.DetailItem(
                    label: "Recovery Score",
                    value: "\(score)%",
                    icon: "heart.fill"
                ))
            }

            if let hrv = event.metadataDouble(for: "hrv") {
                items.append(TimelineEventDetail.DetailItem(
                    label: "HRV",
                    value: "\(Int(hrv)) ms",
                    icon: "waveform.path.ecg"
                ))
            }

            if !items.isEmpty {
                sections.append(TimelineEventDetail.DetailSection(title: "Recovery Metrics", items: items))
            }

        case .vital:
            var items: [TimelineEventDetail.DetailItem] = []

            if let hr = event.metadataInt(for: "resting_hr") {
                items.append(TimelineEventDetail.DetailItem(
                    label: "Resting Heart Rate",
                    value: "\(hr) bpm",
                    icon: "heart.fill"
                ))
            }

            if let hrv = event.metadataDouble(for: "hrv") {
                items.append(TimelineEventDetail.DetailItem(
                    label: "HRV",
                    value: "\(Int(hrv)) ms",
                    icon: "waveform.path.ecg"
                ))
            }

            if !items.isEmpty {
                sections.append(TimelineEventDetail.DetailSection(title: "Vital Signs", items: items))
            }

        case .note:
            if let fullText = event.metadataString(for: "full_text") {
                sections.append(TimelineEventDetail.DetailSection(
                    title: "Note Content",
                    items: [
                        TimelineEventDetail.DetailItem(
                            label: "Note",
                            value: fullText,
                            icon: "note.text"
                        )
                    ]
                ))
            }
        }

        // Add source information section
        sections.append(TimelineEventDetail.DetailSection(
            title: "Data Source",
            items: [
                TimelineEventDetail.DetailItem(
                    label: "Source",
                    value: event.sourceType.displayName,
                    icon: event.sourceType.iconName
                ),
                TimelineEventDetail.DetailItem(
                    label: "Recorded",
                    value: event.timestamp.formatted(date: .abbreviated, time: .shortened),
                    icon: "clock.fill"
                )
            ]
        ))

        // Get conflicting events if any
        var conflictingEvents: [TimelineEvent]? = nil
        if let conflictIds = event.conflictsWith, !conflictIds.isEmpty {
            if let cached = cachedEvents[patientId] {
                conflictingEvents = cached.filter { conflictIds.contains($0.id) }
            }
        }

        return TimelineEventDetail(
            id: event.id,
            event: event,
            detailSections: sections,
            relatedEvents: nil,
            conflictingEvents: conflictingEvents
        )
    }
}
