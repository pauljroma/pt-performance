import Foundation

/// Service for integrating with WHOOP API
/// Part of Build 40 (Optional) - WHOOP Integration for Auto-Regulation System
/// Provides OAuth 2.0 authentication and fetches recovery/sleep data
class WHOOPService {
    private let clientId: String
    private let clientSecret: String
    private let redirectUri: String = "ptperformance://whoop-callback"

    private let baseURL = "https://api.whoop.com/v1"

    init(clientId: String, clientSecret: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
    }

    // MARK: - OAuth 2.0 Flow

    /// Generate WHOOP OAuth authorization URL
    /// Required scopes: read:recovery, read:sleep, read:cycles
    /// - Returns: Authorization URL for user to authenticate with WHOOP
    func getAuthorizationURL() -> URL? {
        var components = URLComponents(string: "https://api.whoop.com/oauth/authorize")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "read:recovery read:sleep read:cycles")
        ]
        return components?.url
    }

    /// Exchange authorization code for access token
    /// - Parameter code: Authorization code from OAuth callback
    /// - Returns: WHOOPAccessToken containing access token, refresh token, and expiry
    func exchangeCodeForToken(code: String) async throws -> WHOOPAccessToken {
        let url = URL(string: "https://api.whoop.com/oauth/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "grant_type=authorization_code&code=\(code)&client_id=\(clientId)&client_secret=\(clientSecret)&redirect_uri=\(redirectUri)"
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw WHOOPError.authenticationFailed
        }

        return try JSONDecoder().decode(WHOOPAccessToken.self, from: data)
    }

    /// Refresh an expired access token using refresh token
    /// - Parameter refreshToken: The refresh token from previous authentication
    /// - Returns: New WHOOPAccessToken with updated credentials
    func refreshAccessToken(refreshToken: String) async throws -> WHOOPAccessToken {
        let url = URL(string: "https://api.whoop.com/oauth/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "grant_type=refresh_token&refresh_token=\(refreshToken)&client_id=\(clientId)&client_secret=\(clientSecret)"
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw WHOOPError.authenticationFailed
        }

        return try JSONDecoder().decode(WHOOPAccessToken.self, from: data)
    }

    // MARK: - Data Fetching

    /// Fetch today's most recent recovery data
    /// Includes recovery score, HRV, RHR, and other recovery metrics
    /// - Parameter accessToken: Valid WHOOP access token
    /// - Returns: WHOOPRecovery with latest recovery data
    func fetchTodayRecovery(accessToken: String) async throws -> WHOOPRecovery {
        let url = URL(string: "\(baseURL)/recovery")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WHOOPError.apiError("Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            throw WHOOPError.apiError("HTTP \(httpResponse.statusCode)")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let recoveryResponse = try decoder.decode(WHOOPRecoveryResponse.self, from: data)

        // Return most recent recovery
        guard let latest = recoveryResponse.records.first else {
            throw WHOOPError.noDataAvailable
        }

        return latest
    }

    /// Fetch today's most recent sleep data
    /// Includes sleep performance, quality duration, and sleep stages
    /// - Parameter accessToken: Valid WHOOP access token
    /// - Returns: WHOOPSleep with latest sleep data
    func fetchTodaySleep(accessToken: String) async throws -> WHOOPSleep {
        let url = URL(string: "\(baseURL)/sleep")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WHOOPError.apiError("Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            throw WHOOPError.apiError("HTTP \(httpResponse.statusCode)")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let sleepResponse = try decoder.decode(WHOOPSleepResponse.self, from: data)

        guard let latest = sleepResponse.records.first else {
            throw WHOOPError.noDataAvailable
        }

        return latest
    }
}

// MARK: - Models

/// WHOOP OAuth access token
struct WHOOPAccessToken: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

/// WHOOP recovery data
struct WHOOPRecovery: Codable {
    let cycleId: Int
    let sleepId: Int
    let userId: Int
    let createdAt: String
    let updatedAt: String
    let scoreState: String
    let score: WHOOPRecoveryScore

    enum CodingKeys: String, CodingKey {
        case cycleId = "cycle_id"
        case sleepId = "sleep_id"
        case userId = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case scoreState = "score_state"
        case score
    }
}

/// WHOOP recovery score details
struct WHOOPRecoveryScore: Codable {
    let recoveryScore: Int  // 0-100%
    let restingHeartRate: Int
    let hrvRmssd: Double  // HRV in milliseconds
    let spo2Percentage: Double?
    let skinTempCelsius: Double?

    enum CodingKeys: String, CodingKey {
        case recoveryScore = "recovery_score"
        case restingHeartRate = "resting_heart_rate"
        case hrvRmssd = "hrv_rmssd_milli"
        case spo2Percentage = "spo2_percentage"
        case skinTempCelsius = "skin_temp_celsius"
    }
}

/// WHOOP sleep data
struct WHOOPSleep: Codable {
    let id: Int
    let userId: Int
    let createdAt: String
    let updatedAt: String
    let start: String
    let end: String
    let sleepNeeded: SleepNeeded
    let score: SleepScore

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case start
        case end
        case sleepNeeded = "sleep_needed"
        case score
    }
}

