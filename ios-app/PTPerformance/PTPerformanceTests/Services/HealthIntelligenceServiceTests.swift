//
//  HealthIntelligenceServiceTests.swift
//  PTPerformanceTests
//
//  Unit tests for Health Intelligence services
//  Tests AICoachService, FastingService, RecoveryService, and SupplementService
//

import XCTest
@testable import PTPerformance

// MARK: - AICoachService Tests

@MainActor
final class AICoachServiceTests: XCTestCase {

    var sut: AICoachService!

    override func setUp() async throws {
        try await super.setUp()
        sut = AICoachService.shared
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Singleton Tests

    func testSharedInstanceExists() {
        XCTAssertNotNil(AICoachService.shared)
    }

    func testSharedInstanceIsSingleton() {
        let instance1 = AICoachService.shared
        let instance2 = AICoachService.shared
        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - Initial State Tests

    func testInitialState_CurrentResponseIsNil() {
        XCTAssertNil(sut.currentResponse)
    }

    func testInitialState_ProactiveInsightsIsEmpty() {
        XCTAssertTrue(sut.proactiveInsights.isEmpty)
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading)
    }

    func testInitialState_ErrorIsNil() {
        XCTAssertNil(sut.error)
    }

    // MARK: - Published Properties

    func testPublishedProperties_Exist() {
        _ = sut.currentResponse
        _ = sut.proactiveInsights
        _ = sut.isLoading
        _ = sut.error
    }
}

// MARK: - AICoachError Tests

final class AICoachErrorTests: XCTestCase {

    func testAICoachError_NoPatientId_Description() {
        let error = AICoachError.noPatientId
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("patient") == true)
    }

    func testAICoachError_InvalidResponse_Description() {
        let error = AICoachError.invalidResponse
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("invalid") == true)
    }

    func testAICoachError_NetworkError_Description() {
        let underlyingError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Connection failed"])
        let error = AICoachError.networkError(underlyingError)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("Network") == true)
    }
}

// MARK: - UnifiedCoachResponse Tests

final class UnifiedCoachResponseTests: XCTestCase {

    func testUnifiedCoachResponse_Decoding() throws {
        let json = """
        {
            "coaching_id": "coach-123",
            "greeting": "Good morning!",
            "primary_message": "Your recovery looks good today.",
            "insights": [],
            "today_focus": "Focus on mobility work",
            "weekly_priorities": ["Increase sleep", "Add recovery sessions"],
            "data_summary": {
                "readiness": "High",
                "training": "On track",
                "recovery": "Adequate",
                "labs": "No recent data"
            },
            "proactive_alerts": ["Your HRV is declining"],
            "follow_up_questions": ["How did you sleep?", "Any soreness?"],
            "disclaimer": "Not medical advice"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(UnifiedCoachResponse.self, from: json)

        XCTAssertEqual(response.coachingId, "coach-123")
        XCTAssertEqual(response.greeting, "Good morning!")
        XCTAssertEqual(response.primaryMessage, "Your recovery looks good today.")
        XCTAssertEqual(response.todayFocus, "Focus on mobility work")
        XCTAssertEqual(response.weeklyPriorities.count, 2)
        XCTAssertEqual(response.proactiveAlerts.count, 1)
        XCTAssertEqual(response.followUpQuestions.count, 2)
    }

    func testUnifiedCoachResponse_WithInsights() throws {
        let json = """
        {
            "coaching_id": "coach-456",
            "greeting": "Hello",
            "primary_message": "Here are your insights",
            "insights": [
                {
                    "category": "recovery",
                    "priority": "high",
                    "insight": "Your HRV improved",
                    "action": "Continue current routine",
                    "rationale": "Data shows consistent improvement"
                }
            ],
            "today_focus": "Rest",
            "weekly_priorities": [],
            "data_summary": {
                "readiness": "High",
                "training": "Light",
                "recovery": "Good",
                "labs": "N/A"
            },
            "proactive_alerts": [],
            "follow_up_questions": [],
            "disclaimer": "Disclaimer"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(UnifiedCoachResponse.self, from: json)

        XCTAssertEqual(response.insights.count, 1)
        XCTAssertEqual(response.insights.first?.category, .recovery)
        XCTAssertEqual(response.insights.first?.priority, .high)
    }
}

// MARK: - CoachingInsight Tests

final class CoachingInsightTests: XCTestCase {

