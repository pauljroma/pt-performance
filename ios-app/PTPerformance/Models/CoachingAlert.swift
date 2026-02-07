//
//  CoachingAlert.swift
//  PTPerformance
//
//  Model for coaching alerts that notify therapists of patient issues
//

import Foundation
import SwiftUI

/// Represents a coaching alert for a patient
struct CoachingAlert: Codable, Identifiable, Hashable, Equatable, Sendable {
    let id: UUID
    let patientId: UUID
    let therapistId: UUID
    let alertType: AlertType
    let severity: AlertSeverity
    let title: String
    let message: String
    let createdAt: Date
    var acknowledgedAt: Date?
    var resolvedAt: Date?
    let metadata: [String: String]?

    var isActive: Bool {
        resolvedAt == nil
    }

    var isAcknowledged: Bool {
        acknowledgedAt != nil
    }

    var isCritical: Bool {
        severity == .critical
    }

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case therapistId = "therapist_id"
        case alertType = "alert_type"
        case severity
        case title
        case message
        case createdAt = "created_at"
        case acknowledgedAt = "acknowledged_at"
        case resolvedAt = "resolved_at"
        case metadata
    }
}

// MARK: - Alert Type

extension CoachingAlert {
    enum AlertType: String, Codable, CaseIterable, Sendable {
        case adherenceDropoff = "adherence_dropoff"
        case painIncrease = "pain_increase"
        case missedSessions = "missed_sessions"
        case workloadSpike = "workload_spike"
        case recoveryIssue = "recovery_issue"
        case programCompletion = "program_completion"
        case milestoneReached = "milestone_reached"
        case rtsReadiness = "rts_readiness"
        case assessmentDue = "assessment_due"
        case custom = "custom"

        var displayName: String {
            switch self {
            case .adherenceDropoff: return "Adherence Drop"
            case .painIncrease: return "Pain Increase"
            case .missedSessions: return "Missed Sessions"
            case .workloadSpike: return "Workload Spike"
            case .recoveryIssue: return "Recovery Issue"
            case .programCompletion: return "Program Completion"
            case .milestoneReached: return "Milestone Reached"
            case .rtsReadiness: return "RTS Readiness"
            case .assessmentDue: return "Assessment Due"
            case .custom: return "Custom Alert"
            }
        }

        var icon: String {
            switch self {
            case .adherenceDropoff: return "chart.line.downtrend.xyaxis"
            case .painIncrease: return "waveform.path.ecg"
            case .missedSessions: return "calendar.badge.exclamationmark"
            case .workloadSpike: return "exclamationmark.arrow.triangle.2.circlepath"
            case .recoveryIssue: return "bed.double.fill"
            case .programCompletion: return "checkmark.seal.fill"
            case .milestoneReached: return "star.fill"
            case .rtsReadiness: return "figure.run"
            case .assessmentDue: return "list.clipboard"
            case .custom: return "bell.fill"
            }
        }

        var color: Color {
            switch self {
            case .adherenceDropoff: return .orange
            case .painIncrease: return .red
            case .missedSessions: return .yellow
            case .workloadSpike: return .red
            case .recoveryIssue: return .purple
            case .programCompletion: return .green
            case .milestoneReached: return .blue
            case .rtsReadiness: return .teal
            case .assessmentDue: return .indigo
            case .custom: return .gray
            }
        }
    }
}

// MARK: - Alert Severity

extension CoachingAlert {
    enum AlertSeverity: String, Codable, CaseIterable, Comparable, Sendable {
        case low = "LOW"
        case medium = "MEDIUM"
        case high = "HIGH"
        case critical = "CRITICAL"

        var displayName: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .critical: return "Critical"
            }
        }

        var color: Color {
            switch self {
            case .low: return .blue
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }

        var sortOrder: Int {
            switch self {
            case .low: return 0
            case .medium: return 1
            case .high: return 2
            case .critical: return 3
            }
        }

        static func < (lhs: AlertSeverity, rhs: AlertSeverity) -> Bool {
            lhs.sortOrder < rhs.sortOrder
        }
    }
}

// MARK: - Alert with Patient Info

/// Alert combined with patient information for display
struct CoachingAlertWithPatient: Identifiable {
    let alert: CoachingAlert
    let patient: Patient

    var id: UUID { alert.id }
}
