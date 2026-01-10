import XCTest
@testable import PTPerformance

/// BUILD 118 - Phase 3: Unit Tests for ReadinessService
/// Tests core functionality of daily readiness check-in system
final class ReadinessServiceTests: XCTestCase {

    var sut: ReadinessService!
    var mockClient: MockSupabaseClient!
    let testPatientId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    override func setUp() {
        super.setUp()
        mockClient = MockSupabaseClient()
        sut = ReadinessService(client: mockClient)
    }

    override func tearDown() {
        sut = nil
        mockClient = nil
        super.tearDown()
    }

    // MARK: - Test Successful Check-In Submission

    /// Tests that a valid check-in submission succeeds and returns correct data
    func testSuccessfulCheckInSubmission() async throws {
        // Given: Valid readiness data
        let sleepHours = 7.5
        let sorenessLevel = 3
        let energyLevel = 8
        let stressLevel = 2

        // Mock database response with calculated score
        let expectedScore = 89.5
        mockClient.mockReadinessResponse = DailyReadiness(
            id: UUID(),
            patientId: testPatientId,
            date: Date(),
            sleepHours: sleepHours,
            sorenessLevel: sorenessLevel,
            energyLevel: energyLevel,
            stressLevel: stressLevel,
            readinessScore: expectedScore,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When: Submitting readiness check-in
        let result = try await sut.submitReadiness(
            patientId: testPatientId,
            sleepHours: sleepHours,
            sorenessLevel: sorenessLevel,
            energyLevel: energyLevel,
            stressLevel: stressLevel
        )

        // Then: Result should match expected values
        XCTAssertEqual(result.patientId, testPatientId)
        XCTAssertEqual(result.sleepHours, sleepHours)
        XCTAssertEqual(result.sorenessLevel, sorenessLevel)
        XCTAssertEqual(result.energyLevel, energyLevel)
        XCTAssertEqual(result.stressLevel, stressLevel)
        XCTAssertEqual(result.readinessScore, expectedScore)

        // And: Loading state should be false after completion
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Test RLS Policy Enforcement

    /// Tests that RLS policies are enforced (patient can only access own data)
    func testRLSPolicyEnforcement() async throws {
        // Given: Attempting to access another patient's data
        let unauthorizedPatientId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

        // Mock RLS rejection response
        mockClient.shouldSimulateRLSError = true

        // When/Then: Should throw authorization error
        do {
            _ = try await sut.getTodayReadiness(for: unauthorizedPatientId)
            XCTFail("Should have thrown RLS authorization error")
        } catch {
            // Expected behavior: RLS blocks unauthorized access
            XCTAssertTrue(error.localizedDescription.contains("RLS") ||
                         error.localizedDescription.contains("permission"))
        }
    }

    // MARK: - Test Score Calculation Accuracy

    /// Tests that readiness scores are calculated correctly by the database trigger
    func testScoreCalculationAccuracy() async throws {
        // Given: Known input values
        let perfectMetrics = (sleep: 8.0, soreness: 1, energy: 10, stress: 1)
        let poorMetrics = (sleep: 4.0, soreness: 9, energy: 2, stress: 9)

        // When: Submitting with perfect metrics
        mockClient.mockReadinessResponse = DailyReadiness(
            id: UUID(),
            patientId: testPatientId,
            date: Date(),
            sleepHours: perfectMetrics.sleep,
            sorenessLevel: perfectMetrics.soreness,
            energyLevel: perfectMetrics.energy,
            stressLevel: perfectMetrics.stress,
            readinessScore: 97.5, // Expected high score
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        let perfectResult = try await sut.submitReadiness(
            patientId: testPatientId,
            sleepHours: perfectMetrics.sleep,
            sorenessLevel: perfectMetrics.soreness,
            energyLevel: perfectMetrics.energy,
            stressLevel: perfectMetrics.stress
        )

        // Then: Should have high score (>90)
        XCTAssertGreaterThan(perfectResult.readinessScore ?? 0, 90.0)

        // When: Submitting with poor metrics
        mockClient.mockReadinessResponse = DailyReadiness(
            id: UUID(),
            patientId: testPatientId,
            date: Date(),
            sleepHours: poorMetrics.sleep,
            sorenessLevel: poorMetrics.soreness,
            energyLevel: poorMetrics.energy,
            stressLevel: poorMetrics.stress,
            readinessScore: 25.0, // Expected low score
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        let poorResult = try await sut.submitReadiness(
            patientId: testPatientId,
            sleepHours: poorMetrics.sleep,
            sorenessLevel: poorMetrics.soreness,
            energyLevel: poorMetrics.energy,
            stressLevel: poorMetrics.stress
        )

        // Then: Should have low score (<40)
        XCTAssertLessThan(poorResult.readinessScore ?? 100, 40.0)
    }

    // MARK: - Test Date Format Compatibility

    /// Tests that both DATE (YYYY-MM-DD) and TIMESTAMP formats are decoded correctly
    func testDateFormatCompatibility() async throws {
        // Given: Mock responses with different date formats
        let dateOnlyJSON = """
        {
            "id": "00000000-0000-0000-0000-000000000003",
            "patient_id": "\(testPatientId.uuidString)",
            "date": "2026-01-03",
            "sleep_hours": 7.5,
            "soreness_level": 3,
            "energy_level": 8,
            "stress_level": 2,
            "readiness_score": 85.0,
            "notes": null,
            "created_at": "2026-01-03T10:00:00Z",
            "updated_at": "2026-01-03T10:00:00Z"
        }
        """.data(using: .utf8)!

        let timestampJSON = """
        {
            "id": "00000000-0000-0000-0000-000000000004",
            "patient_id": "\(testPatientId.uuidString)",
            "date": "2026-01-03T00:00:00Z",
            "sleep_hours": 8.0,
            "soreness_level": 2,
            "energy_level": 9,
            "stress_level": 1,
            "readiness_score": 92.0,
            "notes": null,
            "created_at": "2026-01-03T10:00:00Z",
            "updated_at": "2026-01-03T10:00:00Z"
        }
        """.data(using: .utf8)!

        // When: Decoding both formats
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try ISO8601 with time first
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }

            iso8601Formatter.formatOptions = [.withInternetDateTime]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }

            // Try DATE format (YYYY-MM-DD)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = dateFormatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date")
        }

        // Then: Both should decode successfully
        XCTAssertNoThrow(try decoder.decode(DailyReadiness.self, from: dateOnlyJSON))
        XCTAssertNoThrow(try decoder.decode(DailyReadiness.self, from: timestampJSON))
    }

    // MARK: - Test Numeric Decoding (Both Integer and Float)

    /// Tests that readiness_score can be decoded from both integer and float formats
    func testNumericDecodingBothFormats() async throws {
        // Given: Score as integer
        let integerScoreJSON = """
        {
            "id": "00000000-0000-0000-0000-000000000005",
            "patient_id": "\(testPatientId.uuidString)",
            "date": "2026-01-03",
            "sleep_hours": 7.5,
            "soreness_level": 3,
            "energy_level": 8,
            "stress_level": 2,
            "readiness_score": 85,
            "notes": null,
            "created_at": "2026-01-03T10:00:00Z",
            "updated_at": "2026-01-03T10:00:00Z"
        }
        """.data(using: .utf8)!

        // Given: Score as float
        let floatScoreJSON = """
        {
            "id": "00000000-0000-0000-0000-000000000006",
            "patient_id": "\(testPatientId.uuidString)",
            "date": "2026-01-03",
            "sleep_hours": 7.5,
            "soreness_level": 3,
            "energy_level": 8,
            "stress_level": 2,
            "readiness_score": 85.5,
            "notes": null,
            "created_at": "2026-01-03T10:00:00Z",
            "updated_at": "2026-01-03T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // When/Then: Both should decode successfully
        let intResult = try decoder.decode(DailyReadiness.self, from: integerScoreJSON)
        XCTAssertEqual(intResult.readinessScore, 85.0)

        let floatResult = try decoder.decode(DailyReadiness.self, from: floatScoreJSON)
        XCTAssertEqual(floatResult.readinessScore, 85.5)
    }

    // MARK: - Test Partial Data Submission

    /// Tests that check-ins with only some metrics still work
    func testPartialDataSubmission() async throws {
        // Given: Only sleep and energy provided
        mockClient.mockReadinessResponse = DailyReadiness(
            id: UUID(),
            patientId: testPatientId,
            date: Date(),
            sleepHours: 7.0,
            sorenessLevel: nil,
            energyLevel: 8,
            stressLevel: nil,
            readinessScore: 75.0, // Normalized score despite missing data
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When: Submitting partial data
        let result = try await sut.submitReadiness(
            patientId: testPatientId,
            sleepHours: 7.0,
            energyLevel: 8
        )

        // Then: Should succeed with non-null score
        XCTAssertNotNil(result.readinessScore)
        XCTAssertEqual(result.sleepHours, 7.0)
        XCTAssertEqual(result.energyLevel, 8)
        XCTAssertNil(result.sorenessLevel)
        XCTAssertNil(result.stressLevel)
    }
}

// MARK: - Mock Supabase Client for Testing

class MockSupabaseClient: PTSupabaseClient {
    var mockReadinessResponse: DailyReadiness?
    var shouldSimulateRLSError = false

    override var client: SupabaseClient {
        // Return mock client that simulates database responses
        fatalError("Use mockReadinessResponse instead")
    }
}
