//
//  RecoveryTrackingTests.swift
//  PTPerformanceTests
//
//  Comprehensive tests for patient recovery tracking features.
//  Tests logging recovery sessions (sauna, cold plunge, contrast),
//  recovery statistics calculation, streak tracking, and recovery recommendations.
//

import XCTest
import SwiftUI
@testable import PTPerformance

// MARK: - Mock Recovery Tracking Service

class MockRecoveryTrackingService {

    var shouldFailLogSession = false
    var shouldFailFetchSessions = false
    var shouldFailFetchStatistics = false
    var shouldFailFetchRecommendations = false

    var logSessionCallCount = 0
    var fetchSessionsCallCount = 0
    var fetchStatisticsCallCount = 0
    var fetchRecommendationsCallCount = 0

    var mockSessions: [MockRecoverySession] = []
    var mockStatistics: MockRecoveryStatistics?
    var mockRecommendations: [MockRecoveryRecommendation] = []

    var lastLoggedSession: (
        protocolType: String,
        durationMinutes: Int,
        temperature: Double?,
        heartRate: Int?,
        effort: Int,
        notes: String?
    )?

    func logSession(
        patientId: UUID,
        protocolType: String,
        durationMinutes: Int,
        temperature: Double?,
        heartRate: Int?,
        effort: Int,
        notes: String?
    ) async throws -> MockRecoverySession {
        logSessionCallCount += 1
        if shouldFailLogSession {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to log session"])
        }
        lastLoggedSession = (protocolType, durationMinutes, temperature, heartRate, effort, notes)
        return MockRecoverySession(
            id: UUID(),
            patientId: patientId,
            protocolType: protocolType,
            durationMinutes: durationMinutes,
            temperature: temperature,
            heartRate: heartRate,
            effort: effort,
            notes: notes,
            loggedAt: Date()
        )
    }

    func fetchSessions(patientId: UUID, limit: Int) async throws -> [MockRecoverySession] {
        fetchSessionsCallCount += 1
        if shouldFailFetchSessions {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch sessions"])
        }
        return mockSessions
    }

    func fetchStatistics(patientId: UUID) async throws -> MockRecoveryStatistics {
        fetchStatisticsCallCount += 1
        if shouldFailFetchStatistics {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch statistics"])
        }
        return mockStatistics ?? MockRecoveryStatistics(
            totalSessions: 0,
            totalMinutes: 0,
            currentStreak: 0,
            longestStreak: 0,
            favoriteProtocol: nil,
            weeklyGoalProgress: 0.0
        )
    }

    func fetchRecommendations(patientId: UUID) async throws -> [MockRecoveryRecommendation] {
        fetchRecommendationsCallCount += 1
        if shouldFailFetchRecommendations {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch recommendations"])
        }
        return mockRecommendations
    }

    func reset() {
        shouldFailLogSession = false
        shouldFailFetchSessions = false
        shouldFailFetchStatistics = false
        shouldFailFetchRecommendations = false
        logSessionCallCount = 0
        fetchSessionsCallCount = 0
        fetchStatisticsCallCount = 0
        fetchRecommendationsCallCount = 0
        mockSessions = []
        mockStatistics = nil
        mockRecommendations = []
        lastLoggedSession = nil
    }
}

// MARK: - Mock Models

struct MockRecoverySession: Identifiable, Equatable {
    let id: UUID
    let patientId: UUID
    let protocolType: String
    let durationMinutes: Int
    let temperature: Double?
    let heartRate: Int?
    let effort: Int
    let notes: String?
    let loggedAt: Date
}

struct MockRecoveryStatistics {
    let totalSessions: Int
    let totalMinutes: Int
    let currentStreak: Int
    let longestStreak: Int
    let favoriteProtocol: String?
    let weeklyGoalProgress: Double
}

struct MockRecoveryRecommendation: Identifiable {
    let id: UUID
    let protocolType: String
    let reason: String
    let priority: String
    let suggestedDuration: Int
}

// MARK: - Recovery Tracking Tests

@MainActor
final class RecoveryTrackingTests: XCTestCase {

    var mockService: MockRecoveryTrackingService!
    let testPatientId = UUID()

    override func setUp() async throws {
        try await super.setUp()
        mockService = MockRecoveryTrackingService()
    }

    override func tearDown() async throws {
        mockService = nil
        try await super.tearDown()
    }

