//
//  RTSProtocolViewModelTests.swift
//  PTPerformanceTests
//
//  Comprehensive unit tests for RTSProtocolViewModel
//  Tests protocol lifecycle, phase management, clearances, and computed properties
//

import XCTest
import SwiftUI
@testable import PTPerformance

// MARK: - RTSProtocolViewModel Tests

@MainActor
final class RTSProtocolViewModelTests: XCTestCase {

    var sut: RTSProtocolViewModel!

    override func setUp() {
        super.setUp()
        sut = RTSProtocolViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_ProtocolsIsEmpty() {
        XCTAssertTrue(sut.protocols.isEmpty)
    }

    func testInitialState_CurrentProtocolIsNil() {
        XCTAssertNil(sut.currentProtocol)
    }

    func testInitialState_PhasesIsEmpty() {
        XCTAssertTrue(sut.phases.isEmpty)
    }

    func testInitialState_CurrentPhaseIsNil() {
        XCTAssertNil(sut.currentPhase)
    }

    func testInitialState_SportsIsEmpty() {
        XCTAssertTrue(sut.sports.isEmpty)
    }

    func testInitialState_ClearancesIsEmpty() {
        XCTAssertTrue(sut.clearances.isEmpty)
    }

    func testInitialState_ReadinessScoresIsEmpty() {
        XCTAssertTrue(sut.readinessScores.isEmpty)
    }

    func testInitialState_LatestReadinessIsNil() {
        XCTAssertNil(sut.latestReadiness)
    }

    func testInitialState_RecentActivityIsEmpty() {
        XCTAssertTrue(sut.recentActivity.isEmpty)
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading)
    }

    func testInitialState_IsSavingIsFalse() {
        XCTAssertFalse(sut.isSaving)
    }

    func testInitialState_ErrorMessageIsNil() {
        XCTAssertNil(sut.errorMessage)
    }

    func testInitialState_SuccessMessageIsNil() {
        XCTAssertNil(sut.successMessage)
    }

    // MARK: - Form State Tests

    func testInitialState_SelectedSportIsNil() {
        XCTAssertNil(sut.selectedSport)
    }

    func testInitialState_InjuryTypeIsEmpty() {
        XCTAssertEqual(sut.injuryType, "")
    }

    func testInitialState_SurgeryDateIsNil() {
        XCTAssertNil(sut.surgeryDate)
    }

    func testInitialState_NotesIsEmpty() {
        XCTAssertEqual(sut.notes, "")
    }
}

// MARK: - Computed Properties Tests - Phase Status

@MainActor
final class RTSProtocolViewModelPhaseStatusTests: XCTestCase {

    var sut: RTSProtocolViewModel!

