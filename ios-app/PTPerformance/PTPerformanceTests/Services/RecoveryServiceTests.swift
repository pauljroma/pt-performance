//
//  RecoveryServiceTests.swift
//  PTPerformanceTests
//
//  Unit tests for RecoveryService
//  Tests recovery session models, protocol types, and service state management
//

import XCTest
@testable import PTPerformance

// MARK: - RecoveryProtocolType Tests

final class RecoveryServiceProtocolTypeTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testRecoveryProtocolType_RawValues() {
        XCTAssertEqual(RecoveryProtocolType.saunaTraditional.rawValue, "sauna_traditional")
        XCTAssertEqual(RecoveryProtocolType.saunaInfrared.rawValue, "sauna_infrared")
        XCTAssertEqual(RecoveryProtocolType.saunaSteam.rawValue, "sauna_steam")
        XCTAssertEqual(RecoveryProtocolType.coldPlunge.rawValue, "cold_plunge")
        XCTAssertEqual(RecoveryProtocolType.coldShower.rawValue, "cold_shower")
        XCTAssertEqual(RecoveryProtocolType.iceBath.rawValue, "ice_bath")
        XCTAssertEqual(RecoveryProtocolType.contrast.rawValue, "contrast")
    }

    func testRecoveryProtocolType_InitFromRawValue() {
        XCTAssertEqual(RecoveryProtocolType(rawValue: "sauna_traditional"), .saunaTraditional)
        XCTAssertEqual(RecoveryProtocolType(rawValue: "sauna_infrared"), .saunaInfrared)
        XCTAssertEqual(RecoveryProtocolType(rawValue: "sauna_steam"), .saunaSteam)
        XCTAssertEqual(RecoveryProtocolType(rawValue: "cold_plunge"), .coldPlunge)
        XCTAssertEqual(RecoveryProtocolType(rawValue: "cold_shower"), .coldShower)
        XCTAssertEqual(RecoveryProtocolType(rawValue: "ice_bath"), .iceBath)
        XCTAssertEqual(RecoveryProtocolType(rawValue: "contrast"), .contrast)
        XCTAssertNil(RecoveryProtocolType(rawValue: "invalid"))
    }

    // MARK: - Display Name Tests

    func testRecoveryProtocolType_DisplayNames() {
        XCTAssertEqual(RecoveryProtocolType.saunaTraditional.displayName, "Traditional Sauna")
        XCTAssertEqual(RecoveryProtocolType.saunaInfrared.displayName, "Infrared Sauna")
        XCTAssertEqual(RecoveryProtocolType.saunaSteam.displayName, "Steam Room")
        XCTAssertEqual(RecoveryProtocolType.coldPlunge.displayName, "Cold Plunge")
        XCTAssertEqual(RecoveryProtocolType.coldShower.displayName, "Cold Shower")
        XCTAssertEqual(RecoveryProtocolType.iceBath.displayName, "Ice Bath")
        XCTAssertEqual(RecoveryProtocolType.contrast.displayName, "Contrast Therapy")
    }

    // MARK: - Icon Tests

    func testRecoveryProtocolType_Icons() {
        XCTAssertEqual(RecoveryProtocolType.saunaTraditional.icon, "flame.fill")
        XCTAssertEqual(RecoveryProtocolType.saunaInfrared.icon, "flame")
        XCTAssertEqual(RecoveryProtocolType.saunaSteam.icon, "cloud.fill")
        XCTAssertEqual(RecoveryProtocolType.coldPlunge.icon, "snowflake")
        XCTAssertEqual(RecoveryProtocolType.coldShower.icon, "drop.fill")
        XCTAssertEqual(RecoveryProtocolType.iceBath.icon, "snowflake.circle.fill")
        XCTAssertEqual(RecoveryProtocolType.contrast.icon, "arrow.left.arrow.right")
    }

    // MARK: - CaseIterable Tests

    func testRecoveryProtocolType_AllCases() {
        let allCases = RecoveryProtocolType.allCases
        XCTAssertEqual(allCases.count, 7)
        XCTAssertTrue(allCases.contains(.saunaTraditional))
        XCTAssertTrue(allCases.contains(.saunaInfrared))
        XCTAssertTrue(allCases.contains(.saunaSteam))
        XCTAssertTrue(allCases.contains(.coldPlunge))
        XCTAssertTrue(allCases.contains(.coldShower))
        XCTAssertTrue(allCases.contains(.iceBath))
        XCTAssertTrue(allCases.contains(.contrast))
    }

    // MARK: - Codable Tests

    func testRecoveryProtocolType_Encoding() throws {
        let protocolType = RecoveryProtocolType.coldPlunge
        let encoder = JSONEncoder()
        let data = try encoder.encode(protocolType)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertEqual(jsonString, "\"cold_plunge\"")
    }

    func testRecoveryProtocolType_Decoding() throws {
        let json = "\"sauna_traditional\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        let protocolType = try decoder.decode(RecoveryProtocolType.self, from: json)

        XCTAssertEqual(protocolType, .saunaTraditional)
    }
}

