//
//  SafetyRule.swift
//  PTPerformance
//
//  Clinical Safety Checks - Safety rule definitions for automated patient monitoring
//

import SwiftUI

// MARK: - Safety Rule Type

/// Types of safety rules for automated patient monitoring
enum SafetyRuleType: String, Codable, CaseIterable, Identifiable {
    case painThreshold = "pain_threshold"
    case adherenceDropoff = "adherence_dropoff"
    case missedSessions = "missed_sessions"
    case velocityDecline = "velocity_decline"
    case romRegression = "rom_regression"
    case workloadSpike = "workload_spike"
    case noCheckIn = "no_check_in"
    case postOpMilestone = "post_op_milestone"
    case custom = "custom"

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .painThreshold: return "Pain Threshold"
        case .adherenceDropoff: return "Adherence Drop-off"
        case .missedSessions: return "Missed Sessions"
        case .velocityDecline: return "Velocity Decline"
        case .romRegression: return "ROM Regression"
        case .workloadSpike: return "Workload Spike"
        case .noCheckIn: return "No Check-In"
        case .postOpMilestone: return "Post-Op Milestone"
        case .custom: return "Custom Rule"
        }
    }

    /// Description of what this rule monitors
    var ruleDescription: String {
        switch self {
        case .painThreshold:
            return "Triggers when patient reports pain above a threshold"
        case .adherenceDropoff:
            return "Triggers when adherence drops below target percentage"
        case .missedSessions:
            return "Triggers after consecutive missed sessions"
        case .velocityDecline:
            return "Triggers when throwing velocity drops from baseline"
        case .romRegression:
            return "Triggers when range of motion decreases"
        case .workloadSpike:
            return "Triggers when workload increases too rapidly"
        case .noCheckIn:
            return "Triggers after days without patient check-in"
        case .postOpMilestone:
            return "Triggers for post-operative milestone reviews"
        case .custom:
            return "Custom rule with configurable conditions"
        }
    }

    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .painThreshold: return "exclamationmark.triangle.fill"
        case .adherenceDropoff: return "chart.line.downtrend.xyaxis"
        case .missedSessions: return "calendar.badge.exclamationmark"
        case .velocityDecline: return "speedometer"
        case .romRegression: return "figure.flexibility"
        case .workloadSpike: return "chart.line.uptrend.xyaxis"
        case .noCheckIn: return "person.crop.circle.badge.questionmark"
        case .postOpMilestone: return "cross.circle.fill"
        case .custom: return "gearshape.fill"
        }
    }

    /// Color for UI display
    var color: Color {
        switch self {
        case .painThreshold: return .red
        case .adherenceDropoff: return .orange
        case .missedSessions: return .yellow
        case .velocityDecline: return .purple
        case .romRegression: return .blue
        case .workloadSpike: return .pink
        case .noCheckIn: return .gray
        case .postOpMilestone: return .teal
        case .custom: return .indigo
        }
    }

    /// Default metric unit for this rule type
    var defaultUnit: String? {
        switch self {
        case .painThreshold: return "pain scale"
        case .adherenceDropoff: return "%"
        case .missedSessions: return "sessions"
        case .velocityDecline: return "mph"
        case .romRegression: return "degrees"
        case .workloadSpike: return "%"
        case .noCheckIn: return "days"
        case .postOpMilestone: return "weeks"
        case .custom: return nil
        }
    }
}

// MARK: - Comparison Operator

/// Operators for rule condition comparisons
enum ComparisonOperator: String, Codable, CaseIterable, Identifiable {
    case greaterThan = "gt"
    case greaterThanOrEqual = "gte"
    case lessThan = "lt"
    case lessThanOrEqual = "lte"
    case equal = "eq"
    case notEqual = "neq"

    var id: String { rawValue }

    /// Display symbol for UI
    var symbol: String {
        switch self {
        case .greaterThan: return ">"
        case .greaterThanOrEqual: return ">="
        case .lessThan: return "<"
        case .lessThanOrEqual: return "<="
        case .equal: return "="
        case .notEqual: return "!="
        }
    }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .greaterThan: return "Greater than"
        case .greaterThanOrEqual: return "Greater than or equal"
        case .lessThan: return "Less than"
        case .lessThanOrEqual: return "Less than or equal"
        case .equal: return "Equal to"
        case .notEqual: return "Not equal to"
        }
    }

    /// Evaluate the condition
    func evaluate(value: Double, threshold: Double) -> Bool {
        switch self {
        case .greaterThan: return value > threshold
        case .greaterThanOrEqual: return value >= threshold
        case .lessThan: return value < threshold
        case .lessThanOrEqual: return value <= threshold
        case .equal: return value == threshold
        case .notEqual: return value != threshold
        }
    }
}

// MARK: - Rule Condition

/// Condition definition for a safety rule
struct RuleCondition: Codable, Equatable, Hashable {
    let metric: String
    let `operator`: ComparisonOperator
    let threshold: Double
    let unit: String?
    let lookbackDays: Int?

    enum CodingKeys: String, CodingKey {
        case metric
        case `operator`
        case threshold
        case unit
        case lookbackDays = "lookback_days"
    }

