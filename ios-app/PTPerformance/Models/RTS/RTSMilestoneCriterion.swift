import Foundation
import SwiftUI

// MARK: - RTSMilestoneCriterion Model
// Criteria definitions and test results for Return-to-Sport milestones

/// Represents a criterion that must be met to progress through RTS phases
struct RTSMilestoneCriterion: Identifiable, Codable, Hashable {
    let id: UUID
    let phaseId: UUID
    let category: RTSCriterionCategory
    let name: String
    let description: String
    let targetValue: Double?
    let targetUnit: String?
    let comparisonOperator: RTSComparisonOperator
    let isRequired: Bool
    let sortOrder: Int
    let createdAt: Date
    var updatedAt: Date

    /// For UI - latest test result (populated from separate query)
    var latestResult: RTSTestResult?

    enum CodingKeys: String, CodingKey {
        case id
        case phaseId = "phase_id"
        case category
        case name
        case description
        case targetValue = "target_value"
        case targetUnit = "target_unit"
        case comparisonOperator = "comparison_operator"
        case isRequired = "is_required"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case latestResult = "latest_result"
    }

    // MARK: - Computed Properties

    /// Whether the criterion has been passed based on latest result
    var isPassed: Bool {
        latestResult?.passed ?? false
    }

    /// Whether the criterion has been tested
    var hasBeenTested: Bool {
        latestResult != nil
    }

    /// Formatted target description
    var targetDescription: String {
        guard let value = targetValue else { return "N/A" }
        let unit = targetUnit ?? ""
        return "\(comparisonOperator.symbol) \(Int(value))\(unit.isEmpty ? "" : " ")\(unit)"
    }

    /// Status icon based on test results
    var statusIcon: String {
        if isPassed {
            return "checkmark.circle.fill"
        } else if hasBeenTested {
            return "xmark.circle.fill"
        } else {
            return "circle"
        }
    }

    /// Status color based on test results
    var statusColor: Color {
        if isPassed {
            return .green
        } else if hasBeenTested {
            return .red
        } else {
            return .gray
        }
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        phaseId: UUID,
        category: RTSCriterionCategory,
        name: String,
        description: String,
        targetValue: Double? = nil,
        targetUnit: String? = nil,
        comparisonOperator: RTSComparisonOperator = .greaterThanOrEqual,
        isRequired: Bool = true,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        latestResult: RTSTestResult? = nil
    ) {
        self.id = id
        self.phaseId = phaseId
        self.category = category
        self.name = name
        self.description = description
        self.targetValue = targetValue
        self.targetUnit = targetUnit
        self.comparisonOperator = comparisonOperator
        self.isRequired = isRequired
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.latestResult = latestResult
    }
}

// MARK: - Criterion Category

/// Categories of RTS milestone criteria
enum RTSCriterionCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case functional
    case strength
    case rom
    case pain
    case psychological

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .functional: return "Functional"
        case .strength: return "Strength"
        case .rom: return "Range of Motion"
        case .pain: return "Pain"
        case .psychological: return "Psychological"
        }
    }

    /// SF Symbol icon name
    var icon: String {
        switch self {
        case .functional: return "figure.walk"
        case .strength: return "dumbbell.fill"
        case .rom: return "arrow.left.and.right"
        case .pain: return "waveform.path.ecg"
        case .psychological: return "brain.head.profile"
        }
    }

    /// Color for UI display
    var color: Color {
        switch self {
        case .functional: return .blue
        case .strength: return .orange
        case .rom: return .purple
        case .pain: return .red
        case .psychological: return .teal
        }
    }
}

// MARK: - Comparison Operator

/// Comparison operators for evaluating criterion values
enum RTSComparisonOperator: String, Codable, CaseIterable, Hashable {
    case greaterThanOrEqual = ">="
    case lessThanOrEqual = "<="
    case equal = "=="
    case between = "between"

    /// Symbol for display
    var symbol: String {
        switch self {
        case .greaterThanOrEqual: return ">="
        case .lessThanOrEqual: return "<="
        case .equal: return "="
        case .between: return "between"
        }
    }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .greaterThanOrEqual: return "Greater than or equal"
        case .lessThanOrEqual: return "Less than or equal"
        case .equal: return "Equal to"
        case .between: return "Between"
        }
    }

    /// Evaluate whether a value meets the target
    /// - Parameters:
    ///   - value: The actual measured value
    ///   - target: The target value to compare against
    ///   - upperBound: Optional upper bound for "between" operator
    /// - Returns: Whether the value meets the criterion
    func evaluate(value: Double, target: Double, upperBound: Double? = nil) -> Bool {
        switch self {
        case .greaterThanOrEqual:
            return value >= target
        case .lessThanOrEqual:
            return value <= target
        case .equal:
            return abs(value - target) < 0.001
        case .between:
            guard let upper = upperBound else { return value >= target }
            return value >= target && value <= upper
        }
    }
}

// MARK: - Test Result