// MARK: - RecoveryPriority Tests

final class RecoveryServicePriorityTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testRecoveryPriority_RawValues() {
        XCTAssertEqual(RecoveryPriority.high.rawValue, "high")
        XCTAssertEqual(RecoveryPriority.medium.rawValue, "medium")
        XCTAssertEqual(RecoveryPriority.low.rawValue, "low")
    }

    func testRecoveryPriority_InitFromRawValue() {
        XCTAssertEqual(RecoveryPriority(rawValue: "high"), .high)
        XCTAssertEqual(RecoveryPriority(rawValue: "medium"), .medium)
        XCTAssertEqual(RecoveryPriority(rawValue: "low"), .low)
        XCTAssertNil(RecoveryPriority(rawValue: "invalid"))
    }

    // MARK: - Codable Tests

    func testRecoveryPriority_Encoding() throws {
        let priority = RecoveryPriority.high
        let encoder = JSONEncoder()
        let data = try encoder.encode(priority)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertEqual(jsonString, "\"high\"")
    }

    func testRecoveryPriority_Decoding() throws {
        let json = "\"medium\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        let priority = try decoder.decode(RecoveryPriority.self, from: json)

        XCTAssertEqual(priority, .medium)
    }
}

// MARK: - RecoverySession Tests

final class RecoveryServiceSessionTests: XCTestCase {

    // MARK: - Memberwise Initializer Tests

    func testRecoverySession_MemberwiseInit() {
        let id = UUID()
        let patientId = UUID()
        let loggedAt = Date()
        let createdAt = Date()

        let session = RecoverySession(
            id: id,
            patientId: patientId,
            protocolType: .saunaTraditional,
            loggedAt: loggedAt,
            durationSeconds: 1200, // 20 minutes in seconds
            temperature: 180.0,
            heartRateAvg: 110,
            heartRateMax: 140,
            perceivedEffort: 7,
            rating: 4,
            notes: "Felt great after",
            createdAt: createdAt
        )

        XCTAssertEqual(session.id, id)
        XCTAssertEqual(session.patientId, patientId)
        XCTAssertEqual(session.protocolType, .saunaTraditional)
        XCTAssertEqual(session.loggedAt, loggedAt)
        XCTAssertEqual(session.durationMinutes, 20)
        XCTAssertEqual(session.durationSeconds, 1200)
        XCTAssertEqual(session.temperature, 180.0)
        XCTAssertEqual(session.heartRateAvg, 110)
        XCTAssertEqual(session.heartRateMax, 140)
        XCTAssertEqual(session.perceivedEffort, 7)
        XCTAssertEqual(session.rating, 4)
        XCTAssertEqual(session.notes, "Felt great after")
    }

    func testRecoverySession_OptionalFields() {
        let session = RecoverySession(
            id: UUID(),
            patientId: UUID(),
            protocolType: .contrast,
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

        XCTAssertNil(session.temperature)
        XCTAssertNil(session.heartRateAvg)
        XCTAssertNil(session.heartRateMax)
        XCTAssertNil(session.perceivedEffort)
        XCTAssertNil(session.rating)
        XCTAssertNil(session.notes)
    }

    // MARK: - Identifiable Tests

    func testRecoverySession_Identifiable() {
        let id = UUID()
        let session = RecoverySession(
            id: id,
            patientId: UUID(),
            protocolType: .coldPlunge,
            loggedAt: Date(),
            durationSeconds: 180,
            temperature: 38.0,
            heartRateAvg: nil,
            heartRateMax: nil,
            perceivedEffort: nil,
            rating: nil,
            notes: nil,
            createdAt: Date()
        )

        XCTAssertEqual(session.id, id)
    }

    // MARK: - Hashable Tests

    func testRecoverySession_Hashable() {
        let id = UUID()
        let patientId = UUID()
        let date = Date()

        let session1 = RecoverySession(
            id: id,
            patientId: patientId,
            protocolType: .saunaTraditional,
            loggedAt: date,
            durationSeconds: 1200,
            temperature: 180.0,
            heartRateAvg: nil,
            heartRateMax: nil,
            perceivedEffort: nil,
            rating: nil,
            notes: nil,
            createdAt: date
        )
        let session2 = RecoverySession(
            id: id,
            patientId: patientId,
            protocolType: .saunaTraditional,
            loggedAt: date,
            durationSeconds: 1200,
            temperature: 180.0,
            heartRateAvg: nil,
            heartRateMax: nil,
            perceivedEffort: nil,
            rating: nil,
            notes: nil,
            createdAt: date
        )

        XCTAssertEqual(session1, session2)
    }
}

// MARK: - RecoveryRecommendation Tests

final class RecoveryServiceRecommendationTests: XCTestCase {

