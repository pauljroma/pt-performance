import Foundation
import Supabase

// MARK: - Pain Entry Model

/// Represents a persisted pain log entry from Supabase
struct PainEntry: Codable, Identifiable {
    let id: UUID
    let athleteId: UUID
    let regions: [String]
    let intensity: Int
    let notes: String?
    let loggedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case athleteId = "athlete_id"
        case regions
        case intensity
        case notes
        case loggedAt = "logged_at"
    }
}

// MARK: - Insert Models

/// Encodable struct for inserting a pain log row into Supabase
private struct PainLogInsert: Encodable {
    let id: String
    let athlete_id: String
    let regions: [String]
    let intensity: Int
    let notes: String?
    let logged_at: String
    let created_at: String
}

/// Encodable struct for inserting a therapist notification row into Supabase
private struct TherapistNotificationInsert: Encodable {
    let id: String
    let type: String
    let athlete_id: String
    let message: String
    let read: Bool
    let created_at: String
}

// MARK: - Pain Tracking Service

/// Service for persisting pain log entries and triggering therapist alerts.
///
/// Handles all Supabase operations for the `pain_logs` and `therapist_notifications` tables.
/// When a patient reports pain intensity >= 5, a real-time alert is inserted for the therapist.
///
/// ## Thread Safety
/// Marked `@MainActor` for safe UI updates. All methods are async.
@MainActor
final class PainTrackingService {
    static let shared = PainTrackingService()

    private let supabase = PTSupabaseClient.shared
    private let logger = DebugLogger.shared

    private init() {}

    // MARK: - ISO8601 Formatter

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    // MARK: - Save Pain Entry

    /// Inserts a new pain log entry into the `pain_logs` table.
    ///
    /// - Parameters:
    ///   - athleteId: The UUID of the athlete/patient logging pain.
    ///   - regions: Array of body region strings (e.g., `["shoulder_left", "lumbar"]`).
    ///   - intensity: Pain intensity on a 1-10 scale.
    ///   - notes: Optional free-text notes about the pain.
    func savePainEntry(athleteId: UUID, regions: [String], intensity: Int, notes: String?) async throws {
        let now = Date()
        let timestamp = Self.iso8601Formatter.string(from: now)

        let entry = PainLogInsert(
            id: UUID().uuidString,
            athlete_id: athleteId.uuidString,
            regions: regions,
            intensity: min(10, max(1, intensity)),
            notes: notes,
            logged_at: timestamp,
            created_at: timestamp
        )

        do {
            try await supabase.client
                .from("pain_logs")
                .insert(entry)
                .execute()

            logger.log("Pain entry saved — intensity: \(intensity), regions: \(regions.joined(separator: ", "))", level: .success)

            // Check if therapist should be alerted
            await checkAndAlertTherapist(athleteId: athleteId, intensity: intensity)
        } catch {
            logger.log("Failed to save pain entry: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    // MARK: - Fetch Pain History

    /// Fetches the most recent pain log entries for an athlete.
    ///
    /// - Parameters:
    ///   - athleteId: The UUID of the athlete/patient.
    ///   - limit: Maximum number of entries to return (default 20).
    /// - Returns: An array of `PainEntry` sorted by `logged_at` descending.
    func fetchPainHistory(athleteId: UUID, limit: Int = 20) async -> [PainEntry] {
        do {
            let entries: [PainEntry] = try await supabase.client
                .from("pain_logs")
                .select()
                .eq("athlete_id", value: athleteId.uuidString)
                .order("logged_at", ascending: false)
                .limit(limit)
                .execute()
                .value

            logger.log("Fetched \(entries.count) pain history entries", level: .info)
            return entries
        } catch {
            logger.log("Failed to fetch pain history: \(error.localizedDescription)", level: .error)
            return []
        }
    }

    // MARK: - Therapist Alert

    /// If intensity >= 5, inserts a high-pain notification into `therapist_notifications`.
    ///
    /// - Parameters:
    ///   - athleteId: The UUID of the athlete/patient.
    ///   - intensity: The reported pain intensity.
    func checkAndAlertTherapist(athleteId: UUID, intensity: Int) async {
        guard intensity >= 5 else { return }

        let now = Date()
        let timestamp = Self.iso8601Formatter.string(from: now)
        let severity = intensity >= 8 ? "critical" : "warning"

        let notification = TherapistNotificationInsert(
            id: UUID().uuidString,
            type: "high_pain",
            athlete_id: athleteId.uuidString,
            message: "Patient reported pain level \(intensity)/10 (\(severity))",
            read: false,
            created_at: timestamp
        )

        do {
            try await supabase.client
                .from("therapist_notifications")
                .insert(notification)
                .execute()

            logger.log("Therapist notified of high pain (\(intensity)/10) for athlete \(athleteId.uuidString.prefix(8))", level: .warning)
        } catch {
            logger.log("Failed to send therapist notification: \(error.localizedDescription)", level: .error)
        }
    }
}