    override func setUp() {
        super.setUp()
        sut = RTSProtocolViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - activePhases Tests

    func testActivePhases_WhenNoPhases_ReturnsEmpty() {
        XCTAssertTrue(sut.activePhases.isEmpty)
    }

    func testActivePhases_FiltersCorrectly() {
        let protocolId = UUID()

        let activePhase = RTSPhase(
            protocolId: protocolId,
            phaseNumber: 2,
            phaseName: "Active Phase",
            activityLevel: .yellow,
            description: "Currently active",
            startedAt: Date(),
            completedAt: nil
        )

        let completedPhase = RTSPhase(
            protocolId: protocolId,
            phaseNumber: 1,
            phaseName: "Completed Phase",
            activityLevel: .red,
            description: "Already done",
            startedAt: Calendar.current.date(byAdding: .day, value: -14, to: Date()),
            completedAt: Calendar.current.date(byAdding: .day, value: -7, to: Date())
        )

        let pendingPhase = RTSPhase(
            protocolId: protocolId,
            phaseNumber: 3,
            phaseName: "Pending Phase",
            activityLevel: .green,
            description: "Not started",
            startedAt: nil,
            completedAt: nil
        )

        sut.phases = [completedPhase, activePhase, pendingPhase]

        XCTAssertEqual(sut.activePhases.count, 1)
        XCTAssertEqual(sut.activePhases.first?.phaseName, "Active Phase")
    }

    func testActivePhases_MultipleActivePhases() {
        let protocolId = UUID()

        let active1 = RTSPhase(
            protocolId: protocolId,
            phaseNumber: 1,
            phaseName: "Active 1",
            activityLevel: .yellow,
            description: "Active",
            startedAt: Date(),
            completedAt: nil
        )

        let active2 = RTSPhase(
            protocolId: protocolId,
            phaseNumber: 2,
            phaseName: "Active 2",
            activityLevel: .yellow,
            description: "Also active",
            startedAt: Date(),
            completedAt: nil
        )

        sut.phases = [active1, active2]

        XCTAssertEqual(sut.activePhases.count, 2)
    }

    // MARK: - completedPhases Tests

    func testCompletedPhases_WhenNoPhases_ReturnsEmpty() {
        XCTAssertTrue(sut.completedPhases.isEmpty)
    }

    func testCompletedPhases_FiltersCorrectly() {
        let protocolId = UUID()

        let completed1 = RTSPhase(
            protocolId: protocolId,
            phaseNumber: 1,
            phaseName: "Completed 1",
            activityLevel: .red,
            description: "Done",
            startedAt: Calendar.current.date(byAdding: .day, value: -21, to: Date()),
            completedAt: Calendar.current.date(byAdding: .day, value: -14, to: Date())
        )

        let completed2 = RTSPhase(
            protocolId: protocolId,
            phaseNumber: 2,
            phaseName: "Completed 2",
            activityLevel: .yellow,
            description: "Also done",
            startedAt: Calendar.current.date(byAdding: .day, value: -14, to: Date()),
            completedAt: Calendar.current.date(byAdding: .day, value: -7, to: Date())
        )

        let active = RTSPhase(
            protocolId: protocolId,
            phaseNumber: 3,
            phaseName: "Active",
            activityLevel: .yellow,
            description: "Currently active",
            startedAt: Date(),
            completedAt: nil
        )

        sut.phases = [completed1, completed2, active]

        XCTAssertEqual(sut.completedPhases.count, 2)
    }

    // MARK: - pendingPhases Tests

    func testPendingPhases_WhenNoPhases_ReturnsEmpty() {
        XCTAssertTrue(sut.pendingPhases.isEmpty)
    }

    func testPendingPhases_FiltersCorrectly() {
        let protocolId = UUID()

        let pending1 = RTSPhase(
            protocolId: protocolId,
            phaseNumber: 3,
            phaseName: "Pending 1",
            activityLevel: .green,
            description: "Not started",
            startedAt: nil,
            completedAt: nil
        )

        let pending2 = RTSPhase(
            protocolId: protocolId,
            phaseNumber: 4,
            phaseName: "Pending 2",
            activityLevel: .green,
            description: "Also not started",
            startedAt: nil,
            completedAt: nil
        )

        let active = RTSPhase(
            protocolId: protocolId,
            phaseNumber: 2,
            phaseName: "Active",
            activityLevel: .yellow,
            description: "Active",
            startedAt: Date(),
            completedAt: nil
        )

        sut.phases = [active, pending1, pending2]

        XCTAssertEqual(sut.pendingPhases.count, 2)
    }

    // MARK: - overallProgress Tests

    func testOverallProgress_WhenNoPhases_ReturnsZero() {
        XCTAssertEqual(sut.overallProgress, 0)
    }

    func testOverallProgress_WhenNoCompleted_ReturnsZero() {
        let protocolId = UUID()
        sut.phases = [
            RTSPhase(protocolId: protocolId, phaseNumber: 1, phaseName: "P1", activityLevel: .red, description: "", startedAt: Date(), completedAt: nil),
            RTSPhase(protocolId: protocolId, phaseNumber: 2, phaseName: "P2", activityLevel: .yellow, description: "", startedAt: nil, completedAt: nil)
        ]

        XCTAssertEqual(sut.overallProgress, 0)
    }

    func testOverallProgress_WhenHalfCompleted_ReturnsFiftyPercent() {
        let protocolId = UUID()
        sut.phases = [
            RTSPhase(protocolId: protocolId, phaseNumber: 1, phaseName: "P1", activityLevel: .red, description: "", startedAt: Date(), completedAt: Date()),
            RTSPhase(protocolId: protocolId, phaseNumber: 2, phaseName: "P2", activityLevel: .yellow, description: "", startedAt: nil, completedAt: nil)
        ]

        XCTAssertEqual(sut.overallProgress, 0.5, accuracy: 0.001)
    }

    func testOverallProgress_WhenAllCompleted_ReturnsOne() {
        let protocolId = UUID()
        sut.phases = [
            RTSPhase(protocolId: protocolId, phaseNumber: 1, phaseName: "P1", activityLevel: .red, description: "", startedAt: Date(), completedAt: Date()),
            RTSPhase(protocolId: protocolId, phaseNumber: 2, phaseName: "P2", activityLevel: .yellow, description: "", startedAt: Date(), completedAt: Date()),
            RTSPhase(protocolId: protocolId, phaseNumber: 3, phaseName: "P3", activityLevel: .green, description: "", startedAt: Date(), completedAt: Date())
        ]

        XCTAssertEqual(sut.overallProgress, 1.0, accuracy: 0.001)
    }
}

// MARK: - Traffic Light and Readiness Tests

@MainActor
final class RTSProtocolViewModelReadinessTests: XCTestCase {

    var sut: RTSProtocolViewModel!

    override func setUp() {
        super.setUp()
        sut = RTSProtocolViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testCurrentTrafficLight_WhenNoReadiness_ReturnsRed() {
        XCTAssertNil(sut.latestReadiness)
        XCTAssertEqual(sut.currentTrafficLight, .red)
    }

    func testCurrentTrafficLight_WhenGreenReadiness_ReturnsGreen() {
        sut.latestReadiness = RTSReadinessScore(
            protocolId: UUID(),
            phaseId: UUID(),
            recordedBy: UUID(),
            physicalScore: 90,
            functionalScore: 90,
            psychologicalScore: 90
        )

        XCTAssertEqual(sut.currentTrafficLight, .green)
    }

    func testCurrentTrafficLight_WhenYellowReadiness_ReturnsYellow() {
        sut.latestReadiness = RTSReadinessScore(
            protocolId: UUID(),
            phaseId: UUID(),
            recordedBy: UUID(),
            physicalScore: 70,
            functionalScore: 70,
            psychologicalScore: 70
        )

        XCTAssertEqual(sut.currentTrafficLight, .yellow)
    }

    func testCurrentTrafficLight_WhenRedReadiness_ReturnsRed() {
        sut.latestReadiness = RTSReadinessScore(
            protocolId: UUID(),
            phaseId: UUID(),
            recordedBy: UUID(),
            physicalScore: 50,
            functionalScore: 50,
            psychologicalScore: 50
        )

        XCTAssertEqual(sut.currentTrafficLight, .red)
    }

    func testLatestReadinessScore_IsAliasForLatestReadiness() {
        let score = RTSReadinessScore(
            protocolId: UUID(),
            phaseId: UUID(),
            recordedBy: UUID(),
            physicalScore: 85,
            functionalScore: 85,
            psychologicalScore: 85
        )

        sut.latestReadiness = score

        XCTAssertEqual(sut.latestReadinessScore?.id, sut.latestReadiness?.id)
    }
}

// MARK: - canAdvancePhase Tests

@MainActor
final class RTSProtocolViewModelCanAdvanceTests: XCTestCase {

