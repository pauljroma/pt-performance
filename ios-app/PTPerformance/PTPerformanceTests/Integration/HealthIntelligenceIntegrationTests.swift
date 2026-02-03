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
            fastingType: .intermittent16_8,
            startTime: startTime,
            endTime: nil,
            targetHours: 16,
            actualHours: nil,
            breakfastFood: nil,
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
            fastingType: .intermittent16_8,
            startTime: startTime,
            endTime: nil,
            targetHours: 16,
            actualHours: nil,
            breakfastFood: nil,
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
            fastingType: .intermittent16_8,
            startTime: startTime,
            endTime: endTime,
            targetHours: 16,
            actualHours: 17.0,
            breakfastFood: nil,
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
            fastingType: .intermittent16_8,
            startTime: Date(),
            endTime: nil,
            targetHours: 16,
            actualHours: nil,
            breakfastFood: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )
        XCTAssertTrue(activeFast.isActive)

        // Completed fast (has end time)
        let completedFast = FastingLog(
            id: UUID(),
            patientId: UUID(),
            fastingType: .intermittent16_8,
            startTime: Date().addingTimeInterval(-20 * 3600),
            endTime: Date().addingTimeInterval(-4 * 3600),
            targetHours: 16,
            actualHours: 16.0,
            breakfastFood: nil,
            energyLevel: nil,
            notes: nil,
            createdAt: Date()
        )
        XCTAssertFalse(completedFast.isActive)
    }

    func testFastingType_TargetHours() {
        // Verify all fasting types have correct target hours
        XCTAssertEqual(FastingType.intermittent16_8.targetHours, 16)
        XCTAssertEqual(FastingType.intermittent18_6.targetHours, 18)
        XCTAssertEqual(FastingType.intermittent20_4.targetHours, 20)
        XCTAssertEqual(FastingType.omad.targetHours, 23)
        XCTAssertEqual(FastingType.extended24.targetHours, 24)
        XCTAssertEqual(FastingType.extended36.targetHours, 36)
        XCTAssertEqual(FastingType.extended48.targetHours, 48)
        XCTAssertEqual(FastingType.custom.targetHours, 16) // Default
    }
}

// MARK: - Recovery Session Logging Tests

final class RecoverySessionLoggingTests: XCTestCase {

    func testRecoverySession_Creation() {
        let id = UUID()
        let patientId = UUID()
        let startTime = Date()

        let session = RecoverySession(
            id: id,
            patientId: patientId,
            protocolType: .sauna,
            startTime: startTime,
            duration: 1200, // 20 minutes
            temperature: 180.0,
            heartRateAvg: 120,
            heartRateMax: 140,
            perceivedEffort: 7,
            notes: "Good session",
            createdAt: startTime
        )

        XCTAssertEqual(session.id, id)
        XCTAssertEqual(session.patientId, patientId)
        XCTAssertEqual(session.protocolType, .sauna)
        XCTAssertEqual(session.duration, 1200)
        XCTAssertEqual(session.temperature, 180.0)
    }

    func testRecoverySession_ColdPlunge() {
        let session = RecoverySession(
            id: UUID(),
            patientId: UUID(),
            protocolType: .coldPlunge,
            startTime: Date(),
            duration: 180, // 3 minutes
            temperature: 50.0, // Fahrenheit
            heartRateAvg: 60,
            heartRateMax: 65,
            perceivedEffort: 9,
            notes: "Very cold!",
            createdAt: Date()
        )

        XCTAssertEqual(session.protocolType, .coldPlunge)
        XCTAssertEqual(session.duration, 180)
        XCTAssertEqual(session.temperature, 50.0)
    }

