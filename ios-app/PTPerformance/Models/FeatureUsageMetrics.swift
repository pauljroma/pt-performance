//
//  FeatureUsageMetrics.swift
//  PTPerformance
//
//  ACP-964: Feature Usage Tracking
//  Defines app features, adoption stages, discovery paths, and usage statistics
//  used by FeatureUsageTracker to measure feature engagement and adoption.
//

import Foundation

// MARK: - App Feature

/// Every trackable feature in PT Performance.
///
/// Cases are organized by the app's primary navigation areas and map directly
/// to the View folders in the project. Add new features here as the app grows.
enum AppFeature: String, CaseIterable, Codable, Sendable {

    // MARK: Workout & Training
    case workoutSession = "workout_session"
    case manualWorkout = "manual_workout"
    case programBuilder = "program_builder"
    case programLibrary = "program_library"
    case exerciseLibrary = "exercise_library"
    case templates = "templates"
    case intervalTimers = "interval_timers"

    // MARK: AI & Intelligence
    case aiCoach = "ai_coach"
    case aiChat = "ai_chat"
    case exerciseSubstitution = "exercise_substitution"
    case progressiveOverloadAI = "progressive_overload_ai"
    case healthIntelligence = "health_intelligence"

    // MARK: Health & Recovery
    case readinessScore = "readiness_score"
    case recoveryTracking = "recovery_tracking"
    case healthKit = "healthkit"
    case bodyComposition = "body_composition"
    case armCare = "arm_care"
    case shoulderHealth = "shoulder_health"
    case wellness = "wellness"

    // MARK: Progress & Analytics
    case progressTracking = "progress_tracking"
    case performanceDashboard = "performance_dashboard"
    case reports = "reports"
    case history = "history"
    case streaks = "streaks"
    case achievements = "achievements"
    case x2Index = "x2_index"

    // MARK: Nutrition
    case nutritionTracking = "nutrition_tracking"
    case mealPlanning = "meal_planning"
    case supplements = "supplements"
    case fasting = "fasting"

    // MARK: Education & Content
    case learningContent = "learning_content"
    case evidenceLibrary = "evidence_library"
    case exerciseVideos = "exercise_videos"

    // MARK: Social & Engagement
    case socialSharing = "social_sharing"
    case journal = "journal"
    case dailyCheckIn = "daily_check_in"

    // MARK: Scheduling & Planning
    case scheduling = "scheduling"
    case timeline = "timeline"

    // MARK: Clinical (PT Mode)
    case soapNotes = "soap_notes"
    case patientManagement = "patient_management"
    case rtsProtocol = "rts_protocol"
    case clinicalAssessment = "clinical_assessment"
    case outcomeMeasures = "outcome_measures"

    // MARK: Baseball Specialization
    case baseballPack = "baseball_pack"

    /// Human-readable display name for dashboards and reports.
    var displayName: String {
        switch self {
        case .workoutSession:        return "Workout Session"
        case .manualWorkout:         return "Manual Workout"
        case .programBuilder:        return "Program Builder"
        case .programLibrary:        return "Program Library"
        case .exerciseLibrary:       return "Exercise Library"
        case .templates:             return "Templates"
        case .intervalTimers:        return "Interval Timers"
        case .aiCoach:               return "AI Coach"
        case .aiChat:                return "AI Chat"
        case .exerciseSubstitution:  return "Exercise Substitution"
        case .progressiveOverloadAI: return "Progressive Overload AI"
        case .healthIntelligence:    return "Health Intelligence"
        case .readinessScore:        return "Readiness Score"
        case .recoveryTracking:      return "Recovery Tracking"
        case .healthKit:             return "HealthKit"
        case .bodyComposition:       return "Body Composition"
        case .armCare:               return "Arm Care"
        case .shoulderHealth:        return "Shoulder Health"
        case .wellness:              return "Wellness"
        case .progressTracking:      return "Progress Tracking"
        case .performanceDashboard:  return "Performance Dashboard"
        case .reports:               return "Reports"
        case .history:               return "History"
        case .streaks:               return "Streaks"
        case .achievements:          return "Achievements"
        case .x2Index:               return "X2 Index"
        case .nutritionTracking:     return "Nutrition Tracking"
        case .mealPlanning:          return "Meal Planning"
        case .supplements:           return "Supplements"
        case .fasting:               return "Fasting"
        case .learningContent:       return "Learning Content"
        case .evidenceLibrary:       return "Evidence Library"
        case .exerciseVideos:        return "Exercise Videos"
        case .socialSharing:         return "Social Sharing"
        case .journal:               return "Journal"
        case .dailyCheckIn:          return "Daily Check-In"
        case .scheduling:            return "Scheduling"
        case .timeline:              return "Timeline"
        case .soapNotes:             return "SOAP Notes"
        case .patientManagement:     return "Patient Management"
        case .rtsProtocol:           return "RTS Protocol"
        case .clinicalAssessment:    return "Clinical Assessment"
        case .outcomeMeasures:       return "Outcome Measures"
        case .baseballPack:          return "Baseball Pack"
        }
    }

