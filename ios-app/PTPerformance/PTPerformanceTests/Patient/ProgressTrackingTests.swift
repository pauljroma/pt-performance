//
//  ProgressTrackingTests.swift
//  PTPerformanceTests
//
//  Comprehensive tests for patient progress tracking features.
//  Tests readiness check-in, body composition logging, achievement unlocking,
//  and progress charts data.
//

import XCTest
import SwiftUI
@testable import PTPerformance

// MARK: - Mock Services

class MockProgressTrackingService {

    var shouldFailSubmitReadiness = false
    var shouldFailFetchReadiness = false
    var shouldFailLogBodyComp = false
    var shouldFailFetchBodyComp = false
    var shouldFailFetchAchievements = false
    var shouldFailFetchChartData = false

    var submitReadinessCallCount = 0
    var fetchReadinessCallCount = 0
    var logBodyCompCallCount = 0
    var fetchBodyCompCallCount = 0
    var fetchAchievementsCallCount = 0
    var fetchChartDataCallCount = 0

    var mockReadinessHistory: [MockDailyReadiness] = []
    var mockBodyCompHistory: [MockBodyComposition] = []
    var mockAchievements: [MockAchievement] = []
    var mockChartData: MockProgressChartData?

    var lastSubmittedReadiness: (
        sleepHours: Double,
        soreness: Int,
        energy: Int,
        stress: Int,
        notes: String?
    )?

    var lastLoggedBodyComp: (
        weight: Double?,
        bodyFat: Double?,
        muscleMass: Double?,
        notes: String?
    )?

    func submitReadiness(
        patientId: UUID,
        sleepHours: Double,
        soreness: Int,
        energy: Int,
        stress: Int,
        notes: String?
    ) async throws -> MockDailyReadiness {
        submitReadinessCallCount += 1
        if shouldFailSubmitReadiness {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Submit readiness failed"])
        }
        lastSubmittedReadiness = (sleepHours, soreness, energy, stress, notes)
        return MockDailyReadiness(
            id: UUID(),
            patientId: patientId,
            date: Date(),
            sleepHours: sleepHours,
            soreness: soreness,
            energy: energy,
            stress: stress,
            readinessScore: calculateReadinessScore(sleepHours: sleepHours, soreness: soreness, energy: energy, stress: stress),
            notes: notes
        )
    }

    func fetchReadinessHistory(patientId: UUID, days: Int) async throws -> [MockDailyReadiness] {
        fetchReadinessCallCount += 1
        if shouldFailFetchReadiness {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Fetch readiness failed"])
        }
        return mockReadinessHistory
    }

    func logBodyComposition(
        patientId: UUID,
        weight: Double?,
        bodyFat: Double?,
        muscleMass: Double?,
        notes: String?
    ) async throws -> MockBodyComposition {
        logBodyCompCallCount += 1
        if shouldFailLogBodyComp {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Log body composition failed"])
        }
        lastLoggedBodyComp = (weight, bodyFat, muscleMass, notes)
        return MockBodyComposition(
            id: UUID(),
            patientId: patientId,
            date: Date(),
            weight: weight,
            bodyFat: bodyFat,
            muscleMass: muscleMass,
            notes: notes
        )
    }

    func fetchBodyCompHistory(patientId: UUID, limit: Int) async throws -> [MockBodyComposition] {
        fetchBodyCompCallCount += 1
        if shouldFailFetchBodyComp {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Fetch body composition failed"])
        }
        return mockBodyCompHistory
    }

    func fetchAchievements(patientId: UUID) async throws -> [MockAchievement] {
        fetchAchievementsCallCount += 1
        if shouldFailFetchAchievements {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Fetch achievements failed"])
        }
        return mockAchievements
    }

    func fetchChartData(patientId: UUID, metric: String, days: Int) async throws -> MockProgressChartData {
        fetchChartDataCallCount += 1
        if shouldFailFetchChartData {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Fetch chart data failed"])
        }
        return mockChartData ?? MockProgressChartData(
            metric: metric,
            dataPoints: [],
            trend: nil
        )
    }

