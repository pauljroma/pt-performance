//
//  ProgramType.swift
//  PTPerformance
//
//  Build 294: Program type classification for rehab, performance, and lifestyle programs
//

import Foundation
import SwiftUI

/// The three program categories available in the system
enum ProgramType: String, Codable, CaseIterable, Identifiable {
    case rehab = "rehab"
    case performance = "performance"
    case lifestyle = "lifestyle"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rehab: return "Rehab"
        case .performance: return "Performance"
        case .lifestyle: return "Lifestyle"
        }
    }

    var description: String {
        switch self {
        case .rehab: return "Rehabilitation and injury recovery programs"
        case .performance: return "Athletic performance and sport-specific training"
        case .lifestyle: return "General wellness, fitness, and healthy living"
        }
    }

    var icon: String {
        switch self {
        case .rehab: return "cross.case.fill"
        case .performance: return "bolt.fill"
        case .lifestyle: return "heart.fill"
        }
    }

    var color: Color {
        switch self {
        case .rehab: return .orange
        case .performance: return .blue
        case .lifestyle: return .green
        }
    }

    /// Maps existing ProtocolCategory values to ProgramType
    static func from(protocolCategory: TherapyProtocol.ProtocolCategory) -> ProgramType {
        switch protocolCategory {
        case .postSurgical, .painManagement:
            return .rehab
        case .returnToSport, .throwing:
            return .performance
        case .strengthBuilding:
            return .performance
        case .performance:
            return .performance
        case .lifestyle:
            return .lifestyle
        }
    }

    /// Which ProtocolCategories are valid for this type
    var allowedProtocolCategories: [TherapyProtocol.ProtocolCategory] {
        switch self {
        case .rehab:
            return [.postSurgical, .painManagement]
        case .performance:
            return [.returnToSport, .throwing, .strengthBuilding, .performance]
        case .lifestyle:
            return [.strengthBuilding, .lifestyle]
        }
    }
}
