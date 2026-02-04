//
//  LabAnalysis.swift
//  PTPerformance
//
//  AI Lab Analysis Response Models
//  Structures for parsing and displaying AI-generated lab analysis
//

import Foundation
import SwiftUI

// MARK: - Lab Analysis Response

/// Comprehensive AI analysis of a lab result
struct LabAnalysis: Codable, Identifiable {
    let analysisId: String
    let analysisText: String
    let recommendations: [String]
    let biomarkerAnalyses: [BiomarkerAnalysis]
    let trainingCorrelations: [TrainingCorrelation]
    let sleepCorrelations: [TrainingCorrelation]
    let overallHealthScore: Int
    let priorityActions: [String]
    let medicalDisclaimer: String
    let cached: Bool

    var id: String { analysisId }

    enum CodingKeys: String, CodingKey {
        case analysisId = "analysis_id"
        case analysisText = "analysis_text"
        case recommendations
        case biomarkerAnalyses = "biomarker_analyses"
        case trainingCorrelations = "training_correlations"
        case sleepCorrelations = "sleep_correlations"
        case overallHealthScore = "overall_health_score"
        case priorityActions = "priority_actions"
        case medicalDisclaimer = "medical_disclaimer"
        case cached
    }

    // MARK: - Computed Properties

    /// Biomarkers that are flagged as concerning (low, high, or critical)
    var concerningBiomarkers: [BiomarkerAnalysis] {
        biomarkerAnalyses.filter { $0.status != .optimal && $0.status != .normal }
    }

    /// Biomarkers in optimal range
    var optimalBiomarkers: [BiomarkerAnalysis] {
        biomarkerAnalyses.filter { $0.status == .optimal }
    }

    /// Health score color based on value
    var healthScoreColor: String {
        switch overallHealthScore {
        case 80...100: return "green"
        case 60..<80: return "yellow"
        default: return "red"
        }
    }

    /// Formatted health score text
    var healthScoreText: String {
        switch overallHealthScore {
        case 90...100: return "Excellent"
        case 80..<90: return "Very Good"
        case 70..<80: return "Good"
        case 60..<70: return "Fair"
        default: return "Needs Attention"
        }
    }
}

// MARK: - Biomarker Analysis

/// Individual biomarker analysis from AI
struct BiomarkerAnalysis: Codable, Identifiable {
    let biomarkerType: String
    let name: String
    let value: Double
    let unit: String
    let status: BiomarkerStatus
    let interpretation: String

    var id: String { biomarkerType }

    enum CodingKeys: String, CodingKey {
        case biomarkerType = "biomarker_type"
        case name
        case value
        case unit
        case status
        case interpretation
    }
}

/// Status of a biomarker value relative to reference ranges
enum BiomarkerStatus: String, Codable {
    case optimal
    case normal
    case low
    case high
    case critical

    /// Display color for the status
    var color: String {
        switch self {
        case .optimal: return "green"
        case .normal: return "blue"
        case .low, .high: return "orange"
        case .critical: return "red"
        }
    }

    /// User-friendly display text
    var displayText: String {
        switch self {
        case .optimal: return "Optimal"
        case .normal: return "Normal"
        case .low: return "Low"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }

    /// Icon for the status
    var iconName: String {
        switch self {
        case .optimal: return "checkmark.circle.fill"
        case .normal: return "circle.fill"
        case .low: return "arrow.down.circle.fill"
        case .high: return "arrow.up.circle.fill"
        case .critical: return "exclamationmark.triangle.fill"
        }
    }

    /// SwiftUI Color for the status (used in views)
    var statusColor: Color {
        switch self {
        case .optimal: return .modusTealAccent
        case .normal: return .modusCyan
        case .low, .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Training/Sleep Correlations

/// Correlation between biomarker and training/sleep factors
struct TrainingCorrelation: Codable, Identifiable {
    let factor: String
    let relationship: String
    let recommendation: String

    var id: String { factor }
}

// MARK: - Lab Analysis Error Response

/// Error response from AI lab analysis edge function
struct LabAnalysisErrorResponse: Codable {
    let error: String
    let medicalDisclaimer: String?

    enum CodingKeys: String, CodingKey {
        case error
        case medicalDisclaimer = "medical_disclaimer"
    }
}

// MARK: - Biomarker Trend Data

/// Historical biomarker data point for trend charts
struct BiomarkerTrendPoint: Identifiable {
    let id: UUID
    let date: Date
    let value: Double
    let biomarkerType: String
    let unit: String
    let optimalLow: Double?
    let optimalHigh: Double?
    let normalLow: Double?
    let normalHigh: Double?

    init(id: UUID = UUID(), date: Date, value: Double, biomarkerType: String, unit: String,
         optimalLow: Double? = nil, optimalHigh: Double? = nil,
         normalLow: Double? = nil, normalHigh: Double? = nil) {
        self.id = id
        self.date = date
        self.value = value
        self.biomarkerType = biomarkerType
        self.unit = unit
        self.optimalLow = optimalLow
        self.optimalHigh = optimalHigh
        self.normalLow = normalLow
        self.normalHigh = normalHigh
    }

    /// Status based on reference ranges
    var status: BiomarkerStatus {
        // Check optimal range first
        if let low = optimalLow, let high = optimalHigh {
            if value >= low && value <= high {
                return .optimal
            }
        }

        // Check normal range
        if let low = normalLow, let high = normalHigh {
            // Check for critical (significantly outside normal)
            if value < low * 0.7 || value > high * 1.3 {
                return .critical
            }
            if value < low {
                return .low
            }
            if value > high {
                return .high
            }
        }

        return .normal
    }
}
