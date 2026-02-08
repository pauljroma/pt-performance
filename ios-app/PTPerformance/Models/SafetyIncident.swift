//
//  SafetyIncident.swift
//  PTPerformance
//
//  Safety Incident Model for X2Index
//  M9: AI flags uncertainty, abstains on weak evidence, forces escalation when threshold crossed
//  Target: 0 unresolved high-severity safety incidents
//

import Foundation

// MARK: - Safety Incident

/// Represents a safety incident that requires attention
/// Used for tracking pain thresholds, vital anomalies, contradictory data, AI uncertainty, and missed escalations
struct SafetyIncident: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    let athleteId: UUID
    let incidentType: IncidentType
    let severity: Severity
    let description: String
    let triggerData: [String: AnyCodableValue]?
    let status: IncidentStatus
    let escalatedTo: UUID?
    let resolvedBy: UUID?
    let resolvedAt: Date?
    let resolutionNotes: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case athleteId = "athlete_id"
        case incidentType = "incident_type"
        case severity
        case description
        case triggerData = "trigger_data"
        case status
        case escalatedTo = "escalated_to"
        case resolvedBy = "resolved_by"
        case resolvedAt = "resolved_at"
        case resolutionNotes = "resolution_notes"
        case createdAt = "created_at"
    }

    init(
        id: UUID = UUID(),
        athleteId: UUID,
        incidentType: IncidentType,
        severity: Severity,
        description: String,
        triggerData: [String: AnyCodableValue]? = nil,
        status: IncidentStatus = .open,
        escalatedTo: UUID? = nil,
        resolvedBy: UUID? = nil,
        resolvedAt: Date? = nil,
        resolutionNotes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.athleteId = athleteId
        self.incidentType = incidentType
        self.severity = severity
        self.description = description
        self.triggerData = triggerData
        self.status = status
        self.escalatedTo = escalatedTo
        self.resolvedBy = resolvedBy
        self.resolvedAt = resolvedAt
        self.resolutionNotes = resolutionNotes
        self.createdAt = createdAt
    }

    // MARK: - Hashable Conformance

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SafetyIncident, rhs: SafetyIncident) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Incident Type

    /// Types of safety incidents
    enum IncidentType: String, Codable, CaseIterable, Sendable {
        case painThreshold = "pain_threshold"
        case vitalAnomaly = "vital_anomaly"
        case contradictoryData = "contradictory_data"
        case aiUncertainty = "ai_uncertainty"
        case missedEscalation = "missed_escalation"

        var displayName: String {
            switch self {
            case .painThreshold: return "Pain Threshold"
            case .vitalAnomaly: return "Vital Anomaly"
            case .contradictoryData: return "Contradictory Data"
            case .aiUncertainty: return "AI Uncertainty"
            case .missedEscalation: return "Missed Escalation"
            }
        }

        var icon: String {
            switch self {
            case .painThreshold: return "cross.circle.fill"
            case .vitalAnomaly: return "heart.fill"
            case .contradictoryData: return "exclamationmark.2"
            case .aiUncertainty: return "questionmark.circle.fill"
            case .missedEscalation: return "arrow.up.circle.fill"
            }
        }

        var description: String {
            switch self {
            case .painThreshold:
                return "Patient reported pain score exceeds safety threshold"
            case .vitalAnomaly:
                return "Vital signs (HRV, HR, etc.) show concerning patterns"
            case .contradictoryData:
                return "Check-in data contains contradictions requiring review"
            case .aiUncertainty:
                return "AI model confidence is too low for reliable claims"
            case .missedEscalation:
                return "A required escalation was not triggered in time"
            }
        }
    }

    // MARK: - Severity

    /// Severity levels for incidents
    enum Severity: String, Codable, CaseIterable, Sendable {
        case low
        case medium
        case high
        case critical

        var displayName: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .critical: return "Critical"
            }
        }

        var colorName: String {
            switch self {
            case .low: return "gray"
            case .medium: return "yellow"
            case .high: return "orange"
            case .critical: return "red"
            }
        }

        var icon: String {
            switch self {
            case .low: return "info.circle"
            case .medium: return "exclamationmark.triangle"
            case .high: return "exclamationmark.triangle.fill"
            case .critical: return "exclamationmark.octagon.fill"
            }
        }

        /// Priority order for sorting (lower = higher priority)
        var sortOrder: Int {
            switch self {
            case .critical: return 0
            case .high: return 1
            case .medium: return 2
            case .low: return 3
            }
        }
    }

    // MARK: - Incident Status

    /// Status of a safety incident
    enum IncidentStatus: String, Codable, CaseIterable, Sendable {
        case open
        case investigating
        case resolved
        case dismissed

        var displayName: String {
            switch self {
            case .open: return "Open"
            case .investigating: return "Investigating"
            case .resolved: return "Resolved"
            case .dismissed: return "Dismissed"
            }
        }

        var icon: String {
            switch self {
            case .open: return "circle"
            case .investigating: return "magnifyingglass.circle"
            case .resolved: return "checkmark.circle.fill"
            case .dismissed: return "xmark.circle"
            }
        }

        var colorName: String {
            switch self {
            case .open: return "red"
            case .investigating: return "yellow"
            case .resolved: return "green"
            case .dismissed: return "gray"
            }
        }

        /// Whether the incident is still active (not resolved or dismissed)
        var isActive: Bool {
            self == .open || self == .investigating
        }
    }
}

