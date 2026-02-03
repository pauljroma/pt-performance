//
//  HealthIntelligenceModelTests.swift
//  PTPerformanceTests
//
//  Comprehensive unit tests for Health Intelligence model types
//  Tests LabAnalysis, ParsedLabResult, RecoveryImpactAnalysis, and SupplementRecommendation
//

import XCTest
@testable import PTPerformance

// MARK: - LabAnalysis Tests

final class LabAnalysisTests: XCTestCase {

    // MARK: - Initialization Tests

    func testLabAnalysis_Initialization() {
        let analysis = createMockLabAnalysis()

        XCTAssertEqual(analysis.analysisId, "test-analysis-123")
        XCTAssertEqual(analysis.analysisText, "Overall health markers are within normal range")
        XCTAssertEqual(analysis.recommendations.count, 2)
        XCTAssertEqual(analysis.biomarkerAnalyses.count, 3)
        XCTAssertEqual(analysis.trainingCorrelations.count, 1)
        XCTAssertEqual(analysis.sleepCorrelations.count, 1)
        XCTAssertEqual(analysis.overallHealthScore, 85)
        XCTAssertEqual(analysis.priorityActions.count, 2)
        XCTAssertTrue(analysis.medicalDisclaimer.contains("not medical advice"))
        XCTAssertFalse(analysis.cached)
    }

    func testLabAnalysis_Identifiable() {
        let analysis = createMockLabAnalysis()
        XCTAssertEqual(analysis.id, "test-analysis-123")
    }

    // MARK: - Computed Properties Tests

    func testLabAnalysis_ConcerningBiomarkers() {
        let analysis = createMockLabAnalysis()
        let concerning = analysis.concerningBiomarkers

        // Should only include non-optimal and non-normal
        XCTAssertTrue(concerning.contains { $0.status == .low || $0.status == .high || $0.status == .critical })
        XCTAssertFalse(concerning.contains { $0.status == .optimal || $0.status == .normal })
    }

    func testLabAnalysis_OptimalBiomarkers() {
        let analysis = createMockLabAnalysis()
        let optimal = analysis.optimalBiomarkers

        XCTAssertTrue(optimal.allSatisfy { $0.status == .optimal })
    }

    func testLabAnalysis_HealthScoreColor_Green() {
        var analysis = createMockLabAnalysis(healthScore: 85)
        XCTAssertEqual(analysis.healthScoreColor, "green")

        analysis = createMockLabAnalysis(healthScore: 80)
        XCTAssertEqual(analysis.healthScoreColor, "green")

        analysis = createMockLabAnalysis(healthScore: 100)
        XCTAssertEqual(analysis.healthScoreColor, "green")
    }

    func testLabAnalysis_HealthScoreColor_Yellow() {
        var analysis = createMockLabAnalysis(healthScore: 79)
        XCTAssertEqual(analysis.healthScoreColor, "yellow")

        analysis = createMockLabAnalysis(healthScore: 60)
        XCTAssertEqual(analysis.healthScoreColor, "yellow")

        analysis = createMockLabAnalysis(healthScore: 70)
        XCTAssertEqual(analysis.healthScoreColor, "yellow")
    }

    func testLabAnalysis_HealthScoreColor_Red() {
        var analysis = createMockLabAnalysis(healthScore: 59)
        XCTAssertEqual(analysis.healthScoreColor, "red")

        analysis = createMockLabAnalysis(healthScore: 0)
        XCTAssertEqual(analysis.healthScoreColor, "red")

        analysis = createMockLabAnalysis(healthScore: 30)
        XCTAssertEqual(analysis.healthScoreColor, "red")
    }