    func testCoachingInsight_Decoding() throws {
        let json = """
        {
            "category": "training",
            "priority": "medium",
            "insight": "You've been training hard",
            "action": "Consider a deload",
            "rationale": "Volume has been high for 3 weeks"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let insight = try decoder.decode(CoachingInsight.self, from: json)

        XCTAssertEqual(insight.category, .training)
        XCTAssertEqual(insight.priority, .medium)
        XCTAssertEqual(insight.insight, "You've been training hard")
        XCTAssertEqual(insight.action, "Consider a deload")
    }

    func testCoachingInsight_Identifiable() throws {
        let json = """
        {
            "category": "sleep",
            "priority": "high",
            "insight": "Sleep has declined",
            "action": "Improve sleep hygiene",
            "rationale": "Average sleep dropped by 1 hour"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let insight = try decoder.decode(CoachingInsight.self, from: json)

        // ID should be composed of category and insight prefix
        XCTAssertTrue(insight.id.contains("sleep"))
    }

    func testCoachingInsight_Hashable() throws {
        let json1 = """
        {
            "category": "nutrition",
            "priority": "low",
            "insight": "Protein intake is adequate",
            "action": "Maintain current diet",
            "rationale": "Meeting daily targets"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let insight1 = try decoder.decode(CoachingInsight.self, from: json1)
        let insight2 = try decoder.decode(CoachingInsight.self, from: json1)

        XCTAssertEqual(insight1, insight2)
    }
}

// MARK: - CoachingCategory Tests

final class CoachingCategoryTests: XCTestCase {

    func testCoachingCategory_RawValues() {
        XCTAssertEqual(CoachingCategory.training.rawValue, "training")
        XCTAssertEqual(CoachingCategory.recovery.rawValue, "recovery")
        XCTAssertEqual(CoachingCategory.nutrition.rawValue, "nutrition")
        XCTAssertEqual(CoachingCategory.sleep.rawValue, "sleep")
        XCTAssertEqual(CoachingCategory.labs.rawValue, "labs")
        XCTAssertEqual(CoachingCategory.general.rawValue, "general")
    }

    func testCoachingCategory_DisplayNames() {
        XCTAssertEqual(CoachingCategory.training.displayName, "Training")
        XCTAssertEqual(CoachingCategory.recovery.displayName, "Recovery")
        XCTAssertEqual(CoachingCategory.nutrition.displayName, "Nutrition")
        XCTAssertEqual(CoachingCategory.sleep.displayName, "Sleep")
        XCTAssertEqual(CoachingCategory.labs.displayName, "Labs")
        XCTAssertEqual(CoachingCategory.general.displayName, "General")
    }

    func testCoachingCategory_Icons() {
        for category in CoachingCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty)
        }
    }

    func testCoachingCategory_Colors() {
        for category in CoachingCategory.allCases {
            XCTAssertFalse(category.color.isEmpty)
        }
    }
}

// MARK: - CoachingPriority Tests

final class CoachingPriorityTests: XCTestCase {

    func testCoachingPriority_RawValues() {
        XCTAssertEqual(CoachingPriority.high.rawValue, "high")
        XCTAssertEqual(CoachingPriority.medium.rawValue, "medium")
        XCTAssertEqual(CoachingPriority.low.rawValue, "low")
    }

    func testCoachingPriority_SortOrder() {
        XCTAssertEqual(CoachingPriority.high.sortOrder, 0)
        XCTAssertEqual(CoachingPriority.medium.sortOrder, 1)
        XCTAssertEqual(CoachingPriority.low.sortOrder, 2)
    }

    func testCoachingPriority_Sorting() {
        let priorities: [CoachingPriority] = [.low, .high, .medium]
        let sorted = priorities.sorted { $0.sortOrder < $1.sortOrder }

        XCTAssertEqual(sorted, [.high, .medium, .low])
    }
}

// MARK: - DataSummary Tests

final class DataSummaryTests: XCTestCase {

    func testDataSummary_Decoding() throws {
        let json = """
        {
            "readiness": "High - 85/100",
            "training": "3 sessions this week",
            "recovery": "2 sauna sessions",
            "labs": "Last test: 2 weeks ago"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let summary = try decoder.decode(DataSummary.self, from: json)

        XCTAssertEqual(summary.readiness, "High - 85/100")
        XCTAssertEqual(summary.training, "3 sessions this week")
        XCTAssertEqual(summary.recovery, "2 sauna sessions")
        XCTAssertEqual(summary.labs, "Last test: 2 weeks ago")
    }

    func testDataSummary_Hashable() throws {
        let summary1 = DataSummary(
            readiness: "High",
            training: "Good",
            recovery: "Adequate",
            labs: "N/A"
        )
        let summary2 = DataSummary(
            readiness: "High",
            training: "Good",
            recovery: "Adequate",
            labs: "N/A"
        )

        XCTAssertEqual(summary1, summary2)
    }
}

// MARK: - AICoachMessage Tests

final class AICoachMessageTests: XCTestCase {

    func testAICoachMessage_UserMessage() {
        let message = AICoachMessage(
            role: .user,
            content: "How is my recovery?"
        )

        XCTAssertNotNil(message.id)
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content, "How is my recovery?")
        XCTAssertNotNil(message.timestamp)
        XCTAssertNil(message.insights)
        XCTAssertNil(message.suggestedQuestions)
    }

    func testAICoachMessage_CoachMessage() {
        let insights = [
            CoachingInsight(
                category: .recovery,
                priority: .high,
                insight: "Test insight",
                action: "Take action",
                rationale: "Because"
            )
        ]

        let message = AICoachMessage(
            role: .coach,
            content: "Your recovery is excellent!",
            insights: insights,
            suggestedQuestions: ["What should I do next?"]
        )

        XCTAssertEqual(message.role, .coach)
        XCTAssertEqual(message.insights?.count, 1)
        XCTAssertEqual(message.suggestedQuestions?.count, 1)
    }

    func testAICoachMessage_SystemMessage() {
        let message = AICoachMessage(
            role: .system,
            content: "Session started"
        )

        XCTAssertEqual(message.role, .system)
    }

    func testAICoachMessage_Equatable() {
        let id = UUID()
        let message1 = AICoachMessage(
            id: id,
            role: .user,
            content: "Test"
        )
        let message2 = AICoachMessage(
            id: id,
            role: .user,
            content: "Different content"
        )

        // Equality based on ID only
        XCTAssertEqual(message1, message2)
    }
}

// MARK: - AICoachMessageRole Tests

final class AICoachMessageRoleTests: XCTestCase {

