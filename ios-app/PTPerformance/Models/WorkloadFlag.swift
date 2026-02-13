//
//  WorkloadFlag.swift
//  PTPerformance
//
//  Model for throwing workload alerts and flags
//

import Foundation

struct WorkloadFlag: Identifiable, Codable, Hashable, Equatable {
    let id: UUID
    let patientId: UUID
    let flagType: FlagType
    let severity: Severity
    let message: String
    let value: Double
    let threshold: Double
    let timestamp: Date
    let isResolved: Bool

    enum FlagType: String, Codable, Hashable {
        case highWorkload = "high_workload"
        case velocityDrop = "velocity_drop"
        case commandLoss = "command_loss"
        case consecutiveDays = "consecutive_days"
        case painIncrease = "pain_increase"

        var displayName: String {
            switch self {
            case .highWorkload: return "High Workload"
            case .velocityDrop: return "Velocity Drop"
            case .commandLoss: return "Command Loss"
            case .consecutiveDays: return "Consecutive Days"
            case .painIncrease: return "Pain Increase"
            }
        }
    }

    enum Severity: String, Codable, Hashable {
        case warning = "yellow"
        case critical = "red"

        var colorName: String {
            self == .critical ? "red" : "orange"
        }
    }

    var icon: String {
        switch flagType {
        case .highWorkload:
            return "chart.line.uptrend.xyaxis"
        case .velocityDrop:
            return "speedometer"
        case .commandLoss:
            return "target"
        case .consecutiveDays:
            return "calendar.badge.exclamationmark"
        case .painIncrease:
            return "exclamationmark.triangle.fill"
        }
    }

    var colorName: String {
        severity.colorName
    }

    // Sample flags for testing
    static let sampleFlags: [WorkloadFlag] = [
        WorkloadFlag(
            id: UUID(),
            patientId: UUID(),
            flagType: .velocityDrop,
            severity: .critical,
            message: "Fastball velocity down 4.2 mph from baseline",
            value: 84.3,
            threshold: 88.5,
            timestamp: Date().addingTimeInterval(-3600),
            isResolved: false
        ),
        WorkloadFlag(
            id: UUID(),
            patientId: UUID(),
            flagType: .highWorkload,
            severity: .warning,
            message: "Pitch count above recommended threshold",
            value: 75,
            threshold: 60,
            timestamp: Date().addingTimeInterval(-7200),
            isResolved: false
        ),
        WorkloadFlag(
            id: UUID(),
            patientId: UUID(),
            flagType: .commandLoss,
            severity: .warning,
            message: "Strike percentage declining (55% vs 65% baseline)",
            value: 55,
            threshold: 65,
            timestamp: Date().addingTimeInterval(-10800),
            isResolved: false
        )
    ]
}
