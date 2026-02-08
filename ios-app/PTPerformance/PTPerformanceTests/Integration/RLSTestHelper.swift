//
//  RLSTestHelper.swift
//  PTPerformanceTests
//
//  Helper class for RLS (Row Level Security) policy integration tests.
//  Provides utilities for setting up test authentication, simulating different
//  user types, and cleaning up test data.
//
//  IMPORTANT: These tests run against real Supabase and require:
//  - INTEGRATION_TESTS_ENABLED=true environment variable
//  - Valid Supabase credentials in Config.swift
//

import Foundation
import XCTest
@testable import PTPerformance

// MARK: - RLS Test User Types

/// Represents different user types for RLS testing
enum RLSTestUserType {
    /// Demo patient account (well-known ID for testing)
    case demoPatient

    /// Demo therapist account (well-known ID for testing)
    case demoTherapist

    /// A different patient (to test cross-patient access denial)
    case otherPatient

    /// Anonymous/unauthenticated user
    case anonymous

    /// Custom user with specific ID
    case custom(userId: UUID, role: UserRole)

    /// The well-known demo patient UUID
    static let demoPatientId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    /// The well-known demo therapist UUID
    static let demoTherapistId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

    /// A secondary patient for cross-access testing
    static let otherPatientId = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!

    var userId: UUID? {
        switch self {
        case .demoPatient:
            return Self.demoPatientId
        case .demoTherapist:
            return Self.demoTherapistId
        case .otherPatient:
            return Self.otherPatientId
        case .anonymous:
            return nil
        case .custom(let userId, _):
            return userId
        }
    }

    var role: UserRole? {
        switch self {
        case .demoPatient, .otherPatient:
            return .patient
        case .demoTherapist:
            return .therapist
        case .anonymous:
            return nil
        case .custom(_, let role):
            return role
        }
    }

    var displayName: String {
        switch self {
        case .demoPatient:
            return "Demo Patient (00000000-0000-0000-0000-000000000001)"
        case .demoTherapist:
            return "Demo Therapist (00000000-0000-0000-0000-000000000002)"
        case .otherPatient:
            return "Other Patient (00000000-0000-0000-0000-000000000003)"
        case .anonymous:
            return "Anonymous (unauthenticated)"
        case .custom(let userId, let role):
            return "Custom \(role.rawValue) (\(userId.uuidString))"
        }
    }
}

// MARK: - RLS Test Operation

/// Operations to test against RLS policies
enum RLSTestOperation: String, CaseIterable {
    case select = "SELECT"
    case insert = "INSERT"
    case update = "UPDATE"
    case delete = "DELETE"
}

// MARK: - RLS Test Result

/// Result of an RLS policy test
struct RLSTestResult {
    let table: String
    let operation: RLSTestOperation
    let userType: RLSTestUserType
    let success: Bool
    let error: Error?
    let expectedToSucceed: Bool

    var isPassing: Bool {
        success == expectedToSucceed
    }

    var failureMessage: String? {
        guard !isPassing else { return nil }

        if expectedToSucceed && !success {
            return """
                RLS Policy FAILED: \(operation.rawValue) on '\(table)' as \(userType.displayName)
                Expected: SUCCESS
                Got: FAILURE
                Error: \(error?.localizedDescription ?? "Unknown error")
                """
        } else {
            return """
                RLS Policy FAILED: \(operation.rawValue) on '\(table)' as \(userType.displayName)
                Expected: DENIED (RLS should block this)
                Got: SUCCESS (operation was allowed when it shouldn't be)
                """
        }
    }
}

// MARK: - RLS Test Configuration

/// Configuration for RLS tests
struct RLSTestConfiguration {
    /// Whether to run integration tests (requires environment variable)
    static var isEnabled: Bool {
        ProcessInfo.processInfo.environment["INTEGRATION_TESTS_ENABLED"] == "true"
    }

    /// Supabase URL (can be overridden for test environment)
    static var supabaseURL: String {
        ProcessInfo.processInfo.environment["TEST_SUPABASE_URL"] ?? Config.supabaseURL
    }

    /// Supabase anon key (can be overridden for test environment)
    static var supabaseAnonKey: String {
        ProcessInfo.processInfo.environment["TEST_SUPABASE_ANON_KEY"] ?? Config.supabaseAnonKey
    }

    /// Demo patient email for authentication
    static var demoPatientEmail: String {
        ProcessInfo.processInfo.environment["TEST_DEMO_PATIENT_EMAIL"] ?? "demo-patient@ptperformance.app"
    }

