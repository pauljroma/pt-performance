//
//  KPIDashboardViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for KPIDashboardViewModel
//  Tests initial state, guardrail evaluation, trend mapping, export data,
//  computed properties, and incident filtering.
//

import XCTest
@testable import PTPerformance

// MARK: - Tests

@MainActor
final class KPIDashboardViewModelTests: XCTestCase {

    // MARK: - Properties

    private var sut: KPIDashboardViewModel!

    // MARK: - Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        sut = KPIDashboardViewModel()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_DashboardIsNil() {
        XCTAssertNil(sut.dashboard, "dashboard should be nil initially")
    }

    func testInitialState_OpenIncidentsIsEmpty() {
        XCTAssertTrue(sut.openIncidents.isEmpty, "openIncidents should be empty initially")
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading, "isLoading should be false initially")
    }

    func testInitialState_LastErrorIsNil() {
        XCTAssertNil(sut.lastError, "lastError should be nil initially")
    }

    func testInitialState_TrendsAreNil() {
        XCTAssertNil(sut.ptWauTrend, "ptWauTrend should be nil initially")
        XCTAssertNil(sut.athleteWauTrend, "athleteWauTrend should be nil initially")
        XCTAssertNil(sut.citationTrend, "citationTrend should be nil initially")
        XCTAssertNil(sut.latencyTrend, "latencyTrend should be nil initially")
    }

    // MARK: - Guardrail Evaluation Tests

    func testAllGuardrailsMet_WhenNoDashboard_ReturnsFalse() {
        XCTAssertFalse(sut.allGuardrailsMet, "allGuardrailsMet should be false when dashboard is nil")
    }

    func testAllGuardrailsMet_WhenAllMet_ReturnsTrue() {
        sut.dashboard = makeDashboard(
            ptWau: 0.70,
            athleteWau: 0.65,
            citationCoverage: 0.97,
            p95LatencyMs: 3000,
            unresolvedHighSeverity: 0
        )

        XCTAssertTrue(sut.allGuardrailsMet, "allGuardrailsMet should be true when all metrics meet targets")
    }

    func testAllGuardrailsMet_WhenPTBelowTarget_ReturnsFalse() {
        sut.dashboard = makeDashboard(
            ptWau: 0.50,
            athleteWau: 0.65,
            citationCoverage: 0.97,
            p95LatencyMs: 3000,
            unresolvedHighSeverity: 0
        )

        XCTAssertFalse(sut.allGuardrailsMet, "allGuardrailsMet should be false when PT WAU is below target")
    }

    func testAllGuardrailsMet_WhenAthleteBelowTarget_ReturnsFalse() {
        sut.dashboard = makeDashboard(
            ptWau: 0.70,
            athleteWau: 0.50,
            citationCoverage: 0.97,
            p95LatencyMs: 3000,
            unresolvedHighSeverity: 0
        )

        XCTAssertFalse(sut.allGuardrailsMet, "allGuardrailsMet should be false when athlete WAU is below target")
    }

    func testAllGuardrailsMet_WhenCitationBelowTarget_ReturnsFalse() {
        sut.dashboard = makeDashboard(
            ptWau: 0.70,
            athleteWau: 0.65,
            citationCoverage: 0.90,
            p95LatencyMs: 3000,
            unresolvedHighSeverity: 0
        )

        XCTAssertFalse(sut.allGuardrailsMet, "allGuardrailsMet should be false when citation coverage is below target")
    }

    func testAllGuardrailsMet_WhenLatencyAboveTarget_ReturnsFalse() {
        sut.dashboard = makeDashboard(
            ptWau: 0.70,
            athleteWau: 0.65,
            citationCoverage: 0.97,
            p95LatencyMs: 6000,
            unresolvedHighSeverity: 0
        )

        XCTAssertFalse(sut.allGuardrailsMet, "allGuardrailsMet should be false when latency is above target")
    }

    func testAllGuardrailsMet_WhenSafetyNotMet_ReturnsFalse() {
        sut.dashboard = makeDashboard(
            ptWau: 0.70,
            athleteWau: 0.65,
            citationCoverage: 0.97,
            p95LatencyMs: 3000,
            unresolvedHighSeverity: 2
        )

        XCTAssertFalse(sut.allGuardrailsMet, "allGuardrailsMet should be false when there are unresolved high-severity incidents")
    }

    // MARK: - GuardrailsNotMet Count Tests

    func testGuardrailsNotMet_WhenNoDashboard_ReturnsFive() {
        XCTAssertEqual(sut.guardrailsNotMet, 5, "guardrailsNotMet should return 5 when dashboard is nil")
    }

    func testGuardrailsNotMet_WhenAllMet_ReturnsZero() {
        sut.dashboard = makeDashboard(
            ptWau: 0.70,
            athleteWau: 0.65,
            citationCoverage: 0.97,
            p95LatencyMs: 3000,
            unresolvedHighSeverity: 0
        )

        XCTAssertEqual(sut.guardrailsNotMet, 0, "guardrailsNotMet should return 0 when all targets met")
    }

    func testGuardrailsNotMet_WhenTwoNotMet_ReturnsTwo() {
        sut.dashboard = makeDashboard(
            ptWau: 0.50,
            athleteWau: 0.65,
            citationCoverage: 0.97,
            p95LatencyMs: 6000,
            unresolvedHighSeverity: 0
        )

        XCTAssertEqual(sut.guardrailsNotMet, 2, "guardrailsNotMet should return 2 when PT WAU and latency fail")
    }

    func testGuardrailsNotMet_WhenAllNotMet_ReturnsFive() {
        sut.dashboard = makeDashboard(
            ptWau: 0.40,
            athleteWau: 0.40,
            citationCoverage: 0.80,
            p95LatencyMs: 8000,
            unresolvedHighSeverity: 3
        )

        XCTAssertEqual(sut.guardrailsNotMet, 5, "guardrailsNotMet should return 5 when all metrics fail targets")
    }

    // MARK: - Summary Status Tests

    func testSummaryStatus_WhenNoDashboard_ReturnsLoading() {
        XCTAssertEqual(sut.summaryStatus, "Loading...", "summaryStatus should return Loading... when dashboard is nil")
    }

    func testSummaryStatus_WhenAllMet_ReturnsAllGuardrailsMet() {
        sut.dashboard = makeDashboard(
            ptWau: 0.70,
            athleteWau: 0.65,
            citationCoverage: 0.97,
            p95LatencyMs: 3000,
            unresolvedHighSeverity: 0
        )

        XCTAssertEqual(sut.summaryStatus, "All guardrails met")
    }

    func testSummaryStatus_WhenOneNotMet_ReturnsSingular() {
        sut.dashboard = makeDashboard(
            ptWau: 0.50,
            athleteWau: 0.65,
            citationCoverage: 0.97,
            p95LatencyMs: 3000,
            unresolvedHighSeverity: 0
        )

        XCTAssertEqual(sut.summaryStatus, "1 guardrail needs attention")
    }

    func testSummaryStatus_WhenMultipleNotMet_ReturnsPlural() {
        sut.dashboard = makeDashboard(
            ptWau: 0.50,
            athleteWau: 0.40,
            citationCoverage: 0.80,
            p95LatencyMs: 3000,
            unresolvedHighSeverity: 0
        )

        XCTAssertEqual(sut.summaryStatus, "3 guardrails need attention")
    }

    // MARK: - Guardrail Alerts Tests

    func testGuardrailAlerts_WhenNoDashboard_ReturnsEmpty() {
        XCTAssertTrue(sut.guardrailAlerts.isEmpty, "guardrailAlerts should be empty when dashboard is nil")
    }

    func testGuardrailAlerts_WhenAllMet_ReturnsEmpty() {
        sut.dashboard = makeDashboard(
            ptWau: 0.70,
            athleteWau: 0.65,
            citationCoverage: 0.97,
            p95LatencyMs: 3000,
            unresolvedHighSeverity: 0
        )

        XCTAssertTrue(sut.guardrailAlerts.isEmpty, "guardrailAlerts should be empty when all targets met")
    }

    func testGuardrailAlerts_WhenPTBelowTarget_ContainsPTAlert() {
        sut.dashboard = makeDashboard(
            ptWau: 0.50,
            athleteWau: 0.65,
            citationCoverage: 0.97,
            p95LatencyMs: 3000,
            unresolvedHighSeverity: 0
        )

        let alerts = sut.guardrailAlerts
        XCTAssertEqual(alerts.count, 1, "Should have 1 alert for PT WAU")
        XCTAssertEqual(alerts.first?.guardrail, "PT Weekly Active Usage")
    }

    func testGuardrailAlerts_WhenAllNotMet_ContainsFiveAlerts() {
        sut.dashboard = makeDashboard(
            ptWau: 0.40,
            athleteWau: 0.40,
            citationCoverage: 0.80,
            p95LatencyMs: 8000,
            unresolvedHighSeverity: 3
        )

        XCTAssertEqual(sut.guardrailAlerts.count, 5, "Should have 5 alerts when all guardrails fail")
    }

    func testGuardrailAlerts_SafetyAlert_HasCriticalSeverity() {
        sut.dashboard = makeDashboard(
            ptWau: 0.70,
            athleteWau: 0.65,
            citationCoverage: 0.97,
            p95LatencyMs: 3000,
            unresolvedHighSeverity: 2
        )

        let safetyAlert = sut.guardrailAlerts.first { $0.guardrail == "Unresolved High-Severity Incidents" }
        XCTAssertNotNil(safetyAlert, "Safety alert should exist")
        XCTAssertEqual(safetyAlert?.severity, .critical, "Safety alert should have critical severity")
        XCTAssertEqual(safetyAlert?.targetValue, "0", "Safety alert target should be 0")
    }

    func testGuardrailAlerts_LatencyAlert_ContainsCorrectValues() {
        sut.dashboard = makeDashboard(
            ptWau: 0.70,
            athleteWau: 0.65,
            citationCoverage: 0.97,
            p95LatencyMs: 6000,
            unresolvedHighSeverity: 0
        )

        let latencyAlert = sut.guardrailAlerts.first { $0.guardrail == "p95 Summary Latency" }
        XCTAssertNotNil(latencyAlert, "Latency alert should exist")
        XCTAssertEqual(latencyAlert?.currentValue, "6000ms")
        XCTAssertEqual(latencyAlert?.targetValue, "5000ms")
    }

    func testGuardrailAlerts_CitationAlert_ContainsCorrectValues() {
        sut.dashboard = makeDashboard(
            ptWau: 0.70,
            athleteWau: 0.65,
            citationCoverage: 0.88,
            p95LatencyMs: 3000,
            unresolvedHighSeverity: 0
        )

        let citationAlert = sut.guardrailAlerts.first { $0.guardrail == "AI Citation Coverage" }
        XCTAssertNotNil(citationAlert, "Citation alert should exist")
        XCTAssertEqual(citationAlert?.currentValue, "88%")
        XCTAssertEqual(citationAlert?.targetValue, "95%")
    }

    func testGuardrailAlerts_HaveUniqueIds() {
        sut.dashboard = makeDashboard(
            ptWau: 0.40,
            athleteWau: 0.40,
            citationCoverage: 0.80,
            p95LatencyMs: 8000,
            unresolvedHighSeverity: 3
        )

        let alerts = sut.guardrailAlerts
        let ids = Set(alerts.map { $0.id })
        XCTAssertEqual(ids.count, alerts.count, "All alerts should have unique IDs")
    }

    // MARK: - Trend Mapping Tests

    func testMapTrend_NilMetric_ReturnsStable() {
        let result = sut.mapTrend(nil)
        XCTAssertEqual(result, .stable, "Nil metric should map to .stable")
    }

    func testMapTrend_NilChangePct_ReturnsStable() {
        let metric = EFTrendMetric(current: 100, previous: 90, changePct: nil)
        let result = sut.mapTrend(metric)
        XCTAssertEqual(result, .stable, "Nil changePct should map to .stable")
    }

    func testMapTrend_PositiveLargeChange_ReturnsUp() {
        let metric = EFTrendMetric(current: 110, previous: 100, changePct: 10.0)
        let result = sut.mapTrend(metric)
        XCTAssertEqual(result, .up, "changePct > 1.0 should map to .up")
    }

    func testMapTrend_NegativeLargeChange_ReturnsDown() {
        let metric = EFTrendMetric(current: 90, previous: 100, changePct: -10.0)
        let result = sut.mapTrend(metric)
        XCTAssertEqual(result, .down, "changePct < -1.0 should map to .down")
    }

    func testMapTrend_SmallPositiveChange_ReturnsStable() {
        let metric = EFTrendMetric(current: 101, previous: 100, changePct: 0.5)
        let result = sut.mapTrend(metric)
        XCTAssertEqual(result, .stable, "changePct between -1.0 and 1.0 should map to .stable")
    }

    func testMapTrend_SmallNegativeChange_ReturnsStable() {
        let metric = EFTrendMetric(current: 99, previous: 100, changePct: -0.5)
        let result = sut.mapTrend(metric)
        XCTAssertEqual(result, .stable, "changePct between -1.0 and 1.0 should map to .stable")
    }

    func testMapTrend_ExactlyPositiveOne_ReturnsStable() {
        let metric = EFTrendMetric(current: 101, previous: 100, changePct: 1.0)
        let result = sut.mapTrend(metric)
        XCTAssertEqual(result, .stable, "changePct == 1.0 should map to .stable (threshold is >1.0)")
    }

    func testMapTrend_ExactlyNegativeOne_ReturnsStable() {
        let metric = EFTrendMetric(current: 99, previous: 100, changePct: -1.0)
        let result = sut.mapTrend(metric)
        XCTAssertEqual(result, .stable, "changePct == -1.0 should map to .stable (threshold is <-1.0)")
    }

    func testMapTrend_JustAbovePositiveThreshold_ReturnsUp() {
        let metric = EFTrendMetric(current: 101, previous: 100, changePct: 1.01)
        let result = sut.mapTrend(metric)
        XCTAssertEqual(result, .up, "changePct just above 1.0 should map to .up")
    }

    func testMapTrend_JustBelowNegativeThreshold_ReturnsDown() {
        let metric = EFTrendMetric(current: 99, previous: 100, changePct: -1.01)
        let result = sut.mapTrend(metric)
        XCTAssertEqual(result, .down, "changePct just below -1.0 should map to .down")
    }

    func testMapTrend_ZeroChange_ReturnsStable() {
        let metric = EFTrendMetric(current: 100, previous: 100, changePct: 0.0)
        let result = sut.mapTrend(metric)
        XCTAssertEqual(result, .stable, "changePct == 0 should map to .stable")
    }

    // MARK: - Incident Filtering Tests

    func testFilterIncidents_WhenEmpty_ReturnsEmpty() {
        let result = sut.filterIncidents(minSeverity: .critical)
        XCTAssertTrue(result.isEmpty, "Should return empty array when no incidents")
    }

    func testFilterIncidents_BySeverity_ReturnsCorrectResults() {
        sut.openIncidents = [
            makeIncident(severity: .critical),
            makeIncident(severity: .high),
            makeIncident(severity: .medium),
            makeIncident(severity: .low)
        ]

        let criticalOnly = sut.filterIncidents(minSeverity: .critical)
        XCTAssertEqual(criticalOnly.count, 1, "Should return only critical incidents")

        let highAndAbove = sut.filterIncidents(minSeverity: .high)
        XCTAssertEqual(highAndAbove.count, 2, "Should return critical and high incidents")

        let mediumAndAbove = sut.filterIncidents(minSeverity: .medium)
        XCTAssertEqual(mediumAndAbove.count, 3, "Should return critical, high, and medium incidents")

        let all = sut.filterIncidents(minSeverity: .low)
        XCTAssertEqual(all.count, 4, "Should return all incidents when filtering by .low")
    }

    func testIncidentsOfType_ReturnsMatchingType() {
        sut.openIncidents = [
            makeIncident(type: .painThreshold),
            makeIncident(type: .painThreshold),
            makeIncident(type: .vitalAnomaly),
            makeIncident(type: .aiUncertainty)
        ]

        let painIncidents = sut.incidents(ofType: .painThreshold)
        XCTAssertEqual(painIncidents.count, 2, "Should return 2 pain threshold incidents")

        let vitalIncidents = sut.incidents(ofType: .vitalAnomaly)
        XCTAssertEqual(vitalIncidents.count, 1, "Should return 1 vital anomaly incident")

        let missedEscalations = sut.incidents(ofType: .missedEscalation)
        XCTAssertTrue(missedEscalations.isEmpty, "Should return empty for types not present")
    }

    // MARK: - Urgent Incidents Tests

    func testUrgentIncidents_WhenEmpty_ReturnsEmpty() {
        XCTAssertTrue(sut.urgentIncidents.isEmpty, "urgentIncidents should be empty with no incidents")
    }

    func testUrgentIncidents_ReturnsHighSeverityUnresolved() {
        sut.openIncidents = [
            makeIncident(severity: .critical, status: .open),
            makeIncident(severity: .high, status: .open),
            makeIncident(severity: .medium, status: .open),
            makeIncident(severity: .high, status: .resolved),
            makeIncident(severity: .low, status: .open)
        ]

        let urgent = sut.urgentIncidents
        XCTAssertEqual(urgent.count, 2, "Should return only unresolved high/critical incidents")
    }

    func testUrgentIncidents_ExcludesDismissed() {
        sut.openIncidents = [
            makeIncident(severity: .critical, status: .dismissed),
            makeIncident(severity: .high, status: .dismissed)
        ]

        XCTAssertTrue(sut.urgentIncidents.isEmpty, "Dismissed incidents should not be urgent")
    }

    // MARK: - Incidents Needing Escalation Tests

    func testIncidentsNeedingEscalation_WhenEmpty_ReturnsEmpty() {
        XCTAssertTrue(sut.incidentsNeedingEscalation.isEmpty, "Should be empty with no incidents")
    }

    func testIncidentsNeedingEscalation_ReturnsHighSeverityNotEscalated() {
        let escalatedId = UUID()
        sut.openIncidents = [
            makeIncident(severity: .critical, status: .open, escalatedTo: nil),
            makeIncident(severity: .high, status: .open, escalatedTo: escalatedId),
            makeIncident(severity: .high, status: .open, escalatedTo: nil),
            makeIncident(severity: .medium, status: .open, escalatedTo: nil)
        ]

        let needEscalation = sut.incidentsNeedingEscalation
        XCTAssertEqual(needEscalation.count, 2, "Should return high/critical incidents not yet escalated")
    }

    // MARK: - Export Data Tests

    func testGenerateExportData_WhenNoDashboard_ReturnsNil() {
        XCTAssertNil(sut.generateExportData(), "generateExportData should return nil when dashboard is nil")
    }

    func testGenerateExportData_ContainsAllSections() {
        sut.dashboard = makeDashboard()

        guard let exportData = sut.generateExportData() else {
            XCTFail("generateExportData should not return nil when dashboard exists")
            return
        }

        XCTAssertNotNil(exportData["period_start"], "Export data should contain period_start")
        XCTAssertNotNil(exportData["period_end"], "Export data should contain period_end")
        XCTAssertNotNil(exportData["generated_at"], "Export data should contain generated_at")
        XCTAssertNotNil(exportData["pt_metrics"], "Export data should contain pt_metrics")
        XCTAssertNotNil(exportData["athlete_metrics"], "Export data should contain athlete_metrics")
        XCTAssertNotNil(exportData["ai_metrics"], "Export data should contain ai_metrics")
        XCTAssertNotNil(exportData["safety_metrics"], "Export data should contain safety_metrics")
        XCTAssertNotNil(exportData["open_incidents"], "Export data should contain open_incidents")
    }

    func testGenerateExportData_PTMetricsAreCorrect() {
        sut.dashboard = makeDashboard(ptWau: 0.72)

        guard let exportData = sut.generateExportData(),
              let ptMetrics = exportData["pt_metrics"] as? [String: Any] else {
            XCTFail("Export data should contain pt_metrics dictionary")
            return
        }

        XCTAssertEqual(ptMetrics["total_pts"] as? Int, 25)
        XCTAssertEqual(ptMetrics["weekly_active_pts"] as? Int, 18)
        XCTAssertEqual(ptMetrics["wau_percentage"] as? Double, 0.72)
        XCTAssertEqual(ptMetrics["meets_target"] as? Bool, true)
    }

    func testGenerateExportData_AIMetricsContainTargetFlags() {
        sut.dashboard = makeDashboard(citationCoverage: 0.90, p95LatencyMs: 6000)

        guard let exportData = sut.generateExportData(),
              let aiMetrics = exportData["ai_metrics"] as? [String: Any] else {
            XCTFail("Export data should contain ai_metrics dictionary")
            return
        }

        XCTAssertEqual(aiMetrics["citation_meets_target"] as? Bool, false,
                       "Citation below 0.95 should be false")
        XCTAssertEqual(aiMetrics["latency_meets_target"] as? Bool, false,
                       "Latency above 5000ms should be false")
    }

    func testGenerateExportData_SafetyMetricsAreCorrect() {
        sut.dashboard = makeDashboard(unresolvedHighSeverity: 3, totalIncidents: 15)

        guard let exportData = sut.generateExportData(),
              let safetyMetrics = exportData["safety_metrics"] as? [String: Any] else {
            XCTFail("Export data should contain safety_metrics dictionary")
            return
        }

        XCTAssertEqual(safetyMetrics["total_incidents"] as? Int, 15)
        XCTAssertEqual(safetyMetrics["unresolved_high_severity"] as? Int, 3)
        XCTAssertEqual(safetyMetrics["meets_target"] as? Bool, false)
    }

    func testGenerateExportData_IncludesOpenIncidents() {
        sut.dashboard = makeDashboard()
        sut.openIncidents = [
            makeIncident(type: .painThreshold, severity: .high),
            makeIncident(type: .vitalAnomaly, severity: .medium)
        ]

        guard let exportData = sut.generateExportData(),
              let incidents = exportData["open_incidents"] as? [[String: Any]] else {
            XCTFail("Export data should contain open_incidents array")
            return
        }

        XCTAssertEqual(incidents.count, 2, "Export should include all open incidents")

        let firstIncident = incidents[0]
        XCTAssertNotNil(firstIncident["id"], "Incident export should contain id")
        XCTAssertNotNil(firstIncident["type"], "Incident export should contain type")
        XCTAssertNotNil(firstIncident["severity"], "Incident export should contain severity")
        XCTAssertNotNil(firstIncident["status"], "Incident export should contain status")
        XCTAssertNotNil(firstIncident["description"], "Incident export should contain description")
        XCTAssertNotNil(firstIncident["age_seconds"], "Incident export should contain age_seconds")
    }

    func testGenerateExportData_DatesAreISO8601() {
        sut.dashboard = makeDashboard()

        guard let exportData = sut.generateExportData(),
              let periodStart = exportData["period_start"] as? String,
              let generatedAt = exportData["generated_at"] as? String else {
            XCTFail("Export should contain date strings")
            return
        }

        let formatter = ISO8601DateFormatter()
        XCTAssertNotNil(formatter.date(from: periodStart), "period_start should be valid ISO8601")
        XCTAssertNotNil(formatter.date(from: generatedAt), "generated_at should be valid ISO8601")
    }

    func testGenerateExportData_EmptyIncidentsProducesEmptyArray() {
        sut.dashboard = makeDashboard()
        sut.openIncidents = []

        guard let exportData = sut.generateExportData(),
              let incidents = exportData["open_incidents"] as? [[String: Any]] else {
            XCTFail("Export should contain open_incidents array")
            return
        }

        XCTAssertTrue(incidents.isEmpty, "open_incidents should be empty when no incidents")
    }

    // MARK: - Text Summary Tests

    func testGenerateTextSummary_WhenNoDashboard_ReturnsUnavailable() {
        let summary = sut.generateTextSummary()
        XCTAssertEqual(summary, "Dashboard not available")
    }

    func testGenerateTextSummary_ContainsReportTitle() {
        sut.dashboard = makeDashboard()

        let summary = sut.generateTextSummary()
        XCTAssertTrue(summary.contains("X2Index KPI Dashboard Report"), "Summary should contain report title")
    }

    func testGenerateTextSummary_ContainsSectionHeaders() {
        sut.dashboard = makeDashboard()

        let summary = sut.generateTextSummary()
        XCTAssertTrue(summary.contains("NORTH STAR GUARDRAILS"), "Should contain guardrails section")
        XCTAssertTrue(summary.contains("SUMMARY"), "Should contain summary section")
    }

    func testGenerateTextSummary_ShowsOKForMetTargets() {
        sut.dashboard = makeDashboard(
            ptWau: 0.70,
            athleteWau: 0.65,
            citationCoverage: 0.97,
            p95LatencyMs: 3000,
            unresolvedHighSeverity: 0
        )

        let summary = sut.generateTextSummary()
        let okCount = summary.components(separatedBy: "[OK]").count - 1
        XCTAssertEqual(okCount, 5, "Should show [OK] for all 5 met guardrails")
    }

    func testGenerateTextSummary_ShowsBelowForUnmetTargets() {
        sut.dashboard = makeDashboard(
            ptWau: 0.50,
            athleteWau: 0.50,
            citationCoverage: 0.90,
            p95LatencyMs: 6000,
            unresolvedHighSeverity: 2
        )

        let summary = sut.generateTextSummary()
        XCTAssertTrue(summary.contains("[BELOW]"), "Should indicate below-target metrics")
        XCTAssertTrue(summary.contains("[ABOVE]"), "Should indicate above-target metrics")
    }

    func testGenerateTextSummary_IncludesIncidentSection_WhenIncidentsExist() {
        sut.dashboard = makeDashboard()
        sut.openIncidents = [
            makeIncident(type: .painThreshold, severity: .high)
        ]

        let summary = sut.generateTextSummary()
        XCTAssertTrue(summary.contains("OPEN INCIDENTS (1)"), "Summary should show incident count")
    }

    func testGenerateTextSummary_OmitsIncidentSection_WhenNoIncidents() {
        sut.dashboard = makeDashboard()
        sut.openIncidents = []

        let summary = sut.generateTextSummary()
        XCTAssertFalse(summary.contains("OPEN INCIDENTS"), "Should not have incident section when empty")
    }

    func testGenerateTextSummary_TruncatesMoreThanFiveIncidents() {
        sut.dashboard = makeDashboard()
        sut.openIncidents = (0..<8).map { _ in
            makeIncident(type: .painThreshold, severity: .high)
        }

        let summary = sut.generateTextSummary()
        XCTAssertTrue(summary.contains("... and 3 more"), "Should indicate additional incidents beyond 5")
    }

    func testGenerateTextSummary_ContainsGeneratedTimestamp() {
        sut.dashboard = makeDashboard()

        let summary = sut.generateTextSummary()
        XCTAssertTrue(summary.contains("Generated:"), "Should contain generated timestamp")
    }

    func testGenerateTextSummary_ContainsMetricValues() {
        sut.dashboard = makeDashboard(ptWau: 0.70, p95LatencyMs: 3200)

        let summary = sut.generateTextSummary()
        XCTAssertTrue(summary.contains("70%"), "Summary should contain PT WAU percentage")
        XCTAssertTrue(summary.contains("3200ms"), "Summary should contain latency value")
        XCTAssertTrue(summary.contains("target: 65%"), "Summary should contain PT WAU target")
        XCTAssertTrue(summary.contains("target: 5000ms"), "Summary should contain latency target")
    }

    func testGenerateTextSummary_ContainsTotalCounts() {
        sut.dashboard = makeDashboard()

        let summary = sut.generateTextSummary()
        XCTAssertTrue(summary.contains("Total PTs: 25"), "Should contain total PTs")
        XCTAssertTrue(summary.contains("Total Athletes: 450"), "Should contain total athletes")
    }

    // MARK: - Guardrail Boundary Tests

    func testGuardrails_AtExactTargetValues() {
        sut.dashboard = makeDashboard(
            ptWau: 0.65,
            athleteWau: 0.60,
            citationCoverage: 0.95,
            p95LatencyMs: 5000,
            unresolvedHighSeverity: 0
        )

        XCTAssertTrue(sut.allGuardrailsMet, "All guardrails should be met at exact target values")
        XCTAssertEqual(sut.guardrailsNotMet, 0)
    }

    func testGuardrails_JustBelowTargetValues() {
        sut.dashboard = makeDashboard(
            ptWau: 0.6499,
            athleteWau: 0.5999,
            citationCoverage: 0.9499,
            p95LatencyMs: 5001,
            unresolvedHighSeverity: 1
        )

        XCTAssertFalse(sut.allGuardrailsMet)
        XCTAssertEqual(sut.guardrailsNotMet, 5)
    }

    // MARK: - KPIAlert Identity Tests

    func testKPIAlert_IdIsComposedOfGuardrailAndValues() {
        let alert = KPIAlert(
            guardrail: "Test Guardrail",
            currentValue: "50%",
            targetValue: "65%",
            severity: .warning,
            message: "Test message"
        )

        XCTAssertEqual(alert.id, "Test Guardrail-50%-65%")
    }

    // MARK: - DateRangePeriod Tests

    func testDateRangePeriod_DaysMapping() {
        XCTAssertEqual(DateRangePeriod.today.days, 1)
        XCTAssertEqual(DateRangePeriod.lastWeek.days, 7)
        XCTAssertEqual(DateRangePeriod.lastMonth.days, 30)
        XCTAssertEqual(DateRangePeriod.lastQuarter.days, 90)
    }

    func testDateRangePeriod_DisplayNames() {
        XCTAssertEqual(DateRangePeriod.today.displayName, "Today")
        XCTAssertEqual(DateRangePeriod.lastWeek.displayName, "Week")
        XCTAssertEqual(DateRangePeriod.lastMonth.displayName, "Month")
        XCTAssertEqual(DateRangePeriod.lastQuarter.displayName, "Quarter")
    }

    // MARK: - KPITrend Display Properties Tests

    func testKPITrend_DisplayNames() {
        XCTAssertEqual(KPITrend.up.displayName, "Trending Up")
        XCTAssertEqual(KPITrend.down.displayName, "Trending Down")
        XCTAssertEqual(KPITrend.stable.displayName, "Stable")
    }

    func testKPITrend_IconNames() {
        XCTAssertEqual(KPITrend.up.iconName, "arrow.up.right")
        XCTAssertEqual(KPITrend.down.iconName, "arrow.down.right")
        XCTAssertEqual(KPITrend.stable.iconName, "arrow.right")
    }

    // MARK: - Helper Methods

    /// Create a KPIDashboard with customizable metrics
    private func makeDashboard(
        ptWau: Double = 0.72,
        athleteWau: Double = 0.70,
        citationCoverage: Double = 0.97,
        p95LatencyMs: Int = 3200,
        unresolvedHighSeverity: Int = 0,
        totalIncidents: Int = 12
    ) -> KPIDashboard {
        KPIDashboard(
            periodStart: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
            periodEnd: Date(),
            ptMetrics: PTMetrics(
                totalPTs: 25,
                weeklyActivePTs: 18,
                wauPercentage: ptWau,
                avgPrepTimeSeconds: 180,
                briefsOpened: 156,
                plansAssigned: 42
            ),
            athleteMetrics: AthleteMetrics(
                totalAthletes: 450,
                weeklyActiveAthletes: 315,
                wauPercentage: athleteWau,
                checkInsCompleted: 1250,
                taskCompletionRate: 0.82,
                avgStreakDays: 4.5
            ),
            aiMetrics: AIMetrics(
                claimsGenerated: 2400,
                citationCoverage: citationCoverage,
                avgConfidence: 0.85,
                p95LatencyMs: p95LatencyMs,
                abstentions: 48,
                uncertaintyFlags: 120
            ),
            safetyMetrics: SafetyMetrics(
                totalIncidents: totalIncidents,
                unresolvedHighSeverity: unresolvedHighSeverity,
                escalationsTriggered: 8,
                thresholdBreaches: 15
            )
        )
    }

    /// Create a SafetyIncident for testing
    private func makeIncident(
        type: SafetyIncident.IncidentType = .painThreshold,
        severity: SafetyIncident.Severity = .high,
        status: SafetyIncident.IncidentStatus = .open,
        escalatedTo: UUID? = nil
    ) -> SafetyIncident {
        SafetyIncident(
            id: UUID(),
            athleteId: UUID(),
            incidentType: type,
            severity: severity,
            description: "Test incident",
            status: status,
            escalatedTo: escalatedTo
        )
    }
}
