//
//  RTSModelTests.swift
//  PTPerformanceTests
//
//  Comprehensive unit tests for Return-to-Sport (RTS) models
//  Tests encoding/decoding, computed properties, and business logic
//

import XCTest
import SwiftUI
@testable import PTPerformance

// MARK: - Test Fixture Data

/// Test fixture data for RTS protocol testing
enum RTSTestFixtures {

    // MARK: - Sports Fixtures

    static let baseballSport = RTSSport(
        id: UUID(uuidString: "00000000-0000-0000-0001-000000000001")!,
        name: "Baseball",
        category: .throwing,
        defaultPhases: [
            RTSPhaseTemplate(
                phaseNumber: 1,
                phaseName: "Protected Motion",
                activityLevel: .red,
                description: "Pain-free ROM, no throwing",
                targetDurationWeeks: 2
            ),
            RTSPhaseTemplate(
                phaseNumber: 2,
                phaseName: "Light Tossing",
                activityLevel: .yellow,
                description: "Light catch at short distance",
                targetDurationWeeks: 2
            ),
            RTSPhaseTemplate(
                phaseNumber: 3,
                phaseName: "Long Toss",
                activityLevel: .yellow,
                description: "Progressive distance throwing",
                targetDurationWeeks: 3
            ),
            RTSPhaseTemplate(
                phaseNumber: 4,
                phaseName: "Return to Mound",
                activityLevel: .green,
                description: "Full velocity throwing, game simulation",
                targetDurationWeeks: 2
            )
        ]
    )

    static let runningSport = RTSSport(
        id: UUID(uuidString: "00000000-0000-0000-0001-000000000002")!,
        name: "Running",
        category: .running,
        defaultPhases: [
            RTSPhaseTemplate(
                phaseNumber: 1,
                phaseName: "Walk/Light Activity",
                activityLevel: .red,
                description: "Walking only, no running",
                targetDurationWeeks: 2
            ),
            RTSPhaseTemplate(
                phaseNumber: 2,
                phaseName: "Run/Walk Intervals",
                activityLevel: .yellow,
                description: "Alternating run and walk periods",
                targetDurationWeeks: 2
            ),
            RTSPhaseTemplate(
                phaseNumber: 3,
                phaseName: "Continuous Running",
                activityLevel: .yellow,
                description: "Progressive distance and pace",
                targetDurationWeeks: 3
            ),
            RTSPhaseTemplate(
                phaseNumber: 4,
                phaseName: "Full Training",
                activityLevel: .green,
                description: "Full training load and competition",
                targetDurationWeeks: 2
            )
        ]
    )

    static let soccerSport = RTSSport(
        id: UUID(uuidString: "00000000-0000-0000-0001-000000000003")!,
        name: "Soccer",
        category: .cutting,
        defaultPhases: [
            RTSPhaseTemplate(
                phaseNumber: 1,
                phaseName: "Linear Movement",
                activityLevel: .red,
                description: "Walking and light jogging only",
                targetDurationWeeks: 2
            ),
            RTSPhaseTemplate(
                phaseNumber: 2,
                phaseName: "Lateral Movement",
                activityLevel: .yellow,
                description: "Side shuffles, carioca drills",
                targetDurationWeeks: 2
            ),
            RTSPhaseTemplate(
                phaseNumber: 3,
                phaseName: "Sport-Specific Drills",
                activityLevel: .yellow,
                description: "Ball work, cutting at 50% intensity",
                targetDurationWeeks: 3
            ),
            RTSPhaseTemplate(
                phaseNumber: 4,
                phaseName: "Return to Play",
                activityLevel: .green,
                description: "Full practice, then game clearance",
                targetDurationWeeks: 2
            )
        ]
    )

    static let basketballSport = RTSSport(
        id: UUID(uuidString: "00000000-0000-0000-0001-000000000004")!,
        name: "Basketball",
        category: .cutting,
        defaultPhases: [
            RTSPhaseTemplate(
                phaseNumber: 1,
                phaseName: "Linear Court Movement",
                activityLevel: .red,
                description: "Walking, jogging in straight lines",
                targetDurationWeeks: 2
            ),
            RTSPhaseTemplate(
                phaseNumber: 2,
                phaseName: "Change of Direction",
                activityLevel: .yellow,
                description: "Controlled cutting and pivoting",
                targetDurationWeeks: 2
            ),
            RTSPhaseTemplate(
                phaseNumber: 3,
                phaseName: "Basketball Drills",
                activityLevel: .yellow,
                description: "Shooting, passing, non-contact drills",
                targetDurationWeeks: 2
            ),
            RTSPhaseTemplate(
                phaseNumber: 4,
                phaseName: "5-on-5 Practice",
                activityLevel: .yellow,
                description: "Full practice with contact",
                targetDurationWeeks: 2
            ),
            RTSPhaseTemplate(
                phaseNumber: 5,
                phaseName: "Game Clearance",
                activityLevel: .green,
                description: "Full game participation",
                targetDurationWeeks: 1
            )
        ]
    )

    // MARK: - Protocol Fixtures

    static let patientId = UUID(uuidString: "00000000-0000-0000-0002-000000000001")!
    static let therapistId = UUID(uuidString: "00000000-0000-0000-0002-000000000002")!

    static func createProtocol(
        id: UUID = UUID(),
        status: RTSProtocolStatus = .active,
        sport: RTSSport = baseballSport,
        injuryDate: Date = Calendar.current.date(byAdding: .month, value: -3, to: Date())!,
        targetReturnDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date())!
    ) -> RTSProtocol {
        RTSProtocol(
            id: id,
            patientId: patientId,
            therapistId: therapistId,
            sportId: sport.id,
            injuryType: "ACL Reconstruction",
            surgeryDate: Calendar.current.date(byAdding: .day, value: 7, to: injuryDate),
            injuryDate: injuryDate,
            targetReturnDate: targetReturnDate,
            status: status,
            notes: "Post-operative rehabilitation protocol"
        )
    }

    // MARK: - Phase Fixtures

    static func createPhase(
        protocolId: UUID,
        phaseNumber: Int = 1,
        activityLevel: RTSTrafficLight = .yellow,
        startedAt: Date? = nil,
        completedAt: Date? = nil
    ) -> RTSPhase {
        RTSPhase(
            protocolId: protocolId,
            phaseNumber: phaseNumber,
            phaseName: "Phase \(phaseNumber)",
            activityLevel: activityLevel,
            description: "Test phase \(phaseNumber) description",
            entryCriteria: ["Criterion 1", "Criterion 2"],
            exitCriteria: ["Exit 1", "Exit 2"],
            startedAt: startedAt,
            completedAt: completedAt,
            targetDurationDays: 14
        )
    }

    // MARK: - Clearance Fixtures

    static func createClearance(
        protocolId: UUID,
        clearanceType: RTSClearanceType = .phaseClearance,
        clearanceLevel: RTSTrafficLight = .yellow,
        status: RTSClearanceStatus = .draft,
        requiresPhysicianSignature: Bool = false,
        signedBy: UUID? = nil,
        signedAt: Date? = nil,
        coSignedBy: UUID? = nil,
        coSignedAt: Date? = nil
    ) -> RTSClearance {
        RTSClearance(
            protocolId: protocolId,
            clearanceType: clearanceType,
            clearanceLevel: clearanceLevel,
            status: status,
            assessmentSummary: "Assessment summary for testing",
            recommendations: "Test recommendations",
            restrictions: clearanceLevel != .green ? "Some restrictions apply" : nil,
            requiresPhysicianSignature: requiresPhysicianSignature,
            signedBy: signedBy,
            signedAt: signedAt,
            coSignedBy: coSignedBy,
            coSignedAt: coSignedAt
        )
    }

    // MARK: - Readiness Score Fixtures

    static func createReadinessScore(
        protocolId: UUID,
        phaseId: UUID,
        physical: Double = 80,
        functional: Double = 80,
        psychological: Double = 80,
        riskFactors: [RTSRiskFactor] = []
    ) -> RTSReadinessScore {
        RTSReadinessScore(
            protocolId: protocolId,
            phaseId: phaseId,
            recordedBy: therapistId,
            physicalScore: physical,
            functionalScore: functional,
            psychologicalScore: psychological,
            riskFactors: riskFactors,
            notes: "Test readiness assessment"
        )
    }

    // MARK: - Criterion Fixtures

    static func createCriterion(
        phaseId: UUID,
        category: RTSCriterionCategory = .strength,
        targetValue: Double = 85,
        comparisonOperator: RTSComparisonOperator = .greaterThanOrEqual,
        isRequired: Bool = true,
        latestResult: RTSTestResult? = nil
    ) -> RTSMilestoneCriterion {
        RTSMilestoneCriterion(
            phaseId: phaseId,
            category: category,
            name: "\(category.displayName) Test",
            description: "Test criterion for \(category.displayName)",
            targetValue: targetValue,
            targetUnit: "%",
            comparisonOperator: comparisonOperator,
            isRequired: isRequired,
            sortOrder: 1,
            latestResult: latestResult
        )
    }

    static func createTestResult(
        criterionId: UUID,
        protocolId: UUID,
        value: Double = 87,
        passed: Bool = true
    ) -> RTSTestResult {
        RTSTestResult(
            criterionId: criterionId,
            protocolId: protocolId,
            recordedBy: therapistId,
            value: value,
            unit: "%",
            passed: passed,
            notes: "Test result notes"
        )
    }
}