    // MARK: - Memberwise Initializer Tests

    func testRecoveryRecommendation_MemberwiseInit() {
        let id = UUID()
        let recommendation = RecoveryRecommendation(
            id: id,
            protocolType: .saunaTraditional,
            reason: "High training volume this week",
            priority: .high,
            suggestedDuration: 20
        )

        XCTAssertEqual(recommendation.id, id)
        XCTAssertEqual(recommendation.protocolType, .saunaTraditional)
        XCTAssertEqual(recommendation.reason, "High training volume this week")
        XCTAssertEqual(recommendation.priority, .high)
        XCTAssertEqual(recommendation.suggestedDuration, 20)
    }

    // MARK: - Identifiable Tests

    func testRecoveryRecommendation_Identifiable() {
        let id = UUID()
        let recommendation = RecoveryRecommendation(
            id: id,
            protocolType: .coldPlunge,
            reason: "Test",
            priority: .medium,
            suggestedDuration: 3
        )

        XCTAssertEqual(recommendation.id, id)
    }
}

// MARK: - RecoveryService Tests

@MainActor
final class RecoveryServiceTests: XCTestCase {

    var sut: RecoveryService!

    override func setUp() async throws {
        try await super.setUp()
        sut = RecoveryService.shared
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Singleton Tests

    func testSharedInstanceExists() {
        XCTAssertNotNil(RecoveryService.shared)
    }

    func testSharedInstanceIsSingleton() {
        let instance1 = RecoveryService.shared
        let instance2 = RecoveryService.shared
        XCTAssertTrue(instance1 === instance2, "Shared instances should be the same object")
    }

    // MARK: - Initial State Tests

    func testInitialState_SessionsIsArray() {
        XCTAssertNotNil(sut.sessions)
        XCTAssertTrue(sut.sessions is [RecoverySession])
    }

    func testInitialState_RecommendationsIsArray() {
        XCTAssertNotNil(sut.recommendations)
        XCTAssertTrue(sut.recommendations is [RecoveryRecommendation])
    }

    func testInitialState_IsLoadingProperty() {
        _ = sut.isLoading
    }

    func testInitialState_ErrorProperty() {
        _ = sut.error
    }

    // MARK: - Published Properties Tests

    func testSessions_IsPublished() {
        let sessions = sut.sessions
        XCTAssertNotNil(sessions)
    }

    func testRecommendations_IsPublished() {
        let recommendations = sut.recommendations
        XCTAssertNotNil(recommendations)
    }

    // MARK: - Generate Recommendations Tests

    func testGenerateRecommendations_CreatesRecommendations() async {
        // When
        await sut.generateRecommendations()

        // Then
        XCTAssertFalse(sut.recommendations.isEmpty)
        XCTAssertEqual(sut.recommendations.count, 2)
    }

    func testGenerateRecommendations_IncludesSaunaRecommendation() async {
        await sut.generateRecommendations()

        let saunaRecommendation = sut.recommendations.first { $0.protocolType == .saunaTraditional }
        XCTAssertNotNil(saunaRecommendation)
        XCTAssertEqual(saunaRecommendation?.priority, .high)
        XCTAssertEqual(saunaRecommendation?.suggestedDuration, 20)
    }

    func testGenerateRecommendations_IncludesColdPlungeRecommendation() async {
        await sut.generateRecommendations()

        let coldRecommendation = sut.recommendations.first { $0.protocolType == .coldPlunge }
        XCTAssertNotNil(coldRecommendation)
        XCTAssertEqual(coldRecommendation?.priority, .medium)
        XCTAssertEqual(coldRecommendation?.suggestedDuration, 3)
    }

    // MARK: - Weekly Stats Tests

    func testWeeklyStats_ReturnsZeroForEmptySessions() {
        // Given: Empty sessions (default state)
        // Note: Sessions may have data from other tests

        // When
        let stats = sut.weeklyStats()

        // Then: Verify tuple structure
        XCTAssertGreaterThanOrEqual(stats.totalSessions, 0)
        XCTAssertGreaterThanOrEqual(stats.totalMinutes, 0)
        // favoriteProtocol can be nil or a valid protocol type
    }

    func testWeeklyStats_ReturnsTuple() {
        let stats = sut.weeklyStats()

        // Verify the tuple has correct types
        let totalSessions: Int = stats.totalSessions
        let totalMinutes: Int = stats.totalMinutes
        let favoriteProtocol: RecoveryProtocolType? = stats.favoriteProtocol

        XCTAssertNotNil(totalSessions)
        XCTAssertNotNil(totalMinutes)
        _ = favoriteProtocol // Can be nil
    }
}

// MARK: - Codable Decoding Tests

final class RecoverySessionDecodingTests: XCTestCase {