    func testRecoveryProtocolTypes_Coverage() {
        // Verify all protocol types are testable
        let protocols: [RecoveryProtocolType] = [
            .sauna, .coldPlunge, .contrast, .cryotherapy,
            .floatTank, .massage, .stretching, .meditation
        ]

        for protocolType in protocols {
            let session = RecoverySession(
                id: UUID(),
                patientId: UUID(),
                protocolType: protocolType,
                startTime: Date(),
                duration: 600,
                temperature: nil,
                heartRateAvg: nil,
                heartRateMax: nil,
                perceivedEffort: nil,
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
                protocolType: .sauna,
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
            dataPointsAnalyzed: 20
        )

        XCTAssertEqual(analysis.positiveInsights.count, 1)
        XCTAssertEqual(analysis.negativeInsights.count, 1)
        XCTAssertNotNil(analysis.topInsight)
        XCTAssertEqual(analysis.topInsight?.type, .hrvImprovement)
    }

    func testRecoveryCorrelation_SignificanceCheck() {
        // Significant correlation
        let significant = RecoveryCorrelation(
            protocolType: .sauna,
            metric: .hrv,
            correlationCoefficient: 0.65,
            pValue: 0.03, // < 0.05
            sampleSize: 10, // >= 5
            averageImpact: 12.0
        )
        XCTAssertTrue(significant.isSignificant)

        // Not significant - high p-value
        let highPValue = RecoveryCorrelation(
            protocolType: .coldPlunge,
            metric: .sleepDuration,
            correlationCoefficient: 0.50,
            pValue: 0.08, // >= 0.05
            sampleSize: 10,
            averageImpact: 8.0
        )
        XCTAssertFalse(highPValue.isSignificant)

        // Not significant - small sample
        let smallSample = RecoveryCorrelation(
            protocolType: .meditation,
            metric: .hrv,
            correlationCoefficient: 0.70,
            pValue: 0.01,
            sampleSize: 3, // < 5
            averageImpact: 15.0
        )
        XCTAssertFalse(smallSample.isSignificant)
    }
}

// MARK: - Supplement Recommendation Integration Tests

final class SupplementRecommendationIntegrationTests: XCTestCase {

