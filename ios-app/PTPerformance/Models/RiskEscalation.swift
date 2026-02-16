//
//  RiskEscalation.swift
//  PTPerformance
//
//  Model for Risk Escalation System (M4) - X2Index Command Center
//  Alerts therapists when athletes show concerning safety patterns
//

import Foundation
import SwiftUI

// MARK: - Risk Escalation Model

/// Represents a risk escalation alert for a patient requiring therapist attention
struct RiskEscalation: Identifiable, Codable, Hashable, Equatable, Sendable {
    let id: UUID
    let patientId: UUID
    let therapistId: UUID
    let escalationType: EscalationType
    let severity: EscalationSeverity
    let triggerData: [String: AnyCodableValue]
    let message: String
    let recommendation: String
    let createdAt: Date
    var acknowledgedAt: Date?
    var acknowledgedBy: UUID?
    var resolvedAt: Date?
    var resolutionNotes: String?
    let status: EscalationStatus

    /// Whether the escalation is still active (not resolved)
    var isActive: Bool {
        resolvedAt == nil
    }

    /// Whether the escalation has been acknowledged
    var isAcknowledged: Bool {
        acknowledgedAt != nil
    }

    /// Whether this requires immediate attention
    var requiresImmediateAttention: Bool {
        severity == .critical && !isAcknowledged
    }

    /// Time since the escalation was created
    var timeSinceCreation: TimeInterval {
        Date().timeIntervalSince(createdAt)
    }

    /// Human-readable time since creation
    var timeSinceCreationText: String {
        let hours = Int(timeSinceCreation / 3600)
        if hours < 1 {
            let minutes = Int(timeSinceCreation / 60)
            return "\(minutes)m ago"
        } else if hours < 24 {
            return "\(hours)h ago"
        } else {
            let days = hours / 24
            return "\(days)d ago"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case therapistId = "therapist_id"
        case escalationType = "escalation_type"
        case severity
        case triggerData = "trigger_data"
        case message
        case recommendation
        case createdAt = "created_at"
        case acknowledgedAt = "acknowledged_at"
        case acknowledgedBy = "acknowledged_by"
        case resolvedAt = "resolved_at"
        case resolutionNotes = "resolution_notes"
        case status
    }
}

// MARK: - Escalation Type

/// Types of risk escalations that can be triggered
enum EscalationType: String, Codable, CaseIterable, Sendable {
    case lowRecovery = "low_recovery"           // Recovery <40% for 3+ days
    case painSpike = "pain_spike"               // Pain jumps 3+ points
    case missedSessions = "missed_sessions"     // 3+ consecutive misses
    case abnormalVitals = "abnormal_vitals"     // HR/HRV out of range
    case noCheckIn = "no_check_in"              // No check-in for 5+ days
    case adherenceDropoff = "adherence_drop"    // Sudden adherence decline
    case workloadSpike = "workload_spike"       // Acute:chronic workload ratio spike
    case sleepDeficit = "sleep_deficit"         // Chronic sleep deprivation
    case stressElevation = "stress_elevation"   // Sustained high stress levels
    case unknown = "unknown"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Self(rawValue: rawValue) ?? .unknown
    }