    /// Demo patient password for authentication
    /// SECURITY: Must be set via TEST_DEMO_PATIENT_PASSWORD environment variable
    static var demoPatientPassword: String {
        guard let password = ProcessInfo.processInfo.environment["TEST_DEMO_PATIENT_PASSWORD"], !password.isEmpty else {
            fatalError("TEST_DEMO_PATIENT_PASSWORD environment variable must be set for integration tests")
        }
        return password
    }

    /// Demo therapist email for authentication
    static var demoTherapistEmail: String {
        ProcessInfo.processInfo.environment["TEST_DEMO_THERAPIST_EMAIL"] ?? "demo-therapist@ptperformance.app"
    }

    /// Demo therapist password for authentication
    /// SECURITY: Must be set via TEST_DEMO_THERAPIST_PASSWORD environment variable
    static var demoTherapistPassword: String {
        guard let password = ProcessInfo.processInfo.environment["TEST_DEMO_THERAPIST_PASSWORD"], !password.isEmpty else {
            fatalError("TEST_DEMO_THERAPIST_PASSWORD environment variable must be set for integration tests")
        }
        return password
    }

    /// Timeout for async operations
    static let asyncTimeout: TimeInterval = 30.0

    /// Tables that require RLS testing
    static let criticalTables = [
        "sessions",
        "session_exercises",
        "exercise_logs",
        "manual_sessions",
        "manual_session_exercises",
        "workout_prescriptions",
        "workout_modifications",
        "patient_favorite_templates",
        "patient_workout_templates",
        "streak_records",
        "daily_readiness",
        "arm_care_assessments",
        "body_comp_measurements"
    ]
}

// MARK: - RLS Test Helper

/// Helper class for running RLS policy integration tests
@MainActor
class RLSTestHelper {

    /// The Supabase client used for testing
    private let client: PTSupabaseClient

    /// UUIDs of test records created during tests (for cleanup)
    private var createdTestRecords: [(table: String, id: UUID)] = []

    /// Current authenticated user type
    private var currentUserType: RLSTestUserType = .anonymous

    init() {
        client = PTSupabaseClient.shared
    }

    // MARK: - Authentication Methods

    /// Signs in as the demo patient
    func signInAsDemoPatient() async throws {
        try await client.signIn(
            email: RLSTestConfiguration.demoPatientEmail,
            password: RLSTestConfiguration.demoPatientPassword
        )
        currentUserType = .demoPatient
    }

    /// Signs in as the demo therapist
    func signInAsDemoTherapist() async throws {
        try await client.signIn(
            email: RLSTestConfiguration.demoTherapistEmail,
            password: RLSTestConfiguration.demoTherapistPassword
        )
        currentUserType = .demoTherapist
    }

    /// Signs out the current user
    func signOut() async throws {
        try await client.signOut()
        currentUserType = .anonymous
    }

    /// Gets the current user ID
    var currentUserId: String? {
        client.userId
    }

    /// Gets the current user role
    var currentUserRole: UserRole? {
        client.userRole
    }

    // MARK: - Test Record Management

    /// Generates a test UUID with a recognizable prefix for easy identification
    func generateTestId() -> UUID {
        // Use a pattern that's easy to identify as test data
        // Format: FFFFFFFF-FFFF-FFFF-FFFF-<timestamp>
        let timestamp = UInt64(Date().timeIntervalSince1970 * 1000) % 0xFFFFFFFFFFFF
        let hexTimestamp = String(format: "%012llx", timestamp)
        return UUID(uuidString: "ffffffff-ffff-ffff-ffff-\(hexTimestamp)")!
    }

    /// Registers a created test record for cleanup
    func registerTestRecord(table: String, id: UUID) {
        createdTestRecords.append((table: table, id: id))
    }

    /// Cleans up all test records created during tests
    func cleanupTestRecords() async {
        for record in createdTestRecords.reversed() {
            do {
                try await client.client
                    .from(record.table)
                    .delete()
                    .eq("id", value: record.id.uuidString)
                    .execute()
            } catch {
                // Log but don't fail - cleanup is best-effort
                print("Warning: Failed to cleanup test record \(record.id) from \(record.table): \(error)")
            }
        }
        createdTestRecords.removeAll()
    }

    // MARK: - RLS Test Operations

    /// Tests SELECT operation on a table
    func testSelect(
        table: String,
        userType: RLSTestUserType,
        expectedToSucceed: Bool,
        filter: ((any Supabase.PostgrestFilterBuilder) -> any Supabase.PostgrestFilterBuilder)? = nil
    ) async -> RLSTestResult {
        do {
            var query = client.client.from(table).select()

            // Apply patient_id filter if testing patient-owned data
            if let userId = userType.userId, userType.role == .patient {
                query = query.eq("patient_id", value: userId.uuidString)
            }

            // Apply any custom filter
            if let filter = filter {
                // Note: We can't easily chain filters due to protocol constraints
                // This is a simplified version
            }

            let _: [[String: Any]] = try await query.limit(1).execute().value

            return RLSTestResult(
                table: table,
                operation: .select,
                userType: userType,
                success: true,
                error: nil,
                expectedToSucceed: expectedToSucceed
            )
        } catch {
            return RLSTestResult(
                table: table,
                operation: .select,
                userType: userType,
                success: false,
                error: error,
                expectedToSucceed: expectedToSucceed
            )
        }
    }

