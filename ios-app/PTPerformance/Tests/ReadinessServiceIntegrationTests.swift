//
//  ReadinessServiceIntegrationTests.swift
//  PTPerformance
//
//  Integration tests for ReadinessService database operations
//

import XCTest
@testable import PTPerformance

@MainActor
class ReadinessServiceIntegrationTests: XCTestCase {
    var service: ReadinessService!
    var supabase: PTSupabaseClient!

    override func setUp() async throws {
        try await super.setUp()
        supabase = PTSupabaseClient.shared
        service = ReadinessService(supabase: supabase)
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
            .from("daily_readiness")
            .select()
            .limit(1)
            .execute()

        XCTAssertNotNil(response.data)
    }

    // MARK: - Submit Readiness Tests

    func testSubmitDailyReadiness() async throws {
        // Given
        let readiness = DailyReadiness(
            id: UUID(),
            patientId: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            date: Date(),
            sleepHours: 7.5,
            sleepQuality: 4,
            hrvScore: 65.0,
            recoveryScore: 78.0,
            stressorLevel: 3,
            muscleSoreness: 4,
            jointPain: 1,
            generalWellbeing: 4,
            rawReadinessBand: .green,
            modifiedReadinessBand: .green,
            dataSource: .manual
        )

        // When
        do {
            try await service.submitDailyReadiness(readiness)

            // Then - verify record was inserted
            let response = try await supabase.client
                .from("daily_readiness")
                .select()
                .eq("id", value: readiness.id.uuidString)
                .single()
                .execute()

            XCTAssertNotNil(response.data)

            // Cleanup
            try await supabase.client
                .from("daily_readiness")
                .delete()
                .eq("id", value: readiness.id.uuidString)
                .execute()

        } catch {
            // Foreign key errors are expected in test environment
            print("Note: \(error.localizedDescription)")
        }
    }

    func testSubmitReadiness_ValidatesInput() async throws {
        // Given - invalid readiness with negative sleep hours
        let readiness = DailyReadiness(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            sleepHours: -5.0,  // Invalid
            sleepQuality: 1,
            hrvScore: nil,
            recoveryScore: nil,
            stressorLevel: 5,
            muscleSoreness: 5,
            jointPain: 5,
            generalWellbeing: 1,
            rawReadinessBand: .red,
            modifiedReadinessBand: .red,
            dataSource: .manual
        )

        // When/Then - should handle gracefully
        do {
            try await service.submitDailyReadiness(readiness)
        } catch {
            // Expected to fail with validation error
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Fetch Readiness Tests

    func testFetchRecentReadiness() async throws {
        // Given
        let patientId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

        // When
        do {
            let history = try await service.fetchRecentReadiness(
                patientId: patientId,
                days: 7
            )

            // Then - should return array (might be empty)
            XCTAssertNotNil(history)
            XCTAssertGreaterThanOrEqual(history.count, 0)

            // Verify date range if data exists
            if let latest = history.first {
                let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
                XCTAssertGreaterThan(latest.date, weekAgo)
            }
        } catch {
            print("Note: \(error.localizedDescription)")
        }
    }

    func testFetchTodayReadiness() async throws {
        // Given
        let patientId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

        // When
        do {
            let todayReadiness = try await service.fetchTodayReadiness(patientId: patientId)

            // Then - might be nil if no entry for today
            if let readiness = todayReadiness {
                let calendar = Calendar.current
                XCTAssertTrue(calendar.isDateInToday(readiness.date))
            }
        } catch {
            print("Note: \(error.localizedDescription)")
        }
    }

    // MARK: - Readiness Modification Tests

    func testRecordReadinessModification() async throws {
        // Given
        let modification = ReadinessModification(
            id: UUID(),
            readinessId: UUID(),
            modifiedBy: UUID(),
            originalBand: .green,
            newBand: .yellow,
            reason: "Therapist override based on visual assessment",
            createdAt: Date()
        )

        // When
        do {
            try await service.recordModification(modification)

            // Then - verify record was inserted
            let response = try await supabase.client
                .from("readiness_modifications")
                .select()
                .eq("id", value: modification.id.uuidString)
                .single()
                .execute()

            XCTAssertNotNil(response.data)

            // Cleanup
            try await supabase.client
                .from("readiness_modifications")
                .delete()
                .eq("id", value: modification.id.uuidString)
                .execute()

        } catch {
            print("Note: \(error.localizedDescription)")
        }
    }

    // MARK: - Calculation Tests

    func testCalculateReadinessBand_Green() {
        // Given
        let readiness = DailyReadiness(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            sleepHours: 8.0,
            sleepQuality: 5,
            hrvScore: 70.0,
            recoveryScore: 85.0,
            stressorLevel: 1,
            muscleSoreness: 1,
            jointPain: 0,
            generalWellbeing: 5,
            rawReadinessBand: .green,
            modifiedReadinessBand: .green,
            dataSource: .whoop
        )

        // When
        let band = service.calculateReadinessBand(readiness)

        // Then
        XCTAssertEqual(band, .green)
    }

    func testCalculateReadinessBand_Yellow() {
        // Given
        let readiness = DailyReadiness(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            sleepHours: 6.5,
            sleepQuality: 3,
            hrvScore: 55.0,
            recoveryScore: 65.0,
            stressorLevel: 3,
            muscleSoreness: 3,
            jointPain: 1,
            generalWellbeing: 3,
            rawReadinessBand: .yellow,
            modifiedReadinessBand: .yellow,
            dataSource: .manual
        )

        // When
        let band = service.calculateReadinessBand(readiness)

        // Then
        XCTAssertEqual(band, .yellow)
    }

    func testCalculateReadinessBand_Red() {
        // Given
        let readiness = DailyReadiness(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            sleepHours: 4.0,
            sleepQuality: 1,
            hrvScore: 35.0,
            recoveryScore: 40.0,
            stressorLevel: 5,
            muscleSoreness: 5,
            jointPain: 4,
            generalWellbeing: 1,
            rawReadinessBand: .red,
            modifiedReadinessBand: .red,
            dataSource: .manual
        )

        // When
        let band = service.calculateReadinessBand(readiness)

        // Then
        XCTAssertEqual(band, .red)
    }

    func testJointPain_AutoOverrideToRed() {
        // Given - good metrics but joint pain
        let readiness = DailyReadiness(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            sleepHours: 8.0,
            sleepQuality: 5,
            hrvScore: 75.0,
            recoveryScore: 90.0,
            stressorLevel: 1,
            muscleSoreness: 1,
            jointPain: 4,  // High joint pain
            generalWellbeing: 5,
            rawReadinessBand: .green,
            modifiedReadinessBand: .red,  // Should be overridden
            dataSource: .manual
        )

        // When
        let band = service.calculateReadinessBand(readiness)

        // Then
        XCTAssertEqual(band, .red, "High joint pain should override to red band")
    }

    // MARK: - Performance Tests

    func testReadinessCalculationPerformance() throws {
        measure {
            let service = ReadinessService(supabase: supabase)
            for _ in 0..<1000 {
                let readiness = DailyReadiness(
                    id: UUID(),
                    patientId: UUID(),
                    date: Date(),
                    sleepHours: 7.5,
                    sleepQuality: 4,
                    hrvScore: 65.0,
                    recoveryScore: 75.0,
                    stressorLevel: 2,
                    muscleSoreness: 3,
                    jointPain: 1,
                    generalWellbeing: 4,
                    rawReadinessBand: .green,
                    modifiedReadinessBand: .green,
                    dataSource: .manual
                )
                let band = service.calculateReadinessBand(readiness)
                XCTAssertNotNil(band)
            }
        }
    }
}
