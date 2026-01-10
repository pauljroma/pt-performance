//
//  NetworkRetry.swift
//  PTPerformance
//
//  Build 95 - Agent 9: Network retry logic with exponential backoff
//

import Foundation

/// Retry configuration for network requests
struct RetryConfig {
    let maxAttempts: Int
    let initialDelay: TimeInterval
    let maxDelay: TimeInterval
    let multiplier: Double

    static let `default` = RetryConfig(
        maxAttempts: 3,
        initialDelay: 1.0,
        maxDelay: 10.0,
        multiplier: 2.0
    )

    static let quick = RetryConfig(
        maxAttempts: 2,
        initialDelay: 0.5,
        maxDelay: 2.0,
        multiplier: 2.0
    )

    static let aggressive = RetryConfig(
        maxAttempts: 5,
        initialDelay: 0.5,
        maxDelay: 30.0,
        multiplier: 2.0
    )
}

/// Network retry utility with exponential backoff
actor NetworkRetry {

    // MARK: - Retry with Exponential Backoff

    /// Retry an async operation with exponential backoff
    /// - Parameters:
    ///   - config: Retry configuration
    ///   - shouldRetry: Closure to determine if error is retryable
    ///   - operation: The async operation to retry
    /// - Returns: Result of the operation
    static func retry<T>(
        config: RetryConfig = .default,
        shouldRetry: ((Error) -> Bool)? = nil,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var attempt = 1
        var lastError: Error?

        while attempt <= config.maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error

                // Check if we should retry
                let isRetryable = shouldRetry?(error) ?? isRetryableError(error)

                // Don't retry if not retryable or max attempts reached
                if !isRetryable || attempt >= config.maxAttempts {
                    throw error
                }

                // Calculate delay with exponential backoff
                let delay = calculateDelay(
                    attempt: attempt,
                    initialDelay: config.initialDelay,
                    maxDelay: config.maxDelay,
                    multiplier: config.multiplier
                )

                print("⚠️ Retry attempt \(attempt)/\(config.maxAttempts) failed: \(error.localizedDescription)")
                print("   Retrying in \(String(format: "%.1f", delay))s...")

                // Wait before retrying
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

                attempt += 1
            }
        }

        throw lastError ?? AppError.unknown(NSError(domain: "NetworkRetry", code: -1))
    }

    // MARK: - Retry with Timeout

    /// Retry an operation with both retry logic and timeout
    /// - Parameters:
    ///   - timeout: Maximum time to allow for the operation
    ///   - config: Retry configuration
    ///   - operation: The async operation to retry
    /// - Returns: Result of the operation
    static func retryWithTimeout<T>(
        timeout: TimeInterval,
        config: RetryConfig = .default,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withTimeout(timeout: timeout) {
            try await retry(config: config, operation: operation)
        }
    }

    // MARK: - Timeout Wrapper

    /// Execute an operation with a timeout
    /// - Parameters:
    ///   - timeout: Maximum time to allow for the operation
    ///   - operation: The async operation to execute
    /// - Returns: Result of the operation
    static func withTimeout<T>(
        timeout: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            // Add the main operation
            group.addTask {
                try await operation()
            }

            // Add timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw AppError.requestTimeout
            }

            // Return first result (either success or timeout)
            guard let result = try await group.next() else {
                throw AppError.requestTimeout
            }

            // Cancel remaining tasks
            group.cancelAll()

            return result
        }
    }

    // MARK: - Helper Methods

    /// Calculate delay for retry attempt using exponential backoff
    private static func calculateDelay(
        attempt: Int,
        initialDelay: TimeInterval,
        maxDelay: TimeInterval,
        multiplier: Double
    ) -> TimeInterval {
        let exponentialDelay = initialDelay * pow(multiplier, Double(attempt - 1))
        let jitter = Double.random(in: 0.0...0.2) * exponentialDelay
        return min(exponentialDelay + jitter, maxDelay)
    }

    /// Check if an error is retryable
    private static func isRetryableError(_ error: Error) -> Bool {
        // URLErrors that are retryable
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut,
                 .cannotConnectToHost,
                 .networkConnectionLost,
                 .notConnectedToInternet,
                 .dnsLookupFailed,
                 .cannotFindHost:
                return true
            default:
                return false
            }
        }

        // AppErrors that are retryable
        if let appError = error as? AppError {
            return appError.shouldRetry
        }

        // Check error description for common retryable patterns
        let description = error.localizedDescription.lowercased()
        return description.contains("timeout") ||
               description.contains("connection") ||
               description.contains("network") ||
               description.contains("unavailable")
    }
}

// MARK: - Retry Extensions for Common Operations

extension NetworkRetry {

    /// Retry a Supabase query
    static func retrySupabaseQuery<T>(
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await retry(
            config: .default,
            shouldRetry: { error in
                // Retry on network errors and timeout
                isRetryableError(error)
            },
            operation: operation
        )
    }

    /// Retry an Edge Function call with timeout
    static func retryEdgeFunction<T>(
        timeout: TimeInterval = 30.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await retryWithTimeout(
            timeout: timeout,
            config: .quick,
            operation: operation
        )
    }

    /// Retry an AI request with extended timeout
    static func retryAIRequest<T>(
        timeout: TimeInterval = 60.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await retryWithTimeout(
            timeout: timeout,
            config: RetryConfig(
                maxAttempts: 2, // AI requests are expensive, limit retries
                initialDelay: 2.0,
                maxDelay: 5.0,
                multiplier: 2.0
            ),
            operation: operation
        )
    }
}
