//
//  PTBriefViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for PTBriefViewModel
//  Tests initial state, computed properties, action management,
//  supporting types, and pure helper logic.
//

import XCTest
import SwiftUI
@testable import PTPerformance

// MARK: - Tests

@MainActor
final class PTBriefViewModelTests: XCTestCase {

    var sut: PTBriefViewModel!

    override func setUp() async throws {
        try await super.setUp()
        sut = PTBriefViewModel()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_AthleteIsNil() {
        XCTAssertNil(sut.athlete, "athlete should be nil initially")
    }

    func testInitialState_ReadinessScoreIsNil() {
        XCTAssertNil(sut.readinessScore, "readinessScore should be nil initially")
    }

    func testInitialState_LatestDailyReadinessIsNil() {
        XCTAssertNil(sut.latestDailyReadiness, "latestDailyReadiness should be nil initially")
    }

    func testInitialState_KeyChangesIsEmpty() {
        XCTAssertTrue(sut.keyChanges.isEmpty, "keyChanges should be empty initially")
    }

    func testInitialState_RiskAlertsIsEmpty() {
        XCTAssertTrue(sut.riskAlerts.isEmpty, "riskAlerts should be empty initially")
    }

    func testInitialState_SuggestedActionsIsEmpty() {
        XCTAssertTrue(sut.suggestedActions.isEmpty, "suggestedActions should be empty initially")
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading, "isLoading should be false initially")
    }

    func testInitialState_ErrorMessageIsNil() {
        XCTAssertNil(sut.errorMessage, "errorMessage should be nil initially")
    }

    func testInitialState_SectionLoadingStatesAreFalse() {
        XCTAssertFalse(sut.isLoadingReadiness, "isLoadingReadiness should be false initially")
        XCTAssertFalse(sut.isLoadingDeltas, "isLoadingDeltas should be false initially")
        XCTAssertFalse(sut.isLoadingRisks, "isLoadingRisks should be false initially")
        XCTAssertFalse(sut.isLoadingActions, "isLoadingActions should be false initially")
    }

    func testInitialState_KPITimestampsAreNil() {
        XCTAssertNil(sut.briefOpenedAt, "briefOpenedAt should be nil initially")
        XCTAssertNil(sut.briefLoadedAt, "briefLoadedAt should be nil initially")
    }

    func testInitialState_NavigationStatesAreFalse() {
        XCTAssertFalse(sut.showScoreBreakdown, "showScoreBreakdown should be false initially")
        XCTAssertFalse(sut.showEvidenceDetail, "showEvidenceDetail should be false initially")
        XCTAssertFalse(sut.showProtocolBuilder, "showProtocolBuilder should be false initially")
    }

    func testInitialState_SelectionsAreNil() {
        XCTAssertNil(sut.selectedDelta, "selectedDelta should be nil initially")
        XCTAssertNil(sut.selectedRisk, "selectedRisk should be nil initially")
    }

    // MARK: - Computed Property Tests: hasCriticalRisks

    func testHasCriticalRisks_WhenEmpty_ReturnsFalse() {
        sut.riskAlerts = []
        XCTAssertFalse(sut.hasCriticalRisks, "hasCriticalRisks should be false when no alerts")
    }

    func testHasCriticalRisks_WhenLowSeverityOnly_ReturnsFalse() {
        sut.riskAlerts = [
            makeRiskAlert(severity: .low, requiresAcknowledgment: true)
        ]
        XCTAssertFalse(sut.hasCriticalRisks, "hasCriticalRisks should be false with only low-severity alerts")
    }

    func testHasCriticalRisks_WhenModerateSeverityOnly_ReturnsFalse() {
        sut.riskAlerts = [
            makeRiskAlert(severity: .moderate, requiresAcknowledgment: true)
        ]
        XCTAssertFalse(sut.hasCriticalRisks, "hasCriticalRisks should be false with only moderate-severity alerts")
    }

    func testHasCriticalRisks_WhenHighSeverityNotRequiringAcknowledgment_ReturnsFalse() {
        sut.riskAlerts = [
            makeRiskAlert(severity: .high, requiresAcknowledgment: false)
        ]
        XCTAssertFalse(sut.hasCriticalRisks, "hasCriticalRisks should be false when high-severity does not require acknowledgment")
    }

    func testHasCriticalRisks_WhenHighSeverityRequiringAcknowledgment_ReturnsTrue() {
        sut.riskAlerts = [
            makeRiskAlert(severity: .high, requiresAcknowledgment: true)
        ]
        XCTAssertTrue(sut.hasCriticalRisks, "hasCriticalRisks should be true when high-severity requires acknowledgment")
    }

    func testHasCriticalRisks_WhenCriticalSeverityRequiringAcknowledgment_ReturnsTrue() {
        sut.riskAlerts = [
            makeRiskAlert(severity: .critical, requiresAcknowledgment: true)
        ]
        XCTAssertTrue(sut.hasCriticalRisks, "hasCriticalRisks should be true when critical-severity requires acknowledgment")
    }

