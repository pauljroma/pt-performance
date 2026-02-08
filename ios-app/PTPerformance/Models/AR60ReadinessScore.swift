import SwiftUI

// MARK: - AR60 Readiness Score Models
// X2Index Performance & Recovery Command Center
// North Star metric system for assessing athlete readiness in 60 seconds

/// Composite readiness score with confidence and evidence-backed contributors
/// AR60 (Actionable Readiness in 60 Seconds) is the core metric for PT assessment
struct AR60ReadinessScore: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let athleteId: UUID
    let score: Int // 0-100 composite readiness score
    let confidence: Double // 0.0-1.0 confidence based on data completeness
    let trend: ReadinessTrend
    let contributors: [ReadinessContributor]
    let timestamp: Date
    let uncertaintyFlag: Bool // True when data is stale (>24h) or conflicting

    /// Trend direction for readiness over time
    enum ReadinessTrend: String, Codable, CaseIterable, Sendable {
        case improving
        case stable
        case declining
        case unknown

        var displayName: String {
            switch self {
            case .improving: return "Improving"
            case .stable: return "Stable"
            case .declining: return "Declining"
            case .unknown: return "Unknown"
            }
        }

        var icon: String {
            switch self {
            case .improving: return "arrow.up.right"
            case .stable: return "arrow.forward"
            case .declining: return "arrow.down.right"
            case .unknown: return "questionmark"
            }
        }

        var color: Color {
            switch self {
            case .improving: return .modusTealAccent
            case .stable: return .modusCyan
            case .declining: return .orange
            case .unknown: return .secondary
            }
        }
    }

    // MARK: - Computed Properties

    /// Readiness category based on score
    var category: AR60Category {
        AR60Category.category(for: score)
    }

    /// Formatted score text
    var formattedScore: String {
        "\(score)"
    }

    /// Confidence level description
    var confidenceLevel: AR60ConfidenceLevel {
        AR60ConfidenceLevel.level(for: confidence)
    }

    /// Primary color for the score
    var scoreColor: Color {
        category.color
    }

    /// Whether the score should be treated with caution
    var requiresCaution: Bool {
        uncertaintyFlag || confidence < 0.5
    }

    /// Top contributors (positive impact)
    var topContributors: [ReadinessContributor] {
        contributors
            .filter { $0.impact == .positive }
            .sorted { $0.weightedValue > $1.weightedValue }
            .prefix(3)
            .map { $0 }
    }

    /// Limiting factors (negative impact)
    var limitingFactors: [ReadinessContributor] {
        contributors
            .filter { $0.impact == .negative || $0.impact == .critical }
            .sorted { $0.weightedValue < $1.weightedValue }
    }

    /// Critical alerts requiring immediate attention
    var criticalAlerts: [ReadinessContributor] {
        contributors.filter { $0.impact == .critical }
    }

    // MARK: - Initializers

    init(
        id: UUID = UUID(),
        athleteId: UUID,
        score: Int,
        confidence: Double,
        trend: ReadinessTrend,
        contributors: [ReadinessContributor],
        timestamp: Date = Date(),
        uncertaintyFlag: Bool = false
    ) {
        self.id = id
        self.athleteId = athleteId
        self.score = max(0, min(100, score))
        self.confidence = max(0.0, min(1.0, confidence))
        self.trend = trend
        self.contributors = contributors
        self.timestamp = timestamp
        self.uncertaintyFlag = uncertaintyFlag
    }
}

// MARK: - AR60 Category

/// Readiness category classification with training recommendations
enum AR60Category: String, Codable, CaseIterable, Sendable {
    case optimal = "Optimal"
    case ready = "Ready"
    case moderate = "Moderate"
    case caution = "Caution"
    case recovery = "Recovery"

    /// Determine the readiness category for a given score
    static func category(for score: Int) -> AR60Category {
        switch score {
        case 85...100: return .optimal
        case 70..<85: return .ready
        case 55..<70: return .moderate
        case 40..<55: return .caution
        default: return .recovery
        }
    }

    /// Display color for the category
    var color: Color {
        switch self {
        case .optimal: return .modusTealAccent
        case .ready: return .modusCyan
        case .moderate: return .yellow
        case .caution: return .orange
        case .recovery: return .red
        }
    }