// MARK: - RTSProtocol Tests

final class RTSProtocolTests: XCTestCase {

    // MARK: - Encoding/Decoding Tests

    func testRTSProtocol_Encoding() throws {
        let protocol_ = RTSTestFixtures.createProtocol()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(protocol_)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Verify snake_case keys
        XCTAssertNotNil(json["patient_id"])
        XCTAssertNotNil(json["therapist_id"])
        XCTAssertNotNil(json["sport_id"])
        XCTAssertNotNil(json["injury_type"])
        XCTAssertNotNil(json["injury_date"])
        XCTAssertNotNil(json["target_return_date"])
        XCTAssertNotNil(json["created_at"])
        XCTAssertNotNil(json["updated_at"])
    }

    func testRTSProtocol_Decoding() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "patient_id": "00000000-0000-0000-0002-000000000001",
            "therapist_id": "00000000-0000-0000-0002-000000000002",
            "sport_id": "00000000-0000-0000-0001-000000000001",
            "injury_type": "ACL Reconstruction",
            "surgery_date": "2024-01-15T12:00:00Z",
            "injury_date": "2024-01-08T12:00:00Z",
            "target_return_date": "2024-07-15T12:00:00Z",
            "status": "active",
            "notes": "Test protocol",
            "created_at": "2024-01-15T12:00:00Z",
            "updated_at": "2024-01-15T12:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let protocol_ = try decoder.decode(RTSProtocol.self, from: json)

        XCTAssertEqual(protocol_.injuryType, "ACL Reconstruction")
        XCTAssertEqual(protocol_.status, .active)
        XCTAssertNotNil(protocol_.surgeryDate)
    }

    func testRTSProtocol_RoundTrip() throws {
        let original = RTSTestFixtures.createProtocol()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(RTSProtocol.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.patientId, decoded.patientId)
        XCTAssertEqual(original.therapistId, decoded.therapistId)
        XCTAssertEqual(original.sportId, decoded.sportId)
        XCTAssertEqual(original.injuryType, decoded.injuryType)
        XCTAssertEqual(original.status, decoded.status)
    }

    // MARK: - Computed Properties Tests

    func testDaysUntilTarget_FutureDate() {
        let targetDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        let protocol_ = RTSTestFixtures.createProtocol(targetReturnDate: targetDate)

        XCTAssertEqual(protocol_.daysUntilTarget, 30, accuracy: 1)
    }

    func testDaysUntilTarget_PastDate() {
        let targetDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let protocol_ = RTSTestFixtures.createProtocol(targetReturnDate: targetDate)

        XCTAssertEqual(protocol_.daysUntilTarget, -10, accuracy: 1)
    }

    func testProgressPercentage_AtStart() {
        let injuryDate = Date()
        let targetDate = Calendar.current.date(byAdding: .day, value: 100, to: Date())!
        let protocol_ = RTSTestFixtures.createProtocol(injuryDate: injuryDate, targetReturnDate: targetDate)

        XCTAssertEqual(protocol_.progressPercentage, 0, accuracy: 0.05)
    }

    func testProgressPercentage_Midway() {
        let injuryDate = Calendar.current.date(byAdding: .day, value: -50, to: Date())!
        let targetDate = Calendar.current.date(byAdding: .day, value: 50, to: Date())!
        let protocol_ = RTSTestFixtures.createProtocol(injuryDate: injuryDate, targetReturnDate: targetDate)

        XCTAssertEqual(protocol_.progressPercentage, 0.5, accuracy: 0.05)
    }

    func testProgressPercentage_CapsAtOne() {
        let injuryDate = Calendar.current.date(byAdding: .day, value: -200, to: Date())!
        let targetDate = Calendar.current.date(byAdding: .day, value: -100, to: Date())!
        let protocol_ = RTSTestFixtures.createProtocol(injuryDate: injuryDate, targetReturnDate: targetDate)

        XCTAssertEqual(protocol_.progressPercentage, 1.0, accuracy: 0.01)
    }

    func testDaysSinceInjury() {
        let injuryDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let protocol_ = RTSTestFixtures.createProtocol(injuryDate: injuryDate)

        XCTAssertEqual(protocol_.daysSinceInjury, 30, accuracy: 1)
    }

    func testIsActive_WhenStatusActive() {
        let protocol_ = RTSTestFixtures.createProtocol(status: .active)
        XCTAssertTrue(protocol_.isActive)
    }

    func testIsActive_WhenStatusDraft() {
        let protocol_ = RTSTestFixtures.createProtocol(status: .draft)
        XCTAssertFalse(protocol_.isActive)
    }

    func testIsCompleted_WhenStatusCompleted() {
        let protocol_ = RTSTestFixtures.createProtocol(status: .completed)
        XCTAssertTrue(protocol_.isCompleted)
    }

    func testIsCompleted_WhenStatusActive() {
        let protocol_ = RTSTestFixtures.createProtocol(status: .active)
        XCTAssertFalse(protocol_.isCompleted)
    }
}

// MARK: - RTSProtocolStatus Tests

final class RTSModelProtocolStatusTests: XCTestCase {

    func testRawValues() {
        XCTAssertEqual(RTSProtocolStatus.draft.rawValue, "draft")
        XCTAssertEqual(RTSProtocolStatus.active.rawValue, "active")
        XCTAssertEqual(RTSProtocolStatus.completed.rawValue, "completed")
        XCTAssertEqual(RTSProtocolStatus.discontinued.rawValue, "discontinued")
    }

    func testDisplayNames() {
        XCTAssertEqual(RTSProtocolStatus.draft.displayName, "Draft")
        XCTAssertEqual(RTSProtocolStatus.active.displayName, "Active")
        XCTAssertEqual(RTSProtocolStatus.completed.displayName, "Completed")
        XCTAssertEqual(RTSProtocolStatus.discontinued.displayName, "Discontinued")
    }

    func testIsEditable_DraftAndActive() {
        XCTAssertTrue(RTSProtocolStatus.draft.isEditable)
        XCTAssertTrue(RTSProtocolStatus.active.isEditable)
    }

    func testIsEditable_CompletedAndDiscontinued() {
        XCTAssertFalse(RTSProtocolStatus.completed.isEditable)
        XCTAssertFalse(RTSProtocolStatus.discontinued.isEditable)
    }

    func testAllCases() {
        let allCases = RTSProtocolStatus.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.draft))
        XCTAssertTrue(allCases.contains(.active))
        XCTAssertTrue(allCases.contains(.completed))
        XCTAssertTrue(allCases.contains(.discontinued))
    }
}

// MARK: - RTSPhase Tests

final class RTSPhaseTests: XCTestCase {

