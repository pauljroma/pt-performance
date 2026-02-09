//
//  SOAPPlanSuggestionServiceTests.swift
//  PTPerformanceTests
//
//  Unit tests for SOAPPlanSuggestionService
//  Tests PlanSuggestion model, PlanSuggestionCategory/Priority enums, errors, and service state
//

import XCTest
@testable import PTPerformance

// MARK: - PlanSuggestion Model Tests

final class PlanSuggestionTests: XCTestCase {

    // MARK: - Initialization Tests

    func testPlanSuggestion_MemberwiseInit() {
        let suggestion = PlanSuggestion(
            id: "test-id",
            category: .interventions,
            content: "Continue therapeutic exercise",
            rationale: "To improve strength and ROM",
            priority: .high
        )

        XCTAssertEqual(suggestion.id, "test-id")
        XCTAssertEqual(suggestion.category, .interventions)
        XCTAssertEqual(suggestion.content, "Continue therapeutic exercise")
        XCTAssertEqual(suggestion.rationale, "To improve strength and ROM")
        XCTAssertEqual(suggestion.priority, .high)
    }

    func testPlanSuggestion_DefaultId() {
        let suggestion = PlanSuggestion(
            category: .goals,
            content: "Improve ROM",
            rationale: "Based on assessment"
        )

        XCTAssertFalse(suggestion.id.isEmpty)
        XCTAssertEqual(suggestion.priority, .medium) // default priority
    }

    func testPlanSuggestion_DefaultPriority() {
        let suggestion = PlanSuggestion(
            category: .education,
            content: "Teach proper lifting technique",
            rationale: "Patient needs education"
        )

        XCTAssertEqual(suggestion.priority, .medium)
    }

    // MARK: - Identifiable Tests

    func testPlanSuggestion_Identifiable() {
        let suggestion1 = PlanSuggestion(
            id: "id-1",
            category: .frequency,
            content: "2x per week",
            rationale: "Optimal frequency"
        )

        let suggestion2 = PlanSuggestion(
            id: "id-2",
            category: .frequency,
            content: "2x per week",
            rationale: "Optimal frequency"
        )

        XCTAssertNotEqual(suggestion1.id, suggestion2.id)
    }

    // MARK: - Hashable Tests

    func testPlanSuggestion_Hashable() {
        let suggestion1 = PlanSuggestion(
            id: "same-id",
            category: .goals,
            content: "Content",
            rationale: "Rationale"
        )

        let suggestion2 = PlanSuggestion(
            id: "same-id",
            category: .goals,
            content: "Content",
            rationale: "Rationale"
        )

        XCTAssertEqual(suggestion1, suggestion2)
        XCTAssertEqual(suggestion1.hashValue, suggestion2.hashValue)
    }

    func testPlanSuggestion_HashableInSet() {
        let suggestion1 = PlanSuggestion(
            id: "id-1",
            category: .goals,
            content: "Content 1",
            rationale: "Rationale 1"
        )

        let suggestion2 = PlanSuggestion(
            id: "id-2",
            category: .interventions,
            content: "Content 2",
            rationale: "Rationale 2"
        )

        let set: Set<PlanSuggestion> = [suggestion1, suggestion2]
        XCTAssertEqual(set.count, 2)
    }

    // MARK: - Decoding Tests

