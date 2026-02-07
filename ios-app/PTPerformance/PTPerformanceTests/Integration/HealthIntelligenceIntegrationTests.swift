//
//  HealthIntelligenceIntegrationTests.swift
//  PTPerformanceTests
//
//  Integration tests for Health Intelligence features
//  Tests end-to-end flows for lab upload, fasting timer, and recovery logging
//

import XCTest
@testable import PTPerformance

// MARK: - Lab PDF Upload Flow Tests

final class LabPDFUploadFlowTests: XCTestCase {

    // MARK: - ParseLabPDFResponse Flow Tests

    func testLabUploadFlow_ParseResponseToParsedLabResult() throws {
        // Simulate a successful parse response
        let json = """
        {
            "success": true,
            "provider": "quest",
            "test_date": "2024-01-15",
            "patient_name": "John Doe",
            "ordering_physician": "Dr. Smith",
            "biomarkers": [
                {
                    "name": "Hemoglobin",
                    "value": 14.5,
                    "unit": "g/dL",
                    "reference_range": "12.0-17.0",
                    "reference_low": 12.0,
                    "reference_high": 17.0,
                    "flag": "normal",
                    "category": "Hematology"
                },
                {
                    "name": "Vitamin D",
                    "value": 25.0,
                    "unit": "ng/mL",
                    "reference_range": "30.0-100.0",
                    "reference_low": 30.0,
                    "reference_high": 100.0,
                    "flag": "low",
                    "category": "Vitamins"
                }
            ],
            "confidence": "high",
            "parsing_notes": ["Successfully extracted all markers"]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(ParseLabPDFResponse.self, from: json)

        // Convert to ParsedLabResult
        let parsedResult = response.toParsedLabResult()

        XCTAssertNotNil(parsedResult)
        XCTAssertEqual(parsedResult?.provider, .quest)
        XCTAssertEqual(parsedResult?.patientName, "John Doe")
        XCTAssertEqual(parsedResult?.biomarkers.count, 2)
        XCTAssertEqual(parsedResult?.confidence, .high)

        // Verify biomarker flags are preserved
        let lowBiomarker = parsedResult?.biomarkers.first { $0.flag == .low }
        XCTAssertNotNil(lowBiomarker)
        XCTAssertEqual(lowBiomarker?.name, "Vitamin D")
    }

    func testLabUploadFlow_FailedParse() throws {
        let json = """
        {
            "success": false,
            "biomarkers": [],
            "confidence": "low",
            "error": "Unable to parse PDF - format not recognized"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(ParseLabPDFResponse.self, from: json)

        // Should return nil on failure
        let parsedResult = response.toParsedLabResult()
        XCTAssertNil(parsedResult)
        XCTAssertEqual(response.error, "Unable to parse PDF - format not recognized")
    }

    // MARK: - Biomarker Conversion Flow Tests

    func testBiomarkerConversionFlow_ToLabMarker() {
        let parsedBiomarker = ParsedBiomarker(
            id: UUID(),
            name: "Testosterone",
            value: 650.0,
            unit: "ng/dL",
            referenceRange: "300-1000",
            referenceLow: 300.0,
            referenceHigh: 1000.0,
            flag: .normal,
            category: "Hormones",
            isSelected: true
        )

        let labMarker = parsedBiomarker.toLabMarker()

        XCTAssertEqual(labMarker.name, "Testosterone")
        XCTAssertEqual(labMarker.value, 650.0)
        XCTAssertEqual(labMarker.unit, "ng/dL")
        XCTAssertEqual(labMarker.referenceMin, 300.0)
        XCTAssertEqual(labMarker.referenceMax, 1000.0)
        XCTAssertEqual(labMarker.status, .normal)
    }

    func testBiomarkerConversionFlow_FlagMapping() {
        let testCases: [(BiomarkerFlag?, MarkerStatus)] = [
            (.normal, .normal),
            (.low, .low),
            (.high, .high),
            (.critical, .critical),
            (nil, .normal) // Default case
        ]

        for (flag, expectedStatus) in testCases {
            let biomarker = ParsedBiomarker(
                name: "Test",
                value: 50.0,
                unit: "units",
                flag: flag
            )

            let labMarker = biomarker.toLabMarker()
            XCTAssertEqual(labMarker.status, expectedStatus, "Flag \(String(describing: flag)) should map to \(expectedStatus)")
        }
    }

    // MARK: - Lab Analysis Response Flow Tests

    func testLabAnalysisFlow_ResponseProcessing() throws {
        let json = """
        {
            "analysis_id": "analysis-123",
            "analysis_text": "Your lab results show generally good health with some areas for improvement.",
            "recommendations": [
                "Consider vitamin D supplementation",
                "Monitor ferritin levels"
            ],
            "biomarker_analyses": [
                {
                    "biomarker_type": "vitamin_d",
                    "name": "Vitamin D",
                    "value": 28.0,
                    "unit": "ng/mL",
                    "status": "low",
                    "interpretation": "Below optimal range - supplementation recommended"
                }
            ],
            "training_correlations": [
                {
                    "factor": "High training volume",
                    "relationship": "May deplete vitamin D stores",
                    "recommendation": "Consider higher dose during heavy training blocks"
                }
            ],
            "sleep_correlations": [],
            "overall_health_score": 78,
            "priority_actions": ["Start vitamin D supplementation"],
            "medical_disclaimer": "This is not medical advice. Consult your doctor.",
            "cached": false
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let analysis = try decoder.decode(LabAnalysis.self, from: json)

        // Verify analysis properties
        XCTAssertEqual(analysis.overallHealthScore, 78)
        XCTAssertEqual(analysis.healthScoreText, "Good")
        XCTAssertEqual(analysis.healthScoreColor, "yellow")

        // Verify concerning biomarkers
        XCTAssertEqual(analysis.concerningBiomarkers.count, 1)
        XCTAssertEqual(analysis.concerningBiomarkers.first?.status, .low)

        // Verify optimal biomarkers is empty
        XCTAssertTrue(analysis.optimalBiomarkers.isEmpty)
    }
}

// MARK: - Fasting Timer Accuracy Tests

final class FastingTimerAccuracyTests: XCTestCase {

    func testFastingLog_ProgressCalculation_50Percent() {
        let startTime = Date().addingTimeInterval(-8 * 3600) // 8 hours ago
        let log = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent,
            startedAt: startTime,
            endedAt: nil,
            plannedEndAt: nil,
            targetHours: 16,
            actualHours: nil,
            wasBrokenEarly: nil,
            breakReason: nil,
            moodStart: nil,
            moodEnd: nil,
            hungerLevel: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )

        // 8/16 = 50%
        XCTAssertEqual(log.progressPercent, 0.5, accuracy: 0.05)
    }

    func testFastingLog_ProgressCalculation_Complete() {
        let startTime = Date().addingTimeInterval(-18 * 3600) // 18 hours ago
        let log = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent,
            startedAt: startTime,
            endedAt: nil,
            plannedEndAt: nil,
            targetHours: 16,
            actualHours: nil,
            wasBrokenEarly: nil,
            breakReason: nil,
            moodStart: nil,
            moodEnd: nil,
            hungerLevel: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )

        // Should be capped at 1.0
        XCTAssertEqual(log.progressPercent, 1.0, accuracy: 0.01)
    }

    func testFastingLog_ProgressCalculation_CompletedFast() {
        let startTime = Date().addingTimeInterval(-20 * 3600)
        let endTime = startTime.addingTimeInterval(17 * 3600) // 17 hour fast

        let log = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent,
            startedAt: startTime,
            endedAt: endTime,
            plannedEndAt: nil,
            targetHours: 16,
            actualHours: 17.0,
            wasBrokenEarly: nil,
            breakReason: nil,
            moodStart: nil,
            moodEnd: nil,
            hungerLevel: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )

        // 17/16 > 1.0, capped at 1.0
        XCTAssertEqual(log.progressPercent, 1.0, accuracy: 0.01)
    }

    func testFastingLog_IsActive() {
        // Active fast (no end time)
        let activeFast = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent,
            startedAt: Date(),
            endedAt: nil,
            plannedEndAt: nil,
            targetHours: 16,
            actualHours: nil,
            wasBrokenEarly: nil,
            breakReason: nil,
            moodStart: nil,
            moodEnd: nil,
            hungerLevel: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )
        XCTAssertTrue(activeFast.isActive)

        // Completed fast (has end time)
        let completedFast = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent,
            startedAt: Date().addingTimeInterval(-20 * 3600),
            endedAt: Date().addingTimeInterval(-4 * 3600),
            plannedEndAt: nil,
            targetHours: 16,
            actualHours: 16.0,
            wasBrokenEarly: nil,
            breakReason: nil,
            moodStart: nil,
            moodEnd: nil,
            hungerLevel: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )
        XCTAssertFalse(completedFast.isActive)
    }

    func testFastingType_TargetHours() {
        // Verify fasting types have correct target hours
        XCTAssertEqual(FastingType.intermittent.targetHours, 16)
        XCTAssertEqual(FastingType.extended.targetHours, 24)
        XCTAssertEqual(FastingType.waterOnly.targetHours, 24)
        XCTAssertEqual(FastingType.modified.targetHours, 18)
        XCTAssertEqual(FastingType.custom.targetHours, 16) // Default
    }
}

// MARK: - Recovery Session Logging Tests

final class RecoverySessionLoggingTests: XCTestCase {

    func testRecoverySession_Creation() {
        let id = UUID()
        let patientId = UUID()
        let loggedAt = Date()

        let session = RecoverySession(
            id: id,
            patientId: patientId,
            protocolType: .saunaTraditional,
            loggedAt: loggedAt,
            durationSeconds: 1200, // 20 minutes
            temperature: 180.0,
            heartRateAvg: 120,
            heartRateMax: 140,
            perceivedEffort: 7,
            rating: 4,
            notes: "Good session",
            createdAt: loggedAt
        )

        XCTAssertEqual(session.id, id)
        XCTAssertEqual(session.patientId, patientId)
        XCTAssertEqual(session.protocolType, .saunaTraditional)
        XCTAssertEqual(session.durationSeconds, 1200)
        XCTAssertEqual(session.temperature, 180.0)
    }

    func testRecoverySession_ColdPlunge() {
        let session = RecoverySession(
            id: UUID(),
            patientId: UUID(),
            protocolType: .coldPlunge,
            loggedAt: Date(),
            durationSeconds: 180, // 3 minutes
            temperature: 50.0, // Fahrenheit
            heartRateAvg: 60,
            heartRateMax: 65,
            perceivedEffort: 9,
            rating: 5,
            notes: "Very cold!",
            createdAt: Date()
        )

        XCTAssertEqual(session.protocolType, .coldPlunge)
        XCTAssertEqual(session.durationSeconds, 180)
        XCTAssertEqual(session.temperature, 50.0)
    }

    func testRecoveryProtocolTypes_Coverage() {
        // Verify all protocol types are testable
        let protocols: [RecoveryProtocolType] = [
            .saunaTraditional, .saunaInfrared, .saunaSteam,
            .coldPlunge, .coldShower, .iceBath, .contrast
        ]

        for protocolType in protocols {
            let session = RecoverySession(
                id: UUID(),
                patientId: UUID(),
                protocolType: protocolType,
                loggedAt: Date(),
                durationSeconds: 600,
                temperature: nil,
                heartRateAvg: nil,
                heartRateMax: nil,
                perceivedEffort: nil,
                rating: nil,
                notes: nil,
                createdAt: Date()
            )

            XCTAssertEqual(session.protocolType, protocolType)
            XCTAssertFalse(protocolType.displayName.isEmpty)
            XCTAssertFalse(protocolType.icon.isEmpty)
        }
    }
}

// MARK: - Recovery Impact Analysis Integration Tests

final class RecoveryImpactAnalysisIntegrationTests: XCTestCase {

    func testImpactAnalysis_SufficientDataCheck() {
        // With sufficient data
        let withData = RecoveryImpactAnalysis(
            insights: [],
            correlations: [],
            personalizedRecommendations: [],
            analysisDate: Date(),
            dataPointsAnalyzed: 10
        )
        XCTAssertTrue(withData.hasSufficientData)

        // Without sufficient data
        let withoutData = RecoveryImpactAnalysis(
            insights: [],
            correlations: [],
            personalizedRecommendations: [],
            analysisDate: Date(),
            dataPointsAnalyzed: 3
        )
        XCTAssertFalse(withoutData.hasSufficientData)

        // Edge case: exactly at threshold
        let atThreshold = RecoveryImpactAnalysis(
            insights: [],
            correlations: [],
            personalizedRecommendations: [],
            analysisDate: Date(),
            dataPointsAnalyzed: 5
        )
        XCTAssertTrue(atThreshold.hasSufficientData)
    }

    func testImpactAnalysis_InsightCategorization() {
        let insights = [
            RecoveryInsight(
                type: .hrvImprovement,
                metric: .hrv,
                protocolType: .saunaTraditional,
                impactPercentage: 15.0,
                confidence: 0.85,
                description: "HRV improved",
                dataPoints: 10
            ),
            RecoveryInsight(
                type: .sleepDecline,
                metric: .sleepDuration,
                protocolType: .coldPlunge,
                impactPercentage: -5.0,
                confidence: 0.70,
                description: "Sleep declined",
                dataPoints: 8
            )
        ]

        let analysis = RecoveryImpactAnalysis(
            insights: insights,
            correlations: [],
            personalizedRecommendations: [],
            analysisDate: Date(),
            dataPointsAnalyzed: 18
        )

        XCTAssertEqual(analysis.positiveInsights.count, 1)
        XCTAssertEqual(analysis.negativeInsights.count, 1)
        XCTAssertEqual(analysis.topInsight?.type, .hrvImprovement) // Higher confidence
    }

    func testImpactAnalysis_CorrelationStrength() {
        let strongCorrelation = RecoveryCorrelation(
            protocolType: .saunaTraditional,
            metric: .hrv,
            correlationCoefficient: 0.75,
            pValue: 0.01,
            sampleSize: 20,
            averageImpact: 15.0
        )

        let weakCorrelation = RecoveryCorrelation(
            protocolType: .coldPlunge,
            metric: .sleepDuration,
            correlationCoefficient: 0.25,
            pValue: 0.10,
            sampleSize: 8,
            averageImpact: 5.0
        )

        XCTAssertEqual(strongCorrelation.strength, "Strong")
        XCTAssertEqual(weakCorrelation.strength, "Weak")
        XCTAssertTrue(strongCorrelation.isSignificant)
        XCTAssertFalse(weakCorrelation.isSignificant)
    }
}

// MARK: - Cross-Feature Integration Tests

final class CrossFeatureIntegrationTests: XCTestCase {

    func testFastingAndRecovery_DataFlowConsistency() {
        // Test that fasting and recovery can coexist
        let patientId = UUID()

        let fastingLog = FastingLog(
            id: UUID(),
            patientId: patientId,
            fastingType: .intermittent,
            startedAt: Date().addingTimeInterval(-16 * 3600),
            endedAt: Date(),
            plannedEndAt: nil,
            targetHours: 16,
            actualHours: 16.0,
            wasBrokenEarly: false,
            breakReason: nil,
            moodStart: 7,
            moodEnd: 8,
            hungerLevel: 5,
            energyLevel: 7,
            notes: nil,
            createdAt: Date()
        )

        let recoverySession = RecoverySession(
            id: UUID(),
            patientId: patientId,
            protocolType: .saunaTraditional,
            loggedAt: Date(),
            durationSeconds: 1200,
            temperature: 180.0,
            heartRateAvg: 110,
            heartRateMax: 130,
            perceivedEffort: 6,
            rating: 4,
            notes: nil,
            createdAt: Date()
        )

        // Both should have same patient ID
        XCTAssertEqual(fastingLog.patientId, recoverySession.patientId)
        XCTAssertFalse(fastingLog.isActive) // Fast completed
        XCTAssertEqual(recoverySession.durationMinutes, 20)
    }

    func testLabAndFasting_HealthDataCorrelation() {
        // Test lab markers and fasting data can be correlated
        let labMarker = LabMarker(
            id: UUID(),
            name: "Glucose",
            value: 85.0,
            unit: "mg/dL",
            referenceMin: 70.0,
            referenceMax: 100.0,
            status: .normal
        )

        let fastingLog = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent,
            startedAt: Date().addingTimeInterval(-16 * 3600),
            endedAt: Date(),
            plannedEndAt: nil,
            targetHours: 16,
            actualHours: 16.0,
            wasBrokenEarly: nil,
            breakReason: nil,
            moodStart: nil,
            moodEnd: nil,
            hungerLevel: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )

        // Both markers and fasting logs should be trackable
        XCTAssertEqual(labMarker.status, .normal)
        XCTAssertEqual(fastingLog.progressPercent, 1.0, accuracy: 0.01)
    }
}
