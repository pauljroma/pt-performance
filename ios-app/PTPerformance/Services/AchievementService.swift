//
//  AchievementService.swift
//  PTPerformance
//
//  Gamification Polish - Milestone Celebrations & Achievements
//  Service for tracking achievements, checking unlocks, and triggering celebrations
//

import SwiftUI
import Combine

// MARK: - Achievement Service

/// Service for managing achievement tracking, unlocking, and celebrations
@MainActor
class AchievementService: ObservableObject {

    // MARK: - Singleton

    static let shared = AchievementService()

    // MARK: - Published Properties

    @Published var unlockedAchievements: [UnlockedAchievement] = []
    @Published var achievementProgress: [AchievementProgress] = []
    @Published var recentUnlocks: [AchievementUnlockEvent] = []
    @Published var isLoading = false
    @Published var error: Error?

    /// Total achievement points earned
    @Published var totalPoints: Int = 0

    /// Pending celebration to show
    @Published var pendingCelebration: AchievementUnlockEvent?

    /// Pending streak milestone celebration
    @Published var pendingStreakMilestone: StreakMilestone?

    /// Pending PR celebration
    @Published var pendingPRCelebration: PRCelebrationData?

    // MARK: - Private Properties

    private let client: PTSupabaseClient
    private let logger = DebugLogger.shared
    private var patientId: UUID?

    // UserDefaults keys for local caching
    private let unlockedAchievementsKey = "unlocked_achievements"
    private let lastSyncKey = "achievements_last_sync"

    // MARK: - Initialization

    nonisolated init(client: PTSupabaseClient = .shared) {
        self.client = client
    }

    // MARK: - Public Methods

    /// Initialize service for a patient
    func initialize(for patientId: UUID) async {
        self.patientId = patientId
        await loadAchievements()
        await checkAllAchievements()
    }

    /// Load unlocked achievements from storage/server
    func loadAchievements() async {
        guard let patientId = patientId else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            // Try to fetch from server
            let response = try await client.client
                .from("patient_achievements")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                return try Self.parseDate(dateString)
            }

            let achievements = try decoder.decode([UnlockedAchievement].self, from: response.data)
            self.unlockedAchievements = achievements

            // Calculate progress for all achievements
            await calculateAllProgress()

            // Calculate total points
            calculateTotalPoints()

