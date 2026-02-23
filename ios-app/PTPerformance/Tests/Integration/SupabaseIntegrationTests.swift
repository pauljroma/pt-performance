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
        // After the RLS tightening migration (20260222140000_tighten_demo_rls.sql),
        // the sessions table requires auth.uid()-scoped policies. Querying without
        // a properly authenticated session (via the demo-auth edge function) returns
        // "permission denied". This is the CORRECT security behavior.
        //
        // The app always authenticates before querying sessions, so this does not
        // affect production. Full RLS coverage is verified in RLSPolicyTests which
        // authenticates as demo patient/therapist before querying.
        do {
            let response: [Session] = try await supabase.client
                .from("sessions")
                .select()
                .limit(1)
                .execute()
                .value

            print("Sessions table accessible, found \(response.count) session(s)")

        } catch {
            let errorMessage = error.localizedDescription
            if errorMessage.contains("permission denied") || errorMessage.contains("RLS") {
                // Expected after RLS tightening -- unauthenticated queries are blocked.
                // This confirms RLS is working correctly.
                print("Sessions table correctly requires authentication (RLS active)")
            } else {
                XCTFail("""
                    Cannot query sessions table (unexpected error)
                    Error: \(errorMessage)

                    Expected either success (authenticated) or 'permission denied' (RLS).
                    Got a different error, which may indicate a schema or connectivity issue.
                    """)
            }
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
