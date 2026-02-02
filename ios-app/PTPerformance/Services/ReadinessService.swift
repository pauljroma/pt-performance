import Foundation
import Supabase
import SwiftUI

// MARK: - Encodable Structs for Supabase RPC

/// RPC parameters for calculating readiness score
private struct CalculateReadinessScoreParams: Encodable {
    let pPatientId: String
    let pDate: String

    enum CodingKeys: String, CodingKey {
        case pPatientId = "p_patient_id"
        case pDate = "p_date"
    }
}

/// RPC parameters for getting readiness trend
private struct GetReadinessTrendParams: Encodable {
    let pPatientId: String
    let pDays: String

    enum CodingKeys: String, CodingKey {
        case pPatientId = "p_patient_id"
        case pDays = "p_days"
    }
}

/// RPC parameters for upsert_daily_readiness function (BUILD 385)
private struct UpsertDailyReadinessParams: Encodable {
    let pPatientId: String
    let pDate: String
    let pSleepHours: Double?
    let pSorenessLevel: Int?
    let pEnergyLevel: Int?
    let pStressLevel: Int?
    let pNotes: String?

    enum CodingKeys: String, CodingKey {
        case pPatientId = "p_patient_id"
        case pDate = "p_date"
        case pSleepHours = "p_sleep_hours"
        case pSorenessLevel = "p_soreness_level"
        case pEnergyLevel = "p_energy_level"
        case pStressLevel = "p_stress_level"
        case pNotes = "p_notes"
    }
}

/// RPC parameters for get_daily_readiness function (BUILD 385)
private struct GetDailyReadinessParams: Encodable {
    let pPatientId: String
    let pDate: String

    enum CodingKeys: String, CodingKey {
        case pPatientId = "p_patient_id"
        case pDate = "p_date"
    }
}

/// Service for managing daily readiness data
/// Provides CRUD operations for daily readiness check-ins
/// Uses database functions for automatic score calculation
@MainActor
class ReadinessService: ObservableObject {
    nonisolated(unsafe) private let client: PTSupabaseClient
    @Published var isLoading: Bool = false
    @Published var error: Error?

    nonisolated init(client: PTSupabaseClient = .shared) {
        self.client = client
    }

    // MARK: - Submit Daily Readiness

    /// Submit or update daily readiness check-in
    /// Score is automatically calculated by database trigger
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - date: Date of check-in (defaults to today)
    ///   - sleepHours: Hours of sleep (0-24)
    ///   - sorenessLevel: Muscle soreness (1-10, 1=no soreness)
    ///   - energyLevel: Energy level (1-10, 1=exhausted)
    ///   - stressLevel: Stress level (1-10, 1=no stress)
    ///   - notes: Optional patient notes
    /// - Returns: Created/updated DailyReadiness record with calculated score
    func submitReadiness(
        patientId: UUID,
        date: Date = Date(),
        sleepHours: Double? = nil,
        sorenessLevel: Int? = nil,
        energyLevel: Int? = nil,
        stressLevel: Int? = nil,
        notes: String? = nil
    ) async throws -> DailyReadiness {
        isLoading = true
        defer { isLoading = false }

        // Create and validate input
        // Format date as YYYY-MM-DD for PostgreSQL DATE column
        // BUILD 137: Use local timezone for consistency with getTodayReadiness
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: date)

        let input = ReadinessInput(
            sleepHours: sleepHours,
            sorenessLevel: sorenessLevel,
            energyLevel: energyLevel,
            stressLevel: stressLevel,
            notes: notes,
            patientId: patientId.uuidString,
            date: dateString
        )

        try input.validate()

