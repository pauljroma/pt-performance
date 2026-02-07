//
//  RTSServiceTests.swift
//  PTPerformanceTests
//
//  Comprehensive unit tests for RTSService
//  Tests Return-to-Sport service operations including sports, protocols, phases,
//  criteria, test results, advancements, clearances, and readiness scores.
//

import XCTest
@testable import PTPerformance

// MARK: - RTSServiceError Tests

final class RTSServiceErrorTests: XCTestCase {

    // MARK: - Error Description Tests

    func testRTSServiceError_FetchFailed_Description() {
        let error = RTSServiceError.fetchFailed("sports")
        XCTAssertEqual(error.errorDescription, "Failed to fetch: sports")
    }

    func testRTSServiceError_SaveFailed_Description() {
        let error = RTSServiceError.saveFailed("protocol")
        XCTAssertEqual(error.errorDescription, "Failed to save: protocol")
    }

    func testRTSServiceError_ProtocolNotFound_Description() {
        let error = RTSServiceError.protocolNotFound
        XCTAssertEqual(error.errorDescription, "RTS protocol not found")
    }

    func testRTSServiceError_PhaseNotFound_Description() {
        let error = RTSServiceError.phaseNotFound
        XCTAssertEqual(error.errorDescription, "Phase not found")
    }

    func testRTSServiceError_CriterionNotFound_Description() {
        let error = RTSServiceError.criterionNotFound
        XCTAssertEqual(error.errorDescription, "Milestone criterion not found")
    }

    func testRTSServiceError_ClearanceNotFound_Description() {
        let error = RTSServiceError.clearanceNotFound
        XCTAssertEqual(error.errorDescription, "Clearance document not found")
    }

    func testRTSServiceError_CannotSignClearance_Description() {
        let error = RTSServiceError.cannotSignClearance
        XCTAssertEqual(error.errorDescription, "Cannot sign clearance - document must be marked complete first")
    }

    func testRTSServiceError_CannotCoSignClearance_Description() {
        let error = RTSServiceError.cannotCoSignClearance
        XCTAssertEqual(error.errorDescription, "Cannot co-sign clearance - document must be signed first")
    }

    func testRTSServiceError_InvalidInput_Description() {
        let error = RTSServiceError.invalidInput("Patient ID is required")
        XCTAssertEqual(error.errorDescription, "Patient ID is required")
    }

    func testRTSServiceError_InsufficientData_Description() {
        let error = RTSServiceError.insufficientData
        XCTAssertEqual(error.errorDescription, "Insufficient data to complete operation")
    }

    func testRTSServiceError_NetworkError_Description() {
        let underlyingError = NSError(domain: "test", code: 500, userInfo: nil)
        let error = RTSServiceError.networkError(underlyingError)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Network error"))
    }

    // MARK: - Recovery Suggestion Tests

    func testRTSServiceError_FetchFailed_RecoverySuggestion() {
        let error = RTSServiceError.fetchFailed("data")
        XCTAssertEqual(error.recoverySuggestion, "Please check your connection and try again.")
    }

    func testRTSServiceError_SaveFailed_RecoverySuggestion() {
        let error = RTSServiceError.saveFailed("data")
        XCTAssertEqual(error.recoverySuggestion, "Your changes couldn't be saved. Please try again.")
    }

    func testRTSServiceError_NotFoundErrors_RecoverySuggestion() {
        let notFoundErrors: [RTSServiceError] = [
            .protocolNotFound,
            .phaseNotFound,
            .criterionNotFound,
            .clearanceNotFound
        ]

        for error in notFoundErrors {
            XCTAssertEqual(error.recoverySuggestion, "The requested item may have been deleted. Please refresh.")
        }
    }

    func testRTSServiceError_CannotSignClearance_RecoverySuggestion() {
        let error = RTSServiceError.cannotSignClearance
        XCTAssertEqual(error.recoverySuggestion, "Mark the clearance as complete before signing.")
    }

    func testRTSServiceError_CannotCoSignClearance_RecoverySuggestion() {
        let error = RTSServiceError.cannotCoSignClearance
        XCTAssertEqual(error.recoverySuggestion, "The primary signature must be completed first.")
    }

    func testRTSServiceError_InvalidInput_RecoverySuggestion() {
        let error = RTSServiceError.invalidInput("test")
        XCTAssertEqual(error.recoverySuggestion, "Please correct the input and try again.")
    }

    func testRTSServiceError_InsufficientData_RecoverySuggestion() {
        let error = RTSServiceError.insufficientData
        XCTAssertEqual(error.recoverySuggestion, "Please ensure all required data is provided.")
    }

    func testRTSServiceError_NetworkError_RecoverySuggestion() {
        let underlyingError = NSError(domain: "test", code: 500, userInfo: nil)
        let error = RTSServiceError.networkError(underlyingError)
        XCTAssertEqual(error.recoverySuggestion, "Check your internet connection and try again.")
    }
}

// MARK: - RTSAdvancementDecision Tests

final class RTSAdvancementDecisionTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testRTSAdvancementDecision_RawValues() {
        XCTAssertEqual(RTSAdvancementDecision.advance.rawValue, "advance")
        XCTAssertEqual(RTSAdvancementDecision.extend.rawValue, "extend")
        XCTAssertEqual(RTSAdvancementDecision.hold.rawValue, "hold")
        XCTAssertEqual(RTSAdvancementDecision.manualOverride.rawValue, "manualOverride")
    }

    func testRTSAdvancementDecision_InitFromRawValue() {
        XCTAssertEqual(RTSAdvancementDecision(rawValue: "advance"), .advance)
        XCTAssertEqual(RTSAdvancementDecision(rawValue: "extend"), .extend)
        XCTAssertEqual(RTSAdvancementDecision(rawValue: "hold"), .hold)
        XCTAssertEqual(RTSAdvancementDecision(rawValue: "manualOverride"), .manualOverride)
        XCTAssertNil(RTSAdvancementDecision(rawValue: "invalid"))
    }

    // MARK: - Display Name Tests

    func testRTSAdvancementDecision_DisplayNames() {
        XCTAssertEqual(RTSAdvancementDecision.advance.displayName, "Advance")
        XCTAssertEqual(RTSAdvancementDecision.extend.displayName, "Extend")
        XCTAssertEqual(RTSAdvancementDecision.hold.displayName, "Hold")
        XCTAssertEqual(RTSAdvancementDecision.manualOverride.displayName, "Manual Override")
    }

    // MARK: - CaseIterable Tests

    func testRTSAdvancementDecision_AllCases() {
        let allCases = RTSAdvancementDecision.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.advance))
        XCTAssertTrue(allCases.contains(.extend))
        XCTAssertTrue(allCases.contains(.hold))
        XCTAssertTrue(allCases.contains(.manualOverride))
    }

    // MARK: - Codable Tests

    func testRTSAdvancementDecision_Encoding() throws {
        let decision = RTSAdvancementDecision.advance
        let encoder = JSONEncoder()
        let data = try encoder.encode(decision)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertEqual(jsonString, "\"advance\"")
    }

    func testRTSAdvancementDecision_Decoding() throws {
        let json = "\"extend\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        let decision = try decoder.decode(RTSAdvancementDecision.self, from: json)

        XCTAssertEqual(decision, .extend)
    }
}

// MARK: - RTSCriteriaSummary Tests

final class RTSCriteriaSummaryTests: XCTestCase {

    // MARK: - Initialization Tests

    func testRTSCriteriaSummary_DefaultInit() {
        let summary = RTSCriteriaSummary()

        XCTAssertEqual(summary.totalCriteria, 0)
        XCTAssertEqual(summary.passedCriteria, 0)
        XCTAssertEqual(summary.requiredPassed, 0)
        XCTAssertEqual(summary.requiredTotal, 0)
        XCTAssertNil(summary.notes)
    }

    func testRTSCriteriaSummary_CustomInit() {
        let summary = RTSCriteriaSummary(
            totalCriteria: 5,
            passedCriteria: 4,
            requiredPassed: 3,
            requiredTotal: 3,
            notes: "All required criteria met"
        )

        XCTAssertEqual(summary.totalCriteria, 5)
        XCTAssertEqual(summary.passedCriteria, 4)
        XCTAssertEqual(summary.requiredPassed, 3)
        XCTAssertEqual(summary.requiredTotal, 3)
        XCTAssertEqual(summary.notes, "All required criteria met")
    }

    // MARK: - Hashable Tests

