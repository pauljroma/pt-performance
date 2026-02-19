//
//  AchievementLeaderboardTests.swift
//  PTPerformanceTests
//
//  Tests for AchievementLeaderboardView and LeaderboardViewModel
//

import XCTest
@testable import PTPerformance

// MARK: - LeaderboardTimeFilter Tests

final class LeaderboardTimeFilterTests: XCTestCase {

    func testLeaderboardTimeFilter_AllCases() {
        let allCases = LeaderboardTimeFilter.allCases

        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.weekly))
        XCTAssertTrue(allCases.contains(.monthly))
        XCTAssertTrue(allCases.contains(.allTime))
    }

    func testLeaderboardTimeFilter_RawValues() {
        XCTAssertEqual(LeaderboardTimeFilter.weekly.rawValue, "weekly")
        XCTAssertEqual(LeaderboardTimeFilter.monthly.rawValue, "monthly")
        XCTAssertEqual(LeaderboardTimeFilter.allTime.rawValue, "all_time")
    }

    func testLeaderboardTimeFilter_DisplayNames() {
        XCTAssertEqual(LeaderboardTimeFilter.weekly.displayName, "This Week")
        XCTAssertEqual(LeaderboardTimeFilter.monthly.displayName, "This Month")
        XCTAssertEqual(LeaderboardTimeFilter.allTime.displayName, "All Time")
    }

    func testLeaderboardTimeFilter_Icons() {
        XCTAssertEqual(LeaderboardTimeFilter.weekly.icon, "calendar.badge.clock")
        XCTAssertEqual(LeaderboardTimeFilter.monthly.icon, "calendar")
        XCTAssertEqual(LeaderboardTimeFilter.allTime.icon, "star.fill")
    }

    func testLeaderboardTimeFilter_Identifiable() {
        let filter = LeaderboardTimeFilter.weekly

        XCTAssertEqual(filter.id, filter.rawValue)
    }
}

// MARK: - AchievementLeaderboardEntry Tests

final class AchievementLeaderboardEntryTests: XCTestCase {

    func testLeaderboardEntry_Initialization() {
        let entry = AchievementLeaderboardEntry(
            id: UUID(),
            rank: 1,
            displayName: "Test User",
            avatarInitials: "TU",
            totalPoints: 500,
            achievementCount: 15,
            isCurrentUser: false,
            isOptedIn: true
        )

        XCTAssertEqual(entry.rank, 1)
        XCTAssertEqual(entry.displayName, "Test User")
        XCTAssertEqual(entry.avatarInitials, "TU")
        XCTAssertEqual(entry.totalPoints, 500)
        XCTAssertEqual(entry.achievementCount, 15)
        XCTAssertFalse(entry.isCurrentUser)
        XCTAssertTrue(entry.isOptedIn)
    }

    // MARK: - displayNameFormatted Tests

    func testDisplayNameFormatted_CurrentUser() {
        let entry = AchievementLeaderboardEntry(
            id: UUID(),
            rank: 5,
            displayName: "John Doe",
            avatarInitials: "JD",
            totalPoints: 300,
            achievementCount: 10,
            isCurrentUser: true,
            isOptedIn: true
        )

        XCTAssertEqual(entry.displayNameFormatted, "You")
    }

    func testDisplayNameFormatted_OptedInUser() {
        let entry = AchievementLeaderboardEntry(
            id: UUID(),
            rank: 3,
            displayName: "Jane Smith",
            avatarInitials: "JS",
            totalPoints: 400,
            achievementCount: 12,
            isCurrentUser: false,
            isOptedIn: true
        )

        XCTAssertEqual(entry.displayNameFormatted, "Jane Smith")
    }

    func testDisplayNameFormatted_NotOptedIn() {
        let entry = AchievementLeaderboardEntry(
            id: UUID(),
            rank: 7,
            displayName: "Hidden User",
            avatarInitials: "HU",
            totalPoints: 200,
            achievementCount: 8,
            isCurrentUser: false,
            isOptedIn: false
        )

        XCTAssertEqual(entry.displayNameFormatted, "Patient 7")
    }