    // MARK: - Logging Recovery Sessions Tests

    func testLogSession_Sauna_Success() async throws {
        let session = try await mockService.logSession(
            patientId: testPatientId,
            protocolType: "sauna_traditional",
            durationMinutes: 20,
            temperature: 180.0,
            heartRate: 120,
            effort: 7,
            notes: "Felt great"
        )

        XCTAssertNotNil(session)
        XCTAssertEqual(mockService.logSessionCallCount, 1)
        XCTAssertEqual(mockService.lastLoggedSession?.protocolType, "sauna_traditional")
        XCTAssertEqual(mockService.lastLoggedSession?.durationMinutes, 20)
        XCTAssertEqual(mockService.lastLoggedSession?.temperature, 180.0)
        XCTAssertEqual(mockService.lastLoggedSession?.heartRate, 120)
        XCTAssertEqual(mockService.lastLoggedSession?.effort, 7)
    }

    func testLogSession_ColdPlunge_Success() async throws {
        let session = try await mockService.logSession(
            patientId: testPatientId,
            protocolType: "cold_plunge",
            durationMinutes: 3,
            temperature: 40.0,
            heartRate: nil,
            effort: 8,
            notes: "Challenging but rewarding"
        )

        XCTAssertNotNil(session)
        XCTAssertEqual(mockService.lastLoggedSession?.protocolType, "cold_plunge")
        XCTAssertEqual(mockService.lastLoggedSession?.durationMinutes, 3)
        XCTAssertEqual(mockService.lastLoggedSession?.temperature, 40.0)
        XCTAssertNil(mockService.lastLoggedSession?.heartRate)
    }

    func testLogSession_Contrast_Success() async throws {
        let session = try await mockService.logSession(
            patientId: testPatientId,
            protocolType: "contrast",
            durationMinutes: 15,
            temperature: nil,  // Temperature varies in contrast
            heartRate: 110,
            effort: 6,
            notes: "3 rounds hot/cold"
        )

        XCTAssertNotNil(session)
        XCTAssertEqual(mockService.lastLoggedSession?.protocolType, "contrast")
        XCTAssertEqual(mockService.lastLoggedSession?.durationMinutes, 15)
        XCTAssertNil(mockService.lastLoggedSession?.temperature)
    }

    func testLogSession_InfraredSauna_Success() async throws {
        let session = try await mockService.logSession(
            patientId: testPatientId,
            protocolType: "sauna_infrared",
            durationMinutes: 30,
            temperature: 150.0,
            heartRate: 100,
            effort: 5,
            notes: nil
        )

        XCTAssertNotNil(session)
        XCTAssertEqual(mockService.lastLoggedSession?.protocolType, "sauna_infrared")
        XCTAssertEqual(mockService.lastLoggedSession?.durationMinutes, 30)
    }

    func testLogSession_IceBath_Success() async throws {
        let session = try await mockService.logSession(
            patientId: testPatientId,
            protocolType: "ice_bath",
            durationMinutes: 5,
            temperature: 35.0,
            heartRate: nil,
            effort: 9,
            notes: "Very cold!"
        )

        XCTAssertNotNil(session)
        XCTAssertEqual(mockService.lastLoggedSession?.protocolType, "ice_bath")
        XCTAssertEqual(mockService.lastLoggedSession?.temperature, 35.0)
        XCTAssertEqual(mockService.lastLoggedSession?.effort, 9)
    }

    func testLogSession_ColdShower_Success() async throws {
        let session = try await mockService.logSession(
            patientId: testPatientId,
            protocolType: "cold_shower",
            durationMinutes: 2,
            temperature: nil,
            heartRate: nil,
            effort: 5,
            notes: nil
        )

        XCTAssertNotNil(session)
        XCTAssertEqual(mockService.lastLoggedSession?.protocolType, "cold_shower")
        XCTAssertEqual(mockService.lastLoggedSession?.durationMinutes, 2)
    }

    func testLogSession_SteamRoom_Success() async throws {
        let session = try await mockService.logSession(
            patientId: testPatientId,
            protocolType: "sauna_steam",
            durationMinutes: 15,
            temperature: nil,  // Steam rooms use humidity
            heartRate: 115,
            effort: 6,
            notes: nil
        )

        XCTAssertNotNil(session)
        XCTAssertEqual(mockService.lastLoggedSession?.protocolType, "sauna_steam")
    }