    func testRTSCriteriaSummary_Hashable() {
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

    // MARK: - Codable Tests

    func testRTSCriteriaSummary_Decoding() throws {
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

    func testRTSCriteriaSummary_DecodingWithNullNotes() throws {
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
}

// MARK: - RTSPhaseAdvancement Tests

final class RTSPhaseAdvancementTests: XCTestCase {

    // MARK: - Initialization Tests

    func testRTSPhaseAdvancement_Initialization() {
        let id = UUID()
        let protocolId = UUID()
        let fromPhaseId = UUID()
        let toPhaseId = UUID()
        let decidedBy = UUID()
        let decidedAt = Date()
        let createdAt = Date()

        let summary = RTSCriteriaSummary(
            totalCriteria: 5,
            passedCriteria: 5,
            requiredPassed: 3,
            requiredTotal: 3
        )

        let advancement = RTSPhaseAdvancement(
            id: id,
            protocolId: protocolId,
            fromPhaseId: fromPhaseId,
            toPhaseId: toPhaseId,
            decision: .advance,
            decisionReason: "All criteria met",
            criteriaSummary: summary,
            decidedBy: decidedBy,
            decidedAt: decidedAt,
            createdAt: createdAt
        )

        XCTAssertEqual(advancement.id, id)
        XCTAssertEqual(advancement.protocolId, protocolId)
        XCTAssertEqual(advancement.fromPhaseId, fromPhaseId)
        XCTAssertEqual(advancement.toPhaseId, toPhaseId)
        XCTAssertEqual(advancement.decision, .advance)
        XCTAssertEqual(advancement.decisionReason, "All criteria met")
        XCTAssertEqual(advancement.criteriaSummary.totalCriteria, 5)
        XCTAssertEqual(advancement.decidedBy, decidedBy)
        XCTAssertEqual(advancement.decidedAt, decidedAt)
        XCTAssertEqual(advancement.createdAt, createdAt)
    }

    func testRTSPhaseAdvancement_NilFromPhaseId() {
        let advancement = RTSPhaseAdvancement(
            id: UUID(),
            protocolId: UUID(),
            fromPhaseId: nil,
            toPhaseId: UUID(),
            decision: .advance,
            decisionReason: "Starting protocol",
            criteriaSummary: RTSCriteriaSummary(),
            decidedBy: UUID(),
            decidedAt: Date(),
            createdAt: Date()
        )

        XCTAssertNil(advancement.fromPhaseId)
    }

    // MARK: - Identifiable Tests

    func testRTSPhaseAdvancement_Identifiable() {
        let id = UUID()
        let advancement = RTSPhaseAdvancement(
            id: id,
            protocolId: UUID(),
            fromPhaseId: UUID(),
            toPhaseId: UUID(),
            decision: .hold,
            decisionReason: "Criteria not met",
            criteriaSummary: RTSCriteriaSummary(),
            decidedBy: UUID(),
            decidedAt: Date(),
            createdAt: Date()
        )

        XCTAssertEqual(advancement.id, id)
    }

    // MARK: - Codable Tests

    func testRTSPhaseAdvancement_Decoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "protocol_id": "660e8400-e29b-41d4-a716-446655440001",
            "from_phase_id": "770e8400-e29b-41d4-a716-446655440002",
            "to_phase_id": "880e8400-e29b-41d4-a716-446655440003",
            "decision": "advance",
            "decision_reason": "All gates passed successfully",
            "criteria_summary": {
                "total_criteria": 5,
                "passed_criteria": 5,
                "required_passed": 3,
                "required_total": 3,
                "notes": null
            },
            "decided_by": "990e8400-e29b-41d4-a716-446655440004",
            "decided_at": "2024-01-15T10:00:00Z",
            "created_at": "2024-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let advancement = try decoder.decode(RTSPhaseAdvancement.self, from: json)

        XCTAssertEqual(advancement.decision, .advance)
        XCTAssertEqual(advancement.decisionReason, "All gates passed successfully")
        XCTAssertEqual(advancement.criteriaSummary.totalCriteria, 5)
        XCTAssertEqual(advancement.criteriaSummary.passedCriteria, 5)
    }

    func testRTSPhaseAdvancement_AllDecisionTypes() throws {
        let decisions = ["advance", "extend", "hold", "manualOverride"]

        for decision in decisions {
            let json = """
            {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "protocol_id": "660e8400-e29b-41d4-a716-446655440001",
                "from_phase_id": null,
                "to_phase_id": "880e8400-e29b-41d4-a716-446655440003",
                "decision": "\(decision)",
                "decision_reason": "Test reason",
                "criteria_summary": {
                    "total_criteria": 0,
                    "passed_criteria": 0,
                    "required_passed": 0,
                    "required_total": 0,
                    "notes": null
                },
                "decided_by": "990e8400-e29b-41d4-a716-446655440004",
                "decided_at": "2024-01-15T10:00:00Z",
                "created_at": "2024-01-15T10:00:00Z"
            }
            """.data(using: .utf8)!

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let advancement = try decoder.decode(RTSPhaseAdvancement.self, from: json)

            XCTAssertEqual(advancement.decision.rawValue, decision)
        }
    }
}

// MARK: - RTSService Tests

@MainActor
final class RTSServiceTests: XCTestCase {

    var sut: RTSService!

    override func setUp() async throws {
        try await super.setUp()
        sut = RTSService.shared
        sut.clearError()
    }

    override func tearDown() async throws {
        sut.clearError()
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Singleton Tests

    func testSharedInstanceExists() {
        XCTAssertNotNil(RTSService.shared)
    }

    func testSharedInstanceIsSingleton() {
        let instance1 = RTSService.shared
        let instance2 = RTSService.shared
        XCTAssertTrue(instance1 === instance2, "Shared instances should be the same object")
    }

    // MARK: - Initial State Tests

    func testInitialState_IsLoadingProperty() {
        XCTAssertFalse(sut.isLoading)
    }

    func testInitialState_ErrorMessageProperty() {
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Clear Error Tests

    func testClearError_SetsErrorMessageToNil() {
        // Given: Set an error message
        sut.errorMessage = "Test error"
        XCTAssertNotNil(sut.errorMessage)

        // When
        sut.clearError()

        // Then
        XCTAssertNil(sut.errorMessage)
    }
}

// MARK: - RTSProtocolStatus Tests

final class RTSProtocolStatusTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testRTSProtocolStatus_RawValues() {
        XCTAssertEqual(RTSProtocolStatus.draft.rawValue, "draft")
        XCTAssertEqual(RTSProtocolStatus.active.rawValue, "active")
        XCTAssertEqual(RTSProtocolStatus.completed.rawValue, "completed")
        XCTAssertEqual(RTSProtocolStatus.discontinued.rawValue, "discontinued")
    }

    func testRTSProtocolStatus_InitFromRawValue() {
        XCTAssertEqual(RTSProtocolStatus(rawValue: "draft"), .draft)
        XCTAssertEqual(RTSProtocolStatus(rawValue: "active"), .active)
        XCTAssertEqual(RTSProtocolStatus(rawValue: "completed"), .completed)
        XCTAssertEqual(RTSProtocolStatus(rawValue: "discontinued"), .discontinued)
        XCTAssertNil(RTSProtocolStatus(rawValue: "invalid"))
    }

    // MARK: - Display Name Tests

    func testRTSProtocolStatus_DisplayNames() {
        XCTAssertEqual(RTSProtocolStatus.draft.displayName, "Draft")
        XCTAssertEqual(RTSProtocolStatus.active.displayName, "Active")
        XCTAssertEqual(RTSProtocolStatus.completed.displayName, "Completed")
        XCTAssertEqual(RTSProtocolStatus.discontinued.displayName, "Discontinued")
    }

    // MARK: - Icon Tests

    func testRTSProtocolStatus_Icons() {
        XCTAssertEqual(RTSProtocolStatus.draft.icon, "doc.badge.ellipsis")
        XCTAssertEqual(RTSProtocolStatus.active.icon, "play.circle.fill")
        XCTAssertEqual(RTSProtocolStatus.completed.icon, "checkmark.circle.fill")
        XCTAssertEqual(RTSProtocolStatus.discontinued.icon, "xmark.circle.fill")
    }

    // MARK: - IsEditable Tests

    func testRTSProtocolStatus_IsEditable() {
        XCTAssertTrue(RTSProtocolStatus.draft.isEditable)
        XCTAssertTrue(RTSProtocolStatus.active.isEditable)
        XCTAssertFalse(RTSProtocolStatus.completed.isEditable)
        XCTAssertFalse(RTSProtocolStatus.discontinued.isEditable)
    }

    // MARK: - CaseIterable Tests

    func testRTSProtocolStatus_AllCases() {
        let allCases = RTSProtocolStatus.allCases
        XCTAssertEqual(allCases.count, 4)
    }

    // MARK: - Codable Tests

    func testRTSProtocolStatus_Encoding() throws {
        let status = RTSProtocolStatus.active
        let encoder = JSONEncoder()
        let data = try encoder.encode(status)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertEqual(jsonString, "\"active\"")
    }

    func testRTSProtocolStatus_Decoding() throws {
        let json = "\"completed\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        let status = try decoder.decode(RTSProtocolStatus.self, from: json)

        XCTAssertEqual(status, .completed)
    }
}

// MARK: - RTSProtocol Model Tests

final class RTSProtocolModelTests: XCTestCase {

    // MARK: - Initialization Tests

    func testRTSProtocol_Initialization() {
        let id = UUID()
        let patientId = UUID()
        let therapistId = UUID()
        let sportId = UUID()
        let injuryDate = Date()
        let targetReturnDate = Calendar.current.date(byAdding: .month, value: 6, to: Date())!

        let rtsProtocol = RTSProtocol(
            id: id,
            patientId: patientId,
            therapistId: therapistId,
            sportId: sportId,
            injuryType: "ACL Reconstruction",
            injuryDate: injuryDate,
            targetReturnDate: targetReturnDate
        )

        XCTAssertEqual(rtsProtocol.id, id)
        XCTAssertEqual(rtsProtocol.patientId, patientId)
        XCTAssertEqual(rtsProtocol.therapistId, therapistId)
        XCTAssertEqual(rtsProtocol.sportId, sportId)
        XCTAssertEqual(rtsProtocol.injuryType, "ACL Reconstruction")
        XCTAssertEqual(rtsProtocol.status, .draft)
        XCTAssertNil(rtsProtocol.surgeryDate)
        XCTAssertNil(rtsProtocol.actualReturnDate)
        XCTAssertNil(rtsProtocol.currentPhaseId)
        XCTAssertNil(rtsProtocol.notes)
    }

    // MARK: - Computed Properties Tests

    func testRTSProtocol_IsActive() {
        let activeProtocol = RTSProtocol(
            patientId: UUID(),
            therapistId: UUID(),
            sportId: UUID(),
            injuryType: "Test",
            injuryDate: Date(),
            targetReturnDate: Date(),
            status: .active
        )

        let draftProtocol = RTSProtocol(
            patientId: UUID(),
            therapistId: UUID(),
            sportId: UUID(),
            injuryType: "Test",
            injuryDate: Date(),
            targetReturnDate: Date(),
            status: .draft
        )

        XCTAssertTrue(activeProtocol.isActive)
        XCTAssertFalse(draftProtocol.isActive)
    }

    func testRTSProtocol_IsCompleted() {
        let completedProtocol = RTSProtocol(
            patientId: UUID(),
            therapistId: UUID(),
            sportId: UUID(),
            injuryType: "Test",
            injuryDate: Date(),
            targetReturnDate: Date(),
            status: .completed
        )

        let activeProtocol = RTSProtocol(
            patientId: UUID(),
            therapistId: UUID(),
            sportId: UUID(),
            injuryType: "Test",
            injuryDate: Date(),
            targetReturnDate: Date(),
            status: .active
        )

        XCTAssertTrue(completedProtocol.isCompleted)
        XCTAssertFalse(activeProtocol.isCompleted)
    }

    func testRTSProtocol_DaysSinceInjury() {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let rtsProtocol = RTSProtocol(
            patientId: UUID(),
            therapistId: UUID(),
            sportId: UUID(),
            injuryType: "Test",
            injuryDate: sevenDaysAgo,
            targetReturnDate: Date()
        )

        XCTAssertEqual(rtsProtocol.daysSinceInjury, 7)
    }

    // MARK: - Codable Tests

    func testRTSProtocol_Decoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "therapist_id": "770e8400-e29b-41d4-a716-446655440002",
            "sport_id": "880e8400-e29b-41d4-a716-446655440003",
            "injury_type": "ACL Reconstruction",
            "surgery_date": "2024-01-10T00:00:00Z",
            "injury_date": "2024-01-01T00:00:00Z",
            "target_return_date": "2024-07-01T00:00:00Z",
            "actual_return_date": null,
            "status": "active",
            "current_phase_id": null,
            "notes": "Test protocol",
            "created_at": "2024-01-15T10:00:00Z",
            "updated_at": "2024-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let rtsProtocol = try decoder.decode(RTSProtocol.self, from: json)

        XCTAssertEqual(rtsProtocol.injuryType, "ACL Reconstruction")
        XCTAssertEqual(rtsProtocol.status, .active)
        XCTAssertNotNil(rtsProtocol.surgeryDate)
        XCTAssertNil(rtsProtocol.actualReturnDate)
        XCTAssertNil(rtsProtocol.currentPhaseId)
        XCTAssertEqual(rtsProtocol.notes, "Test protocol")
    }
}

// MARK: - RTSProtocolInput Validation Tests

final class RTSProtocolInputValidationTests: XCTestCase {

    func testRTSProtocolInput_ValidationSuccess() throws {
        let input = RTSProtocolInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            sportId: UUID().uuidString,
            injuryType: "ACL Tear",
            injuryDate: "2024-01-01",
            targetReturnDate: "2024-07-01"
        )

        XCTAssertNoThrow(try input.validate())
    }

    func testRTSProtocolInput_ValidationFailure_MissingPatientId() {
        let input = RTSProtocolInput(
            patientId: nil,
            therapistId: UUID().uuidString,
            sportId: UUID().uuidString,
            injuryType: "ACL Tear",
            injuryDate: "2024-01-01",
            targetReturnDate: "2024-07-01"
        )

        XCTAssertThrowsError(try input.validate()) { error in
            guard case RTSProtocolError.invalidInput(let message) = error else {
                XCTFail("Expected RTSProtocolError.invalidInput")
                return
            }
            XCTAssertEqual(message, "Patient ID is required")
        }
    }

    func testRTSProtocolInput_ValidationFailure_MissingTherapistId() {
        let input = RTSProtocolInput(
            patientId: UUID().uuidString,
            therapistId: nil,
            sportId: UUID().uuidString,
            injuryType: "ACL Tear",
            injuryDate: "2024-01-01",
            targetReturnDate: "2024-07-01"
        )

        XCTAssertThrowsError(try input.validate()) { error in
            guard case RTSProtocolError.invalidInput(let message) = error else {
                XCTFail("Expected RTSProtocolError.invalidInput")
                return
            }
            XCTAssertEqual(message, "Therapist ID is required")
        }
    }

    func testRTSProtocolInput_ValidationFailure_MissingSportId() {
        let input = RTSProtocolInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            sportId: nil,
            injuryType: "ACL Tear",
            injuryDate: "2024-01-01",
            targetReturnDate: "2024-07-01"
        )

        XCTAssertThrowsError(try input.validate()) { error in
            guard case RTSProtocolError.invalidInput(let message) = error else {
                XCTFail("Expected RTSProtocolError.invalidInput")
                return
            }
            XCTAssertEqual(message, "Sport ID is required")
        }
    }