    /// Icon for the category
    var icon: String {
        switch self {
        case .optimal: return "checkmark.circle.fill"
        case .ready: return "arrow.up.circle.fill"
        case .moderate: return "minus.circle.fill"
        case .caution: return "exclamationmark.triangle.fill"
        case .recovery: return "bed.double.fill"
        }
    }

    /// Score range description
    var scoreRange: String {
        switch self {
        case .optimal: return "85-100"
        case .ready: return "70-84"
        case .moderate: return "55-69"
        case .caution: return "40-54"
        case .recovery: return "0-39"
        }
    }

    /// Training recommendation
    var recommendation: String {
        switch self {
        case .optimal: return "Peak readiness - maximize training intensity"
        case .ready: return "Good to train - proceed with planned session"
        case .moderate: return "Train with awareness - consider modifications"
        case .caution: return "Reduced intensity - focus on technique"
        case .recovery: return "Rest recommended - prioritize recovery"
        }
    }

    /// Suggested intensity adjustment
    var intensityMultiplier: Double {
        switch self {
        case .optimal: return 1.0
        case .ready: return 0.95
        case .moderate: return 0.80
        case .caution: return 0.60
        case .recovery: return 0.30
        }
    }
}

// MARK: - Confidence Level

/// Confidence level for the AR60 score
enum AR60ConfidenceLevel: String, Codable, CaseIterable, Sendable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    case insufficient = "Insufficient"

    /// Determine confidence level from numeric value
    static func level(for confidence: Double) -> AR60ConfidenceLevel {
        switch confidence {
        case 0.8...1.0: return .high
        case 0.6..<0.8: return .medium
        case 0.4..<0.6: return .low
        default: return .insufficient
        }
    }

    /// Display color
    var color: Color {
        switch self {
        case .high: return .modusTealAccent
        case .medium: return .modusCyan
        case .low: return .orange
        case .insufficient: return .red
        }
    }

    /// Icon for confidence level
    var icon: String {
        switch self {
        case .high: return "checkmark.shield.fill"
        case .medium: return "shield.fill"
        case .low: return "shield.lefthalf.filled"
        case .insufficient: return "exclamationmark.shield.fill"
        }
    }

    /// Description for PT
    var description: String {
        switch self {
        case .high: return "Complete data from multiple sources"
        case .medium: return "Good data, some gaps"
        case .low: return "Limited data available"
        case .insufficient: return "Insufficient data for reliable assessment"
        }
    }
}

// MARK: - Readiness Contributor