    /// Tests INSERT operation on a table
    func testInsert(
        table: String,
        userType: RLSTestUserType,
        expectedToSucceed: Bool,
        data: [String: Any]
    ) async -> RLSTestResult {
        let testId = generateTestId()
        var insertData = data
        insertData["id"] = testId.uuidString

        // Add patient_id for patient-owned tables
        if let userId = userType.userId, userType.role == .patient {
            insertData["patient_id"] = userId.uuidString
        }

        do {
            try await client.client
                .from(table)
                .insert(insertData)
                .execute()

            // Register for cleanup if successful
            registerTestRecord(table: table, id: testId)

            return RLSTestResult(
                table: table,
                operation: .insert,
                userType: userType,
                success: true,
                error: nil,
                expectedToSucceed: expectedToSucceed
            )
        } catch {
            return RLSTestResult(
                table: table,
                operation: .insert,
                userType: userType,
                success: false,
                error: error,
                expectedToSucceed: expectedToSucceed
            )
        }
    }

    /// Tests UPDATE operation on a table
    func testUpdate(
        table: String,
        userType: RLSTestUserType,
        expectedToSucceed: Bool,
        recordId: UUID,
        data: [String: Any]
    ) async -> RLSTestResult {
        do {
            try await client.client
                .from(table)
                .update(data)
                .eq("id", value: recordId.uuidString)
                .execute()

            return RLSTestResult(
                table: table,
                operation: .update,
                userType: userType,
                success: true,
                error: nil,
                expectedToSucceed: expectedToSucceed
            )
        } catch {
            return RLSTestResult(
                table: table,
                operation: .update,
                userType: userType,
                success: false,
                error: error,
                expectedToSucceed: expectedToSucceed
            )
        }
    }

    /// Tests DELETE operation on a table
    func testDelete(
        table: String,
        userType: RLSTestUserType,
        expectedToSucceed: Bool,
        recordId: UUID
    ) async -> RLSTestResult {
        do {
            try await client.client
                .from(table)
                .delete()
                .eq("id", value: recordId.uuidString)
                .execute()

            // Remove from cleanup list if we deleted it
            createdTestRecords.removeAll { $0.table == table && $0.id == recordId }

            return RLSTestResult(
                table: table,
                operation: .delete,
                userType: userType,
                success: true,
                error: nil,
                expectedToSucceed: expectedToSucceed
            )
        } catch {
            return RLSTestResult(
                table: table,
                operation: .delete,
                userType: userType,
                success: false,
                error: error,
                expectedToSucceed: expectedToSucceed
            )
        }
    }

    // MARK: - Convenience Test Methods

    /// Runs a full CRUD test cycle for a table
    func runFullCRUDTest(
        table: String,
        userType: RLSTestUserType,
        testData: [String: Any],
        updateData: [String: Any],
        expectedResults: [RLSTestOperation: Bool]
    ) async -> [RLSTestResult] {
        var results: [RLSTestResult] = []
        var createdRecordId: UUID?

        // Test SELECT
        if let expected = expectedResults[.select] {
            let result = await testSelect(table: table, userType: userType, expectedToSucceed: expected)
            results.append(result)
        }

        // Test INSERT
        if let expected = expectedResults[.insert] {
            let result = await testInsert(table: table, userType: userType, expectedToSucceed: expected, data: testData)
            results.append(result)

            // If insert succeeded, get the ID for update/delete tests
            if result.success {
                if let lastRecord = createdTestRecords.last, lastRecord.table == table {
                    createdRecordId = lastRecord.id
                }
            }
        }

        // Test UPDATE (only if we have a record to update)
        if let expected = expectedResults[.update], let recordId = createdRecordId {
            let result = await testUpdate(table: table, userType: userType, expectedToSucceed: expected, recordId: recordId, data: updateData)
            results.append(result)
        }

        // Test DELETE (only if we have a record to delete)
        if let expected = expectedResults[.delete], let recordId = createdRecordId {
            let result = await testDelete(table: table, userType: userType, expectedToSucceed: expected, recordId: recordId)
            results.append(result)
        }

        return results
    }

    // MARK: - Test Data Generators