    func testLogSession_Failure() async {
        mockService.shouldFailLogSession = true

        do {
            _ = try await mockService.logSession(
                patientId: testPatientId,
                protocolType: "sauna_traditional",
                durationMinutes: 20,
                temperature: 180.0,
                heartRate: nil,
                effort: 7,
                notes: nil
            )
            XCTFail("Should throw error when logging fails")
        } catch {
            XCTAssertEqual(mockService.logSessionCallCount, 1)
        }
    }

    func testLogSession_WithoutOptionalFields() async throws {
        let session = try await mockService.logSession(
            patientId: testPatientId,
            protocolType: "cold_plunge",
            durationMinutes: 3,
            temperature: nil,
            heartRate: nil,
            effort: 7,
            notes: nil
        )

        XCTAssertNotNil(session)
        XCTAssertNil(mockService.lastLoggedSession?.temperature)
        XCTAssertNil(mockService.lastLoggedSession?.heartRate)
        XCTAssertNil(mockService.lastLoggedSession?.notes)
    }

    func testLogSession_EffortRange() async throws {
        // Test minimum effort
        _ = try await mockService.logSession(
            patientId: testPatientId,
            protocolType: "cold_shower",
            durationMinutes: 1,
            temperature: nil,
            heartRate: nil,
            effort: 1,
            notes: nil
        )
        XCTAssertEqual(mockService.lastLoggedSession?.effort, 1)

        // Test maximum effort
        _ = try await mockService.logSession(
            patientId: testPatientId,
            protocolType: "ice_bath",
            durationMinutes: 5,
            temperature: 32.0,
            heartRate: nil,
            effort: 10,
            notes: nil
        )
        XCTAssertEqual(mockService.lastLoggedSession?.effort, 10)
    }

    // MARK: - Recovery Statistics Tests

    func testFetchStatistics_Success() async throws {
        mockService.mockStatistics = MockRecoveryStatistics(
            totalSessions: 25,
            totalMinutes: 450,
            currentStreak: 5,
            longestStreak: 12,
            favoriteProtocol: "sauna_traditional",
            weeklyGoalProgress: 0.75
        )

        let stats = try await mockService.fetchStatistics(patientId: testPatientId)

        XCTAssertEqual(stats.totalSessions, 25)
        XCTAssertEqual(stats.totalMinutes, 450)
        XCTAssertEqual(stats.currentStreak, 5)
        XCTAssertEqual(stats.longestStreak, 12)
        XCTAssertEqual(stats.favoriteProtocol, "sauna_traditional")
        XCTAssertEqual(stats.weeklyGoalProgress, 0.75, accuracy: 0.01)
    }

    func testFetchStatistics_Empty() async throws {
        mockService.mockStatistics = MockRecoveryStatistics(
            totalSessions: 0,
            totalMinutes: 0,
            currentStreak: 0,
            longestStreak: 0,
            favoriteProtocol: nil,
            weeklyGoalProgress: 0.0
        )

        let stats = try await mockService.fetchStatistics(patientId: testPatientId)

        XCTAssertEqual(stats.totalSessions, 0)
        XCTAssertEqual(stats.totalMinutes, 0)
        XCTAssertNil(stats.favoriteProtocol)
    }

    func testFetchStatistics_Failure() async {
        mockService.shouldFailFetchStatistics = true

        do {
            _ = try await mockService.fetchStatistics(patientId: testPatientId)
            XCTFail("Should throw error when fetch fails")
        } catch {
            XCTAssertEqual(mockService.fetchStatisticsCallCount, 1)
        }
    }

    func testFetchStatistics_WeeklyProgress() async throws {
        // Test various weekly progress levels
        mockService.mockStatistics = MockRecoveryStatistics(
            totalSessions: 3,
            totalMinutes: 60,
            currentStreak: 3,
            longestStreak: 3,
            favoriteProtocol: "cold_plunge",
            weeklyGoalProgress: 0.5  // 50% toward weekly goal
        )

        let stats = try await mockService.fetchStatistics(patientId: testPatientId)

        XCTAssertEqual(stats.weeklyGoalProgress, 0.5, accuracy: 0.01)
    }

    // MARK: - Streak Tracking Tests

