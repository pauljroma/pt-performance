//
//  CoachingAlertServiceTests.swift
//  PTPerformanceTests
//
//  Unit tests for CoachingAlertService
//  Tests alert fetching, actions, exceptions, safety rules, preferences, and error handling
//

import XCTest
@testable import PTPerformance

// MARK: - AlertType Tests

final class AlertTypeTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testAlertType_RawValues() {
        XCTAssertEqual(CoachingAlert.AlertType.adherenceDropoff.rawValue, "adherence_dropoff")
        XCTAssertEqual(CoachingAlert.AlertType.painIncrease.rawValue, "pain_increase")
        XCTAssertEqual(CoachingAlert.AlertType.missedSessions.rawValue, "missed_sessions")
        XCTAssertEqual(CoachingAlert.AlertType.workloadSpike.rawValue, "workload_spike")
        XCTAssertEqual(CoachingAlert.AlertType.recoveryIssue.rawValue, "recovery_issue")
        XCTAssertEqual(CoachingAlert.AlertType.programCompletion.rawValue, "program_completion")
        XCTAssertEqual(CoachingAlert.AlertType.milestoneReached.rawValue, "milestone_reached")
        XCTAssertEqual(CoachingAlert.AlertType.rtsReadiness.rawValue, "rts_readiness")
        XCTAssertEqual(CoachingAlert.AlertType.assessmentDue.rawValue, "assessment_due")
        XCTAssertEqual(CoachingAlert.AlertType.custom.rawValue, "custom")
    }

    func testAlertType_InitFromRawValue() {
        XCTAssertEqual(CoachingAlert.AlertType(rawValue: "adherence_dropoff"), .adherenceDropoff)
        XCTAssertEqual(CoachingAlert.AlertType(rawValue: "pain_increase"), .painIncrease)
        XCTAssertEqual(CoachingAlert.AlertType(rawValue: "missed_sessions"), .missedSessions)
        XCTAssertEqual(CoachingAlert.AlertType(rawValue: "workload_spike"), .workloadSpike)
        XCTAssertEqual(CoachingAlert.AlertType(rawValue: "recovery_issue"), .recoveryIssue)
        XCTAssertEqual(CoachingAlert.AlertType(rawValue: "program_completion"), .programCompletion)
        XCTAssertEqual(CoachingAlert.AlertType(rawValue: "milestone_reached"), .milestoneReached)
        XCTAssertEqual(CoachingAlert.AlertType(rawValue: "rts_readiness"), .rtsReadiness)
        XCTAssertEqual(CoachingAlert.AlertType(rawValue: "assessment_due"), .assessmentDue)
        XCTAssertEqual(CoachingAlert.AlertType(rawValue: "custom"), .custom)
        XCTAssertNil(CoachingAlert.AlertType(rawValue: "invalid"))
    }

    // MARK: - Display Name Tests

    func testAlertType_DisplayNames() {
        XCTAssertEqual(CoachingAlert.AlertType.adherenceDropoff.displayName, "Adherence Drop")
        XCTAssertEqual(CoachingAlert.AlertType.painIncrease.displayName, "Pain Increase")
        XCTAssertEqual(CoachingAlert.AlertType.missedSessions.displayName, "Missed Sessions")
        XCTAssertEqual(CoachingAlert.AlertType.workloadSpike.displayName, "Workload Spike")
        XCTAssertEqual(CoachingAlert.AlertType.recoveryIssue.displayName, "Recovery Issue")
        XCTAssertEqual(CoachingAlert.AlertType.programCompletion.displayName, "Program Completion")
        XCTAssertEqual(CoachingAlert.AlertType.milestoneReached.displayName, "Milestone Reached")
        XCTAssertEqual(CoachingAlert.AlertType.rtsReadiness.displayName, "RTS Readiness")
        XCTAssertEqual(CoachingAlert.AlertType.assessmentDue.displayName, "Assessment Due")
        XCTAssertEqual(CoachingAlert.AlertType.custom.displayName, "Custom Alert")
    }

    // MARK: - Icon Tests

    func testAlertType_Icons() {
        XCTAssertEqual(CoachingAlert.AlertType.adherenceDropoff.icon, "chart.line.downtrend.xyaxis")
        XCTAssertEqual(CoachingAlert.AlertType.painIncrease.icon, "waveform.path.ecg")
        XCTAssertEqual(CoachingAlert.AlertType.missedSessions.icon, "calendar.badge.exclamationmark")
        XCTAssertEqual(CoachingAlert.AlertType.workloadSpike.icon, "exclamationmark.arrow.triangle.2.circlepath")
        XCTAssertEqual(CoachingAlert.AlertType.recoveryIssue.icon, "bed.double.fill")
        XCTAssertEqual(CoachingAlert.AlertType.programCompletion.icon, "checkmark.seal.fill")
        XCTAssertEqual(CoachingAlert.AlertType.milestoneReached.icon, "star.fill")
        XCTAssertEqual(CoachingAlert.AlertType.rtsReadiness.icon, "figure.run")
        XCTAssertEqual(CoachingAlert.AlertType.assessmentDue.icon, "list.clipboard")
        XCTAssertEqual(CoachingAlert.AlertType.custom.icon, "bell.fill")
    }

    // MARK: - Color Tests

    func testAlertType_Colors() {
        XCTAssertEqual(CoachingAlert.AlertType.adherenceDropoff.color, .orange)
        XCTAssertEqual(CoachingAlert.AlertType.painIncrease.color, .red)
        XCTAssertEqual(CoachingAlert.AlertType.missedSessions.color, .yellow)
        XCTAssertEqual(CoachingAlert.AlertType.workloadSpike.color, .red)
        XCTAssertEqual(CoachingAlert.AlertType.recoveryIssue.color, .purple)
        XCTAssertEqual(CoachingAlert.AlertType.programCompletion.color, .green)
        XCTAssertEqual(CoachingAlert.AlertType.milestoneReached.color, .blue)
        XCTAssertEqual(CoachingAlert.AlertType.rtsReadiness.color, .teal)
        XCTAssertEqual(CoachingAlert.AlertType.assessmentDue.color, .indigo)
        XCTAssertEqual(CoachingAlert.AlertType.custom.color, .gray)
    }

    // MARK: - CaseIterable Tests

    func testAlertType_AllCases() {
        let allCases = CoachingAlert.AlertType.allCases
        XCTAssertEqual(allCases.count, 10)
        XCTAssertTrue(allCases.contains(.adherenceDropoff))
        XCTAssertTrue(allCases.contains(.painIncrease))
        XCTAssertTrue(allCases.contains(.missedSessions))
        XCTAssertTrue(allCases.contains(.workloadSpike))
        XCTAssertTrue(allCases.contains(.recoveryIssue))
        XCTAssertTrue(allCases.contains(.programCompletion))
        XCTAssertTrue(allCases.contains(.milestoneReached))
        XCTAssertTrue(allCases.contains(.rtsReadiness))
        XCTAssertTrue(allCases.contains(.assessmentDue))
        XCTAssertTrue(allCases.contains(.custom))
    }

    // MARK: - Codable Tests

    func testAlertType_Encoding() throws {
        let alertType = CoachingAlert.AlertType.painIncrease
        let encoder = JSONEncoder()
        let data = try encoder.encode(alertType)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertEqual(jsonString, "\"pain_increase\"")
    }

    func testAlertType_Decoding() throws {
        let json = "\"workload_spike\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        let alertType = try decoder.decode(CoachingAlert.AlertType.self, from: json)

        XCTAssertEqual(alertType, .workloadSpike)
    }

    // MARK: - Unique Values Tests

    func testAlertType_UniqueDisplayNames() {
        let names = CoachingAlert.AlertType.allCases.map { $0.displayName }
        let uniqueNames = Set(names)

        XCTAssertEqual(names.count, uniqueNames.count, "Each alert type should have a unique display name")
    }

    func testAlertType_AllHaveIcons() {
        for alertType in CoachingAlert.AlertType.allCases {
            XCTAssertFalse(alertType.icon.isEmpty, "\(alertType) should have an icon")
        }
    }
}

