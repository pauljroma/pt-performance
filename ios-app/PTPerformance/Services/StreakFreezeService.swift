//
//  StreakFreezeService.swift
//  PTPerformance
//
//  ACP-1029: Streak System Gamification
//  Service for managing streak freezes, comeback mechanics, and milestone tracking
//

import SwiftUI

// MARK: - Streak Freeze Service

/// Service for managing streak freeze inventory, comeback detection, and milestone celebrations
@MainActor
class StreakFreezeService: ObservableObject {

    // MARK: - Singleton

    static let shared = StreakFreezeService()

    // MARK: - Published Properties

    @Published var inventory: StreakFreezeInventory
    @Published var comebackState: StreakComebackState?
    @Published var pendingMilestone: StreakMilestone?
    @Published var pendingFreezeReward: StreakFreezeReward?
    @Published var showFreezeUsedConfirmation: Bool = false
    @Published var lastFreezeUsedDate: Date?

    // MARK: - Private Properties

    private let userDefaultsKey = "streak_freeze_inventory"
    private let celebratedMilestonesKey = "streak_celebrated_milestones"
    private let previousStreakKey = "streak_previous_value"
    private let logger = DebugLogger.shared

    // MARK: - Initialization

    private init() {
        // Load saved inventory
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let saved = try? JSONDecoder().decode(StreakFreezeInventory.self, from: data) {
            self.inventory = saved
        } else {
            self.inventory = StreakFreezeInventory()
        }
    }

    // MARK: - Freeze Management

    /// Use a streak freeze to protect the streak for today
    /// - Returns: Whether a freeze was successfully used
    func useFreeze() -> Bool {
        guard inventory.availableCount > 0 else {
            logger.log("[StreakFreezeService] No freezes available", level: .warning)
            return false
        }

        let today = Calendar.current.startOfDay(for: Date())
        let success = inventory.useFreeze(for: today)

        if success {
            saveInventory()
            lastFreezeUsedDate = today
            showFreezeUsedConfirmation = true
            logger.log("[StreakFreezeService] Freeze used for \(today). Remaining: \(inventory.availableCount)", level: .success)

            // Auto-dismiss confirmation after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.showFreezeUsedConfirmation = false
            }
        }

        return success
    }

    /// Check and award freezes based on milestone achievements
    /// - Parameter currentStreak: The current streak count
    func checkAndAwardFreezes(for currentStreak: Int) {
        guard let reward = StreakFreezeReward.reward(for: currentStreak) else { return }

        // Check if this reward was already given
        let awardedKey = "freeze_awarded_\(reward.requiredStreak)"
        guard !UserDefaults.standard.bool(forKey: awardedKey) else { return }

        // Award the freeze
        if inventory.awardFreeze() {
            saveInventory()
            UserDefaults.standard.set(true, forKey: awardedKey)
            pendingFreezeReward = reward

            logger.log("[StreakFreezeService] Awarded freeze for \(reward.requiredStreak)-day milestone. Available: \(inventory.availableCount)", level: .success)

            HapticFeedback.success()
        }
    }

    /// Clear pending freeze reward after display
    func clearFreezeReward() {
        pendingFreezeReward = nil
    }

    // MARK: - Comeback Detection

    /// Evaluate comeback state based on current streak data
    /// - Parameters:
    ///   - currentStreak: Current active streak count
    ///   - lastActivityDate: Date of last recorded activity
    func evaluateComebackState(currentStreak: Int, lastActivityDate: Date?) {
        // Store previous streak for comeback messaging
        let previousStreak = UserDefaults.standard.integer(forKey: previousStreakKey)

        if currentStreak > 0 {
            // Save current streak as previous for future reference
            UserDefaults.standard.set(currentStreak, forKey: previousStreakKey)
            comebackState = nil
            return
        }

        // Current streak is 0 -- check if this is a comeback situation
        guard let lastDate = lastActivityDate else {
            comebackState = nil
            return
        }

        let daysMissed = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0

        if daysMissed >= 1 && previousStreak > 0 {
            let phase = ComebackPhase.phase(for: daysMissed)
            comebackState = StreakComebackState(
                previousStreak: previousStreak,
                daysSinceLastActivity: daysMissed,
                comebackPhase: phase
            )

            logger.log("[StreakFreezeService] Comeback detected: \(daysMissed) days missed, previous streak: \(previousStreak)", level: .info)
        } else {
            comebackState = nil
        }
    }

    // MARK: - Milestone Tracking

    /// Check if a new milestone was reached and should be celebrated
    /// - Parameter currentStreak: The current streak count
    func checkMilestone(for currentStreak: Int) {
        guard let milestone = StreakMilestone.milestone(for: currentStreak) else { return }

        // Check if this milestone was already celebrated
        let celebrated = celebratedMilestones()
        guard !celebrated.contains(currentStreak) else { return }

        // Mark as celebrated and trigger the celebration
        markMilestoneCelebrated(currentStreak)
        pendingMilestone = milestone

        logger.log("[StreakFreezeService] Milestone reached: \(milestone.displayName) (\(currentStreak) days)", level: .success)
    }

    /// Clear the pending milestone celebration
    func clearMilestone() {
        pendingMilestone = nil
    }

    // MARK: - Freeze Display Helpers

    /// Whether a freeze can currently be activated (streak is at risk today)
    func canActivateFreeze(isAtRisk: Bool) -> Bool {
        isAtRisk && inventory.availableCount > 0
    }

    /// Description of when the next freeze will be earned
    func nextFreezeEarnedDescription(currentStreak: Int) -> String? {
        let nextReward = StreakFreezeReward.allCases.first { reward in
            reward.requiredStreak > currentStreak
        }

        guard let reward = nextReward else {
            return nil
        }

        let daysUntil = reward.requiredStreak - currentStreak
        return "\(daysUntil) day\(daysUntil == 1 ? "" : "s") until next Streak Shield"
    }

    // MARK: - Private Helpers

    private func saveInventory() {
        do {
            let data = try JSONEncoder().encode(inventory)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            logger.log("[StreakFreezeService] Failed to save inventory: \(error.localizedDescription)", level: .error)
        }
    }

    private func celebratedMilestones() -> Set<Int> {
        let array = UserDefaults.standard.array(forKey: celebratedMilestonesKey) as? [Int] ?? []
        return Set(array)
    }

    private func markMilestoneCelebrated(_ streak: Int) {
        var celebrated = celebratedMilestones()
        celebrated.insert(streak)
        UserDefaults.standard.set(Array(celebrated), forKey: celebratedMilestonesKey)
    }
}