    // MARK: - Equatable Tests

    func testLeaderboardEntry_Equatable() {
        let id = UUID()
        let entry1 = AchievementLeaderboardEntry(
            id: id,
            rank: 1,
            displayName: "User",
            avatarInitials: "U",
            totalPoints: 100,
            achievementCount: 5,
            isCurrentUser: false,
            isOptedIn: true
        )
        let entry2 = AchievementLeaderboardEntry(
            id: id,
            rank: 1,
            displayName: "User",
            avatarInitials: "U",
            totalPoints: 100,
            achievementCount: 5,
            isCurrentUser: false,
            isOptedIn: true
        )

        XCTAssertEqual(entry1, entry2)
    }

    func testLeaderboardEntry_NotEquatable() {
        let entry1 = AchievementLeaderboardEntry(
            id: UUID(),
            rank: 1,
            displayName: "User1",
            avatarInitials: "U1",
            totalPoints: 100,
            achievementCount: 5,
            isCurrentUser: false,
            isOptedIn: true
        )
        let entry2 = AchievementLeaderboardEntry(
            id: UUID(),
            rank: 2,
            displayName: "User2",
            avatarInitials: "U2",
            totalPoints: 200,
            achievementCount: 7,
            isCurrentUser: false,
            isOptedIn: true
        )

        XCTAssertNotEqual(entry1, entry2)
    }
}

// MARK: - LeaderboardViewModel Tests

@MainActor
final class LeaderboardViewModelTests: XCTestCase {

    func testLeaderboardViewModel_InitialState() {
        let viewModel = LeaderboardViewModel()

        XCTAssertTrue(viewModel.entries.isEmpty)
        XCTAssertNil(viewModel.currentUserEntry)
        XCTAssertEqual(viewModel.selectedFilter, .weekly)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }

    func testLeaderboardViewModel_FilterChange() {
        let viewModel = LeaderboardViewModel()

        viewModel.selectedFilter = .monthly
        XCTAssertEqual(viewModel.selectedFilter, .monthly)

        viewModel.selectedFilter = .allTime
        XCTAssertEqual(viewModel.selectedFilter, .allTime)
    }
}

// MARK: - Sample Data Tests

final class AchievementLeaderboardSampleDataTests: XCTestCase {

    func testSampleEntries_HasEntries() {
        let samples = AchievementLeaderboardEntry.sampleEntries

        XCTAssertFalse(samples.isEmpty)
        XCTAssertGreaterThanOrEqual(samples.count, 5)
    }

    func testSampleEntries_HasCurrentUser() {
        let samples = AchievementLeaderboardEntry.sampleEntries

        let currentUser = samples.first { $0.isCurrentUser }
        XCTAssertNotNil(currentUser)
    }

    func testSampleEntries_RanksAreSequential() {
        let samples = AchievementLeaderboardEntry.sampleEntries

        for (index, entry) in samples.enumerated() {
            XCTAssertEqual(entry.rank, index + 1)
        }
    }

    func testSampleEntries_PointsAreDescending() {
        let samples = AchievementLeaderboardEntry.sampleEntries

        for i in 0..<(samples.count - 1) {
            XCTAssertGreaterThanOrEqual(
                samples[i].totalPoints,
                samples[i + 1].totalPoints,
                "Points should be in descending order"
            )
        }
    }

    func testSampleEntries_HasVariedOptInStatus() {
        let samples = AchievementLeaderboardEntry.sampleEntries

        let optedIn = samples.filter { $0.isOptedIn }
        let notOptedIn = samples.filter { !$0.isOptedIn }

        // Should have both opted-in and not opted-in users
        XCTAssertFalse(optedIn.isEmpty)
        XCTAssertFalse(notOptedIn.isEmpty)
    }
}