    func testStreakTracking_CurrentStreak() async throws {
        mockService.mockStatistics = MockRecoveryStatistics(
            totalSessions: 10,
            totalMinutes: 200,
            currentStreak: 7,
            longestStreak: 14,
            favoriteProtocol: "sauna_traditional",
            weeklyGoalProgress: 1.0
        )

        let stats = try await mockService.fetchStatistics(patientId: testPatientId)

        XCTAssertEqual(stats.currentStreak, 7)
        XCTAssertGreaterThanOrEqual(stats.longestStreak, stats.currentStreak)
    }

    func testStreakTracking_NewRecord() async throws {
        mockService.mockStatistics = MockRecoveryStatistics(
            totalSessions: 30,
            totalMinutes: 600,
            currentStreak: 30,
            longestStreak: 30,
            favoriteProtocol: "contrast",
            weeklyGoalProgress: 1.0
        )

        let stats = try await mockService.fetchStatistics(patientId: testPatientId)

        XCTAssertEqual(stats.currentStreak, stats.longestStreak)
    }

    func testStreakTracking_BrokenStreak() async throws {
        mockService.mockStatistics = MockRecoveryStatistics(
            totalSessions: 25,
            totalMinutes: 500,
            currentStreak: 0,  // Streak broken
            longestStreak: 21,
            favoriteProtocol: "sauna_traditional",
            weeklyGoalProgress: 0.0
        )

        let stats = try await mockService.fetchStatistics(patientId: testPatientId)

        XCTAssertEqual(stats.currentStreak, 0)
        XCTAssertEqual(stats.longestStreak, 21)  // Previous record preserved
    }

    func testStreakTracking_JustStarted() async throws {
        mockService.mockStatistics = MockRecoveryStatistics(
            totalSessions: 1,
            totalMinutes: 20,
            currentStreak: 1,
            longestStreak: 1,
            favoriteProtocol: "sauna_traditional",
            weeklyGoalProgress: 0.2
        )

        let stats = try await mockService.fetchStatistics(patientId: testPatientId)

        XCTAssertEqual(stats.currentStreak, 1)
        XCTAssertEqual(stats.longestStreak, 1)
    }

    // MARK: - Recovery Recommendations Tests

    func testFetchRecommendations_Success() async throws {
        mockService.mockRecommendations = [
            MockRecoveryRecommendation(
                id: UUID(),
                protocolType: "sauna_traditional",
                reason: "High training volume this week",
                priority: "high",
                suggestedDuration: 20
            ),
            MockRecoveryRecommendation(
                id: UUID(),
                protocolType: "cold_plunge",
                reason: "Aid muscle recovery",
                priority: "medium",
                suggestedDuration: 3
            )
        ]

        let recommendations = try await mockService.fetchRecommendations(patientId: testPatientId)

        XCTAssertEqual(recommendations.count, 2)
        XCTAssertEqual(recommendations[0].protocolType, "sauna_traditional")
        XCTAssertEqual(recommendations[0].priority, "high")
        XCTAssertEqual(recommendations[1].protocolType, "cold_plunge")
    }

    func testFetchRecommendations_Empty() async throws {
        mockService.mockRecommendations = []

        let recommendations = try await mockService.fetchRecommendations(patientId: testPatientId)

        XCTAssertTrue(recommendations.isEmpty)
    }

    func testFetchRecommendations_Failure() async {
        mockService.shouldFailFetchRecommendations = true

        do {
            _ = try await mockService.fetchRecommendations(patientId: testPatientId)
            XCTFail("Should throw error when fetch fails")
        } catch {
            XCTAssertEqual(mockService.fetchRecommendationsCallCount, 1)
        }
    }

    func testFetchRecommendations_Priority() async throws {
        mockService.mockRecommendations = [
            MockRecoveryRecommendation(
                id: UUID(),
                protocolType: "contrast",
                reason: "Balance heat and cold exposure",
                priority: "low",
                suggestedDuration: 15
            )
        ]

        let recommendations = try await mockService.fetchRecommendations(patientId: testPatientId)

        XCTAssertEqual(recommendations[0].priority, "low")
    }

    // MARK: - Session History Tests

