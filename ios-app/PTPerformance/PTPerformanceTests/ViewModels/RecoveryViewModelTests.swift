//
//  RecoveryViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for RecoveryViewModel
//  Tests initial state, computed properties, form state, and session filtering
//

import XCTest
@testable import PTPerformance

@MainActor
final class RecoveryViewModelTests: XCTestCase {

    var sut: RecoveryViewModel!

    override func setUp() {
        super.setUp()
        sut = RecoveryViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_SessionsIsEmpty() {
        XCTAssertTrue(sut.sessions.isEmpty, "sessions should be empty initially")
    }

    func testInitialState_RecommendationsIsEmpty() {
        XCTAssertTrue(sut.recommendations.isEmpty, "recommendations should be empty initially")
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading, "isLoading should be false initially")
    }

    func testInitialState_ErrorIsNil() {
        XCTAssertNil(sut.error, "error should be nil initially")
    }

    func testInitialState_ShowingLogSheetIsFalse() {
        XCTAssertFalse(sut.showingLogSheet, "showingLogSheet should be false initially")
    }

    func testInitialState_SelectedProtocolIsSauna() {
        XCTAssertEqual(sut.selectedProtocol, .sauna, "selectedProtocol should be .sauna initially")
    }

    // MARK: - Form State Initial Values

    func testInitialState_LogDurationIs15() {
        XCTAssertEqual(sut.logDuration, 15, "logDuration should be 15 initially")
    }

    func testInitialState_LogTemperatureIsNil() {
        XCTAssertNil(sut.logTemperature, "logTemperature should be nil initially")
    }

    func testInitialState_LogHeartRateIsNil() {
        XCTAssertNil(sut.logHeartRate, "logHeartRate should be nil initially")
    }

    func testInitialState_LogEffortIs5() {
        XCTAssertEqual(sut.logEffort, 5, "logEffort should be 5 initially")
    }

    func testInitialState_LogNotesIsEmpty() {
        XCTAssertEqual(sut.logNotes, "", "logNotes should be empty initially")
    }

    // MARK: - Computed Properties Tests - todaySessions

    func testTodaySessions_WhenEmpty_ReturnsEmpty() {
        sut.sessions = []
        XCTAssertTrue(sut.todaySessions.isEmpty, "todaySessions should be empty when sessions is empty")
    }

