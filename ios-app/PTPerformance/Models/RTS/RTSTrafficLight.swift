//
//  RTSTrafficLight.swift
//  PTPerformance
//
//  Traffic light system for Return-to-Sport activity clearance
//

import Foundation
import SwiftUI

// MARK: - Traffic Light System

/// Traffic light system for Return-to-Sport activity clearance
/// Used across RTS module for phase activity levels, clearance levels, and readiness scores
enum RTSTrafficLight: String, Codable, CaseIterable, Identifiable, Hashable {
    case green   // 80-100: Cleared/Full activity
    case yellow  // 60-79: Caution/Modified activity
    case red     // 0-59: Restricted/Protected

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .green: return "Cleared"
        case .yellow: return "Caution"
        case .red: return "Restricted"
        }
    }

    /// Detailed description for users
    var description: String {
        switch self {
        case .green:
            return "Full activity cleared. Progress to sport-specific training."
        case .yellow:
            return "Modified activity with caution. Continue progression with monitoring."
        case .red:
            return "Restricted activity. Focus on rehabilitation and recovery."
        }
    }

    /// Color for UI display
    var color: Color {
        switch self {
        case .green: return .green
        case .yellow: return .yellow
        case .red: return .red
        }
    }

    /// SF Symbol icon name
    var icon: String {
        switch self {
        case .green: return "checkmark.circle.fill"
        case .yellow: return "exclamationmark.triangle.fill"
        case .red: return "xmark.octagon.fill"
        }
    }

    /// Minimum score threshold for this level
    var minimumScore: Double {
        switch self {
        case .green: return 80
        case .yellow: return 60
        case .red: return 0
        }
    }

    /// Maximum score threshold for this level
    var maximumScore: Double {
        switch self {
        case .green: return 100
        case .yellow: return 79.99
        case .red: return 59.99
        }
    }

    /// Determine traffic light from readiness score
    /// - Parameter score: Readiness score (0-100), scores outside range are clamped
    /// - Returns: Appropriate traffic light status
    static func from(score: Double) -> RTSTrafficLight {
        // Handle extreme scores - scores >= 80 are always green, scores < 60 are always red
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .yellow
        } else {
            return .red
        }
    }

    /// Check if a score falls within this traffic light level
    /// - Parameter score: Score to check (0-100)
    /// - Returns: True if score falls within this level's range
    func contains(score: Double) -> Bool {
        switch self {
        case .green:
            return score >= 80 && score <= 100
        case .yellow:
            return score >= 60 && score < 80
        case .red:
            return score >= 0 && score < 60
        }
    }
}