    /// The feature category, used for grouping in reports and dashboards.
    var category: FeatureCategory {
        switch self {
        case .workoutSession, .manualWorkout, .programBuilder, .programLibrary,
             .exerciseLibrary, .templates, .intervalTimers:
            return .workoutTraining
        case .aiCoach, .aiChat, .exerciseSubstitution, .progressiveOverloadAI,
             .healthIntelligence:
            return .aiIntelligence
        case .readinessScore, .recoveryTracking, .healthKit, .bodyComposition,
             .armCare, .shoulderHealth, .wellness:
            return .healthRecovery
        case .progressTracking, .performanceDashboard, .reports, .history,
             .streaks, .achievements, .x2Index:
            return .progressAnalytics
        case .nutritionTracking, .mealPlanning, .supplements, .fasting:
            return .nutrition
        case .learningContent, .evidenceLibrary, .exerciseVideos:
            return .educationContent
        case .socialSharing, .journal, .dailyCheckIn:
            return .socialEngagement
        case .scheduling, .timeline:
            return .schedulingPlanning
        case .soapNotes, .patientManagement, .rtsProtocol, .clinicalAssessment,
             .outcomeMeasures:
            return .clinical
        case .baseballPack:
            return .specialization
        }
    }
}

// MARK: - Feature Category

/// High-level grouping of features for aggregate reporting.
enum FeatureCategory: String, CaseIterable, Codable, Sendable {
    case workoutTraining = "workout_training"
    case aiIntelligence = "ai_intelligence"
    case healthRecovery = "health_recovery"
    case progressAnalytics = "progress_analytics"
    case nutrition = "nutrition"
    case educationContent = "education_content"
    case socialEngagement = "social_engagement"
    case schedulingPlanning = "scheduling_planning"
    case clinical = "clinical"
    case specialization = "specialization"

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .workoutTraining:    return "Workout & Training"
        case .aiIntelligence:     return "AI & Intelligence"
        case .healthRecovery:     return "Health & Recovery"
        case .progressAnalytics:  return "Progress & Analytics"
        case .nutrition:          return "Nutrition"
        case .educationContent:   return "Education & Content"
        case .socialEngagement:   return "Social & Engagement"
        case .schedulingPlanning: return "Scheduling & Planning"
        case .clinical:           return "Clinical"
        case .specialization:     return "Specialization"
        }
    }
}

// MARK: - Feature Action

/// The type of interaction a user has with a feature.
enum FeatureAction: String, CaseIterable, Codable, Sendable {
    /// User navigated to or saw the feature for the first time.
    case discovered = "discovered"
    /// User actively interacted with the feature (opened, tapped, browsed).
    case used = "used"
    /// User completed the feature's primary workflow (e.g. finished a workout, sent a message).
    case completed = "completed"
}

// MARK: - Discovery Source

/// How the user found or navigated to a feature.
enum DiscoverySource: String, CaseIterable, Codable, Sendable {
    /// User tapped a tab in the main tab bar.
    case tabBar = "tab_bar"
    /// User tapped a card or link on the Today/Home hub.
    case todayHub = "today_hub"
    /// User followed a deep link from a push notification.
    case pushNotification = "push_notification"
    /// User tapped a search result.
    case search = "search"
    /// User followed a recommendation from the AI coach.
    case aiRecommendation = "ai_recommendation"
    /// User navigated from the onboarding flow.
    case onboarding = "onboarding"
    /// User tapped an in-app upsell or paywall CTA.
    case upsell = "upsell"
    /// User tapped a related feature link within another feature.
    case crossFeatureLink = "cross_feature_link"
    /// User accessed the feature via a deep link URL.
    case deepLink = "deep_link"
    /// User tapped a widget on the home screen.
    case widget = "widget"
    /// Source could not be determined or was not specified.
    case unknown = "unknown"
}

// MARK: - Adoption Stage