    let protocolId = UUID()

    // MARK: - Encoding/Decoding Tests

    func testRTSPhase_Encoding() throws {
        let phase = RTSTestFixtures.createPhase(protocolId: protocolId, startedAt: Date())

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(phase)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertNotNil(json["protocol_id"])
        XCTAssertNotNil(json["phase_number"])
        XCTAssertNotNil(json["phase_name"])
        XCTAssertNotNil(json["activity_level"])
        XCTAssertNotNil(json["entry_criteria"])
        XCTAssertNotNil(json["exit_criteria"])
        XCTAssertNotNil(json["target_duration_days"])
    }

    func testRTSPhase_Decoding() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "protocol_id": "00000000-0000-0000-0000-000000000002",
            "phase_number": 2,
            "phase_name": "Light Tossing",
            "activity_level": "yellow",
            "description": "Light catch at short distance",
            "entry_criteria": ["Pain-free ROM", "Medical clearance"],
            "exit_criteria": ["10 sessions completed", "LSI >= 80%"],
            "started_at": "2024-02-01T12:00:00Z",
            "target_duration_days": 14,
            "created_at": "2024-01-15T12:00:00Z",
            "updated_at": "2024-02-01T12:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let phase = try decoder.decode(RTSPhase.self, from: json)

        XCTAssertEqual(phase.phaseNumber, 2)
        XCTAssertEqual(phase.phaseName, "Light Tossing")
        XCTAssertEqual(phase.activityLevel, .yellow)
        XCTAssertEqual(phase.entryCriteria.count, 2)
        XCTAssertEqual(phase.exitCriteria.count, 2)
        XCTAssertEqual(phase.targetDurationDays, 14)
    }

    // MARK: - Status Tests

    func testIsActive_StartedNotCompleted() {
        let phase = RTSTestFixtures.createPhase(
            protocolId: protocolId,
            startedAt: Date(),
            completedAt: nil
        )

        XCTAssertTrue(phase.isActive)
        XCTAssertFalse(phase.isCompleted)
        XCTAssertFalse(phase.isPending)
    }

    func testIsCompleted_HasCompletedAt() {
        let phase = RTSTestFixtures.createPhase(
            protocolId: protocolId,
            startedAt: Calendar.current.date(byAdding: .day, value: -14, to: Date()),
            completedAt: Date()
        )

        XCTAssertFalse(phase.isActive)
        XCTAssertTrue(phase.isCompleted)
        XCTAssertFalse(phase.isPending)
    }

    func testIsPending_NotStarted() {
        let phase = RTSTestFixtures.createPhase(
            protocolId: protocolId,
            startedAt: nil,
            completedAt: nil
        )

        XCTAssertFalse(phase.isActive)
        XCTAssertFalse(phase.isCompleted)
        XCTAssertTrue(phase.isPending)
    }

    func testDaysInPhase_Active() {
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let phase = RTSTestFixtures.createPhase(
            protocolId: protocolId,
            startedAt: startDate,
            completedAt: nil
        )

        XCTAssertEqual(phase.daysInPhase ?? 0, 7, accuracy: 1)
    }

    func testDaysInPhase_Completed() {
        let startDate = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        let endDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let phase = RTSTestFixtures.createPhase(
            protocolId: protocolId,
            startedAt: startDate,
            completedAt: endDate
        )

        XCTAssertEqual(phase.daysInPhase ?? 0, 7, accuracy: 1)
    }

    func testDaysInPhase_NotStarted() {
        let phase = RTSTestFixtures.createPhase(protocolId: protocolId)
        XCTAssertNil(phase.daysInPhase)
    }

    func testProgressPercentage_Active() {
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let phase = RTSTestFixtures.createPhase(
            protocolId: protocolId,
            startedAt: startDate,
            completedAt: nil
        )

        // 7 days into 14 day target = 50%
        XCTAssertEqual(phase.progressPercentage ?? 0, 0.5, accuracy: 0.1)
    }

    func testStatusText_Variations() {
        let pending = RTSTestFixtures.createPhase(protocolId: protocolId)
        XCTAssertEqual(pending.statusText, "Pending")

        let completed = RTSTestFixtures.createPhase(
            protocolId: protocolId,
            startedAt: Date(),
            completedAt: Date()
        )
        XCTAssertEqual(completed.statusText, "Completed")

        let active = RTSTestFixtures.createPhase(
            protocolId: protocolId,
            startedAt: Date(),
            completedAt: nil
        )
        XCTAssertTrue(active.statusText.contains("Day") || active.statusText == "Active")
    }

    func testTargetDurationWeeks() {
        let phase = RTSTestFixtures.createPhase(protocolId: protocolId)
        XCTAssertEqual(phase.targetDurationWeeks, 2) // 14 days / 7 = 2 weeks
    }
}

// MARK: - RTSTrafficLight Tests

final class RTSModelTrafficLightTests: XCTestCase {

    // MARK: - from(score:) Tests

    func testFromScore_RedZone_0() {
        XCTAssertEqual(RTSTrafficLight.from(score: 0), .red)
    }

    func testFromScore_RedZone_30() {
        XCTAssertEqual(RTSTrafficLight.from(score: 30), .red)
    }

    func testFromScore_RedZone_59() {
        XCTAssertEqual(RTSTrafficLight.from(score: 59), .red)
    }

    func testFromScore_RedZone_59_99() {
        XCTAssertEqual(RTSTrafficLight.from(score: 59.99), .red)
    }

    func testFromScore_YellowZone_60() {
        XCTAssertEqual(RTSTrafficLight.from(score: 60), .yellow)
    }

    func testFromScore_YellowZone_70() {
        XCTAssertEqual(RTSTrafficLight.from(score: 70), .yellow)
    }

    func testFromScore_YellowZone_79() {
        XCTAssertEqual(RTSTrafficLight.from(score: 79), .yellow)
    }

    func testFromScore_YellowZone_79_99() {
        XCTAssertEqual(RTSTrafficLight.from(score: 79.99), .yellow)
    }

    func testFromScore_GreenZone_80() {
        XCTAssertEqual(RTSTrafficLight.from(score: 80), .green)
    }

    func testFromScore_GreenZone_90() {
        XCTAssertEqual(RTSTrafficLight.from(score: 90), .green)
    }

    func testFromScore_GreenZone_100() {
        XCTAssertEqual(RTSTrafficLight.from(score: 100), .green)
    }

    func testFromScore_NegativeScore() {
        XCTAssertEqual(RTSTrafficLight.from(score: -10), .red)
    }

    func testFromScore_ScoreAbove100() {
        XCTAssertEqual(RTSTrafficLight.from(score: 150), .green)
    }

    // MARK: - Boundary Tests

    func testBoundary_59To60() {
        XCTAssertEqual(RTSTrafficLight.from(score: 59), .red)
        XCTAssertEqual(RTSTrafficLight.from(score: 60), .yellow)
    }

    func testBoundary_79To80() {
        XCTAssertEqual(RTSTrafficLight.from(score: 79), .yellow)
        XCTAssertEqual(RTSTrafficLight.from(score: 80), .green)
    }

    // MARK: - contains(score:) Tests

    func testContainsScore_Green() {
        XCTAssertTrue(RTSTrafficLight.green.contains(score: 80))
        XCTAssertTrue(RTSTrafficLight.green.contains(score: 90))
        XCTAssertTrue(RTSTrafficLight.green.contains(score: 100))
        XCTAssertFalse(RTSTrafficLight.green.contains(score: 79))
        XCTAssertFalse(RTSTrafficLight.green.contains(score: 101))
    }

    func testContainsScore_Yellow() {
        XCTAssertTrue(RTSTrafficLight.yellow.contains(score: 60))
        XCTAssertTrue(RTSTrafficLight.yellow.contains(score: 70))
        XCTAssertTrue(RTSTrafficLight.yellow.contains(score: 79))
        XCTAssertFalse(RTSTrafficLight.yellow.contains(score: 59))
        XCTAssertFalse(RTSTrafficLight.yellow.contains(score: 80))
    }

