//
//  CheckInService.swift
//  PTPerformance
//
//  X2Index M8: Check-In Service
//  Singleton service for managing athlete daily check-ins
//  Syncs to Supabase immediately with local caching for offline support
//

import SwiftUI
import Foundation

// MARK: - Encodable Structs for Supabase RPC

/// RPC parameters for submitting a check-in
private struct SubmitCheckInParams: Encodable {
    let pAthleteId: String
    let pDate: String
    let pSleepQuality: Int
    let pSleepHours: Double?
    let pSoreness: Int
    let pSorenessLocations: [String]?
    let pStress: Int
    let pEnergy: Int
    let pPainScore: Int?
    let pPainLocations: [String]?
    let pMood: Int
    let pFreeText: String?

    enum CodingKeys: String, CodingKey {
        case pAthleteId = "p_athlete_id"
        case pDate = "p_date"
        case pSleepQuality = "p_sleep_quality"
        case pSleepHours = "p_sleep_hours"
        case pSoreness = "p_soreness"
        case pSorenessLocations = "p_soreness_locations"
        case pStress = "p_stress"
        case pEnergy = "p_energy"
        case pPainScore = "p_pain_score"
        case pPainLocations = "p_pain_locations"
        case pMood = "p_mood"
        case pFreeText = "p_free_text"
    }
}

/// RPC parameters for getting check-in
private struct GetCheckInParams: Encodable {
    let pAthleteId: String
    let pDate: String

    enum CodingKeys: String, CodingKey {
        case pAthleteId = "p_athlete_id"
        case pDate = "p_date"
    }
}

/// RPC parameters for getting check-in history
private struct GetCheckInHistoryParams: Encodable {
    let pAthleteId: String
    let pDays: Int

    enum CodingKeys: String, CodingKey {
        case pAthleteId = "p_athlete_id"
        case pDays = "p_days"
    }
}

/// RPC parameters for getting streak
private struct GetCheckInStreakParams: Encodable {
    let pAthleteId: String

    enum CodingKeys: String, CodingKey {
        case pAthleteId = "p_athlete_id"
    }
}

// MARK: - Check-In Service

/// Service for managing athlete daily check-ins
///
/// Provides methods for:
/// - Submitting daily check-ins
/// - Retrieving today's check-in
/// - Fetching check-in history
/// - Getting streak information
///
/// Features:
/// - Immediate sync to Supabase
/// - Local caching for offline support
/// - Target: <=60 second sync latency
@MainActor
class CheckInService: ObservableObject {

    // MARK: - Singleton

    static let shared = CheckInService()

    // MARK: - Properties

    nonisolated(unsafe) private let client: PTSupabaseClient
    private let logger = DebugLogger.shared
    private let errorLogger = ErrorLogger.shared

    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var todayCheckIn: DailyCheckIn?
    @Published var currentStreak: CheckInStreak?

    // Local cache
    private var checkInCache: [String: DailyCheckIn] = [:]
    private var lastCacheUpdate: Date?
    private let cacheExpirationSeconds: TimeInterval = 300 // 5 minutes

    // MARK: - Initialization

    nonisolated init(client: PTSupabaseClient = .shared) {
        self.client = client
    }

    // MARK: - Submit Check-In

    /// Submit a new daily check-in
    ///
    /// - Parameter checkIn: The check-in data to submit
    /// - Returns: The created DailyCheckIn record
    /// - Throws: CheckInError if submission fails
    @discardableResult
    func submitCheckIn(_ checkIn: DailyCheckInInput) async throws -> DailyCheckIn {
        isLoading = true
        defer { isLoading = false }

        // Validate input
        try checkIn.validate()

        guard let athleteIdString = PTSupabaseClient.shared.userId,
              let athleteId = UUID(uuidString: athleteIdString) else {
            throw CheckInError.notAuthenticated
        }

        // Format date as YYYY-MM-DD
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: Date())

        logger.log("[CheckInService] Submitting check-in for athlete: \(athleteIdString), date: \(dateString)", level: .diagnostic)