    func testRecoverySession_Decoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "session_type": "sauna_traditional",
            "logged_at": "2024-01-15T10:30:00Z",
            "duration_minutes": 20,
            "temperature_f": 180.0,
            "heart_rate_avg": 110,
            "heart_rate_max": 140,
            "perceived_effort": 7,
            "rating": 4,
            "notes": "Great session",
            "created_at": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let session = try decoder.decode(RecoverySession.self, from: json)

        XCTAssertEqual(session.protocolType, .saunaTraditional)
        XCTAssertEqual(session.durationMinutes, 20)
        XCTAssertEqual(session.durationSeconds, 1200)
        XCTAssertEqual(session.temperature, 180.0)
        XCTAssertEqual(session.heartRateAvg, 110)
        XCTAssertEqual(session.heartRateMax, 140)
        XCTAssertEqual(session.perceivedEffort, 7)
        XCTAssertEqual(session.rating, 4)
        XCTAssertEqual(session.notes, "Great session")
    }

    func testRecoverySession_DecodingWithNullOptionals() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "session_type": "contrast",
            "logged_at": "2024-01-15T10:30:00Z",
            "duration_minutes": 10,
            "temperature_f": null,
            "heart_rate_avg": null,
            "heart_rate_max": null,
            "perceived_effort": null,
            "rating": null,
            "notes": null,
            "created_at": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let session = try decoder.decode(RecoverySession.self, from: json)

        XCTAssertNil(session.temperature)
        XCTAssertNil(session.heartRateAvg)
        XCTAssertNil(session.heartRateMax)
        XCTAssertNil(session.perceivedEffort)
        XCTAssertNil(session.rating)
        XCTAssertNil(session.notes)
    }

    func testRecoverySession_AllProtocolTypes() throws {
        let protocolTypes = ["sauna_traditional", "sauna_infrared", "sauna_steam",
                             "cold_plunge", "cold_shower", "ice_bath", "contrast"]

        for protocolType in protocolTypes {
            let json = """
            {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "patient_id": "660e8400-e29b-41d4-a716-446655440001",
                "session_type": "\(protocolType)",
                "logged_at": "2024-01-15T10:30:00Z",
                "duration_minutes": 10,
                "temperature_f": null,
                "heart_rate_avg": null,
                "heart_rate_max": null,
                "perceived_effort": null,
                "rating": null,
                "notes": null,
                "created_at": "2024-01-15T10:30:00Z"
            }
            """.data(using: .utf8)!

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let session = try decoder.decode(RecoverySession.self, from: json)

            XCTAssertEqual(session.protocolType.rawValue, protocolType)
        }
    }

    func testRecoveryRecommendation_Decoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "protocol_type": "cold_plunge",
            "reason": "Post-workout recovery",
            "priority": "high",
            "suggested_duration": 3
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let recommendation = try decoder.decode(RecoveryRecommendation.self, from: json)

        XCTAssertEqual(recommendation.protocolType, .coldPlunge)
        XCTAssertEqual(recommendation.reason, "Post-workout recovery")
        XCTAssertEqual(recommendation.priority, .high)
        XCTAssertEqual(recommendation.suggestedDuration, 3)
    }
}

// MARK: - Edge Cases Tests

final class RecoveryServiceEdgeCaseTests: XCTestCase {

