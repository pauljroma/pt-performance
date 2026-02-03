//
//  RecoverySessionTests.swift
//  PTPerformanceTests
//
//  Unit tests for RecoverySession, RecoveryProtocolType, RecoveryRecommendation, and RecoveryPriority models
//

import XCTest
@testable import PTPerformance

final class RecoverySessionTests: XCTestCase {

    // MARK: - RecoverySession Initialization Tests

    func testRecoverySessionInitialization() {
        let id = UUID()
        let patientId = UUID()
        let startTime = Date()
        let createdAt = Date()

        let session = RecoverySession(
            id: id,
            patientId: patientId,
            protocolType: .sauna,
            startTime: startTime,
            duration: 1200, // 20 minutes
            temperature: 180.0,
            heartRateAvg: 120,
            heartRateMax: 145,
            perceivedEffort: 7,
            notes: "Great session",
            createdAt: createdAt
        )

        XCTAssertEqual(session.id, id)
        XCTAssertEqual(session.patientId, patientId)
        XCTAssertEqual(session.protocolType, .sauna)
        XCTAssertEqual(session.startTime, startTime)
        XCTAssertEqual(session.duration, 1200)
        XCTAssertEqual(session.temperature, 180.0)
        XCTAssertEqual(session.heartRateAvg, 120)
        XCTAssertEqual(session.heartRateMax, 145)
        XCTAssertEqual(session.perceivedEffort, 7)
        XCTAssertEqual(session.notes, "Great session")
        XCTAssertEqual(session.createdAt, createdAt)
    }

