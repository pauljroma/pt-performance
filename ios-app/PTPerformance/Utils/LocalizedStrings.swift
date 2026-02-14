//
//  LocalizedStrings.swift
//  PTPerformance
//
//  Centralized string constants for localization support.
//  Use these constants instead of hardcoded strings throughout the app.
//

import Foundation

/// Centralized string constants organized by category for easy localization.
/// Usage: `Text(LocalizedStrings.TimePeriods.week)`
enum LocalizedStrings {

    // MARK: - Time Periods

    /// Time period strings used in analytics pickers and displays
    enum TimePeriods {
        static let week = "Week"
        static let month = "Month"
        static let threeMonths = "3 Months"
        static let year = "Year"
        static let thisWeek = "This Week"
        static let lastWeek = "Last Week"
    }

    // MARK: - Loading States

    /// Loading indicator text
    enum LoadingStates {
        static let loading = "Loading..."
        static let loadingAnalytics = "Loading analytics..."
        static let loadingPrograms = "Loading programs..."
        static let loadingHistory = "Loading history..."
        static let loadingYourWeek = "Loading your week..."
        static let loadingStrengthData = "Loading strength data..."
    }

    // MARK: - Error States

    /// Error message titles and descriptions
    enum ErrorStates {
        static let couldntLoadSummary = "Couldn't Load Summary"
        static let couldntLoadHistory = "Couldn't Load History"
        static let couldntLoadData = "Couldn't load data"
        static let somethingWentWrong = "Something Went Wrong"
        static let tryAgain = "Try Again"
        static let retry = "Retry"
        static let unableToLoad = "Unable to Load"
    }

    // MARK: - Common Actions

    /// Common button and action text
    enum Common {
        static let cancel = "Cancel"
        static let save = "Save"
        static let done = "Done"
        static let delete = "Delete"
        static let edit = "Edit"
        static let add = "Add"
        static let close = "Close"
        static let next = "Next"
        static let back = "Back"
        static let confirm = "Confirm"
        static let viewHistory = "View History"
    }

    // MARK: - Section Headers

    /// Section header text used across views
    enum SectionHeaders {
        static let myPrograms = "My Programs"
        static let winsThisWeek = "Wins This Week"
        static let focusAreas = "Focus Areas"
        static let yourProgress = "Your Progress"
        static let aboutThisProgram = "About This Program"
        static let equipmentRequired = "Equipment Required"
        static let workoutSchedule = "Workout Schedule"
        static let weeklyNotifications = "Weekly Notifications"
        static let pastWeeks = "Past Weeks"
        static let adherenceTrend = "Adherence Trend"
        // ACP-1028: Weekly Summary Personalization
        static let keyWins = "Key Wins"
        static let areasToFocus = "Areas to Focus"
        static let nextWeekPlan = "Next Week Plan"
        static let weeklyInsight = "Weekly Insight"
        static let weekOverWeek = "Week over Week"
        static let personalizedForYou = "Personalized for You"
    }

    // MARK: - Empty States

    /// Empty state titles and messages
    enum EmptyStates {
        static let noDataYet = "No Data Yet"
        static let noAnalyticsDataYet = "No Analytics Data Yet"
        static let noStrengthData = "No Strength Data"
        static let noWeeklyHistoryYet = "No Weekly History Yet"
        static let signInRequired = "Sign In Required"

        // Empty state messages
        static let completeWorkoutsToSee = "Complete some workouts to see your weekly summary"
        static let completeFirstWorkout = "Complete your first workout to start tracking your progress."
        static let logWeightedExercises = "Log weighted exercises to track your strength progression over time."
    }

    // MARK: - Analytics & Stats

    /// Analytics-related labels
    enum Analytics {
        static let totalVolume = "Total Volume"
        static let avgVolume = "Avg Volume"
        static let peakWeek = "Peak Week"
        static let strengthGain = "Strength Gain"
        static let workouts = "Workouts"
        static let adherence = "Adherence"
        static let volume = "Volume"
        static let streak = "Streak"
        static let perWeek = "per week"
        static let vsLastWeek = "vs Last Week"
        static let days = "days"
    }

    // MARK: - Program Related

    /// Program section text
    enum Programs {
        static let programDetails = "Program Details"
        static let viewWeeklyWorkouts = "View Weekly Workouts"
        static let seeYourScheduleByWeek = "See your workout schedule by week"
        static let active = "active"
        static let duration = "Duration"
        static let difficulty = "Difficulty"
        static let category = "Category"
    }

    // MARK: - Status Labels

    /// Status indicator text
    enum Status {
        static let enabled = "Enabled"
        static let disabled = "Disabled"
    }

    // MARK: - Navigation Titles

    /// Navigation bar titles
    enum NavigationTitles {
        static let progress = "Progress"
        static let weeklySummary = "Weekly Summary"
        static let weeklyHistory = "Weekly History"
        static let weekDetails = "Week Details"
    }
}