    private func calculateReadinessScore(sleepHours: Double, soreness: Int, energy: Int, stress: Int) -> Double {
        let sleepComponent = min(sleepHours / 8.0, 1.0) * 35
        let energyComponent = Double(energy) / 10.0 * 35
        let sorenessComponent = (1.0 - Double(soreness - 1) / 9.0) * 15
        let stressComponent = (1.0 - Double(stress - 1) / 9.0) * 15
        return sleepComponent + energyComponent + sorenessComponent + stressComponent
    }

    func reset() {
        shouldFailSubmitReadiness = false
        shouldFailFetchReadiness = false
        shouldFailLogBodyComp = false
        shouldFailFetchBodyComp = false
        shouldFailFetchAchievements = false
        shouldFailFetchChartData = false
        submitReadinessCallCount = 0
        fetchReadinessCallCount = 0
        logBodyCompCallCount = 0
        fetchBodyCompCallCount = 0
        fetchAchievementsCallCount = 0
        fetchChartDataCallCount = 0
        mockReadinessHistory = []
        mockBodyCompHistory = []
        mockAchievements = []
        mockChartData = nil
        lastSubmittedReadiness = nil
        lastLoggedBodyComp = nil
    }
}

// MARK: - Mock Models

struct MockDailyReadiness: Identifiable, Equatable {
    let id: UUID
    let patientId: UUID
    let date: Date
    let sleepHours: Double
    let soreness: Int
    let energy: Int
    let stress: Int
    let readinessScore: Double
    let notes: String?
}

struct MockBodyComposition: Identifiable, Equatable {
    let id: UUID
    let patientId: UUID
    let date: Date
    let weight: Double?
    let bodyFat: Double?
    let muscleMass: Double?
    let notes: String?
}

struct MockAchievement: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let type: String
    let tier: String
    let requirement: Int
    let currentValue: Int
    let isUnlocked: Bool
    let unlockedAt: Date?
    let points: Int
}

struct MockProgressChartData {
    let metric: String
    let dataPoints: [(date: Date, value: Double)]
    let trend: Double?
}

// MARK: - Progress Tracking Tests

@MainActor
final class ProgressTrackingTests: XCTestCase {

    var mockService: MockProgressTrackingService!
    let testPatientId = UUID()

    override func setUp() async throws {
        try await super.setUp()
        mockService = MockProgressTrackingService()
    }

    override func tearDown() async throws {
        mockService = nil
        try await super.tearDown()
    }

    // MARK: - Readiness Check-In Tests

    func testSubmitReadiness_OptimalValues() async throws {
        let readiness = try await mockService.submitReadiness(
            patientId: testPatientId,
            sleepHours: 8.0,
            soreness: 1,
            energy: 10,
            stress: 1,
            notes: nil
        )

        XCTAssertNotNil(readiness)
        XCTAssertEqual(mockService.lastSubmittedReadiness?.sleepHours, 8.0)
        XCTAssertEqual(mockService.lastSubmittedReadiness?.soreness, 1)
        XCTAssertEqual(mockService.lastSubmittedReadiness?.energy, 10)
        XCTAssertEqual(mockService.lastSubmittedReadiness?.stress, 1)
        XCTAssertEqual(readiness.readinessScore, 100.0, accuracy: 1.0)
    }

    func testSubmitReadiness_PoorValues() async throws {
        let readiness = try await mockService.submitReadiness(
            patientId: testPatientId,
            sleepHours: 4.0,
            soreness: 8,
            energy: 2,
            stress: 9,
            notes: "Feeling exhausted"
        )

        XCTAssertNotNil(readiness)
        XCTAssertLessThan(readiness.readinessScore, 50.0)
        XCTAssertEqual(mockService.lastSubmittedReadiness?.notes, "Feeling exhausted")
    }

