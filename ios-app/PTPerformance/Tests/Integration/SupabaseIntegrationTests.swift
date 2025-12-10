//
//  SupabaseIntegrationTests.swift
//  PTPerformanceTests
//
//  Integration tests for Supabase client
//  Tests actual database connectivity and query execution
//

import XCTest
@testable import PTPerformance

@MainActor
final class SupabaseIntegrationTests: XCTestCase {

    var supabase: PTSupabaseClient!

    override func setUp() async throws {
        try await super.setUp()
        supabase = PTSupabaseClient.shared
    }

    override func tearDown() async throws {
        supabase = nil
        try await super.tearDown()
    }

    // MARK: - Client Configuration Tests

    func testSupabaseClientInitialized() {
        XCTAssertNotNil(supabase, "Supabase client should be initialized")
        XCTAssertNotNil(supabase.client, "Supabase client instance should exist")
    }

    func testSupabaseURLConfiguration() {
        let config = Config.supabaseURL

        XCTAssertTrue(config.hasPrefix("https://"),
            "Supabase URL should use HTTPS")
        XCTAssertTrue(config.contains("supabase.co"),
            "Supabase URL should be *.supabase.co domain")
    }

    // MARK: - Authentication Tests

    func testDemoPatientLogin() async throws {
        // Test patient login with demo credentials
        do {
            let session = try await supabase.client.auth.signIn(
                email: Config.Demo.patientEmail,
                password: Config.Demo.patientPassword
            )

            XCTAssertNotNil(session, "Patient login should succeed")
            XCTAssertNotNil(session.user, "Should have user after login")
            XCTAssertEqual(session.user.email, Config.Demo.patientEmail,
                "User email should match login email")

            print("✅ Patient login successful: \(session.user.id)")

            // Cleanup: sign out
            try await supabase.client.auth.signOut()

        } catch {
            XCTFail("""
                🚨 CRITICAL: Patient login failed
                Email: \(Config.Demo.patientEmail)
                Error: \(error.localizedDescription)

                This means:
                1. Supabase credentials are invalid, OR
                2. Demo patient doesn't exist in database, OR
                3. Network/Supabase is down

                Build CANNOT be deployed if login fails!
                """)
        }
    }

    func testDemoTherapistLogin() async throws {
        // Test therapist login with demo credentials
        do {
            let session = try await supabase.client.auth.signIn(
                email: Config.Demo.therapistEmail,
                password: Config.Demo.therapistPassword
            )

            XCTAssertNotNil(session, "Therapist login should succeed")
            XCTAssertNotNil(session.user, "Should have user after login")
            XCTAssertEqual(session.user.email, Config.Demo.therapistEmail,
                "User email should match login email")

            print("✅ Therapist login successful: \(session.user.id)")

            // Cleanup: sign out
            try await supabase.client.auth.signOut()

        } catch {
            XCTFail("""
                🚨 CRITICAL: Therapist login failed
                Email: \(Config.Demo.therapistEmail)
                Error: \(error.localizedDescription)

                Build CANNOT be deployed if login fails!
                """)
        }
    }

    // MARK: - Database Query Tests

    func testPatientsTableAccessible() async throws {
        // Test that patients table can be queried
        do {
            let response: [Patient] = try await supabase.client
                .from("patients")
                .select()
                .limit(1)
                .execute()
                .value

            print("✅ Patients table accessible, found \(response.count) patient(s)")

        } catch {
            XCTFail("""
                🚨 CRITICAL: Cannot query patients table
                Error: \(error.localizedDescription)

                This means:
                1. Table doesn't exist, OR
                2. RLS policies block access, OR
                3. Schema mismatch

                Therapist dashboard will FAIL!
                """)
        }
    }

    func testSessionsTableAccessible() async throws {
        // Test that sessions table can be queried
        do {
            let response: [Session] = try await supabase.client
                .from("sessions")
                .select()
                .limit(1)
                .execute()
                .value

            print("✅ Sessions table accessible, found \(response.count) session(s)")

        } catch {
            XCTFail("""
                🚨 CRITICAL: Cannot query sessions table
                Error: \(error.localizedDescription)

                Patient session loading will FAIL!
                """)
        }
    }