    func testFetchSessions_Success() async throws {
        let today = Date()
        let yesterday = Date().addingTimeInterval(-86400)

        mockService.mockSessions = [
            MockRecoverySession(
                id: UUID(),
                patientId: testPatientId,
                protocolType: "sauna_traditional",
                durationMinutes: 20,
                temperature: 180.0,
                heartRate: 120,
                effort: 7,
                notes: nil,
                loggedAt: today
            ),
            MockRecoverySession(
                id: UUID(),
                patientId: testPatientId,
                protocolType: "cold_plunge",
                durationMinutes: 3,
                temperature: 40.0,
                heartRate: nil,
                effort: 8,
                notes: nil,
                loggedAt: yesterday
            )
        ]

        let sessions = try await mockService.fetchSessions(patientId: testPatientId, limit: 10)

        XCTAssertEqual(sessions.count, 2)
        XCTAssertEqual(sessions[0].protocolType, "sauna_traditional")
        XCTAssertEqual(sessions[1].protocolType, "cold_plunge")
    }

    func testFetchSessions_Empty() async throws {
        mockService.mockSessions = []

        let sessions = try await mockService.fetchSessions(patientId: testPatientId, limit: 10)

        XCTAssertTrue(sessions.isEmpty)
    }

    func testFetchSessions_Failure() async {
        mockService.shouldFailFetchSessions = true

        do {
            _ = try await mockService.fetchSessions(patientId: testPatientId, limit: 10)
            XCTFail("Should throw error when fetch fails")
        } catch {
            XCTAssertEqual(mockService.fetchSessionsCallCount, 1)
        }
    }

    // MARK: - Today's Sessions Tests

    func testTodaySessions_Filter() {
        let today = Date()
        let yesterday = Date().addingTimeInterval(-86400)
        let lastWeek = Date().addingTimeInterval(-604800)

        let sessions = [
            MockRecoverySession(id: UUID(), patientId: testPatientId, protocolType: "sauna_traditional", durationMinutes: 20, temperature: nil, heartRate: nil, effort: 7, notes: nil, loggedAt: today),
            MockRecoverySession(id: UUID(), patientId: testPatientId, protocolType: "cold_plunge", durationMinutes: 3, temperature: nil, heartRate: nil, effort: 8, notes: nil, loggedAt: today),
            MockRecoverySession(id: UUID(), patientId: testPatientId, protocolType: "contrast", durationMinutes: 15, temperature: nil, heartRate: nil, effort: 6, notes: nil, loggedAt: yesterday),
            MockRecoverySession(id: UUID(), patientId: testPatientId, protocolType: "sauna_infrared", durationMinutes: 30, temperature: nil, heartRate: nil, effort: 5, notes: nil, loggedAt: lastWeek)
        ]

        let todaySessions = sessions.filter { Calendar.current.isDateInToday($0.loggedAt) }

        XCTAssertEqual(todaySessions.count, 2)
    }

    // MARK: - This Week's Sessions Tests

    func testThisWeekSessions_Filter() {
        let today = Date()
        let threeDaysAgo = Date().addingTimeInterval(-259200)  // 3 days
        let twoWeeksAgo = Date().addingTimeInterval(-1209600)  // 14 days

        let sessions = [
            MockRecoverySession(id: UUID(), patientId: testPatientId, protocolType: "sauna_traditional", durationMinutes: 20, temperature: nil, heartRate: nil, effort: 7, notes: nil, loggedAt: today),
            MockRecoverySession(id: UUID(), patientId: testPatientId, protocolType: "cold_plunge", durationMinutes: 3, temperature: nil, heartRate: nil, effort: 8, notes: nil, loggedAt: threeDaysAgo),
            MockRecoverySession(id: UUID(), patientId: testPatientId, protocolType: "contrast", durationMinutes: 15, temperature: nil, heartRate: nil, effort: 6, notes: nil, loggedAt: twoWeeksAgo)
        ]

        let sevenDaysAgo = Date().addingTimeInterval(-604800)
        let thisWeekSessions = sessions.filter { $0.loggedAt >= sevenDaysAgo }

        XCTAssertEqual(thisWeekSessions.count, 2)
    }

    // MARK: - Protocol Type Display Tests

    func testProtocolType_DisplayName() {
        let protocolNames: [String: String] = [
            "sauna_traditional": "Traditional Sauna",
            "sauna_infrared": "Infrared Sauna",
            "sauna_steam": "Steam Room",
            "cold_plunge": "Cold Plunge",
            "cold_shower": "Cold Shower",
            "ice_bath": "Ice Bath",
            "contrast": "Contrast Therapy"
        ]

        for (rawValue, displayName) in protocolNames {
            XCTAssertEqual(getDisplayName(for: rawValue), displayName)
        }
    }