    var sut: RTSProtocolViewModel!

    override func setUp() {
        super.setUp()
        sut = RTSProtocolViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testCanAdvancePhase_WhenNoCurrentPhase_ReturnsFalse() {
        XCTAssertNil(sut.currentPhase)
        XCTAssertFalse(sut.canAdvancePhase)
    }

    func testCanAdvancePhase_WhenPhaseNotActive_ReturnsFalse() {
        let pendingPhase = RTSPhase(
            protocolId: UUID(),
            phaseNumber: 1,
            phaseName: "Pending",
            activityLevel: .red,
            description: "",
            startedAt: nil,
            completedAt: nil
        )

        sut.currentPhase = pendingPhase
        XCTAssertFalse(sut.canAdvancePhase)
    }

    func testCanAdvancePhase_WhenActiveButLowReadiness_ReturnsFalse() {
        let activePhase = RTSPhase(
            protocolId: UUID(),
            phaseNumber: 1,
            phaseName: "Active",
            activityLevel: .yellow,
            description: "",
            startedAt: Date(),
            completedAt: nil
        )

        sut.currentPhase = activePhase
        sut.latestReadiness = RTSReadinessScore(
            protocolId: UUID(),
            phaseId: UUID(),
            recordedBy: UUID(),
            physicalScore: 70,
            functionalScore: 70,
            psychologicalScore: 70
        )

        XCTAssertFalse(sut.canAdvancePhase)
    }

    func testCanAdvancePhase_WhenActiveAndHighReadiness_ReturnsTrue() {
        let activePhase = RTSPhase(
            protocolId: UUID(),
            phaseNumber: 1,
            phaseName: "Active",
            activityLevel: .yellow,
            description: "",
            startedAt: Date(),
            completedAt: nil
        )

        sut.currentPhase = activePhase
        sut.latestReadiness = RTSReadinessScore(
            protocolId: UUID(),
            phaseId: UUID(),
            recordedBy: UUID(),
            physicalScore: 90,
            functionalScore: 90,
            psychologicalScore: 90
        )

        XCTAssertTrue(sut.canAdvancePhase)
    }

    func testCanAdvancePhase_WhenReadinessExactly80_ReturnsTrue() {
        let activePhase = RTSPhase(
            protocolId: UUID(),
            phaseNumber: 1,
            phaseName: "Active",
            activityLevel: .yellow,
            description: "",
            startedAt: Date(),
            completedAt: nil
        )

        sut.currentPhase = activePhase
        sut.latestReadiness = RTSReadinessScore(
            protocolId: UUID(),
            phaseId: UUID(),
            recordedBy: UUID(),
            physicalScore: 80,
            functionalScore: 80,
            psychologicalScore: 80
        )

        XCTAssertTrue(sut.canAdvancePhase)
    }

    func testCanAdvancePhase_WhenReadiness79_ReturnsFalse() {
        let activePhase = RTSPhase(
            protocolId: UUID(),
            phaseNumber: 1,
            phaseName: "Active",
            activityLevel: .yellow,
            description: "",
            startedAt: Date(),
            completedAt: nil
        )

        sut.currentPhase = activePhase
        // Overall = 80*0.4 + 80*0.4 + 75*0.2 = 32 + 32 + 15 = 79
        sut.latestReadiness = RTSReadinessScore(
            protocolId: UUID(),
            phaseId: UUID(),
            recordedBy: UUID(),
            physicalScore: 80,
            functionalScore: 80,
            psychologicalScore: 75
        )

        XCTAssertFalse(sut.canAdvancePhase)
    }
}

// MARK: - Form Validation Tests

@MainActor
final class RTSProtocolViewModelFormValidationTests: XCTestCase {

    var sut: RTSProtocolViewModel!

    override func setUp() {
        super.setUp()
        sut = RTSProtocolViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testIsFormValid_WhenAllFieldsEmpty_ReturnsFalse() {
        XCTAssertFalse(sut.isFormValid)
    }

    func testIsFormValid_WhenNoSportSelected_ReturnsFalse() {
        sut.injuryType = "ACL Tear"
        sut.injuryDate = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        sut.targetReturnDate = Calendar.current.date(byAdding: .month, value: 6, to: Date())!

        XCTAssertFalse(sut.isFormValid)
    }

    func testIsFormValid_WhenInjuryTypeEmpty_ReturnsFalse() {
        sut.selectedSport = createSampleSport()
        sut.injuryType = ""
        sut.injuryDate = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        sut.targetReturnDate = Calendar.current.date(byAdding: .month, value: 6, to: Date())!

        XCTAssertFalse(sut.isFormValid)
    }

    func testIsFormValid_WhenInjuryTypeOnlyWhitespace_ReturnsFalse() {
        sut.selectedSport = createSampleSport()
        sut.injuryType = "   "
        sut.injuryDate = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        sut.targetReturnDate = Calendar.current.date(byAdding: .month, value: 6, to: Date())!

        XCTAssertFalse(sut.isFormValid)
    }

    func testIsFormValid_WhenTargetDateBeforeInjuryDate_ReturnsFalse() {
        sut.selectedSport = createSampleSport()
        sut.injuryType = "ACL Tear"
        sut.injuryDate = Date()
        sut.targetReturnDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        XCTAssertFalse(sut.isFormValid)
    }

    func testIsFormValid_WhenTargetDateEqualsInjuryDate_ReturnsFalse() {
        sut.selectedSport = createSampleSport()
        sut.injuryType = "ACL Tear"
        let date = Date()
        sut.injuryDate = date
        sut.targetReturnDate = date

        XCTAssertFalse(sut.isFormValid)
    }

    func testIsFormValid_WhenAllFieldsValid_ReturnsTrue() {
        sut.selectedSport = createSampleSport()
        sut.injuryType = "ACL Tear"
        sut.injuryDate = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        sut.targetReturnDate = Calendar.current.date(byAdding: .month, value: 6, to: Date())!

        XCTAssertTrue(sut.isFormValid)
    }

    // MARK: - Helper Methods

    private func createSampleSport() -> RTSSport {
        RTSSport(
            name: "Baseball",
            category: .throwing,
            defaultPhases: []
        )
    }
}

// MARK: - Protocol Filtering Tests

@MainActor
final class RTSProtocolViewModelFilteringTests: XCTestCase {

