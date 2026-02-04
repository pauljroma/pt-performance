//
//  CohortAnalytics.swift
//  PTPerformance
//
//  Data models for cohort analytics and patient benchmarking
//  Enables therapists to compare individual patient performance against cohort averages
//

import Foundation

// MARK: - Cohort Benchmarks

/// Aggregate metrics across all patients for a therapist
struct CohortBenchmarks: Codable, Equatable {
    /// Total number of active patients in the cohort
    let totalPatients: Int

    /// Average adherence percentage across all patients (0-100)
    let averageAdherence: Double

    /// Average pain reduction percentage (positive = improvement)
    let averagePainReduction: Double

    /// Average strength gains percentage
    let averageStrengthGains: Double

    /// Average sessions completed per week
    let averageSessionsPerWeek: Double

    /// Average program completion rate (0-100)
    let averageProgramCompletion: Double

    /// Median time to recovery in days (for patients who completed programs)
    let medianRecoveryDays: Int?

    /// Date range for the benchmark calculation
    let periodStart: Date
    let periodEnd: Date

    // MARK: - Computed Properties

    var formattedAdherence: String {
        String(format: "%.0f%%", averageAdherence)
    }

    var formattedPainReduction: String {
        String(format: "%.1f%%", averagePainReduction)
    }

    var formattedStrengthGains: String {
        String(format: "%.1f%%", averageStrengthGains)
    }

    var formattedSessionsPerWeek: String {
        String(format: "%.1f", averageSessionsPerWeek)
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case totalPatients = "total_patients"
        case averageAdherence = "average_adherence"
        case averagePainReduction = "average_pain_reduction"
        case averageStrengthGains = "average_strength_gains"
        case averageSessionsPerWeek = "average_sessions_per_week"
        case averageProgramCompletion = "average_program_completion"
        case medianRecoveryDays = "median_recovery_days"
        case periodStart = "period_start"
        case periodEnd = "period_end"
    }
}

// MARK: - Patient Comparison

/// Comparison of an individual patient against cohort benchmarks
struct PatientComparison: Codable, Identifiable, Equatable {
    let id: UUID
    let patientId: UUID
    let patientName: String

    /// Patient's adherence percentage
    let adherence: Double

    /// Percentile ranking for adherence (0-100, higher = better)
    let adherencePercentile: Int

    /// Patient's pain reduction percentage
    let painReduction: Double

    /// Percentile ranking for pain reduction
    let painReductionPercentile: Int

    /// Patient's strength gains percentage
    let strengthGains: Double

    /// Percentile ranking for strength gains
    let strengthGainsPercentile: Int

    /// Patient's sessions completed per week
    let sessionsPerWeek: Double

    /// Overall score combining all metrics (0-100)
    let overallScore: Double

    /// Overall percentile ranking
    let overallPercentile: Int

    /// Comparison status relative to cohort
    var comparisonStatus: ComparisonStatus {
        if overallPercentile >= 75 {
            return .aboveAverage
        } else if overallPercentile >= 25 {
            return .average
        } else {
            return .belowAverage
        }
    }

    enum ComparisonStatus: String, Codable {
        case aboveAverage = "above_average"
        case average = "average"
        case belowAverage = "below_average"

        var displayName: String {
            switch self {
            case .aboveAverage: return "Above Average"
            case .average: return "Average"
            case .belowAverage: return "Below Average"
            }
        }

        var iconName: String {
            switch self {
            case .aboveAverage: return "arrow.up.circle.fill"
            case .average: return "equal.circle.fill"
            case .belowAverage: return "arrow.down.circle.fill"
            }
        }
    }

    // MARK: - Computed Properties

    var formattedAdherence: String {
        String(format: "%.0f%%", adherence)
    }

    var formattedPainReduction: String {
        String(format: "%.1f%%", painReduction)
    }

    var formattedStrengthGains: String {
        String(format: "%.1f%%", strengthGains)
    }

    var adherenceDelta: Double {
        adherence - 50 // Difference from median
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case patientName = "patient_name"
        case adherence
        case adherencePercentile = "adherence_percentile"
        case painReduction = "pain_reduction"
        case painReductionPercentile = "pain_reduction_percentile"
        case strengthGains = "strength_gains"
        case strengthGainsPercentile = "strength_gains_percentile"
        case sessionsPerWeek = "sessions_per_week"
        case overallScore = "overall_score"
        case overallPercentile = "overall_percentile"
    }
}

// MARK: - Compliance Distribution