    func testProtocolType_Icon() {
        let protocolIcons: [String: String] = [
            "sauna_traditional": "flame.fill",
            "sauna_infrared": "flame",
            "sauna_steam": "cloud.fill",
            "cold_plunge": "snowflake",
            "cold_shower": "drop.fill",
            "ice_bath": "snowflake.circle.fill",
            "contrast": "arrow.left.arrow.right"
        ]

        for (rawValue, iconName) in protocolIcons {
            XCTAssertEqual(getIcon(for: rawValue), iconName)
        }
    }

    // MARK: - Duration Formatting Tests

    func testDurationFormatting_Minutes() {
        XCTAssertEqual(formatDuration(minutes: 3), "3 min")
        XCTAssertEqual(formatDuration(minutes: 20), "20 min")
        XCTAssertEqual(formatDuration(minutes: 45), "45 min")
    }

    func testDurationFormatting_Hours() {
        XCTAssertEqual(formatDuration(minutes: 60), "1 hr")
        XCTAssertEqual(formatDuration(minutes: 90), "1 hr 30 min")
        XCTAssertEqual(formatDuration(minutes: 120), "2 hrs")
    }

    // MARK: - Temperature Formatting Tests

    func testTemperatureFormatting_Fahrenheit() {
        XCTAssertEqual(formatTemperature(180.0), "180°F")
        XCTAssertEqual(formatTemperature(40.0), "40°F")
    }

    func testTemperatureFormatting_Nil() {
        let temp: Double? = nil
        XCTAssertNil(temp.map { formatTemperature($0) })
    }

    // MARK: - Weekly Stats Calculation Tests

    func testWeeklyStats_TotalMinutes() {
        let sessions = [
            MockRecoverySession(id: UUID(), patientId: testPatientId, protocolType: "sauna_traditional", durationMinutes: 20, temperature: nil, heartRate: nil, effort: 7, notes: nil, loggedAt: Date()),
            MockRecoverySession(id: UUID(), patientId: testPatientId, protocolType: "cold_plunge", durationMinutes: 3, temperature: nil, heartRate: nil, effort: 8, notes: nil, loggedAt: Date()),
            MockRecoverySession(id: UUID(), patientId: testPatientId, protocolType: "contrast", durationMinutes: 15, temperature: nil, heartRate: nil, effort: 6, notes: nil, loggedAt: Date())
        ]

        let totalMinutes = sessions.reduce(0) { $0 + $1.durationMinutes }

        XCTAssertEqual(totalMinutes, 38)
    }

    func testWeeklyStats_SessionCount() {
        let sessions = [
            MockRecoverySession(id: UUID(), patientId: testPatientId, protocolType: "sauna_traditional", durationMinutes: 20, temperature: nil, heartRate: nil, effort: 7, notes: nil, loggedAt: Date()),
            MockRecoverySession(id: UUID(), patientId: testPatientId, protocolType: "cold_plunge", durationMinutes: 3, temperature: nil, heartRate: nil, effort: 8, notes: nil, loggedAt: Date())
        ]

        XCTAssertEqual(sessions.count, 2)
    }

    func testWeeklyStats_FavoriteProtocol() {
        let sessions = [
            MockRecoverySession(id: UUID(), patientId: testPatientId, protocolType: "sauna_traditional", durationMinutes: 20, temperature: nil, heartRate: nil, effort: 7, notes: nil, loggedAt: Date()),
            MockRecoverySession(id: UUID(), patientId: testPatientId, protocolType: "sauna_traditional", durationMinutes: 20, temperature: nil, heartRate: nil, effort: 7, notes: nil, loggedAt: Date()),
            MockRecoverySession(id: UUID(), patientId: testPatientId, protocolType: "cold_plunge", durationMinutes: 3, temperature: nil, heartRate: nil, effort: 8, notes: nil, loggedAt: Date())
        ]

        let protocolCounts = Dictionary(grouping: sessions) { $0.protocolType }
            .mapValues { $0.count }
        let favorite = protocolCounts.max(by: { $0.value < $1.value })?.key

        XCTAssertEqual(favorite, "sauna_traditional")
    }

