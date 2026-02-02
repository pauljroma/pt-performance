//
//  NetworkRetry.swift
//  PTPerformance
//
//  Network retry logic with exponential backoff and offline detection
//

import Foundation

/// Network retry configuration and utilities
struct NetworkRetry {

    // MARK: - Configuration

    /// Default retry configuration
    struct Config {
        /// Maximum number of retry attempts
        let maxRetries: Int
        /// Base delay between retries (will be multiplied by attempt number)
        let baseDelay: TimeInterval
        /// Maximum delay cap
        let maxDelay: TimeInterval
        /// Timeout for the operation
        let timeout: TimeInterval

        static let `default` = Config(
            maxRetries: 3,
            baseDelay: 1.0,
            maxDelay: 10.0,
            timeout: 30.0
        )

        static let edgeFunction = Config(
            maxRetries: 2,
            baseDelay: 2.0,
            maxDelay: 8.0,
            timeout: 60.0
        )

        static let quick = Config(
            maxRetries: 1,
            baseDelay: 0.5,
            maxDelay: 2.0,
            timeout: 10.0
        )
    }

    // MARK: - Retry Logic

    /// Execute a Supabase query with automatic retry logic
    /// - Parameters:
    ///   - config: Retry configuration
    ///   - operation: The async operation to execute
    /// - Returns: The operation result
    /// - Throws: AppError with user-friendly message after all retries exhausted
    static func retrySupabaseQuery<T>(
        config: Config = .default,
        _ operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        var attempt = 0

        while attempt <= config.maxRetries {
            do {
                // Check if we're offline before attempting
                if PTSupabaseClient.shared.isOffline && attempt > 0 {
                    throw AppError.noInternetConnection
                }

                return try await withTimeout(seconds: config.timeout) {
                    try await operation()
                }
            } catch {
                lastError = error

                // Don't retry for certain error types
                if shouldNotRetry(error) {
                    throw convertToAppError(error)
                }

                // Log the retry attempt
                ErrorLogger.shared.logWarning(
                    "Retry attempt \(attempt + 1)/\(config.maxRetries + 1) failed: \(error.localizedDescription)"
                )

                // Calculate delay with exponential backoff
                if attempt < config.maxRetries {
                    let delay = min(
                        config.baseDelay * pow(2.0, Double(attempt)),
                        config.maxDelay
                    )
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }

                attempt += 1
            }
        }

        // All retries exhausted
        throw convertToAppError(lastError ?? AppError.unknown(NSError(
            domain: "NetworkRetry",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Operation failed after \(config.maxRetries) retries"]
        )))
    }

    /// Execute an Edge Function with timeout and retry logic
    /// - Parameters:
    ///   - timeout: Maximum time to wait for response
    ///   - operation: The async operation to execute
    /// - Returns: The operation result
    static func retryEdgeFunction<T>(
        timeout: TimeInterval = 30.0,
        _ operation: @escaping () async throws -> T
    ) async throws -> T {
        let config = Config(
            maxRetries: Config.edgeFunction.maxRetries,
            baseDelay: Config.edgeFunction.baseDelay,
            maxDelay: Config.edgeFunction.maxDelay,
            timeout: timeout
        )

        return try await retrySupabaseQuery(config: config, operation)
    }

    // MARK: - Timeout Wrapper

    /// Execute an operation with a timeout
    private static func withTimeout<T>(
        seconds: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw AppError.requestTimeout
            }

            guard let result = try await group.next() else {
                throw AppError.requestTimeout
            }

            group.cancelAll()
            return result
        }
    }

    // MARK: - Error Classification

    /// Determine if an error should not be retried
    private static func shouldNotRetry(_ error: Error) -> Bool {
        // Check for authentication errors (don't retry)
        if let appError = error as? AppError {
            switch appError {
            case .notAuthenticated, .sessionExpired, .invalidCredentials:
                return true
            case .invalidInput, .missingRequiredData, .invalidDateRange:
                return true
            default:
                return false
            }
        }

        // Check for URL errors that shouldn't be retried
        if let urlError = error as? URLError {
            switch urlError.code {
            case .cancelled, .userCancelledAuthentication:
                return true
            case .badURL, .unsupportedURL:
                return true
            default:
                return false
            }
        }

        // Check error description for non-retryable patterns
        let description = error.localizedDescription.lowercased()
        if description.contains("unauthorized") ||
           description.contains("forbidden") ||
           description.contains("invalid token") {
            return true
        }

        return false
    }

    /// Convert a raw error to a user-friendly AppError
    private static func convertToAppError(_ error: Error) -> AppError {
        // Already an AppError
        if let appError = error as? AppError {
            return appError
        }

        // Use the centralized error conversion
        return AppError.from(error)
    }
}

// MARK: - Network Status Helper

extension NetworkRetry {

    /// Check network connectivity before performing an operation
    /// - Returns: true if online, false if offline
    @MainActor
    static func isNetworkAvailable() -> Bool {
        !PTSupabaseClient.shared.isOffline
    }

    /// Perform an operation with offline fallback
    /// - Parameters:
    ///   - onlineOperation: Operation to perform when online
    ///   - offlineFallback: Fallback value when offline
    /// - Returns: Operation result or fallback
    static func withOfflineFallback<T>(
        onlineOperation: () async throws -> T,
        offlineFallback: () async -> T
    ) async -> T {
        do {
            return try await onlineOperation()
        } catch {
            // Check if this was a network error
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost, .timedOut:
                    await MainActor.run {
                        PTSupabaseClient.shared.isOffline = true
                    }
                    return await offlineFallback()
                default:
                    break
                }
            }

            // For other errors, still try the fallback
            return await offlineFallback()
        }
    }
}