// MARK: - AlertSeverity Tests

final class AlertSeverityTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testAlertSeverity_RawValues() {
        XCTAssertEqual(CoachingAlert.AlertSeverity.low.rawValue, "low")
        XCTAssertEqual(CoachingAlert.AlertSeverity.medium.rawValue, "medium")
        XCTAssertEqual(CoachingAlert.AlertSeverity.high.rawValue, "high")
        XCTAssertEqual(CoachingAlert.AlertSeverity.critical.rawValue, "critical")
    }

    func testAlertSeverity_InitFromRawValue() {
        XCTAssertEqual(CoachingAlert.AlertSeverity(rawValue: "low"), .low)
        XCTAssertEqual(CoachingAlert.AlertSeverity(rawValue: "medium"), .medium)
        XCTAssertEqual(CoachingAlert.AlertSeverity(rawValue: "high"), .high)
        XCTAssertEqual(CoachingAlert.AlertSeverity(rawValue: "critical"), .critical)
        XCTAssertNil(CoachingAlert.AlertSeverity(rawValue: "invalid"))
    }

    // MARK: - Display Name Tests

    func testAlertSeverity_DisplayNames() {
        XCTAssertEqual(CoachingAlert.AlertSeverity.low.displayName, "Low")
        XCTAssertEqual(CoachingAlert.AlertSeverity.medium.displayName, "Medium")
        XCTAssertEqual(CoachingAlert.AlertSeverity.high.displayName, "High")
        XCTAssertEqual(CoachingAlert.AlertSeverity.critical.displayName, "Critical")
    }

    // MARK: - Color Tests

    func testAlertSeverity_Colors() {
        XCTAssertEqual(CoachingAlert.AlertSeverity.low.color, .blue)
        XCTAssertEqual(CoachingAlert.AlertSeverity.medium.color, .yellow)
        XCTAssertEqual(CoachingAlert.AlertSeverity.high.color, .orange)
        XCTAssertEqual(CoachingAlert.AlertSeverity.critical.color, .red)
    }

    // MARK: - Sort Order Tests

    func testAlertSeverity_SortOrder() {
        XCTAssertEqual(CoachingAlert.AlertSeverity.low.sortOrder, 0)
        XCTAssertEqual(CoachingAlert.AlertSeverity.medium.sortOrder, 1)
        XCTAssertEqual(CoachingAlert.AlertSeverity.high.sortOrder, 2)
        XCTAssertEqual(CoachingAlert.AlertSeverity.critical.sortOrder, 3)
    }

    // MARK: - Comparable Tests

    func testAlertSeverity_Comparable() {
        XCTAssertTrue(CoachingAlert.AlertSeverity.low < .medium)
        XCTAssertTrue(CoachingAlert.AlertSeverity.medium < .high)
        XCTAssertTrue(CoachingAlert.AlertSeverity.high < .critical)
        XCTAssertFalse(CoachingAlert.AlertSeverity.critical < .low)
        XCTAssertFalse(CoachingAlert.AlertSeverity.high < .low)
    }

    func testAlertSeverity_Sorting() {
        let severities: [CoachingAlert.AlertSeverity] = [.critical, .low, .high, .medium]
        let sorted = severities.sorted()

        XCTAssertEqual(sorted, [.low, .medium, .high, .critical])
    }

    // MARK: - CaseIterable Tests

    func testAlertSeverity_AllCases() {
        let allCases = CoachingAlert.AlertSeverity.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.low))
        XCTAssertTrue(allCases.contains(.medium))
        XCTAssertTrue(allCases.contains(.high))
        XCTAssertTrue(allCases.contains(.critical))
    }

    // MARK: - Codable Tests

    func testAlertSeverity_Encoding() throws {
        let severity = CoachingAlert.AlertSeverity.critical
        let encoder = JSONEncoder()
        let data = try encoder.encode(severity)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertEqual(jsonString, "\"critical\"")
    }

    func testAlertSeverity_Decoding() throws {
        let json = "\"high\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        let severity = try decoder.decode(CoachingAlert.AlertSeverity.self, from: json)

        XCTAssertEqual(severity, .high)
    }
}

// MARK: - CoachingAlert Tests

final class CoachingAlertTests: XCTestCase {

    // MARK: - Memberwise Initializer Tests

    func testCoachingAlert_MemberwiseInit() {
        let id = UUID()
        let patientId = UUID()
        let therapistId = UUID()
        let createdAt = Date()

        let alert = CoachingAlert(
            id: id,
            patientId: patientId,
            therapistId: therapistId,
            alertType: .painIncrease,
            severity: .high,
            title: "Pain Level Increased",
            message: "Patient reported increased pain level from 3 to 7",
            createdAt: createdAt,
            acknowledgedAt: nil,
            resolvedAt: nil,
            metadata: ["previousPain": "3", "currentPain": "7"]
        )

        XCTAssertEqual(alert.id, id)
        XCTAssertEqual(alert.patientId, patientId)
        XCTAssertEqual(alert.therapistId, therapistId)
        XCTAssertEqual(alert.alertType, .painIncrease)
        XCTAssertEqual(alert.severity, .high)
        XCTAssertEqual(alert.title, "Pain Level Increased")
        XCTAssertEqual(alert.message, "Patient reported increased pain level from 3 to 7")
        XCTAssertNil(alert.acknowledgedAt)
        XCTAssertNil(alert.resolvedAt)
        XCTAssertEqual(alert.metadata?["previousPain"], "3")
        XCTAssertEqual(alert.metadata?["currentPain"], "7")
    }

    func testCoachingAlert_OptionalFields() {
        let alert = CoachingAlert(
            id: UUID(),
            patientId: UUID(),
            therapistId: UUID(),
            alertType: .custom,
            severity: .low,
            title: "Custom Alert",
            message: "A custom alert message",
            createdAt: Date(),
            acknowledgedAt: nil,
            resolvedAt: nil,
            metadata: nil
        )

        XCTAssertNil(alert.acknowledgedAt)
        XCTAssertNil(alert.resolvedAt)
        XCTAssertNil(alert.metadata)
    }

    // MARK: - Computed Properties Tests

    func testCoachingAlert_IsActive_WhenNotResolved() {
        let alert = CoachingAlert(
            id: UUID(),
            patientId: UUID(),
            therapistId: UUID(),
            alertType: .missedSessions,
            severity: .medium,
            title: "Missed Sessions",
            message: "Patient missed 3 sessions",
            createdAt: Date(),
            acknowledgedAt: nil,
            resolvedAt: nil,
            metadata: nil
        )

        XCTAssertTrue(alert.isActive)
    }

    func testCoachingAlert_IsActive_WhenResolved() {
        let alert = CoachingAlert(
            id: UUID(),
            patientId: UUID(),
            therapistId: UUID(),
            alertType: .missedSessions,
            severity: .medium,
            title: "Missed Sessions",
            message: "Patient missed 3 sessions",
            createdAt: Date(),
            acknowledgedAt: nil,
            resolvedAt: Date(),
            metadata: nil
        )

        XCTAssertFalse(alert.isActive)
    }

    func testCoachingAlert_IsAcknowledged_WhenNotAcknowledged() {
        let alert = CoachingAlert(
            id: UUID(),
            patientId: UUID(),
            therapistId: UUID(),
            alertType: .adherenceDropoff,
            severity: .high,
            title: "Adherence Drop",
            message: "Adherence dropped below 50%",
            createdAt: Date(),
            acknowledgedAt: nil,
            resolvedAt: nil,
            metadata: nil
        )

        XCTAssertFalse(alert.isAcknowledged)
    }