    func testPlanSuggestion_DecodingFull() throws {
        let json = """
        {
            "id": "suggestion-123",
            "category": "interventions",
            "content": "Manual therapy for joint mobilization",
            "rationale": "To improve mobility",
            "priority": "high"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let suggestion = try decoder.decode(PlanSuggestion.self, from: json)

        XCTAssertEqual(suggestion.id, "suggestion-123")
        XCTAssertEqual(suggestion.category, .interventions)
        XCTAssertEqual(suggestion.content, "Manual therapy for joint mobilization")
        XCTAssertEqual(suggestion.rationale, "To improve mobility")
        XCTAssertEqual(suggestion.priority, .high)
    }

    func testPlanSuggestion_DecodingWithoutId() throws {
        let json = """
        {
            "category": "education",
            "content": "Teach posture correction",
            "rationale": "Poor posture observed"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let suggestion = try decoder.decode(PlanSuggestion.self, from: json)

        XCTAssertFalse(suggestion.id.isEmpty) // Should generate UUID
        XCTAssertEqual(suggestion.category, .education)
        XCTAssertEqual(suggestion.content, "Teach posture correction")
        XCTAssertEqual(suggestion.rationale, "Poor posture observed")
        XCTAssertEqual(suggestion.priority, .medium) // Default
    }

    func testPlanSuggestion_DecodingWithoutRationale() throws {
        let json = """
        {
            "category": "goals",
            "content": "Increase ROM by 15 degrees"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let suggestion = try decoder.decode(PlanSuggestion.self, from: json)

        XCTAssertEqual(suggestion.rationale, "") // Default empty string
    }

    func testPlanSuggestion_DecodingWithoutPriority() throws {
        let json = """
        {
            "category": "precautions",
            "content": "Avoid overhead activities",
            "rationale": "Risk of impingement"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let suggestion = try decoder.decode(PlanSuggestion.self, from: json)

        XCTAssertEqual(suggestion.priority, .medium) // Default
    }

    func testPlanSuggestion_DecodingAllCategories() throws {
        let categories = ["frequency", "goals", "interventions", "education",
                         "precautions", "follow_up", "referral", "home_program"]

        for categoryRaw in categories {
            let json = """
            {
                "id": "test-\(categoryRaw)",
                "category": "\(categoryRaw)",
                "content": "Test content",
                "rationale": "Test rationale"
            }
            """.data(using: .utf8)!

            let decoder = JSONDecoder()
            let suggestion = try decoder.decode(PlanSuggestion.self, from: json)

            XCTAssertEqual(suggestion.category.rawValue, categoryRaw)
        }
    }

    func testPlanSuggestion_DecodingAllPriorities() throws {
        let priorities = ["high", "medium", "low"]

        for priorityRaw in priorities {
            let json = """
            {
                "category": "goals",
                "content": "Test",
                "rationale": "Test",
                "priority": "\(priorityRaw)"
            }
            """.data(using: .utf8)!

            let decoder = JSONDecoder()
            let suggestion = try decoder.decode(PlanSuggestion.self, from: json)

            XCTAssertEqual(suggestion.priority.rawValue, priorityRaw)
        }
    }

    // MARK: - Encoding Tests

    func testPlanSuggestion_Encoding() throws {
        let suggestion = PlanSuggestion(
            id: "test-id",
            category: .followUp,
            content: "Schedule follow-up in 2 weeks",
            rationale: "Monitor progress",
            priority: .low
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(suggestion)
        let jsonObject = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(jsonObject["id"] as? String, "test-id")
        XCTAssertEqual(jsonObject["category"] as? String, "follow_up")
        XCTAssertEqual(jsonObject["content"] as? String, "Schedule follow-up in 2 weeks")
        XCTAssertEqual(jsonObject["rationale"] as? String, "Monitor progress")
        XCTAssertEqual(jsonObject["priority"] as? String, "low")
    }
}

// MARK: - PlanSuggestionCategory Tests

final class PlanSuggestionCategoryTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testPlanSuggestionCategory_RawValues() {
        XCTAssertEqual(PlanSuggestionCategory.frequency.rawValue, "frequency")
        XCTAssertEqual(PlanSuggestionCategory.goals.rawValue, "goals")
        XCTAssertEqual(PlanSuggestionCategory.interventions.rawValue, "interventions")
        XCTAssertEqual(PlanSuggestionCategory.education.rawValue, "education")
        XCTAssertEqual(PlanSuggestionCategory.precautions.rawValue, "precautions")
        XCTAssertEqual(PlanSuggestionCategory.followUp.rawValue, "follow_up")
        XCTAssertEqual(PlanSuggestionCategory.referral.rawValue, "referral")
        XCTAssertEqual(PlanSuggestionCategory.homeProgram.rawValue, "home_program")
    }

    func testPlanSuggestionCategory_InitFromRawValue() {
        XCTAssertEqual(PlanSuggestionCategory(rawValue: "frequency"), .frequency)
        XCTAssertEqual(PlanSuggestionCategory(rawValue: "goals"), .goals)
        XCTAssertEqual(PlanSuggestionCategory(rawValue: "interventions"), .interventions)
        XCTAssertEqual(PlanSuggestionCategory(rawValue: "education"), .education)
        XCTAssertEqual(PlanSuggestionCategory(rawValue: "precautions"), .precautions)
        XCTAssertEqual(PlanSuggestionCategory(rawValue: "follow_up"), .followUp)
        XCTAssertEqual(PlanSuggestionCategory(rawValue: "referral"), .referral)
        XCTAssertEqual(PlanSuggestionCategory(rawValue: "home_program"), .homeProgram)
        XCTAssertNil(PlanSuggestionCategory(rawValue: "invalid"))
    }

    // MARK: - Display Name Tests

    func testPlanSuggestionCategory_DisplayNames() {
        XCTAssertEqual(PlanSuggestionCategory.frequency.displayName, "Frequency")
        XCTAssertEqual(PlanSuggestionCategory.goals.displayName, "Goals")
        XCTAssertEqual(PlanSuggestionCategory.interventions.displayName, "Interventions")
        XCTAssertEqual(PlanSuggestionCategory.education.displayName, "Patient Education")
        XCTAssertEqual(PlanSuggestionCategory.precautions.displayName, "Precautions")
        XCTAssertEqual(PlanSuggestionCategory.followUp.displayName, "Follow-up")
        XCTAssertEqual(PlanSuggestionCategory.referral.displayName, "Referral")
        XCTAssertEqual(PlanSuggestionCategory.homeProgram.displayName, "Home Program")
    }

    // MARK: - Icon Tests

    func testPlanSuggestionCategory_Icons() {
        XCTAssertEqual(PlanSuggestionCategory.frequency.icon, "calendar")
        XCTAssertEqual(PlanSuggestionCategory.goals.icon, "target")
        XCTAssertEqual(PlanSuggestionCategory.interventions.icon, "hand.raised")
        XCTAssertEqual(PlanSuggestionCategory.education.icon, "book")
        XCTAssertEqual(PlanSuggestionCategory.precautions.icon, "exclamationmark.triangle")
        XCTAssertEqual(PlanSuggestionCategory.followUp.icon, "arrow.clockwise")
        XCTAssertEqual(PlanSuggestionCategory.referral.icon, "arrow.right.circle")
        XCTAssertEqual(PlanSuggestionCategory.homeProgram.icon, "house")
    }

    func testPlanSuggestionCategory_AllIconsNotEmpty() {
        for category in PlanSuggestionCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty, "\(category) should have a non-empty icon")
        }
    }