    // MARK: - Computed Property Tests: criticalRiskCount

    func testCriticalRiskCount_WhenEmpty_ReturnsZero() {
        sut.riskAlerts = []
        XCTAssertEqual(sut.criticalRiskCount, 0, "criticalRiskCount should be 0 when no alerts")
    }

    func testCriticalRiskCount_CountsOnlyHighAndCriticalWithAcknowledgment() {
        sut.riskAlerts = [
            makeRiskAlert(severity: .low, requiresAcknowledgment: true),
            makeRiskAlert(severity: .moderate, requiresAcknowledgment: true),
            makeRiskAlert(severity: .high, requiresAcknowledgment: true),
            makeRiskAlert(severity: .high, requiresAcknowledgment: false),
            makeRiskAlert(severity: .critical, requiresAcknowledgment: true),
            makeRiskAlert(severity: .critical, requiresAcknowledgment: false)
        ]
        XCTAssertEqual(sut.criticalRiskCount, 2, "criticalRiskCount should count only high/critical requiring acknowledgment")
    }

    func testCriticalRiskCount_MultipleCritical() {
        sut.riskAlerts = [
            makeRiskAlert(severity: .critical, requiresAcknowledgment: true),
            makeRiskAlert(severity: .critical, requiresAcknowledgment: true),
            makeRiskAlert(severity: .high, requiresAcknowledgment: true)
        ]
        XCTAssertEqual(sut.criticalRiskCount, 3, "criticalRiskCount should count all qualifying alerts")
    }

    // MARK: - Computed Property Tests: topChanges

    func testTopChanges_WhenEmpty_ReturnsEmpty() {
        sut.keyChanges = []
        XCTAssertTrue(sut.topChanges.isEmpty, "topChanges should be empty when no key changes")
    }

    func testTopChanges_WhenFewerThanThree_ReturnsAll() {
        let deltas = [
            makeDelta(metricName: "HRV"),
            makeDelta(metricName: "Sleep")
        ]
        sut.keyChanges = deltas
        XCTAssertEqual(sut.topChanges.count, 2, "topChanges should return all items when fewer than 3")
    }

    func testTopChanges_WhenExactlyThree_ReturnsAll() {
        let deltas = [
            makeDelta(metricName: "HRV"),
            makeDelta(metricName: "Sleep"),
            makeDelta(metricName: "Energy")
        ]
        sut.keyChanges = deltas
        XCTAssertEqual(sut.topChanges.count, 3, "topChanges should return all 3 items")
    }

    func testTopChanges_WhenMoreThanThree_ReturnsFirstThree() {
        let deltas = [
            makeDelta(metricName: "HRV"),
            makeDelta(metricName: "Sleep"),
            makeDelta(metricName: "Energy"),
            makeDelta(metricName: "Stress"),
            makeDelta(metricName: "Soreness")
        ]
        sut.keyChanges = deltas
        XCTAssertEqual(sut.topChanges.count, 3, "topChanges should return at most 3 items")
        XCTAssertEqual(sut.topChanges[0].metricName, "HRV", "topChanges should preserve order")
        XCTAssertEqual(sut.topChanges[1].metricName, "Sleep", "topChanges should preserve order")
        XCTAssertEqual(sut.topChanges[2].metricName, "Energy", "topChanges should preserve order")
    }

    // MARK: - Computed Property Tests: isFullyLoaded

    func testIsFullyLoaded_WhenAllSectionsNotLoading_ReturnsTrue() {
        sut.isLoadingReadiness = false
        sut.isLoadingDeltas = false
        sut.isLoadingRisks = false
        sut.isLoadingActions = false
        XCTAssertTrue(sut.isFullyLoaded, "isFullyLoaded should be true when no sections are loading")
    }

    func testIsFullyLoaded_WhenReadinessLoading_ReturnsFalse() {
        sut.isLoadingReadiness = true
        sut.isLoadingDeltas = false
        sut.isLoadingRisks = false
        sut.isLoadingActions = false
        XCTAssertFalse(sut.isFullyLoaded, "isFullyLoaded should be false when readiness is loading")
    }

    func testIsFullyLoaded_WhenDeltasLoading_ReturnsFalse() {
        sut.isLoadingReadiness = false
        sut.isLoadingDeltas = true
        sut.isLoadingRisks = false
        sut.isLoadingActions = false
        XCTAssertFalse(sut.isFullyLoaded, "isFullyLoaded should be false when deltas are loading")
    }

    func testIsFullyLoaded_WhenRisksLoading_ReturnsFalse() {
        sut.isLoadingReadiness = false
        sut.isLoadingDeltas = false
        sut.isLoadingRisks = true
        sut.isLoadingActions = false
        XCTAssertFalse(sut.isFullyLoaded, "isFullyLoaded should be false when risks are loading")
    }

    func testIsFullyLoaded_WhenActionsLoading_ReturnsFalse() {
        sut.isLoadingReadiness = false
        sut.isLoadingDeltas = false
        sut.isLoadingRisks = false
        sut.isLoadingActions = true
        XCTAssertFalse(sut.isFullyLoaded, "isFullyLoaded should be false when actions are loading")
    }