    func testRTSProtocolInput_ValidationFailure_EmptyInjuryType() {
        let input = RTSProtocolInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            sportId: UUID().uuidString,
            injuryType: "",
            injuryDate: "2024-01-01",
            targetReturnDate: "2024-07-01"
        )

        XCTAssertThrowsError(try input.validate()) { error in
            guard case RTSProtocolError.invalidInput(let message) = error else {
                XCTFail("Expected RTSProtocolError.invalidInput")
                return
            }
            XCTAssertEqual(message, "Injury type is required")
        }
    }

    func testRTSProtocolInput_ValidationFailure_MissingInjuryDate() {
        let input = RTSProtocolInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            sportId: UUID().uuidString,
            injuryType: "ACL Tear",
            injuryDate: nil,
            targetReturnDate: "2024-07-01"
        )

        XCTAssertThrowsError(try input.validate()) { error in
            guard case RTSProtocolError.invalidInput(let message) = error else {
                XCTFail("Expected RTSProtocolError.invalidInput")
                return
            }
            XCTAssertEqual(message, "Injury date is required")
        }
    }

    func testRTSProtocolInput_ValidationFailure_MissingTargetReturnDate() {
        let input = RTSProtocolInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            sportId: UUID().uuidString,
            injuryType: "ACL Tear",
            injuryDate: "2024-01-01",
            targetReturnDate: nil
        )

        XCTAssertThrowsError(try input.validate()) { error in
            guard case RTSProtocolError.invalidInput(let message) = error else {
                XCTFail("Expected RTSProtocolError.invalidInput")
                return
            }
            XCTAssertEqual(message, "Target return date is required")
        }
    }
}

// MARK: - RTSPhase Model Tests

final class RTSPhaseModelTests: XCTestCase {

    // MARK: - Initialization Tests

    func testRTSPhase_Initialization() {
        let id = UUID()
        let protocolId = UUID()

        let phase = RTSPhase(
            id: id,
            protocolId: protocolId,
            phaseNumber: 2,
            phaseName: "Light Tossing",
            activityLevel: .yellow,
            description: "Begin light tossing at short distances"
        )

        XCTAssertEqual(phase.id, id)
        XCTAssertEqual(phase.protocolId, protocolId)
        XCTAssertEqual(phase.phaseNumber, 2)
        XCTAssertEqual(phase.phaseName, "Light Tossing")
        XCTAssertEqual(phase.activityLevel, .yellow)
        XCTAssertNil(phase.startedAt)
        XCTAssertNil(phase.completedAt)
    }

    // MARK: - Status Tests

    func testRTSPhase_IsPending() {
        let phase = RTSPhase(
            protocolId: UUID(),
            phaseNumber: 1,
            phaseName: "Test",
            activityLevel: .red,
            description: "Test phase",
            startedAt: nil,
            completedAt: nil
        )

        XCTAssertTrue(phase.isPending)
        XCTAssertFalse(phase.isActive)
        XCTAssertFalse(phase.isCompleted)
    }

    func testRTSPhase_IsActive() {
        let phase = RTSPhase(
            protocolId: UUID(),
            phaseNumber: 1,
            phaseName: "Test",
            activityLevel: .yellow,
            description: "Test phase",
            startedAt: Date(),
            completedAt: nil
        )

        XCTAssertFalse(phase.isPending)
        XCTAssertTrue(phase.isActive)
        XCTAssertFalse(phase.isCompleted)
    }

    func testRTSPhase_IsCompleted() {
        let phase = RTSPhase(
            protocolId: UUID(),
            phaseNumber: 1,
            phaseName: "Test",
            activityLevel: .green,
            description: "Test phase",
            startedAt: Calendar.current.date(byAdding: .day, value: -14, to: Date()),
            completedAt: Date()
        )

        XCTAssertFalse(phase.isPending)
        XCTAssertFalse(phase.isActive)
        XCTAssertTrue(phase.isCompleted)
    }

    // MARK: - Days in Phase Tests

    func testRTSPhase_DaysInPhase_Active() {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let phase = RTSPhase(
            protocolId: UUID(),
            phaseNumber: 1,
            phaseName: "Test",
            activityLevel: .yellow,
            description: "Test phase",
            startedAt: sevenDaysAgo,
            completedAt: nil
        )

        XCTAssertEqual(phase.daysInPhase, 7)
    }

    func testRTSPhase_DaysInPhase_Completed() {
        let fourteenDaysAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!

        let phase = RTSPhase(
            protocolId: UUID(),
            phaseNumber: 1,
            phaseName: "Test",
            activityLevel: .green,
            description: "Test phase",
            startedAt: fourteenDaysAgo,
            completedAt: sevenDaysAgo
        )

        XCTAssertEqual(phase.daysInPhase, 7)
    }

    func testRTSPhase_DaysInPhase_NotStarted() {
        let phase = RTSPhase(
            protocolId: UUID(),
            phaseNumber: 1,
            phaseName: "Test",
            activityLevel: .red,
            description: "Test phase",
            startedAt: nil,
            completedAt: nil
        )

        XCTAssertNil(phase.daysInPhase)
    }

    // MARK: - Status Text Tests

    func testRTSPhase_StatusText() {
        let pendingPhase = RTSPhase(
            protocolId: UUID(),
            phaseNumber: 1,
            phaseName: "Test",
            activityLevel: .red,
            description: "Test phase"
        )
        XCTAssertEqual(pendingPhase.statusText, "Pending")

        let completedPhase = RTSPhase(
            protocolId: UUID(),
            phaseNumber: 1,
            phaseName: "Test",
            activityLevel: .green,
            description: "Test phase",
            startedAt: Calendar.current.date(byAdding: .day, value: -14, to: Date()),
            completedAt: Date()
        )
        XCTAssertEqual(completedPhase.statusText, "Completed")
    }
}

// MARK: - RTSCriterionCategory Tests

final class RTSCriterionCategoryTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testRTSCriterionCategory_RawValues() {
        XCTAssertEqual(RTSCriterionCategory.functional.rawValue, "functional")
        XCTAssertEqual(RTSCriterionCategory.strength.rawValue, "strength")
        XCTAssertEqual(RTSCriterionCategory.rom.rawValue, "rom")
        XCTAssertEqual(RTSCriterionCategory.pain.rawValue, "pain")
        XCTAssertEqual(RTSCriterionCategory.psychological.rawValue, "psychological")
    }

    // MARK: - Display Name Tests

    func testRTSCriterionCategory_DisplayNames() {
        XCTAssertEqual(RTSCriterionCategory.functional.displayName, "Functional")
        XCTAssertEqual(RTSCriterionCategory.strength.displayName, "Strength")
        XCTAssertEqual(RTSCriterionCategory.rom.displayName, "Range of Motion")
        XCTAssertEqual(RTSCriterionCategory.pain.displayName, "Pain")
        XCTAssertEqual(RTSCriterionCategory.psychological.displayName, "Psychological")
    }

    // MARK: - Icon Tests

    func testRTSCriterionCategory_Icons() {
        XCTAssertEqual(RTSCriterionCategory.functional.icon, "figure.walk")
        XCTAssertEqual(RTSCriterionCategory.strength.icon, "dumbbell.fill")
        XCTAssertEqual(RTSCriterionCategory.rom.icon, "arrow.left.and.right")
        XCTAssertEqual(RTSCriterionCategory.pain.icon, "waveform.path.ecg")
        XCTAssertEqual(RTSCriterionCategory.psychological.icon, "brain.head.profile")
    }

    // MARK: - CaseIterable Tests

    func testRTSCriterionCategory_AllCases() {
        let allCases = RTSCriterionCategory.allCases
        XCTAssertEqual(allCases.count, 5)
    }
}

// MARK: - RTSComparisonOperator Tests