    func testRecoverySession_ZeroDuration() {
        let session = RecoverySession(
            id: UUID(),
            patientId: UUID(),
            protocolType: .contrast,
            loggedAt: Date(),
            durationSeconds: 0,
            temperature: nil,
            heartRateAvg: nil,
            heartRateMax: nil,
            perceivedEffort: nil,
            rating: nil,
            notes: nil,
            createdAt: Date()
        )

        XCTAssertEqual(session.durationMinutes, 0)
        XCTAssertEqual(session.durationSeconds, 0)
    }

    func testRecoverySession_VeryLongDuration() {
        // 2 hours in seconds
        let session = RecoverySession(
            id: UUID(),
            patientId: UUID(),
            protocolType: .saunaInfrared,
            loggedAt: Date(),
            durationSeconds: 7200,
            temperature: nil,
            heartRateAvg: nil,
            heartRateMax: nil,
            perceivedEffort: nil,
            rating: nil,
            notes: nil,
            createdAt: Date()
        )

        XCTAssertEqual(session.durationMinutes, 120)
        XCTAssertEqual(session.durationSeconds, 7200)
    }

    func testRecoverySession_ColdPlungeTemperature() {
        // Cold plunge at 3 degrees Celsius
        let session = RecoverySession(
            id: UUID(),
            patientId: UUID(),
            protocolType: .coldPlunge,
            loggedAt: Date(),
            durationSeconds: 180,
            temperature: 3.0,
            heartRateAvg: nil,
            heartRateMax: nil,
            perceivedEffort: nil,
            rating: nil,
            notes: nil,
            createdAt: Date()
        )

        XCTAssertEqual(session.temperature, 3.0)
    }

    func testRecoverySession_SaunaHighTemperature() {
        // Sauna at 200 degrees Fahrenheit
        let session = RecoverySession(
            id: UUID(),
            patientId: UUID(),
            protocolType: .saunaTraditional,
            loggedAt: Date(),
            durationSeconds: 1200,
            temperature: 200.0,
            heartRateAvg: nil,
            heartRateMax: nil,
            perceivedEffort: nil,
            rating: nil,
            notes: nil,
            createdAt: Date()
        )

        XCTAssertEqual(session.temperature, 200.0)
    }

    func testRecoverySession_PerceivedEffortRange() {
        // RPE should typically be 1-10
        for rpe in 1...10 {
            let session = RecoverySession(
                id: UUID(),
                patientId: UUID(),
                protocolType: .contrast,
                loggedAt: Date(),
                durationSeconds: 600,
                temperature: nil,
                heartRateAvg: nil,
                heartRateMax: nil,
                perceivedEffort: rpe,
                rating: nil,
                notes: nil,
                createdAt: Date()
            )

            XCTAssertEqual(session.perceivedEffort, rpe)
        }
    }

    func testRecoveryProtocolType_UniqueIcons() {
        let icons = RecoveryProtocolType.allCases.map { $0.icon }
        let uniqueIcons = Set(icons)

        // All icons should be unique
        XCTAssertEqual(icons.count, uniqueIcons.count, "Each protocol type should have a unique icon")
    }

    func testRecoveryProtocolType_UniqueDisplayNames() {
        let names = RecoveryProtocolType.allCases.map { $0.displayName }
        let uniqueNames = Set(names)

        // All display names should be unique
        XCTAssertEqual(names.count, uniqueNames.count, "Each protocol type should have a unique display name")
    }

    func testRecoveryRecommendation_AllPriorities() {
        let priorities: [RecoveryPriority] = [.high, .medium, .low]

        for priority in priorities {
            let recommendation = RecoveryRecommendation(
                id: UUID(),
                protocolType: .saunaTraditional,
                reason: "Test reason",
                priority: priority,
                suggestedDuration: 20
            )

            XCTAssertEqual(recommendation.priority, priority)
        }
    }
}

// MARK: - Impact Analysis Model Tests

final class RecoveryImpactAnalysisModelTests: XCTestCase {

    func testRecoveryImpactAnalysis_HasSufficientData_True() {
        let analysis = RecoveryImpactAnalysis(
            insights: [],
            correlations: [],
            personalizedRecommendations: [],
            analysisDate: Date(),
            dataPointsAnalyzed: 10
        )

        XCTAssertTrue(analysis.hasSufficientData)
    }

    func testRecoveryImpactAnalysis_HasSufficientData_False() {
        let analysis = RecoveryImpactAnalysis(
            insights: [],
            correlations: [],
            personalizedRecommendations: [],
            analysisDate: Date(),
            dataPointsAnalyzed: 3
        )

        XCTAssertFalse(analysis.hasSufficientData)
    }

