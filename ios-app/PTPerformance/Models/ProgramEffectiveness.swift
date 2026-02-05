//
//  ProgramEffectiveness.swift
//  PTPerformance
//
//  Models for Program Effectiveness Analytics
//  Provides data structures for tracking program outcomes and effectiveness
//

import SwiftUI

// MARK: - Program Metrics

/// Comprehensive metrics for a single program
struct ProgramMetrics: Identifiable, Codable, Hashable {
    let id: UUID
    let programId: UUID?
    let programName: String
    let programType: ProgramType?
    let totalEnrollments: Int?
    let activeEnrollments: Int?
    let completedEnrollments: Int?
    let droppedEnrollments: Int?
    let completionRate: Double?
    let averageDurationWeeks: Double?
    let averagePainReduction: Double?
    let averageStrengthGain: Double?
    let averageAdherence: Double?
    let lastUpdated: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case programId = "program_id"
        case programName = "program_name"
        case programType = "program_type"
        case totalEnrollments = "total_enrollments"
        case activeEnrollments = "active_enrollments"
        case completedEnrollments = "completed_enrollments"
        case droppedEnrollments = "dropped_enrollments"
        case completionRate = "completion_rate"
        case averageDurationWeeks = "average_duration_weeks"
        case averagePainReduction = "average_pain_reduction"
        case averageStrengthGain = "average_strength_gain"
        case averageAdherence = "average_adherence"
        case lastUpdated = "last_updated"
    }

    // MARK: - Safe Accessors
    var totalEnrollmentsValue: Int { totalEnrollments ?? 0 }
    var activeEnrollmentsValue: Int { activeEnrollments ?? 0 }
    var completedEnrollmentsValue: Int { completedEnrollments ?? 0 }
    var droppedEnrollmentsValue: Int { droppedEnrollments ?? 0 }
    var completionRateValue: Double { completionRate ?? 0 }
    var averageDurationWeeksValue: Double { averageDurationWeeks ?? 0 }
    var averagePainReductionValue: Double { averagePainReduction ?? 0 }
    var averageStrengthGainValue: Double { averageStrengthGain ?? 0 }
    var averageAdherenceValue: Double { averageAdherence ?? 0 }

    /// Resolved program type (defaults to .rehab for legacy programs)
    var resolvedProgramType: ProgramType {
        programType ?? .rehab
    }

    /// Formatted completion rate as percentage
    var formattedCompletionRate: String {
        String(format: "%.0f%%", completionRateValue * 100)
    }

    /// Formatted pain reduction
    var formattedPainReduction: String {
        String(format: "%.1f pts", averagePainReductionValue)
    }

    /// Formatted strength gain
    var formattedStrengthGain: String {
        String(format: "+%.0f%%", averageStrengthGainValue * 100)
    }

    /// Formatted adherence
    var formattedAdherence: String {
        String(format: "%.0f%%", averageAdherenceValue * 100)
    }

    /// Effectiveness score (weighted combination of metrics)
    var effectivenessScore: Double {
        let completionWeight = 0.3
        let painWeight = 0.25
        let strengthWeight = 0.25
        let adherenceWeight = 0.2

        // Normalize pain reduction (assume max 10 points possible)
        let normalizedPain = min(averagePainReductionValue / 10.0, 1.0)

        return (completionRateValue * completionWeight) +
               (normalizedPain * painWeight) +
               (averageStrengthGainValue * strengthWeight) +
               (averageAdherenceValue * adherenceWeight)
    }

    /// Effectiveness rating based on score
    var effectivenessRating: EffectivenessRating {
        switch effectivenessScore {
        case 0.8...: return .excellent
        case 0.6..<0.8: return .good
        case 0.4..<0.6: return .fair
        default: return .needsImprovement
        }
    }
}

// MARK: - Effectiveness Rating

enum EffectivenessRating: String, CaseIterable {
    case excellent
    case good
    case fair
    case needsImprovement

    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .needsImprovement: return "Needs Improvement"
        }
    }

    var icon: String {
        switch self {
        case .excellent: return "star.fill"
        case .good: return "hand.thumbsup.fill"
        case .fair: return "minus.circle.fill"
        case .needsImprovement: return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .needsImprovement: return .red
        }
    }
}