    func testCoachingAlert_IsAcknowledged_WhenAcknowledged() {
        let alert = CoachingAlert(
            id: UUID(),
            patientId: UUID(),
            therapistId: UUID(),
            alertType: .adherenceDropoff,
            severity: .high,
            title: "Adherence Drop",
            message: "Adherence dropped below 50%",
            createdAt: Date(),
            acknowledgedAt: Date(),
            resolvedAt: nil,
            metadata: nil
        )

        XCTAssertTrue(alert.isAcknowledged)
    }

    func testCoachingAlert_IsCritical_WhenCritical() {
        let alert = CoachingAlert(
            id: UUID(),
            patientId: UUID(),
            therapistId: UUID(),
            alertType: .workloadSpike,
            severity: .critical,
            title: "Critical Workload",
            message: "Workload increased by 200%",
            createdAt: Date(),
            acknowledgedAt: nil,
            resolvedAt: nil,
            metadata: nil
        )

        XCTAssertTrue(alert.isCritical)
    }

    func testCoachingAlert_IsCritical_WhenNotCritical() {
        let alert = CoachingAlert(
            id: UUID(),
            patientId: UUID(),
            therapistId: UUID(),
            alertType: .workloadSpike,
            severity: .high,
            title: "High Workload",
            message: "Workload increased significantly",
            createdAt: Date(),
            acknowledgedAt: nil,
            resolvedAt: nil,
            metadata: nil
        )

        XCTAssertFalse(alert.isCritical)
    }

    // MARK: - Identifiable Tests

    func testCoachingAlert_Identifiable() {
        let id = UUID()
        let alert = CoachingAlert(
            id: id,
            patientId: UUID(),
            therapistId: UUID(),
            alertType: .custom,
            severity: .low,
            title: "Test",
            message: "Test message",
            createdAt: Date(),
            acknowledgedAt: nil,
            resolvedAt: nil,
            metadata: nil
        )

        XCTAssertEqual(alert.id, id)
    }

    // MARK: - Hashable Tests

    func testCoachingAlert_Hashable() {
        let id = UUID()
        let patientId = UUID()
        let therapistId = UUID()
        let date = Date()

        let alert1 = CoachingAlert(
            id: id,
            patientId: patientId,
            therapistId: therapistId,
            alertType: .painIncrease,
            severity: .high,
            title: "Pain",
            message: "Pain increased",
            createdAt: date,
            acknowledgedAt: nil,
            resolvedAt: nil,
            metadata: nil
        )

        let alert2 = CoachingAlert(
            id: id,
            patientId: patientId,
            therapistId: therapistId,
            alertType: .painIncrease,
            severity: .high,
            title: "Pain",
            message: "Pain increased",
            createdAt: date,
            acknowledgedAt: nil,
            resolvedAt: nil,
            metadata: nil
        )

        XCTAssertEqual(alert1, alert2)
        XCTAssertEqual(alert1.hashValue, alert2.hashValue)
    }

    // MARK: - Equatable Tests

    func testCoachingAlert_Equatable() {
        let id = UUID()
        let patientId = UUID()
        let therapistId = UUID()
        let date = Date()

        let alert1 = CoachingAlert(
            id: id,
            patientId: patientId,
            therapistId: therapistId,
            alertType: .recoveryIssue,
            severity: .medium,
            title: "Recovery",
            message: "Recovery issue detected",
            createdAt: date,
            acknowledgedAt: nil,
            resolvedAt: nil,
            metadata: nil
        )

        let alert2 = CoachingAlert(
            id: id,
            patientId: patientId,
            therapistId: therapistId,
            alertType: .recoveryIssue,
            severity: .medium,
            title: "Recovery",
            message: "Recovery issue detected",
            createdAt: date,
            acknowledgedAt: nil,
            resolvedAt: nil,
            metadata: nil
        )

        XCTAssertEqual(alert1, alert2)
    }

    func testCoachingAlert_NotEqual_DifferentIds() {
        let date = Date()
        let patientId = UUID()
        let therapistId = UUID()

        let alert1 = CoachingAlert(
            id: UUID(),
            patientId: patientId,
            therapistId: therapistId,
            alertType: .custom,
            severity: .low,
            title: "Test",
            message: "Test",
            createdAt: date,
            acknowledgedAt: nil,
            resolvedAt: nil,
            metadata: nil
        )

        let alert2 = CoachingAlert(
            id: UUID(),
            patientId: patientId,
            therapistId: therapistId,
            alertType: .custom,
            severity: .low,
            title: "Test",
            message: "Test",
            createdAt: date,
            acknowledgedAt: nil,
            resolvedAt: nil,
            metadata: nil
        )

        XCTAssertNotEqual(alert1, alert2)
    }
}

// MARK: - ServicePatientException Tests

final class ServicePatientExceptionTests: XCTestCase {

    // MARK: - Memberwise Initializer Tests

    func testServicePatientException_MemberwiseInit() {
        let id = UUID()
        let patientId = UUID()
        let oldestDate = Date().addingTimeInterval(-86400 * 7)
        let latestDate = Date()

        let exception = ServicePatientException(
            id: id,
            patientId: patientId,
            firstName: "John",
            lastName: "Doe",
            alertCount: 5,
            criticalCount: 2,
            highCount: 3,
            oldestAlertDate: oldestDate,
            latestAlertDate: latestDate
        )

        XCTAssertEqual(exception.id, id)
        XCTAssertEqual(exception.patientId, patientId)
        XCTAssertEqual(exception.firstName, "John")
        XCTAssertEqual(exception.lastName, "Doe")
        XCTAssertEqual(exception.alertCount, 5)
        XCTAssertEqual(exception.criticalCount, 2)
        XCTAssertEqual(exception.highCount, 3)
        XCTAssertEqual(exception.oldestAlertDate, oldestDate)
        XCTAssertEqual(exception.latestAlertDate, latestDate)
    }

    // MARK: - Computed Properties Tests

    func testServicePatientException_FullName() {
        let exception = ServicePatientException(
            id: UUID(),
            patientId: UUID(),
            firstName: "Jane",
            lastName: "Smith",
            alertCount: 1,
            criticalCount: 0,
            highCount: 1,
            oldestAlertDate: nil,
            latestAlertDate: nil
        )

        XCTAssertEqual(exception.fullName, "Jane Smith")
    }

    func testServicePatientException_HasCriticalAlerts_WhenTrue() {
        let exception = ServicePatientException(
            id: UUID(),
            patientId: UUID(),
            firstName: "Test",
            lastName: "Patient",
            alertCount: 3,
            criticalCount: 1,
            highCount: 2,
            oldestAlertDate: nil,
            latestAlertDate: nil
        )

        XCTAssertTrue(exception.hasCriticalAlerts)
    }

    func testServicePatientException_HasCriticalAlerts_WhenFalse() {
        let exception = ServicePatientException(
            id: UUID(),
            patientId: UUID(),
            firstName: "Test",
            lastName: "Patient",
            alertCount: 3,
            criticalCount: 0,
            highCount: 3,
            oldestAlertDate: nil,
            latestAlertDate: nil
        )

        XCTAssertFalse(exception.hasCriticalAlerts)
    }

    // MARK: - Identifiable Tests

    func testServicePatientException_Identifiable() {
        let id = UUID()
        let exception = ServicePatientException(
            id: id,
            patientId: UUID(),
            firstName: "Test",
            lastName: "User",
            alertCount: 0,
            criticalCount: 0,
            highCount: 0,
            oldestAlertDate: nil,
            latestAlertDate: nil
        )

        XCTAssertEqual(exception.id, id)
    }

    // MARK: - Equatable Tests

    func testServicePatientException_Equatable() {
        let id = UUID()
        let patientId = UUID()

        let exception1 = ServicePatientException(
            id: id,
            patientId: patientId,
            firstName: "Test",
            lastName: "User",
            alertCount: 2,
            criticalCount: 1,
            highCount: 1,
            oldestAlertDate: nil,
            latestAlertDate: nil
        )

        let exception2 = ServicePatientException(
            id: id,
            patientId: patientId,
            firstName: "Test",
            lastName: "User",
            alertCount: 2,
            criticalCount: 1,
            highCount: 1,
            oldestAlertDate: nil,
            latestAlertDate: nil
        )

        XCTAssertEqual(exception1, exception2)
    }
}

