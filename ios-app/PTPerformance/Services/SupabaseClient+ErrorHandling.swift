//
//  SupabaseClient+ErrorHandling.swift
//  PTPerformance
//
//  Build 95 - Agent 9: Enhanced error handling for Supabase operations
//

import Foundation
import Supabase

extension PTSupabaseClient {

    // MARK: - Query with Retry

    /// Execute a Supabase query with automatic retry logic
    /// - Parameter operation: The query operation to execute
    /// - Returns: Query result
    func queryWithRetry<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        do {
            return try await NetworkRetry.retrySupabaseQuery {
                try await operation()
            }
        } catch {
            let appError = AppError.from(error)
            ErrorLogger.shared.logDatabaseError(error)
            throw appError
        }
    }

    // MARK: - Edge Function with Timeout

    /// Invoke an Edge Function with timeout and retry logic
    /// - Parameters:
    ///   - functionName: Name of the Edge Function
    ///   - body: Request body data
    ///   - timeout: Maximum time to wait for response (default: 30s)
    /// - Returns: Function response
    func invokeFunction(
        _ functionName: String,
        body: Data,
        timeout: TimeInterval = 30.0
    ) async throws {
        do {
            try await NetworkRetry.retryEdgeFunction(timeout: timeout) {
                try await self.client.functions.invoke(
                    functionName,
                    options: .init(body: body)
                )
            }
        } catch {
            let appError = AppError.from(error)
            ErrorLogger.shared.logError(
                error,
                context: "Edge Function: \(functionName)"
            )
            throw appError
        }
    }

    // MARK: - Authentication with Error Handling

    /// Sign in with enhanced error handling
    /// - Parameters:
    ///   - email: User email
    ///   - password: User password
    /// - Throws: AppError with user-friendly message
    func signInWithErrorHandling(email: String, password: String) async throws {
        do {
            try await signIn(email: email, password: password)
        } catch {
            let appError = convertAuthError(error)
            ErrorLogger.shared.logError(error, context: "Sign In")
            throw appError
        }
    }

    /// Sign out with enhanced error handling
    /// - Throws: AppError with user-friendly message
    func signOutWithErrorHandling() async throws {
        do {
            try await signOut()
            ErrorLogger.shared.clearUser()
        } catch {
            let appError = AppError.from(error)
            ErrorLogger.shared.logError(error, context: "Sign Out")
            throw appError
        }
    }

    // MARK: - Network Status

    /// Check if the app is currently online
    func checkNetworkStatus() async -> Bool {
        do {
            // Try a lightweight query to check connectivity
            _ = try await client.auth.session
            await MainActor.run { self.isOffline = false }
            return true
        } catch {
            await MainActor.run { self.isOffline = true }
            return false
        }
    }

    // MARK: - Private Helpers

    /// Convert authentication errors to user-friendly AppErrors
    private func convertAuthError(_ error: Error) -> AppError {
        let description = error.localizedDescription.lowercased()

        if description.contains("invalid") && description.contains("credentials") {
            return .invalidCredentials
        }

        if description.contains("session") {
            return .sessionExpired
        }

        if description.contains("unauthorized") || description.contains("not authenticated") {
            return .notAuthenticated
        }

        return .authenticationFailed(error)
    }
}

// MARK: - Offline Mode Support

extension PTSupabaseClient {

    /// BUILD 286: UserDefaults-based offline caching (ACP-600)
    private static let cachePrefix = "pt_offline_cache_"
    private static let cacheTimestampPrefix = "pt_cache_ts_"
    private static let maxCacheAge: TimeInterval = 24 * 60 * 60 // 24 hours

    /// Check if a cached version of data exists and is not expired
    func hasCachedData<T>(forKey key: String, type: T.Type) -> Bool {
        let cacheKey = Self.cachePrefix + key
        guard UserDefaults.standard.data(forKey: cacheKey) != nil else { return false }

        // Check cache age
        let tsKey = Self.cacheTimestampPrefix + key
        let cachedAt = UserDefaults.standard.double(forKey: tsKey)
        if cachedAt > 0 {
            let age = Date().timeIntervalSince1970 - cachedAt
            return age < Self.maxCacheAge
        }
        return true
    }

    /// Get cached data for offline use
    func getCachedData<T: Codable>(forKey key: String, type: T.Type) -> T? {
        let cacheKey = Self.cachePrefix + key
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return nil }

        do {
            return try Self.flexibleDecoder.decode(T.self, from: data)
        } catch {
            ErrorLogger.shared.logWarning("Failed to decode cached data for \(key): \(error.localizedDescription)")
            return nil
        }
    }

    /// Cache data for offline use
    func cacheData<T: Codable>(_ data: T, forKey key: String) {
        let cacheKey = Self.cachePrefix + key
        let tsKey = Self.cacheTimestampPrefix + key

        do {
            let encoded = try JSONEncoder().encode(data)
            UserDefaults.standard.set(encoded, forKey: cacheKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: tsKey)
        } catch {
            ErrorLogger.shared.logWarning("Failed to cache data for \(key): \(error.localizedDescription)")
        }
    }

    /// Clear all cached data
    func clearCache() {
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys
        for key in allKeys where key.hasPrefix(Self.cachePrefix) || key.hasPrefix(Self.cacheTimestampPrefix) {
            defaults.removeObject(forKey: key)
        }
    }
}