    func testAICoachMessageRole_RawValues() {
        XCTAssertEqual(AICoachMessageRole.user.rawValue, "user")
        XCTAssertEqual(AICoachMessageRole.coach.rawValue, "coach")
        XCTAssertEqual(AICoachMessageRole.system.rawValue, "system")
    }

    func testAICoachMessageRole_Codable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for role in [AICoachMessageRole.user, .coach, .system] {
            let data = try encoder.encode(role)
            let decoded = try decoder.decode(AICoachMessageRole.self, from: data)
            XCTAssertEqual(decoded, role)
        }
    }
}

// MARK: - API Response Parsing Tests

final class HealthIntelligenceAPIResponseTests: XCTestCase {

    // MARK: - Lab Analysis Response Parsing

    func testLabAnalysis_CompleteResponseParsing() throws {
        let json = """
        {
            "analysis_id": "test-analysis-001",
            "analysis_text": "Your lab results show overall good health with some areas for improvement.",
            "recommendations": [
                "Increase Vitamin D supplementation to 5000 IU daily",
                "Consider adding Omega-3 fatty acids",
                "Monitor iron levels in 3 months"
            ],
            "biomarker_analyses": [
                {
                    "biomarker_type": "vitamin_d",
                    "name": "Vitamin D, 25-OH",
                    "value": 32.0,
                    "unit": "ng/mL",
                    "status": "normal",
                    "interpretation": "Just above the minimum range. Optimal is 40-60 ng/mL."
                },
                {
                    "biomarker_type": "ferritin",
                    "name": "Ferritin",
                    "value": 28.0,
                    "unit": "ng/mL",
                    "status": "low",
                    "interpretation": "Below optimal for athletic performance."
                }
            ],
            "training_correlations": [
                {
                    "factor": "High volume training",
                    "relationship": "May deplete iron stores faster",
                    "recommendation": "Consider iron supplementation with vitamin C"
                }
            ],
            "sleep_correlations": [
                {
                    "factor": "Vitamin D levels",
                    "relationship": "Suboptimal D may affect sleep quality",
                    "recommendation": "Take D3 in the morning"
                }
            ],
            "overall_health_score": 78,
            "priority_actions": [
                "Address iron deficiency",
                "Optimize Vitamin D"
            ],
            "medical_disclaimer": "This analysis is for informational purposes only.",
            "cached": false
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let analysis = try decoder.decode(LabAnalysis.self, from: json)

        XCTAssertEqual(analysis.analysisId, "test-analysis-001")
        XCTAssertEqual(analysis.recommendations.count, 3)
        XCTAssertEqual(analysis.biomarkerAnalyses.count, 2)
        XCTAssertEqual(analysis.trainingCorrelations.count, 1)
        XCTAssertEqual(analysis.sleepCorrelations.count, 1)
        XCTAssertEqual(analysis.overallHealthScore, 78)
        XCTAssertEqual(analysis.priorityActions.count, 2)
        XCTAssertFalse(analysis.cached)
    }

    func testLabAnalysis_MinimalValidResponse() throws {
        let json = """
        {
            "analysis_id": "minimal",
            "analysis_text": "Minimal analysis",
            "recommendations": [],
            "biomarker_analyses": [],
            "training_correlations": [],
            "sleep_correlations": [],
            "overall_health_score": 50,
            "priority_actions": [],
            "medical_disclaimer": "Disclaimer",
            "cached": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let analysis = try decoder.decode(LabAnalysis.self, from: json)

        XCTAssertEqual(analysis.analysisId, "minimal")
        XCTAssertTrue(analysis.recommendations.isEmpty)
        XCTAssertTrue(analysis.biomarkerAnalyses.isEmpty)
        XCTAssertTrue(analysis.cached)
    }

    func testLabAnalysis_CachedResponse() throws {
        let json = """
        {
            "analysis_id": "cached-001",
            "analysis_text": "Cached analysis",
            "recommendations": ["Recommendation 1"],
            "biomarker_analyses": [],
            "training_correlations": [],
            "sleep_correlations": [],
            "overall_health_score": 85,
            "priority_actions": [],
            "medical_disclaimer": "Disclaimer",
            "cached": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let analysis = try decoder.decode(LabAnalysis.self, from: json)

        XCTAssertTrue(analysis.cached)
    }

    // MARK: - Error Response Parsing

    func testLabAnalysisError_StandardError() throws {
        let json = """
        {
            "error": "Unable to analyze lab results. Please try again later.",
            "medical_disclaimer": "This is not medical advice."
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let errorResponse = try decoder.decode(LabAnalysisErrorResponse.self, from: json)

        XCTAssertEqual(errorResponse.error, "Unable to analyze lab results. Please try again later.")
        XCTAssertEqual(errorResponse.medicalDisclaimer, "This is not medical advice.")
    }

    func testLabAnalysisError_NoDisclaimerProvided() throws {
        let json = """
        {
            "error": "Network timeout"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let errorResponse = try decoder.decode(LabAnalysisErrorResponse.self, from: json)

        XCTAssertEqual(errorResponse.error, "Network timeout")
        XCTAssertNil(errorResponse.medicalDisclaimer)
    }

    func testLabAnalysisError_EmptyErrorString() throws {
        let json = """
        {
            "error": ""
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let errorResponse = try decoder.decode(LabAnalysisErrorResponse.self, from: json)

        XCTAssertEqual(errorResponse.error, "")
    }

    // MARK: - Unified Coach Response Parsing

    func testUnifiedCoachResponse_CompleteResponse() throws {
        let json = """
        {
            "coaching_id": "coach-abc-123",
            "greeting": "Good morning! Ready for another great day.",
            "primary_message": "Your recovery metrics look excellent today.",
            "insights": [
                {
                    "category": "recovery",
                    "priority": "high",
                    "insight": "HRV improved 15% overnight",
                    "action": "You're ready for high intensity training",
                    "rationale": "Strong parasympathetic recovery"
                },
                {
                    "category": "sleep",
                    "priority": "medium",
                    "insight": "Sleep duration was slightly below target",
                    "action": "Aim for 8 hours tonight",
                    "rationale": "7.2 hours vs 8 hour target"
                }
            ],
            "today_focus": "Push day - you're primed for heavy compound lifts",
            "weekly_priorities": [
                "Maintain sleep consistency",
                "Increase protein intake",
                "Add one more recovery session"
            ],
            "data_summary": {
                "readiness": "High (87/100)",
                "training": "4 sessions this week",
                "recovery": "2 sauna, 1 cold plunge",
                "labs": "Last test: 2 weeks ago"
            },
            "proactive_alerts": [
                "Your training volume is approaching the high end"
            ],
            "follow_up_questions": [
                "How did you sleep last night?",
                "Any soreness from yesterday's session?"
            ],
            "disclaimer": "This is AI-generated coaching advice."
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(UnifiedCoachResponse.self, from: json)

        XCTAssertEqual(response.coachingId, "coach-abc-123")
        XCTAssertEqual(response.greeting, "Good morning! Ready for another great day.")
        XCTAssertEqual(response.insights.count, 2)
        XCTAssertEqual(response.weeklyPriorities.count, 3)
        XCTAssertEqual(response.proactiveAlerts.count, 1)
        XCTAssertEqual(response.followUpQuestions.count, 2)
    }

    func testUnifiedCoachResponse_EmptyInsights() throws {
        let json = """
        {
            "coaching_id": "coach-empty",
            "greeting": "Hello",
            "primary_message": "No new insights today",
            "insights": [],
            "today_focus": "Rest day",
            "weekly_priorities": [],
            "data_summary": {
                "readiness": "N/A",
                "training": "N/A",
                "recovery": "N/A",
                "labs": "N/A"
            },
            "proactive_alerts": [],
            "follow_up_questions": [],
            "disclaimer": "Disclaimer"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(UnifiedCoachResponse.self, from: json)

        XCTAssertTrue(response.insights.isEmpty)
        XCTAssertTrue(response.weeklyPriorities.isEmpty)
        XCTAssertTrue(response.proactiveAlerts.isEmpty)
    }
}

// MARK: - Error Handling Tests

final class HealthIntelligenceErrorHandlingTests: XCTestCase {

    // MARK: - Lab Analysis Error Cases

    func testLabAnalysisError_NoPatientId() {
        let error = LabAnalysisError.noPatientId
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.lowercased().contains("patient") ?? false)
    }

    func testLabAnalysisError_AnalysisError() {
        let error = LabAnalysisError.analysisError("Custom error message")
        XCTAssertEqual(error.errorDescription, "Custom error message")
    }

    func testLabAnalysisError_HttpError() {
        let error = LabAnalysisError.httpError(statusCode: 500)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("500") ?? false)
    }

    func testLabAnalysisError_NetworkError() {
        let error = LabAnalysisError.networkError
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.lowercased().contains("network") ?? false)
    }

    func testLabAnalysisError_DecodingError() {
        let error = LabAnalysisError.decodingError("Missing required field: analysis_id")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("analysis_id") ?? false)
    }