// MARK: - Convenience Extensions

extension SafetyIncident {
    /// Whether the incident is resolved
    var isResolved: Bool {
        status == .resolved || status == .dismissed
    }

    /// Whether the incident is high or critical severity
    var isHighSeverity: Bool {
        severity == .high || severity == .critical
    }

    /// Age of the incident
    var age: TimeInterval {
        Date().timeIntervalSince(createdAt)
    }

    /// Human-readable age string
    var ageString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    /// Whether this incident requires urgent attention
    var requiresUrgentAttention: Bool {
        isHighSeverity && !isResolved
    }

    /// Whether escalation is active
    var isEscalated: Bool {
        escalatedTo != nil
    }
}

// MARK: - Safety Thresholds

/// Safety thresholds for automatic incident creation
enum SafetyThresholds {
    /// Pain score threshold for high severity incident (>= 8)
    static let painScoreHigh: Int = 8

    /// Pain score threshold for medium severity incident (>= 6)
    static let painScoreMedium: Int = 6

    /// HRV drop percentage for medium severity incident (> 30%)
    static let hrvDropPercentage: Double = 0.30

    /// HRV drop percentage for high severity incident (> 50%)
    static let hrvDropPercentageHigh: Double = 0.50

    /// AI confidence threshold for uncertainty flag (< 0.7)
    static let aiConfidenceUncertain: Double = 0.7

    /// AI confidence threshold for abstention (< 0.5)
    static let aiConfidenceAbstain: Double = 0.5

    /// Maximum allowed p95 latency in milliseconds
    static let maxLatencyMs: Int = 5000

    /// Maximum hours without escalation for high-severity incidents
    static let escalationTimeoutHours: Int = 4
}

// MARK: - Safety Check Result

/// Result of a safety threshold check
struct SafetyCheckResult: Sendable {
    let incidents: [SafetyIncident]
    let shouldAbstain: Bool
    let requiresEscalation: Bool
    let warnings: [String]

    init(
        incidents: [SafetyIncident] = [],
        shouldAbstain: Bool = false,
        requiresEscalation: Bool = false,
        warnings: [String] = []
    ) {
        self.incidents = incidents
        self.shouldAbstain = shouldAbstain
        self.requiresEscalation = requiresEscalation
        self.warnings = warnings
    }

    /// Whether any issues were detected
    var hasIssues: Bool {
        !incidents.isEmpty || shouldAbstain || requiresEscalation || !warnings.isEmpty
    }

    /// Highest severity among all incidents
    var highestSeverity: SafetyIncident.Severity? {
        incidents.min(by: { $0.severity.sortOrder < $1.severity.sortOrder })?.severity
    }
}

// MARK: - Incident Resolution

/// Resolution details for closing an incident
struct IncidentResolution: Codable, Sendable {
    let incidentId: UUID
    let resolvedBy: UUID
    let notes: String
    let dismissed: Bool

    enum CodingKeys: String, CodingKey {
        case incidentId = "incident_id"
        case resolvedBy = "resolved_by"
        case notes
        case dismissed
    }

    init(
        incidentId: UUID,
        resolvedBy: UUID,
        notes: String,
        dismissed: Bool = false
    ) {
        self.incidentId = incidentId
        self.resolvedBy = resolvedBy
        self.notes = notes
        self.dismissed = dismissed
    }
}

// MARK: - Sample Data for Previews

#if DEBUG
extension SafetyIncident {
    static let samplePainThreshold = SafetyIncident(
        athleteId: UUID(),
        incidentType: .painThreshold,
        severity: .high,
        description: "Patient reported pain score of 9/10 during shoulder press exercise",
        triggerData: [
            "pain_score": .int(9),
            "exercise": .string("Shoulder Press"),
            "set_number": .int(3)
        ],
        status: .open
    )

    static let sampleVitalAnomaly = SafetyIncident(
        athleteId: UUID(),
        incidentType: .vitalAnomaly,
        severity: .medium,
        description: "HRV dropped 35% compared to 7-day baseline",
        triggerData: [
            "current_hrv": .int(42),
            "baseline_hrv": .int(65),
            "drop_percentage": .double(35.4)
        ],
        status: .investigating
    )

    static let sampleAIUncertainty = SafetyIncident(
        athleteId: UUID(),
        incidentType: .aiUncertainty,
        severity: .medium,
        description: "AI model confidence below threshold for training recommendation",
        triggerData: [
            "confidence_score": .double(0.42),
            "claim_type": .string("trainingRecommendation"),
            "abstained": .bool(true)
        ],
        status: .open
    )

    static let sampleResolved = SafetyIncident(
        athleteId: UUID(),
        incidentType: .contradictoryData,
        severity: .low,
        description: "Check-in reported high energy but low sleep quality",
        status: .resolved,
        resolvedBy: UUID(),
        resolvedAt: Date().addingTimeInterval(-3600),
        resolutionNotes: "Athlete confirmed unusual late-night event, data is accurate"
    )

    static let sampleCritical = SafetyIncident(
        athleteId: UUID(),
        incidentType: .painThreshold,
        severity: .critical,
        description: "Patient reported severe acute pain (10/10) with inability to continue exercise",
        triggerData: [
            "pain_score": .int(10),
            "exercise": .string("Deadlift"),
            "stopped_immediately": .bool(true)
        ],
        status: .open,
        escalatedTo: UUID(),
        createdAt: Date().addingTimeInterval(-1800)
    )
}
#endif