/// Individual contributor to the composite readiness score
struct ReadinessContributor: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let domain: ReadinessDomain
    let value: Double // 0-100 normalized score for this domain
    let weight: Double // 0.0-1.0 weight in composite calculation
    let impact: ContributorImpact
    let sourceRefs: [EvidenceSourceRef]

    /// Domain categories for readiness contributors
    enum ReadinessDomain: String, Codable, CaseIterable, Sendable {
        case sleep
        case recovery
        case stress
        case soreness
        case nutrition
        case training
        case biomarkers

        var displayName: String {
            switch self {
            case .sleep: return "Sleep"
            case .recovery: return "Recovery"
            case .stress: return "Stress"
            case .soreness: return "Soreness"
            case .nutrition: return "Nutrition"
            case .training: return "Training Load"
            case .biomarkers: return "Biomarkers"
            }
        }

        var icon: String {
            switch self {
            case .sleep: return "moon.fill"
            case .recovery: return "heart.fill"
            case .stress: return "brain.head.profile"
            case .soreness: return "figure.stand"
            case .nutrition: return "leaf.fill"
            case .training: return "dumbbell.fill"
            case .biomarkers: return "waveform.path.ecg"
            }
        }

        var color: Color {
            switch self {
            case .sleep: return .indigo
            case .recovery: return .modusTealAccent
            case .stress: return .purple
            case .soreness: return .orange
            case .nutrition: return .green
            case .training: return .modusCyan
            case .biomarkers: return .pink
            }
        }

        /// Default weight for this domain
        var defaultWeight: Double {
            switch self {
            case .sleep: return 0.25
            case .recovery: return 0.20
            case .stress: return 0.15
            case .soreness: return 0.15
            case .nutrition: return 0.10
            case .training: return 0.10
            case .biomarkers: return 0.05
            }
        }
    }

    /// Impact classification for a contributor
    enum ContributorImpact: String, Codable, CaseIterable, Sendable {
        case positive
        case neutral
        case negative
        case critical

        var displayName: String {
            switch self {
            case .positive: return "Positive"
            case .neutral: return "Neutral"
            case .negative: return "Limiting"
            case .critical: return "Critical"
            }
        }

        var color: Color {
            switch self {
            case .positive: return .modusTealAccent
            case .neutral: return .secondary
            case .negative: return .orange
            case .critical: return .red
            }
        }

        var icon: String {
            switch self {
            case .positive: return "arrow.up.circle.fill"
            case .neutral: return "minus.circle.fill"
            case .negative: return "arrow.down.circle.fill"
            case .critical: return "exclamationmark.octagon.fill"
            }
        }
    }

    // MARK: - Computed Properties

    /// Weighted value contribution
    var weightedValue: Double {
        value * weight
    }

    /// Formatted value for display
    var formattedValue: String {
        String(format: "%.0f", value)
    }

    /// Formatted weight as percentage
    var formattedWeight: String {
        String(format: "%.0f%%", weight * 100)
    }

    /// Evidence count
    var evidenceCount: Int {
        sourceRefs.count
    }

    /// Most recent evidence timestamp
    var latestEvidence: Date? {
        sourceRefs.map { $0.timestamp }.max()
    }

    /// Check if evidence is stale (>24h old)
    var hasStaleEvidence: Bool {
        guard let latest = latestEvidence else { return true }
        return Date().timeIntervalSince(latest) > 24 * 60 * 60
    }

    // MARK: - Initializers

    init(
        id: UUID = UUID(),
        domain: ReadinessDomain,
        value: Double,
        weight: Double? = nil,
        impact: ContributorImpact,
        sourceRefs: [EvidenceSourceRef] = []
    ) {
        self.id = id
        self.domain = domain
        self.value = max(0, min(100, value))
        self.weight = weight ?? domain.defaultWeight
        self.impact = impact
        self.sourceRefs = sourceRefs
    }
}

// MARK: - Evidence Source Reference

/// Reference to evidence supporting a readiness contributor
struct EvidenceSourceRef: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let sourceType: EvidenceSourceType
    let sourceId: String
    let timestamp: Date
    let snippet: String // Human-readable snippet of the evidence

    /// Types of evidence sources
    enum EvidenceSourceType: String, Codable, CaseIterable, Sendable {
        case wearableMetric
        case dailyCheckIn
        case labResult
        case sessionNote
        case biomarker

        var displayName: String {
            switch self {
            case .wearableMetric: return "Wearable"
            case .dailyCheckIn: return "Check-in"
            case .labResult: return "Lab Result"
            case .sessionNote: return "Session Note"
            case .biomarker: return "Biomarker"
            }
        }

        var icon: String {
            switch self {
            case .wearableMetric: return "applewatch"
            case .dailyCheckIn: return "checkmark.circle"
            case .labResult: return "cross.case"
            case .sessionNote: return "note.text"
            case .biomarker: return "waveform.path.ecg"
            }
        }

        var color: Color {
            switch self {
            case .wearableMetric: return .modusCyan
            case .dailyCheckIn: return .modusTealAccent
            case .labResult: return .pink
            case .sessionNote: return .orange
            case .biomarker: return .purple
            }
        }
    }

    // MARK: - Computed Properties

    /// Age of this evidence in hours
    var ageInHours: Double {
        Date().timeIntervalSince(timestamp) / 3600
    }

    /// Whether this evidence is stale (>24h)
    var isStale: Bool {
        ageInHours > 24
    }

    /// Formatted age for display
    var formattedAge: String {
        let hours = Int(ageInHours)
        if hours < 1 {
            return "Just now"
        } else if hours < 24 {
            return "\(hours)h ago"
        } else {
            let days = hours / 24
            return "\(days)d ago"
        }
    }

    // MARK: - Initializers

    init(
        id: UUID = UUID(),
        sourceType: EvidenceSourceType,
        sourceId: String,
        timestamp: Date = Date(),
        snippet: String
    ) {
        self.id = id
        self.sourceType = sourceType
        self.sourceId = sourceId
        self.timestamp = timestamp
        self.snippet = snippet
    }
}