    // MARK: - Lab Result Error Cases

    func testLabResultError_ParsingFailed() {
        let error = LabResultError.parsingFailed("Could not extract biomarkers")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("biomarkers") ?? false)
    }

    func testLabResultError_UploadFailed() {
        let error = LabResultError.uploadFailed("Server unavailable")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("Server") ?? false)
    }

    func testLabResultError_NoPatientFound() {
        let error = LabResultError.noPatientFound
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.lowercased().contains("patient") ?? false)
    }

    func testLabResultError_NoBiomarkersSelected() {
        let error = LabResultError.noBiomarkersSelected
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.lowercased().contains("biomarker") ?? false)
    }

    func testLabResultError_InvalidPDFData() {
        let error = LabResultError.invalidPDFData
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.lowercased().contains("pdf") ?? false)
    }

    // MARK: - AI Coach Error Cases

    func testAICoachError_NoPatientId() {
        let error = AICoachError.noPatientId
        XCTAssertNotNil(error.errorDescription)
    }

    func testAICoachError_InvalidResponse() {
        let error = AICoachError.invalidResponse
        XCTAssertNotNil(error.errorDescription)
    }

    func testAICoachError_NetworkError() {
        let underlyingError = NSError(domain: "TestDomain", code: -1, userInfo: nil)
        let error = AICoachError.networkError(underlyingError)
        XCTAssertNotNil(error.errorDescription)
    }
}