    var sut: RTSProtocolViewModel!

    override func setUp() {
        super.setUp()
        sut = RTSProtocolViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testActiveProtocols_FiltersCorrectly() {
        let active = createProtocol(status: .active)
        let draft = createProtocol(status: .draft)
        let completed = createProtocol(status: .completed)
        let discontinued = createProtocol(status: .discontinued)

        sut.protocols = [active, draft, completed, discontinued]

        XCTAssertEqual(sut.activeProtocols.count, 1)
        XCTAssertEqual(sut.activeProtocols.first?.status, .active)
    }

    func testDraftProtocols_FiltersCorrectly() {
        let active = createProtocol(status: .active)
        let draft1 = createProtocol(status: .draft)
        let draft2 = createProtocol(status: .draft)
        let completed = createProtocol(status: .completed)

        sut.protocols = [active, draft1, draft2, completed]

        XCTAssertEqual(sut.draftProtocols.count, 2)
        XCTAssertTrue(sut.draftProtocols.allSatisfy { $0.status == .draft })
    }

    func testCompletedProtocols_FiltersCorrectly() {
        let active = createProtocol(status: .active)
        let completed1 = createProtocol(status: .completed)
        let completed2 = createProtocol(status: .completed)
        let discontinued = createProtocol(status: .discontinued)

        sut.protocols = [active, completed1, completed2, discontinued]

        XCTAssertEqual(sut.completedProtocols.count, 2)
        XCTAssertTrue(sut.completedProtocols.allSatisfy { $0.status == .completed })
    }

    // MARK: - Helper Methods

    private func createProtocol(status: RTSProtocolStatus) -> RTSProtocol {
        RTSProtocol(
            patientId: UUID(),
            therapistId: UUID(),
            sportId: UUID(),
            injuryType: "Test Injury",
            injuryDate: Calendar.current.date(byAdding: .month, value: -3, to: Date())!,
            targetReturnDate: Calendar.current.date(byAdding: .month, value: 6, to: Date())!,
            status: status
        )
    }
}

// MARK: - Days Until Target Tests

@MainActor
final class RTSProtocolViewModelDaysUntilTargetTests: XCTestCase {

    var sut: RTSProtocolViewModel!

    override func setUp() {
        super.setUp()
        sut = RTSProtocolViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testDaysUntilTarget_WhenNoProtocol_ReturnsNil() {
        XCTAssertNil(sut.daysUntilTarget)
    }

    func testDaysUntilTarget_WhenProtocolHasFutureTarget_ReturnsPositive() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!

        sut.currentProtocol = RTSProtocol(
            patientId: UUID(),
            therapistId: UUID(),
            sportId: UUID(),
            injuryType: "Test",
            injuryDate: Calendar.current.date(byAdding: .month, value: -3, to: Date())!,
            targetReturnDate: futureDate,
            status: .active
        )

        XCTAssertNotNil(sut.daysUntilTarget)
        XCTAssertEqual(sut.daysUntilTarget ?? 0, 30, accuracy: 1)
    }

    func testDaysUntilTarget_WhenProtocolHasPastTarget_ReturnsNegative() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!

        sut.currentProtocol = RTSProtocol(
            patientId: UUID(),
            therapistId: UUID(),
            sportId: UUID(),
            injuryType: "Test",
            injuryDate: Calendar.current.date(byAdding: .month, value: -6, to: Date())!,
            targetReturnDate: pastDate,
            status: .active
        )

        XCTAssertNotNil(sut.daysUntilTarget)
        XCTAssertLessThan(sut.daysUntilTarget ?? 0, 0)
    }
}

// MARK: - Reset Tests

@MainActor
final class RTSProtocolViewModelResetTests: XCTestCase {

    var sut: RTSProtocolViewModel!