/// WHOOP sleep needed breakdown
struct SleepNeeded: Codable {
    let baselineMilli: Int
    let needFromStrainMilli: Int
    let needFromSleepDebtMilli: Int
    let needFromRecentStrainMilli: Int
    let needFromRecentNapMilli: Int

    enum CodingKeys: String, CodingKey {
        case baselineMilli = "baseline_milli"
        case needFromStrainMilli = "need_from_strain_milli"
        case needFromSleepDebtMilli = "need_from_sleep_debt_milli"
        case needFromRecentStrainMilli = "need_from_recent_strain_milli"
        case needFromRecentNapMilli = "need_from_recent_nap_milli"
    }
}

/// WHOOP sleep score details
struct SleepScore: Codable {
    let sleepPerformancePercentage: Int  // 0-100%
    let qualityDuration: Int  // milliseconds
    let latencyDuration: Int
    let remDuration: Int
    let slowWaveSleepDuration: Int
    let lightSleepDuration: Int
    let awakeDuration: Int

    enum CodingKeys: String, CodingKey {
        case sleepPerformancePercentage = "sleep_performance_percentage"
        case qualityDuration = "quality_duration"
        case latencyDuration = "latency_duration"
        case remDuration = "rem_duration"
        case slowWaveSleepDuration = "slow_wave_sleep_duration"
        case lightSleepDuration = "light_sleep_duration"
        case awakeDuration = "awake_duration"
    }
}

/// WHOOP recovery response (API returns array)
struct WHOOPRecoveryResponse: Codable {
    let records: [WHOOPRecovery]
    let nextToken: String?

    enum CodingKeys: String, CodingKey {
        case records
        case nextToken = "next_token"
    }
}

/// WHOOP sleep response (API returns array)
struct WHOOPSleepResponse: Codable {
    let records: [WHOOPSleep]
    let nextToken: String?

    enum CodingKeys: String, CodingKey {
        case records
        case nextToken = "next_token"
    }
}

/// WHOOP API errors
enum WHOOPError: Error {
    case noDataAvailable
    case authenticationFailed
    case apiError(String)
}

// MARK: - ReadinessService Integration Extension

/// Extension to integrate WHOOP data with ReadinessService
/// NOTE: This extension will work once ReadinessService is implemented in Build 39
extension WHOOPService {
    /// Convert WHOOP data to WHOOPReadinessInput for use with ReadinessService
    /// - Parameters:
    ///   - accessToken: Valid WHOOP access token
    ///   - recovery: WHOOP recovery data (optional, will fetch if nil)
    ///   - sleep: WHOOP sleep data (optional, will fetch if nil)
    /// - Returns: WHOOPReadinessInput with WHOOP data mapped to readiness metrics
    func toWHOOPReadinessInput(
        accessToken: String,
        recovery: WHOOPRecovery? = nil,
        sleep: WHOOPSleep? = nil
    ) async throws -> WHOOPReadinessInput {
        // Fetch data if not provided
        let recoveryData: WHOOPRecovery
        if let r = recovery {
            recoveryData = r
        } else {
            recoveryData = try await fetchTodayRecovery(accessToken: accessToken)
        }

        let sleepData: WHOOPSleep
        if let s = sleep {
            sleepData = s
        } else {
            sleepData = try await fetchTodaySleep(accessToken: accessToken)
        }

        // Convert WHOOP recovery % to readiness input
        let whoopRecoveryPct = recoveryData.score.recoveryScore

        // Extract HRV value for baseline tracking
        let hrvValue = recoveryData.score.hrvRmssd

        // Map sleep performance to quality (1-5 scale)
        let sleepQuality = calculateSleepQuality(from: sleepData.score.sleepPerformancePercentage)

        // Calculate sleep hours from quality duration
        let sleepHours = Double(sleepData.score.qualityDuration) / (1000 * 60 * 60)

        return WHOOPReadinessInput(
            sleepHours: sleepHours,
            sleepQuality: sleepQuality,
            hrvValue: hrvValue,
            whoopRecoveryPct: whoopRecoveryPct,
            subjectiveReadiness: nil,  // Still needs manual input
            armSoreness: false,
            armSorenessSeverity: nil,
            jointPain: [],
            jointPainNotes: nil
        )
    }

    /// Map WHOOP sleep performance percentage to 1-5 quality scale
    /// - Parameter performancePct: WHOOP sleep performance (0-100)
    /// - Returns: Sleep quality rating (1-5)
    private func calculateSleepQuality(from performancePct: Int) -> Int {
        switch performancePct {
        case 85...: return 5  // Excellent
        case 70..<85: return 4  // Good
        case 50..<70: return 3  // Fair
        case 30..<50: return 2  // Poor
        default: return 1  // Very Poor
        }
    }
}

// MARK: - WHOOPReadinessInput Model

/// WHOOP-specific readiness input model
/// Contains fields specific to WHOOP data integration
struct WHOOPReadinessInput: Codable {
    var sleepHours: Double?
    var sleepQuality: Int?
    var hrvValue: Double?
    var whoopRecoveryPct: Int?
    var subjectiveReadiness: Int?
    var armSoreness: Bool
    var armSorenessSeverity: Int?
    var jointPain: [JointPainLocation]
    var jointPainNotes: String?
}

// Note: JointPainLocation is defined in Models/DailyReadiness.swift
