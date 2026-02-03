//
//  DatabaseConstants.swift
//  PTPerformance
//
//  Centralized constants for database RPC parameters and table names.
//  Using constants prevents silent bugs from typos in hardcoded strings.
//

import Foundation

/// Centralized database constants to prevent typos in hardcoded strings
enum DatabaseConstants {

    // MARK: - Common RPC Parameters

    /// Common RPC parameter keys used across multiple services
    /// These map to PostgreSQL function parameters (p_ prefix convention)
    enum RPCParams {
        // Patient identification
        static let patientId = "p_patient_id"

        // Date parameters
        static let date = "p_date"
        static let startDate = "p_start_date"
        static let endDate = "p_end_date"
        static let activityDate = "p_activity_date"

        // Time/duration parameters
        static let days = "p_days"
        static let duration = "p_duration"

        // Common entity IDs
        static let recommendationId = "p_recommendation_id"
        static let sessionId = "p_session_id"
        static let templateId = "p_template_id"
        static let exerciseId = "p_exercise_id"
        static let videoId = "p_video_id"

        // Activity tracking
        static let workoutCompleted = "p_workout_completed"
        static let armCareCompleted = "p_arm_care_completed"
        static let completed = "p_completed"

        // Generic
        static let notes = "p_notes"
    }

    // MARK: - Table Names

    /// Database table names
    enum Tables {
        static let deloadRecommendations = "deload_recommendations"
        static let deloadPeriods = "deload_periods"
        static let streakRecords = "streak_records"
        static let streakHistory = "streak_history"
    }

    // MARK: - RPC Function Names

    /// Database RPC function names
    enum RPCFunctions {
        static let activateDeload = "activate_deload"
        static let isInDeloadPeriod = "is_in_deload_period"
        static let recordStreakActivity = "record_streak_activity"
        static let getStreakHistory = "get_streak_history_for_calendar"
        static let getStreakStatistics = "get_streak_statistics"
    }
}
