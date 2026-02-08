//
//  KPIMetrics.swift
//  PTPerformance
//
//  KPI Dashboard Models for X2Index
//  Tracks North Star metrics: PT WAU, Athlete WAU, Citation Coverage, Latency, Safety Events
//

import Foundation

// MARK: - KPI Dashboard

/// Complete KPI dashboard snapshot for a time period
/// North Star Guardrails:
/// - PT weekly active usage >= 65%
/// - Athlete weekly active usage >= 60%
/// - Citation coverage for AI claims >= 95%
/// - p95 summary latency <= 5s
/// - Unresolved high-severity safety incidents = 0
struct KPIDashboard: Codable, Sendable {
    let periodStart: Date
    let periodEnd: Date
    let ptMetrics: PTMetrics
    let athleteMetrics: AthleteMetrics
    let aiMetrics: AIMetrics
    let safetyMetrics: SafetyMetrics

    enum CodingKeys: String, CodingKey {
        case periodStart = "period_start"
        case periodEnd = "period_end"
        case ptMetrics = "pt_metrics"
        case athleteMetrics = "athlete_metrics"
        case aiMetrics = "ai_metrics"
        case safetyMetrics = "safety_metrics"
    }

    init(
        periodStart: Date,
        periodEnd: Date,
        ptMetrics: PTMetrics,
        athleteMetrics: AthleteMetrics,
        aiMetrics: AIMetrics,
        safetyMetrics: SafetyMetrics
    ) {
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.ptMetrics = ptMetrics
        self.athleteMetrics = athleteMetrics
        self.aiMetrics = aiMetrics
        self.safetyMetrics = safetyMetrics
    }
}

// MARK: - PT Metrics

/// Metrics for physical therapist engagement
/// Target: >= 65% weekly active usage
struct PTMetrics: Codable, Sendable {
    let totalPTs: Int
    let weeklyActivePTs: Int
    let wauPercentage: Double
    let avgPrepTimeSeconds: Double
    let briefsOpened: Int
    let plansAssigned: Int

    enum CodingKeys: String, CodingKey {
        case totalPTs = "total_pts"
        case weeklyActivePTs = "weekly_active_pts"
        case wauPercentage = "wau_percentage"
        case avgPrepTimeSeconds = "avg_prep_time_seconds"
        case briefsOpened = "briefs_opened"
        case plansAssigned = "plans_assigned"
    }

    init(
        totalPTs: Int,
        weeklyActivePTs: Int,
        wauPercentage: Double,
        avgPrepTimeSeconds: Double,
        briefsOpened: Int,
        plansAssigned: Int
    ) {
        self.totalPTs = totalPTs
        self.weeklyActivePTs = weeklyActivePTs
        self.wauPercentage = wauPercentage
        self.avgPrepTimeSeconds = avgPrepTimeSeconds
        self.briefsOpened = briefsOpened
        self.plansAssigned = plansAssigned
    }

    /// Whether PT WAU meets the target of >= 65%
    var meetsTarget: Bool {
        wauPercentage >= KPITargets.ptWauTarget
    }

    /// Status indicator for the metric
    var status: KPIStatus {
        if wauPercentage >= KPITargets.ptWauTarget {
            return .onTarget
        } else if wauPercentage >= KPITargets.ptWauTarget * 0.8 {
            return .warning
        } else {
            return .critical
        }
    }
}

// MARK: - Athlete Metrics

/// Metrics for athlete engagement
/// Target: >= 60% weekly active usage
struct AthleteMetrics: Codable, Sendable {
    let totalAthletes: Int
    let weeklyActiveAthletes: Int
    let wauPercentage: Double
    let checkInsCompleted: Int
    let taskCompletionRate: Double
    let avgStreakDays: Double

    enum CodingKeys: String, CodingKey {
        case totalAthletes = "total_athletes"
        case weeklyActiveAthletes = "weekly_active_athletes"
        case wauPercentage = "wau_percentage"
        case checkInsCompleted = "check_ins_completed"
        case taskCompletionRate = "task_completion_rate"
        case avgStreakDays = "avg_streak_days"
    }

    init(
        totalAthletes: Int,
        weeklyActiveAthletes: Int,
        wauPercentage: Double,
        checkInsCompleted: Int,
        taskCompletionRate: Double,
        avgStreakDays: Double
    ) {
        self.totalAthletes = totalAthletes
        self.weeklyActiveAthletes = weeklyActiveAthletes
        self.wauPercentage = wauPercentage
        self.checkInsCompleted = checkInsCompleted
        self.taskCompletionRate = taskCompletionRate
        self.avgStreakDays = avgStreakDays
    }

    /// Whether Athlete WAU meets the target of >= 60%
    var meetsTarget: Bool {
        wauPercentage >= KPITargets.athleteWauTarget
    }