    func testSubmitReadiness_AverageValues() async throws {
        let readiness = try await mockService.submitReadiness(
            patientId: testPatientId,
            sleepHours: 7.0,
            soreness: 5,
            energy: 5,
            stress: 5,
            notes: nil
        )

        XCTAssertNotNil(readiness)
        XCTAssertGreaterThan(readiness.readinessScore, 40.0)
        XCTAssertLessThan(readiness.readinessScore, 80.0)
    }

    func testSubmitReadiness_WithNotes() async throws {
        let notes = "Had a restless night but feeling energized"

        let readiness = try await mockService.submitReadiness(
            patientId: testPatientId,
            sleepHours: 6.0,
            soreness: 3,
            energy: 7,
            stress: 4,
            notes: notes
        )

        XCTAssertEqual(readiness.notes, notes)
        XCTAssertEqual(mockService.lastSubmittedReadiness?.notes, notes)
    }

    func testSubmitReadiness_Failure() async {
        mockService.shouldFailSubmitReadiness = true

        do {
            _ = try await mockService.submitReadiness(
                patientId: testPatientId,
                sleepHours: 7.0,
                soreness: 5,
                energy: 5,
                stress: 5,
                notes: nil
            )
            XCTFail("Should throw error when submit fails")
        } catch {
            XCTAssertEqual(mockService.submitReadinessCallCount, 1)
        }
    }

    func testSubmitReadiness_SleepHoursRange() async throws {
        // Test minimum sleep
        var readiness = try await mockService.submitReadiness(
            patientId: testPatientId,
            sleepHours: 0.0,
            soreness: 5,
            energy: 5,
            stress: 5,
            notes: nil
        )
        XCTAssertEqual(mockService.lastSubmittedReadiness?.sleepHours, 0.0)

        // Test maximum sleep
        readiness = try await mockService.submitReadiness(
            patientId: testPatientId,
            sleepHours: 12.0,
            soreness: 5,
            energy: 5,
            stress: 5,
            notes: nil
        )
        XCTAssertEqual(mockService.lastSubmittedReadiness?.sleepHours, 12.0)
    }

    func testSubmitReadiness_LevelRanges() async throws {
        // Test minimum levels
        var readiness = try await mockService.submitReadiness(
            patientId: testPatientId,
            sleepHours: 7.0,
            soreness: 1,
            energy: 1,
            stress: 1,
            notes: nil
        )
        XCTAssertEqual(mockService.lastSubmittedReadiness?.soreness, 1)
        XCTAssertEqual(mockService.lastSubmittedReadiness?.energy, 1)
        XCTAssertEqual(mockService.lastSubmittedReadiness?.stress, 1)

        // Test maximum levels
        readiness = try await mockService.submitReadiness(
            patientId: testPatientId,
            sleepHours: 7.0,
            soreness: 10,
            energy: 10,
            stress: 10,
            notes: nil
        )
        XCTAssertEqual(mockService.lastSubmittedReadiness?.soreness, 10)
        XCTAssertEqual(mockService.lastSubmittedReadiness?.energy, 10)
        XCTAssertEqual(mockService.lastSubmittedReadiness?.stress, 10)
    }

    // MARK: - Readiness History Tests

    func testFetchReadinessHistory_Success() async throws {
        mockService.mockReadinessHistory = [
            MockDailyReadiness(id: UUID(), patientId: testPatientId, date: Date(), sleepHours: 7.0, soreness: 3, energy: 7, stress: 4, readinessScore: 75.0, notes: nil),
            MockDailyReadiness(id: UUID(), patientId: testPatientId, date: Date().addingTimeInterval(-86400), sleepHours: 8.0, soreness: 2, energy: 8, stress: 3, readinessScore: 85.0, notes: nil)
        ]

        let history = try await mockService.fetchReadinessHistory(patientId: testPatientId, days: 7)

        XCTAssertEqual(history.count, 2)
        XCTAssertEqual(mockService.fetchReadinessCallCount, 1)
    }

