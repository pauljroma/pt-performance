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

/// RPC parameters for upsert_daily_readiness function
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

/// RPC parameters for get_daily_readiness function
private struct GetDailyReadinessParams: Encodable {
    let pPatientId: String
    let pDate: String

    enum CodingKeys: String, CodingKey {
        case pPatientId = "p_patient_id"
        case pDate = "p_date"
    }
}

/// Service for managing daily readiness check-ins and score calculations.
///
/// Readiness is a daily subjective assessment that helps auto-regulate training intensity.
/// The service handles:
/// - Daily check-in submission and retrieval
/// - Automatic score calculation via database triggers
/// - Historical trend analysis
/// - WHOOP-style band calculation for training recommendations
///
/// ## Score Calculation
/// Readiness scores (0-100) are calculated from:
/// - Sleep hours and quality
/// - Soreness levels
/// - Energy levels
/// - Stress levels
///
/// ## Thread Safety
/// This service is `@MainActor` isolated for UI updates via `@Published` properties.
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
        // Use local timezone for consistency with getTodayReadiness
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
            #if DEBUG
            // Debug: Log what we're sending
            DebugLogger.shared.log("Submitting readiness for patient: \(patientId.uuidString), date: \(dateString)", level: .diagnostic)
            DebugLogger.shared.log("Input: sleep=\(sleepHours ?? 0), soreness=\(sorenessLevel ?? 0), energy=\(energyLevel ?? 0), stress=\(stressLevel ?? 0)", level: .diagnostic)
            #endif

            // Use SECURITY DEFINER function to bypass RLS issues
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

            #if DEBUG
            // Debug: Log response
            DebugLogger.shared.log("Response status: \(response.status)", level: .diagnostic)
            if let rawJSON = String(data: response.data, encoding: .utf8) {
                DebugLogger.shared.log("Response data: \(rawJSON.prefix(500))", level: .diagnostic)
            }
            #endif

            // Use custom decoder that handles both DATE and TIMESTAMP formats
            let decoder = createReadinessDecoder()
            let readiness = try decoder.decode(DailyReadiness.self, from: response.data)

            DebugLogger.shared.log("Readiness saved successfully: score=\(readiness.readinessScore ?? 0)", level: .success)
            return readiness
        } catch {
            ErrorLogger.shared.logError(error, context: "ReadinessService.submitReadiness", metadata: ["patient_id": patientId.uuidString, "date": dateString])
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
        // Use local timezone instead of GMT for daily check-ins
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

        // Use SECURITY DEFINER function to bypass RLS issues
        let params = GetDailyReadinessParams(
            pPatientId: patientId.uuidString,
            pDate: today
        )

        let responseData: Data
        do {
            let response = try await client.client
                .rpc("get_daily_readiness", params: params)
                .execute()
            responseData = response.data
        } catch {
            // Network or RPC execution error - this is a real failure, throw it
            DebugLogger.shared.error("READINESS", """
                Error fetching readiness:
                Error: \(error.localizedDescription)
                Type: \(type(of: error))
                Date queried: \(today)
                Patient: \(patientId.uuidString)
                """)
            self.error = error
            throw ReadinessError.fetchFailed(error)
        }

        // DEBUG: Log response details
        let dataSize = responseData.count
        DebugLogger.shared.info("READINESS", "Response data size: \(dataSize) bytes")

        // Check if response has data (RPC returns null for no data)
        if let rawJSON = String(data: responseData, encoding: .utf8) {
            DebugLogger.shared.info("READINESS", "Raw response: \(rawJSON)")
            if rawJSON == "null" || rawJSON.isEmpty {
                // No data is normal — not every user does a readiness check every day.
                DebugLogger.shared.logOnce(key: "readiness_no_data_\(today)", "[READINESS] No readiness found for date: \(today)", level: .diagnostic)
                return nil  // No data - this is expected for users who haven't checked in
            }
        }

        let decoder = createReadinessDecoder()

        // RPC returns single object, not array
        do {
            let readiness = try decoder.decode(DailyReadiness.self, from: responseData)

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
            // Enhanced error logging to diagnose decoding failures
            let rawJSON = String(data: responseData, encoding: .utf8) ?? "Unable to decode as UTF-8"

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

            // Decoding error is a real failure, throw it
            self.error = decodingError
            throw ReadinessError.fetchFailed(decodingError)
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

    /// Fetch readiness history for a patient (alias for fetchRecentReadiness)
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - days: Number of days to fetch (default 30)
    /// - Returns: Array of readiness records
    func getReadinessHistory(for patientId: UUID, days: Int = 30) async throws -> [DailyReadiness] {
        return try await fetchRecentReadiness(for: patientId, limit: days)
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
    /// - Throws: ReadinessError.fetchFailed if unable to check (network error, etc.)
    func hasLoggedToday(patientId: UUID) async throws -> Bool {
        let todayEntry = try await getTodayReadiness(for: patientId)
        return todayEntry != nil
    }

    /// Check if readiness has been logged for today, with fallback to false on errors.
    ///
    /// Use this variant when you want to gracefully handle errors
    /// (e.g., background checks where UI feedback is not needed).
    ///
    /// - Parameter patientId: Patient UUID
    /// - Returns: True if today's entry exists, false if no entry or on error
    func hasLoggedTodayWithFallback(patientId: UUID) async -> Bool {
        do {
            return try await hasLoggedToday(patientId: patientId)
        } catch {
            DebugLogger.shared.warning("READINESS", "hasLoggedToday failed, returning false: \(error.localizedDescription)")
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
            // Use local timezone for date decoding
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

    /// Fetch a comprehensive readiness summary for dashboard display.
    ///
    /// Performs three concurrent fetches for optimal performance:
    /// - Today's readiness entry
    /// - Last 7 days of entries
    /// - 7-day trend statistics
    ///
    /// - Parameter patientId: The patient's UUID
    /// - Returns: ReadinessSummary containing today's data, recent history, and trends
    /// - Throws: Database errors if any of the fetches fail
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

/// Historical readiness comparison data
struct HistoricalComparison {
    let weekAverage: Double
    let monthAverage: Double
    let best: Double
}

// MARK: - ReadinessService Extension for Daily Check-in

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
    /// Calculate a readiness band (green/yellow/orange/red) from WHOOP-style input.
    ///
    /// This is a pure function that can be called synchronously for immediate UI feedback.
    /// The algorithm weights factors as follows:
    /// - Sleep hours: 30%
    /// - Sleep quality: 20%
    /// - Subjective readiness: 25%
    /// - HRV (if available): 15%
    /// - WHOOP recovery (if available): 25%
    ///
    /// Penalties are applied for:
    /// - Arm soreness: 10-30 points based on severity
    /// - Joint pain: 5 points per affected joint
    ///
    /// - Parameter input: BandCalculationInput containing all readiness metrics
    /// - Returns: Tuple of (readiness band color, calculated score 0-100)
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

// MARK: - Recovery Intelligence: HealthKit Integration

/// Composite readiness score combining subjective and objective data
struct CompositeReadinessScore: Sendable {
    let overallScore: Double              // 0-100
    let hrvScore: Double?                 // HRV component (0-100)
    let sleepScore: Double?               // Sleep component (0-100)
    let restingHRScore: Double?           // Resting HR component (0-100)
    let subjectiveScore: Double?          // Subjective check-in component (0-100)
    let readinessBand: ReadinessBand
    let breakdown: ReadinessBreakdown
    let confidence: ReadinessConfidence   // How confident we are in the score

    /// Breakdown of individual components
    struct ReadinessBreakdown: Sendable {
        let hrvValue: Double?
        let hrvBaseline: Double?
        let hrvDeviation: Double?         // Percentage deviation from baseline
        let sleepHours: Double?
        let sleepEfficiency: Double?
        let restingHR: Double?
        let restingHRBaseline: Double?
        let energyLevel: Int?
        let sorenessLevel: Int?
        let stressLevel: Int?
    }

    /// Confidence level based on data availability
    enum ReadinessConfidence: String, Sendable {
        case high = "high"       // All data sources available
        case medium = "medium"   // Some objective data available
        case low = "low"         // Only subjective data

        var description: String {
            switch self {
            case .high: return "Based on HRV, sleep, and check-in data"
            case .medium: return "Based on partial health data"
            case .low: return "Based on check-in data only"
            }
        }
    }
}

/// Predictive readiness forecast
struct ReadinessForecast: Sendable {
    let date: Date
    let predictedScore: Double
    let confidence: Double           // 0-1, decreases with distance
    let factors: [ForecastFactor]

    struct ForecastFactor: Sendable {
        let name: String
        let impact: Double           // Positive or negative impact
        let description: String
    }
}

/// Historical readiness analysis
struct ReadinessAnalysis: Sendable {
    let averageScore: Double
    let trend: ReadinessTrendDirection
    let volatility: Double           // Standard deviation
    let bestDay: DayOfWeek?
    let worstDay: DayOfWeek?
    let correlations: [CorrelationInsight]
    let patterns: [ReadinessPattern]

    enum ReadinessTrendDirection: String, Sendable {
        case improving = "improving"
        case stable = "stable"
        case declining = "declining"
    }

    enum DayOfWeek: Int, Sendable, CaseIterable {
        case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

        var name: String {
            switch self {
            case .sunday: return "Sunday"
            case .monday: return "Monday"
            case .tuesday: return "Tuesday"
            case .wednesday: return "Wednesday"
            case .thursday: return "Thursday"
            case .friday: return "Friday"
            case .saturday: return "Saturday"
            }
        }
    }

    struct CorrelationInsight: Sendable {
        let factor: String           // e.g., "sleep", "training_volume"
        let correlation: Double      // -1 to 1
        let description: String
    }

    struct ReadinessPattern: Sendable {
        let name: String
        let description: String
        let recommendation: String
    }
}

extension ReadinessService {

    // MARK: - Composite Readiness Score

    /// Calculate a composite readiness score combining HealthKit data with subjective check-in
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - healthKitService: HealthKit service for objective data
    /// - Returns: CompositeReadinessScore with breakdown and confidence level
    func calculateCompositeReadiness(
        for patientId: UUID,
        using healthKitService: HealthKitService
    ) async throws -> CompositeReadinessScore {
        // Fetch all data sources concurrently
        async let subjectiveData = getTodayReadiness(for: patientId)
        async let hrvData = healthKitService.fetchHRV(for: Date())
        async let hrvBaseline = healthKitService.getHRVBaseline(days: 7)
        async let sleepData = healthKitService.fetchSleepData(for: Date())
        async let restingHR = healthKitService.fetchRestingHeartRate(for: Date())

        // Await all results
        let subjective = try? await subjectiveData
        let hrv = try? await hrvData
        let baseline = try? await hrvBaseline
        let sleep = try? await sleepData
        let rhr = try? await restingHR

        // Calculate individual component scores
        var hrvScore: Double?
        var hrvDeviation: Double?
        if let hrv = hrv, let baseline = baseline, baseline > 0 {
            hrvDeviation = ((hrv - baseline) / baseline) * 100
            // HRV score: 100 at +20% above baseline, 50 at baseline, 0 at -40% below
            hrvScore = min(100, max(0, 50 + (hrvDeviation ?? 0) * 2.5))
        }

        var sleepScore: Double?
        if let sleep = sleep {
            // Optimal sleep: 7-9 hours = 100, <5 or >10 hours = lower
            let hours = sleep.totalHours
            if hours >= 7 && hours <= 9 {
                sleepScore = 100
            } else if hours >= 6 {
                sleepScore = 70 + (hours - 6) * 30
            } else if hours >= 5 {
                sleepScore = 50 + (hours - 5) * 20
            } else {
                sleepScore = max(0, hours * 10)
            }
            // Factor in sleep efficiency
            let efficiency = sleep.sleepEfficiency
            sleepScore = sleepScore.map { $0 * (0.5 + efficiency / 200) }
        }

        var rhrScore: Double?
        // RHR score: lower is better, assuming baseline around 60
        if let rhr = rhr {
            if rhr <= 50 {
                rhrScore = 100
            } else if rhr <= 60 {
                rhrScore = 90 - (rhr - 50)
            } else if rhr <= 70 {
                rhrScore = 80 - (rhr - 60) * 2
            } else {
                rhrScore = max(0, 60 - (rhr - 70) * 3)
            }
        }

        var subjectiveScore: Double?
        if let subjective = subjective, let score = subjective.readinessScore {
            subjectiveScore = score
        }

        // Calculate overall score with weighted components
        var totalWeight: Double = 0
        var weightedScore: Double = 0

        // HRV: 30% weight when available
        if let hrvScore = hrvScore {
            weightedScore += hrvScore * 0.30
            totalWeight += 0.30
        }

        // Sleep: 25% weight when available
        if let sleepScore = sleepScore {
            weightedScore += sleepScore * 0.25
            totalWeight += 0.25
        }

        // Resting HR: 15% weight when available
        if let rhrScore = rhrScore {
            weightedScore += rhrScore * 0.15
            totalWeight += 0.15
        }

        // Subjective: 30% base weight, increases if other data missing
        if let subjectiveScore = subjectiveScore {
            let subjectiveWeight = totalWeight > 0 ? 0.30 : 1.0
            weightedScore += subjectiveScore * subjectiveWeight
            totalWeight += subjectiveWeight
        }

        // Normalize score
        let overallScore = totalWeight > 0 ? weightedScore / totalWeight : 50.0

        // Determine confidence level
        let confidence: CompositeReadinessScore.ReadinessConfidence
        if hrvScore != nil && sleepScore != nil && subjectiveScore != nil {
            confidence = .high
        } else if hrvScore != nil || sleepScore != nil {
            confidence = .medium
        } else {
            confidence = .low
        }

        // Determine readiness band
        let band: ReadinessBand
        if overallScore >= 80 {
            band = .green
        } else if overallScore >= 60 {
            band = .yellow
        } else if overallScore >= 40 {
            band = .orange
        } else {
            band = .red
        }

        let breakdown = CompositeReadinessScore.ReadinessBreakdown(
            hrvValue: hrv,
            hrvBaseline: baseline,
            hrvDeviation: hrvDeviation,
            sleepHours: sleep?.totalHours,
            sleepEfficiency: sleep?.sleepEfficiency,
            restingHR: rhr,
            restingHRBaseline: nil, // Could add RHR baseline calculation
            energyLevel: subjective?.energyLevel,
            sorenessLevel: subjective?.sorenessLevel,
            stressLevel: subjective?.stressLevel
        )

        return CompositeReadinessScore(
            overallScore: overallScore,
            hrvScore: hrvScore,
            sleepScore: sleepScore,
            restingHRScore: rhrScore,
            subjectiveScore: subjectiveScore,
            readinessBand: band,
            breakdown: breakdown,
            confidence: confidence
        )
    }

    // MARK: - Predictive Readiness

    /// Forecast readiness scores for the next 3 days
    /// Uses historical patterns and current trends
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - healthKitService: HealthKit service for current data
    /// - Returns: Array of ReadinessForecast for next 3 days
    func predictReadiness(
        for patientId: UUID,
        using healthKitService: HealthKitService
    ) async throws -> [ReadinessForecast] {
        // Fetch historical data (last 14 days)
        let calendar = Calendar.current
        let today = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -14, to: today) else {
            return []
        }

        let historicalData = try await fetchReadiness(for: patientId, from: startDate, to: today)

        // Calculate averages and trends
        let scores = historicalData.compactMap { $0.readinessScore }
        guard !scores.isEmpty else {
            // No historical data, return baseline forecasts
            return (1...3).compactMap { days in
                guard let forecastDate = calendar.date(byAdding: .day, value: days, to: today) else { return nil }
                return ReadinessForecast(
                    date: forecastDate,
                    predictedScore: 65.0,  // Default moderate readiness
                    confidence: 0.3,
                    factors: [
                        ReadinessForecast.ForecastFactor(
                            name: "Limited Data",
                            impact: 0,
                            description: "Not enough historical data for accurate prediction"
                        )
                    ]
                )
            }
        }

        let avgScore = scores.reduce(0, +) / Double(scores.count)

        // Calculate recent trend (last 7 days vs previous 7 days)
        let recentScores = Array(scores.prefix(7))
        let olderScores = Array(scores.dropFirst(7))

        let recentAvg = recentScores.isEmpty ? avgScore : recentScores.reduce(0, +) / Double(recentScores.count)
        let olderAvg = olderScores.isEmpty ? avgScore : olderScores.reduce(0, +) / Double(olderScores.count)
        let trendDirection = recentAvg - olderAvg

        // Get day-of-week patterns
        var dayOfWeekScores: [Int: [Double]] = [:]
        for entry in historicalData {
            let weekday = calendar.component(.weekday, from: entry.date)
            if let score = entry.readinessScore {
                dayOfWeekScores[weekday, default: []].append(score)
            }
        }

        // Generate forecasts
        var forecasts: [ReadinessForecast] = []

        for daysAhead in 1...3 {
            guard let forecastDate = calendar.date(byAdding: .day, value: daysAhead, to: today) else {
                continue
            }

            let weekday = calendar.component(.weekday, from: forecastDate)

            // Base prediction on average + trend + day-of-week adjustment
            var prediction = avgScore

            // Apply trend (diminishing with distance)
            let trendFactor = trendDirection * (0.3 / Double(daysAhead))
            prediction += trendFactor

            // Apply day-of-week adjustment
            var factors: [ReadinessForecast.ForecastFactor] = []

            if let dowScores = dayOfWeekScores[weekday], !dowScores.isEmpty {
                let dowAvg = dowScores.reduce(0, +) / Double(dowScores.count)
                let dowAdjustment = (dowAvg - avgScore) * 0.3
                prediction += dowAdjustment

                if abs(dowAdjustment) > 3 {
                    let dayName = ReadinessAnalysis.DayOfWeek(rawValue: weekday)?.name ?? "This day"
                    factors.append(ReadinessForecast.ForecastFactor(
                        name: "Day Pattern",
                        impact: dowAdjustment,
                        description: dowAdjustment > 0
                            ? "\(dayName)s tend to be better recovery days for you"
                            : "\(dayName)s are typically lower readiness days"
                    ))
                }
            }

            // Add trend factor
            if abs(trendDirection) > 2 {
                factors.append(ReadinessForecast.ForecastFactor(
                    name: "Recent Trend",
                    impact: trendFactor,
                    description: trendDirection > 0
                        ? "Your readiness has been improving recently"
                        : "Your readiness has been declining - consider extra rest"
                ))
            }

            // Confidence decreases with distance
            let confidence = max(0.3, 0.8 - Double(daysAhead - 1) * 0.2)

            // Clamp prediction
            prediction = min(100, max(0, prediction))

            forecasts.append(ReadinessForecast(
                date: forecastDate,
                predictedScore: prediction,
                confidence: confidence,
                factors: factors
            ))
        }

        return forecasts
    }

    // MARK: - Historical Analysis

    /// Analyze historical readiness patterns and correlations
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - days: Number of days to analyze (default 30)
    /// - Returns: ReadinessAnalysis with trends, patterns, and correlations
    func analyzeReadinessHistory(
        for patientId: UUID,
        days: Int = 30
    ) async throws -> ReadinessAnalysis {
        let calendar = Calendar.current
        let today = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: today) else {
            throw ReadinessError.noDataFound
        }

        let data = try await fetchReadiness(for: patientId, from: startDate, to: today)

        guard !data.isEmpty else {
            throw ReadinessError.noDataFound
        }

        let scores = data.compactMap { $0.readinessScore }

        // Calculate average
        let avgScore = scores.reduce(0, +) / Double(scores.count)

        // Calculate standard deviation (volatility)
        let variance = scores.map { pow($0 - avgScore, 2) }.reduce(0, +) / Double(scores.count)
        let volatility = sqrt(variance)

        // Determine trend direction
        let midpoint = data.count / 2
        let recentScores = data.prefix(midpoint).compactMap { $0.readinessScore }
        let olderScores = data.suffix(midpoint).compactMap { $0.readinessScore }

        let recentAvg = recentScores.isEmpty ? avgScore : recentScores.reduce(0, +) / Double(recentScores.count)
        let olderAvg = olderScores.isEmpty ? avgScore : olderScores.reduce(0, +) / Double(olderScores.count)

        let trend: ReadinessAnalysis.ReadinessTrendDirection
        if recentAvg - olderAvg > 5 {
            trend = .improving
        } else if olderAvg - recentAvg > 5 {
            trend = .declining
        } else {
            trend = .stable
        }

        // Analyze day-of-week patterns
        var dayScores: [Int: [Double]] = [:]
        for entry in data {
            let weekday = calendar.component(.weekday, from: entry.date)
            if let score = entry.readinessScore {
                dayScores[weekday, default: []].append(score)
            }
        }

        var dayAverages: [(ReadinessAnalysis.DayOfWeek, Double)] = []
        for (weekday, scores) in dayScores where !scores.isEmpty {
            if let day = ReadinessAnalysis.DayOfWeek(rawValue: weekday) {
                let avg = scores.reduce(0, +) / Double(scores.count)
                dayAverages.append((day, avg))
            }
        }

        let bestDay = dayAverages.max(by: { $0.1 < $1.1 })?.0
        let worstDay = dayAverages.min(by: { $0.1 < $1.1 })?.0

        // Analyze correlations
        var correlations: [ReadinessAnalysis.CorrelationInsight] = []

        // Sleep correlation
        let sleepEntries = data.filter { $0.sleepHours != nil && $0.readinessScore != nil }
        if sleepEntries.count >= 5 {
            let sleepCorr = calculateCorrelation(
                x: sleepEntries.compactMap { $0.sleepHours },
                y: sleepEntries.compactMap { $0.readinessScore }
            )
            if let corr = sleepCorr {
                correlations.append(ReadinessAnalysis.CorrelationInsight(
                    factor: "Sleep",
                    correlation: corr,
                    description: corr > 0.5
                        ? "Sleep duration strongly affects your readiness"
                        : corr > 0.2
                            ? "Sleep has a moderate impact on your readiness"
                            : "Sleep duration has minimal impact on your readiness"
                ))
            }
        }

        // Soreness correlation (inverted - higher soreness = lower readiness expected)
        let sorenessEntries = data.filter { $0.sorenessLevel != nil && $0.readinessScore != nil }
        if sorenessEntries.count >= 5 {
            let sorenessCorr = calculateCorrelation(
                x: sorenessEntries.compactMap { $0.sorenessLevel.map { Double($0) } },
                y: sorenessEntries.compactMap { $0.readinessScore }
            )
            if let corr = sorenessCorr {
                correlations.append(ReadinessAnalysis.CorrelationInsight(
                    factor: "Soreness",
                    correlation: corr,
                    description: corr < -0.3
                        ? "Muscle soreness significantly impacts your readiness"
                        : "Your soreness levels don't strongly affect readiness"
                ))
            }
        }

        // Detect patterns
        var patterns: [ReadinessAnalysis.ReadinessPattern] = []

        // High volatility pattern
        if volatility > 15 {
            patterns.append(ReadinessAnalysis.ReadinessPattern(
                name: "High Variability",
                description: "Your readiness scores vary significantly day to day",
                recommendation: "Try to maintain more consistent sleep and recovery habits"
            ))
        }

        // Weekend vs weekday pattern
        let weekendScores = data.filter {
            let wd = calendar.component(.weekday, from: $0.date)
            return wd == 1 || wd == 7
        }.compactMap { $0.readinessScore }

        let weekdayScores = data.filter {
            let wd = calendar.component(.weekday, from: $0.date)
            return wd >= 2 && wd <= 6
        }.compactMap { $0.readinessScore }

        if !weekendScores.isEmpty && !weekdayScores.isEmpty {
            let weekendAvg = weekendScores.reduce(0, +) / Double(weekendScores.count)
            let weekdayAvg = weekdayScores.reduce(0, +) / Double(weekdayScores.count)

            if weekendAvg - weekdayAvg > 10 {
                patterns.append(ReadinessAnalysis.ReadinessPattern(
                    name: "Weekend Recovery",
                    description: "You recover better on weekends than weekdays",
                    recommendation: "Consider scheduling harder workouts on weekends when you're more recovered"
                ))
            } else if weekdayAvg - weekendAvg > 10 {
                patterns.append(ReadinessAnalysis.ReadinessPattern(
                    name: "Weekday Strength",
                    description: "Your readiness is better on weekdays",
                    recommendation: "Plan key training sessions during the week"
                ))
            }
        }

        // Consecutive low days pattern
        var consecutiveLow = 0
        var maxConsecutiveLow = 0
        for entry in data.sorted(by: { $0.date < $1.date }) {
            if let score = entry.readinessScore, score < 50 {
                consecutiveLow += 1
                maxConsecutiveLow = max(maxConsecutiveLow, consecutiveLow)
            } else {
                consecutiveLow = 0
            }
        }

        if maxConsecutiveLow >= 3 {
            patterns.append(ReadinessAnalysis.ReadinessPattern(
                name: "Extended Fatigue",
                description: "You've had \(maxConsecutiveLow) consecutive days of low readiness",
                recommendation: "Consider a deload week or extra rest days to recover"
            ))
        }

        return ReadinessAnalysis(
            averageScore: avgScore,
            trend: trend,
            volatility: volatility,
            bestDay: bestDay,
            worstDay: worstDay,
            correlations: correlations,
            patterns: patterns
        )
    }

    // MARK: - Helper Methods

    /// Calculate Pearson correlation coefficient between two arrays
    private func calculateCorrelation(x: [Double], y: [Double]) -> Double? {
        guard x.count == y.count && x.count >= 3 else { return nil }

        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        let sumY2 = y.map { $0 * $0 }.reduce(0, +)

        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))

        guard denominator > 0 else { return nil }
        return numerator / denominator
    }
}
