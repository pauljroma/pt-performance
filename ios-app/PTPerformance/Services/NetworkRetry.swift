//
//  NetworkRetry.swift
//  PTPerformance
//
//  Build 138 - Stub implementation for SupabaseClient+ErrorHandling
//

import Foundation

struct NetworkRetry {
    static func retrySupabaseQuery<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        return try await operation()
    }

    static func retryEdgeFunction<T>(timeout: TimeInterval, _ operation: @escaping () async throws -> T) async throws -> T {
        return try await operation()
    }
}