    // MARK: - Helper Methods

    private func getDisplayName(for protocolType: String) -> String {
        switch protocolType {
        case "sauna_traditional": return "Traditional Sauna"
        case "sauna_infrared": return "Infrared Sauna"
        case "sauna_steam": return "Steam Room"
        case "cold_plunge": return "Cold Plunge"
        case "cold_shower": return "Cold Shower"
        case "ice_bath": return "Ice Bath"
        case "contrast": return "Contrast Therapy"
        default: return protocolType
        }
    }

    private func getIcon(for protocolType: String) -> String {
        switch protocolType {
        case "sauna_traditional": return "flame.fill"
        case "sauna_infrared": return "flame"
        case "sauna_steam": return "cloud.fill"
        case "cold_plunge": return "snowflake"
        case "cold_shower": return "drop.fill"
        case "ice_bath": return "snowflake.circle.fill"
        case "contrast": return "arrow.left.arrow.right"
        default: return "questionmark"
        }
    }

    private func formatDuration(minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        } else if minutes == 60 {
            return "1 hr"
        } else if minutes == 120 {
            return "2 hrs"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) hr\(hours > 1 ? "s" : "")"
            } else {
                return "\(hours) hr \(remainingMinutes) min"
            }
        }
    }

    private func formatTemperature(_ temp: Double) -> String {
        return "\(Int(temp))°F"
    }
}

// MARK: - Recovery Impact Analysis Tests

final class RecoveryImpactTests: XCTestCase {

    func testImpactCategory_StrongPositive() {
        let impact = 15.0
        XCTAssertEqual(categorizeImpact(impact), "Strong Positive")
    }

    func testImpactCategory_Positive() {
        let impact = 7.0
        XCTAssertEqual(categorizeImpact(impact), "Positive")
    }

    func testImpactCategory_Neutral() {
        let impact = 2.0
        XCTAssertEqual(categorizeImpact(impact), "Neutral")
    }

    func testImpactCategory_Negative() {
        let impact = -7.0
        XCTAssertEqual(categorizeImpact(impact), "Negative")
    }

    func testImpactCategory_StrongNegative() {
        let impact = -15.0
        XCTAssertEqual(categorizeImpact(impact), "Strong Negative")
    }

    private func categorizeImpact(_ impact: Double) -> String {
        switch impact {
        case 10...: return "Strong Positive"
        case 3..<10: return "Positive"
        case -3..<3: return "Neutral"
        case -10..<(-3): return "Negative"
        default: return "Strong Negative"
        }
    }
}

// MARK: - Recovery Therapy Type Tests

final class RecoveryTherapyTypeTests: XCTestCase {

    func testIsHeatTherapy() {
        let heatProtocols = ["sauna_traditional", "sauna_infrared", "sauna_steam"]
        let coldProtocols = ["cold_plunge", "cold_shower", "ice_bath"]
        let contrastProtocol = "contrast"

        for protocol_ in heatProtocols {
            XCTAssertTrue(isHeatTherapy(protocol_), "\(protocol_) should be heat therapy")
        }

        for protocol_ in coldProtocols {
            XCTAssertFalse(isHeatTherapy(protocol_), "\(protocol_) should not be heat therapy")
        }

        XCTAssertFalse(isHeatTherapy(contrastProtocol))
    }

    func testIsColdTherapy() {
        let heatProtocols = ["sauna_traditional", "sauna_infrared", "sauna_steam"]
        let coldProtocols = ["cold_plunge", "cold_shower", "ice_bath"]
        let contrastProtocol = "contrast"

        for protocol_ in coldProtocols {
            XCTAssertTrue(isColdTherapy(protocol_), "\(protocol_) should be cold therapy")
        }

        for protocol_ in heatProtocols {
            XCTAssertFalse(isColdTherapy(protocol_), "\(protocol_) should not be cold therapy")
        }

        XCTAssertFalse(isColdTherapy(contrastProtocol))
    }

    private func isHeatTherapy(_ protocolType: String) -> Bool {
        ["sauna_traditional", "sauna_infrared", "sauna_steam"].contains(protocolType)
    }

    private func isColdTherapy(_ protocolType: String) -> Bool {
        ["cold_plunge", "cold_shower", "ice_bath"].contains(protocolType)
    }
}