    override func setUp() {
        super.setUp()
        sut = RTSProtocolViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testReset_ClearsAllState() {
        // Set up state
        sut.protocols = [RTSProtocol(
            patientId: UUID(),
            therapistId: UUID(),
            sportId: UUID(),
            injuryType: "Test",
            injuryDate: Date(),
            targetReturnDate: Date(),
            status: .active
        )]
        sut.currentProtocol = sut.protocols.first
        sut.phases = [RTSPhase(
            protocolId: UUID(),
            phaseNumber: 1,
            phaseName: "Test",
            activityLevel: .red,
            description: ""
        )]
        sut.currentPhase = sut.phases.first
        sut.sports = [RTSSport(name: "Baseball", category: .throwing)]
        sut.clearances = [RTSClearance(
            protocolId: UUID(),
            clearanceType: .phaseClearance,
            clearanceLevel: .yellow,
            assessmentSummary: "Test",
            recommendations: "Test"
        )]
        sut.readinessScores = [RTSReadinessScore(
            protocolId: UUID(),
            phaseId: UUID(),
            recordedBy: UUID(),
            physicalScore: 80,
            functionalScore: 80,
            psychologicalScore: 80
        )]
        sut.latestReadiness = sut.readinessScores.first
        sut.selectedSport = sut.sports.first
        sut.injuryType = "ACL Tear"
        sut.notes = "Some notes"
        sut.errorMessage = "Error"
        sut.successMessage = "Success"

        // Reset
        sut.reset()

        // Verify
        XCTAssertTrue(sut.protocols.isEmpty)
        XCTAssertNil(sut.currentProtocol)
        XCTAssertTrue(sut.phases.isEmpty)
        XCTAssertNil(sut.currentPhase)
        XCTAssertTrue(sut.sports.isEmpty)
        XCTAssertTrue(sut.clearances.isEmpty)
        XCTAssertTrue(sut.readinessScores.isEmpty)
        XCTAssertNil(sut.latestReadiness)
        XCTAssertNil(sut.selectedSport)
        XCTAssertEqual(sut.injuryType, "")
        XCTAssertEqual(sut.notes, "")
        XCTAssertNil(sut.errorMessage)
        XCTAssertNil(sut.successMessage)
    }

    func testResetForm_ClearsOnlyFormState() {
        // Set up protocol data
        sut.protocols = [RTSProtocol(
            patientId: UUID(),
            therapistId: UUID(),
            sportId: UUID(),
            injuryType: "Test",
            injuryDate: Date(),
            targetReturnDate: Date(),
            status: .active
        )]
        sut.currentProtocol = sut.protocols.first

        // Set up form state
        sut.selectedSport = RTSSport(name: "Baseball", category: .throwing)
        sut.injuryType = "ACL Tear"
        sut.surgeryDate = Date()
        sut.notes = "Some notes"

        // Reset form only
        sut.resetForm()

        // Verify form cleared
        XCTAssertNil(sut.selectedSport)
        XCTAssertEqual(sut.injuryType, "")
        XCTAssertNil(sut.surgeryDate)
        XCTAssertEqual(sut.notes, "")

        // Verify protocol data preserved
        XCTAssertFalse(sut.protocols.isEmpty)
        XCTAssertNotNil(sut.currentProtocol)
    }

    func testClearMessages_ClearsErrorAndSuccess() {
        sut.errorMessage = "Error"
        sut.successMessage = "Success"

        sut.clearMessages()

        XCTAssertNil(sut.errorMessage)
        XCTAssertNil(sut.successMessage)
    }
}

// MARK: - Clearance Validation Tests

@MainActor
final class RTSProtocolViewModelClearanceTests: XCTestCase {

    var sut: RTSProtocolViewModel!

    override func setUp() {
        super.setUp()
        sut = RTSProtocolViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testCreatePhaseClearance_WhenNoCurrentProtocol_SetsError() async {
        sut.currentProtocol = nil
        sut.currentPhase = RTSPhase(
            protocolId: UUID(),
            phaseNumber: 1,
            phaseName: "Test",
            activityLevel: .yellow,
            description: ""
        )

        let result = await sut.createPhaseClearance()

        XCTAssertNil(result)
        XCTAssertNotNil(sut.errorMessage)
    }

    func testCreatePhaseClearance_WhenNoCurrentPhase_SetsError() async {
        sut.currentProtocol = RTSProtocol(
            patientId: UUID(),
            therapistId: UUID(),
            sportId: UUID(),
            injuryType: "Test",
            injuryDate: Date(),
            targetReturnDate: Date(),
            status: .active
        )
        sut.currentPhase = nil

        let result = await sut.createPhaseClearance()

        XCTAssertNil(result)
        XCTAssertNotNil(sut.errorMessage)
    }

    func testCreateFinalClearance_WhenNoCurrentProtocol_SetsError() async {
        sut.currentProtocol = nil

        let result = await sut.createFinalClearance()

        XCTAssertNil(result)
        XCTAssertNotNil(sut.errorMessage)
    }

    func testCreateFinalClearance_WhenNotGreenLight_SetsError() async {
        sut.currentProtocol = RTSProtocol(
            patientId: UUID(),
            therapistId: UUID(),
            sportId: UUID(),
            injuryType: "Test",
            injuryDate: Date(),
            targetReturnDate: Date(),
            status: .active
        )
        // Yellow readiness
        sut.latestReadiness = RTSReadinessScore(
            protocolId: UUID(),
            phaseId: UUID(),
            recordedBy: UUID(),
            physicalScore: 70,
            functionalScore: 70,
            psychologicalScore: 70
        )

        let result = await sut.createFinalClearance()

        XCTAssertNil(result)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("green zone") ?? false)
    }
}

// MARK: - Advance To Next Phase Validation Tests

@MainActor
final class RTSProtocolViewModelAdvancePhaseTests: XCTestCase {

    var sut: RTSProtocolViewModel!