    func testFetchReadinessHistory_Empty() async throws {
        mockService.mockReadinessHistory = []

        let history = try await mockService.fetchReadinessHistory(patientId: testPatientId, days: 7)

        XCTAssertTrue(history.isEmpty)
    }

    func testFetchReadinessHistory_Failure() async {
        mockService.shouldFailFetchReadiness = true

        do {
            _ = try await mockService.fetchReadinessHistory(patientId: testPatientId, days: 7)
            XCTFail("Should throw error when fetch fails")
        } catch {
            XCTAssertEqual(mockService.fetchReadinessCallCount, 1)
        }
    }

    // MARK: - Body Composition Logging Tests

    func testLogBodyComp_AllFields() async throws {
        let bodyComp = try await mockService.logBodyComposition(
            patientId: testPatientId,
            weight: 180.5,
            bodyFat: 15.5,
            muscleMass: 145.0,
            notes: "Morning weigh-in"
        )

        XCTAssertNotNil(bodyComp)
        XCTAssertEqual(mockService.lastLoggedBodyComp?.weight, 180.5)
        XCTAssertEqual(mockService.lastLoggedBodyComp?.bodyFat, 15.5)
        XCTAssertEqual(mockService.lastLoggedBodyComp?.muscleMass, 145.0)
        XCTAssertEqual(mockService.lastLoggedBodyComp?.notes, "Morning weigh-in")
    }

    func testLogBodyComp_WeightOnly() async throws {
        let bodyComp = try await mockService.logBodyComposition(
            patientId: testPatientId,
            weight: 175.0,
            bodyFat: nil,
            muscleMass: nil,
            notes: nil
        )

        XCTAssertNotNil(bodyComp)
        XCTAssertEqual(mockService.lastLoggedBodyComp?.weight, 175.0)
        XCTAssertNil(mockService.lastLoggedBodyComp?.bodyFat)
        XCTAssertNil(mockService.lastLoggedBodyComp?.muscleMass)
    }

    func testLogBodyComp_BodyFatOnly() async throws {
        let bodyComp = try await mockService.logBodyComposition(
            patientId: testPatientId,
            weight: nil,
            bodyFat: 18.0,
            muscleMass: nil,
            notes: nil
        )

        XCTAssertNotNil(bodyComp)
        XCTAssertNil(mockService.lastLoggedBodyComp?.weight)
        XCTAssertEqual(mockService.lastLoggedBodyComp?.bodyFat, 18.0)
    }

    func testLogBodyComp_Failure() async {
        mockService.shouldFailLogBodyComp = true

        do {
            _ = try await mockService.logBodyComposition(
                patientId: testPatientId,
                weight: 180.0,
                bodyFat: 15.0,
                muscleMass: nil,
                notes: nil
            )
            XCTFail("Should throw error when log fails")
        } catch {
            XCTAssertEqual(mockService.logBodyCompCallCount, 1)
        }
    }

    // MARK: - Body Composition History Tests

    func testFetchBodyCompHistory_Success() async throws {
        mockService.mockBodyCompHistory = [
            MockBodyComposition(id: UUID(), patientId: testPatientId, date: Date(), weight: 180.0, bodyFat: 15.0, muscleMass: 145.0, notes: nil),
            MockBodyComposition(id: UUID(), patientId: testPatientId, date: Date().addingTimeInterval(-604800), weight: 182.0, bodyFat: 16.0, muscleMass: 144.0, notes: nil)
        ]

        let history = try await mockService.fetchBodyCompHistory(patientId: testPatientId, limit: 10)

        XCTAssertEqual(history.count, 2)
    }

    func testFetchBodyCompHistory_Empty() async throws {
        mockService.mockBodyCompHistory = []

        let history = try await mockService.fetchBodyCompHistory(patientId: testPatientId, limit: 10)

        XCTAssertTrue(history.isEmpty)
    }