/// Histogram data for adherence rates across the cohort
struct ComplianceDistribution: Codable, Equatable {
    /// Distribution buckets with patient counts
    let buckets: [ComplianceBucket]

    /// Total number of patients in the distribution
    let totalPatients: Int

    /// Cohort average adherence
    let averageAdherence: Double

    /// Cohort median adherence
    let medianAdherence: Double

    /// Standard deviation of adherence
    let standardDeviation: Double

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case buckets
        case totalPatients = "total_patients"
        case averageAdherence = "average_adherence"
        case medianAdherence = "median_adherence"
        case standardDeviation = "standard_deviation"
    }
}

/// Individual bucket in the compliance distribution histogram
struct ComplianceBucket: Codable, Identifiable, Equatable {
    let id: UUID

    /// Lower bound of the bucket (inclusive)
    let rangeStart: Int

    /// Upper bound of the bucket (exclusive, except for 100%)
    let rangeEnd: Int

    /// Number of patients in this bucket
    let patientCount: Int

    /// Percentage of total patients in this bucket
    let percentage: Double

    /// Display label for the bucket
    var label: String {
        "\(rangeStart)-\(rangeEnd)%"
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case rangeStart = "range_start"
        case rangeEnd = "range_end"
        case patientCount = "patient_count"
        case percentage
    }
}

// MARK: - Retention Data

/// Week-over-week patient retention data
struct RetentionData: Codable, Equatable {
    /// Weekly retention data points
    let weeklyData: [RetentionDataPoint]

    /// Overall retention rate at end of period
    let overallRetentionRate: Double

    /// Average drop-off week (when patients typically stop)
    let averageDropOffWeek: Double?

    /// Number of patients who completed their programs
    let completedPatients: Int

    /// Number of patients who dropped off
    let droppedPatients: Int

    /// Total patients in the cohort
    let totalPatients: Int

    // MARK: - Computed Properties

    var formattedRetentionRate: String {
        String(format: "%.0f%%", overallRetentionRate)
    }

    var dropOffRate: Double {
        100 - overallRetentionRate
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case weeklyData = "weekly_data"
        case overallRetentionRate = "overall_retention_rate"
        case averageDropOffWeek = "average_drop_off_week"
        case completedPatients = "completed_patients"
        case droppedPatients = "dropped_patients"
        case totalPatients = "total_patients"
    }
}

/// Individual data point for retention curve
struct RetentionDataPoint: Codable, Identifiable, Equatable {
    let id: UUID

    /// Week number (1 = first week of program)
    let weekNumber: Int

    /// Number of patients still active at this week
    let activePatients: Int

    /// Retention rate at this week (percentage of original cohort)
    let retentionRate: Double

    /// Number of patients who dropped off this week
    let droppedThisWeek: Int

    /// Display label for the week
    var weekLabel: String {
        "Week \(weekNumber)"
    }

    var formattedRetentionRate: String {
        String(format: "%.0f%%", retentionRate)
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case weekNumber = "week_number"
        case activePatients = "active_patients"
        case retentionRate = "retention_rate"
        case droppedThisWeek = "dropped_this_week"
    }
}

// MARK: - Program Outcomes

/// Outcomes aggregated by program type
struct ProgramOutcomes: Codable, Equatable {
    /// List of program outcome summaries
    let programs: [ProgramOutcomeSummary]

    /// Best performing program by completion rate
    var topProgramByCompletion: ProgramOutcomeSummary? {
        programs.max(by: { $0.completionRate < $1.completionRate })
    }

    /// Best performing program by pain reduction
    var topProgramByPainReduction: ProgramOutcomeSummary? {
        programs.max(by: { $0.averagePainReduction < $1.averagePainReduction })
    }
}

/// Outcome summary for a specific program
struct ProgramOutcomeSummary: Codable, Identifiable, Equatable {
    let id: UUID

    /// Program ID
    let programId: UUID

    /// Program name
    let programName: String

    /// Program type/category
    let programType: String

    /// Number of patients enrolled
    let enrolledPatients: Int

    /// Number of patients who completed
    let completedPatients: Int

    /// Completion rate (0-100)
    let completionRate: Double

    /// Average adherence for patients in this program
    let averageAdherence: Double

    /// Average pain reduction for completed patients
    let averagePainReduction: Double

    /// Average strength gains for completed patients
    let averageStrengthGains: Double

    /// Average days to completion
    let averageDaysToCompletion: Double?

    // MARK: - Computed Properties

    var formattedCompletionRate: String {
        String(format: "%.0f%%", completionRate)
    }

    var formattedAdherence: String {
        String(format: "%.0f%%", averageAdherence)
    }