// MARK: - Sample Data

#if DEBUG
extension AR60ReadinessScore {
    /// Sample score for previews
    static var sample: AR60ReadinessScore {
        AR60ReadinessScore(
            athleteId: UUID(),
            score: 78,
            confidence: 0.85,
            trend: .improving,
            contributors: [
                ReadinessContributor(
                    domain: .sleep,
                    value: 85,
                    impact: .positive,
                    sourceRefs: [
                        EvidenceSourceRef(
                            sourceType: .wearableMetric,
                            sourceId: "whoop_sleep_123",
                            timestamp: Date().addingTimeInterval(-4 * 3600),
                            snippet: "7.5 hours sleep, 85% efficiency"
                        )
                    ]
                ),
                ReadinessContributor(
                    domain: .recovery,
                    value: 72,
                    impact: .neutral,
                    sourceRefs: [
                        EvidenceSourceRef(
                            sourceType: .dailyCheckIn,
                            sourceId: "checkin_456",
                            timestamp: Date().addingTimeInterval(-2 * 3600),
                            snippet: "HRV 52ms, resting HR 58bpm"
                        )
                    ]
                ),
                ReadinessContributor(
                    domain: .soreness,
                    value: 55,
                    impact: .negative,
                    sourceRefs: [
                        EvidenceSourceRef(
                            sourceType: .dailyCheckIn,
                            sourceId: "checkin_456",
                            timestamp: Date().addingTimeInterval(-2 * 3600),
                            snippet: "Moderate lower body soreness"
                        )
                    ]
                ),
                ReadinessContributor(
                    domain: .stress,
                    value: 80,
                    impact: .positive,
                    sourceRefs: []
                ),
                ReadinessContributor(
                    domain: .nutrition,
                    value: 70,
                    impact: .neutral,
                    sourceRefs: [
                        EvidenceSourceRef(
                            sourceType: .dailyCheckIn,
                            sourceId: "fasting_789",
                            timestamp: Date().addingTimeInterval(-12 * 3600),
                            snippet: "16:8 fast completed successfully"
                        )
                    ]
                )
            ],
            uncertaintyFlag: false
        )
    }

    /// Low confidence sample for testing uncertainty
    static var lowConfidenceSample: AR60ReadinessScore {
        AR60ReadinessScore(
            athleteId: UUID(),
            score: 62,
            confidence: 0.45,
            trend: .unknown,
            contributors: [
                ReadinessContributor(
                    domain: .sleep,
                    value: 60,
                    impact: .neutral,
                    sourceRefs: []
                )
            ],
            uncertaintyFlag: true
        )
    }

    /// Critical sample for testing alerts
    static var criticalSample: AR60ReadinessScore {
        AR60ReadinessScore(
            athleteId: UUID(),
            score: 35,
            confidence: 0.90,
            trend: .declining,
            contributors: [
                ReadinessContributor(
                    domain: .sleep,
                    value: 30,
                    impact: .critical,
                    sourceRefs: [
                        EvidenceSourceRef(
                            sourceType: .wearableMetric,
                            sourceId: "whoop_sleep_critical",
                            timestamp: Date().addingTimeInterval(-6 * 3600),
                            snippet: "Only 4 hours sleep, poor quality"
                        )
                    ]
                ),
                ReadinessContributor(
                    domain: .soreness,
                    value: 25,
                    impact: .critical,
                    sourceRefs: [
                        EvidenceSourceRef(
                            sourceType: .sessionNote,
                            sourceId: "note_severe",
                            timestamp: Date().addingTimeInterval(-1 * 3600),
                            snippet: "Severe hamstring tightness reported"
                        )
                    ]
                )
            ],
            uncertaintyFlag: false
        )
    }
}

extension ReadinessContributor {
    static var sampleSleep: ReadinessContributor {
        ReadinessContributor(
            domain: .sleep,
            value: 85,
            impact: .positive,
            sourceRefs: [
                EvidenceSourceRef(
                    sourceType: .wearableMetric,
                    sourceId: "sample_1",
                    snippet: "8 hours sleep"
                )
            ]
        )
    }
}
#endif
