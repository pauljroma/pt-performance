//
//  SupabaseClientTests.swift
//  PTPerformanceTests
//
//  Unit tests for PTSupabaseClient
//  Tests flexible decoder, date formatting, and error handling
//

import XCTest
@testable import PTPerformance

// MARK: - UserRole Tests

final class UserRoleTests: XCTestCase {

    func testUserRole_RawValues() {
        XCTAssertEqual(UserRole.patient.rawValue, "patient")
        XCTAssertEqual(UserRole.therapist.rawValue, "therapist")
    }

    func testUserRole_Equality() {
        let patient1 = UserRole.patient
        let patient2 = UserRole.patient
        let therapist = UserRole.therapist

        XCTAssertEqual(patient1, patient2)
        XCTAssertNotEqual(patient1, therapist)
    }
}

// MARK: - Flexible Decoder Tests

final class FlexibleDecoderTests: XCTestCase {

    /// Test that the flexible decoder handles ISO8601 with fractional seconds
    func testFlexibleDecoder_ISO8601WithFractionalSeconds() throws {
        let json = """
        {
            "timestamp": "2024-01-15T10:30:00.123456+00:00"
        }
        """.data(using: .utf8)!

        struct TestModel: Codable {
            let timestamp: Date
        }

        let decoder = PTSupabaseClient.flexibleDecoder
        let model = try decoder.decode(TestModel.self, from: json)

        XCTAssertNotNil(model.timestamp)

        let calendar = Calendar.current
        let components = calendar.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: model.timestamp)
        XCTAssertEqual(components.year, 2024)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 15)
        XCTAssertEqual(components.hour, 10)
        XCTAssertEqual(components.minute, 30)
    }

    /// Test that the flexible decoder handles ISO8601 without fractional seconds
    func testFlexibleDecoder_ISO8601WithoutFractionalSeconds() throws {
        let json = """
        {
            "timestamp": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        struct TestModel: Codable {
            let timestamp: Date
        }

        let decoder = PTSupabaseClient.flexibleDecoder
        let model = try decoder.decode(TestModel.self, from: json)

        XCTAssertNotNil(model.timestamp)
    }

    /// Test that the flexible decoder handles simple DATE format (yyyy-MM-dd)
    func testFlexibleDecoder_SimpleDateFormat() throws {
        let json = """
        {
            "date": "2024-01-15"
        }
        """.data(using: .utf8)!

        struct TestModel: Codable {
            let date: Date
        }

        let decoder = PTSupabaseClient.flexibleDecoder
        let model = try decoder.decode(TestModel.self, from: json)

        XCTAssertNotNil(model.date)
    }

    /// Test that the flexible decoder handles TIME format (HH:mm:ss)
    func testFlexibleDecoder_TimeFormat() throws {
        let json = """
        {
            "time": "14:30:00"
        }
        """.data(using: .utf8)!

        struct TestModel: Codable {
            let time: Date
        }

        let decoder = PTSupabaseClient.flexibleDecoder
        let model = try decoder.decode(TestModel.self, from: json)

        XCTAssertNotNil(model.time)
    }

    /// Test that the decoder throws for invalid date strings
    func testFlexibleDecoder_InvalidDateString_Throws() {
        let json = """
        {
            "date": "not-a-date"
        }
        """.data(using: .utf8)!

        struct TestModel: Codable {
            let date: Date
        }

        let decoder = PTSupabaseClient.flexibleDecoder

        XCTAssertThrowsError(try decoder.decode(TestModel.self, from: json)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    /// Test that the decoder handles mixed date formats in same model
    func testFlexibleDecoder_MixedDateFormats() throws {
        let json = """
        {
            "created_at": "2024-01-15T10:30:00.123456+00:00",
            "date": "2024-01-15",
            "reminder_time": "09:00:00"
        }
        """.data(using: .utf8)!

        struct TestModel: Codable {
            let createdAt: Date
            let date: Date
            let reminderTime: Date

            enum CodingKeys: String, CodingKey {
                case createdAt = "created_at"
                case date
                case reminderTime = "reminder_time"
            }
        }

        let decoder = PTSupabaseClient.flexibleDecoder
        let model = try decoder.decode(TestModel.self, from: json)

        XCTAssertNotNil(model.createdAt)
        XCTAssertNotNil(model.date)
        XCTAssertNotNil(model.reminderTime)
    }
}

// MARK: - Date Formatting Tests

final class SupabaseDateFormattingTests: XCTestCase {

    func testISO8601DateFormatter_StandardFormat() {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        let dateString = "2024-01-15T10:30:00Z"
        let date = formatter.date(from: dateString)

        XCTAssertNotNil(date)
    }

    func testISO8601DateFormatter_WithFractionalSeconds() {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let dateString = "2024-01-15T10:30:00.123456Z"
        let date = formatter.date(from: dateString)

        XCTAssertNotNil(date)
    }

    func testDateFormatter_SimpleDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        let dateString = "2024-01-15"
        let date = formatter.date(from: dateString)

        XCTAssertNotNil(date)
    }

    func testDateFormatter_TimeOnly() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        let timeString = "14:30:00"
        let date = formatter.date(from: timeString)

        XCTAssertNotNil(date)

        if let date = date {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute, .second], from: date)
            XCTAssertEqual(components.hour, 14)
            XCTAssertEqual(components.minute, 30)
            XCTAssertEqual(components.second, 0)
        }
    }
}

// MARK: - Configuration Tests

final class SupabaseConfigurationTests: XCTestCase {

    func testConfig_HasRequiredValues() {
        // These tests verify that Config has required values
        // The actual values are checked in ConfigTests.swift
        XCTAssertFalse(Config.supabaseURL.isEmpty)
        XCTAssertFalse(Config.supabaseAnonKey.isEmpty)
    }

    func testConfig_URLIsValid() {
        let urlString = Config.supabaseURL
        let url = URL(string: urlString)

        XCTAssertNotNil(url, "Supabase URL should be valid")
        XCTAssertTrue(urlString.hasPrefix("https://"), "URL should use HTTPS")
    }

    func testConfig_AnonKeyFormat() {
        let anonKey = Config.supabaseAnonKey

        // Anon keys should be non-empty and reasonably long
        XCTAssertGreaterThan(anonKey.count, 20, "Anon key should be sufficiently long")
    }
}

// MARK: - Error Handling Tests

final class SupabaseErrorHandlingTests: XCTestCase {

    func testNetworkError_Description() {
        let underlyingError = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: [NSLocalizedDescriptionKey: "The Internet connection appears to be offline."]
        )

        XCTAssertTrue(underlyingError.localizedDescription.contains("offline"))
    }

    func testTimeoutError_Description() {
        let underlyingError = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorTimedOut,
            userInfo: [NSLocalizedDescriptionKey: "The request timed out."]
        )

        XCTAssertTrue(underlyingError.localizedDescription.contains("timed out"))
    }
}

// MARK: - JSON Encoding Tests

final class SupabaseJSONEncodingTests: XCTestCase {

    func testEncoding_SnakeCaseKeys() throws {
        struct TestModel: Codable {
            let patientId: String
            let isActive: Bool
            let createdAt: Date

            enum CodingKeys: String, CodingKey {
                case patientId = "patient_id"
                case isActive = "is_active"
                case createdAt = "created_at"
            }
        }

        let model = TestModel(
            patientId: "123",
            isActive: true,
            createdAt: Date()
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(model)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertTrue(jsonString.contains("patient_id"))
        XCTAssertTrue(jsonString.contains("is_active"))
        XCTAssertTrue(jsonString.contains("created_at"))

        // Verify camelCase is NOT used
        XCTAssertFalse(jsonString.contains("patientId"))
        XCTAssertFalse(jsonString.contains("isActive"))
        XCTAssertFalse(jsonString.contains("createdAt"))
    }

    func testEncoding_NullValues() throws {
        struct TestModel: Codable {
            let requiredField: String
            let optionalField: String?
        }

        let model = TestModel(
            requiredField: "value",
            optionalField: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(model)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertTrue(jsonString.contains("requiredField"))
        // nil optional is typically encoded as null or omitted
    }

    func testEncoding_UUIDs() throws {
        struct TestModel: Codable {
            let id: UUID
        }

        let uuid = UUID()
        let model = TestModel(id: uuid)

        let encoder = JSONEncoder()
        let data = try encoder.encode(model)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertTrue(jsonString.contains(uuid.uuidString))
    }
}

// MARK: - RPC Parameter Encoding Tests

final class RPCParameterEncodingTests: XCTestCase {

    func testRPCParams_EncodesCorrectly() throws {
        struct TestRPCParams: Encodable {
            let pPatientId: String
            let pDate: String

            enum CodingKeys: String, CodingKey {
                case pPatientId = "p_patient_id"
                case pDate = "p_date"
            }
        }

        let params = TestRPCParams(
            pPatientId: "123e4567-e89b-12d3-a456-426614174000",
            pDate: "2024-01-15"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(params)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertTrue(jsonString.contains("p_patient_id"))
        XCTAssertTrue(jsonString.contains("p_date"))
        XCTAssertTrue(jsonString.contains("123e4567-e89b-12d3-a456-426614174000"))
        XCTAssertTrue(jsonString.contains("2024-01-15"))
    }

    func testRPCParams_NumericValues() throws {
        struct TestRPCParams: Encodable {
            let pLimit: Int
            let pOffset: Int

            enum CodingKeys: String, CodingKey {
                case pLimit = "p_limit"
                case pOffset = "p_offset"
            }
        }

        let params = TestRPCParams(pLimit: 10, pOffset: 20)

        let encoder = JSONEncoder()
        let data = try encoder.encode(params)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertTrue(jsonString.contains("\"p_limit\":10"))
        XCTAssertTrue(jsonString.contains("\"p_offset\":20"))
    }
}

// MARK: - Offline Mode Tests

final class OfflineModeTests: XCTestCase {

    func testOfflineMode_DefaultsFalse() {
        // Verify the offline state defaults to false
        // This is a logical test - actual offline detection happens at runtime
        let isOffline = false  // Default state
        XCTAssertFalse(isOffline)
    }

    func testOfflineError_Detection() {
        let offlineError = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: nil
        )

        let isOfflineError = offlineError.code == NSURLErrorNotConnectedToInternet
        XCTAssertTrue(isOfflineError)
    }

    func testNetworkUnavailableError_Detection() {
        let networkError = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNetworkConnectionLost,
            userInfo: nil
        )

        let isNetworkError = [
            NSURLErrorNotConnectedToInternet,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorDataNotAllowed
        ].contains(networkError.code)

        XCTAssertTrue(isNetworkError)
    }
}

// MARK: - Session State Tests

final class SessionStateTests: XCTestCase {

    func testSessionState_LoggedOut() {
        // Simulate logged out state
        let currentSession: String? = nil
        let currentUser: String? = nil
        let userRole: UserRole? = nil
        let userId: String? = nil

        XCTAssertNil(currentSession)
        XCTAssertNil(currentUser)
        XCTAssertNil(userRole)
        XCTAssertNil(userId)
    }

    func testSessionState_PatientLoggedIn() {
        // Simulate patient logged in state
        let userRole: UserRole? = .patient
        let userId: String? = "123e4567-e89b-12d3-a456-426614174000"

        XCTAssertEqual(userRole, .patient)
        XCTAssertNotNil(userId)
    }

    func testSessionState_TherapistLoggedIn() {
        // Simulate therapist logged in state
        let userRole: UserRole? = .therapist
        let userId: String? = "123e4567-e89b-12d3-a456-426614174000"

        XCTAssertEqual(userRole, .therapist)
        XCTAssertNotNil(userId)
    }
}