        do {
            // DEBUG: Log what we're sending
            print("📤 Submitting readiness for patient: \(patientId.uuidString), date: \(dateString)")
            print("📤 Input: sleep=\(sleepHours ?? 0), soreness=\(sorenessLevel ?? 0), energy=\(energyLevel ?? 0), stress=\(stressLevel ?? 0)")

            // BUILD 385: Use SECURITY DEFINER function to bypass RLS issues
            // This function runs with elevated privileges while keeping RLS enabled on the table
            let params = UpsertDailyReadinessParams(
                pPatientId: patientId.uuidString,
                pDate: dateString,
                pSleepHours: sleepHours,
                pSorenessLevel: sorenessLevel,
                pEnergyLevel: energyLevel,
                pStressLevel: stressLevel,
                pNotes: notes
            )

            let response = try await client.client
                .rpc("upsert_daily_readiness", params: params)
                .execute()

            // DEBUG: Log response
            print("📥 Response status: \(response.status)")
            if let rawJSON = String(data: response.data, encoding: .utf8) {
                print("📥 Response data: \(rawJSON.prefix(500))")
            }

            // Use custom decoder that handles both DATE and TIMESTAMP formats
            let decoder = createReadinessDecoder()
            let readiness = try decoder.decode(DailyReadiness.self, from: response.data)

            print("✅ Readiness saved successfully: score=\(readiness.readinessScore ?? 0)")
            return readiness
        } catch {
            print("❌ ReadinessService Error: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Error details: \(error.localizedDescription)")
            self.error = error
            throw error
        }
    }

    // MARK: - Fetch Readiness Factors

    /// Fetch active readiness factors (used for score calculation)
    /// - Returns: Array of active factors with weights
    func fetchReadinessFactors() async throws -> [ReadinessFactor] {
        do {
            let response = try await client.client
                .from("readiness_factors")
                .select()
                .eq("is_active", value: true)
                .order("weight", ascending: false)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([ReadinessFactor].self, from: response.data)
        } catch {
            self.error = error
            throw error
        }
    }

    // MARK: - Calculate Readiness Score

    /// Calculate readiness score using database function
    /// This calls the same calculation logic the trigger uses
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - date: Date to calculate score for
    /// - Returns: Calculated score (0-100)
    func calculateScore(
        for patientId: UUID,
        on date: Date = Date()
    ) async throws -> Double {
        do {
            let dateString = ISO8601DateFormatter().string(from: date)

            let params = CalculateReadinessScoreParams(
                pPatientId: patientId.uuidString,
                pDate: dateString
            )
            let response = try await client.client
                .rpc("calculate_readiness_score", params: params)
                .execute()

            // Decode as Double
            guard let scoreString = String(data: response.data, encoding: .utf8),
                  let score = Double(scoreString) else {
                throw ReadinessError.scoreCalculationFailed
            }

            return score
        } catch {
            self.error = error
            throw error
        }
    }

    // MARK: - Get Readiness Trend

    /// Get readiness trend data and statistics over N days
    /// Uses database function for efficient aggregation
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - days: Number of days to analyze (default 7)
    /// - Returns: Trend data with statistics
    func getReadinessTrend(
        for patientId: UUID,
        days: Int = 7
    ) async throws -> ReadinessTrend {
        do {
            let params = GetReadinessTrendParams(
                pPatientId: patientId.uuidString,
                pDays: String(days)
            )
            let response = try await client.client
                .rpc("get_readiness_trend", params: params)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(ReadinessTrend.self, from: response.data)
        } catch {
            self.error = error
            throw ReadinessError.trendCalculationFailed
        }
    }

    // MARK: - Get Today's Readiness

    /// Fetch today's readiness entry for a patient
    /// - Parameter patientId: Patient UUID
    /// - Returns: Today's readiness or nil if not found
    func getTodayReadiness(for patientId: UUID) async throws -> DailyReadiness? {
        // BUILD 137: Fix timezone - use local timezone instead of GMT for daily check-ins
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current  // Use device's local timezone
        let today = dateFormatter.string(from: Date())

        // DEBUG: Log the exact query being executed
        DebugLogger.shared.logDateConversion(
            original: Date(),
            formatted: today,
            formatter: "yyyy-MM-dd with local timezone (\(TimeZone.current.identifier))"
        )
        DebugLogger.shared.logQuery(
            table: "daily_readiness",
            query: "SELECT * WHERE patient_id = ? AND date = ?",
            params: [
                "patient_id": patientId.uuidString,
                "date": today
            ]
        )

        do {
            // BUILD 385: Use SECURITY DEFINER function to bypass RLS issues
            let params = GetDailyReadinessParams(
                pPatientId: patientId.uuidString,
                pDate: today
            )

            let response = try await client.client
                .rpc("get_daily_readiness", params: params)
                .execute()

            // DEBUG: Log response details
            let dataSize = response.data.count
            DebugLogger.shared.info("READINESS", "Response data size: \(dataSize) bytes")

            // Check if response has data (RPC returns null for no data)
            if let rawJSON = String(data: response.data, encoding: .utf8) {
                DebugLogger.shared.info("READINESS", "Raw response: \(rawJSON)")
                if rawJSON == "null" || rawJSON.isEmpty {
                    DebugLogger.shared.warning("READINESS", "No readiness found for date: \(today)")
                    return nil
                }
            }

            let decoder = createReadinessDecoder()

            // BUILD 385: RPC returns single object, not array
            do {
                let readiness = try decoder.decode(DailyReadiness.self, from: response.data)

                // DEBUG: Log successful fetch
                DebugLogger.shared.success("READINESS", """
                    Found readiness for \(today):
                    Score: \(readiness.readinessScore ?? 0)
                    Sleep: \(readiness.sleepHours ?? 0)h
                    Energy: \(readiness.energyLevel ?? 0)
                    Soreness: \(readiness.sorenessLevel ?? 0)
                    Stress: \(readiness.stressLevel ?? 0)
                    """)

                return readiness
            } catch let decodingError as DecodingError {
                // BUILD 133: Enhanced error logging to diagnose decoding failures
                let rawJSON = String(data: response.data, encoding: .utf8) ?? "Unable to decode as UTF-8"

                DebugLogger.shared.error("READINESS", """
                    DECODING ERROR - Raw JSON follows:
                    \(rawJSON)

                    Decoding error details:
                    \(decodingError)
                    """)

                // Log specific decoding error type
                switch decodingError {
                case .typeMismatch(let type, let context):
                    DebugLogger.shared.error("READINESS", """
                        Type Mismatch:
                        Expected type: \(type)
                        Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))
                        Debug description: \(context.debugDescription)
                        """)
                case .valueNotFound(let type, let context):
                    DebugLogger.shared.error("READINESS", """
                        Value Not Found:
                        Expected type: \(type)
                        Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))
                        Debug description: \(context.debugDescription)
                        """)
                case .keyNotFound(let key, let context):
                    DebugLogger.shared.error("READINESS", """
                        Key Not Found:
                        Missing key: \(key.stringValue)
                        Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))
                        Debug description: \(context.debugDescription)
                        """)
                case .dataCorrupted(let context):
                    DebugLogger.shared.error("READINESS", """
                        Data Corrupted:
                        Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))
                        Debug description: \(context.debugDescription)
                        """)
                @unknown default:
                    DebugLogger.shared.error("READINESS", "Unknown decoding error: \(decodingError)")
                }

                return nil
            }
        } catch {
            // DEBUG: Log other error types (network errors, etc.)
            DebugLogger.shared.error("READINESS", """
                Error fetching readiness:
                Error: \(error.localizedDescription)
                Type: \(type(of: error))
                Date queried: \(today)
                Patient: \(patientId.uuidString)
                """)
            // Return nil if not found (not an error condition)
            return nil
        }
    }

    // MARK: - Fetch Recent Readiness

    /// Fetch recent readiness entries for a patient
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - limit: Maximum number of records (default 7)
    /// - Returns: Array of readiness records, ordered by date descending
    func fetchRecentReadiness(
        for patientId: UUID,
        limit: Int = 7
    ) async throws -> [DailyReadiness] {
        do {
            let response = try await client.client
                .from("daily_readiness")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .order("date", ascending: false)
                .limit(limit)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([DailyReadiness].self, from: response.data)
        } catch {
            self.error = error
            throw error
        }
    }

    // MARK: - Fetch Readiness for Date Range

    /// Fetch readiness entries for a specific date range
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - startDate: Start of date range
    ///   - endDate: End of date range
    /// - Returns: Array of readiness records in range
    func fetchReadiness(
        for patientId: UUID,
        from startDate: Date,
        to endDate: Date
    ) async throws -> [DailyReadiness] {
        let startString = ISO8601DateFormatter().string(from: startDate)
        let endString = ISO8601DateFormatter().string(from: endDate)

        do {
            let response = try await client.client
                .from("daily_readiness")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .gte("date", value: startString)
                .lte("date", value: endString)
                .order("date", ascending: false)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([DailyReadiness].self, from: response.data)
        } catch {
            self.error = error
            throw error
        }
    }

    // MARK: - Delete Readiness Entry

    /// Delete a readiness entry
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - date: Date of entry to delete
    func deleteReadiness(
        for patientId: UUID,
        on date: Date
    ) async throws {
        isLoading = true
        defer { isLoading = false }

        let dateString = ISO8601DateFormatter().string(from: date)

        do {
            try await client.client
                .from("daily_readiness")
                .delete()
                .eq("patient_id", value: patientId.uuidString)
                .eq("date", value: dateString)
                .execute()
        } catch {
            self.error = error
            throw error
        }
    }

    // MARK: - Helper Methods

    /// Check if readiness has been logged for today
    /// - Parameter patientId: Patient UUID
    /// - Returns: True if today's entry exists
    func hasLoggedToday(patientId: UUID) async -> Bool {
        do {
            let todayEntry = try await getTodayReadiness(for: patientId)
            return todayEntry != nil
        } catch {
            return false
        }
    }

    /// Get readiness score interpretation
    /// - Parameter score: Readiness score (0-100)
    /// - Returns: ReadinessScore with level and recommendation
    func interpretScore(_ score: Double) -> ReadinessScore {
        return ReadinessScore(score: score)
    }

    /// Create a JSON decoder configured for daily readiness data
    /// Handles both DATE format (YYYY-MM-DD) and ISO8601 timestamps
    /// - Returns: Configured JSONDecoder
    private func createReadinessDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try ISO8601 with time first (for created_at, updated_at)
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

            // Try DATE format (YYYY-MM-DD) for the 'date' column
            // BUILD 137: Use local timezone for date decoding
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
}

