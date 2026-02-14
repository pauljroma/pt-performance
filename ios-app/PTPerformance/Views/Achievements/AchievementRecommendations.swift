//
//  AchievementRecommendations.swift
//  PTPerformance
//
//  ACP-1030: Achievement System Polish
//  Helper for recommending next achievements to pursue
//

import Foundation

/// Helper for determining which achievements to show as "Up Next"
enum AchievementRecommendations {

    /// Get recommended next goals based on progress
    /// Returns achievements closest to being unlocked
    static func getNextGoals(from allProgress: [AchievementProgress], limit: Int = 3) -> [AchievementProgress] {
        allProgress
            .filter { !$0.isUnlocked && $0.progress > 0 }
            .sorted { lhs, rhs in
                // Prioritize by:
                // 1. Higher progress percentage
                // 2. Lower tier (easier achievements first)
                if abs(lhs.progress - rhs.progress) > 0.01 {
                    return lhs.progress > rhs.progress
                }
                return lhs.definition.tier < rhs.definition.tier
            }
            .prefix(limit)
            .map { $0 }
    }

    /// Get achievements by type for filtered views
    static func achievements(ofType type: AchievementType, from allProgress: [AchievementProgress]) -> [AchievementProgress] {
        allProgress.filter { $0.definition.type == type }
    }

    /// Get achievements by rarity
    static func achievements(ofRarity rarity: AchievementRarity, from allProgress: [AchievementProgress]) -> [AchievementProgress] {
        allProgress.filter { $0.definition.rarity == rarity }
    }

    /// Get achievements by tier
    static func achievements(ofTier tier: AchievementTier, from allProgress: [AchievementProgress]) -> [AchievementProgress] {
        allProgress.filter { $0.definition.tier == tier }
    }
}