    func testSupplementRecommendation_FullFlow() throws {
        let json = """
        {
            "recommendation_id": "rec-integration-test",
            "recommendations": [
                {
                    "supplement_id": "creatine-mono",
                    "name": "Creatine Monohydrate",
                    "brand": "Momentous",
                    "category": "performance",
                    "dosage": "5g daily",
                    "timing": "Post-workout or morning",
                    "evidence_rating": 5,
                    "rationale": "Most studied ergogenic supplement. Supports strength, power, and muscle building.",
                    "goal_alignment": ["muscle_building", "recovery"],
                    "purchase_url": "https://example.com/creatine",
                    "priority": "essential",
                    "warnings": []
                },
                {
                    "supplement_id": "vitamin-d3",
                    "name": "Vitamin D3",
                    "brand": "Momentous",
                    "category": "vitamins",
                    "dosage": "5000 IU daily",
                    "timing": "Morning with food",
                    "evidence_rating": 4,
                    "rationale": "Your lab results showed low vitamin D. Essential for bone health, immunity, and hormone function.",
                    "goal_alignment": ["general", "recovery"],
                    "purchase_url": "https://example.com/vitamin-d",
                    "priority": "essential",
                    "warnings": ["Take with food for better absorption"]
                }
            ],
            "stack_summary": "Foundation stack focused on performance and addressing your vitamin D deficiency",
            "total_daily_cost_estimate": "$1.50",
            "goal_coverage": {
                "muscle_building": ["Creatine Monohydrate"],
                "recovery": ["Creatine Monohydrate", "Vitamin D3"],
                "general": ["Vitamin D3"]
            },
            "interaction_warnings": [],
            "timing_schedule": {
                "morning": [
                    {"name": "Vitamin D3", "dosage": "5000 IU", "notes": "With breakfast"}
                ],
                "pre_workout": [],
                "post_workout": [
                    {"name": "Creatine Monohydrate", "dosage": "5g", "notes": "Mix with protein shake"}
                ],
                "evening": [],
                "with_meals": []
            },
            "disclaimer": "These recommendations are for informational purposes only. Consult your healthcare provider.",
            "cached": false
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(SupplementRecommendationResponse.self, from: json)

        // Verify response structure
        XCTAssertEqual(response.recommendationId, "rec-integration-test")
        XCTAssertEqual(response.recommendations.count, 2)

        // Verify recommendations
        let creatine = response.recommendations.first { $0.name == "Creatine Monohydrate" }
        XCTAssertNotNil(creatine)
        XCTAssertEqual(creatine?.priority, .essential)
        XCTAssertEqual(creatine?.evidenceRating, 5)

        let vitaminD = response.recommendations.first { $0.name == "Vitamin D3" }
        XCTAssertNotNil(vitaminD)
        XCTAssertEqual(vitaminD?.warnings.count, 1)

        // Verify goal coverage
        XCTAssertEqual(response.goalCoverage["muscle_building"]?.count, 1)
        XCTAssertEqual(response.goalCoverage["recovery"]?.count, 2)

        // Verify timing schedule
        XCTAssertEqual(response.timingSchedule.morning.count, 1)
        XCTAssertEqual(response.timingSchedule.postWorkout.count, 1)
        XCTAssertEqual(response.timingSchedule.allTimings.count, 2) // Only non-empty
    }

    func testSupplementPriority_Sorting() {
        let recommendations = [
            AISupplementRecommendation(
                supplementId: "1",
                name: "Optional Supp",
                brand: "Brand",
                category: "other",
                dosage: "1g",
                timing: "Any",
                evidenceRating: 2,
                rationale: "Nice to have",
                goalAlignment: [],
                purchaseUrl: nil,
                priority: .optional,
                warnings: []
            ),
            AISupplementRecommendation(
                supplementId: "2",
                name: "Essential Supp",
                brand: "Brand",
                category: "vitamins",
                dosage: "1g",
                timing: "Morning",
                evidenceRating: 5,
                rationale: "Critical",
                goalAlignment: [],
                purchaseUrl: nil,
                priority: .essential,
                warnings: []
            ),
            AISupplementRecommendation(
                supplementId: "3",
                name: "Recommended Supp",
                brand: "Brand",
                category: "minerals",
                dosage: "1g",
                timing: "Evening",
                evidenceRating: 4,
                rationale: "Helpful",
                goalAlignment: [],
                purchaseUrl: nil,
                priority: .recommended,
                warnings: []
            )
        ]

        let sorted = recommendations.sorted { $0.priority.sortOrder < $1.priority.sortOrder }

        XCTAssertEqual(sorted[0].priority, .essential)
        XCTAssertEqual(sorted[1].priority, .recommended)
        XCTAssertEqual(sorted[2].priority, .optional)
    }
}

// MARK: - AI Coach Integration Tests

final class AICoachIntegrationTests: XCTestCase {

    func testCoachResponse_FullFlow() throws {
        let json = """
        {
            "coaching_id": "coach-integration-test",
            "greeting": "Good morning! I've analyzed your recent data.",
            "primary_message": "Your recovery metrics look great this week. Your HRV is up 12% and sleep quality has improved.",
            "insights": [
                {
                    "category": "recovery",
                    "priority": "high",
                    "insight": "Your HRV has improved significantly after implementing the new sleep routine",
                    "action": "Continue your current sleep schedule",
                    "rationale": "Consistent sleep timing is driving better recovery"
                },
                {
                    "category": "training",
                    "priority": "medium",
                    "insight": "Training volume is slightly elevated",
                    "action": "Consider a lighter session today",
                    "rationale": "Your accumulated fatigue is above baseline"
                }
            ],
            "today_focus": "Prioritize recovery. Light mobility work is recommended.",
            "weekly_priorities": [
                "Maintain sleep consistency",
                "Add one more recovery session",
                "Monitor fatigue levels"
            ],
            "data_summary": {
                "readiness": "High - 88/100",
                "training": "4 sessions, 180 minutes total",
                "recovery": "2 sauna sessions, 1 cold plunge",
                "labs": "Last panel: 2 weeks ago - Vitamin D low"
            },
            "proactive_alerts": [
                "Your vitamin D is still below optimal - consider supplementation"
            ],
            "follow_up_questions": [
                "Would you like tips for improving vitamin D levels?",
                "How are you feeling about your current training load?"
            ],
            "disclaimer": "This is AI-generated coaching based on your data. Not medical advice."
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(UnifiedCoachResponse.self, from: json)

        // Verify response structure
        XCTAssertEqual(response.coachingId, "coach-integration-test")
        XCTAssertFalse(response.greeting.isEmpty)
        XCTAssertFalse(response.primaryMessage.isEmpty)

        // Verify insights
        XCTAssertEqual(response.insights.count, 2)
        let highPriorityInsights = response.insights.filter { $0.priority == .high }
        XCTAssertEqual(highPriorityInsights.count, 1)

        // Verify data summary
        XCTAssertTrue(response.dataSummary.readiness.contains("88"))

        // Verify proactive alerts
        XCTAssertEqual(response.proactiveAlerts.count, 1)
        XCTAssertTrue(response.proactiveAlerts.first?.contains("vitamin D") == true)

        // Verify follow-up questions
        XCTAssertEqual(response.followUpQuestions.count, 2)
    }
}
