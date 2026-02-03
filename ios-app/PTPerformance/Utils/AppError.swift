//
//  AppError.swift
//  PTPerformance
//
//  Build 95 - Agent 9: Centralized error types with user-friendly messages
//

import Foundation

/// User-friendly error types for the Modus app
/// Provides clear, actionable error messages without technical jargon
enum AppError: LocalizedError {

    // MARK: - Network Errors

    case noInternetConnection
    case serverUnreachable
    case requestTimeout
    case networkError(Error)

    // MARK: - Authentication Errors

    case notAuthenticated
    case sessionExpired
    case invalidCredentials
    case authenticationFailed(Error)

    // MARK: - Database Errors

    case dataNotFound
    case saveFailed
    case deleteFailed
    case databaseError(Error)

    // MARK: - AI Service Errors

    case aiServiceUnavailable
    case aiTimeout
    case aiQuotaExceeded
    case aiError(Error)

    // MARK: - Scheduling Errors

    case sessionNotFound
    case duplicateSchedule
    case scheduleConflict
    case schedulingFailed(Error)

    // MARK: - Data Validation Errors

    case invalidInput(String)
    case missingRequiredData
    case invalidDateRange

    // MARK: - Generic Errors

    case unknown(Error)

    // MARK: - User-Friendly Error Descriptions

    var errorDescription: String? {
        switch self {
        // Network
        case .noInternetConnection:
            return "No Internet Connection"
        case .serverUnreachable:
            return "Server Unavailable"
        case .requestTimeout:
            return "Request Timed Out"
        case .networkError:
            return "Network Error"

        // Authentication
        case .notAuthenticated:
            return "Not Signed In"
        case .sessionExpired:
            return "Session Expired"
        case .invalidCredentials:
            return "Invalid Credentials"
        case .authenticationFailed:
            return "Sign In Failed"

        // Database
        case .dataNotFound:
            return "Data Not Found"
        case .saveFailed:
            return "Save Failed"
        case .deleteFailed:
            return "Delete Failed"
        case .databaseError:
            return "Database Error"

        // AI Service
        case .aiServiceUnavailable:
            return "AI Assistant Unavailable"
        case .aiTimeout:
            return "AI Request Timed Out"
        case .aiQuotaExceeded:
            return "AI Usage Limit Reached"
        case .aiError:
            return "AI Assistant Error"

        // Scheduling
        case .sessionNotFound:
            return "Session Not Found"
        case .duplicateSchedule:
            return "Already Scheduled"
        case .scheduleConflict:
            return "Schedule Conflict"
        case .schedulingFailed:
            return "Scheduling Failed"

        // Validation
        case .invalidInput(let field):
            return "Invalid \(field)"
        case .missingRequiredData:
            return "Missing Required Information"
        case .invalidDateRange:
            return "Invalid Date Range"

        // Generic
        case .unknown:
            return "Something Went Wrong"
        }
    }

    // MARK: - User-Friendly Recovery Suggestions

    var recoverySuggestion: String? {
        switch self {
        // Network
        case .noInternetConnection:
            return "Please check your internet connection and try again."
        case .serverUnreachable:
            return "Our servers are temporarily unavailable. Please try again in a few moments."
        case .requestTimeout:
            return "The request took too long. Please check your connection and try again."
        case .networkError:
            return "Please check your internet connection and try again."

        // Authentication
        case .notAuthenticated:
            return "Please sign in to continue."
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .invalidCredentials:
            return "Please check your email and password and try again."
        case .authenticationFailed:
            return "Unable to sign in. Please try again or contact support."

        // Database
        case .dataNotFound:
            return "The requested data could not be found. Please refresh and try again."
        case .saveFailed:
            return "Unable to save your changes. Please try again."
        case .deleteFailed:
            return "Unable to delete. Please try again."
        case .databaseError:
            return "Unable to access your data. Please try again or contact support."

        // AI Service
        case .aiServiceUnavailable:
            return "The AI assistant is temporarily unavailable. Please try again later."
        case .aiTimeout:
            return "The AI assistant didn't respond in time. Please try asking a simpler question."
        case .aiQuotaExceeded:
            return "You've reached your daily AI usage limit. Please try again tomorrow."
        case .aiError:
            return "The AI assistant encountered an error. Please try again."

        // Scheduling
        case .sessionNotFound:
            return "This session no longer exists. Please refresh and try again."
        case .duplicateSchedule:
            return "This session is already scheduled for this date."
        case .scheduleConflict:
            return "You already have a session scheduled at this time."
        case .schedulingFailed:
            return "Unable to schedule this session. Please try again."

        // Validation
        case .invalidInput(let field):
            return "Please enter a valid \(field.lowercased())."
        case .missingRequiredData:
            return "Please fill in all required fields."
        case .invalidDateRange:
            return "Please select a valid date range."

        // Generic
        case .unknown:
            return "An unexpected error occurred. Please try again or contact support."
        }
    }

    // MARK: - Should Retry

    /// Indicates whether the user should be prompted to retry this operation
    var shouldRetry: Bool {
        switch self {
        case .noInternetConnection, .serverUnreachable, .requestTimeout, .networkError:
            return true
        case .aiTimeout, .aiServiceUnavailable:
            return true
        case .saveFailed, .deleteFailed:
            return true
        default:
            return false
        }
    }

    // MARK: - Should Sign Out

    /// Indicates whether this error should trigger a sign-out
    var shouldSignOut: Bool {
        switch self {
        case .sessionExpired, .invalidCredentials:
            return true
        default:
            return false
        }
    }

    // MARK: - Error Conversion