    /// Formatted condition description
    var description: String {
        let unitSuffix = unit.map { " \($0)" } ?? ""
        let lookbackSuffix = lookbackDays.map { " (last \($0) days)" } ?? ""
        return "\(metric) \(`operator`.symbol) \(Int(threshold))\(unitSuffix)\(lookbackSuffix)"
    }
}

// MARK: - Safety Rule

/// A safety rule for automated patient monitoring
struct SafetyRule: Codable, Identifiable, Hashable, Equatable {
    let id: UUID
    let therapistId: UUID
    let name: String
    let ruleType: SafetyRuleType
    let description: String?
    let condition: RuleCondition
    let isEnabled: Bool
    let appliesToAllPatients: Bool
    let patientIds: [UUID]?
    let programIds: [UUID]?
    let priority: Int
    let cooldownHours: Int?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case therapistId = "therapist_id"
        case name
        case ruleType = "rule_type"
        case description
        case condition
        case isEnabled = "is_enabled"
        case appliesToAllPatients = "applies_to_all_patients"
        case patientIds = "patient_ids"
        case programIds = "program_ids"
        case priority
        case cooldownHours = "cooldown_hours"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Computed Properties

    /// Icon name based on rule type
    var iconName: String {
        ruleType.iconName
    }

    /// Color based on rule type
    var color: Color {
        ruleType.color
    }

    /// Formatted priority display
    var priorityLabel: String {
        switch priority {
        case 1: return "Critical"
        case 2: return "High"
        case 3: return "Medium"
        default: return "Low"
        }
    }

    /// Priority color
    var priorityColor: Color {
        switch priority {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        default: return .gray
        }
    }

    /// Scope description for UI
    var scopeDescription: String {
        if appliesToAllPatients {
            return "All patients"
        } else if let patientIds = patientIds, !patientIds.isEmpty {
            return "\(patientIds.count) patient\(patientIds.count == 1 ? "" : "s")"
        } else if let programIds = programIds, !programIds.isEmpty {
            return "\(programIds.count) program\(programIds.count == 1 ? "" : "s")"
        }
        return "No patients assigned"
    }

    /// Cooldown period formatted
    var cooldownDescription: String? {
        guard let hours = cooldownHours else { return nil }
        if hours >= 24 {
            let days = hours / 24
            return "\(days) day\(days == 1 ? "" : "s")"
        }
        return "\(hours) hour\(hours == 1 ? "" : "s")"
    }
}

// MARK: - Safety Rule Input

/// Input model for creating/updating safety rules
struct SafetyRuleInput: Codable {
    var name: String
    var ruleType: String
    var description: String?
    var condition: RuleCondition
    var isEnabled: Bool
    var appliesToAllPatients: Bool
    var patientIds: [String]?
    var programIds: [String]?
    var priority: Int
    var cooldownHours: Int?

    enum CodingKeys: String, CodingKey {
        case name
        case ruleType = "rule_type"
        case description
        case condition
        case isEnabled = "is_enabled"
        case appliesToAllPatients = "applies_to_all_patients"
        case patientIds = "patient_ids"
        case programIds = "program_ids"
        case priority
        case cooldownHours = "cooldown_hours"
    }
}

// MARK: - Sample Data

#if DEBUG
extension SafetyRule {
    static let sample = SafetyRule(
        id: UUID(),
        therapistId: UUID(),
        name: "High Pain Alert",
        ruleType: .painThreshold,
        description: "Alert when patient reports pain 7 or higher",
        condition: RuleCondition(
            metric: "pain_level",
            operator: .greaterThanOrEqual,
            threshold: 7,
            unit: "pain scale",
            lookbackDays: nil
        ),
        isEnabled: true,
        appliesToAllPatients: true,
        patientIds: nil,
        programIds: nil,
        priority: 1,
        cooldownHours: 24,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let sampleRules: [SafetyRule] = [
        sample,
        SafetyRule(
            id: UUID(),
            therapistId: UUID(),
            name: "Low Adherence Warning",
            ruleType: .adherenceDropoff,
            description: "Alert when weekly adherence drops below 70%",
            condition: RuleCondition(
                metric: "adherence_percentage",
                operator: .lessThan,
                threshold: 70,
                unit: "%",
                lookbackDays: 7
            ),
            isEnabled: true,
            appliesToAllPatients: true,
            patientIds: nil,
            programIds: nil,
            priority: 2,
            cooldownHours: 48,
            createdAt: Date(),
            updatedAt: Date()
        ),
        SafetyRule(
            id: UUID(),
            therapistId: UUID(),
            name: "Missed Sessions Check",
            ruleType: .missedSessions,
            description: "Alert after 3 consecutive missed sessions",
            condition: RuleCondition(
                metric: "consecutive_missed",
                operator: .greaterThanOrEqual,
                threshold: 3,
                unit: "sessions",
                lookbackDays: nil
            ),
            isEnabled: true,
            appliesToAllPatients: false,
            patientIds: [UUID(), UUID()],
            programIds: nil,
            priority: 2,
            cooldownHours: 72,
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
}
#endif