// MARK: - ServiceExceptionSummary Tests

final class ServiceExceptionSummaryTests: XCTestCase {

    // MARK: - Memberwise Initializer Tests

    func testServiceExceptionSummary_MemberwiseInit() {
        let oldestDate = Date().addingTimeInterval(-86400 * 14)

        let summary = ServiceExceptionSummary(
            totalActiveAlerts: 15,
            criticalCount: 3,
            highCount: 5,
            mediumCount: 4,
            lowCount: 3,
            patientsNeedingAttention: 8,
            oldestUnresolvedDate: oldestDate
        )

        XCTAssertEqual(summary.totalActiveAlerts, 15)
        XCTAssertEqual(summary.criticalCount, 3)
        XCTAssertEqual(summary.highCount, 5)
        XCTAssertEqual(summary.mediumCount, 4)
        XCTAssertEqual(summary.lowCount, 3)
        XCTAssertEqual(summary.patientsNeedingAttention, 8)
        XCTAssertEqual(summary.oldestUnresolvedDate, oldestDate)
    }

    // MARK: - Computed Properties Tests

    func testServiceExceptionSummary_HasAlerts_WhenTrue() {
        let summary = ServiceExceptionSummary(
            totalActiveAlerts: 5,
            criticalCount: 0,
            highCount: 2,
            mediumCount: 2,
            lowCount: 1,
            patientsNeedingAttention: 3,
            oldestUnresolvedDate: nil
        )

        XCTAssertTrue(summary.hasAlerts)
    }

    func testServiceExceptionSummary_HasAlerts_WhenFalse() {
        let summary = ServiceExceptionSummary(
            totalActiveAlerts: 0,
            criticalCount: 0,
            highCount: 0,
            mediumCount: 0,
            lowCount: 0,
            patientsNeedingAttention: 0,
            oldestUnresolvedDate: nil
        )

        XCTAssertFalse(summary.hasAlerts)
    }

    func testServiceExceptionSummary_HasUrgentAlerts_WithCritical() {
        let summary = ServiceExceptionSummary(
            totalActiveAlerts: 3,
            criticalCount: 1,
            highCount: 0,
            mediumCount: 1,
            lowCount: 1,
            patientsNeedingAttention: 2,
            oldestUnresolvedDate: nil
        )

        XCTAssertTrue(summary.hasUrgentAlerts)
    }

    func testServiceExceptionSummary_HasUrgentAlerts_WithHigh() {
        let summary = ServiceExceptionSummary(
            totalActiveAlerts: 3,
            criticalCount: 0,
            highCount: 2,
            mediumCount: 1,
            lowCount: 0,
            patientsNeedingAttention: 2,
            oldestUnresolvedDate: nil
        )

        XCTAssertTrue(summary.hasUrgentAlerts)
    }

    func testServiceExceptionSummary_HasUrgentAlerts_WhenFalse() {
        let summary = ServiceExceptionSummary(
            totalActiveAlerts: 3,
            criticalCount: 0,
            highCount: 0,
            mediumCount: 2,
            lowCount: 1,
            patientsNeedingAttention: 2,
            oldestUnresolvedDate: nil
        )

        XCTAssertFalse(summary.hasUrgentAlerts)
    }

    // MARK: - Empty Summary Tests

    func testServiceExceptionSummary_Empty() {
        let empty = ServiceExceptionSummary.empty

        XCTAssertEqual(empty.totalActiveAlerts, 0)
        XCTAssertEqual(empty.criticalCount, 0)
        XCTAssertEqual(empty.highCount, 0)
        XCTAssertEqual(empty.mediumCount, 0)
        XCTAssertEqual(empty.lowCount, 0)
        XCTAssertEqual(empty.patientsNeedingAttention, 0)
        XCTAssertNil(empty.oldestUnresolvedDate)
        XCTAssertFalse(empty.hasAlerts)
        XCTAssertFalse(empty.hasUrgentAlerts)
    }

    // MARK: - Equatable Tests

    func testServiceExceptionSummary_Equatable() {
        let summary1 = ServiceExceptionSummary(
            totalActiveAlerts: 10,
            criticalCount: 2,
            highCount: 3,
            mediumCount: 3,
            lowCount: 2,
            patientsNeedingAttention: 5,
            oldestUnresolvedDate: nil
        )

        let summary2 = ServiceExceptionSummary(
            totalActiveAlerts: 10,
            criticalCount: 2,
            highCount: 3,
            mediumCount: 3,
            lowCount: 2,
            patientsNeedingAttention: 5,
            oldestUnresolvedDate: nil
        )

        XCTAssertEqual(summary1, summary2)
    }
}

// MARK: - ServiceSafetyRule Tests

final class ServiceSafetyRuleTests: XCTestCase {

    // MARK: - Memberwise Initializer Tests