    func testFetchBodyCompHistory_Failure() async {
        mockService.shouldFailFetchBodyComp = true

        do {
            _ = try await mockService.fetchBodyCompHistory(patientId: testPatientId, limit: 10)
            XCTFail("Should throw error when fetch fails")
        } catch {
            XCTAssertEqual(mockService.fetchBodyCompCallCount, 1)
        }
    }

    // MARK: - Achievement Unlocking Tests

    func testFetchAchievements_Unlocked() async throws {
        mockService.mockAchievements = [
            MockAchievement(id: "streak_7_day", title: "Week Warrior", description: "7-day streak", type: "streak", tier: "bronze", requirement: 7, currentValue: 10, isUnlocked: true, unlockedAt: Date(), points: 10),
            MockAchievement(id: "first_workout", title: "First Steps", description: "Complete first workout", type: "workouts", tier: "bronze", requirement: 1, currentValue: 25, isUnlocked: true, unlockedAt: Date(), points: 10)
        ]

        let achievements = try await mockService.fetchAchievements(patientId: testPatientId)

        XCTAssertEqual(achievements.count, 2)
        XCTAssertTrue(achievements.allSatisfy { $0.isUnlocked })
    }

    func testFetchAchievements_Locked() async throws {
        mockService.mockAchievements = [
            MockAchievement(id: "streak_100_day", title: "Century Champion", description: "100-day streak", type: "streak", tier: "diamond", requirement: 100, currentValue: 45, isUnlocked: false, unlockedAt: nil, points: 200)
        ]

        let achievements = try await mockService.fetchAchievements(patientId: testPatientId)

        XCTAssertEqual(achievements.count, 1)
        XCTAssertFalse(achievements[0].isUnlocked)
        XCTAssertNil(achievements[0].unlockedAt)
    }

    func testFetchAchievements_Mixed() async throws {
        mockService.mockAchievements = [
            MockAchievement(id: "streak_7_day", title: "Week Warrior", description: "7-day streak", type: "streak", tier: "bronze", requirement: 7, currentValue: 7, isUnlocked: true, unlockedAt: Date(), points: 10),
            MockAchievement(id: "streak_30_day", title: "Monthly Master", description: "30-day streak", type: "streak", tier: "gold", requirement: 30, currentValue: 7, isUnlocked: false, unlockedAt: nil, points: 50)
        ]

        let achievements = try await mockService.fetchAchievements(patientId: testPatientId)
        let unlocked = achievements.filter { $0.isUnlocked }
        let locked = achievements.filter { !$0.isUnlocked }

        XCTAssertEqual(unlocked.count, 1)
        XCTAssertEqual(locked.count, 1)
    }

    func testFetchAchievements_Progress() async throws {
        mockService.mockAchievements = [
            MockAchievement(id: "workouts_100", title: "Century Club", description: "Complete 100 workouts", type: "workouts", tier: "gold", requirement: 100, currentValue: 75, isUnlocked: false, unlockedAt: nil, points: 50)
        ]

        let achievements = try await mockService.fetchAchievements(patientId: testPatientId)
        let achievement = achievements[0]

        let progress = Double(achievement.currentValue) / Double(achievement.requirement)
        XCTAssertEqual(progress, 0.75, accuracy: 0.01)
    }

    func testFetchAchievements_TotalPoints() async throws {
        mockService.mockAchievements = [
            MockAchievement(id: "streak_7_day", title: "Week Warrior", description: "7-day streak", type: "streak", tier: "bronze", requirement: 7, currentValue: 7, isUnlocked: true, unlockedAt: Date(), points: 10),
            MockAchievement(id: "streak_14_day", title: "Fortnight Fighter", description: "14-day streak", type: "streak", tier: "silver", requirement: 14, currentValue: 14, isUnlocked: true, unlockedAt: Date(), points: 25),
            MockAchievement(id: "first_workout", title: "First Steps", description: "First workout", type: "workouts", tier: "bronze", requirement: 1, currentValue: 1, isUnlocked: true, unlockedAt: Date(), points: 10)
        ]

        let achievements = try await mockService.fetchAchievements(patientId: testPatientId)
        let totalPoints = achievements.filter { $0.isUnlocked }.reduce(0) { $0 + $1.points }

        XCTAssertEqual(totalPoints, 45)
    }