    func testContainsScore_Red() {
        XCTAssertTrue(RTSTrafficLight.red.contains(score: 0))
        XCTAssertTrue(RTSTrafficLight.red.contains(score: 30))
        XCTAssertTrue(RTSTrafficLight.red.contains(score: 59))
        XCTAssertFalse(RTSTrafficLight.red.contains(score: 60))
        XCTAssertFalse(RTSTrafficLight.red.contains(score: -1))
    }

    // MARK: - Property Tests

    func testMinimumScore() {
        XCTAssertEqual(RTSTrafficLight.green.minimumScore, 80)
        XCTAssertEqual(RTSTrafficLight.yellow.minimumScore, 60)
        XCTAssertEqual(RTSTrafficLight.red.minimumScore, 0)
    }

    func testMaximumScore() {
        XCTAssertEqual(RTSTrafficLight.green.maximumScore, 100)
        XCTAssertEqual(RTSTrafficLight.yellow.maximumScore, 79.99)
        XCTAssertEqual(RTSTrafficLight.red.maximumScore, 59.99)
    }

    func testDisplayNames() {
        XCTAssertEqual(RTSTrafficLight.green.displayName, "Cleared")
        XCTAssertEqual(RTSTrafficLight.yellow.displayName, "Caution")
        XCTAssertEqual(RTSTrafficLight.red.displayName, "Restricted")
    }

    func testRawValues() {
        XCTAssertEqual(RTSTrafficLight.green.rawValue, "green")
        XCTAssertEqual(RTSTrafficLight.yellow.rawValue, "yellow")
        XCTAssertEqual(RTSTrafficLight.red.rawValue, "red")
    }

    func testAllCases() {
        let allCases = RTSTrafficLight.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.green))
        XCTAssertTrue(allCases.contains(.yellow))
        XCTAssertTrue(allCases.contains(.red))
    }
}

// MARK: - RTSMilestoneCriterion Tests

final class RTSModelMilestoneCriterionTests: XCTestCase {

    let phaseId = UUID()
    let protocolId = UUID()

    // MARK: - Encoding/Decoding Tests

    func testRTSMilestoneCriterion_Encoding() throws {
        let criterion = RTSTestFixtures.createCriterion(phaseId: phaseId)

        let encoder = JSONEncoder()
        let data = try encoder.encode(criterion)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertNotNil(json["phase_id"])
        XCTAssertNotNil(json["target_value"])
        XCTAssertNotNil(json["target_unit"])
        XCTAssertNotNil(json["comparison_operator"])
        XCTAssertNotNil(json["is_required"])
        XCTAssertNotNil(json["sort_order"])
    }

    func testRTSMilestoneCriterion_Decoding() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "phase_id": "00000000-0000-0000-0000-000000000002",
            "category": "strength",
            "name": "Quad LSI",
            "description": "Limb Symmetry Index for quadriceps",
            "target_value": 85.0,
            "target_unit": "%",
            "comparison_operator": ">=",
            "is_required": true,
            "sort_order": 1,
            "created_at": "2024-01-15T12:00:00Z",
            "updated_at": "2024-01-15T12:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let criterion = try decoder.decode(RTSMilestoneCriterion.self, from: json)

        XCTAssertEqual(criterion.category, .strength)
        XCTAssertEqual(criterion.name, "Quad LSI")
        XCTAssertEqual(criterion.targetValue, 85.0)
        XCTAssertEqual(criterion.comparisonOperator, .greaterThanOrEqual)
        XCTAssertTrue(criterion.isRequired)
    }

    // MARK: - Status Tests

    func testIsPassed_WithPassingResult() {
        let result = RTSTestFixtures.createTestResult(
            criterionId: UUID(),
            protocolId: protocolId,
            value: 90,
            passed: true
        )
        var criterion = RTSTestFixtures.createCriterion(phaseId: phaseId)
        criterion.latestResult = result

        XCTAssertTrue(criterion.isPassed)
        XCTAssertTrue(criterion.hasBeenTested)
    }

    func testIsPassed_WithFailingResult() {
        let result = RTSTestFixtures.createTestResult(
            criterionId: UUID(),
            protocolId: protocolId,
            value: 70,
            passed: false
        )
        var criterion = RTSTestFixtures.createCriterion(phaseId: phaseId)
        criterion.latestResult = result

        XCTAssertFalse(criterion.isPassed)
        XCTAssertTrue(criterion.hasBeenTested)
    }

    func testIsPassed_WithNoResult() {
        let criterion = RTSTestFixtures.createCriterion(phaseId: phaseId)

        XCTAssertFalse(criterion.isPassed)
        XCTAssertFalse(criterion.hasBeenTested)
    }

    func testTargetDescription() {
        let criterion = RTSTestFixtures.createCriterion(
            phaseId: phaseId,
            targetValue: 85,
            comparisonOperator: .greaterThanOrEqual
        )

        XCTAssertEqual(criterion.targetDescription, ">= 85 %")
    }

    func testStatusIcon_Passed() {
        let result = RTSTestFixtures.createTestResult(criterionId: UUID(), protocolId: protocolId, passed: true)
        var criterion = RTSTestFixtures.createCriterion(phaseId: phaseId)
        criterion.latestResult = result

        XCTAssertEqual(criterion.statusIcon, "checkmark.circle.fill")
    }

    func testStatusIcon_Failed() {
        let result = RTSTestFixtures.createTestResult(criterionId: UUID(), protocolId: protocolId, passed: false)
        var criterion = RTSTestFixtures.createCriterion(phaseId: phaseId)
        criterion.latestResult = result

        XCTAssertEqual(criterion.statusIcon, "xmark.circle.fill")
    }

    func testStatusIcon_NotTested() {
        let criterion = RTSTestFixtures.createCriterion(phaseId: phaseId)
        XCTAssertEqual(criterion.statusIcon, "circle")
    }
}

// MARK: - RTSTestResult Tests

final class RTSModelTestResultTests: XCTestCase {

    func testRTSTestResult_Encoding() throws {
        let result = RTSTestFixtures.createTestResult(
            criterionId: UUID(),
            protocolId: UUID()
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(result)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertNotNil(json["criterion_id"])
        XCTAssertNotNil(json["protocol_id"])
        XCTAssertNotNil(json["recorded_by"])
        XCTAssertNotNil(json["recorded_at"])
        XCTAssertNotNil(json["created_at"])
    }

    func testFormattedValue_Integer() {
        let result = RTSTestFixtures.createTestResult(
            criterionId: UUID(),
            protocolId: UUID(),
            value: 85.0
        )

        XCTAssertEqual(result.formattedValue, "85 %")
    }

    func testFormattedValue_Decimal() {
        let result = RTSTestResult(
            criterionId: UUID(),
            protocolId: UUID(),
            recordedBy: UUID(),
            value: 85.5,
            unit: "%",
            passed: true
        )

        XCTAssertEqual(result.formattedValue, "85.5 %")
    }
}

// MARK: - RTSComparisonOperator Tests

final class RTSModelComparisonOperatorTests: XCTestCase {

    // MARK: - Evaluate Tests

    func testEvaluate_GreaterThanOrEqual_Pass() {
        let op = RTSComparisonOperator.greaterThanOrEqual

        XCTAssertTrue(op.evaluate(value: 85, target: 85))
        XCTAssertTrue(op.evaluate(value: 90, target: 85))
    }

    func testEvaluate_GreaterThanOrEqual_Fail() {
        let op = RTSComparisonOperator.greaterThanOrEqual

        XCTAssertFalse(op.evaluate(value: 80, target: 85))
    }

    func testEvaluate_LessThanOrEqual_Pass() {
        let op = RTSComparisonOperator.lessThanOrEqual

        XCTAssertTrue(op.evaluate(value: 2, target: 2))
        XCTAssertTrue(op.evaluate(value: 1, target: 2))
    }

    func testEvaluate_LessThanOrEqual_Fail() {
        let op = RTSComparisonOperator.lessThanOrEqual

        XCTAssertFalse(op.evaluate(value: 3, target: 2))
    }