    var formattedPainReduction: String {
        String(format: "%.1f%%", averagePainReduction)
    }

    var outcomeRating: OutcomeRating {
        // Simple rating based on completion and pain reduction
        let score = (completionRate * 0.4) + (averagePainReduction * 0.6)
        if score >= 70 {
            return .excellent
        } else if score >= 50 {
            return .good
        } else if score >= 30 {
            return .fair
        } else {
            return .needsImprovement
        }
    }

    enum OutcomeRating: String, Codable {
        case excellent
        case good
        case fair
        case needsImprovement = "needs_improvement"

        var displayName: String {
            switch self {
            case .excellent: return "Excellent"
            case .good: return "Good"
            case .fair: return "Fair"
            case .needsImprovement: return "Needs Improvement"
            }
        }

        var iconName: String {
            switch self {
            case .excellent: return "star.fill"
            case .good: return "hand.thumbsup.fill"
            case .fair: return "minus.circle.fill"
            case .needsImprovement: return "exclamationmark.triangle.fill"
            }
        }
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case programId = "program_id"
        case programName = "program_name"
        case programType = "program_type"
        case enrolledPatients = "enrolled_patients"
        case completedPatients = "completed_patients"
        case completionRate = "completion_rate"
        case averageAdherence = "average_adherence"
        case averagePainReduction = "average_pain_reduction"
        case averageStrengthGains = "average_strength_gains"
        case averageDaysToCompletion = "average_days_to_completion"
    }
}

// MARK: - Patient Ranking

/// Patient ranking entry for the ranking table
struct PatientRankingEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let patientId: UUID
    let patientName: String
    let patientInitials: String
    let profileImageUrl: String?

    /// Rank position (1 = best)
    let rank: Int

    /// Adherence percentage
    let adherence: Double

    /// Pain reduction percentage
    let painReduction: Double

    /// Strength gains percentage
    let strengthGains: Double

    /// Overall progress score (0-100)
    let progressScore: Double

    /// Status indicator
    let status: PatientStatus

    /// Last activity date
    let lastActivityDate: Date?

    enum PatientStatus: String, Codable {
        case onTrack = "on_track"
        case needsAttention = "needs_attention"
        case atRisk = "at_risk"
        case inactive = "inactive"

        var displayName: String {
            switch self {
            case .onTrack: return "On Track"
            case .needsAttention: return "Needs Attention"
            case .atRisk: return "At Risk"
            case .inactive: return "Inactive"
            }
        }

        var iconName: String {
            switch self {
            case .onTrack: return "checkmark.circle.fill"
            case .needsAttention: return "exclamationmark.circle.fill"
            case .atRisk: return "exclamationmark.triangle.fill"
            case .inactive: return "moon.zzz.fill"
            }
        }
    }

    // MARK: - Computed Properties

    var formattedAdherence: String {
        String(format: "%.0f%%", adherence)
    }

    var formattedPainReduction: String {
        String(format: "%.1f%%", painReduction)
    }

    var formattedProgressScore: String {
        String(format: "%.0f", progressScore)
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case patientName = "patient_name"
        case patientInitials = "patient_initials"
        case profileImageUrl = "profile_image_url"
        case rank
        case adherence
        case painReduction = "pain_reduction"
        case strengthGains = "strength_gains"
        case progressScore = "progress_score"
        case status
        case lastActivityDate = "last_activity_date"
    }
}

// MARK: - Cohort Trend Data

/// Trend data for cohort-wide metrics over time
struct CohortTrendData: Codable, Equatable {
    /// Weekly trend data points
    let dataPoints: [CohortTrendDataPoint]

    /// Trend direction for adherence
    let adherenceTrend: TrendDirection

    /// Trend direction for pain reduction
    let painReductionTrend: TrendDirection

    /// Trend direction for retention
    let retentionTrend: TrendDirection

    enum TrendDirection: String, Codable {
        case increasing
        case decreasing
        case stable

        var iconName: String {
            switch self {
            case .increasing: return "arrow.up.right"
            case .decreasing: return "arrow.down.right"
            case .stable: return "arrow.right"
            }
        }

        var isPositive: Bool {
            self == .increasing
        }
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case dataPoints = "data_points"
        case adherenceTrend = "adherence_trend"
        case painReductionTrend = "pain_reduction_trend"
        case retentionTrend = "retention_trend"
    }
}

/// Individual data point for cohort trends
struct CohortTrendDataPoint: Codable, Identifiable, Equatable {
    let id: UUID