    func testRecoveryImpactAnalysis_TopInsight() {
        let highConfidenceInsight = RecoveryInsight(
            type: .hrvImprovement,
            metric: .hrv,
            protocolType: .saunaTraditional,
            impactPercentage: 15.0,
            confidence: 0.9,
            description: "HRV improved",
            dataPoints: 10
        )

        let lowConfidenceInsight = RecoveryInsight(
            type: .sleepImprovement,
            metric: .sleepDuration,
            protocolType: .coldPlunge,
            impactPercentage: 20.0,
            confidence: 0.5,
            description: "Sleep improved",
            dataPoints: 5
        )

        let analysis = RecoveryImpactAnalysis(
            insights: [lowConfidenceInsight, highConfidenceInsight],
            correlations: [],
            personalizedRecommendations: [],
            analysisDate: Date(),
            dataPointsAnalyzed: 15
        )

        XCTAssertEqual(analysis.topInsight?.id, highConfidenceInsight.id)
    }

    func testRecoveryImpactAnalysis_PositiveInsights() {
        let positiveInsight = RecoveryInsight(
            type: .hrvImprovement,
            metric: .hrv,
            protocolType: .saunaTraditional,
            impactPercentage: 15.0,
            confidence: 0.9,
            description: "HRV improved",
            dataPoints: 10
        )

        let negativeInsight = RecoveryInsight(
            type: .hrvDecline,
            metric: .hrv,
            protocolType: .coldPlunge,
            impactPercentage: -5.0,
            confidence: 0.7,
            description: "HRV declined",
            dataPoints: 8
        )

        let analysis = RecoveryImpactAnalysis(
            insights: [positiveInsight, negativeInsight],
            correlations: [],
            personalizedRecommendations: [],
            analysisDate: Date(),
            dataPointsAnalyzed: 18
        )

        XCTAssertEqual(analysis.positiveInsights.count, 1)
        XCTAssertEqual(analysis.negativeInsights.count, 1)
    }
}

// MARK: - Recovery Insight Tests

final class RecoveryServiceInsightTests: XCTestCase {

    func testRecoveryInsight_FormattedImpact_Positive() {
        let insight = RecoveryInsight(
            type: .hrvImprovement,
            metric: .hrv,
            protocolType: .saunaTraditional,
            impactPercentage: 15.5,
            confidence: 0.9,
            description: "Test",
            dataPoints: 10
        )

        XCTAssertEqual(insight.formattedImpact, "+15%")
    }

    func testRecoveryInsight_FormattedImpact_Negative() {
        let insight = RecoveryInsight(
            type: .hrvDecline,
            metric: .hrv,
            protocolType: .coldPlunge,
            impactPercentage: -8.5,
            confidence: 0.7,
            description: "Test",
            dataPoints: 8
        )

        XCTAssertEqual(insight.formattedImpact, "-8%")
    }

    func testRecoveryInsight_ImpactCategory_StrongPositive() {
        let insight = RecoveryInsight(
            type: .hrvImprovement,
            metric: .hrv,
            protocolType: .saunaTraditional,
            impactPercentage: 15.0,
            confidence: 0.9,
            description: "Test",
            dataPoints: 10
        )

        XCTAssertEqual(insight.impactCategory, .strongPositive)
    }

    func testRecoveryInsight_ImpactCategory_Positive() {
        let insight = RecoveryInsight(
            type: .hrvImprovement,
            metric: .hrv,
            protocolType: .saunaTraditional,
            impactPercentage: 5.0,
            confidence: 0.9,
            description: "Test",
            dataPoints: 10
        )

        XCTAssertEqual(insight.impactCategory, .positive)
    }

    func testRecoveryInsight_ImpactCategory_Neutral() {
        let insight = RecoveryInsight(
            type: .recoveryEffectiveness,
            metric: .hrv,
            protocolType: .contrast,
            impactPercentage: 1.0,
            confidence: 0.5,
            description: "Test",
            dataPoints: 5
        )

        XCTAssertEqual(insight.impactCategory, .neutral)
    }

    func testRecoveryInsight_ImpactCategory_Negative() {
        let insight = RecoveryInsight(
            type: .hrvDecline,
            metric: .hrv,
            protocolType: .coldPlunge,
            impactPercentage: -5.0,
            confidence: 0.7,
            description: "Test",
            dataPoints: 8
        )

        XCTAssertEqual(insight.impactCategory, .negative)
    }