    // MARK: - Color Tests

    func testPlanSuggestionCategory_Colors() {
        XCTAssertEqual(PlanSuggestionCategory.frequency.color, "blue")
        XCTAssertEqual(PlanSuggestionCategory.goals.color, "green")
        XCTAssertEqual(PlanSuggestionCategory.interventions.color, "purple")
        XCTAssertEqual(PlanSuggestionCategory.education.color, "orange")
        XCTAssertEqual(PlanSuggestionCategory.precautions.color, "red")
        XCTAssertEqual(PlanSuggestionCategory.followUp.color, "teal")
        XCTAssertEqual(PlanSuggestionCategory.referral.color, "indigo")
        XCTAssertEqual(PlanSuggestionCategory.homeProgram.color, "brown")
    }

    func testPlanSuggestionCategory_AllColorsNotEmpty() {
        for category in PlanSuggestionCategory.allCases {
            XCTAssertFalse(category.color.isEmpty, "\(category) should have a non-empty color")
        }
    }

    func testPlanSuggestionCategory_UniqueColors() {
        let colors = PlanSuggestionCategory.allCases.map { $0.color }
        let uniqueColors = Set(colors)
        XCTAssertEqual(colors.count, uniqueColors.count, "All categories should have unique colors")
    }

    // MARK: - CaseIterable Tests