    /// Status indicator for the metric
    var status: KPIStatus {
        if wauPercentage >= KPITargets.athleteWauTarget {
            return .onTarget
        } else if wauPercentage >= KPITargets.athleteWauTarget * 0.8 {
            return .warning
        } else {
            return .critical
        }
    }
}

// MARK: - AI Metrics

/// Metrics for AI performance and safety
/// Targets:
/// - Citation coverage >= 95%
/// - p95 latency <= 5000ms
struct AIMetrics: Codable, Sendable {
    let claimsGenerated: Int
    let citationCoverage: Double // 0.0-1.0
    let avgConfidence: Double
    let p95LatencyMs: Int
    let abstentions: Int
    let uncertaintyFlags: Int

    enum CodingKeys: String, CodingKey {
        case claimsGenerated = "claims_generated"
        case citationCoverage = "citation_coverage"
        case avgConfidence = "avg_confidence"
        case p95LatencyMs = "p95_latency_ms"
        case abstentions
        case uncertaintyFlags = "uncertainty_flags"
    }

    init(
        claimsGenerated: Int,
        citationCoverage: Double,
        avgConfidence: Double,
        p95LatencyMs: Int,
        abstentions: Int,
        uncertaintyFlags: Int
    ) {
        self.claimsGenerated = claimsGenerated
        self.citationCoverage = citationCoverage
        self.avgConfidence = avgConfidence
        self.p95LatencyMs = p95LatencyMs
        self.abstentions = abstentions
        self.uncertaintyFlags = uncertaintyFlags
    }

    /// Whether citation coverage meets the target of >= 95%
    var citationMeetsTarget: Bool {
        citationCoverage >= KPITargets.citationCoverageTarget
    }

    /// Whether p95 latency meets the target of <= 5000ms
    var latencyMeetsTarget: Bool {
        p95LatencyMs <= KPITargets.p95LatencyTargetMs
    }

    /// Status indicator for citation coverage
    var citationStatus: KPIStatus {
        if citationCoverage >= KPITargets.citationCoverageTarget {
            return .onTarget
        } else if citationCoverage >= KPITargets.citationCoverageTarget * 0.9 {
            return .warning
        } else {
            return .critical
        }
    }

    /// Status indicator for latency
    var latencyStatus: KPIStatus {
        if p95LatencyMs <= KPITargets.p95LatencyTargetMs {
            return .onTarget
        } else if p95LatencyMs <= Int(Double(KPITargets.p95LatencyTargetMs) * 1.5) {
            return .warning
        } else {
            return .critical
        }
    }

    /// Abstention rate (abstentions / claims generated)
    var abstentionRate: Double {
        guard claimsGenerated > 0 else { return 0 }
        return Double(abstentions) / Double(claimsGenerated)
    }
}

// MARK: - Safety Metrics

/// Metrics for safety incidents
/// Target: 0 unresolved high-severity incidents
struct SafetyMetrics: Codable, Sendable {
    let totalIncidents: Int
    let unresolvedHighSeverity: Int
    let escalationsTriggered: Int
    let thresholdBreaches: Int

    enum CodingKeys: String, CodingKey {
        case totalIncidents = "total_incidents"
        case unresolvedHighSeverity = "unresolved_high_severity"
        case escalationsTriggered = "escalations_triggered"
        case thresholdBreaches = "threshold_breaches"
    }

    init(
        totalIncidents: Int,
        unresolvedHighSeverity: Int,
        escalationsTriggered: Int,
        thresholdBreaches: Int
    ) {
        self.totalIncidents = totalIncidents
        self.unresolvedHighSeverity = unresolvedHighSeverity
        self.escalationsTriggered = escalationsTriggered
        self.thresholdBreaches = thresholdBreaches
    }

    /// Whether safety meets the target of 0 unresolved high-severity incidents
    var meetsTarget: Bool {
        unresolvedHighSeverity == KPITargets.unresolvedHighSeverityTarget
    }

    /// Status indicator for safety
    var status: KPIStatus {
        if unresolvedHighSeverity == 0 {
            return .onTarget
        } else {
            return .critical // Any unresolved high-severity is critical
        }
    }
}

// MARK: - KPI Targets

/// North Star guardrail targets
enum KPITargets {
    /// PT weekly active usage target: >= 65%
    static let ptWauTarget: Double = 0.65

    /// Athlete weekly active usage target: >= 60%
    static let athleteWauTarget: Double = 0.60

    /// AI citation coverage target: >= 95%
    static let citationCoverageTarget: Double = 0.95

    /// p95 summary latency target: <= 5000ms (5 seconds)
    static let p95LatencyTargetMs: Int = 5000

    /// Unresolved high-severity safety incidents target: 0
    static let unresolvedHighSeverityTarget: Int = 0

    /// AI confidence threshold for showing uncertainty indicator
    static let uncertaintyIndicatorThreshold: Double = 0.7

    /// AI confidence threshold for abstaining (requires PT review)
    static let abstentionThreshold: Double = 0.5
}

// MARK: - KPI Status