    /// Week start date
    let weekStart: Date

    /// Average adherence for the week
    let averageAdherence: Double

    /// Average pain score for the week
    let averagePainScore: Double

    /// Active patient count
    let activePatients: Int

    /// Sessions completed
    let sessionsCompleted: Int

    var weekLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: weekStart)
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case weekStart = "week_start"
        case averageAdherence = "average_adherence"
        case averagePainScore = "average_pain_score"
        case activePatients = "active_patients"
        case sessionsCompleted = "sessions_completed"
    }
}

// MARK: - Sample Data

#if DEBUG
extension CohortBenchmarks {
    static var sample: CohortBenchmarks {
        CohortBenchmarks(
            totalPatients: 42,
            averageAdherence: 78.5,
            averagePainReduction: 45.2,
            averageStrengthGains: 23.8,
            averageSessionsPerWeek: 3.2,
            averageProgramCompletion: 72.0,
            medianRecoveryDays: 84,
            periodStart: Calendar.current.date(byAdding: .day, value: -90, to: Date())!,
            periodEnd: Date()
        )
    }
}

extension PatientComparison {
    static var sample: PatientComparison {
        PatientComparison(
            id: UUID(),
            patientId: UUID(),
            patientName: "John Brebbia",
            adherence: 92.0,
            adherencePercentile: 85,
            painReduction: 52.0,
            painReductionPercentile: 78,
            strengthGains: 28.5,
            strengthGainsPercentile: 72,
            sessionsPerWeek: 4.2,
            overallScore: 86.0,
            overallPercentile: 82
        )
    }
}

extension ComplianceDistribution {
    static var sample: ComplianceDistribution {
        ComplianceDistribution(
            buckets: [
                ComplianceBucket(id: UUID(), rangeStart: 0, rangeEnd: 20, patientCount: 2, percentage: 4.8),
                ComplianceBucket(id: UUID(), rangeStart: 20, rangeEnd: 40, patientCount: 4, percentage: 9.5),
                ComplianceBucket(id: UUID(), rangeStart: 40, rangeEnd: 60, patientCount: 8, percentage: 19.0),
                ComplianceBucket(id: UUID(), rangeStart: 60, rangeEnd: 80, patientCount: 15, percentage: 35.7),
                ComplianceBucket(id: UUID(), rangeStart: 80, rangeEnd: 100, patientCount: 13, percentage: 31.0)
            ],
            totalPatients: 42,
            averageAdherence: 68.5,
            medianAdherence: 72.0,
            standardDeviation: 18.3
        )
    }
}

extension RetentionData {
    static var sample: RetentionData {
        RetentionData(
            weeklyData: (1...12).map { week in
                let retention = max(100.0 - Double(week) * 5.5, 45.0)
                return RetentionDataPoint(
                    id: UUID(),
                    weekNumber: week,
                    activePatients: Int(42.0 * retention / 100.0),
                    retentionRate: retention,
                    droppedThisWeek: week == 1 ? 0 : Int.random(in: 1...3)
                )
            },
            overallRetentionRate: 72.0,
            averageDropOffWeek: 4.2,
            completedPatients: 28,
            droppedPatients: 14,
            totalPatients: 42
        )
    }
}

extension PatientRankingEntry {
    static var sampleList: [PatientRankingEntry] {
        [
            PatientRankingEntry(
                id: UUID(),
                patientId: UUID(),
                patientName: "John Brebbia",
                patientInitials: "JB",
                profileImageUrl: nil,
                rank: 1,
                adherence: 95.0,
                painReduction: 62.0,
                strengthGains: 35.0,
                progressScore: 92.0,
                status: .onTrack,
                lastActivityDate: Date()
            ),
            PatientRankingEntry(
                id: UUID(),
                patientId: UUID(),
                patientName: "Sarah Johnson",
                patientInitials: "SJ",
                profileImageUrl: nil,
                rank: 2,
                adherence: 88.0,
                painReduction: 48.0,
                strengthGains: 28.0,
                progressScore: 85.0,
                status: .onTrack,
                lastActivityDate: Date().addingTimeInterval(-86400)
            ),
            PatientRankingEntry(
                id: UUID(),
                patientId: UUID(),
                patientName: "Mike Thompson",
                patientInitials: "MT",
                profileImageUrl: nil,
                rank: 3,
                adherence: 65.0,
                painReduction: 25.0,
                strengthGains: 15.0,
                progressScore: 58.0,
                status: .needsAttention,
                lastActivityDate: Date().addingTimeInterval(-172800)
            )
        ]
    }
}
#endif