    func testEvaluate_Equal_Pass() {
        let op = RTSComparisonOperator.equal

        XCTAssertTrue(op.evaluate(value: 10, target: 10))
        XCTAssertTrue(op.evaluate(value: 10.0001, target: 10)) // Within tolerance
    }

    func testEvaluate_Equal_Fail() {
        let op = RTSComparisonOperator.equal

        XCTAssertFalse(op.evaluate(value: 10.01, target: 10))
    }

    func testEvaluate_Between_WithUpperBound() {
        let op = RTSComparisonOperator.between

        XCTAssertTrue(op.evaluate(value: 85, target: 80, upperBound: 90))
        XCTAssertTrue(op.evaluate(value: 80, target: 80, upperBound: 90))
        XCTAssertTrue(op.evaluate(value: 90, target: 80, upperBound: 90))
        XCTAssertFalse(op.evaluate(value: 75, target: 80, upperBound: 90))
        XCTAssertFalse(op.evaluate(value: 95, target: 80, upperBound: 90))
    }

    func testEvaluate_Between_WithoutUpperBound() {
        let op = RTSComparisonOperator.between

        // Without upper bound, acts like >=
        XCTAssertTrue(op.evaluate(value: 85, target: 80))
        XCTAssertFalse(op.evaluate(value: 75, target: 80))
    }

    // MARK: - Symbol Tests

    func testSymbols() {
        XCTAssertEqual(RTSComparisonOperator.greaterThanOrEqual.symbol, ">=")
        XCTAssertEqual(RTSComparisonOperator.lessThanOrEqual.symbol, "<=")
        XCTAssertEqual(RTSComparisonOperator.equal.symbol, "=")
        XCTAssertEqual(RTSComparisonOperator.between.symbol, "between")
    }

    // MARK: - Raw Value Tests

    func testRawValues() {
        XCTAssertEqual(RTSComparisonOperator.greaterThanOrEqual.rawValue, ">=")
        XCTAssertEqual(RTSComparisonOperator.lessThanOrEqual.rawValue, "<=")
        XCTAssertEqual(RTSComparisonOperator.equal.rawValue, "==")
        XCTAssertEqual(RTSComparisonOperator.between.rawValue, "between")
    }
}

// MARK: - RTSCriterionCategory Tests

final class RTSModelCriterionCategoryTests: XCTestCase {

    func testRawValues() {
        XCTAssertEqual(RTSCriterionCategory.functional.rawValue, "functional")
        XCTAssertEqual(RTSCriterionCategory.strength.rawValue, "strength")
        XCTAssertEqual(RTSCriterionCategory.rom.rawValue, "rom")
        XCTAssertEqual(RTSCriterionCategory.pain.rawValue, "pain")
        XCTAssertEqual(RTSCriterionCategory.psychological.rawValue, "psychological")
    }

    func testDisplayNames() {
        XCTAssertEqual(RTSCriterionCategory.functional.displayName, "Functional")
        XCTAssertEqual(RTSCriterionCategory.strength.displayName, "Strength")
        XCTAssertEqual(RTSCriterionCategory.rom.displayName, "Range of Motion")
        XCTAssertEqual(RTSCriterionCategory.pain.displayName, "Pain")
        XCTAssertEqual(RTSCriterionCategory.psychological.displayName, "Psychological")
    }

    func testAllCases() {
        XCTAssertEqual(RTSCriterionCategory.allCases.count, 5)
    }
}

// MARK: - RTSClearance Tests

final class RTSClearanceTests: XCTestCase {

    let protocolId = UUID()
    let therapistId = UUID()
    let physicianId = UUID()

    // MARK: - Encoding/Decoding Tests

    func testRTSClearance_Encoding() throws {
        let clearance = RTSTestFixtures.createClearance(protocolId: protocolId)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(clearance)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertNotNil(json["protocol_id"])
        XCTAssertNotNil(json["clearance_type"])
        XCTAssertNotNil(json["clearance_level"])
        XCTAssertNotNil(json["assessment_summary"])
        XCTAssertNotNil(json["requires_physician_signature"])
    }

    func testRTSClearance_Decoding() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "protocol_id": "00000000-0000-0000-0000-000000000002",
            "clearance_type": "final_clearance",
            "clearance_level": "green",
            "status": "signed",
            "assessment_summary": "All criteria met",
            "recommendations": "Full return to sport",
            "requires_physician_signature": true,
            "signed_by": "00000000-0000-0000-0000-000000000003",
            "signed_at": "2024-02-01T12:00:00Z",
            "created_at": "2024-01-15T12:00:00Z",
            "updated_at": "2024-02-01T12:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let clearance = try decoder.decode(RTSClearance.self, from: json)

        XCTAssertEqual(clearance.clearanceType, .finalClearance)
        XCTAssertEqual(clearance.clearanceLevel, .green)
        XCTAssertEqual(clearance.status, .signed)
        XCTAssertTrue(clearance.requiresPhysicianSignature)
        XCTAssertNotNil(clearance.signedBy)
        XCTAssertNotNil(clearance.signedAt)
    }

    // MARK: - Signing Workflow Tests

    func testCanEdit_WhenDraft() {
        let clearance = RTSTestFixtures.createClearance(
            protocolId: protocolId,
            status: .draft
        )

        XCTAssertTrue(clearance.canEdit)
    }

    func testCanEdit_WhenComplete() {
        let clearance = RTSTestFixtures.createClearance(
            protocolId: protocolId,
            status: .complete
        )

        XCTAssertFalse(clearance.canEdit)
    }

    func testCanEdit_WhenSigned() {
        let clearance = RTSTestFixtures.createClearance(
            protocolId: protocolId,
            status: .signed
        )

        XCTAssertFalse(clearance.canEdit)
    }

    func testCanSign_WhenComplete() {
        let clearance = RTSTestFixtures.createClearance(
            protocolId: protocolId,
            status: .complete
        )

        XCTAssertTrue(clearance.canSign)
    }

    func testCanSign_WhenDraft() {
        let clearance = RTSTestFixtures.createClearance(
            protocolId: protocolId,
            status: .draft
        )

        XCTAssertFalse(clearance.canSign)
    }

    func testCanCoSign_WhenSignedAndRequiresPhysician() {
        let clearance = RTSTestFixtures.createClearance(
            protocolId: protocolId,
            status: .signed,
            requiresPhysicianSignature: true,
            signedBy: therapistId,
            signedAt: Date()
        )

        XCTAssertTrue(clearance.canCoSign)
    }

    func testCanCoSign_WhenSignedButNotRequired() {
        let clearance = RTSTestFixtures.createClearance(
            protocolId: protocolId,
            status: .signed,
            requiresPhysicianSignature: false,
            signedBy: therapistId,
            signedAt: Date()
        )

        XCTAssertFalse(clearance.canCoSign)
    }

    func testCanCoSign_WhenAlreadyCoSigned() {
        let clearance = RTSTestFixtures.createClearance(
            protocolId: protocolId,
            status: .coSigned,
            requiresPhysicianSignature: true,
            signedBy: therapistId,
            signedAt: Date(),
            coSignedBy: physicianId,
            coSignedAt: Date()
        )

        XCTAssertFalse(clearance.canCoSign)
    }

    // MARK: - Signature Status Tests

    func testIsFullySigned_NoCoSignRequired() {
        let clearance = RTSTestFixtures.createClearance(
            protocolId: protocolId,
            status: .signed,
            requiresPhysicianSignature: false,
            signedBy: therapistId,
            signedAt: Date()
        )

        XCTAssertTrue(clearance.isSigned)
        XCTAssertTrue(clearance.isFullySigned)
    }

    func testIsFullySigned_CoSignRequired_NotCoSigned() {
        let clearance = RTSTestFixtures.createClearance(
            protocolId: protocolId,
            status: .signed,
            requiresPhysicianSignature: true,
            signedBy: therapistId,
            signedAt: Date()
        )

        XCTAssertTrue(clearance.isSigned)
        XCTAssertFalse(clearance.isFullySigned)
    }

