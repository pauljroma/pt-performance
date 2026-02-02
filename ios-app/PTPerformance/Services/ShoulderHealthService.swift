//
//  ShoulderHealthService.swift
//  PTPerformance
//
//  ACP-545: Shoulder Health Dashboard Service
//  Stores measurements in Supabase, calculates ratios, detects trends
//

import Foundation
import Supabase

/// Service for managing shoulder health measurements, analysis, and recommendations
@MainActor
class ShoulderHealthService {
    static let shared = ShoulderHealthService()
    private let supabase = PTSupabaseClient.shared
    private let logger = DebugLogger.shared

    private init() {}

    // MARK: - ROM Measurements

    /// Fetch ROM measurements for a patient
    func fetchROMMeasurements(
        patientId: String,
        side: ShoulderSide? = nil,
        limit: Int = 50
    ) async throws -> [ShoulderROMMeasurement] {
        logger.info("SHOULDER ROM", "Fetching ROM for patient: \(patientId)")

        do {
            var query = supabase.client
                .from("shoulder_rom_measurements")
                .select()
                .eq("patient_id", value: patientId)

            if let side = side {
                query = query.eq("side", value: side.rawValue)
            }

            let measurements: [ShoulderROMMeasurement] = try await query
                .order("measured_at", ascending: false)
                .limit(limit)
                .execute()
                .value

            logger.success("SHOULDER ROM", "Fetched \(measurements.count) ROM measurements")
            return measurements
        } catch {
            logger.error("SHOULDER ROM", "Error fetching ROM: \(error)")
            throw error
        }
    }

    /// Create a new ROM measurement
    func createROMMeasurement(_ measurement: CreateShoulderROMDTO) async throws -> ShoulderROMMeasurement {
        logger.info("SHOULDER ROM", "Creating ROM measurement for side: \(measurement.side.displayName)")

        do {
            let result: ShoulderROMMeasurement = try await supabase.client
                .from("shoulder_rom_measurements")
                .insert(measurement)
                .select()
                .single()
                .execute()
                .value

            logger.success("SHOULDER ROM", "Created ROM measurement: \(result.id)")

            // Check for concerning trends after adding new measurement
            try await checkROMTrends(patientId: measurement.patientId.uuidString, side: measurement.side)

            return result
        } catch {
            logger.error("SHOULDER ROM", "Error creating ROM: \(error)")
            throw error
        }
    }

    // MARK: - Strength Measurements

    /// Fetch strength measurements for a patient
    func fetchStrengthMeasurements(
        patientId: String,
        side: ShoulderSide? = nil,
        limit: Int = 50
    ) async throws -> [ShoulderStrengthMeasurement] {
        logger.info("SHOULDER STRENGTH", "Fetching strength for patient: \(patientId)")

        do {
            var query = supabase.client
                .from("shoulder_strength_measurements")
                .select()
                .eq("patient_id", value: patientId)

            if let side = side {
                query = query.eq("side", value: side.rawValue)
            }

            let measurements: [ShoulderStrengthMeasurement] = try await query
                .order("measured_at", ascending: false)
                .limit(limit)
                .execute()
                .value

            logger.success("SHOULDER STRENGTH", "Fetched \(measurements.count) strength measurements")
            return measurements
        } catch {
            logger.error("SHOULDER STRENGTH", "Error fetching strength: \(error)")
            throw error
        }
    }

    /// Create a new strength measurement
    func createStrengthMeasurement(_ measurement: CreateShoulderStrengthDTO) async throws -> ShoulderStrengthMeasurement {
        logger.info("SHOULDER STRENGTH", "Creating strength measurement for side: \(measurement.side.displayName)")

        do {
            let result: ShoulderStrengthMeasurement = try await supabase.client
                .from("shoulder_strength_measurements")
                .insert(measurement)
                .select()
                .single()
                .execute()
                .value

            logger.success("SHOULDER STRENGTH", "Created strength measurement: \(result.id)")

            // Check strength ratio and generate alerts if needed
            try await checkStrengthRatio(measurement: result)

            return result
        } catch {
            logger.error("SHOULDER STRENGTH", "Error creating strength: \(error)")
            throw error
        }
    }

    // MARK: - Health Status Calculation