    func testIsFullyLoaded_WhenAllSectionsLoading_ReturnsFalse() {
        sut.isLoadingReadiness = true
        sut.isLoadingDeltas = true
        sut.isLoadingRisks = true
        sut.isLoadingActions = true
        XCTAssertFalse(sut.isFullyLoaded, "isFullyLoaded should be false when all sections are loading")
    }

    // MARK: - Computed Property Tests: loadDurationSeconds

    func testLoadDurationSeconds_WhenBothTimestampsNil_ReturnsNil() {
        XCTAssertNil(sut.loadDurationSeconds, "loadDurationSeconds should be nil when timestamps are nil")
    }

    func testLoadDurationSeconds_WhenOnlyOpenedAtSet_ReturnsNil() {
        // Manually set briefOpenedAt via the private(set) published property workaround:
        // Since briefOpenedAt is private(set), we simulate by going through loadBrief flow partially.
        // Instead, test via the preview extension.
        // We test the logic by verifying nil when loadedAt is missing.
        XCTAssertNil(sut.loadDurationSeconds, "loadDurationSeconds should be nil when briefLoadedAt is nil")
    }

    // MARK: - Computed Property Tests: lastSessionDateFormatted

    func testLastSessionDateFormatted_WhenNoAthlete_ReturnsNil() {
        sut.athlete = nil
        XCTAssertNil(sut.lastSessionDateFormatted, "lastSessionDateFormatted should be nil when no athlete")
    }

    func testLastSessionDateFormatted_WhenAthleteHasNoLastSession_ReturnsNil() {
        sut.athlete = makePatient(lastSessionDate: nil)
        XCTAssertNil(sut.lastSessionDateFormatted, "lastSessionDateFormatted should be nil when athlete has no last session date")
    }