    func testLabAnalysis_HealthScoreText() {
        XCTAssertEqual(createMockLabAnalysis(healthScore: 95).healthScoreText, "Excellent")
        XCTAssertEqual(createMockLabAnalysis(healthScore: 90).healthScoreText, "Excellent")
        XCTAssertEqual(createMockLabAnalysis(healthScore: 85).healthScoreText, "Very Good")
        XCTAssertEqual(createMockLabAnalysis(healthScore: 80).healthScoreText, "Very Good")
        XCTAssertEqual(createMockLabAnalysis(healthScore: 75).healthScoreText, "Good")
        XCTAssertEqual(createMockLabAnalysis(healthScore: 70).healthScoreText, "Good")
        XCTAssertEqual(createMockLabAnalysis(healthScore: 65).healthScoreText, "Fair")
        XCTAssertEqual(createMockLabAnalysis(healthScore: 60).healthScoreText, "Fair")
        XCTAssertEqual(createMockLabAnalysis(healthScore: 55).healthScoreText, "Needs Attention")
        XCTAssertEqual(createMockLabAnalysis(healthScore: 0).healthScoreText, "Needs Attention")
    }

    // MARK: - Codable Tests

    func testLabAnalysis_Encoding() throws {
        let analysis = createMockLabAnalysis()

        let encoder = JSONEncoder()
        let data = try encoder.encode(analysis)

        let jsonObject = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Verify snake_case keys
        XCTAssertNotNil(jsonObject["analysis_id"])
        XCTAssertNotNil(jsonObject["analysis_text"])
        XCTAssertNotNil(jsonObject["biomarker_analyses"])
        XCTAssertNotNil(jsonObject["training_correlations"])
        XCTAssertNotNil(jsonObject["sleep_correlations"])
        XCTAssertNotNil(jsonObject["overall_health_score"])
        XCTAssertNotNil(jsonObject["priority_actions"])
        XCTAssertNotNil(jsonObject["medical_disclaimer"])
    }

    func testLabAnalysis_Decoding() throws {
        let json = """
        {
            "analysis_id": "decoded-id",
            "analysis_text": "Test analysis",
            "recommendations": ["Rec 1"],
            "biomarker_analyses": [],
            "training_correlations": [],
            "sleep_correlations": [],
            "overall_health_score": 75,
            "priority_actions": ["Action 1"],
            "medical_disclaimer": "Not medical advice",
            "cached": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let analysis = try decoder.decode(LabAnalysis.self, from: json)

        XCTAssertEqual(analysis.analysisId, "decoded-id")
        XCTAssertEqual(analysis.analysisText, "Test analysis")
        XCTAssertEqual(analysis.overallHealthScore, 75)
        XCTAssertTrue(analysis.cached)
    }

    // MARK: - Edge Cases

    func testLabAnalysis_EmptyArrays() throws {
        let json = """
        {
            "analysis_id": "empty-test",
            "analysis_text": "No data",
            "recommendations": [],
            "biomarker_analyses": [],
            "training_correlations": [],
            "sleep_correlations": [],
            "overall_health_score": 0,
            "priority_actions": [],
            "medical_disclaimer": "Disclaimer",
            "cached": false
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let analysis = try decoder.decode(LabAnalysis.self, from: json)

        XCTAssertTrue(analysis.recommendations.isEmpty)
        XCTAssertTrue(analysis.biomarkerAnalyses.isEmpty)
        XCTAssertTrue(analysis.trainingCorrelations.isEmpty)
        XCTAssertTrue(analysis.sleepCorrelations.isEmpty)
        XCTAssertTrue(analysis.priorityActions.isEmpty)
        XCTAssertTrue(analysis.concerningBiomarkers.isEmpty)
        XCTAssertTrue(analysis.optimalBiomarkers.isEmpty)
    }

    // MARK: - Helper Methods

    private func createMockLabAnalysis(healthScore: Int = 85) -> LabAnalysis {
        let biomarkers = [
            BiomarkerAnalysis(
                biomarkerType: "vitamin_d",
                name: "Vitamin D",
                value: 45.0,
                unit: "ng/mL",
                status: .optimal,
                interpretation: "Optimal levels"
            ),
            BiomarkerAnalysis(
                biomarkerType: "testosterone",
                name: "Testosterone",
                value: 650.0,
                unit: "ng/dL",
                status: .normal,
                interpretation: "Normal range"
            ),
            BiomarkerAnalysis(
                biomarkerType: "ferritin",
                name: "Ferritin",
                value: 25.0,
                unit: "ng/mL",
                status: .low,
                interpretation: "Below optimal"
            )
        ]

        let trainingCorrelations = [
            TrainingCorrelation(
                factor: "High volume training",
                relationship: "May deplete iron stores",
                recommendation: "Consider iron supplementation"
            )
        ]

        let sleepCorrelations = [
            TrainingCorrelation(
                factor: "Sleep quality",
                relationship: "Vitamin D affects sleep",
                recommendation: "Maintain current levels"
            )
        ]

        return LabAnalysis(
            analysisId: "test-analysis-123",
            analysisText: "Overall health markers are within normal range",
            recommendations: ["Increase iron intake", "Continue current vitamin D regimen"],
            biomarkerAnalyses: biomarkers,
            trainingCorrelations: trainingCorrelations,
            sleepCorrelations: sleepCorrelations,
            overallHealthScore: healthScore,
            priorityActions: ["Check iron levels in 3 months", "Continue training"],
            medicalDisclaimer: "This is not medical advice. Consult your doctor.",
            cached: false
        )
    }
}

// MARK: - BiomarkerAnalysis Tests

final class BiomarkerAnalysisTests: XCTestCase {

