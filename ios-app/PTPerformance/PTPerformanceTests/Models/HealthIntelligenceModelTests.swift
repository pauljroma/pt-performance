//
//  HealthIntelligenceModelTests.swift
//  PTPerformanceTests
//
//  Comprehensive unit tests for Health Intelligence model types
//  Tests LabAnalysis, ParsedLabResult, RecoveryImpactAnalysis, and SupplementRecommendation
//  Includes edge cases for empty results, invalid values, and missing reference ranges
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

// MARK: - HealthScore Threshold Tests

final class HealthScoreThresholdTests: XCTestCase {

    // MARK: - Score Boundary Tests

    func testHealthScoreColor_ExactBoundary80() {
        let analysis = createAnalysisWithScore(80)
        XCTAssertEqual(analysis.healthScoreColor, "green")
    }

    func testHealthScoreColor_JustBelow80() {
        let analysis = createAnalysisWithScore(79)
        XCTAssertEqual(analysis.healthScoreColor, "yellow")
    }

    func testHealthScoreColor_ExactBoundary60() {
        let analysis = createAnalysisWithScore(60)
        XCTAssertEqual(analysis.healthScoreColor, "yellow")
    }

    func testHealthScoreColor_JustBelow60() {
        let analysis = createAnalysisWithScore(59)
        XCTAssertEqual(analysis.healthScoreColor, "red")
    }

    func testHealthScoreColor_MinimumValue() {
        let analysis = createAnalysisWithScore(0)
        XCTAssertEqual(analysis.healthScoreColor, "red")
    }

    func testHealthScoreColor_MaximumValue() {
        let analysis = createAnalysisWithScore(100)
        XCTAssertEqual(analysis.healthScoreColor, "green")
    }

    func testHealthScoreColor_NegativeValue() {
        // Edge case: negative scores should be handled
        let analysis = createAnalysisWithScore(-10)
        XCTAssertEqual(analysis.healthScoreColor, "red")
    }

    // MARK: - Score Text Boundary Tests

    func testHealthScoreText_ExactBoundary90() {
        XCTAssertEqual(createAnalysisWithScore(90).healthScoreText, "Excellent")
    }

    func testHealthScoreText_ExactBoundary89() {
        XCTAssertEqual(createAnalysisWithScore(89).healthScoreText, "Very Good")
    }

    func testHealthScoreText_ExactBoundary80() {
        XCTAssertEqual(createAnalysisWithScore(80).healthScoreText, "Very Good")
    }

    func testHealthScoreText_ExactBoundary79() {
        XCTAssertEqual(createAnalysisWithScore(79).healthScoreText, "Good")
    }

    func testHealthScoreText_ExactBoundary70() {
        XCTAssertEqual(createAnalysisWithScore(70).healthScoreText, "Good")
    }

    func testHealthScoreText_ExactBoundary69() {
        XCTAssertEqual(createAnalysisWithScore(69).healthScoreText, "Fair")
    }

    func testHealthScoreText_ExactBoundary60() {
        XCTAssertEqual(createAnalysisWithScore(60).healthScoreText, "Fair")
    }

    func testHealthScoreText_ExactBoundary59() {
        XCTAssertEqual(createAnalysisWithScore(59).healthScoreText, "Needs Attention")
    }

    // MARK: - Helper Methods

    private func createAnalysisWithScore(_ score: Int) -> LabAnalysis {
        LabAnalysis(
            analysisId: "test",
            analysisText: "Test",
            recommendations: [],
            biomarkerAnalyses: [],
            trainingCorrelations: [],
            sleepCorrelations: [],
            overallHealthScore: score,
            priorityActions: [],
            medicalDisclaimer: "Disclaimer",
            cached: false
        )
    }
}

// MARK: - LabResult Parsing Edge Cases

final class LabResultParsingEdgeCasesTests: XCTestCase {

    // MARK: - Empty Results Tests

    func testLabAnalysis_EmptyBiomarkerAnalyses() {
        let analysis = LabAnalysis(
            analysisId: "empty-test",
            analysisText: "No biomarkers available",
            recommendations: [],
            biomarkerAnalyses: [],
            trainingCorrelations: [],
            sleepCorrelations: [],
            overallHealthScore: 50,
            priorityActions: [],
            medicalDisclaimer: "Disclaimer",
            cached: false
        )

        XCTAssertTrue(analysis.biomarkerAnalyses.isEmpty)
        XCTAssertTrue(analysis.concerningBiomarkers.isEmpty)
        XCTAssertTrue(analysis.optimalBiomarkers.isEmpty)
    }