    /// Human-readable display name
    var displayName: String {
        switch self {
        case .lowRecovery:
            return "Low Recovery"
        case .painSpike:
            return "Pain Spike"
        case .missedSessions:
            return "Missed Sessions"
        case .abnormalVitals:
            return "Abnormal Vitals"
        case .noCheckIn:
            return "No Check-In"
        case .adherenceDropoff:
            return "Adherence Drop"
        case .workloadSpike:
            return "Workload Spike"
        case .sleepDeficit:
            return "Sleep Deficit"
        case .stressElevation:
            return "Stress Elevation"
        case .unknown:
            return "Unknown"
        }
    }

    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .lowRecovery:
            return "battery.25"
        case .painSpike:
            return "waveform.path.ecg"
        case .missedSessions:
            return "calendar.badge.exclamationmark"
        case .abnormalVitals:
            return "heart.text.square"
        case .noCheckIn:
            return "person.crop.circle.badge.questionmark"
        case .adherenceDropoff:
            return "chart.line.downtrend.xyaxis"
        case .workloadSpike:
            return "exclamationmark.arrow.triangle.2.circlepath"
        case .sleepDeficit:
            return "moon.zzz"
        case .stressElevation:
            return "brain.head.profile"
        case .unknown:
            return "questionmark.diamond"
        }
    }

    /// Color associated with this escalation type
    var color: Color {
        switch self {
        case .lowRecovery:
            return .orange
        case .painSpike:
            return .red
        case .missedSessions:
            return .yellow
        case .abnormalVitals:
            return .red
        case .noCheckIn:
            return .purple
        case .adherenceDropoff:
            return .orange
        case .workloadSpike:
            return .red
        case .sleepDeficit:
            return .indigo
        case .stressElevation:
            return .pink
        case .unknown:
            return .gray
        }
    }

    /// Description of what triggers this escalation type
    var triggerDescription: String {
        switch self {
        case .lowRecovery:
            return "Recovery score below 40% for 3+ consecutive days"
        case .painSpike:
            return "Pain level increased by 3+ points in a single day"
        case .missedSessions:
            return "3+ consecutive scheduled sessions missed"
        case .abnormalVitals:
            return "Heart rate or HRV significantly outside normal range"
        case .noCheckIn:
            return "No daily check-in recorded for 5+ days"
        case .adherenceDropoff:
            return "Adherence dropped by 30%+ in the past week"
        case .workloadSpike:
            return "Acute:chronic workload ratio exceeded 1.5"
        case .sleepDeficit:
            return "Average sleep below 5 hours for 3+ nights"
        case .stressElevation:
            return "Stress level at 8+ for 3+ consecutive days"
        case .unknown:
            return "Unknown escalation type"
        }
    }
}

// MARK: - Escalation Severity

/// Severity levels for risk escalations
enum EscalationSeverity: String, Codable, CaseIterable, Comparable, Sendable {
    case critical = "critical"  // Immediate attention required
    case high = "high"          // Same day response needed
    case medium = "medium"      // Within 48 hours
    case low = "low"            // FYI - informational
    case unknown = "unknown"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Self(rawValue: rawValue) ?? .unknown
    }

    /// Human-readable display name
    var displayName: String {
        switch self {
        case .critical:
            return "Critical"
        case .high:
            return "High"
        case .medium:
            return "Medium"
        case .low:
            return "Low"
        case .unknown:
            return "Unknown"
        }
    }

    /// Color associated with this severity
    var color: Color {
        switch self {
        case .critical:
            return .red
        case .high:
            return .orange
        case .medium:
            return .yellow
        case .low:
            return .blue
        case .unknown:
            return .gray
        }
    }

    /// Background color for cards (lighter variant)
    var backgroundColor: Color {
        switch self {
        case .critical:
            return Color.red.opacity(0.15)
        case .high:
            return Color.orange.opacity(0.15)
        case .medium:
            return Color.yellow.opacity(0.15)
        case .low:
            return Color.blue.opacity(0.1)
        case .unknown:
            return Color.gray.opacity(0.1)
        }
    }

    /// Expected response time description
    var responseTimeDescription: String {
        switch self {
        case .critical:
            return "Immediate"
        case .high:
            return "Today"
        case .medium:
            return "Within 48h"
        case .low:
            return "When available"
        case .unknown:
            return "Unknown"
        }
    }

    /// Sort order for prioritization (higher = more urgent)
    var sortOrder: Int {
        switch self {
        case .critical:
            return 4
        case .high:
            return 3
        case .medium:
            return 2
        case .low:
            return 1
        case .unknown:
            return 0
        }
    }

    static func < (lhs: EscalationSeverity, rhs: EscalationSeverity) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

// MARK: - Escalation Status