    /// Calculate overall shoulder health status for a patient
    func calculateHealthStatus(
        patientId: String,
        side: ShoulderSide
    ) async throws -> ShoulderHealthStatus {
        logger.info("SHOULDER HEALTH", "Calculating health status for \(side.displayName) side")

        // Fetch latest measurements
        let romMeasurements = try await fetchROMMeasurements(patientId: patientId, side: side, limit: 10)
        let strengthMeasurements = try await fetchStrengthMeasurements(patientId: patientId, side: side, limit: 10)

        // Get the most recent of each
        let latestROM = romMeasurements.first
        let latestStrength = strengthMeasurements.first

        // Calculate ROM status
        let romStatus = calculateROMStatus(from: latestROM, history: romMeasurements)

        // Calculate strength status
        let strengthStatus = calculateStrengthStatus(from: latestStrength)

        // Generate alerts
        let alerts = generateAlerts(
            romStatus: romStatus,
            strengthStatus: strengthStatus,
            romHistory: romMeasurements,
            strengthHistory: strengthMeasurements
        )

        // Determine overall health level
        let overallHealth = determineOverallHealth(
            romStatus: romStatus,
            strengthStatus: strengthStatus,
            alerts: alerts
        )

        // Generate recommendations
        let recommendations = generateRecommendations(
            romStatus: romStatus,
            strengthStatus: strengthStatus,
            alerts: alerts
        )

        return ShoulderHealthStatus(
            side: side,
            romStatus: romStatus,
            strengthStatus: strengthStatus,
            overallHealth: overallHealth,
            alerts: alerts,
            recommendations: recommendations,
            lastUpdated: Date()
        )
    }

    // MARK: - Trend Analysis

    /// Fetch trend data for charts
    func fetchTrendData(
        patientId: String,
        days: Int = 30
    ) async throws -> ShoulderTrendData {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let startDateStr = ISO8601DateFormatter().string(from: startDate)

        // Fetch ROM data
        let romMeasurements: [ShoulderROMMeasurement] = try await supabase.client
            .from("shoulder_rom_measurements")
            .select()
            .eq("patient_id", value: patientId)
            .gte("measured_at", value: startDateStr)
            .order("measured_at", ascending: true)
            .execute()
            .value

        // Fetch strength data
        let strengthMeasurements: [ShoulderStrengthMeasurement] = try await supabase.client
            .from("shoulder_strength_measurements")
            .select()
            .eq("patient_id", value: patientId)
            .gte("measured_at", value: startDateStr)
            .order("measured_at", ascending: true)
            .execute()
            .value

        // Group by side
        var romTrends: [ShoulderSide: [ShoulderTrendPoint]] = [:]
        var strengthTrends: [ShoulderSide: [ShoulderTrendPoint]] = [:]
        var ratioTrends: [ShoulderSide: [ShoulderTrendPoint]] = [:]

        for side in ShoulderSide.allCases {
            let sideROM = romMeasurements.filter { $0.side == side }
            romTrends[side] = sideROM.map { rom in
                ShoulderTrendPoint(
                    date: rom.measuredAt,
                    value: rom.totalArc,
                    label: "Total Arc"
                )
            }

            let sideStrength = strengthMeasurements.filter { $0.side == side }
            strengthTrends[side] = sideStrength.map { strength in
                ShoulderTrendPoint(
                    date: strength.measuredAt,
                    value: strength.externalRotationStrength,
                    label: "ER Strength"
                )
            }

            ratioTrends[side] = sideStrength.map { strength in
                ShoulderTrendPoint(
                    date: strength.measuredAt,
                    value: strength.erIrRatio,
                    label: "ER:IR Ratio"
                )
            }
        }

        return ShoulderTrendData(
            romTrends: romTrends,
            strengthTrends: strengthTrends,
            ratioTrends: ratioTrends
        )
    }

    // MARK: - Alert Management

    /// Fetch active alerts for a patient
    func fetchAlerts(patientId: String) async throws -> [ShoulderAlert] {
        let alerts: [ShoulderAlert] = try await supabase.client
            .from("shoulder_alerts")
            .select()
            .eq("patient_id", value: patientId)
            .order("created_at", ascending: false)
            .limit(20)
            .execute()
            .value

        return alerts
    }