// MARK: - Convenience Extensions

extension ReadinessService {
    /// Submit readiness with only the metrics that were collected
    /// Makes it easy to submit partial data
    func submitPartialReadiness(
        patientId: UUID,
        date: Date = Date(),
        metrics: [String: Any],
        notes: String? = nil
    ) async throws -> DailyReadiness {
        let sleepHours = metrics["sleep_hours"] as? Double
        let sorenessLevel = metrics["soreness_level"] as? Int
        let energyLevel = metrics["energy_level"] as? Int
        let stressLevel = metrics["stress_level"] as? Int

        return try await submitReadiness(
            patientId: patientId,
            date: date,
            sleepHours: sleepHours,
            sorenessLevel: sorenessLevel,
            energyLevel: energyLevel,
            stressLevel: stressLevel,
            notes: notes
        )
    }

    /// Get comprehensive readiness summary for a patient
    /// Includes today's entry, recent history, and 7-day trend
    func getReadinessSummary(for patientId: UUID) async throws -> ReadinessSummary {
        async let todayEntry = getTodayReadiness(for: patientId)
        async let recentEntries = fetchRecentReadiness(for: patientId, limit: 7)
        async let trend = getReadinessTrend(for: patientId, days: 7)

        return try await ReadinessSummary(
            today: todayEntry,
            recent: recentEntries,
            trend: trend
        )
    }
}

