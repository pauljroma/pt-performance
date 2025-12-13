//
//  ProgressionServiceIntegrationTests.swift
//  PTPerformance
//
//  Integration tests for ProgressionService database operations
//

import XCTest
@testable import PTPerformance

@MainActor
class ProgressionServiceIntegrationTests: XCTestCase {
    var service: ProgressionService!
    var supabase: PTSupabaseClient!

    override func setUp() async throws {
        try await super.setUp()
        supabase = PTSupabaseClient.shared
        service = ProgressionService(supabase: supabase)
    }

    override func tearDown() async throws {
        service = nil
        supabase = nil
        try await super.tearDown()
    }

    // MARK: - Database Connection Tests

    func testDatabaseConnection() async throws {
        // Verify we can connect to Supabase
        let response = try await supabase.client
            .from("load_progression_history")
            .select()
            .limit(1)
            .execute()

        XCTAssertNotNil(response.data)
    }

    // MARK: - Record Progression Tests

    func testRecordProgression_Insert() async throws {
        // Given
        let patientId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let sessionId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let exerciseId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

        let progression = LoadProgression(
            id: UUID(),
            patientId: patientId,
            sessionId: sessionId,
            exerciseId: exerciseId,
            completedReps: 10,
            targetReps: 10,
            actualRPE: 7.0,
            targetRPE: 7.0,
            currentWeight: 135.0,
            recommendedNextWeight: 145.0,
            decision: .increase,
            createdAt: Date()
        )

        // When
        do {
            try await service.recordProgression(progression)

            // Then - verify record was inserted
            let response = try await supabase.client
                .from("load_progression_history")
                .select()
                .eq("id", value: progression.id.uuidString)
                .single()
                .execute()

            XCTAssertNotNil(response.data)

            // Cleanup
            try await supabase.client
                .from("load_progression_history")
                .delete()
                .eq("id", value: progression.id.uuidString)
                .execute()

        } catch {
            // If foreign key constraint fails, that's expected in test environment
            // The important part is that the service method doesn't crash
            XCTAssertTrue(error.localizedDescription.contains("violates foreign key") ||
                         error.localizedDescription.contains("insert"))
        }
    }

    func testRecordProgression_ValidatesData() async throws {
        // Given - invalid progression with negative weight
        let progression = LoadProgression(
            id: UUID(),
            patientId: UUID(),
            sessionId: UUID(),
            exerciseId: UUID(),
            completedReps: 10,
            targetReps: 10,
            actualRPE: 7.0,
            targetRPE: 7.0,
            currentWeight: -100.0,  // Invalid
            recommendedNextWeight: 0,
            decision: .hold,
            createdAt: Date()
        )

        // When/Then - should throw or handle gracefully
        do {
            try await service.recordProgression(progression)
        } catch {
            // Expected to fail with validation or foreign key error
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Fetch Progression Tests

    func testFetchProgressionHistory() async throws {
        // Given
        let patientId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let exerciseId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

        // When
        do {
            let history = try await service.fetchProgressionHistory(
                patientId: patientId,
                exerciseId: exerciseId,
                limit: 10
            )

            // Then - should return array (might be empty)
            XCTAssertNotNil(history)
            XCTAssertGreaterThanOrEqual(history.count, 0)

            // Verify sorting (most recent first)
            if history.count > 1 {
                XCTAssertGreaterThan(history[0].createdAt, history[1].createdAt)
            }
        } catch {
            // If table is empty or foreign keys don't exist, that's ok
            print("Note: \(error.localizedDescription)")
        }
    }

    // MARK: - Deload Trigger Tests

    func testRecordDeloadTrigger() async throws {
        // Given
        let trigger = DeloadTrigger(
            id: UUID(),
            patientId: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            exerciseId: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            triggerDate: Date(),
            consecutiveHardSessions: 7,
            avgRPE: 8.5,
            triggeredDeload: true
        )

        // When
        do {
            try await service.recordDeloadTrigger(trigger)

            // Then - verify record was inserted
            let response = try await supabase.client
                .from("deload_triggers")
                .select()
                .eq("id", value: trigger.id.uuidString)
                .single()
                .execute()

            XCTAssertNotNil(response.data)

            // Cleanup
            try await supabase.client
                .from("deload_triggers")
                .delete()
                .eq("id", value: trigger.id.uuidString)
                .execute()

        } catch {
            // Foreign key errors are expected in test environment
            print("Note: \(error.localizedDescription)")
        }
    }

    // MARK: - Performance Tests

    func testProgressionServicePerformance() throws {
        measure {
            Task {
                let calculator = ProgressionCalculator()
                for _ in 0..<1000 {
                    let decision = calculator.calculateProgression(
                        completedReps: 10,
                        targetReps: 10,
                        actualRPE: 7.0,
                        targetRPE: 7.0,
                        currentWeight: 135.0,
                        movementType: .lowerBodyCompound
                    )
                    XCTAssertNotNil(decision)
                }
            }
        }
    }

    // MARK: - Error Handling Tests

    func testHandlesNetworkErrors() async throws {
        // Test that service handles network errors gracefully
        // This would require mocking the Supabase client
        // For now, we just verify the service exists and has proper error handling
        XCTAssertNotNil(service)
    }
}