    func testFetchAchievements_Failure() async {
        mockService.shouldFailFetchAchievements = true

        do {
            _ = try await mockService.fetchAchievements(patientId: testPatientId)
            XCTFail("Should throw error when fetch fails")
        } catch {
            XCTAssertEqual(mockService.fetchAchievementsCallCount, 1)
        }
    }

    // MARK: - Progress Charts Data Tests

    func testFetchChartData_Weight() async throws {
        let today = Date()
        mockService.mockChartData = MockProgressChartData(
            metric: "weight",
            dataPoints: [
                (date: today.addingTimeInterval(-604800), value: 185.0),
                (date: today.addingTimeInterval(-432000), value: 183.5),
                (date: today.addingTimeInterval(-259200), value: 182.0),
                (date: today, value: 180.5)
            ],
            trend: -0.64  // lbs per day
        )

        let chartData = try await mockService.fetchChartData(patientId: testPatientId, metric: "weight", days: 7)

        XCTAssertEqual(chartData.metric, "weight")
        XCTAssertEqual(chartData.dataPoints.count, 4)
        XCTAssertNotNil(chartData.trend)
    }

    func testFetchChartData_Readiness() async throws {
        mockService.mockChartData = MockProgressChartData(
            metric: "readiness",
            dataPoints: [
                (date: Date().addingTimeInterval(-86400 * 6), value: 65.0),
                (date: Date().addingTimeInterval(-86400 * 5), value: 70.0),
                (date: Date().addingTimeInterval(-86400 * 4), value: 68.0),
                (date: Date().addingTimeInterval(-86400 * 3), value: 75.0),
                (date: Date().addingTimeInterval(-86400 * 2), value: 72.0),
                (date: Date().addingTimeInterval(-86400), value: 80.0),
                (date: Date(), value: 78.0)
            ],
            trend: 2.0  // Improving
        )

        let chartData = try await mockService.fetchChartData(patientId: testPatientId, metric: "readiness", days: 7)

        XCTAssertEqual(chartData.metric, "readiness")
        XCTAssertEqual(chartData.dataPoints.count, 7)
        XCTAssertGreaterThan(chartData.trend ?? 0, 0)  // Positive trend
    }

    func testFetchChartData_Volume() async throws {
        mockService.mockChartData = MockProgressChartData(
            metric: "volume",
            dataPoints: [
                (date: Date().addingTimeInterval(-604800), value: 15000.0),
                (date: Date(), value: 18000.0)
            ],
            trend: 428.6  // lbs per day increase
        )

        let chartData = try await mockService.fetchChartData(patientId: testPatientId, metric: "volume", days: 7)

        XCTAssertEqual(chartData.metric, "volume")
        XCTAssertGreaterThan(chartData.trend ?? 0, 0)
    }

    func testFetchChartData_Empty() async throws {
        mockService.mockChartData = MockProgressChartData(
            metric: "weight",
            dataPoints: [],
            trend: nil
        )

        let chartData = try await mockService.fetchChartData(patientId: testPatientId, metric: "weight", days: 7)

        XCTAssertTrue(chartData.dataPoints.isEmpty)
        XCTAssertNil(chartData.trend)
    }

    func testFetchChartData_Failure() async {
        mockService.shouldFailFetchChartData = true

        do {
            _ = try await mockService.fetchChartData(patientId: testPatientId, metric: "weight", days: 7)
            XCTFail("Should throw error when fetch fails")
        } catch {
            XCTAssertEqual(mockService.fetchChartDataCallCount, 1)
        }
    }
}

// MARK: - Readiness Score Calculation Tests

final class ReadinessScoreCalculationTests: XCTestCase {

    func testReadinessScore_Optimal() {
        let score = calculateReadinessScore(sleepHours: 8.0, soreness: 1, energy: 10, stress: 1)
        XCTAssertEqual(score, 100.0, accuracy: 1.0)
    }