    /// Create a new alert
    private func createAlert(
        patientId: String,
        type: ShoulderAlertType,
        message: String,
        recommendation: String,
        severity: AlertSeverity
    ) async throws {
        struct AlertInsert: Encodable {
            let patientId: String
            let type: String
            let message: String
            let recommendation: String
            let severity: String

            enum CodingKeys: String, CodingKey {
                case patientId = "patient_id"
                case type
                case message
                case recommendation
                case severity
            }
        }

        let alertData = AlertInsert(
            patientId: patientId,
            type: type.rawValue,
            message: message,
            recommendation: recommendation,
            severity: severity.rawValue
        )

        try await supabase.client
            .from("shoulder_alerts")
            .insert(alertData)
            .execute()

        logger.info("SHOULDER ALERT", "Created alert: \(type.displayName)")
    }

    // MARK: - Side-to-Side Comparison

    /// Calculate side-to-side asymmetry
    func calculateAsymmetry(patientId: String) async throws -> (romDifference: Double?, strengthDifference: Double?) {
        let romMeasurements = try await fetchROMMeasurements(patientId: patientId, limit: 20)
        let strengthMeasurements = try await fetchStrengthMeasurements(patientId: patientId, limit: 20)

        // Find most recent for each side
        let leftROM = romMeasurements.first { $0.side == .left }
        let rightROM = romMeasurements.first { $0.side == .right }

        let leftStrength = strengthMeasurements.first { $0.side == .left }
        let rightStrength = strengthMeasurements.first { $0.side == .right }

        var romDifference: Double?
        var strengthDifference: Double?

        if let left = leftROM, let right = rightROM {
            romDifference = abs(left.totalArc - right.totalArc)
        }

        if let left = leftStrength, let right = rightStrength {
            strengthDifference = abs(left.erIrRatio - right.erIrRatio)
        }

        return (romDifference, strengthDifference)
    }

    // MARK: - Private Helper Methods

    private func calculateROMStatus(from latest: ShoulderROMMeasurement?, history: [ShoulderROMMeasurement]) -> ROMStatus {
        guard let latest = latest else {
            return ROMStatus(
                internalRotation: 0,
                externalRotation: 0,
                totalArc: 0,
                deficit: nil
            )
        }

        // Check for IR deficit (common in overhead athletes)
        // Normal IR is typically 70-90 degrees, deficit if significantly below
        var deficit: ROMDeficit?

        if latest.internalRotation < 60 {
            let severity: DeficitSeverity
            if latest.internalRotation < 40 {
                severity = .severe
            } else if latest.internalRotation < 50 {
                severity = .moderate
            } else {
                severity = .mild
            }

            deficit = ROMDeficit(
                type: .internalRotation,
                amount: 70 - latest.internalRotation,  // Assuming 70 as baseline
                severity: severity
            )
        }

        // Check for GIRD (compare to opposite side if available)
        // GIRD is typically defined as > 18-20 degrees difference from opposite side

        return ROMStatus(
            internalRotation: latest.internalRotation,
            externalRotation: latest.externalRotation,
            totalArc: latest.totalArc,
            deficit: deficit
        )
    }

    private func calculateStrengthStatus(from latest: ShoulderStrengthMeasurement?) -> StrengthStatus {
        guard let latest = latest else {
            return StrengthStatus(
                erIrRatio: 0,
                category: .low,
                internalRotationStrength: 0,
                externalRotationStrength: 0
            )
        }

        return StrengthStatus(
            erIrRatio: latest.erIrRatio,
            category: latest.ratioCategory,
            internalRotationStrength: latest.internalRotationStrength,
            externalRotationStrength: latest.externalRotationStrength
        )
    }