            logger.log("AchievementService: Loaded \(achievements.count) unlocked achievements", level: .success)
        } catch {
            logger.log("AchievementService: Error loading achievements: \(error)", level: .warning)
            // Load from local cache if server fails
            loadFromCache()
        }
    }

    /// Check all achievement conditions and unlock any that are met
    func checkAllAchievements() async {
        guard let patientId = patientId else { return }

        // Fetch current stats
        let stats = await fetchPatientStats(patientId: patientId)

        // Check streak achievements
        await checkStreakAchievements(currentStreak: stats.currentStreak, longestStreak: stats.longestStreak)

        // Check workout count achievements
        await checkWorkoutAchievements(completedWorkouts: stats.completedWorkouts)

        // Check PR achievements
        await checkPRAchievements(prCount: stats.prCount)

        // Check volume achievements
        await checkVolumeAchievements(totalVolume: stats.totalVolume)
    }

    /// Check if a specific achievement should be unlocked
    func checkAchievement(_ definition: AchievementDefinition, currentValue: Int) async -> Bool {
        // Already unlocked?
        if isUnlocked(definition.id) {
            return false
        }

        // Check if requirement is met
        if currentValue >= definition.requirement {
            await unlockAchievement(definition, currentValue: currentValue)
            return true
        }

        return false
    }

    /// Unlock an achievement
    func unlockAchievement(_ definition: AchievementDefinition, currentValue: Int) async {
        guard let patientId = patientId else { return }
        guard !isUnlocked(definition.id) else { return }

        let unlocked = UnlockedAchievement(
            achievementId: definition.id,
            patientId: patientId,
            unlockedAt: Date(),
            currentValue: currentValue
        )

        // Save to server
        do {
            try await client.client
                .from("patient_achievements")
                .insert(unlocked)
                .execute()

            logger.log("AchievementService: Unlocked achievement: \(definition.title)", level: .success)
        } catch {
            logger.log("AchievementService: Failed to save achievement: \(error)", level: .warning)
        }

        // Update local state
        unlockedAchievements.append(unlocked)
        saveToCache()

        // Create unlock event
        let event = AchievementUnlockEvent(
            achievement: definition,
            previousValue: currentValue - 1,
            newValue: currentValue
        )
        recentUnlocks.insert(event, at: 0)

        // Trigger celebration
        pendingCelebration = event

        // Haptic feedback
        HapticFeedback.success()

        // Recalculate points
        calculateTotalPoints()
    }

    /// Check if an achievement is unlocked
    func isUnlocked(_ achievementId: String) -> Bool {
        unlockedAchievements.contains { $0.achievementId == achievementId }
    }

    /// Get progress for an achievement
    func getProgress(for definition: AchievementDefinition) -> AchievementProgress? {
        achievementProgress.first { $0.definition.id == definition.id }
    }

    /// Trigger a streak milestone celebration
    func triggerStreakMilestone(_ streak: Int) {
        if let milestone = StreakMilestone.milestone(for: streak) {
            pendingStreakMilestone = milestone
            HapticFeedback.success()
            logger.log("AchievementService: Streak milestone reached: \(milestone.displayName)", level: .success)
        }
    }

    /// Trigger a PR celebration
    func triggerPRCelebration(exerciseName: String, newWeight: Double, previousWeight: Double?, unit: String) {
        let celebrationType: PRCelebrationType
        let improvement: Double?

        if let prev = previousWeight {
            improvement = newWeight - prev
            let improvementPercent = (improvement ?? 0) / prev * 100

            // Check for milestone weights
            let milestoneWeights: [Double] = [100, 135, 185, 225, 275, 315, 365, 405, 495, 500]
            if milestoneWeights.contains(newWeight) {
                celebrationType = .milestonePR
            } else if improvementPercent >= 10 {
                celebrationType = .majorPR
            } else {
                celebrationType = .newPR
            }
        } else {
            celebrationType = .firstPR
            improvement = nil
        }

        pendingPRCelebration = PRCelebrationData(
            exerciseName: exerciseName,
            newWeight: newWeight,
            previousWeight: previousWeight,
            improvement: improvement,
            unit: unit,
            type: celebrationType
        )

        HapticFeedback.success()
        logger.log("AchievementService: PR celebration triggered for \(exerciseName): \(newWeight) \(unit)", level: .success)
    }

    /// Clear pending celebration
    func clearPendingCelebration() {
        pendingCelebration = nil
    }

    /// Clear pending streak milestone
    func clearStreakMilestone() {
        pendingStreakMilestone = nil
    }

    /// Clear pending PR celebration
    func clearPRCelebration() {
        pendingPRCelebration = nil
    }

    /// Share achievement
    func shareAchievement(_ achievement: AchievementDefinition) -> String {
        let shareText = """
        I just unlocked the "\(achievement.title)" achievement in Modus!

        \(achievement.description)

        #Modus #FitnessGoals #Achievement
        """
        return shareText
    }

    // MARK: - Private Methods

    private func checkStreakAchievements(currentStreak: Int, longestStreak: Int) async {
        let streakValue = max(currentStreak, longestStreak)

        _ = await checkAchievement(AchievementCatalog.streak7Day, currentValue: streakValue)
        _ = await checkAchievement(AchievementCatalog.streak14Day, currentValue: streakValue)
        _ = await checkAchievement(AchievementCatalog.streak30Day, currentValue: streakValue)
        _ = await checkAchievement(AchievementCatalog.streak60Day, currentValue: streakValue)
        _ = await checkAchievement(AchievementCatalog.streak100Day, currentValue: streakValue)
    }

    private func checkWorkoutAchievements(completedWorkouts: Int) async {
        _ = await checkAchievement(AchievementCatalog.firstWorkout, currentValue: completedWorkouts)
        _ = await checkAchievement(AchievementCatalog.workouts10, currentValue: completedWorkouts)
        _ = await checkAchievement(AchievementCatalog.workouts25, currentValue: completedWorkouts)
        _ = await checkAchievement(AchievementCatalog.workouts50, currentValue: completedWorkouts)
        _ = await checkAchievement(AchievementCatalog.workouts100, currentValue: completedWorkouts)
        _ = await checkAchievement(AchievementCatalog.workouts250, currentValue: completedWorkouts)
        _ = await checkAchievement(AchievementCatalog.workouts500, currentValue: completedWorkouts)
    }

    private func checkPRAchievements(prCount: Int) async {
        _ = await checkAchievement(AchievementCatalog.firstPR, currentValue: prCount)
        _ = await checkAchievement(AchievementCatalog.prs5, currentValue: prCount)
        _ = await checkAchievement(AchievementCatalog.prs10, currentValue: prCount)
        _ = await checkAchievement(AchievementCatalog.prs25, currentValue: prCount)
    }

    private func checkVolumeAchievements(totalVolume: Int) async {
        _ = await checkAchievement(AchievementCatalog.volume10k, currentValue: totalVolume)
        _ = await checkAchievement(AchievementCatalog.volume50k, currentValue: totalVolume)
        _ = await checkAchievement(AchievementCatalog.volume100k, currentValue: totalVolume)
        _ = await checkAchievement(AchievementCatalog.volume500k, currentValue: totalVolume)
        _ = await checkAchievement(AchievementCatalog.volume1m, currentValue: totalVolume)
    }

    private func calculateAllProgress() async {
        guard let patientId = patientId else { return }

        let stats = await fetchPatientStats(patientId: patientId)

        achievementProgress = AchievementCatalog.all.map { definition in
            let currentValue: Int
            let isUnlocked = self.isUnlocked(definition.id)
            let unlockedAt = unlockedAchievements.first { $0.achievementId == definition.id }?.unlockedAt

            switch definition.type {
            case .streak:
                currentValue = max(stats.currentStreak, stats.longestStreak)
            case .workouts:
                currentValue = stats.completedWorkouts
            case .personalRecord:
                currentValue = stats.prCount
            case .volume:
                currentValue = stats.totalVolume
            case .consistency, .special:
                currentValue = 0
            }

            return AchievementProgress(
                definition: definition,
                currentValue: currentValue,
                isUnlocked: isUnlocked,
                unlockedAt: unlockedAt
            )
        }
    }

    private func calculateTotalPoints() {
        totalPoints = unlockedAchievements.compactMap { unlocked in
            AchievementCatalog.get(unlocked.achievementId)?.tier.points
        }.reduce(0, +)
    }

    private func fetchPatientStats(patientId: UUID) async -> PatientStats {
        var stats = PatientStats()

        // Fetch streak data
        do {
            let streaks = try await StreakTrackingService.shared.fetchCurrentStreaks(for: patientId)
            if let combinedStreak = streaks.first(where: { $0.streakType == .combined }) {
                stats.currentStreak = combinedStreak.currentStreak
                stats.longestStreak = combinedStreak.longestStreak
            }
        } catch {
            logger.log("AchievementService: Failed to fetch streak data: \(error)", level: .warning)
        }

        // Fetch workout count from scheduled sessions
        do {
            let response = try await client.client
                .from("scheduled_sessions")
                .select("id", head: false, count: .exact)
                .eq("patient_id", value: patientId.uuidString)
                .eq("completed", value: true)
                .execute()

            stats.completedWorkouts = response.count ?? 0
        } catch {
            logger.log("AchievementService: Failed to fetch workout count: \(error)", level: .warning)
        }

        // Also count manual sessions
        do {
            let response = try await client.client
                .from("manual_sessions")
                .select("id", head: false, count: .exact)
                .eq("patient_id", value: patientId.uuidString)
                .eq("status", value: "completed")
                .execute()

            stats.completedWorkouts += response.count ?? 0
        } catch {
            logger.log("AchievementService: Failed to fetch manual session count: \(error)", level: .warning)
        }

        // Fetch PR count from big lifts
        do {
            let bigLifts = try await BigLiftsService.shared.fetchBigLiftsSummary(patientId: patientId)
            stats.prCount = bigLifts.reduce(0) { $0 + $1.prCount }
        } catch {
            logger.log("AchievementService: Failed to fetch PR count: \(error)", level: .warning)
        }

        // Fetch total volume (simplified - would need aggregate query in production)
        do {
            let bigLifts = try await BigLiftsService.shared.fetchBigLiftsSummary(patientId: patientId)
            stats.totalVolume = Int(bigLifts.reduce(0.0) { $0 + $1.totalVolume })
        } catch {
            logger.log("AchievementService: Failed to fetch volume: \(error)", level: .warning)
        }

        return stats
    }

    // MARK: - Caching

    private func saveToCache() {
        guard let data = try? JSONEncoder().encode(unlockedAchievements) else { return }
        UserDefaults.standard.set(data, forKey: unlockedAchievementsKey)
        UserDefaults.standard.set(Date(), forKey: lastSyncKey)
    }

    private func loadFromCache() {
        guard let data = UserDefaults.standard.data(forKey: unlockedAchievementsKey),
              let achievements = try? JSONDecoder().decode([UnlockedAchievement].self, from: data) else {
            return
        }
        unlockedAchievements = achievements
    }

    // MARK: - Date Parsing

    private static func parseDate(_ dateString: String) throws -> Date {
        // Try ISO8601 with fractional seconds
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }

        // Try ISO8601 without fractional seconds
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }

        // Try date-only format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatter.date(from: dateString) {
            return date
        }

        throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Cannot decode date: \(dateString)"))
    }
}

