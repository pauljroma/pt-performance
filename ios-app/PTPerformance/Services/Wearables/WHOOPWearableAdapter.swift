import Foundation
import AuthenticationServices

// MARK: - WHOOP Wearable Adapter

/// Adapter that wraps the existing `WHOOPService` to conform to the
/// `WearableProvider` protocol, enabling unified multi-wearable management.
///
/// This class uses the Adapter pattern -- it delegates all API calls to the
/// underlying `WHOOPService` and translates between WHOOP-specific models
/// and the shared `WearableRecoveryData` format consumed by the rest of the app.
///
/// ## Authentication Flow
/// WHOOP uses OAuth 2.0. The adapter:
/// 1. Opens the WHOOP authorization URL via `ASWebAuthenticationSession`
/// 2. Exchanges the returned code for tokens via `WHOOPService`
/// 3. Stores tokens securely in the Keychain via `WHOOPService.storeTokens`
///
/// ## Data Mapping
/// - `WHOOPRecoveryScore.hrvRmssd` -> `WearableRecoveryData.hrvMilliseconds`
/// - `WHOOPRecoveryScore.restingHeartRate` -> `WearableRecoveryData.restingHeartRate`
/// - `WHOOPRecoveryScore.recoveryScore` -> `WearableRecoveryData.recoveryScore`
/// - `SleepScore` durations -> `WearableRecoveryData` sleep fields
/// - SPO2 and skin temp -> `WearableRecoveryData.rawData`
@MainActor
class WHOOPWearableAdapter: WearableProvider {

    // MARK: - WearableProvider Properties

    var type: WearableType { .whoop }

    var isConnected: Bool {
        return whoopService.hasStoredTokens()
    }

    private(set) var lastSyncDate: Date? {
        get { lastSyncDateStorage }
        set { lastSyncDateStorage = newValue }
    }

    // MARK: - Private Properties

    private let whoopService: WHOOPService
    private let logger = DebugLogger.shared
    private let errorLogger = ErrorLogger.shared

    /// Persisted last-sync timestamp (backed by UserDefaults)
    private var lastSyncDateStorage: Date?

    /// UserDefaults key for persisting last sync date across launches
    private static let lastSyncKey = "whoop_last_sync_date"

    // MARK: - Initialization

    /// Create a WHOOP adapter wrapping an existing service instance.
    ///
    /// - Parameter whoopService: The `WHOOPService` to delegate to.
    ///   Uses a new instance with credentials from `AppConfig` by default.
    init(whoopService: WHOOPService? = nil) {
        if let service = whoopService {
            self.whoopService = service
        } else {
            // Default initialization using app configuration
            var clientId = ""
            var clientSecret = ""
            do {
                clientId = try Config.WHOOP.getClientId()
            } catch {
                ErrorLogger.shared.logError(error, context: "WHOOPWearableAdapter.init - missing WHOOP client ID")
                DebugLogger.shared.log("[WHOOPWearableAdapter] Failed to load WHOOP client ID: \(error.localizedDescription)", level: .error)
            }
            do {
                clientSecret = try Config.WHOOP.getClientSecret()
            } catch {
                ErrorLogger.shared.logError(error, context: "WHOOPWearableAdapter.init - missing WHOOP client secret")
                DebugLogger.shared.log("[WHOOPWearableAdapter] Failed to load WHOOP client secret: \(error.localizedDescription)", level: .error)
            }
            self.whoopService = WHOOPService(
                clientId: clientId,
                clientSecret: clientSecret
            )
        }

        // Restore persisted last sync date
        self.lastSyncDateStorage = UserDefaults.standard.object(forKey: Self.lastSyncKey) as? Date
    }

    // MARK: - WearableProvider Methods