    /// Generates minimal test data for a given table
    func generateTestData(for table: String, patientId: UUID) -> [String: Any] {
        let now = ISO8601DateFormatter().string(from: Date())
        let today = DateFormatter.yyyyMMdd.string(from: Date())

        switch table {
        case "sessions":
            return [
                "phase_id": UUID().uuidString,
                "name": "RLS Test Session",
                "sequence": 1,
                "created_at": now
            ]

        case "session_exercises":
            return [
                "session_id": UUID().uuidString,
                "exercise_template_id": UUID().uuidString,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "sequence": 1
            ]

        case "exercise_logs":
            return [
                "session_exercise_id": UUID().uuidString,
                "patient_id": patientId.uuidString,
                "set_number": 1,
                "reps_completed": 10,
                "load_used": 50.0,
                "created_at": now
            ]

        case "manual_sessions":
            return [
                "patient_id": patientId.uuidString,
                "name": "RLS Test Manual Session",
                "session_date": today,
                "status": "draft",
                "created_at": now
            ]

        case "manual_session_exercises":
            return [
                "manual_session_id": UUID().uuidString,
                "exercise_name": "RLS Test Exercise",
                "sequence": 1
            ]

        case "workout_prescriptions":
            return [
                "patient_id": patientId.uuidString,
                "prescribed_by": RLSTestUserType.demoTherapistId.uuidString,
                "name": "RLS Test Prescription",
                "status": "active",
                "created_at": now
            ]

        case "workout_modifications":
            return [
                "patient_id": patientId.uuidString,
                "session_exercise_id": UUID().uuidString,
                "modification_type": "load_reduction",
                "reason": "RLS Test",
                "created_at": now
            ]

        case "patient_favorite_templates":
            return [
                "patient_id": patientId.uuidString,
                "template_id": UUID().uuidString,
                "created_at": now
            ]

        case "patient_workout_templates":
            return [
                "patient_id": patientId.uuidString,
                "name": "RLS Test Template",
                "created_at": now
            ]

        case "streak_records":
            return [
                "patient_id": patientId.uuidString,
                "streak_type": "workout",
                "current_streak": 0,
                "longest_streak": 0,
                "created_at": now,
                "updated_at": now
            ]

        case "daily_readiness":
            return [
                "patient_id": patientId.uuidString,
                "date": today,
                "energy_level": 7,
                "created_at": now,
                "updated_at": now
            ]

        case "arm_care_assessments":
            return [
                "patient_id": patientId.uuidString,
                "date": today,
                "shoulder_pain_score": 8,
                "shoulder_stiffness_score": 8,
                "shoulder_strength_score": 8,
                "elbow_pain_score": 8,
                "elbow_tightness_score": 8,
                "valgus_stress_score": 8,
                "traffic_light": "green",
                "created_at": now,
                "updated_at": now
            ]

        case "body_comp_measurements":
            return [
                "patient_id": patientId.uuidString,
                "measurement_date": today,
                "weight_lbs": 180.0,
                "created_at": now
            ]

        default:
            return [
                "created_at": now
            ]
        }
    }

    /// Generates update data for a given table
    func generateUpdateData(for table: String) -> [String: Any] {
        let now = ISO8601DateFormatter().string(from: Date())

        switch table {
        case "sessions":
            return ["name": "RLS Test Session Updated", "updated_at": now]
        case "manual_sessions":
            return ["name": "RLS Test Manual Session Updated", "updated_at": now]
        case "streak_records":
            return ["current_streak": 1, "updated_at": now]
        case "daily_readiness":
            return ["energy_level": 8, "updated_at": now]
        case "arm_care_assessments":
            return ["shoulder_pain_score": 9, "updated_at": now]
        default:
            return ["updated_at": now]
        }
    }
}

// MARK: - Date Formatter Extension

private extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}

// MARK: - XCTestCase Extension for RLS Tests

extension XCTestCase {

    /// Skips the test if integration tests are not enabled
    func skipIfIntegrationTestsDisabled() throws {
        try XCTSkipUnless(
            RLSTestConfiguration.isEnabled,
            "Integration tests are disabled. Set INTEGRATION_TESTS_ENABLED=true to run."
        )
    }

    /// Asserts that an RLS test result is passing
    func assertRLSTestPassed(_ result: RLSTestResult, file: StaticString = #filePath, line: UInt = #line) {
        if !result.isPassing {
            XCTFail(result.failureMessage ?? "RLS test failed", file: file, line: line)
        }
    }

    /// Asserts that all RLS test results are passing
    func assertAllRLSTestsPassed(_ results: [RLSTestResult], file: StaticString = #filePath, line: UInt = #line) {
        let failures = results.filter { !$0.isPassing }
        if !failures.isEmpty {
            let messages = failures.compactMap { $0.failureMessage }
            XCTFail("RLS tests failed:\n\(messages.joined(separator: "\n\n"))", file: file, line: line)
        }
    }
}