// MARK: - Program Comparison

/// Side-by-side comparison of multiple programs
struct ProgramComparison: Identifiable {
    let id = UUID()
    let programs: [ProgramMetrics]
    let comparisonDate: Date

    /// Get the best program for a specific metric
    func bestProgram(for metric: ComparisonMetric) -> ProgramMetrics? {
        switch metric {
        case .completionRate:
            return programs.max(by: { $0.completionRateValue < $1.completionRateValue })
        case .painReduction:
            return programs.max(by: { $0.averagePainReductionValue < $1.averagePainReductionValue })
        case .strengthGain:
            return programs.max(by: { $0.averageStrengthGainValue < $1.averageStrengthGainValue })
        case .adherence:
            return programs.max(by: { $0.averageAdherenceValue < $1.averageAdherenceValue })
        case .effectiveness:
            return programs.max(by: { $0.effectivenessScore < $1.effectivenessScore })
        }
    }

    /// Check if a program is the winner for a metric
    func isWinner(_ program: ProgramMetrics, for metric: ComparisonMetric) -> Bool {
        bestProgram(for: metric)?.id == program.id
    }
}

/// Metrics available for comparison
enum ComparisonMetric: String, CaseIterable, Identifiable {
    case completionRate
    case painReduction
    case strengthGain
    case adherence
    case effectiveness

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .completionRate: return "Completion Rate"
        case .painReduction: return "Pain Reduction"
        case .strengthGain: return "Strength Gain"
        case .adherence: return "Adherence"
        case .effectiveness: return "Overall Score"
        }
    }

    var icon: String {
        switch self {
        case .completionRate: return "checkmark.circle"
        case .painReduction: return "bolt.slash"
        case .strengthGain: return "arrow.up.right"
        case .adherence: return "calendar.badge.checkmark"
        case .effectiveness: return "star"
        }
    }
}

// MARK: - Phase Dropoff Data

/// Attrition data for each phase of a program
struct PhaseDropoffData: Identifiable, Codable, Hashable {
    let id: UUID
    let programId: UUID
    let phaseNumber: Int
    let phaseName: String
    let startingPatients: Int
    let completingPatients: Int
    let droppedPatients: Int
    let averageCompletionDays: Double
    let commonDropoffReasons: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case programId = "program_id"
        case phaseNumber = "phase_number"
        case phaseName = "phase_name"
        case startingPatients = "starting_patients"
        case completingPatients = "completing_patients"
        case droppedPatients = "dropped_patients"
        case averageCompletionDays = "average_completion_days"
        case commonDropoffReasons = "common_dropoff_reasons"
    }

    /// Completion rate for this phase
    var completionRate: Double {
        guard startingPatients > 0 else { return 0 }
        return Double(completingPatients) / Double(startingPatients)
    }

    /// Dropoff rate for this phase
    var dropoffRate: Double {
        guard startingPatients > 0 else { return 0 }
        return Double(droppedPatients) / Double(startingPatients)
    }

    /// Formatted completion rate
    var formattedCompletionRate: String {
        String(format: "%.0f%%", completionRate * 100)
    }

    /// Risk level based on dropoff rate
    var riskLevel: RiskLevel {
        switch dropoffRate {
        case 0.3...: return .high
        case 0.15..<0.3: return .medium
        default: return .low
        }
    }
}

/// Risk level for phase dropoff
enum RiskLevel: String, CaseIterable {
    case low
    case medium
    case high

    var displayName: String {
        switch self {
        case .low: return "Low Risk"
        case .medium: return "Medium Risk"
        case .high: return "High Risk"
        }
    }

    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

// MARK: - Outcome Distribution

/// Distribution of outcomes for a program
struct OutcomeDistribution: Identifiable, Codable, Hashable {
    let id: UUID
    let programId: UUID
    let successCount: Int
    let partialSuccessCount: Int
    let failedCount: Int
    let ongoingCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case programId = "program_id"
        case successCount = "success_count"
        case partialSuccessCount = "partial_success_count"
        case failedCount = "failed_count"
        case ongoingCount = "ongoing_count"
    }

