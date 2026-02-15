//
//  LeaderboardService.swift
//  PTPerformance
//
//  ACP-997: Leaderboard & Competition
//  Service for fetching, caching, and managing leaderboard data
//

import SwiftUI
import Combine

// MARK: - Leaderboard Type

/// Categories of leaderboard rankings
enum LeaderboardType: String, CaseIterable, Identifiable {
    case weeklyWorkouts = "weekly_workouts"
    case longestStreak = "longest_streak"
    case totalVolume = "total_volume"
    case consistency = "consistency"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weeklyWorkouts: return "Weekly Workouts"
        case .longestStreak: return "Longest Streak"
        case .totalVolume: return "Total Volume"
        case .consistency: return "Consistency"
        }
    }

    var iconName: String {
        switch self {
        case .weeklyWorkouts: return "figure.strengthtraining.traditional"
        case .longestStreak: return "flame.fill"
        case .totalVolume: return "scalemass.fill"
        case .consistency: return "calendar.badge.checkmark"
        }
    }

    var scoreUnit: String {
        switch self {
        case .weeklyWorkouts: return "workouts"
        case .longestStreak: return "days"
        case .totalVolume: return "lbs"
        case .consistency: return "%"
        }
    }

    var scoreSuffix: String {
        switch self {
        case .weeklyWorkouts: return ""
        case .longestStreak: return "d"
        case .totalVolume: return " lbs"
        case .consistency: return "%"
        }
    }
}

// MARK: - Leaderboard Time Period

/// Time period for leaderboard filtering
enum LeaderboardPeriod: String, CaseIterable, Identifiable {
    case weekly = "weekly"
    case allTime = "all_time"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weekly: return "This Week"
        case .allTime: return "All Time"
        }
    }
}

// MARK: - Leaderboard Entry

/// A single entry in the leaderboard
struct LeaderboardEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let rank: Int
    let userId: UUID
    let displayName: String
    let avatarURL: String?
    let score: Double
    let streak: Int
    let isCurrentUser: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case rank
        case userId = "user_id"
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case score
        case streak
        case isCurrentUser = "is_current_user"
    }

    /// Initialize with default values for convenience
    init(
        id: UUID = UUID(),
        rank: Int,
        userId: UUID,
        displayName: String,
        avatarURL: String? = nil,
        score: Double,
        streak: Int = 0,
        isCurrentUser: Bool = false
    ) {
        self.id = id
        self.rank = rank
        self.userId = userId
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.score = score
        self.streak = streak
        self.isCurrentUser = isCurrentUser
    }

    /// Formatted score string for display
    func formattedScore(for type: LeaderboardType) -> String {
        switch type {
        case .weeklyWorkouts:
            return "\(Int(score))"
        case .longestStreak:
            return "\(Int(score))d"
        case .totalVolume:
            if score >= 1_000_000 {
                return String(format: "%.1fM", score / 1_000_000)
            } else if score >= 1000 {
                return String(format: "%.1fk", score / 1000)
            }
            return String(format: "%.0f", score)
        case .consistency:
            return String(format: "%.0f%%", score)
        }
    }

    /// Medal color for top 3 ranks
    var medalColor: Color? {
        switch rank {
        case 1: return .yellow
        case 2: return Color(red: 192/255, green: 192/255, blue: 192/255)
        case 3: return Color(red: 205/255, green: 127/255, blue: 50/255)
        default: return nil
        }
    }

    /// Medal icon for top 3
    var medalIcon: String? {
        switch rank {
        case 1: return "medal.fill"
        case 2: return "medal.fill"
        case 3: return "medal.fill"
        default: return nil
        }
    }
}

// MARK: - Leaderboard Service

/// Service for managing leaderboard data with caching and refresh
@MainActor
class LeaderboardService: ObservableObject {

    // MARK: - Singleton

    static let shared = LeaderboardService()

    // MARK: - Published Properties

    /// Weekly leaderboard entries
    @Published var weeklyLeaderboard: [LeaderboardEntry] = []

    /// All-time leaderboard entries
    @Published var allTimeLeaderboard: [LeaderboardEntry] = []

    /// Currently selected leaderboard type
    @Published var selectedType: LeaderboardType = .weeklyWorkouts

    /// Currently selected time period
    @Published var selectedPeriod: LeaderboardPeriod = .weekly

    /// Loading state
    @Published var isLoading = false