    func testRecoverySessionWithNilOptionals() {
        let session = RecoverySession(
            id: UUID(),
            patientId: UUID(),
            protocolType: .meditation,
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

    // MARK: - RecoverySession Codable Tests

    func testRecoverySessionEncodeDecode() throws {
        let original = createRecoverySession()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(RecoverySession.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.patientId, decoded.patientId)
        XCTAssertEqual(original.protocolType, decoded.protocolType)
        XCTAssertEqual(original.duration, decoded.duration)
        XCTAssertEqual(original.temperature, decoded.temperature)
        XCTAssertEqual(original.heartRateAvg, decoded.heartRateAvg)
        XCTAssertEqual(original.heartRateMax, decoded.heartRateMax)
        XCTAssertEqual(original.perceivedEffort, decoded.perceivedEffort)
        XCTAssertEqual(original.notes, decoded.notes)
    }

    func testRecoverySessionCodingKeysMapping() throws {
        let session = createRecoverySession()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(session)
        let jsonObject = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Verify snake_case keys
        XCTAssertNotNil(jsonObject["patient_id"])
        XCTAssertNotNil(jsonObject["protocol_type"])
        XCTAssertNotNil(jsonObject["start_time"])
        XCTAssertNotNil(jsonObject["heart_rate_avg"])
        XCTAssertNotNil(jsonObject["heart_rate_max"])
        XCTAssertNotNil(jsonObject["perceived_effort"])
        XCTAssertNotNil(jsonObject["created_at"])

        // Verify camelCase keys are NOT present
        XCTAssertNil(jsonObject["patientId"])
        XCTAssertNil(jsonObject["protocolType"])
        XCTAssertNil(jsonObject["startTime"])
        XCTAssertNil(jsonObject["heartRateAvg"])
        XCTAssertNil(jsonObject["heartRateMax"])
        XCTAssertNil(jsonObject["perceivedEffort"])
    }

    func testRecoverySessionHashable() {
        let session1 = createRecoverySession()
        let session2 = createRecoverySession()

        var set = Set<RecoverySession>()
        set.insert(session1)
        set.insert(session2)

        XCTAssertEqual(set.count, 2)
    }

    // MARK: - RecoveryProtocolType Tests

    func testRecoveryProtocolTypeAllCases() {
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

    func testRecoveryProtocolTypeRawValues() {
        XCTAssertEqual(RecoveryProtocolType.sauna.rawValue, "sauna")
        XCTAssertEqual(RecoveryProtocolType.coldPlunge.rawValue, "cold_plunge")
        XCTAssertEqual(RecoveryProtocolType.contrast.rawValue, "contrast")
        XCTAssertEqual(RecoveryProtocolType.cryotherapy.rawValue, "cryotherapy")
        XCTAssertEqual(RecoveryProtocolType.floatTank.rawValue, "float_tank")
        XCTAssertEqual(RecoveryProtocolType.massage.rawValue, "massage")
        XCTAssertEqual(RecoveryProtocolType.stretching.rawValue, "stretching")
        XCTAssertEqual(RecoveryProtocolType.meditation.rawValue, "meditation")
    }

    func testRecoveryProtocolTypeDisplayNames() {
        XCTAssertEqual(RecoveryProtocolType.sauna.displayName, "Sauna")
        XCTAssertEqual(RecoveryProtocolType.coldPlunge.displayName, "Cold Plunge")
        XCTAssertEqual(RecoveryProtocolType.contrast.displayName, "Contrast Therapy")
        XCTAssertEqual(RecoveryProtocolType.cryotherapy.displayName, "Cryotherapy")
        XCTAssertEqual(RecoveryProtocolType.floatTank.displayName, "Float Tank")
        XCTAssertEqual(RecoveryProtocolType.massage.displayName, "Massage")
        XCTAssertEqual(RecoveryProtocolType.stretching.displayName, "Stretching")
        XCTAssertEqual(RecoveryProtocolType.meditation.displayName, "Meditation")
    }

    func testRecoveryProtocolTypeDisplayNamesNotEmpty() {
        for protocolType in RecoveryProtocolType.allCases {
            XCTAssertFalse(protocolType.displayName.isEmpty)
            XCTAssertTrue(protocolType.displayName.first?.isUppercase == true,
                          "Display name should start with uppercase: \(protocolType.displayName)")
        }
    }

    func testRecoveryProtocolTypeIcons() {
        XCTAssertEqual(RecoveryProtocolType.sauna.icon, "flame.fill")
        XCTAssertEqual(RecoveryProtocolType.coldPlunge.icon, "snowflake")
        XCTAssertEqual(RecoveryProtocolType.contrast.icon, "arrow.left.arrow.right")
        XCTAssertEqual(RecoveryProtocolType.cryotherapy.icon, "thermometer.snowflake")
        XCTAssertEqual(RecoveryProtocolType.floatTank.icon, "drop.fill")
        XCTAssertEqual(RecoveryProtocolType.massage.icon, "hand.raised.fill")
        XCTAssertEqual(RecoveryProtocolType.stretching.icon, "figure.flexibility")
        XCTAssertEqual(RecoveryProtocolType.meditation.icon, "brain.head.profile")
    }

    func testRecoveryProtocolTypeIconsNotEmpty() {
        for protocolType in RecoveryProtocolType.allCases {
            XCTAssertFalse(protocolType.icon.isEmpty)
        }
    }

    func testRecoveryProtocolTypeInitFromRawValue() {
        XCTAssertEqual(RecoveryProtocolType(rawValue: "sauna"), .sauna)
        XCTAssertEqual(RecoveryProtocolType(rawValue: "cold_plunge"), .coldPlunge)
        XCTAssertEqual(RecoveryProtocolType(rawValue: "float_tank"), .floatTank)
        XCTAssertNil(RecoveryProtocolType(rawValue: "invalid"))
        XCTAssertNil(RecoveryProtocolType(rawValue: ""))
    }

    func testRecoveryProtocolTypeCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for protocolType in RecoveryProtocolType.allCases {
            let data = try encoder.encode(protocolType)
            let decoded = try decoder.decode(RecoveryProtocolType.self, from: data)
            XCTAssertEqual(decoded, protocolType)
        }
    }

    // MARK: - RecoveryRecommendation Tests

    func testRecoveryRecommendationInitialization() {
        let id = UUID()
        let recommendation = RecoveryRecommendation(
            id: id,
            protocolType: .coldPlunge,
            reason: "High training load yesterday",
            priority: .high,
            suggestedDuration: 15
        )

        XCTAssertEqual(recommendation.id, id)
        XCTAssertEqual(recommendation.protocolType, .coldPlunge)
        XCTAssertEqual(recommendation.reason, "High training load yesterday")
        XCTAssertEqual(recommendation.priority, .high)
        XCTAssertEqual(recommendation.suggestedDuration, 15)
    }

    func testRecoveryRecommendationCodable() throws {
        let original = RecoveryRecommendation(
            id: UUID(),
            protocolType: .sauna,
            reason: "Recovery day",
            priority: .medium,
            suggestedDuration: 20
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RecoveryRecommendation.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.protocolType, decoded.protocolType)
        XCTAssertEqual(original.reason, decoded.reason)
        XCTAssertEqual(original.priority, decoded.priority)
        XCTAssertEqual(original.suggestedDuration, decoded.suggestedDuration)
    }

    func testRecoveryRecommendationCodingKeysMapping() throws {
        let recommendation = RecoveryRecommendation(
            id: UUID(),
            protocolType: .massage,
            reason: "Muscle soreness",
            priority: .low,
            suggestedDuration: 30
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(recommendation)
        let jsonObject = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Verify snake_case keys
        XCTAssertNotNil(jsonObject["protocol_type"])
        XCTAssertNotNil(jsonObject["suggested_duration"])

        // Verify camelCase keys are NOT present
        XCTAssertNil(jsonObject["protocolType"])
        XCTAssertNil(jsonObject["suggestedDuration"])
    }

    // MARK: - RecoveryPriority Tests

    func testRecoveryPriorityRawValues() {
        XCTAssertEqual(RecoveryPriority.high.rawValue, "high")
        XCTAssertEqual(RecoveryPriority.medium.rawValue, "medium")
        XCTAssertEqual(RecoveryPriority.low.rawValue, "low")
    }

    func testRecoveryPriorityInitFromRawValue() {
        XCTAssertEqual(RecoveryPriority(rawValue: "high"), .high)
        XCTAssertEqual(RecoveryPriority(rawValue: "medium"), .medium)
        XCTAssertEqual(RecoveryPriority(rawValue: "low"), .low)
        XCTAssertNil(RecoveryPriority(rawValue: "invalid"))
    }

    func testRecoveryPriorityCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let priorities: [RecoveryPriority] = [.high, .medium, .low]
        for priority in priorities {
            let data = try encoder.encode(priority)
            let decoded = try decoder.decode(RecoveryPriority.self, from: data)
            XCTAssertEqual(decoded, priority)
        }
    }

    // MARK: - Helpers

    private func createRecoverySession() -> RecoverySession {
        RecoverySession(
            id: UUID(),
            patientId: UUID(),
            protocolType: .sauna,
            startTime: Date(),
            duration: 1200,
            temperature: 180.0,
            heartRateAvg: 120,
            heartRateMax: 145,
            perceivedEffort: 7,
            notes: "Great session",
            createdAt: Date()
        )
    }
}