final class RTSComparisonOperatorTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testRTSComparisonOperator_RawValues() {
        XCTAssertEqual(RTSComparisonOperator.greaterThanOrEqual.rawValue, ">=")
        XCTAssertEqual(RTSComparisonOperator.lessThanOrEqual.rawValue, "<=")
        XCTAssertEqual(RTSComparisonOperator.equal.rawValue, "==")
        XCTAssertEqual(RTSComparisonOperator.between.rawValue, "between")
    }

    // MARK: - Symbol Tests

    func testRTSComparisonOperator_Symbols() {
        XCTAssertEqual(RTSComparisonOperator.greaterThanOrEqual.symbol, ">=")
        XCTAssertEqual(RTSComparisonOperator.lessThanOrEqual.symbol, "<=")
        XCTAssertEqual(RTSComparisonOperator.equal.symbol, "=")
        XCTAssertEqual(RTSComparisonOperator.between.symbol, "between")
    }

    // MARK: - Evaluate Tests

    func testRTSComparisonOperator_Evaluate_GreaterThanOrEqual() {
        let op = RTSComparisonOperator.greaterThanOrEqual

        XCTAssertTrue(op.evaluate(value: 85, target: 80))
        XCTAssertTrue(op.evaluate(value: 80, target: 80))
        XCTAssertFalse(op.evaluate(value: 79, target: 80))
    }

    func testRTSComparisonOperator_Evaluate_LessThanOrEqual() {
        let op = RTSComparisonOperator.lessThanOrEqual

        XCTAssertTrue(op.evaluate(value: 2, target: 3))
        XCTAssertTrue(op.evaluate(value: 3, target: 3))
        XCTAssertFalse(op.evaluate(value: 4, target: 3))
    }

    func testRTSComparisonOperator_Evaluate_Equal() {
        let op = RTSComparisonOperator.equal

        XCTAssertTrue(op.evaluate(value: 90, target: 90))
        XCTAssertTrue(op.evaluate(value: 90.0005, target: 90))  // Within tolerance
        XCTAssertFalse(op.evaluate(value: 89, target: 90))
    }

    func testRTSComparisonOperator_Evaluate_Between() {
        let op = RTSComparisonOperator.between

        XCTAssertTrue(op.evaluate(value: 75, target: 70, upperBound: 80))
        XCTAssertTrue(op.evaluate(value: 70, target: 70, upperBound: 80))
        XCTAssertTrue(op.evaluate(value: 80, target: 70, upperBound: 80))
        XCTAssertFalse(op.evaluate(value: 65, target: 70, upperBound: 80))
        XCTAssertFalse(op.evaluate(value: 85, target: 70, upperBound: 80))
    }

    func testRTSComparisonOperator_Evaluate_Between_NoUpperBound() {
        let op = RTSComparisonOperator.between

        // Without upper bound, acts like >= target
        XCTAssertTrue(op.evaluate(value: 85, target: 80, upperBound: nil))
        XCTAssertTrue(op.evaluate(value: 80, target: 80, upperBound: nil))
        XCTAssertFalse(op.evaluate(value: 75, target: 80, upperBound: nil))
    }
}

// MARK: - RTSMilestoneCriterion Tests

final class RTSMilestoneCriterionTests: XCTestCase {

    // MARK: - Initialization Tests

    func testRTSMilestoneCriterion_Initialization() {
        let id = UUID()
        let phaseId = UUID()

        let criterion = RTSMilestoneCriterion(
            id: id,
            phaseId: phaseId,
            category: .strength,
            name: "Quad LSI",
            description: "Limb Symmetry Index for quadriceps strength",
            targetValue: 85,
            targetUnit: "%",
            comparisonOperator: .greaterThanOrEqual,
            isRequired: true,
            sortOrder: 1
        )

        XCTAssertEqual(criterion.id, id)
        XCTAssertEqual(criterion.phaseId, phaseId)
        XCTAssertEqual(criterion.category, .strength)
        XCTAssertEqual(criterion.name, "Quad LSI")
        XCTAssertEqual(criterion.targetValue, 85)
        XCTAssertEqual(criterion.targetUnit, "%")
        XCTAssertEqual(criterion.comparisonOperator, .greaterThanOrEqual)
        XCTAssertTrue(criterion.isRequired)
        XCTAssertEqual(criterion.sortOrder, 1)
        XCTAssertNil(criterion.latestResult)
    }

    // MARK: - Computed Properties Tests

    func testRTSMilestoneCriterion_IsPassed_WithPassingResult() {
        let result = RTSTestResult(
            criterionId: UUID(),
            protocolId: UUID(),
            recordedBy: UUID(),
            value: 87,
            unit: "%",
            passed: true
        )

        var criterion = RTSMilestoneCriterion(
            phaseId: UUID(),
            category: .strength,
            name: "Test",
            description: "Test criterion"
        )
        criterion.latestResult = result

        XCTAssertTrue(criterion.isPassed)
        XCTAssertTrue(criterion.hasBeenTested)
    }

    func testRTSMilestoneCriterion_IsPassed_WithFailingResult() {
        let result = RTSTestResult(
            criterionId: UUID(),
            protocolId: UUID(),
            recordedBy: UUID(),
            value: 75,
            unit: "%",
            passed: false
        )

        var criterion = RTSMilestoneCriterion(
            phaseId: UUID(),
            category: .strength,
            name: "Test",
            description: "Test criterion"
        )
        criterion.latestResult = result

        XCTAssertFalse(criterion.isPassed)
        XCTAssertTrue(criterion.hasBeenTested)
    }

    func testRTSMilestoneCriterion_IsPassed_NoResult() {
        let criterion = RTSMilestoneCriterion(
            phaseId: UUID(),
            category: .strength,
            name: "Test",
            description: "Test criterion"
        )

        XCTAssertFalse(criterion.isPassed)
        XCTAssertFalse(criterion.hasBeenTested)
    }

    func testRTSMilestoneCriterion_TargetDescription() {
        let criterion = RTSMilestoneCriterion(
            phaseId: UUID(),
            category: .strength,
            name: "Test",
            description: "Test criterion",
            targetValue: 85,
            targetUnit: "%",
            comparisonOperator: .greaterThanOrEqual
        )

        XCTAssertEqual(criterion.targetDescription, ">= 85 %")
    }

    func testRTSMilestoneCriterion_TargetDescription_NoValue() {
        let criterion = RTSMilestoneCriterion(
            phaseId: UUID(),
            category: .pain,
            name: "Test",
            description: "Test criterion",
            targetValue: nil
        )

        XCTAssertEqual(criterion.targetDescription, "N/A")
    }

    // MARK: - Status Icon Tests

    func testRTSMilestoneCriterion_StatusIcon() {
        // Not tested
        let notTested = RTSMilestoneCriterion(
            phaseId: UUID(),
            category: .strength,
            name: "Test",
            description: "Test"
        )
        XCTAssertEqual(notTested.statusIcon, "circle")

        // Passed
        var passed = notTested
        passed.latestResult = RTSTestResult(
            criterionId: UUID(),
            protocolId: UUID(),
            recordedBy: UUID(),
            value: 90,
            unit: "%",
            passed: true
        )
        XCTAssertEqual(passed.statusIcon, "checkmark.circle.fill")

        // Failed
        var failed = notTested
        failed.latestResult = RTSTestResult(
            criterionId: UUID(),
            protocolId: UUID(),
            recordedBy: UUID(),
            value: 70,
            unit: "%",
            passed: false
        )
        XCTAssertEqual(failed.statusIcon, "xmark.circle.fill")
    }
}

// MARK: - RTSTestResult Tests

final class RTSTestResultTests: XCTestCase {

    // MARK: - Initialization Tests

    func testRTSTestResult_Initialization() {
        let id = UUID()
        let criterionId = UUID()
        let protocolId = UUID()
        let recordedBy = UUID()
        let recordedAt = Date()

        let result = RTSTestResult(
            id: id,
            criterionId: criterionId,
            protocolId: protocolId,
            recordedBy: recordedBy,
            recordedAt: recordedAt,
            value: 87.5,
            unit: "%",
            passed: true,
            notes: "Good result"
        )

        XCTAssertEqual(result.id, id)
        XCTAssertEqual(result.criterionId, criterionId)
        XCTAssertEqual(result.protocolId, protocolId)
        XCTAssertEqual(result.recordedBy, recordedBy)
        XCTAssertEqual(result.recordedAt, recordedAt)
        XCTAssertEqual(result.value, 87.5)
        XCTAssertEqual(result.unit, "%")
        XCTAssertTrue(result.passed)
        XCTAssertEqual(result.notes, "Good result")
    }

    // MARK: - Formatted Value Tests

    func testRTSTestResult_FormattedValue_WholeNumber() {
        let result = RTSTestResult(
            criterionId: UUID(),
            protocolId: UUID(),
            recordedBy: UUID(),
            value: 85,
            unit: "%",
            passed: true
        )

        XCTAssertEqual(result.formattedValue, "85 %")
    }

    func testRTSTestResult_FormattedValue_Decimal() {
        let result = RTSTestResult(
            criterionId: UUID(),
            protocolId: UUID(),
            recordedBy: UUID(),
            value: 87.5,
            unit: "%",
            passed: true
        )

        XCTAssertEqual(result.formattedValue, "87.5 %")
    }

    // MARK: - Codable Tests

    func testRTSTestResult_Decoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "criterion_id": "660e8400-e29b-41d4-a716-446655440001",
            "protocol_id": "770e8400-e29b-41d4-a716-446655440002",
            "recorded_by": "880e8400-e29b-41d4-a716-446655440003",
            "recorded_at": "2024-01-15T10:00:00Z",
            "value": 87.5,
            "unit": "%",
            "passed": true,
            "notes": "Test notes",
            "created_at": "2024-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let result = try decoder.decode(RTSTestResult.self, from: json)

        XCTAssertEqual(result.value, 87.5)
        XCTAssertEqual(result.unit, "%")
        XCTAssertTrue(result.passed)
        XCTAssertEqual(result.notes, "Test notes")
    }
}

// MARK: - RTSClearanceType Tests

final class RTSClearanceTypeTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testRTSClearanceType_RawValues() {
        XCTAssertEqual(RTSClearanceType.phaseClearance.rawValue, "phase_clearance")
        XCTAssertEqual(RTSClearanceType.finalClearance.rawValue, "final_clearance")
        XCTAssertEqual(RTSClearanceType.conditionalClearance.rawValue, "conditional_clearance")
    }

    // MARK: - Display Name Tests

    func testRTSClearanceType_DisplayNames() {
        XCTAssertEqual(RTSClearanceType.phaseClearance.displayName, "Phase Clearance")
        XCTAssertEqual(RTSClearanceType.finalClearance.displayName, "Final Clearance")
        XCTAssertEqual(RTSClearanceType.conditionalClearance.displayName, "Conditional Clearance")
    }

    // MARK: - Icon Tests

    func testRTSClearanceType_Icons() {
        XCTAssertEqual(RTSClearanceType.phaseClearance.icon, "arrow.right.circle.fill")
        XCTAssertEqual(RTSClearanceType.finalClearance.icon, "checkmark.seal.fill")
        XCTAssertEqual(RTSClearanceType.conditionalClearance.icon, "exclamationmark.shield.fill")
    }

    // MARK: - Description Tests

    func testRTSClearanceType_Descriptions() {
        XCTAssertFalse(RTSClearanceType.phaseClearance.description.isEmpty)
        XCTAssertFalse(RTSClearanceType.finalClearance.description.isEmpty)
        XCTAssertFalse(RTSClearanceType.conditionalClearance.description.isEmpty)
    }

    // MARK: - CaseIterable Tests

    func testRTSClearanceType_AllCases() {
        let allCases = RTSClearanceType.allCases
        XCTAssertEqual(allCases.count, 3)
    }
}

