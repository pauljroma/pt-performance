//
//  AnalyticsTracker.swift
//  PTPerformance
//
//  Analytics event tracking for key user actions
//

import Foundation
import os.log

/// Analytics event tracker for monitoring user actions and feature usage
///
/// Provides a centralized interface for tracking user interactions, feature usage,
/// and performance metrics throughout the app. Events are logged locally and
/// synced to the backend for analysis.
///
/// ## Event Categories
/// - **Program Events**: Creation, editing, deletion of workout programs
/// - **Session Events**: Workout session lifecycle (start, complete, exercise completion)
/// - **AI Events**: Chat interactions, substitution suggestions, recommendations
/// - **Learning Events**: Article views, searches, video watching
/// - **Scheduling Events**: Session scheduling and rescheduling
/// - **Authentication Events**: Login, logout tracking
/// - **Error Events**: Feature and API error tracking
/// - **Performance Events**: Screen load times, slow operations
///
/// ## Usage Example
/// ```swift
/// // Track a session completion
/// AnalyticsTracker.shared.trackSessionCompleted(
///     sessionId: session.id,
///     duration: 45 * 60,
///     exerciseCount: 8,
///     completedCount: 8
/// )
/// ```
class AnalyticsTracker {

    // MARK: - Singleton

    /// Shared singleton instance
    static let shared = AnalyticsTracker()

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.ptperformance.app", category: "Analytics")
    private let errorLogger = ErrorLogger.shared

    // MARK: - Initialization

    private init() {
        logger.info("AnalyticsTracker initialized")
    }

    // MARK: - Event Tracking

    /// Tracks a generic analytics event with optional properties
    ///
    /// This is the core tracking method used by all specific event methods.
    /// Events are logged locally and asynchronously synced to the backend.
    ///
    /// - Parameters:
    ///   - event: The event name (e.g., "session_completed", "exercise_logged")
    ///   - properties: Key-value pairs of event metadata (default: empty)
    ///
    /// - Note: Events are fire-and-forget; backend sync failures are logged but don't block
    func track(event: String, properties: [String: Any] = [:]) {
        var logMessage = "[Analytics] \(event)"

        if !properties.isEmpty {
            let propsString = properties.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            logMessage += " | \(propsString)"
        }

        logger.info("\(logMessage)")

        // Log to ErrorLogger for persistence
        errorLogger.logUserAction(action: event, properties: properties)

        // Fire-and-forget backend sync — does not block the UI
        Task {
            await sendToAnalyticsBackend(event: event, properties: properties)
        }
    }

    // MARK: - Program Events

    /// Tracks when a new workout program is created
    ///
    /// - Parameters:
    ///   - exerciseCount: Total number of exercises in the program
    ///   - sessionCount: Total number of sessions in the program
    ///   - patientId: The patient ID the program was created for
    func trackProgramCreated(exerciseCount: Int, sessionCount: Int, patientId: String) {
        track(event: "program_created", properties: [
            "exercise_count": exerciseCount,
            "session_count": sessionCount,
            "patient_id": patientId
        ])
    }

    /// Tracks when a workout program is edited
    ///
    /// - Parameters:
    ///   - programId: The unique identifier of the program
    ///   - changeType: Description of the type of change made
    func trackProgramEdited(programId: String, changeType: String) {
        track(event: "program_edited", properties: [
            "program_id": programId,
            "change_type": changeType
        ])
    }

    /// Tracks when a workout program is deleted
    ///
    /// - Parameter programId: The unique identifier of the deleted program
    func trackProgramDeleted(programId: String) {
        track(event: "program_deleted", properties: [
            "program_id": programId
        ])
    }

    // MARK: - Session Events

    /// Tracks when a workout session is started
    ///
    /// - Parameters:
    ///   - sessionId: The unique identifier of the session
    ///   - exerciseCount: Number of exercises in the session
    func trackSessionStarted(sessionId: String, exerciseCount: Int) {
        track(event: "session_started", properties: [
            "session_id": sessionId,
            "exercise_count": exerciseCount
        ])
    }

    /// Tracks when a workout session is completed
    ///
    /// - Parameters:
    ///   - sessionId: The unique identifier of the session
    ///   - duration: Total time spent on the session in seconds
    ///   - exerciseCount: Total number of exercises in the session
    ///   - completedCount: Number of exercises actually completed
    func trackSessionCompleted(sessionId: String, duration: TimeInterval, exerciseCount: Int, completedCount: Int) {
        track(event: "session_completed", properties: [
            "session_id": sessionId,
            "duration_seconds": Int(duration),
            "exercise_count": exerciseCount,
            "completed_count": completedCount,
            "completion_rate": completedCount > 0 ? Double(completedCount) / Double(exerciseCount) : 0
        ])
    }

    /// Tracks when an individual exercise is completed
    ///
    /// - Parameters:
    ///   - exerciseId: The unique identifier of the exercise
    ///   - sets: Number of sets completed
    ///   - reps: Number of reps (optional, bodyweight exercises may not have reps)
    ///   - weight: Weight used in pounds (optional)
    func trackExerciseCompleted(exerciseId: String, sets: Int, reps: Int?, weight: Double?) {
        var properties: [String: Any] = [
            "exercise_id": exerciseId,
            "sets": sets
        ]

        if let reps = reps {
            properties["reps"] = reps
        }

        if let weight = weight {
            properties["weight"] = weight
        }

        track(event: "exercise_completed", properties: properties)
    }

    // MARK: - AI Chat Events