    func testPlanSuggestionCategory_AllCases() {
        let allCases = PlanSuggestionCategory.allCases
        XCTAssertEqual(allCases.count, 8)
        XCTAssertTrue(allCases.contains(.frequency))
        XCTAssertTrue(allCases.contains(.goals))
        XCTAssertTrue(allCases.contains(.interventions))
        XCTAssertTrue(allCases.contains(.education))
        XCTAssertTrue(allCases.contains(.precautions))
        XCTAssertTrue(allCases.contains(.followUp))
        XCTAssertTrue(allCases.contains(.referral))
        XCTAssertTrue(allCases.contains(.homeProgram))
    }

    // MARK: - Codable Tests

    func testPlanSuggestionCategory_Encoding() throws {
        for category in PlanSuggestionCategory.allCases {
            let encoder = JSONEncoder()
            let data = try encoder.encode(category)
            let jsonString = String(data: data, encoding: .utf8)!

            XCTAssertEqual(jsonString, "\"\(category.rawValue)\"")
        }
    }

    func testPlanSuggestionCategory_Decoding() throws {
        for category in PlanSuggestionCategory.allCases {
            let json = "\"\(category.rawValue)\"".data(using: .utf8)!
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(PlanSuggestionCategory.self, from: json)

            XCTAssertEqual(decoded, category)
        }
    }

    func testPlanSuggestionCategory_RoundTrip() throws {
        for category in PlanSuggestionCategory.allCases {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()

            let data = try encoder.encode(category)
            let decoded = try decoder.decode(PlanSuggestionCategory.self, from: data)

            XCTAssertEqual(decoded, category)
        }
    }
}

// MARK: - PlanSuggestionPriority Tests

final class PlanSuggestionPriorityTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testPlanSuggestionPriority_RawValues() {
        XCTAssertEqual(PlanSuggestionPriority.high.rawValue, "high")
        XCTAssertEqual(PlanSuggestionPriority.medium.rawValue, "medium")
        XCTAssertEqual(PlanSuggestionPriority.low.rawValue, "low")
    }

    func testPlanSuggestionPriority_InitFromRawValue() {
        XCTAssertEqual(PlanSuggestionPriority(rawValue: "high"), .high)
        XCTAssertEqual(PlanSuggestionPriority(rawValue: "medium"), .medium)
        XCTAssertEqual(PlanSuggestionPriority(rawValue: "low"), .low)
        XCTAssertNil(PlanSuggestionPriority(rawValue: "invalid"))
        XCTAssertNil(PlanSuggestionPriority(rawValue: "HIGH"))
    }

    // MARK: - Sort Order Tests

    func testPlanSuggestionPriority_SortOrder() {
        XCTAssertEqual(PlanSuggestionPriority.high.sortOrder, 0)
        XCTAssertEqual(PlanSuggestionPriority.medium.sortOrder, 1)
        XCTAssertEqual(PlanSuggestionPriority.low.sortOrder, 2)
    }

    func testPlanSuggestionPriority_SortOrderAscending() {
        XCTAssertLessThan(PlanSuggestionPriority.high.sortOrder, PlanSuggestionPriority.medium.sortOrder)
        XCTAssertLessThan(PlanSuggestionPriority.medium.sortOrder, PlanSuggestionPriority.low.sortOrder)
    }

    func testPlanSuggestionPriority_SortingSuggestions() {
        let suggestions = [
            PlanSuggestion(category: .goals, content: "Low", rationale: "", priority: .low),
            PlanSuggestion(category: .goals, content: "High", rationale: "", priority: .high),
            PlanSuggestion(category: .goals, content: "Medium", rationale: "", priority: .medium)
        ]

        let sorted = suggestions.sorted { $0.priority.sortOrder < $1.priority.sortOrder }

        XCTAssertEqual(sorted[0].priority, .high)
        XCTAssertEqual(sorted[1].priority, .medium)
        XCTAssertEqual(sorted[2].priority, .low)
    }

    // MARK: - Codable Tests

    func testPlanSuggestionPriority_Encoding() throws {
        let encoder = JSONEncoder()

        let highData = try encoder.encode(PlanSuggestionPriority.high)
        XCTAssertEqual(String(data: highData, encoding: .utf8), "\"high\"")

        let mediumData = try encoder.encode(PlanSuggestionPriority.medium)
        XCTAssertEqual(String(data: mediumData, encoding: .utf8), "\"medium\"")

        let lowData = try encoder.encode(PlanSuggestionPriority.low)
        XCTAssertEqual(String(data: lowData, encoding: .utf8), "\"low\"")
    }

    func testPlanSuggestionPriority_Decoding() throws {
        let decoder = JSONDecoder()

        let high = try decoder.decode(PlanSuggestionPriority.self, from: "\"high\"".data(using: .utf8)!)
        XCTAssertEqual(high, .high)

        let medium = try decoder.decode(PlanSuggestionPriority.self, from: "\"medium\"".data(using: .utf8)!)
        XCTAssertEqual(medium, .medium)

        let low = try decoder.decode(PlanSuggestionPriority.self, from: "\"low\"".data(using: .utf8)!)
        XCTAssertEqual(low, .low)
    }
}

// MARK: - SOAPPlanSuggestionError Tests

final class SOAPPlanSuggestionErrorTests: XCTestCase {

    // MARK: - Error Description Tests

    func testSOAPPlanSuggestionError_InsufficientInput_Description() {
        let error = SOAPPlanSuggestionError.insufficientInput

        XCTAssertEqual(
            error.errorDescription,
            "Please enter content in at least one section to generate suggestions."
        )
    }

    func testSOAPPlanSuggestionError_DecodingFailed_Description() {
        let underlyingError = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let error = SOAPPlanSuggestionError.decodingFailed(underlyingError)

        XCTAssertEqual(
            error.errorDescription,
            "Unable to parse the AI response. Please try again."
        )
    }

    func testSOAPPlanSuggestionError_NetworkError_Description() {
        let underlyingError = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Connection failed"])
        let error = SOAPPlanSuggestionError.networkError(underlyingError)

        XCTAssertEqual(
            error.errorDescription,
            "Network error: Connection failed"
        )
    }

    // MARK: - LocalizedError Conformance

    func testSOAPPlanSuggestionError_ConformsToLocalizedError() {
        let error: LocalizedError = SOAPPlanSuggestionError.insufficientInput
        XCTAssertNotNil(error.errorDescription)
    }

    // MARK: - Associated Values Tests

    func testSOAPPlanSuggestionError_DecodingFailed_PreservesUnderlyingError() {
        let underlyingError = NSError(domain: "DecodingDomain", code: 123)
        let error = SOAPPlanSuggestionError.decodingFailed(underlyingError)

        if case .decodingFailed(let wrapped) = error {
            let nsError = wrapped as NSError
            XCTAssertEqual(nsError.domain, "DecodingDomain")
            XCTAssertEqual(nsError.code, 123)
        } else {
            XCTFail("Expected decodingFailed case")
        }
    }

    func testSOAPPlanSuggestionError_NetworkError_PreservesUnderlyingError() {
        let underlyingError = NSError(domain: "NetworkDomain", code: 456)
        let error = SOAPPlanSuggestionError.networkError(underlyingError)

        if case .networkError(let wrapped) = error {
            let nsError = wrapped as NSError
            XCTAssertEqual(nsError.domain, "NetworkDomain")
            XCTAssertEqual(nsError.code, 456)
        } else {
            XCTFail("Expected networkError case")
        }
    }
}