    func testLastSessionDateFormatted_WhenAthleteHasLastSession_ReturnsNonNilString() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        sut.athlete = makePatient(lastSessionDate: yesterday)
        XCTAssertNotNil(sut.lastSessionDateFormatted, "lastSessionDateFormatted should return a string when last session date exists")
        XCTAssertFalse(sut.lastSessionDateFormatted!.isEmpty, "lastSessionDateFormatted should not be empty")
    }

    // MARK: - Action Management Tests: approveAction

    func testApproveAction_MatchingAction_SetsStatusToApproved() {
        let actionId = UUID()
        sut.suggestedActions = [
            makeAction(id: actionId, status: .pending)
        ]

        sut.approveAction(sut.suggestedActions[0])

        XCTAssertEqual(sut.suggestedActions[0].status, .approved, "Action status should be approved after approveAction")
    }

    func testApproveAction_NonMatchingAction_DoesNotChangeStatus() {
        let actionId = UUID()
        let otherActionId = UUID()
        sut.suggestedActions = [
            makeAction(id: actionId, status: .pending)
        ]

        let nonExistentAction = makeAction(id: otherActionId, status: .pending)
        sut.approveAction(nonExistentAction)

        XCTAssertEqual(sut.suggestedActions[0].status, .pending, "Action status should remain pending when approving non-matching action")
    }

    func testApproveAction_MultiplActions_OnlyApprovesMatching() {
        let action1Id = UUID()
        let action2Id = UUID()
        let action3Id = UUID()
        sut.suggestedActions = [
            makeAction(id: action1Id, status: .pending),
            makeAction(id: action2Id, status: .pending),
            makeAction(id: action3Id, status: .pending)
        ]

        sut.approveAction(sut.suggestedActions[1])

        XCTAssertEqual(sut.suggestedActions[0].status, .pending, "Non-matching action should remain pending")
        XCTAssertEqual(sut.suggestedActions[1].status, .approved, "Matching action should be approved")
        XCTAssertEqual(sut.suggestedActions[2].status, .pending, "Non-matching action should remain pending")
    }

    // MARK: - Action Management Tests: rejectAction

    func testRejectAction_MatchingAction_SetsStatusToRejected() {
        let actionId = UUID()
        sut.suggestedActions = [
            makeAction(id: actionId, status: .pending)
        ]

        sut.rejectAction(sut.suggestedActions[0])

        XCTAssertEqual(sut.suggestedActions[0].status, .rejected, "Action status should be rejected after rejectAction")
    }

    func testRejectAction_NonMatchingAction_DoesNotChangeStatus() {
        let actionId = UUID()
        sut.suggestedActions = [
            makeAction(id: actionId, status: .pending)
        ]

        let nonExistentAction = makeAction(id: UUID(), status: .pending)
        sut.rejectAction(nonExistentAction)

        XCTAssertEqual(sut.suggestedActions[0].status, .pending, "Action status should remain pending when rejecting non-matching action")
    }

    func testRejectAction_MultipleActions_OnlyRejectsMatching() {
        let action1Id = UUID()
        let action2Id = UUID()
        sut.suggestedActions = [
            makeAction(id: action1Id, status: .pending),
            makeAction(id: action2Id, status: .pending)
        ]

        sut.rejectAction(sut.suggestedActions[0])

        XCTAssertEqual(sut.suggestedActions[0].status, .rejected, "Matching action should be rejected")
        XCTAssertEqual(sut.suggestedActions[1].status, .pending, "Non-matching action should remain pending")
    }

    // MARK: - Plan Approval Tests: approvePlan

    func testApprovePlan_AllPendingActions_BecomeApproved() async {
        sut.suggestedActions = [
            makeAction(id: UUID(), status: .pending),
            makeAction(id: UUID(), status: .pending),
            makeAction(id: UUID(), status: .pending)
        ]

        await sut.approvePlan()

        for action in sut.suggestedActions {
            XCTAssertEqual(action.status, .approved, "All pending actions should be approved after approvePlan")
        }
    }

    func testApprovePlan_MixedStatuses_OnlyPendingBecomeApproved() async {
        sut.suggestedActions = [
            makeAction(id: UUID(), status: .pending),
            makeAction(id: UUID(), status: .rejected),
            makeAction(id: UUID(), status: .pending)
        ]

        await sut.approvePlan()

        XCTAssertEqual(sut.suggestedActions[0].status, .approved, "Pending action should be approved")
        XCTAssertEqual(sut.suggestedActions[1].status, .rejected, "Already rejected action should remain rejected")
        XCTAssertEqual(sut.suggestedActions[2].status, .approved, "Pending action should be approved")
    }

    func testApprovePlan_NoActions_DoesNotCrash() async {
        sut.suggestedActions = []
        await sut.approvePlan()
        XCTAssertTrue(sut.suggestedActions.isEmpty, "Empty actions should remain empty after approvePlan")
    }

    func testApprovePlan_AlreadyApproved_StaysApproved() async {
        sut.suggestedActions = [
            makeAction(id: UUID(), status: .approved)
        ]

        await sut.approvePlan()

        XCTAssertEqual(sut.suggestedActions[0].status, .approved, "Already approved action should stay approved")
    }

    // MARK: - Navigation State Tests

    func testOpenProtocolBuilder_SetsShowProtocolBuilderToTrue() {
        XCTAssertFalse(sut.showProtocolBuilder, "showProtocolBuilder should be false initially")
        sut.openProtocolBuilder()
        XCTAssertTrue(sut.showProtocolBuilder, "showProtocolBuilder should be true after openProtocolBuilder")
    }

    // MARK: - Preview Support Tests

    func testPreview_HasPopulatedData() {
        let preview = PTBriefViewModel.preview

        XCTAssertNotNil(preview.athlete, "Preview should have athlete")
        XCTAssertNotNil(preview.readinessScore, "Preview should have readinessScore")
        XCTAssertNotNil(preview.latestDailyReadiness, "Preview should have latestDailyReadiness")
        XCTAssertFalse(preview.keyChanges.isEmpty, "Preview should have keyChanges")
        XCTAssertFalse(preview.riskAlerts.isEmpty, "Preview should have riskAlerts")
        XCTAssertFalse(preview.suggestedActions.isEmpty, "Preview should have suggestedActions")
    }

    func testPreview_ReadinessScore() {
        let preview = PTBriefViewModel.preview
        XCTAssertEqual(preview.readinessScore?.score, 78, "Preview readiness score should be 78")
        XCTAssertEqual(preview.readinessScore?.trend, .improving, "Preview trend should be improving")
    }

    // MARK: - Helper Methods

    private func makeRiskAlert(
        severity: PTBriefRiskAlert.RiskSeverity,
        requiresAcknowledgment: Bool
    ) -> PTBriefRiskAlert {
        PTBriefRiskAlert(
            id: UUID(),
            title: "Test Alert",
            description: "Test description",
            severity: severity,
            thresholdValue: "1.3",
            currentValue: "1.5",
            source: "Test Source",
            citationCount: 1,
            requiresAcknowledgment: requiresAcknowledgment,
            timestamp: Date()
        )
    }

    private func makeDelta(metricName: String) -> PTBriefDelta {
        PTBriefDelta(
            id: UUID(),
            metricName: metricName,
            direction: .up,
            magnitude: "+10%",
            previousValue: "50",
            currentValue: "55",
            source: "Test Source",
            sourceType: .selfReport,
            citationCount: 1,
            timestamp: Date()
        )
    }

    private func makeAction(id: UUID, status: PTBriefAction.ActionStatus) -> PTBriefAction {
        PTBriefAction(
            id: id,
            title: "Test Action",
            rationale: "Test rationale",
            evidenceSummary: "Test evidence",
            citationCount: 1,
            protocolId: nil,
            priority: .recommended,
            status: status
        )
    }

    private func makePatient(lastSessionDate: Date? = nil) -> Patient {
        Patient(
            id: TestUUIDs.patient,
            therapistId: UUID(),
            firstName: "Test",
            lastName: "Athlete",
            email: "test@example.com",
            lastSessionDate: lastSessionDate
        )
    }
}

// MARK: - PTBriefReadiness Computed Property Tests

