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
        let loggedAt = Date()
        let createdAt = Date()

        let session = RecoverySession(
            id: id,
            patientId: patientId,
            protocolType: .saunaTraditional,
            loggedAt: loggedAt,
            durationSeconds: 1200, // 20 minutes
            temperature: 180.0,
            heartRateAvg: 120,
            heartRateMax: 145,
            perceivedEffort: 7,
            rating: 4,
            notes: "Great session",
            createdAt: createdAt
        )

        XCTAssertEqual(session.id, id)
        XCTAssertEqual(session.patientId, patientId)
        XCTAssertEqual(session.protocolType, .saunaTraditional)
        XCTAssertEqual(session.loggedAt, loggedAt)
        XCTAssertEqual(session.durationMinutes, 20)
        XCTAssertEqual(session.durationSeconds, 1200)
        XCTAssertEqual(session.temperature, 180.0)
        XCTAssertEqual(session.heartRateAvg, 120)
        XCTAssertEqual(session.heartRateMax, 145)
        XCTAssertEqual(session.perceivedEffort, 7)
        XCTAssertEqual(session.rating, 4)
        XCTAssertEqual(session.notes, "Great session")
        XCTAssertEqual(session.createdAt, createdAt)
    }

    func testRecoverySessionWithNilOptionals() {
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
        XCTAssertEqual(original.durationSeconds, decoded.durationSeconds)
        XCTAssertEqual(original.temperature, decoded.temperature)
        // heartRateAvg, heartRateMax, perceivedEffort, rating are NOT encoded
        // (excluded from custom encoder as they're not in database schema)
        XCTAssertNil(decoded.heartRateAvg)
        XCTAssertNil(decoded.heartRateMax)
        XCTAssertNil(decoded.perceivedEffort)
        XCTAssertEqual(original.notes, decoded.notes)
    }

    func testRecoverySessionCodingKeysMapping() throws {
        let session = createRecoverySession()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(session)
        let jsonObject = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Verify snake_case keys (per CodingKeys and custom encoder)
        XCTAssertNotNil(jsonObject["patient_id"])
        XCTAssertNotNil(jsonObject["session_type"])  // Not "protocol_type" - CodingKey maps to session_type
        XCTAssertNotNil(jsonObject["logged_at"])
        XCTAssertNotNil(jsonObject["duration_minutes"])
        // Note: heart_rate_avg, heart_rate_max, perceived_effort are NOT encoded (custom encoder excludes them)
        // These fields are only used locally, not stored in database
        XCTAssertNil(jsonObject["heart_rate_avg"])
        XCTAssertNil(jsonObject["heart_rate_max"])
        XCTAssertNil(jsonObject["perceived_effort"])

        // Verify camelCase keys are NOT present
        XCTAssertNil(jsonObject["patientId"])
        XCTAssertNil(jsonObject["protocolType"])
        XCTAssertNil(jsonObject["loggedAt"])
        XCTAssertNil(jsonObject["durationMinutes"])
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
        XCTAssertEqual(allCases.count, 7)
        XCTAssertTrue(allCases.contains(.saunaTraditional))
        XCTAssertTrue(allCases.contains(.saunaInfrared))
        XCTAssertTrue(allCases.contains(.saunaSteam))
        XCTAssertTrue(allCases.contains(.coldPlunge))
        XCTAssertTrue(allCases.contains(.coldShower))
        XCTAssertTrue(allCases.contains(.iceBath))
        XCTAssertTrue(allCases.contains(.contrast))
    }

    func testRecoveryProtocolTypeRawValues() {
        XCTAssertEqual(RecoveryProtocolType.saunaTraditional.rawValue, "sauna_traditional")
        XCTAssertEqual(RecoveryProtocolType.saunaInfrared.rawValue, "sauna_infrared")
        XCTAssertEqual(RecoveryProtocolType.saunaSteam.rawValue, "sauna_steam")
        XCTAssertEqual(RecoveryProtocolType.coldPlunge.rawValue, "cold_plunge")
        XCTAssertEqual(RecoveryProtocolType.coldShower.rawValue, "cold_shower")
        XCTAssertEqual(RecoveryProtocolType.iceBath.rawValue, "ice_bath")
        XCTAssertEqual(RecoveryProtocolType.contrast.rawValue, "contrast")
    }

    func testRecoveryProtocolTypeDisplayNames() {
        XCTAssertEqual(RecoveryProtocolType.saunaTraditional.displayName, "Traditional Sauna")
        XCTAssertEqual(RecoveryProtocolType.saunaInfrared.displayName, "Infrared Sauna")
        XCTAssertEqual(RecoveryProtocolType.saunaSteam.displayName, "Steam Room")
        XCTAssertEqual(RecoveryProtocolType.coldPlunge.displayName, "Cold Plunge")
        XCTAssertEqual(RecoveryProtocolType.coldShower.displayName, "Cold Shower")
        XCTAssertEqual(RecoveryProtocolType.iceBath.displayName, "Ice Bath")
        XCTAssertEqual(RecoveryProtocolType.contrast.displayName, "Contrast Therapy")
    }

    func testRecoveryProtocolTypeDisplayNamesNotEmpty() {
        for protocolType in RecoveryProtocolType.allCases {
            XCTAssertFalse(protocolType.displayName.isEmpty)
            XCTAssertTrue(protocolType.displayName.first?.isUppercase == true,
                          "Display name should start with uppercase: \(protocolType.displayName)")
        }
    }

    func testRecoveryProtocolTypeIcons() {
        XCTAssertEqual(RecoveryProtocolType.saunaTraditional.icon, "flame.fill")
        XCTAssertEqual(RecoveryProtocolType.saunaInfrared.icon, "flame")
        XCTAssertEqual(RecoveryProtocolType.saunaSteam.icon, "cloud.fill")
        XCTAssertEqual(RecoveryProtocolType.coldPlunge.icon, "snowflake")
        XCTAssertEqual(RecoveryProtocolType.coldShower.icon, "drop.fill")
        XCTAssertEqual(RecoveryProtocolType.iceBath.icon, "snowflake.circle.fill")
        XCTAssertEqual(RecoveryProtocolType.contrast.icon, "arrow.left.arrow.right")
    }

    func testRecoveryProtocolTypeIconsNotEmpty() {
        for protocolType in RecoveryProtocolType.allCases {
            XCTAssertFalse(protocolType.icon.isEmpty)
        }
    }

    func testRecoveryProtocolTypeInitFromRawValue() {
        XCTAssertEqual(RecoveryProtocolType(rawValue: "sauna_traditional"), .saunaTraditional)
        XCTAssertEqual(RecoveryProtocolType(rawValue: "cold_plunge"), .coldPlunge)
        XCTAssertEqual(RecoveryProtocolType(rawValue: "ice_bath"), .iceBath)
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
            protocolType: .saunaTraditional,
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
            protocolType: .iceBath,
            reason: "Muscle soreness",
            priority: .low,
            suggestedDuration: 10
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

    // MARK: - Duration Conversion Tests

    func testRecoverySession_DurationSecondsToMinutes() {
        let session = RecoverySession(
            id: UUID(),
            patientId: UUID(),
            protocolType: .coldPlunge,
            loggedAt: Date(),
            durationSeconds: 180, // 3 minutes
            temperature: nil,
            heartRateAvg: nil,
            heartRateMax: nil,
            perceivedEffort: nil,
            rating: nil,
            notes: nil,
            createdAt: Date()
        )

        XCTAssertEqual(session.durationMinutes, 3)
        XCTAssertEqual(session.durationSeconds, 180)
    }

    func testRecoverySession_DurationConversion_LongSession() {
        let session = RecoverySession(
            id: UUID(),
            patientId: UUID(),
            protocolType: .saunaInfrared,
            loggedAt: Date(),
            durationSeconds: 3600, // 60 minutes
            temperature: 140.0,
            heartRateAvg: nil,
            heartRateMax: nil,
            perceivedEffort: nil,
            rating: nil,
            notes: nil,
            createdAt: Date()
        )

        XCTAssertEqual(session.durationMinutes, 60)
    }

    // MARK: - Intensity Validation Tests

    func testRecoverySession_PerceivedEffort_ValidRange() {
        for effort in 1...10 {
            let session = RecoverySession(
                id: UUID(),
                patientId: UUID(),
                protocolType: .saunaTraditional,
                loggedAt: Date(),
                durationSeconds: 1200,
                temperature: nil,
                heartRateAvg: nil,
                heartRateMax: nil,
                perceivedEffort: effort,
                rating: nil,
                notes: nil,
                createdAt: Date()
            )
            XCTAssertEqual(session.perceivedEffort, effort)
        }
    }

    func testRecoverySession_Rating_ValidRange() {
        for rating in 1...5 {
            let session = RecoverySession(
                id: UUID(),
                patientId: UUID(),
                protocolType: .coldPlunge,
                loggedAt: Date(),
                durationSeconds: 180,
                temperature: nil,
                heartRateAvg: nil,
                heartRateMax: nil,
                perceivedEffort: nil,
                rating: rating,
                notes: nil,
                createdAt: Date()
            )
            XCTAssertEqual(session.rating, rating)
        }
    }

    // MARK: - RecoveryProtocolType Heat/Cold Classification Tests

    func testRecoveryProtocolType_IsHeatTherapy() {
        XCTAssertTrue(RecoveryProtocolType.saunaTraditional.isHeatTherapy)
        XCTAssertTrue(RecoveryProtocolType.saunaInfrared.isHeatTherapy)
        XCTAssertTrue(RecoveryProtocolType.saunaSteam.isHeatTherapy)
        XCTAssertFalse(RecoveryProtocolType.coldPlunge.isHeatTherapy)
        XCTAssertFalse(RecoveryProtocolType.coldShower.isHeatTherapy)
        XCTAssertFalse(RecoveryProtocolType.iceBath.isHeatTherapy)
        XCTAssertFalse(RecoveryProtocolType.contrast.isHeatTherapy)
    }

    func testRecoveryProtocolType_IsColdTherapy() {
        XCTAssertFalse(RecoveryProtocolType.saunaTraditional.isColdTherapy)
        XCTAssertFalse(RecoveryProtocolType.saunaInfrared.isColdTherapy)
        XCTAssertFalse(RecoveryProtocolType.saunaSteam.isColdTherapy)
        XCTAssertTrue(RecoveryProtocolType.coldPlunge.isColdTherapy)
        XCTAssertTrue(RecoveryProtocolType.coldShower.isColdTherapy)
        XCTAssertTrue(RecoveryProtocolType.iceBath.isColdTherapy)
        XCTAssertFalse(RecoveryProtocolType.contrast.isColdTherapy)
    }

    func testRecoveryProtocolType_Contrast_NeitherHeatNorCold() {
        // Contrast therapy is neither pure heat nor pure cold
        XCTAssertFalse(RecoveryProtocolType.contrast.isHeatTherapy)
        XCTAssertFalse(RecoveryProtocolType.contrast.isColdTherapy)
    }

    // MARK: - Sessions With Missing Data Tests

    func testRecoverySession_MinimalData() {
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

        XCTAssertNotNil(session.id)
        XCTAssertEqual(session.durationMinutes, 10)
        XCTAssertNil(session.temperature)
        XCTAssertNil(session.heartRateAvg)
        XCTAssertNil(session.perceivedEffort)
    }

    func testRecoverySession_PartialData() {
        // Only temperature provided, no heart rate data
        let session = RecoverySession(
            id: UUID(),
            patientId: UUID(),
            protocolType: .saunaTraditional,
            loggedAt: Date(),
            durationSeconds: 1200,
            temperature: 175.0,
            heartRateAvg: nil,
            heartRateMax: nil,
            perceivedEffort: 6,
            rating: nil,
            notes: "Good session",
            createdAt: Date()
        )

        XCTAssertEqual(session.temperature, 175.0)
        XCTAssertNil(session.heartRateAvg)
        XCTAssertEqual(session.perceivedEffort, 6)
        XCTAssertNil(session.rating)
    }

    // MARK: - Temperature Validation Tests

    func testRecoverySession_SaunaTemperature_Fahrenheit() {
        let session = RecoverySession(
            id: UUID(),
            patientId: UUID(),
            protocolType: .saunaTraditional,
            loggedAt: Date(),
            durationSeconds: 1200,
            temperature: 185.0, // Fahrenheit
            heartRateAvg: nil,
            heartRateMax: nil,
            perceivedEffort: nil,
            rating: nil,
            notes: nil,
            createdAt: Date()
        )

        XCTAssertEqual(session.temperature, 185.0)
        XCTAssertTrue(session.protocolType.isHeatTherapy)
    }

    func testRecoverySession_ColdPlunge_Temperature_Celsius() {
        let session = RecoverySession(
            id: UUID(),
            patientId: UUID(),
            protocolType: .coldPlunge,
            loggedAt: Date(),
            durationSeconds: 180,
            temperature: 3.5, // Celsius
            heartRateAvg: nil,
            heartRateMax: nil,
            perceivedEffort: nil,
            rating: nil,
            notes: nil,
            createdAt: Date()
        )

        XCTAssertEqual(session.temperature, 3.5)
        XCTAssertTrue(session.protocolType.isColdTherapy)
    }

    // MARK: - Heart Rate Consistency Tests

    func testRecoverySession_HeartRate_AvgLessThanMax() {
        let session = RecoverySession(
            id: UUID(),
            patientId: UUID(),
            protocolType: .saunaTraditional,
            loggedAt: Date(),
            durationSeconds: 1200,
            temperature: 180.0,
            heartRateAvg: 110,
            heartRateMax: 145,
            perceivedEffort: nil,
            rating: nil,
            notes: nil,
            createdAt: Date()
        )

        if let avg = session.heartRateAvg, let max = session.heartRateMax {
            XCTAssertLessThanOrEqual(avg, max)
        }
    }

    // MARK: - Concurrent Sessions Tests

    func testRecoverySessions_DifferentProtocols_SameTime() {
        let loggedAt = Date()

        let saunaSession = RecoverySession(
            id: UUID(),
            patientId: UUID(),
            protocolType: .saunaTraditional,
            loggedAt: loggedAt,
            durationSeconds: 1200,
            temperature: 180.0,
            heartRateAvg: nil,
            heartRateMax: nil,
            perceivedEffort: nil,
            rating: nil,
            notes: nil,
            createdAt: loggedAt
        )

        let coldSession = RecoverySession(
            id: UUID(),
            patientId: saunaSession.patientId,
            protocolType: .coldPlunge,
            loggedAt: loggedAt.addingTimeInterval(1200), // After sauna
            durationSeconds: 180,
            temperature: 4.0,
            heartRateAvg: nil,
            heartRateMax: nil,
            perceivedEffort: nil,
            rating: nil,
            notes: nil,
            createdAt: loggedAt.addingTimeInterval(1200)
        )

        // Verify they are different sessions
        XCTAssertNotEqual(saunaSession.id, coldSession.id)
        XCTAssertEqual(saunaSession.patientId, coldSession.patientId)
        XCTAssertNotEqual(saunaSession.protocolType, coldSession.protocolType)
    }

    // MARK: - Timezone Handling Tests

    func testRecoverySession_TimezoneHandling() throws {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15
        components.hour = 18
        components.minute = 30
        components.timeZone = TimeZone(identifier: "America/Los_Angeles")

        let loggedAt = calendar.date(from: components)!

        let session = RecoverySession(
            id: UUID(),
            patientId: UUID(),
            protocolType: .saunaTraditional,
            loggedAt: loggedAt,
            durationSeconds: 1200,
            temperature: nil,
            heartRateAvg: nil,
            heartRateMax: nil,
            perceivedEffort: nil,
            rating: nil,
            notes: nil,
            createdAt: loggedAt
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(session)
        XCTAssertNotNil(data)
    }

    // MARK: - Helpers

    private func createRecoverySession() -> RecoverySession {
        RecoverySession(
            id: UUID(),
            patientId: UUID(),
            protocolType: .saunaTraditional,
            loggedAt: Date(),
            durationSeconds: 1200,
            temperature: 180.0,
            heartRateAvg: 120,
            heartRateMax: 145,
            perceivedEffort: 7,
            rating: 4,
            notes: "Great session",
            createdAt: Date()
        )
    }
}