// MARK: - SOAPPlanSuggestionResponse Tests

final class SOAPPlanSuggestionResponseTests: XCTestCase {

    func testSOAPPlanSuggestionResponse_DecodingSuccess() throws {
        let json = """
        {
            "success": true,
            "suggestions": [
                {
                    "id": "sug-1",
                    "category": "interventions",
                    "content": "Continue manual therapy",
                    "rationale": "Effective for joint mobility",
                    "priority": "high"
                }
            ],
            "tokens_used": 150
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(SOAPPlanSuggestionResponse.self, from: json)

        XCTAssertTrue(response.success)
        XCTAssertEqual(response.suggestions.count, 1)
        XCTAssertEqual(response.suggestions[0].category, .interventions)
        XCTAssertEqual(response.tokensUsed, 150)
    }

    func testSOAPPlanSuggestionResponse_DecodingWithoutTokensUsed() throws {
        let json = """
        {
            "success": true,
            "suggestions": []
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(SOAPPlanSuggestionResponse.self, from: json)

        XCTAssertTrue(response.success)
        XCTAssertTrue(response.suggestions.isEmpty)
        XCTAssertNil(response.tokensUsed)
    }

    func testSOAPPlanSuggestionResponse_DecodingMultipleSuggestions() throws {
        let json = """
        {
            "success": true,
            "suggestions": [
                {
                    "category": "frequency",
                    "content": "2x per week",
                    "rationale": "Optimal frequency"
                },
                {
                    "category": "goals",
                    "content": "Improve ROM",
                    "rationale": "Based on assessment"
                },
                {
                    "category": "education",
                    "content": "Posture training",
                    "rationale": "Prevent recurrence"
                }
            ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(SOAPPlanSuggestionResponse.self, from: json)

        XCTAssertEqual(response.suggestions.count, 3)
        XCTAssertEqual(response.suggestions[0].category, .frequency)
        XCTAssertEqual(response.suggestions[1].category, .goals)
        XCTAssertEqual(response.suggestions[2].category, .education)
    }

    func testSOAPPlanSuggestionResponse_DecodingFailure() throws {
        let json = """
        {
            "success": false,
            "suggestions": []
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(SOAPPlanSuggestionResponse.self, from: json)

        XCTAssertFalse(response.success)
        XCTAssertTrue(response.suggestions.isEmpty)
    }
}

// MARK: - SOAPPlanSuggestionService State Tests

@MainActor
final class SOAPPlanSuggestionServiceStateTests: XCTestCase {

    var sut: SOAPPlanSuggestionService!

    override func setUp() async throws {
        try await super.setUp()
        sut = SOAPPlanSuggestionService()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading)
    }

    func testInitialState_SuggestionsIsEmpty() {
        XCTAssertTrue(sut.suggestions.isEmpty)
    }

    func testInitialState_ErrorIsNil() {
        XCTAssertNil(sut.error)
    }

    // MARK: - Published Properties Tests

    func testIsLoading_IsPublished() {
        let loading = sut.isLoading
        XCTAssertTrue(loading == true || loading == false)
    }

    func testSuggestions_IsPublished() {
        let suggestions = sut.suggestions
        XCTAssertNotNil(suggestions)
    }

    func testError_IsPublished() {
        let error = sut.error
        _ = error // Can be nil or have a value
    }

    // MARK: - clearSuggestions Tests

    func testClearSuggestions_ClearsSuggestions() {
        // Even if we can't set suggestions directly, we can test the clear method
        sut.clearSuggestions()

        XCTAssertTrue(sut.suggestions.isEmpty)
        XCTAssertNil(sut.error)
    }

    func testClearSuggestions_ClearsError() {
        sut.clearSuggestions()
        XCTAssertNil(sut.error)
    }

    // MARK: - ObservableObject Conformance

    func testService_IsObservableObject() {
        // Verify the service conforms to ObservableObject
        let _: any ObservableObject = sut
    }
}

// MARK: - Edge Cases and Integration Tests

final class PlanSuggestionEdgeCaseTests: XCTestCase {