    func testReadinessScore_Poor() {
        let score = calculateReadinessScore(sleepHours: 2.0, soreness: 10, energy: 1, stress: 10)
        XCTAssertLessThan(score, 30.0)
    }

    func testReadinessScore_Average() {
        let score = calculateReadinessScore(sleepHours: 7.0, soreness: 5, energy: 5, stress: 5)
        XCTAssertGreaterThan(score, 50.0)
        XCTAssertLessThan(score, 75.0)
    }

    func testReadinessScore_SleepWeight() {
        // Higher sleep should increase score
        let lowSleep = calculateReadinessScore(sleepHours: 4.0, soreness: 5, energy: 5, stress: 5)
        let highSleep = calculateReadinessScore(sleepHours: 8.0, soreness: 5, energy: 5, stress: 5)

        XCTAssertGreaterThan(highSleep, lowSleep)
    }

    func testReadinessScore_EnergyWeight() {
        // Higher energy should increase score
        let lowEnergy = calculateReadinessScore(sleepHours: 7.0, soreness: 5, energy: 2, stress: 5)
        let highEnergy = calculateReadinessScore(sleepHours: 7.0, soreness: 5, energy: 9, stress: 5)

        XCTAssertGreaterThan(highEnergy, lowEnergy)
    }

    func testReadinessScore_SorenessInverseWeight() {
        // Lower soreness should increase score
        let highSoreness = calculateReadinessScore(sleepHours: 7.0, soreness: 8, energy: 5, stress: 5)
        let lowSoreness = calculateReadinessScore(sleepHours: 7.0, soreness: 2, energy: 5, stress: 5)

        XCTAssertGreaterThan(lowSoreness, highSoreness)
    }

    func testReadinessScore_StressInverseWeight() {
        // Lower stress should increase score
        let highStress = calculateReadinessScore(sleepHours: 7.0, soreness: 5, energy: 5, stress: 9)
        let lowStress = calculateReadinessScore(sleepHours: 7.0, soreness: 5, energy: 5, stress: 2)

        XCTAssertGreaterThan(lowStress, highStress)
    }

    private func calculateReadinessScore(sleepHours: Double, soreness: Int, energy: Int, stress: Int) -> Double {
        let sleepComponent = min(sleepHours / 8.0, 1.0) * 35
        let energyComponent = Double(energy) / 10.0 * 35
        let sorenessComponent = (1.0 - Double(soreness - 1) / 9.0) * 15
        let stressComponent = (1.0 - Double(stress - 1) / 9.0) * 15
        return sleepComponent + energyComponent + sorenessComponent + stressComponent
    }
}

// MARK: - Readiness Category Tests

final class ReadinessCategoryTests: XCTestCase {

    func testReadinessCategory_Elite() {
        XCTAssertEqual(categorizeReadiness(score: 95.0), "Elite")
        XCTAssertEqual(categorizeReadiness(score: 90.0), "Elite")
    }

    func testReadinessCategory_High() {
        XCTAssertEqual(categorizeReadiness(score: 85.0), "High")
        XCTAssertEqual(categorizeReadiness(score: 75.0), "High")
    }

    func testReadinessCategory_Moderate() {
        XCTAssertEqual(categorizeReadiness(score: 70.0), "Moderate")
        XCTAssertEqual(categorizeReadiness(score: 60.0), "Moderate")
    }

    func testReadinessCategory_Low() {
        XCTAssertEqual(categorizeReadiness(score: 55.0), "Low")
        XCTAssertEqual(categorizeReadiness(score: 45.0), "Low")
    }

    func testReadinessCategory_Poor() {
        XCTAssertEqual(categorizeReadiness(score: 40.0), "Poor")
        XCTAssertEqual(categorizeReadiness(score: 20.0), "Poor")
    }