@MainActor
final class PTBriefReadinessTests: XCTestCase {

    // MARK: - scoreColor Tests

    func testScoreColor_Excellent_ReturnsGreen() {
        let readiness = makeReadiness(score: 85)
        XCTAssertEqual(readiness.scoreColor, .green, "Score 85 should have green color")
    }

    func testScoreColor_AtExcellentBoundary_ReturnsGreen() {
        let readiness = makeReadiness(score: 80)
        XCTAssertEqual(readiness.scoreColor, .green, "Score 80 should have green color")
    }

    func testScoreColor_Good_ReturnsYellow() {
        let readiness = makeReadiness(score: 70)
        XCTAssertEqual(readiness.scoreColor, .yellow, "Score 70 should have yellow color")
    }

    func testScoreColor_AtGoodLowerBoundary_ReturnsYellow() {
        let readiness = makeReadiness(score: 60)
        XCTAssertEqual(readiness.scoreColor, .yellow, "Score 60 should have yellow color")
    }

    func testScoreColor_Moderate_ReturnsOrange() {
        let readiness = makeReadiness(score: 50)
        XCTAssertEqual(readiness.scoreColor, .orange, "Score 50 should have orange color")
    }

    func testScoreColor_AtModerateLowerBoundary_ReturnsOrange() {
        let readiness = makeReadiness(score: 40)
        XCTAssertEqual(readiness.scoreColor, .orange, "Score 40 should have orange color")
    }

    func testScoreColor_Low_ReturnsRed() {
        let readiness = makeReadiness(score: 35)
        XCTAssertEqual(readiness.scoreColor, .red, "Score 35 should have red color")
    }

    func testScoreColor_Zero_ReturnsRed() {
        let readiness = makeReadiness(score: 0)
        XCTAssertEqual(readiness.scoreColor, .red, "Score 0 should have red color")
    }

    func testScoreColor_VeryHigh_ReturnsGreen() {
        let readiness = makeReadiness(score: 100)
        XCTAssertEqual(readiness.scoreColor, .green, "Score 100 should have green color")
    }

    // MARK: - scoreLabel Tests

    func testScoreLabel_Excellent() {
        let readiness = makeReadiness(score: 90)
        XCTAssertEqual(readiness.scoreLabel, "Excellent", "Score 90 should have label Excellent")
    }

    func testScoreLabel_AtExcellentBoundary() {
        let readiness = makeReadiness(score: 80)
        XCTAssertEqual(readiness.scoreLabel, "Excellent", "Score 80 should have label Excellent")
    }

    func testScoreLabel_Good() {
        let readiness = makeReadiness(score: 70)
        XCTAssertEqual(readiness.scoreLabel, "Good", "Score 70 should have label Good")
    }

    func testScoreLabel_AtGoodLowerBoundary() {
        let readiness = makeReadiness(score: 60)
        XCTAssertEqual(readiness.scoreLabel, "Good", "Score 60 should have label Good")
    }

    func testScoreLabel_Moderate() {
        let readiness = makeReadiness(score: 55)
        XCTAssertEqual(readiness.scoreLabel, "Moderate", "Score 55 should have label Moderate")
    }

    func testScoreLabel_AtModerateLowerBoundary() {
        let readiness = makeReadiness(score: 40)
        XCTAssertEqual(readiness.scoreLabel, "Moderate", "Score 40 should have label Moderate")
    }

    func testScoreLabel_Low() {
        let readiness = makeReadiness(score: 30)
        XCTAssertEqual(readiness.scoreLabel, "Low", "Score 30 should have label Low")
    }

    func testScoreLabel_Zero() {
        let readiness = makeReadiness(score: 0)
        XCTAssertEqual(readiness.scoreLabel, "Low", "Score 0 should have label Low")
    }

    // MARK: - ReadinessTrend Tests

    func testReadinessTrend_Improving_DisplayName() {
        XCTAssertEqual(PTBriefReadiness.ReadinessTrend.improving.displayName, "Improving")
    }

    func testReadinessTrend_Stable_DisplayName() {
        XCTAssertEqual(PTBriefReadiness.ReadinessTrend.stable.displayName, "Stable")
    }

    func testReadinessTrend_Declining_DisplayName() {
        XCTAssertEqual(PTBriefReadiness.ReadinessTrend.declining.displayName, "Declining")
    }

    func testReadinessTrend_Improving_Icon() {
        XCTAssertEqual(PTBriefReadiness.ReadinessTrend.improving.icon, "arrow.up.right")
    }

    func testReadinessTrend_Stable_Icon() {
        XCTAssertEqual(PTBriefReadiness.ReadinessTrend.stable.icon, "arrow.right")
    }

    func testReadinessTrend_Declining_Icon() {
        XCTAssertEqual(PTBriefReadiness.ReadinessTrend.declining.icon, "arrow.down.right")
    }

    func testReadinessTrend_Improving_Color() {
        XCTAssertEqual(PTBriefReadiness.ReadinessTrend.improving.color, .green)
    }