    func testLabAnalysis_OnlyOptimalBiomarkers() {
        let biomarkers = [
            BiomarkerAnalysis(
                biomarkerType: "vitamin_d",
                name: "Vitamin D",
                value: 50.0,
                unit: "ng/mL",
                status: .optimal,
                interpretation: "Perfect"
            ),
            BiomarkerAnalysis(
                biomarkerType: "b12",
                name: "Vitamin B12",
                value: 500.0,
                unit: "pg/mL",
                status: .optimal,
                interpretation: "Perfect"
            )
        ]

        let analysis = LabAnalysis(
            analysisId: "optimal-test",
            analysisText: "All optimal",
            recommendations: [],
            biomarkerAnalyses: biomarkers,
            trainingCorrelations: [],
            sleepCorrelations: [],
            overallHealthScore: 100,
            priorityActions: [],
            medicalDisclaimer: "Disclaimer",
            cached: false
        )

        XCTAssertEqual(analysis.optimalBiomarkers.count, 2)
        XCTAssertTrue(analysis.concerningBiomarkers.isEmpty)
    }

    func testLabAnalysis_OnlyConcerningBiomarkers() {
        let biomarkers = [
            BiomarkerAnalysis(
                biomarkerType: "iron",
                name: "Iron",
                value: 20.0,
                unit: "ug/dL",
                status: .low,
                interpretation: "Below optimal"
            ),
            BiomarkerAnalysis(
                biomarkerType: "glucose",
                name: "Glucose",
                value: 150.0,
                unit: "mg/dL",
                status: .high,
                interpretation: "Above optimal"
            ),
            BiomarkerAnalysis(
                biomarkerType: "crp",
                name: "C-Reactive Protein",
                value: 10.0,
                unit: "mg/L",
                status: .critical,
                interpretation: "Needs immediate attention"
            )
        ]

        let analysis = LabAnalysis(
            analysisId: "concerning-test",
            analysisText: "Multiple concerns",
            recommendations: [],
            biomarkerAnalyses: biomarkers,
            trainingCorrelations: [],
            sleepCorrelations: [],
            overallHealthScore: 30,
            priorityActions: [],
            medicalDisclaimer: "Disclaimer",
            cached: false
        )

        XCTAssertEqual(analysis.concerningBiomarkers.count, 3)
        XCTAssertTrue(analysis.optimalBiomarkers.isEmpty)
    }

    // MARK: - Invalid Value Tests

