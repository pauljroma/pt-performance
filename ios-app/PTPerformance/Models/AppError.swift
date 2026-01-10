//
//  AppError.swift
//  PTPerformance
//
//  Build 95 - Agent 9: Centralized error types with user-friendly messages
//

import Foundation

/// User-friendly error types for the PT Performance app
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