    /// Track AI chat session started
    func trackAIChatStarted(context: String) {
        track(event: "ai_chat_started", properties: [
            "context": context
        ])
    }

    /// Track AI message sent
    func trackAIMessageSent(messageLength: Int, responseTime: TimeInterval?) {
        var properties: [String: Any] = [
            "message_length": messageLength
        ]

        if let responseTime = responseTime {
            properties["response_time_ms"] = Int(responseTime * 1000)
        }

        track(event: "ai_message_sent", properties: properties)
    }

    /// Track AI substitution suggested
    func trackAISubstitutionSuggested(originalExerciseId: String, substituteCount: Int) {
        track(event: "ai_substitution_suggested", properties: [
            "original_exercise_id": originalExerciseId,
            "substitute_count": substituteCount
        ])
    }

    /// Track AI substitution accepted
    func trackAISubstitutionAccepted(originalExerciseId: String, newExerciseId: String) {
        track(event: "ai_substitution_accepted", properties: [
            "original_exercise_id": originalExerciseId,
            "new_exercise_id": newExerciseId
        ])
    }

    // MARK: - Learning Events

    /// Track article viewed
    func trackArticleViewed(articleId: String, articleTitle: String, category: String) {
        track(event: "article_viewed", properties: [
            "article_id": articleId,
            "article_title": articleTitle,
            "category": category
        ])
    }

    /// Track article searched
    func trackArticleSearched(searchQuery: String, resultCount: Int) {
        track(event: "article_searched", properties: [
            "search_query": searchQuery,
            "result_count": resultCount
        ])
    }

    /// Track video watched
    func trackVideoWatched(videoId: String, durationWatched: TimeInterval, totalDuration: TimeInterval) {
        track(event: "video_watched", properties: [
            "video_id": videoId,
            "duration_watched_seconds": Int(durationWatched),
            "total_duration_seconds": Int(totalDuration),
            "completion_percentage": totalDuration > 0 ? (durationWatched / totalDuration) * 100 : 0
        ])
    }

    // MARK: - Scheduling Events

    /// Track scheduled session created
    func trackScheduledSessionCreated(sessionDate: Date, programId: String) {
        let dateFormatter = ISO8601DateFormatter()
        track(event: "scheduled_session_created", properties: [
            "session_date": dateFormatter.string(from: sessionDate),
            "program_id": programId
        ])
    }

    /// Track scheduled session rescheduled
    func trackScheduledSessionRescheduled(sessionId: String, oldDate: Date, newDate: Date) {
        let dateFormatter = ISO8601DateFormatter()
        track(event: "scheduled_session_rescheduled", properties: [
            "session_id": sessionId,
            "old_date": dateFormatter.string(from: oldDate),
            "new_date": dateFormatter.string(from: newDate)
        ])
    }

    /// Track scheduled session cancelled
    func trackScheduledSessionCancelled(sessionId: String, reason: String?) {
        var properties: [String: Any] = [
            "session_id": sessionId
        ]

        if let reason = reason {
            properties["reason"] = reason
        }

        track(event: "scheduled_session_cancelled", properties: properties)
    }

    // MARK: - Authentication Events

    /// Track user login
    func trackUserLogin(userId: String, userType: String) {
        track(event: "user_login", properties: [
            "user_id": userId,
            "user_type": userType
        ])
    }

    /// Track user logout
    func trackUserLogout(userId: String, sessionDuration: TimeInterval) {
        track(event: "user_logout", properties: [
            "user_id": userId,
            "session_duration_seconds": Int(sessionDuration)
        ])
    }

    // MARK: - Error Events

    /// Track feature error encountered by user
    func trackFeatureError(feature: String, errorType: String, errorMessage: String) {
        track(event: "feature_error", properties: [
            "feature": feature,
            "error_type": errorType,
            "error_message": errorMessage
        ])
    }

    /// Track API error
    func trackAPIError(endpoint: String, statusCode: Int, errorMessage: String) {
        track(event: "api_error", properties: [
            "endpoint": endpoint,
            "status_code": statusCode,
            "error_message": errorMessage
        ])
    }

    // MARK: - Performance Events

    /// Track screen viewed
    func trackScreenViewed(screenName: String, loadTime: TimeInterval?) {
        var properties: [String: Any] = [
            "screen_name": screenName
        ]

        if let loadTime = loadTime {
            properties["load_time_ms"] = Int(loadTime * 1000)
        }

        track(event: "screen_viewed", properties: properties)
    }

    /// Track slow operation
    func trackSlowOperation(operationName: String, duration: TimeInterval) {
        track(event: "slow_operation", properties: [
            "operation_name": operationName,
            "duration_ms": Int(duration * 1000)
        ])
    }

    // MARK: - Backend Sync

    /// Send analytics event to backend
    /// Currently logs via ErrorLogger for persistence. When a dedicated analytics
    /// backend (e.g. PostHog, Mixpanel, or a Supabase analytics_events table) is
    /// available, replace the body of this method with the appropriate API call.
    private func sendToAnalyticsBackend(event: String, properties: [String: Any]) async {
        errorLogger.logUserAction(action: event, properties: properties)
    }
}

// MARK: - Convenience Extensions

extension AnalyticsTracker {
    /// Track view appearance with automatic load time
    func trackViewAppeared(_ viewName: String, startTime: Date) {
        let loadTime = Date().timeIntervalSince(startTime)
        trackScreenViewed(screenName: viewName, loadTime: loadTime)
    }
}