    func testIsFullySigned_CoSignRequired_CoSigned() {
        let clearance = RTSTestFixtures.createClearance(
            protocolId: protocolId,
            status: .coSigned,
            requiresPhysicianSignature: true,
            signedBy: therapistId,
            signedAt: Date(),
            coSignedBy: physicianId,
            coSignedAt: Date()
        )

        XCTAssertTrue(clearance.isSigned)
        XCTAssertTrue(clearance.isFullySigned)
    }

    func testIsFullyCleared_GreenAndFullySigned() {
        let clearance = RTSTestFixtures.createClearance(
            protocolId: protocolId,
            clearanceType: .finalClearance,
            clearanceLevel: .green,
            status: .signed,
            requiresPhysicianSignature: false,
            signedBy: therapistId,
            signedAt: Date()
        )

        XCTAssertTrue(clearance.isFullyCleared)
    }

    func testIsFullyCleared_YellowLevel() {
        let clearance = RTSTestFixtures.createClearance(
            protocolId: protocolId,
            clearanceLevel: .yellow,
            status: .signed,
            requiresPhysicianSignature: false,
            signedBy: therapistId,
            signedAt: Date()
        )

        XCTAssertFalse(clearance.isFullyCleared)
    }

    func testSignatureStatusText_Variations() {
        let draft = RTSTestFixtures.createClearance(protocolId: protocolId, status: .draft)
        XCTAssertEqual(draft.signatureStatusText, "Draft")

        let complete = RTSTestFixtures.createClearance(protocolId: protocolId, status: .complete)
        XCTAssertEqual(complete.signatureStatusText, "Ready for Signature")

        let signedNoCoSign = RTSTestFixtures.createClearance(
            protocolId: protocolId,
            status: .signed,
            requiresPhysicianSignature: false,
            signedBy: therapistId,
            signedAt: Date()
        )
        XCTAssertEqual(signedNoCoSign.signatureStatusText, "Fully Signed")

        let signedAwaitingCoSign = RTSTestFixtures.createClearance(
            protocolId: protocolId,
            status: .signed,
            requiresPhysicianSignature: true,
            signedBy: therapistId,
            signedAt: Date()
        )
        XCTAssertEqual(signedAwaitingCoSign.signatureStatusText, "Awaiting Co-Signature")

        let coSigned = RTSTestFixtures.createClearance(
            protocolId: protocolId,
            status: .coSigned,
            requiresPhysicianSignature: true,
            signedBy: therapistId,
            signedAt: Date(),
            coSignedBy: physicianId,
            coSignedAt: Date()
        )
        XCTAssertEqual(coSigned.signatureStatusText, "Fully Signed")
    }
}

// MARK: - RTSClearanceStatus Tests

final class RTSModelClearanceStatusTests: XCTestCase {

    func testRawValues() {
        XCTAssertEqual(RTSClearanceStatus.draft.rawValue, "draft")
        XCTAssertEqual(RTSClearanceStatus.complete.rawValue, "complete")
        XCTAssertEqual(RTSClearanceStatus.signed.rawValue, "signed")
        XCTAssertEqual(RTSClearanceStatus.coSigned.rawValue, "co_signed")
    }

    func testDisplayNames() {
        XCTAssertEqual(RTSClearanceStatus.draft.displayName, "Draft")
        XCTAssertEqual(RTSClearanceStatus.complete.displayName, "Complete")
        XCTAssertEqual(RTSClearanceStatus.signed.displayName, "Signed")
        XCTAssertEqual(RTSClearanceStatus.coSigned.displayName, "Co-Signed")
    }

    func testIsLocked() {
        XCTAssertFalse(RTSClearanceStatus.draft.isLocked)
        XCTAssertFalse(RTSClearanceStatus.complete.isLocked)
        XCTAssertTrue(RTSClearanceStatus.signed.isLocked)
        XCTAssertTrue(RTSClearanceStatus.coSigned.isLocked)
    }

    func testTransitions_DraftToComplete() {
        // Simulating workflow transition
        var status = RTSClearanceStatus.draft
        XCTAssertFalse(status.isLocked)

        status = .complete
        XCTAssertFalse(status.isLocked)
    }

    func testTransitions_CompleteToSigned() {
        var status = RTSClearanceStatus.complete
        XCTAssertFalse(status.isLocked)

        status = .signed
        XCTAssertTrue(status.isLocked)
    }

    func testTransitions_SignedToCoSigned() {
        var status = RTSClearanceStatus.signed
        XCTAssertTrue(status.isLocked)

        status = .coSigned
        XCTAssertTrue(status.isLocked)
    }
}

// MARK: - RTSClearanceType Tests

final class RTSModelClearanceTypeTests: XCTestCase {

    func testRawValues() {
        XCTAssertEqual(RTSClearanceType.phaseClearance.rawValue, "phase_clearance")
        XCTAssertEqual(RTSClearanceType.finalClearance.rawValue, "final_clearance")
        XCTAssertEqual(RTSClearanceType.conditionalClearance.rawValue, "conditional_clearance")
    }

    func testDisplayNames() {
        XCTAssertEqual(RTSClearanceType.phaseClearance.displayName, "Phase Clearance")
        XCTAssertEqual(RTSClearanceType.finalClearance.displayName, "Final Clearance")
        XCTAssertEqual(RTSClearanceType.conditionalClearance.displayName, "Conditional Clearance")
    }
}

// MARK: - RTSReadinessScore Tests

final class RTSModelReadinessScoreTests: XCTestCase {

    let protocolId = UUID()
    let phaseId = UUID()

    // MARK: - Encoding/Decoding Tests

    func testRTSReadinessScore_Encoding() throws {
        let score = RTSTestFixtures.createReadinessScore(
            protocolId: protocolId,
            phaseId: phaseId
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(score)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertNotNil(json["protocol_id"])
        XCTAssertNotNil(json["phase_id"])
        XCTAssertNotNil(json["physical_score"])
        XCTAssertNotNil(json["functional_score"])
        XCTAssertNotNil(json["psychological_score"])
        XCTAssertNotNil(json["overall_score"])
        XCTAssertNotNil(json["traffic_light"])
    }

    func testRTSReadinessScore_Decoding() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "protocol_id": "00000000-0000-0000-0000-000000000002",
            "phase_id": "00000000-0000-0000-0000-000000000003",
            "recorded_by": "00000000-0000-0000-0000-000000000004",
            "recorded_at": "2024-02-01T12:00:00Z",
            "physical_score": 85.0,
            "functional_score": 82.0,
            "psychological_score": 78.0,
            "overall_score": 82.4,
            "traffic_light": "green",
            "risk_factors": [],
            "created_at": "2024-02-01T12:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let score = try decoder.decode(RTSReadinessScore.self, from: json)

        XCTAssertEqual(score.physicalScore, 85.0)
        XCTAssertEqual(score.functionalScore, 82.0)
        XCTAssertEqual(score.psychologicalScore, 78.0)
        XCTAssertEqual(score.overallScore, 82.4)
        XCTAssertEqual(score.trafficLight, .green)
    }

    // MARK: - Calculate Overall Tests

    func testCalculateOverall_AllEqual() {
        // 100 * 0.4 + 100 * 0.4 + 100 * 0.2 = 100
        let result = RTSReadinessScore.calculateOverall(
            physical: 100,
            functional: 100,
            psychological: 100
        )
        XCTAssertEqual(result, 100, accuracy: 0.01)
    }

    func testCalculateOverall_AllZero() {
        let result = RTSReadinessScore.calculateOverall(
            physical: 0,
            functional: 0,
            psychological: 0
        )
        XCTAssertEqual(result, 0, accuracy: 0.01)
    }

    func testCalculateOverall_PhysicalWeight() {
        // 100 * 0.4 + 0 * 0.4 + 0 * 0.2 = 40
        let result = RTSReadinessScore.calculateOverall(
            physical: 100,
            functional: 0,
            psychological: 0
        )
        XCTAssertEqual(result, 40, accuracy: 0.01)
    }