    override func setUp() {
        super.setUp()
        sut = RTSProtocolViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testAdvanceToNextPhase_WhenNoCurrentProtocol_SetsError() async {
        sut.currentProtocol = nil
        sut.currentPhase = RTSPhase(
            protocolId: UUID(),
            phaseNumber: 1,
            phaseName: "Test",
            activityLevel: .yellow,
            description: "",
            startedAt: Date()
        )

        await sut.advanceToNextPhase(
            reason: "Test",
            criteriaSummary: RTSCriteriaSummary(totalCriteria: 5, passedCriteria: 5, requiredPassed: 3, requiredTotal: 3)
        )

        XCTAssertNotNil(sut.errorMessage)
    }

    func testAdvanceToNextPhase_WhenNoCurrentPhase_SetsError() async {
        sut.currentProtocol = RTSProtocol(
            patientId: UUID(),
            therapistId: UUID(),
            sportId: UUID(),
            injuryType: "Test",
            injuryDate: Date(),
            targetReturnDate: Date(),
            status: .active
        )
        sut.currentPhase = nil

        await sut.advanceToNextPhase(
            reason: "Test",
            criteriaSummary: RTSCriteriaSummary(totalCriteria: 5, passedCriteria: 5, requiredPassed: 3, requiredTotal: 3)
        )

        XCTAssertNotNil(sut.errorMessage)
    }

    func testAdvanceToNextPhase_WhenNoNextPhase_SetsError() async {
        let protocolId = UUID()

        sut.currentProtocol = RTSProtocol(
            id: protocolId,
            patientId: UUID(),
            therapistId: UUID(),
            sportId: UUID(),
            injuryType: "Test",
            injuryDate: Date(),
            targetReturnDate: Date(),
            status: .active
        )

        // Only one phase - no next phase available
        let phase = RTSPhase(
            protocolId: protocolId,
            phaseNumber: 1,
            phaseName: "Only Phase",
            activityLevel: .yellow,
            description: "",
            startedAt: Date()
        )
        sut.phases = [phase]
        sut.currentPhase = phase

        await sut.advanceToNextPhase(
            reason: "Test",
            criteriaSummary: RTSCriteriaSummary(totalCriteria: 5, passedCriteria: 5, requiredPassed: 3, requiredTotal: 3)
        )

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("No next phase") ?? false)
    }
}

// MARK: - RTSTrafficLight ViewModel Tests

@MainActor
final class RTSTrafficLightViewModelTests: XCTestCase {

    func testFromScore_WhenScoreAbove80_ReturnsGreen() {
        XCTAssertEqual(RTSTrafficLight.from(score: 80), .green)
        XCTAssertEqual(RTSTrafficLight.from(score: 90), .green)
        XCTAssertEqual(RTSTrafficLight.from(score: 100), .green)
    }

    func testFromScore_WhenScoreBetween60And80_ReturnsYellow() {
        XCTAssertEqual(RTSTrafficLight.from(score: 60), .yellow)
        XCTAssertEqual(RTSTrafficLight.from(score: 70), .yellow)
        XCTAssertEqual(RTSTrafficLight.from(score: 79), .yellow)
        XCTAssertEqual(RTSTrafficLight.from(score: 79.99), .yellow)
    }

    func testFromScore_WhenScoreBelow60_ReturnsRed() {
        XCTAssertEqual(RTSTrafficLight.from(score: 0), .red)
        XCTAssertEqual(RTSTrafficLight.from(score: 30), .red)
        XCTAssertEqual(RTSTrafficLight.from(score: 59), .red)
        XCTAssertEqual(RTSTrafficLight.from(score: 59.99), .red)
    }

    func testContainsScore_GreenRange() {
        XCTAssertTrue(RTSTrafficLight.green.contains(score: 80))
        XCTAssertTrue(RTSTrafficLight.green.contains(score: 100))
        XCTAssertFalse(RTSTrafficLight.green.contains(score: 79))
    }

    func testContainsScore_YellowRange() {
        XCTAssertTrue(RTSTrafficLight.yellow.contains(score: 60))
        XCTAssertTrue(RTSTrafficLight.yellow.contains(score: 79))
        XCTAssertFalse(RTSTrafficLight.yellow.contains(score: 80))
        XCTAssertFalse(RTSTrafficLight.yellow.contains(score: 59))
    }

    func testContainsScore_RedRange() {
        XCTAssertTrue(RTSTrafficLight.red.contains(score: 0))
        XCTAssertTrue(RTSTrafficLight.red.contains(score: 59))
        XCTAssertFalse(RTSTrafficLight.red.contains(score: 60))
    }

    func testMinimumScore() {
        XCTAssertEqual(RTSTrafficLight.green.minimumScore, 80)
        XCTAssertEqual(RTSTrafficLight.yellow.minimumScore, 60)
        XCTAssertEqual(RTSTrafficLight.red.minimumScore, 0)
    }

    func testDisplayNames() {
        XCTAssertEqual(RTSTrafficLight.green.displayName, "Cleared")
        XCTAssertEqual(RTSTrafficLight.yellow.displayName, "Caution")
        XCTAssertEqual(RTSTrafficLight.red.displayName, "Restricted")
    }
}

// MARK: - RTSReadinessScore Calculation Tests

@MainActor
final class RTSReadinessScoreCalculationTests: XCTestCase {

    func testCalculateOverall_EqualWeights() {
        // 40% Physical + 40% Functional + 20% Psychological
        let result = RTSReadinessScore.calculateOverall(
            physical: 100,
            functional: 100,
            psychological: 100
        )

        XCTAssertEqual(result, 100, accuracy: 0.01)
    }

    func testCalculateOverall_PhysicalOnly() {
        let result = RTSReadinessScore.calculateOverall(
            physical: 100,
            functional: 0,
            psychological: 0
        )

        XCTAssertEqual(result, 40, accuracy: 0.01)
    }

    func testCalculateOverall_FunctionalOnly() {
        let result = RTSReadinessScore.calculateOverall(
            physical: 0,
            functional: 100,
            psychological: 0
        )

        XCTAssertEqual(result, 40, accuracy: 0.01)
    }