    func testBiomarkerAnalysis_ZeroValue() throws {
        let json = """
        {
            "biomarker_type": "test",
            "name": "Test Marker",
            "value": 0.0,
            "unit": "units",
            "status": "low",
            "interpretation": "No value detected"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let analysis = try decoder.decode(BiomarkerAnalysis.self, from: json)

        XCTAssertEqual(analysis.value, 0.0)
        XCTAssertEqual(analysis.status, .low)
    }

    func testBiomarkerAnalysis_NegativeValue() throws {
        let json = """
        {
            "biomarker_type": "temperature_delta",
            "name": "Temperature Change",
            "value": -2.5,
            "unit": "degrees",
            "status": "normal",
            "interpretation": "Normal variation"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let analysis = try decoder.decode(BiomarkerAnalysis.self, from: json)

        XCTAssertEqual(analysis.value, -2.5)
    }

    func testBiomarkerAnalysis_VeryLargeValue() throws {
        let json = """
        {
            "biomarker_type": "platelets",
            "name": "Platelet Count",
            "value": 450000.0,
            "unit": "cells/uL",
            "status": "normal",
            "interpretation": "Within range"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let analysis = try decoder.decode(BiomarkerAnalysis.self, from: json)

        XCTAssertEqual(analysis.value, 450000.0)
    }

    func testBiomarkerAnalysis_VerySmallDecimalValue() throws {
        let json = """
        {
            "biomarker_type": "tsh",
            "name": "TSH",
            "value": 0.0001,
            "unit": "mIU/L",
            "status": "low",
            "interpretation": "Below range"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let analysis = try decoder.decode(BiomarkerAnalysis.self, from: json)

        XCTAssertEqual(analysis.value, 0.0001, accuracy: 0.00001)
    }

    // MARK: - Missing Reference Ranges Tests

    func testBiomarkerTrendPoint_NoRanges_DefaultsToNormal() {
        let point = BiomarkerTrendPoint(
            date: Date(),
            value: 100.0,
            biomarkerType: "custom_marker",
            unit: "units",
            optimalLow: nil,
            optimalHigh: nil,
            normalLow: nil,
            normalHigh: nil
        )

        XCTAssertEqual(point.status, .normal)
    }

    func testBiomarkerTrendPoint_OnlyOptimalRange() {
        let point = BiomarkerTrendPoint(
            date: Date(),
            value: 50.0,
            biomarkerType: "test",
            unit: "units",
            optimalLow: 40.0,
            optimalHigh: 60.0,
            normalLow: nil,
            normalHigh: nil
        )

        XCTAssertEqual(point.status, .optimal)
    }

    func testBiomarkerTrendPoint_OnlyNormalRange() {
        let point = BiomarkerTrendPoint(
            date: Date(),
            value: 50.0,
            biomarkerType: "test",
            unit: "units",
            optimalLow: nil,
            optimalHigh: nil,
            normalLow: 30.0,
            normalHigh: 100.0
        )

        // Value is within normal but no optimal defined
        XCTAssertEqual(point.status, .normal)
    }

    func testBiomarkerTrendPoint_PartialOptimalRange_LowOnly() {
        let point = BiomarkerTrendPoint(
            date: Date(),
            value: 50.0,
            biomarkerType: "test",
            unit: "units",
            optimalLow: 40.0,
            optimalHigh: nil,
            normalLow: 30.0,
            normalHigh: 100.0
        )

        // With partial optimal range, should fallback to normal check
        XCTAssertEqual(point.status, .normal)
    }

    // MARK: - Partial Data Tests

    func testLabAnalysis_MissingOptionalCorrelations() throws {
        let json = """
        {
            "analysis_id": "partial-test",
            "analysis_text": "Partial data",
            "recommendations": ["Recommendation 1"],
            "biomarker_analyses": [],
            "training_correlations": [],
            "sleep_correlations": [],
            "overall_health_score": 75,
            "priority_actions": [],
            "medical_disclaimer": "Disclaimer",
            "cached": false
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let analysis = try decoder.decode(LabAnalysis.self, from: json)

        XCTAssertTrue(analysis.trainingCorrelations.isEmpty)
        XCTAssertTrue(analysis.sleepCorrelations.isEmpty)
        XCTAssertEqual(analysis.recommendations.count, 1)
    }

    // MARK: - Special Characters in Text

    func testLabAnalysis_SpecialCharactersInText() throws {
        let json = """
        {
            "analysis_id": "special-chars",
            "analysis_text": "Patient's vitamin D level is <30 ng/mL & needs attention. Consider 5000 IU/day.",
            "recommendations": ["Take vitamin D3 >= 2000 IU/day", "Retest in 3-6 months"],
            "biomarker_analyses": [],
            "training_correlations": [],
            "sleep_correlations": [],
            "overall_health_score": 65,
            "priority_actions": ["Schedule follow-up"],
            "medical_disclaimer": "This is not medical advice. Consult your doctor.",
            "cached": false
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let analysis = try decoder.decode(LabAnalysis.self, from: json)

        XCTAssertTrue(analysis.analysisText.contains("<"))
        XCTAssertTrue(analysis.analysisText.contains("&"))
        XCTAssertTrue(analysis.recommendations.first?.contains(">=") ?? false)
    }

    func testTrainingCorrelation_UnicodeCharacters() {
        let correlation = TrainingCorrelation(
            factor: "High-intensity training 🏋️",
            relationship: "May affect cortisol levels",
            recommendation: "Monitor recovery metrics"
        )

        XCTAssertTrue(correlation.factor.contains("🏋️"))
    }
}

// MARK: - LabResult Categorization Tests

final class LabResultCategorizationTests: XCTestCase {

    func testBiomarkerStatus_AllStatusTypes() {
        let statuses: [BiomarkerStatus] = [.optimal, .normal, .low, .high, .critical]

        for status in statuses {
            XCTAssertFalse(status.displayText.isEmpty)
            XCTAssertFalse(status.color.isEmpty)
            XCTAssertFalse(status.iconName.isEmpty)
        }
    }

    func testLabAnalysis_MixedStatusBiomarkers() {
        let biomarkers = [
            BiomarkerAnalysis(biomarkerType: "a", name: "A", value: 1, unit: "u", status: .optimal, interpretation: ""),
            BiomarkerAnalysis(biomarkerType: "b", name: "B", value: 2, unit: "u", status: .normal, interpretation: ""),
            BiomarkerAnalysis(biomarkerType: "c", name: "C", value: 3, unit: "u", status: .low, interpretation: ""),
            BiomarkerAnalysis(biomarkerType: "d", name: "D", value: 4, unit: "u", status: .high, interpretation: ""),
            BiomarkerAnalysis(biomarkerType: "e", name: "E", value: 5, unit: "u", status: .critical, interpretation: "")
        ]

        let analysis = LabAnalysis(
            analysisId: "mixed",
            analysisText: "Mixed",
            recommendations: [],
            biomarkerAnalyses: biomarkers,
            trainingCorrelations: [],
            sleepCorrelations: [],
            overallHealthScore: 60,
            priorityActions: [],
            medicalDisclaimer: "",
            cached: false
        )

        XCTAssertEqual(analysis.optimalBiomarkers.count, 1)
        XCTAssertEqual(analysis.concerningBiomarkers.count, 3) // low, high, critical
    }
}