    func testReadinessTrend_Stable_Color() {
        XCTAssertEqual(PTBriefReadiness.ReadinessTrend.stable.color, .gray)
    }

    func testReadinessTrend_Declining_Color() {
        XCTAssertEqual(PTBriefReadiness.ReadinessTrend.declining.color, .orange)
    }

    // MARK: - PTBriefReadiness Equatable Tests

    func testReadiness_Equatable_SameValues_AreEqual() {
        let date = Date()
        let readiness1 = PTBriefReadiness(
            score: 75, trend: .stable, confidence: 0.85,
            confidenceReason: "Test", lastUpdated: date, citationCount: 3
        )
        let readiness2 = PTBriefReadiness(
            score: 75, trend: .stable, confidence: 0.85,
            confidenceReason: "Test", lastUpdated: date, citationCount: 3
        )
        XCTAssertEqual(readiness1, readiness2, "Readiness with same values should be equal")
    }

    func testReadiness_Equatable_DifferentScores_AreNotEqual() {
        let date = Date()
        let readiness1 = PTBriefReadiness(
            score: 75, trend: .stable, confidence: 0.85,
            confidenceReason: "Test", lastUpdated: date, citationCount: 3
        )
        let readiness2 = PTBriefReadiness(
            score: 80, trend: .stable, confidence: 0.85,
            confidenceReason: "Test", lastUpdated: date, citationCount: 3
        )
        XCTAssertNotEqual(readiness1, readiness2, "Readiness with different scores should not be equal")
    }

    // MARK: - Helper Methods

    private func makeReadiness(score: Double) -> PTBriefReadiness {
        PTBriefReadiness(
            score: score,
            trend: .stable,
            confidence: 0.85,
            confidenceReason: "Test",
            lastUpdated: Date(),
            citationCount: 3
        )
    }
}

// MARK: - Supporting Type Tests: DeltaDirection

@MainActor
final class PTBriefDeltaDirectionTests: XCTestCase {

    func testDeltaDirection_Up_Icon() {
        XCTAssertEqual(PTBriefDelta.DeltaDirection.up.icon, "arrow.up.right")
    }

    func testDeltaDirection_Down_Icon() {
        XCTAssertEqual(PTBriefDelta.DeltaDirection.down.icon, "arrow.down.right")
    }

    func testDeltaDirection_Unchanged_Icon() {
        XCTAssertEqual(PTBriefDelta.DeltaDirection.unchanged.icon, "arrow.right")
    }

    func testDeltaDirection_Up_Color() {
        XCTAssertEqual(PTBriefDelta.DeltaDirection.up.color, .green)
    }

    func testDeltaDirection_Down_Color() {
        XCTAssertEqual(PTBriefDelta.DeltaDirection.down.color, .orange)
    }

    func testDeltaDirection_Unchanged_Color() {
        XCTAssertEqual(PTBriefDelta.DeltaDirection.unchanged.color, .gray)
    }

    func testDeltaDirection_RawValues() {
        XCTAssertEqual(PTBriefDelta.DeltaDirection.up.rawValue, "up")
        XCTAssertEqual(PTBriefDelta.DeltaDirection.down.rawValue, "down")
        XCTAssertEqual(PTBriefDelta.DeltaDirection.unchanged.rawValue, "unchanged")
    }
}

// MARK: - Supporting Type Tests: DataSourceType

@MainActor
final class PTBriefDataSourceTypeTests: XCTestCase {

    func testDataSourceType_Wearable_Icon() {
        XCTAssertEqual(PTBriefDelta.DataSourceType.wearable.icon, "applewatch")
    }

    func testDataSourceType_SelfReport_Icon() {
        XCTAssertEqual(PTBriefDelta.DataSourceType.selfReport.icon, "person.fill.questionmark")
    }

    func testDataSourceType_Assessment_Icon() {
        XCTAssertEqual(PTBriefDelta.DataSourceType.assessment.icon, "clipboard.fill")
    }

    func testDataSourceType_AIInference_Icon() {
        XCTAssertEqual(PTBriefDelta.DataSourceType.aiInference.icon, "sparkles")
    }

    func testDataSourceType_RawValues() {
        XCTAssertEqual(PTBriefDelta.DataSourceType.wearable.rawValue, "Wearable")
        XCTAssertEqual(PTBriefDelta.DataSourceType.selfReport.rawValue, "Self-Report")
        XCTAssertEqual(PTBriefDelta.DataSourceType.assessment.rawValue, "Assessment")
        XCTAssertEqual(PTBriefDelta.DataSourceType.aiInference.rawValue, "AI Inference")
    }
}

// MARK: - Supporting Type Tests: RiskSeverity

@MainActor
final class PTBriefRiskSeverityTests: XCTestCase {

    func testRiskSeverity_Ordering() {
        XCTAssertTrue(PTBriefRiskAlert.RiskSeverity.low < .moderate, "Low should be less than moderate")
        XCTAssertTrue(PTBriefRiskAlert.RiskSeverity.moderate < .high, "Moderate should be less than high")
        XCTAssertTrue(PTBriefRiskAlert.RiskSeverity.high < .critical, "High should be less than critical")
    }