    func testCalculateOverall_PsychologicalOnly() {
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
}

// MARK: - RTSPhase Computed Properties Tests

@MainActor
final class RTSPhaseComputedPropertiesTests: XCTestCase {

    func testIsActive_WhenStartedButNotCompleted_ReturnsTrue() {
        let phase = RTSPhase(
            protocolId: UUID(),
            phaseNumber: 1,
            phaseName: "Test",
            activityLevel: .yellow,
            description: "",
            startedAt: Date(),
            completedAt: nil
        )

        XCTAssertTrue(phase.isActive)
    }

    func testIsActive_WhenNotStarted_ReturnsFalse() {
        let phase = RTSPhase(
            protocolId: UUID(),
            phaseNumber: 1,
            phaseName: "Test",
            activityLevel: .yellow,
            description: "",
            startedAt: nil,
            completedAt: nil
        )

        XCTAssertFalse(phase.isActive)
    }

    func testIsActive_WhenCompleted_ReturnsFalse() {
        let phase = RTSPhase(
            protocolId: UUID(),
            phaseNumber: 1,
            phaseName: "Test",
            activityLevel: .yellow,
            description: "",
            startedAt: Date(),
            completedAt: Date()
        )

        XCTAssertFalse(phase.isActive)
    }

    func testIsCompleted_WhenCompletedAtSet_ReturnsTrue() {
        let phase = RTSPhase(
            protocolId: UUID(),
            phaseNumber: 1,
            phaseName: "Test",
            activityLevel: .yellow,
            description: "",
            startedAt: Date(),
            completedAt: Date()
        )

        XCTAssertTrue(phase.isCompleted)
    }

    func testIsPending_WhenNotStarted_ReturnsTrue() {
        let phase = RTSPhase(
            protocolId: UUID(),
            phaseNumber: 1,
            phaseName: "Test",
            activityLevel: .yellow,
            description: "",
            startedAt: nil,
            completedAt: nil
        )

        XCTAssertTrue(phase.isPending)
    }

    func testStatusText_Variations() {
        let pending = RTSPhase(
            protocolId: UUID(),
            phaseNumber: 1,
            phaseName: "P1",
            activityLevel: .red,
            description: "",
            startedAt: nil,
            completedAt: nil
        )
        XCTAssertEqual(pending.statusText, "Pending")

        let active = RTSPhase(
            protocolId: UUID(),
            phaseNumber: 2,
            phaseName: "P2",
            activityLevel: .yellow,
            description: "",
            startedAt: Date(),
            completedAt: nil
        )
        XCTAssertTrue(active.statusText.contains("Day") || active.statusText == "Active")

        let completed = RTSPhase(
            protocolId: UUID(),
            phaseNumber: 3,
            phaseName: "P3",
            activityLevel: .green,
            description: "",
            startedAt: Date(),
            completedAt: Date()
        )
        XCTAssertEqual(completed.statusText, "Completed")
    }
}

// MARK: - RTSProtocol Status ViewModel Tests

@MainActor
final class RTSProtocolStatusViewModelTests: XCTestCase {

    func testIsActive_WhenStatusActive_ReturnsTrue() {
        let protocol_ = RTSProtocol(
            patientId: UUID(),
            therapistId: UUID(),
            sportId: UUID(),
            injuryType: "Test",
            injuryDate: Date(),
            targetReturnDate: Date(),
            status: .active
        )

        XCTAssertTrue(protocol_.isActive)
    }

    func testIsActive_WhenStatusDraft_ReturnsFalse() {
        let protocol_ = RTSProtocol(
            patientId: UUID(),
            therapistId: UUID(),
            sportId: UUID(),
            injuryType: "Test",
            injuryDate: Date(),
            targetReturnDate: Date(),
            status: .draft
        )

        XCTAssertFalse(protocol_.isActive)
    }

    func testIsCompleted_WhenStatusCompleted_ReturnsTrue() {
        let protocol_ = RTSProtocol(
            patientId: UUID(),
            therapistId: UUID(),
            sportId: UUID(),
            injuryType: "Test",
            injuryDate: Date(),
            targetReturnDate: Date(),
            status: .completed
        )

        XCTAssertTrue(protocol_.isCompleted)
    }

    func testStatusIsEditable() {
        XCTAssertTrue(RTSProtocolStatus.draft.isEditable)
        XCTAssertTrue(RTSProtocolStatus.active.isEditable)
        XCTAssertFalse(RTSProtocolStatus.completed.isEditable)
        XCTAssertFalse(RTSProtocolStatus.discontinued.isEditable)
    }
}

// MARK: - RTSClearance Tests

@MainActor
final class RTSClearanceComputedPropertiesTests: XCTestCase {

    func testCanEdit_WhenDraft_ReturnsTrue() {
        let clearance = RTSClearance(
            protocolId: UUID(),
            clearanceType: .phaseClearance,
            clearanceLevel: .yellow,
            status: .draft,
            assessmentSummary: "Test",
            recommendations: "Test"
        )

        XCTAssertTrue(clearance.canEdit)
    }

    func testCanEdit_WhenSigned_ReturnsFalse() {
        let clearance = RTSClearance(
            protocolId: UUID(),
            clearanceType: .phaseClearance,
            clearanceLevel: .yellow,
            status: .signed,
            assessmentSummary: "Test",
            recommendations: "Test"
        )

        XCTAssertFalse(clearance.canEdit)
    }

