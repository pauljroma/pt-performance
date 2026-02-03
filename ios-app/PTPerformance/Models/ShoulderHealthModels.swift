//
//  ShoulderHealthModels.swift
//  PTPerformance
//
//  ACP-545: Shoulder Health Dashboard Models
//  Defines data structures for ROM tracking, strength balance, and trend alerts
//

import SwiftUI

// MARK: - Shoulder ROM Measurement

/// Represents a single ROM measurement for internal/external rotation
struct ShoulderROMMeasurement: Codable, Identifiable {
    let id: UUID
    let patientId: UUID
    let side: ShoulderSide
    let internalRotation: Double  // degrees
    let externalRotation: Double  // degrees
    let measuredAt: Date
    let notes: String?

    /// Total arc of motion (IR + ER)
    var totalArc: Double {
        return internalRotation + externalRotation
    }

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case side
        case internalRotation = "internal_rotation"
        case externalRotation = "external_rotation"
        case measuredAt = "measured_at"
        case notes
    }
}

// MARK: - Shoulder Strength Measurement

/// Represents a single strength measurement for internal/external rotation
struct ShoulderStrengthMeasurement: Codable, Identifiable {
    let id: UUID
    let patientId: UUID
    let side: ShoulderSide
    let internalRotationStrength: Double  // force in lbs or N
    let externalRotationStrength: Double  // force in lbs or N
    let unit: StrengthUnit
    let measuredAt: Date
    let notes: String?

    /// ER:IR strength ratio - target is 66-75%
    var erIrRatio: Double {
        guard internalRotationStrength > 0 else { return 0 }
        return (externalRotationStrength / internalRotationStrength) * 100
    }

    /// Whether the ratio is within the healthy range (66-75%)
    var isRatioHealthy: Bool {
        return erIrRatio >= 66 && erIrRatio <= 75
    }

    /// Category for the strength ratio
    var ratioCategory: StrengthRatioCategory {
        if erIrRatio < 60 {
            return .low
        } else if erIrRatio < 66 {
            return .belowTarget
        } else if erIrRatio <= 75 {
            return .optimal
        } else if erIrRatio <= 85 {
            return .aboveTarget
        } else {
            return .high
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case side
        case internalRotationStrength = "internal_rotation_strength"
        case externalRotationStrength = "external_rotation_strength"
        case unit
        case measuredAt = "measured_at"
        case notes
    }
}

// MARK: - Supporting Enums

enum ShoulderSide: String, Codable, CaseIterable {
    case left
    case right
    case dominant
    case nonDominant = "non_dominant"

    var displayName: String {
        switch self {
        case .left: return "Left"
        case .right: return "Right"
        case .dominant: return "Dominant"
        case .nonDominant: return "Non-Dominant"
        }
    }

    var icon: String {
        switch self {
        case .left: return "arrow.left"
        case .right: return "arrow.right"
        case .dominant: return "star.fill"
        case .nonDominant: return "star"
        }
    }
}

enum StrengthUnit: String, Codable, CaseIterable {
    case pounds = "lbs"
    case newtons = "N"
    case kilograms = "kg"

    var displayName: String {
        switch self {
        case .pounds: return "lbs"
        case .newtons: return "N"
        case .kilograms: return "kg"
        }
    }
}

enum StrengthRatioCategory: String, Codable {
    case low       // < 60%
    case belowTarget  // 60-65%
    case optimal   // 66-75%
    case aboveTarget  // 76-85%
    case high      // > 85%

    var displayName: String {
        switch self {
        case .low: return "Low - Strengthen External Rotators"
        case .belowTarget: return "Below Target"
        case .optimal: return "Optimal Range"
        case .aboveTarget: return "Above Target"
        case .high: return "High - Balance Training"
        }
    }

    var color: Color {
        switch self {
        case .low: return .red
        case .belowTarget: return .orange
        case .optimal: return .green
        case .aboveTarget: return .yellow
        case .high: return .orange
        }
    }
}

// MARK: - Shoulder Health Status

/// Overall shoulder health status derived from measurements
struct ShoulderHealthStatus: Codable {
    let side: ShoulderSide
    let romStatus: ROMStatus
    let strengthStatus: StrengthStatus
    let overallHealth: HealthLevel
    let alerts: [ShoulderAlert]
    let recommendations: [String]
    let lastUpdated: Date

