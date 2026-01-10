import XCTest
@testable import PTPerformance

/// BUILD 118 - Phase 3: Integration Tests for Daily Readiness
/// Tests end-to-end flows with database interactions
final class ReadinessIntegrationTests: XCTestCase {

    var readinessService: ReadinessService!
    let testPatientId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    override func setUp() async throws {
        try await super.setUp()
        readinessService = ReadinessService(client: .shared)

        // Clean up any existing test data
        try? await readinessService.deleteReadiness(for: testPatientId, on: Date())
    }

    override func tearDown() async throws {
        // Clean up test data
        try? await readinessService.deleteReadiness(for: testPatientId, on: Date())
        readinessService = nil
        try await super.tearDown()
    }

    // MARK: - Test Patient Check-In E2E

    /// Tests complete patient check-in flow from submission to retrieval
    func testPatientCheckInE2E() async throws {
        // Given: Patient wants to log today's readiness
        let today = Date()
        let sleepHours = 7.5
        let sorenessLevel = 3
        let energyLevel = 8
        let stressLevel = 2
        let notes = "Feeling great today!"

        // When: Patient submits check-in
        let submittedEntry = try await readinessService.submitReadiness(
            patientId: testPatientId,
            date: today,
            sleepHours: sleepHours,
            sorenessLevel: sorenessLevel,
            energyLevel: energyLevel,
            stressLevel: stressLevel,
            notes: notes
        )

        // Then: Entry should be created with calculated score
        XCTAssertEqual(submittedEntry.patientId, testPatientId)
        XCTAssertEqual(submittedEntry.sleepHours, sleepHours)
        XCTAssertEqual(submittedEntry.sorenessLevel, sorenessLevel)
        XCTAssertEqual(submittedEntry.energyLevel, energyLevel)
        XCTAssertEqual(submittedEntry.stressLevel, stressLevel)
        XCTAssertEqual(submittedEntry.notes, notes)
        XCTAssertNotNil(submittedEntry.readinessScore, "Database trigger should calculate score")
        XCTAssertGreaterThan(submittedEntry.readinessScore!, 0)
        XCTAssertLessThanOrEqual(submittedEntry.readinessScore!, 100)

        // And: Should be retrievable as today's entry
        let retrievedEntry = try await readinessService.getTodayReadiness(for: testPatientId)
        XCTAssertNotNil(retrievedEntry)
        XCTAssertEqual(retrievedEntry?.id, submittedEntry.id)
        XCTAssertEqual(retrievedEntry?.readinessScore, submittedEntry.readinessScore)

        // And: Should check that entry exists for today
        let hasLogged = await readinessService.hasLoggedToday(patientId: testPatientId)
        XCTAssertTrue(hasLogged, "Should confirm today's entry exists")
    }

    // MARK: - Test Therapist Views Patient Data

    /// Tests that therapists can view all patient readiness data
    func testTherapistViewsPatientData() async throws {
        // Given: Multiple patients have submitted readiness data
        let patient1Id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let patient2Id = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

        // Submit data for patient 1
        let entry1 = try await readinessService.submitReadiness(
            patientId: patient1Id,
            sleepHours: 7.5,
            sorenessLevel: 3,
            energyLevel: 8,
            stressLevel: 2
        )

        // Submit data for patient 2
        let entry2 = try await readinessService.submitReadiness(
            patientId: patient2Id,
            sleepHours: 6.0,
            sorenessLevel: 6,
            energyLevel: 5,
            stressLevel: 7
        )

        // When: Therapist fetches data for each patient
        let patient1Data = try await readinessService.getTodayReadiness(for: patient1Id)
        let patient2Data = try await readinessService.getTodayReadiness(for: patient2Id)

        // Then: Therapist should see both patients' data
        XCTAssertNotNil(patient1Data)
        XCTAssertNotNil(patient2Data)
        XCTAssertEqual(patient1Data?.id, entry1.id)
        XCTAssertEqual(patient2Data?.id, entry2.id)

        // And: Scores should reflect different wellness levels
        XCTAssertGreaterThan(patient1Data?.readinessScore ?? 0, patient2Data?.readinessScore ?? 100,
                            "Patient 1 (better metrics) should have higher score than Patient 2")

        // Cleanup
        try? await readinessService.deleteReadiness(for: patient1Id, on: Date())
        try? await readinessService.deleteReadiness(for: patient2Id, on: Date())
    }

    // MARK: - Test Trend Calculation

    /// Tests that readiness trends are calculated correctly over time
    func testTrendCalculation() async throws {
        // Given: Patient has submitted readiness data for past 7 days
        let today = Date()
        let calendar = Calendar.current

        var submittedEntries: [DailyReadiness] = []

        for dayOffset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!

            // Simulate improving wellness over the week
            let sleepHours = 6.0 + Double(dayOffset) * 0.5  // 6.0 → 9.0
            let sorenessLevel = 7 - dayOffset               // 7 → 1
            let energyLevel = 5 + dayOffset                 // 5 → 11 (capped at 10)
            let stressLevel = 6 - dayOffset                 // 6 → 0 (capped at 1)

            let entry = try await readinessService.submitReadiness(
                patientId: testPatientId,
                date: date,
                sleepHours: sleepHours,
                sorenessLevel: min(max(sorenessLevel, 1), 10),
                energyLevel: min(max(energyLevel, 1), 10),
                stressLevel: min(max(stressLevel, 1), 10)
            )

            submittedEntries.append(entry)
        }