    private func categorizeReadiness(score: Double) -> String {
        switch score {
        case 90...: return "Elite"
        case 75..<90: return "High"
        case 60..<75: return "Moderate"
        case 45..<60: return "Low"
        default: return "Poor"
        }
    }
}

// MARK: - Achievement Tier Tests

final class AchievementTierTests: XCTestCase {

    func testAchievementTier_Points() {
        let tiers: [String: Int] = [
            "bronze": 10,
            "silver": 25,
            "gold": 50,
            "platinum": 100,
            "diamond": 200
        ]

        for (tier, points) in tiers {
            XCTAssertEqual(getPoints(for: tier), points)
        }
    }

    func testAchievementTier_Order() {
        let tierOrder = ["bronze", "silver", "gold", "platinum", "diamond"]
        var previousPoints = 0

        for tier in tierOrder {
            let points = getPoints(for: tier)
            XCTAssertGreaterThan(points, previousPoints)
            previousPoints = points
        }
    }

    private func getPoints(for tier: String) -> Int {
        switch tier {
        case "bronze": return 10
        case "silver": return 25
        case "gold": return 50
        case "platinum": return 100
        case "diamond": return 200
        default: return 0
        }
    }
}

// MARK: - Body Composition Trend Tests

final class BodyCompositionTrendTests: XCTestCase {

    func testWeightTrend_Decreasing() {
        let weights = [185.0, 183.0, 181.0, 179.0]
        let trend = calculateTrend(values: weights)

        XCTAssertLessThan(trend, 0)  // Negative = weight loss
    }

    func testWeightTrend_Increasing() {
        let weights = [175.0, 177.0, 179.0, 181.0]
        let trend = calculateTrend(values: weights)

        XCTAssertGreaterThan(trend, 0)  // Positive = weight gain
    }

    func testWeightTrend_Stable() {
        let weights = [180.0, 180.0, 180.0, 180.0]
        let trend = calculateTrend(values: weights)

        XCTAssertEqual(trend, 0.0, accuracy: 0.01)
    }

    func testBodyFatTrend_Decreasing() {
        let bodyFat = [20.0, 19.0, 18.0, 17.0]
        let trend = calculateTrend(values: bodyFat)

        XCTAssertLessThan(trend, 0)  // Decreasing
    }

    func testMuscleMassTrend_Increasing() {
        let muscleMass = [140.0, 142.0, 144.0, 146.0]
        let trend = calculateTrend(values: muscleMass)

        XCTAssertGreaterThan(trend, 0)  // Increasing
    }

    private func calculateTrend(values: [Double]) -> Double {
        guard values.count >= 2 else { return 0.0 }
        let n = Double(values.count)
        let sumX = (0..<values.count).reduce(0.0) { $0 + Double($1) }
        let sumY = values.reduce(0.0, +)
        let sumXY = (0..<values.count).reduce(0.0) { $0 + Double($1) * values[$1] }
        let sumX2 = (0..<values.count).reduce(0.0) { $0 + Double($1) * Double($1) }

        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
        return slope
    }
}

// MARK: - Progress Percentage Tests

final class ProgressPercentageTests: XCTestCase {

    func testProgress_ZeroPercent() {
        let current = 0
        let requirement = 100

        let progress = Double(current) / Double(requirement)

        XCTAssertEqual(progress, 0.0)
    }

    func testProgress_FiftyPercent() {
        let current = 50
        let requirement = 100

        let progress = Double(current) / Double(requirement)

        XCTAssertEqual(progress, 0.5)
    }

    func testProgress_Complete() {
        let current = 100
        let requirement = 100

        let progress = Double(current) / Double(requirement)

        XCTAssertEqual(progress, 1.0)
    }

    func testProgress_Exceeded() {
        let current = 150
        let requirement = 100

        let progress = min(Double(current) / Double(requirement), 1.0)

        XCTAssertEqual(progress, 1.0)  // Capped at 100%
    }

    func testProgress_Remaining() {
        let current = 75
        let requirement = 100

        let remaining = requirement - current

        XCTAssertEqual(remaining, 25)
    }
}