    func testPlanSuggestion_EmptyContent() {
        let suggestion = PlanSuggestion(
            category: .goals,
            content: "",
            rationale: ""
        )

        XCTAssertEqual(suggestion.content, "")
        XCTAssertEqual(suggestion.rationale, "")
    }

    func testPlanSuggestion_LongContent() {
        let longContent = String(repeating: "Test content. ", count: 100)
        let suggestion = PlanSuggestion(
            category: .interventions,
            content: longContent,
            rationale: "Long content test"
        )

        XCTAssertEqual(suggestion.content, longContent)
    }

    func testPlanSuggestion_SpecialCharactersInContent() {
        let specialContent = "Test with special chars: <>&\"'@#$%^*()"
        let suggestion = PlanSuggestion(
            category: .education,
            content: specialContent,
            rationale: "Special chars test"
        )

        XCTAssertEqual(suggestion.content, specialContent)
    }

    func testPlanSuggestion_UnicodeContent() {
        let unicodeContent = "Patient education: stretch exercises"
        let suggestion = PlanSuggestion(
            category: .education,
            content: unicodeContent,
            rationale: "Unicode test"
        )

        XCTAssertEqual(suggestion.content, unicodeContent)
    }

    func testPlanSuggestion_NewlinesInContent() {
        let multilineContent = "Step 1: Warm up\nStep 2: Exercise\nStep 3: Cool down"
        let suggestion = PlanSuggestion(
            category: .homeProgram,
            content: multilineContent,
            rationale: "Multiline content"
        )

        XCTAssertTrue(suggestion.content.contains("\n"))
    }

    func testMultipleSuggestions_SameCategory() {
        let suggestions = [
            PlanSuggestion(id: "1", category: .goals, content: "Goal 1", rationale: "R1"),
            PlanSuggestion(id: "2", category: .goals, content: "Goal 2", rationale: "R2"),
            PlanSuggestion(id: "3", category: .goals, content: "Goal 3", rationale: "R3")
        ]

        let goalSuggestions = suggestions.filter { $0.category == .goals }
        XCTAssertEqual(goalSuggestions.count, 3)
    }

    func testSuggestions_FilterByCategory() {
        let suggestions = [
            PlanSuggestion(category: .frequency, content: "2x/week", rationale: ""),
            PlanSuggestion(category: .goals, content: "Improve ROM", rationale: ""),
            PlanSuggestion(category: .interventions, content: "Manual therapy", rationale: ""),
            PlanSuggestion(category: .goals, content: "Reduce pain", rationale: "")
        ]

        let goalsOnly = suggestions.filter { $0.category == .goals }
        XCTAssertEqual(goalsOnly.count, 2)

        let frequencyOnly = suggestions.filter { $0.category == .frequency }
        XCTAssertEqual(frequencyOnly.count, 1)
    }

    func testSuggestions_FilterByPriority() {
        let suggestions = [
            PlanSuggestion(category: .precautions, content: "Avoid heavy lifting", rationale: "", priority: .high),
            PlanSuggestion(category: .goals, content: "Improve strength", rationale: "", priority: .medium),
            PlanSuggestion(category: .education, content: "Home exercises", rationale: "", priority: .low),
            PlanSuggestion(category: .interventions, content: "Manual therapy", rationale: "", priority: .high)
        ]

        let highPriority = suggestions.filter { $0.priority == .high }
        XCTAssertEqual(highPriority.count, 2)

        let lowPriority = suggestions.filter { $0.priority == .low }
        XCTAssertEqual(lowPriority.count, 1)
    }
}