    func testCanSign_WhenComplete_ReturnsTrue() {
        let clearance = RTSClearance(
            protocolId: UUID(),
            clearanceType: .phaseClearance,
            clearanceLevel: .yellow,
            status: .complete,
            assessmentSummary: "Test",
            recommendations: "Test"
        )

        XCTAssertTrue(clearance.canSign)
    }

    func testCanCoSign_WhenSignedAndRequiresPhysician_ReturnsTrue() {
        let clearance = RTSClearance(
            protocolId: UUID(),
            clearanceType: .finalClearance,
            clearanceLevel: .green,
            status: .signed,
            assessmentSummary: "Test",
            recommendations: "Test",
            requiresPhysicianSignature: true,
            signedBy: UUID(),
            signedAt: Date(),
            coSignedBy: nil,
            coSignedAt: nil
        )

        XCTAssertTrue(clearance.canCoSign)
    }

    func testIsFullySigned_WhenNoCoSignRequired_ReturnsTrue() {
        let clearance = RTSClearance(
            protocolId: UUID(),
            clearanceType: .phaseClearance,
            clearanceLevel: .yellow,
            status: .signed,
            assessmentSummary: "Test",
            recommendations: "Test",
            requiresPhysicianSignature: false,
            signedBy: UUID(),
            signedAt: Date()
        )

        XCTAssertTrue(clearance.isFullySigned)
    }

    func testIsFullySigned_WhenCoSignRequiredButMissing_ReturnsFalse() {
        let clearance = RTSClearance(
            protocolId: UUID(),
            clearanceType: .finalClearance,
            clearanceLevel: .green,
            status: .signed,
            assessmentSummary: "Test",
            recommendations: "Test",
            requiresPhysicianSignature: true,
            signedBy: UUID(),
            signedAt: Date(),
            coSignedBy: nil,
            coSignedAt: nil
        )

        XCTAssertFalse(clearance.isFullySigned)
    }

    func testIsFullySigned_WhenCoSignComplete_ReturnsTrue() {
        let clearance = RTSClearance(
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

        XCTAssertTrue(clearance.isFullySigned)
    }

    func testIsFullyCleared_WhenGreenAndFullySigned_ReturnsTrue() {
        let clearance = RTSClearance(
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

        XCTAssertTrue(clearance.isFullyCleared)
    }

    func testIsFullyCleared_WhenNotGreen_ReturnsFalse() {
        let clearance = RTSClearance(
            protocolId: UUID(),
            clearanceType: .phaseClearance,
            clearanceLevel: .yellow,
            status: .signed,
            assessmentSummary: "Test",
            recommendations: "Test",
            requiresPhysicianSignature: false,
            signedBy: UUID(),
            signedAt: Date()
        )

        XCTAssertFalse(clearance.isFullyCleared)
    }
}

// MARK: - RTSCriteriaSummary ViewModel Tests

@MainActor
final class RTSCriteriaSummaryViewModelTests: XCTestCase {

    func testInitialization_DefaultValues() {
        let summary = RTSCriteriaSummary()

        XCTAssertEqual(summary.totalCriteria, 0)
        XCTAssertEqual(summary.passedCriteria, 0)
        XCTAssertEqual(summary.requiredPassed, 0)
        XCTAssertEqual(summary.requiredTotal, 0)
        XCTAssertNil(summary.notes)
    }

    func testInitialization_WithValues() {
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
}

// MARK: - RTSComparisonOperator ViewModel Tests

@MainActor
final class RTSComparisonOperatorViewModelTests: XCTestCase {

    func testEvaluate_GreaterThanOrEqual() {
        let op = RTSComparisonOperator.greaterThanOrEqual

        XCTAssertTrue(op.evaluate(value: 85, target: 85))
        XCTAssertTrue(op.evaluate(value: 90, target: 85))
        XCTAssertFalse(op.evaluate(value: 80, target: 85))
    }

    func testEvaluate_LessThanOrEqual() {
        let op = RTSComparisonOperator.lessThanOrEqual

        XCTAssertTrue(op.evaluate(value: 2, target: 2))
        XCTAssertTrue(op.evaluate(value: 1, target: 2))
        XCTAssertFalse(op.evaluate(value: 3, target: 2))
    }

    func testEvaluate_Equal() {
        let op = RTSComparisonOperator.equal

        XCTAssertTrue(op.evaluate(value: 10, target: 10))
        XCTAssertTrue(op.evaluate(value: 10.0001, target: 10)) // Within 0.001 tolerance
        XCTAssertFalse(op.evaluate(value: 10.01, target: 10))
    }

    func testEvaluate_Between() {
        let op = RTSComparisonOperator.between

        // Without upper bound, acts like >=
        XCTAssertTrue(op.evaluate(value: 85, target: 80))
        XCTAssertFalse(op.evaluate(value: 75, target: 80))

        // With upper bound
        XCTAssertTrue(op.evaluate(value: 85, target: 80, upperBound: 90))
        XCTAssertTrue(op.evaluate(value: 80, target: 80, upperBound: 90))
        XCTAssertTrue(op.evaluate(value: 90, target: 80, upperBound: 90))
        XCTAssertFalse(op.evaluate(value: 75, target: 80, upperBound: 90))
        XCTAssertFalse(op.evaluate(value: 95, target: 80, upperBound: 90))
    }

    func testSymbols() {
        XCTAssertEqual(RTSComparisonOperator.greaterThanOrEqual.symbol, ">=")
        XCTAssertEqual(RTSComparisonOperator.lessThanOrEqual.symbol, "<=")
        XCTAssertEqual(RTSComparisonOperator.equal.symbol, "=")
        XCTAssertEqual(RTSComparisonOperator.between.symbol, "between")
    }
}