    private func generateAlerts(
        romStatus: ROMStatus,
        strengthStatus: StrengthStatus,
        romHistory: [ShoulderROMMeasurement],
        strengthHistory: [ShoulderStrengthMeasurement]
    ) -> [ShoulderAlert] {
        var alerts: [ShoulderAlert] = []

        // IR Deficit Alert
        if let deficit = romStatus.deficit, deficit.type == .internalRotation {
            alerts.append(ShoulderAlert(
                id: UUID(),
                type: .irDeficit,
                message: "IR deficit detected - \(Int(deficit.amount)) degrees below baseline",
                recommendation: "Add sleeper stretches to your routine",
                severity: deficit.severity == .severe ? .critical : .warning,
                createdAt: Date()
            ))
        }

        // Low ER:IR Ratio Alert
        if strengthStatus.erIrRatio < 66 && strengthStatus.erIrRatio > 0 {
            let severity: AlertSeverity = strengthStatus.erIrRatio < 60 ? .critical : .warning
            alerts.append(ShoulderAlert(
                id: UUID(),
                type: .lowErIrRatio,
                message: "ER:IR ratio low at \(Int(strengthStatus.erIrRatio))%",
                recommendation: "Prioritize cuff strengthening exercises",
                severity: severity,
                createdAt: Date()
            ))
        }

        // Decreasing ROM Trend Alert
        if romHistory.count >= 3 {
            let recent = Array(romHistory.prefix(3))
            let isDecreasing = recent.enumerated().allSatisfy { index, measurement in
                if index == 0 { return true }
                return measurement.totalArc > recent[index - 1].totalArc
            }

            if isDecreasing {
                alerts.append(ShoulderAlert(
                    id: UUID(),
                    type: .decreasingRom,
                    message: "ROM has been decreasing over recent measurements",
                    recommendation: "Increase mobility work and consider assessment",
                    severity: .warning,
                    createdAt: Date()
                ))
            }
        }

        return alerts
    }

    private func determineOverallHealth(
        romStatus: ROMStatus,
        strengthStatus: StrengthStatus,
        alerts: [ShoulderAlert]
    ) -> HealthLevel {
        let criticalAlerts = alerts.filter { $0.severity == .critical }
        let warningAlerts = alerts.filter { $0.severity == .warning }

        if !criticalAlerts.isEmpty {
            return .atRisk
        }

        if warningAlerts.count >= 2 {
            return .needsAttention
        }

        if !warningAlerts.isEmpty {
            return .fair
        }

        if strengthStatus.category == .optimal && romStatus.deficit == nil {
            return .excellent
        }

        return .good
    }

    private func generateRecommendations(
        romStatus: ROMStatus,
        strengthStatus: StrengthStatus,
        alerts: [ShoulderAlert]
    ) -> [String] {
        var recommendations: [String] = []

        // ROM-based recommendations
        if let deficit = romStatus.deficit {
            switch deficit.type {
            case .internalRotation:
                recommendations.append("Perform sleeper stretches 2x daily")
                recommendations.append("Add cross-body stretches to warm-up")
            case .externalRotation:
                recommendations.append("Include doorway stretches in routine")
            case .totalArc:
                recommendations.append("Focus on overall shoulder mobility work")
            case .glenoHumeralInternalRotationDeficit:
                recommendations.append("GIRD protocol: sleeper stretch + posterior capsule work")
            }
        }

        // Strength-based recommendations
        switch strengthStatus.category {
        case .low:
            recommendations.append("Begin external rotation strengthening program")
            recommendations.append("Side-lying ER with light resistance 3x15")
        case .belowTarget:
            recommendations.append("Continue ER strengthening, progress resistance gradually")
        case .optimal:
            recommendations.append("Maintain current strength training routine")
        case .aboveTarget, .high:
            recommendations.append("Consider adding internal rotation work to balance")
        }

        // If no specific recommendations, add maintenance advice
        if recommendations.isEmpty {
            recommendations.append("Continue current maintenance routine")
            recommendations.append("Regular ROM and strength monitoring recommended")
        }

        return recommendations
    }

    private func checkROMTrends(patientId: String, side: ShoulderSide) async throws {
        let measurements = try await fetchROMMeasurements(patientId: patientId, side: side, limit: 5)

        guard measurements.count >= 3 else { return }

        // Check for consistent decrease in total arc
        let arcs = measurements.map { $0.totalArc }
        let isDecreasing = zip(arcs, arcs.dropFirst()).allSatisfy { $0 > $1 }

        if isDecreasing {
            try await createAlert(
                patientId: patientId,
                type: .decreasingRom,
                message: "Total arc ROM has decreased over the last \(measurements.count) measurements",
                recommendation: "Consider increasing mobility work and stretching frequency",
                severity: .warning
            )
        }
    }

    private func checkStrengthRatio(measurement: ShoulderStrengthMeasurement) async throws {
        // Alert if ratio is below target
        if measurement.erIrRatio < 66 {
            try await createAlert(
                patientId: measurement.patientId.uuidString,
                type: .lowErIrRatio,
                message: "ER:IR ratio at \(Int(measurement.erIrRatio))% - target is 66-75%",
                recommendation: "Prioritize external rotator cuff strengthening exercises",
                severity: measurement.erIrRatio < 60 ? .critical : .warning
            )
        }
    }
}
