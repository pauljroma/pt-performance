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

    /// Check if a cached version of data exists for offline use
    /// This is a placeholder for future offline caching implementation
    func hasCachedData<T>(forKey key: String, type: T.Type) -> Bool {
        // TODO: Implement local caching with UserDefaults or Core Data
        // For now, return false (no offline support yet)
        return false
    }

    /// Get cached data for offline use
    /// This is a placeholder for future offline caching implementation
    func getCachedData<T: Codable>(forKey key: String, type: T.Type) -> T? {
        // TODO: Implement local caching with UserDefaults or Core Data
        // For now, return nil
        return nil
    }

    /// Cache data for offline use
    /// This is a placeholder for future offline caching implementation
    func cacheData<T: Codable>(_ data: T, forKey key: String) {
        // TODO: Implement local caching with UserDefaults or Core Data
        // For now, do nothing
    }
}