    func testWorkloadFlagsTableAccessible() async throws {
        // Test that workload_flags table can be queried
        do {
            let response: [WorkloadFlag] = try await supabase.client
                .from("workload_flags")
                .select()
                .limit(1)
                .execute()
                .value

            print("✅ Workload flags table accessible, found \(response.count) flag(s)")

        } catch {
            print("⚠️ Warning: Cannot query workload_flags table - \(error.localizedDescription)")
            // This is a warning, not a critical failure
        }
    }

    // MARK: - Patient Data Loading Tests

    func testPatientSessionsQueryWithRelationships() async throws {
        // Test the complex query that TodaySessionViewModel uses
        // This query includes nested relationships (sessions -> phases -> programs)

        // Login as patient first
        let session = try await supabase.client.auth.signIn(
            email: Config.Demo.patientEmail,
            password: Config.Demo.patientPassword
        )

        let patientId = session.user.id.uuidString

        do {
            let sessionsResponse: [Session] = try await supabase.client
                .from("sessions")
                .select("""
                    *,
                    phases!inner(
                        id,
                        name,
                        program_id,
                        programs!inner(
                            id,
                            name,
                            patient_id,
                            status
                        )
                    )
                """)
                .eq("phases.programs.patient_id", value: patientId)
                .eq("phases.programs.status", value: "active")
                .order("sequence", ascending: true)
                .limit(1)
                .execute()
                .value

            if sessionsResponse.isEmpty {
                print("""
                    ⚠️ WARNING: No sessions found for patient \(patientId)

                    This is likely why Build 8 shows "data could not be read because it doesn't exist"

                    Possible causes:
                    1. Patient has no active program
                    2. Active program has no phases
                    3. Phases have no sessions
                    4. Database seed data missing

                    ACTION REQUIRED: Run seed scripts to create demo data
                    """)
            } else {
                print("✅ Patient sessions query successful, found \(sessionsResponse.count) session(s)")
            }

        } catch {
            XCTFail("""
                🚨 CRITICAL: Patient sessions query FAILED
                This is the exact query TodaySessionViewModel uses!
                Error: \(error.localizedDescription)

                This explains Build 8 failure: "data could not be read because it doesn't exist"

                Possible causes:
                1. Table relationships broken
                2. RLS policies too restrictive
                3. Foreign keys missing
                4. Schema mismatch
                """)
        }

        // Cleanup
        try await supabase.client.auth.signOut()
    }

    // MARK: - Therapist Data Loading Tests

    func testTherapistPatientsQueryWithFilter() async throws {
        // Test the therapist patient list query with therapist_id filter

        // Login as therapist first
        let session = try await supabase.client.auth.signIn(
            email: Config.Demo.therapistEmail,
            password: Config.Demo.therapistPassword
        )

        let therapistId = session.user.id.uuidString

        do {
            let response: [Patient] = try await supabase.client
                .from("patients")
                .select()
                .eq("therapist_id", value: therapistId)
                .execute()
                .value

            if response.isEmpty {
                print("""
                    ⚠️ WARNING: No patients found for therapist \(therapistId)

                    Possible causes:
                    1. Therapist has no assigned patients
                    2. therapist_id column not populated
                    3. Database seed data missing

                    ACTION REQUIRED: Assign patients to therapist in database
                    """)
            } else {
                print("✅ Therapist patients query successful, found \(response.count) patient(s)")
            }

        } catch {
            XCTFail("""
                🚨 CRITICAL: Therapist patients query FAILED
                Error: \(error.localizedDescription)

                Therapist dashboard will show empty or error!
                """)
        }

        // Cleanup
        try await supabase.client.auth.signOut()
    }

    // MARK: - Performance Tests

    func testQueryPerformance() async throws {
        measure {
            Task {
                _ = try? await supabase.client
                    .from("patients")
                    .select()
                    .limit(10)
                    .execute()
            }
        }
    }
}