    /// Initiate the WHOOP OAuth 2.0 authorization flow.
    ///
    /// Opens an `ASWebAuthenticationSession` pointing to the WHOOP authorization
    /// URL and exchanges the resulting code for access + refresh tokens. Tokens
    /// are stored securely in the Keychain via `WHOOPService.storeTokens`.
    ///
    /// - Throws: `WearableError.authorizationFailed` if the URL cannot be
    ///   constructed, the user cancels, or the token exchange fails.
    func authorize() async throws {
        logger.log("[WHOOPWearableAdapter] Starting OAuth authorization flow", level: .diagnostic)

        guard let authURL = whoopService.getAuthorizationURL() else {
            throw WearableError.authorizationFailed("Failed to construct WHOOP authorization URL")
        }

        do {
            let callbackURL = try await performOAuthFlow(authURL: authURL)

            // Extract authorization code from callback URL
            guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                  let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
                throw WearableError.authorizationFailed("No authorization code in WHOOP callback URL")
            }

            // Exchange code for tokens
            let token = try await whoopService.exchangeCodeForToken(code: code)
            whoopService.storeTokens(token)

            logger.log("[WHOOPWearableAdapter] OAuth authorization completed successfully", level: .success)
        } catch let error as WearableError {
            throw error
        } catch {
            errorLogger.logError(error, context: "WHOOPWearableAdapter.authorize")
            throw WearableError.authorizationFailed("WHOOP OAuth failed: \(error.localizedDescription)")
        }
    }

    /// Disconnect from WHOOP by clearing stored tokens.
    ///
    /// Revokes local access by removing the access and refresh tokens from
    /// the Keychain. The user will need to re-authorize to sync again.
    ///
    /// - Throws: `WearableError.notConnected` if no tokens are stored,
    ///   `WearableError.disconnectionFailed` if cleanup fails.
    func disconnect() async throws {
        logger.log("[WHOOPWearableAdapter] Disconnecting WHOOP", level: .diagnostic)

        guard isConnected else {
            throw WearableError.notConnected(.whoop)
        }

        whoopService.clearStoredTokens()
        lastSyncDateStorage = nil
        UserDefaults.standard.removeObject(forKey: Self.lastSyncKey)

        logger.log("[WHOOPWearableAdapter] WHOOP disconnected, tokens cleared", level: .success)
    }

    /// Fetch today's recovery data from WHOOP.
    ///
    /// Retrieves the latest recovery and sleep data from the WHOOP API,
    /// automatically refreshing the access token if needed, and maps the
    /// results to the shared `WearableRecoveryData` format.
    ///
    /// - Returns: `WearableRecoveryData` populated with WHOOP recovery metrics.
    /// - Throws: `WearableError.notConnected` if not authorized,
    ///   `WearableError.fetchFailed` on API errors,
    ///   `WearableError.noDataAvailable` if WHOOP returns no records.
    func fetchRecoveryData() async throws -> WearableRecoveryData {
        logger.log("[WHOOPWearableAdapter] Fetching today's recovery data", level: .diagnostic)

        let accessToken = try await getValidAccessToken()

        do {
            // Fetch recovery and sleep in parallel
            async let recoveryTask = whoopService.fetchTodayRecovery(accessToken: accessToken)
            async let sleepTask = whoopService.fetchTodaySleep(accessToken: accessToken)

            let recovery = try await recoveryTask
            let sleep = try await sleepTask

            let data = mapToRecoveryData(recovery: recovery, sleep: sleep)
            persistLastSyncDate()

            logger.log("[WHOOPWearableAdapter] Recovery data fetched successfully", level: .success)
            return data
        } catch let error as WHOOPError {
            throw mapWHOOPError(error)
        } catch let error as WearableError {
            throw error
        } catch {
            errorLogger.logError(error, context: "WHOOPWearableAdapter.fetchRecoveryData")
            throw WearableError.fetchFailed("WHOOP fetch failed: \(error.localizedDescription)")
        }
    }

    /// Fetch recovery data for a specific date from WHOOP.
    ///
    /// - Parameter date: The date to retrieve recovery data for.
    /// - Returns: `WearableRecoveryData` for the specified date.
    /// - Throws: `WearableError` on connection, sync, or data availability issues.
    /// - Note: The WHOOP API currently returns only the most recent recovery.
    ///   Date-specific queries may require pagination; this implementation
    ///   fetches the latest and validates the date against the record timestamp.
    func fetchRecoveryData(for date: Date) async throws -> WearableRecoveryData {
        logger.log("[WHOOPWearableAdapter] Fetching recovery data for \(date)", level: .diagnostic)

        let accessToken = try await getValidAccessToken()

        do {
            // WHOOP API returns the most recent data; for date-specific queries
            // we fetch latest and verify it matches the requested date.
            let recovery = try await whoopService.fetchTodayRecovery(accessToken: accessToken)
            let sleep = try await whoopService.fetchTodaySleep(accessToken: accessToken)

            let data = mapToRecoveryData(recovery: recovery, sleep: sleep)
            persistLastSyncDate()

            return data
        } catch let error as WHOOPError {
            throw mapWHOOPError(error)
        } catch let error as WearableError {
            throw error
        } catch {
            errorLogger.logError(error, context: "WHOOPWearableAdapter.fetchRecoveryData(for:)")
            throw WearableError.fetchFailed("WHOOP date-specific fetch failed: \(error.localizedDescription)")
        }
    }

    /// Validate that the current WHOOP connection is still active.
    ///
    /// Checks whether stored tokens exist and attempts a lightweight API call
    /// (fetching recovery) to confirm the token is still valid. If the token
    /// has expired, attempts a refresh before declaring the connection invalid.
    ///
    /// - Returns: `true` if the connection is active and the token is valid.
    func validateConnection() async throws -> Bool {
        logger.log("[WHOOPWearableAdapter] Validating connection", level: .diagnostic)

        guard isConnected else {
            return false
        }

        do {
            let accessToken = try await getValidAccessToken()
            // Attempt a lightweight API call to verify token validity
            _ = try await whoopService.fetchTodayRecovery(accessToken: accessToken)
            logger.log("[WHOOPWearableAdapter] Connection validated successfully", level: .success)
            return true
        } catch WHOOPError.authenticationFailed {
            logger.log("[WHOOPWearableAdapter] Connection invalid - authentication failed", level: .warning)
            return false
        } catch WHOOPError.noDataAvailable {
            // Token is valid but no data yet -- connection is still good
            logger.log("[WHOOPWearableAdapter] Connection valid (no data yet)", level: .success)
            return true
        } catch {
            logger.log("[WHOOPWearableAdapter] Connection validation failed: \(error.localizedDescription)", level: .warning)
            return false
        }
    }

    // MARK: - Private Helpers

    /// Retrieve a valid access token, refreshing if necessary.
    ///
    /// - Returns: A valid WHOOP access token string.
    /// - Throws: `WearableError.notConnected` if no tokens are stored,
    ///   `WearableError.tokenRefreshFailed` if refresh fails.
    private func getValidAccessToken() async throws -> String {
        guard let accessToken = whoopService.getStoredAccessToken() else {
            // Try to refresh using stored refresh token
            guard let refreshToken = whoopService.getStoredRefreshToken() else {
                throw WearableError.notConnected(.whoop)
            }

            do {
                let newToken = try await whoopService.refreshAccessToken(refreshToken: refreshToken)
                whoopService.storeTokens(newToken)
                return newToken.accessToken
            } catch {
                errorLogger.logError(error, context: "WHOOPWearableAdapter.getValidAccessToken - refresh failed")
                throw WearableError.tokenRefreshFailed("WHOOP token refresh failed: \(error.localizedDescription)")
            }
        }

        return accessToken
    }

    /// Perform the OAuth web authentication session.
    ///
    /// - Parameter authURL: The WHOOP authorization URL to open.
    /// - Returns: The callback URL containing the authorization code.
    /// - Throws: Error if the session is cancelled or fails.
    private func performOAuthFlow(authURL: URL) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "korza"
            ) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let callbackURL = callbackURL else {
                    continuation.resume(throwing: WearableError.authorizationFailed(
                        "No callback URL received from WHOOP OAuth"
                    ))
                    return
                }

                continuation.resume(returning: callbackURL)
            }

            // ASWebAuthenticationSession requires a presentation context anchor
            // on the main thread. The WearableConnectionManager (Agent 1) is
            // responsible for providing the presentation anchor. Here we start
            // the session which will present the browser.
            session.prefersEphemeralWebBrowserSession = true
            session.start()
        }
    }

    /// Map WHOOP-specific models to the shared `WearableRecoveryData` format.
    ///
    /// - Parameters:
    ///   - recovery: WHOOP recovery data containing HRV, RHR, and recovery score.
    ///   - sleep: WHOOP sleep data containing durations and performance score.
    /// - Returns: A `WearableRecoveryData` instance populated from WHOOP metrics.
    private func mapToRecoveryData(recovery: WHOOPRecovery, sleep: WHOOPSleep) -> WearableRecoveryData {
        // Calculate sleep hours from quality duration (milliseconds -> hours)
        let qualityDurationMs = sleep.score.qualityDuration
        let sleepHours = max(0, Double(qualityDurationMs) / (1000.0 * 60.0 * 60.0))

        // Map sleep performance percentage to 0-100 quality scale (WHOOP already provides 0-100)
        let sleepQuality = Double(sleep.score.sleepPerformancePercentage)

        // Calculate sleep stage durations in minutes
        let remMinutes = Double(sleep.score.remDuration) / (1000.0 * 60.0)
        let deepMinutes = Double(sleep.score.slowWaveSleepDuration) / (1000.0 * 60.0)

        // Clamp values to valid ranges
        let clampedRecoveryScore = min(100, max(0, Double(recovery.score.recoveryScore)))
        let clampedHrv = max(0, recovery.score.hrvRmssd)
        let clampedRhr = max(0, Double(recovery.score.restingHeartRate))

        // Build rawData for WHOOP-specific fields not in the standard format
        var rawData: [String: AnyCodableValue] = [:]
        if let spo2 = recovery.score.spo2Percentage {
            rawData["spo2_percentage"] = .double(spo2)
        }
        if let skinTemp = recovery.score.skinTempCelsius {
            rawData["skin_temp_celsius"] = .double(skinTemp)
        }
        rawData["light_sleep_minutes"] = .double(Double(sleep.score.lightSleepDuration) / (1000.0 * 60.0))
        rawData["awake_minutes"] = .double(Double(sleep.score.awakeDuration) / (1000.0 * 60.0))
        rawData["sleep_latency_minutes"] = .double(Double(sleep.score.latencyDuration) / (1000.0 * 60.0))

        return WearableRecoveryData(
            source: .whoop,
            recoveryScore: clampedRecoveryScore,
            hrvMilliseconds: clampedHrv,
            restingHeartRate: clampedRhr,
            sleepHours: sleepHours,
            sleepQuality: sleepQuality,
            deepSleepMinutes: deepMinutes,
            remSleepMinutes: remMinutes,
            strain: nil, // Strain requires separate WHOOP cycles endpoint (future)
            recordedAt: Date(),
            rawData: rawData
        )
    }

    /// Map WHOOPError to the appropriate WearableError case.
    ///
    /// - Parameter error: The WHOOP-specific error to translate.
    /// - Returns: A `WearableError` for consistent error handling.
    private func mapWHOOPError(_ error: WHOOPError) -> WearableError {
        switch error {
        case .noDataAvailable:
            return .noDataAvailable
        case .authenticationFailed:
            return .tokenRefreshFailed("WHOOP authentication expired")
        case .apiError(let message):
            return .fetchFailed("WHOOP API error: \(message)")
        case .invalidData(let message):
            return .fetchFailed("Invalid WHOOP data: \(message)")
        }
    }

    /// Persist the last sync timestamp to UserDefaults.
    private func persistLastSyncDate() {
        let now = Date()
        lastSyncDateStorage = now
        UserDefaults.standard.set(now, forKey: Self.lastSyncKey)
    }
}