/// Status of a risk escalation
enum EscalationStatus: String, Codable, CaseIterable, Sendable {
    case pending = "pending"            // Awaiting acknowledgment
    case acknowledged = "acknowledged"  // Therapist has seen it
    case resolved = "resolved"          // Issue has been addressed
    case dismissed = "dismissed"        // Marked as false positive
    case unknown = "unknown"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Self(rawValue: rawValue) ?? .unknown
    }

    /// Human-readable display name
    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .acknowledged:
            return "Acknowledged"
        case .resolved:
            return "Resolved"
        case .dismissed:
            return "Dismissed"
        case .unknown:
            return "Unknown"
        }
    }

    /// Color for status badge
    var color: Color {
        switch self {
        case .pending:
            return .red
        case .acknowledged:
            return .orange
        case .resolved:
            return .green
        case .dismissed:
            return .gray
        case .unknown:
            return .gray
        }
    }

    /// Icon for status
    var iconName: String {
        switch self {
        case .pending:
            return "exclamationmark.circle.fill"
        case .acknowledged:
            return "eye.fill"
        case .resolved:
            return "checkmark.circle.fill"
        case .dismissed:
            return "xmark.circle.fill"
        case .unknown:
            return "questionmark.circle"
        }
    }
}

// MARK: - Risk Escalation with Patient Info

/// Escalation combined with patient information for display
struct RiskEscalationWithPatient: Identifiable, Sendable {
    let escalation: RiskEscalation
    let patient: Patient

    var id: UUID { escalation.id }
}

// MARK: - Escalation Summary

/// Summary of escalations for a therapist's dashboard
struct EscalationSummary: Codable, Equatable, Sendable {
    let totalActive: Int
    let criticalCount: Int
    let highCount: Int
    let mediumCount: Int
    let lowCount: Int
    let unacknowledgedCount: Int
    let patientsAffected: Int
    let oldestUnacknowledgedDate: Date?

    /// Whether there are any urgent escalations
    var hasUrgentEscalations: Bool {
        criticalCount > 0 || highCount > 0
    }

    /// Empty summary
    static let empty = EscalationSummary(
        totalActive: 0,
        criticalCount: 0,
        highCount: 0,
        mediumCount: 0,
        lowCount: 0,
        unacknowledgedCount: 0,
        patientsAffected: 0,
        oldestUnacknowledgedDate: nil
    )

    enum CodingKeys: String, CodingKey {
        case totalActive = "total_active"
        case criticalCount = "critical_count"
        case highCount = "high_count"
        case mediumCount = "medium_count"
        case lowCount = "low_count"
        case unacknowledgedCount = "unacknowledged_count"
        case patientsAffected = "patients_affected"
        case oldestUnacknowledgedDate = "oldest_unacknowledged_date"
    }
}

// MARK: - Escalation Filter

/// Filter options for the escalation queue
struct EscalationFilter: Equatable, Sendable {
    var severities: Set<EscalationSeverity> = Set(EscalationSeverity.allCases)
    var types: Set<EscalationType> = Set(EscalationType.allCases)
    var statuses: Set<EscalationStatus> = [.pending, .acknowledged]
    var patientId: UUID?

    /// Whether any filters are active (not showing all)
    var isFiltered: Bool {
        severities.count < EscalationSeverity.allCases.count ||
        types.count < EscalationType.allCases.count ||
        statuses.count < 2 ||
        patientId != nil
    }

    /// Reset to default (show all active)
    mutating func reset() {
        severities = Set(EscalationSeverity.allCases)
        types = Set(EscalationType.allCases)
        statuses = [.pending, .acknowledged]
        patientId = nil
    }

    /// Filter for critical only
    static var criticalOnly: EscalationFilter {
        var filter = EscalationFilter()
        filter.severities = [.critical]
        return filter
    }

    /// Filter for unacknowledged only
    static var pendingOnly: EscalationFilter {
        var filter = EscalationFilter()
        filter.statuses = [.pending]
        return filter
    }
}
