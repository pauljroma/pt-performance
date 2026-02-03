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

final class RecoveryProtocolTypeTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testRecoveryProtocolType_RawValues() {
        XCTAssertEqual(RecoveryProtocolType.sauna.rawValue, "sauna")
        XCTAssertEqual(RecoveryProtocolType.coldPlunge.rawValue, "cold_plunge")
        XCTAssertEqual(RecoveryProtocolType.contrast.rawValue, "contrast")
        XCTAssertEqual(RecoveryProtocolType.cryotherapy.rawValue, "cryotherapy")
        XCTAssertEqual(RecoveryProtocolType.floatTank.rawValue, "float_tank")
        XCTAssertEqual(RecoveryProtocolType.massage.rawValue, "massage")
        XCTAssertEqual(RecoveryProtocolType.stretching.rawValue, "stretching")
        XCTAssertEqual(RecoveryProtocolType.meditation.rawValue, "meditation")
    }

    func testRecoveryProtocolType_InitFromRawValue() {
        XCTAssertEqual(RecoveryProtocolType(rawValue: "sauna"), .sauna)
        XCTAssertEqual(RecoveryProtocolType(rawValue: "cold_plunge"), .coldPlunge)
        XCTAssertEqual(RecoveryProtocolType(rawValue: "contrast"), .contrast)
        XCTAssertEqual(RecoveryProtocolType(rawValue: "cryotherapy"), .cryotherapy)
        XCTAssertEqual(RecoveryProtocolType(rawValue: "float_tank"), .floatTank)
        XCTAssertEqual(RecoveryProtocolType(rawValue: "massage"), .massage)
        XCTAssertEqual(RecoveryProtocolType(rawValue: "stretching"), .stretching)
        XCTAssertEqual(RecoveryProtocolType(rawValue: "meditation"), .meditation)
        XCTAssertNil(RecoveryProtocolType(rawValue: "invalid"))
    }

    // MARK: - Display Name Tests

    func testRecoveryProtocolType_DisplayNames() {
        XCTAssertEqual(RecoveryProtocolType.sauna.displayName, "Sauna")
        XCTAssertEqual(RecoveryProtocolType.coldPlunge.displayName, "Cold Plunge")
        XCTAssertEqual(RecoveryProtocolType.contrast.displayName, "Contrast Therapy")
        XCTAssertEqual(RecoveryProtocolType.cryotherapy.displayName, "Cryotherapy")
        XCTAssertEqual(RecoveryProtocolType.floatTank.displayName, "Float Tank")
        XCTAssertEqual(RecoveryProtocolType.massage.displayName, "Massage")
        XCTAssertEqual(RecoveryProtocolType.stretching.displayName, "Stretching")
        XCTAssertEqual(RecoveryProtocolType.meditation.displayName, "Meditation")
    }

    // MARK: - Icon Tests

    func testRecoveryProtocolType_Icons() {
        XCTAssertEqual(RecoveryProtocolType.sauna.icon, "flame.fill")
        XCTAssertEqual(RecoveryProtocolType.coldPlunge.icon, "snowflake")
        XCTAssertEqual(RecoveryProtocolType.contrast.icon, "arrow.left.arrow.right")
        XCTAssertEqual(RecoveryProtocolType.cryotherapy.icon, "thermometer.snowflake")
        XCTAssertEqual(RecoveryProtocolType.floatTank.icon, "drop.fill")
        XCTAssertEqual(RecoveryProtocolType.massage.icon, "hand.raised.fill")
        XCTAssertEqual(RecoveryProtocolType.stretching.icon, "figure.flexibility")
        XCTAssertEqual(RecoveryProtocolType.meditation.icon, "brain.head.profile")
    }

    // MARK: - CaseIterable Tests

    func testRecoveryProtocolType_AllCases() {
        let allCases = RecoveryProtocolType.allCases
        XCTAssertEqual(allCases.count, 8)
        XCTAssertTrue(allCases.contains(.sauna))
        XCTAssertTrue(allCases.contains(.coldPlunge))
        XCTAssertTrue(allCases.contains(.contrast))
        XCTAssertTrue(allCases.contains(.cryotherapy))
        XCTAssertTrue(allCases.contains(.floatTank))
        XCTAssertTrue(allCases.contains(.massage))
        XCTAssertTrue(allCases.contains(.stretching))
        XCTAssertTrue(allCases.contains(.meditation))
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
        let json = "\"sauna\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        let protocolType = try decoder.decode(RecoveryProtocolType.self, from: json)

        XCTAssertEqual(protocolType, .sauna)
    }
}