    /// Total outcomes (excluding ongoing)
    var totalCompleted: Int {
        successCount + partialSuccessCount + failedCount
    }

    /// Total including ongoing
    var totalAll: Int {
        totalCompleted + ongoingCount
    }

    /// Success rate
    var successRate: Double {
        guard totalCompleted > 0 else { return 0 }
        return Double(successCount) / Double(totalCompleted)
    }

    /// Partial success rate
    var partialRate: Double {
        guard totalCompleted > 0 else { return 0 }
        return Double(partialSuccessCount) / Double(totalCompleted)
    }

    /// Failure rate
    var failureRate: Double {
        guard totalCompleted > 0 else { return 0 }
        return Double(failedCount) / Double(totalCompleted)
    }

    /// Chart data for outcomes
    var chartData: [OutcomeChartData] {
        [
            OutcomeChartData(category: .success, count: successCount, color: .green),
            OutcomeChartData(category: .partial, count: partialSuccessCount, color: .orange),
            OutcomeChartData(category: .failed, count: failedCount, color: .red),
            OutcomeChartData(category: .ongoing, count: ongoingCount, color: .blue)
        ]
    }
}

/// Chart data point for outcomes
struct OutcomeChartData: Identifiable {
    let id = UUID()
    let category: OutcomeCategory
    let count: Int
    let color: Color
}

/// Outcome categories
enum OutcomeCategory: String, CaseIterable {
    case success
    case partial
    case failed
    case ongoing

    var displayName: String {
        switch self {
        case .success: return "Success"
        case .partial: return "Partial"
        case .failed: return "Did Not Complete"
        case .ongoing: return "In Progress"
        }
    }

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .partial: return "circle.lefthalf.filled"
        case .failed: return "xmark.circle.fill"
        case .ongoing: return "clock.fill"
        }
    }
}

// MARK: - Heatmap Data

/// Data point for heatmap visualization
struct HeatmapDataPoint: Identifiable, Hashable {
    let id = UUID()
    let phaseNumber: Int
    let phaseName: String
    let metricType: HeatmapMetricType
    let value: Double
    let patientCount: Int

    /// Normalized value (0-1) for color intensity
    var normalizedValue: Double {
        switch metricType {
        case .completion, .adherence:
            return value
        case .painLevel:
            // Invert pain (lower is better)
            return max(0, 1 - (value / 10.0))
        case .strengthProgress:
            // Normalize strength gain (assume max 50% gain)
            return min(value / 0.5, 1.0)
        }
    }

    /// Color based on value
    var color: Color {
        let normalized = normalizedValue
        if normalized >= 0.8 {
            return .green
        } else if normalized >= 0.6 {
            return .yellow
        } else if normalized >= 0.4 {
            return .orange
        } else {
            return .red
        }
    }

    /// Color intensity for gradient
    var colorIntensity: Double {
        return max(0.3, normalizedValue)
    }
}

/// Types of metrics for heatmap
enum HeatmapMetricType: String, CaseIterable, Identifiable {
    case completion
    case adherence
    case painLevel
    case strengthProgress

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .completion: return "Completion"
        case .adherence: return "Adherence"
        case .painLevel: return "Pain Level"
        case .strengthProgress: return "Strength Progress"
        }
    }

    var icon: String {
        switch self {
        case .completion: return "checkmark.circle"
        case .adherence: return "calendar"
        case .painLevel: return "bolt.heart"
        case .strengthProgress: return "figure.strengthtraining.traditional"
        }
    }
}

// MARK: - Program Patient Detail