/// Status indicator for KPI metrics
enum KPIStatus: String, Codable, Sendable {
    case onTarget = "on_target"
    case warning = "warning"
    case critical = "critical"

    var displayName: String {
        switch self {
        case .onTarget: return "On Target"
        case .warning: return "Warning"
        case .critical: return "Critical"
        }
    }

    var iconName: String {
        switch self {
        case .onTarget: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }

    var colorName: String {
        switch self {
        case .onTarget: return "green"
        case .warning: return "yellow"
        case .critical: return "red"
        }
    }
}

// MARK: - KPI Event Types

/// Types of KPI events for tracking
enum KPIEventType: String, Codable, CaseIterable, Sendable {
    case briefOpened = "brief_opened"
    case checkInCompleted = "check_in_completed"
    case planAssigned = "plan_assigned"
    case aiClaimGenerated = "ai_claim_generated"
    case sessionStarted = "session_started"
    case sessionCompleted = "session_completed"
    case taskCompleted = "task_completed"

    var displayName: String {
        switch self {
        case .briefOpened: return "Brief Opened"
        case .checkInCompleted: return "Check-in Completed"
        case .planAssigned: return "Plan Assigned"
        case .aiClaimGenerated: return "AI Claim Generated"
        case .sessionStarted: return "Session Started"
        case .sessionCompleted: return "Session Completed"
        case .taskCompleted: return "Task Completed"
        }
    }
}

// MARK: - KPI Trend

/// Trend direction for KPI metrics
enum KPITrend: String, Codable, Sendable {
    case up
    case down
    case stable

    var iconName: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }

    var displayName: String {
        switch self {
        case .up: return "Trending Up"
        case .down: return "Trending Down"
        case .stable: return "Stable"
        }
    }
}

// MARK: - KPI Event

/// Individual KPI tracking event
struct KPIEvent: Codable, Identifiable, Sendable {
    let id: UUID
    let eventType: KPIEventType
    let userId: UUID?
    let athleteId: UUID?
    let metadata: [String: AnyCodableValue]?
    let durationMs: Int?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case eventType = "event_type"
        case userId = "user_id"
        case athleteId = "athlete_id"
        case metadata
        case durationMs = "duration_ms"
        case createdAt = "created_at"
    }

    init(
        id: UUID = UUID(),
        eventType: KPIEventType,
        userId: UUID? = nil,
        athleteId: UUID? = nil,
        metadata: [String: AnyCodableValue]? = nil,
        durationMs: Int? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.eventType = eventType
        self.userId = userId
        self.athleteId = athleteId
        self.metadata = metadata
        self.durationMs = durationMs
        self.createdAt = createdAt
    }
}

// MARK: - Sample Data for Previews

#if DEBUG
extension KPIDashboard {
    static let sample = KPIDashboard(
        periodStart: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
        periodEnd: Date(),
        ptMetrics: PTMetrics(
            totalPTs: 25,
            weeklyActivePTs: 18,
            wauPercentage: 0.72,
            avgPrepTimeSeconds: 180,
            briefsOpened: 156,
            plansAssigned: 42
        ),
        athleteMetrics: AthleteMetrics(
            totalAthletes: 450,
            weeklyActiveAthletes: 315,
            wauPercentage: 0.70,
            checkInsCompleted: 1250,
            taskCompletionRate: 0.82,
            avgStreakDays: 4.5
        ),
        aiMetrics: AIMetrics(
            claimsGenerated: 2400,
            citationCoverage: 0.97,
            avgConfidence: 0.85,
            p95LatencyMs: 3200,
            abstentions: 48,
            uncertaintyFlags: 120
        ),
        safetyMetrics: SafetyMetrics(
            totalIncidents: 12,
            unresolvedHighSeverity: 0,
            escalationsTriggered: 8,
            thresholdBreaches: 15
        )
    )

    static let sampleCritical = KPIDashboard(
        periodStart: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
        periodEnd: Date(),
        ptMetrics: PTMetrics(
            totalPTs: 25,
            weeklyActivePTs: 12,
            wauPercentage: 0.48,
            avgPrepTimeSeconds: 240,
            briefsOpened: 85,
            plansAssigned: 18
        ),
        athleteMetrics: AthleteMetrics(
            totalAthletes: 450,
            weeklyActiveAthletes: 225,
            wauPercentage: 0.50,
            checkInsCompleted: 800,
            taskCompletionRate: 0.65,
            avgStreakDays: 2.1
        ),
        aiMetrics: AIMetrics(
            claimsGenerated: 1800,
            citationCoverage: 0.88,
            avgConfidence: 0.72,
            p95LatencyMs: 6500,
            abstentions: 180,
            uncertaintyFlags: 320
        ),
        safetyMetrics: SafetyMetrics(
            totalIncidents: 25,
            unresolvedHighSeverity: 2,
            escalationsTriggered: 18,
            thresholdBreaches: 35
        )
    )
}
#endif