    /// Convert system errors to user-friendly AppErrors
    static func from(_ error: Error) -> AppError {
        // Network errors
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .noInternetConnection
            case .timedOut:
                return .requestTimeout
            case .cannotFindHost, .cannotConnectToHost:
                return .serverUnreachable
            default:
                return .networkError(urlError)
            }
        }

        // Check error description for common patterns
        let description = error.localizedDescription.lowercased()

        if description.contains("session") && description.contains("expired") {
            return .sessionExpired
        }

        if description.contains("not authenticated") || description.contains("unauthorized") {
            return .notAuthenticated
        }

        if description.contains("timeout") {
            return .requestTimeout
        }

        if description.contains("network") || description.contains("connection") {
            return .networkError(error)
        }

        if description.contains("not found") {
            return .dataNotFound
        }

        // Default to unknown
        return .unknown(error)
    }
}

// MARK: - User-Friendly Alert Extensions

extension AppError {

    /// Get alert title and message for displaying to users
    var alertContent: (title: String, message: String) {
        let title = errorDescription ?? "Error"
        let message = recoverySuggestion ?? "Please try again."
        return (title, message)
    }
}

// MARK: - User-Friendly Error Helper

/// Helper struct for converting any error to a user-friendly message
/// Use this when you have a raw Error and need to display it to users
struct UserFriendlyError {

    /// Convert any error to a user-friendly message
    /// - Parameter error: The raw error to convert
    /// - Returns: A user-friendly message suitable for display
    static func message(for error: Error) -> String {
        // If it's already an AppError, use its built-in message
        if let appError = error as? AppError {
            return appError.recoverySuggestion ?? appError.errorDescription ?? defaultMessage
        }

        // Handle URLError (network issues)
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return "No internet connection. Please check your connection and try again."
            case .timedOut:
                return "The request took too long. Please try again."
            case .cannotFindHost, .cannotConnectToHost:
                return "Unable to reach our servers. Please try again in a moment."
            case .cancelled:
                return "The request was cancelled."
            case .secureConnectionFailed, .serverCertificateUntrusted:
                return "We couldn't establish a secure connection. Please try again."
            default:
                return "Connection error. Please check your internet and try again."
            }
        }

        // Handle DecodingError (data parsing issues)
        if error is DecodingError {
            return "We received unexpected data from the server. Please try again, and if the problem persists, contact support."
        }

        // Handle common error patterns by description
        let description = error.localizedDescription.lowercased()

        // Authentication patterns
        if description.contains("unauthorized") || description.contains("401") {
            return "Please sign in again to continue."
        }

        if description.contains("forbidden") || description.contains("403") {
            return "You don't have permission to perform this action."
        }

        // Session patterns
        if description.contains("session") && description.contains("expired") {
            return "Your session has expired. Please sign in again."
        }

        // Network patterns
        if description.contains("timeout") {
            return "The request took too long. Please try again."
        }

        if description.contains("network") || description.contains("connection") {
            return "Connection error. Please check your internet and try again."
        }

        // Not found patterns
        if description.contains("not found") || description.contains("404") {
            return "The requested item could not be found. Please refresh and try again."
        }

        // Server error patterns
        if description.contains("500") || description.contains("server error") {
            return "Our servers are experiencing issues. Please try again in a moment."
        }

        // Default message
        return defaultMessage
    }

    /// Default error message when we can't determine a specific issue
    private static let defaultMessage = "Something went wrong. Please try again."

    /// Get a title for the error (for alert dialogs)
    /// - Parameter error: The raw error
    /// - Returns: A short, user-friendly title
    static func title(for error: Error) -> String {
        if let appError = error as? AppError {
            return appError.errorDescription ?? "Error"
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return "No Internet"
            case .timedOut:
                return "Request Timed Out"
            case .cannotFindHost, .cannotConnectToHost:
                return "Server Unavailable"
            default:
                return "Connection Error"
            }
        }

        if error is DecodingError {
            return "Data Error"
        }

        let description = error.localizedDescription.lowercased()

        if description.contains("unauthorized") || description.contains("401") {
            return "Session Expired"
        }

        if description.contains("forbidden") || description.contains("403") {
            return "Access Denied"
        }

        if description.contains("not found") || description.contains("404") {
            return "Not Found"
        }

        return "Something Went Wrong"
    }

    /// Check if an error should prompt the user to retry
    /// - Parameter error: The raw error
    /// - Returns: true if a retry might succeed
    static func shouldShowRetry(for error: Error) -> Bool {
        if let appError = error as? AppError {
            return appError.shouldRetry
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut:
                return true
            case .cannotFindHost, .cannotConnectToHost:
                return true
            case .cancelled, .badURL:
                return false
            default:
                return true
            }
        }

        // Most errors are worth retrying
        return true
    }

    /// Check if an error should trigger a sign-out
    /// - Parameter error: The raw error
    /// - Returns: true if the user should be signed out
    static func shouldSignOut(for error: Error) -> Bool {
        if let appError = error as? AppError {
            return appError.shouldSignOut
        }

        let description = error.localizedDescription.lowercased()
        return description.contains("session") && description.contains("expired") ||
               description.contains("unauthorized") ||
               description.contains("invalid token")
    }

    /// Log an error for debugging while returning a user-friendly message
    /// - Parameters:
    ///   - error: The raw error
    ///   - context: Optional context about where the error occurred
    /// - Returns: A user-friendly message
    static func logAndMessage(for error: Error, context: String? = nil) -> String {
        // Log the technical error for debugging
        ErrorLogger.shared.logError(error, context: context)

        // Return the user-friendly message
        return message(for: error)
    }
}