        do {
            // Try RPC function first
            let params = SubmitCheckInParams(
                pAthleteId: athleteIdString,
                pDate: dateString,
                pSleepQuality: checkIn.sleepQuality,
                pSleepHours: checkIn.sleepHours,
                pSoreness: checkIn.soreness,
                pSorenessLocations: checkIn.sorenessLocations,
                pStress: checkIn.stress,
                pEnergy: checkIn.energy,
                pPainScore: checkIn.painScore,
                pPainLocations: checkIn.painLocations,
                pMood: checkIn.mood,
                pFreeText: checkIn.freeText
            )

            let response = try await client.client
                .rpc("upsert_daily_checkin", params: params)
                .execute()

            let decoder = createCheckInDecoder()
            let savedCheckIn = try decoder.decode(DailyCheckIn.self, from: response.data)

            // Update cache and published properties
            let cacheKey = "\(athleteIdString)_\(dateString)"
            checkInCache[cacheKey] = savedCheckIn
            todayCheckIn = savedCheckIn

            // Refresh streak after submission
            _ = try? await getStreak()

            logger.log("[CheckInService] Check-in submitted successfully", level: .success)
            return savedCheckIn

        } catch {
            // Cancelled requests — re-throw without logging
            if error.isCancellation { throw error }

            // Fall back to direct table insert if RPC doesn't exist — this is expected behavior
            logger.logWithCooldown(key: "checkin_rpc_fallback_insert", cooldown: 5, "[CheckInService] RPC failed, trying direct insert: \(error.localizedDescription)", level: .diagnostic)

            do {
                let insertData: [String: AnyEncodable] = [
                    "athlete_id": AnyEncodable(athleteIdString),
                    "date": AnyEncodable(dateString),
                    "sleep_quality": AnyEncodable(checkIn.sleepQuality),
                    "sleep_hours": AnyEncodable(checkIn.sleepHours),
                    "soreness": AnyEncodable(checkIn.soreness),
                    "soreness_locations": AnyEncodable(checkIn.sorenessLocations),
                    "stress": AnyEncodable(checkIn.stress),
                    "energy": AnyEncodable(checkIn.energy),
                    "pain_score": AnyEncodable(checkIn.painScore),
                    "pain_locations": AnyEncodable(checkIn.painLocations),
                    "mood": AnyEncodable(checkIn.mood),
                    "free_text": AnyEncodable(checkIn.freeText),
                    "completed_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
                ]

                let response = try await client.client
                    .from("daily_checkins")
                    .upsert(insertData, onConflict: "athlete_id,date")
                    .select()
                    .single()
                    .execute()

                let decoder = createCheckInDecoder()
                let savedCheckIn = try decoder.decode(DailyCheckIn.self, from: response.data)

                // Update cache and published properties
                let cacheKey = "\(athleteIdString)_\(dateString)"
                checkInCache[cacheKey] = savedCheckIn
                todayCheckIn = savedCheckIn

                logger.log("[CheckInService] Check-in submitted via direct insert", level: .success)
                return savedCheckIn

            } catch let insertError {
                errorLogger.logError(insertError, context: "CheckInService.submitCheckIn", metadata: [
                    "athlete_id": athleteIdString,
                    "date": dateString
                ])
                self.error = insertError
                throw CheckInError.saveFailed
            }
        }
    }

    // MARK: - Get Today's Check-In

    /// Fetch today's check-in for the current athlete
    ///
    /// - Returns: Today's DailyCheckIn or nil if not found
    /// - Throws: CheckInError if fetch fails
    func getTodayCheckIn() async -> DailyCheckIn? {
        guard let athleteIdString = PTSupabaseClient.shared.userId else {
            logger.log("[CheckInService] No authenticated user", level: .warning)
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: Date())

        // Check cache first
        let cacheKey = "\(athleteIdString)_\(dateString)"
        if let cached = checkInCache[cacheKey],
           let lastUpdate = lastCacheUpdate,
           Date().timeIntervalSince(lastUpdate) < cacheExpirationSeconds {
            logger.log("[CheckInService] Returning cached check-in", level: .diagnostic)
            return cached
        }

        logger.log("[CheckInService] Fetching today's check-in for: \(dateString)", level: .diagnostic)

        do {
            // Try RPC function first
            let params = GetCheckInParams(pAthleteId: athleteIdString, pDate: dateString)
            let response = try await client.client
                .rpc("get_daily_checkin", params: params)
                .execute()

            // Check for null response
            if let rawJSON = String(data: response.data, encoding: .utf8),
               rawJSON == "null" || rawJSON.isEmpty {
                logger.log("[CheckInService] No check-in found for today", level: .info)
                return nil
            }

            let decoder = createCheckInDecoder()
            let checkIn = try decoder.decode(DailyCheckIn.self, from: response.data)

            // Update cache
            checkInCache[cacheKey] = checkIn
            lastCacheUpdate = Date()
            todayCheckIn = checkIn

            logger.log("[CheckInService] Fetched today's check-in", level: .success)
            return checkIn

        } catch {
            // Cancelled requests (e.g. navigation) — don't log at all
            guard !error.isCancellation else { return nil }

            // Fall back to direct query — this is expected behavior, not an error
            logger.logWithCooldown(key: "checkin_rpc_fallback_query", cooldown: 5, "[CheckInService] RPC failed, trying direct query: \(error.localizedDescription)", level: .diagnostic)

            do {
                let response = try await client.client
                    .from("daily_checkins")
                    .select()
                    .eq("athlete_id", value: athleteIdString)
                    .eq("date", value: dateString)
                    .limit(1)
                    .execute()

                let decoder = createCheckInDecoder()
                let checkIns = try decoder.decode([DailyCheckIn].self, from: response.data)

                if let checkIn = checkIns.first {
                    checkInCache[cacheKey] = checkIn
                    lastCacheUpdate = Date()
                    todayCheckIn = checkIn
                    return checkIn
                }

                return nil

            } catch let queryError {
                guard !queryError.isCancellation else { return nil }
                errorLogger.logError(queryError, context: "CheckInService.getTodayCheckIn")
                return nil
            }
        }
    }

    // MARK: - Get Check-In History

    /// Fetch check-in history for the specified number of days
    ///
    /// - Parameter days: Number of days to fetch (default 7)
    /// - Returns: Array of DailyCheckIn records, ordered by date descending
    func getCheckInHistory(days: Int = 7) async -> [DailyCheckIn] {
        guard let athleteIdString = PTSupabaseClient.shared.userId else {
            logger.log("[CheckInService] No authenticated user for history fetch", level: .warning)
            return []
        }

        logger.log("[CheckInService] Fetching check-in history for last \(days) days", level: .diagnostic)

        do {
            // Try RPC function first
            let params = GetCheckInHistoryParams(pAthleteId: athleteIdString, pDays: days)
            let response = try await client.client
                .rpc("get_checkin_history", params: params)
                .execute()

            let decoder = createCheckInDecoder()
            let checkIns = try decoder.decode([DailyCheckIn].self, from: response.data)

            logger.log("[CheckInService] Fetched \(checkIns.count) check-ins", level: .success)
            return checkIns

        } catch {
            // Cancelled requests — return empty without logging
            guard !error.isCancellation else { return [] }

            // Fall back to direct query — expected behavior
            logger.logWithCooldown(key: "checkin_rpc_fallback_history", cooldown: 5, "[CheckInService] RPC failed, trying direct query for history", level: .diagnostic)

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone.current

            let endDate = Date()
            guard let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) else {
                return []
            }

            do {
                let response = try await client.client
                    .from("daily_checkins")
                    .select()
                    .eq("athlete_id", value: athleteIdString)
                    .gte("date", value: dateFormatter.string(from: startDate))
                    .lte("date", value: dateFormatter.string(from: endDate))
                    .order("date", ascending: false)
                    .execute()

                let decoder = createCheckInDecoder()
                let checkIns = try decoder.decode([DailyCheckIn].self, from: response.data)
                return checkIns

            } catch let queryError {
                errorLogger.logError(queryError, context: "CheckInService.getCheckInHistory")
                return []
            }
        }
    }

    // MARK: - Get Streak

    /// Fetch current streak information
    ///
    /// - Returns: CheckInStreak with current and longest streak data
    func getStreak() async -> CheckInStreak {
        guard let athleteIdString = PTSupabaseClient.shared.userId else {
            logger.log("[CheckInService] No authenticated user for streak fetch", level: .warning)
            return CheckInStreak()
        }

        logger.log("[CheckInService] Fetching check-in streak", level: .diagnostic)

        do {
            // Try RPC function first
            let params = GetCheckInStreakParams(pAthleteId: athleteIdString)
            let response = try await client.client
                .rpc("get_checkin_streak", params: params)
                .execute()

            // Check for null response
            if let rawJSON = String(data: response.data, encoding: .utf8),
               rawJSON == "null" || rawJSON.isEmpty {
                let emptyStreak = CheckInStreak()
                currentStreak = emptyStreak
                return emptyStreak
            }

            let decoder = createCheckInDecoder()
            let streak = try decoder.decode(CheckInStreak.self, from: response.data)

            currentStreak = streak
            logger.log("[CheckInService] Streak: \(streak.currentStreak) days", level: .success)
            return streak

        } catch {
            // Cancelled requests — return empty streak without logging
            guard !error.isCancellation else { return CheckInStreak() }

            // Fall back to calculating from history — expected behavior
            logger.logWithCooldown(key: "checkin_rpc_fallback_streak", cooldown: 5, "[CheckInService] RPC failed, calculating streak from history", level: .diagnostic)

            let history = await getCheckInHistory(days: 365)
            let streak = calculateStreak(from: history)
            currentStreak = streak
            return streak
        }
    }

    // MARK: - Check Has Checked In Today

    /// Check if the athlete has already checked in today
    ///
    /// - Returns: True if today's check-in exists
    func hasCheckedInToday() async -> Bool {
        let checkIn = await getTodayCheckIn()
        return checkIn != nil
    }

    // MARK: - Clear Cache

    /// Clear the local cache
    func clearCache() {
        checkInCache.removeAll()
        lastCacheUpdate = nil
        todayCheckIn = nil
        currentStreak = nil
        logger.log("[CheckInService] Cache cleared", level: .info)
    }

    // MARK: - Private Helpers

    /// Create a JSON decoder configured for check-in data
    private func createCheckInDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try ISO8601 with fractional seconds first
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }

            // Try ISO8601 without fractional seconds
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }

            // Try DATE format (YYYY-MM-DD)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone.current
            if let date = dateFormatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string: \(dateString)"
            )
        }
        return decoder
    }

    /// Calculate streak from check-in history
    private func calculateStreak(from history: [DailyCheckIn]) -> CheckInStreak {
        guard !history.isEmpty else {
            return CheckInStreak()
        }

        let calendar = Calendar.current
        let sortedHistory = history.sorted { $0.date > $1.date }

        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0
        var expectedDate = calendar.startOfDay(for: Date())

        for checkIn in sortedHistory {
            let checkInDate = calendar.startOfDay(for: checkIn.date)

            if checkInDate == expectedDate {
                tempStreak += 1
                if tempStreak > longestStreak {
                    longestStreak = tempStreak
                }
                if currentStreak == 0 || checkInDate == calendar.date(byAdding: .day, value: -(currentStreak), to: calendar.startOfDay(for: Date())) {
                    currentStreak = tempStreak
                }
                expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
            } else if checkInDate < expectedDate {
                // Gap in streak
                tempStreak = 1
                expectedDate = calendar.date(byAdding: .day, value: -1, to: checkInDate) ?? checkInDate
            }
        }

        // Check if current streak is still valid (includes today or yesterday)
        if let lastCheckIn = sortedHistory.first {
            let lastDate = calendar.startOfDay(for: lastCheckIn.date)
            let today = calendar.startOfDay(for: Date())
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

            if lastDate != today && lastDate != yesterday {
                currentStreak = 0
            }
        }

        return CheckInStreak(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            lastCheckInDate: sortedHistory.first?.date,
            totalCheckIns: history.count
        )
    }
}

// MARK: - AnyEncodable Helper

/// Type-erased Encodable wrapper for dictionary values
private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init<T: Encodable>(_ wrapped: T?) {
        _encode = { encoder in
            var container = encoder.singleValueContainer()
            if let value = wrapped {
                try container.encode(value)
            } else {
                try container.encodeNil()
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