/// Comprehensive readiness summary
struct ReadinessSummary {
    let today: DailyReadiness?
    let recent: [DailyReadiness]
    let trend: ReadinessTrend

    var hasLoggedToday: Bool {
        today != nil
    }

    var currentScore: Double? {
        today?.readinessScore
    }

    var averageScore: Double? {
        trend.statistics.avgReadiness
    }

    var scoreChange: Double? {
        guard let current = currentScore,
              let average = averageScore else {
            return nil
        }
        return current - average
    }
}

// MARK: - BUILD 351: ReadinessService Extension for Daily Check-in

/// Thresholds for determining readiness band from calculated score
private enum ReadinessThreshold {
    /// High readiness - green band (80+)
    static let high = 80.0
    /// Moderate readiness - yellow band (60+)
    static let moderate = 60.0
    /// Poor readiness - orange band (40+)
    static let poor = 40.0
    // Below poor threshold = red band
}

extension ReadinessService {
    /// Calculate readiness band from WHOOP-style input
    /// Uses algorithm from Auto-Regulation System (Build 39)
    /// - Parameter input: BandCalculationInput with sleep, soreness, and subjective data
    /// - Returns: Tuple of (ReadinessBand, Optional score)
    nonisolated func calculateReadinessBand(input: BandCalculationInput) -> (ReadinessBand, Double?) {
        // Calculate weighted score (0-100)
        var score: Double = 50.0 // Default baseline

        // Sleep component (30% weight)
        if let sleepHours = input.sleepHours {
            // Optimal is 7-9 hours, scale accordingly
            let sleepScore: Double
            if sleepHours >= 7 && sleepHours <= 9 {
                sleepScore = 100.0
            } else if sleepHours >= 6 && sleepHours < 7 {
                sleepScore = 70.0
            } else if sleepHours >= 5 && sleepHours < 6 {
                sleepScore = 50.0
            } else if sleepHours > 9 && sleepHours <= 10 {
                sleepScore = 90.0
            } else {
                sleepScore = 30.0
            }
            score = score * 0.7 + sleepScore * 0.3
        }

        // Sleep quality component (20% weight)
        if let sleepQuality = input.sleepQuality {
            let qualityScore = Double(sleepQuality) / 5.0 * 100.0
            score = score * 0.8 + qualityScore * 0.2
        }

        // Subjective readiness component (25% weight)
        if let subjective = input.subjectiveReadiness {
            let subjectiveScore = Double(subjective) / 5.0 * 100.0
            score = score * 0.75 + subjectiveScore * 0.25
        }

        // HRV component (15% weight) - if available
        if let hrv = input.hrvValue {
            // HRV > 60 is good, < 40 is concerning
            let hrvScore = min(100.0, max(0.0, (hrv - 20) / 60 * 100))
            score = score * 0.85 + hrvScore * 0.15
        }

        // WHOOP recovery (25% weight) - if available, use instead of calculated score
        if let whoopRecovery = input.whoopRecoveryPct {
            score = score * 0.75 + Double(whoopRecovery) * 0.25
        }

        // Pain penalties
        if input.armSoreness {
            if let severity = input.armSorenessSeverity {
                // Severe = 3, Moderate = 2, Mild = 1
                let penalty = Double(severity) * 10.0
                score = max(0, score - penalty)
            } else {
                score = max(0, score - 10)
            }
        }

        // Joint pain penalty (5 points per joint)
        let jointPenalty = Double(input.jointPain.count) * 5.0
        score = max(0, score - jointPenalty)

        // Clamp to 0-100
        score = min(100, max(0, score))

        // Determine band
        let band: ReadinessBand
        if score >= ReadinessThreshold.high {
            band = .green
        } else if score >= ReadinessThreshold.moderate {
            band = .yellow
        } else if score >= ReadinessThreshold.poor {
            band = .orange
        } else {
            band = .red
        }

        return (band, score)
    }