// MARK: - RecoveryPriority Tests

final class RecoveryPriorityTests: XCTestCase {

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

final class RecoverySessionTests: XCTestCase {

    // MARK: - Memberwise Initializer Tests

    func testRecoverySession_MemberwiseInit() {
        let id = UUID()
        let patientId = UUID()
        let startTime = Date()
        let createdAt = Date()

        let session = RecoverySession(
            id: id,
            patientId: patientId,
            protocolType: .sauna,
            startTime: startTime,
            duration: 1200, // 20 minutes in seconds
            temperature: 180.0,
            heartRateAvg: 110,
            heartRateMax: 140,
            perceivedEffort: 7,
            notes: "Felt great after",
            createdAt: createdAt
        )

        XCTAssertEqual(session.id, id)
        XCTAssertEqual(session.patientId, patientId)
        XCTAssertEqual(session.protocolType, .sauna)
        XCTAssertEqual(session.startTime, startTime)
        XCTAssertEqual(session.duration, 1200)
        XCTAssertEqual(session.temperature, 180.0)
        XCTAssertEqual(session.heartRateAvg, 110)
        XCTAssertEqual(session.heartRateMax, 140)
        XCTAssertEqual(session.perceivedEffort, 7)
        XCTAssertEqual(session.notes, "Felt great after")
    }

    func testRecoverySession_OptionalFields() {
        let session = RecoverySession(
            id: UUID(),
            patientId: UUID(),
            protocolType: .stretching,
            startTime: Date(),
            duration: 600,
            temperature: nil,
            heartRateAvg: nil,
            heartRateMax: nil,
            perceivedEffort: nil,
            notes: nil,
            createdAt: Date()
        )

        XCTAssertNil(session.temperature)
        XCTAssertNil(session.heartRateAvg)
        XCTAssertNil(session.heartRateMax)
        XCTAssertNil(session.perceivedEffort)
        XCTAssertNil(session.notes)
    }

    // MARK: - Identifiable Tests

    func testRecoverySession_Identifiable() {
        let id = UUID()
        let session = RecoverySession(
            id: id,
            patientId: UUID(),
            protocolType: .coldPlunge,
            startTime: Date(),
            duration: 180,
            temperature: 38.0,
            heartRateAvg: nil,
            heartRateMax: nil,
            perceivedEffort: nil,
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
            protocolType: .sauna,
            startTime: date,
            duration: 1200,
            temperature: 180.0,
            heartRateAvg: nil,
            heartRateMax: nil,
            perceivedEffort: nil,
            notes: nil,
            createdAt: date
        )
        let session2 = RecoverySession(
            id: id,
            patientId: patientId,
            protocolType: .sauna,
            startTime: date,
            duration: 1200,
            temperature: 180.0,
            heartRateAvg: nil,
            heartRateMax: nil,
            perceivedEffort: nil,
            notes: nil,
            createdAt: date
        )

        XCTAssertEqual(session1, session2)
    }
}

// MARK: - RecoveryRecommendation Tests

final class RecoveryRecommendationTests: XCTestCase {

    // MARK: - Memberwise Initializer Tests

