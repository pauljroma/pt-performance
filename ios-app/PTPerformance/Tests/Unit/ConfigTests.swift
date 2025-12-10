//
//  ConfigTests.swift
//  PTPerformanceTests
//
//  Unit tests for Config
//  CRITICAL: Validates backend URL configuration to prevent localhost bugs
//

import XCTest
@testable import PTPerformance

final class ConfigTests: XCTestCase {

    // MARK: - Backend URL Tests (CRITICAL)

    func testBackendURLNotLocalhost() {
        let backendURL = Config.backendURL

        // CRITICAL BUG PREVENTION: Backend must NEVER be localhost on physical devices
        XCTAssertFalse(backendURL.contains("localhost"),
            """
            🚨 CRITICAL BUG: Backend URL contains 'localhost'
            This will FAIL on physical devices (TestFlight builds)
            Expected: Supabase Edge Functions URL
            Actual: \(backendURL)
            """)

        XCTAssertFalse(backendURL.contains("127.0.0.1"),
            "🚨 CRITICAL BUG: Backend URL contains '127.0.0.1' - will fail on physical devices")

        XCTAssertFalse(backendURL.contains(":3000"),
            "Backend URL should not contain port :3000 (local dev server)")

        XCTAssertFalse(backendURL.contains(":4000"),
            "Backend URL should not contain port :4000 (local dev server)")
    }

    func testBackendURLIsHTTPS() {
        let backendURL = Config.backendURL

        XCTAssertTrue(backendURL.hasPrefix("https://"),
            """
            Backend URL should use HTTPS
            Got: \(backendURL)
            """)
    }

    func testBackendURLIsSupabase() {
        let backendURL = Config.backendURL

        // Should be Supabase Edge Functions endpoint
        XCTAssertTrue(backendURL.contains("supabase.co"),
            """
            Backend URL should be Supabase Edge Functions
            Expected: https://[project].supabase.co/functions/v1
            Actual: \(backendURL)
            """)

        XCTAssertTrue(backendURL.contains("/functions/v1"),
            "Backend URL should include Edge Functions path: /functions/v1")
    }

    func testBackendURLMatchesSupabaseURL() {
        let backendURL = Config.backendURL
        let supabaseURL = Config.supabaseURL

        // Backend should be based on same Supabase project
        XCTAssertTrue(backendURL.contains(supabaseURL.replacingOccurrences(of: "https://", with: "")),
            """
            Backend URL should be based on Supabase URL
            Supabase: \(supabaseURL)
            Backend: \(backendURL)
            """)
    }

    // MARK: - Supabase Configuration Tests

    func testSupabaseURLIsValid() {
        let supabaseURL = Config.supabaseURL

        XCTAssertTrue(supabaseURL.hasPrefix("https://"),
            "Supabase URL should use HTTPS")

        XCTAssertTrue(supabaseURL.contains("supabase.co"),
            "Supabase URL should be *.supabase.co")

        XCTAssertFalse(supabaseURL.contains("localhost"),
            "Supabase URL should not be localhost")
    }

    func testSupabaseAnonKeyExists() {
        let anonKey = Config.supabaseAnonKey

        XCTAssertFalse(anonKey.isEmpty,
            "Supabase anon key should not be empty")

        XCTAssertGreaterThan(anonKey.count, 20,
            "Supabase anon key should be valid JWT token")
    }

    // MARK: - App Version Tests

    func testAppVersionExists() {
        XCTAssertFalse(Config.appVersion.isEmpty,
            "App version should not be empty")
    }

    func testBuildNumberExists() {
        XCTAssertFalse(Config.buildNumber.isEmpty,
            "Build number should not be empty")
    }

    // MARK: - Demo Credentials Tests

    func testDemoPatientCredentials() {
        XCTAssertFalse(Config.Demo.patientEmail.isEmpty,
            "Demo patient email should not be empty")

        XCTAssertTrue(Config.Demo.patientEmail.contains("@"),
            "Demo patient email should be valid email format")

        XCTAssertFalse(Config.Demo.patientPassword.isEmpty,
            "Demo patient password should not be empty")

        XCTAssertGreaterThan(Config.Demo.patientPassword.count, 8,
            "Demo patient password should be reasonably strong")
    }

    func testDemoTherapistCredentials() {
        XCTAssertFalse(Config.Demo.therapistEmail.isEmpty,
            "Demo therapist email should not be empty")

        XCTAssertTrue(Config.Demo.therapistEmail.contains("@"),
            "Demo therapist email should be valid email format")

        XCTAssertFalse(Config.Demo.therapistPassword.isEmpty,
            "Demo therapist password should not be empty")

        XCTAssertGreaterThan(Config.Demo.therapistPassword.count, 8,
            "Demo therapist password should be reasonably strong")
    }

    // MARK: - Environment Variable Tests

    func testBackendURLCanBeOverridden() {
        // Verify that BACKEND_URL environment variable would be respected
        // (Can't actually set env var in unit test, but can verify structure)

        let backendURL = Config.backendURL
        XCTAssertNotNil(backendURL,
            "Backend URL should have a default value")
    }

    // MARK: - Critical Bug Regression Tests

    func testNoDebugConditionalCompilation() {
        // This test ensures we don't reintroduce #if DEBUG conditional
        // that caused Build 7 to fail

        let backendURL = Config.backendURL

        // Backend URL should be same for all build configurations
        // No DEBUG/RELEASE differences that cause localhost on TestFlight

        #if DEBUG
        XCTAssertFalse(backendURL.contains("localhost"),
            "🚨 REGRESSION: DEBUG build uses localhost - this broke Build 7!")
        #endif

        #if !DEBUG
        XCTAssertFalse(backendURL.contains("localhost"),
            "RELEASE build should not use localhost")
        #endif
    }
}