// MARK: - RTSClearanceStatus Tests

final class RTSClearanceStatusTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testRTSClearanceStatus_RawValues() {
        XCTAssertEqual(RTSClearanceStatus.draft.rawValue, "draft")
        XCTAssertEqual(RTSClearanceStatus.complete.rawValue, "complete")
        XCTAssertEqual(RTSClearanceStatus.signed.rawValue, "signed")
        XCTAssertEqual(RTSClearanceStatus.coSigned.rawValue, "co_signed")
    }

    // MARK: - Display Name Tests

    func testRTSClearanceStatus_DisplayNames() {
        XCTAssertEqual(RTSClearanceStatus.draft.displayName, "Draft")
        XCTAssertEqual(RTSClearanceStatus.complete.displayName, "Complete")
        XCTAssertEqual(RTSClearanceStatus.signed.displayName, "Signed")
        XCTAssertEqual(RTSClearanceStatus.coSigned.displayName, "Co-Signed")
    }

    // MARK: - Icon Tests

    func testRTSClearanceStatus_Icons() {
        XCTAssertEqual(RTSClearanceStatus.draft.icon, "doc.badge.ellipsis")
        XCTAssertEqual(RTSClearanceStatus.complete.icon, "doc.badge.checkmark")
        XCTAssertEqual(RTSClearanceStatus.signed.icon, "signature")
        XCTAssertEqual(RTSClearanceStatus.coSigned.icon, "checkmark.seal")
    }

    // MARK: - IsLocked Tests

    func testRTSClearanceStatus_IsLocked() {
        XCTAssertFalse(RTSClearanceStatus.draft.isLocked)
        XCTAssertFalse(RTSClearanceStatus.complete.isLocked)
        XCTAssertTrue(RTSClearanceStatus.signed.isLocked)
        XCTAssertTrue(RTSClearanceStatus.coSigned.isLocked)
    }

    // MARK: - CaseIterable Tests

    func testRTSClearanceStatus_AllCases() {
        let allCases = RTSClearanceStatus.allCases
        XCTAssertEqual(allCases.count, 4)
    }
}

// MARK: - RTSClearance Model Tests

final class RTSClearanceModelTests: XCTestCase {

    // MARK: - Initialization Tests

    func testRTSClearance_Initialization() {
        let id = UUID()
        let protocolId = UUID()

        let clearance = RTSClearance(
            id: id,
            protocolId: protocolId,
            clearanceType: .phaseClearance,
            clearanceLevel: .yellow,
            assessmentSummary: "Patient met Phase 2 criteria",
            recommendations: "Progress to Phase 3"
        )

        XCTAssertEqual(clearance.id, id)
        XCTAssertEqual(clearance.protocolId, protocolId)
        XCTAssertEqual(clearance.clearanceType, .phaseClearance)
        XCTAssertEqual(clearance.clearanceLevel, .yellow)
        XCTAssertEqual(clearance.status, .draft)
        XCTAssertFalse(clearance.requiresPhysicianSignature)
        XCTAssertNil(clearance.signedBy)
        XCTAssertNil(clearance.signedAt)
        XCTAssertNil(clearance.coSignedBy)
        XCTAssertNil(clearance.coSignedAt)
    }

    // MARK: - Can Edit Tests

    func testRTSClearance_CanEdit() {
        let draftClearance = RTSClearance(
            protocolId: UUID(),
            clearanceType: .phaseClearance,
            clearanceLevel: .yellow,
            status: .draft,
            assessmentSummary: "Test",
            recommendations: "Test"
        )
        XCTAssertTrue(draftClearance.canEdit)

        let signedClearance = RTSClearance(
            protocolId: UUID(),
            clearanceType: .phaseClearance,
            clearanceLevel: .yellow,
            status: .signed,
            assessmentSummary: "Test",
            recommendations: "Test"
        )
        XCTAssertFalse(signedClearance.canEdit)
    }

    // MARK: - Can Sign Tests

    func testRTSClearance_CanSign() {
        let completeClearance = RTSClearance(
            protocolId: UUID(),
            clearanceType: .phaseClearance,
            clearanceLevel: .green,
            status: .complete,
            assessmentSummary: "Test",
            recommendations: "Test"
        )
        XCTAssertTrue(completeClearance.canSign)

        let draftClearance = RTSClearance(
            protocolId: UUID(),
            clearanceType: .phaseClearance,
            clearanceLevel: .green,
            status: .draft,
            assessmentSummary: "Test",
            recommendations: "Test"
        )
        XCTAssertFalse(draftClearance.canSign)
    }

    // MARK: - Can Co-Sign Tests

    func testRTSClearance_CanCoSign() {
        let signedClearanceRequiringCoSign = RTSClearance(
            protocolId: UUID(),
            clearanceType: .finalClearance,
            clearanceLevel: .green,
            status: .signed,
            assessmentSummary: "Test",
            recommendations: "Test",
            requiresPhysicianSignature: true,
            signedBy: UUID(),
            signedAt: Date()
        )
        XCTAssertTrue(signedClearanceRequiringCoSign.canCoSign)

        let signedClearanceNotRequiringCoSign = RTSClearance(
            protocolId: UUID(),
            clearanceType: .phaseClearance,
            clearanceLevel: .green,
            status: .signed,
            assessmentSummary: "Test",
            recommendations: "Test",
            requiresPhysicianSignature: false,
            signedBy: UUID(),
            signedAt: Date()
        )
        XCTAssertFalse(signedClearanceNotRequiringCoSign.canCoSign)
    }

    // MARK: - Is Fully Signed Tests

    func testRTSClearance_IsFullySigned() {
        // Fully signed without co-signature required
        let signedWithoutCoSignRequired = RTSClearance(
            protocolId: UUID(),
            clearanceType: .phaseClearance,
            clearanceLevel: .green,
            status: .signed,
            assessmentSummary: "Test",
            recommendations: "Test",
            requiresPhysicianSignature: false,
            signedBy: UUID(),
            signedAt: Date()
        )
        XCTAssertTrue(signedWithoutCoSignRequired.isFullySigned)

        // Fully signed with co-signature
        let coSignedClearance = RTSClearance(
            protocolId: UUID(),
            clearanceType: .finalClearance,
            clearanceLevel: .green,
            status: .coSigned,
            assessmentSummary: "Test",
            recommendations: "Test",
            requiresPhysicianSignature: true,
            signedBy: UUID(),
            signedAt: Date(),
            coSignedBy: UUID(),
            coSignedAt: Date()
        )
        XCTAssertTrue(coSignedClearance.isFullySigned)

        // Awaiting co-signature
        let awaitingCoSign = RTSClearance(
            protocolId: UUID(),
            clearanceType: .finalClearance,
            clearanceLevel: .green,
            status: .signed,
            assessmentSummary: "Test",
            recommendations: "Test",
            requiresPhysicianSignature: true,
            signedBy: UUID(),
            signedAt: Date()
        )
        XCTAssertFalse(awaitingCoSign.isFullySigned)
    }

    // MARK: - Signature Status Text Tests

    func testRTSClearance_SignatureStatusText() {
        let draft = RTSClearance(
            protocolId: UUID(),
            clearanceType: .phaseClearance,
            clearanceLevel: .yellow,
            status: .draft,
            assessmentSummary: "Test",
            recommendations: "Test"
        )
        XCTAssertEqual(draft.signatureStatusText, "Draft")

        let readyForSignature = RTSClearance(
            protocolId: UUID(),
            clearanceType: .phaseClearance,
            clearanceLevel: .yellow,
            status: .complete,
            assessmentSummary: "Test",
            recommendations: "Test"
        )
        XCTAssertEqual(readyForSignature.signatureStatusText, "Ready for Signature")

        let signed = RTSClearance(
            protocolId: UUID(),
            clearanceType: .phaseClearance,
            clearanceLevel: .green,
            status: .signed,
            assessmentSummary: "Test",
            recommendations: "Test",
            requiresPhysicianSignature: false,
            signedBy: UUID(),
            signedAt: Date()
        )
        XCTAssertEqual(signed.signatureStatusText, "Fully Signed")

        let awaitingCoSign = RTSClearance(
            protocolId: UUID(),
            clearanceType: .finalClearance,
            clearanceLevel: .green,
            status: .signed,
            assessmentSummary: "Test",
            recommendations: "Test",
            requiresPhysicianSignature: true,
            signedBy: UUID(),
            signedAt: Date()
        )
        XCTAssertEqual(awaitingCoSign.signatureStatusText, "Awaiting Co-Signature")

        let fullySigned = RTSClearance(
            protocolId: UUID(),
            clearanceType: .finalClearance,
            clearanceLevel: .green,
            status: .coSigned,
            assessmentSummary: "Test",
            recommendations: "Test",
            requiresPhysicianSignature: true,
            signedBy: UUID(),
            signedAt: Date(),
            coSignedBy: UUID(),
            coSignedAt: Date()
        )
        XCTAssertEqual(fullySigned.signatureStatusText, "Fully Signed")
    }
}

// MARK: - RTSClearanceInput Validation Tests

final class RTSClearanceInputValidationTests: XCTestCase {

    func testRTSClearanceInput_ValidationSuccess() throws {
        let input = RTSClearanceInput(
            protocolId: UUID().uuidString,
            clearanceType: "phase_clearance",
            clearanceLevel: "yellow",
            assessmentSummary: "Patient met criteria",
            recommendations: "Progress to next phase"
        )

        XCTAssertNoThrow(try input.validate())
    }

    func testRTSClearanceInput_ValidationFailure_MissingProtocolId() {
        let input = RTSClearanceInput(
            protocolId: nil,
            clearanceType: "phase_clearance",
            clearanceLevel: "yellow",
            assessmentSummary: "Test",
            recommendations: "Test"
        )

        XCTAssertThrowsError(try input.validate()) { error in
            guard case RTSClearanceError.invalidInput(let message) = error else {
                XCTFail("Expected RTSClearanceError.invalidInput")
                return
            }
            XCTAssertEqual(message, "Protocol ID is required")
        }
    }