/// Represents a single test result for a milestone criterion
struct RTSTestResult: Identifiable, Codable, Hashable {
    let id: UUID
    let criterionId: UUID
    let protocolId: UUID
    let recordedBy: UUID
    let recordedAt: Date
    let value: Double
    let unit: String
    let passed: Bool
    let notes: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case criterionId = "criterion_id"
        case protocolId = "protocol_id"
        case recordedBy = "recorded_by"
        case recordedAt = "recorded_at"
        case value
        case unit
        case passed
        case notes
        case createdAt = "created_at"
    }

    // MARK: - Computed Properties

    /// Formatted recorded date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: recordedAt)
    }

    /// Formatted value with unit
    var formattedValue: String {
        let valueStr = value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
        return "\(valueStr) \(unit)"
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        criterionId: UUID,
        protocolId: UUID,
        recordedBy: UUID,
        recordedAt: Date = Date(),
        value: Double,
        unit: String,
        passed: Bool,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.criterionId = criterionId
        self.protocolId = protocolId
        self.recordedBy = recordedBy
        self.recordedAt = recordedAt
        self.value = value
        self.unit = unit
        self.passed = passed
        self.notes = notes
        self.createdAt = createdAt
    }
}

// MARK: - Input Models

/// Input model for creating/updating milestone criteria
struct RTSMilestoneCriterionInput: Codable {
    var phaseId: String?
    var category: String?
    var name: String?
    var description: String?
    var targetValue: Double?
    var targetUnit: String?
    var comparisonOperator: String?
    var isRequired: Bool?
    var sortOrder: Int?

    enum CodingKeys: String, CodingKey {
        case phaseId = "phase_id"
        case category
        case name
        case description
        case targetValue = "target_value"
        case targetUnit = "target_unit"
        case comparisonOperator = "comparison_operator"
        case isRequired = "is_required"
        case sortOrder = "sort_order"
    }
}

/// Input model for recording test results
struct RTSTestResultInput: Codable {
    var criterionId: String?
    var protocolId: String?
    var recordedBy: String?
    var recordedAt: String?
    var value: Double?
    var unit: String?
    var passed: Bool?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case criterionId = "criterion_id"
        case protocolId = "protocol_id"
        case recordedBy = "recorded_by"
        case recordedAt = "recorded_at"
        case value
        case unit
        case passed
        case notes
    }

    /// Validate input before submission
    func validate() throws {
        guard criterionId != nil else {
            throw RTSCriterionError.invalidInput("Criterion ID is required")
        }
        guard protocolId != nil else {
            throw RTSCriterionError.invalidInput("Protocol ID is required")
        }
        guard recordedBy != nil else {
            throw RTSCriterionError.invalidInput("Recorder ID is required")
        }
        guard value != nil else {
            throw RTSCriterionError.invalidInput("Value is required")
        }
        guard let unit = unit, !unit.isEmpty else {
            throw RTSCriterionError.invalidInput("Unit is required")
        }
    }
}

// MARK: - Errors

enum RTSCriterionError: LocalizedError {
    case invalidInput(String)
    case criterionNotFound
    case saveFailed
    case fetchFailed
    case resultSaveFailed

    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return message
        case .criterionNotFound:
            return "Milestone criterion not found"
        case .saveFailed:
            return "Failed to save milestone criterion"
        case .fetchFailed:
            return "Failed to fetch milestone criteria"
        case .resultSaveFailed:
            return "Failed to save test result"
        }
    }
}

// MARK: - Sample Data

#if DEBUG
extension RTSMilestoneCriterion {
    static let strengthSample = RTSMilestoneCriterion(
        phaseId: UUID(),
        category: .strength,
        name: "Quad LSI",
        description: "Limb Symmetry Index for quadriceps strength",
        targetValue: 85,
        targetUnit: "%",
        comparisonOperator: .greaterThanOrEqual,
        isRequired: true,
        sortOrder: 1,
        latestResult: RTSTestResult(
            criterionId: UUID(),
            protocolId: UUID(),
            recordedBy: UUID(),
            value: 87,
            unit: "%",
            passed: true
        )
    )

    static let functionalSample = RTSMilestoneCriterion(
        phaseId: UUID(),
        category: .functional,
        name: "Single Leg Hop",
        description: "Single leg hop for distance LSI",
        targetValue: 90,
        targetUnit: "%",
        comparisonOperator: .greaterThanOrEqual,
        isRequired: true,
        sortOrder: 2
    )

    static let painSample = RTSMilestoneCriterion(
        phaseId: UUID(),
        category: .pain,
        name: "Pain with Activity",
        description: "Pain level during sport-specific activity",
        targetValue: 2,
        targetUnit: "/10",
        comparisonOperator: .lessThanOrEqual,
        isRequired: true,
        sortOrder: 3,
        latestResult: RTSTestResult(
            criterionId: UUID(),
            protocolId: UUID(),
            recordedBy: UUID(),
            value: 3,
            unit: "/10",
            passed: false,
            notes: "Mild pain with cutting movements"
        )
    )

    static let psychologicalSample = RTSMilestoneCriterion(
        phaseId: UUID(),
        category: .psychological,
        name: "ACL-RSI Score",
        description: "ACL Return to Sport after Injury scale",
        targetValue: 70,
        targetUnit: "%",
        comparisonOperator: .greaterThanOrEqual,
        isRequired: false,
        sortOrder: 4
    )
}
#endif