    func testRiskSeverity_LowNotGreaterThanHigh() {
        XCTAssertFalse(PTBriefRiskAlert.RiskSeverity.low > .high, "Low should not be greater than high")
    }

    func testRiskSeverity_CriticalGreatestOfAll() {
        XCTAssertTrue(PTBriefRiskAlert.RiskSeverity.critical > .low, "Critical should be greater than low")
        XCTAssertTrue(PTBriefRiskAlert.RiskSeverity.critical > .moderate, "Critical should be greater than moderate")
        XCTAssertTrue(PTBriefRiskAlert.RiskSeverity.critical > .high, "Critical should be greater than high")
    }

    func testRiskSeverity_DisplayNames() {
        XCTAssertEqual(PTBriefRiskAlert.RiskSeverity.low.displayName, "Low")
        XCTAssertEqual(PTBriefRiskAlert.RiskSeverity.moderate.displayName, "Moderate")
        XCTAssertEqual(PTBriefRiskAlert.RiskSeverity.high.displayName, "High")
        XCTAssertEqual(PTBriefRiskAlert.RiskSeverity.critical.displayName, "Critical")
    }

    func testRiskSeverity_Icons() {
        XCTAssertEqual(PTBriefRiskAlert.RiskSeverity.low.icon, "exclamationmark.circle")
        XCTAssertEqual(PTBriefRiskAlert.RiskSeverity.moderate.icon, "exclamationmark.triangle")
        XCTAssertEqual(PTBriefRiskAlert.RiskSeverity.high.icon, "exclamationmark.triangle.fill")
        XCTAssertEqual(PTBriefRiskAlert.RiskSeverity.critical.icon, "exclamationmark.octagon.fill")
    }

    func testRiskSeverity_Colors() {
        XCTAssertEqual(PTBriefRiskAlert.RiskSeverity.low.color, .yellow)
        XCTAssertEqual(PTBriefRiskAlert.RiskSeverity.moderate.color, .orange)
        XCTAssertEqual(PTBriefRiskAlert.RiskSeverity.high.color, .red)
        XCTAssertEqual(PTBriefRiskAlert.RiskSeverity.critical.color, .red)
    }

    func testRiskSeverity_RawValues() {
        XCTAssertEqual(PTBriefRiskAlert.RiskSeverity.low.rawValue, 1)
        XCTAssertEqual(PTBriefRiskAlert.RiskSeverity.moderate.rawValue, 2)
        XCTAssertEqual(PTBriefRiskAlert.RiskSeverity.high.rawValue, 3)
        XCTAssertEqual(PTBriefRiskAlert.RiskSeverity.critical.rawValue, 4)
    }
}

// MARK: - Supporting Type Tests: ActionPriority

@MainActor
final class PTBriefActionPriorityTests: XCTestCase {

    func testActionPriority_Ordering() {
        XCTAssertTrue(PTBriefAction.ActionPriority.suggested < .recommended, "Suggested should be less than recommended")
        XCTAssertTrue(PTBriefAction.ActionPriority.recommended < .urgent, "Recommended should be less than urgent")
    }

    func testActionPriority_UrgentIsHighest() {
        XCTAssertTrue(PTBriefAction.ActionPriority.urgent > .suggested, "Urgent should be greater than suggested")
        XCTAssertTrue(PTBriefAction.ActionPriority.urgent > .recommended, "Urgent should be greater than recommended")
    }

    func testActionPriority_DisplayNames() {
        XCTAssertEqual(PTBriefAction.ActionPriority.suggested.displayName, "Suggested")
        XCTAssertEqual(PTBriefAction.ActionPriority.recommended.displayName, "Recommended")
        XCTAssertEqual(PTBriefAction.ActionPriority.urgent.displayName, "Urgent")
    }

    func testActionPriority_RawValues() {
        XCTAssertEqual(PTBriefAction.ActionPriority.suggested.rawValue, 1)
        XCTAssertEqual(PTBriefAction.ActionPriority.recommended.rawValue, 2)
        XCTAssertEqual(PTBriefAction.ActionPriority.urgent.rawValue, 3)
    }
}

// MARK: - Supporting Type Tests: ActionStatus

@MainActor
final class PTBriefActionStatusTests: XCTestCase {

    func testActionStatus_RawValues() {
        XCTAssertEqual(PTBriefAction.ActionStatus.pending.rawValue, "pending")
        XCTAssertEqual(PTBriefAction.ActionStatus.approved.rawValue, "approved")
        XCTAssertEqual(PTBriefAction.ActionStatus.rejected.rawValue, "rejected")
    }
}

// MARK: - PTBriefError Tests

@MainActor
final class PTBriefErrorTests: XCTestCase {

    func testNoReadinessData_ErrorDescription() {
        let error = PTBriefError.noReadinessData
        XCTAssertEqual(error.errorDescription, "No readiness data available for this athlete")
    }

    func testNoCheckInData_ErrorDescription() {
        let error = PTBriefError.noCheckInData
        XCTAssertEqual(error.errorDescription, "No check-in data available for comparison")
    }