    enum CodingKeys: String, CodingKey {
        case side
        case romStatus = "rom_status"
        case strengthStatus = "strength_status"
        case overallHealth = "overall_health"
        case alerts
        case recommendations
        case lastUpdated = "last_updated"
    }
}

struct ROMStatus: Codable {
    let internalRotation: Double
    let externalRotation: Double
    let totalArc: Double
    let deficit: ROMDeficit?

    enum CodingKeys: String, CodingKey {
        case internalRotation = "internal_rotation"
        case externalRotation = "external_rotation"
        case totalArc = "total_arc"
        case deficit
    }
}

struct ROMDeficit: Codable {
    let type: ROMDeficitType
    let amount: Double  // degrees of deficit
    let severity: DeficitSeverity
}

enum ROMDeficitType: String, Codable {
    case internalRotation = "internal_rotation"
    case externalRotation = "external_rotation"
    case totalArc = "total_arc"
    case glenoHumeralInternalRotationDeficit = "gird" // GIRD

    var displayName: String {
        switch self {
        case .internalRotation: return "Internal Rotation Deficit"
        case .externalRotation: return "External Rotation Deficit"
        case .totalArc: return "Total Arc Deficit"
        case .glenoHumeralInternalRotationDeficit: return "GIRD (Glenohumeral Internal Rotation Deficit)"
        }
    }
}

enum DeficitSeverity: String, Codable {
    case mild     // < 10 degrees
    case moderate // 10-20 degrees
    case severe   // > 20 degrees

    var color: Color {
        switch self {
        case .mild: return .yellow
        case .moderate: return .orange
        case .severe: return .red
        }
    }
}

struct StrengthStatus: Codable {
    let erIrRatio: Double
    let category: StrengthRatioCategory
    let internalRotationStrength: Double
    let externalRotationStrength: Double

    enum CodingKeys: String, CodingKey {
        case erIrRatio = "er_ir_ratio"
        case category
        case internalRotationStrength = "internal_rotation_strength"
        case externalRotationStrength = "external_rotation_strength"
    }
}

enum HealthLevel: String, Codable, CaseIterable {
    case excellent
    case good
    case fair
    case needsAttention = "needs_attention"
    case atRisk = "at_risk"

    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .needsAttention: return "Needs Attention"
        case .atRisk: return "At Risk"
        }
    }

    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .yellow
        case .needsAttention: return .orange
        case .atRisk: return .red
        }
    }

    var icon: String {
        switch self {
        case .excellent: return "checkmark.seal.fill"
        case .good: return "checkmark.circle.fill"
        case .fair: return "exclamationmark.circle"
        case .needsAttention: return "exclamationmark.triangle"
        case .atRisk: return "xmark.octagon.fill"
        }
    }
}

// MARK: - Shoulder Alerts

struct ShoulderAlert: Codable, Identifiable {
    let id: UUID
    let type: ShoulderAlertType
    let message: String
    let recommendation: String
    let severity: AlertSeverity
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case message
        case recommendation
        case severity
        case createdAt = "created_at"
    }
}

enum ShoulderAlertType: String, Codable {
    case irDeficit = "ir_deficit"
    case erDeficit = "er_deficit"
    case lowErIrRatio = "low_er_ir_ratio"
    case highErIrRatio = "high_er_ir_ratio"
    case decreasingRom = "decreasing_rom"
    case asymmetry = "asymmetry"
    case gird = "gird"

    var displayName: String {
        switch self {
        case .irDeficit: return "IR Deficit Detected"
        case .erDeficit: return "ER Deficit Detected"
        case .lowErIrRatio: return "Low ER:IR Ratio"
        case .highErIrRatio: return "High ER:IR Ratio"
        case .decreasingRom: return "Decreasing ROM Trend"
        case .asymmetry: return "Side-to-Side Asymmetry"
        case .gird: return "GIRD Detected"
        }
    }

    var icon: String {
        switch self {
        case .irDeficit, .erDeficit, .decreasingRom: return "arrow.down.circle"
        case .lowErIrRatio, .highErIrRatio: return "percent"
        case .asymmetry: return "scale.3d"
        case .gird: return "exclamationmark.triangle.fill"
        }
    }
}

enum AlertSeverity: String, Codable {
    case info
    case warning
    case critical

    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Trend Data

struct ShoulderTrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let label: String
}