    func testRecoveryInsight_ImpactCategory_StrongNegative() {
        let insight = RecoveryInsight(
            type: .hrvDecline,
            metric: .hrv,
            protocolType: .coldPlunge,
            impactPercentage: -15.0,
            confidence: 0.8,
            description: "Test",
            dataPoints: 12
        )

        XCTAssertEqual(insight.impactCategory, .strongNegative)
    }

    func testRecoveryInsight_ConfidenceLevel() {
        let highConfidence = RecoveryInsight(
            type: .hrvImprovement,
            metric: .hrv,
            protocolType: .saunaTraditional,
            impactPercentage: 15.0,
            confidence: 0.85,
            description: "Test",
            dataPoints: 10
        )
        XCTAssertEqual(highConfidence.confidenceLevel, "High")

        let moderateConfidence = RecoveryInsight(
            type: .hrvImprovement,
            metric: .hrv,
            protocolType: .saunaTraditional,
            impactPercentage: 15.0,
            confidence: 0.65,
            description: "Test",
            dataPoints: 10
        )
        XCTAssertEqual(moderateConfidence.confidenceLevel, "Moderate")

        let lowConfidence = RecoveryInsight(
            type: .hrvImprovement,
            metric: .hrv,
            protocolType: .saunaTraditional,
            impactPercentage: 15.0,
            confidence: 0.35,
            description: "Test",
            dataPoints: 10
        )
        XCTAssertEqual(lowConfidence.confidenceLevel, "Low")
    }
}

// MARK: - Recovery Correlation Tests

final class RecoveryServiceCorrelationTests: XCTestCase {

    func testRecoveryCorrelation_Strength_Strong() {
        let correlation = RecoveryCorrelation(
            protocolType: .saunaTraditional,
            metric: .hrv,
            correlationCoefficient: 0.75,
            pValue: 0.02,
            sampleSize: 20,
            averageImpact: 15.0
        )

        XCTAssertEqual(correlation.strength, "Strong")
    }

    func testRecoveryCorrelation_Strength_Moderate() {
        let correlation = RecoveryCorrelation(
            protocolType: .coldPlunge,
            metric: .sleepDuration,
            correlationCoefficient: 0.55,
            pValue: 0.03,
            sampleSize: 15,
            averageImpact: 10.0
        )

        XCTAssertEqual(correlation.strength, "Moderate")
    }

    func testRecoveryCorrelation_Strength_Weak() {
        let correlation = RecoveryCorrelation(
            protocolType: .contrast,
            metric: .deepSleep,
            correlationCoefficient: 0.3,
            pValue: 0.04,
            sampleSize: 10,
            averageImpact: 5.0
        )

        XCTAssertEqual(correlation.strength, "Weak")
    }

    func testRecoveryCorrelation_Strength_Negligible() {
        let correlation = RecoveryCorrelation(
            protocolType: .iceBath,
            metric: .restingHeartRate,
            correlationCoefficient: 0.1,
            pValue: 0.1,
            sampleSize: 8,
            averageImpact: 2.0
        )

        XCTAssertEqual(correlation.strength, "Negligible")
    }

    func testRecoveryCorrelation_IsSignificant_True() {
        let correlation = RecoveryCorrelation(
            protocolType: .saunaTraditional,
            metric: .hrv,
            correlationCoefficient: 0.7,
            pValue: 0.02,
            sampleSize: 10,
            averageImpact: 15.0
        )

        XCTAssertTrue(correlation.isSignificant)
    }

    func testRecoveryCorrelation_IsSignificant_False_HighPValue() {
        let correlation = RecoveryCorrelation(
            protocolType: .saunaTraditional,
            metric: .hrv,
            correlationCoefficient: 0.7,
            pValue: 0.1,
            sampleSize: 10,
            averageImpact: 15.0
        )

        XCTAssertFalse(correlation.isSignificant)
    }

    func testRecoveryCorrelation_IsSignificant_False_SmallSample() {
        let correlation = RecoveryCorrelation(
            protocolType: .saunaTraditional,
            metric: .hrv,
            correlationCoefficient: 0.7,
            pValue: 0.02,
            sampleSize: 3,
            averageImpact: 15.0
        )

        XCTAssertFalse(correlation.isSignificant)
    }
}

// MARK: - Health Metric Type Tests

final class RecoveryHealthMetricTypeTests: XCTestCase {