// MARK: - Caching Behavior Tests

final class HealthIntelligenceCachingTests: XCTestCase {

    func testLabAnalysis_IdentifiesCachedResponse() throws {
        let json = """
        {
            "analysis_id": "cached-test",
            "analysis_text": "Cached analysis",
            "recommendations": [],
            "biomarker_analyses": [],
            "training_correlations": [],
            "sleep_correlations": [],
            "overall_health_score": 80,
            "priority_actions": [],
            "medical_disclaimer": "Disclaimer",
            "cached": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let analysis = try decoder.decode(LabAnalysis.self, from: json)

        XCTAssertTrue(analysis.cached)
    }

    func testLabAnalysis_IdentifiesFreshResponse() throws {
        let json = """
        {
            "analysis_id": "fresh-test",
            "analysis_text": "Fresh analysis",
            "recommendations": [],
            "biomarker_analyses": [],
            "training_correlations": [],
            "sleep_correlations": [],
            "overall_health_score": 80,
            "priority_actions": [],
            "medical_disclaimer": "Disclaimer",
            "cached": false
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let analysis = try decoder.decode(LabAnalysis.self, from: json)

        XCTAssertFalse(analysis.cached)
    }
}

// MARK: - Edge Case Response Tests

final class HealthIntelligenceEdgeCaseResponseTests: XCTestCase {