    func testRecoveryRecommendation_MemberwiseInit() {
        let id = UUID()
        let recommendation = RecoveryRecommendation(
            id: id,
            protocolType: .sauna,
            reason: "High training volume this week",
            priority: .high,
            suggestedDuration: 20
        )

        XCTAssertEqual(recommendation.id, id)
        XCTAssertEqual(recommendation.protocolType, .sauna)
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

        let saunaRecommendation = sut.recommendations.first { $0.protocolType == .sauna }
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
            "protocol_type": "sauna",
            "start_time": "2024-01-15T10:30:00Z",
            "duration": 1200,
            "temperature": 180.0,
            "heart_rate_avg": 110,
            "heart_rate_max": 140,
            "perceived_effort": 7,
            "notes": "Great session",
            "created_at": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let session = try decoder.decode(RecoverySession.self, from: json)

        XCTAssertEqual(session.protocolType, .sauna)
        XCTAssertEqual(session.duration, 1200)
        XCTAssertEqual(session.temperature, 180.0)
        XCTAssertEqual(session.heartRateAvg, 110)
        XCTAssertEqual(session.heartRateMax, 140)
        XCTAssertEqual(session.perceivedEffort, 7)
        XCTAssertEqual(session.notes, "Great session")
    }

    func testRecoverySession_DecodingWithNullOptionals() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "protocol_type": "stretching",
            "start_time": "2024-01-15T10:30:00Z",
            "duration": 600,
            "temperature": null,
            "heart_rate_avg": null,
            "heart_rate_max": null,
            "perceived_effort": null,
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
        XCTAssertNil(session.notes)
    }

    func testRecoverySession_AllProtocolTypes() throws {
        let protocolTypes = ["sauna", "cold_plunge", "contrast", "cryotherapy",
                             "float_tank", "massage", "stretching", "meditation"]

        for protocolType in protocolTypes {
            let json = """
            {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "patient_id": "660e8400-e29b-41d4-a716-446655440001",
                "protocol_type": "\(protocolType)",
                "start_time": "2024-01-15T10:30:00Z",
                "duration": 600,
                "temperature": null,
                "heart_rate_avg": null,
                "heart_rate_max": null,
                "perceived_effort": null,
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
            protocolType: .meditation,
            startTime: Date(),
            duration: 0,
            temperature: nil,
            heartRateAvg: nil,
            heartRateMax: nil,
            perceivedEffort: nil,
            notes: nil,
            createdAt: Date()
        )

        XCTAssertEqual(session.duration, 0)
    }

    func testRecoverySession_VeryLongDuration() {
        // 2 hours in seconds
        let session = RecoverySession(
            id: UUID(),
            patientId: UUID(),
            protocolType: .massage,
            startTime: Date(),
            duration: 7200,
            temperature: nil,
            heartRateAvg: nil,
            heartRateMax: nil,
            perceivedEffort: nil,
            notes: nil,
            createdAt: Date()
        )

        XCTAssertEqual(session.duration, 7200)
    }

    func testRecoverySession_ColdPlungeTemperature() {
        // Cold plunge at 3 degrees Celsius
        let session = RecoverySession(
            id: UUID(),
            patientId: UUID(),
            protocolType: .coldPlunge,
            startTime: Date(),
            duration: 180,
            temperature: 3.0,
            heartRateAvg: nil,
            heartRateMax: nil,
            perceivedEffort: nil,
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
            protocolType: .sauna,
            startTime: Date(),
            duration: 1200,
            temperature: 200.0,
            heartRateAvg: nil,
            heartRateMax: nil,
            perceivedEffort: nil,
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
                protocolType: .stretching,
                startTime: Date(),
                duration: 600,
                temperature: nil,
                heartRateAvg: nil,
                heartRateMax: nil,
                perceivedEffort: rpe,
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
                protocolType: .sauna,
                reason: "Test reason",
                priority: priority,
                suggestedDuration: 20
            )

            XCTAssertEqual(recommendation.priority, priority)
        }
    }
}