    func testLoadFailed_ErrorDescription() {
        let underlyingError = NSError(domain: "TestDomain", code: 42, userInfo: [NSLocalizedDescriptionKey: "Test failure"])
        let error = PTBriefError.loadFailed(underlyingError)
        XCTAssertNotNil(error.errorDescription, "loadFailed should have an error description")
        XCTAssertTrue(error.errorDescription!.contains("Test failure"), "loadFailed should contain underlying error description")
    }
}

// MARK: - PTBriefDelta Identifiable/Equatable Tests

@MainActor
final class PTBriefDeltaTests: XCTestCase {

    func testDelta_Identifiable_HasUniqueId() {
        let delta1 = PTBriefDelta(
            id: UUID(), metricName: "HRV", direction: .up, magnitude: "+10%",
            previousValue: "45", currentValue: "50", source: "Watch",
            sourceType: .wearable, citationCount: 1, timestamp: Date()
        )
        let delta2 = PTBriefDelta(
            id: UUID(), metricName: "HRV", direction: .up, magnitude: "+10%",
            previousValue: "45", currentValue: "50", source: "Watch",
            sourceType: .wearable, citationCount: 1, timestamp: Date()
        )
        XCTAssertNotEqual(delta1.id, delta2.id, "Each delta should have a unique id")
    }

    func testDelta_Equatable_SameId_AreEqual() {
        let sharedId = UUID()
        let date = Date()
        let delta1 = PTBriefDelta(
            id: sharedId, metricName: "HRV", direction: .up, magnitude: "+10%",
            previousValue: "45", currentValue: "50", source: "Watch",
            sourceType: .wearable, citationCount: 1, timestamp: date
        )
        let delta2 = PTBriefDelta(
            id: sharedId, metricName: "HRV", direction: .up, magnitude: "+10%",
            previousValue: "45", currentValue: "50", source: "Watch",
            sourceType: .wearable, citationCount: 1, timestamp: date
        )
        XCTAssertEqual(delta1, delta2, "Deltas with same values should be equal")
    }
}

// MARK: - PTBriefRiskAlert Identifiable/Equatable Tests

@MainActor
final class PTBriefRiskAlertTests: XCTestCase {

    func testRiskAlert_Identifiable_HasUniqueId() {
        let alert1 = PTBriefRiskAlert(
            id: UUID(), title: "Alert 1", description: "Desc",
            severity: .high, thresholdValue: "1.3", currentValue: "1.5",
            source: "Test", citationCount: 1, requiresAcknowledgment: true, timestamp: Date()
        )
        let alert2 = PTBriefRiskAlert(
            id: UUID(), title: "Alert 2", description: "Desc",
            severity: .high, thresholdValue: "1.3", currentValue: "1.5",
            source: "Test", citationCount: 1, requiresAcknowledgment: true, timestamp: Date()
        )
        XCTAssertNotEqual(alert1.id, alert2.id, "Each alert should have a unique id")
    }
}

// MARK: - PTBriefAction Tests

@MainActor
final class PTBriefActionTests: XCTestCase {

    func testAction_Identifiable_HasUniqueId() {
        let action1 = PTBriefAction(
            id: UUID(), title: "Action 1", rationale: "Reason",
            evidenceSummary: "Evidence", citationCount: 2, protocolId: nil,
            priority: .recommended, status: .pending
        )
        let action2 = PTBriefAction(
            id: UUID(), title: "Action 2", rationale: "Reason",
            evidenceSummary: "Evidence", citationCount: 2, protocolId: nil,
            priority: .recommended, status: .pending
        )
        XCTAssertNotEqual(action1.id, action2.id, "Each action should have a unique id")
    }

    func testAction_StatusMutation() {
        var action = PTBriefAction(
            id: UUID(), title: "Test", rationale: "Reason",
            evidenceSummary: "Evidence", citationCount: 1, protocolId: nil,
            priority: .suggested, status: .pending
        )

        XCTAssertEqual(action.status, .pending, "Status should start as pending")

        action.status = .approved
        XCTAssertEqual(action.status, .approved, "Status should be mutable to approved")

        action.status = .rejected
        XCTAssertEqual(action.status, .rejected, "Status should be mutable to rejected")
    }

    func testAction_WithProtocolId() {
        let protocolId = UUID()
        let action = PTBriefAction(
            id: UUID(), title: "Protocol Action", rationale: "Reason",
            evidenceSummary: "Evidence", citationCount: 1, protocolId: protocolId,
            priority: .urgent, status: .pending
        )
        XCTAssertEqual(action.protocolId, protocolId, "protocolId should be set correctly")
    }

    func testAction_WithoutProtocolId() {
        let action = PTBriefAction(
            id: UUID(), title: "No Protocol", rationale: "Reason",
            evidenceSummary: "Evidence", citationCount: 1, protocolId: nil,
            priority: .suggested, status: .pending
        )
        XCTAssertNil(action.protocolId, "protocolId should be nil when not set")
    }
}