struct ShoulderTrendData {
    let romTrends: [ShoulderSide: [ShoulderTrendPoint]]
    let strengthTrends: [ShoulderSide: [ShoulderTrendPoint]]
    let ratioTrends: [ShoulderSide: [ShoulderTrendPoint]]

    static var empty: ShoulderTrendData {
        return ShoulderTrendData(
            romTrends: [:],
            strengthTrends: [:],
            ratioTrends: [:]
        )
    }
}

// MARK: - DTOs for Creating Records

struct CreateShoulderROMDTO: Codable {
    let patientId: UUID
    let side: ShoulderSide
    let internalRotation: Double
    let externalRotation: Double
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case side
        case internalRotation = "internal_rotation"
        case externalRotation = "external_rotation"
        case notes
    }
}

struct CreateShoulderStrengthDTO: Codable {
    let patientId: UUID
    let side: ShoulderSide
    let internalRotationStrength: Double
    let externalRotationStrength: Double
    let unit: StrengthUnit
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case side
        case internalRotationStrength = "internal_rotation_strength"
        case externalRotationStrength = "external_rotation_strength"
        case unit
        case notes
    }
}

// MARK: - Sample Data for Previews

extension ShoulderROMMeasurement {
    static var sample: ShoulderROMMeasurement {
        ShoulderROMMeasurement(
            id: UUID(),
            patientId: UUID(),
            side: .right,
            internalRotation: 70,
            externalRotation: 90,
            measuredAt: Date(),
            notes: nil
        )
    }

    static var samples: [ShoulderROMMeasurement] {
        [
            ShoulderROMMeasurement(id: UUID(), patientId: UUID(), side: .right, internalRotation: 70, externalRotation: 90, measuredAt: Date(), notes: nil),
            ShoulderROMMeasurement(id: UUID(), patientId: UUID(), side: .left, internalRotation: 75, externalRotation: 95, measuredAt: Date(), notes: nil),
            ShoulderROMMeasurement(id: UUID(), patientId: UUID(), side: .right, internalRotation: 65, externalRotation: 88, measuredAt: Date().addingTimeInterval(-86400), notes: nil)
        ]
    }
}

extension ShoulderStrengthMeasurement {
    static var sample: ShoulderStrengthMeasurement {
        ShoulderStrengthMeasurement(
            id: UUID(),
            patientId: UUID(),
            side: .right,
            internalRotationStrength: 30,
            externalRotationStrength: 21,
            unit: .pounds,
            measuredAt: Date(),
            notes: nil
        )
    }

    static var samples: [ShoulderStrengthMeasurement] {
        [
            ShoulderStrengthMeasurement(id: UUID(), patientId: UUID(), side: .right, internalRotationStrength: 30, externalRotationStrength: 21, unit: .pounds, measuredAt: Date(), notes: nil),
            ShoulderStrengthMeasurement(id: UUID(), patientId: UUID(), side: .left, internalRotationStrength: 28, externalRotationStrength: 20, unit: .pounds, measuredAt: Date(), notes: nil)
        ]
    }
}

extension ShoulderHealthStatus {
    static var sample: ShoulderHealthStatus {
        ShoulderHealthStatus(
            side: .right,
            romStatus: ROMStatus(
                internalRotation: 70,
                externalRotation: 90,
                totalArc: 160,
                deficit: nil
            ),
            strengthStatus: StrengthStatus(
                erIrRatio: 70,
                category: .optimal,
                internalRotationStrength: 30,
                externalRotationStrength: 21
            ),
            overallHealth: .good,
            alerts: [],
            recommendations: ["Continue current maintenance routine"],
            lastUpdated: Date()
        )
    }
}

extension ShoulderAlert {
    static var sampleIRDeficit: ShoulderAlert {
        ShoulderAlert(
            id: UUID(),
            type: .irDeficit,
            message: "IR deficit detected - 15 degrees below baseline",
            recommendation: "Add sleeper stretches to your routine",
            severity: .warning,
            createdAt: Date()
        )
    }

    static var sampleLowRatio: ShoulderAlert {
        ShoulderAlert(
            id: UUID(),
            type: .lowErIrRatio,
            message: "ER:IR ratio low at 58%",
            recommendation: "Prioritize cuff strengthening exercises",
            severity: .warning,
            createdAt: Date()
        )
    }
}