    func testRTSClearanceInput_ValidationFailure_MissingClearanceType() {
        let input = RTSClearanceInput(
            protocolId: UUID().uuidString,
            clearanceType: nil,
            clearanceLevel: "yellow",
            assessmentSummary: "Test",
            recommendations: "Test"
        )

        XCTAssertThrowsError(try input.validate()) { error in
            guard case RTSClearanceError.invalidInput(let message) = error else {
                XCTFail("Expected RTSClearanceError.invalidInput")
                return
            }
            XCTAssertEqual(message, "Clearance type is required")
        }
    }

    func testRTSClearanceInput_ValidationFailure_MissingClearanceLevel() {
        let input = RTSClearanceInput(
            protocolId: UUID().uuidString,
            clearanceType: "phase_clearance",
            clearanceLevel: nil,
            assessmentSummary: "Test",
            recommendations: "Test"
        )

        XCTAssertThrowsError(try input.validate()) { error in
            guard case RTSClearanceError.invalidInput(let message) = error else {
                XCTFail("Expected RTSClearanceError.invalidInput")
                return
            }
            XCTAssertEqual(message, "Clearance level is required")
        }
    }

    func testRTSClearanceInput_ValidationFailure_EmptyAssessmentSummary() {
        let input = RTSClearanceInput(
            protocolId: UUID().uuidString,
            clearanceType: "phase_clearance",
            clearanceLevel: "yellow",
            assessmentSummary: "",
            recommendations: "Test"
        )

        XCTAssertThrowsError(try input.validate()) { error in
            guard case RTSClearanceError.invalidInput(let message) = error else {
                XCTFail("Expected RTSClearanceError.invalidInput")
                return
            }
            XCTAssertEqual(message, "Assessment summary is required")
        }
    }

    func testRTSClearanceInput_ValidationFailure_EmptyRecommendations() {
        let input = RTSClearanceInput(
            protocolId: UUID().uuidString,
            clearanceType: "phase_clearance",
            clearanceLevel: "yellow",
            assessmentSummary: "Test",
            recommendations: ""
        )

        XCTAssertThrowsError(try input.validate()) { error in
            guard case RTSClearanceError.invalidInput(let message) = error else {
                XCTFail("Expected RTSClearanceError.invalidInput")
                return
            }
            XCTAssertEqual(message, "Recommendations are required")
        }
    }
}

// MARK: - RTSRiskSeverity Tests

final class RTSRiskSeverityTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testRTSRiskSeverity_RawValues() {
        XCTAssertEqual(RTSRiskSeverity.low.rawValue, "low")
        XCTAssertEqual(RTSRiskSeverity.moderate.rawValue, "moderate")
        XCTAssertEqual(RTSRiskSeverity.high.rawValue, "high")
    }

    // MARK: - Display Name Tests

    func testRTSRiskSeverity_DisplayNames() {
        XCTAssertEqual(RTSRiskSeverity.low.displayName, "Low")
        XCTAssertEqual(RTSRiskSeverity.moderate.displayName, "Moderate")
        XCTAssertEqual(RTSRiskSeverity.high.displayName, "High")
    }

    // MARK: - Icon Tests

    func testRTSRiskSeverity_Icons() {
        XCTAssertEqual(RTSRiskSeverity.low.icon, "exclamationmark.circle")
        XCTAssertEqual(RTSRiskSeverity.moderate.icon, "exclamationmark.triangle")
        XCTAssertEqual(RTSRiskSeverity.high.icon, "exclamationmark.octagon.fill")
    }

    // MARK: - Weight Tests

    func testRTSRiskSeverity_Weights() {
        XCTAssertEqual(RTSRiskSeverity.low.weight, 0.25)
        XCTAssertEqual(RTSRiskSeverity.moderate.weight, 0.5)
        XCTAssertEqual(RTSRiskSeverity.high.weight, 1.0)
    }

    // MARK: - CaseIterable Tests

    func testRTSRiskSeverity_AllCases() {
        let allCases = RTSRiskSeverity.allCases
        XCTAssertEqual(allCases.count, 3)
    }
}

// MARK: - RTSRiskFactor Tests

final class RTSRiskFactorTests: XCTestCase {

    // MARK: - Initialization Tests

    func testRTSRiskFactor_Initialization() {
        let riskFactor = RTSRiskFactor(
            category: "Strength",
            name: "Quad weakness",
            severity: .moderate,
            notes: "LSI at 75%"
        )

        XCTAssertEqual(riskFactor.category, "Strength")
        XCTAssertEqual(riskFactor.name, "Quad weakness")
        XCTAssertEqual(riskFactor.severity, .moderate)
        XCTAssertEqual(riskFactor.notes, "LSI at 75%")
    }

    // MARK: - Identifiable Tests

    func testRTSRiskFactor_Identifiable() {
        let riskFactor = RTSRiskFactor(
            category: "Psychological",
            name: "Fear of reinjury",
            severity: .high
        )

        XCTAssertEqual(riskFactor.id, "PsychologicalFear of reinjury")
    }

    // MARK: - Codable Tests