    func testServiceSafetyRule_MemberwiseInit() {
        let id = UUID()
        let createdBy = UUID()
        let createdAt = Date()
        let updatedAt = Date()

        let rule = ServiceSafetyRule(
            id: id,
            name: "Pain Threshold Alert",
            description: "Alert when pain exceeds threshold",
            ruleType: "pain_increase",
            priority: "high",
            threshold: 7.0,
            comparisonOperator: ">=",
            timeWindowDays: 7,
            isActive: true,
            isSystemRule: true,
            createdBy: createdBy,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        XCTAssertEqual(rule.id, id)
        XCTAssertEqual(rule.name, "Pain Threshold Alert")
        XCTAssertEqual(rule.description, "Alert when pain exceeds threshold")
        XCTAssertEqual(rule.ruleType, "pain_increase")
        XCTAssertEqual(rule.priority, "high")
        XCTAssertEqual(rule.threshold, 7.0)
        XCTAssertEqual(rule.comparisonOperator, ">=")
        XCTAssertEqual(rule.timeWindowDays, 7)
        XCTAssertTrue(rule.isActive)
        XCTAssertTrue(rule.isSystemRule)
        XCTAssertEqual(rule.createdBy, createdBy)
    }

    func testServiceSafetyRule_OptionalFields() {
        let rule = ServiceSafetyRule(
            id: UUID(),
            name: "Simple Rule",
            description: nil,
            ruleType: "custom",
            priority: "low",
            threshold: 5.0,
            comparisonOperator: ">",
            timeWindowDays: nil,
            isActive: true,
            isSystemRule: false,
            createdBy: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        XCTAssertNil(rule.description)
        XCTAssertNil(rule.timeWindowDays)
        XCTAssertNil(rule.createdBy)
        XCTAssertFalse(rule.isSystemRule)
    }

    // MARK: - Identifiable Tests

    func testServiceSafetyRule_Identifiable() {
        let id = UUID()
        let rule = ServiceSafetyRule(
            id: id,
            name: "Test Rule",
            description: nil,
            ruleType: "test",
            priority: "medium",
            threshold: 1.0,
            comparisonOperator: "==",
            timeWindowDays: nil,
            isActive: true,
            isSystemRule: false,
            createdBy: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        XCTAssertEqual(rule.id, id)
    }

    // MARK: - Equatable Tests

    func testServiceSafetyRule_Equatable() {
        let id = UUID()
        let date = Date()

        let rule1 = ServiceSafetyRule(
            id: id,
            name: "Test",
            description: nil,
            ruleType: "test",
            priority: "low",
            threshold: 5.0,
            comparisonOperator: ">",
            timeWindowDays: nil,
            isActive: true,
            isSystemRule: false,
            createdBy: nil,
            createdAt: date,
            updatedAt: date
        )

        let rule2 = ServiceSafetyRule(
            id: id,
            name: "Test",
            description: nil,
            ruleType: "test",
            priority: "low",
            threshold: 5.0,
            comparisonOperator: ">",
            timeWindowDays: nil,
            isActive: true,
            isSystemRule: false,
            createdBy: nil,
            createdAt: date,
            updatedAt: date
        )

        XCTAssertEqual(rule1, rule2)
    }
}

// MARK: - ServiceCoachingPreferences Tests

final class ServiceCoachingPreferencesTests: XCTestCase {

    // MARK: - Memberwise Initializer Tests

    func testServiceCoachingPreferences_MemberwiseInit() {
        let id = UUID()
        let therapistId = UUID()
        let createdAt = Date()
        let updatedAt = Date()

        let preferences = ServiceCoachingPreferences(
            id: id,
            therapistId: therapistId,
            emailNotifications: true,
            pushNotifications: true,
            criticalAlertSound: true,
            dailyDigestEnabled: true,
            dailyDigestTime: "08:00",
            alertPrioritiesEnabled: ["critical", "high", "medium"],
            alertTypesEnabled: ["pain_increase", "missed_sessions", "adherence_dropoff"],
            autoAcknowledgeHours: 24,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        XCTAssertEqual(preferences.id, id)
        XCTAssertEqual(preferences.therapistId, therapistId)
        XCTAssertTrue(preferences.emailNotifications)
        XCTAssertTrue(preferences.pushNotifications)
        XCTAssertTrue(preferences.criticalAlertSound)
        XCTAssertTrue(preferences.dailyDigestEnabled)
        XCTAssertEqual(preferences.dailyDigestTime, "08:00")
        XCTAssertEqual(preferences.alertPrioritiesEnabled, ["critical", "high", "medium"])
        XCTAssertEqual(preferences.alertTypesEnabled, ["pain_increase", "missed_sessions", "adherence_dropoff"])
        XCTAssertEqual(preferences.autoAcknowledgeHours, 24)
    }

    func testServiceCoachingPreferences_OptionalFields() {
        let preferences = ServiceCoachingPreferences(
            id: UUID(),
            therapistId: UUID(),
            emailNotifications: false,
            pushNotifications: false,
            criticalAlertSound: false,
            dailyDigestEnabled: false,
            dailyDigestTime: nil,
            alertPrioritiesEnabled: [],
            alertTypesEnabled: [],
            autoAcknowledgeHours: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        XCTAssertNil(preferences.dailyDigestTime)
        XCTAssertNil(preferences.autoAcknowledgeHours)
        XCTAssertTrue(preferences.alertPrioritiesEnabled.isEmpty)
        XCTAssertTrue(preferences.alertTypesEnabled.isEmpty)
    }

    // MARK: - Equatable Tests

    func testServiceCoachingPreferences_Equatable() {
        let id = UUID()
        let therapistId = UUID()
        let date = Date()

        let prefs1 = ServiceCoachingPreferences(
            id: id,
            therapistId: therapistId,
            emailNotifications: true,
            pushNotifications: true,
            criticalAlertSound: true,
            dailyDigestEnabled: false,
            dailyDigestTime: nil,
            alertPrioritiesEnabled: ["critical"],
            alertTypesEnabled: ["pain_increase"],
            autoAcknowledgeHours: nil,
            createdAt: date,
            updatedAt: date
        )

        let prefs2 = ServiceCoachingPreferences(
            id: id,
            therapistId: therapistId,
            emailNotifications: true,
            pushNotifications: true,
            criticalAlertSound: true,
            dailyDigestEnabled: false,
            dailyDigestTime: nil,
            alertPrioritiesEnabled: ["critical"],
            alertTypesEnabled: ["pain_increase"],
            autoAcknowledgeHours: nil,
            createdAt: date,
            updatedAt: date
        )

        XCTAssertEqual(prefs1, prefs2)
    }
}

// MARK: - CoachingAlertError Tests

final class CoachingAlertErrorTests: XCTestCase {

    // MARK: - Error Description Tests

    func testCoachingAlertError_ErrorDescriptions() {
        let underlyingError = NSError(domain: "test", code: 1, userInfo: nil)

        XCTAssertEqual(CoachingAlertError.fetchFailed(underlyingError).errorDescription, "Couldn't Load Alerts")
        XCTAssertEqual(CoachingAlertError.acknowledgeFailed(underlyingError).errorDescription, "Couldn't Acknowledge Alert")
        XCTAssertEqual(CoachingAlertError.resolveFailed(underlyingError).errorDescription, "Couldn't Resolve Alert")
        XCTAssertEqual(CoachingAlertError.dismissFailed(underlyingError).errorDescription, "Couldn't Dismiss Alert")
        XCTAssertEqual(CoachingAlertError.updateFailed(underlyingError).errorDescription, "Couldn't Update Settings")
        XCTAssertEqual(CoachingAlertError.alertNotFound.errorDescription, "Alert Not Found")
        XCTAssertEqual(CoachingAlertError.notAuthenticated.errorDescription, "Not Signed In")
        XCTAssertEqual(CoachingAlertError.invalidUUID("bad-uuid").errorDescription, "Invalid Identifier")
    }

    // MARK: - Recovery Suggestion Tests

    func testCoachingAlertError_RecoverySuggestions() {
        let underlyingError = NSError(domain: "test", code: 1, userInfo: nil)

        XCTAssertEqual(
            CoachingAlertError.fetchFailed(underlyingError).recoverySuggestion,
            "We couldn't load your alerts. Please check your connection and try again."
        )
        XCTAssertEqual(
            CoachingAlertError.acknowledgeFailed(underlyingError).recoverySuggestion,
            "We couldn't mark this alert as acknowledged. Please try again."
        )
        XCTAssertEqual(
            CoachingAlertError.resolveFailed(underlyingError).recoverySuggestion,
            "We couldn't resolve this alert. Please try again."
        )
        XCTAssertEqual(
            CoachingAlertError.dismissFailed(underlyingError).recoverySuggestion,
            "We couldn't dismiss this alert. Please try again."
        )
        XCTAssertEqual(
            CoachingAlertError.updateFailed(underlyingError).recoverySuggestion,
            "We couldn't save your settings. Please try again."
        )
        XCTAssertEqual(
            CoachingAlertError.alertNotFound.recoverySuggestion,
            "This alert may have been removed. Please refresh your alerts."
        )
        XCTAssertEqual(
            CoachingAlertError.notAuthenticated.recoverySuggestion,
            "Please sign in to manage alerts."
        )
        XCTAssertEqual(
            CoachingAlertError.invalidUUID("test").recoverySuggestion,
            "An internal error occurred. Please try again."
        )
    }

    // MARK: - Should Retry Tests

    func testCoachingAlertError_ShouldRetry() {
        let underlyingError = NSError(domain: "test", code: 1, userInfo: nil)

        // Errors that should retry
        XCTAssertTrue(CoachingAlertError.fetchFailed(underlyingError).shouldRetry)
        XCTAssertTrue(CoachingAlertError.acknowledgeFailed(underlyingError).shouldRetry)
        XCTAssertTrue(CoachingAlertError.resolveFailed(underlyingError).shouldRetry)
        XCTAssertTrue(CoachingAlertError.dismissFailed(underlyingError).shouldRetry)
        XCTAssertTrue(CoachingAlertError.updateFailed(underlyingError).shouldRetry)

        // Errors that should not retry
        XCTAssertFalse(CoachingAlertError.alertNotFound.shouldRetry)
        XCTAssertFalse(CoachingAlertError.notAuthenticated.shouldRetry)
        XCTAssertFalse(CoachingAlertError.invalidUUID("test").shouldRetry)
    }

    // MARK: - Underlying Error Tests

    func testCoachingAlertError_UnderlyingError() {
        let underlyingError = NSError(domain: "TestDomain", code: 42, userInfo: [NSLocalizedDescriptionKey: "Test error"])

        // Errors with underlying error
        XCTAssertNotNil(CoachingAlertError.fetchFailed(underlyingError).underlyingError)
        XCTAssertNotNil(CoachingAlertError.acknowledgeFailed(underlyingError).underlyingError)
        XCTAssertNotNil(CoachingAlertError.resolveFailed(underlyingError).underlyingError)
        XCTAssertNotNil(CoachingAlertError.dismissFailed(underlyingError).underlyingError)
        XCTAssertNotNil(CoachingAlertError.updateFailed(underlyingError).underlyingError)

        // Errors without underlying error
        XCTAssertNil(CoachingAlertError.alertNotFound.underlyingError)
        XCTAssertNil(CoachingAlertError.notAuthenticated.underlyingError)
        XCTAssertNil(CoachingAlertError.invalidUUID("test").underlyingError)
    }

    func testCoachingAlertError_UnderlyingErrorDetails() {
        let underlyingError = NSError(domain: "TestDomain", code: 42, userInfo: nil)
        let error = CoachingAlertError.fetchFailed(underlyingError)

        if let underlying = error.underlyingError as? NSError {
            XCTAssertEqual(underlying.domain, "TestDomain")
            XCTAssertEqual(underlying.code, 42)
        } else {
            XCTFail("Expected underlying error to be an NSError")
        }
    }

    // MARK: - LocalizedError Conformance Tests

    func testCoachingAlertError_LocalizedErrorConformance() {
        let error = CoachingAlertError.alertNotFound

        // LocalizedError provides localizedDescription via errorDescription
        XCTAssertEqual(error.localizedDescription, "Alert Not Found")
    }
}

// MARK: - CoachingAlertService Tests

@MainActor
final class CoachingAlertServiceTests: XCTestCase {

    // MARK: - Singleton Tests

    func testSharedInstanceExists() async {
        let instance = await CoachingAlertService.shared
        XCTAssertNotNil(instance)
    }

    // MARK: - Invalid UUID String Tests

    func testFetchActiveAlerts_InvalidUUID_ThrowsError() async {
        let service = await CoachingAlertService.shared

        do {
            _ = try await service.fetchActiveAlerts(therapistId: "not-a-valid-uuid")
            XCTFail("Expected invalidUUID error to be thrown")
        } catch let error as CoachingAlertError {
            if case .invalidUUID(let invalidString) = error {
                XCTAssertEqual(invalidString, "not-a-valid-uuid")
            } else {
                XCTFail("Expected invalidUUID error, got \(error)")
            }
        } catch {
            XCTFail("Expected CoachingAlertError, got \(error)")
        }
    }

    func testFetchPatientAlerts_InvalidUUID_ThrowsError() async {
        let service = await CoachingAlertService.shared

        do {
            _ = try await service.fetchPatientAlerts(patientId: "invalid-uuid-string")
            XCTFail("Expected invalidUUID error to be thrown")
        } catch let error as CoachingAlertError {
            if case .invalidUUID(let invalidString) = error {
                XCTAssertEqual(invalidString, "invalid-uuid-string")
            } else {
                XCTFail("Expected invalidUUID error, got \(error)")
            }
        } catch {
            XCTFail("Expected CoachingAlertError, got \(error)")
        }
    }

    func testAcknowledgeAlert_InvalidUUID_ThrowsError() async {
        let service = await CoachingAlertService.shared

        do {
            _ = try await service.acknowledgeAlert(alertId: "bad-id")
            XCTFail("Expected invalidUUID error to be thrown")
        } catch let error as CoachingAlertError {
            if case .invalidUUID(let invalidString) = error {
                XCTAssertEqual(invalidString, "bad-id")
            } else {
                XCTFail("Expected invalidUUID error, got \(error)")
            }
        } catch {
            XCTFail("Expected CoachingAlertError, got \(error)")
        }
    }

    func testResolveAlert_InvalidUUID_ThrowsError() async {
        let service = await CoachingAlertService.shared

        do {
            _ = try await service.resolveAlert(alertId: "bad-uuid", notes: "test")
            XCTFail("Expected invalidUUID error to be thrown")
        } catch let error as CoachingAlertError {
            if case .invalidUUID(let invalidString) = error {
                XCTAssertEqual(invalidString, "bad-uuid")
            } else {
                XCTFail("Expected invalidUUID error, got \(error)")
            }
        } catch {
            XCTFail("Expected CoachingAlertError, got \(error)")
        }
    }

    func testDismissAlert_InvalidUUID_ThrowsError() async {
        let service = await CoachingAlertService.shared

        do {
            _ = try await service.dismissAlert(alertId: "123-not-valid")
            XCTFail("Expected invalidUUID error to be thrown")
        } catch let error as CoachingAlertError {
            if case .invalidUUID(let invalidString) = error {
                XCTAssertEqual(invalidString, "123-not-valid")
            } else {
                XCTFail("Expected invalidUUID error, got \(error)")
            }
        } catch {
            XCTFail("Expected CoachingAlertError, got \(error)")
        }
    }

    func testFetchPatientExceptions_InvalidUUID_ThrowsError() async {
        let service = await CoachingAlertService.shared

        do {
            _ = try await service.fetchPatientExceptions(therapistId: "xyz")
            XCTFail("Expected invalidUUID error to be thrown")
        } catch let error as CoachingAlertError {
            if case .invalidUUID(let invalidString) = error {
                XCTAssertEqual(invalidString, "xyz")
            } else {
                XCTFail("Expected invalidUUID error, got \(error)")
            }
        } catch {
            XCTFail("Expected CoachingAlertError, got \(error)")
        }
    }

    func testFetchExceptionSummary_InvalidUUID_ThrowsError() async {
        let service = await CoachingAlertService.shared

        do {
            _ = try await service.fetchExceptionSummary(therapistId: "")
            XCTFail("Expected invalidUUID error to be thrown")
        } catch let error as CoachingAlertError {
            if case .invalidUUID(let invalidString) = error {
                XCTAssertEqual(invalidString, "")
            } else {
                XCTFail("Expected invalidUUID error, got \(error)")
            }
        } catch {
            XCTFail("Expected CoachingAlertError, got \(error)")
        }
    }

    func testFetchPreferences_InvalidUUID_ThrowsError() async {
        let service = await CoachingAlertService.shared

        do {
            _ = try await service.fetchPreferences(therapistId: "abc-123")
            XCTFail("Expected invalidUUID error to be thrown")
        } catch let error as CoachingAlertError {
            if case .invalidUUID(let invalidString) = error {
                XCTAssertEqual(invalidString, "abc-123")
            } else {
                XCTFail("Expected invalidUUID error, got \(error)")
            }
        } catch {
            XCTFail("Expected CoachingAlertError, got \(error)")
        }
    }

    // MARK: - Valid UUID String Tests

    func testFetchActiveAlerts_ValidUUID_DoesNotThrowInvalidUUIDError() async {
        let service = await CoachingAlertService.shared
        let validUUID = UUID().uuidString

        do {
            _ = try await service.fetchActiveAlerts(therapistId: validUUID)
            // If we get here without an invalidUUID error, the UUID parsing worked
            // The call may still fail due to network/auth issues, but that's expected
        } catch let error as CoachingAlertError {
            if case .invalidUUID = error {
                XCTFail("Should not throw invalidUUID for valid UUID string")
            }
            // Other errors (fetchFailed, etc.) are acceptable in test environment
        } catch {
            // Other errors are acceptable
        }
    }

    func testFetchPatientAlerts_ValidUUID_DoesNotThrowInvalidUUIDError() async {
        let service = await CoachingAlertService.shared
        let validUUID = UUID().uuidString

        do {
            _ = try await service.fetchPatientAlerts(patientId: validUUID, includeResolved: true)
        } catch let error as CoachingAlertError {
            if case .invalidUUID = error {
                XCTFail("Should not throw invalidUUID for valid UUID string")
            }
        } catch {
            // Other errors are acceptable
        }
    }
}

// MARK: - Codable Decoding Tests

final class CoachingAlertDecodingTests: XCTestCase {

    func testCoachingAlert_Decoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "therapist_id": "770e8400-e29b-41d4-a716-446655440002",
            "alert_type": "pain_increase",
            "severity": "high",
            "title": "Pain Level Alert",
            "message": "Patient pain increased significantly",
            "created_at": "2024-01-15T10:30:00Z",
            "acknowledged_at": null,
            "resolved_at": null,
            "metadata": {"previous": "3", "current": "7"}
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let alert = try decoder.decode(CoachingAlert.self, from: json)

        XCTAssertEqual(alert.alertType, .painIncrease)
        XCTAssertEqual(alert.severity, .high)
        XCTAssertEqual(alert.title, "Pain Level Alert")
        XCTAssertEqual(alert.message, "Patient pain increased significantly")
        XCTAssertNil(alert.acknowledgedAt)
        XCTAssertNil(alert.resolvedAt)
        XCTAssertEqual(alert.metadata?["previous"], "3")
        XCTAssertEqual(alert.metadata?["current"], "7")
        XCTAssertTrue(alert.isActive)
        XCTAssertFalse(alert.isAcknowledged)
    }

    func testCoachingAlert_DecodingWithDates() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "therapist_id": "770e8400-e29b-41d4-a716-446655440002",
            "alert_type": "missed_sessions",
            "severity": "medium",
            "title": "Missed Sessions",
            "message": "Patient missed 3 sessions",
            "created_at": "2024-01-15T10:30:00Z",
            "acknowledged_at": "2024-01-15T11:00:00Z",
            "resolved_at": "2024-01-16T09:00:00Z",
            "metadata": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let alert = try decoder.decode(CoachingAlert.self, from: json)

        XCTAssertNotNil(alert.acknowledgedAt)
        XCTAssertNotNil(alert.resolvedAt)
        XCTAssertNil(alert.metadata)
        XCTAssertFalse(alert.isActive)
        XCTAssertTrue(alert.isAcknowledged)
    }

    func testCoachingAlert_AllAlertTypes() throws {
        let alertTypes = [
            "adherence_dropoff", "pain_increase", "missed_sessions",
            "workload_spike", "recovery_issue", "program_completion",
            "milestone_reached", "rts_readiness", "assessment_due", "custom"
        ]

        for alertType in alertTypes {
            let json = """
            {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "patient_id": "660e8400-e29b-41d4-a716-446655440001",
                "therapist_id": "770e8400-e29b-41d4-a716-446655440002",
                "alert_type": "\(alertType)",
                "severity": "low",
                "title": "Test",
                "message": "Test message",
                "created_at": "2024-01-15T10:30:00Z",
                "acknowledged_at": null,
                "resolved_at": null,
                "metadata": null
            }
            """.data(using: .utf8)!

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let alert = try decoder.decode(CoachingAlert.self, from: json)

            XCTAssertEqual(alert.alertType.rawValue, alertType)
        }
    }

    func testCoachingAlert_AllSeverities() throws {
        let severities = ["low", "medium", "high", "critical"]

        for severity in severities {
            let json = """
            {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "patient_id": "660e8400-e29b-41d4-a716-446655440001",
                "therapist_id": "770e8400-e29b-41d4-a716-446655440002",
                "alert_type": "custom",
                "severity": "\(severity)",
                "title": "Test",
                "message": "Test message",
                "created_at": "2024-01-15T10:30:00Z",
                "acknowledged_at": null,
                "resolved_at": null,
                "metadata": null
            }
            """.data(using: .utf8)!

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let alert = try decoder.decode(CoachingAlert.self, from: json)

            XCTAssertEqual(alert.severity.rawValue, severity)
        }
    }

    func testServicePatientException_Decoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "first_name": "John",
            "last_name": "Doe",
            "alert_count": 5,
            "critical_count": 2,
            "high_count": 3,
            "oldest_alert_date": "2024-01-10T10:30:00Z",
            "latest_alert_date": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exception = try decoder.decode(ServicePatientException.self, from: json)

        XCTAssertEqual(exception.firstName, "John")
        XCTAssertEqual(exception.lastName, "Doe")
        XCTAssertEqual(exception.fullName, "John Doe")
        XCTAssertEqual(exception.alertCount, 5)
        XCTAssertEqual(exception.criticalCount, 2)
        XCTAssertEqual(exception.highCount, 3)
        XCTAssertNotNil(exception.oldestAlertDate)
        XCTAssertNotNil(exception.latestAlertDate)
        XCTAssertTrue(exception.hasCriticalAlerts)
    }

    func testServicePatientException_DecodingWithNullDates() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "first_name": "Jane",
            "last_name": "Smith",
            "alert_count": 0,
            "critical_count": 0,
            "high_count": 0,
            "oldest_alert_date": null,
            "latest_alert_date": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exception = try decoder.decode(ServicePatientException.self, from: json)

        XCTAssertNil(exception.oldestAlertDate)
        XCTAssertNil(exception.latestAlertDate)
        XCTAssertFalse(exception.hasCriticalAlerts)
    }

    func testServiceExceptionSummary_Decoding() throws {
        let json = """
        {
            "total_active_alerts": 15,
            "critical_count": 3,
            "high_count": 5,
            "medium_count": 4,
            "low_count": 3,
            "patients_needing_attention": 8,
            "oldest_unresolved_date": "2024-01-01T10:30:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let summary = try decoder.decode(ServiceExceptionSummary.self, from: json)

        XCTAssertEqual(summary.totalActiveAlerts, 15)
        XCTAssertEqual(summary.criticalCount, 3)
        XCTAssertEqual(summary.highCount, 5)
        XCTAssertEqual(summary.mediumCount, 4)
        XCTAssertEqual(summary.lowCount, 3)
        XCTAssertEqual(summary.patientsNeedingAttention, 8)
        XCTAssertNotNil(summary.oldestUnresolvedDate)
        XCTAssertTrue(summary.hasAlerts)
        XCTAssertTrue(summary.hasUrgentAlerts)
    }

    func testServiceSafetyRule_Decoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "name": "Pain Threshold Alert",
            "description": "Alerts when pain exceeds threshold",
            "rule_type": "pain_increase",
            "priority": "high",
            "threshold": 7.0,
            "comparison_operator": ">=",
            "time_window_days": 7,
            "is_active": true,
            "is_system_rule": true,
            "created_by": "660e8400-e29b-41d4-a716-446655440001",
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let rule = try decoder.decode(ServiceSafetyRule.self, from: json)

        XCTAssertEqual(rule.name, "Pain Threshold Alert")
        XCTAssertEqual(rule.description, "Alerts when pain exceeds threshold")
        XCTAssertEqual(rule.ruleType, "pain_increase")
        XCTAssertEqual(rule.priority, "high")
        XCTAssertEqual(rule.threshold, 7.0)
        XCTAssertEqual(rule.comparisonOperator, ">=")
        XCTAssertEqual(rule.timeWindowDays, 7)
        XCTAssertTrue(rule.isActive)
        XCTAssertTrue(rule.isSystemRule)
        XCTAssertNotNil(rule.createdBy)
    }

    func testServiceSafetyRule_DecodingWithNulls() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "name": "Simple Rule",
            "description": null,
            "rule_type": "custom",
            "priority": "low",
            "threshold": 5.0,
            "comparison_operator": ">",
            "time_window_days": null,
            "is_active": true,
            "is_system_rule": false,
            "created_by": null,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let rule = try decoder.decode(ServiceSafetyRule.self, from: json)

        XCTAssertNil(rule.description)
        XCTAssertNil(rule.timeWindowDays)
        XCTAssertNil(rule.createdBy)
        XCTAssertFalse(rule.isSystemRule)
    }

    func testServiceCoachingPreferences_Decoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "therapist_id": "660e8400-e29b-41d4-a716-446655440001",
            "email_notifications": true,
            "push_notifications": true,
            "critical_alert_sound": true,
            "daily_digest_enabled": true,
            "daily_digest_time": "08:00",
            "alert_priorities_enabled": ["critical", "high", "medium"],
            "alert_types_enabled": ["pain_increase", "missed_sessions"],
            "auto_acknowledge_hours": 24,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let prefs = try decoder.decode(ServiceCoachingPreferences.self, from: json)

        XCTAssertTrue(prefs.emailNotifications)
        XCTAssertTrue(prefs.pushNotifications)
        XCTAssertTrue(prefs.criticalAlertSound)
        XCTAssertTrue(prefs.dailyDigestEnabled)
        XCTAssertEqual(prefs.dailyDigestTime, "08:00")
        XCTAssertEqual(prefs.alertPrioritiesEnabled, ["critical", "high", "medium"])
        XCTAssertEqual(prefs.alertTypesEnabled, ["pain_increase", "missed_sessions"])
        XCTAssertEqual(prefs.autoAcknowledgeHours, 24)
    }

    func testServiceCoachingPreferences_DecodingWithNulls() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "therapist_id": "660e8400-e29b-41d4-a716-446655440001",
            "email_notifications": false,
            "push_notifications": false,
            "critical_alert_sound": false,
            "daily_digest_enabled": false,
            "daily_digest_time": null,
            "alert_priorities_enabled": [],
            "alert_types_enabled": [],
            "auto_acknowledge_hours": null,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let prefs = try decoder.decode(ServiceCoachingPreferences.self, from: json)

        XCTAssertFalse(prefs.emailNotifications)
        XCTAssertFalse(prefs.pushNotifications)
        XCTAssertFalse(prefs.criticalAlertSound)
        XCTAssertFalse(prefs.dailyDigestEnabled)
        XCTAssertNil(prefs.dailyDigestTime)
        XCTAssertTrue(prefs.alertPrioritiesEnabled.isEmpty)
        XCTAssertTrue(prefs.alertTypesEnabled.isEmpty)
        XCTAssertNil(prefs.autoAcknowledgeHours)
    }
}

// MARK: - Edge Cases Tests

final class CoachingAlertEdgeCaseTests: XCTestCase {

    func testCoachingAlert_CriticalSeverityCheck() {
        for severity in CoachingAlert.AlertSeverity.allCases {
            let alert = CoachingAlert(
                id: UUID(),
                patientId: UUID(),
                therapistId: UUID(),
                alertType: .custom,
                severity: severity,
                title: "Test",
                message: "Test",
                createdAt: Date(),
                acknowledgedAt: nil,
                resolvedAt: nil,
                metadata: nil
            )

            if severity == .critical {
                XCTAssertTrue(alert.isCritical)
            } else {
                XCTAssertFalse(alert.isCritical)
            }
        }
    }

    func testCoachingAlert_ActiveAndAcknowledgedCombinations() {
        // Active, not acknowledged
        let alert1 = CoachingAlert(
            id: UUID(),
            patientId: UUID(),
            therapistId: UUID(),
            alertType: .painIncrease,
            severity: .high,
            title: "Test",
            message: "Test",
            createdAt: Date(),
            acknowledgedAt: nil,
            resolvedAt: nil,
            metadata: nil
        )
        XCTAssertTrue(alert1.isActive)
        XCTAssertFalse(alert1.isAcknowledged)

        // Active, acknowledged
        let alert2 = CoachingAlert(
            id: UUID(),
            patientId: UUID(),
            therapistId: UUID(),
            alertType: .painIncrease,
            severity: .high,
            title: "Test",
            message: "Test",
            createdAt: Date(),
            acknowledgedAt: Date(),
            resolvedAt: nil,
            metadata: nil
        )
        XCTAssertTrue(alert2.isActive)
        XCTAssertTrue(alert2.isAcknowledged)

        // Resolved, not acknowledged
        let alert3 = CoachingAlert(
            id: UUID(),
            patientId: UUID(),
            therapistId: UUID(),
            alertType: .painIncrease,
            severity: .high,
            title: "Test",
            message: "Test",
            createdAt: Date(),
            acknowledgedAt: nil,
            resolvedAt: Date(),
            metadata: nil
        )
        XCTAssertFalse(alert3.isActive)
        XCTAssertFalse(alert3.isAcknowledged)

        // Resolved and acknowledged
        let alert4 = CoachingAlert(
            id: UUID(),
            patientId: UUID(),
            therapistId: UUID(),
            alertType: .painIncrease,
            severity: .high,
            title: "Test",
            message: "Test",
            createdAt: Date(),
            acknowledgedAt: Date(),
            resolvedAt: Date(),
            metadata: nil
        )
        XCTAssertFalse(alert4.isActive)
        XCTAssertTrue(alert4.isAcknowledged)
    }

    func testServiceExceptionSummary_CountConsistency() {
        // Sum of individual counts should equal total (typical case)
        let summary = ServiceExceptionSummary(
            totalActiveAlerts: 10,
            criticalCount: 2,
            highCount: 3,
            mediumCount: 3,
            lowCount: 2,
            patientsNeedingAttention: 5,
            oldestUnresolvedDate: nil
        )

        let sumOfCounts = summary.criticalCount + summary.highCount + summary.mediumCount + summary.lowCount
        XCTAssertEqual(summary.totalActiveAlerts, sumOfCounts)
    }

    func testAlertSeverity_AllCasesHaveColors() {
        for severity in CoachingAlert.AlertSeverity.allCases {
            // Just verify color exists and is not nil
            _ = severity.color
        }
    }

    func testAlertType_AllCasesHaveColors() {
        for alertType in CoachingAlert.AlertType.allCases {
            // Just verify color exists and is not nil
            _ = alertType.color
        }
    }

    func testCoachingAlert_EmptyMetadata() {
        let alert = CoachingAlert(
            id: UUID(),
            patientId: UUID(),
            therapistId: UUID(),
            alertType: .custom,
            severity: .low,
            title: "Test",
            message: "Test",
            createdAt: Date(),
            acknowledgedAt: nil,
            resolvedAt: nil,
            metadata: [:]
        )

        XCTAssertNotNil(alert.metadata)
        XCTAssertTrue(alert.metadata?.isEmpty ?? false)
    }

    func testCoachingAlert_LargeMetadata() {
        var metadata: [String: String] = [:]
        for i in 0..<100 {
            metadata["key\(i)"] = "value\(i)"
        }

        let alert = CoachingAlert(
            id: UUID(),
            patientId: UUID(),
            therapistId: UUID(),
            alertType: .custom,
            severity: .low,
            title: "Test",
            message: "Test",
            createdAt: Date(),
            acknowledgedAt: nil,
            resolvedAt: nil,
            metadata: metadata
        )

        XCTAssertEqual(alert.metadata?.count, 100)
    }

    func testServicePatientException_ZeroCounts() {
        let exception = ServicePatientException(
            id: UUID(),
            patientId: UUID(),
            firstName: "No",
            lastName: "Alerts",
            alertCount: 0,
            criticalCount: 0,
            highCount: 0,
            oldestAlertDate: nil,
            latestAlertDate: nil
        )

        XCTAssertEqual(exception.alertCount, 0)
        XCTAssertFalse(exception.hasCriticalAlerts)
    }

    func testServiceSafetyRule_ComparisonOperators() {
        let operators = [">=", ">", "<=", "<", "==", "!="]

        for op in operators {
            let rule = ServiceSafetyRule(
                id: UUID(),
                name: "Test \(op)",
                description: nil,
                ruleType: "test",
                priority: "low",
                threshold: 5.0,
                comparisonOperator: op,
                timeWindowDays: nil,
                isActive: true,
                isSystemRule: false,
                createdBy: nil,
                createdAt: Date(),
                updatedAt: Date()
            )

            XCTAssertEqual(rule.comparisonOperator, op)
        }
    }
}
