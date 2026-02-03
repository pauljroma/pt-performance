import SwiftUI

/// Helper model for readiness score ranges and categories
/// Provides categorization and recommendations based on readiness scores
struct ReadinessScoreHelper {
    let score: Double
    
    /// Initialize with a score
    init(score: Double) {
        self.score = score
    }
    
    /// Get the readiness category for this score
    var category: ReadinessCategory {
        return ReadinessCategory.category(for: score)
    }
    
    /// Get the color for this score
    var color: Color {
        return category.color
    }
    
    /// Get the recommendation for this score
    var recommendation: String {
        return category.recommendation
    }
    
    /// Get the formatted score text
    var scoreText: String {
        return String(format: "%.1f", score)
    }
}

/// Typealias for compatibility with ReadinessServiceBuild116
typealias ReadinessScore = ReadinessScoreHelper

/// Readiness category classification with training recommendations
/// Based on Agent 3 specifications
enum ReadinessCategory: String, Codable, CaseIterable, Sendable {
    case elite = "Elite"
    case high = "High"
    case moderate = "Moderate"
    case low = "Low"
    case poor = "Poor"
    
    // MARK: - Score Classification
    
    /// Determine the readiness category for a given score
    /// - Parameter score: Readiness score (0-100)
    /// - Returns: The appropriate readiness category
    static func category(for score: Double) -> ReadinessCategory {
        switch score {
        case 90...100:
            return .elite
        case 75..<90:
            return .high
        case 60..<75:
            return .moderate
        case 45..<60:
            return .low
        default:
            return .poor
        }
    }
    
    // MARK: - Display Properties
    
    /// Color associated with this category
    var color: Color {
        switch self {
        case .elite:
            return .green
        case .high:
            return .blue
        case .moderate:
            return .yellow
        case .low:
            return .orange
        case .poor:
            return .red
        }
    }
    
    /// Display name for this category
    var displayName: String {
        return rawValue
    }
    
    /// Training recommendation for this category
    var recommendation: String {
        switch self {
        case .elite:
            return "Ready for high intensity training"
        case .high:
            return "Ready for normal training load"
        case .moderate:
            return "Proceed with caution, consider lighter work"
        case .low:
            return "Consider light work or active recovery"
        case .poor:
            return "Rest recommended, avoid intense training"
        }
    }
    
    /// Detailed description of the score range
    var scoreRange: String {
        switch self {
        case .elite:
            return "90-100"
        case .high:
            return "75-89"
        case .moderate:
            return "60-74"
        case .low:
            return "45-59"
        case .poor:
            return "0-44"
        }
    }
    
    /// Full description with range and recommendation
    var fullDescription: String {
        return "\(displayName) (\(scoreRange)): \(recommendation)"
    }
    
    // MARK: - Training Modifications
    
    /// Suggested volume adjustment percentage
    var volumeAdjustment: Double {
        switch self {
        case .elite:
            return 0.0      // No adjustment
        case .high:
            return 0.0      // No adjustment
        case .moderate:
            return -0.15    // -15%
        case .low:
            return -0.30    // -30%
        case .poor:
            return -0.50    // -50% or rest
        }
    }
    
    /// Suggested intensity adjustment percentage
    var intensityAdjustment: Double {
        switch self {
        case .elite:
            return 0.0      // No adjustment
        case .high:
            return 0.0      // No adjustment
        case .moderate:
            return -0.10    // -10%
        case .low:
            return -0.20    // -20%
        case .poor:
            return -0.40    // -40% or rest
        }
    }
    
    /// Whether training should be modified
    var shouldModifyTraining: Bool {
        return self != .elite && self != .high
    }
    
    /// Whether rest is recommended
    var recommendsRest: Bool {
        return self == .poor
    }
}

// MARK: - Sample Data

extension ReadinessCategory {
    /// All categories in order from best to worst
    static var allOrdered: [ReadinessCategory] {
        return [.elite, .high, .moderate, .low, .poor]
    }
    
    /// Sample category
    static var sample: ReadinessCategory {
        return .high
    }
}

extension ReadinessScoreHelper {
    /// Sample score helpers for testing
    static let samples: [ReadinessScoreHelper] = [
        ReadinessScoreHelper(score: 95.0),  // Elite
        ReadinessScoreHelper(score: 80.0),  // High
        ReadinessScoreHelper(score: 65.0),  // Moderate
        ReadinessScoreHelper(score: 50.0),  // Low
        ReadinessScoreHelper(score: 35.0)   // Poor
    ]
    
    /// Sample score helper
    static var sample: ReadinessScoreHelper {
        return samples[1]  // High category
    }
}