    func testCalculateOverall_FunctionalWeight() {
        // 0 * 0.4 + 100 * 0.4 + 0 * 0.2 = 40
        let result = RTSReadinessScore.calculateOverall(
            physical: 0,
            functional: 100,
            psychological: 0
        )
        XCTAssertEqual(result, 40, accuracy: 0.01)
    }

    func testCalculateOverall_PsychologicalWeight() {
        // 0 * 0.4 + 0 * 0.4 + 100 * 0.2 = 20
        let result = RTSReadinessScore.calculateOverall(
            physical: 0,
            functional: 0,
            psychological: 100
        )
        XCTAssertEqual(result, 20, accuracy: 0.01)
    }

    func testCalculateOverall_MixedScores() {
        // 90 * 0.4 + 80 * 0.4 + 70 * 0.2 = 36 + 32 + 14 = 82
        let result = RTSReadinessScore.calculateOverall(
            physical: 90,
            functional: 80,
            psychological: 70
        )
        XCTAssertEqual(result, 82, accuracy: 0.01)
    }

    func testCalculateOverall_BoundaryCase_ExactlyGreen() {
        // Target 80: 80 * 0.4 + 80 * 0.4 + 80 * 0.2 = 32 + 32 + 16 = 80
        let result = RTSReadinessScore.calculateOverall(
            physical: 80,
            functional: 80,
            psychological: 80
        )
        XCTAssertEqual(result, 80, accuracy: 0.01)
    }

    func testCalculateOverall_BoundaryCase_JustBelowGreen() {
        // 80 * 0.4 + 80 * 0.4 + 75 * 0.2 = 32 + 32 + 15 = 79
        let result = RTSReadinessScore.calculateOverall(
            physical: 80,
            functional: 80,
            psychological: 75
        )
        XCTAssertEqual(result, 79, accuracy: 0.01)
    }

    // MARK: - Auto-calculate Tests

    func testInitializer_AutoCalculatesOverall() {
        let score = RTSReadinessScore(
            protocolId: protocolId,
            phaseId: phaseId,
            recordedBy: UUID(),
            physicalScore: 90,
            functionalScore: 80,
            psychologicalScore: 70
        )

        // 90 * 0.4 + 80 * 0.4 + 70 * 0.2 = 82
        XCTAssertEqual(score.overallScore, 82, accuracy: 0.01)
    }

    func testInitializer_AutoCalculatesTrafficLight_Green() {
        let score = RTSReadinessScore(
            protocolId: protocolId,
            phaseId: phaseId,
            recordedBy: UUID(),
            physicalScore: 90,
            functionalScore: 90,
            psychologicalScore: 90
        )

        XCTAssertEqual(score.trafficLight, .green)
    }

    func testInitializer_AutoCalculatesTrafficLight_Yellow() {
        let score = RTSReadinessScore(
            protocolId: protocolId,
            phaseId: phaseId,
            recordedBy: UUID(),
            physicalScore: 70,
            functionalScore: 70,
            psychologicalScore: 70
        )

        XCTAssertEqual(score.trafficLight, .yellow)
    }

    func testInitializer_AutoCalculatesTrafficLight_Red() {
        let score = RTSReadinessScore(
            protocolId: protocolId,
            phaseId: phaseId,
            recordedBy: UUID(),
            physicalScore: 50,
            functionalScore: 50,
            psychologicalScore: 50
        )

        XCTAssertEqual(score.trafficLight, .red)
    }

    // MARK: - Risk Factor Tests

    func testHasHighRisk_WithHighRiskFactor() {
        let riskFactors = [
            RTSRiskFactor(category: "Pain", name: "Persistent pain", severity: .high)
        ]
        let score = RTSTestFixtures.createReadinessScore(
            protocolId: protocolId,
            phaseId: phaseId,
            riskFactors: riskFactors
        )

        XCTAssertTrue(score.hasHighRisk)
    }

    func testHasHighRisk_WithModerateRiskOnly() {
        let riskFactors = [
            RTSRiskFactor(category: "Strength", name: "LSI below threshold", severity: .moderate)
        ]
        let score = RTSTestFixtures.createReadinessScore(
            protocolId: protocolId,
            phaseId: phaseId,
            riskFactors: riskFactors
        )

        XCTAssertFalse(score.hasHighRisk)
    }

    func testHasModerateOrHigherRisk() {
        let riskFactors = [
            RTSRiskFactor(category: "Psychological", name: "Fear of reinjury", severity: .moderate)
        ]
        let score = RTSTestFixtures.createReadinessScore(
            protocolId: protocolId,
            phaseId: phaseId,
            riskFactors: riskFactors
        )

        XCTAssertTrue(score.hasModerateOrHigherRisk)
    }

    func testRiskFactorCounts() {
        let riskFactors = [
            RTSRiskFactor(category: "Pain", name: "Pain1", severity: .high),
            RTSRiskFactor(category: "Pain", name: "Pain2", severity: .high),
            RTSRiskFactor(category: "Strength", name: "Strength1", severity: .moderate),
            RTSRiskFactor(category: "Psychological", name: "Psych1", severity: .low),
            RTSRiskFactor(category: "Psychological", name: "Psych2", severity: .low)
        ]
        let score = RTSTestFixtures.createReadinessScore(
            protocolId: protocolId,
            phaseId: phaseId,
            riskFactors: riskFactors
        )

        let counts = score.riskFactorCounts
        XCTAssertEqual(counts.high, 2)
        XCTAssertEqual(counts.moderate, 1)
        XCTAssertEqual(counts.low, 2)
    }

    // MARK: - Percentage Formatting Tests

    func testPercentageStrings() {
        let score = RTSTestFixtures.createReadinessScore(
            protocolId: protocolId,
            phaseId: phaseId,
            physical: 85,
            functional: 82,
            psychological: 78
        )

        XCTAssertEqual(score.physicalPercentage, "85%")
        XCTAssertEqual(score.functionalPercentage, "82%")
        XCTAssertEqual(score.psychologicalPercentage, "78%")
    }
}

// MARK: - RTSRiskSeverity Tests

final class RTSModelRiskSeverityTests: XCTestCase {

    func testRawValues() {
        XCTAssertEqual(RTSRiskSeverity.low.rawValue, "low")
        XCTAssertEqual(RTSRiskSeverity.moderate.rawValue, "moderate")
        XCTAssertEqual(RTSRiskSeverity.high.rawValue, "high")
    }

    func testDisplayNames() {
        XCTAssertEqual(RTSRiskSeverity.low.displayName, "Low")
        XCTAssertEqual(RTSRiskSeverity.moderate.displayName, "Moderate")
        XCTAssertEqual(RTSRiskSeverity.high.displayName, "High")
    }

    func testWeights() {
        XCTAssertEqual(RTSRiskSeverity.low.weight, 0.25)
        XCTAssertEqual(RTSRiskSeverity.moderate.weight, 0.5)
        XCTAssertEqual(RTSRiskSeverity.high.weight, 1.0)
    }
}

// MARK: - RTSSport Tests

final class RTSModelSportTests: XCTestCase {

    func testRTSSport_Encoding() throws {
        let sport = RTSTestFixtures.baseballSport

        let encoder = JSONEncoder()
        let data = try encoder.encode(sport)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertNotNil(json["default_phases"])
        XCTAssertNotNil(json["created_at"])
        XCTAssertNotNil(json["updated_at"])
    }

    func testRTSSport_Decoding() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0001-000000000001",
            "name": "Baseball",
            "category": "throwing",
            "default_phases": [
                {
                    "phase_number": 1,
                    "phase_name": "Protected Motion",
                    "activity_level": "red",
                    "description": "Pain-free ROM",
                    "target_duration_weeks": 2
                }
            ],
            "created_at": "2024-01-15T12:00:00Z",
            "updated_at": "2024-01-15T12:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let sport = try decoder.decode(RTSSport.self, from: json)