    /// Submit daily readiness using WHOOP-style input
    /// Converts to database format and saves
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - input: BandCalculationInput with all readiness data
    /// - Returns: Created DailyReadiness record
    func submitDailyReadiness(
        patientId: UUID,
        input: BandCalculationInput
    ) async throws -> DailyReadiness {
        // Calculate the readiness band/score
        let (_, _) = calculateReadinessBand(input: input)

        // Map WHOOP-style input to database format
        // Convert subjective readiness (1-5) to energy level (1-10)
        let energyLevel: Int? = input.subjectiveReadiness.map { $0 * 2 }

        // Convert arm soreness to soreness level (1-10)
        let sorenessLevel: Int?
        if input.armSoreness {
            sorenessLevel = (input.armSorenessSeverity ?? 1) * 3 + 1 // Maps 1-3 to 4,7,10
        } else if !input.jointPain.isEmpty {
            sorenessLevel = input.jointPain.count * 2 + 1 // Some soreness from joints
        } else {
            sorenessLevel = 1 // No soreness
        }

        // Build notes from joint pain locations
        var notes = input.jointPainNotes ?? ""
        if !input.jointPain.isEmpty {
            let jointList = input.jointPain.map { $0.displayName }.joined(separator: ", ")
            if notes.isEmpty {
                notes = "Joint pain: \(jointList)"
            } else {
                notes += " | Joint pain: \(jointList)"
            }
        }

        // Call existing submitReadiness method
        return try await submitReadiness(
            patientId: patientId,
            date: Date(),
            sleepHours: input.sleepHours,
            sorenessLevel: sorenessLevel,
            energyLevel: energyLevel,
            stressLevel: nil, // Not captured in WHOOP-style input
            notes: notes.isEmpty ? nil : notes
        )
    }
}