// MARK: - Supporting Types

/// Patient statistics for achievement checking
private struct PatientStats {
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var completedWorkouts: Int = 0
    var prCount: Int = 0
    var totalVolume: Int = 0
}

/// Data for PR celebration display
struct PRCelebrationData: Identifiable, Equatable {
    var id: String { "\(exerciseName)-\(newWeight)-\(type)" }
    let exerciseName: String
    let newWeight: Double
    let previousWeight: Double?
    let improvement: Double?
    let unit: String
    let type: PRCelebrationType

    var formattedWeight: String {
        String(format: "%.0f %@", newWeight, unit)
    }

    var formattedImprovement: String? {
        guard let improvement = improvement else { return nil }
        return String(format: "+%.0f %@", improvement, unit)
    }

    static func == (lhs: PRCelebrationData, rhs: PRCelebrationData) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Preview Support

#if DEBUG
extension AchievementService {
    /// Create a preview instance with sample data
    static var preview: AchievementService {
        let service = AchievementService()
        service.unlockedAchievements = [
            UnlockedAchievement(achievementId: "first_workout", patientId: UUID(), unlockedAt: Date()),
            UnlockedAchievement(achievementId: "streak_7_day", patientId: UUID(), unlockedAt: Date()),
            UnlockedAchievement(achievementId: "workouts_10", patientId: UUID(), unlockedAt: Date())
        ]
        service.achievementProgress = AchievementProgress.sampleArray
        service.totalPoints = 45
        return service
    }
}
#endif
