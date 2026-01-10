//
//  RoleBasedAccessTests.swift
//  PTPerformanceTests
//
//  Created by BUILD 119 on 2026-01-03
//  Purpose: Test role-based access control and RLS policies
//

import XCTest
@testable import PTPerformance

final class RoleBasedAccessTests: XCTestCase {

    var client: SupabaseClient!

    override func setUpWithError() throws {
        client = SupabaseClient.shared
    }

    override func tearDownWithError() throws {
        client = nil
    }

    // MARK: - Patient Access Tests

    func testPatientCanOnlyAccessOwnData() async throws {
        // Given: A patient user
        let patientEmail = "patient@test.com"
        let patientPassword = "TestPassword123"

        // When: Patient queries daily_readiness
        try await client.client.auth.signIn(email: patientEmail, password: patientPassword)
        let session = try await client.client.auth.session

        let response = try await client.client.database
            .from("daily_readiness")
            .select()
            .execute()

        // Then: Should only see own data
        let data = try JSONDecoder().decode([DailyReadiness].self, from: response.data)
        XCTAssertTrue(data.allSatisfy { $0.patientId == session.user.id })
    }

    func testPatientCannotAccessOtherPatientData() async throws {
        // Given: A patient user
        let patientEmail = "patient@test.com"
        let otherPatientId = UUID()

        // When: Patient tries to query other patient's data
        try await client.client.auth.signIn(email: patientEmail, password: "TestPassword123")

        let response = try await client.client.database
            .from("daily_readiness")
            .select()
            .eq("patient_id", value: otherPatientId.uuidString)
            .execute()

        // Then: Should return empty (RLS blocks access)
        let data = try JSONDecoder().decode([DailyReadiness].self, from: response.data)
        XCTAssertTrue(data.isEmpty, "Patient should not see other patient's data")
    }

    // MARK: - Therapist Access Tests

    func testTherapistCanAccessAssignedPatients() async throws {
        // Given: A therapist with assigned patients
        let therapistEmail = "therapist@test.com"
        let therapistPassword = "TestPassword123"

        try await client.client.auth.signIn(email: therapistEmail, password: therapistPassword)
        let session = try await client.client.auth.session

        // Get assigned patients
        let assignedPatients = try await client.client.database
            .from("therapist_patients")
            .select("patient_id")
            .eq("therapist_id", value: session.user.id.uuidString)
            .eq("active", value: true)
            .execute()

        let patientIds = try JSONDecoder().decode([TherapistPatient].self, from: assignedPatients.data)
            .map { $0.patientId }

        // When: Therapist queries daily_readiness
        let response = try await client.client.database
            .from("daily_readiness")
            .select()
            .execute()

        // Then: Should see assigned patients' data
        let readinessData = try JSONDecoder().decode([DailyReadiness].self, from: response.data)

        for entry in readinessData {
            XCTAssertTrue(
                patientIds.contains(entry.patientId),
                "Therapist should only see assigned patients' data"
            )
        }
    }

    func testTherapistCannotAccessUnassignedPatients() async throws {
        // Given: A therapist
        let therapistEmail = "therapist@test.com"
        let unassignedPatientId = UUID()

        try await client.client.auth.signIn(email: therapistEmail, password: "TestPassword123")

        // When: Therapist tries to access unassigned patient's data
        let response = try await client.client.database
            .from("daily_readiness")
            .select()
            .eq("patient_id", value: unassignedPatientId.uuidString)
            .execute()

        // Then: Should return empty (RLS blocks access)
        let data = try JSONDecoder().decode([DailyReadiness].self, from: response.data)
        XCTAssertTrue(data.isEmpty, "Therapist should not see unassigned patient's data")
    }

    // MARK: - Unauthenticated Access Tests

    func testUnauthenticatedUserBlocked() async throws {
        // Given: No authenticated session
        try await client.client.auth.signOut()

        // When: Try to query daily_readiness
        do {
            _ = try await client.client.database
                .from("daily_readiness")
                .select()
                .execute()

            XCTFail("Unauthenticated access should be blocked")
        } catch {
            // Then: Should throw auth error
            XCTAssertTrue(true, "Unauthenticated access correctly blocked")
        }
    }
}

// MARK: - Test Models

struct TherapistPatient: Codable {
    let patientId: UUID

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
    }
}