    /// Error state
    @Published var error: Error?

    /// Current user's entry (for pinned display)
    @Published var currentUserEntry: LeaderboardEntry?

    /// Last refresh timestamp
    @Published var lastRefreshed: Date?

    // MARK: - Private Properties

    private let client: PTSupabaseClient
    private let logger = DebugLogger.shared
    private var patientId: UUID?

    /// Local cache for leaderboard data
    private var cache: [String: (entries: [LeaderboardEntry], timestamp: Date)] = [:]
    private let cacheExpiry: TimeInterval = 300 // 5 minutes

    // MARK: - Computed Properties

    /// The active leaderboard based on selected period
    var activeLeaderboard: [LeaderboardEntry] {
        switch selectedPeriod {
        case .weekly: return weeklyLeaderboard
        case .allTime: return allTimeLeaderboard
        }
    }

    /// Top 3 entries from the active leaderboard
    var podiumEntries: [LeaderboardEntry] {
        Array(activeLeaderboard.prefix(3))
    }

    /// Entries below the top 3
    var remainingEntries: [LeaderboardEntry] {
        Array(activeLeaderboard.dropFirst(3))
    }

    /// Whether the current user is in the visible list
    var isCurrentUserVisible: Bool {
        activeLeaderboard.contains { $0.isCurrentUser }
    }

    // MARK: - Initialization

    nonisolated init(client: PTSupabaseClient = .shared) {
        self.client = client
    }

    // MARK: - Public Methods

    /// Initialize the leaderboard service for a user
    func initialize(for patientId: UUID) async {
        self.patientId = patientId
        logger.info("Leaderboard", "Initializing leaderboard for patient: \(patientId)")
        await refreshLeaderboard()
    }

    /// Refresh the leaderboard data
    func refreshLeaderboard() async {
        logger.info("Leaderboard", "Refreshing leaderboard: \(selectedType.displayName) / \(selectedPeriod.displayName)")

        isLoading = true
        defer { isLoading = false }

        // Check cache first
        let cacheKey = "\(selectedType.rawValue)_\(selectedPeriod.rawValue)"
        if let cached = cache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < cacheExpiry {
            logger.diagnostic("[Leaderboard] Using cached data for \(cacheKey)")
            applyEntries(cached.entries)
            return
        }

        do {
            guard let patientId = patientId else {
                logger.warning("Leaderboard", "No patient ID set")
                return
            }

            // Fetch from Supabase RPC
            let entries: [LeaderboardEntry] = try await client.client
                .rpc("get_leaderboard", params: [
                    "p_type": selectedType.rawValue,
                    "p_period": selectedPeriod.rawValue,
                    "p_patient_id": patientId.uuidString,
                    "p_limit": "50"
                ])
                .execute()
                .value

            // Cache the result
            cache[cacheKey] = (entries: entries, timestamp: Date())

            applyEntries(entries)
            lastRefreshed = Date()

            logger.success("Leaderboard", "Loaded \(entries.count) leaderboard entries")
        } catch {
            if error.isCancellation { return }
            self.error = error
            logger.error("Leaderboard", "Failed to load leaderboard: \(error.localizedDescription)")
        }
    }

    /// Change the leaderboard type and refresh
    func selectType(_ type: LeaderboardType) async {
        guard type != selectedType else { return }
        selectedType = type
        HapticFeedback.selectionChanged()
        logger.info("Leaderboard", "Selected leaderboard type: \(type.displayName)")
        await refreshLeaderboard()
    }

    /// Change the time period and refresh
    func selectPeriod(_ period: LeaderboardPeriod) async {
        guard period != selectedPeriod else { return }
        selectedPeriod = period
        HapticFeedback.selectionChanged()
        logger.info("Leaderboard", "Selected leaderboard period: \(period.displayName)")
        await refreshLeaderboard()
    }

    /// Clear the cache and force a fresh fetch
    func invalidateCache() {
        cache.removeAll()
        logger.info("Leaderboard", "Cache invalidated")
    }

    // MARK: - Private Methods

    /// Apply fetched entries to the appropriate published properties
    private func applyEntries(_ entries: [LeaderboardEntry]) {
        switch selectedPeriod {
        case .weekly:
            weeklyLeaderboard = entries
        case .allTime:
            allTimeLeaderboard = entries
        }

        // Find current user's entry
        currentUserEntry = entries.first { $0.isCurrentUser }
    }
}