/// Patient enrolled in a program with their outcomes
struct ProgramPatient: Identifiable, Codable, Hashable {
    let id: UUID
    let patientId: UUID
    let firstName: String
    let lastName: String
    let programId: UUID
    let enrollmentDate: Date
    let currentPhase: Int
    let completionPercentage: Double
    let adherenceRate: Double
    let painReduction: Double?
    let status: String

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case programId = "program_id"
        case enrollmentDate = "enrollment_date"
        case currentPhase = "current_phase"
        case completionPercentage = "completion_percentage"
        case adherenceRate = "adherence_rate"
        case painReduction = "pain_reduction"
        case status
    }

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var initials: String {
        let first = firstName.prefix(1).uppercased()
        let last = lastName.prefix(1).uppercased()
        return "\(first)\(last)"
    }

    var enrollmentStatus: EnrollmentStatus {
        EnrollmentStatus(rawValue: status) ?? .active
    }
}

// MARK: - Sample Data

extension ProgramMetrics {
    static var sample: ProgramMetrics {
        ProgramMetrics(
            id: UUID(),
            programId: UUID(),
            programName: "ACL Recovery Protocol",
            programType: .rehab,
            totalEnrollments: 45,
            activeEnrollments: 12,
            completedEnrollments: 28,
            droppedEnrollments: 5,
            completionRate: 0.85,
            averageDurationWeeks: 16.5,
            averagePainReduction: 4.2,
            averageStrengthGain: 0.35,
            averageAdherence: 0.88,
            lastUpdated: Date()
        )
    }

    static var sampleList: [ProgramMetrics] {
        [
            sample,
            ProgramMetrics(
                id: UUID(),
                programId: UUID(),
                programName: "Shoulder Mobility Program",
                programType: .rehab,
                totalEnrollments: 32,
                activeEnrollments: 8,
                completedEnrollments: 20,
                droppedEnrollments: 4,
                completionRate: 0.83,
                averageDurationWeeks: 12.0,
                averagePainReduction: 3.8,
                averageStrengthGain: 0.28,
                averageAdherence: 0.82,
                lastUpdated: Date()
            ),
            ProgramMetrics(
                id: UUID(),
                programId: UUID(),
                programName: "Post-Surgery Strength",
                programType: .performance,
                totalEnrollments: 18,
                activeEnrollments: 5,
                completedEnrollments: 10,
                droppedEnrollments: 3,
                completionRate: 0.77,
                averageDurationWeeks: 20.0,
                averagePainReduction: 5.1,
                averageStrengthGain: 0.42,
                averageAdherence: 0.79,
                lastUpdated: Date()
            )
        ]
    }
}

extension PhaseDropoffData {
    static var sampleList: [PhaseDropoffData] {
        [
            PhaseDropoffData(
                id: UUID(),
                programId: UUID(),
                phaseNumber: 1,
                phaseName: "Foundation",
                startingPatients: 45,
                completingPatients: 42,
                droppedPatients: 3,
                averageCompletionDays: 28,
                commonDropoffReasons: ["Time constraints", "Lack of progress"]
            ),
            PhaseDropoffData(
                id: UUID(),
                programId: UUID(),
                phaseNumber: 2,
                phaseName: "Strengthening",
                startingPatients: 42,
                completingPatients: 38,
                droppedPatients: 4,
                averageCompletionDays: 35,
                commonDropoffReasons: ["Difficulty level", "Pain"]
            ),
            PhaseDropoffData(
                id: UUID(),
                programId: UUID(),
                phaseNumber: 3,
                phaseName: "Advanced",
                startingPatients: 38,
                completingPatients: 35,
                droppedPatients: 3,
                averageCompletionDays: 42,
                commonDropoffReasons: ["Return to activity", "Insurance"]
            ),
            PhaseDropoffData(
                id: UUID(),
                programId: UUID(),
                phaseNumber: 4,
                phaseName: "Return to Sport",
                startingPatients: 35,
                completingPatients: 33,
                droppedPatients: 2,
                averageCompletionDays: 28,
                commonDropoffReasons: ["Cleared by physician"]
            )
        ]
    }
}

extension OutcomeDistribution {
    static var sample: OutcomeDistribution {
        OutcomeDistribution(
            id: UUID(),
            programId: UUID(),
            successCount: 28,
            partialSuccessCount: 8,
            failedCount: 5,
            ongoingCount: 12
        )
    }
}