    func testTodaySessions_FiltersTodayOnly() {
        let todaySession = createMockSession(protocolType: .sauna, startTime: Date())
        let yesterdaySession = createMockSession(protocolType: .coldPlunge, startTime: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
        let lastWeekSession = createMockSession(protocolType: .massage, startTime: Calendar.current.date(byAdding: .day, value: -7, to: Date())!)

        sut.sessions = [todaySession, yesterdaySession, lastWeekSession]

        XCTAssertEqual(sut.todaySessions.count, 1, "todaySessions should only include today's sessions")
        XCTAssertEqual(sut.todaySessions.first?.id, todaySession.id, "todaySessions should contain the correct session")
    }

    func testTodaySessions_MultipleTodaySessions() {
        let session1 = createMockSession(protocolType: .sauna, startTime: Date())
        let session2 = createMockSession(protocolType: .coldPlunge, startTime: Date())

        sut.sessions = [session1, session2]

        XCTAssertEqual(sut.todaySessions.count, 2, "todaySessions should include all sessions from today")
    }

    // MARK: - Computed Properties Tests - thisWeekSessions

    func testThisWeekSessions_WhenEmpty_ReturnsEmpty() {
        sut.sessions = []
        XCTAssertTrue(sut.thisWeekSessions.isEmpty, "thisWeekSessions should be empty when sessions is empty")
    }

    func testThisWeekSessions_FiltersLast7Days() {
        let todaySession = createMockSession(protocolType: .sauna, startTime: Date())
        let threeDaysAgo = createMockSession(protocolType: .coldPlunge, startTime: Calendar.current.date(byAdding: .day, value: -3, to: Date())!)
        let sixDaysAgo = createMockSession(protocolType: .massage, startTime: Calendar.current.date(byAdding: .day, value: -6, to: Date())!)
        let eightDaysAgo = createMockSession(protocolType: .stretching, startTime: Calendar.current.date(byAdding: .day, value: -8, to: Date())!)

        sut.sessions = [todaySession, threeDaysAgo, sixDaysAgo, eightDaysAgo]

        XCTAssertEqual(sut.thisWeekSessions.count, 3, "thisWeekSessions should include sessions from last 7 days")
        XCTAssertFalse(sut.thisWeekSessions.contains(where: { $0.id == eightDaysAgo.id }), "thisWeekSessions should not include sessions older than 7 days")
    }

    // MARK: - Computed Properties Tests - sessionsForProtocol

    func testSessionsForProtocol_WhenEmpty_ReturnsEmpty() {
        sut.sessions = []
        XCTAssertTrue(sut.sessionsForProtocol(.sauna).isEmpty, "sessionsForProtocol should be empty when sessions is empty")
    }

    func testSessionsForProtocol_FiltersByType() {
        let saunaSession1 = createMockSession(protocolType: .sauna, startTime: Date())
        let saunaSession2 = createMockSession(protocolType: .sauna, startTime: Date())
        let coldPlungeSession = createMockSession(protocolType: .coldPlunge, startTime: Date())
        let massageSession = createMockSession(protocolType: .massage, startTime: Date())

        sut.sessions = [saunaSession1, saunaSession2, coldPlungeSession, massageSession]

        let saunaSessions = sut.sessionsForProtocol(.sauna)
        XCTAssertEqual(saunaSessions.count, 2, "Should return 2 sauna sessions")

        let coldPlungeSessions = sut.sessionsForProtocol(.coldPlunge)
        XCTAssertEqual(coldPlungeSessions.count, 1, "Should return 1 cold plunge session")

        let stretchingSessions = sut.sessionsForProtocol(.stretching)
        XCTAssertTrue(stretchingSessions.isEmpty, "Should return empty for protocol with no sessions")
    }

    // MARK: - Form State Tests

    func testSelectedProtocol_CanBeChanged() {
        XCTAssertEqual(sut.selectedProtocol, .sauna)

        sut.selectedProtocol = .coldPlunge
        XCTAssertEqual(sut.selectedProtocol, .coldPlunge, "selectedProtocol should be changeable")

        sut.selectedProtocol = .meditation
        XCTAssertEqual(sut.selectedProtocol, .meditation, "selectedProtocol should be changeable to any protocol type")
    }

    func testLogDuration_CanBeSet() {
        sut.logDuration = 30
        XCTAssertEqual(sut.logDuration, 30, "logDuration should be settable")
    }

    func testLogTemperature_CanBeSet() {
        sut.logTemperature = 180.0
        XCTAssertEqual(sut.logTemperature, 180.0, "logTemperature should be settable")
    }

    func testLogHeartRate_CanBeSet() {
        sut.logHeartRate = 120
        XCTAssertEqual(sut.logHeartRate, 120, "logHeartRate should be settable")
    }

    func testLogEffort_CanBeSet() {
        sut.logEffort = 8
        XCTAssertEqual(sut.logEffort, 8, "logEffort should be settable")
    }

    func testLogNotes_CanBeSet() {
        sut.logNotes = "Great session"
        XCTAssertEqual(sut.logNotes, "Great session", "logNotes should be settable")
    }

    // MARK: - Sheet State Tests

    func testShowingLogSheet_CanBeToggled() {
        XCTAssertFalse(sut.showingLogSheet)

        sut.showingLogSheet = true
        XCTAssertTrue(sut.showingLogSheet, "showingLogSheet should be togglable to true")

        sut.showingLogSheet = false
        XCTAssertFalse(sut.showingLogSheet, "showingLogSheet should be togglable to false")
    }

    // MARK: - Error State Tests

    func testError_CanBeSet() {
        XCTAssertNil(sut.error)

        sut.error = "Failed to load sessions"
        XCTAssertEqual(sut.error, "Failed to load sessions", "error should be settable")

        sut.error = nil
        XCTAssertNil(sut.error, "error should be clearable")
    }

    // MARK: - Loading State Tests

    func testIsLoading_CanBeSet() {
        XCTAssertFalse(sut.isLoading)

        sut.isLoading = true
        XCTAssertTrue(sut.isLoading, "isLoading should be settable to true")

        sut.isLoading = false
        XCTAssertFalse(sut.isLoading, "isLoading should be settable to false")
    }

    // MARK: - RecoveryProtocolType Tests

    func testRecoveryProtocolType_AllCasesHaveDisplayName() {
        for protocolType in RecoveryProtocolType.allCases {
            XCTAssertFalse(protocolType.displayName.isEmpty, "Protocol type \(protocolType) should have a display name")
        }
    }

    func testRecoveryProtocolType_AllCasesHaveIcon() {
        for protocolType in RecoveryProtocolType.allCases {
            XCTAssertFalse(protocolType.icon.isEmpty, "Protocol type \(protocolType) should have an icon")
        }
    }

    func testRecoveryProtocolType_DisplayNames() {
        XCTAssertEqual(RecoveryProtocolType.sauna.displayName, "Sauna")
        XCTAssertEqual(RecoveryProtocolType.coldPlunge.displayName, "Cold Plunge")
        XCTAssertEqual(RecoveryProtocolType.contrast.displayName, "Contrast Therapy")
        XCTAssertEqual(RecoveryProtocolType.cryotherapy.displayName, "Cryotherapy")
        XCTAssertEqual(RecoveryProtocolType.floatTank.displayName, "Float Tank")
        XCTAssertEqual(RecoveryProtocolType.massage.displayName, "Massage")
        XCTAssertEqual(RecoveryProtocolType.stretching.displayName, "Stretching")
        XCTAssertEqual(RecoveryProtocolType.meditation.displayName, "Meditation")
    }

    func testRecoveryProtocolType_Icons() {
        XCTAssertEqual(RecoveryProtocolType.sauna.icon, "flame.fill")
        XCTAssertEqual(RecoveryProtocolType.coldPlunge.icon, "snowflake")
        XCTAssertEqual(RecoveryProtocolType.contrast.icon, "arrow.left.arrow.right")
        XCTAssertEqual(RecoveryProtocolType.meditation.icon, "brain.head.profile")
    }

    // MARK: - RecoveryPriority Tests

    func testRecoveryPriority_AllCasesExist() {
        let allPriorities: [RecoveryPriority] = [.high, .medium, .low]
        for priority in allPriorities {
            XCTAssertNotNil(priority.rawValue, "Priority \(priority) should have a raw value")
        }
    }

    // MARK: - Edge Cases

    func testSessions_CanBeCleared() {
        let session = createMockSession(protocolType: .sauna, startTime: Date())
        sut.sessions = [session]

        XCTAssertFalse(sut.sessions.isEmpty)

        sut.sessions = []
        XCTAssertTrue(sut.sessions.isEmpty, "sessions should be clearable")
    }

    func testRecommendations_CanBeSet() {
        let recommendation = createMockRecommendation(protocolType: .sauna, priority: .high)
        sut.recommendations = [recommendation]

        XCTAssertEqual(sut.recommendations.count, 1, "recommendations should be settable")
        XCTAssertEqual(sut.recommendations.first?.id, recommendation.id)
    }

    // MARK: - Helper Methods

    private func createMockSession(protocolType: RecoveryProtocolType, startTime: Date) -> RecoverySession {
        return RecoverySession(
            id: UUID(),
            patientId: UUID(),
            protocolType: protocolType,
            startTime: startTime,
            duration: 900, // 15 minutes
            temperature: nil,
            heartRateAvg: nil,
            heartRateMax: nil,
            perceivedEffort: 5,
            notes: nil,
            createdAt: Date()
        )
    }

    private func createMockRecommendation(protocolType: RecoveryProtocolType, priority: RecoveryPriority) -> RecoveryRecommendation {
        return RecoveryRecommendation(
            id: UUID(),
            protocolType: protocolType,
            reason: "Recommended based on training load",
            priority: priority,
            suggestedDuration: 15
        )
    }
}