    func testRTSRiskFactor_Decoding() throws {
        let json = """
        {
            "category": "Strength",
            "name": "Hamstring weakness",
            "severity": "moderate",
            "notes": "LSI at 78%"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let riskFactor = try decoder.decode(RTSRiskFactor.self, from: json)

        XCTAssertEqual(riskFactor.category, "Strength")
        XCTAssertEqual(riskFactor.name, "Hamstring weakness")
        XCTAssertEqual(riskFactor.severity, .moderate)
        XCTAssertEqual(riskFactor.notes, "LSI at 78%")
    }
}

// MARK: - RTSReadinessScore Tests

final class RTSReadinessScoreTests: XCTestCase {

    // MARK: - Initialization Tests

    func testRTSReadinessScore_Initialization() {
        let id = UUID()
        let protocolId = UUID()
        let phaseId = UUID()
        let recordedBy = UUID()

        let score = RTSReadinessScore(
            id: id,
            protocolId: protocolId,
            phaseId: phaseId,
            recordedBy: recordedBy,
            physicalScore: 85,
            functionalScore: 80,
            psychologicalScore: 75
        )

        XCTAssertEqual(score.id, id)
        XCTAssertEqual(score.protocolId, protocolId)
        XCTAssertEqual(score.phaseId, phaseId)
        XCTAssertEqual(score.recordedBy, recordedBy)
        XCTAssertEqual(score.physicalScore, 85)
        XCTAssertEqual(score.functionalScore, 80)
        XCTAssertEqual(score.psychologicalScore, 75)
    }

    // MARK: - Overall Score Calculation Tests

    func testRTSReadinessScore_CalculateOverall() {
        // Physical 40%, Functional 40%, Psychological 20%
        let overall = RTSReadinessScore.calculateOverall(
            physical: 80,
            functional: 80,
            psychological: 80
        )

        XCTAssertEqual(overall, 80.0)
    }

    func testRTSReadinessScore_CalculateOverall_DifferentScores() {
        let overall = RTSReadinessScore.calculateOverall(
            physical: 100,
            functional: 100,
            psychological: 50
        )

        // (100 * 0.4) + (100 * 0.4) + (50 * 0.2) = 40 + 40 + 10 = 90
        XCTAssertEqual(overall, 90.0)
    }

    func testRTSReadinessScore_AutoCalculatesOverall() {
        let score = RTSReadinessScore(
            protocolId: UUID(),
            phaseId: UUID(),
            recordedBy: UUID(),
            physicalScore: 90,
            functionalScore: 85,
            psychologicalScore: 80
        )

        // (90 * 0.4) + (85 * 0.4) + (80 * 0.2) = 36 + 34 + 16 = 86
        XCTAssertEqual(score.overallScore, 86.0)
    }

    // MARK: - Traffic Light Tests

    func testRTSReadinessScore_AutoDeterminesTrafficLight_Green() {
        let score = RTSReadinessScore(
            protocolId: UUID(),
            phaseId: UUID(),
            recordedBy: UUID(),
            physicalScore: 90,
            functionalScore: 90,
            psychologicalScore: 90
        )

        XCTAssertEqual(score.trafficLight, .green)
    }

    func testRTSReadinessScore_AutoDeterminesTrafficLight_Yellow() {
        let score = RTSReadinessScore(
            protocolId: UUID(),
            phaseId: UUID(),
            recordedBy: UUID(),
            physicalScore: 75,
            functionalScore: 75,
            psychologicalScore: 75
        )

        XCTAssertEqual(score.trafficLight, .yellow)
    }

    func testRTSReadinessScore_AutoDeterminesTrafficLight_Red() {
        let score = RTSReadinessScore(
            protocolId: UUID(),
            phaseId: UUID(),
            recordedBy: UUID(),
            physicalScore: 50,
            functionalScore: 50,
            psychologicalScore: 50
        )

        XCTAssertEqual(score.trafficLight, .red)
    }

    // MARK: - Risk Factor Tests

    func testRTSReadinessScore_HasHighRisk() {
        let scoreWithHighRisk = RTSReadinessScore(
            protocolId: UUID(),
            phaseId: UUID(),
            recordedBy: UUID(),
            physicalScore: 60,
            functionalScore: 60,
            psychologicalScore: 60,
            riskFactors: [
                RTSRiskFactor(category: "Pain", name: "Persistent pain", severity: .high)
            ]
        )

        XCTAssertTrue(scoreWithHighRisk.hasHighRisk)

        let scoreWithModerateRisk = RTSReadinessScore(
            protocolId: UUID(),
            phaseId: UUID(),
            recordedBy: UUID(),
            physicalScore: 70,
            functionalScore: 70,
            psychologicalScore: 70,
            riskFactors: [
                RTSRiskFactor(category: "Strength", name: "Weakness", severity: .moderate)
            ]
        )

        XCTAssertFalse(scoreWithModerateRisk.hasHighRisk)
    }

    func testRTSReadinessScore_HasModerateOrHigherRisk() {
        let scoreWithModerateRisk = RTSReadinessScore(
            protocolId: UUID(),
            phaseId: UUID(),
            recordedBy: UUID(),
            physicalScore: 70,
            functionalScore: 70,
            psychologicalScore: 70,
            riskFactors: [
                RTSRiskFactor(category: "Strength", name: "Weakness", severity: .moderate)
            ]
        )

        XCTAssertTrue(scoreWithModerateRisk.hasModerateOrHigherRisk)

        let scoreWithLowRisk = RTSReadinessScore(
            protocolId: UUID(),
            phaseId: UUID(),
            recordedBy: UUID(),
            physicalScore: 80,
            functionalScore: 80,
            psychologicalScore: 80,
            riskFactors: [
                RTSRiskFactor(category: "Minor", name: "Minor issue", severity: .low)
            ]
        )

        XCTAssertFalse(scoreWithLowRisk.hasModerateOrHigherRisk)
    }

    func testRTSReadinessScore_RiskFactorCounts() {
        let score = RTSReadinessScore(
            protocolId: UUID(),
            phaseId: UUID(),
            recordedBy: UUID(),
            physicalScore: 60,
            functionalScore: 60,
            psychologicalScore: 60,
            riskFactors: [
                RTSRiskFactor(category: "A", name: "1", severity: .high),
                RTSRiskFactor(category: "B", name: "2", severity: .high),
                RTSRiskFactor(category: "C", name: "3", severity: .moderate),
                RTSRiskFactor(category: "D", name: "4", severity: .low),
                RTSRiskFactor(category: "E", name: "5", severity: .low)
            ]
        )

        let counts = score.riskFactorCounts
        XCTAssertEqual(counts.high, 2)
        XCTAssertEqual(counts.moderate, 1)
        XCTAssertEqual(counts.low, 2)
    }

    // MARK: - Percentage String Tests

    func testRTSReadinessScore_PercentageStrings() {
        let score = RTSReadinessScore(
            protocolId: UUID(),
            phaseId: UUID(),
            recordedBy: UUID(),
            physicalScore: 85,
            functionalScore: 80,
            psychologicalScore: 75
        )

        XCTAssertEqual(score.physicalPercentage, "85%")
        XCTAssertEqual(score.functionalPercentage, "80%")
        XCTAssertEqual(score.psychologicalPercentage, "75%")
    }
}

// MARK: - RTSReadinessScoreInput Tests

final class RTSReadinessScoreInputTests: XCTestCase {

    func testRTSReadinessScoreInput_ValidationSuccess() throws {
        let input = RTSReadinessScoreInput(
            protocolId: UUID().uuidString,
            phaseId: UUID().uuidString,
            recordedBy: UUID().uuidString,
            physicalScore: 85,
            functionalScore: 80,
            psychologicalScore: 75
        )

        XCTAssertNoThrow(try input.validate())
    }

    func testRTSReadinessScoreInput_ValidationFailure_MissingProtocolId() {
        let input = RTSReadinessScoreInput(
            protocolId: nil,
            phaseId: UUID().uuidString,
            recordedBy: UUID().uuidString
        )

        XCTAssertThrowsError(try input.validate()) { error in
            guard case RTSReadinessError.invalidInput(let message) = error else {
                XCTFail("Expected RTSReadinessError.invalidInput")
                return
            }
            XCTAssertEqual(message, "Protocol ID is required")
        }
    }

    func testRTSReadinessScoreInput_ValidationFailure_InvalidPhysicalScore() {
        let input = RTSReadinessScoreInput(
            protocolId: UUID().uuidString,
            phaseId: UUID().uuidString,
            recordedBy: UUID().uuidString,
            physicalScore: 150  // Invalid: > 100
        )

        XCTAssertThrowsError(try input.validate()) { error in
            guard case RTSReadinessError.invalidInput(let message) = error else {
                XCTFail("Expected RTSReadinessError.invalidInput")
                return
            }
            XCTAssertEqual(message, "Physical score must be 0-100")
        }
    }

    func testRTSReadinessScoreInput_ValidationFailure_NegativeFunctionalScore() {
        let input = RTSReadinessScoreInput(
            protocolId: UUID().uuidString,
            phaseId: UUID().uuidString,
            recordedBy: UUID().uuidString,
            functionalScore: -10  // Invalid: < 0
        )

        XCTAssertThrowsError(try input.validate()) { error in
            guard case RTSReadinessError.invalidInput(let message) = error else {
                XCTFail("Expected RTSReadinessError.invalidInput")
                return
            }
            XCTAssertEqual(message, "Functional score must be 0-100")
        }
    }

    func testRTSReadinessScoreInput_CalculateDerivedFields() {
        var input = RTSReadinessScoreInput(
            protocolId: UUID().uuidString,
            phaseId: UUID().uuidString,
            recordedBy: UUID().uuidString,
            physicalScore: 90,
            functionalScore: 85,
            psychologicalScore: 80
        )

        input.calculateDerivedFields()

        // (90 * 0.4) + (85 * 0.4) + (80 * 0.2) = 36 + 34 + 16 = 86
        XCTAssertEqual(input.overallScore, 86.0)
        XCTAssertEqual(input.trafficLight, "green")
    }

    func testRTSReadinessScoreInput_CalculateDerivedFields_MissingScores() {
        var input = RTSReadinessScoreInput(
            protocolId: UUID().uuidString,
            phaseId: UUID().uuidString,
            recordedBy: UUID().uuidString,
            physicalScore: 90
            // Missing functional and psychological
        )

        input.calculateDerivedFields()

        // Should not calculate if any scores missing
        XCTAssertNil(input.overallScore)
        XCTAssertNil(input.trafficLight)
    }
}

// MARK: - RTSReadinessTrend Tests

final class RTSReadinessTrendTests: XCTestCase {

    func testRTSReadinessTrendDirection_DisplayNames() {
        XCTAssertEqual(RTSReadinessTrendDirection.improving.displayName, "Improving")
        XCTAssertEqual(RTSReadinessTrendDirection.stable.displayName, "Stable")
        XCTAssertEqual(RTSReadinessTrendDirection.declining.displayName, "Declining")
    }

    func testRTSReadinessTrendDirection_Icons() {
        XCTAssertEqual(RTSReadinessTrendDirection.improving.icon, "arrow.up.right")
        XCTAssertEqual(RTSReadinessTrendDirection.stable.icon, "arrow.right")
        XCTAssertEqual(RTSReadinessTrendDirection.declining.icon, "arrow.down.right")
    }
}

// MARK: - RTSTrafficLight Tests

final class RTSTrafficLightTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testRTSTrafficLight_RawValues() {
        XCTAssertEqual(RTSTrafficLight.green.rawValue, "green")
        XCTAssertEqual(RTSTrafficLight.yellow.rawValue, "yellow")
        XCTAssertEqual(RTSTrafficLight.red.rawValue, "red")
    }

    // MARK: - Display Name Tests

    func testRTSTrafficLight_DisplayNames() {
        XCTAssertEqual(RTSTrafficLight.green.displayName, "Cleared")
        XCTAssertEqual(RTSTrafficLight.yellow.displayName, "Caution")
        XCTAssertEqual(RTSTrafficLight.red.displayName, "Restricted")
    }

    // MARK: - Description Tests

    func testRTSTrafficLight_Descriptions() {
        XCTAssertFalse(RTSTrafficLight.green.description.isEmpty)
        XCTAssertFalse(RTSTrafficLight.yellow.description.isEmpty)
        XCTAssertFalse(RTSTrafficLight.red.description.isEmpty)
    }

    // MARK: - Icon Tests

    func testRTSTrafficLight_Icons() {
        XCTAssertEqual(RTSTrafficLight.green.icon, "checkmark.circle.fill")
        XCTAssertEqual(RTSTrafficLight.yellow.icon, "exclamationmark.triangle.fill")
        XCTAssertEqual(RTSTrafficLight.red.icon, "xmark.octagon.fill")
    }

    // MARK: - Score Threshold Tests

    func testRTSTrafficLight_MinimumScores() {
        XCTAssertEqual(RTSTrafficLight.green.minimumScore, 80)
        XCTAssertEqual(RTSTrafficLight.yellow.minimumScore, 60)
        XCTAssertEqual(RTSTrafficLight.red.minimumScore, 0)
    }

    func testRTSTrafficLight_MaximumScores() {
        XCTAssertEqual(RTSTrafficLight.green.maximumScore, 100)
        XCTAssertEqual(RTSTrafficLight.yellow.maximumScore, 79.99)
        XCTAssertEqual(RTSTrafficLight.red.maximumScore, 59.99)
    }

    // MARK: - From Score Tests

    func testRTSTrafficLight_FromScore_Green() {
        XCTAssertEqual(RTSTrafficLight.from(score: 80), .green)
        XCTAssertEqual(RTSTrafficLight.from(score: 90), .green)
        XCTAssertEqual(RTSTrafficLight.from(score: 100), .green)
    }

    func testRTSTrafficLight_FromScore_Yellow() {
        XCTAssertEqual(RTSTrafficLight.from(score: 60), .yellow)
        XCTAssertEqual(RTSTrafficLight.from(score: 70), .yellow)
        XCTAssertEqual(RTSTrafficLight.from(score: 79), .yellow)
    }

    func testRTSTrafficLight_FromScore_Red() {
        XCTAssertEqual(RTSTrafficLight.from(score: 0), .red)
        XCTAssertEqual(RTSTrafficLight.from(score: 30), .red)
        XCTAssertEqual(RTSTrafficLight.from(score: 59), .red)
    }

    func testRTSTrafficLight_FromScore_EdgeCases() {
        XCTAssertEqual(RTSTrafficLight.from(score: 79.99), .yellow)
        XCTAssertEqual(RTSTrafficLight.from(score: 59.99), .red)
    }

    // MARK: - Contains Score Tests

    func testRTSTrafficLight_ContainsScore() {
        XCTAssertTrue(RTSTrafficLight.green.contains(score: 85))
        XCTAssertFalse(RTSTrafficLight.green.contains(score: 79))

        XCTAssertTrue(RTSTrafficLight.yellow.contains(score: 70))
        XCTAssertFalse(RTSTrafficLight.yellow.contains(score: 59))
        XCTAssertFalse(RTSTrafficLight.yellow.contains(score: 80))

        XCTAssertTrue(RTSTrafficLight.red.contains(score: 40))
        XCTAssertFalse(RTSTrafficLight.red.contains(score: 60))
    }

    // MARK: - CaseIterable Tests

    func testRTSTrafficLight_AllCases() {
        let allCases = RTSTrafficLight.allCases
        XCTAssertEqual(allCases.count, 3)
    }
}

// MARK: - RTSSport Tests

final class RTSSportTests: XCTestCase {

    // MARK: - Initialization Tests

    func testRTSSport_Initialization() {
        let id = UUID()
        let sport = RTSSport(
            id: id,
            name: "Baseball",
            category: .throwing
        )

        XCTAssertEqual(sport.id, id)
        XCTAssertEqual(sport.name, "Baseball")
        XCTAssertEqual(sport.category, .throwing)
        XCTAssertTrue(sport.defaultPhases.isEmpty)
    }

    func testRTSSport_WithPhaseTemplates() {
        let templates = [
            RTSPhaseTemplate(
                phaseNumber: 1,
                phaseName: "Phase 1",
                activityLevel: .red,
                description: "Initial phase",
                targetDurationWeeks: 2
            ),
            RTSPhaseTemplate(
                phaseNumber: 2,
                phaseName: "Phase 2",
                activityLevel: .yellow,
                description: "Progression phase",
                targetDurationWeeks: 3
            )
        ]

        let sport = RTSSport(
            name: "Soccer",
            category: .cutting,
            defaultPhases: templates
        )

        XCTAssertEqual(sport.defaultPhases.count, 2)
        XCTAssertEqual(sport.defaultPhases[0].phaseName, "Phase 1")
        XCTAssertEqual(sport.defaultPhases[1].phaseName, "Phase 2")
    }
}

// MARK: - RTSSportCategory Tests

final class RTSSportCategoryTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testRTSSportCategory_RawValues() {
        XCTAssertEqual(RTSSportCategory.throwing.rawValue, "throwing")
        XCTAssertEqual(RTSSportCategory.running.rawValue, "running")
        XCTAssertEqual(RTSSportCategory.cutting.rawValue, "cutting")
    }

    // MARK: - Display Name Tests

    func testRTSSportCategory_DisplayNames() {
        XCTAssertEqual(RTSSportCategory.throwing.displayName, "Throwing Sports")
        XCTAssertEqual(RTSSportCategory.running.displayName, "Running Sports")
        XCTAssertEqual(RTSSportCategory.cutting.displayName, "Cutting/Pivoting Sports")
    }

    // MARK: - Icon Tests

    func testRTSSportCategory_Icons() {
        XCTAssertEqual(RTSSportCategory.throwing.icon, "baseball.fill")
        XCTAssertEqual(RTSSportCategory.running.icon, "figure.run")
        XCTAssertEqual(RTSSportCategory.cutting.icon, "arrow.triangle.branch")
    }

    // MARK: - CaseIterable Tests

    func testRTSSportCategory_AllCases() {
        let allCases = RTSSportCategory.allCases
        XCTAssertEqual(allCases.count, 3)
    }
}

// MARK: - RTSPhaseTemplate Tests

final class RTSPhaseTemplateTests: XCTestCase {

    func testRTSPhaseTemplate_Initialization() {
        let template = RTSPhaseTemplate(
            phaseNumber: 1,
            phaseName: "Protected Motion",
            activityLevel: .red,
            description: "Focus on pain-free range of motion",
            targetDurationWeeks: 2
        )

        XCTAssertEqual(template.phaseNumber, 1)
        XCTAssertEqual(template.phaseName, "Protected Motion")
        XCTAssertEqual(template.activityLevel, .red)
        XCTAssertEqual(template.description, "Focus on pain-free range of motion")
        XCTAssertEqual(template.targetDurationWeeks, 2)
    }

    func testRTSPhaseTemplate_Identifiable() {
        let template = RTSPhaseTemplate(
            phaseNumber: 2,
            phaseName: "Light Activity",
            activityLevel: .yellow,
            description: "Test"
        )

        XCTAssertEqual(template.id, "2-Light Activity")
    }

    func testRTSPhaseTemplate_NilTargetDuration() {
        let template = RTSPhaseTemplate(
            phaseNumber: 3,
            phaseName: "Return to Play",
            activityLevel: .green,
            description: "Full activity clearance"
        )

        XCTAssertNil(template.targetDurationWeeks)
    }
}

// MARK: - Sample Data Tests

#if DEBUG
final class RTSSampleDataTests: XCTestCase {

    func testRTSProtocol_SampleData() {
        let sample = RTSProtocol.sample

        XCTAssertEqual(sample.injuryType, "ACL Reconstruction")
        XCTAssertEqual(sample.status, .active)
        XCTAssertNotNil(sample.surgeryDate)
    }

    func testRTSProtocol_CompletedSampleData() {
        let sample = RTSProtocol.completedSample

        XCTAssertEqual(sample.status, .completed)
        XCTAssertNotNil(sample.actualReturnDate)
    }

    func testRTSPhase_ActiveSampleData() {
        let sample = RTSPhase.activeSample

        XCTAssertEqual(sample.phaseName, "Light Tossing")
        XCTAssertEqual(sample.activityLevel, .yellow)
        XCTAssertTrue(sample.isActive)
    }

    func testRTSPhase_CompletedSampleData() {
        let sample = RTSPhase.completedSample

        XCTAssertTrue(sample.isCompleted)
    }

    func testRTSPhase_PendingSampleData() {
        let sample = RTSPhase.pendingSample

        XCTAssertTrue(sample.isPending)
    }

    func testRTSMilestoneCriterion_StrengthSampleData() {
        let sample = RTSMilestoneCriterion.strengthSample

        XCTAssertEqual(sample.category, .strength)
        XCTAssertEqual(sample.name, "Quad LSI")
        XCTAssertTrue(sample.isRequired)
        XCTAssertNotNil(sample.latestResult)
        XCTAssertTrue(sample.isPassed)
    }

    func testRTSMilestoneCriterion_FunctionalSampleData() {
        let sample = RTSMilestoneCriterion.functionalSample

        XCTAssertEqual(sample.category, .functional)
        XCTAssertNil(sample.latestResult)
        XCTAssertFalse(sample.hasBeenTested)
    }

    func testRTSMilestoneCriterion_PainSampleData() {
        let sample = RTSMilestoneCriterion.painSample

        XCTAssertEqual(sample.category, .pain)
        XCTAssertEqual(sample.comparisonOperator, .lessThanOrEqual)
        XCTAssertNotNil(sample.latestResult)
        XCTAssertFalse(sample.isPassed)
    }

    func testRTSClearance_DraftSampleData() {
        let sample = RTSClearance.draftSample

        XCTAssertEqual(sample.status, .draft)
        XCTAssertTrue(sample.canEdit)
        XCTAssertFalse(sample.canSign)
    }

    func testRTSClearance_SignedSampleData() {
        let sample = RTSClearance.signedSample

        XCTAssertEqual(sample.status, .signed)
        XCTAssertTrue(sample.isSigned)
        XCTAssertTrue(sample.requiresPhysicianSignature)
        XCTAssertFalse(sample.isFullySigned)
    }

    func testRTSClearance_CoSignedSampleData() {
        let sample = RTSClearance.coSignedSample

        XCTAssertEqual(sample.status, .coSigned)
        XCTAssertTrue(sample.isFullySigned)
    }

    func testRTSReadinessScore_GreenSampleData() {
        let sample = RTSReadinessScore.greenSample

        XCTAssertEqual(sample.trafficLight, .green)
        XCTAssertGreaterThanOrEqual(sample.overallScore, 80)
    }

    func testRTSReadinessScore_YellowSampleData() {
        let sample = RTSReadinessScore.yellowSample

        XCTAssertEqual(sample.trafficLight, .yellow)
        XCTAssertGreaterThanOrEqual(sample.overallScore, 60)
        XCTAssertLessThan(sample.overallScore, 80)
    }

    func testRTSReadinessScore_RedSampleData() {
        let sample = RTSReadinessScore.redSample

        XCTAssertEqual(sample.trafficLight, .red)
        XCTAssertLessThan(sample.overallScore, 60)
        XCTAssertTrue(sample.hasHighRisk)
    }

    func testRTSSport_BaseballSampleData() {
        let sample = RTSSport.baseballSample

        XCTAssertEqual(sample.name, "Baseball")
        XCTAssertEqual(sample.category, .throwing)
        XCTAssertEqual(sample.defaultPhases.count, 4)
    }

    func testRTSSport_SoccerSampleData() {
        let sample = RTSSport.soccerSample

        XCTAssertEqual(sample.name, "Soccer")
        XCTAssertEqual(sample.category, .cutting)
        XCTAssertEqual(sample.defaultPhases.count, 4)
    }
}
#endif

// MARK: - Edge Case Tests

final class RTSServiceEdgeCaseTests: XCTestCase {

    func testRTSTrafficLight_BoundaryScores() {
        // Exactly at boundaries
        XCTAssertEqual(RTSTrafficLight.from(score: 80.0), .green)
        XCTAssertEqual(RTSTrafficLight.from(score: 60.0), .yellow)
        XCTAssertEqual(RTSTrafficLight.from(score: 0.0), .red)
    }

    func testRTSTrafficLight_ExtremeScores() {
        // Score below 0
        XCTAssertEqual(RTSTrafficLight.from(score: -10), .red)

        // Score above 100
        XCTAssertEqual(RTSTrafficLight.from(score: 110), .green)
    }

    func testRTSComparisonOperator_EdgeValues() {
        // Equal comparison with very close values
        let op = RTSComparisonOperator.equal
        XCTAssertTrue(op.evaluate(value: 90.0001, target: 90.0002))  // Within tolerance
        XCTAssertFalse(op.evaluate(value: 90.01, target: 90.02))  // Outside tolerance
    }

    func testRTSReadinessScore_ZeroScores() {
        let score = RTSReadinessScore(
            protocolId: UUID(),
            phaseId: UUID(),
            recordedBy: UUID(),
            physicalScore: 0,
            functionalScore: 0,
            psychologicalScore: 0
        )

        XCTAssertEqual(score.overallScore, 0)
        XCTAssertEqual(score.trafficLight, .red)
    }

    func testRTSReadinessScore_MaxScores() {
        let score = RTSReadinessScore(
            protocolId: UUID(),
            phaseId: UUID(),
            recordedBy: UUID(),
            physicalScore: 100,
            functionalScore: 100,
            psychologicalScore: 100
        )

        XCTAssertEqual(score.overallScore, 100)
        XCTAssertEqual(score.trafficLight, .green)
    }

    func testRTSCriteriaSummary_AllZeros() {
        let summary = RTSCriteriaSummary(
            totalCriteria: 0,
            passedCriteria: 0,
            requiredPassed: 0,
            requiredTotal: 0
        )

        XCTAssertEqual(summary.totalCriteria, 0)
        XCTAssertEqual(summary.passedCriteria, 0)
    }

    func testRTSPhase_DaysInPhase_SameDay() {
        let now = Date()
        let phase = RTSPhase(
            protocolId: UUID(),
            phaseNumber: 1,
            phaseName: "Test",
            activityLevel: .yellow,
            description: "Test phase",
            startedAt: now,
            completedAt: nil
        )

        XCTAssertEqual(phase.daysInPhase, 0)
    }

    func testRTSProtocol_ProgressPercentage_PastTargetDate() {
        let injuryDate = Calendar.current.date(byAdding: .month, value: -12, to: Date())!
        let targetDate = Calendar.current.date(byAdding: .month, value: -3, to: Date())!

        let rtsProtocol = RTSProtocol(
            patientId: UUID(),
            therapistId: UUID(),
            sportId: UUID(),
            injuryType: "Test",
            injuryDate: injuryDate,
            targetReturnDate: targetDate
        )

        // Progress should be capped at 1.0
        XCTAssertEqual(rtsProtocol.progressPercentage, 1.0)
    }

    func testRTSProtocol_DaysUntilTarget_Negative() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let rtsProtocol = RTSProtocol(
            patientId: UUID(),
            therapistId: UUID(),
            sportId: UUID(),
            injuryType: "Test",
            injuryDate: Calendar.current.date(byAdding: .month, value: -6, to: Date())!,
            targetReturnDate: pastDate
        )

        XCTAssertLessThan(rtsProtocol.daysUntilTarget, 0)
    }
}
