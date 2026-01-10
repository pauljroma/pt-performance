//
//  ModeFeature.swift
//  PTPerformance
//
//  Created by Claude (BUILD 115) on 2026-01-02.
//  Feature visibility per mode
//

import Foundation

/// Feature definition per mode
struct ModeFeature: Codable, Identifiable {
    let id: String
    let mode: Mode
    let featureKey: String
    let featureName: String
    let featureDescription: String?
    let enabled: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case mode
        case featureKey = "feature_key"
        case featureName = "feature_name"
        case featureDescription = "feature_description"
        case enabled
    }
}

/// Known feature keys (for compile-time safety)
enum FeatureKey: String {
    // REHAB features
    case painTracking = "pain_tracking"
    case romExercises = "rom_exercises"
    case safetyAlerts = "safety_alerts"
    case ptMessaging = "pt_messaging"
    case progressPhotos = "progress_photos"
    case functionTests = "function_tests"

    // STRENGTH features
    case prTracking = "pr_tracking"
    case volumeTrends = "volume_trends"
    case habitStreaks = "habit_streaks"
    case progressiveOverload = "progressive_overload"
    case workoutCalendar = "workout_calendar"
    case bodyComp = "body_comp"

    // PERFORMANCE features
    case readinessScore = "readiness_score"
    case periodization = "periodization"
    case teamManagement = "team_management"
    case competitionPrep = "competition_prep"
    case advancedAnalytics = "advanced_analytics"
    case videoAnalysis = "video_analysis"
}