/// A user's adoption level for a specific feature, derived from usage count.
///
/// Stages progress as usage increases:
/// - `new`: Never used the feature
/// - `firstUse`: Used the feature exactly once
/// - `repeatUser`: Used the feature 2-9 times
/// - `powerUser`: Used the feature 10 or more times
enum AdoptionStage: String, CaseIterable, Codable, Sendable, Comparable {
    /// User has never interacted with this feature.
    case new = "new"
    /// User has used this feature exactly once.
    case firstUse = "first_use"
    /// User has used this feature 2-9 times.
    case repeatUser = "repeat_user"
    /// User has used this feature 10+ times.
    case powerUser = "power_user"

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .new:        return "New"
        case .firstUse:   return "First Use"
        case .repeatUser: return "Repeat User"
        case .powerUser:  return "Power User"
        }
    }

    /// Determines the adoption stage for a given total-use count.
    static func stage(forTotalUses count: Int) -> AdoptionStage {
        switch count {
        case 0:     return .new
        case 1:     return .firstUse
        case 2...9: return .repeatUser
        default:    return .powerUser
        }
    }

    // MARK: Comparable

    private var sortOrder: Int {
        switch self {
        case .new:        return 0
        case .firstUse:   return 1
        case .repeatUser: return 2
        case .powerUser:  return 3
        }
    }

    static func < (lhs: AdoptionStage, rhs: AdoptionStage) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

// MARK: - Feature Usage Record

/// A single timestamped record of a feature interaction.
struct FeatureUsageRecord: Codable, Sendable {
    /// Unique identifier for this record.
    let id: String
    /// The feature that was used.
    let feature: AppFeature
    /// The type of interaction.
    let action: FeatureAction
    /// When the interaction occurred.
    let timestamp: Date
    /// How the user arrived at the feature (nil if not tracked).
    let discoverySource: DiscoverySource?
    /// Feature-specific metadata (e.g. exercise count, message length).
    let metadata: [String: String]

    enum CodingKeys: String, CodingKey {
        case id
        case feature
        case action
        case timestamp
        case discoverySource = "discovery_source"
        case metadata
    }

    init(
        id: String = UUID().uuidString,
        feature: AppFeature,
        action: FeatureAction,
        timestamp: Date = Date(),
        discoverySource: DiscoverySource? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.feature = feature
        self.action = action
        self.timestamp = timestamp
        self.discoverySource = discoverySource
        self.metadata = metadata
    }
}

// MARK: - Feature Usage Summary

/// Aggregated usage statistics for a single feature, computed from persisted records.
struct FeatureUsageSummary: Codable, Sendable {
    /// The feature these stats describe.
    let feature: AppFeature
    /// Total number of interactions across all action types.
    let totalUses: Int
    /// Breakdown of interactions by action type.
    let usesByAction: [FeatureAction: Int]
    /// When the user first interacted with this feature (nil if never used).
    let firstUsedDate: Date?
    /// When the user most recently interacted with this feature (nil if never used).
    let lastUsedDate: Date?
    /// Current adoption stage derived from total uses.
    let adoptionStage: AdoptionStage
    /// Number of distinct calendar days the feature was used.
    let distinctDaysUsed: Int
    /// Which discovery sources led the user to this feature, with counts.
    let discoverySourceCounts: [DiscoverySource: Int]

    enum CodingKeys: String, CodingKey {
        case feature
        case totalUses = "total_uses"
        case usesByAction = "uses_by_action"
        case firstUsedDate = "first_used_date"
        case lastUsedDate = "last_used_date"
        case adoptionStage = "adoption_stage"
        case distinctDaysUsed = "distinct_days_used"
        case discoverySourceCounts = "discovery_source_counts"
    }
}

// MARK: - Feature Adoption Report

/// A snapshot of feature adoption across the entire app for reporting and dashboards.
struct FeatureAdoptionReport: Codable, Sendable {
    /// When this report was generated.
    let generatedAt: Date
    /// Per-feature summaries keyed by feature raw value.
    let featureSummaries: [String: FeatureUsageSummary]
    /// Count of features at each adoption stage.
    let adoptionDistribution: [AdoptionStage: Int]
    /// Count of features in each category that have been used at least once.
    let categoryAdoption: [FeatureCategory: Int]
    /// Top discovery sources across all features, sorted by total count descending.
    let topDiscoverySources: [DiscoverySource: Int]
    /// Total features tracked.
    let totalFeaturesTracked: Int
    /// Total features that have been used at least once.
    let totalFeaturesAdopted: Int

    enum CodingKeys: String, CodingKey {
        case generatedAt = "generated_at"
        case featureSummaries = "feature_summaries"
        case adoptionDistribution = "adoption_distribution"
        case categoryAdoption = "category_adoption"
        case topDiscoverySources = "top_discovery_sources"
        case totalFeaturesTracked = "total_features_tracked"
        case totalFeaturesAdopted = "total_features_adopted"
    }
}