    func testLabAnalysis_VeryLongAnalysisText() throws {
        let longText = String(repeating: "This is a long analysis. ", count: 100)
        let json = """
        {
            "analysis_id": "long-text",
            "analysis_text": "\(longText)",
            "recommendations": [],
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

        XCTAssertEqual(analysis.analysisText, longText)
    }

    func testLabAnalysis_ManyBiomarkers() throws {
        var biomarkersJson = "["
        for i in 0..<50 {
            if i > 0 { biomarkersJson += "," }
            biomarkersJson += """
            {
                "biomarker_type": "marker_\(i)",
                "name": "Marker \(i)",
                "value": \(Double(i) * 10),
                "unit": "units",
                "status": "normal",
                "interpretation": "Normal"
            }
            """
        }
        biomarkersJson += "]"

        let json = """
        {
            "analysis_id": "many-biomarkers",
            "analysis_text": "Analysis",
            "recommendations": [],
            "biomarker_analyses": \(biomarkersJson),
            "training_correlations": [],
            "sleep_correlations": [],
            "overall_health_score": 85,
            "priority_actions": [],
            "medical_disclaimer": "Disclaimer",
            "cached": false
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let analysis = try decoder.decode(LabAnalysis.self, from: json)

        XCTAssertEqual(analysis.biomarkerAnalyses.count, 50)
    }

    func testLabAnalysis_SpecialCharactersInStrings() throws {
        let json = """
        {
            "analysis_id": "special-chars",
            "analysis_text": "Your vitamin D level is <30 ng/mL. Consider 5000 IU/day. Monitor A1c < 5.7%.",
            "recommendations": ["Increase D3 to >=5000 IU", "Keep A1c < 5.7%"],
            "biomarker_analyses": [],
            "training_correlations": [],
            "sleep_correlations": [],
            "overall_health_score": 70,
            "priority_actions": [],
            "medical_disclaimer": "Consult your doctor & follow up in 3-6 months.",
            "cached": false
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let analysis = try decoder.decode(LabAnalysis.self, from: json)

        XCTAssertTrue(analysis.analysisText.contains("<"))
        XCTAssertTrue(analysis.recommendations.first?.contains(">=") ?? false)
        XCTAssertTrue(analysis.medicalDisclaimer.contains("&"))
    }

    func testLabAnalysis_UnicodeCharacters() throws {
        let json = """
        {
            "analysis_id": "unicode-test",
            "analysis_text": "Great progress on your health journey!",
            "recommendations": ["Keep it up!"],
            "biomarker_analyses": [],
            "training_correlations": [],
            "sleep_correlations": [],
            "overall_health_score": 90,
            "priority_actions": [],
            "medical_disclaimer": "Disclaimer",
            "cached": false
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let analysis = try decoder.decode(LabAnalysis.self, from: json)

        XCTAssertTrue(analysis.analysisText.contains("!"))
    }
}