        XCTAssertEqual(sport.name, "Baseball")
        XCTAssertEqual(sport.category, .throwing)
        XCTAssertEqual(sport.defaultPhases.count, 1)
        XCTAssertEqual(sport.defaultPhases.first?.phaseNumber, 1)
    }

    func testBaseballSportFixture() {
        let sport = RTSTestFixtures.baseballSport

        XCTAssertEqual(sport.name, "Baseball")
        XCTAssertEqual(sport.category, .throwing)
        XCTAssertEqual(sport.defaultPhases.count, 4)
    }

    func testRunningSportFixture() {
        let sport = RTSTestFixtures.runningSport

        XCTAssertEqual(sport.name, "Running")
        XCTAssertEqual(sport.category, .running)
        XCTAssertEqual(sport.defaultPhases.count, 4)
    }

    func testSoccerSportFixture() {
        let sport = RTSTestFixtures.soccerSport

        XCTAssertEqual(sport.name, "Soccer")
        XCTAssertEqual(sport.category, .cutting)
        XCTAssertEqual(sport.defaultPhases.count, 4)
    }

    func testBasketballSportFixture() {
        let sport = RTSTestFixtures.basketballSport

        XCTAssertEqual(sport.name, "Basketball")
        XCTAssertEqual(sport.category, .cutting)
        XCTAssertEqual(sport.defaultPhases.count, 5)
    }
}

// MARK: - RTSSportCategory Tests

final class RTSModelSportCategoryTests: XCTestCase {

    func testRawValues() {
        XCTAssertEqual(RTSSportCategory.throwing.rawValue, "throwing")
        XCTAssertEqual(RTSSportCategory.running.rawValue, "running")
        XCTAssertEqual(RTSSportCategory.cutting.rawValue, "cutting")
    }

    func testDisplayNames() {
        XCTAssertEqual(RTSSportCategory.throwing.displayName, "Throwing Sports")
        XCTAssertEqual(RTSSportCategory.running.displayName, "Running Sports")
        XCTAssertEqual(RTSSportCategory.cutting.displayName, "Cutting/Pivoting Sports")
    }

    func testAllCases() {
        XCTAssertEqual(RTSSportCategory.allCases.count, 3)
    }
}

// MARK: - RTSPhaseTemplate Tests

final class RTSModelPhaseTemplateTests: XCTestCase {

    func testRTSPhaseTemplate_Decoding() throws {
        let json = """
        {
            "phase_number": 2,
            "phase_name": "Light Tossing",
            "activity_level": "yellow",
            "description": "Light catch at short distance",
            "target_duration_weeks": 2
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let template = try decoder.decode(RTSPhaseTemplate.self, from: json)

        XCTAssertEqual(template.phaseNumber, 2)
        XCTAssertEqual(template.phaseName, "Light Tossing")
        XCTAssertEqual(template.activityLevel, .yellow)
        XCTAssertEqual(template.targetDurationWeeks, 2)
    }

    func testRTSPhaseTemplate_Id() {
        let template = RTSPhaseTemplate(
            phaseNumber: 1,
            phaseName: "Protected Motion",
            activityLevel: .red,
            description: "Test"
        )

        XCTAssertEqual(template.id, "1-Protected Motion")
    }
}

// MARK: - RTSAdvancementDecision Tests

final class RTSModelAdvancementDecisionTests: XCTestCase {

    func testRawValues() {
        XCTAssertEqual(RTSAdvancementDecision.advance.rawValue, "advance")
        XCTAssertEqual(RTSAdvancementDecision.extend.rawValue, "extend")
        XCTAssertEqual(RTSAdvancementDecision.hold.rawValue, "hold")
        XCTAssertEqual(RTSAdvancementDecision.manualOverride.rawValue, "manualOverride")
    }

    func testDisplayNames() {
        XCTAssertEqual(RTSAdvancementDecision.advance.displayName, "Advance")
        XCTAssertEqual(RTSAdvancementDecision.extend.displayName, "Extend")
        XCTAssertEqual(RTSAdvancementDecision.hold.displayName, "Hold")
        XCTAssertEqual(RTSAdvancementDecision.manualOverride.displayName, "Manual Override")
    }

    func testInitFromRawValue() {
        XCTAssertEqual(RTSAdvancementDecision(rawValue: "advance"), .advance)
        XCTAssertEqual(RTSAdvancementDecision(rawValue: "extend"), .extend)
        XCTAssertEqual(RTSAdvancementDecision(rawValue: "hold"), .hold)
        XCTAssertEqual(RTSAdvancementDecision(rawValue: "manualOverride"), .manualOverride)
        XCTAssertNil(RTSAdvancementDecision(rawValue: "invalid"))
    }

    func testAllCases() {
        let allCases = RTSAdvancementDecision.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.advance))
        XCTAssertTrue(allCases.contains(.extend))
        XCTAssertTrue(allCases.contains(.hold))
        XCTAssertTrue(allCases.contains(.manualOverride))
    }

    func testEncoding() throws {
        let decision = RTSAdvancementDecision.advance
        let encoder = JSONEncoder()
        let data = try encoder.encode(decision)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertEqual(jsonString, "\"advance\"")
    }

    func testDecoding() throws {
        let json = "\"extend\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        let decision = try decoder.decode(RTSAdvancementDecision.self, from: json)

        XCTAssertEqual(decision, .extend)
    }
}

// MARK: - RTSCriteriaSummary Tests (already exists but adding more comprehensive tests)

final class RTSCriteriaSummaryModelTests: XCTestCase {

    func testDefaultInit() {
        let summary = RTSCriteriaSummary()

        XCTAssertEqual(summary.totalCriteria, 0)
        XCTAssertEqual(summary.passedCriteria, 0)
        XCTAssertEqual(summary.requiredPassed, 0)
        XCTAssertEqual(summary.requiredTotal, 0)
        XCTAssertNil(summary.notes)
    }

    func testCustomInit() {
        let summary = RTSCriteriaSummary(
            totalCriteria: 10,
            passedCriteria: 8,
            requiredPassed: 5,
            requiredTotal: 5,
            notes: "All required criteria met"
        )

        XCTAssertEqual(summary.totalCriteria, 10)
        XCTAssertEqual(summary.passedCriteria, 8)
        XCTAssertEqual(summary.requiredPassed, 5)
        XCTAssertEqual(summary.requiredTotal, 5)
        XCTAssertEqual(summary.notes, "All required criteria met")
    }

    func testHashable() {
        let summary1 = RTSCriteriaSummary(
            totalCriteria: 5,
            passedCriteria: 4,
            requiredPassed: 3,
            requiredTotal: 3
        )
        let summary2 = RTSCriteriaSummary(
            totalCriteria: 5,
            passedCriteria: 4,
            requiredPassed: 3,
            requiredTotal: 3
        )

        XCTAssertEqual(summary1, summary2)
        XCTAssertEqual(summary1.hashValue, summary2.hashValue)
    }

    func testDecoding() throws {
        let json = """
        {
            "total_criteria": 5,
            "passed_criteria": 4,
            "required_passed": 3,
            "required_total": 3,
            "notes": "Test notes"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let summary = try decoder.decode(RTSCriteriaSummary.self, from: json)

        XCTAssertEqual(summary.totalCriteria, 5)
        XCTAssertEqual(summary.passedCriteria, 4)
        XCTAssertEqual(summary.requiredPassed, 3)
        XCTAssertEqual(summary.requiredTotal, 3)
        XCTAssertEqual(summary.notes, "Test notes")
    }

    func testDecodingWithNullNotes() throws {
        let json = """
        {
            "total_criteria": 3,
            "passed_criteria": 2,
            "required_passed": 2,
            "required_total": 2,
            "notes": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let summary = try decoder.decode(RTSCriteriaSummary.self, from: json)

        XCTAssertNil(summary.notes)
    }

    func testAllZeros() {
        let summary = RTSCriteriaSummary(
            totalCriteria: 0,
            passedCriteria: 0,
            requiredPassed: 0,
            requiredTotal: 0
        )

        XCTAssertEqual(summary.totalCriteria, 0)
        XCTAssertEqual(summary.passedCriteria, 0)
        XCTAssertEqual(summary.requiredPassed, 0)
        XCTAssertEqual(summary.requiredTotal, 0)
    }
}