    func testBiomarkerAnalysis_Initialization() {
        let analysis = BiomarkerAnalysis(
            biomarkerType: "hemoglobin",
            name: "Hemoglobin",
            value: 14.5,
            unit: "g/dL",
            status: .normal,
            interpretation: "Within normal range"
        )

        XCTAssertEqual(analysis.biomarkerType, "hemoglobin")
        XCTAssertEqual(analysis.name, "Hemoglobin")
        XCTAssertEqual(analysis.value, 14.5)
        XCTAssertEqual(analysis.unit, "g/dL")
        XCTAssertEqual(analysis.status, .normal)
        XCTAssertEqual(analysis.interpretation, "Within normal range")
    }

    func testBiomarkerAnalysis_Identifiable() {
        let analysis = BiomarkerAnalysis(
            biomarkerType: "test_marker",
            name: "Test",
            value: 100,
            unit: "units",
            status: .optimal,
            interpretation: "Good"
        )

        XCTAssertEqual(analysis.id, "test_marker")
    }

    func testBiomarkerAnalysis_Codable() throws {
        let json = """
        {
            "biomarker_type": "crp",
            "name": "C-Reactive Protein",
            "value": 0.5,
            "unit": "mg/L",
            "status": "optimal",
            "interpretation": "Low inflammation"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let analysis = try decoder.decode(BiomarkerAnalysis.self, from: json)

        XCTAssertEqual(analysis.biomarkerType, "crp")
        XCTAssertEqual(analysis.name, "C-Reactive Protein")
        XCTAssertEqual(analysis.value, 0.5)
        XCTAssertEqual(analysis.status, .optimal)
    }
}

// MARK: - BiomarkerStatus Tests

final class BiomarkerStatusTests: XCTestCase {

    func testBiomarkerStatus_RawValues() {
        XCTAssertEqual(BiomarkerStatus.optimal.rawValue, "optimal")
        XCTAssertEqual(BiomarkerStatus.normal.rawValue, "normal")
        XCTAssertEqual(BiomarkerStatus.low.rawValue, "low")
        XCTAssertEqual(BiomarkerStatus.high.rawValue, "high")
        XCTAssertEqual(BiomarkerStatus.critical.rawValue, "critical")
    }

    func testBiomarkerStatus_Colors() {
        XCTAssertEqual(BiomarkerStatus.optimal.color, "green")
        XCTAssertEqual(BiomarkerStatus.normal.color, "blue")
        XCTAssertEqual(BiomarkerStatus.low.color, "orange")
        XCTAssertEqual(BiomarkerStatus.high.color, "orange")
        XCTAssertEqual(BiomarkerStatus.critical.color, "red")
    }

    func testBiomarkerStatus_DisplayText() {
        XCTAssertEqual(BiomarkerStatus.optimal.displayText, "Optimal")
        XCTAssertEqual(BiomarkerStatus.normal.displayText, "Normal")
        XCTAssertEqual(BiomarkerStatus.low.displayText, "Low")
        XCTAssertEqual(BiomarkerStatus.high.displayText, "High")
        XCTAssertEqual(BiomarkerStatus.critical.displayText, "Critical")
    }

    func testBiomarkerStatus_IconName() {
        XCTAssertEqual(BiomarkerStatus.optimal.iconName, "checkmark.circle.fill")
        XCTAssertEqual(BiomarkerStatus.normal.iconName, "circle.fill")
        XCTAssertEqual(BiomarkerStatus.low.iconName, "arrow.down.circle.fill")
        XCTAssertEqual(BiomarkerStatus.high.iconName, "arrow.up.circle.fill")
        XCTAssertEqual(BiomarkerStatus.critical.iconName, "exclamationmark.triangle.fill")
    }

    func testBiomarkerStatus_Codable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for status in [BiomarkerStatus.optimal, .normal, .low, .high, .critical] {
            let data = try encoder.encode(status)
            let decoded = try decoder.decode(BiomarkerStatus.self, from: data)
            XCTAssertEqual(decoded, status)
        }
    }
}

// MARK: - TrainingCorrelation Tests

final class TrainingCorrelationTests: XCTestCase {

    func testTrainingCorrelation_Initialization() {
        let correlation = TrainingCorrelation(
            factor: "High intensity training",
            relationship: "Increases cortisol",
            recommendation: "Include recovery days"
        )

        XCTAssertEqual(correlation.factor, "High intensity training")
        XCTAssertEqual(correlation.relationship, "Increases cortisol")
        XCTAssertEqual(correlation.recommendation, "Include recovery days")
    }

    func testTrainingCorrelation_Identifiable() {
        let correlation = TrainingCorrelation(
            factor: "test_factor",
            relationship: "test",
            recommendation: "test"
        )

        XCTAssertEqual(correlation.id, "test_factor")
    }

    func testTrainingCorrelation_Codable() throws {
        let original = TrainingCorrelation(
            factor: "Volume",
            relationship: "Affects recovery",
            recommendation: "Moderate volume"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TrainingCorrelation.self, from: data)

        XCTAssertEqual(original.factor, decoded.factor)
        XCTAssertEqual(original.relationship, decoded.relationship)
        XCTAssertEqual(original.recommendation, decoded.recommendation)
    }
}

// MARK: - BiomarkerTrendPoint Tests

final class BiomarkerTrendPointTests: XCTestCase {

    func testBiomarkerTrendPoint_Initialization() {
        let date = Date()
        let point = BiomarkerTrendPoint(
            date: date,
            value: 45.0,
            biomarkerType: "vitamin_d",
            unit: "ng/mL",
            optimalLow: 40.0,
            optimalHigh: 60.0,
            normalLow: 30.0,
            normalHigh: 100.0
        )

        XCTAssertEqual(point.date, date)
        XCTAssertEqual(point.value, 45.0)
        XCTAssertEqual(point.biomarkerType, "vitamin_d")
        XCTAssertEqual(point.unit, "ng/mL")
        XCTAssertEqual(point.optimalLow, 40.0)
        XCTAssertEqual(point.optimalHigh, 60.0)
        XCTAssertEqual(point.normalLow, 30.0)
        XCTAssertEqual(point.normalHigh, 100.0)
    }

    func testBiomarkerTrendPoint_Status_Optimal() {
        let point = BiomarkerTrendPoint(
            date: Date(),
            value: 50.0,
            biomarkerType: "vitamin_d",
            unit: "ng/mL",
            optimalLow: 40.0,
            optimalHigh: 60.0,
            normalLow: 30.0,
            normalHigh: 100.0
        )

        XCTAssertEqual(point.status, .optimal)
    }

    func testBiomarkerTrendPoint_Status_Normal() {
        let point = BiomarkerTrendPoint(
            date: Date(),
            value: 35.0, // Between normal and optimal
            biomarkerType: "vitamin_d",
            unit: "ng/mL",
            optimalLow: 40.0,
            optimalHigh: 60.0,
            normalLow: 30.0,
            normalHigh: 100.0
        )

        XCTAssertEqual(point.status, .normal)
    }

    func testBiomarkerTrendPoint_Status_Low() {
        let point = BiomarkerTrendPoint(
            date: Date(),
            value: 25.0, // Below normal
            biomarkerType: "vitamin_d",
            unit: "ng/mL",
            optimalLow: 40.0,
            optimalHigh: 60.0,
            normalLow: 30.0,
            normalHigh: 100.0
        )

        XCTAssertEqual(point.status, .low)
    }

    func testBiomarkerTrendPoint_Status_High() {
        let point = BiomarkerTrendPoint(
            date: Date(),
            value: 110.0, // Above normal
            biomarkerType: "vitamin_d",
            unit: "ng/mL",
            optimalLow: 40.0,
            optimalHigh: 60.0,
            normalLow: 30.0,
            normalHigh: 100.0
        )

        XCTAssertEqual(point.status, .high)
    }

    func testBiomarkerTrendPoint_Status_Critical_Low() {
        let point = BiomarkerTrendPoint(
            date: Date(),
            value: 15.0, // Significantly below normal (< 30 * 0.7 = 21)
            biomarkerType: "vitamin_d",
            unit: "ng/mL",
            optimalLow: 40.0,
            optimalHigh: 60.0,
            normalLow: 30.0,
            normalHigh: 100.0
        )

        XCTAssertEqual(point.status, .critical)
    }

    func testBiomarkerTrendPoint_Status_Critical_High() {
        let point = BiomarkerTrendPoint(
            date: Date(),
            value: 150.0, // Significantly above normal (> 100 * 1.3 = 130)
            biomarkerType: "vitamin_d",
            unit: "ng/mL",
            optimalLow: 40.0,
            optimalHigh: 60.0,
            normalLow: 30.0,
            normalHigh: 100.0
        )

        XCTAssertEqual(point.status, .critical)
    }

    func testBiomarkerTrendPoint_Status_NoRanges() {
        let point = BiomarkerTrendPoint(
            date: Date(),
            value: 50.0,
            biomarkerType: "custom",
            unit: "units"
        )

        XCTAssertEqual(point.status, .normal) // Default when no ranges
    }
}

// MARK: - LabAnalysisErrorResponse Tests

final class LabAnalysisErrorResponseTests: XCTestCase {

    func testLabAnalysisErrorResponse_Decoding() throws {
        let json = """
        {
            "error": "Unable to parse lab results",
            "medical_disclaimer": "Please consult your doctor"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(LabAnalysisErrorResponse.self, from: json)

        XCTAssertEqual(response.error, "Unable to parse lab results")
        XCTAssertEqual(response.medicalDisclaimer, "Please consult your doctor")
    }

    func testLabAnalysisErrorResponse_NilDisclaimer() throws {
        let json = """
        {
            "error": "Network error"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(LabAnalysisErrorResponse.self, from: json)

        XCTAssertEqual(response.error, "Network error")
        XCTAssertNil(response.medicalDisclaimer)
    }
}