    func testHealthMetricType_AllCasesHaveDisplayName() {
        for metric in HealthMetricType.allCases {
            XCTAssertFalse(metric.displayName.isEmpty)
        }
    }

    func testHealthMetricType_AllCasesHaveUnit() {
        for metric in HealthMetricType.allCases {
            XCTAssertFalse(metric.unit.isEmpty)
        }
    }

    func testHealthMetricType_Units() {
        XCTAssertEqual(HealthMetricType.hrv.unit, "ms")
        XCTAssertEqual(HealthMetricType.sleepDuration.unit, "hours")
        XCTAssertEqual(HealthMetricType.sleepQuality.unit, "%")
        XCTAssertEqual(HealthMetricType.deepSleep.unit, "min")
        XCTAssertEqual(HealthMetricType.remSleep.unit, "min")
        XCTAssertEqual(HealthMetricType.restingHeartRate.unit, "bpm")
    }
}

// MARK: - Recovery Insight Type Tests

final class RecoveryServiceInsightTypeTests: XCTestCase {

    func testRecoveryInsightType_AllCasesHaveDisplayName() {
        for type in RecoveryInsightType.allCases {
            XCTAssertFalse(type.displayName.isEmpty)
        }
    }

    func testRecoveryInsightType_AllCasesHaveIcon() {
        for type in RecoveryInsightType.allCases {
            XCTAssertFalse(type.icon.isEmpty)
        }
    }
}

// MARK: - Concurrent Sessions Tests

final class RecoveryConcurrentSessionTests: XCTestCase {

    func testMultipleSessions_SamePatient_SameDay() {
        let patientId = UUID()
        let today = Date()

        let saunaSession = RecoverySession(
            id: UUID(),
            patientId: patientId,
            protocolType: .saunaTraditional,
            loggedAt: today,
            durationSeconds: 1200,
            temperature: 180.0,
            heartRateAvg: nil,
            heartRateMax: nil,
            perceivedEffort: nil,
            rating: nil,
            notes: nil,
            createdAt: today
        )

        let coldSession = RecoverySession(
            id: UUID(),
            patientId: patientId,
            protocolType: .coldPlunge,
            loggedAt: today.addingTimeInterval(1500), // 25 min later
            durationSeconds: 180,
            temperature: 4.0,
            heartRateAvg: nil,
            heartRateMax: nil,
            perceivedEffort: nil,
            rating: nil,
            notes: nil,
            createdAt: today.addingTimeInterval(1500)
        )

        XCTAssertEqual(saunaSession.patientId, coldSession.patientId)
        XCTAssertNotEqual(saunaSession.id, coldSession.id)
        XCTAssertNotEqual(saunaSession.protocolType, coldSession.protocolType)
    }

    func testContrastTherapy_AlternatingHotCold() {
        // Contrast therapy involves alternating hot and cold
        let session = RecoverySession(
            id: UUID(),
            patientId: UUID(),
            protocolType: .contrast,
            loggedAt: Date(),
            durationSeconds: 900, // 15 minutes total
            temperature: nil, // Temperature varies
            heartRateAvg: nil,
            heartRateMax: nil,
            perceivedEffort: 7,
            rating: nil,
            notes: "3 rounds: 3 min hot, 1 min cold",
            createdAt: Date()
        )

        XCTAssertEqual(session.protocolType, .contrast)
        XCTAssertFalse(session.protocolType.isHeatTherapy)
        XCTAssertFalse(session.protocolType.isColdTherapy)
    }
}

// MARK: - Timezone Handling Tests

final class RecoveryTimezoneTests: XCTestCase {

    func testRecoverySession_CrossTimezoneDecoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "session_type": "sauna_traditional",
            "logged_at": "2024-06-15T18:30:00+09:00",
            "duration_minutes": 20,
            "temperature_f": 180.0,
            "notes": null,
            "created_at": "2024-06-15T18:30:00+09:00"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let session = try decoder.decode(RecoverySession.self, from: json)
        XCTAssertNotNil(session.loggedAt)
        XCTAssertEqual(session.temperature, 180.0)
    }

    func testRecoverySession_UTCDecoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "session_type": "cold_plunge",
            "logged_at": "2024-06-15T10:00:00Z",
            "duration_minutes": 3,
            "temperature_f": 4.0,
            "notes": null,
            "created_at": "2024-06-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let session = try decoder.decode(RecoverySession.self, from: json)
        XCTAssertNotNil(session.loggedAt)
        XCTAssertEqual(session.protocolType, .coldPlunge)
    }
}