        // When: Fetching trend data
        let trendData = try await readinessService.fetchRecentReadiness(for: testPatientId, limit: 7)

        // Then: Should have 7 entries
        XCTAssertEqual(trendData.count, 7, "Should have 7 days of data")

        // And: Trend should show improvement (scores increasing over time)
        let sortedByDate = trendData.sorted { $0.date < $1.date }
        if sortedByDate.count >= 2 {
            let firstScore = sortedByDate.first?.readinessScore ?? 0
            let lastScore = sortedByDate.last?.readinessScore ?? 0
            XCTAssertGreaterThan(lastScore, firstScore,
                                "Latest score should be higher than earliest (improving trend)")
        }

        // And: When fetching trend statistics
        let trend = try await readinessService.getReadinessTrend(for: testPatientId, days: 7)

        XCTAssertNotNil(trend.statistics.avgReadiness, "Should calculate average")
        XCTAssertGreaterThan(trend.statistics.avgReadiness ?? 0, 0, "Average should be positive")

        // Cleanup
        for dayOffset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            try? await readinessService.deleteReadiness(for: testPatientId, on: date)
        }
    }

    // MARK: - Test Upsert Behavior (Prevent Duplicates)

    /// Tests that submitting twice for same day updates instead of creating duplicate
    func testUpsertBehavior() async throws {
        // Given: Patient submits morning check-in
        let morningEntry = try await readinessService.submitReadiness(
            patientId: testPatientId,
            sleepHours: 6.0,
            sorenessLevel: 7,
            energyLevel: 5,
            stressLevel: 6,
            notes: "Morning check-in"
        )

        let morningScore = morningEntry.readinessScore

        // Wait a moment to ensure timestamps differ
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // When: Patient updates with afternoon values (better metrics)
        let afternoonEntry = try await readinessService.submitReadiness(
            patientId: testPatientId,
            date: Date(), // Same day
            sleepHours: 7.5,
            sorenessLevel: 3,
            energyLevel: 8,
            stressLevel: 2,
            notes: "Afternoon update"
        )

        // Then: Should have same ID (updated, not created new)
        XCTAssertEqual(afternoonEntry.id, morningEntry.id, "Should update existing entry, not create new")

        // And: Should have updated values
        XCTAssertEqual(afternoonEntry.sleepHours, 7.5)
        XCTAssertEqual(afternoonEntry.notes, "Afternoon update")

        // And: Score should have improved
        XCTAssertNotNil(afternoonEntry.readinessScore)
        if let morningScore = morningScore, let afternoonScore = afternoonEntry.readinessScore {
            XCTAssertGreaterThan(afternoonScore, morningScore, "Better metrics should yield higher score")
        }

        // And: Only one entry should exist for today
        let allToday = try await readinessService.getTodayReadiness(for: testPatientId)
        XCTAssertNotNil(allToday)
        XCTAssertEqual(allToday?.id, afternoonEntry.id)
    }

    // MARK: - Test Dynamic Weight Calculation

    /// Tests that scores use dynamic weights from readiness_factors table
    func testDynamicWeightCalculation() async throws {
        // Given: Database has custom weights configured in readiness_factors
        let factors = try await readinessService.fetchReadinessFactors()

        XCTAssertFalse(factors.isEmpty, "Should have active readiness factors")

        // When: Submitting check-in
        let entry = try await readinessService.submitReadiness(
            patientId: testPatientId,
            sleepHours: 8.0,
            sorenessLevel: 2,
            energyLevel: 9,
            stressLevel: 1
        )

        // Then: Score should be calculated using those weights
        XCTAssertNotNil(entry.readinessScore)
        XCTAssertGreaterThan(entry.readinessScore!, 85.0, "Excellent metrics should yield high score")

        // And: Calculated score should match database function
        let calculatedScore = try await readinessService.calculateScore(for: testPatientId, on: Date())
        XCTAssertEqual(entry.readinessScore, calculatedScore, accuracy: 0.1,
                      "Trigger score should match database function calculation")
    }

    // MARK: - Test Date Range Queries

    /// Tests fetching readiness data for specific date ranges
    func testDateRangeQueries() async throws {
        // Given: Entries over a 30-day period
        let today = Date()
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -29, to: today)!

        // Submit entries for specific dates within range
        let targetDates = [0, 7, 14, 21, 28] // Day offsets
        for offset in targetDates {
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            try await readinessService.submitReadiness(
                patientId: testPatientId,
                date: date,
                sleepHours: 7.5,
                sorenessLevel: 3,
                energyLevel: 8,
                stressLevel: 2
            )
        }

        // When: Fetching data for 30-day range
        let rangeData = try await readinessService.fetchReadiness(
            for: testPatientId,
            from: startDate,
            to: today
        )

        // Then: Should return entries within range
        XCTAssertEqual(rangeData.count, targetDates.count, "Should return all entries in range")

        // And: All dates should be within range
        for entry in rangeData {
            XCTAssertGreaterThanOrEqual(entry.date, startDate)
            XCTAssertLessThanOrEqual(entry.date, today)
        }

        // Cleanup
        for offset in targetDates {
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            try? await readinessService.deleteReadiness(for: testPatientId, on: date)
        }
    }
}
